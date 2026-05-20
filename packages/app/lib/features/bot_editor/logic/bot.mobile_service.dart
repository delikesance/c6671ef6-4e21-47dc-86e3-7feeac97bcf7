part of 'bot.dart';

const String _mobileSessionsDataKey = 'mobile_bot_sessions';
const String _mobileReadyBotIdsDataKey = 'mobile_ready_bot_ids';
const String _mobileCommandTypeKey = 'type';
const String _mobileCommandSyncSessions = 'mobile_sessions_sync';
const String _mobileCommandReloadBot = 'mobile_bot_reload';
const String _mobileCommandSyncFlags = 'mobile_flags_sync';
const Duration _mobileSessionSyncRetryDelay = Duration(milliseconds: 250);
const int _mobileSessionSyncRetryCount = 6;
const Duration _mobileServiceStartupPollDelay = Duration(milliseconds: 150);
const Duration _mobileServiceStartupTimeout = Duration(seconds: 5);
final MobileSessionsOrchestrator _mobileSessionsOrchestrator =
    MobileSessionsOrchestrator();

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

Future<bool> _safeIsRunningForegroundService() async {
  try {
    return await FlutterForegroundTask.isRunningService;
  } on MissingPluginException {
    return false;
  } on PlatformException catch (error) {
    if (_isDeadChannelError(error)) {
      return false;
    }
    rethrow;
  }
}

Map<String, String> _normalizeMobileSessionsMap(dynamic raw) {
  if (raw is! Map) {
    return <String, String>{};
  }
  final normalized = <String, String>{};
  raw.forEach((key, value) {
    final botId = key.toString().trim();
    final token = value?.toString().trim() ?? '';
    if (botId.isEmpty || token.isEmpty) {
      return;
    }
    normalized[botId] = token;
  });
  return normalized;
}

Future<Map<String, String>> _readConfiguredMobileSessions({
  bool allowLegacyFallback = true,
}) async {
  try {
    final raw = await FlutterForegroundTask.getData<dynamic>(
      key: _mobileSessionsDataKey,
    );
    final mapped = _normalizeMobileSessionsMap(raw);
    if (mapped.isNotEmpty) {
      return mapped;
    }
  } catch (_) {}

  if (!allowLegacyFallback) {
    return <String, String>{};
  }

  // Legacy single-bot fallback.
  try {
    final token = await FlutterForegroundTask.getData<String>(key: 'token');
    final runningBotId = await FlutterForegroundTask.getData<String>(
      key: 'running_bot_id',
    );
    if (runningBotId != null &&
        runningBotId.trim().isNotEmpty &&
        token != null &&
        token.trim().isNotEmpty) {
      return <String, String>{runningBotId.trim(): token.trim()};
    }
  } catch (_) {}

  return <String, String>{};
}

Future<Map<String, String>> _readConfiguredMobileSessionsAfterStartup() async {
  for (var attempt = 0; attempt < _mobileSessionSyncRetryCount; attempt++) {
    final configured = await _readConfiguredMobileSessions(
      allowLegacyFallback: false,
    );
    if (configured.isNotEmpty) {
      return configured;
    }
    if (attempt < _mobileSessionSyncRetryCount - 1) {
      await Future<void>.delayed(_mobileSessionSyncRetryDelay);
    }
  }

  return _readConfiguredMobileSessions();
}

Future<void> _writeConfiguredMobileSessions(
  Map<String, String> sessions,
) async {
  final sanitized = <String, String>{};
  for (final entry in sessions.entries) {
    final botId = entry.key.trim();
    final token = entry.value.trim();
    if (botId.isEmpty || token.isEmpty) {
      continue;
    }
    sanitized[botId] = token;
  }

  try {
    await FlutterForegroundTask.saveData(
      key: _mobileSessionsDataKey,
      value: sanitized,
    );
  } catch (_) {}

  if (sanitized.isEmpty) {
    try {
      await FlutterForegroundTask.removeData(key: 'token');
    } catch (_) {}
    try {
      await FlutterForegroundTask.removeData(key: 'running_bot_id');
    } catch (_) {}
    return;
  }

  final first = sanitized.entries.first;
  try {
    await FlutterForegroundTask.saveData(key: 'token', value: first.value);
  } catch (_) {}
  try {
    await FlutterForegroundTask.saveData(
      key: 'running_bot_id',
      value: first.key,
    );
  } catch (_) {}
}

Future<Set<String>> getConfiguredMobileBotIds() async {
  final sessions = await _readConfiguredMobileSessions();
  return sessions.keys.toSet();
}

Future<Set<String>> getReadyMobileBotIds() async {
  try {
    final raw = await FlutterForegroundTask.getData<dynamic>(
      key: _mobileReadyBotIdsDataKey,
    );
    if (raw is Iterable) {
      return raw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .toSet();
    }
  } catch (_) {}

  return <String>{};
}

Future<void> startMobileBotSession({
  required String botId,
  required String token,
}) async {
  await _mobileSessionsOrchestrator.runSerialized(() async {
    final trimmedBotId = botId.trim();
    final trimmedToken = token.trim();
    if (trimmedBotId.isEmpty || trimmedToken.isEmpty) {
      throw Exception('botId/token invalid for mobile session start.');
    }

    final sessions = await _readConfiguredMobileSessions();
    sessions[trimmedBotId] = trimmedToken;
    await _writeConfiguredMobileSessions(sessions);

    var running = false;
    try {
      running = await _safeIsRunningForegroundService();
    } on MissingPluginException {
      running = false;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        running = false;
      } else {
        rethrow;
      }
    }

    if (running) {
      await _syncConfiguredMobileSessionsWithService(sessions);
    } else {
      await startService();
      final started = await _waitForForegroundServiceStartup();
      if (started) {
        await _syncConfiguredMobileSessionsWithService(sessions);
      }
    }
  });
}

Future<void> stopMobileBotSession({required String botId}) async {
  await _mobileSessionsOrchestrator.runSerialized(() async {
    final trimmedBotId = botId.trim();
    if (trimmedBotId.isEmpty) {
      return;
    }

    final sessions = await _readConfiguredMobileSessions();
    sessions.remove(trimmedBotId);
    await _writeConfiguredMobileSessions(sessions);

    var running = false;
    try {
      running = await _safeIsRunningForegroundService();
    } on MissingPluginException {
      running = false;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        running = false;
      } else {
        rethrow;
      }
    }

    if (running) {
      if (sessions.isEmpty) {
        try {
          await FlutterForegroundTask.stopService();
        } on MissingPluginException {
          // Ignore when plugin is unavailable on this platform.
        } on PlatformException catch (error) {
          if (!_isDeadChannelError(error)) {
            rethrow;
          }
        }
      } else {
        await _syncConfiguredMobileSessionsWithService(sessions);
      }
    }

    removeMobileRunningBotId(trimmedBotId);
    setBotRuntimeActive(isDesktopBotRunning || mobileRunningBotIds.isNotEmpty);
  });
}

Future<void> syncMobileBotSessionsWithService() async {
  await _mobileSessionsOrchestrator.runSerialized(() async {
    final sessions = await _readConfiguredMobileSessions();
    await _syncConfiguredMobileSessionsWithService(sessions);
  });
}

Future<bool> _waitForForegroundServiceStartup() async {
  final deadline = DateTime.now().add(_mobileServiceStartupTimeout);
  while (true) {
    try {
      if (await _safeIsRunningForegroundService()) {
        return true;
      }
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        return false;
      }
      rethrow;
    } catch (_) {}

    if (DateTime.now().isAfter(deadline)) {
      return false;
    }

    await Future<void>.delayed(_mobileServiceStartupPollDelay);
  }
}

Future<void> _syncConfiguredMobileSessionsWithService(
  Map<String, String> sessions,
) async {
  if (sessions.isEmpty) {
    return;
  }

  final payload = <String, dynamic>{
    _mobileCommandTypeKey: _mobileCommandSyncSessions,
    'sessions': sessions,
  };

  for (var attempt = 0; attempt < _mobileSessionSyncRetryCount; attempt++) {
    try {
      if (await _safeIsRunningForegroundService()) {
        FlutterForegroundTask.sendDataToTask(payload);
      }
    } on MissingPluginException {
      return;
    } on PlatformException catch (error) {
      if (_isDeadChannelError(error)) {
        return;
      }
      rethrow;
    } catch (_) {}

    if (attempt < _mobileSessionSyncRetryCount - 1) {
      await Future<void>.delayed(_mobileSessionSyncRetryDelay);
    }
  }
}

Future<void> syncMobileDebugFlagsWithService() async {
  try {
    final running = await _safeIsRunningForegroundService();
    if (!running) {
      return;
    }
    FlutterForegroundTask.sendDataToTask(<String, dynamic>{
      _mobileCommandTypeKey: _mobileCommandSyncFlags,
    });
  } on MissingPluginException {
    // Ignore when foreground task plugin is unavailable on this platform.
  } on PlatformException catch (error) {
    if (!_isDeadChannelError(error)) {
      rethrow;
    }
  } catch (_) {}
}

Future<void> syncMobileBotConfigWithService(String botId) async {
  try {
    final running = await _safeIsRunningForegroundService();
    if (!running) {
      return;
    }
    FlutterForegroundTask.sendDataToTask(<String, dynamic>{
      _mobileCommandTypeKey: _mobileCommandReloadBot,
      'botId': botId,
    });
  } on MissingPluginException {
    // Ignore when foreground task plugin is unavailable on this platform.
  } on PlatformException catch (error) {
    if (!_isDeadChannelError(error)) {
      rethrow;
    }
  } catch (_) {}
}

Future<void> initForegroundService({int eventIntervalMs = 5000}) async {
  final safeIntervalMs = eventIntervalMs.clamp(1000, 60000);
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
      eventAction: ForegroundTaskEventAction.repeat(safeIntervalMs),
      autoRunOnBoot: false,
      autoRunOnMyPackageReplaced: false,
      allowWakeLock: true,
      allowWifiLock: true,
    ),
  );
}

Future<void> startService() async {
  debugPrint('[Bot] startService() called');
  try {
    await FlutterForegroundTask.startService(
      serviceId: 110,
      notificationTitle: 'Bots are running',
      notificationText: 'Bots are running in the background',
      callback: startCallback,
      notificationButtons: [NotificationButton(id: 'stop', text: 'Stop')],
    );
  } on PlatformException catch (error) {
    if (!_isDeadChannelError(error)) {
      rethrow;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      await FlutterForegroundTask.startService(
        serviceId: 110,
        notificationTitle: 'Bots are running',
        notificationText: 'Bots are running in the background',
        callback: startCallback,
        notificationButtons: [NotificationButton(id: 'stop', text: 'Stop')],
      );
    } on PlatformException catch (retryError) {
      if (_isDeadChannelError(retryError)) {
        throw Exception(
          'Foreground service channel unavailable. Please reopen the app and try again.',
        );
      }
      rethrow;
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  ui.DartPluginRegistrant.ensureInitialized();
  debugPrint('[Bot] startCallback() invoked');
  FlutterForegroundTask.setTaskHandler(DiscordBotTaskHandler());
}

@pragma('vm:entry-point')
void stopCallback() {
  FlutterForegroundTask.stopService();
}

@pragma('vm:entry-point')
class DiscordBotTaskHandler extends TaskHandler {
  late final BotEngine _engine;
  AppManager? _manager;
  StreamSubscription<LogRecord>? _mobileNyxxLogsSubscription;
  bool? _lastKnownDebugEnabled;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter taskStarter) async {
    ui.DartPluginRegistrant.ensureInitialized();
    debugPrint('[Bot] DiscordBotTaskHandler.onStart()');
    
    _manager = AppManager();

    _engine = BotEngine(
      store: _manager!,
      callbacks: BotEngineCallbacks(
        onLog: (msg, {required botId}) => _emitTaskLogToMain(msg, botId: botId),
        onDebugLog: (msg, {botId}) => _emitTaskDebugLogToMain(msg, botId: botId),
        onLifecycleChange: (event, {required botId}) => _emitTaskLifecycleToMain(event, botId: botId),
        onMetrics: (metrics, {required botId}) => _emitTaskMetricsToMain(botId: botId),
      ),
    );

    await _syncDebugFlagFromMain();
    _bindMobileNyxxLogs();

    final sessions = await _readConfiguredMobileSessionsAfterStartup();
    await _syncSessions(sessions);
  }

  Future<void> _syncDebugFlagFromMain() async {
    try {
      final persisted = await FlutterForegroundTask.getData<bool>(
        key: _debugLogsEnabledDataKey,
      );
      if (persisted != null) {
        final changed = _lastKnownDebugEnabled != persisted;
        _debugBotLogsEnabled = persisted;
        _lastKnownDebugEnabled = persisted;
        if (changed) {
          await _emitTaskLogToMain(
            persisted
                ? 'Mobile debug logs enabled'
                : 'Mobile debug logs disabled',
            botId: null,
          );
        }
      }
    } catch (_) {}
  }

  void _bindMobileNyxxLogs() {
    unawaited(_mobileNyxxLogsSubscription?.cancel());
    Logger.root.level = Level.ALL;
    _mobileNyxxLogsSubscription = Logger.root.onRecord.listen((record) {
      final formatted = _formatNyxxLogRecord(record);
      debugPrint('[Bot][Nyxx] $formatted');

      if (record.level >= Level.WARNING) {
        unawaited(_emitTaskLogToMain('NYXX: $formatted'));
      }
      unawaited(_emitTaskDebugLogToMain(formatted));
    });
  }

  Future<void> _syncSessions(Map<String, String> desired) async {
    final currentIds = _engine.runningBotIds;
    final desiredIds = desired.keys.toSet();

    for (final botId in currentIds.difference(desiredIds)) {
      await _engine.stop(botId);
    }

    for (final entry in desired.entries) {
      if (!currentIds.contains(entry.key)) {
        await _engine.startWithId(entry.key, entry.value);
      }
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    unawaited(_syncDebugFlagFromMain());
    for (final botId in _engine.runningBotIds) {
      unawaited(_emitTaskMetricsToMain(botId: botId));
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _engine.stopAll();
    await _mobileNyxxLogsSubscription?.cancel();
    _mobileNyxxLogsSubscription = null;
    
    if (isTimeout) {
      await _emitTaskLogToMain('Service interrupted (timeout), restarting...');
      await startService();
    } else {
      await _emitTaskLogToMain('Service stopped');
    }
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      final payload = Map<String, dynamic>.from(data.cast<dynamic, dynamic>());
      final type = payload[_mobileCommandTypeKey] as String?;
      if (type == _mobileCommandSyncSessions) {
        final sessions = _normalizeMobileSessionsMap(payload['sessions']);
        unawaited(_syncSessions(sessions));
      } else if (type == _mobileCommandReloadBot) {
        final botId = payload['botId'] as String?;
        if (botId != null) {
          unawaited(_engine.reload(botId));
        }
      } else if (type == _mobileCommandSyncFlags) {
        unawaited(_syncDebugFlagFromMain());
      }
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      unawaited(_emitTaskLogToMain('Stop requested from notification', botId: null));
      stopCallback();
    }
  }

  Future<void> _emitTaskLogToMain(String message, {String? botId}) async {
    FlutterForegroundTask.sendDataToMain({
      'type': 'bot_log',
      'botId': botId,
      'message': message,
    });
  }

  Future<void> _emitTaskDebugLogToMain(String message, {String? botId}) async {
    if (!_debugBotLogsEnabled) return;
    FlutterForegroundTask.sendDataToMain({
      'type': 'bot_log',
      'botId': botId,
      'message': 'DEBUG: $message',
    });
  }

  Future<void> _emitTaskLifecycleToMain(String event, {required String botId}) async {
    FlutterForegroundTask.sendDataToMain({
      'type': 'bot_lifecycle',
      'botId': botId,
      'state': event,
    });

    final ready = event == 'started';
    final currentReady = await getReadyMobileBotIds();
    if (ready) {
      currentReady.add(botId);
    } else {
      currentReady.remove(botId);
    }
    await FlutterForegroundTask.saveData(
      key: _mobileReadyBotIdsDataKey,
      value: currentReady.toList(),
    );
  }

  Future<void> _emitTaskMetricsToMain({required String botId}) async {
    final rss = _readCurrentProcessRssBytes();
    final cpu = _readCurrentProcessCpuPercent();
    final storage = await _readBotStorageBytes(botId: botId);
    final session = _engine.getSession(botId);
    final guildCount = session?.gateway?.guilds.cache.length;

    FlutterForegroundTask.sendDataToMain({
      'type': 'bot_metrics',
      'botId': botId,
      'rssBytes': rss,
      'cpuPercent': cpu,
      'storageBytes': storage,
      'guildCount': guildCount,
    });
  }
}
