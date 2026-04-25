import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/utils/app_storage_directory.dart';
import 'package:bot_creator/utils/database.dart';
import 'package:bot_creator/utils/premium_capabilities.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:flutter/foundation.dart';

final _appManager = AppManager();

/// Registers the runner sync hooks so that command saves use localized
/// updates while broader bot saves still fall back to a full reload.
///
/// Call this once during app initialisation.
void initRunnerAutoReload() {
  Future<String> resolveBotName(String botId) async {
    final app = await _appManager.getApp(botId);
    return (app['username'] ?? app['name'] ?? '').toString().trim();
  }

  Future<void> fallbackReload(
    String botId,
    String context,
    Object error,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final payload = await buildBotPayload(botId);
      final botName = await resolveBotName(botId);
      await client.reloadBot(botId, botName, payload);
      debugPrint(
        '[AutoReload] $context fallback reloaded bot $botId on runner.',
      );
    } catch (fallbackError) {
      debugPrint(
        '[AutoReload] $context skipped for $botId: $error | fallback: $fallbackError',
      );
    }
  }

  AppManager.onAfterSave = (String botId) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final payload = await buildBotPayload(botId);
      final botName = await resolveBotName(botId);
      await client.reloadBot(botId, botName, payload);
      debugPrint('[AutoReload] Reloaded bot $botId on runner.');
    } catch (error) {
      // Silent best-effort: runner may be offline or bot may not be running.
      debugPrint('[AutoReload] Runner reload skipped for $botId: $error');
    }
  };

  AppManager.onAfterCommandSave = (
    String botId,
    String commandId,
    Map<String, dynamic> command,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final botName = await resolveBotName(botId);
      await client.syncCommand(botId, botName, commandId, command);
      debugPrint('[AutoReload] Synced command $commandId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Command sync', error);
    }
  };

  AppManager.onAfterCommandDelete = (String botId, String commandId) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final botName = await resolveBotName(botId);
      await client.deleteCommand(botId, botName, commandId);
      debugPrint('[AutoReload] Deleted command $commandId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Command delete', error);
    }
  };

  AppManager.onAfterWorkflowSave = (
    String botId,
    String workflowName,
    Map<String, dynamic> workflow,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final botName = await resolveBotName(botId);
      await client.syncWorkflow(botId, botName, workflowName, workflow);
      debugPrint('[AutoReload] Synced workflow $workflowName for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Workflow sync', error);
    }
  };

  AppManager.onAfterWorkflowDelete = (String botId, String workflowName) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final botName = await resolveBotName(botId);
      await client.deleteWorkflow(botId, botName, workflowName);
      debugPrint('[AutoReload] Deleted workflow $workflowName for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Workflow delete', error);
    }
  };

  AppManager.onAfterGlobalVariableSave = (
    String botId,
    String key,
    dynamic value,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.setGlobalVariable(botId, key, value);
      debugPrint('[AutoReload] Synced global variable $key for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Global variable save', error);
    }
  };

  AppManager.onAfterGlobalVariableDelete = (String botId, String key) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.removeGlobalVariable(botId, key);
      debugPrint('[AutoReload] Removed global variable $key for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Global variable delete', error);
    }
  };

  AppManager.onAfterGlobalVariableRename = (
    String botId,
    String oldKey,
    String newKey,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.renameGlobalVariable(botId, oldKey, newKey);
      debugPrint(
        '[AutoReload] Renamed global variable $oldKey -> $newKey for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Global variable rename', error);
    }
  };

  AppManager.onAfterScopedVariableDefinitionSave = (
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.setScopedVariableDefinition(
        botId,
        key,
        scope,
        defaultValue,
        valueType: valueType,
      );
      debugPrint(
        '[AutoReload] Synced scoped definition $scope/$key for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Scoped definition save', error);
    }
  };

  AppManager.onAfterScopedVariableDefinitionDelete = (
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.removeScopedVariableDefinition(
        botId,
        key,
        scope: scope,
        purgeStoredValues: purgeStoredValues,
      );
      debugPrint(
        '[AutoReload] Removed scoped definition ${scope ?? "*"}/$key for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Scoped definition delete', error);
    }
  };

  AppManager.onAfterScheduledTriggerSave = (
    String botId,
    String triggerId,
    Map<String, dynamic> trigger,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.syncScheduledTrigger(botId, triggerId, trigger);
      debugPrint('[AutoReload] Synced trigger $triggerId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Scheduled trigger save', error);
    }
  };

  AppManager.onAfterScheduledTriggerDelete = (
    String botId,
    String triggerId,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.deleteScheduledTrigger(botId, triggerId);
      debugPrint('[AutoReload] Deleted trigger $triggerId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Scheduled trigger delete', error);
    }
  };

  AppManager.onAfterInboundWebhookSave = (
    String botId,
    String webhookId,
    Map<String, dynamic> webhook,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.syncInboundWebhook(botId, webhookId, webhook);
      debugPrint('[AutoReload] Synced inbound webhook $webhookId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Inbound webhook save', error);
    }
  };

  AppManager.onAfterInboundWebhookDelete = (
    String botId,
    String webhookId,
  ) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      await client.deleteInboundWebhook(botId, webhookId);
      debugPrint('[AutoReload] Deleted inbound webhook $webhookId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Inbound webhook delete', error);
    }
  };
}

/// Assembles a [BotConfig] JSON payload for a given bot by reading all data
/// from [AppManager] (app details, global variables, workflows, statuses) and
/// loading every command from its individual file under `apps/{botId}/`.
///
/// This payload can be pushed to the runner via [RunnerClient.syncBot].
Future<Map<String, dynamic>> buildBotPayload(String botId) async {
  final appData = await _appManager.getApp(botId);
  if (appData.isEmpty) {
    throw StateError('Bot "$botId" not found in local storage.');
  }

  final token = (appData['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    throw StateError('Bot "$botId" has no token configured.');
  }

  final intents = Map<String, bool>.from(
    (appData['intents'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v == true),
        ) ??
        const {},
  );

  final globalVariables = Map<String, dynamic>.from(
    (appData['globalVariables'] as Map?)?.map(
          (k, v) => MapEntry(k.toString(), v),
        ) ??
        const <String, dynamic>{},
  );
  final scopedVariables = await _appManager.exportScopedVariables(botId);
  final scopedVariableDefinitions = List<Map<String, dynamic>>.from(
    (appData['scopedVariableDefinitions'] as List?)?.whereType<Map>().map(
          (entry) => Map<String, dynamic>.from(entry),
        ) ??
        const <Map<String, dynamic>>[],
  );

  final workflows = List<Map<String, dynamic>>.from(
    (appData['workflows'] as List?)?.whereType<Map>().map(
          (w) => Map<String, dynamic>.from(w),
        ) ??
        const [],
  );

  final scheduledTriggers = List<Map<String, dynamic>>.from(
    (appData['scheduledTriggers'] as List?)?.whereType<Map>().map(
          (entry) => Map<String, dynamic>.from(entry),
        ) ??
        const [],
  );

  final inboundWebhookEndpoints = List<Map<String, dynamic>>.from(
    (appData['inboundWebhooks'] as List?)?.whereType<Map>().map(
          (entry) => Map<String, dynamic>.from(entry),
        ) ??
        const [],
  );

  final statuses =
      ((appData['activities'] ?? appData['statuses']) as List?)
          ?.whereType<Map>()
          .map((s) => BotStatusConfig.fromJson(Map<String, dynamic>.from(s)))
          .toList(growable: false) ??
      const <BotStatusConfig>[];

  final commands = await _loadAllCommands(botId);

  final config = BotConfig(
    token: token,
    builtInLegacyHelpEnabled: appData['builtInLegacyHelpEnabled'] != false,
    inboundWebhooks: PremiumCapabilities.hasCapability(
      PremiumCapability.inboundWebhooks,
    ),
    autoSharding: PremiumCapabilities.hasCapability(
      PremiumCapability.autoSharding,
    ),
    autoRestart: PremiumCapabilities.hasCapability(
      PremiumCapability.autoRestart,
    ),
    username:
        (appData['username'] ?? '').toString().trim().isEmpty
            ? null
            : appData['username'].toString().trim(),
    avatarPath:
        (appData['avatar'] ?? '').toString().trim().isEmpty
            ? null
            : appData['avatar'].toString().trim(),
    intents: intents,
    globalVariables: globalVariables,
    scopedVariables: scopedVariables,
    scopedVariableDefinitions: scopedVariableDefinitions,
    workflows: workflows,
    scheduledTriggers: scheduledTriggers,
    inboundWebhookEndpoints: inboundWebhookEndpoints,
    statuses: statuses,
    commands: commands,
  );

  config.validate();
  return config.toJson();
}

/// Reads all command JSON files from the `apps/{botId}/` sub-directory.
Future<List<Map<String, dynamic>>> _loadAllCommands(String botId) async {
  final docsDir = await getAppStorageDirectory();
  final commandDir = Directory('${docsDir.path}/apps/$botId');

  if (!await commandDir.exists()) return const [];

  final commands = <Map<String, dynamic>>[];

  await for (final entity in commandDir.list()) {
    if (entity is File && entity.path.endsWith('.json')) {
      try {
        final raw = await entity.readAsString();
        if (raw.isNotEmpty) {
          final decoded = jsonDecode(raw);
          if (decoded is Map) {
            commands.add(Map<String, dynamic>.from(decoded));
          }
        }
      } catch (_) {
        // Skip corrupt command files — the runner will just not register them.
      }
    }
  }

  return commands;
}
