import 'dart:async';

import 'package:firebase_performance/firebase_performance.dart';
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

/// Operations worth a Firebase Performance trace, by exact name.
///
/// Every name here is a mark that already exists on a hot path (see
/// `database.dart`, `command.create.dart`, `main.dart`), so tracing reuses the
/// instrumentation the ANR work installed instead of adding a second one.
///
/// A custom trace is a premium resource: only these are traced, everything
/// else is dropped by [isTracedOperation]. `editor_keystroke_analysis` is
/// deliberately absent — it runs on every keystroke, so a trace per keystroke
/// would exhaust the custom-trace quota and bury the traces that matter under
/// keystroke noise.
const Set<String> tracedStallOperations = <String>{
  'load_command',
  'save_command',
  'list_commands',
  'editor_open',
};

/// Prefix of the warm-up marks (`_runStartupTask` in `main.dart` names every
/// startup step `startup_<step>`), traced as a family.
const String tracedStartupOperationPrefix = 'startup_';

/// Whether [operation] may open a Firebase Performance trace.
bool isTracedOperation(String operation) {
  return tracedStallOperations.contains(operation) ||
      operation.startsWith(tracedStartupOperationPrefix);
}

/// One open trace, as the bridge needs it: start it, stop it.
///
/// A narrow interface rather than the plugin's `Trace`, whose only constructor
/// is private to `firebase_performance`: a test can record the calls without
/// pretending a real trace exists.
abstract class StallTrace {
  Future<void> start();
  Future<void> stop();
}

/// Opens a trace for [operation], or returns null when tracing is unavailable.
typedef OpenStallTrace = StallTrace? Function(String operation);

/// The origin of every custom trace the app reports.
///
/// Fed by `UiStallMonitor.onOperationMark`, so a trace exists for every traced
/// operation whether it was fast or slow — the point is the distribution of
/// real durations, not only the ones that also produced an `op_slow`
/// breadcrumb. Nothing here blocks the UI thread: the marks arrive
/// synchronously, the SDK calls are fired and forgotten.
final UiStallOperationTraces stallOperationTraces = UiStallOperationTraces();

/// Firebase Performance adapter for the monitor's operation marks.
class UiStallOperationTraces {
  UiStallOperationTraces({OpenStallTrace? openTrace})
    : _openTrace = openTrace ?? _openFirebaseTrace;

  /// How a trace is opened. Overridable so tests observe the bridge without a
  /// live Firebase app.
  final OpenStallTrace _openTrace;

  /// Traces opened by a start mark and not yet stopped.
  final Map<String, StallTrace> _open = <String, StallTrace>{};

  /// Sink for `UiStallMonitor.onOperationMark`.
  ///
  /// Never throws and never awaits: it is called from inside the UI-thread
  /// operation it measures, so a slow SDK call must not become part of the
  /// measured duration. Tracing must also never be the reason a save or an
  /// editor open fails.
  void onOperationMark(String operation, bool started) {
    if (!isTracedOperation(operation)) {
      return;
    }

    if (!started) {
      final trace = _open.remove(operation);
      if (trace != null) {
        _fireAndForget(trace.stop());
      }
      return;
    }

    // A markStart for an operation already open would open a second trace with
    // the same name and leave the first one dangling: keep the first.
    if (_open.containsKey(operation)) {
      return;
    }
    final trace = _openTrace(operation);
    if (trace == null) {
      return;
    }
    _open[operation] = trace;
    _fireAndForget(trace.start());
  }

  /// Runs [call] without awaiting it, and drops any failure.
  ///
  /// A rejected [StallTrace] future would otherwise surface as an unhandled
  /// async error in the zone that owns the app: a tracing detail must not be
  /// reported as an app failure, and must not repeat itself on every mark.
  static void _fireAndForget(Future<void> call) {
    unawaited(
      call.then<void>(
        (_) {},
        onError: (Object error, StackTrace stackTrace) {},
      ),
    );
  }
}

/// Opens a real Firebase Performance trace, or null when the plugin cannot be
/// reached (web, desktop, unit tests, Firebase not initialised yet).
///
/// Availability is discovered, not predicted: `FirebasePerformance.instance`
/// throws when the default Firebase app does not exist, which is exactly the
/// condition to swallow. The check is not cached — the first startup marks run
/// before `startup_firebase_init`, so an early failure is not a verdict for the
/// rest of the process.
StallTrace? _openFirebaseTrace(String operation) {
  try {
    return _FirebaseStallTrace(
      FirebasePerformance.instance.newTrace(operation),
    );
  } catch (_) {
    return null;
  }
}

/// One Firebase Performance trace, behind [StallTrace].
class _FirebaseStallTrace implements StallTrace {
  _FirebaseStallTrace(this._trace);

  final Trace _trace;

  @override
  Future<void> start() => _trace.start();

  @override
  Future<void> stop() => _trace.stop();
}

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
