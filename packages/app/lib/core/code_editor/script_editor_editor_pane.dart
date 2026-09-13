import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/code_editor/script_editor_diagnostics_bar.dart';
import 'package:bot_creator/core/code_editor/script_editor_editor_body.dart';
import 'package:bot_creator/core/code_editor/script_editor_language.dart';
import 'package:bot_creator/core/code_editor/script_editor_snippet.dart';
import 'package:flutter/material.dart';

/// Montage du panneau d'édition du chrome partagé.
///
/// Empile, de haut en bas, la barre des extraits (présente seulement si la page
/// en déclare), la zone de code colorée qui occupe toute la place restante, la
/// barre de caractères rapides mobile et la barre de diagnostics.
///
/// Le panneau ne détient aucun état et ne décide de rien : [ScriptEditorScaffold]
/// lui transmet l'état déjà dérivé (caret, complétions et signature déjà filtrées
/// par leur visibilité, diagnostics) ainsi que les rappels. Les libellés arrivent
/// eux aussi déjà localisés, et l'insertion d'un extrait ou d'un caractère rapide
/// passe par les helpers de `script_editor_snippet.dart`.
class ScriptEditorEditorPane extends StatelessWidget {
  const ScriptEditorEditorPane({
    super.key,
    required this.colors,
    required this.settings,
    required this.controller,
    required this.focusNode,
    required this.language,
    required this.hintText,
    required this.wordWrap,
    required this.showIndentGuides,
    required this.caretLine,
    required this.caretColumn,
    required this.completion,
    required this.completionSelectedIndex,
    required this.signatureHint,
    required this.onKeyEvent,
    required this.onCompletionSelected,
    required this.onCompletionHover,
    required this.snippets,
    required this.showQuickCharsBar,
    required this.onShowUxSheet,
    required this.showDiagnostics,
    required this.diagnostics,
    required this.isEmptyDocument,
    required this.emptyLabel,
    required this.cleanLabel,
    required this.messageBuilder,
  });

  final CodeEditorThemeColors colors;
  final CodeEditorSettings settings;

  /// Contrôleur du champ et focus de l'éditeur, détenus par le scaffold.
  final TextEditingController controller;
  final FocusNode focusNode;
  final ScriptEditorLanguage language;

  /// Indication affichée dans un document vide (déjà localisée).
  final String hintText;

  /// Habillage effectif (choix de l'utilisateur ou réglage global) et guides.
  final bool wordWrap;
  final bool showIndentGuides;

  /// Position (0-indexée) du caret, utilisée par les guides et les superpositions.
  final int caretLine;
  final int caretColumn;

  /// Complétions et signature à peindre ; `null` masque le panneau ou la bulle.
  final ScriptCompletionResult? completion;
  final int completionSelectedIndex;
  final ScriptSignatureHint? signatureHint;

  /// Touches de l'éditeur (flèches, Entrée, Échap) et sélection des complétions.
  final KeyEventResult Function(FocusNode node, KeyEvent event) onKeyEvent;
  final ValueChanged<ScriptCompletionEntry> onCompletionSelected;
  final ValueChanged<int> onCompletionHover;

  /// Extraits insérables ; la barre n'apparaît que si la liste est non vide.
  final List<ScriptEditorSnippet> snippets;

  /// Barre de caractères rapides : mobile seulement, et selon le réglage global.
  final bool showQuickCharsBar;
  final VoidCallback onShowUxSheet;

  /// Barre de diagnostics et état du document qu'elle doit refléter.
  final bool showDiagnostics;
  final List<ScriptDiagnostic> diagnostics;
  final bool isEmptyDocument;
  final String emptyLabel;
  final String cleanLabel;
  final String Function(ScriptDiagnostic diagnostic) messageBuilder;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          if (snippets.isNotEmpty)
            ScriptEditorSnippetBar(
              snippets: snippets,
              colors: colors,
              onSnippet: (snippet) => scriptInsertText(
                controller,
                snippet.insert,
                focusNode: focusNode,
                caretOffset: snippet.cursorOffset,
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: colors.background,
              child: ScriptEditorBody(
                controller: controller,
                focusNode: focusNode,
                language: language,
                settings: settings,
                colors: colors,
                hintText: hintText,
                wordWrap: wordWrap,
                showIndentGuides: showIndentGuides,
                caretLine: caretLine,
                caretColumn: caretColumn,
                completion: completion,
                completionSelectedIndex: completionSelectedIndex,
                signatureHint: signatureHint,
                onKeyEvent: onKeyEvent,
                onCompletionSelected: onCompletionSelected,
                onCompletionHover: onCompletionHover,
              ),
            ),
          ),
          if (showQuickCharsBar)
            ScriptEditorQuickCharsBar(
              chars: language.quickChars,
              colors: colors,
              onChar: (char) =>
                  scriptInsertText(controller, char, focusNode: focusNode),
              onShowUxSheet: onShowUxSheet,
            ),
          if (showDiagnostics)
            ScriptEditorDiagnosticsBar(
              diagnostics: diagnostics,
              isEmptyDocument: isEmptyDocument,
              emptyLabel: emptyLabel,
              cleanLabel: cleanLabel,
              messageBuilder: messageBuilder,
            ),
        ],
      ),
    );
  }
}
