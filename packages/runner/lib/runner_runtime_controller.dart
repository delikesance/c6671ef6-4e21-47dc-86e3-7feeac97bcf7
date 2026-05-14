import 'dart:io';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_runner/discord_runner.dart';
import 'package:bot_creator_runner/runner_bot_store.dart';
import 'package:bot_creator_runner/stores/command_stats_store.dart';

class RunnerBotRuntimeState {
  const RunnerBotRuntimeState({
    required this.botId,
    required this.botName,
    required this.state,
    required this.lastSeenAt,
    this.lastError,
    this.baselineRssBytes,
  });

  final String botId;
  final String botName;
  final String state;
  final DateTime? lastSeenAt;
  final String? lastError;
  final int? baselineRssBytes;
}

class RunnerRuntimeController {
  RunnerRuntimeController({RunnerBotStore? botStore, String? dataDir})
    : _botStore = botStore ?? RunnerBotStore(dataDir: dataDir),
      _commandStatsStore = CommandStatsStore(dataDir ?? _resolveDataDir());

  final RunnerBotStore _botStore;
  final CommandStatsStore _commandStatsStore;
  bool _statsInitialized = false;

  static String _resolveDataDir() {
    final configured =
        (Platform.environment['BOT_CREATOR_DATA_DIR'] ?? '').trim();
    return configured.isNotEmpty ? configured : './data';
  }

  final Map<String, DiscordRunner> _runners = <String, DiscordRunner>{};
  final Map<String, String> _botNames = <String, String>{};
  final Map<String, int?> _baselineRssByBot = <String, int?>{};
  final Map<String, DateTime> _lastSeenAtByBot = <String, DateTime>{};
  final Map<String, String?> _lastErrorByBot = <String, String?>{};
  final Set<String> _busyBots = <String>{};

  bool get isRunning => _runners.isNotEmpty;
  int get runningCount => _runners.length;
  List<String> get runningBotIds => _runners.keys.toList(growable: false);

  RunnerBotStore get botStore => _botStore;

  CommandStatsStore get commandStatsStore => _commandStatsStore;

  bool isBotRunning(String botId) => _runners.containsKey(botId);

  bool isDebugReplayCapturing(String botId) {
    final runner = _runners[botId];
    if (runner == null) {
      return false;
    }
    return runner.isDebugReplayCapturing;
  }

  void setDebugReplayCapturing(String botId, bool enabled) {
    final runner = _runners[botId];
    if (runner == null) {
      throw StateError('Bot "$botId" is not running.');
    }
    runner.setDebugReplayCapturing(enabled);
  }

  List<Map<String, dynamic>> listDebugReplays(String botId, {int limit = 30}) {
    final runner = _runners[botId];
    if (runner == null) {
      throw StateError('Bot "$botId" is not running.');
    }
    return runner.listDebugReplays(limit: limit);
  }

  void clearDebugReplays(String botId) {
    final runner = _runners[botId];
    if (runner == null) {
      throw StateError('Bot "$botId" is not running.');
    }
    runner.clearDebugReplays();
  }

  int? baselineRssForBot(String botId) => _baselineRssByBot[botId];

  RunnerBotRuntimeState runtimeStateForBot(String botId) {
    final running = _runners.containsKey(botId);
    return RunnerBotRuntimeState(
      botId: botId,
      botName: _botNames[botId] ?? botId,
      state: running ? 'running' : 'stopped',
      lastSeenAt: _lastSeenAtByBot[botId],
      lastError: _lastErrorByBot[botId],
      baselineRssBytes: _baselineRssByBot[botId],
    );
  }

  List<RunnerBotRuntimeState> listRuntimeStates() {
    final ids =
        <String>{
            ..._runners.keys,
            ..._botNames.keys,
            ..._lastSeenAtByBot.keys,
            ..._lastErrorByBot.keys,
          }.toList()
          ..sort();
    return ids.map(runtimeStateForBot).toList(growable: false);
  }

  /// Starts the bot identified by [botId] using the config persisted in the
  /// store.
  Future<void> startBot({required String botId, String? botName}) async {
    if (_busyBots.contains(botId)) {
      throw StateError('Bot "$botId" transition already in progress.');
    }
    if (_runners.containsKey(botId)) {
      throw StateError('Bot "$botId" is already running.');
    }

    _busyBots.add(botId);
    _lastSeenAtByBot[botId] = DateTime.now().toUtc();

    final baseline = _readCurrentProcessRssBytes();

    final entry = await _botStore.loadEntry(botId);
    if (entry == null) {
      _busyBots.remove(botId);
      throw StateError(
        'Bot "$botId" not found in store. Sync from the app first.',
      );
    }

    await startBotWithConfig(
      entry.config,
      botId: botId,
      botName: botName ?? entry.name,
      baselineRssBytes: baseline,
    );
    await _botStore.setRunning(botId, true);
  }

  /// Starts a bot directly from a [BotConfig] (used when syncing and starting
  /// in a single call).
  Future<void> startBotWithConfig(
    BotConfig config, {
    required String botId,
    String? botName,
    int? baselineRssBytes,
  }) async {
    if (_busyBots.contains(botId) && !_runners.containsKey(botId)) {
      // already locked by startBot
    } else if (_busyBots.contains(botId)) {
      throw StateError('Bot "$botId" transition already in progress.');
    } else {
      _busyBots.add(botId);
    }

    if (_runners.containsKey(botId)) {
      _busyBots.remove(botId);
      throw StateError('Bot "$botId" is already running.');
    }

    final runner = DiscordRunner(botId, config, statsStore: _commandStatsStore);
    try {
      if (!_statsInitialized) {
        await _commandStatsStore.init();
        _statsInitialized = true;
      }
      await runner.start();
      _runners[botId] = runner;
      _botNames[botId] = (botName ?? '').trim().isEmpty ? botId : botName!;
      _baselineRssByBot[botId] =
          baselineRssBytes ?? _readCurrentProcessRssBytes();
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
      _lastErrorByBot.remove(botId);
    } catch (error) {
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
      _lastErrorByBot[botId] = error.toString();
      rethrow;
    } finally {
      _busyBots.remove(botId);
    }
  }

  Future<void> stopBot(String botId) async {
    if (_busyBots.contains(botId)) {
      throw StateError('Bot "$botId" transition already in progress.');
    }

    final runner = _runners[botId];
    if (runner == null) {
      await _botStore.setRunning(botId, false);
      return;
    }

    _busyBots.add(botId);
    try {
      await runner.stop();
      _runners.remove(botId);
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
      await _botStore.setRunning(botId, false);
    } finally {
      _busyBots.remove(botId);
    }
  }

  Future<void> stopAllBots() async {
    final ids = _runners.keys.toList(growable: false);
    for (final botId in ids) {
      await stopBot(botId);
    }
  }

  /// Automatically resumes all bots that were marked as running in the store.
  Future<void> selfHeal() async {
    final entries = await _botStore.listAll();
    final toStart = entries.where((e) => e.running).toList();
    if (toStart.isEmpty) return;

    stdout.writeln(
      '[Self-Healing] Resuming ${toStart.length} bot(s) previously running...',
    );
    for (final entry in toStart) {
      try {
        await startBot(botId: entry.id, botName: entry.name);
        stdout.writeln(
          '[Self-Healing] Bot "${entry.name}" (${entry.id}) resumed.',
        );
      } catch (e) {
        stderr.writeln(
          '[Self-Healing] Failed to resume bot "${entry.name}" (${entry.id}): $e',
        );
      }
    }
  }

  Future<void> dispose() async {
    await stopAllBots();
  }

  /// Hot-reloads the config for a running bot without disconnecting
  /// from Discord.  Also persists the updated config to the store so
  /// a subsequent [startBot] call uses the latest version.
  Future<void> reloadBot(String botId, BotConfig newConfig) async {
    final name = _botNames[botId] ?? botId;
    await _botStore.save(botId, name, newConfig);
    final runner = _runners[botId];
    if (runner != null) {
      final requiresReconnect = await runner.reloadConfig(newConfig);
      if (requiresReconnect && newConfig.autoRestart) {
        await _restartRunningBotWithConfig(
          botId,
          name: name,
          config: newConfig,
        );
      }
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
    }
  }

  Future<void> upsertWorkflow(
    String botId,
    Map<String, dynamic> workflow,
  ) async {
    await _updateBotConfig(botId, (config) {
      final workflowName = (workflow['name'] ?? '').toString().trim();
      if (workflowName.isEmpty) {
        throw StateError('Missing workflow name for bot "$botId".');
      }

      final nextWorkflows = config.workflows
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      final nextWorkflow = Map<String, dynamic>.from(workflow)
        ..['name'] = workflowName;
      final index = nextWorkflows.indexWhere(
        (entry) =>
            (entry['name'] ?? '').toString().trim().toLowerCase() ==
            workflowName.toLowerCase(),
      );
      if (index >= 0) {
        nextWorkflows[index] = nextWorkflow;
      } else {
        nextWorkflows.add(nextWorkflow);
      }
      return config.copyWith(workflows: nextWorkflows);
    }, reloadRunner: true);
  }

  Future<void> deleteWorkflow(String botId, String workflowName) async {
    final normalizedWorkflowName = workflowName.trim();
    if (normalizedWorkflowName.isEmpty) {
      throw StateError('Missing workflow name for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final nextWorkflows = config.workflows
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      nextWorkflows.removeWhere(
        (entry) =>
            (entry['name'] ?? '').toString().trim().toLowerCase() ==
            normalizedWorkflowName.toLowerCase(),
      );
      return config.copyWith(workflows: nextWorkflows);
    }, reloadRunner: true);
  }

  Future<void> upsertGlobalVariable(
    String botId,
    String key,
    dynamic value,
  ) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw StateError('Missing variable key for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final nextGlobals = Map<String, dynamic>.from(config.globalVariables)
        ..[normalizedKey] = value;
      return config.copyWith(globalVariables: nextGlobals);
    });
  }

  Future<void> removeGlobalVariable(String botId, String key) async {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) {
      throw StateError('Missing variable key for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final nextGlobals = Map<String, dynamic>.from(config.globalVariables)
        ..remove(normalizedKey);
      return config.copyWith(globalVariables: nextGlobals);
    });
  }

  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    final normalizedOldKey = oldKey.trim();
    final normalizedNewKey = newKey.trim();
    if (normalizedOldKey.isEmpty || normalizedNewKey.isEmpty) {
      throw StateError('Missing variable key for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final nextGlobals = Map<String, dynamic>.from(config.globalVariables);
      if (!nextGlobals.containsKey(normalizedOldKey)) {
        return config;
      }
      final value = nextGlobals.remove(normalizedOldKey);
      nextGlobals[normalizedNewKey] = value;
      return config.copyWith(globalVariables: nextGlobals);
    });
  }

  Future<void> upsertScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    final normalizedKey = key.trim();
    final normalizedScope = scope.trim();
    if (normalizedKey.isEmpty || normalizedScope.isEmpty) {
      throw StateError('Missing scoped variable definition for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final defs = config.scopedVariableDefinitions
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      final next = <String, dynamic>{
        'key': normalizedKey,
        'scope': normalizedScope,
        'defaultValue': defaultValue,
        'valueType': valueType,
      };
      final normalizedRefKey = BotConfig.normalizeScopedVariableKey(normalizedKey);
      final index = defs.indexWhere(
        (entry) =>
            BotConfig.normalizeScopedVariableKey(
              (entry['key'] ?? '').toString(),
            ) ==
            normalizedRefKey &&
            (entry['scope'] ?? '').toString().trim() == normalizedScope,
      );
      if (index >= 0) {
        defs[index] = next;
      } else {
        defs.add(next);
      }
      return config.copyWith(scopedVariableDefinitions: defs);
    });
  }

  Future<void> deleteScopedVariableDefinition(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    final normalizedKey = key.trim();
    final normalizedScope = scope?.trim() ?? '';
    if (normalizedKey.isEmpty) {
      throw StateError('Missing scoped variable key for bot "$botId".');
    }

    await _updateBotConfig(botId, (config) {
      final defs = config.scopedVariableDefinitions
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      final normalizedRefKey = BotConfig.normalizeScopedVariableKey(normalizedKey);
      defs.removeWhere((entry) {
        final matchesKey =
            BotConfig.normalizeScopedVariableKey(
              (entry['key'] ?? '').toString(),
            ) ==
            normalizedRefKey;
        if (!matchesKey) {
          return false;
        }
        if (normalizedScope.isEmpty) {
          return true;
        }
        return (entry['scope'] ?? '').toString().trim() == normalizedScope;
      });
      return config.copyWith(scopedVariableDefinitions: defs);
    });

    if (purgeStoredValues) {
      // The runner web layer handles the variable-store purge for us.
    }
  }

  Future<void> upsertCommand(String botId, Map<String, dynamic> command) async {
    await _updateBotCommands(botId, (commands) {
      final commandId = (command['id'] ?? '').toString().trim();
      if (commandId.isEmpty) {
        throw StateError('Missing command id for bot "$botId".');
      }
      final nextCommand = Map<String, dynamic>.from(command);
      final index = commands.indexWhere(
        (entry) => (entry['id'] ?? '').toString().trim() == commandId,
      );
      if (index >= 0) {
        commands[index] = nextCommand;
      } else {
        commands.add(nextCommand);
      }
    });
  }

  Future<void> deleteCommand(String botId, String commandId) async {
    final normalizedCommandId = commandId.trim();
    if (normalizedCommandId.isEmpty) {
      throw StateError('Missing command id for bot "$botId".');
    }
    await _updateBotCommands(botId, (commands) {
      commands.removeWhere(
        (entry) => (entry['id'] ?? '').toString().trim() == normalizedCommandId,
      );
    });
  }

  Future<void> upsertScheduledTrigger(
    String botId,
    String triggerId,
    Map<String, dynamic> trigger,
  ) async {
    await _updateBotConfig(botId, (config) {
      final nextTriggers = config.scheduledTriggers
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      final nextTrigger = Map<String, dynamic>.from(trigger)
        ..['id'] = triggerId;
      final index = nextTriggers.indexWhere(
        (entry) => (entry['id'] ?? '').toString() == triggerId,
      );
      if (index >= 0) {
        nextTriggers[index] = nextTrigger;
      } else {
        nextTriggers.add(nextTrigger);
      }
      return config.copyWith(scheduledTriggers: nextTriggers);
    }, reloadRunner: true);
  }

  Future<void> deleteScheduledTrigger(String botId, String triggerId) async {
    await _updateBotConfig(botId, (config) {
      final nextTriggers = config.scheduledTriggers
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      nextTriggers.removeWhere(
        (entry) => (entry['id'] ?? '').toString() == triggerId,
      );
      return config.copyWith(scheduledTriggers: nextTriggers);
    }, reloadRunner: true);
  }

  Future<void> upsertInboundWebhook(
    String botId,
    String webhookId,
    Map<String, dynamic> webhook,
  ) async {
    await _updateBotConfig(botId, (config) {
      final nextWebhooks = config.inboundWebhookEndpoints
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      final nextWebhook = Map<String, dynamic>.from(webhook)
        ..['id'] = webhookId;
      final index = nextWebhooks.indexWhere(
        (entry) => (entry['id'] ?? '').toString() == webhookId,
      );
      if (index >= 0) {
        nextWebhooks[index] = nextWebhook;
      } else {
        nextWebhooks.add(nextWebhook);
      }
      return config.copyWith(inboundWebhookEndpoints: nextWebhooks);
    }, reloadRunner: false);
  }

  Future<void> deleteInboundWebhook(String botId, String webhookId) async {
    await _updateBotConfig(botId, (config) {
      final nextWebhooks = config.inboundWebhookEndpoints
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: true);
      nextWebhooks.removeWhere(
        (entry) => (entry['id'] ?? '').toString() == webhookId,
      );
      return config.copyWith(inboundWebhookEndpoints: nextWebhooks);
    }, reloadRunner: false);
  }

  Future<void> _updateBotCommands(
    String botId,
    void Function(List<Map<String, dynamic>> commands) mutate,
  ) async {
    final entry = await _botStore.loadEntry(botId);
    if (entry == null) {
      throw StateError(
        'Bot "$botId" not found in store. Sync from the app first.',
      );
    }

    final nextCommands = entry.config.commands
        .map((command) => Map<String, dynamic>.from(command))
        .toList(growable: true);
    mutate(nextCommands);

    final nextConfig = entry.config.copyWith(commands: nextCommands);
    await _botStore.save(botId, entry.name, nextConfig);

    final runner = _runners[botId];
    if (runner != null) {
      if (shouldRebindEventWorkflowListeners(runner.config, nextConfig)) {
        final requiresReconnect = await runner.reloadConfig(nextConfig);
        if (requiresReconnect && nextConfig.autoRestart) {
          await _restartRunningBotWithConfig(
            botId,
            name: entry.name,
            config: nextConfig,
          );
        }
      } else {
        await runner.reloadConfig(nextConfig);
      }
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
    }
  }

  Future<void> _updateBotConfig(
    String botId,
    BotConfig Function(BotConfig config) transform, {
    bool reloadRunner = false,
  }) async {
    final entry = await _botStore.loadEntry(botId);
    if (entry == null) {
      throw StateError(
        'Bot "$botId" not found in store. Sync from the app first.',
      );
    }

    final nextConfig = transform(entry.config);
    await _botStore.save(botId, entry.name, nextConfig);

    final runner = _runners[botId];
    if (runner != null) {
      if (reloadRunner) {
        final requiresReconnect = await runner.reloadConfig(nextConfig);
        if (requiresReconnect && nextConfig.autoRestart) {
          await _restartRunningBotWithConfig(
            botId,
            name: entry.name,
            config: nextConfig,
          );
        }
      } else {
        await runner.reloadConfig(nextConfig);
      }
      _lastSeenAtByBot[botId] = DateTime.now().toUtc();
    }
  }

  Future<void> triggerInboundWebhook(
    String botId, {
    required String workflowName,
    required Map<String, dynamic> payload,
    required Map<String, String> headers,
    String? requestId,
    String? sourceIp,
  }) async {
    final runner = _runners[botId];
    if (runner == null) {
      throw StateError('Bot "$botId" is not running.');
    }
    if (!runner.config.inboundWebhooks) {
      throw StateError('Inbound webhooks are disabled for bot "$botId".');
    }

    await runner.executeInboundWebhook(
      workflowName: workflowName,
      payload: payload,
      headers: headers,
      requestId: requestId,
      sourceIp: sourceIp,
    );
    _lastSeenAtByBot[botId] = DateTime.now().toUtc();
  }

  Future<void> _restartRunningBotWithConfig(
    String botId, {
    required String name,
    required BotConfig config,
  }) async {
    final existing = _runners[botId];
    if (existing == null) {
      return;
    }

    await existing.stop();
    _runners.remove(botId);

    final replacement = DiscordRunner(botId, config, statsStore: _commandStatsStore);
    try {
      await replacement.start();
      _runners[botId] = replacement;
      _botNames[botId] = name;
      _lastErrorByBot.remove(botId);
    } catch (error) {
      _lastErrorByBot[botId] = error.toString();
      rethrow;
    }
  }

  int? _readCurrentProcessRssBytes() {
    try {
      return ProcessInfo.currentRss;
    } catch (_) {
      return null;
    }
  }
}

enum EventWorkflowListenerMode { none, messageCreateOnly, full }

EventWorkflowListenerMode resolveEventWorkflowListenerMode(BotConfig config) {
  final hasEventWorkflows =
      config.workflows.any((w) => w['workflowType'] == 'event');
  if (hasEventWorkflows) return EventWorkflowListenerMode.full;

  final hasLegacyCommands =
      config.commands.any(isLegacyCommandEnabledInConfigEntry);
  if (hasLegacyCommands) return EventWorkflowListenerMode.messageCreateOnly;

  return EventWorkflowListenerMode.none;
}

bool shouldRebindEventWorkflowListeners(
  BotConfig previous,
  BotConfig next,
) {
  final prevMode = resolveEventWorkflowListenerMode(previous);
  final nextMode = resolveEventWorkflowListenerMode(next);
  return prevMode != nextMode;
}

bool isLegacyCommandEnabledInConfigEntry(Map<String, dynamic> entry) {
  final data = entry['data'] as Map?;
  if (data == null) return false;
  final legacyMode = data['legacyModeEnabled'] == true;
  if (!legacyMode) return false;

  final type = (entry['type'] ?? data['commandType'] ?? '').toString();
  return type == 'chatInput' || type.isEmpty;
}
