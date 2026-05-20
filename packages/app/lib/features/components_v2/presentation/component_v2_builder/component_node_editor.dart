import 'package:flutter/material.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'dart:convert';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_factory.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/mini_block_container.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// Depth-based accent colours for nesting levels (0 = root).
const _kDepthColors = [
  AppTheme.grey,
  AppTheme.info,
  AppTheme.success,
  AppTheme.warning,
  AppTheme.brandPrimary,
];

Color _depthColor(int depth) =>
    _kDepthColors[depth.clamp(0, _kDepthColors.length - 1)];

class ComponentNodeEditor extends StatefulWidget {
  final ComponentNode node;
  final ValueChanged<ComponentNode> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
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

  @override
  State<ComponentNodeEditor> createState() => _ComponentNodeEditorState();
}

class _ComponentNodeEditorState extends State<ComponentNodeEditor> {
  final Set<String> _forcedSections = {};

  // Property getters to minimise changes in method bodies.
  ComponentNode get node => widget.node;
  ValueChanged<ComponentNode> get onChanged => widget.onChanged;
  VoidCallback get onRemove => widget.onRemove;
  VoidCallback? get onMoveUp => widget.onMoveUp;
  VoidCallback? get onMoveDown => widget.onMoveDown;
  int get depth => widget.depth;
  List<VariableSuggestion> get variableSuggestions =>
      widget.variableSuggestions;
  String? get botIdForConfig => widget.botIdForConfig;

  @override
  void didUpdateWidget(ComponentNodeEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.type != oldWidget.node.type) {
      _forcedSections.clear();
    }
  }

  bool _isSectionVisible(String section, bool hasContent) =>
      hasContent || _forcedSections.contains(section);

  void _showSection(String section) {
    setState(() => _forcedSections.add(section));
  }

  void _hideSection(String section, VoidCallback clearData) {
    setState(() => _forcedSections.remove(section));
    clearData();
  }

  // ---------------------------------------------------------------------------
  // Confirm + remove
  // ---------------------------------------------------------------------------

  Future<void> _confirmAndRemove(BuildContext context) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.component_remove_title,
      content: context.tr.component_remove_confirm,
      confirmLabel: context.tr.common_remove,
      isDestructive: true,
    );
    if (!shouldDelete) return;
    onRemove();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
            padding: const EdgeInsets.all(AppTheme.spacingSm),
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusXs,
                            ),
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
                          color: AppTheme.errorLight,
                        ),
                        tooltip: context.tr.common_remove,
                        onPressed: () => _confirmAndRemove(context),
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

  // ---------------------------------------------------------------------------
  // Type helpers
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Body dispatcher
  // ---------------------------------------------------------------------------

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
    if (node is LabelNode) {
      return _buildLabelEditor(node as LabelNode, context);
    }
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

  // ---------------------------------------------------------------------------
  // Responsive helper
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // ActionRow editor (unchanged structure)
  // ---------------------------------------------------------------------------

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

            List<ComponentV2Type> allowedTypes;
            if (hasSelect) {
              allowedTypes = [];
            } else if (buttonCount > 0) {
              allowedTypes = buttonCount < 5 ? [ComponentV2Type.button] : [];
            } else {
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

  // ---------------------------------------------------------------------------
  // Button editor — MINI-BLOCKS
  // ---------------------------------------------------------------------------

  Widget _buildButtonEditor(ButtonNode btn, BuildContext context) {
    final hasWorkflow = btn.workflowName.trim().isNotEmpty;
    final hasEmoji = btn.emoji.trim().isNotEmpty;
    final availableSections = <(String, IconData, String)>[
      if (!_isSectionVisible('btn_workflow', hasWorkflow))
        (
          'btn_workflow',
          Icons.account_tree,
          context.tr.component_block_workflow,
        ),
      if (!_isSectionVisible('btn_emoji', hasEmoji))
        ('btn_emoji', Icons.emoji_emotions, context.tr.emojis_tab_short),
      if (!_isSectionVisible('btn_disabled', btn.disabled))
        ('btn_disabled', Icons.block, context.tr.common_disabled),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label & Style (essential)
        MiniBlockContainer(
          icon: Icons.smart_button,
          label: context.tr.component_block_label_style,
          child: _buildResponsiveTwoFieldRow(
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
                      .map(
                        (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                      )
                      .toList(),
              onChanged: (v) {
                if (v != null) {
                  btn.style = v;
                  onChanged(btn);
                }
              },
            ),
          ),
        ),
        // Custom ID or URL (essential, context-dependent)
        if (btn.style == BcButtonStyle.link)
          MiniBlockContainer(
            icon: Icons.link,
            label: context.tr.embed_label_url,
            child: TextFormField(
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
            ),
          )
        else
          MiniBlockContainer(
            icon: Icons.fingerprint,
            label: context.tr.common_custom_id_required,
            child: TextFormField(
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
          ),
        // Emoji (optional)
        if (_isSectionVisible('btn_emoji', hasEmoji))
          MiniBlockContainer(
            icon: Icons.emoji_emotions,
            label: context.tr.emojis_tab_short,
            onRemove:
                () => _hideSection('btn_emoji', () {
                  btn.emoji = '';
                  onChanged(btn);
                }),
            child: VariableTextField(
              label: context.tr.emojis_tab_short,
              initialValue: btn.emoji,
              suggestions: variableSuggestions,
              onChanged: (v) {
                btn.emoji = v;
                onChanged(btn);
              },
            ),
          ),
        // Disabled (optional)
        if (_isSectionVisible('btn_disabled', btn.disabled))
          MiniBlockContainer(
            icon: Icons.block,
            label: context.tr.common_disabled,
            onRemove:
                () => _hideSection('btn_disabled', () {
                  btn.disabled = false;
                  onChanged(btn);
                }),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.tr.common_disabled),
              value: btn.disabled,
              onChanged: (v) {
                btn.disabled = v;
                onChanged(btn);
              },
            ),
          ),
        // Workflow (optional)
        if (_isSectionVisible('btn_workflow', hasWorkflow))
          MiniBlockContainer(
            icon: Icons.account_tree,
            label: context.tr.component_block_workflow,
            onRemove:
                () => _hideSection('btn_workflow', () {
                  btn.workflowName = '';
                  btn.workflowEntryPoint = '';
                  btn.workflowArguments = {};
                  onChanged(btn);
                }),
            child: _WorkflowSelectorField(
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
          ),
        if (availableSections.isNotEmpty)
          AddSectionMenu(
            sections: availableSections,
            onSelected: _showSection,
            buttonLabel: context.tr.common_add_section,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SelectMenu editor — MINI-BLOCKS
  // ---------------------------------------------------------------------------

  Widget _buildSelectMenuEditor(SelectMenuNode menu, BuildContext context) {
    final hasWorkflow = menu.workflowName.trim().isNotEmpty;
    final hasRange = menu.minValues != 1 || menu.maxValues != 1;
    final availableSections = <(String, IconData, String)>[
      if (!_isSectionVisible('sel_workflow', hasWorkflow))
        (
          'sel_workflow',
          Icons.account_tree,
          context.tr.component_block_workflow,
        ),
      if (!_isSectionVisible('sel_range', hasRange))
        ('sel_range', Icons.sync_alt, context.tr.component_selection_range),
      if (!_isSectionVisible('sel_disabled', menu.disabled))
        ('sel_disabled', Icons.block, context.tr.common_disabled),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Identity (essential)
        MiniBlockContainer(
          icon: Icons.fingerprint,
          label: context.tr.common_custom_id,
          child: _buildResponsiveTwoFieldRow(
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
        ),
        // Workflow (optional)
        if (_isSectionVisible('sel_workflow', hasWorkflow))
          MiniBlockContainer(
            icon: Icons.account_tree,
            label: context.tr.component_block_workflow,
            onRemove:
                () => _hideSection('sel_workflow', () {
                  menu.workflowName = '';
                  menu.workflowEntryPoint = '';
                  menu.workflowArguments = {};
                  onChanged(menu);
                }),
            child: _WorkflowSelectorField(
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
          ),
        // Disabled (optional)
        if (_isSectionVisible('sel_disabled', menu.disabled))
          MiniBlockContainer(
            icon: Icons.block,
            label: context.tr.common_disabled,
            onRemove:
                () => _hideSection('sel_disabled', () {
                  menu.disabled = false;
                  onChanged(menu);
                }),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(context.tr.common_disabled),
              value: menu.disabled,
              onChanged: (v) {
                menu.disabled = v;
                onChanged(menu);
              },
            ),
          ),
        // Selection Range (optional)
        if (_isSectionVisible('sel_range', hasRange))
          MiniBlockContainer(
            icon: Icons.sync_alt,
            label: context.tr.component_selection_range,
            onRemove:
                () => _hideSection('sel_range', () {
                  menu.minValues = 1;
                  menu.maxValues = 1;
                  onChanged(menu);
                }),
            child: _buildResponsiveTwoFieldRow(
              first: TextFormField(
                initialValue: menu.minValues.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr.component_min_selections,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) {
                  menu.minValues = int.tryParse(v) ?? 1;
                  onChanged(menu);
                },
              ),
              second: TextFormField(
                initialValue: menu.maxValues.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr.component_max_selections,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) {
                  menu.maxValues = int.tryParse(v) ?? 1;
                  onChanged(menu);
                },
              ),
            ),
          ),
        // Options (essential for stringSelect)
        if (menu.type == ComponentV2Type.stringSelect)
          MiniBlockContainer(
            icon: Icons.list,
            label: context.tr.component_options,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...menu.options.asMap().entries.map((e) {
                  final idx = e.key;
                  final opt = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildResponsiveTwoFieldRow(
                                  first: TextFormField(
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
                                  second: TextFormField(
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
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  size: 16,
                                  color: AppTheme.error,
                                ),
                                onPressed: () {
                                  menu.options.removeAt(idx);
                                  onChanged(menu);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _buildResponsiveTwoFieldRow(
                            first: TextFormField(
                              initialValue: opt.description,
                              decoration: InputDecoration(
                                labelText: context.tr.common_description,
                                isDense: true,
                                hintText: 'Optional description (max 100)',
                              ),
                              onChanged: (v) {
                                opt.description = v;
                                onChanged(menu);
                              },
                            ),
                            second: TextFormField(
                              initialValue:
                                  opt.emoji is String
                                      ? opt.emoji as String
                                      : '',
                              decoration: InputDecoration(
                                labelText: context.tr.emojis_tab_short,
                                isDense: true,
                                hintText: 'Emoji ID or :name:',
                              ),
                              onChanged: (v) {
                                // Simplified: if it looks like JSON, we could parse it,
                                // but for now we store as string.
                                opt.emoji = v;
                                onChanged(menu);
                              },
                            ),
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(context.tr.common_default),
                            value: opt.isDefault,
                            onChanged: (v) {
                              // Only one can be default? Discord allows multiple for some types?
                              // Actually for String Select, it can be multiple if max_values > 1.
                              opt.isDefault = v;
                              onChanged(menu);
                            },
                          ),
                        ],
                      ),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        if (availableSections.isNotEmpty)
          AddSectionMenu(
            sections: availableSections,
            onSelected: _showSection,
            buttonLabel: context.tr.common_add_section,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TextDisplay editor (unchanged)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Separator editor (unchanged)
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Section editor — MINI-BLOCKS
  // ---------------------------------------------------------------------------

  Widget _buildSectionEditor(SectionNode node, BuildContext context) {
    final hasAccessory = node.accessory != null;
    final availableSections = <(String, IconData, String)>[
      if (!_isSectionVisible('sec_accessory', hasAccessory))
        (
          'sec_accessory',
          Icons.extension,
          context.tr.component_section_accessory,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Text Displays (essential)
        MiniBlockContainer(
          icon: Icons.text_fields,
          label: context.tr.component_section_text_displays,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...node.components.asMap().entries.map((e) {
                final idx = e.key;
                final child = e.value;
                return ComponentNodeEditor(
                  node: child,
                  depth: depth + 1,
                  onChanged: (updated) {
                    final newChildren = List<TextDisplayNode>.from(
                      node.components,
                    );
                    newChildren[idx] = updated as TextDisplayNode;
                    node.components = newChildren;
                    onChanged(node);
                  },
                  onRemove: () {
                    final newChildren = List<TextDisplayNode>.from(
                      node.components,
                    )..removeAt(idx);
                    node.components = newChildren;
                    onChanged(node);
                  },
                  onMoveUp:
                      idx == 0
                          ? null
                          : () {
                            final list = List<TextDisplayNode>.from(
                              node.components,
                            );
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
                            final list = List<TextDisplayNode>.from(
                              node.components,
                            );
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
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        // Accessory (optional)
        if (_isSectionVisible('sec_accessory', hasAccessory))
          MiniBlockContainer(
            icon: Icons.extension,
            label: context.tr.component_section_accessory,
            onRemove:
                () => _hideSection('sec_accessory', () {
                  node.accessory = null;
                  onChanged(node);
                }),
            child:
                node.accessory != null
                    ? ComponentNodeEditor(
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
                    : _buildAddComponentDropdown(
                      context,
                      (newNode) {
                        node.accessory = newNode;
                        onChanged(node);
                      },
                      allowedTypes: [
                        ComponentV2Type.button,
                        ComponentV2Type.thumbnail,
                      ],
                    ),
          ),
        if (availableSections.isNotEmpty)
          AddSectionMenu(
            sections: availableSections,
            onSelected: _showSection,
            buttonLabel: context.tr.common_add_section,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Container editor — MINI-BLOCKS
  // ---------------------------------------------------------------------------

  Widget _buildContainerEditor(ContainerNode node, BuildContext context) {
    final hasColor = node.accentColor.isNotEmpty;
    final availableSections = <(String, IconData, String)>[
      if (!_isSectionVisible('cnt_color', hasColor))
        ('cnt_color', Icons.palette, context.tr.component_accent_color),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Accent Color (optional)
        if (_isSectionVisible('cnt_color', hasColor))
          MiniBlockContainer(
            icon: Icons.palette,
            label: context.tr.component_accent_color,
            onRemove:
                () => _hideSection('cnt_color', () {
                  node.accentColor = '';
                  onChanged(node);
                }),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    key: ValueKey('container_color_${node.accentColor}'),
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
                  icon: const Icon(Icons.color_lens, color: AppTheme.info),
                  tooltip: context.tr.component_choose_color,
                  onPressed: () {
                    Color currentColor = AppTheme.grey;
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
                                onColorChanged: (c) => currentColor = c,
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
                                          .substring(2)
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
          ),
        // Children (always shown directly)
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
        if (availableSections.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: AddSectionMenu(
              sections: availableSections,
              onSelected: _showSection,
              buttonLabel: context.tr.common_add_section,
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Label editor — MINI-BLOCKS
  // ---------------------------------------------------------------------------

  Widget _buildLabelEditor(LabelNode node, BuildContext context) {
    final hasComponent = node.component != null;
    final availableSections = <(String, IconData, String)>[
      if (!_isSectionVisible('lbl_component', hasComponent))
        (
          'lbl_component',
          Icons.extension,
          context.tr.component_component_to_wrap,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Label & Description (essential)
        MiniBlockContainer(
          icon: Icons.label,
          label: context.tr.component_label_title,
          child: Column(
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
            ],
          ),
        ),
        // Wrapped component (optional)
        if (_isSectionVisible('lbl_component', hasComponent))
          MiniBlockContainer(
            icon: Icons.extension,
            label: context.tr.component_component_to_wrap,
            onRemove:
                () => _hideSection('lbl_component', () {
                  node.component = null;
                  onChanged(node);
                }),
            child:
                node.component != null
                    ? ComponentNodeEditor(
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
                    : _buildAddComponentDropdown(
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
          ),
        if (availableSections.isNotEmpty)
          AddSectionMenu(
            sections: availableSections,
            onSelected: _showSection,
            buttonLabel: context.tr.common_add_section,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Simple editors (unchanged)
  // ---------------------------------------------------------------------------

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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(context.tr.common_required),
          value: node.isRequired,
          onChanged: (v) {
            node.isRequired = v;
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
                  child: _buildResponsiveTwoFieldRow(
                    first: TextFormField(
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
                    second: TextFormField(
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
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: AppTheme.error,
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
            style: const TextStyle(fontSize: 12),
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
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(context.tr.common_required),
          value: node.isRequired,
          onChanged: (v) {
            node.isRequired = v;
            onChanged(node);
          },
        ),
        const SizedBox(height: 8),
        _buildResponsiveTwoFieldRow(
          first: TextFormField(
            initialValue: node.minValues.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr.component_min_selections,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              node.minValues = int.tryParse(v) ?? 1;
              onChanged(node);
            },
          ),
          second: TextFormField(
            initialValue: node.maxValues.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: context.tr.component_max_selections,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) {
              node.maxValues = int.tryParse(v) ?? 1;
              onChanged(node);
            },
          ),
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
                  child: _buildResponsiveTwoFieldRow(
                    first: TextFormField(
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
                    second: TextFormField(
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
                ),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle,
                    size: 16,
                    color: AppTheme.error,
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
                    color: AppTheme.error,
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
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Add component dropdown
  // ---------------------------------------------------------------------------

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
                border: Border.all(color: AppTheme.grey),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, size: 16, color: AppTheme.grey),
                  SizedBox(width: 8),
                  Text(
                    'Add Child Component',
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
  Map<String, List<WorkflowArgumentDefinition>> _workflowArgDefs = const {};
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

    final generalWorkflows =
        workflows
            .where(
              (workflow) =>
                  normalizeWorkflowType(workflow['workflowType']) ==
                  workflowTypeGeneral,
            )
            .toList();

    final names = generalWorkflows
      .map((workflow) => (workflow['name'] ?? '').toString().trim())
      .where((name) => name.isNotEmpty)
      .toList(growable: false)..sort();

    final argDefs = <String, List<WorkflowArgumentDefinition>>{};
    for (final workflow in generalWorkflows) {
      final name = (workflow['name'] ?? '').toString().trim();
      if (name.isNotEmpty) {
        argDefs[name] = parseWorkflowArgumentDefinitions(workflow['arguments']);
      }
    }

    setState(() {
      _availableWorkflowNames = names;
      _workflowArgDefs = argDefs;
      _loadingWorkflows = false;
    });
  }

  Future<void> _editWorkflowArguments() async {
    final workflowName = _selectedWorkflow.trim();
    final defs = _workflowArgDefs[workflowName] ?? const [];

    if (defs.isNotEmpty) {
      await _editWorkflowArgumentsForm(defs);
    } else {
      await _editWorkflowArgumentsJson();
    }
  }

  Future<void> _editWorkflowArgumentsForm(
    List<WorkflowArgumentDefinition> defs,
  ) async {
    final controllers = <String, TextEditingController>{};
    for (final def in defs) {
      controllers[def.name] = TextEditingController(
        text: (_workflowArguments[def.name] ?? '').toString(),
      );
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: AppTheme.dialogShape,
          icon: Icon(Icons.data_object, color: AppTheme.brandPrimary, size: 32),
          title: Text(
            context.tr.component_workflow_args_title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final def in defs) ...[
                    TextField(
                      controller: controllers[def.name],
                      decoration: InputDecoration(
                        labelText: def.name + (def.required ? ' *' : ''),
                        hintText: context.tr.component_value_hint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                        helperText:
                            def.defaultValue.isNotEmpty
                                ? '${context.tr.common_default}: ${def.defaultValue}'
                                : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.fromLTRB(
            AppTheme.spacingLg,
            0,
            AppTheme.spacingLg,
            AppTheme.spacingLg,
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(shape: AppTheme.buttonShape),
              child: Text(context.tr.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(shape: AppTheme.buttonShape),
              child: Text(context.tr.common_save),
            ),
          ],
        );
      },
    );

    // Read values and dispose controllers before setState to avoid
    // "used after being disposed" errors during the rebuild.
    final result = <String, dynamic>{};
    if (saved == true) {
      for (final def in defs) {
        final value = controllers[def.name]!.text.trim();
        if (value.isNotEmpty) {
          result[def.name] = value;
        }
      }
    }
    for (final ctrl in controllers.values) {
      ctrl.dispose();
    }
    if (saved == true) {
      setState(() {
        _workflowArguments = result;
      });
      widget.onArgumentsChanged(_workflowArguments);
    }
  }

  Future<void> _editWorkflowArgumentsJson() async {
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
                shape: AppTheme.dialogShape,
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
                actionsAlignment: MainAxisAlignment.center,
                actionsPadding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLg,
                  0,
                  AppTheme.spacingLg,
                  AppTheme.spacingLg,
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      shape: AppTheme.buttonShape,
                    ),
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
                    style: FilledButton.styleFrom(shape: AppTheme.buttonShape),
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
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            decoration: BoxDecoration(
              color: AppTheme.success,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: AppTheme.success),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.success,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.successMessage} "$_selectedWorkflow" will be executed (entry: ${_entryPointCtrl.text.trim().isEmpty ? 'default' : _entryPointCtrl.text.trim()}, args: ${_workflowArguments.length}).',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.success,
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
