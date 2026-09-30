import 'package:bot_creator_shared/utils/application_command_lookup.dart';
import 'package:test/test.dart';

Map<String, dynamic> command(
  String id,
  String name, {
  String type = 'chatInput',
  Map<String, dynamic> data = const {},
}) => {'id': id, 'name': name, 'type': type, 'data': data};

void main() {
  test('restored IDs resolve without changing the history identity', () {
    final restored = command('old-id', 'daily');
    expect(
      findApplicationCommand(
        [restored],
        discordId: 'new-id',
        name: 'daily',
        type: 'chatInput',
      ),
      same(restored),
    );
    final synced = withDiscordCommandId(restored, 'old-id', 'new-id');
    expect(synced['id'], 'old-id');
    expect(synced['discordId'], 'new-id');
    expect(restored.containsKey('discordId'), isFalse);
    expect(
      findApplicationCommand(
        [synced],
        discordId: 'new-id',
        name: 'daily',
        type: 'chatInput',
      ),
      same(synced),
    );
  });
  test('exact Discord ID wins over an ambiguous name', () {
    final target = command('stable', 'daily')..['discordId'] = 'live';
    expect(
      findApplicationCommand(
        [command('old', 'daily'), target],
        discordId: 'live',
        name: 'daily',
        type: 'chatInput',
      ),
      same(target),
    );
  });
  test('ambiguous names and duplicate IDs reject arbitrary workflows', () {
    final duplicates = [command('one', 'daily'), command('two', 'daily')];
    expect(
      findApplicationCommand(
        duplicates,
        discordId: 'missing',
        name: 'daily',
        type: 'chatInput',
      ),
      isNull,
    );
    duplicates[1]['discordId'] = 'one';
    expect(
      findApplicationCommand(
        duplicates,
        discordId: 'one',
        name: 'daily',
        type: 'chatInput',
      ),
      isNull,
    );
  });
  test('same-named context menus cannot intercept slash commands', () {
    final slash = command('slash-old', 'daily');
    expect(
      findApplicationCommand(
        [command('live', 'daily', type: 'user'), slash],
        discordId: 'live',
        name: 'daily',
        type: 'chatInput',
      ),
      same(slash),
    );
    expect(
      findApplicationCommand(
        [slash],
        discordId: 'slash-old',
        name: 'daily',
        type: 'message',
      ),
      isNull,
    );
  });
  test('prefix and local-only commands never run through interactions', () {
    for (final flag in ['legacyModeEnabled', 'legacyLocalOnly', 'localOnly']) {
      expect(
        findApplicationCommand(
          [
            command('live', 'daily', data: {flag: true}),
          ],
          discordId: 'live',
          name: 'daily',
          type: 'chatInput',
        ),
        isNull,
      );
    }
  });
}
