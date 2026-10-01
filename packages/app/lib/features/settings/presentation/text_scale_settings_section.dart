import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_appearance.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class TextScaleSettingsSection extends StatelessWidget {
  const TextScaleSettingsSection({super.key});

  static const sliderKey = ValueKey('settings_text_scale_slider');
  static const resetKey = ValueKey('settings_text_scale_reset');
  static const previewKey = ValueKey('settings_text_scale_preview');

  static String _percentage(double value) => '${(value * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ThemeProvider>();
    final factor = AppAppearanceConfig.normalizeTextScale(
      provider.appearance.textScale,
    );
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.settings_text_size_title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_percentage(factor), style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.settings_text_size_description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Semantics(
          label: context.tr.settings_text_size_title,
          child: Slider(
            key: sliderKey,
            value: factor,
            min: AppAppearanceConfig.minTextScale,
            max: AppAppearanceConfig.maxTextScale,
            divisions: 10,
            label: _percentage(factor),
            semanticFormatterCallback: _percentage,
            onChanged: provider.setTextScale,
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            context.tr.settings_text_size_preview,
            key: previewKey,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextButton.icon(
          key: resetKey,
          onPressed: factor == 1.0 ? null : () => provider.setTextScale(1.0),
          icon: const AppIcon.fromMaterial(Icons.restart_alt),
          label: Text(context.tr.settings_text_size_reset),
        ),
      ],
    );
  }
}
