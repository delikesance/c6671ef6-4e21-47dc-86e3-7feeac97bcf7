import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:test/test.dart';

void main() {
  test('traces preserve lazy evaluation and selected branch order', () async {
    final events = <BdfdTraceEvent>[];
    final context = BdfdContext(onTrace: events.add);
    final runtime = BdfdRuntime();
    final source =
        r'$if[false]$var[x;ignored]$elseif[true]$var[x;selected]$else$var[x;ignored]$endif$var[x]';
    expect(await runtime.execute(source, context: context), 'selected');
    expect(events.where((e) => e.kind == 'condition').map((e) => e.status), [
      'false',
      'true',
    ]);
    expect(events.where((e) => e.kind == 'branch').single.branch, 1);
    expect(
      events
          .where((e) => e.kind == 'function' && e.status == 'returned')
          .map((e) => e.value),
      ['', 'selected'],
    );
    expect(events.every((e) => e.location.source == source), true);
  });

  test(
    'unknown calls trace only opaque source and never nested functions',
    () async {
      final events = <BdfdTraceEvent>[];
      const source = r'$unknown[$var[x;forbidden]]';
      final context = BdfdContext(onTrace: events.add);
      expect(await BdfdRuntime().execute(source, context: context), source);
      expect(events, hasLength(1));
      expect(events.single.status, 'literal');
      expect(events.single.value, source);
      expect(context.temporaryVariables, isEmpty);
    },
  );

  test('nested argument evaluation runs once and retains call depth', () async {
    final events = <BdfdTraceEvent>[];
    final runtime = BdfdRuntime(
      functions: {
        'twice': BdfdNativeFunction(
          minArguments: 1,
          maxArguments: 1,
          handler: (call) async {
            final first = await call.argument(0);
            return '$first/${await call.argument(0)}';
          },
        ),
      },
    );
    expect(
      await runtime.execute(
        r'$twice[$toUppercase[x]]',
        context: BdfdContext(onTrace: events.add),
      ),
      'X/X',
    );
    expect(
      events.where((e) => e.status == 'start').map((e) => e.functionDepth),
      [1, 2],
    );
    expect(events.where((e) => e.status == 'returned').map((e) => e.value), [
      'X',
      'X/X',
    ]);
    expect(
      events
          .where((e) => e.status == 'returned')
          .every((e) => e.durationMicroseconds! >= 0),
      true,
    );
  });

  test(
    'nested eval reports its own source location and script depth',
    () async {
      final events = <BdfdTraceEvent>[];
      final context = BdfdContext(onTrace: events.add);
      context.temporaryVariables['script'] = '\n\$toUppercase[x]';
      expect(
        await BdfdRuntime().execute(r'$eval[$var[script]]', context: context),
        '\nX',
      );
      final child = events.singleWhere(
        (e) =>
            e.location.functionName == r'$toUppercase' &&
            e.status == 'returned',
      );
      expect(child.scriptDepth, 2);
      expect(child.functionDepth, 2);
      expect(child.location.line, 2);
      expect(child.location.column, 1);
      expect(child.location.source, context.temporaryVariables['script']);
    },
  );

  test(
    'while conditions include the false evaluation that exits the loop',
    () async {
      final events = <BdfdTraceEvent>[];
      final context = BdfdContext(onTrace: events.add);
      expect(
        await BdfdRuntime().execute(
          r'$var[x;0]$while[$var[x]<1]$var[x;1]$endwhile',
          context: context,
        ),
        '',
      );
      expect(
        events.where((e) => e.kind == 'loopCondition').map((e) => e.status),
        ['true', 'false'],
      );
    },
  );

  test('trace observers cannot change results by throwing', () async {
    final context = BdfdContext(
      onTrace: (_) => throw StateError('observer failed'),
    );
    expect(
      await BdfdRuntime().execute(r'$var[x;once]$var[x]', context: context),
      'once',
    );
    expect(context.temporaryVariables['x'], 'once');
  });

  test('native loop traces record iterations and break', () async {
    final events = <BdfdTraceEvent>[];
    expect(
      await BdfdRuntime().execute(
        r'$for[5]$i$break$endfor',
        context: BdfdContext(onTrace: events.add),
      ),
      '0',
    );
    expect(events.where((e) => e.kind == 'loop').map((e) => e.status), [
      'iteration',
      'break',
    ]);
    expect(
      events
          .where(
            (e) => e.kind == 'function' && e.location.functionName == r'$break',
          )
          .last
          .status,
      'break',
    );
  });

  test('sandbox keeps native failure location and catch event', () async {
    final result = await testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'script': '\n\$try\$httpGet[https://example.test]\$catch caught\$endtry',
    });
    expect(result['success'], true, reason: '$result');
    final trace = result['trace'] as List;
    final error = trace.singleWhere(
      (e) => e['type'] == 'bdfdFunction' && e['status'] == 'error',
    );
    expect(error['line'], 2);
    expect(error['function'], r'$httpGet');
    expect(
      trace.any((e) => e['type'] == 'bdfdCatch' && e['status'] == 'handled'),
      true,
    );
    expect(result['responses'][0]['payload']['content'], '\n caught');
  });

  test('sandbox bounds traces and explicitly reports omitted events', () async {
    final result = await testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'script': r'$for[600]$var[x;$i]$endfor',
    });
    expect(result['success'], true, reason: '$result');
    expect(result['trace'], hasLength(1001));
    expect(result['native_trace_dropped'], greaterThan(0));
    expect((result['trace'] as List).last['type'], 'bdfdProgram');
  });
}
