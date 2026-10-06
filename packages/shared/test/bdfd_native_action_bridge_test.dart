import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/services/http_service.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'package:bot_creator_shared/engine/workflow_executor.dart';
import 'package:bot_creator_shared/engine/bot_engine_callbacks.dart';
import 'helpers/variables_test_helpers.dart';

class _Gateway implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

class _Messages implements BotMessageService {
  final sent = <String>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    sent.add(request.payload['content'].toString());
    return BotMessageResult(messageId: '${sent.length}');
  }
}

class _Policy implements ActionExecutionPolicy {
  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() {}
  @override
  void record(Map<String, dynamic> frame) {}
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async => false;
}

class _Store extends MemoryBotDataStore {
  Map<String, dynamic>? workflow;
  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => workflow;
}

Action _script(String source) => Action(
  type: BotCreatorActionType.runBdfdScript,
  payload: {'bdfdBackend': 'native-v1', 'scriptContent': source},
);
Future<Map<String, String>> _run(
  List<Action> actions,
  _Store store,
  _Messages messages, {
  Map<String, String>? variables,
  CommandExecutionBudget? budget,
  ActionExecutionPolicy? executionPolicy,
}) {
  final values = variables ?? <String, String>{};
  return handleActions(
    _Gateway(),
    null,
    actions: actions,
    store: store,
    botId: 'bot',
    variables: values,
    resolveTemplate: (s) => resolveTemplatePlaceholders(s, values),
    executionPolicy: executionPolicy,
    bdfdMessages: messages,
    bdfdHttp: HttpService(
      clientFactory: () => throw StateError('Unexpected HTTP access'),
    ),
    throwOnError: true,
    executionBudget: budget,
  );
}

void main() {
  test(
    'native runBdfdScript shares temporary values with real visual executors',
    () async {
      final values = <String, String>{};
      final store = _Store();
      final messages = _Messages();
      await _run(
        [
          Action(
            type: BotCreatorActionType.setTemporaryVariable,
            payload: {'key': 'seed', 'value': '4'},
          ),
          _script(r'$var[count;$sum[$var[seed];1]]'),
          _script(
            r'$var[count;$sum[$var[count];1]]$setVar[done;$var[count]]$var[count]',
          ),
          Action(
            type: BotCreatorActionType.setTemporaryVariable,
            payload: {'key': 'observed', 'value': '((temp.count))'},
          ),
        ],
        store,
        messages,
        variables: values,
      );
      expect(store.globalVariables['done'], '6');
      expect(values['temp.observed'], '6');
      expect(messages.sent, ['6']);
    },
  );
  test(
    'native source keeps unknown functions and placeholders without interpolation',
    () async {
      final values = <String, String>{'temp.x': 'original', 'secret': 'wrong'};
      final messages = _Messages();
      await _run(
        [_script(r'$unknown[$var[x;changed]] ((secret)) $var[x]')],
        _Store(),
        messages,
        variables: values,
      );
      expect(messages.sent, [r'$unknown[$var[x;changed]] ((secret)) original']);
      expect(values['temp.x'], 'original');
    },
  );
  test('native session survives nested visual branches', () async {
    final messages = _Messages();
    await _run(
      [
        _script(r'$jsonParse[{"n":4}]$textSplit[a,b;,]'),
        Action(
          type: BotCreatorActionType.ifBlock,
          payload: {
            'conditionVariable': 'true',
            'conditionOperator': 'equals',
            'conditionValue': 'true',
            'thenActions': [_script(r'$json[n]:$splitText[2]').toJson()],
          },
        ),
      ],
      _Store(),
      messages,
    );
    expect(messages.sent, ['4:b']);
  });
  test(
    'script workflows execute natively and stop their visual caller',
    () async {
      final store = _Store()
        ..workflow = {
          'name': 'child',
          'data': {
            'executionMode': 'bdfd_script',
            'bdfdBackend': 'native-v1',
            'bdfdScriptContent':
                r'$setVar[before;yes]$onlyIf[false;denied]$setVar[insideAfter;bad]',
          },
        };
      final messages = _Messages();
      final results = await _run(
        [
          Action(
            type: BotCreatorActionType.runWorkflow,
            payload: {'workflowName': 'child'},
          ),
          _script(r'$setVar[parentAfter;bad]'),
        ],
        store,
        messages,
      );
      expect(results['__stopped__'], 'true');
      expect(store.globalVariables, {'before': 'yes'});
      expect(messages.sent, ['denied']);
    },
  );
  test(
    'known unsupported functions fail before sending and do not compile to blocks',
    () async {
      final messages = _Messages();
      await expectLater(
        _run(
          [_script(r'$sendMessage[never]$kick[222]')],
          _Store(),
          messages,
          executionPolicy: _Policy(),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(messages.sent, isEmpty);
    },
  );
  test('native bridge obeys the callers cancelled execution budget', () async {
    final messages = _Messages();
    final budget = CommandExecutionBudget(limit: Duration.zero);
    await expectLater(
      _run(
        [_script(r'$sendMessage[never]')],
        _Store(),
        messages,
        budget: budget,
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(messages.sent, isEmpty);
  });
  test(
    'general workflow preprocessing preserves native source at every nesting level',
    () async {
      final messages = _Messages();
      final executor = WorkflowExecutor(
        store: _Store(),
        callbacks: const BotEngineCallbacks(),
        bdfdMessages: messages,
      );
      final variables = <String, String>{
        'bdfd.userVariableSemantics': '2',
        'user.username': 'Owner',
      };
      await executor.executeGeneralWorkflow(
        workflowData: {
          'actions': [
            _script(r'$username').toJson(),
            Action(
              type: BotCreatorActionType.ifBlock,
              payload: {
                'conditionVariable': 'true',
                'conditionOperator': 'equals',
                'conditionValue': 'true',
                'thenActions': [_script(r'$username').toJson()],
              },
            ).toJson(),
          ],
        },
        gateway: _Gateway(),
        botId: 'bot',
        runtimeVariables: variables,
      );
      expect(messages.sent, ['Owner', 'Owner']);
    },
  );
  test(
    'execution policy cannot fall through to live moderation without an adapter',
    () async {
      final messages = _Messages();
      await expectLater(
        handleActions(
          _Gateway(),
          null,
          actions: [_script(r'$sendMessage[never]$kick[222]')],
          store: _Store(),
          botId: 'bot',
          variables: {'guild.id': '10'},
          resolveTemplate: (value) => value,
          executionPolicy: _Policy(),
          bdfdMessages: messages,
          bdfdHttp: HttpService(
            clientFactory: () => throw StateError('Unexpected HTTP'),
          ),
          throwOnError: true,
        ),
        throwsA(
          isA<BdfdNativeError>().having(
            (e) => e.message,
            'message',
            contains(r'Unsupported native function $kick'),
          ),
        ),
      );
      expect(messages.sent, isEmpty);
    },
  );
}
