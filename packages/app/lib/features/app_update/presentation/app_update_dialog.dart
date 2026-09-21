// Dialogue de proposition de mise à jour.
//
// NON BLOQUANT : barrière franchissable au tap, « Plus tard » toujours
// disponible, aucune action de l'app n'est suspendue. Et il n'est affiché
// qu'UNE fois par version disponible — la décision vit dans
// `AppUpdateCheckPolicy.shouldPrompt` (pure, testée).
//
// Ce fichier ne connaît ni Play Core ni le réseau : il rend un booléen
// « l'utilisateur a accepté » et l'appelant (`AppUpdateService`) exécute.
import 'package:flutter/material.dart';

import 'package:bot_creator/core/i18n/i18n.dart';

/// Affiche le dialogue et rend `true` si l'utilisateur demande la mise à jour.
Future<bool> showAppUpdateDialog(
  BuildContext context, {
  required String availableVersion,
  required String installedVersion,
}) async {
  final tr = context.tr;
  final accepted = await showDialog<bool>(
    context: context,
    // Franchissable : un tap à côté = « plus tard », jamais un cul-de-sac.
    barrierDismissible: true,
    builder: (dialogContext) {
      final dialogTr = dialogContext.tr;
      return AlertDialog(
        icon: const Icon(Icons.system_update_alt_outlined),
        title: Text(dialogTr.app_update_dialog_title),
        content: Text(
          dialogTr.app_update_dialog_message(availableVersion, installedVersion),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogTr.app_update_later),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(tr.app_update_update_now),
          ),
        ],
      );
    },
  );
  return accepted ?? false;
}
