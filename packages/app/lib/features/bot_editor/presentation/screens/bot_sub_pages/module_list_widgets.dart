import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/theme/block_category.dart';
import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Briques communes des pages de modules (workflows, variables globales,
/// planificateur, webhooks entrants) : même anatomie de ligne que la liste de
/// commandes — pastille de famille, titre, résumé mono sur une ligne, chips,
/// menu « plus » au lieu d'icônes de suppression rouges.

/// Hauteur minimale d'une ligne de module (maquette : 62 px).
const double kModuleRowMinHeight = 62;

/// Ligne de module : surface plate (#16181E), bordure fine, rayon 16.
class ModuleRowCard extends StatelessWidget {
  const ModuleRowCard({
    super.key,
    required this.family,
    required this.icon,
    required this.title,
    this.summary,
    this.monoSummary = true,
    this.chips = const <Widget>[],
    this.trailing = const <Widget>[],
    this.onTap,
    this.dimmed = false,
    this.titleMono = false,
  });

  final BlockFamily family;
  final IconData icon;
  final String title;
  final String? summary;
  final bool monoSummary;
  final bool titleMono;
  final List<Widget> chips;
  final List<Widget> trailing;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kModuleRowMinHeight),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            Opacity(
              opacity: dimmed ? 0.55 : 1,
              child: family.pastille(icon, size: 40, iconSize: 20),
            ),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            height: 20 / 15,
                            fontWeight: FontWeight.w700,
                            color: dimmed
                                ? scheme.onSurface.withValues(alpha: 0.7)
                                : scheme.onSurface,
                            fontFamily: titleMono ? 'JetBrainsMono' : null,
                          ),
                        ),
                      ),
                      if (chips.length == 1) ...[
                        const SizedBox(width: 8),
                        chips.first,
                      ],
                    ],
                  ),
                  if (summary != null && summary!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 18 / 12.5,
                          color: tokens.muted,
                          fontFamily: monoSummary ? 'JetBrainsMono' : null,
                        ),
                      ),
                    ),
                  if (chips.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(spacing: 6, runSpacing: 4, children: chips),
                    ),
                ],
              ),
            ),
            ...trailing,
          ],
        ),
      ),
    );
    return Material(
      color: tokens.card,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: tokens.cardBorder),
      ),
      child: onTap == null ? body : InkWell(onTap: onTap, child: body),
    );
  }
}

/// Chip compact (20 px) pour les lignes de module.
class ModuleChip extends StatelessWidget {
  const ModuleChip(this.label, {super.key, this.mono = false});

  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.clusterBorder.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: tokens.muted,
          fontFamily: mono ? 'JetBrainsMono' : null,
        ),
      ),
    );
  }
}

/// Entrée d'un menu « plus » de ligne : icône + libellé, ton danger optionnel.
PopupMenuItem<T> moduleMenuItem<T>(
  BuildContext context, {
  required T value,
  required IconData icon,
  required String label,
  bool danger = false,
  VoidCallback? onTap,
}) {
  final color = danger ? Theme.of(context).colorScheme.error : null;
  return PopupMenuItem<T>(
    value: value,
    onTap: onTap,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon.fromMaterial(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: color == null ? null : TextStyle(color: color)),
      ],
    ),
  );
}

/// Bouton « plus » 44 px des lignes de module.
Widget moduleMoreButton<T>({
  required BuildContext context,
  required String tooltip,
  required List<PopupMenuEntry<T>> Function(BuildContext) itemBuilder,
  PopupMenuItemSelected<T>? onSelected,
}) {
  return PopupMenuButton<T>(
    tooltip: tooltip,
    padding: EdgeInsets.zero,
    icon: AppIcon.fromMaterial(
      Icons.more_vert_rounded,
      size: 20,
      color: HomeTokens.of(context).muted,
    ),
    onSelected: onSelected,
    itemBuilder: itemBuilder,
  );
}

/// Surtitre de section en majuscules (couleur de famille facultative).
class ModuleOverline extends StatelessWidget {
  const ModuleOverline(this.text, {super.key, this.family});

  final String text;
  final BlockFamily? family;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Semantics(
        header: true,
        child: Text(
          text.toUpperCase(),
          style: family != null
              ? family!.overlineStyle()
              : TextStyle(
                  fontSize: 10.5,
                  height: 14 / 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.84,
                  color: tokens.muted,
                ),
        ),
      ),
    );
  }
}

/// Carte « fonctionnalité premium » à plat (remplace la Card teintée).
class ModuleUpsellCard extends StatelessWidget {
  const ModuleUpsellCard({
    super.key,
    required this.title,
    required this.description,
    required this.action,
  });

  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.containerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon.fromMaterial(
                Icons.workspace_premium_rounded,
                color: AppTheme.premiumGold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(color: tokens.muted)),
          const SizedBox(height: 12),
          action,
        ],
      ),
    );
  }
}
