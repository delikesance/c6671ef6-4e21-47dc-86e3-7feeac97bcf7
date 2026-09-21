// Un nom qui vaut l'ID n'est PAS un nom : l'app doit le demander à Discord.
//
// Défaut constaté : un bot s'affiche sous son ID (`1488275294295949504`) sur sa carte et en
// tête de sa page — et le manager stocke ce même ID comme `bot_name`, donc personne n'avait
// jamais interrogé Discord. Tout est tenu par l'EXÉCUTION, sans aucun transport réel (client
// HTTP injecté) : un non-nom déclenche `GET /users/@me` et le nom réel est écrit par le chemin
// d'écriture unique ; un nom qui est un nom ne produit AUCUNE requête ; un refus, une panne ou
// l'identité d'un autre bot n'écrit rien et ne remonte pas à l'écran ; deux déclenchements dans
// un même lancement ne font qu'une requête.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_scan.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_sync.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nyxx/nyxx.dart' show Snowflake;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _botId = '1488275294295949504';
const String _autreBotId = '1350824555119382678';

/// Identifiant que ce fichier ne dote JAMAIS d'un jeton : sert au cas « sans jeton ».
const String _botSansJetonId = '1172019421583621324';

/// Jeton FACTICE (jamais un vrai) : la forme suffit à prouver le trajet.
const String _jeton = 'JETON-DE-TEST.abcXYZ.0123456789abcdefghij';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Faux Discord : compte les requêtes et garde la dernière pour l'inspecter.
class _FauxDiscord {
  _FauxDiscord({required this.statusCode, this.body = const {}, this.horsLigne});

  final int statusCode;
  final Map<String, dynamic> body;

  /// Simule une panne réseau : aucune réponse n'arrive (jamais un vrai socket).
  final bool? horsLigne;

  final List<http.Request> requests = <http.Request>[];

  int get count => requests.length;
  Map<String, String> get lastHeaders => requests.last.headers;
  String get lastPath => requests.last.url.path;

  http.Client client() => MockClient((request) async {
    requests.add(request);
    if (horsLigne == true) throw const SocketException('hors ligne (test)');
    return http.Response(
      jsonEncode(body),
      statusCode,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
}

/// Corps de `GET /users/@me` pour un bot qui a enfin un nom.
Map<String, dynamic> _identite({
  String id = _botId,
  String username = 'Bot-Creator',
  String avatar = 'a1b2c3',
}) => <String, dynamic>{
  'id': id,
  'username': username,
  'avatar': avatar,
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
    racine = await Directory.systemTemp.createTemp('bot_identity_sync_test_');
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
    // La comptabilité vit le temps du processus : sans remise à zéro, le premier test
    // consommerait la tentative des suivants. Les fiches sont retirées pour la même raison :
    // un nom déjà réparé ferait passer le test suivant pour rien.
    resetBotIdentityFetchAttempts();
    final appsDir = Directory('${racine.path}/apps');
    if (appsDir.existsSync()) appsDir.deleteSync(recursive: true);
  });

  /// Fiche locale telle que la synchro la laisse : c'est l'état de départ du symptôme.
  Future<void> poserFiche({
    String botId = _botId,
    String? nom,
    String token = _jeton,
  }) => manager.createOrUpdateApp(
    id: Snowflake.parse(botId),
    username: nom ?? botId,
    token: token,
  );

  /// Le nom tel qu'il est ÉCRIT sur ce poste — la seule preuve qui compte.
  Future<String> nomEcri([String botId = _botId]) async =>
      (await manager.getApp(botId))['name'].toString();

  Future<BotIdentitySyncOutcome> rafraichir(_FauxDiscord discord) =>
      refreshBotIdentityFromDiscord(
        botId: _botId,
        httpClient: discord.client(),
      );

  /// Balayage de synchro, tel que `syncAllBotsFromManager` l'appelle.
  Future<List<BotIdentitySyncOutcome>> balayer(
    _FauxDiscord discord,
    List<String> botIds,
  ) => refreshBotIdentitiesFromDiscord(
    accountBots: <Map<String, dynamic>>[
      for (final id in botIds) <String, dynamic>{'bot_id': id},
    ],
    localAppOf: (id) => manager.getApp(id),
    httpClient: discord.client(),
    betweenAttempts: Duration.zero,
  );

  group('nom qui vaut l\'ID : Discord est interrogé, puis le nom est écrit', () {
    test('GET /users/@me avec le jeton du bot, et le nom réel remplace l\'ID',
        () async {
      final discord = _FauxDiscord(
        statusCode: 200,
        body: _identite(username: 'JeanMichel'),
      );
      await poserFiche();

      final outcome = await rafraichir(discord);
      final app = await manager.getApp(_botId);

      expect(outcome, BotIdentitySyncOutcome.updated);
      expect(discord.count, 1, reason: 'le nom vient de Discord, pas d\'une invention');
      expect(discord.lastPath, '/api/v10/users/@me');
      expect(
        discord.lastHeaders['Authorization'],
        'Bot $_jeton',
        reason: 'c\'est le jeton du bot qui a ce droit, et lui seul',
      );
      expect(
        app['name'],
        'JeanMichel',
        reason: 'le nom doit être écrit par le chemin d\'écriture unique',
      );
      expect(
        app['token'],
        _jeton,
        reason: 'la récupération ne touche pas au jeton déjà présent',
      );
      expect(app['avatar'].toString(), contains('a1b2c3'));
    });

    test('nom vide réparé par le balayage, un seul essai s\'il est listé deux fois',
        () async {
      final discord = _FauxDiscord(
        statusCode: 200,
        body: _identite(username: 'JeanMichel'),
      );
      await poserFiche(nom: '   ');

      // `_botSansJetonId` n'a aucun jeton : il est ignoré AVANT tout appel, sans rien
      // consommer — et le même bot listé deux fois n'est tenté qu'une fois.
      final outcomes = await balayer(discord, <String>[
        _botId,
        _botId,
        _botSansJetonId,
      ]);

      expect(
        outcomes,
        <BotIdentitySyncOutcome>[BotIdentitySyncOutcome.updated],
        reason:
            'après la réparation, les passages suivants n\'ont plus rien à faire : ni le '
            'même bot relu, ni un bot sans jeton ne produisent d\'essai',
      );
      expect(
        discord.count,
        1,
        reason: 'une tentative par bot, jamais une par passage de synchro',
      );
      expect(await nomEcri(), 'JeanMichel');
    });
  });

  group('un nom qui est un nom n\'est jamais réécrit', () {
    test('nom choisi : aucune requête, directe comme par le balayage', () async {
      final discord = _FauxDiscord(
        statusCode: 200,
        body: _identite(username: 'Nom-Impose-Par-Discord'),
      );
      await poserFiche(nom: 'MonSuperBot');

      expect(await rafraichir(discord), BotIdentitySyncOutcome.notNeeded);
      expect(await balayer(discord, <String>[_botId]), isEmpty);
      expect(
        discord.count,
        0,
        reason: 'un nom choisi est un nom : on ne le remplace pas par un autre',
      );
      expect(await nomEcri(), 'MonSuperBot');
    });
  });

  group('Discord ne rend rien d\'écrivable : le nom connu est conservé', () {
    test('jeton refusé, panne réseau, ou identité d\'un AUTRE bot', () async {
      await poserFiche();
      final refuse = _FauxDiscord(
        statusCode: 401,
        body: const <String, dynamic>{'message': '401: Unauthorized'},
      );
      final autre = _FauxDiscord(
        statusCode: 200,
        body: _identite(id: _autreBotId, username: 'Autre-Bot'),
      );
      final injoignable = _FauxDiscord(statusCode: 200, horsLigne: true);

      expect(await rafraichir(refuse), BotIdentitySyncOutcome.refused);
      // Réarmement propre au TEST : chaque cas doit être exerçable dans le même lancement.
      resetBotIdentityFetchAttempts();
      expect(await rafraichir(autre), BotIdentitySyncOutcome.refused);
      resetBotIdentityFetchAttempts();
      expect(await rafraichir(injoignable), BotIdentitySyncOutcome.refused);

      expect(
        await nomEcri(),
        _botId,
        reason:
            'aucune exception, aucun nom inventé : le symptôme reste visible mais honnête, '
            'et il sera réparé au prochain essai réussi',
      );
    });
  });

  group('garde anti-rafale', () {
    test('échec puis rejeu, et succès puis rejeu : un seul appel par bot', () async {
      await poserFiche();
      await poserFiche(botId: _autreBotId);
      final panne = _FauxDiscord(statusCode: 503, body: const {});

      expect(await rafraichir(panne), BotIdentitySyncOutcome.refused);
      expect(
        await rafraichir(panne),
        BotIdentitySyncOutcome.alreadyAttempted,
        reason:
            'on ne harcèle pas Discord : la tentative suivante aura lieu à la prochaine '
            'session, jamais en rafale dans celle-ci',
      );
      expect(await nomEcri(), _botId);
      expect(panne.count, 1);

      // Un SUCCÈS n'autorise pas davantage un second appel pour le même bot : on rétablit
      // le symptôme pour prouver que c'est bien la COMPTABILITÉ — et non la condition du
      // nom — qui tient le débit.
      final ok = _FauxDiscord(
        statusCode: 200,
        body: _identite(id: _autreBotId, username: 'JeanMichel'),
      );
      Future<BotIdentitySyncOutcome> rafraichirAutre() =>
          refreshBotIdentityFromDiscord(
            botId: _autreBotId,
            httpClient: ok.client(),
          );

      expect(await rafraichirAutre(), BotIdentitySyncOutcome.updated);
      await poserFiche(botId: _autreBotId);
      expect(await rafraichirAutre(), BotIdentitySyncOutcome.alreadyAttempted);
      expect(ok.count, 1, reason: 'un seul appel par bot et par lancement');
    });
  });
}
