/// Statistiques d'exécution des commandes
/// (`GET /gateway/bots/{id}/command-stats?hours=N`).
///
/// Même contrat que `domain.BotCommandStatsSnapshot` du Manager. Les champs de
/// santé (erreurs, latences) sont additifs côté serveur : un champ absent vaut
/// zéro, et une latence à zéro veut dire « inconnue », pas « 0 ms ».
class CommandStats {
  const CommandStats({
    required this.hours,
    required this.totalAllTime,
    required this.commands,
    required this.timeline,
    required this.locales,
    required this.health,
  });

  final int hours;
  final int totalAllTime;
  final List<CommandCount> commands;
  final List<TimelineEntry> timeline;
  final List<LocaleCount> locales;
  final CommandHealth health;

  factory CommandStats.fromJson(Map<String, dynamic> json) {
    List<T> list<T>(Object? raw, T Function(Map<String, dynamic>) read) => [
      if (raw is List)
        for (final item in raw.whereType<Map>())
          read(Map<String, dynamic>.from(item)),
    ];
    final health = json['health'];
    return CommandStats(
      hours: _int(json['hours']),
      totalAllTime: _int(json['totalAllTime']),
      commands: list(json['commands'], CommandCount.fromJson),
      timeline: list(json['timeline'], TimelineEntry.fromJson),
      locales: list(json['locales'], LocaleCount.fromJson),
      health: health is Map
          ? CommandHealth.fromJson(Map<String, dynamic>.from(health))
          : const CommandHealth(),
    );
  }
}

class CommandCount {
  const CommandCount({
    required this.command,
    required this.count,
    this.failed = 0,
    this.errorRatePct = 0,
    this.latencySamples = 0,
    this.avgLatencyMs = 0,
    this.p50LatencyMs = 0,
    this.p95LatencyMs = 0,
  });

  final String command;
  final int count;
  final int failed;
  final double errorRatePct;
  final int latencySamples;
  final int avgLatencyMs;
  final int p50LatencyMs;
  final int p95LatencyMs;

  /// Au moins une latence mesurée : sinon l'interface affiche un tiret.
  bool get hasLatency => latencySamples > 0;

  factory CommandCount.fromJson(Map<String, dynamic> json) => CommandCount(
    command: '${json['command'] ?? ''}',
    count: _int(json['count']),
    failed: _int(json['failed']),
    errorRatePct: _double(json['errorRatePct']),
    latencySamples: _int(json['latencySamples']),
    avgLatencyMs: _int(json['avgLatencyMs']),
    p50LatencyMs: _int(json['p50LatencyMs']),
    p95LatencyMs: _int(json['p95LatencyMs']),
  );
}

/// Un seau d'une heure : [hourBucket] = heures écoulées depuis l'epoch Unix
/// (`floor(epoch_ms / 3 600 000)`), les heures sans exécution sont absentes.
class TimelineEntry {
  const TimelineEntry({required this.hourBucket, required this.count});

  final int hourBucket;
  final int count;

  DateTime get start =>
      DateTime.fromMillisecondsSinceEpoch(hourBucket * 3600000, isUtc: true);

  factory TimelineEntry.fromJson(Map<String, dynamic> json) =>
      TimelineEntry(hourBucket: _int(json['hour']), count: _int(json['count']));
}

class LocaleCount {
  const LocaleCount({required this.locale, required this.count});

  final String locale;
  final int count;

  factory LocaleCount.fromJson(Map<String, dynamic> json) => LocaleCount(
    locale: '${json['locale'] ?? ''}',
    count: _int(json['count']),
  );
}

class CommandHealth {
  const CommandHealth({
    this.total = 0,
    this.failed = 0,
    this.errorRatePct = 0,
    this.p50LatencyMs = 0,
    this.p95LatencyMs = 0,
  });

  final int total;
  final int failed;
  final double errorRatePct;
  final int p50LatencyMs;
  final int p95LatencyMs;

  /// Le P50/P95 global vaut 0 quand aucune latence n'a été remontée.
  bool get hasLatency => p50LatencyMs > 0 || p95LatencyMs > 0;

  factory CommandHealth.fromJson(Map<String, dynamic> json) => CommandHealth(
    total: _int(json['total']),
    failed: _int(json['failed']),
    errorRatePct: _double(json['errorRatePct']),
    p50LatencyMs: _int(json['p50LatencyMs']),
    p95LatencyMs: _int(json['p95LatencyMs']),
  );
}

/// Barres du graphique : la fenêtre découpée en seaux de 1 h (jusqu'à 48 h) ou
/// de 24 h au-delà, les seaux sans exécution comptés à zéro. Le dernier seau
/// est celui de [now]. Les seaux journaliers sont alignés sur la fin de la
/// fenêtre, pas sur minuit, pour que la dernière barre soit « les dernières
/// 24 h ».
List<int> timelineBars(List<TimelineEntry> timeline, int hours, DateTime now) {
  final span = hours <= 48 ? 1 : 24;
  final bars = (hours / span).ceil().clamp(1, 1000);
  final nowBucket = now.toUtc().millisecondsSinceEpoch ~/ 3600000;
  final firstBucket = nowBucket - bars * span + 1;
  final out = List<int>.filled(bars, 0);
  for (final entry in timeline) {
    final offset = entry.hourBucket - firstBucket;
    if (offset < 0) continue;
    final index = offset ~/ span;
    if (index >= 0 && index < bars) out[index] += entry.count;
  }
  return out;
}

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

double _double(Object? v) =>
    v is num ? v.toDouble() : double.tryParse('$v') ?? 0;
