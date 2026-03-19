/// Abstract interface over bot data storage.
/// Both [AppManager] (Flutter app) and [RunnerDataStore] (CLI runner) implement this.
abstract class BotDataStore {
  /// Returns all global variables for [botId] with typed values (string|number).
  Future<Map<String, dynamic>> getGlobalVariables(String botId);

  /// Returns a single global variable value, or null if not set.
  Future<dynamic> getGlobalVariable(String botId, String key);

  /// Persists or updates a global variable.
  Future<void> setGlobalVariable(String botId, String key, dynamic value);

  /// Renames a global variable key.
  Future<void> renameGlobalVariable(String botId, String oldKey, String newKey);

  /// Removes a global variable.
  Future<void> removeGlobalVariable(String botId, String key);

  /// Returns scoped variables for [scope] and [contextId].
  Future<Map<String, dynamic>> getScopedVariables(
    String botId,
    String scope,
    String contextId,
  );

  /// Returns a single scoped variable.
  Future<dynamic> getScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  );

  /// Persists or updates a scoped variable.
  Future<void> setScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
    dynamic value,
  );

  /// Renames a scoped variable key.
  Future<void> renameScopedVariable(
    String botId,
    String scope,
    String contextId,
    String oldKey,
    String newKey,
  );

  /// Removes a scoped variable.
  Future<void> removeScopedVariable(
    String botId,
    String scope,
    String contextId,
    String key,
  );

  /// Finds a workflow by name (case-insensitive), or null if not found.
  Future<Map<String, dynamic>?> getWorkflowByName(String botId, String name);
}
