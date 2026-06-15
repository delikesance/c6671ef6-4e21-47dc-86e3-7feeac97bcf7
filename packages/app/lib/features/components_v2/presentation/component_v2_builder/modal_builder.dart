import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator_shared/types/component.dart';
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart' show ActionsBuilderPage;
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_editor.dart';
import 'package:bot_creator/features/components_v2/presentation/component_v2_builder/component_node_factory.dart';

/// Widget for editing a full Modal definition (title, customId, text inputs, inline actions).
class ModalBuilderWidget extends StatefulWidget {
  final ModalDefinition modal;
  final ValueChanged<ModalDefinition> onChanged;
  final List<VariableSuggestion> variableSuggestions;
  final String? botIdForConfig;

  const ModalBuilderWidget({
    super.key,
    required this.modal,
    required this.onChanged,
    required this.variableSuggestions,
    this.botIdForConfig,
  });

  @override
  State<ModalBuilderWidget> createState() => _ModalBuilderWidgetState();
}

class _ModalBuilderWidgetState extends State<ModalBuilderWidget> {
  late TextEditingController _titleCtrl;
  late TextEditingController _customIdCtrl;
  late List<ModalTextInputDefinition> _inputs;
  late List<String> _inputKeys;
  late List<ComponentNode> _components;
  late List<String> _componentKeys;
  late List<Map<String, dynamic>> _modalActions;

  @override
  void initState() {
    super.initState();
    _initFromWidget();
  }

  @override
  void didUpdateWidget(ModalBuilderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.modal != oldWidget.modal) {
      if (_titleCtrl.text != widget.modal.title) {
        _titleCtrl.text = widget.modal.title;
      }
      if (_customIdCtrl.text != widget.modal.customId) {
        _customIdCtrl.text = widget.modal.customId;
      }
      // Only regenerate keys on structural changes (add/remove), not on
      // content changes.  The _InputEditor state owns its own controllers.
      final newInputs = widget.modal.inputs;
      if (_inputs.length != newInputs.length ||
          !_listEquals(
            _inputs.map((i) => i.toJson()).toList(),
            newInputs.map((i) => i.toJson()).toList(),
          )) {
        final structureChanged = _inputs.length != newInputs.length;
        _inputs = List.from(newInputs);
        if (structureChanged) {
          _inputKeys = List.generate(_inputs.length, (_) => UniqueKey().toString());
        }
      }
      final newComponents = widget.modal.components;
      if (_components.length != newComponents.length ||
          !_listEquals(
            _components.map((c) => c.toJson()).toList(),
            newComponents.map((c) => c.toJson()).toList(),
          )) {
        final structureChanged = _components.length != newComponents.length;
        _components = newComponents
            .map((c) => ComponentNode.fromJson(c.toJson()))
            .toList();
        if (structureChanged) {
          _componentKeys = List.generate(_components.length, (_) => UniqueKey().toString());
        }
      }
      if (!_listEquals(_modalActions, widget.modal.actions)) {
        _modalActions = List.from(widget.modal.actions);
      }
    }
  }

  bool _listEquals(List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (jsonEncode(a[i]) != jsonEncode(b[i])) return false;
    }
    return true;
  }

  void _initFromWidget() {
    _titleCtrl = TextEditingController(text: widget.modal.title);
    _customIdCtrl = TextEditingController(text: widget.modal.customId);
    _inputs = List.from(widget.modal.inputs);
    _inputKeys = List.generate(_inputs.length, (_) => UniqueKey().toString());
    _components = widget.modal.components
        .map((c) => ComponentNode.fromJson(c.toJson()))
        .toList();
    _componentKeys = List.generate(_components.length, (_) => UniqueKey().toString());
    _modalActions = List.from(widget.modal.actions);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customIdCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ModalDefinition(
        title: _titleCtrl.text,
        customId: _customIdCtrl.text,
        inputs: List.from(_inputs),
        components: List.from(_components),
        actions: List.from(_modalActions),
      ),
    );
  }

  void _addInput() {
    if (_inputs.length >= 5) return;
    setState(() {
      _inputs.add(
        ModalTextInputDefinition(
          label: context.tr.modal_field_default_label(_inputs.length + 1),
        ),
      );
      _inputKeys.add(UniqueKey().toString());
    });
    _emit();
  }

  Future<void> _removeInput(int index) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.modal_remove_field_title,
      content: context.tr.modal_remove_field_confirm,
      confirmLabel: context.tr.common_remove,
      isDestructive: true,
    );
    if (!shouldDelete) return;

    setState(() {
      _inputs.removeAt(index);
      _inputKeys.removeAt(index);
    });
    _emit();
  }

  void _updateInput(int index, ModalTextInputDefinition updated) {
    setState(() => _inputs[index] = updated);
    _emit();
  }

  void _updateComponent(int index, ComponentNode updated) {
    setState(() => _components[index] = updated);
    _emit();
  }

  Future<void> _removeComponent(int index) async {
    final shouldDelete = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.component_remove_title,
      content: context.tr.component_remove_confirm,
      confirmLabel: context.tr.common_remove,
      isDestructive: true,
    );
    if (!shouldDelete) return;

    setState(() {
      _components.removeAt(index);
      _componentKeys.removeAt(index);
    });
    _emit();
  }

  void _addV2Component(ComponentV2Type type) {
    if (_components.length >= 5) return;
    setState(() {
      // Auto-migrate legacy inputs if we are transitioning to components
      if (_components.isEmpty && _inputs.isNotEmpty) {
        _components = _inputs.map((input) {
          return LabelNode(
            label: input.label,
            component: ModalTextInputNode(
              customId: input.customId,
              style: input.style,
              label: input.label,
              placeholder: input.placeholder,
              value: input.defaultValue,
              required: input.required,
              minLength: input.minLength,
              maxLength: input.maxLength,
            ),
          );
        }).toList();
        _componentKeys = List.generate(_components.length, (_) => UniqueKey().toString());
        _inputs.clear();
        _inputKeys.clear();
      }

      final innerComponent = ComponentNodeFactory.create(type);
      final label = LabelNode(
        label: ComponentNodeFactory.labelFor(type),
        component: innerComponent,
      );
      _components.add(label);
      _componentKeys.add(UniqueKey().toString());
    });
    _emit();
  }

  IconData _getIconForType(ComponentV2Type type) {
    return switch (type) {
      ComponentV2Type.textInput => Icons.text_fields,
      ComponentV2Type.stringSelect => Icons.list,
      ComponentV2Type.userSelect => Icons.person,
      ComponentV2Type.roleSelect => Icons.admin_panel_settings,
      ComponentV2Type.mentionableSelect => Icons.alternate_email,
      ComponentV2Type.channelSelect => Icons.tag,
      ComponentV2Type.fileUpload => Icons.upload_file,
      ComponentV2Type.radioGroup => Icons.radio_button_checked,
      ComponentV2Type.checkboxGroup => Icons.check_box,
      ComponentV2Type.checkbox => Icons.check_box_outline_blank,
      _ => Icons.extension,
    };
  }

  String _getDisplayNameForType(ComponentV2Type type) {
    return switch (type) {
      ComponentV2Type.textInput => 'Text Input',
      ComponentV2Type.stringSelect => 'Dropdown Selection',
      ComponentV2Type.userSelect => 'User Selector',
      ComponentV2Type.roleSelect => 'Role Selector',
      ComponentV2Type.mentionableSelect => 'User/Role Selector',
      ComponentV2Type.channelSelect => 'Channel Selector',
      ComponentV2Type.fileUpload => 'File Upload',
      ComponentV2Type.radioGroup => 'Radio Buttons',
      ComponentV2Type.checkboxGroup => 'Checkbox Group',
      ComponentV2Type.checkbox => 'Single Checkbox',
      _ => ComponentNodeFactory.labelFor(type),
    };
  }

  Future<void> _editActions() async {
    // Merge modal input/component fields into variable suggestions so they appear
    // in autocomplete when configuring submit actions.
    final mergedSuggestions = List<VariableSuggestion>.from(
      widget.variableSuggestions,
    );
    for (final input in _inputs) {
      final name = 'modal.${input.customId}';
      if (widget.variableSuggestions.any((s) => s.name == name)) continue;
      mergedSuggestions.add(
        VariableSuggestion(
          name: name,
          kind: VariableSuggestionKind.nonNumeric,
          category: shared.VariableCategory.interaction,
        ),
      );
    }
    for (final component in _components) {
      if (component is LabelNode && component.component != null) {
        final inner = component.component!;
        String? customId;
        if (inner is ModalTextInputNode) {
          customId = inner.customId;
        } else if (inner is SelectMenuNode) {
          customId = inner.customId;
        } else if (inner is FileUploadNode) {
          customId = inner.customId;
        } else if (inner is RadioGroupNode) {
          customId = inner.customId;
        } else if (inner is CheckboxGroupNode) {
          customId = inner.customId;
        } else if (inner is CheckboxNode) {
          customId = inner.customId;
        }
        if (customId != null && customId.isNotEmpty) {
          final name = 'modal.$customId';
          if (mergedSuggestions.any((s) => s.name == name)) continue;
          mergedSuggestions.add(
            VariableSuggestion(
              name: name,
              kind: VariableSuggestionKind.nonNumeric,
              category: shared.VariableCategory.interaction,
            ),
          );
        }
      }
    }

    final result = await Navigator.push<List<Map<String, dynamic>>>(
      context,
      MaterialPageRoute(
        builder: (_) => ActionsBuilderPage(
          initialActions: List.from(_modalActions),
          variableSuggestions: mergedSuggestions,
          botIdForConfig: widget.botIdForConfig,
          editPath: ['Modal', widget.modal.customId],
          isWorkflow: true,
          isModalContext: true,
        ),
      ),
    );
    if (result != null) {
      setState(() => _modalActions = result);
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isV2 = _components.isNotEmpty;
    final count = isV2 ? _components.length : _inputs.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dynamic_form, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr.modal_builder_title,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.modal_inputs_count(count),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  const Icon(Icons.dynamic_form, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr.modal_builder_title,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    context.tr.modal_inputs_count(count),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.brandPrimary.withValues(alpha: 0.3)),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title & Custom ID ──
              _buildMiniBlock(
                icon: Icons.title,
                label: 'Identity',
                child: Column(children: [
                  _buildField(
                    label: 'Title',
                    initialValue: _titleCtrl.text,
                    onChanged: (v) {
                      _titleCtrl.text = v;
                      _emit();
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildField(
                    label: context.tr.common_custom_id,
                    initialValue: _customIdCtrl.text,
                    onChanged: (v) {
                      _customIdCtrl.text = v;
                      _emit();
                    },
                  ),
                ]),
              ),
              const SizedBox(height: 12),

              // ── Fields ──
              if (_components.isNotEmpty) ...[
                ..._components.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final component = entry.value;
                  return ComponentNodeEditor(
                    key: ValueKey(_componentKeys[idx]),
                    node: component,
                    depth: 0,
                    variableSuggestions: widget.variableSuggestions,
                    onChanged: (updated) => _updateComponent(idx, updated),
                    onRemove: () => _removeComponent(idx),
                    botIdForConfig: widget.botIdForConfig,
                    isModalContext: true,
                  );
                }),
              ] else ...[
                ..._inputs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final input = entry.value;
                  return _InputEditor(
                    key: ValueKey(_inputKeys[idx]),
                    input: input,
                    index: idx,
                    variableSuggestions: widget.variableSuggestions,
                    onChanged: (updated) => _updateInput(idx, updated),
                    onRemove: () => _removeInput(idx),
                  );
                }),
              ],

              if (count < 5)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      PopupMenuButton<ComponentV2Type>(
                        tooltip: 'Add Field',
                        onSelected: _addV2Component,
                        itemBuilder: (BuildContext context) {
                          final v2Types = [
                            ComponentV2Type.textInput,
                            ComponentV2Type.stringSelect,
                            ComponentV2Type.userSelect,
                            ComponentV2Type.roleSelect,
                            ComponentV2Type.mentionableSelect,
                            ComponentV2Type.channelSelect,
                            ComponentV2Type.fileUpload,
                            ComponentV2Type.radioGroup,
                            ComponentV2Type.checkboxGroup,
                            ComponentV2Type.checkbox,
                          ];
                          return v2Types.map((t) {
                            return PopupMenuItem(
                              value: t,
                              child: Row(
                                children: [
                                  Icon(_getIconForType(t), size: 16, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _getDisplayNameForType(t),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_circle_outline, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Add Field',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(height: 24),

              // ── Submit Actions ──
              _buildMiniBlock(
                icon: Icons.play_circle_outline,
                label: 'Submit Actions',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_modalActions.isNotEmpty) ...[
                      Text(
                        '${_modalActions.length} action(s) configured',
                        style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                    ],
                    FilledButton.icon(
                      onPressed: _editActions,
                      icon: const Icon(Icons.edit_note, size: 18),
                      label: Text(
                        _modalActions.isEmpty
                            ? 'Configure Submit Actions'
                            : 'Edit Submit Actions',
                      ),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniBlock({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingSm),
            child: Material(type: MaterialType.transparency, child: child),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: onChanged,
    );
  }
}

/// Individual text input editor within a modal.
///
/// Uses [StatefulWidget] with local [TextEditingController]s so the text
/// fields keep focus and cursor position across parent rebuilds.
class _InputEditor extends StatefulWidget {
  final ModalTextInputDefinition input;
  final int index;
  final List<VariableSuggestion> variableSuggestions;
  final ValueChanged<ModalTextInputDefinition> onChanged;
  final VoidCallback onRemove;

  const _InputEditor({
    super.key,
    required this.input,
    required this.index,
    required this.variableSuggestions,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<_InputEditor> createState() => _InputEditorState();
}

class _InputEditorState extends State<_InputEditor> {
  late TextEditingController _labelCtrl;
  late TextEditingController _customIdCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.input.label);
    _customIdCtrl = TextEditingController(text: widget.input.customId);
  }

  @override
  void didUpdateWidget(covariant _InputEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only sync controller text when the external value changes from
    // outside (e.g. another widget's action) — never when the user is typing.
    if (oldWidget.input.label != widget.input.label &&
        _labelCtrl.text != widget.input.label) {
      _labelCtrl.text = widget.input.label;
    }
    if (oldWidget.input.customId != widget.input.customId &&
        _customIdCtrl.text != widget.input.customId) {
      _customIdCtrl.text = widget.input.customId;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _customIdCtrl.dispose();
    super.dispose();
  }

  ModalTextInputDefinition _buildDefinition({
    String? label,
    String? customId,
    BcTextInputStyle? style,
    bool? required,
  }) {
    return ModalTextInputDefinition(
      customId: customId ?? _customIdCtrl.text,
      label: label ?? _labelCtrl.text,
      style: style ?? widget.input.style,
      placeholder: widget.input.placeholder,
      defaultValue: widget.input.defaultValue,
      required: required ?? widget.input.required,
      minLength: widget.input.minLength,
      maxLength: widget.input.maxLength,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.brandPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              ),
              child: Text('#${widget.index + 1}', style: TextStyle(fontSize: 11, color: AppTheme.brandPrimary)),
            ),
            const Spacer(),
            InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              onTap: widget.onRemove,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 16, color: Theme.of(context).colorScheme.error),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          VariableTextField(
            controller: _labelCtrl,
            label: context.tr.common_label,
            useLabelText: true,
            suggestions: widget.variableSuggestions,
            onChanged: (_) => widget.onChanged(_buildDefinition()),
          ),
          const SizedBox(height: 8),
          VariableTextField(
            controller: _customIdCtrl,
            label: context.tr.common_custom_id,
            useLabelText: true,
            suggestions: widget.variableSuggestions,
            onChanged: (_) => widget.onChanged(_buildDefinition()),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<BcTextInputStyle>(
                initialValue: widget.input.style,
                decoration: const InputDecoration(labelText: 'Style', border: OutlineInputBorder(), isDense: true),
                items: BcTextInputStyle.values.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (v) {
                  if (v != null) widget.onChanged(_buildDefinition(style: v));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(context.tr.common_required, style: const TextStyle(fontSize: 13)),
                value: widget.input.required,
                onChanged: (v) => widget.onChanged(_buildDefinition(required: v)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
