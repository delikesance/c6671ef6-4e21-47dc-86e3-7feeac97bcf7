// Preuve de la garde anti-charge-utile-vide.
//
// Trois propriétés, chacune au niveau où elle est indispensable :
//   1. la garde partagée reconnaît le profil de l'incident (commands/events
//      vides) et épargne les poussées de métadonnées ;
//   2. `buildJsBotPayload` REFUSE de rendre une charge vide : une erreur typée,
//      jamais un retour vide silencieux ;
//   3. le client réseau refuse AVANT tout appel — y compris avant le repli
//      « re-POST direct » — et pousse normalement une charge valide.
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Charge dégénérée typique : c'est le profil exact de la poussée de 378 octets
/// qui a remplacé la configuration d'un bot.
Map<String, dynamic> degeneratePayload() => <String, dynamic>{
  'runtimeEngine': runtimeEngineJavascript,
  'commands': <dynamic>[],
  'events': <dynamic>[],
  'scheduled': <dynamic>[],
  'inboundWebhooks': <dynamic>[],
  'globalVariables': <String, dynamic>{},
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  const botId = 'payload-guard-bot';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp('payload_guard_test');
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
    // État neutre à chaque test : aucune commande, aucun workflow, aucune
    // variable — donc, pour le moteur JS, une charge utile VIDE.
    await appManager.deleteAppCommands(botId);
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'username': 'GuardBot',
      'token': 'test-token',
      'runtimeEngine': runtimeEngineJavascript,
      'workflows': <Map<String, dynamic>>[],
    });
  });

  group('garde partagée', () {
    test('le profil de l\'incident est reconnu comme dégénéré', () {
      final payload = degeneratePayload();
      expect(isDegenerateBotPayload(payload), isTrue);
      debugPrint('[PREUVE] charge jugée dégénérée = $payload');
    });

    test('une seule famille remplie suffit à sauver la charge', () {
      expect(
        isDegenerateBotPayload(<String, dynamic>{
          'commands': <dynamic>[],
          'events': <dynamic>[],
          'globalVariables': <String, dynamic>{'a': 1},
        }),
        isFalse,
      );
      expect(
        isDegenerateBotPayload(<String, dynamic>{
          'commands': <dynamic>[
            <String, dynamic>{'name': 'ping'},
          ],
        }),
        isFalse,
      );
      expect(
        isDegenerateBotPayload(<String, dynamic>{
          'scheduledTriggers': <dynamic>[
            <String, dynamic>{'everyMinutes': 5},
          ],
        }),
        isFalse,
      );
      expect(
        isDegenerateBotPayload(<String, dynamic>{
          'inboundWebhookEndpoints': <dynamic>[
            <String, dynamic>{'path': '/hook'},
          ],
        }),
        isFalse,
      );
    });

    test('une poussée de métadonnées n\'est pas jugée', () {
      // Les poussées de jeton/pseudo transportent la fiche locale de l'app :
      // elles n'annoncent AUCUNE famille d'automatisation.
      expect(isDegenerateBotPayload(const <String, dynamic>{}), isFalse);
      expect(
        isDegenerateBotPayload(<String, dynamic>{
          'token': 'x',
          'username': 'y',
        }),
        isFalse,
      );
    });

    test('le refus est typé et porte un message lisible', () {
      Object? failure;
      try {
        assertNonDegenerateBotPayload(<String, dynamic>{
          'commands': <dynamic>[],
        }, source: 'test');
      } catch (error) {
        failure = error;
      }
      debugPrint('[PREUVE] refus brut = $failure');
      expect(failure, isA<DegenerateBotPayloadException>());
      expect(failure.toString(), contains('test'));
      expect(failure.toString(), contains('no command'));
    });
  });

  group('buildJsBotPayload', () {
    test('REFUSE de rendre une charge vide au lieu de la rendre', () async {
      await appManager.saveAppCommand(botId, 'cmd-without-script', {
        'id': 'cmd-without-script',
        'name': 'ping',
        'type': 'chatInput',
        'data': <String, dynamic>{},
      });

      Map<String, dynamic>? rendered;
      Object? failure;
      try {
        rendered = await buildJsBotPayload(botId);
      } catch (error) {
        failure = error;
      }

      debugPrint(
        '[PREUVE] charge rendue = $rendered / échec = $failure',
      );
      expect(rendered, isNull, reason: 'jamais de vide silencieux');
      expect(failure, isA<DegenerateBotPayloadException>());
      expect(
        (failure! as DegenerateBotPayloadException).source,
        'buildJsBotPayload',
      );
    });

    test('rend la charge complète quand elle porte des automatisations', () async {
      await appManager.saveAppCommand(botId, 'cmd-js', {
        'id': 'cmd-js',
        'name': 'ping',
        'type': 'chatInput',
        'data': <String, dynamic>{
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("pong");',
        },
      });

      final payload = await buildJsBotPayload(botId);
      debugPrint(
        '[PREUVE] commands=${payload['commands']} events=${payload['events']}',
      );
      expect(payload['commands'], hasLength(1));
      expect(isDegenerateBotPayload(payload), isFalse);
    });
  });

  group('garde centrale du client', () {
    test('syncBot refuse une charge dégénérée sans aucun appel réseau', () async {
      final requests = <http.Request>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );

      Object? failure;
      try {
        await client.syncBot('bot-1', 'Bot', degeneratePayload());
      } catch (error) {
        failure = error;
      }

      debugPrint(
        '[PREUVE] syncBot dégénéré : échec = $failure / '
        'requêtes émises = ${requests.length}',
      );
      expect(failure, isA<DegenerateBotPayloadException>());
      expect(
        requests,
        isEmpty,
        reason: 'aucune charge vide ne doit atteindre le réseau, '
            'ni directement ni par le repli re-POST',
      );
    });

    test(
      'saveDiscordBotSnapshot refuse une charge dégénérée sans appel réseau',
      () async {
        final requests = <http.Request>[];
        final client = MainApiClient(
          baseUrl: 'https://api.example.com',
          accessToken: 'token',
          httpClient: MockClient((request) async {
            requests.add(request);
            return http.Response('{}', 200);
          }),
        );

        Object? failure;
        try {
          await client.saveDiscordBotSnapshot(
            botId: 'bot-1',
            botToken: 'bot-token',
            config: degeneratePayload(),
          );
        } catch (error) {
          failure = error;
        }

        debugPrint(
          '[PREUVE] snapshot dégénéré : échec = $failure / '
          'requêtes émises = ${requests.length}',
        );
        expect(failure, isA<DegenerateBotPayloadException>());
        expect(requests, isEmpty);
      },
    );

    test('syncBot pousse normalement une charge valide', () async {
      final requests = <http.Request>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );

      await client.syncBot('bot-1', 'Bot', <String, dynamic>{
        'runtimeEngine': runtimeEngineJavascript,
        'commands': <dynamic>[
          <String, dynamic>{'name': 'ping', 'script': 'reply();'},
        ],
        'events': <dynamic>[],
      });

      final paths = requests.map((request) => request.url.path).toList();
      final bodies = requests
          .map((request) => request.body)
          .join('\n---\n');
      debugPrint('[PREUVE] chemins appelés = $paths');
      debugPrint('[PREUVE] charges transmises = $bodies');
      expect(paths, contains('/gateway/bots/sync'));
      // La charge part par l'URL présignée (ou, en repli, dans le corps direct) :
      // on cherche donc le contenu, pas un chemin particulier.
      expect(bodies, contains('"commands"'));
      expect(bodies, contains('ping'));
    });
  });
}
