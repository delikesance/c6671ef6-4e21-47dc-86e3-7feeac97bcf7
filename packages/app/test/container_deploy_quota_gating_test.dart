// Le quota de conteneurs d'une formule s'applique à TOUT LE MONDE, premium
// compris : une formule d'hébergement en cours (1 conteneur, affiché « 1/1 »)
// ne crée pas de place supplémentaire. Un bot clé en main n'ayant aucune
// configuration à sauvegarder, l'écran doit griser « Lancer le bot clé en
// main » AVANT la saisie du token dès que le quota est épuisé — et dire
// pourquoi.
//
// Ces tests verrouillent le miroir écran du verdict serveur
// (`can_deploy` + `deploy_blocked_reason` de /containers/eligibility).
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/containers/presentation/container_deploy_page.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
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

/// Corps de `/containers/eligibility` tel que le serveur le sert.
String _eligibilityBody({
  required bool premium,
  required int active,
  required int max,
  bool canDeploy = true,
  String? blockedReason,
  int minutes = 600,
}) {
  return jsonEncode(<String, dynamic>{
    'premium': premium,
    'active_containers': active,
    'max_containers': max,
    'can_deploy': canDeploy,
    'deploy_blocked_reason': blockedReason,
    'allow_turnkey': true,
    'hosting_minutes_balance': minutes,
    'ad_reward_minutes': 60,
    'plan_tier_code': premium ? 'HOSTED_APP_ONES' : 'FREE',
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp(
      'container_deploy_gating_test_',
    );
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

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  /// Monte l'écran de déploiement avec l'éligibilité servie par [body].
  Future<AppLocalizations> pumpDeployPage(
    WidgetTester tester,
    String body,
  ) async {
    tester.view.physicalSize = const Size(500, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      httpClient: MockClient((http.Request request) async {
        return http.Response(
          body,
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.darkTheme(),
        home: ContainerDeployPage(client: client),
      ),
    );
    // Pompes bornées : la page interroge le réseau au montage, et un `await` réel
    // ne progresse pas en temps simulé — il faut des fenêtres de temps réel.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 5)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
    return AppLocalizations.delegate.load(const Locale('fr'));
  }

  /// Bouton de LANCEMENT (repéré par son libellé : l'écran peut porter d'autres
  /// `FilledButton`, comme l'action « regarder une publicité » d'un avis de blocage).
  FilledButton launchButton(WidgetTester tester, AppLocalizations tr) {
    return tester.widget<FilledButton>(
      find.ancestor(
        of: find.text(tr.container_deploy_launch_btn),
        matching: find.byType(FilledButton),
      ),
    );
  }

  testWidgets(
    'quota atteint (premium 1/1) : lancement grisé et raison affichée',
    (WidgetTester tester) async {
      final tr = await pumpDeployPage(
        tester,
        _eligibilityBody(
          premium: true,
          active: 1,
          max: 1,
          canDeploy: false,
          blockedReason: 'container_limit',
        ),
      );

      expect(
        find.text(tr.container_deploy_launch_btn),
        findsOneWidget,
        reason: 'le bouton doit rester dans l’arbre, seulement désactivé',
      );
      expect(
        launchButton(tester, tr).onPressed,
        isNull,
        reason:
            'quota de conteneurs atteint (1/1) : le lancement doit être '
            'impossible, premium compris',
      );
      expect(
        find.text(tr.container_deploy_blocked_container_limit),
        findsOneWidget,
        reason: 'l’écran doit expliquer le blocage, pas seulement griser',
      );
    },
  );

  testWidgets(
    'quota non atteint (premium 0/1) : lancement actif et aucune raison',
    (WidgetTester tester) async {
      final tr = await pumpDeployPage(
        tester,
        _eligibilityBody(premium: true, active: 0, max: 1),
      );

      expect(find.text(tr.container_deploy_launch_btn), findsOneWidget);
      expect(
        launchButton(tester, tr).onPressed,
        isNotNull,
        reason: 'une place libre doit rester déployable',
      );
      expect(find.text(tr.container_deploy_blocked_container_limit), findsNothing);
    },
  );

  testWidgets(
    'verdict serveur prioritaire : refus malgré des chiffres locaux libres',
    (WidgetTester tester) async {
      final tr = await pumpDeployPage(
        tester,
        _eligibilityBody(
          premium: true,
          active: 0,
          max: 5,
          canDeploy: false,
          blockedReason: 'container_limit',
        ),
      );

      expect(launchButton(tester, tr).onPressed, isNull);
      expect(find.text(tr.container_deploy_blocked_container_limit), findsOneWidget);
    },
  );

  // La plateforme est forcée PUIS RESTAURÉE DANS LE CORPS du test : le binding de test
  // vérifie à la fin de chaque corps que les variables de debug de `foundation` sont
  // intactes, donc un `setUp`/`tearDown` (ou un `addTearDown`) arrive trop tard et fait
  // échouer le test sur cet invariant. L'hôte de la suite est Linux, donc « poste de
  // travail » par défaut : le parcours mobile doit se déclarer explicitement.
  group('parcours mobile (publicité récompensée)', () {
    testWidgets(
      'minutes épuisées (ad-financé, mobile) : lancement grisé et porte de sortie par la pub',
      (WidgetTester tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        final tr = await pumpDeployPage(
          tester,
          _eligibilityBody(
            premium: false,
            active: 0,
            max: 1,
            minutes: 0,
            canDeploy: false,
            blockedReason: 'no_minutes',
          ),
        );

        // Sans minutes, l'écran ne propose plus de lancement du tout : il met en avant
        // l'unique porte de sortie (regarder une publicité). C'est encore plus strict
        // qu'un bouton grisé, donc conforme à la règle « pas de configuration à sauver
        // pour rien ».
        expect(find.text(tr.container_deploy_launch_btn), findsNothing);
        expect(find.text(tr.container_deploy_blocked_no_minutes), findsOneWidget);
        expect(find.text(tr.container_hosted_ad_button(60)), findsWidgets);

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });

  group('poste de travail (aucune publicité)', () {
    testWidgets(
      'minutes épuisées : le solde serveur et les formules, jamais une vidéo',
      (WidgetTester tester) async {
        // Le desktop ne diffuse aucune publicité : le temps d'hébergement y vient du
        // solde serveur (`hosting_minutes_balance`, qui inclut déjà les minutes gagnées
        // par pub sur mobile). L'écran doit donc montrer ce solde et renvoyer aux
        // formules — jamais proposer une vidéo qui n'existe pas.
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        final tr = await pumpDeployPage(
          tester,
          _eligibilityBody(
            premium: false,
            active: 0,
            max: 1,
            minutes: 0,
            canDeploy: false,
            blockedReason: 'no_minutes',
          ),
        );

        expect(
          find.text(tr.container_hosted_ad_button(60)),
          findsNothing,
          reason: 'aucun parcours publicitaire ne doit exister sur un poste de travail',
        );
        expect(
          find.text(tr.container_hosted_minutes_available(0)),
          findsWidgets,
          reason:
              'le solde annoncé par le serveur doit être affiché (bannière et avis '
              'peuvent le rappeler tous les deux)',
        );
        expect(
          find.text(tr.plan_limit_view_offers),
          findsWidgets,
          reason: 'la porte de sortie desktop est la formule, pas la publicité',
        );

        debugDefaultTargetPlatformOverride = null;
      },
    );
  });

  testWidgets(
    'compte ad-financé avec des minutes : lancement actif',
    (WidgetTester tester) async {
      final tr = await pumpDeployPage(
        tester,
        _eligibilityBody(premium: false, active: 0, max: 1, minutes: 120),
      );

      expect(launchButton(tester, tr).onPressed, isNotNull);
    },
  );

  testWidgets(
    'hébergement cloud coupé par le serveur : la raison affichée dit la vraie cause',
    (WidgetTester tester) async {
      // Le serveur a dit lui-même que l'hébergement cloud est coupé sur ce
      // déploiement (`premium_cloud_enabled: false`).
      await SubscriptionService.applyPushedAccountState(const <String, dynamic>{
        'plan': 'FREE',
        'premium_cloud_enabled': false,
      });
      addTearDown(() async {
        // Sinon le fichier entier hériterait d'un « cloud coupé ».
        await SubscriptionService.debugResetForTests();
      });

      final tr = await pumpDeployPage(
        tester,
        _eligibilityBody(
          premium: false,
          active: 0,
          max: 1,
          canDeploy: false,
          blockedReason: 'no_minutes',
          minutes: 0,
        ),
      );

      expect(
        find.text(tr.container_deploy_blocked_cloud_disabled),
        findsOneWidget,
        reason:
            'la cause est l\'interrupteur du déploiement : proposer une publicité ou une formule '
            'promettrait une porte qui n\'existe pas',
      );
      expect(
        find.text(tr.container_deploy_blocked_no_minutes),
        findsNothing,
        reason: 'la phrase des minutes propose la publicité récompensée : ici elle serait fausse',
      );
    },
  );
}
