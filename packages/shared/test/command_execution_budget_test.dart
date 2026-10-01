import 'package:bot_creator_shared/actions/execution_budget.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

void main() {
  test('production default deadline is fifteen minutes', () {
    expect(CommandExecutionBudget().limit, const Duration(minutes: 15));
  });
  test(
    'expired budget stays cancelled after a pending operation finishes',
    () async {
      final budget = CommandExecutionBudget(
        limit: const Duration(milliseconds: 20),
      );
      await expectLater(
        budget.run(
          () => Future<void>.delayed(const Duration(milliseconds: 70)),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(budget.check, throwsA(isA<CommandExecutionTimeout>()));
    },
  );
  test(
    'nested wait shares the command deadline and cannot execute later actions',
    () async {
      final variables = <String, String>{};
      await expectLater(
        handleActions(
          _NoDiscord(),
          null,
          store: MemoryBotDataStore(),
          botId: 'bot',
          resolveTemplate: (s) => s,
          actions: [
            Action(
              type: BotCreatorActionType.ifBlock,
              payload: {
                'condition.variable': 'yes',
                'condition.operator': 'equals',
                'condition.value': 'yes',
                'thenActions': [
                  {
                    'type': 'wait',
                    'payload': {'duration': '150ms'},
                  },
                  {
                    'type': 'setTemporaryVariable',
                    'payload': {'key': 'late', 'value': 'bad'},
                  },
                ],
              },
            ),
            Action(
              type: BotCreatorActionType.setTemporaryVariable,
              payload: {'key': 'after', 'value': 'bad'},
            ),
          ],
          variables: variables,
          executionBudget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 30),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(variables['temp.late'], isNull);
      expect(variables['temp.after'], isNull);
    },
  );
  test('infinite C-style loop stops at the shared deadline', () async {
    final variables = <String, String>{};
    await expectLater(
      handleActions(
        _NoDiscord(),
        null,
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: variables,
        resolveTemplate: (s) => s,
        executionBudget: CommandExecutionBudget(
          limit: const Duration(milliseconds: 30),
        ),
        actions: [
          Action(
            type: BotCreatorActionType.forLoop,
            payload: {
              'mode': 'cstyle',
              'init': 'i=0',
              'condition': '0 == 0',
              'update': 'i++',
              'varNames': ['i'],
              'bodyActions': [
                {
                  'type': 'setTemporaryVariable',
                  'payload': {'key': 'touched', 'value': 'yes'},
                },
              ],
            },
          ),
        ],
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    final index = variables['_loop.index'];
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(variables['_loop.index'], index);
  });
  for (final mode in [ActionOnErrorMode.stop, ActionOnErrorMode.continueMode]) {
    test(
      'executor error respects ${mode.name} before subsequent actions',
      () async {
        final variables = <String, String>{};
        final run = handleActions(
          _NoDiscord(),
          null,
          store: MemoryBotDataStore(),
          botId: 'bot',
          resolveTemplate: (s) => s,
          actions: [
            Action(type: BotCreatorActionType.addRole, payload: {})
              ..error['mode'] = mode == ActionOnErrorMode.stop
                  ? 'stop'
                  : 'continue',
            Action(
              type: BotCreatorActionType.setTemporaryVariable,
              payload: {'key': 'after', 'value': 'ok'},
            ),
          ],
          variables: variables,
        );
        if (mode == ActionOnErrorMode.stop) {
          await expectLater(run, throwsA(isA<Exception>()));
          expect(variables['temp.after'], isNull);
        } else {
          final result = await run;
          expect(result['action_0'], contains('guild context'));
          expect(variables['temp.after'], 'ok');
        }
        expect(variables['error.command'], 'addRole');
      },
    );
  }
}
