import 'dart:async';

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/database.dart';

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
