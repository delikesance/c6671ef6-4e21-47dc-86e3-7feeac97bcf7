import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_kind.dart';
import 'package:bot_creator/core/runner/embedded_js_runner_service.dart';
import 'package:bot_creator/core/secure/secure_storage_service.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A single runner connection configuration.
class RunnerConnectionConfig {
  const RunnerConnectionConfig({
    required this.id,
    required this.url,
    this.apiToken,
    this.name,
    this.kind = RunnerKind.auto,
    this.useEmbedded = false,
  });

  /// Unique identifier for this runner entry.
  final String id;

  final String url;
  final String? apiToken;

  /// Optional human-readable label (e.g. "Production", "Dev Server").
  final String? name;
  final RunnerKind kind;
  final bool useEmbedded;

  RunnerClient createClient({Duration? getTimeout, Duration? postTimeout}) {
    return RunnerClient(
      baseUrl: url,
      apiToken: apiToken,
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  Map<String, dynamic> toJson({bool includeToken = false}) => {
    'id': id,
    'url': url,
    if (includeToken && apiToken != null) 'apiToken': apiToken,
    if (name != null) 'name': name,
    'kind': kind.toJson(),
    'useEmbedded': useEmbedded,
  };

  factory RunnerConnectionConfig.fromJson(Map<String, dynamic> json) {
    return RunnerConnectionConfig(
      id: (json['id'] ?? '').toString(),
      url: (json['url'] ?? '').toString(),
      apiToken: _normalize(json['apiToken']?.toString()),
      name: _normalize(json['name']?.toString()),
      kind: RunnerKind.fromJson(json['kind']?.toString()),
      useEmbedded: json['useEmbedded'] == true,
    );
  }
}

/// Manages a registry of runner connections with an active runner selection.
///
/// Non-sensitive metadata is stored in SharedPreferences. API tokens are stored
/// in [SecureStorageService] under `runner_api_token:<id>`.
class RunnerSettings {
  RunnerSettings._();

  // Legacy keys (singleton format)
  static const _keyUrl = 'developer_runner_url';
  static const _keyApiToken = 'developer_runner_api_token';

  // Multi-runner keys
  static const _keyRegistry = 'runner_registry';
  static const _keyActiveId = 'runner_active_id';
  static const _keyTemporarilyDisabled = 'runner_temporarily_disabled';
  static const _keyBotAssociations = 'runner_bot_associations';

  static String _tokenStorageKey(String runnerId) => 'runner_api_token:$runnerId';

  /// In-memory association of botId to runnerId.
  static final Map<String, String> _botRunnerAssociation = <String, String>{};

  /// Associates a bot with a specific runner ID.
  static void associateBotWithRunner(String botId, String runnerId) {
    _botRunnerAssociation[botId] = runnerId;
    unawaited(_saveAssociations());
  }

  /// Returns the runner ID associated with a bot, if known.
  static String? getAssociatedRunnerId(String botId) {
    return _botRunnerAssociation[botId];
  }

  static Future<void> _saveAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyBotAssociations, jsonEncode(_botRunnerAssociation));
    } catch (_) {}
  }

  static Future<void> loadAssociations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyBotAssociations);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map;
        _botRunnerAssociation.clear();
        for (final entry in decoded.entries) {
          _botRunnerAssociation[entry.key.toString()] = entry.value.toString();
        }
      }
    } catch (_) {}
  }

  /// Returns true if runner usage is temporarily disabled.
  static Future<bool> isTemporarilyDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTemporarilyDisabled) ?? false;
  }

  /// Temporarily enables/disables runner usage while preserving stored config.
  static Future<void> setTemporarilyDisabled(bool disabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTemporarilyDisabled, disabled);
  }

  /// Returns all registered runners.
  static Future<List<RunnerConnectionConfig>> getRunners() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);
    final raw = prefs.getString(_keyRegistry);
    if (raw == null) return [];
    final runners = _decodeRegistry(raw);
    await _migrateRegistryTokens(prefs, runners);
    return _hydrateRunnerTokens(runners);
  }

  /// Returns the active runner ID, or `null` if none is selected.
  static Future<String?> getActiveId() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);
    return prefs.getString(_keyActiveId);
  }

  /// Returns the active runner config, or `null` if none is configured.
  static Future<RunnerConnectionConfig?> getConfig() async {
    if (await isTemporarilyDisabled()) {
      return null;
    }
    return _hydrateStoredConfig(await getStoredConfig());
  }

  /// Resolves the best runner config for a specific bot.
  ///
  /// JavaScript bots on desktop fall back to the embedded JS runner when no
  /// external runner is configured.
  static Future<RunnerConnectionConfig?> resolveConfigForBot(String botId) async {
    if (await isTemporarilyDisabled()) {
      return null;
    }

    final engine = await getBotRuntimeEngine(botId);
    final isJavascriptBot = engine == runtimeEngineJavascript;

    if (isJavascriptBot && !kIsWeb && _isDesktopPlatform) {
      final embedded = await prepareEmbeddedJsRunner();
      if (embedded != null) {
        return embedded;
      }
    }

    final associatedId = getAssociatedRunnerId(botId);
    if (associatedId != null && associatedId != 'local') {
      final runners = await getRunners();
      final match = runners.where((r) => r.id == associatedId);
      if (match.isNotEmpty) {
        final candidate = match.first;
        if (!isJavascriptBot || _supportsJavascriptRunner(candidate)) {
          final hydrated = await _hydrateStoredConfig(candidate);
          if (hydrated != null) {
            return hydrated;
          }
        }
      }
    }

    final stored = await getStoredConfig();
    if (stored != null) {
      if (!isJavascriptBot || _supportsJavascriptRunner(stored)) {
        final hydrated = await _hydrateStoredConfig(stored);
        if (hydrated != null) {
          return hydrated;
        }
      }
    }

    if (isJavascriptBot && !kIsWeb && _isDesktopPlatform) {
      return prepareEmbeddedJsRunner();
    }

    return null;
  }

  /// Starts the embedded JS runner on desktop and registers it locally so the
  /// app can use it without a manual Settings toggle.
  static Future<RunnerConnectionConfig?> prepareEmbeddedJsRunner() async {
    if (kIsWeb || !_isDesktopPlatform) {
      return null;
    }

    final embedded = await EmbeddedJsRunnerService.instance.ensureConfig();
    if (embedded == null) {
      return null;
    }

    await _persistEmbeddedRunnerAvailability(embedded);
    return embedded;
  }

  static Future<void> _persistEmbeddedRunnerAvailability(
    RunnerConnectionConfig embedded,
  ) async {
    final runners = await getRunners();
    final hasEmbedded = runners.any(
      (runner) => runner.useEmbedded || runner.id == embedded.id,
    );
    if (!hasEmbedded) {
      await addRunner(embedded);
    }

    final activeId = await getActiveId();
    if ((activeId ?? '').isEmpty) {
      await setActiveRunner(embedded.id);
    }
  }

  static bool supportsJavascriptRunner(RunnerConnectionConfig config) {
    return _supportsJavascriptRunner(config);
  }

  static bool _supportsJavascriptRunner(RunnerConnectionConfig config) {
    return config.useEmbedded ||
        config.kind == RunnerKind.javascript ||
        config.kind == RunnerKind.auto;
  }

  static bool get _isDesktopPlatform {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.windows || TargetPlatform.linux || TargetPlatform.macOS =>
        true,
      _ => false,
    };
  }

  static Future<RunnerConnectionConfig?> _hydrateStoredConfig(
    RunnerConnectionConfig? stored,
  ) async {
    if (stored == null) {
      return null;
    }
    if (stored.useEmbedded && !kIsWeb) {
      final embedded = await EmbeddedJsRunnerService.instance.ensureConfig();
      if (embedded != null) {
        return embedded;
      }
    }
    return stored;
  }

  /// Returns the stored active runner config even if temporarily disabled.
  static Future<RunnerConnectionConfig?> getStoredConfig() async {
    final runners = await getRunners();
    if (runners.isEmpty) return null;
    final activeId = await getActiveId();
    if (activeId != null) {
      final match = runners.where((r) => r.id == activeId);
      if (match.isNotEmpty) return match.first;
    }
    // Fallback to first runner if active ID is stale
    return runners.first;
  }

  /// Creates a [RunnerClient] for the active runner, or `null` if none is
  /// configured.
  static Future<RunnerClient?> createClient({
    Duration? getTimeout,
    Duration? postTimeout,
  }) async {
    final config = await getConfig();
    return config?.createClient(
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  /// Creates a [RunnerClient] for the runner associated with the bot,
  /// or falls back to the active runner if no association exists.
  static Future<RunnerClient?> createClientForBot(
    String botId, {
    Duration? getTimeout,
    Duration? postTimeout,
  }) async {
    final engine = await getBotRuntimeEngine(botId);
    final isJavascriptBot = engine == runtimeEngineJavascript;

    final associatedId = _botRunnerAssociation[botId];
    if (associatedId != null) {
      final runners = await getRunners();
      final match = runners.where((r) => r.id == associatedId);
      if (match.isNotEmpty) {
        final candidate = match.first;
        if (!isJavascriptBot || _supportsJavascriptRunner(candidate)) {
          final hydrated = await _hydrateStoredConfig(candidate);
          return hydrated?.createClient(
            getTimeout: getTimeout,
            postTimeout: postTimeout,
          );
        }
      }
    }
    final config = await resolveConfigForBot(botId);
    return config?.createClient(
      getTimeout: getTimeout,
      postTimeout: postTimeout,
    );
  }

  /// Returns the saved runner URL of the active runner, or `null`.
  static Future<String?> getUrl() async => (await getConfig())?.url;

  /// Returns the API token of the active runner, or `null`.
  static Future<String?> getApiToken() async => (await getConfig())?.apiToken;

  /// Adds or updates a runner in the registry.
  ///
  /// If a runner with the same [config.id] already exists, it is replaced.
  /// If this is the first runner, it automatically becomes the active one.
  static Future<void> addRunner(RunnerConnectionConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);
    final runners = await _hydrateRunnerTokens(_decodeRegistry(prefs.getString(_keyRegistry)));
    runners.removeWhere((r) => r.id == config.id);
    runners.add(config);
    await _persistRunner(config);
    await _saveRegistry(prefs, runners, includeTokens: false);

    // Auto-select if it's the only runner or no active selection
    final currentActive = prefs.getString(_keyActiveId);
    if (currentActive == null || runners.length == 1) {
      await prefs.setString(_keyActiveId, config.id);
    }
  }

  /// Removes a runner from the registry by [id].
  ///
  /// If the removed runner was active, the first remaining runner (if any)
  /// becomes active.
  static Future<void> removeRunner(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacy(prefs);
    final runners = await _hydrateRunnerTokens(_decodeRegistry(prefs.getString(_keyRegistry)));
    runners.removeWhere((r) => r.id == id);
    await _deleteRunnerToken(id);
    await _saveRegistry(prefs, runners, includeTokens: false);

    if (prefs.getString(_keyActiveId) == id) {
      if (runners.isNotEmpty) {
        await prefs.setString(_keyActiveId, runners.first.id);
      } else {
        await prefs.remove(_keyActiveId);
      }
    }
  }

  /// Sets the active runner by [id]. The runner must already be registered.
  static Future<void> setActiveRunner(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveId, id);
  }

  /// Backward-compatible save: updates the active runner, or creates one.
  static Future<void> save({
    String? url,
    String? apiToken,
    RunnerKind? kind,
    bool? useEmbedded,
  }) async {
    if (useEmbedded == true) {
      final config = await getStoredConfig();
      final id = config?.id ?? _generateId();
      await addRunner(
        RunnerConnectionConfig(
          id: id,
          url: config?.url ?? 'http://127.0.0.1:18080',
          apiToken: config?.apiToken,
          name: config?.name ?? 'Embedded JS Runner',
          kind: kind ?? RunnerKind.javascript,
          useEmbedded: true,
        ),
      );
      return;
    }

    final normalizedUrl = _normalize(url);
    if (normalizedUrl == null) {
      // Clear all runners
      await clear();
      return;
    }

    final config = await getStoredConfig();
    final id = config?.id ?? _generateId();
    await addRunner(
      RunnerConnectionConfig(
        id: id,
        url: normalizedUrl,
        apiToken: _normalize(apiToken),
        name: config?.name,
        kind: kind ?? config?.kind ?? RunnerKind.auto,
        useEmbedded: useEmbedded ?? config?.useEmbedded ?? false,
      ),
    );
  }

  /// Backward-compatible helper.
  static Future<void> setUrl(String? url) async {
    await save(url: url, apiToken: await getApiToken());
  }

  /// Backward-compatible helper.
  static Future<void> setApiToken(String? apiToken) async {
    await save(url: await getUrl(), apiToken: apiToken);
  }

  /// Clears the entire runner registry.
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final runners = await _hydrateRunnerTokens(_decodeRegistry(prefs.getString(_keyRegistry)));
    for (final runner in runners) {
      await _deleteRunnerToken(runner.id);
    }
    await prefs.remove(_keyRegistry);
    await prefs.remove(_keyActiveId);
    await prefs.remove(_keyTemporarilyDisabled);
    // Also clean up legacy keys
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyApiToken);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  static Future<List<RunnerConnectionConfig>> _hydrateRunnerTokens(
    List<RunnerConnectionConfig> runners,
  ) async {
    if (runners.isEmpty) {
      return runners;
    }
    try {
      final secure = await SecureStorageService.instance;
      final hydrated = <RunnerConnectionConfig>[];
      for (final runner in runners) {
        final storedToken = await secure.read(_tokenStorageKey(runner.id));
        hydrated.add(
          RunnerConnectionConfig(
            id: runner.id,
            url: runner.url,
            apiToken: _normalize(storedToken) ?? runner.apiToken,
            name: runner.name,
            kind: runner.kind,
            useEmbedded: runner.useEmbedded,
          ),
        );
      }
      return hydrated;
    } catch (_) {
      return runners;
    }
  }

  static Future<void> _persistRunner(RunnerConnectionConfig config) async {
    try {
      final secure = await SecureStorageService.instance;
      final token = _normalize(config.apiToken);
      if (token == null) {
        await secure.delete(_tokenStorageKey(config.id));
      } else {
        await secure.write(_tokenStorageKey(config.id), token);
      }
    } catch (_) {}
  }

  static Future<void> _deleteRunnerToken(String runnerId) async {
    try {
      final secure = await SecureStorageService.instance;
      await secure.delete(_tokenStorageKey(runnerId));
    } catch (_) {}
  }

  static Future<void> _migrateRegistryTokens(
    SharedPreferences prefs,
    List<RunnerConnectionConfig> runners,
  ) async {
    var containsLegacyTokens = false;
    for (final runner in runners) {
      if (runner.apiToken != null) {
        containsLegacyTokens = true;
        await _persistRunner(runner);
      }
    }
    if (!containsLegacyTokens) {
      return;
    }

    final sanitized = runners
        .map(
          (runner) => RunnerConnectionConfig(
            id: runner.id,
            url: runner.url,
            name: runner.name,
            kind: runner.kind,
            useEmbedded: runner.useEmbedded,
          ),
        )
        .toList(growable: false);
    await _saveRegistry(prefs, sanitized, includeTokens: false);
  }

  /// Migrates the old singleton format into the registry (once).
  static Future<void> _migrateLegacy(SharedPreferences prefs) async {
    // If registry already exists, skip migration
    if (prefs.containsKey(_keyRegistry)) return;

    final legacyUrl = _normalize(prefs.getString(_keyUrl));
    if (legacyUrl == null) return;

    final legacyToken = _normalize(prefs.getString(_keyApiToken));
    final id = _generateId();
    final config = RunnerConnectionConfig(
      id: id,
      url: legacyUrl,
      apiToken: legacyToken,
      name: 'Default',
    );

    await _persistRunner(config);
    await _saveRegistry(prefs, [config], includeTokens: false);
    await prefs.setString(_keyActiveId, config.id);
    // Remove legacy keys after successful migration
    await prefs.remove(_keyUrl);
    await prefs.remove(_keyApiToken);
  }

  static List<RunnerConnectionConfig> _decodeRegistry(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map(
            (e) =>
                RunnerConnectionConfig.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((c) => c.url.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveRegistry(
    SharedPreferences prefs,
    List<RunnerConnectionConfig> runners, {
    required bool includeTokens,
  }) async {
    final json = jsonEncode(
      runners.map((r) => r.toJson(includeToken: includeTokens)).toList(),
    );
    await prefs.setString(_keyRegistry, json);

    if (includeTokens) {
      for (final runner in runners) {
        await _persistRunner(runner);
      }
    }
  }

  static String _generateId() {
    // Simple timestamp-based ID, sufficient for a small local registry
    return DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  }
}

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
