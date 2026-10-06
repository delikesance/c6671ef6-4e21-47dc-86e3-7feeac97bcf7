import './nyxx_lite.dart';

bool commandOptionSupportsAutocomplete(CommandOptionType type) {
  return type == CommandOptionType.string ||
      type == CommandOptionType.integer ||
      type == CommandOptionType.number;
}

String commandOptionTypeToText(CommandOptionType type) {
  if (type == CommandOptionType.subCommand) return 'subCommand';
  if (type == CommandOptionType.subCommandGroup) return 'subCommandGroup';
  if (type == CommandOptionType.string) return 'string';
  if (type == CommandOptionType.integer) return 'integer';
  if (type == CommandOptionType.boolean) return 'boolean';
  if (type == CommandOptionType.user) return 'user';
  if (type == CommandOptionType.channel) return 'channel';
  if (type == CommandOptionType.role) return 'role';
  if (type == CommandOptionType.mentionable) return 'mentionable';
  if (type == CommandOptionType.number) return 'number';
  if (type == CommandOptionType.attachment) return 'attachment';
  return 'string';
}

Map<String, dynamic>? normalizeSerializedAutocompleteConfig(dynamic raw) {
  if (raw is! Map) {
    return null;
  }

  final source = Map<String, dynamic>.from(
    raw.map((key, value) => MapEntry(key.toString(), value)),
  );

  final rawMode = (source['mode'] ?? '').toString().trim();
  final mode = rawMode == 'static'
      ? 'static'
      : rawMode == 'inline'
      ? 'inline'
      : 'workflow';

  final workflow = (source['workflow'] ?? '').toString().trim();
  final entryPoint = (source['entryPoint'] ?? 'main').toString().trim();

  final arguments = <String, dynamic>{};
  if (source['arguments'] is Map) {
    final rawArguments = Map<String, dynamic>.from(
      (source['arguments'] as Map).map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
    for (final entry in rawArguments.entries) {
      final key = entry.key.trim();
      if (key.isEmpty) {
        continue;
      }
      arguments[key] = entry.value;
    }
  }

  final staticChoices = <Map<String, dynamic>>[];
  if (source['staticChoices'] is List) {
    for (final raw in (source['staticChoices'] as List)) {
      if (raw is! Map) continue;
      staticChoices.add(
        Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
  }

  final inlineActions = <Map<String, dynamic>>[];
  if (source['inlineActions'] is List) {
    for (final raw in (source['inlineActions'] as List)) {
      if (raw is! Map) continue;
      inlineActions.add(
        Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v))),
      );
    }
  }

  final enabled =
      source['enabled'] == true ||
      (source['enabled'] == null &&
          (workflow.isNotEmpty ||
              arguments.isNotEmpty ||
              staticChoices.isNotEmpty ||
              inlineActions.isNotEmpty));

  if (!enabled &&
      workflow.isEmpty &&
      arguments.isEmpty &&
      staticChoices.isEmpty &&
      inlineActions.isEmpty) {
    return null;
  }

  return <String, dynamic>{
    'enabled': enabled,
    'mode': mode,
    'workflow': workflow,
    'entryPoint': entryPoint.isEmpty ? 'main' : entryPoint,
    'arguments': arguments,
    if (staticChoices.isNotEmpty) 'staticChoices': staticChoices,
    if (inlineActions.isNotEmpty) 'inlineActions': inlineActions,
  };
}
