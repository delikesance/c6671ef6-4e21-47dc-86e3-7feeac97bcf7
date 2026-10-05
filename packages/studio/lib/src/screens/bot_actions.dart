import 'package:flutter/material.dart';

import '../api/start_refusal.dart';
import '../api/studio_api.dart';

/// Explique un échec de lancement/arrêt : refus de formule traduit, sinon le
/// message du serveur.
Future<void> explainBotError(
  BuildContext context,
  StudioBot bot,
  Object error,
) {
  final refusal = StartRefusal.fromError(error);
  final title =
      refusal?.title ??
      (bot.running
          ? "Impossible d'arrêter le bot"
          : 'Impossible de lancer le bot');
  final body =
      refusal?.body ?? (error is StudioApiException ? error.message : '$error');
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
