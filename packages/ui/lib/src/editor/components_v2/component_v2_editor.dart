import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/component.dart';
import '../models/variable_suggestion.dart';
import './component_node_editor.dart';
import './component_node_factory.dart';
import '../../l10n/tr_extension.dart';

import '../../theme/app_theme.dart';

import '../../widgets/app_icon.dart';

/// Full visual editor for a ComponentV2 message (text + recursive component nodes).
/// Manages a [ComponentV2Definition] and notifies via [onChanged].
class ComponentV2EditorWidget extends StatefulWidget {
  final ComponentV2Definition definition;
  final ValueChanged<ComponentV2Definition> onChanged;
  final List<VariableSuggestion> variableSuggestions;
  final String? botIdForConfig;

  const ComponentV2EditorWidget({
    super.key,
    required this.definition,
    required this.onChanged,
    required this.variableSuggestions,
    this.botIdForConfig,
  });

  @override
  State<ComponentV2EditorWidget> createState() =>
      _ComponentV2EditorWidgetState();
}

class _ComponentV2EditorWidgetState extends State<ComponentV2EditorWidget> {
  late List<ComponentNode> _components;
  late bool _ephemeral;

  @override
  void initState() {
    super.initState();
    _initFromWidget();
  }

  @override
  void didUpdateWidget(ComponentV2EditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the external definition reference has changed, re-sync our local state
    // to prevent losing data visually when the parent redraws.
    if (widget.definition != oldWidget.definition) {
      _initFromWidget();
    }
  }

  void _initFromWidget() {
    // Deep copy components via json serialization round-trip
    _components = widget.definition.components
        .map((c) => ComponentNode.fromJson(c.toJson()))
        .toList();
    _ephemeral = widget.definition.ephemeral;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ComponentV2Definition(
        content: '',
        components: _components
            .map((c) => ComponentNode.fromJson(c.toJson()))
            .toList(),
        ephemeral: _ephemeral,
      ),
    );
  }

  void _addNode(ComponentV2Type type) {
    setState(() => _components.add(ComponentNodeFactory.create(type)));
    _emit();
  }

  void _removeNode(int index) {
    setState(() => _components.removeAt(index));
    _emit();
  }

  void _updateNode(int index, ComponentNode updated) {
    setState(() {
      _components[index] = updated;
    });
    _emit();
  }

  String _getTitleForType(ComponentV2Type type) =>
      ComponentNodeFactory.labelFor(type);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header bar — surface neutre du thème : le violet n'est plus utilisé
        // comme remplissage décoratif.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              AppIcon.fromMaterial(
                Icons.dashboard_customize,
                size: 18,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.reply_mode_layout,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      context.tr.reply_mode_layout_desc,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
                child: Text(
                  '${_components.length}',
                  style: TextStyle(
                    color: scheme.onSurface,
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
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  context.tr.component_ephemeral_hint,
                  style: TextStyle(fontSize: 13),
                ),
                value: _ephemeral,
                onChanged: (v) {
                  setState(() => _ephemeral = v);
                  _emit();
                },
              ),
              const Divider(height: 16),
              // Render root components
              ..._components.asMap().entries.map((entry) {
                final index = entry.key;
                final node = entry.value;
                String? nodeKey;
                if (node is ButtonNode) {
                  nodeKey = node.customId;
                } else if (node is SelectMenuNode) {
                  nodeKey = node.customId;
                } else if (node is ModalTextInputNode) {
                  nodeKey = node.customId;
                } else if (node is ActionRowNode) {
                  nodeKey = node.components
                      .map((c) {
                        if (c is ButtonNode) return c.customId;
                        if (c is SelectMenuNode) return c.customId;
                        return '';
                      })
                      .join('-');
                }
                return ComponentNodeEditor(
                  key: nodeKey != null && nodeKey.isNotEmpty
                      ? ValueKey(nodeKey)
                      : ValueKey('root_$index'),
                  node: node,
                  onChanged: (updated) => _updateNode(index, updated),
                  onRemove: () => _removeNode(index),
                  variableSuggestions: widget.variableSuggestions,
                  botIdForConfig: widget.botIdForConfig,
                );
              }),
              const SizedBox(height: 8),
              // Add root component dropdown
              PopupMenuButton<ComponentV2Type>(
                tooltip: context.tr.component_add_root,
                onSelected: (v) {
                  _addNode(v);
                },
                itemBuilder: (BuildContext context) {
                  final rootTypes = [
                    ComponentV2Type.container,
                    ComponentV2Type.actionRow,
                    ComponentV2Type.section,
                    ComponentV2Type.textDisplay,
                    ComponentV2Type.mediaGallery,
                    ComponentV2Type.file,
                    ComponentV2Type.separator,
                  ];
                  return rootTypes
                      .map(
                        (t) => PopupMenuItem(
                          value: t,
                          child: Text(_getTitleForType(t)),
                        ),
                      )
                      .toList();
                },
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
                      AppIcon.fromMaterial(
                        Icons.add,
                        size: 16,
                        color: AppTheme.grey,
                      ),
                      SizedBox(width: 8),
                      Text(
                        context.tr.component_add_root,
                        style: TextStyle(
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
