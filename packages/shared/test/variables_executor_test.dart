import 'package:bot_creator_shared/actions/executors/variables_executor.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

void main() {
  group('executeVariablesAction', () {
    test('appendArrayElement appends to a global root array', () async {
      final store = _MemoryBotDataStore();
      final results = <String, String>{};
      final variables = <String, String>{};

      final handled = await executeVariablesAction(
        type: BotCreatorActionType.appendArrayElement,
        store: store,
        botId: 'bot-1',
        payload: <String, dynamic>{
          'target': 'global',
          'key': 'scores',
          'valueType': 'number',
          'numberValue': '4',
        },
        resultKey: 'append',
        results: results,
        variables: variables,
        resolveValue: (input) => input,
        guildId: null,
        fallbackChannelId: null,
        interaction: null,
      );

      expect(handled, isTrue);
      expect(store.globalVariables['scores'], <dynamic>[4]);
      expect(results['append'], '[4]');
      expect(variables['global.scores'], '[4]');
      expect(variables['append.items'], '[4]');
      expect(variables['append.length'], '1');
    });

    test(
      'appendArrayElement and removeArrayElement support scoped JSON paths',
      () async {
        final store = _MemoryBotDataStore(
          scopedVariables: <String, Map<String, Map<String, dynamic>>>{
            'guild': <String, Map<String, dynamic>>{
              'guild-1': <String, dynamic>{
                'stats': <String, dynamic>{
                  'items': <Map<String, dynamic>>[
                    <String, dynamic>{'name': 'Alice'},
                  ],
                },
              },
            },
          },
        );
        final variables = <String, String>{'guildId': 'guild-1'};
        final appendResults = <String, String>{};

        await executeVariablesAction(
          type: BotCreatorActionType.appendArrayElement,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'target': 'scoped',
            'scope': 'guild',
            'key': 'stats',
            'path': r'$.items',
            'valueType': 'json',
            'jsonValue': '{"name":"Bob"}',
          },
          resultKey: 'appendScoped',
          results: appendResults,
          variables: variables,
          resolveValue: (input) => input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(
          store.scopedVariables['guild']?['guild-1']?['stats'],
          <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Alice'},
              <String, dynamic>{'name': 'Bob'},
            ],
          },
        );
        expect(variables['appendScoped.length'], '2');

        final removeResults = <String, String>{};
        await executeVariablesAction(
          type: BotCreatorActionType.removeArrayElement,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'target': 'scoped',
            'scope': 'guild',
            'key': 'stats',
            'path': r'$.items',
            'index': '0',
          },
          resultKey: 'removeScoped',
          results: removeResults,
          variables: variables,
          resolveValue: (input) => input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(
          store.scopedVariables['guild']?['guild-1']?['stats'],
          <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{'name': 'Bob'},
            ],
          },
        );
        expect(removeResults['removeScoped'], '[{"name":"Bob"}]');
        expect(variables['removeScoped.length'], '1');
        expect(variables['removeScoped.removed'], '{"name":"Alice"}');
      },
    );

    test(
      'queryArray filters, sorts, paginates and stores runtime aliases',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{};
        final variables = <String, String>{};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.queryArray,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'input':
                '{"items":[{"name":"Charlie","score":7},{"name":"Alice","score":12},{"name":"Bob","score":10}]}',
            'path': r'$.items',
            'filterTemplate': '{score}',
            'filterOperator': 'gte',
            'filterValue': '10',
            'sortTemplate': '{name}',
            'order': 'desc',
            'offset': '0',
            'limit': '1',
            'storeAs': 'topScores',
          },
          resultKey: 'query',
          results: results,
          variables: variables,
          resolveValue: (input) => input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['query'], '[{"name":"Bob","score":10}]');
        expect(variables['query.items'], '[{"name":"Bob","score":10}]');
        expect(variables['query.count'], '1');
        expect(variables['query.total'], '2');
        expect(variables['topScores'], '[{"name":"Bob","score":10}]');
      },
    );

    test(
      'getScopedVariable resolves user scope from fallback runtime identity keys',
      () async {
        final store = _MemoryBotDataStore(
          scopedVariables: <String, Map<String, Map<String, dynamic>>>{
            'user': <String, Map<String, dynamic>>{
              'user-42': <String, dynamic>{'profile': 'dark'},
            },
          },
        );
        final results = <String, String>{};
        final variables = <String, String>{
          'userId': 'Unknown User',
          'interaction.user.id': 'user-42',
        };

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.getScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{'scope': 'user', 'key': 'profile'},
          resultKey: 'getProfile',
          results: results,
          variables: variables,
          resolveValue: (input) => input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['getProfile'], 'dark');
        expect(variables['user.bc_profile'], 'dark');
        expect(variables['user.profile'], 'dark');
      },
    );

    test(
      'getScopedVariable reads legacy user context and copies to canonical context',
      () async {
        final store = _MemoryBotDataStore(
          scopedVariables: <String, Map<String, Map<String, dynamic>>>{
            'user': <String, Map<String, dynamic>>{
              'Unknown User': <String, dynamic>{'profile': 'legacy'},
            },
          },
        );
        final results = <String, String>{};
        final variables = <String, String>{'userId': 'user-99'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.getScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{'scope': 'user', 'key': 'profile'},
          resultKey: 'getProfile',
          results: results,
          variables: variables,
          resolveValue: (input) => input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['getProfile'], 'legacy');
        expect(store.scopedVariables['user']?['user-99']?['profile'], 'legacy');
        expect(
          store.scopedVariables['user']?['Unknown User']?['profile'],
          'legacy',
        );
      },
    );

    test(
      'runtimeJsonBlock bootstraps empty source and supports append/index',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{};
        final variables = <String, String>{};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.runtimeJsonBlock,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'source': '((guild.bc_items_db))',
            'operations': <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'arrayAppend',
                'path': <String>['items'],
                'value': 'sword',
              },
              <String, dynamic>{
                'op': 'arrayIndex',
                'path': <String>['items'],
                'value': 'sword',
                'readIndex': 0,
              },
            ],
          },
          resultKey: 'rtJson',
          results: results,
          variables: variables,
          resolveValue:
              (input) => input == '((guild.bc_items_db))' ? '' : input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['rtJson'], '{"items":["sword"]}');
        expect(variables['rtJson.json_0'], '0');
      },
    );

    test(
      'runtimeJsonBlock reuses same-block json reads inside later path segments',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{};
        final variables = <String, String>{};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.runtimeJsonBlock,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'source': '((guild.bc_items_db))',
            'operations': <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'arrayAppend',
                'path': <String>['items'],
                'value': 'shield',
              },
              <String, dynamic>{
                'op': 'arrayAppend',
                'path': <String>['items'],
                'value': 'potion',
              },
              <String, dynamic>{
                'op': 'arrayIndex',
                'path': <String>['items'],
                'value': 'potion',
                'readIndex': 0,
              },
              <String, dynamic>{
                'op': 'get',
                'path': <String>['items', '((rtJson.json_0))'],
                'readIndex': 1,
              },
            ],
          },
          resultKey: 'rtJson',
          results: results,
          variables: variables,
          resolveValue:
              (input) => input == '((guild.bc_items_db))' ? '' : input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['rtJson'], '{"items":["shield","potion"]}');
        expect(variables['rtJson.json_0'], '1');
        expect(variables['rtJson.json_1'], 'potion');
      },
    );

    test(
      'runtimeJsonBlock stores root json in variables for nested branch reuse',
      () async {
        final store = _MemoryBotDataStore();
        final parentResults = <String, String>{};
        final variables = <String, String>{};

        final parentHandled = await executeVariablesAction(
          type: BotCreatorActionType.runtimeJsonBlock,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'source': '((guild.bc_items_db))',
            'operations': <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'arrayIndex',
                'path': <String>['items'],
                'value': 'bow',
                'readIndex': 0,
              },
            ],
          },
          resultKey: 'rtJson_0',
          results: parentResults,
          variables: variables,
          resolveValue:
              (input) =>
                  input == '((guild.bc_items_db))'
                      ? '{"items":["axe","bow","wand"]}'
                      : input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(parentHandled, isTrue);
        expect(parentResults['rtJson_0'], '{"items":["axe","bow","wand"]}');
        expect(variables['rtJson_0'], '{"items":["axe","bow","wand"]}');
        expect(variables['rtJson_0.json_0'], '1');

        // Simulate nested if/else execution where branch actions get a fresh
        // results map but still share the same variables map.
        final branchResults = <String, String>{};
        final branchHandled = await executeVariablesAction(
          type: BotCreatorActionType.runtimeJsonBlock,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'source': '((rtJson_0))',
            'operations': <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'get',
                'path': <String>['items', '((rtJson_0.json_0))'],
                'readIndex': 0,
              },
            ],
          },
          resultKey: 'rtJson_1',
          results: branchResults,
          variables: variables,
          resolveValue: (input) => input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(branchHandled, isTrue);
        expect(branchResults['rtJson_1.json_0'], 'bow');
        expect(variables['rtJson_1.json_0'], 'bow');
      },
    );

    test(
      'runtimeJsonBlock recovers from scalar source by promoting to object',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{};
        final variables = <String, String>{};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.runtimeJsonBlock,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'source': '((guild.bc_items_db))',
            'operations': <Map<String, dynamic>>[
              <String, dynamic>{
                'op': 'arrayAppend',
                'path': <String>['items'],
                'value': 'sword',
              },
            ],
          },
          resultKey: 'rtJson',
          results: results,
          variables: variables,
          resolveValue:
              (input) =>
                  input == '((guild.bc_items_db))'
                      ? '1453848265786396794'
                      : input,
          guildId: null,
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(results['rtJson'], '{"items":["sword"]}');
      },
    );

    test(
      'setScopedVariable falls back to merged variables/results for placeholders',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{
          'rtJson_0.json_0': '{"items":["sword"]}',
        };
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': '((rtJson_0.json_0))',
          },
          resultKey: 'setItems',
          results: results,
          variables: variables,
          // Simulate a resolver that does not know action results.
          resolveValue: (input) => input == '((rtJson_0.json_0))' ? '' : input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["sword"]}',
        );
        expect(variables['guild.bc_items_db'], '{"items":["sword"]}');
        expect(variables['setItems.persisted'], '{"items":["sword"]}');
        expect(results['setItems'], 'OK');
      },
    );

    test(
      'setScopedVariable resolves non-empty unresolved placeholders from merged context',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{
          'rtJson_0.json_0': '{"items":["epee"]}',
        };
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': '((rtJson_0.json_0))',
          },
          resultKey: 'setItems2',
          results: results,
          variables: variables,
          // Simulate a resolver that leaves unknown placeholders unchanged.
          resolveValue: (input) => input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["epee"]}',
        );
        expect(variables['guild.bc_items_db'], '{"items":["epee"]}');
        expect(results['setItems2'], 'OK');
      },
    );

    test(
      'setScopedVariable falls back to rtJson root when json index key is missing',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{'rtJson_0': '{"items":["axe"]}'};
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': '((rtJson_0.json_9))',
          },
          resultKey: 'setItems3',
          results: results,
          variables: variables,
          // Simulate a resolver that does not know action results.
          resolveValue: (input) => input == '((rtJson_0.json_9))' ? '' : input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["axe"]}',
        );
        expect(variables['guild.bc_items_db'], '{"items":["axe"]}');
        expect(variables['setItems3.persisted'], '{"items":["axe"]}');
        expect(results['setItems3'], 'OK');
      },
    );

    test(
      'setScopedVariable resolves rtJson placeholder from action alias keys',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{
          'action_1.json_0': '{"items":["bow"]}',
          'action_1': '{"items":["bow"]}',
        };
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': '((rtJson_0.json_0))',
          },
          resultKey: 'setItems4',
          results: results,
          variables: variables,
          // Simulate a resolver that does not know action results.
          resolveValue: (input) => input == '((rtJson_0.json_0))' ? '' : input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["bow"]}',
        );
        expect(variables['setItems4.directFallback'], '{"items":["bow"]}');
        expect(variables['setItems4.persisted'], '{"items":["bow"]}');
        expect(results['setItems4'], 'OK');
      },
    );

    test(
      'setScopedVariable rtJson alias prefers JSON action value over status strings',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{
          'action_0': 'OK',
          'action_1': 'store',
          'action_2': '{"items":["shield"]}',
        };
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': '((rtJson_0))',
          },
          resultKey: 'setItems6',
          results: results,
          variables: variables,
          resolveValue: (input) => input == '((rtJson_0))' ? '' : input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["shield"]}',
        );
        expect(variables['setItems6.persisted'], '{"items":["shield"]}');
        expect(results['setItems6'], 'OK');
      },
    );

    test(
      r'setScopedVariable resolves literal $jsonStringify from runtime json results',
      () async {
        final store = _MemoryBotDataStore();
        final results = <String, String>{'rtJson_0': '{"items":["hammer"]}'};
        final variables = <String, String>{'guildId': 'guild-1'};

        final handled = await executeVariablesAction(
          type: BotCreatorActionType.setScopedVariable,
          store: store,
          botId: 'bot-1',
          payload: <String, dynamic>{
            'scope': 'guild',
            'key': 'items_db',
            'valueType': 'string',
            'value': r'$jsonStringify',
          },
          resultKey: 'setItems5',
          results: results,
          variables: variables,
          resolveValue: (input) => input == r'$jsonStringify' ? '' : input,
          guildId: Snowflake.parse('1'),
          fallbackChannelId: null,
          interaction: null,
        );

        expect(handled, isTrue);
        expect(
          store.scopedVariables['guild']?['guild-1']?['items_db'],
          '{"items":["hammer"]}',
        );
        expect(variables['setItems5.persisted'], '{"items":["hammer"]}');
        expect(results['setItems5'], 'OK');
      },
    );
  });
}

class _MemoryBotDataStore implements BotDataStore {
  _MemoryBotDataStore({
    Map<String, dynamic>? globalVariables,
    Map<String, Map<String, Map<String, dynamic>>>? scopedVariables,
  }) : globalVariables = globalVariables ?? <String, dynamic>{},
       scopedVariables =
           scopedVariables ?? <String, Map<String, Map<String, dynamic>>>{};

  final Map<String, dynamic> globalVariables;
  final Map<String, Map<String, Map<String, dynamic>>> scopedVariables;

  @override
  Future<List<Map<String, dynamic>>> getScopedVariableDefinitions(
    String botId,
  ) async {
    return const <Map<String, dynamic>>[];
  }

  @override
  Future<void> setScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {}

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String botId) async =>
      Map<String, dynamic>.from(globalVariables);

  @override
  Future<dynamic> getGlobalVariable(String botId, String key) async =>
      globalVariables[key];

  @override
  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value,
  ) async {
    globalVariables[key] = value;
  }

  @override
  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    if (!globalVariables.containsKey(oldKey)) {
      return;
    }
    globalVariables[newKey] = globalVariables.remove(oldKey);
  }

  @override
  Future<void> removeGlobalVariable(String botId, String key) async {
    globalVariables.remove(key);
  }

  @override
  Future<Map<String, dynamic>> getScopedVariables(
    String botId,
    String scope,
    String contextId,
  ) async {
    return Map<String, dynamic>.from(
      scopedVariables[scope]?[contextId] ?? const <String, dynamic>{},
    );
  }

  @override
  Future<dynamic> getScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    return scopedVariables[scope]?[contextId]?[key];
  }

  @override
  Future<void> setScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic value,
  ) async {
    scopedVariables.putIfAbsent(scope, () => <String, Map<String, dynamic>>{});
    scopedVariables[scope]!.putIfAbsent(contextId, () => <String, dynamic>{});
    scopedVariables[scope]![contextId]![key] = value;
  }

  @override
  Future<void> renameScopedVariable(
    String botId,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  ) async {
    final bucket = scopedVariables[scope]?[contextId];
    if (bucket == null || !bucket.containsKey(oldKey)) {
      return;
    }
    bucket[newKey] = bucket.remove(oldKey);
  }

  @override
  Future<void> removeScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    scopedVariables[scope]?[contextId]?.remove(key);
  }

  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<void> pushScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic element,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<dynamic> popScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<dynamic> removeScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<dynamic> getScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<int> getScopedArrayLength(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<Map<String, dynamic>> queryScopedArray(
    String botId,
    String scope,
    String contextId,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
    String? filter,
  }) async {
    throw UnsupportedError('Not used in these tests');
  }

  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async {
    throw UnsupportedError('Not used in these tests');
  }
}
