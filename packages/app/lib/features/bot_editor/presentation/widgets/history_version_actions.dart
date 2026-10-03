import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

class HistoryVersionMenu extends StatelessWidget {
  const HistoryVersionMenu({super.key, required this.onDelete});
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    enabled: onDelete != null,
    tooltip: context.tr.more_options_title,
    icon: const AppIcon.fromMaterial(Icons.more_vert),
    onSelected: (_) => onDelete?.call(),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: 'delete',
        child: Row(
          children: [
            AppIcon.fromMaterial(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              context.tr.common_delete,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ),
      ),
    ],
  );
}

class HistoryVersionActions extends StatelessWidget {
  const HistoryVersionActions({
    super.key,
    required this.onPreview,
    required this.onRestore,
    required this.restoreLabel,
  });
  final VoidCallback? onPreview;
  final VoidCallback? onRestore;
  final String restoreLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final preview = TextButton(
      onPressed: onPreview,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Text(context.tr.history_preview, textAlign: TextAlign.center),
    );
    final restore = TextButton(
      onPressed: onRestore,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.onPrimaryContainer,
      ),
      child: Text(restoreLabel, textAlign: TextAlign.center),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [preview, const SizedBox(height: 8), restore],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: preview),
              const SizedBox(width: 8),
              Expanded(child: restore),
            ],
          ),
        );
      },
    );
  }
}
