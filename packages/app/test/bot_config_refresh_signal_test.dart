import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_refresh.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Le remplacement de la copie locale d'un bot (restauration de version, synchro
/// entrante) doit AVERTIR les écrans qui affichent cette copie. Sans ce signal,
/// la liste des commandes gardait l'état d'avant l'opération : une restauration
/// ne s'y voyait pas, alors que le stockage était déjà à jour.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late AppManager appManager;
  const botId = '111222333444555666';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp('bot_config_refresh');
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
    });
    for (final cmd in await appManager.listAppCommands(
      botId,
      forceRefresh: true,
    )) {
      final cmdId = (cmd['id'] ?? '').toString();
      if (cmdId.isNotEmpty) {
        await appManager.deleteAppCommand(botId, cmdId);
      }
    }
  });

  test(
    'le remplacement de la config locale prévient les abonnés, APRÈS écriture',
    () async {
      var notifications = 0;
      String? notifiedBot;
      bool? syncingWhenNotified;
      void listener() {
        notifications++;
        notifiedBot = BotConfigRefreshNotifier.instance.botId;
        // Au moment où l'écran est prévenu, la synchro doit être TERMINÉE : un
        // écran qui relit le stockage pendant l'application verrait un état à
        // moitié écrit.
        syncingWhenNotified = AppManager.isSyncingFromRemote;
      }

      BotConfigRefreshNotifier.instance.addListener(listener);
      addTearDown(
        () => BotConfigRefreshNotifier.instance.removeListener(listener),
      );

      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: <String, dynamic>{
          'commands': <Map<String, dynamic>>[
            {'id': 'cmd_1', 'name': 'cmd_1', 'data': <String, dynamic>{}},
          ],
        },
        saveAppMetadata: false,
      );

      expect(notifications, 1);
      expect(notifiedBot, botId);
      expect(syncingWhenNotified, isFalse);
    },
  );

  test(
    'un écran qui se recharge sur le signal voit l\'état REMPLACÉ',
    () async {
      List<String> idsSeenByListener = <String>[];
      final relecture = Completer<void>();

      void listener() {
        // C'est exactement ce que fait la liste des commandes : relire.
        appManager.listAppCommands(botId, forceRefresh: true).then((cmds) {
          idsSeenByListener = cmds
              .map((c) => (c['id'] ?? '').toString())
              .toList();
          if (!relecture.isCompleted) relecture.complete();
        });
      }

      BotConfigRefreshNotifier.instance.addListener(listener);
      addTearDown(
        () => BotConfigRefreshNotifier.instance.removeListener(listener),
      );

      await appManager.saveAppCommand(botId, 'created_after', <String, dynamic>{
        'id': 'created_after',
        'name': 'created_after',
        'type': 'chatInput',
        'data': <String, dynamic>{},
      });

      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: <String, dynamic>{
          'commands': <Map<String, dynamic>>[
            {
              'id': 'in_the_version',
              'name': 'in_the_version',
              'data': <String, dynamic>{},
            },
          ],
        },
        saveAppMetadata: false,
        deleteMissingLocalCommands: true,
      );
      // Laisse le listener asynchrone terminer sa relecture : on attend SA
      // relecture, pas un délai arbitraire.
      await relecture.future.timeout(const Duration(seconds: 10));

      expect(idsSeenByListener, contains('in_the_version'));
      expect(idsSeenByListener, isNot(contains('created_after')));
    },
  );

  test('deux remplacements successifs du même bot sont distinguables', () async {
    final revisions = <int>[];
    void listener() =>
        revisions.add(BotConfigRefreshNotifier.instance.revision);

    BotConfigRefreshNotifier.instance.addListener(listener);
    addTearDown(
      () => BotConfigRefreshNotifier.instance.removeListener(listener),
    );

    for (final id in <String>['cmd_a', 'cmd_b']) {
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: <String, dynamic>{
          'commands': <Map<String, dynamic>>[
            {'id': id, 'name': id, 'data': <String, dynamic>{}},
          ],
        },
        saveAppMetadata: false,
      );
    }

    expect(revisions.length, 2);
    expect(
      revisions[1],
      greaterThan(revisions[0]),
      reason:
          'un simple botId identique ne réveillerait pas un écran déjà à jour',
    );
  });
}
