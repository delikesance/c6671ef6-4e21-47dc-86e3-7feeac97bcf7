// Verrou des jetons NEUTRES de la refonte (valeurs exactes) et des contrastes
// WCAG du thème par défaut.
//
// Ces valeurs sont la signature visuelle du défaut graphite : si l'une bouge,
// c'est un changement produit assumé, pas un effet de bord. Les presets de
// couleur (qui, eux, ont le droit de teinter les surfaces) sont couverts par
// `test/app_appearance_test.dart`.
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ratio de contraste WCAG 2.1 — implémentation locale et indépendante, pour ne
/// pas valider la palette avec le code qui la fabrique.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Jetons neutres (défaut graphite)', () {
    test('rayons et breakpoints', () {
      expect(AppTheme.radiusCard, 24.0);
      expect(AppTheme.radiusMd, 12.0);
      expect(AppTheme.radiusPill, 999.0);
      expect(AppTheme.desktopBreakpoint, 720.0);
    });

    test('couleurs neutralisées de la refonte', () {
      expect(AppTheme.neutralSeed, const Color(0xFF33343B));
      expect(AppTheme.scaffoldDark, const Color(0xFF0E0F13));
      expect(AppTheme.homeCard, const Color(0xFF16181E));
      expect(AppTheme.homeCardBorder, const Color(0xFF222631));
      expect(AppTheme.homeNavBar, const Color(0xFF12141A));
      expect(AppTheme.homeNavSelected, const Color(0xFF1E212A));
      expect(AppTheme.homeCreateFill, AppTheme.homeNavSelected);
      expect(AppTheme.homeCreateBorder, const Color(0xFFAAAAAA));
      expect(AppTheme.homeClusterBg, const Color(0xFF12141A));
      expect(AppTheme.homeClusterBorder, const Color(0xFF272B36));
      expect(AppTheme.homeContainerLowest, const Color(0xFF0B0C10));
      expect(AppTheme.homeGhostBorder, const Color(0xFF3A3F4F));
      expect(AppTheme.homeMuted, const Color(0xFF9AA0AF));
      expect(AppTheme.metaText, AppTheme.homeMuted);
      expect(AppTheme.dataAccent, const Color(0xFFDCF0FF));
      expect(AppTheme.online, const Color(0xFF10B981));
      expect(AppTheme.danger, const Color(0xFFFF4D4D));
    });
  });

  group('HomeTokens (ThemeExtension) — défaut graphite', () {
    final tokens = AppTheme.darkTheme().extension<HomeTokens>()!;

    test('les jetons valent exactement les constantes historiques', () {
      expect(tokens.card, AppTheme.homeCard);
      expect(tokens.cardBorder, AppTheme.homeCardBorder);
      expect(tokens.navBar, AppTheme.homeNavBar);
      expect(tokens.navSelected, AppTheme.homeNavSelected);
      expect(tokens.createFill, AppTheme.homeCreateFill);
      expect(tokens.createBorder, AppTheme.homeCreateBorder);
      expect(tokens.clusterBg, AppTheme.homeClusterBg);
      expect(tokens.clusterBorder, AppTheme.homeClusterBorder);
      expect(tokens.containerLowest, AppTheme.homeContainerLowest);
      expect(tokens.ghostBorder, AppTheme.homeGhostBorder);
      expect(tokens.muted, AppTheme.homeMuted);
      expect(tokens.metaText, AppTheme.homeMuted);
      expect(tokens.dataAccent, AppTheme.dataAccent);
      expect(tokens.online, AppTheme.online);
      expect(tokens.danger, AppTheme.danger);
    });

    test('l\'accent d\'action est la variante sombre du preset graphite', () {
      // Depuis l'arrivée des accents par mode, le thème sombre par défaut peint
      // `graphite.accentDark` (#AC79CB) : le violet de marque brut (#6A0FA2)
      // ne donnait que 1.77:1 sur la carte graphite — la variante éclaircie
      // est désormais l'accent lui-même, directement lisible.
      expect(tokens.accent, AppAppearancePreset.graphite.accentDark);
      expect(
        _contrast(tokens.accent, AppTheme.homeCard),
        greaterThanOrEqualTo(4.5),
      );
      // `accentRing` reste une variante dérivée : elle doit couvrir en plus la
      // pastille de sélection (`secondaryContainer`), sur laquelle l'accent
      // seul peut encore tomber sous 3:1.
      expect(
        _contrast(tokens.accentRing, AppTheme.homeCard),
        greaterThanOrEqualTo(3.0),
      );
    });

    test('copyWith et lerp restent cohérents (contrat ThemeExtension)', () {
      final copy = tokens.copyWith(muted: const Color(0xFF123456));
      expect(copy.muted, const Color(0xFF123456));
      expect(copy.card, tokens.card);

      final half = tokens.lerp(tokens.copyWith(card: Colors.white), 0.5);
      expect(half.card, Color.lerp(tokens.card, Colors.white, 0.5));
      expect(tokens.lerp(null, 0.5).card, tokens.card);
    });
  });

  group('AppTheme.darkTheme() sans argument = rendu historique', () {
    final theme = AppTheme.darkTheme();

    test('fond, canvas et brightness', () {
      expect(theme.scaffoldBackgroundColor, AppTheme.scaffoldDark);
      expect(theme.canvasColor, AppTheme.scaffoldDark);
      expect(theme.brightness, Brightness.dark);
    });

    test('rôles M3 : surfaces et textes neutres', () {
      final scheme = theme.colorScheme;
      expect(scheme.surface, AppTheme.homeCard);
      expect(scheme.surfaceContainerLowest, AppTheme.homeContainerLowest);
      expect(scheme.surfaceContainerLow, AppTheme.homeClusterBg);
      expect(scheme.surfaceContainer, AppTheme.homeCard);
      expect(scheme.surfaceContainerHigh, AppTheme.homeCard);
      expect(scheme.surfaceContainerHighest, AppTheme.homeNavSelected);
      expect(scheme.onSurface, Colors.white);
      expect(scheme.onSurfaceVariant, AppTheme.homeMuted);
      expect(scheme.outline, AppTheme.homeGhostBorder);
      expect(scheme.outlineVariant, AppTheme.homeCardBorder);
      expect(scheme.error, AppTheme.danger);
      expect(scheme.onError, AppTheme.scaffoldDark);
    });

    test('AppBar neutre, posée sur le fond', () {
      expect(theme.appBarTheme.backgroundColor, AppTheme.scaffoldDark);
      expect(theme.appBarTheme.foregroundColor, theme.colorScheme.onSurface);
      expect(theme.appBarTheme.elevation, 0);
      expect(theme.appBarTheme.surfaceTintColor, Colors.transparent);
      expect(theme.appBarTheme.centerTitle, isFalse);
    });

    test(
      'cartes : rayon radiusCard, bordure outlineVariant, élévation nulle',
      () {
        final card = theme.cardTheme;
        expect(card.elevation, 0.0);
        expect(card.color, AppTheme.homeCard);
        expect(card.margin, EdgeInsets.zero);
        expect(card.surfaceTintColor, Colors.transparent);
        final shape = card.shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(AppTheme.radiusCard));
        expect(shape.side.color, AppTheme.homeCardBorder);
      },
    );
  });

  group('Contrastes WCAG du thème par défaut', () {
    test('paires texte ≥ 4.5:1 et accent ≥ 3:1, dans les deux modes', () {
      for (final theme in <ThemeData>[
        AppTheme.lightTheme(),
        AppTheme.darkTheme(),
      ]) {
        final scheme = theme.colorScheme;
        final tokens = theme.extension<HomeTokens>()!;
        final label = theme.brightness == Brightness.light ? 'clair' : 'sombre';

        void check(
          String name,
          Color foreground,
          Color background,
          double min,
        ) {
          final ratio = _contrast(foreground, background);
          // ignore: avoid_print
          print(
            'WCAG $label ${name.padRight(22)} ${ratio.toStringAsFixed(2)}:1 '
            '(min $min)',
          );
          expect(ratio, greaterThanOrEqualTo(min), reason: '$label / $name');
        }

        check('onPrimary/primary', scheme.onPrimary, scheme.primary, 4.5);
        check(
          'onSecondary/secondary',
          scheme.onSecondary,
          scheme.secondary,
          4.5,
        );
        check('onError/error', scheme.onError, scheme.error, 4.5);
        check('primary/surface', scheme.primary, scheme.surface, 4.5);
        check('onAccent/accent', tokens.onAccent, tokens.accent, 4.5);
        check('accentRing/surface', tokens.accentRing, scheme.surface, 3.0);
      }
    });
  });
}
