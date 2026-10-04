import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/widgets/floating_glass_nav_bar.dart';
import 'package:flutter/material.dart';

/// Barre de navigation PLATE de la refonte (84 px, `#12141A`, filet haut).
///
/// Même modèle d'item que [FloatingGlassNavBar] ([FloatingGlassNavItem]) :
/// le passage se fait en changeant le nom du widget. Item actif = barre
/// violette 28x3 + icône violette + libellé blanc. Semantics = libellé (pas de Tooltip).
class FlatNavBar extends StatelessWidget {
  const FlatNavBar({super.key, required this.items});

  final List<FloatingGlassNavItem> items;

  static const double height = 84;

  /// Hauteur à réserver sous le contenu (barre + zone de sécurité basse).
  static double contentClearanceOf(BuildContext context) =>
      height + MediaQuery.paddingOf(context).bottom;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Material(
      color: AppTheme.homeNavBar,
      child: Container(
        height: height + bottom,
        padding: EdgeInsets.only(bottom: bottom),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.homeCardBorder)),
        ),
        child: Row(
          children: [
            for (final item in items)
              Expanded(child: _FlatNavItem(item: item, vertical: false)),
          ],
        ),
      ),
    );
  }
}

/// Rail de navigation desktop (84 px de large) : icône + libellé 10 px dessous.
class FlatNavRail extends StatelessWidget {
  const FlatNavRail({
    super.key,
    required this.items,
    this.leading,
    this.trailing,
  });

  final List<FloatingGlassNavItem> items;

  /// Widget optionnel en tête de rail (logo).
  final Widget? leading;

  /// Widget optionnel en pied de rail (paramètres, compte).
  final Widget? trailing;

  static const double width = 84;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.homeNavBar,
      child: Container(
        width: width,
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppTheme.homeCardBorder)),
        ),
        child: SafeArea(
          right: false,
          child: Column(
            children: [
              if (leading != null) ...[
                const SizedBox(height: 12),
                leading!,
                const SizedBox(height: 8),
              ] else
                const SizedBox(height: 8),
              for (final item in items)
                SizedBox(
                  height: 64,
                  child: _FlatNavItem(item: item, vertical: true),
                ),
              const Spacer(),
              ?trailing,
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlatNavItem extends StatelessWidget {
  const _FlatNavItem({required this.item, required this.vertical});

  final FloatingGlassNavItem item;

  /// `true` pour le rail (indicateur à gauche) ; `false` pour la barre basse
  /// (indicateur en haut).
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final selected = item.selected;
    final iconColor = selected ? AppTheme.actionVioletSoft : AppTheme.homeMuted;
    final labelColor = selected ? Colors.white : AppTheme.homeMuted;
    final indicator = Container(
      width: vertical ? 3 : 28,
      height: vertical ? 28 : 3,
      decoration: BoxDecoration(
        color: selected ? AppTheme.actionViolet : Colors.transparent,
        borderRadius: BorderRadius.circular(2),
      ),
    );
    final content = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon.fromMaterial(
          selected ? (item.selectedIcon ?? item.icon) : item.icon,
          size: 24,
          color: iconColor,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            item.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: labelColor,
            ),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: item.onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: vertical
              ? Row(
                  children: [
                    indicator,
                    Expanded(child: content),
                  ],
                )
              : Column(
                  children: [
                    indicator,
                    Expanded(child: content),
                  ],
                ),
        ),
      ),
    );
  }
}
