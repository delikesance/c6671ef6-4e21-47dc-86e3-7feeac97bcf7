import 'dart:async';

import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/control_flow_state.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_ast.dart';
import 'package:test/test.dart';

/// The small, additive runtime hooks the visual blocks rely on (try lifecycle
/// calls, requests applied by the enclosing list, the step limit) and the shape
/// of the translated blocks.

BdfdFunctionCallAst _call(String name, [List<String> args = const []]) =>
    BdfdFunctionCallAst(
      name: name,
      arguments: [
        for (final arg in args) [BdfdTextAst(arg, start: 0, end: 1)],
      ],
      start: 0,
      end: 1,
    );

BdfdStatement _stmt(String name, [List<String> args = const []]) =>
    BdfdExpression(_call(name, args));

void main() {
  late List<String> log;
  late BdfdRuntime runtime;
  late BdfdContext context;

  setUp(() {
    log = [];
    context = BdfdContext();
    BdfdNativeFunction fn(
      String name,
      FutureOr<void> Function(BdfdInvocation call) body,
    ) => BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 2,
      handler: (call) async {
        log.add(name);
        await body(call);
        return '';
      },
    );
    runtime = BdfdRuntime(
      functions: {
        'bc_a': fn('a', (_) {}),
        'bc_b': fn('b', (_) {}),
        'bc_c': fn('c', (_) {}),
        'bc_fail': fn(
          'fail',
          (call) => throw BdfdNativeError('boom', call.location),
        ),
        'bc_enter': fn('enter', (_) {}),
        'bc_catch': fn('catch', (_) {}),
        'bc_exit': fn('exit', (_) {}),
        'bc_skipouter': fn('skipouter', (call) {
          call.context.requestSkip(1, outer: true);
        }),
        'bc_skipinner': fn('skipinner', (call) {
          call.context.requestSkip(1);
        }),
        'bc_jumpouter': fn('jumpouter', (call) {
          call.context.requestJump(4, outer: true);
        }),
      },
    );
  });

  Future<void> run(List<BdfdStatement> statements) => runtime.executeProgram(
    BdfdProgram.fromStatements('synthetic', statements),
    context: context,
  );

  group('BdfdTry lifecycle hooks', () {
    test('enter, body, exit when nothing fails', () async {
      await run([
        BdfdTry(
          _call('bc_try'),
          [_stmt('bc_a')],
          [_stmt('bc_b')],
          enter: _call('bc_enter'),
          onCatch: _call('bc_catch'),
          exit: _call('bc_exit'),
        ),
      ]);
      expect(log, ['enter', 'a', 'exit']);
    });

    test('a caught failure runs onCatch, the catch body, then exit', () async {
      await run([
        BdfdTry(
          _call('bc_try'),
          [_stmt('bc_fail'), _stmt('bc_a')],
          [_stmt('bc_b')],
          enter: _call('bc_enter'),
          onCatch: _call('bc_catch'),
          exit: _call('bc_exit'),
        ),
      ]);
      expect(log, ['enter', 'fail', 'catch', 'b', 'exit']);
    });

    test('a failing catch body skips exit and propagates', () async {
      await expectLater(
        run([
          BdfdTry(
            _call('bc_try'),
            [_stmt('bc_fail')],
            [_stmt('bc_fail')],
            enter: _call('bc_enter'),
            exit: _call('bc_exit'),
          ),
        ]),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(log, ['enter', 'fail', 'fail']);
    });

    test('hooks are validated with the program', () async {
      await expectLater(
        run([
          BdfdTry(
            _call('bc_try'),
            const [],
            const [],
            enter: _call('bc_enter', ['1', '2', '3']),
          ),
        ]),
        throwsA(isA<BdfdNativeError>()),
      );
    });
  });

  group('requests made from a catch body', () {
    BdfdTry guarded(String request) =>
        BdfdTry(_call('bc_try'), [_stmt('bc_fail')], [_stmt(request)]);

    test('an outer skip lands on the list that holds the try', () async {
      await run([guarded('bc_skipouter'), _stmt('bc_a'), _stmt('bc_b')]);
      expect(log, ['fail', 'skipouter', 'b']);
    });

    test('an inner skip is consumed by the catch body itself', () async {
      await run([guarded('bc_skipinner'), _stmt('bc_a'), _stmt('bc_b')]);
      expect(log, ['fail', 'skipinner', 'a', 'b']);
    });

    test('an outer jump continues at the ordinal', () async {
      await run([
        guarded('bc_jumpouter'),
        _stmt('bc_a'),
        _stmt('bc_b'),
        _stmt('bc_c'),
      ]);
      expect(log, ['fail', 'jumpouter', 'c']);
    });

    test('a nested try hands the request to its own parent list', () async {
      await run([
        BdfdTry(_call('bc_try'), [
          guarded('bc_skipouter'),
          _stmt('bc_a'),
          _stmt('bc_b'),
        ], const []),
        _stmt('bc_c'),
      ]);
      expect(log, ['fail', 'skipouter', 'b', 'c']);
    });
  });

  group('step limit', () {
    test('maxSteps can be tightened around a program', () async {
      context.maxSteps = context.steps + 5;
      await expectLater(
        run([for (var i = 0; i < 10; i++) _stmt('bc_a')]),
        throwsA(
          isA<BdfdNativeError>().having(
            (e) => e.message,
            'message',
            'Execution step limit exceeded.',
          ),
        ),
      );
    });

    test('steps are exposed and cumulative', () async {
      await run([_stmt('bc_a')]);
      final first = context.steps;
      await run([_stmt('bc_a')]);
      expect(context.steps, greaterThan(first));
    });
  });

  group('startScript', () {
    test('forgets the stop flag a previous script left', () {
      context.stopped = true;
      context.removeLinks = true;
      context.startScript();
      expect(context.stopped, isFalse);
      expect(context.removeLinks, isFalse);
    });

    test('depth counts the programs executing on the context', () async {
      var seen = -1;
      runtime = BdfdRuntime(
        functions: {
          'bc_depth': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (call) {
              seen = call.context.depth;
              return '';
            },
          ),
        },
      );
      await run([_stmt('bc_depth')]);
      expect(seen, 1);
      expect(context.depth, 0);
    });
  });

  group('translated blocks', () {
    const translator = ActionTranslator();
    Action role(String key, {Map<String, String> error = const {}}) => Action(
      type: BotCreatorActionType.addRole,
      key: key,
      payload: {'userId': '1', 'roleId': '2'},
    )..error.addAll(error);

    Action loop(List<Action> body, {Map<String, String> error = const {}}) =>
        Action(
          type: BotCreatorActionType.forLoop,
          key: 'loop',
          payload: {
            'mode': 'simple',
            'iterations': '2',
            'bodyActions': body.map((a) => a.toJson()).toList(),
          },
        )..error.addAll(error);

    test('a loop is one native while whose body keeps its own ordinals', () {
      final result = translator.translate([
        loop([role('a'), role('b')]),
      ]);
      final statement = result.program.statements.single as BdfdLoop;
      expect(statement.syntax.kind.name, 'whileLoop');
      expect((statement.node as BdfdFunctionCallAst).name, 'bc_forLoop');
      expect(statement.body, hasLength(2));
      final refs = result.refs.values.where((r) => !r.topLevel).toList();
      expect(refs.map((r) => r.ordinal), [1, 2]);
      // Children live under the loop key and an iteration marker.
      expect(refs.first.path.first, 'loop');
      expect(refs.first.path.last, startsWith(visualIterationMarker));
    });

    test('a block with its own error mode is wrapped in a try', () {
      for (final mode in [
        {'mode': 'continue'},
        {'mode': 'skip', 'skipCount': '2'},
      ]) {
        final result = translator.translate([
          loop([role('a')], error: mode),
        ]);
        final statement = result.program.statements.single as BdfdTry;
        expect(statement.body.single, isA<BdfdLoop>());
        expect(statement.catchBody, hasLength(1));
      }
      // The routed top-level action leaves its own mode to the caller.
      final routed = translator.translate([
        loop([role('a')], error: {'mode': 'continue'}),
      ], topLevelErrorModes: false);
      expect(routed.program.statements.single, isA<BdfdLoop>());
    });

    test(
      'tryCatch becomes a try with lifecycle hooks and no extra statements',
      () {
        final block = Action(
          type: BotCreatorActionType.ifBlock,
          key: 't',
          payload: {
            'tryCatch': true,
            'thenActions': [role('a').toJson()],
            'elseActions': [role('b').toJson(), role('c').toJson()],
          },
        );
        final statement =
            translator.translate([block]).program.statements.single as BdfdTry;
        expect(statement.body, hasLength(1));
        expect(statement.catchBody, hasLength(2));
        expect(statement.enter, isNotNull);
        expect(statement.onCatch, isNotNull);
        expect(statement.exit, isNotNull);
      },
    );

    test('children of a protected list carry no error mode', () {
      final block = Action(
        type: BotCreatorActionType.ifBlock,
        key: 't',
        payload: {
          'tryCatch': true,
          'thenActions': [
            role('a', error: {'mode': 'continue'}).toJson(),
          ],
          'elseActions': <dynamic>[],
        },
      );
      final statement =
          translator.translate([block]).program.statements.single as BdfdTry;
      final call =
          (statement.body.single as BdfdExpression).node as BdfdFunctionCallAst;
      expect((call.arguments[2].single as BdfdTextAst).value, '{"path":["t"]}');
    });

    test('jumpToAction carries the table of its list', () {
      final jump = Action(
        type: BotCreatorActionType.jumpToAction,
        key: 'j',
        payload: {'targetKey': 'end'},
      );
      final program = translator.translate([jump, role('a'), role('end')]);
      final call =
          (program.program.statements.first as BdfdExpression).node
              as BdfdFunctionCallAst;
      final options = (call.arguments[2].single as BdfdTextAst).value;
      expect(options, contains('"own":1'));
      expect(options, contains('"count":3'));
      expect(options, contains('"end":3'));
    });
  });
}
