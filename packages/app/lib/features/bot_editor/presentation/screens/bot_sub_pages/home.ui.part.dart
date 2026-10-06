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

// Briques visuelles de l'accueil d'un bot : elles vivent dans
// `package:bot_creator_ui` (partagées avec le Studio, qui affiche la même page).
// Les noms privés d'origine pointent vers elles.
TextStyle _botMono(double size, Color color) => botHomeMono(size, color);

typedef _BotPalette = BotHomePalette;
typedef _BotButtonVariant = BotHomeButtonVariant;
typedef _BotButton = BotHomeButton;
typedef _BotLinkButton = BotHomeLinkButton;
typedef _BotPanel = BotHomePanel;
typedef _BotRow = BotHomeRow;
typedef _BotChip = BotHomeChip;
typedef _BotEmptyHint = BotHomeEmptyHint;
typedef _BotCountdown = BotHomeCountdown;
typedef _BotCardGrid = BotHomeCardGrid;
typedef _BotMonogram = BotHomeMonogram;

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

/// Carte « Logs du bot » : en-tête (titre + action) et console intégrée.
///
/// La console affiche DEUX sources, dans cet ordre de vérité :
///  1. les lignes LUES sur le serveur pour un bot hébergé (`serverLogs`, rempli
///     par `BotServerLogsScope`) : c'est ce qui la remplit même quand aucun flux
///     ne pousse rien ;
///  2. le flux en direct, en BONUS : ses lignes s'ajoutent à la suite.
/// Sur un bot exécuté en local, `serverLogs` reste vide : rien ne change.
///
/// Le rendu (en-tête, filtre Tout / Infos / Erreurs, console) est celui du kit
/// partagé [BotHomeConsolePanel] ; cette classe ne fait que rassembler les lignes
/// et dire la VÉRITÉ sur l'état vide.
class BotHomeLiveConsoleCard extends StatelessWidget {
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

  /// Sous-titre de l'état vide : il doit dire la VÉRITÉ.
  ///
  /// Trois cas, dans cet ordre :
  ///  - le serveur a répondu une liste vide → il n'y a rien à afficher, on le
  ///    dit, au lieu de laisser croire qu'un flux poussé va finir par arriver ;
  ///  - la lecture a échoué → on le dit aussi. La cause n'est jamais relayée :
  ///    un message d'erreur peut recracher la réponse du serveur, et un log de
  ///    bot peut y avoir laissé un secret échappé ;
  ///  - sinon (bot local, lecture pas encore revenue) → texte d'origine.
  String _emptyHintText(BuildContext context) {
    final isFr = Localizations.localeOf(context).languageCode == 'fr';
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
    return StreamBuilder<List<String>>(
      stream: getBotLogsStreamForBot(botId),
      initialData: getBotLogsSnapshotForBot(botId),
      builder: (context, snapshot) => BotHomeConsolePanel(
        // La lecture des logs du bot hébergé fait autorité ; le flux en direct
        // la complète en bonus. Sans rien de poussé, les lignes lues
        // s'affichent quand même — c'est tout le correctif.
        lines: mergeBotLogLines(
          readFromServer: serverLogs.lines,
          live: snapshot.data ?? const <String>[],
        ),
        emptyHint: _emptyHintText(context),
        onOpenLogs: onOpenLogs,
        fillHeight: fillHeight,
        showLevelFilter: showLevelFilter,
        compactLineCount: compactLineCount,
      ),
    );
  }
}
