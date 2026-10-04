import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_bindings.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:bot_creator/core/storage/sqlite_variable_store.dart';
import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/string_sanitizer.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart'
    as normalize_lib;
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:nyxx/nyxx.dart';

class AppManager implements BotDataStore {
  static bool _legacyRemoteSync = false;
  static int _remoteSyncDepth = 0;
  static bool get isSyncingFromRemote =>
      _legacyRemoteSync || _remoteSyncDepth > 0;
  static set isSyncingFromRemote(bool value) => _legacyRemoteSync = value;

  /// Nested and concurrent imports must not reactivate outbound hooks early.
  static VoidCallback beginRemoteSync() {
    _remoteSyncDepth++;
    var released = false;
    return () {
      if (released) return;
      released = true;
      _remoteSyncDepth--;
    };
  }

  static final AppManager _instance = AppManager._internal();
  factory AppManager() => _instance;

  /// Optional hook called after non-command saves that should trigger a full
  /// runner reload.
  ///
  /// Set this once at app startup (e.g. in main.dart) with a closure that
  /// builds the bot payload and calls [RunnerClient.reloadBot].
  /// The hook must be a no-throw fire-and-forget operation.
  static Future<void> Function(String botId)? onAfterSave;

  /// Optional hook called after a single command save.
  static Future<void> Function(
    String botId,
    String commandId,
    Map<String, dynamic> command,
  )?
  onAfterCommandSave;

  /// Optional hook called after a single command delete.
  static Future<void> Function(
    String botId,
    String commandId, {
    String? discordId,
  })?
  onAfterCommandDelete;

  /// Optional hook called after a workflow save.
  static Future<void> Function(
    String botId,
    String workflowName,
    Map<String, dynamic> workflow,
  )?
  onAfterWorkflowSave;

  /// Optional hook called after a workflow delete.
  static Future<void> Function(String botId, String workflowName)?
  onAfterWorkflowDelete;

  /// Optional hook called after a global variable save or rename.
  static Future<void> Function(String botId, String key, dynamic value)?
  onAfterGlobalVariableSave;

  /// Optional hook called after a global variable delete.
  static Future<void> Function(String botId, String key)?
  onAfterGlobalVariableDelete;

  /// Optional hook called after a global variable rename.
  static Future<void> Function(String botId, String oldKey, String newKey)?
  onAfterGlobalVariableRename;

  /// Optional hook called after a scoped variable definition save.
  static Future<void> Function(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType,
  })?
  onAfterScopedVariableDefinitionSave;

  /// Optional hook called after a scoped variable definition delete.
  static Future<void> Function(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues,
  })?
  onAfterScopedVariableDefinitionDelete;

  static Future<void> Function(
    String botId,
    String triggerId,
    Map<String, dynamic> trigger,
  )?
  onAfterScheduledTriggerSave;

  static Future<void> Function(String botId, String triggerId)?
  onAfterScheduledTriggerDelete;

  static Future<void> Function(
    String botId,
    String webhookId,
    Map<String, dynamic> webhook,
  )?
  onAfterInboundWebhookSave;

  static Future<void> Function(String botId, String webhookId)?
  onAfterInboundWebhookDelete;

  final StreamController<List<dynamic>> _appsStreamController =
      StreamController<List<dynamic>>.broadcast();
  List<dynamic> _apps = [];
  bool _initialized = false;
  bool get isInitialized => _initialized;
  List<dynamic> get currentApps => List.unmodifiable(_apps);
  late SqliteVariableStore _variableStore;
  bool _sqliteAvailable = false;
  final Map<String, Future<void>> _appWriteChains = <String, Future<void>>{};
  final Map<String, List<Map<String, dynamic>>> _commandListCache =
      <String, List<Map<String, dynamic>>>{};
  final Map<String, Map<String, dynamic>> _payloadCache =
      <String, Map<String, dynamic>>{};

  AppManager._internal() {
    unawaited(_init());
  }

  static Future<String> _path() => getAppStoragePath();

  Future<String> get path async => getAppStoragePath();

  Future<void> _init() async {
    final path = await _path();
    final appsDir = Directory("$path/apps");
    if (!await appsDir.exists()) {
      await appsDir.create(recursive: true);
    }

    try {
      _variableStore = SqliteVariableStore();
      await _variableStore.init();
      _sqliteAvailable = true;
    } catch (error) {
      _sqliteAvailable = false;
      debugPrint(
        '[AppManager._init] SQLite init failed: $error\n'
        '[AppManager._init] Falling back to JSON scoped variable store.',
      );
    }

    try {
      await getAllApps();
      // Une passe de nettoyage au chargement : les versions précédentes de
      // l'écran de déploiement enregistraient un bot clé en main comme un bot
      // LOCAL (marqueur `is_turnkey` / `type: 'turnkey'`). Ces entrées ne sont pas
      // des bots : elles sont supprimées ici, une seule fois, sans toucher aux
      // vrais bots configurés. Voir [purgeTurnkeyAppEntries].
      final purged = await purgeTurnkeyAppEntries();
      if (purged > 0) {
        debugPrint(
          '[AppManager._init] $purged entrée(s) clé en main (faux bots locaux) '
          'supprimée(s).',
        );
      }
      await _writeWorkflowCompatibilityReportIfDebug();
    } catch (error) {
      debugPrint('[AppManager._init] App list load failed: $error');
      _apps = [];
    } finally {
      _initialized = true;
    }

    _appsStreamController.add(_apps);
    _startStreamUpdateLoop();
  }

  void _startStreamUpdateLoop() async {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      _appsStreamController.add(_apps);
    }
  }

  Future<File> createOrUpdateApp({
    required Snowflake id,
    required String username,
    String? avatarHash,
    String? discriminator,
    required String token,
    Map<String, bool>? intents,
    String? prefix,
    int? approximateGuildCount,
    bool notifyRuntime = true,
  }) async {
    final botId = id.toString();
    return await _enqueueAppWrite(botId, () async {
      final path = await _path();
      final file = File("$path/apps/$botId.json");
      final allAppsFile = File("$path/apps/all_apps.json");
      Map<String, dynamic> existingData = <String, dynamic>{};
      if (await file.exists()) {
        final existingContent = await file.readAsString();
        if (existingContent.isNotEmpty) {
          existingData = Map<String, dynamic>.from(
            jsonDecode(existingContent) as Map<String, dynamic>,
          );
        }
      }

      final existingAvatar = existingData['avatar']?.toString();
      final avatarUri =
          (avatarHash == null &&
              discriminator == null &&
              existingAvatar != null &&
              existingAvatar.isNotEmpty &&
              !existingAvatar.contains('https://cdn.discordapp.com/avatars/'))
          ? existingAvatar
          : makeAvatarUrl(
              botId,
              avatarId: avatarHash ?? existingAvatar,
              discriminator: discriminator,
            );

      // Le jeton reçu peut être VIDE sans que le bot soit sans jeton : le manager
      // RÉDIGE volontairement `bot_token` dans ses listes (« Zero plaintext token in
      // summary lists », et son propre test l'exige), et un jeton ne redescend jamais du
      // serveur. Écraser la valeur locale par du vide détruirait le seul jeton dont
      // dispose ce poste de travail pour exécuter le bot en local — c'est arrivé :
      // l'entrée de coffre est passée de 137 octets (jeton réel) à 41 (chaîne vide) à la
      // première synchro, puis « Token invalid or missing » sur tous les bots.
      // On garde donc le jeton déjà connu quand l'appel n'en apporte pas. Un effacement
      // volontaire passe par la suppression de l'application, pas par une synchro.
      var effectiveToken = token.trim();
      if (effectiveToken.isEmpty) {
        effectiveToken = (existingData['token'] ?? '').toString().trim();
      }
      if (effectiveToken.isEmpty) {
        try {
          final secure = await SecureStorageService.instance;
          effectiveToken = ((await secure.read('bot_token:$botId')) ?? '')
              .trim();
        } catch (_) {
          // Coffre indisponible : on continue sans jeton plutôt que d'échouer.
        }
      }

      final data = Map<String, dynamic>.from(existingData)
        ..['bdfdUserVariableSemantics'] = existingData.isEmpty
            ? 2
            : (existingData['bdfdUserVariableSemantics'] ?? 1)
        ..['name'] = username.sanitizedUtf16
        ..['id'] = botId
        ..['avatar'] = avatarUri
        ..['token'] = effectiveToken
        ..['prefix'] = () {
          final raw = (prefix ?? existingData['prefix'] ?? '!')
              .toString()
              .trim();
          return raw.isEmpty ? '!' : raw;
        }()
        ..['createdAt'] =
            existingData['createdAt'] ?? DateTime.now().toIso8601String()
        ..['intents'] = intents ?? existingData['intents'] ?? {}
        ..['approximate_guild_count'] =
            approximateGuildCount ?? existingData['approximate_guild_count']
        ..['guild_count'] =
            approximateGuildCount ??
            existingData['guild_count'] ??
            existingData['approximate_guild_count']
        ..['globalVariables'] = Map<String, dynamic>.from(
          (existingData['globalVariables'] as Map?)?.cast<String, dynamic>() ??
              const {},
        )
        ..['scopedVariables'] = Map<String, dynamic>.from(
          (existingData['scopedVariables'] as Map?)?.cast<String, dynamic>() ??
              const {},
        )
        ..['scopedVariableDefinitions'] = List<Map<String, dynamic>>.from(
          ((existingData['scopedVariableDefinitions']) as List?)
                  ?.whereType<Map>()
                  .map((entry) => Map<String, dynamic>.from(entry)) ??
              const <Map<String, dynamic>>[],
        )
        ..['workflows'] = List<Map<String, dynamic>>.from(
          _coerceWorkflowList(existingData['workflows']),
        )
        ..['scheduledTriggers'] = List<Map<String, dynamic>>.from(
          ((existingData['scheduledTriggers']) as List?)?.whereType<Map>().map(
                (entry) => Map<String, dynamic>.from(entry),
              ) ??
              const <Map<String, dynamic>>[],
        )
        ..['statuses'] = List<Map<String, dynamic>>.from(
          (existingData['statuses'] as List?)?.whereType<Map>().map(
                (status) => Map<String, dynamic>.from(status),
              ) ??
              const <Map<String, dynamic>>[],
        )
        ..['activities'] = List<Map<String, dynamic>>.from(
          ((existingData['activities'] ?? existingData['statuses']) as List?)
                  ?.whereType<Map>()
                  .map((activity) => Map<String, dynamic>.from(activity)) ??
              const <Map<String, dynamic>>[],
        );

      // `_writeAppToDisk` dépose le jeton dans le coffre AVANT d'écrire le
      // fichier, et JAMAIS une valeur vide : une chaîne vide écraserait le jeton
      // local (voir le commentaire plus haut sur la rédaction côté manager).
      await _writeAppToDisk(botId, data);
      if (!await allAppsFile.exists()) {
        await allAppsFile.create(recursive: true);
      }

      final appsList = await getAllApps();
      final index = appsList.indexWhere((a) => a['id'] == botId);
      if (index >= 0) {
        appsList[index]['name'] = username;
        appsList[index]['avatar'] = avatarUri;
        if (approximateGuildCount != null) {
          appsList[index]['approximate_guild_count'] = approximateGuildCount;
          appsList[index]['guild_count'] = approximateGuildCount;
        }
      } else {
        appsList.add({
          'name': username,
          'avatar': avatarUri,
          'id': botId,
          'approximate_guild_count': ?approximateGuildCount,
          'guild_count': ?approximateGuildCount,
        });
      }

      await allAppsFile.writeAsString(jsonEncode(appsList));
      _apps = appsList;
      _appsStreamController.add(appsList);
      await invalidatePayloadCache(botId);
      if (notifyRuntime) {
        unawaited((onAfterSave ?? (_) async {}).call(botId));
      }
      return file;
    });
  }

  /// Deletes a bot completely: cloud API (S3 + manager) then local files.
  ///
  /// This should be the single entry point for bot deletion to ensure
  /// no orphaned data remains on the cloud or device.
  Future<void> deleteBotCompletely(String botId) async {
    // 1. Cloud delete — tells the API Manager to remove the bot
    //    and clean up S3 / managed variables.
    try {
      final config = await MainApiSettingsStore.loadConfig();
      if (config.isConfigured) {
        final session = await MainApiSettingsStore.loadSession();
        if (session != null && !session.isExpired) {
          final client = MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );
          await client.deleteBot(botId);
          debugPrint('[AppManager] Bot $botId deleted from cloud.');
        }
      }
    } catch (e) {
      debugPrint('[AppManager] Cloud bot deletion failed (continuing): $e');
    }

    // 2. Local delete — removes local files and tombstone-records.
    await deleteApp(botId);
  }

  /// Vrai si l'entrée locale [app] n'est PAS un bot configuré mais un bot clé en
  /// main (un conteneur) enregistré par erreur comme bot local.
  ///
  /// Seul ce marqueur explicite compte : `is_turnkey: true` ou `type: 'turnkey'`.
  /// On ne se fie PAS à la présence d'un `container_id` — un vrai bot ne doit
  /// jamais être pris pour un conteneur, ni disparaître.
  static bool isTurnkeyAppEntry(Map<dynamic, dynamic> app) {
    if (app['is_turnkey'] == true) return true;
    return app['type']?.toString().trim().toLowerCase() == 'turnkey';
  }

  /// Supprime, en UNE passe, les entrées locales marquées clé en main
  /// (voir [isTurnkeyAppEntry]) : un bot clé en main est un conteneur, il n'a
  /// aucune configuration à éditer ni token à conserver localement.
  ///
  /// Ne touche à AUCUNE entrée sans ce marqueur : un vrai bot configuré ne doit
  /// jamais disparaître. Retourne le nombre d'entrées supprimées.
  Future<int> purgeTurnkeyAppEntries() async {
    final apps = await getAllApps();
    final doomed = <String>[
      for (final raw in apps)
        if (raw is Map &&
            isTurnkeyAppEntry(raw) &&
            (raw['id'] ?? '').toString().trim().isNotEmpty)
          (raw['id']).toString().trim(),
    ];
    if (doomed.isEmpty) return 0;

    for (final id in doomed) {
      // Pas de pierre tombale (`_deleted_bots.json`) : cette entrée n'était pas
      // un bot, il n'y a rien à « laisser supprimé » — et une tombale portant
      // l'ID Discord du bot effacerait le vrai bot si l'utilisateur le configure
      // ensuite.
      await deleteApp(id, recordTombstone: false);
    }
    debugPrint(
      '[AppManager] purgeTurnkeyAppEntries: ${doomed.length} entrée(s) clé en '
      'main supprimée(s) : ${doomed.join(', ')}',
    );
    return doomed.length;
  }

  Future<void> deleteApp(String id, {bool recordTombstone = true}) async {
    final path = await _path();
    final appFile = File("$path/apps/$id.json");
    if (await appFile.exists()) {
      await appFile.delete();
    }
    final statsFile = File("$path/apps/$id.command_stats.json");
    if (await statsFile.exists()) {
      await statsFile.delete();
    }
    final appDirectory = Directory("$path/apps/$id");
    if (await appDirectory.exists()) {
      await appDirectory.delete(recursive: true);
    }
    await invalidatePayloadCache(id);
    final allAppsFile = File("$path/apps/all_apps.json");
    if (!await allAppsFile.exists()) return;

    final content = await allAppsFile.readAsString();
    final appsList = content.isNotEmpty
        ? jsonDecode(content) as List<dynamic>
        : [];
    appsList.removeWhere((a) => a['id'] == id);

    await allAppsFile.writeAsString(jsonEncode(appsList));
    _apps = appsList;
    _appsStreamController.add(appsList);

    // Record deletion in tombstone file so bot stays deleted after restore
    // (`recordTombstone: false` pour un nettoyage : un faux bot n'a pas de
    // suppression à mémoriser, sinon le vrai bot du même ID serait effacé plus tard).
    if (recordTombstone) {
      await _recordDeletion(path, id);
    }
  }

  Future<void> _recordDeletion(String path, String botId) async {
    final deletedFile = File("$path/apps/_deleted_bots.json");
    Map<String, dynamic> deleted = <String, dynamic>{};
    if (await deletedFile.exists()) {
      try {
        final raw = await deletedFile.readAsString();
        final decoded = raw.isNotEmpty ? jsonDecode(raw) : null;
        if (decoded is Map) {
          deleted = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    deleted[botId] = DateTime.now().toUtc().toIso8601String();
    await deletedFile.writeAsString(jsonEncode(deleted));
  }

  /// Re-applies deletions recorded in _deleted_bots.json after a restore.
  Future<void> reapDeletedBots() async {
    final path = await _path();
    final deletedFile = File("$path/apps/_deleted_bots.json");
    if (!await deletedFile.exists()) return;

    Map<String, dynamic> deleted;
    try {
      final raw = await deletedFile.readAsString();
      final decoded = raw.isNotEmpty ? jsonDecode(raw) : null;
      if (decoded is! Map) return;
      deleted = Map<String, dynamic>.from(decoded);
    } catch (_) {
      return;
    }

    for (final botId in deleted.keys) {
      final appFile = File("$path/apps/$botId.json");
      if (await appFile.exists()) {
        await appFile.delete();
      }
      final appDirectory = Directory("$path/apps/$botId");
      if (await appDirectory.exists()) {
        await appDirectory.delete(recursive: true);
      }
    }

    // Rebuild the app index without the deleted bots
    final rebuilt = await _rebuildAppsIndexFromFiles(path);
    _apps = rebuilt;
    _appsStreamController.add(rebuilt);
  }

  Future<List<dynamic>> _rebuildAppsIndexFromFiles(String path) async {
    final appsDir = Directory("$path/apps");
    if (!await appsDir.exists()) {
      return const <dynamic>[];
    }

    final appsList = <Map<String, dynamic>>[];
    await for (final entity in appsDir.list()) {
      if (entity is! File ||
          !entity.path.endsWith('.json') ||
          entity.path.endsWith('all_apps.json') ||
          entity.path.endsWith('_deleted_bots.json') ||
          entity.path.endsWith('command_stats.json') ||
          entity.path.endsWith('payload.json')) {
        continue;
      }

      try {
        final content = await entity.readAsString();
        if (content.isEmpty) {
          continue;
        }

        final decoded = jsonDecode(content);
        if (decoded is! Map || decoded['id'] == null) {
          continue;
        }

        final app = Map<String, dynamic>.from(decoded);
        final rawAvatar = (app['avatar'] ?? '').toString();
        final cleanAvatar = rawAvatar.isNotEmpty
            ? makeAvatarUrl(app['id'].toString(), avatarId: rawAvatar)
            : '';
        appsList.add(<String, dynamic>{
          'id': app['id'].toString(),
          'name': (app['name'] ?? 'Unknown').toString(),
          'avatar': cleanAvatar,
          if (app['guild_count'] != null) 'guild_count': app['guild_count'],
          if (app['approximate_guild_count'] != null)
            'approximate_guild_count': app['approximate_guild_count'],
        });
      } catch (_) {}
    }

    final allAppsFile = File("$path/apps/all_apps.json");
    await allAppsFile.writeAsString(jsonEncode(appsList));
    return appsList;
  }

  Future<List<dynamic>> getAllApps() async {
    final path = await _path();
    final allAppsFile = File("$path/apps/all_apps.json");

    if (await allAppsFile.exists()) {
      try {
        final content = await allAppsFile.readAsString();
        final decoded = content.isNotEmpty ? jsonDecode(content) : const [];
        if (decoded is List) {
          final appsList = decoded.whereType<Map>().map((raw) {
            final m = Map<String, dynamic>.from(raw);
            final botId = (m['id'] ?? '').toString();
            final rawAvatar = (m['avatar'] ?? '').toString();
            if (botId.isNotEmpty &&
                rawAvatar.contains('https://cdn.discordapp.com/avatars/')) {
              m['avatar'] = makeAvatarUrl(botId, avatarId: rawAvatar);
            }
            return m;
          }).toList();
          if (appsList.isNotEmpty) {
            _apps = appsList;
            return appsList;
          }
        }
      } catch (_) {}
    }

    final rebuilt = await _rebuildAppsIndexFromFiles(path);
    _apps = rebuilt;
    return rebuilt;
  }

  Stream<List<dynamic>> getAppStream() => _appsStreamController.stream;

  Future<void> refreshApps() async {
    debugPrint('[AppManager] Refreshing app list...');
    final apps = await getAllApps();
    debugPrint('[AppManager] Apps loaded from disk: ${apps.length} app(s)');
    for (final app in apps) {
      debugPrint('[AppManager]   - ${app['name'] ?? 'Unknown'} (${app['id']})');
    }
    _appsStreamController.add(apps);
    debugPrint('[AppManager] Stream updated with ${apps.length} app(s)');
  }

  Future<void> clearLogs(String id) async {
    final path = await _path();
    final logsFile = File("$path/apps/$id/logs.json");
    if (await logsFile.exists()) {
      await logsFile.delete();
    }
  }

  Future<void> deleteAllLogs() async {
    final apps = await getAllApps();
    for (final app in apps) {
      await clearLogs(app["id"]);
    }
  }

  @override
  Future<Map<String, dynamic>> getApp(String id) async {
    final path = await _path();
    final file = File("$path/apps/$id.json");
    if (!await file.exists()) return {};

    final data = await file.readAsString();
    final result = data.isNotEmpty
        ? Map<String, dynamic>.from(jsonDecode(data) as Map<String, dynamic>)
        : <String, dynamic>{};

    // Le coffre fait foi ; le jeton du fichier n'est qu'un reste des versions
    // qui l'y écrivaient.
    var secureToken = '';
    try {
      final secure = await SecureStorageService.instance;
      secureToken = ((await secure.read('bot_token:$id')) ?? '').trim();
    } catch (_) {
      // Coffre indisponible : on garde le jeton du fichier, c'est le seul.
    }
    if (secureToken.isNotEmpty) {
      // Ce que le FICHIER portait, avant de le remplacer par la valeur du coffre :
      // c'est ça qui détermine s'il reste une copie en clair à retirer.
      final fichierPortaitLeJeton = (result['token'] ?? '')
          .toString()
          .trim()
          .isNotEmpty;
      result['token'] = secureToken;
      if (fichierPortaitLeJeton) {
        // Une copie en clair traîne encore dans le fichier : on la retire.
        // Lancé SANS être attendu, et volontairement : `getApp` est appelé
        // depuis la chaîne d'écriture (`_mutateApp`), et attendre ici une
        // écriture qui se chaîne APRÈS la sienne la ferait attendre elle-même.
        unawaited(_scrubPlaintextTokenCopy(id));
      }
    }

    return result;
  }

  /// Retire du fichier un jeton resté en clair (copie d'une version antérieure).
  ///
  /// Relit le fichier DANS la chaîne d'écriture : écrire ici l'instantané lu par
  /// `getApp` écraserait une sauvegarde concurrente avec des données périmées.
  Future<void> _scrubPlaintextTokenCopy(String id) async {
    await _enqueueAppWrite(id, () async {
      final path = await _path();
      final file = File("$path/apps/$id.json");
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.isEmpty) return;
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        return;
      }
      if ((data['token'] ?? '').toString().isEmpty) return;
      data.remove('token');
      await _writeAppToDisk(id, data);
    });
  }

  Future<Map<String, dynamic>?> getCachedPayload(String botId) async {
    if (_payloadCache.containsKey(botId)) {
      return _payloadCache[botId];
    }

    try {
      final path = await _path();
      final file = File("$path/apps/$botId.payload.json");
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final decoded = jsonDecode(content);
          if (decoded is Map) {
            final payload = Map<String, dynamic>.from(decoded);
            _payloadCache[botId] = payload;
            return payload;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveCachedPayload(
    String botId,
    Map<String, dynamic> payload,
  ) async {
    _payloadCache[botId] = payload;
    try {
      final path = await _path();
      final file = File("$path/apps/$botId.payload.json");
      await file.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  Future<void> invalidatePayloadCache(String botId) async {
    _payloadCache.remove(botId);
    _commandListCache.remove(botId);
    try {
      final path = await _path();
      final file = File("$path/apps/$botId.payload.json");
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  /// A restore replaces files outside saveAppCommand. Discard both memory and
  /// archived payload caches so execution reads the restored command files.
  Future<void> invalidateRestoredCommandCaches() async {
    _commandListCache.clear();
    _payloadCache.clear();
    final storagePath = await _path();
    final directory = Directory('$storagePath/apps');
    if (!await directory.exists()) return;
    await for (final entry in directory.list()) {
      if (entry is File && entry.path.endsWith('.payload.json')) {
        await entry.delete();
      }
    }
  }

  Future<void> saveApp(
    String id,
    Map<String, dynamic> data, {
    bool notifyRuntime = true,
  }) async {
    // Le coffre n'est plus écrit ici : `_writeAppToDisk` s'en charge AVANT le
    // fichier (et sait quoi faire quand le coffre refuse).
    await _enqueueAppWrite(id, () async {
      await _writeAppToDisk(id, data);
    });
    await invalidatePayloadCache(id);
    if (notifyRuntime) {
      unawaited((onAfterSave ?? (_) async {}).call(id));
    }
  }

  /// Écrit le document de l'application sur le disque — SANS le jeton.
  ///
  /// Le jeton est un secret : il ne doit pas rester en clair dans
  /// `apps/<id>.json`, un fichier JSON lisible par n'importe quel processus du
  /// poste (sauvegardes, indexeur Spotlight, copie du dossier de données). Il
  /// part donc dans le coffre système, et le fichier ne le porte plus. Rien ne
  /// change pour les appelants : `getApp` relit le coffre en premier et rend le
  /// jeton comme avant.
  ///
  /// L'ORDRE compte, et il est l'inverse de ce qui était fait : le coffre est
  /// écrit et ATTENDU d'abord. Ce n'est que s'il refuse qu'on retombe sur la
  /// copie JSON — un jeton perdu est pire qu'un jeton en clair (l'équipe l'a
  /// vécu : « Token invalid or missing » sur tous les bots, sans moyen de
  /// récupérer). Une tâche non attendue qui échoue après coup ne protège rien.
  Future<void> _writeAppToDisk(String id, Map<String, dynamic> data) async {
    final path = await _path();
    final file = File("$path/apps/$id.json");

    final token = (data['token'] ?? '').toString().trim();
    var tokenStoredInVault = false;
    if (token.isNotEmpty) {
      tokenStoredInVault = await storeTokenInVault(id, token);
    }
    final toWrite = appDocumentForDisk(
      data,
      tokenStoredInVault: tokenStoredInVault,
    );

    if (!await file.exists()) {
      await file.create(recursive: true);
    }
    await file.writeAsString(jsonEncode(toWrite));
  }

  /// Ce qui part RÉELLEMENT sur le disque : le document sans son jeton.
  ///
  /// La règle tient en une ligne et mérite d'être isolée, parce que c'est elle
  /// qui décide qu'un secret ne traîne plus dans un fichier — et parce que le
  /// repli « coffre en échec » ne se simule pas avec un vrai coffre : un jeton
  /// perdu est pire qu'un jeton en clair, donc quand le coffre a refusé, le
  /// document garde sa copie. Un jeton vide, lui, ne s'écrit JAMAIS : il
  /// effacerait le jeton local au prochain enregistrement.
  @visibleForTesting
  static Map<String, dynamic> appDocumentForDisk(
    Map<String, dynamic> data, {
    required bool tokenStoredInVault,
  }) {
    final document = Map<String, dynamic>.from(data);
    final token = (document['token'] ?? '').toString().trim();
    if (token.isEmpty || tokenStoredInVault) {
      document.remove('token');
    }
    return document;
  }

  /// Dépose le jeton dans le coffre système et dit s'il y est.
  ///
  /// Rend `false` quand le coffre est indisponible : l'appelant doit alors
  /// garder le jeton dans le fichier plutôt que de le perdre. Public (et
  /// `visibleForTesting`) parce que c'est la seule façon de prouver ce repli :
  /// un coffre réel en échec ne se simule pas.
  @visibleForTesting
  Future<bool> storeTokenInVault(String id, String token) async {
    try {
      final secure = await SecureStorageService.instance;
      await secure.write('bot_token:$id', token);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<T> _enqueueAppWrite<T>(String id, Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _appWriteChains[id] ?? Future<void>.value();
    late final Future<void> next;
    next = previous
        .catchError((_) {})
        .then((_) async {
          try {
            final result = await action();
            completer.complete(result);
          } catch (error, stackTrace) {
            completer.completeError(error, stackTrace);
          }
        })
        .whenComplete(() {
          if (identical(_appWriteChains[id], next)) {
            _appWriteChains.remove(id);
          }
        });
    _appWriteChains[id] = next;
    return completer.future;
  }

  /// Waits for all pending app writes to complete so the filesystem
  /// reflects the latest in-memory state (used before backup).
  Future<void> flushPendingWrites() async {
    final snapshot = Map<String, Future<void>>.from(_appWriteChains);
    if (snapshot.isEmpty) return;
    await Future.wait(snapshot.values).catchError((_) => <void>[]);
  }

  Future<void> _mutateApp(
    String id,
    void Function(Map<String, dynamic> data) mutate,
  ) async {
    await _enqueueAppWrite(id, () async {
      final appData = Map<String, dynamic>.from(await getApp(id));
      mutate(appData);
      await _writeAppToDisk(id, appData);
    });
  }

  @override
  Future<void> updateGuildCount(String id, int count) async {
    final index = _apps.indexWhere((a) => a['id'] == id);
    if (index >= 0) {
      if (_apps[index]['guild_count'] == count) {
        return;
      }
      _apps[index]['guild_count'] = count;
    } else {
      return;
    }

    final path = await _path();
    final appFile = File("$path/apps/$id.json");
    if (await appFile.exists()) {
      final content = await appFile.readAsString();
      if (content.isNotEmpty) {
        final data = jsonDecode(content) as Map<String, dynamic>;
        data['guild_count'] = count;
        // Par `_writeAppToDisk`, pas en direct : c'était le SECOND écrivain du
        // document, et un écrivain en direct ne peut pas faire respecter la règle
        // « pas de jeton en clair dans le fichier » (il recopiait ce qu'il venait
        // de lire, copie en clair comprise).
        await _writeAppToDisk(id, data);
      }
    }

    final allAppsFile = File("$path/apps/all_apps.json");
    if (await allAppsFile.exists()) {
      await allAppsFile.writeAsString(jsonEncode(_apps));
    }
    _appsStreamController.add(List<dynamic>.from(_apps));
  }

  File _commandStatsFileAtPath(String path, String botId) {
    return File("$path/apps/$botId.command_stats.json");
  }

  @override
  Future<void> recordCommandExecution(
    String botId,
    String commandName, {
    DateTime? executedAt,
  }) async {
    final normalizedCommandName = commandName.trim();
    if (normalizedCommandName.isEmpty) {
      return;
    }

    await _enqueueAppWrite(botId, () async {
      final path = await _path();
      final file = _commandStatsFileAtPath(path, botId);
      await file.parent.create(recursive: true);

      List<dynamic> rawEntries = const <dynamic>[];
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final decoded = content.isNotEmpty ? jsonDecode(content) : null;
          if (decoded is List) {
            rawEntries = decoded;
          }
        } catch (_) {}
      }

      final nowMs =
          (executedAt ?? DateTime.now().toUtc()).millisecondsSinceEpoch;
      final cutoffMs = nowMs - const Duration(days: 30).inMilliseconds;
      final normalized = <Map<String, dynamic>>[];
      for (final entry in rawEntries) {
        if (entry is! Map) {
          continue;
        }
        final map = Map<String, dynamic>.from(entry.cast<String, dynamic>());
        final name = (map['command'] ?? '').toString().trim();
        final timestamp = int.tryParse((map['executedAt'] ?? '').toString());
        if (name.isEmpty || timestamp == null || timestamp < cutoffMs) {
          continue;
        }
        normalized.add(<String, dynamic>{
          'command': name,
          'executedAt': timestamp,
        });
      }

      normalized.add(<String, dynamic>{
        'command': normalizedCommandName,
        'executedAt': nowMs,
      });

      const maxEntries = 50000;
      final kept = normalized.length > maxEntries
          ? normalized.sublist(normalized.length - maxEntries)
          : normalized;
      await file.writeAsString(jsonEncode(kept));
    });
  }

  Future<Map<String, dynamic>> getLocalCommandStats(
    String botId, {
    int hours = 24,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final safeHours = hours <= 0 ? 24 : hours;
    final path = await _path();
    final file = _commandStatsFileAtPath(path, botId);
    if (!await file.exists()) {
      return <String, dynamic>{
        'botId': botId,
        'hours': safeHours,
        'totalAllTime': 0,
        'commands': const <Map<String, dynamic>>[],
        'timeline': const <Map<String, dynamic>>[],
        'locales': const <Map<String, dynamic>>[],
        'health': const <String, dynamic>{
          'total': 0,
          'failed': 0,
          'errorRatePct': 0.0,
          'p50LatencyMs': 0,
          'p95LatencyMs': 0,
        },
      };
    }

    List<dynamic> rawEntries = const <dynamic>[];
    try {
      final content = await file.readAsString();
      final decoded = content.isNotEmpty ? jsonDecode(content) : null;
      if (decoded is List) {
        rawEntries = decoded;
      }
    } catch (_) {}

    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final sinceMs = startDate != null
        ? startDate.toUtc().millisecondsSinceEpoch
        : nowMs - (safeHours * 3600000);
    final untilMs = endDate != null
        ? endDate.toUtc().millisecondsSinceEpoch
        : nowMs;
    var totalAllTime = 0;
    final countsByCommand = <String, int>{};
    final countsByHourBucket = <int, int>{};

    for (final entry in rawEntries) {
      if (entry is! Map) {
        continue;
      }
      final map = Map<String, dynamic>.from(entry.cast<String, dynamic>());
      final name = (map['command'] ?? '').toString().trim();
      final timestamp = int.tryParse((map['executedAt'] ?? '').toString());
      if (name.isEmpty || timestamp == null) {
        continue;
      }

      totalAllTime += 1;
      if (timestamp < sinceMs || timestamp > untilMs) {
        continue;
      }

      countsByCommand.update(name, (value) => value + 1, ifAbsent: () => 1);
      final hourBucket = timestamp ~/ 3600000;
      countsByHourBucket.update(
        hourBucket,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final commands =
        countsByCommand.entries
            .map(
              (entry) => <String, dynamic>{
                'command': entry.key,
                'count': entry.value,
              },
            )
            .toList(growable: false)
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final sortedBuckets = countsByHourBucket.keys.toList(growable: false)
      ..sort();
    final timeline = sortedBuckets
        .map(
          (bucket) => <String, dynamic>{
            'hour': bucket.toString(),
            'count': countsByHourBucket[bucket]!,
          },
        )
        .toList(growable: false);

    return <String, dynamic>{
      'botId': botId,
      'hours': safeHours,
      'totalAllTime': totalAllTime,
      'commands': commands,
      'timeline': timeline,
      'locales': const <Map<String, dynamic>>[],
      'health': const <String, dynamic>{
        'total': 0,
        'failed': 0,
        'errorRatePct': 0.0,
        'p50LatencyMs': 0,
        'p95LatencyMs': 0,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String id) async {
    final appData = await getApp(id);
    return Map<String, dynamic>.from(
      (appData['globalVariables'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  @override
  Future<void> setGlobalVariable(
    String id,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    await _mutateApp(id, (appData) {
      final globals = Map<String, dynamic>.from(
        (appData['globalVariables'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      globals[key] = value;
      // Note: JSON-based global variables in AppManager don't currently support TTL persistence
      // as they are stored in a simple Map. For full TTL support, use SQLite.
      appData['globalVariables'] = globals;
    });
    await invalidatePayloadCache(id);
    unawaited(
      (onAfterGlobalVariableSave ?? (_, _, _) async {}).call(id, key, value),
    );
  }

  @override
  Future<dynamic> getGlobalVariable(String id, String key) async {
    final globals = await getGlobalVariables(id);
    return globals[key];
  }

  @override
  Future<void> renameGlobalVariable(
    String id,
    String oldKey,
    String newKey,
  ) async {
    if (oldKey == newKey) {
      return;
    }
    await _mutateApp(id, (appData) {
      final globals = Map<String, dynamic>.from(
        (appData['globalVariables'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      if (!globals.containsKey(oldKey)) {
        return;
      }
      final previous = globals.remove(oldKey);
      globals[newKey] = previous;
      appData['globalVariables'] = globals;
    });
    unawaited(
      (onAfterGlobalVariableRename ?? (_, _, _) async {}).call(
        id,
        oldKey,
        newKey,
      ),
    );
  }

  @override
  Future<void> removeGlobalVariable(String id, String key) async {
    await _mutateApp(id, (appData) {
      final globals = Map<String, dynamic>.from(
        (appData['globalVariables'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      globals.remove(key);
      appData['globalVariables'] = globals;
    });
    unawaited((onAfterGlobalVariableDelete ?? (_, _) async {}).call(id, key));
  }

  @override
  Future<Map<String, dynamic>> getScopedVariables(
    String id,
    String scope,
    String contextId,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.getScopedVariables(id, scope, contextId);
    }
    return await _getScopedContextFromJson(id, scope, contextId);
  }

  @override
  Future<dynamic> getScopedVariable(
    String id,
    String scope,
    String contextId,
    String key,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.getScopedVariable(id, scope, contextId, key);
    }
    final contextMap = await _getScopedContextFromJson(id, scope, contextId);
    return contextMap[key];
  }

  @override
  Future<void> setScopedVariable(
    String id,
    String scope,
    String contextId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    if (_sqliteAvailable) {
      await _variableStore.setScopedVariable(
        id,
        scope,
        contextId,
        key,
        value,
        ttl: ttl,
      );
      return;
    }
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      contextMap[key] = value;
    });
    await invalidatePayloadCache(id);
  }

  @override
  Future<int?> getScopedVariableTtl(
    String id,
    String scope,
    String contextId,
    String key,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.getScopedVariableTtl(
        id,
        scope,
        contextId,
        key,
      );
    }
    return null;
  }

  @override
  Future<void> renameScopedVariable(
    String id,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  ) async {
    if (_sqliteAvailable) {
      await _variableStore.renameScopedVariable(
        id,
        scope,
        contextId,
        oldKey,
        newKey,
      );
      return;
    }
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      if (!contextMap.containsKey(oldKey)) {
        return;
      }
      final value = contextMap.remove(oldKey);
      contextMap[newKey] = value;
    });
    await invalidatePayloadCache(id);
  }

  @override
  Future<void> removeScopedVariable(
    String id,
    String scope,
    String contextId,
    String key,
  ) async {
    if (_sqliteAvailable) {
      await _variableStore.removeScopedVariable(id, scope, contextId, key);
      return;
    }
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      contextMap.remove(key);
    });
    await invalidatePayloadCache(id);
  }

  @override
  Future<void> pushScopedArrayElement(
    String id,
    String scope,
    String contextId,
    String key,
    dynamic element,
  ) async {
    if (_sqliteAvailable) {
      await _variableStore.pushScopedArrayElement(
        id,
        scope,
        contextId,
        key,
        element,
      );
      return;
    }
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      final existing = contextMap[key];
      final list = existing is List
          ? List<dynamic>.from(existing)
          : <dynamic>[];
      list.add(element);
      contextMap[key] = list;
    });
    await invalidatePayloadCache(id);
  }

  @override
  Future<dynamic> popScopedArrayElement(
    String id,
    String scope,
    String contextId,
    String key,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.popScopedArrayElement(
        id,
        scope,
        contextId,
        key,
      );
    }

    dynamic removed;
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      final existing = contextMap[key];
      if (existing is! List || existing.isEmpty) {
        removed = null;
        return;
      }
      final list = List<dynamic>.from(existing);
      removed = list.removeLast();
      contextMap[key] = list;
    });
    await invalidatePayloadCache(id);
    return removed;
  }

  @override
  Future<dynamic> removeScopedArrayElement(
    String id,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.removeScopedArrayElement(
        id,
        scope,
        contextId,
        key,
        index,
      );
    }

    dynamic removed;
    await _mutateScopedContextInJson(id, scope, contextId, (contextMap) {
      final existing = contextMap[key];
      if (existing is! List) {
        removed = null;
        return;
      }
      final list = List<dynamic>.from(existing);
      if (index < 0 || index >= list.length) {
        removed = null;
        return;
      }
      removed = list.removeAt(index);
      contextMap[key] = list;
    });
    await invalidatePayloadCache(id);
    return removed;
  }

  @override
  Future<dynamic> getScopedArrayElement(
    String id,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.getScopedArrayElement(
        id,
        scope,
        contextId,
        key,
        index,
      );
    }
    final contextMap = await _getScopedContextFromJson(id, scope, contextId);
    final list = contextMap[key];
    if (list is! List || index < 0 || index >= list.length) {
      return null;
    }
    return list[index];
  }

  @override
  Future<int> getScopedArrayLength(
    String id,
    String scope,
    String contextId,
    String key,
  ) async {
    if (_sqliteAvailable) {
      return await _variableStore.getScopedArrayLength(
        id,
        scope,
        contextId,
        key,
      );
    }
    final contextMap = await _getScopedContextFromJson(id, scope, contextId);
    final list = contextMap[key];
    return list is List ? list.length : 0;
  }

  @override
  Future<Map<String, dynamic>> queryScopedArray(
    String id,
    String scope,
    String contextId,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
    String? filter,
  }) async {
    if (_sqliteAvailable) {
      return await _variableStore.queryScopedArray(
        id,
        scope,
        contextId,
        key,
        offset: offset,
        limit: limit,
        descending: descending,
        filter: filter,
      );
    }

    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit.clamp(1, 25);
    final contextMap = await _getScopedContextFromJson(id, scope, contextId);
    final existing = contextMap[key];
    final source = existing is List
        ? List<dynamic>.from(existing)
        : <dynamic>[];
    final filtered = source
        .where((entry) => _arrayElementMatchesFilter(entry, filter))
        .toList(growable: false);
    final ordered = descending
        ? filtered.reversed.toList(growable: false)
        : filtered;
    final end = (safeOffset + safeLimit) > ordered.length
        ? ordered.length
        : (safeOffset + safeLimit);
    final page = safeOffset >= ordered.length
        ? const <dynamic>[]
        : ordered.sublist(safeOffset, end);

    return <String, dynamic>{
      'items': page,
      'count': page.length,
      'total': ordered.length,
    };
  }

  String _normalizeScopedStorageKey(String key) {
    final trimmed = key.trim();
    if (trimmed.startsWith('bc_') && trimmed.length > 3) {
      return trimmed.substring(3);
    }
    return trimmed;
  }

  /// Returns true when [value] should be treated as "not set" — i.e. null
  /// or an empty/whitespace-only string.  Mirrors the same logic used by
  /// injectScopedRuntimeVariables in the shared package.
  bool _isMissingOrEmptyValue(dynamic value) {
    if (value == null) return true;
    if (value is String) return value.trim().isEmpty;
    return false;
  }

  /// Looks up the default value from [definitions] for the given [scope]
  /// and normalized [storageKey].  Returns null when no matching definition
  /// exists or when the default itself is missing / empty.
  dynamic _defaultValueFor(
    List<Map<String, dynamic>> definitions,
    String scope,
    String storageKey,
  ) {
    for (final def in definitions) {
      final defKey = _normalizeScopedStorageKey((def['key'] ?? '').toString());
      final defScope = (def['scope'] ?? '').toString().trim();
      if (defKey == storageKey && defScope == scope.trim()) {
        final dv = def['defaultValue'];
        // Only return non-trivial defaults (skip null / empty-string).
        if (dv != null && !(dv is String && dv.trim().isEmpty)) {
          return dv;
        }
        return null;
      }
    }
    return null;
  }

  String _toScopedReferenceKey(String key) {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }
    return trimmed.startsWith('bc_') ? trimmed : 'bc_$trimmed';
  }

  String _normalizeInboundWebhookPath(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    final noLeading = trimmed.replaceFirst(RegExp(r'^/+'), '');
    return noLeading.replaceAll(RegExp(r'/+'), '/');
  }

  Map<String, dynamic> _normalizeInboundWebhook(Map<String, dynamic> raw) {
    final id = (raw['id'] ?? '').toString().trim();
    final path = _normalizeInboundWebhookPath((raw['path'] ?? '').toString());
    final workflowName = (raw['workflowName'] ?? '').toString().trim();
    final secret = (raw['secret'] ?? '').toString().trim();
    final enabled = raw['enabled'] != false;

    return <String, dynamic>{
      'id': id,
      'path': path,
      'workflowName': workflowName,
      'secret': secret,
      'enabled': enabled,
      if (raw['createdAt'] != null) 'createdAt': raw['createdAt'],
      if (raw['updatedAt'] != null) 'updatedAt': raw['updatedAt'],
    };
  }

  Map<String, dynamic> _readScopedContextFromAppData(
    Map<String, dynamic> appData,
    String scope,
    String contextId,
  ) {
    final scopedVariables = Map<String, dynamic>.from(
      (appData['scopedVariables'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final scopeMap = Map<String, dynamic>.from(
      (scopedVariables[scope] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    return Map<String, dynamic>.from(
      (scopeMap[contextId] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  Future<Map<String, dynamic>> _getScopedContextFromJson(
    String id,
    String scope,
    String contextId,
  ) async {
    final appData = await getApp(id);
    return _readScopedContextFromAppData(appData, scope, contextId);
  }

  Future<void> _mutateScopedContextInJson(
    String id,
    String scope,
    String contextId,
    void Function(Map<String, dynamic> contextMap) mutate,
  ) async {
    await _mutateApp(id, (appData) {
      final scopedVariables = Map<String, dynamic>.from(
        (appData['scopedVariables'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      final scopeMap = Map<String, dynamic>.from(
        (scopedVariables[scope] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );
      final contextMap = Map<String, dynamic>.from(
        (scopeMap[contextId] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      );

      mutate(contextMap);

      if (contextMap.isEmpty) {
        scopeMap.remove(contextId);
      } else {
        scopeMap[contextId] = contextMap;
      }
      if (scopeMap.isEmpty) {
        scopedVariables.remove(scope);
      } else {
        scopedVariables[scope] = scopeMap;
      }
      appData['scopedVariables'] = scopedVariables;
    });
  }

  Future<List<String>> _listContextIdsFromJson(
    String id,
    String scope, {
    String? searchKey,
  }) async {
    final appData = await getApp(id);
    final scopedVariables = Map<String, dynamic>.from(
      (appData['scopedVariables'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final scopeMap = Map<String, dynamic>.from(
      (scopedVariables[scope] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
    final lookupKey = (searchKey ?? '').trim();
    final contextIds = <String>[];
    for (final entry in scopeMap.entries) {
      final contextId = entry.key.trim();
      if (contextId.isEmpty || entry.value is! Map) {
        continue;
      }
      if (lookupKey.isEmpty) {
        contextIds.add(contextId);
        continue;
      }
      final contextMap = Map<String, dynamic>.from(
        (entry.value as Map).cast<String, dynamic>(),
      );
      if (contextMap.containsKey(lookupKey)) {
        contextIds.add(contextId);
      }
    }
    contextIds.sort();
    return contextIds;
  }

  bool _arrayElementMatchesFilter(dynamic value, String? filter) {
    final normalized = (filter ?? '').trim();
    if (normalized.isEmpty) {
      return true;
    }
    final lower = normalized.toLowerCase();
    final rendered = value?.toString() ?? '';

    if (lower.startsWith('contains ')) {
      final needle = normalized.substring('contains '.length).trim();
      return rendered.toLowerCase().contains(needle.toLowerCase());
    }

    num? valueNum;
    if (value is num) {
      valueNum = value;
    } else {
      valueNum = num.tryParse(rendered);
    }

    bool compareNum(String prefix, bool Function(num a, num b) predicate) {
      if (!lower.startsWith(prefix) || valueNum == null) {
        return false;
      }
      final rhs = num.tryParse(normalized.substring(prefix.length).trim());
      if (rhs == null) {
        return false;
      }
      return predicate(valueNum, rhs);
    }

    if (compareNum('>=', (a, b) => a >= b)) return true;
    if (compareNum('<=', (a, b) => a <= b)) return true;
    if (compareNum('>', (a, b) => a > b)) return true;
    if (compareNum('<', (a, b) => a < b)) return true;
    if (lower.startsWith('==')) {
      final rhs = normalized.substring(2).trim();
      if (valueNum != null) {
        final rhsNum = num.tryParse(rhs);
        if (rhsNum != null) {
          return valueNum == rhsNum;
        }
      }
      return rendered == rhs;
    }

    return rendered.toLowerCase().contains(normalized.toLowerCase());
  }

  // ===== SCOPED VARIABLE DEFINITIONS (stored in bot JSON, not SQLite) =====

  /// Returns the list of scoped variable definitions for [botId].
  /// Each entry is { 'key': String, 'scope': String, 'defaultValue': dynamic }.
  @override
  Future<List<Map<String, dynamic>>> getCommands(String botId) async {
    return await listAppCommands(botId);
  }

  @override
  Future<List<Map<String, dynamic>>> getScopedVariableDefinitions(
    String botId,
  ) async {
    final data = await getApp(botId);
    final raw = data['scopedVariableDefinitions'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Adds or updates a scoped variable definition in the bot JSON.
  @override
  Future<void> setScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    final normalizedKey = _normalizeScopedStorageKey(key);
    if (normalizedKey.isEmpty) {
      return;
    }
    await _mutateApp(botId, (data) {
      final defs = List<dynamic>.from(
        (data['scopedVariableDefinitions'] as List?) ?? const [],
      );
      final entry = <String, dynamic>{
        'key': normalizedKey,
        'scope': scope,
        'defaultValue': defaultValue,
        'valueType': valueType,
      };
      final idx = defs.indexWhere(
        (e) =>
            e is Map &&
            _normalizeScopedStorageKey((e['key'] ?? '').toString()) ==
                normalizedKey &&
            (e['scope'] ?? '').toString().trim() == scope.trim(),
      );
      if (idx >= 0) {
        defs[idx] = entry;
      } else {
        defs.add(entry);
      }
      data['scopedVariableDefinitions'] = defs;
    });
    unawaited(
      (onAfterScopedVariableDefinitionSave ??
              (
                String botId,
                String key,
                String scope,
                dynamic defaultValue, {
                String? valueType,
              }) async {})
          .call(
            botId,
            normalizedKey,
            scope,
            defaultValue,
            valueType: valueType,
          ),
    );
  }

  /// Removes a scoped variable definition from the bot JSON.
  Future<void> removeScopedVariableDefinition(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    final normalizedKey = _normalizeScopedStorageKey(key);
    final normalizedScope = (scope ?? '').trim();
    if (normalizedKey.isEmpty) {
      return;
    }

    if (purgeStoredValues) {
      final scopesToPurge = normalizedScope.isNotEmpty
          ? <String>{normalizedScope}
          : (await getScopedVariableDefinitions(botId))
                .where(
                  (entry) =>
                      _normalizeScopedStorageKey(
                        (entry['key'] ?? '').toString(),
                      ) ==
                      normalizedKey,
                )
                .map((entry) => (entry['scope'] ?? '').toString().trim())
                .where((value) => value.isNotEmpty)
                .toSet();
      for (final scopeName in scopesToPurge) {
        await _removeAllScopedValuesForKey(botId, scopeName, normalizedKey);
      }
    }

    await _mutateApp(botId, (data) {
      final defs = List<dynamic>.from(
        (data['scopedVariableDefinitions'] as List?) ?? const [],
      );
      defs.removeWhere(
        (e) =>
            e is Map &&
            _normalizeScopedStorageKey((e['key'] ?? '').toString()) ==
                normalizedKey &&
            (normalizedScope.isEmpty ||
                (e['scope'] ?? '').toString().trim() == normalizedScope),
      );
      data['scopedVariableDefinitions'] = defs;
    });
    unawaited(
      (onAfterScopedVariableDefinitionDelete ??
              (
                String botId,
                String key, {
                String? scope,
                bool purgeStoredValues = false,
              }) async {})
          .call(
            botId,
            normalizedKey,
            scope: normalizedScope.isEmpty ? null : normalizedScope,
            purgeStoredValues: purgeStoredValues,
          ),
    );
  }

  Future<void> _removeAllScopedValuesForKey(
    String botId,
    String scope,
    String key,
  ) async {
    final normalizedScope = scope.trim();
    final storageKey = _normalizeScopedStorageKey(key);
    if (normalizedScope.isEmpty || storageKey.isEmpty) {
      return;
    }

    final legacyKey = _toScopedReferenceKey(storageKey);
    final contextIds = List<String>.from(
      _sqliteAvailable
          ? await _variableStore.listContextIds(
              botId,
              normalizedScope,
              searchKey: storageKey,
            )
          : await _listContextIdsFromJson(
              botId,
              normalizedScope,
              searchKey: storageKey,
            ),
      growable: true,
    );
    if (legacyKey != storageKey) {
      final legacyContextIds = _sqliteAvailable
          ? await _variableStore.listContextIds(
              botId,
              normalizedScope,
              searchKey: legacyKey,
            )
          : await _listContextIdsFromJson(
              botId,
              normalizedScope,
              searchKey: legacyKey,
            );
      contextIds.addAll(legacyContextIds);
    }

    final uniqueContextIds = contextIds.toSet().toList(growable: false)..sort();
    for (final contextId in uniqueContextIds) {
      await removeScopedVariable(botId, normalizedScope, contextId, storageKey);
      if (legacyKey != storageKey) {
        await removeScopedVariable(
          botId,
          normalizedScope,
          contextId,
          legacyKey,
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) async {
    if (_sqliteAvailable) {
      return await _variableStore.queryScopedVariableIndex(
        botId,
        scope,
        _normalizeScopedStorageKey(key),
        offset: offset,
        limit: limit,
        descending: descending,
      );
    }

    final normalizedKey = _normalizeScopedStorageKey(key);
    final contextIds = await _listContextIdsFromJson(
      botId,
      scope,
      searchKey: normalizedKey,
    );
    final items = <Map<String, dynamic>>[];
    for (final contextId in contextIds) {
      final value = await getScopedVariable(
        botId,
        scope,
        contextId,
        normalizedKey,
      );
      if (value == null) {
        continue;
      }
      items.add(<String, dynamic>{
        'contextId': contextId,
        'key': normalizedKey,
        'value': value,
      });
    }

    if (descending) {
      items.sort(
        (a, b) => (b['contextId'] ?? '').toString().compareTo(
          (a['contextId'] ?? '').toString(),
        ),
      );
    } else {
      items.sort(
        (a, b) => (a['contextId'] ?? '').toString().compareTo(
          (b['contextId'] ?? '').toString(),
        ),
      );
    }

    final safeOffset = offset < 0 ? 0 : offset;
    final safeLimit = limit.clamp(1, 1000);
    final end = (safeOffset + safeLimit) > items.length
        ? items.length
        : (safeOffset + safeLimit);
    final page = safeOffset >= items.length
        ? const <Map<String, dynamic>>[]
        : items.sublist(safeOffset, end);

    return <String, dynamic>{
      'items': page,
      'count': page.length,
      'total': items.length,
    };
  }

  Future<Map<String, dynamic>> listScopedValuesForKey(
    String id,
    String scope,
    String key,
  ) async {
    final storageKey = _normalizeScopedStorageKey(key);
    final legacyKey = _toScopedReferenceKey(storageKey);

    final contextIds = List<String>.from(
      _sqliteAvailable
          ? await _variableStore.listContextIds(
              id,
              scope,
              searchKey: storageKey,
            )
          : await _listContextIdsFromJson(id, scope, searchKey: storageKey),
      growable: true,
    );
    if (legacyKey != storageKey) {
      final legacyContextIds = _sqliteAvailable
          ? await _variableStore.listContextIds(id, scope, searchKey: legacyKey)
          : await _listContextIdsFromJson(id, scope, searchKey: legacyKey);
      contextIds.addAll(legacyContextIds);
    }
    final dedupedContextIds = contextIds.toSet().toList(growable: false);
    dedupedContextIds.sort();

    // Look up the definition's default value so we can replace empty
    // stored values with it — mirroring what injectScopedRuntimeVariables
    // does at runtime.
    final definitions = await getScopedVariableDefinitions(id);
    final defaultValue = _defaultValueFor(definitions, scope, storageKey);

    final result = <String, dynamic>{};
    for (final contextId in dedupedContextIds) {
      var value = await getScopedVariable(id, scope, contextId, storageKey);
      if (value == null && legacyKey != storageKey) {
        value = await getScopedVariable(id, scope, contextId, legacyKey);
      }
      // If the stored value is missing or empty but the definition
      // specifies a non-trivial default, use the default instead.
      if (_isMissingOrEmptyValue(value) && defaultValue != null) {
        value = defaultValue;
      }
      if (value != null) {
        result[contextId] = value;
      }
    }

    return result;
  }

  Future<Map<String, Map<String, Map<String, dynamic>>>> exportScopedVariables(
    String botId,
  ) async {
    const scopes = <String>[
      'guild',
      'channel',
      'user',
      'guildMember',
      'message',
    ];

    final exported = <String, Map<String, Map<String, dynamic>>>{};
    for (final scope in scopes) {
      final contextIds = _sqliteAvailable
          ? await _variableStore.listContextIds(botId, scope)
          : await _listContextIdsFromJson(botId, scope);
      if (contextIds.isEmpty) {
        continue;
      }

      final scopeValues = <String, Map<String, dynamic>>{};
      for (final contextId in contextIds) {
        final values = await getScopedVariables(botId, scope, contextId);
        if (values.isEmpty) {
          continue;
        }
        scopeValues[contextId] = Map<String, dynamic>.from(values);
      }

      if (scopeValues.isNotEmpty) {
        exported[scope] = scopeValues;
      }
    }

    return exported;
  }

  @override
  Future<List<Map<String, dynamic>>> getWorkflows(String id) async {
    final cached = await getCachedPayload(id);
    if (cached != null) {
      final workflows = cached['workflows'];
      if (workflows is List) {
        return workflows
            .whereType<Map>()
            .map((w) => Map<String, dynamic>.from(w))
            .toList(growable: false);
      }
    }

    final app = await getApp(id);
    final rawWorkflows = _coerceWorkflowList(app['workflows']);
    return rawWorkflows
        .map((workflow) => _normalizeStoredWorkflow(workflow))
        .toList(growable: false);
  }

  Future<void> saveWorkflow(
    String id, {
    required String name,
    required List<Map<String, dynamic>> actions,
    String? entryPoint,
    List<Map<String, dynamic>>? arguments,
    String? workflowType,
    Map<String, dynamic>? eventTrigger,
    String? folder,
    Map<String, String>? eventVariableAliases,
    String? executionMode,
    String? jsScriptContent,
    String? bdfdScriptContent,
    String? bdfdBackend,
  }) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final workflows = _coerceWorkflowList(app['workflows']);

    final normalizedName = name.trim();
    final index = workflows.indexWhere(
      (workflow) =>
          (workflow['name'] ?? '').toString().toLowerCase() ==
          normalizedName.toLowerCase(),
    );
    final existing = index >= 0
        ? _normalizeStoredWorkflow(Map<String, dynamic>.from(workflows[index]))
        : null;
    final normalizedEntryPoint = entryPoint == null
        ? normalizeWorkflowEntryPoint(existing?['entryPoint'])
        : normalizeWorkflowEntryPoint(entryPoint);
    final normalizedWorkflowType = workflowType == null
        ? normalizeWorkflowType(existing?['workflowType'])
        : normalizeWorkflowType(workflowType);
    final normalizedArguments = serializeWorkflowArgumentDefinitions(
      parseWorkflowArgumentDefinitions(
        arguments ?? existing?['arguments'] ?? const [],
      ),
    );

    final resolvedFolder = (folder ?? existing?['folder'] ?? '')
        .toString()
        .trim();

    // Preserve existing aliases when not explicitly passed.
    final resolvedAliases =
        eventVariableAliases ??
        (existing?['eventVariableAliases'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );

    final resolvedExecutionMode = normalizeWorkflowExecutionMode(
      executionMode ?? existing?['executionMode'],
    );
    final resolvedJsScript = normalizeWorkflowJsScriptContent(
      jsScriptContent ?? existing?['jsScriptContent'],
    );

    final payload = <String, dynamic>{
      'name': normalizedName,
      'actions': List<Map<String, dynamic>>.from(actions),
      'workflowType': normalizedWorkflowType,
      'entryPoint': normalizedEntryPoint,
      'arguments': normalizedArguments,
      'executionMode': resolvedExecutionMode,
      if (bdfdScriptContent != null || existing?['bdfdScriptContent'] != null)
        'bdfdScriptContent':
            bdfdScriptContent ?? existing!['bdfdScriptContent'],
      if (bdfdBackend != null || existing?['bdfdBackend'] != null)
        'bdfdBackend': bdfdBackend ?? existing!['bdfdBackend'],
      'updatedAt': DateTime.now().toIso8601String(),
      if (resolvedFolder.isNotEmpty) 'folder': resolvedFolder,
      if (resolvedAliases != null && resolvedAliases.isNotEmpty)
        'eventVariableAliases': resolvedAliases,
      if (resolvedJsScript.isNotEmpty) 'jsScriptContent': resolvedJsScript,
    };

    if (normalizedWorkflowType == workflowTypeEvent) {
      payload['eventTrigger'] = normalizeWorkflowEventTrigger(
        eventTrigger ?? existing?['eventTrigger'],
      );
    }

    if (index >= 0) {
      workflows[index] = payload;
    } else {
      workflows.add(payload);
    }

    app['workflows'] = workflows;
    await saveApp(id, app);
    unawaited(
      (onAfterWorkflowSave ?? (_, _, _) async {}).call(
        id,
        normalizedName,
        Map<String, dynamic>.from(payload),
      ),
    );
  }

  Future<void> deleteWorkflow(String id, String name) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final workflows = _coerceWorkflowList(app['workflows']);

    workflows.removeWhere(
      (workflow) =>
          (workflow['name'] ?? '').toString().toLowerCase() ==
          name.toLowerCase(),
    );

    app['workflows'] = workflows;
    await saveApp(id, app);
    unawaited((onAfterWorkflowDelete ?? (_, _) async {}).call(id, name));
  }

  Future<List<Map<String, dynamic>>> getScheduledTriggers(String id) async {
    final app = await getApp(id);
    return ((app['scheduledTriggers'] as List?)
            ?.whereType<Map>()
            .map(
              (entry) =>
                  _normalizeScheduledTrigger(Map<String, dynamic>.from(entry)),
            )
            .where(
              (entry) =>
                  (entry['workflowName'] ?? '').toString().trim().isNotEmpty,
            )
            .toList(growable: false)) ??
        const <Map<String, dynamic>>[];
  }

  Future<void> saveScheduledTrigger(
    String id, {
    required String workflowName,
    required int everyMinutes,
    bool enabled = true,
    String? triggerId,
    String? label,
  }) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final triggers =
        ((app['scheduledTriggers'] as List?)
            ?.whereType<Map>()
            .map(
              (entry) =>
                  _normalizeScheduledTrigger(Map<String, dynamic>.from(entry)),
            )
            .toList(growable: true)) ??
        <Map<String, dynamic>>[];

    final normalizedWorkflowName = workflowName.trim();
    if (normalizedWorkflowName.isEmpty) {
      throw ArgumentError('workflowName is required');
    }

    final normalizedId = (triggerId ?? '').trim().isEmpty
        ? 'sch_${DateTime.now().microsecondsSinceEpoch}'
        : triggerId!.trim();

    final index = triggers.indexWhere(
      (entry) => (entry['id'] ?? '').toString() == normalizedId,
    );

    // Le plafond suit la MÊME règle que l'accès (voir `premium_feature_gate`) : quand le
    // bot tourne sur cet appareil, les déclencheurs ne coûtent rien au serveur, donc le
    // plafond de la formule payante s'applique sans abonnement. Débloquer l'écran sans
    // relever le plafond laisserait un bouton « Ajouter » qui refuse toute création.
    final limit =
        premiumCapabilityAvailableForBot(
          PremiumCapability.schedulerTriggers,
          botId: id,
        )
        ? PremiumCapabilities.premiumLimitFor(
            PremiumCapability.schedulerTriggers,
          )
        : PremiumCapabilities.limitFor(PremiumCapability.schedulerTriggers);
    final wouldCreate = index < 0;
    if (wouldCreate && triggers.length >= limit) {
      throw StateError('scheduler_trigger_limit_reached:$limit');
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'id': normalizedId,
      'workflowName': normalizedWorkflowName,
      'label': (label ?? normalizedWorkflowName).trim(),
      'everyMinutes': everyMinutes.clamp(1, 10080),
      'enabled': enabled,
      'updatedAt': nowIso,
    };

    if (index >= 0) {
      payload['createdAt'] = triggers[index]['createdAt'] ?? nowIso;
      triggers[index] = _normalizeScheduledTrigger(payload);
    } else {
      payload['createdAt'] = nowIso;
      triggers.add(_normalizeScheduledTrigger(payload));
    }

    app['scheduledTriggers'] = triggers;
    await saveApp(id, app);

    unawaited(
      (onAfterScheduledTriggerSave ?? (_, _, _) async {}).call(
        id,
        normalizedId,
        Map<String, dynamic>.from(payload),
      ),
    );
  }

  Future<void> deleteScheduledTrigger(String id, String triggerId) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final triggers =
        ((app['scheduledTriggers'] as List?)
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: true)) ??
        <Map<String, dynamic>>[];
    triggers.removeWhere(
      (entry) => (entry['id'] ?? '').toString().trim() == triggerId.trim(),
    );
    app['scheduledTriggers'] = triggers;
    await saveApp(id, app);

    unawaited(
      (onAfterScheduledTriggerDelete ?? (_, _) async {}).call(id, triggerId),
    );
  }

  Future<List<Map<String, dynamic>>> getInboundWebhooks(String id) async {
    final app = await getApp(id);
    return _decodeInboundWebhooks(app['inboundWebhooks'])
        .map((entry) => _normalizeInboundWebhook(entry))
        .where((entry) {
          return (entry['path'] ?? '').toString().trim().isNotEmpty &&
              (entry['workflowName'] ?? '').toString().trim().isNotEmpty;
        })
        .toList(growable: false);
  }

  /// Decodes the stored inbound-webhook list.
  ///
  /// The column is free-form JSON, so a legacy row (or a hand-edited config)
  /// can hold any type here: a bare `as List?` cast threw
  /// "bool is not a subtype of List?" and crashed the app on a FATAL path.
  static List<Map<String, dynamic>> _decodeInboundWebhooks(Object? raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }

  Future<void> saveInboundWebhook(
    String id, {
    required String path,
    required String workflowName,
    required String secret,
    bool enabled = true,
    String? webhookId,
  }) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final webhooks = _decodeInboundWebhooks(
      app['inboundWebhooks'],
    ).map((entry) => _normalizeInboundWebhook(entry)).toList();

    final normalizedPath = _normalizeInboundWebhookPath(path);
    final normalizedWorkflow = workflowName.trim();
    final normalizedSecret = secret.trim();
    if (normalizedPath.isEmpty ||
        normalizedWorkflow.isEmpty ||
        normalizedSecret.isEmpty) {
      throw ArgumentError('path, workflowName and secret are required');
    }

    final normalizedId = (webhookId ?? '').trim().isEmpty
        ? 'wh_${DateTime.now().microsecondsSinceEpoch}'
        : webhookId!.trim();

    final duplicatePath = webhooks.any((entry) {
      return (entry['id'] ?? '').toString() != normalizedId &&
          (entry['path'] ?? '').toString().trim().toLowerCase() ==
              normalizedPath.toLowerCase();
    });
    if (duplicatePath) {
      throw StateError('inbound_webhook_path_conflict');
    }

    final index = webhooks.indexWhere(
      (entry) => (entry['id'] ?? '').toString() == normalizedId,
    );

    final limit = PremiumCapabilities.limitFor(
      PremiumCapability.inboundWebhooks,
    );
    final wouldCreate = index < 0;
    if (wouldCreate && webhooks.length >= limit) {
      throw StateError('inbound_webhook_limit_reached:$limit');
    }

    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'id': normalizedId,
      'path': normalizedPath,
      'workflowName': normalizedWorkflow,
      'secret': normalizedSecret,
      'enabled': enabled,
      'updatedAt': nowIso,
    };

    if (index >= 0) {
      payload['createdAt'] = webhooks[index]['createdAt'] ?? nowIso;
      webhooks[index] = _normalizeInboundWebhook(payload);
    } else {
      payload['createdAt'] = nowIso;
      webhooks.add(_normalizeInboundWebhook(payload));
    }

    app['inboundWebhooks'] = webhooks;
    await saveApp(id, app);

    unawaited(
      (onAfterInboundWebhookSave ?? (_, _, _) async {}).call(
        id,
        webhookId ?? payload['id'],
        Map<String, dynamic>.from(payload),
      ),
    );
  }

  Future<void> deleteInboundWebhook(String id, String webhookId) async {
    final app = Map<String, dynamic>.from(await getApp(id));
    final webhooks = _decodeInboundWebhooks(app['inboundWebhooks']);
    webhooks.removeWhere(
      (entry) => (entry['id'] ?? '').toString().trim() == webhookId.trim(),
    );
    app['inboundWebhooks'] = webhooks;
    await saveApp(id, app);

    unawaited(
      (onAfterInboundWebhookDelete ?? (_, _) async {}).call(id, webhookId),
    );
  }

  Map<String, dynamic> _normalizeScheduledTrigger(Map<String, dynamic> raw) {
    final id = (raw['id'] ?? '').toString().trim();
    final workflowName = (raw['workflowName'] ?? '').toString().trim();
    final label = (raw['label'] ?? workflowName).toString().trim();
    final minutesRaw = int.tryParse((raw['everyMinutes'] ?? '').toString());
    final everyMinutes = (minutesRaw != null && minutesRaw > 0)
        ? minutesRaw.clamp(1, 10080)
        : 60;

    return <String, dynamic>{
      'id': id,
      'workflowName': workflowName,
      'label': label,
      'everyMinutes': everyMinutes,
      'enabled': raw['enabled'] != false,
      if (raw['createdAt'] != null) 'createdAt': raw['createdAt'],
      if (raw['updatedAt'] != null) 'updatedAt': raw['updatedAt'],
    };
  }

  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String id,
    String name,
  ) async {
    final workflows = await getWorkflows(id);
    for (final workflow in workflows) {
      if ((workflow['name'] ?? '').toString().toLowerCase() ==
          name.toLowerCase()) {
        return workflow;
      }
    }
    return null;
  }

  Map<String, dynamic> _normalizeStoredWorkflow(Map<String, dynamic> workflow) {
    final draft = Map<String, dynamic>.from(workflow);
    final rawType = (draft['workflowType'] ?? '').toString().trim();
    final hasLegacyEventHints =
        draft['eventTrigger'] != null ||
        (draft['event']?.toString().trim().isNotEmpty ?? false) ||
        (draft['listenFor']?.toString().trim().isNotEmpty ?? false);

    if (rawType.isEmpty && hasLegacyEventHints) {
      draft['workflowType'] = workflowTypeEvent;
      if (draft['eventTrigger'] == null) {
        final eventName =
            (draft['event'] ?? draft['listenFor'] ?? 'messageCreate')
                .toString()
                .trim();
        draft['eventTrigger'] = <String, dynamic>{
          'category': 'messages',
          'event': eventName.isEmpty ? 'messageCreate' : eventName,
        };
      }
    }

    return normalizeStoredWorkflowDefinition(draft);
  }

  List<Map<String, dynamic>> _coerceWorkflowList(dynamic raw) {
    if (raw is! List) {
      return <Map<String, dynamic>>[];
    }

    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is Map) {
        result.add(Map<String, dynamic>.from(item));
        continue;
      }

      if (item is String) {
        final text = item.trim();
        if (text.isEmpty) {
          continue;
        }
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map) {
            result.add(Map<String, dynamic>.from(decoded));
          }
        } catch (_) {
          // Keep compatibility mode resilient: malformed entries are skipped.
        }
      }
    }

    return result;
  }

  Future<void> _writeWorkflowCompatibilityReportIfDebug() async {
    if (kReleaseMode || !Platform.isWindows) {
      return;
    }

    try {
      final report = <String, dynamic>{
        'generatedAt': DateTime.now().toIso8601String(),
        'apps': <Map<String, dynamic>>[],
      };

      for (final appMeta in _apps) {
        if (appMeta is! Map) {
          continue;
        }

        final id = (appMeta['id'] ?? '').toString().trim();
        if (id.isEmpty) {
          continue;
        }

        final app = await getApp(id);
        final raw = app['workflows'];
        final rawList = raw is List ? raw : const <dynamic>[];
        final parsed = _coerceWorkflowList(raw);
        final normalized = parsed
            .map((entry) => _normalizeStoredWorkflow(entry))
            .toList(growable: false);
        final commandRefsByFile = await _collectCommandWorkflowReferences(id);
        final referencedWorkflowNames = commandRefsByFile.values
            .expand((names) => names)
            .toSet();
        final normalizedWorkflowNames = normalized
            .map((entry) => (entry['name'] ?? '').toString().trim())
            .where((name) => name.isNotEmpty)
            .toSet();
        final missingReferencedWorkflows =
            referencedWorkflowNames
                .where((name) => !normalizedWorkflowNames.contains(name))
                .toList(growable: false)
              ..sort();

        final missingNames = normalized
            .where(
              (workflow) => (workflow['name'] ?? '').toString().trim().isEmpty,
            )
            .length;

        (report['apps'] as List<Map<String, dynamic>>).add({
          'id': id,
          'name': (appMeta['name'] ?? '').toString(),
          'rawWorkflowEntries': rawList.length,
          'parsedWorkflowEntries': parsed.length,
          'normalizedWorkflowEntries': normalized.length,
          'droppedEntries': rawList.length - parsed.length,
          'missingNameAfterNormalization': missingNames,
          'commandWorkflowReferenceCount': referencedWorkflowNames.length,
          'missingReferencedWorkflows': missingReferencedWorkflows,
          'commandWorkflowReferencesByFile': commandRefsByFile,
          'rawTypes': rawList
              .map((entry) => entry.runtimeType.toString())
              .toList(),
          'normalizedPreview': normalized.take(20).toList(),
        });
      }

      final basePath = await _path();
      final debugDir = Directory('$basePath/apps/_debug');
      if (!await debugDir.exists()) {
        await debugDir.create(recursive: true);
      }

      final reportFile = File(
        '$basePath/apps/_debug/workflow_compat_report.json',
      );
      final encoder = const JsonEncoder.withIndent('  ');
      await reportFile.writeAsString(encoder.convert(report));

      debugPrint('Workflow compatibility report written: ${reportFile.path}');
    } catch (error) {
      debugPrint('Workflow compatibility report failed: $error');
    }
  }

  Future<Map<String, List<String>>> _collectCommandWorkflowReferences(
    String botId,
  ) async {
    final basePath = await _path();
    final commandsDir = Directory('$basePath/apps/$botId');
    if (!await commandsDir.exists()) {
      return const <String, List<String>>{};
    }

    final result = <String, List<String>>{};
    final entities = await commandsDir.list().toList();
    for (final entity in entities) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      try {
        final content = await entity.readAsString();
        if (content.trim().isEmpty) {
          continue;
        }
        final decoded = jsonDecode(content);
        final names = _extractWorkflowNames(decoded).toList(growable: false)
          ..sort();
        if (names.isNotEmpty) {
          final fileName = entity.uri.pathSegments.last;
          result[fileName] = names;
        }
      } catch (_) {
        // Ignore malformed command files in debug report generation.
      }
    }

    return result;
  }

  Set<String> _extractWorkflowNames(dynamic node) {
    final names = <String>{};
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString();
        if (key == 'workflowName') {
          final value = entry.value?.toString().trim() ?? '';
          if (value.isNotEmpty) {
            names.add(value);
          }
        }
        names.addAll(_extractWorkflowNames(entry.value));
      }
      return names;
    }

    if (node is List) {
      for (final item in node) {
        names.addAll(_extractWorkflowNames(item));
      }
    }
    return names;
  }

  Future<Map<String, dynamic>> getAppCommand(
    String id,
    String commandId,
  ) async {
    activeUiStallMonitor?.markStart('load_command');
    try {
      final path = await _path();
      final file = File("$path/apps/$id/$commandId.json");
      if (!await file.exists()) return {};

      final data = await file.readAsString();
      if (data.isEmpty) return {};

      final decoded = Map<String, dynamic>.from(jsonDecode(data));
      final normalized = normalizeCommandData(decoded);
      normalized['id'] = commandId;
      if (!_deepEquals(decoded, normalized)) {
        await file.writeAsString(jsonEncode(normalized));
      }

      return normalized;
    } finally {
      activeUiStallMonitor?.markEnd('load_command');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> listAppCommands(
    String id, {
    bool forceRefresh = false,
  }) async {
    activeUiStallMonitor?.markStart('list_commands');
    try {
      if (!forceRefresh) {
        final cachedMemory = _commandListCache[id];
        if (cachedMemory != null) return cachedMemory;

        final cachedPayload = await getCachedPayload(id);
        if (cachedPayload != null) {
          final commands = cachedPayload['commands'];
          if (commands is List) {
            final list = commands
                .whereType<Map>()
                .map((c) => Map<String, dynamic>.from(c))
                .toList(growable: false);
            _commandListCache[id] = list;
            return list;
          }
        }
      }

      final path = await _path();
      final dir = Directory("$path/apps/$id");
      if (!await dir.exists()) {
        return const <Map<String, dynamic>>[];
      }

      final entities = await dir.list().toList();
      final commands = <Map<String, dynamic>>[];

      for (final entity in entities) {
        if (entity is! File || !entity.path.endsWith('.json')) {
          continue;
        }

        try {
          final content = await entity.readAsString();
          if (content.trim().isEmpty) {
            continue;
          }

          final decoded = Map<String, dynamic>.from(jsonDecode(content));
          final normalized = normalizeCommandData(decoded);
          final fileName = entity.uri.pathSegments.last;
          final fallbackId = fileName.substring(0, fileName.length - 5);

          // The filename is the storage/history identity. Older sync versions
          // wrote a new filename while leaving the previous ID in the content.
          normalized['id'] = fallbackId;
          final rawName = (normalized['name'] ?? '').toString().trim();
          normalized['name'] = rawName.isEmpty
              ? _fallbackCommandName(fallbackId)
              : rawName;
          normalized['description'] = (normalized['description'] ?? '')
              .toString();
          commands.add(normalized);
        } catch (_) {
          // Ignore malformed command files to keep list rendering resilient.
        }
      }

      commands.sort((a, b) {
        final aName = (a['name'] ?? '').toString().toLowerCase();
        final bName = (b['name'] ?? '').toString().toLowerCase();
        return aName.compareTo(bName);
      });
      _commandListCache[id] = commands;
      return commands;
    } finally {
      activeUiStallMonitor?.markEnd('list_commands');
    }
  }

  @override
  Future<void> saveAppCommand(
    String id,
    String commandId,
    Map<String, dynamic> data,
  ) async {
    activeUiStallMonitor?.markStart('save_command');
    try {
      _commandListCache.remove(id);

      final path = await _path();
      final file = File("$path/apps/$id/$commandId.json");

      if (!await file.exists()) await file.create(recursive: true);
      final stored = normalizeCommandData(<String, dynamic>{
        ...data,
        'id': commandId,
      });
      await file.writeAsString(jsonEncode(stored));
      await invalidatePayloadCache(id);
      unawaited(
        (onAfterCommandSave ?? (_, _, _) async {}).call(
          id,
          commandId,
          Map<String, dynamic>.from(stored),
        ),
      );
    } finally {
      activeUiStallMonitor?.markEnd('save_command');
    }
  }

  @override
  Map<String, dynamic> normalizeCommandData(Map<String, dynamic> command) {
    return normalize_lib.normalizeCommandData(command);
  }

  bool _deepEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    return jsonEncode(a) == jsonEncode(b);
  }

  Future<void> deleteAppCommand(String id, String commandId) async {
    _commandListCache.remove(id);
    final path = await _path();
    final file = File("$path/apps/$id/$commandId.json");
    String? discordId;
    try {
      final command = jsonDecode(await file.readAsString()) as Map;
      discordId = (command['discordId'] ?? commandId).toString();
    } catch (_) {
      // Malformed or already absent files must still be deletable.
    }
    if (await file.exists()) await file.delete();
    await invalidatePayloadCache(id);
    final hook = onAfterCommandDelete;
    if (hook != null) {
      unawaited(hook(id, commandId, discordId: discordId));
    }
  }

  Future<void> deleteAppCommands(String id) async {
    _commandListCache.remove(id);
    final path = await _path();
    final dir = Directory("$path/apps/$id");
    if (!await dir.exists()) return;

    final files = await dir.list().toList();
    for (final file in files) {
      if (file is File && file.path.endsWith(".json")) {
        await file.delete();
      }
    }
    await invalidatePayloadCache(id);
  }

  Future<List<FileSystemEntity>> getAllAppDirectory() async {
    final path = await _path();
    final dir = Directory("$path/apps");
    if (!await dir.exists()) return [];

    final files = await dir.list(recursive: true).toList();
    final allAppsFile = File("$path/apps/all_apps.json");
    if (await allAppsFile.exists()) files.add(allAppsFile);
    return files;
  }

  Future<void> deleteAllApps() async {
    final apps = await getAllApps();
    for (final app in apps) {
      await deleteApp(app['id']);
    }
  }
}

/// Deterministic, non-colliding fallback command name derived from the command
/// file name, so several nameless commands no longer share one name.
String _fallbackCommandName(String fallbackId) {
  final slug = fallbackId
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final safe = slug.isEmpty ? 'unnamed' : slug;
  return 'cmd_${safe.length > 32 ? safe.substring(0, 32) : safe}';
}
