import './code_editor_theme_data.dart';
import './script_editor_language.dart';
import '../l10n/tr_extension.dart';
import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';

/// Extrait de code insérable depuis la barre de chips de l'éditeur
/// ([ScriptEditorSnippetBar]).
///
/// La barre n'est affichée que si la page en déclare (éditeur JavaScript) ;
/// elle reste vide pour BDFD, dont l'autocomplete couvre déjà le besoin.
class ScriptEditorSnippet {
  const ScriptEditorSnippet({
    required this.label,
    required this.insert,
    this.cursorOffset,
  });

  /// Texte affiché sur la chip.
  final String label;

  /// Texte écrit à la position du caret.
  final String insert;

  /// Offset du caret à l'intérieur de [insert] ; par défaut, sa fin.
  final int? cursorOffset;
}

/// Barre horizontale des extraits de code, au-dessus de la zone d'édition.
class ScriptEditorSnippetBar extends StatelessWidget {
  const ScriptEditorSnippetBar({
    super.key,
    required this.snippets,
    required this.colors,
    required this.onSnippet,
  });

  final List<ScriptEditorSnippet> snippets;
  final CodeEditorThemeColors colors;
  final void Function(ScriptEditorSnippet snippet) onSnippet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      // La chip garde sa hauteur intrinsèque (40 px) : une bande plus basse la
      // comprimait et écrasait sa marge interne et sa cible tactile.
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          itemCount: snippets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (_, index) {
            final snippet = snippets[index];
            return ActionChip(
              label: Text(snippet.label, style: const TextStyle(fontSize: 11)),
              visualDensity: VisualDensity.compact,
              backgroundColor: colors.selection,
              labelStyle: TextStyle(color: colors.text),
              side: BorderSide(color: colors.gutterText.withValues(alpha: 0.4)),
              onPressed: () => onSnippet(snippet),
            );
          },
        ),
      ),
    );
  }
}

/// Barre de caractères rapides affichée sur mobile : les caractères déclarés
/// par le langage y sont insérés au caret.
class ScriptEditorQuickCharsBar extends StatelessWidget {
  const ScriptEditorQuickCharsBar({
    super.key,
    required this.chars,
    required this.colors,
    required this.onChar,
    required this.onShowUxSheet,
  });

  final List<String> chars;
  final CodeEditorThemeColors colors;
  final ValueChanged<String> onChar;
  final VoidCallback onShowUxSheet;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.gutterText.withValues(alpha: 0.2)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: context.tr.code_editor_settings_title,
              icon: AppIcon.fromMaterial(
                Icons.tune,
                size: 20,
                color: colors.text.withValues(alpha: 0.8),
              ),
              onPressed: onShowUxSheet,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final char in chars)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: _charButton(char),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _charButton(String char) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () => onChar(char),
      child: Container(
        alignment: Alignment.center,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.gutterText.withValues(alpha: 0.25)),
        ),
        child: Text(
          char,
          style: TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: colors.text,
          ),
        ),
      ),
    );
  }
}

/// Écrit [value] à la place de la sélection du champ, puis rend le focus à
/// [focusNode] et place le caret [caretOffset] caractères après le début de
/// l'insertion (par défaut à sa fin).
void scriptInsertText(
  TextEditingController controller,
  String value, {
  FocusNode? focusNode,
  int? caretOffset,
}) {
  final text = controller.text;
  final selection = controller.selection;
  final start = (selection.isValid ? selection.start : text.length).clamp(
    0,
    text.length,
  );
  final end = selection.isValid
      ? selection.end.clamp(start, text.length)
      : text.length;
  final replaced = text.replaceRange(start, end, value);
  final offset = (start + (caretOffset ?? value.length)).clamp(
    0,
    replaced.length,
  );
  controller.value = TextEditingValue(
    text: replaced,
    selection: TextSelection.collapsed(offset: offset),
  );
  focusNode?.requestFocus();
}

/// Remplace le préfixe en cours par [entry] et place le caret selon
/// [scriptCaretOffsetAfterInsert].
void scriptInsertCompletion(
  TextEditingController controller,
  ScriptCompletionResult completion,
  ScriptCompletionEntry entry, {
  FocusNode? focusNode,
}) {
  final text = controller.text;
  final caret = scriptClampedCaret(text, controller.selection);
  final start = completion.replaceStart.clamp(0, caret);
  final replaced = text.replaceRange(start, caret, entry.insert);
  final offset = scriptCaretOffsetAfterInsert(
    entry,
    start,
  ).clamp(0, replaced.length);
  controller.value = TextEditingValue(
    text: replaced,
    selection: TextSelection.collapsed(offset: offset),
  );
  focusNode?.requestFocus();
}
