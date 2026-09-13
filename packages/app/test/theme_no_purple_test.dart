import 'dart:math' as math;

import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Le violet est un ACCENT D'ACTION, pas un habillage.
///
/// Historique : l'app peignait d'abord sa marque partout (AppBar pleine couleur,
/// pastille de navigation violette, `primary` violet dans ~43 usages), puis une
/// refonte a tout neutralisé. Décision actuelle : le chrome reste NEUTRE et le
/// violet revient, comme accent, uniquement sur les zones d'ACTION.
///
/// Ce test verrouille les DEUX moitiés de la règle :
///   * ce qui doit rester neutre — AppBar, fonds, `colorScheme.primary`, et le
///     REMPLISSAGE de la pastille de navigation ;
///   * ce qui porte légitimement l'accent — boutons d'action principale,
///     anneaux de focus, contrôles actifs (switch/checkbox/radio/segments) et
///     bordure d'indicateur de l'item de navigation sélectionné — avec les
///     contrastes WCAG qui vont avec (≥ 4.5:1 sur du texte, ≥ 3:1 sur un
///     élément d'interface).
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

  /// Ratio de contraste WCAG 2.1 (implémentation locale).
  double contrast(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final lighter = la > lb ? la : lb;
    final darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  const purples = <Color>[
    AppTheme.brandPrimary,
    AppTheme.brandSecondary,
    AppTheme.brandPurpleSoft,
  ];

  final themes = <String, ThemeData>{
    'clair': AppTheme.lightTheme(),
    'sombre': AppTheme.darkTheme(),
  };

  group('Ce qui reste neutre par défaut', () {
    test('`colorScheme.primary` : neutre dans les deux thèmes', () {
      // ~43 usages de `colorScheme.primary` (états sélectionnés, liens,
      // accents) sont répartis dans toute l'app : si ce rôle redevient violet,
      // le violet revient « dans plein de pages » sans qu'aucun autre test ne
      // bronche. L'accent, lui, passe par `HomeTokens.accent`.
      for (final entry in themes.entries) {
        final label = entry.key;
        final primary = entry.value.colorScheme.primary;
        // ignore: avoid_print
        print(
          'PRIMARY $label -> $primary (chroma '
          '${chromaOf(primary).toStringAsFixed(3)}, '
          'on=${entry.value.colorScheme.onPrimary})',
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
      for (final entry in themes.entries) {
        final theme = entry.value;
        final label = entry.key;
        final appBar = theme.appBarTheme.backgroundColor!;
        // ignore: avoid_print
        print(
          'APPBAR $label -> $appBar (chroma '
          '${chromaOf(appBar).toStringAsFixed(3)})',
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

      final light = themes['clair']!;
      expect(
        light.appBarTheme.backgroundColor,
        light.colorScheme.surface,
        reason: 'en clair l\'AppBar doit être la surface M3, comme Google',
      );
      expect(light.appBarTheme.foregroundColor, light.colorScheme.onSurface);
    });

    test('aucun fond global teinté', () {
      final light = themes['clair']!;
      final dark = themes['sombre']!;
      expect(light.scaffoldBackgroundColor, light.colorScheme.surface);
      expect(dark.scaffoldBackgroundColor, AppTheme.scaffoldDark);
      expect(chromaOf(dark.scaffoldBackgroundColor), lessThan(0.06));
      expect(chromaOf(light.scaffoldBackgroundColor), lessThan(0.06));
    });
  });

  group('Ce qui porte légitimement l\'accent', () {
    test('bouton d\'action principale : violet + texte lisible', () {
      // L'accent suit désormais la variante du MODE courant : violet de marque
      // en clair, violet éclairci en sombre (`graphite.accentDark`), seul
      // lisible sur les surfaces graphite.
      final expectedAccent = <Brightness, Color>{
        Brightness.light: AppTheme.brandPrimary,
        Brightness.dark: AppAppearancePreset.graphite.accentDark,
      };
      for (final entry in themes.entries) {
        final theme = entry.value;
        final label = entry.key;
        final tokens = theme.extension<HomeTokens>()!;
        final style = theme.filledButtonTheme.style!;
        final background = style.backgroundColor!.resolve(
          const <WidgetState>{},
        )!;
        final foreground = style.foregroundColor!.resolve(
          const <WidgetState>{},
        )!;
        // ignore: avoid_print
        print(
          'BOUTON $label -> $background / $foreground '
          '(${contrast(foreground, background).toStringAsFixed(2)}:1)',
        );
        expect(
          background,
          tokens.accent,
          reason: 'l\'action principale $label porte l\'accent du thème',
        );
        expect(
          background,
          expectedAccent[theme.brightness],
          reason: 'l\'action principale $label porte l\'accent de son mode',
        );
        expect(
          isVioletHue(background),
          isTrue,
          reason: 'l\'accent $label a perdu sa teinte',
        );
        expect(
          contrast(foreground, background),
          greaterThanOrEqualTo(4.5),
          reason: 'texte du bouton $label illisible',
        );
      }
    });

    test('anneau de focus : accent visible (≥ 3:1) dans les deux thèmes', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final label = entry.key;
        final tokens = theme.extension<HomeTokens>()!;
        final ring =
            (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
                .borderSide
                .color;
        final fill = Color.alphaBlend(
          theme.inputDecorationTheme.fillColor!,
          theme.scaffoldBackgroundColor,
        );
        // ignore: avoid_print
        print(
          'FOCUS $label -> $ring (chroma ${chromaOf(ring).toStringAsFixed(3)}, '
          '${contrast(ring, fill).toStringAsFixed(2)}:1 sur le champ)',
        );
        expect(ring, tokens.accentRing);
        expect(
          chromaOf(ring),
          greaterThan(0.06),
          reason: 'l\'anneau de focus $label n\'est plus coloré du tout',
        );
        expect(contrast(ring, fill), greaterThanOrEqualTo(3.0));
      }
    });

    test('contrôles actifs et onglet actif portent l\'accent', () {
      for (final entry in themes.entries) {
        final theme = entry.value;
        final accent = theme.extension<HomeTokens>()!.accent;
        const selected = <WidgetState>{WidgetState.selected};
        const idle = <WidgetState>{};

        expect(theme.switchTheme.trackColor!.resolve(selected), accent);
        expect(
          theme.switchTheme.trackColor!.resolve(idle),
          isNull,
          reason: 'au repos, le switch garde les rôles M3 neutres',
        );
        expect(theme.switchTheme.thumbColor!.resolve(selected), isNotNull);
        expect(theme.checkboxTheme.fillColor!.resolve(selected), accent);
        expect(theme.checkboxTheme.fillColor!.resolve(idle), isNull);
        expect(theme.radioTheme.fillColor!.resolve(selected), accent);
        expect(theme.radioTheme.fillColor!.resolve(idle), isNull);
        expect(
          theme.segmentedButtonTheme.style!.backgroundColor!.resolve(selected),
          accent,
        );
        expect(
          theme.tabBarTheme.indicatorColor,
          theme.extension<HomeTokens>()!.accentRing,
        );
      }
    });
  });

  group('Navigation : pastille neutre, indicateur d\'accent', () {
    Future<AnimatedContainer> selectedItem(
      WidgetTester tester,
      ThemeData theme,
    ) async {
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

      return tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byTooltip('Accueil'),
          matching: find.byType(AnimatedContainer),
        ),
      );
    }

    for (final entry in themes.entries) {
      testWidgets('item sélectionné (${entry.key}) : pastille neutre + '
          'indicateur d\'accent', (tester) async {
        final theme = entry.value;
        final tokens = theme.extension<HomeTokens>()!;
        final container = await selectedItem(tester, theme);
        final fill = (container.decoration! as BoxDecoration).color!;
        final indicator =
            ((container.foregroundDecoration! as BoxDecoration).border!
                    as Border)
                .top
                .color;

        // ignore: avoid_print
        print(
          'NAV ${entry.key} -> pastille $fill (chroma '
          '${chromaOf(fill).toStringAsFixed(3)}), indicateur $indicator '
          '(${contrast(indicator, fill).toStringAsFixed(2)}:1)',
        );

        if (entry.key == 'sombre') {
          // En mode sombre, le fond sélectionné porte la couleur d'accent à 30%
          // d'opacité avec une bordure d'accent à 100%.
          expect(fill, tokens.accent.withValues(alpha: 0.30));
          expect(indicator, tokens.accentIndicator);
        } else {
          // En mode clair, la pastille de fond reste NEUTRE : la sélection ne redevient jamais
          // un aplat de couleur de marque.
          expect(purples.contains(fill), isFalse);
          expect(chromaOf(fill), lessThan(0.06));

          // L'indicateur, lui, porte l'accent, et reste visible sur la pastille.
          expect(indicator, tokens.accentRing);
          expect(chromaOf(indicator), greaterThan(0.06));
          expect(contrast(indicator, fill), greaterThanOrEqualTo(3.0));
        }
      });
    }

    testWidgets('item inactif : aucun indicateur', (tester) async {
      await selectedItem(tester, themes['sombre']!);
      final idle = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byTooltip('Cmd'),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(idle.foregroundDecoration, isNull);
      expect((idle.decoration! as BoxDecoration).color, Colors.transparent);
    });
  });
}
