// The app gets ANR reports from Crashlytics with no Dart frame at all, so the
// UI-thread operation that froze the app must be identified on the device,
// while it happens. UiStallMonitor is that probe: it is fed by a periodic
// ticker and by frame callbacks, and its emitted breadcrumbs must be exact —
// a missed stall is a support ticket nobody can answer, and a false positive
// buries the real one.
//
// Tick instants are injected so the stall logic is tested without a real
// clock. Marked operations read the real clock, so those cases use a very low
// threshold and a comfortable wait, never a tight one.

import 'package:bot_creator/core/diagnostics/ui_stall_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

/// One event captured from the monitor's sink.
class _Stall {
  _Stall(this.message, this.data);

  final String message;
  final Map<String, Object?> data;
}

/// One operation mark delivered to the monitor's hook.
class _Mark {
  _Mark(this.operation, this.started);

  final String operation;
  final bool started;
}

/// Builds a monitor whose events land in a fresh list, plus that list.
({UiStallMonitor monitor, List<_Stall> stalls}) _buildMonitor({
  Duration stallThreshold = const Duration(milliseconds: 1000),
  Duration frameThreshold = const Duration(milliseconds: 700),
  String screen = 'home',
}) {
  final stalls = <_Stall>[];
  final monitor = UiStallMonitor(
    stallThreshold: stallThreshold,
    frameThreshold: frameThreshold,
    currentScreen: () => screen,
    onStall: (message, data) => stalls.add(_Stall(message, data)),
  );
  return (monitor: monitor, stalls: stalls);
}

/// Builds a monitor that also records the operation marks it observes.
({UiStallMonitor monitor, List<_Mark> marks}) _buildObservedMonitor({
  Duration frameThreshold = const Duration(milliseconds: 700),
}) {
  final marks = <_Mark>[];
  final monitor = UiStallMonitor(
    frameThreshold: frameThreshold,
    currentScreen: () => 'home',
    onStall: (message, data) {},
    onOperationMark: (operation, started) =>
        marks.add(_Mark(operation, started)),
  );
  return (monitor: monitor, marks: marks);
}

void main() {
  group('UiStallMonitor.onTick', () {
    test('the first tick only arms the monitor', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor();

      monitor.onTick(DateTime(2026, 1, 1, 12));

      expect(stalls, isEmpty);
    });

    test('a late tick reports ui_stall with the measured delay', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        screen: 'settings',
      );
      final start = DateTime(2026, 1, 1, 12);

      monitor.onTick(start);
      // 2400 ms later than the previous tick: the isolate spent that time
      // blocked, and nothing else can explain the gap.
      monitor.onTick(start.add(const Duration(milliseconds: 2400)));

      expect(stalls, hasLength(1));
      expect(stalls.single.message, 'ui_stall');
      expect(stalls.single.data['delay_ms'], 2400);
      expect(stalls.single.data['delay_ms'], isA<int>());
      expect(stalls.single.data['screen'], 'settings');
    });

    test('an on-time tick reports nothing', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor();
      final start = DateTime(2026, 1, 1, 12);

      monitor.onTick(start);
      monitor.onTick(start.add(const Duration(milliseconds: 16)));
      monitor.onTick(start.add(const Duration(milliseconds: 32)));

      expect(stalls, isEmpty);
    });

    test('a tick exactly at the threshold reports nothing', () {
      // The contract is strictly greater than stallThreshold: a ticker that
      // drifts by exactly one period is jitter, not a stall.
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        stallThreshold: const Duration(milliseconds: 1000),
      );
      final start = DateTime(2026, 1, 1, 12);

      monitor.onTick(start);
      monitor.onTick(start.add(const Duration(milliseconds: 1000)));

      expect(stalls, isEmpty);
    });

    test('each stall is measured from the previous tick, not the first', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor();
      final start = DateTime(2026, 1, 1, 12);

      monitor.onTick(start);
      monitor.onTick(start.add(const Duration(milliseconds: 1500)));
      monitor.onTick(start.add(const Duration(milliseconds: 1600)));
      monitor.onTick(start.add(const Duration(milliseconds: 5000)));

      expect(stalls, hasLength(2));
      expect(stalls[0].data['delay_ms'], 1500);
      expect(stalls[1].data['delay_ms'], 3400);
    });
  });

  group('UiStallMonitor.onFrame', () {
    test('a frame above the threshold reports long_frame', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
        screen: 'editor',
      );

      monitor.onFrame(
        const Duration(milliseconds: 120),
        const Duration(milliseconds: 80),
      );

      expect(stalls, hasLength(1));
      expect(stalls.single.message, 'long_frame');
      expect(stalls.single.data['build_ms'], 120);
      expect(stalls.single.data['raster_ms'], 80);
      expect(stalls.single.data['screen'], 'editor');
    });

    test('a slow raster alone is enough to report long_frame', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
      );

      monitor.onFrame(
        const Duration(milliseconds: 4),
        const Duration(milliseconds: 300),
      );

      expect(stalls, hasLength(1));
      expect(stalls.single.message, 'long_frame');
    });

    test('a frame at or below the threshold reports nothing', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
      );

      monitor.onFrame(
        const Duration(milliseconds: 50),
        const Duration(milliseconds: 10),
      );
      monitor.onFrame(
        const Duration(milliseconds: 12),
        const Duration(milliseconds: 16),
      );

      expect(stalls, isEmpty);
    });
  });

  group('UiStallMonitor operation marks', () {
    test(
      'an operation over the threshold reports op_slow with merged data',
      () async {
        final (monitor: monitor, stalls: stalls) = _buildMonitor(
          frameThreshold: const Duration(milliseconds: 50),
          screen: 'bot_list',
        );

        monitor.markStart('load_bots', <String, Object?>{'count': 42});
        // Comfortable margin over the 50 ms threshold: this asserts that the
        // overrun is detected, not how precise the wall clock is.
        await Future<void>.delayed(const Duration(milliseconds: 150));
        monitor.markEnd('load_bots');

        expect(stalls, hasLength(1));
        expect(stalls.single.message, 'op_slow');
        expect(stalls.single.data['operation'], 'load_bots');
        expect(stalls.single.data['elapsed_ms'], isA<int>());
        expect(
          stalls.single.data['elapsed_ms']! as int,
          greaterThanOrEqualTo(100),
        );
        expect(stalls.single.data['count'], 42);
        expect(stalls.single.data['screen'], 'bot_list');
      },
    );

    test('an operation under the threshold reports nothing', () async {
      // The threshold is deliberately far above any plausible scheduling
      // hiccup between the two statements, so this cannot flake on a loaded
      // machine the way a 50 ms threshold would.
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(seconds: 30),
      );

      monitor.markStart('fast_operation');
      monitor.markEnd('fast_operation');

      expect(stalls, isEmpty);
    });

    test('markEnd of an unknown operation does not throw', () {
      final (monitor: monitor, stalls: stalls) = _buildMonitor();

      expect(() => monitor.markEnd('never_started'), returnsNormally);
      expect(stalls, isEmpty);
    });

    test('markEnd of an already closed operation does not throw', () async {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
      );

      monitor.markStart('load_bots');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      monitor.markEnd('load_bots');
      expect(() => monitor.markEnd('load_bots'), returnsNormally);

      expect(stalls, hasLength(1));
    });

    test('markStart twice on the same operation restarts cleanly', () async {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
      );

      // A caller that missed its markEnd must not corrupt the next measure:
      // the second markStart replaces the first instead of throwing.
      monitor.markStart('load_bots');
      expect(() => monitor.markStart('load_bots'), returnsNormally);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      monitor.markEnd('load_bots');

      expect(stalls, hasLength(1));
      expect(stalls.single.message, 'op_slow');
      expect(stalls.single.data['operation'], 'load_bots');
    });
  });

  group('UiStallMonitor operation marks', () {
    test(
      'markStart and markEnd notify the observer with the operation name',
      () {
        final (monitor: monitor, marks: marks) = _buildObservedMonitor();

        monitor.markStart('load_command');
        monitor.markEnd('load_command');

        expect(marks, hasLength(2));
        expect(marks[0].operation, 'load_command');
        expect(marks[0].started, isTrue);
        expect(marks[1].operation, 'load_command');
        expect(marks[1].started, isFalse);
      },
    );

    test('a fast operation still notifies the observer', () {
      // The hook is not the stall report: an observer that measures durations
      // needs the fast runs too, or it only ever sees the pathological ones.
      final (monitor: monitor, marks: marks) = _buildObservedMonitor(
        frameThreshold: const Duration(seconds: 30),
      );

      monitor.markStart('save_command');
      monitor.markEnd('save_command');

      expect(marks.map((mark) => mark.started), <bool>[true, false]);
    });

    test('an observer is notified even when nothing is reported as slow', () {
      final (monitor: monitor, marks: marks) = _buildObservedMonitor();

      monitor.markStart('editor_keystroke_analysis');
      monitor.markEnd('editor_keystroke_analysis');

      // Nothing for the observer to filter here: the whitelist that keeps a
      // per-keystroke trace out lives in the observer, not in the monitor.
      expect(marks, hasLength(2));
      expect(marks.first.operation, 'editor_keystroke_analysis');
    });

    test('a stray markEnd notifies the observer without throwing', () {
      final (monitor: monitor, marks: marks) = _buildObservedMonitor();

      expect(() => monitor.markEnd('never_started'), returnsNormally);

      // The observer sees every mark and decides: the monitor does not hide a
      // mark from it just because the monitor has no measurement to close.
      expect(marks, hasLength(1));
      expect(marks.single.started, isFalse);
    });

    test('a monitor without the hook reports the same events', () async {
      // The hook is optional: a monitor built without it keeps emitting its
      // `op_slow` report, unchanged (this is the build main() used before the
      // performance traces were wired in).
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        frameThreshold: const Duration(milliseconds: 50),
      );

      monitor.markStart('load_command', <String, Object?>{'count': 7});
      await Future<void>.delayed(const Duration(milliseconds: 150));
      monitor.markEnd('load_command');

      expect(stalls, hasLength(1));
      expect(stalls.single.message, 'op_slow');
      expect(stalls.single.data['count'], 7);
    });
  });

  group('UiStallMonitor screen attribution', () {
    test('every emitted event carries the current screen', () async {
      final (monitor: monitor, stalls: stalls) = _buildMonitor(
        stallThreshold: const Duration(milliseconds: 1000),
        frameThreshold: const Duration(milliseconds: 50),
        screen: 'dashboard',
      );
      final start = DateTime(2026, 1, 1, 12);

      monitor.onTick(start);
      monitor.onTick(start.add(const Duration(milliseconds: 3000)));
      monitor.onFrame(
        const Duration(milliseconds: 10),
        const Duration(milliseconds: 200),
      );
      monitor.markStart('load_bots');
      await Future<void>.delayed(const Duration(milliseconds: 150));
      monitor.markEnd('load_bots');

      expect(stalls.map((stall) => stall.message), <String>[
        'ui_stall',
        'long_frame',
        'op_slow',
      ]);
      for (final stall in stalls) {
        expect(stall.data['screen'], 'dashboard', reason: stall.message);
      }
    });
  });
}
