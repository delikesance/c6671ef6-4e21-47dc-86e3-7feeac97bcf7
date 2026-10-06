import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/random_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:test/test.dart';

class _Output implements BdfdOutput, BdfdErrorOutput {
  String pending = '';
  Map<String, dynamic>? embed;
  final sent = <String>[];
  final embeds = <Map<String, dynamic>>[];
  bool failNextFlush = false;
  @override
  void append(String text) => pending += text;
  @override
  void discard() {
    pending = '';
    embed = null;
  }

  @override
  void replaceErrorEmbed(Map<String, dynamic> value) => embed = value;
  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async {
    if (failNextFlush) {
      failNextFlush = false;
      throw BdfdNativeError('Send failed', location);
    }
    if (pending.isNotEmpty) {
      sent.add(context.removeLinks ? removeBdfdLinks(pending) : pending);
    }
    if (embed != null) embeds.add(embed!);
    discard();
  }
}

void main() {
  test(
    'flush errors use suppression without retrying the original draft',
    () async {
      final sink = _Output()..failNextFlush = true;
      expect(
        await BdfdRuntime().execute(
          r'$suppressErrors[Oops]draft',
          context: BdfdContext(output: sink),
        ),
        'Oops',
      );
      expect(sink.sent, ['Oops']);
    },
  );
  test(
    'unescape expansion and argument reads evaluate effects only once',
    () async {
      var effects = 0;
      final runtime = BdfdRuntime(
        functions: {
          'effect': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              effects++;
              return 'a;b';
            },
          ),
          'inspect': BdfdNativeFunction(
            minArguments: 1,
            maxArguments: 1,
            handler: (call) async {
              final plain = await call.argument(0);
              final expanded = await call.expandedArguments();
              expect(await call.expandedArguments(), expanded);
              return '$plain/${expanded.join('|')}';
            },
          ),
        },
      );
      expect(await runtime.execute(r'$inspect[$unescape[$effect]]'), 'a;b/a|b');
      expect(effects, 1);
    },
  );
  test('functions execute at their call site with runtime data', () async {
    final runtime = BdfdRuntime();
    expect(
      await runtime.execute(
        r'$func[greet;Who]$funcReturn[Hello $funcArg[who]! ]$funcEnd$var[user;Alice]$funcCall[GREET;$var[user]]',
      ),
      'Hello Alice! ',
    );
  });
  test('body text is returned once and declarations emit nothing', () async {
    final sink = _Output();
    final result = await BdfdRuntime().execute(
      r'$func[wrap;x]<$funcArg[x]>$funcEnd$funcCall[wrap;a]$funcCall[wrap;b]',
      context: BdfdContext(output: sink),
    );
    expect(result, '<a><b>');
    expect(sink.sent, ['<a><b>']);
  });
  test(
    'nested calls evaluate arguments in caller scope and restore locals',
    () async {
      expect(
        await BdfdRuntime().execute(
          r'$func[inner;x]$funcReturn[<$funcArg[x]>]$funcEnd$func[outer;x]$funcCall[inner;$funcArg[x]]/$funcArg[x]$funcEnd$funcCall[outer;a]/$funcArg[x]',
        ),
        '<a>/a/',
      );
    },
  );
  test(
    'last executed return wins matching the existing local contract',
    () async {
      final context = BdfdContext();
      expect(
        await BdfdRuntime().execute(
          r'$func[f]discard$funcReturn[first]$var[effect;yes]$funcReturn[last]$funcEnd$funcCall[f]',
          context: context,
        ),
        'last',
      );
      expect(context.temporaryVariables['effect'], 'yes');
    },
  );
  test('nested function declarations are scoped to the function call', () async {
    expect(
      await BdfdRuntime().execute(
        r'$func[outer]$func[inner]value$funcEnd$funcCall[inner]$funcEnd$funcCall[outer]/$funcCall[inner]',
      ),
      'value/',
    );
  });
  test(
    'missing arguments default empty and surplus arguments stay lazy',
    () async {
      final context = BdfdContext();
      expect(
        await BdfdRuntime().execute(
          r'$func[f;x]<$funcArg[x]>$funcEnd$funcCall[f]/$funcCall[f;a;$var[bad;yes]]',
          context: context,
        ),
        '<>/<a>',
      );
      expect(context.temporaryVariables.containsKey('bad'), false);
    },
  );
  test(
    'undefined functions stay empty without evaluating unused arguments',
    () async {
      final context = BdfdContext();
      expect(
        await BdfdRuntime().execute(
          r'$funcCall[missing;$var[bad;yes]]',
          context: context,
        ),
        '',
      );
      expect(context.temporaryVariables, isEmpty);
    },
  );
  test('recursion is bounded and frames recover', () async {
    expect(
      await BdfdRuntime().execute(
        r'$func[f]x$funcCall[f]$funcEnd$funcCall[f]/$funcArg[x]',
      ),
      '${'x' * 10}/',
    );
  });
  test(
    'declared unused functions stay lazy but signatures preflight',
    () async {
      final context = BdfdContext();
      await BdfdRuntime().execute(
        r'$func[f]$var[bad;yes]$funcEnd',
        context: context,
      );
      expect(context.temporaryVariables, isEmpty);
      expect(
        BdfdRuntime().execute(
          r'$var[before;yes]$func[f]$var[x;y;z]$funcEnd',
          context: context,
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(context.temporaryVariables, isEmpty);
    },
  );
  test('malformed definitions reject before effects', () async {
    for (final source in [
      r'$func[f]',
      r'$funcEnd',
      r'$func[f;x;X]$funcEnd',
      r'$func[$var[x]]$funcEnd',
    ]) {
      expect(BdfdRuntime().execute(source), throwsA(isA<BdfdNativeError>()));
    }
  });
  test('unknown calls hide nested custom calls and declarations', () async {
    const source = r'$unknown[$func[f]$var[x;bad]$funcEnd$funcCall[f]]';
    final context = BdfdContext();
    expect(await BdfdRuntime().execute(source, context: context), source);
    expect(context.temporaryVariables, isEmpty);
  });
  test(
    'ordinary error suppression discards drafts and stops later effects',
    () async {
      final context = BdfdContext();
      expect(
        await BdfdRuntime().execute(
          r'$suppressErrors[Oops]$var[before;yes]draft$checkCondition[invalid]$var[after;bad]',
          context: context,
        ),
        'Oops',
      );
      expect(context.temporaryVariables, {'before': 'yes'});
      expect(context.stopped, true);
    },
  );
  test(
    'silent suppression and guards use the configured error response',
    () async {
      expect(
        await BdfdRuntime().execute(
          r'$suppressErrors draft$checkCondition[invalid]',
        ),
        '',
      );
      expect(
        await BdfdRuntime().execute(
          r'$suppressErrors[Configured]draft$onlyIf[false;Original]',
        ),
        'Configured',
      );
    },
  );
  test('try catches errors before global suppression', () async {
    expect(
      await BdfdRuntime().execute(
        r'$suppressErrors[Oops]$try$checkCondition[invalid]$catch Caught$endTry',
      ),
      ' Caught',
    );
  });
  test('error embeds replace drafts and inherit guard messages', () async {
    final sink = _Output();
    expect(
      await BdfdRuntime().execute(
        r'$embedSuppressErrors[Error;;#ff0000;Bot;Footer;https://example.com/icon.png]draft$onlyIf[false;Original]',
        context: BdfdContext(output: sink),
      ),
      '',
    );
    expect(sink.sent, isEmpty);
    expect(sink.embeds.single, {
      'title': 'Error',
      'description': 'Original',
      'color': 0xff0000,
      'author': {'name': 'Bot'},
      'footer': {'text': 'Footer', 'icon_url': 'https://example.com/icon.png'},
    });
  });
  test('error embeds validate empty fields, colors and icon URLs', () async {
    for (final source in [
      r'$embedSuppressErrors[;]',
      r'$embedSuppressErrors[E;;#zz]',
      r'$embedSuppressErrors[E;;;;F;file:///icon]',
    ]) {
      expect(BdfdRuntime().execute(source), throwsA(isA<BdfdNativeError>()));
    }
  });
  test('suppression does not swallow shared execution deadlines', () async {
    expect(
      BdfdRuntime().execute(
        r'$suppressErrors[Oops]$loop[1000000]$endLoop',
        context: BdfdContext(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test(
    'error policy and custom functions do not leak across invocations',
    () async {
      final context = BdfdContext();
      final runtime = BdfdRuntime();
      await runtime.execute(
        r'$func[f]value$funcEnd$suppressErrors$suppressErrorLogging$removeLinks',
        context: context,
      );
      expect(context.suppressErrorLogging, true);
      expect(
        await runtime.execute(
          r'$funcCall[f]https://example.com',
          context: context,
        ),
        'https://example.com',
      );
      expect(context.suppressErrorLogging, false);
      expect(
        runtime.execute(r'$checkCondition[invalid]', context: context),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'removeLinks filters complete drafts irrespective of directive position',
    () async {
      expect(
        await BdfdRuntime().execute(
          r'Link https://example.com/path end$removeLinks',
        ),
        'Link  end',
      );
    },
  );
  test(
    'unescape creates semicolon choices while ordinary runtime data stays literal',
    () async {
      final functions = bdfdRandomFunctions();
      functions['choices'] = BdfdNativeFunction(
        minArguments: 1,
        maxArguments: 100,
        handler: (call) async => (await call.expandedArguments()).join('|'),
      );
      final runtime = BdfdRuntime(functions: functions);
      expect(await runtime.execute(r'$var[x;ab]$unescape[]'), '');
      final context = BdfdContext(
        temporaryVariables: {'x': r'a;$var[bad;yes];c'},
      );
      expect(
        await runtime.execute(r'$choices[$var[x]]', context: context),
        r'a;$var[bad;yes];c',
      );
      expect(
        await runtime.execute(
          r'$choices[pre$unescape[$var[x]]post;z]',
          context: context,
        ),
        r'prea|$var[bad|yes]|cpost|z',
      );
      expect(context.temporaryVariables.containsKey('bad'), false);
    },
  );
}
