import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:flutter/material.dart';
import 'package:re_highlight/styles/base16/onedark.dart';
import 'package:re_highlight/styles/base16/ros-pine-dawn.dart';
import 'package:re_highlight/styles/base16/ros-pine.dart';
import 'package:re_highlight/styles/github-dark.dart';
import 'package:re_highlight/styles/github.dart';
import 'package:re_highlight/styles/monokai.dart';
import 'package:re_highlight/styles/vs2015.dart';

/// Complete colour palette of a code editor for a given [CodeEditorTheme].
///
/// Two consumers are expected:
///  * the syntax highlighters (`re_highlight` via [hljsTheme], plus the BDFD
///    parser) which need the individual token colours;
///  * the surrounding editor chrome (gutter, active line, selection, cursor)
///    which needs [background], [surface] and friends.
///
/// Always obtain an instance through [CodeEditorThemeColors.forTheme] so the
/// palette stays in sync with the selected [CodeEditorTheme].
class CodeEditorThemeColors {
  final Color background;
  final Color surface;
  final Color text;
  final Color comment;
  final Color keyword;
  final Color function;
  final Color string;
  final Color number;
  final Color punctuation;
  final Color bracket;
  final Color semicolon;
  final Color selection;
  final Color gutterBackground;
  final Color gutterText;
  final Color activeLineBackground;
  final Color indentGuide;
  final Color cursor;

  /// Theme map consumed by `package:highlight` / `package:re_highlight`.
  final Map<String, TextStyle> hljsTheme;

  const CodeEditorThemeColors({
    required this.background,
    required this.surface,
    required this.text,
    required this.comment,
    required this.keyword,
    required this.function,
    required this.string,
    required this.number,
    required this.punctuation,
    required this.bracket,
    required this.semicolon,
    required this.selection,
    required this.gutterBackground,
    required this.gutterText,
    required this.activeLineBackground,
    required this.indentGuide,
    required this.cursor,
    required this.hljsTheme,
  });

  /// Returns the palette of [theme].
  ///
  /// The editor palettes are deliberately independent from the app light/dark
  /// theme (`AppTheme`): a theme like Rosé Pine must render the same way
  /// whatever the surrounding app theme is. Only the surrounding chrome of the
  /// settings page uses the app tokens.
  static CodeEditorThemeColors forTheme(CodeEditorTheme theme) {
    switch (theme) {
      case CodeEditorTheme.rosePine:
        return const CodeEditorThemeColors(
          background: Color(0xFF191724),
          surface: Color(0xFF1F1D2E),
          text: Color(0xFFE0DEF4),
          comment: Color(0xFF6E6A86),
          keyword: Color(0xFF31748F),
          function: Color(0xFFEB6F92), // Love / Rose
          string: Color(0xFFF6C177), // Gold
          number: Color(0xFFEBBCBA), // Rose
          punctuation: Color(0xFF908CAA),
          bracket: Color(0xFF9CCFD8), // Foam
          semicolon: Color(0xFFC4A7E7), // Iris
          selection: Color(0xFF26233A),
          gutterBackground: Color(0xFF16141F),
          gutterText: Color(0xFF555169),
          activeLineBackground: Color(0xFF211F30),
          indentGuide: Color(0x336E6A86),
          cursor: Color(0xFF56949F),
          hljsTheme: rosPineTheme,
        );

      case CodeEditorTheme.rosePineDawn:
        return const CodeEditorThemeColors(
          background: Color(0xFFFAF4ED),
          surface: Color(0xFFFFFDF8),
          text: Color(0xFF575279),
          comment: Color(0xFF9893A5),
          keyword: Color(0xFF286983), // Pine
          function: Color(0xFFB4637A), // Love
          string: Color(0xFFEA9D34), // Gold
          number: Color(0xFFD7827E), // Rose
          punctuation: Color(0xFF797593),
          bracket: Color(0xFF56949F), // Foam
          semicolon: Color(0xFF907AA9), // Iris
          selection: Color(0xFFF2E9DE),
          gutterBackground: Color(0xFFF4EDE4),
          gutterText: Color(0xFF9893A5),
          activeLineBackground: Color(0xFFF0E7DB),
          indentGuide: Color(0x339893A5),
          cursor: Color(0xFF286983),
          hljsTheme: rosPineDawnTheme,
        );

      case CodeEditorTheme.vsCodeDark:
        return const CodeEditorThemeColors(
          background: Color(0xFF1E1E1E),
          surface: Color(0xFF252526),
          text: Color(0xFFD4D4D4),
          comment: Color(0xFF6A9955),
          keyword: Color(0xFF569CD6),
          function: Color(0xFFDCDCAA),
          string: Color(0xFFCE9178),
          number: Color(0xFFB5CEA8),
          punctuation: Color(0xFFD4D4D4),
          bracket: Color(0xFFFFD700),
          semicolon: Color(0xFFE51400),
          selection: Color(0xFF264F78),
          gutterBackground: Color(0xFF1E1E1E),
          gutterText: Color(0xFF858585),
          activeLineBackground: Color(0xFF282828),
          indentGuide: Color(0x2BFFFFFF),
          cursor: Color(0xFFAEAFAD),
          hljsTheme: vs2015Theme,
        );

      case CodeEditorTheme.githubDark:
        return const CodeEditorThemeColors(
          background: Color(0xFF0D1117),
          surface: Color(0xFF161B22),
          text: Color(0xFFC9D1D9),
          comment: Color(0xFF8B949E),
          keyword: Color(0xFFFF7B72),
          function: Color(0xFFD2A8FF),
          string: Color(0xFFA5D6FF),
          number: Color(0xFF79C0FF),
          punctuation: Color(0xFFC9D1D9),
          bracket: Color(0xFF79C0FF),
          semicolon: Color(0xFFFF7B72),
          selection: Color(0xFF1F6FEB),
          gutterBackground: Color(0xFF0D1117),
          gutterText: Color(0xFF6E7681),
          activeLineBackground: Color(0xFF161B22),
          indentGuide: Color(0x26C9D1D9),
          cursor: Color(0xFF58A6FF),
          hljsTheme: githubDarkTheme,
        );

      case CodeEditorTheme.githubLight:
        return const CodeEditorThemeColors(
          background: Color(0xFFFFFFFF),
          surface: Color(0xFFF6F8FA),
          text: Color(0xFF24292F),
          comment: Color(0xFF6E7781),
          keyword: Color(0xFFCF222E),
          function: Color(0xFF8250DF),
          string: Color(0xFF0A3069),
          number: Color(0xFF0550AE),
          punctuation: Color(0xFF24292F),
          bracket: Color(0xFF0969DA),
          semicolon: Color(0xFFCF222E),
          selection: Color(0xFFB6E3FF),
          gutterBackground: Color(0xFFF6F8FA),
          gutterText: Color(0xFF8C959F),
          activeLineBackground: Color(0xFFF1F4F8),
          indentGuide: Color(0x26000000),
          cursor: Color(0xFF0969DA),
          hljsTheme: githubTheme,
        );

      case CodeEditorTheme.oneDark:
        return const CodeEditorThemeColors(
          background: Color(0xFF282C34),
          surface: Color(0xFF21252B),
          text: Color(0xFFABB2BF),
          comment: Color(0xFF5C6370),
          keyword: Color(0xFFC678DD),
          function: Color(0xFF61AFEF),
          string: Color(0xFF98C379),
          number: Color(0xFFD19A66),
          punctuation: Color(0xFFABB2BF),
          bracket: Color(0xFFE5C07B),
          semicolon: Color(0xFFE06C75),
          selection: Color(0xFF3E4451),
          gutterBackground: Color(0xFF21252B),
          gutterText: Color(0xFF4B5263),
          activeLineBackground: Color(0xFF2C313A),
          indentGuide: Color(0x2BABB2BF),
          cursor: Color(0xFF528BFF),
          hljsTheme: onedarkTheme,
        );

      case CodeEditorTheme.monokai:
        return const CodeEditorThemeColors(
          background: Color(0xFF272822),
          surface: Color(0xFF1E1F1C),
          text: Color(0xFFF8F8F2),
          comment: Color(0xFF75715E),
          keyword: Color(0xFFF92672),
          function: Color(0xFFA6E22E),
          string: Color(0xFFE6DB74),
          number: Color(0xFFAE81FF),
          punctuation: Color(0xFFF8F8F2),
          bracket: Color(0xFF66D9EF),
          semicolon: Color(0xFFF92672),
          selection: Color(0xFF49483E),
          gutterBackground: Color(0xFF1E1F1C),
          gutterText: Color(0xFF75715E),
          activeLineBackground: Color(0xFF3E3D32),
          indentGuide: Color(0x2BF8F8F2),
          cursor: Color(0xFFF8F8F0),
          hljsTheme: monokaiTheme,
        );
    }
  }
}
