import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Une entrée de [FloatingGlassNavBar].
///
/// Le libellé sert à la fois de texte sous l'icône et de tooltip : c'est aussi
/// la signature sur laquelle s'appuient les tests de navigation
/// (`find.byTooltip(libellé localisé)`), donc il doit toujours être localisé.
class FloatingGlassNavItem {
  const FloatingGlassNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedIcon,
  });

  /// Icône à l'état inactif, et seule icône si [selectedIcon] est `null`.
  final IconData icon;

  /// Variante pleine affichée quand l'item est sélectionné.
  final IconData? selectedIcon;

  final String label;
  final bool selected;
  final VoidCallback onTap;
}

/// Barre de navigation flottante « verre dépoli », partagée par le shell
/// mobile de la Home (`MyMainPage`) et l'éditeur de bot (`AppEditPage`), afin
/// que les deux bottom menus aient exactement le même design.
///
/// Le widget ne se positionne pas lui-même : l'appelant l'insère dans un
/// `Stack` d'un `Scaffold(extendBody: true)` via les constantes de mise en page
/// partagées, pour que les deux écrans placent la barre à l'identique :
///
/// ```dart
/// Positioned(
///   left: FloatingGlassNavBar.margin,
///   right: FloatingGlassNavBar.margin,
///   bottom: FloatingGlassNavBar.bottomOffsetOf(context),
///   child: FloatingGlassNavBar(items: items),
/// )
/// ```
///
/// Les contenus placés sous la barre doivent réserver
/// [FloatingGlassNavBar.contentClearanceOf] en bas pour ne rien masquer.
class FloatingGlassNavBar extends StatelessWidget {
  const FloatingGlassNavBar({
    super.key,
    required this.items,
    this.height = defaultHeight,
  });

  /// Hauteur de référence de la barre.
  static const double defaultHeight = 64;

  /// Marge entre la barre et les bords gauche/droit/bas de l'écran.
  static const double margin = 16;

  /// Rayon des coins extérieurs (identique au rayon des cartes).
  static const double radius = AppTheme.radiusCard;

  /// Padding interne entre le bord de la barre et ses items.
  static const double inset = 8;

  /// Espace horizontal entre deux items.
  static const double itemGap = 6;

  /// Rayon des items et de leur fond sélectionné.
  static const double itemRadius = 16;

  /// Hauteur d'un item.
  static const double itemHeight = 48;

  /// Décalage bas à passer au `Positioned` qui accueille la barre.
  static double bottomOffsetOf(BuildContext context) =>
      margin + MediaQuery.paddingOf(context).bottom;

  /// Espace vertical occupé en bas de l'écran par la barre (décalage bas +
  /// hauteur) : le padding bas minimum à réserver par le contenu.
  static double contentClearanceOf(BuildContext context) =>
      bottomOffsetOf(context) + defaultHeight;

  final List<FloatingGlassNavItem> items;

  /// Hauteur de la barre. Exposée pour permettre un override explicite, mais
  /// la valeur par défaut est celle partagée par les deux écrans.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(FloatingGlassNavBar.radius);

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.85 : 0.16),
              blurRadius: isDark ? 48 : 24,
              spreadRadius: isDark ? 4 : 0,
              offset: Offset(0, isDark ? 8 : 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: isDark
                  ? AppTheme.homeNavBar
                  : scheme.surface.withValues(alpha: 0.96),
              border: Border.all(
                color: isDark ? AppTheme.homeCardBorder : scheme.outlineVariant,
              ),
            ),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const SizedBox(width: itemGap),
                      Expanded(child: _FloatingGlassNavItemView(items[i])),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingGlassNavItemView extends StatelessWidget {
  const _FloatingGlassNavItemView(this.item);

  final FloatingGlassNavItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedColor = isDark
        ? AppTheme.brandPurpleSoft
        : AppTheme.brandPrimary;
    final idleColor = isDark
        ? AppTheme.homeMuted
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final color = item.selected ? selectedColor : idleColor;
    final radius = BorderRadius.circular(FloatingGlassNavBar.itemRadius);

    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: radius,
          splashColor: selectedColor.withValues(alpha: 0.12),
          highlightColor: selectedColor.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            curve: Curves.easeOutCubic,
            height: FloatingGlassNavBar.itemHeight,
            decoration: BoxDecoration(
              borderRadius: radius,
              color: item.selected
                  ? (isDark
                        ? AppTheme.homeNavSelected
                        : AppTheme.brandPrimary.withValues(alpha: 0.12))
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.selected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: item.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
