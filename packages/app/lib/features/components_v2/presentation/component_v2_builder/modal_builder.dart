import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/models/types/component.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflows.page.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// Widget for editing a full Modal definition (title, customId, text inputs).
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
  late TextEditingController _onWorkflowCtrl;
  late TextEditingController _onWorkflowEntryPointCtrl;
  late Map<String, dynamic> _onWorkflowArguments;
  late List<ModalTextInputDefinition> _inputs;
  List<String> _availableWorkflowNames = const [];

  /// Argument definitions per workflow name (loaded from saved workflows).
  Map<String, List<WorkflowArgumentDefinition>> _workflowArgDefs = const {};
  bool _loadingWorkflows = false;

  @override
  void initState() {
    super.initState();
    _initFromWidget();
    _loadAvailableWorkflows();
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
      if (_onWorkflowCtrl.text != (widget.modal.onSubmitWorkflow ?? '')) {
        _onWorkflowCtrl.text = widget.modal.onSubmitWorkflow ?? '';
      }
      if (_onWorkflowEntryPointCtrl.text != widget.modal.onSubmitEntryPoint) {
        _onWorkflowEntryPointCtrl.text = widget.modal.onSubmitEntryPoint;
      }
      _onWorkflowArguments = Map<String, dynamic>.from(
        widget.modal.onSubmitArguments,
      );
      _inputs = List.from(widget.modal.inputs);
    }
    if (widget.botIdForConfig != oldWidget.botIdForConfig) {
      _loadAvailableWorkflows();
    }
  }

  void _initFromWidget() {
    _titleCtrl = TextEditingController(text: widget.modal.title);
    _customIdCtrl = TextEditingController(text: widget.modal.customId);
    _onWorkflowCtrl = TextEditingController(
      text: widget.modal.onSubmitWorkflow ?? '',
    );
    _onWorkflowEntryPointCtrl = TextEditingController(
      text: widget.modal.onSubmitEntryPoint,
    );
    _onWorkflowArguments = Map<String, dynamic>.from(
      widget.modal.onSubmitArguments,
    );
    _inputs = List.from(widget.modal.inputs);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _customIdCtrl.dispose();
    _onWorkflowCtrl.dispose();
    _onWorkflowEntryPointCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ModalDefinition(
        title: _titleCtrl.text,
        customId: _customIdCtrl.text,
        inputs: List.from(_inputs),
        onSubmitWorkflow:
            _onWorkflowCtrl.text.trim().isEmpty
                ? null
                : _onWorkflowCtrl.text.trim(),
        onSubmitEntryPoint: _onWorkflowEntryPointCtrl.text.trim(),
        onSubmitArguments: Map<String, dynamic>.from(_onWorkflowArguments),
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
    if (!shouldDelete) {
      return;
    }

    setState(() => _inputs.removeAt(index));
    _emit();
  }

  void _updateInput(int index, ModalTextInputDefinition updated) {
    setState(() => _inputs[index] = updated);
    _emit();
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

  Future<void> _editOnSubmitArguments() async {
    final workflowName = _onWorkflowCtrl.text.trim();
    final defs = _workflowArgDefs[workflowName] ?? const [];

    // If the workflow has defined arguments, show a per-field form;
    // otherwise fall back to a raw JSON editor for manual/custom args.
    if (defs.isNotEmpty) {
      await _editOnSubmitArgumentsForm(defs);
    } else {
      await _editOnSubmitArgumentsJson();
    }
  }

  /// Per-field argument editor – one TextField per workflow argument definition.
  Future<void> _editOnSubmitArgumentsForm(
    List<WorkflowArgumentDefinition> defs,
  ) async {
    final controllers = <String, TextEditingController>{};
    for (final def in defs) {
      controllers[def.name] = TextEditingController(
        text: (_onWorkflowArguments[def.name] ?? '').toString(),
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
        _onWorkflowArguments = result;
      });
      _emit();
    }
  }

  /// Raw JSON fallback for workflows with no defined arguments.
  Future<void> _editOnSubmitArgumentsJson() async {
    final jsonController = TextEditingController(
      text:
          _onWorkflowArguments.isEmpty
              ? '{}'
              : const JsonEncoder.withIndent(
                '  ',
              ).convert(_onWorkflowArguments),
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
                          _onWorkflowArguments = <String, dynamic>{};
                        });
                        _emit();
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
                          _onWorkflowArguments = Map<String, dynamic>.from(
                            parsed.map(
                              (key, value) => MapEntry(key.toString(), value),
                            ),
                          );
                        });
                        _emit();
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
                        const Icon(
                          Icons.dynamic_form,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr.modal_builder_title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr.modal_inputs_count(_inputs.length),

                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    context.tr.modal_inputs_count(_inputs.length),
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
            border: Border.all(
              color: AppTheme.brandPrimary.withValues(alpha: 0.3),
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Mini-block: Title & Custom ID ──
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.title,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            context.tr.modal_title_label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final titleField = VariableTextField(
                            label: context.tr.modal_title_label,
                            initialValue: widget.modal.title,
                            suggestions: widget.variableSuggestions,
                            onChanged: (v) {
                              _titleCtrl.text = v;
                              _emit();
                            },
                          );
                          final customIdField = TextFormField(
                            controller: _customIdCtrl,
                            decoration: InputDecoration(
                              labelText: context.tr.common_custom_id,
                              border: const OutlineInputBorder(),
                              isDense: true,
                              helperText: context.tr.modal_custom_id_hint,
                            ),
                            onChanged: (_) => _emit(),
                          );

                          if (constraints.maxWidth < 560) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                titleField,
                                const SizedBox(height: 8),
                                customIdField,
                              ],
                            );
                          }

                          return Row(
                            children: [
                              Expanded(flex: 3, child: titleField),
                              const SizedBox(width: 8),
                              Expanded(flex: 2, child: customIdField),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // ── Mini-block: Workflow ──
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_tree,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr.modal_workflow_submit,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.botIdForConfig != null) ...[
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final workflowSelector = DropdownButtonFormField<
                                  String
                                >(
                                  initialValue:
                                      _onWorkflowCtrl.text.trim().isEmpty
                                          ? null
                                          : (_availableWorkflowNames.contains(
                                                _onWorkflowCtrl.text.trim(),
                                              )
                                              ? _onWorkflowCtrl.text.trim()
                                              : null),
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
                                            setState(() {
                                              _onWorkflowCtrl.text =
                                                  (value ?? '').trim();
                                            });
                                            _emit();
                                          },
                                  decoration: InputDecoration(
                                    labelText: context.tr.modal_workflow_submit,
                                    border: const OutlineInputBorder(),
                                    isDense: true,
                                    helperText:
                                        _loadingWorkflows
                                            ? context.tr.autocomplete_loading
                                            : (_availableWorkflowNames.isEmpty
                                                ? context
                                                    .tr
                                                    .autocomplete_no_workflows
                                                : context
                                                    .tr
                                                    .autocomplete_select_workflow),
                                  ),
                                );

                                final refreshButton = IconButton(
                                  tooltip: context.tr.common_refresh_workflows,
                                  onPressed:
                                      _loadingWorkflows
                                          ? null
                                          : _loadAvailableWorkflows,
                                  icon: const Icon(Icons.refresh),
                                );

                                if (constraints.maxWidth < 440) {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      workflowSelector,
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: refreshButton,
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: workflowSelector),
                                    const SizedBox(width: 8),
                                    refreshButton,
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              key: ValueKey(
                                'modal_manual_workflow_${widget.modal.customId}_${_onWorkflowCtrl.text.trim()}',
                              ),
                              initialValue: _onWorkflowCtrl.text.trim(),
                              decoration: InputDecoration(
                                labelText: context.tr.autocomplete_type_name,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                _onWorkflowCtrl.text = value.trim();
                                _emit();
                              },
                            ),
                          ] else ...[
                            VariableTextField(
                              label: context.tr.modal_workflow_submit,
                              initialValue: widget.modal.onSubmitWorkflow ?? '',
                              hint: context.tr.workflow_hint_name,
                              suggestions: widget.variableSuggestions,
                              onChanged: (v) {
                                _onWorkflowCtrl.text = v;
                                _emit();
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                onPressed:
                                    widget.botIdForConfig == null
                                        ? null
                                        : () async {
                                          final botId = widget.botIdForConfig;
                                          if (botId == null) {
                                            return;
                                          }
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => WorkflowsPage(
                                                    botId: botId,
                                                  ),
                                            ),
                                          );
                                          await _loadAvailableWorkflows();
                                        },
                                icon: const Icon(Icons.account_tree),
                                label: Text(context.tr.common_manage_workflows),
                              ),
                            ],
                          ),
                          if (_onWorkflowCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _onWorkflowEntryPointCtrl,
                              decoration: InputDecoration(
                                labelText:
                                    context.tr.workflow_entry_point_optional,
                                border: const OutlineInputBorder(),
                                isDense: true,
                                helperText:
                                    context.tr.workflow_entry_point_helper,
                              ),
                              onChanged: (_) => _emit(),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _editOnSubmitArguments,
                              icon: const Icon(Icons.data_object),
                              label: Text(
                                _onWorkflowArguments.isEmpty
                                    ? context.tr.workflow_set_call_args
                                    : context.tr.workflow_edit_call_args(
                                      _onWorkflowArguments.length,
                                    ),
                              ),
                            ),
                          ],
                          if (_onWorkflowCtrl.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusSm,
                                ),
                                border: Border.all(
                                  color: AppTheme.success.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
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
                                      context.tr.workflow_on_submit_info(
                                        _onWorkflowCtrl.text.trim(),
                                        _onWorkflowEntryPointCtrl.text
                                                .trim()
                                                .isEmpty
                                            ? 'default'
                                            : _onWorkflowEntryPointCtrl.text
                                                .trim(),
                                        _onWorkflowArguments.length,
                                      ),
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
                          ] else ...[
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                context.tr.workflow_no_workflow_note,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Inputs list
              ..._inputs.asMap().entries.map((entry) {
                final index = entry.key;
                final input = entry.value;
                return _ModalTextInputTile(
                  key: ValueKey(
                    input.customId,
                  ), // Critical for preserving state
                  index: index,
                  input: input,
                  onChanged: (updated) => _updateInput(index, updated),
                  onRemove: () => _removeInput(index),
                  variableSuggestions: widget.variableSuggestions,
                );
              }),
              // Add input button
              if (_inputs.length < 5)
                TextButton.icon(
                  onPressed: _addInput,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(context.tr.modal_add_text_input),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModalTextInputTile extends StatefulWidget {
  final int index;
  final ModalTextInputDefinition input;
  final ValueChanged<ModalTextInputDefinition> onChanged;
  final VoidCallback onRemove;
  final List<VariableSuggestion> variableSuggestions;

  const _ModalTextInputTile({
    super.key,
    required this.index,
    required this.input,
    required this.onChanged,
    required this.onRemove,
    required this.variableSuggestions,
  });

  @override
  State<_ModalTextInputTile> createState() => _ModalTextInputTileState();
}

class _ModalTextInputTileState extends State<_ModalTextInputTile> {
  late TextEditingController _customIdCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _placeholderCtrl;
  late TextEditingController _defaultValCtrl;

  @override
  void initState() {
    super.initState();
    _customIdCtrl = TextEditingController(text: widget.input.customId);
    _labelCtrl = TextEditingController(text: widget.input.label);
    _placeholderCtrl = TextEditingController(text: widget.input.placeholder);
    _defaultValCtrl = TextEditingController(text: widget.input.defaultValue);
  }

  @override
  void didUpdateWidget(_ModalTextInputTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.input.customId != oldWidget.input.customId &&
        _customIdCtrl.text != widget.input.customId) {
      _customIdCtrl.text = widget.input.customId;
    }
    if (widget.input.label != oldWidget.input.label &&
        _labelCtrl.text != widget.input.label) {
      _labelCtrl.text = widget.input.label;
    }
    if (widget.input.placeholder != oldWidget.input.placeholder &&
        _placeholderCtrl.text != widget.input.placeholder) {
      _placeholderCtrl.text = widget.input.placeholder;
    }
    if (widget.input.defaultValue != oldWidget.input.defaultValue &&
        _defaultValCtrl.text != widget.input.defaultValue) {
      _defaultValCtrl.text = widget.input.defaultValue;
    }
  }

  @override
  void dispose() {
    _customIdCtrl.dispose();
    _labelCtrl.dispose();
    _placeholderCtrl.dispose();
    _defaultValCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      ModalTextInputDefinition(
        customId: _customIdCtrl.text,
        label: _labelCtrl.text,
        style: widget.input.style,
        placeholder: _placeholderCtrl.text,
        defaultValue: _defaultValCtrl.text,
        required: widget.input.required,
        minLength: widget.input.minLength,
        maxLength: widget.input.maxLength,
      ),
    );
  }

  Widget _buildResponsiveTwoFieldRow({
    required Widget first,
    required Widget second,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [first, const SizedBox(height: 8), second],
          );
        }

        return Row(
          children: [
            Expanded(child: first),
            const SizedBox(width: 8),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Mini-block header (same style as embed mini-blocks) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.input.label.isEmpty
                        ? context.tr.modal_input_index(widget.index + 1)
                        : widget.input.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                  ),
                  child: Text(
                    widget.input.style.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.brandSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  onTap: widget.onRemove,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 16, color: AppTheme.grey),
                  ),
                ),
              ],
            ),
          ),
          // ── Content ──
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildResponsiveTwoFieldRow(
                  first: TextFormField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr.common_label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _emit(),
                  ),
                  second: TextFormField(
                    controller: _customIdCtrl,
                    decoration: InputDecoration(
                      labelText: context.tr.common_custom_id,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => _emit(),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _placeholderCtrl,
                  decoration: InputDecoration(
                    labelText: context.tr.common_placeholder,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => _emit(),
                ),
                const SizedBox(height: 8),
                VariableTextField(
                  label: context.tr.modal_default_value,
                  initialValue: widget.input.defaultValue,
                  suggestions: widget.variableSuggestions,
                  onChanged: (v) {
                    _defaultValCtrl.text = v;
                    _emit();
                  },
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stylePicker = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr.modal_style,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children:
                              BcTextInputStyle.values.map((style) {
                                return FilterChip(
                                  label: Text(
                                    style.name,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  selected: widget.input.style == style,
                                  onSelected: (_) {
                                    widget.onChanged(
                                      ModalTextInputDefinition(
                                        customId: _customIdCtrl.text,
                                        label: _labelCtrl.text,
                                        style: style,
                                        placeholder: _placeholderCtrl.text,
                                        defaultValue: _defaultValCtrl.text,
                                        required: widget.input.required,
                                        minLength: widget.input.minLength,
                                        maxLength: widget.input.maxLength,
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                        ),
                      ],
                    );

                    final requiredToggle = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr.common_required,
                          style: const TextStyle(fontSize: 12),
                        ),
                        Switch(
                          value: widget.input.required,
                          onChanged: (v) {
                            widget.onChanged(
                              ModalTextInputDefinition(
                                customId: _customIdCtrl.text,
                                label: _labelCtrl.text,
                                style: widget.input.style,
                                placeholder: _placeholderCtrl.text,
                                defaultValue: _defaultValCtrl.text,
                                required: v,
                                minLength: widget.input.minLength,
                                maxLength: widget.input.maxLength,
                              ),
                            );
                          },
                        ),
                      ],
                    );

                    if (constraints.maxWidth < 560) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          stylePicker,
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: requiredToggle,
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: stylePicker),
                        const SizedBox(width: 8),
                        requiredToggle,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
