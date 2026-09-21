// L'écran de déploiement doit HONORER le schéma d'environnement du template clé
// en main : un champ de saisie par variable déclarée, pré-rempli avec la valeur
// par défaut, en lecture seule quand le serveur impose la valeur — et l'env
// envoyé à `/containers/deploy` est celui du SCHÉMA, plus un `TOKEN` en dur.
//
// Le harnais (path_provider + sqflite ffi simulés, MockClient, pompes bornées)
// est celui de `test/container_deploy_no_local_bot_test.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_templates.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
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

/// Template tel que le manager le sert : le schéma est sous `env_fields_schema`
/// (l'app lisait `env_fields`, d'où un formulaire toujours vide).
const String _templateTitle = 'SkyBot';

Map<String, dynamic> _templateJson() => <String, dynamic>{
  'id': 'skybot',
  'slug': 'skybot',
  'title': _templateTitle,
  'description': 'Bot de test piloté par son schéma',
  'image': 'ghcr.io/example/skybot:latest',
  'icon': 'music',
  'category': 'music',
  'cpu_millis': 250,
  'memory_mb': 256,
  'storage_gb': 1,
  'requires_private_registry': false,
  'required_intents': <String>['Message Content Intent'],
  'tips': <String>['Astuce de test'],
  'translations': <String, dynamic>{},
  'env_fields_schema': <Map<String, dynamic>>[
    <String, dynamic>{
      'key': 'TOKEN',
      'label': 'Discord token',
      'required': true,
      'secret': true,
      'default_value': '',
    },
    <String, dynamic>{
      'key': 'LAVALINK_URL',
      'label': 'Lavalink URL',
      'required': false,
      'default_value': 'ws://node:2333',
    },
    <String, dynamic>{
      'key': 'REGION',
      'label': 'Region',
      'fixed': true,
      'default_value': 'eu-west',
    },
    <String, dynamic>{
      'key': 'NODE_ID',
      'label': 'Node id',
      'source': 'node',
      'source_variable': 'node.id',
    },
  ],
};

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late List<Map<String, dynamic>> deployBodies;

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
    deployBodies = <Map<String, dynamic>>[];
    documentsDir = await Directory.systemTemp.createTemp(
      'container_deploy_turnkey_env_',
    );

    // `AppManager` démarre une boucle de fond perpétuelle : l'amorcer hors du
    // temps simulé, comme le fait le reste de la suite.
    final appManager = AppManager();
    await appManager.getAllApps();
    for (var i = 0; i < 300 && !appManager.isInitialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  });

  testWidgets(
    'le formulaire rend le schéma du template et envoie l’env complet',
    (WidgetTester tester) async {
      // Le template est celui de la réponse du manager : le sélectionner par son
      // titre, comme le ferait l'utilisateur.
      setCachedTurnkeyTemplates(<HostedAppTemplate>[
        HostedAppTemplate.fromJson(_templateJson()),
      ]);
      addTearDown(() => setCachedTurnkeyTemplates(<HostedAppTemplate>[]));

      tester.view.physicalSize = const Size(600, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((http.Request request) async {
          final path = request.url.path;
          if (path.endsWith('/containers/eligibility')) {
            return _jsonResponse(_eligibilityBody());
          }
          if (path.endsWith('/gateway/turnkey/validate-token')) {
            return _jsonResponse(
              jsonEncode(<String, dynamic>{
                'id': '222222222222222222',
                'username': 'SkyBot',
              }),
            );
          }
          if (path.endsWith('/containers/deploy')) {
            deployBodies.add(
              jsonDecode(request.body) as Map<String, dynamic>,
            );
            // Pas de `container_id` : la page se referme d'elle-même, sans
            // pousser l'écran de détail (et ses minuteries).
            return _jsonResponse(jsonEncode(<String, dynamic>{}));
          }
          return _jsonResponse(jsonEncode(<String, dynamic>{}));
        }),
      );

      final tr = await AppLocalizations.delegate.load(const Locale('fr'));

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

      Future<void> settle({int windows = 20}) async {
        for (var i = 0; i < windows; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 5)),
          );
          await tester.pump(const Duration(milliseconds: 50));
        }
      }

      await settle();

      // Le template du serveur est proposé ET sélectionnable.
      expect(find.text(_templateTitle), findsOneWidget);
      await tester.tap(find.text(_templateTitle));
      await tester.pump();

      // Un champ par variable du schéma : la section apparaît avec le modèle.
      expect(find.text(tr.container_deploy_env_fields_section), findsOneWidget);

      Finder fieldWithLabel(String label) => find.ancestor(
        of: find.text(label),
        matching: find.byType(TextFormField),
      );

      // Variable avec défaut : pré-remplie.
      final url = fieldWithLabel('Lavalink URL');
      expect(url, findsOneWidget);
      expect(
        find.descendant(of: url, matching: find.text('ws://node:2333')),
        findsOneWidget,
        reason: 'le défaut déclaré par le template pré-remplit le champ',
      );

      // Variable imposée par le serveur : en lecture seule, jamais saisissable.
      final region = fieldWithLabel('Region');
      expect(
        tester.widget<TextField>(find.descendant(
          of: region,
          matching: find.byType(TextField),
        )).enabled,
        isFalse,
        reason: 'un champ figé par le serveur ne se saisit pas',
      );
      expect(
        find.descendant(of: region, matching: find.byIcon(Icons.lock_outline)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: region,
          matching: find.text(tr.container_deploy_env_server_provided),
        ),
        findsOneWidget,
      );

      // Le token garde son champ dédié, en tête du formulaire.
      await tester.enterText(
        fieldWithLabel(tr.app_bot_token),
        'TOKEN-DISCORD-DE-TEST',
      );
      await tester.pump();
      // L'utilisateur saisit sa propre valeur : elle doit primer sur le défaut.
      await tester.enterText(url, 'ws://mon-noeud:443');
      await tester.pump();

      expect(find.text(tr.container_deploy_launch_btn), findsOneWidget);
      await tester.tap(find.text(tr.container_deploy_launch_btn));

      for (var i = 0; i < 200; i++) {
        if (find.byType(ContainerDeployPage).evaluate().isEmpty) break;
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 5)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
      await settle();

      expect(
        deployBodies,
        hasLength(1),
        reason: 'le déploiement doit réellement être parti au serveur',
      );
      final env = Map<String, String>.from(deployBodies.single['env'] as Map);

      expect(env['TOKEN'], 'TOKEN-DISCORD-DE-TEST');
      expect(
        env['TOKEN'],
        isNotEmpty,
        reason:
            'non-vacuité : la clé déclarée par le template est bien celle que '
            'le champ token dédié alimente',
      );
      expect(env['LAVALINK_URL'], 'ws://mon-noeud:443');
      expect(env['REGION'], 'eu-west', reason: 'valeur figée déclarée');
      expect(
        env.containsKey('NODE_ID'),
        isFalse,
        reason:
            'variable alimentée par le nœud et sans valeur déclarée : l’app '
            'n’invente rien, le serveur l’impose',
      );

      // La notification de succès porte un minuteur de 4 s : on le laisse expirer.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
