import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

Future<Map<String, dynamic>> buildJsBotPayload(String botId) async {
  final appData = await AppManager().getApp(botId);
  if (appData.isEmpty) {
    throw StateError('Bot "$botId" not found in local storage.');
  }

  final token = (appData['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    throw StateError('Bot "$botId" has no token configured.');
  }

  final commandsRaw = await AppManager().listAppCommands(botId);
  final commands = <Map<String, dynamic>>[];

  for (final command in commandsRaw) {
    if (command is! Map) {
      continue;
    }
    final normalized = normalizeCommandData(Map<String, dynamic>.from(command));
    final data = Map<String, dynamic>.from(
      (normalized['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final executionMode =
        (data['executionMode'] ?? 'workflow').toString().trim().toLowerCase();
    if (executionMode != 'javascript') {
      continue;
    }

    final script = (data['jsScriptContent'] ?? '').toString();
    if (script.trim().isEmpty) {
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
    final script = (map['jsScriptContent'] ?? '').toString();
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
    final script = (map['jsScriptContent'] ?? '').toString();
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

  return {
    'runtimeEngine': runtimeEngineJavascript,
    'token': token,
    'prefix': (appData['prefix'] ?? '!').toString(),
    'autoRestart': appData['autoRestart'] == true,
    'intents': Map<String, bool>.from(
      (appData['intents'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value == true),
          ) ??
          const {},
    ),
    'commands': commands,
    'events': const <Map<String, dynamic>>[],
    'scheduled': scheduled,
    'inboundWebhooks': inboundWebhooks,
    'globalVariables': Map<String, dynamic>.from(
      (appData['globalVariables'] as Map?) ?? const {},
    ),
    'scriptTimeoutMs': 30000,
  };
}

Future<void> validateJsBotPayloadOrThrow(String botId) async {
  final payload = await buildJsBotPayload(botId);
  final commands = (payload['commands'] as List?) ?? const [];
  if (commands.isEmpty) {
    throw StateError(
      'This JavaScript bot has no JavaScript commands. Add at least one command in JavaScript mode.',
    );
  }
}
