import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// A single block in the Scratch-like editor.
///
/// Displays a colored card with a header (icon + title), an optional badge for
/// required/non-deletable blocks, and a collapsible body.
class ScratchBlock extends StatelessWidget {
  const ScratchBlock({
    super.key,
    required this.color,
    required this.title,
    required this.icon,
    required this.child,
    this.required = false,
    this.isFinal = false,
    this.onDelete,
    this.collapsed = false,
    this.onToggleCollapse,
    this.onMoveUp,
    this.onMoveDown,
    this.badge,
    this.trailing,
    this.dragHandle,
    this.flat = false,
    this.overline,
  });

  /// Small category label shown above the title (in the category color).
  final String? overline;

  /// Optional drag handle widget shown in the header for reordering.
  final Widget? dragHandle;

  /// Whether to render without card borders/margins and colored header bar.
  final bool flat;

  /// Category accent color shown on the left strip and header icon.
  final Color color;

  /// Block title displayed in the header.
  final String title;

  /// Icon displayed in the header.
  final IconData icon;

  /// Block body content.
  final Widget child;

  /// When true the block cannot be deleted (no delete button shown).
  final bool required;

  /// When true, the block is a terminal / cap block (e.g. "respond with").
  /// A visual stop indicator is shown at the bottom and no connector should
  /// follow.
  final bool isFinal;

  /// Called when the user taps the delete button. Not shown if [required].
  final VoidCallback? onDelete;

  /// Whether the body is currently collapsed.
  final bool collapsed;

  /// Called when the user taps the header to expand/collapse.
  final VoidCallback? onToggleCollapse;

  /// Called to move this block up in the list.
  final VoidCallback? onMoveUp;

  /// Called to move this block down in the list.
  final VoidCallback? onMoveDown;

  /// Optional badge widget shown after the title (e.g. "required" chip).
  final Widget? badge;

  /// Optional trailing widget in the header row.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = isDark
        ? Color.alphaBlend(Colors.white.withAlpha(6), colorScheme.surface)
        : colorScheme.surface;

    if (flat) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon.fromMaterial(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (badge != null) ...[const SizedBox(width: 6), badge!],
              ],
            ),
            const SizedBox(height: 8),
            Container(padding: const EdgeInsets.only(left: 4), child: child),
            const SizedBox(height: 8),
            Divider(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
              height: 1,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bodyColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          InkWell(
            onTap: onToggleCollapse,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
              child: Row(
                children: [
                  if (dragHandle != null) ...[
                    dragHandle!,
                    const SizedBox(width: 6),
                  ],
                  // Category icon tile
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withAlpha(36),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: color.withAlpha(82)),
                    ),
                    child: Center(
                      child: AppIcon.fromMaterial(icon, color: color, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (overline != null)
                          Text(
                            overline!.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: color,
                            ),
                          ),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: colorScheme.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 6),
                              badge!,
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  ?trailing,
                  if (onMoveUp != null)
                    _HeaderIconButton(
                      icon: Icons.arrow_upward,
                      onPressed: onMoveUp!,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (onMoveDown != null)
                    _HeaderIconButton(
                      icon: Icons.arrow_downward,
                      onPressed: onMoveDown!,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (!required && onDelete != null)
                    _HeaderIconButton(
                      icon: Icons.delete_outline,
                      onPressed: onDelete!,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  if (onToggleCollapse != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: AppIcon.fromMaterial(
                        collapsed ? Icons.expand_more : Icons.expand_less,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // ── Body ──
          if (!collapsed)
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spacingMd,
                0,
                AppTheme.spacingMd,
                AppTheme.spacingMd,
              ),
              child: child,
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        icon: AppIcon.fromMaterial(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}

/// A small chip badge used inside block headers (e.g. "required").
class ScratchBlockBadge extends StatelessWidget {
  const ScratchBlockBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: effectiveColor.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        border: Border.all(color: effectiveColor.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: effectiveColor,
        ),
      ),
    );
  }
}
