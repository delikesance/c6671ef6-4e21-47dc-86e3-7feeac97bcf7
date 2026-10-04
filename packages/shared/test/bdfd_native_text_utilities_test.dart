import 'dart:convert';

import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/text_utility_functions.dart';
import 'package:bot_creator_shared/services/text_utility_operations.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  functions: bdfdTextUtilityFunctions(),
);

void main() {
  test('byteCount matches official multilingual UTF-8 examples', () async {
    for (final entry in {
      'Hello World!': 12,
      'Привет Мир!': 20,
      '你好世界！': 15,
      '': 0,
      '😀': 4,
      'e\u0301': 3,
    }.entries) {
      expect(
        await _engine().execute('\$byteCount[${entry.key}]'),
        '${entry.value}',
      );
    }
    for (final text in ['\ud800', '\udc00', 'a\ud800b', '\ud800\ud800']) {
      expect(bdfdUtf8ByteCount(text), utf8.encode(text).length);
    }
  });
  test('linesCount counts LF including trailing and blank lines', () async {
    for (final entry in {
      'Hello World!': 1,
      'a\nb': 2,
      'a\n': 2,
      '\n': 2,
      '\n\n': 3,
      'a\r\nb': 2,
      'a\rb': 1,
    }.entries) {
      expect(
        await _engine().execute('\$linesCount[${entry.key}]'),
        '${entry.value}',
      );
    }
    await expectLater(
      _engine().execute(r'$linesCount[]'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test('cropText reproduces wiki emoji example', () async {
    expect(
      await _engine().execute(
        r'$cropText[Hello everyone! This message is very cool. 😎 We hope you enjoy coding in BDFD, bye!;50;...]',
      ),
      'Hello everyone! This message is very cool. 😎 We ho...',
    );
  });
  test(
    'cropText adds ending only on truncation and preserves Unicode scalars',
    () async {
      for (final entry in {
        r'$cropText[abc;3;...]': 'abc',
        r'$cropText[abc;100;...]': 'abc',
        r'$cropText[abc;0;...]': '...',
        r'$cropText[;0;...]': '',
        r'$cropText[😀b;1;!]': '😀!',
        r'$cropText[abc;2;]': 'ab',
        r'$cropText[abc;999999999999999999999999999999999999;!]': 'abc',
      }.entries) {
        expect(await _engine().execute(entry.key), entry.value);
      }
      for (final maximum in ['-1', '1.2', '', '0x10']) {
        await expectLater(
          _engine().execute('\$cropText[text;$maximum;!]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'numberSeparator formats documented examples and exact large integers',
    () async {
      for (final entry in {
        r'$numberSeparator[5000]': '5,000',
        r'$numberSeparator[2536000]': '2,536,000',
        r'$numberSeparator[-1234567; ]': '-1 234 567',
        r'$numberSeparator[0]': '0',
        r'$numberSeparator[123;|]': '123',
        r'$numberSeparator[1000;]': '1,000',
        r'$numberSeparator[123456789012345678901234567890;_]':
            '123_456_789_012_345_678_901_234_567_890',
      }.entries) {
        expect(await _engine().execute(entry.key), entry.value);
      }
      for (final value in ['', '1.5', 'NaN', '0x100', '1e3']) {
        await expectLater(
          _engine().execute('\$numberSeparator[$value]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test('isBoolean uses all and only wiki playground exact strings', () async {
    for (final value in bdfdBooleanWords) {
      expect(await _engine().execute('\$isBoolean[$value]'), 'true');
    }
    for (final value in [
      '',
      'TRUE',
      'Yes',
      ' yes ',
      '1',
      '0',
      'enabled',
      'text',
    ]) {
      expect(await _engine().execute('\$isBoolean[$value]'), 'false');
    }
  });
  test(
    'isValidHex matches official playground without inventing six digit rule',
    () async {
      for (final value in [
        '#E67E22',
        'E67E22',
        'abc',
        '#f',
        '1234567890abcdef',
      ]) {
        expect(await _engine().execute('\$isValidHex[$value]'), 'true');
      }
      for (final value in [
        '',
        '#',
        'text',
        ' #abc',
        '#abc ',
        '0xFF',
        '##abc',
      ]) {
        expect(await _engine().execute('\$isValidHex[$value]'), 'false');
      }
    },
  );
  test(
    'isNumber matches official examples and finite JS numeric playground',
    () async {
      for (final value in [
        '52',
        '52.4',
        '-12',
        '+.5',
        '2.',
        '1e3',
        ' 52 ',
        '0xFF',
        '0b10',
        '0o10',
        '-0',
        '1e-999',
      ]) {
        expect(
          await _engine().execute('\$isNumber[$value]'),
          'true',
          reason: value,
        );
      }
      for (final value in [
        '',
        ' ',
        'hello',
        '52a',
        'NaN',
        'Infinity',
        '-Infinity',
        '1e999',
        '+0xFF',
        '0b2',
        '--1',
      ]) {
        expect(
          await _engine().execute('\$isNumber[$value]'),
          'false',
          reason: value,
        );
      }
    },
  );
  test(
    'sort reproduces wiki and sorts floats numerically with exact separator',
    () async {
      for (final entry in {
        r'$sort[8;5;9;1;3;asc;4; - ]': '1 - 3 - 5 - 8',
        r'$sort[1.2;-2;10;0.5;desc;-1;|]': '10|1.2|0.5|-2',
        r'$sort[8;asc;100; / ]': '8',
        r'$sort[8;9;asc;0;|]': '',
        r'$sort[1.0;1;01;asc;-1;|]': '1.0|1|01',
        r'$sort[8;9;asc;999999999999999999999999999;|]': '8|9',
      }.entries) {
        expect(await _engine().execute(entry.key), entry.value);
      }
      for (final source in [
        r'$sort[abc;asc;-1;|]',
        r'$sort[NaN;asc;-1;|]',
        r'$sort[8;up;-1;|]',
        r'$sort[8;asc;-2;|]',
        r'$sort[8;asc;1.5;|]',
        r'$sort[8;asc;-1;]',
      ]) {
        await expectLater(
          _engine().execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test('bad arity preflight runs before prior variable effects', () async {
    for (final source in [
      r'$byteCount',
      r'$byteCount[a;b]',
      r'$linesCount',
      r'$cropText[a;1]',
      r'$cropText[a;1;!;extra]',
      r'$numberSeparator',
      r'$numberSeparator[1;,;extra]',
      r'$isNumber',
      r'$isBoolean[a;b]',
      r'$isValidHex',
      r'$sort[8;asc;-1]',
    ]) {
      final context = BdfdContext();
      await expectLater(
        _engine().execute(r'$var[bad;1]' + source, context: context),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(context.temporaryVariables['bad'], isNull);
    }
  });
  test(
    'sort compares large integers, close fractions and tiny exponent values exactly',
    () async {
      for (final entry in {
        r'$sort[9223372036854775809;9223372036854775808;asc;-1;|]':
            '9223372036854775808|9223372036854775809',
        r'$sort[0.12345678901234567892;0.12345678901234567891;asc;-1;|]':
            '0.12345678901234567891|0.12345678901234567892',
        r'$sort[1e-999;0;-1e-999;asc;-1;|]': '-1e-999|0|1e-999',
        r'$sort[-2.5;-2.51;-0;0;desc;-1;|]': '-0|0|-2.5|-2.51',
        r'$sort[1e2;100;100.0;asc;-1;|]': '1e2|100|100.0',
      }.entries) {
        expect(await _engine().execute(entry.key), entry.value);
      }
    },
  );
  test(
    'unknown functions retain raw text and do not evaluate arguments',
    () async {
      const source = r'$unknown[$byteCount[$var[bad;1]];x]';
      final context = BdfdContext();
      expect(await _engine().execute(source, context: context), source);
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test('returned strings never execute their code-shaped contents', () async {
    final context = BdfdContext(
      temporaryVariables: {'payload': r'$var[bad;1]'},
    );
    expect(
      await _engine().execute(
        r'$cropText[$var[payload];100;]',
        context: context,
      ),
      r'$var[bad;1]',
    );
    expect(context.temporaryVariables['bad'], isNull);
  });
  test('operations check budget during long scans and formatting', () {
    for (final operation in <void Function(void Function())>[
      (check) => bdfdUtf8ByteCount('😀' * 1000, checkBudget: check),
      (check) => bdfdLineCount('a\n' * 1000, checkBudget: check),
      (check) => bdfdCropText('😀' * 1000, 999, '', checkBudget: check),
      (check) => bdfdNumberSeparator(
        BigInt.parse('9' * 1000),
        ',',
        checkBudget: check,
      ),
    ]) {
      var checks = 0;
      expect(
        () => operation(() {
          if (++checks == 3) throw StateError('cancelled');
        }),
        throwsStateError,
      );
      expect(checks, 3);
    }
  });
}
