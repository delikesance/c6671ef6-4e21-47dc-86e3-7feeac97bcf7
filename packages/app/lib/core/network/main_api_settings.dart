import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bot_creator/core/analytics/user_identity.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';

const String _defaultMainApiBaseUrlRaw = kDebugMode
    ? 'https://dev.bot-creator.fr/'
    : 'https://api.bot-creator.fr';
String get defaultMainApiBaseUrl =>
    MainApiConfig.normalizeBaseUrl(_defaultMainApiBaseUrlRaw);

class MainApiConfig {
  const MainApiConfig({this.baseUrl = ''});

  final String baseUrl;

  bool get isConfigured => baseUrl.trim().isNotEmpty;

  MainApiConfig copyWith({String? baseUrl}) {
    return MainApiConfig(baseUrl: normalizeBaseUrl(baseUrl ?? this.baseUrl));
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'baseUrl': normalizeBaseUrl(baseUrl),
  };

  factory MainApiConfig.fromJson(Map<String, dynamic> json) {
    return MainApiConfig(
      baseUrl: normalizeBaseUrl(json['baseUrl']?.toString() ?? ''),
    );
  }

  static String normalizeBaseUrl(String raw) {
    var normalized = raw.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

enum MainApiAuthMethod {
  discordOauth('discord_oauth'),
  botToken('bot_token'),
  emailPassword('email_password');

  const MainApiAuthMethod(this.storageValue);

  final String storageValue;

  static MainApiAuthMethod? fromStorage(String? raw) {
    switch (raw?.trim()) {
      case 'discord_oauth':
        return MainApiAuthMethod.discordOauth;
      case 'bot_token':
        return MainApiAuthMethod.botToken;
      case 'email_password':
        return MainApiAuthMethod.emailPassword;
      default:
        return null;
    }
  }
}

class MainApiSession {
  const MainApiSession({
    required this.accessToken,
    required this.expiresAt,
    this.refreshToken,
    this.userId,
    this.username,
    this.scopes = const <String>[],
    this.authMethod,
  });

  final String accessToken;
  final DateTime expiresAt;
  final String? refreshToken;
  final String? userId;
  final String? username;
  final List<String> scopes;
  final MainApiAuthMethod? authMethod;

  bool get isExpired => expiresAt.isBefore(DateTime.now().toUtc());

  bool expiresSoon({Duration threshold = const Duration(minutes: 2)}) {
    return expiresAt.isBefore(DateTime.now().toUtc().add(threshold));
  }

  bool get isManagedAccount =>
      authMethod == MainApiAuthMethod.discordOauth ||
      authMethod == MainApiAuthMethod.emailPassword;

  MainApiSession copyWith({
    String? accessToken,
    DateTime? expiresAt,
    String? refreshToken,
    String? userId,
    String? username,
    List<String>? scopes,
    MainApiAuthMethod? authMethod,
  }) {
    return MainApiSession(
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      scopes: scopes ?? this.scopes,
      authMethod: authMethod ?? this.authMethod,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'accessToken': accessToken,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
    'refreshToken': _normalize(refreshToken),
    'userId': _normalize(userId),
    'username': _normalize(username),
    if (scopes.isNotEmpty) 'scopes': scopes,
    if (authMethod != null) 'authMethod': authMethod!.storageValue,
  };

  factory MainApiSession.fromJson(Map<String, dynamic> json) {
    final rawScopes = json['scopes'];
    return MainApiSession(
      accessToken: (json['accessToken'] ?? '').toString(),
      expiresAt: DateTime.parse((json['expiresAt'] ?? '').toString()).toUtc(),
      refreshToken: _normalize(json['refreshToken']?.toString()),
      userId: _normalize(json['userId']?.toString()),
      username: _normalize(json['username']?.toString()),
      scopes: rawScopes is List
          ? rawScopes
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
          : const <String>[],
      authMethod: MainApiAuthMethod.fromStorage(json['authMethod']?.toString()),
    );
  }
}

class MainApiSettingsStore {
  MainApiSettingsStore._();

  static const String _configKey = 'main_api_config';
  static const String _sessionKey = 'main_api_session';

  static MainApiSession? _memorySession;
  static bool _memorySessionLoaded = false;

  static void invalidateSessionCache() {
    _memorySession = null;
    _memorySessionLoaded = false;
  }

  static Future<MainApiConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = _decodeJsonMap(prefs.getString(_configKey));
    if (json == null) {
      return MainApiConfig(baseUrl: defaultMainApiBaseUrl);
    }
    final config = MainApiConfig.fromJson(json);
    if (!config.isConfigured) {
      return MainApiConfig(baseUrl: defaultMainApiBaseUrl);
    }
    return config;
  }

  static Future<void> saveConfig(MainApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(config.toJson()));
  }

  static Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }

  static Future<MainApiSession?> loadSession() async {
    if (_memorySessionLoaded) {
      return _memorySession;
    }

    String? jsonStr;
    try {
      final secure = await SecureStorageService.instance;
      jsonStr = await secure.read('main_api_session');
    } catch (_) {
      // Secure storage unavailable; fall through
    }

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      jsonStr = prefs.getString(_sessionKey);
    }

    if (jsonStr == null || jsonStr.trim().isEmpty) {
      _memorySession = null;
      _memorySessionLoaded = true;
      return null;
    }

    _memorySession = _sessionFromStoredJson(jsonStr);
    _memorySessionLoaded = true;
    return _memorySession;
  }

  static Future<void> saveSession(MainApiSession session) async {
    final jsonStr = jsonEncode(session.toJson());

    try {
      final secure = await SecureStorageService.instance;
      await secure.write('main_api_session', jsonStr);
    } catch (_) {
      // Secure storage unavailable
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonStr);
    _memorySession = session;
    _memorySessionLoaded = true;
  }

  /// Persists a bot-token exchange only when no managed account session exists.
  static Future<bool> trySaveBotTokenSession(MainApiSession session) async {
    final existing = await loadSession();
    if (existing?.isManagedAccount ?? false) {
      return false;
    }
    await saveSession(
      session.copyWith(authMethod: MainApiAuthMethod.botToken),
    );
    return true;
  }

  static Future<void> clearSession() async {
    try {
      final secure = await SecureStorageService.instance;
      await secure.delete('main_api_session');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _memorySession = null;
    _memorySessionLoaded = true;
    // Sign-out, whether the user asked for it or the session expired: reports
    // must stop being attributed to an account that is no longer signed in.
    // Not awaited — clearing a session must not wait on a diagnostics SDK.
    unawaited(_clearUserIdentity());
  }

  static Future<void> clearAll() async {
    try {
      final secure = await SecureStorageService.instance;
      await secure.delete('main_api_session');
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
    await prefs.remove(_sessionKey);
    _memorySession = null;
    _memorySessionLoaded = true;
    unawaited(_clearUserIdentity());
  }
}

/// Clears the published identity, swallowing nothing: [UserIdentity.apply]
/// already reports its own failures and never throws.
Future<void> _clearUserIdentity() => UserIdentity.apply(null);

MainApiSession? _sessionFromStoredJson(String raw) {
  final json = _decodeJsonMap(raw);
  if (json == null) {
    return null;
  }

  final accessToken = _normalize(json['accessToken']?.toString());
  final expiresAt = _normalize(json['expiresAt']?.toString());
  if (accessToken == null || expiresAt == null) {
    return null;
  }

  return MainApiSession.fromJson(json);
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
