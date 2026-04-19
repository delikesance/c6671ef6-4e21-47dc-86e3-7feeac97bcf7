import 'dart:convert';

import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:http/http.dart' as http;

class MainApiClientException implements Exception {
  const MainApiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '[$statusCode] $message';
  }
}

class MainApiAuthorizationStart {
  const MainApiAuthorizationStart({
    required this.authorizeUrl,
    required this.state,
  });

  final String authorizeUrl;
  final String state;
}

class MainApiClient implements RemoteRuntimeClient {
  MainApiClient({
    required String baseUrl,
    String? accessToken,
    http.Client? httpClient,
    Duration? timeout,
  }) : _baseUrl = MainApiConfig.normalizeBaseUrl(baseUrl),
       _accessToken = _normalize(accessToken),
       _http = httpClient ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 30);

  final String _baseUrl;
  final String? _accessToken;
  final http.Client _http;
  final Duration _timeout;

  @override
  RemoteRuntimeSource get runtimeSource => RemoteRuntimeSource.manager;

  MainApiClient withAccessToken(String? token) {
    return MainApiClient(
      baseUrl: _baseUrl,
      accessToken: token,
      httpClient: _http,
      timeout: _timeout,
    );
  }

  Uri _uri(String path, {Map<String, String?>? query}) {
    final uri = Uri.parse('$_baseUrl$path');
    if (query == null) return uri;
    final params = <String, String>{};
    for (final entry in query.entries) {
      if (entry.value != null) {
        params[entry.key] = entry.value!;
      }
    }
    return uri.replace(queryParameters: params);
  }

  Map<String, String> _headers({
    bool includeAuth = true,
    String contentType = 'application/json',
  }) {
    final headers = <String, String>{'content-type': contentType};
    if (includeAuth && _accessToken != null) {
      headers['authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String?>? query,
    bool includeAuth = true,
  }) async {
    final response = await _http
        .get(
          _uri(path, query: query),
          headers: _headers(includeAuth: includeAuth),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    final response = await _http
        .post(
          _uri(path),
          headers: _headers(includeAuth: includeAuth),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _parseResponse(response);
  }

  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      json =
          decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : <String, dynamic>{};
    } catch (_) {
      json = <String, dynamic>{};
    }

    if (response.statusCode >= 400) {
      final message =
          (json['error'] ??
                  json['message'] ??
                  response.reasonPhrase ??
                  'Unknown error')
              .toString();
      throw MainApiClientException(message, statusCode: response.statusCode);
    }

    return json;
  }

  @override
  Future<bool> checkHealth() async {
    try {
      final json = await _getFirstAvailable(const <String>[
        '/healthz',
        '/health',
        '/',
      ], includeAuth: false);
      if (json.isEmpty) {
        return true;
      }
      return json['ok'] == true ||
          json['healthy'] == true ||
          json['status'] == 'ok';
    } catch (_) {
      return false;
    }
  }

  Future<MainApiAuthorizationStart> startDiscordAuthorization({
    required String redirectUri,
    required String state,
  }) async {
    final json = await _post('/auth/discord/start', <String, dynamic>{
      'redirectUri': redirectUri,
    }, includeAuth: false);

    final authorizeUrl = _extractString(json, <String>[
      'authorizeUrl',
      'authorizationUrl',
      'authorization_url',
      'url',
    ]);
    final returnedState = _extractString(json, <String>['state']) ?? state;

    if (authorizeUrl == null || authorizeUrl.isEmpty) {
      throw const MainApiClientException(
        'Main API did not return an authorization URL.',
      );
    }

    return MainApiAuthorizationStart(
      authorizeUrl: authorizeUrl,
      state: returnedState,
    );
  }

  Future<MainApiSession> completeDiscordAuthorization({
    required String code,
    required String state,
    required String redirectUri,
  }) async {
    final json = await _post('/auth/discord/exchange', <String, dynamic>{
      'code': code,
      'state': state,
      'redirectUri': redirectUri,
    }, includeAuth: false);
    return _sessionFromAuthPayload(json);
  }

  Future<MainApiSession> exchangeDiscordBotToken({
    required String botToken,
  }) async {
    final json = await _post('/auth/discord/bot/exchange', <String, dynamic>{
      'botToken': botToken,
    }, includeAuth: false);
    return _sessionFromAuthPayload(json);
  }

  Future<MainApiSession> refreshSession({required String refreshToken}) async {
    final json = await _post('/auth/refresh', <String, dynamic>{
      'refreshToken': refreshToken,
    }, includeAuth: false);
    return _sessionFromAuthPayload(json);
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      return await _get('/auth/me', includeAuth: true);
    } on MainApiClientException catch (error) {
      if (!_isNotFound(error)) {
        rethrow;
      }
      // Manager API currently exposes runtime summary but may not expose /auth/me.
      return _get('/gateway/runtime', includeAuth: true);
    }
  }

  @override
  Future<RunnerStatus> getStatus({String? botId}) async {
    if (botId == null || botId.trim().isEmpty) {
      final json = await _getFirstAvailable(const <String>[
        '/gateway/status',
        '/status',
      ]);
      return RunnerStatus.fromJson(json);
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _getFirstAvailable(<String>[
      '/gateway/bots/$encodedBotId/status',
      '/bots/$encodedBotId/status',
    ]);
    final bot = json['bot'];
    if (bot is Map) {
      return RunnerStatus.fromJson(<String, dynamic>{
        'running': (bot['state'] ?? '').toString() == 'running',
        'bots': <dynamic>[bot],
      });
    }
    return const RunnerStatus(running: false, bots: <RunnerBotRuntime>[]);
  }

  @override
  Future<RunnerMetrics> getMetrics({String? botId}) async {
    if (botId == null || botId.trim().isEmpty) {
      final json = await _getFirstAvailable(const <String>[
        '/gateway/metrics',
        '/metrics',
      ]);
      return RunnerMetrics.fromJson(json);
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _getFirstAvailable(<String>[
      '/gateway/bots/$encodedBotId/metrics',
      '/bots/$encodedBotId/metrics',
    ]);
    return RunnerMetrics.fromJson(json);
  }

  @override
  Future<void> syncBot(
    String botId,
    String botName,
    Map<String, dynamic> config,
  ) async {
    await _postFirstAvailable(
      const <String>['/gateway/bots/sync', '/bots/sync'],
      <String, dynamic>{'botId': botId, 'botName': botName, 'config': config},
    );
  }

  Future<void> saveDiscordBotSnapshot({
    required String botToken,
    required Map<String, dynamic> config,
  }) async {
    await _postFirstAvailable(
      const <String>['/gateway/bots/discord/save', '/bots/discord/save'],
      <String, dynamic>{'bot_token': botToken, 'config': config},
    );
  }

  Future<Map<String, dynamic>> verifyBilling({
    required String provider,
    required String receipt,
    String? transactionId,
  }) async {
    return _post('/billing/verify', <String, dynamic>{
      'provider': provider,
      'receipt': receipt,
      if (_normalize(transactionId) case final value?) 'transaction_id': value,
    });
  }

  @override
  Future<void> startBot(String botId, {String? botName}) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _postFirstAvailable(
      <String>[
        '/gateway/bots/$encodedBotId/start',
        '/bots/$encodedBotId/start',
      ],
      <String, dynamic>{
        if (_normalize(botName) case final value?) 'bot_name': value,
        if (_normalize(botName) case final value?) 'botName': value,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> stopBot(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    return await _postFirstAvailable(<String>[
      '/gateway/bots/$encodedBotId/stop',
      '/bots/$encodedBotId/stop',
    ], const <String, dynamic>{});
  }

  @override
  Future<Map<String, dynamic>> getGatewayRuntime() async {
    return _get('/gateway/runtime');
  }

  @override
  Future<Map<String, dynamic>> getBotRuntime(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    return _get('/gateway/bots/$encodedBotId/runtime');
  }

  @override
  Future<Map<String, dynamic>> getRunnerInfo() async {
    return _get('/gateway/runner');
  }

  @override
  Future<List<String>> getLogs({String? botId, int limit = 300}) async {
    final path =
        (botId == null || botId.trim().isEmpty)
            ? '/gateway/logs'
            : '/gateway/logs';
    final json = await _get(
      path,
      query: <String, String?>{'limit': limit.toString()},
    );
    final rawLines = json['lines'];
    if (rawLines is! List) {
      return const <String>[];
    }
    return rawLines.map((entry) => entry.toString()).toList(growable: false);
  }

  Future<Map<String, dynamic>> claimBotAdRuntime({
    required String botId,
    required String placement,
    required String rewardId,
    required String idempotencyKey,
    required DateTime occurredAt,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    return _post(
      '/gateway/bots/$encodedBotId/runtime/claim-ad',
      <String, dynamic>{
        'placement': placement,
        'reward_id': rewardId,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'idempotency_key': idempotencyKey,
      },
    );
  }

  Future<Map<String, dynamic>> getGlobalVariables(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get('/gateway/bots/$encodedBotId/variables/global');
    final raw = json['values'] ?? json['variables'];
    if (raw is! Map) {
      return const <String, dynamic>{};
    }
    return Map<String, dynamic>.from(raw);
  }

  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/global/set',
      <String, dynamic>{'key': key.trim(), 'value': value},
    );
  }

  Future<void> removeGlobalVariable(String botId, String key) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/global/remove',
      <String, dynamic>{'key': key.trim()},
    );
  }

  Future<List<Map<String, dynamic>>> getScopedVariableDefinitions(
    String botId,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get(
      '/gateway/bots/$encodedBotId/variables/scoped-definitions',
    );
    final raw = json['definitions'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  Future<void> setScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/scoped-definitions/set',
      <String, dynamic>{
        'key': key.trim(),
        'scope': scope.trim(),
        'defaultValue': defaultValue,
        'valueType': valueType,
      },
    );
  }

  Future<void> removeScopedVariableDefinition(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/scoped-definitions/remove',
      <String, dynamic>{
        'key': key.trim(),
        if (scope != null && scope.trim().isNotEmpty) 'scope': scope.trim(),
        if (purgeStoredValues) 'purgeStoredValues': true,
      },
    );
  }

  Future<Map<String, dynamic>> listScopedValuesForKey(
    String botId,
    String scope,
    String key,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final normalizedScope = scope.trim();
    final normalizedKey = key.trim();
    final json = await _get(
      '/gateway/bots/$encodedBotId/variables/scoped-values',
      query: <String, String?>{'scope': normalizedScope, 'key': normalizedKey},
    );
    final raw = json['values'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is! List) {
      return const <String, dynamic>{};
    }

    final valuesByContext = <String, dynamic>{};
    for (final entry in raw.whereType<Map>()) {
      final item = Map<String, dynamic>.from(entry);
      final scopeId = (item['scope_id'] ?? '').toString().trim();
      if (scopeId.isEmpty) {
        continue;
      }
      final scopeAuxId = (item['scope_aux_id'] ?? '').toString().trim();
      final contextId =
          normalizedScope == 'guildMember' && scopeAuxId.isNotEmpty
              ? '$scopeId:$scopeAuxId'
              : scopeId;
      valuesByContext[contextId] = item['value'];
    }
    return valuesByContext;
  }

  Future<Map<String, dynamic>> _getFirstAvailable(
    List<String> paths, {
    Map<String, String?>? query,
    bool includeAuth = true,
  }) async {
    MainApiClientException? notFoundError;
    for (final path in paths) {
      try {
        return await _get(path, query: query, includeAuth: includeAuth);
      } on MainApiClientException catch (error) {
        if (_isNotFound(error)) {
          notFoundError = error;
          continue;
        }
        rethrow;
      }
    }
    throw notFoundError ??
        const MainApiClientException('No compatible API route found.');
  }

  Future<Map<String, dynamic>> _postFirstAvailable(
    List<String> paths,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    MainApiClientException? notFoundError;
    for (final path in paths) {
      try {
        return await _post(path, body, includeAuth: includeAuth);
      } on MainApiClientException catch (error) {
        if (_isNotFound(error)) {
          notFoundError = error;
          continue;
        }
        rethrow;
      }
    }
    throw notFoundError ??
        const MainApiClientException('No compatible API route found.');
  }

  MainApiSession _sessionFromAuthPayload(Map<String, dynamic> json) {
    final tokens = _extractMap(json, <String>['tokens']) ?? json;
    final user =
        _extractMap(json, <String>['user']) ??
        _extractMap(tokens, <String>['user']);

    final accessToken =
        _extractString(tokens, <String>[
          'accessToken',
          'access_token',
          'token',
        ]) ??
        _extractString(json, <String>['accessToken', 'access_token', 'token']);
    if (accessToken == null || accessToken.isEmpty) {
      throw const MainApiClientException(
        'Main API did not return an access token.',
      );
    }

    final refreshToken =
        _extractString(tokens, <String>['refreshToken', 'refresh_token']) ??
        _extractString(json, <String>['refreshToken', 'refresh_token']);

    final expiresAtIso =
        _extractString(tokens, <String>['expiresAt', 'expires_at']) ??
        _extractString(json, <String>['expiresAt', 'expires_at']);
    final expiresIn =
        _extractInt(tokens, <String>['expiresIn', 'expires_in']) ??
        _extractInt(json, <String>['expiresIn', 'expires_in']);

    DateTime expiresAt;
    if (expiresAtIso != null && expiresAtIso.isNotEmpty) {
      expiresAt =
          DateTime.tryParse(expiresAtIso)?.toUtc() ??
          DateTime.now().toUtc().add(const Duration(hours: 1));
    } else {
      expiresAt = DateTime.now().toUtc().add(
        Duration(seconds: expiresIn ?? 3600),
      );
    }

    final scopesRaw = tokens['scopes'] ?? json['scopes'];
    final scopes =
        scopesRaw is List
            ? scopesRaw
                .map((item) => item.toString().trim())
                .where((item) => item.isNotEmpty)
                .toList(growable: false)
            : const <String>[];

    return MainApiSession(
      accessToken: accessToken,
      refreshToken: _normalize(refreshToken),
      expiresAt: expiresAt,
      userId:
          _extractString(user, <String>['id', 'userId', 'discordId']) ??
          _extractString(json, <String>[
            'owner_id',
            'ownerId',
            'userId',
            'discordUserId',
          ]),
      username:
          _extractString(user, <String>[
            'username',
            'global_name',
            'name',
            'tag',
          ]) ??
          _extractString(json, <String>['username', 'name']),
      scopes: scopes,
    );
  }
}

bool _isNotFound(MainApiClientException error) {
  return error.statusCode == 404;
}

String? _extractString(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    final normalized = _normalize(value.toString());
    if (normalized != null) return normalized;
  }
  return null;
}

int? _extractInt(Map<String, dynamic>? source, List<String> keys) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value == null) continue;
    if (value is int) return value;
    final parsed = int.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

Map<String, dynamic>? _extractMap(
  Map<String, dynamic>? source,
  List<String> keys,
) {
  if (source == null) return null;
  for (final key in keys) {
    final value = source[key];
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return null;
}

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
