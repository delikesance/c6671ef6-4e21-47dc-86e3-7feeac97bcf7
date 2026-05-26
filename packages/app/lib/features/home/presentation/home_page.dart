import 'dart:async';
import 'dart:io';
import 'package:bot_creator/core/network/main_api_owner_sync.dart';
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
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/discord_rpc/logic/discord_rpc_service.dart';
import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/features/ads/logic/ad_consent_service.dart';
import 'package:bot_creator/features/ads/logic/ads_placement_policy.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/app_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';

String _formatHostingDuration(BuildContext context, int totalMinutes) {
  if (totalMinutes <= 0) {
    return context.tr.unit_minute(0);
  }

  const minutesPerHour = 60;
  const minutesPerDay = minutesPerHour * 24;
  const minutesPerMonth = minutesPerDay * 30;

  var remaining = totalMinutes;
  final months = remaining ~/ minutesPerMonth;
  remaining %= minutesPerMonth;
  final days = remaining ~/ minutesPerDay;
  remaining %= minutesPerDay;
  final hours = remaining ~/ minutesPerHour;
  remaining %= minutesPerHour;
  final minutes = remaining;

  final parts = <String>[];
  if (months > 0) {
    parts.add(context.tr.unit_month(months));
  }
  if (days > 0) {
    parts.add(context.tr.unit_day(days));
  }
  if (hours > 0) {
    parts.add(context.tr.unit_hour(hours));
  }
  if (minutes > 0 || parts.isEmpty) {
    parts.add(context.tr.unit_minute(minutes));
  }

  return parts.join(', ');
}

Color _hostingTimeColor(BuildContext context, int minutes) {
  const minutesPerDay = 60 * 24; // 1440
  const minutesThreeDays = minutesPerDay * 3; // 4320

  if (minutes < minutesPerDay) return AppTheme.error;
  if (minutes < minutesThreeDays) return AppTheme.warning;
  return AppTheme.successAccent;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
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
  Timer? _statusRefreshTimer;

  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  bool get _isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  bool get _supportsManagerRuntime => !kIsWeb && !_isDesktop;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
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
      await syncAllBotsFromManager(silent: true);
    }());

    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        _initRunningState();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _statusRefreshTimer?.cancel();
    for (final ctrl in _pulseControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncAllBotsFromManager(silent: true);
    }
  }

  // ── Initialisation de l'état running ───────────────────────────────────────

  Future<void> _initRunningState() async {
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

    final hasActiveRemote = remoteClient != null || remoteRuntime.client != null;
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
                        _runtimeSourceByBotId[botId] = RemoteRuntimeSource.local;
                        _runtimeDetailLabelByBotId[botId] = null;
                      });
                    }
                    return botId;
                  }

                   final perBotClient = await _resolveMainApiClientForBot(
                    botId: botId,
                    attemptSessionRestore: true,
                  );
                  final botRuntime = await _resolveRemoteRuntime(botId: botId);
                  
                  final associatedId = RunnerSettings.getAssociatedRunnerId(botId);
                  final isManagerBot = associatedId == 'manager' || (associatedId == null && perBotClient != null);
                  
                  final source = isManagerBot ? RemoteRuntimeSource.manager : botRuntime.source;
                  final detailLabel = isManagerBot ? (remoteRuntime.detailLabel ?? 'Bot Creator servers') : botRuntime.detailLabel;

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
                  appendBotDebugLog(
                    '[_initRunningState] Bot $botId status fetched: statusRunning=${status.running}, activeBotId=${status.activeBotId ?? 'none'}, botEntries=${status.bots.length}, isBotRunning=$isRunning.',
                  );
                  return isRunning ? botId : null;
                } catch (error) {
                  appendBotDebugLog(
                    'Failed to sync running status for $botId: $error',
                  );
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
        setState(() => _freeMinutesByBotId = <String, int>{});
      }
      return;
    }

    final ids = <String>{...?(botIds?.where((id) => id.trim().isNotEmpty))};
    if (ids.isEmpty) {
      final names = await _loadBotNamesById();
      ids.addAll(names.keys.where((id) => id.trim().isNotEmpty));
    }
    if (ids.isEmpty) {
      return;
    }

    final updated = <String, int>{..._freeMinutesByBotId};
    for (final botId in ids) {
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final minutes = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );
        updated[botId] = minutes;
      } catch (_) {
        // Best-effort refresh only.
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _freeMinutesByBotId = updated;
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
        '[syncAllBotsFromManager] Aborted: global manager client unavailable. Fetching running states directly.',
      );
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
      final fetchedOwners = <String>{};
      for (final rawApp in apps) {
        if (rawApp is! Map) {
          continue;
        }
        final app = Map<String, dynamic>.from(rawApp.cast<dynamic, dynamic>());
        final botId = (app['id'] ?? '').toString().trim();
        if (botId.isEmpty) {
          continue;
        }
        final token = (app['token'] ?? '').toString();
        final client = await _resolveMainApiClientForBot(
          botId: botId,
          botToken: token,
          attemptSessionRestore: true,
        );
        if (client == null) {
          appendBotDebugLog(
            '[syncAllBotsFromManager] No manager client for local bot $botId during owner expansion.',
          );
          continue;
        }

        final session = await MainApiSettingsStore.loadSession();
        final ownerKey = (session?.userId ?? '').trim();
        final dedupeKey = ownerKey.isEmpty ? 'bot:$botId' : 'owner:$ownerKey';
        if (fetchedOwners.contains(dedupeKey)) {
          appendBotDebugLog(
            '[syncAllBotsFromManager] Owner already fetched for dedupeKey=$dedupeKey, skipping duplicate listBots call.',
          );
          continue;
        }
        fetchedOwners.add(dedupeKey);
        appendBotDebugLog(
          '[syncAllBotsFromManager] Fetching listBots for dedupeKey=$dedupeKey using client=${client.runtimeType}.',
        );
        mergeBots(await client.listBots());
      }

      final bots = botsById.values.toList(growable: false);
      appendBotDebugLog(
        '[syncAllBotsFromManager] Total merged bot payloads=${bots.length}.',
      );
      for (final bot in bots) {
        try {
          final botId = bot['bot_id']?.toString() ?? '';
          if (botId.isEmpty) continue;

          final botName = bot['bot_name']?.toString() ?? 'Unnamed Bot';
          final config = bot['config'] as Map<String, dynamic>? ?? {};

          // Prefer manager token if available, otherwise use local token
          String token = bot['bot_token']?.toString() ?? '';
          if (token.isEmpty) {
            final existing = await appManager.getApp(botId);
            token = (existing['token'] ?? '').toString();
          }

          int? fetchedApproxGuildCount;
          if (token.trim().isNotEmpty) {
            try {
              final snapshotClient = await _resolveMainApiClientForBot(
                botId: botId,
                botToken: token,
                attemptSessionRestore: true,
              );
              if (snapshotClient != null) {
                final payload = await buildBotPayload(botId);
                await snapshotClient.saveDiscordBotSnapshot(
                  botToken: token,
                  config: payload,
                );
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Bot $botId snapshot synced before status refresh.',
                );
              } else {
                appendBotDebugLog(
                  '[syncAllBotsFromManager] Bot $botId snapshot sync skipped: manager client unavailable.',
                );
              }
            } catch (error) {
              appendBotDebugLog(
                '[syncAllBotsFromManager] Bot $botId snapshot sync failed before status refresh: $error',
              );
            }

            try {
              final ownerMetadata =
                  await getDiscordApplicationOwnerMetadata(token);
              if (ownerMetadata != null) {
                final approx = ownerMetadata.rawJson['approximate_guild_count'];
                if (approx is int) {
                  fetchedApproxGuildCount = approx;
                } else if (approx != null) {
                  fetchedApproxGuildCount = int.tryParse(approx.toString());
                }
              }
            } catch (error) {
              appendBotDebugLog(
                '[syncAllBotsFromManager] Failed to fetch Discord application owner metadata for $botId: $error',
              );
            }
          }

          await appManager.createOrUpdateApp(
            id: Snowflake.parse(botId),
            username: botName,
            avatarHash:
                bot['avatar_hash']?.toString() ?? bot['avatar']?.toString(),
            discriminator: bot['discriminator']?.toString(),
            token: token,
            intents: (config['intents'] as Map?)?.cast<String, bool>(),
            prefix: config['prefix']?.toString(),
            approximateGuildCount: fetchedApproxGuildCount,
          );
          appendBotDebugLog(
            '[syncAllBotsFromManager] Bot $botId persisted locally (name=$botName).',
          );
        } catch (e) {
          developer.log('Failed to sync bot ${bot['bot_id']}: $e');
          appendBotDebugLog(
            '[syncAllBotsFromManager] Failed to sync bot ${bot['bot_id']}: $e',
          );
        }
      }

      if (mounted) {
        appendBotDebugLog(
          '[syncAllBotsFromManager] Triggering _initRunningState after bot sync.',
        );
        await _initRunningState();
      }
    } catch (e) {
      appendBotDebugLog('[syncAllBotsFromManager] Sync failed: $e');
      if (mounted) {
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
    final detailLabel = _runtimeDetailLabelByBotId[botId] ?? _runtimeDetailLabel;
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

    var session = await MainApiSettingsStore.loadSession();
    if (session != null && session.isExpired && session.refreshToken != null) {
      try {
        appendBotDebugLog(
          '[_resolveGlobalMainApiClient] Global session expired; attempting to refresh.',
        );
        final client = MainApiClient(
          baseUrl: config.baseUrl,
          timeout: const Duration(seconds: 5),
        );
        final newSession = await client.refreshSession(
          refreshToken: session.refreshToken!,
        );
        await MainApiSettingsStore.saveSession(newSession);
        session = newSession;
        appendBotDebugLog(
          '[_resolveGlobalMainApiClient] Global session refreshed successfully.',
        );
      } catch (error) {
        appendBotDebugLog(
          '[_resolveGlobalMainApiClient] Global session refresh failed: $error.',
        );
      }
    }

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
        '[_resolveGlobalMainApiClient] Global manager client unavailable; trying restore from ${apps.length} local apps.',
      );
      for (final rawApp in apps) {
        if (rawApp is! Map) continue;
        final botId = (rawApp['id'] ?? '').toString();
        final token = (rawApp['token'] ?? '').toString();
        if (botId.isNotEmpty && token.isNotEmpty) {
          appendBotDebugLog(
            '[_resolveGlobalMainApiClient] Trying restore with bot $botId.',
          );
          final client = await _resolveMainApiClientForBot(
            botId: botId,
            botToken: token,
            attemptSessionRestore: true,
          );
          if (client != null) {
            appendBotDebugLog(
              '[_resolveGlobalMainApiClient] Success: global client restored from bot $botId.',
            );
            return client;
          }
        }
      }
      appendBotDebugLog(
        '[_resolveGlobalMainApiClient] Failed to restore global client from any local app.',
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
        getTimeout: const Duration(seconds: 30),
        postTimeout: const Duration(seconds: 90),
      );

      // ── Fetch + validate token before anything else (only when starting) ──
      String? token;
      if (!isRunning) {
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
              getTimeout: const Duration(seconds: 30),
              postTimeout: const Duration(seconds: 90),
            );
            usingRunner = runtime.client != null || runtime.blocksLocalFallback;
          }

          if (!sessionRestored || runtime.blocksLocalFallback) {
            final message =
                runtime.unavailableReason ??
                _uiCopy(
                  fr:
                      'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en:
                      'Sign in to Bot Creator in Settings before starting this bot.',
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
            final payload = await buildBotPayload(botId);
            if (client is MainApiClient) {
              final app = await appManager.getApp(botId);
              final botToken = (app['token'] ?? '').toString().trim();
              if (botToken.isNotEmpty) {
                try {
                  await client.saveDiscordBotSnapshot(
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
              final runnerConfig = await RunnerSettings.getConfig();
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
        startBotLogSession(botId: botId);
        appendBotLog('Bot start requested', botId: botId);
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

    final payload = await buildBotPayload(botId);
    try {
      await remoteClient.saveDiscordBotSnapshot(
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
      customData:
          Uri(
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

    if (!force && (_freeMinutesByBotId[botId] ?? 0) > 0) {
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
                fr:
                    "Limite de visionnage ou cooldown actif. Veuillez réessayer plus tard.",
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
                fr:
                    "Impossible de synchroniser la configuration du bot avec l'API principale.",
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
                fr:
                    "Impossible de générer le contexte publicitaire (compte non connecté ou token manquant).",
                en:
                    "Failed to build ad context. Please ensure you are signed in and your bot token is set.",
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
        final useIOSPhoneLayout = isIOS && width < 600;
        final int crossAxisCount;
        final double horizontalPadding;
        // Responsive grid based on screen width
        if (width < 480) {
          // Phone - single column
          crossAxisCount = 1;
          horizontalPadding = isIOS ? 8.0 : 12.0;
        } else if (width < 600) {
          // Mobile - 2 columns
          crossAxisCount = 2;
          horizontalPadding = isIOS ? 8.0 : 12.0;
        } else if (width >= 1500) {
          // Extra large desktop - 5 columns
          crossAxisCount = 5;
          horizontalPadding = 24.0;
        } else if (width >= 1200) {
          // Large desktop - 4 columns
          crossAxisCount = 4;
          horizontalPadding = 24.0;
        } else if (width >= 900) {
          // Tablet - 3 columns
          crossAxisCount = 3;
          horizontalPadding = 20.0;
        } else if (width >= 760) {
          // Medium tablet - 3 columns
          crossAxisCount = 3;
          horizontalPadding = 16.0;
        } else {
          // Small tablet - 2 columns
          crossAxisCount = 2;
          horizontalPadding = isIOS ? 12.0 : 16.0;
        }

        final effectiveCrossAxisCount = useIOSPhoneLayout ? 1 : crossAxisCount;
        final listHorizontalPadding =
            useIOSPhoneLayout
                ? 6.0
                : isIOS
                ? 10.0
                : 14.0;
        final contentWidth =
            width - (horizontalPadding * 2) - (listHorizontalPadding * 2);

        final cardWidth =
            (contentWidth - ((effectiveCrossAxisCount - 1) * 12)) /
            effectiveCrossAxisCount;

        return Padding(
          padding: EdgeInsets.all(horizontalPadding),
          child: StreamBuilder<List<dynamic>>(
            stream: appManager.getAppStream(),
            initialData: const <dynamic>[],
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                developer.log(
                  'Error loading data: ${snapshot.error}',
                  name: 'HomePage',
                );
                return Center(child: Text(context.tr.app_loading_error));
              }

              final apps = snapshot.data;
              if (apps == null || apps.isEmpty) {
                return const _EmptyStateWithSupport();
              }

              return Column(
                children: [

                  if (AdsPlacementPolicy.isPlacementEnabled(
                        NativeAdPlacement.homeBots,
                      ) &&
                      apps.length >= AdsPlacementPolicy.listInterval)
                    const NativeAdSlot(
                      placement: NativeAdPlacement.homeBots,
                      height: 118,
                      margin: EdgeInsets.only(bottom: 12),
                    ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => syncAllBotsFromManager(silent: false),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(
                          bottom: 80,
                          left: listHorizontalPadding,
                          right: listHorizontalPadding,
                        ),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children:
                                apps.map((app) {
                                  final name =
                                      app['name']?.toString() ??
                                      context.tr.home_unknown_app;
                                  final id = app['id']?.toString() ?? '';
                                  final avatar = app['avatar']?.toString();
                                  final guildCount =
                                      switch (app['approximate_guild_count'] ??
                                          app['guild_count']) {
                                        final int value => value,
                                        final String s => int.tryParse(s) ?? 0,
                                        _ => 0,
                                      };

                                  final isRunning = _runningBotIds.contains(id);

                                  const runtimeToggleAllowed = true;

                                  final canToggle =
                                      runtimeToggleAllowed &&
                                      _botIdInAction == null;

                                  final pulseCtrl = _getOrCreatePulseController(
                                    id,
                                  );

                                  return SizedBox(
                                    width: cardWidth,
                                    child: _BotCard(
                                      name: name,
                                      id: id,
                                      avatar: avatar,
                                      guildCount: guildCount,
                                      compact: width < 760,
                                      isRunning: isRunning,
                                      canToggle: canToggle,
                                      isTogglingThisBot: _botIdInAction == id,
                                      runtimeBadgeLabel:
                                          isRunning
                                              ? _runtimeBadgeLabel(id)
                                              : null,
                                      freeMinutes: _freeMinutesByBotId[id],
                                      pulseController: pulseCtrl,
                                      onManage:
                                          () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) => AppEditPage(
                                                    appName: name,
                                                    id: int.tryParse(id) ?? 0,
                                                  ),
                                            ),
                                          ).then((_) => _initRunningState()),
                                      onToggle:
                                          () => _toggleBot(
                                            botId: id,
                                            botName: name,
                                          ),
                                      onAddTime:
                                          _supportsForegroundTask
                                              ? () => _addHostingTime(id)
                                              : null,
                                      showPremiumLabels:
                                          _supportsForegroundTask,
                                      onLogs:
                                          isRunning
                                              ? () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) => BotLogsPage(
                                                        botId: id,
                                                      ),
                                                ),
                                              )
                                              : null,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ── Widget carte ─────────────────────────────────────────────────────────────

class _BotCard extends StatelessWidget {
  const _BotCard({
    required this.name,
    required this.id,
    required this.avatar,
    required this.guildCount,
    required this.compact,
    required this.isRunning,
    required this.canToggle,
    required this.isTogglingThisBot,
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
  final bool compact;
  final bool isRunning;
  final bool canToggle;
  final bool isTogglingThisBot;
  final String? runtimeBadgeLabel;
  final int? freeMinutes;
  final AnimationController pulseController;
  final bool showPremiumLabels;
  final VoidCallback onManage;
  final VoidCallback onToggle;
  final VoidCallback? onAddTime;
  final VoidCallback? onLogs;

  static const _onlineGradient = AppTheme.botCardOnlineGradient;
  static const _offlineGradient = AppTheme.botCardOfflineGradient;

  String _serverCountLabel(BuildContext context) {
    final count = guildCount ?? 0;
    return count > 1
        ? context.tr.home_server_count_other(count)
        : context.tr.home_server_count_one(count);
  }

  @override
  Widget build(BuildContext context) {
    final avatarRadius = compact ? 24.0 : 34.0;
    final avatarFallbackSize = compact ? 48.0 : 68.0;
    final titleFontSize = compact ? 13.0 : 16.0;
    final buttonVerticalPadding = compact ? 4.0 : 10.0;

    final gradientColors = isRunning ? _onlineGradient : _offlineGradient;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      elevation: isRunning ? 8 : 3,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 10.0 : 14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Status badge pill ──────────────────────────────────────────
              Align(
                alignment: Alignment.topRight,
                child: AnimatedBuilder(
                  animation: pulseController,
                  builder: (_, _) {
                    final opacity =
                        isRunning ? 0.5 + 0.5 * pulseController.value : 1.0;
                    return Opacity(
                      opacity: opacity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusPill,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isRunning
                                        ? AppTheme.successAccent
                                        : AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isRunning
                                  ? context.tr.home_status_online
                                  : context.tr.home_status_offline,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // ── Avatar + Identity ──────────────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: compact ? 8 : 12),
                  // Avatar with glow ring when running
                  Container(
                    decoration:
                        isRunning
                            ? BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.successAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            )
                            : null,
                    child:
                        avatar != null && avatar!.isNotEmpty
                            ? CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  avatar!,
                                  width: avatarRadius * 2,
                                  height: avatarRadius * 2,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, _, _) => Icon(
                                        Icons.smart_toy_rounded,
                                        size: avatarFallbackSize * 0.6,
                                        color: Colors.white70,
                                      ),
                                ),
                              ),
                            )
                            : CircleAvatar(
                              radius: avatarRadius,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.1,
                              ),
                              child: Icon(
                                Icons.smart_toy_rounded,
                                size: avatarFallbackSize * 0.6,
                                color: Colors.white70,
                              ),
                            ),
                  ),

                  SizedBox(height: compact ? 8 : 14),

                  // Name
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 2),

                  // Server count + runner label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _serverCountLabel(context),
                        style: TextStyle(
                          fontSize: compact ? 10.5 : 11.0,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),

                  // Runner badge (hidden in compact to save space)
                  if (runtimeBadgeLabel != null && !compact) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.dns_outlined,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              runtimeBadgeLabel!,
                              style: TextStyle(
                                fontSize: compact ? 9.0 : 9.5,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!SubscriptionService.isSubscribed &&
                      freeMinutes != null &&
                      onAddTime != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      context.tr.home_hosting_time_left(
                        _formatHostingDuration(context, freeMinutes!),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: compact ? 10 : 11,
                        color: _hostingTimeColor(
                          context,
                          freeMinutes!,
                        ).withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),

              // ── Action buttons ─────────────────────────────────────────────
              SizedBox(height: compact ? 10 : 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canToggle ? onToggle : null,
                  icon:
                      isTogglingThisBot
                          ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(
                            isRunning
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 16,
                          ),
                  label: Text(
                    isRunning
                        ? context.tr.home_stop
                        : (!showPremiumLabels
                            ? context.tr.bot_home_start
                            : (SubscriptionService.isSubscribed
                                ? context.tr.home_start_premium
                                : ((freeMinutes ?? 0) > 0
                                    ? context.tr.bot_home_start
                                    : context.tr.home_start_ads))),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        isRunning
                            ? Colors.white.withValues(alpha: 0.2)
                            : AppTheme.success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.1,
                    ),
                    disabledForegroundColor: Colors.white38,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                    padding: EdgeInsets.symmetric(
                      vertical: buttonVerticalPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),

              if (isRunning &&
                  !SubscriptionService.isSubscribed &&
                  onAddTime != null) ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canToggle ? onAddTime : null,
                    icon:
                        isTogglingThisBot
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.more_time_rounded, size: 16),
                    label: Text(context.tr.home_add_time),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      padding: EdgeInsets.symmetric(
                        vertical: buttonVerticalPadding,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ],

              SizedBox(height: compact ? 4 : 6),

              // Manage + Logs row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onManage,
                      icon: const Icon(Icons.tune_rounded, size: 14),
                      label: Text(context.tr.home_manage),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.15),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                        padding: EdgeInsets.symmetric(
                          vertical: buttonVerticalPadding,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onLogs,
                    icon: const Icon(Icons.article_outlined, size: 18),
                    tooltip: context.tr.home_logs_tooltip,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor:
                          onLogs != null
                              ? Colors.white.withValues(alpha: 0.8)
                              : Colors.white.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
      ),
    );
  }
}


