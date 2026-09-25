import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/core/utils/log_redaction.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainApiClientException implements Exception {
  const MainApiClientException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Code applicatif rendu par le serveur (`domain.APIError.code`, ex.
  /// `bot_config_overshrink`, `token_decrypt_failed`).
  ///
  /// POURQUOI ce champ existe séparément du [message] : la phrase du message est
  /// faite pour un humain et peut changer (tailles, détails) ; le code, lui, est
  /// le contrat. Des décisions d'interface — « ce 409 est une QUESTION, pas une
  /// panne » — ne doivent pas dépendre d'un `contains` sur une phrase.
  /// `null` quand la réponse ne porte pas de code (panne réseau, corps vide).
  final String? code;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return '[$statusCode] $message';
  }
}

/// Réduit une exception d'API à une raison lisible : statut, code, message.
///
/// POURQUOI elle est partagée : les écrans qui annoncent un échec doivent dire
/// POURQUOI (version disparue, moteur dépareillé, refus d'API) et non afficher
/// un « échec » muet ; le code applicatif, lui, est la partie stable du contrat
/// (cf. [MainApiClientException.code]).
String describeApiFailure(Object error) {
  if (error is MainApiClientException) {
    return <String>[
      if (error.statusCode != null) 'HTTP ${error.statusCode}',
      if ((error.code ?? '').isNotEmpty) error.code!,
      error.message,
    ].join(' — ');
  }
  return error.toString();
}

/// Cause d'un échec de récupération du jeton d'un bot
/// (`POST /gateway/bots/{id}/token`), telle que l'interface doit la DIRE.
///
/// Le point qui coûte le plus cher à confondre : un `404` de ROUTE (manager
/// plus ancien que l'application, la route n'existe pas encore) n'est pas un
/// « bot absent du compte », et ce n'est pas non plus une panne réseau. Dire
/// « vérifie ta connexion » devant un serveur en retard est un mensonge qui
/// envoie l'utilisateur chercher une panne inexistante (constaté sur dev).
enum BotTokenExportFailure {
  /// `404 bot_not_found` : bot inconnu OU appartenant à un autre propriétaire —
  /// le serveur rend volontairement la même réponse pour ne rien révéler.
  botMissing,

  /// `404` sans code applicatif (ou `501`) : la route n'existe pas sur CE
  /// serveur. Rien à voir avec la connexion : il faut mettre à jour le serveur.
  serverUnsupported,

  /// `409 token_unavailable` : bot connu, aucune credential enregistrée côté
  /// compte. Réessayer ne la fera pas apparaître.
  notStored,

  /// `500 token_decrypt_failed` : la credential existe mais le serveur n'arrive
  /// pas à la relire (clé absente ou tournée). Réessayer n'y changera rien.
  serverCannotRead,

  /// Autre `5xx`, ou panne réseau : réessayer a un sens.
  network,
}

/// Échec typé d'une récupération de jeton de bot.
///
/// Le message porte la CAUSE, jamais la valeur du jeton ni le corps de la
/// réponse : cette exception finit dans les journaux et les rapports de crash.
class BotTokenExportException implements Exception {
  const BotTokenExportException(this.failure);

  final BotTokenExportFailure failure;

  @override
  String toString() {
    switch (failure) {
      case BotTokenExportFailure.botMissing:
        return 'bot token export failed: bot not found on this account (404)';
      case BotTokenExportFailure.serverUnsupported:
        return 'bot token export failed: route missing on this server (404/501)';
      case BotTokenExportFailure.notStored:
        return 'bot token export failed: no credential stored server-side (409)';
      case BotTokenExportFailure.serverCannotRead:
        return 'bot token export failed: server cannot decrypt its credential';
      case BotTokenExportFailure.network:
        return 'bot token export failed: network or retryable server error';
    }
  }
}

/// Réponse de `GET /gateway/snapshot` : la charge utile ET la version (`ETag`) qui
/// l'accompagne. Les deux voyagent ensemble parce que c'est l'ETag, mémorisé par
/// l'appelant, qui transforme le prochain appel en `304` (aucun retraitement).
class GatewaySnapshotResponse {
  const GatewaySnapshotResponse({required this.payload, this.etag});

  final Map<String, dynamic> payload;
  final String? etag;
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

  /// Internal cache of the last saved snapshot hash per bot id.
  /// Key format: "${baseUrl}:snapshot:${botId}"
  static final Map<String, String> _lastSavedSnapshots = <String, String>{};

  /// Deduplicates concurrent Discord OAuth code exchanges (codes are single-use).
  static final Map<String, Future<MainApiSession>> _inflightDiscordExchanges =
      <String, Future<MainApiSession>>{};

  /// Maximum number of entries in each hash cache before LRU eviction.
  static const int _maxHashCacheEntries = 100;

  static const String _lastSyncedHashesKey = 'main_api_last_synced_hashes';
  static const String _lastSavedSnapshotsKey =
      'main_api_last_saved_snapshots_v2';

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

      debugPrint(
        '[MainApiClient] Initialized with ${_lastSyncedHashes.length} synced hashes and ${_lastSavedSnapshots.length} snapshot hashes.',
      );
    } catch (e) {
      debugPrint('[MainApiClient] Failed to load persisted hashes: $e');
    }
  }

  static Future<void> _persistHashes(
    String key,
    Map<String, String> cache,
  ) async {
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

  /// Le délai de reprise effectif de CETTE instance.
  ///
  /// POURQUOI UN SEAM ICI : l'échelle de reprise (1 s, 2 s, 4 s) est invisible
  /// dans un test qui la subit — un test de panne réseau attendrait 7 secondes
  /// de vraies horloges, donc serait lent ET instable sur une machine chargée.
  /// La valeur par défaut reste celle de la production, à l'identique.
  Duration get _retryDelay => _retryBaseDelayOverride ?? _baseRetryDelay;
  static const double _retryBackoffMultiplier = 2.0;

  /// Budget d'une POUSSÉE de configuration (`/gateway/bots/sync`,
  /// `/gateway/bots/discord/save`).
  ///
  /// Ces deux routes ne répondent pas avant que le manager ait son runner :
  /// l'attente est bornée par MANAGED_RUNNER_HEALTH_TIMEOUT_SECONDS (120 s par
  /// défaut), à laquelle s'ajoute le travail de synchro. Mesuré sur 24 h de
  /// sauvegardes réelles : p50 = 125 s, maximum = 187 s.
  ///
  /// Le `_timeout` global (30 s) faisait donc abandonner le client PENDANT que
  /// le serveur travaillait encore : l'abandon est journalisé côté serveur
  /// (499 `request_canceled`,`context canceled` sur l'upload du document), et
  /// la poussée est perdue côté utilisateur. Ce budget-ci est volontairement
  /// SUPÉRIEUR au budget serveur — un client qui abandonne juste avant la
  /// réponse transforme une attente en échec.
  static const Duration configPushTimeout = Duration(minutes: 4);

  /// Cleans up the hash caches using LRU eviction when they exceed the max size.
  static void _evictOldestHashEntries(Map<String, String> cache) {
    if (cache.length <= _maxHashCacheEntries) return;
    final keysToRemove = cache.keys
        .take(cache.length - _maxHashCacheEntries)
        .toList();
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

  /// LE SIGNAL « LE MANAGER RÉPOND DE NOUVEAU ».
  ///
  /// POURQUOI ICI, ET NULLE PART AILLEURS : le disjoncteur est le seul objet de
  /// l'application qui sache qu'une panne a eu lieu ET qu'elle est terminée. La
  /// première requête qui aboutit après des échecs EST le retour de
  /// connectivité — sans sonde périodique, sans dépendance de plateforme, et
  /// sans plugin réseau de plus.
  ///
  /// `null` par défaut : strictement inerte tant que rien n'est branché. Le
  /// rappel n'est appelé QU'UNE FOIS par panne (la trace d'échec est consommée
  /// en le lisant), donc il ne peut pas devenir une boucle quand l'appelant
  /// fait lui-même des requêtes.
  static void Function()? onConnectivityRestored;

  /// Records a success, resetting the circuit breaker.
  static void _recordCircuitSuccess(String baseUrl) {
    final hadFailure = _circuits.remove(baseUrl) != null;
    if (!hadFailure) return;
    final notify = onConnectivityRestored;
    if (notify == null) return;
    try {
      notify();
    } catch (error) {
      // Un abonné ne doit JAMAIS casser la requête qui vient d'aboutir : c'est
      // la requête de l'utilisateur qui compte, pas notre notification.
      debugPrint('[MainApiClient] connectivity-restored hook failed: $error');
    }
  }

  /// Resets all circuit breakers and health caches (e.g. when app resumes from background).
  static void resetCircuitBreakers() {
    _circuits.clear();
    _healthCache.clear();
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
    Duration? retryDelay,

    /// Budget d'une poussée de configuration de CETTE instance (tests) :
    /// la valeur par défaut est [configPushTimeout], celle de la production.
    Duration? pushTimeout,
  }) : _baseUrl = MainApiConfig.normalizeBaseUrl(baseUrl),
       _accessToken = _normalize(accessToken),
       _http = httpClient ?? http.Client(),
       _timeout = timeout ?? const Duration(seconds: 30),
       _retryBaseDelayOverride = retryDelay,
       _configPushTimeoutOverride = pushTimeout;

  final String _baseUrl;
  String get baseUrl => _baseUrl;
  String? _accessToken;
  final http.Client _http;
  final Duration _timeout;
  final Duration? _retryBaseDelayOverride;
  final Duration? _configPushTimeoutOverride;

  /// Le budget de poussée effectif de CETTE instance (voir [configPushTimeout]).
  ///
  /// POURQUOI UN SEAM ICI : le budget réel est de quatre minutes, pour rester
  /// au-dessus du budget d'attente du serveur (~2 min). Un test qui devrait le
  /// subir attendrait quatre minutes de vraie horloge ; il l'abaisse donc, et
  /// vérifie ce qui compte — que le budget est RESPECTÉ et qu'un échec après
  /// l'upload n'est PAS rejoué. La valeur par défaut reste celle de la
  /// production, à l'identique.
  Duration get _configPushTimeout =>
      _configPushTimeoutOverride ?? configPushTimeout;

  @override
  RemoteRuntimeSource get runtimeSource => RemoteRuntimeSource.manager;

  MainApiClient withAccessToken(String? token) {
    return MainApiClient(
      baseUrl: _baseUrl,
      accessToken: token,
      httpClient: _http,
      timeout: _timeout,
      retryDelay: _retryBaseDelayOverride,
      pushTimeout: _configPushTimeoutOverride,
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
    String? contentType = 'application/json',
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{};
    if (contentType != null) {
      headers['content-type'] = contentType;
    }
    if (includeAuth && _accessToken != null) {
      headers['authorization'] = 'Bearer $_accessToken';
    }
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  /// L'en-tête `If-Match` d'une écriture granulaire, ou `null` s'il n'y a rien
  /// à affirmer.
  ///
  /// DEUX PITIQUES, TRAITÉES ICI ET NULLE PART AILLEURS :
  ///
  ///  1. la valeur est ENTOURÉE DE GUILLEMETS — c'est la forme standard d'un
  ///     validateur d'entité, et le serveur les retire avant de comparer. Les
  ///     omettre « marcherait » contre un serveur tolérant et casserait le jour
  ///     où une passerelle stricte s'intercalerait ;
  ///  2. une révision ABSENTE ou VIDE n'émet AUCUN en-tête. Envoyer
  ///     `If-Match: ""` voudrait dire « la révision est la chaîne vide », ce qui
  ///     n'est pas la même chose que « je n'affirme rien » — le serveur, lui,
  ///     refuse une révision vide à raison. Ne rien envoyer est donc la seule
  ///     écriture honnête quand aucune révision n'est connue.
  Map<String, String>? _ifMatchHeaders(String? revision) {
    final normalized = revision?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return <String, String>{'if-match': '"$normalized"'};
  }

  Future<void> _ensureFreshAccessToken() async {
    if (Platform.environment.containsKey('FLUTTER_TEST') &&
        !MainApiSettingsStore.isSessionLoaded) {
      return;
    }
    try {
      final session = await loadMainApiSession();
      if (session != null) {
        if (session.isExpired || session.expiresSoon()) {
          final refreshed = await restoreMainApiSessionIfNeeded(
            timeout: _timeout,
            httpClient: _http,
          );
          if (refreshed?.accessToken != null &&
              refreshed!.accessToken.trim().isNotEmpty) {
            _accessToken = refreshed.accessToken;
          }
        } else if (_accessToken == null || _accessToken!.isEmpty) {
          _accessToken = session.accessToken;
        }
      }
    } catch (e) {
      debugPrint('[MainApiClient] Proactive token check error: $e');
    }
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

    if (includeAuth) {
      await _ensureFreshAccessToken();
    }

    final uri = _uri(path, query: query);
    appendBotDebugLog('[MainApiClient] GET ${redactUriForLog(uri.toString())}');

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
        if ((error.statusCode == 401 || error.statusCode == 403) &&
            includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error)) {
          rethrow;
        }
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] GET $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
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
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    Map<String, String>? extraHeaders,
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    if (includeAuth) {
      await _ensureFreshAccessToken();
    }

    final uri = _uri(path);
    final encodedBody = jsonEncode(body);
    appendBotDebugLog(
      '[MainApiClient] POST $uri body=${redactSensitiveJson(encodedBody)}',
    );

    // Une reprise n'a de sens que sur une requête SANS EFFET. Sur une poussée
    // de configuration, chaque reprise renvoie jusqu'à 100 Ko pendant que le
    // serveur travaille peut-être encore sur la première : avec `_maxRetries`
    // = 3, c'est QUATRE envois pour une seule action de l'utilisateur, et le
    // verrou de synchro par bot répond `409 bot_sync_in_progress` aux suivants.
    // Les routes de poussée appellent donc avec `retryOnFailure: false`.
    final int maxRetries = retryOnFailure ? _maxRetries : 0;

    var attempt = 0;
    // Le rafraîchissement de session ne consomme PAS une reprise (la panne est
    // celle du jeton, pas celle de la requête) mais ne se répète pas.
    var refreshedSession = false;

    while (true) {
      try {
        final response = await _http
            .post(
              uri,
              headers: _headers(
                includeAuth: includeAuth,
                extraHeaders: extraHeaders,
              ),
              body: encodedBody,
            )
            .timeout(timeout ?? _timeout);
        appendBotDebugLog(
          '[MainApiClient] POST $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        if ((error.statusCode == 401 || error.statusCode == 403) &&
            includeAuth &&
            !refreshedSession) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            refreshedSession = true;
            continue;
          }
        }
        if (_isClientError(error)) {
          rethrow;
        }
        if (attempt >= maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] POST $uri attempt ${attempt + 1}/$maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
        attempt++;
      } catch (error) {
        if (attempt >= maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] POST $uri attempt ${attempt + 1}/$maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
        attempt++;
      }
    }
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

    if (includeAuth) {
      await _ensureFreshAccessToken();
    }

    final uri = _uri(path, query: query);
    appendBotDebugLog(
      '[MainApiClient] DELETE ${redactUriForLog(uri.toString())}',
    );

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
        if ((error.statusCode == 401 || error.statusCode == 403) &&
            includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error)) {
          rethrow;
        }
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        appendBotDebugLog(
          '[MainApiClient] DELETE $uri attempt ${attempt + 1}/$_maxRetries failed: $error — retrying...',
        );
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
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
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

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

    if (includeAuth) {
      await _ensureFreshAccessToken();
    }

    final uri = _uri(path);
    final encodedBody = jsonEncode(body);
    appendBotDebugLog('[MainApiClient] PUT ${redactUriForLog(uri.toString())}');

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .put(
              uri,
              headers: _headers(includeAuth: includeAuth),
              body: encodedBody,
            )
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] PUT $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) &&
            includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error)) {
          rethrow;
        }
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body, {
    bool includeAuth = true,
    Map<String, String>? extraHeaders,
  }) async {
    if (_isCircuitOpen(_baseUrl)) {
      throw MainApiClientException(
        'Circuit breaker open for $_baseUrl — too many failures.',
      );
    }

    if (includeAuth) {
      await _ensureFreshAccessToken();
    }

    final uri = _uri(path);
    final encodedBody = jsonEncode(body);
    appendBotDebugLog(
      '[MainApiClient] PATCH ${redactUriForLog(uri.toString())}',
    );

    Object? lastError;
    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await _http
            .patch(
              uri,
              headers: _headers(
                includeAuth: includeAuth,
                extraHeaders: extraHeaders,
              ),
              body: encodedBody,
            )
            .timeout(_timeout);
        appendBotDebugLog(
          '[MainApiClient] PATCH $uri responded with ${response.statusCode}',
        );
        _recordCircuitSuccess(_baseUrl);
        return _parseResponse(response);
      } on MainApiClientException catch (error) {
        lastError = error;
        if ((error.statusCode == 401 || error.statusCode == 403) &&
            includeAuth) {
          final newTokens = await _tryRefreshSession();
          if (newTokens != null) {
            _accessToken = newTokens;
            continue;
          }
        }
        if (_isClientError(error)) {
          rethrow;
        }
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      } catch (error) {
        lastError = error;
        if (attempt >= _maxRetries) {
          _recordCircuitFailure(_baseUrl);
          rethrow;
        }
        await Future<void>.delayed(
          _retryDelay * pow(_retryBackoffMultiplier, attempt),
        );
      }
    }

    if (lastError is Exception) throw lastError;
    throw const MainApiClientException('Request failed after retries.');
  }

  /// Returns the parsed response body as a Map.
  /// If the response is a List, it is wrapped as {'data': list}.
  Map<String, dynamic> _parseResponse(http.Response response) {
    Map<String, dynamic> json;
    try {
      final decoded = _decodeUtf8Json(response);
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
      final rawCode = json['code'];
      final code = rawCode is String && rawCode.trim().isNotEmpty
          ? rawCode.trim()
          : null;
      throw MainApiClientException(
        message,
        statusCode: response.statusCode,
        code: code,
      );
    }

    return json;
  }

  dynamic _decodeUtf8Json(http.Response response) {
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<String?> _tryRefreshSession() async {
    try {
      debugPrint(
        '[MainApiClient] Access token expired or invalid (401/403). Attempting central session restore...',
      );
      final session = await restoreMainApiSessionIfNeeded(
        timeout: _timeout,
        force: true,
        httpClient: _http,
      );
      return session?.accessToken;
    } catch (e) {
      debugPrint('[MainApiClient] Failed to refresh session: $e');
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
    final key = '${code.trim()}|${state.trim()}|$redirectUri';
    final existing = _inflightDiscordExchanges[key];
    if (existing != null) {
      return await existing;
    }
    final future =
        _post('/auth/discord/exchange', <String, dynamic>{
          'code': code,
          'state': state,
          'redirect_uri': redirectUri,
        }, includeAuth: false).then(
          (json) => _sessionFromAuthPayload(
            json,
            authMethod: MainApiAuthMethod.discordOauth,
          ),
        );
    _inflightDiscordExchanges[key] = future;
    try {
      return await future;
    } finally {
      _inflightDiscordExchanges.remove(key);
    }
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

  Future<MainApiSession> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final json = await _post('/auth/login', <String, dynamic>{
      'email': email.trim(),
      'password': password,
    }, includeAuth: false);
    return _sessionFromAuthPayload(
      json,
      authMethod: MainApiAuthMethod.emailPassword,
    );
  }

  Future<Map<String, dynamic>> setCredentials({
    required String email,
    required String password,
    String? currentPassword,
  }) async {
    return _post('/auth/credentials', <String, dynamic>{
      'email': email.trim(),
      'password': password,
      if (currentPassword != null && currentPassword.isNotEmpty)
        'current_password': currentPassword,
    });
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

  /// Identifiant d'un bot tel que les listes du manager le portent : `bot_id`
  /// (`GET /gateway/bots`, `/gateway/snapshot`, canal temps réel), avec `id` en
  /// secours pour les charges utiles locales. Jamais de cast qui pourrait jeter.
  static String botIdOf(Map<String, dynamic> bot) =>
      (bot['bot_id'] ?? bot['id'])?.toString().trim() ?? '';

  /// Propriétaire annoncé d'un bot, tel que le payload du manager le porte :
  /// `owner_id` (champ additif de `GET /gateway/bots`), ou le bloc `team`.
  /// Chaîne vide quand le serveur ne dit rien — aucune invention locale.
  static String _botOwnerIdOf(Map<String, dynamic> bot) {
    final team = bot['team'];
    final owner = bot['owner'];
    final candidates = <Object?>[
      bot['owner_id'],
      bot['ownerId'],
      team is Map ? team['owner_user_id'] : null,
      team is Map ? team['ownerUserId'] : null,
      owner is Map ? owner['id'] : null,
      owner is Map ? owner['owner_id'] : null,
    ];
    for (final candidate in candidates) {
      final value = candidate?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  /// Les bots où l'utilisateur n'est que COLLABORATEUR, avec l'identifiant de
  /// leur propriétaire quand le serveur le donne (chaîne vide sinon).
  ///
  /// Un seul appel (`GET /gateway/bots`) : les deux informations — le partage
  /// (`is_collaborative`) et le propriétaire (`owner_id`) — viennent du même
  /// payload. Un bot dont l'identifiant est illisible est ignoré.
  ///
  /// Tolérant : un serveur plus ancien ne renvoie pas `is_collaborative` => le
  /// map est vide, donc tout reste dans « My bots » (aucun faux positif). Le
  /// test est un test STRICT de booléen : une valeur d'un autre type (chaîne
  /// `"true"`) est traitée comme absente, jamais convertie.
  Future<Map<String, String>> fetchCollaborativeBotOwners() async {
    final bots = await listBots();
    final owners = <String, String>{};
    for (final bot in bots) {
      if (bot['is_collaborative'] != true) continue;
      final id = botIdOf(bot);
      if (id.isEmpty) continue;
      owners[id] = _botOwnerIdOf(bot);
    }
    return owners;
  }

  /// Normalise une liste JSON en `List<Map<String, dynamic>>`.
  ///
  /// Le canal renvoie des listes (`bots`, `collaborators`, `messages`) dont les
  /// éléments peuvent être de formes variées : un élément non-objet est ignoré
  /// plutôt que de faire jeter tout l'appel.
  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }

  /// Équipe d'un bot : le propriétaire et ses collaborateurs, avec leurs droits.
  Future<List<Map<String, dynamic>>> listTeamCollaborators(String botId) async {
    final json = await _get('/gateway/bots/$botId/team/collaborators');
    return _asMapList(json['collaborators']);
  }

  /// Mes droits sur un bot, tels que le SERVEUR les accorde : le bloc
  /// `my_permissions` de la route d'équipe (`can_start_stop`, `can_claim_ads`, …).
  ///
  /// `null` quand le serveur ne renvoie pas ce bloc (serveur plus ancien) : les
  /// droits sont alors INCONNUS, et l'appelant doit retomber sur un refus plutôt
  /// que d'offrir une action que le propriétaire n'a peut-être pas accordée.
  Future<Map<String, dynamic>?> fetchMyTeamPermissions(String botId) async {
    final json = await _get('/gateway/bots/$botId/team/collaborators');
    final raw = json['my_permissions'];
    if (raw is! Map) {
      return null;
    }
    return Map<String, dynamic>.from(raw);
  }

  /// Ajoute un collaborateur, ou remplace ses droits s'il est déjà membre.
  Future<void> upsertTeamCollaborator(
    String botId,
    String userId,
    Map<String, dynamic> permissions,
  ) => _post('/gateway/bots/$botId/team/collaborators', <String, dynamic>{
    'user_id': userId,
    'permissions': permissions,
  });

  /// Retire un collaborateur de l'équipe : il perd l'accès au bot et au tchat.
  Future<void> removeTeamCollaborator(String botId, String userId) =>
      _delete('/gateway/bots/$botId/team/collaborators/$userId');

  /// Page du tchat d'équipe, du plus récent au plus ancien.
  ///
  /// [beforeId] pagine vers le passé : le tchat est **persisté côté serveur**,
  /// donc un appareil qui rejoint ouvre la conversation, il ne la recommence pas.
  Future<List<Map<String, dynamic>>> listTeamChatMessages(
    String botId, {
    int? beforeId,
    int limit = 50,
  }) async {
    final json = await _get(
      '/gateway/bots/$botId/team/chat',
      query: <String, String?>{
        'before_id': beforeId?.toString(),
        'limit': limit.toString(),
      },
    );
    return _asMapList(json['messages']);
  }

  /// Publie un message dans le tchat d'équipe ; le serveur en fait un événement
  /// temps réel (`team.chat.message`) pour les autres appareils.
  Future<Map<String, dynamic>> sendTeamChatMessage(
    String botId,
    String content,
  ) => _post('/gateway/bots/$botId/team/chat', <String, dynamic>{
    'content': content,
  });

  Future<void> deleteBot(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    await _delete('/gateway/bots/$encodedBotId');
  }

  /// Demande au compte le jeton d'un bot déjà géré côté serveur
  /// (`POST /gateway/bots/{id}/token`).
  ///
  /// Le serveur ne rend JAMAIS ce jeton dans ses listes (`GET /gateway/bots`
  /// rédige volontairement `bot_token`) : sans cette route, un appareil qui n'a
  /// pas saisi le jeton une première fois ne peut pas exécuter le bot en local,
  /// et un rafraîchissement n'y change rien. L'appel est un acte explicite du
  /// propriétaire : corps vide, session du compte (`read:bots`).
  ///
  /// Ne journalise ni la réponse ni le jeton : seul le code HTTP part dans les
  /// traces (voir `_post`).
  ///
  /// Échoue en [BotTokenExportException], dont la cause est distinguée par
  /// [BotTokenExportFailure] — un `404` de ROUTE (manager plus ancien que
  /// l'app) est [BotTokenExportFailure.serverUnsupported], pas un « bot absent »
  /// et encore moins une panne réseau.
  Future<BotTokenExport> fetchBotToken(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final Map<String, dynamic> json;
    try {
      json = await _post(
        '/gateway/bots/$encodedBotId/token',
        <String, dynamic>{},
      );
    } on MainApiClientException catch (error) {
      throw BotTokenExportException(_classifyBotTokenExportFailure(error));
    } catch (_) {
      // Panne réseau, réponse illisible : même cause que les 5xx réessayables.
      throw const BotTokenExportException(BotTokenExportFailure.network);
    }
    final export = BotTokenExport.fromJson(json);
    if (export.token.isEmpty) {
      // 200 sans jeton : le corps n'a pas la forme attendue (proxy, page
      // d'erreur servie en 200). Aucun jeton ne doit être inventé ni stocké.
      throw const BotTokenExportException(BotTokenExportFailure.network);
    }
    return export;
  }

  @override
  Future<RunnerStatus> getStatus({String? botId}) async {
    if (botId == null || botId.trim().isEmpty) {
      try {
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
      } on MainApiClientException catch (e) {
        // In pool mode, /gateway/runtime returns 404 pool_mode_active.
        // Return empty status gracefully instead of propagating the error.
        if (e.message.contains('pool_mode_active') ||
            e.message.contains('pool mode')) {
          return RunnerStatus(running: false, bots: const <RunnerBotRuntime>[]);
        }
        rethrow;
      }
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    try {
      final statusJson = await _get('/gateway/bots/$encodedBotId/status');
      final bot = statusJson['bot'];
      final state = bot is Map ? (bot['state'] ?? '').toString() : '';
      final running = state.toLowerCase() == 'running';
      return RunnerStatus(
        running: running,
        bots: <RunnerBotRuntime>[
          RunnerBotRuntime(
            botId: botId.trim(),
            botName: bot is Map ? (bot['botName'] ?? '').toString() : '',
            state: running ? 'running' : 'stopped',
          ),
        ],
      );
    } on MainApiClientException {
      return RunnerStatus(
        running: false,
        bots: <RunnerBotRuntime>[
          RunnerBotRuntime(botId: botId.trim(), botName: '', state: 'stopped'),
        ],
      );
    }
  }

  @override
  Future<RunnerMetrics> getMetrics({String? botId}) async {
    if (botId == null || botId.trim().isEmpty) {
      try {
        final json = await _getFirstAvailable(const <String>[
          '/gateway/metrics',
          '/metrics',
        ]);
        return RunnerMetrics.fromJson(json);
      } on MainApiClientException catch (e) {
        if (e.message.contains('pool_mode_active') ||
            e.message.contains('pool mode')) {
          return RunnerMetrics(
            running: false,
            bots: const <RunnerBotRuntime>[],
          );
        }
        rethrow;
      }
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _getFirstAvailable(<String>[
      '/gateway/bots/$encodedBotId/metrics',
      '/bots/$encodedBotId/metrics',
    ]);
    return RunnerMetrics.fromJson(json);
  }

  Map<String, dynamic> _sanitizeConfigForUpload(Map<String, dynamic> source) {
    final sanitized = Map<String, dynamic>.from(source);
    sanitized.remove('token');
    sanitized.remove('botToken');
    sanitized.remove('bot_token');

    final db = sanitized['databaseConfig'];
    if (db is Map) {
      final cleanDb = Map<String, dynamic>.from(db);
      cleanDb.remove('password');
      final uri = cleanDb['uri']?.toString() ?? '';
      if (uri.contains('@')) {
        cleanDb.remove('uri');
      }
      cleanDb['encrypted'] = true;
      sanitized['databaseConfig'] = cleanDb;
    }
    return sanitized;
  }

  @override
  Future<void> syncBot(
    String botId,
    String botName,
    Map<String, dynamic> config, {
    bool force = false,
    bool confirmOvershrink = false,
  }) async {
    // POURQUOI la garde est en TÊTE de méthode : c'est le dernier point avant le
    // réseau. Une charge utile vide (aucune commande, aucun événement, aucun
    // webhook, aucune variable) a déjà écrasé la configuration d'un bot ; on la
    // refuse AVANT tout appel — et donc avant le repli « re-POST direct », qui
    // rejouerait la même charge vide. Rien n'est renvoyé automatiquement.
    assertNonDegenerateBotPayload(config, source: 'syncBot');

    final cacheKey = '$_baseUrl:$botId';
    final currentHash = HashUtil.calculateHash(config);

    if (!force && _lastSyncedHashes[cacheKey] == currentHash) {
      debugPrint('[MainApiClient] Sync skipped for $botId (already current).');
      return;
    }

    final safeConfig = _sanitizeConfigForUpload(config);

    // Le drapeau n'est posé QUE quand l'utilisateur a répondu oui au dialogue de
    // sur-réduction. Il voyage dans les deux corps visant `/gateway/bots/sync`
    // (chemin pré-signé et repli direct) : une poussée rejouée doit être la MÊME,
    // à ce champ près.
    final overshrinkConsent = <String, dynamic>{
      if (confirmOvershrink) 'confirmOvershrink': true,
    };

    // Le document est-il DÉJÀ dans le stockage d'objets ? C'est ce qui décide si
    // un échec a le droit d'être rejoué en repli direct.
    //
    // POURQUOI ce drapeau : le repli existe pour un stockage d'objets
    // injoignable, pas pour une synchro qui échoue. Or le `catch` d'origine
    // couvrait les DEUX et renvoyait la poussée entière (les 100 Ko de
    // configuration) alors que le document était déjà en place et que le
    // serveur travaillait peut-être encore sur la première — journal de l'app :
    // « Presigned config upload failed … Falling back to legacy direct sync »,
    // présent sur 106 des 230 synchros, chacune relançant l'attente de pool du
    // serveur (~2 min).
    var uploadedToObjectStore = false;

    try {
      // 1. Get presigned ticket
      final ticket = await presignBotConfig(botId: botId);

      // 2. Upload config JSON to the presigned uploadUrl (zero plaintext secrets)
      final configJsonBytes = utf8.encode(jsonEncode(safeConfig));
      await uploadFileToPresignedUrl(
        uploadUrl: ticket.uploadUrl,
        fileBytes: configJsonBytes,
        contentType: 'application/json; charset=utf-8',
      );
      uploadedToObjectStore = true;

      // 3. Call sync endpoint with configUrl — budget de poussée, un seul essai
      await _postFirstAvailable(
        const <String>['/gateway/bots/sync', '/bots/sync'],
        <String, dynamic>{
          'botId': botId,
          'botName': botName,
          'configUrl': ticket.configUrl,
          ...overshrinkConsent,
        },
        timeout: _configPushTimeout,
        retryOnFailure: false,
      );
    } catch (error) {
      if (uploadedToObjectStore) {
        // Le document est en place : cet échec vient de la synchro elle-même.
        // Rejouer la poussée entière ne répare rien, ne fait que renvoyer la
        // configuration sur un serveur qui la traite encore, et se heurte au
        // verrou de synchro par bot (409 bot_sync_in_progress).
        debugPrint(
          '[MainApiClient] Config sync failed after a successful upload: $error. Not replaying the config.',
        );
        rethrow;
      }

      debugPrint(
        '[MainApiClient] Presigned config upload failed: $error. Falling back to legacy direct sync.',
      );

      // Fallback: legacy direct POST sync with sanitized config
      await _postFirstAvailable(
        const <String>['/gateway/bots/sync', '/bots/sync'],
        <String, dynamic>{
          'botId': botId,
          'botName': botName,
          'config': safeConfig,
          ...overshrinkConsent,
        },
        timeout: _configPushTimeout,
        retryOnFailure: false,
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
    required String botId,
    required String botToken,
    required Map<String, dynamic> config,
    bool force = false,
  }) async {
    // Même refus que `syncBot` (mêmes critères, garde partagée) : la sauvegarde
    // Discord est un second chemin de poussée, il ne doit pas être le maillon
    // faible qui laisse passer une charge vide.
    assertNonDegenerateBotPayload(config, source: 'saveDiscordBotSnapshot');

    final normalizedBotId = botId.trim();
    final cacheKey = '$_baseUrl:snapshot:$normalizedBotId';
    final currentHash = HashUtil.calculateHash(config);

    if (!force && _lastSavedSnapshots[cacheKey] == currentHash) {
      debugPrint('[MainApiClient] Snapshot skipped (already current).');
      return;
    }

    // Même budget que `syncBot` — c'est la même attente de pool côté serveur
    // (p50 mesuré à 124,7 s sur cette route) — et AUCUN rejeu : renvoyer une
    // sauvegarde de 100 Ko pendant qu'une synchro tient le verrou par bot rend
    // un `409 bot_sync_in_progress` (trois cas sur 24 h, 21 s chacun).
    //
    // `bot_id` : l'identifiant sous lequel l'APP connaît ce bot. Le manager
    // identifie le bot par son jeton (`/applications/@me`) et l'ignorait donc
    // jusqu'ici. Sans lui, une annonce récompensée regardée pour ce bot envoie
    // un callback SSV que le manager ne peut rattacher à aucun bot : la
    // publicité est vue et la récompense est jetée (« no owner candidate
    // accepted the claim »). L'envoyer permet au manager d'enregistrer la
    // correspondance identifiant local → bot géré.
    await _postFirstAvailable(
      const <String>['/gateway/bots/discord/save', '/bots/discord/save'],
      <String, dynamic>{
        'bot_token': botToken,
        'config': config,
        'bot_id': normalizedBotId,
      },
      timeout: _configPushTimeout,
      retryOnFailure: false,
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
    String? appAccountToken,
  }) async {
    return _post('/billing/verify', <String, dynamic>{
      'platform': platform,
      'serverVerificationData': serverVerificationData,
      'productId': productId,
      'localTransactionId': ?_normalize(localTransactionId),
      'appAccountToken': ?_normalize(appAccountToken),
    });
  }

  @override
  Future<void> startBot(String botId, {String? botName}) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    // AUCUN REJEU : demarrer un bot est une action a effet cote serveur (le
    // manager provisionne/reconcilie son execution). Le defaut `_maxRetries = 3`
    // envoyait jusqu'a quatre demarrages pour un seul clic, et le journal de
    // production en a garde la trace (`bot_sync_in_progress` en 409 sur les
    // envois suivants). Conforme a la regle du depot : un rejeu est reserve aux
    // routes sans effet visible.
    await _post(
      '/gateway/bots/$encodedBotId/start',
      <String, dynamic>{
        'bot_name': ?_normalize(botName),
        'botName': ?_normalize(botName),
      },
      retryOnFailure: false,
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

  /// Comme `_get`, mais rend la réponse HTTP brute : indispensable pour lire l'ETag et
  /// distinguer un 304 (rien n'a changé) d'un 200. On réutilise `_http`, `_headers` et
  /// `_timeout` du client (même circuit breaker, mêmes entêtes d'auth).
  Future<http.Response> _getRaw(
    String path, {
    Map<String, String>? headers,
  }) async {
    await _ensureFreshAccessToken();
    final uri = _uri(path);
    final merged = <String, String>{
      ..._headers(includeAuth: true),
      ...?headers,
    };
    final response = await _http.get(uri, headers: merged).timeout(_timeout);
    _recordCircuitSuccess(_baseUrl);
    appendBotDebugLog(
      '[MainApiClient] GET $uri responded with ${response.statusCode}',
    );
    return response;
  }

  /// État complet (compte, bots, apps hébergées) en une seule requête.
  ///
  /// - 200 → la charge utile analysée ;
  /// - 304 → `null` : rien n'a changé depuis `etag`, ne rien réappliquer ;
  /// - 404 → lève une `MainApiClientException` : le manager est plus ancien, l'appelant
  ///   doit retomber sur son repli « une requête par bot ».
  Future<Map<String, dynamic>?> getGatewaySnapshot({String? etag}) async {
    return (await getGatewaySnapshotWithEtag(etag: etag))?.payload;
  }

  /// Variante de [getGatewaySnapshot] qui rend AUSSI l'ETag de la réponse : c'est lui
  /// qu'il faut renvoyer au prochain appel (`If-None-Match`) pour obtenir un `304` et
  /// éviter de retélécharger l'état complet à chaque repli.
  Future<GatewaySnapshotResponse?> getGatewaySnapshotWithEtag({
    String? etag,
  }) async {
    final response = await _getRaw(
      '/gateway/snapshot',
      // `?etag` : l'entête est omise quand il n'y a pas encore de version mémorisée.
      headers: {'If-None-Match': ?etag},
    );
    if (response.statusCode == 304) return null;
    if (response.statusCode != 200) {
      throw MainApiClientException(
        'GET /gateway/snapshot failed with ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw const MainApiClientException(
        'GET /gateway/snapshot returned a non-object body',
      );
    }
    return GatewaySnapshotResponse(
      payload: Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>()),
      etag: _headerIgnoreCase(response, 'etag'),
    );
  }

  /// Lecture d'un entête HTTP indépendante de la casse : un `ETag` renvoyé en
  /// majuscules par Go et un `etag` côté Dart doivent produire le même 304.
  static String? _headerIgnoreCase(http.Response response, String name) {
    final wanted = name.toLowerCase();
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() == wanted) return entry.value;
    }
    return null;
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
    final response = await _http
        .get(Uri.parse(configUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw MainApiClientException(
        'Failed to download config: ${response.statusCode}',
      );
    }
    final decoded = _decodeUtf8Json(response);
    if (decoded is! Map) {
      throw const MainApiClientException('Invalid config format');
    }
    return Map<String, dynamic>.from(decoded);
  }

  /// Lists available config versions for a bot from R2 storage.
  Future<List<Map<String, dynamic>>> getBotConfigVersions(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final response = await _get('/gateway/bots/$encodedBotId/versions');
    final data = response['data'];
    if (data is List) {
      return data
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(growable: false);
    }
    return const <Map<String, dynamic>>[];
  }

  /// Restaure une version de la configuration d'un bot.
  ///
  /// [confirmOvershrink] demande au manager une restauration FORCÉE : sans lui,
  /// le manager refuse les versions passées sous son plancher de plausibilité
  /// (`409 bot_config_version_too_small`). POURQUOI ce drapeau existe : ce
  /// plancher protège une POUSSÉE (une suppression massive et involontaire),
  /// alors qu'une restauration est par définition un retour en arrière demandé
  /// explicitement — la version visée est celle qui tournait avant, elle est
  /// donc légitime même si elle est pauvre. Le manager ne l'applique que
  /// lorsqu'il honore le drapeau ; sinon il refuse encore, et l'application le
  /// dit sans faire croire à une panne.
  Future<bool> restoreBotConfigVersion(
    String botId,
    String versionKey, {
    bool confirmOvershrink = false,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final response = await _post(
      '/gateway/bots/$encodedBotId/versions/restore',
      {'key': versionKey, if (confirmOvershrink) 'confirmOvershrink': true},
    );
    return response['ok'] == true;
  }

  /// Fetches the full config JSON for a specific version snapshot.
  Future<Map<String, dynamic>> getBotConfigVersion(
    String botId,
    String versionKey,
  ) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final encodedKey = Uri.encodeQueryComponent(versionKey);
    final json = await _get(
      '/gateway/bots/$encodedBotId/versions/config',
      query: <String, String?>{'key': encodedKey},
    );
    final configUrl = (json['configUrl'] ?? '').toString().trim();
    if (configUrl.isEmpty) {
      throw const MainApiClientException('No config URL returned for version');
    }

    final response = await _http
        .get(Uri.parse(configUrl))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw MainApiClientException(
        'Failed to download version config: ${response.statusCode}',
      );
    }
    final decoded = _decodeUtf8Json(response);
    if (decoded is! Map) {
      throw const MainApiClientException('Invalid version config format');
    }
    return Map<String, dynamic>.from(decoded);
  }

  // ─── /api/v2 : la façade granulaire ────────────────────────────────────────
  //
  // COMMENT CES MÉTHODES SONT ÉCRITES, ET POURQUOI ELLES RESSEMBLENT AU LEGACY :
  // elles passent par la MÊME plomberie que le reste du client (`_get`, `_post`,
  // `_patch` : authentification proactive, reprise, disjoncteur, décodage et
  // exception typée portant le code applicatif). Une seconde plomberie pour la
  // v2 serait une seconde façon d'échouer.
  //
  // CE QUE CES MÉTHODES NE FONT PAS : elles ne décident JAMAIS du format. Elles
  // appellent la route qu'on leur demande et rendent ce que le serveur répond —
  // c'est `BotDataRepository` qui choisit, sonde en main. Un client qui
  // choisirait tout seul serait un client qui suppose.
  //
  // REPRISE DES ÉCRITURES : une écriture granulaire est IDEMPOTENTE sous
  // `If-Match` — rejouer la même écriture avec la même précondition ne peut pas
  // écrire deux fois, puisque le serveur refuse dès que la révision a bougé. La
  // reprise automatique est donc sûre ici. Conséquence bornée et connue : si la
  // première tentative a abouti mais que sa réponse s'est perdue, la reprise
  // rend `409` et l'appelant recharge — l'écriture, elle, est bien en place.

  /// Sonde `GET /api/v2/capabilities`.
  ///
  /// Rend `null` quand la ROUTE n'existe pas (404/405) : c'est le cas NOMINAL
  /// d'un serveur plus ancien que l'application, pas une panne. Toute autre
  /// erreur (401, 5xx, réseau) est relayée : une sonde qui échoue ne prouve
  /// aucune absence, et le dépôt ne doit pas désarmer la v2 sur une panne.
  Future<BotCapabilities?> fetchCapabilities() async {
    try {
      final json = await _get('/api/v2/capabilities');
      return BotCapabilities.fromWire(json);
    } on MainApiClientException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) return null;
      rethrow;
    }
  }

  /// `GET /api/v2/bots/{botId}/commands` : la liste ALLÉGÉE.
  Future<CommandPage> listCommandsV2(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get('/api/v2/bots/$encodedBotId/commands');
    return CommandPage.fromWire(json);
  }

  /// `GET /api/v2/bots/{botId}/commands/{commandId}` : la commande ENTIÈRE.
  Future<CommandDetail> getCommandV2(String botId, String commandId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final encodedCommandId = Uri.encodeComponent(commandId.trim());
    final json = await _get(
      '/api/v2/bots/$encodedBotId/commands/$encodedCommandId',
    );
    final raw = json['command'];
    if (raw is! Map) {
      throw const MainApiClientException('Invalid command payload');
    }
    return CommandDetail(
      botId: botId.trim(),
      commandId: commandId.trim(),
      raw: Map<String, dynamic>.from(raw),
      revision: (json['revision'] ?? '').toString().trim(),
    );
  }

  /// `PATCH /api/v2/bots/{botId}/commands/{commandId}` : l'écriture ciblée.
  ///
  /// La commande est ENVELOPPÉE (`{"command": …}`) comme côté serveur, qui
  /// REFUSE les champs inconnus : une faute de frappe dans le corps devient une
  /// erreur nommée au lieu d'une commande silencieusement réduite à une clé.
  Future<GranularWriteResult> patchCommandV2(
    String botId,
    String commandId,
    Map<String, dynamic> command, {
    String? ifMatch,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final encodedCommandId = Uri.encodeComponent(commandId.trim());
    final json = await _patch(
      '/api/v2/bots/$encodedBotId/commands/$encodedCommandId',
      <String, dynamic>{'command': command},
      extraHeaders: _ifMatchHeaders(ifMatch),
    );
    return GranularWriteResult.fromWire(json);
  }

  /// `GET /api/v2/bots/{botId}/commands/{commandId}/history` : métadonnées des
  /// dernières versions journalisées (aucun contenu de version ne sort d'ici).
  Future<List<CommandVersionInfo>> listCommandHistoryV2(
    String botId,
    String commandId, {
    int? limit,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final encodedCommandId = Uri.encodeComponent(commandId.trim());
    final json = await _get(
      '/api/v2/bots/$encodedBotId/commands/$encodedCommandId/history',
      query: <String, String?>{if (limit != null) 'limit': limit.toString()},
    );
    return CommandVersionInfo.listFromWire(json);
  }

  /// `POST /api/v2/bots/{botId}/commands/{commandId}/rollback/{historyId}` :
  /// réapplique le contenu d'une version journalisée.
  ///
  /// La restauration est journalisée côté serveur comme une NOUVELLE entrée :
  /// elle est donc annulable, et ce n'est pas la même promesse qu'un écrasement.
  Future<GranularWriteResult> restoreCommandVersionV2(
    String botId,
    String commandId,
    String historyId, {
    String? ifMatch,
    bool confirmOvershrink = false,
  }) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final encodedCommandId = Uri.encodeComponent(commandId.trim());
    final encodedHistoryId = Uri.encodeComponent(historyId.trim());
    final json = await _post(
      '/api/v2/bots/$encodedBotId/commands/$encodedCommandId/rollback/'
      '$encodedHistoryId',
      <String, dynamic>{if (confirmOvershrink) 'confirmOvershrink': true},
      extraHeaders: _ifMatchHeaders(ifMatch),
    );
    return GranularWriteResult.fromWire(json);
  }

  @override
  Future<Map<String, dynamic>> getRunnerInfo() async {
    return _get('/gateway/runner');
  }

  @override
  Future<List<String>> getLogs({String? botId, int limit = 300}) async {
    final List<String> paths;
    if (botId == null || botId.trim().isEmpty) {
      try {
        paths = const <String>['/gateway/logs', '/logs'];

        final json = await _getFirstAvailable(
          paths,
          query: <String, String?>{'limit': limit.toString()},
        );

        final rawLines = json['lines'];
        if (rawLines is! List) {
          return const <String>[];
        }
        return rawLines
            .map((entry) => entry.toString())
            .toList(growable: false);
      } on MainApiClientException catch (e) {
        if (e.message.contains('pool_mode_active') ||
            e.message.contains('pool mode')) {
          return const <String>[];
        }
        rethrow;
      }
    }

    final encodedBotId = Uri.encodeComponent(botId.trim());
    paths = <String>[
      '/gateway/bots/$encodedBotId/logs',
      '/bots/$encodedBotId/logs',
    ];

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

  Future<List<Map<String, dynamic>>> getBotAdHistory(String botId) async {
    final encodedBotId = Uri.encodeComponent(botId.trim());
    final json = await _get('/gateway/bots/$encodedBotId/runtime/ad-history');
    final raw = json['data'] ?? json['claims'] ?? json['history'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<bool> registerDeviceToken({
    required String fcmToken,
    String platform = '',
    String locale = '',
  }) async {
    try {
      final json = await _post('/gateway/account/device', <String, dynamic>{
        'fcm_token': fcmToken.trim(),
        'platform': platform.trim(),
        'locale': locale.trim(),
      });
      return json['success'] == true;
    } catch (_) {
      return false;
    }
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
    Duration? timeout,
    bool retryOnFailure = true,
  }) async {
    MainApiClientException? notFoundError;
    for (final path in paths) {
      try {
        return await _post(
          path,
          body,
          includeAuth: includeAuth,
          timeout: timeout,
          retryOnFailure: retryOnFailure,
        );
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

  MainApiSession _sessionFromAuthPayload(
    Map<String, dynamic> json, {
    MainApiAuthMethod? authMethod,
  }) {
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
    final scopes = scopesRaw is List
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
      authMethod: authMethod,
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
    final response = await _http
        .put(
          uri,
          headers: <String, String>{'content-type': contentType},
          body: fileBytes,
        )
        .timeout(_timeout);

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
    return await _post('/marketplace/$templateId/apply', <String, dynamic>{
      'botId': botId,
      'variables': variables,
    });
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

  // ──────────────────────────────────────────────
  // Container / Hosted App methods
  // ──────────────────────────────────────────────

  /// List all containers for the authenticated owner.
  Future<List<ContainerInfo>> listContainers() async {
    final json = await _get('/containers');
    final list =
        (json['containers'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    return list.map((e) => ContainerInfo.fromJson(e)).toList();
  }

  /// Free/premium eligibility for deploying a hosted Docker container.
  Future<HostedAppEligibility> getHostedAppEligibility() async {
    final json = await _get('/containers/eligibility');
    return HostedAppEligibility.fromJson(json);
  }

  /// Mapping des formules servi par le serveur : quelles formules existent, quels droits
  /// elles portent, et à quels identifiants de produits elles correspondent.
  ///
  /// Usage : les CAPACITÉS, jamais l'affichage. L'application s'en sert pour reconnaître
  /// les SKUs rattachés aux formules (achat et validation des reçus) — les offres montrées
  /// à l'utilisateur restent une fonctionnalité de l'application, avec ses propres textes
  /// et sa propre mise en page.
  Future<PlanCatalogInfo> getGatewayPlans() async {
    final json = await _get('/gateway/plans');
    return PlanCatalogInfo.fromJson(json);
  }

  /// Claim a rewarded-ad deploy slot for a free hosted container.
  Future<HostedAppClaimAdResult> claimHostedAppAd({
    required String placement,
    required String rewardId,
    required String idempotencyKey,
    DateTime? occurredAt,
  }) async {
    final json = await _post('/containers/claim-ad', <String, dynamic>{
      'placement': placement,
      'reward_id': rewardId,
      'idempotency_key': idempotencyKey,
      'occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
    });
    return HostedAppClaimAdResult.fromJson(json);
  }

  /// Deploy a new container (async, returns job + container IDs).
  ///
  /// AUCUN REJEU : la route cree un conteneur par appel. Le manager n'a pas de
  /// cle d'idempotence sur cette route (verifie : `DeployContainer` appelle
  /// `Compute.Deploy` sans cle, et consomme les minutes offertes via
  /// `OnDeployed`) : un rejeu apres un simple depassement de delai cree un
  /// SECOND conteneur, facture, et reconsomme des minutes. L'utilisateur voit
  /// l'echec et reclique ; il ne paie pas deux fois.
  Future<Map<String, dynamic>> deployContainer({
    required String image,
    required int cpuMillis,
    required int memoryMb,
    int storageGb = 10,
    Map<String, String> env = const <String, String>{},
    String? registryCredentialId,
    RegistryAuthInput? registryAuth,
    bool saveRegistryAuth = false,
    String? saveRegistryLabel,
  }) async {
    final body = <String, dynamic>{
      'image': image,
      'cpu_millis': cpuMillis,
      'memory_mb': memoryMb,
      'storage_gb': storageGb,
      'env': env,
    };
    if (registryCredentialId != null && registryCredentialId.isNotEmpty) {
      body['registry_credential_id'] = registryCredentialId;
    }
    if (registryAuth != null) {
      body['registry_auth'] = registryAuth.toJson();
    }
    if (saveRegistryAuth) {
      body['save_registry_auth'] = true;
      if (saveRegistryLabel != null && saveRegistryLabel.isNotEmpty) {
        body['save_registry_label'] = saveRegistryLabel;
      }
    }
    return _post('/containers/deploy', body, retryOnFailure: false);
  }

  Future<List<RegistryCredential>> listRegistryCredentials() async {
    final json = await _get('/registry-credentials');
    final list =
        (json['credentials'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    return list.map(RegistryCredential.fromJson).toList();
  }

  Future<RegistryCredential> createRegistryCredential({
    required String label,
    required String registryHost,
    required String username,
    required String password,
  }) async {
    // AUCUN REJEU : chaque appel cree une ligne. Un rejeu laisse des doublons
    // d'identifiants dans la liste du locataire, que rien ne distingue ensuite.
    final json = await _post(
      '/registry-credentials',
      <String, dynamic>{
        'label': label,
        'registry_host': registryHost,
        'username': username,
        'password': password,
      },
      retryOnFailure: false,
    );
    return RegistryCredential.fromJson(json);
  }

  Future<RegistryCredential> updateRegistryCredential(
    String id, {
    String? label,
    String? registryHost,
    String? username,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (label != null) body['label'] = label;
    if (registryHost != null) body['registry_host'] = registryHost;
    if (username != null) body['username'] = username;
    if (password != null) body['password'] = password;
    final json = await _patch('/registry-credentials/$id', body);
    return RegistryCredential.fromJson(json);
  }

  Future<void> deleteRegistryCredential(String id) async {
    await _delete('/registry-credentials/$id');
  }

  /// Get the current status of a container.
  Future<Map<String, dynamic>> getContainerStatus(String id) async {
    return _get('/containers/$id/status');
  }

  /// Fetch recent container logs (read-only, no exec shell).
  Future<String> getContainerLogs(String id, {int tail = 200}) async {
    final json = await _get('/containers/$id/logs?tail=$tail');
    return json['logs']?.toString() ?? '';
  }

  /// Stop a running container (shut down; config is kept for restart).
  Future<void> stopContainer(String id) async {
    await _post('/containers/$id/stop', <String, dynamic>{});
  }

  /// Start a stopped container using saved image and environment variables.
  Future<Map<String, dynamic>> startContainer(String id) async {
    return _post('/containers/$id/start', <String, dynamic>{});
  }

  /// Résout l'identité Discord du bot que fait tourner un conteneur
  /// (`POST /containers/{id}/discord-identity`) : le serveur est seul à savoir
  /// quel bot un conteneur exécute, et il rend l'URL d'invitation à ouvrir.
  ///
  /// Échoue en `409` (`discord_identity_unavailable`) quand le token du bot est
  /// absent ou révoqué — l'appelant doit alors inviter l'utilisateur à
  /// redéployer, pas à réessayer.
  Future<DiscordBotIdentity> fetchContainerDiscordIdentity(String id) async {
    final json = await _post(
      '/containers/$id/discord-identity',
      <String, dynamic>{},
    );
    return DiscordBotIdentity.fromJson(json);
  }

  /// Permanently delete a container from the database and compute layer.
  Future<void> deleteContainer(String id) async {
    await _delete('/containers/$id');
  }

  /// Extend the TTL of a container.
  Future<Map<String, dynamic>> extendContainerTTL(
    String id,
    int ttlMinutes,
  ) async {
    return _patch('/containers/$id/ttl', <String, dynamic>{
      'ttl_minutes': ttlMinutes,
    });
  }

  /// Update CPU / memory resources of a container.
  Future<Map<String, dynamic>> updateContainerResources(
    String id, {
    required int cpuMillis,
    required int memoryMb,
  }) async {
    return _patch('/containers/$id/resources', <String, dynamic>{
      'cpu_millis': cpuMillis,
      'memory_mb': memoryMb,
    });
  }

  /// Connect to the container console WebSocket.
  /// Returns a connected [WebSocketChannel] ready for bidirectional I/O.
  WebSocketChannel connectContainerConsole(String id) {
    final uri = Uri.parse(
      '${_baseUrl.replaceFirst('http', 'ws')}/containers/$id/console',
    );
    return IOWebSocketChannel.connect(
      uri,
      headers: _headers(includeAuth: true, contentType: null),
    );
  }

  /// Fetch Turnkey bot templates for the specified locale.
  Future<List<Map<String, dynamic>>> getTurnkeyTemplates({
    String locale = 'fr',
  }) async {
    final json = await _get(
      '/gateway/turnkey/templates?locale=$locale',
      includeAuth: false,
    );
    final templates = json['templates'];
    if (templates is List) {
      return templates
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Technically validates a Discord bot token (/users/@me) without requiring Discord App ownership.
  Future<Map<String, dynamic>> validateTurnkeyDiscordToken(
    String botToken,
  ) async {
    return await _post('/gateway/turnkey/validate-token', <String, dynamic>{
      'bot_token': botToken.trim(),
    }, includeAuth: false);
  }

  /// Returns a shared reconnecting session for owner bot status/runtime events.
  GatewayBotEventsSession connectGatewayBotEvents() {
    return GatewayBotEventsManager.obtain(
      baseUrl: _baseUrl,
      headers: _headers(includeAuth: true, contentType: null),
    );
  }

  /// Annonces publiées depuis l'admin (`GET /gateway/announcements`).
  ///
  /// Le serveur rend un TABLEAU trié du plus grave au moins grave ; `_get`
  /// l'enveloppe sous `data` (ou le nomme `announcements`). Les entrées qui ne
  /// sont pas des objets sont écartées ici ; le décodage champ par champ,
  /// tolérant aux types inattendus, vit dans
  /// `features/announcements/logic/announcement.dart`.
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    final json = await _get('/gateway/announcements');
    final raw = json['announcements'] ?? json['data'];
    if (raw is! List) {
      return const <Map<String, dynamic>>[];
    }
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList(growable: false);
  }
}

/// Returns true for client errors (4xx except 429) that should NOT be retried.
bool _isNotFound(MainApiClientException error) {
  return error.statusCode == 404;
}

/// Traduit un échec HTTP de `POST /gateway/bots/{id}/token` en cause
/// exploitable par l'interface.
///
/// Deux pièges de cette route : un `404` peut venir de la ROUTE ABSENTE
/// (manager plus ancien que l'app — le routeur Go rend alors une page 404 sans
/// code applicatif) ou d'un bot étranger au compte (`404 bot_not_found`) ; et un
/// `500` de cette route est le `token_decrypt_failed` documenté, donc une panne
/// définitive côté serveur, pas une panne réseau à réessayer.
BotTokenExportFailure _classifyBotTokenExportFailure(
  MainApiClientException error,
) {
  final appCode = error.message.trim().toLowerCase();
  // Le code applicatif prime : il peut arriver sur un statut que le contrat ne
  // prévoit pas (proxy, passerelle).
  if (appCode == 'token_decrypt_failed') {
    return BotTokenExportFailure.serverCannotRead;
  }
  switch (error.statusCode) {
    case 404:
      return appCode == 'bot_not_found'
          ? BotTokenExportFailure.botMissing
          : BotTokenExportFailure.serverUnsupported;
    case 409:
      return BotTokenExportFailure.notStored;
    case 500:
      return BotTokenExportFailure.serverCannotRead;
    case 501:
      return BotTokenExportFailure.serverUnsupported;
  }
  // 5xx réessayables (502/503/504) et pannes réseau : même conséquence pour
  // l'utilisateur, « vérifie ta connexion » est ici le seul message honnête.
  return BotTokenExportFailure.network;
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

/// Information about a hosted container.
class RegistryCredential {
  const RegistryCredential({
    required this.id,
    required this.label,
    required this.registryHost,
    required this.username,
  });

  final String id;
  final String label;
  final String registryHost;
  final String username;

  factory RegistryCredential.fromJson(Map<String, dynamic> json) {
    return RegistryCredential(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      registryHost: (json['registry_host'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}

class RegistryAuthInput {
  const RegistryAuthInput({
    required this.username,
    required this.password,
    this.registry,
  });

  final String? registry;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (registry != null && registry!.isNotEmpty) 'registry': registry,
    'username': username,
    'password': password,
  };
}

String detectRegistryHostFromImage(String image) {
  final trimmed = image.trim();
  if (trimmed.isEmpty) return '';
  var first = trimmed;
  final at = trimmed.indexOf('@');
  if (at > 0) first = trimmed.substring(0, at);
  final slash = first.indexOf('/');
  if (slash > 0) {
    final head = first.substring(0, slash);
    if (head.contains('.') || head == 'localhost') {
      return head.toLowerCase();
    }
  }
  return 'docker.io';
}

/// Information about a hosted container.
class ContainerInfo {
  final String id;
  final String ownerId;
  final String swarmServiceId;
  final String image;
  final int cpuMillis;
  final int memoryMb;
  final int memoryUsageBytes;
  final int storageGb;
  final Map<String, String> env;
  final String state;
  final int hostPort;
  final String nodeIp;
  final String? registryCredentialId;
  final String registryHost;
  final String registryUsername;
  final String healthStatus;
  final String statusCode;
  final String statusMessage;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Identifiant d'application Discord du bot que fait tourner ce conteneur,
  /// quand le serveur l'a déjà résolu (`discord_application_id`).
  ///
  /// ABSENT (`null`) pour les conteneurs déployés avant que le serveur ne
  /// mémorise l'identité : l'appelant fait alors résoudre l'identité par le
  /// serveur (`POST /containers/{id}/discord-identity`). C'est l'absence, et
  /// non une valeur vide, qui déclenche cette résolution.
  final String? discordApplicationId;
  final String? discordBotName;
  final String? discordBotAvatar;

  const ContainerInfo({
    required this.id,
    required this.ownerId,
    this.swarmServiceId = '',
    required this.image,
    required this.cpuMillis,
    required this.memoryMb,
    this.memoryUsageBytes = 0,
    required this.storageGb,
    this.env = const <String, String>{},
    required this.state,
    this.hostPort = 0,
    this.nodeIp = '',
    this.registryCredentialId,
    this.registryHost = '',
    this.registryUsername = '',
    this.healthStatus = '',
    this.statusCode = '',
    this.statusMessage = '',
    this.discordApplicationId,
    this.discordBotName,
    this.discordBotAvatar,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) {
    return ContainerInfo(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['owner_id'] ?? '').toString(),
      swarmServiceId: (json['swarm_service_id'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      cpuMillis: _parseInt(json['cpu_millis'], 0),
      memoryMb: _parseInt(json['memory_mb'], 0),
      memoryUsageBytes: _parseInt(json['memory_usage_bytes'], 0),
      storageGb: _parseInt(json['storage_gb'], 0),
      env: (json['env'] is Map<String, dynamic>
          ? (json['env'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            )
          : <String, String>{}),
      state: (json['state'] ?? '').toString(),
      hostPort: _parseInt(json['host_port'], 0),
      nodeIp: (json['node_ip'] ?? '').toString(),
      registryCredentialId: json['registry_credential_id']?.toString(),
      registryHost: (json['registry_host'] ?? '').toString(),
      registryUsername: (json['registry_username'] ?? '').toString(),
      healthStatus: (json['health_status'] ?? '').toString(),
      statusCode: (json['status_code'] ?? '').toString(),
      statusMessage: (json['status_message'] ?? '').toString(),
      discordApplicationId: _parseOptionalId(json['discord_application_id']),
      discordBotName: json['discord_bot_name']?.toString(),
      discordBotAvatar: json['discord_bot_avatar']?.toString(),
      expiresAt: _parseDateTime(json['expires_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  String? get discordBotAvatarUrl {
    final avatar = discordBotAvatar?.trim() ?? '';
    if (avatar.isEmpty) return null;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }
    final appId = discordApplicationId?.trim() ?? '';
    if (appId.isNotEmpty) {
      return 'https://cdn.discordapp.com/avatars/$appId/$avatar.png?size=1024';
    }
    return null;
  }

  bool get isRunning => state == 'RUNNING';
  bool get isPending => state == 'PENDING';
  bool get isProvisioning => state == 'PROVISIONING' || state == 'PENDING';
  bool get isStopped => state == 'STOPPED' || state == 'STOPPING';
  bool get isFailed => state == 'FAILED';
  bool get isTerminal => isStopped || isFailed;
  bool get usesPrivateRegistry =>
      registryHost.isNotEmpty || registryUsername.isNotEmpty;

  static int parseInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic v, int fallback) => parseInt(v, fallback);

  /// Identifiant technique optionnel : `null` quand le serveur ne le renvoie
  /// pas, jamais une chaîne vide (voir [ContainerInfo.discordApplicationId]).
  static String? _parseOptionalId(dynamic v) {
    final value = v?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime(0);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime(0);
  }
}

/// Identité Discord du bot que fait tourner un conteneur, telle que le serveur
/// la résout (`POST /containers/{id}/discord-identity`) : de quoi l'inviter
/// dans un serveur, `invite_url` étant prête à ouvrir.
class DiscordBotIdentity {
  const DiscordBotIdentity({
    required this.botId,
    this.username = '',
    this.avatar = '',
    this.inviteUrl = '',
  });

  /// ID Discord du bot (le `client_id` de l'URL d'invitation).
  final String botId;

  final String username;
  final String avatar;

  /// URL d'invitation composée par le serveur ; vide s'il ne l'a pas fournie.
  final String inviteUrl;

  factory DiscordBotIdentity.fromJson(Map<String, dynamic> json) {
    // Certaines routes enveloppent la charge utile sous `data` : on accepte les
    // deux formes plutôt que de rendre une identité vide sur une réponse saine.
    final nested = json['data'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return DiscordBotIdentity(
      botId: (source['bot_id'] ?? '').toString().trim(),
      username: (source['username'] ?? '').toString(),
      avatar: (source['avatar'] ?? '').toString(),
      inviteUrl: (source['invite_url'] ?? '').toString().trim(),
    );
  }
}

/// Jeton d'un bot tel que le compte le rend
/// (`POST /gateway/bots/{id}/token`).
///
/// Cette route est la SEULE surface qui transporte un jeton vers l'appareil :
/// les listes du serveur (`GET /gateway/bots`, `/gateway/snapshot`, le canal
/// temps réel) le rédigent volontairement. La réponse porte
/// `Cache-Control: no-store` côté serveur, et ce modèle n'est jamais journalisé
/// ni relayé à l'analytique : seule son existence compte pour l'appelant.
class BotTokenExport {
  const BotTokenExport({
    required this.botId,
    required this.token,
    this.validatedAt,
  });

  /// ID Discord du bot à qui appartient [token].
  final String botId;

  /// Le jeton en clair. Ne jamais l'écrire dans un journal, un message d'erreur
  /// ni un événement analytique.
  final String token;

  /// Date de validation de la credential côté serveur ; `null` si le serveur ne
  /// l'a pas fournie (elle est omise quand elle est nulle).
  final DateTime? validatedAt;

  factory BotTokenExport.fromJson(Map<String, dynamic> json) {
    // Certaines routes enveloppent la charge utile sous `data` : on accepte les
    // deux formes plutôt que de rendre un jeton vide sur une réponse saine.
    final nested = json['data'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : json;
    final rawValidatedAt = source['validated_at']?.toString().trim() ?? '';
    return BotTokenExport(
      botId: (source['bot_id'] ?? '').toString().trim(),
      token: (source['token'] ?? '').toString().trim(),
      validatedAt: rawValidatedAt.isEmpty
          ? null
          : DateTime.tryParse(rawValidatedAt),
    );
  }
}

/// Une formule du catalogue serveur : ce qu'elle permet, et les SKUs qui la
/// vendent (liste vide = formule non achetable, par exemple accordée à la main
/// par un administrateur).
class PurchasablePlanInfo {
  const PurchasablePlanInfo({
    required this.code,
    required this.displayName,
    required this.maxBots,
    required this.maxTurnkeyBots,
    required this.allowTurnkey,
    required this.allowOwnBots,
    required this.productIds,
    this.isDefault = false,
  });

  final String code;
  final String displayName;

  /// 0 = illimité (règle de tout le produit).
  final int maxBots;
  final int maxTurnkeyBots;

  final bool allowTurnkey;
  final bool allowOwnBots;
  final List<String> productIds;

  /// Formule attribuée d'office à tout compte sans abonnement (FREE) : elle
  /// n'est jamais achetée, donc elle s'affiche comme un socle, sans bouton.
  final bool isDefault;

  bool get isPurchasable => productIds.isNotEmpty;

  factory PurchasablePlanInfo.fromJson(Map<String, dynamic> json) {
    final rawIds = json['product_ids'];
    return PurchasablePlanInfo(
      code: json['code']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? '',
      maxBots: ContainerInfo.parseInt(json['max_bots'], 0),
      maxTurnkeyBots: ContainerInfo.parseInt(json['max_turnkey_bots'], 0),
      allowTurnkey: json['allow_turnkey'] != false,
      allowOwnBots: json['allow_own_bots'] != false,
      isDefault: json['is_default'] == true,
      productIds: rawIds is List
          ? rawIds
                .map((entry) => entry.toString())
                .where((entry) => entry.isNotEmpty)
                .toList()
          : const <String>[],
    );
  }
}

/// Catalogue des formules achetables + état réel du compte (`/gateway/plans`).
class PlanCatalogInfo {
  const PlanCatalogInfo({required this.plans, this.currentTierCode});

  final List<PurchasablePlanInfo> plans;

  /// Formule réellement appliquée au compte, telle que le serveur la résout.
  final String? currentTierCode;

  factory PlanCatalogInfo.fromJson(Map<String, dynamic> json) {
    final rawPlans = json['plans'];
    final current = json['current'];
    return PlanCatalogInfo(
      plans: rawPlans is List
          ? rawPlans
                .whereType<Map>()
                .map(
                  (entry) => PurchasablePlanInfo.fromJson(
                    Map<String, dynamic>.from(entry),
                  ),
                )
                .toList()
          : const <PurchasablePlanInfo>[],
      currentTierCode: current is Map
          ? _normalize(current['tier_code']?.toString())
          : null,
    );
  }
}

class HostedAppEligibility {
  const HostedAppEligibility({
    required this.premium,
    required this.hostingMinutesBalance,
    required this.activeContainers,
    required this.canDeploy,
    required this.maxContainers,
    required this.adRewardMinutes,
    this.deployBlockedReason,
    this.allowTurnkey = true,
    this.planTierCode,
    this.hostingExpiresAt,
    this.hostingPermanent = false,
  });

  final bool premium;
  final int hostingMinutesBalance;
  final int activeContainers;
  final bool canDeploy;

  /// Plafond de conteneurs, fixé par la formule du compte côté serveur (elle
  /// prime sur l'abonnement store) : c'est exactement le chiffre appliqué au
  /// démarrage, donc celui que l'écran doit montrer.
  final int maxContainers;
  final int adRewardMinutes;

  /// La formule inclut-elle le clé en main / les applications hébergées ?
  final bool allowTurnkey;

  /// Code de la formule servie par le serveur (ex. `FREE`, `STARTER`, `PRO`).
  final String? planTierCode;

  /// Fin de la couverture hébergement, quand le serveur la connaît (échéance d'un
  /// abonnement ou du dernier octroi qui couvre).
  final DateTime? hostingExpiresAt;

  /// Vrai seulement quand le serveur dit que la couverture n'a PAS d'échéance
  /// (un octroi permanent). Les deux champs sont nuls/faux quand l'information
  /// manque : le client ne doit alors rien affirmer sur la durée.
  final bool hostingPermanent;

  /// `container_limit` | `no_minutes` | `plan_not_included` | null when
  /// [canDeploy] is true.
  final String? deployBlockedReason;

  bool get isBlockedByContainerLimit =>
      deployBlockedReason == 'container_limit';
  bool get isBlockedByNoMinutes => deployBlockedReason == 'no_minutes';
  bool get isBlockedByPlan => deployBlockedReason == 'plan_not_included';

  factory HostedAppEligibility.fromJson(Map<String, dynamic> json) {
    return HostedAppEligibility(
      premium: json['premium'] == true,
      hostingMinutesBalance: ContainerInfo.parseInt(
        json['hosting_minutes_balance'],
        0,
      ),
      activeContainers: ContainerInfo.parseInt(json['active_containers'], 0),
      canDeploy: json['can_deploy'] == true,
      maxContainers: ContainerInfo.parseInt(json['max_containers'], 1),
      adRewardMinutes: ContainerInfo.parseInt(json['ad_reward_minutes'], 60),
      deployBlockedReason: _normalize(
        json['deploy_blocked_reason']?.toString(),
      ),
      allowTurnkey: json['allow_turnkey'] != false,
      planTierCode: _normalize(json['plan_tier_code']?.toString()),
      hostingExpiresAt: DateTime.tryParse(
        json['hosting_expires_at']?.toString() ?? '',
      )?.toUtc(),
      hostingPermanent: json['hosting_permanent'] == true,
    );
  }
}

class HostedAppClaimAdResult {
  const HostedAppClaimAdResult({
    required this.grantedMinutes,
    required this.hostingMinutesBalance,
  });

  final int grantedMinutes;
  final int hostingMinutesBalance;

  factory HostedAppClaimAdResult.fromJson(Map<String, dynamic> json) {
    return HostedAppClaimAdResult(
      grantedMinutes: ContainerInfo.parseInt(json['granted_minutes'], 0),
      hostingMinutesBalance: ContainerInfo.parseInt(
        json['hosting_minutes_balance'],
        0,
      ),
    );
  }
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
