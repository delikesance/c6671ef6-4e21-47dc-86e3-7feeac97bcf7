import 'dart:async';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/js_editor/js_completion_index.dart';
import 'package:bot_creator/core/js_editor/js_editor_snippets.dart';
import 'package:bot_creator/core/js_editor/js_syntax_controller.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
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

    final position = _cursorLineCharacter(_controller.text, _controller.selection.baseOffset);
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

  void _insertAtCursor(String insert, {int? cursorOffset}) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.start;
    final end = selection.end;
    final newText = text.replaceRange(start, end, insert);
    final caret = start + (cursorOffset ?? insert.length);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: caret),
    );
    _refreshCompletions();
  }

  void _applyCompletion(JsCompletionCandidate candidate) {
    final text = _controller.text;
    final offset = _controller.selection.baseOffset;
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
            (_selectedCompletion - 1 + _completions.length) % _completions.length;
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

  Widget _buildCompletionOverlay(BoxConstraints constraints) {
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
    final panelHeight = (visibleCount * itemHeight + panelVerticalPadding).clamp(
      80.0,
      panelMaxHeight,
    );

    final scrollY =
        _scrollController.hasClients ? _scrollController.offset : 0.0;

    final desiredLeft =
        editorLeftPadding + (caret.character * charWidth);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.codeSurface : AppTheme.codeSurfaceVariant,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF252526) : const Color(0xFF37474F),
        title: Text(
          widget.title ?? context.tr.js_editor_title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: context.tr.bdfd_editor_docs,
            icon: const Icon(Icons.menu_book, color: Colors.white70),
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
              onSnippet: _insertSnippet,
            ),
            if (_loadingIndex)
              const LinearProgressIndicator(minHeight: 2),
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
                          style: const TextStyle(
                            fontFamily: 'Consolas, Courier New, monospace',
                            fontSize: 13,
                            height: 1.54,
                            color: Color(0xffc9d1d9),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintText: context.tr.js_editor_hint,
                            hintStyle: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: AppTheme.grey,
                            ),
                          ),
                          cursorColor: Colors.white,
                        ),
                        if (_completions.isNotEmpty)
                          _buildCompletionOverlay(constraints),
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
    required this.onSnippet,
  });

  final List<JsEditorSnippet> snippets;
  final void Function(JsEditorSnippet snippet) onSnippet;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1E1E1E),
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
              label: Text(
                snippet.label,
                style: const TextStyle(fontSize: 11),
              ),
              visualDensity: VisualDensity.compact,
              backgroundColor: const Color(0xFF2D2D30),
              labelStyle: const TextStyle(color: Color(0xFF90CAF9)),
              side: const BorderSide(color: Color(0xFF3C3C3C)),
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
    required this.onSelected,
    required this.onHover,
  });

  final List<JsCompletionCandidate> items;
  final int selectedIndex;
  final void Function(JsCompletionCandidate item) onSelected;
  final void Function(int index) onHover;

  @override
  Widget build(BuildContext context) {
    final visible = items.take(10).toList();
    return Material(
      elevation: 8,
      color: const Color(0xFF252526),
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
                color: selected ? const Color(0xFF094771) : null,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.centerLeft,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: selected ? Colors.white : const Color(0xFFCCCCCC),
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
