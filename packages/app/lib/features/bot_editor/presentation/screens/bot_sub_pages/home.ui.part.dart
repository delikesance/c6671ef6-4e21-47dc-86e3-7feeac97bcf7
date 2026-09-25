part of 'home.dart';

extension _AppHomePageUI on _AppHomePageState {
  Color _hostingTimeColor(int minutes) {
    const minutesPerDay = 60 * 24;
    const minutesThreeDays = minutesPerDay * 3;

    if (minutes < minutesPerDay) return AppTheme.error;
    if (minutes < minutesThreeDays) return AppTheme.warning;
    return AppTheme.online;
  }

  String formatDuration(int i) {
    return formatHostingDuration(context, i);
  }

  /// Plan d'affichage du temps d'hébergement sur un POSTE DE TRAVAIL, décidé par
  /// la brique partagée (`hosting_time_offer.dart`) : ce que l'écran a le droit
  /// d'OFFRIR (bouton pub, explication, état « illimité ») et ce qu'il a le droit
  /// d'ANNONCER comme échéance (la date du serveur, ou rien).
  ///
  /// `null` hors poste de travail : le mobile garde sa règle de visibilité
  /// historique, au mot près.
  HostingTimePlan? get _desktopHostingPlan => desktopHostingTimePlan(
    botId: widget.client.user.id.toString(),
    serverReportsRunning: _botLaunched,
    serverSessionExpiresAt: _sessionExpiresAt,
    premiumFunded: _fundingMode == 'premium',
  );

  /// Hors poste de travail, la carte garde sa règle historique — sauf sur un
  /// point : plus aucune date n'est FABRIQUÉE depuis le solde. Un stock de
  /// minutes n'est pas une échéance, sur aucune plateforme.
  HostingTimePlan get _historicalHostingPlan => HostingTimePlan(
    offer: resolveHostingTimeOffer(
      isDesktop: false,
      hasNoAds: hasNoAdsEntitlement(),
      premiumFunded: _fundingMode == 'premium',
    ),
    deadline: resolveHostingDeadline(
      runOrigin: null,
      serverProvidesDeadline: _sessionExpiresAt != null,
    ),
  );

  bool get _shouldShowHostingCard {
    final plan = _desktopHostingPlan;
    if (plan != null) {
      // Sur un poste : un abonné voit son état « illimité » (rien n'expire, rien
      // à obtenir), un bot réellement hébergé voit son échéance réelle ou son
      // temps restant, un bot exécuté par ce poste ne voit rien — il ne consomme
      // pas le solde cloud.
      return plan.showsHostingCard;
    }
    // Règle historique hors poste de travail, au mot près.
    if (_fundingMode == 'premium') {
      return false;
    }
    if (SubscriptionService.isSubscribed) {
      return false;
    }
    return _supportsForegroundTask;
  }

  /// Libellé d'état de l'en-tête : il dit QUI exécute le bot, pas ce que l'écran
  /// aimerait afficher. Sur un poste, c'est l'état vivant qui tranche ; ailleurs,
  /// l'ancien libellé est conservé au mot près.
  String _headerStatusLabel(BuildContext context) {
    final origin = _runOrigin;
    if (origin == null) {
      return _botLaunched
          ? context.tr.home_hosting_status_active
          : context.tr.home_status_offline;
    }
    return botRunSourceLabel(context.tr, origin) ?? context.tr.home_status_offline;
  }

  Widget _buildWideOverview(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    return BotHomeDesktopOverview(
      header: _buildWideHeader(context),
      leftBuilder: (context, fillViewport) =>
          _buildWideLeftColumn(context, botId: botId, displayName: displayName),
      rightBuilder: (context, fillViewport) => _buildWideRightColumn(
        context,
        botId: botId,
        fillViewport: fillViewport,
      ),
    );
  }

  Widget _buildWideHeader(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(
                  Icons.dashboard_rounded,
                  size: 18,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr.home_tab,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    _headerStatusLabel(context),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _botLaunched ? AppTheme.online : muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          HomeHeaderIconButton(
            icon: Icons.sync_rounded,
            iconSize: 14,
            tooltip: context.tr.common_refresh,
            onTap: _isReconciling ? null : _refreshOverview,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildWideLeftColumn(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    return [
      _buildHeroControlCard(context, botId: botId, displayName: displayName),
      if (_shouldShowHostingCard) ...[
        const SizedBox(height: 16),
        _buildHostingCard(context),
      ],
      const SizedBox(height: 16),
      _buildCloudSyncCard(context, botId: botId),
      if (_shouldShowObservability) ...[
        const SizedBox(height: 16),
        _buildQuickObservabilityCard(context, botId: botId),
      ],
      const SizedBox(height: 20),
      _buildDangerZoneCard(context, botId: botId),
    ];
  }

  List<Widget> _buildWideRightColumn(
    BuildContext context, {
    required String botId,
    required bool fillViewport,
  }) {
    return [
      // En mode « pleine hauteur », la console absorbe tout l'espace vertical
      // restant de la colonne au lieu d'être plafonnée à 160 px.
      if (fillViewport)
        Expanded(
          child: _buildLiveConsoleCard(context, botId: botId, fillHeight: true),
        )
      else
        _buildLiveConsoleCard(context, botId: botId),
    ];
  }

  Widget _buildNarrowOverview(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        FloatingGlassNavBar.contentClearanceOf(context) + 16,
      ),
      children: [
        _buildHeroControlCard(context, botId: botId, displayName: displayName),
        if (_shouldShowHostingCard) ...[
          const SizedBox(height: 12),
          _buildHostingCard(context),
        ],
        const SizedBox(height: 14),
        _buildLiveConsoleCard(context, botId: botId),
        const SizedBox(height: 14),
        _buildCloudSyncCard(context, botId: botId),
        if (_shouldShowObservability) ...[
          const SizedBox(height: 14),
          _buildQuickObservabilityCard(context, botId: botId),
        ],
        const SizedBox(height: 20),
        _buildDangerZoneCard(context, botId: botId),
      ],
    );
  }

  Widget _buildHeroControlCard(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final cardColor = isDark ? tokens.card : scheme.surfaceContainer;
    final borderColor = isDark
        ? AppTheme.brandPrimary.withValues(alpha: 0.22)
        : scheme.outlineVariant;
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HomeBotAvatar(
                imageUrl: avatar.isEmpty ? null : avatar,
                ringColor: AppTheme.brandPrimary.withValues(alpha: 0.4),
                ringWidth: 1.5,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: homeDisplayStyle(
                        18,
                        color: scheme.onSurface,
                        weight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Tooltip(
                          message:
                              Localizations.localeOf(context).languageCode ==
                                  'fr'
                              ? 'Copier l\'ID'
                              : 'Copy ID',
                          child: InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: botId));
                              HapticFeedback.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    Localizations.localeOf(
                                              context,
                                            ).languageCode ==
                                            'fr'
                                        ? 'ID $botId copié dans le presse-papiers'
                                        : 'ID $botId copied to clipboard',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'ID $botId',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: muted,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 11,
                                    color: muted.withValues(alpha: 0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HomeStatusPill(
                isRunning: _botLaunched && !_botStarting,
                pulseController: _statusPulseController,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HomeCardActionButton(
                  icon: _botLaunched
                      ? Icons.stop_rounded
                      : Icons.play_arrow_rounded,
                  label: _botStarting
                      ? context.tr.bot_home_starting
                      : (_botLaunched
                            ? context.tr.home_stop
                            : context.tr.home_start),
                  onTap: _botStarting ? null : _toggleBotLaunchState,
                  loading: _botStarting,
                  accent: _botLaunched ? AppTheme.danger : AppTheme.online,
                  stopSquare: _botLaunched,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HomeCardActionButton(
                  icon: Icons.restart_alt_rounded,
                  iconSize: 14,
                  label: context.tr.bot_home_restart,
                  onTap: (!_botLaunched || _botStarting)
                      ? null
                      : () => unawaited(_restartBot()),
                  loading: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: HomeCardActionButton(
              icon: Icons.person_add_alt_1_rounded,
              iconSize: 14,
              label: context.tr.bot_home_invite,
              onTap: () => unawaited(_openInviteLink(botId)),
              loading: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveConsoleCard(
    BuildContext context, {
    required String botId,
    bool fillHeight = false,
  }) {
    // Le panneau LIT les logs d'un bot hébergé (`GET /gateway/bots/{id}/logs`)
    // au lieu d'attendre un flux poussé : sans cette lecture, la console d'un bot
    // qui tourne sur les serveurs Bot Creator restait vide.
    return BotServerLogsScope(
      botId: botId,
      builder: (context, serverLogs) => BotHomeLiveConsoleCard(
        botId: botId,
        isLive: _botLaunched,
        fillHeight: fillHeight,
        serverLogs: serverLogs,
        onOpenLogs: () => _openBotLogsPage(botId),
      ),
    );
  }

  void _openBotLogsPage(String botId) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => BotLogsPage(botId: botId)));
  }

  Widget _buildCloudSyncCard(BuildContext context, {required String botId}) {
    final tokens = HomeTokens.of(context);
    final muted = Theme.of(context).brightness == Brightness.dark
        ? tokens.muted
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return _WireframeSection(
      title: context.tr.bot_home_section_tools,
      children: [
        _WireframeTile(
          icon: Icons.cloud_download_outlined,
          title: context.tr.bot_home_pull,
          trailing: _isPullingApp
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: muted,
                  ),
                )
              : null,
          onTap: _isPullingApp
              ? null
              : () async {
                  await _pullFromRemote(showSnack: true);
                  unawaited(refreshBotRuntime(botId));
                },
        ),
        _WireframeTile(
          icon: Icons.cloud_upload_outlined,
          title: context.tr.bot_home_push,
          trailing: _isPushingApp
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: muted,
                  ),
                )
              : null,
          onTap: _isPushingApp
              ? null
              : () async {
                  await _pushToRemote(showSnack: true);
                  unawaited(refreshBotRuntime(botId));
                },
        ),
        _WireframeTile(
          icon: Icons.history_rounded,
          title: context.tr.bot_home_version_history,
          onTap: () => _openVersionHistory(botId),
        ),
      ],
    );
  }

  Widget _buildQuickObservabilityCard(
    BuildContext context, {
    required String botId,
  }) {
    return _WireframeSection(
      title: context.tr.bot_home_section_monitoring,
      children: [
        if (ResponsiveHelper.isDesktopPlatform() &&
            _runtimeCapabilities.supportsBotProcessStats)
          _WireframeTile(
            icon: Icons.insights_outlined,
            title: context.tr.bot_home_view_stats,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => BotStatsPage(botId: botId)),
              );
            },
          ),
        if (_runtimeCapabilities.supportsDebugReplay &&
            PremiumCapabilities.isCapabilityRolledOut(
              PremiumCapability.visualDebuggerReplay,
            ))
          _WireframeTile(
            icon: Icons.bug_report_outlined,
            title: context.tr.bot_home_view_replay,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DebugReplayPage(botId: botId),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDangerZoneCard(BuildContext context, {required String botId}) {
    return _DashedDeleteTile(
      label: context.tr.bot_home_delete,
      onTap: () => _deleteBot(botId),
    );
  }

  /// Carte « temps total » de l'hébergement : en-tête (libellé de section +
  /// historique des pubs + refresh) puis la carte qui détaille la réserve.
  Widget _buildHostingCard(BuildContext context) {
    final balance = _displayFreeMinutesBalance();
    final parts = splitHostingDuration(balance);
    // Sur un poste, la décision est partagée ; ailleurs, la règle historique.
    final plan = _desktopHostingPlan ?? _historicalHostingPlan;
    final expiresAt = _sessionExpiresAt;
    final unlimited = plan.showsUnlimitedState;
    final breakdown = _hostingSegments(parts);

    // Contenu écrit : une seule vérité à la fois, décidée par la brique partagée
    // (`resolveHostingCardCopy`). L'écran ne choisit plus lui-même ce qu'il
    // écrit, donc il ne peut plus FABRIQUER une échéance depuis le solde :
    //   * un abonné lit son ÉTAT (« illimité ») ;
    //   * sinon l'échéance RÉELLE du serveur, quand il en fournit une ;
    //   * sinon le TEMPS RESTANT (le solde) — 138 mois de stock ne font pas le
    //     14 février 2038 ;
    //   * bot arrêté : la réserve attend.
    final cardCopy = switch (resolveHostingCardCopy(
      plan,
      botLaunched: _botLaunched,
      serverSessionExpiresAt: expiresAt,
    )) {
      HostingCardCopy.unlimited => (
        overline: context.tr.home_hosting_unlimited_overline,
        headline: context.tr.home_hosting_unlimited_headline,
        segments: const <({String value, String label})>[],
      ),
      HostingCardCopy.serverDeadline => (
        overline: context.tr.home_hosting_expiration_expected,
        headline: formatHostingExpiration(context, expiresAt!),
        segments: breakdown,
      ),
      HostingCardCopy.remainingTime => (
        overline: context.tr.home_hosting_remaining_overline,
        headline: formatDuration(balance),
        segments: breakdown,
      ),
      HostingCardCopy.preservedTime => (
        overline: context.tr.home_hosting_time_preserved_overline,
        headline: formatDuration(balance),
        segments: breakdown,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.home_hosting_total,
                style: homeSectionLabelStyle(context),
              ),
            ),
            HomeHeaderIconButton(
              icon: Icons.history_rounded,
              iconSize: 14,
              tooltip: context.tr.home_hosting_ad_history,
              onTap: _showAdHistoryDialog,
            ),
            const SizedBox(width: 8),
            HomeHeaderIconButton(
              icon: Icons.refresh_rounded,
              iconSize: 14,
              tooltip: context.tr.common_refresh,
              onTap: _isReconciling ? null : _refreshOverview,
            ),
          ],
        ),
        const SizedBox(height: 10),
        HomeHostingTimeCard(
          statusLabel: _botLaunched
              ? context.tr.home_hosting_status_active_short
              : context.tr.home_hosting_status_paused_short,
          // Quand le bot tourne, la pastille porte la santé de la réserve
          // (vert / orange / rouge) ; arrêté, la réserve est simplement en
          // attente. Un abonné n'a plus de réserve à surveiller : sa pastille
          // ne peut pas devenir rouge pour un solde qu'il ne consomme pas.
          statusColor: unlimited
              ? (_botLaunched ? AppTheme.online : AppTheme.warning)
              : (_botLaunched
                    ? _hostingTimeColor(balance)
                    : AppTheme.warning),
          overline: cardCopy.overline,
          headline: cardCopy.headline,
          segments: cardCopy.segments,
          // Ce que cet écran a le droit d'OFFRIR : bouton (mobile non abonné),
          // explication (poste de travail), rien (abonné).
          offer: plan.offer,
          showTeamBadge: _ownerMetadata?.teamId.isNotEmpty == true,
          emphasizeBorder: !unlimited && balance < 120 && _botLaunched,
          isAddingTime: _isAddingTime,
          onAddTime: _isAddingTime ? null : _addRuntimeTime,
        ),
      ],
    );
  }

  /// Décomposition du temps restant : une valeur et un libellé par unité.
  List<({String value, String label})> _hostingSegments(
    HostingDurationParts parts,
  ) {
    return [
      (value: _twoDigits(parts.months), label: context.tr.unit_short_month),
      (value: _twoDigits(parts.days), label: context.tr.unit_short_day),
      (value: _twoDigits(parts.hours), label: context.tr.unit_short_hour),
      (value: _twoDigits(parts.minutes), label: context.tr.unit_short_minute),
    ];
  }

  /// Complète une valeur sur deux chiffres (« 07 », « 05 », « 53 »).
  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _WireframeSection extends StatelessWidget {
  const _WireframeSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final cardColor = isDark ? tokens.card : scheme.surfaceContainer;
    final borderColor = isDark ? tokens.cardBorder : scheme.outlineVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: homeSectionLabelStyle(context)),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: borderColor),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _WireframeTile extends StatelessWidget {
  const _WireframeTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final muted = isDark ? tokens.muted : scheme.onSurfaceVariant;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              trailing ??
                  Icon(Icons.chevron_right_rounded, size: 18, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedDeleteTile extends StatelessWidget {
  const _DashedDeleteTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.danger,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: HomeDashedRoundedRectPainter(
                color: AppTheme.danger.withValues(alpha: 0.55),
                radius: AppTheme.radiusCard,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Hauteur minimale (px) de la zone de contenu à partir de laquelle la home
/// desktop passe en mode « pleine hauteur » : les deux colonnes occupent alors
/// toute la fenêtre et la console de logs absorbe l'espace vertical restant.
/// En dessous (fenêtre courte), on retombe sur la mise en page scrollable
/// historique pour ne jamais déborder.
const double kBotHomeDesktopFillMinHeight = 560;

/// Largeur sous laquelle l'en-tête de la console réduit son action à une icône.
///
/// Mesuré : à EXACTEMENT 380 px (l'ancienne valeur), la variante « large »
/// débordait encore de 7 px — le seuil était trop juste d'un cheveu. La marge
/// est portée à 400 px, et un test de frontière verrouille les deux côtés.
const double kBotHomeLogsHeaderCompactWidth = 400;

/// Mise en page desktop de la home d'un bot.
///
/// Les builders reçoivent `fillViewport` :
/// - `true` : la fenêtre est assez haute, les colonnes s'étirent sur toute la
///   hauteur (`CrossAxisAlignment.stretch`) et la colonne de gauche devient
///   défilable seule si son contenu dépasse. C'est ce flag qui autorise
///   l'appelant à placer un `Expanded` (ex. la console de logs) dans la
///   colonne de droite.
/// - `false` : fenêtre courte, mise en page scrollable historique inchangée.
///
/// La largeur et les marges horizontales viennent du contrat commun
/// ([PageContent]) : la page ne code plus ses propres bornes.
class BotHomeDesktopOverview extends StatelessWidget {
  const BotHomeDesktopOverview({
    super.key,
    this.header,
    required this.leftBuilder,
    required this.rightBuilder,
  });

  final Widget? header;
  final List<Widget> Function(BuildContext context, bool fillViewport)
  leftBuilder;
  final List<Widget> Function(BuildContext context, bool fillViewport)
  rightBuilder;

  /// Respiration verticale propre à la home (16 px en haut, 32 px en bas) :
  /// le contrat commun ne fournit que les marges horizontales, et la mise en
  /// page pleine hauteur s'appuie sur ce bas de page.
  static const EdgeInsets _verticalPadding = EdgeInsets.only(
    top: 16,
    bottom: 32,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fillViewport =
            constraints.maxHeight.isFinite &&
            constraints.maxHeight >= kBotHomeDesktopFillMinHeight;
        final left = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: leftBuilder(context, fillViewport),
        );
        final right = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rightBuilder(context, fillViewport),
        );

        if (!fillViewport) {
          return PageContent(
            child: SingleChildScrollView(
              padding: _verticalPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ?header,
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: left),
                      const SizedBox(width: 24),
                      Expanded(flex: 6, child: right),
                    ],
                  ),
                ],
              ),
            ),
          );
        }

        final contentRow = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // La colonne de gauche défile seule si son contenu dépasse
            // la hauteur de la fenêtre (aucun débordement possible).
            Expanded(
              flex: 5,
              child: SingleChildScrollView(primary: false, child: left),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 6, child: right),
          ],
        );

        return PageContent(
          child: Padding(
            padding: _verticalPadding,
            child: header != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header!,
                      Expanded(child: contentRow),
                    ],
                  )
                : contentRow,
          ),
        );
      },
    );
  }
}

/// Carte « Logs du bot » : en-tête (titre + pastille LIVE + action) et console
/// intégrée.
///
/// La console affiche DEUX sources, dans cet ordre de vérité :
///  1. les lignes LUES sur le serveur pour un bot hébergé (`serverLogs`, rempli
///     par `BotServerLogsScope`) : c'est ce qui la remplit même quand aucun flux
///     ne pousse rien ;
///  2. le flux en direct, en BONUS : ses lignes s'ajoutent à la suite.
/// Sur un bot exécuté en local, `serverLogs` reste vide : rien ne change.
class BotHomeLiveConsoleCard extends StatelessWidget {
  const BotHomeLiveConsoleCard({
    super.key,
    required this.botId,
    required this.isLive,
    required this.onOpenLogs,
    this.fillHeight = false,
    this.serverLogs = const BotServerLogsState(),
  });

  final String botId;
  final bool isLive;
  final VoidCallback onOpenLogs;

  /// `true` : la console s'étire sur la hauteur fournie par le parent (qui doit
  /// être bornée). `false` : hauteur historique bornée 110 → 160 px.
  final bool fillHeight;

  /// Ce que la LECTURE des logs du bot hébergé a rendu
  /// (`GET /gateway/bots/{id}/logs`). Vide tant qu'aucune lecture n'a eu lieu —
  /// et un bot exécuté en local n'en produit jamais.
  final BotServerLogsState serverLogs;

  /// Nombre de lignes affichées quand la console a une hauteur bornée.
  static const int _compactLineCount = 5;

  /// Plafond du nombre de lignes rendues quand la console s'étire.
  static const int _maxVisibleLines = 200;

  /// Sous-titre de l'état vide : il doit dire la VÉRITÉ.
  ///
  /// Trois cas, dans cet ordre :
  ///  - le serveur a répondu une liste vide → il n'y a rien à afficher, on le
  ///    dit, au lieu de laisser croire qu'un flux poussé va finir par arriver ;
  ///  - la lecture a échoué → on le dit aussi. La cause n'est jamais relayée :
  ///    un message d'erreur peut recracher la réponse du serveur, et un log de
  ///    bot peut y avoir laissé un secret échappé ;
  ///  - sinon (bot local, lecture pas encore revenue) → texte d'origine.
  String _emptyHintText(BuildContext context, {required bool isFr}) {
    if (serverLogs.isEmptyFromServer) {
      return context.tr.bot_logs_server_empty;
    }
    if (serverLogs.readFailed) {
      return context.tr.bot_logs_server_read_failed;
    }
    return isLive
        ? (isFr
              ? 'En attente d\'événements en direct...'
              : 'Waiting for live events...')
        : (isFr
              ? 'Démarrez le bot pour afficher les logs en direct'
              : 'Start the bot to view live logs');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeTokens.of(context);
    final cardColor = isDark ? tokens.card : scheme.surfaceContainer;
    final borderColor = isDark ? tokens.cardBorder : scheme.outlineVariant;

    final console = Container(
      color: isDark ? const Color(0xFF0B0D13) : const Color(0xFF1B1D28),
      padding: const EdgeInsets.all(12),
      constraints: fillHeight
          ? null
          : const BoxConstraints(minHeight: 110, maxHeight: 160),
      child: StreamBuilder<List<String>>(
        stream: getBotLogsStreamForBot(botId),
        initialData: getBotLogsSnapshotForBot(botId),
        builder: (context, snapshot) {
          // La lecture des logs du bot hébergé fait autorité ; le flux en direct
          // la complète en bonus. Sans rien de poussé, les lignes lues
          // s'affichent quand même — c'est tout le correctif.
          final logs = mergeBotLogLines(
            readFromServer: serverLogs.lines,
            live: snapshot.data ?? const <String>[],
          );
          if (logs.isEmpty) {
            if (fillHeight) {
              final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(
                          Icons.terminal_rounded,
                          size: 22,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        context.tr.bot_logs_empty,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.firaCode(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _emptyHintText(context, isFr: isFr),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.code_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      context.tr.bot_logs_empty,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.firaCode(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          final visibleCount = fillHeight
              ? _maxVisibleLines
              : _compactLineCount;
          final recentLogs = logs.length > visibleCount
              ? logs.sublist(logs.length - visibleCount)
              : logs;
          final lines = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in recentLogs)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 1.5),
                  child: Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: const Color(0xFFC9D1D9),
                      height: 1.2,
                    ),
                  ),
                ),
            ],
          );
          if (!fillHeight) {
            return lines;
          }
          // Console étirée : les dernières lignes restent collées en bas et
          // l'historique défile au lieu de déborder.
          return SingleChildScrollView(
            primary: false,
            reverse: true,
            child: lines,
          );
        },
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: fillHeight ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: _buildHeader(context, scheme),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          if (fillHeight)
            Expanded(
              child: InkWell(onTap: onOpenLogs, child: console),
            )
          else
            InkWell(onTap: onOpenLogs, child: console),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme scheme) {
    // L'en-tête s'adapte à la largeur réellement disponible : sous
    // [kBotHomeLogsHeaderCompactWidth], l'action « Voir les logs » se réduit à
    // une icône + tooltip. Le titre est élastique (ellipsis) et ne pousse donc
    // jamais le reste du Row hors de la carte.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kBotHomeLogsHeaderCompactWidth;
        return Row(
          children: [
            Icon(Icons.terminal_rounded, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      context.tr.bot_logs_title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (isLive) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.online.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        border: Border.all(
                          color: AppTheme.online.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.online,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.online,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (compact)
              IconButton(
                onPressed: onOpenLogs,
                tooltip: context.tr.bot_home_view_logs,
                iconSize: 16,
                color: scheme.primary,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                icon: const Icon(Icons.open_in_new_rounded),
              )
            else
              TextButton.icon(
                onPressed: onOpenLogs,
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: Text(
                  context.tr.bot_home_view_logs,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        );
      },
    );
  }
}
