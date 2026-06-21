import 'package:bot_creator/features/bot_editor/presentation/screens/bdfd_docs.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';

import 'package:bot_creator_shared/utils/bdfd_autocomplete.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';
import 'package:bot_creator_shared/utils/bdfd_signature_hints.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class _BdfdSyntaxColors {
  static const Color function = AppTheme.syntaxOrange;
  static const Color bracket = AppTheme.syntaxCyan;
  static const Color semicolon = AppTheme.errorLight;
  static const Color text = AppTheme.syntaxGrey;
}

class _BdfdAutoIndentFormatter extends TextInputFormatter {
  const _BdfdAutoIndentFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.selection.isValid || !newValue.selection.isCollapsed) {
      return newValue;
    }

    final oldText = oldValue.text;
    final newText = newValue.text;
    if (newText.length <= oldText.length) {
      return newValue;
    }

    final delta = newText.length - oldText.length;
    if (delta != 1) {
      return newValue;
    }

    final caret = newValue.selection.baseOffset;
    if (caret <= 0 || caret > newText.length) {
      return newValue;
    }

    final inserted = newText[caret - 1];
    if (inserted != '\n') {
      return newValue;
    }

    final previousLineBreak =
        caret > 1 ? newText.lastIndexOf('\n', caret - 2) : -1;
    final previousLineStart = previousLineBreak < 0 ? 0 : previousLineBreak + 1;
    final previousLine = newText.substring(previousLineStart, caret - 1);
    final indentMatch = RegExp(r'^[ \t]+').firstMatch(previousLine);
    final indent = indentMatch?.group(0) ?? '';
    if (indent.isEmpty) {
      return newValue;
    }

    final updatedText = newText.replaceRange(caret, caret, indent);
    return TextEditingValue(
      text: updatedText,
      selection: TextSelection.collapsed(offset: caret + indent.length),
      composing: TextRange.empty,
    );
  }
}

class BdfdIndentGuidesPainter extends CustomPainter {
  const BdfdIndentGuidesPainter({
    required this.source,
    required this.activeLine,
    required this.lineNumberGutterWidth,
    required this.scrollX,
    required this.scrollY,
    required this.showHorizontalOffset,
  });

  final String source;
  final int activeLine;
  final double lineNumberGutterWidth;
  final double scrollX;
  final double scrollY;
  final bool showHorizontalOffset;
  static const double lineHeight = 20;
  static const double charWidth = 7.8;
  static const double topPadding = 12;
  static const double leftPadding = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint =
        Paint()
          ..color = const Color(0x33FFFFFF)
          ..strokeWidth = 1;
    final matchingPaint =
        Paint()
          ..color = const Color(0x66FFD54F)
          ..strokeWidth = 1.2;
    final activePaint =
        Paint()
          ..color = const Color(0xCCFFD54F)
          ..strokeWidth = 1.8;

    final lines = source.split('\n');
    final activeIndentColumns =
        activeLine >= 0 && activeLine < lines.length
            ? _countIndentColumns(lines[activeLine])
            : 0;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final y = topPadding + (i * lineHeight) - scrollY;
      if (y + lineHeight < 0 || y > size.height) {
        continue;
      }

      final indentColumns = _countIndentColumns(line);
      if (indentColumns < 2) {
        continue;
      }

      for (var col = 2; col <= indentColumns; col += 2) {
        Paint paint = defaultPaint;
        if (activeIndentColumns >= 2 && col <= activeIndentColumns) {
          paint = matchingPaint;
        }
        if (i == activeLine && col <= activeIndentColumns) {
          paint = activePaint;
        }

        final x =
            lineNumberGutterWidth +
            leftPadding +
            (col * charWidth) -
            (showHorizontalOffset ? scrollX : 0);
        if (x < lineNumberGutterWidth + 2 || x > size.width) {
          continue;
        }
        canvas.drawLine(Offset(x, y + 2), Offset(x, y + lineHeight - 2), paint);
      }
    }
  }

  int _countIndentColumns(String line) {
    var columns = 0;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == ' ') {
        columns += 1;
      } else if (c == '\t') {
        columns += 2;
      } else {
        break;
      }
    }
    return columns;
  }

  @override
  bool shouldRepaint(covariant BdfdIndentGuidesPainter oldDelegate) {
    return source != oldDelegate.source ||
        activeLine != oldDelegate.activeLine ||
        lineNumberGutterWidth != oldDelegate.lineNumberGutterWidth ||
        scrollX != oldDelegate.scrollX ||
        scrollY != oldDelegate.scrollY ||
        showHorizontalOffset != oldDelegate.showHorizontalOffset;
  }
}

class BdfdSyntaxController extends TextEditingController {
  BdfdSyntaxController({super.text});

  final BdfdLexer _lexer = BdfdLexer();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    if (source.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final result = _lexer.tokenize(source);
    final children = <TextSpan>[];
    final covered = StringBuffer();

    for (final token in result.tokens) {
      if (token.type == BdfdTokenType.eof) {
        continue;
      }

      final Color color;
      switch (token.type) {
        case BdfdTokenType.function:
          color = _BdfdSyntaxColors.function;
        case BdfdTokenType.openBracket:
        case BdfdTokenType.closeBracket:
          color = _BdfdSyntaxColors.bracket;
        case BdfdTokenType.semicolon:
          color = _BdfdSyntaxColors.semicolon;
        default:
          color = _BdfdSyntaxColors.text;
      }

      covered.write(token.lexeme);
      children.add(
        TextSpan(text: token.lexeme, style: style?.copyWith(color: color)),
      );
    }

    // Safety: if tokenizer output doesn't exactly cover the source text,
    // fall back to plain text to avoid cursor offset misalignment.
    if (covered.toString() != source) {
      return TextSpan(text: source, style: style);
    }

    // If there is active composing (IME), wrap the composing region.
    if (withComposing && value.isComposingRangeValid) {
      return TextSpan(
        style: style,
        children: _splitSpanAtComposing(children, style),
      );
    }

    return TextSpan(style: style, children: children);
  }

  /// Splits children spans at the composing range boundaries so that
  /// Flutter can style the composing region accordingly.
  List<InlineSpan> _splitSpanAtComposing(
    List<TextSpan> children,
    TextStyle? style,
  ) {
    final composing = value.composing;
    final result = <InlineSpan>[];
    var offset = 0;

    for (final child in children) {
      final len = child.text!.length;
      final childEnd = offset + len;

      if (childEnd <= composing.start || offset >= composing.end) {
        // Fully outside composing range — keep as-is.
        result.add(child);
      } else if (offset >= composing.start && childEnd <= composing.end) {
        // Fully inside composing range — wrap with composing style.
        result.add(TextSpan(
          text: child.text,
          style: child.style?.copyWith(
            decoration: TextDecoration.underline,
          ),
        ));
      } else {
        // Partially inside — split.
        final beforeLen = (composing.start - offset).clamp(0, len);
        final insideLen =
            (composing.end - (offset + beforeLen)).clamp(0, len - beforeLen);
        final afterLen = len - beforeLen - insideLen;

        if (beforeLen > 0) {
          result.add(TextSpan(
            text: child.text!.substring(0, beforeLen),
            style: child.style,
          ));
        }
        if (insideLen > 0) {
          result.add(TextSpan(
            text: child.text!.substring(beforeLen, beforeLen + insideLen),
            style: child.style?.copyWith(
              decoration: TextDecoration.underline,
            ),
          ));
        }
        if (afterLen > 0) {
          result.add(TextSpan(
            text: child.text!.substring(beforeLen + insideLen),
            style: child.style,
          ));
        }
      }

      offset = childEnd;
    }

    return result;
  }
}

final RegExp _bdfdIdentifierChar = RegExp(r'[A-Za-z0-9_]');
const int _minAutocompletePrefixLength = 2;
const int _maxAutocompleteItems = 6;

enum _AutocompleteMode { none, function, emoji }

class BdfdEditorPage extends StatefulWidget {
  const BdfdEditorPage({
    super.key,
    required this.initialCode,
    this.title,
    this.appEmojis = const [],
  });

  final String initialCode;
  final String? title;
  final List<AppEmoji> appEmojis;

  @override
  State<BdfdEditorPage> createState() => _BdfdEditorPageState();
}

class _BdfdEditorPageState extends State<BdfdEditorPage> {
  late final BdfdSyntaxController _controller;
  final BdfdCompiler _compiler = BdfdCompiler();
  final ScrollController _editorScrollController = ScrollController();
  final ScrollController _editorHorizontalScrollController = ScrollController();
  final ScrollController _lineNumberScrollController = ScrollController();
  final FocusNode _editorFocusNode = FocusNode();

  BdfdCompileResult? _compileResult;
  bool _wordWrap = false;
  bool _showIndentGuides = true;
  bool _showDiagnostics = true;
  int _activeGuideLine = 0;
  int _autocompleteSelectedIndex = 0;
  List<MapEntry<String, String>> _autocompleteEntries =
      const <MapEntry<String, String>>[];
  _AutocompleteMode _autocompleteMode = _AutocompleteMode.none;
  BdfdSignatureContext? _signatureContext;
  final BdfdLexer _signatureLexer = BdfdLexer();

  bool get _isDesktopLike {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.windows ||
        platform == TargetPlatform.macOS ||
        platform == TargetPlatform.linux;
  }

  @override
  void initState() {
    super.initState();
    _controller = BdfdSyntaxController(text: widget.initialCode);
    _controller.addListener(_updateAutocomplete);
    _controller.addListener(_updateSignatureHint);
    _controller.addListener(_updateActiveGuideLine);
    _editorScrollController.addListener(_syncLineNumberScroll);
    _recompile();
  }

  @override
  void dispose() {
    _controller.removeListener(_updateAutocomplete);
    _controller.removeListener(_updateSignatureHint);
    _controller.removeListener(_updateActiveGuideLine);
    _editorScrollController.removeListener(_syncLineNumberScroll);
    _editorScrollController.dispose();
    _editorHorizontalScrollController.dispose();
    _lineNumberScrollController.dispose();
    _editorFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _isAutocompleteVisible =>
      _autocompleteEntries.isNotEmpty && _editorFocusNode.hasFocus;

  bool get _isSignatureHintVisible =>
      _isDesktopLike &&
      _signatureContext != null &&
      _editorFocusNode.hasFocus &&
      !_isAutocompleteVisible;

  void _syncLineNumberScroll() {
    if (_lineNumberScrollController.hasClients &&
        _editorScrollController.hasClients) {
      _lineNumberScrollController.jumpTo(_editorScrollController.offset);
    }

    if (_isAutocompleteVisible && mounted) {
      setState(() {});
    }
  }

  void _updateActiveGuideLine() {
    final line = _caretLineColumn().line;
    if (line != _activeGuideLine && mounted) {
      setState(() {
        _activeGuideLine = line;
      });
    }
  }

  bool _sameEntries(
    List<MapEntry<String, String>> a,
    List<MapEntry<String, String>> b,
  ) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].key != b[i].key || a[i].value != b[i].value) {
        return false;
      }
    }
    return true;
  }

  ({int start, _AutocompleteMode mode})? _findAutocompleteStart(
    String text,
    int caretOffset,
  ) {
    if (caretOffset <= 0 || caretOffset > text.length) {
      return null;
    }

    // Check for emoji prefix: <:
    if (caretOffset >= 2 &&
        text[caretOffset - 2] == '<' &&
        text[caretOffset - 1] == ':') {
      // Allow a: for animated emojis: <a:
      if (caretOffset >= 3 &&
          text[caretOffset - 3] == 'a' &&
          text[caretOffset - 2] == ':') {
        // caret is after <a: — prefix start is at <
        var i = caretOffset - 3;
        if (i >= 1 && text[i - 1] == '<') {
          return (start: i - 1, mode: _AutocompleteMode.emoji);
        }
      }
      // caret is after <: — prefix start is at <
      return (start: caretOffset - 2, mode: _AutocompleteMode.emoji);
    }

    // Emoji prefix with partial text typed: <a:partial or <:partial
    var i = caretOffset - 1;
    while (i >= 0) {
      final c = text[i];
      if (c == ':' && i >= 1 && text[i - 1] == 'a' && i >= 2 && text[i - 2] == '<') {
        return (start: i - 2, mode: _AutocompleteMode.emoji);
      }
      if (c == ':' && i >= 1 && text[i - 1] == '<') {
        return (start: i - 1, mode: _AutocompleteMode.emoji);
      }
      if (_bdfdIdentifierChar.hasMatch(c)) {
        i -= 1;
        continue;
      }
      break;
    }

    // Check for function prefix: $
    i = caretOffset - 1;
    while (i >= 0) {
      final c = text[i];
      if (_bdfdIdentifierChar.hasMatch(c)) {
        i -= 1;
        continue;
      }
      if (c == r'$') {
        return (start: i, mode: _AutocompleteMode.function);
      }
      return null;
    }

    return null;
  }

  List<MapEntry<String, String>> _computeAutocompleteEntries() {
    final text = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid) {
      return const <MapEntry<String, String>>[];
    }

    final caret = sel.baseOffset;
    final result = _findAutocompleteStart(text, caret);
    if (result == null) {
      return const <MapEntry<String, String>>[];
    }

    final start = result.start;
    final mode = result.mode;

    if (mode == _AutocompleteMode.emoji) {
      return _computeEmojiAutocompleteEntries(text, caret, start);
    }

    // Function autocomplete (existing logic)
    final prefix = text.substring(start + 1, caret).toLowerCase();
    if (prefix.length < _minAutocompletePrefixLength) {
      return const <MapEntry<String, String>>[];
    }

    final matches = bdfdAutocompleteTemplates.entries
        .where((entry) => entry.key.startsWith(prefix))
        .toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    if (matches.length == 1 && matches.first.key == prefix) {
      return const <MapEntry<String, String>>[];
    }

    return matches.take(_maxAutocompleteItems).toList(growable: false);
  }

  List<MapEntry<String, String>> _computeEmojiAutocompleteEntries(
    String text,
    int caret,
    int prefixStart,
  ) {
    final emojis = widget.appEmojis;
    if (emojis.isEmpty) {
      return const <MapEntry<String, String>>[];
    }

    // Extract the name prefix: text between <: or <a: and caret
    final afterPrefix = text.substring(prefixStart, caret);
    String namePrefix;
    if (afterPrefix.startsWith('<a:')) {
      namePrefix = afterPrefix.substring(3).toLowerCase();
    } else if (afterPrefix.startsWith('<:')) {
      namePrefix = afterPrefix.substring(2).toLowerCase();
    } else {
      return const <MapEntry<String, String>>[];
    }

    if (namePrefix.isEmpty) {
      // Show all emojis when just <: is typed
      return emojis
          .take(_maxAutocompleteItems)
          .map((e) => MapEntry(e.name, e.mention))
          .toList(growable: false);
    }

    final matches = emojis
        .where((e) => e.name.toLowerCase().startsWith(namePrefix))
        .take(_maxAutocompleteItems)
        .map((e) => MapEntry(e.name, e.mention))
        .toList(growable: false);

    if (matches.length == 1 && matches.first.key.toLowerCase() == namePrefix) {
      return const <MapEntry<String, String>>[];
    }

    return matches;
  }

  void _updateAutocomplete() {
    if (!_editorFocusNode.hasFocus) {
      if (_autocompleteEntries.isNotEmpty) {
        setState(() {
          _autocompleteEntries = const <MapEntry<String, String>>[];
          _autocompleteSelectedIndex = 0;
          _autocompleteMode = _AutocompleteMode.none;
        });
      }
      return;
    }

    final text = _controller.text;
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.baseOffset : text.length;
    final result = _findAutocompleteStart(text, caret);
    final mode = result?.mode ?? _AutocompleteMode.none;

    final entries = _computeAutocompleteEntries();
    if (entries.length != _autocompleteEntries.length ||
        !_sameEntries(entries, _autocompleteEntries) ||
        mode != _autocompleteMode) {
      final previousValue =
          (_autocompleteEntries.isNotEmpty &&
                  _autocompleteSelectedIndex >= 0 &&
                  _autocompleteSelectedIndex < _autocompleteEntries.length)
              ? _autocompleteEntries[_autocompleteSelectedIndex].value
              : null;

      setState(() {
        _autocompleteMode = mode;
        _autocompleteEntries = entries;
        if (entries.isEmpty) {
          _autocompleteSelectedIndex = 0;
        } else if (previousValue != null) {
          final restored = entries.indexWhere((e) => e.value == previousValue);
          _autocompleteSelectedIndex = restored >= 0 ? restored : 0;
        } else {
          _autocompleteSelectedIndex = 0;
        }
      });
    }
  }

  void _updateSignatureHint() {
    final source = _controller.text;
    final sel = _controller.selection;
    if (!sel.isValid || source.isEmpty) {
      if (_signatureContext != null) {
        setState(() => _signatureContext = null);
      }
      return;
    }

    final caret = sel.baseOffset;
    final lexerResult = _signatureLexer.tokenize(source);
    final ctx = bdfdSignatureContextAt(source, caret, lexerResult);

    if (ctx != _signatureContext) {
      final changed =
          ctx?.functionName != _signatureContext?.functionName ||
          ctx?.activeIndex != _signatureContext?.activeIndex;
      if (changed || (ctx == null) != (_signatureContext == null)) {
        setState(() => _signatureContext = ctx);
      }
    }
  }

  KeyEventResult _handleEditorKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_isDesktopLike || !_isAutocompleteVisible) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      setState(() {
        _autocompleteEntries = const <MapEntry<String, String>>[];
        _autocompleteSelectedIndex = 0;
        _autocompleteMode = _AutocompleteMode.none;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _autocompleteSelectedIndex =
            (_autocompleteSelectedIndex + 1) % _autocompleteEntries.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _autocompleteSelectedIndex =
            (_autocompleteSelectedIndex - 1 + _autocompleteEntries.length) %
            _autocompleteEntries.length;
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.tab) {
      final idx = _autocompleteSelectedIndex.clamp(
        0,
        _autocompleteEntries.length - 1,
      );
      final selected = _autocompleteEntries[idx];
      _insertAutocompleteTemplate(selected.key, selected.value);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  String _signatureLookupKeyForTemplate(String key, String template) {
    if (bdfdSignatureHints.containsKey(key)) {
      return key;
    }

    final match = RegExp(r'\$([A-Za-z0-9_]+)\[').firstMatch(template);
    if (match != null) {
      final parsed = (match.group(1) ?? '').toLowerCase();
      if (bdfdSignatureHints.containsKey(parsed)) {
        return parsed;
      }
    }

    return key;
  }

  String _normalizeSignatureParameter(String raw) {
    final withoutMeta = raw.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
    return withoutMeta == '...' ? '' : withoutMeta;
  }

  bool _isOptionalSignatureParameter(String raw) {
    final lower = raw.toLowerCase();
    if (!lower.contains('(') || !lower.contains(')')) {
      return false;
    }

    return RegExp(r'\((?:[^)]*\bopt(?:ional)?\b[^)]*)\)').hasMatch(lower);
  }

  String _templateWithDefaultArguments(String key, String template) {
    final bracketIdx = template.indexOf('[]');
    if (bracketIdx < 0) {
      return template;
    }

    final signatureKey = _signatureLookupKeyForTemplate(key, template);
    final parameters = bdfdSignatureHints[signatureKey];
    if (parameters == null || parameters.isEmpty) {
      return template;
    }

    final defaults = parameters
        .where((p) => !_isOptionalSignatureParameter(p))
        .map(_normalizeSignatureParameter)
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (defaults.isEmpty) {
      return template;
    }

    return template.replaceFirst('[]', '[${defaults.join(' ; ')}]');
  }

  void _insertAutocompleteTemplate(String key, String template) {
    final text = _controller.text;
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.baseOffset : text.length;

    final result = _findAutocompleteStart(text, caret);
    if (result == null) {
      return;
    }

    final start = result.start;
    final mode = result.mode;

    if (mode == _AutocompleteMode.emoji) {
      // For emoji, template is already the full mention like <:name:id>
      final replaced = text.replaceRange(start, caret, '$template>');
      _controller.value = TextEditingValue(
        text: replaced,
        selection: TextSelection.collapsed(offset: start + template.length + 1),
      );

      setState(() {
        _recompile();
        _autocompleteEntries = const <MapEntry<String, String>>[];
        _autocompleteSelectedIndex = 0;
        _autocompleteMode = _AutocompleteMode.none;
      });

      _editorFocusNode.requestFocus();
      return;
    }

    // Function autocomplete (existing logic)
    final resolvedTemplate = _templateWithDefaultArguments(key, template);
    final replaced = text.replaceRange(start, caret, resolvedTemplate);
    final bracketIdx = resolvedTemplate.indexOf('[');
    final nextOffset =
        bracketIdx >= 0
            ? start + bracketIdx + 1
            : start + resolvedTemplate.length;

    _controller.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: nextOffset),
    );

    setState(() {
      _recompile();
      _autocompleteEntries = const <MapEntry<String, String>>[];
      _autocompleteSelectedIndex = 0;
      _autocompleteMode = _AutocompleteMode.none;
    });

    _editorFocusNode.requestFocus();
  }

  void _recompile() {
    final source = _controller.text;
    if (source.trim().isEmpty) {
      _compileResult = null;
      return;
    }
    _compileResult = _compiler.compile(source);
  }

  List<BdfdCompileDiagnostic> get _diagnostics =>
      _compileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get _hasErrors => _diagnostics.any(
    (d) => d.severity == BdfdCompileDiagnosticSeverity.error,
  );

  int get _lineCount => '\n'.allMatches(_controller.text).length + 1;

  double get _lineNumberGutterWidth {
    final count = _lineCount;
    return count > 999 ? 56.0 : (count > 99 ? 48.0 : 40.0);
  }

  ({int line, int column}) _caretLineColumn() {
    final sel = _controller.selection;
    final caret = sel.isValid ? sel.baseOffset : _controller.text.length;
    final safe = caret.clamp(0, _controller.text.length);
    final before = _controller.text.substring(0, safe);
    final lines = before.split('\n');
    return (line: lines.length - 1, column: lines.last.length);
  }

  void _done() {
    Navigator.of(context).pop(_controller.text);
  }

  void _insertAtCaret(String value) {
    final text = _controller.text;
    final selection = _controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final safeStart = start.clamp(0, text.length);
    final safeEnd = end.clamp(0, text.length);
    final replaced = text.replaceRange(safeStart, safeEnd, value);
    _controller.value = TextEditingValue(
      text: replaced,
      selection: TextSelection.collapsed(offset: safeStart + value.length),
    );
    setState(_recompile);
    _editorFocusNode.requestFocus();
  }

  void _showEditorUxSheet() {
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
                  Text(
                    context.tr.bdfd_editor_ux_title,
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(context.tr.bdfd_editor_includes),
              const SizedBox(height: 6),
              Text(context.tr.bdfd_editor_auto_indent),
              Text(context.tr.bdfd_editor_indent_guides),
              Text(context.tr.bdfd_editor_quick_keys),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.codeSurface : AppTheme.codeSurfaceVariant,
      appBar: AppBar(
        backgroundColor:
            isDark ? const Color(0xFF252526) : const Color(0xFF37474F),
        title: Text(
          widget.title ?? context.tr.bdfd_editor_title,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: context.tr.bdfd_editor_docs,
            icon: const Icon(Icons.menu_book, color: Colors.white70),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const BdfdDocsPage()),
              );
            },
          ),
          IconButton(
            tooltip: context.tr.bdfd_editor_wrap_toggle,
            icon: Icon(
              _wordWrap ? Icons.wrap_text : Icons.format_align_left,
              color: Colors.white70,
            ),
            onPressed: () => setState(() => _wordWrap = !_wordWrap),
          ),
          IconButton(
            tooltip: context.tr.bdfd_editor_ux_title,
            icon: const Icon(
              Icons.tips_and_updates_outlined,
              color: Colors.white70,
            ),
            onPressed: _showEditorUxSheet,
          ),
          IconButton(
            tooltip: context.tr.bdfd_editor_diagnostics_toggle,
            icon: Icon(
              _showDiagnostics ? Icons.bug_report : Icons.bug_report_outlined,
              color:
                  _hasErrors
                      ? AppTheme.error
                      : (_diagnostics.isNotEmpty
                          ? AppTheme.warning
                          : AppTheme.success),
            ),
            onPressed:
                () => setState(() => _showDiagnostics = !_showDiagnostics),
          ),
          IconButton(
            tooltip: context.tr.bdfd_editor_toggle_indent,
            icon: Icon(
              _showIndentGuides
                  ? Icons.format_indent_increase
                  : Icons.format_indent_decrease,
              color: Colors.white70,
            ),
            onPressed:
                () => setState(() => _showIndentGuides = !_showIndentGuides),
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
          children: [
            Expanded(child: _buildEditorBody()),
            if (!_isDesktopLike) _buildMobileSpecialCharsBar(),
            if (_showDiagnostics) _buildDiagnosticsBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditorBody() {
    final editorField = _buildTextField();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_wordWrap) {
          return Stack(
            children: [
              _buildIndentGuidesOverlay(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_buildLineNumbers(), Expanded(child: editorField)],
              ),
              _buildSignatureHintOverlay(constraints),
              _buildAutocompleteOverlay(constraints),
            ],
          );
        }

        return Stack(
          children: [
            _buildIndentGuidesOverlay(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLineNumbers(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _editorHorizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: IntrinsicWidth(child: editorField),
                  ),
                ),
              ],
            ),
            _buildSignatureHintOverlay(constraints),
            _buildAutocompleteOverlay(constraints),
          ],
        );
      },
    );
  }

  Widget _buildIndentGuidesOverlay() {
    if (!_showIndentGuides) {
      return const SizedBox.shrink();
    }

    final scrollY =
        _editorScrollController.hasClients
            ? _editorScrollController.offset
            : 0.0;
    final scrollX =
        (!_wordWrap && _editorHorizontalScrollController.hasClients)
            ? _editorHorizontalScrollController.offset
            : 0.0;

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: BdfdIndentGuidesPainter(
            source: _controller.text,
            activeLine: _activeGuideLine,
            lineNumberGutterWidth: _lineNumberGutterWidth,
            scrollX: scrollX,
            scrollY: scrollY,
            showHorizontalOffset: !_wordWrap,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSpecialCharsBar() {
    final theme = Theme.of(context);
    final chars = <String>[r'$', '<:', ';', '[', ']'];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2328),
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.premiumGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                border: Border.all(
                  color: AppTheme.premiumGold.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                onTap: _showEditorUxSheet,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    'EDITOR UX',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.premiumGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Row(
                children: chars
                    .map(
                      (char) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            minimumSize: const Size(48, 38),
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () => _insertAtCaret(char),
                          child: Text(
                            char,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignatureHintOverlay(BoxConstraints constraints) {
    if (!_isSignatureHintVisible) {
      return const SizedBox.shrink();
    }

    final ctx = _signatureContext!;

    const lineHeight = 20.0;
    const charWidth = 7.8;
    const editorTopPadding = 12.0;
    const editorLeftPadding = 8.0;

    final caret = _caretLineColumn();

    final scrollY =
        _editorScrollController.hasClients
            ? _editorScrollController.offset
            : 0.0;
    final scrollX =
        (!_wordWrap && _editorHorizontalScrollController.hasClients)
            ? _editorHorizontalScrollController.offset
            : 0.0;

    final desiredLeft =
        _lineNumberGutterWidth +
        editorLeftPadding +
        (caret.column * charWidth) -
        scrollX;
    // Position above the current line.
    final desiredTop =
        editorTopPadding + (caret.line * lineHeight) - scrollY - 32;

    final minLeft = _lineNumberGutterWidth + 4;
    final maxLeft =
        constraints.maxWidth <= minLeft
            ? minLeft
            : (constraints.maxWidth - 320).clamp(minLeft, constraints.maxWidth);
    final left = desiredLeft.clamp(minLeft, maxLeft);
    final maxTop =
        constraints.maxHeight <= 0
            ? 0.0
            : (constraints.maxHeight - 40).clamp(0.0, constraints.maxHeight);
    final top = desiredTop.clamp(0.0, maxTop);

    // Build the parameter spans with the active one highlighted.
    final spans = <InlineSpan>[];
    spans.add(
      TextSpan(
        text: '${ctx.functionName}[ ',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: _BdfdSyntaxColors.function,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    for (var i = 0; i < ctx.parameters.length; i++) {
      if (i > 0) {
        spans.add(
          const TextSpan(
            text: ' ; ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: _BdfdSyntaxColors.semicolon,
            ),
          ),
        );
      }

      final isActive = i == ctx.activeIndex;
      spans.add(
        TextSpan(
          text: ctx.parameters[i],
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: isActive ? Colors.white : AppTheme.grey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            decoration: isActive ? TextDecoration.underline : null,
            decorationColor: isActive ? AppTheme.info : null,
          ),
        ),
      );
    }

    spans.add(
      const TextSpan(
        text: ' ]',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          color: _BdfdSyntaxColors.bracket,
        ),
      ),
    );

    return Positioned(
      left: left,
      top: top,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: const Color(0xFF1E293B),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: RichText(text: TextSpan(children: spans)),
        ),
      ),
    );
  }

  Widget _buildAutocompleteOverlay(BoxConstraints constraints) {
    if (!_isAutocompleteVisible) {
      return const SizedBox.shrink();
    }

    const lineHeight = 20.0;
    const charWidth = 7.8;
    const editorTopPadding = 12.0;
    const editorLeftPadding = 8.0;
    const itemHeight = 30.0;
    const panelVerticalPadding = 8.0;
    const panelMaxHeight = 168.0;

    final caret = _caretLineColumn();
    final panelHeight = (_autocompleteEntries.length * itemHeight +
            panelVerticalPadding)
        .clamp(80.0, panelMaxHeight);

    final scrollY =
        _editorScrollController.hasClients
            ? _editorScrollController.offset
            : 0.0;
    final scrollX =
        (!_wordWrap && _editorHorizontalScrollController.hasClients)
            ? _editorHorizontalScrollController.offset
            : 0.0;

    final desiredLeft =
        _lineNumberGutterWidth +
        editorLeftPadding +
        (caret.column * charWidth) -
        scrollX;
    final desiredTop =
        editorTopPadding + ((caret.line + 1) * lineHeight) - scrollY + 4;

    final minLeft = _lineNumberGutterWidth + 4;
    final maxLeft = (constraints.maxWidth - 220).clamp(
      minLeft,
      double.infinity,
    );
    final left = desiredLeft.clamp(minLeft, maxLeft);
    final minTop = editorTopPadding + lineHeight;
    final maxTop = (constraints.maxHeight - panelHeight).clamp(
      minTop,
      double.infinity,
    );
    final top = desiredTop.clamp(minTop, maxTop);

    return Positioned(
      left: left,
      top: top,
      width: 220,
      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        color: const Color(0xFF22313A),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: panelMaxHeight),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: _autocompleteEntries.length,
            itemBuilder: (_, index) {
              final entry = _autocompleteEntries[index];
              final isSelected = index == _autocompleteSelectedIndex;
              final isEmoji = _autocompleteMode == _AutocompleteMode.emoji;
              final hasNewline = entry.value.contains('\n');
              return InkWell(
                onHover: (hovering) {
                  if (!mounted ||
                      !hovering ||
                      _autocompleteSelectedIndex == index) {
                    return;
                  }
                  setState(() {
                    _autocompleteSelectedIndex = index;
                  });
                },
                onTap:
                    () => _insertAutocompleteTemplate(entry.key, entry.value),
                child: Container(
                  height: itemHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? const Color(0xFF094771)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isEmoji
                            ? Icons.emoji_emotions_outlined
                            : hasNewline
                                ? Icons.segment
                                : Icons.functions,
                        size: 14,
                        color: isSelected ? Colors.white : AppTheme.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.value.replaceAll('\n', ' ↵ '),
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isSelected ? Colors.white : AppTheme.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white70 : AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLineNumbers() {
    final count = _lineCount;

    return SizedBox(
      width: _lineNumberGutterWidth,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: _lineNumberScrollController,
          itemCount: count,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(top: 12),
          itemBuilder: (_, index) {
            return SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      height: 1.54,
                      color: AppTheme.grey,
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
      onKeyEvent: _handleEditorKey,
      child: TextField(
        controller: _controller,
        focusNode: _editorFocusNode,
        scrollController: _editorScrollController,
        inputFormatters: const [_BdfdAutoIndentFormatter()],
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 13,
          height: 1.54,
          color: _BdfdSyntaxColors.text,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          hintText: context.tr.cmd_bdfd_script_hint,
          hintStyle: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: AppTheme.grey,
          ),
        ),
        cursorColor: Colors.white,
        onChanged: (_) => setState(_recompile),
      ),
    );
  }

  Widget _buildDiagnosticsBar() {
    final diagnostics = _diagnostics;
    final isEmpty = _controller.text.trim().isEmpty;

    if (isEmpty || diagnostics.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.5),
          border: Border(top: BorderSide(color: AppTheme.success)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, size: 16, color: AppTheme.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEmpty
                    ? context.tr.bdfd_editor_empty
                    : context.tr.cmd_bdfd_diagnostics_clean,
                style: TextStyle(fontSize: 12, color: AppTheme.success),
              ),
            ),
          ],
        ),
      );
    }

    final bgColor =
        _hasErrors
            ? AppTheme.error.withValues(alpha: 0.5)
            : AppTheme.warning.withValues(alpha: 0.5);
    final borderColor = _hasErrors ? AppTheme.error : AppTheme.warning;

    return Container(
      constraints: const BoxConstraints(maxHeight: 140),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: ListView(
        shrinkWrap: true,
        children:
            diagnostics.map((d) {
              final isError = d.severity == BdfdCompileDiagnosticSeverity.error;
              final icon =
                  isError ? Icons.error_outline : Icons.warning_amber_rounded;
              final color = isError ? AppTheme.error : AppTheme.warning;
              final loc =
                  (d.line != null && d.column != null)
                      ? 'L${d.line}:C${d.column} '
                      : '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$loc${d.message}',
                        style: TextStyle(fontSize: 12, color: color),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }
}
