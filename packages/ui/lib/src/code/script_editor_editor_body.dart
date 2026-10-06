import './code_editor_settings.dart';
import './code_editor_theme_data.dart';
import './script_editor_indent_guides.dart';
import './script_editor_language.dart';
import './script_editor_overlays.dart';
import './editor_theme_scope.dart';
import 'package:flutter/material.dart';

/// Corps d'édition du chrome : gouttière des numéros de ligne synchronisée avec
/// le défilement vertical, guides d'indentation, deux modes d'affichage
/// (habillage des lignes ou défilement horizontal) et superpositions
/// (autocomplete, signature).
///
/// Le widget ne possède ni le texte ni le focus : le scaffold les détient et
/// lui transmet l'état du caret ainsi que les complétions/signatures à peindre
/// (déjà filtrées par leur visibilité).
class ScriptEditorBody extends StatefulWidget {
  const ScriptEditorBody({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.language,
    required this.settings,
    required this.colors,
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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ScriptEditorLanguage language;
  final CodeEditorSettings settings;
  final CodeEditorThemeColors colors;

  /// Indication affichée dans un document vide (déjà localisée).
  final String hintText;

  /// Habillage effectif (choix de l'utilisateur ou réglage global).
  final bool wordWrap;

  final bool showIndentGuides;

  /// Ligne (0-indexée) du caret, soulignée par les guides.
  final int caretLine;

  /// Colonne (0-indexée) du caret.
  final int caretColumn;

  /// Complétions à afficher ; `null` masque le panneau.
  final ScriptCompletionResult? completion;

  final int completionSelectedIndex;

  /// Signature à afficher ; `null` masque la bulle.
  final ScriptSignatureHint? signatureHint;

  /// Touches de l'éditeur (flèches, Entrée, Échap).
  final KeyEventResult Function(FocusNode node, KeyEvent event) onKeyEvent;

  final ValueChanged<ScriptCompletionEntry> onCompletionSelected;
  final ValueChanged<int> onCompletionHover;

  @override
  State<ScriptEditorBody> createState() => _ScriptEditorBodyState();
}

class _ScriptEditorBodyState extends State<ScriptEditorBody> {
  final ScrollController _verticalScrollController = ScrollController();
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _verticalScrollController.addListener(_onEditorScrolled);
  }

  @override
  void dispose() {
    _verticalScrollController.removeListener(_onEditorScrolled);
    _verticalScrollController.dispose();
    _horizontalScrollController.dispose();
    _lineNumberScrollController.dispose();
    super.dispose();
  }

  /// La gouttière suit le défilement vertical du code ; le panneau
  /// d'autocomplete, ancré au caret, doit se replacer à chaque défilement.
  void _onEditorScrolled() {
    if (_lineNumberScrollController.hasClients &&
        _verticalScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_verticalScrollController.offset);
    }
    if (widget.completion != null && mounted) {
      setState(() {});
    }
  }

  int get _lineCount => '\n'.allMatches(widget.controller.text).length + 1;

  double get _gutterWidth {
    if (!widget.settings.showLineNumbers) {
      return 0;
    }
    final count = _lineCount;
    return count > 999 ? 56.0 : (count > 99 ? 48.0 : 40.0);
  }

  double get _scrollY => _verticalScrollController.hasClients
      ? _verticalScrollController.offset
      : 0;

  double get _scrollX =>
      !widget.wordWrap && _horizontalScrollController.hasClients
      ? _horizontalScrollController.offset
      : 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final field = _buildTextField();
        return Stack(
          children: [
            _buildIndentGuidesOverlay(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.settings.showLineNumbers) _buildLineNumbers(),
                Expanded(
                  child: widget.wordWrap
                      ? field
                      : SingleChildScrollView(
                          controller: _horizontalScrollController,
                          scrollDirection: Axis.horizontal,
                          // `IntrinsicWidth` dimensionne la zone sur sa plus
                          // longue ligne, mais laisserait un script court plus
                          // étroit que la fenêtre : le `ConstrainedBox` lui
                          // impose au minimum la largeur disponible.
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minWidth: constraints.maxWidth - _gutterWidth,
                            ),
                            child: IntrinsicWidth(child: field),
                          ),
                        ),
                ),
              ],
            ),
            if (widget.signatureHint != null)
              ScriptSignatureHintOverlay(
                hint: widget.signatureHint!,
                gutterWidth: _gutterWidth,
                caretLine: widget.caretLine,
                caretColumn: widget.caretColumn,
                scrollX: _scrollX,
                scrollY: _scrollY,
                showHorizontalOffset: !widget.wordWrap,
                constraints: constraints,
                colors: widget.colors,
              ),
            if (widget.completion != null)
              ScriptAutocompleteOverlay(
                entries: widget.completion!.entries,
                selectedIndex: widget.completionSelectedIndex,
                gutterWidth: _gutterWidth,
                caretLine: widget.caretLine,
                caretColumn: widget.caretColumn,
                scrollX: _scrollX,
                scrollY: _scrollY,
                showHorizontalOffset: !widget.wordWrap,
                constraints: constraints,
                colors: widget.colors,
                onSelected: widget.onCompletionSelected,
                onHover: widget.onCompletionHover,
              ),
          ],
        );
      },
    );
  }

  Widget _buildIndentGuidesOverlay() {
    if (!widget.showIndentGuides || !widget.settings.showIndentGuides) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ScriptIndentGuidesPainter(
            source: widget.controller.text,
            activeLine: widget.caretLine,
            lineNumberGutterWidth: _gutterWidth,
            scrollX: _scrollX,
            scrollY: _scrollY,
            showHorizontalOffset: !widget.wordWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildLineNumbers() {
    final lineBox = widget.settings.fontSize * widget.settings.lineHeight;

    return Container(
      width: _gutterWidth,
      color: widget.colors.gutterBackground,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: _lineNumberScrollController,
          itemCount: _lineCount,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: ScriptEditorMetrics.topPadding),
          itemBuilder: (_, index) {
            return SizedBox(
              height: lineBox,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: widget.settings.fontFamily.fontString,
                      fontSize: widget.settings.fontSize,
                      height: widget.settings.lineHeight,
                      color: widget.colors.gutterText,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField() {
    return Focus(
      onKeyEvent: widget.onKeyEvent,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        scrollController: _verticalScrollController,
        inputFormatters: [ScriptAutoIndentFormatter(widget.language)],
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: codeEditorTextStyle(widget.settings, widget.colors),
        decoration: InputDecoration(
          isDense: true,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ScriptEditorMetrics.leftPadding,
            vertical: ScriptEditorMetrics.topPadding,
          ),
          hintText: widget.hintText,
          hintStyle: TextStyle(
            fontFamily: widget.settings.fontFamily.fontString,
            fontSize: widget.settings.fontSize,
            color: widget.colors.gutterText,
          ),
        ),
        cursorColor: widget.colors.cursor,
      ),
    );
  }
}
