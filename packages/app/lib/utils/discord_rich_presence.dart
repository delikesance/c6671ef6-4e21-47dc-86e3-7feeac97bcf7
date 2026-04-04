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
  required bool runnerModeEnabled,
  String? preferredBotId,
  String? preferredBotName,
  String? activeRunnerLabel,
  DateTime? startedAt,
}) {
  if (runningBotIds.isEmpty) {
    return DiscordRichPresence(
      details: 'Bot Creator open',
      state: runnerModeEnabled ? 'Runner mode ready' : 'Desktop ready',
    );
  }

  final sortedIds = runningBotIds.toList(growable: false)..sort();
  final controllingBotId =
      preferredBotId != null && runningBotIds.contains(preferredBotId)
          ? preferredBotId
          : sortedIds.first;

  final controllingBotName = _truncate(
    (preferredBotId == controllingBotId ? preferredBotName : null) ??
        botNamesById[controllingBotId] ??
        controllingBotId,
    80,
  );

  final modeState =
      runnerModeEnabled
          ? (activeRunnerLabel?.trim().isNotEmpty ?? false)
              ? 'Runner ${_truncate(activeRunnerLabel!.trim(), 48)}'
              : 'Runner mode'
          : 'Local desktop runtime';

  final botCountSuffix =
      runningBotIds.length > 1 ? ' • ${runningBotIds.length} bots active' : '';

  return DiscordRichPresence(
    details: 'Running $controllingBotName',
    state: '$modeState$botCountSuffix',
    startTime: startedAt,
  );
}

String _truncate(String value, int maxLength) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) {
    return trimmed;
  }
  if (maxLength <= 1) {
    return trimmed.substring(0, maxLength);
  }
  return '${trimmed.substring(0, maxLength - 1)}…';
}
