import 'dart:async';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';

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
  Map<String, dynamic>? payloadOverride,
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
  // `payloadOverride` existe pour la bascule de moteur : la charge doit être
  // celle VALIDÉE avant l'effacement local, jamais une reconstruction tardive.
  final payload = payloadOverride ?? await buildRemotePayload(trimmedBotId);

  await client.saveDiscordBotSnapshot(
    botId: trimmedBotId,
    botToken: token,
    config: payload,
    force: forceSnapshot,
  );
  await client.syncBot(trimmedBotId, botName, payload);
}

/// Construit et VALIDE la charge utile du moteur [engine] visé par une bascule.
///
/// POURQUOI à part : la bascule doit décider AVANT de toucher aux données
/// locales. La charge est donc construite avec le moteur CIBLE appliqué à la
/// volée (sans changer le moteur stocké) ; si elle est dégénérée, l'appelant
/// annule la bascule sans avoir rien effacé.
Future<Map<String, dynamic>> _buildEnginePayloadOrThrow(
  String botId,
  String engine,
) async {
  final payload = engine == runtimeEngineJavascript
      ? await buildJsBotPayload(botId)
      : await buildBotPayload(botId);
  assertNonDegenerateBotPayload(payload, source: 'switchBotRuntimeEngine');
  return payload;
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

  // 1. VALIDER AVANT D'EFFACER.
  //
  // POURQUOI cet ordre est vital : l'ancien code effaçait d'abord
  // (`clearBotAutomationData`), puis reconstruisait la charge utile — vide,
  // puisque les données venaient de disparaître — et la poussait. La bascule
  // pouvait donc vider la configuration du bot dans le nuage ET en local, sans
  // retour. Ici, si la charge cible ne peut pas être construite ou est
  // dégénérée, l'exception remonte et RIEN n'a été touché.
  final targetPayload = await _buildEnginePayloadOrThrow(
    trimmedBotId,
    targetEngine,
  );

  await stopBotIfRunning(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
  );

  // 2. Sauvegarde de l'état actuel (moteur courant) : c'est la copie de secours
  //    annoncée par le dialogue de confirmation.
  await _syncBotConfigToManager(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
    forceSnapshot: true,
  );

  await deleteAllDiscordApplicationCommands(trimmedBotId);

  // 3. Effacement local : autorisé seulement maintenant que la cible est
  //    construite ET validée.
  await clearBotAutomationData(trimmedBotId);
  await setBotRuntimeEngine(trimmedBotId, targetEngine);
  await AppManager().invalidatePayloadCache(trimmedBotId);

  // 4. On pousse la charge VALIDÉE à l'étape 1, jamais une reconstruction :
  //    les données locales viennent d'être vidées, une reconstruction
  //    donnerait la charge vide de l'incident (378 octets) et écraserait la
  //    configuration conservée pour la restauration.
  await _syncBotConfigToManager(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
    forceSnapshot: true,
    payloadOverride: targetPayload,
  );
}
