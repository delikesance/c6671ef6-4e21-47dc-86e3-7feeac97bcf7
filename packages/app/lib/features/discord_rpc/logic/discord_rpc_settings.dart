import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const String discordRpcFixedApplicationId = '1350824555119382678';

class DiscordRpcConfig {
  const DiscordRpcConfig({
    this.enabled = true,
    String clientId = discordRpcFixedApplicationId,
    String clientSecret = '',
    String brokerUrl = '',
  }) : clientId = discordRpcFixedApplicationId,
       clientSecret = '',
       brokerUrl = '';

  final bool enabled;
  final String clientId;
  final String clientSecret;
  final String brokerUrl;

  bool get hasClientId => true;

  bool get hasClientSecret => false;

  bool get hasBrokerUrl => false;

  DiscordRpcConfig copyWith({
    bool? enabled,
    String? clientId,
    String? clientSecret,
    String? brokerUrl,
  }) {
    return DiscordRpcConfig(
      enabled: enabled ?? this.enabled,
      clientId: clientId ?? this.clientId,
      clientSecret: clientSecret ?? this.clientSecret,
      brokerUrl: brokerUrl ?? this.brokerUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'enabled': enabled,
      'clientId': discordRpcFixedApplicationId,
    };
  }

  factory DiscordRpcConfig.fromJson(Map<String, dynamic> json) {
    return DiscordRpcConfig(enabled: json['enabled'] == true);
  }
}

class DiscordRpcSession {
  const DiscordRpcSession({
    required this.accessToken,
    required this.sessionToken,
    required this.expiresAt,
    this.scopes = const <String>[],
    this.userId,
    this.username,
    this.authorizedAt,
  });

  final String accessToken;
  final String sessionToken;
  final DateTime expiresAt;
  final List<String> scopes;
  final String? userId;
  final String? username;
  final DateTime? authorizedAt;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  bool expiresSoon({Duration threshold = const Duration(minutes: 2)}) {
    return expiresAt.isBefore(DateTime.now().toUtc().add(threshold));
  }

  DiscordRpcSession copyWith({
    String? accessToken,
    String? sessionToken,
    DateTime? expiresAt,
    List<String>? scopes,
    String? userId,
    String? username,
    DateTime? authorizedAt,
  }) {
    return DiscordRpcSession(
      accessToken: accessToken ?? this.accessToken,
      sessionToken: sessionToken ?? this.sessionToken,
      expiresAt: expiresAt ?? this.expiresAt,
      scopes: scopes ?? this.scopes,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      authorizedAt: authorizedAt ?? this.authorizedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'sessionToken': sessionToken,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      if (scopes.isNotEmpty) 'scopes': scopes,
      'userId': ?_normalize(userId),
      'username': ?_normalize(username),
      if (authorizedAt != null)
        'authorizedAt': authorizedAt!.toUtc().toIso8601String(),
    };
  }

  factory DiscordRpcSession.fromJson(Map<String, dynamic> json) {
    final rawScopes = json['scopes'];
    final rawAuthorizedAt = _normalize(json['authorizedAt']?.toString());
    return DiscordRpcSession(
      accessToken: (json['accessToken'] ?? '').toString(),
      sessionToken: (json['sessionToken'] ?? '').toString(),
      expiresAt: DateTime.parse((json['expiresAt'] ?? '').toString()).toUtc(),
      scopes:
          rawScopes is List
              ? rawScopes
                  .map((scope) => scope.toString().trim())
                  .where((scope) => scope.isNotEmpty)
                  .toList(growable: false)
              : const <String>[],
      userId: _normalize(json['userId']?.toString()),
      username: _normalize(json['username']?.toString()),
      authorizedAt:
          rawAuthorizedAt == null
              ? null
              : DateTime.tryParse(rawAuthorizedAt)?.toUtc(),
    );
  }
}

class DiscordRpcSettingsStore {
  DiscordRpcSettingsStore._();

  static const String _configKey = 'discord_rpc_config';
  static const String _sessionKey = 'discord_rpc_session';

  static Future<DiscordRpcConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _decodeJsonMap(prefs.getString(_configKey));
    if (json == null) {
      return const DiscordRpcConfig();
    }
    return DiscordRpcConfig.fromJson(json);
  }

  static Future<void> saveConfig(DiscordRpcConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }

  static Future<DiscordRpcSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _decodeJsonMap(prefs.getString(_sessionKey));
    if (json == null) {
      return null;
    }
    final accessToken = (json['accessToken'] ?? '').toString().trim();
    final sessionToken = (json['sessionToken'] ?? '').toString().trim();
    final expiresAt = (json['expiresAt'] ?? '').toString().trim();
    if (accessToken.isEmpty || sessionToken.isEmpty || expiresAt.isEmpty) {
      return null;
    }
    return DiscordRpcSession.fromJson(json);
  }

  static Future<void> saveSession(DiscordRpcSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await prefs.remove(_sessionKey);
  }
}

Map<String, dynamic>? _decodeJsonMap(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
  } catch (_) {}
  return null;
}

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
