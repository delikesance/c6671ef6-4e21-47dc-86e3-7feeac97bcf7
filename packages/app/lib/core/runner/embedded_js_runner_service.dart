import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_runner_downloader.dart';
import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EmbeddedJsRunnerService {
  EmbeddedJsRunnerService._();

  static final EmbeddedJsRunnerService instance = EmbeddedJsRunnerService._();

  Process? _process;
  String? _url;
  String? _apiToken;
  int? _port;
  final StringBuffer _processOutput = StringBuffer();

  bool get isRunning => _process != null;

  Future<RunnerConnectionConfig?> ensureConfig() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        await _ensureStarted();
        if (_url != null && _apiToken != null) {
          return RunnerConnectionConfig(
            id: RunnerSettings.embeddedRunnerId,
            url: _url!,
            apiToken: _apiToken,
            name: 'Embedded JS Runner',
            kind: RunnerKind.javascript,
            useEmbedded: true,
          );
        }
      } catch (error, stackTrace) {
        debugPrint('[EmbeddedJsRunner] Failed to start: $error');
        debugPrint('$stackTrace');
      }
    }
    return null;
  }

  Future<void> stop() async {
    final process = _process;
    _process = null;
    _url = null;
    _apiToken = null;
    _port = null;
    if (process != null) {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // Best effort: the OS may take a moment to release the file lock.
      }
    }
  }

  Future<void> _ensureStarted() async {
    if (_process != null) {
      return;
    }

    _processOutput.clear();

    await stop();

    final binaryPath = await _resolveBinaryPath();
    if (binaryPath == null) {
      throw StateError('Embedded JS runner binary is not available on this platform.');
    }

    _port = 18080 + (DateTime.now().millisecond % 1000);
    _apiToken = 'embedded-${DateTime.now().millisecondsSinceEpoch}';
    _url = 'http://127.0.0.1:$_port';

    final dataDir = await _dataDir();
    final logFile = p.join(dataDir, 'runner.log');

    _process = await Process.start(
      binaryPath,
      const [],
      workingDirectory: dataDir,
      environment: {
        'BOT_CREATOR_WEB_HOST': '127.0.0.1',
        'BOT_CREATOR_WEB_PORT': _port.toString(),
        'BOT_CREATOR_API_TOKEN': _apiToken!,
        'BOT_CREATOR_DATA_DIR': dataDir,
        'BOT_CREATOR_RUNNER_LOG_FILE': logFile,
      },
    );

    _process!.stdout.transform(const SystemEncoding().decoder).listen((chunk) {
      if (chunk.trim().isNotEmpty) {
        _processOutput.writeln(chunk.trim());
        debugPrint('[EmbeddedJsRunner] $chunk');
      }
    });
    _process!.stderr.transform(const SystemEncoding().decoder).listen((chunk) {
      if (chunk.trim().isNotEmpty) {
        _processOutput.writeln(chunk.trim());
        debugPrint('[EmbeddedJsRunner][stderr] $chunk');
      }
    });

    await _waitUntilHealthy();
  }

  Future<bool> _hasProcessExited() async {
    final process = _process;
    if (process == null) {
      return true;
    }
    try {
      await process.exitCode.timeout(const Duration(milliseconds: 0));
      return true;
    } on TimeoutException {
      return false;
    }
  }

  String _processOutputSummary() {
    final text = _processOutput.toString().trim();
    if (text.isEmpty) {
      return '';
    }
    if (text.length <= 500) {
      return text;
    }
    return '...${text.substring(text.length - 500)}';
  }

  Future<void> _waitUntilHealthy() async {
    final url = _url;
    if (url == null) {
      return;
    }

    final client = HttpClient();
    try {
      for (var attempt = 0; attempt < 40; attempt++) {
        if (await _hasProcessExited()) {
          final summary = _processOutputSummary();
          throw StateError(
            summary.isEmpty
                ? 'Embedded JS runner exited before becoming healthy.'
                : 'Embedded JS runner exited before becoming healthy: $summary',
          );
        }
        try {
          final request = await client.getUrl(Uri.parse('$url/health'));
          final response = await request.close().timeout(
            const Duration(milliseconds: 500),
          );
          if (response.statusCode == 200) {
            return;
          }
        } catch (_) {}
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      throw StateError('Embedded JS runner did not become healthy in time.');
    } finally {
      client.close(force: true);
    }
  }

  Future<String?> _resolveBinaryPath() async {
    final platformAsset = resolveEmbeddedRunnerPlatformAsset();
    if (platformAsset == null) {
      return null;
    }

    final supportDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(supportDir.path, 'embedded-runner-js'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final assetPath = platformAsset.bundleAssetPath;
    final fileName = platformAsset.fileName;
    final bundledSize = await _bundledAssetByteLength(assetPath);
    if (bundledSize != null) {
      final versionedFileName =
          '${p.basenameWithoutExtension(fileName)}.$bundledSize${p.extension(fileName)}';
      final cachedPath = p.join(targetDir.path, versionedFileName);
      if (await _isEmbeddedBinaryValid(File(cachedPath))) {
        return cachedPath;
      }
    }

    final cachedBinary = await _findCachedBinary(targetDir, fileName);
    if (cachedBinary != null) {
      return cachedBinary;
    }

    var data = await _readBundledAsset(assetPath);
    if (data == null) {
      final directPath = await _findDevBinary(assetPath);
      if (directPath != null) {
        return directPath;
      }
      debugPrint(
        '[EmbeddedJsRunner] Downloading latest release: $fileName',
      );
      data = await downloadEmbeddedRunnerLatestRelease(fileName);
      if (data == null) {
        debugPrint(
          '[EmbeddedJsRunner] Failed to download latest release for $fileName',
        );
        return null;
      }
    }

    final versionedFileName =
        '${p.basenameWithoutExtension(fileName)}.${data.length}${p.extension(fileName)}';
    final targetPath = p.join(targetDir.path, versionedFileName);
    await File(targetPath).writeAsBytes(data, flush: true);
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', targetPath]);
    }
    await _pruneOldCachedBinaries(targetDir, keepFileName: versionedFileName);
    return targetPath;
  }

  Future<String?> _findCachedBinary(Directory targetDir, String fileName) async {
    final baseName = p.basenameWithoutExtension(fileName);
    final extension = p.extension(fileName);
    try {
      await for (final entity in targetDir.list()) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        final matchesVersioned =
            name.startsWith('$baseName.') && name.endsWith(extension);
        if (name != fileName && !matchesVersioned) {
          continue;
        }
        if (await _isEmbeddedBinaryValid(entity)) {
          return entity.path;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _pruneOldCachedBinaries(
    Directory targetDir, {
    required String keepFileName,
  }) async {
    try {
      await for (final entity in targetDir.list()) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        if (name == keepFileName || name == 'runner.log') {
          continue;
        }
        if (!name.contains('bot-creator-runner-js')) {
          continue;
        }
        try {
          await entity.delete();
        } on PathAccessException {
          // Another process may still hold an older build open; ignore.
        }
      }
    } catch (_) {}
  }

  Future<bool> _isEmbeddedBinaryValid(File file) async {
    if (!await file.exists()) {
      return false;
    }
    final size = await file.length();
    return size >= embeddedRunnerMinBinaryBytes;
  }

  Future<String?> _findDevBinary(String assetPath) async {
    for (final candidate in _devAssetCandidates(assetPath)) {
      try {
        final file = File(candidate);
        if (await _isEmbeddedBinaryValid(file)) {
          debugPrint('[EmbeddedJsRunner] Using dev binary at $candidate');
          return file.path;
        }
      } catch (_) {}
    }
    return null;
  }

  List<String> _devAssetCandidates(String assetPath) {
    final fileName = p.basename(assetPath);
    final cwd = Directory.current.path;
    final candidates = <String>{
      assetPath,
      p.join(cwd, assetPath),
      p.join(cwd, 'packages', 'app', assetPath),
      p.join(cwd, 'bot-creator', 'packages', 'app', assetPath),
      p.join('packages', 'app', assetPath),
    };

    try {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      candidates.add(p.join(exeDir, 'data', 'flutter_assets', assetPath));
      var dir = Directory(exeDir);
      for (var i = 0; i < 6; i++) {
        candidates.add(p.join(dir.path, 'packages', 'app', assetPath));
        candidates.add(p.join(dir.path, assetPath));
        final parent = dir.parent;
        if (parent.path == dir.path) {
          break;
        }
        dir = parent;
      }
    } catch (_) {}

    return candidates
        .where((path) => p.basename(path) == fileName || path.endsWith(fileName))
        .toList(growable: false);
  }

  Future<int?> _bundledAssetByteLength(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.lengthInBytes;
    } catch (_) {
      for (final candidate in _devAssetCandidates(assetPath)) {
        try {
          final file = File(candidate);
          if (await _isEmbeddedBinaryValid(file)) {
            return file.length();
          }
        } catch (_) {}
      }
    }
    return null;
  }

  Future<List<int>?> _readBundledAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List();
      if (!isEmbeddedRunnerBinaryValid(bytes)) {
        return null;
      }
      return bytes;
    } catch (_) {
      for (final candidate in _devAssetCandidates(assetPath)) {
        try {
          final file = File(candidate);
          if (await _isEmbeddedBinaryValid(file)) {
            return file.readAsBytes();
          }
        } catch (_) {}
      }
      return null;
    }
  }

  Future<String> _dataDir() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'embedded-runner-data');
    await Directory(path).create(recursive: true);
    return path;
  }
}
