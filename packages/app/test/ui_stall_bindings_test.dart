// UiStallBindings is the only Flutter-aware part of the stall instrumentation:
// it feeds the pure-Dart UiStallMonitor from a ticker, from frame timings and
// from app lifecycle. A bug here is silent — the monitor simply sees no data
// and the next ANR report is as opaque as the ones this work exists to
// explain — so the tests below check that each source reaches the monitor,
// that a lifecycle transition lands on the injected sink with the right state,
// and that start()/stop() can be called repeatedly without throwing.

import 'package:bot_creator/core/diagnostics/ui_stall_bindings.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_monitor.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// One event captured from a sink.
class _Event {
  _Event(this.message, this.data);

  final String message;
  final Map<String, Object?> data;
}

/// A monitor whose events land in a fresh list, with its threshold low enough
/// that any forwarded frame is reported.
({UiStallMonitor monitor, List<_Event> events}) _monitor({
  Duration frameThreshold = Duration.zero,
  String screen = 'editor',
}) {
  final events = <_Event>[];
  final monitor = UiStallMonitor(
    frameThreshold: frameThreshold,
    currentScreen: () => screen,
    onStall: (message, data) => events.add(_Event(message, data)),
  );
  return (monitor: monitor, events: events);
}

/// A frame that took 10 ms to build and 14 ms to rasterize.
FrameTiming _frame({int buildMicros = 10000, int rasterMicros = 14000}) {
  return FrameTiming(
    vsyncStart: 0,
    buildStart: 1000,
    buildFinish: 1000 + buildMicros,
    rasterStart: 12000,
    rasterFinish: 12000 + rasterMicros,
    rasterFinishWallTime: 27000,
  );
}

/// One call a trace received.
class _TraceCall {
  _TraceCall(this.operation, this.call);

  final String operation;

  /// 'start' or 'stop'.
  final String call;
}

/// A trace that records what it was asked to do.
class _FakeTrace implements StallTrace {
  _FakeTrace(this.operation, this.calls, {this.failOnStart = false});

  final String operation;
  final List<_TraceCall> calls;
  final bool failOnStart;

  @override
  Future<void> start() async {
    calls.add(_TraceCall(operation, 'start'));
    if (failOnStart) {
      throw StateError('cannot start the trace for $operation');
    }
  }

  @override
  Future<void> stop() async {
    calls.add(_TraceCall(operation, 'stop'));
  }
}

/// A bridge that opens [_FakeTrace]s instead of Firebase traces.
({UiStallOperationTraces traces, List<_TraceCall> calls}) _fakeTraces({
  bool failOnStart = false,
}) {
  final calls = <_TraceCall>[];
  final traces = UiStallOperationTraces(
    openTrace: (operation) =>
        _FakeTrace(operation, calls, failOnStart: failOnStart),
  );
  return (traces: traces, calls: calls);
}

void main() {
  // The bindings register a timings callback and a lifecycle observer, both of
  // which need a real binding instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('start() then stop() does not throw and stop() is idempotent', () {
    final bindings = UiStallBindings(
      monitor: _monitor().monitor,
      onEvent: (message, data) {},
    );

    bindings.start();
    bindings.stop();
    // A teardown path that runs twice (or after a failed startup) must not
    // throw: an exception here would mask the real failure.
    bindings.stop();
  });

  test('stop() before start() does nothing', () {
    final bindings = UiStallBindings(
      monitor: _monitor().monitor,
      onEvent: (message, data) {},
    );

    bindings.stop();
  });

  test('a lifecycle transition is reported on the injected sink', () {
    final events = <_Event>[];
    final bindings = UiStallBindings(
      monitor: _monitor().monitor,
      onEvent: (message, data) => events.add(_Event(message, data)),
    );

    bindings.didChangeAppLifecycleState(AppLifecycleState.paused);
    bindings.didChangeAppLifecycleState(AppLifecycleState.resumed);

    expect(events.map((event) => event.message), <String>[
      'app_lifecycle',
      'app_lifecycle',
    ]);
    expect(events[0].data['state'], 'paused');
    expect(events[1].data['state'], 'resumed');
  });

  test('lifecycle reporting can be turned off', () {
    final events = <_Event>[];
    final bindings = UiStallBindings(
      monitor: _monitor().monitor,
      reportLifecycle: false,
      onEvent: (message, data) => events.add(_Event(message, data)),
    );

    bindings.didChangeAppLifecycleState(AppLifecycleState.detached);

    expect(events, isEmpty);
  });

  test('onFrameTimings forwards build and raster durations to the monitor', () {
    final (monitor: monitor, events: events) = _monitor();
    final bindings = UiStallBindings(
      monitor: monitor,
      onEvent: (message, data) {},
    );

    bindings.onFrameTimings(<FrameTiming>[_frame()]);

    expect(events, hasLength(1));
    expect(events.single.message, 'long_frame');
    expect(events.single.data['build_ms'], 10);
    expect(events.single.data['raster_ms'], 14);
    // The screen the monitor reports comes from its own currentScreen callback.
    expect(events.single.data['screen'], 'editor');
  });

  test('onFrameTimings forwards every timing of a batch', () {
    final (monitor: monitor, events: events) = _monitor();
    final bindings = UiStallBindings(
      monitor: monitor,
      onEvent: (message, data) {},
    );

    bindings.onFrameTimings(<FrameTiming>[_frame(), _frame(rasterMicros: 1)]);

    expect(events, hasLength(2));
  });

  test('a frame under the monitor threshold is not reported', () {
    final (monitor: monitor, events: events) = _monitor(
      frameThreshold: const Duration(milliseconds: 700),
    );
    final bindings = UiStallBindings(
      monitor: monitor,
      onEvent: (message, data) {},
    );

    bindings.onFrameTimings(<FrameTiming>[_frame()]);

    expect(events, isEmpty);
  });

  group('operation traces', () {
    test('the whitelist traces the marked hot paths and the warm-up', () {
      expect(isTracedOperation('load_command'), isTrue);
      expect(isTracedOperation('save_command'), isTrue);
      expect(isTracedOperation('list_commands'), isTrue);
      expect(isTracedOperation('editor_open'), isTrue);
      expect(isTracedOperation('startup_firebase_init'), isTrue);
      expect(isTracedOperation('startup_main_api_session_restore'), isTrue);
    });

    test('editor_keystroke_analysis is never traced', () {
      // One keystroke runs this mark. A custom trace per keystroke would
      // exhaust the trace quota and flood the console with noise: the
      // exclusion is by omission from the whitelist, and it is load-bearing.
      expect(isTracedOperation('editor_keystroke_analysis'), isFalse);
      expect(
        tracedStallOperations,
        isNot(contains('editor_keystroke_analysis')),
      );
    });

    test('an operation outside the whitelist is ignored', () {
      final (traces: traces, calls: calls) = _fakeTraces();

      traces.onOperationMark('some_other_operation', true);
      traces.onOperationMark('some_other_operation', false);

      expect(calls, isEmpty);
    });

    test('a traced mark opens one trace and closes it', () {
      final (traces: traces, calls: calls) = _fakeTraces();

      traces.onOperationMark('load_command', true);
      traces.onOperationMark('load_command', false);

      expect(calls.map((call) => call.call), <String>['start', 'stop']);
      expect(calls.map((call) => call.operation), <String>[
        'load_command',
        'load_command',
      ]);
    });

    test('a second start on an open operation is ignored', () {
      // markStart restarts the monitor's own measurement, but a second trace
      // with the same name would be data corruption and a leak.
      final (traces: traces, calls: calls) = _fakeTraces();

      traces.onOperationMark('save_command', true);
      traces.onOperationMark('save_command', true);
      traces.onOperationMark('save_command', false);
      // The first trace was the one closed: a late stop finds nothing open.
      traces.onOperationMark('save_command', false);

      expect(calls.map((call) => call.call), <String>['start', 'stop']);
    });

    test('a stop without an open trace does nothing', () {
      final (traces: traces, calls: calls) = _fakeTraces();

      traces.onOperationMark('list_commands', false);

      expect(calls, isEmpty);
    });

    test('two operations can be traced at the same time', () {
      final (traces: traces, calls: calls) = _fakeTraces();

      traces.onOperationMark('load_command', true);
      traces.onOperationMark('editor_open', true);
      traces.onOperationMark('editor_open', false);
      traces.onOperationMark('load_command', false);

      expect(calls.map((call) => '${call.operation}:${call.call}'), <String>[
        'load_command:start',
        'editor_open:start',
        'editor_open:stop',
        'load_command:stop',
      ]);
    });

    test('a rejected trace future is dropped, not reported', () async {
      final (traces: traces, calls: calls) = _fakeTraces(failOnStart: true);
      // This is the wiring main() installs: the hook is the bridge's own
      // method, called from inside the operation being measured.
      final observed = UiStallMonitor(
        currentScreen: () => 'editor',
        onStall: (message, data) {},
        onOperationMark: traces.onOperationMark,
      );

      observed.markStart('load_command');
      observed.markEnd('load_command');

      // An unhandled async error would fail this test: the trace's start()
      // rejected, and nothing else is allowed to notice.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(calls.map((call) => call.call), <String>['start', 'stop']);
    });

    test('tracing is inert when Firebase Performance is unavailable', () async {
      // The real factory, no injected seam: no Firebase app exists in a unit
      // test, which is also the state of desktop, web and any run before
      // `startup_firebase_init`. The marks must be dropped silently — no
      // exception, and nothing logged on every mark.
      final traces = UiStallOperationTraces();
      final observed = UiStallMonitor(
        currentScreen: () => 'editor',
        onStall: (message, data) {},
        onOperationMark: traces.onOperationMark,
      );

      expect(() => observed.markStart('save_command'), returnsNormally);
      expect(() => observed.markEnd('save_command'), returnsNormally);
      expect(
        () => observed.markStart('startup_firebase_init'),
        returnsNormally,
      );
      expect(() => observed.markEnd('startup_firebase_init'), returnsNormally);

      await Future<void>.delayed(const Duration(milliseconds: 10));
    });
  });
}
