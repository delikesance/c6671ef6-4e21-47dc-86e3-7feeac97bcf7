import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Shared visual container for a "mini-block" section.
/// Renders a compact header (icon + label + optional close button) above the content.
class MiniBlockContainer extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  /// When non-null the section is removable and shows a close (×) button.
  final VoidCallback? onRemove;

  const MiniBlockContainer({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = HomeTokens.of(context);
    final deleteLabel = context.tr.common_delete;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: tokens.clusterBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            child: Row(
              children: [
                AppIcon.fromMaterial(
                  icon,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Suppression rangée dans un menu ⋮ (plus de croix isolée).
                if (onRemove != null)
                  PopupMenuButton<String>(
                    tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    icon: AppIcon.fromMaterial(
                      Icons.more_vert,
                      size: 18,
                      color: tokens.muted,
                    ),
                    onSelected: (_) => onRemove?.call(),
                    itemBuilder: (_) => [
                      PopupMenuItem(value: 'delete', child: Text(deleteLabel)),
                    ],
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.clusterBorder),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ],
      ),
    );
  }
}

/// A re-usable "Add section" popup menu for mini-block editors.
class AddSectionMenu extends StatelessWidget {
  final List<(String key, IconData icon, String label)> sections;
  final ValueChanged<String> onSelected;
  final String buttonLabel;

  const AddSectionMenu({
    super.key,
    required this.sections,
    required this.onSelected,
    required this.buttonLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (sections.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return PopupMenuButton<String>(
      onSelected: onSelected,
      itemBuilder: (_) => sections
          .map(
            (s) => PopupMenuItem(
              value: s.$1,
              child: Row(
                children: [
                  AppIcon.fromMaterial(s.$2, size: 18),
                  const SizedBox(width: 8),
                  Flexible(child: Text(s.$3, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon.fromMaterial(
              Icons.add,
              size: 18,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              buttonLabel,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
