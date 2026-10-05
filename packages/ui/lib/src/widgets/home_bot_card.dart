import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import 'app_icon.dart';
import 'duration_formatter.dart';
import 'home_ui.dart';

/// Carte d'accueil d'un bot classique (repliable) : avatar, serveurs, état et
/// actions (démarrer/arrêter, gérer, logs).
///
/// Publique — et non privée — pour que le test de la liste d'accueil monte la
/// vraie carte d'un bot classique À CÔTÉ de celle d'un conteneur clé en main
/// ([buildHomeProjectCards]), c'est-à-dire la composition réellement rendue.
class HomeBotCard extends StatefulWidget {
  const HomeBotCard({
    super.key,
    required this.name,
    required this.id,
    required this.avatar,
    required this.guildCount,
    required this.isRunning,
    required this.canToggle,
    required this.isTogglingThisBot,
    required this.initiallyExpanded,
    this.pulseController,
    required this.onManage,
    required this.onToggle,
    required this.onAddTime,
    required this.onLogs,
    required this.showPremiumLabels,
    required this.freeMinutes,
    this.onTeam,
    this.runtimeBadgeLabel,
    this.showsHostingExpiration = true,
    this.isTurnkey = false,
    this.showTeamBadge = false,
    this.ownerLabel,
    this.hasLocalToken = true,
    this.onTokenImported,
    this.isSubscribed = false,
    this.supportsHostingTime = false,
    this.serverAvatars,
    this.showServers = true,
    this.hostingOverride,
  });

  /// Montrer la ligne « actif sur N serveurs » (faux quand l'hôte ne connaît
  /// pas les serveurs du bot).
  final bool showServers;

  /// Boîte d'hébergement calculée par l'hôte (remplace la règle de l'app) ;
  /// `null` : règle par défaut.
  final ({String overline, String value, String? detail})? hostingOverride;

  /// Le compte est abonné (l'hôte lit son service d'abonnement).
  final bool isSubscribed;

  /// La plateforme peut héberger la tâche de fond : seul cas où « ajouter du
  /// temps » a un sens (mobile).
  final bool supportsHostingTime;

  /// Pastilles des serveurs du bot (l'app y met ses avatars réels) ; absent :
  /// la ligne n'affiche que le texte.
  final Widget? serverAvatars;

  final String name;
  final String id;
  final String? avatar;
  final int guildCount;
  final bool isRunning;
  final bool canToggle;
  final bool isTogglingThisBot;
  final bool initiallyExpanded;
  final String? runtimeBadgeLabel;
  final int freeMinutes;

  /// Faut-il afficher la ligne d'expiration / de réserve d'hébergement ?
  ///
  /// Vrai par défaut (affichage historique, notamment mobile). Un écran d'un
  /// poste de travail le passe à `false` dès que la source d'exécution n'est pas
  /// les serveurs Bot Creator : un bot qui tourne ICI ne consomme pas le solde
  /// cloud, donc afficher « Expire le … » serait un mensonge — c'est exactement
  /// le défaut signalé par le propriétaire (échéance en 2038 sur un bot local).
  final bool showsHostingExpiration;

  final AnimationController? pulseController;
  final bool showPremiumLabels;
  final bool isTurnkey;

  /// Badge « équipe » : vrai sur une carte PARTAGÉE (le bot ne m'appartient pas).
  /// Faux par défaut, donc une carte à moi ne change pas d'un pixel.
  final bool showTeamBadge;

  /// Propriétaire du bot, quand la carte doit le nommer (bot partagé). `null`
  /// quand le serveur ne l'a pas annoncé : la ligne entière disparaît plutôt que
  /// d'afficher un libellé inventé.
  final String? ownerLabel;

  final VoidCallback? onManage;

  /// Ouvre le tchat d'équipe du bot. Renseigné sur une carte PARTAGÉE
  /// uniquement : le collaborateur garde ainsi un chemin vers son équipe même
  /// sans droit d'édition. `null` sur une carte « à moi », qui garde donc
  /// exactement ses actions d'avant.
  final VoidCallback? onTeam;

  final VoidCallback onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onLogs;

  /// Faux quand ce poste n'a AUCUN jeton utilisable pour ce bot : c'est la
  /// seule situation où « Importer le jeton depuis mon compte » a quelque
  /// chose à faire, donc la seule où le bouton est offert.
  final bool hasLocalToken;

  /// Relais après un import RÉUSSI depuis la carte (l'accueil se recharge).
  final Future<void> Function()? onTokenImported;

  @override
  State<HomeBotCard> createState() => HomeBotCardState();
}

class HomeBotCardState extends State<HomeBotCard> {
  bool _hovered = false;
  late bool _expanded = widget.initiallyExpanded;
  bool get _supportsForegroundTask => widget.supportsHostingTime;

  @override
  void didUpdateWidget(covariant HomeBotCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Realign on the layout-driven default when the window width changes
    // (desktop resize / rotation).
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String _startLabel(BuildContext context) {
    if (widget.isRunning) return context.tr.home_stop;
    if (!widget.showPremiumLabels) return context.tr.bot_home_start;
    if (widget.isSubscribed) return context.tr.home_start_premium;
    if (widget.freeMinutes > 0) return context.tr.bot_home_start;
    return context.tr.home_start_ads;
  }

  String _serverCountLabel(BuildContext context) {
    final count = widget.guildCount;
    return count == 1
        ? context.tr.home_active_on_servers_one(count)
        : context.tr.home_active_on_servers_other(count);
  }

  /// Ajouter du temps n'a de sens que pour un bot réellement en marche, et
  /// seulement sur les plateformes capables d'héberger la tâche de fond. Un
  /// poste de travail n'a aucun concept d'hébergement : l'action n'y est jamais
  /// proposée.
  bool get _showAddHosting {
    if (!widget.isRunning) return false;
    if (!_supportsForegroundTask) return false;
    return !widget.isSubscribed;
  }

  /// Boîte d'hébergement (surtitre, valeur, précision) ou `null` quand elle n'a
  /// pas lieu d'être.
  ///
  /// On montre le TEMPS RESTANT, jamais une date calculée : `maintenant + solde`
  /// donnait des échéances fantaisistes (année 2038 pour un solde illimité). Une
  /// date d'expiration ne s'affiche que si le serveur en fournit une.
  ({String overline, String value, String? detail})? _hostingBox(
    BuildContext context,
  ) {
    if (!widget.showsHostingExpiration) return null;
    // Abonné : la puce « illimité » dit déjà tout, un solde n'a plus de sens.
    if (widget.showPremiumLabels && widget.isSubscribed) {
      return null;
    }
    final tr = context.tr;
    if (widget.isRunning) {
      return (
        overline: tr.home_hosting_remaining_overline,
        value: widget.freeMinutes <= 0
            ? tr.home_hosting_expired
            : formatHostingDuration(context, widget.freeMinutes),
        detail: tr.home_hosting_status_active,
      );
    }
    return (
      overline: tr.home_hosting_time_preserved_overline,
      value: widget.freeMinutes <= 0
          ? tr.home_hosting_status_paused
          : tr.home_hosting_banked(
              formatHostingDuration(context, widget.freeMinutes),
            ),
      detail: tr.home_hosting_time_preserved,
    );
  }

  /// Menu « Plus d'actions » : ce qui n'a pas sa place dans la rangée principale.
  List<PopupMenuEntry<String>> _overflowEntries(
    BuildContext context, {
    required bool teamInMenu,
  }) {
    final tr = context.tr;
    return [
      if (_showAddHosting)
        PopupMenuItem<String>(
          value: 'add_time',
          enabled: widget.canToggle && widget.onAddTime != null,
          child: Text(tr.home_add_time),
        ),
      if (widget.onLogs != null)
        PopupMenuItem<String>(value: 'logs', child: Text(tr.home_logs_tooltip)),
      if (teamInMenu)
        PopupMenuItem<String>(value: 'team', child: Text(tr.team_tab)),
    ];
  }

  Widget _buildExpandedContent(BuildContext context, ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    // La source vivante (« Ce poste », « Serveurs Bot Creator ») porte l'état ;
    // sans source, on retombe sur l'ancien libellé mobile.
    final badge =
        widget.runtimeBadgeLabel ??
        (widget.isRunning ? context.tr.home_synced_active : null);
    final hosting = widget.hostingOverride ?? _hostingBox(context);
    // Le chemin vers l'équipe reste un bouton tant que « Gérer » est absent ;
    // sinon il rejoint le menu pour ne pas écraser la rangée d'actions.
    final teamInMenu = widget.onTeam != null && widget.onManage != null;
    final overflow = _overflowEntries(context, teamInMenu: teamInMenu);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Divider(
          height: 1,
          thickness: 1,
          color: isDark ? tokens.cardBorder : scheme.outlineVariant,
        ),
        const SizedBox(height: 16),
        if (widget.showServers)
          HomeServerPresenceRow(
            title: _serverCountLabel(context),
            statusLabel: badge,
            avatars: widget.serverAvatars,
          ),
        if (hosting != null) ...[
          if (widget.showServers) const SizedBox(height: 12),
          HomeHostingBox(
            overline: hosting.overline,
            value: hosting.value,
            detail: hosting.detail,
          ),
        ],
        if (widget.showPremiumLabels && widget.isSubscribed) ...[
          const SizedBox(height: 10),
          HomeInfoChip(
            icon: Icons.all_inclusive_rounded,
            value: context.tr.hosted_app_subscription_benefit_unlimited,
            badge: true,
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: HomeCardActionButton(
                icon: widget.isRunning
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                label: _startLabel(context),
                onTap: widget.canToggle ? widget.onToggle : null,
                loading: widget.isTogglingThisBot,
                accent: widget.isRunning ? AppTheme.danger : null,
                stopSquare: widget.isRunning,
              ),
            ),
            if (widget.onManage != null) ...[
              const SizedBox(width: 10),
              Expanded(
                child: HomeCardActionButton(
                  icon: Icons.tune_rounded,
                  iconSize: 14,
                  label: context.tr.home_manage,
                  onTap: widget.onManage,
                ),
              ),
            ],
            // Chemin vers l'équipe : offert même sans droit d'édition, c'est
            // l'usage principal d'un collaborateur. MÊME libellé que l'onglet du
            // même nom dans l'éditeur du bot.
            if (widget.onTeam != null && !teamInMenu) ...[
              const SizedBox(width: 10),
              Expanded(
                child: HomeCardActionButton(
                  icon: Icons.groups_outlined,
                  iconSize: 14,
                  label: context.tr.team_tab,
                  onTap: widget.onTeam,
                ),
              ),
            ],
            if (overflow.isNotEmpty) ...[
              const SizedBox(width: 10),
              HomeOverflowMenuButton(
                tooltip: context.tr.home_more_actions,
                entries: overflow,
                onSelected: (value) {
                  switch (value) {
                    case 'add_time':
                      widget.onAddTime?.call();
                    case 'logs':
                      widget.onLogs?.call();
                    case 'team':
                      widget.onTeam?.call();
                  }
                },
              ),
            ],
          ],
        ),
        // La reprise du jeton est devenue AUTOMATIQUE (synchro + démarrage sur ce poste) :
        // offrir un bouton « Importer le jeton depuis mon compte » obligeait l'utilisateur
        // à comprendre un détail d'implémentation pour que son bot démarre. Il ne reste
        // donc aucun geste à faire ici, pas même quand ce poste n'a aucun jeton.
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    // Carte = surface « panneau » ; les blocs internes (serveurs, hébergement)
    // sont en « raised » : surfaces PLATES, le survol ne change que la bordure.
    final cardColor = isDark ? tokens.clusterBg : scheme.surfaceContainer;
    final borderColor = isDark
        ? (_hovered ? tokens.clusterBorder : tokens.cardBorder)
        : scheme.outlineVariant;
    // Desktop : la carte est toujours dépliée (pas de chevron).
    final wide = MediaQuery.sizeOf(context).width >= AppTheme.desktopBreakpoint;
    // Mobile, carte repliée d'un bot arrêté : « Démarrer » reste à portée.
    final showInlineStart = !wide && !_expanded && !widget.isRunning;

    return MouseRegion(
      cursor: wide ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: wide ? null : _toggleExpanded,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: EdgeInsets.all(wide ? 20 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HomeBotAvatar(imageUrl: widget.avatar, size: 44),
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
                                    widget.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: homeDisplayStyle(
                                      wide ? 18 : 15.5,
                                      weight: FontWeight.w700,
                                      color: scheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (widget.isTurnkey) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.primary.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: scheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      context.tr.home_badge_turnkey,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: scheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                                if (widget.showTeamBadge) ...[
                                  const SizedBox(width: 8),
                                  const HomeSharedBotBadge(),
                                ],
                              ],
                            ),
                            if (!wide) ...[
                              const SizedBox(height: 6),
                              HomeStatusPill(
                                isRunning: widget.isRunning,
                                pulseController: widget.pulseController,
                              ),
                            ],
                            if (widget.ownerLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.ownerLabel!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? tokens.muted
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (wide)
                        HomeStatusPill(
                          isRunning: widget.isRunning,
                          pulseController: widget.pulseController,
                        ),
                      if (showInlineStart) ...[
                        SizedBox(
                          width: 104,
                          child: HomeCardActionButton(
                            icon: Icons.play_arrow_rounded,
                            label: _startLabel(context),
                            onTap: widget.canToggle ? widget.onToggle : null,
                            loading: widget.isTogglingThisBot,
                          ),
                        ),
                      ],
                      if (!wide)
                        // Cible tactile 44 px ; l'état de dépliage est annoncé.
                        Semantics(
                          button: true,
                          expanded: _expanded,
                          label: widget.name,
                          excludeSemantics: true,
                          onTap: _toggleExpanded,
                          // Toute la carte est cliquable : le chevron n'a besoin que
                          // de 36 px de large, la hauteur reste à 44.
                          child: SizedBox(
                            width: 36,
                            height: 44,
                            child: Center(
                              child: AppIcon.fromMaterial(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: isDark
                                    ? tokens.muted
                                    : scheme.onSurfaceVariant,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: _buildExpandedContent(context, scheme),
                    crossFadeState: _expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                    sizeCurve: Curves.easeInOut,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge « équipe » d'une carte PARTAGÉE : ce bot appartient à quelqu'un d'autre.
///
/// Libellé pris dans l'i18n (`team_tab_short`) plutôt qu'écrit en dur : une UI
/// française n'affiche pas un mot anglais figé.
class HomeSharedBotBadge extends StatelessWidget {
  const HomeSharedBotBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.discord.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.discord.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppIcon.fromMaterial(
            Icons.groups,
            size: 11,
            color: AppTheme.discord,
          ),
          const SizedBox(width: 4),
          Text(
            context.tr.team_tab_short,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.discord,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeInfoChip extends StatelessWidget {
  const HomeInfoChip({
    super.key,
    required this.icon,
    required this.value,
    this.badge = false,
  });

  final IconData icon;
  final String value;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badge
            ? tokens.dataAccent.withValues(alpha: 0.12)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: badge
              ? tokens.dataAccent.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon.fromMaterial(
            icon,
            size: 13,
            color: badge ? tokens.dataAccent : tokens.muted,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: RichText(
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: tokens.dataAccent,
                ),
                text: value,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state avec CTA support ──────────────────────────────────────────

/// Boîte d'hébergement d'une carte bot : surtitre, valeur, précision. Fond
/// « raised » neutre, rayon 16 ; aucune couleur de statut.
class HomeHostingBox extends StatelessWidget {
  const HomeHostingBox({
    super.key,
    required this.overline,
    required this.value,
    this.detail,
  });

  final String overline;
  final String value;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? tokens.card : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? tokens.clusterBorder : scheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            overline.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: homeSectionLabelStyle(context),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: homeDisplayStyle(
              15,
              weight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          if (detail != null) ...[
            const SizedBox(height: 2),
            Text(
              detail!,
              style: GoogleFonts.inter(fontSize: 12.5, color: muted),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton « ⋮ » 44×44 d'une carte bot : ouvre le menu des actions secondaires.
class HomeOverflowMenuButton extends StatelessWidget {
  const HomeOverflowMenuButton({
    super.key,
    required this.tooltip,
    required this.entries,
    required this.onSelected,
  });

  final String tooltip;
  final List<PopupMenuEntry<String>> entries;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? tokens.card : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? tokens.clusterBorder : scheme.outline,
        ),
      ),
      child: PopupMenuButton<String>(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        icon: AppIcon.fromMaterial(
          Icons.more_vert_rounded,
          size: 20,
          color: isDark ? tokens.muted : scheme.onSurfaceVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: onSelected,
        itemBuilder: (_) => entries,
      ),
    );
  }
}

/// Ligne « actif sur N serveurs » d'une carte de bot : pastilles de serveurs
/// (fournies par l'hôte), titre et source d'exécution.
class HomeServerPresenceRow extends StatelessWidget {
  const HomeServerPresenceRow({
    super.key,
    required this.title,
    this.statusLabel,
    this.avatars,
  });

  final String title;
  final String? statusLabel;
  final Widget? avatars;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;
    final tokens = HomeTokens.of(context);
    final clusterBg = isDark ? tokens.card : scheme.surfaceContainerLow;
    final clusterBorder = isDark ? tokens.clusterBorder : scheme.outlineVariant;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: clusterBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: clusterBorder),
      ),
      child: Row(
        children: [
          if (avatars != null) ...[avatars!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if (statusLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w400,
                      color: isDark ? tokens.muted : scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
