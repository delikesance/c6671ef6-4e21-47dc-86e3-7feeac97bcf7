import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

import './app_icon.dart';

/// Variante de rendu de [FloatingGlassNavBar] : mêmes items, même fond « verre
/// dépoli », même animation et mêmes dimensions d'item — seule la mise en page
/// diffère.
enum FloatingGlassNavVariant {
  /// Barre flottante du bottom menu : positionnée par l'appelant dans un
  /// `Stack` via [FloatingGlassNavBar.bottomOffsetOf].
  floating,

  /// Bandeau intégré au flux (`Column`, `AppBar.bottom`, en-tête de section) :
  /// plus court, sans ombre portée ni positionnement flottant.
  inline,
}

/// Une entrée de [FloatingGlassNavBar]. Le libellé sert de texte sous l'icône et
/// de tooltip : c'est la signature des tests de navigation
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

/// Barre de navigation « verre dépoli » partagée par toute l'application :
/// bottom menu du shell mobile (`MyMainPage`), bottom menu de l'éditeur de bot
/// (`AppEditPage`), pastilles de modules/système et onglets de l'éditeur.
///
/// En variante [FloatingGlassNavVariant.floating], le widget ne se positionne
/// pas lui-même : l'appelant l'insère dans un `Stack` (`Scaffold(extendBody:
/// true)`) via les constantes partagées, pour un placement identique partout :
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
/// Les contenus sous la barre réservent [FloatingGlassNavBar.contentClearanceOf].
///
/// En variante [FloatingGlassNavVariant.inline] (`FloatingGlassNavBar.inline`),
/// le bandeau se place dans un flux : `Column`, `AppBar.bottom` (dimensionné
/// avec [FloatingGlassNavBar.inlinePreferredHeight]) ou tout autre en-tête.
class FloatingGlassNavBar extends StatelessWidget {
  /// Barre flottante (bottom menu). Voir [FloatingGlassNavBar.inline] pour le
  /// bandeau intégré au flux.
  const FloatingGlassNavBar({
    super.key,
    required this.items,
    this.height = defaultHeight,
  }) : variant = FloatingGlassNavVariant.floating,
       scrollable = false;

  /// Bandeau inline : mêmes items que la barre flottante, mais intégré au flux.
  ///
  /// Avec [scrollable], les items gardent leur largeur intrinsèque et le
  /// bandeau défile horizontalement (utile au-delà de 3 items sur mobile) ;
  /// sinon ils se répartissent toute la largeur disponible.
  const FloatingGlassNavBar.inline({
    super.key,
    required this.items,
    this.scrollable = false,
    this.height = inlineHeight,
  }) : variant = FloatingGlassNavVariant.inline;

  /// Hauteur de référence de la barre flottante.
  static const double defaultHeight = 64;

  /// Hauteur de référence du bandeau inline (plus court que la barre).
  static const double inlineHeight = 58;

  /// Marge entre la barre flottante et les bords gauche/droit/bas de l'écran.
  static const double margin = 16;

  /// Rayon des coins extérieurs (identique au rayon des cartes).
  static const double radius = AppTheme.radiusCard;

  /// Padding interne entre le bord de la barre et ses items.
  static const double inset = 8;

  /// Espace horizontal entre deux items.
  static const double itemGap = 6;

  /// Rayon des items et de leur fond sélectionné.
  static const double itemRadius = 16;

  /// Hauteur d'un item de la barre flottante.
  static const double itemHeight = 48;

  /// Hauteur d'un item du bandeau inline.
  static const double inlineItemHeight = 42;

  /// Marge horizontale recommandée autour d'un bandeau inline.
  static const double inlineHorizontalMargin = 12;

  /// Marge verticale recommandée autour d'un bandeau inline.
  static const double inlineVerticalMargin = 6;

  /// Hauteur à réserver par un bandeau inline, marges comprises : à passer comme
  /// `preferredSize` dans `AppBar.bottom`.
  static const double inlinePreferredHeight =
      inlineHeight + inlineVerticalMargin * 2;

  /// Largeur minimale d'un item du bandeau inline [scrollable] : garantit une
  /// cible tactile confortable même pour un libellé court.
  static const double inlineScrollItemMinWidth = 84;

  /// Décalage bas à passer au `Positioned` qui accueille la barre flottante.
  static double bottomOffsetOf(BuildContext context) =>
      margin + MediaQuery.paddingOf(context).bottom;

  /// Espace vertical à réserver sous le contenu pour ne pas masquer la barre.
  static double contentClearanceOf(BuildContext context) =>
      bottomOffsetOf(context) + defaultHeight;

  final List<FloatingGlassNavItem> items;

  /// [FloatingGlassNavVariant.floating] ou [FloatingGlassNavVariant.inline].
  final FloatingGlassNavVariant variant;

  /// Bandeau inline uniquement : items à largeur intrinsèque et défilement
  /// horizontal au lieu d'un partage de la largeur disponible.
  final bool scrollable;

  /// Hauteur du conteneur : surchargeable, défaut dépendant de la variante.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Thème porteur des jetons « home ». Un thème construit à la main sans
    // extension `HomeTokens` (tests) retombe sur les constantes historiques
    // plutôt que sur une dérivation de palette : sa signature visuelle exacte
    // — le fond `AppTheme.homeNavBar` — reste verrouillée.
    final tokens = Theme.of(context).extension<HomeTokens>();
    final radius = BorderRadius.circular(FloatingGlassNavBar.radius);
    final isInline = variant == FloatingGlassNavVariant.inline;
    final itemHeight = isInline
        ? FloatingGlassNavBar.inlineItemHeight
        : FloatingGlassNavBar.itemHeight;

    final Widget itemsRow;
    if (isInline && scrollable) {
      itemsRow = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(width: itemGap),
              ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: inlineScrollItemMinWidth,
                ),
                child: _FloatingGlassNavItemView(items[i], height: itemHeight),
              ),
            ],
          ],
        ),
      );
    } else {
      itemsRow = Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: itemGap),
            Expanded(
              child: _FloatingGlassNavItemView(items[i], height: itemHeight),
            ),
          ],
        ],
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          // Le bandeau inline n'est pas posé au-dessus du contenu : pas
          // d'ombre portée, seulement la même surface en verre dépoli.
          boxShadow: isInline
              ? null
              : [
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
                  ? (tokens?.navBar ?? AppTheme.homeNavBar)
                  : scheme.surface.withValues(alpha: 0.96),
              border: Border.all(
                color: isDark
                    ? (tokens?.cardBorder ?? AppTheme.homeCardBorder)
                    : scheme.outlineVariant,
              ),
            ),
            child: SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.all(inset),
                child: itemsRow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingGlassNavItemView extends StatelessWidget {
  const _FloatingGlassNavItemView(this.item, {required this.height});

  final FloatingGlassNavItem item;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<HomeTokens>();
    final accent = tokens?.accent ?? scheme.primary;
    final accentIndicator = HomeTokens.of(context).accentIndicator;
    final selectedForeground = isDark
        ? Colors.white
        : scheme.onSecondaryContainer;
    final selectedFill = isDark
        ? accent.withValues(alpha: 0.30)
        : scheme.secondaryContainer;
    final idleColor = isDark
        ? (tokens?.muted ?? AppTheme.homeMuted)
        : scheme.onSurfaceVariant;
    final color = item.selected ? selectedForeground : idleColor;
    final radius = BorderRadius.circular(FloatingGlassNavBar.itemRadius);
    final borderStroke = accentIndicator;

    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: radius,
          splashColor: selectedFill.withValues(alpha: 0.5),
          highlightColor: selectedFill.withValues(alpha: 0.35),
          child: AnimatedContainer(
            duration: AppTheme.animFast,
            curve: Curves.easeOutCubic,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: radius,
              color: item.selected ? selectedFill : Colors.transparent,
            ),
            // Indicateur d'accent de l'item sélectionné : la pastille de fond
            // reste NEUTRE, seule la bordure porte la couleur d'accent. Peint en
            // `foregroundDecoration` pour ne pas décaler (padding de bordure)
            // l'icône et le libellé de l'item.
            foregroundDecoration: item.selected
                ? BoxDecoration(
                    borderRadius: radius,
                    border: Border.all(color: borderStroke, width: 1.5),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon.fromMaterial(
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
