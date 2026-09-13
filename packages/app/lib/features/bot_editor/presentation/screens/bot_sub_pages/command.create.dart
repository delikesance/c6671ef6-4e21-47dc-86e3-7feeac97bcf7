import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_validation.dart';
import 'package:bot_creator/features/documentation/documentation_navigation.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart'
    show ActionItem;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart'
    show ActionsBuilderPage;
import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/bot_editor/logic/app_emoji_api.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_command_rules.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_command_validation_messages.dart';
import 'package:bot_creator/features/bot_editor/logic/command_variable_catalog.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bdfd_editor_page.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/js_editor_page.dart';

import 'package:bot_creator/features/bot_editor/presentation/widgets/option_widget.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/command_create_cards/basic_info_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/command_create_cards/actions_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/metadata_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_graph_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_models.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/mobile_keyboard_accessory_bar.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator_shared/utils/variable_catalog.dart'
    show inferCategory;
import 'package:bot_creator/features/bot_editor/logic/command_editor_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart' hide ButtonStyle;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

part 'command.create.variable_suggestions.dart';
part 'command.create.serialization.dart';
part 'command.create.edit_shell.dart';
part 'command.create.workflow.dart';
part 'command.create.validation.dart';
part 'command.create.wizard.dart';
part 'command.create.block_editor.dart';
part 'command.create.bdfd.dart';
part 'command.create.javascript.dart';

/// Snapshot of editor body fields used by Selector for fine-grained rebuilds.
class _EditorBodySnapshot {
  const _EditorBodySnapshot({
    required this.isLoading,
    required this.isDataIncomplete,
    required this.commandName,
    required this.commandDescription,
    required this.storageId,
  });

  final bool isLoading;
  final bool isDataIncomplete;
  final String commandName;
  final String commandDescription;
  final String? storageId;
}

class CommandCreatePage extends StatefulWidget {
  final NyxxRest? client;
  final String? botId;
  final Snowflake id;
  final String? localCommandId;
  final String? prefillName;
  const CommandCreatePage({
    super.key,
    this.client,
    this.botId,
    this.id = Snowflake.zero,
    this.localCommandId,
    this.prefillName,
  });

  @override
  State<CommandCreatePage> createState() => _CommandCreatePageState();
}

bool get _isDesktop =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS);

class _CommandCreatePageState extends State<CommandCreatePage> {
  static const Uuid _uuid = Uuid();
  static const String _editorModeSimple = 'simple';
  static const String _editorModeAdvanced = 'advanced';
  static const String _executionModeWorkflow = 'workflow';
  static const String _executionModeBdfdScript = 'bdfd_script';
  static const String _executionModeJavascript = 'javascript';
  static const String _rootWorkflowRoute = '__root__';
  static const int _defaultCommandNameMaxLength = 32;
  static const int _localLegacyCommandNameMaxLength = 256;
  static final RegExp _awaitedCommandTriggerPattern = RegExp(
    r'^\$awaitedcommand\[(.+?);(.*)\]$',
    caseSensitive: false,
  );
  static final RegExp _awaitedCommandErrorTriggerPattern = RegExp(
    r'^\$awaitedcommanderror\[(.+?)\]$',
    caseSensitive: false,
  );

  late final CommandEditorNotifier _editorNotifier;

  String _commandName = "";
  String _commandDescription = "";
  ApplicationCommandType _commandType = ApplicationCommandType.chatInput;
  List<CommandOptionBuilder> _options = [];
  List<Map<String, dynamic>> _actions = [];
  Set<String> _persistedGlobalVariableNames = <String>{};
  Set<String> _scopedVariableSuggestionNames = {
    'guild.key',
    'user.key',
    'channel.key',
    'guildMember.key',
    'message.key',
  };
  bool _isLoading = true;
  List<AppEmoji> _appEmojis = [];

  /// True when editing an existing command that couldn't be fully loaded
  /// (client offline AND no local `data` block). Disables editing UI.
  bool _isDataIncomplete = false;

  /// True when the command has a non-zero id but doesn't exist on Discord
  /// (e.g. template commands saved locally). Saving will create instead of update.
  bool _isLocalOnlyCommand = false;
  List<ApplicationIntegrationType> _integrationTypes = [
    ApplicationIntegrationType.guildInstall,
  ];
  List<InteractionContextType> _contexts = [InteractionContextType.guild];
  String _defaultMemberPermissions = '';
  String _editorMode = _editorModeSimple;
  String _executionMode = _executionModeWorkflow;
  String _bdfdScriptContent = '';
  String _jsScriptContent = '';
  final TextEditingController _bdfdScriptController = TextEditingController();
  final TextEditingController _jsScriptController = TextEditingController();
  String _botRuntimeEngine = runtimeEngineDart;
  final BdfdCompiler _bdfdCompiler = BdfdCompiler();
  BdfdCompileResult? _bdfdCompileResult;
  bool _legacyModeEnabled = false;
  bool _localOnlyCommand = false;
  String _folder = '';
  final TextEditingController _folderController = TextEditingController();
  List<String> _existingFolders = const <String>[];
  String _legacyPrefixOverride = '';

  /// Alias (mots déclencheurs supplémentaires) de la commande message legacy.
  List<String> _legacyAliases = const <String>[];

  /// Mots déclencheurs déjà portés par les autres commandes Message Texte du
  /// bot (déclencheur → nom de la commande), utilisés par [EntryPointBlock]
  /// pour afficher un avertissement de collision non bloquant.
  Map<String, String> _legacyAliasOwners = const <String, String>{};
  String _legacyResponseTarget = 'reply';
  Map<String, Map<String, dynamic>> _subcommandWorkflows =
      <String, Map<String, dynamic>>{};
  String _activeSubcommandRoute = _rootWorkflowRoute;
  int _currentEditorStep = 0;

  /// View layout mode on Desktop: 'linear' (Scratch blocks) or 'blueprint' (Unreal node graph).
  String _desktopViewMode = 'linear';

  /// Persisted node coordinates on the 2D Blueprint canvas
  final Map<String, Offset> _blueprintNodePositions = <String, Offset>{};

  /// Set of connection IDs severed by the user in Blueprint mode
  final Set<String> _blueprintSeveredConnections = <String>{};

  bool get _isSimpleMode => false;

  bool get _isBdfdScriptMode => _executionMode == _executionModeBdfdScript;

  bool get _isJavascriptMode => _executionMode == _executionModeJavascript;

  bool get _supportsJavascriptMode =>
      _botRuntimeEngine == runtimeEngineJavascript;

  bool get _isJavascriptOnlyBot => _botRuntimeEngine == runtimeEngineJavascript;

  List<BdfdCompileDiagnostic> get _bdfdDiagnostics =>
      _bdfdCompileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get _hasBdfdCompileErrors => _bdfdDiagnostics.any(
    (diagnostic) => diagnostic.severity == BdfdCompileDiagnosticSeverity.error,
  );

  String _normalizeExecutionMode(Object? raw) {
    if (_botRuntimeEngine != runtimeEngineJavascript) {
      final value = (raw ?? _executionModeWorkflow)
          .toString()
          .trim()
          .toLowerCase();
      if (value == _executionModeBdfdScript) return _executionModeBdfdScript;
      return _executionModeWorkflow;
    }
    return _executionModeJavascript;
  }

  Future<void> _loadRuntimeContext() async {
    var botRuntimeEngine = runtimeEngineDart;

    final botId = _botIdForConfig;
    if (botId != null) {
      botRuntimeEngine = await getBotRuntimeEngine(botId);
    }

    if (!mounted) return;
    _applyStateUpdate(() {
      _botRuntimeEngine = botRuntimeEngine;
      if (_botRuntimeEngine == runtimeEngineJavascript) {
        _executionMode = _executionModeJavascript;
      } else if (_executionMode == _executionModeJavascript) {
        _executionMode = _executionModeWorkflow;
      }
    });
  }

  void _promoteSimpleModeDraftIfNeeded(String persistedEditorMode) {
    _editorMode = _editorModeAdvanced;
  }

  void _refreshBdfdCompileResult({bool notify = true}) {
    final source = _bdfdScriptController.text;
    final nextResult = _bdfdCompiler.compile(source);
    if (!notify || !mounted) {
      _bdfdScriptContent = source;
      _bdfdCompileResult = nextResult;
      return;
    }

    _applyStateUpdate(() {
      _bdfdScriptContent = source;
      _bdfdCompileResult = nextResult;
    });
  }

  String _formatBdfdDiagnostic(BdfdCompileDiagnostic diagnostic) {
    final location = (diagnostic.line != null && diagnostic.column != null)
        ? 'L${diagnostic.line}:C${diagnostic.column} '
        : '';
    return '$location${diagnostic.message}';
  }

  bool get _supportsCommandDescription =>
      _commandType == ApplicationCommandType.chatInput;

  bool get _supportsCommandOptions =>
      _commandType == ApplicationCommandType.chatInput;

  bool get _supportsSimpleMode => false;

  bool get _allowsInternalLegacyCallbackNames =>
      _commandType == ApplicationCommandType.chatInput &&
      _legacyModeEnabled &&
      _localOnlyCommand;

  int get _commandNameMaxLength => _allowsInternalLegacyCallbackNames
      ? _localLegacyCommandNameMaxLength
      : _defaultCommandNameMaxLength;

  bool _looksLikeAwaitedCallbackTrigger(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.startsWith(r'$awaitedcommand[') ||
        normalized.startsWith(r'$awaitedcommanderror[');
  }

  bool _isAwaitedCallbackTrigger(String value) {
    final normalized = value.trim();
    return _awaitedCommandTriggerPattern.hasMatch(normalized) ||
        _awaitedCommandErrorTriggerPattern.hasMatch(normalized);
  }

  bool get _isAwaitedCallbackCommand => _isAwaitedCallbackTrigger(_commandName);

  bool get _requiresCommandDescription =>
      _supportsCommandDescription &&
      !_legacyModeEnabled &&
      !_isAwaitedCallbackCommand;

  String get _effectiveCommandDescription =>
      _supportsCommandDescription ? _commandDescription : '';

  bool _isHierarchyOptionType(CommandOptionType type) {
    return type == CommandOptionType.subCommand ||
        type == CommandOptionType.subCommandGroup;
  }

  bool _containsHierarchyOption(List<CommandOptionBuilder> options) {
    for (final option in options) {
      if (_isHierarchyOptionType(option.type)) {
        return true;
      }
      final nested = option.options;
      if (nested != null &&
          nested.isNotEmpty &&
          _containsHierarchyOption(nested)) {
        return true;
      }
    }
    return false;
  }

  List<String> _collectSubcommandRoutes(List<CommandOptionBuilder> options) {
    final routes = <String>[];

    for (final option in options) {
      final name = option.name.trim();
      if (name.isEmpty) {
        continue;
      }

      if (option.type == CommandOptionType.subCommand) {
        routes.add(name);
        continue;
      }

      if (option.type == CommandOptionType.subCommandGroup) {
        final children = option.options ?? <CommandOptionBuilder>[];
        for (final child in children) {
          if (child.type != CommandOptionType.subCommand) {
            continue;
          }
          final childName = child.name.trim();
          if (childName.isEmpty) {
            continue;
          }
          routes.add('$name/$childName');
        }
      }
    }

    return routes;
  }

  Map<String, dynamic> _cloneJsonMap(Map<String, dynamic> source) {
    return cloneJsonMap(source);
  }

  List<Map<String, dynamic>> _cloneJsonListOfMaps(
    List<Map<String, dynamic>> source,
  ) {
    return List<Map<String, dynamic>>.from(
      (jsonDecode(jsonEncode(source)) as List).whereType<Map>().map(
        (entry) => Map<String, dynamic>.from(entry),
      ),
    );
  }

  Map<String, dynamic> _buildCurrentWorkflowPayload() {
    return {'actions': _cloneJsonListOfMaps(_actions)};
  }

  Map<String, dynamic> _buildDefaultWorkflowPayload() {
    return {'actions': <Map<String, dynamic>>[]};
  }

  void _applyWorkflowPayloadToEditor(Map<String, dynamic> payload) {
    final actions = List<Map<String, dynamic>>.from(
      (payload['actions'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    );

    _actions = actions;
  }

  Map<String, Map<String, dynamic>> _normalizeStoredSubcommandWorkflows(
    dynamic raw,
  ) {
    if (raw is! Map) {
      return <String, Map<String, dynamic>>{};
    }

    final normalized = <String, Map<String, dynamic>>{};
    raw.forEach((key, value) {
      if (value is! Map) {
        return;
      }
      final route = key.toString().trim();
      if (route.isEmpty) {
        return;
      }
      normalized[route] = Map<String, dynamic>.from(
        value.cast<String, dynamic>(),
      );
    });

    return normalized;
  }

  void _persistActiveSubcommandWorkflow() {
    if (_activeSubcommandRoute == _rootWorkflowRoute) {
      return;
    }
    if (!_subcommandWorkflows.containsKey(_activeSubcommandRoute)) {
      return;
    }

    _subcommandWorkflows[_activeSubcommandRoute] =
        _buildCurrentWorkflowPayload();
  }

  void _syncSubcommandWorkflowRoutes() {
    final routes = _collectSubcommandRoutes(_options);
    if (routes.isEmpty) {
      _subcommandWorkflows = <String, Map<String, dynamic>>{};
      _activeSubcommandRoute = _rootWorkflowRoute;
      return;
    }

    final hadExistingWorkflows = _subcommandWorkflows.isNotEmpty;
    _persistActiveSubcommandWorkflow();

    final next = <String, Map<String, dynamic>>{};
    for (final route in routes) {
      final existing = _subcommandWorkflows[route];
      if (existing != null) {
        next[route] = _cloneJsonMap(existing);
      } else {
        next[route] = (!hadExistingWorkflows && next.isEmpty)
            ? _buildCurrentWorkflowPayload()
            : _buildDefaultWorkflowPayload();
      }
    }

    _subcommandWorkflows = next;
    if (!_subcommandWorkflows.containsKey(_activeSubcommandRoute)) {
      _activeSubcommandRoute = routes.first;
    }

    final activePayload = _subcommandWorkflows[_activeSubcommandRoute];
    if (activePayload != null) {
      _applyWorkflowPayloadToEditor(activePayload);
    }
  }

  void _switchActiveSubcommandRoute(String route) {
    if (route == _activeSubcommandRoute) {
      return;
    }
    _persistActiveSubcommandWorkflow();
    _activeSubcommandRoute = route;
    final payload = _subcommandWorkflows[route];
    if (payload != null) {
      _applyWorkflowPayloadToEditor(payload);
    }
  }

  String _workflowRouteLabel(String route) {
    final parts = route.split('/');
    if (parts.length == 2) {
      return '/$_commandName ${parts[0]} ${parts[1]}';
    }
    return '/$_commandName $route';
  }

  Widget _buildLegacyModeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.legacy_prefix_mode_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr.legacy_prefix_mode_desc,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 10),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr.command_legacy_mode_title),
              subtitle: Text(context.tr.legacy_prefix_mode_subtitle),
              value: _legacyModeEnabled,
              onChanged: !_supportsCommandOptions
                  ? null
                  : (enabled) {
                      _applyStateUpdate(() {
                        _legacyModeEnabled = enabled;
                        _localOnlyCommand = enabled;
                      });
                    },
            ),
            if (_legacyModeEnabled) ...[
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _legacyPrefixOverride,
                decoration: InputDecoration(
                  labelText: context.tr.legacy_prefix_override_label,
                  hintText: context.tr.legacy_prefix_override_hint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _legacyPrefixOverride = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _legacyResponseTarget,
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
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _legacyResponseTarget = value;
                  });
                },
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.command_modal_disabled_legacy,
                style: TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubcommandWorkflowSelectorCard() {
    if (_isJavascriptOnlyBot || _subcommandWorkflows.isEmpty) {
      return const SizedBox.shrink();
    }

    final routes = _subcommandWorkflows.keys.toList(growable: false);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.command_subcommand_workflow_title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              context.tr.command_subcommand_workflow_desc,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: routes.contains(_activeSubcommandRoute)
                  ? _activeSubcommandRoute
                  : routes.first,
              decoration: InputDecoration(
                labelText: context.tr.command_target_subcommand,
                border: OutlineInputBorder(),
              ),
              items: routes
                  .map(
                    (route) => DropdownMenuItem<String>(
                      value: route,
                      child: Text(_workflowRouteLabel(route)),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _switchActiveSubcommandRoute(value);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _applyOptionsUpdate(List<CommandOptionBuilder> options) {
    _hasUnsavedChanges = true;
    _options = options;
    if (_containsHierarchyOption(_options)) {
      _editorMode = _editorModeAdvanced;
    } else if (!_supportsSimpleMode) {
      _editorMode = _editorModeAdvanced;
    } else {}
    _syncSubcommandWorkflowRoutes();
  }

  /// Parses a prefill name like "ticket new" or "ticket config new" into the
  /// proper SubCommand / SubCommandGroup structure.
  ///
  /// - 1 word  → `_commandName` only (no subcommands).
  /// - 2 words → parent command + SubCommand option.
  /// - 3 words → parent command + SubCommandGroup + SubCommand option.
  void _applyPrefillName(String raw) {
    final parts = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return;

    _commandName = parts.first;

    if (parts.length == 2) {
      // "ticket new" → parent "ticket", subCommand "new"
      final subCmd = CommandOptionBuilder(
        type: CommandOptionType.subCommand,
        name: parts[1],
        description: parts[1],
      );
      _options = [subCmd];
      _editorMode = _editorModeAdvanced;
    } else if (parts.length >= 3) {
      // "ticket config new" → parent "ticket", group "config", subCommand "new"
      final subCmd = CommandOptionBuilder(
        type: CommandOptionType.subCommand,
        name: parts[2],
        description: parts[2],
      );
      final group = CommandOptionBuilder(
        type: CommandOptionType.subCommandGroup,
        name: parts[1],
        description: parts[1],
      );
      group.options = [subCmd];
      _options = [group];
      _editorMode = _editorModeAdvanced;
    }

    // Let the sync pick up the newly created options → workflows.
    _syncSubcommandWorkflowRoutes();
  }

  CommandOptionBuilder _buildOptionFromApplicationOption(dynamic source) {
    final option = CommandOptionBuilder(
      type: source.type as CommandOptionType,
      name: source.name.toString(),
      description: source.description?.toString() ?? '',
      isRequired: source.isRequired == true,
      minValue: source.minValue as num?,
      maxValue: source.maxValue as num?,
      nameLocalizations: source.nameLocalizations as Map<Locale, String>?,
      descriptionLocalizations:
          source.descriptionLocalizations as Map<Locale, String>?,
    );
    option.hasAutocomplete = source.hasAutocomplete == true;
    if (option.hasAutocomplete == true &&
        commandOptionSupportsAutocomplete(option.type)) {
      setCommandOptionAutocompleteConfig(option, <String, dynamic>{
        'enabled': true,
        'workflow': '',
        'entryPoint': 'main',
        'arguments': <String, dynamic>{},
      });
    }

    final rawChoices = source.choices;
    if (rawChoices is List &&
        rawChoices.isNotEmpty &&
        option.hasAutocomplete != true) {
      option.choices = rawChoices
          .map(
            (choice) => CommandOptionChoiceBuilder(
              name: choice.name.toString(),
              value: choice.value,
            ),
          )
          .toList(growable: false);
    }

    final rawOptions = source.options;
    if (rawOptions is List && rawOptions.isNotEmpty) {
      option.options = rawOptions
          .map(_buildOptionFromApplicationOption)
          .toList(growable: false);
    }

    return option;
  }

  List<CommandOptionBuilder> get _effectiveOptions {
    if (!_supportsCommandOptions) {
      return <CommandOptionBuilder>[];
    }
    if (_isBdfdScriptMode) {
      return _options;
    }
    return _options;
  }

  List<Map<String, dynamic>> get _effectiveActions => _actions;

  String? get _botIdForConfig =>
      widget.client?.user.id.toString() ?? widget.botId;

  String? get _explicitLocalCommandId {
    final id = (widget.localCommandId ?? '').trim();
    return id.isEmpty ? null : id;
  }

  String? get _existingCommandStorageId {
    final localId = _explicitLocalCommandId;
    if (localId != null) {
      return localId;
    }
    if (!widget.id.isZero) {
      return widget.id.toString();
    }
    return null;
  }

  bool get _isEditingExistingCommand => _existingCommandStorageId != null;

  bool get _canToggleLegacyOnlyLocal =>
      !_isEditingExistingCommand || _isLocalOnlyCommand || _legacyModeEnabled;

  String _generateLegacyOnlyCommandId() => _uuid.v4();

  bool get _showEditShell => !_isDataIncomplete && !_isLoading;

  bool _hasUnsavedChanges = false;

  bool get _isDirty {
    if (!_showEditShell) return false;
    return _hasUnsavedChanges;
  }

  @override
  void initState() {
    super.initState();
    _editorNotifier = CommandEditorNotifier();
    if (widget.prefillName != null && widget.prefillName!.isNotEmpty) {
      _applyPrefillName(widget.prefillName!);
    }
    _bdfdScriptController.text = _bdfdScriptContent;
    _jsScriptController.text = _jsScriptContent;
    _refreshBdfdCompileResult(notify: false);
    _init();
  }

  @override
  void dispose() {
    _editorNotifier.dispose();
    _bdfdScriptController.dispose();
    _jsScriptController.dispose();
    _folderController.dispose();
    super.dispose();
  }

  Widget _buildFolderField() {
    return Autocomplete<String>(
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
        setState(() {
          _folder = selection;
          _folderController.text = selection;
        });
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
                              Icon(
                                Icons.folder_outlined,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        if (controller.text != _folderController.text) {
          controller.text = _folderController.text;
        }
        controller.addListener(() {
          if (_folderController.text != controller.text) {
            _folderController.text = controller.text;
            _folder = controller.text.trim();
          }
        });
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: context.tr.commands_folder_label,
            hintText: context.tr.commands_folder_hint,
            prefixIcon: const Icon(Icons.folder_outlined),
            suffixIcon: _existingFolders.isNotEmpty
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.folder_open),
                    tooltip: 'Dossiers existants',
                    onSelected: (String selection) {
                      setState(() {
                        controller.text = selection;
                        _folderController.text = selection;
                        _folder = selection;
                      });
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
    );
  }

  void _syncNotifier() {
    _editorNotifier.batchUpdate(
      (s) => s.copyWith(
        isLoading: _isLoading,
        isDataIncomplete: _isDataIncomplete,
        commandName: _commandName,
        commandDescription: _commandDescription,
        commandType: _commandType,
        editorMode: _editorMode,
        executionMode: _executionMode,
        legacyModeEnabled: _legacyModeEnabled,
        localOnlyCommand: _localOnlyCommand,
        folder: _folder,
      ),
    );
  }

  void _applyStateUpdate(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    _hasUnsavedChanges = true;
    setState(callback);
    _syncNotifier();
  }

  Widget _buildEditorBody({required double contentMaxWidth}) {
    return Selector<CommandEditorNotifier, _EditorBodySnapshot>(
      selector: (_, notifier) => _EditorBodySnapshot(
        isLoading: notifier.state.isLoading,
        isDataIncomplete: notifier.state.isDataIncomplete,
        commandName: notifier.state.commandName,
        commandDescription: notifier.state.commandDescription,
        storageId: _existingCommandStorageId,
      ),
      builder: (context, snap, _) {
        if (snap.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.isDataIncomplete) {
          return _buildIncompleteDataView(snap, contentMaxWidth);
        }
        return _buildBlockEditor(contentMaxWidth: contentMaxWidth);
      },
    );
  }

  Widget _buildIncompleteDataView(_EditorBodySnapshot snap, double maxWidth) {
    // Marge horizontale portée par `PageContent` (contrat commun) ; la borne
    // ci-dessous réutilise la même largeur de contenu.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.warning,
                border: Border.all(color: AppTheme.warning),
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.warning,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr.cmd_offline_incomplete_warning,
                      style: const TextStyle(
                        color: AppTheme.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.terminal),
                title: Text(
                  snap.commandName.isNotEmpty
                      ? snap.commandName
                      : (snap.storageId ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: snap.commandDescription.isNotEmpty
                    ? Text(snap.commandDescription)
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.menu_book_outlined),
                  tooltip: context.tr.cmd_show_variables,
                  onPressed: _openDocumentationCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetDirtyState() {
    _hasUnsavedChanges = false;
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_isDirty) {
      return true;
    }

    final discard = await AppTheme.showConfirmDialog(
      context,
      title: context.tr.command_unsaved_title,
      content: context.tr.command_unsaved_confirm,
      cancelLabel: context.tr.command_unsaved_keep,
      confirmLabel: context.tr.common_discard,
      isDestructive: true,
    );

    return discard;
  }

  Future<void> _saveExistingCommand() async {
    developer.log(
      '[_saveExistingCommand] invoked — commandName="$_commandName" existingId=$_existingCommandStorageId isEditing=$_isEditingExistingCommand isDirty=$_isDirty',
      name: 'CommandCreatePage',
    );
    if (!await _validateCommandInputs()) {
      developer.log(
        '[_saveExistingCommand] validation FAILED, aborting save.',
        name: 'CommandCreatePage',
      );
      return;
    }
    developer.log(
      '[_saveExistingCommand] validation passed, logging analytics and calling _updateOrCreate.',
      name: 'CommandCreatePage',
    );
    unawaited(
      AppAnalytics.logEvent(
        name: "update_command",
        parameters: {
          "command_name": _commandName,
          "command_id": _existingCommandStorageId ?? 'unknown',
        },
      ),
    );
    await _updateOrCreate();
    _hasUnsavedChanges = false;
    developer.log(
      '[_saveExistingCommand] _updateOrCreate completed.',
      name: 'CommandCreatePage',
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForCloudSync({
    required String botId,
    required String botToken,
  }) async {
    // Cloud sync is now supported on all platforms including desktop.
    developer.log(
      '[_resolveMainApiClientForCloudSync] START botId=$botId tokenPresent=${botToken.isNotEmpty}',
      name: 'CommandCreatePage',
    );
    final config = await MainApiSettingsStore.loadConfig();
    developer.log(
      '[_resolveMainApiClientForCloudSync] config loaded: isConfigured=${config.isConfigured} baseUrl=${config.isConfigured ? config.baseUrl : "(not set)"}',
      name: 'CommandCreatePage',
    );
    if (!config.isConfigured) {
      developer.log(
        '[_resolveMainApiClientForCloudSync] SKIP botId=$botId: Main API base URL is not configured.',
        name: 'CommandCreatePage',
      );
      return null;
    }

    developer.log(
      '[_resolveMainApiClientForCloudSync] loading stored session for botId=$botId',
      name: 'CommandCreatePage',
    );
    final session = await MainApiSettingsStore.loadSession();
    developer.log(
      '[_resolveMainApiClientForCloudSync] session: present=${session != null} expired=${session?.isExpired} userId=${session?.userId ?? "(none)"}',
      name: 'CommandCreatePage',
    );

    developer.log(
      '[_resolveMainApiClientForCloudSync] fetching Discord application owner metadata (tokenPresent=${botToken.isNotEmpty}) for botId=$botId',
      name: 'CommandCreatePage',
    );
    final ownerMetadata = botToken.trim().isEmpty
        ? null
        : await getDiscordApplicationOwnerMetadata(botToken);
    final ownerCandidates =
        ownerMetadata?.ownerCandidateIds ?? const <String>[];
    final sessionOwnerId = (session?.userId ?? '').trim();
    developer.log(
      '[_resolveMainApiClientForCloudSync] ownerMetadata: present=${ownerMetadata != null} candidates=$ownerCandidates sessionOwnerId="$sessionOwnerId" for botId=$botId',
      name: 'CommandCreatePage',
    );

    final hasUsableSession =
        session != null &&
        !session.isExpired &&
        (ownerCandidates.isEmpty || ownerCandidates.contains(sessionOwnerId));
    developer.log(
      '[_resolveMainApiClientForCloudSync] hasUsableSession=$hasUsableSession (sessionPresent=${session != null} sessionExpired=${session?.isExpired} ownerMatch=${ownerCandidates.isEmpty || ownerCandidates.contains(sessionOwnerId)}) for botId=$botId',
      name: 'CommandCreatePage',
    );
    if (hasUsableSession) {
      developer.log(
        '[_resolveMainApiClientForCloudSync] REUSING existing Main API session (botId=$botId owner=${sessionOwnerId.isEmpty ? "unknown" : sessionOwnerId}).',
        name: 'CommandCreatePage',
      );
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }

    if (session != null && !session.isExpired && ownerCandidates.isNotEmpty) {
      developer.log(
        '[_resolveMainApiClientForCloudSync] OWNER MISMATCH on existing session (botId=$botId sessionOwner=$sessionOwnerId expectedOneOf=${ownerCandidates.join(",")}). Will restore session from bot token.',
        name: 'CommandCreatePage',
      );
    }

    if (botToken.trim().isEmpty) {
      developer.log(
        '[_resolveMainApiClientForCloudSync] SKIP botId=$botId: no usable session and bot token is missing — cannot restore.',
        name: 'CommandCreatePage',
      );
      return null;
    }

    developer.log(
      '[_resolveMainApiClientForCloudSync] attempting exchangeDiscordBotToken for botId=$botId preferredOwnerId=${ownerMetadata?.resolveOwnerId(preferredOwnerId: session?.userId)}',
      name: 'CommandCreatePage',
    );
    try {
      final restoredSession = await MainApiClient(
        baseUrl: config.baseUrl,
      ).exchangeDiscordBotToken(botToken: botToken);
      developer.log(
        '[_resolveMainApiClientForCloudSync] exchangeDiscordBotToken OK: restoredUserId=${restoredSession.userId} isExpired=${restoredSession.isExpired} for botId=$botId',
        name: 'CommandCreatePage',
      );

      final restoredOwnerId = (restoredSession.userId ?? '').trim();
      if (ownerCandidates.isNotEmpty &&
          restoredOwnerId.isNotEmpty &&
          !ownerCandidates.contains(restoredOwnerId)) {
        developer.log(
          '[_resolveMainApiClientForCloudSync] OWNER MISMATCH after token exchange (botId=$botId restoredOwner=$restoredOwnerId expectedOneOf=${ownerCandidates.join(",")}). Aborting.',
          name: 'CommandCreatePage',
        );
        return null;
      }

      developer.log(
        '[_resolveMainApiClientForCloudSync] saving restored session and returning client (botId=$botId owner=${restoredSession.userId ?? "unknown"}).',
        name: 'CommandCreatePage',
      );
      await MainApiSettingsStore.trySaveBotTokenSession(restoredSession);
      developer.log(
        '[_resolveMainApiClientForCloudSync] session saved OK for botId=$botId.',
        name: 'CommandCreatePage',
      );

      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: restoredSession.accessToken,
      );
    } catch (error, stackTrace) {
      developer.log(
        '[_resolveMainApiClientForCloudSync] EXCEPTION during token exchange for botId=$botId: $error',
        name: 'CommandCreatePage',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<bool> _syncCommandChangesToCloud({required String botId}) async {
    // Cloud sync is now supported on all platforms including desktop.
    developer.log(
      '[_syncCommandChangesToCloud] START botId=$botId commandName="$_commandName"',
      name: 'CommandCreatePage',
    );
    try {
      developer.log(
        '[_syncCommandChangesToCloud] fetching app data for botId=$botId',
        name: 'CommandCreatePage',
      );
      final app = await appManager.getApp(botId);
      final botToken = (app['token'] ?? '').toString().trim();
      final botName = (app['name'] ?? botId).toString().trim();
      developer.log(
        '[_syncCommandChangesToCloud] app fetched — botName="$botName" tokenPresent=${botToken.isNotEmpty} tokenLength=${botToken.length}',
        name: 'CommandCreatePage',
      );

      developer.log(
        '[_syncCommandChangesToCloud] resolving Main API client for botId=$botId',
        name: 'CommandCreatePage',
      );
      final mainApiClient = await _resolveMainApiClientForCloudSync(
        botId: botId,
        botToken: botToken,
      );
      if (mainApiClient == null) {
        developer.log(
          '[_syncCommandChangesToCloud] ABORT — could not resolve a Main API client (no config, no session, or owner mismatch) for botId=$botId',
          name: 'CommandCreatePage',
        );
        return false;
      }
      developer.log(
        '[_syncCommandChangesToCloud] Main API client resolved OK for botId=$botId',
        name: 'CommandCreatePage',
      );

      developer.log(
        '[_syncCommandChangesToCloud] building bot payload for botId=$botId',
        name: 'CommandCreatePage',
      );
      final payload = await buildRemotePayload(botId);
      developer.log(
        '[_syncCommandChangesToCloud] payload built — topLevelKeys=${payload.keys.toList()} for botId=$botId',
        name: 'CommandCreatePage',
      );

      try {
        developer.log(
          '[_syncCommandChangesToCloud] calling syncBot botId=$botId botName="${botName.isEmpty ? botId : botName}"',
          name: 'CommandCreatePage',
        );
        await mainApiClient.syncBot(
          botId,
          botName.isEmpty ? botId : botName,
          payload,
        );
        developer.log(
          '[_syncCommandChangesToCloud] syncBot SUCCESS botId=$botId',
          name: 'CommandCreatePage',
        );
        return true;
      } catch (error, stackTrace) {
        developer.log(
          '[_syncCommandChangesToCloud] syncBot FAILED for botId=$botId: $error — will attempt snapshot fallback=${botToken.isNotEmpty}',
          name: 'CommandCreatePage',
          stackTrace: stackTrace,
        );
        if (botToken.isNotEmpty) {
          developer.log(
            '[_syncCommandChangesToCloud] attempting saveDiscordBotSnapshot fallback for botId=$botId',
            name: 'CommandCreatePage',
          );
          await mainApiClient.saveDiscordBotSnapshot(
            botId: botId,
            botToken: botToken,
            config: payload,
          );
          developer.log(
            '[_syncCommandChangesToCloud] saveDiscordBotSnapshot fallback SUCCESS botId=$botId',
            name: 'CommandCreatePage',
          );
          return true;
        }
        developer.log(
          '[_syncCommandChangesToCloud] no bot token for fallback snapshot, giving up for botId=$botId',
          name: 'CommandCreatePage',
        );
        return false;
      }
    } catch (error, stackTrace) {
      developer.log(
        '[_syncCommandChangesToCloud] EXCEPTION in cloud sync for botId=$botId: $error',
        name: 'CommandCreatePage',
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  void _notifyCloudSyncFailed(String botId) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr.command_cloud_sync_failed_saved),
        action: SnackBarAction(
          label: context.tr.command_cloud_sync_retry,
          onPressed: () {
            unawaited(_syncCommandChangesToCloud(botId: botId));
          },
        ),
      ),
    );
  }

  void _openDocumentationCenter() {
    openDocumentationHubForBot(
      context,
      botId: _botIdForConfig,
      initialSection: DocumentationSection.botCreatorDocs,
    );
  }

  Widget _buildCommandOptionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr.command_options_title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              _legacyModeEnabled
                  ? context.tr.command_options_legacy_params
                  : context.tr.command_options_slash_params,
              style: TextStyle(fontSize: 12, color: AppTheme.grey),
            ),
            const SizedBox(height: 12),
            OptionWidget(
              initialOptions: _options,
              botIdForConfig: _botIdForConfig,
              variableSuggestions: _actionVariableSuggestions,
              isPrefixCommand: _legacyModeEnabled,
              onChange: (options) {
                _hasUnsavedChanges = true;
                _syncNotifier();
                setState(() {
                  _applyOptionsUpdate(options);
                });
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() {});
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _init() async {
    await _loadRuntimeContext();
    await AppAnalytics.logScreenView(
      screenName: "CommandCreatePage",
      screenClass: "CommandCreatePage",
      parameters: {
        "command_id": _existingCommandStorageId ?? 'new',
        "command_name": _isEditingExistingCommand
            ? _commandName
            : "New Command",
        "is_new_command": _isEditingExistingCommand ? "false" : "true",
        "client_id": widget.client?.user.id.toString() ?? "unknown",
      },
    );

    await _refreshPersistedVariableNames();

    final botId = _botIdForConfig;
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
        // Mots déclencheurs déjà pris par les autres commandes Message Texte :
        // l'éditeur d'alias s'en sert pour son avertissement de collision
        // (jamais bloquant). La commande éditée est exclue de la carte.
        final aliasOwners = legacyTriggerOwners(
          commands,
          excludeId: _existingCommandStorageId,
        );
        _applyStateUpdate(() {
          _existingFolders = folders;
          _legacyAliasOwners = aliasOwners;
        });
      } catch (_) {}
    }

    // Load application emojis silently for autocomplete
    try {
      final bid = _botIdForConfig;
      if (bid != null) {
        final token = (await appManager.getApp(bid))['token'] as String?;
        if (token != null && token.isNotEmpty) {
          final emojis = await AppEmojiApi.listEmojis(token, bid);
          _applyStateUpdate(() => _appEmojis = emojis);
        }
      }
    } catch (_) {}

    final explicitLocalId = _explicitLocalCommandId;
    if (explicitLocalId != null) {
      final botId = _botIdForConfig;
      if (botId == null) {
        if (!mounted) {
          return;
        }
        _applyStateUpdate(() {
          _isLoading = false;
        });
        return;
      }

      final commandData = await appManager.getAppCommand(
        botId,
        explicitLocalId,
      );
      if (!mounted) {
        return;
      }
      if (commandData.isEmpty) {
        _applyStateUpdate(() {
          _isLoading = false;
          _isDataIncomplete = true;
        });
        return;
      }

      final normalized = appManager.normalizeCommandData(
        Map<String, dynamic>.from(commandData),
      );
      final normalizedData = Map<String, dynamic>.from(
        normalized['data'] ?? const {},
      );
      final executionMode = _normalizeExecutionMode(
        normalizedData['executionMode'],
      );
      final persistedEditorMode =
          (normalizedData['editorMode'] ?? _editorModeAdvanced)
              .toString()
              .toLowerCase();
      final editorMode = persistedEditorMode == _editorModeSimple
          ? _editorModeSimple
          : _editorModeAdvanced;

      _applyStateUpdate(() {
        _isLocalOnlyCommand = true;
        _commandName = (normalized['name'] ?? '').toString();
        _commandDescription = (normalized['description'] ?? '').toString();
        _folder = (normalized['folder'] ?? '').toString().trim();
        _folderController.text = _folder;
        final savedType = _commandTypeFromText(
          (normalizedData['commandType'] ?? normalized['type'] ?? '')
              .toString(),
        );
        _commandType = savedType ?? _commandType;
        _editorMode = editorMode;
        _executionMode = executionMode;
        _bdfdScriptContent = (normalizedData['bdfdScriptContent'] ?? '')
            .toString();
        _bdfdScriptController.text = _bdfdScriptContent;
        _jsScriptContent = (normalizedData['jsScriptContent'] ?? '').toString();
        _jsScriptController.text = _jsScriptContent;
        _bdfdCompileResult = _bdfdCompiler.compile(_bdfdScriptContent);
        _legacyModeEnabled = normalizedData['legacyModeEnabled'] == true;
        _localOnlyCommand =
            normalizedData['legacyLocalOnly'] == true ||
            normalizedData['localOnly'] == true ||
            _legacyModeEnabled;
        _legacyPrefixOverride = (normalizedData['legacyPrefixOverride'] ?? '')
            .toString();
        _legacyAliases = List<String>.from(
          (normalizedData['legacyAliases'] as List?)?.whereType<String>() ??
              const <String>[],
        );
        final loadedLegacyResponseTarget =
            (normalizedData['legacyResponseTarget'] ?? 'reply').toString();
        _legacyResponseTarget = loadedLegacyResponseTarget == 'channelSend'
            ? 'channelSend'
            : 'reply';
        if (!_supportsSimpleMode) {
          _editorMode = _editorModeAdvanced;
        }
        _actions = List<Map<String, dynamic>>.from(
          (normalizedData['actions'] as List?)?.whereType<Map>().map(
                (e) => Map<String, dynamic>.from(e),
              ) ??
              const [],
        );
        _subcommandWorkflows = _normalizeStoredSubcommandWorkflows(
          normalizedData['subcommandWorkflows'],
        );
        _activeSubcommandRoute =
            (normalizedData['activeSubcommandRoute'] ?? _rootWorkflowRoute)
                .toString();
        final storedOptions = normalizedData['options'];
        if (storedOptions is List) {
          _options = deserializeCommandOptions(storedOptions);
        }
        _promoteSimpleModeDraftIfNeeded(editorMode);
        if (_subcommandWorkflows.containsKey(_activeSubcommandRoute)) {
          final activePayload = _subcommandWorkflows[_activeSubcommandRoute];
          if (activePayload != null) {
            _applyWorkflowPayloadToEditor(activePayload);
          }
        }
        _defaultMemberPermissions =
            (normalizedData['defaultMemberPermissions'] ?? '')
                .toString()
                .trim();
        _resetDirtyState();
        _isLoading = false;
      });
      return;
    }

    // first let's check if the command is already created or not
    if (!widget.id.isZero) {
      ApplicationCommand? command;
      try {
        final commandsList = await widget.client?.commands.list(
          withLocalizations: true,
        );
        command = commandsList?.cast<ApplicationCommand?>().firstWhere(
          (c) => c?.id == widget.id,
          orElse: () => null,
        );
      } catch (_) {}

      try {
        command ??= await widget.client?.commands.fetch(widget.id);
      } catch (_) {}

      // check if we also have the command in the database
      final botId = _botIdForConfig;
      if (botId == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final commandData = await appManager.getAppCommand(
        botId,
        widget.id.toString(),
      );
      // let's set the command data to the fields
      final data = commandData["data"];
      if (data != null) {
        final normalized = appManager.normalizeCommandData(
          Map<String, dynamic>.from(commandData),
        );
        final normalizedData = Map<String, dynamic>.from(
          normalized["data"] ?? const {},
        );
        final executionMode = _normalizeExecutionMode(
          normalizedData['executionMode'],
        );
        final persistedEditorMode =
            (normalizedData['editorMode'] ?? _editorModeAdvanced)
                .toString()
                .toLowerCase();
        final editorMode = persistedEditorMode == _editorModeSimple
            ? _editorModeSimple
            : _editorModeAdvanced;

        if (!mounted) return;
        setState(() {
          _editorMode = editorMode;
          _executionMode = executionMode;
          _folder = (normalized['folder'] ?? '').toString().trim();
          _folderController.text = _folder;
          _bdfdScriptContent = (normalizedData['bdfdScriptContent'] ?? '')
              .toString();
          _bdfdScriptController.text = _bdfdScriptContent;
          _jsScriptContent = (normalizedData['jsScriptContent'] ?? '')
              .toString();
          _jsScriptController.text = _jsScriptContent;
          _bdfdCompileResult = _bdfdCompiler.compile(_bdfdScriptContent);
          _legacyModeEnabled = normalizedData['legacyModeEnabled'] == true;
          _localOnlyCommand =
              normalizedData['legacyLocalOnly'] == true ||
              normalizedData['localOnly'] == true ||
              _legacyModeEnabled;
          _legacyPrefixOverride = (normalizedData['legacyPrefixOverride'] ?? '')
              .toString();
          _legacyAliases = List<String>.from(
            (normalizedData['legacyAliases'] as List?)?.whereType<String>() ??
                const <String>[],
          );
          final loadedLegacyResponseTarget =
              (normalizedData['legacyResponseTarget'] ?? 'reply').toString();
          _legacyResponseTarget = loadedLegacyResponseTarget == 'channelSend'
              ? 'channelSend'
              : 'reply';
          final savedType = _commandTypeFromText(
            (normalizedData['commandType'] ?? commandData['type'] ?? '')
                .toString(),
          );
          _commandType = savedType ?? _commandType;
          if (!_supportsSimpleMode) {
            _editorMode = _editorModeAdvanced;
          }
          _actions = List<Map<String, dynamic>>.from(
            (normalizedData["actions"] as List?)?.whereType<Map>().map(
                  (e) => Map<String, dynamic>.from(e),
                ) ??
                const [],
          );
          _subcommandWorkflows = _normalizeStoredSubcommandWorkflows(
            normalizedData['subcommandWorkflows'],
          );
          _activeSubcommandRoute =
              (normalizedData['activeSubcommandRoute'] ?? _rootWorkflowRoute)
                  .toString();
          final storedOptions = normalizedData['options'];
          if (storedOptions is List) {
            _options = deserializeCommandOptions(storedOptions);
          }
          _promoteSimpleModeDraftIfNeeded(editorMode);
          if (_subcommandWorkflows.containsKey(_activeSubcommandRoute)) {
            final activePayload = _subcommandWorkflows[_activeSubcommandRoute];
            if (activePayload != null) {
              _applyWorkflowPayloadToEditor(activePayload);
            }
          }
          _defaultMemberPermissions =
              (normalizedData['defaultMemberPermissions'] ?? '')
                  .toString()
                  .trim();
        });
      } else {
        // No local data found for this existing command — default to advanced
        if (!mounted) return;
        setState(() {
          _editorMode = _editorModeAdvanced;
        });
      }
      // ── Safety net: always terminate loading even if Discord is offline ──
      if (command == null) {
        // Load minimal fields from local storage so the read-only banner can
        // display the command name/description even without a Discord connection.
        final localName = commandData['name']?.toString() ?? '';
        final localDescription = commandData['description']?.toString() ?? '';
        // The command is incomplete only when the full `data` block is absent.
        // If the data block exists, the command can be edited locally offline.
        final hasFullLocalData = data != null;
        if (!mounted) return;
        _applyStateUpdate(() {
          _isLocalOnlyCommand = true;
          if (localName.isNotEmpty) {
            _commandName = localName;
          }
          if (localDescription.isNotEmpty) {
            _commandDescription = localDescription;
          }
          final localType = _commandTypeFromText(
            (commandData['type'] ?? '').toString(),
          );
          if (localType != null) {
            _commandType = localType;
          }
          _isLoading = false;
          _isDataIncomplete = !hasFullLocalData;
          if (hasFullLocalData) {
            _resetDirtyState();
          }
        });
        return;
      }

      final currentCommand = command;
      if (!mounted) return;
      _applyStateUpdate(() {
        _commandName = currentCommand.name;
        _commandDescription = currentCommand.description;
        _commandType = currentCommand.type;
        final storedOptions = data is Map
            ? Map<String, dynamic>.from(data.cast<String, dynamic>())['options']
            : null;
        if (storedOptions is List) {
          _options = deserializeCommandOptions(storedOptions);
        } else if (currentCommand.options != null) {
          _options = currentCommand.options!
              .map(_buildOptionFromApplicationOption)
              .toList();
        } else {
          _options = [];
        }
        _integrationTypes = currentCommand.integrationTypes.map((e) {
          if (e == ApplicationIntegrationType.guildInstall) {
            return ApplicationIntegrationType.guildInstall;
          } else if (e == ApplicationIntegrationType.userInstall) {
            return ApplicationIntegrationType.userInstall;
          } else {
            return ApplicationIntegrationType.guildInstall;
          }
        }).toList();
        _contexts = [];
        if (currentCommand.contexts != null) {
          _contexts = currentCommand.contexts!.toList();
        } else {
          // legacy defaults to guild
          _contexts = [InteractionContextType.guild];
        }
        if (_defaultMemberPermissions.isEmpty &&
            currentCommand.defaultMemberPermissions != null) {
          _defaultMemberPermissions = currentCommand
              .defaultMemberPermissions!
              .value
              .toString();
        }
        if (!_supportsSimpleMode) {
          _editorMode = _editorModeAdvanced;
        }
        if (_containsHierarchyOption(_options)) {
          _editorMode = _editorModeAdvanced;
        }
        _syncSubcommandWorkflowRoutes();
        _resetDirtyState();
        _isLoading = false;
      });
    } else {
      _applyStateUpdate(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrCreate() async {
    developer.log(
      '[_updateOrCreate] START commandName="$_commandName" isEditing=$_isEditingExistingCommand isLocalOnly=$_localOnlyCommand isSimpleMode=$_isSimpleMode botId=$_botIdForConfig existingId=$_existingCommandStorageId commandType=$_commandType clientNull=${widget.client == null}',
      name: 'CommandCreatePage',
    );
    // check if any field is empty
    if (_commandName.isEmpty ||
        (_requiresCommandDescription && _commandDescription.isEmpty)) {
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(context.tr.cmd_error_fill_fields),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.tr.ok),
          ),
        ],
      );
      showDialog(context: context, builder: (context) => dialog);
      return;
    }

    final simpleValidationError = null;
    if (simpleValidationError != null) {
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(simpleValidationError),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.tr.ok),
          ),
        ],
      );
      showDialog(context: context, builder: (context) => dialog);
      return;
    }

    developer.log(
      '[_updateOrCreate] persisting active subcommand workflow state',
      name: 'CommandCreatePage',
    );
    _persistActiveSubcommandWorkflow();

    final effectiveOptions = _effectiveOptions;
    final effectiveActions = _effectiveActions;
    developer.log(
      '[_updateOrCreate] building command data payload (effectiveOptionsCount=${effectiveOptions.length} effectiveActionsCount=${effectiveActions.length})',
      name: 'CommandCreatePage',
    );
    final commandData = _buildCommandDataPayload(
      effectiveActions: effectiveActions,
    );
    developer.log(
      '[_updateOrCreate] commandData built (topLevelKeys=${commandData.keys.toList()})',
      name: 'CommandCreatePage',
    );

    final client = widget.client;
    final botId = _botIdForConfig;
    final existingStorageId = _existingCommandStorageId;
    developer.log(
      '[_updateOrCreate] resolved botId=$botId existingStorageId=$existingStorageId clientNull=${client == null}',
      name: 'CommandCreatePage',
    );
    if (botId == null) {
      developer.log(
        '[_updateOrCreate] ERROR botId is null — showing error dialog and aborting.',
        name: 'CommandCreatePage',
      );
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(context.tr.command_error_missing_bot_id),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(context.tr.common_ok),
          ),
        ],
      );
      showDialog(context: context, builder: (context) => dialog);
      return;
    }

    Future<void> saveLocal(String commandId) async {
      developer.log(
        '[saveLocal] saving commandId=$commandId botId=$botId name="$_commandName" folder="$_folder" isEditing=$_isEditingExistingCommand',
        name: 'CommandCreatePage',
      );
      final localPayload = <String, dynamic>{
        'name': _commandName,
        'description': _effectiveCommandDescription,
        'type': _commandTypeToText(_commandType),
        'id': commandId,
        'updatedAt': DateTime.now().toIso8601String(),
        'data': commandData,
        if (_folder.isNotEmpty) 'folder': _folder,
      };

      if (!_isEditingExistingCommand) {
        localPayload['createdAt'] = DateTime.now().toIso8601String();
      }

      await appManager.saveAppCommand(botId, commandId, localPayload);
      developer.log(
        '[saveLocal] saved OK commandId=$commandId botId=$botId',
        name: 'CommandCreatePage',
      );
    }

    Future<void> performSave(
      void Function(String status) updateStatus,
      Completer<Future<void> Function()> reloadCompleter,
    ) async {
      final originalHook = AppManager.onAfterCommandSave;
      AppManager.onAfterCommandSave = (bId, cId, cmd) async {
        if (!reloadCompleter.isCompleted) {
          reloadCompleter.complete(() async {
            if (originalHook != null) {
              await originalHook(bId, cId, cmd);
            }
          });
        }
      };

      try {
        if (client == null || _localOnlyCommand || _legacyModeEnabled) {
          updateStatus('local_save');
          final localCommandId =
              existingStorageId ??
              ((_localOnlyCommand || _legacyModeEnabled)
                  ? _generateLegacyOnlyCommandId()
                  : DateTime.now().microsecondsSinceEpoch.toString());

          // If transitioning from a Discord-registered command to local-only/legacy,
          // remove the slash command from Discord so it doesn't linger.
          if (client != null && !widget.id.isZero) {
            try {
              developer.log(
                '[performSave] Transitioning to local-only/legacy. Deleting command from Discord (id=${widget.id})',
                name: 'CommandCreatePage',
              );
              await client.commands.delete(widget.id);
            } catch (e) {
              developer.log(
                '[performSave] Discord deletion failed (may already be deleted): $e',
                name: 'CommandCreatePage',
              );
            }
          }

          await saveLocal(localCommandId);

          updateStatus('reload_runtime');
          await refreshBotRuntime(botId);
          return;
        }

        // Online Discord Flow
        updateStatus('discord_sync');
        if (!_isEditingExistingCommand || _isLocalOnlyCommand) {
          // Create a new command on Discord
          final ApplicationCommandBuilder commandBuilder;
          if (_commandType == ApplicationCommandType.user) {
            commandBuilder = ApplicationCommandBuilder.user(name: _commandName);
          } else if (_commandType == ApplicationCommandType.message) {
            commandBuilder = ApplicationCommandBuilder.message(
              name: _commandName,
            );
          } else {
            commandBuilder = ApplicationCommandBuilder.chatInput(
              name: _commandName,
              description: _commandDescription,
              options: effectiveOptions,
            );
          }

          final parsedPermissions = _parseDefaultMemberPermissions(
            _defaultMemberPermissions,
          );
          commandBuilder.defaultMemberPermissions = parsedPermissions;

          commandBuilder.integrationTypes = _integrationTypes;
          if (_contexts.isNotEmpty) {
            commandBuilder.contexts = _contexts;
          }
          developer.log(
            '[_updateOrCreate] calling createCommand on Discord (botId=$botId commandName="$_commandName" type=$_commandType folder="$_folder" optionsCount=${effectiveOptions.length})',
            name: 'CommandCreatePage',
          );
          await createCommand(
            client,
            commandBuilder,
            data: commandData,
            folder: _folder,
          );
          developer.log(
            '[_updateOrCreate] Discord createCommand succeeded (botId=$botId commandName="$_commandName")',
            name: 'CommandCreatePage',
          );
          // Cloud sync is not supported on Desktop platforms
          if (!_isDesktop) {
            developer.log(
              '[_updateOrCreate] triggering cloud sync after create (botId=$botId)',
              name: 'CommandCreatePage',
            );

            updateStatus('cloud_sync');
            final cloudSyncOk = await _syncCommandChangesToCloud(botId: botId);
            developer.log(
              '[_updateOrCreate] cloud sync after create result=$cloudSyncOk (botId=$botId)',
              name: 'CommandCreatePage',
            );
            if (!cloudSyncOk) {
              _notifyCloudSyncFailed(botId);
            }
          }
          // Delete the old temp-ID file if this was a local-only command
          if (_isLocalOnlyCommand) {
            final previousId = existingStorageId;
            developer.log(
              '[_updateOrCreate] cleaning up old local-only command file (previousId=$previousId botId=$botId)',
              name: 'CommandCreatePage',
            );
            if (previousId != null) {
              await appManager.deleteAppCommand(botId, previousId);
              developer.log(
                '[_updateOrCreate] deleted old local-only command file (previousId=$previousId botId=$botId)',
                name: 'CommandCreatePage',
              );
            }
          }
        } else {
          // Update the existing command
          final ApplicationCommandUpdateBuilder commandBuilder;
          if (_commandType == ApplicationCommandType.user) {
            commandBuilder = ApplicationCommandUpdateBuilder.user(
              name: _commandName,
            );
          } else if (_commandType == ApplicationCommandType.message) {
            commandBuilder = ApplicationCommandUpdateBuilder.message(
              name: _commandName,
            );
          } else {
            commandBuilder = ApplicationCommandUpdateBuilder.chatInput(
              name: _commandName,
              description: _commandDescription,
            );
          }
          final parsedPermissions = _parseDefaultMemberPermissions(
            _defaultMemberPermissions,
          );
          commandBuilder.defaultMemberPermissions = parsedPermissions;
          commandBuilder.integrationTypes = _integrationTypes;
          if (_contexts.isNotEmpty) {
            commandBuilder.contexts = _contexts;
          } else {
            commandBuilder.contexts = [];
          }
          if (_commandType == ApplicationCommandType.chatInput) {
            if (effectiveOptions.isNotEmpty) {
              commandBuilder.options = effectiveOptions;
            } else {
              commandBuilder.options = [];
            }
          }

          developer.log(
            '[_updateOrCreate] calling updateCommand on Discord (botId=$botId commandId=${widget.id} commandName="$_commandName" type=$_commandType folder="$_folder" optionsCount=${effectiveOptions.length})',
            name: 'CommandCreatePage',
          );
          await updateCommand(
            client,
            widget.id,
            commandBuilder: commandBuilder,
            data: commandData,
            folder: _folder,
          );
          developer.log(
            '[_updateOrCreate] Discord updateCommand succeeded (botId=$botId commandId=${widget.id})',
            name: 'CommandCreatePage',
          );
          // Cloud sync is not supported on Desktop platforms
          if (!_isDesktop) {
            developer.log(
              '[_updateOrCreate] triggering cloud sync after update (botId=$botId)',
              name: 'CommandCreatePage',
            );

            updateStatus('cloud_sync');
            final cloudSyncOk = await _syncCommandChangesToCloud(botId: botId);
            developer.log(
              '[_updateOrCreate] cloud sync after update result=$cloudSyncOk (botId=$botId)',
              name: 'CommandCreatePage',
            );
            if (!cloudSyncOk) {
              _notifyCloudSyncFailed(botId);
            }
          }
        }
      } finally {
        AppManager.onAfterCommandSave = originalHook;
      }
    }

    if (!mounted) return;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, anim1, anim2) {
        return _DeploymentProgressOverlay(
          botId: botId,
          commandName: _commandName,
          isEditing: _isEditingExistingCommand,
          isLocalOnly: _localOnlyCommand || _legacyModeEnabled,
          client: client,
          onSave: performSave,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final guardDiscardOnPop = _showEditShell && _isDirty;
    final showStickyEditSave =
        _showEditShell && !_isLoading && !_isDataIncomplete;

    return ChangeNotifierProvider.value(
      value: _editorNotifier,
      child: PopScope(
        canPop: !guardDiscardOnPop,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop || !guardDiscardOnPop) {
            return;
          }
          if (await _confirmDiscardIfDirty()) {
            if (mounted) {
              Navigator.pop(context);
            }
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(
              _commandName.trim().isNotEmpty
                  ? '/${_commandName.trim()}'
                  : context.tr.edit_shell_untitled_command,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                tooltip: context.tr.edit_shell_command_settings,
                onPressed: _openCommandSettings,
                icon: const Icon(Icons.tune_rounded),
              ),
              if (!_isEditingExistingCommand)
                IconButton(
                  tooltip: context.tr.serialization_import_title,
                  onPressed: _importCommandPayload,
                  icon: const Icon(Icons.content_paste_go_outlined),
                ),
              IconButton(
                tooltip: context.tr.serialization_export_json_title,
                onPressed: _showCommandExportOptions,
                icon: const Icon(Icons.copy_all_outlined),
              ),
              IconButton(
                onPressed: _openDocumentationCenter,
                tooltip: context.tr.cmd_show_variables,
                icon: const Icon(Icons.info_outline),
              ),
              if (!_isEditingExistingCommand && !_isDataIncomplete)
                IconButton(
                  icon: const Icon(Icons.cancel),
                  tooltip: context.tr.cancel,
                  onPressed: () async {
                    Navigator.pop(context);
                  },
                ),
              if (_isEditingExistingCommand)
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: context.tr.cmd_delete_tooltip,
                  onPressed: () async {
                    final shouldDelete = await AppTheme.showConfirmDialog(
                      context,
                      title: context.tr.cmd_delete_tooltip,
                      content:
                          'This command will be deleted permanently. Continue?',
                      confirmLabel: context.tr.delete,
                      isDestructive: true,
                    );
                    if (!shouldDelete) {
                      return;
                    }

                    final botId = _botIdForConfig;
                    final commandId = _existingCommandStorageId;
                    if (botId == null) {
                      return;
                    }
                    if (commandId == null) {
                      return;
                    }

                    final remoteClient = widget.client;
                    if (remoteClient != null && !widget.id.isZero) {
                      try {
                        await remoteClient.commands.delete(widget.id);
                      } catch (e) {
                        final message = e.toString();
                        final alreadyDeleted =
                            message.contains('10063') ||
                            message.contains('Unknown application command') ||
                            message.contains('404');
                        if (!alreadyDeleted) {
                          if (!mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Discord delete failed. Local delete applied. $e',
                              ),
                            ),
                          );
                        }
                      }
                    }

                    await appManager.deleteAppCommand(botId, commandId);
                    if (!mounted) {
                      return;
                    }
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
          floatingActionButton: showStickyEditSave
              ? FloatingActionButton(
                  onPressed: _isEditingExistingCommand
                      ? (_isDirty ? _saveExistingCommand : null)
                      : () async {
                          if (await _validateCommandInputs()) {
                            await _updateOrCreate();
                            _hasUnsavedChanges = false;
                          }
                        },
                  backgroundColor: _isEditingExistingCommand && !_isDirty
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: _isEditingExistingCommand && !_isDirty
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
                      : Colors.white,
                  tooltip: _isEditingExistingCommand
                      ? (_isDirty
                            ? context.tr.edit_shell_save_changes
                            : context.tr.edit_shell_all_saved)
                      : context.tr.cmd_create_tooltip,
                  child: Icon(
                    _isEditingExistingCommand
                        ? (_isDirty ? Icons.save : Icons.check)
                        : Icons.add,
                  ),
                )
              : null,
          bottomNavigationBar:
              MediaQuery.of(context).viewInsets.bottom > 0 &&
                  (MediaQuery.of(context).size.width < 800 ||
                      defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
              ? MobileKeyboardAccessoryBar(
                  variableSuggestions: _actionVariableSuggestions,
                )
              : null,
          body: SafeArea(
            top: false,
            // Largeur et marges communes à toutes les pages (contrat
            // `AppPageLayout`) : la page ne code plus ses propres bornes.
            child: LayoutBuilder(
              builder: (context, constraints) {
                final contentMaxWidth = AppPageLayout.contentMaxWidthFor(
                  constraints.maxWidth,
                );

                return PageContent(
                  child: _buildEditorBody(contentMaxWidth: contentMaxWidth),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DEPLOYMENT & SYNC PROGRESS OVERLAY
// ═══════════════════════════════════════════════════════════════════════════════

enum SyncStepState { pending, active, success, error }

class _SyncStepData {
  final String id;
  final String title;
  final String subtitle;
  SyncStepState state = SyncStepState.pending;
  String? error;

  _SyncStepData({
    required this.id,
    required this.title,
    required this.subtitle,
  });
}

class _DeploymentProgressOverlay extends StatefulWidget {
  final String? botId;
  final String commandName;
  final bool isEditing;
  final bool isLocalOnly;
  final NyxxRest? client;
  final Future<void> Function(
    void Function(String status) updateStatus,
    Completer<Future<void> Function()> reloadCompleter,
  )
  onSave;

  const _DeploymentProgressOverlay({
    required this.botId,
    required this.commandName,
    required this.isEditing,
    required this.isLocalOnly,
    required this.client,
    required this.onSave,
  });

  @override
  State<_DeploymentProgressOverlay> createState() =>
      _DeploymentProgressOverlayState();
}

class _DeploymentProgressOverlayState
    extends State<_DeploymentProgressOverlay> {
  late List<_SyncStepData> _steps;
  bool _hasError = false;
  bool _isSuccess = false;
  Completer<Future<void> Function()>? _reloadCompleter;

  @override
  void initState() {
    super.initState();
    _initSteps();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDeployment();
    });
  }

  void _initSteps() {
    if (widget.isLocalOnly || widget.client == null) {
      _steps = [
        _SyncStepData(
          id: 'local_save',
          title: 'Sauvegarde locale',
          subtitle: 'Enregistrement de la commande sur l\'appareil',
        ),
        _SyncStepData(
          id: 'reload_runtime',
          title: 'Rechargement du Bot',
          subtitle: 'Application à chaud de la configuration',
        ),
      ];
    } else if (_isDesktop) {
      // Cloud sync is not supported on Desktop platforms
      _steps = [
        _SyncStepData(
          id: 'discord_sync',
          title: 'Synchronisation Discord',
          subtitle: 'Publication de la commande sur l\'API Discord',
        ),
        _SyncStepData(
          id: 'reload_runtime',
          title: 'Rechargement à chaud',
          subtitle: 'Mise à jour instantanée du runner de votre bot',
        ),
      ];
    } else {
      _steps = [
        _SyncStepData(
          id: 'discord_sync',
          title: 'Synchronisation Discord',
          subtitle: 'Publication de la commande sur l\'API Discord',
        ),
        _SyncStepData(
          id: 'cloud_sync',
          title: 'Sauvegarde Cloud',
          subtitle: 'Synchronisation sécurisée dans votre espace en ligne',
        ),
        _SyncStepData(
          id: 'reload_runtime',
          title: 'Rechargement à chaud',
          subtitle: 'Mise à jour instantanée du runner de votre bot',
        ),
      ];
    }
    _hasError = false;
    _isSuccess = false;
  }

  void _updateStepState(String stepId, SyncStepState state) {
    if (!mounted) return;
    setState(() {
      for (var step in _steps) {
        if (step.id == stepId) {
          step.state = state;
        }
      }
    });
  }

  void _autoSuccessPreviousSteps(String activeStepId) {
    if (!mounted) return;
    setState(() {
      bool foundActive = false;
      for (var step in _steps) {
        if (step.id == activeStepId) {
          foundActive = true;
        }
        if (!foundActive) {
          step.state = SyncStepState.success;
        }
      }
    });
  }

  Future<void> _startDeployment() async {
    setState(() {
      _hasError = false;
      for (var step in _steps) {
        step.state = SyncStepState.pending;
        step.error = null;
      }
    });

    final reloadCompleter = Completer<Future<void> Function()>();
    _reloadCompleter = reloadCompleter;

    try {
      // 1. Run performSave from parent
      await widget.onSave((status) {
        _updateStepState(status, SyncStepState.active);
        _autoSuccessPreviousSteps(status);
      }, reloadCompleter);

      // 2. Wait for reload completer
      if (!widget.isLocalOnly && widget.client != null) {
        if (!_isDesktop) {
          _updateStepState('cloud_sync', SyncStepState.success);
        }
        _updateStepState('reload_runtime', SyncStepState.active);

        final reloadCompleter = _reloadCompleter;
        if (reloadCompleter != null && reloadCompleter.isCompleted) {
          final reloadAction = await reloadCompleter.future;
          await reloadAction();
        } else {
          final botId = widget.botId;
          if (botId != null) {
            await refreshBotRuntime(botId);
          }
        }
      }

      // Mark all steps successful
      if (mounted) {
        setState(() {
          for (var step in _steps) {
            step.state = SyncStepState.success;
          }
          _isSuccess = true;
        });
      }

      // Show beautiful checkmark and auto-pop after a brief delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.cmd_deploy_success_toast(widget.commandName),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pop(); // Pops overlay
        Navigator.of(context).pop(); // Pops command create page
      }
    } catch (e, stack) {
      developer.log(
        'Deployment failed: $e',
        name: 'DeploymentProgressOverlay',
        error: e,
        stackTrace: stack,
      );

      if (mounted) {
        setState(() {
          _hasError = true;
          for (var step in _steps) {
            if (step.state == SyncStepState.active) {
              step.state = SyncStepState.error;
              step.error = e.toString();
            }
          }
        });
      }
    }
  }

  Widget _buildStepIcon(SyncStepState state) {
    switch (state) {
      case SyncStepState.pending:
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
        );
      case SyncStepState.active:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      case SyncStepState.success:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.success,
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 16),
        );
      case SyncStepState.error:
        return Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.error,
          ),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        );
    }
  }

  String _getStepTitle(BuildContext context, String id) {
    switch (id) {
      case 'local_save':
        return context.tr.cmd_deploy_local_save_title;
      case 'reload_runtime':
        return widget.isLocalOnly || widget.client == null
            ? context.tr.cmd_deploy_reload_bot_title
            : context.tr.cmd_deploy_hot_reload_title;
      case 'discord_sync':
        return context.tr.cmd_deploy_discord_sync_title;
      case 'cloud_sync':
        return context.tr.cmd_deploy_cloud_sync_title;
      default:
        return '';
    }
  }

  String _getStepSubtitle(BuildContext context, String id) {
    switch (id) {
      case 'local_save':
        return context.tr.cmd_deploy_local_save_subtitle;
      case 'reload_runtime':
        return widget.isLocalOnly || widget.client == null
            ? context.tr.cmd_deploy_reload_bot_subtitle
            : context.tr.cmd_deploy_hot_reload_subtitle;
      case 'discord_sync':
        return context.tr.cmd_deploy_discord_sync_subtitle;
      case 'cloud_sync':
        return context.tr.cmd_deploy_cloud_sync_subtitle;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color(0xFF1E1F22).withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.9);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.08);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Glassmorphic background blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(color: Colors.black.withValues(alpha: 0.65)),
            ),
          ),
          // Dialog container
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated pulsing visual status indicator
                        if (_isSuccess)
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 500),
                            tween: Tween(begin: 0.0, end: 1.0),
                            curve: Curves.elasticOut,
                            builder: (context, val, child) {
                              return Transform.scale(
                                scale: val,
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.success,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.successLight,
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          )
                        else if (_hasError)
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.error,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.errorLight,
                                  blurRadius: 15,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 40,
                            ),
                          )
                        else
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 72,
                                height: 72,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              TweenAnimationBuilder<double>(
                                duration: const Duration(seconds: 2),
                                tween: Tween(begin: 0.0, end: 1.0),
                                builder: (context, val, child) {
                                  return Opacity(
                                    opacity: 0.7 + 0.3 * (val - 0.5).abs() * 2,
                                    child: child,
                                  );
                                },
                                child: Icon(
                                  Icons.sync,
                                  size: 32,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                        // Title
                        Text(
                          _isSuccess
                              ? context.tr.cmd_deploy_success_title
                              : (_hasError
                                    ? context.tr.cmd_deploy_failed_title
                                    : context.tr.cmd_deploy_in_progress_title),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(
                              context,
                            ).textTheme.titleLarge?.color,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          context.tr.cmd_deploy_config_subtitle(
                            widget.commandName,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28),
                        // Steps List
                        Column(
                          children: _steps.map((step) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10.0,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: _buildStepIcon(step.state),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getStepTitle(context, step.id),
                                          style: TextStyle(
                                            fontWeight:
                                                step.state ==
                                                    SyncStepState.active
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            color:
                                                step.state ==
                                                    SyncStepState.pending
                                                ? Theme.of(
                                                    context,
                                                  ).disabledColor
                                                : Theme.of(
                                                    context,
                                                  ).textTheme.bodyLarge?.color,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _getStepSubtitle(context, step.id),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color:
                                                step.state ==
                                                    SyncStepState.pending
                                                ? Theme.of(context)
                                                      .disabledColor
                                                      .withValues(alpha: 0.6)
                                                : Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color
                                                      ?.withValues(alpha: 0.65),
                                          ),
                                        ),
                                        if (step.state == SyncStepState.error &&
                                            step.error != null) ...[
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppTheme.error.withValues(
                                                alpha: 0.08,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppTheme.error
                                                    .withValues(alpha: 0.15),
                                              ),
                                            ),
                                            child: Text(
                                              step.error!,
                                              style: const TextStyle(
                                                color: AppTheme.error,
                                                fontSize: 11,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        // Error buttons
                        if (_hasError) ...[
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pop(); // Close overlay only
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr.cmd_deploy_close_button,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _startDeployment,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    context.tr.cmd_deploy_retry_button,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
