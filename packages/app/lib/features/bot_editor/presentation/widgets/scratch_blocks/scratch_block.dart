import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
  });

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
    final surfaceColor =
        isDark
            ? Color.alphaBlend(color.withAlpha(25), colorScheme.surface)
            : Color.alphaBlend(color.withAlpha(15), colorScheme.surface);
    final headerColor =
        isDark
            ? Color.alphaBlend(color.withAlpha(50), colorScheme.surface)
            : Color.alphaBlend(color.withAlpha(30), colorScheme.surface);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: color.withAlpha(80), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──
          Material(
            color: headerColor,
            child: InkWell(
              onTap: onToggleCollapse,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Color strip indicator
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
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
                    ),
                    if (trailing != null) trailing!,
                    // Reorder buttons (only for non-required blocks)
                    if (onMoveUp != null || onMoveDown != null) ...[
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
                    ],
                    if (!required && onDelete != null)
                      _HeaderIconButton(
                        icon: Icons.close,
                        onPressed: onDelete!,
                        color: colorScheme.error,
                      ),
                    if (onToggleCollapse != null)
                      Icon(
                        collapsed ? Icons.expand_more : Icons.expand_less,
                        color: colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ── Body ──
          if (!collapsed)
            Container(
              color: surfaceColor,
              padding: const EdgeInsets.all(AppTheme.spacingMd),
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
      width: 28,
      height: 28,
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 18,
        icon: Icon(icon, color: color),
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
