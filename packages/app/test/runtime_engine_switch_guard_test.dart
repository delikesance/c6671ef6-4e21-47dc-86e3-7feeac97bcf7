// L'ordre de `switchBotRuntimeEngine`, prouvé par le seul cas qui compte :
// une bascule dont la charge cible serait vide doit être REFUSÉE **avant** tout
// effacement, et les commandes locales doivent survivre.
//
// Si l'ordre destructeur revient (effacer puis valider), ce fichier échoue en
// montrant les commandes disparues : c'est la mutation rejouée en preuve de
// non-vacuité.
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _refusedBotId = 'switch-refused-bot';
const String _doneBotId = 'switch-done-bot';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp('switch_guard_test');
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
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    for (final botId in <String>[_refusedBotId, _doneBotId]) {
      await appManager.deleteAppCommands(botId);
      // Aucune variable, aucun webhook, aucun déclencheur : un bot au moteur
      // dart dont AUCUNE automatisation ne survit au moteur JS.
      await appManager.saveApp(botId, <String, dynamic>{
        'id': botId,
        'username': 'SwitchBot',
        'token': 'test-token',
        'runtimeEngine': runtimeEngineDart,
        'workflows': <Map<String, dynamic>>[],
      });
    }
  });

  test(
    'bascule refusée quand la charge cible serait vide : commandes intactes',
    () async {
      await appManager.saveAppCommand(_refusedBotId, 'cmd-keep', {
        'id': 'cmd-keep',
        'name': 'ping',
        'description': 'Ping',
        'type': 'chatInput',
        // Ni script JS ni action convertissable : cette commande disparaîtrait
        // de la charge utile JS.
        'data': <String, dynamic>{},
      });

      final before = await appManager.listAppCommands(_refusedBotId);
      debugPrint(
        '[PREUVE] commandes AVANT bascule = '
        '${before.map((command) => command['id']).toList()}',
      );

      Object? failure;
      try {
        await switchBotRuntimeEngine(
          _refusedBotId,
          runtimeEngineJavascript,
          supportsManagerRuntime: false,
        );
      } catch (error) {
        failure = error;
      }

      final after = await appManager.listAppCommands(_refusedBotId);
      debugPrint('[PREUVE] échec de la bascule = $failure');
      debugPrint(
        '[PREUVE] commandes APRÈS bascule refusée = '
        '${after.map((command) => command['id']).toList()}',
      );

      // LE point du correctif : la bascule a échoué AVANT tout effacement.
      expect(after.map((command) => command['id']).toList(), <String>[
        'cmd-keep',
      ]);
      expect(await getBotRuntimeEngine(_refusedBotId), runtimeEngineDart);
      expect(failure, isA<DegenerateBotPayloadException>());
    },
  );

  test(
    'bascule validée : moteur changé, et une reconstruction tardive serait vide',
    () async {
      await appManager.saveAppCommand(_doneBotId, 'cmd-js', {
        'id': 'cmd-js',
        'name': 'ping',
        'type': 'chatInput',
        'data': <String, dynamic>{
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("pong");',
        },
      });

      await switchBotRuntimeEngine(
        _doneBotId,
        runtimeEngineJavascript,
        supportsManagerRuntime: false,
      );

      expect(
        await getBotRuntimeEngine(_doneBotId),
        runtimeEngineJavascript,
      );

      // POURQUOI cette vérification : après l'effacement local, reconstruire la
      // charge donnerait une charge VIDE. C'est donc bien la charge validée
      // avant l'effacement qui doit être poussée — sinon la configuration du
      // bot serait écrasée par ces 378 octets.
      Object? rebuild;
      try {
        await buildJsBotPayload(_doneBotId);
      } catch (error) {
        rebuild = error;
      }
      debugPrint('[PREUVE] reconstruction après effacement = $rebuild');
      expect(rebuild, isA<DegenerateBotPayloadException>());

      // Contrat annoncé par le dialogue de confirmation : les données locales
      // du moteur quitté sont remises à zéro.
      expect(await appManager.listAppCommands(_doneBotId), isEmpty);
    },
  );
}
