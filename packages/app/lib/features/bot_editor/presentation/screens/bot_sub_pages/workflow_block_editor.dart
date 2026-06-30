import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;

import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;
import 'package:bot_creator_shared/utils/variable_catalog.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// Full-screen Scratch-like block editor for creating or editing a workflow.
///
/// Replaces the previous two-step flow (metadata dialog → ActionsBuilderPage)
/// with a single unified view:
///   Metadata block → EntryPoint block → Action blocks → Add button
class WorkflowBlockEditor extends StatefulWidget {
  const WorkflowBlockEditor({
    super.key,
    required this.botId,
    this.initial,
    this.initialWorkflowType,
    this.appEmojis = const [],
    required this.eventCatalog,
    required this.eventCategories,
    required this.eventsForCategory,
    required this.eventCategoryLabel,
    required this.buildVariableSuggestions,
  });

  final String botId;

  /// If non-null, we're editing an existing workflow.
  final Map<String, dynamic>? initial;
  final String? initialWorkflowType;
  final List<AppEmoji> appEmojis;

  // Event catalog callbacks — delegated from WorkflowsPage because the
  // catalog is defined there as a private getter.
  final List<WorkflowEventItem> Function(String category) eventsForCategory;
  final List<String> eventCategories;
  final String Function(String category) eventCategoryLabel;
  final Future<List<VariableSuggestion>> Function({
    required String workflowType,
    required List<WorkflowArgumentDefinition> argumentDefinitions,
    required Map<String, dynamic> eventTrigger,
  })
  buildVariableSuggestions;

  /// Convenience: externally provided full event list for lookup.
  final List<WorkflowEventItem> eventCatalog;

  @override
  State<WorkflowBlockEditor> createState() => _WorkflowBlockEditorState();
}

class _WorkflowBlockEditorState extends State<WorkflowBlockEditor> {
  late final TextEditingController _nameController;
  late final TextEditingController _folderController;
  late final TextEditingController _entryPointController;

  late String _workflowType;
  late Map<String, dynamic> _eventTrigger;
  late String _selectedCategory;
  late String _selectedEvent;
  late List<_EditableArg> _arguments;
  late List<Map<String, dynamic>> _actions;

  /// Event variable aliases: originalName → customName.
  Map<String, String> _eventVariableAliases = <String, String>{};

  /// Whether the event variables list in the sidebar is expanded.
  bool _eventVariablesExpanded = true;

  /// 0 for Config (Metadata/Trigger), 1 for Action blocks palette.
  int _sidebarTab = 0;

  /// Wizard step for mobile editor (0 to 3)
  int _wizardStep = 0;

  /// Tab index for mobile editor in edit mode (0 for Trigger, 1 for Actions)
  int _mobileTab = 0;

  /// Mobile trigger type selection
  late String _mobileTriggerType;

  List<VariableSuggestion> _variableSuggestions = [];
  bool _saving = false;
  List<String> _existingFolders = const [];

  bool get _isEditing => widget.initial != null;

  String get _triggerType {
    if (_workflowType == workflowTypeGeneral) {
      return 'command';
    }
    if (_selectedCategory == 'core' && _selectedEvent == 'interactionCreate') {
      return 'button';
    }
    return 'event';
  }

  Future<void> _loadExistingFolders() async {
    try {
      final workflows = await appManager.getWorkflows(widget.botId);
      final folders = workflows
          .map((w) => (w['folder'] ?? '').toString().trim())
          .where((f) => f.isNotEmpty)
          .toSet()
          .toList()..sort();
      if (mounted) {
        setState(() {
          _existingFolders = folders;
        });
      }
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadExistingFolders();

    final normalized =
        widget.initial != null
            ? normalizeStoredWorkflowDefinition(
              Map<String, dynamic>.from(widget.initial!),
            )
            : null;

    _nameController = TextEditingController(
      text: (normalized?['name'] ?? '').toString(),
    );
    _folderController = TextEditingController(
      text: (normalized?['folder'] ?? '').toString().trim(),
    );
    _entryPointController = TextEditingController(
      text: normalizeWorkflowEntryPoint(normalized?['entryPoint']),
    );

    _workflowType = normalizeWorkflowType(
      widget.initialWorkflowType ?? normalized?['workflowType'],
    );
    _eventTrigger = normalizeWorkflowEventTrigger(normalized?['eventTrigger']);
    _selectedCategory = (_eventTrigger['category'] ?? 'messages').toString();
    _selectedEvent = (_eventTrigger['event'] ?? 'messageCreate').toString();

    final parsed = parseWorkflowArgumentDefinitions(normalized?['arguments']);
    _arguments =
        parsed
            .map(
              (d) => _EditableArg(
                name: d.name,
                required: d.required,
                defaultValue: d.defaultValue,
              ),
            )
            .toList();
    if (_arguments.isEmpty) {
      _arguments.add(_EditableArg(name: ''));
    }

    // Load existing event variable aliases.
    final rawAliases = normalized?['eventVariableAliases'];
    _eventVariableAliases = <String, String>{};
    if (rawAliases is Map) {
      for (final entry in rawAliases.entries) {
        final k = entry.key.toString();
        final v = entry.value?.toString() ?? '';
        if (k.isNotEmpty && v.isNotEmpty) {
          _eventVariableAliases[k] = v;
        }
      }
    }

    _actions = List<Map<String, dynamic>>.from(
      (normalized?['actions'] as List?)?.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ) ??
          const <Map<String, dynamic>>[],
    );

    _ensureEventSelection();
    _refreshVariableSuggestions();

    if (_workflowType == workflowTypeEvent) {
      if (_selectedEvent == 'interactionCreate') {
        _mobileTriggerType = 'button';
      } else {
        _mobileTriggerType = 'event';
      }
    } else {
      _mobileTriggerType = 'command';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _folderController.dispose();
    _entryPointController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  void _ensureEventSelection() {
    final cats = widget.eventCategories;
    var changed = false;
    if (!cats.contains(_selectedCategory) && cats.isNotEmpty) {
      _selectedCategory = cats.first;
      changed = true;
    }
    final events = widget.eventsForCategory(_selectedCategory);
    if (events.isNotEmpty && !events.any((e) => e.event == _selectedEvent)) {
      _selectedEvent = events.first.event;
      changed = true;
    }
    if (changed || _eventTrigger.isEmpty) {
      _eventTrigger = {
        ..._eventTrigger,
        'category': _selectedCategory,
        'event': _selectedEvent,
      };
    }
  }

  Future<void> _refreshVariableSuggestions() async {
    final defs = _arguments
        .where((a) => a.name.trim().isNotEmpty)
        .map(
          (a) => WorkflowArgumentDefinition(
            name: a.name.trim(),
            required: a.required,
            defaultValue: a.defaultValue,
          ),
        )
        .toList(growable: false);

    final suggestions = await widget.buildVariableSuggestions(
      workflowType: _workflowType,
      argumentDefinitions: defs,
      eventTrigger: _eventTrigger,
    );

    // Scan workflow actions for setTemporaryVariable blocks and expose
    // their keys as temp.<key> suggestions so they appear in autocomplete
    // for downstream blocks.
    final deduped = <String, VariableSuggestion>{};
    for (final s in suggestions) {
      deduped[s.name] = s;
    }
    for (final action in _actions) {
      final type = (action['type'] ?? '').toString();
      if (type != 'setTemporaryVariable') continue;

      final payload = Map<String, dynamic>.from(
        (action['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      final rawKey = (payload['key'] ?? '').toString().trim();
      if (rawKey.isEmpty) continue;

      final normalizedKey = rawKey.startsWith('bc_') && rawKey.length > 3
          ? rawKey.substring(3)
          : rawKey;
      final name = 'temp.$normalizedKey';
      if (deduped.containsKey(name)) continue;

      deduped[name] = VariableSuggestion(
        name: name,
        kind: VariableSuggestionKind.unknown,
        category: shared.VariableCategory.temp,
      );
    }

    if (mounted) {
      setState(() => _variableSuggestions = deduped.values.toList(growable: false));
    }

    // Add aliased versions of event variables.
    _refreshAliasedEventSuggestions();
  }

  void _refreshAliasedEventSuggestions() {
    if (_workflowType != workflowTypeEvent || _eventVariableAliases.isEmpty) {
      return;
    }

    // Remove any previously added aliased suggestions to avoid duplicates.
    final aliasedNames = _eventVariableAliases.values.toSet();
    final filtered = _variableSuggestions
        .where((s) => !aliasedNames.contains(s.name))
        .toList();

    for (final entry in _eventVariableAliases.entries) {
      final originalName = entry.key;
      final alias = entry.value;
      // Find the original suggestion to copy its kind/category
      final original = _variableSuggestions.cast<VariableSuggestion?>().firstWhere(
        (s) => s?.name == originalName,
        orElse: () => null,
      );
      filtered.add(VariableSuggestion(
        name: alias,
        kind: original?.kind ?? VariableSuggestionKind.unknown,
        category: original?.category ?? shared.VariableCategory.other,
      ));
    }

    if (mounted) {
      setState(() {
        _variableSuggestions = filtered;
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr.workflows_name)));
      return;
    }
    setState(() => _saving = true);

    final oldName = widget.initial?['name']?.toString();
    final nameChanged = oldName != null && oldName != name;

    if (nameChanged) {
      try {
        await appManager.deleteWorkflow(widget.botId, oldName);
      } catch (_) {
        // Keep saving resilient if deleting the old one fails.
      }
    }

    final entryPoint = normalizeWorkflowEntryPoint(_entryPointController.text);
    final argDefs = _arguments
        .where((a) => a.name.trim().isNotEmpty)
        .map(
          (a) => WorkflowArgumentDefinition(
            name: a.name.trim(),
            required: a.required,
            defaultValue: a.defaultValue,
          ),
        )
        .toList(growable: false);

    await appManager.saveWorkflow(
      widget.botId,
      name: name,
      actions: _actions,
      entryPoint: entryPoint,
      arguments: serializeWorkflowArgumentDefinitions(argDefs),
      workflowType: _workflowType,
      eventTrigger: _workflowType == workflowTypeEvent ? _eventTrigger : null,
      folder: _folderController.text.trim(),
      eventVariableAliases:
          _eventVariableAliases.isNotEmpty ? Map<String, String>.from(_eventVariableAliases) : null,
    );

    // Dynamic Refresh: apply changes immediately to running bot.
    unawaited(refreshBotRuntime(widget.botId));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.brandPrimary,
        title: Text(
          _isEditing ? context.tr.workflows_edit : context.tr.workflows_create,
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(AppTheme.spacingMd),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: context.tr.save,
              onPressed: _save,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = MediaQuery.of(context).size.width >= 800 &&
                !Platform.environment.containsKey('FLUTTER_TEST');
            final maxWidth =
                constraints.maxWidth >= 1200
                    ? 980.0
                    : (isDesktop ? 860.0 : 680.0);

            final canvasWidget = Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: ScratchBlockCanvas(
                    skipConnectorAfterIndices: _buildFinalBlockIndices(showHeaderBlocks: !isDesktop),
                    children: _buildBlocks(showAddButton: true, showHeaderBlocks: !isDesktop),
                  ),
                ),
              ),
            );

            if (isDesktop) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 340,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _sidebarTab = 0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _sidebarTab == 0 ? AppTheme.brandPrimary : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.tune_outlined,
                                          color: _sidebarTab == 0 ? AppTheme.brandPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.tr.scratch_trigger_tab,
                                          style: TextStyle(
                                            fontWeight: _sidebarTab == 0 ? FontWeight.bold : FontWeight.normal,
                                            color: _sidebarTab == 0 ? AppTheme.brandPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _sidebarTab = 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: _sidebarTab == 1 ? AppTheme.brandPrimary : Colors.transparent,
                                          width: 2.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_box_outlined,
                                          color: _sidebarTab == 1 ? AppTheme.brandPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.tr.scratch_blocks_tab,
                                          style: TextStyle(
                                            fontWeight: _sidebarTab == 1 ? FontWeight.bold : FontWeight.normal,
                                            color: _sidebarTab == 1 ? AppTheme.brandPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
                                            fontSize: 13.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: IndexedStack(
                            index: _sidebarTab,
                            children: [
                              SingleChildScrollView(
                                padding: const EdgeInsets.all(AppTheme.spacingMd),
                                child: _buildUnifiedTriggerConfig(flat: true),
                              ),
                              ScratchBlockPalette(
                                onActionSelected: (type) {
                                  setState(() {
                                    final uniqueId = 'action_${DateTime.now().microsecondsSinceEpoch}';
                                    _actions.add(<String, dynamic>{
                                      'id': uniqueId,
                                      'type': type.name,
                                      'enabled': true,
                                      'key': uniqueId,
                                      'depend_on': <String>[],
                                      'error': {'mode': 'stop'},
                                      'payload': Map<String, dynamic>.from(type.defaultParameters),
                                    });
                                  });
                                  _refreshVariableSuggestions();
                                },
                                isInteraction: false,
                                isWorkflow: true,
                                popOnSelect: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                          center: Alignment.center,
                          radius: 1.3,
                        ),
                      ),
                      child: canvasWidget,
                    ),
                  ),
                ],
              );
            }

            if (_isEditing) {
              return _buildMobileTabEditor();
            }

            return _buildMobileWizard();
          },
        ),
      ),
    );
  }

  List<Widget> _buildBlocks({
    bool showAddButton = true,
    bool showHeaderBlocks = true,
  }) {
    return [
      // ── Metadata block ──
      if (showHeaderBlocks) _buildMetadataBlock(),

      // ── Entry Point block ──
      if (showHeaderBlocks) _buildEntryPointBlock(),

      // ── Action blocks ──
      ..._buildActionBlocks(),

      // ── Add button ──
      if (showAddButton) _buildAddBlockButton(),
    ];
  }

  Set<int> _buildFinalBlockIndices({bool showHeaderBlocks = true}) {
    final offset = showHeaderBlocks ? 2 : 0;
    final indices = <int>{};
    for (var i = 0; i < _actions.length; i++) {
      final type = BotCreatorActionType.values.firstWhere(
        (t) => t.name == _actions[i]['type'],
        orElse: () => BotCreatorActionType.sendMessage,
      );
      if (isFinalAction(type)) {
        indices.add(offset + i);
      }
    }
    return indices;
  }

  // ── Unified Trigger Configuration Panel ──

  Widget _buildTriggerTypeOption({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final currentType = _triggerType;
    final isSelected = currentType == type;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          if (type == 'button') {
            _workflowType = workflowTypeEvent;
            _selectedCategory = 'core';
            _selectedEvent = 'interactionCreate';
            _eventTrigger = {
              'category': 'core',
              'event': 'interactionCreate',
              'customIdFilter': (_eventTrigger['customIdFilter'] ?? '').toString(),
            };
          } else if (type == 'event') {
            _workflowType = workflowTypeEvent;
            if (_selectedEvent == 'interactionCreate') {
              _selectedCategory = 'messages';
              _selectedEvent = 'messageCreate';
            }
            _eventTrigger = {
              'category': _selectedCategory,
              'event': _selectedEvent,
              'customIdFilter': (_eventTrigger['customIdFilter'] ?? '').toString(),
            };
          } else {
            _workflowType = workflowTypeGeneral;
          }
        });
        _refreshVariableSuggestions();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandPrimary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandPrimary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.brandPrimary : AppTheme.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.brandPrimary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedTriggerConfig({bool flat = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isButton = _triggerType == 'button';
    final isEvent = _triggerType == 'event';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── SECTION 1: General Info ──
        Text(
          context.tr.scratch_workflow_metadata,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: AppTheme.brandPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: context.tr.scratch_workflow_name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _folderController,
          decoration: InputDecoration(
            labelText: context.tr.workflows_folder_label,
            hintText: context.tr.workflows_folder_hint,
            prefixIcon: const Icon(Icons.folder_outlined),
            suffixIcon: _existingFolders.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Dossiers existants',
                    onSelected: (String selection) {
                      setState(() {
                        _folderController.text = selection;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _existingFolders.map((String folder) {
                        return PopupMenuItem<String>(
                          value: folder,
                          child: Text(folder),
                        );
                      }).toList();
                    },
                  )
                : null,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),
        const SizedBox(height: 16),

        // ── SECTION 2: Trigger Type Selector ──
        Text(
          context.tr.scratch_entry_point_listen,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: getCategoryColor('EntryPoint'),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildTriggerTypeOption(
          type: 'button',
          label: context.tr.scratch_wizard_trigger_button_title,
          icon: Icons.smart_button,
        ),
        const SizedBox(height: 6),
        _buildTriggerTypeOption(
          type: 'event',
          label: context.tr.scratch_wizard_trigger_event_title,
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 6),
        _buildTriggerTypeOption(
          type: 'command',
          label: context.tr.scratch_wizard_trigger_function_title,
          icon: Icons.play_arrow,
        ),
        const SizedBox(height: 16),

        // ── SECTION 3: Trigger Settings ──
        if (isButton) ...[
          TextFormField(
            initialValue: (_eventTrigger['customIdFilter'] ?? '').toString(),
            decoration: InputDecoration(
              labelText: context.tr.scratch_custom_id_filter_label,
              hintText: context.tr.scratch_custom_id_filter_hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _eventTrigger = {
                  ..._eventTrigger,
                  'customIdFilter': value.trim(),
                };
              });
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              context.tr.scratch_custom_id_filter_desc,
              style: const TextStyle(fontSize: 11, color: AppTheme.grey),
            ),
          ),
        ] else if (isEvent) ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedCategory.isNotEmpty ? _selectedCategory : null,
            decoration: InputDecoration(
              labelText: context.tr.scratch_event_category,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: widget.eventCategories
                .map((cat) {
                  final label = widget.eventCategoryLabel != null
                      ? widget.eventCategoryLabel!(cat)
                      : cat;
                  return DropdownMenuItem(value: cat, child: Text(label));
                })
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedCategory = value;
                  final evts = widget.eventsForCategory(value);
                  if (evts.isNotEmpty) {
                    _selectedEvent = evts.first.event;
                  }
                  _eventTrigger = {
                    'category': _selectedCategory,
                    'event': _selectedEvent,
                  };
                });
                _refreshVariableSuggestions();
              }
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedEvent.isNotEmpty ? _selectedEvent : null,
            key: ValueKey('event-dropdown-$_selectedCategory'),
            decoration: InputDecoration(
              labelText: context.tr.scratch_event_name,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: widget.eventsForCategory(_selectedCategory)
                .map((def) {
                  return DropdownMenuItem(
                    value: def.event,
                    child: Text(def.label),
                  );
                })
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedEvent = value;
                  _eventTrigger = {
                    'category': _selectedCategory,
                    'event': _selectedEvent,
                  };
                });
                _refreshVariableSuggestions();
              }
            },
          ),
          const SizedBox(height: 12),
          _buildEventVariablesSection(),
        ] else ...[
          TextFormField(
            controller: _entryPointController,
            decoration: InputDecoration(
              labelText: context.tr.scratch_entry_point_label,
              hintText: context.tr.scratch_entry_point_hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              _refreshVariableSuggestions();
            },
          ),
          const SizedBox(height: 12),
          _buildArgumentsSection(),
        ],
      ],
    );
  }

  // ── Metadata Block ──

  Widget _buildMetadataBlock({bool flat = false}) {
    return ScratchBlock(
      flat: flat,
      color: getCategoryColor('Metadata'),
      title: context.tr.scratch_workflow_metadata,
      icon: Icons.description_outlined,
      required: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tr.scratch_workflow_name,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Folder
          TextFormField(
            controller: _folderController,
            decoration: InputDecoration(
              labelText: context.tr.workflows_folder_label,
              hintText: context.tr.workflows_folder_hint,
              prefixIcon: const Icon(Icons.folder_outlined),
              suffixIcon: _existingFolders.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.folder_open),
                      tooltip: 'Dossiers existants',
                      onSelected: (String selection) {
                        setState(() {
                          _folderController.text = selection;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _existingFolders.map((String folder) {
                          return PopupMenuItem<String>(
                            value: folder,
                            child: Text(folder),
                          );
                        }).toList();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Workflow type selector
          Text(
            context.tr.scratch_workflow_type,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: workflowTypeGeneral,
                label: Text(context.tr.scratch_workflow_type_general),
                icon: const Icon(Icons.account_tree_outlined),
              ),
              ButtonSegment(
                value: workflowTypeEvent,
                label: Text(context.tr.scratch_workflow_type_event),
                icon: const Icon(Icons.notifications_active_outlined),
              ),
            ],
            selected: {_workflowType},
            onSelectionChanged: (value) {
              setState(() {
                _workflowType = value.first;
                if (_workflowType == workflowTypeEvent) {
                  _ensureEventSelection();
                }
              });
              _refreshVariableSuggestions();
            },
          ),
          const SizedBox(height: 12),

          // Event variables aliases (only for event workflows)
          if (_workflowType == workflowTypeEvent)
            _buildEventVariablesSection(),

          // Arguments
          _buildArgumentsSection(),
        ],
      ),
    );
  }

  Widget _buildArgumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.tr.scratch_workflow_arguments,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 20),
              tooltip: context.tr.scratch_workflow_add_argument,
              onPressed: () {
                setState(() {
                  _arguments.add(_EditableArg(name: ''));
                });
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        for (var i = 0; i < _arguments.length; i++)
          Padding(
            key: ValueKey(_arguments[i].id),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _arguments[i].name,
                    decoration: InputDecoration(
                      hintText: context.tr.workflow_argument_hint,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      suffixIcon:
                          _arguments.length > 1
                              ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  setState(() => _arguments.removeAt(i));
                                  _refreshVariableSuggestions();
                                },
                                visualDensity: VisualDensity.compact,
                              )
                              : null,
                    ),
                    onChanged: (value) {
                      _arguments[i] = _arguments[i].copyWith(name: value);
                      _refreshVariableSuggestions();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(
                    context.tr.scratch_block_required,
                    style: const TextStyle(fontSize: 11),
                  ),
                  selected: _arguments[i].required,
                  onSelected: (value) {
                    setState(() {
                      _arguments[i] = _arguments[i].copyWith(required: value);
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Shows event-specific variables with optional alias fields.
  /// Only visible when the workflow type is "Event".
  Widget _buildEventVariablesSection() {
    final eventVars = VariableCatalog.getSuggestionsForEvent(_selectedEvent);
    if (eventVars.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        InkWell(
          onTap:
              () => setState(
                () => _eventVariablesExpanded = !_eventVariablesExpanded,
              ),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                AnimatedRotation(
                  turns: _eventVariablesExpanded ? 0.25 : 0.0, // down vs right
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppTheme.grey,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Event Variables (${eventVars.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_eventVariablesExpanded) ...[
          const SizedBox(height: 4),
          Text(
            'Optionally rename variables for this workflow.',
            style: TextStyle(fontSize: 11, color: AppTheme.grey),
          ),
          const SizedBox(height: 8),
          for (final v in eventVars)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        v.name,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppTheme.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: _eventVariableAliases[v.name] ?? '',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: v.name,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        final trimmed = value.trim();
                        setState(() {
                          if (trimmed.isEmpty) {
                            _eventVariableAliases.remove(v.name);
                          } else {
                            _eventVariableAliases[v.name] = trimmed;
                          }
                        });
                        _refreshVariableSuggestions();
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  // ── Entry Point Block ──

  Widget _buildEntryPointBlock({bool flat = false}) {
    final events = widget.eventsForCategory(_selectedCategory);

    return WorkflowEntryPointBlock(
      flat: flat,
      workflowType: _workflowType,
      entryPoint: _entryPointController.text,
      onEntryPointChanged: (value) {
        _entryPointController.text = value;
        _refreshVariableSuggestions();
      },
      eventCategories: widget.eventCategories,
      selectedCategory: _selectedCategory,
      onCategoryChanged: (value) {
        setState(() {
          _selectedCategory = value;
          final evts = widget.eventsForCategory(value);
          if (evts.isNotEmpty) {
            _selectedEvent = evts.first.event;
          }
          _eventTrigger = {
            'category': _selectedCategory,
            'event': _selectedEvent,
          };
        });
        _refreshVariableSuggestions();
      },
      eventDefinitions: events,
      selectedEvent: _selectedEvent,
      onEventChanged: (value) {
        setState(() {
          _selectedEvent = value;
          _eventTrigger = {
            'category': _selectedCategory,
            'event': _selectedEvent,
          };
        });
        _refreshVariableSuggestions();
      },
      eventCategoryLabel: widget.eventCategoryLabel,
      customIdFilter: (_eventTrigger['customIdFilter'] ?? '').toString(),
      onCustomIdFilterChanged: (value) {
        setState(() {
          _eventTrigger = {
            ..._eventTrigger,
            'customIdFilter': value.trim(),
          };
        });
      },
    );
  }

  // ── Action Blocks ──

  List<Widget> _buildActionBlocks() {
    final blocks = <Widget>[];

    // Precompute ActionItem list for Jump to action dropdown
    final allActionItems = List<ActionItem>.generate(
      _actions.length,
      (i) => ActionItem.fromJson(_actions[i], fallbackId: 'action_$i'),
    );

    for (var i = 0; i < _actions.length; i++) {
      final action = ActionItem.fromJson(_actions[i], fallbackId: 'action_$i');
      blocks.add(
        ActionBlock(
          key: ValueKey('wf-action-${action.id}'),
          action: action,
          index: i,
          totalCount: _actions.length,
          variableSuggestions: _variableSuggestions,
          emojiSuggestions: widget.appEmojis,
          botIdForConfig: widget.botId,
          onRemove: () {
            setState(() => _actions.removeAt(i));
          },
          onPasteAbove: (copiedAction) {
            setState(() {
              final copy = Map<String, dynamic>.from(
                jsonDecode(jsonEncode(copiedAction)),
              );
              copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
              _actions.insert(i, copy);
            });
            _refreshVariableSuggestions();
          },
          onPasteBelow: (copiedAction) {
            setState(() {
              final copy = Map<String, dynamic>.from(
                jsonDecode(jsonEncode(copiedAction)),
              );
              copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
              _actions.insert(i + 1, copy);
            });
            _refreshVariableSuggestions();
          },
          onDuplicate: () {
            setState(() {
              final copy = Map<String, dynamic>.from(
                jsonDecode(jsonEncode(_actions[i])),
              );
              copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
              _actions.insert(i + 1, copy);
            });
            _refreshVariableSuggestions();
          },
          onMoveUp:
              i > 0
                  ? () {
                    setState(() {
                      final item = _actions.removeAt(i);
                      _actions.insert(i - 1, item);
                    });
                  }
                  : null,
          onMoveDown:
              i < _actions.length - 1
                  ? () {
                    setState(() {
                      final item = _actions.removeAt(i);
                      _actions.insert(i + 1, item);
                    });
                  }
                  : null,
          onParameterChanged: (key, value) {
            setState(() {
              if (key == '__enabled__') {
                _actions[i]['enabled'] = value == true;
                return;
              }
              if (key == '__onErrorMode__') {
                final error = Map<String, dynamic>.from(
                  (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                );
                error['mode'] = value == 'continue' ? 'continue'
                    : (value == 'jump' ? 'jump' : (value == 'skip' ? 'skip' : 'stop'));
                _actions[i]['error'] = error;
                return;
              }
              if (key == '__onErrorJumpTarget__') {
                final error = Map<String, dynamic>.from(
                  (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                );
                error['jumpToActionId'] = value?.toString();
                _actions[i]['error'] = error;
                return;
              }
              if (key == '__onErrorSkipCount__') {
                final error = Map<String, dynamic>.from(
                  (_actions[i]['error'] as Map?)?.cast<String, dynamic>() ??
                      const {},
                );
                error['skipCount'] = value?.toString();
                _actions[i]['error'] = error;
                return;
              }
              if (key == '__actionKey__') {
                _actions[i]['key'] = value.toString();
                return;
              }
              final payload = Map<String, dynamic>.from(
                (_actions[i]['payload'] as Map?)?.cast<String, dynamic>() ??
                    const {},
              );
              payload[key] = value;
              _actions[i]['payload'] = payload;
            });
            _refreshVariableSuggestions();
          },
          onSuggestionSelected: (key, value) {
            setState(() {
              final payload = Map<String, dynamic>.from(
                (_actions[i]['payload'] as Map?)?.cast<String, dynamic>() ??
                    const {},
              );
              payload[key] = value;
              _actions[i]['payload'] = payload;
            });
            _refreshVariableSuggestions();
          },
          fieldRefreshVersionOf: (_) => 0,
          onEditNestedActions: (current, suggestions, blockName, {onChanged}) async {
            final result = await Navigator.push<List<Map<String, dynamic>>>(
              context,
              MaterialPageRoute<List<Map<String, dynamic>>>(
                builder:
                    (_) => ActionsBuilderPage(
                      initialActions: current,
                      variableSuggestions: suggestions,
                      emojiSuggestions: widget.appEmojis,
                      botIdForConfig: widget.botId,
                      editPath: ['Racine', blockName],
                      onChanged: onChanged,
                      isInteraction: false,
                      isWorkflow: true,
                    ),
              ),
            );
            return result;
          },
          allActions: allActionItems,
        ),
      );
    }
    return blocks;
  }

  // ── Add Block Button ──

  Widget _buildAddBlockButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: () {
          showBlockPalette(
            context,
            isInteraction: false,
            isWorkflow: true,
            onActionSelected: (type) {
              setState(() {
                final uniqueId = 'action_${DateTime.now().microsecondsSinceEpoch}';
                _actions.add(<String, dynamic>{
                  'id': uniqueId,
                  'type': type.name,
                  'enabled': true,
                  'key': uniqueId,
                  'depend_on': <String>[],
                  'error': {'mode': 'stop'},
                  'payload': Map<String, dynamic>.from(type.defaultParameters),
                });
              });
            },
          );
        },
        icon: const Icon(Icons.add),
        label: Text(context.tr.scratch_add_block),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  // ── Mobile Tab Editor (Edit Mode) ──

  Widget _buildMobileTabEditor() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Tab Header
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _mobileTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _mobileTab == 0 ? AppTheme.brandPrimary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.tune_outlined,
                          color: _mobileTab == 0 ? AppTheme.brandPrimary : theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.scratch_trigger_tab,
                          style: TextStyle(
                            fontWeight: _mobileTab == 0 ? FontWeight.bold : FontWeight.normal,
                            color: _mobileTab == 0 ? AppTheme.brandPrimary : theme.colorScheme.onSurfaceVariant,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _mobileTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _mobileTab == 1 ? AppTheme.brandPrimary : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_agenda_outlined,
                          color: _mobileTab == 1 ? AppTheme.brandPrimary : theme.colorScheme.onSurfaceVariant,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.actions_title,
                          style: TextStyle(
                            fontWeight: _mobileTab == 1 ? FontWeight.bold : FontWeight.normal,
                            color: _mobileTab == 1 ? AppTheme.brandPrimary : theme.colorScheme.onSurfaceVariant,
                            fontSize: 13.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: IndexedStack(
            index: _mobileTab,
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: _buildUnifiedTriggerConfig(flat: true),
              ),
              _buildStep3Actions(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile Wizard Flow ──

  Widget _buildMobileWizard() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stepsTitles = [
      context.tr.scratch_wizard_step_trigger,
      context.tr.scratch_wizard_step_config,
      context.tr.scratch_wizard_step_actions,
      context.tr.scratch_wizard_step_save,
    ];

    return PopScope(
      canPop: _wizardStep == 0,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_wizardStep > 0) {
          setState(() => _wizardStep--);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Step progress header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      stepsTitles[_wizardStep],
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "${_wizardStep + 1} / 4",
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_wizardStep + 1) / 4,
                    minHeight: 6,
                    backgroundColor: colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.brandPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Main body content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey<int>(_wizardStep),
                child: _buildWizardStepContent(),
              ),
            ),
          ),

          // Navigation Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                if (_wizardStep > 0)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _wizardStep--),
                      icon: const Icon(Icons.arrow_back),
                      label: Text(context.tr.common_back),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  )
                else
                  const Spacer(),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _wizardStep == 3 ? _save : _advanceWizardStep,
                    icon: Icon(_wizardStep == 3 ? Icons.save : Icons.arrow_forward),
                    label: Text(
                      _wizardStep == 3
                          ? context.tr.save
                          : context.tr.common_next,
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.brandPrimary,
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _advanceWizardStep() {
    if (_wizardStep == 0) {
      setState(() {
        if (_mobileTriggerType == 'button') {
          _workflowType = workflowTypeEvent;
          _selectedCategory = 'core';
          _selectedEvent = 'interactionCreate';
          _eventTrigger = {
            'category': 'core',
            'event': 'interactionCreate',
            'customIdFilter': (_eventTrigger['customIdFilter'] ?? '').toString(),
          };
        } else if (_mobileTriggerType == 'event') {
          _workflowType = workflowTypeEvent;
          if (_selectedEvent == 'interactionCreate') {
            _selectedCategory = 'messages';
            _selectedEvent = 'messageCreate';
          }
          _eventTrigger = {
            'category': _selectedCategory,
            'event': _selectedEvent,
            'customIdFilter': (_eventTrigger['customIdFilter'] ?? '').toString(),
          };
        } else {
          _workflowType = workflowTypeGeneral;
        }
        _wizardStep = 1;
      });
      _refreshVariableSuggestions();
    } else {
      setState(() {
        _wizardStep++;
      });
    }
  }

  Widget _buildWizardStepContent() {
    switch (_wizardStep) {
      case 0:
        return _buildStep1TriggerType();
      case 1:
        return _buildStep2TriggerConfig();
      case 2:
        return _buildStep3Actions();
      case 3:
        return _buildStep4SummaryAndSave();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1TriggerType() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            context.tr.scratch_wizard_trigger_instruction,
            style: const TextStyle(fontSize: 14, color: AppTheme.grey),
          ),
        ),
        _buildTriggerTypeCard(
          type: 'button',
          title: context.tr.scratch_wizard_trigger_button_title,
          desc: context.tr.scratch_wizard_trigger_button_desc,
          icon: Icons.smart_button,
        ),
        const SizedBox(height: 12),
        _buildTriggerTypeCard(
          type: 'event',
          title: context.tr.scratch_wizard_trigger_event_title,
          desc: context.tr.scratch_wizard_trigger_event_desc,
          icon: Icons.flash_on,
        ),
        const SizedBox(height: 12),
        _buildTriggerTypeCard(
          type: 'command',
          title: context.tr.scratch_wizard_trigger_function_title,
          desc: context.tr.scratch_wizard_trigger_function_desc,
          icon: Icons.play_arrow,
        ),
      ],
    );
  }

  Widget _buildTriggerTypeCard({
    required String type,
    required String title,
    required String desc,
    required IconData icon,
  }) {
    final isSelected = _mobileTriggerType == type;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        setState(() {
          _mobileTriggerType = type;
        });
        _advanceWizardStep();
      },
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandPrimary.withValues(alpha: 0.08)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandPrimary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? AppTheme.brandPrimary : AppTheme.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppTheme.brandPrimary : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2TriggerConfig() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_mobileTriggerType == 'button') ...[
            Text(
              context.tr.scratch_wizard_config_button_instruction,
              style: const TextStyle(fontSize: 13, color: AppTheme.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: (_eventTrigger['customIdFilter'] ?? '').toString(),
              decoration: InputDecoration(
                labelText: context.tr.scratch_custom_id_filter_label,
                hintText: context.tr.scratch_custom_id_filter_hint,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _eventTrigger = {
                    ..._eventTrigger,
                    'customIdFilter': value.trim(),
                  };
                });
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                context.tr.scratch_custom_id_filter_desc,
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
            ),
          ] else if (_mobileTriggerType == 'event') ...[
            _buildEntryPointBlock(),
            if (_workflowType == workflowTypeEvent) ...[
              const SizedBox(height: 16),
              _buildEventVariablesSection(),
            ],
          ] else ...[
            _buildEntryPointBlock(),
            const SizedBox(height: 16),
            _buildArgumentsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildStep3Actions() {
    return ScratchBlockCanvas(
      skipConnectorAfterIndices: _buildFinalBlockIndices(showHeaderBlocks: false),
      children: [
        if (_actions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: Column(
              children: [
                Icon(Icons.view_agenda_outlined, size: 48, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  context.tr.scratch_wizard_actions_empty_title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr.scratch_wizard_actions_empty_desc,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppTheme.grey),
                ),
              ],
            ),
          )
        else
          ..._buildActionBlocks(),
        _buildAddBlockButton(),
      ],
    );
  }

  Widget _buildStep4SummaryAndSave() {
    final theme = Theme.of(context);
    final isButton = _mobileTriggerType == 'button';
    final isEvent = _mobileTriggerType == 'event';

    String triggerSummary = '';
    if (isButton) {
      final cid = _eventTrigger['customIdFilter'] ?? '';
      triggerSummary = context.tr.scratch_wizard_summary_trigger_button(cid.toString());
    } else if (isEvent) {
      triggerSummary = context.tr.scratch_wizard_summary_trigger_event(_selectedEvent);
    } else {
      triggerSummary = context.tr.scratch_wizard_summary_trigger_function;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr.scratch_wizard_summary_title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.flash_on, size: 18, color: AppTheme.brandPrimary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        triggerSummary,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.view_agenda, size: 18, color: AppTheme.success),
                    const SizedBox(width: 8),
                    Text(
                      context.tr.scratch_wizard_summary_actions_count(_actions.length),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr.scratch_wizard_save_details,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tr.scratch_wizard_workflow_name_label,
              hintText: context.tr.scratch_wizard_workflow_name_hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _folderController,
            decoration: InputDecoration(
              labelText: context.tr.scratch_wizard_folder_label,
              hintText: context.tr.scratch_wizard_folder_hint,
              prefixIcon: const Icon(Icons.folder_outlined),
              suffixIcon: _existingFolders.isNotEmpty
                  ? PopupMenuButton<String>(
                      icon: const Icon(Icons.folder_open),
                      onSelected: (String selection) {
                        setState(() {
                          _folderController.text = selection;
                        });
                      },
                      itemBuilder: (BuildContext context) {
                        return _existingFolders.map((String folder) {
                          return PopupMenuItem<String>(
                            value: folder,
                            child: Text(folder),
                          );
                        }).toList();
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight editable argument model (private to this file).
class _EditableArg {
  final String id;
  final String name;
  final bool required;
  final String defaultValue;

  _EditableArg({
    String? id,
    required this.name,
    this.required = false,
    this.defaultValue = '',
  }) : id = id ?? UniqueKey().toString();

  _EditableArg copyWith({String? name, bool? required, String? defaultValue}) {
    return _EditableArg(
      id: id,
      name: name ?? this.name,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}
