import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';

class CommandFolderHeader extends StatelessWidget {
  final String title;
  final int count;
  final int directCount;
  final int depth;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onRename;
  final VoidCallback? onMove;
  final VoidCallback onDelete;
  final VoidCallback? onAddSubfolder;
  final VoidCallback? onNewCommand;
  final ValueChanged<Map<String, dynamic>>? onAcceptDrop;

  const CommandFolderHeader({
    super.key,
    required this.title,
    required this.count,
    this.directCount = 0,
    this.depth = 0,
    required this.isExpanded,
    required this.onToggle,
    required this.onRename,
    this.onMove,
    required this.onDelete,
    this.onAddSubfolder,
    this.onNewCommand,
    this.onAcceptDrop,
  });

  @override
  Widget build(BuildContext context) {
    final indentPadding = depth * 16.0;
    final headerChild = InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: EdgeInsets.fromLTRB(4 + indentPadding, 12, 4, 6),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0.25 : 0,
              duration: const Duration(milliseconds: 200),
              child: AppIcon.fromMaterial(
                Icons.chevron_right,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            if (depth > 0) ...[
              Text(
                '↳ ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            AppIcon.fromMaterial(
              isExpanded ? Icons.folder_open : Icons.folder,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: AppIcon.fromMaterial(
                Icons.more_vert,
                size: 18,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              padding: EdgeInsets.zero,
              itemBuilder: (context) => [
                if (onNewCommand != null)
                  PopupMenuItem(
                    value: 'add_command',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.add_circle_outline,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_create_button),
                      ],
                    ),
                  ),
                if (onAddSubfolder != null)
                  PopupMenuItem(
                    value: 'add_subfolder',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.create_new_folder_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_create_folder),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(Icons.edit, size: 18),
                      const SizedBox(width: 8),
                      Text(context.tr.commands_rename_folder),
                    ],
                  ),
                ),
                if (onMove != null)
                  PopupMenuItem(
                    value: 'move',
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.drive_file_move_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(context.tr.commands_move_to_folder),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const AppIcon.fromMaterial(
                        Icons.delete_outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(context.tr.commands_delete_folder),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'add_command') {
                  onNewCommand?.call();
                } else if (value == 'add_subfolder') {
                  onAddSubfolder?.call();
                } else if (value == 'rename') {
                  onRename();
                } else if (value == 'move') {
                  onMove?.call();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
            ),
          ],
        ),
      ),
    );

    if (onAcceptDrop == null) return headerChild;

    return DragTarget<Map<String, dynamic>>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAcceptDrop!(details.data),
      builder: (context, candidateData, _) {
        final isHovered = candidateData.isNotEmpty;
        if (!isHovered) return headerChild;
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
          child: headerChild,
        );
      },
    );
  }
}
