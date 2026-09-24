import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/lavalink_config.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/utils/command_migration.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart';

/// Les drapeaux premium transmis au bot, calculés à UN SEUL endroit.
///
/// Pourquoi une fonction à part : ces quatre booléens décident de ce que le bot
/// s'autorise à faire, et ils étaient auparavant figés sur la formule du compte — donc
/// un bot exécuté sur la machine de l'utilisateur recevait « non premium » alors que
/// rien n'y coûte au serveur. Les sortir ici rend la règle vérifiable directement,
/// sans monter la base de données ni le calcul complet du payload.
///
/// Les webhooks entrants restent cadrés par la formule : ils exigent une adresse
/// publique fournie par Bot Creator, qu'un bot local n'a pas.
@visibleForTesting
({bool inboundWebhooks, bool autoSharding, bool autoRestart, bool isPremium})
premiumFlagsForBot(String? botId) {
  return (
    inboundWebhooks: premiumCapabilityAvailableForBot(
      PremiumCapability.inboundWebhooks,
      botId: botId,
    ),
    autoSharding: premiumCapabilityAvailableForBot(
      PremiumCapability.autoSharding,
      botId: botId,
    ),
    autoRestart: premiumCapabilityAvailableForBot(
      PremiumCapability.autoRestart,
      botId: botId,
    ),
    isPremium: premiumExecutionAvailableForBot(botId),
  );
}

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

  void requestSync(
    String botId,
    Future<void> Function(String botId) syncTask, {
    bool immediate = false,
  }) {
    _debounceTimers[botId]?.cancel();

    if (immediate) {
      _debounceTimers.remove(botId);
      _firstRequestTimes.remove(botId);
      _performSync(botId, syncTask);
      return;
    }

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

  void _performSync(
    String botId,
    Future<void> Function(String botId) syncTask,
  ) {
    _firstRequestTimes.remove(botId);
    unawaited(syncTask(botId));
  }
}

final _batcher = _SyncBatcher();

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
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      final payload = await buildRemotePayload(botId);
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
    if (AppManager.isSyncingFromRemote) return;
    _batcher.requestSync(botId, _executeSync);
  };

  onRefreshBotRuntime = (String botId, {bool immediate = false}) async {
    _batcher.requestSync(botId, _executeSync, immediate: immediate);
  };

  AppManager.onAfterCommandSave = (
    String botId,
    String commandId,
    Map<String, dynamic> command,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client != null) {
        final botName = await resolveBotName(botId);
        await client.syncCommand(botId, botName, commandId, command);
        debugPrint('[AutoReload] Synced command $commandId for bot $botId.');
      }
    } catch (error) {
      debugPrint('[AutoReload] Command sync on runner failed for $botId: $error');
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterCommandDelete = (String botId, String commandId) async {
    if (AppManager.isSyncingFromRemote) return;

    var deletedViaRunner = false;

    // 1. Try runner client first.
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client != null) {
        final botName = await resolveBotName(botId);
        await client.deleteCommand(botId, botName, commandId);
        debugPrint(
          '[AutoReload] Deleted command $commandId for bot $botId via runner.',
        );
        deletedViaRunner = true;
      }
    } catch (error) {
      final message = error.toString();
      if (message.contains('10063') ||
          message.contains('Unknown application command')) {
        debugPrint(
          '[AutoReload] Command $commandId already absent from Discord '
          '(runner delete skipped).',
        );
      } else {
        debugPrint(
          '[AutoReload] Command delete on runner failed for $botId: $error',
        );
      }
    }

    // 2. Fallback: delete directly via Discord REST API so the command
    //    disappears from Discord even when no runner is connected.
    if (!deletedViaRunner) {
      try {
        final appData = await _appManager.getApp(botId);
        final token = (appData['token'] ?? '').toString().trim();
        if (token.isNotEmpty) {
          final rest = await Nyxx.connectRest(token);
          try {
            await rest.commands.delete(Snowflake.parse(commandId));
            debugPrint(
              '[AutoReload] Deleted command $commandId for bot $botId '
              'directly from Discord.',
            );
          } finally {
            rest.close();
          }
        } else {
          debugPrint(
            '[AutoReload] Cannot delete command $commandId: '
            'no token available for bot $botId.',
          );
        }
      } catch (error) {
        final message = error.toString();
        // 10063 = Unknown application command — already deleted from Discord.
        // This is expected when the command was removed externally or was
        // never synced; the local delete already succeeded.
        if (message.contains('10063') ||
            message.contains('Unknown application command')) {
          debugPrint(
            '[AutoReload] Command $commandId already absent from Discord '
            '(local delete OK).',
          );
        } else {
          debugPrint(
            '[AutoReload] Direct Discord delete failed for $botId '
            'command $commandId: $error',
          );
        }
      }
    }

    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterWorkflowSave = (
    String botId,
    String workflowName,
    Map<String, dynamic> workflow,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
      _batcher.requestSync(botId, _executeSync);
      return;
    }
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client != null) {
        final botName = await resolveBotName(botId);
        await client.syncWorkflow(botId, botName, workflowName, workflow);
        debugPrint('[AutoReload] Synced workflow $workflowName for bot $botId.');
      }
    } catch (error) {
      debugPrint('[AutoReload] Workflow sync on runner failed for $botId: $error');
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterWorkflowDelete = (String botId, String workflowName) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client != null) {
        final botName = await resolveBotName(botId);
        await client.deleteWorkflow(botId, botName, workflowName);
        debugPrint('[AutoReload] Deleted workflow $workflowName for bot $botId.');
      }
    } catch (error) {
      debugPrint('[AutoReload] Workflow delete on runner failed for $botId: $error');
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterGlobalVariableSave = (
    String botId,
    String key,
    dynamic value,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.setGlobalVariable(botId, key, value);
      debugPrint('[AutoReload] Synced global variable $key for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Global variable save', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterGlobalVariableDelete = (String botId, String key) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.removeGlobalVariable(botId, key);
      debugPrint('[AutoReload] Removed global variable $key for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Global variable delete', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterGlobalVariableRename = (
    String botId,
    String oldKey,
    String newKey,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.renameGlobalVariable(botId, oldKey, newKey);
      debugPrint(
        '[AutoReload] Renamed global variable $oldKey -> $newKey for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Global variable rename', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterScopedVariableDefinitionSave = (
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
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
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterScopedVariableDefinitionDelete = (
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
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
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterScheduledTriggerSave = (
    String botId,
    String triggerId,
    Map<String, dynamic> trigger,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.syncScheduledTrigger(botId, triggerId, trigger);
      debugPrint('[AutoReload] Synced trigger $triggerId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Scheduled trigger save', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterScheduledTriggerDelete = (
    String botId,
    String triggerId,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.deleteScheduledTrigger(botId, triggerId);
      debugPrint('[AutoReload] Deleted trigger $triggerId for bot $botId.');
    } catch (error) {
      await fallbackReload(botId, 'Scheduled trigger delete', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterInboundWebhookSave = (
    String botId,
    String webhookId,
    Map<String, dynamic> webhook,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.syncInboundWebhook(botId, webhookId, webhook);
      debugPrint(
        '[AutoReload] Synced inbound webhook $webhookId for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Inbound webhook save', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };

  AppManager.onAfterInboundWebhookDelete = (
    String botId,
    String webhookId,
  ) async {
    if (AppManager.isSyncingFromRemote) return;
    try {
      final client = await RunnerSettings.createClientForBot(botId);
      if (client == null) return;
      await client.deleteInboundWebhook(botId, webhookId);
      debugPrint(
        '[AutoReload] Deleted inbound webhook $webhookId for bot $botId.',
      );
    } catch (error) {
      await fallbackReload(botId, 'Inbound webhook delete', error);
    }
    _batcher.requestSync(botId, _executeSync);
  };
}

/// LE POINT D'ENTRÉE PUBLIC DU CHEMIN LEGACY : pousser le document ENTIER d'un
/// bot par le circuit qui tourne déjà (`buildRemotePayload` → `buildBotPayload`,
/// puis relais au runner local et envoi au manager).
///
/// POURQUOI CETTE FONCTION EXISTE, ET POURQUOI ELLE N'EST PAS UNE SECONDE
/// IMPLÉMENTATION : le repli du dépôt de données (`BotDataRepository`) doit
/// rejouer une sauvegarde par le chemin EXISTANT, et ce chemin vit ici, autour
/// d'un batcher privé. Exposer une porte d'entrée qui pousse IMMÉDIATEMENT (en
/// annulant l'attente en cours pour ce bot) évite de dupliquer la construction
/// du document ou de rendre le batcher public — deux façons de laisser diverger
/// l'ancien et le nouveau chemin.
///
/// ELLE N'ATTEND PAS LA FIN DE LA POUSSÉE : `_performSync` lance la tâche sans
/// l'attendre, comme pour chaque sauvegarde de commande de l'application. Un
/// appelant qui l'attend sait que la poussée est DEMANDÉE, pas terminée.
Future<void> pushWholeBotDocumentToManager(String botId) async {
  _batcher.requestSync(botId, _executeSync, immediate: true);
}

/// LE DÉCLENCHEUR « POUSSÉE RÉUSSIE » DE LA FILE HORS-LIGNE.
///
/// Appelé APRÈS qu'un document entier a été accepté par le manager, jamais
/// avant, et JAMAIS attendu : le vidage de la file fait ses propres appels
/// réseau et ne doit pas allonger la chaîne de synchronisation.
///
/// `null` tant qu'aucun coordinateur n'est branché — strictement inerte en son
/// absence. Un crochet qui n'existe pas ne peut pas casser la synchronisation
/// d'un utilisateur, et c'est la seule forme acceptable pour un point
/// d'accroche ajouté à un chemin qui tourne déjà en production.
Future<void> Function(String botId)? onBotDocumentPushed;

Future<void> _executeSync(String botId) async {
  try {
    final engine = await getBotRuntimeEngine(botId);
    if (engine == runtimeEngineJavascript) {
      try {
        await validateJsBotPayloadOrThrow(botId);
      } catch (error) {
        debugPrint('[AutoReload] JS payload not ready for $botId: $error');
        return;
      }
    }
    final payload = await buildRemotePayload(botId);
    final app = await _appManager.getApp(botId);
    final botName = (app['username'] ?? app['name'] ?? '').toString().trim();
    final botToken = (app['token'] ?? '').toString().trim();

    final futures = <Future<void>>[];

    // 0. Local Desktop Runtime Sync (internal session)
    if (_isDesktopPlatform) {
      applyDesktopRuntimeSettings(botId: botId, appData: app);
    }

    // 1. Desktop Runner Sync (only on desktop platforms)
    if (_isDesktopPlatform) {
      futures.add(() async {
        try {
          final isRunningInApp = isDesktopBotRunningId(botId);
          final config = await RunnerSettings.getConfig();
          final url = config?.url ?? '';
          final isLocalRunner = url.contains('localhost') || url.contains('127.0.0.1');

          if (isRunningInApp && isLocalRunner) {
            debugPrint(
              '[AutoReload] Sync skipped for $botId: bot is running internally and runner is local.',
            );
            return;
          }

          final client = await RunnerSettings.createClientForBot(botId);
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
            // Note: saveDiscordBotSnapshot and syncBot now benefit from 
            // internal caching if implemented in MainApiClient or similar.
            await mainApiClient.saveDiscordBotSnapshot(
              botId: botId,
              botToken: botToken,
              config: payload,
            );
            await mainApiClient.syncBot(botId, botName, payload);
            debugPrint('[AutoReload] Synced bot $botId to cloud (batched).');
            // La poussée a été ACCEPTÉE : c'est la preuve la plus fraîche que
            // le manager répond. On en profite pour vider la file hors-ligne,
            // sans l'attendre (voir [onBotDocumentPushed]).
            final outboxPushHook = onBotDocumentPushed;
            if (outboxPushHook != null) {
              unawaited(
                outboxPushHook(botId).catchError((Object error) {
                  debugPrint(
                    '[AutoReload] Outbox drain skipped for $botId: $error',
                  );
                }),
              );
            }
          }
        }
      } catch (error) {
        if (_isTransientNetworkError(error)) {
          debugPrint('[AutoReload] Cloud sync skipped for $botId (offline).');
        } else {
          debugPrint('[AutoReload] Cloud sync failed for $botId: $error');
        }
      }
    }());

    // 3. Mobile Service Sync (only on mobile)
    if (!_isDesktopPlatform) {
      futures.add(syncMobileBotConfigWithService(botId));
    }

    await Future.wait(futures);
  } catch (error) {
    debugPrint('[AutoReload] Auto-reload failed for $botId: $error');
  }
}

/// Builds the config payload appropriate for the bot runtime engine.
Future<Map<String, dynamic>> buildRemotePayload(String botId) async {
  final engine = await getBotRuntimeEngine(botId);
  if (engine == runtimeEngineJavascript) {
    return buildJsBotPayload(botId);
  }
  return buildBotPayload(botId);
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

  var intentsChanged = false;
  try {
    intentsChanged = await refreshAppIntentsFromPortal(
      botId: botId,
      appData: appData,
      token: token,
    );
    if (intentsChanged) {
      await _appManager.invalidatePayloadCache(botId);
    }
  } catch (e) {
    if (_isTransientNetworkError(e)) {
      debugPrint(
        '[buildBotPayload] Offline — skipping Discord app flags fetch.',
      );
    } else {
      debugPrint('[buildBotPayload] Failed to fetch app flags for intents: $e');
    }
  }

  final cached = await _appManager.getCachedPayload(botId);
  if (cached != null && !intentsChanged) {
    return cached;
  }

  final scopedVariables = await _appManager.exportScopedVariables(botId);
  final commands = await _appManager.listAppCommands(botId);

  // Evaluate premium capabilities before passing to isolate
  final premiumFlags = premiumFlagsForBot(botId);
  final lavalinkConfigRaw = appData['lavalinkConfig'] as Map<String, dynamic>?;

  final payloadArgs = <String, dynamic>{
    'appData': appData,
    'token': token,
    'scopedVariables': scopedVariables,
    'commands': commands,
    'inboundWebhooks': premiumFlags.inboundWebhooks,
    'autoSharding': premiumFlags.autoSharding,
    'autoRestart': premiumFlags.autoRestart,
    'isPremium': premiumFlags.isPremium,
    'lavalinkConfig': lavalinkConfigRaw,
  };

  final payload = await compute(_buildPayloadInBackground, payloadArgs);
  await _appManager.saveCachedPayload(botId, payload);
  return payload;
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
  final isPremium = args['isPremium'] as bool;
  final lavalinkConfigRaw = args['lavalinkConfig'] as Map<String, dynamic>?;

  final scopedVariables = <String, Map<String, Map<String, dynamic>>>{};
  for (final scopeEntry in scopedVariablesRaw.entries) {
    final scopeKey = scopeEntry.key.toString();
    final contextMapRaw = scopeEntry.value as Map;
    final contextMap = <String, Map<String, dynamic>>{};
    for (final contextEntry in contextMapRaw.entries) {
      contextMap[contextEntry.key.toString()] = Map<String, dynamic>.from(
        contextEntry.value as Map,
      );
    }
    scopedVariables[scopeKey] = contextMap;
  }

  final commands = List<Map<String, dynamic>>.from(commandsRaw);

  // Optimize command payloads by stripping legacy response/simpleConfig keys
  // from migrated commands before transmission.
  stripMigratedCommandData(commands);

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
    (appData['inboundWebhooks'] is List ? appData['inboundWebhooks'] as List? : null)
        ?.whereType<Map>().map(
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
    prefix: (appData['prefix'] ?? '!').toString(),
    presenceStatus: (appData['presenceStatus'] ?? 'online').toString(),
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
  final configJson = jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>;
  // Lavalink : schéma FIGÉ (contrat avec le runner) — `enabled` + `custom_servers`,
  // jamais l'ancienne forme `lavalinkConfig`.
  applyLavalinkSchema(configJson, lavalinkConfigRaw);
  configJson['isPremium'] = isPremium;
  return configJson;
}

bool _isTransientNetworkError(Object error) {
  final message = error.toString();
  return message.contains('SocketException') ||
      message.contains('Failed host lookup') ||
      message.contains('ClientException');
}
