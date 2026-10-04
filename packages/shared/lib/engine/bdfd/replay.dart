import 'program.dart';
import 'runtime.dart';

/// Bounded native observations in the existing replay transport format.
class BdfdReplayCapture {
  final Stopwatch clock = Stopwatch()..start();
  final frames = <Map<String, dynamic>>[];
  int dropped = 0;

  void record(BdfdTraceEvent event) {
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
