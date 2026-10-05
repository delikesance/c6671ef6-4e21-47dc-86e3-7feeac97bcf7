import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../theme/block_family.dart';
import '../../widgets/app_icon.dart';
import '../logic/command_folder_tree.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';

/// Carte d'une commande dans la liste : pastille de type, nom, dossier,
/// compteurs (options, actions, sous-commandes) et alias.
///
/// Travaille sur la commande JSON de l'app (`name`, `type`, `folder`,
/// `templateOrigin`, `data.{commandType, options, actions, legacy*}`). Les
/// actions (ouvrir, déplacer, supprimer, mode sélection) sont des callbacks :
/// l'hôte décide ce qu'elles font, et un callback absent masque l'entrée.
class CommandListCard extends StatelessWidget {
  const CommandListCard({
    super.key,
    required this.command,
    required this.onOpen,
    this.onLongPress,
    this.onMove,
    this.onDelete,
    this.selectMode = false,
    this.selected = false,
    this.onSelectedChanged,
  });

  final Map<String, dynamic> command;
  final VoidCallback onOpen;
  final VoidCallback? onLongPress;
  final VoidCallback? onMove;
  final VoidCallback? onDelete;
  final bool selectMode;
  final bool selected;
  final ValueChanged<bool>? onSelectedChanged;

  Map<String, dynamic> get _data =>
      (command['data'] as Map?)?.cast<String, dynamic>() ?? const {};

  IconData get _typeIcon {
    if (_data['legacyModeEnabled'] == true) return Icons.text_fields_rounded;
    final type = (command['type'] ?? _data['commandType'] ?? 'chatInput')
        .toString();
    switch (type) {
      case 'user':
        return Icons.person_outline;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      default:
        return Icons.terminal_rounded;
    }
  }

  BlockFamily get _family => _data['legacyModeEnabled'] == true
      ? BlockFamily.events
      : BlockFamily.messages;

  @override
  Widget build(BuildContext context) {
    final name = (command['name'] ?? 'unknown').toString();
    final templateOrigin = command['templateOrigin'];
    final templateId =
        (templateOrigin is Map ? templateOrigin['templateId'] : '') ?? '';
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final hasMenu = onMove != null || onDelete != null;
    return Card(
      color: tokens.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: tokens.clusterBorder),
      ),
      child: InkWell(
        onLongPress: onLongPress,
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            children: [
              if (selectMode)
                Checkbox(
                  value: selected,
                  onChanged: (v) => onSelectedChanged?.call(v == true),
                )
              else
                _family.pastille(_typeIcon, size: 40, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // Nom de commande en monospace (identifiant).
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if ('$templateId'.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppIcon.fromMaterial(
                                  Icons.auto_awesome,
                                  size: 12,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$templateId',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _subtitle(context),
                  ],
                ),
              ),
              if (!selectMode && hasMenu)
                PopupMenuButton<String>(
                  tooltip: context.tr.more_options_title,
                  icon: AppIcon.fromMaterial(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onSelected: (value) {
                    if (value == 'move') onMove?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onMove != null)
                      PopupMenuItem(
                        value: 'move',
                        child: Row(
                          children: [
                            const AppIcon.fromMaterial(
                              Icons.drive_file_move_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Text(context.tr.commands_move_to_folder),
                          ],
                        ),
                      ),
                    if (onMove != null && onDelete != null)
                      const PopupMenuDivider(),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            AppIcon.fromMaterial(
                              Icons.delete_outline,
                              size: 18,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.tr.delete,
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AppIcon.fromMaterial(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _subtitle(BuildContext context) {
    final folder = normalizeFolderPath((command['folder'] ?? '').toString());
    final colorScheme = Theme.of(context).colorScheme;
    final optionsCount = (_data['options'] as List?)?.length ?? 0;
    final actionsCount = (_data['actions'] as List?)?.length ?? 0;
    final subcommandCount = (_data['subcommandWorkflows'] as Map?)?.length ?? 0;
    final legacyMode = _data['legacyModeEnabled'] == true;
    final legacyLocal = _data['legacyLocalOnly'] == true;
    final aliases = legacyMode
        ? normalizeLegacyCommandAliases(_data['legacyAliases'])
        : const <String>[];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (folder.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.fromMaterial(
                  Icons.folder_outlined,
                  size: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 3),
                Text(
                  folder,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (optionsCount > 0)
          CommandMetaChip(
            label: context.tr.review_options_count(optionsCount),
            tooltip: context.tr.component_options,
          ),
        CommandMetaChip(
          label: context.tr.bot_home_actions_count(actionsCount),
          tooltip: context.tr.actions_title,
        ),
        if (subcommandCount > 0)
          CommandMetaChip(
            label: '$subcommandCount',
            icon: Icons.route_outlined,
            tooltip: context.tr.actions_workflows,
          ),
        if (legacyMode && !legacyLocal)
          const CommandMetaChip(icon: Icons.history_toggle_off),
        if (legacyLocal) const CommandMetaChip(icon: Icons.offline_bolt),
        for (final alias in aliases)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Text(
              '!$alias',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

/// Pastille d'information d'une carte de commande (compteur ou icône).
class CommandMetaChip extends StatelessWidget {
  const CommandMetaChip({super.key, this.label, this.icon, this.tooltip});

  final String? label;
  final IconData? icon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final chip = Container(
      constraints: const BoxConstraints(minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: HomeTokens.of(context).navSelected,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            AppIcon.fromMaterial(
              icon!,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          if (label != null) ...[
            if (icon != null) const SizedBox(width: 4),
            Text(
              label!,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}
