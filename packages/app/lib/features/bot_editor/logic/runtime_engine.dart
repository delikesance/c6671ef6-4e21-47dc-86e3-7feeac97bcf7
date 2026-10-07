import 'package:shared_preferences/shared_preferences.dart';
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

bool configurationContainsJavascript(Map<String, dynamic> config) {
  Iterable<dynamic> entries(dynamic raw) => raw is List
      ? raw
      : raw is Map
      ? raw.values
      : const [];
  return [
    ...entries(config['commands']),
    ...entries(config['workflows']),
  ].whereType<Map>().any((entry) {
    final data = entry['data'] is Map ? entry['data'] as Map : entry;
    return data['executionMode'] == 'javascript' ||
        (entry['type'] == 'command' && entry['script'] is String);
  });
}

/// Missing markers in old JS exports must not silently select the Dart runner.
String? runtimeEngineFromConfiguration(Map<String, dynamic> config) {
  final raw = (config['runtimeEngine'] ?? '').toString().trim().toLowerCase();
  if (raw.isNotEmpty &&
      raw != runtimeEngineDart &&
      raw != runtimeEngineJavascript) {
    throw StateError('Unknown runtime engine in imported configuration.');
  }
  final hasJavascript = configurationContainsJavascript(config);
  if (raw == runtimeEngineDart && hasJavascript) {
    throw StateError(
      'Dart configuration contains JavaScript commands or workflows.',
    );
  }
  return raw.isNotEmpty
      ? raw
      : hasJavascript
      ? runtimeEngineJavascript
      : null;
}

Future<String> getBotRuntimeEngine(String botId) async {
  final app = await AppManager().getApp(botId);
  final raw = (app['runtimeEngine'] ?? runtimeEngineDart)
      .toString()
      .trim()
      .toLowerCase();
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
        endBotLogSession(botId: trimmedBotId, source: remoteRuntime.source);
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
    setBotRuntimeActive(isDesktopBotRunning || mobileRunningBotIds.isNotEmpty);
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

  final app = Map<String, dynamic>.from(
    await AppManager().getApp(trimmedBotId),
  );
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

  final botName = (app['username'] ?? app['name'] ?? trimmedBotId)
      .toString()
      .trim();
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
  payload['runtimeEngine'] = normalizeRuntimeEngine(engine);
  // Un bot Dart n'exécute pas de JavaScript : pousser ces éléments donnerait au
  // serveur une configuration mixte que l'éditeur local ne voit ni n'édite, et
  // que le runner refuse. On les retire de la charge cible.
  var removed = 0;
  if (normalizeRuntimeEngine(engine) == runtimeEngineDart) {
    for (final key in const ['commands', 'workflows']) {
      final raw = payload[key];
      if (raw is! List) continue;
      payload[key] = raw.where((entry) {
        final isJs = configurationContainsJavascript({
          key: [entry],
        });
        if (isJs) removed += 1;
        return !isJs;
      }).toList();
    }
  }
  // Une charge vide parce qu'on a retiré le JavaScript est un canevas vierge
  // voulu ; sinon, la garde contre l'effacement accidentel reste entière.
  if (removed == 0) {
    assertNonDegenerateBotPayload(payload, source: 'switchBotRuntimeEngine');
  }
  return payload;
}

/// Noms des commandes et workflows locaux qui ne passeront PAS sur le moteur
/// [engine] (aucun équivalent, ou JavaScript vers Dart). Sert à les lister dans
/// la confirmation, au lieu de les laisser disparaître sans le dire.
Future<List<String>> previewEngineSwitchLeftOut(
  String botId,
  String engine,
) async {
  try {
    final target = normalizeRuntimeEngine(engine);
    final payload = target == runtimeEngineJavascript
        ? await buildJsBotPayload(botId)
        : await buildBotPayload(botId);
    final carried = <String>{
      for (final key in const ['commands', 'workflows'])
        if (payload[key] is List)
          for (final entry in payload[key] as List)
            if (entry is Map &&
                !(target == runtimeEngineDart &&
                    configurationContainsJavascript({
                      key: [entry],
                    })))
              '${entry['name'] ?? ''}'.toLowerCase(),
    };
    final local = <String>[
      for (final c in await AppManager().listAppCommands(botId))
        '${c['name'] ?? ''}',
      for (final w in await AppManager().getWorkflows(botId))
        '${w['name'] ?? ''}',
    ];
    final leftOut = <String>{
      for (final name in local)
        if (name.isNotEmpty && !carried.contains(name.toLowerCase())) name,
    };
    return leftOut.toList()..sort();
  } catch (_) {
    return const [];
  }
}

String _engineSwitchKey(String botId) => 'engine_switch_confirmed:$botId';

/// Après une bascule de moteur, le serveur garde la configuration convertie
/// alors que le local repart vide : la première poussée suivante paraîtrait une
/// suppression massive que l'utilisateur n'a jamais faite (il a seulement
/// confirmé la bascule). On retient donc cet accord pour la première poussée.
Future<void> _markEngineSwitchConfirmed(String botId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(_engineSwitchKey(botId), true);
}

Future<bool> hasEngineSwitchConfirmation(String botId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_engineSwitchKey(botId)) ?? false;
}

Future<void> clearEngineSwitchConfirmation(String botId) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_engineSwitchKey(botId));
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

  // 3. Pousser la charge cible VALIDÉE au manager AVANT tout effacement local.
  //    Si la poussée échoue (serveur inaccessible, refus, erreur réseau),
  //    l'exception remonte et les commandes locales restent INTACTES.
  await _syncBotConfigToManager(
    trimmedBotId,
    supportsManagerRuntime: supportsManagerRuntime,
    forceSnapshot: true,
    payloadOverride: targetPayload,
  );

  await deleteAllDiscordApplicationCommands(trimmedBotId);

  // 4. Effacement local : autorisé seulement maintenant que le serveur distant
  //    a validé et persisté la bascule avec succès.
  await clearBotAutomationData(trimmedBotId);
  await setBotRuntimeEngine(trimmedBotId, targetEngine);
  await _markEngineSwitchConfirmed(trimmedBotId);
  await AppManager().invalidatePayloadCache(trimmedBotId);
}
