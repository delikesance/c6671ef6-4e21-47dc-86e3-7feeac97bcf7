import 'dart:async';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_merge.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:nyxx/nyxx.dart' hide Builder;
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';

enum BotSyncStatus {
  /// Both local and cloud configurations are identical.
  inSync,

  /// Cloud has newer updates and local has no un-pushed modifications. Safe to auto-apply.
  cloudNewer,

  /// Local has edits newer than cloud or local-only items, but cloud has no new edits.
  localNewer,

  /// Both local and cloud have divergent changes (e.g. edits on both sides). Requires user decision.
  conflict,

  /// Bot doesn't exist on Cloud or is offline/unreachable.
  noRemoteConfig,

  /// Error fetching remote config (e.g. network failure).
  error,
}

class BotReconciliationCheckResult {
  const BotReconciliationCheckResult({
    required this.status,
    this.remoteConfig,
    this.diff,
    this.remoteTimestamp,
    this.localTimestamp,
    this.errorMessage,
  });

  final BotSyncStatus status;
  final Map<String, dynamic>? remoteConfig;
  final BotConfigMergeDiff? diff;
  final DateTime? remoteTimestamp;
  final DateTime? localTimestamp;
  final String? errorMessage;
}

class BotReconciliationService {
  BotReconciliationService._();

  /// Checks the synchronization status between local storage and the Cloud (Manager).
  static Future<BotReconciliationCheckResult> checkSyncStatus({
    required String botId,
    required MainApiClient client,
    AppManager? appManager,
  }) async {
    final mgr = appManager ?? AppManager();

    Map<String, dynamic> remoteConfig;
    try {
      remoteConfig = await client.getBotConfig(botId);
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('404') ||
          msg.contains('No config URL returned') ||
          msg.contains('not found')) {
        return const BotReconciliationCheckResult(
          status: BotSyncStatus.noRemoteConfig,
        );
      }
      return BotReconciliationCheckResult(
        status: BotSyncStatus.error,
        errorMessage: msg,
      );
    }

    final remoteCommands = extractCommandListFromConfig(
      remoteConfig['commands'],
    );
    final localCommands = await mgr.listAppCommands(botId, forceRefresh: true);
    final localApp = await mgr.getApp(botId);

    final diff = computeBotConfigMergeDiff(localCommands, remoteCommands);
    final remoteTs = _getRemoteMaxTimestamp(remoteConfig, remoteCommands);
    final localTs = _getLocalMaxTimestamp(localApp, localCommands);

    // Hashes comparison for exact identity
    final remoteHash = HashUtil.calculateHash(
      _canonicalizeForHash(remoteConfig),
    );
    final localHash = HashUtil.calculateHash(
      _canonicalizeLocal(localApp, localCommands),
    );

    if (remoteHash == localHash) {
      return BotReconciliationCheckResult(
        status: BotSyncStatus.inSync,
        remoteConfig: remoteConfig,
        diff: diff,
        remoteTimestamp: remoteTs,
        localTimestamp: localTs,
      );
    }

    // The remote document is authoritative regardless of local timestamps.
    return BotReconciliationCheckResult(
      status: BotSyncStatus.cloudNewer,
      remoteConfig: remoteConfig,
      diff: diff,
      remoteTimestamp: remoteTs,
      localTimestamp: localTs,
    );
  }

  /// Overwrites local state with Cloud config, preserving credentials and refreshing indexes.
  static Future<void> applyCloudToLocal({
    required String botId,
    required Map<String, dynamic> remoteConfig,
    AppManager? appManager,
  }) async {
    final mgr = appManager ?? AppManager();
    final existingApp = await mgr.getApp(botId);
    final existingToken = (existingApp['token'] ?? '').toString().trim();
    final remoteToken = (remoteConfig['token'] ?? '').toString().trim();
    final effectiveToken = remoteToken.isNotEmpty ? remoteToken : existingToken;

    // Apply commands and workflows
    await applyManagerConfigToLocal(
      appManager: mgr,
      botId: botId,
      remoteConfig: remoteConfig,
      saveAppMetadata: true,
      deleteMissingLocalCommands: true,
    );

    // Ensure all_apps.json index and token are up to date
    final username =
        (remoteConfig['username'] ??
                remoteConfig['name'] ??
                existingApp['name'] ??
                'Bot')
            .toString();
    final avatar =
        (remoteConfig['avatar'] ??
                remoteConfig['avatarPath'] ??
                existingApp['avatar'] ??
                '')
            .toString();

    final idSnowflake = (int.tryParse(botId) != null)
        ? Snowflake.parse(botId)
        : null;
    if (idSnowflake != null && effectiveToken.isNotEmpty) {
      await mgr.createOrUpdateApp(
        id: idSnowflake,
        username: username,
        token: effectiveToken,
        avatarHash: avatar.isNotEmpty ? avatar : null,
        notifyRuntime: false,
      );
    }

    await mgr.invalidatePayloadCache(botId);
  }

  /// Intelligently merges remote and local configurations without deleting items,
  /// resolves command conflicts by newest edit, and pushes the merged result to Cloud.
  static Future<void> smartMerge({
    bool pushToCloud = true,
    required String botId,
    required Map<String, dynamic> remoteConfig,
    required MainApiClient client,
    AppManager? appManager,
    String? botName,
  }) async {
    final mgr = appManager ?? AppManager();
    final endRemoteSync = AppManager.beginRemoteSync();
    try {
      await applyManagerRuntimeMetadataToLocal(
        appManager: mgr,
        botId: botId,
        remoteConfig: remoteConfig,
      );
      final localCommands = await mgr.listAppCommands(
        botId,
        forceRefresh: true,
      );
      final remoteCommands = extractCommandListFromConfig(
        remoteConfig['commands'],
      );

      final localCmdsById = <String, Map<String, dynamic>>{
        for (final cmd in localCommands)
          (cmd['id'] ?? cmd['name'] ?? '').toString(): cmd,
      };

      // 1. Merge commands:
      final commandsToImport = <Map<String, dynamic>>[];
      for (final remoteCmd in remoteCommands) {
        final id = (remoteCmd['id'] ?? remoteCmd['name'] ?? '').toString();
        if (id.isEmpty) continue;

        final localCmd = localCmdsById[id];
        if (localCmd == null) {
          // Cloud-only command: save locally
          commandsToImport.add(remoteCmd);
        } else {
          // Exists on both: compare timestamps
          final remoteUpdated = parseBotConfigTimestamp(remoteCmd['updatedAt']);
          final localUpdated = parseBotConfigTimestamp(localCmd['updatedAt']);

          if (remoteUpdated != null &&
              localUpdated != null &&
              remoteUpdated.isAfter(localUpdated)) {
            commandsToImport.add(remoteCmd);
          }
          // If local is newer or identical, local is kept
        }
      }

      await applyManagerConfigToLocal(
        appManager: mgr,
        botId: botId,
        saveAppMetadata: false,
        remoteConfig: {'commands': commandsToImport},
        deleteMissingLocalCommands: false,
      );

      // 2. Merge workflows:
      final remoteWorkflows =
          (remoteConfig['workflows'] as List?)?.whereType<Map>().toList() ?? [];
      final localApp = await mgr.getApp(botId);
      final localWorkflows =
          (localApp['workflows'] as List?)?.whereType<Map>().toList() ?? [];

      final localWfByName = <String, Map<String, dynamic>>{
        for (final wf in localWorkflows)
          (wf['name'] ?? '').toString(): Map<String, dynamic>.from(wf),
      };

      for (final rWf in remoteWorkflows) {
        final name = (rWf['name'] ?? '').toString();
        if (name.isEmpty) continue;

        if (!localWfByName.containsKey(name)) {
          await mgr.saveWorkflow(
            botId,
            name: name,
            actions: ((rWf['actions'] as List?) ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
            entryPoint: rWf['entryPoint']?.toString(),
            arguments: ((rWf['arguments'] as List?) ?? [])
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList(),
            workflowType: rWf['workflowType']?.toString(),
            eventTrigger: rWf['eventTrigger'] != null
                ? Map<String, dynamic>.from(rWf['eventTrigger'] as Map)
                : null,
            folder: rWf['folder']?.toString(),
            executionMode: rWf['executionMode']?.toString(),
            jsScriptContent: rWf['jsScriptContent']?.toString(),
            eventVariableAliases: (rWf['eventVariableAliases'] as Map?)
                ?.cast<String, String>(),
          );
        }
      }

      // 3. Merge global variables:
      final remoteGlobals =
          (remoteConfig['globalVariables'] as Map?)?.cast<String, dynamic>() ??
          {};
      for (final entry in remoteGlobals.entries) {
        final localVal = await mgr.getGlobalVariable(botId, entry.key);
        if (localVal == null) {
          await mgr.setGlobalVariable(botId, entry.key, entry.value);
        }
      }

      await mgr.invalidatePayloadCache(botId);
      if (!pushToCloud) return;

      // 4. Push the unified merged payload back to Cloud
      final mergedPayload = await buildRemotePayload(botId);
      final effectiveName =
          botName ??
          (localApp['username'] ??
                  localApp['name'] ??
                  remoteConfig['username'] ??
                  'Bot')
              .toString();

      await client.syncBot(botId, effectiveName, mergedPayload, force: true);
    } finally {
      endRemoteSync();
    }
  }

  /// Keeps local configuration and overwrites Cloud with local data.
  static Future<void> keepLocalAndPushToCloud({
    required String botId,
    required MainApiClient client,
    String? botName,
    AppManager? appManager,
  }) async {
    final mgr = appManager ?? AppManager();
    final payload = await buildRemotePayload(botId);
    final app = await mgr.getApp(botId);
    final effectiveName =
        botName ?? (app['username'] ?? app['name'] ?? 'Bot').toString();

    await client.syncBot(botId, effectiveName, payload, force: true);
  }

  static DateTime? _getRemoteMaxTimestamp(
    Map<String, dynamic> config,
    List<Map<String, dynamic>> commands,
  ) {
    DateTime? latest;
    for (final cmd in commands) {
      final t = parseBotConfigTimestamp(cmd['updatedAt']);
      if (t != null && (latest == null || t.isAfter(latest))) {
        latest = t;
      }
    }
    final configTs = parseBotConfigTimestamp(
      config['updatedAt'] ?? config['savedAt'],
    );
    if (configTs != null && (latest == null || configTs.isAfter(latest))) {
      latest = configTs;
    }
    return latest;
  }

  static DateTime? _getLocalMaxTimestamp(
    Map<String, dynamic> app,
    List<Map<String, dynamic>> commands,
  ) {
    DateTime? latest;
    for (final cmd in commands) {
      final t = parseBotConfigTimestamp(cmd['updatedAt']);
      if (t != null && (latest == null || t.isAfter(latest))) {
        latest = t;
      }
    }
    final appTs = parseBotConfigTimestamp(app['updatedAt'] ?? app['savedAt']);
    if (appTs != null && (latest == null || appTs.isAfter(latest))) {
      latest = appTs;
    }
    return latest;
  }

  static Map<String, dynamic> _canonicalizeForHash(
    Map<String, dynamic> config,
  ) {
    final commands = extractCommandListFromConfig(
      config['commands'],
    ).map(normalizeCommandData).toList();
    final workflows =
        (config['workflows'] as List?)?.whereType<Map>().toList() ?? [];
    return {
      'commands':
          commands
              .map(
                (command) => HashUtil.calculateHash({
                  'id': command['id'] ?? command['commandId'],
                  'name': command['name'],
                  'description': command['description'] ?? '',
                  'updatedAt': command['updatedAt'],
                  'enabled': command['enabled'] ?? true,
                  'data': command['data'] ?? {},
                }),
              )
              .toList()
            ..sort(),
      'workflows':
          workflows
              .map(
                (workflow) => HashUtil.calculateHash({
                  for (final entry in workflow.entries)
                    if (entry.key != 'createdAt' && entry.key != 'updatedAt')
                      entry.key: entry.value,
                }),
              )
              .toList()
            ..sort(),
      'globals': config['globalVariables'] ?? {},
    };
  }

  static Map<String, dynamic> _canonicalizeLocal(
    Map<String, dynamic> app,
    List<Map<String, dynamic>> commands,
  ) => _canonicalizeForHash({...app, 'commands': commands});
}
