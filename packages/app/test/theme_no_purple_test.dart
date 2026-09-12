import 'dart:math' as math;

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// L'utilisateur voyait encore du violet « dans plein de pages », en thème
/// CLAIR surtout : l'AppBar claire était peinte en `brandPrimary` plein et la
/// pastille de l'item de navigation sélectionné en `brandPrimary` à 12 %.
///
/// Ce test verrouille la règle : le violet n'est plus qu'un ACCENT d'action
/// principale. Ni la barre d'application, ni un état sélectionné de navigation
/// ne doivent être teintés.
void main() {
  /// « Quantité de couleur » d'une teinte : écart entre le canal le plus fort
  /// et le plus faible, ramené sur 0..1.
  ///
  /// On n'utilise PAS la saturation HSL : elle est instable sur les blancs et
  /// les noirs (un blanc cassé `#FCF8FA` affiche une saturation de 0.40, contre
  /// 0.58 pour le violet de marque `#6A0FA2` — impossible de distinguer les
  /// deux). La chroma, elle, vaut 0.016 pour ce blanc et 0.58 pour le violet.
  double chromaOf(Color color) {
    final channels = <double>[color.r, color.g, color.b];
    return channels.reduce(math.max) - channels.reduce(math.min);
  }

  /// Vrai si la teinte tombe dans le violet/magenta (260°–340°).
  ///
  /// C'est le critère qui distingue vraiment « accent bleu ardoise » (teinte
  /// ~225°, ce que produit la variante M3 `neutral`) de « violet de marque »
  /// (teinte ~277°). La chroma seule ne suffit pas : un ardoise légèrement
  /// bleuté la dépasse sans être violet pour autant.
  bool isVioletHue(Color color) {
    final hue = HSLColor.fromColor(color).hue;
    return hue >= 260 && hue < 340;
  }

  const purples = <Color>[
    AppTheme.brandPrimary,
    AppTheme.brandSecondary,
    AppTheme.brandPurpleSoft,
  ];

  Future<Color> selectedFill(WidgetTester tester, ThemeData theme) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Scaffold(
          body: FloatingGlassNavBar(
            items: [
              FloatingGlassNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Accueil',
                selected: true,
                onTap: () {},
              ),
              FloatingGlassNavItem(
                icon: Icons.terminal_rounded,
                label: 'Cmd',
                selected: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    final fills = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((w) => (w.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .where((c) => c.a > 0)
        .toList();

    expect(fills, hasLength(1), reason: 'un seul item sélectionné');
    return fills.single;
  }

  test('accent `colorScheme.primary` : neutre dans les deux thèmes', () {
    // ~43 usages de `colorScheme.primary` (états sélectionnés, liens, accents)
    // sont répartis dans toute l'app : si ce rôle redevient violet, le violet
    // revient « dans plein de pages » sans qu'aucun autre test ne bronche.
    for (final theme in <ThemeData>[
      AppTheme.lightTheme(),
      AppTheme.darkTheme(),
    ]) {
      final primary = theme.colorScheme.primary;
      final label = theme.brightness == Brightness.light ? 'clair' : 'sombre';
      // ignore: avoid_print
      print(
        'PRIMARY $label -> $primary (chroma '
        '${chromaOf(primary).toStringAsFixed(3)}, '
        'on=${theme.colorScheme.onPrimary})',
      );
      expect(purples.contains(primary), isFalse);
      expect(
        isVioletHue(primary),
        isFalse,
        reason: 'l\'accent $label est encore violet',
      );
      expect(chromaOf(primary), lessThan(0.12));
    }
  });

  test('AppBar : neutre en clair comme en sombre', () {
    for (final theme in <ThemeData>[
      AppTheme.lightTheme(),
      AppTheme.darkTheme(),
    ]) {
      final appBar = theme.appBarTheme.backgroundColor!;
      final label = theme.brightness == Brightness.light ? 'clair' : 'sombre';
      // ignore: avoid_print
      print(
        'APPBAR $label -> $appBar (chroma '
        '${chromaOf(appBar).toStringAsFixed(3)}, luminance '
        '${appBar.computeLuminance().toStringAsFixed(3)})',
      );
      expect(
        purples.contains(appBar),
        isFalse,
        reason: 'la barre d\'application $label est pleine couleur de marque',
      );
      expect(
        chromaOf(appBar),
        lessThan(0.06),
        reason: 'la barre d\'application $label est encore teintée (chroma)',
      );
    }

    final light = AppTheme.lightTheme();
    expect(
      light.appBarTheme.backgroundColor,
      light.colorScheme.surface,
      reason: 'en clair l\'AppBar doit être la surface M3, comme Google',
    );
    expect(light.appBarTheme.foregroundColor, light.colorScheme.onSurface);
  });

  testWidgets('item sélectionné (clair) : pastille neutre', (tester) async {
    final fill = await selectedFill(tester, AppTheme.lightTheme());
    // ignore: avoid_print
    print(
      'NAV CLAIR sélection -> $fill (chroma '
      '${chromaOf(fill).toStringAsFixed(3)})',
    );
    expect(purples.contains(fill), isFalse);
    expect(chromaOf(fill), lessThan(0.06));
  });

  testWidgets('item sélectionné (sombre) : pastille neutre', (tester) async {
    final fill = await selectedFill(tester, AppTheme.darkTheme());
    // ignore: avoid_print
    print(
      'NAV SOMBRE sélection -> $fill (chroma '
      '${chromaOf(fill).toStringAsFixed(3)})',
    );
    expect(purples.contains(fill), isFalse);
    expect(chromaOf(fill), lessThan(0.06));
  });
}
