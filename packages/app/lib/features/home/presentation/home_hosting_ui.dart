import 'package:bot_creator/features/home/logic/hosting_time_offer.dart';
import 'package:bot_creator/features/home/presentation/home_hosting_action_area.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Carte « temps total » d'hébergement de la home d'un bot.
///
/// Pastille d'état + badge d'équipe, expiration prévue (surtitre + valeur), puis
/// la décomposition du temps restant en mois / jours / heures / minutes et
/// l'action « Ajouter du temps ».
///
/// C'est [offer] qui décide ce que le bas de la carte a le droit de proposer :
/// bouton (mobile non abonné), explication (poste de travail) ou rien
/// (abonné). Aucune condition de plateforme ni de formule n'est recopiée ici.
class HomeHostingTimeCard extends StatelessWidget {
  const HomeHostingTimeCard({
    super.key,
    required this.statusLabel,
    required this.statusColor,
    required this.overline,
    required this.headline,
    required this.segments,
    required this.onAddTime,
    this.offer = HostingTimeOffer.addTime,
    this.showTeamBadge = false,
    this.isAddingTime = false,
    this.emphasizeBorder = false,
  });

  /// Ce que cet écran a le droit d'offrir (décision `hosting_time_offer.dart`).
  final HostingTimeOffer offer;

  /// Libellé de la pastille d'état (« Session active »).
  final String statusLabel;

  /// Couleur de la pastille : santé de la réserve (vert / orange / rouge).
  final Color statusColor;

  /// Surtitre du bloc principal (« Expiration prévue ») — rendu en majuscules,
  /// comme les libellés d'unités.
  final String overline;

  /// Valeur principale : date d'expiration, ou temps restant quand le bot est
  /// arrêté.
  final String headline;

  /// Décomposition du temps restant : une entrée par unité (valeur + libellé).
  final List<({String value, String label})> segments;

  /// Badge « Team » (bot rattaché à une équipe).
  final bool showTeamBadge;

  final VoidCallback? onAddTime;
  final bool isAddingTime;

  /// Bordure d'alerte (réserve critique) ; par défaut la bordure de carte.
  final bool emphasizeBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? tokens.card : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: emphasizeBorder
              ? AppTheme.error.withValues(alpha: 0.9)
              : (isDark ? tokens.cardBorder : scheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HostingStatusPill(label: statusLabel, color: statusColor),
              const Spacer(),
              if (showTeamBadge) const _HostingTeamBadge(),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            overline.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headline,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: homeDisplayStyle(
              20,
              color: scheme.onSurface,
              weight: FontWeight.w700,
            ),
          ),
          // Un abonné n'a rien à décompter : sa carte ne porte que son état, et
          // aucune décomposition ne doit apparaître sous un « illimité ».
          if (segments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _HostingSegments(segments: segments),
          ],
          HomeHostingActionArea(
            offer: offer,
            onAddTime: onAddTime,
            isAddingTime: isAddingTime,
          ),
        ],
      ),
    );
  }
}

/// Pastille d'état de la carte d'hébergement (point + libellé).
class _HostingStatusPill extends StatelessWidget {
  const _HostingStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge « Team » : bot hébergé pour une équipe.
class _HostingTeamBadge extends StatelessWidget {
  const _HostingTeamBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.discord.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppTheme.discord.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.fromMaterial(
            Icons.groups,
            size: 12,
            color: AppTheme.discord,
          ),
          const SizedBox(width: 4),
          Text(
            context.tr.team_tab,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.discord,
            ),
          ),
        ],
      ),
    );
  }
}

/// Décomposition du temps restant : une colonne par unité, séparateurs fins.
class _HostingSegments extends StatelessWidget {
  const _HostingSegments({required this.segments});

  final List<({String value, String label})> segments;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;
    final background = isDark ? tokens.clusterBg : scheme.surfaceContainerLow;
    final separator = (isDark ? tokens.clusterBorder : scheme.outlineVariant)
        .withValues(alpha: 0.6);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard - 8),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) Container(width: 1, height: 30, color: separator),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    segments[i].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: homeDisplayStyle(
                      17,
                      color: scheme.onSurface,
                      weight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    segments[i].label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
