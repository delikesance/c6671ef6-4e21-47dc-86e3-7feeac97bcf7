import 'package:bot_creator/utils/app_theme.dart';
import 'package:flutter/material.dart';

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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
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
                if (onRemove != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    onTap: onRemove,
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXs),
                      child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: child,
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
                  Icon(s.$2, size: 18),
                  const SizedBox(width: 8),
                  Text(s.$3),
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
            Icon(Icons.add, size: 18, color: theme.colorScheme.primary),
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
