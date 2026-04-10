import 'package:flutter/material.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/routes/app/workflows.page.dart';
import 'package:bot_creator/types/component.dart';
import 'package:bot_creator/types/variable_suggestion.dart';
import 'dart:convert';
import 'package:bot_creator/widgets/variable_text_field.dart';
import 'package:bot_creator/widgets/component_v2_builder/component_node_factory.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../../utils/i18n.dart';

/// Depth-based accent colours for nesting levels (0 = root).
const _kDepthColors = [
  Colors.blueGrey,
  Colors.blue,
  Colors.green,
  Colors.orange,
  Colors.purple,
];

Color _depthColor(int depth) =>
    _kDepthColors[depth.clamp(0, _kDepthColors.length - 1)];

class ComponentNodeEditor extends StatelessWidget {
  final ComponentNode node;
  final ValueChanged<ComponentNode> onChanged;
  final VoidCallback onRemove;

  /// Optional: show an "up" arrow to move this node earlier in its parent list.
  final VoidCallback? onMoveUp;

  /// Optional: show a "down" arrow to move this node later in its parent list.
  final VoidCallback? onMoveDown;

  /// Nesting depth — 0 for root nodes, +1 for each level of children.
  final int depth;
  final List<VariableSuggestion> variableSuggestions;
  final String? botIdForConfig;

  const ComponentNodeEditor({
    super.key,
    required this.node,
    required this.onChanged,
    required this.onRemove,
    this.onMoveUp,
    this.onMoveDown,
    this.depth = 0,
    required this.variableSuggestions,
    this.botIdForConfig,
  });

  Future<void> _confirmAndRemove(BuildContext context) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (dialogContext) => AlertDialog.adaptive(
                title: Text(context.tr.component_remove_title),
                content: Text(context.tr.component_remove_confirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.tr.common_cancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(
                      context.tr.common_remove,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
    if (!shouldDelete) {
      return;
    }
    onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _depthColor(depth);
    final indent = depth * 8.0;
    return Padding(
      padding: EdgeInsets.only(left: indent, top: 4, bottom: 4),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: accentColor.withValues(alpha: 0.6),
              width: 3,
            ),
          ),
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: depth == 0 ? 1 : 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: accentColor.withValues(alpha: 0.2)),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForType(node.type),
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTitleForType(node.type),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: depth == 0 ? 13 : 12,
                        color: accentColor,
                      ),
                    ),
                    if (depth > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'L$depth',
                            style: TextStyle(
                              fontSize: 9,
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (onMoveUp != null)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 14),
                          tooltip: context.tr.common_move_up,
                          onPressed: onMoveUp,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    if (onMoveDown != null)
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 14),
                          tooltip: context.tr.common_move_down,
                          onPressed: onMoveDown,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        tooltip: context.tr.common_remove,
                        onPressed: () {
                          _confirmAndRemove(context);
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildEditorBody(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(ComponentV2Type type) {
    return switch (type) {
      ComponentV2Type.actionRow => Icons.view_stream,
      ComponentV2Type.button => Icons.smart_button,
      ComponentV2Type.stringSelect => Icons.list,
      ComponentV2Type.userSelect => Icons.person,
      ComponentV2Type.roleSelect => Icons.admin_panel_settings,
      ComponentV2Type.mentionableSelect => Icons.alternate_email,
      ComponentV2Type.channelSelect => Icons.tag,
      ComponentV2Type.section => Icons.view_agenda,
      ComponentV2Type.textDisplay => Icons.text_fields,
      ComponentV2Type.thumbnail => Icons.image,
      ComponentV2Type.mediaGallery => Icons.photo_library,
      ComponentV2Type.file => Icons.insert_drive_file,
      ComponentV2Type.separator => Icons.horizontal_rule,
      ComponentV2Type.container => Icons.aspect_ratio,
      ComponentV2Type.label => Icons.label,
      ComponentV2Type.fileUpload => Icons.upload_file,
      ComponentV2Type.radioGroup => Icons.radio_button_checked,
      ComponentV2Type.checkboxGroup => Icons.check_box,
      ComponentV2Type.checkbox => Icons.check_box_outline_blank,
    };
  }

  String _getTitleForType(ComponentV2Type type) =>
      ComponentNodeFactory.labelFor(type);

  Widget _buildEditorBody(BuildContext context) {
    if (node is ActionRowNode) {
      return _buildActionRowEditor(node as ActionRowNode, context);
    }
    if (node is ButtonNode) {
      return _buildButtonEditor(node as ButtonNode, context);
    }
    if (node is SelectMenuNode) {
      return _buildSelectMenuEditor(node as SelectMenuNode, context);
    }
    if (node is TextDisplayNode) {
      return _buildTextDisplayEditor(node as TextDisplayNode, context);
    }
    if (node is SeparatorNode) {
      return _buildSeparatorEditor(node as SeparatorNode, context);
    }
    if (node is SectionNode) {
      return _buildSectionEditor(node as SectionNode, context);
    }
    if (node is ContainerNode) {
      return _buildContainerEditor(node as ContainerNode, context);
    }
    if (node is LabelNode) return _buildLabelEditor(node as LabelNode, context);
    if (node is CheckboxNode) {
      return _buildCheckboxEditor(node as CheckboxNode, context);
    }
    if (node is RadioGroupNode) {
      return _buildRadioGroupEditor(node as RadioGroupNode, context);
    }
    if (node is CheckboxGroupNode) {
      return _buildCheckboxGroupEditor(node as CheckboxGroupNode, context);
    }
    if (node is FileUploadNode) {
      return _buildFileUploadEditor(node as FileUploadNode, context);
    }
    if (node is FileNode) return _buildFileEditor(node as FileNode, context);
    if (node is ThumbnailNode) {
      return _buildThumbnailEditor(node as ThumbnailNode, context);
    }
    if (node is MediaGalleryNode) {
      return _buildMediaGalleryEditor(node as MediaGalleryNode, context);
    }
    return Text(context.tr.component_not_implemented);
  }

  Widget _buildResponsiveTwoFieldRow({
    required Widget first,
    required Widget second,
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 8), second],
          );
        }

        return Row(
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 8),
            Expanded(flex: secondFlex, child: second),
          ],
        );
      },
    );
  }

  // --- Node Editors ---

  Widget _buildActionRowEditor(ActionRowNode row, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...row.components.asMap().entries.map((e) {
          final idx = e.key;
          final child = e.value;
          return ComponentNodeEditor(
            node: child,
            depth: depth + 1,
            onChanged: (updated) {
              final newChildren = List<ComponentNode>.from(row.components);
              newChildren[idx] = updated;
              row.components = newChildren;
              onChanged(row);
            },
            onRemove: () {
              final newChildren = List<ComponentNode>.from(row.components)
                ..removeAt(idx);
              row.components = newChildren;
              onChanged(row);
            },
            onMoveUp:
                idx == 0
                    ? null
                    : () {
                      final list = List<ComponentNode>.from(row.components);
                      final tmp = list[idx - 1];
                      list[idx - 1] = list[idx];
                      list[idx] = tmp;
                      row.components = list;
                      onChanged(row);
                    },
            onMoveDown:
                idx == row.components.length - 1
                    ? null
                    : () {
                      final list = List<ComponentNode>.from(row.components);
                      final tmp = list[idx + 1];
                      list[idx + 1] = list[idx];
                      list[idx] = tmp;
                      row.components = list;
                      onChanged(row);
                    },
            variableSuggestions: variableSuggestions,
            botIdForConfig: botIdForConfig,
          );
        }),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final components = row.components;
            final buttonCount = components.whereType<ButtonNode>().length;
            final hasSelect = components.any((c) => c is SelectMenuNode);

            List<ComponentV2Type>? allowedTypes;
            if (hasSelect) {
              allowedTypes = []; // No more components allowed
            } else if (buttonCount > 0) {
              if (buttonCount < 5) {
                allowedTypes = [ComponentV2Type.button];
              } else {
                allowedTypes = []; // Max buttons reached
              }
            } else {
              // Empty or other? (Discord V1 Action Row should only have these)
              allowedTypes = [
                ComponentV2Type.button,
                ComponentV2Type.stringSelect,
                ComponentV2Type.userSelect,
                ComponentV2Type.roleSelect,
                ComponentV2Type.mentionableSelect,
                ComponentV2Type.channelSelect,
              ];
            }

            if (allowedTypes.isEmpty) return const SizedBox.shrink();

            return _buildAddComponentDropdown(context, (newNode) {
              row.components = [...row.components, newNode];
              onChanged(row);
            }, allowedTypes: allowedTypes);
          },
        ),
      ],
    );
  }

  Widget _buildButtonEditor(ButtonNode btn, BuildContext context) {
    return Column(
      children: [
        _buildResponsiveTwoFieldRow(
          first: VariableTextField(
            label: context.tr.component_label,
            initialValue: btn.label,
            suggestions: variableSuggestions,
            onChanged: (v) {
              btn.label = v;
              onChanged(btn);
            },
          ),
          second: DropdownButtonFormField<BcButtonStyle>(
            initialValue: btn.style,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr.common_style,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items:
                BcButtonStyle.values
                    .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                    .toList(),
            onChanged: (v) {
              if (v != null) {
                btn.style = v;
                onChanged(btn);
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        if (btn.style == BcButtonStyle.link)
          TextFormField(
            initialValue: btn.url,
            decoration: InputDecoration(
              labelText: context.tr.common_url,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              btn.url = v;
              onChanged(btn);
            },
          )
        else
          Column(
            children: [
              TextFormField(
                initialValue: btn.customId,
                decoration: InputDecoration(
                  labelText: context.tr.common_custom_id_required,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? context.tr.component_validation_required
                            : null,
                onChanged: (v) {
                  btn.customId = v;
                  onChanged(btn);
                },
              ),
              const SizedBox(height: 8),
              _WorkflowSelectorField(
                botIdForConfig: botIdForConfig,
                label: context.tr.component_workflow_optional,
                fallbackHint: context.tr.component_workflow_click_hint,
                selectedWorkflow: btn.workflowName,
                entryPoint: btn.workflowEntryPoint,
                workflowArguments: btn.workflowArguments,
                variableSuggestions: variableSuggestions,
                successMessage: context.tr.component_on_click_workflow,
                onChanged: (value) {
                  btn.workflowName = value ?? '';
                  onChanged(btn);
                },
                onEntryPointChanged: (value) {
                  btn.workflowEntryPoint = value ?? '';
                  onChanged(btn);
                },
                onArgumentsChanged: (value) {
                  btn.workflowArguments = Map<String, dynamic>.from(value);
                  onChanged(btn);
                },
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSelectMenuEditor(SelectMenuNode menu, BuildContext context) {
    return Column(
      children: [
        _buildResponsiveTwoFieldRow(
          first: TextFormField(
            initialValue: menu.customId,
            decoration: InputDecoration(
              labelText: context.tr.common_custom_id,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              menu.customId = v;
              onChanged(menu);
            },
          ),
          second: TextFormField(
            initialValue: menu.placeholder,
            decoration: InputDecoration(
              labelText: context.tr.common_placeholder,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              menu.placeholder = v;
              onChanged(menu);
            },
          ),
        ),
        const SizedBox(height: 8),
        _WorkflowSelectorField(
          botIdForConfig: botIdForConfig,
          label: context.tr.component_workflow_optional,
          fallbackHint: context.tr.component_workflow_select_hint,
          selectedWorkflow: menu.workflowName,
          entryPoint: menu.workflowEntryPoint,
          workflowArguments: menu.workflowArguments,
          variableSuggestions: variableSuggestions,
          successMessage: context.tr.component_on_select_workflow,
          onChanged: (value) {
            menu.workflowName = value ?? '';
            onChanged(menu);
          },
          onEntryPointChanged: (value) {
            menu.workflowEntryPoint = value ?? '';
            onChanged(menu);
          },
          onArgumentsChanged: (value) {
            menu.workflowArguments = Map<String, dynamic>.from(value);
            onChanged(menu);
          },
        ),
        if (menu.type == ComponentV2Type.stringSelect) ...[
          const SizedBox(height: 8),
          Text(
            context.tr.component_options,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          ...menu.options.asMap().entries.map((e) {
            final idx = e.key;
            final opt = e.value;
            return Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 540;
                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          initialValue: opt.label,
                          decoration: InputDecoration(
                            labelText: context.tr.common_label,
                            isDense: true,
                          ),
                          onChanged: (v) {
                            opt.value = v;
                            onChanged(menu);
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              size: 16,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              menu.options.removeAt(idx);
                              onChanged(menu);
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: opt.label,
                          decoration: InputDecoration(
                            labelText: context.tr.common_label,
                            isDense: true,
                          ),
                          onChanged: (v) {
                            opt.label = v;
                            onChanged(menu);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          initialValue: opt.value,
                          decoration: InputDecoration(
                            labelText: context.tr.common_value,
                            isDense: true,
                          ),
                          onChanged: (v) {
                            opt.value = v;
                            onChanged(menu);
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove_circle,
                          size: 16,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          menu.options.removeAt(idx);
                          onChanged(menu);
                        },
                      ),
                    ],
                  );
                },
              ),
            );
          }),
          TextButton.icon(
            onPressed: () {
              menu.options.add(
                SelectMenuOption(
                  label: context.tr.component_new_option,
                  value: 'value',
                ),
              );
              onChanged(menu);
            },
            icon: const Icon(Icons.add, size: 14),
            label: Text(
              context.tr.common_add_option,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextDisplayEditor(TextDisplayNode node, BuildContext context) {
    return VariableTextField(
      label: context.tr.component_markdown_content,
      initialValue: node.content,
      maxLines: 3,
      suggestions: variableSuggestions,
      onChanged: (v) {
        node.content = v;
        onChanged(node);
      },
    );
  }

  Widget _buildSeparatorEditor(SeparatorNode node, BuildContext context) {
    return Row(
      children: [
        Switch(
          value: node.isDivider,
          onChanged: (v) {
            node.isDivider = v;
            onChanged(node);
          },
        ),
        Text(context.tr.component_visible_divider),
        const Spacer(),
        DropdownButton<int>(
          value: node.spacing,
          items: [
            DropdownMenuItem(
              value: 1,
              child: Text(context.tr.component_spacing_small),
            ),
            DropdownMenuItem(
              value: 2,
              child: Text(context.tr.component_spacing_large),
            ),
          ],
          onChanged: (v) {
            if (v != null) {
              node.spacing = v;
              onChanged(node);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSectionEditor(SectionNode node, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr.component_section_text_displays,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        ...node.components.asMap().entries.map((e) {
          final idx = e.key;
          final child = e.value;
          return ComponentNodeEditor(
            node: child,
            depth: depth + 1,
            onChanged: (updated) {
              final newChildren = List<TextDisplayNode>.from(node.components);
              newChildren[idx] = updated as TextDisplayNode;
              node.components = newChildren;
              onChanged(node);
            },
            onRemove: () {
              final newChildren = List<TextDisplayNode>.from(node.components)
                ..removeAt(idx);
              node.components = newChildren;
              onChanged(node);
            },
            onMoveUp:
                idx == 0
                    ? null
                    : () {
                      final list = List<TextDisplayNode>.from(node.components);
                      final tmp = list[idx - 1];
                      list[idx - 1] = list[idx];
                      list[idx] = tmp;
                      node.components = list;
                      onChanged(node);
                    },
            onMoveDown:
                idx == node.components.length - 1
                    ? null
                    : () {
                      final list = List<TextDisplayNode>.from(node.components);
                      final tmp = list[idx + 1];
                      list[idx + 1] = list[idx];
                      list[idx] = tmp;
                      node.components = list;
                      onChanged(node);
                    },
            variableSuggestions: variableSuggestions,
            botIdForConfig: botIdForConfig,
          );
        }),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {
            node.components = [...node.components, TextDisplayNode()];
            onChanged(node);
          },
          icon: const Icon(Icons.add, size: 14),
          label: Text(
            context.tr.component_add_text_display,
            style: TextStyle(fontSize: 12),
          ),
        ),
        const Divider(),
        Text(
          context.tr.component_section_accessory,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        if (node.accessory != null)
          ComponentNodeEditor(
            node: node.accessory!,
            depth: depth + 1,
            onChanged: (updated) {
              node.accessory = updated;
              onChanged(node);
            },
            onRemove: () {
              node.accessory = null;
              onChanged(node);
            },
            variableSuggestions: variableSuggestions,
            botIdForConfig: botIdForConfig,
          )
        else
          _buildAddComponentDropdown(context, (newNode) {
            node.accessory = newNode;
            onChanged(node);
          }, allowedTypes: [ComponentV2Type.button, ComponentV2Type.thumbnail]),
      ],
    );
  }

  Widget _buildContainerEditor(ContainerNode node, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                key: ValueKey('container_color_\${node.accentColor}'),
                initialValue: node.accentColor,
                decoration: InputDecoration(
                  labelText: context.tr.component_accent_color,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) {
                  node.accentColor = v;
                  onChanged(node);
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.color_lens, color: Colors.blueAccent),
              tooltip: context.tr.component_choose_color,
              onPressed: () {
                Color currentColor = Colors.blueGrey;
                if (node.accentColor.isNotEmpty) {
                  try {
                    final hex = node.accentColor.replaceAll('#', '');
                    if (hex.length == 6) {
                      currentColor = Color(int.parse('0xFF$hex'));
                    }
                  } catch (_) {}
                }
                showDialog(
                  context: context,
                  builder:
                      (ctx) => AlertDialog(
                        title: Text(context.tr.component_pick_accent_color),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: currentColor,
                            enableAlpha: false,
                            hexInputBar: true,
                            onColorChanged: (c) {
                              currentColor = c;
                            },
                          ),
                        ),
                        actions: [
                          TextButton(
                            child: Text(context.tr.common_cancel),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                          TextButton(
                            child: Text(context.tr.common_ok),
                            onPressed: () {
                              node.accentColor =
                                  currentColor
                                      .toARGB32()
                                      .toRadixString(16)
                                      .substring(
                                        2,
                                      ) // remove trailing alpha usually if length 8
                                      .toUpperCase();
                              onChanged(node);
                              Navigator.of(ctx).pop();
                            },
                          ),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...node.components.asMap().entries.map((e) {
          final idx = e.key;
          final child = e.value;
          return ComponentNodeEditor(
            node: child,
            depth: depth + 1,
            onChanged: (updated) {
              final newChildren = List<ComponentNode>.from(node.components);
              newChildren[idx] = updated;
              node.components = newChildren;
              onChanged(node);
            },
            onRemove: () {
              final newChildren = List<ComponentNode>.from(node.components)
                ..removeAt(idx);
              node.components = newChildren;
              onChanged(node);
            },
            onMoveUp:
                idx == 0
                    ? null
                    : () {
                      final list = List<ComponentNode>.from(node.components);
                      final tmp = list[idx - 1];
                      list[idx - 1] = list[idx];
                      list[idx] = tmp;
                      node.components = list;
                      onChanged(node);
                    },
            onMoveDown:
                idx == node.components.length - 1
                    ? null
                    : () {
                      final list = List<ComponentNode>.from(node.components);
                      final tmp = list[idx + 1];
                      list[idx + 1] = list[idx];
                      list[idx] = tmp;
                      node.components = list;
                      onChanged(node);
                    },
            variableSuggestions: variableSuggestions,
            botIdForConfig: botIdForConfig,
          );
        }),
        const SizedBox(height: 8),
        _buildAddComponentDropdown(
          context,
          (newNode) {
            node.components = [...node.components, newNode];
            onChanged(node);
          },
          allowedTypes: [
            ComponentV2Type.actionRow,
            ComponentV2Type.textDisplay,
            ComponentV2Type.section,
            ComponentV2Type.mediaGallery,
            ComponentV2Type.separator,
            ComponentV2Type.file,
          ],
        ),
      ],
    );
  }

  Widget _buildLabelEditor(LabelNode node, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        VariableTextField(
          label: context.tr.component_label_title,
          initialValue: node.label,
          suggestions: variableSuggestions,
          onChanged: (v) {
            node.label = v;
            onChanged(node);
          },
        ),
        const SizedBox(height: 8),
        VariableTextField(
          label: context.tr.common_description,
          initialValue: node.description,
          suggestions: variableSuggestions,
          onChanged: (v) {
            node.description = v;
            onChanged(node);
          },
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.component_component_to_wrap,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        if (node.component != null)
          ComponentNodeEditor(
            node: node.component!,
            depth: depth + 1,
            onChanged: (updated) {
              node.component = updated;
              onChanged(node);
            },
            onRemove: () {
              node.component = null;
              onChanged(node);
            },
            variableSuggestions: variableSuggestions,
            botIdForConfig: botIdForConfig,
          )
        else
          _buildAddComponentDropdown(
            context,
            (newNode) {
              node.component = newNode;
              onChanged(node);
            },
            allowedTypes: [
              ComponentV2Type.stringSelect,
              ComponentV2Type.userSelect,
              ComponentV2Type.roleSelect,
              ComponentV2Type.mentionableSelect,
              ComponentV2Type.channelSelect,
              ComponentV2Type.fileUpload,
              ComponentV2Type.radioGroup,
              ComponentV2Type.checkboxGroup,
              ComponentV2Type.checkbox,
            ],
          ),
      ],
    );
  }

  Widget _buildCheckboxEditor(CheckboxNode node, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            initialValue: node.customId,
            decoration: InputDecoration(
              labelText: context.tr.common_custom_id,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              node.customId = v;
              onChanged(node);
            },
          ),
        ),
        Switch(
          value: node.isDefault,
          onChanged: (v) {
            node.isDefault = v;
            onChanged(node);
          },
        ),
        Text(context.tr.component_checked_by_default),
      ],
    );
  }

  Widget _buildRadioGroupEditor(RadioGroupNode node, BuildContext context) {
    return Column(
      children: [
        TextFormField(
          initialValue: node.customId,
          decoration: InputDecoration(
            labelText: context.tr.common_custom_id,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) {
            node.customId = v;
            onChanged(node);
          },
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.component_radio_options,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        ...node.options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: opt.label,
                    decoration: InputDecoration(
                      labelText: context.tr.common_label,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      opt.label = v;
                      onChanged(node);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: opt.value,
                    decoration: InputDecoration(
                      labelText: context.tr.common_value,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      opt.value = v;
                      onChanged(node);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    node.options.removeAt(idx);
                    onChanged(node);
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            node.options.add(
              RadioGroupOptionNode(
                label: context.tr.component_new_radio,
                value: 'value',
              ),
            );
            onChanged(node);
          },
          icon: const Icon(Icons.add, size: 14),
          label: Text(
            context.tr.component_add_radio_option,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckboxGroupEditor(
    CheckboxGroupNode node,
    BuildContext context,
  ) {
    return Column(
      children: [
        TextFormField(
          initialValue: node.customId,
          decoration: InputDecoration(
            labelText: context.tr.common_custom_id,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (v) {
            node.customId = v;
            onChanged(node);
          },
        ),
        const SizedBox(height: 8),
        Text(
          context.tr.component_checkbox_options,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        ...node.options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: opt.label,
                    decoration: InputDecoration(
                      labelText: context.tr.common_label,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      opt.value = v;
                      onChanged(node);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    node.options.removeAt(idx);
                    onChanged(node);
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            node.options.add(
              CheckboxGroupOptionNode(
                label: context.tr.component_new_checkbox,
                value: 'value',
              ),
            );
            onChanged(node);
          },
          icon: const Icon(Icons.add, size: 14),
          label: Text(
            context.tr.component_add_checkbox_option,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildFileUploadEditor(FileUploadNode node, BuildContext context) {
    return TextFormField(
      initialValue: node.customId,
      decoration: InputDecoration(
        labelText: context.tr.common_custom_id,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) {
        node.customId = v;
        onChanged(node);
      },
    );
  }

  Widget _buildFileEditor(FileNode node, BuildContext context) {
    return TextFormField(
      initialValue: node.file.url,
      decoration: InputDecoration(
        labelText: context.tr.component_file_url,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) {
        node.file.url = v;
        onChanged(node);
      },
    );
  }

  Widget _buildThumbnailEditor(ThumbnailNode node, BuildContext context) {
    return TextFormField(
      initialValue: node.media.url,
      decoration: InputDecoration(
        labelText: context.tr.component_thumbnail_url,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (v) {
        node.media.url = v;
        onChanged(node);
      },
    );
  }

  Widget _buildMediaGalleryEditor(MediaGalleryNode node, BuildContext context) {
    return Column(
      children: [
        Text(
          context.tr.component_media_urls,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        ...node.items.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          return Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: opt.media.url,
                    decoration: InputDecoration(
                      labelText: context.tr.component_media_url,
                      isDense: true,
                    ),
                    onChanged: (v) {
                      opt.media.url = v;
                      onChanged(node);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    node.items.removeAt(idx);
                    onChanged(node);
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
          onPressed: () {
            node.items.add(MediaGalleryItemNode());
            onChanged(node);
          },
          icon: const Icon(Icons.add, size: 14),
          label: Text(
            context.tr.component_add_media_item,
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // --- Utility Component Adder ---

  Widget _buildAddComponentDropdown(
    BuildContext context,
    ValueChanged<ComponentNode> onAdd, {
    List<ComponentV2Type>? allowedTypes,
  }) {
    final types = allowedTypes ?? ComponentV2Type.values;

    return Row(
      children: [
        Expanded(
          child: PopupMenuButton<ComponentV2Type>(
            tooltip: context.tr.component_add_child,
            onSelected: (v) => onAdd(ComponentNodeFactory.create(v)),
            itemBuilder: (BuildContext context) {
              return types
                  .map(
                    (t) => PopupMenuItem(
                      value: t,
                      child: Text(_getTitleForType(t)),
                    ),
                  )
                  .toList();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueGrey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: Colors.blueGrey),
                  SizedBox(width: 8),
                  Text(
                    'Add Child Component',
                    style: TextStyle(
                      color: Colors.blueGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WorkflowSelectorField extends StatefulWidget {
  final String? botIdForConfig;
  final String label;
  final String fallbackHint;
  final String? selectedWorkflow;
  final String entryPoint;
  final Map<String, dynamic> workflowArguments;
  final List<VariableSuggestion> variableSuggestions;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String?> onEntryPointChanged;
  final ValueChanged<Map<String, dynamic>> onArgumentsChanged;
  final String successMessage;

  const _WorkflowSelectorField({
    required this.botIdForConfig,
    required this.label,
    required this.fallbackHint,
    required this.selectedWorkflow,
    required this.entryPoint,
    required this.workflowArguments,
    required this.variableSuggestions,
    required this.onChanged,
    required this.onEntryPointChanged,
    required this.onArgumentsChanged,
    required this.successMessage,
  });

  @override
  State<_WorkflowSelectorField> createState() => _WorkflowSelectorFieldState();
}

class _WorkflowSelectorFieldState extends State<_WorkflowSelectorField> {
  late String _selectedWorkflow;
  late TextEditingController _entryPointCtrl;
  late Map<String, dynamic> _workflowArguments;
  List<String> _availableWorkflowNames = const [];
  bool _loadingWorkflows = false;

  @override
  void initState() {
    super.initState();
    _selectedWorkflow = (widget.selectedWorkflow ?? '').trim();
    _entryPointCtrl = TextEditingController(text: widget.entryPoint.trim());
    _workflowArguments = Map<String, dynamic>.from(widget.workflowArguments);
    _loadAvailableWorkflows();
  }

  @override
  void didUpdateWidget(covariant _WorkflowSelectorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSelected = (widget.selectedWorkflow ?? '').trim();
    if (nextSelected != _selectedWorkflow) {
      _selectedWorkflow = nextSelected;
    }
    final nextEntryPoint = widget.entryPoint.trim();
    if (_entryPointCtrl.text != nextEntryPoint) {
      _entryPointCtrl.text = nextEntryPoint;
    }
    _workflowArguments = Map<String, dynamic>.from(widget.workflowArguments);
    if (widget.botIdForConfig != oldWidget.botIdForConfig) {
      _loadAvailableWorkflows();
    }
  }

  @override
  void dispose() {
    _entryPointCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableWorkflows() async {
    final botId = widget.botIdForConfig;
    if (botId == null || botId.trim().isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _availableWorkflowNames = const [];
        _loadingWorkflows = false;
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loadingWorkflows = true;
      });
    }

    final workflows = await appManager.getWorkflows(botId);
    if (!mounted) {
      return;
    }

    final names = workflows
      .map((workflow) => (workflow['name'] ?? '').toString().trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false)..sort();

    setState(() {
      _availableWorkflowNames = names;
      _loadingWorkflows = false;
    });
  }

  Future<void> _editWorkflowArguments() async {
    final jsonController = TextEditingController(
      text:
          _workflowArguments.isEmpty
              ? '{}'
              : const JsonEncoder.withIndent('  ').convert(_workflowArguments),
    );
    String? error;

    await showDialog<void>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(context.tr.component_workflow_args_title),
                content: SizedBox(
                  width: 520,
                  child: TextField(
                    controller: jsonController,
                    minLines: 8,
                    maxLines: 16,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      errorText: error,
                      helperText: context.tr.component_workflow_args_hint,
                    ),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(context.tr.common_cancel),
                  ),
                  FilledButton(
                    onPressed: () {
                      final raw = jsonController.text.trim();
                      if (raw.isEmpty) {
                        setState(() {
                          _workflowArguments = <String, dynamic>{};
                        });
                        widget.onArgumentsChanged(_workflowArguments);
                        Navigator.pop(dialogContext);
                        return;
                      }

                      try {
                        final parsed = jsonDecode(raw);
                        if (parsed is! Map) {
                          setDialogState(() {
                            error = context.tr.workflow_root_json_error;
                          });
                          return;
                        }

                        setState(() {
                          _workflowArguments = Map<String, dynamic>.from(
                            parsed.map(
                              (key, value) => MapEntry(key.toString(), value),
                            ),
                          );
                        });
                        widget.onArgumentsChanged(_workflowArguments);
                        Navigator.pop(dialogContext);
                      } catch (e) {
                        setDialogState(() {
                          error = e.toString();
                        });
                      }
                    },
                    child: Text(context.tr.common_save),
                  ),
                ],
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final botId = widget.botIdForConfig?.trim();
    final hasBotContext = botId != null && botId.isNotEmpty;

    final selectedInList =
        _selectedWorkflow.isNotEmpty &&
                _availableWorkflowNames.contains(_selectedWorkflow)
            ? _selectedWorkflow
            : null;

    final workflowNameInput =
        hasBotContext
            ? Column(
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final selector = DropdownButtonFormField<String>(
                      key: ValueKey(
                        'workflow_${widget.label}_${selectedInList}_${_availableWorkflowNames.length}',
                      ),
                      initialValue: selectedInList,
                      isExpanded: true,
                      items:
                          _availableWorkflowNames
                              .map(
                                (name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(name),
                                ),
                              )
                              .toList(),
                      onChanged:
                          _loadingWorkflows
                              ? null
                              : (value) {
                                final next = (value ?? '').trim();
                                setState(() {
                                  _selectedWorkflow = next;
                                });
                                widget.onChanged(next.isEmpty ? null : next);
                              },
                      decoration: InputDecoration(
                        labelText: widget.label,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText:
                            _loadingWorkflows
                                ? context.tr.autocomplete_loading
                                : (_availableWorkflowNames.isEmpty
                                    ? context.tr.autocomplete_no_workflows
                                    : context.tr.autocomplete_select_workflow),
                      ),
                    );

                    final refreshButton = IconButton(
                      tooltip: context.tr.common_refresh_workflows,
                      onPressed:
                          _loadingWorkflows ? null : _loadAvailableWorkflows,
                      icon: const Icon(Icons.refresh),
                    );

                    if (constraints.maxWidth < 440) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          selector,
                          Align(
                            alignment: Alignment.centerRight,
                            child: refreshButton,
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: selector),
                        const SizedBox(width: 8),
                        refreshButton,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: ValueKey(
                    'workflow_manual_${widget.label}_$_selectedWorkflow',
                  ),
                  initialValue: _selectedWorkflow,
                  decoration: InputDecoration(
                    labelText: context.tr.autocomplete_type_name,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    final next = value.trim();
                    setState(() {
                      _selectedWorkflow = next;
                    });
                    widget.onChanged(next.isEmpty ? null : next);
                  },
                ),
              ],
            )
            : VariableTextField(
              label: widget.label,
              initialValue: _selectedWorkflow,
              hint: widget.fallbackHint,
              suggestions: widget.variableSuggestions,
              onChanged: (value) {
                final nextValue = value.trim();
                setState(() {
                  _selectedWorkflow = nextValue;
                });
                widget.onChanged(nextValue.isEmpty ? null : nextValue);
              },
            );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        workflowNameInput,
        if (hasBotContext) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed:
                _loadingWorkflows
                    ? null
                    : () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkflowsPage(botId: botId),
                        ),
                      );
                      await _loadAvailableWorkflows();
                    },
            icon: const Icon(Icons.account_tree),
            label: Text(context.tr.common_manage_workflows),
          ),
        ],
        if (_selectedWorkflow.isNotEmpty) ...[
          const SizedBox(height: 8),
          TextFormField(
            controller: _entryPointCtrl,
            decoration: InputDecoration(
              labelText: context.tr.workflow_entry_point_optional,
              border: const OutlineInputBorder(),
              isDense: true,
              helperText: context.tr.workflow_entry_point_helper,
            ),
            onChanged: (value) => widget.onEntryPointChanged(value.trim()),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _editWorkflowArguments,
            icon: const Icon(Icons.data_object),
            label: Text(
              _workflowArguments.isEmpty
                  ? context.tr.workflow_set_call_args
                  : context.tr.workflow_edit_call_args(
                    _workflowArguments.length,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.successMessage} "$_selectedWorkflow" will be executed (entry: ${_entryPointCtrl.text.trim().isEmpty ? 'default' : _entryPointCtrl.text.trim()}, args: ${_workflowArguments.length}).',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
