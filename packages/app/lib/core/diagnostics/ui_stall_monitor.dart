/// Pure-Dart instrumentation for main-isolate (UI thread) stalls.
///
/// The app receives ANR reports from Crashlytics with no Dart frame at all:
/// only a truncated native stack, which says nothing about which UI-thread
/// operation froze the app. This monitor runs on the UI isolate itself and
/// turns what it observes into bounded breadcrumbs — `ui_stall`, `long_frame`
/// and `op_slow` — so the Firebase console can name the culprit instead of
/// showing an opaque native trace.
///
/// The class depends on nothing but the Dart core library: no Flutter import,
/// no `dart:ui`, no system clock. Time always arrives from the caller — a
/// periodic ticker, frame callbacks with measured build/raster durations — or
/// from `DateTime.now()` for operations the app marks manually. That keeps
/// every decision testable without a real clock and lets the class run on any
/// isolate.
class UiStallMonitor {
  UiStallMonitor({
    this.stallThreshold = const Duration(milliseconds: 1000),
    this.frameThreshold = const Duration(milliseconds: 700),
    required this.currentScreen,
    required this.onStall,
    this.onOperationMark,
  });

  /// Shortest lateness between two consecutive ticks that counts as a stall.
  ///
  /// A ticker on the UI isolate fires on a fixed period, so a tick that lands
  /// meaningfully later than expected cannot be explained by scheduling jitter:
  /// the isolate was not running its event loop.
  final Duration stallThreshold;

  /// A frame or a marked operation longer than this is worth reporting.
  final Duration frameThreshold;

  /// Resolves the screen the user is on when an event is emitted.
  final String Function() currentScreen;

  /// Sink for emitted events, typically a Crashlytics breadcrumb.
  final void Function(String message, Map<String, Object?> data) onStall;

  /// Optional observer of the operation marks: called with `started: true`
  /// from [markStart] and `started: false` from [markEnd], for every mark and
  /// whatever the operation takes.
  ///
  /// It exists so a caller can measure the same operations — Firebase
  /// Performance traces — without the monitor having to know about it, and
  /// without the hot paths carrying a second call. A monitor built without it
  /// behaves exactly as before: the hook is a plain function type, so this
  /// class still depends on nothing but the Dart core library.
  ///
  /// Marks are delivered synchronously: the observer must not block, and it is
  /// its own responsibility to defer or drop work.
  final void Function(String operation, bool started)? onOperationMark;

  /// Instant of the last tick, or null before the first one. The first tick
  /// only arms the monitor: it has no earlier instant to measure from.
  DateTime? _previousTick;

  /// Operations opened by `markStart` and not yet closed by `markEnd`.
  final Map<String, _OpenOperation> _openOperations =
      <String, _OpenOperation>{};

  /// Called from a periodic ticker running on the UI isolate. A tick that
  /// arrives later than stallThreshold after the previous one proves the UI
  /// thread was blocked in between.
  void onTick(DateTime now) {
    final previous = _previousTick;
    // Update the reference before emitting: an exception thrown by the sink
    // must not leave the monitor measuring from a stale instant.
    _previousTick = now;
    if (previous == null) {
      return;
    }
    final delay = now.difference(previous);
    if (delay <= stallThreshold) {
      return;
    }
    _emit('ui_stall', <String, Object?>{'delay_ms': delay.inMilliseconds});
  }

  /// Called for every completed frame.
  void onFrame(Duration build, Duration raster) {
    // The longest phase is what decides: a cheap build with an expensive
    // raster (or the reverse) stalls the thread just as badly.
    final longest = build > raster ? build : raster;
    if (longest <= frameThreshold) {
      return;
    }
    _emit('long_frame', <String, Object?>{
      'build_ms': build.inMilliseconds,
      'raster_ms': raster.inMilliseconds,
    });
  }

  /// Marks the start of an operation that may block the UI thread.
  ///
  /// Marking a name that is already open restarts the measurement instead of
  /// piling up: a caller that missed its `markEnd` cannot make the next
  /// measurement wrong. This method never throws.
  void markStart(String operation, [Map<String, Object?>? data]) {
    _openOperations[operation] = _OpenOperation(DateTime.now(), data);
    onOperationMark?.call(operation, true);
  }

  /// Marks the end of that operation. Emits only when it exceeded
  /// frameThreshold.
  ///
  /// An unknown operation is ignored rather than reported: a stray `markEnd`
  /// is a caller bug, not a UI stall, and the monitor runs on the thread it is
  /// supposed to protect. This method never throws.
  void markEnd(String operation) {
    // Every mark reaches the observer, including this one when the operation
    // was never opened: the hook keeps its own bookkeeping and decides.
    onOperationMark?.call(operation, false);
    final open = _openOperations.remove(operation);
    if (open == null) {
      return;
    }
    final elapsed = DateTime.now().difference(open.startedAt);
    if (elapsed <= frameThreshold) {
      return;
    }
    final data = <String, Object?>{
      'operation': operation,
      'elapsed_ms': elapsed.inMilliseconds,
    };
    final extra = open.data;
    if (extra != null) {
      data.addAll(extra);
    }
    _emit('op_slow', data);
  }

  /// Emits one event. The screen is always present: an ANR report is only
  /// actionable when it names what the user was looking at when the UI thread
  /// froze.
  void _emit(String message, Map<String, Object?> data) {
    data['screen'] = currentScreen();
    onStall(message, data);
  }
}

/// An operation opened by `markStart` and not yet closed by `markEnd`.
class _OpenOperation {
  _OpenOperation(this.startedAt, this.data);

  /// Instant the operation started, read from the real clock.
  final DateTime startedAt;

  /// Optional caller data merged into the `op_slow` payload.
  final Map<String, Object?>? data;
}
