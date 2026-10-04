import 'dart:math';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/services/math_operations.dart';
import 'package:bot_creator_shared/utils/math_parser.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');

class _Random implements Random {
  _Random({required this.fraction});
  final double fraction;
  int fractions = 0;
  int integers = 0;
  @override
  double nextDouble() {
    fractions++;
    return fraction;
  }

  @override
  int nextInt(int max) {
    integers++;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'decimal random reports precision-collapsed bounds without entropy draws',
    () async {
      final random = _Random(fraction: .5);
      await expectLater(
        _engine().execute(
          r'$enableDecimals[yes]$random[9223372036854775806;9223372036854775807]',
          context: BdfdContext(random: random),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(random.fractions, 0);
      expect(random.integers, 0);
    },
  );
  test(
    'native power precedence uses right association and protects legacy mode',
    () async {
      expect(
        await _engine().execute(
          r'$enableDecimals[yes]$calculate[2**3**2]|$calculate[-2**2]|$calculate[(-2)**2]|$calculate[2**-2]',
        ),
        '512|-4|4|0.25',
      );
      expect(MathExpressionParser.evaluate('2**3**2'), 64);
      expect(MathExpressionParser.evaluate('-2**2'), 4);
      expect(
        MathExpressionParser.evaluate(
          '${'2**' * 20}2',
          strictArithmetic: true,
          maxDepth: 8,
        ),
        isNull,
      );
    },
  );
  test('enableDecimals defaults no and controls math fraction output', () async {
    final context = BdfdContext();
    final engine = _engine();
    expect(context.decimalsEnabled, false);
    expect(
      await engine.execute(
        r'$divide[5;2]|$sum[1.2;1.3]|$sub[3.2;1]|$multi[1.5;1.5]|$calculate[10+5.9-9]',
        context: context,
      ),
      '3|3|2|2|7',
    );
    expect(
      await engine.execute(
        r'$enableDecimals[yes]$divide[5;2]|$sum[1.2;1.3]|$sub[3.2;1]|$multi[1.5;1.5]|$calculate[10+5.9-9]',
        context: context,
      ),
      '2.5|2.5|2.2|2.25|6.9',
    );
    expect(context.decimalsEnabled, true);
    expect(
      await engine.execute(
        r'$enableDecimals[no]$divide[5;2]',
        context: context,
      ),
      '3',
    );
    expect(context.decimalsEnabled, false);
  });
  test(
    'decimal state shares explicit eval and isolates distinct invocations',
    () async {
      final engine = _engine();
      final context = BdfdContext(
        temporaryVariables: {'code': r'$enableDecimals[yes]$divide[5;2]'},
      );
      expect(
        await engine.execute(
          r'$eval[$var[code]]|$divide[5;2]',
          context: context,
        ),
        '2.5|2.5',
      );
      expect(
        await engine.execute(r'$divide[5;2]', context: BdfdContext()),
        '3',
      );
      expect(
        await engine.execute(
          r'$if[false]$enableDecimals[yes]$endif$divide[5;2]',
        ),
        '3',
      );
    },
  );
  test(
    'sqrt matches official negative errors and default nearest examples',
    () async {
      expect(
        await _engine().execute(r'$sqrt[25]|$sqrt[2]|$sqrt[24]|$sqrt[0]'),
        '5|1|5|0',
      );
      expect(
        await _engine().execute(r'$enableDecimals[yes]$sqrt[2.25]|$sqrt[25]'),
        '1.5|5',
      );
      final value = double.parse(
        await _engine().execute(r'$enableDecimals[yes]$sqrt[2]'),
      );
      expect(value, closeTo(sqrt(2), 1e-15));
      await expectLater(
        _engine().execute(r'$sqrt[-2]'),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'round supports official decimal-place example and vacantable zero default',
    () async {
      for (final entry in {
        r'$round[100.123;1]': '100.1',
        r'$round[1.5]': '2',
        r'$round[1.5;]': '2',
        r'$round[100.123;2]': '100.12',
        r'$round[1.005;2]': '1.01',
        r'$round[-1.5]': '-1',
        r'$round[-1.005;2]': '-1',
        r'$round[-1.006;2]': '-1.01',
        r'$round[15;-1]': '20',
        r'$round[-15;-1]': '-10',
        r'$round[1.25;999999999999999999999999]': '1.25',
        r'$round[1.25;-999999999999999999999999]': '0',
        r'$round[1e-320;320]': '1e-320',
        r'$round[1e-320;319]': '0',
        r'$round[9223372036854775808;0]': '9223372036854775808',
      }.entries) {
        expect(
          await _engine().execute(entry.key),
          entry.value,
          reason: entry.key,
        );
      }
      expect(
        await _engine().execute(
          r'$enableDecimals[no]$round[100.123;1]|$enableDecimals[yes]$round[100.123;1]',
        ),
        '100.1|100.1',
      );
    },
  );
  test(
    'ceil floor follow official negative examples and preserve integer precision',
    () async {
      expect(
        await _engine().execute(
          r'$ceil[6.3]|$ceil[-6.4]|$ceil[8]|$floor[6.2]|$floor[-6.4]|$floor[9]',
        ),
        '7|-6|8|6|-7|9',
      );
      expect(
        await _engine().execute(
          r'$ceil[9223372036854775807]|$floor[9223372036854775807]',
        ),
        '9223372036854775807|9223372036854775807',
      );
    },
  );
  test(
    'min max require integers and compare exact values beyond signed64',
    () async {
      expect(await _engine().execute(r'$min[3;5;1]|$max[100;20;50]'), '1|100');
      expect(
        await _engine().execute(
          r'$min[9223372036854775809;9223372036854775808]|$max[-999999999999999999999999;-1000000000000000000000000]',
        ),
        '9223372036854775808|-999999999999999999999999',
      );
      for (final source in [
        r'$min[1.2;2]',
        r'$enableDecimals[yes]$max[1.0;2]',
        r'$min[0x10;2]',
        r'$max[;2]',
      ]) {
        await expectLater(
          _engine().execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'modulo reproduces official examples and dividend-sign remainder convention',
    () async {
      expect(
        await _engine().execute(r'$modulo[5;10]|$modulo[10;100]|$modulo[25;5]'),
        '5|10|0',
      );
      expect(
        await _engine().execute(r'$modulo[-5;3]|$modulo[5;-3]|$modulo[-5;-3]'),
        '-2|2|-2',
      );
      expect(await _engine().execute(r'$modulo[9223372036854775808;3]'), '2');
      for (final source in [
        r'$modulo[1;0]',
        r'$modulo[1.5;2]',
        r'$modulo[1;2.0]',
      ]) {
        await expectLater(
          _engine().execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'calculate applies documented operators and rejects zero divisors in strict native mode',
    () async {
      expect(
        await _engine().execute(
          r'$enableDecimals[yes]$calculate[(10+5.9)-9]|$calculate[2**3]|$calculate[10%3]|$calculate[-5%3]',
        ),
        '6.9|8|1|-2',
      );
      expect(await _engine().execute('\$calculate[2\t+\n3]'), '5');
      for (final source in [
        r'$calculate[1/0]',
        r'$calculate[1%0]',
        r'$calculate[1/(2-2)+4]',
        r'$calculate[(-1)**.5]',
        r'$divide[1;0]',
        r'$divide[1;-0.0]',
      ]) {
        await expectLater(
          _engine().execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(MathExpressionParser.evaluate('1/0'), 0);
      expect(MathExpressionParser.evaluate('1%0'), 0);
      expect(
        MathExpressionParser.evaluate('1/0', strictArithmetic: true),
        isNull,
      );
      expect(
        MathExpressionParser.evaluate('1%0', strictArithmetic: true),
        isNull,
      );
    },
  );
  test(
    'integer arithmetic avoids signed overflow and huge double formatting avoids clamping',
    () async {
      expect(
        await _engine().execute(
          r'$sum[9223372036854775807;1]|$sub[-9223372036854775808;1]|$multi[1000000000000;1000000000000]',
        ),
        '9223372036854775808|-9223372036854775809|1000000000000000000000000',
      );
      final text = bdfdNumberText(1e100);
      expect(
        await _engine().execute(r'$sum[9223372036854775808;1]'),
        '9223372036854775809',
      );
      expect(BigInt.parse(text), BigInt.from(1e100));
      expect(text.length, 101);
    },
  );
  test(
    'decimals-enabled random uses decimal draws even for integer endpoints',
    () async {
      final random = _Random(fraction: .59525);
      final context = BdfdContext(random: random);
      expect(
        await _engine().execute(
          r'$enableDecimals[yes]$random[1;5]',
          context: context,
        ),
        '3.381',
      );
      expect(random.fractions, 1);
      expect(random.integers, 0);
      expect(
        await _engine().execute(
          r'$enableDecimals[no]$random[1;5]',
          context: context,
        ),
        '1',
      );
      expect(random.integers, 1);
      expect(
        await _engine().execute(
          r'$enableDecimals[yes]$random',
          context: context,
        ),
        '5.9525',
      );
    },
  );
  test(
    'decimals-disabled random with fractional bounds selects in-range integers',
    () async {
      final random = _Random(fraction: .59525);
      expect(
        await _engine().execute(
          r'$random[1.25;2.25]|$random[-2.5;-1.5]',
          context: BdfdContext(random: random),
        ),
        '2|-2',
      );
      expect(random.fractions, 0);
      await expectLater(
        _engine().execute(r'$random[1.2;1.8]'),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test('bad arities fail before effects and decimal state changes', () async {
    for (final source in [
      r'$enableDecimals',
      r'$enableDecimals[yes;no]',
      r'$sqrt',
      r'$sqrt[2;3]',
      r'$modulo[1]',
      r'$modulo[1;2;3]',
      r'$round',
      r'$round[1;2;3]',
      r'$min[1]',
      r'$max[1]',
    ]) {
      final context = BdfdContext();
      await expectLater(
        _engine().execute(
          r'$var[bad;1]$enableDecimals[yes]' + source,
          context: context,
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(context.temporaryVariables['bad'], isNull);
      expect(context.decimalsEnabled, false);
    }
  });
  test('invalid numeric fields and decimal switches report errors', () async {
    for (final source in [
      r'$enableDecimals[]',
      r'$enableDecimals[maybe]',
      r'$sqrt[NaN]',
      r'$sqrt[Infinity]',
      r'$round[Infinity;1]',
      r'$round[1;1.5]',
      r'$round[1;0x1]',
      r'$sum[1;0x2]',
    ]) {
      await expectLater(
        _engine().execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
  });
  test(
    'unknown functions remain literal and do not toggle decimals inside their arguments',
    () async {
      final context = BdfdContext();
      const source = r'$unknown[$enableDecimals[yes];$sqrt[$var[bad;1]]]';
      expect(await _engine().execute(source, context: context), source);
      expect(context.decimalsEnabled, false);
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test(
    'strict parser limits nested expressions and observes budget checks',
    () async {
      expect(
        MathExpressionParser.evaluate(
          '${'(' * 30}1${')' * 30}',
          strictArithmetic: true,
          maxDepth: 8,
        ),
        isNull,
      );
      expect(
        MathExpressionParser.evaluate(
          '${'-' * 30}1',
          strictArithmetic: true,
          maxDepth: 8,
        ),
        isNull,
      );
      await expectLater(
        _engine().execute(
          '\$calculate[${'(' * 30}1${')' * 30}]',
          context: BdfdContext(maxDepth: 8),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      var checks = 0;
      expect(
        () => MathExpressionParser.evaluate(
          List.filled(1000, '1').join('+'),
          strictArithmetic: true,
          checkBudget: () {
            if (++checks == 5) throw StateError('cancelled');
          },
        ),
        throwsStateError,
      );
      expect(checks, 5);
    },
  );
  test(
    'production sandbox uses decimal switch and pure math without fixtures or effects',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$enableDecimals[yes]$sqrt[2.25]|$round[100.123;1]|$modulo[25;5]|$divide[5;2]',
        'bdfdBackend': 'native-v1',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '1.5|100.1|0|2.5');
      expect(result['effects'], isEmpty);
      expect(result['entity_requests'], isEmpty);
    },
  );
}
