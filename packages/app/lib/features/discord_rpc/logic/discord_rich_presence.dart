import 'package:bot_creator/core/network/runner_client.dart';

class DiscordRichPresence {
  const DiscordRichPresence({
    required this.details,
    this.state,
    this.startTime,
  });

  final String details;
  final String? state;
  final DateTime? startTime;

  Map<String, dynamic> toActivityJson() {
    return <String, dynamic>{
      'type': 0,
      'details': _truncate(details, 128),
      if ((state ?? '').trim().isNotEmpty)
        'state': _truncate(state!.trim(), 128),
      if (startTime != null)
        'timestamps': <String, dynamic>{
          'start': startTime!.toUtc().millisecondsSinceEpoch ~/ 1000,
        },
    };
  }
}

DiscordRichPresence buildBotCreatorRichPresence({
  required Set<String> runningBotIds,
  required Map<String, String> botNamesById,
  required RemoteRuntimeSource runtimeSource,
  String? preferredBotId,
  String? preferredBotName,
  String? activeSourceLabel,
  DateTime? startedAt,
}) {
  if (runningBotIds.isEmpty) {
    return DiscordRichPresence(
      details: 'Bot Creator open',
      state: switch (runtimeSource) {
        RemoteRuntimeSource.manager => 'Bot Creator servers ready',
        RemoteRuntimeSource.runner => 'Server mode ready',
        RemoteRuntimeSource.local => 'Desktop ready',
      },
    );
  }

  final sortedIds = runningBotIds.toList(growable: false)..sort();
  final controllingBotId =
      preferredBotId != null && runningBotIds.contains(preferredBotId)
          ? preferredBotId
          : sortedIds.first;

  final controllingBotName = _truncate(
    _sanitizeUtf16(
      (preferredBotId == controllingBotId ? preferredBotName : null) ??
          botNamesById[controllingBotId] ??
          controllingBotId,
    ),
    80,
  );

  final modeState = switch (runtimeSource) {
    RemoteRuntimeSource.manager =>
      (activeSourceLabel?.trim().isNotEmpty ?? false)
          ? 'Bot Creator ${_truncate(_sanitizeUtf16(activeSourceLabel!.trim()), 48)}'
          : 'Bot Creator servers',
    RemoteRuntimeSource.runner =>
      (activeSourceLabel?.trim().isNotEmpty ?? false)
          ? 'Server ${_truncate(_sanitizeUtf16(activeSourceLabel!.trim()), 48)}'
          : 'Server mode',
    RemoteRuntimeSource.local => 'Local desktop runtime',
  };

  final botCountSuffix =
      runningBotIds.length > 1 ? ' \u2022 ${runningBotIds.length} bots active' : '';

  return DiscordRichPresence(
    details: 'Running $controllingBotName',
    state: '$modeState$botCountSuffix',
    startTime: startedAt,
  );
}

/// Replaces unpaired surrogates with U+FFFD to prevent
/// Flutter text rendering crashes ("string is not well-formed UTF-16").
String _sanitizeUtf16(String input) {
  final buffer = StringBuffer();
  for (var i = 0; i < input.length; i++) {
    final codeUnit = input.codeUnitAt(i);
    if (_isHighSurrogate(codeUnit)) {
      if (i + 1 < input.length && _isLowSurrogate(input.codeUnitAt(i + 1))) {
        buffer.writeCharCode(codeUnit);
        buffer.writeCharCode(input.codeUnitAt(i + 1));
        i++; // skip the low surrogate
      } else {
        buffer.write('\uFFFD'); // replacement character
      }
    } else if (_isLowSurrogate(codeUnit)) {
      buffer.write('\uFFFD'); // unpaired low surrogate
    } else {
      buffer.writeCharCode(codeUnit);
    }
  }
  return buffer.toString();
}

String _truncate(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  if (maxLength <= 1) {
    return trimmed.substring(0, maxLength);
  }
  // Safe truncation: avoid splitting surrogate pairs (emoji, etc.)
  // which would produce invalid UTF-16 and crash Flutter's text renderer.
  var end = maxLength - 1;
  // If we landed on a low surrogate, also skip the preceding high surrogate.
  if (end > 0 && _isLowSurrogate(trimmed.codeUnitAt(end))) {
    end--;
  }
  // Skip any trailing high surrogate (its low surrogate is beyond our range).
  if (end > 0 && _isHighSurrogate(trimmed.codeUnitAt(end))) {
    end--;
  }
  if (end == 0) {
    return '\u2026';
  }
  return '${trimmed.substring(0, end)}\u2026';
}

bool _isHighSurrogate(int codeUnit) {
  return codeUnit >= 0xD800 && codeUnit <= 0xDBFF;
}

bool _isLowSurrogate(int codeUnit) {
  return codeUnit >= 0xDC00 && codeUnit <= 0xDFFF;
}
