import 'package:bot_creator_shared/engine/event_dispatcher.dart';
import 'package:test/test.dart';

void main() {
  group(r'Issue #232: {$t} timed trigger modifier and message deletion', () {
    test(r'cleans {$t} from command trigger names', () {
      expect(EventDispatcher.cleanCommandTriggerName(r'clear {$t}'), 'clear');
      expect(
        EventDispatcher.cleanCommandTriggerName(r'purge {$t:5s}'),
        'purge',
      );
      expect(EventDispatcher.cleanCommandTriggerName(r'{$t}kick'), 'kick');
      expect(EventDispatcher.cleanCommandTriggerName('ban'), 'ban');
    });

    test(r'extracts timed trigger delay from {$t}', () {
      expect(
        EventDispatcher.extractTimedTriggerDelay(r'clear {$t}'),
        Duration.zero,
      );
      expect(
        EventDispatcher.extractTimedTriggerDelay(r'clear {$t:5s}'),
        const Duration(seconds: 5),
      );
      expect(
        EventDispatcher.extractTimedTriggerDelay(r'clear {$t:500ms}'),
        const Duration(milliseconds: 500),
      );
      expect(
        EventDispatcher.extractTimedTriggerDelay(r'clear {$t:2m}'),
        const Duration(minutes: 2),
      );
      expect(EventDispatcher.extractTimedTriggerDelay('clear'), isNull);
    });
  });
}
