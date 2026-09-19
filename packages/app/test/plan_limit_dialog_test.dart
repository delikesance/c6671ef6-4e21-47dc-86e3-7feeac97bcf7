// L'avertissement de dépassement de formule : sur un compte ad-financé, un bot
// « en plus » n'est pas refusé, il tourne financé par pub — mais l'utilisateur doit
// être prévenu AVANT de lancer, avec la possibilité d'aller voir les offres.
//
// Règle produit : un compte premium ne regarde JAMAIS de publicité. Son quota de
// démarrage est une limite stricte, la seule sortie est de changer de formule.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/plan_limit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpDialogHost(WidgetTester tester, PlanLimitBlock block) async {
  // Le runner de test s'exécute sur un poste de travail : sans ça, l'application se
  // croit sur desktop (« premium par défaut ») et masquerait la voie pub.
  SubscriptionService.debugSetDesktopForTests(false);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => showPlanLimitDialog(context, block),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'un compte ad-financé au-delà du quota prévient et propose le financement par pub',
    (tester) async {
      SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
      SubscriptionService.debugSetPlanQuotasForTests(maxBots: 2);

      await _pumpDialogHost(tester, PlanLimitBlock.planBotQuotaReached);

      expect(find.textContaining('fait tourner 2 bots'), findsOneWidget);
      expect(
        find.textContaining('gagné en regardant des pubs'),
        findsOneWidget,
      );

      await tester.tap(find.text('Démarrer financé par pub'));
      await tester.pumpAndSettle();
      expect(find.text('Démarrer financé par pub'), findsNothing);
    },
  );

  testWidgets('un compte premium ne se voit jamais proposer de publicité', (
    tester,
  ) async {
    SubscriptionService.debugSetLocalSubscriptionForTests(
      active: true,
      productId: 'bot_creator_premium_monthly',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
    SubscriptionService.debugSetPlanQuotasForTests(maxBots: 2);

    await _pumpDialogHost(tester, PlanLimitBlock.planBotQuotaReached);

    expect(find.text('Démarrer financé par pub'), findsNothing);
    expect(
      find.textContaining('passez à une formule supérieure'),
      findsOneWidget,
    );
    expect(find.text('Voir les offres'), findsOneWidget);
  });

  testWidgets(
    'une formule sans bots perso reste un refus, sans financement par pub',
    (tester) async {
      SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
      SubscriptionService.debugSetPlanQuotasForTests(
        maxBots: 0,
        allowOwnBots: false,
      );

      await _pumpDialogHost(tester, PlanLimitBlock.planExcludesOwnBots);

      expect(
        find.text('Bots perso non inclus dans votre formule'),
        findsOneWidget,
      );
      expect(find.text('Démarrer financé par pub'), findsNothing);
      expect(find.text('Voir les offres'), findsOneWidget);
    },
  );
}
