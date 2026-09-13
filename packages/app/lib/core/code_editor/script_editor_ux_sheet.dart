import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/settings/presentation/code_editor_settings_page.dart';
import 'package:flutter/material.dart';

/// Feuille « UX » du chrome d'éditeur : elle rappelle les fonctions de
/// l'éditeur (puces déjà localisées par la page) et ouvre les réglages de la
/// palette.
///
/// Elle vit à part de `script_editor_chrome.dart`, qui ne garde que la barre
/// d'application et ses bascules. Aucun libellé n'est codé en dur : le titre,
/// les puces et les libellés des boutons viennent de la page ou de l'i18n.
void showScriptEditorUxSheet(
  BuildContext context, {
  required String title,
  required List<String> bullets,
  required VoidCallback onOpenSettings,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final bullet in bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(bullet),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                onOpenSettings();
              },
              icon: const Icon(Icons.palette_outlined, size: 18),
              label: Text(context.tr.code_editor_settings_title),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: Text(context.tr.close),
            ),
          ],
        ),
      );
    },
  );
}

/// Ouvre la page des réglages de la palette depuis un éditeur.
void openCodeEditorSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CodeEditorSettingsPage()),
  );
}
