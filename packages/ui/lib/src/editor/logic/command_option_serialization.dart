import 'dart:convert';

import '../../discord/nyxx_lite.dart';
import '../../discord/command_autocomplete_lite.dart';

export '../../discord/command_autocomplete_lite.dart'
    show commandOptionSupportsAutocomplete, commandOptionTypeToText;

final Expando<Map<String, dynamic>> _autocompleteConfigExpando =
    Expando<Map<String, dynamic>>('command_option_autocomplete_config');

CommandOptionType commandOptionTypeFromText(String text) {
  final normalized = text.trim().toLowerCase();
  switch (normalized) {
    case 'subcommand':
      return CommandOptionType.subCommand;
    case 'subcommandgroup':
      return CommandOptionType.subCommandGroup;
    case 'integer':
      return CommandOptionType.integer;
    case 'boolean':
      return CommandOptionType.boolean;
    case 'user':
      return CommandOptionType.user;
    case 'channel':
      return CommandOptionType.channel;
    case 'role':
      return CommandOptionType.role;
    case 'mentionable':
      return CommandOptionType.mentionable;
    case 'number':
      return CommandOptionType.number;
    case 'attachment':
      return CommandOptionType.attachment;
    case 'string':
    default:
      return CommandOptionType.string;
  }
}

Map<String, dynamic>? normalizeCommandOptionAutocompleteConfig(dynamic raw) {
  // Delegate to shared for canonical normalization
  final result = normalizeSerializedAutocompleteConfig(raw);
  if (result == null) {
    return null;
  }

  // App-specific: always emit 'staticChoices' (shared omits it if empty)
  if (!result.containsKey('staticChoices')) {
    result['staticChoices'] = <Map<String, dynamic>>[];
  }

  // App-specific: auto-enable when mode is 'inline'
  // (shared auto-enables on inlineActions.isNotEmpty instead)
  if (result['mode'] == 'inline' && result['enabled'] != true) {
    result['enabled'] = true;
  }

  // App-specific: auto-enable when mode is 'javascript'
  if (result['mode'] == 'javascript' && result['enabled'] != true) {
    result['enabled'] = true;
  }

  return result;
}

Map<String, dynamic>? getCommandOptionAutocompleteConfig(
  CommandOptionBuilder option,
) {
  final config = _autocompleteConfigExpando[option];
  if (config != null) {
    return cloneJsonMap(config);
  }
  if (option.hasAutocomplete == true) {
    return <String, dynamic>{
      'enabled': true,
      'mode': 'workflow',
      'workflow': '',
      'entryPoint': 'main',
      'arguments': <String, dynamic>{},
      'staticChoices': <Map<String, dynamic>>[],
    };
  }
  return null;
}

bool isCommandOptionAutocompleteEnabled(CommandOptionBuilder option) {
  final config = getCommandOptionAutocompleteConfig(option);
  return config != null && config['enabled'] == true;
}

void setCommandOptionAutocompleteConfig(
  CommandOptionBuilder option,
  Map<String, dynamic>? rawConfig,
) {
  final normalized = normalizeCommandOptionAutocompleteConfig(rawConfig);
  _autocompleteConfigExpando[option] = normalized == null
      ? null
      : cloneJsonMap(normalized);
  option.hasAutocomplete = normalized?['enabled'] == true;
  if (option.hasAutocomplete == true) {
    option.choices = null;
  }
}

Map<String, dynamic> serializeCommandOption(CommandOptionBuilder option) {
  final autocomplete = getCommandOptionAutocompleteConfig(option);
  return <String, dynamic>{
    'type': commandOptionTypeToText(option.type),
    'name': option.name,
    'description': option.description,
    'required': option.isRequired,
    if (option.minValue != null) 'minValue': option.minValue,
    if (option.maxValue != null) 'maxValue': option.maxValue,
    if (option.minLength != null) 'minLength': option.minLength,
    if (option.maxLength != null) 'maxLength': option.maxLength,
    if (option.channelTypes != null)
      'channelTypes': option.channelTypes!.map((type) => type.value).toList(),
    'autocomplete': ?autocomplete,
    if (autocomplete == null && option.choices?.isNotEmpty == true)
      'choices': option.choices!
          .map((choice) => {'name': choice.name, 'value': choice.value})
          .toList(growable: false),
    if (option.options?.isNotEmpty == true)
      'options': serializeCommandOptions(option.options!),
  };
}

List<Map<String, dynamic>> serializeCommandOptions(
  List<CommandOptionBuilder> options,
) {
  return options.map(serializeCommandOption).toList(growable: false);
}

CommandOptionBuilder deserializeCommandOption(Map<String, dynamic> raw) {
  final rawMin = raw['minValue'];
  final rawMax = raw['maxValue'];
  final rawMinLen = raw['minLength'];
  final rawMaxLen = raw['maxLength'];
  final num? minValue = rawMin is num
      ? rawMin
      : num.tryParse(rawMin?.toString() ?? '');
  final num? maxValue = rawMax is num
      ? rawMax
      : num.tryParse(rawMax?.toString() ?? '');
  final int? minLength = rawMinLen is int
      ? rawMinLen
      : int.tryParse(rawMinLen?.toString() ?? '');
  final int? maxLength = rawMaxLen is int
      ? rawMaxLen
      : int.tryParse(rawMaxLen?.toString() ?? '');

  final option = CommandOptionBuilder(
    type: commandOptionTypeFromText((raw['type'] ?? '').toString()),
    name: (raw['name'] ?? '').toString(),
    description: (raw['description'] ?? '').toString(),
    isRequired: raw['required'] == true,
    minValue: minValue,
    maxValue: maxValue,
    minLength: minLength,
    maxLength: maxLength,
    channelTypes: (raw['channelTypes'] as List?)
        ?.map((type) {
          final intVal = type is int
              ? type
              : int.tryParse(type?.toString() ?? '');
          return intVal != null ? ChannelType(intVal) : null;
        })
        .whereType<ChannelType>()
        .toList(),
  );

  final autocompleteConfig = normalizeCommandOptionAutocompleteConfig(
    raw['autocomplete'],
  );
  if (autocompleteConfig != null) {
    setCommandOptionAutocompleteConfig(option, autocompleteConfig);
  } else {
    option.hasAutocomplete = raw['hasAutocomplete'] == true;
  }

  final choicesRaw = raw['choices'];
  if (choicesRaw is List && option.hasAutocomplete != true) {
    option.choices = choicesRaw
        .whereType<Map>()
        .map(
          (choice) => CommandOptionChoiceBuilder(
            name: (choice['name'] ?? '').toString(),
            value: choice['value'],
          ),
        )
        .toList();
  }

  final nestedOptionsRaw = raw['options'];
  if (nestedOptionsRaw is List) {
    option.options = nestedOptionsRaw
        .whereType<Map>()
        .map(
          (entry) => deserializeCommandOption(Map<String, dynamic>.from(entry)),
        )
        .toList(growable: false);
  }

  return option;
}

List<CommandOptionBuilder> deserializeCommandOptions(List<dynamic> rawOptions) {
  return rawOptions
      .whereType<Map>()
      .map(
        (entry) => deserializeCommandOption(Map<String, dynamic>.from(entry)),
      )
      .toList(growable: false);
}

Map<String, dynamic> cloneJsonMap(Map<String, dynamic> source) {
  return Map<String, dynamic>.from(jsonDecode(jsonEncode(source)) as Map);
}

Map<String, dynamic> cloneSubcommandWorkflowPayloads(
  Map<String, Map<String, dynamic>> payloads,
) {
  return Map<String, dynamic>.from(jsonDecode(jsonEncode(payloads)) as Map);
}
