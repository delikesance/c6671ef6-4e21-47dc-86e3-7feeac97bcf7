import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  /// Internal cache of the last synced configuration hash per bot.
  /// Key format: "${baseUrl}:${botId}"
  static final Map<String, String> _lastSyncedHashes = <String, String>{};

  /// Internal cache of the last saved snapshot hash per bot token.
  /// Key format: "${baseUrl}:snapshot:${botToken}"
  static final Map<String, String> _lastSavedSnapshots = <String, String>{};

  /// Maximum number of entries in each hash cache before LRU eviction.
  static const int _maxHashCacheEntries = 100;

  static const String _lastSyncedHashesKey = 'main_api_last_synced_hashes';
  static const String _lastSavedSnapshotsKey = 'main_api_last_saved_snapshots';

  /// Initializes the client by loading persisted hashes from disk.
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final syncedHashesJson = prefs.getString(_lastSyncedHashesKey);
      if (syncedHashesJson != null) {
        final decoded = jsonDecode(syncedHashesJson);
        if (decoded is Map) {
          _lastSyncedHashes.addAll(decoded.cast<String, String>());
        }
      }

      final snapshotHashesJson = prefs.getString(_lastSavedSnapshotsKey);
      if (snapshotHashesJson != null) {
        final decoded = jsonDecode(snapshotHashesJson);
        if (decoded is Map) {
          _lastSavedSnapshots.addAll(decoded.cast<String, String>());
        }
      }
      
      debugPrint('[MainApiClient] Initialized with ${_lastSyncedHashes.length} synced hashes and ${_lastSavedSnapshots.length} snapshot hashes.');
    } catch (e) {
      debugPrint('[MainApiClient] Failed to load persisted hashes: $e');
    }
  }

  static Future<void> _persistHashes(String key, Map<String, String> cache) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(cache));
    } catch (e) {
      debugPrint('[MainApiClient] Failed to persist hashes for $key: $e');
    }
  }

  /// TTL cache for health check results.
  static final Map<String, _CachedHealth> _healthCache =
      <String, _CachedHealth>{};
  static const Duration _healthCacheTtl = Duration(seconds: 30);

  /// Circuit breaker state per base URL.
  static final Map<String, _CircuitState> _circuits = <String, _CircuitState>{};
  static const int _circuitMaxFailures = 3;
  static const Duration _circuitCooldown = Duration(seconds: 60);

  /// Retry configuration.
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 1);
  static const double _retryBackoffMultiplier = 2.0;

  /// Cleans up the hash caches using LRU eviction when they exceed the max size.
  static void _evictOldestHashEntries(Map<String, String> cache) {
    if (cache.length <= _maxHashCacheEntries) return;
    final keysToRemove =
        cache.keys.take(cache.length - _maxHashCacheEntries).toList();
    for (final key in keysToRemove) {
      cache.remove(key);
    }
  }

  /// Checks if the circuit is open (too many failures) for a given base URL.
  static bool _isCircuitOpen(String baseUrl) {
    final state = _circuits[baseUrl];
    if (state == null) return false;
    if (state.failureCount < _circuitMaxFailures) return false;
    final elapsed = DateTime.now().difference(state.firstFailure);
    if (elapsed >= _circuitCooldown) {
      _circuits.remove(baseUrl);
      return false;
    }
    return true;
  }

  /// Records a failure for circuit breaker tracking.
  static void _recordCircuitFailure(String baseUrl) {
    final now = DateTime.now();
    final existing = _circuits[baseUrl];
    if (existing != null &&
        now.difference(existing.firstFailure) < _circuitCooldown) {
      existing.failureCount++;
    } else {
      _circuits[baseUrl] = _CircuitState(firstFailure: now, failureCount: 1);
    }
  }

  /// Records a success, resetting the circuit breaker.
  static void _recordCircuitSuccess(String baseUrl) {
    _circuits.remove(baseUrl);
  }

  /// Returns a cached health check result if still valid, null otherwise.
  static bool? _getCachedHealth(String baseUrl) {
    final cached = _healthCache[baseUrl];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.timestamp) >= _healthCacheTtl) {
      _healthCache.remove(baseUrl);
      return null;
    }
    return cached.healthy;
  }

  /// Stores a health check result in the TTL cache.
  static void _setCachedHealth(String baseUrl, bool healthy) {
    _healthCache[baseUrl] = _CachedHealth(
      healthy: healthy,
      timestamp: DateTime.now(),
    );
  }

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
  String? _accessToken;
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
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    final uri = _uri(path, query: query);
    appendBotDebugLog('[MainApiClient] GET $uri');

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .get(uri, headers: _headers(includeAuth: includeAuth))
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] GET $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) && includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error) || attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] GET $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] GET $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    _recordCircuitFailure(_baseUrl);
    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    final uri = _uri(path);
    final encodedBody = jsonEncode(body);
    appendBotDebugLog('[MainApiClient] POST $uri body=$encodedBody');

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .post(
              uri,
              headers: _headers(includeAuth: includeAuth),
              body: encodedBody,
            )
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] POST $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) && includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error) || attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] POST $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] POST $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    _recordCircuitFailure(_baseUrl);
    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  Future<Map<String, dynamic>> _delete(
    String path, {
    Map<String, String?>? query,
    bool includeAuth = true,
  }) async {
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    final uri = _uri(path, query: query);
    appendBotDebugLog('[MainApiClient] DELETE $uri');

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .delete(uri, headers: _headers(includeAuth: includeAuth))
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] DELETE $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) && includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error) || attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] DELETE $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] DELETE $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    _recordCircuitFailure(_baseUrl);
    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
  }) async {
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    final uri = _uri(path);
    final encodedBody = jsonEncode(body);
    appendBotDebugLog('[MainApiClient] PUT $uri');

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .put(uri, headers: _headers(includeAuth: includeAuth), body: encodedBody)
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] PUT $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) && includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error) || attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _baseRetryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    _recordCircuitFailure(_baseUrl);
    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  /// Returns the parsed response body as a Map.
  /// If the response is a List, it is wrapped as {'data': list}.
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        json = Map<String, dynamic>.from(decoded);
      } else if (decoded is List) {
        json = <String, dynamic>{'data': decoded};
      } else {
        json = <String, dynamic>{};
      }
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

  Future<String?> _tryRefreshSession() async {
    try {
      final session = await MainApiSettingsStore.loadSession();
      final refreshToken = session?.refreshToken?.trim() ?? '';
      if (refreshToken.isEmpty) {
        return null;
      }
      debugPrint('[MainApiClient] Access token expired or invalid (401/403). Attempting to refresh session...');
      final publicClient = MainApiClient(baseUrl: _baseUrl, httpClient: _http, timeout: _timeout);
      final newSession = await publicClient.refreshSession(refreshToken: refreshToken);
      await MainApiSettingsStore.saveSession(newSession);
      debugPrint('[MainApiClient] Session refreshed successfully.');
      return newSession.accessToken;
    } catch (e) {
      debugPrint('[MainApiClient] Failed to refresh session: $e');
      if (e is MainApiClientException && (e.statusCode == 401 || e.statusCode == 403)) {
        debugPrint('[MainApiClient] Refresh token rejected. Clearing session.');
        await MainApiSettingsStore.clearSession();
      }
      return null;
    }
  }

  @override
  Future<bool> checkHealth() async {
    final cached = _getCachedHealth(_baseUrl);
    if (cached != null) {
      return cached;
    }

    try {
      final json = await _getFirstAvailable(const <String>[
        '/healthz',
        '/health',
        '/',
      ], includeAuth: false);
      final healthy =
          json.isEmpty ||
          json['ok'] == true ||
          json['healthy'] == true ||
          json['status'] == 'ok';
      _setCachedHealth(_baseUrl, healthy);
      return healthy;
    } catch (_) {
      _setCachedHealth(_baseUrl, false);
      return false;
    }
  }

  Future<MainApiAuthorizationStart> startDiscordAuthorization({
    required String redirectUri,
    required String state,
  }) async {
    final json = await _post('/auth/discord/start', <String, dynamic>{
      'redirect_uri': redirectUri,
      'state': state,
    }, includeAuth: false);

    final authorizeUrl = _extractString(json, <String>[
      'authorization_url',
      'authorizationUrl',
      'authorizeUrl',
      'url',
    ]);
    final returnedState = _extractString(json, <String>['state']) ?? state;

    if (authorizeUrl == null || authorizeUrl.isEmpty) {
      throw const MainApiClientException(
        'Bot Creator Server did not return an authorization URL.',
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
      'redirect_uri': redirectUri,
    }, includeAuth: false);
    return _sessionFromAuthPayload(json);
  }

  Future<MainApiSession> exchangeDiscordBotToken({
    required String botToken,
  }) async {
    final json = await _post('/auth/discord/bot/exchange', <String, dynamic>{
      'bot_token': botToken,
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
  Future<List<Map<String, dynamic>>> listBots() async {
    final json = await _get('/gateway/bots');
    final raw = json['bots'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  Future<void> deleteBot(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _delete('/gateway/bots/$encodedBotId');
  }

  @override
  Future<RunnerStatus> getStatus({String? botId}) async {
    if (botId == null || botId.trim().isEmpty) {
      final json = await _get('/gateway/runtime');
      var isRunning = false;
      for (final value in json.values) {
        if (value is Map) {
          final running = value['bots_running'] as int? ?? 0;
          if (running > 0) {
            isRunning = true;
            break;
          }
        }
      }
          return RunnerStatus(
        running: isRunning,
        bots: const <RunnerBotRuntime>[],
      );
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get('/gateway/bots/$encodedBotId/runtime');
    final running = json['session_active'] == true;
    return RunnerStatus(
      running: running,
      bots: <RunnerBotRuntime>[
        RunnerBotRuntime(
          botId: botId.trim(),
          botName: '',
          state: running ? 'running' : 'stopped',
        ),
      ],
    );
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
    Map<String, dynamic> config, {
    bool force = false,
  }) async {
    final cacheKey = '$_baseUrl:$botId';
    final currentHash = HashUtil.calculateHash(config);

    if (!force && _lastSyncedHashes[cacheKey] == currentHash) {
      debugPrint('[MainApiClient] Sync skipped for $botId (already current).');
      return;
    }

    try {
      // 1. Get presigned ticket
      final ticket = await presignBotConfig(botId: botId);
      
      // 2. Upload config JSON to the presigned uploadUrl
      final configJsonBytes = utf8.encode(jsonEncode(config));
      await uploadFileToPresignedUrl(
        uploadUrl: ticket.uploadUrl,
        fileBytes: configJsonBytes,
        contentType: 'application/json',
      );

      // 3. Call sync endpoint with configUrl
      await _postFirstAvailable(
        const <String>['/gateway/bots/sync', '/bots/sync'],
        <String, dynamic>{
          'botId': botId,
          'botName': botName,
          'configUrl': ticket.configUrl,
        },
      );
    } catch (error) {
      debugPrint('[MainApiClient] Presigned config upload failed: $error. Falling back to legacy direct sync.');
      
      // Fallback: legacy direct POST sync
      await _postFirstAvailable(
        const <String>['/gateway/bots/sync', '/bots/sync'],
        <String, dynamic>{
          'botId': botId,
          'botName': botName,
          'config': config,
        },
      );
    }

    _lastSyncedHashes[cacheKey] = currentHash;
    _evictOldestHashEntries(_lastSyncedHashes);
    unawaited(_persistHashes(_lastSyncedHashesKey, _lastSyncedHashes));
    return;
  }

  @override
  Future<void> reloadBot(
    String botId,
    String botName,
    Map<String, dynamic> configJson, {
    bool force = false,
  }) async {
    // For the manager, reload is currently treated as a sync.
    return syncBot(botId, botName, configJson, force: force);
  }

  @override
  Future<void> syncCommand(
    String botId,
    String botName,
    String commandId,
    Map<String, dynamic> commandJson,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post('/gateway/bots/$encodedBotId/commands/sync', <String, dynamic>{
      'botId': botId,
      'botName': botName,
      'commandId': commandId,
      'command': commandJson,
    });
  }

  @override
  Future<void> deleteCommand(
    String botId,
    String botName,
    String commandId,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/commands/delete',
      <String, dynamic>{
        'botId': botId,
        'botName': botName,
        'commandId': commandId,
      },
    );
  }

  @override
  Future<void> syncWorkflow(
    String botId,
    String botName,
    String workflowName,
    Map<String, dynamic> workflowJson,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post('/gateway/bots/$encodedBotId/workflows/sync', <String, dynamic>{
      'botId': botId,
      'botName': botName,
      'workflowName': workflowName,
      'workflow': workflowJson,
    });
  }

  @override
  Future<void> deleteWorkflow(
    String botId,
    String botName,
    String workflowName,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/workflows/delete',
      <String, dynamic>{
        'botId': botId,
        'botName': botName,
        'workflowName': workflowName,
      },
    );
  }

  Future<void> saveDiscordBotSnapshot({
    required String botToken,
    required Map<String, dynamic> config,
    bool force = false,
  }) async {
    final cacheKey = '$_baseUrl:snapshot:$botToken';
    final currentHash = HashUtil.calculateHash(config);

    if (!force && _lastSavedSnapshots[cacheKey] == currentHash) {
      debugPrint('[MainApiClient] Snapshot skipped (already current).');
      return;
    }

    await _postFirstAvailable(
      const <String>['/gateway/bots/discord/save', '/bots/discord/save'],
      <String, dynamic>{'bot_token': botToken, 'config': config},
    );

    _lastSavedSnapshots[cacheKey] = currentHash;
    _evictOldestHashEntries(_lastSavedSnapshots);
    unawaited(_persistHashes(_lastSavedSnapshotsKey, _lastSavedSnapshots));
  }

  Future<Map<String, dynamic>> verifyBilling({
    required String platform,
    required String serverVerificationData,
    required String productId,
    String? localTransactionId,
  }) async {
    return _post('/billing/verify', <String, dynamic>{
      'platform': platform,
      'serverVerificationData': serverVerificationData,
      'productId': productId,
      'localTransactionId': ?_normalize(localTransactionId),
    });
  }

  @override
  Future<void> startBot(String botId, {String? botName}) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post('/gateway/bots/$encodedBotId/start', <String, dynamic>{
      'bot_name': ?_normalize(botName),
      'botName': ?_normalize(botName),
    });
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

  /// Gets the URL for downloading the bot's full config JSON from the Manager.
  /// The config is stored in R2 and is publicly accessible.
  Future<Map<String, dynamic>> getBotConfig(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get('/gateway/bots/$encodedBotId/config');
    final configUrl = (json['configUrl'] ?? '').toString().trim();
    if (configUrl.isEmpty) {
      throw const MainApiClientException('No config URL returned');
    }

    // Download the config JSON from the public R2 URL (no auth needed)
    final httpClient = http.Client();
    try {
      final response = await httpClient
          .get(Uri.parse(configUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw MainApiClientException(
          'Failed to download config: ${response.statusCode}',
        );
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        throw const MainApiClientException('Invalid config format');
      }
      return Map<String, dynamic>.from(decoded);
    } finally {
      httpClient.close();
    }
  }

  /// Lists available config versions for a bot from R2 storage.
  Future<List<Map<String, dynamic>>> getBotConfigVersions(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final response = await _get('/gateway/bots/$encodedBotId/versions');
    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// Restores a previous config version from the version history.
  Future<bool> restoreBotConfigVersion(String botId, String versionKey) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final response = await _post(
      '/gateway/bots/$encodedBotId/versions/restore',
      {'key': versionKey},
    );
    return response['ok'] == true;
  }

  @override
  Future<Map<String, dynamic>> getRunnerInfo() async {
    return _get('/gateway/runner');
  }

  @override
  Future<List<String>> getLogs({String? botId, int limit = 300}) async {
    final List<String> paths;
    if (botId == null || botId.trim().isEmpty) {
      paths = const <String>['/gateway/logs', '/logs'];
    } else {
      final encodedBotId = Uri.encodeComponent(botId.trim());
      paths = <String>[
        '/gateway/bots/$encodedBotId/logs',
        '/bots/$encodedBotId/logs',
      ];
    }

    final json = await _getFirstAvailable(
      paths,
      query: <String, String?>{'limit': limit.toString()},
    );

    final rawLines = json['lines'];
    if (rawLines is! List) {
      return const <String>[];
    }
    return rawLines.map((entry) => entry.toString()).toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> getCommandStats(
    String botId, {
    int hours = 24,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    return _get(
      '/gateway/bots/$encodedBotId/command-stats',
      query: <String, String?>{'hours': hours.toString()},
    );
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

  @override
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

  @override
  Future<void> removeGlobalVariable(String botId, String key) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/global/remove',
      <String, dynamic>{'key': key.trim()},
    );
  }

  @override
  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/global/rename',
      <String, dynamic>{'oldKey': oldKey.trim(), 'newKey': newKey.trim()},
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

  @override
  Future<void> setScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    final normalizedKey = BotConfig.normalizeScopedVariableKey(key);
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/scoped-definitions/set',
      <String, dynamic>{
        'key': normalizedKey,
        'scope': scope.trim(),
        'defaultValue': defaultValue,
        'valueType': valueType,
      },
    );
  }

  @override
  Future<void> removeScopedVariableDefinition(
    String botId,
    String key, {
    String? scope,
    bool purgeStoredValues = false,
  }) async {
    final normalizedKey = BotConfig.normalizeScopedVariableKey(key);
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/variables/scoped-definitions/remove',
      <String, dynamic>{
        'key': normalizedKey,
        if (scope != null && scope.trim().isNotEmpty) 'scope': scope.trim(),
        if (purgeStoredValues) 'purgeStoredValues': true,
      },
    );
  }

  @override
  Future<void> syncScheduledTrigger(
    String botId,
    String triggerId,
    Map<String, dynamic> triggerJson,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/triggers/scheduled/sync',
      <String, dynamic>{'triggerId': triggerId, 'trigger': triggerJson},
    );
  }

  @override
  Future<void> deleteScheduledTrigger(String botId, String triggerId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/triggers/scheduled/delete',
      <String, dynamic>{'triggerId': triggerId},
    );
  }

  @override
  Future<void> syncInboundWebhook(
    String botId,
    String webhookId,
    Map<String, dynamic> webhookJson,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/triggers/webhooks/sync',
      <String, dynamic>{'webhookId': webhookId, 'webhook': webhookJson},
    );
  }

  @override
  Future<void> deleteInboundWebhook(String botId, String webhookId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _post(
      '/gateway/bots/$encodedBotId/triggers/webhooks/delete',
      <String, dynamic>{'webhookId': webhookId},
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
        'Bot Creator Server did not return an access token.',
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
            'displayName',
            'display_name',
            'preferred_username',
          ]) ??
          _extractString(json, <String>[
            'username',
            'name',
            'displayName',
            'display_name',
            'global_name',
          ]) ??
          _extractString(
            _extractMap(user, <String>['discord', 'profile']) ??
                _extractMap(json, <String>['discord', 'profile']),
            <String>['username', 'global_name', 'name', 'display_name'],
          ),
      scopes: scopes,
    );
  }

  Future<PresignBotConfigResponse> presignBotConfig({String? botId}) async {
    final body = <String, dynamic>{
      if (botId != null && botId.trim().isNotEmpty) 'botId': botId.trim(),
    };
    final json = await _post('/gateway/bots/presign-config', body);
    return PresignBotConfigResponse.fromJson(json);
  }

  Future<PresignUploadFileResponse> presignUploadFile({
    required String filename,
    required String contentType,
    required int sizeBytes,
  }) async {
    final body = <String, dynamic>{
      'filename': filename,
      'contentType': contentType,
      'size': sizeBytes,
    };
    final json = await _post('/storage/presign', body);
    return PresignUploadFileResponse.fromJson(json);
  }

  Future<void> uploadFileToPresignedUrl({
    required String uploadUrl,
    required List<int> fileBytes,
    required String contentType,
  }) async {
    final uri = Uri.parse(uploadUrl);
    final response = await _http.put(
      uri,
      headers: <String, String>{
        'content-type': contentType,
      },
      body: fileBytes,
    ).timeout(_timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MainApiClientException(
        'Failed to upload file to storage: ${response.statusCode} - ${response.reasonPhrase}',
        statusCode: response.statusCode,
      );
    }
  }

  // ── Marketplace ──────────────────────────────────────────────

  /// List all marketplace templates.
  Future<List<Map<String, dynamic>>> listMarketplaceTemplates() async {
    final json = await _get('/marketplace');
    final list = (json['data'] as List?) ?? <dynamic>[];
    return list.cast<Map<String, dynamic>>();
  }

  /// Get a single marketplace template by ID.
  Future<Map<String, dynamic>> getMarketplaceTemplate(String id) async {
    return await _get('/marketplace/$id');
  }

  /// Publish a new template.
  Future<Map<String, dynamic>> createMarketplaceTemplate(
    Map<String, dynamic> template,
  ) async {
    return await _post('/marketplace', template);
  }

  /// Update an existing template.
  Future<Map<String, dynamic>> updateMarketplaceTemplate(
    String id,
    Map<String, dynamic> template,
  ) async {
    return await _put('/marketplace/$id', template);
  }

  /// Delete a marketplace template.
  Future<void> deleteMarketplaceTemplate(String id) async {
    await _delete('/marketplace/$id');
  }

  /// Apply a marketplace template to a bot, incrementing its download count.
  Future<Map<String, dynamic>> applyMarketplaceTemplate(
    String templateId,
    String botId,
    Map<String, String> variables,
  ) async {
    return await _post(
      '/marketplace/$templateId/apply',
      <String, dynamic>{
        'botId': botId,
        'variables': variables,
      },
    );
  }

  /// Rate a marketplace template (0.0 - 5.0).
  Future<Map<String, dynamic>> rateMarketplaceTemplate(
    String templateId,
    double rating,
  ) async {
    return await _post('/marketplace/$templateId/rate', <String, dynamic>{
      'rating': rating,
    });
  }
}

/// Returns true for client errors (4xx except 429) that should NOT be retried.
bool _isNotFound(MainApiClientException error) {
  return error.statusCode == 404;
}

/// Returns true for client errors (4xx except 429) that should NOT be retried.
bool _isClientError(MainApiClientException error) {
  final code = error.statusCode;
  if (code == null) return false;
  return code >= 400 && code < 500 && code != 429;
}

/// Internal state for the circuit breaker.
class _CircuitState {
  _CircuitState({required this.firstFailure, required this.failureCount});
  DateTime firstFailure;
  int failureCount;
}

/// Cached health check result with timestamp.
class _CachedHealth {
  _CachedHealth({required this.healthy, required this.timestamp});
  final bool healthy;
  final DateTime timestamp;
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

class PresignBotConfigResponse {
  final String botId;
  final String configUrl;
  final String uploadUrl;

  const PresignBotConfigResponse({
    required this.botId,
    required this.configUrl,
    required this.uploadUrl,
  });

  factory PresignBotConfigResponse.fromJson(Map<String, dynamic> json) {
    return PresignBotConfigResponse(
      botId: (json['botId'] ?? '').toString(),
      configUrl: (json['configUrl'] ?? '').toString(),
      uploadUrl: (json['uploadUrl'] ?? '').toString(),
    );
  }
}

class PresignUploadFileResponse {
  final String fileId;
  final String objectKey;
  final String uploadUrl;

  const PresignUploadFileResponse({
    required this.fileId,
    required this.objectKey,
    required this.uploadUrl,
  });

  factory PresignUploadFileResponse.fromJson(Map<String, dynamic> json) {
    return PresignUploadFileResponse(
      fileId: (json['file_id'] ?? '').toString(),
      objectKey: (json['object_key'] ?? '').toString(),
      uploadUrl: (json['upload_url'] ?? '').toString(),
    );
  }
}
