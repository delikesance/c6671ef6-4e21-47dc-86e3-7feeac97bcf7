import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bot_creator_shared/actions/handle_component_interaction.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/actions/interaction_response.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/events/event_contexts.dart';
import 'package:bot_creator_shared/utils/interaction_ack_state.dart';
import 'package:bot_creator_shared/utils/command_autocomplete.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/global.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:bot_creator_shared/utils/runtime_variables.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:bot_creator_shared/utils/workflow_call.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';

import 'command_workflow_routing.dart';
import 'runner_data_store.dart';
import 'stores/command_stats_store.dart';

part 'discord_runner_legacy.part.dart';
part 'discord_runner_events.part.dart';
part 'discord_runner_interactions.part.dart';
part 'discord_runner_helpers.part.dart';
part 'discord_runner_profile.part.dart';

// No longer a static logger. Each runner has its own.

class _AwaitedLegacyTrigger {
  const _AwaitedLegacyTrigger({
    required this.name,
    required this.isErrorTrigger,
    this.filter,
  });

  final String name;
  final bool isErrorTrigger;
  final String? filter;
}

class _AwaitedLegacyCallbacks {
  const _AwaitedLegacyCallbacks({
    this.successCommand,
    this.errorCommand,
    this.filter,
  });

  final Map<String, dynamic>? successCommand;
  final Map<String, dynamic>? errorCommand;
  final String? filter;

  _AwaitedLegacyCallbacks copyWith({
    Map<String, dynamic>? successCommand,
    Map<String, dynamic>? errorCommand,
    String? filter,
  }) {
    return _AwaitedLegacyCallbacks(
      successCommand: successCommand ?? this.successCommand,
      errorCommand: errorCommand ?? this.errorCommand,
      filter: filter ?? this.filter,
    );
  }
}

_AwaitedLegacyTrigger? _parseAwaitedLegacyTrigger(String rawName) {
  final name = rawName.trim();
  final successMatch = RegExp(
    r'^\$awaitedcommand\[(.+?);(.*)\]$',
    caseSensitive: false,
  ).firstMatch(name);
  if (successMatch != null) {
    final awaitedName = (successMatch.group(1) ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final filter = successMatch.group(2)?.trim();
    if (awaitedName.isEmpty) {
      return null;
    }
    return _AwaitedLegacyTrigger(
      name: awaitedName,
      isErrorTrigger: false,
      filter: filter == null || filter.isEmpty ? null : filter,
    );
  }

  final errorMatch = RegExp(
    r'^\$awaitedcommanderror\[(.+?)\]$',
    caseSensitive: false,
  ).firstMatch(name);
  if (errorMatch != null) {
    final awaitedName = (errorMatch.group(1) ?? '')
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    if (awaitedName.isEmpty) {
      return null;
    }
    return _AwaitedLegacyTrigger(name: awaitedName, isErrorTrigger: true);
  }

  return null;
}

bool _matchesAwaitedFilter(String message, String? rawFilter) {
  final filter = (rawFilter ?? '').trim();
  if (filter.isEmpty) {
    return true;
  }

  if (!filter.startsWith('<') || !filter.endsWith('>')) {
    return true;
  }

  final body = filter.substring(1, filter.length - 1).trim();
  if (body.isEmpty) {
    return true;
  }

  if (body.toLowerCase() == 'numeric') {
    return RegExp(r'^-?\d+(\.\d+)?$').hasMatch(message.trim());
  }

  final allowed =
      body
          .split('/')
          .map((entry) => entry.trim().toLowerCase())
          .where((entry) => entry.isNotEmpty)
          .toSet();
  if (allowed.isEmpty) {
    return true;
  }
  return allowed.contains(message.trim().toLowerCase());
}

enum EventWorkflowListenerMode { none, messageCreateOnly, full }

bool isLegacyCommandEnabledInConfigEntry(Map<String, dynamic> command) {
  final data = Map<String, dynamic>.from(
    (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
  );
  final value = Map<String, dynamic>.from(
    (data['data'] as Map?)?.cast<String, dynamic>() ?? data,
  );
  final commandType =
      (value['commandType'] ?? command['type'] ?? 'chatInput')
          .toString()
          .toLowerCase();
  return value['legacyModeEnabled'] == true &&
      (commandType == 'chatinput' ||
          commandType == 'chat_input' ||
          commandType == 'chat-input' ||
          commandType == 'slash');
}

EventWorkflowListenerMode resolveEventWorkflowListenerMode(BotConfig config) {
  final hasEventWorkflows = config.workflows.any((workflow) {
    final normalized = normalizeStoredWorkflowDefinition(workflow);
    return normalizeWorkflowType(normalized['workflowType']) ==
        workflowTypeEvent;
  });
  if (hasEventWorkflows) {
    return EventWorkflowListenerMode.full;
  }

  final hasLegacyCommands = config.commands.any(
    isLegacyCommandEnabledInConfigEntry,
  );
  if (hasLegacyCommands) {
    return EventWorkflowListenerMode.messageCreateOnly;
  }

  return EventWorkflowListenerMode.none;
}

bool shouldRebindEventWorkflowListeners(
  BotConfig previousConfig,
  BotConfig newConfig,
) {
  return resolveEventWorkflowListenerMode(previousConfig) !=
      resolveEventWorkflowListenerMode(newConfig);
}

/// Connects to Discord via nyxx, registers command listeners, and dispatches
/// interactions to the shared action handlers — matching commands by their Discord ID.
class DiscordRunner {
  final String botId;
  BotConfig config;
  final RunnerDataStore store;
  final CommandStatsStore? statsStore;
  final Logger _log;

  NyxxGateway? _gateway;
  DateTime? _startedAt;
  String? _cachedApplicationOwnerId;
  Timer? _statusRotationTimer;
  Timer? _scheduledWorkflowTimer;
  final Map<String, DateTime> _scheduledLastRun = <String, DateTime>{};
  final List<StreamSubscription<dynamic>> _eventWorkflowSubscriptions =
      <StreamSubscription<dynamic>>[];
  final Random _random = Random();
  bool _debugReplayCapturing = true;
  final List<Map<String, dynamic>> _debugReplays = <Map<String, dynamic>>[];

  static const int _maxDebugReplays = 30;

  bool get isDebugReplayCapturing => _debugReplayCapturing;

  void setDebugReplayCapturing(bool enabled) {
    _debugReplayCapturing = enabled;
  }

  List<Map<String, dynamic>> listDebugReplays({int limit = _maxDebugReplays}) {
    final safeLimit = limit <= 0 ? 1 : limit;
    if (_debugReplays.length <= safeLimit) {
      return List<Map<String, dynamic>>.from(_debugReplays);
    }
    return List<Map<String, dynamic>>.from(_debugReplays.take(safeLimit));
  }

  void clearDebugReplays() {
    _debugReplays.clear();
  }

  void _appendDebugReplay({
    required String commandLabel,
    required String botId,
    required List<Map<String, dynamic>> frames,
    required int totalMs,
  }) {
    final record = <String, dynamic>{
      'commandLabel': commandLabel,
      'triggeredAt': DateTime.now().toUtc().toIso8601String(),
      'botId': botId,
      'frames': frames,
      'totalMs': totalMs,
    };
    _debugReplays.insert(0, record);
    if (_debugReplays.length > _maxDebugReplays) {
      _debugReplays.removeRange(_maxDebugReplays, _debugReplays.length);
    }
  }

  Future<Map<String, String>> _runActionsWithReplay({
    required String replayLabel,
    required NyxxGateway client,
    required Interaction? interaction,
    required List<Action> actions,
    required String botId,
    required Map<String, String> runtimeVariables,
    Snowflake? fallbackChannelId,
    Snowflake? fallbackGuildId,
    List<Action> Function(List<Action>)? nestedActionsPreprocessor,
  }) async {
    var replayCapturedByActions = false;
    await _hydratePlaceholdersWithContexts(
      actions: actions,
      variables: runtimeVariables,
      botId: botId,
    );
    return handleActions(
      client,
      interaction,
      actions: actions,
      store: store,
      botId: botId,
      variables: runtimeVariables,
      resolveTemplate: (input) => resolveTemplatePlaceholders(input, runtimeVariables),
      fallbackChannelId: fallbackChannelId,
      fallbackGuildId: fallbackGuildId,
      onLog: (msg) => _log.info(msg),
      nestedActionsPreprocessor: nestedActionsPreprocessor,
      onReplayCaptured:
          _debugReplayCapturing
              ? (frames, totalMs) {
                replayCapturedByActions = true;
                _appendDebugReplay(
                  commandLabel: replayLabel,
                  botId: botId,
                  frames: frames
                      .map((entry) => Map<String, dynamic>.from(entry))
                      .toList(growable: false),
                  totalMs: totalMs,
                );
              }
              : null,
    ).then((results) {
      if (_debugReplayCapturing &&
          !replayCapturedByActions &&
          actions.isNotEmpty) {
        _appendDebugReplay(
          commandLabel: replayLabel,
          botId: botId,
          frames: <Map<String, dynamic>>[
            <String, dynamic>{
              'actionType': 'commandExecution',
              'startMs': 0,
              'durationMs': 1,
              'result': 'No replay frames were produced.',
            },
          ],
          totalMs: 1,
        );
      }
      return results;
    });
  }

  DiscordRunner(this.botId, this.config, {this.statsStore})
    : store = RunnerDataStore(config),
      _log = Logger('bot:$botId');

  Future<void> start() async {
    _log.info('Starting runner with ${config.commands.length} command(s)...');

    final hasLegacy = config.commands.any(_isLegacyCommandEnabled);

    // 1. Fetch which privileged intents Discord has approved for this app.
    final approvedPrivileged = await _fetchApprovedPrivilegedIntents(
      config.token,
    );
    if (approvedPrivileged.isNotEmpty) {
      _log.info(
        'Approved privileged intents: ${approvedPrivileged.join(', ')}',
      );
    }

    // 2. Resolve the intents required by configured event workflows
    //    and legacy commands, gated by privileged-intent approval.
    final warnings = <String>[];
    final requiredKeys = resolveRequiredIntentKeys(
      eventWorkflows: _eventWorkflows,
      hasLegacyCommands: hasLegacy,
      approvedPrivilegedIntents: approvedPrivileged,
      warnings: warnings,
    );

    for (final w in warnings) {
      _log.warning(w);
    }

    // 3. Merge with any extra intents the user explicitly enabled.
    final mergedKeys = <String>{...requiredKeys};
    for (final entry in config.intents.entries) {
      if (entry.value == true) {
        // Only add non-privileged or approved privileged intents.
        if (!privilegedIntentKeys.contains(entry.key) ||
            approvedPrivileged.contains(entry.key)) {
          mergedKeys.add(entry.key);
        }
      }
    }

    _log.info('Resolved gateway intents: ${mergedKeys.join(', ')}');
    _log.info(
      config.autoSharding
          ? 'Auto-sharding enabled (Discord recommended shard count).'
          : 'Auto-sharding disabled (forcing a single shard).',
    );

    _gateway = await Nyxx.connectGateway(
      config.token,
      _buildIntentsFromKeys(mergedKeys),
      options: GatewayClientOptions(),
    );

    _startedAt = DateTime.now();

    _gateway!.onReady.listen((event) async {
      _log.info(
        'Bot ${event.user.username} (#${event.user.id}) is online and ready.',
      );
      try {
        final app = await _gateway!.applications.fetchCurrentApplication();
        _cachedApplicationOwnerId = app.owner?.id.toString();
      } catch (_) {}

      await _reconcileCurrentBotProfile(event.gateway.client);
      _startStatusRotation(event.gateway.client);
    });

    _gateway!.onInteractionCreate.listen((event) async {
      try {
        await _handleInteraction(event);
      } catch (error, stack) {
        _log.severe('Top-level interaction error: $error', error, stack);
      }
    });

    _registerEventWorkflowListeners();
    _startScheduledWorkflowLoop();

    _log.info(
      'Gateway connected — listening for interactions and ${_eventWorkflows.length} event workflow(s).',
    );
  }

  Future<void> stop() async {
    _statusRotationTimer?.cancel();
    _statusRotationTimer = null;
    _scheduledWorkflowTimer?.cancel();
    _scheduledWorkflowTimer = null;
    _scheduledLastRun.clear();
    await _cancelEventWorkflowListeners();
    await _gateway?.close();
    _gateway = null;
    await store.dispose();
    _log.info('Runner stopped.');
  }

  /// Hot-reloads the bot configuration without disconnecting from Discord.
  Future<bool> reloadConfig(BotConfig newConfig) async {
    final previousConfig = config;
    final requiresReconnect =
        previousConfig.token.trim() != newConfig.token.trim() ||
        !_sameIntents(previousConfig.intents, newConfig.intents) ||
        previousConfig.autoSharding != newConfig.autoSharding;
    shouldRebindEventWorkflowListeners(previousConfig, newConfig);

    config = newConfig;
    store.updateWorkflows(newConfig.workflows);
    _scheduledWorkflowTimer?.cancel();
    _scheduledWorkflowTimer = null;
    _scheduledLastRun.clear();
    _startScheduledWorkflowLoop();
    if (_gateway != null) {
      await _rebindEventWorkflowListeners();
    }
    if (_gateway != null) {
      _startStatusRotation(_gateway!);
      unawaited(_reconcileCurrentBotProfile(_gateway!));
    }
    _log.info(
      'Config reloaded (live): ${newConfig.commands.length} command(s), '
      '${newConfig.workflows.length} workflow(s).',
    );
    return requiresReconnect;
  }

  Future<void> executeInboundWebhook({
    required String workflowName,
    required Map<String, dynamic> payload,
    required Map<String, String> headers,
    String? requestId,
    String? sourceIp,
  }) async {
    final gateway = _gateway;
    if (gateway == null) {
      throw StateError('Bot is not connected to Discord.');
    }

    final normalizedWorkflowName = workflowName.trim();
    if (normalizedWorkflowName.isEmpty) {
      throw StateError('Missing workflow name.');
    }

    final workflow = config.workflows
        .map(normalizeStoredWorkflowDefinition)
        .where((entry) {
          final type = normalizeWorkflowType(entry['workflowType']);
          if (type == workflowTypeEvent) {
            return false;
          }
          return (entry['name'] ?? '').toString().trim().toLowerCase() ==
              normalizedWorkflowName.toLowerCase();
        })
        .cast<Map<String, dynamic>?>()
        .firstWhere((entry) => entry != null, orElse: () => null);

    if (workflow == null) {
      throw StateError('Workflow "$normalizedWorkflowName" was not found.');
    }

    final actions = List<Action>.from(
      ((workflow['actions'] as List?) ?? const <dynamic>[])
          .whereType<Map>()
          .map((json) => Action.fromJson(Map<String, dynamic>.from(json))),
    );
    if (actions.isEmpty) {
      throw StateError('Workflow "$normalizedWorkflowName" has no actions.');
    }

    final botId = gateway.user.id.toString();
    final runtimeVariables = <String, String>{
      'workflow.type': workflowTypeInboundWebhook,
      'inbound.event.name': 'inboundWebhook',
      'inbound.workflow.name': normalizedWorkflowName,
      'inbound.request.id': (requestId ?? '').trim(),
      'inbound.source.ip': (sourceIp ?? '').trim(),
      'inbound.payload.json': jsonEncode(payload),
    };

    for (final entry in payload.entries) {
      final key = entry.key.toString().trim();
      if (key.isEmpty) {
        continue;
      }
      runtimeVariables['inbound.payload.$key'] =
          entry.value == null ? '' : entry.value.toString();
    }
    for (final entry in headers.entries) {
      final key = entry.key.trim().toLowerCase();
      if (key.isEmpty) {
        continue;
      }
      runtimeVariables['inbound.header.$key'] = entry.value;
    }

    runtimeVariables.addAll(extractBotRuntimeDetails(gateway));
    _injectGatewayBotVariables(runtimeVariables);

    await hydrateRuntimeVariables(
      store: store,
      botId: botId,
      runtimeVariables: runtimeVariables,
      guildContextId: null,
      channelContextId: null,
      userContextId: null,
      messageContextId: null,
    );

    final providedArguments = normalizeWorkflowCallArguments(payload['args']);
    applyWorkflowInvocationContext(
      variables: runtimeVariables,
      workflowName: normalizedWorkflowName,
      entryPoint: normalizeWorkflowEntryPoint(workflow['entryPoint']),
      definitions: parseWorkflowArgumentDefinitions(workflow['arguments']),
      providedArguments: providedArguments,
    );

    await _runActionsWithReplay(
      replayLabel: 'inbound:$normalizedWorkflowName',
      client: gateway,
      interaction: null,
      actions: actions,
      botId: botId,
      runtimeVariables: runtimeVariables,
    );
    _log.info('Executed inbound workflow "$normalizedWorkflowName".');
  }

  static const _intentKeyToGateway = <String, Flags<GatewayIntents>>{
    'Guilds': GatewayIntents.guilds,
    'Guild Members': GatewayIntents.guildMembers,
    'Guild Moderation': GatewayIntents.guildModeration,
    'Guild Expressions': GatewayIntents.guildExpressions,
    'Guild Integrations': GatewayIntents.guildIntegrations,
    'Guild Webhooks': GatewayIntents.guildWebhooks,
    'Guild Invites': GatewayIntents.guildInvites,
    'Guild Voice States': GatewayIntents.guildVoiceStates,
    'Guild Presence': GatewayIntents.guildPresences,
    'Guild Messages': GatewayIntents.guildMessages,
    'Guild Message Reactions': GatewayIntents.guildMessageReactions,
    'Guild Message Typing': GatewayIntents.guildMessageTyping,
    'Direct Messages': GatewayIntents.directMessages,
    'Direct Message Reactions': GatewayIntents.directMessageReactions,
    'Direct Message Typing': GatewayIntents.directMessageTyping,
    'Message Content': GatewayIntents.messageContent,
    'Guild Scheduled Events': GatewayIntents.guildScheduledEvents,
    'Auto Moderation Configuration': GatewayIntents.autoModerationConfiguration,
    'Auto Moderation Execution': GatewayIntents.autoModerationExecution,
    'Guild Message Polls': GatewayIntents.guildMessagePolls,
    'Direct Message Polls': GatewayIntents.directMessagePolls,
  };
}
