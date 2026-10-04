import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
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
      throw StateError('$invocation');
}

void main() {
  test(
    'C-style variables and iteration counters have distinct values',
    () async {
      expect(
        await BdfdRuntime().execute(
          r'$for[i=3,j=10;i>0;i--,j+=2]$i-$j-$loopIndex-$loopCount;$endfor',
        ),
        '3-10-0-1;2-12-1-2;1-14-2-3;',
      );
    },
  );

  test(
    'multiple C-style variables and arithmetic updates are executed at runtime',
    () async {
      expect(
        await BdfdRuntime().execute(
          r'$for[x=1,y=16;x<8;x*=2,y/=2]$x:$y;$endfor',
        ),
        '1:16;2:8;4:4;',
      );
    },
  );

  test(
    'fractional update operands preserve integer loop variable semantics',
    () async {
      expect(
        await BdfdRuntime().execute(r'$for[x=2;x<8;x*=1.5]$x,$endfor'),
        '2,3,4,6,',
      );
    },
  );

  test('conditions and updates observe changed temporary values', () async {
    expect(
      await BdfdRuntime().execute(
        r'$var[limit;6]$var[step;1]'
        r'$for[x=0;x<$var[limit];x+=$var[step]]$x'
        r'$if[$x==1]$var[step;2]$endif$endfor',
      ),
      '0135',
    );
  });

  test('continue applies C-style updates; break skips them', () async {
    expect(
      await BdfdRuntime().execute(
        r'$for[x=0;x<5;x++]$if[$x==1]$continue$endif'
        r'$if[$x==3]$break$endif$x$endfor done',
      ),
      '02 done',
    );
  });

  test('nested loops restore bindings even if an inner loop breaks', () async {
    expect(
      await BdfdRuntime().execute(
        r'$for[x=2;x<4;x++]$x:$for[x=7;x<10;x++]$x$break$endfor:$x;'
        r'$for[item;a;b]$item$endfor:$x;$endfor $x',
      ),
      r'2:7:2;ab:2;3:7:3;ab:3; $x',
    );
  });

  test('list values are evaluated once and remain data', () async {
    final context = BdfdContext(temporaryVariables: {'text': r'$stop'});
    expect(
      await BdfdRuntime().execute(
        r'$for[item;red;$var[text];blue]$item/$loopIndex;$endfor',
        context: context,
      ),
      r'red/0;$stop/1;blue/2;',
    );
  });

  test('loop alias supports count, list and C-style forms', () async {
    expect(
      await BdfdRuntime().execute(
        r'$loop[2]$i$endloop'
        r'$loop[item;a;b]$item$endloop$loop[x=3;x>0;x--]$x$endloop',
      ),
      '01ab321',
    );
  });

  test('invalid loop grammar is rejected before effects', () async {
    var effects = 0;
    final runtime = BdfdRuntime(
      functions: {
        'effect': BdfdNativeFunction(
          minArguments: 0,
          maxArguments: 0,
          handler: (_) {
            effects++;
            return '';
          },
        ),
      },
    );
    for (final source in [
      r'$effect$for[bad;i<3;i++]$endfor',
      r'$effect$for[x=0;x<3;not an update]$endfor',
      r'$effect$for[x=0;x<3;j++]$endfor',
    ]) {
      await expectLater(
        runtime.execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(effects, 0);
  });

  test(
    'evaluated initialization cannot introduce another loop assignment',
    () async {
      final context = BdfdContext(temporaryVariables: {'input': '0,j=2'});
      await expectLater(
        BdfdRuntime().execute(
          r'$for[x=$var[input];x<3;x++]body$endfor',
          context: context,
        ),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );

  test('empty infinite C-style loop stops at the shared deadline', () async {
    await expectLater(
      BdfdRuntime().execute(
        r'$for[x=0;x==0;x+=0]$endfor',
        context: BdfdContext(
          maxSteps: 100000000,
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 20),
          ),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });

  test(
    'final variables match the real block handler for runtime C-style and list loops',
    () async {
      const source =
          r'$var[limit;4]$var[trace;]'
          r'$for[x=0;x<$var[limit];x+=1]$var[trace;$var[trace]$x,]$endfor'
          r'$for[item;red;blue]$var[trace;$var[trace]$item,]$endfor';
      final compiled = BdfdCompiler().compile(source);
      expect(compiled.hasErrors, isFalse);
      final variables = <String, String>{};
      final result = await handleActions(
        _NoDiscord(),
        null,
        actions: compiled.actions,
        store: MemoryBotDataStore(),
        botId: 'native-loops-parity',
        variables: variables,
        resolveTemplate: (text) => resolveTemplatePlaceholders(text, variables),
      );
      expect(result['error'], isNull, reason: '$result');
      final context = BdfdContext();
      await BdfdRuntime().execute(source, context: context);
      expect(context.temporaryVariables['trace'], variables['temp.trace']);
      expect(context.temporaryVariables['trace'], '0,1,2,3,red,blue,');
    },
  );
}
