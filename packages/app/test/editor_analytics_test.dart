import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/editor_analytics.dart';
import 'package:flutter_test/flutter_test.dart';

class _Event {
  _Event(this.name, this.parameters);

  final String name;
  final Map<String, Object?> parameters;
}

class _Recorder {
  final List<_Event> events = <_Event>[];

  void install() {
    AppAnalytics.debugSetEventObserver(
      (name, parameters) =>
          events.add(_Event(name, parameters ?? const <String, Object?>{})),
    );
  }

  _Event get single => events.single;
}

void main() {
  late _Recorder recorder;

  setUp(() {
    recorder = _Recorder()..install();
  });

  tearDown(() {
    AppAnalytics.debugResetObservers();
  });

  test('duration bucket classification is bounded', () {
    expect(EditorAnalytics.durationBucket(const Duration(seconds: 3)), '<10s');
    expect(
      EditorAnalytics.durationBucket(const Duration(seconds: 15)),
      '10-60s',
    );
    expect(EditorAnalytics.durationBucket(const Duration(minutes: 2)), '1-5m');
    expect(EditorAnalytics.durationBucket(const Duration(minutes: 10)), '5m+');

    for (final duration in [
      Duration.zero,
      const Duration(seconds: 9),
      const Duration(seconds: 30),
      const Duration(minutes: 3),
      const Duration(hours: 1),
    ]) {
      expect(
        EditorAnalytics.durationBucket(duration),
        isIn(EditorAnalytics.durationBuckets),
      );
    }
  });

  test('keystroke bucket classification is bounded', () {
    expect(EditorAnalytics.keystrokeBucket(0), '0');
    expect(EditorAnalytics.keystrokeBucket(5), '1-10');
    expect(EditorAnalytics.keystrokeBucket(25), '11-50');
    expect(EditorAnalytics.keystrokeBucket(100), '51-200');
    expect(EditorAnalytics.keystrokeBucket(500), '201+');

    for (final count in [-1, 0, 1, 10, 50, 150, 1000]) {
      expect(
        EditorAnalytics.keystrokeBucket(count),
        isIn(EditorAnalytics.keystrokeBuckets),
      );
    }
  });

  test('editor_session_end formats parameters cleanly', () async {
    await EditorAnalytics.editorSessionEnd(
      saved: false,
      duration: const Duration(seconds: 45),
      keystrokes: 35,
    );

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'editor_session_end');
    expect(recorder.single.parameters, {
      'saved': 'false',
      'duration_bucket': '10-60s',
      'keystroke_bucket': '11-50',
    });
  });

  test('editor_session_end with saved true', () async {
    await EditorAnalytics.editorSessionEnd(
      saved: true,
      duration: const Duration(minutes: 6),
      keystrokes: 250,
    );

    expect(recorder.events, hasLength(1));
    expect(recorder.single.name, 'editor_session_end');
    expect(recorder.single.parameters, {
      'saved': 'true',
      'duration_bucket': '5m+',
      'keystroke_bucket': '201+',
    });
  });
}
