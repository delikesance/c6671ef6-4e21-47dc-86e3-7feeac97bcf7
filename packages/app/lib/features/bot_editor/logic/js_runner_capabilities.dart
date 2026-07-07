import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

/// Feature flags for bot runtime engines. Dart runner supports the full
/// visual-workflow surface; runner-js supports a smaller script-based subset.
class BotRuntimeCapabilities {
  const BotRuntimeCapabilities._({
    required this.supportsWorkflows,
    required this.supportsSchedulerUi,
    required this.supportsInboundWebhooksUi,
    required this.supportsCommandDashboard,
    required this.supportsDebugReplay,
    required this.supportsBotProcessStats,
    required this.supportsLavalink,
    required this.supportsStatusRotation,
    required this.supportsSubcommandWorkflows,
  });

  final bool supportsWorkflows;
  final bool supportsSchedulerUi;
  final bool supportsInboundWebhooksUi;
  final bool supportsCommandDashboard;
  final bool supportsDebugReplay;
  final bool supportsBotProcessStats;
  final bool supportsLavalink;
  final bool supportsStatusRotation;
  final bool supportsSubcommandWorkflows;

  static const BotRuntimeCapabilities dart = BotRuntimeCapabilities._(
    supportsWorkflows: true,
    supportsSchedulerUi: true,
    supportsInboundWebhooksUi: true,
    supportsCommandDashboard: true,
    supportsDebugReplay: true,
    supportsBotProcessStats: true,
    supportsLavalink: true,
    supportsStatusRotation: true,
    supportsSubcommandWorkflows: true,
  );

  static const BotRuntimeCapabilities javascript = BotRuntimeCapabilities._(
    supportsWorkflows: false,
    supportsSchedulerUi: false,
    supportsInboundWebhooksUi: false,
    supportsCommandDashboard: false,
    supportsDebugReplay: false,
    supportsBotProcessStats: false,
    supportsLavalink: false,
    supportsStatusRotation: false,
    supportsSubcommandWorkflows: false,
  );
}

Future<bool> isJavascriptBot(String botId) async {
  final engine = await getBotRuntimeEngine(botId);
  return isJavascriptRuntimeEngine(engine);
}

BotRuntimeCapabilities capabilitiesForEngine(String? engine) {
  return isJavascriptRuntimeEngine(engine)
      ? BotRuntimeCapabilities.javascript
      : BotRuntimeCapabilities.dart;
}

Future<BotRuntimeCapabilities> getBotRuntimeCapabilities(String botId) async {
  final engine = await getBotRuntimeEngine(botId);
  return capabilitiesForEngine(engine);
}
