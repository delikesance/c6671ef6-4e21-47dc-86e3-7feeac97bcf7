import 'package:bot_creator/core/i18n/i18n.dart';
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
  final muted = isDark
      ? AppTheme.homeMuted
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
    final bg = isDark
        ? AppTheme.homeCard
        : Theme.of(context).colorScheme.surfaceContainerHigh;
    final border = isDark
        ? AppTheme.homeCardBorder
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

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl?.isNotEmpty ?? false;
    final iconSize = size * (26 / 48);
    final label = fallbackLabel?.trim() ?? '';

    Widget fallback() {
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
      return Icon(fallbackIcon, color: Colors.white, size: iconSize);
    }

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
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return fallback();
              },
              errorBuilder: (_, _, _) => fallback(),
            )
          : fallback(),
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
    final Color fg = accent ?? scheme.onSurface;
    final Color borderColor = accent != null
        ? accent!.withValues(alpha: 0.20)
        : (isDark ? AppTheme.homeGhostBorder : scheme.outline);
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
