part of 'bot.dart';

class _CpuSample {
  const _CpuSample({required this.jiffies, required this.timestampMs});

  final int jiffies;
  final int timestampMs;
}

class BotRuntimeMetrics {
  const BotRuntimeMetrics({
    this.rssBytes,
    this.estimatedRssBytes,
    this.cpuPercent,
    this.storageBytes,
    this.baselineRssBytes,
    this.baselineCapturedAt,
  });

  final int? rssBytes;
  final int? estimatedRssBytes;
  final double? cpuPercent;
  final int? storageBytes;
  final int? baselineRssBytes;
  final DateTime? baselineCapturedAt;

  BotRuntimeMetrics copyWith({
    int? rssBytes,
    int? estimatedRssBytes,
    double? cpuPercent,
    int? storageBytes,
    int? baselineRssBytes,
    DateTime? baselineCapturedAt,
  }) {
    return BotRuntimeMetrics(
      rssBytes: rssBytes ?? this.rssBytes,
      estimatedRssBytes: estimatedRssBytes ?? this.estimatedRssBytes,
      cpuPercent: cpuPercent ?? this.cpuPercent,
      storageBytes: storageBytes ?? this.storageBytes,
      baselineRssBytes: baselineRssBytes ?? this.baselineRssBytes,
      baselineCapturedAt: baselineCapturedAt ?? this.baselineCapturedAt,
    );
  }
}

String _buildBotBucketKey(RemoteRuntimeSource source, String? botId) {
  final normalizedBotId = botId?.trim() ?? '';
  final bucketBotId = normalizedBotId.isEmpty
      ? _globalBotBucketKey
      : normalizedBotId;
  return '${source.name}::$bucketBotId';
}

String _bucketBotId(String key) {
  final separatorIndex = key.indexOf('::');
  if (separatorIndex == -1 || separatorIndex + 2 >= key.length) {
    return key;
  }
  return key.substring(separatorIndex + 2);
}

String _resolveBotBucketKey(
  String? botId, {
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
}) {
  final trimmed = botId?.trim() ?? '';
  if (trimmed.isNotEmpty) {
    return _buildBotBucketKey(source, trimmed);
  }
  final active = _activeBotLogBotId?.trim() ?? '';
  if (active.isNotEmpty && _activeBotLogSource == source) {
    return _buildBotBucketKey(source, active);
  }
  return _buildBotBucketKey(source, null);
}

_CpuSample? _lastCpuSample;
bool _remoteMetricsBaselineInitialized = false;

int? _readCurrentProcessRssBytes() {
  try {
    return ProcessInfo.currentRss;
  } catch (_) {
    return null;
  }
}

void captureBotBaselineRss({bool force = false}) {
  if (!force && _botBaselineRssBytes != null) {
    return;
  }
  final current = _readCurrentProcessRssBytes();
  if (current == null) {
    return;
  }
  _botBaselineRssBytes = current;
  _botBaselineCapturedAt = DateTime.now();
  if (!_botEstimatedRssController.isClosed) {
    _botEstimatedRssController.add(_botEstimatedRssBytes);
  }
}

void clearBotBaselineRss() {
  _botBaselineRssBytes = null;
  _botBaselineCapturedAt = null;
  _botEstimatedRssBytes = null;
  if (!_botEstimatedRssController.isClosed) {
    _botEstimatedRssController.add(null);
  }
}

void setBotRuntimeActive(bool active) {
  _botRuntimeActive = active;
  if (active) {
    return;
  }

  _remoteMetricsBaselineInitialized = false;
  clearBotBaselineRss();
  _lastCpuSample = null;
  _updateBotMetrics(
    rssBytes: null,
    cpuPercent: null,
    storageBytes: null,
    overwriteNulls: true,
  );
}

int? _readCurrentProcessCpuJiffies() {
  if (!(Platform.isAndroid || Platform.isLinux)) {
    return null;
  }

  try {
    final stat = File('/proc/self/stat').readAsStringSync();
    final lastParen = stat.lastIndexOf(')');
    if (lastParen == -1 || lastParen + 2 >= stat.length) {
      return null;
    }
    final afterState = stat.substring(lastParen + 2).trim();
    final fields = afterState.split(RegExp(r'\s+'));
    if (fields.length <= 11) {
      return null;
    }

    final utime = int.tryParse(fields[10]);
    final stime = int.tryParse(fields[11]);
    if (utime == null || stime == null) {
      return null;
    }
    return utime + stime;
  } catch (_) {
    return null;
  }
}

double? _readCurrentProcessCpuPercent() {
  final jiffies = _readCurrentProcessCpuJiffies();
  if (jiffies == null) {
    return null;
  }

  final nowMs = DateTime.now().millisecondsSinceEpoch;
  final prev = _lastCpuSample;
  _lastCpuSample = _CpuSample(jiffies: jiffies, timestampMs: nowMs);

  if (prev == null) {
    return 0.0;
  }

  final deltaJiffies = jiffies - prev.jiffies;
  final deltaMs = nowMs - prev.timestampMs;
  if (deltaJiffies <= 0 || deltaMs <= 0) {
    return 0;
  }

  const ticksPerSecond = 100.0;
  final elapsedSeconds = deltaMs / 1000.0;
  final cpuSeconds = deltaJiffies / ticksPerSecond;
  final cores = Platform.numberOfProcessors.clamp(1, 64);
  final percent = (cpuSeconds / elapsedSeconds) * 100.0 / cores;
  if (percent.isNaN || percent.isInfinite) {
    return null;
  }
  return percent.clamp(0, 100.0);
}

Future<int?> _readBotStorageBytes({String? botId}) async {
  try {
    final docsDir = await storage_utils.getAppStorageDirectory();
    final basePath = docsDir.path;
    final appsDir = Directory('$basePath/apps');
    if (!await appsDir.exists()) {
      return 0;
    }

    Future<int> dirSize(Directory dir) async {
      var total = 0;
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is File) {
          try {
            total += await entity.length();
          } catch (_) {}
        }
      }
      return total;
    }

    if (botId == null || botId.isEmpty) {
      return await dirSize(appsDir);
    }

    var total = 0;
    final botJson = File('$basePath/apps/$botId.json');
    if (await botJson.exists()) {
      total += await botJson.length();
    }
    final botDir = Directory('$basePath/apps/$botId');
    if (await botDir.exists()) {
      total += await dirSize(botDir);
    }
    return total;
  } catch (_) {
    return null;
  }
}

void _updateBotMetrics({
  int? rssBytes,
  double? cpuPercent,
  int? storageBytes,
  int? estimatedRssBytes,
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
  bool overwriteNulls = false,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  final previous = _botMetricsByBot[key] ?? const BotRuntimeMetrics();

  final nextRss = overwriteNulls || rssBytes != null
      ? rssBytes
      : previous.rssBytes;
  final nextCpu = overwriteNulls || cpuPercent != null
      ? cpuPercent
      : previous.cpuPercent;
  final nextStorage = overwriteNulls || storageBytes != null
      ? storageBytes
      : previous.storageBytes;

  int? nextEstimated;
  if (estimatedRssBytes != null) {
    nextEstimated = estimatedRssBytes;
  } else if (nextRss != null && _botBaselineRssBytes != null) {
    nextEstimated = (nextRss - _botBaselineRssBytes!).clamp(0, nextRss);
  } else if (overwriteNulls || nextRss == null) {
    nextEstimated = null;
  } else {
    nextEstimated = previous.estimatedRssBytes;
  }

  final next = BotRuntimeMetrics(
    rssBytes: nextRss,
    estimatedRssBytes: nextEstimated,
    cpuPercent: nextCpu,
    storageBytes: nextStorage,
    baselineRssBytes: _botBaselineRssBytes,
    baselineCapturedAt: _botBaselineCapturedAt,
  );
  _botMetricsByBot[key] = next;

  if (!_botMetricsByBotController.isClosed) {
    _botMetricsByBotController.add(
      Map<String, BotRuntimeMetrics>.unmodifiable(_botMetricsByBot),
    );
  }

  final selectedKey = _resolveBotBucketKey(
    _activeBotLogBotId,
    source: _activeBotLogSource,
  );
  final selected =
      _botMetricsByBot[selectedKey] ??
      _botMetricsByBot[key] ??
      const BotRuntimeMetrics();

  _botProcessRssBytes = selected.rssBytes;
  _botEstimatedRssBytes = selected.estimatedRssBytes;
  _botProcessCpuPercent = selected.cpuPercent;
  _botProcessStorageBytes = selected.storageBytes;

  if (!_botProcessRssController.isClosed) {
    _botProcessRssController.add(_botProcessRssBytes);
  }
  if (!_botEstimatedRssController.isClosed) {
    _botEstimatedRssController.add(_botEstimatedRssBytes);
  }
  if (!_botProcessCpuController.isClosed) {
    _botProcessCpuController.add(_botProcessCpuPercent);
  }
  if (!_botProcessStorageController.isClosed) {
    _botProcessStorageController.add(_botProcessStorageBytes);
  }
}

Future<void> _refreshBotMetrics({
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
}) async {
  final rss = _readCurrentProcessRssBytes();
  final cpu = _readCurrentProcessCpuPercent();
  final storage = await _readBotStorageBytes(botId: botId);
  _updateBotMetrics(
    rssBytes: rss,
    cpuPercent: cpu,
    storageBytes: storage,
    botId: botId,
    source: source,
  );
}

Future<void> refreshBotStatsNow({
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
  bool captureBaseline = false,
}) async {
  if (!isBotRuntimeActive) {
    _updateBotMetrics(
      rssBytes: null,
      cpuPercent: null,
      storageBytes: null,
      botId: botId,
      source: source,
      overwriteNulls: true,
    );
    return;
  }

  if (captureBaseline) {
    captureBotBaselineRss(force: true);
  }
  await _refreshBotMetrics(botId: botId, source: source);
}

void updateBotRuntimeMetricsFromRemote({
  required bool running,
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.runner,
  int? rssBytes,
  int? estimatedRssBytes,
  double? cpuPercent,
  int? storageBytes,
}) {
  if (!running) {
    setBotRuntimeActive(false);
    return;
  }

  if (!_remoteMetricsBaselineInitialized && rssBytes != null) {
    _botBaselineRssBytes = rssBytes;
    _botBaselineCapturedAt = DateTime.now();
    _remoteMetricsBaselineInitialized = true;
  }

  setBotRuntimeActive(true);
  _updateBotMetrics(
    rssBytes: rssBytes,
    estimatedRssBytes: estimatedRssBytes,
    cpuPercent: cpuPercent,
    storageBytes: storageBytes,
    botId: botId,
    source: source,
    overwriteNulls: true,
  );
}

Stream<int?> getBotProcessRssStream() => _botProcessRssController.stream;

int? getBotProcessRssBytes() => _botProcessRssBytes;

Stream<int?> getBotEstimatedRssStream() => _botEstimatedRssController.stream;

int? getBotEstimatedRssBytes() => _botEstimatedRssBytes;

int? getBotBaselineRssBytes() => _botBaselineRssBytes;

DateTime? getBotBaselineCapturedAt() => _botBaselineCapturedAt;

Stream<double?> getBotProcessCpuStream() => _botProcessCpuController.stream;

double? getBotProcessCpuPercent() => _botProcessCpuPercent;

Stream<int?> getBotProcessStorageStream() =>
    _botProcessStorageController.stream;

int? getBotProcessStorageBytes() => _botProcessStorageBytes;

void _publishBotLogs() {
  final selectedKey = _resolveBotBucketKey(
    _activeBotLogBotId,
    source: _activeBotLogSource,
  );
  _botLogs = List<String>.from(
    _botLogsByBot[selectedKey] ?? const <String>[],
    growable: false,
  );

  if (!_botLogsController.isClosed) {
    _botLogsController.add(List<String>.unmodifiable(_botLogs));
  }
  if (!_botLogsByBotController.isClosed) {
    _botLogsByBotController.add(
      Map<String, List<String>>.unmodifiable(_botLogsByBot),
    );
  }
}

Stream<List<String>> getBotLogsStream() => _botLogsController.stream;

List<String> getBotLogsSnapshot() => List<String>.unmodifiable(_botLogs);

/// Source de runtime qui produit actuellement les logs de chaque bot.
///
/// Un bot n'a qu'une seule source « vivante » à la fois (local, runner ou
/// manager) : le panneau console intégré doit donc lire le même bucket que
/// [BotLogsPage] au lieu de supposer que tout arrive en local (bug « panneau
/// vide alors que la page affiche les logs »).
final Map<String, RemoteRuntimeSource> _botLogSourceByBot =
    <String, RemoteRuntimeSource>{};

void _rememberBotLogSource(String botId, RemoteRuntimeSource source) {
  final trimmed = botId.trim();
  if (trimmed.isEmpty) {
    return;
  }
  _botLogSourceByBot[trimmed] = source;
}

/// Mémorise (et publie) la source de logs réellement utilisée pour [botId].
///
/// Appelée par `BotLogsPage` après résolution du runtime, pour que tout autre
/// lecteur (panneau console de la home) affiche les mêmes lignes.
void setBotLogsSourceForBot(String? botId, RemoteRuntimeSource source) {
  final trimmed = botId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return;
  }
  _rememberBotLogSource(trimmed, source);
  if (!_botLogsByBotController.isClosed) {
    _botLogsByBotController.add(
      Map<String, List<String>>.unmodifiable(_botLogsByBot),
    );
  }
}

/// Source de logs à utiliser pour [botId] quand l'appelant n'en fournit pas.
///
/// Ordre de résolution : source mémorisée (session de logs en cours ou
/// dernière ligne reçue), puis source de la session active si c'est ce bot,
/// puis local.
RemoteRuntimeSource resolveBotLogsSourceForBot(String? botId) {
  final trimmed = botId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return _activeBotLogSource;
  }
  final remembered = _botLogSourceByBot[trimmed];
  if (remembered != null) {
    return remembered;
  }
  if (_activeBotLogBotId?.trim() == trimmed) {
    return _activeBotLogSource;
  }
  return RemoteRuntimeSource.local;
}

/// Bucket exact que `BotLogsPage` affiche pour [botId] : celui de la source de
/// runtime résolue pour ce bot. Aucune heuristique ici, le panneau intégré et
/// la page doivent lire le même bucket.
List<String> _visibleBotLogsForBot(String botId) {
  final key = _buildBotBucketKey(resolveBotLogsSourceForBot(botId), botId);
  return _botLogsByBot[key] ?? const <String>[];
}

Stream<List<String>> getBotLogsStreamForBot(String? botId) {
  // Le flux ré-évalue le snapshot à chaque publication : si la source de logs
  // du bot change (démarrage sur un runner, sync manager…), le panneau suit
  // sans reconstruire le widget.
  return _botLogsByBotController.stream.map(
    (_) => getBotLogsSnapshotForBot(botId),
  );
}

Stream<List<String>> getBotLogsStreamForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botLogsByBotController.stream.map(
    (logsByBot) =>
        List<String>.unmodifiable(logsByBot[key] ?? const <String>[]),
  );
}

/// Snapshot des logs visibles pour [botId], en tenant compte de la source de
/// runtime qui alimente réellement ce bot (voir [_visibleBotLogsForBot]).
List<String> getBotLogsSnapshotForBot(String? botId) {
  final trimmed = botId?.trim() ?? '';
  if (trimmed.isEmpty) {
    return getBotLogsSnapshotForBotFromSource(
      botId,
      source: resolveBotLogsSourceForBot(botId),
    );
  }
  return List<String>.unmodifiable(_visibleBotLogsForBot(trimmed));
}

List<String> getBotLogsSnapshotForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  final logs = _botLogsByBot[key] ?? const <String>[];
  return List<String>.unmodifiable(logs);
}

Set<String> getKnownBotLogIds() {
  final ids = <String>{...mobileRunningBotIds};
  final bucketKeys = <String>{..._botLogsByBot.keys, ..._botMetricsByBot.keys};
  for (final key in bucketKeys) {
    final botId = _bucketBotId(key);
    if (botId != _globalBotBucketKey) {
      ids.add(botId);
    }
  }
  return ids;
}

Future<Map<String, String>> getKnownBotNamesById() async {
  final knownIds = getKnownBotLogIds();
  if (knownIds.isEmpty) {
    return const <String, String>{};
  }

  final namesById = <String, String>{};
  try {
    final apps = await appManager.getAllApps();
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp);
      final botId = (app['id'] ?? '').toString().trim();
      if (botId.isEmpty || !knownIds.contains(botId)) {
        continue;
      }

      final botName = (app['name'] ?? '').toString().trim();
      if (botName.isNotEmpty) {
        namesById[botId] = botName;
      }
    }
  } catch (_) {}

  for (final botId in knownIds) {
    namesById.putIfAbsent(botId, () => botId);
  }

  return Map<String, String>.unmodifiable(namesById);
}

void startBotLogSession({
  required String botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
}) {
  _activeBotLogBotId = botId;
  _activeBotLogSource = source;
  _rememberBotLogSource(botId, source);
  final key = _buildBotBucketKey(source, botId);
  _botLogsByBot[key] = <String>[];
  _remoteMetricsBaselineInitialized = false;
  captureBotBaselineRss(force: true);
  _lastCpuSample = null;
  _updateBotMetrics(
    rssBytes: null,
    cpuPercent: null,
    storageBytes: null,
    botId: botId,
    source: source,
    overwriteNulls: true,
  );
  appendBotLog('Log session started', botId: botId, source: source);
}

void endBotLogSession({
  required String botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
  bool clearLogs = true,
}) {
  final key = botId.trim();
  if (key.isEmpty) {
    return;
  }
  final bucketKey = _buildBotBucketKey(source, key);

  if (clearLogs) {
    _botLogsByBot.remove(bucketKey);
  }
  _botMetricsByBot.remove(bucketKey);

  if (_activeBotLogBotId == key && _activeBotLogSource == source) {
    _activeBotLogBotId = null;
    _activeBotLogSource = RemoteRuntimeSource.local;
  }

  _publishBotLogs();

  if (!_botMetricsByBotController.isClosed) {
    _botMetricsByBotController.add(
      Map<String, BotRuntimeMetrics>.unmodifiable(_botMetricsByBot),
    );
  }

  final selectedKey = _resolveBotBucketKey(
    _activeBotLogBotId,
    source: _activeBotLogSource,
  );
  final selected = _botMetricsByBot[selectedKey];
  _botProcessRssBytes = selected?.rssBytes;
  _botEstimatedRssBytes = selected?.estimatedRssBytes;
  _botProcessCpuPercent = selected?.cpuPercent;
  _botProcessStorageBytes = selected?.storageBytes;

  if (!_botProcessRssController.isClosed) {
    _botProcessRssController.add(_botProcessRssBytes);
  }
  if (!_botEstimatedRssController.isClosed) {
    _botEstimatedRssController.add(_botEstimatedRssBytes);
  }
  if (!_botProcessCpuController.isClosed) {
    _botProcessCpuController.add(_botProcessCpuPercent);
  }
  if (!_botProcessStorageController.isClosed) {
    _botProcessStorageController.add(_botProcessStorageBytes);
  }
}

bool _startsWithTimestamp(String message) {
  final trimmed = message.trimLeft();
  if (trimmed.isEmpty) {
    return false;
  }

  final hhmmssPattern = RegExp(
    r'^\[(?:[01]?\d|2[0-3]):[0-5]\d:[0-5]\d(?:\.\d+)?\]',
  );
  if (hhmmssPattern.hasMatch(trimmed)) {
    return true;
  }

  final isoPattern = RegExp(
    r'^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\]',
  );
  return isoPattern.hasMatch(trimmed);
}

void appendBotLog(
  String message, {
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  _rememberBotLogSource(botId ?? '', source);
  final logs = _botLogsByBot.putIfAbsent(key, () => <String>[]);
  final line = _startsWithTimestamp(message)
      ? message
      : '[${_timestampNow()}] $message';
  logs.add(line);
  if (kDebugMode && source != RemoteRuntimeSource.local) {
    developer.log('New remote log appended: $line', name: 'BotLogs');
  }
  if (logs.length > _maxBotLogLines) {
    _botLogsByBot[key] = logs.sublist(logs.length - _maxBotLogLines);
  }
  _publishBotLogs();
}

Stream<int?> getBotProcessRssStreamForBot(String? botId) {
  return getBotProcessRssStreamForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

Stream<int?> getBotProcessRssStreamForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBotController.stream.map(
    (metricsByBot) => metricsByBot[key]?.rssBytes,
  );
}

int? getBotProcessRssBytesForBot(String? botId) {
  return getBotProcessRssBytesForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

int? getBotProcessRssBytesForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBot[key]?.rssBytes;
}

Stream<int?> getBotEstimatedRssStreamForBot(String? botId) {
  return getBotEstimatedRssStreamForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

Stream<int?> getBotEstimatedRssStreamForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBotController.stream.map(
    (metricsByBot) => metricsByBot[key]?.estimatedRssBytes,
  );
}

int? getBotEstimatedRssBytesForBot(String? botId) {
  return getBotEstimatedRssBytesForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

int? getBotEstimatedRssBytesForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBot[key]?.estimatedRssBytes;
}

Stream<double?> getBotProcessCpuStreamForBot(String? botId) {
  return getBotProcessCpuStreamForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

Stream<double?> getBotProcessCpuStreamForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBotController.stream.map(
    (metricsByBot) => metricsByBot[key]?.cpuPercent,
  );
}

double? getBotProcessCpuPercentForBot(String? botId) {
  return getBotProcessCpuPercentForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

double? getBotProcessCpuPercentForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBot[key]?.cpuPercent;
}

Stream<int?> getBotProcessStorageStreamForBot(String? botId) {
  return getBotProcessStorageStreamForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

Stream<int?> getBotProcessStorageStreamForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBotController.stream.map(
    (metricsByBot) => metricsByBot[key]?.storageBytes,
  );
}

int? getBotProcessStorageBytesForBot(String? botId) {
  return getBotProcessStorageBytesForBotFromSource(
    botId,
    source: RemoteRuntimeSource.local,
  );
}

int? getBotProcessStorageBytesForBotFromSource(
  String? botId, {
  required RemoteRuntimeSource source,
}) {
  final key = _resolveBotBucketKey(botId, source: source);
  return _botMetricsByBot[key]?.storageBytes;
}

void appendBotDebugLog(
  String message, {
  String? botId,
  RemoteRuntimeSource source = RemoteRuntimeSource.local,
}) {
  developer.log(message, name: 'BotDebug');
  if (!_debugBotLogsEnabled) {
    return;
  }
  // Doublé dans la console de `flutter run` : le journal interne est invisible là où l'on
  // cherche naturellement une trace quand un geste ne fait pas ce qu'on attend. C'est
  // exactement ce qui a manqué pour diagnostiquer un choix de démarrage non honoré.
  debugPrint('[bot-debug] $message');
  appendBotLog('DEBUG: $message', botId: botId, source: source);
}

String _formatNyxxLogRecord(LogRecord record) {
  final buffer = StringBuffer(
    '[${record.level.name}] [${record.loggerName}] ${record.message}',
  );
  if (record.error != null) {
    buffer.write(' | error=${record.error}');
  }
  return buffer.toString();
}

void consumeForegroundTaskDataForBotLogs(Object data) {
  if (data is! Map) {
    return;
  }
  final map = Map<String, dynamic>.from(data.cast<dynamic, dynamic>());
  if (map['type'] == 'bot_lifecycle') {
    final state = map['state']?.toString();
    final botId = map['botId']?.toString();
    if (state == 'started') {
      if (botId != null && botId.isNotEmpty) {
        addMobileRunningBotId(botId);
      }
      setBotRuntimeActive(true);
      return;
    }
    if (state == 'stopped') {
      if (botId != null && botId.isNotEmpty) {
        removeMobileRunningBotId(botId);
        endBotLogSession(botId: botId);
      } else {
        setMobileRunningBotId(null);
      }
      setBotRuntimeActive(
        isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
      );
    }
    return;
  }

  if (map['type'] == 'bot_metrics') {
    final botId = map['botId']?.toString();
    final rssBytes = map['rssBytes'];
    final rssAsInt = (rssBytes is int)
        ? rssBytes
        : int.tryParse((rssBytes ?? '').toString());
    final cpuRaw = map['cpuPercent'];
    final cpuAsDouble = (cpuRaw is num)
        ? cpuRaw.toDouble()
        : double.tryParse('$cpuRaw');
    final storageRaw = map['storageBytes'];
    final storageAsInt = (storageRaw is int)
        ? storageRaw
        : int.tryParse((storageRaw ?? '').toString());

    final guildCountRaw = map['guildCount'];
    if (guildCountRaw != null && botId != null && botId.isNotEmpty) {
      final guildCountAsInt = (guildCountRaw is int)
          ? guildCountRaw
          : int.tryParse(guildCountRaw.toString());
      if (guildCountAsInt != null) {
        appManager.updateGuildCount(botId, guildCountAsInt);
      }
    }

    _updateBotMetrics(
      rssBytes: rssAsInt,
      cpuPercent: cpuAsDouble,
      storageBytes: storageAsInt,
      botId: botId,
    );
    return;
  }

  if (map['type'] == 'debug_replay') {
    try {
      final record = DebugReplayRecord.fromJson(map);
      appendDebugReplay(record);
    } catch (_) {}
    return;
  }

  if (map['type'] != 'bot_log') {
    return;
  }
  final botId = map['botId']?.toString();
  final message = map['message']?.toString();
  if (message == null || message.isEmpty) {
    return;
  }
  appendBotLog(message, botId: botId);
}
