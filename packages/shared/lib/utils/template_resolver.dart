import 'dart:convert';
import 'dart:math';

import 'math_parser.dart';
import '../services/text_operations.dart';
import 'runtime_cooldowns.dart';

final _random = Random();

class _ResolvedExpression {
  const _ResolvedExpression({required this.found, this.value});

  final bool found;
  final dynamic value;
}

List<Object>? _parseJsonPathSegments(String rawPath) {
  var path = rawPath.trim();
  if (path.isEmpty) {
    return null;
  }

  if (path.startsWith(r'$.')) {
    path = path.substring(2);
  } else if (path.startsWith(r'$')) {
    path = path.substring(1);
  }

  if (path.isEmpty) {
    return const <Object>[];
  }

  final segments = <Object>[];
  final token = StringBuffer();

  void flushToken() {
    if (token.isNotEmpty) {
      segments.add(token.toString());
      token.clear();
    }
  }

  for (var index = 0; index < path.length; index++) {
    final char = path[index];
    if (char == '.') {
      flushToken();
      continue;
    }

    if (char == '[') {
      flushToken();
      final closing = path.indexOf(']', index + 1);
      if (closing == -1) {
        return null;
      }
      final indexText = path.substring(index + 1, closing).trim();
      final listIndex = int.tryParse(indexText);
      if (listIndex == null) {
        return null;
      }
      segments.add(listIndex);
      index = closing;
      continue;
    }

    token.write(char);
  }

  flushToken();
  return segments;
}

List<Object>? parseJsonPathSegments(String rawPath) {
  return _parseJsonPathSegments(rawPath);
}

dynamic extractJsonPathValue(dynamic data, String rawPath) {
  final segments = _parseJsonPathSegments(rawPath);
  if (segments == null) {
    return null;
  }

  dynamic current = data;
  for (final segment in segments) {
    if (segment is String) {
      if (segment.isEmpty) {
        continue;
      }
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
      continue;
    }

    if (segment is int) {
      if (current is List && segment >= 0 && segment < current.length) {
        current = current[segment];
      } else {
        return null;
      }
    }
  }

  return current;
}

String _stringifyResolvedValue(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  if (value is num || value is bool) {
    return value.toString();
  }
  return jsonEncode(value);
}

dynamic decodeJsonStringIfNeeded(dynamic value) {
  if (value is! String) {
    return value;
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return value;
  }

  final looksJson =
      (trimmed.startsWith('[') && trimmed.endsWith(']')) ||
      (trimmed.startsWith('{') && trimmed.endsWith('}')) ||
      trimmed == 'null';
  if (!looksJson) {
    return value;
  }

  try {
    return jsonDecode(trimmed);
  } catch (_) {
    return value;
  }
}

// Resolve clock functions on demand; initial event snapshots must not freeze them.
String? _resolveLiveClock(String key) {
  if (key == 'gettimestamp' || key == 'timestamp') {
    return (DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000).toString();
  }
  if (key == 'gettimestampms' || key == 'timestampms') {
    return DateTime.now().toUtc().millisecondsSinceEpoch.toString();
  }
  if (key == 'actualtime') {
    return DateTime.now().toUtc().toIso8601String();
  }
  if (key == 'day') {
    return DateTime.now().day.toString();
  }
  if (key == 'month') {
    return DateTime.now().month.toString();
  }
  if (key == 'year') {
    return DateTime.now().year.toString();
  }
  if (key == 'hour') {
    return DateTime.now().hour.toString();
  }
  if (key == 'minute') {
    return DateTime.now().minute.toString();
  }
  if (key == 'second') {
    return DateTime.now().second.toString();
  }
  if (key == 'time') {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}:'
        '${now.second.toString().padLeft(2, '0')}';
  }
  if (key == 'date') {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  return null;
}

String? _lookupVariableValue(String key, Map<String, String> updates) {
  final cooldown = RegExp(
    r'^cooldown(?:\[([^\]]*)\])?\.remaining$',
    caseSensitive: false,
  ).firstMatch(key);
  if (cooldown != null) {
    return RuntimeCooldowns.query(updates, cooldown.group(1));
  }
  final loweredUptimeKey = key.toLowerCase();
  if (loweredUptimeKey == 'bot.uptime' || loweredUptimeKey == 'uptime') {
    final rawUptime = updates['bot.uptime'] ?? '0';
    final uptimeMs = int.tryParse(rawUptime) ?? 0;
    final seconds = uptimeMs ~/ 1000;
    final hrs = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hrs.toString().padLeft(2, '0')}:'
        '${mins.toString().padLeft(2, '0')}:'
        '${secs.toString().padLeft(2, '0')}';
  }
  if (updates['__runtime.liveClock'] == 'true') {
    final clockValue = _resolveLiveClock(key.toLowerCase());
    if (clockValue != null) return clockValue;
  }
  final val = updates[key];
  if (val != null) {
    return val;
  }

  final loweredKey = key.toLowerCase();
  for (final entry in updates.entries) {
    if (entry.key.toLowerCase() == loweredKey) {
      return entry.value;
    }
  }

  // Check if it's a dynamic dataUrl lookup
  if (loweredKey.endsWith('.dataurl')) {
    final baseKey = key.substring(0, key.length - '.dataurl'.length);
    final baseValue = _lookupVariableValue(baseKey, updates);
    if (baseValue != null) {
      return 'data:image/png;base64,$baseValue';
    }
  }

  // Check if it's a dynamic createEmoji lookup
  if (loweredKey.startsWith('_bdfd_createemoji_') &&
      !loweredKey.contains('.')) {
    final emojiId =
        _lookupVariableValue('$key.emojiId', updates) ??
        _lookupVariableValue('$loweredKey.emojiid', updates);
    if (emojiId != null && emojiId.isNotEmpty) {
      final name =
          _lookupVariableValue('$key.name', updates) ??
          _lookupVariableValue('$loweredKey.name', updates) ??
          '';
      final animated =
          (_lookupVariableValue('$key.animated', updates) ??
              _lookupVariableValue('$loweredKey.animated', updates)) ==
          'true';
      return '<${animated ? 'a' : ''}:$name:$emojiId>';
    }
  }

  final clockValue = _resolveLiveClock(loweredKey);
  if (clockValue != null) return clockValue;

  // Dynamic random property fallbacks
  if (loweredKey == 'random.userid' || loweredKey == 'randomuserid') {
    return _pickRandomEntityId(updates['random.userIds']);
  }
  if (loweredKey == 'random.user' || loweredKey == 'randomuser') {
    final id = _pickRandomEntityId(updates['random.userIds']);
    if (id.isEmpty) return '';
    try {
      final names = jsonDecode(updates['random.userNames'] ?? '{}');
      if (names is Map) return names[id]?.toString() ?? id;
    } catch (_) {}
    return id;
  }
  if (loweredKey == 'random.mention' || loweredKey == 'randommention') {
    final id = _pickRandomEntityId(updates['random.userIds']);
    return id.isEmpty ? '' : '<@$id>';
  }
  if (loweredKey == 'random.channelid' || loweredKey == 'randomchannelid') {
    return _pickRandomEntityId(updates['random.channelIds']);
  }
  if (loweredKey == 'random.guildid' || loweredKey == 'randomguildid') {
    return _pickRandomEntityId(updates['random.guildIds']);
  }
  if (loweredKey == 'random.roleid' || loweredKey == 'randomroleid') {
    return _pickRandomEntityId(updates['random.roleIds']);
  }
  if (loweredKey == 'random.categoryid' || loweredKey == 'randomcategoryid') {
    return _pickRandomEntityId(updates['random.categoryIds']);
  }

  // Numeric member count fallbacks for BDFD compliance
  if (loweredKey == 'guild.onlinemembers' ||
      loweredKey == 'guild.offlinemembers' ||
      loweredKey == 'guild.idlemembers' ||
      loweredKey == 'guild.dndmembers' ||
      loweredKey == 'guild.invisiblemembers' ||
      loweredKey == 'onlinemembers' ||
      loweredKey == 'guild.membercount' ||
      loweredKey == 'membercount' ||
      loweredKey == 'allmemberscount') {
    return '0';
  }

  // Contextual fallback for user[<id>].<prop> and member[<id>].<prop>
  final userBracketMatch = RegExp(
    r'^(user|member)\[([^\]]+)\]\.(.+)$',
    caseSensitive: false,
  ).firstMatch(key);
  if (userBracketMatch != null) {
    final targetId = userBracketMatch.group(2)!.trim();
    final prop = userBracketMatch.group(3)!.trim();
    final lowerProp = prop.toLowerCase();
    final authorId = (updates['author.id'] ?? updates['user.id'] ?? '').trim();
    if (authorId.isNotEmpty && targetId == authorId) {
      if (lowerProp == 'username') {
        final u = updates['author.username'] ?? updates['user.username'];
        if (u != null) return u;
      } else if (lowerProp == 'avatar') {
        final a =
            updates['author.avatar'] ??
            updates['user.avatar'] ??
            updates['member.avatar'];
        if (a != null) return a;
      } else if (lowerProp == 'displayname') {
        final d =
            updates['member.displayName'] ??
            updates['author.displayName'] ??
            updates['user.displayName'] ??
            updates['author.username'];
        if (d != null) return d;
      } else if (lowerProp == 'globalname') {
        final g =
            updates['author.globalName'] ??
            updates['user.globalName'] ??
            updates['author.username'];
        if (g != null) return g;
      } else if (lowerProp == 'nick' || lowerProp == 'nickname') {
        final n =
            updates['member.nick'] ??
            updates['author.displayName'] ??
            updates['author.username'];
        if (n != null) return n;
      } else if (lowerProp == 'tag' || lowerProp == 'discriminator') {
        final t = updates['author.tag'] ?? updates['user.tag'];
        if (t != null) return t;
      } else if (lowerProp == 'isbot') {
        return updates['author.isBot'] ?? updates['user.isBot'] ?? 'false';
      } else if (lowerProp == 'isadmin') {
        return updates['member.isAdmin'] ?? 'false';
      } else if (lowerProp == 'isbooster') {
        return updates['member.isBooster'] ?? 'false';
      } else if (lowerProp == 'exists') {
        return 'true';
      } else if (lowerProp.startsWith('bc_')) {
        final customVal =
            updates['user.$prop'] ??
            updates['user.${prop.toLowerCase()}'] ??
            updates['member.$prop'] ??
            updates['member.${prop.toLowerCase()}'];
        if (customVal != null) return customVal;
      } else {
        final customVal =
            updates['user.bc_$prop'] ??
            updates['user.bc_${prop.toLowerCase()}'] ??
            updates['user.$prop'] ??
            updates['member.bc_$prop'] ??
            updates['member.$prop'];
        if (customVal != null) return customVal;
      }
    }
  }

  // Contextual fallback for guild[<id>].<prop> and server[<id>].<prop>
  final guildBracketMatch = RegExp(
    r'^(guild|server)\[([^\]]+)\]\.(.+)$',
    caseSensitive: false,
  ).firstMatch(key);
  if (guildBracketMatch != null) {
    final targetId = guildBracketMatch.group(2)!.trim();
    final prop = guildBracketMatch.group(3)!.trim();
    final lowerProp = prop.toLowerCase();
    final guildId = (updates['guild.id'] ?? updates['server.id'] ?? '').trim();
    if (guildId.isNotEmpty && targetId == guildId) {
      if (lowerProp.startsWith('bc_')) {
        final customVal = updates['guild.$prop'] ?? updates['server.$prop'];
        if (customVal != null) return customVal;
      } else {
        final customVal =
            updates['guild.bc_$prop'] ??
            updates['server.bc_$prop'] ??
            updates['guild.$prop'] ??
            updates['server.$prop'];
        if (customVal != null) return customVal;
      }
    }
  }

  // Contextual fallback for channel[<id>].<prop>
  final channelBracketMatch = RegExp(
    r'^channel\[([^\]]+)\]\.(.+)$',
    caseSensitive: false,
  ).firstMatch(key);
  if (channelBracketMatch != null) {
    final targetId = channelBracketMatch.group(1)!.trim();
    final prop = channelBracketMatch.group(2)!.trim();
    final lowerProp = prop.toLowerCase();
    final channelId = (updates['channel.id'] ?? '').trim();
    if (channelId.isNotEmpty && targetId == channelId) {
      if (lowerProp.startsWith('bc_')) {
        final customVal = updates['channel.$prop'];
        if (customVal != null) return customVal;
      } else {
        final customVal =
            updates['channel.bc_$prop'] ?? updates['channel.$prop'];
        if (customVal != null) return customVal;
      }
    }
  }

  // Boolean property fallbacks for BDFD compliance
  if (loweredKey.endsWith('.isbot') ||
      loweredKey.endsWith('.isadmin') ||
      loweredKey.endsWith('.isbooster') ||
      loweredKey.endsWith('.exists') ||
      loweredKey.endsWith('.isnsfw') ||
      loweredKey.endsWith('.nsfw') ||
      loweredKey.endsWith('.istimedout') ||
      loweredKey.endsWith('.isbanned') ||
      loweredKey == 'isbot' ||
      loweredKey == 'isadmin' ||
      loweredKey == 'isbooster' ||
      loweredKey == 'isnsfw' ||
      loweredKey == 'istimedout' ||
      loweredKey == 'isbanned' ||
      loweredKey == 'exists') {
    return 'false';
  }

  return null;
}

String _pickRandomEntityId(String? encoded) {
  if (encoded == null || encoded.isEmpty) return '';
  try {
    final ids = jsonDecode(encoded);
    if (ids is List && ids.isNotEmpty) {
      return ids[_random.nextInt(ids.length)].toString();
    }
  } catch (_) {}
  return '';
}

bool _isMeaningfulResolvedValue(dynamic value) {
  if (value == null) {
    return false;
  }
  if (value is String) {
    return value.trim().isNotEmpty;
  }
  return true;
}

bool _looksLikeLiteralFallback(String expression) {
  final trimmed = expression.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  if (_isWrappedStringLiteral(trimmed)) {
    return true;
  }
  return RegExp(r'^[^A-Za-z0-9_.$\[\]()]+$').hasMatch(trimmed);
}

dynamic _resolveComputedVariableValue(String key, Map<String, String> updates) {
  final markerIndex = key.lastIndexOf('.\$');
  if (markerIndex == -1) {
    return null;
  }

  final bodyVariableKey = key.substring(0, markerIndex);
  final jsonPathRaw = key.substring(markerIndex + 1);
  if (!jsonPathRaw.startsWith(r'$')) {
    return null;
  }

  final rawBody = _lookupVariableValue(bodyVariableKey, updates);
  if (rawBody == null || rawBody.isEmpty) {
    return null;
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(rawBody);
  } catch (_) {
    return null;
  }

  return extractJsonPathValue(decoded, jsonPathRaw);
}

List<String> _splitTopLevel(String input, String delimiter) {
  final parts = <String>[];
  final buffer = StringBuffer();
  var parenthesisDepth = 0;
  var bracketDepth = 0;
  String? quote;
  var escaping = false;

  for (var index = 0; index < input.length; index++) {
    final char = input[index];

    if (quote != null) {
      buffer.write(char);
      if (escaping) {
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }

    if (char == '"' || char == "'") {
      quote = char;
      buffer.write(char);
      continue;
    }

    if (char == '(') {
      parenthesisDepth++;
      buffer.write(char);
      continue;
    }

    if (char == ')') {
      if (parenthesisDepth > 0) {
        parenthesisDepth--;
      }
      buffer.write(char);
      continue;
    }

    if (char == '[') {
      bracketDepth++;
      buffer.write(char);
      continue;
    }

    if (char == ']') {
      if (bracketDepth > 0) {
        bracketDepth--;
      }
      buffer.write(char);
      continue;
    }

    if (parenthesisDepth == 0 &&
        bracketDepth == 0 &&
        input.startsWith(delimiter, index)) {
      parts.add(buffer.toString());
      buffer.clear();
      index += delimiter.length - 1;
      continue;
    }

    buffer.write(char);
  }

  parts.add(buffer.toString());
  return parts;
}

String _unescapeStringLiteral(String body) {
  final buffer = StringBuffer();
  for (var index = 0; index < body.length; index++) {
    final char = body[index];
    if (char != r'\' || index + 1 >= body.length) {
      buffer.write(char);
      continue;
    }

    final next = body[++index];
    switch (next) {
      case 'n':
        buffer.write('\n');
        break;
      case 'r':
        buffer.write('\r');
        break;
      case 't':
        buffer.write('\t');
        break;
      case r'\':
        buffer.write(r'\');
        break;
      case '"':
        buffer.write('"');
        break;
      case "'":
        buffer.write("'");
        break;
      default:
        buffer
          ..write(r'\')
          ..write(next);
        break;
    }
  }
  return buffer.toString();
}

String _toTitleCase(String input) {
  if (input.isEmpty) {
    return '';
  }

  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  var shouldUppercaseNext = true;

  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final isLetterOrDigit = RegExp(r'[a-z0-9]').hasMatch(char);
    if (!isLetterOrDigit) {
      shouldUppercaseNext = true;
      buffer.write(char);
      continue;
    }

    if (shouldUppercaseNext) {
      buffer.write(char.toUpperCase());
      shouldUppercaseNext = false;
    } else {
      buffer.write(char);
    }
  }

  return buffer.toString();
}

int _countLines(String input) {
  if (input.isEmpty) {
    return 0;
  }
  return input.replaceAll('\r\n', '\n').split('\n').length;
}

String _formatNumberWithSeparator(num value, String separator) {
  final parts = value.toString().split('.');
  final integerPart = parts[0];
  final decimalPart = parts.length > 1 ? parts[1] : '';

  final sign = integerPart.startsWith('-') ? '-' : '';
  final digits = sign.isEmpty ? integerPart : integerPart.substring(1);
  final grouped = <String>[];

  for (var i = digits.length; i > 0; i -= 3) {
    final start = (i - 3).clamp(0, digits.length);
    grouped.add(digits.substring(start, i));
  }

  final joined = grouped.reversed.join(separator);
  if (decimalPart.isEmpty) {
    return '$sign$joined';
  }
  return '$sign$joined.$decimalPart';
}

bool _isWrappedStringLiteral(String input) {
  if (input.length < 2) {
    return false;
  }
  final quote = input[0];
  if ((quote != '"' && quote != "'") || input[input.length - 1] != quote) {
    return false;
  }

  var escaping = false;
  for (var index = 1; index < input.length - 1; index++) {
    final char = input[index];
    if (escaping) {
      escaping = false;
      continue;
    }
    if (char == r'\') {
      escaping = true;
      continue;
    }
    if (char == quote) {
      return false;
    }
  }

  return true;
}

({String name, String inner})? _parseFunctionCall(String expression) {
  final openIndex = expression.indexOf('(');
  if (openIndex <= 0 || !expression.endsWith(')')) {
    return null;
  }

  final name = expression.substring(0, openIndex).trim();
  if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
    return null;
  }

  var depth = 0;
  String? quote;
  var escaping = false;
  for (var index = openIndex; index < expression.length; index++) {
    final char = expression[index];

    if (quote != null) {
      if (escaping) {
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }

    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }

    if (char == '(') {
      depth++;
      continue;
    }

    if (char == ')') {
      depth--;
      if (depth == 0 && index != expression.length - 1) {
        return null;
      }
      if (depth < 0) {
        return null;
      }
    }
  }

  if (depth != 0) {
    return null;
  }

  return (
    name: name,
    inner: expression.substring(openIndex + 1, expression.length - 1),
  );
}

_ResolvedExpression? _resolveBracketCollectionVariableValue(
  String key,
  Map<String, String> updates,
) {
  final openIndex = key.lastIndexOf('[');
  if (openIndex <= 0 || !key.endsWith(']')) {
    return null;
  }

  final baseKey = key.substring(0, openIndex).trim();
  if (baseKey.isEmpty) {
    return null;
  }

  final rawCollection = _lookupVariableValue('__collection.$baseKey', updates);
  if (rawCollection == null || rawCollection.isEmpty) {
    return null;
  }

  dynamic decoded;
  try {
    decoded = jsonDecode(rawCollection);
  } catch (_) {
    return null;
  }

  if (decoded is! List) {
    return null;
  }

  final items = decoded.map(_stringifyResolvedValue).toList(growable: false);
  final spec = key.substring(openIndex + 1, key.length - 1);
  final trimmedSpec = spec.trim();

  final numericIndex = int.tryParse(trimmedSpec);
  if (numericIndex != null) {
    final zeroBasedIndex = numericIndex - 1;
    if (zeroBasedIndex < 0 || zeroBasedIndex >= items.length) {
      return const _ResolvedExpression(found: true, value: '');
    }
    return _ResolvedExpression(found: true, value: items[zeroBasedIndex]);
  }

  if (trimmedSpec.isEmpty) {
    return const _ResolvedExpression(found: true, value: '');
  }

  final separatorIndex = spec.indexOf(';');
  final separator = separatorIndex == -1
      ? spec
      : spec.substring(0, separatorIndex);
  final limitRaw = separatorIndex == -1
      ? ''
      : spec.substring(separatorIndex + 1).trim();
  final limit = int.tryParse(limitRaw);
  final boundedItems = limit == null || limit < 0
      ? items
      : items.take(limit).toList(growable: false);
  return _ResolvedExpression(found: true, value: boundedItems.join(separator));
}

({String name, String inner})? _parseBracketFunctionCall(String expression) {
  final openIndex = expression.indexOf('[');
  if (openIndex <= 0 || !expression.endsWith(']')) {
    return null;
  }

  final name = expression.substring(0, openIndex).trim();
  if (!RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) {
    return null;
  }

  var depth = 0;
  String? quote;
  var escaping = false;
  for (var index = openIndex; index < expression.length; index++) {
    final char = expression[index];

    if (quote != null) {
      if (escaping) {
        escaping = false;
      } else if (char == r'\') {
        escaping = true;
      } else if (char == quote) {
        quote = null;
      }
      continue;
    }

    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }

    if (char == '[') {
      depth++;
      continue;
    }

    if (char == ']') {
      depth--;
      if (depth == 0 && index != expression.length - 1) {
        return null;
      }
      if (depth < 0) {
        return null;
      }
    }
  }

  if (depth != 0) {
    return null;
  }

  return (
    name: name,
    inner: expression.substring(openIndex + 1, expression.length - 1),
  );
}

double? _evaluateSimpleMathExpression(String expression) =>
    MathExpressionParser.evaluate(expression);

dynamic _applyBdfdBracketFunction(
  String rawName,
  List<String> rawArgs,
  List<dynamic> resolvedArgs,
  Map<String, String> updates,
) {
  final name = rawName.trim().toLowerCase();
  switch (name) {
    case 'userreacted':
      final parts = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .toList();
      final channelId = parts.isNotEmpty ? parts[0] : '';
      final messageId = parts.length > 1 ? parts[1] : '';
      final userId = parts.length > 2 ? parts[2] : '';
      final emoji = parts.length > 3 ? parts[3] : '';
      final key = 'userReacted[$channelId;$messageId;$userId;$emoji]';
      final lookup =
          _lookupVariableValue(key, updates) ??
          _lookupVariableValue(key.toLowerCase(), updates);
      if (lookup != null) return lookup;
      final shorthand = 'userReacted[$channelId;$messageId;$emoji]';
      final shortLookup =
          _lookupVariableValue(shorthand, updates) ??
          _lookupVariableValue(shorthand.toLowerCase(), updates);
      if (shortLookup != null) return shortLookup;
      return 'false';
    case 'leaderboardposition':
      final posJoined = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .join(';');
      final posKey = 'leaderboardPosition[$posJoined]';
      return _lookupVariableValue(posKey, updates) ??
          _lookupVariableValue(posKey.toLowerCase(), updates) ??
          _lookupVariableValue('leaderboard.position', updates) ??
          '1';
    case 'leaderboardvalue':
      final valJoined = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .join(';');
      final valKey = 'leaderboardValue[$valJoined]';
      return _lookupVariableValue(valKey, updates) ??
          _lookupVariableValue(valKey.toLowerCase(), updates) ??
          _lookupVariableValue('leaderboard.value', updates) ??
          '0';
    case 'globaluserleaderboard':
      final gulJoined = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .join(';');
      final gulKey = 'globalUserLeaderboard[$gulJoined]';
      return _lookupVariableValue(gulKey, updates) ??
          _lookupVariableValue(gulKey.toLowerCase(), updates) ??
          _lookupVariableValue('globalUserLeaderboard', updates) ??
          '';
    case 'serverleaderboard':
      final slJoined = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .join(';');
      final slKey = 'serverLeaderboard[$slJoined]';
      return _lookupVariableValue(slKey, updates) ??
          _lookupVariableValue(slKey.toLowerCase(), updates) ??
          _lookupVariableValue('serverLeaderboard', updates) ??
          '';
    case 'userleaderboard':
      final ulJoined = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .join(';');
      final ulKey = 'userLeaderboard[$ulJoined]';
      return _lookupVariableValue(ulKey, updates) ??
          _lookupVariableValue(ulKey.toLowerCase(), updates) ??
          _lookupVariableValue('userLeaderboard', updates) ??
          '';
    case 'bdfdhasrole':
      final roles = resolvedArgs.isEmpty
          ? ''
          : _stringifyResolvedValue(resolvedArgs.first);
      final roleId = resolvedArgs.length > 1
          ? _stringifyResolvedValue(resolvedArgs[1]).trim()
          : '';
      return (roleId.isNotEmpty &&
              roles.split(',').map((id) => id.trim()).contains(roleId))
          .toString();
    case 'bdfduserroles':
      final encoded = resolvedArgs.isEmpty
          ? '[]'
          : _stringifyResolvedValue(resolvedArgs.first);
      try {
        final names = jsonDecode(encoded);
        if (names is List) {
          return names
              .map((name) => name.toString())
              .where((name) => name.isNotEmpty && name != '@everyone')
              .join('\n');
        }
      } catch (_) {}
      return '';
    case 'bdfdismentioned':
      final userId = resolvedArgs.isEmpty ? '' : resolvedArgs.first.toString();
      if (userId.isEmpty) return 'false';
      final mentions = (updates['message.mentions'] ?? '')
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty);
      return mentions.contains(userId).toString();
    case 'bdfdmessageargument':
      final parts = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates).trim())
          .toList();
      final first = parts.isNotEmpty ? parts[0] : '';
      final second = parts.length > 1 ? parts[1] : '';
      final content = updates['message.content'] ?? '';
      final words = content
          .trim()
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();
      if (first.isEmpty && second.isEmpty) return content;
      if (first.startsWith('>')) {
        if (first == '>') return words.isEmpty ? '' : words.last;
        final skip = int.tryParse(first.substring(1));
        return skip != null && skip >= 0 ? words.skip(skip).join(' ') : '';
      }
      final start = int.tryParse(first);
      if (start != null && start > 0) {
        final end = int.tryParse(second);
        if (end != null && end > 0) {
          return words
              .skip(start - 1)
              .take((end - start + 1).clamp(0, words.length))
              .join(' ');
        }
        if (second.isEmpty && parts.length > 2 && parts[2] == 'true') {
          return words.skip(start - 1).join(' ');
        }
        final word = start <= words.length ? words[start - 1] : '';
        return word.isNotEmpty ? word : updates['opts.$second'] ?? '';
      }
      return updates['opts.${second.isNotEmpty ? second : first}'] ?? '';
    case 'bdfdmentionedusers':
    case 'bdfdmentionedchannels':
      final requested = rawArgs.isNotEmpty
          ? resolveTemplatePlaceholders(rawArgs[0], updates).trim()
          : '';
      final fallbackRaw = rawArgs.length > 1
          ? resolveTemplatePlaceholders(
              rawArgs[1],
              updates,
            ).trim().toLowerCase()
          : '';
      final index = int.tryParse(requested) ?? 1;
      final base = name == 'bdfdmentionedchannels'
          ? 'message.channelMentions'
          : 'message.mentions';
      final values = (updates[base] ?? '')
          .split(',')
          .where((id) => id.isNotEmpty)
          .toList();
      final value =
          updates['$base[${index - 1}]'] ??
          (index > 0 && index <= values.length ? values[index - 1] : '');
      final fallback = const {'true', 'yes', '1'}.contains(fallbackRaw);
      return value.isNotEmpty
          ? value
          : fallback
          ? updates[name == 'bdfdmentionedchannels'
                    ? 'channel.id'
                    : 'author.id'] ??
                ''
          : '';
    case 'bdfdremovelinks':
      return resolveTemplatePlaceholders(
        rawArgs.join(';'),
        updates,
      ).replaceAll(RegExp(r'https?://[^\s]+'), '');
    case 'bdfdusertag':
      final username = rawArgs.isNotEmpty
          ? resolveTemplatePlaceholders(rawArgs[0], updates)
          : '';
      final discriminator = rawArgs.length > 1
          ? resolveTemplatePlaceholders(rawArgs[1], updates)
          : '';
      // Contexts historically store the discriminator in user.tag/author.tag.
      // Accept a complete tag too, for callers supplying normalized fixtures.
      if (discriminator.contains('#')) return discriminator;
      final number = int.tryParse(discriminator);
      return number != null && number != 0
          ? '$username#$discriminator'
          : username;
    // Compiler-generated expressions for command-local textSplit state.
    case 'bdfdtextsplitinit':
    case 'bdfdtextsplitget':
    case 'bdfdtextsplitlength':
    case 'bdfdtextsplitindex':
    case 'bdfdtextsplitjoin':
    case 'bdfdtextsplitedit':
    case 'bdfdtextsplitremove':
      final args = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates))
          .toList();
      String arg(int index) => index < args.length ? args[index] : '';
      if (name == 'bdfdtextsplitinit') {
        return jsonEncode(arg(0).split(arg(1)));
      }
      final decoded = jsonDecode(updates['temp._bdfd_textsplit'] ?? '[]');
      final state = TextSplitState(
        (decoded as List).map((value) => value.toString()),
      );
      if (name == 'bdfdtextsplitlength') return state.length.toString();
      if (name == 'bdfdtextsplitindex') return state.indexOf(arg(0)).toString();
      if (name == 'bdfdtextsplitjoin') return state.join(arg(0));
      if (name == 'bdfdtextsplitget') return state.at(arg(0));
      final index = int.tryParse(arg(0).trim());
      if (index != null) {
        if (name == 'bdfdtextsplitedit') {
          state.edit(index, arg(1));
        } else {
          state.remove(index);
        }
      }
      return jsonEncode(state.values);
    case 'checkcontains':
      final args = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates))
          .toList();
      final text = args.isEmpty ? '' : args.first;
      return args.skip(1).any(text.contains) ? 'true' : 'false';
    case 'replacetext':
    case 'repeatmessage':
    case 'removecontains':
    case 'numberseparator':
      final args = rawArgs
          .map((arg) => resolveTemplatePlaceholders(arg, updates))
          .toList();
      final text = args.isEmpty ? '' : args.first;
      if (name == 'repeatmessage') {
        final count = int.tryParse(args.length > 1 ? args[1].trim() : '') ?? 1;
        return text * count.clamp(0, 100);
      }
      if (name == 'removecontains') {
        var result = text;
        for (final target in args.skip(1)) {
          if (target.isNotEmpty) result = result.replaceAll(target, '');
        }
        return result;
      }
      if (name == 'numberseparator') {
        final value = num.tryParse(text.trim());
        if (value == null) return '';
        final separator = args.length > 1 && args[1].isNotEmpty ? args[1] : ',';
        return _formatNumberWithSeparator(value, separator);
      }
      final sample = args.length > 1 ? args[1] : '';
      final replacement = args.length > 2 ? args[2] : '';
      final count = int.tryParse(args.length > 3 ? args[3].trim() : '') ?? 1;
      return replaceTextOccurrences(text, sample, replacement, amount: count);
    case 'calculate':
      if (rawArgs.isEmpty) {
        return null;
      }
      final expression = resolveTemplatePlaceholders(
        rawArgs.first,
        updates,
      ).trim();
      final result = _evaluateSimpleMathExpression(expression);
      if (result == null) {
        return null;
      }
      return MathExpressionParser.format(
        result,
        enableDecimals: _isEnableDecimals(updates),
      );
    case 'isnumber':
    case 'isinteger':
    case 'isboolean':
    case 'isvalidhex':
      final raw = rawArgs.isEmpty
          ? ''
          : resolveTemplatePlaceholders(rawArgs.first, updates).trim();
      switch (name.trim().toLowerCase()) {
        case 'isnumber':
          return num.tryParse(raw) != null;
        case 'isinteger':
          return int.tryParse(raw) != null;
        case 'isboolean':
          return const {
            'true',
            'false',
            'yes',
            'no',
            '1',
            '0',
            'on',
            'off',
          }.contains(raw.toLowerCase());
        default:
          final cleaned = raw.startsWith('#') ? raw.substring(1) : raw;
          return RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned);
      }
    case 'ceil':
      final ceilValue = resolvedArgs.isEmpty
          ? null
          : _coerceNum(resolvedArgs[0]);
      return ceilValue?.ceil();
    case 'floor':
      final floorValue = resolvedArgs.isEmpty
          ? null
          : _coerceNum(resolvedArgs[0]);
      return floorValue?.floor();
    case 'round':
      final roundValue = resolvedArgs.isEmpty
          ? null
          : _coerceNum(resolvedArgs[0]);
      return roundValue?.round();
    case 'sqrt':
      final sqrtValue = resolvedArgs.isEmpty
          ? null
          : _coerceNum(resolvedArgs[0]);
      if (sqrtValue == null) {
        return null;
      }
      return MathExpressionParser.format(
        sqrt(sqrtValue.toDouble()),
        enableDecimals: _isEnableDecimals(updates),
      );
    case 'max':
      if (resolvedArgs.length < 2) {
        return null;
      }
      final left = _coerceNum(resolvedArgs[0]);
      final right = _coerceNum(resolvedArgs[1]);
      if (left == null || right == null) {
        return null;
      }
      return MathExpressionParser.format(
        max(left, right),
        enableDecimals: _isEnableDecimals(updates),
      );
    case 'min':
      if (resolvedArgs.length < 2) {
        return null;
      }
      final left = _coerceNum(resolvedArgs[0]);
      final right = _coerceNum(resolvedArgs[1]);
      if (left == null || right == null) {
        return null;
      }
      return MathExpressionParser.format(
        min(left, right),
        enableDecimals: _isEnableDecimals(updates),
      );
    case 'modulo':
    case 'multi':
    case 'divide':
    case 'sub':
      if (resolvedArgs.length < 2) {
        return null;
      }
      final left = _coerceNum(resolvedArgs[0]);
      final right = _coerceNum(resolvedArgs[1]);
      if (left == null || right == null) {
        return null;
      }
      final enableDecimals = _isEnableDecimals(updates);
      switch (name) {
        case 'modulo':
          return MathExpressionParser.format(
            right != 0 ? left % right : 0,
            enableDecimals: enableDecimals,
          );
        case 'multi':
          return MathExpressionParser.format(
            left * right,
            enableDecimals: enableDecimals,
          );
        case 'divide':
          return MathExpressionParser.format(
            right != 0 ? left / right : 0,
            enableDecimals: enableDecimals,
          );
        case 'sub':
          return MathExpressionParser.format(
            left - right,
            enableDecimals: enableDecimals,
          );
      }
      return null;
    case 'checkcondition':
      // Argument is the raw (unresolved) condition expression, e.g.
      // "((sub[((getTimestamp));((uservar[...]...))]))>=86400". Resolve the
      // operand placeholders, then evaluate the comparison.
      if (rawArgs.isEmpty) {
        return null;
      }
      return _evaluateStringCondition(rawArgs[0], updates) ? 'true' : 'false';
    case 'totitlecase':
    case 'tolowercase':
    case 'touppercase':
    case 'url':
    case 'charcount':
    case 'linescount':
    case 'croptext':
    case 'split':
      return _applyFunction(name, resolvedArgs, updates);
    case 'bytecount':
      if (resolvedArgs.isEmpty) {
        return null;
      }
      return utf8.encode(_stringifyResolvedValue(resolvedArgs.first)).length;
    case 'trimcontent':
    case 'trimspace':
      if (resolvedArgs.isEmpty) {
        return null;
      }
      return _stringifyResolvedValue(resolvedArgs.first).trim();
    case 'sort':
      final values = resolvedArgs
          .map(_stringifyResolvedValue)
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      if (values.every((value) => num.tryParse(value) != null)) {
        values.sort((a, b) => num.parse(a).compareTo(num.parse(b)));
      } else {
        values.sort();
      }
      return values.join(';');
    case 'sum':
      if (resolvedArgs.isEmpty) {
        return null;
      }
      final enableDecimals = _isEnableDecimals(updates);
      if (resolvedArgs.length == 1) {
        final source = _coerceList(resolvedArgs[0]);
        if (source != null) {
          num total = 0;
          for (final item in source) {
            final numeric = _coerceNum(item);
            if (numeric != null) {
              total += numeric;
            }
          }
          return MathExpressionParser.format(
            total,
            enableDecimals: enableDecimals,
          );
        }
      }
      num total = 0;
      var foundNumeric = false;
      for (final arg in resolvedArgs) {
        final numeric = _coerceNum(arg);
        if (numeric == null) {
          return null;
        }
        foundNumeric = true;
        total += numeric;
      }
      return foundNumeric
          ? MathExpressionParser.format(total, enableDecimals: enableDecimals)
          : null;
    case 'random':
      if (resolvedArgs.length < 2) {
        return _random.nextBool() ? 'true' : '';
      }
      final enableDecimals = _isEnableDecimals(updates);
      if (enableDecimals) {
        final min = _coerceNum(resolvedArgs[0]) ?? 0;
        final max = _coerceNum(resolvedArgs[1]) ?? 1;
        if (max <= min) return null;
        final value = min + _random.nextDouble() * (max - min);
        return MathExpressionParser.format(value, enableDecimals: true);
      }
      final min = _coerceInt(resolvedArgs[0]);
      final max = _coerceInt(resolvedArgs[1]);
      if (min == null || max == null || max < min) {
        return null;
      }
      return min + _random.nextInt(max - min + 1);
    case 'randomstring':
      final length =
          (int.tryParse(
                    rawArgs.isEmpty
                        ? ''
                        : resolveTemplatePlaceholders(
                            rawArgs.first,
                            updates,
                          ).trim(),
                  ) ??
                  10)
              .clamp(1, 1000);
      const defaults =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      final supplied = rawArgs.length > 1
          ? resolveTemplatePlaceholders(rawArgs[1], updates)
          : '';
      final chars = (supplied.isEmpty ? defaults : supplied).runes.toList();
      return String.fromCharCodes(
        List.generate(length, (_) => chars[_random.nextInt(chars.length)]),
      );
    case 'randomtext':
      final sourceArgs = rawArgs.isNotEmpty
          ? rawArgs
          : resolvedArgs.map((a) => _stringifyResolvedValue(a)).toList();
      if (sourceArgs.isEmpty) {
        return '';
      }
      final options = sourceArgs.map((a) => a.trim()).toList();
      if (options.length == 1 && options.first.isEmpty) {
        return '';
      }
      final chosen = options[_random.nextInt(options.length)];
      return resolveTemplatePlaceholders(chosen, updates);
    case 'date':
      final now = DateTime.now();
      return '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    case 'and':
      if (rawArgs.isEmpty) {
        return 'false';
      }
      for (final arg in rawArgs) {
        if (!_evaluateStringCondition(arg, updates)) {
          return 'false';
        }
      }
      return 'true';
    case 'or':
      if (rawArgs.isEmpty) {
        return 'false';
      }
      for (final arg in rawArgs) {
        if (_evaluateStringCondition(arg, updates)) {
          return 'true';
        }
      }
      return 'false';
    case 'varexists':
      var key = resolvedArgs.isEmpty
          ? ''
          : _stringifyResolvedValue(resolvedArgs.first).trim().toLowerCase();
      if (key.startsWith('bc_')) key = key.substring(3);
      if (key.isEmpty) return 'false';
      return updates.keys.any((entry) => entry.toLowerCase() == 'temp.$key')
          ? 'true'
          : 'false';
    case 'listvar':
      final sep =
          (resolvedArgs.isNotEmpty
                  ? _stringifyResolvedValue(resolvedArgs.first)
                  : ', ')
              .replaceAll(r'\n', '\n');
      final entries =
          _inspectRuntimeVariables(updates)['temp'] ?? const <String, String>{};
      return entries.entries
          .map((entry) => '${entry.key}: ${jsonEncode(entry.value)}')
          .join(sep);
    case 'userperms':
      var userId = resolvedArgs.isNotEmpty
          ? _stringifyResolvedValue(resolvedArgs[0]).trim()
          : '';
      if (userId.isEmpty) {
        userId = _lookupVariableValue('author.id', updates) ?? '';
      }
      final returnAmount = resolvedArgs.length > 1
          ? _coerceInt(resolvedArgs[1]) ?? -1
          : -1;
      final separator = rawArgs.length > 2 ? rawArgs[2] : ', ';

      final authorId = _lookupVariableValue('author.id', updates) ?? '';
      final requestedPerms = resolvedArgs.length > 3
          ? _stringifyResolvedValue(resolvedArgs[3])
          : null;
      final rawPerms =
          requestedPerms ??
          _lookupVariableValue('permissions.byId.$userId', updates) ??
          (userId == authorId
              ? _lookupVariableValue('member.permissions', updates)
              : null) ??
          '';

      if (rawPerms.isEmpty) {
        return '';
      }

      final list = rawPerms
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final bdfdPerms = <String>[];
      for (final p in list) {
        final bdfdName = _mapToLowercaseToBdfdPerm(p);
        if (bdfdName != null) {
          bdfdPerms.add(bdfdName);
        }
      }

      final resultList = (returnAmount >= 0)
          ? bdfdPerms.take(returnAmount).toList()
          : bdfdPerms;
      return resultList.join(separator);
    case 'authorperms':
    case 'memberperms':
      final authorIdVal = _lookupVariableValue('author.id', updates) ?? '';
      final rawMemberPerms =
          _lookupVariableValue('member.permissions', updates) ??
          _lookupVariableValue('permissions.byId.$authorIdVal', updates) ??
          '';
      if (rawMemberPerms.isEmpty) return '';
      final permList = rawMemberPerms
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final mappedBdfd = <String>[];
      for (final p in permList) {
        final bdfdName = _mapToLowercaseToBdfdPerm(p);
        if (bdfdName != null) mappedBdfd.add(bdfdName);
      }
      return mappedBdfd.join(', ');
    case 'getrole':
      final targetUserId = resolvedArgs.isNotEmpty
          ? _stringifyResolvedValue(resolvedArgs[0]).trim()
          : (_lookupVariableValue('author.id', updates) ?? '');
      final rawIndex = resolvedArgs.length > 1
          ? _coerceInt(resolvedArgs[1]) ?? 1
          : 1;
      final rolesStr =
          _lookupVariableValue('member[$targetUserId].roles', updates) ??
          _lookupVariableValue('member.roles', updates) ??
          '';
      if (rolesStr.isEmpty) return '';
      final roleList = rolesStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      final oneBasedIndex = rawIndex - 1;
      if (oneBasedIndex >= 0 && oneBasedIndex < roleList.length) {
        return roleList[oneBasedIndex];
      }
      return '';
    case 'servernames':
      final amount = resolvedArgs.isNotEmpty
          ? _coerceInt(resolvedArgs[0]) ?? -1
          : -1;
      final separator = (rawArgs.length > 1 && rawArgs[1].isNotEmpty)
          ? rawArgs[1]
          : ', ';
      final rawNames = _lookupVariableValue('bot.guildNames', updates) ?? '';
      final encodedNames = _lookupVariableValue('bot.guildNamesJson', updates);
      if (rawNames.isEmpty && (encodedNames == null || encodedNames.isEmpty)) {
        return '';
      }
      List<String>? parsedNames;
      if (encodedNames != null) {
        try {
          final decoded = jsonDecode(encodedNames);
          if (decoded is List) {
            parsedNames = decoded.map((name) => name.toString()).toList();
          }
        } catch (_) {}
      }
      final list =
          parsedNames ??
          rawNames
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
      final resultList = (amount >= 0) ? list.take(amount).toList() : list;
      return resultList.join(separator);
    case 'variablescount':
      final type = resolvedArgs.isEmpty
          ? ''
          : _stringifyResolvedValue(resolvedArgs.first).trim().toLowerCase();
      final scopes = _inspectRuntimeVariables(updates);
      if (type.isEmpty) {
        return scopes.values
            .fold<int>(0, (total, values) => total + values.length)
            .toString();
      }
      final normalized = switch (type) {
        'server' => 'guild',
        'member' || 'guildmember' => 'guildmember',
        _ => type,
      };
      return (scopes[normalized]?.length ?? 0).toString();
    default:
      return null;
  }
}

// Inspect only custom values, deduplicating their context and legacy aliases.
Map<String, Map<String, String>> _inspectRuntimeVariables(
  Map<String, String> variables,
) {
  final explicitTempNames = <String>{};
  try {
    explicitTempNames.addAll(
      (jsonDecode(variables['__variables.tempNames'] ?? '[]') as List).map(
        (name) => name.toString().toLowerCase(),
      ),
    );
  } catch (_) {
    // Legacy contexts may not carry the optional inspection metadata.
  }
  final scopes = <String, Map<String, String>>{};
  final scoped = RegExp(
    r'^(user|guild|server|channel|guildMember|member|message)(?:\[[^\]]+\])?\.bc_(.+)$',
    caseSensitive: false,
  );
  for (final entry in variables.entries) {
    String? scope, name;
    final key = entry.key;
    if (key.toLowerCase().startsWith('temp.')) {
      scope = 'temp';
      name = key.substring(5).toLowerCase();
      if (name.startsWith('bc_')) name = name.substring(3);
      if (!explicitTempNames.contains(name) &&
          (name.startsWith('_') || name == 'debug_last_var')) {
        continue;
      }
    } else if (key.startsWith('global.')) {
      scope = 'global';
      name = key.substring(7);
    } else if (key.startsWith('variables.bc_')) {
      scope = 'global';
      name = key.substring(13);
    } else {
      final match = scoped.firstMatch(key);
      if (match != null) {
        scope = switch (match.group(1)!.toLowerCase()) {
          'server' => 'guild',
          'member' => 'guildmember',
          final value => value,
        };
        name = match.group(2)!;
      }
    }
    if (scope != null && name != null && name.isNotEmpty) {
      scopes.putIfAbsent(scope, () => {})[name] = entry.value;
    }
  }
  return scopes;
}

bool _isEnableDecimals(Map<String, String> updates) {
  return (updates['temp._enabledecimals'] ??
              updates['temp._enableDecimals'] ??
              '')
          .trim()
          .toLowerCase() ==
      'yes';
}

int? _coerceInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(_stringifyResolvedValue(value).trim());
}

num? _coerceNum(dynamic value) {
  if (value is num) {
    return value;
  }
  return num.tryParse(_stringifyResolvedValue(value).trim());
}

bool _coerceBool(dynamic value, {bool fallback = false}) {
  if (value is bool) {
    return value;
  }

  final text = _stringifyResolvedValue(value).trim().toLowerCase();
  if (text == 'true') {
    return true;
  }
  if (text == 'false') {
    return false;
  }
  return fallback;
}

List<dynamic>? _coerceList(dynamic value) {
  final decoded = decodeJsonStringIfNeeded(value);
  if (decoded is List) {
    return List<dynamic>.from(decoded);
  }
  return null;
}

const Set<String> _discordMediaFormats = <String>{
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
};

String _normalizeDiscordMediaFormat(dynamic value, {String fallback = 'webp'}) {
  final normalized = _stringifyResolvedValue(value).trim().toLowerCase();
  if (_discordMediaFormats.contains(normalized)) {
    return normalized;
  }
  return fallback;
}

int _normalizeDiscordMediaSize(dynamic value, {int fallback = 1024}) {
  final parsed = _coerceInt(value) ?? fallback;
  final bounded = parsed.clamp(16, 4096);
  return bounded;
}

String _applyDiscordMediaOptions(
  dynamic rawUrl, {
  dynamic format,
  dynamic size,
}) {
  final source = _stringifyResolvedValue(rawUrl).trim();
  if (source.isEmpty) {
    return '';
  }

  final uri = Uri.tryParse(source);
  if (uri == null) {
    return source;
  }

  final normalizedFormat = _normalizeDiscordMediaFormat(format);
  final normalizedSize = _normalizeDiscordMediaSize(size);
  final segments = List<String>.from(uri.pathSegments);
  if (segments.isNotEmpty) {
    final last = segments.last;
    final dotIndex = last.lastIndexOf('.');
    if (dotIndex > 0 && dotIndex < last.length - 1) {
      segments[segments.length - 1] =
          '${last.substring(0, dotIndex)}.$normalizedFormat';
    }
  }

  final queryParameters = Map<String, String>.from(uri.queryParameters);
  queryParameters['size'] = normalizedSize.toString();

  return uri
      .replace(pathSegments: segments, queryParameters: queryParameters)
      .toString();
}

String _resolveItemPlaceholderValue(dynamic item, String rawPath) {
  final path = rawPath.trim();
  if (path.isEmpty) {
    return '';
  }

  if (path == 'value') {
    return _stringifyResolvedValue(item);
  }

  final composedPath = path.startsWith(r'$')
      ? path
      : path.startsWith('[')
      ? '\$$path'
      : '\$.$path';
  return _stringifyResolvedValue(extractJsonPathValue(item, composedPath));
}

String resolveItemTemplate(
  String template,
  dynamic item,
  Map<String, String> updates,
) {
  final interpolated = template.replaceAllMapped(RegExp(r'\{([^{}]+)\}'), (
    match,
  ) {
    return _resolveItemPlaceholderValue(item, match.group(1)!);
  });
  return resolveTemplatePlaceholders(interpolated, updates);
}

dynamic _applyFunction(
  String rawName,
  List<dynamic> args,
  Map<String, String> updates,
) {
  final name = rawName.trim().toLowerCase();
  switch (name) {
    case 'titlecase':
    case 'totitlecase':
    case 'title':
      if (args.isEmpty) {
        return null;
      }
      return _toTitleCase(_stringifyResolvedValue(args.first));
    case 'lower':
    case 'lowercase':
    case 'tolowercase':
      if (args.isEmpty) {
        return null;
      }
      return _stringifyResolvedValue(args.first).toLowerCase();
    case 'url':
      if (args.length < 2) {
        return null;
      }
      final urlMode = _stringifyResolvedValue(args[0]).trim().toLowerCase();
      final urlText = _stringifyResolvedValue(args[1]);
      try {
        if (urlMode == 'encode') {
          return Uri.encodeQueryComponent(urlText);
        } else if (urlMode == 'decode') {
          return Uri.decodeQueryComponent(urlText);
        }
      } catch (_) {
        return urlText;
      }
      return urlText;
    case 'upper':
    case 'uppercase':
    case 'touppercase':
      if (args.isEmpty) {
        return null;
      }
      return _stringifyResolvedValue(args.first).toUpperCase();
    case 'trim':
      if (args.isEmpty) {
        return null;
      }
      return _stringifyResolvedValue(args.first).trim();
    case 'replace':
      if (args.length < 3) {
        return null;
      }
      final source = _stringifyResolvedValue(args[0]);
      final search = _stringifyResolvedValue(args[1]);
      final replacement = _stringifyResolvedValue(args[2]);
      return source.replaceAll(search, replacement);
    case 'contains':
      if (args.length < 2) {
        return null;
      }
      final haystack = _stringifyResolvedValue(args[0]).toLowerCase();
      final needle = _stringifyResolvedValue(args[1]).toLowerCase();
      return haystack.contains(needle) ? 'true' : '';
    case 'length':
    case 'charcount':
    case 'charcounts':
      if (args.isEmpty) {
        return null;
      }
      final value = decodeJsonStringIfNeeded(args.first);
      if (value is List || value is Map || value is String) {
        return value.length;
      }
      return null;
    case 'linescount':
      if (args.isEmpty) {
        return null;
      }
      return _countLines(_stringifyResolvedValue(args.first));
    case 'numberseparator':
      if (args.isEmpty) {
        return null;
      }
      final value = _coerceNum(args.first);
      if (value == null) {
        return null;
      }
      final separator = args.length >= 2
          ? _stringifyResolvedValue(args[1])
          : ',';
      return _formatNumberWithSeparator(value, separator);
    case 'split':
      if (args.length < 2) {
        return null;
      }
      final source = _stringifyResolvedValue(args[0]);
      final separator = _stringifyResolvedValue(args[1]);
      final parts = separator.isEmpty
          ? source.split('')
          : source.split(separator);
      if (args.length < 3) {
        return parts;
      }
      final index = _coerceInt(args[2]);
      if (index == null || index < 0 || index >= parts.length) {
        return null;
      }
      return parts[index];
    case 'at':
      if (args.length < 2) {
        return null;
      }
      final source = _coerceList(args[0]);
      final index = _coerceInt(args[1]);
      if (source == null || index == null) {
        return null;
      }
      if (index < 0 || index >= source.length) {
        return null;
      }
      return source[index];
    case 'first':
      if (args.isEmpty) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null || source.isEmpty) {
        return null;
      }
      return source.first;
    case 'last':
      if (args.isEmpty) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null || source.isEmpty) {
        return null;
      }
      return source.last;
    case 'slice':
    case 'crop':
    case 'croptext':
      if (args.length < 2) {
        return null;
      }
      final start = _coerceInt(args[1]);
      if (start == null) {
        return null;
      }

      if (name == 'crop' || name == 'croptext') {
        final source = _stringifyResolvedValue(args[0]);
        final maxLength = start;
        if (maxLength < 0) {
          return null;
        }
        final suffix = args.length >= 3
            ? _stringifyResolvedValue(args[2])
            : '...';
        if (source.length <= maxLength) {
          return source;
        }
        if (maxLength == 0) {
          return '';
        }
        return source.substring(0, maxLength) + suffix;
      }

      final end = args.length >= 3 ? _coerceInt(args[2]) : null;

      final sourceList = _coerceList(args[0]);
      if (sourceList != null) {
        final safeStart = start.clamp(0, sourceList.length);
        final safeEnd = (end ?? sourceList.length).clamp(
          safeStart,
          sourceList.length,
        );
        return sourceList.sublist(safeStart, safeEnd);
      }

      final sourceString = _stringifyResolvedValue(args[0]);
      if (sourceString.isEmpty) {
        return '';
      }
      final safeStart = start.clamp(0, sourceString.length);
      final safeEnd = (end ?? sourceString.length).clamp(
        safeStart,
        sourceString.length,
      );
      return sourceString.substring(safeStart, safeEnd);
    case 'join':
      if (args.length < 2) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null) {
        return null;
      }
      final separator = _stringifyResolvedValue(args[1]);
      return source.map(_stringifyResolvedValue).join(separator);
    case 'sum':
      if (args.isEmpty) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null) {
        return null;
      }
      num total = 0;
      for (final item in source) {
        final numeric = _coerceNum(item);
        if (numeric != null) {
          total += numeric;
        }
      }
      return total;
    case 'formateach':
      if (args.length < 3) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null) {
        return null;
      }
      final itemTemplate = _stringifyResolvedValue(args[1]);
      final separator = _stringifyResolvedValue(args[2]);
      return source
          .map((item) => resolveItemTemplate(itemTemplate, item, updates))
          .join(separator);
    case 'embedfields':
      if (args.length < 3) {
        return null;
      }
      final source = _coerceList(args[0]);
      if (source == null) {
        return null;
      }
      final nameTemplate = _stringifyResolvedValue(args[1]);
      final valueTemplate = _stringifyResolvedValue(args[2]);
      final isInline = args.length >= 4 ? _coerceBool(args[3]) : false;
      final fields = <Map<String, dynamic>>[];
      for (final item in source) {
        final fieldName = resolveItemTemplate(nameTemplate, item, updates);
        final fieldValue = resolveItemTemplate(valueTemplate, item, updates);
        if (fieldName.isEmpty || fieldValue.isEmpty) {
          continue;
        }
        fields.add(<String, dynamic>{
          'name': fieldName,
          'value': fieldValue,
          'inline': isInline,
        });
      }
      return fields;
    case 'avatar':
      if (args.isEmpty) {
        return null;
      }
      return _applyDiscordMediaOptions(
        args.first,
        format: args.length >= 2 ? args[1] : 'webp',
        size: args.length >= 3 ? args[2] : 1024,
      );
    case 'banner':
      if (args.isEmpty) {
        return null;
      }
      return _applyDiscordMediaOptions(
        args.first,
        format: args.length >= 2 ? args[1] : 'webp',
        size: args.length >= 3 ? args[2] : 1024,
      );
    case 'coin':
    case 'random':
      // coin() / random() → random bool ("true" or "")
      // Use coin() in conditionals for true/false branching.
      // random() is kept as a legacy alias.
      return _random.nextBool() ? 'true' : '';
    case 'randomchoice':
    case 'randomtext':
      // randomchoice("a", "b", "c") → picks one at random
      if (args.isEmpty) {
        return null;
      }
      return args[_random.nextInt(args.length)];
    case 'randomint':
      // randomint(min, max) → random integer in [min, max]
      if (args.length < 2) {
        return null;
      }
      final min = _coerceInt(args[0]);
      final max = _coerceInt(args[1]);
      if (min == null || max == null || max < min) {
        return null;
      }
      return min + _random.nextInt(max - min + 1);
    default:
      return null;
  }
}

_ResolvedExpression _evaluateSingleExpression(
  String expression,
  Map<String, String> updates,
) {
  final trimmed = expression.trim();
  if (trimmed.isEmpty) {
    return const _ResolvedExpression(found: true, value: '');
  }

  if (_isWrappedStringLiteral(trimmed)) {
    return _ResolvedExpression(
      found: true,
      value: _unescapeStringLiteral(trimmed.substring(1, trimmed.length - 1)),
    );
  }

  if (trimmed == 'null') {
    return const _ResolvedExpression(found: true, value: null);
  }
  if (trimmed == 'true') {
    return const _ResolvedExpression(found: true, value: true);
  }
  if (trimmed == 'false') {
    return const _ResolvedExpression(found: true, value: false);
  }

  final number = num.tryParse(trimmed);
  if (number != null) {
    return _ResolvedExpression(found: true, value: number);
  }

  final functionCall = _parseFunctionCall(trimmed);
  if (functionCall != null) {
    var delimiter = ',';
    final hasTopLevelSemicolon =
        _splitTopLevel(functionCall.inner, ';').length > 1;
    final hasTopLevelComma = _splitTopLevel(functionCall.inner, ',').length > 1;
    if (hasTopLevelSemicolon && !hasTopLevelComma) {
      delimiter = ';';
    }
    final args = _splitTopLevel(functionCall.inner, delimiter);
    final resolvedArgs = <dynamic>[];
    for (final arg in args) {
      final outcome = _evaluateExpression(arg, updates);
      if (!outcome.found) {
        return const _ResolvedExpression(found: false);
      }
      resolvedArgs.add(outcome.value);
    }
    final value = _applyFunction(functionCall.name, resolvedArgs, updates);
    if (value == null && functionCall.name.trim().toLowerCase() != 'length') {
      return const _ResolvedExpression(found: false);
    }
    return _ResolvedExpression(found: true, value: value);
  }

  final bracketFunctionCall = _parseBracketFunctionCall(trimmed);
  if (bracketFunctionCall != null) {
    final rawArgs = _splitTopLevel(bracketFunctionCall.inner, ';');
    final nameLower = bracketFunctionCall.name.trim().toLowerCase();

    // Fast-path for functions that operate directly on raw condition/template expressions
    if (nameLower == 'randomtext' ||
        nameLower == 'calculate' ||
        nameLower == 'checkcondition' ||
        nameLower == 'and' ||
        nameLower == 'or') {
      final value = _applyBdfdBracketFunction(
        bracketFunctionCall.name,
        rawArgs,
        const [],
        updates,
      );
      if (value != null) {
        return _ResolvedExpression(found: true, value: value);
      }
    }

    final resolvedArgs = <dynamic>[];
    for (final arg in rawArgs) {
      final outcome = _evaluateExpression(arg, updates);
      if (outcome.found) {
        resolvedArgs.add(outcome.value);
      } else {
        final resolvedText = resolveTemplatePlaceholders(arg.trim(), updates);
        final numVal = num.tryParse(resolvedText);
        if (numVal != null) {
          resolvedArgs.add(numVal);
        } else {
          resolvedArgs.add(resolvedText);
        }
      }
    }
    final value = _applyBdfdBracketFunction(
      bracketFunctionCall.name,
      rawArgs,
      resolvedArgs,
      updates,
    );
    if (value != null) {
      return _ResolvedExpression(found: true, value: value);
    }
    // Fallback: If argument resolution or function evaluation fails,
    // check if the fully-resolved key exists directly in updates.
    final resolvedFullKey = resolveTemplatePlaceholders(
      trimmed,
      updates,
    ).trim();
    final directVal = _lookupVariableValue(resolvedFullKey, updates);
    if (directVal != null) {
      return _ResolvedExpression(found: true, value: directVal);
    }
  }

  String resolvedKey = trimmed;
  if (trimmed.contains('((')) {
    final nestedResolved = resolveTemplatePlaceholders(trimmed, updates).trim();
    if (nestedResolved.isNotEmpty) {
      resolvedKey = nestedResolved;
      if (trimmed.startsWith('((') && trimmed.endsWith('))')) {
        return _ResolvedExpression(found: true, value: resolvedKey);
      }
    }
  }

  final direct = _lookupVariableValue(resolvedKey, updates);
  if (direct != null) {
    return _ResolvedExpression(found: true, value: direct);
  }

  final computed = _resolveComputedVariableValue(resolvedKey, updates);
  if (computed != null) {
    return _ResolvedExpression(found: true, value: computed);
  }

  final bracketCollection = _resolveBracketCollectionVariableValue(
    resolvedKey,
    updates,
  );
  if (bracketCollection != null) {
    return bracketCollection;
  }

  if (_looksLikeLiteralFallback(trimmed)) {
    return _ResolvedExpression(found: true, value: resolvedKey);
  }

  return const _ResolvedExpression(found: false);
}

_ResolvedExpression _evaluateExpression(
  String expression,
  Map<String, String> updates,
) {
  final candidates = _splitTopLevel(expression, '|');
  if (candidates.length <= 1) {
    return _evaluateSingleExpression(expression, updates);
  }

  for (final candidate in candidates) {
    final outcome = _evaluateSingleExpression(candidate, updates);
    if (outcome.found && _isMeaningfulResolvedValue(outcome.value)) {
      return outcome;
    }
  }

  return const _ResolvedExpression(found: false);
}

dynamic resolveTemplateExpressionValue(
  String expression,
  Map<String, String> updates,
) {
  final outcome = _evaluateExpression(expression, updates);
  if (!outcome.found) {
    return null;
  }
  return outcome.value;
}

String resolveTemplateExpressionToString(
  String expression,
  Map<String, String> updates,
) {
  return _stringifyResolvedValue(
    resolveTemplateExpressionValue(expression, updates),
  );
}

String resolveTemplatePlaceholders(
  String initial,
  Map<String, String> updates,
) {
  if (initial.isEmpty) {
    return initial;
  }

  final buffer = StringBuffer();
  var index = 0;
  while (index < initial.length) {
    var start = initial.indexOf('((', index);
    if (start == -1) {
      buffer.write(initial.substring(index));
      break;
    }

    // A placeholder can be surrounded by literal parentheses, for example
    // `XP (((temp.xp)))`. The delimiter is the innermost opening pair.
    while (start + 2 < initial.length && initial[start + 2] == '(') {
      start++;
    }
    buffer.write(initial.substring(index, start));
    var cursor = start + 2;
    var depth = 0;
    String? quote;
    var escaping = false;
    var foundClosing = false;

    while (cursor < initial.length) {
      final char = initial[cursor];

      if (quote != null) {
        if (escaping) {
          escaping = false;
        } else if (char == r'\') {
          escaping = true;
        } else if (char == quote) {
          quote = null;
        }
        cursor++;
        continue;
      }

      if (char == '"' || char == "'") {
        quote = char;
        cursor++;
        continue;
      }

      if (char == '(') {
        depth++;
        cursor++;
        continue;
      }

      if (char == ')') {
        if (depth > 0) {
          depth--;
          cursor++;
          continue;
        }
        if (cursor + 1 < initial.length && initial[cursor + 1] == ')') {
          final expression = initial.substring(start + 2, cursor);
          buffer.write(resolveTemplateExpressionToString(expression, updates));
          index = cursor + 2;
          foundClosing = true;
          break;
        }
      }

      cursor++;
    }

    if (!foundClosing) {
      buffer.write(initial.substring(start));
      break;
    }
  }

  return buffer.toString();
}

bool _evaluateStringCondition(String expression, Map<String, String> updates) {
  final trimmed = expression.trim();
  if (trimmed.isEmpty) {
    return false;
  }

  // Parse operators
  const symbolOperators = <String, String>{
    '>=': 'greaterOrEqual',
    '<=': 'lessOrEqual',
    '==': 'equals',
    '!=': 'notEquals',
    '>': 'greaterThan',
    '<': 'lessThan',
  };

  for (final entry in symbolOperators.entries) {
    final parts = _splitTopLevel(trimmed, entry.key);
    final splitIndex = parts.length > 1 ? parts.first.length : -1;
    if (splitIndex > 0) {
      final left = resolveTemplatePlaceholders(
        trimmed.substring(0, splitIndex).trim(),
        updates,
      );
      final right = resolveTemplatePlaceholders(
        trimmed.substring(splitIndex + entry.key.length).trim(),
        updates,
      );
      return _evaluateConditionValue(left, entry.value, right);
    }
  }

  const wordOperators = <String, String>{
    ' notcontains ': 'notContains',
    ' contains ': 'contains',
    ' startswith ': 'startsWith',
    ' endswith ': 'endsWith',
  };

  final padded = ' $trimmed ';
  final lowered = padded.toLowerCase();
  for (final entry in wordOperators.entries) {
    final parts = _splitTopLevel(lowered, entry.key);
    if (parts.length > 1) {
      final index = parts.first.length;
      final left = resolveTemplatePlaceholders(
        padded.substring(0, index).trim(),
        updates,
      );
      final right = resolveTemplatePlaceholders(
        padded.substring(index + entry.key.length).trim(),
        updates,
      );
      return _evaluateConditionValue(left, entry.value, right);
    }
  }

  // If no operator, check if it's truthy (not empty and not 'false' and not '0')
  final resolved = resolveTemplatePlaceholders(trimmed, updates).trim();
  return resolved.isNotEmpty &&
      resolved.toLowerCase() != 'false' &&
      resolved != '0';
}

bool _evaluateConditionValue(String left, String operator, String right) {
  switch (operator) {
    case 'equals':
      return left == right;
    case 'notEquals':
      return left != right;
    case 'contains':
      return left.toLowerCase().contains(right.toLowerCase());
    case 'notContains':
      return !left.toLowerCase().contains(right.toLowerCase());
    case 'startsWith':
      return left.toLowerCase().startsWith(right.toLowerCase());
    case 'endsWith':
      return left.toLowerCase().endsWith(right.toLowerCase());
    default:
      final leftNum = num.tryParse(left);
      final rightNum = num.tryParse(right);
      if (leftNum != null && rightNum != null) {
        switch (operator) {
          case 'greaterThan':
            return leftNum > rightNum;
          case 'lessThan':
            return leftNum < rightNum;
          case 'greaterOrEqual':
            return leftNum >= rightNum;
          case 'lessOrEqual':
            return leftNum <= rightNum;
        }
      }
      return false;
  }
}

String? _mapToLowercaseToBdfdPerm(String lowercasePerm) {
  switch (lowercasePerm.trim().toLowerCase()) {
    case 'addreactions':
      return 'ADD_REACTIONS';
    case 'administrator':
      return 'ADMINISTRATOR';
    case 'attachfiles':
      return 'ATTACH_FILES';
    case 'banmembers':
      return 'BAN_MEMBERS';
    case 'changenickname':
      return 'CHANGE_NICKNAME';
    case 'connect':
      return 'CONNECT';
    case 'createinstantinvite':
      return 'CREATE_INSTANT_INVITE';
    case 'createprivatethreads':
      return 'CREATE_PRIVATE_THREADS';
    case 'createpublicthreads':
      return 'CREATE_PUBLIC_THREADS';
    case 'deafenmembers':
      return 'DEAFEN_MEMBERS';
    case 'embedlinks':
      return 'EMBED_LINKS';
    case 'kickmembers':
      return 'KICK_MEMBERS';
    case 'managechannels':
      return 'MANAGE_CHANNELS';
    case 'manageevents':
      return 'MANAGE_EVENTS';
    case 'manageguild':
      return 'MANAGE_GUILD';
    case 'manageguildexpressions':
      return 'MANAGE_GUILD_EXPRESSIONS';
    case 'managemessages':
      return 'MANAGE_MESSAGES';
    case 'managenicknames':
      return 'MANAGE_NICKNAMES';
    case 'manageroles':
      return 'MANAGE_ROLES';
    case 'managethreads':
      return 'MANAGE_THREADS';
    case 'managewebhooks':
      return 'MANAGE_WEBHOOKS';
    case 'mentioneveryone':
      return 'MENTION_EVERYONE';
    case 'moderatemembers':
      return 'MODERATE_MEMBERS';
    case 'movemembers':
      return 'MOVE_MEMBERS';
    case 'mutemembers':
      return 'MUTE_MEMBERS';
    case 'priorityspeaker':
      return 'PRIORITY_SPEAKER';
    case 'readmessagehistory':
      return 'READ_MESSAGE_HISTORY';
    case 'requesttospeak':
      return 'REQUEST_TO_SPEAK';
    case 'sendmessages':
      return 'SEND_MESSAGES';
    case 'sendmessagesinthreads':
      return 'SEND_MESSAGES_IN_THREADS';
    case 'sendttsmessages':
      return 'SEND_TTS_MESSAGES';
    case 'sendvoicemessages':
      return 'SEND_VOICE_MESSAGES';
    case 'speak':
      return 'SPEAK';
    case 'stream':
      return 'STREAM';
    case 'useapplicationcommands':
      return 'USE_APPLICATION_COMMANDS';
    case 'useexternalemojis':
      return 'USE_EXTERNAL_EMOJIS';
    case 'useexternalstickers':
      return 'USE_EXTERNAL_STICKERS';
    case 'usesoundboard':
      return 'USE_SOUNDBOARD';
    case 'usevoiceactivity':
      return 'USE_VAD';
    case 'viewauditlog':
      return 'VIEW_AUDIT_LOG';
    case 'viewchannel':
      return 'VIEW_CHANNEL';
    case 'viewguildinsights':
      return 'VIEW_GUILD_INSIGHTS';
    default:
      return lowercasePerm.toUpperCase();
  }
}

/// Adds always-available bot-level variables to [vars].
/// Usable in any text field across the entire bot config:
/// ((bot.id)), ((bot.uptime)), ((bot.guildCount)), ((bot.ping)),
/// ((getTimestamp)), ((getTimestampMs)), ((day)), ((month)),
/// ((year)), ((hour)), ((minute)), ((second)), ((time)), ((date)).
void injectAlwaysAvailableVariables(
  Map<String, String> vars, {
  required String botId,
  int guildCount = 0,
  int uptimeMs = 0,
  int pingMs = 0,
}) {
  final now = DateTime.now();
  vars['__runtime.liveClock'] = 'true';
  vars.putIfAbsent('bot.id', () => botId);
  vars.putIfAbsent('bot.guildCount', () => '$guildCount');
  vars.putIfAbsent('bot.uptime', () => '$uptimeMs');
  vars.putIfAbsent('bot.ping', () => '$pingMs');
  vars['getTimestamp'] = '${now.millisecondsSinceEpoch ~/ 1000}';
  vars['timestamp'] = '${now.millisecondsSinceEpoch ~/ 1000}';
  vars['getTimestampMs'] = '${now.millisecondsSinceEpoch}';
  vars['timestampMs'] = '${now.millisecondsSinceEpoch}';
  vars['actualTime'] = now.toUtc().toIso8601String();
  vars['day'] = '${now.day}';
  vars['month'] = '${now.month}';
  vars['year'] = '${now.year}';
  vars['hour'] = '${now.hour}';
  vars['minute'] = '${now.minute}';
  vars['second'] = '${now.second}';
  vars['time'] =
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';
  vars['date'] =
      '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
