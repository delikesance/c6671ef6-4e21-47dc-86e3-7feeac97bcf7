import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/runtime_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
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
    'android blocks local fallback when manager account is not connected',
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

  test('android local hosting opt-in restores local runtime', () async {
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

  test('iOS ignores local hosting opt-in and keeps manager runtime', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await RuntimePreferences.setMobileLocalHostingEnabled(true);
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );

    final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

    expect(runtime.source, RemoteRuntimeSource.manager);
    expect(runtime.client, isNull);
    expect(runtime.blocksLocalFallback, isTrue);
  });

  test(
    'desktop ignores manager runtime and still uses direct runner',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: 'runner-1',
          url: 'https://runner.example.com',
        ),
      );

      final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

      expect(runtime.source, RemoteRuntimeSource.runner);
      expect(runtime.client, isNotNull);
    },
  );

  test('desktop falls back to local when no runner is configured', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );

    final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

    expect(runtime.source, RemoteRuntimeSource.local);
    expect(runtime.client, isNull);
  });

  test(
    'manager start retries while free runtime credit is still propagating',
    () async {
      var attempts = 0;
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          if (request.url.path == '/gateway/bots/bot-1/start') {
            attempts += 1;
            if (attempts < 3) {
              return http.Response(
                '{"code":"bot_free_time_required","message":"bot requires free runtime credits before start"}',
                403,
              );
            }
            return http.Response('{}', 200);
          }
          return http.Response('{}', 404);
        }),
      );

      await startManagerBotWithCreditRetry(
        client: client,
        botId: 'bot-1',
        botName: 'Test Bot',
        timeout: const Duration(seconds: 1),
        retryDelay: const Duration(milliseconds: 1),
      );

      expect(attempts, 3);
    },
  );

  test('manager start uses only the gateway start endpoint', () async {
    final requestedPaths = <String>[];
    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      httpClient: MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path == '/gateway/bots/bot-1/start') {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('{}', 404);
      }),
    );

    await client.startBot('bot-1', botName: 'Test Bot');

    expect(requestedPaths, <String>['/gateway/bots/bot-1/start']);
  });

  test('manager start retries while the runner is deploying', () async {
    var attempts = 0;
    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      httpClient: MockClient((request) async {
        if (request.url.path == '/gateway/bots/bot-1/start') {
          attempts += 1;
          if (attempts < 3) {
            return http.Response(
              '{"code":"runner_not_deployed","message":"runner is not deployed for this owner"}',
              404,
            );
          }
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('{}', 404);
      }),
    );

    await startManagerBotWithCreditRetry(
      client: client,
      botId: 'bot-1',
      botName: 'Test Bot',
      timeout: const Duration(seconds: 1),
      retryDelay: const Duration(milliseconds: 1),
    );

    expect(attempts, 3);
  });
}
