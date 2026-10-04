import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_results.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_runner.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_ast.dart';
import 'package:bot_creator_shared/utils/bdfd_functions.dart';
import 'package:test/test.dart';

class _Moderation implements BotModerationService {
  final requests = <BotModerationRequest>[];
  Duration delay = Duration.zero;
  @override
  Future<String> moderate(
    BotModerationRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    requests.add(request);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    budget.check();
    if (request.userId == 'bad' || request.userId.isEmpty) {
      throw StateError('Missing or invalid userId/roleId');
    }
    return request.userId;
  }
}

class _Setup {
  _Setup({
    Map<String, String>? variables,
    Map<String, String>? results,
    this.throwOnError = false,
    CommandExecutionBudget? budget,
  }) : variables = variables ?? {},
       results = results ?? {},
       moderation = _Moderation() {
    sink = ResultSink(results: this.results, variables: this.variables);
    env = ActionRunEnvironment(
      variables: this.variables,
      sink: sink,
      resolveTemplate: (value) => value.replaceAllMapped(
        RegExp(r'\(\(([^)]+)\)\)'),
        (m) => this.variables[m.group(1)] ?? '',
      ),
      budget: budget ?? CommandExecutionBudget(),
      moderation: moderation,
      guildId: '10',
      throwOnError: throwOnError,
    );
    context = BdfdContext(variables: this.variables, budget: env.budget);
  }
  final Map<String, String> variables;
  final Map<String, String> results;
  final bool throwOnError;
  final _Moderation moderation;
  late final ResultSink sink;
  late final ActionRunEnvironment env;
  late final BdfdContext context;
  final runner = const BdfdActionRunner();
}

BdfdFunctionCallAst _call(String name, List<String> args) =>
    BdfdFunctionCallAst(
      name: name,
      arguments: [
        for (final arg in args) [BdfdTextAst(arg, start: 0, end: 1)],
      ],
      start: 0,
      end: 1,
    );

Future<String> _eval(_Setup setup, BdfdStatement statement) async {
  final runtime = BdfdRuntime(functions: bdfdVisualFunctions(setup.env));
  return runtime.executeProgram(
    BdfdProgram.fromStatements('synthetic', [statement]),
    context: setup.context,
  );
}

Action _role(
  String key, {
  String user = '1',
  Map<String, String> error = const {},
  bool enabled = true,
}) => Action(
  type: BotCreatorActionType.addRole,
  key: key,
  enabled: enabled,
  payload: {'userId': user, 'roleId': '2'},
)..error.addAll(error);

void main() {
  group('hidden functions', () {
    test('are outside the catalogue and the production registry', () {
      final names = bdfdVisualFunctionNames();
      expect(
        names,
        containsAll(['bc_tpl', 'bc_cond', 'bc_addrole', 'bc_removerole']),
      );
      expect(names.intersection(allBdfdFunctions), isEmpty);
      final registered = BdfdEngine.validation().supportedFunctions;
      expect(registered.intersection(names), isEmpty);
      // The audit invariant: every catalogue function stays registered.
      expect(allBdfdFunctions.difference(registered), isEmpty);
    });

    test('a BDFD script cannot call them: they stay opaque literals', () async {
      final engine = BdfdEngine.validation();
      final program = engine.prepare(r'$bc_tpl[x]$bc_addRole[a;b;c]');
      expect(program.statements, hasLength(2));
      final bound = BdfdRuntime(
        functions: bdfdVisualFunctions(_Setup().env),
      ).supportedFunctions;
      expect(bound, containsAll(bdfdVisualFunctionNames()));
      expect(engine.supportedFunctions, isNot(contains('bc_tpl')));
    });

    test('cannot shadow the core language', () {
      expect(
        () => BdfdRuntime(
          functions: bdfdVisualFunctions(_Setup().env, handlers: {}),
        ),
        returnsNormally,
      );
    });
  });

  group('bc_tpl', () {
    test('result placeholders win, then the template resolver', () async {
      final setup = _Setup(
        variables: {'name': 'Ada', 'first': 'from variables'},
        results: {'first': 'from results', 'a.b': 'nested'},
      );
      expect(
        await _eval(
          setup,
          BdfdExpression(
            _call('bc_tpl', [
              '((first)) ((action.first)) ((a.b)) ((name)) ((unknown))',
            ]),
          ),
        ),
        'from results from results nested Ada ',
      );
    });

    test('reads the results of the list at the given path', () async {
      final setup = _Setup(results: {'k': 'root'});
      setup.sink.set(['block'], 'k', 'inner');
      Future<String> run(String path) =>
          _eval(setup, BdfdExpression(_call('bc_tpl', ['((k))', path])));
      expect(await run('["block"]'), 'inner');
      // Reading the root list publishes the finished nested ones.
      expect(await run('[]'), 'root');
      expect(setup.results['block.k'], 'inner');
    });

    test('keeps unresolved result lookups for the template resolver', () {
      expect(
        resolveActionValue('((action.nope))', {}, (v) => 'T($v)'),
        'T(((action.nope)))',
      );
    });
  });

  group('bc_cond', () {
    Future<String> cond(
      _Setup setup,
      String json, {
      int index = 0,
      String key = 'gate',
    }) => _eval(
      setup,
      BdfdExpression(_call('bc_cond', [key, '$index', json, '[]'])),
    );

    test('evaluates the visual operators and labels the block', () async {
      final setup = _Setup(variables: {'a': 'hello world', 'n': '5'});
      expect(
        await cond(
          setup,
          '{"variable":"a","operator":"contains","value":"world"}',
        ),
        'true',
      );
      expect(setup.results['gate'], 'IF_TRUE');
      expect(
        await cond(setup, '{"variable":"a","operator":"equals","value":"x"}'),
        'false',
      );
      expect(setup.results['gate'], 'IF_FALSE');
      expect(
        await cond(
          setup,
          '{"variable":"n","operator":"greaterThan","value":"3"}',
        ),
        'true',
      );
      // Unknown operators are false, as in the historical executor.
      expect(
        await cond(setup, '{"variable":"n","operator":"bogus","value":"3"}'),
        'false',
      );
      // else-if branches only label the block when they match.
      expect(
        await cond(
          setup,
          '{"variable":"a","operator":"matches","value":"^hello"}',
          index: 2,
        ),
        'true',
      );
      expect(setup.results['gate'], 'ELSE_IF_2');
      expect(
        await cond(setup, '{"variable":"a","value":"nope"}', index: 3),
        'false',
      );
      expect(setup.results['gate'], 'ELSE_IF_2');
      expect(
        await cond(
          setup,
          '{"group":"and","negate":true,"conditions":['
          '{"variable":"n","value":"5"},'
          '{"variable":"a","operator":"isNotEmpty"}]}',
        ),
        'false',
      );
    });

    test(
      'resolves placeholders against the results of the block list',
      () async {
        final setup = _Setup(variables: {'v': 'x'}, results: {'prev': 'x'});
        expect(
          await cond(setup, '{"variable":"((prev))","value":"((v))"}'),
          'true',
        );
      },
    );

    test('invalid conditions fail as native errors', () async {
      await expectLater(
        cond(_Setup(), '{not json'),
        throwsA(isA<BdfdNativeError>()),
      );
    });
  });

  group('error mapping', () {
    BdfdStatement action(String user, {String options = '{"path":[]}'}) =>
        BdfdExpression(
          _call('bc_addRole', [
            'k',
            '{"userId":"$user","roleId":"2"}',
            options,
          ]),
        );

    test(
      'failures reach the runtime as BdfdNativeError with the cause',
      () async {
        final setup = _Setup();
        await expectLater(
          _eval(setup, action('bad')),
          throwsA(
            isA<BdfdNativeError>()
                .having((e) => e.cause, 'cause', isA<Exception>())
                .having(
                  (e) => e.message,
                  'message',
                  contains('Missing or invalid'),
                ),
          ),
        );
        expect(setup.results['k'], startsWith('Error: Exception: '));
        expect(setup.variables['error.command'], 'addRole');
      },
    );

    test('a try/catch statement sees the failure', () async {
      final setup = _Setup();
      final runtime = BdfdRuntime(functions: bdfdVisualFunctions(setup.env));
      await runtime.executeProgram(
        BdfdProgram.fromStatements('s', [
          BdfdTry(
            _call('try', []),
            [action('bad')],
            [
              BdfdExpression(_call('c', ['caught'])),
            ],
          ),
          action('7'),
        ]),
        context: setup.context,
      );
      expect(
        setup.context.results['error.message'],
        contains('Missing or invalid'),
      );
      expect(setup.results['k'], '7');
    });

    test('a timeout is never caught by a try statement', () async {
      final setup = _Setup(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 20)),
      );
      setup.moderation.delay = const Duration(milliseconds: 100);
      final runtime = BdfdRuntime(functions: bdfdVisualFunctions(setup.env));
      await expectLater(
        runtime.executeProgram(
          BdfdProgram.fromStatements('s', [
            BdfdTry(_call('try', []), [action('7')], []),
          ]),
          context: setup.context,
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
    });

    test('protected executions rethrow whatever the mode says', () async {
      final setup = _Setup(throwOnError: true);
      await expectLater(
        _eval(setup, action('bad', options: '{"path":[],"mode":"continue"}')),
        throwsA(isA<BdfdNativeError>()),
      );
    });

    test('continue, skip and jump are applied by the failing action', () async {
      final setup = _Setup();
      final runtime = BdfdRuntime(functions: bdfdVisualFunctions(setup.env));
      await runtime.executeProgram(
        BdfdProgram.fromStatements('s', [
          action('bad', options: '{"path":[],"mode":"continue"}'),
          BdfdExpression(
            _call('bc_addRole', [
              'skipper',
              '{"userId":"bad","roleId":"2"}',
              '{"path":[],"mode":"skip","count":1}',
            ]),
          ),
          BdfdExpression(
            _call('bc_addRole', [
              'dropped',
              '{"userId":"1","roleId":"2"}',
              '{"path":[]}',
            ]),
          ),
          BdfdExpression(
            _call('bc_addRole', [
              'jumper',
              '{"userId":"bad","roleId":"2"}',
              '{"path":[],"mode":"jump","ordinal":6}',
            ]),
          ),
          BdfdExpression(
            _call('bc_addRole', [
              'dropped2',
              '{"userId":"1","roleId":"2"}',
              '{"path":[]}',
            ]),
          ),
          BdfdExpression(
            _call('bc_addRole', [
              'end',
              '{"userId":"9","roleId":"2"}',
              '{"path":[]}',
            ]),
          ),
        ]),
        context: setup.context,
      );
      expect(setup.results.keys, ['k', 'skipper', 'jumper', 'end']);
    });
  });

  group('BdfdActionRunner.run', () {
    test(
      'runs a whole list with results, error modes and nested blocks',
      () async {
        final setup = _Setup(variables: {'flag': 'yes'});
        final results = await setup.runner.run(
          [
            _role('a', user: '5'),
            Action(
              type: BotCreatorActionType.ifBlock,
              key: 'gate',
              payload: {
                'variable': 'flag',
                'operator': 'equals',
                'value': 'yes',
                'thenActions': [
                  _role('inner', user: '6').toJson(),
                  _role('off', enabled: false).toJson(),
                ],
              },
            ),
            _role('bad', user: 'bad', error: {'mode': 'continue'}),
            _role('last', user: '8'),
          ],
          env: setup.env,
          context: setup.context,
        );
        expect(results, {
          'a': '5',
          'gate': 'IF_TRUE',
          'gate.inner': '6',
          'bad': startsWith('Error: Exception: '),
          'last': '8',
        });
        expect(setup.moderation.requests.map((r) => r.userId), [
          '5',
          '6',
          '', // 'bad' is no id: the historical payload parsing yields ''
          '8',
        ]);
      },
    );

    test(
      'a failure ends up on the top-level action and is rethrown unwrapped',
      () async {
        final setup = _Setup(variables: {'flag': 'yes'});
        Object? thrown;
        try {
          await setup.runner.run(
            [
              Action(
                type: BotCreatorActionType.ifBlock,
                key: 'gate',
                payload: {
                  'variable': 'flag',
                  'value': 'yes',
                  'thenActions': [_role('inner', user: 'bad').toJson()],
                },
              ),
            ],
            env: setup.env,
            context: setup.context,
          );
        } catch (error) {
          thrown = error;
        }
        expect(thrown, isA<Exception>());
        expect(thrown, isNot(isA<BdfdNativeError>()));
        expect(setup.results['gate'], 'Error: $thrown');
        expect(setup.variables['error.command'], 'ifBlock');
      },
    );

    test(
      'acknowledges first, unless the list defers or opens a modal',
      () async {
        final calls = <bool>[];
        Future<void> ack({required bool ephemeral}) async =>
            calls.add(ephemeral);
        await _Setup().runner.run(
          [_role('a')],
          env: _Setup().env,
          context: _Setup().context,
          acknowledge: ack,
        );
        expect(calls, [false]);
        final setup = _Setup();
        await setup.runner.run(
          [
            _role('a'),
            Action(
              type: BotCreatorActionType.deferInteraction,
              enabled: false,
              payload: {},
            ),
          ],
          env: setup.env,
          context: setup.context,
          acknowledge: ack,
        );
        expect(calls, [false]);
      },
    );

    test('keeps the host script state out of the visual program', () async {
      final setup = _Setup();
      var flushed = 0;
      setup.context.beforeFlush.add(() async => flushed++);
      final events = <String>[];
      setup.context.onTrace = (event) => events.add(event.kind);
      await setup.runner.runAction(
        _role('a'),
        env: setup.env,
        context: setup.context,
        index: 0,
      );
      expect(flushed, 0);
      expect(setup.context.beforeFlush, hasLength(1));
      expect(events, isEmpty);
      expect(setup.context.onTrace, isNotNull);
      expect(setup.results, {'a': '1'});
    });
  });

  group('ResultSink', () {
    test('publishes nested lists on commit and forgets aborted ones', () {
      final sink = ResultSink(results: {}, variables: {});
      sink.set(['a'], 'x', '1');
      sink.set(['a', 'b'], 'y', '2');
      sink.set([], 'a', 'IF_TRUE');
      expect(sink.results, {'a': 'IF_TRUE', 'a.x': '1', 'a.b.y': '2'});
      sink.set(['c'], 'z', '3');
      sink.discard(['c']);
      expect(sink.scope(const []), {'a': 'IF_TRUE', 'a.x': '1', 'a.b.y': '2'});
    });

    test('mirrors fields into variables and records errors', () {
      final sink = ResultSink(results: {}, variables: {});
      sink.field(const [], 'req', 'status', '200', actionPrefix: true);
      expect(sink.results['req.status'], '200');
      expect(sink.variables['req.status'], '200');
      expect(sink.variables['action.req.status'], '200');
      sink.recordError('httpRequest', 'req', const [], 'boom');
      expect(sink.results['req'], 'Error: boom');
      expect(sink.variables['error.message'], 'boom');
      expect(sink.variables['error.command'], 'httpRequest');
      expect(sink.variables['error.row'], '');
      sink.set(const [], 'n', '42');
      sink.noteNumeric(const [], 'n');
      expect(sink.variables['lastSentMessageId'], '42');
      sink.set(const [], 'e', 'Error: 42');
      sink.noteNumeric(const [], 'e');
      expect(sink.variables['lastSentMessageId'], '42');
    });
  });
}
