// Moved to package:bot_creator_ui (shared with Studio) : l'écran est
// `SubscriptionsHubPage` du paquet, monté sur `AppSubscriptionsHost`. Ce fichier
// garde l'ancienne signature (`const SubscriptionsHubPage()`, `.open(context)`)
// et le repli « indisponible sur cette plateforme » propre à l'app.
import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/app_subscriptions_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Central page listing bot premium and hosted-app subscriptions.
class SubscriptionsHubPage extends StatelessWidget {
  const SubscriptionsHubPage({super.key});

  static Future<void> open(BuildContext context) {
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
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SubscriptionsHubPage()),
    );
  }

  @override
  Widget build(BuildContext context) =>
      const ui.SubscriptionsHubPage(host: AppSubscriptionsHost());
}
