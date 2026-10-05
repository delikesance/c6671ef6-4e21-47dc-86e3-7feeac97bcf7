import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:nyxx/nyxx.dart' hide Builder;
import 'package:bot_creator/main.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';

import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/widgets/variable_text_field.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/js_editor/js_editor_snippets.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_command_rules.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_command_validation_messages.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/js_editor_page.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class OptionWidget extends StatefulWidget {
  final Function(List<CommandOptionBuilder>) onChange;
  final List<CommandOptionBuilder>? initialOptions;
  final String? botIdForConfig;
  final List<VariableSuggestion> variableSuggestions;
  final bool isPrefixCommand;

  const OptionWidget({
    super.key,
    required this.onChange,
    this.initialOptions,
    this.botIdForConfig,
    this.variableSuggestions = const <VariableSuggestion>[],
    this.isPrefixCommand = false,
  });

  @override
  OptionWidgetState createState() => OptionWidgetState();
}

class OptionWidgetState extends State<OptionWidget> {
  static const List<CommandOptionType> _leafOptionTypes = <CommandOptionType>[
    CommandOptionType.string,
    CommandOptionType.integer,
    CommandOptionType.boolean,
    CommandOptionType.user,
    CommandOptionType.channel,
    CommandOptionType.role,
    CommandOptionType.mentionable,
    CommandOptionType.number,
    CommandOptionType.attachment,
  ];

  static const List<CommandOptionType> _hierarchyOptionTypes =
      <CommandOptionType>[
        CommandOptionType.subCommand,
        CommandOptionType.subCommandGroup,
      ];

  final List<CommandOptionBuilder> options = <CommandOptionBuilder>[];
  List<String> _availableWorkflowNames = const [];
  bool _loadingWorkflows = false;
  bool _isJavascriptBot = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialOptions != null) {
      options.addAll(widget.initialOptions!);
      for (final option in options) {
        _normalizeForType(option);
      }
    }
    _loadAvailableWorkflows();
    _loadRuntimeEngine();
  }

  @override
  void didUpdateWidget(OptionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.botIdForConfig != oldWidget.botIdForConfig) {
      _loadAvailableWorkflows();
      _loadRuntimeEngine();
    }
  }

  Future<void> _loadRuntimeEngine() async {
    final botId = widget.botIdForConfig;
    if (botId == null || botId.trim().isEmpty) {
      if (mounted) {
        setState(() => _isJavascriptBot = false);
      }
      return;
    }

    final engine = await getBotRuntimeEngine(botId);
    if (!mounted) {
      return;
    }
    setState(() => _isJavascriptBot = isJavascriptRuntimeEngine(engine));
  }

  Future<void> _loadAvailableWorkflows() async {
    final botId = widget.botIdForConfig;
    if (botId == null || botId.trim().isEmpty) {
      if (mounted) {
        setState(() {
          _availableWorkflowNames = const [];
          _loadingWorkflows = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _loadingWorkflows = true);
    try {
      final workflows = await appManager.getWorkflows(botId);
      if (!mounted) return;
      final names =
          workflows
              .where(
                (w) =>
                    normalizeWorkflowType(w['workflowType']) ==
                    workflowTypeGeneral,
              )
              .map((w) => (w['name'] ?? '').toString().trim())
              .where((n) => n.isNotEmpty)
              .toList(growable: false)
            ..sort();
      setState(() {
        _availableWorkflowNames = names;
        _loadingWorkflows = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingWorkflows = false);
    }
  }

  bool _isHierarchyType(CommandOptionType type) {
    return _hierarchyOptionTypes.contains(type);
  }

  bool _isNumericType(CommandOptionType type) {
    return type == CommandOptionType.integer ||
        type == CommandOptionType.number;
  }

  bool _supportsChoices(CommandOptionType type) {
    return type == CommandOptionType.string ||
        type == CommandOptionType.integer ||
        type == CommandOptionType.number;
  }

  bool _supportsAutocomplete(CommandOptionType type) {
    return commandOptionSupportsAutocomplete(type);
  }

  String _typeLabel(CommandOptionType type) {
    switch (type) {
      case CommandOptionType.string:
        return context.tr.option_type_string;
      case CommandOptionType.integer:
        return context.tr.option_type_integer;
      case CommandOptionType.boolean:
        return context.tr.option_type_boolean;
      case CommandOptionType.user:
        return context.tr.option_type_user;
      case CommandOptionType.channel:
        return context.tr.option_type_channel;
      case CommandOptionType.role:
        return context.tr.option_type_role;
      case CommandOptionType.mentionable:
        return context.tr.option_type_mentionable;
      case CommandOptionType.number:
        return context.tr.option_type_number;
      case CommandOptionType.attachment:
        return context.tr.option_type_attachment;
      case CommandOptionType.subCommand:
        return context.tr.option_type_subcommand;
      case CommandOptionType.subCommandGroup:
        return context.tr.option_type_subcommand_group;
    }
    return context.tr.option_type_unknown;
  }

  List<CommandOptionType> _allowedTypesForLevel({
    required CommandOptionType? parentType,
    required List<CommandOptionBuilder> siblings,
  }) {
    if (parentType == CommandOptionType.subCommandGroup) {
      return const <CommandOptionType>[CommandOptionType.subCommand];
    }

    if (parentType == CommandOptionType.subCommand) {
      return _leafOptionTypes;
    }

    final hasHierarchy = siblings.any((entry) => _isHierarchyType(entry.type));
    final hasLeaf = siblings.any((entry) => !_isHierarchyType(entry.type));

    if (hasHierarchy && !hasLeaf) {
      return _hierarchyOptionTypes;
    }

    if (hasLeaf && !hasHierarchy) {
      return _leafOptionTypes;
    }

    return <CommandOptionType>[..._leafOptionTypes, ..._hierarchyOptionTypes];
  }

  CommandOptionBuilder _buildDefaultOption(
    List<CommandOptionBuilder> target, {
    required CommandOptionType? parentType,
  }) {
    final allowedTypes = _allowedTypesForLevel(
      parentType: parentType,
      siblings: target,
    );
    final type = allowedTypes.first;
    final option = CommandOptionBuilder(
      name: 'option${target.length + 1}',
      description: context.tr.option_description_new(target.length + 1),
      type: type,
      isRequired: false,
    );
    _normalizeForType(option);
    return option;
  }

  void _normalizeForType(CommandOptionBuilder option) {
    final type = option.type;

    if (_isHierarchyType(type)) {
      option.isRequired = false;
      option.choices = null;
      option.minValue = null;
      option.maxValue = null;
      option.hasAutocomplete = null;
      setCommandOptionAutocompleteConfig(option, null);
      option.options ??= <CommandOptionBuilder>[];

      if (type == CommandOptionType.subCommand) {
        option.options = (option.options ?? <CommandOptionBuilder>[])
            .where((entry) => !_isHierarchyType(entry.type))
            .toList(growable: true);
      }

      if (type == CommandOptionType.subCommandGroup) {
        option.options = (option.options ?? <CommandOptionBuilder>[])
            .where((entry) => entry.type == CommandOptionType.subCommand)
            .toList(growable: true);
      }
      return;
    }

    option.options = null;

    if (!_supportsChoices(type)) {
      option.choices = null;
    }

    if (!_supportsAutocomplete(type)) {
      option.hasAutocomplete = null;
      setCommandOptionAutocompleteConfig(option, null);
    }

    if (option.hasAutocomplete == true) {
      option.choices = null;
    }

    if (!_isNumericType(type)) {
      option.minValue = null;
      option.maxValue = null;
    }
  }

  void _updateWidget() {
    widget.onChange(options);
  }

  String? _nameValidator(
    String? value,
    List<CommandOptionBuilder> levelOptions,
    CommandOptionBuilder current,
  ) {
    if (value == null || value.isEmpty) {
      return context.tr.option_name_required;
    }

    if (widget.isPrefixCommand) {
      if (value.length > discordCommandNameMaxLength) {
        return context.tr.option_name_max_length;
      }
    } else {
      final issue = validateChatInputOptionName(value);
      final message = discordCommandValidationMessage(
        context,
        issue,
        maxLength: discordCommandNameMaxLength,
      );
      if (message != null) {
        return message;
      }
    }

    var duplicates = 0;
    for (final entry in levelOptions) {
      if (entry.name == value && !identical(entry, current)) {
        duplicates++;
      }
    }

    if (duplicates > 0) {
      return context.tr.option_name_duplicate;
    }

    return null;
  }

  TextInputType _choiceKeyboardType(CommandOptionType type) {
    if (_isNumericType(type)) {
      return TextInputType.number;
    }
    return TextInputType.text;
  }

  Widget _buildOptionsLevel(
    List<CommandOptionBuilder> levelOptions, {
    required CommandOptionType? parentType,
    required int depth,
  }) {
    return Column(
      children: <Widget>[
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: levelOptions.length,
          itemBuilder: (BuildContext context, int index) {
            final option = levelOptions[index];
            final allowedTypes = _allowedTypesForLevel(
              parentType: parentType,
              siblings: levelOptions
                  .where((o) => o != option)
                  .toList(growable: false),
            );

            if (!allowedTypes.contains(option.type)) {
              option.type = allowedTypes.first;
              _normalizeForType(option);
            }

            return _tile(
              radius: 18,
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  option.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                trailing: IconButton(
                  icon: const AppIcon.fromMaterial(
                    Icons.delete,
                    color: AppTheme.statusErrorText,
                  ),
                  onPressed: () async {
                    final shouldDelete = await AppTheme.showConfirmDialog(
                      context,
                      title: context.tr.option_delete_title,
                      content: context.tr.option_delete_confirm,
                      confirmLabel: context.tr.common_delete,
                      isDestructive: true,
                    );
                    if (!shouldDelete) {
                      return;
                    }

                    setState(() {
                      levelOptions.removeAt(index);
                      _updateWidget();
                    });
                  },
                ),
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(
                      left: depth > 0 ? 12 : 0,
                      right: 8,
                      bottom: 8,
                    ),
                    child: Column(
                      children: <Widget>[
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: widget.isPrefixCommand
                                ? context.tr.common_name
                                : requiredFieldLabel(context.tr.common_name),
                            border: OutlineInputBorder(),
                          ),
                          initialValue: option.name,
                          maxLength: 32,
                          validator: (String? value) {
                            return _nameValidator(value, levelOptions, option);
                          },
                          onChanged: (String value) {
                            setState(() {
                              option.name = value;
                              _updateWidget();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: widget.isPrefixCommand
                                ? context.tr.common_description
                                : requiredFieldLabel(
                                    context.tr.common_description,
                                  ),
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 100,
                          maxLines: 2,
                          minLines: 1,
                          initialValue: option.description,
                          validator: (String? value) {
                            if (widget.isPrefixCommand) {
                              if (value != null && value.length > 100) {
                                return context.tr.command_description_length;
                              }
                              return null;
                            }
                            if (value == null || value.isEmpty) {
                              return context.tr.option_desc_required;
                            }
                            return null;
                          },
                          onChanged: (String value) {
                            setState(() {
                              option.description = value;
                              _updateWidget();
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        _tile(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Row(
                              children: <Widget>[
                                Text(context.tr.common_type),
                                const Spacer(),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<CommandOptionType>(
                                    value: option.type,
                                    onChanged: (CommandOptionType? newValue) {
                                      if (newValue == null) {
                                        return;
                                      }
                                      setState(() {
                                        option.type = newValue;
                                        _normalizeForType(option);
                                        _updateWidget();
                                      });
                                    },
                                    items: allowedTypes
                                        .map(
                                          (CommandOptionType type) =>
                                              DropdownMenuItem<
                                                CommandOptionType
                                              >(
                                                value: type,
                                                child: Text(_typeLabel(type)),
                                              ),
                                        )
                                        .toList(growable: false),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!_isHierarchyType(option.type))
                          _tile(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
                              child: Row(
                                children: [
                                  Text(context.tr.common_required),
                                  const Spacer(),
                                  Switch(
                                    value: option.isRequired ?? false,
                                    onChanged: (bool value) {
                                      setState(() {
                                        option.isRequired = value;
                                        _updateWidget();
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!_isHierarchyType(option.type) &&
                            _supportsAutocomplete(option.type))
                          _tile(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: CheckboxListTile(
                              title: Text(context.tr.autocomplete_dynamic),
                              subtitle: Text(
                                context.tr.autocomplete_dynamic_desc,
                              ),
                              value: isCommandOptionAutocompleteEnabled(option),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    setCommandOptionAutocompleteConfig(option, {
                                      'enabled': true,
                                      'mode': _isJavascriptBot
                                          ? 'javascript'
                                          : 'inline',
                                      if (_isJavascriptBot)
                                        'jsScript': defaultJsAutocompleteScript,
                                      'staticChoices': <Map<String, dynamic>>[],
                                    });
                                  } else {
                                    setCommandOptionAutocompleteConfig(
                                      option,
                                      null,
                                    );
                                  }
                                  _normalizeForType(option);
                                  _updateWidget();
                                });
                              },
                            ),
                          ),
                        if (isCommandOptionAutocompleteEnabled(
                          option,
                        )) ...<Widget>[
                          Builder(
                            builder: (context) {
                              final cfg =
                                  getCommandOptionAutocompleteConfig(option) ??
                                  <String, dynamic>{
                                    'enabled': true,
                                    'mode': 'inline',
                                    'staticChoices': <Map<String, dynamic>>[],
                                  };
                              final currentMode = () {
                                final raw = (cfg['mode'] ?? '')
                                    .toString()
                                    .trim()
                                    .toLowerCase();
                                if (raw == 'static') {
                                  return 'static';
                                }
                                if (raw == 'javascript') {
                                  return 'javascript';
                                }
                                if (raw == 'workflow' && !_isJavascriptBot) {
                                  return 'workflow';
                                }
                                return _isJavascriptBot
                                    ? 'javascript'
                                    : 'inline';
                              }();

                              Map<String, dynamic> updatedCfg([
                                Map<String, dynamic>? overrides,
                              ]) {
                                final base = Map<String, dynamic>.from(cfg);
                                if (overrides != null) base.addAll(overrides);
                                return base;
                              }

                              void saveConfig(Map<String, dynamic> newCfg) {
                                setState(() {
                                  setCommandOptionAutocompleteConfig(
                                    option,
                                    newCfg,
                                  );
                                  _updateWidget();
                                });
                              }

                              // ── Mode selector ──────────────────────────────
                              final modeSelector = SegmentedButton<String>(
                                segments: [
                                  if (_isJavascriptBot)
                                    const ButtonSegment(
                                      value: 'javascript',
                                      label: Text('JavaScript'),
                                      icon: AppIcon.fromMaterial(
                                        Icons.javascript,
                                      ),
                                    )
                                  else
                                    ButtonSegment(
                                      value: 'inline',
                                      label: Text(context.tr.common_inline),
                                      icon: const AppIcon.fromMaterial(
                                        Icons.code,
                                      ),
                                    ),
                                  ButtonSegment(
                                    value: 'static',
                                    label: Text(
                                      context.tr.common_static_options,
                                    ),
                                    icon: const AppIcon.fromMaterial(
                                      Icons.list_alt_outlined,
                                    ),
                                  ),
                                ],
                                selected: {currentMode},
                                onSelectionChanged: (Set<String> selection) {
                                  final nextMode = selection.first;
                                  saveConfig(
                                    updatedCfg({
                                      'mode': nextMode,
                                      if (nextMode == 'javascript' &&
                                          (cfg['jsScript'] ?? '')
                                              .toString()
                                              .trim()
                                              .isEmpty)
                                        'jsScript': defaultJsAutocompleteScript,
                                    }),
                                  );
                                },
                              );

                              // ── Workflow panel ─────────────────────────────
                              Widget workflowPanel() {
                                final currentWorkflow = (cfg['workflow'] ?? '')
                                    .toString()
                                    .trim();
                                final dropdownValue =
                                    _availableWorkflowNames.contains(
                                      currentWorkflow,
                                    )
                                    ? currentWorkflow
                                    : null;
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            initialValue: dropdownValue,
                                            isExpanded: true,
                                            items: _availableWorkflowNames
                                                .map(
                                                  (name) =>
                                                      DropdownMenuItem<String>(
                                                        value: name,
                                                        child: Text(name),
                                                      ),
                                                )
                                                .toList(),
                                            onChanged: _loadingWorkflows
                                                ? null
                                                : (value) => saveConfig(
                                                    updatedCfg({
                                                      'workflow': value ?? '',
                                                    }),
                                                  ),
                                            decoration: InputDecoration(
                                              labelText: context
                                                  .tr
                                                  .autocomplete_workflow_label,
                                              border:
                                                  const OutlineInputBorder(),
                                              helperText: _loadingWorkflows
                                                  ? context
                                                        .tr
                                                        .autocomplete_loading
                                                  : (_availableWorkflowNames
                                                            .isEmpty
                                                        ? context
                                                              .tr
                                                              .autocomplete_no_workflows
                                                        : context
                                                              .tr
                                                              .autocomplete_select_workflow),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: context
                                              .tr
                                              .common_refresh_workflows,
                                          onPressed: _loadingWorkflows
                                              ? null
                                              : _loadAvailableWorkflows,
                                          icon: const AppIcon.fromMaterial(
                                            Icons.refresh,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      key: ValueKey(
                                        'ac_workflow_manual_$currentWorkflow',
                                      ),
                                      initialValue: currentWorkflow,
                                      decoration: InputDecoration(
                                        labelText:
                                            context.tr.autocomplete_type_name,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      onChanged: (v) => saveConfig(
                                        updatedCfg({'workflow': v}),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      key: ValueKey('ac_ep_${cfg['workflow']}'),
                                      decoration: InputDecoration(
                                        labelText:
                                            context.tr.workflow_entry_point,
                                        border: const OutlineInputBorder(),
                                      ),
                                      initialValue:
                                          (cfg['entryPoint'] ?? 'main')
                                              .toString(),
                                      onChanged: (v) => saveConfig(
                                        updatedCfg({
                                          'entryPoint': v.trim().isEmpty
                                              ? 'main'
                                              : v,
                                        }),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Builder(
                                      builder: (context) {
                                        final args = Map<String, dynamic>.from(
                                          cfg['arguments'] is Map
                                              ? (cfg['arguments'] as Map).map(
                                                  (k, v) =>
                                                      MapEntry(k.toString(), v),
                                                )
                                              : const {},
                                        );
                                        final entries = args.entries.toList();

                                        void saveArgs(
                                          Map<String, dynamic> newArgs,
                                        ) {
                                          saveConfig(
                                            updatedCfg({'arguments': newArgs}),
                                          );
                                        }

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            if (entries.isNotEmpty)
                                              Text(
                                                context
                                                    .tr
                                                    .workflow_arguments_section,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            if (entries.isNotEmpty)
                                              const SizedBox(height: 4),
                                            ...List.generate(entries.length, (
                                              i,
                                            ) {
                                              final k = entries[i].key;
                                              final v =
                                                  entries[i].value
                                                      ?.toString() ??
                                                  '';
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: _responsiveRow(
                                                  first: TextFormField(
                                                    key: ValueKey(
                                                      'arg_k_${option.name}_$i',
                                                    ),
                                                    initialValue: k,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          context.tr.common_key,
                                                      border:
                                                          OutlineInputBorder(),
                                                      isDense: true,
                                                    ),
                                                    onChanged: (newKey) {
                                                      final updated =
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(args);
                                                      updated.remove(k);
                                                      if (newKey
                                                          .trim()
                                                          .isNotEmpty) {
                                                        updated[newKey.trim()] =
                                                            v;
                                                      }
                                                      saveArgs(updated);
                                                    },
                                                  ),
                                                  second: VariableTextField(
                                                    key: ValueKey(
                                                      'arg_v_${option.name}_$i',
                                                    ),
                                                    label:
                                                        context.tr.common_value,
                                                    useLabelText: true,
                                                    initialValue: v,
                                                    suggestions: widget
                                                        .variableSuggestions,
                                                    hint: context
                                                        .tr
                                                        .hint_use_variables,
                                                    onChanged: (newVal) {
                                                      final updated =
                                                          Map<
                                                            String,
                                                            dynamic
                                                          >.from(args);
                                                      updated[k] = newVal;
                                                      saveArgs(updated);
                                                    },
                                                  ),
                                                  trailing: IconButton(
                                                    icon:
                                                        const AppIcon.fromMaterial(
                                                          Icons.delete_outline,
                                                        ),
                                                    tooltip: context
                                                        .tr
                                                        .common_remove,
                                                    onPressed: () async {
                                                      final shouldDelete =
                                                          await AppTheme.showConfirmDialog(
                                                            context,
                                                            title: context
                                                                .tr
                                                                .option_delete_argument_title,
                                                            content: context
                                                                .tr
                                                                .option_delete_argument_confirm,
                                                            confirmLabel: context
                                                                .tr
                                                                .common_delete,
                                                            isDestructive: true,
                                                          );
                                                      if (!shouldDelete) {
                                                        return;
                                                      }
                                                      final updated =
                                                          Map<
                                                              String,
                                                              dynamic
                                                            >.from(args)
                                                            ..remove(k);
                                                      saveArgs(updated);
                                                    },
                                                  ),
                                                ),
                                              );
                                            }),
                                            OutlinedButton.icon(
                                              onPressed: () {
                                                final updated =
                                                    Map<String, dynamic>.from(
                                                      args,
                                                    );
                                                var idx = entries.length;
                                                var newKey = 'arg$idx';
                                                while (updated.containsKey(
                                                  newKey,
                                                )) {
                                                  idx++;
                                                  newKey = 'arg$idx';
                                                }
                                                updated[newKey] = '';
                                                saveArgs(updated);
                                              },
                                              icon: const AppIcon.fromMaterial(
                                                Icons.add,
                                              ),
                                              label: Text(
                                                context.tr.common_add_argument,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                );
                              }

                              // ── Static options panel ───────────────────────
                              Widget staticPanel() {
                                final staticChoices = <Map<String, dynamic>>[];
                                if (cfg['staticChoices'] is List) {
                                  for (final raw
                                      in cfg['staticChoices'] as List) {
                                    if (raw is Map) {
                                      staticChoices.add(
                                        Map<String, dynamic>.from(
                                          raw.map(
                                            (k, v) => MapEntry(k.toString(), v),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }

                                void saveChoices(
                                  List<Map<String, dynamic>> choices,
                                ) {
                                  saveConfig(
                                    updatedCfg({'staticChoices': choices}),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      context.tr.autocomplete_filter_hint,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    ...List.generate(staticChoices.length, (i) {
                                      final choice = staticChoices[i];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: _responsiveRow(
                                          firstFlex: 3,
                                          secondFlex: 3,
                                          first: TextFormField(
                                            key: ValueKey(
                                              'sc_name_${option.name}_$i',
                                            ),
                                            initialValue: (choice['name'] ?? '')
                                                .toString(),
                                            decoration: InputDecoration(
                                              labelText: context.tr
                                                  .option_label_number(i + 1),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (v) {
                                              final updated =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(staticChoices);
                                              updated[i] = {
                                                ...updated[i],
                                                'name': v,
                                              };
                                              saveChoices(updated);
                                            },
                                          ),
                                          second: TextFormField(
                                            key: ValueKey(
                                              'sc_val_${option.name}_$i',
                                            ),
                                            initialValue:
                                                (choice['value'] ?? '')
                                                    .toString(),
                                            decoration: InputDecoration(
                                              labelText: context.tr
                                                  .option_value_number(i + 1),
                                              border:
                                                  const OutlineInputBorder(),
                                              isDense: true,
                                            ),
                                            onChanged: (v) {
                                              final updated =
                                                  List<
                                                    Map<String, dynamic>
                                                  >.from(staticChoices);
                                              updated[i] = {
                                                ...updated[i],
                                                'value': v,
                                              };
                                              saveChoices(updated);
                                            },
                                          ),
                                          trailing: IconButton(
                                            icon: const AppIcon.fromMaterial(
                                              Icons.delete_outline,
                                            ),
                                            tooltip: context.tr.common_remove,
                                            onPressed: () async {
                                              final shouldDelete =
                                                  await AppTheme.showConfirmDialog(
                                                    context,
                                                    title: context
                                                        .tr
                                                        .option_delete_title,
                                                    content: context
                                                        .tr
                                                        .option_choice_delete_confirm,
                                                    confirmLabel: context
                                                        .tr
                                                        .common_delete,
                                                    isDestructive: true,
                                                  );
                                              if (!shouldDelete) {
                                                return;
                                              }
                                              final updated =
                                                  List<
                                                      Map<String, dynamic>
                                                    >.from(staticChoices)
                                                    ..removeAt(i);
                                              saveChoices(updated);
                                            },
                                          ),
                                        ),
                                      );
                                    }),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          final updated = [
                                            ...staticChoices,
                                            {
                                              'name':
                                                  'Option ${staticChoices.length + 1}',
                                              'value':
                                                  'option_${staticChoices.length + 1}',
                                            },
                                          ];
                                          saveChoices(updated);
                                        },
                                        icon: const AppIcon.fromMaterial(
                                          Icons.add,
                                        ),
                                        label: Text(
                                          context.tr.common_add_option,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              // ── JavaScript panel ───────────────────────────
                              Widget javascriptPanel() {
                                final script =
                                    (cfg['jsScript'] ??
                                            defaultJsAutocompleteScript)
                                        .toString();
                                final preview = script.trim().isEmpty
                                    ? defaultJsAutocompleteScript
                                    : (script.length > 220
                                          ? '${script.substring(0, 220)}…'
                                          : script);

                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        context.tr.option_autocomplete_js_hint,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        preview,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                          color: Color(0xFFCFD8DC),
                                        ),
                                        maxLines: 8,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 10),
                                      FilledButton.icon(
                                        onPressed: () async {
                                          final result = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute<String>(
                                              builder: (_) => JsEditorPage(
                                                initialCode:
                                                    script.trim().isEmpty
                                                    ? defaultJsAutocompleteScript
                                                    : script,
                                                title: context
                                                    .tr
                                                    .option_autocomplete_javascript,
                                                snippets:
                                                    jsAutocompleteSnippets,
                                              ),
                                            ),
                                          );
                                          if (result != null) {
                                            saveConfig(
                                              updatedCfg({'jsScript': result}),
                                            );
                                          }
                                        },
                                        icon: const AppIcon.fromMaterial(
                                          Icons.edit_note,
                                          size: 18,
                                        ),
                                        label: Text(
                                          script.trim().isEmpty
                                              ? 'Configure Autocomplete JavaScript'
                                              : 'Edit Autocomplete JavaScript',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // ── Inline actions panel ──────────────────────
                              Widget inlinePanel() {
                                final inlineActions = cfg['inlineActions'];
                                final count = inlineActions is List
                                    ? inlineActions.length
                                    : 0;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm,
                                    ),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (count > 0) ...[
                                        Text(
                                          context.tr.actions_configured_count(
                                            count,
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                      ],
                                      FilledButton.icon(
                                        onPressed: () async {
                                          final initial =
                                              (inlineActions is List)
                                              ? List<Map<String, dynamic>>.from(
                                                  inlineActions
                                                      .whereType<Map>()
                                                      .map(
                                                        (e) =>
                                                            Map<
                                                              String,
                                                              dynamic
                                                            >.from(e),
                                                      ),
                                                )
                                              : <Map<String, dynamic>>[];

                                          final result =
                                              await Navigator.push<
                                                List<Map<String, dynamic>>
                                              >(
                                                context,
                                                MaterialPageRoute<
                                                  List<Map<String, dynamic>>
                                                >(
                                                  builder: (_) => ActionsBuilderPage(
                                                    initialActions: initial,
                                                    variableSuggestions: widget
                                                        .variableSuggestions,
                                                    emojiSuggestions: const [],
                                                    botIdForConfig:
                                                        widget.botIdForConfig,
                                                    isInteraction: false,
                                                    isWorkflow: true,
                                                    isAutocompleteContext: true,
                                                    onChanged: (updatedActions) {
                                                      saveConfig(
                                                        updatedCfg({
                                                          'inlineActions':
                                                              updatedActions,
                                                        }),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );

                                          if (result != null) {
                                            saveConfig(
                                              updatedCfg({
                                                'inlineActions': result,
                                              }),
                                            );
                                          }
                                        },
                                        icon: AppIcon.fromMaterial(
                                          count > 0
                                              ? Icons.edit_note
                                              : Icons.add,
                                          size: 18,
                                        ),
                                        label: Text(
                                          count > 0
                                              ? 'Edit Autocomplete Actions'
                                              : 'Configure Autocomplete Actions',
                                        ),
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSm,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  modeSelector,
                                  const SizedBox(height: 10),
                                  if (currentMode == 'workflow')
                                    workflowPanel()
                                  else if (currentMode == 'inline')
                                    inlinePanel()
                                  else if (currentMode == 'javascript')
                                    javascriptPanel()
                                  else
                                    staticPanel(),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_isNumericType(option.type)) ...<Widget>[
                          _responsiveRow(
                            first: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: context.tr.option_min_value,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              initialValue: option.minValue?.toString(),
                              onChanged: (String value) {
                                setState(() {
                                  option.minValue = value.isEmpty
                                      ? null
                                      : num.tryParse(value);
                                  _updateWidget();
                                });
                              },
                            ),
                            second: TextFormField(
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: context.tr.option_max_value,
                                border: const OutlineInputBorder(),
                                isDense: true,
                              ),
                              initialValue: option.maxValue?.toString(),
                              onChanged: (String value) {
                                setState(() {
                                  option.maxValue = value.isEmpty
                                      ? null
                                      : num.tryParse(value);
                                  _updateWidget();
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        _tile(
                          margin: const EdgeInsets.only(top: 4),
                          child: ExpansionTile(
                            shape: const Border(),
                            collapsedShape: const Border(),
                            title: Text(context.tr.option_add_localizations),
                            childrenPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            children: <Widget>[
                              DropdownButtonFormField<Locale>(
                                decoration: InputDecoration(
                                  labelText: context.tr.option_select_language,
                                  border: const OutlineInputBorder(),
                                ),
                                initialValue: Locale.fr,
                                items: Locale.values
                                    .map(
                                      (Locale locale) =>
                                          DropdownMenuItem<Locale>(
                                            value: locale,
                                            child: Text(
                                              locale.toString().split('.').last,
                                            ),
                                          ),
                                    )
                                    .toList(growable: false),
                                onChanged: (Locale? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  setState(() {
                                    option.nameLocalizations ??=
                                        <Locale, String>{};
                                    option.descriptionLocalizations ??=
                                        <Locale, String>{};
                                    option.nameLocalizations!.putIfAbsent(
                                      value,
                                      () => '',
                                    );
                                    option.descriptionLocalizations!
                                        .putIfAbsent(value, () => '');
                                    _updateWidget();
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (option.nameLocalizations != null &&
                                  option.nameLocalizations!.isNotEmpty)
                                ...option.nameLocalizations!.entries.map((
                                  entry,
                                ) {
                                  final locale = entry.key;
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Text(
                                                locale
                                                    .toString()
                                                    .split('.')
                                                    .last,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon:
                                                    const AppIcon.fromMaterial(
                                                      Icons.delete,
                                                      size: 20,
                                                    ),
                                                onPressed: () async {
                                                  final shouldDelete =
                                                      await AppTheme.showConfirmDialog(
                                                        context,
                                                        title: context
                                                            .tr
                                                            .option_delete_localization_title,
                                                        content: context
                                                            .tr
                                                            .option_delete_localization_confirm,
                                                        confirmLabel: context
                                                            .tr
                                                            .common_delete,
                                                        isDestructive: true,
                                                      );
                                                  if (!shouldDelete) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    option.nameLocalizations!
                                                        .remove(locale);
                                                    option
                                                        .descriptionLocalizations!
                                                        .remove(locale);
                                                    _updateWidget();
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          TextFormField(
                                            decoration: InputDecoration(
                                              labelText: context
                                                  .tr
                                                  .option_localized_name,
                                              isDense: true,
                                            ),
                                            initialValue: option
                                                .nameLocalizations![locale],
                                            onChanged: (String val) {
                                              setState(() {
                                                option.nameLocalizations![locale] =
                                                    val;
                                                _updateWidget();
                                              });
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          TextFormField(
                                            decoration: InputDecoration(
                                              labelText: context
                                                  .tr
                                                  .option_localized_description,
                                              isDense: true,
                                            ),
                                            initialValue: option
                                                .descriptionLocalizations![locale],
                                            onChanged: (String val) {
                                              setState(() {
                                                option.descriptionLocalizations![locale] =
                                                    val;
                                                _updateWidget();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_supportsChoices(option.type) &&
                            !isCommandOptionAutocompleteEnabled(
                              option,
                            )) ...<Widget>[
                          if (option.choices != null)
                            ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: option.choices?.length ?? 0,
                              itemBuilder:
                                  (BuildContext context, int choiceIndex) {
                                    return ExpansionTile(
                                      title: Text(
                                        context.tr.component_choice_number(
                                          choiceIndex + 1,
                                        ),
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      trailing: IconButton(
                                        icon: const AppIcon.fromMaterial(
                                          Icons.delete,
                                        ),
                                        onPressed: () async {
                                          final shouldDelete =
                                              await AppTheme.showConfirmDialog(
                                                context,
                                                title: context
                                                    .tr
                                                    .option_choice_delete_title,
                                                content: context
                                                    .tr
                                                    .option_choice_delete_confirm,
                                                confirmLabel:
                                                    context.tr.common_delete,
                                                isDestructive: true,
                                              );
                                          if (!shouldDelete) {
                                            return;
                                          }

                                          setState(() {
                                            option.choices!.removeAt(
                                              choiceIndex,
                                            );
                                            _updateWidget();
                                          });
                                        },
                                      ),
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      children: <Widget>[
                                        TextFormField(
                                          decoration: InputDecoration(
                                            labelText:
                                                context.tr.option_choice_name,
                                            border: const OutlineInputBorder(),
                                          ),
                                          initialValue:
                                              option.choices![choiceIndex].name,
                                          maxLength: 100,
                                          onChanged: (String value) {
                                            setState(() {
                                              option
                                                      .choices![choiceIndex]
                                                      .name =
                                                  value;
                                              _updateWidget();
                                            });
                                          },
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          keyboardType: _choiceKeyboardType(
                                            option.type,
                                          ),
                                          decoration: InputDecoration(
                                            labelText:
                                                context.tr.option_choice_value,
                                            border: const OutlineInputBorder(),
                                          ),
                                          initialValue: option
                                              .choices![choiceIndex]
                                              .value
                                              .toString(),
                                          maxLength: 100,
                                          onChanged: (String value) {
                                            setState(() {
                                              if (_isNumericType(option.type)) {
                                                option
                                                        .choices![choiceIndex]
                                                        .value =
                                                    num.tryParse(value) ?? 0;
                                              } else {
                                                option
                                                        .choices![choiceIndex]
                                                        .value =
                                                    value;
                                              }
                                              _updateWidget();
                                            });
                                          },
                                        ),
                                      ],
                                    );
                                  },
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.homeContainerLowest,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onSurface,
                                elevation: 0,
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(
                                    color: AppTheme.homeGhostBorder,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  option.choices ??=
                                      <CommandOptionChoiceBuilder>[];
                                  option.choices!.add(
                                    CommandOptionChoiceBuilder(
                                      name:
                                          'Choice ${option.choices!.length + 1}',
                                      value: _isNumericType(option.type)
                                          ? 0
                                          : 'Value ${option.choices!.length + 1}',
                                    ),
                                  );
                                  _updateWidget();
                                });
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const AppIcon.fromMaterial(Icons.add),
                                  const SizedBox(width: 8),
                                  Text(context.tr.option_add_choice),
                                ],
                              ),
                            ),
                          ),
                        ],
                        if (_isHierarchyType(option.type)) ...<Widget>[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              option.type == CommandOptionType.subCommandGroup
                                  ? context.tr.option_subcommands
                                  : context.tr.option_subcommand_options,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.grey),
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusSm,
                              ),
                            ),
                            child: _buildOptionsLevel(
                              option.options ?? <CommandOptionBuilder>[],
                              parentType: option.type,
                              depth: depth + 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        if (levelOptions.length < 25)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.homeContainerLowest,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                elevation: 0,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppTheme.homeGhostBorder),
                ),
              ),
              onPressed: () {
                setState(() {
                  levelOptions.add(
                    _buildDefaultOption(levelOptions, parentType: parentType),
                  );
                  _updateWidget();
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const AppIcon.fromMaterial(Icons.add),
                  const SizedBox(width: 8),
                  Text(context.tr.common_add_option),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _responsiveRow({
    required Widget first,
    required Widget second,
    Widget? trailing,
    int firstFlex = 1,
    int secondFlex = 1,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: first),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: second),
                  if (trailing != null) SizedBox(width: 40),
                ],
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: firstFlex, child: first),
            const SizedBox(width: 6),
            Expanded(flex: secondFlex, child: second),
            ?trailing,
          ],
        );
      },
    );
  }

  /// Rounded, bordered surface shared by every row of an option, so the whole
  /// editor reads as one design (cards inside the command-options card).
  Widget _tile({
    required Widget child,
    double radius = 14,
    EdgeInsetsGeometry margin = EdgeInsets.zero,
  }) {
    return Padding(
      padding: margin,
      child: Material(
        clipBehavior: Clip.antiAlias,
        color: AppTheme.homeContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: AppTheme.homeCardBorder),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        children: <Widget>[
          _buildOptionsLevel(options, parentType: null, depth: 0),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
