import 'package:flutter/material.dart';

import '../theme.dart';
import 'studio_rail.dart';

/// Barre de navigation du bas (téléphone), équivalent de `FlatNavBar` de l'app :
/// 84 px, fond du rail, liseré en haut, indicateur de 28×3 sur l'entrée active.
class StudioBottomBar extends StatelessWidget {
  const StudioBottomBar({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final List<RailEntry> items;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: StudioColors.rail,
        border: Border(top: BorderSide(color: StudioColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 84,
          child: Row(
            children: [
              for (final entry in items)
                Expanded(
                  child: _BarItem(
                    entry: entry,
                    selected: entry.id == selectedId,
                    onTap: () => onSelect(entry.id),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final RailEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? StudioColors.actionSoft : StudioColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: entry.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? StudioColors.action : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Spacer(),
            Icon(entry.icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              entry.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : StudioColors.muted,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
