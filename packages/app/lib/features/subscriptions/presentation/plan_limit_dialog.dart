// Moved to package:bot_creator_ui (shared with Studio) : la boîte est
// `PlanLimitDialog` du paquet. Ce fichier garde l'ancienne signature
// (`PlanLimitDialog(block:)`, `showPlanLimitDialog(context, block)`) : l'app y
// ajoute ce que SEUL son état local sait (compte ad-financé, plafond de bots) et
// la traduction d'un refus serveur (`PlanLimitRefusal`, type du client réseau).
import 'package:bot_creator/core/network/remote_runtime.dart'
    show PlanLimitRefusal;
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

export 'package:bot_creator_ui/src/subscriptions/plan_limit_dialog.dart'
    show PlanLimitAction;

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
    // Un compte premium ne regarde JAMAIS de publicité : au-delà de son quota, le
    // démarrage est refusé et la seule sortie est de changer de formule. Un compte
    // ad-financé, lui, peut dépasser son quota en gagnant du temps par une pub.
    return ui.PlanLimitDialog(
      block: block,
      adFunded: !SubscriptionService.isSubscribed,
      maxBots: SubscriptionService.activePlanMaxBots ?? 0,
    );
  }
}

/// Affiche le refus de la formule, ou l'avertissement de financement par pub.
///
/// Renvoie l'action choisie : c'est à l'appelant d'ouvrir les offres ou de lancer
/// le bot avec son propre contexte.
Future<ui.PlanLimitAction> showPlanLimitDialog(
  BuildContext context,
  PlanLimitBlock block,
) async {
  final action = await showDialog<ui.PlanLimitAction>(
    context: context,
    builder: (_) => PlanLimitDialog(block: block),
  );
  return action ?? ui.PlanLimitAction.dismissed;
}
