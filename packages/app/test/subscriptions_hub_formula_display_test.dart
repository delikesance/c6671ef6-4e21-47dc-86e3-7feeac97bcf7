// Deux cartes d'offres, deux familles de capacités — et le nom de la formule doit aller sur
// celle dont il porte l'offre.
//
// Cas réel à l'origine de ce test : un compte dont la formule serveur s'appelle
// « Host One App » (une offre d'APPLICATIONS HÉBERGÉES) affichait ce nom sous « Bot Premium »
// pendant que la carte « Applications hébergées » restait « Non abonné » — parce qu'elle
// n'écoutait que le reçu du store, jamais la formule accordée par le serveur.
//
// Ce que ce test verrouille :
// - le nom d'une formule d'hébergement s'affiche sur la carte du bas, avec son plafond ;
// - la carte Bot Premium n'annonce plus que la capacité bot (elle reste « Actif », la
//   formule accorde bien le premium) ;
// - la carte d'hébergement s'allume sur la formule serveur, sans reçu store ;
// - la mention « Géré par le serveur » apparaît des deux côtés.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscriptions_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    SubscriptionService.debugSetDesktopForTests(false);
    SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
    SubscriptionService.debugSetPlanIdentityForTests();
    SubscriptionService.debugSetPlanQuotasForTests(fromServer: false);
    HostedAppSubscriptionService.debugSetServerGrantForTests(granted: false);
  });

  Future<void> pumpHub(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // Locale forcée : les assertions portent sur les libellés affichés, et
        // l'environnement de test rend l'anglais par défaut.
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const SubscriptionsHubPage(),
      ),
    );
    // Le hub rafraîchit ses états au montage : ces appels touchent de vraies APIs
    // asynchrones (préférences, réseau) qui ne progressent pas en temps simulé. Les
    // fenêtres de temps réel ci-dessous les laissent aboutir — en test comme en pratique,
    // elles retombent sur l'état injecté (aucune session configurée).
    for (var i = 0; i < 40; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets(
    'une formule d\'hébergement affiche son nom en bas, pas sous Bot Premium',
    (tester) async {
      // Compte premium dont la formule serveur est « Host One App » : bots illimités et
      // une application hébergée.
      SubscriptionService.debugSetLocalSubscriptionForTests(active: true);
      SubscriptionService.debugSetPlanIdentityForTests(
        displayName: 'Host One App',
        tierCode: 'HOST_ONE_APP',
        provider: 'admin_remote',
      );
      SubscriptionService.debugSetPlanQuotasForTests(
        maxBots: 0,
        maxTurnkeyBots: 1,
      );
      HostedAppSubscriptionService.debugSetServerGrantForTests(
        granted: true,
        maxContainers: 1,
        planTierCode: 'HOST_ONE_APP',
      );

      await pumpHub(tester);

      // La carte du bas porte le nom de la formule et son plafond.
      expect(
        find.textContaining('Host One App'),
        findsOneWidget,
        reason:
            'le nom de la formule d\'hébergement doit apparaître (sur la carte du bas)',
      );
      expect(
        find.textContaining('1 bot hébergé'),
        findsOneWidget,
        reason: 'la capacité d\'hébergement vient de la formule serveur',
      );

      // La carte du haut n'annonce que la capacité bot, plus le nom de la formule.
      expect(
        find.textContaining('Bots illimités'),
        findsOneWidget,
        reason:
            'la carte Bot Premium parle de bots ; le nom d\'une offre d\'hébergement n\'y a '
            'pas sa place',
      );

      // Les deux cartes sont actives, et signalent que c'est le serveur qui gère.
      expect(find.text('Géré par le serveur'), findsNWidgets(2));
    },
  );

  testWidgets('un formulaire de bots garde son nom sur la carte du haut', (
    tester,
  ) async {
    // Formule qui n'inclut PAS les hébergements : son nom reste sur la carte Bot Premium.
    SubscriptionService.debugSetLocalSubscriptionForTests(active: true);
    SubscriptionService.debugSetPlanIdentityForTests(
      displayName: 'Pro',
      tierCode: 'PRO',
    );
    SubscriptionService.debugSetPlanQuotasForTests(
      maxBots: 5,
      maxTurnkeyBots: 0,
    );
    HostedAppSubscriptionService.debugSetServerGrantForTests(granted: false);

    await pumpHub(tester);

    expect(
      find.textContaining('Pro'),
      findsOneWidget,
      reason: 'une formule de bots s\'affiche sur la carte des bots',
    );
    expect(
      find.textContaining('Host One App'),
      findsNothing,
      reason: 'aucune formule d\'hébergement ici',
    );
  });

  testWidgets('sans droit serveur ni reçu, la carte d\'hébergement est inactive', (
    tester,
  ) async {
    SubscriptionService.debugSetLocalSubscriptionForTests(active: true);
    SubscriptionService.debugSetPlanIdentityForTests(displayName: 'Pro');
    SubscriptionService.debugSetPlanQuotasForTests(maxBots: 5);
    HostedAppSubscriptionService.debugSetServerGrantForTests(granted: false);

    await pumpHub(tester);

    // Une seule mention « Géré par le serveur » : celle de Bot Premium.
    expect(find.text('Géré par le serveur'), findsOneWidget);
    // Et la carte d'hébergement propose d'ailleurs de s'abonner.
    expect(find.textContaining('S\'abonner'), findsWidgets);
  });
}
