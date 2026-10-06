import 'dart:convert';

/// Placeholders the Manager leaves in library entries: Discord IDs and e-mail addresses.
final _placeholderPattern = RegExp(r'\{\{(id_\d+|email)\}\}');
final _discordId = RegExp(r'^\d{15,22}$');
final _plainValue = RegExp(r'^[^\s"\\{}]{1,40}$');

const _libraryModes = {'bdfd_script', 'javascript', 'workflow'};

/// Builds the arguments of a `local_create_command` from a library entry, so the model only has to
/// send the differences: new name/description, real IDs for the `{{id_N}}` placeholders and exact
/// text replacements. Replacements are applied to the entry's template first, then the placeholders
/// are filled, so a replacement may itself contain a placeholder.
Map<String, dynamic> deriveLibraryCommandArgs(
  Map<String, dynamic> entry, {
  required String botId,
  required String name,
  String? description,
  Map<String, dynamic> values = const {},
  List replacements = const [],
}) {
  final mode = entry['mode'];
  if (mode is! String || !_libraryModes.contains(mode)) {
    throw const FormatException('Library entry has an unsupported mode');
  }
  var text = mode == 'workflow'
      ? jsonEncode(entry['actions'] ?? const [])
      : (entry['script'] as String? ?? '');
  if (text.trim().isEmpty) {
    throw const FormatException('Library entry has no content');
  }
  for (var i = 0; i < replacements.length; i++) {
    final replacement = replacements[i] as Map;
    final find = replacement['find'] as String;
    if (!text.contains(find)) {
      throw FormatException(
        'Replacement ${i + 1}: the text to replace is not in the library entry',
      );
    }
    text = text.split(find).join(replacement['replace'] as String);
  }
  final missing = <String>{};
  String fill(String input) =>
      input.replaceAllMapped(_placeholderPattern, (match) {
        final token = match.group(0)!;
        final key = match.group(1)!;
        final value = values[token] ?? values[key];
        if (value is! String) {
          missing.add(token);
          return token;
        }
        final valid = key.startsWith('id_')
            ? _discordId.hasMatch(value)
            : _plainValue.hasMatch(value);
        if (!valid) {
          throw FormatException(
            key.startsWith('id_')
                ? 'The value for $token must be a Discord ID'
                : 'The value for $token is not valid',
          );
        }
        return value;
      });
  final filledText = fill(text);
  final filledOptions = fill(jsonEncode(entry['options'] ?? const []));
  if (missing.isNotEmpty) {
    throw FormatException(
      'Provide a value for: ${(missing.toList()..sort()).join(', ')}',
    );
  }
  return {
    'bot_id': botId,
    'name': name,
    'description': description ?? entry['description'],
    'execution_mode': mode,
    'options': jsonDecode(filledOptions),
    if (mode == 'workflow')
      'actions_json': filledText
    else
      'script': filledText,
  };
}

int _occurrences(String text, String find) {
  var count = 0;
  for (
    var at = text.indexOf(find);
    at != -1;
    at = text.indexOf(find, at + find.length)
  ) {
    count++;
  }
  return count;
}

/// Applies exact substitutions to a script. Each `find` must occur exactly once in the text as it
/// stands when that edit is applied, otherwise nothing is changed (the caller never sees a partial
/// result). The replacement is inserted literally: BDFD uses `$` everywhere.
String patchCopilotScript(String script, List edits) {
  var text = script;
  for (var i = 0; i < edits.length; i++) {
    final edit = edits[i] as Map;
    final find = edit['find'] as String;
    final found = _occurrences(text, find);
    if (found == 0) {
      throw FormatException('Edit ${i + 1}: the text to replace was not found');
    }
    if (found > 1) {
      throw FormatException(
        'Edit ${i + 1}: the text occurs $found times; include more context to make it unique',
      );
    }
    final at = text.indexOf(find);
    text =
        text.substring(0, at) +
        (edit['replace'] as String) +
        text.substring(at + find.length);
  }
  if (text == script) {
    throw const FormatException('The edits do not change the script');
  }
  return text;
}

/// The execution mode and source of a stored command (or of one of its subcommand routes).
({String mode, String script}) copilotCommandScript(
  Map<String, dynamic> command, {
  String? route,
}) {
  final data = Map<String, dynamic>.from(command['data'] as Map? ?? {});
  var source = data;
  if (route != null) {
    final workflows = data['subcommandWorkflows'];
    if (workflows is! Map || workflows[route] is! Map) {
      throw StateError('Subcommand route not found');
    }
    source = Map<String, dynamic>.from(workflows[route] as Map);
  }
  final mode =
      (source['executionMode'] ?? data['executionMode'] ?? 'bdfd_script')
          .toString();
  final script = switch (mode) {
    'javascript' => source['jsScriptContent'],
    'workflow' => '',
    _ => source['bdfdScriptContent'],
  };
  return (mode: mode, script: (script as String?) ?? '');
}
