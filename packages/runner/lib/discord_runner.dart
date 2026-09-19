import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_shared/bot_creator_shared.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

import 'runner_data_store.dart';
import 'stores/command_stats_store.dart';

/// Thin delegate runner that utilizes the shared [BotEngine].
class DiscordRunner {
  final String botId;
  BotConfig config;
  final RunnerDataStore store;
  final CommandStatsStore? statsStore;
  final void Function(String reason)? onDisconnected;
  final void Function(BotRuntimeMetrics metrics, {required String botId})?
  onMetrics;
  final Logger _log;

  late final BotEngine _engine;
  Timer? _scheduledWorkflowTimer;
  final Map<String, DateTime> _scheduledLastRun = <String, DateTime>{};

  DiscordRunner(
    this.botId,
    this.config, {
    this.statsStore,
    this.onDisconnected,
    this.onMetrics,
  })
    : store = RunnerDataStore(config, statsStore: statsStore),
      _log = Logger('bot:$botId') {
    _engine = BotEngine(
      store: store,
      callbacks: BotEngineCallbacks(
        onLog: (msg, {required botId}) => _log.info(msg),
        onDebugLog: (msg, {botId}) => _log.fine(msg),
        onLifecycleChange: (event, {required botId}) =>
            _log.info('Lifecycle change: $event'),
        onReplayCaptured: (botId, label, frames, totalMs) {
          _engine.saveDebugReplay(botId, label, frames, totalMs);
        },
        isDebugReplayCapturing: (botId) => _engine.isDebugReplayCapturing(botId),
        onDisconnected: (reason, {required botId}) {
          if (isDiscordGatewayDisallowedIntents(null, reason)) {
            _log.warning('Disallowed intents (4014): $reason');
          } else {
            _log.warning('Permanent disconnection: $reason');
          }
          onDisconnected?.call(reason);
        },
        onMetrics: (metrics, {required botId}) {
          onMetrics?.call(metrics, botId: botId);
        },
      ),
    );
  }

  Future<void> start() async {
    _log.info('Starting runner with BotEngine...');
    await _engine.startWithId(botId, config.token);
    _startScheduledWorkflowLoop();
  }

  Future<void> stop() async {
    _scheduledWorkflowTimer?.cancel();
    _scheduledWorkflowTimer = null;
    await _engine.stop(botId);
    await store.dispose();
  }

  Future<bool> reloadConfig(BotConfig newConfig) async {
    final previousConfig = config;
    final requiresReconnect =
        previousConfig.token.trim() != newConfig.token.trim() ||
        !_sameIntents(previousConfig.intents, newConfig.intents) ||
        previousConfig.autoSharding != newConfig.autoSharding ||
        // Musique : on compare l'ÉTAT réel. Un bloc `lavalink` présent mais éteint
        // (`enabled: false`, cas d'un compte non premium) ne doit pas faire croire
        // que la musique est configurée ; allumer ou éteindre doit reconnecter.
        (previousConfig.lavalinkConfig?.enabled ?? false) !=
            (newConfig.lavalinkConfig?.enabled ?? false);

    config = newConfig;
    store.updateConfig(newConfig);
    
    await _engine.reload(botId);
    
    _log.info('Runner config reloaded.');
    return requiresReconnect;
  }

  bool _sameIntents(Map<String, bool> a, Map<String, bool> b) {
    if (a.length != b.length) return false;
    for (final entry in a.entries) {
      if ((b[entry.key] ?? false) != entry.value) return false;
    }
    return true;
  }

  void _startScheduledWorkflowLoop() {
    _scheduledWorkflowTimer?.cancel();
    _scheduledWorkflowTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _tickScheduledWorkflows();
    });
  }

  Future<void> _tickScheduledWorkflows() async {
    // Periodically prune expired interaction listeners from the registry to prevent memory leaks.
    InteractionListenerRegistry.instance.pruneExpired();

    final session = _engine.getSession(botId);
    if (session == null || !session.isActive) return;

    final now = DateTime.now();
    final triggers = config.scheduledTriggers
        .map((entry) => Map<String, dynamic>.from(entry))
        .where((entry) => entry['enabled'] != false);

    for (final trigger in triggers) {
      final workflowName = (trigger['workflowName'] ?? '').toString();
      final everyMinutes = int.tryParse((trigger['everyMinutes'] ?? '').toString()) ?? 0;
      if (workflowName.isEmpty || everyMinutes <= 0) continue;

      final lastRun = _scheduledLastRun[workflowName];
      if (lastRun == null || now.difference(lastRun).inMinutes >= everyMinutes) {
        _scheduledLastRun[workflowName] = now;
        unawaited(_executeScheduledWorkflow(session, trigger));
      }
    }
  }

  Future<void> _executeScheduledWorkflow(
    BotSession session,
    Map<String, dynamic> trigger,
  ) async {
    final workflowName = (trigger['workflowName'] ?? '').toString().trim();
    final workflow = await store.getWorkflowByName(botId, workflowName);
    if (workflow == null) return;

    final runtimeVariables = <String, String>{
      'workflow.type': 'general',
      'workflow.trigger': 'scheduled',
      'trigger.minutes': (trigger['everyMinutes'] ?? '').toString(),
    };

    session.injectVariables(runtimeVariables);
    if (session.gateway != null) {
      runtimeVariables.addAll(extractBotRuntimeDetails(session.gateway!));
    }

    await session.workflowExecutor.executeGeneralWorkflow(
      workflowData: workflow,
      gateway: session.gateway!,
      botId: botId,
      runtimeVariables: runtimeVariables,
    );
  }

  Future<void> executeInboundWebhook({
    required String workflowName,
    required Map<String, dynamic> payload,
    required Map<String, String> headers,
    String? requestId,
    String? sourceIp,
  }) async {
    final session = _engine.getSession(botId);
    if (session == null || !session.isActive) {
      throw StateError('Bot is not connected.');
    }

    final workflow = await store.getWorkflowByName(botId, workflowName);
    if (workflow == null) {
      throw StateError('Workflow "$workflowName" not found.');
    }

    final runtimeVariables = <String, String>{
      'workflow.type': 'inboundWebhook',
      'inbound.event.name': 'inboundWebhook',
      'inbound.workflow.name': workflowName,
      'inbound.request.id': requestId ?? '',
      'inbound.source.ip': sourceIp ?? '',
      'inbound.payload.json': jsonEncode(payload),
    };

    for (final entry in payload.entries) {
      runtimeVariables['inbound.payload.${entry.key}'] = entry.value?.toString() ?? '';
    }
    for (final entry in headers.entries) {
      runtimeVariables['inbound.header.${entry.key.toLowerCase()}'] = entry.value;
    }

    session.injectVariables(runtimeVariables);
    if (session.gateway != null) {
      runtimeVariables.addAll(extractBotRuntimeDetails(session.gateway!));
    }

    // Handle arguments if provided in payload
    final providedArguments = normalizeWorkflowCallArguments(payload['args']);
    applyWorkflowInvocationContext(
      variables: runtimeVariables,
      workflowName: workflowName,
      entryPoint: normalizeWorkflowEntryPoint(workflow['entryPoint']),
      definitions: parseWorkflowArgumentDefinitions(workflow['arguments']),
      providedArguments: providedArguments,
    );

    await session.workflowExecutor.executeGeneralWorkflow(
      workflowData: workflow,
      gateway: session.gateway!,
      botId: botId,
      runtimeVariables: runtimeVariables,
    );
  }

  bool get isDebugReplayCapturing => _engine.isDebugReplayCapturing(botId);
  void setDebugReplayCapturing(bool enabled) =>
      _engine.setDebugReplayCapturing(botId, enabled);
  List<Map<String, dynamic>> listDebugReplays({int limit = 30}) =>
      _engine.listDebugReplays(botId, limit: limit);
  void clearDebugReplays() => _engine.clearDebugReplays(botId);
}


