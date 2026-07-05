import 'dart:async';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';

const runtimeEngineDart = 'dart';
const runtimeEngineJavascript = 'javascript';

Future<String> getBotRuntimeEngine(String botId) async {
  final app = await AppManager().getApp(botId);
  final raw = (app['runtimeEngine'] ?? runtimeEngineDart).toString().trim().toLowerCase();
  if (raw == runtimeEngineJavascript) {
    return runtimeEngineJavascript;
  }
  return runtimeEngineDart;
}

Future<void> setBotRuntimeEngine(String botId, String engine) async {
  final app = Map<String, dynamic>.from(await AppManager().getApp(botId));
  app['runtimeEngine'] = engine.trim().toLowerCase() == runtimeEngineJavascript
      ? runtimeEngineJavascript
      : runtimeEngineDart;
  await AppManager().saveApp(botId, app);
  if (isJavascriptRuntimeEngine(app['runtimeEngine']?.toString())) {
    unawaited(RunnerSettings.prepareEmbeddedJsRunner());
  }
}

bool isJavascriptRuntimeEngine(String? engine) {
  return (engine ?? '').trim().toLowerCase() == runtimeEngineJavascript;
}

String normalizeRuntimeEngine(String engine) {
  return engine.trim().toLowerCase() == runtimeEngineJavascript
      ? runtimeEngineJavascript
      : runtimeEngineDart;
}

Future<void> stopBotIfRunning(
  String botId, {
  bool supportsManagerRuntime = true,
}) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return;
  }

  var stopped = false;

  final remoteRuntime = await resolveRemoteRuntime(
    supportsManagerRuntime: supportsManagerRuntime,
    botId: trimmedBotId,
  );
  final remoteClient = remoteRuntime.client;
  if (remoteClient != null) {
    try {
      final status = await remoteClient.getStatus(botId: trimmedBotId);
      if (status.isBotRunning(trimmedBotId)) {
        await remoteClient.stopBot(trimmedBotId);
        endBotLogSession(
          botId: trimmedBotId,
          source: remoteRuntime.source,
        );
        stopped = true;
      }
    } catch (_) {
      // Fall through to local stop checks.
    }
  }

  if (!stopped && isDesktopBotRunningId(trimmedBotId)) {
    await stopDesktopBot(botId: trimmedBotId);
    endBotLogSession(botId: trimmedBotId);
    stopped = true;
  }

  if (!stopped && isMobileBotRunning(trimmedBotId)) {
    await stopMobileBotSession(botId: trimmedBotId);
    endBotLogSession(botId: trimmedBotId);
    stopped = true;
  }

  if (stopped) {
    setBotRuntimeActive(
      isDesktopBotRunning || mobileRunningBotIds.isNotEmpty,
    );
  }
}

Future<void> clearBotAutomationData(String botId) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return;
  }

  await AppManager().deleteAppCommands(trimmedBotId);

  final workflows = await AppManager().getWorkflows(trimmedBotId);
  for (final workflow in workflows) {
    final name = (workflow['name'] ?? '').toString().trim();
    if (name.isEmpty) {
      continue;
    }
    await AppManager().deleteWorkflow(trimmedBotId, name);
  }

  final app = Map<String, dynamic>.from(await AppManager().getApp(trimmedBotId));
  app['scheduledTriggers'] = <Map<String, dynamic>>[];
  app['inboundWebhooks'] = <Map<String, dynamic>>[];
  app['inboundWebhookEndpoints'] = <Map<String, dynamic>>[];
  app['globalVariables'] = <String, dynamic>{};
  await AppManager().saveApp(trimmedBotId, app);
  await AppManager().invalidatePayloadCache(trimmedBotId);
}

Future<void> _syncBotConfigToManager(
  String botId, {
  required bool supportsManagerRuntime,
  bool forceSnapshot = false,
}) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return;
  }

  final remoteRuntime = await resolveRemoteRuntime(
    supportsManagerRuntime: supportsManagerRuntime,
    botId: trimmedBotId,
  );
  final client = remoteRuntime.client;
  if (client is! MainApiClient) {
    return;
  }

  final app = await AppManager().getApp(trimmedBotId);
  final token = (app['token'] ?? '').toString().trim();
  if (token.isEmpty) {
    return;
  }

  final botName =
      (app['username'] ?? app['name'] ?? trimmedBotId).toString().trim();
  final payload = await buildRemotePayload(trimmedBotId);

  await client.saveDiscordBotSnapshot(
    botId: trimmedBotId,
    botToken: token,
    config: payload,
    force: forceSnapshot,
  );
  await client.syncBot(trimmedBotId, botName, payload);
}

Future<void> switchBotRuntimeEngine(
  String botId,
  String engine, {
  bool supportsManagerRuntime = true,
}) async {
  final trimmedBotId = botId.trim();
  if (trimmedBotId.isEmpty) {
    return;
  }

  final targetEngine = normalizeRuntimeEngine(engine);
  final currentEngine = await getBotRuntimeEngine(trimmedBotId);
  if (currentEngine == targetEngine) {
    return;
  }

  await stopBotIfRunning(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
  );

  await _syncBotConfigToManager(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
    forceSnapshot: true,
  );

  await deleteAllDiscordApplicationCommands(trimmedBotId);

  await clearBotAutomationData(trimmedBotId);
  await setBotRuntimeEngine(trimmedBotId, targetEngine);
  await AppManager().invalidatePayloadCache(trimmedBotId);

  await _syncBotConfigToManager(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
    forceSnapshot: true,
  );
}
