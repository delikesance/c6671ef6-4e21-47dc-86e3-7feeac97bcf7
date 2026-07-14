import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/runner/embedded_js_runner_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EmbeddedJsRunnerService config', () {
    test('embedded runner registry id matches RunnerSettings constant', () {
      expect(RunnerSettings.embeddedRunnerId, 'embedded-js');
    });

    test('startup failure detail is null before any start attempt', () {
      expect(RunnerSettings.embeddedRunnerStartupFailureDetail(), isNull);
      expect(EmbeddedJsRunnerService.instance.lastStartupPhase, isNull);
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
}
