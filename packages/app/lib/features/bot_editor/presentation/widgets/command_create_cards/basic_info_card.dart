import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_command_validation_messages.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

class BasicInfoCard extends StatefulWidget {
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

  const BasicInfoCard({
    super.key,
    required this.commandName,
    required this.commandDescription,
    required this.commandType,
    required this.isLegacyCommand,
    required this.canEditCommandType,
    required this.showDescriptionField,
    required this.integrationTypes,
    required this.contexts,
    required this.onNameChanged,
    required this.onDescriptionChanged,
    required this.onCommandTypeChanged,
    required this.onLegacyCommandChanged,
    required this.localOnlyCommand,
    required this.onLocalOnlyCommandChanged,
    required this.onIntegrationTypesChanged,
    required this.onContextsChanged,
    required this.defaultMemberPermissions,
    required this.onDefaultMemberPermissionsChanged,
    required this.nameValidator,
    this.nameMaxLength = 32,
    this.legacyAliases = const <String>[],
    this.onLegacyAliasesChanged,
  });

  @override
  State<BasicInfoCard> createState() => _BasicInfoCardState();
}

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

class _BasicInfoCardState extends State<BasicInfoCard> {
  static final RegExp _awaitedSuccessPattern = RegExp(
    r'^\$awaitedcommand\[(.+?);(.*)\]$',
    caseSensitive: false,
  );
  static final RegExp _awaitedErrorPattern = RegExp(
    r'^\$awaitedcommanderror\[(.+?)\]$',
    caseSensitive: false,
  );
  static final List<_PermissionItem> _permissionItems = [
    _PermissionItem(0, 'Create Invite'),
    _PermissionItem(1, 'Kick Members'),
    _PermissionItem(2, 'Ban Members'),
    _PermissionItem(3, 'Administrator'),
    _PermissionItem(4, 'Manage Channels'),
    _PermissionItem(5, 'Manage Server'),
    _PermissionItem(6, 'Add Reactions'),
    _PermissionItem(7, 'View Audit Log'),
    _PermissionItem(8, 'Priority Speaker'),
    _PermissionItem(9, 'Stream'),
    _PermissionItem(10, 'View Channel'),
    _PermissionItem(11, 'Send Messages'),
    _PermissionItem(12, 'Send TTS Messages'),
    _PermissionItem(13, 'Manage Messages'),
    _PermissionItem(14, 'Embed Links'),
    _PermissionItem(15, 'Attach Files'),
    _PermissionItem(16, 'Read Message History'),
    _PermissionItem(17, 'Mention Everyone'),
    _PermissionItem(18, 'Use External Emojis'),
    _PermissionItem(19, 'View Server Insights'),
    _PermissionItem(20, 'Connect (Voice)'),
    _PermissionItem(21, 'Speak (Voice)'),
    _PermissionItem(22, 'Mute Members'),
    _PermissionItem(23, 'Deafen Members'),
    _PermissionItem(24, 'Move Members'),
    _PermissionItem(25, 'Use Voice Activity'),
    _PermissionItem(26, 'Change Nickname'),
    _PermissionItem(27, 'Manage Nicknames'),
    _PermissionItem(28, 'Manage Roles'),
    _PermissionItem(29, 'Manage Webhooks'),
    _PermissionItem(30, 'Manage Expressions'),
    _PermissionItem(31, 'Use Application Commands'),
    _PermissionItem(32, 'Request To Speak'),
    _PermissionItem(33, 'Manage Events'),
    _PermissionItem(34, 'Manage Threads'),
    _PermissionItem(35, 'Create Public Threads'),
    _PermissionItem(36, 'Create Private Threads'),
    _PermissionItem(37, 'Use External Stickers'),
    _PermissionItem(38, 'Send Messages In Threads'),
    _PermissionItem(39, 'Use Embedded Activities'),
    _PermissionItem(40, 'Moderate Members'),
    _PermissionItem(41, 'View Monetization Analytics'),
    _PermissionItem(42, 'Use Soundboard'),
    _PermissionItem(43, 'Create Expressions'),
    _PermissionItem(44, 'Create Events'),
    _PermissionItem(45, 'Use External Sounds'),
    _PermissionItem(46, 'Send Voice Messages'),
    _PermissionItem(49, 'Send Polls'),
    _PermissionItem(50, 'Use External Apps'),
  ];

  late Set<int> _selectedPermissionOffsets;
  late BigInt _unknownBits;
  late final TextEditingController _nameController;
  late final TextEditingController _aliasesController;
  bool _awaitedPresetEnabled = false;
  bool _awaitedIsErrorTrigger = false;
  String _awaitedCallbackName = '';
  String _awaitedCallbackFilter = '';

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
    _selectedPermissionOffsets = <int>{};
    _unknownBits = BigInt.zero;
    _nameController = TextEditingController(text: widget.commandName);
    _aliasesController = TextEditingController(
      text: widget.legacyAliases.take(2).join(', '),
    );
    _applyBitfield(widget.defaultMemberPermissions);
    _syncAwaitedPresetFromCommandName(widget.commandName);
  }

  @override
  void didUpdateWidget(covariant BasicInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultMemberPermissions != widget.defaultMemberPermissions) {
      _applyBitfield(widget.defaultMemberPermissions);
    }
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
    if (oldWidget.commandName != widget.commandName ||
        oldWidget.isLegacyCommand != widget.isLegacyCommand ||
        oldWidget.localOnlyCommand != widget.localOnlyCommand) {
      _syncAwaitedPresetFromCommandName(widget.commandName);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aliasesController.dispose();
    super.dispose();
  }

  void _applyBitfield(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      _selectedPermissionOffsets = <int>{};
      _unknownBits = BigInt.zero;
      return;
    }

    BigInt parsed;
    try {
      parsed = BigInt.parse(trimmed);
    } catch (_) {
      _selectedPermissionOffsets = <int>{};
      _unknownBits = BigInt.zero;
      return;
    }

    if (parsed < BigInt.zero) {
      parsed = BigInt.zero;
    }

    final selected = <int>{};
    BigInt knownMask = BigInt.zero;

    for (final item in _permissionItems) {
      final bit = BigInt.one << item.offset;
      knownMask |= bit;
      if ((parsed & bit) != BigInt.zero) {
        selected.add(item.offset);
      }
    }

    _selectedPermissionOffsets = selected;
    _unknownBits = parsed & ~knownMask;
  }

  String _computedBitfield() {
    BigInt value = _unknownBits;
    for (final offset in _selectedPermissionOffsets) {
      value |= (BigInt.one << offset);
    }
    return value == BigInt.zero ? '' : value.toString();
  }

  void _togglePermission(int offset, bool enabled) {
    setState(() {
      if (enabled) {
        _selectedPermissionOffsets.add(offset);
      } else {
        _selectedPermissionOffsets.remove(offset);
      }
    });
    widget.onDefaultMemberPermissionsChanged(_computedBitfield());
  }

  void _clearPermissions() {
    setState(() {
      _selectedPermissionOffsets.clear();
      _unknownBits = BigInt.zero;
    });
    widget.onDefaultMemberPermissionsChanged('');
  }

  String _commandTypeValue() {
    if (widget.isLegacyCommand) {
      return 'legacy';
    }
    if (widget.commandType == ApplicationCommandType.user) {
      return 'user';
    }
    if (widget.commandType == ApplicationCommandType.message) {
      return 'message';
    }
    return 'slash';
  }

  String _rulesHintText() {
    if (widget.isLegacyCommand) {
      return context.tr.command_prefix_rules_hint;
    }
    if (widget.commandType == ApplicationCommandType.user) {
      return context.tr.command_discord_rules_user_hint;
    }
    if (widget.commandType == ApplicationCommandType.message) {
      return context.tr.command_discord_rules_message_hint;
    }
    return context.tr.command_discord_rules_slash_hint;
  }

  Widget _buildRulesBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        _rulesHintText(),
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  bool get _descriptionRequired =>
      widget.showDescriptionField && !widget.isLegacyCommand;

  bool get _canUseAwaitedPreset =>
      widget.isLegacyCommand ||
      widget.localOnlyCommand ||
      widget.canEditCommandType;

  void _syncAwaitedPresetFromCommandName(String commandName) {
    final normalized = commandName.trim();
    final successMatch = _awaitedSuccessPattern.firstMatch(normalized);
    if (successMatch != null) {
      _awaitedPresetEnabled = true;
      _awaitedIsErrorTrigger = false;
      _awaitedCallbackName = successMatch.group(1)?.trim() ?? '';
      _awaitedCallbackFilter = successMatch.group(2)?.trim() ?? '';
      return;
    }

    final errorMatch = _awaitedErrorPattern.firstMatch(normalized);
    if (errorMatch != null) {
      _awaitedPresetEnabled = true;
      _awaitedIsErrorTrigger = true;
      _awaitedCallbackName = errorMatch.group(1)?.trim() ?? '';
      _awaitedCallbackFilter = '';
      return;
    }

    if (!_awaitedPresetEnabled) {
      _awaitedIsErrorTrigger = false;
      _awaitedCallbackName = '';
      _awaitedCallbackFilter = '';
    }
  }

  String _fallbackAwaitedName() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      return 'callback';
    }
    final successMatch = _awaitedSuccessPattern.firstMatch(trimmed);
    if (successMatch != null) {
      return successMatch.group(1)?.trim().isNotEmpty == true
          ? successMatch.group(1)!.trim()
          : 'callback';
    }
    final errorMatch = _awaitedErrorPattern.firstMatch(trimmed);
    if (errorMatch != null) {
      return errorMatch.group(1)?.trim().isNotEmpty == true
          ? errorMatch.group(1)!.trim()
          : 'callback';
    }
    return trimmed;
  }

  String _buildAwaitedCommandName() {
    final callbackName = _awaitedCallbackName.trim();
    if (_awaitedIsErrorTrigger) {
      return '\$awaitedCommandError[$callbackName]';
    }
    return '\$awaitedCommand[$callbackName;${_awaitedCallbackFilter.trim()}]';
  }

  void _applyAwaitedPresetName() {
    final nextName = _buildAwaitedCommandName();
    if (_nameController.text != nextName) {
      _nameController.text = nextName;
    }
    widget.onNameChanged(nextName);
    setState(() {});
  }

  void _enableAwaitedPreset() {
    if (!_awaitedPresetEnabled) {
      widget.onLegacyCommandChanged(true);
      widget.onCommandTypeChanged(ApplicationCommandType.chatInput);
      widget.onLocalOnlyCommandChanged(true);
    }
    setState(() {
      _awaitedPresetEnabled = true;
      _awaitedCallbackName = _fallbackAwaitedName();
      _awaitedCallbackFilter = _awaitedIsErrorTrigger
          ? ''
          : _awaitedCallbackFilter;
      if (_awaitedCallbackName.isEmpty) {
        _awaitedCallbackName = 'callback';
      }
    });
    _applyAwaitedPresetName();
  }

  void _disableAwaitedPreset() {
    setState(() {
      _awaitedPresetEnabled = false;
      _awaitedIsErrorTrigger = false;
      _awaitedCallbackName = '';
      _awaitedCallbackFilter = '';
    });
  }

  Widget _buildAwaitedPresetCard() {
    final colorScheme = Theme.of(context).colorScheme;
    if (!_awaitedPresetEnabled) {
      return Card(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr.command_legacy_preset_title,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr.command_legacy_preset_desc,
                style: TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  key: const ValueKey('awaited-preset-enable'),
                  onPressed: _enableAwaitedPreset,
                  icon: const AppIcon.fromMaterial(Icons.hourglass_top_rounded),
                  label: Text(context.tr.command_awaited_preset_button),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: colorScheme.secondaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.command_awaited_preset_active,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _disableAwaitedPreset,
                  child: Text(context.tr.command_edit_raw_name),
                ),
              ],
            ),
            Text(
              context.tr.command_awaited_preset_desc,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              key: const ValueKey('awaited-preset-kind'),
              segments: <ButtonSegment<bool>>[
                ButtonSegment<bool>(
                  value: false,
                  label: Text(context.tr.command_awaited_success),
                  icon: const AppIcon.fromMaterial(Icons.check_circle_outline),
                ),
                ButtonSegment<bool>(
                  value: true,
                  label: Text(context.tr.command_awaited_error),
                  icon: const AppIcon.fromMaterial(Icons.error_outline),
                ),
              ],
              selected: <bool>{_awaitedIsErrorTrigger},
              onSelectionChanged: (selection) {
                final nextValue = selection.first;
                setState(() {
                  _awaitedIsErrorTrigger = nextValue;
                  if (_awaitedIsErrorTrigger) {
                    _awaitedCallbackFilter = '';
                  }
                });
                _applyAwaitedPresetName();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('awaited-preset-name'),
              initialValue: _awaitedCallbackName,
              decoration: InputDecoration(
                labelText: context.tr.command_awaited_name_label,
                hintText: context.tr.command_awaited_name_hint,
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _awaitedCallbackName = value.trim();
                _applyAwaitedPresetName();
              },
            ),
            if (!_awaitedIsErrorTrigger) ...[
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('awaited-preset-filter'),
                initialValue: _awaitedCallbackFilter,
                decoration: InputDecoration(
                  labelText: context.tr.command_awaited_filter_label,
                  hintText: context.tr.command_awaited_filter_hint,
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  _awaitedCallbackFilter = value.trim();
                  _applyAwaitedPresetName();
                },
              ),
            ],
            const SizedBox(height: 10),
            SelectableText(
              _buildAwaitedCommandName(),
              key: const ValueKey('awaited-preset-preview'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final computedBitfield = _computedBitfield();
    final selectedNames = _permissionItems
        .where((item) => _selectedPermissionOffsets.contains(item.offset))
        .map((item) => item.label)
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.command_info_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr.command_info_desc,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 10),
            _buildRulesBanner(Theme.of(context).colorScheme),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, innerConstraints) {
                final isWide = innerConstraints.maxWidth >= 760;
                final nameField = TextFormField(
                  controller: _nameController,
                  autocorrect: false,
                  readOnly: _awaitedPresetEnabled,
                  validator: widget.nameValidator,
                  maxLength: widget.nameMaxLength,
                  decoration: InputDecoration(
                    labelText: requiredFieldLabel(
                      context.tr.command_name_label,
                    ),
                    border: const OutlineInputBorder(),
                    helperText: _awaitedPresetEnabled
                        ? context.tr.command_name_generated
                        : null,
                  ),
                  onChanged: widget.onNameChanged,
                );

                final commandTypeField = DropdownButtonFormField<String>(
                  initialValue: _commandTypeValue(),
                  decoration: InputDecoration(
                    labelText: context.tr.command_type_label,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'slash',
                      child: Text(context.tr.command_type_slash),
                    ),
                    DropdownMenuItem(
                      value: 'legacy',
                      child: Text(context.tr.command_type_legacy),
                    ),
                    DropdownMenuItem(
                      value: 'user',
                      child: Text(context.tr.command_type_user),
                    ),
                    DropdownMenuItem(
                      value: 'message',
                      child: Text(context.tr.command_type_message),
                    ),
                  ],
                  onChanged: widget.canEditCommandType && !_awaitedPresetEnabled
                      ? (value) {
                          if (value != null) {
                            if (value == 'legacy') {
                              widget.onLegacyCommandChanged(true);
                              widget.onCommandTypeChanged(
                                ApplicationCommandType.chatInput,
                              );
                            } else {
                              widget.onLegacyCommandChanged(false);
                              widget.onCommandTypeChanged(
                                value == 'user'
                                    ? ApplicationCommandType.user
                                    : value == 'message'
                                    ? ApplicationCommandType.message
                                    : ApplicationCommandType.chatInput,
                              );
                            }
                          }
                        }
                      : null,
                );

                final descriptionField = TextFormField(
                  autocorrect: false,
                  maxLength: 100,
                  maxLines: 3,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  validator: (value) {
                    if (!_descriptionRequired) {
                      if (value != null && value.length > 100) {
                        return context.tr.command_description_length;
                      }
                      return null;
                    }
                    if (value == null || value.isEmpty) {
                      return context.tr.command_description_required;
                    }
                    if (value.length > 100) {
                      return context.tr.command_description_length;
                    }
                    return null;
                  },
                  initialValue: widget.commandDescription,
                  decoration: InputDecoration(
                    labelText: _descriptionRequired
                        ? requiredFieldLabel(context.tr.common_description)
                        : context.tr.common_description,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: widget.onDescriptionChanged,
                );

                final aliasesField = TextFormField(
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
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isLegacyCommand) ...[
                      nameField,
                      const SizedBox(height: 12),
                      aliasesField,
                      if (widget.showDescriptionField) ...[
                        const SizedBox(height: 12),
                        descriptionField,
                      ],
                    ] else if (isWide && widget.showDescriptionField)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: nameField),
                          const SizedBox(width: 12),
                          Expanded(child: descriptionField),
                        ],
                      )
                    else ...[
                      nameField,
                      if (widget.showDescriptionField) ...[
                        const SizedBox(height: 12),
                        descriptionField,
                      ],
                    ],
                    const SizedBox(height: 12),
                    commandTypeField,
                    if (_canUseAwaitedPreset) ...[
                      const SizedBox(height: 12),
                      _buildAwaitedPresetCard(),
                    ],
                    if (!widget.canEditCommandType) ...[
                      const SizedBox(height: 6),
                      Text(
                        context.tr.command_type_locked,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr.local_command_title),
                      subtitle: Text(
                        _awaitedPresetEnabled
                            ? context.tr.local_command_awaited_desc
                            : context.tr.local_command_desc,
                      ),
                      value: widget.localOnlyCommand,
                      onChanged: _awaitedPresetEnabled || widget.isLegacyCommand
                          ? null
                          : widget.onLocalOnlyCommandChanged,
                    ),
                    if (!widget.isLegacyCommand) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.tr.command_integration_label,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.integrationTypes.contains(
                                  ApplicationIntegrationType.guildInstall,
                                ),
                                onChanged: (value) {
                                  final newTypes =
                                      List<ApplicationIntegrationType>.from(
                                        widget.integrationTypes,
                                      );
                                  if (value == true) {
                                    newTypes.add(
                                      ApplicationIntegrationType.guildInstall,
                                    );
                                  } else {
                                    newTypes.remove(
                                      ApplicationIntegrationType.guildInstall,
                                    );
                                  }
                                  widget.onIntegrationTypesChanged(newTypes);
                                },
                              ),
                              Text(context.tr.command_integration_guild),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.integrationTypes.contains(
                                  ApplicationIntegrationType.userInstall,
                                ),
                                onChanged: (value) {
                                  final newTypes =
                                      List<ApplicationIntegrationType>.from(
                                        widget.integrationTypes,
                                      );
                                  if (value == true) {
                                    newTypes.add(
                                      ApplicationIntegrationType.userInstall,
                                    );
                                  } else {
                                    newTypes.remove(
                                      ApplicationIntegrationType.userInstall,
                                    );
                                  }
                                  widget.onIntegrationTypesChanged(newTypes);
                                },
                              ),
                              Text(context.tr.command_integration_user),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr.command_scope_label,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.start,
                        spacing: 20,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.contexts.contains(
                                  InteractionContextType.guild,
                                ),
                                onChanged: (value) {
                                  final newContexts =
                                      List<InteractionContextType>.from(
                                        widget.contexts,
                                      );
                                  if (value == true) {
                                    newContexts.add(
                                      InteractionContextType.guild,
                                    );
                                  } else {
                                    newContexts.remove(
                                      InteractionContextType.guild,
                                    );
                                  }
                                  widget.onContextsChanged(newContexts);
                                },
                              ),
                              Text(context.tr.command_context_guild),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.contexts.contains(
                                  InteractionContextType.botDm,
                                ),
                                onChanged: (value) {
                                  final newContexts =
                                      List<InteractionContextType>.from(
                                        widget.contexts,
                                      );
                                  if (value == true) {
                                    newContexts.add(
                                      InteractionContextType.botDm,
                                    );
                                  } else {
                                    newContexts.remove(
                                      InteractionContextType.botDm,
                                    );
                                  }
                                  widget.onContextsChanged(newContexts);
                                },
                              ),
                              Text(context.tr.command_context_bot_dm),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: widget.contexts.contains(
                                  InteractionContextType.privateChannel,
                                ),
                                onChanged: (value) {
                                  final newContexts =
                                      List<InteractionContextType>.from(
                                        widget.contexts,
                                      );
                                  if (value == true) {
                                    newContexts.add(
                                      InteractionContextType.privateChannel,
                                    );
                                  } else {
                                    newContexts.remove(
                                      InteractionContextType.privateChannel,
                                    );
                                  }
                                  widget.onContextsChanged(newContexts);
                                },
                              ),
                              Text(context.tr.command_context_group_dm),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr.command_permissions_label,
                        style: TextStyle(fontSize: 12, color: AppTheme.grey),
                      ),
                      const SizedBox(height: 8),
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                        childrenPadding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        title: Text(context.tr.command_permissions_title),
                        subtitle: Text(
                          _selectedPermissionOffsets.isEmpty
                              ? context.tr.command_permissions_none
                              : context.tr.command_permissions_count(
                                  _selectedPermissionOffsets.length,
                                ),
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: selectedNames
                                  .map((name) => Chip(label: Text(name)))
                                  .toList(),
                            ),
                          ),
                          if (selectedNames.isNotEmpty)
                            const SizedBox(height: 8),
                          ..._permissionItems.map((item) {
                            final isSelected = _selectedPermissionOffsets
                                .contains(item.offset);
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              value: isSelected,
                              title: Text(item.label),
                              subtitle: Text(
                                'Bit ${item.offset}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              onChanged: (checked) {
                                _togglePermission(item.offset, checked == true);
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          }),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: _clearPermissions,
                                icon: const AppIcon.fromMaterial(Icons.clear),
                                label: Text(context.tr.common_clear),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        key: ValueKey('permissions_bitfield_$computedBitfield'),
                        initialValue: computedBitfield.isEmpty
                            ? '0'
                            : computedBitfield,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: context.tr.command_permissions_bitfield,
                          border: const OutlineInputBorder(),
                          helperText:
                              context.tr.command_permissions_bitfield_helper,
                        ),
                      ),
                      if (_unknownBits != BigInt.zero) ...[
                        const SizedBox(height: 6),
                        Text(
                          context.tr.command_permissions_unknown_bits(
                            _unknownBits.toString(),
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                      if (_selectedPermissionOffsets.contains(3)) ...[
                        const SizedBox(height: 6),
                        Text(
                          context.tr.command_permissions_admin_warning,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        context.tr.command_permissions_tip,
                        style: TextStyle(fontSize: 11, color: AppTheme.grey),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem {
  final int offset;
  final String label;

  const _PermissionItem(this.offset, this.label);
}
