import 'dart:io';

import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_js_runner_service.dart';
import 'package:bot_creator/core/runner/embedded_runner_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  late Directory _root;

  void setRoot(Directory root) {
    _root = root;
  }

  @override
  Future<String?> getApplicationSupportPath() async => _root.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempRoot;
  late _FakePathProviderPlatform fakePathProvider;

  setUpAll(() {
    fakePathProvider = _FakePathProviderPlatform();
    PathProviderPlatform.instance = fakePathProvider;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempRoot = await Directory.systemTemp.createTemp('embedded-runner-test');
    fakePathProvider.setRoot(tempRoot);
  });

  tearDown(() async {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  });

  group('EmbeddedJsRunnerService config', () {
    test('embedded runner registry id matches RunnerSettings constant', () {
      expect(RunnerSettings.embeddedRunnerId, 'embedded-js');
    });

    test('startup failure detail is null before any start attempt', () async {
      expect(
        await RunnerSettings.embeddedRunnerStartupFailureNotice(),
        isNull,
      );
      expect(EmbeddedJsRunnerService.instance.lastStartupPhase, isNull);
    });

    test('hasLiveConfig is false before startup', () {
      expect(EmbeddedJsRunnerService.instance.hasLiveConfig, isFalse);
    });
  });

  group('embedded runner registration', () {
    test('persisted embedded runner uses javascript kind and useEmbedded', () async {
      const embedded = RunnerConnectionConfig(
        id: RunnerSettings.embeddedRunnerId,
        url: 'http://127.0.0.1:3000',
        name: 'Embedded JS Runner',
        kind: RunnerKind.javascript,
        useEmbedded: true,
      );

      await RunnerSettings.addRunner(embedded);
      await RunnerSettings.setActiveRunner(RunnerSettings.embeddedRunnerId);

      final runners = await RunnerSettings.getRunners();
      final stored = runners.firstWhere(
        (runner) => runner.id == RunnerSettings.embeddedRunnerId,
      );

      expect(stored.useEmbedded, isTrue);
      expect(stored.kind, RunnerKind.javascript);
      expect(RunnerSettings.isInternalEmbeddedRunner(stored), isTrue);
    });
  });

  group('EmbeddedJsRunnerService diagnostics', () {
    test('getDiagnostics reports idle state before startup', () async {
      final diagnostics = await EmbeddedJsRunnerService.instance.getDiagnostics();

      expect(diagnostics.isRunning, isFalse);
      expect(diagnostics.isDownloading, isFalse);
    });

    test('clearCachedBinary removes cached runner binaries', () async {
      final cacheDir = Directory(p.join(tempRoot.path, 'embedded-runner-js'));
      await cacheDir.create(recursive: true);

      final fakeBinary = File(
        p.join(cacheDir.path, 'bot-creator-runner-js-linux-x64.1048576'),
      );
      await fakeBinary.writeAsBytes(
        List.filled(embeddedRunnerMinBinaryBytes, 1),
      );
      final logFile = File(p.join(cacheDir.path, 'runner.log'));
      await logFile.writeAsString('runner log');

      await EmbeddedJsRunnerService.instance.clearCachedBinary();

      expect(await fakeBinary.exists(), isFalse);
      expect(await logFile.exists(), isTrue);

      final diagnostics = await EmbeddedJsRunnerService.instance.getDiagnostics();
      expect(diagnostics.binaryPath, isNull);
    });

    test('getDiagnostics reports cached binary without starting runner', () async {
      final cacheDir = Directory(p.join(tempRoot.path, 'embedded-runner-js'));
      await cacheDir.create(recursive: true);
      final fileName = embeddedRunnerBinaryFileName();
      final fakeBinary = File(
        p.join(cacheDir.path, '${p.basenameWithoutExtension(fileName)}.1048576${p.extension(fileName)}'),
      );
      await fakeBinary.writeAsBytes(
        List.filled(embeddedRunnerMinBinaryBytes, 2),
      );

      final diagnostics = await EmbeddedJsRunnerService.instance.getDiagnostics();

      expect(diagnostics.binaryPath, fakeBinary.path);
      expect(diagnostics.binarySizeBytes, embeddedRunnerMinBinaryBytes);
      expect(diagnostics.isRunning, isFalse);
    });
  });
}
