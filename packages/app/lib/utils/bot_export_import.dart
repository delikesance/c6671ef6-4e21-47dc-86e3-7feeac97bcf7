import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/utils/normalize_command_data.dart';
import 'package:bot_creator/utils/workflow_call.dart';

/// Manifest schema version for export compatibility.
const int _manifestVersion = 1;

/// Sections that can be exported/imported.
enum ExportSection { commands, workflows, status, globalVariables }

/// Builds a ZIP archive containing selected sections of a bot's data.
///
/// The ZIP structure:
/// ```
/// manifest.json
/// commands/{commandId}.json   (if commands selected)
/// workflows.json              (if workflows selected)
/// status.json                 (if status selected)
/// global_variables.json       (if globalVariables selected)
/// ```
///
/// The bot token is NEVER included in the export.
Future<Uint8List> exportBot(
  String botId, {
  Set<ExportSection> sections = const {
    ExportSection.commands,
    ExportSection.workflows,
    ExportSection.status,
    ExportSection.globalVariables,
  },
  Set<String>? commandIds,
  Set<String>? workflowNames,
}) async {
  final archive = Archive();
  final appData = await appManager.getApp(botId);

  final manifest = <String, dynamic>{
    'version': _manifestVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'sections': sections.map((s) => s.name).toList(),
  };

  // Commands
  if (sections.contains(ExportSection.commands)) {
    final commands = await appManager.listAppCommands(botId);
    final selectedCommands =
        commandIds != null
            ? commands.where(
              (c) => commandIds.contains((c['id'] ?? '').toString()),
            )
            : commands;

    for (final cmd in selectedCommands) {
      final id = (cmd['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final full = await appManager.getAppCommand(botId, id);
      if (full.isEmpty) continue;
      // Strip token if somehow present
      final sanitized = Map<String, dynamic>.from(full)..remove('token');
      final json = const JsonEncoder.withIndent('  ').convert(sanitized);
      archive.addFile(
        ArchiveFile.bytes('commands/$id.json', utf8.encode(json)),
      );
    }
    manifest['commandCount'] = selectedCommands.length;
  }

  // Workflows
  if (sections.contains(ExportSection.workflows)) {
    final workflows = await appManager.getWorkflows(botId);
    final selectedWorkflows =
        workflowNames != null
            ? workflows.where(
              (w) => workflowNames.contains((w['name'] ?? '').toString()),
            )
            : workflows;
    final list = selectedWorkflows.toList();
    final json = const JsonEncoder.withIndent('  ').convert(list);
    archive.addFile(ArchiveFile.bytes('workflows.json', utf8.encode(json)));
    manifest['workflowCount'] = list.length;
  }

  // Status (statuses + activities, but NOT token)
  if (sections.contains(ExportSection.status)) {
    final statusPayload = <String, dynamic>{
      'statuses': appData['statuses'] ?? [],
      'activities': appData['activities'] ?? [],
    };
    final json = const JsonEncoder.withIndent('  ').convert(statusPayload);
    archive.addFile(ArchiveFile.bytes('status.json', utf8.encode(json)));
  }

  // Global variables (definitions + values)
  if (sections.contains(ExportSection.globalVariables)) {
    final globalVars = await appManager.getGlobalVariables(botId);
    final json = const JsonEncoder.withIndent('  ').convert(globalVars);
    archive.addFile(
      ArchiveFile.bytes('global_variables.json', utf8.encode(json)),
    );
  }

  // Manifest
  final manifestJson = const JsonEncoder.withIndent('  ').convert(manifest);
  archive.addFile(
    ArchiveFile.bytes('manifest.json', utf8.encode(manifestJson)),
  );

  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded);
}

/// Result of parsing an exported ZIP for preview.
class ImportPreview {
  final int manifestVersion;
  final List<Map<String, dynamic>> commands;
  final List<Map<String, dynamic>> workflows;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? globalVariables;

  const ImportPreview({
    required this.manifestVersion,
    required this.commands,
    required this.workflows,
    this.status,
    this.globalVariables,
  });

  bool get hasCommands => commands.isNotEmpty;
  bool get hasWorkflows => workflows.isNotEmpty;
  bool get hasStatus => status != null;
  bool get hasGlobalVariables =>
      globalVariables != null && globalVariables!.isNotEmpty;
}

/// Conflict resolution strategy for a single item.
enum ConflictResolution { overwrite, skip }

/// Parses a ZIP archive and returns a preview of its contents.
ImportPreview parseExportZip(Uint8List zipBytes) {
  final archive = ZipDecoder().decodeBytes(zipBytes);

  // Read manifest
  final manifestFile = archive.findFile('manifest.json');
  int version = 1;
  if (manifestFile != null) {
    final manifestJson = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    version = (manifest['version'] as int?) ?? 1;
  }

  // Read commands
  final commands = <Map<String, dynamic>>[];
  for (final file in archive.files) {
    if (file.name.startsWith('commands/') && file.name.endsWith('.json')) {
      try {
        final json = utf8.decode(file.content as List<int>);
        final cmd = Map<String, dynamic>.from(jsonDecode(json) as Map);
        commands.add(normalizeCommandData(cmd));
      } catch (_) {}
    }
  }

  // Read workflows
  var workflows = <Map<String, dynamic>>[];
  final workflowsFile = archive.findFile('workflows.json');
  if (workflowsFile != null) {
    try {
      final json = utf8.decode(workflowsFile.content as List<int>);
      final list = jsonDecode(json) as List;
      workflows =
          list
              .whereType<Map>()
              .map(
                (w) => normalizeStoredWorkflowDefinition(
                  Map<String, dynamic>.from(w),
                ),
              )
              .toList();
    } catch (_) {}
  }

  // Read status
  Map<String, dynamic>? status;
  final statusFile = archive.findFile('status.json');
  if (statusFile != null) {
    try {
      final json = utf8.decode(statusFile.content as List<int>);
      status = Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {}
  }

  // Read global variables
  Map<String, dynamic>? globalVars;
  final globalVarsFile = archive.findFile('global_variables.json');
  if (globalVarsFile != null) {
    try {
      final json = utf8.decode(globalVarsFile.content as List<int>);
      globalVars = Map<String, dynamic>.from(jsonDecode(json) as Map);
    } catch (_) {}
  }

  return ImportPreview(
    manifestVersion: version,
    commands: commands,
    workflows: workflows,
    status: status,
    globalVariables: globalVars,
  );
}

/// Imports selected sections from a parsed export into a bot.
///
/// [commandResolutions] maps command name (lowercase) to resolution.
/// Commands not in the map are auto-imported (no local conflict).
///
/// [workflowResolutions] maps workflow name to resolution.
/// Workflows not in the map are auto-imported.
Future<ImportResult> importBot(
  String botId, {
  required ImportPreview preview,
  bool importCommands = true,
  bool importWorkflows = true,
  bool importStatus = true,
  bool importGlobalVariables = true,
  Map<String, ConflictResolution> commandResolutions = const {},
  Map<String, ConflictResolution> workflowResolutions = const {},
}) async {
  int commandsImported = 0;
  int commandsSkipped = 0;
  int workflowsImported = 0;
  int workflowsSkipped = 0;

  // Import commands
  if (importCommands && preview.hasCommands) {
    final existingCommands = await appManager.listAppCommands(botId);
    final existingByName = <String, Map<String, dynamic>>{};
    for (final cmd in existingCommands) {
      final name = (cmd['name'] ?? '').toString().toLowerCase();
      if (name.isNotEmpty) existingByName[name] = cmd;
    }

    for (final cmd in preview.commands) {
      final name = (cmd['name'] ?? '').toString();
      final nameLower = name.toLowerCase();
      final existing = existingByName[nameLower];

      if (existing != null) {
        final resolution = commandResolutions[nameLower];
        if (resolution == null || resolution == ConflictResolution.skip) {
          commandsSkipped++;
          continue;
        }
        // Overwrite: use existing command's ID
        final existingId = (existing['id'] ?? '').toString();
        final sanitized = Map<String, dynamic>.from(cmd)..remove('token');
        sanitized['id'] = existingId;
        await appManager.saveAppCommand(botId, existingId, sanitized);
        commandsImported++;
      } else {
        // New command — assign a local ID
        final localId = DateTime.now().microsecondsSinceEpoch.toString();
        final sanitized = Map<String, dynamic>.from(cmd)..remove('token');
        sanitized['id'] = localId;
        await appManager.saveAppCommand(botId, localId, sanitized);
        commandsImported++;
      }
    }
  }

  // Import workflows
  if (importWorkflows && preview.hasWorkflows) {
    final existingWorkflows = await appManager.getWorkflows(botId);
    final existingByName = <String, Map<String, dynamic>>{};
    for (final wf in existingWorkflows) {
      final name = (wf['name'] ?? '').toString();
      if (name.isNotEmpty) existingByName[name] = wf;
    }

    for (final wf in preview.workflows) {
      final name = (wf['name'] ?? '').toString();
      final existing = existingByName[name];

      if (existing != null) {
        final resolution = workflowResolutions[name];
        if (resolution == null || resolution == ConflictResolution.skip) {
          workflowsSkipped++;
          continue;
        }
      }

      final workflowType = normalizeWorkflowType(wf['workflowType']);
      await appManager.saveWorkflow(
        botId,
        name: name,
        actions: List<Map<String, dynamic>>.from(
          (wf['actions'] as List?)?.whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ) ??
              const <Map<String, dynamic>>[],
        ),
        entryPoint: normalizeWorkflowEntryPoint(wf['entryPoint']),
        arguments: serializeWorkflowArgumentDefinitions(
          parseWorkflowArgumentDefinitions(wf['arguments']),
        ),
        workflowType: workflowType,
        eventTrigger:
            workflowType == workflowTypeEvent
                ? normalizeWorkflowEventTrigger(wf['eventTrigger'])
                : null,
        folder: (wf['folder'] ?? '').toString().trim(),
      );
      workflowsImported++;
    }
  }

  // Import status
  if (importStatus && preview.hasStatus) {
    final appData = Map<String, dynamic>.from(await appManager.getApp(botId));
    if (preview.status!.containsKey('statuses')) {
      appData['statuses'] = preview.status!['statuses'];
    }
    if (preview.status!.containsKey('activities')) {
      appData['activities'] = preview.status!['activities'];
    }
    await appManager.saveApp(botId, appData);
  }

  // Import global variables
  if (importGlobalVariables && preview.hasGlobalVariables) {
    for (final entry in preview.globalVariables!.entries) {
      await appManager.setGlobalVariable(botId, entry.key, entry.value);
    }
  }

  return ImportResult(
    commandsImported: commandsImported,
    commandsSkipped: commandsSkipped,
    workflowsImported: workflowsImported,
    workflowsSkipped: workflowsSkipped,
    statusImported: importStatus && preview.hasStatus,
    globalVariablesImported:
        importGlobalVariables && preview.hasGlobalVariables,
  );
}

class ImportResult {
  final int commandsImported;
  final int commandsSkipped;
  final int workflowsImported;
  final int workflowsSkipped;
  final bool statusImported;
  final bool globalVariablesImported;

  const ImportResult({
    required this.commandsImported,
    required this.commandsSkipped,
    required this.workflowsImported,
    required this.workflowsSkipped,
    required this.statusImported,
    required this.globalVariablesImported,
  });
}
