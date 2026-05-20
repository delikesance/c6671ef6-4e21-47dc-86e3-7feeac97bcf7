import 'dart:async';
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

  List<VariableSuggestion> _variableSuggestions = [];
  bool _saving = false;

  bool get _isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();

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
      _arguments.add(const _EditableArg(name: ''));
    }

    _actions = List<Map<String, dynamic>>.from(
      (normalized?['actions'] as List?)?.whereType<Map>().map(
            (item) => Map<String, dynamic>.from(item),
          ) ??
          const <Map<String, dynamic>>[],
    );

    _ensureEventSelection();
    _refreshVariableSuggestions();
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
    if (!cats.contains(_selectedCategory) && cats.isNotEmpty) {
      _selectedCategory = cats.first;
    }
    final events = widget.eventsForCategory(_selectedCategory);
    if (events.isNotEmpty && !events.any((e) => e.event == _selectedEvent)) {
      _selectedEvent = events.first.event;
    }
    _eventTrigger = {'category': _selectedCategory, 'event': _selectedEvent};
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
    if (mounted) {
      setState(() => _variableSuggestions = suggestions);
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
            final maxWidth =
                constraints.maxWidth >= 1200
                    ? 980.0
                    : (constraints.maxWidth >= 900 ? 860.0 : 680.0);

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.spacingLg),
                  child: ScratchBlockCanvas(
                    skipConnectorAfterIndices: _buildFinalBlockIndices(),
                    children: _buildBlocks(),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildBlocks() {
    return [
      // ── Metadata block ──
      _buildMetadataBlock(),

      // ── Entry Point block ──
      _buildEntryPointBlock(),

      // ── Action blocks ──
      ..._buildActionBlocks(),

      // ── Add button ──
      _buildAddBlockButton(),
    ];
  }

  /// Indices (in the canvas children list) of final / cap blocks after which
  /// no connector should be drawn.
  Set<int> _buildFinalBlockIndices() {
    const offset = 2; // MetadataBlock + EntryPointBlock
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

  // ── Metadata Block ──

  Widget _buildMetadataBlock() {
    return ScratchBlock(
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
                  _arguments.add(const _EditableArg(name: ''));
                });
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        for (var i = 0; i < _arguments.length; i++)
          Padding(
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

  // ── Entry Point Block ──

  Widget _buildEntryPointBlock() {
    final events = widget.eventsForCategory(_selectedCategory);

    return WorkflowEntryPointBlock(
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
    );
  }

  // ── Action Blocks ──

  List<Widget> _buildActionBlocks() {
    final blocks = <Widget>[];
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
                error['mode'] = value == 'continue' ? 'continue' : 'stop';
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
                    ),
              ),
            );
            return result;
          },
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
            onActionSelected: (type) {
              setState(() {
                _actions.add(<String, dynamic>{
                  'id': 'action_${_actions.length}',
                  'type': type.name,
                  'enabled': true,
                  'key': 'action_${_actions.length}',
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
}

/// Lightweight editable argument model (private to this file).
class _EditableArg {
  final String name;
  final bool required;
  final String defaultValue;

  const _EditableArg({
    required this.name,
    this.required = false,
    this.defaultValue = '',
  });

  _EditableArg copyWith({String? name, bool? required, String? defaultValue}) {
    return _EditableArg(
      name: name ?? this.name,
      required: required ?? this.required,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }
}
