import 'dart:convert';

import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_command.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/types/action.dart' as blocks;
import 'package:bot_creator_shared/utils/event_catalog.dart';
import 'package:bot_creator_shared/utils/command_trigger_type.dart';

bool copilotCommandUsesDiscord(Map<String, dynamic> command) =>
    {'slash', 'hybrid'}.contains(commandTriggerType(command));

Map<String, dynamic> copyCopilotMap(Map source) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);

void requireCopilotRevision(Object source, String expected) {
  if (HashUtil.calculateHash(source) != expected) {
    throw StateError(
      'Configuration changed; read its latest revision before editing',
    );
  }
}

List<Map<String, dynamic>> validateCopilotOptions(List raw, {int depth = 0}) {
  if (raw.length > 25 || depth > 2) {
    throw const FormatException('Too many options or subcommand levels');
  }
  final names = <String>{};
  var optionalSeen = false;
  final options = raw.map((item) {
    if (item is! Map) throw const FormatException('Invalid option');
    final option = copyCopilotMap(item);
    final name = option['name'];
    final description = option['description'];
    if (name is! String ||
        !RegExp(r"^[a-z0-9_\-]{1,32}$").hasMatch(name) ||
        !names.add(name) ||
        description is! String ||
        description.trim().isEmpty ||
        description.length > 100) {
      throw const FormatException(
        'Invalid or duplicate option name/description',
      );
    }
    final type = option['type'];
    const types = {
      'string',
      'integer',
      'number',
      'boolean',
      'user',
      'channel',
      'role',
      'mentionable',
      'attachment',
      'subCommand',
      'subCommandGroup',
    };
    if (!types.contains(type)) {
      throw const FormatException('Unsupported option type');
    }
    final container = type == 'subCommand' || type == 'subCommandGroup';
    if (container) {
      if (depth == 2 ||
          (type == 'subCommandGroup' && depth != 0) ||
          option['required'] == true ||
          option.containsKey('choices') ||
          option.containsKey('autocomplete')) {
        throw const FormatException('Invalid subcommand structure');
      }
      // The editor serializer writes required:null/false on containers.
      // Discord accepts required only for leaf arguments.
      option.remove('required');
      option['options'] = validateCopilotOptions(
        option['options'] as List? ?? [],
        depth: depth + 1,
      );
      final children = option['options'] as List;
      if (type == 'subCommandGroup' &&
          (children.isEmpty ||
              children.any((o) => o['type'] != 'subCommand'))) {
        throw const FormatException('A group must contain subcommands');
      }
      if (type == 'subCommand' &&
          children.any(
            (o) => o['type'] == 'subCommand' || o['type'] == 'subCommandGroup',
          )) {
        throw const FormatException('A subcommand must contain arguments');
      }
    } else {
      if (option.containsKey('options')) {
        throw const FormatException('Arguments cannot contain options');
      }
      if (option['required'] == true && optionalSeen) {
        throw const FormatException(
          'Required arguments must precede optional arguments',
        );
      }
      optionalSeen = optionalSeen || option['required'] != true;
      final choices = option['choices'];
      final autocomplete = option['autocomplete'];
      if ((choices != null || autocomplete != null) &&
          !{'string', 'integer', 'number'}.contains(type)) {
        throw const FormatException(
          'This option type does not support choices/autocomplete',
        );
      }
      if (choices != null) {
        if (choices is! List ||
            choices.length > 25 ||
            autocomplete is Map && autocomplete['enabled'] == true) {
          throw const FormatException(
            'Invalid choices or choices with autocomplete',
          );
        }
        for (final choice in choices) {
          if (choice is! Map ||
              choice['name'] is! String ||
              (choice['name'] as String).isEmpty ||
              (choice['name'] as String).length > 100) {
            throw const FormatException('Invalid choice');
          }
          final value = choice['value'];
          if (type == 'string'
              ? value is! String || value.length > 100
              : type == 'integer'
              ? value is! int
              : value is! num) {
            throw const FormatException(
              'Choice value does not match option type',
            );
          }
        }
      }
      for (final key in ['minValue', 'maxValue']) {
        if (option[key] != null &&
            (!{'integer', 'number'}.contains(type) ||
                option[key] is! num ||
                type == 'integer' && option[key] is! int)) {
          throw const FormatException('Invalid numeric bound');
        }
      }
      if (option['minValue'] != null &&
          option['maxValue'] != null &&
          (option['minValue'] as num) > (option['maxValue'] as num)) {
        throw const FormatException('Minimum exceeds maximum');
      }
      for (final key in ['minLength', 'maxLength']) {
        if (option[key] != null &&
            (type != 'string' ||
                option[key] is! int ||
                (option[key] as int) < (key == 'minLength' ? 0 : 1) ||
                (option[key] as int) > 6000)) {
          throw const FormatException('Invalid text length bound');
        }
      }
      if (option['minLength'] != null &&
          option['maxLength'] != null &&
          (option['minLength'] as int) > (option['maxLength'] as int)) {
        throw const FormatException('Minimum length exceeds maximum');
      }
      if (option['channelTypes'] != null && type != 'channel') {
        throw const FormatException('Channel types require a channel option');
      }
    }
    return option;
  }).toList();
  if (options.any(
        (o) => o['type'] == 'subCommand' || o['type'] == 'subCommandGroup',
      ) &&
      options.any(
        (o) => o['type'] != 'subCommand' && o['type'] != 'subCommandGroup',
      )) {
    throw const FormatException(
      'Cannot mix subcommands and arguments at one level',
    );
  }
  final encoded = jsonEncode(options);
  // Discord's aggregate text limit includes command metadata; allow its share here.
  var textLength = 0;
  void count(Object? value) {
    if (value is Map) {
      for (final entry in value.entries) {
        if ({'name', 'description', 'value'}.contains(entry.key) &&
            entry.value is String) {
          textLength += (entry.value as String).length;
        } else if (entry.value is Map || entry.value is List) {
          count(entry.value);
        }
      }
    } else if (value is List) {
      for (final item in value) {
        count(item);
      }
    }
  }

  count(options);
  if (textLength > 7868 || encoded.length > 64000) {
    throw const FormatException('Command options are too large');
  }
  return options;
}

List<String> copilotOptionRoutes(List options, [String prefix = '']) {
  final result = <String>[];
  for (final raw in options.whereType<Map>()) {
    final route = prefix.isEmpty ? '${raw['name']}' : '$prefix/${raw['name']}';
    if (raw['type'] == 'subCommand') result.add(route);
    if (raw['type'] == 'subCommandGroup') {
      result.addAll(copilotOptionRoutes(raw['options'] as List? ?? [], route));
    }
  }
  return result;
}

Map<String, dynamic> withCopilotOptions(
  Map<String, dynamic> command,
  List options,
) {
  final copy = copyCopilotMap(command);
  final data = copyCopilotMap(copy['data'] as Map? ?? {});
  data['options'] = validateCopilotOptions(options);
  final oldRoutes = data['subcommandWorkflows'] as Map? ?? {};
  final routes = copilotOptionRoutes(options);
  if (routes.isNotEmpty || oldRoutes.isNotEmpty) {
    data['subcommandWorkflows'] = {
      for (final route in routes)
        route: copyCopilotMap(
          oldRoutes[route] as Map? ??
              {
                for (final key in [
                  'executionMode',
                  'bdfdScriptContent',
                  'jsScriptContent',
                  'actions',
                  'response',
                ])
                  if (data.containsKey(key)) key: data[key],
              },
        ),
    };
  }
  copy['data'] = data;
  return copy;
}

Map<String, dynamic> updateCopilotOptions(
  Map<String, dynamic> command,
  Map<String, dynamic> args,
) {
  requireCopilotRevision(command, args['expected_revision'] as String);
  if ((command['type'] ?? 'chatInput') != 'chatInput') {
    throw const FormatException('Only slash commands have options');
  }
  final copy = copyCopilotMap(command);
  final data = copy['data'] as Map? ?? {};
  final options = List<dynamic>.from(data['options'] as List? ?? []);
  List current = options;
  final path = List<String>.from(args['path'] as List? ?? []);
  for (final part in path) {
    final matches = current
        .whereType<Map>()
        .where((o) => o['name'] == part)
        .toList();
    if (matches.length != 1 ||
        !{'subCommand', 'subCommandGroup'}.contains(matches.single['type'])) {
      throw StateError('Subcommand path not found');
    }
    current =
        matches.single['options'] as List? ??
        (matches.single['options'] = <dynamic>[]);
  }
  final name = args['option_name'];
  final index = current.indexWhere((o) => o is Map && o['name'] == name);
  switch (args['operation']) {
    case 'add':
      if (index >= 0) throw StateError('Option already exists');
      final option = copyCopilotMap(args['option'] as Map? ?? {});
      if (option['name'] != name) {
        throw const FormatException('Option name does not match');
      }
      current.add(option);
    case 'update':
      if (index < 0) throw StateError('Option not found');
      final option = {
        ...copyCopilotMap(current[index] as Map),
        ...copyCopilotMap(args['option'] as Map? ?? {}),
      };
      if (option['name'] != name && _executionUsesOption(data, path, name)) {
        throw StateError(
          'The execution refers to this option; update those references before renaming',
        );
      }
      if (option['name'] != name &&
          {'subCommand', 'subCommandGroup'}.contains(option['type'])) {
        final oldPrefix = [...path, name].join('/');
        final newPrefix = [...path, option['name']].join('/');
        final routes = data['subcommandWorkflows'] as Map?;
        if (routes != null) {
          for (final key in routes.keys.toList()) {
            if (key == oldPrefix || '$key'.startsWith('$oldPrefix/')) {
              routes['$newPrefix${'$key'.substring(oldPrefix.length)}'] = routes
                  .remove(key);
            }
          }
        }
      }
      current[index] = option;
    case 'remove':
      if (index < 0) throw StateError('Option not found');
      if (_executionUsesOption(data, path, name)) {
        throw StateError(
          'The execution refers to this option; update those references before removing it',
        );
      }
      current.removeAt(index);
    default:
      throw const FormatException('Unsupported option operation');
  }
  // Required arguments are always ordered first without changing their relative order.
  void order(List list) {
    final ordered = [
      ...list.where((o) => o['required'] == true),
      ...list.where((o) => o['required'] != true),
    ];
    list
      ..clear()
      ..addAll(ordered);
    for (final item in list) {
      if (item['options'] is List) order(item['options'] as List);
    }
  }

  order(options);
  return withCopilotOptions(copy, options);
}

bool _executionUsesOption(Map data, List path, String name) {
  final texts = <String>[jsonEncode(data)];
  void inspect(Object? value) {
    if (value is Map) {
      final source = value['bdfdScriptContent'];
      if (source is String && source.trim().isNotEmpty) {
        // Source is retained in BDFD mode; derive references using the same
        // compiler as execution, including $message[argument] expressions.
        texts.add(jsonEncode(compileCopilotCommand(source)));
      }
      for (final child in value.values) {
        inspect(child);
      }
    } else if (value is List) {
      for (final child in value) {
        inspect(child);
      }
    }
  }

  inspect(data);
  final names = {
    name,
    [...path, name].join('.'),
  };
  return names.any(
    (option) => texts.any(
      (text) => RegExp(
        'opts\\.${RegExp.escape(option)}(?![A-Za-z0-9_])',
      ).hasMatch(text),
    ),
  );
}

Map<String, dynamic> copilotPresence(Map app) => {
  'presenceStatus': app['presenceStatus'] ?? 'online',
  'activities': app['activities'] ?? app['statuses'] ?? [],
};

Map<String, dynamic> validateCopilotPresence(Map<String, dynamic> args) {
  if (!{'online', 'idle', 'dnd', 'invisible'}.contains(args['status'])) {
    throw const FormatException('Unsupported presence status');
  }
  final activities = (args['activities'] as List).map((raw) {
    final status = BotStatusConfig.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
    status.validate();
    return status.toJson();
  }).toList();
  return {'presenceStatus': args['status'], 'activities': activities};
}

Map<String, dynamic> buildCopilotWorkflow(
  Map<String, dynamic> args, {
  Map? existing,
  required bool javascriptRuntime,
  bool legacyUserVariables = false,
}) {
  final copy = copyCopilotMap(existing ?? {});
  final mode =
      args['execution_mode'] ??
      copy['executionMode'] ??
      (javascriptRuntime ? 'javascript' : 'workflow');
  if (javascriptRuntime != (mode == 'javascript')) {
    throw StateError('Workflow execution mode does not match bot runtime');
  }
  List<Map<String, dynamic>> actions;
  if (mode == 'javascript') {
    final script = args['script'] ?? copy['jsScriptContent'];
    if (script is! String || script.trim().isEmpty || script.length > 12000) {
      throw const FormatException('JavaScript source is required');
    }
    copy['jsScriptContent'] = script;
    actions = [];
  } else if (mode == 'bdfd_script') {
    actions = compileCopilotCommand(
      args['script'] as String? ?? '',
      legacyUserVariables: legacyUserVariables,
    );
  } else if (mode == 'workflow') {
    final raw = args['actions'] ?? copy['actions'];
    if (raw is! List || raw.isEmpty || raw.length > 80) {
      throw const FormatException('Workflow blocks are required');
    }
    actions = raw
        .map(
          (item) =>
              blocks.Action.fromJson(copyCopilotMap(item as Map)).toJson(),
        )
        .toList();
  } else {
    throw const FormatException('Unsupported workflow execution mode');
  }
  copy.addAll({
    'name': args['name'],
    'actions': actions,
    'executionMode': mode == 'javascript' ? 'javascript' : 'workflow',
    'workflowType': args['workflow_type'] ?? copy['workflowType'] ?? 'general',
    'entryPoint': args['entry_point'] ?? copy['entryPoint'] ?? 'main',
    'arguments': args['arguments'] ?? copy['arguments'] ?? [],
  });
  if (copy['workflowType'] == 'event') {
    final event = args['event_trigger'] ?? copy['eventTrigger'];
    if (event is! Map ||
        !EventCatalog.getEvents().any(
          (e) => e.event == event['event'] && e.category == event['category'],
        )) {
      throw const FormatException(
        'Choose a supported event from local_list_events',
      );
    }
    copy['eventTrigger'] = copyCopilotMap(event);
  } else {
    copy.remove('eventTrigger');
  }
  final names = <String>{};
  for (final argument in copy['arguments'] as List) {
    if (argument is! Map ||
        argument['name'] is! String ||
        !RegExp(r'^[A-Za-z0-9_]{1,64}$').hasMatch(argument['name'] as String) ||
        !names.add(argument['name'] as String)) {
      throw const FormatException('Invalid or duplicate workflow argument');
    }
  }
  return copy;
}
