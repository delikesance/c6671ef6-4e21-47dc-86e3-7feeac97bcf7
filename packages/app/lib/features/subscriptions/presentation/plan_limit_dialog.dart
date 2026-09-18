import 'package:flutter/material.dart';

import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:bot_creator/core/network/remote_runtime.dart'
    show PlanLimitRefusal;
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';

/// Explique qu'un démarrage est refusé par la formule du compte.
///
/// Les quotas d'une formule s'appliquent **au démarrage** : c'est donc le dernier
/// moment utile pour montrer la sortie de secours (les offres), plutôt que de
/// laisser l'utilisateur buter sur un refus serveur sans explication.
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
    final (String title, String description) = switch (block) {
      PlanLimitBlock.planExcludesOwnBots => (
        tr.plan_limit_own_bots_title,
        tr.plan_limit_own_bots_desc,
      ),
      PlanLimitBlock.planBotQuotaReached => (
        tr.plan_limit_bot_quota_title,
        tr.plan_limit_bot_quota_desc,
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
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr.common_close),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(tr.plan_limit_view_offers),
        ),
      ],
    );
  }
}

/// Affiche le refus de démarrage lié à la formule.
///
/// Renvoie `true` quand l'utilisateur demande à voir les offres : c'est à
/// l'appelant d'ouvrir l'écran des abonnements, avec son propre contexte.
Future<bool?> showPlanLimitDialog(BuildContext context, PlanLimitBlock block) {
  return showDialog<bool>(
    context: context,
    builder: (_) => PlanLimitDialog(block: block),
  );
}
