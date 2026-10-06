import 'package:flutter/material.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';
import '../../widgets/flat_nav_top_bar.dart';
import '../../widgets/floating_glass_nav_bar.dart';
import '../../widgets/home_ui.dart';
import 'editor_sidebar.dart';

/// Navigation d'un bot sur desktop, en barre du haut : retour, identité du bot,
/// onglets, puis (à droite) mode débutant et réglages. Même contrat que
/// [EditorRail] : une vue pure, l'état vit chez le parent.
class EditorTopBar extends StatelessWidget {
  const EditorTopBar({
    super.key,
    required this.appName,
    required this.botId,
    this.avatarUrl,
    required this.sections,
    required this.activeItemId,
    required this.onSelectItem,
    required this.onBack,
    this.pinnedItem,
    this.showBackButton = false,
    this.showBeginnerMode = false,
    this.beginnerMode = false,
    this.onBeginnerModeChanged,
  });

  final String appName;
  final String botId;
  final String? avatarUrl;
  final List<EditorSidebarSection> sections;
  final EditorSidebarItem? pinnedItem;
  final String activeItemId;
  final void Function(String itemId) onSelectItem;
  final VoidCallback onBack;
  final bool showBackButton;
  final bool showBeginnerMode;
  final bool beginnerMode;
  final ValueChanged<bool>? onBeginnerModeChanged;

  String get _initial {
    final trimmed = appName.trim();
    return trimmed.isEmpty
        ? '?'
        : String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final items = [for (final section in sections) ...section.items];

    final identity = Tooltip(
      message: '$appName\nID $botId',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBackButton) ...[
            IconButton(
              tooltip: tr.common_back,
              onPressed: onBack,
              icon: const AppIcon.fromMaterial(
                Icons.arrow_back_rounded,
                size: 20,
              ),
            ),
            const SizedBox(width: 4),
          ],
          HomeBotAvatar(imageUrl: avatarUrl, size: 34, fallbackLabel: _initial),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              appName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBeginnerMode)
          IconButton(
            tooltip: tr.beginner_mode_label,
            onPressed: () => onBeginnerModeChanged?.call(!beginnerMode),
            icon: AppIcon.fromMaterial(
              Icons.school_rounded,
              size: 20,
              color: beginnerMode
                  ? AppTheme.actionVioletSoft
                  : AppTheme.homeMuted,
            ),
          ),
        if (pinnedItem != null)
          NavTopBarTab(
            icon: pinnedItem!.icon,
            label: pinnedItem!.tooltip ?? pinnedItem!.label,
            selected: pinnedItem!.id == activeItemId,
            onTap: () => onSelectItem(pinnedItem!.id),
          ),
      ],
    );

    return FlatNavTopBar(
      leading: identity,
      trailing: trailing,
      items: [
        for (final item in items)
          FloatingGlassNavItem(
            icon: item.icon,
            label: item.tooltip ?? item.label,
            selected: item.id == activeItemId,
            onTap: () => onSelectItem(item.id),
          ),
      ],
    );
  }
}
