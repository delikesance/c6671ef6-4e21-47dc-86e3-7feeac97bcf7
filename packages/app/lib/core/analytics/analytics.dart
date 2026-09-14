import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import 'posthog_service.dart';

class AppAnalytics {
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
