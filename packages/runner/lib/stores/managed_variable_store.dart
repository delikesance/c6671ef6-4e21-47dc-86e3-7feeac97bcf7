import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bot_creator_shared/bot/variable_database.dart';

class ManagedVariableStore implements VariableDatabase {
  final VariableDatabase _cache;
  final String _baseUrl;
  final String _token;
  final http.Client _httpClient = http.Client();

  ManagedVariableStore(
    this._cache, {
    required String baseUrl,
    required String token,
  }) : _baseUrl =
           baseUrl.endsWith('/')
               ? baseUrl.substring(0, baseUrl.length - 1)
               : baseUrl,
       _token = token;

  void dispose() {
    _httpClient.close();
  }

  Future<void> _post(
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
        print(
          '[ManagedVariableStore] Failed to sync variable mutation: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print(
        '[ManagedVariableStore] Network error syncing variable mutation: $e',
      );
    }
  }

  // ===== READS (delegated entirely to cache) =====

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String botId) =>
      _cache.getGlobalVariables(botId);

  @override
  Future<dynamic> getGlobalVariable(String botId, String key) =>
      _cache.getGlobalVariable(botId, key);

  @override
  Future<Map<String, dynamic>> getScopedVariables(
    String botId,
    String scope,
    String contextId,
  ) => _cache.getScopedVariables(botId, scope, contextId);

  @override
  Future<dynamic> getScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) => _cache.getScopedVariable(botId, scope, contextId, key);

  @override
  Future<List<String>> listContextIds(
    String botId,
    String scope, {
    String? searchKey,
  }) => _cache.listContextIds(botId, scope, searchKey: searchKey);

  @override
  Future<Map<String, dynamic>> queryScopedVariableIndex(
    String botId,
    String scope,
    String key, {
    int offset = 0,
    int limit = 25,
    bool descending = true,
  }) => _cache.queryScopedVariableIndex(
    botId,
    scope,
    key,
    offset: offset,
    limit: limit,
    descending: descending,
  );

  @override
  Future<dynamic> getScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) => _cache.getScopedArrayElement(botId, scope, contextId, key, index);

  @override
  Future<int> getScopedArrayLength(
    String botId,
    String scope,
    String contextId,
    String key,
  ) => _cache.getScopedArrayLength(botId, scope, contextId, key);

  @override
  Future<int?> getScopedVariableTtl(
    String botId,
    String scope,
    String contextId,
    String key,
  ) => _cache.getScopedVariableTtl(botId, scope, contextId, key);

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
  }) => _cache.queryScopedArray(
    botId,
    scope,
    contextId,
    key,
    offset: offset,
    limit: limit,
    descending: descending,
    filter: filter,
  );

  // ===== WRITES (delegated to cache + HTTP push) =====

  @override
  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    await _cache.setGlobalVariable(botId, key, value, ttl: ttl);
    await _post(botId, '/global/set', {
      'key': key,
      'value': value,
      if (ttl != null) 'ttl': ttl,
    });
  }

  @override
  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    // Manager API doesn't support 'rename' directly, so we emulate it.
    final value = await _cache.getGlobalVariable(botId, oldKey);
    await _cache.renameGlobalVariable(botId, oldKey, newKey);
    if (value != null) {
      await setGlobalVariable(botId, newKey, value);
      await removeGlobalVariable(botId, oldKey);
    }
  }

  @override
  Future<void> removeGlobalVariable(String botId, String key) async {
    await _cache.removeGlobalVariable(botId, key);
    await _post(botId, '/global/remove', {'key': key});
  }

  (String, String) _splitContextId(String scope, String contextId) {
    if (scope == 'guildMember') {
      final parts = contextId.split(':');
      if (parts.length >= 2) return (parts[0], parts[1]);
      return (parts.isNotEmpty ? parts[0] : '', '');
    }
    return (contextId, '');
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
    await _cache.setScopedVariable(botId, scope, contextId, key, value, ttl: ttl);
    final (scopeId, scopeAuxId) = _splitContextId(scope, contextId);
    await _post(botId, '/scoped-values/set', {
      'scope': scope,
      'key': key,
      'scope_id': scopeId,
      'scope_aux_id': scopeAuxId,
      'value': value,
      if (ttl != null) 'ttl': ttl,
    });
  }

  @override
  Future<void> renameScopedVariable(
    String botId,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  ) async {
    final value = await _cache.getScopedVariable(
      botId,
      scope,
      contextId,
      oldKey,
    );
    await _cache.renameScopedVariable(botId, scope, contextId, oldKey, newKey);
    if (value != null) {
      await setScopedVariable(botId, scope, contextId, newKey, value);
      await removeScopedVariable(botId, scope, contextId, oldKey);
    }
  }

  @override
  Future<void> removeScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    await _cache.removeScopedVariable(botId, scope, contextId, key);
    final (scopeId, scopeAuxId) = _splitContextId(scope, contextId);
    await _post(botId, '/scoped-values/remove', {
      'scope': scope,
      'key': key,
      'scope_id': scopeId,
      'scope_aux_id': scopeAuxId,
    });
  }

  @override
  Future<void> pushScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic element,
  ) async {
    await _cache.pushScopedArrayElement(botId, scope, contextId, key, element);
    final newValue = await _cache.getScopedVariable(
      botId,
      scope,
      contextId,
      key,
    );
    await setScopedVariable(botId, scope, contextId, key, newValue);
  }

  @override
  Future<dynamic> popScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final popped = await _cache.popScopedArrayElement(
      botId,
      scope,
      contextId,
      key,
    );
    final newValue = await _cache.getScopedVariable(
      botId,
      scope,
      contextId,
      key,
    );
    if (newValue != null) {
      await setScopedVariable(botId, scope, contextId, key, newValue);
    } else {
      // Array became empty and variable unlinked? Or null array.
      await removeScopedVariable(botId, scope, contextId, key);
    }
    return popped;
  }

  @override
  Future<dynamic> removeScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    final removed = await _cache.removeScopedArrayElement(
      botId,
      scope,
      contextId,
      key,
      index,
    );
    final newValue = await _cache.getScopedVariable(
      botId,
      scope,
      contextId,
      key,
    );
    if (newValue != null) {
      await setScopedVariable(botId, scope, contextId, key, newValue);
    } else {
      await removeScopedVariable(botId, scope, contextId, key);
    }
    return removed;
  }

  @override
  Future<void> deleteAllForBot(String botId) async {
    // Usually never called from Bot Execution contexts (only on total purge).
    // Not safely proxyable right now without a global purge route.
    await _cache.deleteAllForBot(botId);
  }
}
