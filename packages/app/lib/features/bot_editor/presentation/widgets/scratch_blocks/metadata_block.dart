import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';

import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/main.dart';

import 'package:bot_creator/features/bot_editor/presentation/widgets/command_create_cards/basic_info_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/option_widget.dart';
import 'scratch_block.dart';
import 'scratch_block_palette.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class _MaxTwoCommaSeparatedFormatter extends TextInputFormatter {
  const _MaxTwoCommaSeparatedFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final parts = newValue.text.split(',');
    if (parts.length > 2) {
      final truncated = '${parts[0]},${parts[1]}';
      return TextEditingValue(
        text: truncated,
        selection: TextSelection.collapsed(offset: truncated.length),
      );
    }
    return newValue;
  }
}

/// A fixed (non-deletable) block that displays command metadata.
///
/// Shows essential fields (name, description, type, folder) directly,
/// and hides advanced Discord settings behind an expandable section.
class MetadataBlock extends StatefulWidget {
  const MetadataBlock({
    super.key,
    required this.commandName,
    required this.commandDescription,
    required this.commandType,
    required this.isLegacyCommand,
    required this.localOnlyCommand,
    required this.canEditCommandType,
    required this.showDescriptionField,
    required this.integrationTypes,
    required this.contexts,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onCommandTypeChanged,
    required this.onLegacyCommandChanged,
    required this.onLocalOnlyCommandChanged,
    required this.onIntegrationTypesChanged,
    required this.onContextsChanged,
    required this.defaultMemberPermissions,
    required this.onDefaultMemberPermissionsChanged,
    required this.nameValidator,
    this.nameMaxLength = 32,
    this.legacyAliases = const <String>[],
    this.onLegacyAliasesChanged,
    // Options
    this.showOptions = true,
    this.options,
    this.onOptionsChanged,
    this.botIdForConfig,
    this.variableSuggestions = const [],
    // Folder
    this.folderController,
    this.onFolderChanged,
    this.showCommandTypeSelector = false,
  });

  final bool showCommandTypeSelector;

  final String commandName;
  final String commandDescription;
  final ApplicationCommandType commandType;
  final bool isLegacyCommand;
  final bool localOnlyCommand;
  final bool canEditCommandType;
  final bool showDescriptionField;
  final List<ApplicationIntegrationType> integrationTypes;
  final List<InteractionContextType> contexts;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<ApplicationCommandType> onCommandTypeChanged;
  final ValueChanged<bool> onLegacyCommandChanged;
  final ValueChanged<bool> onLocalOnlyCommandChanged;
  final ValueChanged<List<ApplicationIntegrationType>>
  onIntegrationTypesChanged;
  final ValueChanged<List<InteractionContextType>> onContextsChanged;
  final String defaultMemberPermissions;
  final ValueChanged<String> onDefaultMemberPermissionsChanged;
  final String? Function(String?) nameValidator;
  final int nameMaxLength;
  final List<String> legacyAliases;
  final ValueChanged<List<String>>? onLegacyAliasesChanged;

  // Options
  final bool showOptions;
  final List<CommandOptionBuilder>? options;
  final ValueChanged<List<CommandOptionBuilder>>? onOptionsChanged;
  final String? botIdForConfig;
  final List<VariableSuggestion> variableSuggestions;

  // Folder
  final TextEditingController? folderController;
  final ValueChanged<String>? onFolderChanged;

  @override
  State<MetadataBlock> createState() => _MetadataBlockState();
}

class _MetadataBlockState extends State<MetadataBlock> {
  bool _collapsed = false;
  bool _advancedExpanded = false;
  bool _optionsExpanded = false;

  late final TextEditingController _nameController;
  late final TextEditingController _aliasesController;
  List<String> _existingFolders = const <String>[];

  static List<String> _parseAliases(String raw) {
    final parts = raw.split(',');
    final result = <String>[];
    for (final part in parts) {
      var cleaned = part.trim();
      if (cleaned.startsWith('!')) {
        cleaned = cleaned.substring(1).trim();
      }
      cleaned = cleaned.toLowerCase();
      if (cleaned.isNotEmpty && !result.contains(cleaned)) {
        result.add(cleaned);
        if (result.length >= 2) break;
      }
    }
    return result;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.commandName);
    _aliasesController = TextEditingController(
      text: widget.legacyAliases.take(2).join(', '),
    );
    _loadExistingFolders();
  }

  Future<void> _loadExistingFolders() async {
    final botId = widget.botIdForConfig;
    if (botId != null) {
      try {
        final commands = await appManager.listAppCommands(botId);
        final folders =
            commands
                .map((c) => (c['folder'] ?? '').toString().trim())
                .where((f) => f.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
        if (mounted) {
          setState(() {
            _existingFolders = folders;
          });
        }
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(covariant MetadataBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commandName != widget.commandName &&
        _nameController.text != widget.commandName) {
      _nameController.text = widget.commandName;
    }
    if (!listEquals(oldWidget.legacyAliases, widget.legacyAliases)) {
      final currentParsed = _parseAliases(_aliasesController.text);
      if (!listEquals(currentParsed, widget.legacyAliases)) {
        final nextText = widget.legacyAliases.take(2).join(', ');
        if (_aliasesController.text != nextText) {
          _aliasesController.text = nextText;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  String _commandTypeSegmentValue() {
    if (widget.isLegacyCommand) return 'legacy';
    if (widget.commandType == ApplicationCommandType.user) return 'user';
    if (widget.commandType == ApplicationCommandType.message) return 'message';
    return 'slash';
  }

  /// Count of advanced settings that differ from defaults.
  int get _advancedSettingsCount {
    var count = 0;
    if (widget.localOnlyCommand) count++;
    if (widget.defaultMemberPermissions.isNotEmpty) count++;
    if (!widget.integrationTypes.contains(
          ApplicationIntegrationType.guildInstall,
        ) ||
        widget.integrationTypes.contains(
          ApplicationIntegrationType.userInstall,
        )) {
      count++;
    }
    if (widget.contexts.length != 1 ||
        !widget.contexts.contains(InteractionContextType.guild)) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ScratchBlock(
      color: getCategoryColor('Metadata'),
      title: context.tr.scratch_block_metadata,
      icon: Icons.info_outline,
      required: true,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      badge: ScratchBlockBadge(
        label: context.tr.scratch_block_required,
        color: getCategoryColor('Metadata'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Command name ──
          TextFormField(
            controller: _nameController,
            autocorrect: false,
            validator: widget.nameValidator,
            maxLength: widget.nameMaxLength,
            decoration: InputDecoration(
              labelText: context.tr.command_name_label,
              hintText: context.tr.scratch_meta_name_hint,
              prefixIcon: const AppIcon.fromMaterial(Icons.tag),
              border: const OutlineInputBorder(),
            ),
            onChanged: widget.onNameChanged,
          ),

          // ── Aliases (Prefix Commands only) ──
          if (widget.isLegacyCommand) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _aliasesController,
              autocorrect: false,
              inputFormatters: const [_MaxTwoCommaSeparatedFormatter()],
              decoration: InputDecoration(
                labelText: context.tr.command_alias_label,
                hintText: 'p, ping',
                helperText: context.tr.command_alias_limit(2),
                prefixIcon: const AppIcon.fromMaterial(
                  Icons.alternate_email,
                  size: 20,
                ),
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return null;
                final parts = val.split(',');
                if (parts.length > 2) {
                  return context.tr.command_alias_limit(2);
                }
                for (final p in parts) {
                  final t = p.trim();
                  if (t.isNotEmpty && RegExp(r'\s').hasMatch(t)) {
                    return 'Alias cannot contain spaces';
                  }
                  if (t.length > 32) {
                    return 'Alias maximum length is 32 characters';
                  }
                }
                return null;
              },
              onChanged: (text) {
                widget.onLegacyAliasesChanged?.call(_parseAliases(text));
              },
            ),
          ],

          // ── Description ──
          if (widget.showDescriptionField) ...[
            const SizedBox(height: 12),
            TextFormField(
              autocorrect: false,
              maxLength: 100,
              maxLines: 2,
              minLines: 1,
              initialValue: widget.commandDescription,
              decoration: InputDecoration(
                labelText: context.tr.common_description,
                hintText: context.tr.scratch_meta_desc_hint,
                prefixIcon: const AppIcon.fromMaterial(Icons.short_text),
                border: const OutlineInputBorder(),
              ),
              onChanged: widget.onDescriptionChanged,
            ),
          ],

          // ── Command type (simplified, omitted by default as EntryPointBlock handles it) ──
          if (widget.showCommandTypeSelector) ...[
            const SizedBox(height: 12),
            Text(
              context.tr.scratch_meta_type_label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 420;
                return SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'slash',
                      label: compact
                          ? const SizedBox.shrink()
                          : Text(context.tr.scratch_meta_type_slash),
                      icon: const AppIcon.fromMaterial(
                        Icons.terminal,
                        size: 18,
                      ),
                      tooltip: compact
                          ? context.tr.scratch_meta_type_slash
                          : null,
                    ),
                    ButtonSegment(
                      value: 'legacy',
                      label: compact
                          ? const SizedBox.shrink()
                          : Text(context.tr.scratch_meta_type_prefix),
                      icon: const AppIcon.fromMaterial(
                        Icons.textsms_outlined,
                        size: 18,
                      ),
                      tooltip: compact
                          ? context.tr.scratch_meta_type_prefix
                          : null,
                    ),
                    ButtonSegment(
                      value: 'user',
                      label: compact
                          ? const SizedBox.shrink()
                          : Text(context.tr.scratch_meta_type_user),
                      icon: const AppIcon.fromMaterial(
                        Icons.person_outline,
                        size: 18,
                      ),
                      tooltip: compact
                          ? context.tr.scratch_meta_type_user
                          : null,
                    ),
                    ButtonSegment(
                      value: 'message',
                      label: compact
                          ? const SizedBox.shrink()
                          : Text(context.tr.scratch_meta_type_message),
                      icon: const AppIcon.fromMaterial(
                        Icons.message_outlined,
                        size: 18,
                      ),
                      tooltip: compact
                          ? context.tr.scratch_meta_type_message
                          : null,
                    ),
                  ],
                  selected: {_commandTypeSegmentValue()},
                  onSelectionChanged: widget.canEditCommandType
                      ? (value) {
                          final selected = value.first;
                          if (selected == 'legacy') {
                            widget.onLegacyCommandChanged(true);
                            widget.onCommandTypeChanged(
                              ApplicationCommandType.chatInput,
                            );
                          } else {
                            widget.onLegacyCommandChanged(false);
                            widget.onCommandTypeChanged(
                              selected == 'user'
                                  ? ApplicationCommandType.user
                                  : selected == 'message'
                                  ? ApplicationCommandType.message
                                  : ApplicationCommandType.chatInput,
                            );
                          }
                        }
                      : null,
                );
              },
            ),
            // Type helper text
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _commandTypeHelperText(),
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],

          // ── Folder ──
          if (widget.folderController != null) ...[
            const SizedBox(height: 12),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (_existingFolders.isEmpty) {
                  return const Iterable<String>.empty();
                }
                if (textEditingValue.text.isEmpty) {
                  return _existingFolders;
                }
                final query = textEditingValue.text.toLowerCase();
                return _existingFolders.where((String option) {
                  return option.toLowerCase().contains(query);
                });
              },
              onSelected: (String selection) {
                widget.folderController?.text = selection;
                if (widget.onFolderChanged != null) {
                  widget.onFolderChanged!(selection);
                }
              },
              optionsViewBuilder:
                  (
                    BuildContext context,
                    AutocompleteOnSelected<String> onSelected,
                    Iterable<String> options,
                  ) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        color: Theme.of(context).colorScheme.surface,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 200,
                            maxWidth: 300,
                          ),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final String option = options.elementAt(index);
                              return InkWell(
                                onTap: () => onSelected(option),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      AppIcon.fromMaterial(
                                        Icons.folder_outlined,
                                        size: 18,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        option,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    final folderController = widget.folderController;
                    if (folderController != null &&
                        controller.text != folderController.text) {
                      controller.text = folderController.text;
                    }
                    controller.addListener(() {
                      if (folderController != null &&
                          folderController.text != controller.text) {
                        folderController.text = controller.text;
                        if (widget.onFolderChanged != null) {
                          widget.onFolderChanged!(controller.text.trim());
                        }
                      }
                    });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: context.tr.commands_folder_label,
                        hintText: context.tr.commands_folder_hint,
                        prefixIcon: const AppIcon.fromMaterial(
                          Icons.folder_outlined,
                        ),
                        suffixIcon: _existingFolders.isNotEmpty
                            ? PopupMenuButton<String>(
                                icon: const AppIcon.fromMaterial(
                                  Icons.folder_open,
                                ),
                                tooltip:
                                    context.tr.command_create_existing_folders,
                                onSelected: (String selection) {
                                  setState(() {
                                    controller.text = selection;
                                    if (folderController != null) {
                                      folderController.text = selection;
                                    }
                                  });
                                  if (widget.onFolderChanged != null) {
                                    widget.onFolderChanged!(selection);
                                  }
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
                      onSubmitted: (_) => onFieldSubmitted(),
                    );
                  },
            ),
          ],

          // ── Advanced settings (collapsed by default) ──
          // Keep visible if already expanded (e.g. user enabled awaited preset
          // which changes the command type to legacy).
          if (!widget.isLegacyCommand || _advancedExpanded) ...[
            const SizedBox(height: 16),
            _buildAdvancedSection(colorScheme),
          ],

          // ── Slash command options ──
          if (widget.showOptions &&
              widget.options != null &&
              widget.onOptionsChanged != null) ...[
            const SizedBox(height: 12),
            _buildOptionsSection(),
          ],
        ],
      ),
    );
  }

  String _commandTypeHelperText() {
    switch (_commandTypeSegmentValue()) {
      case 'slash':
        return context.tr.scratch_meta_type_slash_desc;
      case 'legacy':
        return context.tr.scratch_meta_type_prefix_desc;
      case 'user':
        return context.tr.scratch_meta_type_user_desc;
      case 'message':
        return context.tr.scratch_meta_type_message_desc;
      default:
        return '';
    }
  }

  Widget _buildAdvancedSection(ColorScheme colorScheme) {
    final advancedCount = _advancedSettingsCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _advancedExpanded = !_advancedExpanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AppIcon.fromMaterial(
                  _advancedExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                AppIcon.fromMaterial(
                  Icons.tune,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  context.tr.scratch_meta_advanced,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (advancedCount > 0) ...[
                  const SizedBox(width: 8),
                  ScratchBlockBadge(
                    label: '$advancedCount',
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_advancedExpanded) ...[
          const SizedBox(height: 8),
          // Delegate to BasicInfoCard for the advanced fields.
          // We hide it inside the expansion so a beginner never sees it.
          BasicInfoCard(
            commandName: widget.commandName,
            commandDescription: widget.commandDescription,
            commandType: widget.commandType,
            isLegacyCommand: widget.isLegacyCommand,
            canEditCommandType: widget.canEditCommandType,
            showDescriptionField: false, // Already shown above
            integrationTypes: widget.integrationTypes,
            contexts: widget.contexts,
            onNameChanged: (name) {
              if (_nameController.text != name) {
                _nameController.text = name;
              }
              widget.onNameChanged(name);
            },
            onDescriptionChanged: (_) {},
            onCommandTypeChanged: widget.onCommandTypeChanged,
            onLegacyCommandChanged: widget.onLegacyCommandChanged,
            localOnlyCommand: widget.localOnlyCommand,
            onLocalOnlyCommandChanged: widget.onLocalOnlyCommandChanged,
            onIntegrationTypesChanged: widget.onIntegrationTypesChanged,
            onContextsChanged: widget.onContextsChanged,
            defaultMemberPermissions: widget.defaultMemberPermissions,
            onDefaultMemberPermissionsChanged:
                widget.onDefaultMemberPermissionsChanged,
            nameValidator: widget.nameValidator,
            nameMaxLength: widget.nameMaxLength,
            legacyAliases: widget.legacyAliases,
            onLegacyAliasesChanged: widget.onLegacyAliasesChanged,
          ),
        ],
      ],
    );
  }

  Widget _buildOptionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _optionsExpanded = !_optionsExpanded),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                AppIcon.fromMaterial(
                  _optionsExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  context.tr.command_options_title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.options!.isNotEmpty)
                  ScratchBlockBadge(
                    label: '${widget.options!.length}',
                    color: getCategoryColor('Metadata'),
                  ),
              ],
            ),
          ),
        ),
        if (_optionsExpanded)
          OptionWidget(
            onChange: widget.onOptionsChanged!,
            initialOptions: widget.options,
            botIdForConfig: widget.botIdForConfig,
            variableSuggestions: widget.variableSuggestions,
          ),
      ],
    );
  }
}
