library;

import 'dart:async';

import 'dart:developer' as developer;
import 'dart:io';

import 'dart:ui' as ui;

import 'package:bot_creator/main.dart';
import 'package:bot_creator_shared/bot_creator_shared.dart' hide 
  BotRuntimeMetrics, 
  getDiscordUser, 
  generateKeyValues, 
  findFocusedOption, 
  normalizeStoredWorkflowDefinition, 
  normalizeWorkflowType, 
  workflowTypeGeneral, 
  workflowTypeEvent,
  normalizeWorkflowEventTrigger,
  resolveWorkflowCallArguments,
  applyWorkflowInvocationContext,
  normalizeWorkflowEntryPoint,
  parseWorkflowArgumentDefinitions,
  getChannelName,
  makeAvatarUrl;
import 'package:bot_creator_shared/utils/global.dart' as shared_global;
import 'package:bot_creator/core/storage/database.dart';





import 'package:bot_creator/core/network/mobile_sessions_orchestrator.dart';
import 'package:bot_creator/core/storage/app_storage_directory.dart' as storage_utils;
import 'package:bot_creator/core/network/runner_client.dart';


import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:nyxx/nyxx.dart';

part 'bot.logs.dart';
part 'bot.debug_replay.dart';
part 'bot.template.dart';
part 'bot.mobile_service.dart';


/// The central bot execution engine for the desktop app.
final BotEngine _engine = BotEngine(
  store: appManager,
  callbacks: BotEngineCallbacks(
    onLog: (msg, {required botId}) => appendBotLog(msg, botId: botId),
    onDebugLog: (msg, {botId}) => appendBotLog(msg, botId: botId),
    onLifecycleChange: (event, {required botId}) {
      if (event == 'started') {
        _botRuntimeActive = true;
      } else if (event == 'stopped' && _engine.runningBotIds.isEmpty) {
        _botRuntimeActive = false;
      }
      setBotRuntimeActive(_botRuntimeActive || mobileRunningBotIds.isNotEmpty);
    },
    onMetrics: (metrics, {required botId}) {
      appManager.updateGuildCount(botId, metrics.guildCount);
    },
    onReplayCaptured: (botId, label, frames, totalMs) {
      _engine.saveDebugReplay(botId, label, frames, totalMs);
      appendDebugReplay(DebugReplayRecord(
        botId: botId,
        commandLabel: label,
        triggeredAt: DateTime.now(),
        frames: frames.map(DebugActionFrame.fromJson).toList(),
        totalMs: totalMs,
      ));
    },
    isDebugReplayCapturing: (botId) =>
        _engine.isDebugReplayCapturing(botId) || isDebugReplayCapturing,
  ),
);







String? get desktopRunningBotId {
  if (_engine.runningBotIds.isEmpty) return null;
  return _engine.runningBotIds.first;
}

Set<String> get desktopRunningBotIds => _engine.runningBotIds;

bool isDesktopBotRunningId(String botId) => _engine.runningBotIds.contains(botId.trim());

NyxxGateway? desktopGatewayForBot(String botId) => _engine.getSession(botId.trim())?.gateway;

String? _mobileRunningBotId;
final Set<String> _mobileRunningBotIds = <String>{};
String? get mobileRunningBotId {
  if (_mobileRunningBotId != null && _mobileRunningBotId!.isNotEmpty) {
    return _mobileRunningBotId;
  }
  if (_mobileRunningBotIds.isEmpty) {
    return null;
  }
  return _mobileRunningBotIds.first;
}

Set<String> get mobileRunningBotIds =>
    Set<String>.unmodifiable(_mobileRunningBotIds);

bool isMobileBotRunning(String botId) => _mobileRunningBotIds.contains(botId);

void setMobileRunningBotId(String? id) {
  _mobileRunningBotId = id;
  _mobileRunningBotIds.clear();
  if (id != null && id.trim().isNotEmpty) {
    _mobileRunningBotIds.add(id.trim());
  }
}

void addMobileRunningBotId(String id) {
  final trimmed = id.trim();
  if (trimmed.isEmpty) {
    return;
  }
  _mobileRunningBotIds.add(trimmed);
  _mobileRunningBotId ??= trimmed;
}

void removeMobileRunningBotId(String id) {
  final trimmed = id.trim();
  if (trimmed.isEmpty) {
    return;
  }
  _mobileRunningBotIds.remove(trimmed);
  if (_mobileRunningBotId == trimmed) {
    _mobileRunningBotId =
        _mobileRunningBotIds.isEmpty ? null : _mobileRunningBotIds.first;
  }
}

const int _maxBotLogLines = 500;
const String _globalBotBucketKey = '__global__';
final StreamController<List<String>> _botLogsController =
    StreamController<List<String>>.broadcast();
final StreamController<Map<String, List<String>>> _botLogsByBotController =
    StreamController<Map<String, List<String>>>.broadcast();
final StreamController<int?> _botProcessRssController =
    StreamController<int?>.broadcast();
final StreamController<int?> _botEstimatedRssController =
    StreamController<int?>.broadcast();
final StreamController<double?> _botProcessCpuController =
    StreamController<double?>.broadcast();
final StreamController<int?> _botProcessStorageController =
    StreamController<int?>.broadcast();
final StreamController<Map<String, BotRuntimeMetrics>>
_botMetricsByBotController =
    StreamController<Map<String, BotRuntimeMetrics>>.broadcast();
List<String> _botLogs = <String>[];
final Map<String, List<String>> _botLogsByBot = <String, List<String>>{};
String? _activeBotLogBotId;
RemoteRuntimeSource _activeBotLogSource = RemoteRuntimeSource.local;
bool _debugBotLogsEnabled = false;
const String _debugLogsEnabledDataKey = 'debugLogsEnabled';
int? _botProcessRssBytes;
int? _botBaselineRssBytes;
DateTime? _botBaselineCapturedAt;
int? _botEstimatedRssBytes;
double? _botProcessCpuPercent;
int? _botProcessStorageBytes;
final Map<String, BotRuntimeMetrics> _botMetricsByBot =
    <String, BotRuntimeMetrics>{};
bool _botRuntimeActive = false;


bool get isDesktopBotRunning => _engine.isRunning;
bool get isBotDebugLogsEnabled => _debugBotLogsEnabled;
bool get isBotRuntimeActive => _botRuntimeActive;

void applyDesktopRuntimeSettings({
  required String botId,
  required Map<String, dynamic> appData,
}) {
  unawaited(_engine.reload(botId));
}

/// A callback registered by the synchronization engine (bot_payload_builder)
/// to handle runtime refresh requests.
Future<void> Function(String botId, {bool immediate})? onRefreshBotRuntime;

/// Centralized helper to refresh all runtime configurations (status, workflows, listeners)
/// for a running bot session (Desktop, Mobile, or Remote).
Future<void> refreshBotRuntime(String botId) async {
  if (onRefreshBotRuntime != null) {
    await onRefreshBotRuntime!(botId, immediate: true);
  }
}

Future<void> _persistDebugLogsEnabled(bool enabled) async {
  try {
    await FlutterForegroundTask.saveData(
      key: _debugLogsEnabledDataKey,
      value: enabled,
    );
  } catch (_) {}
}

void setBotDebugLogsEnabled(bool enabled) {
  _debugBotLogsEnabled = enabled;
  appendBotLog(enabled ? 'Debug logs enabled' : 'Debug logs disabled');
  unawaited(_persistDebugLogsEnabled(enabled));
}

String _two(int value) => value < 10 ? '0$value' : '$value';

String _timestampNow() {
  final now = DateTime.now();
  return '${_two(now.hour)}:${_two(now.minute)}:${_two(now.second)}';
}



/// Convert the intents configuration map to GatewayIntents
Flags<GatewayIntents> buildGatewayIntents(Map<String, bool>? intentsMap) {
  if (intentsMap == null || intentsMap.isEmpty) {
    return GatewayIntents.allUnprivileged;
  }

  Flags<GatewayIntents> intents = GatewayIntents.none;

  if (intentsMap['Guild Presence'] == true) {
    intents = intents | GatewayIntents.guildPresences;
  }
  if (intentsMap['Guild Members'] == true) {
    intents = intents | GatewayIntents.guildMembers;
  }
  if (intentsMap['Message Content'] == true) {
    intents = intents | GatewayIntents.messageContent;
  }
  if (intentsMap['Direct Messages'] == true) {
    intents = intents | GatewayIntents.directMessages;
  }
  if (intentsMap['Guilds'] == true) {
    intents = intents | GatewayIntents.guilds;
  }
  if (intentsMap['Guild Messages'] == true) {
    intents = intents | GatewayIntents.guildMessages;
  }
  if (intentsMap['Guild Message Reactions'] == true) {
    intents = intents | GatewayIntents.guildMessageReactions;
  }
  if (intentsMap['Direct Message Reactions'] == true) {
    intents = intents | GatewayIntents.directMessageReactions;
  }
  if (intentsMap['Guild Message Typing'] == true) {
    intents = intents | GatewayIntents.guildMessageTyping;
  }
  if (intentsMap['Direct Message Typing'] == true) {
    intents = intents | GatewayIntents.directMessageTyping;
  }
  if (intentsMap['Guild Scheduled Events'] == true) {
    intents = intents | GatewayIntents.guildScheduledEvents;
  }
  if (intentsMap['Auto Moderation Configuration'] == true) {
    intents = intents | GatewayIntents.autoModerationConfiguration;
  }
  if (intentsMap['Auto Moderation Execution'] == true) {
    intents = intents | GatewayIntents.autoModerationExecution;
  }

  if (intents == GatewayIntents.none) {
    return GatewayIntents.allUnprivileged;
  }

  return intents;
}

Future<void> startDesktopBot(String token) async {
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    throw Exception('Desktop bot mode is only available on desktop platforms.');
  }

  final botUser = await shared_global.getDiscordUser(token);
  final botId = botUser.id.toString();
  
  await _engine.startWithId(botId, token);
}

Future<void> stopDesktopBot({String? botId}) async {
  if (botId == null) {
    await _engine.stopAll();
    return;
  }

  final normalizedBotId = botId.trim();
  if (normalizedBotId.isEmpty) return;

  await _engine.stop(normalizedBotId);
  setBotRuntimeActive(_engine.isRunning || mobileRunningBotIds.isNotEmpty);
}


Future<void> createCommand(
  NyxxRest client,
  ApplicationCommandBuilder commandBuilder, {
  Map<String, dynamic> data = const {},
  String folder = '',
}) async {
  try {
    final command = await client.commands.create(commandBuilder);
    final Map<String, dynamic> commandData = {
      'name': command.name,
      'description': command.description,
      'type': _commandTypeToStorage(command.type),
      'id': command.id.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    };
    if (data.isNotEmpty) {
      commandData['data'] = data;
    }
    if (folder.isNotEmpty) {
      commandData['folder'] = folder;
    }
    await appManager.saveAppCommand(
      client.user.id.toString(),
      command.id.toString(),
      commandData,
    );
  } catch (e) {
    throw Exception('Failed to create command: $e');
  }
}

Future<void> updateCommand(
  NyxxRest client,
  Snowflake commandId, {
  required ApplicationCommandUpdateBuilder commandBuilder,
  Map<String, dynamic> data = const {},
  String folder = '',
}) async {
  try {
    final command = await client.commands.update(commandId, commandBuilder);
    final Map<String, dynamic> commandData = {
      'name': command.name,
      'description': command.description,
      'type': _commandTypeToStorage(command.type),
      'id': command.id.toString(),
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (data.isNotEmpty) {
      commandData['data'] = data;
    }
    if (folder.isNotEmpty) {
      commandData['folder'] = folder;
    }
    await appManager.saveAppCommand(
      client.user.id.toString(),
      command.id.toString(),
      commandData,
    );
  } catch (e) {
    throw Exception('Failed to update command: $e');
  }
}

String _commandTypeToStorage(ApplicationCommandType type) {
  if (type == ApplicationCommandType.user) {
    return 'user';
  }
  if (type == ApplicationCommandType.message) {
    return 'message';
  }
  return 'chatInput';
}
