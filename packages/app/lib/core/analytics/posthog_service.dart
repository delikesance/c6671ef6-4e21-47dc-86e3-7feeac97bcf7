import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:posthog_flutter/posthog_flutter.dart' as ph;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// PostHog analytics service — used on desktop platforms where Firebase
/// Analytics is unavailable.
class PosthogService {
  static const _apiKey = 'phc_CeXy4mW5wmhxGpknMm7cWUTNmKgqb7HZZNnNcjzY53Qp';
  static const _host = 'https://eu.posthog.com';

  static bool _initialized = false;
  static String? _distinctId;

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

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

  static Future<void> init() async {
    if (_initialized) return;
    if (!_isDesktop) return;

    if (_useHttpFallback) {
      await _getOrCreateDistinctId();
      _initialized = true;
      return;
    }

    try {
      final config = ph.PostHogConfig(_apiKey)
        ..host = _host
        ..captureApplicationLifecycleEvents = true;

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
}
