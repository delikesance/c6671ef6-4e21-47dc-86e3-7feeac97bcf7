import 'dart:math';
import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/random_operations.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');

class _Draws implements Random {
  _Draws({this.ints = const [], this.fraction = 0});
  final List<int> ints;
  final double fraction;
  final limits = <int>[];
  int index = 0;
  int decimalReads = 0;
  @override
  int nextInt(int max) {
    limits.add(max);
    final value = index < ints.length ? ints[index++] : max - 1;
    if (value < 0 || value >= max) {
      throw StateError('Invalid test random draw.');
    }
    return value;
  }

  @override
  double nextDouble() {
    decimalReads++;
    return fraction;
  }

  @override
  bool nextBool() => throw UnimplementedError();
}

void main() {
  test('bare random produces digits including both endpoints', () async {
    final rng = _Draws(ints: [0, 9]);
    expect(
      await _engine().execute(
        r'$random|$random',
        context: BdfdContext(random: rng),
      ),
      '0|9',
    );
    expect(rng.limits, [10, 10]);
  });
  test('integer random includes minimum and excludes maximum', () async {
    final rng = _Draws(ints: [0, 4]);
    expect(
      await _engine().execute(
        r'$random[1;6]|$random[1;6]|$random[-2;-1]',
        context: BdfdContext(random: rng),
      ),
      '1|5|-2',
    );
    expect(rng.limits, [5, 5]);
  });
  test('wide integer range remains exact without signed overflow', () async {
    final rng = _Draws(ints: [0, 0, 4294967295, 4294967294]);
    expect(
      await _engine().execute(
        r'$random[-9223372036854775808;9223372036854775807]|$random[-9223372036854775808;9223372036854775807]',
        context: BdfdContext(random: rng),
      ),
      '-9223372036854775808|9223372036854775806',
    );
    expect(rng.limits, [4294967296, 4294967296, 4294967296, 4294967296]);
  });
  test('wide integer sampler rejects samples outside population', () {
    final rng = _Draws(ints: [4294967295, 1, 0, 0]);
    expect(
      randomInteger(rng, 0, 4294967297, CommandExecutionBudget()),
      BigInt.zero,
    );
    expect(rng.limits, [4294967296, 2, 4294967296, 2]);
  });
  test('wide integer rejection sampling obeys the shared deadline', () {
    final budget = CommandExecutionBudget(
      limit: const Duration(milliseconds: 10),
    );
    expect(
      () => randomInteger(_Draws(), 0, 4294967297, budget),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test('decimal random respects bounds and preserves decimal output', () async {
    final context = BdfdContext(random: _Draws(fraction: .5));
    expect(
      await _engine().execute(
        r'$enableDecimals[yes]$random[1.25;2.25]|$random[-2.5;-1.5]',
        context: context,
      ),
      '1.75|-2',
    );
  });
  test('decimal interpolation cannot round to excluded upper endpoint', () {
    final rng = _Draws(fraction: .9999999999999999);
    expect(randomDecimal(rng, 1.0, 1.0000000000000002), 1.0);
    final negative = randomDecimal(rng, -1.0000000000000002, -1.0);
    expect(negative, lessThan(-1.0));
    expect(negative, greaterThanOrEqualTo(-1.0000000000000002));
    expect(randomDecimal(rng, -double.minPositive, 0), -double.minPositive);
  });
  test('decimal range handles spans exceeding maximum finite double', () {
    expect(randomDecimal(_Draws(fraction: .5), -1e308, 1e308), 0);
    final value = randomDecimal(
      _Draws(fraction: .9999999999999999),
      -1e308,
      1e308,
    );
    expect(value.isFinite, true);
    expect(value, lessThan(1e308));
  });
  test('randomText preserves selected spaces and empty options', () async {
    final context = BdfdContext(random: _Draws(ints: [0, 1, 0]));
    expect(
      await _engine().execute(
        r'$randomText[ hello ;bye]|$randomText[hello;]|$randomText[]',
        context: context,
      ),
      ' hello ||',
    );
  });
  test('randomText evaluates selected argument only once', () async {
    final context = BdfdContext(random: _Draws(ints: [1]));
    expect(
      await _engine().execute(
        r'$randomText[$var[wrong;1]a;$var[right;1]b]',
        context: context,
      ),
      'b',
    );
    expect(context.temporaryVariables, {'right': '1'});
  });
  test('randomText output is data and is never interpreted as code', () async {
    final context = BdfdContext(
      random: _Draws(ints: [0]),
      temporaryVariables: {'data': r'$var[bad;1]'},
    );
    expect(
      await _engine().execute(r'$randomText[$var[data]]', context: context),
      r'$var[bad;1]',
    );
    expect(context.temporaryVariables['bad'], isNull);
  });
  test(
    'randomString uses uppercase lowercase and digit alphabet with length cap',
    () async {
      final rng = _Draws(ints: [0, 25, 26, 51, 52, 61]);
      expect(
        await _engine().execute(
          r'$randomString[6]',
          context: BdfdContext(random: rng),
        ),
        'AZaz09',
      );
      expect(rng.limits, List.filled(6, 62));
      expect(
        await _engine().execute(r'$randomString[10]'),
        matches(RegExp(r'^[A-Za-z0-9]{10}$')),
      );
    },
  );
  test('invalid random bounds and lengths consume no entropy', () async {
    final rng = _Draws();
    for (final source in [
      r'$random[1;1]',
      r'$random[6;1]',
      r'$random[;5]',
      r'$random[0;Infinity]',
      r'$random[NaN;1]',
      r'$randomString[0]',
      r'$randomString[11]',
      r'$randomString[1.5]',
      r'$randomString[]',
    ]) {
      await expectLater(
        _engine().execute(source, context: BdfdContext(random: rng)),
        throwsA(isA<BdfdNativeError>()),
        reason: source,
      );
    }
    expect(rng.limits, isEmpty);
    expect(rng.decimalReads, 0);
  });
  test('invalid arity rejects in preflight before preceding effects', () async {
    final context = BdfdContext();
    for (final source in [
      r'$random[1]',
      r'$random[1;2;3]',
      r'$randomString[1;abc]',
      r'$randomText',
    ]) {
      await expectLater(
        _engine().execute(r'$var[bad;1]' + source, context: context),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(context.temporaryVariables['bad'], isNull);
    BdfdEngine.validation().prepare(
      r'$random$random[1;6]$randomText[]$randomString[10]',
    );
  });
  test(
    'unknown functions preserve random expressions and consume no entropy',
    () async {
      final rng = _Draws();
      const source = r'$unknown[$random;$randomString[10];$randomText[a;b]]';
      expect(
        await _engine().execute(source, context: BdfdContext(random: rng)),
        source,
      );
      expect(rng.limits, isEmpty);
    },
  );
  test('random functions share context across explicit eval', () async {
    final rng = _Draws(ints: [0, 1, 2]);
    final context = BdfdContext(
      random: rng,
      temporaryVariables: {'code': r'$random$randomString[1]'},
    );
    expect(
      await _engine().execute(r'$random$eval[$var[code]]', context: context),
      '01C',
    );
    expect(rng.limits, [10, 10, 62]);
  });
  test(
    'sandbox random functions execute natively without block effects',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$random[7;8]|$randomText[only]|$randomString[10]',
        'bdfdBackend': 'native-v1',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], isEmpty);
      expect(
        result['results']['output'],
        matches(RegExp(r'^7\|only\|[A-Za-z0-9]{10}$')),
      );
    },
  );
}
