import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/core/js_editor/editor_theme_scope.dart';
import 'package:bot_creator_shared/utils/bdfd_lexer.dart';
import 'package:flutter/widgets.dart';

/// Contrôleur de texte qui colore un script BDFD.
///
/// Les couleurs viennent de la palette choisie par l'utilisateur dans les
/// réglages de l'éditeur ([CodeEditorThemeColors]) ; le lexer BDFD découpe la
/// source en jetons, chacun rendu avec la couleur de son type.
///
/// Si la couverture des jetons ne reconstitue pas exactement la source, le
/// rendu retombe sur du texte brut : mieux vaut un document non coloré qu'un
/// décalage entre le texte peint et la position du curseur.
class BdfdSyntaxController extends TextEditingController {
  BdfdSyntaxController({super.text, CodeEditorThemeColors? themeColors})
    : _themeColors = themeColors ?? defaultCodeEditorThemeColors;

  CodeEditorThemeColors _themeColors;

  /// Palette qui colore le script ; Rosé Pine tant que les réglages
  /// utilisateur ne sont pas résolus (voir [CodeEditorThemeColors.forTheme]).
  CodeEditorThemeColors get themeColors => _themeColors;

  /// Change la palette et relance le rendu de la coloration.
  ///
  /// Le contrôleur n'est jamais recréé — notifier les auditeurs suffit — donc
  /// la sélection, l'offset de défilement et l'historique d'annulation
  /// survivent à un changement de thème. (Recréer le contrôleur depuis
  /// `build()` est ce qui levait `LateInitializationError`.)
  set themeColors(CodeEditorThemeColors value) {
    if (identical(_themeColors, value)) {
      return;
    }
    _themeColors = value;
    notifyListeners();
  }

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

    final functionColor = _themeColors.function;
    final bracketColor = _themeColors.bracket;
    final semicolonColor = _themeColors.semicolon;
    final textColor = _themeColors.text;

    for (final token in result.tokens) {
      if (token.type == BdfdTokenType.eof) {
        continue;
      }

      final Color color;
      switch (token.type) {
        case BdfdTokenType.function:
          color = functionColor;
        case BdfdTokenType.openBracket:
        case BdfdTokenType.closeBracket:
          color = bracketColor;
        case BdfdTokenType.semicolon:
          color = semicolonColor;
        default:
          color = textColor;
      }

      covered.write(token.lexeme);
      children.add(
        TextSpan(
          text: token.lexeme,
          style: style?.copyWith(color: color),
        ),
      );
    }

    // Filet de sécurité : si les jetons ne couvrent pas exactement la source,
    // on rend le texte brut pour ne pas décaler le curseur.
    if (covered.toString() != source) {
      return TextSpan(text: source, style: style);
    }

    // Composition IME en cours : la région composée est encadrée à part.
    if (withComposing && value.isComposingRangeValid) {
      return TextSpan(
        style: style,
        children: _splitSpanAtComposing(children, style),
      );
    }

    return TextSpan(style: style, children: children);
  }

  /// Découpe les jetons aux bornes de la région de composition pour que
  /// Flutter puisse styler cette région (soulignement) sans perdre la
  /// coloration.
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
        // Entièrement hors de la région composée : jetons conservés tels quels.
        result.add(child);
      } else if (offset >= composing.start && childEnd <= composing.end) {
        // Entièrement dans la région composée : souligné.
        result.add(
          TextSpan(
            text: child.text,
            style: child.style?.copyWith(decoration: TextDecoration.underline),
          ),
        );
      } else {
        // À cheval : découpe.
        final beforeLen = (composing.start - offset).clamp(0, len);
        final insideLen = (composing.end - (offset + beforeLen)).clamp(
          0,
          len - beforeLen,
        );
        final afterLen = len - beforeLen - insideLen;

        if (beforeLen > 0) {
          result.add(
            TextSpan(
              text: child.text!.substring(0, beforeLen),
              style: child.style,
            ),
          );
        }
        if (insideLen > 0) {
          result.add(
            TextSpan(
              text: child.text!.substring(beforeLen, beforeLen + insideLen),
              style: child.style?.copyWith(
                decoration: TextDecoration.underline,
              ),
            ),
          );
        }
        if (afterLen > 0) {
          result.add(
            TextSpan(
              text: child.text!.substring(beforeLen + insideLen),
              style: child.style,
            ),
          );
        }
      }

      offset = childEnd;
    }

    return result;
  }
}
