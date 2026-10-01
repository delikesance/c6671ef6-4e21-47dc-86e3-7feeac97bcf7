import 'dart:convert';
import '../bot/bot_data_store.dart';

class SandboxStore implements BotDataStore {
  SandboxStore({
    Map<String, dynamic>? globalVariables,
    Map<String, Map<String, Map<String, dynamic>>>? scopedVariables,
    List<Map<String, dynamic>>? scopedDefinitions,
    List<Map<String, dynamic>>? workflows,
  }) : globalVariables = globalVariables ?? <String, dynamic>{},
       scopedVariables =
           scopedVariables ?? <String, Map<String, Map<String, dynamic>>>{},
       scopedDefinitions = scopedDefinitions ?? <Map<String, dynamic>>[],
       workflows = workflows ?? <Map<String, dynamic>>[];

  final Map<String, dynamic> globalVariables;
  final Map<String, Map<String, Map<String, dynamic>>> scopedVariables;
  final List<Map<String, dynamic>> scopedDefinitions;
  final List<Map<String, dynamic>> workflows;

  List<dynamic> _array(String scope, String context, String key) {
    final bucket = scopedVariables
        .putIfAbsent(scope, () => {})
        .putIfAbsent(context, () => {});
    final raw = bucket[key];
    final value = raw is String ? jsonDecode(raw) : raw;
    if (value != null && value is! List) {
      throw StateError('Variable $key is not an array');
    }
    return bucket[key] = List<dynamic>.from(value as List? ?? []);
  }

  Map<String, dynamic> snapshot() => {
    'global': globalVariables,
    'scoped': scopedVariables,
    'definitions': scopedDefinitions,
  };

  @override
  Future<List<Map<String, dynamic>>> getCommands(String botId) async =>
      const [];

  @override
  Future<List<Map<String, dynamic>>> getScopedVariableDefinitions(
    String botId,
  ) async {
    return scopedDefinitions;
  }

  @override
  Future<void> setScopedVariableDefinition(
    String botId,
    String key,
    String scope,
    dynamic defaultValue, {
    String valueType = 'string',
  }) async {
    scopedDefinitions.add(<String, dynamic>{
      'key': key,
      'scope': scope,
      'defaultValue': defaultValue,
      'valueType': valueType,
    });
  }

  @override
  Future<Map<String, dynamic>> getGlobalVariables(String botId) async =>
      Map<String, dynamic>.from(globalVariables);

  @override
  Future<dynamic> getGlobalVariable(String botId, String key) async =>
      globalVariables[key];

  @override
  Future<void> setGlobalVariable(
    String botId,
    String key,
    dynamic value, {
    String? ttl,
  }) async {
    globalVariables[key] = value;
  }

  @override
  Future<void> renameGlobalVariable(
    String botId,
    String oldKey,
    String newKey,
  ) async {
    if (!globalVariables.containsKey(oldKey)) {
      return;
    }
    globalVariables[newKey] = globalVariables.remove(oldKey);
  }

  @override
  Future<void> removeGlobalVariable(String botId, String key) async {
    globalVariables.remove(key);
  }

  @override
  Future<Map<String, dynamic>> getScopedVariables(
    String botId,
    String scope,
    String contextId,
  ) async {
    return Map<String, dynamic>.from(
      scopedVariables[scope]?[contextId] ?? const <String, dynamic>{},
    );
  }

  @override
  Future<dynamic> getScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    return scopedVariables[scope]?[contextId]?[key];
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
    scopedVariables.putIfAbsent(scope, () => <String, Map<String, dynamic>>{});
    scopedVariables[scope]!.putIfAbsent(contextId, () => <String, dynamic>{});
    scopedVariables[scope]![contextId]![key] = value;
  }

  @override
  Future<int?> getScopedVariableTtl(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    return null;
  }

  @override
  Future<void> renameScopedVariable(
    String botId,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  ) async {
    final bucket = scopedVariables[scope]?[contextId];
    if (bucket == null || !bucket.containsKey(oldKey)) {
      return;
    }
    bucket[newKey] = bucket.remove(oldKey);
  }

  @override
  Future<void> removeScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    scopedVariables[scope]?[contextId]?.remove(key);
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
    throw UnsupportedError(
      'Scoped index queries need a sandbox implementation',
    );
  }

  @override
  Future<void> pushScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic element,
  ) async {
    final array = _array(scope, contextId, key);
    array.add(element);
  }

  @override
  Future<dynamic> popScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    final array = _array(scope, contextId, key);
    return array.isEmpty ? null : array.removeLast();
  }

  @override
  Future<dynamic> removeScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    final array = _array(scope, contextId, key);
    return index < 0 || index >= array.length ? null : array.removeAt(index);
  }

  @override
  Future<dynamic> getScopedArrayElement(
    String botId,
    String scope,
    String contextId,
    String key,
    int index,
  ) async {
    final array = _array(scope, contextId, key);
    return index < 0 || index >= array.length ? null : array[index];
  }

  @override
  Future<int> getScopedArrayLength(
    String botId,
    String scope,
    String contextId,
    String key,
  ) async {
    return _array(scope, contextId, key).length;
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
    throw UnsupportedError('Not implemented by sandbox storage');
  }

  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async => workflows
      .where(
        (workflow) =>
            workflow['name']?.toString().toLowerCase() == name.toLowerCase(),
      )
      .firstOrNull;

  @override
  Future<Map<String, dynamic>> getApp(String botId) async =>
      throw UnsupportedError('Not used');

  @override
  Future<List<Map<String, dynamic>>> getWorkflows(String botId) async =>
      workflows;

  @override
  Future<List<Map<String, dynamic>>> listAppCommands(
    String botId, {
    bool forceRefresh = false,
  }) async => throw UnsupportedError('Not used');

  @override
  Future<void> saveAppCommand(
    String botId,
    String commandId,
    Map<String, dynamic> data,
  ) async => throw UnsupportedError('Not used');

  @override
  Future<void> updateGuildCount(String botId, int count) async =>
      throw UnsupportedError('Not used');

  @override
  Future<void> recordCommandExecution(String botId, String commandName) async =>
      throw UnsupportedError('Not used');

  @override
  Map<String, dynamic> normalizeCommandData(Map<String, dynamic> raw) => raw;
}
