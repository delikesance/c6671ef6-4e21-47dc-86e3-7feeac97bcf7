import 'dart:convert';

import 'package:bot_creator/core/discord/discord_intent_sync.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';

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
  final commands = <Map<String, dynamic>>[];

  for (final command in commandsRaw) {
    final normalized = normalizeCommandData(Map<String, dynamic>.from(command));
    final data = Map<String, dynamic>.from(
      (normalized['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final executionMode =
        (data['executionMode'] ?? 'workflow').toString().trim().toLowerCase();
    var script = (data['jsScriptContent'] ?? data['script'] ?? '').toString();
    if (executionMode != 'javascript') {
      if (script.trim().isEmpty) {
        script = _synthesizeJsFromWorkflowActions(
          (data['actions'] as List?) ?? const [],
        ) ?? '';
      }
      if (script.trim().isEmpty) {
        continue;
      }
    } else if (script.trim().isEmpty) {
      continue;
    }

    commands.add({
      'id': (normalized['id'] ?? '').toString(),
      'type': 'command',
      'name': (normalized['name'] ?? '').toString(),
      'description': (data['description'] ?? normalized['name'] ?? '').toString(),
      'options': data['options'] ?? const [],
      'enabled': normalized['enabled'] != false,
      'script': script,
    });
  }

  final inboundWebhooks = <Map<String, dynamic>>[];
  final endpoints = (appData['inboundWebhookEndpoints'] as List?) ?? const [];
  for (final endpoint in endpoints) {
    if (endpoint is! Map) {
      continue;
    }
    final map = Map<String, dynamic>.from(endpoint);
    final script = (map['jsScriptContent'] ?? map['script'] ?? '').toString();
    if (script.trim().isEmpty) {
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
    final script = (map['jsScriptContent'] ?? map['script'] ?? '').toString();
    if (script.trim().isEmpty) {
      continue;
    }
    final everyMinutes = int.tryParse((map['everyMinutes'] ?? '').toString()) ?? 0;
    if (everyMinutes <= 0) {
      continue;
    }
    scheduled.add({
      'id': (map['id'] ?? map['workflowName'] ?? '').toString(),
      'type': 'scheduled',
      'name': (map['workflowName'] ?? '').toString(),
      'everyMinutes': everyMinutes,
      'enabled': map['enabled'] != false,
      'script': script,
    });
  }

  final events = <Map<String, dynamic>>[];
  final workflows = await AppManager().getWorkflows(botId);
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

    final executionMode =
        (wf['executionMode'] ?? workflowExecutionModeWorkflow).toString().trim().toLowerCase();
    var script = normalizeWorkflowJsScriptContent(wf['jsScriptContent']);
    if (executionMode != workflowExecutionModeJavascript && script.trim().isEmpty) {
      script = _synthesizeJsFromWorkflowActions(
            (wf['actions'] as List?) ?? const [],
            preferMessage: true,
          ) ??
          '';
    }
    if (script.trim().isEmpty) {
      continue;
    }

    events.add({
      'id': (wf['name'] ?? eventName).toString(),
      'type': 'event',
      'name': eventName,
      'enabled': true,
      'script': script,
    });
  }

  final prefixRaw = (appData['prefix'] ?? '').toString().trim();
  final hasPrefixCommands = commands.any((command) {
    final name = (command['name'] ?? '').toString().trim();
    return name.isNotEmpty;
  });
  final includePrefix = prefixRaw.isNotEmpty && hasPrefixCommands;

  return {
    'runtimeEngine': runtimeEngineJavascript,
    'token': token,
    if (includePrefix) 'prefix': prefixRaw,
    'autoRestart': appData['autoRestart'] == true,
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
    'globalVariables': Map<String, dynamic>.from(
      (appData['globalVariables'] as Map?) ?? const {},
    ),
    'scopedVariableDefinitions': List<Map<String, dynamic>>.from(
      (appData['scopedVariableDefinitions'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    ),
    'scriptTimeoutMs': 15 * 60 * 1000,
  };
}

Future<void> validateJsBotPayloadOrThrow(String botId) async {
  await buildJsBotPayload(botId);
}

String? _synthesizeJsFromWorkflowActions(
  List<dynamic> actions, {
  bool preferMessage = false,
}) {
  for (final raw in actions) {
    if (raw is! Map) {
      continue;
    }
    final type = (raw['type'] ?? '').toString();
    if (type != 'respondWithMessage' && type != 'sendMessage') {
      continue;
    }
    final payload = Map<String, dynamic>.from(
      (raw['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final content = (payload['content'] ?? '').toString();
    if (content.trim().isEmpty) {
      continue;
    }
    final ephemeral = payload['ephemeral'] == true;
    if (preferMessage) {
      return 'await message.reply(${jsonEncode(content)});';
    }
    if (ephemeral) {
      return 'await interaction.reply({ content: ${jsonEncode(content)}, ephemeral: true });';
    }
    return 'await interaction.reply(${jsonEncode(content)});';
  }
  return null;
}
