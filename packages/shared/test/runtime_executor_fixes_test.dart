import 'package:bot_creator_shared/actions/executors/control_flow_executor.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

/// Comprehensive runtime executor tests for:
/// 1. $for[varName;val1;val2;...] list iteration (mode: 'list')
/// 2. $jsonArray[key;separator] splitting (initArray with separator)
/// 3. $json[] context initialization end-to-end
/// 4. $jsonKey[]/$jsonValue[] inside $jsonForEach end-to-end
void main() {
  // ─────────────────────────────────────────────────────────────────────
  // 1. DIRECT TESTS: _executeListForLoop (mode: 'list')
  // ─────────────────────────────────────────────────────────────────────
  group('executeControlFlowAction forLoop list mode', () {
    Future<bool> runListLoop({
      required Map<String, dynamic> payload,
      required Map<String, String> results,
      required List<List<Action>> executedBatches,
      required Map<String, String> variables,
      String Function(String input)? resolveValue,
    }) {
      return executeControlFlowAction(
        type: BotCreatorActionType.forLoop,
        payload: payload,
        resultKey: 'loop',
        results: results,
        variables: variables,
        botId: 'test_bot',
        resolveValue: resolveValue ?? (input) => input,
        onLog: null,
        activeWorkflowStack: <String>{},
        getWorkflowByName: (_) async => null,
        executeActions: (actions) async {
          final resolvedActions = actions.map((a) {
            final resolvedPayload = a.payload.map((key, value) {
              if (value is String) {
                return MapEntry(
                  key,
                  resolveTemplatePlaceholders(value, variables),
                );
              }
              return MapEntry(key, value);
            });
            return Action(
              type: a.type,
              payload: resolvedPayload,
              key: a.key,
              enabled: a.enabled,
            );
          }).toList();
          executedBatches.add(resolvedActions);
          return <String, String>{'nested': 'ok'};
        },
      );
    }

    test('iterates over static resolved values', () async {
      final results = <String, String>{};
      final batches = <List<Action>>[];
      final variables = <String, String>{};

      await runListLoop(
        variables: variables,
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': <String>['sword', 'shield', 'potion'],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{
                'content': 'Item: ((_loop.var.item))',
              },
            },
          ],
        },
        results: results,
        executedBatches: batches,
      );

      expect(batches, hasLength(3));
      expect(results['loop'], 'LOOP_3');
      expect(batches[0][0].payload['content'], 'Item: sword');
      expect(batches[1][0].payload['content'], 'Item: shield');
      expect(batches[2][0].payload['content'], 'Item: potion');
    });

    test('sets _loop.index (0-based) and _loop.count (1-based)', () async {
      final results = <String, String>{};
      final batches = <List<Action>>[];
      final variables = <String, String>{};

      await runListLoop(
        variables: variables,
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'x',
          'values': <String>['a', 'b', 'c'],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{
                'content':
                    '#((_loop.count)) idx:((_loop.index)) = ((_loop.var.x))',
              },
            },
          ],
        },
        results: results,
        executedBatches: batches,
      );

      expect(batches, hasLength(3));
      expect(batches[0][0].payload['content'], '#1 idx:0 = a');
      expect(batches[1][0].payload['content'], '#2 idx:1 = b');
      expect(batches[2][0].payload['content'], '#3 idx:2 = c');
    });

    test('executes the entire list despite obsolete maxIterations', () async {
      final results = <String, String>{};
      final batches = <List<Action>>[];

      await runListLoop(
        variables: <String, String>{},
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': List<String>.generate(10, (i) => 'val$i'),
          'maxIterations': 5,
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{'content': '((_loop.var.item))'},
            },
          ],
        },
        results: results,
        executedBatches: batches,
      );

      expect(batches, hasLength(10));
      expect(results['loop'], 'LOOP_10');
    });

    test('propagates __stopped__', () async {
      final results = <String, String>{};

      await executeControlFlowAction(
        type: BotCreatorActionType.forLoop,
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': <String>['a', 'b', 'c'],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{'content': '((_loop.var.item))'},
            },
          ],
        },
        resultKey: 'loop',
        results: results,
        variables: <String, String>{},
        botId: 'test_bot',
        resolveValue: (input) => input,
        onLog: null,
        activeWorkflowStack: <String>{},
        getWorkflowByName: (_) async => null,
        executeActions: (actions) async {
          return <String, String>{'__stopped__': 'true'};
        },
      );

      expect(results['__stopped__'], 'true');
    });

    test('resolves runtime values via resolveValue', () async {
      final results = <String, String>{};
      final batches = <List<Action>>[];
      final variables = <String, String>{};

      await runListLoop(
        variables: variables,
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': <String>['((temp.custom))', 'static'],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{'content': '((_loop.var.item))'},
            },
          ],
        },
        results: results,
        executedBatches: batches,
        resolveValue: (input) => input.replaceAll('((temp.custom))', 'dynamic'),
      );

      expect(batches, hasLength(2));
      expect(batches[0][0].payload['content'], 'dynamic');
      expect(batches[1][0].payload['content'], 'static');
    });

    test('handles empty values list', () async {
      final results = <String, String>{};
      final batches = <List<Action>>[];

      await runListLoop(
        variables: <String, String>{},
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': <String>[],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{'content': 'x'},
            },
          ],
        },
        results: results,
        executedBatches: batches,
      );

      expect(batches, isEmpty);
      expect(results['loop'], 'LOOP_0');
    });

    test('cleans up loop variables after execution', () async {
      final results = <String, String>{};
      final variables = <String, String>{};

      await runListLoop(
        variables: variables,
        payload: <String, dynamic>{
          'mode': 'list',
          'varName': 'item',
          'values': <String>['a', 'b'],
          'bodyActions': <Map<String, dynamic>>[
            <String, dynamic>{
              'type': 'sendMessage',
              'payload': <String, dynamic>{'content': '((_loop.var.item))'},
            },
          ],
        },
        results: results,
        executedBatches: <List<Action>>[],
      );

      expect(variables.containsKey('_loop.var.item'), isFalse);
      expect(variables.containsKey('_loop.index'), isFalse);
      expect(variables.containsKey('_loop.count'), isFalse);
    });
  });
}
