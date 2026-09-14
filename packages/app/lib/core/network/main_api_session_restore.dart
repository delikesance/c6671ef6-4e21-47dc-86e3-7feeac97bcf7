import 'dart:async';

import 'package:bot_creator/core/analytics/user_identity.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

Future<MainApiSession?>? _activeRestoreFuture;

/// Reads the persisted Main API session from memory/disk without network I/O.
Future<MainApiSession?> loadMainApiSession() {
  return MainApiSettingsStore.loadSession();
}

/// Ensures the persisted Main API session is valid, refreshing when needed.
Future<MainApiSession?> ensureMainApiSession({
  Duration timeout = const Duration(seconds: 6),
  bool force = false,
}) {
  return restoreMainApiSessionIfNeeded(timeout: timeout, force: force);
}

/// Restores a persisted Main API session by refreshing when the access token
/// is expired or close to expiry. Deduplicates concurrent requests.
Future<MainApiSession?> restoreMainApiSessionIfNeeded({
  Duration timeout = const Duration(seconds: 6),
  bool force = false,
}) async {
  if (_activeRestoreFuture != null) {
    return _activeRestoreFuture;
  }

  final completer = Completer<MainApiSession?>();
  _activeRestoreFuture = completer.future;

  try {
    final result = await _restoreMainApiSessionIfNeededInternal(
      timeout: timeout,
      force: force,
    );
    _publishRestoredIdentity(result);
    completer.complete(result);
    return result;
  } catch (error, stack) {
    completer.completeError(error, stack);
    rethrow;
  } finally {
    _activeRestoreFuture = null;
  }
}

/// Publishes the identity of a restored session.
///
/// Restoring is the only moment a user who is already signed in can be named:
/// without this, their reports stay anonymous until their next login, which for
/// a persisted session may never come. Hooked here rather than at one bootstrap
/// call site because every restore path goes through this function — the app
/// bootstrap, the mobile account gate, and the restore that runs before an
/// authenticated request.
///
/// A session without a user id does NOT clear the identity: a refresh response
/// can come back without a user payload, and that is not a sign-out.
void _publishRestoredIdentity(MainApiSession? session) {
  final userId = session?.userId?.trim() ?? '';
  if (userId.isEmpty) {
    return;
  }
  unawaited(UserIdentity.apply(userId));
}

Future<MainApiSession?> _restoreMainApiSessionIfNeededInternal({
  required Duration timeout,
  required bool force,
}) async {
  final config = await MainApiSettingsStore.loadConfig();
  var session = await loadMainApiSession();
  if (session == null) {
    return null;
  }

  if (session.isExpired && (session.refreshToken?.trim().isEmpty ?? true)) {
    await MainApiSettingsStore.clearSession();
    return null;
  }

  final refreshToken = session.refreshToken?.trim() ?? '';
  if (refreshToken.isEmpty) {
    return session.isExpired ? null : session;
  }

  if (!force && !session.isExpired && !session.expiresSoon()) {
    return session;
  }

  final client = MainApiClient(
    baseUrl: config.baseUrl,
    timeout: timeout,
  );
  try {
    final refreshedSession = await client.refreshSession(
      refreshToken: refreshToken,
    );
    final authMethod = session.authMethod ?? refreshedSession.authMethod;
    final merged = refreshedSession.copyWith(authMethod: authMethod);
    await MainApiSettingsStore.saveSession(merged);
    return merged;
  } catch (error) {
    if (error is MainApiClientException &&
        (error.statusCode == 401 || error.statusCode == 403)) {
      await MainApiSettingsStore.clearSession();
      return null;
    }
    if (session.isExpired) {
      return null;
    }
    return session;
  }
}
