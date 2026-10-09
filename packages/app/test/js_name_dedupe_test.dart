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

  test('a payload rename is reported through onRenamed', () {
    final used = <String>{'ping'};
    final seen = <String>[];
    deduplicateCommandName(
      'Ping',
      used,
      onRenamed: (o, r) => seen.add('$o->$r'),
    );
    expect(seen, ['Ping->Ping_2']);
  });

  group('isCommandNameTaken', () {
    test('rejects an exact duplicate', () {
      expect(isCommandNameTaken('ping', ['ping', 'help']), isTrue);
    });

    test('ignores case and surrounding spaces', () {
      expect(isCommandNameTaken(' PING ', ['ping']), isTrue);
    });

    test('accepts a free name and an empty one', () {
      expect(isCommandNameTaken('pong', ['ping']), isFalse);
      expect(isCommandNameTaken('  ', ['ping']), isFalse);
    });

    test('renaming to its own name is allowed once it is excluded', () {
      final all = ['ping', 'help'];
      final others = all.where((n) => n != 'ping');
      expect(isCommandNameTaken('Ping', others), isFalse);
      expect(isCommandNameTaken('help', others), isTrue);
    });
  });

  group('suggestDuplicateCommandName', () {
    test('proposes <name>_copie when free', () {
      expect(suggestDuplicateCommandName('ping', ['ping']), 'ping_copie');
    });

    test('adds a numeric suffix when the copy name is taken', () {
      expect(
        suggestDuplicateCommandName('ping', ['ping', 'Ping_copie']),
        'ping_copie_2',
      );
    });

    test('stays within 32 characters', () {
      final long = 'a' * 32;
      final name = suggestDuplicateCommandName(long, [long]);
      expect(name.length, lessThanOrEqualTo(32));
      expect(name.endsWith('_copie'), isTrue);
    });
  });
}
