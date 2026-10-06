import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/start_refusal.dart';
import '../api/studio_api.dart';
import '../editor/studio_subscriptions_host.dart';
import '../l10n_ext.dart';

/// Explique un échec de lancement/arrêt : refus de formule traduit, sinon le
/// message du serveur.
Future<void> explainBotError(
  BuildContext context,
  StudioBot bot,
  Object error,
) {
  final refusal = StartRefusal.fromError(error);
  final l = context.l10n;
  // Un refus de formule est expliqué par la boîte de l'app, avec sa sortie
  // « Voir les offres » (le hub des abonnements, en lecture seule ici). Le
  // Studio n'a pas de publicité : le serveur a refusé, il n'y a rien à
  // « continuer », donc jamais de financement par pub.
  final block = refusal?.planLimit;
  if (block != null) {
    return _explainPlanLimit(context, block);
  }
  final title =
      refusal?.title(l, context.tr) ??
      (bot.running ? l.botStopFailed : l.botStartFailed);
  final body =
      refusal?.body(l, context.tr) ??
      (error is StudioApiException ? error.message : '$error');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.tr.common_close),
        ),
      ],
    ),
  );
}

Future<void> _explainPlanLimit(
  BuildContext context,
  PlanLimitBlock block,
) async {
  final action = await showPlanLimitDialog(context, block);
  if (action == PlanLimitAction.viewOffers && context.mounted) {
    await openStudioSubscriptions(context);
  }
}
