import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:flutter/material.dart';
import 'package:nyxx/nyxx.dart' hide Builder;

import 'scratch_block.dart';
import 'scratch_block_palette.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Describes what the command listens for.
enum CommandEntryPointType {
  /// Slash command interaction (Discord Application Command).
  interaction,

  /// Legacy prefix-based message command.
  message,
}

/// Associe chaque mot déclencheur des commandes Message Texte [commands] au
/// nom de la commande qui le porte (nom effectif puis alias).
///
/// La commande d'identifiant [excludeId] est ignorée : un alias ne doit pas
/// être signalé en collision avec sa propre commande. Le premier porteur d'un
/// déclencheur gagne (ordre de [commands]).
Map<String, String> legacyTriggerOwners(
  List<Map<String, dynamic>> commands, {
  String? excludeId,
}) {
  final owners = <String, String>{};
  for (final command in commands) {
    final id = (command['id'] ?? '').toString();
    if (excludeId != null && id == excludeId) {
      continue;
    }
    final name = (command['name'] ?? '').toString().trim();
    for (final trigger in legacyCommandTriggerNames(command)) {
      owners.putIfAbsent(trigger, () => name);
    }
  }
  return owners;
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
    // Command type (Slash, Legacy, User, Message)
    this.commandType = ApplicationCommandType.chatInput,
    this.onCommandTypeChanged,
    this.canEditCommandType = true,
    // Legacy prefix options
    this.legacyModeEnabled = false,
    this.onLegacyModeChanged,
    this.legacyPrefixOverride = '',
    this.onLegacyPrefixOverrideChanged,
    this.legacyAliases = const <String>[],
    this.onLegacyAliasesChanged,
    this.legacyAliasOwners = const <String, String>{},
    this.legacyResponseTarget = 'reply',
    this.onLegacyResponseTargetChanged,
    // Execution mode
    this.executionMode = 'workflow',
    this.onExecutionModeChanged,
    this.showWorkflowMode = true,
    this.showBdfdMode = true,
    this.showJavascriptMode = false,
    this.commandName,
    this.onOpenSettings,
  });

  final String? commandName;
  final VoidCallback? onOpenSettings;

  final CommandEntryPointType entryPointType;
  final ValueChanged<CommandEntryPointType> onEntryPointTypeChanged;

  final ApplicationCommandType commandType;
  final ValueChanged<ApplicationCommandType>? onCommandTypeChanged;
  final bool canEditCommandType;

  final bool legacyModeEnabled;
  final ValueChanged<bool>? onLegacyModeChanged;
  final String legacyPrefixOverride;
  final ValueChanged<String>? onLegacyPrefixOverrideChanged;

  /// Alias (mots déclencheurs supplémentaires) de la commande Message Texte.
  final List<String> legacyAliases;

  /// Notifié avec la liste normalisée après chaque ajout ou retrait d'alias.
  final ValueChanged<List<String>>? onLegacyAliasesChanged;

  /// Mots déclencheurs déjà portés par les AUTRES commandes Message Texte du
  /// bot (déclencheur → nom de la commande). Sert uniquement à afficher un
  /// avertissement de collision non bloquant.
  final Map<String, String> legacyAliasOwners;

  final String legacyResponseTarget;
  final ValueChanged<String>? onLegacyResponseTargetChanged;

  /// `'workflow'` for visual blocks, `'bdfd_script'` for BDFD script, `'javascript'` for JS.
  final String executionMode;
  final ValueChanged<String>? onExecutionModeChanged;
  final bool showWorkflowMode;
  final bool showBdfdMode;
  final bool showJavascriptMode;

  @override
  State<EntryPointBlock> createState() => _EntryPointBlockState();
}

class _EntryPointBlockState extends State<EntryPointBlock> {
  bool _collapsed = false;
  bool _legacyExpanded = false;

  /// Champ de saisie du prochain alias à ajouter.
  late final TextEditingController _aliasController;

  /// Message d'erreur transitoire (alias déjà présent dans la liste).
  String? _aliasError;

  @override
  void initState() {
    super.initState();
    _aliasController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant EntryPointBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.legacyAliases != widget.legacyAliases) {
      // Liste remplacée par le parent : l'erreur de saisie n'est plus
      // forcément d'actualité.
      _aliasError = null;
    }
  }

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  /// Alias affichés (normalisés) de la commande.
  List<String> get _aliases =>
      normalizeLegacyCommandAliases(widget.legacyAliases);

  /// Vrai si [candidate] désigne déjà un alias de [aliases], en comparant les
  /// mots déclencheurs nettoyés (`!`/`{$t}` ignorés, casse repliée).
  bool _isAliasDuplicate(String candidate, List<String> aliases) {
    final trigger = cleanLegacyCommandTriggerName(candidate);
    return aliases.any(
      (alias) => cleanLegacyCommandTriggerName(alias) == trigger,
    );
  }

  /// Ajoute l'alias tapé à la liste, ou affiche pourquoi il est refusé.
  ///
  /// Retourne `true` quand le champ de saisie peut être vidé.
  bool _appendAlias(String raw) {
    final candidate = normalizeLegacyCommandAliases(<String>[raw]);
    if (candidate.isEmpty) {
      // Entrée vide ou invalide (espace interne) : aucun alias à ajouter.
      if (_aliasError != null) {
        setState(() => _aliasError = null);
      }
      return true;
    }
    if (_isAliasDuplicate(candidate.single, _aliases)) {
      setState(() => _aliasError = context.tr.command_alias_duplicate);
      return false;
    }
    setState(() => _aliasError = null);
    widget.onLegacyAliasesChanged?.call(
      normalizeLegacyCommandAliases(<String>[..._aliases, ...candidate]),
    );
    return true;
  }

  /// Ajout par Entrée (ou validation du clavier).
  void _commitAliasInput() {
    if (_aliasController.text.trim().isEmpty) {
      return;
    }
    if (_appendAlias(_aliasController.text)) {
      _aliasController.clear();
    }
  }

  /// Ajout par virgule : tous les fragments terminés sont ajoutés, le dernier
  /// (encore en cours de saisie) reste dans le champ.
  void _onAliasInputChanged(String raw) {
    if (!raw.contains(',')) {
      return;
    }
    final parts = raw.split(',');
    final remainder = parts.removeLast();
    // Les fragments sont fusionnés localement puis remontés en UNE mise à
    // jour : tant que le parent n'a pas reconstruit le widget, `_aliases` ne
    // reflète pas encore les ajouts précédents.
    final merged = <String>[..._aliases];
    var hasNewAlias = false;
    var hasDuplicate = false;
    for (final part in parts) {
      final candidate = normalizeLegacyCommandAliases(<String>[part]);
      if (candidate.isEmpty) {
        continue;
      }
      if (_isAliasDuplicate(candidate.single, merged)) {
        hasDuplicate = true;
        continue;
      }
      merged.add(candidate.single);
      hasNewAlias = true;
    }
    if (hasNewAlias) {
      setState(() => _aliasError = null);
      widget.onLegacyAliasesChanged?.call(
        normalizeLegacyCommandAliases(merged),
      );
    } else if (hasDuplicate) {
      setState(() => _aliasError = context.tr.command_alias_duplicate);
    }
    _aliasController.value = TextEditingValue(
      text: remainder,
      selection: TextSelection.collapsed(offset: remainder.length),
    );
  }

  /// Retire un alias de la liste (croix de la chip).
  void _removeAlias(String alias) {
    final trigger = cleanLegacyCommandTriggerName(alias);
    final updated = _aliases
        .where(
          (candidate) => cleanLegacyCommandTriggerName(candidate) != trigger,
        )
        .toList(growable: false);
    setState(() => _aliasError = null);
    widget.onLegacyAliasesChanged?.call(updated);
  }

  /// Étiquette affichée pour une chip d'alias : `!mot`.
  String _aliasTriggerLabel(String alias) => '!$alias';

  String _commandTypeSegmentValue() {
    if (widget.legacyModeEnabled) return 'legacy';
    switch (widget.commandType) {
      case ApplicationCommandType.user:
        return 'user';
      case ApplicationCommandType.message:
        return 'message';
      case ApplicationCommandType.chatInput:
      default:
        return 'slash';
    }
  }

  void _onTypeSelected(String selected) {
    if (selected == 'legacy') {
      widget.onLegacyModeChanged?.call(true);
      widget.onCommandTypeChanged?.call(ApplicationCommandType.chatInput);
      widget.onEntryPointTypeChanged(CommandEntryPointType.message);
    } else {
      widget.onLegacyModeChanged?.call(false);
      final newType = selected == 'user'
          ? ApplicationCommandType.user
          : selected == 'message'
          ? ApplicationCommandType.message
          : ApplicationCommandType.chatInput;
      widget.onCommandTypeChanged?.call(newType);
      widget.onEntryPointTypeChanged(CommandEntryPointType.interaction);
    }
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

  String _typeBadgeLabel() {
    switch (_commandTypeSegmentValue()) {
      case 'slash':
        return context.tr.scratch_meta_type_slash;
      case 'legacy':
        return context.tr.scratch_meta_type_prefix;
      case 'user':
        return context.tr.scratch_meta_type_user;
      case 'message':
        return context.tr.scratch_meta_type_message;
      default:
        return context.tr.scratch_block_required;
    }
  }

  @override
  Widget build(BuildContext context) {
    final typeVal = _commandTypeSegmentValue();
    final isLegacy = typeVal == 'legacy';
    final colorScheme = Theme.of(context).colorScheme;
    final selectorStyle = SegmentedButton.styleFrom(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurfaceVariant,
      selectedBackgroundColor: Color.alphaBlend(
        colorScheme.primary.withValues(alpha: 0.12),
        colorScheme.surfaceContainerLow,
      ),
      selectedForegroundColor: colorScheme.onSurface,
      side: BorderSide(color: colorScheme.outlineVariant),
    );
    final cmdName = widget.commandName?.trim();
    final prefix = typeVal == 'slash' ? '/' : (typeVal == 'legacy' ? '!' : '');
    // Le titre résume les mots déclencheurs : `!nom, !alias1, !alias2…`.
    final triggerLabel = <String>[
      if (cmdName != null && cmdName.isNotEmpty) '$prefix$cmdName',
      if (isLegacy)
        for (final alias in normalizeLegacyCommandAliases(widget.legacyAliases))
          '!$alias',
    ].join(', ');
    final blockTitle = triggerLabel.isEmpty
        ? context.tr.scratch_block_entry_point
        : '${context.tr.scratch_block_entry_point} ($triggerLabel)';

    return ScratchBlock(
      color: getCategoryColor('EntryPoint'),
      title: blockTitle,
      icon: Icons.play_circle_outline,
      required: true,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      badge: ScratchBlockBadge(
        label: _typeBadgeLabel(),
        color: getCategoryColor('EntryPoint'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.onOpenSettings != null) ...[
            FilledButton.tonalIcon(
              onPressed: widget.onOpenSettings,
              icon: const AppIcon.fromMaterial(Icons.tune_rounded, size: 16),
              label: Text(
                (cmdName != null && cmdName.isNotEmpty)
                    ? '${context.tr.edit_shell_command_settings} ($prefix$cmdName)'
                    : context.tr.edit_shell_command_settings,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 38),
                backgroundColor: colorScheme.surfaceContainerHighest,
                foregroundColor: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          // ── Entry point type selector (Slash, Prefix, User, Message) ──
          Text(
            context.tr.scratch_entry_point_listen,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 460;
              return SegmentedButton<String>(
                style: selectorStyle,
                segments: [
                  ButtonSegment(
                    value: 'slash',
                    label: compact
                        ? const SizedBox.shrink()
                        : Text(context.tr.scratch_meta_type_slash),
                    icon: const AppIcon.fromMaterial(Icons.terminal, size: 18),
                    tooltip: context.tr.scratch_meta_type_slash,
                  ),
                  ButtonSegment(
                    value: 'legacy',
                    label: compact
                        ? const SizedBox.shrink()
                        : Text(context.tr.scratch_entry_message),
                    icon: const AppIcon.fromMaterial(
                      Icons.textsms_outlined,
                      size: 18,
                    ),
                    tooltip: context.tr.scratch_meta_type_prefix,
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
                    tooltip: context.tr.scratch_meta_type_user,
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
                    tooltip: context.tr.scratch_meta_type_message,
                  ),
                ],
                selected: {typeVal},
                onSelectionChanged: widget.canEditCommandType
                    ? (selection) => _onTypeSelected(selection.first)
                    : null,
              );
            },
          ),
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

          const SizedBox(height: 12),

          // ── Execution mode selector ──
          if (widget.onExecutionModeChanged != null) ...[
            Text(
              context.tr.scratch_execution_mode,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final segments = <ButtonSegment<String>>[];
                if (widget.showWorkflowMode) {
                  segments.add(
                    ButtonSegment<String>(
                      value: 'workflow',
                      label: Text(context.tr.scratch_mode_blocks),
                      icon: const AppIcon.fromMaterial(Icons.view_agenda),
                    ),
                  );
                }
                if (widget.showBdfdMode) {
                  segments.add(
                    ButtonSegment<String>(
                      value: 'bdfd_script',
                      label: Text(context.tr.scratch_mode_bdfd),
                      icon: const AppIcon.fromMaterial(Icons.code),
                    ),
                  );
                }
                if (widget.showJavascriptMode) {
                  segments.add(
                    ButtonSegment<String>(
                      value: 'javascript',
                      label: Text(context.tr.cmd_execution_mode_javascript),
                      icon: const AppIcon.fromMaterial(Icons.code),
                    ),
                  );
                }
                if (segments.isEmpty) {
                  return const SizedBox.shrink();
                }
                final selectedValue =
                    segments.any(
                      (segment) => segment.value == widget.executionMode,
                    )
                    ? widget.executionMode
                    : segments.first.value;
                return SegmentedButton<String>(
                  style: selectorStyle,
                  segments: segments,
                  selected: <String>{selectedValue},
                  onSelectionChanged: (selection) {
                    widget.onExecutionModeChanged!(selection.first);
                  },
                );
              },
            ),
            const SizedBox(height: 12),
          ],

          // ── Legacy prefix config (expandable) ──
          if (isLegacy ||
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
                AppIcon.fromMaterial(
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
            if (widget.onLegacyAliasesChanged != null)
              _buildAliasesEditor(colorScheme),
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

  /// Éditeur des alias « Message Texte » : saisie, chips supprimables,
  /// messages d'aide/erreur/limite et avertissement de collision non bloquant.
  ///
  /// Le champ accepte plusieurs mots séparés par des virgules ; les entrées
  /// sont nettoyées par [normalizeLegacyCommandAliases] afin de rester
  /// cohérentes avec le moteur (minuscules, préfixe `!` retiré, doublons et
  /// espaces internes refusés, limite de [kMaxLegacyCommandAliases] alias).
  Widget _buildAliasesEditor(ColorScheme colorScheme) {
    final aliases = _aliases;
    final isFull = aliases.length >= kMaxLegacyCommandAliases;

    // Avertissement purement informatif : un alias déjà porté par une AUTRE
    // commande Message Texte du bot ne déclenchera jamais celle-ci, mais la
    // sauvegarde n'est jamais bloquée pour autant.
    final collisions = <String, String>{};
    for (final alias in aliases) {
      final owner =
          widget.legacyAliasOwners[cleanLegacyCommandTriggerName(alias)];
      if (owner != null && owner.isNotEmpty) {
        collisions[alias] = owner;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _aliasController,
            enabled: !isFull,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _commitAliasInput(),
            onChanged: _onAliasInputChanged,
            decoration: InputDecoration(
              labelText: context.tr.command_alias_label,
              hintText: context.tr.command_alias_hint,
              border: const OutlineInputBorder(),
            ),
          ),
          if (aliases.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final alias in aliases)
                  InputChip(
                    label: Text(
                      _aliasTriggerLabel(alias),
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    deleteIcon: const AppIcon.fromMaterial(
                      Icons.close,
                      size: 16,
                    ),
                    onDeleted: () => _removeAlias(alias),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            context.tr.command_alias_help,
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
          if (_aliasError != null) ...[
            const SizedBox(height: 4),
            Text(
              _aliasError!,
              style: TextStyle(fontSize: 11.5, color: colorScheme.error),
            ),
          ],
          if (isFull) ...[
            const SizedBox(height: 4),
            Text(
              context.tr.command_alias_limit(kMaxLegacyCommandAliases),
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          for (final collision in collisions.entries) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIcon.fromMaterial(
                  Icons.warning_amber_rounded,
                  size: 15,
                  color: AppTheme.warning,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_aliasTriggerLabel(collision.key)} · '
                    '${context.tr.command_alias_collision(collision.value)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.warning,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
    this.customIdFilter = '',
    this.onCustomIdFilterChanged,
    this.flat = false,
    this.executionMode = 'workflow',
    this.onExecutionModeChanged,
    this.showJavascriptMode = false,
  });

  /// Whether to render without card borders/margins and colored header bar.
  final bool flat;

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

  final String customIdFilter;
  final ValueChanged<String>? onCustomIdFilterChanged;

  /// `'workflow'` for visual blocks, `'javascript'` for JS scripts.
  final String executionMode;
  final ValueChanged<String>? onExecutionModeChanged;
  final bool showJavascriptMode;

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
      flat: widget.flat,
      color: getCategoryColor('EntryPoint'),
      title: isEvent
          ? context.tr.scratch_entry_event_trigger
          : context.tr.scratch_entry_function,
      icon: isEvent ? Icons.flash_on : Icons.play_arrow,
      required: true,
      collapsed: widget.flat ? false : _collapsed,
      onToggleCollapse: widget.flat
          ? null
          : () => setState(() => _collapsed = !_collapsed),
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
          initialValue: widget.selectedCategory.isNotEmpty
              ? widget.selectedCategory
              : null,
          decoration: InputDecoration(
            labelText: context.tr.scratch_event_category,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: widget.eventCategories
              .map((cat) {
                final label = widget.eventCategoryLabel != null
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
          isExpanded: true,
          initialValue: widget.selectedEvent.isNotEmpty
              ? widget.selectedEvent
              : null,
          decoration: InputDecoration(
            labelText: context.tr.scratch_event_name,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          items: widget.eventDefinitions
              .map((def) {
                return DropdownMenuItem(
                  value: def.event,
                  child: Text(def.label, overflow: TextOverflow.ellipsis),
                );
              })
              .toList(growable: false),
          onChanged: (value) {
            if (value != null) widget.onEventChanged?.call(value);
          },
        ),

        // ── Custom ID filter ──
        if (widget.selectedEvent == 'interactionCreate') ...[
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.customIdFilter,
            decoration: InputDecoration(
              labelText: context.tr.scratch_custom_id_filter_label,
              hintText: context.tr.scratch_custom_id_filter_hint,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: widget.onCustomIdFilterChanged,
          ),
        ],

        if (widget.onExecutionModeChanged != null &&
            widget.showJavascriptMode) ...[
          const SizedBox(height: 12),
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
                icon: const AppIcon.fromMaterial(Icons.view_agenda),
              ),
              ButtonSegment<String>(
                value: 'javascript',
                label: Text(context.tr.cmd_execution_mode_javascript),
                icon: const AppIcon.fromMaterial(Icons.code),
              ),
            ],
            selected: <String>{
              widget.executionMode == 'javascript' ? 'javascript' : 'workflow',
            },
            onSelectionChanged: (selection) {
              widget.onExecutionModeChanged!(selection.first);
            },
          ),
        ],

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
