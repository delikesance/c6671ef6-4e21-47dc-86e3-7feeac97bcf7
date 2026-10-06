import 'dart:async';

import './script_editor_language.dart';
import './script_editor_scaffold.dart';
import '../l10n/tr_extension.dart';
import './editor_theme_scope.dart';
import './js_completion_index.dart';
import './js_editor_snippets.dart';
import './js_script_language.dart';
import './js_syntax_controller.dart';
import '../editor/models/app_emoji.dart';
import '../docs/documentation_hub_page.dart';
import '../docs/documentation_urls.dart';
import 'package:flutter/material.dart';

/// Éditeur de scripts JavaScript des commandes et des blocs de workflow.
///
/// La page n'assemble plus rien elle-même : elle injecte la couche langage
/// JavaScript ([JsScriptLanguage]) dans le chrome d'éditeur partagé
/// ([ScriptEditorScaffold]), qui apporte numéros de ligne, guides d'indentation,
/// auto-indent, autocomplete, signatures, diagnostics temps réel, bascules
/// d'affichage et barre de caractères rapides mobile.
class JsEditorPage extends StatefulWidget {
  const JsEditorPage({
    super.key,
    required this.initialCode,
    this.title,
    this.enableAutocomplete = true,
    this.snippets,
    this.appEmojis = const <AppEmoji>[],
  });

  final String initialCode;

  /// Titre de la barre d'application ; `null` prend le titre localisé.
  final String? title;

  final bool enableAutocomplete;

  /// Extraits de la barre de chips ; `null` prend [jsEditorSnippets].
  final List<JsEditorSnippet>? snippets;

  /// Emojis du serveur courant, proposés après le déclencheur `<:` / `<a:`.
  final List<AppEmoji> appEmojis;

  @override
  State<JsEditorPage> createState() => _JsEditorPageState();
}

class _JsEditorPageState extends State<JsEditorPage> {
  /// Contrôleur colorant le JavaScript (re_highlight) avec la palette choisie.
  late final JsSyntaxController _controller;

  JsCompletionIndex? _completionIndex;

  @override
  void initState() {
    super.initState();
    _controller = JsSyntaxController(text: widget.initialCode);
    unawaited(_loadCompletionIndex());
  }

  /// Charge l'index d'autocomplete **sans bloquer l'affichage** : la page
  /// s'ouvre immédiatement avec les emojis pour seules complétions, puis
  /// rebascule sur le langage complet une fois l'index disponible.
  Future<void> _loadCompletionIndex() async {
    if (!widget.enableAutocomplete) {
      return;
    }
    try {
      final index = await JsCompletionIndex.load();
      if (!mounted) {
        return;
      }
      setState(() => _completionIndex = index);
    } catch (_) {
      // Index illisible ou absent de l'installation : les complétions de
      // symboles restent indisponibles, le reste de l'éditeur fonctionne.
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = codeEditorSettingsOf(context);
    final colors = codeEditorColorsOf(context);
    _controller
      ..themeColors = colors
      ..baseStyle = codeEditorTextStyle(settings, colors);
  }

  /// Traduit un diagnostic de la couche JavaScript en message affichable.
  ///
  /// Un diagnostic portant déjà un [ScriptDiagnostic.message] (analyseurs
  /// externes) prime ; sinon le [ScriptDiagnostic.code] est résolu dans la
  /// locale courante.
  String _messageFor(ScriptDiagnostic diagnostic) {
    final message = diagnostic.message;
    if (message != null) {
      return message;
    }
    switch (diagnostic.code) {
      case ScriptDiagnosticCode.unterminatedString:
        return context.tr.js_diag_unterminated_string;
      case ScriptDiagnosticCode.unterminatedTemplate:
        return context.tr.js_diag_unterminated_template;
      case ScriptDiagnosticCode.unterminatedComment:
        return context.tr.js_diag_unterminated_comment;
      case ScriptDiagnosticCode.unexpectedClosing:
        return context.tr.js_diag_unexpected_closing(diagnostic.detail);
      case ScriptDiagnosticCode.unclosedOpening:
        return context.tr.js_diag_unclosed_opening(
          diagnostic.detail,
          '${diagnostic.detailLine ?? diagnostic.line ?? ''}',
        );
    }
  }

  void _openDocs() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const DocumentationHubPage(
          initialSection: DocumentationSection.discordJs,
          showDiscordJsTab: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScriptEditorScaffold(
      title: widget.title ?? context.tr.js_editor_title,
      initialCode: widget.initialCode,
      controller: _controller,
      language: JsScriptLanguage(
        index: _completionIndex,
        appEmojis: widget.appEmojis,
      ),
      hintText: context.tr.js_editor_hint,
      uxSheetTitle: context.tr.js_editor_ux_title,
      uxSheetBullets: <String>[
        context.tr.js_editor_includes,
        context.tr.js_editor_auto_indent,
        context.tr.js_editor_indent_guides,
        context.tr.js_editor_quick_keys,
      ],
      emptyLabel: context.tr.js_editor_empty,
      cleanLabel: context.tr.js_editor_diagnostics_clean,
      onOpenDocs: _openDocs,
      messageBuilder: _messageFor,
      snippets: widget.snippets ?? jsEditorSnippets,
      enableAutocomplete: widget.enableAutocomplete,
    );
  }
}
