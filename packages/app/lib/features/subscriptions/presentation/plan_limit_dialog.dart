import 'package:flutter/material.dart';

import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:bot_creator/core/network/remote_runtime.dart'
    show PlanLimitRefusal;
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';

/// Ce que l'utilisateur a choisi devant un refus de la formule.
enum PlanLimitAction {
  /// L'écran s'est fermé sans décision.
  dismissed,

  /// Voir les offres (ouvrir le hub des abonnements).
  viewOffers,

  /// Continuer quand même : le bot dépassera la formule et tournera financé par pub.
  continueAdFunded,
}

/// Explique qu'un démarrage est refusé par la formule du compte, ou qu'il sera
/// financé par pub parce qu'il dépasse le quota.
///
/// Les quotas d'une formule s'appliquent **au démarrage** : c'est donc le dernier
/// moment utile pour montrer la sortie de secours (les offres), ou pour prévenir
/// honnêtement qu'un bot en plus consommera du temps gagné en regardant des pubs.
class PlanLimitDialog extends StatelessWidget {
  const PlanLimitDialog({required this.block, super.key});

  final PlanLimitBlock block;

  /// Retrouve l'explication locale à partir d'un refus renvoyé par le serveur.
  ///
  /// Le serveur reste seul juge : s'il refuse alors que l'écran local croyait le
  /// démarrage possible (formule changée entre-temps), l'utilisateur voit la
  /// même explication que s'il avait été bloqué en amont.
  static PlanLimitBlock blockFromRefusal(PlanLimitRefusal refusal) {
    switch (refusal) {
      case PlanLimitRefusal.excludesOwnBots:
        return PlanLimitBlock.planExcludesOwnBots;
      case PlanLimitRefusal.botQuotaReached:
        return PlanLimitBlock.planBotQuotaReached;
      case PlanLimitRefusal.excludesTurnkey:
        return PlanLimitBlock.planExcludesTurnkey;
      case PlanLimitRefusal.turnkeyQuotaReached:
        return PlanLimitBlock.planTurnkeyQuotaReached;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    // Au-delà du quota de la formule, le démarrage n'est pas refusé : le bot tourne
    // financé par pub. On prévient et on laisse continuer, au lieu de bloquer.
    final adFunded = block == PlanLimitBlock.planBotQuotaReached;
    final (String title, String description) = switch (block) {
      PlanLimitBlock.planExcludesOwnBots => (
        tr.plan_limit_own_bots_title,
        tr.plan_limit_own_bots_desc,
      ),
      PlanLimitBlock.planBotQuotaReached => (
        tr.plan_limit_bot_quota_title,
        tr.plan_limit_bot_quota_ad_funded_desc(
          SubscriptionService.activePlanMaxBots ?? 0,
        ),
      ),
      PlanLimitBlock.planExcludesTurnkey => (
        tr.plan_limit_turnkey_title,
        tr.plan_limit_turnkey_desc,
      ),
      PlanLimitBlock.planTurnkeyQuotaReached => (
        tr.plan_limit_turnkey_quota_title,
        tr.plan_limit_turnkey_quota_desc,
      ),
    };

    return AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(PlanLimitAction.dismissed),
          child: Text(tr.common_close),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(PlanLimitAction.viewOffers),
          child: Text(tr.plan_limit_view_offers),
        ),
        if (adFunded)
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(PlanLimitAction.continueAdFunded),
            child: Text(tr.plan_limit_quota_continue_ad),
          ),
      ],
    );
  }
}

/// Affiche le refus de la formule, ou l'avertissement de financement par pub.
///
/// Renvoie l'action choisie : c'est à l'appelant d'ouvrir les offres ou de lancer
/// le bot avec son propre contexte.
Future<PlanLimitAction> showPlanLimitDialog(
  BuildContext context,
  PlanLimitBlock block,
) async {
  final action = await showDialog<PlanLimitAction>(
    context: context,
    builder: (_) => PlanLimitDialog(block: block),
  );
  return action ?? PlanLimitAction.dismissed;
}
