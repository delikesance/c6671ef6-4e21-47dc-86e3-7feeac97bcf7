import 'package:bot_creator_shared/bot/json_variable_store.dart';
import 'package:test/test.dart';

void main() {
  test('removeAllScopedValuesForKey clears one key across contexts', () async {
    final store = JsonVariableStore.fromMaps(
      scopedVariables: {
        'user': {
          'u1': {'coins': 10, 'xp': 1},
          'u2': {'coins': 50},
        },
      },
    );

    await store.removeAllScopedValuesForKey('bot', 'user', 'coins');

    expect(await store.getScopedVariable('bot', 'user', 'u1', 'coins'), isNull);
    expect(await store.getScopedVariable('bot', 'user', 'u1', 'xp'), 1);
    expect(await store.getScopedVariable('bot', 'user', 'u2', 'coins'), isNull);
  });

  test('queryScopedVariableIndex allows limit up to 1000', () async {
    final byContext = <String, Map<String, dynamic>>{};
    for (var i = 0; i < 40; i++) {
      byContext['u$i'] = {'score': i};
    }
    final store = JsonVariableStore.fromMaps(
      scopedVariables: {'user': byContext},
    );

    final page = await store.queryScopedVariableIndex(
      'bot',
      'user',
      'score',
      limit: 40,
    );
    expect(page['count'], 40);
    expect(page['total'], 40);
  });
}
