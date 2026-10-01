import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_factory.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/theme/app_theme.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Visual editor for traditional "normal" message components (only ActionRows containing Buttons/Selects).
/// Manages a [ComponentV2Definition] but strictly limits available types.
class NormalComponentEditorWidget extends StatefulWidget {
  final ComponentV2Definition definition;
  final ValueChanged<ComponentV2Definition> onChanged;
  final List<VariableSuggestion> variableSuggestions;
  final String? botIdForConfig;

  const NormalComponentEditorWidget({
    super.key,
    required this.definition,
    required this.onChanged,
    required this.variableSuggestions,
    this.botIdForConfig,
  });

  @override
  State<NormalComponentEditorWidget> createState() =>
      _NormalComponentEditorWidgetState();
}

class _NormalComponentEditorWidgetState
    extends State<NormalComponentEditorWidget> {
  late List<ComponentNode> _components;

  @override
  void initState() {
    super.initState();
    _initFromWidget();
  }

  @override
  void didUpdateWidget(NormalComponentEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.definition != oldWidget.definition) {
      _initFromWidget();
    }
  }

  void _initFromWidget() {
    // Deep copy components via json serialization round-trip
    _components = widget.definition.components
        .map((c) => ComponentNode.fromJson(c.toJson()))
        // Ensure we strictly keep only ActionRows at root level
        .whereType<ActionRowNode>()
        .toList();
  }

  void _emit() {
    widget.onChanged(
      ComponentV2Definition(
        content: widget.definition.content,
        components: _components
            .map((c) => ComponentNode.fromJson(c.toJson()))
            .toList(),
        ephemeral: widget.definition.ephemeral,
      ),
    );
  }

  void _addNode() {
    if (_components.length >= 5) {
      return; // Discord limit: max 5 Action Rows per message
    }
    setState(() => _components.add(ActionRowNode()));
    _emit();
  }

  void _removeNode(int index) {
    setState(() => _components.removeAt(index));
    _emit();
  }

  Future<void> _confirmAndRemoveNode(int index) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.component_remove_row_title,
      content: context.tr.component_remove_confirm,
      confirmLabel: context.tr.common_remove,
      isDestructive: true,
    );
    if (!shouldDelete) {
      return;
    }
    _removeNode(index);
  }

  void _updateNode(int index, ComponentNode updated) {
    setState(() {
      _components[index] = updated;
    });
    _emit();
  }

  // A custom locked-down ActionRow editor for "Normal" message components.
  // It only allows Button and Select Menus inside the rows.
  Widget _buildNormalActionRowEditor(ActionRowNode row, int index) {
    final rowKey = row.components.isNotEmpty
        ? row.components
              .map((c) {
                if (c is ButtonNode) return c.customId;
                if (c is SelectMenuNode) return c.customId;
                return '';
              })
              .join('-')
        : 'row_$index';
    return Card(
      key: ValueKey(rowKey),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppTheme.grey),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIcon.fromMaterial(
                  Icons.view_stream,
                  size: 16,
                  color: AppTheme.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  context.tr.component_action_row,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.grey,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const AppIcon.fromMaterial(
                    Icons.delete,
                    size: 16,
                    color: AppTheme.error,
                  ),
                  onPressed: () {
                    _confirmAndRemoveNode(index);
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...row.components.asMap().entries.map((e) {
                  final childIdx = e.key;
                  final child = e.value;
                  String? childKey;
                  if (child is ButtonNode) {
                    childKey = child.customId;
                  } else if (child is SelectMenuNode) {
                    childKey = child.customId;
                  }
                  return ComponentNodeEditor(
                    key: childKey != null ? ValueKey(childKey) : null,
                    node: child,
                    onChanged: (updated) {
                      final newChildren = List<ComponentNode>.from(
                        row.components,
                      );
                      newChildren[childIdx] = updated;
                      row.components = newChildren;
                      _updateNode(index, row);
                    },
                    onRemove: () {
                      final newChildren = List<ComponentNode>.from(
                        row.components,
                      )..removeAt(childIdx);
                      row.components = newChildren;
                      _updateNode(index, row);
                    },
                    variableSuggestions: widget.variableSuggestions,
                    botIdForConfig: widget.botIdForConfig,
                  );
                }),
                Builder(
                  builder: (context) {
                    final components = row.components;
                    final buttonCount = components
                        .whereType<ButtonNode>()
                        .length;
                    final hasSelect = components.any(
                      (c) => c is SelectMenuNode,
                    );

                    List<ComponentV2Type>? allowedTypes;
                    if (hasSelect) {
                      allowedTypes = [];
                    } else if (buttonCount > 0) {
                      if (buttonCount < 5) {
                        allowedTypes = [ComponentV2Type.button];
                      } else {
                        allowedTypes = [];
                      }
                    } else {
                      allowedTypes = [
                        ComponentV2Type.button,
                        ComponentV2Type.stringSelect,
                        ComponentV2Type.userSelect,
                        ComponentV2Type.roleSelect,
                        ComponentV2Type.mentionableSelect,
                        ComponentV2Type.channelSelect,
                        ComponentV2Type.categorySelect,
                        ComponentV2Type.voiceSelect,
                      ];
                    }

                    if (allowedTypes.isEmpty) return const SizedBox.shrink();

                    return _buildAddComponentDropdown((newNode) {
                      row.components = [...row.components, newNode];
                      _updateNode(index, row);
                    }, allowedTypes: allowedTypes);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddComponentDropdown(
    ValueChanged<ComponentNode> onAdd, {
    List<ComponentV2Type>? allowedTypes,
  }) {
    final types =
        allowedTypes ??
        [
          ComponentV2Type.button,
          ComponentV2Type.stringSelect,
          ComponentV2Type.userSelect,
          ComponentV2Type.roleSelect,
          ComponentV2Type.mentionableSelect,
          ComponentV2Type.channelSelect,
          ComponentV2Type.categorySelect,
          ComponentV2Type.voiceSelect,
        ];
    final isOnlyButton =
        types.length == 1 && types.first == ComponentV2Type.button;
    final dropdownLabel = isOnlyButton
        ? context.tr.component_add_button
        : context.tr.component_add_button_or_select;
    return PopupMenuButton<ComponentV2Type>(
      tooltip: context.tr.component_add_child,
      onSelected: (type) {
        onAdd(ComponentNodeFactory.create(type));
      },
      itemBuilder: (context) {
        return types
            .map(
              (t) => PopupMenuItem(
                value: t,
                child: Text(
                  t.name[0].toUpperCase() +
                      t.name
                          .substring(1)
                          .replaceAllMapped(
                            RegExp(r'[A-Z]'),
                            (m) => ' ${m.group(0)}',
                          ),
                ),
              ),
            )
            .toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.grey, width: 2),
          borderRadius: BorderRadius.circular(AppTheme.radiusXs),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AppIcon.fromMaterial(
              Icons.add_circle_outline,
              size: 16,
              color: AppTheme.grey,
            ),
            const SizedBox(width: 8),
            Text(
              dropdownLabel,
              style: const TextStyle(
                color: AppTheme.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.info, AppTheme.info.withValues(alpha: 0.7)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              const AppIcon.fromMaterial(
                Icons.dashboard_customize,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr.reply_buttons_optional,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  '${_components.length}/5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.info.withValues(alpha: 0.3)),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._components.asMap().entries.map((entry) {
                final index = entry.key;
                final node = entry.value as ActionRowNode;
                return _buildNormalActionRowEditor(node, index);
              }),
              const SizedBox(height: 8),
              if (_components.length < 5)
                InkWell(
                  onTap: _addNode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.grey),
                      borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                    ),
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(
                          Icons.add,
                          size: 16,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr.component_add_action_row,
                          style: const TextStyle(
                            color: AppTheme.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
