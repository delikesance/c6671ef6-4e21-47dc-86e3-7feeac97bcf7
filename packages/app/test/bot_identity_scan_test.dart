// Un bot HÉBERGÉ n'a AUCUN jeton sur ce poste : sans le redemander, son identité ne peut pas
// être demandée à Discord et son nom reste l'ID à l'écran. Défaut constaté par le
// propriétaire : après `7df792c0`, le nom n'avait toujours pas changé à l'écran. La cause
// tenait au balayage, qui exigeait un jeton DÉJÀ présent dans la fiche locale — or un bot
// hébergé n'en a aucun : le manager RÉDIGE `bot_token` dans ses listes (« Zero plaintext
// token in summary lists ») et le jeton vit chiffré côté compte. Le balayage vit désormais
// dans `bot_identity_scan.dart` : ce fichier-là est son test.
//
// Ce que ce fichier tient par l'EXÉCUTION, sans aucun transport réel (client HTTP et faux
// compte injectés) :
//   * le jeton est redemandé à la SEULE route qui le rend
//     (`POST /gateway/bots/{id}/token`), PUIS c'est CE jeton qui interroge Discord, et le nom
//     réel est écrit par le chemin d'écriture unique ;
//   * une seule tentative : un rejeu du balayage dans le même lancement ne produit ni second
//     export ni seconde requête à Discord ;
//   * quand la reprise échoue (404), rien n'est écrit, aucune exception ne remonte, la
//     synchro des autres bots se poursuit, et le symptôme reste visible mais honnête ;
//   * sans compte (hors ligne), rien ne part : Discord n'est jamais interrogé sans jeton.
// Aucun jeton n'est journalisé : sa VALEUR DE TEST ne sert qu'à comparer ce que le faux Discord reçoit.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_scan.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_sync.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nyxx/nyxx.dart' show Snowflake;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'turnkey_bot_invite_test_support.dart' show FakeMainApiManager;

/// Bots HÉBERGÉS : nom = ID et aucun jeton sur ce poste. Un identifiant DÉDIÉ par cas, jamais
/// réutilisé d'un cas à l'autre : le coffre chiffré vit dans le même processus pour tout le
/// fichier et garderait sinon le jeton écrit par un cas précédent.
const String _botHebergeId = '1092544379810381825';
const String _botHebergeEchecId = '1100648619452727317';
const String _botHebergeSansCompteId = '1118762034973005824';

/// Bot qui a, lui, un jeton local : la synchro d'identité fonctionnait déjà pour celui-là.
const String _botAvecJetonId = '1488275294295949504';

/// Jeton FACTICE (jamais un vrai) déjà présent sur le poste.
const String _jetonLocal = 'JETON-LOCAL-DE-TEST.abcXYZ.0123456789abcdefghij';

/// Jeton FACTICE rendu par le compte, DIFFÉRENT du local : prouve que l'appel à Discord est
/// parti avec le jeton REPRIS, et non avec un autre.
const String _jetonRepris = 'JETON-REPRIS-DE-TEST.qrsTUV.ZYXWVUTSRQPONMLKJIHG';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Faux Discord : compte les requêtes et garde la dernière pour l'inspecter.
class _FauxDiscord {
  _FauxDiscord({required this.statusCode, required this.body});

  final int statusCode;
  final Map<String, dynamic> body;

  final List<http.Request> requests = <http.Request>[];

  int get count => requests.length;
  Map<String, String> get lastHeaders => requests.last.headers;

  http.Client client() => MockClient((request) async {
    requests.add(request);
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
}

/// Corps de `GET /users/@me` pour un bot qui a enfin un nom.
Map<String, dynamic> _identite({required String id, String username = 'JeanMichel'}) =>
    <String, dynamic>{
      'id': id,
      'username': username,
      'avatar': 'a1b2c3',
      'discriminator': '0',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory racine;
  // Créé APRÈS l'installation du faux `path_provider` : `AppManager` lit son dossier de
  // stockage dès la construction, donc avant le faux canal il échouerait au chargement.
  late AppManager manager;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    racine = await Directory.systemTemp.createTemp('bot_identity_scan_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return racine.path;
        });
    manager = AppManager();
    await manager.getAllApps();
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
    // Les DEUX comptabilités vivent le temps du processus : sans remise à zéro, le premier
    // cas consommerait la tentative des suivants — celle de l'identité ET celle du jeton.
    resetBotIdentityFetchAttempts();
    resetBotTokenAutoImportAttempts();
    final appsDir = Directory('${racine.path}/apps');
    if (appsDir.existsSync()) appsDir.deleteSync(recursive: true);
  });

  /// Fiche locale telle que la synchro la laisse pour un bot hébergé : nom = ID, sans jeton.
  Future<void> poserFiche({
    required String botId,
    String? nom,
    String token = _jetonLocal,
  }) => manager.createOrUpdateApp(
    id: Snowflake.parse(botId),
    username: nom ?? botId,
    token: token,
  );

  /// Le nom tel qu'il est ÉCRIT sur ce poste — la seule preuve qui compte.
  Future<String> nomEcri(String botId) async =>
      (await manager.getApp(botId))['name'].toString();

  /// Le jeton tel qu'il est ÉCRIT sur ce poste (vide quand il n'y en a aucun).
  Future<String> jetonEcri(String botId) async =>
      ((await manager.getApp(botId))['token'] ?? '').toString().trim();

  /// Balayage de synchro, tel que `syncAllBotsFromManager` l'appelle : avec le client du
  /// COMPTE, celui qui sait reprendre le jeton d'un bot hébergé.
  Future<List<BotIdentitySyncOutcome>> balayer(
    _FauxDiscord discord,
    List<String> botIds, {
    MainApiClient? client,
  }) => refreshBotIdentitiesFromDiscord(
    // Charge utile du compte pour ces bots : `bot_token` rédigé (vide), comme dans ses listes.
    accountBots: <Map<String, dynamic>>[
      for (final id in botIds) <String, dynamic>{'bot_id': id, 'bot_token': ''},
    ],
    localAppOf: (id) => manager.getApp(id),
    client: client,
    httpClient: discord.client(),
    betweenAttempts: Duration.zero,
  );

  group('bot hébergé : le jeton est repris pour pouvoir demander son nom', () {
    test('le jeton de la route dédiée sert à Discord, en UNE tentative', () async {
      final discord = _FauxDiscord(
        statusCode: 200,
        body: _identite(id: _botHebergeId),
      );
      final compte = FakeMainApiManager(
        baseUrl: 'https://manager-identite-heberge.test',
        body: <String, dynamic>{'bot_id': _botHebergeId, 'token': _jetonRepris},
      );
      await poserFiche(botId: _botHebergeId, token: '');
      // PRÉMISSE du défaut : ce poste n'a aucun jeton local pour ce bot.
      expect(await jetonEcri(_botHebergeId), isEmpty);

      final outcomes = await balayer(
        discord,
        <String>[_botHebergeId],
        client: compte.client(),
      );

      expect(outcomes, <BotIdentitySyncOutcome>[BotIdentitySyncOutcome.updated]);
      expect(
        compte.calls,
        <String>['POST /gateway/bots/$_botHebergeId/token'],
        reason: 'le jeton est redemandé à la route dédiée, et à elle seule',
      );
      expect(compte.requests, 1, reason: 'une tentative, jamais une rafale');
      expect(discord.count, 1, reason: 'une requête d\'identité, une seule');
      expect(
        discord.lastHeaders['Authorization'],
        'Bot $_jetonRepris',
        reason: 'c\'est le jeton REPRIS auprès du compte qui interroge Discord',
      );
      expect(await nomEcri(_botHebergeId), 'JeanMichel');
      expect(
        await jetonEcri(_botHebergeId),
        _jetonRepris,
        reason: 'le jeton repris reste sur ce poste : l\'app peut exécuter ce bot',
      );

      // Rejeu immédiat : le nom réparé ne déclenche plus rien du tout.
      final rejeu = await balayer(
        discord,
        <String>[_botHebergeId],
        client: compte.client(),
      );
      expect(rejeu, isEmpty);
      expect(
        compte.requests,
        1,
        reason: 'aucun second export du même jeton dans le même lancement',
      );
      expect(discord.count, 1, reason: 'aucune seconde requête à Discord');
    });

    test(
      'reprise en échec (404) : rien n\'est écrit, la synchro se poursuit, un seul essai',
      () async {
        final discord = _FauxDiscord(
          statusCode: 200,
          body: _identite(id: _botAvecJetonId),
        );
        final compte = FakeMainApiManager(
          baseUrl: 'https://manager-identite-heberge-404.test',
          statusCode: 404,
          body: <String, dynamic>{'error': 'bot_not_found'},
        );
        await poserFiche(botId: _botHebergeEchecId, token: '');
        await poserFiche(botId: _botAvecJetonId);
        final compteClient = compte.client();

        final premier = await balayer(
          discord,
          <String>[_botHebergeEchecId, _botAvecJetonId],
          client: compteClient,
        );
        final second = await balayer(
          discord,
          <String>[_botHebergeEchecId, _botAvecJetonId],
          client: compteClient,
        );

        expect(
          premier,
          <BotIdentitySyncOutcome>[
            BotIdentitySyncOutcome.noToken,
            BotIdentitySyncOutcome.updated,
          ],
          reason:
              'le bot hébergé n\'a pas pu être interrogé (aucun jeton), et la synchro '
              'a bien continué jusqu\'à l\'autre bot : aucune exception ne remonte',
        );
        expect(
          second,
          <BotIdentitySyncOutcome>[BotIdentitySyncOutcome.noToken],
          reason:
              'au rejeu, le bot réparé n\'a plus rien à faire ; le bot hébergé, lui, est '
              'retenté sans nouvel export : un 404 définitif ne se rejoue pas',
        );
        expect(compte.requests, 1, reason: 'aucune rafale d\'exports');
        expect(discord.count, 1, reason: 'le bot hébergé n\'a jamais atteint Discord');
        expect(
          await nomEcri(_botHebergeEchecId),
          _botHebergeEchecId,
          reason: 'aucun nom inventé : le symptôme reste, et la prochaine session retentera',
        );
        expect(await nomEcri(_botAvecJetonId), 'JeanMichel');
      },
    );

    test('sans compte (hors ligne) : rien ne part, rien n\'est écrit', () async {
      final discord = _FauxDiscord(
        statusCode: 200,
        body: _identite(id: _botHebergeSansCompteId),
      );
      await poserFiche(botId: _botHebergeSansCompteId, token: '');

      final outcomes = await balayer(discord, <String>[_botHebergeSansCompteId]);

      expect(
        outcomes,
        isEmpty,
        reason: 'sans compte, le comportement reste celui d\'avant : aucune tentative',
      );
      expect(
        discord.count,
        0,
        reason: 'sans jeton, Discord ne doit jamais être interrogé',
      );
      expect(await nomEcri(_botHebergeSansCompteId), _botHebergeSansCompteId);
    });
  });
}
