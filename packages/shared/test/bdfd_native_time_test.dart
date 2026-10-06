import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:timezone/data/latest.dart' as data;
import 'package:timezone/timezone.dart' as tz;
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

BdfdEngine _engine() => BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');

void main() {
  test(
    'BDFD timezone does not replace the ambient application timezone',
    () async {
      data.initializeTimeZones();
      final old = tz.local;
      final ambient = tz.getLocation('America/New_York');
      tz.setLocalLocation(ambient);
      try {
        final context = BdfdContext(clock: () => DateTime.utc(2026, 1, 1));
        expect(
          await _engine().execute(
            r'$time[Asia/Kathmandu]$hour:$minute',
            context: context,
          ),
          '5:45',
        );
        expect(tz.local.name, 'America/New_York');
        expect(identical(tz.getLocation('America/New_York'), ambient), true);
      } finally {
        tz.setLocalLocation(old);
      }
    },
  );
  test(
    'UTC default matches official date month and numeric field examples',
    () async {
      final context = BdfdContext(
        clock: () => DateTime.utc(2026, 10, 4, 6, 5, 2),
      );
      expect(
        await _engine().execute(
          r'$date|$day|$hour|$minute|$second|$month|$year',
          context: context,
        ),
        '2026-10-04|4|6|5|2|October|2026',
      );
      expect(context.time.timezone, 'UTC');
    },
  );
  test(
    'fractional timezone rolls calendar across year and month boundary',
    () async {
      final context = BdfdContext(
        clock: () => DateTime.utc(2025, 12, 31, 23, 45),
      );
      expect(
        await _engine().execute(
          r'$time[Asia/Kathmandu]$date|$hour:$minute|$day|$month|$year',
          context: context,
        ),
        '2026-01-01|5:30|1|January|2026',
      );
    },
  );
  for (final entry in {
    '2026-03-29T00:59:00Z': '1:59',
    '2026-03-29T01:00:00Z': '3:0',
    '2026-10-25T00:59:00Z': '2:59',
    '2026-10-25T01:00:00Z': '2:0',
  }.entries) {
    test('Paris DST conversion at ${entry.key}', () async {
      final context = BdfdContext(clock: () => DateTime.parse(entry.key));
      expect(
        await _engine().execute(
          r'$time[Europe/Paris]$hour:$minute',
          context: context,
        ),
        entry.value,
      );
    });
  }
  test('western timezone rolls date back to leap day', () async {
    final context = BdfdContext(clock: () => DateTime.utc(2024, 3, 1, 1));
    expect(
      await _engine().execute(
        r'$time[America/New_York]$date|$month|$day|$hour',
        context: context,
      ),
      '2024-02-29|February|29|20',
    );
  });
  test(
    'private timezone database retains aliases after external initialization',
    () async {
      data.initializeTimeZones();
      final context = BdfdContext(clock: () => DateTime.utc(2026, 7, 1, 12));
      expect(
        await _engine().execute(r'$time[US/Arizona]$hour', context: context),
        '5',
      );
    },
  );
  test(
    'timezone belongs to context and cannot leak between invocations',
    () async {
      final engine = _engine();
      DateTime clock() => DateTime.utc(2026, 7, 1, 12);
      final first = BdfdContext(clock: clock);
      final second = BdfdContext(clock: clock);
      expect(
        await engine.execute(r'$time[Europe/Paris]$hour', context: first),
        '14',
      );
      expect(await engine.execute(r'$hour', context: second), '12');
      expect(await engine.execute(r'$hour', context: first), '14');
    },
  );
  test(
    'explicit eval shares clock and timezone state with its caller',
    () async {
      final context = BdfdContext(
        clock: () => DateTime.utc(2026, 1, 1),
        temporaryVariables: {'code': r'$time[Asia/Kathmandu]$hour:$minute'},
      );
      expect(
        await _engine().execute(
          r'$hour|$eval[$var[code]]|$hour',
          context: context,
        ),
        '0|5:45|5',
      );
      expect(context.time.timezone, 'Asia/Kathmandu');
    },
  );
  test(
    'invalid timezone caught by script leaves previous timezone intact',
    () async {
      final context = BdfdContext(clock: () => DateTime.utc(2026, 1, 1, 1));
      expect(
        await _engine().execute(
          r'$time[Europe/Paris]$try$time[Not/A_Zone]$catch caught$endtry$hour',
          context: context,
        ),
        ' caught2',
      );
      expect(context.time.timezone, 'Europe/Paris');
    },
  );
  test(
    'clock is read live for each function and never during preparation',
    () async {
      var now = DateTime.utc(2026, 12, 31, 23, 59, 59);
      var reads = 0;
      final context = BdfdContext(
        clock: () {
          reads++;
          return now;
        },
      );
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        functions: {
          'advance': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              now = now.add(const Duration(seconds: 1));
              return '';
            },
          ),
        },
      );
      final program = engine.prepare(r'$date|$second|$advance$date|$second');
      expect(reads, 0);
      expect(
        await engine.executeProgram(program, context: context),
        '2026-12-31|59|2027-01-01|0',
      );
      expect(reads, 4);
    },
  );
  test(
    'timestamps support default seconds and explicit s ms ns units',
    () async {
      final context = BdfdContext(
        clock: () => DateTime.fromMicrosecondsSinceEpoch(1234567, isUtc: true),
      );
      expect(
        await _engine().execute(
          r'$getTimestamp|$getTimestamp[s]|$getTimestamp[ms]|$getTimestamp[ns]',
          context: context,
        ),
        '1|1|1234|1234567000',
      );
    },
  );
  test(
    'nanosecond timestamps do not overflow signed 64-bit integers',
    () async {
      final context = BdfdContext(clock: () => DateTime.utc(2500));
      expect(
        await _engine().execute(r'$getTimestamp[ns]', context: context),
        '16725225600000000000',
      );
    },
  );
  test('timezone changes do not alter Unix timestamps', () async {
    final context = BdfdContext(
      clock: () => DateTime.fromMillisecondsSinceEpoch(1234, isUtc: true),
    );
    expect(
      await _engine().execute(
        r'$getTimestamp[ms]|$time[America/New_York]$getTimestamp[ms]',
        context: context,
      ),
      '1234|1234',
    );
  });
  test(
    'negative epoch timestamps floor instead of truncating toward zero',
    () async {
      final context = BdfdContext(
        clock: () => DateTime.fromMicrosecondsSinceEpoch(-1, isUtc: true),
      );
      expect(
        await _engine().execute(
          r'$getTimestamp|$getTimestamp[ms]|$getTimestamp[ns]',
          context: context,
        ),
        '-1|-1|-1000',
      );
    },
  );
  test(
    'unknown wrappers leave timezone clock and nested arguments untouched',
    () async {
      var reads = 0;
      final context = BdfdContext(
        clock: () {
          reads++;
          return DateTime.utc(2026);
        },
      );
      const source = r'$unknown[$time[Asia/Kathmandu];$date;$getTimestamp]';
      expect(await _engine().execute(source, context: context), source);
      expect(reads, 0);
      expect(context.time.timezone, 'UTC');
    },
  );
  test('invalid units and zones fail without reading clock', () async {
    var reads = 0;
    final context = BdfdContext(
      clock: () {
        reads++;
        return DateTime.utc(2026);
      },
    );
    for (final source in [
      r'$time[]',
      r'$time[Not/A_Zone]',
      r'$getTimestamp[]',
      r'$getTimestamp[MS]',
      r'$getTimestamp[minutes]',
    ]) {
      await expectLater(
        _engine().execute(source, context: context),
        throwsA(isA<BdfdNativeError>()),
        reason: source,
      );
    }
    expect(reads, 0);
    expect(context.time.timezone, 'UTC');
  });
  test('invalid arity is rejected before preceding effects', () async {
    final context = BdfdContext();
    for (final source in [
      r'$date[1]',
      r'$day[1]',
      r'$hour[1]',
      r'$minute[1]',
      r'$second[1]',
      r'$month[1]',
      r'$year[1]',
      r'$time',
      r'$time[UTC;Europe/Paris]',
      r'$getTimestamp[s;ms]',
    ]) {
      await expectLater(
        _engine().execute(r'$var[bad;1]' + source, context: context),
        throwsA(isA<BdfdNativeError>()),
        reason: source,
      );
    }
    expect(context.temporaryVariables['bad'], isNull);
    BdfdEngine.validation().prepare(
      r'$time[UTC]$date$day$hour$minute$second$month$year$getTimestamp[ns]',
    );
  });
  test(
    'sandbox date functions run without blocks and retain month labels',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$time[Etc/UTC]$date|$month|$getTimestamp[ms]',
        'bdfdBackend': 'native-v1',
      });
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], isEmpty);
      expect(
        result['results']['output'],
        matches(RegExp(r'^\d{4}-\d{2}-\d{2}\|[A-Z][a-z]+\|\d{13}$')),
      );
    },
  );
}
