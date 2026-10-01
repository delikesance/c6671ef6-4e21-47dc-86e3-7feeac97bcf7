part of 'appearance_settings_section.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Aperçus et sélecteurs de couleurs de la carte « Apparence »
// ═══════════════════════════════════════════════════════════════════════════════
//
// Galerie des huit presets (aperçu réel graine + accent + surface, coche sur le
// preset actif), pastilles cliquables « couleur principale » / « accent » et
// mappage `id de preset → clé i18n` (les `.arb` n'ont pas de lookup dynamique).
//
// ═══════════════════════════════════════════════════════════════════════════════

/// Galerie des huit presets : chaque carte montre les couleurs réelles du
/// thème (graine, accent, surface) et une coche sur le preset actif.
class _PresetGallery extends StatelessWidget {
  const _PresetGallery({required this.provider, required this.appearance});

  final ThemeProvider provider;
  final AppAppearanceConfig appearance;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    // Deux colonnes dès que la largeur le permet ; jamais de grille à hauteur
    // fixe (les libellés allemands/japonais sont plus longs).
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 2 : 1;
        final tileWidth = (constraints.maxWidth - (columns - 1) * 8) / columns;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final preset in AppAppearancePreset.values)
              SizedBox(
                width: tileWidth,
                child: _PresetTile(
                  key: AppearanceSettingsSection.presetKey(preset),
                  preset: preset,
                  surface: _previewSurface(preset, brightness),
                  selected: preset.id == appearance.presetId,
                  onTap: () => provider.setPreset(preset),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Aperçu cliquable d'un preset.
class _PresetTile extends StatelessWidget {
  const _PresetTile({
    super.key,
    required this.preset,
    required this.surface,
    required this.selected,
    required this.onTap,
  });

  final AppAppearancePreset preset;
  final Color surface;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final indicator = HomeTokens.of(context).accentIndicator;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected ? indicator : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                _Swatch(color: preset.seed),
                const SizedBox(width: 6),
                _Swatch(color: preset.accentFor(theme.brightness)),
                const SizedBox(width: 6),
                _Swatch(color: surface, square: true),
                const Spacer(),
                if (selected)
                  AppIcon.fromMaterial(
                    Icons.check_circle,
                    size: 18,
                    color: indicator,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _presetLabel(context, preset),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              _presetDescription(context, preset),
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pastille d'aperçu d'une couleur du preset.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, this.square = false});

  final Color color;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(4) : null,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

/// Pastille cliquable « couleur principale » / « accent ».
class _ColorPickerTile extends StatelessWidget {
  const _ColorPickerTile({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: scheme.outlineVariant),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _hexColor(color),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            AppIcon.fromMaterial(
              Icons.palette_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utilitaires
// ─────────────────────────────────────────────────────────────────────────────

/// Libellé traduit d'un preset.
///
/// Exhaustif par construction : un nouvel id sans libellé ne compilerait pas.
/// Un id inconnu — config d'une version future — affiche l'id brut.
String _presetLabel(BuildContext context, AppAppearancePreset preset) =>
    switch (preset.id) {
      'graphite' => context.tr.appearance_preset_graphite,
      'violet_bc' => context.tr.appearance_preset_violet_bc,
      'discord' => context.tr.appearance_preset_discord,
      'ocean' => context.tr.appearance_preset_ocean,
      'forest' => context.tr.appearance_preset_forest,
      'amber' => context.tr.appearance_preset_amber,
      'rose' => context.tr.appearance_preset_rose,
      'high_contrast' => context.tr.appearance_preset_high_contrast,
      _ => preset.id,
    };

/// Description courte traduite d'un preset (même mapping que [_presetLabel]).
String _presetDescription(BuildContext context, AppAppearancePreset preset) =>
    switch (preset.id) {
      'graphite' => context.tr.appearance_preset_graphite_desc,
      'violet_bc' => context.tr.appearance_preset_violet_bc_desc,
      'discord' => context.tr.appearance_preset_discord_desc,
      'ocean' => context.tr.appearance_preset_ocean_desc,
      'forest' => context.tr.appearance_preset_forest_desc,
      'amber' => context.tr.appearance_preset_amber_desc,
      'rose' => context.tr.appearance_preset_rose_desc,
      'high_contrast' => context.tr.appearance_preset_high_contrast_desc,
      _ => '',
    };

/// Surface RÉELLE d'un preset pour [brightness], avec la même règle que
/// [AppTheme] : le défaut graphite garde la carte neutre `homeCard` en mode
/// sombre, les autres presets suivent la palette M3 dérivée de leur graine.
Color _previewSurface(AppAppearancePreset preset, Brightness brightness) {
  final config = AppAppearanceConfig.defaults.copyWith(
    presetId: preset.id,
    seedColor: preset.seed,
    accentColor: preset.accentFor(brightness),
  );
  if (config.usesNeutralSurfaces && brightness == Brightness.dark) {
    return AppTheme.homeCard;
  }
  return ColorScheme.fromSeed(
    seedColor: preset.seed,
    brightness: brightness,
    dynamicSchemeVariant: preset.variant,
    contrastLevel: preset.contrastLevel,
  ).surface;
}

/// Code couleur technique (`#RRGGBB`) : jamais traduit.
String _hexColor(Color color) =>
    '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
