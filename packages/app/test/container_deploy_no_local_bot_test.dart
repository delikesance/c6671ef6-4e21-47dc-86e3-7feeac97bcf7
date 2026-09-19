// Déployer un bot clé en main n'enregistre AUCUN bot local.
//
// Un bot clé en main est un CONTENEUR, sans configuration à éditer : l'accueil le
// liste via `listContainers()` (carte `HomeTurnkeyContainerCard`). L'écran de
// déploiement enregistrait autrefois un « faux bot BDFD » local (`is_turnkey` /
// `type: 'turnkey'`) sous l'ID DISCORD du bot, avec une config par défaut et le
// token Discord en clair — au risque d'écraser un vrai bot portant le même ID, et
// avec une ligne de bot fantôme côté manager à la clé.
//
// Le harnais (path_provider + sqflite ffi simulés, MockClient) est celui de
// `test/container_deploy_quota_gating_test.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// L'écran résout le compte connecté au montage (stockage local) : il lui faut un
/// dossier `path_provider` simulé et une base sqflite ffi, comme le reste de la suite.
const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

/// Identité Discord renvoyée par le serveur pour le token fourni : c'est sous cet
/// ID que l'ancien code fabriquait un faux bot local.
const String _discordBotId = '111111111111111111';
const String _discordBotName = 'FauxBotBDFD';

/// Corps de `/containers/eligibility` : un compte dont le quota est libre, donc
/// un déploiement autorisé.
String _eligibilityBody() {
  return jsonEncode(<String, dynamic>{
    'premium': true,
    'active_containers': 0,
    'max_containers': 1,
    'can_deploy': true,
    'deploy_blocked_reason': null,
    'allow_turnkey': true,
    'hosting_minutes_balance': 600,
    'ad_reward_minutes': 60,
    'plan_tier_code': 'HOSTED_APP_ONES',
  });
}

http.Response _jsonResponse(String body) {
  return http.Response(
    body,
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

/// Toutes les entrées de bot réellement écrites dans le stockage local : les
/// fichiers d'index (`all_apps.json`, `_deleted_bots.json`) n'en sont pas.
Future<List<String>> _botEntryFiles(Directory documentsDir) async {
  final appsDir = Directory('${documentsDir.path}/apps');
  if (!await appsDir.exists()) return const <String>[];
  final names = <String>[];
  await for (final entity in appsDir.list()) {
    if (entity is! File) continue;
    final name = entity.uri.pathSegments.last;
    if (name == 'all_apps.json' || name == '_deleted_bots.json') continue;
    names.add(name);
  }
  names.sort();
  return names;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late List<String> requestPaths;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Fichiers SQLite verrouillés : sans importance pour le test.
      }
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    requestPaths = <String>[];
    documentsDir = await Directory.systemTemp.createTemp(
      'container_deploy_no_local_bot_',
    );

    // Amorce `AppManager` HORS du temps simulé : son initialisation démarre une
    // boucle de fond perpétuelle (`Future.delayed(2 s)` dans
    // `_startStreamUpdateLoop`). Lancée depuis la zone de temps simulé d'un
    // `testWidgets`, cette minuterie y resterait en vie à la fin et ferait
    // échouer un test pourtant vert (« A Timer is still pending »). `setUp`
    // tourne en asynchrone RÉEL : la boucle y pose de vraies minuteries.
    final appManager = AppManager();
    await appManager.getAllApps();
    for (var i = 0; i < 300 && !appManager.isInitialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  testWidgets(
    'un déploiement clé en main n\'écrit aucun bot dans le stockage local',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((http.Request request) async {
          final path = request.url.path;
          requestPaths.add(path);
          if (path.endsWith('/containers/eligibility')) {
            return _jsonResponse(_eligibilityBody());
          }
          if (path.endsWith('/gateway/turnkey/validate-token')) {
            return _jsonResponse(
              jsonEncode(<String, dynamic>{
                'id': _discordBotId,
                'username': _discordBotName,
              }),
            );
          }
          if (path.endsWith('/containers/deploy')) {
            // Le conteneur part bien en déploiement : c'est cette réussite qui
            // déclenchait l'enregistrement du faux bot local.
            return _jsonResponse(jsonEncode(<String, dynamic>{}));
          }
          return _jsonResponse(jsonEncode(<String, dynamic>{}));
        }),
      );

      final tr = await AppLocalizations.delegate.load(const Locale('fr'));

      // L'écran est poussé au-dessus d'un écran d'accueil : il peut se refermer
      // normalement en fin de déploiement (aucune page de détail de conteneur
      // n'est ouverte ici, ses minuteries relèvent d'un autre test).
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ContainerDeployPage(client: client),
                  ),
                ),
                child: const Text('ouvrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('ouvrir'));

      // Pompes bornées : la page interroge le réseau au montage, et un `await`
      // réel ne progresse pas en temps simulé — il faut des fenêtres de temps
      // réel (`runAsync`). Chaque fenêtre fait avancer la chaîne d'un cran.
      Future<void> settle({int windows = 20}) async {
        for (var i = 0; i < windows; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settle();

      // Le quota est libre : le lancement doit être actif.
      final launch = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text(tr.container_deploy_launch_btn),
          matching: find.byType(FilledButton),
        ),
      );
      expect(
        launch.onPressed,
        isNotNull,
        reason: 'un déploiement autorisé doit pouvoir être lancé',
      );

      await tester.enterText(
        find.byType(TextFormField),
        'TOKEN-DISCORD-DE-TEST',
      );
      await tester.pump();

      await tester.tap(find.text(tr.container_deploy_launch_btn));

      // Le déploiement enchaîne plusieurs allers-retours réels (validation du
      // token, puis déploiement, puis — dans l'ANCIEN code — écriture locale du
      // faux bot) : 20 fenêtres n'y suffisaient pas, et une lecture du stockage
      // faite trop tôt aurait vu un disque vide même avec le bug. On attend donc
      // la FERMETURE de l'écran (fin de l'enchaînement), bornée pour autant.
      Future<void> settleUntilDeployPageClosed({int maxWindows = 200}) async {
        for (var i = 0; i < maxWindows; i++) {
          if (find.byType(ContainerDeployPage).evaluate().isEmpty) return;
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settleUntilDeployPageClosed();
      // Fenêtres de drainage : laisse aboutir un éventuel enregistrement local
      // lancé sans être attendu (`unawaited`) juste avant la fermeture.
      await settle(windows: 20);

      // Les lectures du stockage local passent par `runAsync` : dans la zone de
      // temps SIMULÉ d'un `testWidgets`, la poursuite d'un `await` sur une
      // opération `dart:io` n'est jamais planifiée si plus rien ne pompe — le
      // test pendait alors jusqu'au plafond du lanceur, sans même que son propre
      // `--timeout` puisse se déclencher.
      final entries = await tester.runAsync(() => _botEntryFiles(documentsDir));

      // 1. Le déploiement a RÉELLEMENT eu lieu (sinon le test passerait pour de
      //    mauvaises raisons) : le token a été validé puis le conteneur déployé.
      expect(
        requestPaths.where((p) => p.endsWith('/gateway/turnkey/validate-token')),
        isNotEmpty,
        reason: 'le token fourni doit être validé côté serveur',
      );
      expect(
        requestPaths.where((p) => p.endsWith('/containers/deploy')),
        isNotEmpty,
        reason: 'le conteneur clé en main doit être envoyé au déploiement',
      );

      // L'écran s'est refermé tout seul (le serveur ne renvoie pas
      // `container_id` ici) : plus personne ne tourne, aucun écran de détail de
      // conteneur — et ses minuteries de rafraîchissement — n'a été poussé.
      expect(
        find.byType(ContainerDeployPage),
        findsNothing,
        reason: 'le déploiement réussi doit refermer l’écran de déploiement',
      );

      // 2. Aucun bot local n'a été créé — ni sous l'ID Discord du bot, ni sous
      //    aucun autre ID. Un bot clé en main est un conteneur, pas un bot.
      expect(
        entries,
        isEmpty,
        reason:
            'un déploiement clé en main ne doit enregistrer AUCUN bot local '
            '(pseudo-bot turnkey, config par défaut, token en clair)',
      );

      // 3. L'index des bots reste vide : rien à afficher dans la liste des bots.
      final indexFile = File('${documentsDir.path}/apps/all_apps.json');
      final indexContent = await tester.runAsync(() async {
        if (!await indexFile.exists()) return null;
        return await indexFile.readAsString();
      });
      if (indexContent != null) {
        expect(
          jsonDecode(indexContent),
          isEmpty,
          reason: 'l\'index des bots ne doit contenir aucune entrée',
        );
      }

      // La notification de succès porte un minuteur de 4 s : on le laisse
      // expirer, sinon le test se termine avec une minuterie en vie.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
