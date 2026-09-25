import 'dart:io';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_export_import.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

class BotExportImportPage extends StatefulWidget {
  final String botId;
  const BotExportImportPage({super.key, required this.botId});

  @override
  State<BotExportImportPage> createState() => _BotExportImportPageState();
}

class _BotExportImportPageState extends State<BotExportImportPage> {
  // Export state
  bool _exportCommands = true;
  bool _exportWorkflows = true;
  bool _exportStatus = true;
  bool _exportGlobalVariables = true;
  bool _isExporting = false;
  final Set<String> _selectedCommandIds = {};
  final Set<String> _selectedWorkflowNames = {};

  // Import state
  bool _isImporting = false;
  ImportPreview? _importPreview;
  bool _importCommands = true;
  bool _importWorkflows = true;
  bool _importStatus = true;
  bool _importGlobalVariables = true;
  final Map<String, ConflictResolution> _commandResolutions = {};
  final Map<String, ConflictResolution> _workflowResolutions = {};
  List<Map<String, dynamic>> _localCommands = [];
  List<Map<String, dynamic>> _localWorkflows = [];

  /// Moteur ACTUEL du bot : c'est le défaut du choix proposé à l'import, donc
  /// ce que l'utilisateur voit quand il n'a rien décidé.
  String _botEngine = runtimeEngineDart;

  /// Moteur appliqué par l'import en cours (déclaré par le ZIP, ou choisi).
  String _importEngine = runtimeEngineDart;

  @override
  void initState() {
    super.initState();
    _loadLocalData();
  }

  Future<void> _loadLocalData() async {
    final commands = await appManager.listAppCommands(widget.botId);
    final workflows = await appManager.getWorkflows(widget.botId);
    final engine = await getBotRuntimeEngine(widget.botId);
    if (!mounted) return;
    setState(() {
      _botEngine = engine;
      _importEngine = engine;
      _localCommands = commands;
      _localWorkflows = workflows;
      _selectedCommandIds
        ..clear()
        ..addAll(
          commands
              .map((c) => (c['id'] ?? '').toString())
              .where((id) => id.isNotEmpty),
        );
      _selectedWorkflowNames
        ..clear()
        ..addAll(
          workflows
              .map((w) => (w['name'] ?? '').toString())
              .where((n) => n.isNotEmpty),
        );
    });
  }

  Set<ExportSection> get _selectedExportSections {
    final sections = <ExportSection>{};
    if (_exportCommands && _selectedCommandIds.isNotEmpty) {
      sections.add(ExportSection.commands);
    }
    if (_exportWorkflows && _selectedWorkflowNames.isNotEmpty) {
      sections.add(ExportSection.workflows);
    }
    if (_exportStatus) sections.add(ExportSection.status);
    if (_exportGlobalVariables) sections.add(ExportSection.globalVariables);
    return sections;
  }

  Future<void> _performExport() async {
    if (_selectedExportSections.isEmpty) return;

    setState(() => _isExporting = true);
    try {
      final zipBytes = await exportBot(
        widget.botId,
        sections: _selectedExportSections,
        commandIds: _exportCommands ? _selectedCommandIds : null,
        workflowNames: _exportWorkflows ? _selectedWorkflowNames : null,
      );

      if (!mounted) return;

      // Save using file_picker save dialog
      await FilePicker.saveFile(
        dialogTitle: context.tr.export_button,
        fileName: 'bot_export.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
        bytes: zipBytes,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.export_failed('$e'))));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _pickAndParseZip() async {
    FilePickerResult? pickerResult;
    try {
      pickerResult = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
    } catch (e) {
      // Handle file picker already active error gracefully
      if (e.toString().contains('already_active')) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.export_file_picker_busy)),
        );
        return;
      }
      rethrow;
    }

    if (pickerResult == null || pickerResult.files.isEmpty) return;
    final result = pickerResult.files.first;
    if (result.path == null || result.path!.isEmpty) return;

    // Use dart:io File like the rest of the codebase (drive.dart, emojis.page.dart).
    // Avoid using result.readAsBytes() which can fail with "file data is not available"
    final bytes = await File(result.path!).readAsBytes();
    if (bytes.isEmpty) return;

    try {
      final preview = parseExportZip(bytes);

      if (!mounted) return;
      setState(() {
        _importPreview = preview;
        // Moteur : ce que le ZIP déclare, sinon le moteur ACTUEL du bot. Le
        // défaut n'est jamais une devinette sur le contenu : un import ne doit
        // pas changer de moteur tout seul, il le PROPOSE.
        _importEngine = preview.runtimeEngineDeclared
            ? preview.runtimeEngine
            : _botEngine;
        _importCommands = preview.hasCommands;
        _importWorkflows = preview.hasWorkflows;
        _importStatus = preview.hasStatus;
        _importGlobalVariables = preview.hasGlobalVariables;
        _commandResolutions.clear();
        _workflowResolutions.clear();

        // Pre-detect conflicts
        final localCommandNames = _localCommands
            .map((c) => (c['name'] ?? '').toString().toLowerCase())
            .toSet();
        for (final cmd in preview.commands) {
          final name = (cmd['name'] ?? '').toString().toLowerCase();
          if (localCommandNames.contains(name)) {
            _commandResolutions[name] = ConflictResolution.skip;
          }
        }

        final localWorkflowNames = _localWorkflows
            .map((w) => (w['name'] ?? '').toString())
            .toSet();
        for (final wf in preview.workflows) {
          final name = (wf['name'] ?? '').toString();
          if (localWorkflowNames.contains(name)) {
            _workflowResolutions[name] = ConflictResolution.skip;
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.import_parse_failed('$e'))),
      );
    }
  }

  Future<void> _performImport() async {
    if (_importPreview == null) return;

    setState(() => _isImporting = true);
    try {
      final result = await importBot(
        widget.botId,
        preview: _importPreview!,
        runtimeEngine: _importEngine,
        importCommands: _importCommands,
        importWorkflows: _importWorkflows,
        importStatus: _importStatus,
        importGlobalVariables: _importGlobalVariables,
        commandResolutions: _commandResolutions,
        workflowResolutions: _workflowResolutions,
      );

      if (!mounted) return;
      final parts = <String>[];
      if (result.commandsImported > 0) {
        parts.add(
          context.tr.import_summary_commands_imported(result.commandsImported),
        );
      }
      if (result.commandsSkipped > 0) {
        parts.add(
          context.tr.import_summary_commands_skipped(result.commandsSkipped),
        );
      }
      if (result.workflowsImported > 0) {
        parts.add(
          context.tr.import_summary_workflows_imported(
            result.workflowsImported,
          ),
        );
      }
      if (result.workflowsSkipped > 0) {
        parts.add(
          context.tr.import_summary_workflows_skipped(result.workflowsSkipped),
        );
      }
      if (result.statusImported) {
        parts.add(context.tr.import_summary_status_imported);
      }
      if (result.globalVariablesImported) {
        parts.add(context.tr.import_summary_variables_imported);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            parts.isEmpty ? context.tr.import_nothing : parts.join(', '),
          ),
        ),
      );

      setState(() => _importPreview = null);
      await _loadLocalData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.import_failed('$e'))));
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr.export_import_title)),
      // Largeur et marges communes à toutes les pages (contrat AppPageLayout).
      body: SafeArea(
        top: false,
        child: PageContent(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildExportSection(),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                _buildImportSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr.export_section_title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.export_section_desc,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        _buildExportCommandsSection(),
        _buildExportWorkflowsSection(),
        CheckboxListTile(
          value: _exportStatus,
          onChanged: (v) => setState(() => _exportStatus = v ?? false),
          title: Text(context.tr.export_status),
          dense: true,
        ),
        CheckboxListTile(
          value: _exportGlobalVariables,
          onChanged: (v) => setState(() => _exportGlobalVariables = v ?? false),
          title: Text(context.tr.export_global_variables),
          dense: true,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _isExporting || _selectedExportSections.isEmpty
              ? null
              : _performExport,
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.upload_file),
          label: Text(context.tr.export_button),
        ),
      ],
    );
  }

  Widget _buildExportCommandsSection() {
    final allIds = _localCommands
        .map((c) => (c['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toList();
    final allSelected =
        _exportCommands &&
        allIds.every((id) => _selectedCommandIds.contains(id));
    final someSelected =
        _exportCommands &&
        !allSelected &&
        allIds.any((id) => _selectedCommandIds.contains(id));

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          onChanged: (v) {
            setState(() {
              if (v == true || v == null) {
                _exportCommands = true;
                _selectedCommandIds
                  ..clear()
                  ..addAll(allIds);
              } else {
                _exportCommands = false;
                _selectedCommandIds.clear();
              }
            });
          },
          title: Text(context.tr.export_commands),
          subtitle: Text(
            '${_selectedCommandIds.length} / ${_localCommands.length}',
          ),
          dense: true,
        ),
        if (_exportCommands)
          ...List.generate(_localCommands.length, (i) {
            final cmd = _localCommands[i];
            final id = (cmd['id'] ?? '').toString();
            final name = (cmd['name'] ?? id).toString();
            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: CheckboxListTile(
                value: _selectedCommandIds.contains(id),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedCommandIds.add(id);
                    } else {
                      _selectedCommandIds.remove(id);
                    }
                    _exportCommands = _selectedCommandIds.isNotEmpty;
                  });
                },
                title: Text(name, style: const TextStyle(fontSize: 14)),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildExportWorkflowsSection() {
    final allNames = _localWorkflows
        .map((w) => (w['name'] ?? '').toString())
        .where((n) => n.isNotEmpty)
        .toList();
    final allSelected =
        _exportWorkflows &&
        allNames.every((n) => _selectedWorkflowNames.contains(n));
    final someSelected =
        _exportWorkflows &&
        !allSelected &&
        allNames.any((n) => _selectedWorkflowNames.contains(n));

    return Column(
      children: [
        CheckboxListTile(
          value: allSelected ? true : (someSelected ? null : false),
          tristate: true,
          onChanged: (v) {
            setState(() {
              if (v == true || v == null) {
                _exportWorkflows = true;
                _selectedWorkflowNames
                  ..clear()
                  ..addAll(allNames);
              } else {
                _exportWorkflows = false;
                _selectedWorkflowNames.clear();
              }
            });
          },
          title: Text(context.tr.export_workflows),
          subtitle: Text(
            '${_selectedWorkflowNames.length} / ${_localWorkflows.length}',
          ),
          dense: true,
        ),
        if (_exportWorkflows)
          ...List.generate(_localWorkflows.length, (i) {
            final wf = _localWorkflows[i];
            final name = (wf['name'] ?? '').toString();
            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: CheckboxListTile(
                value: _selectedWorkflowNames.contains(name),
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedWorkflowNames.add(name);
                    } else {
                      _selectedWorkflowNames.remove(name);
                    }
                    _exportWorkflows = _selectedWorkflowNames.isNotEmpty;
                  });
                },
                title: Text(name, style: const TextStyle(fontSize: 14)),
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            );
          }),
      ],
    );
  }

  Widget _buildImportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr.import_section_title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.tr.import_section_desc,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        if (_importPreview == null) ...[
          OutlinedButton.icon(
            onPressed: _pickAndParseZip,
            icon: const Icon(Icons.folder_open),
            label: Text(context.tr.import_pick_file),
          ),
        ] else ...[
          _buildImportPreview(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _importPreview = null),
                  child: Text(context.tr.cancel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _isImporting ? null : _performImport,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download),
                  label: Text(context.tr.import_button),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildImportPreview() {
    final preview = _importPreview!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildImportEngineSection(preview),
        const SizedBox(height: 8),
        if (preview.hasCommands) ...[
          CheckboxListTile(
            value: _importCommands,
            onChanged: (v) => setState(() => _importCommands = v ?? false),
            title: Text(
              '${context.tr.export_commands} (${preview.commands.length})',
            ),
            dense: true,
          ),
          if (_importCommands) ..._buildCommandConflicts(preview),
        ],
        if (preview.hasWorkflows) ...[
          CheckboxListTile(
            value: _importWorkflows,
            onChanged: (v) => setState(() => _importWorkflows = v ?? false),
            title: Text(
              '${context.tr.export_workflows} (${preview.workflows.length})',
            ),
            dense: true,
          ),
          if (_importWorkflows) ..._buildWorkflowConflicts(preview),
        ],
        if (preview.hasStatus)
          CheckboxListTile(
            value: _importStatus,
            onChanged: (v) => setState(() => _importStatus = v ?? false),
            title: Text(context.tr.export_status),
            dense: true,
          ),
        if (preview.hasGlobalVariables)
          CheckboxListTile(
            value: _importGlobalVariables,
            onChanged: (v) =>
                setState(() => _importGlobalVariables = v ?? false),
            title: Text(context.tr.export_global_variables),
            dense: true,
          ),
      ],
    );
  }

  /// Choix du moteur d'exécution pour CET import.
  ///
  /// Un ZIP qui déclare son moteur fait foi (on l'affiche, il n'est pas
  /// modifiable). Un ZIP muet ne décide rien : on demande, en proposant le
  /// moteur actuel du bot pour qu'un import ne bascule jamais le moteur par
  /// surprise — c'est justement ce qui cassait des bots JavaScript.
  Widget _buildImportEngineSection(ImportPreview preview) {
    final theme = Theme.of(context);
    final tr = context.tr;
    final declared = preview.runtimeEngineDeclared;
    final willSwitch =
        normalizeRuntimeEngine(_importEngine) !=
        normalizeRuntimeEngine(_botEngine);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.memory, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(tr.import_engine_title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 6),
          if (declared)
            Text(
              tr.import_engine_declared(_engineLabel(_importEngine)),
              style: theme.textTheme.bodySmall,
            )
          else ...[
            Text(tr.import_engine_missing, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: runtimeEngineDart,
                  label: Text(tr.import_engine_dart_label),
                ),
                ButtonSegment(
                  value: runtimeEngineJavascript,
                  label: Text(tr.import_engine_javascript_label),
                ),
              ],
              selected: {normalizeRuntimeEngine(_importEngine)},
              onSelectionChanged: (selection) =>
                  setState(() => _importEngine = selection.first),
            ),
          ],
          if (willSwitch) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tr.import_engine_will_switch(
                      _engineLabel(_botEngine),
                      _engineLabel(_importEngine),
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _engineLabel(String engine) =>
      normalizeRuntimeEngine(engine) == runtimeEngineJavascript
      ? context.tr.import_engine_javascript_label
      : context.tr.import_engine_dart_label;

  List<Widget> _buildCommandConflicts(ImportPreview preview) {
    final conflicts = <Widget>[];
    for (final cmd in preview.commands) {
      final name = (cmd['name'] ?? '').toString();
      final nameLower = name.toLowerCase();
      if (!_commandResolutions.containsKey(nameLower)) continue;

      final resolution = _commandResolutions[nameLower]!;
      conflicts.add(
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: AppTheme.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
              SegmentedButton<ConflictResolution>(
                segments: [
                  ButtonSegment(
                    value: ConflictResolution.overwrite,
                    label: Text(
                      context.tr.import_overwrite,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  ButtonSegment(
                    value: ConflictResolution.skip,
                    label: Text(
                      context.tr.import_skip,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                selected: {resolution},
                onSelectionChanged: (s) {
                  setState(() => _commandResolutions[nameLower] = s.first);
                },
              ),
            ],
          ),
        ),
      );
    }
    return conflicts;
  }

  List<Widget> _buildWorkflowConflicts(ImportPreview preview) {
    final conflicts = <Widget>[];
    for (final wf in preview.workflows) {
      final name = (wf['name'] ?? '').toString();
      if (!_workflowResolutions.containsKey(name)) continue;

      final resolution = _workflowResolutions[name]!;
      conflicts.add(
        Padding(
          padding: const EdgeInsets.only(left: 32, bottom: 4),
          child: Row(
            children: [
              Icon(Icons.warning_amber, size: 16, color: AppTheme.warning),
              const SizedBox(width: 8),
              Expanded(child: Text(name, style: const TextStyle(fontSize: 13))),
              SegmentedButton<ConflictResolution>(
                segments: [
                  ButtonSegment(
                    value: ConflictResolution.overwrite,
                    label: Text(
                      context.tr.import_overwrite,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                  ButtonSegment(
                    value: ConflictResolution.skip,
                    label: Text(
                      context.tr.import_skip,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
                selected: {resolution},
                onSelectionChanged: (s) {
                  setState(() => _workflowResolutions[name] = s.first);
                },
              ),
            ],
          ),
        ),
      );
    }
    return conflicts;
  }
}
