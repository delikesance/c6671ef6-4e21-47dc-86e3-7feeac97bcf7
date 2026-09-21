// TEMPS D'HÉBERGEMENT : l'écran de bot doit l'offrir HONNÊTEMENT.
//
// Défauts mesurés par le propriétaire (capture à l'appui), sur l'écran d'un bot :
//   A. un bouton « + Ajouter du temps » s'affichait sur un POSTE DE TRAVAIL, alors
//      que la pub récompensée est un geste MOBILE (le flux publicitaire ne fait
//      rien hors Android/iOS) : un geste impossible était offert ;
//   B. un ABONNÉ (pubs supprimées) voyait toujours ET le compte à rebours ET le
//      bouton : rien ne les masquait ;
//   C. un bot exécuté par CE POSTE pouvait afficher une échéance d'hébergement ;
//   D. la date « 14 févr. 2038 » n'était pas une échéance mais le STOCK de minutes
//      converti en date (138 mois) — `DateTime.now().add(Duration(minutes: solde))`.
//
// Les quatre cas dictés par le propriétaire sont verrouillés ici, plus la
// non-régression mobile (le bouton reste : c'est là que se regardent les pubs).
// Aucun transport réel : la formule vient d'un état poussé, la plateforme du seam
// partagé, l'association du bot de `RunnerSettings`.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/logic/hosting_time_offer.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _botHeberge = 'bot-heberge';
const String _botLocal = 'bot-local';

/// 5 997 142 minutes : le solde exact du rapport de bug (138 mois).
const int _soldeDuBug = 5997142;

const List<({String value, String label})> _breakdown = <({
  String value,
  String label,
})>[
  (value: '138', label: 'Mois'),
  (value: '24', label: 'Jours'),
  (value: '16', label: 'Heures'),
  (value: '52', label: 'Min'),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppLocalizations tr;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RunnerSettings.resetAssociationsForTests();
    await SubscriptionService.debugResetForTests();
  });

  tearDown(() async {
    RunnerSettings.resetAssociationsForTests();
    // Rend la plateforme RÉELLE : sans ça, un test suivant hériterait du forçage.
    SubscriptionService.debugSetDesktopForTests(null);
    await SubscriptionService.debugResetForTests();
  });

  Widget hostApp(Widget child) {
    return MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(brightness: Brightness.dark),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );
  }

  HomeHostingTimeCard card({
    required HostingTimeOffer offer,
    String overline = 'Temps restant',
    String headline = '138 mois, 24 jours, 16 heures, 52 minutes',
    List<({String value, String label})> breakdown = _breakdown,
    VoidCallback? onAddTime,
  }) {
    return HomeHostingTimeCard(
      statusLabel: 'Session active',
      statusColor: AppTheme.online,
      overline: overline,
      headline: headline,
      segments: breakdown,
      offer: offer,
      onAddTime: onAddTime ?? () {},
    );
  }

  /// État de compte poussé par le serveur — le seul chemin qui décide de la
  /// formule sans réseau (même levier que `desktop_server_plan_test.dart`).
  Future<void> serveurAnnonce(String plan) async {
    await SubscriptionService.applyPushedAccountState(<String, dynamic>{
      'plan': plan,
    });
  }

  group('CAS 1 — poste de travail, bot hébergé, non abonné', () {
    testWidgets(
      'l’explication remplace le bouton, et AUCUNE date n’est inventée depuis le solde',
      (tester) async {
        SubscriptionService.debugSetDesktopForTests(true);
        RunnerSettings.associateBotWithRunner(_botHeberge, 'manager');
        await serveurAnnonce('FREE');

        // Le serveur ne fournit AUCUNE échéance : que des minutes en stock.
        final plan = desktopHostingTimePlan(
          botId: _botHeberge,
          serverReportsRunning: true,
          serverSessionExpiresAt: null,
          premiumFunded: false,
        );

        expect(plan, isNotNull, reason: 'sur un poste, la décision est prise');
        expect(plan!.offer, HostingTimeOffer.adsOnMobileOnly);
        expect(plan.showsAddTimeButton, isFalse);
        expect(plan.showsMobileAdsExplanation, isTrue);
        expect(
          plan.deadline,
          HostingDeadline.balanceOnly,
          reason: 'sans échéance serveur, il ne reste que le solde',
        );
        expect(
          resolveHostingCardCopy(
            plan,
            botLaunched: true,
            serverSessionExpiresAt: null,
          ),
          HostingCardCopy.remainingTime,
          reason:
              'la carte écrit un TEMPS RESTANT : la date de 2038 venait d’un solde',
        );

        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          hostApp(card(offer: plan.offer, overline: tr.home_hosting_remaining_overline)),
        );
        await tester.pumpAndSettle();

        expect(
          find.widgetWithText(FilledButton, tr.home_add_time),
          findsNothing,
          reason: 'aucun geste impossible offert : la pub est un geste mobile',
        );
        expect(find.text(tr.home_add_time_mobile_only), findsOneWidget);
        expect(find.text('EXPIRATION PRÉVUE'), findsNothing);
        expect(
          find.textContaining('2038'),
          findsNothing,
          reason: 'le stock de minutes ne doit produire aucune date',
        );
        expect(find.text('138 mois, 24 jours, 16 heures, 52 minutes'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'pas de débordement à 320 dp');
      },
    );

    testWidgets(
      'carte « poste de travail » : la date du SERVEUR reste affichée telle quelle',
      (tester) async {
        SubscriptionService.debugSetDesktopForTests(true);
        RunnerSettings.associateBotWithRunner(_botHeberge, 'manager');
        await serveurAnnonce('FREE');

        final echeance = DateTime.utc(2026, 3, 4, 16, 30);
        final plan = desktopHostingTimePlan(
          botId: _botHeberge,
          serverReportsRunning: true,
          serverSessionExpiresAt: echeance,
          premiumFunded: false,
        );

        expect(plan!.deadline, HostingDeadline.serverProvided);
        expect(
          resolveHostingCardCopy(
            plan,
            botLaunched: true,
            serverSessionExpiresAt: echeance,
          ),
          HostingCardCopy.serverDeadline,
        );

        await tester.pumpWidget(
          hostApp(
            card(
              offer: plan.offer,
              overline: tr.home_hosting_expiration_expected,
              headline: '4 mars 2026 à 17:30',
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('4 mars 2026 à 17:30'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, tr.home_add_time), findsNothing);
        expect(find.text(tr.home_add_time_mobile_only), findsOneWidget);
      },
    );
  });

  group('CAS 2 — abonné (pubs supprimées)', () {
    testWidgets(
      'état « illimité » : ni bouton, ni compte à rebours, et il prime sur l’explication desktop',
      (tester) async {
        SubscriptionService.debugSetDesktopForTests(true);
        RunnerSettings.associateBotWithRunner(_botHeberge, 'manager');
        await serveurAnnonce('PREMIUM');

        final plan = desktopHostingTimePlan(
          botId: _botHeberge,
          serverReportsRunning: true,
          serverSessionExpiresAt: null,
          premiumFunded: false,
        );

        expect(plan!.offer, HostingTimeOffer.unlimited);
        expect(plan.showsAddTimeButton, isFalse);
        expect(
          plan.showsMobileAdsExplanation,
          isFalse,
          reason:
              '« illimité » prime : un abonné sur un poste ne lit pas l’explication des pubs',
        );
        expect(plan.showsUnlimitedState, isTrue);
        expect(plan.showsHostingCard, isTrue);
        expect(
          resolveHostingCardCopy(
            plan,
            botLaunched: true,
            serverSessionExpiresAt: null,
          ),
          HostingCardCopy.unlimited,
        );

        await tester.pumpWidget(
          hostApp(
            card(
              offer: plan.offer,
              overline: tr.home_hosting_unlimited_overline,
              headline: tr.home_hosting_unlimited_headline,
              breakdown: const <({String value, String label})>[],
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(FilledButton), findsNothing);
        expect(find.text('EXPIRATION PRÉVUE'), findsNothing);
        expect(
          find.text('MOIS'),
          findsNothing,
          reason: 'rien n’expire : aucun décompte ne doit apparaître',
        );
        expect(find.text(tr.home_add_time_mobile_only), findsNothing);
        expect(find.text(tr.home_hosting_unlimited_headline), findsOneWidget);
      },
    );

    testWidgets(
      'hébergement déjà payé par la formule (`funding_mode: premium`) : même état illimité',
      (tester) async {
        SubscriptionService.debugSetDesktopForTests(true);
        RunnerSettings.associateBotWithRunner(_botHeberge, 'manager');
        await serveurAnnonce('FREE');

        final plan = desktopHostingTimePlan(
          botId: _botHeberge,
          serverReportsRunning: true,
          serverSessionExpiresAt: null,
          premiumFunded: true,
        );

        expect(
          plan!.offer,
          HostingTimeOffer.unlimited,
          reason:
              'le serveur dit que la formule paie cet hébergement : rien à obtenir, '
              'et surtout pas « 0 minute restante »',
        );
      },
    );
  });

  group('CAS 3 — bot exécuté par ce poste', () {
    testWidgets('aucune échéance, aucune date : la carte n’a rien à annoncer', (
      tester,
    ) async {
      SubscriptionService.debugSetDesktopForTests(true);
      RunnerSettings.associateBotWithRunner(_botLocal, 'local');
      await serveurAnnonce('FREE');

      final plan = desktopHostingTimePlan(
        botId: _botLocal,
        serverReportsRunning: true,
        // Même quand le serveur annonce une échéance, un bot exécuté ICI ne
        // consomme pas le solde cloud : il n'a donc rien à en dire.
        serverSessionExpiresAt: DateTime.utc(2038, 2, 14, 17, 8),
        premiumFunded: false,
      );

      expect(plan!.deadline, HostingDeadline.none);
      expect(plan.showsServerDeadline, isFalse);
      expect(
        plan.showsHostingCard,
        isFalse,
        reason: 'un bot local n’a ni échéance ni réserve à annoncer',
      );
      expect(plan.showsAddTimeButton, isFalse);
    });

    testWidgets('le solde seul ne crée jamais une source d’hébergement', (
      tester,
    ) async {
      SubscriptionService.debugSetDesktopForTests(true);
      RunnerSettings.associateBotWithRunner(_botLocal, 'local');
      await serveurAnnonce('FREE');

      final plan = desktopHostingTimePlan(
        botId: _botLocal,
        serverReportsRunning: false,
        serverSessionExpiresAt: DateTime.utc(2038, 2, 14, 17, 8),
        premiumFunded: false,
      );

      // Ceinture et bretelles du bug C : la résolution de source (brique partagée)
      // et la décision d'échéance doivent dire la même chose.
      expect(plan!.deadline, HostingDeadline.none);
      expect(plan.showsHostingCard, isFalse);
      expect(_soldeDuBug, greaterThan(0));
    });
  });

  group('CAS 4 — mobile non abonné : le bouton RESTE', () {
    testWidgets('hors poste de travail, rien n’est décidé ici et le bouton reste', (
      tester,
    ) async {
      // Le seam est forcé DANS LES DEUX SENS : sans ça, `isDesktopRunPlatform`
      // retombe sur le vrai système d'exploitation de la machine de test (Linux).
      SubscriptionService.debugSetDesktopForTests(false);
      RunnerSettings.associateBotWithRunner(_botHeberge, 'manager');
      await serveurAnnonce('FREE');

      expect(
        desktopHostingTimePlan(
          botId: _botHeberge,
          serverReportsRunning: true,
          serverSessionExpiresAt: null,
          premiumFunded: false,
        ),
        isNull,
        reason:
            'hors poste, l’écran garde sa règle historique : le bouton y reste',
      );
      expect(
        resolveHostingTimeOffer(
          isDesktop: false,
          hasNoAds: false,
          premiumFunded: false,
        ),
        HostingTimeOffer.addTime,
      );

      final plan = HostingTimePlan(
        offer: resolveHostingTimeOffer(
          isDesktop: false,
          hasNoAds: false,
          premiumFunded: false,
        ),
        deadline: resolveHostingDeadline(
          runOrigin: null,
          serverProvidesDeadline: false,
        ),
      );

      await tester.pumpWidget(
        hostApp(card(offer: plan.offer, overline: tr.home_hosting_remaining_overline)),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, tr.home_add_time),
        findsOneWidget,
        reason: 'non-régression mobile : c’est là que se regardent les pubs',
      );
      expect(find.text(tr.home_add_time_mobile_only), findsNothing);
    });
  });
}
