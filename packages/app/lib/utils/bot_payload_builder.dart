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
  AppManager.onAfterSave = (String botId) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final payload = await buildBotPayload(botId);
      final app = await _appManager.getApp(botId);
      final botName = (app['username'] ?? app['name'] ?? '').toString().trim();
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
      final app = await _appManager.getApp(botId);
      final botName = (app['username'] ?? app['name'] ?? '').toString().trim();
      await client.syncCommand(botId, botName, commandId, command);
      debugPrint('[AutoReload] Synced command $commandId for bot $botId.');
    } catch (error) {
      try {
        final client = await RunnerSettings.createClient();
        if (client == null) return;
        final payload = await buildBotPayload(botId);
        final app = await _appManager.getApp(botId);
        final botName =
            (app['username'] ?? app['name'] ?? '').toString().trim();
        await client.reloadBot(botId, botName, payload);
        debugPrint(
          '[AutoReload] Command sync fallback reloaded bot $botId on runner.',
        );
      } catch (fallbackError) {
        debugPrint(
          '[AutoReload] Command sync skipped for $botId/$commandId: $error | fallback: $fallbackError',
        );
      }
    }
  };

  AppManager.onAfterCommandDelete = (String botId, String commandId) async {
    try {
      final client = await RunnerSettings.createClient();
      if (client == null) return;
      final app = await _appManager.getApp(botId);
      final botName = (app['username'] ?? app['name'] ?? '').toString().trim();
      await client.deleteCommand(botId, botName, commandId);
      debugPrint('[AutoReload] Deleted command $commandId for bot $botId.');
    } catch (error) {
      try {
        final client = await RunnerSettings.createClient();
        if (client == null) return;
        final payload = await buildBotPayload(botId);
        final app = await _appManager.getApp(botId);
        final botName =
            (app['username'] ?? app['name'] ?? '').toString().trim();
        await client.reloadBot(botId, botName, payload);
        debugPrint(
          '[AutoReload] Command delete fallback reloaded bot $botId on runner.',
        );
      } catch (fallbackError) {
        debugPrint(
          '[AutoReload] Command delete skipped for $botId/$commandId: $error | fallback: $fallbackError',
        );
      }
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
