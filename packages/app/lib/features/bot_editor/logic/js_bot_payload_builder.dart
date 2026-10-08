import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_helpers.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:flutter/foundation.dart';
import 'package:bot_creator_shared/utils/command_trigger_type.dart';

Future<Map<String, dynamic>> buildJsBotPayload(String botId) async {
  final appData = await AppManager().getApp(botId);
  if (appData.isEmpty) {
    throw StateError('Bot "$botId" not found in local storage.');
  }

  final token = (appData['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    throw StateError('Bot "$botId" has no token configured.');
  }

  try {
    await refreshAppIntentsFromPortal(
      botId: botId,
      appData: appData,
      token: token,
    );
  } catch (_) {
    // Keep stored intents when portal sync is unavailable.
  }

  final commandsRaw = await AppManager().listAppCommands(botId);
  final workflows = await AppManager().getWorkflows(botId);
  String linkedScript(Map map) {
    final direct = (map['jsScriptContent'] ?? map['script'] ?? '').toString();
    if (direct.trim().isNotEmpty) return direct;
    final name = (map['workflowName'] ?? '').toString();
    final matches = workflows.where((w) => w['name'] == name);
    if (matches.isEmpty) return '';
    final workflow = matches.first;
    final source = normalizeWorkflowJsScriptContent(
      workflow['jsScriptContent'],
    );
    if (source.trim().isNotEmpty) return source;
    return synthesizeJsFromWorkflowActions(
          (workflow['actions'] as List?) ?? const [],
        ) ??
        '';
  }

  final commands = <Map<String, dynamic>>[];
  final usedNames = <String>{};

  for (final command in commandsRaw) {
    final normalized = normalizeCommandData(Map<String, dynamic>.from(command));
    final data = Map<String, dynamic>.from(
      (normalized['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final triggerType = commandTriggerType(normalized);
    final executionMode = (data['executionMode'] ?? 'workflow')
        .toString()
        .trim()
        .toLowerCase();
    var script = (data['jsScriptContent'] ?? data['script'] ?? '').toString();
    if (executionMode != 'javascript') {
      if (script.trim().isEmpty) {
        script =
            synthesizeJsFromWorkflowActions(
              (data['actions'] as List?) ?? const [],
              preferMessage: triggerType == 'prefix',
            ) ??
            '';
      }
      if (script.trim().isEmpty) continue;
    } else if (script.trim().isEmpty) {
      continue;
    }

    final rawName = (normalized['name'] ?? '').toString().trim();
    if (rawName.isEmpty) {
      debugPrint(
        '[buildJsBotPayload] Skipping "${(normalized['id'] ?? '').toString()}": '
        'empty name.',
      );
      continue;
    }
    final uniqueName = deduplicateCommandName(rawName, usedNames);
    commands.add({
      'id': (normalized['id'] ?? '').toString(),
      'type': 'command',
      'triggerType': triggerType,
      'prefixName': cleanLegacyCommandTriggerName(
        (data['legacyPrefixOverride'] ?? '').toString().trim().isEmpty
            ? rawName
            : data['legacyPrefixOverride'].toString(),
      ),
      'data': {
        ...data,
        'executionMode': 'javascript',
        'jsScriptContent': script,
      },
      if (normalized['folder'] != null) 'folder': normalized['folder'],
      if (normalized['discordId'] != null) 'discordId': normalized['discordId'],
      'name': uniqueName,
      'description':
          (normalized['description'] ?? data['description'] ?? uniqueName)
              .toString(),
      'discordType': resolveDiscordCommandType(data['commandType']),
      'aliases': normalizeLegacyCommandAliases(data['legacyAliases'])
          .map(cleanLegacyCommandTriggerName)
          .where((alias) => alias.isNotEmpty)
          .toSet()
          .toList(),
      'options': data['options'] ?? const [],
      if (data['defaultMemberPermissions'] != null)
        'defaultMemberPermissions': data['defaultMemberPermissions'],
      if (data['contexts'] is List) 'contexts': data['contexts'],
      if (data['integrationTypes'] is List)
        'integrationTypes': data['integrationTypes'],
      'enabled': normalized['enabled'] != false,
      'script': script,
    });
  }

  final inboundWebhooks = <Map<String, dynamic>>[];
  // Legacy settings store an enable/disable bool in inboundWebhooks. Only
  // actual lists contain endpoints; do not migrate or overwrite stored data.
  final endpoints = [
    for (final raw in [
      appData['inboundWebhooks'],
      appData['inboundWebhookEndpoints'],
    ])
      if (raw is List) ...raw,
  ];
  final usedWebhookPaths = <String>{};
  for (final endpoint in endpoints) {
    if (endpoint is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(endpoint);
    final script = linkedScript(map);
    if (script.trim().isEmpty) {
      continue;
    }
    final hookPath = (map['path'] ?? '').toString().trim();
    // Le runner refuse toute la config pour un chemin vide ou en double.
    if (hookPath.isEmpty || !usedWebhookPaths.add(hookPath.toLowerCase())) {
      debugPrint('[buildJsBotPayload] Skipping inbound webhook "$hookPath".');
      continue;
    }
    inboundWebhooks.add({
      'id': (map['id'] ?? map['path'] ?? '').toString(),
      'type': 'inboundWebhook',
      'path': (map['path'] ?? '').toString(),
      'secret': (map['secret'] ?? '').toString(),
      'enabled': map['enabled'] != false,
      'script': script,
    });
  }

  final scheduled = <Map<String, dynamic>>[];
  final triggers = (appData['scheduledTriggers'] as List?) ?? const [];
  for (final trigger in triggers) {
    if (trigger is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(trigger);
    final script = linkedScript(map);
    if (script.trim().isEmpty) {
      continue;
    }
    final everyMinutes =
        int.tryParse((map['everyMinutes'] ?? '').toString()) ?? 0;
    if (everyMinutes <= 0) {
      continue;
    }
    final scheduleId = (map['id'] ?? map['workflowName'] ?? '').toString();
    if (scheduleId.trim().isEmpty) continue; // `id` doit être non vide
    scheduled.add({
      'id': scheduleId,
      'type': 'scheduled',
      'name': (map['workflowName'] ?? '').toString(),
      'everyMinutes': everyMinutes,
      'enabled': map['enabled'] != false,
      'script': script,
    });
  }

  final events = <Map<String, dynamic>>[];
  final usedEventIds = <String>{};
  for (final rawWorkflow in workflows) {
    final wf = normalizeStoredWorkflowDefinition(
      Map<String, dynamic>.from(rawWorkflow),
    );
    if (normalizeWorkflowType(wf['workflowType']) != workflowTypeEvent) {
      continue;
    }
    final trigger = normalizeWorkflowEventTrigger(wf['eventTrigger']);
    final eventName = trigger['event'].toString().trim();
    if (eventName.isEmpty) {
      continue;
    }

    final executionMode = (wf['executionMode'] ?? workflowExecutionModeWorkflow)
        .toString()
        .trim()
        .toLowerCase();
    var script = normalizeWorkflowJsScriptContent(wf['jsScriptContent']);
    if (executionMode != workflowExecutionModeJavascript &&
        script.trim().isEmpty) {
      script =
          synthesizeJsFromWorkflowActions(
            (wf['actions'] as List?) ?? const [],
            preferMessage: true,
          ) ??
          '';
    }
    if (script.trim().isEmpty) {
      continue;
    }

    var eventId = (wf['name'] ?? eventName).toString();
    if (eventId.trim().isEmpty) eventId = eventName;
    final baseEventId = eventId;
    var eventSuffix = 2;
    while (!usedEventIds.add(eventId)) {
      eventId = '${baseEventId}_$eventSuffix';
      eventSuffix += 1;
    }
    events.add({
      'id': eventId,
      'type': 'event',
      'name': eventName,
      'enabled': true,
      'script': script,
    });
  }

  final prefixRaw = (appData['prefix'] ?? '').toString().trim();
  final includePrefix = prefixRaw.isNotEmpty;

  final presenceStatusRaw = (appData['presenceStatus'] ?? 'online')
      .toString()
      .trim()
      .toLowerCase();
  const allowedPresence = {'online', 'idle', 'dnd', 'invisible'};
  final presenceStatus = allowedPresence.contains(presenceStatusRaw)
      ? presenceStatusRaw
      : 'online';

  final presenceActivities = <Map<String, dynamic>>[];
  final rawActivities =
      (appData['activities'] as List?) ??
      (appData['statuses'] as List?) ??
      const [];
  for (final entry in rawActivities) {
    if (entry is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(entry);
    final name = (map['name'] ?? map['text'] ?? '').toString().trim();
    if (name.isEmpty) {
      continue;
    }
    final typeRaw = (map['type'] ?? 'playing').toString().trim().toLowerCase();
    const allowedTypes = {
      'playing', 'streaming', 'listening', 'watching', 'competing', //
    };
    final type = allowedTypes.contains(typeRaw) ? typeRaw : 'playing';
    final url = (map['url'] ?? '').toString().trim();
    presenceActivities.add({
      'type': type,
      'name': name,
      if (url.isNotEmpty) 'url': url,
    });
  }

  final payload = <String, dynamic>{
    'runtimeEngine': runtimeEngineJavascript,
    'bdfdUserVariableSemantics': appData['bdfdUserVariableSemantics'] == 2
        ? 2
        : 1,
    'token': token,
    if (includePrefix) 'prefix': prefixRaw,
    'autoRestart': appData['autoRestart'] == true,
    'presence': {'status': presenceStatus, 'activities': presenceActivities},
    'intents': Map<String, bool>.from(
      (appData['intents'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value == true),
          ) ??
          const {},
    ),
    'commands': commands,
    'events': events,
    'scheduled': scheduled,
    'inboundWebhooks': inboundWebhooks,
    // Les définitions d'ÉDITEUR doivent voyager avec les listes converties du
    // runner : le document serveur est REMPLACÉ en entier par cette poussée, et
    // sans ces clés les workflows, déclencheurs planifiés et webhooks entrants
    // enregistrés disparaissaient à chaque synchro (le Studio les affichait
    // vides, l'app les perdait au prochain aller-retour).
    'workflows': [for (final w in workflows) Map<String, dynamic>.from(w)],
    'scheduledTriggers': [
      for (final t
          in appData['scheduledTriggers'] is List
              ? appData['scheduledTriggers'] as List
              : const [])
        if (t is Map) Map<String, dynamic>.from(t),
    ],
    'inboundWebhookEndpoints': [
      for (final e
          in appData['inboundWebhooks'] is List
              ? appData['inboundWebhooks'] as List
              : const [])
        if (e is Map) Map<String, dynamic>.from(e),
    ],
    'globalVariables': Map<String, dynamic>.from(
      (appData['globalVariables'] as Map?) ?? const {},
    ),
    'scopedVariableDefinitions': List<Map<String, dynamic>>.from(
      (appData['scopedVariableDefinitions'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    ),
    'databaseConfig': Map<String, dynamic>.from(
      (appData['databaseConfig'] as Map?) ?? const {'type': 'none'},
    ),
    'scriptTimeoutMs': 15 * 60 * 1000,
  };

  // POURQUOI cette garde est ICI : ce constructeur SAUTE les commandes sans
  // script (`continue` ci-dessus) et pouvait donc rendre une charge utile
  // « vide sans automatisation » — exactement la charge de 378 octets qui a
  // remplacé la config d'un bot. On refuse explicitement au lieu de rendre du
  // vide : l'appelant reçoit une erreur lisible, et rien n'est poussé.
  assertNonDegenerateBotPayload(payload, source: 'buildJsBotPayload');
  return payload;
}

Future<void> validateJsBotPayloadOrThrow(String botId) async {
  await buildJsBotPayload(botId);
}
