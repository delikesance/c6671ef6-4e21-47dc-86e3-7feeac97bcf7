import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../theme/block_family.dart';
import '../widgets/app_icon.dart';
import '../widgets/home_ui.dart';

// Briques visuelles de l'accueil d'un bot (identité, hébergement, commandes,
// workflows, console). Partagées entre l'app et le Studio : même design, un seul
// code. Elles ne connaissent ni l'API ni le stockage : l'hôte leur donne des
// textes, des listes et des callbacks.

/// En dessous de cette largeur, l'en-tête de la console passe en forme compacte
/// (« Afficher tout »).
const double _consoleCompactWidth = 400;

/// Police mono (identifiants, commandes, logs, compteurs).
TextStyle botHomeMono(double size, Color color) => TextStyle(
  fontFamily: 'JetBrainsMono',
  fontSize: size,
  color: color,
  letterSpacing: 0,
);

/// Palette de l'accueil d'un bot. Sombre : surfaces de la refonte (panneau
/// #12141A, surélevé #16181E, fond #0E0F13, action violette). Clair : dérivée du
/// `ColorScheme`, comme le reste de l'interface.
class BotHomePalette {
  const BotHomePalette({
    required this.ground,
    required this.panel,
    required this.panelBorder,
    required this.raised,
    required this.raisedBorder,
    required this.chip,
    required this.text,
    required this.softText,
    required this.muted,
    required this.violet,
    required this.violetSoft,
    required this.onViolet,
    required this.console,
  });

  final Color ground;
  final Color panel;
  final Color panelBorder;
  final Color raised;
  final Color raisedBorder;
  final Color chip;
  final Color text;
  final Color softText;
  final Color muted;
  final Color violet;
  final Color violetSoft;
  final Color onViolet;
  final Color console;

  factory BotHomePalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.dark) {
      final tokens = HomeTokens.of(context);
      return BotHomePalette(
        ground: theme.scaffoldBackgroundColor,
        panel: tokens.clusterBg,
        panelBorder: tokens.cardBorder,
        raised: tokens.card,
        raisedBorder: tokens.clusterBorder,
        chip: const Color(0xFF1F222C),
        text: scheme.onSurface,
        softText: const Color(0xFFC9CDD8),
        muted: tokens.muted,
        violet: AppTheme.actionViolet,
        violetSoft: AppTheme.actionVioletSoft,
        onViolet: Colors.white,
        console: tokens.containerLowest,
      );
    }
    return BotHomePalette(
      ground: theme.scaffoldBackgroundColor,
      panel: scheme.surfaceContainer,
      panelBorder: scheme.outlineVariant,
      raised: scheme.surfaceContainerHigh,
      raisedBorder: scheme.outlineVariant,
      chip: scheme.surfaceContainerHighest,
      text: scheme.onSurface,
      softText: scheme.onSurface,
      muted: scheme.onSurfaceVariant,
      violet: scheme.primary,
      violetSoft: scheme.primary,
      onViolet: scheme.onPrimary,
      console: scheme.surfaceContainerLowest,
    );
  }
}

enum BotHomeButtonVariant { primary, secondary, danger, online, ghost }

/// Bouton plat de l'accueil : 12 px de rayon, 44 px de haut minimum.
class BotHomeButton extends StatelessWidget {
  const BotHomeButton({
    super.key,
    required this.variant,
    required this.label,
    required this.onTap,
    this.icon,
    this.stopSquare = false,
    this.loading = false,
    this.compact = false,
    this.expand = true,
    this.height = 44,
  });

  final BotHomeButtonVariant variant;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool stopSquare;
  final bool loading;

  /// Libellé 13 px / 600 (rangée secondaire mobile).
  final bool compact;

  /// `false` : le bouton prend la largeur de son contenu.
  final bool expand;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    final (Color bg, Color border, Color fg) = switch (variant) {
      BotHomeButtonVariant.primary => (
        p.violet,
        Colors.transparent,
        p.onViolet,
      ),
      BotHomeButtonVariant.secondary => (p.raised, p.raisedBorder, p.text),
      BotHomeButtonVariant.danger => (
        AppTheme.statusError.withValues(alpha: 0.08),
        AppTheme.statusError.withValues(alpha: 0.4),
        AppTheme.statusErrorText,
      ),
      BotHomeButtonVariant.online => (
        AppTheme.statusOnline.withValues(alpha: 0.08),
        AppTheme.statusOnline.withValues(alpha: 0.4),
        AppTheme.statusOnline,
      ),
      BotHomeButtonVariant.ghost => (
        Colors.transparent,
        Colors.transparent,
        p.softText,
      ),
    };
    final enabled = onTap != null && !loading;
    final textColor = compact && variant == BotHomeButtonVariant.secondary
        ? p.softText
        : fg;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
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
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: fg,
              borderRadius: BorderRadius.circular(2.5),
            ),
          )
        else if (icon != null)
          AppIcon.fromMaterial(icon!, size: compact ? 16 : 18, color: fg),
        if (loading || stopSquare || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13 : 14,
              fontWeight: compact ? FontWeight.w600 : FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    );

    return Opacity(
      opacity: (onTap == null && !loading) ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Ink(
            height: height,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 18),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Lien discret (44 px de haut) : « Voir les 8 », « Afficher tout ».
class BotHomeLinkButton extends StatelessWidget {
  const BotHomeLinkButton({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.trailingIcon,
    this.tooltip,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    final link = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leadingIcon != null) ...[
                  AppIcon.fromMaterial(
                    leadingIcon!,
                    size: 18,
                    color: p.softText,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: p.softText,
                    ),
                  ),
                ),
                if (trailingIcon != null) ...[
                  const SizedBox(width: 4),
                  AppIcon.fromMaterial(
                    trailingIcon!,
                    size: 16,
                    color: p.softText,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    return tooltip == null ? link : Tooltip(message: tooltip!, child: link);
  }
}

/// Carte plate (rayon 20, panneau #12141A) avec en-tête titre + action.
class BotHomePanel extends StatelessWidget {
  const BotHomePanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.footer,
    this.wide = false,
    this.emphasize = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? footer;
  final bool wide;

  /// Bordure d'alerte (réserve d'hébergement critique).
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    return Container(
      padding: wide
          ? const EdgeInsets.all(24)
          : const EdgeInsets.fromLTRB(18, 18, 18, 10),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: emphasize
              ? AppTheme.statusError.withValues(alpha: 0.6)
              : p.panelBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 44),
            margin: const EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: wide ? 17 : 15,
                    height: 24 / 17,
                    fontWeight: wide ? FontWeight.w800 : FontWeight.w700,
                    color: p.text,
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
          child,
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );
  }
}

/// Rangée surélevée (commande / workflow) : pastille, contenu, chevron.
class BotHomeRow extends StatelessWidget {
  const BotHomeRow({
    super.key,
    required this.leading,
    required this.child,
    this.onTap,
  });

  final Widget leading;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    return Material(
      color: p.raised,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 60),
          padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.raisedBorder),
          ),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Expanded(child: child),
              SizedBox(
                width: 28,
                child: Center(
                  child: AppIcon.fromMaterial(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: p.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip neutre (« 3 actions », « Équipe »).
class BotHomeChip extends StatelessWidget {
  const BotHomeChip({super.key, required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    final height = large ? 26.0 : 22.0;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: large ? 10 : 8),
      decoration: BoxDecoration(
        color: p.chip,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB4B9C6),
            ),
          ),
        ],
      ),
    );
  }
}

class BotHomeEmptyHint extends StatelessWidget {
  const BotHomeEmptyHint({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: TextStyle(fontSize: 13.5, color: p.muted)),
    );
  }
}

/// Temps restant en cellules (mois, jours, heures, minutes…).
class BotHomeCountdown extends StatelessWidget {
  const BotHomeCountdown({
    super.key,
    required this.segments,
    required this.wide,
  });

  final List<({String value, String label})> segments;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: wide ? 14 : 12),
      decoration: BoxDecoration(
        color: wide ? p.raised : p.ground,
        borderRadius: BorderRadius.circular(wide ? 16 : 14),
        border: Border.all(color: wide ? p.raisedBorder : p.panelBorder),
      ),
      child: Row(
        children: [
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0)
              Container(
                width: 1,
                height: 40,
                color: wide ? p.raisedBorder : p.panelBorder,
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    segments[i].value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: wide
                        ? TextStyle(
                            fontSize: 26,
                            height: 30 / 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.26,
                            color: p.text,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          )
                        : botHomeMono(22, p.text).copyWith(
                            height: 26 / 22,
                            fontWeight: FontWeight.w500,
                          ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    segments[i].label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.84,
                      color: p.muted,
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

/// [BotHomeCountdown] qui s'écoule à la seconde jusqu'à [deadline] : mois (30 j),
/// jours, heures, minutes, secondes. Passé l'échéance : [expiredLabel].
class BotHomeLiveCountdown extends StatefulWidget {
  const BotHomeLiveCountdown({
    super.key,
    required this.deadline,
    required this.expiredLabel,
    required this.wide,
    this.now,
  });

  final DateTime deadline;
  final String expiredLabel;
  final bool wide;

  /// Horloge injectable (tests) ; par défaut `DateTime.now`.
  final DateTime Function()? now;

  @override
  State<BotHomeLiveCountdown> createState() => _BotHomeLiveCountdownState();
}

class _BotHomeLiveCountdownState extends State<BotHomeLiveCountdown> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference((widget.now ?? DateTime.now)());
    final p = BotHomePalette.of(context);
    if (left.isNegative) {
      return Text(
        widget.expiredLabel,
        style: TextStyle(
          fontSize: 20,
          height: 26 / 20,
          fontWeight: FontWeight.w800,
          color: p.text,
        ),
      );
    }
    final tr = context.tr;
    String two(int v) => v.toString().padLeft(2, '0');
    final days = left.inDays;
    return BotHomeCountdown(
      wide: widget.wide,
      segments: [
        (value: two(days ~/ 30), label: tr.unit_short_month),
        (value: two(days % 30), label: tr.unit_short_day),
        (value: two(left.inHours % 24), label: tr.unit_short_hour),
        (value: two(left.inMinutes % 60), label: tr.unit_short_minute),
        (value: two(left.inSeconds % 60), label: tr.unit_short_second),
      ],
    );
  }
}

/// Grille de cartes : colonnes de 320 px minimum, 20 px d'écart, cartes d'une
/// même rangée étirées à la même hauteur.
class BotHomeCardGrid extends StatelessWidget {
  const BotHomeCardGrid({super.key, required this.children});

  final List<Widget> children;

  static const double _minColumn = 320;
  static const double _gap = 20;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = ((width + _gap) / (_minColumn + _gap)).floor().clamp(
          1,
          children.length,
        );
        final rows = <Widget>[];
        for (var start = 0; start < children.length; start += columns) {
          final slice = children.skip(start).take(columns).toList();
          if (rows.isNotEmpty) rows.add(const SizedBox(height: _gap));
          rows.add(
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < columns; i++) ...[
                    if (i > 0) const SizedBox(width: _gap),
                    Expanded(
                      child: i < slice.length ? slice[i] : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

/// Monogramme du bot : initiales dans une pastille (carré arrondi), ou son
/// avatar Discord quand l'URL est connue.
class BotHomeMonogram extends StatelessWidget {
  const BotHomeMonogram({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.radius,
  });

  final String name;
  final String imageUrl;
  final double size;
  final double radius;

  String get _initials {
    final words = name
        .trim()
        .split(RegExp(r'[\s\-_]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final raw = words.length > 1
        ? '${String.fromCharCode(words[0].runes.first)}${String.fromCharCode(words[1].runes.first)}'
        : String.fromCharCodes(words[0].runes.take(2));
    return raw.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isNotEmpty) {
      return HomeBotAvatar(
        imageUrl: imageUrl,
        size: size,
        fallbackLabel: _initials,
      );
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BlockFamily.http.pastilleDecoration(radius: radius),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w800,
          color: BlockFamily.http.color,
        ),
      ),
    );
  }
}

/// Filtre de niveau de la console (sur le texte des lignes de log).
enum BotHomeLogLevel { all, info, error }

/// Carte « Logs du bot » : en-tête (titre + filtre + action) et console.
///
/// Reçoit des lignes DÉJÀ rassemblées (l'hôte fusionne ce qu'il lit et ce qu'il
/// reçoit en direct) : la carte ne sait pas d'où elles viennent. Avec
/// [showLevelFilter] (desktop), un sélecteur Tout / Infos / Erreurs filtre les
/// lignes d'après leur niveau (`[INFO]`, `[ERROR]`, `[SEVERE]`…).
class BotHomeConsolePanel extends StatefulWidget {
  const BotHomeConsolePanel({
    super.key,
    required this.lines,
    required this.onOpenLogs,
    required this.emptyHint,
    this.fillHeight = false,
    this.showLevelFilter = false,
    this.compactLineCount = 3,
  });

  final List<String> lines;
  final VoidCallback onOpenLogs;

  /// Sous-titre de l'état vide : il doit dire la VÉRITÉ (rien reçu, lecture
  /// échouée, bot arrêté…). Fourni par l'hôte, qui connaît la situation.
  final String emptyHint;

  /// `true` : la console s'étire sur la hauteur fournie par le parent (qui doit
  /// être bornée). `false` : hauteur bornée selon [compactLineCount].
  final bool fillHeight;

  /// Affiche le sélecteur de niveau (Tout / Infos / Erreurs).
  final bool showLevelFilter;

  /// Nombre de lignes affichées quand la console a une hauteur bornée.
  final int compactLineCount;

  /// Plafond du nombre de lignes rendues quand la console s'étire.
  static const int maxVisibleLines = 200;

  @override
  State<BotHomeConsolePanel> createState() => _BotHomeConsolePanelState();
}

class _BotHomeConsolePanelState extends State<BotHomeConsolePanel> {
  BotHomeLogLevel _filter = BotHomeLogLevel.all;

  bool _matchesFilter(String line) {
    switch (_filter) {
      case BotHomeLogLevel.all:
        return true;
      case BotHomeLogLevel.info:
        return line.toUpperCase().contains('[INFO]');
      case BotHomeLogLevel.error:
        final upper = line.toUpperCase();
        return upper.contains('[ERROR]') ||
            upper.contains('[SEVERE]') ||
            upper.contains('[FATAL]');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    final fillHeight = widget.fillHeight;
    final wideStyle = widget.showLevelFilter;
    final allLogs = widget.lines;
    final logs = allLogs.where(_matchesFilter).toList(growable: false);

    Widget body;
    if (logs.isEmpty) {
      body = _buildEmpty(context, p, filtered: allLogs.isNotEmpty);
    } else {
      final visibleCount = fillHeight
          ? BotHomeConsolePanel.maxVisibleLines
          : widget.compactLineCount;
      final recent = logs.length > visibleCount
          ? logs.sublist(logs.length - visibleCount)
          : logs;
      final lines = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final line in recent)
            BotHomeLogLine(line: line, wide: wideStyle, palette: p),
        ],
      );
      // Console étirée : les dernières lignes restent collées en bas et
      // l'historique défile au lieu de déborder.
      body = fillHeight
          ? SingleChildScrollView(primary: false, reverse: true, child: lines)
          : lines;
    }

    final console = Container(
      decoration: BoxDecoration(
        color: wideStyle ? p.console : p.ground,
        borderRadius: BorderRadius.circular(wideStyle ? 14 : 12),
        border: Border.all(color: p.panelBorder),
      ),
      padding: fillHeight
          ? const EdgeInsets.all(12)
          : EdgeInsets.symmetric(
              horizontal: wideStyle ? 16 : 12,
              vertical: wideStyle ? 14 : 10,
            ),
      constraints: fillHeight
          ? null
          : BoxConstraints(minHeight: wideStyle ? 150 : 0),
      child: body,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
      decoration: BoxDecoration(
        color: p.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _buildHeader(context, p),
          const SizedBox(height: 6),
          if (fillHeight)
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onOpenLogs,
                child: console,
              ),
            )
          else
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: widget.onOpenLogs,
              child: console,
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    BotHomePalette p, {
    required bool filtered,
  }) {
    final title = context.tr.bot_logs_empty;
    if (widget.fillHeight) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.raised,
                  border: Border.all(color: p.raisedBorder),
                ),
                child: AppIcon.fromMaterial(
                  Icons.terminal_rounded,
                  size: 22,
                  color: p.muted,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: botHomeMono(13, p.softText),
              ),
              if (!filtered) ...[
                const SizedBox(height: 6),
                Text(
                  widget.emptyHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: p.muted),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon.fromMaterial(Icons.code_rounded, size: 16, color: p.muted),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: botHomeMono(12, p.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, BotHomePalette p) {
    // L'en-tête s'adapte à la largeur réellement disponible : sous
    // [_consoleCompactWidth], l'action devient « Afficher tout ».
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < _consoleCompactWidth;
        final inlineFilter =
            widget.showLevelFilter && constraints.maxWidth >= 600;
        final filter = widget.showLevelFilter ? _buildFilter(context, p) : null;
        final action = compact
            ? BotHomeLinkButton(
                label: context.tr.bot_logs_show_all,
                trailingIcon: Icons.arrow_forward_rounded,
                tooltip: context.tr.bot_home_view_logs,
                onTap: widget.onOpenLogs,
              )
            : BotHomeLinkButton(
                label: context.tr.bot_home_view_logs,
                leadingIcon: Icons.terminal_rounded,
                onTap: widget.onOpenLogs,
              );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.terminal_rounded,
                  size: 18,
                  color: p.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.tr.bot_logs_title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: widget.showLevelFilter ? 17 : 15,
                      height: 24 / 17,
                      fontWeight: widget.showLevelFilter
                          ? FontWeight.w800
                          : FontWeight.w700,
                      color: p.text,
                    ),
                  ),
                ),
                if (inlineFilter) ...[filter!, const SizedBox(width: 12)],
                Flexible(flex: 0, child: action),
              ],
            ),
            if (filter != null && !inlineFilter)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 4),
                child: Align(alignment: Alignment.centerLeft, child: filter),
              ),
          ],
        );
      },
    );
  }

  /// Sélecteur segmenté Tout / Infos / Erreurs.
  Widget _buildFilter(BuildContext context, BotHomePalette p) {
    final entries = <(BotHomeLogLevel, String)>[
      (BotHomeLogLevel.all, context.tr.common_all),
      (BotHomeLogLevel.info, context.tr.bot_home_logs_filter_info),
      (BotHomeLogLevel.error, context.tr.bot_home_logs_filter_errors),
    ];
    return Semantics(
      container: true,
      label: context.tr.bot_home_logs_filter_label,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: p.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.raisedBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (value, label) in entries)
              Padding(
                padding: EdgeInsets.only(
                  left: value == BotHomeLogLevel.all ? 0 : 4,
                ),
                child: Semantics(
                  button: true,
                  selected: _filter == value,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(9),
                    onTap: () => setState(() => _filter = value),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 36),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _filter == value
                            ? const Color(0xFF262A38)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: _filter == value
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _filter == value ? p.text : p.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Une ligne de console en police mono : l'horodatage ISO initial est atténué.
class BotHomeLogLine extends StatelessWidget {
  const BotHomeLogLine({
    super.key,
    required this.line,
    required this.wide,
    required this.palette,
  });

  final String line;
  final bool wide;
  final BotHomePalette palette;

  static final RegExp _timestamp = RegExp(
    r'^(\[\d{4}-\d{2}-\d{2}T[^\]]*\])(.*)$',
  );

  @override
  Widget build(BuildContext context) {
    final size = wide ? 12.5 : 11.5;
    final base = botHomeMono(
      size,
      palette.softText,
    ).copyWith(height: (wide ? 22 : 18) / size);
    final match = _timestamp.firstMatch(line);
    final span = match == null
        ? TextSpan(text: line, style: base)
        : TextSpan(
            style: base,
            children: [
              TextSpan(
                text: match.group(1),
                style: base.copyWith(color: palette.muted),
              ),
              TextSpan(text: match.group(2)),
            ],
          );
    return Text.rich(span, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}

/// En-tête d'identité PLAT (sans carte) : monogramme, nom, pastille d'état, ID
/// mono avec copie et source d'exécution ; les actions à droite sur desktop,
/// dessous sur téléphone.
class BotHomeIdentityHeader extends StatelessWidget {
  const BotHomeIdentityHeader({
    super.key,
    required this.name,
    required this.botId,
    required this.statusPill,
    required this.actions,
    required this.wide,
    this.imageUrl,
    this.sourceLabel,
    this.onCopyId,
  });

  final String name;
  final String botId;
  final String? imageUrl;
  final Widget statusPill;

  /// Qui exécute le bot (« Serveurs Bot Creator »), quand on le sait.
  final String? sourceLabel;
  final VoidCallback? onCopyId;

  /// Boutons d'action (Inviter, Redémarrer, Arrêter). Chaque bouton arrive avec
  /// la largeur que l'hôte lui veut.
  final List<Widget> actions;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = BotHomePalette.of(context);
    final idRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'ID $botId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: botHomeMono(wide ? 13 : 12.5, p.muted),
          ),
        ),
        if (onCopyId != null)
          Tooltip(
            message: MaterialLocalizations.of(context).copyButtonLabel,
            child: SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onCopyId,
                child: Center(
                  child: AppIcon.fromMaterial(
                    Icons.copy_rounded,
                    size: 16,
                    color: p.muted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    if (wide) {
      return Wrap(
        spacing: 24,
        runSpacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 320, maxWidth: 640),
            child: Row(
              children: [
                BotHomeMonogram(
                  name: name,
                  imageUrl: imageUrl ?? '',
                  size: 52,
                  radius: 16,
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 24,
                              height: 30 / 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.24,
                              color: p.text,
                            ),
                          ),
                          statusPill,
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(child: idRow),
                          if (sourceLabel != null) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                sourceLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(spacing: 10, runSpacing: 10, children: actions),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BotHomeMonogram(
              name: name,
              imageUrl: imageUrl ?? '',
              size: 56,
              radius: 18,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      height: 26 / 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: p.text,
                    ),
                  ),
                  SizedBox(height: 32, child: idRow),
                ],
              ),
            ),
            const SizedBox(width: 12),
            statusPill,
          ],
        ),
        const SizedBox(height: 18),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }
}
