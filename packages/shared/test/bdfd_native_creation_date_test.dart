import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/go_time_format.dart';
import 'package:bot_creator_shared/services/time_operations.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');
const exampleId = '803569638084313098';

void main() {
  test(
    'deprecated userJoinedDiscord shares the official snowflake contract',
    () async {
      for (final source in [
        r'$userJoinedDiscord[803569638084313098]',
        r'$userJoinedDiscord[803569638084313098;January 2, 2006 at 3:04 PM (MST -07:00)]',
        r'$time[America/St_Johns]$userJoinedDiscord[803569638084313098;15:04 MST -07:00]',
        r'$userJoinedDiscord[18446744073709551615]',
        r'$userJoinedDiscord[803569638084313098;]',
      ]) {
        expect(
          await _engine().execute(source),
          await _engine().execute(
            source.replaceAll('userJoinedDiscord', 'creationDate'),
          ),
        );
      }
      for (final source in [
        r'$userJoinedDiscord',
        r'$userJoinedDiscord[1;2006;extra]',
      ]) {
        final context = BdfdContext();
        await expectLater(
          _engine().execute(r'$var[bad;1]' + source, context: context),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(context.temporaryVariables['bad'], isNull);
      }
      await expectLater(
        _engine().execute(r'$userJoinedDiscord[]'),
        throwsA(isA<BdfdNativeError>()),
      );
      const opaque = r'$unknown[$userJoinedDiscord[$var[bad;1]]]';
      final context = BdfdContext();
      expect(await _engine().execute(opaque, context: context), opaque);
      expect(context.temporaryVariables['bad'], isNull);
      final result = await testCommandInSandbox({
        'script': r'$userJoinedDiscord[803569638084313098]',
        'bdfdBackend': 'native-v1',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '2021-01-26');
      expect(result['effects'], isEmpty);
      expect(result['entity_requests'], isEmpty);
    },
  );
  test('creationDate matches official default and custom examples', () async {
    final engine = _engine();
    expect(
      await engine.execute(r'$creationDate[803569638084313098]'),
      '2021-01-26',
    );
    expect(
      await engine.execute(
        r'$creationDate[803569638084313098;January 2, 2006 at 3:04 PM (MST -07:00)]',
      ),
      'January 26, 2021 at 10:18 AM (UTC +00:00)',
    );
  });
  final expected = {
    '2006': '2021',
    '06': '21',
    '__2': ' 26',
    '002': '026',
    'Jan': 'Jan',
    'January': 'January',
    '01': '01',
    '1': '1',
    'Mon': 'Tue',
    'Monday': 'Tuesday',
    '02': '26',
    '2': '26',
    '_2': '26',
    'PM': 'AM',
    'pm': 'am',
    '05': '51',
    '5': '51',
    '15': '10',
    '3': '10',
    '03': '10',
    '4': '18',
    '04': '18',
    'MST': 'UTC',
    '-0700': '+0000',
    '-07:00': '+00:00',
    '-07': '+00',
    '-070000': '+000000',
    '-07:00:00': '+00:00:00',
    'Z0700': 'Z',
    'Z07:00': 'Z',
    'Z07': 'Z',
    'Z070000': 'Z',
    'Z07:00:00': 'Z',
  };
  for (final entry in expected.entries) {
    test('Go layout field ${entry.key} matches documented value', () async {
      expect(
        await _engine().execute('\$creationDate[$exampleId;${entry.key}]'),
        entry.value,
      );
    });
  }
  test(
    'weekday and month formats are case insensitive per BDFD wiki',
    () async {
      expect(
        await _engine().execute(
          r'$creationDate[803569638084313098;JANUARY MONDAY jan mon mst Pm]',
        ),
        'January Tuesday Jan Tue UTC AM',
      );
    },
  );
  test('Go day and year padding uses calendar day of year', () {
    expect(formatGoTime(DateTime.utc(2024, 1, 3), '_2|__2|002'), ' 3|  3|003');
    expect(
      formatGoTime(DateTime.utc(2024, 12, 31), '002|2006|06'),
      '366|2024|24',
    );
    expect(formatGoTime(DateTime.utc(2025, 12, 31), '002'), '365');
    expect(formatGoTime(DateTime.utc(2024, 1, 3), '_2006'), '_2024');
  });
  test('12-hour clock handles midnight noon and PM separately', () {
    expect(
      formatGoTime(DateTime.utc(2026, 1, 1), '15|3|03|PM|pm'),
      '00|12|12|AM|am',
    );
    expect(
      formatGoTime(DateTime.utc(2026, 1, 1, 12), '15|3|03|PM|pm'),
      '12|12|12|PM|pm',
    );
    expect(
      formatGoTime(DateTime.utc(2026, 1, 1, 23), '15|3|03|PM|pm'),
      '23|11|11|PM|pm',
    );
  });
  test(
    'Go fraction layouts retain fixed zeros and trim optional zeros',
    () async {
      expect(
        await _engine().execute(
          r'$creationDate[803569638084313098;15:04:05.000|05.999|05,000000000]',
        ),
        '10:18:51.321|51.321|51,321000000',
      );
      expect(
        formatGoTime(DateTime.utc(2026), '05.000|05.999|05,999'),
        '00.000|00|00',
      );
      expect(
        formatGoTime(DateTime.utc(2026, 1, 1, 0, 0, 0, 120), '05.999'),
        '00.12',
      );
    },
  );
  test(
    'Snowflake decoder handles all low bits and unsigned 64-bit range',
    () async {
      expect(discordSnowflakeCreation('1'), DateTime.utc(2015));
      expect(discordSnowflakeCreation('4194303'), DateTime.utc(2015));
      expect(
        discordSnowflakeCreation('4194304'),
        DateTime.utc(2015, 1, 1, 0, 0, 0, 1),
      );
      expect(
        await _engine().execute(
          r'$creationDate[18446744073709551615;2006-01-02T15:04:05.000Z07:00]',
        ),
        '2154-05-15T07:35:11.103Z',
      );
      expect(
        await _engine().execute(r'$creationDate[9223372036854775808]'),
        '2084-09-06',
      );
    },
  );
  test(
    'creationDate uses timezone conversion without consulting current clock',
    () async {
      var reads = 0;
      final context = BdfdContext(
        clock: () {
          reads++;
          return DateTime.utc(1900);
        },
      );
      expect(
        await _engine().execute(
          r'$time[Europe/Paris]$creationDate[803569638084313098;15:04 MST -07:00]',
          context: context,
        ),
        '11:18 CET +01:00',
      );
      expect(reads, 0);
      expect(context.time.timezone, 'Europe/Paris');
    },
  );
  test(
    'offset formats handle fractional western offsets and ISO nonzero zones',
    () {
      final state = BdfdTimeState()..setTimezone('America/St_Johns');
      final date = state.inTimezone(discordSnowflakeCreation(exampleId));
      expect(
        formatGoTime(date, '-07|-0700|-07:00|-070000|-07:00:00|Z07:00'),
        '-03|-0330|-03:30|-033000|-03:30:00|-03:30',
      );
    },
  );
  test('Go day of year is unaffected by DST elapsed hours', () {
    final state = BdfdTimeState()..setTimezone('Europe/Paris');
    final local = state.inTimezone(DateTime.utc(2026, 3, 30));
    expect(formatGoTime(local, '002'), '089');
  });
  test(
    'literal layout text empty layout and abbreviation boundaries survive',
    () async {
      expect(
        await _engine().execute(r'$creationDate[803569638084313098;]'),
        '',
      );
      expect(
        formatGoTime(
          discordSnowflakeCreation(exampleId),
          'Janitor Monsoon | YYYY-MM-DD',
        ),
        'Janitor Monsoon | YYYY-MM-DD',
      );
      final context = BdfdContext(
        temporaryVariables: {'layout': r'$var[bad;1]'},
      );
      expect(
        await _engine().execute(
          r'$creationDate[803569638084313098;$var[layout]]',
          context: context,
        ),
        r'$var[bad;1]',
      );
      expect(context.temporaryVariables['bad'], isNull);
    },
  );
  test('malformed and oversized IDs fail with native diagnostics', () async {
    for (final value in [
      '',
      '0',
      '-1',
      '+1',
      '0x123',
      '1.5',
      'NaN',
      '18446744073709551616',
      '<@803569638084313098>',
    ]) {
      await expectLater(
        _engine().execute('\$creationDate[$value]'),
        throwsA(isA<BdfdNativeError>()),
        reason: value,
      );
    }
    expect(
      await _engine().execute(r'$try$creationDate[bad]$catch invalid$endtry'),
      ' invalid',
    );
  });
  test('invalid signature rejects before preceding effects', () async {
    final context = BdfdContext();
    for (final source in [r'$creationDate', r'$creationDate[1;2006;extra]']) {
      await expectLater(
        _engine().execute(r'$var[bad;1]' + source, context: context),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(context.temporaryVariables['bad'], isNull);
    BdfdEngine.validation().prepare(r'$creationDate[803569638084313098;2006]');
  });
  test('unknown wrappers keep IDs and format arguments opaque', () async {
    final context = BdfdContext();
    const source = r'$unknown[$creationDate[$var[bad;1];2006]]';
    expect(await _engine().execute(source, context: context), source);
    expect(context.temporaryVariables['bad'], isNull);
  });
  test('long Go layout checks the execution deadline', () {
    final budget = CommandExecutionBudget(limit: Duration.zero);
    expect(
      () => formatGoTime(
        DateTime.utc(2026),
        List.filled(1000, 'literal').join(),
        checkBudget: budget.check,
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test(
    'sandbox creationDate needs no entity fixtures and makes no request',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$creationDate[803569638084313098]',
        'bdfdBackend': 'native-v1',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '2021-01-26');
      expect(result['effects'], isEmpty);
      expect(result['entity_requests'], isEmpty);
    },
  );
}
