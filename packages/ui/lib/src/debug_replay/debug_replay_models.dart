// Modèles du rejeu de débogueur : une exécution de commande (`DebugReplayRecord`)
// et ses étapes (`DebugActionFrame`), tels que le runner les écrit et que l'app
// et le Studio les lisent. Aucun accès réseau ni fichier : ils servent aussi bien
// à la mémoire locale de l'app qu'aux réponses du Manager.
library;

class DebugActionFrame {
  final String actionType;
  final int startMs;
  final int durationMs;
  final String? result;
  final int? loopDepth;
  final int? loopIteration;
  final Map<String, String>? variablesBefore;
  final Map<String, String>? variablesAfter;
  final Map<String, dynamic>? nativeMetadata;

  const DebugActionFrame({
    required this.actionType,
    required this.startMs,
    required this.durationMs,
    this.result,
    this.loopDepth,
    this.loopIteration,
    this.variablesBefore,
    this.variablesAfter,
    this.nativeMetadata,
  });

  bool get isNative => nativeMetadata?['backend'] == 'native-v1';
  bool get isError =>
      nativeMetadata?['nativeStatus'] == 'error' ||
      nativeMetadata?['nativeStatus'] == 'timeout' ||
      (result != null && result!.startsWith('Error:'));

  String get displayName => isNative
      ? actionType
      : actionType
            .replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
            .trimLeft()
            .replaceFirstMapped(
              RegExp(r'^.'),
              (m) => m.group(0)!.toUpperCase(),
            );

  factory DebugActionFrame.fromJson(Map<String, dynamic> json) =>
      DebugActionFrame(
        actionType: (json['actionType'] ?? '').toString(),
        startMs: (json['startMs'] as int?) ?? 0,
        durationMs: (json['durationMs'] as int?) ?? 0,
        result: json['result']?.toString(),
        loopDepth: json['loopDepth'] as int?,
        loopIteration: json['loopIteration'] as int?,
        variablesBefore: _castStringMap(json['variablesBefore']),
        variablesAfter: _castStringMap(json['variablesAfter']),
        nativeMetadata: json['backend'] == 'native-v1'
            ? Map.unmodifiable({
                for (final key in [
                  'backend',
                  'nativeKind',
                  'nativeStatus',
                  'line',
                  'column',
                  'scriptDepth',
                  'functionDepth',
                  'branch',
                  'eventsDropped',
                  'valueTruncated',
                ])
                  if (json.containsKey(key)) key: json[key],
              })
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    ...?nativeMetadata,
    'actionType': actionType,
    'startMs': startMs,
    'durationMs': durationMs,
    if (result != null) 'result': result,
    if (loopDepth != null) 'loopDepth': loopDepth,
    if (loopIteration != null) 'loopIteration': loopIteration,
    if (variablesBefore != null) 'variablesBefore': variablesBefore,
    if (variablesAfter != null) 'variablesAfter': variablesAfter,
  };
}

Map<String, String>? _castStringMap(dynamic raw) {
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }
  return null;
}

class DebugReplayRecord {
  final String commandLabel;
  final DateTime triggeredAt;
  final String botId;
  final List<DebugActionFrame> frames;
  final int totalMs;

  const DebugReplayRecord({
    required this.commandLabel,
    required this.triggeredAt,
    required this.botId,
    required this.frames,
    required this.totalMs,
  });

  bool get hasError => frames.any((f) => f.isError);
  int get actionCount => frames.length;

  factory DebugReplayRecord.fromJson(Map<String, dynamic> json) {
    final rawFrames = json['frames'];
    final frames = (rawFrames is List)
        ? rawFrames
              .whereType<Map>()
              .map(
                (f) => DebugActionFrame.fromJson(Map<String, dynamic>.from(f)),
              )
              .toList(growable: false)
        : const <DebugActionFrame>[];
    return DebugReplayRecord(
      commandLabel: (json['commandLabel'] ?? '').toString(),
      triggeredAt:
          DateTime.tryParse(json['triggeredAt']?.toString() ?? '') ??
          DateTime.now(),
      botId: (json['botId'] ?? '').toString(),
      frames: frames,
      totalMs: (json['totalMs'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'commandLabel': commandLabel,
    'triggeredAt': triggeredAt.toUtc().toIso8601String(),
    'botId': botId,
    'frames': frames.map((f) => f.toJson()).toList(growable: false),
    'totalMs': totalMs,
  };
}

/// Réponse de `GET …/debug-replays` : l'état de la capture et les exécutions
/// capturées (la plus récente d'abord).
class DebugReplaySnapshot {
  const DebugReplaySnapshot({required this.capturing, required this.replays});

  final bool capturing;
  final List<DebugReplayRecord> replays;

  factory DebugReplaySnapshot.fromWire(Map<String, dynamic> json) {
    final raw = json['replays'];
    return DebugReplaySnapshot(
      capturing: json['capturing'] == true,
      replays: [
        if (raw is List)
          for (final item in raw.whereType<Map>())
            DebugReplayRecord.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
