import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_runner_downloader.dart';
import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Snapshot of embedded JS runner state for settings and diagnostics.
class EmbeddedRunnerDiagnostics {
  const EmbeddedRunnerDiagnostics({
    required this.isRunning,
    required this.isDownloading,
    this.phase,
    this.lastError,
    this.binaryPath,
    this.binarySizeBytes,
    this.baseUrl,
    this.logPath,
    this.version,
  });

  final bool isRunning;
  final bool isDownloading;
  final String? phase;
  final String? lastError;
  final String? binaryPath;
  final int? binarySizeBytes;
  final String? baseUrl;
  final String? logPath;
  final String? version;
}

class EmbeddedJsRunnerService {
  EmbeddedJsRunnerService._();

  static final EmbeddedJsRunnerService instance = EmbeddedJsRunnerService._();

  Process? _process;
  String? _url;
  String? _apiToken;
  int? _port;
  String? _binaryPath;
  String? _logPath;
  String? _lastStartupError;
  String? _lastBinaryResolveError;
  String? _lastStartupPhase;
  Future<void>? _startFuture;
  final StringBuffer _processOutput = StringBuffer();
  final ValueNotifier<EmbeddedRunnerDownloadProgress?> downloadProgress =
      ValueNotifier<EmbeddedRunnerDownloadProgress?>(null);

  bool get isRunning => _process != null;

  bool get hasLiveConfig =>
      _process != null && _url != null && _apiToken != null;

  bool get isDownloading =>
      downloadProgress.value != null || _lastStartupPhase == 'downloading';

  String? get lastStartupError => _lastStartupError;

  String? get lastStartupPhase => _lastStartupPhase;

  String? get binaryPath => _binaryPath;

  String? get logPath => _logPath;

  String? get baseUrl => _url;

  Future<RunnerConnectionConfig?> ensureConfig() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      if (_process != null && (_url == null || _apiToken == null)) {
        await stop();
      }

      if (hasLiveConfig) {
        _lastStartupPhase = 'running';
        return _buildConfig();
      }

      _startFuture ??= _ensureStarted();
      try {
        await _startFuture;
      } catch (error, stackTrace) {
        _lastStartupError = error.toString();
        _lastStartupPhase = 'failed';
        debugPrint('[EmbeddedJsRunner] Failed to start: $error');
        debugPrint('$stackTrace');
        await AppDiagnostics.logError(
          'Embedded JS runner failed to start',
          error,
          stackTrace,
          fatal: false,
          information: _diagnosticsInformation(),
        );
      } finally {
        _startFuture = null;
      }

      if (_url != null && _apiToken != null) {
        _lastStartupError = null;
        _lastStartupPhase = 'running';
        return _buildConfig();
      }
    }
    return null;
  }

  /// Clears in-flight startup so [ensureConfig] can start fresh (e.g. after hot reload).
  void resetStartupState() {
    _startFuture = null;
  }

  /// Stops the runner and starts it again using the existing binary resolution chain.
  Future<RunnerConnectionConfig?> restart() async {
    if (kIsWeb || !_isDesktopPlatform) {
      return null;
    }
    await stop();
    resetStartupState();
    return ensureConfig();
  }

  /// Deletes cached PKG binaries (keeps runner.log) and downloads a fresh release.
  Future<RunnerConnectionConfig?> redownloadAndRestart() async {
    if (kIsWeb || !_isDesktopPlatform) {
      return null;
    }
    await stop();
    resetStartupState();
    _binaryPath = null;
    _lastStartupError = null;
    await clearCachedBinary();

    _startFuture = _ensureStarted(forceRedownload: true);
    try {
      await _startFuture;
    } catch (error, stackTrace) {
      _lastStartupError = error.toString();
      _lastStartupPhase = 'failed';
      debugPrint('[EmbeddedJsRunner] Failed to redownload: $error');
      debugPrint('$stackTrace');
      await AppDiagnostics.logError(
        'Embedded JS runner redownload failed',
        error,
        stackTrace,
        fatal: false,
        information: _diagnosticsInformation(),
      );
    } finally {
      _startFuture = null;
    }

    if (_url != null && _apiToken != null) {
      _lastStartupError = null;
      _lastStartupPhase = 'running';
      return _buildConfig();
    }
    return null;
  }

  /// Removes downloaded runner binaries from application support storage.
  Future<void> clearCachedBinary() async {
    final targetDir = await _embeddedRunnerCacheDir();
    if (!await targetDir.exists()) {
      return;
    }

    try {
      await for (final entity in targetDir.list()) {
        if (entity is! File) {
          continue;
        }
        final name = p.basename(entity.path);
        if (name == 'runner.log' || !name.contains('bot-creator-runner-js')) {
          continue;
        }
        try {
          await entity.delete();
        } on PathAccessException {
          // Process may still hold the file open.
        }
      }
    } catch (_) {}

    if (_binaryPath != null) {
      final cached = File(_binaryPath!);
      if (!await cached.exists()) {
        _binaryPath = null;
      }
    }
  }

  /// Returns current runner status for the settings UI.
  Future<EmbeddedRunnerDiagnostics> getDiagnostics() async {
    var binaryPath = _binaryPath;
    int? binarySizeBytes;

    if (binaryPath != null) {
      final file = File(binaryPath);
      if (await file.exists()) {
        binarySizeBytes = await file.length();
      } else {
        binaryPath = null;
      }
    }

    if (binaryPath == null) {
      final platformAsset = resolveEmbeddedRunnerPlatformAsset();
      if (platformAsset != null) {
        final targetDir = await _embeddedRunnerCacheDir();
        binaryPath = await _findCachedBinary(targetDir, platformAsset.fileName);
        if (binaryPath != null) {
          binarySizeBytes = await File(binaryPath).length();
        }
      }
    }

    String? version;
    if (isRunning && _url != null) {
      try {
        version = await _buildConfig()
            .createClient(getTimeout: const Duration(seconds: 5))
            .getRunnerVersion();
        if (version != null && version.trim().isEmpty) {
          version = null;
        } else {
          version = version?.trim();
        }
      } catch (_) {
        version = null;
      }
    }

    return EmbeddedRunnerDiagnostics(
      isRunning: isRunning,
      isDownloading: isDownloading,
      phase: _lastStartupPhase,
      lastError: _lastStartupError ?? _lastBinaryResolveError,
      binaryPath: binaryPath,
      binarySizeBytes: binarySizeBytes,
      baseUrl: _url,
      logPath: _logPath,
      version: version,
    );
  }

  bool get _isDesktopPlatform {
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> stop() async {
    final process = _process;
    _process = null;
    _url = null;
    _apiToken = null;
    _port = null;
    _lastStartupPhase = 'stopped';
    if (process != null) {
      process.kill();
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // Best effort: the OS may take a moment to release the file lock.
      }
    }
  }

  Future<void> _ensureStarted({bool forceRedownload = false}) async {
    if (_process != null) {
      return;
    }

    _processOutput.clear();
    _lastStartupError = null;
    _lastStartupPhase = 'resolving_binary';

    await stop();

    final binaryPath = await _resolveBinaryPath(forceRedownload: forceRedownload);
    if (binaryPath == null) {
      throw StateError(
        _lastBinaryResolveError ??
            'Embedded JS runner binary is not available on this platform.',
      );
    }
    _binaryPath = binaryPath;

    _lastStartupPhase = 'spawning';
    _port = 18080 + (DateTime.now().millisecond % 1000);
    _apiToken = 'embedded-${DateTime.now().millisecondsSinceEpoch}';
    _url = 'http://127.0.0.1:$_port';

    final dataDir = await _dataDir();
    _logPath = p.join(dataDir, 'runner.log');

    _process = await Process.start(
      binaryPath,
      const [],
      workingDirectory: dataDir,
      environment: {
        'BOT_CREATOR_WEB_HOST': '127.0.0.1',
        'BOT_CREATOR_WEB_PORT': _port.toString(),
        'BOT_CREATOR_API_TOKEN': _apiToken!,
        'BOT_CREATOR_DATA_DIR': dataDir,
        'BOT_CREATOR_RUNNER_LOG_FILE': _logPath!,
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

    _lastStartupPhase = 'health_check';
    await _waitUntilHealthy();

    await AppDiagnostics.logInfo(
      'Embedded JS runner started',
      data: {
        'baseUrl': _url,
        'binaryPath': binaryPath,
        'dataDir': dataDir,
        'logPath': _logPath,
      },
    );
  }

  RunnerConnectionConfig _buildConfig() {
    return RunnerConnectionConfig(
      id: RunnerSettings.embeddedRunnerId,
      url: _url!,
      apiToken: _apiToken,
      name: 'Embedded JS Runner',
      kind: RunnerKind.javascript,
      useEmbedded: true,
    );
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

  Future<String?> _resolveBinaryPath({bool forceRedownload = false}) async {
    _lastBinaryResolveError = null;
    final platformAsset = resolveEmbeddedRunnerPlatformAsset();
    if (platformAsset == null) {
      _lastBinaryResolveError =
          'Embedded JS runner is not supported on this platform.';
      return null;
    }

    if (!forceRedownload) {
      final envOverride = embeddedRunnerEnvOverridePath();
      if (envOverride != null) {
        final envFile = File(envOverride);
        if (await _isEmbeddedBinaryValid(envFile)) {
          return envOverride;
        }
        _lastBinaryResolveError =
            'BOT_CREATOR_EMBEDDED_RUNNER_JS_PATH is set but invalid: $envOverride';
        return null;
      }
    }

    final targetDir = await _embeddedRunnerCacheDir();
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final assetPath = platformAsset.bundleAssetPath;
    final fileName = platformAsset.fileName;

    if (!forceRedownload) {
      // 1. Valid cached copy
      final cachedBinary = await _findCachedBinary(targetDir, fileName);
      if (cachedBinary != null) {
        return cachedBinary;
      }

      // 2. Packaged asset on disk (filesystem copy — preferred for release)
      final fromPackage = await _copyPackagedAssetToCache(
        targetDir,
        fileName,
        assetPath,
      );
      if (fromPackage != null) {
        return fromPackage;
      }

      // 3. rootBundle (dev / tests)
      var data = await _readBundledAsset(assetPath);

      // 4. Dev path candidates (local checkout / monorepo sibling build)
      if (data == null) {
        final directPath = await _findDevBinary(assetPath);
        if (directPath != null) {
          return directPath;
        }
      } else {
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
    }

    debugPrint(
      '[EmbeddedJsRunner] Downloading latest release: $fileName',
    );
    _lastStartupPhase = 'downloading';
    _updateDownloadProgress(
      const EmbeddedRunnerDownloadProgress(receivedBytes: 0),
    );
    EmbeddedRunnerDownloadResult download;
    try {
      download = await downloadEmbeddedRunnerLatestRelease(
        fileName,
        onProgress: _updateDownloadProgress,
      );
    } finally {
      _updateDownloadProgress(null);
    }
    if (!download.ok) {
      _lastBinaryResolveError =
          download.failureReason ?? 'Failed to download latest release.';
      debugPrint(
        '[EmbeddedJsRunner] Failed to download latest release: '
        '${_lastBinaryResolveError!}',
      );
      return null;
    }

    final data = download.bytes!;
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

  Future<String?> _copyPackagedAssetToCache(
    Directory targetDir,
    String fileName,
    String assetPath,
  ) async {
    final packagedPath = await resolvePackagedEmbeddedRunnerAsset(assetPath);
    if (packagedPath == null) {
      return null;
    }

    final source = File(packagedPath);
    final versionedFileName =
        '${p.basenameWithoutExtension(fileName)}.${await source.length()}${p.extension(fileName)}';
    final targetPath = p.join(targetDir.path, versionedFileName);

    if (await _isEmbeddedBinaryValid(File(targetPath))) {
      return targetPath;
    }

    await source.copy(targetPath);
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
    return isEmbeddedRunnerBinaryFileValid(file);
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
      ...monorepoRunnerJsBuildCandidates(fileName),
      assetPath,
      p.join(cwd, assetPath),
      p.join(cwd, 'packages', 'app', assetPath),
      p.join(cwd, 'bot-creator', 'packages', 'app', assetPath),
      p.join('packages', 'app', assetPath),
    };

    for (final candidate in packagedEmbeddedRunnerAssetCandidates(assetPath)) {
      candidates.add(candidate);
    }

    return candidates
        .where((path) => p.basename(path) == fileName || path.endsWith(fileName))
        .toList(growable: false);
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
      return null;
    }
  }

  Future<String> _dataDir() async {
    final dir = await getApplicationSupportDirectory();
    final path = p.join(dir.path, 'embedded-runner-data');
    await Directory(path).create(recursive: true);
    return path;
  }

  Future<Directory> _embeddedRunnerCacheDir() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory(p.join(supportDir.path, 'embedded-runner-js'));
  }

  String _diagnosticsInformation() {
    final summary = _processOutputSummary();
    return [
      'phase=$_lastStartupPhase',
      if (_binaryPath != null) 'binaryPath=$_binaryPath',
      if (_logPath != null) 'logPath=$_logPath',
      if (_url != null) 'baseUrl=$_url',
      if (summary.isNotEmpty) 'processOutput=$summary',
      'asset=${resolveEmbeddedRunnerPlatformAsset()?.bundleAssetPath ?? 'unknown'}',
    ].join('; ');
  }

  void _updateDownloadProgress(EmbeddedRunnerDownloadProgress? progress) {
    downloadProgress.value = progress;
  }
}
