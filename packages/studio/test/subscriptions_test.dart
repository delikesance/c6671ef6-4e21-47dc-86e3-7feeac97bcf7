import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/auth/auth_controller.dart';
import 'package:bot_creator_studio/src/auth/studio_session.dart';
import 'package:bot_creator_studio/src/editor/studio_hosted_containers_host.dart';
import 'package:bot_creator_studio/src/editor/studio_subscriptions_host.dart';
import 'package:bot_creator_studio/src/locale_controller.dart';
import 'package:bot_creator_studio/src/premium/premium_gate.dart';
import 'package:bot_creator_studio/src/premium/studio_feature.dart';
import 'package:bot_creator_studio/src/screens/bot_actions.dart';
import 'package:bot_creator_studio/src/studio_app.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _catalog({bool published = true}) => {
  'published': published,
  'document': {
    'schema_version': 1,
    'default_locale': 'en',
    'offers': [
      {
        'id': 'pro',
        'kind': 'subscription',
        'period': 'month',
        'enabled': true,
        'translations': {
          'en': {
            'title': 'Pro plan',
            'description': 'Everything for serious bots',
            'benefits': ['Four bots', 'No ads'],
          },
        },
        'bindings': [
          {
            'provider': 'google',
            'platform': 'android',
            'product_id': 'pro_android',
            'base_plan_id': 'monthly',
          },
        ],
        'required_capabilities': ['commerce.subscription.v1'],
      },
    ],
  },
};

List<Map<String, dynamic>> _entries(int count, {int from = 0}) => [
  for (var i = from; i < from + count; i++)
    {
      'delta': i.isEven ? 1000000 : -250000,
      'source': i.isEven ? 'admin_grant' : 'copilot',
      'created_at': DateTime.now()
          .toUtc()
          .subtract(Duration(days: 3 + i))
          .toIso8601String(),
      'reference': 'ref-$i',
      'reason': i.isEven ? 'welcome bonus' : '',
      'conversation_id': i.isEven ? '' : 'conv-$i',
    },
];

/// Un Manager simulé : formule, éligibilité à l'hébergement, catalogue,
/// portefeuille et historique des crédits. Chaque requête est gardée.
class _Manager {
  Map<String, dynamic> runtime = {'plan': 'FREE'};
  Map<String, dynamic> eligibility = {
    'premium': false,
    'hosting_minutes_balance': 0,
    'active_containers': 0,
    'max_containers': 1,
    'can_deploy': false,
    'allow_turnkey': true,
  };
  Map<String, dynamic>? catalog;
  Map<String, dynamic> wallet = {
    'available': 2500000,
    'reserved': 0,
    'purchased': 1000000,
    'rewarded': 500000,
    'granted': 1000000,
    'blocked': false,
    'spins': 2,
    'remaining_ads': 3,
    'roulette': {
      'enabled': true,
      'prizes': [
        {'credits': 100000},
      ],
    },
  };
  bool down = false;
  final seen = <http.Request>[];

  http.Client get client => MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p == '/gateway/runtime') {
      return down ? _json({'error': 'down'}, 503) : _json(runtime);
    }
    if (p == '/containers/eligibility') {
      return down ? _json({'error': 'down'}, 503) : _json(eligibility);
    }
    if (p == '/gateway/commerce/catalog') {
      final c = catalog;
      return c == null ? _json({'error': 'not found'}, 404) : _json(c);
    }
    if (p == '/gateway/ai/wallet') return _json(wallet);
    if (p == '/gateway/ai/ledger') {
      final offset = int.parse(r.url.queryParameters['offset'] ?? '0');
      return _json({
        'entries': _entries(offset == 0 ? 50 : 2, from: offset),
        'has_more': offset == 0,
      });
    }
    return _json({'ok': true});
  });

  StudioApi get api =>
      StudioApi(baseUrl: 'https://api.test', client: client)
        ..accessToken = ({bool force = false}) async => 'tok';

  Iterable<String> get calls => seen.map(
    (r) =>
        '${r.method} ${r.url.path}${r.url.query.isEmpty ? '' : '?${r.url.query}'}',
  );
}

Widget _app(Widget home, {Locale locale = const Locale('en')}) => MaterialApp(
  localizationsDelegates: [
    ...AppLocalizations.localizationsDelegates,
    ...StudioLocalizations.localizationsDelegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  locale: locale,
  theme: AppTheme.darkTheme(),
  home: home,
);

void _tall(WidgetTester tester) {
  tester.view.physicalSize = const Size(900, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  group('hôte des abonnements : format des appels', () {
    test(
      'formule gratuite : rien n\'est actif, tout vient du Manager',
      () async {
        final manager = _Manager();
        final host = StudioSubscriptionsHost(manager.api);

        final s = await host.refresh();
        expect(s.botActive, isFalse);
        expect(s.hostedActive, isFalse);
        expect(
          manager.calls,
          containsAll(['GET /gateway/runtime', 'GET /containers/eligibility']),
        );
        for (final r in manager.seen) {
          expect(r.headers['authorization'], 'Bearer tok', reason: r.url.path);
        }
        expect(host.current, same(s));
      },
    );

    test('formule payante : nom, plafonds, échéance et hébergement', () async {
      final manager = _Manager()
        ..runtime = {
          'plan': 'PREMIUM',
          'display_name': 'Pro',
          'max_bots': 4,
          'provider': 'admin_remote',
          'expires_at': '2030-01-02T03:04:05Z',
        }
        ..eligibility = {
          'premium': true,
          'allow_turnkey': true,
          'max_containers': 2,
          'hosting_permanent': true,
          'hosting_minutes_balance': 0,
          'can_deploy': true,
        };
      final s = await StudioSubscriptionsHost(manager.api).refresh();
      expect(s.botActive, isTrue);
      expect(s.planDisplayName, 'Pro');
      expect(s.planMaxBots, 4);
      expect(s.botExpiresAt, DateTime.utc(2030, 1, 2, 3, 4, 5));
      expect(s.botServerGranted, isTrue);
      expect(s.hostedActive, isTrue);
      expect(s.hostedServerGranted, isTrue);
      expect(s.hostedMaxContainers, 2);
      expect(s.hostingCoveragePermanent, isTrue);
      expect(s.hostingCoverageExpiresAt, isNull);
    });

    test('le socle gratuit du serveur n\'allume pas l\'hébergement', () async {
      // Le serveur répond 1 conteneur / turnkey autorisé quand aucune formule
      // n'est connue : seul `premium` distingue une formule payante.
      final manager = _Manager()
        ..eligibility = {
          'premium': false,
          'allow_turnkey': true,
          'max_containers': 1,
        };
      final s = await StudioSubscriptionsHost(manager.api).refresh();
      expect(s.hostedActive, isFalse);
    });

    test(
      'un abonnement de boutique n\'est pas « géré par le serveur »',
      () async {
        final manager = _Manager()
          ..runtime = {'plan': 'PREMIUM', 'provider': 'google_play'};
        final s = await StudioSubscriptionsHost(manager.api).refresh();
        expect(s.botActive, isTrue);
        expect(s.botServerGranted, isFalse);
      },
    );

    test('Manager injoignable : l\'état précédent est gardé', () async {
      final manager = _Manager()..runtime = {'plan': 'PREMIUM'};
      final host = StudioSubscriptionsHost(manager.api);
      final before = await host.refresh();
      expect(before.botActive, isTrue);
      manager.down = true;
      // Une panne n'efface rien : le Studio n'affirme pas « gratuit » sur une
      // lecture qui a échoué.
      expect(await host.refresh(), same(before));
      expect(host.current.botActive, isTrue);
    });

    test('catalogue : lu et décodé ; non publié ou absent = rien', () async {
      final manager = _Manager()..catalog = _catalog();
      final host = StudioSubscriptionsHost(manager.api);
      final catalog = await host.loadCommerce();
      expect(catalog!.offers.single.text('en', 'en')!.title, 'Pro plan');
      expect(manager.calls, contains('GET /gateway/commerce/catalog'));

      manager.catalog = _catalog(published: false);
      expect(await host.loadCommerce(), isNull);
      manager.catalog = null;
      expect(await host.loadCommerce(), isNull);
    });

    test('capacités : aucun achat web, aucune roulette', () async {
      final host = StudioSubscriptionsHost(_Manager().api);
      expect(host.canPurchase, isFalse);
      expect(host.hasRewardedAds, isFalse);
      expect(await host.restoreBotPurchases(), isFalse);
      expect(host.storePlatform, isNull);
      final credits = StudioAiCreditsHost(_Manager().api);
      expect(credits.rewardsPlatform, isNull);
      expect(credits.canOpenConversation, isFalse);
      expect(await credits.loadPacks('fr'), isEmpty);
      expect(
        await credits.buyPack(
          const AiCreditsPack(id: 'x', title: 't', price: '1', credits: 1),
        ),
        isFalse,
      );
      await expectLater(credits.spin('k'), throwsUnsupportedError);
      await expectLater(credits.watchRewardAd(), throwsUnsupportedError);
    });

    test('crédits : portefeuille et historique par page de 50', () async {
      final manager = _Manager();
      final host = StudioAiCreditsHost(manager.api);
      expect((await host.wallet())['available'], 2500000);
      final page = await host.ledger(offset: 50);
      expect(page['has_more'], isFalse);
      expect(
        manager.calls,
        containsAll([
          'GET /gateway/ai/wallet',
          'GET /gateway/ai/ledger?offset=50',
        ]),
      );
    });
  });

  group('hub des abonnements (écran de l\'app) sur le Manager', () {
    testWidgets('compte gratuit : inactif, lecture seule, mention mobile', (
      tester,
    ) async {
      _tall(tester);
      final manager = _Manager();
      await tester.pumpWidget(
        _app(SubscriptionsHubPage(host: StudioSubscriptionsHost(manager.api))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscriptions'), findsOneWidget);
      expect(find.text('Not subscribed'), findsNWidgets(2));
      // Ni achat, ni restauration, ni gestion : la phrase de l'app pour les
      // plateformes sans boutique.
      expect(find.text('Subscribe'), findsNothing);
      expect(find.text('Restore purchases'), findsNothing);
      expect(find.text('Manage subscription'), findsNothing);
      expect(
        find.text('Subscriptions are currently available on mobile only.'),
        findsOneWidget,
      );
      // Les offres restent lisibles même sans catalogue publié.
      expect(find.text('View plans'), findsOneWidget);
    });

    testWidgets('formule payante : nom, plafond, échéance, couverture', (
      tester,
    ) async {
      _tall(tester);
      final manager = _Manager()
        ..runtime = {
          'plan': 'PREMIUM',
          'display_name': 'Pro',
          'max_bots': 4,
          'provider': 'admin_remote',
          'expires_at': '2099-01-02T03:04:05Z',
        }
        ..eligibility = {
          'premium': true,
          'allow_turnkey': true,
          'max_containers': 2,
          'hosting_expires_at': '2099-05-06T07:08:09Z',
        };
      await tester.pumpWidget(
        _app(SubscriptionsHubPage(host: StudioSubscriptionsHost(manager.api))),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active'), findsNWidgets(2));
      // La formule d'hébergement porte son nom en bas avec son plafond ; la
      // carte du haut n'annonce que la capacité bot.
      expect(find.textContaining('Pro · '), findsOneWidget);
      expect(find.text('Pro (4 bots max)'), findsNothing);
      expect(find.text('4 bots max'), findsOneWidget);
      expect(find.text('Managed by server'), findsNWidgets(2));
      expect(find.textContaining('Renews until'), findsNWidgets(2));
    });

    testWidgets('« Voir les offres » ouvre le catalogue, sans prix ni achat', (
      tester,
    ) async {
      _tall(tester);
      final manager = _Manager()..catalog = _catalog();
      await tester.pumpWidget(
        _app(SubscriptionsHubPage(host: StudioSubscriptionsHost(manager.api))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
      expect(find.text('Pro plan'), findsOneWidget);
      expect(find.text('Everything for serious bots'), findsOneWidget);
      expect(find.text('Four bots'), findsOneWidget);
      expect(find.text('No ads'), findsOneWidget);
      expect(find.text('Restore purchases'), findsNothing);
      expect(
        find.text(
          'This plan is currently unavailable. Please try again later.',
        ),
        findsNothing,
      );
      expect(
        find.text('Subscriptions are currently available on mobile only.'),
        findsWidgets,
      );
      expect(find.text('Privacy policy'), findsOneWidget);
    });

    testWidgets('sans catalogue publié : la liste des avantages Premium', (
      tester,
    ) async {
      _tall(tester);
      final manager = _Manager();
      await tester.pumpWidget(
        _app(SubscriptionsHubPage(host: StudioSubscriptionsHost(manager.api))),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionPage), findsOneWidget);
      expect(find.text('Annual'), findsNothing);
      expect(find.text('Monthly'), findsNothing);
      final tr = AppLocalizations.of(
        tester.element(find.byType(SubscriptionPage)),
      );
      expect(find.text(tr.subscription_feature_no_ads_title), findsOneWidget);
    });
  });

  group('crédits IA (écran de l\'app) sur le Manager', () {
    testWidgets('solde, répartition, historique paginé, sans roulette', (
      tester,
    ) async {
      _tall(tester);
      final manager = _Manager();
      await tester.pumpWidget(
        _app(AICreditsPage(host: StudioAiCreditsHost(manager.api))),
      );
      await tester.pumpAndSettle();

      expect(find.text('AI credits'), findsOneWidget);
      expect(find.text('Purchases'), findsOneWidget);
      expect(find.text('Credit history'), findsOneWidget);
      expect(find.text('Admin grant'), findsWidgets);
      // Ni roulette, ni publicité, ni pack : capacités absentes de l'hôte.
      expect(find.text('Spin the wheel'), findsNothing);
      expect(find.textContaining('Watch an ad'), findsNothing);
      expect(find.text('Open conversation'), findsNothing);

      expect(manager.calls, contains('GET /gateway/ai/ledger?offset=0'));
      await tester.scrollUntilVisible(
        find.text('Next'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(manager.calls, contains('GET /gateway/ai/ledger?offset=50'));
    });

    testWidgets('portefeuille illisible : « indisponible »', (tester) async {
      _tall(tester);
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient((r) async => _json({'error': 'down'}, 503)),
      )..accessToken = ({bool force = false}) async => 'tok';
      await tester.pumpWidget(
        _app(AICreditsPage(host: StudioAiCreditsHost(api))),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI credits unavailable. Try again.'), findsOneWidget);
    });
  });

  group('refus de formule et verrous Premium', () {
    Future<void> pumpWithScope(
      WidgetTester tester,
      _Manager manager,
      Widget child,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _app(
          StudioSubscriptionsScope(
            host: StudioSubscriptionsHost(manager.api),
            child: Scaffold(body: child),
          ),
        ),
      );
    }

    testWidgets(
      'quota de bots : la boîte de l\'app, puis « Voir les offres »',
      (tester) async {
        final manager = _Manager();
        late BuildContext ctx;
        await pumpWithScope(
          tester,
          manager,
          Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox();
            },
          ),
        );
        const bot = StudioBot(id: '1', name: 'Mod');
        unawaited(
          explainBotError(
            ctx,
            bot,
            const StudioApiException(
              'personal bot limit reached',
              statusCode: 403,
              code: 'bot_quota_reached',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(PlanLimitDialog), findsOneWidget);
        // Pas de publicité dans le navigateur : jamais de « continuer financé
        // par pub », même sur un compte gratuit.
        expect(find.text('Start ad-funded'), findsNothing);
        await tester.tap(find.text('View plans'));
        await tester.pumpAndSettle();
        expect(find.byType(SubscriptionsHubPage), findsOneWidget);
        expect(manager.calls, contains('GET /gateway/runtime'));
      },
    );

    testWidgets('verrou Premium : bouton « Voir les offres » vers le hub', (
      tester,
    ) async {
      final manager = _Manager();
      await pumpWithScope(
        tester,
        manager,
        const PremiumGate(
          feature: StudioFeature.scheduler,
          plan: StudioPlan.free,
          child: Text('contenu'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('contenu'), findsNothing);
      await tester.tap(find.text('View plans'));
      await tester.pumpAndSettle();
      expect(find.byType(SubscriptionsHubPage), findsOneWidget);
    });

    testWidgets('hors de la coque : pas de bouton vers un hub absent', (
      tester,
    ) async {
      _tall(tester);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: PremiumGate(
              feature: StudioFeature.scheduler,
              plan: StudioPlan.free,
              child: Text('contenu'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('View plans'), findsNothing);
    });

    test('applications hébergées : les formules deviennent consultables', () {
      final api = _Manager().api;
      expect(StudioHostedContainersHost(api).upsellMode, HostedUpsellMode.none);
      expect(
        StudioHostedContainersHost(
          api,
          subscriptions: StudioSubscriptionsHost(api),
        ).upsellMode,
        HostedUpsellMode.plans,
      );
    });
  });

  group('réglages du Studio', () {
    testWidgets('la carte « Abonnements » ouvre le hub', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SessionStore().save(
        StudioSession(
          accessToken: 'tok',
          refreshToken: 'ref',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          username: 'ana',
        ),
      );
      final manager = _Manager()
        ..runtime = {'plan': 'PREMIUM', 'display_name': 'Pro'};
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: manager.client,
      );
      final locale = LocaleController();
      await locale.set(const Locale('en'));
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        StudioApp(
          auth: AuthController(api: api),
          locale: locale,
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.tap(find.text('Settings'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(SubscriptionsSettingsCard), findsOneWidget);
      expect(find.text('Subscriptions & billing'), findsOneWidget);
      await tester.tap(find.text('Subscriptions & billing'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(SubscriptionsHubPage), findsOneWidget);
      expect(find.text('Active'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
