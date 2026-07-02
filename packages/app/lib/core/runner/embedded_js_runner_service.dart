import 'dart:io';

import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
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

  bool get isRunning => _process != null;

  Future<RunnerConnectionConfig?> ensureConfig() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await _ensureStarted();
      if (_url != null && _apiToken != null) {
        return RunnerConnectionConfig(
          id: 'embedded-js',
          url: _url!,
          apiToken: _apiToken,
          name: 'Embedded JS Runner',
          kind: RunnerKind.javascript,
          useEmbedded: true,
        );
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
    }
  }

  Future<void> _ensureStarted() async {
    if (_process != null) {
      return;
    }

    final binaryPath = await _resolveBinaryPath();
    if (binaryPath == null) {
      throw StateError('Embedded JS runner binary is not available on this platform.');
    }

    _port = 18080 + (DateTime.now().millisecond % 1000);
    _apiToken = 'embedded-${DateTime.now().millisecondsSinceEpoch}';
    _url = 'http://127.0.0.1:$_port';

    _process = await Process.start(
      binaryPath,
      const [],
      environment: {
        'BOT_CREATOR_WEB_HOST': '127.0.0.1',
        'BOT_CREATOR_WEB_PORT': '$_port',
        'BOT_CREATOR_API_TOKEN': _apiToken!,
        'BOT_CREATOR_DATA_DIR': await _dataDir(),
      },
    );
  }

  Future<String?> _resolveBinaryPath() async {
    final supportDir = await getApplicationSupportDirectory();
    final targetDir = Directory(p.join(supportDir.path, 'embedded-runner-js'));
    if (!await targetDir.exists()) {
      await targetDir.create(recursive: true);
    }

    final assetPath = _assetPathForPlatform();
    if (assetPath == null) {
      return null;
    }

    final fileName = p.basename(assetPath);
    final targetPath = p.join(targetDir.path, fileName);
    final targetFile = File(targetPath);

    if (!await targetFile.exists()) {
      final data = await _readBundledAsset(assetPath);
      if (data == null) {
        return null;
      }
      await targetFile.writeAsBytes(data, flush: true);
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', targetPath]);
      }
    }

    return targetPath;
  }

  String? _assetPathForPlatform() {
    if (Platform.isWindows) {
      return 'assets/embedded-runner-js/bot-creator-runner-js-win.exe';
    }
    if (Platform.isLinux) {
      return 'assets/embedded-runner-js/bot-creator-runner-js-linux-x64';
    }
    if (Platform.isMacOS) {
      return 'assets/embedded-runner-js/bot-creator-runner-js-macos-arm64';
    }
    return null;
  }

  Future<List<int>?> _readBundledAsset(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      return data.buffer.asUint8List();
    } catch (_) {
      try {
        final devCandidate = File(p.join('packages', 'app', assetPath));
        if (await devCandidate.exists()) {
          return devCandidate.readAsBytes();
        }
      } catch (_) {}
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
