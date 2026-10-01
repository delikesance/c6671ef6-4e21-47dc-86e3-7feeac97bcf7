import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/utils/bdfd_duration_parser.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

void main() {
  test(
    'duration supports compounds, decimals and units without partial parses',
    () {
      for (final sample in [
        ('2m30s', const Duration(seconds: 150)),
        (
          '1h 5 minutes 20 milliseconds',
          const Duration(minutes: 65, milliseconds: 20),
        ),
        ('0.5s', const Duration(milliseconds: 500)),
        ('0.125', const Duration(milliseconds: 125)),
        ('1w', const Duration(days: 7)),
        ('1y', const Duration(days: 365)),
        ('0s', Duration.zero),
      ]) {
        expect(parseBdfdDuration(sample.$1), sample.$2, reason: sample.$1);
      }
      for (final invalid in [
        '',
        '-1s',
        '1bogus',
        '1m trailing',
        '1m 2',
        '1s-2s',
        '999999999999999999999999999999999999999999999999999999999999',
        '${'9' * 400}s',
      ]) {
        expect(parseBdfdDuration(invalid), isNull, reason: invalid);
      }
    },
  );
  test('wait really delays the following action', () async {
    final watch = Stopwatch()..start();
    final result = await testCommandInSandbox({
      'script': r'$wait[30ms]$setVar[after;yes]done',
    });
    expect(result['success'], true, reason: '$result');
    expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(30));
    expect(result['storage_after']['global']['after'], 'yes');
  });
  test('invalid wait stops before the following storage mutation', () async {
    final result = await testCommandInSandbox({
      'script': r'$wait[2bogus]$setVar[after;bad]done',
    });
    expect(result['success'], false);
    expect(result['storage_after']['global'], isEmpty);
  });
  test('long waits are terminated by the sandbox deadline', () async {
    final result = await testCommandInSandbox({
      'script': r'$wait[15m]$setVar[after;bad]',
    }, timeout: const Duration(milliseconds: 200));
    expect(result['success'], false);
    expect(result['terminated'], true);
    expect(result['error'], contains('time limit'));
  });
  test('injected timestamp stays live throughout an execution', () async {
    final vars = <String, String>{};
    injectAlwaysAvailableVariables(vars, botId: 'bot');
    final first = int.parse(
      resolveTemplatePlaceholders('((getTimestampMs))', vars),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final second = int.parse(
      resolveTemplatePlaceholders('((getTimestampMs))', vars),
    );
    expect(second - first, greaterThanOrEqualTo(25));
  });
  test(
    'calendar and timestamp outputs reflect the host clock rather than initial snapshots',
    () {
      final vars = <String, String>{};
      injectAlwaysAvailableVariables(vars, botId: 'bot');
      final readers = <String, String Function(DateTime)>{
        'day': (time) => '${time.day}',
        'month': (time) => '${time.month}',
        'year': (time) => '${time.year}',
        'hour': (time) => '${time.hour}',
        'minute': (time) => '${time.minute}',
        'second': (time) => '${time.second}',
        'date': (time) =>
            '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}',
        'time': (time) =>
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
        'getTimestamp': (time) => '${time.millisecondsSinceEpoch ~/ 1000}',
        'getTimestampMs': (time) => '${time.millisecondsSinceEpoch}',
      };
      for (final entry in readers.entries) {
        vars[entry.key] = 'stale';
        final before = DateTime.now();
        final actual = resolveTemplatePlaceholders('((${entry.key}))', vars);
        final after = DateTime.now();
        if (entry.key == 'getTimestampMs') {
          expect(
            int.parse(actual),
            inInclusiveRange(
              before.millisecondsSinceEpoch,
              after.millisecondsSinceEpoch,
            ),
          );
        } else {
          expect(
            actual,
            anyOf(entry.value(before), entry.value(after)),
            reason: entry.key,
          );
        }
      }
    },
  );
}
