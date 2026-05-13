import 'dart:io';

import 'package:logging/logging.dart';

class RunnerLogStore {
  RunnerLogStore({this.maxEntries = 500, String? dataDir})
      : _dataDir = (dataDir ??
                Platform.environment['BOT_CREATOR_DATA_DIR'] ??
                './data')
            .trim() {
    _initializeFiles();
  }

  final int maxEntries;
  final String _dataDir;
  final Map<String, List<String>> _buckets = {};
  final List<String> _systemEntries = [];
  final Map<String, File> _files = {};
  File? _systemFile;

  List<String> tail({String? botId, int limit = 200}) {
    final safeLimit = limit <= 0 ? 1 : limit;
    final entries = botId == null ? _systemEntries : (_buckets[botId] ?? []);

    if (entries.length <= safeLimit) {
      return List<String>.from(entries);
    }
    return List<String>.from(entries.sublist(entries.length - safeLimit));
  }

  void add(LogRecord record, {String? botId}) {
    final timestamp = record.time.toUtc().toIso8601String();
    final errorPart = record.error == null ? '' : ' | ${record.error}';
    final line =
        '[$timestamp] [${record.level.name}] ${record.loggerName}: ${record.message}$errorPart';

    if (botId != null) {
      final bucket = _buckets.putIfAbsent(botId, () => []);
      bucket.add(line);
      if (bucket.length > maxEntries) {
        bucket.removeAt(0);
      }
      _writeToFile(botId, line);
    } else {
      _systemEntries.add(line);
      if (_systemEntries.length > maxEntries) {
        _systemEntries.removeAt(0);
      }
      _writeToSystemFile(line);
    }
  }

  void _writeToFile(String botId, String line) {
    try {
      final file = _files.putIfAbsent(botId, () {
        final f = File('$_dataDir/logs/bot_$botId.log');
        f.parent.createSync(recursive: true);
        return f;
      });
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: false);
    } catch (_) {}
  }

  void _writeToSystemFile(String line) {
    try {
      _systemFile ??= File('$_dataDir/logs/runner.log')..parent.createSync(recursive: true);
      _systemFile?.writeAsStringSync('$line\n', mode: FileMode.append, flush: false);
    } catch (_) {}
  }

  void _initializeFiles() {
    // Files are created lazily in _writeToFile and _writeToSystemFile
  }
}
