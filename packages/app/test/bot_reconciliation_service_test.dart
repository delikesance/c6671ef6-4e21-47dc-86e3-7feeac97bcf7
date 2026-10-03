import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_reconciliation_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late AppManager appManager;
  const botId = '123456789012345678';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp(
      'bot_reconciliation_test',
    );
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
    // Reset bot state for each test
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'name': 'TestBot',
      'token': 'test_token',
      'workflows': <Map<String, dynamic>>[],
      'globalVariables': <String, dynamic>{},
    });

    final existingCmds = await appManager.listAppCommands(botId);
    for (final cmd in existingCmds) {
      await appManager.deleteAppCommand(botId, cmd['id'].toString());
    }
  });

  MainApiClient createMockClientWithConfig(Map<String, dynamic> config) {
    return MainApiClient(
      baseUrl: 'https://manager.example.com',
      accessToken: 'dummy_token',
      httpClient: MockClient((request) async {
        if (request.url.host == 'r2.example.com') {
          return http.Response(
            jsonEncode(config),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/config')) {
          return http.Response(
            jsonEncode({'configUrl': 'https://r2.example.com/config.json'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/sync')) {
          return http.Response('{"ok":true}', 200);
        }
        return http.Response('{"error":"not found"}', 404);
      }),
    );
  }

  test(
    'checkSyncStatus detects cloudNewer when remote has newer commands',
    () async {
      // Local has older cmd
      await appManager.saveAppCommand(botId, 'cmd_ping', {
        'id': 'cmd_ping',
        'name': 'ping',
        'updatedAt': '2026-09-01T10:00:00.000Z',
      });

      final remoteConfig = {
        'commands': [
          {
            'id': 'cmd_ping',
            'name': 'ping',
            'updatedAt': '2026-09-04T12:00:00.000Z',
          },
        ],
        'workflows': [],
        'globalVariables': {},
        'updatedAt': '2026-09-04T12:00:00.000Z',
      };

      final client = createMockClientWithConfig(remoteConfig);
      final result = await BotReconciliationService.checkSyncStatus(
        botId: botId,
        client: client,
        appManager: appManager,
      );

      expect(result.status, BotSyncStatus.cloudNewer);
      expect(result.diff?.updatedCommands.length, 1);
    },
  );

  test(
    'checkSyncStatus detects inSync when local and remote are identical',
    () async {
      await appManager.saveAppCommand(botId, 'cmd_ping', {
        'id': 'cmd_ping',
        'name': 'ping',
        'updatedAt': '2026-09-04T12:00:00.000Z',
      });

      final remoteConfig = {
        'commands': [
          {
            'id': 'cmd_ping',
            'name': 'ping',
            'updatedAt': '2026-09-04T12:00:00.000Z',
          },
        ],
        'workflows': [],
        'globalVariables': {},
      };

      final client = createMockClientWithConfig(remoteConfig);
      final result = await BotReconciliationService.checkSyncStatus(
        botId: botId,
        client: client,
        appManager: appManager,
      );

      expect(result.status, BotSyncStatus.inSync);
    },
  );

  test('checkSyncStatus favors cloud despite newer local edits', () async {
    await appManager.saveAppCommand(botId, 'cmd_ping', {
      'id': 'cmd_ping',
      'name': 'ping',
      'updatedAt': '2026-09-05T10:00:00.000Z',
    });

    final remoteConfig = {
      'commands': [
        {
          'id': 'cmd_ping',
          'name': 'ping',
          'updatedAt': '2026-09-04T12:00:00.000Z',
        },
      ],
      'workflows': [],
      'globalVariables': {},
    };

    final client = createMockClientWithConfig(remoteConfig);
    final result = await BotReconciliationService.checkSyncStatus(
      botId: botId,
      client: client,
      appManager: appManager,
    );

    expect(result.status, BotSyncStatus.cloudNewer);
  });

  test('checkSyncStatus favors cloud when both sides differ', () async {
    // Local updated cmd1
    await appManager.saveAppCommand(botId, 'cmd1', {
      'id': 'cmd1',
      'name': 'cmd1',
      'updatedAt': '2026-09-05T10:00:00.000Z',
    });

    // Remote updated cmd2 (or added cmd2 with newer timestamp)
    final remoteConfig = {
      'commands': [
        {'id': 'cmd1', 'name': 'cmd1', 'updatedAt': '2026-09-01T10:00:00.000Z'},
        {'id': 'cmd2', 'name': 'cmd2', 'updatedAt': '2026-09-04T12:00:00.000Z'},
      ],
      'workflows': [],
      'globalVariables': {},
    };

    final client = createMockClientWithConfig(remoteConfig);
    final result = await BotReconciliationService.checkSyncStatus(
      botId: botId,
      client: client,
      appManager: appManager,
    );

    expect(result.status, BotSyncStatus.cloudNewer);
  });

  test(
    'applyCloudToLocal overwrites local commands and preserves token',
    () async {
      await appManager.saveApp(botId, {
        'id': botId,
        'name': 'OldName',
        'token': 'secret_local_token',
      });

      await appManager.saveAppCommand(botId, 'old_cmd', {
        'id': 'old_cmd',
        'name': 'old_cmd',
        'updatedAt': '2026-01-01T00:00:00.000Z',
      });

      final remoteConfig = {
        'name': 'NewCloudName',
        'token': '', // Empty remote token should not erase local token
        'commands': [
          {
            'id': 'new_cmd',
            'name': 'new_cmd',
            'updatedAt': '2026-09-04T15:00:00.000Z',
          },
        ],
        'workflows': [
          {'name': 'WelcomeWorkflow', 'actions': []},
        ],
      };

      await BotReconciliationService.applyCloudToLocal(
        botId: botId,
        remoteConfig: remoteConfig,
        appManager: appManager,
      );

      final commands = await appManager.listAppCommands(botId);
      expect(commands.map((c) => c['id']), contains('new_cmd'));
      expect(commands.map((c) => c['id']), isNot(contains('old_cmd')));

      final updatedApp = await appManager.getApp(botId);
      expect(updatedApp['token'], 'secret_local_token');
    },
  );

  test(
    'remote content wins with equal timestamps and workflow lengths',
    () async {
      final stamp = '2026-09-04T12:00:00.000Z';
      await appManager.saveAppCommand(botId, 'same', {
        'id': 'same',
        'name': 'ping',
        'updatedAt': stamp,
        'data': {
          'response': {'text': 'local'},
        },
      });
      await appManager.saveApp(botId, {
        'id': botId,
        'name': 'TestBot',
        'token': 'test_token',
        'workflows': [
          {
            'name': 'flow',
            'actions': [
              {'type': 'local'},
            ],
          },
        ],
      });
      final remote = <String, dynamic>{
        'commands': [
          {
            'id': 'same',
            'name': 'ping',
            'updatedAt': stamp,
            'data': {
              'response': {'text': 'remote'},
            },
          },
        ],
        'workflows': [
          {
            'name': 'flow',
            'actions': [
              {'type': 'remote'},
            ],
          },
        ],
      };
      final status = await BotReconciliationService.checkSyncStatus(
        botId: botId,
        client: createMockClientWithConfig(remote),
        appManager: appManager,
      );
      expect(status.status, BotSyncStatus.cloudNewer);
      await BotReconciliationService.applyCloudToLocal(
        botId: botId,
        remoteConfig: remote,
        appManager: appManager,
      );
      final command = await appManager.getAppCommand(botId, 'same');
      expect(command['data']['response']['text'], 'remote');
      final app = await appManager.getApp(botId);
      expect(app['workflows'][0]['actions'][0]['type'], 'remote');
    },
  );

  test(
    'empty cloud removes local duplicate and workflow without pushing',
    () async {
      await appManager.saveAppCommand(botId, 'old-id', {
        'id': 'old-id',
        'name': 'eval',
      });
      await appManager.saveAppCommand(botId, 'new-id', {
        'id': 'new-id',
        'name': 'eval',
      });
      await appManager.saveWorkflow(botId, name: 'local-flow', actions: []);
      await BotReconciliationService.applyCloudToLocal(
        botId: botId,
        remoteConfig: {'commands': [], 'workflows': [], 'globalVariables': {}},
        appManager: appManager,
      );
      expect(
        await appManager.listAppCommands(botId, forceRefresh: true),
        isEmpty,
      );
      expect(await appManager.getWorkflows(botId), isEmpty);
      expect((await appManager.getApp(botId))['token'], 'test_token');
    },
  );

  test(
    'smartMerge preserves both local-only and remote-only commands and workflows',
    () async {
      // Local has local_only_cmd and older shared_cmd
      await appManager.saveAppCommand(botId, 'local_only_cmd', {
        'id': 'local_only_cmd',
        'name': 'local_only_cmd',
        'updatedAt': '2026-09-04T10:00:00.000Z',
      });
      await appManager.saveAppCommand(botId, 'shared_cmd', {
        'id': 'shared_cmd',
        'name': 'shared_cmd_old_content',
        'updatedAt': '2026-09-01T10:00:00.000Z',
      });

      // Remote has remote_only_cmd and newer shared_cmd
      final remoteConfig = {
        'commands': [
          {
            'id': 'remote_only_cmd',
            'name': 'remote_only_cmd',
            'updatedAt': '2026-09-04T11:00:00.000Z',
          },
          {
            'id': 'shared_cmd',
            'name': 'shared_cmd_new_content',
            'updatedAt': '2026-09-04T12:00:00.000Z',
          },
        ],
        'workflows': [
          {'name': 'CloudWorkflow', 'actions': []},
        ],
        'globalVariables': {'cloud_var': '123'},
      };

      var syncPayloadPushed = false;
      final client = MainApiClient(
        baseUrl: 'https://manager.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          if (request.url.path.contains('/sync')) {
            syncPayloadPushed = true;
            return http.Response('{"ok":true}', 200);
          }
          return http.Response('{"error":"not found"}', 404);
        }),
      );

      await BotReconciliationService.smartMerge(
        botId: botId,
        remoteConfig: remoteConfig,
        client: client,
        appManager: appManager,
        botName: 'TestBot',
      );

      final mergedCommands = await appManager.listAppCommands(botId);
      final commandIds = mergedCommands.map((c) => c['id']).toSet();

      // Both local-only and remote-only are preserved!
      expect(commandIds, contains('local_only_cmd'));
      expect(commandIds, contains('remote_only_cmd'));
      expect(commandIds, contains('shared_cmd'));

      // Newer remote content was picked for shared_cmd
      final sharedCmd = mergedCommands.firstWhere(
        (c) => c['id'] == 'shared_cmd',
      );
      expect(sharedCmd['name'], 'shared_cmd_new_content');

      // Remote workflow was added
      final app = await appManager.getApp(botId);
      final workflows = (app['workflows'] as List).cast<Map>();
      expect(workflows.map((w) => w['name']), contains('CloudWorkflow'));

      // Pushed to Cloud to unify both devices
      expect(syncPayloadPushed, isTrue);
    },
  );
}
