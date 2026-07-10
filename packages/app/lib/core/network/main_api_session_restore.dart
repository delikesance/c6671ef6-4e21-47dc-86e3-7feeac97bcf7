import 'dart:async';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

Future<MainApiSession?>? _activeRestoreFuture;

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
    completer.complete(result);
    return result;
  } catch (error, stack) {
    completer.completeError(error, stack);
    rethrow;
  } finally {
    _activeRestoreFuture = null;
  }
}

Future<MainApiSession?> _restoreMainApiSessionIfNeededInternal({
  required Duration timeout,
  required bool force,
}) async {
  final config = await MainApiSettingsStore.loadConfig();
  var session = await MainApiSettingsStore.loadSession();
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
    await MainApiSettingsStore.saveSession(
      refreshedSession.copyWith(authMethod: authMethod),
    );
    return refreshedSession.copyWith(authMethod: authMethod);
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
