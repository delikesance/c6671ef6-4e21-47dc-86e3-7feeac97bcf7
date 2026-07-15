import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RunnerConnectionConfig serialization', () {
    test('roundtrips through JSON', () {
      const config = RunnerConnectionConfig(
        id: 'abc',
        url: 'https://runner.example.com',
        apiToken: 'tok123',
        name: 'Prod',
      );
      final json = config.toJson(includeToken: true);
      final restored = RunnerConnectionConfig.fromJson(json);

      expect(restored.id, 'abc');
      expect(restored.url, 'https://runner.example.com');
      expect(restored.apiToken, 'tok123');
      expect(restored.name, 'Prod');
    });

    test('omits null fields in toJson', () {
      const config = RunnerConnectionConfig(id: 'x', url: 'http://a');
      final json = config.toJson();

      expect(json.containsKey('apiToken'), isFalse);
      expect(json.containsKey('name'), isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final config = RunnerConnectionConfig.fromJson({
        'id': '1',
        'url': 'http://a',
      });
      expect(config.apiToken, isNull);
      expect(config.name, isNull);
    });
  });

  group('Empty state', () {
    test('getRunners returns empty list', () async {
      expect(await RunnerSettings.getRunners(), isEmpty);
    });

    test('getConfig returns null', () async {
      expect(await RunnerSettings.getConfig(), isNull);
    });

    test('createClient returns null', () async {
      expect(await RunnerSettings.createClient(), isNull);
    });

    test('getUrl returns null', () async {
      expect(await RunnerSettings.getUrl(), isNull);
    });

    test('getActiveId returns null', () async {
      expect(await RunnerSettings.getActiveId(), isNull);
    });
  });

  group('addRunner', () {
    test('adds a single runner and auto-selects it', () async {
      const config = RunnerConnectionConfig(
        id: 'r1',
        url: 'http://localhost:8080',
        name: 'Local',
      );

      await RunnerSettings.addRunner(config);

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.id, 'r1');
      expect(runners.first.url, 'http://localhost:8080');
      expect(runners.first.name, 'Local');

      final active = await RunnerSettings.getConfig();
      expect(active?.id, 'r1');
    });

    test('replaces runner with same id', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'r1', url: 'http://old'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'r1', url: 'http://new'),
      );

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.url, 'http://new');
    });

    test('adds multiple runners', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'b', url: 'http://b'),
      );

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(2));
      expect(runners.map((r) => r.id), containsAll(['a', 'b']));
    });
  });

  group('removeRunner', () {
    test('removes a runner', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'b', url: 'http://b'),
      );

      await RunnerSettings.removeRunner('a');

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.id, 'b');
    });

    test('promotes next runner when active is removed', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'b', url: 'http://b'),
      );
      await RunnerSettings.setActiveRunner('a');

      await RunnerSettings.removeRunner('a');

      final active = await RunnerSettings.getConfig();
      expect(active?.id, 'b');
    });

    test('clears active when last runner removed', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.removeRunner('a');

      expect(await RunnerSettings.getConfig(), isNull);
      expect(await RunnerSettings.getActiveId(), isNull);
    });
  });

  group('setActiveRunner', () {
    test('switches active runner', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'b', url: 'http://b'),
      );

      await RunnerSettings.setActiveRunner('b');
      expect((await RunnerSettings.getConfig())?.id, 'b');

      await RunnerSettings.setActiveRunner('a');
      expect((await RunnerSettings.getConfig())?.id, 'a');
    });
  });

  group('createClient', () {
    test('creates client from active runner', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: 'r1',
          url: 'http://localhost:9000',
          apiToken: 'secret',
        ),
      );

      final client = await RunnerSettings.createClient();
      expect(client, isNotNull);
    });
  });

  group('backward-compatible save/setUrl/setApiToken', () {
    test('save creates a runner entry', () async {
      await RunnerSettings.save(url: 'http://myrunner', apiToken: 'tok');

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.url, 'http://myrunner');
      expect(runners.first.apiToken, 'tok');
    });

    test('save with null URL clears user config', () async {
      await RunnerSettings.save(url: 'http://x', apiToken: 'y');
      await RunnerSettings.save(url: null);

      expect(await RunnerSettings.getRunners(), isEmpty);
      expect(await RunnerSettings.getConfig(), isNull);
    });

    test('setUrl updates active runner URL', () async {
      await RunnerSettings.save(url: 'http://old', apiToken: 'tok');
      await RunnerSettings.setUrl('http://new');

      expect(await RunnerSettings.getUrl(), 'http://new');
      expect(await RunnerSettings.getApiToken(), 'tok');
    });

    test('setApiToken updates active runner token', () async {
      await RunnerSettings.save(url: 'http://host', apiToken: 'old');
      await RunnerSettings.setApiToken('new');

      expect(await RunnerSettings.getApiToken(), 'new');
      expect(await RunnerSettings.getUrl(), 'http://host');
    });
  });

  group('clear', () {
    test('clears all runners and legacy keys', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://a'),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'b', url: 'http://b'),
      );

      await RunnerSettings.clear();

      expect(await RunnerSettings.getRunners(), isEmpty);
      expect(await RunnerSettings.getConfig(), isNull);
      expect(await RunnerSettings.getActiveId(), isNull);
    });
  });

  group('legacy migration', () {
    test('migrates singleton URL/token into registry', () async {
      // Simulate legacy format stored directly in SharedPreferences
      SharedPreferences.setMockInitialValues({
        'developer_runner_url': 'http://legacy-runner:8080',
        'developer_runner_api_token': 'legacytoken',
      });

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.url, 'http://legacy-runner:8080');
      expect(runners.first.apiToken, 'legacytoken');
      expect(runners.first.name, 'Default');

      // Active runner should be set
      final config = await RunnerSettings.getConfig();
      expect(config?.url, 'http://legacy-runner:8080');
      expect(config?.apiToken, 'legacytoken');

      // Legacy keys should be cleaned up
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('developer_runner_url'), isNull);
      expect(prefs.getString('developer_runner_api_token'), isNull);

      // New registry key should exist
      expect(prefs.getString('runner_registry'), isNotNull);
    });

    test('does not re-migrate if registry already exists', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'existing', url: 'http://existing'),
      );

      // Manually set legacy keys (should be ignored)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('developer_runner_url', 'http://stale');

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.id, 'existing');
    });

    test('skips migration when no legacy URL exists', () async {
      SharedPreferences.setMockInitialValues({
        'developer_runner_api_token': 'orphan-token',
      });

      final runners = await RunnerSettings.getRunners();
      expect(runners, isEmpty);
    });
  });

  group('edge cases', () {
    test(
      'getConfig falls back to first runner if active ID is stale',
      () async {
        await RunnerSettings.addRunner(
          const RunnerConnectionConfig(id: 'a', url: 'http://a'),
        );
        // Set a non-existent active ID
        await RunnerSettings.setActiveRunner('nonexistent');

        final config = await RunnerSettings.getConfig();
        expect(config?.id, 'a');
      },
    );

    test('corrupt registry JSON returns empty list', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('runner_registry', 'not-json');

      final runners = await RunnerSettings.getRunners();
      expect(runners, isEmpty);
    });

    test('registry entries with empty URL are filtered out', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'runner_registry',
        jsonEncode([
          {'id': 'good', 'url': 'http://ok'},
          {'id': 'bad', 'url': ''},
        ]),
      );

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.id, 'good');
    });
  });

  group('temporary disable', () {
    test(
      'preserves stored runner config while disabling active usage',
      () async {
        await RunnerSettings.addRunner(
          const RunnerConnectionConfig(id: 'a', url: 'http://runner'),
        );

        await RunnerSettings.setTemporarilyDisabled(true);

        expect(await RunnerSettings.isTemporarilyDisabled(), isTrue);
        expect(await RunnerSettings.getConfig(), isNull);
        expect((await RunnerSettings.getStoredConfig())?.url, 'http://runner');
      },
    );

    test('re-enabling restores the stored runner config', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'a', url: 'http://runner'),
      );
      await RunnerSettings.setTemporarilyDisabled(true);

      await RunnerSettings.setTemporarilyDisabled(false);

      expect(await RunnerSettings.isTemporarilyDisabled(), isFalse);
      expect((await RunnerSettings.getConfig())?.url, 'http://runner');
    });
  });

  group('embedded runner separation', () {
    test('getUserStoredConfig ignores embedded-js entry', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: RunnerSettings.embeddedRunnerId,
          url: 'http://127.0.0.1:18080',
          useEmbedded: true,
        ),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: 'remote',
          url: 'https://runner.example.com',
        ),
      );
      await RunnerSettings.setActiveRunner(RunnerSettings.embeddedRunnerId);

      final userConfig = await RunnerSettings.getUserStoredConfig();
      expect(userConfig?.id, 'remote');
      expect((await RunnerSettings.getConfig())?.id, 'remote');
    });

    test('getConfig does not return embedded entry when it is active', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: RunnerSettings.embeddedRunnerId,
          url: 'http://127.0.0.1:18080',
          useEmbedded: true,
        ),
      );
      await RunnerSettings.setActiveRunner(RunnerSettings.embeddedRunnerId);

      expect(await RunnerSettings.getConfig(), isNull);
      expect(await RunnerSettings.getUserStoredConfig(), isNull);
    });

    test('clearUserConfig preserves embedded registry entry', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: RunnerSettings.embeddedRunnerId,
          url: 'http://127.0.0.1:18080',
          useEmbedded: true,
        ),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(id: 'remote', url: 'https://runner.example.com'),
      );
      await RunnerSettings.setActiveRunner('remote');

      await RunnerSettings.clearUserConfig();

      final runners = await RunnerSettings.getRunners();
      expect(runners, hasLength(1));
      expect(runners.first.id, RunnerSettings.embeddedRunnerId);
      expect(await RunnerSettings.getUserStoredConfig(), isNull);
      expect(await RunnerSettings.getConfig(), isNull);
    });

    test('migrates active embedded selection to user runner when available', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'runner_registry',
        jsonEncode([
          {
            'id': RunnerSettings.embeddedRunnerId,
            'url': 'http://127.0.0.1:18080',
            'useEmbedded': true,
          },
          {
            'id': 'remote',
            'url': 'https://runner.example.com',
          },
        ]),
      );
      await prefs.setString('runner_active_id', RunnerSettings.embeddedRunnerId);

      await RunnerSettings.getRunners();

      expect(await RunnerSettings.getActiveId(), 'remote');
      expect((await RunnerSettings.getUserStoredConfig())?.url,
          'https://runner.example.com');
    });

    test('addRunner refreshes embedded runner url when already registered', () async {
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: RunnerSettings.embeddedRunnerId,
          url: 'http://127.0.0.1:18080',
          apiToken: 'old-token',
          useEmbedded: true,
        ),
      );
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: RunnerSettings.embeddedRunnerId,
          url: 'http://127.0.0.1:19090',
          apiToken: 'new-token',
          useEmbedded: true,
        ),
      );

      final runners = await RunnerSettings.getRunners();
      final embedded = runners.firstWhere(
        (runner) => runner.id == RunnerSettings.embeddedRunnerId,
      );
      expect(embedded.url, 'http://127.0.0.1:19090');
    });
  });

  group('resolveConfigForBot with runner temporarily disabled', () {
    late Directory documentsDir;
    const dartBotId = 'runner-settings-dart-bot';
    const jsBotId = 'runner-settings-js-bot';

    setUpAll(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      documentsDir = await Directory.systemTemp.createTemp('runner_settings_test');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, (call) async {
        return documentsDir.path;
      });
      appManager = AppManager();
    });

    tearDownAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_pathProviderChannel, null);
      if (await documentsDir.exists()) {
        try {
          await documentsDir.delete(recursive: true);
        } catch (_) {}
      }
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await appManager.saveApp(dartBotId, <String, dynamic>{
        'id': dartBotId,
        'username': 'DartBot',
        'runtimeEngine': runtimeEngineDart,
      });
      await appManager.saveApp(jsBotId, <String, dynamic>{
        'id': jsBotId,
        'username': 'JsBot',
        'runtimeEngine': runtimeEngineJavascript,
      });
      await RunnerSettings.addRunner(
        const RunnerConnectionConfig(
          id: 'remote',
          url: 'https://runner.example.com',
        ),
      );
      await RunnerSettings.setActiveRunner('remote');
      await RunnerSettings.setTemporarilyDisabled(true);
    });

    test('dart bot returns null and does not use remote runner', () async {
      final config = await RunnerSettings.resolveConfigForBot(dartBotId);
      expect(config, isNull);
    });

    test('javascript bot skips remote runner when disabled on desktop', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        final config = await RunnerSettings.resolveConfigForBot(jsBotId);
        expect(config?.url, isNot('https://runner.example.com'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
