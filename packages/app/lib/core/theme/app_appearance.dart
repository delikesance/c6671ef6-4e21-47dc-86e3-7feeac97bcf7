import 'dart:convert';

import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Bot Creator — Apparence de l'application (presets + personnalisation)
// ═══════════════════════════════════════════════════════════════════════════════
//
// Ce fichier décrit *ce que l'utilisateur choisit* : un thème prédéfini
// (« preset ») et/ou des couleurs personnalisées. `app_theme.dart` décrit
// *comment* ce choix est peint (ThemeData, jetons, accent d'action).
//
//   * [AppAppearancePreset] — catalogue des thèmes prédéfinis (graine M3,
//     variante de schéma, accent) ;
//   * [AppAppearanceConfig] — choix effectif, sérialisé en JSON dans
//     `SharedPreferences` (clé `app_appearance`).
//
// Le preset par défaut, [AppAppearancePreset.graphite], reproduit exactement le
// rendu de la refonte graphite : surfaces neutres, violet uniquement en ACCENT
// d'action (boutons, anneaux de focus, indicateurs de sélection active).
//
// ═══════════════════════════════════════════════════════════════════════════════

/// Un thème prédéfini d'apparence : graine M3, variante de schéma et accents.
///
/// Chaque preset porte DEUX variantes d'accent — [accentLight] pour le mode
/// clair, [accentDark] pour le mode sombre — et non une couleur unique peinte
/// telle quelle dans les deux modes : un accent clair (cyan, vert, ambre)
/// devient illisible sur des surfaces claires, et le violet de marque sombre ne
/// donne que 1.77:1 sur le graphite sombre du défaut. Règle de dérivation : la
/// variante SOMBRE est le ton ÉCLAIRCI de la teinte, la variante CLAIRE le ton
/// FONCÉ (façon M3). Tout preset garantit ainsi un ratio accent/surface
/// ≥ 4.5:1 dans les DEUX modes — verrouillé par `test/app_appearance_test.dart`
/// (groupe « Contrastes WCAG »).
///
/// Les libellés sont des **clés i18n** (`labelKey` / `descriptionKey`) : les
/// chaînes traduites seront ajoutées aux `.arb` par la vague « Settings →
/// Apparence », en même temps que la galerie de presets.
@immutable
class AppAppearancePreset {
  const AppAppearancePreset({
    required this.id,
    required this.labelKey,
    required this.descriptionKey,
    required this.seed,
    required this.accentLight,
    required this.accentDark,
    this.variant = DynamicSchemeVariant.tonalSpot,
    this.contrastLevel = 0.0,
  });

  /// Identifiant stable, persisté en JSON — ne jamais le renommer.
  final String id;

  /// Clé i18n du nom affiché dans les Settings.
  final String labelKey;

  /// Clé i18n de la description courte du preset.
  final String descriptionKey;

  /// Graine de `ColorScheme.fromSeed` : elle teinte les surfaces dérivées.
  final Color seed;

  /// Variante d'accent du mode CLAIR : ton FONCÉ de la teinte du preset,
  /// lisible sur les surfaces claires (≥ 4.5:1, verrouillé par test).
  final Color accentLight;

  /// Variante d'accent du mode SOMBRE : ton ÉCLAIRCI de la teinte du preset,
  /// lisible sur les surfaces sombres (≥ 4.5:1, verrouillé par test).
  final Color accentDark;

  /// Accent du preset pour [brightness] : [accentDark] en mode sombre,
  /// [accentLight] sinon.
  Color accentFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentDark : accentLight;

  /// Variante de schéma M3. `neutral` (défaut graphite) garde les surfaces
  /// désaturées ; `tonalSpot` (défaut M3) laisse la teinte de la graine colorer
  /// les surfaces du preset.
  final DynamicSchemeVariant variant;

  /// Niveau de contraste M3 (0 = normal, 1 = maximum), utilisé par le preset
  /// [highContrast].
  final double contrastLevel;

  // ─── Catalogue ────────────────────────────────────────────────────────────

  /// Défaut : rendu historique de la refonte graphite (surfaces neutres), avec
  /// le violet de marque en accent d'action. La graine et la variante CLAIRE
  /// doivent rester identiques aux constantes `AppTheme.neutralSeed` /
  /// `AppTheme.brandPrimary` (vérifié par `test/app_appearance_test.dart` et
  /// `test/theme_redesign_tokens_test.dart`) ; la variante sombre est le violet
  /// de marque éclairci, seul lisible sur la carte graphite.
  static const graphite = AppAppearancePreset(
    id: 'graphite',
    labelKey: 'appearance_preset_graphite',
    descriptionKey: 'appearance_preset_graphite_desc',
    seed: Color(0xFF33343B),
    variant: DynamicSchemeVariant.neutral,
    accentLight: Color(0xFF6A0FA2),
    accentDark: Color(0xFFAC79CB),
  );

  /// Charte violette Bot Creator : ici les *surfaces* sont teintées (c'est le
  /// rôle d'un preset de couleur) ; l'accent reprend le violet vif de la
  /// marque, en ton foncé en clair et en ton clair en sombre.
  static const violetBc = AppAppearancePreset(
    id: 'violet_bc',
    labelKey: 'appearance_preset_violet_bc',
    descriptionKey: 'appearance_preset_violet_bc_desc',
    seed: Color(0xFF6A0FA2),
    accentLight: Color(0xFF952EF5),
    accentDark: Color(0xFFAF59FF),
  );

  /// Blurple Discord.
  static const discord = AppAppearancePreset(
    id: 'discord',
    labelKey: 'appearance_preset_discord',
    descriptionKey: 'appearance_preset_discord_desc',
    seed: Color(0xFF5865F2),
    accentLight: Color(0xFF515DDF),
    accentDark: Color(0xFF6E79F4),
  );

  /// Océan (cyan).
  static const ocean = AppAppearancePreset(
    id: 'ocean',
    labelKey: 'appearance_preset_ocean',
    descriptionKey: 'appearance_preset_ocean_desc',
    seed: Color(0xFF0E7490),
    accentLight: Color(0xFF137685),
    accentDark: Color(0xFF22D3EE),
  );

  /// Forêt (vert).
  static const forest = AppAppearancePreset(
    id: 'forest',
    labelKey: 'appearance_preset_forest',
    descriptionKey: 'appearance_preset_forest_desc',
    seed: Color(0xFF166534),
    accentLight: Color(0xFF297A46),
    accentDark: Color(0xFF4ADE80),
  );

  /// Ambre (orange).
  static const amber = AppAppearancePreset(
    id: 'amber',
    labelKey: 'appearance_preset_amber',
    descriptionKey: 'appearance_preset_amber_desc',
    seed: Color(0xFFB45309),
    accentLight: Color(0xFF956007),
    accentDark: Color(0xFFF59E0B),
  );

  /// Rose (magenta).
  static const rose = AppAppearancePreset(
    id: 'rose',
    labelKey: 'appearance_preset_rose',
    descriptionKey: 'appearance_preset_rose_desc',
    seed: Color(0xFFBE185D),
    accentLight: Color(0xFFC9246D),
    accentDark: Color(0xFFE14E8F),
  );

  /// Contraste maximal : paliers `on*` renforcés par M3 (`contrastLevel = 1`),
  /// graine neutre et accent violet — le preset le plus lisible pour les
  /// utilisateurs qui en ont besoin. Les deux variantes d'accent sont
  /// volontairement TRÈS contrastées (≈ 10:1 en clair, ≈ 8:1 en sombre), pas
  /// la dérive minimale à 4.5:1 : c'est tout l'intérêt du preset.
  static const highContrast = AppAppearancePreset(
    id: 'high_contrast',
    labelKey: 'appearance_preset_high_contrast',
    descriptionKey: 'appearance_preset_high_contrast_desc',
    seed: Color(0xFF111111),
    variant: DynamicSchemeVariant.neutral,
    accentLight: Color(0xFF4C1D95),
    accentDark: Color(0xFFB19DF7),
    contrastLevel: 1.0,
  );

  /// Catalogue complet, dans l'ordre d'affichage de la future galerie.
  static const values = <AppAppearancePreset>[
    graphite,
    violetBc,
    discord,
    ocean,
    forest,
    amber,
    rose,
    highContrast,
  ];

  /// Preset correspondant à [id], ou [graphite] si l'identifiant est inconnu
  /// (config d'une version future ou corrompue : l'app reste utilisable).
  static AppAppearancePreset byId(String? id) =>
      values.firstWhere((preset) => preset.id == id, orElse: () => graphite);

  /// Vrai si [id] désigne un preset du catalogue.
  static bool exists(String id) => values.any((preset) => preset.id == id);
}

/// Configuration d'apparence complète de l'application.
///
/// Entrée des fabriques de thème (`AppTheme.darkTheme(appearance: config)`) et
/// unité de persistance : [encode] / [decode] produisent le JSON stocké dans
/// `SharedPreferences`.
@immutable
class AppAppearanceConfig {
  const AppAppearanceConfig({
    required this.mode,
    required this.presetId,
    required this.accentColor,
    required this.seedColor,
    this.textScale = 1.0,
  });

  /// Mode clair / sombre / système.
  final ThemeMode mode;

  /// Preset de référence (base mise en évidence dans la future galerie) ; les
  /// couleurs ci-dessous peuvent avoir été personnalisées après coup.
  final String presetId;

  /// Accent effectif des zones d'action : boutons, anneaux de focus, sélections
  /// actives. Quand un preset est actif, c'est sa variante CLAIRE
  /// ([AppAppearancePreset.accentLight]) — la référence STABLE de persistance,
  /// indépendante du mode ; la couleur réellement peinte dans le mode courant
  /// se lit via [accentFor]. Un accent personnalisé s'applique, lui, tel quel
  /// dans les deux modes.
  final Color accentColor;

  /// Graine effective des `ColorScheme` (teinte des surfaces).
  final Color seedColor;

  /// App adjustment applied on top of the device's accessibility text scale.
  // Objects retained by hot reload can predate this field. Keep their absent
  // adjustment equivalent to the default instead of failing during a build.
  final double? textScale;
  static const minTextScale = 0.75;
  static const maxTextScale = 1.25;

  static double normalizeTextScale(double? value) =>
      value != null && value.isFinite
      ? value.clamp(minTextScale, maxTextScale).toDouble()
      : 1.0;

  /// Valeurs d'usine : rendu historique (graphite, mode sombre, accent violet
  /// de marque). Elles doivent rester identiques à
  /// [AppAppearancePreset.graphite] (vérifié par
  /// `test/app_appearance_test.dart` : les deux sources ne peuvent pas se
  /// référencer en `const`).
  static const defaults = AppAppearanceConfig(
    mode: ThemeMode.dark,
    presetId: 'graphite',
    accentColor: Color(0xFF6A0FA2),
    seedColor: Color(0xFF33343B),
  );

  /// Preset de référence résolu (jamais `null`).
  AppAppearancePreset get preset => AppAppearancePreset.byId(presetId);

  /// Vrai tant que la graine est celle du défaut graphite : les surfaces du
  /// thème restent alors strictement neutres (aucune régression visuelle).
  bool get usesNeutralSurfaces =>
      seedColor == AppAppearancePreset.graphite.seed;

  /// Vrai si [accentColor] est encore une variante du preset de référence : la
  /// variante CLAIRE (référence écrite par `ThemeProvider.setPreset`) ou — pour
  /// les configs persistées avant l'arrivée des accents par mode — la variante
  /// SOMBRE. L'accent suit alors [accentFor] selon le mode ; sinon c'est une
  /// personnalisation, appliquée telle quelle dans les deux modes.
  bool get usesPresetAccent {
    final preset = this.preset;
    return accentColor == preset.accentLight ||
        accentColor == preset.accentDark;
  }

  /// Accent réellement peint dans [brightness] : la variante du preset quand il
  /// est actif ([usesPresetAccent]), l'accent personnalisé sinon.
  Color accentFor(Brightness brightness) =>
      usesPresetAccent ? preset.accentFor(brightness) : accentColor;

  AppAppearanceConfig copyWith({
    ThemeMode? mode,
    String? presetId,
    Color? accentColor,
    Color? seedColor,
    double? textScale,
  }) {
    return AppAppearanceConfig(
      mode: mode ?? this.mode,
      presetId: presetId ?? this.presetId,
      accentColor: accentColor ?? this.accentColor,
      seedColor: seedColor ?? this.seedColor,
      textScale: normalizeTextScale(textScale ?? this.textScale),
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'mode': switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    },
    'presetId': presetId,
    'accentColor': accentColor.toARGB32(),
    'seedColor': seedColor.toARGB32(),
    'textScale': normalizeTextScale(textScale),
  };

  /// Sérialise la config pour `SharedPreferences`.
  String encode() => jsonEncode(toJson());

  /// Config la plus proche possible de [json] : chaque champ absent, d'un type
  /// inattendu ou hors bornes retombe sur [defaults] — champ par champ, pour
  /// qu'une config partiellement corrompue conserve ce qui reste lisible.
  factory AppAppearanceConfig.fromJson(Map<String, Object?> json) {
    return AppAppearanceConfig(
      mode: _modeFrom(json['mode']) ?? defaults.mode,
      presetId: switch (json['presetId']) {
        final String id when AppAppearancePreset.exists(id) => id,
        _ => defaults.presetId,
      },
      accentColor: _colorFrom(json['accentColor']) ?? defaults.accentColor,
      seedColor: _colorFrom(json['seedColor']) ?? defaults.seedColor,
      textScale: switch (json['textScale']) {
        final num value => normalizeTextScale(value.toDouble()),
        _ => defaults.textScale,
      },
    );
  }

  /// Décode une config produite par [encode] ; toute entrée illisible (`null`,
  /// JSON invalide, JSON valide mais qui n'est pas un objet…) retombe sur
  /// [defaults].
  static AppAppearanceConfig decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return defaults;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return defaults;
    }
    if (decoded is! Map<String, Object?>) {
      return defaults;
    }
    return AppAppearanceConfig.fromJson(decoded);
  }

  static ThemeMode? _modeFrom(Object? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };

  static Color? _colorFrom(Object? value) {
    if (value is! int || value < 0 || value > 0xFFFFFFFF) {
      return null;
    }
    return Color(value);
  }

  @override
  bool operator ==(Object other) =>
      other is AppAppearanceConfig &&
      other.mode == mode &&
      other.presetId == presetId &&
      other.accentColor == accentColor &&
      other.seedColor == seedColor &&
      normalizeTextScale(other.textScale) == normalizeTextScale(textScale);

  @override
  int get hashCode => Object.hash(
    mode,
    presetId,
    accentColor,
    seedColor,
    normalizeTextScale(textScale),
  );

  @override
  String toString() =>
      'AppAppearanceConfig(mode: $mode, presetId: $presetId, '
      'accentColor: $accentColor, seedColor: $seedColor, textScale: $textScale)';
}
