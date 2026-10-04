import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/fake_role_gateway.dart';
import 'helpers/variables_test_helpers.dart';

/// Parity of the control-flow family (ifBlock with tryCatch / suppressErrors /
/// every error mode, forLoop, jsonForEachLoop, stopUnless, stop, skipActions,
/// jumpToAction, wait, runWorkflow, runBdfdScript, log) between the historical
/// executors (`ActionTranslator.none()`) and the native engine. Effects are
/// observed through role changes (addRole / removeRole are native since wave 0),
/// script messages and log lines.

class _Spy extends ActionTranslator {
  _Spy() : super();
  int native = 0;
  @override
  BdfdActionProgram translate(
    List<Action> actions, {
    int firstIndex = 0,
    bool topLevelErrorModes = true,
  }) {
    native++;
    return super.translate(
      actions,
      firstIndex: firstIndex,
      topLevelErrorModes: topLevelErrorModes,
    );
  }
}

class _Messages implements BotMessageService {
  final sent = <String>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    sent.add(request.payload['content'].toString());
    return BotMessageResult(messageId: '${sent.length}');
  }
}

class _Store extends MemoryBotDataStore {
  _Store(this.workflows);
  final Map<String, Map<String, dynamic>> workflows;
  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => workflows[name];
}

class _Outcome {
  _Outcome({
    required this.gateway,
    required this.messages,
    required this.logs,
    required this.results,
    required this.variables,
    required this.error,
    required this.native,
    required this.frames,
  });
  final FakeGateway gateway;
  final _Messages messages;
  final List<String> logs;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;
  final List<Map<String, dynamic>> frames;

  Map<String, Object?> get effects => {
    'roleChanges': gateway.guild.memberManager.roleChanges,
    'messages': messages.sent,
    'logs': logs,
  };
  String? get errorText => error == null
      ? null
      : '${error.runtimeType}: ${error is CommandExecutionTimeout ? 'timeout' : error}';
  List<String> get changedUsers => [
    for (final change in gateway.guild.memberManager.roleChanges)
      change['user'].toString(),
  ];
}

Future<_Outcome> _execute(
  List<Action> actions, {
  required bool native,
  Map<String, String>? variables,
  Map<String, Map<String, dynamic>> workflows = const {},
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  int? maxSteps,
}) async {
  final gateway = FakeGateway()
    ..guild.permissions = Permissions.manageRoles.value;
  final messages = _Messages();
  final logs = <String>[];
  final values = <String, String>{'guild.id': '10', ...?variables};
  final spy = _Spy();
  final frames = <Map<String, dynamic>>[];
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      gateway,
      null,
      actions: actions,
      store: _Store(workflows),
      botId: 'bot',
      variables: values,
      fallbackGuildId: Snowflake(10),
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      bdfdMessages: messages,
      onLog: logs.add,
      executionPolicy: policy,
      throwOnError: throwOnError,
      onReplayCaptured: (captured, _) => frames.addAll(captured),
      visualMaxSteps: maxSteps,
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return _Outcome(
    gateway: gateway,
    messages: messages,
    logs: logs,
    results: results,
    variables: values,
    error: error,
    native: spy.native,
    frames: frames,
  );
}

Future<_Outcome> _parity(
  List<Action> actions, {
  Map<String, String>? variables,
  Map<String, Map<String, dynamic>> workflows = const {},
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  bool expectNative = true,
}) async {
  Future<_Outcome> run(bool native) => _execute(
    actions.map((a) => Action.fromJson(a.toJson())).toList(),
    native: native,
    variables: variables,
    workflows: workflows,
    throwOnError: throwOnError,
    policy: policy,
  );
  final historical = await run(false);
  final native = await run(true);
  expect(historical.native, 0);
  if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  expect(native.effects, historical.effects, reason: 'effects');
  expect(native.results, historical.results, reason: 'results');
  expect(native.variables, historical.variables, reason: 'variables');
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}

// -- builders ---------------------------------------------------------------

Action _act(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic> payload = const {},
  Map<String, String> error = const {},
  bool enabled = true,
}) =>
    Action(type: type, key: key, enabled: enabled, payload: payload)
      ..error.addAll(error);

/// addRole acting on [user]; fails (empty role) when [bad].
Action _add(
  String key, {
  String user = '1',
  bool bad = false,
  Map<String, String> error = const {},
  Map<String, dynamic>? payload,
}) => _act(
  BotCreatorActionType.addRole,
  key: key,
  error: error,
  payload: {'userId': user, 'roleId': bad ? '' : '64', ...?payload},
);

Action _if(
  String key, {
  Map<String, dynamic>? condition,
  List<Action> then = const [],
  List<Action> otherwise = const [],
  Map<String, String> error = const {},
  Map<String, dynamic>? extra,
}) => _act(
  BotCreatorActionType.ifBlock,
  key: key,
  error: error,
  payload: {
    ...(condition ?? _is('flag', 'yes')),
    'thenActions': then.map((a) => a.toJson()).toList(),
    'elseActions': otherwise.map((a) => a.toJson()).toList(),
    ...?extra,
  },
);

Map<String, String> _is(String variable, String value) => {
  'variable': variable,
  'operator': 'equals',
  'value': value,
};

Action _stop([String? key]) => _act(BotCreatorActionType.stop, key: key);

Action _skip(String key, String count) =>
    _act(BotCreatorActionType.skipActions, key: key, payload: {'count': count});

Action _jump(String key, String target) => _act(
  BotCreatorActionType.jumpToAction,
  key: key,
  payload: {'targetKey': target},
);

Action _simpleLoop(
  String key,
  String iterations,
  List<Action> body, {
  Map<String, String> error = const {},
}) => _act(
  BotCreatorActionType.forLoop,
  key: key,
  error: error,
  payload: {
    'mode': 'simple',
    'iterations': iterations,
    'bodyActions': body.map((a) => a.toJson()).toList(),
  },
);

Action _listLoop(String key, List<String> values, List<Action> body) => _act(
  BotCreatorActionType.forLoop,
  key: key,
  payload: {
    'mode': 'list',
    'varName': 'item',
    'values': values,
    'bodyActions': body.map((a) => a.toJson()).toList(),
  },
);

Action _cLoop(
  String key,
  List<Action> body, {
  String init = 'i=1',
  String condition = 'i<=3',
  String update = 'i++',
}) => _act(
  BotCreatorActionType.forLoop,
  key: key,
  payload: {
    'mode': 'cstyle',
    'init': init,
    'condition': condition,
    'update': update,
    'varNames': ['i'],
    'bodyActions': body.map((a) => a.toJson()).toList(),
  },
);

Action _jsonLoop(
  String key,
  String source,
  List<Action> body, {
  List<String> path = const [],
}) => _act(
  BotCreatorActionType.jsonForEachLoop,
  key: key,
  payload: {
    'source': source,
    'path': path,
    'bodyActions': body.map((a) => a.toJson()).toList(),
  },
);

Action _workflowCall(String key, String name) => _act(
  BotCreatorActionType.runWorkflow,
  key: key,
  payload: {'workflowName': name},
);

Map<String, dynamic> _workflow(List<Action> actions) => {
  'entryPoint': 'main',
  'actions': actions.map((a) => a.toJson()).toList(),
};

void main() {
  final yes = {'flag': 'yes'};

  group('stop / stopUnless', () {
    test('stop ends the execution at the top level', () async {
      final outcome = await _parity([_add('a'), _stop('halt'), _add('b')]);
      expect(outcome.results, {
        'a': '1',
        'halt': 'STOPPED',
        '__stopped__': 'true',
      });
      expect(outcome.changedUsers, ['1']);
    });

    test('stopUnless lets a passing condition through', () async {
      final outcome = await _parity([
        _act(
          BotCreatorActionType.stopUnless,
          key: 'gate',
          payload: _is('flag', 'yes'),
        ),
        _add('a'),
      ], variables: yes);
      expect(outcome.results, {'gate': 'PASSED', 'a': '1'});
    });

    test('stopUnless stops on a failing condition', () async {
      final outcome = await _parity(
        [
          _add('a'),
          _act(
            BotCreatorActionType.stopUnless,
            key: 'gate',
            payload: _is('flag', 'yes'),
          ),
          _add('b'),
        ],
        variables: {'flag': 'no'},
      );
      expect(outcome.results, {
        'a': '1',
        'gate': 'STOPPED',
        '__stopped__': 'true',
      });
    });

    test('stop inside nested blocks marks every list like the historical '
        'code', () async {
      final outcome = await _parity([
        _if(
          'outer',
          then: [
            _add('a'),
            _if('inner', then: [_stop('halt'), _add('never')]),
            _add('never2'),
          ],
        ),
        _add('never3'),
      ], variables: yes);
      expect(outcome.results!['__stopped__'], 'true');
      expect(outcome.results!['outer.inner.__stopped__'], 'true');
      expect(outcome.results!['outer.inner.halt'], 'STOPPED');
      expect(outcome.changedUsers, ['1']);
    });

    test(
      'stopUnless that fails inside a loop ends loop and execution',
      () async {
        final outcome = await _parity([
          _simpleLoop('loop', '5', [
            _add('a', user: '((_loop.count))'),
            _act(
              BotCreatorActionType.stopUnless,
              key: 'gate',
              payload: {
                'variable': '_loop.index',
                'operator': 'notEquals',
                'value': '1',
              },
            ),
          ]),
          _add('after'),
        ]);
        expect(outcome.results!['loop'], 'LOOP_5');
        expect(outcome.results!['loop.iter1.gate'], 'STOPPED');
        expect(outcome.results!['loop.iter1.__stopped__'], 'true');
        expect(outcome.variables.containsKey('_loop.index'), isFalse);
        expect(outcome.changedUsers, ['1', '2']);
      },
    );
  });

  group('skipActions / jumpToAction', () {
    test('skipActions drops the next actions of its list', () async {
      final outcome = await _parity([
        _skip('s', '2'),
        _add('a'),
        _add('b'),
        _add('c'),
      ]);
      expect(outcome.results, {'s': 'SKIPPED_2', 'c': '1'});
    });

    test('a templated or invalid count', () async {
      await _parity(
        [_skip('s', '((n))'), _add('a'), _add('b')],
        variables: {'n': '1'},
      );
      final outcome = await _parity([_skip('s', 'abc'), _add('a')]);
      expect(outcome.results, {'s': 'SKIPPED_0', 'a': '1'});
    });

    test('skipActions inside a branch counts the branch actions', () async {
      final outcome = await _parity([
        _if('g', then: [_skip('s', '1'), _add('a'), _add('b')]),
        _add('after'),
      ], variables: yes);
      expect(outcome.results!.keys.toSet(), {'g', 'g.s', 'g.b', 'after'});
    });

    test('jumpToAction by key, id, position and template', () async {
      for (final target in ['end', 'e1', '4', '((t))']) {
        final outcome = await _parity(
          [
            _jump('j', target),
            _add('skipped1'),
            _add('skipped2'),
            _act(
              BotCreatorActionType.addRole,
              key: 'end',
              payload: {'userId': '1', 'roleId': '64', '_actionId': 'e1'},
            ),
          ],
          variables: {'t': 'end'},
        );
        expect(outcome.results!.keys.toSet(), {'j', 'end'}, reason: target);
        expect(
          outcome.results!['j'],
          'JUMP_TO_${target == '((t))' ? 'end' : target}',
        );
      }
    });

    test('an unknown target does not jump', () async {
      final outcome = await _parity([_jump('j', 'nope'), _add('a')]);
      expect(outcome.results, {'j': 'JUMP_TO_nope', 'a': '1'});
    });

    test('an empty target only leaves the result', () async {
      final outcome = await _parity([_jump('j', ''), _add('a')]);
      expect(outcome.results, {'j': 'JUMP_TO_', 'a': '1'});
    });

    test('jumpToAction inside a branch resolves among its siblings', () async {
      for (final target in ['end', '3', '((t))']) {
        final outcome = await _parity(
          [
            _if('g', then: [_jump('j', target), _add('skipped'), _add('end')]),
            _add('after'),
          ],
          variables: {...yes, 't': 'end'},
        );
        expect(outcome.results!.keys.toSet(), {'g', 'g.j', 'g.end', 'after'});
      }
    });

    test('a backward target stays a no-op at the top level', () async {
      final outcome = await _parity([
        _act(BotCreatorActionType.log, key: 'first', payload: {'message': 'x'}),
        _jump('j', 'first'),
        _add('after'),
      ]);
      expect(outcome.results!['after'], '1');
    });
  });

  group('wait / log', () {
    test('wait pauses and reports', () async {
      final watch = Stopwatch()..start();
      final outcome = await _parity([
        _act(
          BotCreatorActionType.wait,
          key: 'w',
          payload: {'duration': '30ms'},
        ),
        _add('a'),
      ]);
      expect(outcome.results, {'w': 'WAITED', 'a': '1'});
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(60));
    });

    test('an invalid duration fails the same way', () async {
      final outcome = await _parity([
        _act(
          BotCreatorActionType.wait,
          key: 'w',
          payload: {'duration': 'soon'},
        ),
      ]);
      expect(outcome.errorText, contains('Invalid wait duration: soon'));
    });

    test('log writes the resolved message', () async {
      final outcome = await _parity(
        [
          _act(
            BotCreatorActionType.log,
            key: 'l',
            payload: {'message': 'hello ((who))'},
          ),
          _act(
            BotCreatorActionType.log,
            key: 'empty',
            payload: {'message': ''},
          ),
        ],
        variables: {'who': 'world'},
      );
      expect(outcome.logs, ['hello world']);
      expect(outcome.results, {'l': 'LOGGED', 'empty': 'LOGGED'});
    });
  });

  group('runBdfdScript / runWorkflow', () {
    Action script(String source, {String key = 's'}) => _act(
      BotCreatorActionType.runBdfdScript,
      key: key,
      payload: {'scriptContent': source, 'bdfdBackend': 'native-v1'},
    );

    test('runs a script and prefixes its results', () async {
      final outcome = await _parity([script(r'$sendMessage[one]'), _add('a')]);
      expect(outcome.messages.sent, ['one']);
      expect(outcome.results!['s'], 'BDFD_OK');
    });

    test('an empty script', () async {
      final outcome = await _parity([script('  ')]);
      expect(outcome.results, {'s': 'BDFD_EMPTY'});
    });

    test('a script that stops ends the execution', () async {
      final outcome = await _parity([
        script(r'$sendMessage[one]$stop'),
        _add('never'),
      ]);
      expect(outcome.results!['__stopped__'], 'true');
      expect(outcome.changedUsers, isEmpty);
    });

    test('a script error fails the action', () async {
      final outcome = await _parity([script(r'$sendMessage[a;b;c;d;e;f]')]);
      expect(outcome.error, isNotNull);
    });

    test('two scripts do not share user functions', () async {
      final outcome = await _parity([
        script(r'$func[hi]$sendMessage[from-func]$funcEnd', key: 'one'),
        script(r'$hi', key: 'two'),
      ]);
      expect(outcome.messages.sent, isNotEmpty);
    });

    test('scripts inside a block', () async {
      final outcome = await _parity([
        _if('g', then: [script(r'$sendMessage[nested]'), _add('a')]),
      ], variables: yes);
      expect(outcome.messages.sent, ['nested']);
      expect(outcome.results!['g.s'], 'BDFD_OK');
    });

    final workflows = {
      'greet': _workflow([_add('w1', user: '7'), _add('w2', user: '8')]),
      'halts': _workflow([_add('w1', user: '7'), _stop('h'), _add('w2')]),
      'broken': _workflow([_add('w1', bad: true)]),
    };

    test(
      'runWorkflow keeps the results and workflow.response contract',
      () async {
        final outcome = await _parity([
          _workflowCall('call', 'greet'),
          _add('a'),
        ], workflows: workflows);
        expect(outcome.results!['call'], 'WORKFLOW_OK:main');
        expect(outcome.results!['call.w1'], '7');
        expect(outcome.variables['workflow.response'], 'WORKFLOW_OK:main');
        expect(outcome.variables['workflow.response.w2'], '8');
        expect(outcome.changedUsers, ['7', '8', '1']);
      },
    );

    test('a stop inside the workflow stops the caller', () async {
      final outcome = await _parity([
        _workflowCall('call', 'halts'),
        _add('never'),
      ], workflows: workflows);
      expect(outcome.results!['__stopped__'], 'true');
      expect(outcome.changedUsers, ['7']);
    });

    test('unknown workflows and failures', () async {
      final unknown = await _parity([
        _workflowCall('call', 'missing'),
      ], workflows: workflows);
      expect(unknown.errorText, contains('Workflow not found: missing'));
      await _parity([_workflowCall('call', 'broken')], workflows: workflows);
    });

    test('runWorkflow inside a loop', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '2', [_workflowCall('call', 'greet')]),
      ], workflows: workflows);
      expect(outcome.results!['loop.iter1.call'], 'WORKFLOW_OK:main');
    });
  });

  group('ifBlock tryCatch', () {
    Action tryBlock(
      String key,
      List<Action> body,
      List<Action> onError, {
      Map<String, String> error = const {},
    }) => _if(
      key,
      then: body,
      otherwise: onError,
      error: error,
      extra: {'tryCatch': true},
    );

    test('a body that succeeds', () async {
      final outcome = await _parity([
        tryBlock('t', [_add('a')], [_add('never')]),
        _add('after'),
      ]);
      expect(outcome.results, {'t': 'TRY_OK', 't.a': '1', 'after': '1'});
    });

    test('a failing body runs the catch list and drops body results', () async {
      final outcome = await _parity([
        tryBlock(
          't',
          [_add('ok'), _add('bad', bad: true), _add('never')],
          [_add('rescue', user: '9')],
        ),
        _add('after'),
      ]);
      expect(outcome.results, {
        't': 'TRY_CAUGHT',
        't.rescue': '9',
        'after': '1',
      });
      expect(
        outcome.variables.keys.where((k) => k.startsWith('error.')),
        isEmpty,
      );
    });

    test('the catch list sees the error variables', () async {
      final outcome = await _parity([
        tryBlock(
          't',
          [_add('bad', bad: true)],
          [
            _act(
              BotCreatorActionType.log,
              key: 'l',
              payload: {'message': '((error.command)): ((error.message))'},
            ),
          ],
        ),
      ]);
      expect(outcome.logs.single, startsWith('addRole: Exception: '));
    });

    test('outer error variables are restored', () async {
      final outcome = await _parity([
        _add('bad', bad: true, error: {'mode': 'continue'}),
        tryBlock('t', [_add('bad2', bad: true)], []),
      ]);
      expect(outcome.variables['error.command'], 'addRole');
      expect(outcome.results!['t'], 'TRY_CAUGHT');
    });

    test('children ignore their own error modes inside a try', () async {
      final outcome = await _parity([
        tryBlock(
          't',
          [
            _add('bad', bad: true, error: {'mode': 'continue'}),
            _add('never'),
          ],
          [_add('rescue')],
        ),
      ]);
      expect(outcome.results!['t'], 'TRY_CAUGHT');
      expect(outcome.results!.containsKey('t.never'), isFalse);
    });

    test('a failing catch list fails the block', () async {
      final outcome = await _parity([
        tryBlock('t', [_add('bad', bad: true)], [_add('bad2', bad: true)]),
        _add('never'),
      ]);
      expect(outcome.error, isNotNull);
    });

    test('skip and stop inside a try body', () async {
      final outcome = await _parity([
        tryBlock('t', [_skip('s', '1'), _add('skipped'), _add('kept')], []),
        tryBlock('u', [_stop('halt')], []),
        _add('never'),
      ]);
      expect(outcome.results!['t.kept'], '1');
      expect(outcome.results!['__stopped__'], 'true');
    });

    test('a try inside a loop restarts cleanly each iteration', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '3', [
          tryBlock(
            't',
            [_add('bad', bad: true)],
            [_add('r', user: '((_loop.count))')],
          ),
        ]),
      ]);
      expect(outcome.changedUsers, ['1', '2', '3']);
    });

    test('the block error mode applies to a failing catch list', () async {
      final outcome = await _parity([
        tryBlock(
          't',
          [_add('bad', bad: true)],
          [_add('bad2', bad: true)],
          error: {'mode': 'continue'},
        ),
        _add('after'),
      ]);
      expect(outcome.error, isNull);
      expect(outcome.results!['t'], startsWith('Error: '));
    });
  });

  group('ifBlock suppressErrors', () {
    Action suppressing(String key, List<Action> body, {String? message}) => _if(
      key,
      then: body,
      extra: {'suppressErrors': true, 'suppressErrorsMessage': ?message},
    );

    test('a failing branch is swallowed', () async {
      final outcome = await _parity([
        suppressing('s', [_add('ok'), _add('bad', bad: true), _add('never')]),
        _add('after'),
      ], variables: yes);
      expect(outcome.results, {'s': 'IF_TRUE', 'after': '1'});
      expect(
        outcome.variables.keys.where((k) => k.startsWith('error.')),
        isEmpty,
      );
    });

    test('a branch that works publishes its results', () async {
      final outcome = await _parity([
        suppressing('s', [_add('ok')]),
      ], variables: yes);
      expect(outcome.results, {'s': 'IF_TRUE', 's.ok': '1'});
    });

    test('the error response goes through respondWithMessage', () async {
      await _parity([
        suppressing('s', [_add('bad', bad: true)], message: 'oops'),
        _add('after'),
      ], variables: yes);
    });

    test('an empty branch has nothing to suppress', () async {
      final outcome = await _parity([suppressing('s', [])], variables: yes);
      expect(outcome.results, {'s': 'IF_TRUE'});
    });

    test('nested children ignore their error modes', () async {
      final outcome = await _parity([
        suppressing('s', [
          _add('bad', bad: true, error: {'mode': 'continue'}),
          _add('never'),
        ]),
        _add('after'),
      ], variables: yes);
      expect(outcome.results, {'s': 'IF_TRUE', 'after': '1'});
    });
  });

  group('error modes on blocks', () {
    Action failingBlock(Map<String, String> error) =>
        _if('g', error: error, then: [_add('ok'), _add('bad', bad: true)]);

    test('skip drops the actions after the block', () async {
      final outcome = await _parity([
        failingBlock({'mode': 'skip', 'skipCount': '1'}),
        _add('skipped'),
        _add('kept'),
      ], variables: yes);
      expect(outcome.results!.keys.toSet(), {'g', 'kept'});
      expect(outcome.results!['g'], startsWith('Error: '));
    });

    test('jump continues at the named later action', () async {
      final outcome = await _parity([
        failingBlock({'mode': 'jump', 'jumpToActionId': 'end'}),
        _add('skipped'),
        _add('end'),
      ], variables: yes);
      expect(outcome.results!.keys.toSet(), {'g', 'end'});
    });

    test('a backward or unknown jump fails like stop', () async {
      final outcome = await _parity([
        _add('first'),
        failingBlock({'mode': 'jump', 'jumpToActionId': 'first'}),
      ], variables: yes);
      expect(outcome.error, isNotNull);
    });

    test('skip on a block nested in a branch', () async {
      final outcome = await _parity([
        _if(
          'outer',
          then: [
            _if(
              'inner',
              error: {'mode': 'skip', 'skipCount': '1'},
              then: [_add('bad', bad: true)],
            ),
            _add('skipped'),
            _add('kept'),
          ],
        ),
      ], variables: yes);
      expect(outcome.results!.keys.toSet(), {
        'outer',
        'outer.inner',
        'outer.kept',
      });
    });

    test(
      'a loop failing under skip mode keeps its finished iterations',
      () async {
        final outcome = await _parity(
          [
            _simpleLoop(
              'loop',
              '3',
              [
                _add('a', user: '((_loop.count))'),
                _add('b', bad: true, payload: {'roleId': '((fail))'}),
              ],
              error: {'mode': 'skip', 'skipCount': '1'},
            ),
            _add('skipped'),
            _add('kept'),
          ],
          variables: {'fail': ''},
        );
        expect(outcome.results!['loop'], startsWith('Error: '));
        expect(outcome.results!.containsKey('skipped'), isFalse);
      },
    );
  });

  group('forLoop simple', () {
    test('runs the body and publishes iteration results', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '3', [
          _add('a', user: '((_loop.count))'),
          _add('b', user: '((a))'),
        ]),
      ]);
      expect(outcome.results!['loop'], 'LOOP_3');
      expect(outcome.results!['loop.iter2.a'], '3');
      expect(outcome.results!['loop.iter0.b'], '1');
      expect(outcome.variables.containsKey('_loop.index'), isFalse);
      expect(outcome.variables.containsKey('_loop.count'), isFalse);
    });

    test('zero, negative, invalid and templated counts', () async {
      for (final count in ['0', '-2', 'many', '', '((n))']) {
        final outcome = await _parity(
          [
            _simpleLoop('loop', count, [_add('a')]),
          ],
          variables: {'n': '2'},
        );
        expect(
          outcome.results!['loop'],
          count == '((n))' ? 'LOOP_2' : 'LOOP_0',
        );
      }
    });

    test('an empty body', () async {
      final outcome = await _parity([_simpleLoop('loop', '4', [])]);
      expect(outcome.results, {'loop': 'LOOP_0'});
    });

    test('disabled body actions keep their ordinal', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '2', [
          _skip('s', '1'),
          _act(BotCreatorActionType.addRole, key: 'off', enabled: false),
          _add('kept'),
        ]),
      ]);
      expect(outcome.results!.keys.toSet(), {
        'loop',
        'loop.iter0.s',
        'loop.iter0.kept',
        'loop.iter1.s',
        'loop.iter1.kept',
      });
    });

    test('body actions read only the results of their own iteration', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '2', [
          _add('a', user: '((_loop.count))'),
          _add('b', user: '((a))'),
        ]),
      ]);
      expect(outcome.changedUsers, ['1', '1', '2', '2']);
    });

    test('nested loops publish with the full path', () async {
      final outcome = await _parity([
        _simpleLoop('outer', '2', [
          _simpleLoop('inner', '2', [_add('leaf', user: '((_loop.count))')]),
        ]),
      ]);
      expect(outcome.results!['outer.iter1.inner'], 'LOOP_2');
      expect(outcome.results!['outer.iter1.inner.iter1.leaf'], '2');
      expect(outcome.results!.length, 1 + 2 * (1 + 2));
    });

    test('a failing body action stops the loop', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '3', [_add('a'), _add('bad', bad: true)]),
      ]);
      expect(outcome.error, isNotNull);
      expect(outcome.variables['error.command'], 'forLoop');
    });

    test('continue mode on the body action keeps looping', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '2', [
          _add('bad', bad: true, error: {'mode': 'continue'}),
          _add('good'),
        ]),
      ]);
      expect(outcome.results!['loop.iter1.good'], '1');
      expect(outcome.results!['loop.iter0.bad'], startsWith('Error: '));
    });

    test('a loop inside a branch', () async {
      final outcome = await _parity([
        _if(
          'g',
          then: [
            _simpleLoop('loop', '2', [_add('a', user: '((_loop.count))')]),
          ],
        ),
      ], variables: yes);
      expect(outcome.results!['g.loop.iter1.a'], '2');
    });
  });

  group('forLoop list and cstyle', () {
    test('list loop binds the item', () async {
      final outcome = await _parity(
        [
          _listLoop(
            'loop',
            ['5', '((n))', '7'],
            [_add('a', user: '((_loop.var.item))')],
          ),
        ],
        variables: {'n': '6'},
      );
      expect(outcome.changedUsers, ['5', '6', '7']);
      expect(outcome.results!['loop'], 'LOOP_3');
      expect(outcome.variables.containsKey('_loop.var.item'), isFalse);
    });

    test('an empty list', () async {
      final outcome = await _parity([
        _listLoop('loop', [], [_add('a')]),
      ]);
      expect(outcome.results, {'loop': 'LOOP_0'});
    });

    test('cstyle loop counts with its variable', () async {
      final outcome = await _parity([
        _cLoop('loop', [_add('a', user: '((_loop.var.i))')]),
      ]);
      expect(outcome.changedUsers, ['1', '2', '3']);
      expect(outcome.results!['loop'], 'LOOP_3');
      expect(outcome.variables.containsKey('_loop.var.i'), isFalse);
    });

    test('cstyle with compound update and templated bounds', () async {
      final outcome = await _parity(
        [
          _cLoop(
            'loop',
            [_add('a', user: '((_loop.var.i))')],
            init: 'i=((start))',
            condition: 'i<((end))',
            update: 'i += 2',
          ),
        ],
        variables: {'start': '2', 'end': '9'},
      );
      expect(outcome.changedUsers, ['2', '4', '6', '8']);
    });

    test('cstyle with a false first condition and an invalid update', () async {
      final none = await _parity([
        _cLoop('loop', [_add('a')], condition: 'i>5'),
      ]);
      expect(none.results, {'loop': 'LOOP_0'});
      final bad = await _parity([
        _cLoop('loop', [_add('a')], update: 'i ?? 2'),
      ]);
      expect(bad.errorText, contains('Invalid loop update'));
    });

    test(
      'stop inside a cstyle loop does not count the stopped iteration',
      () async {
        final outcome = await _parity([
          _cLoop('loop', [
            _add('a', user: '((_loop.var.i))'),
            _if('g', condition: _is('_loop.var.i', '2'), then: [_stop('halt')]),
          ]),
        ]);
        expect(outcome.results!['loop'], 'LOOP_1');
        expect(outcome.results!['loop.iter1.g.halt'], 'STOPPED');
      },
    );

    test('stop inside a simple loop keeps the full count', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '4', [_stop('halt')]),
      ]);
      expect(outcome.results!['loop'], 'LOOP_4');
    });
  });

  group('jsonForEachLoop', () {
    const source = '{"a":"x","b":"y"}';
    test('iterates the payload source', () async {
      final outcome = await _parity([
        _jsonLoop('each', source, [_add('u', user: '((_loop.count))')]),
      ]);
      expect(outcome.changedUsers, ['1', '2']);
      expect(outcome.results!['each'], 'JSONFE_2');
      expect(
        outcome.variables.keys.where((k) => k.startsWith('_loop.')),
        isEmpty,
      );
    });

    test('binds the key, value and index', () async {
      final outcome = await _parity([
        _jsonLoop('each', '[10,20]', [
          _add('u', user: '((_loop.var.jsonvalue))'),
          _act(
            BotCreatorActionType.log,
            key: 'l',
            payload: {
              'message': '((_loop.var.jsonkey))/((_loop.var.jsonindex))',
            },
          ),
        ]),
      ]);
      expect(outcome.logs, ['0/0', '1/1']);
    });

    test('follows a path and handles a missing one', () async {
      final nested = await _parity([
        _jsonLoop('each', '{"list":[1,2,3]}', [_add('u')], path: ['list']),
      ]);
      expect(nested.results!['each'], 'JSONFE_3');
      final missing = await _parity([
        _jsonLoop('each', source, [_add('u')], path: ['nope']),
      ]);
      expect(missing.results, {'each': 'JSONFE_0'});
    });

    test('an empty body and a bad source', () async {
      final empty = await _parity([_jsonLoop('each', source, [])]);
      expect(empty.results, {'each': 'JSONFE_0'});
      final bad = await _parity([
        _jsonLoop('each', 'not json', [_add('u')]),
      ]);
      expect(bad.results, {'each': 'JSONFE_0'});
    });

    test('reads the latest JSON result of its list', () async {
      final outcome = await _parity([
        _act(
          BotCreatorActionType.addRole,
          key: 'rtjson_1',
          payload: {'userId': '5', 'roleId': '64'},
        ),
        _jsonLoop('each', '[1]', [_add('u')]),
      ]);
      expect(outcome.results!['each'], 'JSONFE_1');
    });
  });

  group('routing', () {
    test('a policy keeps blocks historical but runs leaves natively', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '2', [_add('a', user: '((_loop.count))')]),
        _stop('halt'),
      ], policy: _NoPolicy());
      expect(outcome.native, greaterThan(0));
      expect(outcome.results!['loop'], 'LOOP_2');
    });

    test('a block with an unsupported child stays historical', () async {
      final outcome = await _parity([
        _simpleLoop('loop', '1', [
          _act(
            BotCreatorActionType.respondWithMessage,
            key: 'r',
            payload: {'content': 'x'},
          ),
        ]),
      ], expectNative: false);
      expect(outcome.native, 0);
    });

    test('protected executions ignore error modes (throwOnError)', () async {
      await _parity([
        _simpleLoop('loop', '2', [
          _add('bad', bad: true, error: {'mode': 'continue'}),
        ]),
      ], throwOnError: true);
    });
  });

  group('limits and diagnostics (native only)', () {
    test('the step limit stops a runaway C-style loop', () async {
      final outcome = await _execute(
        [
          _cLoop('loop', [
            _act(BotCreatorActionType.log, key: 'l', payload: {'message': 'x'}),
          ], condition: 'i>=0'),
        ],
        native: true,
        maxSteps: 500,
      );
      expect(outcome.errorText, contains('Execution step limit exceeded'));
    });

    test('the limit does not touch a loop within it', () async {
      final outcome = await _execute(
        [
          _simpleLoop('loop', '20', [_add('a')]),
        ],
        native: true,
        maxSteps: 1000,
      );
      expect(outcome.error, isNull);
      expect(outcome.results!['loop'], 'LOOP_20');
    });

    test('execution.time is refreshed for native children', () async {
      final outcome = await _execute(
        [
          _if(
            'g',
            then: [
              _act(
                BotCreatorActionType.wait,
                key: 'w',
                payload: {'duration': '40ms'},
              ),
              _act(
                BotCreatorActionType.log,
                key: 'l',
                payload: {'message': '((execution.time))'},
              ),
            ],
          ),
        ],
        native: true,
        variables: yes,
      );
      final ms = int.parse(outcome.logs.single.replaceAll('ms', ''));
      expect(ms, greaterThanOrEqualTo(35));
    });

    test(
      'replay frames of nested native actions carry key and snapshots',
      () async {
        final outcome = await _execute(
          [
            _if('g', then: [_add('a', user: '3')]),
          ],
          native: true,
          variables: yes,
        );
        final frames = outcome.frames
            .where(
              (f) => f['actionKey'] == 'a' && f['nativeStatus'] == 'returned',
            )
            .toList();
        expect(frames, hasLength(1));
        expect(frames.single['visualActionType'], 'addRole');
        expect(frames.single['actionType'], 'bc_addRole');
        expect(frames.single['variablesBefore'], isA<Map>());
        expect(frames.single['variablesAfter'], isA<Map>());
        // The loop's own per-action frame is the only one of the routed action.
        expect(
          outcome.frames.where((f) => f['actionType'] == 'ifBlock'),
          isNotEmpty,
        );
      },
    );
  });
}

class _NoPolicy implements ActionExecutionPolicy {
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
