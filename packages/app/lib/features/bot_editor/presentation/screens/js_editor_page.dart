import 'dart:async';

import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/js_editor/editor_theme_scope.dart';
import 'package:bot_creator/core/js_editor/js_completion_index.dart';
import 'package:bot_creator/core/js_editor/js_editor_snippets.dart';
import 'package:bot_creator/core/js_editor/js_syntax_controller.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsEditorPage extends StatefulWidget {
  const JsEditorPage({
    super.key,
    required this.initialCode,
    this.title,
    this.enableAutocomplete = true,
    this.snippets,
  });

  final String initialCode;
  final String? title;
  final bool enableAutocomplete;
  final List<JsEditorSnippet>? snippets;

  @override
  State<JsEditorPage> createState() => _JsEditorPageState();
}

class _JsEditorPageState extends State<JsEditorPage> {
  late final JsSyntaxController _controller;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  JsCompletionIndex? _completionIndex;
  List<JsCompletionCandidate> _completions = const [];
  int _selectedCompletion = 0;
  Timer? _debounce;
  bool _loadingIndex = true;

  @override
  void initState() {
    super.initState();
    _controller = JsSyntaxController(text: widget.initialCode);
    _controller.addListener(_onTextChanged);
    _scrollController.addListener(_onEditorScrolled);
    _loadCompletionIndex();
  }

  void _onEditorScrolled() {
    if (_completions.isEmpty || !mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _loadCompletionIndex() async {
    if (!widget.enableAutocomplete) {
      setState(() => _loadingIndex = false);
      return;
    }
    try {
      final index = await JsCompletionIndex.load();
      if (!mounted) {
        return;
      }
      setState(() {
        _completionIndex = index;
        _loadingIndex = false;
      });
      _refreshCompletions();
    } catch (_) {
      if (mounted) {
        setState(() => _loadingIndex = false);
      }
    }
  }

  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 120), _refreshCompletions);
  }

  void _refreshCompletions() {
    final index = _completionIndex;
    if (index == null || !widget.enableAutocomplete) {
      return;
    }

    final position = _cursorLineCharacter(
      _controller.text,
      _controller.selection.baseOffset,
    );
    final items = index.completionsAt(
      documentText: _controller.text,
      line: position.line,
      character: position.character,
    );

    setState(() {
      _completions = items;
      _selectedCompletion = 0;
    });
  }

  void _done() {
    Navigator.pop(context, _controller.text);
  }

  void _insertSnippet(JsEditorSnippet snippet) {
    _insertAtCursor(snippet.insert, cursorOffset: snippet.cursorOffset);
  }

  (int start, int end) _clampedTextSelection(String text) {
    final length = text.length;
    final selection = _controller.selection;
    if (!selection.isValid || selection.start < 0 || selection.end < 0) {
      final offset = selection.baseOffset.clamp(0, length);
      return (offset, offset);
    }
    final start = selection.start.clamp(0, length);
    final end = selection.end.clamp(start, length);
    return (start, end);
  }

  void _insertAtCursor(String insert, {int? cursorOffset}) {
    final text = _controller.text;
    final (start, end) = _clampedTextSelection(text);
    final newText = text.replaceRange(start, end, insert);
    final caret = (start + (cursorOffset ?? insert.length)).clamp(
      0,
      newText.length,
    );
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    _refreshCompletions();
  }

  void _applyCompletion(JsCompletionCandidate candidate) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset.clamp(0, text.length);
    final position = _cursorLineCharacter(text, offset);
    final lines = text.split('\n');
    final line = lines[position.line];
    final before = line.substring(0, position.character);

    var replaceStart = offset;
    var insertText = candidate.insertText ?? candidate.label;

    if (before.endsWith('.')) {
      replaceStart = offset;
    } else {
      final match = RegExp(r'[a-zA-Z_$][\w$]*$').firstMatch(before);
      if (match != null) {
        replaceStart = offset - match.group(0)!.length;
      }
    }

    final newText = text.replaceRange(replaceStart, offset, insertText);
    final caret = replaceStart + insertText.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    setState(() => _completions = const []);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (_completions.isEmpty || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _selectedCompletion = (_selectedCompletion + 1) % _completions.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _selectedCompletion =
            (_selectedCompletion - 1 + _completions.length) %
            _completions.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      _applyCompletion(_completions[_selectedCompletion]);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() => _completions = const []);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildCompletionOverlay(
    BoxConstraints constraints,
    CodeEditorThemeColors colors,
  ) {
    const lineHeight = 20.0;
    const charWidth = 7.8;
    const editorTopPadding = 12.0;
    const editorLeftPadding = 12.0;
    const itemHeight = 30.0;
    const panelVerticalPadding = 8.0;
    const panelWidth = 240.0;
    const panelMaxHeight = 220.0;

    final caret = _cursorLineCharacter(
      _controller.text,
      _controller.selection.baseOffset,
    );
    final visibleCount = _completions.length.clamp(0, 10);
    final panelHeight = (visibleCount * itemHeight + panelVerticalPadding)
        .clamp(80.0, panelMaxHeight);

    final scrollY = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;

    final desiredLeft = editorLeftPadding + (caret.character * charWidth);
    final desiredTop =
        editorTopPadding + ((caret.line + 1) * lineHeight) - scrollY + 4;

    final maxLeft = (constraints.maxWidth - panelWidth).clamp(
      editorLeftPadding,
      constraints.maxWidth,
    );
    final left = desiredLeft.clamp(editorLeftPadding, maxLeft);

    final minTop = editorTopPadding;
    final maxTop = (constraints.maxHeight - panelHeight).clamp(
      minTop,
      constraints.maxHeight,
    );
    final top = desiredTop.clamp(minTop, maxTop);

    return Positioned(
      left: left,
      top: top,
      width: panelWidth,
      child: _CompletionPanel(
        items: _completions,
        selectedIndex: _selectedCompletion,
        colors: colors,
        onSelected: _applyCompletion,
        onHover: (index) {
          setState(() => _selectedCompletion = index);
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onEditorScrolled);
    _controller
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The palette and the font are user settings (Rosé Pine by default). They
    // are pushed into the existing controller: the setter notifies the
    // listeners so the highlighting re-renders, without ever recreating the
    // controller in build() (that crashed with LateInitializationError and
    // dropped the selection and the undo history).
    final settings = codeEditorSettingsOf(context);
    final colors = codeEditorColorsOf(context);
    _controller
      ..themeColors = colors
      ..baseStyle = codeEditorTextStyle(settings, colors);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        title: Text(
          widget.title ?? context.tr.js_editor_title,
          style: TextStyle(color: colors.text, fontSize: 16),
        ),
        iconTheme: IconThemeData(color: colors.text),
        actions: [
          IconButton(
            tooltip: context.tr.bdfd_editor_docs,
            icon: Icon(
              Icons.menu_book,
              color: colors.text.withValues(alpha: 0.7),
            ),
            onPressed: () {
              openDocumentationHub(
                context,
                initialSection: DocumentationSection.discordJs,
                showDiscordJsTab: true,
              );
            },
          ),
          TextButton(
            onPressed: _done,
            child: Text(
              context.tr.done,
              style: TextStyle(color: colors.text, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SnippetBar(
              snippets: widget.snippets ?? jsEditorSnippets,
              colors: colors,
              onSnippet: _insertSnippet,
            ),
            if (_loadingIndex) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Focus(
                    onKeyEvent: _handleKey,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          scrollController: _scrollController,
                          maxLines: null,
                          expands: true,
                          autocorrect: false,
                          enableSuggestions: false,
                          textAlignVertical: TextAlignVertical.top,
                          keyboardType: TextInputType.multiline,
                          style: codeEditorTextStyle(settings, colors),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintText: context.tr.js_editor_hint,
                            hintStyle: TextStyle(
                              fontFamily: settings.fontFamily.fontString,
                              fontSize: settings.fontSize,
                              color: colors.gutterText,
                            ),
                          ),
                          cursorColor: colors.cursor,
                        ),
                        if (_completions.isNotEmpty)
                          _buildCompletionOverlay(constraints, colors),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnippetBar extends StatelessWidget {
  const _SnippetBar({
    required this.snippets,
    required this.colors,
    required this.onSnippet,
  });

  final List<JsEditorSnippet> snippets;
  final CodeEditorThemeColors colors;
  final void Function(JsEditorSnippet snippet) onSnippet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          itemCount: snippets.length,
          separatorBuilder: (_, _) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
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

class _CompletionPanel extends StatelessWidget {
  const _CompletionPanel({
    required this.items,
    required this.selectedIndex,
    required this.colors,
    required this.onSelected,
    required this.onHover,
  });

  final List<JsCompletionCandidate> items;
  final int selectedIndex;
  final CodeEditorThemeColors colors;
  final void Function(JsCompletionCandidate item) onSelected;
  final void Function(int index) onHover;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(10).toList();
    return Material(
      elevation: 8,
      color: colors.surface,
      borderRadius: BorderRadius.circular(6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 220),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final item = visible[index];
            final selected = index == selectedIndex;
            return InkWell(
              onTap: () => onSelected(item),
              onHover: (hovering) {
                if (hovering) {
                  onHover(index);
                }
              },
              child: Container(
                height: 30,
                color: selected ? colors.selection : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: selected ? colors.text : colors.gutterText,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

({int line, int character}) _cursorLineCharacter(String text, int offset) {
  final safeOffset = offset.clamp(0, text.length);
  final before = text.substring(0, safeOffset);
  final line = '\n'.allMatches(before).length;
  final lineStart = before.lastIndexOf('\n') + 1;
  return (line: line, character: safeOffset - lineStart);
}
