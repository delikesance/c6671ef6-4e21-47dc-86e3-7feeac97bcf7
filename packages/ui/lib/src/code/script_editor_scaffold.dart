import 'dart:async';

import '../diagnostics/ui_diagnostics.dart';
import './script_editor_chrome.dart';
import './script_editor_editor_pane.dart';
import './script_editor_language.dart';
import './script_editor_snippet.dart';
import './script_editor_ux_sheet.dart';
import '../l10n/tr_extension.dart';
import './editor_theme_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Chrome d'éditeur partagé par les scripts BDFD et JavaScript.
///
/// Le scaffold assemble la barre d'application ([ScriptEditorAppBar]) et le
/// panneau d'édition ([ScriptEditorEditorPane], qui empile le corps d'édition,
/// la barre des extraits, la barre de caractères rapides mobile et la barre de
/// diagnostics) ; il détient l'état de l'éditeur (complétions, signature,
/// diagnostics, bascules d'affichage).
///
/// Aucun libellé d'UI n'est codé en dur : tout arrive déjà localisé, et tout ce
/// qui dépend du langage passe par [language].
class ScriptEditorScaffold extends StatefulWidget {
  const ScriptEditorScaffold({
    super.key,
    required this.title,
    required this.initialCode,
    required this.language,
    required this.hintText,
    required this.uxSheetTitle,
    required this.uxSheetBullets,
    required this.onOpenDocs,
    required this.messageBuilder,
    this.snippets = const <ScriptEditorSnippet>[],
    this.enableAutocomplete = true,
    this.prefersWordWrap = false,
    this.controller,
    this.emptyLabel,
    this.cleanLabel,
  });

  /// Tous les libellés déjà affichables le sont : titre et indication du
  /// document vide, titre et puces de la feuille « UX ».
  final String title;
  final String hintText;
  final String uxSheetTitle;
  final List<String> uxSheetBullets;

  /// Contenu initial, ignoré si [controller] est fourni.
  final String initialCode;

  /// Couche langage : complétions, signatures, diagnostics, caractères rapides.
  final ScriptEditorLanguage language;

  /// Ouvre la documentation propre au langage.
  final VoidCallback onOpenDocs;

  /// Traduit un diagnostic en message de la barre du bas.
  final String Function(ScriptDiagnostic diagnostic) messageBuilder;

  /// Extraits insérables ; la barre n'apparaît que si la liste est non vide.
  final List<ScriptEditorSnippet> snippets;

  final bool enableAutocomplete;

  /// Habillage activé à l'ouverture (le réglage global prime aussi).
  final bool prefersWordWrap;

  /// Contrôleur personnalisé (coloration d'un lexer) ; le scaffold en crée un
  /// simple quand il est absent, et ne libère alors que le sien.
  final TextEditingController? controller;

  /// Messages du document vide et du document propre ; clés BDFD par défaut.
  final String? emptyLabel;
  final String? cleanLabel;

  @override
  State<ScriptEditorScaffold> createState() => _ScriptEditorScaffoldState();
}

class _ScriptEditorScaffoldState extends State<ScriptEditorScaffold> {
  late final TextEditingController _controller;
  late final bool _ownsController;
  final FocusNode _focusNode = FocusNode();

  List<ScriptDiagnostic> _diagnostics = const <ScriptDiagnostic>[];

  /// Analyse lourde (« diagnosticsFor » : compilation BDFD complète, analyse
  /// JavaScript complète) retirée du chemin de la frappe : elle est reprogrammée
  /// après une courte pause d'inactivité, alors que le caret, l'autocomplete et
  /// la signature restent synchrones dans [_refresh].
  Timer? _diagnosticsDebounce;

  /// Délai d'inactivité avant de relancer l'analyse lourde.
  static const Duration _diagnosticsDebounceDuration = Duration(
    milliseconds: 250,
  );

  ScriptCompletionResult? _completion;
  int _completionSelectedIndex = 0;
  ScriptSignatureHint? _signatureHint;
  int _caretLine = 0;
  int _caretColumn = 0;
  late bool _wordWrap;
  bool _showIndentGuides = true;
  bool _showDiagnostics = true;

  late final DateTime _sessionStart;
  int _keystrokes = 0;
  String _lastTrackedText = '';
  bool _sessionReported = false;

  void _reportSessionEnd({required bool saved}) {
    if (_sessionReported) return;
    _sessionReported = true;
    final duration = DateTime.now().difference(_sessionStart);
    unawaited(
      UiDiagnostics.editorSessionEnd(
        saved: saved,
        duration: duration,
        keystrokes: _keystrokes,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialCode);
    _sessionStart = DateTime.now();
    _lastTrackedText = _controller.text;
    _wordWrap = widget.prefersWordWrap;
    _controller.addListener(_onEditorChanged);
    _focusNode.addListener(_onEditorChanged);
    _refresh();
  }

  @override
  void dispose() {
    _reportSessionEnd(saved: false);
    _diagnosticsDebounce?.cancel();
    _controller.removeListener(_onEditorChanged);
    _focusNode.removeListener(_onEditorChanged);
    _focusNode.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onEditorChanged() {
    if (!mounted) {
      return;
    }
    final currentText = _controller.text;
    if (currentText != _lastTrackedText) {
      _keystrokes++;
      _lastTrackedText = currentText;
    }
    setState(_refresh);
  }

  /// Recalcule l'état dépendant du texte et du caret (complétions, signature,
  /// ligne active des guides) et reprogramme l'analyse lourde.
  void _refresh() {
    UiDiagnostics.markStart('editor_keystroke_analysis');
    try {
      final text = _controller.text;
      final caret = scriptClampedCaret(text, _controller.selection);
      final position = scriptLineColumnAt(text, caret);
      _caretLine = position.line - 1;
      _caretColumn = position.column - 1;

      final completion = widget.enableAutocomplete
          ? widget.language.completionAt(text, caret)
          : null;
      _completion = completion;
      _completionSelectedIndex = completion == null || completion.isEmpty
          ? 0
          : _completionSelectedIndex.clamp(0, completion.entries.length - 1);
      _signatureHint = text.isEmpty
          ? null
          : widget.language.signatureAt(text, caret);
      _scheduleDiagnostics(text);
    } finally {
      UiDiagnostics.markEnd('editor_keystroke_analysis');
    }
  }

  /// Reprogramme l'analyse des diagnostics, seule opération chère de la frappe
  /// (compilation BDFD complète, analyse JavaScript complète) : elle attend une
  /// pause d'inactivité au lieu de bloquer l'isolate UI à chaque caractère.
  ///
  /// Le caret, l'autocomplete et la signature restent synchrones, donc
  /// l'éditeur réagit toujours à l'instant même.
  void _scheduleDiagnostics(String text) {
    _diagnosticsDebounce?.cancel();
    if (text.trim().isEmpty) {
      _diagnostics = const <ScriptDiagnostic>[];
      return;
    }
    _diagnosticsDebounce = Timer(_diagnosticsDebounceDuration, () {
      if (!mounted) {
        return;
      }
      // Garde anti-résultat-périmé : une frappe plus récente a déjà reprogrammé
      // l'analyse, le texte capturé n'est plus celui du document.
      if (_controller.text != text) {
        return;
      }
      final diagnostics = widget.language.diagnosticsFor(text);
      if (!mounted) {
        return;
      }
      setState(() => _diagnostics = diagnostics);
    });
  }

  static const Set<TargetPlatform> _desktopPlatforms = {
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  };

  bool get _isDesktopLike =>
      _desktopPlatforms.contains(Theme.of(context).platform);

  bool get _isCompletionVisible =>
      _completion != null && !_completion!.isEmpty && _focusNode.hasFocus;

  bool get _isSignatureVisible =>
      _isDesktopLike &&
      !_isCompletionVisible &&
      _focusNode.hasFocus &&
      _signatureHint != null;

  /// Touches du panneau d'autocomplete.
  ///
  /// Aucun filtre de plateforme : un clavier matériel (tablette, Chromebook)
  /// doit pouvoir parcourir et valider les complétions comme sur desktop. Le
  /// panneau n'étant visible qu'avec le focus, cette condition suffit à ne
  /// jamais intercepter de frappe au clavier virtuel.
  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    final completion = _completion;
    if (event is! KeyDownEvent ||
        completion == null ||
        completion.isEmpty ||
        !_focusNode.hasFocus) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    final count = completion.entries.length;
    if (key == LogicalKeyboardKey.escape) {
      setState(() {
        _completion = null;
        _completionSelectedIndex = 0;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final step = key == LogicalKeyboardKey.arrowDown ? 1 : count - 1;
      setState(() {
        _completionSelectedIndex = (_completionSelectedIndex + step) % count;
      });
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.tab) {
      _completeWith(
        completion.entries[_completionSelectedIndex.clamp(0, count - 1)],
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Insère l'entrée choisie à la place du préfixe en cours et referme le
  /// panneau.
  void _completeWith(ScriptCompletionEntry entry) {
    final completion = _completion;
    if (completion == null) {
      return;
    }
    scriptInsertCompletion(
      _controller,
      completion,
      entry,
      focusNode: _focusNode,
    );
    setState(() {
      _completion = null;
      _completionSelectedIndex = 0;
    });
  }

  void _showUxSheet() => showScriptEditorUxSheet(
    context,
    title: widget.uxSheetTitle,
    bullets: widget.uxSheetBullets,
    onOpenSettings: () => openCodeEditorSettings(context),
  );

  @override
  Widget build(BuildContext context) {
    final settings = codeEditorSettingsOf(context);
    final colors = codeEditorColorsOf(context);
    final isEmptyDocument = _controller.text.trim().isEmpty;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _reportSessionEnd(saved: false);
        }
      },
      child: Scaffold(
        backgroundColor: colors.background,
        appBar: ScriptEditorAppBar(
          title: widget.title,
          colors: colors,
          wordWrap: _wordWrap,
          showIndentGuides: _showIndentGuides,
          showDiagnostics: _showDiagnostics,
          diagnostics: _diagnostics,
          onDone: () {
            _reportSessionEnd(saved: true);
            Navigator.of(context).pop(_controller.text);
          },
          onOpenDocs: widget.onOpenDocs,
          onOpenSettings: () => openCodeEditorSettings(context),
          onToggleWordWrap: () => setState(() => _wordWrap = !_wordWrap),
          onToggleIndentGuides: () =>
              setState(() => _showIndentGuides = !_showIndentGuides),
          onToggleDiagnostics: () =>
              setState(() => _showDiagnostics = !_showDiagnostics),
          onShowUxSheet: _showUxSheet,
        ),
        body: ScriptEditorEditorPane(
          colors: colors,
          settings: settings,
          controller: _controller,
          focusNode: _focusNode,
          language: widget.language,
          hintText: widget.hintText,
          wordWrap: _wordWrap || settings.wordWrap,
          showIndentGuides: _showIndentGuides,
          caretLine: _caretLine,
          caretColumn: _caretColumn,
          completion: _isCompletionVisible ? _completion : null,
          completionSelectedIndex: _completionSelectedIndex,
          signatureHint: _isSignatureVisible ? _signatureHint : null,
          onKeyEvent: _handleEditorKey,
          onCompletionSelected: _completeWith,
          onCompletionHover: (index) {
            setState(() => _completionSelectedIndex = index);
          },
          snippets: widget.snippets,
          showQuickCharsBar: !_isDesktopLike && settings.showQuickCharsBar,
          onShowUxSheet: _showUxSheet,
          showDiagnostics: _showDiagnostics,
          diagnostics: _diagnostics,
          isEmptyDocument: isEmptyDocument,
          emptyLabel: widget.emptyLabel ?? context.tr.bdfd_editor_empty,
          cleanLabel:
              widget.cleanLabel ?? context.tr.cmd_bdfd_diagnostics_clean,
          messageBuilder: widget.messageBuilder,
        ),
      ),
    );
  }
}
