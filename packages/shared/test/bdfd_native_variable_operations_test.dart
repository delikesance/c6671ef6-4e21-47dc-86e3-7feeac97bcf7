import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/variable_functions.dart';
import 'package:bot_creator_shared/services/variable_service.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _IndexedStore extends MemoryBotDataStore {
  _IndexedStore({
    super.scopedDefinitions,
    super.scopedVariables,
    super.globalVariables,
  });
  int pages = 0;
  int writes = 0;
  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) async {
    pages++;
    final items = <Map<String, dynamic>>[
      for (final entry in (scopedVariables[scope] ?? {}).entries)
        if (entry.value.containsKey(key))
          {'contextId': entry.key, 'value': entry.value[key]},
    ]..sort((a, b) => a['value'].toString().compareTo(b['value'].toString()));
    final end = (offset + limit).clamp(0, items.length);
    return {
      'items': offset >= items.length ? [] : items.sublist(offset, end),
      'total': items.length,
    };
  }

  @override
  Future<void> setScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    writes++;
    await super.setScopedVariable(
      botId,
      scope,
      contextId,
      key,
      value,
      ttl: ttl,
    );
  }
}

void main() {
  BdfdRuntime runtime(MemoryBotDataStore store, {bool legacy = false}) =>
      BdfdRuntime(
        functions: bdfdVariableFunctions(
          VariableService(store, 'bot'),
          legacyUserVariables: legacy,
        ),
      );
  test(
    'varExists checks definitions or global keys without creating values',
    () async {
      final store = _IndexedStore(
        globalVariables: {'Global': ''},
        scopedDefinitions: [
          {'scope': 'guildMember', 'key': 'bc_Money', 'defaultValue': 0},
        ],
      );
      expect(
        await runtime(
          store,
        ).execute(r'$varExists[Money]/$varExists[Global]/$varExists[Hi]'),
        'true/true/false',
      );
      expect(store.writes, 0);
      expect(store.scopedVariables, isEmpty);
      expect(store.globalVariables, {'Global': ''});
    },
  );
  for (final entry in {
    'resetServerVar': 'guild',
    'resetChannelVar': 'channel',
  }.entries) {
    test(
      '${entry.key} restores defaults everywhere preserving other scopes and keys',
      () async {
        final store = _IndexedStore(
          scopedDefinitions: [
            {'scope': entry.value, 'key': 'count', 'defaultValue': 0},
          ],
          scopedVariables: {
            entry.value: {
              '1': {'count': 5, 'other': 9},
              '2': {'count': 8},
            },
            'user': {
              '3': {'count': 12},
            },
          },
        );
        expect(await runtime(store).execute('\$${entry.key}[count]'), '');
        expect(store.scopedVariables[entry.value], {
          '1': {'count': 0, 'other': 9},
          '2': {'count': 0},
        });
        expect(store.scopedVariables['user']!['3']!['count'], 12);
        expect(store.scopedDefinitions.single['defaultValue'], 0);
      },
    );
  }
  test(
    'resetUserVar without ID resets everyone across guild member contexts',
    () async {
      final store = _IndexedStore(
        scopedDefinitions: [
          {'scope': 'guildMember', 'key': 'score', 'defaultValue': 7},
        ],
        scopedVariables: {
          'guildMember': {
            '1:2': {'score': 12},
            '3:2': {'score': 40},
            '1:4': {'score': 55},
          },
          'user': {
            '2': {'score': 100},
          },
        },
      );
      await runtime(store).execute(r'$resetUserVar[score]');
      expect(
        store.scopedVariables['guildMember']!.values.map((v) => v['score']),
        everyElement(7),
      );
      expect(store.scopedVariables['user']!['2']!['score'], 100);
    },
  );
  test('explicit reset user selects that user only across guilds', () async {
    final store = _IndexedStore(
      scopedDefinitions: [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': false},
      ],
      scopedVariables: {
        'guildMember': {
          '1:2': {'score': 12},
          '3:2': {'score': 40},
          '1:4': {'score': 55},
        },
      },
    );
    await runtime(store).execute(r'$resetUserVar[score;2]');
    expect(store.scopedVariables['guildMember']!['1:2']!['score'], false);
    expect(store.scopedVariables['guildMember']!['3:2']!['score'], false);
    expect(store.scopedVariables['guildMember']!['1:4']!['score'], 55);
  });
  test(
    'legacy user mode resets global user scope without changing guild values',
    () async {
      final store = _IndexedStore(
        scopedDefinitions: [
          {'scope': 'user', 'key': 'score', 'defaultValue': 'start'},
        ],
        scopedVariables: {
          'user': {
            '2': {'score': 'changed'},
          },
          'guildMember': {
            '1:2': {'score': 'guild'},
          },
        },
      );
      await runtime(store, legacy: true).execute(r'$resetUserVar[score;2]');
      expect(store.scopedVariables['user']!['2']!['score'], 'start');
      expect(store.scopedVariables['guildMember']!['1:2']!['score'], 'guild');
    },
  );
  test(
    'index snapshot handles multiple pages despite reordered default values',
    () async {
      final store = _IndexedStore(
        scopedDefinitions: [
          {'scope': 'guild', 'key': 'score', 'defaultValue': -1},
        ],
        scopedVariables: {
          'guild': {
            for (var i = 0; i < 600; i++) '$i': {'score': i},
          },
        },
      );
      await runtime(store).execute(r'$resetServerVar[score]');
      expect(store.writes, 600);
      expect(
        store.scopedVariables['guild']!.values.map((v) => v['score']),
        everyElement(-1),
      );
      expect(store.pages, 4);
    },
  );
  test(
    'empty defaults also replace old prefixed aliases and legacy contexts',
    () async {
      final store = _IndexedStore(
        scopedDefinitions: [
          {'scope': 'guild', 'key': 'bc_score', 'default_value': ''},
        ],
        scopedVariables: {
          'guild': {
            'DM': {'bc_score': 'old'},
            '1': {'bc_score': 'old', 'score': 'canonical'},
          },
        },
      );
      await runtime(store).execute(r'$resetServerVar[bc_score]');
      expect(store.scopedVariables['guild']!['DM'], {
        'bc_score': '',
        'score': '',
      });
      expect(store.scopedVariables['guild']!['1'], {
        'bc_score': '',
        'score': '',
      });
      expect(await runtime(store).execute(r'$getServerVar[score;1]'), '');
    },
  );
  test('reset missing declaration fails without inventing a default', () async {
    final store = _IndexedStore(
      scopedVariables: {
        'guild': {
          '1': {'score': 55},
        },
      },
    );
    await expectLater(
      runtime(store).execute(r'$resetServerVar[score]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(store.writes, 0);
    expect(store.scopedVariables['guild']!['1']!['score'], 55);
  });
  test('structured defaults persist as structured values', () async {
    final store = _IndexedStore(
      scopedDefinitions: [
        {
          'scope': 'channel',
          'key': 'list',
          'defaultValue': ['default'],
        },
      ],
      scopedVariables: {
        'channel': {
          '1': {'list': 'changed'},
        },
      },
    );
    await runtime(store).execute(r'$resetChannelVar[list]');
    expect(store.scopedVariables['channel']!['1']!['list'], ['default']);
  });
  test('preflight rejects arity before earlier effects', () async {
    final store = _IndexedStore();
    for (final script in [
      r'$setVar[x;written]$resetServerVar[x;1]',
      r'$setVar[x;written]$resetChannelVar[x;1]',
      r'$setVar[x;written]$resetUserVar[x;1;2]',
      r'$setVar[x;written]$varExists[x;y]',
    ]) {
      await expectLater(
        runtime(store).execute(script),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(store.globalVariables, isEmpty);
  });
  test(
    'invalid user IDs and empty names fail before storage changes',
    () async {
      final store = _IndexedStore();
      for (final id in ['', '0', '-1', '<@2>', '18446744073709551616']) {
        await expectLater(
          runtime(store).execute('\$resetUserVar[x;$id]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      for (final fn in [
        'resetUserVar',
        'resetServerVar',
        'resetChannelVar',
        'varExists',
      ]) {
        await expectLater(
          runtime(store).execute('\$$fn[]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(store.writes, 0);
    },
  );
  test('unknown function arguments remain opaque', () async {
    final store = _IndexedStore();
    const source = r'$notAFunction[$setVar[x;bad]]';
    expect(await runtime(store).execute(source), source);
    expect(store.globalVariables, isEmpty);
  });
  test('budget callback prevents writes after index reads', () async {
    final store = _IndexedStore(
      scopedDefinitions: [
        {'scope': 'guild', 'key': 'x', 'defaultValue': 0},
      ],
      scopedVariables: {
        'guild': {
          '1': {'x': 3},
        },
      },
    );
    await expectLater(
      VariableService(store, 'bot').resetScoped(
        scope: 'guild',
        key: 'x',
        checkBudget: () {
          if (store.pages >= 1) throw StateError('cancel');
        },
      ),
      throwsStateError,
    );
    expect(store.writes, 0);
  });
}
