// Moved to package:bot_creator_ui (shared with Studio) : l'écran des offres est
// `SubscriptionPage` du paquet, monté sur `AppSubscriptionsHost`. Ce fichier
// garde l'ancienne signature (`SubscriptionPage.show(context)`), l'analytique
// d'entonnoir et le repli « indisponible sur cette plateforme » propres à l'app.
import 'dart:async';

import 'package:bot_creator/core/analytics/monetization_funnel.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/app_subscriptions_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Full-screen page (or bottom-sheet) for purchasing a premium subscription.
class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  /// Show the subscription page as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    if (!SubscriptionService.supportsNativeBilling) {
      // Repli explicite : sans `ScaffoldMessenger` (arbre pas encore monté,
      // écran détaché), l'échec est JOURNALISÉ — jamais avalé par un `?.` muet.
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        unawaited(
          AppDiagnostics.logInfo(
            'Subscriptions: platform-unavailable message not shown '
            '(no ScaffoldMessenger)',
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.tr.subscription_not_available_on_platform),
          ),
        );
      }
      return Future<void>.value();
    }

    unawaited(MonetizationFunnel.subscriptionPageView());
    return ui.SubscriptionPage.show(context, const AppSubscriptionsHost());
  }

  @override
  Widget build(BuildContext context) =>
      const ui.SubscriptionPage(host: AppSubscriptionsHost());
}
