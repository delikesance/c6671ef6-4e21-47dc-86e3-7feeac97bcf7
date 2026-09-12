// Tests du socle « Apparence » : configuration (presets + personnalisation),
// sérialisation JSON tolérante, migration de l'ancienne clé `theme_mode` et
// contrastes WCAG de TOUS les presets dans les deux modes.
//
// Le ratio de contraste est recalculé ici (implémentation locale) : valider une
// palette avec la fonction qui la fabrique ne prouverait rien.
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ratio de contraste WCAG 2.1 entre deux couleurs (1:1 à 21:1).
double _ratio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

/// « Quantité de couleur » d'une teinte : écart entre le canal le plus fort et
/// le plus faible. Un accent qui perdrait sa teinte (blanc/noir pur de secours)
/// tomberait à 0 — cette mesure le détecte, contrairement à la saturation HSL.
double _chroma(Color color) {
  final channels = <double>[color.r, color.g, color.b];
  final maxChannel = channels.reduce((a, b) => a > b ? a : b);
  final minChannel = channels.reduce((a, b) => a < b ? a : b);
  return maxChannel - minChannel;
}

/// Fond réel d'un remplissage translucide (les champs clairs sont posés en
/// `withValues(alpha: 0.5)` sur la surface du thème).
Color _opaque(Color foreground, Color background) =>
    Color.alphaBlend(foreground, background);

/// Les deux thèmes d'un preset, pour balayer tous les cas.
///
/// La config de chaque mode porte la référence persistée de CE mode
/// (`accentColor` = variante claire ou sombre) : c'est la situation réelle
/// écrite par `ThemeProvider.setPreset` / relue d'une config sauvegardée.
Map<String, ThemeData> _themesFor(AppAppearancePreset preset) {
  AppAppearanceConfig configFor(Brightness brightness) =>
      AppAppearanceConfig.defaults.copyWith(
        presetId: preset.id,
        seedColor: preset.seed,
        accentColor: preset.accentFor(brightness),
      );
  return <String, ThemeData>{
    'clair': AppTheme.lightTheme(appearance: configFor(Brightness.light)),
    'sombre': AppTheme.darkTheme(appearance: configFor(Brightness.dark)),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppAppearanceConfig — JSON', () {
    test('aller-retour : encode/decode conserve tous les champs', () {
      const config = AppAppearanceConfig(
        mode: ThemeMode.light,
        presetId: 'ocean',
        accentColor: Color(0xFF22D3EE),
        seedColor: Color(0xFF0E7490),
      );
      final decoded = AppAppearanceConfig.decode(config.encode());
      expect(decoded, config);
      expect(decoded.mode, ThemeMode.light);
      expect(decoded.presetId, 'ocean');
      expect(decoded.accentColor, const Color(0xFF22D3EE));
      expect(decoded.seedColor, const Color(0xFF0E7490));
      expect(decoded.hashCode, config.hashCode);
    });

    test('toJson : couleur en entier ARGB, mode en texte', () {
      final json = AppAppearanceConfig.defaults.toJson();
      expect(json['mode'], 'dark');
      expect(json['presetId'], 'graphite');
      expect(json['accentColor'], 0xFF6A0FA2);
      expect(json['seedColor'], 0xFF33343B);
    });

    test('mode système conservé', () {
      final config = AppAppearanceConfig.defaults.copyWith(
        mode: ThemeMode.system,
      );
      expect(
        AppAppearanceConfig.decode(config.encode()).mode,
        ThemeMode.system,
      );
    });

    test('config corrompue → valeurs d\'usine', () {
      for (final raw in <String?>[
        null,
        '',
        'pas du json',
        '{"mode":', // JSON tronqué
        '[1, 2, 3]', // JSON valide mais pas un objet
        '"graphite"', // JSON valide mais pas un objet
        '12', // idem
        'null', // idem
      ]) {
        expect(
          AppAppearanceConfig.decode(raw),
          AppAppearanceConfig.defaults,
          reason: 'entrée: $raw',
        );
      }
    });

    test('champs invalides → retombée champ par champ', () {
      final decoded = AppAppearanceConfig.decode(
        '{"mode":"banana","presetId":"pas_un_preset",'
        '"accentColor":"violet","seedColor":-1}',
      );
      expect(decoded.mode, AppAppearanceConfig.defaults.mode);
      expect(decoded.presetId, AppAppearanceConfig.defaults.presetId);
      expect(decoded.accentColor, AppAppearanceConfig.defaults.accentColor);
      expect(decoded.seedColor, AppAppearanceConfig.defaults.seedColor);
    });

    test('une config partiellement lisible conserve ce qui est valide', () {
      final decoded = AppAppearanceConfig.decode(
        '{"mode":"light","presetId":"discord","accentColor":4283983346,'
        '"seedColor":null}',
      );
      expect(decoded.mode, ThemeMode.light);
      expect(decoded.presetId, 'discord');
      expect(decoded.accentColor, const Color(0xFF5865F2));
      expect(decoded.seedColor, AppAppearanceConfig.defaults.seedColor);
    });

    test('copyWith ne touche que les champs fournis', () {
      final config = AppAppearanceConfig.defaults.copyWith(
        accentColor: const Color(0xFF00FF00),
      );
      expect(config.accentColor, const Color(0xFF00FF00));
      expect(config.seedColor, AppAppearanceConfig.defaults.seedColor);
      expect(config.presetId, AppAppearanceConfig.defaults.presetId);
      expect(config.mode, AppAppearanceConfig.defaults.mode);
    });
  });

  group('Presets', () {
    test('catalogue complet et cohérent', () {
      expect(AppAppearancePreset.values, hasLength(8));
      expect(
        AppAppearancePreset.values.map((preset) => preset.id).toSet(),
        hasLength(AppAppearancePreset.values.length),
        reason: 'identifiants uniques (ils sont persistés en JSON)',
      );
      for (final preset in AppAppearancePreset.values) {
        expect(preset.id, isNotEmpty);
        expect(preset.labelKey, isNotEmpty);
        expect(preset.descriptionKey, isNotEmpty);
        expect(preset.labelKey, isNot(preset.descriptionKey));
        expect(
          preset.accentLight.a,
          1.0,
          reason: '${preset.id} : accent clair opaque',
        );
        expect(
          preset.accentDark.a,
          1.0,
          reason: '${preset.id} : accent sombre opaque',
        );
        expect(preset.seed.a, 1.0, reason: '${preset.id} : graine opaque');
        expect(preset.contrastLevel, inInclusiveRange(0.0, 1.0));
        expect(AppAppearancePreset.byId(preset.id), same(preset));
      }
    });

    test('ids attendus (contrat de persistance)', () {
      expect(
        AppAppearancePreset.values.map((preset) => preset.id).toList(),
        <String>[
          'graphite',
          'violet_bc',
          'discord',
          'ocean',
          'forest',
          'amber',
          'rose',
          'high_contrast',
        ],
      );
    });

    test('identifiant inconnu → graphite (jamais de crash)', () {
      expect(AppAppearancePreset.byId('nope'), AppAppearancePreset.graphite);
      expect(AppAppearancePreset.byId(null), AppAppearancePreset.graphite);
      expect(AppAppearancePreset.exists('graphite'), isTrue);
      expect(AppAppearancePreset.exists('nope'), isFalse);
      expect(AppAppearancePreset.byId('graphite').id, 'graphite');
    });

    test('le défaut et les constantes de la charte restent alignés', () {
      // Ces valeurs ne peuvent pas se référencer en `const` (deux fichiers) :
      // l'invariant est donc verrouillé ici.
      expect(AppAppearanceConfig.defaults.presetId, 'graphite');
      expect(
        AppAppearancePreset.graphite.seed,
        AppTheme.neutralSeed,
        reason: 'le défaut graphite doit garder la graine neutre historique',
      );
      expect(
        AppAppearancePreset.graphite.accentLight,
        AppTheme.brandPrimary,
        reason: 'la variante claire par défaut est le violet de marque',
      );
      // La variante sombre est le violet de marque éclairci : lue sur la carte
      // graphite, elle doit rester ≥ 4.5:1 (ratio local, même seuil que la
      // carte « Apparence »).
      expect(
        _ratio(AppAppearancePreset.graphite.accentDark, AppTheme.homeCard),
        greaterThanOrEqualTo(4.5),
        reason: 'le violet éclairci doit être lisible sur la carte graphite',
      );
      expect(
        AppAppearancePreset.graphite.variant,
        DynamicSchemeVariant.neutral,
      );
      expect(AppAppearanceConfig.defaults.mode, ThemeMode.dark);
      expect(AppAppearanceConfig.defaults.seedColor, AppTheme.neutralSeed);
      expect(AppAppearanceConfig.defaults.accentColor, AppTheme.brandPrimary);
      expect(
        AppAppearanceConfig.defaults.usesNeutralSurfaces,
        isTrue,
        reason: 'le défaut garde des surfaces strictement neutres',
      );
      for (final preset in AppAppearancePreset.values) {
        if (preset.id == 'graphite') {
          continue;
        }
        expect(
          preset.seed == AppTheme.neutralSeed,
          isFalse,
          reason: '${preset.id} doit teinter les surfaces (graine propre)',
        );
      }
    });
  });

  group('Accent par mode (clair / sombre)', () {
    test('un preset actif peint la variante de son mode', () {
      for (final preset in AppAppearancePreset.values) {
        final config = AppAppearanceConfig.defaults.copyWith(
          presetId: preset.id,
          seedColor: preset.seed,
          accentColor: preset.accentLight,
        );
        expect(config.usesPresetAccent, isTrue, reason: preset.id);
        expect(
          config.accentFor(Brightness.light),
          preset.accentLight,
          reason: '${preset.id} / clair',
        );
        expect(
          config.accentFor(Brightness.dark),
          preset.accentDark,
          reason: '${preset.id} / sombre',
        );
      }
    });

    test('un accent personnalisé s\'applique tel quel dans les deux modes', () {
      const custom = Color(0xFF00FF00);
      final config = AppAppearanceConfig.defaults.copyWith(accentColor: custom);
      expect(config.usesPresetAccent, isFalse);
      expect(config.accentFor(Brightness.light), custom);
      expect(config.accentFor(Brightness.dark), custom);
    });

    test('l\'accent d\'un AUTRE preset est une personnalisation', () {
      final config = AppAppearanceConfig.defaults.copyWith(
        presetId: 'graphite',
        accentColor: AppAppearancePreset.ocean.accentDark,
      );
      expect(
        config.usesPresetAccent,
        isFalse,
        reason: 'seules les variantes du preset de référence comptent',
      );
      expect(
        config.accentFor(Brightness.dark),
        AppAppearancePreset.ocean.accentDark,
      );
    });

    test('rétrocompatibilité : une config persistée sur la variante sombre '
        'reste un preset', () {
      // Les configs écrites avant l'arrivée des accents par mode portaient la
      // couleur unique de l'ancien catalogue : ici la variante sombre du
      // défaut. Elle doit être reconnue comme preset (et non comme une
      // personnalisation), et l'accent peint suivre le mode courant.
      final legacyJson = AppAppearanceConfig.defaults
          .copyWith(
            presetId: 'graphite',
            accentColor: AppAppearancePreset.graphite.accentDark,
          )
          .encode();
      final legacy = AppAppearanceConfig.decode(legacyJson);

      expect(legacy.usesPresetAccent, isTrue);
      expect(
        legacy.accentFor(Brightness.light),
        AppAppearancePreset.graphite.accentLight,
      );
      expect(
        legacy.accentFor(Brightness.dark),
        AppAppearancePreset.graphite.accentDark,
      );
      expect(
        AppTheme.lightTheme(appearance: legacy).extension<HomeTokens>()!.accent,
        AppAppearancePreset.graphite.accentLight,
      );
      expect(
        AppTheme.darkTheme(appearance: legacy).extension<HomeTokens>()!.accent,
        AppAppearancePreset.graphite.accentDark,
      );
    });
  });

  group('AppTheme paramétrique', () {
    test('sans argument = configuration par défaut explicite', () {
      final implicitDark = AppTheme.darkTheme();
      final explicitDark = AppTheme.darkTheme(
        appearance: AppAppearanceConfig.defaults,
      );
      final implicitLight = AppTheme.lightTheme();
      final explicitLight = AppTheme.lightTheme(
        appearance: AppAppearanceConfig.defaults,
      );

      for (final pair in <List<ThemeData>>[
        <ThemeData>[implicitDark, explicitDark],
        <ThemeData>[implicitLight, explicitLight],
      ]) {
        final a = pair[0];
        final b = pair[1];
        expect(a.colorScheme.primary, b.colorScheme.primary);
        expect(a.colorScheme.surface, b.colorScheme.surface);
        expect(
          a.colorScheme.secondaryContainer,
          b.colorScheme.secondaryContainer,
        );
        expect(a.scaffoldBackgroundColor, b.scaffoldBackgroundColor);
        expect(
          a.extension<HomeTokens>()!.accentRing,
          b.extension<HomeTokens>()!.accentRing,
        );
        expect(
          a.extension<HomeTokens>()!.accentIndicator,
          b.extension<HomeTokens>()!.accentIndicator,
        );
        expect(
          a.filledButtonTheme.style!.backgroundColor!.resolve(
            const <WidgetState>{},
          ),
          b.filledButtonTheme.style!.backgroundColor!.resolve(
            const <WidgetState>{},
          ),
        );
      }
    });

    test('le défaut graphite garde les jetons home* historiques', () {
      final tokens = AppTheme.darkTheme().extension<HomeTokens>()!;
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
      // L'accent n'est plus le violet de marque brut en mode sombre mais sa
      // variante éclaircie (`graphite.accentDark`), seule lisible sur graphite.
      expect(
        tokens.accent,
        AppAppearancePreset.graphite.accentFor(Brightness.dark),
      );
    });

    test('un preset teinté change surfaces et accent, pas par accident', () {
      final dark = AppTheme.darkTheme();
      final violet = AppTheme.darkTheme(
        appearance: AppAppearanceConfig.defaults.copyWith(
          presetId: 'violet_bc',
          seedColor: AppAppearancePreset.violetBc.seed,
          accentColor: AppAppearancePreset.violetBc.accentLight,
        ),
      );
      expect(
        violet.colorScheme.surface,
        isNot(dark.colorScheme.surface),
        reason: 'un preset de couleur doit teinter les surfaces sombres',
      );
      expect(
        violet.extension<HomeTokens>()!.accent,
        AppAppearancePreset.violetBc.accentFor(Brightness.dark),
      );
      expect(
        violet.extension<HomeTokens>()!.card,
        isNot(AppTheme.homeCard),
        reason: 'les jetons suivent la palette du preset',
      );
      expect(
        AppTheme.darkTheme().colorScheme.surface,
        AppTheme.homeCard,
        reason: 'aucune fuite : le défaut reste neutre',
      );
    });

    testWidgets('HomeTokens.of() dérive de la palette sans extension', (
      tester,
    ) async {
      late HomeTokens tokens;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              tokens = HomeTokens.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tokens.accent, AppTheme.brandPrimary);
      expect(tokens.accentRing, isNotNull);
    });
  });

  group('Contrastes WCAG (tous les presets, deux modes)', () {
    test('paires M3 et accent ≥ 4.5:1, anneaux ≥ 3:1', () {
      for (final preset in AppAppearancePreset.values) {
        for (final entry in _themesFor(preset).entries) {
          final mode = entry.key;
          final theme = entry.value;
          final scheme = theme.colorScheme;
          final tokens = theme.extension<HomeTokens>()!;

          void checkText(String name, Color foreground, Color background) {
            final ratio = _ratio(foreground, background);
            // ignore: avoid_print
            print(
              'CONTRASTE ${preset.id.padRight(14)} $mode  '
              '${name.padRight(26)} ${ratio.toStringAsFixed(2)}:1',
            );
            expect(
              ratio,
              greaterThanOrEqualTo(4.5),
              reason: '${preset.id} / $mode : $name (texte)',
            );
          }

          void checkUi(String name, Color a, Color b) {
            final ratio = _ratio(a, b);
            // ignore: avoid_print
            print(
              'CONTRASTE ${preset.id.padRight(14)} $mode  '
              '${name.padRight(26)} ${ratio.toStringAsFixed(2)}:1',
            );
            expect(
              ratio,
              greaterThanOrEqualTo(3.0),
              reason: '${preset.id} / $mode : $name (élément d\'interface)',
            );
          }

          checkText('onPrimary/primary', scheme.onPrimary, scheme.primary);
          checkText(
            'onSecondary/secondary',
            scheme.onSecondary,
            scheme.secondary,
          );
          checkText('onError/error', scheme.onError, scheme.error);
          checkText('onAccent/accent', tokens.onAccent, tokens.accent);
          // C'est exactement le ratio affiché par la carte « Apparence » :
          // aucun preset ne doit y déclencher l'alerte de contraste.
          checkText('accent/surface', tokens.accent, scheme.surface);

          checkUi('accentRing/surface', tokens.accentRing, scheme.surface);
          checkUi(
            'accentRing/surfaceContainerHighest',
            tokens.accentRing,
            scheme.surfaceContainerHighest,
          );
          // Indicateur d'état actif : rôle DÉDIÉ `accentIndicator`, dont le
          // fond réel est la pastille de sélection. Sans ce rôle, il faudrait
          // `accentRing` ≥ 3:1 sur la pastille aussi — impossible pour
          // `high_contrast` en clair (pastille très sombre) comme en sombre
          // (pastille très claire) : les contraintes sont contradictoires.
          checkUi(
            'accentIndicator/secondaryContainer',
            tokens.accentIndicator,
            scheme.secondaryContainer,
          );
          checkUi(
            'indicateur de nav/pastille',
            tokens.accentIndicator,
            scheme.secondaryContainer,
          );
          // L'accent ne se réfugie pas dans le gris : les deux rôles gardent
          // une teinte colorée (le but produit est un accent violet, pas un
          // blanc/noir pur de secours).
          expect(
            _chroma(tokens.accentRing),
            greaterThan(0.06),
            reason: '${preset.id} / $mode : accentRing délavé',
          );
          expect(
            _chroma(tokens.accentIndicator),
            greaterThan(0.06),
            reason: '${preset.id} / $mode : accentIndicator délavé',
          );

          // Anneau de focus : la bordure du champ est posée sur le remplissage
          // réel (translucide en clair), composite sur le fond du thème.
          final focusRing =
              (theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder)
                  .borderSide
                  .color;
          final rawFill = theme.inputDecorationTheme.fillColor!;
          final fieldFill = _opaque(rawFill, theme.scaffoldBackgroundColor);
          checkUi('anneau de focus/champ', focusRing, fieldFill);
        }
      }
    });

    test('le violet par défaut reste visible sur les surfaces graphite', () {
      final tokens = AppTheme.darkTheme().extension<HomeTokens>()!;
      final accentRatio = _ratio(tokens.accent, AppTheme.homeCard);
      final ringRatio = _ratio(tokens.accentRing, AppTheme.homeCard);
      // ignore: avoid_print
      print(
        'CONTRASTE graphite (défaut) accent/homeCard '
        '${accentRatio.toStringAsFixed(2)}:1  accentRing/homeCard '
        '${ringRatio.toStringAsFixed(2)}:1',
      );
      expect(
        accentRatio,
        greaterThanOrEqualTo(4.5),
        reason: 'l\'accent sombre est directement lisible sur graphite',
      );
      expect(
        ringRatio,
        greaterThanOrEqualTo(3.0),
        reason: 'l\'anneau de focus doit être visible sur la carte graphite',
      );
      expect(
        tokens.accentRing,
        isNot(tokens.accent),
        reason:
            'l\'anneau couvre en plus la pastille de sélection '
            '(secondaryContainer) : il reste une variante dérivée',
      );
    });
  });

  group('Navigation — indicateur d\'accent sur la pastille', () {
    // Le widget doit consommer `accentIndicator` : c'est le seul rôle dont le
    // 3:1 est garanti sur la pastille pour les presets extrêmes, et le bug
    // d'origine (2.34:1) venait précisément de ce chemin.
    testWidgets('l\'indicateur peint est `accentIndicator`, lisible sur '
        'la pastille (preset high_contrast inclus)', (tester) async {
      for (final preset in <AppAppearancePreset>[
        AppAppearancePreset.highContrast,
        AppAppearancePreset.graphite,
      ]) {
        for (final entry in _themesFor(preset).entries) {
          final theme = entry.value;
          final tokens = theme.extension<HomeTokens>()!;
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
                  ],
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 250));

          final container = tester.widget<AnimatedContainer>(
            find.descendant(
              of: find.byTooltip('Accueil'),
              matching: find.byType(AnimatedContainer),
            ),
          );
          final indicator =
              ((container.foregroundDecoration! as BoxDecoration).border!
                      as Border)
                  .top
                  .color;
          final pill = (container.decoration! as BoxDecoration).color!;

          // ignore: avoid_print
          print(
            'NAV-INDICATEUR ${preset.id.padRight(14)} ${entry.key.padRight(6)} '
            '${_ratio(indicator, pill).toStringAsFixed(2)}:1',
          );
          expect(
            indicator,
            tokens.accentIndicator,
            reason: '${preset.id} / ${entry.key} : rôle d\'indicateur ignoré',
          );
          expect(
            _ratio(indicator, pill),
            greaterThanOrEqualTo(3.0),
            reason:
                '${preset.id} / ${entry.key} : indicateur illisible sur '
                'la pastille',
          );
        }
      }
    });
  });

  group('ThemeProvider — persistance et migration', () {
    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('démarrage vierge : valeurs d\'usine', () async {
      final provider = ThemeProvider();
      await pumpEventQueue();
      expect(provider.appearance, AppAppearanceConfig.defaults);
      expect(provider.themeMode, ThemeMode.dark);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_appearance'), isNull);
    });

    test(
      'migration : `theme_mode` initialise le mode puis disparaît',
      () async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'theme_mode': 'light',
        });
        final provider = ThemeProvider();
        await pumpEventQueue();

        expect(provider.themeMode, ThemeMode.light);
        expect(provider.appearance.presetId, 'graphite');
        expect(provider.appearance.seedColor, AppTheme.neutralSeed);

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('theme_mode'), isFalse);
        final saved = AppAppearanceConfig.decode(
          prefs.getString('app_appearance'),
        );
        expect(saved.mode, ThemeMode.light);
        expect(saved, provider.appearance);
      },
    );

    test('migration : mode sombre et valeur inconnue → sombre', () async {
      for (final legacy in <String>['dark', 'system', 'n_importe_quoi']) {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'theme_mode': legacy,
        });
        final provider = ThemeProvider();
        await pumpEventQueue();
        expect(provider.themeMode, ThemeMode.dark, reason: 'legacy: $legacy');
      }
    });

    test('la config complète prime sur l\'ancienne clé', () async {
      final stored = AppAppearanceConfig.defaults.copyWith(
        mode: ThemeMode.light,
        presetId: 'forest',
        seedColor: AppAppearancePreset.forest.seed,
        accentColor: AppAppearancePreset.forest.accentLight,
      );
      SharedPreferences.setMockInitialValues(<String, Object>{
        'theme_mode': 'dark',
        'app_appearance': stored.encode(),
      });
      final provider = ThemeProvider();
      await pumpEventQueue();

      expect(provider.appearance, stored);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('theme_mode'), isFalse);
    });

    test('setMode / setPreset / setAccent / setSeed persistent', () async {
      final provider = ThemeProvider();
      await pumpEventQueue();

      await provider.setPreset(AppAppearancePreset.discord);
      expect(provider.appearance.presetId, 'discord');
      expect(provider.appearance.seedColor, AppAppearancePreset.discord.seed);
      expect(
        provider.appearance.accentColor,
        AppAppearancePreset.discord.accentLight,
      );

      await provider.setMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);

      await provider.setAccent(const Color(0xFF00FF00));
      expect(provider.appearance.accentColor, const Color(0xFF00FF00));
      expect(
        provider.appearance.seedColor,
        AppAppearancePreset.discord.seed,
        reason: 'personnaliser l\'accent ne change pas les surfaces',
      );

      await provider.setSeed(const Color(0xFF123456));
      expect(provider.appearance.seedColor, const Color(0xFF123456));
      expect(provider.appearance.usesNeutralSurfaces, isFalse);

      final prefs = await SharedPreferences.getInstance();
      final saved = AppAppearanceConfig.decode(
        prefs.getString('app_appearance'),
      );
      expect(saved, provider.appearance);
      expect(saved.mode, ThemeMode.light);
      expect(saved.accentColor, const Color(0xFF00FF00));
    });

    test('toggleTheme bascule et persiste', () async {
      final provider = ThemeProvider();
      await pumpEventQueue();

      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.light);
      await provider.toggleTheme();
      expect(provider.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(
        AppAppearanceConfig.decode(prefs.getString('app_appearance')).mode,
        ThemeMode.dark,
      );
    });

    test('resetToDefaults (et son alias) revient à l\'usine', () async {
      final provider = ThemeProvider();
      await pumpEventQueue();
      await provider.setPreset(AppAppearancePreset.rose);
      await provider.setMode(ThemeMode.light);

      await provider.resetToDefaults();
      expect(provider.appearance, AppAppearanceConfig.defaults);
      expect(provider.themeMode, ThemeMode.dark);

      // L'ancien nom reste fonctionnel (utilisé par `settings_page.dart`).
      await provider.setPreset(AppAppearancePreset.amber);
      await provider.resetToDefault();
      expect(provider.appearance, AppAppearanceConfig.defaults);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_appearance'), isNull);
      expect(prefs.containsKey('theme_mode'), isFalse);
    });
  });
}
