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
}
