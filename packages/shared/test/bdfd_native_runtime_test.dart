import 'dart:async';

import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/context_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';

class _NoDiscord implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access: $invocation');
}

void main() {
  late BdfdRuntime runtime;
  late BdfdContext context;
  late List<String> effects;
  setUp(() {
    context = BdfdContext();
    effects = [];
    runtime = BdfdRuntime(
      functions: {
        'effect': BdfdNativeFunction(
          minArguments: 1,
          maxArguments: 1,
          handler: (call) async {
            effects.add(await call.argument(0));
            return '';
          },
        ),
        'fail': BdfdNativeFunction(
          minArguments: 0,
          maxArguments: 0,
          handler: (_) => throw StateError('service failure'),
        ),
      },
    );
  });

  test('runtime values remain data until explicit eval', () async {
    context.temporaryVariables['input'] = r'$effect[injected]';
    expect(
      await runtime.execute(
        r'$var[value;$var[input]]$var[value]',
        context: context,
      ),
      r'$effect[injected]',
    );
    expect(effects, isEmpty);
  });

  test(
    'branches evaluate in order, select one branch, then continue',
    () async {
      final result = await runtime.execute(
        r'$var[x;1]$if[$var[x]==0]$fail'
        r'$elseif[$var[x]==1]$effect[selected]$var[x;2]'
        r'$elseif[$fail]bad$else$effect[else]$endif'
        r'$if[$var[x]==2]yes$else$fail$endif$var[x]',
        context: context,
      );
      expect(result, 'yes2');
      expect(effects, ['selected']);
    },
  );

  test('inline if and boolean operators short circuit', () async {
    expect(
      await runtime.execute(
        r'$if[true;chosen;$fail]$and[false;$fail]$or[true;$fail]',
      ),
      'chosenfalsetrue',
    );
  });

  test('comments are neither validated as code nor evaluated', () async {
    expect(await runtime.execute(r'$c[$notAFunction[$fail]]ok'), 'ok');
  });

  test('counted loops restore the outer index', () async {
    expect(
      await runtime.execute(
        r'$var[n;2]$for[$var[n]]$i:$for[2]$i$endfor:$i;$endfor',
        context: context,
      ),
      '0:01:0;1:01:1;',
    );
  });

  test(
    'while rechecks mutated values and handles continue and break',
    () async {
      expect(
        await runtime.execute(
          r'$var[x;0]$while[$var[x]<5]$var[x;$sum[$var[x];1]]'
          r'$if[$var[x]==2]$continue$endif'
          r'$if[$var[x]==4]$break$endif$var[x]$endwhile:done',
          context: context,
        ),
        '13:done',
      );
      expect(context.temporaryVariables['x'], '4');
    },
  );

  test('stop preserves text and never replays effects', () async {
    expect(
      await runtime.execute(r'before$effect[once]$stop$effect[never]after'),
      'before',
    );
    expect(effects, ['once']);
  });

  test('onlyIf evaluates denial lazily and stops the script', () async {
    expect(await runtime.execute(r'$onlyIf[true;$fail]ok'), 'ok');
    expect(
      await runtime.execute(r'pending$onlyIf[false;denied]$effect[never]'),
      'denied',
    );
    expect(effects, isEmpty);
  });

  test('try catches service failures without replaying effects', () async {
    expect(
      await runtime.execute(
        r'$try$effect[once]$fail$effect[never]$catch recovered$endtry done',
        context: context,
      ),
      ' recovered done',
    );
    expect(effects, ['once']);
    expect(context.results['error.message'], contains(r'$fail'));
  });

  test('try does not catch stop or loop control', () async {
    expect(
      await runtime.execute(r'$try before$stop$catch bad$endtry after'),
      ' before',
    );
    expect(
      await runtime.execute(r'$for[3]$try$break$catch bad$endtry$endfor done'),
      ' done',
    );
  });

  test('eval shares temporary state and response state', () async {
    context.temporaryVariables['code'] = r'$var[x;changed]nested';
    final response = context.response;
    expect(
      await runtime.execute(r'$eval[$var[code]]:$var[x]', context: context),
      'nested:changed',
    );
    expect(identical(context.response, response), isTrue);
  });

  test('diagnostics locate errors inside dynamic code', () async {
    context.temporaryVariables['code'] = '\n\$fail';
    await expectLater(
      runtime.execute(r'$eval[$var[code]]', context: context),
      throwsA(
        isA<BdfdNativeError>()
            .having((e) => e.location.line, 'line', 2)
            .having((e) => e.location.column, 'column', 1)
            .having((e) => e.location.functionName, 'function', r'$fail'),
      ),
    );
  });

  test(
    'unknown functions are preserved verbatim without evaluating their arguments',
    () async {
      const source =
          r'Hello $UnKnOwN[  a ; $effect[never];$sum[bad] ] / $unknown';
      expect(await runtime.execute(source), source);
      expect(effects, isEmpty);
      expect(
        await runtime.execute(r'$if[false]$unknown[$fail]$endif done'),
        ' done',
      );
    },
  );

  test(
    'unknown functions stay literal inside recognized arguments and explicit eval',
    () async {
      expect(
        await runtime.execute(r'$var[x;$unknown[$fail]]$var[x]'),
        r'$unknown[$fail]',
      );
      context.temporaryVariables['code'] = r'$unknown[$effect[never]]';
      expect(
        await runtime.execute(r'$eval[$var[code]]', context: context),
        r'$unknown[$effect[never]]',
      );
      expect(effects, isEmpty);
    },
  );

  test('known functions not yet migrated fail before effects', () async {
    await expectLater(
      runtime.execute(r'$effect[never]$title[Pending]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(effects, isEmpty);
  });

  test('invalid arity fails before effects', () async {
    await expectLater(
      runtime.execute(r'$effect[never]$sum[1]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(effects, isEmpty);
  });

  test('unbalanced or misplaced branches fail before effects', () async {
    for (final source in [
      r'$effect[x]$if[true]x',
      r'$effect[x]$else',
      r'$if[true]x$else y$elseif[false]z$endif',
      r'$for[1]x$endwhile',
    ]) {
      await expectLater(
        runtime.execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(effects, isEmpty);
  });

  test('math uses the shared parser and rejects nonfinite results', () async {
    expect(
      await runtime.execute(
        r'$enableDecimals[yes]$ceil[$calculate[100*(1.5^2)]]:$divide[5;2]',
      ),
      '225:2.5',
    );
    await expectLater(
      runtime.execute(r'$divide[1;0]'),
      throwsA(isA<BdfdNativeError>()),
    );
  });

  test('step limit terminates an infinite loop', () async {
    await expectLater(
      runtime.execute(
        r'$while[true]$endwhile',
        context: BdfdContext(maxSteps: 20),
      ),
      throwsA(
        isA<BdfdNativeError>().having(
          (e) => e.message,
          'message',
          contains('step limit'),
        ),
      ),
    );
  });

  test('recursive eval shares the invocation limit', () async {
    final recursive = BdfdContext(maxDepth: 4);
    recursive.temporaryVariables['code'] = r'$eval[$var[code]]';
    await expectLater(
      runtime.execute(r'$eval[$var[code]]', context: recursive),
      throwsA(
        isA<BdfdNativeError>().having(
          (e) => e.message,
          'message',
          contains('limit'),
        ),
      ),
    );
    expect(recursive.callStack, isEmpty);
  });

  test(
    'timeout blocks later effects after asynchronous work resumes',
    () async {
      final gate = Completer<String>();
      final budget = CommandExecutionBudget(
        limit: const Duration(milliseconds: 20),
      );
      final waiting = BdfdRuntime(
        functions: {
          'wait': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) => gate.future,
          ),
          'effect': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              effects.add('unexpected');
              return '';
            },
          ),
        },
      );
      await expectLater(
        waiting.execute(
          r'$try$wait$catch$effect$endtry$effect',
          context: BdfdContext(budget: budget),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      gate.complete('late');
      await Future<void>.delayed(Duration.zero);
      expect(effects, isEmpty);
    },
  );

  test(
    'context functions read current values without interpreting them as code',
    () async {
      final current = BdfdContext(
        variables: {'message.content': r'$effect[injected]'},
      );
      final engine = BdfdRuntime(functions: bdfdContextFunctions());
      expect(
        await engine.execute(r'$message', context: current),
        r'$effect[injected]',
      );
      current.variables['message.content'] = 'changed';
      expect(await engine.execute(r'$message', context: current), 'changed');
    },
  );

  test(
    'an argument with effects is evaluated once even when requested twice',
    () async {
      var reads = 0;
      final engine = BdfdRuntime(
        functions: {
          'read': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) => '${++reads}',
          ),
          'twice': BdfdNativeFunction(
            minArguments: 1,
            maxArguments: 1,
            handler: (call) async =>
                '${await call.argument(0)}:${await call.argument(0)}',
          ),
        },
      );
      expect(await engine.execute(r'$twice[$read]'), '1:1');
      expect(reads, 1);
    },
  );

  test(
    'nested scripts share acknowledgement state through service callbacks',
    () async {
      final engine = BdfdRuntime(
        functions: {
          'ack': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (call) {
              if (call.context.response.acknowledged) return 'followup';
              call.context.response.acknowledged = true;
              return 'initial';
            },
          ),
        },
      );
      context.temporaryVariables['code'] = r'$ack';
      expect(
        await engine.execute(r'$eval[$var[code]]:$ack', context: context),
        'initial:followup',
      );
    },
  );

  test(
    'nested errors retain the calling function stack after cleanup',
    () async {
      context.temporaryVariables['code'] = r'$fail';
      try {
        await runtime.execute(r'$eval[$var[code]]', context: context);
        fail('Expected a service failure.');
      } on BdfdNativeError catch (error) {
        expect(error.callStack.map((frame) => frame.functionName), [
          r'$eval',
          r'$fail',
        ]);
      }
      expect(context.callStack, isEmpty);
    },
  );

  test(
    'parity with actual block runtime on nested variables and branches',
    () async {
      const source =
          r'$var[x;0]$for[4]'
          r'$if[$i<2]$var[x;$sum[$var[x];2]]'
          r'$else$var[x;$sum[$var[x];3]]$endif$endfor'
          r'$var[label;$toUpperCase[value]]';
      final compiled = BdfdCompiler().compile(source);
      expect(compiled.hasErrors, isFalse);
      final legacy = <String, String>{};
      final result = await handleActions(
        _NoDiscord(),
        null,
        actions: compiled.actions,
        store: MemoryBotDataStore(),
        botId: 'native-parity',
        variables: legacy,
        resolveTemplate: (text) => resolveTemplatePlaceholders(text, legacy),
      );
      expect(result['error'], isNull, reason: '$result');
      await runtime.execute(source, context: context);
      expect(context.temporaryVariables['x'], legacy['temp.x']);
      expect(context.temporaryVariables['label'], legacy['temp.label']);
      expect(context.temporaryVariables['x'], '10');
    },
  );
}
