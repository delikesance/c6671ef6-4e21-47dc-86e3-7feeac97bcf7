import 'package:flutter/material.dart';

import 'package:bot_creator_ui/bot_creator_ui.dart';

/// Demande confirmation avant de quitter un éditeur qui porte des modifications
/// non enregistrées. Rend vrai quand on peut quitter (rien à perdre, ou l'accord
/// de l'utilisateur) : sans cela, le bouton retour jetait l'édition en silence.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  required bool dirty,
}) async {
  if (!dirty) return true;
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(context.tr.command_unsaved_title),
      content: Text(context.tr.command_unsaved_confirm),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.tr.command_unsaved_keep),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(context.tr.common_discard),
        ),
      ],
    ),
  );
  return leave ?? false;
}
