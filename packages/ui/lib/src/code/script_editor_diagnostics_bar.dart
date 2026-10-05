import './script_editor_language.dart';
import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

import '../widgets/app_icon.dart';

/// Barre de diagnostics sous la zone d'édition.
///
/// Trois états : document vide ou aucun problème détecté (vert), avertissement
/// (orange), erreur (rouge). Le liseré supérieur porte la couleur pleine, le
/// fond la même couleur à 0,5 d'alpha, et la liste est plafonnée à 140 px.
///
/// Le texte de chaque diagnostic vient de [messageBuilder], fourni par la page
/// qui connaît la langue de l'interface : la couche langage ne transporte que
/// des codes, jamais de texte affiché.
class ScriptEditorDiagnosticsBar extends StatelessWidget {
  const ScriptEditorDiagnosticsBar({
    super.key,
    required this.diagnostics,
    required this.isEmptyDocument,
    required this.emptyLabel,
    required this.cleanLabel,
    required this.messageBuilder,
  });

  /// Diagnostics du document courant ; vide = rien à signaler.
  final List<ScriptDiagnostic> diagnostics;

  /// `true` quand le script ne contient que des blancs.
  final bool isEmptyDocument;

  /// Message affiché quand le document est vide.
  final String emptyLabel;

  /// Message affiché quand le document ne présente aucun problème.
  final String cleanLabel;

  /// Traduit un diagnostic (code, ligne, détail) en message localisé.
  final String Function(ScriptDiagnostic diagnostic) messageBuilder;

  bool get _hasErrors => diagnostics.any(
    (diagnostic) => diagnostic.severity == ScriptDiagnosticSeverity.error,
  );

  @override
  Widget build(BuildContext context) {
    if (diagnostics.isEmpty) {
      return _banner(
        isEmptyDocument ? emptyLabel : cleanLabel,
        AppTheme.success,
      );
    }

    final accent = _hasErrors ? AppTheme.error : AppTheme.warning;
    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: accent)),
      ),
      child: ListView(
        shrinkWrap: true,
        children: [for (final diagnostic in diagnostics) _row(diagnostic)],
      ),
    );
  }

  Widget _banner(String label, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.5),
        border: Border(top: BorderSide(color: accent)),
      ),
      child: Row(
        children: [
          AppIcon.fromMaterial(
            Icons.check_circle_outline,
            size: 16,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: accent)),
          ),
        ],
      ),
    );
  }

  Widget _row(ScriptDiagnostic diagnostic) {
    final isError = diagnostic.severity == ScriptDiagnosticSeverity.error;
    final accent = isError ? AppTheme.error : AppTheme.warning;
    final location = (diagnostic.line != null && diagnostic.column != null)
        ? 'L${diagnostic.line}:C${diagnostic.column} '
        : '';
    // Un message déjà rédigé par un analyseur (compilateur BDFD) est affiché
    // tel quel, position comprise ; sinon la page traduit le code du diagnostic
    // et la barre préfixe le résultat par la position détectée.
    final label =
        diagnostic.message ?? '$location${messageBuilder(diagnostic)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon.fromMaterial(
            isError ? Icons.error_outline : Icons.warning_amber_rounded,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 12, color: accent)),
          ),
        ],
      ),
    );
  }
}
