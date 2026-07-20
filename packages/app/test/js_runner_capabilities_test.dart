import 'package:bot_creator/features/bot_editor/logic/js_runner_capabilities.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BotRuntimeCapabilities', () {
    test('dart engine exposes all Dart-only features', () {
      final caps = capabilitiesForEngine(runtimeEngineDart);

      expect(caps.supportsWorkflows, isTrue);
      expect(caps.supportsEventListeners, isTrue);
      expect(caps.supportsSchedulerUi, isTrue);
      expect(caps.supportsInboundWebhooksUi, isTrue);
      expect(caps.supportsCommandDashboard, isTrue);
      expect(caps.supportsDebugReplay, isTrue);
      expect(caps.supportsBotProcessStats, isTrue);
      expect(caps.supportsLavalink, isTrue);
      expect(caps.supportsStatusRotation, isTrue);
      expect(caps.supportsSubcommandWorkflows, isTrue);
    });

    test('javascript engine exposes events/scheduler/webhooks but not Dart-only features', () {
      final caps = capabilitiesForEngine(runtimeEngineJavascript);

      expect(caps.supportsWorkflows, isFalse);
      expect(caps.supportsEventListeners, isTrue);
      expect(caps.supportsSchedulerUi, isTrue);
      expect(caps.supportsInboundWebhooksUi, isTrue);
      expect(caps.supportsCommandDashboard, isFalse);
      expect(caps.supportsDebugReplay, isFalse);
      expect(caps.supportsBotProcessStats, isFalse);
      expect(caps.supportsLavalink, isFalse);
      expect(caps.supportsStatusRotation, isFalse);
      expect(caps.supportsSubcommandWorkflows, isFalse);
    });

    test('capabilitiesForEngine defaults unknown values to dart', () {
      final caps = capabilitiesForEngine(null);
      expect(caps, BotRuntimeCapabilities.dart);
    });
  });
}
