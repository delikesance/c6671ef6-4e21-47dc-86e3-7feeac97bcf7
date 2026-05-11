part of 'home.dart';

extension _AppHomePageLogic on _AppHomePageState {
  bool get _supportsForegroundTask => Platform.isAndroid || Platform.isIOS;
  bool get _supportsManagerRuntime => !kIsWeb;

  Future<bool> _requestPermissions() async {
    if (!_supportsForegroundTask) {
      return true;
    }

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

  Future<void> _init() async {
    final botId = widget.client.user.id.toString();
    appendBotDebugLog('[AppHome._init] Starting init for botId=$botId.');
    final app = await appManager.getApp(botId);
    var isRunning = false;

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
    if (mounted) {
      _setState(() {
        _botLaunched = isRunning;
        _botStarting = false;
        _appName = app["name"];
        avatar = app["avatar"] ?? "";
      });
    }
    appendBotDebugLog(
      '[AppHome._init] State updated: botLaunched=$_botLaunched, appName=$_appName.',
    );

    unawaited(_refreshFreeRuntimeBalance());
    unawaited(_syncAppFromRemote(showSnack: false));
    appendBotDebugLog('[AppHome._init] Init completed for botId=$botId.');
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
}
