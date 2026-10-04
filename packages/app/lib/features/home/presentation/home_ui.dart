import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/image_disk_cache.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/logic/hosting_time_offer.dart';
import 'package:bot_creator/features/home/presentation/home_hosting_action_area.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';
import 'package:bot_creator/core/widgets/status_pill.dart';

/// Shared display text style used across the Home redesign.
TextStyle homeDisplayStyle(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w600,
}) {
  return GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color);
}

/// Overline / section label matching the Home header muted caption.
TextStyle homeSectionLabelStyle(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final tokens = HomeTokens.of(context);
  final muted = isDark
      ? tokens.muted
      : Theme.of(context).colorScheme.onSurfaceVariant;
  // Surtitre de la refonte : Inter 10.5 / 700 / 0.08em (à passer en MAJUSCULES).
  return GoogleFonts.inter(
    color: muted,
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.84,
    height: 1.27,
  );
}

/// Squared icon button used in the Home header (sync / add / settings).
class HomeHeaderIconButton extends StatelessWidget {
  const HomeHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 16,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final bg = isDark
        ? tokens.card
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final border = isDark
        ? tokens.clusterBorder
        : Theme.of(context).colorScheme.outlineVariant;
    final fg = isDark
        ? Colors.white
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              // Cible tactile 44 px minimum.
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: AppIcon.fromMaterial(icon, size: iconSize, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

/// Circular Discord-style bot avatar from the Home bot cards.
///
/// Les octets passent par [ImageDiskCache] (mémoire → disque → réseau) : une
/// icône déjà vue n'est plus retéléchargée via HTTP au démarrage suivant.
/// Le contrat d'affichage reste inchangé — repli pendant le chargement, repli
/// sur erreur, `gaplessPlayback` contre le flash lors d'un changement d'URL.
/// Si le cache disque est indisponible, on retombe sur `Image.network`.
class HomeBotAvatar extends StatelessWidget {
  const HomeBotAvatar({
    super.key,
    required this.imageUrl,
    this.size = 48,
    this.background,
    this.ringColor,
    this.ringWidth = 0,
    this.fallbackIcon = Icons.smart_toy_rounded,
    this.fallbackLabel,
    this.diskCache,
  });

  final String? imageUrl;
  final double size;

  /// Fond du cercle, utilisé aussi pendant le chargement et sur erreur.
  /// Par défaut le bleu Discord (comportement historique).
  final Color? background;

  /// Anneau peint *par-dessus* l'image, pour séparer deux avatars superposés.
  final Color? ringColor;
  final double ringWidth;

  /// Icône de repli quand aucune image n'est disponible.
  final IconData fallbackIcon;

  /// Repli textuel (vraie initiale d'un serveur par exemple) : prioritaire sur
  /// [fallbackIcon] quand il est non vide.
  final String? fallbackLabel;

  /// Cache d'images injectable (tests) ; par défaut [ImageDiskCache.instance].
  final ImageDiskCache? diskCache;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.isNotEmpty ?? false;
    final fallback = _HomeAvatarFallback(
      size: size,
      label: fallbackLabel?.trim() ?? '',
      icon: fallbackIcon,
    );

    final circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background ?? AppTheme.discord,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasImage
          ? _DiskCachedAvatarImage(
              url: imageUrl!,
              size: size,
              fallback: fallback,
              diskCache: diskCache ?? ImageDiskCache.instance,
            )
          : fallback,
    );

    if (ringWidth <= 0 || ringColor == null) return circle;

    // La décoration d'un `Container` est peinte *derrière* son enfant : une
    // bordure y serait recouverte par l'image en `BoxFit.cover`. L'anneau est
    // donc peint dans une couche au-dessus.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: circle),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor!, width: ringWidth),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Repli neutre d'un avatar : initiale réelle si connue, sinon icône.
class _HomeAvatarFallback extends StatelessWidget {
  const _HomeAvatarFallback({
    required this.size,
    required this.label,
    required this.icon,
  });

  final double size;

  /// Initiale (déjà nettoyée) à afficher ; vide → [icon].
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (label.isNotEmpty) {
      return Text(
        label,
        style: GoogleFonts.inter(
          fontSize: size * (14 / 36),
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }
    return AppIcon.fromMaterial(
      icon,
      color: Colors.white,
      size: size * (26 / 48),
    );
  }
}

/// Image d'avatar servie par [ImageDiskCache] (mémoire → disque → réseau).
///
/// Le repli est affiché tant que le provider n'est pas résolu, puis sur erreur
/// de décodage. Sur le chemin réseau, le comportement historique est conservé
/// à l'identique (`loadingBuilder` → repli, `errorBuilder` → repli).
class _DiskCachedAvatarImage extends StatefulWidget {
  const _DiskCachedAvatarImage({
    required this.url,
    required this.size,
    required this.fallback,
    required this.diskCache,
  });

  final String url;
  final double size;
  final Widget fallback;
  final ImageDiskCache diskCache;

  @override
  State<_DiskCachedAvatarImage> createState() => _DiskCachedAvatarImageState();
}

class _DiskCachedAvatarImageState extends State<_DiskCachedAvatarImage> {
  late Future<ImageProvider> _provider;

  @override
  void initState() {
    super.initState();
    _provider = widget.diskCache.providerFor(widget.url);
  }

  @override
  void didUpdateWidget(_DiskCachedAvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.diskCache != widget.diskCache) {
      _provider = widget.diskCache.providerFor(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ImageProvider>(
      future: _provider,
      builder: (context, snapshot) {
        final provider = snapshot.data;
        // Résolution en cours (ou en échec : le cache ne lève jamais) → repli.
        if (provider == null) return widget.fallback;

        if (provider is NetworkImage) {
          return Image.network(
            provider.url,
            fit: BoxFit.cover,
            width: widget.size,
            height: widget.size,
            gaplessPlayback: true,
            loadingBuilder: (context, child, progress) =>
                progress == null ? child : widget.fallback,
            errorBuilder: (_, _, _) => widget.fallback,
          );
        }

        return Image(
          image: provider,
          fit: BoxFit.cover,
          width: widget.size,
          height: widget.size,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => widget.fallback,
        );
      },
    );
  }
}

/// Pastille d'état d'un bot (en ligne / arrêté) : plate, sans halo.
///
/// [pulseController] est conservé pour compatibilité d'appel mais n'anime plus
/// rien : la refonte n'autorise aucun glow.
class HomeStatusPill extends StatelessWidget {
  const HomeStatusPill({
    super.key,
    required this.isRunning,
    required this.pulseController,
  });

  final bool isRunning;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return isRunning
        ? StatusPill.online(label: context.tr.home_status_online)
        : StatusPill.stopped(label: context.tr.container_state_stopped);
  }
}

/// Ghost / accent action button used inside Home bot cards (Start / Manage).
class HomeCardActionButton extends StatelessWidget {
  const HomeCardActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.loading = false,
    this.stopSquare = false,
    this.iconSize = 14,
  });

  static const double height = 44;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accent;
  final bool loading;
  final bool stopSquare;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    // Danger : texte rouge lisible (#FB8A9D), le point/anneau gardent le rouge.
    final Color fg = accent == null
        ? scheme.onSurface
        : (accent == AppTheme.danger ? AppTheme.statusErrorText : accent!);
    final Color tint = accent == AppTheme.danger
        ? AppTheme.statusError
        : (accent ?? Colors.transparent);
    final Color borderColor = accent != null
        ? tint.withValues(alpha: 0.40)
        : (isDark ? tokens.clusterBorder : scheme.outline);
    final Color bg = accent != null
        ? tint.withValues(alpha: 0.08)
        : (isDark ? tokens.card : Colors.white.withValues(alpha: 0.40));
    final bool enabled = onTap != null && !loading;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          // Ink (not Container) so the splash paints above the background.
          child: Ink(
            height: height,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                else if (stopSquare)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: fg,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  )
                else
                  AppIcon.fromMaterial(icon, size: iconSize, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Anti-aliased dashed rounded rect (Home “Create a bot” / destructive rows).
class HomeDashedRoundedRectPainter extends CustomPainter {
  const HomeDashedRoundedRectPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 1.5;
    const dashLength = 5.5;
    const gapLength = 4.0;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        strokeWidth / 2,
        strokeWidth / 2,
        size.width - strokeWidth,
        size.height - strokeWidth,
      ),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.high;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final next = (distance + length).clamp(0.0, metric.length);
        if (draw && next > distance) {
          canvas.drawPath(metric.extractPath(distance, next), paint);
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant HomeDashedRoundedRectPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
