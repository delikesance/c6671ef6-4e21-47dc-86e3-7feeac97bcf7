part of 'home.dart';

extension _AppHomePageUI on _AppHomePageState {
  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  Color _hostingTimeColor(int minutes) {
    const minutesPerDay = 60 * 24;
    const minutesThreeDays = minutesPerDay * 3;

    if (minutes < minutesPerDay) return AppTheme.error;
    if (minutes < minutesThreeDays) return AppTheme.warning;
    return AppTheme.successAccent;
  }

  String formatDuration(int i) {
    return formatHostingDuration(context, i);
  }

  bool get _shouldShowHostingCard {
    if (_fundingMode == 'premium') {
      return false;
    }
    // In dev mode on desktop, always show time management UX
    if (kDebugMode && !_supportsForegroundTask) {
      return true;
    }
    if (SubscriptionService.isSubscribed) {
      return false;
    }
    return _supportsForegroundTask;
  }

  Widget _buildWideOverview(
    BuildContext context, {
    required String botId,
    required String displayName,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Controls, Hosting, Cloud
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeroControlCard(
                      context,
                      botId: botId,
                      displayName: displayName,
                    ),
                    if (_shouldShowHostingCard) ...[
                      const SizedBox(height: 16),
                      _buildHostingCard(context),
                    ],
                    const SizedBox(height: 16),
                    _buildCloudSyncCard(context, botId: botId),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right Column: Live Console, Observability, Danger Zone
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLiveConsoleCard(context, botId: botId),
                    if (_shouldShowObservability) ...[
                      const SizedBox(height: 16),
                      _buildQuickObservabilityCard(context, botId: botId),
                    ],
                    const SizedBox(height: 20),
                    _buildDangerZoneCard(context, botId: botId),
                  ],
                ),
              ),
            ],
          ),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _buildHeroControlCard(
          context,
          botId: botId,
          displayName: displayName,
        ),
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
    final cardColor = isDark ? AppTheme.homeCard : scheme.surfaceContainer;
    final borderColor = isDark ? AppTheme.homeCardBorder : scheme.outlineVariant;
    final muted = isDark ? AppTheme.homeMuted : scheme.onSurfaceVariant;

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
                        Text(
                          'ID $botId',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: muted,
                          ),
                        ),
                        if (_shouldShowHostingCard)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (_displayFreeMinutesBalance() < 120 &&
                                          _botLaunched
                                      ? scheme.error
                                      : scheme.primary)
                                  .withValues(alpha: 0.12),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 11,
                                  color: _displayFreeMinutesBalance() < 120 &&
                                          _botLaunched
                                      ? scheme.error
                                      : scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  formatDuration(_displayFreeMinutesBalance()),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _displayFreeMinutesBalance() < 120 &&
                                            _botLaunched
                                        ? scheme.error
                                        : scheme.primary,
                                  ),
                                ),
                              ],
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
                  accent: _botLaunched ? AppTheme.danger : null,
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

  Widget _buildLiveConsoleCard(BuildContext context, {required String botId}) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.homeCard : scheme.surfaceContainer;
    final borderColor = isDark ? AppTheme.homeCardBorder : scheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
            child: Row(
              children: [
                Icon(Icons.terminal_rounded, size: 18, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  context.tr.bot_logs_title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                if (_botLaunched)
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
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BotLogsPage(botId: botId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                  label: Text(
                    context.tr.bot_home_view_logs,
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
            ),
          ),
          Divider(height: 1, thickness: 1, color: borderColor),
          InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BotLogsPage(botId: botId),
                ),
              );
            },
            child: Container(
              color: isDark
                  ? const Color(0xFF0B0D13)
                  : const Color(0xFF1B1D28),
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 110, maxHeight: 160),
              child: StreamBuilder<List<String>>(
                stream: getBotLogsStreamForBot(botId),
                initialData: getBotLogsSnapshotForBot(botId),
                builder: (context, snapshot) {
                  final logs = snapshot.data ?? const <String>[];
                  if (logs.isEmpty) {
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
                          Text(
                            context.tr.bot_logs_empty,
                            style: GoogleFonts.firaCode(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final recentLogs = logs.length > 5
                      ? logs.sublist(logs.length - 5)
                      : logs;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.end,
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
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloudSyncCard(BuildContext context, {required String botId}) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.homeMuted
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
                MaterialPageRoute(
                  builder: (_) => BotStatsPage(botId: botId),
                ),
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

  Widget _buildHostingCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.homeCard : colorScheme.surfaceContainer;
    final borderColor =
        (_displayFreeMinutesBalance() < 120 && _botLaunched
                ? colorScheme.error
                : (isDark ? AppTheme.homeCardBorder : colorScheme.outlineVariant))
            .withValues(alpha: 0.9);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _botLaunched ? AppTheme.online : AppTheme.warning,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _botLaunched
                      ? context.tr.home_hosting_status_active
                      : context.tr.home_hosting_status_paused,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _botLaunched ? AppTheme.online : AppTheme.warning,
                  ),
                ),
              ),
              if (_ownerMetadata?.teamId.isNotEmpty == true) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.discord.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(
                      color: AppTheme.discord.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups, size: 12, color: AppTheme.discord),
                      const SizedBox(width: 4),
                      Text(
                        'Team',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.discord,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              HomeHeaderIconButton(
                icon: Icons.history_rounded,
                iconSize: 14,
                tooltip: context.tr.home_hosting_ad_history,
                onTap: _showAdHistoryDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _botLaunched
                ? context.tr.home_hosting_time_left(
                    formatDuration(_displayFreeMinutesBalance()),
                  )
                : context.tr.home_hosting_banked(
                    formatDuration(_displayFreeMinutesBalance()),
                  ),
            style: homeDisplayStyle(
              16,
              color: _hostingTimeColor(_displayFreeMinutesBalance()),
              weight: FontWeight.w700,
            ),
          ),
          if (!_botLaunched) ...[
            const SizedBox(height: 4),
            Text(
              context.tr.home_hosting_time_preserved,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: isDark ? AppTheme.homeMuted : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 12),
          HomeCardActionButton(
            icon: Icons.add_rounded,
            iconSize: 14,
            label: context.tr.home_add_time,
            onTap: _isAddingTime ? null : _addRuntimeTime,
            loading: _isAddingTime,
          ),
        ],
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
    final cardColor = isDark ? AppTheme.homeCard : scheme.surfaceContainer;
    final borderColor = isDark ? AppTheme.homeCardBorder : scheme.outlineVariant;

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
                if (i > 0)
                  Divider(height: 1, thickness: 1, color: borderColor),
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
    final muted = isDark ? AppTheme.homeMuted : scheme.onSurfaceVariant;

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
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.danger,
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
