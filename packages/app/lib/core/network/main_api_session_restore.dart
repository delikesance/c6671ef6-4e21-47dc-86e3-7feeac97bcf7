import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';

/// Restores a persisted Main API session by refreshing when the access token
/// is expired or close to expiry.
Future<MainApiSession?> restoreMainApiSessionIfNeeded({
  Duration timeout = const Duration(seconds: 6),
}) async {
  final config = await MainApiSettingsStore.loadConfig();
  var session = await MainApiSettingsStore.loadSession();
  if (session == null) {
    return null;
  }

  if (session.authMethod == MainApiAuthMethod.emailPassword) {
    return session.isExpired ? null : session;
  }

  if (session.isExpired && (session.refreshToken?.trim().isEmpty ?? true)) {
    await MainApiSettingsStore.clearSession();
    return null;
  }

  final refreshToken = session.refreshToken?.trim() ?? '';
  if (refreshToken.isEmpty || (!session.isExpired && !session.expiresSoon())) {
    return session.isExpired ? null : session;
  }

  final client = MainApiClient(
    baseUrl: config.baseUrl,
    timeout: timeout,
  );
  try {
    final refreshedSession = await client.refreshSession(
      refreshToken: refreshToken,
    );
    await MainApiSettingsStore.saveRefreshedSession(refreshedSession);
    return refreshedSession;
  } catch (_) {
    if (session.isExpired) {
      return null;
    }
    return session;
  }
}
