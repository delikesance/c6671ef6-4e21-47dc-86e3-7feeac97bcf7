import 'package:bot_creator_runner/web_log_store.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

void main() {
  group('RunnerLogStore TTL', () {
    test('filters out log lines older than 7 days', () {
      final store = RunnerLogStore();
      final now = DateTime.now().toUtc();
      final sixDaysAgo = now.subtract(const Duration(days: 6));
      final eightDaysAgo = now.subtract(const Duration(days: 8));

      // Inject old log
      store.add(
        LogRecord(Level.INFO, 'Old message', 'test'),
        botId: 'bot-ttl',
        timeOverride: eightDaysAgo,
      );

      // Inject recent log
      store.add(
        LogRecord(Level.INFO, 'Recent message', 'test'),
        botId: 'bot-ttl',
        timeOverride: sixDaysAgo,
      );

      final lines = store.tail(botId: 'bot-ttl', limit: 100);
      expect(lines.length, equals(1));
      expect(lines.first.contains('Recent message'), isTrue);
      expect(lines.first.contains('Old message'), isFalse);
    });
  });
}
