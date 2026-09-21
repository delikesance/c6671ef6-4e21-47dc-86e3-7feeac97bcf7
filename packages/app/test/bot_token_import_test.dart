// Le jeton d'un bot ne redescend du compte que par une DEMANDE EXPLICITE, jamais par une liste.
//
// Contexte mesuré : sur un poste de travail qui n'avait jamais saisi le jeton, tous les bots
// affichaient « Token invalid or missing », même après un rafraîchissement. Le manager RÉDIGE
// volontairement `bot_token` dans ses listes (`internal/services/bot_gateway.go` :
// `BotToken: "" // Zero plaintext token in summary lists`) : un jeton ne pouvait donc JAMAIS
// revenir, et il restait perdu d'un appareil à l'autre.
//
// La route dédiée `POST /gateway/bots/{id}/token` comble ce trou, avec trois garanties que ce
// test tient par l'exécution et non par la lecture :
//   * chaque cause d'échec a sa PROPRE issue (un 404 de route absente sur un manager plus
//     ancien ne doit jamais être présenté comme une panne de connexion) ;
//   * la reprise automatique est bornée à UNE tentative par bot et par lancement, et ne part
//     jamais sans compte : deux synchros ne peuvent pas produire deux exports ;
//   * le jeton repris est réellement écrit sur le poste, par le chemin d'écriture unique
//     (`createOrUpdateApp`), celui que `app_token_preserved_test.dart` protège déjà.
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_auto_recovery.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'turnkey_bot_invite_test_support.dart'
    show FakeMainApiManager, arbFrText, tr;

/// Jeton FACTICE (jamais un vrai) : la forme suffit à prouver le trajet.
const String _jeton = 'JETON-DE-TEST.abcXYZ.0123456789abcdefghij';
const String _botId = '1350824555119382678';
const String _autreBotId = '1488275294295949504';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Issue de l'export, ou échec explicite si aucun échec n'est levé.
///
/// Pourquoi passer par une exception plutôt qu'un booléen : `fetchBotToken` DOIT lever pour
/// toute cause d'échec ; un `null` retourné silencieusement serait un jeton inventé.
Future<BotTokenExportFailure> _failureOf(FakeMainApiManager manager) async {
  try {
    await manager.client().fetchBotToken(_botId);
  } on BotTokenExportException catch (error) {
    return error.failure;
  }
  fail('un export en échec doit lever BotTokenExportException');
}

/// Bot du compte tel que `GET /gateway/bots` le renvoie : jeton rédigé, donc vide.
Map<String, dynamic> _botDuCompte({
  String botId = _botId,
  bool? tokenInvalid,
}) => <String, dynamic>{
  'bot_id': botId,
  'bot_name': 'Bot-Creator',
  'bot_token': '',
  'token_invalid': ?tokenInvalid,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory racine;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    racine = await Directory.systemTemp.createTemp('bot_token_import_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return racine.path;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await racine.exists()) {
      try {
        await racine.delete(recursive: true);
      } catch (_) {
        // Fichiers encore verrouillés : sans importance pour le test.
      }
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    // La comptabilité des tentatives automatiques vit le temps du processus : sans
    // remise à zéro, le premier test consommerait la tentative des suivants.
    resetBotTokenAutoImportAttempts();
  });

  group('client : chaque cause d\'échec a sa propre issue', () {
    test('200 : le jeton et sa date reviennent, par la route du contrat', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-ok.test',
        body: <String, dynamic>{
          'bot_id': _botId,
          'token': _jeton,
          'validated_at': '2026-09-13T02:13:00Z',
        },
      );

      final export = await manager.client().fetchBotToken(_botId);

      expect(export.botId, _botId);
      expect(export.token, _jeton);
      expect(export.validatedAt?.toUtc().year, 2026);
      expect(
        manager.calls,
        <String>['POST /gateway/bots/$_botId/token'],
        reason: 'l\'export passe par la route dédiée, jamais par une liste',
      );
    });

    test('404 bot_not_found : le bot n\'est pas sur le compte', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-404-code.test',
        statusCode: 404,
        body: <String, dynamic>{'error': 'bot_not_found'},
      );

      expect(await _failureOf(manager), BotTokenExportFailure.botMissing);
    });

    test(
      '404 sans code applicatif (manager plus ancien) : route absente, pas une panne réseau',
      () async {
        final manager = FakeMainApiManager(
          baseUrl: 'https://manager-export-404-route.test',
          statusCode: 404,
          // Le routeur d'un manager qui ne connaît pas encore la route rend sa page
          // « 404 page not found » : aucun code applicatif dans le corps.
          body: const <String, dynamic>{},
        );

        expect(
          await _failureOf(manager),
          BotTokenExportFailure.serverUnsupported,
          reason:
              'confondre ce cas avec une panne réseau ferait dire « vérifie ta connexion » '
              'à l\'utilisateur alors que le serveur est simplement plus ancien',
        );
      },
    );

    test('409 : aucune credential enregistrée pour ce bot', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-409.test',
        statusCode: 409,
        body: <String, dynamic>{'error': 'token_unavailable'},
      );

      expect(await _failureOf(manager), BotTokenExportFailure.notStored);
    });

    test('500 : le serveur n\'arrive pas à relire le jeton', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-500.test',
        statusCode: 500,
        body: <String, dynamic>{'error': 'token_decrypt_failed'},
      );

      expect(await _failureOf(manager), BotTokenExportFailure.serverCannotRead);
    });

    test('503 : cause réessayable, donc panne réseau', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-503.test',
        statusCode: 503,
        body: <String, dynamic>{'error': 'service_unavailable'},
      );

      expect(await _failureOf(manager), BotTokenExportFailure.network);
    });

    test('200 sans jeton : aucun jeton inventé', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-export-vide.test',
        body: <String, dynamic>{'bot_id': _botId, 'token': ''},
      );

      expect(
        await _failureOf(manager),
        BotTokenExportFailure.network,
        reason: 'un corps 200 sans jeton (proxy, page d\'erreur) ne doit rien écrire',
      );
    });
  });

  group('reprise automatique', () {
    test(
      'deux synchros successives ne produisent qu\'un seul export, et le jeton est écrit',
      () async {
        final manager = FakeMainApiManager(
          baseUrl: 'https://manager-reprise-ok.test',
          body: <String, dynamic>{'bot_id': _botId, 'token': _jeton},
        );

        final premier = await recoverMissingBotTokens(
          client: manager.client(),
          accountBots: <Map<String, dynamic>>[_botDuCompte()],
          localTokenOf: (_) => '',
          betweenAttempts: Duration.zero,
        );
        final second = await recoverMissingBotTokens(
          client: manager.client(),
          accountBots: <Map<String, dynamic>>[_botDuCompte()],
          localTokenOf: (_) => '',
          betweenAttempts: Duration.zero,
        );

        expect(premier, <BotTokenImportOutcome>[BotTokenImportOutcome.imported]);
        expect(
          second,
          <BotTokenImportOutcome>[BotTokenImportOutcome.alreadyAttempted],
          reason: 'la garantie de débit tient à la réservation AVANT l\'appel réseau',
        );
        expect(
          manager.requests,
          1,
          reason: 'une synchro répétée ne doit pas multiplier les exports',
        );

        final app = await AppManager().getApp(_botId);
        expect(
          app['token'],
          _jeton,
          reason: 'le jeton repris doit être écrit sur ce poste par le chemin unique',
        );
      },
    );

    test('sans compte : rien ne part, même pas une tentative', () async {
      final outcomes = await recoverMissingBotTokens(
        client: null,
        accountBots: <Map<String, dynamic>>[_botDuCompte()],
        localTokenOf: (_) => '',
        betweenAttempts: Duration.zero,
      );

      expect(outcomes, isEmpty);
    });

    test('un 409 ne se rejoue pas à la synchro suivante', () async {
      final manager = FakeMainApiManager(
        baseUrl: 'https://manager-reprise-409.test',
        statusCode: 409,
        body: <String, dynamic>{'error': 'token_unavailable'},
      );

      final premier = await recoverMissingBotTokens(
        client: manager.client(),
        accountBots: <Map<String, dynamic>>[_botDuCompte()],
        localTokenOf: (_) => '',
        betweenAttempts: Duration.zero,
      );
      final second = await recoverMissingBotTokens(
        client: manager.client(),
        accountBots: <Map<String, dynamic>>[_botDuCompte()],
        localTokenOf: (_) => '',
        betweenAttempts: Duration.zero,
      );

      expect(premier, <BotTokenImportOutcome>[BotTokenImportOutcome.notStored]);
      expect(second, <BotTokenImportOutcome>[BotTokenImportOutcome.alreadyAttempted]);
      expect(
        manager.requests,
        1,
        reason: 'un échec définitif ne se résout pas en réessayant',
      );
    });

    test('un bot déjà pourvu ou annoncé invalide ne déclenche aucune requête', () async {
      final manager = FakeMainApiManager(baseUrl: 'https://manager-reprise-skip.test');

      final outcomes = await recoverMissingBotTokens(
        client: manager.client(),
        accountBots: <Map<String, dynamic>>[
          // (d) le serveur le dit invalide : reprendre une credential morte ne donnerait rien.
          _botDuCompte(tokenInvalid: true),
          // (b) ce poste a déjà un jeton utilisable.
          _botDuCompte(botId: _autreBotId),
        ],
        localTokenOf: (botId) => botId == _autreBotId ? _jeton : '',
        betweenAttempts: Duration.zero,
      );

      expect(
        outcomes,
        <BotTokenImportOutcome>[BotTokenImportOutcome.serverAnnouncesInvalid],
        reason:
            'le bot annoncé invalide est bien EXAMINÉ (il apparaît dans le journal), mais '
            'le bot déjà pourvu ne l\'est même pas — la distinction sert au diagnostic',
      );
      expect(
        manager.requests,
        0,
        reason: 'aucun des deux ne doit produire d\'export',
      );
    });
  });

  group('messages : une phrase par cause, jamais de texte trompeur', () {
    test('chaque issue rend un texte issu de l\'ARB français', () {
      expect(
        botTokenImportMessage(BotTokenImportOutcome.imported, tr),
        arbFrText('bot_token_import_success'),
      );
      expect(
        botTokenImportMessage(BotTokenImportOutcome.botMissing, tr),
        arbFrText('bot_token_import_missing'),
      );
      expect(
        botTokenImportMessage(BotTokenImportOutcome.notStored, tr),
        arbFrText('bot_token_import_not_stored'),
      );
      expect(
        botTokenImportMessage(BotTokenImportOutcome.serverCannotRead, tr),
        arbFrText('bot_token_import_server_cannot_read'),
      );
      expect(
        botTokenImportMessage(BotTokenImportOutcome.serverUnsupported, tr),
        arbFrText('bot_token_import_server_unsupported'),
      );
    });

    test('le cas « route absente » ne parle jamais de connexion', () {
      final unsupported = botTokenImportMessage(
        BotTokenImportOutcome.serverUnsupported,
        tr,
      );
      final reseau = botTokenImportMessage(BotTokenImportOutcome.network, tr);

      expect(unsupported, isNotEmpty);
      expect(
        unsupported,
        isNot(reseau),
        reason: 'deux causes distinctes ne peuvent pas partager la même phrase',
      );
    });
  });
}
