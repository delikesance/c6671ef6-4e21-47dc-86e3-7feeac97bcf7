import 'dart:convert';

import '../bot/bot_data_store.dart';

String scopedStorageKey(String rawKey) {
  final key = rawKey.trim();
  if (key.isEmpty) {
    throw Exception('key is required for scoped variables');
  }
  if (key.startsWith('bc_')) {
    if (key.length <= 3) {
      throw Exception('key is required for scoped variables');
    }
    return key.substring(3);
  }
  return key;
}

String scopedReferenceKey(String rawKey) {
  final key = rawKey.trim();
  if (key.isEmpty) {
    throw Exception('key is required for scoped variables');
  }
  return key.startsWith('bc_') ? key : 'bc_$key';
}

String inferDefinitionValueType(dynamic value) {
  if (value is num) {
    return 'number';
  }
  if (value is bool) {
    return 'bool';
  }
  if (value is List || value is Map<String, dynamic>) {
    return 'json';
  }
  return 'string';
}

Future<void> ensureScopedDefinitionExists({
  required BotDataStore store,
  required String botId,
  required String scope,
  required String storageKey,
  required dynamic defaultValue,
}) async {
  final definitions = await store.getScopedVariableDefinitions(botId);
  final exists = definitions.any((entry) {
    final entryScope = (entry['scope'] ?? '').toString().trim().toLowerCase();
    final entryKeyRaw = (entry['key'] ?? '').toString().trim().toLowerCase();
    if (entryScope != scope.toLowerCase() || entryKeyRaw.isEmpty) {
      return false;
    }
    try {
      return scopedStorageKey(entryKeyRaw).toLowerCase() ==
          storageKey.toLowerCase();
    } catch (_) {
      return false;
    }
  });
  if (exists) {
    return;
  }

  await store.setScopedVariableDefinition(
    botId,
    storageKey,
    scope,
    defaultValue,
    valueType: inferDefinitionValueType(defaultValue),
  );
}

String stringifyVariableValue(dynamic value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  if (value is List || value is Map) {
    return jsonEncode(value);
  }
  return value.toString();
}

List<String> legacyContextIdsForScope(String scope, String canonicalContextId) {
  switch (scope) {
    case 'user':
      return const <String>['Unknown User'];
    case 'guild':
    case 'channel':
      return const <String>['DM'];
    case 'guildMember':
      final parts = canonicalContextId.split(':');
      final guild = parts.isNotEmpty ? parts.first.trim() : '';
      final user = parts.length > 1 ? parts[1].trim() : '';
      return <String>{
        'DM:Unknown User',
        if (guild.isNotEmpty) '$guild:Unknown User',
        if (user.isNotEmpty) 'DM:$user',
      }.toList(growable: false);
    default:
      return const <String>[];
  }
}

/// Storage semantics shared by visual blocks and the native BDFD runtime.
class VariableService {
  VariableService(this.store, this.botId);
  final BotDataStore store;
  final String botId;

  /// Names declared in the local schema, not the per-context value index.
  Future<List<String>> declaredNames({
    String? scope,
    void Function()? checkBudget,
  }) async {
    checkBudget?.call();
    final definitions = await store.getScopedVariableDefinitions(botId);
    checkBudget?.call();
    final names = <String, String>{};
    void add(String raw) {
      checkBudget?.call();
      if (raw.trim().isEmpty) return;
      final name = scopedStorageKey(raw);
      names.putIfAbsent(name.toLowerCase(), () => name);
    }

    for (final definition in definitions) {
      checkBudget?.call();
      if (scope == null ||
          (definition['scope'] ?? '').toString().trim().toLowerCase() ==
              scope.trim().toLowerCase()) {
        add((definition['key'] ?? '').toString());
      }
    }
    if (scope == null) {
      final globals = await store.getGlobalVariables(botId);
      checkBudget?.call();
      for (final name in globals.keys) {
        add(name);
      }
    }
    return List.unmodifiable(names.values);
  }

  /// Tests the declaration catalogue without reading or creating a value.
  Future<bool> exists(String key, {void Function()? checkBudget}) async {
    checkBudget?.call();
    final normalized = scopedStorageKey(key).toLowerCase();
    final definitions = await store.getScopedVariableDefinitions(botId);
    checkBudget?.call();
    for (final definition in definitions) {
      checkBudget?.call();
      final raw = (definition['key'] ?? '').toString();
      if (raw.trim().isNotEmpty &&
          scopedStorageKey(raw).toLowerCase() == normalized) {
        return true;
      }
    }
    final globals = await store.getGlobalVariables(botId);
    checkBudget?.call();
    return globals.keys.any((name) {
      checkBudget?.call();
      return scopedStorageKey(name).toLowerCase() == normalized;
    });
  }

  /// Restores declared defaults, preserving definitions and unrelated keys.
  /// Snapshot the index before writing: index ordering depends on values.
  Future<void> resetScoped({
    required String scope,
    required String key,
    String? userId,
    String? guildId,
    void Function()? checkBudget,
  }) async {
    final normalized = scopedStorageKey(key).toLowerCase();
    checkBudget?.call();
    final definitions = await store.getScopedVariableDefinitions(botId);
    checkBudget?.call();
    final definition = definitions.firstWhere(
      (entry) =>
          (entry['scope'] ?? '').toString().toLowerCase() ==
              scope.toLowerCase() &&
          (entry['key'] ?? '').toString().trim().isNotEmpty &&
          scopedStorageKey(entry['key'].toString()).toLowerCase() == normalized,
      orElse: () => const <String, dynamic>{},
    );
    if (definition.isEmpty ||
        (!definition.containsKey('defaultValue') &&
            !definition.containsKey('default_value'))) {
      throw ArgumentError('No declared default for $scope variable "$key".');
    }
    final storageKey = scopedStorageKey(definition['key'].toString());
    final value = definition.containsKey('defaultValue')
        ? definition['defaultValue']
        : definition['default_value'];
    final targets = <String, Set<String>>{};
    for (final indexedKey in {storageKey, scopedReferenceKey(storageKey)}) {
      var offset = 0;
      while (true) {
        checkBudget?.call();
        final page = await store.queryScopedVariableIndex(
          botId,
          scope,
          indexedKey,
          offset: offset,
          limit: 250,
        );
        checkBudget?.call();
        final items = page['items'];
        if (items is! List) throw StateError('Invalid variable index page.');
        for (final item in items) {
          checkBudget?.call();
          if (item is! Map) throw StateError('Invalid variable index entry.');
          final contextId = (item['contextId'] ?? '').toString();
          if (contextId.isEmpty) throw StateError('Missing variable context.');
          final matches =
              (userId == null ||
                  (scope == 'guildMember'
                      ? contextId.split(':').last == userId
                      : contextId == userId)) &&
              (guildId == null ||
                  scope != 'guildMember' ||
                  contextId.split(':').first == guildId);
          if (matches) {
            targets
                .putIfAbsent(contextId, () => <String>{storageKey})
                .add(indexedKey);
          }
        }
        offset += items.length;
        final total = page['total'];
        if (items.isEmpty || (total is num && offset >= total)) break;
      }
    }
    // Global-user legacy mode has a complete context even if not yet stored.
    if (scope == 'user' && userId != null) {
      targets.putIfAbsent(userId, () => <String>{storageKey});
    }
    for (final target in targets.entries) {
      for (final targetKey in target.value) {
        checkBudget?.call();
        await store.setScopedVariable(
          botId,
          scope,
          target.key,
          targetKey,
          value ?? '',
        );
        checkBudget?.call();
      }
    }
  }

  Future<({dynamic value, bool defaulted})> readScoped({
    required String scope,
    required String contextId,
    required String key,
  }) async {
    final storageKey = scopedStorageKey(key);
    final referenceKey = scopedReferenceKey(key);
    var value = await store.getScopedVariable(
      botId,
      scope,
      contextId,
      storageKey,
    );
    if (value == null) {
      final legacyContextIds = legacyContextIdsForScope(scope, contextId);
      for (final legacyContextId in legacyContextIds) {
        value = await store.getScopedVariable(
          botId,
          scope,
          legacyContextId,
          storageKey,
        );
        if (value != null) {
          // Legacy compatibility: copy forward to canonical context, keep legacy data untouched.
          await store.setScopedVariable(
            botId,
            scope,
            contextId,
            storageKey,
            value,
          );
          break;
        }
      }
    }
    if (value == null && referenceKey != storageKey) {
      value = await store.getScopedVariable(
        botId,
        scope,
        contextId,
        referenceKey,
      );
      if (value != null) {
        await store.setScopedVariable(
          botId,
          scope,
          contextId,
          storageKey,
          value,
        );
      }
    }
    if (value == null && referenceKey != storageKey) {
      final legacyContextIds = legacyContextIdsForScope(scope, contextId);
      for (final legacyContextId in legacyContextIds) {
        value = await store.getScopedVariable(
          botId,
          scope,
          legacyContextId,
          referenceKey,
        );
        if (value != null) {
          await store.setScopedVariable(
            botId,
            scope,
            contextId,
            storageKey,
            value,
          );
          break;
        }
      }
    }
    bool isValueEmpty(dynamic v) {
      if (v == null) return true;
      final s = v.toString().trim();
      return s.isEmpty || s == 'null' || s == 'empty/null';
    }

    var defaulted = false;
    if (isValueEmpty(value)) {
      // Resolve definition default value
      dynamic defaultValue = '';
      var hasDef = false;
      try {
        final definitions = await store.getScopedVariableDefinitions(botId);
        final def = definitions.firstWhere((entry) {
          final entryScope = (entry['scope'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final entryKeyRaw = (entry['key'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return entryScope == scope.toLowerCase() &&
              scopedStorageKey(entryKeyRaw).toLowerCase() ==
                  storageKey.toLowerCase();
        }, orElse: () => const <String, dynamic>{});
        if (def.containsKey('defaultValue')) {
          defaultValue = def['defaultValue'];
          hasDef = true;
        } else if (def.containsKey('default_value')) {
          defaultValue = def['default_value'];
          hasDef = true;
        }
      } catch (_) {}

      // If the current value is missing/empty, and the definition has a non-empty/non-null default value,
      // we apply the definition-based default value.
      if (hasDef && !isValueEmpty(defaultValue)) {
        value = defaultValue;
        defaulted = true;
        await store.setScopedVariable(
          botId,
          scope,
          contextId,
          storageKey,
          value,
        );
        await ensureScopedDefinitionExists(
          store: store,
          botId: botId,
          scope: scope,
          storageKey: storageKey,
          defaultValue: value,
        );
      } else if (value == null) {
        // If no non-empty default value definition exists, but value was completely null,
        // we fallback to empty string and write it.
        value = '';
        defaulted = true;
        await store.setScopedVariable(
          botId,
          scope,
          contextId,
          storageKey,
          value,
        );
      }
    }

    return (value: value, defaulted: defaulted);
  }

  Future<dynamic> readGlobal(String key) async {
    if (key.trim().isEmpty) throw ArgumentError('A variable key is required.');
    var value = await store.getGlobalVariable(botId, key);
    if (value == null) {
      value = '';
      await store.setGlobalVariable(botId, key, value);
    }
    return value;
  }

  Future<void> writeScoped({
    required String scope,
    required String contextId,
    required String key,
    required dynamic value,
  }) async {
    final storageKey = scopedStorageKey(key);
    await store.setScopedVariable(botId, scope, contextId, storageKey, value);
    await ensureScopedDefinitionExists(
      store: store,
      botId: botId,
      scope: scope,
      storageKey: storageKey,
      defaultValue: value,
    );
  }

  Future<void> writeGlobal(String key, dynamic value) async {
    if (key.trim().isEmpty) throw ArgumentError('A variable key is required.');
    await store.setGlobalVariable(botId, key, value);
  }
}
