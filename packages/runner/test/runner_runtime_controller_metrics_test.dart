import 'dart:io';

import 'package:bot_creator_runner/runner_bot_store.dart';
import 'package:bot_creator_runner/runner_runtime_controller.dart';
import 'package:bot_creator_shared/bot_creator_shared.dart';
import 'package:test/test.dart';

void main() {
  group('RunnerRuntimeController metrics', () {
    late Directory tempDir;
    late RunnerRuntimeController controller;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('runner-metrics-test-');
      controller = RunnerRuntimeController(
        botStore: RunnerBotStore(dataDir: tempDir.path),
        dataDir: tempDir.path,
      );
    });

    tearDown(() async {
      await controller.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('recordBotMetrics stores guild count and marginal rss', () {
      const botId = 'metrics-bot';
      controller.seedBotMetricsForTest(
        botId: botId,
        botName: 'Metrics Bot',
        baselineRssBytes: 40 * 1024 * 1024,
      );

      controller.recordBotMetrics(
        botId,
        const BotRuntimeMetrics(
          guildCount: 7,
          shardsCount: 1,
          latencyMs: 42,
          uptimeSeconds: 10,
          memoryUsageBytes: 0,
          cpuUsagePercent: 0,
        ),
      );

      final state = controller.runtimeStateForBot(botId);
      expect(state.guildCount, 7);
      expect(state.pid, pid);
      expect(state.rssBytes, isNotNull);
      expect(state.rssBytes, greaterThanOrEqualTo(0));
    });

    test('preserves guild count and rss after disconnect', () {
      const botId = 'disconnect-bot';
      controller.seedBotMetricsForTest(
        botId: botId,
        botName: 'Disconnect Bot',
        baselineRssBytes: 32 * 1024 * 1024,
        guildCount: 3,
        rssBytes: 8 * 1024 * 1024,
      );

      controller.simulateBotDisconnectedForTest(
        botId,
        'Disallowed intents (4014) — enable required intents',
      );

      final state = controller.runtimeStateForBot(botId);
      expect(state.state, 'error');
      expect(state.guildCount, 3);
      expect(state.rssBytes, 8 * 1024 * 1024);
      expect(state.lastError, contains('4014'));
    });
  });
}
