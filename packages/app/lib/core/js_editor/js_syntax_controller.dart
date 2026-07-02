import 'package:flutter/material.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github-dark.dart';

final _highlight = Highlight()..registerLanguage('javascript', langJavascript);

/// Syntax-highlighted [TextEditingController] for JavaScript command scripts.
class JsSyntaxController extends TextEditingController {
  JsSyntaxController({super.text});

  static const _baseStyle = TextStyle(
    fontFamily: 'Consolas, Courier New, monospace',
    fontSize: 13,
    height: 1.54,
    color: Color(0xffc9d1d9),
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final source = text;
    if (source.isEmpty) {
      return TextSpan(text: '', style: style ?? _baseStyle);
    }

    try {
      final result = _highlight.highlight(code: source, language: 'javascript');
      final renderer = TextSpanRenderer(style ?? _baseStyle, githubDarkTheme);
      result.render(renderer);
      final span = renderer.span;
      if (span == null) {
        return TextSpan(text: source, style: style ?? _baseStyle);
      }
      return span;
    } catch (_) {
      return TextSpan(text: source, style: style ?? _baseStyle);
    }
  }
}
