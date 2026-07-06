import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_merge.dart';
import 'package:flutter/material.dart';

Future<bool> showBotConfigPullConfirmDialog({
  required BuildContext context,
  required BotConfigMergeDiff diff,
  required String remoteTimestamp,
  required String localTimestamp,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.cloud_download, color: colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr.bot_home_pull,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildTimestampRow(
                    icon: Icons.cloud,
                    label: context.tr.bot_home_pull_dialog_remote,
                    timestamp: remoteTimestamp,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  _buildTimestampRow(
                    icon: Icons.phone_android,
                    label: context.tr.bot_home_pull_dialog_local,
                    timestamp: localTimestamp,
                    color: colorScheme.secondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (diff.hasChanges) ...[
              Text(
                context.tr.bot_home_pull_dialog_changes,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              if (diff.newCommands.isNotEmpty)
                _buildChangeRow(
                  Icons.add_circle_outline,
                  '${diff.newCommands.length} ${context.tr.bot_home_pull_dialog_new_commands}',
                  AppTheme.successAccent,
                ),
              if (diff.updatedCommands.isNotEmpty)
                _buildChangeRow(
                  Icons.update,
                  '${diff.updatedCommands.length} ${context.tr.bot_home_pull_dialog_updated_commands}',
                  AppTheme.warning,
                ),
              _buildChangeRow(
                Icons.check_circle_outline,
                '${diff.unchangedCount} ${context.tr.bot_home_pull_dialog_unchanged}',
                AppTheme.grey,
              ),
              _buildChangeRow(
                Icons.phone_android,
                '${diff.localOnlyCount} ${context.tr.bot_home_pull_dialog_local_only}',
                colorScheme.secondary,
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr.bot_home_pull_dialog_up_to_date,
                        style: TextStyle(color: AppTheme.successAccent),
                      ),
                    ),
                  ],
                ),
              ),
            if (diff.localOnlyCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${diff.localOnlyCount} ${context.tr.bot_home_pull_dialog_local_preserved}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(context.tr.common_cancel),
        ),
        FilledButton.icon(
          onPressed: diff.hasChanges ? () => Navigator.of(ctx).pop(true) : null,
          icon: const Icon(Icons.cloud_download, size: 18),
          label: Text(
            diff.hasChanges
                ? '${context.tr.bot_home_pull} (${diff.newCommands.length + diff.updatedCommands.length})'
                : context.tr.bot_home_pull,
          ),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

Widget _buildTimestampRow({
  required IconData icon,
  required String label,
  required String timestamp,
  required Color color,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color)),
            Text(
              timestamp,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildChangeRow(IconData icon, String label, Color color) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: color))),
      ],
    ),
  );
}
