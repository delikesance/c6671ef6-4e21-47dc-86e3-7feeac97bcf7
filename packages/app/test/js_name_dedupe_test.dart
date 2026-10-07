import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('duplicates are detected without regard to case, like the runner', () {
    final used = <String>{};
    expect(deduplicateCommandName('Ping', used), 'Ping');
    expect(deduplicateCommandName('ping', used), 'ping_2');
    expect(deduplicateCommandName('PING', used), 'PING_3');
  });

  test('a suffixed name still fits the 32 characters of the schema', () {
    final used = <String>{};
    final long = 'a' * 32;
    expect(deduplicateCommandName(long, used).length, 32);
    final second = deduplicateCommandName(long, used);
    expect(second.length, lessThanOrEqualTo(32));
    expect(second.endsWith('_2'), isTrue);
    expect(used.length, 2);
  });
}
