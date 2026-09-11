import 'dart:async';
import 'dart:io';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/ads/presentation/native_ad_slot.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nyxx/nyxx.dart' hide Locale, Logger;
import 'dart:developer' as developer;
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_merge.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_config_pull_dialog.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/utils/string_sanitizer.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/core/utils/duration_formatter.dart';
import 'package:bot_creator/features/containers/presentation/container_list_page.dart';
import 'package:bot_creator/features/bot_management/presentation/create_page.dart';
import 'package:bot_creator/features/settings/presentation/settings_page.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  /// The currently active HomePage instance. Set in initState, cleared in dispose.
  /// Replaces the old module-level GlobalKey pattern that caused
  /// "Multiple widgets used the same GlobalKey" crashes during navigation.
  static HomePageState? current;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> triggerRefresh() async {
    await _refreshIndicatorKey.currentState?.show();
  }

  /// IDs des bots en cours d'exécution.
  Set<String> _runningBotIds = <String>{};

  RemoteRuntimeSource _runtimeSource = RemoteRuntimeSource.local;
  String? _runtimeDetailLabel;
  final Map<String, RemoteRuntimeSource> _runtimeSourceByBotId = {};
  final Map<String, String?> _runtimeDetailLabelByBotId = {};

  /// ID du bot en cours d'action (démarrage/arrêt/ajout de temps).
  String? _botIdInAction;

  /// Un AnimationController par carte (clé = bot id) pour l'effet pulse.
  final Map<String, AnimationController> _pulseControllers = {};
  Map<String, int> _freeMinutesByBotId = <String, int>{};
  final Map<String, DateTime> _sessionExpiresAtByBotId = <String, DateTime>{};
  final Map<String, int> _botNotFoundStreak = <String, int>{};
  final Set<String> _skippedMissingBotIds = <String>{};
  static const int _missingBot404Threshold = 3;
  Timer? _statusRefreshTimer;
  StreamSubscription<GatewayBotEvent>? _gatewayEventsSub;
  StreamSubscription<bool>? _gatewayConnectionSub;
  bool _gatewayEventsConnected = false;
  int _httpFallbackTick = 0;

  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  bool get _isDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get _supportsManagerRuntime => !kIsWeb && !_isDesktop;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    current = this;
    appendBotDebugLog('>>>> [BOT_DEBUG] HomePage.initState ENTERED <<<<');
    WidgetsBinding.instance.addObserver(this);
    AppAnalytics.logScreenView(screenName: 'HomePage', screenClass: 'HomePage');
    AppAnalytics.logEvent(name: 'home_page_opened');
    unawaited(() async {
      try {
        if (warmUpFuture != null) {
          await warmUpFuture;
        }
      } catch (_) {}
      // Detect running state immediately so the user sees online bots
      // right away, even if the full manager sync takes longer.
      await _initRunningState();
      await syncAllBotsFromManager(silent: true);
      await _ensureGatewayBotEvents();
    }());

    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      // Local FREE countdown tick (no HTTP).
      if (_sessionExpiresAtByBotId.isNotEmpty) {
        setState(() {});
      }
      // HTTP fallback only while WebSocket is down (every ~60s).
      if (!_gatewayEventsConnected) {
        _httpFallbackTick++;
        if (_httpFallbackTick >= 4) {
          _httpFallbackTick = 0;
          unawaited(_initRunningState());
        }
      } else {
        _httpFallbackTick = 0;
      }
    });
  }

  @override
  void dispose() {
    if (current == this) current = null;
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    unawaited(_gatewayEventsSub?.cancel());
    unawaited(_gatewayConnectionSub?.cancel());
    for (final ctrl in _pulseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      MainApiClient.resetCircuitBreakers();
      // Immediately refresh running state so the UI updates fast,
      // then do the full sync in background.
      unawaited(_ensureGatewayBotEvents());
      if (!_gatewayEventsConnected) {
        _initRunningState();
      }
      syncAllBotsFromManager(silent: true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      unawaited(appManager.flushPendingWrites());
    }
  }

  // ── Initialisation de l'état running ───────────────────────────────────────

  /// Guards against concurrent [_initRunningState] calls.
  bool _isRefreshingRunningState = false;

  Future<void> _initRunningState() async {
    if (_isRefreshingRunningState) return;
    _isRefreshingRunningState = true;
    try {
      final runningIds = <String>{};
      _runtimeSourceByBotId.clear();
      _runtimeDetailLabelByBotId.clear();
      appendBotDebugLog('[_initRunningState] Starting running-state refresh.');
      final remoteClient = await _resolveGlobalMainApiClient();
      final remoteRuntime = await _resolveRemoteRuntime(
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );
      appendBotDebugLog(
        '[_initRunningState] Resolved runtime: source=${remoteRuntime.source}, hasClient=${remoteRuntime.client != null}, blocksLocalFallback=${remoteRuntime.blocksLocalFallback}, detail=${remoteRuntime.detailLabel ?? 'none'}.',
      );
      final apps = await appManager.getAllApps();
      final localBotIds = apps
          .whereType<Map>()
          .map((raw) => (raw['id'] ?? '').toString().trim())
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
      appendBotDebugLog(
        '[_initRunningState] Local bot ids loaded: count=${localBotIds.length}, ids=${localBotIds.join(',')}.',
      );

      unawaited(
        SubscriptionService.resolveEffectivePremiumStatus(
          client: remoteClient,
          forceRefresh: true,
        ),
      );

      final hasActiveRemote =
          remoteClient != null || remoteRuntime.client != null;
      if (hasActiveRemote || localBotIds.isNotEmpty) {
        appendBotDebugLog(
          '[_initRunningState] Performing running-state detection (remoteClient=${remoteClient?.runtimeType}, remoteRuntime=${remoteRuntime.client?.runtimeType}, localBotIds=${localBotIds.length}).',
        );
        try {
          if (localBotIds.isEmpty) {
            appendBotDebugLog(
              '[_initRunningState] No local bot ids found. Falling back to global status list.',
            );
            final statusClient = remoteClient ?? remoteRuntime.client;
            if (statusClient != null) {
              final status = await statusClient.getStatus();
              appendBotDebugLog(
                '[_initRunningState] Global status fetched: bots=${status.bots.length}, running=${status.running}.',
              );
              for (final bot in status.bots) {
                if (bot.isRunning) {
                  runningIds.add(bot.botId);
                  appendBotDebugLog(
                    '[_initRunningState] Marked running (global): ${bot.botId}.',
                  );
                }
              }
            }
          } else {
            appendBotDebugLog(
              '[_initRunningState] Checking per-bot status with owner-aware client resolution.',
            );
            final runningChecks = localBotIds
                .where((botId) => !_skippedMissingBotIds.contains(botId))
                .map((botId) async {
                  try {
                    appendBotDebugLog(
                      '[_initRunningState] Resolving client for bot $botId.',
                    );

                    // Check local in-app running state first!
                    final isInternalRunning = _supportsForegroundTask
                        ? isMobileBotRunning(botId)
                        : desktopRunningBotIds.contains(botId);
                    if (isInternalRunning) {
                      appendBotDebugLog(
                        '[_initRunningState] Bot $botId is running internally in-app.',
                      );
                      if (mounted) {
                        setState(() {
                          _runtimeSourceByBotId[botId] =
                              RemoteRuntimeSource.local;
                          _runtimeDetailLabelByBotId[botId] = null;
                        });
                      }
                      return botId;
                    }

                    final perBotClient = await _resolveMainApiClientForBot(
                      botId: botId,
                      attemptSessionRestore: false,
                    );
                    final botRuntime = remoteRuntime;

                    final associatedId = RunnerSettings.getAssociatedRunnerId(
                      botId,
                    );
                    final isManagerBot =
                        associatedId == 'manager' ||
                        (associatedId == null && perBotClient != null);

                    final source = isManagerBot
                        ? RemoteRuntimeSource.manager
                        : botRuntime.source;
                    final detailLabel = isManagerBot
                        ? (remoteRuntime.detailLabel ?? 'Bot Creator servers')
                        : botRuntime.detailLabel;

                    if (mounted) {
                      setState(() {
                        _runtimeSourceByBotId[botId] = source;
                        _runtimeDetailLabelByBotId[botId] = detailLabel;
                      });
                    }
                    final statusClient = isManagerBot
                        ? (perBotClient ?? remoteClient)
                        : (botRuntime.client ?? perBotClient ?? remoteClient);
                    appendBotDebugLog(
                      '[_initRunningState] Bot $botId status client: ${statusClient.runtimeType}, resolvedSource=$source, usedFallbackToGlobal=${!isManagerBot && botRuntime.client == null}.',
                    );
                    if (statusClient == null) {
                      return null;
                    }
                    final status = await statusClient.getStatus(botId: botId);
                    final isRunning = status.isBotRunning(botId);
                    _noteBotFound(botId);
                    appendBotDebugLog(
                      '[_initRunningState] Bot $botId status fetched: statusRunning=${status.running}, activeBotId=${status.activeBotId ?? 'none'}, botEntries=${status.bots.length}, isBotRunning=$isRunning.',
                    );
                    return isRunning ? botId : null;
                  } catch (error) {
                    if (error is MainApiClientException &&
                        error.statusCode == 404) {
                      _noteBotNotFound(botId);
                      appendBotDebugLog(
                        '[_initRunningState] Bot $botId missing on manager (404 streak=${_botNotFoundStreak[botId]}).',
                      );
                    } else {
                      appendBotDebugLog(
                        'Failed to sync running status for $botId: $error',
                      );
                    }
                    return null;
                  }
                })
                .toList(growable: false);

            final resolvedRunningIds = await Future.wait(runningChecks);
            for (final botId in resolvedRunningIds.whereType<String>()) {
              runningIds.add(botId);
              appendBotDebugLog(
                '[_initRunningState] Marked running (per-bot): $botId.',
              );
            }
          }
        } catch (_) {}

        appendBotDebugLog(
          '[_initRunningState] Remote detection completed. Running ids=${runningIds.join(',')}.',
        );

        if (!mounted) return;
        setState(() {
          _runningBotIds = runningIds;
          _runtimeSource = remoteRuntime.source;
          _runtimeDetailLabel = remoteRuntime.detailLabel;
        });
        _syncPulse(runningIds);
        await _syncDiscordRpcPresence(runningIds);
        unawaited(_refreshBotRuntimeBalances());
        return;
      }

      if (remoteRuntime.blocksLocalFallback) {
        appendBotDebugLog(
          '[_initRunningState] No remote client and local fallback is blocked. Running set remains empty.',
        );
        if (!mounted) return;
        setState(() {
          _runningBotIds = runningIds;
          _runtimeSource = remoteRuntime.source;
          _runtimeDetailLabel = remoteRuntime.detailLabel;
        });
        _syncPulse(runningIds);
        await _syncDiscordRpcPresence(runningIds);
        unawaited(_refreshBotRuntimeBalances());
        return;
      }

      if (_supportsForegroundTask) {
        try {
          appendBotDebugLog(
            '[_initRunningState] Falling back to foreground task running-state detection.',
          );
          final running = await FlutterForegroundTask.isRunningService;
          appendBotDebugLog(
            '[_initRunningState] Foreground service running=$running.',
          );
          if (running) {
            final configuredIds = await getConfiguredMobileBotIds();
            appendBotDebugLog(
              '[_initRunningState] Configured mobile bot ids: count=${configuredIds.length}, ids=${configuredIds.join(',')}.',
            );
            if (configuredIds.isNotEmpty) {
              runningIds.addAll(configuredIds);
              for (final botId in configuredIds) {
                addMobileRunningBotId(botId);
              }
            } else {
              final fallbackId =
                  mobileRunningBotId ??
                  await FlutterForegroundTask.getData<String>(
                    key: 'running_bot_id',
                  );
              if (fallbackId != null && fallbackId.isNotEmpty) {
                runningIds.add(fallbackId);
                addMobileRunningBotId(fallbackId);
                appendBotDebugLog(
                  '[_initRunningState] Added fallback running bot id from foreground task data: $fallbackId.',
                );
              }
            }
          }
        } on MissingPluginException {
          // Plateforme non supportée.
          appendBotDebugLog(
            '[_initRunningState] Foreground plugin unavailable on this platform.',
          );
        }
      } else {
        runningIds.addAll(desktopRunningBotIds);
        appendBotDebugLog(
          '[_initRunningState] Using desktop running ids fallback: ${desktopRunningBotIds.join(',')}.',
        );
      }
      if (!mounted) return;
      setState(() {
        _runningBotIds = runningIds;
        _runtimeSource = RemoteRuntimeSource.local;
        _runtimeDetailLabel = null;
      });

      for (final botId in desktopRunningBotIds) {
        final guildCount = desktopGatewayForBot(botId)?.guilds.cache.length;
        if (guildCount != null) {
          appManager.updateGuildCount(botId, guildCount);
        }
      }
      _syncPulse(runningIds);
      await _syncDiscordRpcPresence(runningIds);
      unawaited(_refreshBotRuntimeBalances());
      appendBotDebugLog(
        '[_initRunningState] Completed with local fallback. Running ids=${runningIds.join(',')}.',
      );
    } finally {
      _isRefreshingRunningState = false;
    }
  }

  int _extractFreeMinutes(dynamic raw) {
    if (raw == null) {
      return 0;
    }
    if (raw is int) {
      return raw;
    }
    return int.tryParse(raw.toString()) ?? 0;
  }

  DateTime? _extractSessionExpiresAt(Map<String, dynamic> runtime) {
    final raw = runtime['session_expires_at'] ?? runtime['sessionExpiresAt'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  String _fundingModeOf(Map<String, dynamic> runtime) {
    return (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
  }

  int _remainingMinutesUntil(DateTime expiresAt) {
    final now = DateTime.now().toUtc();
    if (!expiresAt.isAfter(now)) return 0;
    final delta = expiresAt.difference(now);
    var minutes = delta.inMinutes;
    if (delta.inSeconds % 60 != 0) minutes++;
    return minutes < 0 ? 0 : minutes;
  }

  int _displayFreeMinutesForBot(String botId) {
    final expires = _sessionExpiresAtByBotId[botId];
    if (expires != null) {
      return _remainingMinutesUntil(expires);
    }
    return _freeMinutesByBotId[botId] ?? 0;
  }

  void _noteBotNotFound(String botId) {
    final next = (_botNotFoundStreak[botId] ?? 0) + 1;
    _botNotFoundStreak[botId] = next;
    if (next >= _missingBot404Threshold) {
      _skippedMissingBotIds.add(botId);
      _sessionExpiresAtByBotId.remove(botId);
      _freeMinutesByBotId.remove(botId);
    }
  }

  void _noteBotFound(String botId) {
    _botNotFoundStreak.remove(botId);
    _skippedMissingBotIds.remove(botId);
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
      setState(() => _gatewayEventsConnected = connected);
      if (connected) {
        _httpFallbackTick = 0;
      } else {
        unawaited(_initRunningState());
      }
    });
    if (session.isConnected && mounted) {
      setState(() => _gatewayEventsConnected = true);
    }
  }

  void _onGatewayBotEvent(GatewayBotEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case GatewayBotEventType.snapshot:
        _applyGatewayBotSnapshot(event.bots);
        break;
      case GatewayBotEventType.botUpdated:
        final bot = event.bot;
        if (bot != null) {
          _applyGatewayBotUpdate(bot);
        }
        break;
      case GatewayBotEventType.botDeleted:
        final botId = event.bot?.botId.trim() ?? '';
        if (botId.isNotEmpty) {
          _applyGatewayBotDeleted(botId);
        }
        break;
      case GatewayBotEventType.ping:
      case GatewayBotEventType.unknown:
        break;
    }
  }

  void _applyGatewayBotSnapshot(List<GatewayBotEventPayload> bots) {
    final running = <String>{};
    final freeMinutes = <String, int>{};
    final expires = <String, DateTime>{};
    for (final bot in bots) {
      final botId = bot.botId.trim();
      if (botId.isEmpty) continue;
      _noteBotFound(botId);
      if (bot.isRunning) {
        running.add(botId);
      }
      if (bot.fundingMode == 'premium') {
        continue;
      }
      if (bot.sessionExpiresAt != null && bot.fundingMode == 'free') {
        expires[botId] = bot.sessionExpiresAt!;
        freeMinutes[botId] = _remainingMinutesUntil(bot.sessionExpiresAt!);
      } else {
        freeMinutes[botId] = bot.freeMinutesBalance;
      }
    }
    setState(() {
      _runningBotIds = running;
      _freeMinutesByBotId = freeMinutes;
      _sessionExpiresAtByBotId
        ..clear()
        ..addAll(expires);
      _gatewayEventsConnected = true;
    });
    _syncPulse(running);
    unawaited(_syncDiscordRpcPresence(running));
  }

  void _applyGatewayBotUpdate(GatewayBotEventPayload bot) {
    final botId = bot.botId.trim();
    if (botId.isEmpty) return;
    _noteBotFound(botId);
    setState(() {
      if (bot.isRunning) {
        _runningBotIds = {..._runningBotIds, botId};
      } else {
        _runningBotIds = {..._runningBotIds}..remove(botId);
      }
      if (bot.fundingMode == 'premium') {
        _freeMinutesByBotId.remove(botId);
        _sessionExpiresAtByBotId.remove(botId);
      } else if (bot.sessionExpiresAt != null && bot.fundingMode == 'free') {
        _sessionExpiresAtByBotId[botId] = bot.sessionExpiresAt!;
        _freeMinutesByBotId[botId] = _remainingMinutesUntil(
          bot.sessionExpiresAt!,
        );
      } else {
        _sessionExpiresAtByBotId.remove(botId);
        _freeMinutesByBotId[botId] = bot.freeMinutesBalance;
      }
    });
    _syncPulse(_runningBotIds);
    unawaited(_syncDiscordRpcPresence(_runningBotIds));
  }

  void _applyGatewayBotDeleted(String botId) {
    setState(() {
      _runningBotIds = {..._runningBotIds}..remove(botId);
      _freeMinutesByBotId.remove(botId);
      _sessionExpiresAtByBotId.remove(botId);
      _skippedMissingBotIds.add(botId);
      _botNotFoundStreak.remove(botId);
    });
    _syncPulse(_runningBotIds);
    unawaited(_syncDiscordRpcPresence(_runningBotIds));
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

  Future<void> _refreshBotRuntimeBalances({Iterable<String>? botIds}) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      if (mounted && _freeMinutesByBotId.isNotEmpty) {
        setState(() {
          _freeMinutesByBotId = <String, int>{};
          _sessionExpiresAtByBotId.clear();
        });
      }
      return;
    }

    final ids = <String>{...?(botIds?.where((id) => id.trim().isNotEmpty))};
    if (ids.isEmpty) {
      final names = await _loadBotNamesById();
      ids.addAll(names.keys.where((id) => id.trim().isNotEmpty));
    }
    ids.removeWhere(_skippedMissingBotIds.contains);
    if (ids.isEmpty) {
      return;
    }

    final updated = <String, int>{..._freeMinutesByBotId};
    final updatedExpires = <String, DateTime>{..._sessionExpiresAtByBotId};
    for (final botId in ids) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        _noteBotFound(botId);
        final funding = _fundingModeOf(runtime);
        if (funding == 'premium') {
          updated.remove(botId);
          updatedExpires.remove(botId);
          continue;
        }
        final expires = _extractSessionExpiresAt(runtime);
        if (expires != null && funding == 'free') {
          updatedExpires[botId] = expires;
          updated[botId] = _remainingMinutesUntil(expires);
        } else {
          updatedExpires.remove(botId);
          updated[botId] = _extractFreeMinutes(
            runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
          );
        }
      } catch (error) {
        if (error is MainApiClientException && error.statusCode == 404) {
          _noteBotNotFound(botId);
          updated.remove(botId);
          updatedExpires.remove(botId);
        }
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _freeMinutesByBotId = updated;
      _sessionExpiresAtByBotId
        ..clear()
        ..addAll(updatedExpires);
    });
  }

  Future<MainApiClient?> _resolveManagerClientForSync() async {
    final remoteClient = await _resolveGlobalMainApiClient();
    if (remoteClient != null) {
      return remoteClient;
    }

    final apps = await appManager.getAllApps();
    appendBotDebugLog(
      '[_resolveManagerClientForSync] Global manager client unavailable. Trying local bot tokens from ${apps.length} apps.',
    );
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp.cast<dynamic, dynamic>());
      final botId = (app['id'] ?? '').toString().trim();
      final token = (app['token'] ?? '').toString().trim();
      if (botId.isEmpty || token.isEmpty) {
        continue;
      }

      appendBotDebugLog(
        '[_resolveManagerClientForSync] Attempting manager session restore from bot $botId.',
      );
      final client = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: token,
        attemptSessionRestore: true,
      );
      if (client != null) {
        appendBotDebugLog(
          '[_resolveManagerClientForSync] Restored manager client from bot $botId.',
        );
        return client;
      }
    }

    appendBotDebugLog(
      '[_resolveManagerClientForSync] Unable to restore a manager client from local bot tokens.',
    );
    return null;
  }

  Future<void> syncAllBotsFromManager({bool silent = false}) async {
    appendBotDebugLog(
      '[syncAllBotsFromManager] Starting sync. silent=$silent.',
    );
    final remoteClient = await _resolveManagerClientForSync();
    if (remoteClient == null) {
      appendBotDebugLog(
        '[syncAllBotsFromManager] Global manager client unavailable. Starting direct Discord API sync for local bots.',
      );
      try {
        final apps = await appManager.getAllApps();
        final syncTasks = apps.map((rawApp) async {
          if (rawApp is! Map) {
            return;
          }
          final app = Map<String, dynamic>.from(
            rawApp.cast<dynamic, dynamic>(),
          );
          final botId = (app['id'] ?? '').toString().trim();
          final token = (app['token'] ?? '').toString().trim();
          if (botId.isEmpty || token.isEmpty) {
            return;
          }

          try {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Syncing local bot $botId directly from Discord.',
            );
            final discordUser = await getDiscordUser(token);
            final botName = discordUser.username.sanitizedUtf16;
            final avatarHash = discordUser.avatarHash;
            final discriminator = discordUser.discriminator.toString();

            int? fetchedApproxGuildCount;
            try {
              final guildCount = await getDiscordBotGuildCount(token);
              if (guildCount != null) {
                fetchedApproxGuildCount = guildCount;
              } else {
                final ownerMetadata = await getDiscordApplicationOwnerMetadata(
                  token,
                );
                if (ownerMetadata != null) {
                  final approx =
                      ownerMetadata.rawJson['approximate_guild_count'];
                  if (approx is int) {
                    fetchedApproxGuildCount = approx;
                  } else if (approx != null) {
                    fetchedApproxGuildCount = int.tryParse(approx.toString());
                  }
                }
              }
            } catch (error) {
              appendBotDebugLog(
                '[syncAllBotsFromManager] Failed to fetch Discord guild count for local bot $botId: $error',
              );
            }

            await appManager.createOrUpdateApp(
              id: Snowflake.parse(botId),
              username: botName,
              avatarHash: avatarHash,
              discriminator: discriminator,
              token: token,
              intents: (app['intents'] as Map?)?.cast<String, bool>(),
              prefix: app['prefix']?.toString(),
              approximateGuildCount: fetchedApproxGuildCount,
            );
            appendBotDebugLog(
              '[syncAllBotsFromManager] Local bot $botId metadata updated successfully.',
            );
          } catch (e) {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Failed to sync local bot $botId directly: $e',
            );
          }
        });
        await Future.wait(syncTasks);
      } catch (e) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Failed to fetch local apps for direct sync: $e',
        );
      }

      if (mounted) {
        await _initRunningState();
      }
      return;
    }

    try {
      final botsById = <String, Map<String, dynamic>>{};

      void mergeBots(List<Map<String, dynamic>> bots) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Merging bot payload batch size=${bots.length}.',
        );
        for (final bot in bots) {
          final botId = (bot['bot_id'] ?? '').toString().trim();
          if (botId.isEmpty) {
            appendBotDebugLog(
              '[syncAllBotsFromManager] Skipping bot payload with empty bot_id.',
            );
            continue;
          }
          botsById[botId] = bot;
        }
      }

      mergeBots(await remoteClient.listBots());
      final apps = await appManager.getAllApps();
      appendBotDebugLog(
        '[syncAllBotsFromManager] Local apps for owner expansion count=${apps.length}.',
      );
      // ── Phase 1: collect owner list clients (global session or one fallback) ──
      final ownerClients = <String, MainApiClient>{};
      final globalClient = await _resolveGlobalMainApiClient(
        attemptRestore: false,
      );
      if (globalClient != null) {
        ownerClients['global'] = globalClient;
      } else {
        final apps = await appManager.getAllApps();
        for (final rawApp in apps) {
          if (rawApp is! Map) continue;
          final botId = (rawApp['id'] ?? '').toString().trim();
          final token = (rawApp['token'] ?? '').toString().trim();
          if (token.isEmpty) continue;
          final ephemeral = await _ownerSyncHelper
              .exchangeEphemeralBotTokenClient(token);
          if (ephemeral != null) {
            ownerClients['bot:$botId'] = ephemeral;
            break;
          }
        }
      }

      // ── Phase 2: fetch listBots in parallel ──
      if (ownerClients.isNotEmpty) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Fetching listBots for ${ownerClients.length} unique owners in parallel.',
        );
        final listBotsTasks = ownerClients.entries
            .map((entry) async {
              final dedupeKey = entry.key;
              final client = entry.value;
              try {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Fetching listBots for dedupeKey=$dedupeKey.',
                );
                mergeBots(await client.listBots());
              } catch (error) {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] listBots failed for dedupeKey=$dedupeKey: $error',
                );
              }
            })
            .toList(growable: false);
        await Future.wait(listBotsTasks);
      }

      final bots = botsById.values.toList(growable: false);
      appendBotDebugLog(
        '[syncAllBotsFromManager] Total merged bot payloads=${bots.length}.',
      );
      // Phase 3: sync each bot (network calls in parallel, filesystem sequential)
      appendBotDebugLog(
        '[syncAllBotsFromManager] Syncing ${bots.length} bots - network phase in parallel.',
      );

      final botSyncTasks = bots
          .map((bot) async {
            final botId = bot['bot_id']?.toString() ?? '';
            if (botId.isEmpty) return null;

            var botName = bot['bot_name']?.toString() ?? 'Unnamed Bot';
            final config = bot['config'] as Map<String, dynamic>? ?? {};

            String token = bot['bot_token']?.toString() ?? '';
            if (token.isEmpty) {
              try {
                final existing = await appManager.getApp(botId);
                token = (existing['token'] ?? '').toString();
              } catch (_) {}
            }

            String? avatarHash =
                bot['avatar_hash']?.toString() ?? bot['avatar']?.toString();
            String? discriminator = bot['discriminator']?.toString();

            int? fetchedApproxGuildCount;
            if (token.trim().isNotEmpty) {
              // If avatar is missing, fetch full bot user profile from Discord REST
              if (avatarHash == null || avatarHash.isEmpty) {
                try {
                  final profile = await getDiscordBotUserProfile(token);
                  if (profile != null) {
                    final fetchedAvatar = profile['avatar'];
                    if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
                      avatarHash = fetchedAvatar;
                    }
                    final fetchedDiscrim = profile['discriminator'];
                    if (fetchedDiscrim != null && fetchedDiscrim.isNotEmpty) {
                      discriminator = fetchedDiscrim;
                    }
                    final fetchedName = profile['username'];
                    if (fetchedName != null &&
                        fetchedName.isNotEmpty &&
                        botName == 'Unnamed Bot') {
                      botName = fetchedName;
                    }
                  }
                } catch (error) {
                  appendBotDebugLog(
                    '[syncAllBotsFromManager] Avatar profile fetch failed for $botId: $error',
                  );
                }
              }

              try {
                final guildCount = await getDiscordBotGuildCount(token);
                if (guildCount != null) {
                  fetchedApproxGuildCount = guildCount;
                } else {
                  final ownerMetadata =
                      await getDiscordApplicationOwnerMetadata(token);
                  if (ownerMetadata != null) {
                    final approx =
                        ownerMetadata.rawJson['approximate_guild_count'];
                    if (approx is int) {
                      fetchedApproxGuildCount = approx;
                    } else if (approx != null) {
                      fetchedApproxGuildCount = int.tryParse(approx.toString());
                    }
                  }
                }
              } catch (error) {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Guild count fetch failed for $botId: $error',
                );
              }
            }

            return _BotSyncResult(
              botId: botId,
              botName: botName,
              token: token,
              config: config,
              bot: bot,
              guildCount: fetchedApproxGuildCount,
              avatarHash: avatarHash,
              discriminator: discriminator,
            );
          })
          .toList(growable: false);

      final syncResults = await Future.wait(botSyncTasks);

      AppManager.isSyncingFromRemote = true;
      try {
        for (final result in syncResults) {
          if (result == null) continue;
          try {
            await appManager.createOrUpdateApp(
              id: Snowflake.parse(result.botId),
              username: result.botName,
              avatarHash: result.avatarHash,
              discriminator: result.discriminator,
              token: result.token,
              intents: (result.config['intents'] as Map?)?.cast<String, bool>(),
              prefix: result.config['prefix']?.toString(),
              approximateGuildCount: result.guildCount,
            );

            // Rehydrate commands and workflows from remote config
            final remoteConfig = result.config;
            final remoteCommands = extractCommandListFromConfig(
              remoteConfig['commands'],
            );
            final localCommands = await appManager.listAppCommands(
              result.botId,
              forceRefresh: true,
            );
            final localWorkflows = await appManager.getWorkflows(result.botId);
            final remoteWorkflows = remoteConfig['workflows'];

            final hasRemoteData =
                remoteCommands.isNotEmpty ||
                (remoteWorkflows is List && remoteWorkflows.isNotEmpty) ||
                (remoteWorkflows is Map && remoteWorkflows.isNotEmpty);

            if (hasRemoteData) {
              if (localCommands.isEmpty && localWorkflows.isEmpty) {
                // Fresh device / newly synced bot: restore all commands and workflows
                await applyManagerConfigToLocal(
                  appManager: appManager,
                  botId: result.botId,
                  remoteConfig: remoteConfig,
                  saveAppMetadata: false,
                );
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Restored ${remoteCommands.length} commands for bot ${result.botId} to local DB.',
                );
              } else {
                // Check if remote has newer edits
                final localNewer = botConfigLocalHasNewerEdits(
                  localCommands,
                  remoteCommands,
                );
                final diff = computeBotConfigMergeDiff(
                  localCommands,
                  remoteCommands,
                );
                if (!localNewer && diff.hasChanges) {
                  await applyManagerConfigToLocal(
                    appManager: appManager,
                    botId: result.botId,
                    remoteConfig: remoteConfig,
                    saveAppMetadata: false,
                  );
                  appendBotDebugLog(
                    '[syncAllBotsFromManager] Auto-merged updated commands/workflows from remote for bot ${result.botId}.',
                  );
                }
              }
            }
          } catch (e) {
            developer.log('Failed to sync bot ${result.botId}: $e');
            appendBotDebugLog(
              '[syncAllBotsFromManager] Failed to sync bot ${result.botId}: $e',
            );
          }
        }
      } finally {
        AppManager.isSyncingFromRemote = false;
      }

      if (mounted) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Triggering _initRunningState after bot sync.',
        );
        await _initRunningState();
      }
    } catch (e) {
      appendBotDebugLog('[syncAllBotsFromManager] Sync failed: $e');
      if (mounted && !silent) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr.home_sync_failed)));
      }
    }
  }

  // ── Gestion des animations pulse ───────────────────────────────────────────

  AnimationController _getOrCreatePulseController(String botId) {
    return _pulseControllers.putIfAbsent(
      botId,
      () => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  void _syncPulse(Set<String> runningIds) {
    for (final entry in _pulseControllers.entries) {
      if (runningIds.contains(entry.key)) {
        if (!entry.value.isAnimating) {
          entry.value.repeat(reverse: true);
        }
      } else {
        entry.value
          ..stop()
          ..value = 0;
      }
    }
  }

  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }

  String? _runtimeBadgeLabel(String botId) {
    final source = _runtimeSourceByBotId[botId] ?? _runtimeSource;
    final detailLabel =
        _runtimeDetailLabelByBotId[botId] ?? _runtimeDetailLabel;
    return switch (source) {
      RemoteRuntimeSource.manager => _uiCopy(
        fr: 'Serveurs Bot Creator',
        en: 'Bot Creator servers',
      ),
      RemoteRuntimeSource.runner =>
        (detailLabel?.trim().isNotEmpty ?? false)
            ? context.tr.runner_source_label(detailLabel!)
            : _uiCopy(fr: 'Runner', en: 'Runner'),
      RemoteRuntimeSource.local => null,
    };
  }

  Future<Map<String, String>> _loadBotNamesById() async {
    final apps = await appManager.getAllApps();
    final namesById = <String, String>{};
    for (final rawApp in apps) {
      if (rawApp is! Map) {
        continue;
      }
      final app = Map<String, dynamic>.from(rawApp);
      final botId = (app['id'] ?? '').toString();
      if (botId.isEmpty) {
        continue;
      }
      namesById[botId] = (app['name'] ?? botId).toString();
    }
    return namesById;
  }

  Future<void> _syncDiscordRpcPresence(
    Set<String> runningBotIds, {
    String? preferredBotId,
    String? preferredBotName,
  }) async {
    try {
      final botNamesById = await _loadBotNamesById();
      await DiscordRpcService.instance.syncBotRuntimeState(
        runningBotIds: runningBotIds,
        botNamesById: botNamesById,
        runtimeSource: _runtimeSource,
        preferredBotId: preferredBotId,
        preferredBotName: preferredBotName,
        activeSourceLabel: _runtimeDetailLabel,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to sync Discord RPC presence: $error',
        name: 'HomePage',
        stackTrace: stackTrace,
      );
    }
  }

  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    String? botId,
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 90),
  }) async {
    return resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
      botId: botId,
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  MainApiOwnerSyncHelper get _ownerSyncHelper => MainApiOwnerSyncHelper(
    resolveRuntime:
        ({
          getTimeout = const Duration(seconds: 30),
          postTimeout = const Duration(seconds: 90),
        }) => _resolveRemoteRuntime(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
    loadLocalBotById: (botId) async => await appManager.getApp(botId),
    log: appendBotDebugLog,
  );

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
  }) async {
    return _ownerSyncHelper.restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: botToken,
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    if (!_supportsManagerRuntime) {
      return null;
    }
    return _ownerSyncHelper.resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: attemptSessionRestore,
    );
  }

  Future<MainApiClient?> _resolveGlobalMainApiClient({
    bool attemptRestore = true,
  }) async {
    if (!_supportsManagerRuntime) {
      return null;
    }
    appendBotDebugLog(
      '[_resolveGlobalMainApiClient] Resolving global client (attemptRestore=$attemptRestore).',
    );

    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Manager is not configured. Returning null.',
      );
      return null;
    }

    var session = await loadMainApiSession();

    if (session != null && !session.isExpired) {
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Active global session found. Returning MainApiClient.',
      );
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }

    if (attemptRestore) {
      final apps = await appManager.getAllApps();
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] No active session; trying one ephemeral bot-token exchange from ${apps.length} local apps.',
      );
      for (final rawApp in apps) {
        if (rawApp is! Map) continue;
        final token = (rawApp['token'] ?? '').toString().trim();
        if (token.isEmpty) continue;
        final client = await _ownerSyncHelper.exchangeEphemeralBotTokenClient(
          token,
        );
        if (client != null) {
          appendBotDebugLog(
            '[_resolveGlobalMainApiClient] Success: ephemeral client from local bot token.',
          );
          return client;
        }
        break;
      }
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Failed to create ephemeral client from local apps.',
      );
    }

    return null;
  }

  // ── Démarrage / Arrêt du bot ───────────────────────────────────────────────

  Future<void> _toggleBot({
    required String botId,
    required String botName,
  }) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    try {
      final isRunning = _runningBotIds.contains(botId);

      var runtime = await _resolveRemoteRuntime(
        botId: botId,
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );

      // ── Fetch + validate token before anything else (only when starting) ──
      String? token;
      if (!isRunning) {
        final app = await appManager.getApp(botId);
        token = app['token']?.toString();

        // Sync config from manager before startup (the basic sync)
        try {
          appendBotDebugLog(
            '[_toggleBot] Fetching latest config from manager before launch...',
          );
          final syncClient = await _resolveMainApiClientForBot(
            botId: botId,
            botToken: token,
            attemptSessionRestore: true,
          );
          if (syncClient != null) {
            final remoteConfig = await syncClient
                .getBotConfig(botId)
                .timeout(const Duration(seconds: 15));
            if (remoteConfig.isNotEmpty) {
              if (remoteConfig['inboundWebhooks'] is bool) {
                remoteConfig.remove('inboundWebhooks');
              }
              if (app['avatar'] != null && remoteConfig['avatar'] == null) {
                remoteConfig['avatar'] = app['avatar'];
              }
              if (app['name'] != null && remoteConfig['name'] == null) {
                remoteConfig['name'] = app['name'];
              }
              final existingToken = (app['token'] ?? token ?? '')
                  .toString()
                  .trim();
              remoteConfig['token'] = existingToken;

              final localCommands = await appManager.listAppCommands(
                botId,
                forceRefresh: true,
              );
              final remoteCommands = extractCommandListFromConfig(
                remoteConfig['commands'],
              );
              final diff = computeBotConfigMergeDiff(
                localCommands,
                remoteCommands,
              );
              final localNewer = botConfigLocalHasNewerEdits(
                localCommands,
                remoteCommands,
              );

              if (!diff.hasChanges) {
                appendBotDebugLog(
                  '[_toggleBot] Pre-launch pull skipped: no remote updates'
                  '${diff.localOnlyCount > 0 ? ' (local-only commands preserved)' : ''}'
                  '${localNewer ? ' (local edits are newer)' : ''}',
                );
              } else if (localCommands.isEmpty ||
                  (!localNewer && diff.localOnlyCount == 0)) {
                await applyManagerConfigToLocal(
                  appManager: appManager,
                  botId: botId,
                  remoteConfig: remoteConfig,
                );
                appendBotDebugLog(
                  '[_toggleBot] Pre-launch config sync auto-applied for $botId',
                );
              } else {
                if (!mounted) return;
                final confirmed = await showBotConfigPullConfirmDialog(
                  context: context,
                  diff: diff,
                  remoteTimestamp: formatBotConfigTimestamp(remoteConfig),
                  localTimestamp: await formatLocalBotConfigTimestamp(
                    appManager,
                    botId,
                  ),
                );
                if (confirmed) {
                  await applyManagerConfigToLocal(
                    appManager: appManager,
                    botId: botId,
                    remoteConfig: remoteConfig,
                  );
                  appendBotDebugLog(
                    '[_toggleBot] Pre-launch config sync confirmed and applied for $botId',
                  );
                } else {
                  appendBotDebugLog(
                    '[_toggleBot] Pre-launch pull declined for $botId',
                  );
                }
              }
            }
          }
        } catch (e) {
          appendBotDebugLog(
            '[_toggleBot] Pre-launch config sync failed/skipped: $e',
          );
        }

        var usingRunner = runtime.client != null || runtime.blocksLocalFallback;

        if (runtime.blocksLocalFallback) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();

          final sessionRestored = await _restoreMainApiSessionWithBotToken(
            botId: botId,
            botToken: token,
          );
          if (sessionRestored) {
            runtime = await _resolveRemoteRuntime(
              botId: botId,
              getTimeout: const Duration(seconds: 30),
              postTimeout: const Duration(seconds: 90),
            );
            usingRunner = runtime.client != null || runtime.blocksLocalFallback;
          }

          if (!sessionRestored || runtime.blocksLocalFallback) {
            final message =
                runtime.unavailableReason ??
                _uiCopy(
                  fr: 'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en: 'Sign in to Bot Creator in Settings before starting this bot.',
                );
            throw Exception(message);
          }
        }

        if (!usingRunner) {
          final app = await appManager.getApp(botId);
          token = app['token']?.toString();
          if (token == null || token.trim().isEmpty) {
            throw Exception(context.tr.home_token_missing(botName));
          }

          // Token check against Discord before showing ads
          try {
            await getDiscordUser(token);
          } catch (_) {
            if (!mounted) return;
            final proceed = await AppTheme.showConfirmDialog(
              context,
              title: context.tr.bot_home_token_invalid_title,
              content: context.tr.bot_home_token_invalid_content,
              confirmLabel: context.tr.bot_home_start,
            );
            if (!proceed || !mounted) return;
          }
        }

        final adUnlocked = await _maybeOfferRewardedAd(
          botId: botId,
          botToken: token,
          successMessage: context.tr.rewarded_start_thanks,
        );
        if (!adUnlocked) {
          return;
        }
        if (!mounted) return;
      }

      // ── Runner API (API only) ─────────────────────────────────────────────
      runtime = await _resolveRemoteRuntime(
        botId: botId,
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );
      final client = runtime.client;
      if (client != null) {
        try {
          if (isRunning) {
            appendBotLog(
              'Bot stop requested',
              botId: botId,
              source: runtime.source,
            );
            await client.stopBot(botId);

            endBotLogSession(botId: botId, source: runtime.source);
            unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds}..remove(botId);
              });
            }
            setBotRuntimeActive(_runningBotIds.isNotEmpty);
          } else {
            startBotLogSession(botId: botId, source: runtime.source);
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: runtime.source,
            );
            if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
              await validateJsBotPayloadOrThrow(botId);
            }
            final payload = await buildRemotePayload(botId);
            if (client is MainApiClient) {
              final app = await appManager.getApp(botId);
              final botToken = (app['token'] ?? '').toString().trim();
              if (botToken.isNotEmpty) {
                try {
                  await client.saveDiscordBotSnapshot(
                    botId: botId,
                    botToken: botToken,
                    config: payload,
                  );
                } catch (_) {
                  // Best-effort only: do not block start if save route fails.
                }
              }
            }
            await client.syncBot(botId, botName, payload);
            if (client is MainApiClient) {
              await startManagerBotWithCreditRetry(
                client: client,
                botId: botId,
                botName: botName,
              );
              RunnerSettings.associateBotWithRunner(botId, 'manager');
            } else {
              await client.startBot(botId, botName: botName);
              final runnerConfig = await RunnerSettings.resolveConfigForBot(
                botId,
              );
              if (runnerConfig != null) {
                RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
              }
            }
            setBotRuntimeActive(true);
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds, botId};
                _runtimeSource = runtime.source;
                _runtimeDetailLabel = runtime.detailLabel;
              });
            }
          }
        } catch (error) {
          if (client is MainApiClient) {
            throw Exception(await describeManagerRuntimeFailure(client, error));
          }
          rethrow;
        }
        _syncPulse(_runningBotIds);
        await _syncDiscordRpcPresence(
          _runningBotIds,
          preferredBotId: _runningBotIds.contains(botId) ? botId : null,
          preferredBotName: _runningBotIds.contains(botId) ? botName : null,
        );
        return;
      }

      // ── Local engine ──────────────────────────────────────────────────────
      // Token already fetched and validated above; re-read if needed (stop path)
      if (token == null) {
        final app = await appManager.getApp(botId);
        token = app['token']?.toString();
      }
      if (token == null || token.trim().isEmpty) {
        throw Exception(context.tr.home_token_missing(botName));
      }

      if (!isRunning) {
        clearBotBaselineRss();
        final engine = await getBotRuntimeEngine(botId);
        final isJsDesktop =
            !_supportsForegroundTask && engine == runtimeEngineJavascript;
        if (!isJsDesktop) {
          startBotLogSession(botId: botId);
          appendBotLog('Bot start requested', botId: botId);
        }
      }

      if (_supportsForegroundTask) {
        // ── Mobile (Android / iOS) ─────────────────────────────────────────
        if (isRunning) {
          appendBotLog('Bot stop requested', botId: botId);
          await stopMobileBotSession(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
          setBotRuntimeActive(_runningBotIds.isNotEmpty);
        } else {
          // Vérifier / demander la permission de notification.
          try {
            var perm =
                await FlutterForegroundTask.checkNotificationPermission();
            if (perm != NotificationPermission.granted) {
              await FlutterForegroundTask.requestNotificationPermission();
            }
          } on MissingPluginException {
            // Continuer sans vérification sur les plateformes non supportées.
          }

          await initForegroundService(eventIntervalMs: 5000);
          await startMobileBotSession(botId: botId, token: token);

          try {
            final running = await FlutterForegroundTask.isRunningService;
            if (!running) {
              throw Exception(context.tr.home_foreground_service_not_started);
            }
          } on MissingPluginException {
            // Accepter sur les plateformes de dev.
          }

          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
        }
      } else {
        // ── Desktop (Linux / Windows / macOS) ─────────────────────────────
        if (isRunning) {
          appendBotLog(
            context.tr.home_log_desktop_stop_requested,
            botId: botId,
          );
          await stopDesktopBot(botId: botId);
          unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
          endBotLogSession(botId: botId);
          setBotRuntimeActive(
            isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
          );
          clearBotBaselineRss();
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds}..remove(botId);
            });
          }
        } else {
          if (await getBotRuntimeEngine(botId) == runtimeEngineJavascript) {
            final runnerConfig = await RunnerSettings.resolveConfigForBot(
              botId,
            );
            if (runnerConfig == null) {
              final startupDetail =
                  await RunnerSettings.embeddedRunnerStartupFailureDetail();
              final detailSuffix =
                  startupDetail == null || startupDetail.isEmpty
                  ? ''
                  : ' ($startupDetail)';
              throw Exception(
                _uiCopy(
                  fr: 'Le runner JS embarque n\'a pas pu demarrer. Relancez completement l\'application (pas un hot reload).$detailSuffix',
                  en: 'The embedded JS runner could not start. Fully restart the app (not hot reload).$detailSuffix',
                ),
              );
            }

            final client = runnerConfig.createClient();
            startBotLogSession(
              botId: botId,
              source: RemoteRuntimeSource.runner,
            );
            clearBotBaselineRss();
            appendBotLog(
              'Bot start requested',
              botId: botId,
              source: RemoteRuntimeSource.runner,
            );
            await validateJsBotPayloadOrThrow(botId);
            final payload = await buildRemotePayload(botId);
            await client.syncBot(botId, botName, payload);
            await client.startBot(botId, botName: botName);
            RunnerSettings.associateBotWithRunner(botId, runnerConfig.id);
            setBotRuntimeActive(true);
            if (mounted) {
              setState(() {
                _runningBotIds = <String>{..._runningBotIds, botId};
                _runtimeSource = RemoteRuntimeSource.runner;
                _runtimeDetailLabel = runnerConfig.name ?? runnerConfig.url;
              });
            }
            _syncPulse(_runningBotIds);
            await _syncDiscordRpcPresence(
              _runningBotIds,
              preferredBotId: botId,
              preferredBotName: botName,
            );
            return;
          }
          await startDesktopBot(token);
          if (mounted) {
            setState(() {
              _runningBotIds = <String>{..._runningBotIds, botId};
            });
          }
        }
      }

      _syncPulse(_runningBotIds);
      await _syncDiscordRpcPresence(
        _runningBotIds,
        preferredBotId: _runningBotIds.contains(botId) ? botId : null,
        preferredBotName: _runningBotIds.contains(botId) ? botName : null,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.error_with_details(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _botIdInAction = null);
    }
  }

  Future<int?> _fetchMainApiRuntimeBalance(String botId) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return null;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      return _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> _waitForMainApiRewardCredit({
    required String botId,
    required int? previousBalance,
  }) async {
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      return true;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (DateTime.now().isBefore(deadline)) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final balance = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );

        if (mounted) {
          setState(() {
            _freeMinutesByBotId = <String, int>{
              ..._freeMinutesByBotId,
              botId: balance,
            };
          });
        }

        if (previousBalance == null ||
            balance > previousBalance ||
            _hasFreeRuntimeAvailable(runtime, balance)) {
          return true;
        }
      } catch (_) {
        // Keep polling until timeout.
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    return false;
  }

  Future<bool> _ensureMainApiBotSnapshotForAd(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) {
      return false;
    }

    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    if (remoteClient == null) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager client unavailable before snapshot sync.',
      );
      return false;
    }

    final payload = await buildRemotePayload(botId);
    try {
      await remoteClient.saveDiscordBotSnapshot(
        botId: botId,
        botToken: botToken,
        config: payload,
      );
      return true;
    } catch (error) {
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: manager snapshot sync failed: $error',
      );
      return false;
    }
  }

  Future<AdRewardSsvContext?> _buildMainApiAdSsvContext(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) {
      return null;
    }

    final session = await MainApiSettingsStore.loadSession();
    final ownerId = (session?.userId ?? '').trim();
    if (ownerId.isEmpty) {
      return null;
    }

    return AdRewardSsvContext(
      userId: ownerId,
      customData: Uri(
        queryParameters: <String, String>{
          'owner_id': ownerId,
          'bot_id': botId,
          'placement': 'admob_rewarded',
        },
      ).query,
    );
  }

  Future<void> _addHostingTime(String botId) async {
    if (_botIdInAction != null) return;
    setState(() => _botIdInAction = botId);

    try {
      final app = await appManager.getApp(botId);
      final botToken = (app['token'] ?? '').toString().trim();

      final rewarded = await _maybeOfferRewardedAd(
        botId: botId,
        botToken: botToken.isNotEmpty ? botToken : null,
        force: true,
        successMessage: context.tr.home_time_added,
      );
      if (rewarded && mounted) {
        unawaited(_refreshBotRuntimeBalances(botIds: [botId]));
      }
    } finally {
      if (mounted) {
        setState(() => _botIdInAction = null);
      }
    }
  }

  Future<bool> _isMainApiPremiumUser({
    required String botId,
    String? botToken,
  }) async {
    try {
      final remoteClient = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: botToken,
        attemptSessionRestore: true,
      ).timeout(const Duration(seconds: 4), onTimeout: () => null);

      return await SubscriptionService.canSkipRewardedAdsWithTimeout(
        client: remoteClient is MainApiClient ? remoteClient : null,
        forceRefresh: true,
        allowStoredManagerSession: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _maybeOfferRewardedAd({
    required String botId,
    String? botToken,
    bool force = false,
    String? successMessage,
  }) async {
    if (!_supportsForegroundTask || !mounted) {
      return true;
    }

    if (await _isMainApiPremiumUser(botId: botId, botToken: botToken)) {
      return true;
    }

    if (!force && _displayFreeMinutesForBot(botId) > 0) {
      return true;
    }

    if (!AdRewardService.hasReadyRewardedAd) {
      // Try to load an ad on-demand and wait up to 4 seconds
      final loaded = await AdRewardService.ensureAdLoaded(
        timeout: const Duration(seconds: 4),
      );
      if (!loaded) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details(
                  context.tr.rewarded_start_no_ad_available,
                ),
              ),
            ),
          );
        }
        return false;
      }
    }

    if (!await AdRewardService.shouldOfferRewardedAd(
      checkPremiumCapability: false,
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uiCopy(
                fr: "Limite de visionnage ou cooldown actif. Veuillez réessayer plus tard.",
                en: "Ad cooldown or limit is active. Please try again later.",
              ),
            ),
          ),
        );
      }
      return false;
    }

    final consentGranted = await _ensureAdsConsent();
    if (!consentGranted && kReleaseMode) {
      return false;
    }
    if (!mounted) {
      return false;
    }

    final snapshotReady = await _ensureMainApiBotSnapshotForAd(botId);
    if (!snapshotReady) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uiCopy(
                fr: "Impossible de synchroniser la configuration du bot avec l'API principale.",
                en: "Failed to sync bot configuration with the main API.",
              ),
            ),
          ),
        );
      }
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to sync bot snapshot (/applications/@me).',
      );
      return false;
    }

    final ssvContext = await _buildMainApiAdSsvContext(botId);
    if (ssvContext == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uiCopy(
                fr: "Impossible de générer le contexte publicitaire (compte non connecté ou token manquant).",
                en: "Failed to build ad context. Please ensure you are signed in and your bot token is set.",
              ),
            ),
          ),
        );
      }
      appendBotDebugLog(
        'Rewarded ad skipped for $botId: unable to resolve Discord owner via /applications/@me.',
      );
      return false;
    }

    var rewardEarned = false;
    final adShown = await AdRewardService.showRewardedAd(
      ssvContext: ssvContext,
      onRewardEarned: () async {
        rewardEarned = true;
      },
    );
    if (!adShown) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                context.tr.rewarded_start_no_ad_available,
              ),
            ),
          ),
        );
      }
      return false;
    }

    if (!rewardEarned) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr.error_with_details(
                context.tr.rewarded_start_complete_ad,
              ),
            ),
          ),
        );
      }
      return false;
    }

    final previousBalance = await _fetchMainApiRuntimeBalance(botId);

    unawaited(() async {
      final rewardCredited = await _waitForMainApiRewardCredit(
        botId: botId,
        previousBalance: previousBalance,
      );
      if (!rewardCredited) {
        appendBotDebugLog(
          'Reward credit still pending for $botId after ad completion; start flow continues with automatic manager retry.',
        );
        return;
      }
      await _refreshBotRuntimeBalances(botIds: <String>[botId]);
    }());

    await SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true);
    if (!mounted) {
      return false;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage ?? context.tr.rewarded_start_thanks),
      ),
    );
    return true;
  }

  Future<bool> _ensureAdsConsent() async {
    final consentGranted = await AdConsentService.ensureCanRequestAds();
    if (!consentGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.ads_consent_refused_info)),
      );
    }
    return consentGranted;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<dynamic>>(
      stream: appManager.getAppStream(),
      initialData: const <dynamic>[],
      builder: (context, snapshot) {
        final apps = snapshot.data;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= AppTheme.desktopBreakpoint;
            final columns = isWide ? 2 : 1;
            final contentMaxWidth = isWide ? 1000.0 : 640.0;
            final sidePad = isWide ? 28.0 : 16.0;
            final horizontal = width > contentMaxWidth
                ? (width - contentMaxWidth) / 2 + sidePad
                : sidePad;
            final innerWidth = width - horizontal * 2;

            final children = <Widget>[
              _HomeHeader(
                onRefresh: () {
                  unawaited(triggerRefresh());
                },
                onDocs: () {
                  openDocumentationHub(context, showDiscordJsTab: true);
                },
                onSettings: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingPage()),
                  );
                },
                showCreate: isWide,
                onCreate: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AppCreatePage()),
                  );
                },
              ),
              const SizedBox(height: 22),
              if (!_isDesktop) ...[
                const _HostedAppsHomeCard(),
                const SizedBox(height: 22),
              ],
            ];

            if (snapshot.hasError) {
              developer.log(
                'Error loading data: ${snapshot.error}',
                name: 'HomePage',
              );
              children.add(
                _buildHomeInfoCard(
                  context,
                  Icons.error_outline_rounded,
                  context.tr.app_loading_error,
                ),
              );
            } else if (apps == null || apps.isEmpty) {
              children.add(const _EmptyStateWithSupport());
            } else {
              if (AdsPlacementPolicy.isPlacementEnabled(
                    NativeAdPlacement.homeBots,
                  ) &&
                  apps.length >= AdsPlacementPolicy.listInterval) {
                children.add(
                  const NativeAdSlot(
                    placement: NativeAdPlacement.homeBots,
                    height: 118,
                    margin: EdgeInsets.only(bottom: 16),
                  ),
                );
              }

              final cards = <Widget>[
                for (final app in apps)
                  _buildRedesignBotCard(
                    context,
                    app,
                    initiallyExpanded: isWide,
                  ),
              ];

              if (columns == 1) {
                for (var i = 0; i < cards.length; i++) {
                  children.add(
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: i == cards.length - 1 ? 0 : 14,
                      ),
                      child: cards[i],
                    ),
                  );
                }
              } else {
                const gap = 16.0;
                final cardWidth = (innerWidth - (columns - 1) * gap) / columns;
                children.add(
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final card in cards)
                        SizedBox(width: cardWidth, child: card),
                    ],
                  ),
                );
              }
            }

            return RefreshIndicator(
              key: _refreshIndicatorKey,
              onRefresh: () => syncAllBotsFromManager(silent: false),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  24,
                  horizontal,
                  isWide ? 40 : 120,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: children,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRedesignBotCard(
    BuildContext context,
    dynamic app, {
    required bool initiallyExpanded,
  }) {
    final name =
        app['name']?.toString().sanitizedUtf16 ?? context.tr.home_unknown_app;
    final id = app['id']?.toString() ?? '';
    final avatar = app['avatar']?.toString();
    final guildCount = switch (app['guild_count'] ??
        app['approximate_guild_count']) {
      final int value => value,
      final String s => int.tryParse(s) ?? 0,
      _ => 0,
    };
    final isRunning = _runningBotIds.contains(id);
    const runtimeToggleAllowed = true;
    final canToggle = runtimeToggleAllowed && _botIdInAction == null;
    final pulseCtrl = _getOrCreatePulseController(id);
    final freeMinutes = _displayFreeMinutesForBot(id);

    return _BotCard(
      key: ValueKey<String>(id),
      name: name,
      id: id,
      avatar: avatar,
      guildCount: guildCount,
      isRunning: isRunning,
      canToggle: canToggle,
      isTogglingThisBot: _botIdInAction == id,
      initiallyExpanded: initiallyExpanded,
      runtimeBadgeLabel: isRunning ? _runtimeBadgeLabel(id) : null,
      freeMinutes: freeMinutes,
      pulseController: pulseCtrl,
      showPremiumLabels: _supportsForegroundTask,
      onManage: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AppEditPage(appName: name, id: int.tryParse(id) ?? 0),
        ),
      ).then((_) => _initRunningState()),
      onToggle: () => _toggleBot(botId: id, botName: name),
      onAddTime: _supportsForegroundTask ? () => _addHostingTime(id) : null,
      onLogs: isRunning
          ? () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BotLogsPage(botId: id)),
            )
          : null,
    );
  }

  Widget _buildHomeInfoCard(
    BuildContext context,
    IconData icon,
    String message,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

// ── En-tête d'accueil ─────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.onRefresh,
    required this.onDocs,
    required this.onSettings,
    this.onCreate,
    this.showCreate = false,
  });

  final VoidCallback onRefresh;
  final VoidCallback onDocs;
  final VoidCallback onSettings;
  final VoidCallback? onCreate;
  final bool showCreate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr.home_overline,
                style: TextStyle(
                  color: scheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr.app_title,
                  maxLines: 1,
                  softWrap: false,
                  style: GoogleFonts.syne(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (showCreate && onCreate != null) ...[
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text(context.tr.app_create_button),
          ),
          const SizedBox(width: 12),
        ],
        _HeaderIconButton(
          icon: Icons.sync_rounded,
          tooltip: context.tr.common_refresh,
          onTap: onRefresh,
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.menu_book_rounded,
          tooltip: context.tr.docs_hub_title,
          onTap: onDocs,
        ),
        const SizedBox(width: 10),
        _HeaderIconButton(
          icon: Icons.settings_rounded,
          tooltip: context.tr.settings_tab,
          onTap: onSettings,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(13),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

Color _botColor(String seed) {
  var hash = 0;
  for (final unit in seed.codeUnits) {
    hash = (hash * 31 + unit) & 0x7fffffff;
  }
  final hue = (hash % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, 0.5, 0.66).toColor();
}

class _BrandIconSquare extends StatelessWidget {
  const _BrandIconSquare({
    required this.icon,
    this.size = 48,
    this.imageUrl,
    this.tint,
  });

  final IconData icon;
  final double size;
  final String? imageUrl;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final tintColor = tint;

    Widget fallbackIcon() => Icon(
      icon,
      color: tintColor ?? scheme.onSurfaceVariant,
      size: size * 0.5,
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: hasImage
            ? scheme.surfaceContainerHigh
            : (tintColor != null
                  ? tintColor.withValues(alpha: 0.18)
                  : scheme.surfaceContainerHigh),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasImage
              ? scheme.outlineVariant
              : (tintColor != null
                    ? tintColor.withValues(alpha: 0.38)
                    : scheme.outlineVariant),
        ),
      ),
      child: hasImage
          ? Image.network(
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              gaplessPlayback: true,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Center(child: fallbackIcon());
              },
              errorBuilder: (_, _, _) => Center(child: fallbackIcon()),
            )
          : fallbackIcon(),
    );
  }
}

// ── Carte bot (collapsible) ───────────────────────────────────────────────────

class _BotCard extends StatefulWidget {
  const _BotCard({
    super.key,
    required this.name,
    required this.id,
    required this.avatar,
    required this.guildCount,
    required this.isRunning,
    required this.canToggle,
    required this.isTogglingThisBot,
    required this.initiallyExpanded,
    required this.pulseController,
    required this.onManage,
    required this.onToggle,
    required this.onAddTime,
    required this.onLogs,
    required this.showPremiumLabels,
    this.runtimeBadgeLabel,
    this.freeMinutes,
  });

  final String name;
  final String id;
  final String? avatar;
  final int? guildCount;
  final bool isRunning;
  final bool canToggle;
  final bool isTogglingThisBot;
  final bool initiallyExpanded;
  final String? runtimeBadgeLabel;
  final int? freeMinutes;
  final AnimationController pulseController;
  final bool showPremiumLabels;
  final VoidCallback onManage;
  final VoidCallback onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onLogs;

  @override
  State<_BotCard> createState() => _BotCardState();
}

class _BotCardState extends State<_BotCard> {
  bool _hovered = false;
  late bool _expanded = widget.initiallyExpanded;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  String _startLabel(BuildContext context) {
    if (widget.isRunning) return context.tr.home_stop;
    if (!widget.showPremiumLabels) return context.tr.bot_home_start;
    if (SubscriptionService.isSubscribed) return context.tr.home_start_premium;
    if ((widget.freeMinutes ?? 0) > 0) return context.tr.bot_home_start;
    return context.tr.home_start_ads;
  }

  String _serverCountLabel(BuildContext context) {
    final count = widget.guildCount ?? 0;
    return count > 1
        ? context.tr.home_server_count_other(count)
        : context.tr.home_server_count_one(count);
  }

  bool get _showAddHosting =>
      widget.isRunning &&
      !SubscriptionService.isSubscribed &&
      widget.onAddTime != null;

  Widget _buildExpandedContent(BuildContext context, ColorScheme scheme) {
    final chips = <Widget>[
      _InfoChip(
        icon: Icons.dns_rounded,
        value: _serverCountLabel(context),
      ),
    ];

    if (widget.showPremiumLabels) {
      if (SubscriptionService.isSubscribed) {
        chips.add(
          _InfoChip(
            icon: Icons.all_inclusive_rounded,
            value: context.tr.hosted_app_subscription_benefit_unlimited,
            badge: true,
          ),
        );
      } else if (widget.freeMinutes != null) {
        chips.add(
          _InfoChip(
            icon: Icons.bolt_rounded,
            value: formatHostingDuration(context, widget.freeMinutes!),
          ),
        );
      }
    }

    if (widget.runtimeBadgeLabel != null) {
      chips.add(
        _InfoChip(
          icon: Icons.dns_outlined,
          value: widget.runtimeBadgeLabel!,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
        const SizedBox(height: 14),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _CardActionButton(
                icon: widget.isRunning
                    ? Icons.stop_rounded
                    : Icons.play_arrow_rounded,
                label: _startLabel(context),
                onTap: widget.canToggle ? widget.onToggle : null,
                loading: widget.isTogglingThisBot,
                accent: widget.isRunning ? AppTheme.danger : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _CardActionButton(
                icon: Icons.tune_rounded,
                label: context.tr.home_manage,
                onTap: widget.onManage,
              ),
            ),
          ],
        ),
        if (_showAddHosting) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _CardActionButton(
              icon: Icons.add_rounded,
              label: context.tr.home_add_time,
              onTap: widget.canToggle ? widget.onAddTime : null,
              accent: AppTheme.brandPrimary,
              foreground: AppTheme.brandPurpleSoft,
            ),
          ),
        ],
        if (widget.onLogs != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: _CardActionButton(
              icon: Icons.article_outlined,
              label: context.tr.home_logs_tooltip,
              onTap: widget.onLogs,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final Color borderTop = (widget.isRunning
            ? AppTheme.brandPurpleSoft
            : Colors.white)
        .withValues(
          alpha: _hovered ? 0.50 : (widget.isRunning ? 0.30 : 0.14),
        );
    final Color borderBottom = Colors.white.withValues(
      alpha: _hovered ? 0.16 : 0.04,
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [borderTop, borderBottom],
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    spreadRadius: -4,
                    offset: const Offset(0, 14),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(1),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _cardGradient(scheme, widget.isRunning, _hovered),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard - 1),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard - 1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AvatarSquare(
                          seed: widget.name,
                          imageUrl: widget.avatar,
                          isRunning: widget.isRunning,
                          pulseController: widget.pulseController,
                          showBadge: false,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _displayStyle(
                              16.5,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _StatusPill(
                          isRunning: widget.isRunning,
                          pulseController: widget.pulseController,
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            Icons.expand_more_rounded,
                            color: scheme.onSurfaceVariant,
                            size: 22,
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
      ),
    );
  }
}

TextStyle _displayStyle(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w700,
}) {
  return GoogleFonts.syne(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: -0.2,
  );
}

Gradient _cardGradient(ColorScheme scheme, bool isRunning, bool hovered) {
  final top = isRunning
      ? Color.alphaBlend(
          AppTheme.brandPrimary.withValues(alpha: 0.18),
          scheme.surfaceContainerHigh,
        )
      : scheme.surfaceContainerHigh;
  final bottom = scheme.surfaceContainer;
  final lift = hovered ? 0.06 : 0.0;
  Color raise(Color c) =>
      Color.alphaBlend(Colors.white.withValues(alpha: lift), c);
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [raise(top), raise(bottom)],
  );
}

class _AvatarSquare extends StatelessWidget {
  const _AvatarSquare({
    required this.seed,
    required this.imageUrl,
    required this.isRunning,
    required this.pulseController,
    this.showBadge = true,
  });

  final String seed;
  final String? imageUrl;
  final bool isRunning;
  final AnimationController pulseController;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _BrandIconSquare(
            icon: Icons.smart_toy_rounded,
            size: 50,
            imageUrl: imageUrl,
            tint: _botColor(seed),
          ),
          if (showBadge)
            Positioned(
              top: -4,
              right: -4,
              child: AnimatedBuilder(
                animation: pulseController,
                builder: (_, _) {
                  final glow =
                      isRunning ? 0.4 + 0.6 * pulseController.value : 1.0;
                  final dotColor =
                      isRunning ? AppTheme.online : scheme.onSurfaceVariant;
                  return Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scheme.surface,
                    ),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: dotColor,
                        boxShadow: isRunning
                            ? [
                                BoxShadow(
                                  color: AppTheme.online.withValues(
                                    alpha: 0.8 * glow,
                                  ),
                                  blurRadius: 9,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CardActionButton extends StatelessWidget {
  const _CardActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.accent,
    this.foreground,
    this.loading = false,
  });

  static const double _height = 40;

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? accent;
  final Color? foreground;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color fg = foreground ?? accent ?? scheme.onSurface;
    final Color borderColor =
        accent != null ? accent!.withValues(alpha: 0.45) : scheme.outline;
    final Color? bg = accent?.withValues(alpha: 0.12);
    final bool enabled = onTap != null && !loading;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            height: _height,
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fg,
                    ),
                  )
                else
                  Icon(icon, size: 16, color: fg),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isRunning, required this.pulseController});

  final bool isRunning;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color color = isRunning ? AppTheme.online : scheme.onSurfaceVariant;
    final label = isRunning
        ? context.tr.home_status_online
        : context.tr.home_status_offline;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, _) {
              final glow = isRunning ? 0.4 + 0.6 * pulseController.value : 0.0;
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: isRunning
                      ? [
                          BoxShadow(
                            color: AppTheme.online.withValues(alpha: 0.8 * glow),
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
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.value,
    this.label,
    this.badge = false,
  });

  final IconData icon;
  final String value;
  final String? label;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badge
            ? AppTheme.dataAccent.withValues(alpha: 0.12)
            : scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(
          color: badge
              ? AppTheme.dataAccent.withValues(alpha: 0.35)
              : scheme.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: badge ? AppTheme.dataAccent : AppTheme.metaText,
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
                  color: AppTheme.dataAccent,
                ),
                children: [
                  TextSpan(text: value),
                  if (label != null)
                    TextSpan(
                      text: ' $label',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.metaText,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state avec CTA support ──────────────────────────────────────────

class _EmptyStateWithSupport extends StatelessWidget {
  const _EmptyStateWithSupport();

  static const _discordUrl = 'https://discord.gg/gyEGNBUZdA';
  static const _discordColor = AppTheme.discord;

  Future<void> _openDiscord() async {
    final uri = Uri.parse(_discordUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr.app_no_apps,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            context.tr.home_empty_support_hint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openDiscord,
            icon: const Icon(Icons.forum_rounded, size: 18),
            label: Text(context.tr.home_empty_support_btn),
            style: FilledButton.styleFrom(
              backgroundColor: _discordColor,
              foregroundColor: Colors.white,
              textStyle: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _HostedAppsHomeCard extends StatefulWidget {
  const _HostedAppsHomeCard();

  @override
  State<_HostedAppsHomeCard> createState() => _HostedAppsHomeCardState();
}

class _HostedAppsHomeCardState extends State<_HostedAppsHomeCard> {
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final session = await MainApiSettingsStore.loadSession();
    if (mounted) {
      setState(() => _hasSession = session != null && !session.isExpired);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasSession) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContainerListPage()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: scheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const _BrandIconSquare(icon: Icons.smart_toy_rounded, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.container_list_title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.tr.container_hosted_subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}


class _BotSyncResult {
  const _BotSyncResult({
    required this.botId,
    required this.botName,
    required this.token,
    required this.config,
    required this.bot,
    required this.guildCount,
    this.avatarHash,
    this.discriminator,
  });

  final String botId;
  final String botName;
  final String token;
  final Map<String, dynamic> config;
  final Map<String, dynamic> bot;
  final int? guildCount;
  final String? avatarHash;
  final String? discriminator;
}
