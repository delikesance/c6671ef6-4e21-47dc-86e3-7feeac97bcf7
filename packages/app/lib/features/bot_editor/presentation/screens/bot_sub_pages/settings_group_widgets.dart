import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Briques partagées des pages de réglages (carte groupée, titre en overline,
/// lignes de 54 px minimum). Elles lisent [HomeTokens] : les préréglages
/// d'apparence autres que graphite gardent leurs propres couleurs.

/// Hauteur minimale d'une ligne de réglage (cible tactile confortable).
const double kSettingsRowMinHeight = 54;

/// Titre de section en overline (majuscules, 10.5 px, espacé).
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key, this.danger = false});

  final String title;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 10.5,
            height: 14 / 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.84,
            color: danger ? AppTheme.statusErrorText : tokens.muted,
          ),
        ),
      ),
    );
  }
}

/// Carte plate de réglages : fond « raised », bordure fine, rayon 20.
/// Les enfants sont séparés par un filet de 1 px (comme dans la maquette).
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.divided = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (divided && i > 0) {
        items.add(Divider(height: 1, thickness: 1, color: tokens.cardBorder));
      }
      items.add(children[i]);
    }
    // Material (et non DecoratedBox) : les ListTile enfants peignent leur
    // encre sur le Material le plus proche.
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items,
        ),
      ),
    );
  }
}

/// Section complète : overline + carte groupée.
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.danger = false,
    this.padding = EdgeInsets.zero,
    this.divided = true,
  });

  final String title;
  final List<Widget> children;
  final bool danger;
  final EdgeInsetsGeometry padding;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSectionHeader(title, danger: danger),
          SettingsGroupCard(
            padding: padding,
            divided: divided,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// Pastille d'icône neutre (36 px) des lignes de réglages.
class SettingsRowIcon extends StatelessWidget {
  const SettingsRowIcon(this.icon, {super.key, this.family});

  final IconData icon;

  /// Si fourni, la pastille prend la teinte de la famille de blocs.
  final BlockFamily? family;

  @override
  Widget build(BuildContext context) {
    final fam = family;
    if (fam != null) return fam.pastille(icon, size: 36, iconSize: 18);
    final tokens = HomeTokens.of(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: tokens.clusterBg,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: tokens.clusterBorder),
      ),
      child: Center(
        child: AppIcon.fromMaterial(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Ligne de réglage : icône optionnelle, titre, sous-titre, contrôle final.
/// 54 px minimum ; toute la ligne est cliquable si [onTap] est fourni.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.minHeight = kSettingsRowMinHeight,
    this.monoSubtitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double minHeight;
  final bool monoSubtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final content = ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 14, 8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 18 / 14.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 16 / 12.5,
                          color: tokens.muted,
                          fontFamily: monoSubtitle ? 'JetBrainsMono' : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
      ),
    );
    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

/// Ligne de navigation : même gabarit + chevron.
class SettingsNavRow extends StatelessWidget {
  const SettingsNavRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettingsRow(
      title: title,
      subtitle: subtitle,
      leading: leading,
      onTap: onTap,
      trailing: AppIcon.fromMaterial(
        Icons.chevron_right,
        size: 20,
        color: HomeTokens.of(context).muted,
      ),
    );
  }
}

/// Ligne avec un vrai interrupteur ; la ligne entière bascule.
class SettingsToggleRow extends StatelessWidget {
  const SettingsToggleRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final cb = onChanged;
    return MergeSemantics(
      child: SettingsRow(
        title: title,
        subtitle: subtitle,
        leading: leading,
        onTap: cb == null ? null : () => cb(!value),
        trailing: Switch(value: value, onChanged: cb),
      ),
    );
  }
}

/// Petit libellé « chip » (type d'activité, compteur…).
class SettingsChip extends StatelessWidget {
  const SettingsChip(this.label, {super.key, this.minWidth = 0});

  final String label;
  final double minWidth;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Container(
      constraints: BoxConstraints(minWidth: minWidth, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.clusterBorder.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
