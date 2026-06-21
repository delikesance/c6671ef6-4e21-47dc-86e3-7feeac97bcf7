import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:flutter/material.dart';

import 'scratch_block.dart';
import 'scratch_block_palette.dart';
import 'package:bot_creator/core/theme/app_theme.dart';

/// Describes what the command listens for.
enum CommandEntryPointType {
  /// Slash command interaction (Discord Application Command).
  interaction,

  /// Legacy prefix-based message command.
  message,
}

/// A fixed (non-deletable) block that shows what triggers the command.
///
/// For commands this is "Listens for an Interaction" or "Listens for a Message".
/// For workflows this is an event trigger or entry-point function — see
/// [WorkflowEntryPointBlock].
class EntryPointBlock extends StatefulWidget {
  const EntryPointBlock({
    super.key,
    required this.entryPointType,
    required this.onEntryPointTypeChanged,
    // Legacy prefix options
    this.legacyModeEnabled = false,
    this.onLegacyModeChanged,
    this.legacyPrefixOverride = '',
    this.onLegacyPrefixOverrideChanged,
    this.legacyResponseTarget = 'reply',
    this.onLegacyResponseTargetChanged,
    // Execution mode
    this.executionMode = 'workflow',
    this.onExecutionModeChanged,
  });

  final CommandEntryPointType entryPointType;
  final ValueChanged<CommandEntryPointType> onEntryPointTypeChanged;

  final bool legacyModeEnabled;
  final ValueChanged<bool>? onLegacyModeChanged;
  final String legacyPrefixOverride;
  final ValueChanged<String>? onLegacyPrefixOverrideChanged;
  final String legacyResponseTarget;
  final ValueChanged<String>? onLegacyResponseTargetChanged;

  /// `'workflow'` for visual blocks, `'bdfd_script'` for BDFD script.
  final String executionMode;
  final ValueChanged<String>? onExecutionModeChanged;

  @override
  State<EntryPointBlock> createState() => _EntryPointBlockState();
}

class _EntryPointBlockState extends State<EntryPointBlock> {
  bool _collapsed = false;
  bool _legacyExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isInteraction =
        widget.entryPointType == CommandEntryPointType.interaction;
    final colorScheme = Theme.of(context).colorScheme;

    return ScratchBlock(
      color: getCategoryColor('EntryPoint'),
      title: context.tr.scratch_block_entry_point,
      icon: Icons.play_circle_outline,
      required: true,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      badge: ScratchBlockBadge(
        label: context.tr.scratch_block_required,
        color: getCategoryColor('EntryPoint'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Entry point type selector ──
          Text(
            context.tr.scratch_entry_point_listen,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          SegmentedButton<CommandEntryPointType>(
            segments: <ButtonSegment<CommandEntryPointType>>[
              ButtonSegment<CommandEntryPointType>(
                value: CommandEntryPointType.interaction,
                label: Text(context.tr.scratch_entry_interaction),
                icon: const Icon(Icons.bolt),
              ),
              ButtonSegment<CommandEntryPointType>(
                value: CommandEntryPointType.message,
                label: Text(context.tr.scratch_entry_message),
                icon: const Icon(Icons.chat_bubble_outline),
              ),
            ],
            selected: <CommandEntryPointType>{widget.entryPointType},
            onSelectionChanged: (selection) {
              widget.onEntryPointTypeChanged(selection.first);
            },
          ),

          const SizedBox(height: 12),

          // ── Execution mode selector ──
          if (widget.onExecutionModeChanged != null) ...[
            Text(
              context.tr.scratch_execution_mode,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: <ButtonSegment<String>>[
                ButtonSegment<String>(
                  value: 'workflow',
                  label: Text(context.tr.scratch_mode_blocks),
                  icon: const Icon(Icons.view_agenda),
                ),
                ButtonSegment<String>(
                  value: 'bdfd_script',
                  label: Text(context.tr.scratch_mode_bdfd),
                  icon: const Icon(Icons.code),
                ),
                ButtonSegment<String>(
                  value: 'javascript',
                  label: Text(context.tr.js_editor_segmented_label),
                  icon: const Icon(Icons.javascript),
                ),
              ],
              selected: <String>{widget.executionMode},
              onSelectionChanged: (selection) {
                widget.onExecutionModeChanged!(selection.first);
              },
            ),
            const SizedBox(height: 12),
          ],

          // ── Legacy prefix config (expandable) ──
          if (!isInteraction ||
              (widget.legacyModeEnabled && widget.onLegacyModeChanged != null))
            _buildLegacySection(colorScheme),
        ],
      ),
    );
  }

  Widget _buildLegacySection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _legacyExpanded = !_legacyExpanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  _legacyExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr.scratch_legacy_config,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_legacyExpanded) ...[
          if (widget.onLegacyModeChanged != null)
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr.command_legacy_mode_title),
              subtitle: Text(context.tr.legacy_prefix_mode_subtitle),
              value: widget.legacyModeEnabled,
              onChanged: widget.onLegacyModeChanged,
            ),
          if (widget.legacyModeEnabled) ...[
            const SizedBox(height: 8),
            if (widget.onLegacyPrefixOverrideChanged != null)
              TextFormField(
                initialValue: widget.legacyPrefixOverride,
                decoration: InputDecoration(
                  labelText: context.tr.legacy_prefix_override_label,
                  hintText: context.tr.legacy_prefix_override_hint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: widget.onLegacyPrefixOverrideChanged,
              ),
            if (widget.onLegacyResponseTargetChanged != null) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: widget.legacyResponseTarget,
                decoration: InputDecoration(
                  labelText: context.tr.legacy_response_mode_label,
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'reply',
                    child: Text(context.tr.command_response_mode_reply),
                  ),
                  DropdownMenuItem(
                    value: 'channelSend',
                    child: Text(context.tr.command_response_mode_channel),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    widget.onLegacyResponseTargetChanged!(value);
                  }
                },
              ),
            ],
          ],
        ],
      ],
    );
  }
}

/// Entry-point block for workflows (event trigger or general entry function).
class WorkflowEntryPointBlock extends StatefulWidget {
  const WorkflowEntryPointBlock({
    super.key,
    required this.workflowType,
    this.entryPoint = 'main',
    this.onEntryPointChanged,
    // Event trigger fields
    this.eventCategories = const [],
    this.selectedCategory = '',
    this.onCategoryChanged,
    this.eventDefinitions = const [],
    this.selectedEvent = '',
    this.onEventChanged,
    this.eventCategoryLabel,
    this.eventVariablePreview = const [],
  });

  /// `'general'` or `'event'`.
  final String workflowType;

  /// Entry point function name (for general workflows).
  final String entryPoint;
  final ValueChanged<String>? onEntryPointChanged;

  // Event trigger fields (for event workflows)
  final List<String> eventCategories;
  final String selectedCategory;
  final ValueChanged<String>? onCategoryChanged;
  final List<WorkflowEventItem> eventDefinitions;
  final String selectedEvent;
  final ValueChanged<String>? onEventChanged;
  final String Function(String category)? eventCategoryLabel;
  final List<String> eventVariablePreview;

  @override
  State<WorkflowEntryPointBlock> createState() =>
      _WorkflowEntryPointBlockState();
}

class _WorkflowEntryPointBlockState extends State<WorkflowEntryPointBlock> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final isEvent = widget.workflowType == 'event';

    return ScratchBlock(
      color: getCategoryColor('EntryPoint'),
      title:
          isEvent
              ? context.tr.scratch_entry_event_trigger
              : context.tr.scratch_entry_function,
      icon: isEvent ? Icons.flash_on : Icons.play_arrow,
      required: true,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      badge: ScratchBlockBadge(
        label: context.tr.scratch_block_required,
        color: getCategoryColor('EntryPoint'),
      ),
      child: isEvent ? _buildEventTrigger() : _buildGeneralEntryPoint(),
    );
  }

  Widget _buildGeneralEntryPoint() {
    return TextFormField(
      initialValue: widget.entryPoint,
      decoration: InputDecoration(
        labelText: context.tr.scratch_entry_point_label,
        hintText: context.tr.scratch_entry_point_hint,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: widget.onEntryPointChanged,
    );
  }

  Widget _buildEventTrigger() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Category dropdown ──
        DropdownButtonFormField<String>(
          initialValue:
              widget.selectedCategory.isNotEmpty
                  ? widget.selectedCategory
                  : null,
          decoration: InputDecoration(
            labelText: context.tr.scratch_event_category,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: widget.eventCategories
              .map((cat) {
                final label =
                    widget.eventCategoryLabel != null
                        ? widget.eventCategoryLabel!(cat)
                        : cat;
                return DropdownMenuItem(value: cat, child: Text(label));
              })
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) widget.onCategoryChanged?.call(value);
          },
        ),
        const SizedBox(height: 12),

        // ── Event dropdown ──
        DropdownButtonFormField<String>(
          initialValue:
              widget.selectedEvent.isNotEmpty ? widget.selectedEvent : null,
          decoration: InputDecoration(
            labelText: context.tr.scratch_event_name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: widget.eventDefinitions
              .map((def) {
                return DropdownMenuItem(
                  value: def.event,
                  child: Text(def.label),
                );
              })
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) widget.onEventChanged?.call(value);
          },
        ),

        // ── Variable preview ──
        if (widget.eventVariablePreview.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            context.tr.scratch_event_variables,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: widget.eventVariablePreview
                .take(12)
                .map(
                  (v) => Chip(
                    label: Text(v, style: const TextStyle(fontSize: 11)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

/// Lightweight model for event definitions used by [WorkflowEntryPointBlock].
class WorkflowEventItem {
  const WorkflowEventItem({
    required this.event,
    required this.label,
    this.description = '',
  });

  final String event;
  final String label;
  final String description;
}
