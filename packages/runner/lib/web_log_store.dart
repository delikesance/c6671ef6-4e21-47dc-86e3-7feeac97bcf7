import 'dart:io';

import 'package:logging/logging.dart';

class RunnerLogStore {
  RunnerLogStore({this.maxEntries = 500, String? dataDir})
    : _dataDir =
          (dataDir ?? Platform.environment['BOT_CREATOR_DATA_DIR'] ?? './data')
              .trim() {
    _initializeFiles();
  }

  final int maxEntries;
  final String _dataDir;
  final Map<String, List<String>> _buckets = {};
  final List<String> _systemEntries = [];
  final Map<String, File> _files = {};
  File? _systemFile;

  static const int maxLogAgeMs = 7 * 24 * 60 * 60 * 1000;

  static bool _isLogExpired(String line, [DateTime? now]) {
    final current = now ?? DateTime.now().toUtc();
    final match = RegExp(r'^\[([^\]]+)\]').firstMatch(line);
    if (match != null) {
      final tsStr = match.group(1);
      if (tsStr != null) {
        try {
          final ts = DateTime.parse(tsStr).toUtc();
          if (current.difference(ts).inMilliseconds > maxLogAgeMs) {
            return true;
          }
        } catch (_) {}
      }
    }
    return false;
  }

  List<String> tail({String? botId, int limit = 200}) {
    final safeLimit = limit <= 0 ? 1 : limit;
    final entries = botId == null ? _systemEntries : (_buckets[botId] ?? []);
    final now = DateTime.now().toUtc();
    final nonExpired = entries
        .where((line) => !_isLogExpired(line, now))
        .toList();

    if (nonExpired.length <= safeLimit) {
      return List<String>.from(nonExpired);
    }
    return List<String>.from(nonExpired.sublist(nonExpired.length - safeLimit));
  }

  void add(LogRecord record, {String? botId, DateTime? timeOverride}) {
    final timestamp = (timeOverride ?? record.time).toUtc().toIso8601String();
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
      _systemFile ??= File('$_dataDir/logs/runner.log')
        ..parent.createSync(recursive: true);
      _systemFile?.writeAsStringSync(
        '$line\n',
        mode: FileMode.append,
        flush: false,
      );
    } catch (_) {}
  }

  void _initializeFiles() {
    // Files are created lazily in _writeToFile and _writeToSystemFile
  }
}
