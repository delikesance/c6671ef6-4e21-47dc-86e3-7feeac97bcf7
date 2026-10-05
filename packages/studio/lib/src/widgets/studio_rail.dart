import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

class RailEntry {
  const RailEntry(this.id, this.label, this.icon);

  final String id;
  final String label;
  final IconData icon;
}

/// Rail de navigation de 84 px (équivalent de `FlatNavRail` / `EditorRail`).
/// Une entrée `null` dans [items] dessine un séparateur.
class StudioRail extends StatelessWidget {
  const StudioRail({
    super.key,
    required this.badge,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.bottomItems = const [],
    this.extraSelected = const {},
    this.itemHeight = 56,
  });

  final Widget badge;
  final List<RailEntry?> items;
  final List<RailEntry> bottomItems;
  final String selectedId;

  /// Entrées mises en évidence sans être la page affichée (interrupteurs).
  final Set<String> extraSelected;
  final ValueChanged<String> onSelect;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      decoration: const BoxDecoration(
        color: StudioColors.rail,
        border: Border(right: BorderSide(color: StudioColors.cardBorder)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          badge,
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: [
                for (final entry in items)
                  if (entry == null)
                    const _Divider()
                  else
                    _RailItem(
                      entry: entry,
                      selected:
                          entry.id == selectedId ||
                          extraSelected.contains(entry.id),
                      height: itemHeight,
                      onTap: () => onSelect(entry.id),
                    ),
              ],
            ),
          ),
          for (final entry in bottomItems)
            _RailItem(
              entry: entry,
              selected:
                  entry.id == selectedId || extraSelected.contains(entry.id),
              height: itemHeight,
              onTap: () => onSelect(entry.id),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 28),
    child: Divider(height: 1, thickness: 1, color: StudioColors.cardBorder),
  );
}

class _RailItem extends StatelessWidget {
  const _RailItem({
    required this.entry,
    required this.selected,
    required this.height,
    required this.onTap,
  });

  final RailEntry entry;
  final bool selected;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? StudioColors.actionSoft : StudioColors.muted;
    return Tooltip(
      message: entry.label,
      child: Semantics(
        button: true,
        selected: selected,
        label: entry.label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: Container(
                    width: 3,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected
                          ? StudioColors.action
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppIcon.fromMaterial(entry.icon, size: 22, color: color),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        entry.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.2,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected ? Colors.white : StudioColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastille de marque du rail (« BC » ou initiales du bot).
class RailBadge extends StatelessWidget {
  const RailBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color == StudioColors.action ? StudioColors.actionSoft : color,
        ),
      ),
    );
  }
}

/// Logo du Studio : la même icône que l'application (assets/logo.png, dérivée de
/// packages/app/assets/icon/icon.png).
class StudioLogo extends StatelessWidget {
  const StudioLogo({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.32),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        semanticLabel: 'Bot Creator',
      ),
    );
  }
}
