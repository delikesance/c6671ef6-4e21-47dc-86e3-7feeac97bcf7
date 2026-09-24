import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

List<Map<String, dynamic>> extractCommandListFromConfig(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  if (raw is Map) {
    return raw.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e.cast<String, dynamic>()))
        .toList(growable: false);
  }
  return const <Map<String, dynamic>>[];
}

String localCommandTypeFromRemote(
  Map<String, dynamic> cmd,
  Map<String, dynamic> cmdData,
) {
  final raw = (cmdData['commandType'] ?? cmd['type'] ?? 'chatInput')
      .toString()
      .trim();
  switch (raw.toLowerCase()) {
    case 'command':
    case 'chatinput':
    case 'chat_input':
    case 'chat-input':
    case 'slash':
      return 'chatInput';
    case 'user':
    case 'usercommand':
    case 'user_command':
      return 'user';
    case 'message':
    case 'messagecommand':
    case 'message_command':
      return 'message';
    default:
      return 'chatInput';
  }
}

/// Overwrites local commands and workflows from a Manager config payload.
Future<void> applyManagerConfigToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
  bool saveAppMetadata = true,
  bool deleteMissingLocalCommands = false,
}) async {
  AppManager.isSyncingFromRemote = true;
  try {
    if (saveAppMetadata) {
      final existingApp = await appManager.getApp(botId);
      final merged = Map<String, dynamic>.from(existingApp)
        ..addAll(remoteConfig);

      // Guard runtime engine against unintended mutation or null erasure
      final remoteEngine = (remoteConfig['runtimeEngine'] ?? '')
          .toString()
          .trim();
      final localEngine = (existingApp['runtimeEngine'] ?? '')
          .toString()
          .trim();
      if (remoteEngine.isNotEmpty) {
        merged['runtimeEngine'] = normalizeRuntimeEngine(remoteEngine);
      } else if (localEngine.isNotEmpty) {
        merged['runtimeEngine'] = normalizeRuntimeEngine(localEngine);
      }

      await appManager.saveApp(botId, merged);
    }

    final remoteCommands = extractCommandListFromConfig(
      remoteConfig['commands'],
    );
    final remoteCommandIds = <String>{};
    for (final cmd in remoteCommands) {
      final cmdId = (cmd['id'] ?? cmd['commandId'] ?? '').toString();
      final cmdName = (cmd['name'] ?? '').toString();
      if (cmdId.isEmpty || cmdName.isEmpty) {
        continue;
      }
      remoteCommandIds.add(cmdId);

      final localCmd = await appManager.getAppCommand(botId, cmdId);
      final cmdData = Map<String, dynamic>.from(cmd['data'] ?? cmd);
      if (cmdData['response'] is Map &&
          (cmdData['response'] as Map).containsKey('_migrated')) {
        cmdData.remove('response');
      }
      cmdData.remove('simpleConfig');

      // Preserve folder hierarchy from remote command, command data, or local copy
      final rawFolder =
          (cmd['folder'] ?? cmdData['folder'] ?? localCmd['folder'] ?? '')
              .toString()
              .trim();

      await appManager.saveAppCommand(botId, cmdId, <String, dynamic>{
        'name': cmdName,
        'description': (cmd['description'] ?? '').toString(),
        'type': localCommandTypeFromRemote(cmd, cmdData),
        'id': cmdId,
        'data': cmdData,
        if (rawFolder.isNotEmpty) 'folder': rawFolder,
        'createdAt': (localCmd['createdAt'] ?? DateTime.now().toIso8601String())
            .toString(),
        'updatedAt': (cmd['updatedAt'] ?? DateTime.now().toIso8601String())
            .toString(),
      });
    }

    if (deleteMissingLocalCommands) {
      final localCommands = await appManager.listAppCommands(botId);
      for (final localCmd in localCommands) {
        final localCmdId = (localCmd['id'] ?? '').toString();
        if (localCmdId.isNotEmpty && !remoteCommandIds.contains(localCmdId)) {
          await appManager.deleteAppCommand(botId, localCmdId);
        }
      }
    }

    await applyManagerWorkflowsToLocal(
      appManager: appManager,
      botId: botId,
      remoteConfig: remoteConfig,
      deleteMissingLocalWorkflows: deleteMissingLocalCommands,
    );
  } finally {
    AppManager.isSyncingFromRemote = false;
  }
}

Future<void> applyManagerWorkflowsToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
  bool deleteMissingLocalWorkflows = false,
}) async {
  final remoteWorkflows = remoteConfig['workflows'];
  final remoteWorkflowNames = <String>{};
  if (remoteWorkflows is List) {
    for (final wf in remoteWorkflows) {
      if (wf is! Map) {
        continue;
      }
      final wfName = (wf['name'] ?? '').toString();
      if (wfName.isEmpty) {
        continue;
      }
      remoteWorkflowNames.add(wfName);

      await appManager.saveWorkflow(
        botId,
        name: wfName,
        actions: ((wf['actions'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        entryPoint: wf['entryPoint']?.toString(),
        arguments: ((wf['arguments'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        workflowType: wf['workflowType']?.toString(),
        eventTrigger: wf['eventTrigger'] != null
            ? Map<String, dynamic>.from(wf['eventTrigger'] as Map)
            : null,
        folder: wf['folder']?.toString(),
        eventVariableAliases: wf['eventVariableAliases'] is Map
            ? Map<String, String>.from(
                (wf['eventVariableAliases'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : null,
        executionMode: wf['executionMode']?.toString(),
        jsScriptContent: wf['jsScriptContent']?.toString(),
      );
    }
  }

  if (deleteMissingLocalWorkflows) {
    final localApp = await appManager.getApp(botId);
    final localWorkflows =
        (localApp['workflows'] as List?)?.whereType<Map>().toList() ?? [];
    for (final wf in localWorkflows) {
      final wfName = (wf['name'] ?? '').toString();
      if (wfName.isNotEmpty && !remoteWorkflowNames.contains(wfName)) {
        await appManager.deleteWorkflow(botId, wfName);
      }
    }
  }
}
