import './code_editor_theme_data.dart';
import './editor_theme_scope.dart';
import 'package:flutter/material.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/re_highlight.dart';

final _highlight = Highlight()..registerLanguage('javascript', langJavascript);

/// Syntax-highlighted [TextEditingController] for JavaScript command scripts.
///
/// The token colours come from the palette the user selected in the code editor
/// settings ([CodeEditorThemeColors.hljsTheme]). Rosé Pine is the default of
/// [CodeEditorSettings], so a controller that was never handed a palette still
/// highlights with Rosé Pine instead of the previously hard-coded GitHub Dark.
class JsSyntaxController extends TextEditingController {
  JsSyntaxController({super.text, CodeEditorThemeColors? themeColors})
    : _themeColors = themeColors ?? defaultCodeEditorThemeColors;

  CodeEditorThemeColors _themeColors;
  TextStyle? _baseStyle;

  static const _fallbackBaseStyle = TextStyle(
    fontFamily: 'Consolas, Courier New, monospace',
    fontSize: 13,
    height: 1.54,
  );

  /// Palette currently colouring the code.
  CodeEditorThemeColors get themeColors => _themeColors;

  /// Swaps the palette and re-renders the highlighting.
  ///
  /// Only notifies when the palette really changed, and never recreates the
  /// controller: the selection, the scroll offset and the undo history survive
  /// a theme change. (Recreating the controller from `build()` is what used to
  /// crash with `LateInitializationError`.)
  set themeColors(CodeEditorThemeColors value) {
    if (identical(_themeColors, value)) {
      return;
    }
    _themeColors = value;
    notifyListeners();
  }

  /// Font family / size / line height of the user settings; `null` keeps the
  /// style handed over by the widget.
  TextStyle? get baseStyle => _baseStyle;

  set baseStyle(TextStyle? value) {
    if (_baseStyle == value) {
      return;
    }
    _baseStyle = value;
    notifyListeners();
  }

  /// Base style actually used for rendering: the caller style (widget style or
  /// [baseStyle]) forced to the theme text colour, so the code can never end up
  /// with an unreadable colour on the editor background.
  TextStyle _resolveBaseStyle(TextStyle? style) {
    final base = _baseStyle ?? style ?? _fallbackBaseStyle;
    return base.copyWith(color: _themeColors.text);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    final baseStyle = _resolveBaseStyle(style);
    if (source.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    try {
      final result = _highlight.highlight(code: source, language: 'javascript');
      final renderer = TextSpanRenderer(baseStyle, _themeColors.hljsTheme);
      result.render(renderer);
      final span = renderer.span;
      if (span == null) {
        return TextSpan(text: source, style: baseStyle);
      }
      return span;
    } catch (_) {
      return TextSpan(text: source, style: baseStyle);
    }
  }
}
