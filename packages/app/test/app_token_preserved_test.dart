// Le jeton d'un bot ne doit JAMAIS être effacé par une synchro qui n'en apporte pas.
//
// Mesuré sur un poste de travail : l'entrée de coffre `bot_token:1350824555119382678` est
// passée de 137 octets (jeton réel, coffre d'origine) à 41 octets (chiffrement d'une
// chaîne VIDE) au moment d'une synchro, puis l'écran affichait « Token invalid or
// missing » sur tous les bots — impossible d'en récupérer un seul, même en rafraîchissant.
//
// Cause : le manager RÉDIGE volontairement le jeton dans ses listes
// (`internal/services/bot_gateway.go` : `BotToken: "" // Zero plaintext token in summary
// lists`, et son test `TestBotGatewayListBotsIncludesDecryptedTokens` exige ce vide). La
// synchro reprenait ce champ vide et l'écrivait par-dessus le jeton local. Un jeton ne
// redescend jamais du serveur : la seule copie qui compte est celle du poste.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart' show Snowflake;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const String _botId = '1350824555119382678';

/// Jeton FACTICE (jamais un vrai) : la forme suffit à prouver qu'on ne l'écrase pas.
const String _tokenReel = 'JETON-LOCAL-DE-TEST.abcXYZ.0123456789abcdefghij';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory racine;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    racine = await Directory.systemTemp.createTemp('app_token_preserved_test_');
    // Les applications vivent sous le dossier Documents, le coffre sous le dossier de
    // support : le même dossier temporaire répond aux deux.
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
  });

  test(
    'une synchro sans jeton (champ rédigé par le serveur) n\'efface pas le jeton local',
    () async {
      final manager = AppManager();
      await manager.createOrUpdateApp(
        id: Snowflake.parse(_botId),
        username: 'Bot-Creator',
        token: _tokenReel,
      );

      // Exactement ce que fait `syncAllBotsFromManager` : le serveur renvoie le bot
      // sans son jeton, donc le champ arrive vide.
      await manager.createOrUpdateApp(
        id: Snowflake.parse(_botId),
        username: 'Bot-Creator',
        token: '',
      );

      final app = await manager.getApp(_botId);
      expect(
        app['token'],
        _tokenReel,
        reason: 'un champ rédigé par le serveur ne doit jamais écraser le jeton local',
      );

      final secure = await SecureStorageService.instance;
      expect(
        await secure.read('bot_token:$_botId'),
        _tokenReel,
        reason: 'le coffre est la seule copie du jeton : elle doit survivre à la synchro',
      );
    },
  );

  test(
    'créer un bot sans jeton reste possible (aucun jeton inventé)',
    () async {
      final manager = AppManager();
      const autreBot = '1488275294295949504';

      await manager.createOrUpdateApp(
        id: Snowflake.parse(autreBot),
        username: 'JeanMichel',
        token: '   ',
      );

      final app = await manager.getApp(autreBot);
      expect(
        (app['token'] ?? '').toString(),
        isEmpty,
        reason: 'sans jeton connu, on n\'en fabrique pas un',
      );
    },
  );

  // ─── Le jeton ne reste pas en clair sur le disque ────────────────────────
  //
  // Il était écrit dans `apps/<id>.json` (un JSON lisible par n'importe quel
  // processus du poste : sauvegarde, indexeur, copie du dossier de données) et
  // le coffre n'était qu'une SECONDE écriture, non attendue, APRÈS le fichier.
  // L'ordre est maintenant l'inverse : coffre d'abord, fichier sans jeton.

  test(
    'le jeton ne reste pas en clair dans apps/<id>.json, et il n\'est pas perdu',
    () async {
      final manager = AppManager();
      const botSansCopie = '111122223333444455';
      await manager.createOrUpdateApp(
        id: Snowflake.parse(botSansCopie),
        username: 'SansCopie',
        token: _tokenReel,
      );

      final fichier = File('${await getAppStoragePath()}/apps/$botSansCopie.json');
      expect(await fichier.exists(), isTrue);
      final contenu = await fichier.readAsString();
      expect(
        contenu.contains(_tokenReel),
        isFalse,
        reason: 'un secret ne doit pas rester en clair dans un fichier JSON',
      );
      expect(
        contenu.contains('"token"'),
        isFalse,
        reason: 'le champ lui-même ne doit plus être écrit dans le fichier',
      );

      // Retirer la copie du fichier ne doit RIEN coûter : le coffre la rend.
      final app = await manager.getApp(botSansCopie);
      expect(app['token'], _tokenReel);
      final secure = await SecureStorageService.instance;
      expect(await secure.read('bot_token:$botSansCopie'), _tokenReel);
    },
  );

  test(
    'une copie en clair laissée par une version antérieure est retirée à la lecture',
    () async {
      final manager = AppManager();
      const botHeritage = '999988887777666655';
      final dossier = '${await getAppStoragePath()}/apps';
      await Directory(dossier).create(recursive: true);
      final fichier = File('$dossier/$botHeritage.json');
      await fichier.writeAsString(
        jsonEncode(<String, dynamic>{
          'id': botHeritage,
          'name': 'Heritage',
          'token': _tokenReel,
        }),
      );
      final secure = await SecureStorageService.instance;
      await secure.write('bot_token:$botHeritage', _tokenReel);

      final app = await manager.getApp(botHeritage);
      expect(app['token'], _tokenReel, reason: 'le coffre fait foi');

      // La réparation est chaînée derrière les écritures en cours : sans cette
      // attente on lirait le fichier avant qu'elle ne l'ait nettoyé.
      await manager.flushPendingWrites();
      expect(
        (await fichier.readAsString()).contains(_tokenReel),
        isFalse,
        reason:
            'un fichier qui traîne encore une copie en clair est nettoyé à la première lecture',
      );
    },
  );

  test(
    'la règle : le jeton ne part sur le disque que si le coffre a refusé',
    () {
      final sansCoffre = AppManager.appDocumentForDisk(
        <String, dynamic>{'id': '1', 'name': 'x', 'token': _tokenReel},
        tokenStoredInVault: false,
      );
      expect(
        sansCoffre['token'],
        _tokenReel,
        reason: 'un jeton perdu est pire qu\'un jeton en clair : sans coffre, on garde la copie',
      );

      final avecCoffre = AppManager.appDocumentForDisk(
        <String, dynamic>{'id': '1', 'name': 'x', 'token': _tokenReel},
        tokenStoredInVault: true,
      );
      expect(
        avecCoffre.containsKey('token'),
        isFalse,
        reason: 'quand le coffre l\'a, le fichier ne le porte plus',
      );

      final vide = AppManager.appDocumentForDisk(
        <String, dynamic>{'id': '1', 'token': ''},
        tokenStoredInVault: true,
      );
      expect(
        vide.containsKey('token'),
        isFalse,
        reason: 'un jeton vide ne s\'écrit jamais, même dans le repli',
      );
    },
  );
}
