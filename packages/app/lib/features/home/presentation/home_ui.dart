import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/image_disk_cache.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  return GoogleFonts.spaceGrotesk(
    color: muted,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
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
        ? tokens.cardBorder
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
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: iconSize, color: fg),
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
    return Icon(icon, color: Colors.white, size: size * (26 / 48));
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

/// Online / Offline status pill from the Home bot cards.
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
    final Color color = isRunning ? AppTheme.online : AppTheme.danger;
    final label = isRunning
        ? context.tr.home_status_online
        : context.tr.home_status_offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isRunning ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: color.withValues(alpha: isRunning ? 0.30 : 0.20),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, _) {
              final glow = isRunning ? 0.4 + 0.6 * pulseController.value : 0.0;
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: AppTheme.online.withValues(
                              alpha: 0.8 * glow,
                            ),
                            blurRadius: 7,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
    final Color fg = accent ?? scheme.onSurface;
    final Color borderColor = accent != null
        ? accent!.withValues(alpha: 0.20)
        : (isDark ? tokens.ghostBorder : scheme.outline);
    final Color bg = accent != null
        ? accent!.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: isDark ? 0.02 : 0.40);
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
                  Icon(icon, size: iconSize, color: fg),
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
/// Reprend la grammaire visuelle des cartes de la page « Emojis applicatifs »
/// (visuel centré, libellé, deux actions en icônes) pour afficher le temps
/// restant total en « mois, jours, heures, minutes ».
class HomeHostingTimeCard extends StatelessWidget {
  const HomeHostingTimeCard({
    super.key,
    required this.width,
    required this.totalLabel,
    required this.statusLabel,
    required this.isRunning,
    required this.onAddTime,
    required this.onHistory,
    this.detailLabel,
    this.timeColor,
    this.borderColor,
    this.isAddingTime = false,
  });

  /// Largeur de la carte. La hauteur suit le contenu — pas de ratio figé,
  /// pour qu'un libellé long (« 2 mois, 3 jours, 15 heures, 40 minutes ») ne
  /// déborde jamais.
  final double width;

  /// Temps restant total, déjà formaté (ex. « 2 mois, 3 jours, 15 minutes »).
  final String totalLabel;

  /// « Session active (en ligne) » / « Réserve disponible (en pause) ».
  final String statusLabel;

  /// Ligne secondaire : expiration de la session, ou rappel que le temps est
  /// préservé tant que le bot est arrêté.
  final String? detailLabel;

  /// Vrai quand le bot tourne : teinte le visuel et le statut.
  final bool isRunning;

  /// Couleur de la valeur (santé de la réserve) ; par défaut la couleur d'état.
  final Color? timeColor;

  /// Bordure d'alerte (réserve critique) ; par défaut la bordure de carte.
  final Color? borderColor;

  final bool isAddingTime;
  final VoidCallback? onAddTime;
  final VoidCallback onHistory;

  static const double _visualSize = 76;
  static const double _actionSize = 36;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;
    final stateColor = isRunning ? AppTheme.online : AppTheme.warning;
    final accent = timeColor ?? stateColor;

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? tokens.card : scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color:
                borderColor ??
                (isDark ? tokens.cardBorder : scheme.outlineVariant),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: _visualSize,
              child: Center(
                child: Container(
                  width: _visualSize - 8,
                  height: _visualSize - 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    border: Border.all(color: accent.withValues(alpha: 0.30)),
                  ),
                  child: Icon(Icons.schedule_rounded, size: 30, color: accent),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
              ),
              child: Text(
                totalLabel,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              statusLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: stateColor,
              ),
            ),
            if (detailLabel != null) ...[
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                ),
                child: Text(
                  detailLabel!,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: muted),
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXs),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: isAddingTime
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : const Icon(Icons.add_rounded, size: 18),
                  tooltip: context.tr.home_add_time,
                  onPressed: isAddingTime ? null : onAddTime,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: _actionSize,
                    minHeight: _actionSize,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history_rounded, size: 18),
                  tooltip: context.tr.home_hosting_ad_history,
                  onPressed: onHistory,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: _actionSize,
                    minHeight: _actionSize,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXs),
          ],
        ),
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
