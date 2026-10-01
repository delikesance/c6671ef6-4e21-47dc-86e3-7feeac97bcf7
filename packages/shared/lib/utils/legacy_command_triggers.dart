/// Legacy ("Message Text") command trigger helpers.
///
/// A legacy command is an app command whose `data` map enables legacy mode
/// (`data.legacyModeEnabled == true`) or declares a hybrid trigger. It is triggered by typing the app prefix
/// (`!` by default) followed by one of its trigger words:
///
/// * the effective name — `data.legacyPrefixOverride` when non-empty, otherwise
///   the root `name` of the command;
/// * any of the extra words listed in `data.legacyAliases`.
///
/// A trigger word may carry a `{$t}` / `{$t:5s}` modifier that deletes the
/// triggering message (immediately, or after the given delay). The modifier is
/// ignored for matching but kept for delay extraction.
library;

import 'command_trigger_type.dart';

/// Maximum number of aliases kept by [normalizeLegacyCommandAliases].
const int kMaxLegacyCommandAliases = 10;

/// Maximum length of a single alias kept by [normalizeLegacyCommandAliases].
const int kMaxLegacyCommandAliasLength = 32;

/// Matches a timed-trigger modifier such as `{$t}` or `{$t:5s}`, anywhere.
final RegExp _timedTriggerPattern = RegExp(
  r'\{\$t(?::[^}]+)?\}',
  caseSensitive: false,
);

/// Matches a timed-trigger modifier and captures its optional delay value.
final RegExp _timedTriggerCapturePattern = RegExp(
  r'\{\$t(?::([^}]+))?\}',
  caseSensitive: false,
);

/// Matches a numeric delay such as `5`, `500ms`, `2m` or `1.5h`.
final RegExp _delayValuePattern = RegExp(
  r'^(\d+(?:\.\d+)?)\s*(ms|s|m|h)?$',
  caseSensitive: false,
);

/// Matches any whitespace character.
final RegExp _whitespacePattern = RegExp(r'\s');

/// Removes `{$t}` / `{$t:5s}` modifiers from [rawName], then trims and
/// lowercases the result.
String cleanLegacyCommandTriggerName(String rawName) {
  return rawName.replaceAll(_timedTriggerPattern, '').trim().toLowerCase();
}

/// Extracts the delay encoded in the `{$t}` / `{$t:5s}` modifier of [rawName].
///
/// Returns `null` when [rawName] carries no modifier, [Duration.zero] when the
/// modifier has no (or an unparsable) delay, and the parsed delay otherwise.
Duration? extractLegacyCommandTimedTriggerDelay(String rawName) {
  final match = _timedTriggerCapturePattern.firstMatch(rawName);
  if (match == null) return null;
  final delayStr = match.group(1)?.trim();
  if (delayStr == null || delayStr.isEmpty) {
    return Duration.zero;
  }
  final numMatch = _delayValuePattern.firstMatch(delayStr);
  if (numMatch != null) {
    final value = double.tryParse(numMatch.group(1)!) ?? 0;
    final unit = numMatch.group(2)?.toLowerCase() ?? 's';
    switch (unit) {
      case 'ms':
        return Duration(milliseconds: value.round());
      case 'm':
        return Duration(milliseconds: (value * 60000).round());
      case 'h':
        return Duration(milliseconds: (value * 3600000).round());
      case 's':
      default:
        return Duration(milliseconds: (value * 1000).round());
    }
  }
  return Duration.zero;
}

/// Normalizes a raw `data.legacyAliases` value into a clean trigger list.
///
/// Every entry is cast to string, trimmed, lowercased and stripped of a single
/// leading `!`. An entry is dropped when it is empty or when, once its `{$t}`
/// modifier is removed, it is empty or contains inner whitespace. Entries longer
/// than [maxLength] characters are truncated to [maxLength] characters.
/// Duplicates are removed by comparing their cleaned trigger name (the first
/// occurrence wins) and at most [maxAliases] entries are kept, in input order.
///
/// Tolerates dirty input: a non-list [raw] yields an empty list and non-string
/// entries are ignored.
List<String> normalizeLegacyCommandAliases(
  dynamic raw, {
  int maxAliases = kMaxLegacyCommandAliases,
  int maxLength = kMaxLegacyCommandAliasLength,
}) {
  if (raw is! List || maxAliases <= 0) return const <String>[];
  final aliases = <String>[];
  final seenTriggers = <String>{};
  for (final entry in raw) {
    if (entry is! String) continue;
    var alias = entry.trim();
    if (alias.startsWith('!')) {
      alias = alias.substring(1).trim();
    }
    if (alias.isEmpty) continue;
    if (alias.length > maxLength) {
      alias = alias.substring(0, maxLength);
    }
    alias = alias.toLowerCase();
    final trigger = cleanLegacyCommandTriggerName(alias);
    if (trigger.isEmpty || _whitespacePattern.hasMatch(trigger)) continue;
    if (seenTriggers.add(trigger)) {
      aliases.add(alias);
      if (aliases.length >= maxAliases) break;
    }
  }
  return aliases;
}

/// Returns the effective legacy trigger names of [command]: the cleaned
/// effective name first, then the cleaned aliases, deduplicated with a stable
/// order.
///
/// Returns an empty list unless invocation mode is prefix or hybrid — callers are
/// expected to also check the command type themselves (legacy commands are
/// chat-input commands, i.e. `type` is `chatInput` or empty).
List<String> legacyCommandTriggerNames(Map<String, dynamic> command) {
  if (!_isLegacyCommand(command)) return const <String>[];
  final names = <String>[];
  final seen = <String>{};
  void addTrigger(String rawTrigger) {
    final cleaned = cleanLegacyCommandTriggerName(rawTrigger);
    if (cleaned.isNotEmpty && seen.add(cleaned)) {
      names.add(cleaned);
    }
  }

  addTrigger(_effectiveRawTriggerName(command));
  for (final alias in normalizeLegacyCommandAliases(
    _legacyAliasRawValue(command),
  )) {
    addTrigger(alias);
  }
  return names;
}

/// Whether [typedName] (the first word typed after the app prefix) triggers
/// [command] through its effective name or through one of its aliases.
///
/// The comparison is exact and case-insensitive; `{$t}` / `{$t:5s}` modifiers
/// are ignored on both sides.
bool legacyCommandMatchesTrigger({
  required Map<String, dynamic> command,
  required String typedName,
}) {
  return _matchedLegacyTrigger(command: command, typedName: typedName) != null;
}

/// Delay to wait before deleting the triggering message when [typedName]
/// triggers [command], or `null` when no message deletion is configured.
///
/// The delay of the matched trigger word wins; when that word carries no
/// `{$t}` modifier, the modifier of the effective name is used as a fallback so
/// timed commands keep working when invoked through an alias.
Duration? legacyCommandTimedTriggerDelay({
  required Map<String, dynamic> command,
  required String typedName,
}) {
  final matched = _matchedLegacyTrigger(command: command, typedName: typedName);
  if (matched == null) return null;
  return extractLegacyCommandTimedTriggerDelay(matched) ??
      extractLegacyCommandTimedTriggerDelay(_effectiveRawTriggerName(command));
}

/// Whether [command] enabled the legacy ("Message Text") mode.
bool _isLegacyCommand(Map<String, dynamic> command) {
  return const {'prefix', 'hybrid'}.contains(commandTriggerType(command));
}

/// Raw (unstripped) effective name of [command]: `data.legacyPrefixOverride`
/// when non-empty, otherwise the root `name`.
String _effectiveRawTriggerName(Map<String, dynamic> command) {
  final data = command['data'];
  final override = data is Map
      ? (data['legacyPrefixOverride'] ?? '').toString().trim()
      : '';
  if (override.isNotEmpty) return override;
  return (command['name'] ?? '').toString();
}

/// Raw `data.legacyAliases` value of [command], or `null` when absent.
dynamic _legacyAliasRawValue(Map<String, dynamic> command) {
  final data = command['data'];
  return data is Map ? data['legacyAliases'] : null;
}

/// Raw text of the trigger word (effective name or alias) matched by
/// [typedName], or `null` when nothing matches.
///
/// Candidate order gives priority to the effective name, then to the aliases in
/// their stored order; the first matching candidate wins.
String? _matchedLegacyTrigger({
  required Map<String, dynamic> command,
  required String typedName,
}) {
  if (!_isLegacyCommand(command)) return null;
  final typed = cleanLegacyCommandTriggerName(typedName);
  if (typed.isEmpty) return null;
  final candidates = <String>[
    _effectiveRawTriggerName(command),
    ...normalizeLegacyCommandAliases(_legacyAliasRawValue(command)),
  ];
  for (final candidate in candidates) {
    if (cleanLegacyCommandTriggerName(candidate) == typed) {
      return candidate;
    }
  }
  return null;
}
