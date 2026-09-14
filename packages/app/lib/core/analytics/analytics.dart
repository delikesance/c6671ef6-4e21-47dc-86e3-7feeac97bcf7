import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'posthog_service.dart';

class AppAnalytics {
  /// Observes the events and user properties leaving the app.
  ///
  /// Function fields rather than direct reads, so a unit test can assert the
  /// shipped taxonomy — event names, parameters and their values — without a
  /// live Firebase app or a PostHog key. The recording happens before the
  /// platform is consulted: what is observed is the taxonomy, on every
  /// platform, including the ones with no analytics backend.
  static void Function(String name, Map<String, Object>? parameters)?
  _eventObserver;
  static void Function(String name, String value)? _userPropertyObserver;

  /// Records the events sent through [logEvent]. Test-only.
  @visibleForTesting
  static void debugSetEventObserver(
    void Function(String name, Map<String, Object>? parameters)? observer,
  ) {
    _eventObserver = observer;
  }

  /// Records the user properties sent through [setUserProperties]. Test-only.
  @visibleForTesting
  static void debugSetUserPropertyObserver(
    void Function(String name, String value)? observer,
  ) {
    _userPropertyObserver = observer;
  }

  /// Drops both observers, so one test cannot observe another one's traffic.
  @visibleForTesting
  static void debugResetObservers() {
    _eventObserver = null;
    _userPropertyObserver = null;
  }

  static bool get _isDesktop =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.macOS ||
          defaultTargetPlatform == TargetPlatform.linux);

  static bool get _isSupported {
    if (kIsWeb) return true;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return false;
      default:
        return false;
    }
  }

  static Future<void> setCollectionEnabled(bool enabled) async {
    if (_isSupported) {
      try {
        await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(enabled);
      } catch (_) {}
    }
  }

  static Future<void> logAppOpen() async {
    if (_isSupported) {
      try {
        await FirebaseAnalytics.instance.logAppOpen();
      } catch (_) {}
    }
    if (_isDesktop) {
      await PosthogService.capture(eventName: 'app_open');
    }
  }

  /// Attributes subsequent Analytics events to one user. A null [userId]
  /// removes it (sign-out).
  ///
  /// The value is the Discord account id, passed through untouched: support
  /// has to be able to find the person from the console, which a hash or a
  /// truncation would prevent.
  static Future<void> setUserId(String? userId) async {
    if (_isSupported) {
      try {
        await FirebaseAnalytics.instance.setUserId(id: userId);
      } catch (_) {}
    }
  }

  /// Publishes the dimensions that segment the activation funnel as user
  /// properties, one per dimension.
  ///
  /// Every value comes from a closed list — a bucket or an enumerated label,
  /// never an id, a duration or a free-form string: user properties cannot be
  /// purged from the console once a high-cardinality value reaches them.
  /// `AppUserProperties.refresh` is the only caller, and it is called once at
  /// startup.
  static Future<void> setUserProperties({
    String? platform,
    String? premiumTier,
    String? botCountBucket,
    String? locale,
  }) async {
    final values = <String, String>{
      'platform': ?platform,
      'premium_tier': ?premiumTier,
      'bot_count_bucket': ?botCountBucket,
      'locale': ?locale,
    };

    for (final entry in values.entries) {
      _userPropertyObserver?.call(entry.key, entry.value);
      if (_isSupported) {
        try {
          await FirebaseAnalytics.instance.setUserProperty(
            name: entry.key,
            value: entry.value,
          );
        } catch (_) {}
      }
    }
  }

  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) async {
    // Published before anything is sent: the screen name must already be
    // current when an event fired in the same frame reads it back.
    AppDiagnostics.currentScreen = screenName;
    if (_isSupported) {
      try {
        await FirebaseAnalytics.instance.logScreenView(
          screenName: screenName,
          screenClass: screenClass,
          parameters: parameters,
        );
      } catch (_) {}
    }
    if (_isDesktop) {
      await PosthogService.screenView(
        screenName: screenName,
        properties: parameters,
      );
    }
  }

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    _eventObserver?.call(name, parameters);
    if (_isSupported) {
      try {
        await FirebaseAnalytics.instance.logEvent(
          name: name,
          parameters: parameters,
        );
      } catch (_) {}
    }
    if (_isDesktop) {
      await PosthogService.capture(eventName: name, properties: parameters);
    }
  }

  static Future<void> logAdEvent({
    required String action,
    required String format,
    required String placement,
    Map<String, Object>? parameters,
  }) async {
    final merged = <String, Object>{
      'ad_action': action,
      'ad_format': format,
      'ad_placement': placement,
      ...?parameters,
    };
    await logEvent(name: 'ad_event', parameters: merged);
  }
}
