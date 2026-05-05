import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_logs.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/debug_replay_page.dart';
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/ads/logic/ad_reward_service.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
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
  final List<QuickAccessSection> secondarySections;
  const AppHomePage({
    super.key,
    required this.client,
    this.onNavigateToSection,
    this.secondarySections = const [],
  });

  @override
  State<AppHomePage> createState() => _AppHomePageState();
}

class _AppHomePageState extends State<AppHomePage>
    with TickerProviderStateMixin {
  String _appName = "";
  NyxxRest? client; // Changez en nullable
  String avatar = "";
  bool _botLaunched = false;
  bool _botStarting = false;
  int? _freeMinutesBalance;
  bool _isAddingTime = false;
  bool _isSyncingApp = false;
  void Function(Object)? _taskDataCallback;

  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  bool get _supportsManagerRuntime => !kIsWeb;

  String _uiCopy({required String fr, required String en}) {
    return Localizations.localeOf(context).languageCode == 'fr' ? fr : en;
  }



  Color _hostingTimeColor(int minutes) {
    const minutesPerDay = 60 * 24; // 1440
    const minutesThreeDays = minutesPerDay * 3; // 4320

    if (minutes < minutesPerDay) return AppTheme.error;
    if (minutes < minutesThreeDays) return AppTheme.warning;
    return AppTheme.successAccent;
  }

  bool _isDeadChannelError(Object error) {
    if (error is! PlatformException) return false;
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();
    return code.contains('channel') ||
        message.contains('dead channel') ||
        message.contains('unable to establish connection on channel') ||
        details.contains('dead channel') ||
        details.contains('unable to establish connection on channel');
  }

  Future<bool> _requestPermissions() async {
    if (!_supportsForegroundTask) {
      return true;
    }

    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    try {
      var notificationPermission =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermission != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
        notificationPermission =
            await FlutterForegroundTask.checkNotificationPermission();
      }

      if (notificationPermission != NotificationPermission.granted) {
        return false;
      }

      if (Platform.isAndroid) {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      }
    } on MissingPluginException {
      // No-op on unsupported platforms.
      return true;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        debugPrint('Foreground permission channel unavailable; skipping.');
        return true;
      }
      rethrow;
    }

    return true;
  }

  Future<void> _initService() async {
    if (!_supportsForegroundTask) {
      return;
    }

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ResolvedRemoteRuntime> _resolveRemoteRuntime({
    Duration getTimeout = const Duration(seconds: 30),
    Duration postTimeout = const Duration(seconds: 90),
  }) async {
    return resolveRemoteRuntime(
      supportsManagerRuntime: _supportsManagerRuntime,
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

  Future<DiscordApplicationOwnerMetadata?>
  _resolveDiscordOwnerMetadataForBotStart({
    required String botId,
    required String? token,
  }) async {
    return _ownerSyncHelper.resolveDiscordOwnerMetadataForBotStart(
      botId: botId,
      token: token,
    );
  }

  Future<bool> _restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
    String? preferredOwnerId,
    Iterable<String> acceptableOwnerIds = const <String>[],
  }) async {
    return _ownerSyncHelper.restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: botToken,
      preferredOwnerId: preferredOwnerId,
      acceptableOwnerIds: acceptableOwnerIds,
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    return _ownerSyncHelper.resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: attemptSessionRestore,
    );
  }

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
      // Initialize service configuration.
      _initService();
    });
    _init();
  }

  @override
  void dispose() {
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

  Future<void> _init() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog('[AppHome._init] Starting init for botId=$botId.');
    final app = await appManager.getApp(botId);
    var isRunning = false;

    // Use a short timeout for the initial check — we don't want to block the
    // UI for 30 s just to find out the session needs restoring.
    var remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 5),
      postTimeout: const Duration(seconds: 10),
    );
    var remoteClient = remoteRuntime.client;

    if (remoteClient == null &&
        remoteRuntime.source == RemoteRuntimeSource.manager) {
      final token = (app['token'] ?? '').toString().trim();
      if (token.isNotEmpty) {
        appendBotDebugLog(
          '[AppHome._init] Manager client missing; restoring session directly via bot token.',
        );
        final restored = await _ownerSyncHelper
            .restoreMainApiSessionWithBotToken(botId: botId, botToken: token)
            .timeout(
              const Duration(seconds: 8),
              onTimeout: () {
                appendBotDebugLog(
                  '[AppHome._init] Session restore timed out (8s); continuing without manager.',
                );
                return false;
              },
            );
        if (restored) {
          appendBotDebugLog(
            '[AppHome._init] Manager session restored successfully via bot token.',
          );
          remoteRuntime = await _resolveRemoteRuntime(
            getTimeout: const Duration(seconds: 5),
            postTimeout: const Duration(seconds: 10),
          );
          remoteClient = remoteRuntime.client;
        } else {
          appendBotDebugLog('[AppHome._init] Manager session restore failed.');
        }
      }
    }

    appendBotDebugLog(
      '[AppHome._init] Runtime resolved: source=${remoteRuntime.source}, hasClient=${remoteClient != null}, blocksLocalFallback=${remoteRuntime.blocksLocalFallback}, detail=${remoteRuntime.detailLabel ?? 'none'}.',
    );
    unawaited(
      SubscriptionService.resolveEffectivePremiumStatus(
        client: remoteClient is MainApiClient ? remoteClient : null,
        forceRefresh: true,
      ),
    );
    if (remoteClient != null) {
      try {
        appendBotDebugLog(
          '[AppHome._init] Fetching per-bot status via ${remoteClient.runtimeType} for botId=$botId.',
        );
        final status = await remoteClient.getStatus(botId: botId);
        appendBotDebugLog(
          '[AppHome._init] Status fetched: running=${status.running}, activeBotId=${status.activeBotId ?? 'none'}, botEntries=${status.bots.length}.',
        );
        isRunning = status.isBotRunning(botId);
        appendBotDebugLog(
          '[AppHome._init] Bot running evaluation from remote status: botId=$botId, isRunning=$isRunning.',
        );
      } catch (_) {
        appendBotDebugLog(
          '[AppHome._init] Failed to fetch remote status; defaulting isRunning=false.',
        );
        isRunning = false;
      }
    } else if (remoteRuntime.blocksLocalFallback) {
      appendBotDebugLog(
        '[AppHome._init] Local fallback blocked and no remote client available; forcing isRunning=false.',
      );
      isRunning = false;
    } else {
      if (_supportsForegroundTask) {
        try {
          appendBotDebugLog(
            '[AppHome._init] Using foreground-task fallback for botId=$botId.',
          );
          final readyIds = await getReadyMobileBotIds();
          appendBotDebugLog(
            '[AppHome._init] Ready mobile ids=${readyIds.join(',')}.',
          );
          if (readyIds.contains(botId) || isMobileBotRunning(botId)) {
            isRunning = true;
            appendBotDebugLog(
              '[AppHome._init] Marked running from readyIds/isMobileBotRunning.',
            );
          } else {
            final configuredIds = await getConfiguredMobileBotIds();
            final serviceRunning = await FlutterForegroundTask.isRunningService;
            // Fallback: if the bot is configured and the foreground service is
            // alive, keep Home state consistent when navigating between pages.
            isRunning = serviceRunning && configuredIds.contains(botId);
            appendBotDebugLog(
              '[AppHome._init] Foreground fallback computed isRunning=$isRunning (serviceRunning=$serviceRunning, configuredIds=${configuredIds.join(',')}).',
            );
          }
        } on MissingPluginException {
          appendBotDebugLog(
            '[AppHome._init] Foreground plugin unavailable; forcing isRunning=false.',
          );
          isRunning = false;
        } on PlatformException catch (error) {
          if (_isDeadChannelError(error)) {
            appendBotDebugLog(
              '[AppHome._init] Dead channel during foreground lookup; forcing isRunning=false. error=$error',
            );
            isRunning = false;
          } else {
            rethrow;
          }
        } catch (_) {
          appendBotDebugLog(
            '[AppHome._init] Unexpected foreground fallback error; forcing isRunning=false.',
          );
          isRunning = false;
        }
      } else {
        isRunning = isDesktopBotRunningId(botId);
        appendBotDebugLog(
          '[AppHome._init] Desktop fallback isRunning=$isRunning for botId=$botId.',
        );
      }
    }

    appendBotDebugLog(
      '[AppHome._init] Final running decision for botId=$botId isRunning=$isRunning.',
    );

    await AppAnalytics.logScreenView(
      screenName: "AppHomePage",
      screenClass: "AppHomePage",
      parameters: {
        "app_name": app["name"],
        "app_id": botId,
        "is_running": isRunning ? "true" : "false",
      },
    );
    setState(() {
      _botLaunched = isRunning;
      _botStarting = false;
      _appName = app["name"];
      avatar = app["avatar"] ?? "";
    });
    appendBotDebugLog(
      '[AppHome._init] State updated: botLaunched=$_botLaunched, appName=$_appName.',
    );

    unawaited(_refreshFreeRuntimeBalance());
    unawaited(_syncAppFromRemote(showSnack: false));
    appendBotDebugLog('[AppHome._init] Init completed for botId=$botId.');
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

  Future<void> _refreshFreeRuntimeBalance() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog(
      '[_refreshFreeRuntimeBalance] Fetching runtime balance for botId=$botId.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] No MainApiClient available (source=${remoteRuntime.source}); balance cleared.',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _freeMinutesBalance = null;
      });
      return;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      final balance = _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
      final sessionActive =
          runtime['session_active'] ?? runtime['sessionActive'];
      final fundingMode =
          runtime['funding_mode'] ?? runtime['fundingMode'] ?? '';
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] botId=$botId balance=$balance '
        'session_active=$sessionActive funding_mode=$fundingMode.',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _freeMinutesBalance = balance;
      });
    } catch (error) {
      appendBotDebugLog(
        '[_refreshFreeRuntimeBalance] getBotRuntime failed for botId=$botId: $error',
      );
      // Keep UI resilient if runtime endpoint is temporarily unavailable.
    }
  }

  Future<void> _syncAppFromRemote({required bool showSnack}) async {
    if (_isSyncingApp) {
      return;
    }

    _isSyncingApp = true;
    try {
      final user = await widget.client.user.get();
      final botId = user.id.toString();
      final app = await appManager.getApp(botId);
      final token = (app['token'] ?? '').toString().trim();
      if (token.isEmpty) {
        throw Exception('Token not found');
      }

      await appManager.createOrUpdateApp(
        id: user.id,
        username: user.username,
        avatarHash: user.avatarHash,
        discriminator: user.discriminator.toString(),
        token: token,
      );

      try {
        final remoteCommands = await widget.client.commands.list(
          withLocalizations: true,
        );

        // Build an index of all local commands to reconcile temp IDs.
        final allLocal = await appManager.listAppCommands(botId);
        final reconciledLocalIds = <String>{};

        for (final command in remoteCommands) {
          final commandId = command.id.toString();
          var local = await appManager.getAppCommand(botId, commandId);

          // If no local match by Discord ID, find by name+type to reconcile
          // commands that were created offline with a temporary ID.
          if (local.isEmpty) {
            final commandType =
                command.type == ApplicationCommandType.user
                    ? 'user'
                    : command.type == ApplicationCommandType.message
                    ? 'message'
                    : 'chatinput';
            final match = allLocal.cast<Map<String, dynamic>?>().firstWhere((
              c,
            ) {
              final localId = (c!['id'] ?? '').toString();
              if (reconciledLocalIds.contains(localId)) return false;
              if (localId == commandId) return false;
              // Never reconcile legacy-only commands — they are local-only
              // and must not be absorbed into a Discord command.
              final localData = (c['data'] as Map?)?.cast<String, dynamic>();
              if (localData != null &&
                  localData['legacyModeEnabled'] == true &&
                  localData['legacyLocalOnly'] == true) {
                return false;
              }
              final localName = (c['name'] ?? '').toString();
              final localType =
                  (c['type'] ?? 'chatInput').toString().toLowerCase();
              return localName == command.name && localType == commandType;
            }, orElse: () => null);

            if (match != null) {
              final oldId = (match['id'] ?? '').toString();
              local = match;
              reconciledLocalIds.add(oldId);
              // Remove the orphaned file with the temp ID.
              await appManager.deleteAppCommand(botId, oldId);
            }
          }

          final merged = <String, dynamic>{
            ...local,
            'id': commandId,
            'name': command.name,
            'description': command.description,
          };
          await appManager.saveAppCommand(botId, commandId, merged);
        }
      } catch (_) {
        // Keep profile sync resilient even if remote command fetch fails.
      }

      final refreshed = await appManager.getApp(botId);
      if (mounted) {
        setState(() {
          _appName = (refreshed['name'] ?? _appName).toString();
          avatar = (refreshed['avatar'] ?? avatar).toString();
        });
      }

      if (showSnack && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.bot_home_sync_success)),
        );
      }
    } catch (e) {
      if (showSnack && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      _isSyncingApp = false;
    }
  }

  Future<int?> _fetchMainApiRuntimeBalance(String botId) async {
    appendBotDebugLog(
      '[_fetchMainApiRuntimeBalance] Fetching runtime balance for botId=$botId.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      appendBotDebugLog(
        '[_fetchMainApiRuntimeBalance] No MainApiClient (source=${remoteRuntime.source}); returning null.',
      );
      return null;
    }

    try {
      final runtime = await remoteClient.getBotRuntime(botId);
      final balance = _extractFreeMinutes(
        runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
      );
      final sessionActive =
          runtime['session_active'] ?? runtime['sessionActive'];
      appendBotDebugLog(
        '[_fetchMainApiRuntimeBalance] botId=$botId balance=$balance session_active=$sessionActive.',
      );
      return balance;
    } catch (error) {
      appendBotDebugLog(
        '[_fetchMainApiRuntimeBalance] getBotRuntime failed for botId=$botId: $error',
      );
      return null;
    }
  }

  Future<bool> _waitForMainApiRewardCredit({
    required String botId,
    required int? previousBalance,
  }) async {
    appendBotDebugLog(
      '[_waitForMainApiRewardCredit] Starting poll for botId=$botId previousBalance=$previousBalance.',
    );
    final remoteRuntime = await _resolveRemoteRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final remoteClient = remoteRuntime.client;
    if (remoteClient is! MainApiClient) {
      appendBotDebugLog(
        '[_waitForMainApiRewardCredit] No MainApiClient (source=${remoteRuntime.source}); skipping poll.',
      );
      return true;
    }

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    var attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      attempt++;
      try {
        final runtime = await remoteClient.getBotRuntime(botId);
        final balance = _extractFreeMinutes(
          runtime['free_minutes_balance'] ?? runtime['freeMinutesBalance'],
        );
        final sessionActive =
            runtime['session_active'] ?? runtime['sessionActive'];
        final fundingMode =
            runtime['funding_mode'] ?? runtime['fundingMode'] ?? '';
        appendBotDebugLog(
          '[_waitForMainApiRewardCredit] attempt=$attempt botId=$botId '
          'balance=$balance session_active=$sessionActive funding_mode=$fundingMode.',
        );

        if (mounted) {
          setState(() {
            _freeMinutesBalance = balance;
          });
        }

        if ((previousBalance != null && balance > previousBalance) ||
            _hasFreeRuntimeAvailable(runtime, balance)) {
          appendBotDebugLog(
            '[_waitForMainApiRewardCredit] Credit confirmed at attempt=$attempt for botId=$botId.',
          );
          return true;
        }
      } catch (error) {
        appendBotDebugLog(
          '[_waitForMainApiRewardCredit] getBotRuntime error at attempt=$attempt for botId=$botId: $error',
        );
        // Keep polling until timeout.
      }

      await Future<void>.delayed(const Duration(seconds: 1));
    }

    appendBotDebugLog(
      '[_waitForMainApiRewardCredit] Timed out after $attempt attempts for botId=$botId.',
    );
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
    final ownerIdFromSession = (session?.userId ?? '').trim();
    final ownerMetadata = await getDiscordApplicationOwnerMetadata(botToken);
    final ownerIdFromDiscord = ownerMetadata?.resolveOwnerId() ?? '';

    if (ownerMetadata != null &&
        ownerMetadata.matchesOwnerId(ownerIdFromSession)) {
      if (ownerIdFromSession.isNotEmpty &&
          ownerIdFromSession != ownerIdFromDiscord) {
        appendBotDebugLog(
          'Owner reconciliation for $botId: keeping manager session owner $ownerIdFromSession because it is a valid Discord team owner/member.',
        );
      }
    } else if (ownerIdFromSession.isNotEmpty &&
        ownerIdFromDiscord.isNotEmpty &&
        ownerIdFromSession != ownerIdFromDiscord) {
      appendBotDebugLog(
        'Owner mismatch for $botId: using discord application owner $ownerIdFromDiscord instead of manager session owner $ownerIdFromSession for ad mapping.',
      );
    }

    final ownerId =
        ownerMetadata?.resolveOwnerId(preferredOwnerId: ownerIdFromSession) ??
        ownerIdFromSession;
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
              if (ownerIdFromDiscord.isNotEmpty)
                'discord_owner_id': ownerIdFromDiscord,
            },
          ).query,
    );
  }

  Future<void> _addRuntimeTime() async {
    if (_isAddingTime || _botStarting) {
      return;
    }

    final botId = widget.client.user.id.toString();
    final previousBalance = _freeMinutesBalance;
    setState(() {
      _isAddingTime = true;
    });

    try {
      final unlocked = await _maybeOfferRewardedAd(
        botId: botId,
        previousBalance: previousBalance,
      );
      if (!unlocked) {
        if (mounted) {
          setState(() {
            _freeMinutesBalance = previousBalance;
          });
        }
        return;
      }

      final rewardCredited = await _waitForMainApiRewardCredit(
        botId: botId,
        previousBalance: previousBalance,
      );
      await _refreshFreeRuntimeBalance();

      if (!rewardCredited && mounted) {
        await showDialog<void>(
          context: context,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(
                  _uiCopy(fr: 'Crédit en cours', en: 'Credit is still syncing'),
                ),
                content: Text(
                  _uiCopy(
                    fr:
                        'La récompense pub est en cours de synchronisation. Réessaie le démarrage dans quelques secondes.',
                    en:
                        'Your ad reward is still syncing. Try starting the bot again in a few seconds.',
                  ),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(_uiCopy(fr: 'OK', en: 'OK')),
                  ),
                ],
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTime = false;
        });
      }
    }
  }

  Future<bool> _isMainApiPremiumUser({
    required String botId,
    String? botToken,
  }) async {
    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    return SubscriptionService.canSkipRewardedAds(
      client: remoteClient is MainApiClient ? remoteClient : null,
      forceRefresh: true,
      allowStoredManagerSession: false,
    );
  }

  Future<bool> _maybeOfferRewardedAd({
    required String botId,
    String? botToken,
    int? previousBalance,
  }) async {
    try {
      if (!_supportsForegroundTask || !mounted) {
        return true;
      }

      if (await _isMainApiPremiumUser(botId: botId, botToken: botToken)) {
        return true;
      }

      if (!AdRewardService.hasReadyRewardedAd) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details('rewarded_start_no_ad_available'),
              ),
            ),
          );
        }
        return false;
      }

      final snapshotReady = await _ensureMainApiBotSnapshotForAd(botId);
      if (!snapshotReady) {
        appendBotDebugLog(
          'Rewarded ad skipped for $botId: unable to sync bot snapshot (/applications/@me).',
        );
        return false;
      }

      final ssvContext = await _buildMainApiAdSsvContext(botId);
      if (ssvContext == null) {
        appendBotDebugLog(
          'Rewarded ad skipped for $botId: unable to resolve Discord owner via /applications/@me.',
        );
        return false;
      }

      final shouldOffer = await AdRewardService.shouldOfferRewardedAd(
        checkPremiumCapability: false,
      ).timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!shouldOffer) {
        return false;
      }

      final consentGranted = await _ensureAdsConsent().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
      if (!consentGranted || !mounted) {
        return false;
      }

      if (kDebugMode) {
        final shouldWatch = await AppTheme.showConfirmDialog(
          context,
          title: context.tr.rewarded_start_title,
          content: context.tr.rewarded_start_message,
          cancelLabel: context.tr.rewarded_start_skip,
          confirmLabel: context.tr.rewarded_start_watch,
        );

        if (!shouldWatch || !mounted) {
          return false;
        }
      } else {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder:
              (dialogContext) => AlertDialog(
                title: Text(context.tr.rewarded_start_title),
                content: Text(context.tr.rewarded_start_message),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: Text(context.tr.rewarded_start_continue),
                  ),
                ],
              ),
        );
      }

      final effectivePreviousBalance =
          previousBalance ?? await _fetchMainApiRuntimeBalance(botId);

      var rewardEarned = false;
      final adShown = await AdRewardService.showRewardedAd(
        ssvContext: ssvContext,
        onRewardEarned: () async {
          rewardEarned = true;
        },
      );
      if (!adShown || !rewardEarned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details('rewarded_start_complete_ad'),
              ),
            ),
          );
        }
        return false;
      }

      unawaited(() async {
        final rewardCredited = await _waitForMainApiRewardCredit(
          botId: botId,
          previousBalance: effectivePreviousBalance,
        );
        if (!rewardCredited) {
          appendBotDebugLog(
            'Reward credit still pending for $botId after ad completion; start flow continues with automatic manager retry.',
          );
          return;
        }
        await _refreshFreeRuntimeBalance();
      }());

      await SubscriptionService.resolveEffectivePremiumStatus(
        forceRefresh: true,
      );

      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.rewarded_start_thanks)));
      return true;
    } catch (error) {
      appendBotDebugLog('Rewarded ad flow skipped due to error: $error');
      return false;
    }
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

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingLg,
              AppTheme.spacingMd,
              AppTheme.spacingLg,
              AppTheme.spacingSm,
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: colorScheme.primary),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: AppTheme.spacingXs),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
    Widget? trailing,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
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
          final showQuickAccess = constraints.maxWidth < 900;
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
                      // Bot avatar with gradient ring
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
                            child:
                                avatar.isNotEmpty
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
                      if (Platform.isIOS) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(
                              color: AppTheme.warning.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.info_outline,
                                  color: AppTheme.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.tr.bot_home_ios_notice_title,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr.bot_home_ios_notice_content,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: AppTheme.spacingXl),
                      // ── Start / Stop Bot ──────────────────────────
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor:
                              _botLaunched
                                  ? AppTheme.error
                                  : _botStarting
                                  ? AppTheme.warning
                                  : AppTheme.success,
                          minimumSize: const Size.fromHeight(48),
                          shape: AppTheme.buttonShape,
                        ),
                        onPressed:
                            _botStarting
                                ? null
                                : () async {
                                  try {
                                    final app = await appManager.getApp(
                                      widget.client.user.id.toString(),
                                    );
                                    final token = app["token"]?.toString();
                                    if (token == null || token.trim().isEmpty) {
                                      throw Exception("Token not found");
                                    }

                                    final botId =
                                        widget.client.user.id.toString();

                                    if (_botLaunched) {
                                      final shouldStop =
                                          await AppTheme.showConfirmDialog(
                                            context,
                                            title: _uiCopy(
                                              fr: 'Arrêter le bot ?',
                                              en: 'Stop this bot?',
                                            ),
                                            content: _uiCopy(
                                              fr:
                                                  'Si une session gratuite est en cours, le temps restant peut être perdu. Continuer ?',
                                              en:
                                                  'If a free runtime session is active, remaining time may be lost. Continue?',
                                            ),
                                            confirmLabel: _uiCopy(
                                              fr: 'Arrêter',
                                              en: 'Stop',
                                            ),
                                            icon: Icons.warning_amber_rounded,
                                          );
                                      if (!shouldStop || !mounted) {
                                        return;
                                      }
                                    }

                                    var remoteRuntime =
                                        await _resolveRemoteRuntime(
                                          getTimeout: const Duration(
                                            seconds: 30,
                                          ),
                                          postTimeout: const Duration(
                                            seconds: 90,
                                          ),
                                        );

                                    if (!_botLaunched &&
                                        remoteRuntime.blocksLocalFallback) {
                                      final ownerMetadata =
                                          await _resolveDiscordOwnerMetadataForBotStart(
                                            botId: botId,
                                            token: token,
                                          );
                                      final session =
                                          await MainApiSettingsStore.loadSession();
                                      final preferredOwnerId = ownerMetadata
                                          ?.resolveOwnerId(
                                            preferredOwnerId: session?.userId,
                                          );

                                      final sessionRestored =
                                          await _restoreMainApiSessionWithBotToken(
                                            botId: botId,
                                            botToken: token,
                                            preferredOwnerId: preferredOwnerId,
                                            acceptableOwnerIds:
                                                ownerMetadata
                                                    ?.ownerCandidateIds ??
                                                const <String>[],
                                          );

                                      if (sessionRestored) {
                                        remoteRuntime =
                                            await _resolveRemoteRuntime(
                                              getTimeout: const Duration(
                                                seconds: 30,
                                              ),
                                              postTimeout: const Duration(
                                                seconds: 90,
                                              ),
                                            );
                                      }

                                      if (remoteRuntime.blocksLocalFallback) {
                                        final baseMessage =
                                            remoteRuntime.unavailableReason ??
                                            _uiCopy(
                                              fr:
                                                  'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                                              en:
                                                  'Sign in to Bot Creator in Settings before starting this bot.',
                                            );

                                        final message =
                                            ownerMetadata == null ||
                                                    ownerMetadata
                                                        .ownerCandidateIds
                                                        .isEmpty
                                                ? baseMessage
                                                : '$baseMessage\nDiscord owners: ${ownerMetadata.candidatesLabel}';

                                        throw Exception(message);
                                      }
                                    }

                                    if (!_botLaunched) {
                                      if (remoteRuntime.client == null) {
                                        try {
                                          await getDiscordUser(token);
                                        } catch (_) {
                                          if (!mounted) return;
                                          final proceed =
                                              await AppTheme.showConfirmDialog(
                                                context,
                                                title:
                                                    context
                                                        .tr
                                                        .bot_home_token_invalid_title,
                                                content:
                                                    context
                                                        .tr
                                                        .bot_home_token_invalid_content,
                                                confirmLabel:
                                                    context.tr.bot_home_start,
                                              );
                                          if (!proceed || !mounted) return;
                                        }
                                      }
                                      if (SubscriptionService.isSubscribed) {
                                        await SubscriptionService.syncStatusWithBackend(
                                          force: true,
                                        );
                                      }

                                      final adUnlocked =
                                          await _maybeOfferRewardedAd(
                                            botId: botId,
                                            botToken: token,
                                          );
                                      if (!adUnlocked) {
                                        return;
                                      }
                                    }

                                    // ── Runner API (API only) ────────────────────────────
                                    final remoteClient = remoteRuntime.client;

                                    if (remoteClient != null) {
                                      try {
                                        if (_botLaunched) {
                                          appendBotLog(
                                            'Bot stop requested',
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          await remoteClient.stopBot(botId);
                                          endBotLogSession(
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          setBotRuntimeActive(false);
                                          if (mounted) {
                                            setState(
                                              () => _botLaunched = false,
                                            );
                                          }
                                        } else {
                                          startBotLogSession(
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          clearBotBaselineRss();
                                          appendBotLog(
                                            'Bot start requested',
                                            botId: botId,
                                            source: remoteRuntime.source,
                                          );
                                          final payload = await buildBotPayload(
                                            botId,
                                          );
                                          if (remoteClient is MainApiClient) {
                                            final botToken = token.trim();
                                            if (botToken.isNotEmpty) {
                                              try {
                                                await remoteClient
                                                    .saveDiscordBotSnapshot(
                                                      botToken: botToken,
                                                      config: payload,
                                                    );
                                              } catch (_) {
                                                // Best-effort only: do not block start if save route fails.
                                              }
                                            }
                                          }
                                          await remoteClient.syncBot(
                                            botId,
                                            _appName,
                                            payload,
                                          );
                                          if (remoteClient is MainApiClient) {
                                            await startManagerBotWithCreditRetry(
                                              client: remoteClient,
                                              botId: botId,
                                              botName: _appName,
                                            );
                                            RunnerSettings.associateBotWithRunner(
                                              botId,
                                              'manager',
                                            );
                                          } else {
                                            await remoteClient.startBot(
                                              botId,
                                              botName: _appName,
                                            );
                                            final runnerConfig =
                                                await RunnerSettings.getConfig();
                                            if (runnerConfig != null) {
                                              RunnerSettings.associateBotWithRunner(
                                                botId,
                                                runnerConfig.id,
                                              );
                                            }
                                          }
                                          setBotRuntimeActive(true);
                                          if (mounted) {
                                            setState(() => _botLaunched = true);
                                          }
                                        }
                                      } catch (error) {
                                        if (remoteClient is MainApiClient) {
                                          throw Exception(
                                            await describeManagerRuntimeFailure(
                                              remoteClient,
                                              error,
                                            ),
                                          );
                                        }
                                        rethrow;
                                      }
                                      return;
                                    }

                                    // ── Local engine ─────────────────────────────────
                                    if (!_botLaunched) {
                                      clearBotBaselineRss();
                                      startBotLogSession(botId: botId);
                                      appendBotLog(
                                        'Bot start requested',
                                        botId: botId,
                                      );
                                    }

                                    if (_supportsForegroundTask) {
                                      if (_botLaunched) {
                                        appendBotLog(
                                          'Bot stop requested',
                                          botId: botId,
                                        );
                                        await stopMobileBotSession(
                                          botId: botId,
                                        );
                                        endBotLogSession(botId: botId);
                                        setBotRuntimeActive(
                                          isDesktopBotRunning ||
                                              mobileRunningBotIds.isNotEmpty,
                                        );
                                        if (mounted) {
                                          setState(() {
                                            _botLaunched = false;
                                            _botStarting = false;
                                          });
                                        }
                                        return;
                                      }

                                      final permissionGranted =
                                          await _requestPermissions();
                                      if (!permissionGranted) {
                                        throw Exception(
                                          context.tr.bot_home_notif_required,
                                        );
                                      }
                                      await _initService();

                                      await startMobileBotSession(
                                        botId: botId,
                                        token: token,
                                      );
                                      developer.log(
                                        'Token saved, starting foreground service',
                                        name: 'AppHomePage',
                                      );

                                      final running =
                                          await FlutterForegroundTask
                                              .isRunningService;
                                      if (!running) {
                                        throw Exception(
                                          context
                                              .tr
                                              .bot_home_service_not_started,
                                        );
                                      }

                                      if (mounted) {
                                        setState(() {
                                          _botLaunched = false;
                                          _botStarting = true;
                                        });
                                      }
                                    } else {
                                      if (_botLaunched) {
                                        appendBotLog(
                                          context.tr.bot_home_log_desktop_stop,
                                          botId: botId,
                                        );
                                        await stopDesktopBot(botId: botId);
                                        endBotLogSession(botId: botId);
                                        setBotRuntimeActive(
                                          isDesktopBotRunning ||
                                              mobileRunningBotIds.isNotEmpty,
                                        );
                                        clearBotBaselineRss();
                                        if (mounted) {
                                          setState(() {
                                            _botLaunched = false;
                                            _botStarting = false;
                                          });
                                        }
                                        return;
                                      }

                                      await startDesktopBot(token);
                                    }

                                    if (mounted) {
                                      setState(() {
                                        _botLaunched = !_supportsForegroundTask;
                                        _botStarting = false;
                                      });
                                    }
                                  } on PlatformException catch (error) {
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _botStarting = false;
                                    });
                                    final deadChannel = _isDeadChannelError(
                                      error,
                                    );
                                    final display =
                                        deadChannel
                                            ? 'Foreground service channel unavailable. Please reopen the app and try again.'
                                            : error.toString();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr.bot_home_start_error(
                                            display,
                                          ),
                                        ),
                                      ),
                                    );
                                  } catch (e) {
                                    if (!mounted) {
                                      return;
                                    }
                                    setState(() {
                                      _botStarting = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          context.tr.bot_home_start_error(
                                            e.toString(),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
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
                      if (_supportsForegroundTask) ...[
                        const SizedBox(height: AppTheme.spacingMd),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusLg,
                            ),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  context.tr.home_hosting_time_left(
                                    formatDuration(_freeMinutesBalance ?? 0),
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _hostingTimeColor(
                                      _freeMinutesBalance ?? 0,
                                    ).withValues(alpha: 0.95),
                                  ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed:
                                    _isAddingTime ? null : _addRuntimeTime,
                                icon:
                                    _isAddingTime
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
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: AppTheme.spacingXl),
                      // ── Premiers pas (Getting Started) ──────────────────────────
                      if (widget.onNavigateToSection != null)
                        _buildSection(
                          icon: Icons.rocket_launch_outlined,
                          title: context.tr.bot_home_section_getting_started,
                          children: [
                            _buildActionTile(
                              icon: Icons.tune,
                              label: context.tr.bot_home_customize,
                              onTap: () => widget.onNavigateToSection!(8),
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
                      // ── Quick access to secondary sections (mobile) ──
                      if (showQuickAccess &&
                          widget.secondarySections.isNotEmpty &&
                          widget.onNavigateToSection != null) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 4,
                                  bottom: 10,
                                ),
                                child: Text(
                                  context.tr.quick_access_title,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              GridView.count(
                                crossAxisCount: 3,
                                mainAxisSpacing: 10,
                                crossAxisSpacing: 10,
                                childAspectRatio: 1.12,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  for (
                                    var i = 0;
                                    i <
                                        widget.secondarySections.length.clamp(
                                          0,
                                          3,
                                        );
                                    i++
                                  )
                                    _QuickAccessChip(
                                      icon: widget.secondarySections[i].icon,
                                      label:
                                          widget.secondarySections[i].labelKey,
                                      onTap:
                                          () => widget.onNavigateToSection!(
                                            widget.secondarySections[i].index,
                                          ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingSm),
                      ],
                      // ── Monitoring section ──────────────────────────
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
                          if (PremiumCapabilities.isCapabilityRolledOut(
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
                                    builder:
                                        (_) => DebugReplayPage(botId: botId),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // ── Tools section ──────────────────────────
                      _buildSection(
                        icon: Icons.build_outlined,
                        title: context.tr.bot_home_section_tools,
                        children: [
                          _buildActionTile(
                            icon: Icons.sync,
                            label: context.tr.bot_home_sync,
                            onTap:
                                _isSyncingApp
                                    ? null
                                    : () async {
                                      await _syncAppFromRemote(showSnack: true);
                                      unawaited(
                                        refreshBotRuntime(
                                          widget.client.user.id.toString(),
                                        ),
                                      );
                                    },
                            trailing:
                                _isSyncingApp
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
                      // ── Danger zone ──────────────────────────
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
                              await appManager.deleteApp(
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
  
  String formatDuration(int i) {
    final hours = i ~/ 60;
    final minutes = i % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

class _QuickAccessChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
