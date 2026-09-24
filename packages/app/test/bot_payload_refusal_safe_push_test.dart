// Preuve du DERNIER maillon côté client : quand la garde anti-config-vide
// REFUSE une poussée, il ne doit en résulter ni perte de données locales, ni
// exception non gérée — mais un message traduit.
//
// Trois propriétés, chacune au niveau où elle se décide :
//   1. le refus se traduit dans les 6 langues (traduction réelle, pas le repli
//      anglais) et n'accapare PAS les erreurs qui ne sont pas des refus ;
//   2. une poussée refusée ne touche à RIEN en local et n'émet AUCUN appel
//      réseau : c'est la règle « ne plus effacer avant de valider » ;
//   3. après un refus, l'édition continue — une charge valide repart.
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _botId = 'refusal-safe-push-bot';

/// Les 6 langues servies par l'application.
const List<String> _locales = <String>['en', 'fr', 'de', 'ja', 'pt', 'tr'];

/// Le profil exact de la charge de 378 octets qui a remplacé une configuration.
Map<String, dynamic> _degeneratePayload() => <String, dynamic>{
  'runtimeEngine': 'javascript',
  'commands': <dynamic>[],
  'events': <dynamic>[],
  'scheduled': <dynamic>[],
  'inboundWebhooks': <dynamic>[],
  'globalVariables': <String, dynamic>{},
};

/// Un client dont la couche HTTP enregistre toute requête émise.
///
/// POURQUOI l'enregistrement compte : la garde doit refuser AVANT le réseau.
/// Une requête enregistrée prouverait que la charge vide est partie quand même.
MainApiClient _client(List<http.Request> sink) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    return http.Response('{}', 200);
  }),
);

/// Appelle [body] et rend l'erreur attrapée — ou `null` si rien n'a levé.
///
/// La capture VOLONTAIRE est le point du test : un refus doit être attrapable
/// par les `catch` des écrans, donc ne jamais partir en exception non gérée.
Future<Object?> _catching(Future<void> Function() body) async {
  try {
    await body();
    return null;
  } catch (error) {
    return error;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp('refusal_safe_push');
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
    await appManager.deleteAppCommands(_botId);
    await appManager.saveApp(_botId, <String, dynamic>{
      'id': _botId,
      'username': 'RefusalBot',
      'token': 'test-token',
      'runtimeEngine': 'javascript',
      'workflows': <Map<String, dynamic>>[],
    });
  });

  group('message localisé', () {
    test('le refus se traduit dans les 6 langues, jamais en repli anglais', () async {
      final messages = <String, String>{};
      for (final code in _locales) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        final message = localizedBotPayloadRefusalMessage(
          l10n,
          const DegenerateBotPayloadException('syncBot'),
        );
        expect(message, isNotNull, reason: 'aucun message en « $code »');
        expect(message!.trim(), isNotEmpty, reason: 'message vide en « $code »');
        expect(message, l10n.bot_payload_refused_local_kept);
        messages[code] = message;
      }
      debugPrint('[PREUVE] messages de refus = $messages');
      // Une traduction RÉELLE n'est pas l'anglais recopié : sinon on serait en
      // repli silencieux, exactement le défaut que le garde-fou i18n traque.
      expect(messages['fr'], isNot(messages['en']));
      expect(messages['de'], isNot(messages['en']));
      expect(messages['ja'], isNot(messages['en']));
    });

    test("une erreur qui n'est pas un refus garde le message d'erreur habituel", () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(isBotPayloadRefusal(Exception('reseau')), isFalse);
      expect(
        localizedBotPayloadRefusalMessage(l10n, Exception('reseau')),
        isNull,
        reason: "un échec réseau ne doit pas être présenté comme un refus",
      );
      expect(
        isBotPayloadRefusal(const DegenerateBotPayloadException('syncBot')),
        isTrue,
      );
    });
  });

  group('poussée refusée : local intact, message au lieu d\'une exception', () {
    Future<void> seedKeptCommand() => appManager.saveAppCommand(
      _botId,
      'cmd-keep',
      <String, dynamic>{
        'id': 'cmd-keep',
        'name': 'ping',
        'type': 'chatInput',
        'data': <String, dynamic>{
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("pong");',
        },
      },
    );

    test('syncBot refuse sans rien effacer et sans appel réseau', () async {
      await seedKeptCommand();

      final appBefore = await appManager.getApp(_botId);
      final commandsBefore = await appManager.listAppCommands(_botId);
      expect(commandsBefore.map((command) => command['id']).toList(), <String>[
        'cmd-keep',
      ]);

      final requests = <http.Request>[];
      final failure = await _catching(
        () => _client(
          requests,
        ).syncBot(_botId, 'RefusalBot', _degeneratePayload()),
      );

      // 1. Le refus est typé et ATTRAPABLE : jamais d'exception non gérée.
      expect(failure, isA<DegenerateBotPayloadException>());
      // 2. Aucune charge n'a atteint le réseau.
      expect(
        requests,
        isEmpty,
        reason: 'une charge vide ne doit pas partir, même par le repli re-POST',
      );
      // 3. L'écran disposera d'un message traduit pour ce refus.
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(localizedBotPayloadRefusalMessage(l10n, failure!), isNotNull);

      // 4. LE point de la règle « ne plus effacer avant de valider » : la
      //    donnée locale est intacte, à l'entrée près.
      final appAfter = await appManager.getApp(_botId);
      final commandsAfter = await appManager.listAppCommands(_botId);
      debugPrint('[PREUVE] app AVANT=$appBefore');
      debugPrint('[PREUVE] app APRÈS=$appAfter');
      debugPrint(
        '[PREUVE] commandes AVANT=${commandsBefore.map((c) => c['id']).toList()} '
        'APRÈS=${commandsAfter.map((c) => c['id']).toList()}',
      );
      expect(appAfter, appBefore);
      expect(commandsAfter.map((command) => command['id']).toList(), <String>[
        'cmd-keep',
      ]);
    });

    test('saveDiscordBotSnapshot refuse de même, sans rien effacer', () async {
      await seedKeptCommand();

      final appBefore = await appManager.getApp(_botId);
      final commandsBefore = await appManager.listAppCommands(_botId);

      final requests = <http.Request>[];
      final failure = await _catching(
        () => _client(requests).saveDiscordBotSnapshot(
          botId: _botId,
          botToken: 'test-token',
          config: _degeneratePayload(),
        ),
      );

      expect(failure, isA<DegenerateBotPayloadException>());
      expect(requests, isEmpty);
      expect(
        (failure! as DegenerateBotPayloadException).source,
        'saveDiscordBotSnapshot',
      );

      expect(await appManager.getApp(_botId), appBefore);
      expect(
        (await appManager.listAppCommands(_botId)).map((c) => c['id']).toList(),
        commandsBefore.map((c) => c['id']).toList(),
      );
    });

    test("après un refus, l'édition continue : une charge valide se pousse", () async {
      final requests = <http.Request>[];
      final client = _client(requests);

      final refused = await _catching(
        () => client.syncBot(_botId, 'RefusalBot', _degeneratePayload()),
      );
      expect(refused, isA<DegenerateBotPayloadException>());
      expect(requests, isEmpty);

      // L'utilisateur complète sa configuration : la commande qui manquait.
      await seedKeptCommand();

      await client.syncBot(_botId, 'RefusalBot', <String, dynamic>{
        'runtimeEngine': 'javascript',
        'commands': <dynamic>[
          <String, dynamic>{'name': 'ping', 'script': 'reply();'},
        ],
        'events': <dynamic>[],
      });

      debugPrint(
        '[PREUVE] chemins poussés après édition = '
        '${requests.map((request) => request.url.path).toList()}',
      );
      expect(
        requests,
        isNotEmpty,
        reason: 'une charge valide doit repartir normalement après un refus',
      );
    });
  });
}
