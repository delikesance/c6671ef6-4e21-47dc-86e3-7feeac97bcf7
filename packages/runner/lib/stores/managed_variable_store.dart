import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bot_creator_shared/bot/variable_database.dart';

/// An implementation of [VariableDatabase] that communicates directly with the
/// Manager API via HTTP, without any local caching.
///
/// This ensures that the runner always has the most up-to-date values, even if
/// they are modified by external systems (e.g., the Admin Dashboard).
class ManagedVariableStore implements VariableDatabase {
  final String _baseUrl;
  final String _token;
  final http.Client _httpClient = http.Client();

  ManagedVariableStore({required String baseUrl, required this._token})
    : _baseUrl =
          baseUrl.endsWith('/')
              ? baseUrl.substring(0, baseUrl.length - 1)
              : baseUrl;

  void dispose() {
    _httpClient.close();
  }

  Future<dynamic> _post(
    String botId,
    String suffix,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/bots/${Uri.encodeComponent(botId)}/variables$suffix',
    );
    try {
      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );
      if (response.statusCode >= 400) {
        throw StateError(
          '[ManagedVariableStore] API error ($suffix): ${response.statusCode} - ${response.body}',
        );
      }
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      throw StateError('[ManagedVariableStore] Network error ($suffix): $e');
    }
  }

  Future<dynamic> _get(
    String botId,
    String suffix,
    Map<String, String> queryParameters,
  ) async {
    final url = Uri.parse(
      '$_baseUrl/bots/${Uri.encodeComponent(botId)}/variables$suffix',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Cache-Control': 'no-cache',
        },
      );
      if (response.statusCode == 404) {
        return null;
      }
      if (response.statusCode >= 400) {
        throw StateError(
          '[ManagedVariableStore] API error ($suffix): ${response.statusCode} - ${response.body}',
        );
      }
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    } catch (e) {
      throw StateError('[ManagedVariableStore] Network error ($suffix): $e');
    }
  }

  (String, String) _splitContextId(String scope, String contextId) {
    if (scope == 'guildMember') {
      final parts = contextId.split(':');
      if (parts.length >= 2) return (parts[0], parts[1]);
      return (parts.isNotEmpty ? parts[0] : '', '');
    }
    return (contextId, '');
  }

  // ===== GLOBAL VARIABLES =====

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String botId) async {
    final response = await _get(botId, '/global/list', {});
    if (response is List) {
      final result = <String, dynamic>{};
      for (final item in response) {
        if (item is Map && item.containsKey('key')) {
          result[item['key'].toString()] = item['value'];
        }
      }
      return result;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  @override
  Future<dynamic> getGlobalVariable(String botId, String key) async {
    final response = await _get(botId, '/global/get', {'key': key});
    if (response is Map<String, dynamic>) {
      return response['value'];
    }
    return response;
  }

  @override
  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    int? ttlMs;
    if (ttl != null) {
      ttlMs = _parseBdfdTtl(ttl);
    }
    await _post(botId, '/global/set', {
      'key': key,
      'value': value,
      'ttl': ?ttlMs,
    });
  }

  @override
  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    await _post(botId, '/global/rename', {'oldKey': oldKey, 'newKey': newKey});
  }

  @override
  Future<void> removeGlobalVariable(String botId, String key) async {
    await _post(botId, '/global/remove', {'key': key});
  }

  // ===== SCOPED VARIABLES =====

  @override
  Future<Map<String, dynamic>> getScopedVariables(
    String botId,
    String scope,
    String contextId,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    final response = await _get(botId, '/scoped/list', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
    });
    if (response is List) {
      final result = <String, dynamic>{};
      for (final item in response) {
        if (item is Map && item.containsKey('key')) {
          result[item['key'].toString()] = item['value'];
        }
      }
      return result;
    }
    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }
    return {};
  }

  @override
  Future<dynamic> getScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    final response = await _get(botId, '/scoped/get', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
    });
    if (response is Map<String, dynamic>) {
      return response['value'];
    }
    return response;
  }

  @override
  Future<void> setScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    int? ttlMs;
    if (ttl != null) {
      ttlMs = _parseBdfdTtl(ttl);
    }

    await _post(botId, '/scoped/set', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
      'value': value,
      'ttl': ?ttlMs,
    });
  }

  int? _parseBdfdTtl(String ttl) {
    final trimmed = ttl.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    final match = RegExp(r'^(\d+)([smhd]?)$').firstMatch(trimmed);
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!);
    if (value == null) return null;

    final unit = match.group(2);
    switch (unit) {
      case 's':
        return value * 1000;
      case 'm':
        return value * 1000 * 60;
      case 'h':
        return value * 1000 * 60 * 60;
      case 'd':
        return value * 1000 * 60 * 60 * 24;
      default:
        return value * 1000; // Default to seconds
    }
  }

  @override
  Future<void> renameScopedVariable(
    String botId,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    await _post(botId, '/scoped/rename', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'oldKey': oldKey,
      'newKey': newKey,
    });
  }

  @override
  Future<void> removeScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    await _post(botId, '/scoped/remove', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
    });
  }

  @override
  Future<List<String>> listContextIds(
    String botId,
    String scope, {
    String? searchKey,
  }) async {
    final response = await _get(botId, '/scoped/list-contexts', {
      'scope': scope,
      'search_key': ?searchKey,
    });
    return List<String>.from(response ?? []);
  }

  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) async {
    final response = await _get(botId, '/scoped/query-index', {
      'scope': scope,
      'key': key,
      'offset': offset.toString(),
      'limit': limit.toString(),
      'descending': descending.toString(),
    });
    return Map<String, dynamic>.from(response ?? {});
  }

  // ===== SCOPED ARRAYS =====

  @override
  Future<dynamic> getScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    return await _get(botId, '/scoped/array/get-element', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
      'index': index.toString(),
    });
  }

  @override
  Future<int> getScopedArrayLength(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    final response = await _get(botId, '/scoped/array/length', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
    });
    return response as int? ?? 0;
  }

  @override
  Future<void> pushScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic element,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    await _post(botId, '/scoped/array/push', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
      'element': element,
    });
  }

  @override
  Future<dynamic> popScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    return await _post(botId, '/scoped/array/pop', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
    });
  }

  @override
  Future<dynamic> removeScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    return await _post(botId, '/scoped/array/remove-element', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
      'index': index,
    });
  }

  @override
  Future<Map<String, dynamic>> queryScopedArray(
    String botId,
    String scope,
    String contextId,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
    String? filter,
  }) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    final response = await _get(botId, '/scoped/array/query', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
      'offset': offset.toString(),
      'limit': limit.toString(),
      'descending': descending.toString(),
      'filter': ?filter,
    });
    return Map<String, dynamic>.from(response ?? {});
  }

  @override
  Future<int?> getScopedVariableTtl(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final (id, auxId) = _splitContextId(scope, contextId);
    final response = await _get(botId, '/scoped/ttl', {
      'scope': scope,
      'scope_id': id,
      'scope_aux_id': auxId,
      'key': key,
    });
    if (response is int) {
      return response;
    }
    if (response is Map<String, dynamic>) {
      return response['ttl'] as int?;
    }
    return null;
  }

  @override
  Future<void> deleteAllForBot(String botId) async {
    await _post(botId, '/all/delete', {});
  }
}
