import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_runner/runner_runtime_controller.dart';
import 'package:bot_creator_runner/discord_runner.dart';
import 'package:test/test.dart';

const String workflowTypeEvent = 'event';

void main() {
  group('DiscordRunner.reloadConfig Lavalink Reconnect Trigger', () {
    test('reconnect is required when Lavalink config is added (null -> non-null)', () async {
      final initial = BotConfig(token: 'token', intents: {'Guilds': true});
      final runner = DiscordRunner('test-bot', initial);

      final nextConfig = BotConfig(
        token: 'token',
        intents: {'Guilds': true},
        lavalinkConfig: const LavalinkConfig(host: 'localhost', port: 2333),
      );

      final requiresReconnect = await runner.reloadConfig(nextConfig);
      expect(requiresReconnect, isTrue);
    });

    test('reconnect is required when Lavalink config is removed (non-null -> null)', () async {
      final initial = BotConfig(
        token: 'token',
        intents: {'Guilds': true},
        lavalinkConfig: const LavalinkConfig(host: 'localhost', port: 2333),
      );
      final runner = DiscordRunner('test-bot', initial);

      final nextConfig = BotConfig(token: 'token', intents: {'Guilds': true});

      final requiresReconnect = await runner.reloadConfig(nextConfig);
      expect(requiresReconnect, isTrue);
    });

    test('reconnect is NOT required when Lavalink config details change without changing presence', () async {
      final initial = BotConfig(
        token: 'token',
        intents: {'Guilds': true},
        lavalinkConfig: const LavalinkConfig(host: 'localhost', port: 2333),
      );
      final runner = DiscordRunner('test-bot', initial);

      final nextConfig = BotConfig(
        token: 'token',
        intents: {'Guilds': true},
        lavalinkConfig: const LavalinkConfig(host: 'other-host', port: 2334),
      );

      final requiresReconnect = await runner.reloadConfig(nextConfig);
      expect(requiresReconnect, isFalse);
    });
  });
  group('resolveEventWorkflowListenerMode', () {
    test('returns none when no event workflows and no legacy commands', () {
      final config = _config();
      expect(
        resolveEventWorkflowListenerMode(config),
        EventWorkflowListenerMode.none,
      );
    });

    test(
      'returns messageCreateOnly with legacy-enabled slash command only',
      () {
        final config = _config(
          commands: <Map<String, dynamic>>[
            _legacyEnabledCommand(type: 'chatInput'),
          ],
        );
        expect(
          resolveEventWorkflowListenerMode(config),
          EventWorkflowListenerMode.messageCreateOnly,
        );
      },
    );

    test('returns full when event workflow exists', () {
      final config = _config(
        workflows: <Map<String, dynamic>>[
          <String, dynamic>{
            'name': 'onMessage',
            'workflowType': workflowTypeEvent,
            'eventTrigger': <String, dynamic>{'event': 'messageCreate'},
            'actions': <Map<String, dynamic>>[],
          },
        ],
      );
      expect(
        resolveEventWorkflowListenerMode(config),
        EventWorkflowListenerMode.full,
      );
    });
  });

  group('shouldRebindEventWorkflowListeners', () {
    test('false for none -> none', () {
      final previous = _config();
      final next = _config();
      expect(shouldRebindEventWorkflowListeners(previous, next), isFalse);
    });

    test('false for full -> full', () {
      final previous = _config(
        workflows: <Map<String, dynamic>>[_eventWorkflow('messageCreate')],
      );
      final next = _config(
        workflows: <Map<String, dynamic>>[_eventWorkflow('guildMemberAdd')],
      );
      expect(shouldRebindEventWorkflowListeners(previous, next), isFalse);
    });

    test('true for none -> messageCreateOnly', () {
      final previous = _config();
      final next = _config(
        commands: <Map<String, dynamic>>[
          _legacyEnabledCommand(type: 'chatInput'),
        ],
      );
      expect(shouldRebindEventWorkflowListeners(previous, next), isTrue);
    });

    test('true for messageCreateOnly -> full', () {
      final previous = _config(
        commands: <Map<String, dynamic>>[
          _legacyEnabledCommand(type: 'chatInput'),
        ],
      );
      final next = _config(
        workflows: <Map<String, dynamic>>[_eventWorkflow('messageCreate')],
      );
      expect(shouldRebindEventWorkflowListeners(previous, next), isTrue);
    });

    test('true for full -> messageCreateOnly', () {
      final previous = _config(
        workflows: <Map<String, dynamic>>[_eventWorkflow('messageCreate')],
      );
      final next = _config(
        commands: <Map<String, dynamic>>[
          _legacyEnabledCommand(type: 'chatInput'),
        ],
      );
      expect(shouldRebindEventWorkflowListeners(previous, next), isTrue);
    });
  });

  group('isLegacyCommandEnabledInConfigEntry', () {
    test(
      'returns false for user command even if legacyModeEnabled is true',
      () {
        expect(
          isLegacyCommandEnabledInConfigEntry(
            _legacyEnabledCommand(type: 'user'),
          ),
          isFalse,
        );
      },
    );

    test(
      'returns false for message command even if legacyModeEnabled is true',
      () {
        expect(
          isLegacyCommandEnabledInConfigEntry(
            _legacyEnabledCommand(type: 'message'),
          ),
          isFalse,
        );
      },
    );
  });
}

BotConfig _config({
  List<Map<String, dynamic>> commands = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> workflows = const <Map<String, dynamic>>[],
}) {
  return BotConfig(token: 'token', commands: commands, workflows: workflows);
}

Map<String, dynamic> _legacyEnabledCommand({required String type}) {
  return <String, dynamic>{
    'type': type,
    'name': 'legacy',
    'data': <String, dynamic>{'legacyModeEnabled': true, 'commandType': type},
  };
}

Map<String, dynamic> _eventWorkflow(String eventName) {
  return <String, dynamic>{
    'name': 'wf-$eventName',
    'workflowType': workflowTypeEvent,
    'eventTrigger': <String, dynamic>{'event': eventName},
    'actions': <Map<String, dynamic>>[],
  };
}
