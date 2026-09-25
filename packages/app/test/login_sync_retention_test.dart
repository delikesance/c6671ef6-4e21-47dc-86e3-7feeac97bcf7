import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/auth/main_api_account_bootstrap.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
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
  const botId = '987654321098765432';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp(
      'login_sync_retention_test',
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
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'name': 'TestBot',
      'token': 'test_token',
      'workflows': <Map<String, dynamic>>[],
      'globalVariables': <String, dynamic>{},
    });

    final existingCmds = await appManager.listAppCommands(
      botId,
      forceRefresh: true,
    );
    for (final cmd in existingCmds) {
      final cmdId = (cmd['id'] ?? '').toString();
      if (cmdId.isNotEmpty) {
        await appManager.deleteAppCommand(botId, cmdId);
      }
    }
  });

  test(
    'applyManagerConfigToLocal does NOT delete local-only commands by default',
    () async {
      // 1. Save a local command
      await appManager.saveAppCommand(botId, 'local_only', <String, dynamic>{
        'id': 'local_only',
        'name': 'local_only',
        'description': 'Local only command',
        'type': 'chatInput',
        'data': <String, dynamic>{},
      });

      // 2. Remote config contains only a remote command
      final remoteConfig = <String, dynamic>{
        'commands': <Map<String, dynamic>>[
          {
            'id': 'remote_cmd',
            'name': 'remote_cmd',
            'description': 'Remote command',
            'data': <String, dynamic>{},
          },
        ],
      };

      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remoteConfig,
        saveAppMetadata: false,
        deleteMissingLocalCommands: false,
      );

      final commandsAfter = await appManager.listAppCommands(
        botId,
        forceRefresh: true,
      );
      final commandIds = commandsAfter.map((c) => c['id']).toList();

      expect(commandIds, contains('local_only'));
      expect(commandIds, contains('remote_cmd'));
    },
  );

  test(
    'une RESTAURATION, elle, supprime les commandes absentes de la version restaurée',
    () async {
      // Le cas réel : le stockage local contient une commande créée APRÈS la
      // version que l'on restaure (les deux « eval » venaient de là). Une
      // restauration doit rétablir un ÉTAT, pas faire l'union avec l'état
      // courant — sinon la liste affiche des commandes qui n'existent plus sur
      // le serveur, et la synchro suivante les y renvoie (la restauration est
      // annulée en silence).
      await appManager.saveAppCommand(botId, 'created_after', <String, dynamic>{
        'id': 'created_after',
        'name': 'created_after',
        'description': 'Créée après la version restaurée',
        'type': 'chatInput',
        'data': <String, dynamic>{},
      });
      await appManager.saveAppCommand(
        botId,
        'in_the_version',
        <String, dynamic>{
          'id': 'in_the_version',
          'name': 'in_the_version',
          'description': 'Présente dans la version',
          'type': 'chatInput',
          'data': <String, dynamic>{'marker': 'état local'},
        },
      );

      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: <String, dynamic>{
          'commands': <Map<String, dynamic>>[
            {
              'id': 'in_the_version',
              'name': 'in_the_version',
              'description': 'Présente dans la version',
              'data': <String, dynamic>{'marker': 'version restaurée'},
            },
          ],
        },
        saveAppMetadata: false,
        deleteMissingLocalCommands: true,
      );

      final after = await appManager.listAppCommands(botId, forceRefresh: true);
      final ids = after.map((c) => c['id']).toList();

      expect(
        ids,
        contains('in_the_version'),
        reason: 'la version restaurée doit être là',
      );
      expect(
        ids,
        isNot(contains('created_after')),
        reason: 'aucune commande créée après la version ne doit survivre',
      );
      final restored = after.firstWhere((c) => c['id'] == 'in_the_version');
      expect(
        restored['name'],
        'in_the_version',
        reason: 'la commande présente dans la version est bien celle restaurée',
      );
    },
  );

  test(
    'syncManagedBotsAfterDiscordLogin fetches R2 config and preserves local commands',
    () async {
      // 1. Setup local command
      await appManager
          .saveAppCommand(botId, 'my_preexisting_cmd', <String, dynamic>{
            'id': 'my_preexisting_cmd',
            'name': 'my_preexisting_cmd',
            'description': 'User preexisting command',
            'type': 'chatInput',
            'data': <String, dynamic>{},
          });

      // 2. Mock HTTP client simulating manager listBots (R2 wrapper) + getBotConfig + R2 download
      final mockHttpClient = MockClient((request) async {
        final uri = request.url;
        if (uri.path == '/gateway/bots') {
          return http.Response(
            jsonEncode({
              'bots': [
                {
                  'bot_id': botId,
                  'bot_name': 'TestBot',
                  'bot_token': 'dummy_token',
                  // config without inlined commands (wrapper only)
                  'config': {'config_url': 'https://r2.test/bot_config.json'},
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (uri.path == '/gateway/bots/$botId/config') {
          return http.Response(
            jsonEncode({'configUrl': 'https://r2.test/bot_config.json'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (uri.host == 'r2.test') {
          return http.Response(
            jsonEncode({
              'commands': [
                {
                  'id': 'cloud_cmd_1',
                  'name': 'cloud_cmd_1',
                  'description': 'Cloud command from R2',
                  'data': {},
                },
              ],
              'workflows': [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (uri.path.contains('/gateway/bots/presign-config')) {
          return http.Response(
            jsonEncode({
              'uploadUrl': 'https://r2.test/upload',
              'configUrl': 'https://r2.test/uploaded_config.json',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else if (uri.path.contains('/gateway/bots/sync') ||
            uri.path.contains('/bots/sync')) {
          return http.Response(jsonEncode({'ok': true}), 200);
        }

        return http.Response('Not Found', 404);
      });

      await http.runWithClient(() async {
        await syncManagedBotsAfterDiscordLogin(
          baseUrl: 'http://test-manager.local',
          accessToken: 'test_access_token',
        );
      }, () => mockHttpClient);

      final commandsAfter = await appManager.listAppCommands(
        botId,
        forceRefresh: true,
      );
      final commandIds = commandsAfter.map((c) => c['id']).toList();

      // Verify both preexisting local command and cloud command exist!
      expect(commandIds, contains('my_preexisting_cmd'));
      expect(commandIds, contains('cloud_cmd_1'));
    },
  );

  test(
    'AppManager exposes isInitialized and currentApps without empty flash',
    () async {
      expect(appManager.isInitialized, isTrue);
      final apps = appManager.currentApps;
      expect(apps, isNotEmpty);
      final found = apps.any((a) => a['id'] == botId);
      expect(found, isTrue);
    },
  );
}
