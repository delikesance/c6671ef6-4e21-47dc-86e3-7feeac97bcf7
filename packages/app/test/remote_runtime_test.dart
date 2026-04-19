import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/remote_runtime.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:bot_creator/utils/runtime_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('mobile prefers manager when a valid session exists', () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );

    final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

    expect(runtime.source, RemoteRuntimeSource.manager);
    expect(runtime.client, isNotNull);
    expect(runtime.blocksLocalFallback, isFalse);
  });

  test(
    'mobile blocks local fallback when manager account is not connected',
    () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: 'runner-1',
          url: 'https://runner.example.com',
        ),
      );

      final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

      expect(runtime.source, RemoteRuntimeSource.manager);
      expect(runtime.client, isNull);
      expect(runtime.blocksLocalFallback, isTrue);
    },
  );

  test('mobile local hosting opt-in restores local runtime', () async {
    await RuntimePreferences.setMobileLocalHostingEnabled(true);
    await RunnerSettings.addRunner(
      const RunnerConnectionConfig(
        id: 'runner-1',
        url: 'https://runner.example.com',
      ),
    );

    final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

    expect(runtime.source, RemoteRuntimeSource.local);
    expect(runtime.client, isNull);
    expect(runtime.blocksLocalFallback, isFalse);
  });

  test('desktop still uses direct runner when configured', () async {
    await RunnerSettings.addRunner(
      const RunnerConnectionConfig(
        id: 'runner-1',
        url: 'https://runner.example.com',
      ),
    );

    final runtime = await resolveRemoteRuntime(supportsManagerRuntime: false);

    expect(runtime.source, RemoteRuntimeSource.runner);
    expect(runtime.client, isNotNull);
    expect(runtime.blocksLocalFallback, isFalse);
  });
}
