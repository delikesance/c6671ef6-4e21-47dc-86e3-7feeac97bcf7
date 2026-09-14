import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:posthog_flutter/posthog_flutter.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// PostHog analytics service — used on all supported platforms (Android, iOS,
/// macOS, Windows, Linux). Uses the posthog_flutter SDK where available
/// (macOS, Android, iOS) with session recording enabled; falls back to HTTP
/// capture on Windows/Linux (no session recording).
class PosthogService {
  static const _apiKey = 'phc_CeXy4mW5wmhxGpknMm7cWUTNmKgqb7HZZNnNcjzY53Qp';
  static const _host = 'https://eu.i.posthog.com';

  static bool _initialized = false;
  static String? _distinctId;

  static bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _useHttpFallback =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  static Future<String> _getOrCreateDistinctId() async {
    if (_distinctId != null) return _distinctId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('posthog_distinct_id');
      if (id == null) {
        id = const Uuid().v4();
        await prefs.setString('posthog_distinct_id', id);
      }
      _distinctId = id;
      return id;
    } catch (_) {
      final id = const Uuid().v4();
      _distinctId = id;
      return id;
    }
  }

  static Future<void> _sendHttpEvent({
    required String event,
    Map<String, Object>? properties,
  }) async {
    try {
      final distinctId = await _getOrCreateDistinctId();
      final url = Uri.parse('https://eu.i.posthog.com/capture/');
      final body = jsonEncode({
        'api_key': _apiKey,
        'event': event,
        'properties': {
          'distinct_id': distinctId,
          ...?properties,
          '\$lib': 'bot_creator_custom_dart',
          '\$lib_version': '1.0.0',
          '\$os': defaultTargetPlatform.name,
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (e) {
      debugPrint('[PosthogService] Failed to send HTTP event: $e');
    }
  }

  static Future<void> _sendHttpIdentify({
    required String userId,
    Map<String, Object>? properties,
  }) async {
    try {
      final distinctId = await _getOrCreateDistinctId();
      final url = Uri.parse('https://eu.i.posthog.com/capture/');
      final body = jsonEncode({
        'api_key': _apiKey,
        'event': '\$identify',
        'properties': {
          'distinct_id': distinctId,
          '\$set': {
            'userId': userId,
            ...?properties,
          },
          '\$lib': 'bot_creator_custom_dart',
          '\$lib_version': '1.0.0',
          '\$os': defaultTargetPlatform.name,
        },
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      });
      await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
    } catch (e) {
      debugPrint('[PosthogService] Failed to send HTTP identify: $e');
    }
  }

  /// Deterministic session recording sampling at ~20% — keeps us under the
  /// 2 500 free monthly recordings by only enabling replays for a subset of
  /// users. Uses the persistent distinct ID so the same user always gets the
  /// same treatment.
  static Future<bool> _shouldRecordSessions() async {
    final id = await _getOrCreateDistinctId();
    final hash = id.hashCode;
    return hash.abs() % 100 < 20;
  }

  static Future<void> init() async {
    if (_initialized) return;
    if (!_isSupportedPlatform) return;

    if (_useHttpFallback) {
      await _getOrCreateDistinctId();
      _initialized = true;
      return;
    }

    try {
      final doRecord = await _shouldRecordSessions();
      final config = ph.PostHogConfig(_apiKey)
        ..host = _host
        ..captureApplicationLifecycleEvents = true
        ..sessionReplay = doRecord
        ..sessionReplayConfig = (ph.PostHogSessionReplayConfig()
          ..maskAllTexts = false
          ..maskAllImages = false);

      await ph.Posthog().setup(config);
      _initialized = true;
    } catch (e) {
      debugPrint('[PosthogService] posthog_flutter init failed: $e');
    }
  }

  static Future<void> screenView({
    required String screenName,
    Map<String, Object>? properties,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return;

    if (_useHttpFallback) {
      await _sendHttpEvent(
        event: '\$screen',
        properties: {
          '\$screen_name': screenName,
          ...?properties,
        },
      );
      return;
    }

    try {
      await ph.Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (_) {}
  }

  static Future<void> capture({
    required String eventName,
    Map<String, Object>? properties,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return;

    if (_useHttpFallback) {
      await _sendHttpEvent(
        event: eventName,
        properties: properties,
      );
      return;
    }

    try {
      await ph.Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (_) {}
  }

  static Future<void> identify({
    required String userId,
    Map<String, Object>? properties,
  }) async {
    if (!_initialized) await init();
    if (!_initialized) return;

    if (_useHttpFallback) {
      await _sendHttpIdentify(
        userId: userId,
        properties: properties,
      );
      return;
    }

    try {
      await ph.Posthog().identify(
        userId: userId,
        userProperties: properties,
      );
    } catch (_) {}
  }

  /// Whether [init] has completed, i.e. whether this service can receive
  /// events on this platform.
  ///
  /// Callers that push identity during a lifecycle transition read this instead
  /// of calling [init] themselves: initialising PostHog from a diagnostics path
  /// would wake the HTTP transport as a side effect of a login, and every unit
  /// test would then issue a real capture request.
  static bool get isInitialized => _initialized;

  /// Sign-out: forgets the identified user.
  ///
  /// The native SDK drops the stored person and rotates its anonymous id; the
  /// HTTP fallback unsets the `userId` person property, so later events are not
  /// attributed to the account that just left.
  static Future<void> clearIdentity() async {
    if (!_initialized) return;

    if (_useHttpFallback) {
      await _sendHttpEvent(
        event: '\$identify',
        properties: <String, Object>{
          '\$unset': <String>['userId'],
        },
      );
      return;
    }

    try {
      await ph.Posthog().reset();
    } catch (_) {}
  }
}
