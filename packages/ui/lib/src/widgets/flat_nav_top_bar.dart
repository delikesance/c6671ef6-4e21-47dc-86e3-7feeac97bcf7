import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'floating_glass_nav_bar.dart';

/// Barre de navigation du haut (desktop) : logo, onglets horizontaux, actions à
/// droite. Remplace le rail latéral de 84 px, dont les libellés étaient tronqués
/// (« Documentat… ») : ici chaque onglet a la place de son texte.
///
/// Même modèle d'item que [FlatNavBar] ([FloatingGlassNavItem]). Onglet actif =
/// pastille violette, icône violette douce, libellé blanc. Quand la fenêtre est
/// trop étroite pour tous les onglets, la rangée défile horizontalement au lieu
/// de déborder.
class FlatNavTopBar extends StatelessWidget {
  const FlatNavTopBar({
    super.key,
    required this.items,
    this.leading,
    this.trailing,
  });

  final List<FloatingGlassNavItem> items;

  /// En tête de barre (logo, bouton retour, identité du bot).
  final Widget? leading;

  /// En fin de barre (réglages, compte).
  final Widget? trailing;

  static const double height = 60;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.homeNavBar,
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.homeCardBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (leading != null) ...[leading!, const SizedBox(width: 20)],
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final item in items)
                            NavTopBarTab(
                              icon: item.selected
                                  ? (item.selectedIcon ?? item.icon)
                                  : item.icon,
                              label: item.label,
                              selected: item.selected,
                              onTap: item.onTap,
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 12),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un onglet de la barre du haut : icône + libellé sur une ligne, le libellé
/// n'est jamais coupé.
class NavTopBarTab extends StatelessWidget {
  const NavTopBarTab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? AppTheme.actionVioletSoft : AppTheme.homeMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.actionViolet.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon.fromMaterial(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: selected ? Colors.white : AppTheme.homeMuted,
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
