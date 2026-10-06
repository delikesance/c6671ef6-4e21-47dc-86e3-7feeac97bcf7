import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../api/start_refusal.dart';
import '../api/studio_api.dart';
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
