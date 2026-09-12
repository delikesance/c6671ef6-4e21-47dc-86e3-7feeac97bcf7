import 'package:bot_creator/core/code_editor/code_editor_settings.dart';
import 'package:bot_creator/core/code_editor/code_editor_theme_data.dart';
import 'package:bot_creator/features/settings/presentation/code_editor_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'aperçu JS des réglages de l'éditeur doit refléter le VRAI rendu des
/// éditeurs (même moteur de colorisation, `hljsTheme` de la palette). Il
/// peignait auparavant chaque ligne d'une seule couleur : l'aperçu était plat
/// et ne changeait quasiment pas avec le thème.
void main() {
  const snippet = '''
const retries = 3; // tentatives restantes
function ping(name) { return `Pong \${name}`; }
''';

  Set<Color> colorsOf(CodeEditorTheme theme) {
    final span = buildJsHighlightedSpan(
      snippet,
      settings: const CodeEditorSettings(),
      colors: CodeEditorThemeColors.forTheme(theme),
    );

    final found = <Color>{};
    void walk(InlineSpan node) {
      if (node is! TextSpan) return;
      final color = node.style?.color;
      if (color != null) found.add(color);
      for (final child in node.children ?? const <InlineSpan>[]) {
        walk(child);
      }
    }

    walk(span);
    return found;
  }

  test('aperçu JS : plusieurs couleurs de tokens, pas une seule', () {
    final palette = colorsOf(CodeEditorTheme.rosePine);
    // ignore: avoid_print
    print(
      'APERCU JS Rosé Pine -> ${palette.length} couleurs: '
      '${palette.map((c) => c.toARGB32().toRadixString(16)).join(', ')}',
    );
    expect(
      palette.length,
      greaterThanOrEqualTo(3),
      reason: 'mots-clés, chaînes, nombres et commentaires doivent différer',
    );
  });

  test('aperçu JS : deux thèmes donnent deux colorations différentes', () {
    final rosePine = colorsOf(CodeEditorTheme.rosePine);
    final dawn = colorsOf(CodeEditorTheme.rosePineDawn);
    final mono = colorsOf(CodeEditorTheme.monokai);

    expect(rosePine, isNot(equals(dawn)));
    expect(rosePine, isNot(equals(mono)));
  });
}
