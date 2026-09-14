import 'dart:async';

import 'package:bot_creator/core/analytics/analytics.dart';

/// Captures editor drop-off signals and session metrics.
///
/// Bounded parameters ensure Firebase parameter cardinality remains minimal:
/// `duration_bucket` and `keystroke_bucket` are strictly closed sets.
class EditorAnalytics {
  EditorAnalytics._();

  /// Closed values for the `duration_bucket` parameter.
  static const List<String> durationBuckets = <String>[
    '<10s',
    '10-60s',
    '1-5m',
    '5m+',
  ];

  /// Closed values for the `keystroke_bucket` parameter.
  static const List<String> keystrokeBuckets = <String>[
    '0',
    '1-10',
    '11-50',
    '51-200',
    '201+',
  ];

  /// Reduces a session duration to one of [durationBuckets].
  static String durationBucket(Duration duration) {
    if (duration < const Duration(seconds: 10)) return durationBuckets[0];
    if (duration < const Duration(minutes: 1)) return durationBuckets[1];
    if (duration < const Duration(minutes: 5)) return durationBuckets[2];
    return durationBuckets[3];
  }

  /// Reduces a keystroke count to one of [keystrokeBuckets].
  static String keystrokeBucket(int keystrokes) {
    if (keystrokes <= 0) return keystrokeBuckets[0];
    if (keystrokes <= 10) return keystrokeBuckets[1];
    if (keystrokes <= 50) return keystrokeBuckets[2];
    if (keystrokes <= 200) return keystrokeBuckets[3];
    return keystrokeBuckets[4];
  }

  /// The user closed or exited an editor session.
  ///
  /// [saved] indicates whether the session ended with saving the code (e.g. tapping "Done")
  /// or discarding/exiting without saving.
  static Future<void> editorSessionEnd({
    required bool saved,
    required Duration duration,
    required int keystrokes,
  }) => AppAnalytics.logEvent(
    name: 'editor_session_end',
    parameters: <String, Object>{
      'saved': saved ? 'true' : 'false',
      'duration_bucket': durationBucket(duration),
      'keystroke_bucket': keystrokeBucket(keystrokes),
    },
  );
}
