import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator_shared/utils/command_trigger_type.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_refresh.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_presence_keys.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

List<Map<String, dynamic>> extractCommandListFromConfig(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  if (raw is Map) {
    return raw.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

String localCommandTypeFromRemote(
  Map<String, dynamic> cmd,
  Map<String, dynamic> cmdData,
) {
  final raw =
      (cmdData['commandType'] ??
              cmdData['discordType'] ??
              cmd['discordType'] ??
              cmd['type'] ??
              'chatInput')
          .toString()
          .trim();
  switch (raw.toLowerCase()) {
    case 'command':
    case 'chatinput':
    case 'chat_input':
    case 'chat-input':
    case 'slash':
      return 'chatInput';
    case 'user':
    case 'usercommand':
    case 'user_command':
      return 'user';
    case 'message':
    case 'messagecommand':
    case 'message_command':
      return 'message';
    default:
      return 'chatInput';
  }
}

/// Le Manager ne renvoie JAMAIS les identifiants de la base personnalisée : sa
/// copie est un repère expurgé (`{type, encrypted: true}`, sans hôte ni mot de
/// passe). La recopier telle quelle sur la configuration locale effaçait les
/// identifiants saisis à chaque synchro entrante, d'où une base qui « ne reste
/// pas » tant qu'on ne ré-enregistre pas. On garde donc la copie locale tant que
/// le repère distant ne désigne pas un autre type de base.
void keepLocalDatabaseCredentials(
  Map<String, dynamic> merged,
  Map<String, dynamic> existingApp,
  Map<String, dynamic> remoteConfig,
) {
  final local = existingApp['databaseConfig'];
  final remote = remoteConfig['databaseConfig'];
  if (local is! Map || remote is! Map || remote['encrypted'] != true) return;
  final localType = (local['type'] ?? 'none').toString().trim().toLowerCase();
  final remoteType = (remote['type'] ?? 'none').toString().trim().toLowerCase();
  if (localType == 'none') return;
  if (remoteType == 'none' || remoteType.isEmpty || remoteType == localType) {
    // Copie locale VIDE (enregistrée sans rien saisir) alors que le Manager sait
    // qu'une copie existe : on adopte le repère distant, qui porte l'indice
    // `hasCredentials`, sinon cet appareil ne saurait jamais qu'ils existent.
    if (remote['hasCredentials'] == true &&
        remoteType == localType &&
        !databaseConfigHasCredentials(local)) {
      return;
    }
    merged['databaseConfig'] = Map<String, dynamic>.from(local);
  }
}

/// Vrai si ce `databaseConfig` porte réellement des identifiants saisis ici.
bool databaseConfigHasCredentials(Map<dynamic, dynamic>? db) {
  if (db == null) return false;
  for (final key in const ['uri', 'host', 'user', 'password']) {
    if ((db[key] ?? '').toString().trim().isNotEmpty) return true;
  }
  return false;
}

/// `addAll(remoteConfig)` écrase aussi deux clés dont la forme distante n'est
/// PAS celle du stockage local :
/// - `inboundWebhooks` : localement la liste des endpoints saisis, à distance un
///   booléen (moteur Dart) ou la forme runner (id, path, secret, script) ; la
///   vraie liste revient dans `inboundWebhookEndpoints`. On garde la liste
///   locale, et on n'adopte la liste distante que si rien n'existe localement.
/// - `globalVariables` : les variables écrites par le runtime local et pas encore
///   poussées disparaissaient à la synchro suivante. Les clés distantes gagnent,
///   les clés seulement locales sont conservées.
void keepLocalAutomationDefinitions(
  Map<String, dynamic> merged,
  Map<String, dynamic> existingApp,
  Map<String, dynamic> remoteConfig,
) {
  final localHooks = existingApp['inboundWebhooks'];
  if (localHooks is List) {
    merged['inboundWebhooks'] = List<dynamic>.from(localHooks);
  } else if (remoteConfig['inboundWebhookEndpoints'] is List) {
    merged['inboundWebhooks'] = List<dynamic>.from(
      remoteConfig['inboundWebhookEndpoints'] as List,
    );
  } else if (merged['inboundWebhooks'] is! List) {
    merged.remove('inboundWebhooks');
  }

  // Le serveur renvoie la musique sous `lavalink` (schéma figé), l'app la lit
  // sous `lavalinkConfig`. On l'adopte seulement si rien n'est configuré ici : le
  // serveur éteint Lavalink pour un compte gratuit, alors que le bot local peut
  // légitimement garder la musique sur cet appareil.
  final remoteLavalink = remoteConfig['lavalink'];
  if (existingApp['lavalinkConfig'] is! Map && remoteLavalink is Map) {
    merged['lavalinkConfig'] = Map<String, dynamic>.from(remoteLavalink);
  }

  final localGlobals = existingApp['globalVariables'];
  final remoteGlobals = remoteConfig['globalVariables'];
  if (localGlobals is Map && remoteGlobals is Map) {
    merged['globalVariables'] = <String, dynamic>{
      ...localGlobals.map((k, v) => MapEntry(k.toString(), v)),
      ...remoteGlobals.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}

/// Imports runtime identity without triggering an outbound synchronization.
Future<void> applyManagerRuntimeMetadataToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
}) async {
  final engine = runtimeEngineFromConfiguration(remoteConfig);
  final app = Map<String, dynamic>.from(await appManager.getApp(botId));
  var changed = false;
  if (engine != null && app['runtimeEngine'] != engine) {
    app['runtimeEngine'] = engine;
    changed = true;
  }
  if (remoteConfig.containsKey('bdfdUserVariableSemantics') &&
      app['bdfdUserVariableSemantics'] !=
          remoteConfig['bdfdUserVariableSemantics']) {
    app['bdfdUserVariableSemantics'] =
        remoteConfig['bdfdUserVariableSemantics'];
    changed = true;
  }
  if (changed) await appManager.saveApp(botId, app, notifyRuntime: false);
}

/// Overwrites local commands and workflows from a Manager config payload.
Future<void> applyManagerConfigToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
  bool saveAppMetadata = true,
  bool deleteMissingLocalCommands = false,
}) async {
  final importedEngine = runtimeEngineFromConfiguration(remoteConfig);
  final endRemoteSync = AppManager.beginRemoteSync();
  try {
    if (saveAppMetadata) {
      final existingApp = await appManager.getApp(botId);
      final merged = Map<String, dynamic>.from(existingApp)
        ..addAll(remoteConfig);
      // Le Manager ne porte que `statuses` ; sans cette recopie, les anciennes
      // `activities` locales (lues en premier) masquent le statut tiré du cloud.
      mirrorPresenceActivities(merged, remoteConfig);
      keepLocalDatabaseCredentials(merged, existingApp, remoteConfig);
      keepLocalAutomationDefinitions(merged, existingApp, remoteConfig);

      if (remoteConfig['prefix'] == null && existingApp.containsKey('prefix')) {
        merged['prefix'] = existingApp['prefix'];
      }

      // Guard runtime engine against unintended mutation or null erasure
      final remoteEngine = importedEngine ?? '';
      final localEngine = (existingApp['runtimeEngine'] ?? '')
          .toString()
          .trim();
      if (remoteEngine.isNotEmpty) {
        merged['runtimeEngine'] = normalizeRuntimeEngine(remoteEngine);
      } else if (localEngine.isNotEmpty) {
        merged['runtimeEngine'] = normalizeRuntimeEngine(localEngine);
      }

      await appManager.saveApp(botId, merged, notifyRuntime: false);
    } else {
      await applyManagerRuntimeMetadataToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remoteConfig,
      );
    }

    final remoteCommands = extractCommandListFromConfig(
      remoteConfig['commands'],
    );
    final remoteCommandIds = <String>{};
    for (final cmd in remoteCommands) {
      final cmdId = (cmd['id'] ?? cmd['commandId'] ?? '').toString();
      final cmdName = (cmd['name'] ?? '').toString();
      if (cmdId.isEmpty || cmdName.isEmpty) {
        continue;
      }
      remoteCommandIds.add(cmdId);

      final localCmd = await appManager.getAppCommand(botId, cmdId);
      final cmdData = Map<String, dynamic>.from(cmd['data'] ?? cmd);
      for (final key in [
        'triggerType',
        'prefixName',
        'aliases',
        'legacyModeEnabled',
        'legacyLocalOnly',
        'legacyPrefixOverride',
        'legacyAliases',
        'discordType',
        'options',
        'defaultMemberPermissions',
        'contexts',
        'integrationTypes',
      ]) {
        if (!cmdData.containsKey(key) && cmd.containsKey(key)) {
          cmdData[key] = cmd[key];
        }
      }
      // Infer before nesting flattened handlers: absent legacy JS modes remain
      // hybrid, while any historical prefix/local-only flags remain authoritative.
      cmdData['triggerType'] = commandTriggerType({
        ...cmd,
        if (cmd['data'] is Map) 'data': cmdData,
      });
      if (cmd['type'] == 'command' && cmd['script'] is String) {
        cmdData['executionMode'] = 'javascript';
        cmdData['jsScriptContent'] = cmd['script'];
      }
      if (cmdData['response'] is Map &&
          (cmdData['response'] as Map).containsKey('_migrated')) {
        cmdData.remove('response');
      }
      cmdData.remove('simpleConfig');

      // Preserve folder hierarchy from remote command, command data, or local copy
      final rawFolder =
          (cmd['folder'] ?? cmdData['folder'] ?? localCmd['folder'] ?? '')
              .toString()
              .trim();

      await appManager.saveAppCommand(botId, cmdId, <String, dynamic>{
        'name': cmdName,
        'description': (cmd['description'] ?? '').toString(),
        'type': localCommandTypeFromRemote(cmd, cmdData),
        'id': cmdId,
        if (cmd['enabled'] != null) 'enabled': cmd['enabled'],
        if (cmd['discordId'] != null) 'discordId': cmd['discordId'],
        'data': cmdData,
        if (rawFolder.isNotEmpty) 'folder': rawFolder,
        'createdAt': (localCmd['createdAt'] ?? DateTime.now().toIso8601String())
            .toString(),
        'updatedAt': (cmd['updatedAt'] ?? DateTime.now().toIso8601String())
            .toString(),
      });
    }

    if (deleteMissingLocalCommands) {
      final localCommands = await appManager.listAppCommands(botId);
      for (final localCmd in localCommands) {
        final localCmdId = (localCmd['id'] ?? '').toString();
        if (localCmdId.isNotEmpty && !remoteCommandIds.contains(localCmdId)) {
          await appManager.deleteAppCommand(botId, localCmdId);
        }
      }
    }

    await applyManagerWorkflowsToLocal(
      appManager: appManager,
      botId: botId,
      remoteConfig: remoteConfig,
      deleteMissingLocalWorkflows: deleteMissingLocalCommands,
    );
  } finally {
    endRemoteSync();
  }

  // Le remplacement est TERMINÉ : on prévient les écrans qui affichent une copie
  // locale (liste des commandes, workflows…). Le signal est posé ici, et pas dans
  // chaque appelant, parce que c'est le seul endroit qui remplace la copie : une
  // restauration de version, une synchro entrante et l'amorçage de session
  // passent tous par là, et aucun ne doit oublier de rafraîchir l'interface.
  BotConfigRefreshNotifier.instance.notifyConfigReplaced(botId);
}

Future<void> applyManagerWorkflowsToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
  bool deleteMissingLocalWorkflows = false,
}) async {
  final remoteWorkflows = remoteConfig['workflows'];
  final remoteWorkflowNames = <String>{};
  if (remoteWorkflows is List) {
    for (final wf in remoteWorkflows) {
      if (wf is! Map) {
        continue;
      }
      final wfName = (wf['name'] ?? '').toString();
      if (wfName.isEmpty) {
        continue;
      }
      remoteWorkflowNames.add(wfName);

      await appManager.saveWorkflow(
        botId,
        name: wfName,
        actions: ((wf['actions'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        entryPoint: wf['entryPoint']?.toString(),
        arguments: ((wf['arguments'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        workflowType: wf['workflowType']?.toString(),
        eventTrigger: wf['eventTrigger'] != null
            ? Map<String, dynamic>.from(wf['eventTrigger'] as Map)
            : null,
        folder: wf['folder']?.toString(),
        eventVariableAliases: wf['eventVariableAliases'] is Map
            ? Map<String, String>.from(
                (wf['eventVariableAliases'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : null,
        executionMode: wf['executionMode']?.toString(),
        jsScriptContent: wf['jsScriptContent']?.toString(),
      );
    }
  }

  if (deleteMissingLocalWorkflows) {
    final localApp = await appManager.getApp(botId);
    final localWorkflows =
        (localApp['workflows'] as List?)?.whereType<Map>().toList() ?? [];
    for (final wf in localWorkflows) {
      final wfName = (wf['name'] ?? '').toString();
      if (wfName.isNotEmpty && !remoteWorkflowNames.contains(wfName)) {
        await appManager.deleteWorkflow(botId, wfName);
      }
    }
  }
}
