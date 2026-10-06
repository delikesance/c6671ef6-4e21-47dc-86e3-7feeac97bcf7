import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';

/// Pourquoi un démarrage est refusé par la formule du compte (miroir des refus
/// 403 du Manager : `own_bots_not_allowed`, `bot_quota_reached`,
/// `turnkey_not_allowed`, `turnkey_quota_reached`).
enum PlanLimitBlock {
  planExcludesOwnBots,
  planBotQuotaReached,
  planExcludesTurnkey,
  planTurnkeyQuotaReached,
}

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
///
/// [adFunded] : le compte est ad-financé (non premium) et le bot dépasse son
/// quota, l'écran propose alors de continuer financé par pub ([maxBots] est le
/// plafond cité). Un compte premium ne regarde JAMAIS de publicité : sa limite
/// est stricte et la seule sortie est de changer de formule. Un client sans
/// publicité (le Studio) laisse [adFunded] à faux : le serveur a refusé, il n'y
/// a rien à « continuer ».
class PlanLimitDialog extends StatelessWidget {
  const PlanLimitDialog({
    required this.block,
    this.adFunded = false,
    this.maxBots = 0,
    super.key,
  });

  final PlanLimitBlock block;
  final bool adFunded;
  final int maxBots;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final funded = adFunded && block == PlanLimitBlock.planBotQuotaReached;
    final (String title, String description) = switch (block) {
      PlanLimitBlock.planExcludesOwnBots => (
        tr.plan_limit_own_bots_title,
        tr.plan_limit_own_bots_desc,
      ),
      PlanLimitBlock.planBotQuotaReached => (
        tr.plan_limit_bot_quota_title,
        funded
            ? tr.plan_limit_bot_quota_ad_funded_desc(maxBots)
            : tr.plan_limit_bot_quota_desc,
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
        if (funded)
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
  PlanLimitBlock block, {
  bool adFunded = false,
  int maxBots = 0,
}) async {
  final action = await showDialog<PlanLimitAction>(
    context: context,
    builder: (_) =>
        PlanLimitDialog(block: block, adFunded: adFunded, maxBots: maxBots),
  );
  return action ?? PlanLimitAction.dismissed;
}
