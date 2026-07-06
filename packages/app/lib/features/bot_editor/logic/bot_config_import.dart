import 'package:bot_creator/core/storage/database.dart';

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
  final raw =
      (cmdData['commandType'] ?? cmd['type'] ?? 'chatInput').toString().trim();
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
}) async {
  AppManager.isSyncingFromRemote = true;
  try {
    if (saveAppMetadata) {
      await appManager.saveApp(botId, remoteConfig);
    }

    final remoteCommands = extractCommandListFromConfig(remoteConfig['commands']);
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

      await appManager.saveAppCommand(botId, cmdId, <String, dynamic>{
        'name': cmdName,
        'description': (cmd['description'] ?? '').toString(),
        'type': localCommandTypeFromRemote(cmd, cmdData),
        'id': cmdId,
        'data': cmdData,
        'createdAt':
            (localCmd['createdAt'] ?? DateTime.now().toIso8601String())
                .toString(),
        'updatedAt':
            (cmd['updatedAt'] ?? DateTime.now().toIso8601String()).toString(),
      });
    }

    final localCommands = await appManager.listAppCommands(botId);
    for (final localCmd in localCommands) {
      final localCmdId = (localCmd['id'] ?? '').toString();
      if (localCmdId.isNotEmpty && !remoteCommandIds.contains(localCmdId)) {
        await appManager.deleteAppCommand(botId, localCmdId);
      }
    }

    await applyManagerWorkflowsToLocal(
      appManager: appManager,
      botId: botId,
      remoteConfig: remoteConfig,
    );
  } finally {
    AppManager.isSyncingFromRemote = false;
  }
}

Future<void> applyManagerWorkflowsToLocal({
  required AppManager appManager,
  required String botId,
  required Map<String, dynamic> remoteConfig,
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
      );
    }
  }

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
