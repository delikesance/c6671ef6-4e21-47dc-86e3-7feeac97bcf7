part of 'home.dart';

extension _AppHomePageUI on _AppHomePageState {
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
    return botRunSourceLabel(context.tr, origin) ??
        context.tr.home_status_offline;
  }

  Widget _buildWideOverview(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    final palette = _BotPalette.of(context);
    final showHosting = _shouldShowHostingCard;
    // Grille d'aperçus : Hébergement, Commandes (top 4), Workflows.
    final cards = <Widget>[
      if (showHosting) _buildHostingCard(context, wide: true),
      _buildCommandsPreviewCard(context, palette),
      _buildWorkflowsPreviewCard(context, palette),
    ];
    final secondary = <Widget>[
      _buildCloudSyncCard(context, botId: botId),
      if (_shouldShowObservability)
        _buildQuickObservabilityCard(context, botId: botId),
    ];

    return PageContent(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildIdentityHeader(
              context,
              botId: botId,
              displayName: displayName,
              wide: true,
            ),
            const SizedBox(height: 24),
            _BotCardGrid(children: cards),
            const SizedBox(height: 20),
            // Console pleine largeur, filtrée par niveau (Tout / Infos / Erreurs).
            _buildLiveConsoleCard(context, botId: botId, wide: true),
            const SizedBox(height: 20),
            _BotCardGrid(children: secondary),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: _buildDangerZoneCard(context, botId: botId),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNarrowOverview(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        FlatNavBar.contentClearanceOf(context) + 16,
      ),
      children: [
        _buildIdentityHeader(
          context,
          botId: botId,
          displayName: displayName,
          wide: false,
        ),
        if (_shouldShowHostingCard) ...[
          const SizedBox(height: 18),
          _buildHostingCard(context, wide: false),
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

  Future<void> _copyBotId(String botId) async {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    await Clipboard.setData(ClipboardData(text: botId));
    HapticFeedback.selectionClick();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFr
              ? 'ID $botId copié dans le presse-papiers'
              : 'ID $botId copied to clipboard',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// En-tête d'identité PLAT (sans carte) : monogramme, nom, ID mono avec copie,
  /// pastille d'état, puis les actions du bot. Sur desktop les actions passent à
  /// droite du nom ; « Inviter le bot » y est l'action principale (violette),
  /// sauf bot arrêté où c'est « Démarrer » qui prend le relais en vert d'état.
  Widget _buildIdentityHeader(
    BuildContext context, {
    required String botId,
    required String displayName,
    required bool wide,
  }) {
    final palette = _BotPalette.of(context);
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
    final starting = _botStarting;
    final running = _botLaunched && !starting;
    final statusPill = starting
        ? StatusPill.warning(label: context.tr.bot_home_starting)
        : (running
              ? StatusPill.online(label: context.tr.home_status_online)
              : StatusPill.stopped(label: context.tr.home_status_offline));

    final idRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            'ID $botId',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _botMono(wide ? 13 : 12.5, palette.muted),
          ),
        ),
        Tooltip(
          message: isFr ? 'Copier l\'ID' : 'Copy ID',
          child: SizedBox(
            width: 44,
            height: 44,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => unawaited(_copyBotId(botId)),
              child: Center(
                child: AppIcon.fromMaterial(
                  Icons.copy_rounded,
                  size: 16,
                  color: palette.muted,
                ),
              ),
            ),
          ),
        ),
      ],
    );

    final toggleButton = _BotButton(
      variant: _botLaunched
          ? _BotButtonVariant.danger
          : _BotButtonVariant.online,
      icon: _botLaunched ? Icons.stop_rounded : Icons.play_arrow_rounded,
      stopSquare: _botLaunched,
      label: starting
          ? context.tr.bot_home_starting
          : (_botLaunched ? context.tr.home_stop : context.tr.home_start),
      loading: starting,
      height: wide ? 44 : 48,
      onTap: starting ? null : _toggleBotLaunchState,
    );
    final restartButton = _BotButton(
      variant: _BotButtonVariant.secondary,
      icon: Icons.restart_alt_rounded,
      label: context.tr.bot_home_restart,
      height: wide ? 44 : 48,
      onTap: (!_botLaunched || starting)
          ? null
          : () => unawaited(_restartBot()),
    );
    final inviteButton = _BotButton(
      variant: wide && _botLaunched
          ? _BotButtonVariant.primary
          : _BotButtonVariant.secondary,
      icon: Icons.person_add_alt_1_rounded,
      label: context.tr.bot_home_invite,
      compact: !wide,
      onTap: () => unawaited(_openInviteLink(botId)),
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
                _BotMonogram(
                  name: displayName,
                  imageUrl: avatar,
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
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 24,
                              height: 30 / 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.24,
                              color: palette.text,
                            ),
                          ),
                          statusPill,
                        ],
                      ),
                      Row(
                        children: [
                          Flexible(child: idRow),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _headerStatusLabel(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: palette.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(width: 168, child: inviteButton),
              SizedBox(width: 152, child: restartButton),
              SizedBox(width: 132, child: toggleButton),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _BotMonogram(
              name: displayName,
              imageUrl: avatar,
              size: 56,
              radius: 18,
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
                    style: TextStyle(
                      fontSize: 20,
                      height: 26 / 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: palette.text,
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
        Row(
          children: [
            Expanded(child: toggleButton),
            const SizedBox(width: 8),
            Expanded(child: restartButton),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: inviteButton),
            const SizedBox(width: 8),
            Expanded(
              child: _BotButton(
                variant: _BotButtonVariant.secondary,
                icon: Icons.auto_awesome_outlined,
                label: context.tr.copilot_title,
                compact: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CopilotPage(
                      botId: botId,
                      botName: displayName,
                      location: 'local',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Carte « Commandes » de la home desktop : les 4 premières commandes.
  Widget _buildCommandsPreviewCard(BuildContext context, _BotPalette palette) {
    final commands = _homeCommands;
    return _BotPanel(
      title: context.tr.commands_tab,
      wide: true,
      trailing: commands.isEmpty || widget.onOpenSection == null
          ? null
          : _BotLinkButton(
              label: context.tr.bot_home_commands_see_all(commands.length),
              trailingIcon: Icons.chevron_right_rounded,
              onTap: () => widget.onOpenSection!('commands'),
            ),
      child: commands.isEmpty
          ? _BotEmptyHint(text: context.tr.commands_empty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final command in commands.take(4)) ...[
                  _buildCommandRow(context, palette, command),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Widget _buildCommandRow(
    BuildContext context,
    _BotPalette palette,
    Map<String, dynamic> command,
  ) {
    final data = Map<String, dynamic>.from(
      (command['data'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final name = (command['name'] ?? 'unknown').toString();
    final actionsCount = (data['actions'] as List?)?.length ?? 0;
    return _BotRow(
      leading: BlockFamily.messages.pastille(
        Icons.terminal_rounded,
        size: 36,
        iconSize: 18,
      ),
      onTap: widget.onOpenSection == null
          ? null
          : () => widget.onOpenSection!('commands'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '/$name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _botMono(
              14.5,
              palette.text,
            ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14.5),
          ),
          const SizedBox(height: 5),
          _BotChip(label: context.tr.bot_home_actions_count(actionsCount)),
        ],
      ),
    );
  }

  /// Carte « Workflows » de la home desktop : aperçu + création.
  Widget _buildWorkflowsPreviewCard(BuildContext context, _BotPalette palette) {
    final workflows = _homeWorkflows;
    return _BotPanel(
      title: context.tr.workflows_tab,
      wide: true,
      footer: widget.onOpenSection == null
          ? null
          : _BotButton(
              variant: _BotButtonVariant.secondary,
              icon: Icons.add_rounded,
              label: context.tr.workflows_create,
              onTap: () => widget.onOpenSection!('workflows'),
            ),
      child: workflows.isEmpty
          ? _BotEmptyHint(text: context.tr.workflows_empty)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final workflow in workflows.take(3)) ...[
                  _buildWorkflowRow(context, palette, workflow),
                  const SizedBox(height: 8),
                ],
              ],
            ),
    );
  }

  Widget _buildWorkflowRow(
    BuildContext context,
    _BotPalette palette,
    Map<String, dynamic> workflow,
  ) {
    final isEvent = workflow['workflowType']?.toString() == workflowTypeEvent;
    final family = isEvent ? BlockFamily.events : BlockFamily.logic;
    final name = (workflow['name'] ?? '').toString();
    final actionsCount = (workflow['actions'] as List?)?.length ?? 0;
    final trigger = workflow['eventTrigger'];
    final eventName = trigger is Map ? (trigger['event'] ?? '').toString() : '';
    final details = [
      if (isEvent && eventName.isNotEmpty) eventName,
      context.tr.bot_home_actions_count(actionsCount),
    ].join(' · ');
    return _BotRow(
      leading: family.pastille(
        isEvent ? Icons.bolt_rounded : Icons.account_tree_outlined,
        size: 36,
        iconSize: 18,
      ),
      onTap: widget.onOpenSection == null
          ? null
          : () => widget.onOpenSection!('workflows'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (isEvent
                    ? context.tr.workflows_type_badge_event
                    : context.tr.workflows_type_badge_general)
                .toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: family.overlineStyle(),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w700,
              color: palette.text,
            ),
          ),
          Text(
            details,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, color: palette.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveConsoleCard(
    BuildContext context, {
    required String botId,
    bool fillHeight = false,
    bool wide = false,
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
        showLevelFilter: wide,
        compactLineCount: wide ? 8 : 3,
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
    return _FlatDeleteTile(
      label: context.tr.bot_home_delete,
      onTap: () => _deleteBot(botId),
    );
  }

  /// Carte « Hébergement » : pastille de session, chip Équipe, temps restant en
  /// 4 cellules, ligne d'échéance (UNIQUEMENT si le serveur en fournit une),
  /// « Ajouter du temps » (seule action violette, mobile non abonné) et
  /// l'historique des pubs.
  Widget _buildHostingCard(BuildContext context, {required bool wide}) {
    final palette = _BotPalette.of(context);
    final balance = _displayFreeMinutesBalance();
    final parts = splitHostingDuration(balance);
    // Sur un poste, la décision est partagée ; ailleurs, la règle historique.
    final plan = _desktopHostingPlan ?? _historicalHostingPlan;
    final expiresAt = _sessionExpiresAt;
    final unlimited = plan.showsUnlimitedState;
    final breakdown = _hostingSegments(parts);

    // Une seule vérité à la fois, décidée par la brique partagée
    // (`resolveHostingCardCopy`) : aucune date n'est FABRIQUÉE depuis le solde.
    final copy = resolveHostingCardCopy(
      plan,
      botLaunched: _botLaunched,
      serverSessionExpiresAt: expiresAt,
    );
    final overline = switch (copy) {
      HostingCardCopy.unlimited => context.tr.home_hosting_unlimited_overline,
      HostingCardCopy.preservedTime =>
        context.tr.home_hosting_time_preserved_overline,
      _ => context.tr.home_hosting_remaining_overline,
    };
    final showCountdown = copy != HostingCardCopy.unlimited;
    // Échéance : seulement quand le serveur la donne (jamais déduite du solde).
    final showExpiry =
        copy == HostingCardCopy.serverDeadline && expiresAt != null;

    final pillVariant = unlimited
        ? (_botLaunched ? StatusPillVariant.online : StatusPillVariant.warning)
        : (_botLaunched
              ? _hostingPillVariant(balance)
              : StatusPillVariant.warning);

    final addTime = plan.showsAddTimeButton;
    return _BotPanel(
      title: context.tr.bot_home_hosting_title,
      wide: wide,
      emphasize: !unlimited && balance < 120 && _botLaunched,
      trailing: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          StatusPill(
            variant: pillVariant,
            label: _botLaunched
                ? context.tr.home_hosting_status_active_short
                : context.tr.home_hosting_status_paused_short,
          ),
          if (_ownerMetadata?.teamId.isNotEmpty == true)
            _BotChip(label: context.tr.team_tab, large: wide),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            overline.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              height: 13 / 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.84,
              color: palette.muted,
            ),
          ),
          const SizedBox(height: 12),
          if (unlimited)
            Text(
              context.tr.home_hosting_unlimited_headline,
              style: TextStyle(
                fontSize: 20,
                height: 26 / 20,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            )
          else if (showCountdown)
            _BotCountdown(segments: breakdown, wide: wide),
          if (showExpiry) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: palette.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatSessionExpiration(context, expiresAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: wide ? 14 : 13.5,
                      height: 20 / 14,
                      color: palette.softText,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (addTime) ...[
            const SizedBox(height: 16),
            _BotButton(
              variant: _BotButtonVariant.primary,
              icon: Icons.add_rounded,
              label: context.tr.home_add_time,
              height: 48,
              loading: _isAddingTime,
              onTap: _isAddingTime ? null : _addRuntimeTime,
            ),
          ] else if (plan.showsMobileAdsExplanation) ...[
            // Poste de travail : les pubs récompensées se regardent sur mobile,
            // aucun bouton « Ajouter du temps » n'est proposé ici.
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: AppIcon.fromMaterial(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: palette.muted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.home_add_time_mobile_only,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: palette.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Tooltip(
              message: context.tr.home_hosting_ad_history,
              child: _BotButton(
                variant: _BotButtonVariant.ghost,
                icon: Icons.history_rounded,
                label: context.tr.home_hosting_ad_history,
                expand: !wide,
                onTap: _showAdHistoryDialog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Santé de la réserve → variante de pastille (vert / orange / rouge).
  StatusPillVariant _hostingPillVariant(int minutes) {
    const minutesPerDay = 60 * 24;
    if (minutes < minutesPerDay) return StatusPillVariant.error;
    if (minutes < minutesPerDay * 3) return StatusPillVariant.warning;
    return StatusPillVariant.online;
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

/// Police mono (identifiants, commandes, logs, compteurs).
TextStyle _botMono(double size, Color color) => TextStyle(
  fontFamily: 'JetBrainsMono',
  fontSize: size,
  color: color,
  letterSpacing: 0,
);

/// Palette de la home d'un bot. Sombre : surfaces de la refonte (panneau
/// #12141A, surélevé #16181E, fond #0E0F13, action violette). Clair : dérivée
/// du `ColorScheme`, comme le reste de l'app.
class _BotPalette {
  const _BotPalette({
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

  factory _BotPalette.of(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (theme.brightness == Brightness.dark) {
      final tokens = HomeTokens.of(context);
      return _BotPalette(
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
    return _BotPalette(
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

enum _BotButtonVariant { primary, secondary, danger, online, ghost }

/// Bouton plat de la home : 12 px de rayon, 44 px de haut minimum.
class _BotButton extends StatelessWidget {
  const _BotButton({
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

  final _BotButtonVariant variant;
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
    final p = _BotPalette.of(context);
    final (Color bg, Color border, Color fg) = switch (variant) {
      _BotButtonVariant.primary => (p.violet, Colors.transparent, p.onViolet),
      _BotButtonVariant.secondary => (p.raised, p.raisedBorder, p.text),
      _BotButtonVariant.danger => (
        AppTheme.statusError.withValues(alpha: 0.08),
        AppTheme.statusError.withValues(alpha: 0.4),
        AppTheme.statusErrorText,
      ),
      _BotButtonVariant.online => (
        AppTheme.statusOnline.withValues(alpha: 0.08),
        AppTheme.statusOnline.withValues(alpha: 0.4),
        AppTheme.statusOnline,
      ),
      _BotButtonVariant.ghost => (
        Colors.transparent,
        Colors.transparent,
        p.softText,
      ),
    };
    final enabled = onTap != null && !loading;
    final textColor = compact && variant == _BotButtonVariant.secondary
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
class _BotLinkButton extends StatelessWidget {
  const _BotLinkButton({
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
    final p = _BotPalette.of(context);
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
class _BotPanel extends StatelessWidget {
  const _BotPanel({
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
    final p = _BotPalette.of(context);
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
class _BotRow extends StatelessWidget {
  const _BotRow({required this.leading, required this.child, this.onTap});

  final Widget leading;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = _BotPalette.of(context);
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
class _BotChip extends StatelessWidget {
  const _BotChip({required this.label, this.large = false});

  final String label;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final p = _BotPalette.of(context);
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
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFB4B9C6),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotEmptyHint extends StatelessWidget {
  const _BotEmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = _BotPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(text, style: TextStyle(fontSize: 13.5, color: p.muted)),
    );
  }
}

/// Temps restant en 4 cellules (mois, jours, heures, minutes).
class _BotCountdown extends StatelessWidget {
  const _BotCountdown({required this.segments, required this.wide});

  final List<({String value, String label})> segments;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = _BotPalette.of(context);
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
                        : _botMono(22, p.text).copyWith(
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

/// Grille de cartes de la home desktop : colonnes de 320 px minimum, 20 px
/// d'écart, cartes d'une même rangée étirées à la même hauteur.
class _BotCardGrid extends StatelessWidget {
  const _BotCardGrid({required this.children});

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

/// Monogramme du bot : initiales dans une pastille HTTP (carré arrondi), ou son
/// avatar Discord quand l'URL est connue.
class _BotMonogram extends StatelessWidget {
  const _BotMonogram({
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
              AppIcon.fromMaterial(icon, size: 18, color: muted),
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
                  AppIcon.fromMaterial(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: muted,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FlatDeleteTile extends StatelessWidget {
  const _FlatDeleteTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Surface PLATE (plus de pointillés) : fond rouge 8 %, bordure rouge 40 %.
    return _BotButton(
      variant: _BotButtonVariant.danger,
      icon: Icons.delete_outline_rounded,
      label: label,
      height: 48,
      onTap: onTap,
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
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(
                  context,
                ).copyWith(scrollbars: false),
                child: SingleChildScrollView(primary: false, child: left),
              ),
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

/// Filtre de niveau de la console desktop (sur le texte des lignes de log).
enum _LogLevelFilter { all, info, error }

/// Carte « Logs du bot » : en-tête (titre + action) et console intégrée.
///
/// La console affiche DEUX sources, dans cet ordre de vérité :
///  1. les lignes LUES sur le serveur pour un bot hébergé (`serverLogs`, rempli
///     par `BotServerLogsScope`) : c'est ce qui la remplit même quand aucun flux
///     ne pousse rien ;
///  2. le flux en direct, en BONUS : ses lignes s'ajoutent à la suite.
/// Sur un bot exécuté en local, `serverLogs` reste vide : rien ne change.
///
/// Avec [showLevelFilter] (desktop), un sélecteur Tout / Infos / Erreurs filtre
/// les lignes d'après leur niveau (`[INFO]`, `[ERROR]`, `[SEVERE]`…).
class BotHomeLiveConsoleCard extends StatefulWidget {
  const BotHomeLiveConsoleCard({
    super.key,
    required this.botId,
    required this.isLive,
    required this.onOpenLogs,
    this.fillHeight = false,
    this.serverLogs = const BotServerLogsState(),
    this.showLevelFilter = false,
    this.compactLineCount = 3,
  });

  final String botId;
  final bool isLive;
  final VoidCallback onOpenLogs;

  /// `true` : la console s'étire sur la hauteur fournie par le parent (qui doit
  /// être bornée). `false` : hauteur bornée selon [compactLineCount].
  final bool fillHeight;

  /// Ce que la LECTURE des logs du bot hébergé a rendu
  /// (`GET /gateway/bots/{id}/logs`). Vide tant qu'aucune lecture n'a eu lieu —
  /// et un bot exécuté en local n'en produit jamais.
  final BotServerLogsState serverLogs;

  /// Affiche le sélecteur de niveau (Tout / Infos / Erreurs).
  final bool showLevelFilter;

  /// Nombre de lignes affichées quand la console a une hauteur bornée.
  final int compactLineCount;

  /// Plafond du nombre de lignes rendues quand la console s'étire.
  static const int _maxVisibleLines = 200;

  @override
  State<BotHomeLiveConsoleCard> createState() => _BotHomeLiveConsoleCardState();
}

class _BotHomeLiveConsoleCardState extends State<BotHomeLiveConsoleCard> {
  _LogLevelFilter _filter = _LogLevelFilter.all;

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
    if (widget.serverLogs.isEmptyFromServer) {
      return context.tr.bot_logs_server_empty;
    }
    if (widget.serverLogs.readFailed) {
      return context.tr.bot_logs_server_read_failed;
    }
    return widget.isLive
        ? (isFr
              ? 'En attente d\'événements en direct...'
              : 'Waiting for live events...')
        : (isFr
              ? 'Démarrez le bot pour afficher les logs en direct'
              : 'Start the bot to view live logs');
  }

  bool _matchesFilter(String line) {
    switch (_filter) {
      case _LogLevelFilter.all:
        return true;
      case _LogLevelFilter.info:
        return line.toUpperCase().contains('[INFO]');
      case _LogLevelFilter.error:
        final upper = line.toUpperCase();
        return upper.contains('[ERROR]') ||
            upper.contains('[SEVERE]') ||
            upper.contains('[FATAL]');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _BotPalette.of(context);
    final fillHeight = widget.fillHeight;
    final wideStyle = widget.showLevelFilter;

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
      child: StreamBuilder<List<String>>(
        stream: getBotLogsStreamForBot(widget.botId),
        initialData: getBotLogsSnapshotForBot(widget.botId),
        builder: (context, snapshot) {
          // La lecture des logs du bot hébergé fait autorité ; le flux en direct
          // la complète en bonus. Sans rien de poussé, les lignes lues
          // s'affichent quand même — c'est tout le correctif.
          final allLogs = mergeBotLogLines(
            readFromServer: widget.serverLogs.lines,
            live: snapshot.data ?? const <String>[],
          );
          final logs = allLogs.where(_matchesFilter).toList(growable: false);
          if (logs.isEmpty) {
            return _buildEmpty(context, p, filtered: allLogs.isNotEmpty);
          }
          final visibleCount = fillHeight
              ? BotHomeLiveConsoleCard._maxVisibleLines
              : widget.compactLineCount;
          final recentLogs = logs.length > visibleCount
              ? logs.sublist(logs.length - visibleCount)
              : logs;
          final lines = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in recentLogs)
                _BotLogLine(line: line, wide: wideStyle, palette: p),
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
    _BotPalette p, {
    required bool filtered,
  }) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
                style: _botMono(13, p.softText),
              ),
              if (!filtered) ...[
                const SizedBox(height: 6),
                Text(
                  _emptyHintText(context, isFr: isFr),
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
            style: _botMono(12, p.muted),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, _BotPalette p) {
    // L'en-tête s'adapte à la largeur réellement disponible : sous
    // [kBotHomeLogsHeaderCompactWidth], l'action devient « Afficher tout ».
    // Le titre est élastique (ellipsis) et ne pousse donc jamais le reste du
    // Row hors de la carte.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < kBotHomeLogsHeaderCompactWidth;
        final inlineFilter =
            widget.showLevelFilter && constraints.maxWidth >= 600;
        final filter = widget.showLevelFilter ? _buildFilter(context, p) : null;
        final action = compact
            ? _BotLinkButton(
                label: context.tr.bot_logs_show_all,
                trailingIcon: Icons.arrow_forward_rounded,
                tooltip: context.tr.bot_home_view_logs,
                onTap: widget.onOpenLogs,
              )
            : _BotLinkButton(
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
  Widget _buildFilter(BuildContext context, _BotPalette p) {
    final entries = <(_LogLevelFilter, String)>[
      (_LogLevelFilter.all, context.tr.common_all),
      (_LogLevelFilter.info, context.tr.bot_home_logs_filter_info),
      (_LogLevelFilter.error, context.tr.bot_home_logs_filter_errors),
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
                  left: value == _LogLevelFilter.all ? 0 : 4,
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
class _BotLogLine extends StatelessWidget {
  const _BotLogLine({
    required this.line,
    required this.wide,
    required this.palette,
  });

  final String line;
  final bool wide;
  final _BotPalette palette;

  static final RegExp _timestamp = RegExp(
    r'^(\[\d{4}-\d{2}-\d{2}T[^\]]*\])(.*)$',
  );

  @override
  Widget build(BuildContext context) {
    final size = wide ? 12.5 : 11.5;
    final base = _botMono(
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
