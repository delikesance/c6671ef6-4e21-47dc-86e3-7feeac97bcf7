import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bot_creator/core/storage/app_storage_directory.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/command_folder_tree.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';

/// Manifest schema version for export compatibility.
const int _manifestVersion = 1;

/// Sections that can be exported/imported.
enum ExportSection { commands, workflows, status, globalVariables }

/// Builds a ZIP archive containing selected sections of a bot's data.
///
/// The ZIP structure:
/// ```
/// manifest.json
/// commands/{commandId}.json   (or commands/{folder}/{commandId}.json)
/// workflows.json              (if workflows selected)
/// status.json                 (if status selected)
/// global_variables.json       (if globalVariables selected)
/// empty_folders.json          (optional, preserved command folder structure)
/// empty_workflow_folders.json (optional, preserved workflow folder structure)
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
  final runtimeEngine = await getBotRuntimeEngine(botId);

  final manifest = <String, dynamic>{
    'version': _manifestVersion,
    'exportedAt': DateTime.now().toIso8601String(),
    'sections': sections.map((s) => s.name).toList(),
    'runtimeEngine': runtimeEngine,
  };

  // Commands
  if (sections.contains(ExportSection.commands)) {
    final commands = await appManager.listAppCommands(botId);
    final selectedCommands = commandIds != null
        ? commands.where((c) => commandIds.contains((c['id'] ?? '').toString()))
        : commands;

    for (final cmd in selectedCommands) {
      final id = (cmd['id'] ?? '').toString();
      if (id.isEmpty) continue;
      final full = await appManager.getAppCommand(botId, id);
      if (full.isEmpty) continue;
      // Strip token if somehow present
      final sanitized = Map<String, dynamic>.from(full)..remove('token');
      final json = const JsonEncoder.withIndent('  ').convert(sanitized);

      final folder = normalizeFolderPath(
        (sanitized['folder'] ?? cmd['folder'] ?? '').toString(),
      );
      final zipEntryPath = folder.isEmpty
          ? 'commands/$id.json'
          : 'commands/$folder/$id.json';

      archive.addFile(ArchiveFile.bytes(zipEntryPath, utf8.encode(json)));
    }
    manifest['commandCount'] = selectedCommands.length;

    // Export empty folders metadata if available
    try {
      final storagePath = await getAppStoragePath();
      final emptyCmdFile = File('$storagePath/apps/$botId/_empty_folders.json');
      if (await emptyCmdFile.exists()) {
        final emptyBytes = await emptyCmdFile.readAsBytes();
        archive.addFile(ArchiveFile.bytes('empty_folders.json', emptyBytes));
      }
    } catch (_) {}
  }

  // Workflows
  if (sections.contains(ExportSection.workflows)) {
    final workflows = await appManager.getWorkflows(botId);
    final selectedWorkflows = workflowNames != null
        ? workflows.where(
            (w) => workflowNames.contains((w['name'] ?? '').toString()),
          )
        : workflows;
    final list = selectedWorkflows.toList();
    final json = const JsonEncoder.withIndent('  ').convert(list);
    archive.addFile(ArchiveFile.bytes('workflows.json', utf8.encode(json)));
    manifest['workflowCount'] = list.length;

    // Export empty workflow folders metadata if available
    try {
      final storagePath = await getAppStoragePath();
      final emptyWfFile = File(
        '$storagePath/apps/$botId/_empty_workflow_folders.json',
      );
      if (await emptyWfFile.exists()) {
        final emptyBytes = await emptyWfFile.readAsBytes();
        archive.addFile(
          ArchiveFile.bytes('empty_workflow_folders.json', emptyBytes),
        );
      }
    } catch (_) {}
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
  final String runtimeEngine;
  final List<Map<String, dynamic>> commands;
  final List<Map<String, dynamic>> workflows;
  final Map<String, dynamic>? status;
  final Map<String, dynamic>? globalVariables;
  final Set<String> emptyFolders;
  final Set<String> emptyWorkflowFolders;

  const ImportPreview({
    required this.manifestVersion,
    this.runtimeEngine = runtimeEngineDart,
    required this.commands,
    required this.workflows,
    this.status,
    this.globalVariables,
    this.emptyFolders = const {},
    this.emptyWorkflowFolders = const {},
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
  String? manifestEngine;
  if (manifestFile != null) {
    final manifestJson = utf8.decode(manifestFile.content as List<int>);
    final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
    version = (manifest['version'] as int?) ?? 1;
    manifestEngine = manifest['runtimeEngine']?.toString();
  }

  // Read empty folders if stored
  final emptyFolders = <String>{};
  final emptyCmdFile = archive.findFile('empty_folders.json');
  if (emptyCmdFile != null) {
    try {
      final json = utf8.decode(emptyCmdFile.content as List<int>);
      final list = (jsonDecode(json) as List).cast<String>();
      emptyFolders.addAll(list);
    } catch (_) {}
  }

  final emptyWorkflowFolders = <String>{};
  final emptyWfFile = archive.findFile('empty_workflow_folders.json');
  if (emptyWfFile != null) {
    try {
      final json = utf8.decode(emptyWfFile.content as List<int>);
      final list = (jsonDecode(json) as List).cast<String>();
      emptyWorkflowFolders.addAll(list);
    } catch (_) {}
  }

  // Read commands
  final commands = <Map<String, dynamic>>[];
  bool hasJsCommands = false;
  for (final file in archive.files) {
    if (file.name.startsWith('commands/') && file.name.endsWith('.json')) {
      try {
        final json = utf8.decode(file.content as List<int>);
        final cmd = Map<String, dynamic>.from(jsonDecode(json) as Map);

        // Deduce folder from ZIP path if not explicit in JSON (e.g. commands/admin/moderation/ban.json)
        if ((cmd['folder'] ?? '').toString().trim().isEmpty) {
          final segments = file.name.split('/');
          if (segments.length > 2) {
            final folderSegments = segments.sublist(1, segments.length - 1);
            cmd['folder'] = folderSegments.join('/');
          }
        }

        commands.add(normalizeCommandData(cmd));

        if (cmd['executionMode'] == runtimeEngineJavascript ||
            (cmd['data'] is Map &&
                cmd['data']['executionMode'] == runtimeEngineJavascript) ||
            (cmd['jsScriptContent'] != null &&
                cmd['jsScriptContent'].toString().trim().isNotEmpty) ||
            (cmd['data'] is Map &&
                cmd['data']['jsScriptContent'] != null &&
                cmd['data']['jsScriptContent'].toString().trim().isNotEmpty)) {
          hasJsCommands = true;
        }
      } catch (_) {}
    }
  }

  // Read workflows
  var workflows = <Map<String, dynamic>>[];
  bool hasJsWorkflows = false;
  final workflowsFile = archive.findFile('workflows.json');
  if (workflowsFile != null) {
    try {
      final json = utf8.decode(workflowsFile.content as List<int>);
      final list = jsonDecode(json) as List;
      workflows = list
          .whereType<Map>()
          .map(
            (w) =>
                normalizeStoredWorkflowDefinition(Map<String, dynamic>.from(w)),
          )
          .toList();

      hasJsWorkflows = workflows.any(
        (w) =>
            w['executionMode'] == runtimeEngineJavascript ||
            (w['jsScriptContent'] != null &&
                w['jsScriptContent'].toString().trim().isNotEmpty),
      );
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

  // Resolve runtime engine: prefer manifest, fallback heuristically to content
  final resolvedEngine =
      (manifestEngine != null && manifestEngine.trim().isNotEmpty)
      ? normalizeRuntimeEngine(manifestEngine)
      : (hasJsCommands || hasJsWorkflows
            ? runtimeEngineJavascript
            : runtimeEngineDart);

  return ImportPreview(
    manifestVersion: version,
    runtimeEngine: resolvedEngine,
    commands: commands,
    workflows: workflows,
    status: status,
    globalVariables: globalVars,
    emptyFolders: emptyFolders,
    emptyWorkflowFolders: emptyWorkflowFolders,
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

  // Restore runtime engine deterministically from export
  await setBotRuntimeEngine(botId, preview.runtimeEngine);

  // Restore empty folders metadata
  try {
    final storagePath = await getAppStoragePath();
    if (preview.emptyFolders.isNotEmpty) {
      final file = File('$storagePath/apps/$botId/_empty_folders.json');
      final existing = <String>{};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          existing.addAll((jsonDecode(content) as List).cast<String>());
        } catch (_) {}
      }
      existing.addAll(preview.emptyFolders);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(existing.toList()));
    }
    if (preview.emptyWorkflowFolders.isNotEmpty) {
      final file = File(
        '$storagePath/apps/$botId/_empty_workflow_folders.json',
      );
      final existing = <String>{};
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          existing.addAll((jsonDecode(content) as List).cast<String>());
        } catch (_) {}
      }
      existing.addAll(preview.emptyWorkflowFolders);
      await file.parent.create(recursive: true);
      await file.writeAsString(jsonEncode(existing.toList()));
    }
  } catch (_) {}

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

      final folder = (cmd['folder'] ?? '').toString().trim();

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
        if (folder.isNotEmpty) {
          sanitized['folder'] = folder;
        }
        await appManager.saveAppCommand(botId, existingId, sanitized);
        commandsImported++;
      } else {
        // New command — assign a local ID
        final localId = DateTime.now().microsecondsSinceEpoch.toString();
        final sanitized = Map<String, dynamic>.from(cmd)..remove('token');
        sanitized['id'] = localId;
        if (folder.isNotEmpty) {
          sanitized['folder'] = folder;
        }
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
        eventTrigger: workflowType == workflowTypeEvent
            ? normalizeWorkflowEventTrigger(wf['eventTrigger'])
            : null,
        folder: (wf['folder'] ?? '').toString().trim(),
        executionMode: wf['executionMode']?.toString(),
        jsScriptContent: wf['jsScriptContent']?.toString(),
        eventVariableAliases: wf['eventVariableAliases'] is Map
            ? Map<String, String>.from(
                (wf['eventVariableAliases'] as Map).map(
                  (k, v) => MapEntry(k.toString(), v.toString()),
                ),
              )
            : null,
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
