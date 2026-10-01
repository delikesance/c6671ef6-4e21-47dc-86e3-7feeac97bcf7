import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'text_scale_settings_section.dart';

part 'appearance_preset_gallery.dart';

/// Seuil WCAG 2.1 des textes (1.4.3). En dessous, le contraste est signalé —
/// jamais bloqué : l'utilisateur reste libre de ses couleurs.
const double _contrastWarningThreshold = 4.5;

/// Carte « Apparence » des Paramètres : mode clair/sombre/système, galerie des
/// huit thèmes prédéfinis, couleurs personnalisées (avec ratio de contraste
/// affiché) et retour aux valeurs d'usine.
///
/// Le widget est auto-suffisant : il lit le [ThemeProvider] ambiant, dont
/// `MaterialApp` (main.dart) dérive ses deux thèmes. Chaque changement est donc
/// repeint immédiatement dans toute l'application, sans redémarrage.
class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  /// Clés stables des cibles interactives (utilisées par les tests).
  static const modeSelectorKey = ValueKey<String>('appearance_mode_selector');
  static const seedPickerKey = ValueKey<String>('appearance_seed_picker');
  static const accentPickerKey = ValueKey<String>('appearance_accent_picker');
  static const resetButtonKey = ValueKey<String>('appearance_reset_button');
  static const contrastRatioKey = ValueKey<String>('appearance_contrast_ratio');
  static const customBadgeKey = ValueKey<String>('appearance_custom_badge');
  static const contrastWarningKey = ValueKey<String>(
    'appearance_contrast_warning',
  );

  /// Clé de la carte d'aperçu d'un preset dans la galerie.
  static ValueKey<String> presetKey(AppAppearancePreset preset) =>
      ValueKey<String>('appearance_preset_${preset.id}');

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final appearance = provider.appearance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Contraste de l'accent CHOISI sur la surface du thème courant : c'est la
    // paire réellement peinte (remplissage des boutons, pastilles d'état).
    final ratio = AppTheme.contrastRatio(
      appearance.accentFor(theme.brightness),
      scheme.surface,
    );
    final ratioOk = ratio >= _contrastWarningThreshold;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.tr.settings_appearance_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr.settings_appearance_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // ── Mode clair / sombre / système ────────────────────────────────
            _SectionLabel(context.tr.settings_appearance_mode_title),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              key: modeSelectorKey,
              showSelectedIcon: false,
              segments: <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(context.tr.settings_appearance_mode_dark),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(context.tr.settings_appearance_mode_light),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(context.tr.settings_appearance_mode_system),
                ),
              ],
              selected: <ThemeMode>{appearance.mode},
              onSelectionChanged: (selection) =>
                  provider.setMode(selection.first),
            ),
            const SizedBox(height: 20),

            const TextScaleSettingsSection(),
            const SizedBox(height: 20),

            // ── Galerie des thèmes prédéfinis ────────────────────────────────
            _SectionLabel(context.tr.settings_appearance_presets_title),
            const SizedBox(height: 8),
            _PresetGallery(provider: provider, appearance: appearance),
            const SizedBox(height: 20),

            // ── Couleurs personnalisées ──────────────────────────────────────
            Row(
              children: <Widget>[
                Expanded(
                  child: _SectionLabel(
                    context.tr.settings_appearance_custom_title,
                  ),
                ),
                // Badge affiché dès que les couleurs s'écartent du preset.
                if (_isCustomised(appearance))
                  const _CustomBadge(key: customBadgeKey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ColorPickerTile(
                    key: seedPickerKey,
                    label: context.tr.settings_appearance_seed_label,
                    color: appearance.seedColor,
                    onTap: () => _pickColor(
                      context: context,
                      title: context.tr.settings_appearance_seed_label,
                      current: appearance.seedColor,
                      onPicked: provider.setSeed,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ColorPickerTile(
                    key: accentPickerKey,
                    label: context.tr.settings_appearance_accent_label,
                    color: appearance.accentFor(theme.brightness),
                    onTap: () => _pickColor(
                      context: context,
                      title: context.tr.settings_appearance_accent_label,
                      current: appearance.accentColor,
                      onPicked: provider.setAccent,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Ratio de contraste (informatif, non bloquant) ────────────────
            Row(
              children: <Widget>[
                Icon(
                  ratioOk
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  size: 16,
                  color: ratioOk ? scheme.onSurfaceVariant : scheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.tr.settings_appearance_contrast_ratio(
                      _formatRatio(ratio),
                    ),
                    key: contrastRatioKey,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (!ratioOk) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                context.tr.settings_appearance_contrast_warning(
                  _formatRatio(ratio),
                ),
                key: contrastWarningKey,
                style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 16),

            // ── Réinitialisation ─────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: resetButtonKey,
                onPressed: () => provider.resetToDefaults(),
                icon: const Icon(Icons.restart_alt),
                label: Text(context.tr.settings_appearance_reset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge « Personnalisé » : les couleurs ne sont plus celles du preset.
class _CustomBadge extends StatelessWidget {
  const _CustomBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        context.tr.settings_appearance_custom_badge,
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Petit titre de bloc interne à la carte.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

/// Vrai dès que la graine ou l'accent diffèrent du preset de référence : les
/// réglages ne décrivent plus le rendu proposé.
bool _isCustomised(AppAppearanceConfig appearance) {
  final preset = appearance.preset;
  return appearance.seedColor != preset.seed || !appearance.usesPresetAccent;
}

/// Ratio WCAG prêt à afficher, ex. « 4.5:1 ».
String _formatRatio(double ratio) => '${ratio.toStringAsFixed(1)}:1';

/// Ouvre le sélecteur de couleur (même dialogue que l'éditeur d'embeds) et
/// applique le choix retenu.
Future<void> _pickColor({
  required BuildContext context,
  required String title,
  required Color current,
  required ValueChanged<Color> onPicked,
}) async {
  Color selected = current;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: BlockPicker(
          pickerColor: current,
          onColorChanged: (color) => selected = color,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.tr.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(context.tr.common_apply),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    onPicked(selected);
  }
}
