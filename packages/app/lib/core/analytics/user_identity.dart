import 'package:flutter/foundation.dart';

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/analytics/posthog_service.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';

/// The three SDKs the signed-in identity is published to.
///
/// Function fields rather than three direct calls so a unit test can observe
/// the fan-out without a live Firebase app or a PostHog key, and so the
/// "who is the user" decision stays in one readable place.
class UserIdentitySinks {
  const UserIdentitySinks({
    required this.setAnalyticsUserId,
    required this.setCrashlyticsUserIdentifier,
    required this.setPosthogUser,
  });

  /// Firebase Analytics. Null removes the user id.
  final Future<void> Function(String? userId) setAnalyticsUserId;

  /// Crashlytics. An empty string clears the user identifier.
  final Future<void> Function(String identifier) setCrashlyticsUserIdentifier;

  /// PostHog. The Discord id, or null to forget the identified user.
  final Future<void> Function(String? userId) setPosthogUser;

  /// The wired-to-the-SDKs sinks the app runs with.
  static UserIdentitySinks get live => UserIdentitySinks(
    setAnalyticsUserId: AppAnalytics.setUserId,
    setCrashlyticsUserIdentifier: AppDiagnostics.setUserIdentifier,
    setPosthogUser: UserIdentity._setPosthogUser,
  );
}

/// The single entry point that publishes the user's identity to every
/// diagnostics and analytics SDK, and the only place that clears it.
///
/// The identity is the Discord account id (`session.userId`, a Discord
/// snowflake), published as-is: no hash, no salt, no truncation. The point is
/// that a support engineer reading a Crashlytics report or an Analytics
/// audience can go from the report to the Discord account, which any
/// transformation would break.
///
/// Called at the three points where the identity changes — a successful
/// Discord login, a session restored from storage at startup, and sign-out —
/// never from a widget: those paths would each re-implement the platform
/// gating and the erase semantics.
class UserIdentity {
  UserIdentity._();

  static UserIdentitySinks _sinks = UserIdentitySinks.live;

  /// The id currently published, `''` while nobody is signed in.
  ///
  /// Identity is applied on every session restore, and restore runs before
  /// every authenticated request: the comparison keeps that from reaching the
  /// SDKs again for a user who is already published.
  static String _current = '';

  /// Publishes [userId] to every SDK, or clears the identity when it is null
  /// or blank (sign-out).
  ///
  /// Never throws and never rejects: a diagnostics SDK that is missing on the
  /// platform — or not initialised yet — must not break a login, a startup
  /// restore or a logout. A failure is reported through [AppDiagnostics.logInfo]
  /// and does not stop the other two sinks.
  static Future<void> apply(String? userId) async {
    final id = userId?.trim() ?? '';
    if (id == _current) {
      return;
    }
    _current = id;

    final signedOut = id.isEmpty;
    await _attempt(
      'firebase_analytics',
      () => _sinks.setAnalyticsUserId(signedOut ? null : id),
    );
    await _attempt(
      'crashlytics',
      () => _sinks.setCrashlyticsUserIdentifier(id),
    );
    await _attempt(
      'posthog',
      () => _sinks.setPosthogUser(signedOut ? null : id),
    );
  }

  /// Runs one sink call, reporting a failure instead of propagating it.
  static Future<void> _attempt(String sdk, Future<void> Function() call) async {
    try {
      await call();
    } catch (error) {
      try {
        await AppDiagnostics.logInfo(
          'User identity could not be applied to $sdk',
          data: <String, Object?>{'error': error.toString()},
        );
      } catch (_) {
        // Diagnostics is itself unavailable: the caller's flow still has to
        // continue, so the failure is dropped rather than rethrown.
      }
    }
  }

  /// PostHog only knew the anonymous installation id until now.
  static Future<void> _setPosthogUser(String? userId) async {
    // PostHog is initialised during the bootstrap, before any login can
    // happen, so this is normally ready. It is not initialised in unit tests,
    // and calling init() from here would make identity a network operation.
    if (!PosthogService.isInitialized) {
      return;
    }
    if (userId == null || userId.isEmpty) {
      await PosthogService.clearIdentity();
      return;
    }
    await PosthogService.identify(userId: userId);
  }

  /// Replaces the sinks. Test-only: the app always runs on
  /// [UserIdentitySinks.live].
  @visibleForTesting
  static void debugSetSinks(UserIdentitySinks sinks) {
    _sinks = sinks;
  }

  /// Forgets the published identity and restores the live sinks, so one test
  /// cannot leak its fake — or its user — into the next one.
  @visibleForTesting
  static void debugResetForTests() {
    _sinks = UserIdentitySinks.live;
    _current = '';
  }
}
