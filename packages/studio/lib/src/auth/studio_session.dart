import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Formule du compte. Le Studio exige toujours une connexion : il n'y a donc
/// pas de niveau « anonyme ».
enum StudioPlan { free, premium }

class StudioSession {
  const StudioSession({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.userId,
    this.username,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final String? userId;
  final String? username;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  bool get expiresSoon => expiresAt.isBefore(
    DateTime.now().toUtc().add(const Duration(minutes: 2)),
  );

  /// Même lecture tolérante que `MainApiClient._sessionFromAuthPayload`.
  factory StudioSession.fromAuthPayload(Map<String, dynamic> json) {
    Map<String, dynamic>? map(Map<String, dynamic>? m, String k) {
      final v = m?[k];
      return v is Map ? Map<String, dynamic>.from(v) : null;
    }

    String? str(Map<String, dynamic>? m, List<String> keys) {
      if (m == null) return null;
      for (final k in keys) {
        final v = m[k]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return null;
    }

    final tokens = map(json, 'tokens') ?? json;
    final user = map(json, 'user') ?? map(tokens, 'user');
    final access =
        str(tokens, const ['accessToken', 'access_token', 'token']) ??
        str(json, const ['accessToken', 'access_token', 'token']);
    if (access == null) {
      throw const FormatException('No access token in auth response.');
    }
    final refresh =
        str(tokens, const ['refreshToken', 'refresh_token']) ??
        str(json, const ['refreshToken', 'refresh_token']);
    final expiresIso =
        str(tokens, const ['expiresAt', 'expires_at']) ??
        str(json, const ['expiresAt', 'expires_at']);
    final expiresIn = int.tryParse(
      str(tokens, const ['expiresIn', 'expires_in']) ??
          str(json, const ['expiresIn', 'expires_in']) ??
          '',
    );
    final expiresAt =
        (expiresIso == null ? null : DateTime.tryParse(expiresIso)?.toUtc()) ??
        DateTime.now().toUtc().add(Duration(seconds: expiresIn ?? 3600));
    return StudioSession(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: expiresAt,
      userId:
          str(user, const ['id', 'userId', 'discordId']) ??
          str(json, const ['owner_id', 'ownerId', 'userId']),
      username:
          str(user, const [
            'username',
            'global_name',
            'name',
            'display_name',
          ]) ??
          str(json, const ['username', 'name', 'global_name']),
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'refreshToken': refreshToken,
    'userId': userId,
    'username': username,
  };

  factory StudioSession.fromJson(Map<String, dynamic> json) => StudioSession(
    accessToken: json['accessToken'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    refreshToken: json['refreshToken'] as String?,
    userId: json['userId'] as String?,
    username: json['username'] as String?,
  );
}

/// Persistance de la session dans le navigateur (`localStorage`).
class SessionStore {
  static const _key = 'studio_session_v1';

  Future<StudioSession?> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return null;
      return StudioSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(StudioSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(session.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
