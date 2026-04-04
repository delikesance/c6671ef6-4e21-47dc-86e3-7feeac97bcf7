import 'package:bot_creator/utils/discord_rich_presence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildBotCreatorRichPresence', () {
    test('builds an idle presence when no bots are running', () {
      final presence = buildBotCreatorRichPresence(
        runningBotIds: const <String>{},
        botNamesById: const <String, String>{},
        runnerModeEnabled: false,
      );

      expect(presence.details, 'Bot Creator open');
      expect(presence.state, 'Desktop ready');
    });

    test('prefers the selected bot when provided', () {
      final presence = buildBotCreatorRichPresence(
        runningBotIds: const <String>{'bot-b', 'bot-a'},
        botNamesById: const <String, String>{'bot-a': 'Alpha', 'bot-b': 'Beta'},
        runnerModeEnabled: true,
        preferredBotId: 'bot-b',
        preferredBotName: 'Beta Override',
        activeRunnerLabel: 'Local Runner',
      );

      expect(presence.details, 'Running Beta Override');
      expect(presence.state, 'Runner Local Runner • 2 bots active');
    });

    test('serializes timestamps as unix seconds', () {
      final startedAt = DateTime.utc(2026, 4, 4, 12, 0, 0);
      final presence = DiscordRichPresence(
        details: 'Running Demo',
        state: 'Local desktop runtime',
        startTime: startedAt,
      );

      final json = presence.toActivityJson();
      expect(json['type'], 0);
      expect(json['timestamps'], <String, dynamic>{
        'start': startedAt.millisecondsSinceEpoch ~/ 1000,
      });
    });
  });
}
