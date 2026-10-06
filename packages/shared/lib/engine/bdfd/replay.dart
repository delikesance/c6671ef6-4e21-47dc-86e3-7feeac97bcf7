import 'program.dart';
import 'runtime.dart';

/// A lightweight copy of [variables] for replay frames: at most 800 entries,
/// values cut at 500 characters (the historical loop's snapshot).
Map<String, String> snapshotReplayVariables(Map<String, String> variables) {
  const maxEntries = 800;
  const maxValueLen = 500;
  final snapshot = <String, String>{};
  for (final entry in variables.entries) {
    if (snapshot.length >= maxEntries) break;
    final value = entry.value;
    snapshot[entry.key] = value.length > maxValueLen
        ? value.substring(0, maxValueLen)
        : value;
  }
  return snapshot;
}

/// Bounded native observations in the existing replay transport format.
///
/// For the calls that run visual actions (`bc_<type>`), a capture given
/// [describe] and [variables] adds the same information the historical loop
/// records per action: `actionKey` (the action's result key), `visualActionType`
/// and, on the frame that ends the call, `variablesBefore` / `variablesAfter`.
/// Without them the format is unchanged.
class BdfdReplayCapture {
  BdfdReplayCapture({this.variables, this.describe});

  /// Variables to snapshot around visual actions.
  final Map<String, String>? variables;

  /// The visual action behind a location of the synthetic program, if any.
  final ({String key, String type})? Function(BdfdLocation location)? describe;

  final Stopwatch clock = Stopwatch()..start();
  final frames = <Map<String, dynamic>>[];
  int dropped = 0;
  final List<Map<String, String>> _before = [];

  void record(BdfdTraceEvent event) {
    final visual =
        event.kind == 'function' &&
            (event.location.functionName?.startsWith('bc_') ?? false)
        ? describe?.call(event.location)
        : null;
    Map<String, String>? before;
    if (visual != null && variables != null) {
      if (event.status == 'start') {
        _before.add(snapshotReplayVariables(variables!));
      } else if (_before.isNotEmpty) {
        before = _before.removeLast();
      }
    }
    if (frames.length >= 1000) {
      dropped++;
      return;
    }
    final duration = (event.durationMicroseconds ?? 0) ~/ 1000;
    final elapsed = clock.elapsedMilliseconds;
    final value = event.value;
    frames.add({
      'actionType': event.location.functionName ?? 'BDFD ${event.kind}',
      'startMs': elapsed,
      'durationMs': duration,
      'backend': 'native-v1',
      'nativeKind': event.kind,
      'nativeStatus': event.status,
      'line': event.location.line,
      'column': event.location.column,
      'scriptDepth': event.scriptDepth,
      'functionDepth': event.functionDepth,
      if (visual != null) 'actionKey': visual.key,
      if (visual != null) 'visualActionType': visual.type,
      'variablesBefore': ?before,
      if (before != null) 'variablesAfter': snapshotReplayVariables(variables!),
      if (event.branch != null) 'branch': event.branch,
      if (event.iteration != null) 'loopIteration': event.iteration,
      if (value != null)
        'result': value.length > 500 ? value.substring(0, 500) : value,
      if (value != null && value.length > 500) 'valueTruncated': true,
    });
  }

  void finish(Object? error, {String? output, bool includeProgram = false}) {
    clock.stop();
    if (includeProgram && error == null) {
      frames.add({
        'actionType': 'BDFD',
        'backend': 'native-v1',
        'nativeStatus': 'completed',
        'startMs': clock.elapsedMilliseconds,
        'durationMs': 0,
        if (output != null)
          'result': output.length > 500 ? output.substring(0, 500) : output,
        if (output != null && output.length > 500) 'valueTruncated': true,
      });
    }
    if (error != null) {
      frames.add({
        'actionType': 'BDFD',
        'backend': 'native-v1',
        'nativeStatus': 'error',
        'startMs': clock.elapsedMilliseconds,
        'durationMs': 0,
        'result': error.toString().length > 500
            ? error.toString().substring(0, 500)
            : error.toString(),
        if (error is BdfdNativeError) 'line': error.location.line,
        if (error is BdfdNativeError) 'column': error.location.column,
      });
    }
    if (dropped > 0) {
      frames.add({
        'actionType': 'BDFD',
        'backend': 'native-v1',
        'nativeStatus': 'truncated',
        'startMs': clock.elapsedMilliseconds,
        'durationMs': 0,
        'eventsDropped': dropped,
      });
    }
  }
}
