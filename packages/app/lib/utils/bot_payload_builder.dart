import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/utils/database.dart';
import 'package:bot_creator/utils/premium_capabilities.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:flutter/foundation.dart';

bool get _isDesktopPlatform {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

final _appManager = AppManager();

/// Debounces and throttles synchronization requests per bot.
class _SyncBatcher {
  final Map<String, Timer> _debounceTimers = {};
  final Map<String, DateTime> _firstRequestTimes = {};

  // X values: 3s debounce (idle), 15s max wait (throttle).
  static const _debounceDuration = Duration(seconds: 3);
  static const _maxThrottleDuration = Duration(seconds: 15);

  void requestSync(String botId, Future<void> Function(String botId) syncTask) {
    _debounceTimers[botId]?.cancel();

    final now = DateTime.now();
    final firstRequest = _firstRequestTimes[botId] ?? now;
    _firstRequestTimes[botId] = firstRequest;

    final elapsedSinceFirst = now.difference(firstRequest);

    if (elapsedSinceFirst >= _maxThrottleDuration) {
      // Throttle limit reached, sync immediately.
      _debounceTimers.remove(botId);
      _performSync(botId, syncTask);
    } else {
      // Debounce: wait for idle.
      _debounceTimers[botId] = Timer(_debounceDuration, () {
        _performSync(botId, syncTask);
      });
    }
  }

  void _performSync(String botId, Future<void> Function(String botId) syncTask) {
    _firstRequestTimes.remove(botId);
    unawaited(syncTask(botId));
  }
}

final _batcher = _SyncBatcher();

/// Registers the [AppManager.onAfterSave] hook so that any command or
/// workflow save automatically pushes an updated config to the runner
/// (if one is configured and the bot is currently running).
///
/// Call this once during app initialisation.
void initRunnerAutoReload() {
  AppManager.onAfterSave = (String botId) async {
    _batcher.requestSync(botId, _executeSync);
  };
}

Future<void> _executeSync(String botId) async {
  try {
    final payload = await buildBotPayload(botId);
    final app = await _appManager.getApp(botId);
    final botName = (app['username'] ?? app['name'] ?? '').toString().trim();
    final botToken = (app['token'] ?? '').toString().trim();

    final futures = <Future<void>>[];

    // 1. Desktop Runner Sync (only on desktop platforms)
    if (_isDesktopPlatform) {
      futures.add(() async {
        try {
          final client = await RunnerSettings.createClient();
          if (client != null) {
            await client.reloadBot(botId, botName, payload);
            debugPrint('[AutoReload] Reloaded bot $botId on runner (batched).');
          }
        } catch (error) {
          debugPrint('[AutoReload] Runner reload skipped for $botId: $error');
        }
      }());
    }

    // 2. Cloud Sync (Manager)
    futures.add(() async {
      try {
        final config = await MainApiSettingsStore.loadConfig();
        if (config.isConfigured) {
          final session = await MainApiSettingsStore.loadSession();
          if (session != null && !session.isExpired) {
            final mainApiClient = MainApiClient(
              baseUrl: config.baseUrl,
              accessToken: session.accessToken,
            );
            await mainApiClient.saveDiscordBotSnapshot(
              botToken: botToken,
              config: payload,
            );
            await mainApiClient.syncBot(botId, botName, payload);
            debugPrint('[AutoReload] Synced bot $botId to cloud (batched).');
          }
        }
      } catch (error) {
        debugPrint('[AutoReload] Cloud sync failed for $botId: $error');
      }
    }());

    await Future.wait(futures);
  } catch (error) {
    debugPrint('[AutoReload] Auto-reload failed for $botId: $error');
  }
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

  final scopedVariables = await _appManager.exportScopedVariables(botId);
  final commands = await _appManager.listAppCommands(botId);

  // Evaluate premium capabilities before passing to isolate
  final inboundWebhooks = PremiumCapabilities.hasCapability(PremiumCapability.inboundWebhooks);
  final autoSharding = PremiumCapabilities.hasCapability(PremiumCapability.autoSharding);
  final autoRestart = PremiumCapabilities.hasCapability(PremiumCapability.autoRestart);

  final payloadArgs = <String, dynamic>{
    'appData': appData,
    'token': token,
    'scopedVariables': scopedVariables,
    'commands': commands,
    'inboundWebhooks': inboundWebhooks,
    'autoSharding': autoSharding,
    'autoRestart': autoRestart,
  };

  return await compute(_buildPayloadInBackground, payloadArgs);
}

/// Background worker to offload CPU-intensive JSON serialization
Map<String, dynamic> _buildPayloadInBackground(Map<String, dynamic> args) {
  final appData = args['appData'] as Map<String, dynamic>;
  final token = args['token'] as String;
  final scopedVariablesRaw = args['scopedVariables'] as Map;
  final commandsRaw = args['commands'] as List;
  final inboundWebhooks = args['inboundWebhooks'] as bool;
  final autoSharding = args['autoSharding'] as bool;
  final autoRestart = args['autoRestart'] as bool;

  final scopedVariables = <String, Map<String, Map<String, dynamic>>>{};
  for (final scopeEntry in scopedVariablesRaw.entries) {
    final scopeKey = scopeEntry.key.toString();
    final contextMapRaw = scopeEntry.value as Map;
    final contextMap = <String, Map<String, dynamic>>{};
    for (final contextEntry in contextMapRaw.entries) {
      contextMap[contextEntry.key.toString()] = Map<String, dynamic>.from(contextEntry.value as Map);
    }
    scopedVariables[scopeKey] = contextMap;
  }

  final commands = List<Map<String, dynamic>>.from(commandsRaw);

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

  final config = BotConfig(
    token: token,
    builtInLegacyHelpEnabled: appData['builtInLegacyHelpEnabled'] != false,
    inboundWebhooks: inboundWebhooks,
    autoSharding: autoSharding,
    autoRestart: autoRestart,
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
  // Decode and re-encode to ensure the object is a clean, primitive Map that can cross isolates.
  return jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>;
}
