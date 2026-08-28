import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/utils/responsive.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_config_versions_page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/utils/duration_formatter.dart';

import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/core/utils/external_link.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';
import 'dart:developer' as developer;

part 'home.logic.part.dart';
part 'home.sync.part.dart';
part 'home.ads.part.dart';
part 'home.ui.part.dart';

/// Describes a secondary section accessible via quick-actions on mobile.
class QuickAccessSection {
  final int index;
  final IconData icon;
  final String labelKey;

  const QuickAccessSection({
    required this.index,
    required this.icon,
    required this.labelKey,
  });
}

class AppHomePage extends StatefulWidget {
  final NyxxRest client;
  final ValueChanged<int>? onNavigateToSection;
  const AppHomePage({
    super.key,
    required this.client,
    this.onNavigateToSection,
  });

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage>
    with TickerProviderStateMixin {
  String _appName = "";
  NyxxRest? client;
  String avatar = "";
  bool _botLaunched = false;
  bool _botStarting = false;
  int? _freeMinutesBalance;
  DateTime? _sessionExpiresAt;
  String _fundingMode = '';
  Timer? _runtimeBalanceTimer;
  StreamSubscription<GatewayBotEvent>? _gatewayEventsSub;
  StreamSubscription<bool>? _gatewayConnectionSub;
  bool _gatewayEventsConnected = false;
  int _httpFallbackTick = 0;
  bool _isAddingTime = false;
  bool _isPushingApp = false;
  bool _isPullingApp = false;
  DiscordApplicationOwnerMetadata? _ownerMetadata;
  BotRuntimeCapabilities _runtimeCapabilities = BotRuntimeCapabilities.dart;
  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  int _extractFreeMinutes(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  DateTime? _extractSessionExpiresAt(Map<String, dynamic> runtime) {
    final raw = runtime['session_expires_at'] ?? runtime['sessionExpiresAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  int _remainingMinutesUntil(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    if (!expiresAt.isAfter(now)) return 0;
    final delta = expiresAt.difference(now);
    var minutes = delta.inMinutes;
    if (delta.inSeconds % 60 != 0) minutes++;
    return minutes < 0 ? 0 : minutes;
  }

  int _displayFreeMinutesBalance() {
    if (_fundingMode == 'premium') return 0;
    final expires = _sessionExpiresAt;
    if (expires != null) {
      return _remainingMinutesUntil(expires);
    }
    return _freeMinutesBalance ?? 0;
  }

  Future<void> _ensureGatewayBotEvents() async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return;
    }
    final session = remoteClient.connectGatewayBotEvents();
    await _gatewayEventsSub?.cancel();
    await _gatewayConnectionSub?.cancel();
    _gatewayEventsSub = session.events.listen(_onGatewayBotEvent);
    _gatewayConnectionSub = session.connectionChanges.listen((connected) {
      if (!mounted) return;
      _setState(() => _gatewayEventsConnected = connected);
      if (!connected && !SubscriptionService.isSubscribed) {
        unawaited(_refreshFreeRuntimeBalance());
      }
    });
    if (session.isConnected && mounted) {
      _setState(() => _gatewayEventsConnected = true);
    }
  }

  void _onGatewayBotEvent(GatewayBotEvent event) {
    if (!mounted) return;
    final currentBotId = widget.client.user.id.toString();
    switch (event.type) {
      case GatewayBotEventType.snapshot:
        for (final bot in event.bots) {
          if (bot.botId == currentBotId) {
            _applyGatewayBotPayload(bot);
            return;
          }
        }
        break;
      case GatewayBotEventType.botUpdated:
        final bot = event.bot;
        if (bot != null && bot.botId == currentBotId) {
          _applyGatewayBotPayload(bot);
        }
        break;
      case GatewayBotEventType.botDeleted:
        if (event.bot?.botId == currentBotId) {
          _setState(() {
            _botLaunched = false;
            _botStarting = false;
            _freeMinutesBalance = null;
            _sessionExpiresAt = null;
            _fundingMode = '';
          });
        }
        break;
      case GatewayBotEventType.ping:
      case GatewayBotEventType.unknown:
        break;
    }
  }

  void _applyGatewayBotPayload(GatewayBotEventPayload bot) {
    _setState(() {
      _botLaunched = bot.isRunning;
      _botStarting = false;
      _fundingMode = bot.fundingMode;
      if (bot.fundingMode == 'premium') {
        _sessionExpiresAt = null;
        _freeMinutesBalance = 0;
      } else if (bot.sessionExpiresAt != null && bot.fundingMode == 'free') {
        _sessionExpiresAt = bot.sessionExpiresAt;
        _freeMinutesBalance = _remainingMinutesUntil(bot.sessionExpiresAt!);
      } else {
        _sessionExpiresAt = null;
        _freeMinutesBalance = bot.freeMinutesBalance;
      }
      _gatewayEventsConnected = true;
    });
  }

  bool _hasFreeRuntimeAvailable(Map<String, dynamic> runtime, int balance) {
    final fundingMode =
        (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final sessionActiveRaw =
        runtime['session_active'] ?? runtime['sessionActive'];
    final sessionActive =
        sessionActiveRaw == true ||
        sessionActiveRaw?.toString().toLowerCase() == 'true';
    return balance > 0 || fundingMode == 'free' || sessionActive;
  }

  void Function(Object)? _taskDataCallback;

  @override
  void initState() {
    super.initState();
    if (_supportsForegroundTask) {
      _taskDataCallback = (Object data) {
        consumeForegroundTaskDataForBotLogs(data);
        if (mounted) {
          final currentBotId = widget.client.user.id.toString();
          var launched = _botLaunched;
          var starting = _botStarting;

          if (data is Map) {
            final map = Map<String, dynamic>.from(
              data.cast<dynamic, dynamic>(),
            );
            if (map['type'] == 'bot_lifecycle' &&
                map['botId']?.toString() == currentBotId) {
              launched = isMobileBotRunning(currentBotId);
              starting = false;
            }
          }

          setState(() {
            _botLaunched = launched;
            _botStarting = starting;
          });
        }
      };
      try {
        FlutterForegroundTask.addTaskDataCallback(_taskDataCallback!);
      } on MissingPluginException {
        debugPrint('Foreground callback registration unavailable on platform');
      } on PlatformException catch (error) {
        if (_isDeadChannelError(error)) {
          debugPrint('Foreground callback channel unavailable; skipping.');
        } else {
          rethrow;
        }
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initService();
    });
    _init();
    unawaited(_ensureGatewayBotEvents());
    _runtimeBalanceTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      if (_sessionExpiresAt != null &&
          !SubscriptionService.isSubscribed &&
          _fundingMode != 'premium') {
        _setState(() {});
      }
      if (!_gatewayEventsConnected && !SubscriptionService.isSubscribed) {
        _httpFallbackTick++;
        if (_httpFallbackTick >= 4) {
          _httpFallbackTick = 0;
          unawaited(_refreshFreeRuntimeBalance());
        }
      } else {
        _httpFallbackTick = 0;
      }
    });
  }

  @override
  void dispose() {
    _runtimeBalanceTimer?.cancel();
    unawaited(_gatewayEventsSub?.cancel());
    unawaited(_gatewayConnectionSub?.cancel());
    final callback = _taskDataCallback;
    if (callback != null) {
      try {
        FlutterForegroundTask.removeTaskDataCallback(callback);
      } on MissingPluginException {
        debugPrint('Foreground callback removal unavailable on platform');
      } on PlatformException catch (error) {
        if (_isDeadChannelError(error)) {
          debugPrint('Foreground callback channel unavailable; skipping.');
        } else {
          rethrow;
        }
      }
    }
    super.dispose();
  }

  Future<List<ApplicationCommand>> getCommands() async {
    if (client == null) {
      throw Exception("Client is not initialized");
    }
    final commands = await client!.commands.list();
    return commands;
  }

  Future<void> _showAdHistoryDialog() async {
    final botId = widget.client.user.id.toString();
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 4),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uiCopy(
                fr: "Impossible de récupérer l'historique (connexion API indisponible)",
                en: "Cannot fetch ad history (API unavailable)",
              ),
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLg),
        ),
      ),
      builder: (sheetContext) {
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: remoteClient.getBotAdHistory(botId),
          builder: (ctx, snapshot) {
            final colorScheme = Theme.of(ctx).colorScheme;
            return Container(
              padding: const EdgeInsets.all(AppTheme.spacingLg),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.7,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.history, color: AppTheme.brandPrimary),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          context.tr.home_hosting_ad_rewards_history_title,
                          style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.all(AppTheme.spacingXl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      child: Center(
                        child: Text(
                          context.tr.home_hosting_ad_history_error,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    )
                  else if (!snapshot.hasData || snapshot.data!.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppTheme.spacingXl),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.tv_off_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: AppTheme.spacingMd),
                            Text(
                              context.tr.home_hosting_ad_history_empty,
                              style: Theme.of(ctx).textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.outline),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: snapshot.data!.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (ctx, i) {
                          final claim = snapshot.data![i];
                          final minutes =
                              claim['granted_minutes'] ??
                              claim['grantedMinutes'] ??
                              0;
                          final placement =
                              (claim['placement'] ?? 'admob_rewarded')
                                  .toString();
                          final occurredRaw =
                              claim['occurred_at'] ?? claim['occurredAt'];
                          final occurred = occurredRaw != null
                              ? DateTime.tryParse(
                                  occurredRaw.toString(),
                                )?.toLocal()
                              : null;
                          final dateStr = occurred != null
                              ? '${occurred.day.toString().padLeft(2, '0')}/${occurred.month.toString().padLeft(2, '0')}/${occurred.year} à ${occurred.hour.toString().padLeft(2, '0')}:${occurred.minute.toString().padLeft(2, '0')}'
                              : '';

                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_circle_outline,
                                color: AppTheme.success,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              '+$minutes min ($placement)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              dateStr,
                              style: Theme.of(ctx).textTheme.bodySmall,
                            ),
                            trailing: Text(
                              formatDuration(
                                minutes is int
                                    ? minutes
                                    : int.tryParse(minutes.toString()) ?? 0,
                              ),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: !ResponsiveHelper.isDesktopPlatform()
            ? IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => context.openParentDrawer(),
              )
            : null,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.brandGradient),
        ),
        title: Text(
          _appName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final contentMaxWidth = constraints.maxWidth >= 900 ? 560.0 : 460.0;
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLg,
                  vertical: AppTheme.spacingLg,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: contentMaxWidth),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const SizedBox(height: AppTheme.spacingLg),
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.brandGradient,
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: colorScheme.surface,
                            child: avatar.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      avatar,
                                      width: 76,
                                      height: 76,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.smart_toy,
                                                size: 40,
                                              ),
                                    ),
                                  )
                                : const Icon(Icons.smart_toy, size: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        _appName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingXl),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _botLaunched
                              ? AppTheme.error
                              : _botStarting
                              ? AppTheme.warning
                              : AppTheme.success,
                          minimumSize: const Size.fromHeight(48),
                          shape: AppTheme.buttonShape,
                        ),
                        onPressed: _botStarting ? null : _toggleBotLaunchState,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_botStarting)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Icon(
                                _botLaunched ? Icons.stop : Icons.play_arrow,
                                color: Colors.white,
                              ),
                            const SizedBox(width: AppTheme.spacingSm),
                            Text(
                              _botStarting
                                  ? context.tr.bot_home_starting
                                  : _botLaunched
                                  ? context.tr.bot_home_stop
                                  : context.tr.bot_home_start,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_supportsForegroundTask &&
                          !SubscriptionService.isSubscribed &&
                          _fundingMode != 'premium') ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTheme.spacingMd),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(
                              color:
                                  (_displayFreeMinutesBalance() < 120 &&
                                              _botLaunched
                                          ? colorScheme.error
                                          : colorScheme.outlineVariant)
                                      .withValues(alpha: 0.4),
                            ),
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
                                      color: _botLaunched
                                          ? AppTheme.success
                                          : AppTheme.warning,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _botLaunched
                                        ? context.tr.home_hosting_status_active
                                        : context.tr.home_hosting_status_paused,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: _botLaunched
                                              ? AppTheme.success
                                              : AppTheme.warning,
                                        ),
                                  ),
                                  const Spacer(),
                                  if (_ownerMetadata?.teamId.isNotEmpty ==
                                      true) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.discord.withValues(
                                          alpha: 0.15,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusSm,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.discord.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.groups,
                                            size: 13,
                                            color: AppTheme.discord,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _ownerMetadata!.teamName.isNotEmpty
                                                ? _ownerMetadata!.teamName
                                                : "Team",
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.discord,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: AppTheme.spacingXs),
                                  ],
                                  IconButton(
                                    tooltip: context.tr.home_hosting_ad_history,
                                    icon: const Icon(Icons.history, size: 20),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: _showAdHistoryDialog,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTheme.spacingSm),
                              Text(
                                _botLaunched
                                    ? context.tr.home_hosting_time_left(
                                        formatDuration(
                                          _displayFreeMinutesBalance(),
                                        ),
                                      )
                                    : context.tr.home_hosting_banked(
                                        formatDuration(
                                          _displayFreeMinutesBalance(),
                                        ),
                                      ),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: _hostingTimeColor(
                                        _displayFreeMinutesBalance(),
                                      ).withValues(alpha: 0.95),
                                    ),
                              ),
                              if (!_botLaunched &&
                                  _displayFreeMinutesBalance() > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  context.tr.home_hosting_time_preserved,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                              if (_botLaunched &&
                                  _sessionExpiresAt != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  formatSessionExpiration(
                                    context,
                                    _sessionExpiresAt!,
                                  ),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.outline,
                                        fontSize: 11,
                                      ),
                                ),
                              ],
                              const SizedBox(height: AppTheme.spacingMd),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonalIcon(
                                  onPressed: _isAddingTime
                                      ? null
                                      : () => _addRuntimeTime(),
                                  icon: _isAddingTime
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.add_circle_outline),
                                  label: Text(context.tr.home_add_time),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXl),
                      if (widget.onNavigateToSection != null)
                        _buildSection(
                          icon: Icons.rocket_launch_outlined,
                          title: context.tr.bot_home_section_getting_started,
                          children: [
                            _buildActionTile(
                              icon: Icons.tune,
                              label: context.tr.bot_home_customize,
                              onTap: () => widget.onNavigateToSection!(9),
                              iconColor: AppTheme.brandPrimary,
                            ),
                            _buildActionTile(
                              icon: Icons.add_circle_outline,
                              label: context.tr.bot_home_create_command,
                              onTap: () => widget.onNavigateToSection!(1),
                              iconColor: AppTheme.success,
                            ),
                          ],
                        ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSection(
                        icon: Icons.monitor_heart_outlined,
                        title: context.tr.bot_home_section_monitoring,
                        children: [
                          _buildActionTile(
                            icon: Icons.receipt_long,
                            label: context.tr.bot_home_view_logs,
                            onTap: () {
                              final botId = widget.client.user.id.toString();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BotLogsPage(botId: botId),
                                ),
                              );
                            },
                          ),
                          if (ResponsiveHelper.isDesktopPlatform() &&
                              _runtimeCapabilities.supportsBotProcessStats)
                            _buildActionTile(
                              icon: Icons.bar_chart,
                              label: context.tr.bot_home_view_stats,
                              onTap: () {
                                final botId = widget.client.user.id.toString();
                                Navigator.push(
                                  context,
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
                            _buildActionTile(
                              icon: Icons.play_circle_outline,
                              label: context.tr.bot_home_view_replay,
                              onTap: () {
                                final botId = widget.client.user.id.toString();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DebugReplayPage(botId: botId),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSection(
                        icon: Icons.build_outlined,
                        title: context.tr.bot_home_section_tools,
                        children: [
                          _buildActionTile(
                            icon: Icons.cloud_download,
                            label: context.tr.bot_home_pull,
                            iconColor: AppTheme.info,
                            onTap: _isPullingApp
                                ? null
                                : () async {
                                    await _pullFromRemote(showSnack: true);
                                    unawaited(
                                      refreshBotRuntime(
                                        widget.client.user.id.toString(),
                                      ),
                                    );
                                  },
                            trailing: _isPullingApp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          _buildActionTile(
                            icon: Icons.cloud_upload,
                            label: context.tr.bot_home_push,
                            iconColor: AppTheme.success,
                            onTap: _isPushingApp
                                ? null
                                : () async {
                                    await _pushToRemote(showSnack: true);
                                    unawaited(
                                      refreshBotRuntime(
                                        widget.client.user.id.toString(),
                                      ),
                                    );
                                  },
                            trailing: _isPushingApp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : null,
                          ),
                          _buildActionTile(
                            icon: Icons.history,
                            label: context.tr.bot_home_version_history,
                            iconColor: AppTheme.grey,
                            onTap: () async {
                              final botId = widget.client.user.id.toString();
                              final app = await appManager.getApp(botId);
                              final token = (app['token'] ?? '')
                                  .toString()
                                  .trim();
                              if (token.isEmpty) return;

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BotConfigVersionsPage(
                                    botId: botId,
                                    botToken: token,
                                    resolveClient: (id, tok) =>
                                        _resolveMainApiClientForBot(
                                          botId: id,
                                          botToken: tok,
                                          attemptSessionRestore: true,
                                        ),
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildActionTile(
                            icon: Icons.person_add,
                            label: context.tr.bot_home_invite,
                            iconColor: AppTheme.info,
                            onTap: () async {
                              final botId = widget.client.user.id.toString();
                              final inviteUrl = Uri.parse(
                                'https://discord.com/api/oauth2/authorize?client_id=$botId&scope=bot&permissions=8',
                              );

                              if (await openExternalUrl(inviteUrl)) {
                                await AppAnalytics.logEvent(
                                  name: "invite_bot",
                                  parameters: {"bot_id": botId},
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      context.tr.bot_home_invite_error,
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      _buildSection(
                        icon: Icons.warning_amber_rounded,
                        title: context.tr.bot_home_section_danger,
                        children: [
                          _buildActionTile(
                            icon: Icons.delete_outline,
                            label: context.tr.bot_home_delete,
                            iconColor: AppTheme.error,
                            textColor: AppTheme.error,
                            trailing: const Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: AppTheme.error,
                            ),
                            onTap: () async {
                              final confirmed =
                                  await AppTheme.showConfirmDialog(
                                    context,
                                    title: context.tr.bot_home_delete,
                                    content: context.tr.bot_home_delete_confirm,
                                    confirmLabel: context.tr.common_delete,
                                    icon: Icons.delete_forever,
                                  );
                              if (!confirmed || !mounted) return;
                              await appManager.deleteBotCompletely(
                                widget.client.user.id.toString(),
                              );
                              if (mounted) Navigator.of(context).pop();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingXxl),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
