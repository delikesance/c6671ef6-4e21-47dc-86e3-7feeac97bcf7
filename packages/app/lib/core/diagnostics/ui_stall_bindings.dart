import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/diagnostics/ui_stall_monitor.dart';

/// The monitor installed by `main()`, or null while instrumentation is not
/// running (unit tests, tool entry points).
///
/// Hot paths — every command save, every editor keystroke, every startup step —
/// read this instead of taking a monitor parameter: one nullable read is
/// cheaper than threading a dependency through the widgets and stores that only
/// exist to pass it along.
UiStallMonitor? activeUiStallMonitor;

/// Flutter-side adapter for [UiStallMonitor].
///
/// The monitor itself is pure Dart: it takes instants and durations from its
/// caller and knows nothing about frames, timers or app lifecycle. This class
/// is the only place that touches Flutter. It feeds the monitor from a
/// periodic ticker (a tick arriving late proves the UI isolate was not running
/// its event loop) and from [SchedulerBinding.addTimingsCallback] (a frame that
/// took too long is over long before the ANR report is written), and it reports
/// lifecycle transitions on the same sink so the breadcrumb trail says whether
/// the app was in the foreground when the UI thread froze.
class UiStallBindings with WidgetsBindingObserver {
  UiStallBindings({
    required this.monitor,
    this.tickPeriod = const Duration(seconds: 1),
    this.reportLifecycle = true,
    void Function(String message, Map<String, Object?> data)? onEvent,
  }) : onEvent = onEvent ?? _logToDiagnostics;

  /// The monitor fed by this adapter and by the marks placed at hot paths.
  final UiStallMonitor monitor;

  /// Period of the UI-isolate ticker. A tick landing later than the monitor's
  /// `stallThreshold` is the stall signal.
  final Duration tickPeriod;

  /// Whether lifecycle transitions are emitted as `app_lifecycle` events.
  final bool reportLifecycle;

  /// Sink for the events this adapter emits itself (lifecycle today). The
  /// monitor keeps its own sink and never sees lifecycle events.
  final void Function(String message, Map<String, Object?> data) onEvent;

  Timer? _ticker;
  bool _running = false;

  /// Mirrors one event into the Crashlytics breadcrumb trail.
  ///
  /// One call, no new plumbing: [AppDiagnostics.logInfo] already writes the
  /// diagnostics file and the Crashlytics breadcrumb.
  static void _logToDiagnostics(String message, Map<String, Object?> data) {
    unawaited(AppDiagnostics.logInfo(message, data: data));
  }

  /// Starts the ticker, subscribes to frame timings and to app lifecycle.
  ///
  /// Safe to call twice: the second call is a no-op.
  void start() {
    if (_running) {
      return;
    }
    _running = true;
    _ticker = Timer.periodic(tickPeriod, (_) => monitor.onTick(DateTime.now()));
    SchedulerBinding.instance.addTimingsCallback(onFrameTimings);
    WidgetsBinding.instance.addObserver(this);
  }

  /// Unregisters everything [start] installed.
  ///
  /// Idempotent: a second call, or a call before [start], does nothing and
  /// cannot throw — the instrumentation must never be the reason a teardown
  /// path fails.
  void stop() {
    if (!_running) {
      return;
    }
    _running = false;
    _ticker?.cancel();
    _ticker = null;
    SchedulerBinding.instance.removeTimingsCallback(onFrameTimings);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!reportLifecycle) {
      return;
    }
    // Backgrounding is the state an ANR report is hardest to interpret from:
    // `state` names it instead of leaving the reader to guess.
    onEvent('app_lifecycle', <String, Object?>{'state': state.name});
  }

  /// Frame timings arrive batched from the engine.
  ///
  /// Every timing in the batch is already finished when this callback runs, so
  /// there is nothing to filter out on this Flutter version (grep the SDK for
  /// `FrameTiming.isCompleted`: it does not exist here).
  void onFrameTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      monitor.onFrame(timing.buildDuration, timing.rasterDuration);
    }
  }
}
