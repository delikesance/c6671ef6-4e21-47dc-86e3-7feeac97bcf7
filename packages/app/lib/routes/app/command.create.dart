import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/main.dart';
import 'package:bot_creator/utils/app_theme.dart';
import 'package:bot_creator/routes/app/builder.response.dart';
import 'package:bot_creator/routes/app/command.reply_editor.dart';
import 'package:bot_creator/routes/app/command_option_serialization.dart';
import 'package:bot_creator/routes/app/command_option_validation.dart';
import 'package:bot_creator/routes/app/workflow_docs.page.dart';
import 'package:bot_creator/types/app_emoji.dart';
import 'package:bot_creator/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/utils/analytics.dart';
import 'package:bot_creator/utils/app_emoji_api.dart';
import 'package:bot_creator/utils/bot.dart';
import 'package:bot_creator/utils/bot_payload_builder.dart';
import 'package:bot_creator/utils/command_variable_catalog.dart';
import 'package:bot_creator/utils/embed_normalization.dart';
import 'package:bot_creator/utils/global.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/simple_mode.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator/widgets/bdfd_editor_page.dart';
import 'package:bot_creator/widgets/option_widget.dart';
import 'package:bot_creator/widgets/command_create_cards/basic_info_card.dart';
import 'package:bot_creator/widgets/command_create_cards/actions_card.dart';
import 'package:bot_creator/widgets/scratch_blocks/scratch_block.dart';
import 'package:bot_creator/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:bot_creator/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator/widgets/scratch_blocks/metadata_block.dart';
import 'package:bot_creator/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/widgets/scratch_blocks/action_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nyxx/nyxx.dart';
import 'package:uuid/uuid.dart';
import 'dart:developer' as developer;

part 'command.create.variable_suggestions.dart';
part 'command.create.serialization.dart';
part 'command.create.simple_mode.dart';
part 'command.create.edit_shell.dart';
part 'command.create.workflow.dart';
part 'command.create.validation.dart';
part 'command.create.wizard.dart';
part 'command.create.block_editor.dart';

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

class _CommandCreatePageState extends State<CommandCreatePage> {
  static const Uuid _uuid = Uuid();
  static const String _editorModeSimple = 'simple';
  static const String _editorModeAdvanced = 'advanced';
  static const String _executionModeWorkflow = 'workflow';
  static const String _executionModeBdfdScript = 'bdfd_script';
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

  String _commandName = "";
  String _commandDescription = "";
  ApplicationCommandType _commandType = ApplicationCommandType.chatInput;
  List<CommandOptionBuilder> _options = [];
  String _response = "";
  final TextEditingController _responseController = TextEditingController();
  String _responseType = 'normal';
  List<Map<String, dynamic>> _responseEmbeds = [];
  Map<String, dynamic> _responseComponents = {};
  Map<String, dynamic> _responseModal = {};
  List<Map<String, dynamic>> _actions = [];
  Map<String, dynamic> _responseWorkflow = _defaultWorkflow();
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
  final TextEditingController _bdfdScriptController = TextEditingController();
  final BdfdCompiler _bdfdCompiler = BdfdCompiler();
  BdfdCompileResult? _bdfdCompileResult;
  bool _legacyModeEnabled = false;
  bool _localOnlyCommand = false;
  String _folder = '';
  final TextEditingController _folderController = TextEditingController();
  String _legacyPrefixOverride = '';
  String _legacyResponseTarget = 'reply';
  bool _simpleDeleteMessages = false;
  bool _simpleKickUser = false;
  bool _simpleBanUser = false;
  bool _simpleUnbanUser = false;
  bool _simpleMuteUser = false;
  bool _simpleUnmuteUser = false;
  bool _simpleAddRole = false;
  bool _simpleRemoveRole = false;
  bool _simpleSendMessage = false;
  bool _simplePinMessage = false;
  bool _simpleUnpinMessage = false;
  bool _simpleCreateInvite = false;
  bool _simpleCreatePoll = false;
  final TextEditingController _simpleSendMessageController =
      TextEditingController();
  final TextEditingController _simpleActionReasonController =
      TextEditingController();
  final TextEditingController _simpleMuteDurationController =
      TextEditingController(text: '10m');
  final TextEditingController _simpleBanDeleteDaysController =
      TextEditingController(text: '0');
  final TextEditingController _simpleDeleteMessagesDefaultCountController =
      TextEditingController(text: '1');
  final TextEditingController _simpleInviteMaxAgeController =
      TextEditingController(text: '86400');
  final TextEditingController _simpleInviteMaxUsesController =
      TextEditingController(text: '0');
  final TextEditingController _simplePollAnswersController =
      TextEditingController(text: 'Yes\nNo');
  final TextEditingController _simplePollDurationHoursController =
      TextEditingController(text: '24');
  bool _simpleInviteTemporary = false;
  bool _simpleInviteUnique = false;
  bool _simplePollAllowMultiselect = false;
  Map<String, Map<String, dynamic>> _subcommandWorkflows =
      <String, Map<String, dynamic>>{};
  String _activeSubcommandRoute = _rootWorkflowRoute;
  bool _isApplyingWorkflowPayload = false;
  int _currentEditorStep = 0;
  bool _showQuickStartBuilder = false;
  String _initialEditSnapshot = '';

  static Map<String, dynamic> _defaultWorkflow() {
    return {
      'workflowMode': 'visual',
      'bdfdScriptContent': '',
      'autoDeferIfActions': true,
      'visibility': 'public',
      'onError': 'edit_error',
      'conditional': {
        'enabled': false,
        'variable': '',
        'whenTrueType': 'normal',
        'whenFalseType': 'normal',
        'whenTrueText': '',
        'whenFalseText': '',
        'whenTrueEmbeds': <Map<String, dynamic>>[],
        'whenFalseEmbeds': <Map<String, dynamic>>[],
        'whenTrueNormalComponents': <String, dynamic>{},
        'whenFalseNormalComponents': <String, dynamic>{},
        'whenTrueComponents': <String, dynamic>{},
        'whenFalseComponents': <String, dynamic>{},
        'whenTrueModal': <String, dynamic>{},
        'whenFalseModal': <String, dynamic>{},
      },
    };
  }

  bool get _isSimpleMode => _editorMode == _editorModeSimple;

  bool get _isBdfdScriptMode => _executionMode == _executionModeBdfdScript;

  List<BdfdCompileDiagnostic> get _bdfdDiagnostics =>
      _bdfdCompileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get _hasBdfdCompileErrors => _bdfdDiagnostics.any(
    (diagnostic) => diagnostic.severity == BdfdCompileDiagnosticSeverity.error,
  );

  String _normalizeExecutionMode(Object? raw) {
    final value =
        (raw ?? _executionModeWorkflow).toString().trim().toLowerCase();
    return value == _executionModeBdfdScript
        ? _executionModeBdfdScript
        : _executionModeWorkflow;
  }

  void _promoteSimpleModeDraftIfNeeded(String persistedEditorMode) {
    if (persistedEditorMode == _editorModeSimple) {
      _hydrateLegacySimpleModeIntoDraft();
    }
    _editorMode = _editorModeAdvanced;
  }

  void _normalizeLegacySimpleResponseType() {
    if (_responseType != 'ephemeral') {
      return;
    }
    _responseType = 'normal';
    _responseWorkflow = _normalizeWorkflow({
      ..._responseWorkflow,
      'visibility': 'ephemeral',
    });
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
    final location =
        (diagnostic.line != null && diagnostic.column != null)
            ? 'L${diagnostic.line}:C${diagnostic.column} '
            : '';
    return '$location${diagnostic.message}';
  }

  bool get _supportsCommandDescription =>
      _commandType == ApplicationCommandType.chatInput;

  bool get _supportsCommandOptions =>
      _commandType == ApplicationCommandType.chatInput;

  bool get _supportsSimpleMode =>
      _commandType == ApplicationCommandType.chatInput;

  bool get _allowModalResponses => !_legacyModeEnabled;

  bool get _allowsInternalLegacyCallbackNames =>
      _commandType == ApplicationCommandType.chatInput &&
      _legacyModeEnabled &&
      _localOnlyCommand;

  int get _commandNameMaxLength =>
      _allowsInternalLegacyCallbackNames
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
      _supportsCommandDescription && !_isAwaitedCallbackCommand;

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

  Map<String, dynamic> _buildResponsePayloadFromEditor() {
    return {
      'mode': _responseEmbeds.isNotEmpty ? 'embed' : 'text',
      'type': _responseType,
      'text': _responseController.text,
      'embed':
          _responseEmbeds.isNotEmpty
              ? Map<String, dynamic>.from(_responseEmbeds.first)
              : {'title': '', 'description': '', 'url': ''},
      'embeds': _cloneJsonListOfMaps(_responseEmbeds.take(10).toList()),
      'components': _cloneJsonMap(_responseComponents),
      'modal': _cloneJsonMap(_responseModal),
      'workflow': _normalizeWorkflow(_cloneJsonMap(_responseWorkflow)),
    };
  }

  Map<String, dynamic> _buildCurrentWorkflowPayload() {
    return {
      'response': _buildResponsePayloadFromEditor(),
      'actions': _cloneJsonListOfMaps(_actions),
    };
  }

  Map<String, dynamic> _buildDefaultWorkflowPayload() {
    return {
      'response': {
        'mode': 'text',
        'type': 'normal',
        'text': '',
        'embed': {'title': '', 'description': '', 'url': ''},
        'embeds': <Map<String, dynamic>>[],
        'components': <String, dynamic>{},
        'modal': <String, dynamic>{},
        'workflow': _defaultWorkflow(),
      },
      'actions': <Map<String, dynamic>>[],
    };
  }

  void _applyWorkflowPayloadToEditor(Map<String, dynamic> payload) {
    final response = Map<String, dynamic>.from(
      (payload['response'] as Map?)?.cast<String, dynamic>() ?? const {},
    );

    final embeds = normalizeResponseEmbedsPayload(
      response['embeds'],
      legacySingleEmbed: response['embed'],
    );

    final actions = List<Map<String, dynamic>>.from(
      (payload['actions'] as List?)?.whereType<Map>().map(
            (entry) => Map<String, dynamic>.from(entry),
          ) ??
          const <Map<String, dynamic>>[],
    );

    final text = (response['text'] ?? '').toString();
    _isApplyingWorkflowPayload = true;
    _responseType = (response['type'] ?? 'normal').toString();
    _response = text;
    if (_responseController.text != text) {
      _responseController.text = text;
    }
    _responseEmbeds = embeds.take(10).toList(growable: false);
    _responseComponents = Map<String, dynamic>.from(
      (response['components'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    _responseModal = Map<String, dynamic>.from(
      (response['modal'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    _responseWorkflow = _normalizeWorkflow(
      Map<String, dynamic>.from(
        (response['workflow'] as Map?)?.cast<String, dynamic>() ??
            _defaultWorkflow(),
      ),
    );
    _actions = actions;
    _isApplyingWorkflowPayload = false;
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
        next[route] =
            (!hadExistingWorkflows && next.isEmpty)
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
              onChanged:
                  !_supportsCommandOptions
                      ? null
                      : (enabled) {
                        setState(() {
                          _legacyModeEnabled = enabled;
                          if (_legacyModeEnabled && _responseType == 'modal') {
                            _responseType = 'normal';
                          }
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
    if (_subcommandWorkflows.isEmpty) {
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
              initialValue:
                  routes.contains(_activeSubcommandRoute)
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
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
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
      !_isEditingExistingCommand || _isLocalOnlyCommand;

  String _generateLegacyOnlyCommandId() => _uuid.v4();

  bool get _showEditShell =>
      _isEditingExistingCommand && !_isDataIncomplete && !_isLoading;

  bool get _isDirty {
    if (!_showEditShell || _initialEditSnapshot.isEmpty) {
      return false;
    }
    return _buildEditSnapshot() != _initialEditSnapshot;
  }

  @override
  void initState() {
    super.initState();
    if (widget.prefillName != null && widget.prefillName!.isNotEmpty) {
      _applyPrefillName(widget.prefillName!);
    }
    _responseController.text = _response;
    _bdfdScriptController.text = _bdfdScriptContent;
    _refreshBdfdCompileResult(notify: false);
    _responseController.addListener(() {
      _response = _responseController.text;
      if (!_isApplyingWorkflowPayload) {
        _persistActiveSubcommandWorkflow();
      }
      if (mounted && !_isApplyingWorkflowPayload) {
        setState(() {});
      }
    });
    _init();
    // Initialize any necessary data or state
  }

  @override
  void dispose() {
    _responseController.dispose();
    _bdfdScriptController.dispose();
    _simpleSendMessageController.dispose();
    _simpleActionReasonController.dispose();
    _simpleMuteDurationController.dispose();
    _simpleBanDeleteDaysController.dispose();
    _simpleDeleteMessagesDefaultCountController.dispose();
    _simpleInviteMaxAgeController.dispose();
    _simpleInviteMaxUsesController.dispose();
    _simplePollAnswersController.dispose();
    _simplePollDurationHoursController.dispose();
    super.dispose();
  }

  Widget _buildFolderField() {
    return TextField(
      controller: _folderController,
      decoration: InputDecoration(
        labelText: context.tr.commands_folder_label,
        hintText: context.tr.commands_folder_hint,
        prefixIcon: const Icon(Icons.folder_outlined),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (val) {
        _folder = val.trim();
      },
    );
  }

  void _applyStateUpdate(VoidCallback callback) {
    if (!mounted) {
      return;
    }
    setState(callback);
  }

  Map<String, Map<String, dynamic>> _buildSnapshotSubcommandWorkflows() {
    final workflows = cloneSubcommandWorkflowPayloads(_subcommandWorkflows).map(
      (key, value) => MapEntry(
        key,
        Map<String, dynamic>.from((value as Map).cast<String, dynamic>()),
      ),
    );
    if (_activeSubcommandRoute != _rootWorkflowRoute &&
        workflows.containsKey(_activeSubcommandRoute)) {
      workflows[_activeSubcommandRoute] = _buildCurrentWorkflowPayload();
    }
    return workflows;
  }

  String _buildEditSnapshot() {
    final integrationTypes = _integrationTypes
      .map(_integrationTypeToText)
      .toList(growable: false)..sort();
    final contexts = _contexts.map(_contextTypeToText).toList(growable: false)
      ..sort();

    final snapshot = <String, dynamic>{
      'name': _commandName,
      'description': _effectiveCommandDescription,
      'commandType': _commandTypeToText(_commandType),
      'folder': _folder.trim(),
      'integrationTypes': integrationTypes,
      'contexts': contexts,
      'data': _buildCommandDataPayload(
        effectiveActions: _effectiveActions,
        persistActiveRoute: false,
        subcommandWorkflowsOverride: _buildSnapshotSubcommandWorkflows(),
      ),
    };

    return jsonEncode(snapshot);
  }

  void _captureInitialEditSnapshot() {
    _initialEditSnapshot = _buildEditSnapshot();
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
      confirmLabel: 'Discard',
      isDestructive: true,
    );

    return discard;
  }

  Future<void> _saveExistingCommand() async {
    developer.log(
      '[_saveExistingCommand] invoked — commandName="$_commandName" existingId=$_existingCommandStorageId isEditing=$_isEditingExistingCommand isDirty=$_isDirty',
      name: 'CommandCreatePage',
    );
    if (!_validateCommandInputs()) {
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
    developer.log(
      '[_saveExistingCommand] _updateOrCreate completed.',
      name: 'CommandCreatePage',
    );
  }

  Future<MainApiClient?> _resolveMainApiClientForCloudSync({
    required String botId,
    required String botToken,
  }) async {
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
    final ownerMetadata =
        botToken.trim().isEmpty
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
      ).exchangeDiscordBotToken(
        botToken: botToken,
        preferredOwnerId: ownerMetadata?.resolveOwnerId(
          preferredOwnerId: session?.userId,
        ),
      );
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
      await MainApiSettingsStore.saveSession(restoredSession);
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
      final payload = await buildBotPayload(botId);
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

  void _openDocumentationCenter() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder:
            (_) => const WorkflowDocumentationPage(
              initialSearch: 'commandType target opts template variables',
            ),
      ),
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
              onChange: (options) {
                setState(() {
                  _applyOptionsUpdate(options);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _init() async {
    await AppAnalytics.logScreenView(
      screenName: "CommandCreatePage",
      screenClass: "CommandCreatePage",
      parameters: {
        "command_id": _existingCommandStorageId ?? 'new',
        "command_name":
            _isEditingExistingCommand ? _commandName : "New Command",
        "is_new_command": _isEditingExistingCommand ? "false" : "true",
        "client_id": widget.client?.user.id.toString() ?? "unknown",
      },
    );

    await _refreshPersistedVariableNames();

    // Load application emojis silently for autocomplete
    try {
      final bid = _botIdForConfig;
      if (bid != null) {
        final token = (await appManager.getApp(bid))['token'] as String?;
        if (token != null && token.isNotEmpty) {
          final emojis = await AppEmojiApi.listEmojis(token, bid);
          if (mounted) setState(() => _appEmojis = emojis);
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
        setState(() {
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
        setState(() {
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
      final editorMode =
          persistedEditorMode == _editorModeSimple
              ? _editorModeSimple
              : _editorModeAdvanced;
      final simpleConfig = _normalizeSimpleConfig(
        Map<String, dynamic>.from(
          (normalizedData['simpleConfig'] as Map?)?.cast<String, dynamic>() ??
              const {},
        ),
      );
      final response = Map<String, dynamic>.from(
        (normalizedData['response'] as Map?)?.cast<String, dynamic>() ??
            const {},
      );
      final embeds = normalizeResponseEmbedsPayload(
        response['embeds'],
        legacySingleEmbed: response['embed'],
      );

      setState(() {
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
        _bdfdScriptContent =
            (normalizedData['bdfdScriptContent'] ?? '').toString();
        _bdfdScriptController.text = _bdfdScriptContent;
        _bdfdCompileResult = _bdfdCompiler.compile(_bdfdScriptContent);
        _legacyModeEnabled = normalizedData['legacyModeEnabled'] == true;
        _localOnlyCommand =
            normalizedData['legacyLocalOnly'] == true ||
            normalizedData['localOnly'] == true;
        _legacyPrefixOverride =
            (normalizedData['legacyPrefixOverride'] ?? '').toString();
        final loadedLegacyResponseTarget =
            (normalizedData['legacyResponseTarget'] ?? 'reply').toString();
        _legacyResponseTarget =
            loadedLegacyResponseTarget == 'channelSend'
                ? 'channelSend'
                : 'reply';
        if (!_supportsSimpleMode) {
          _editorMode = _editorModeAdvanced;
        }
        _applySimpleConfig(simpleConfig);
        _responseType = (response['type'] ?? 'normal').toString();
        if (_legacyModeEnabled && _responseType == 'modal') {
          _responseType = 'normal';
        }
        _response = (response['text'] ?? '').toString();
        _responseController.text = _response;
        _responseEmbeds = embeds.take(10).toList();
        _responseComponents = Map<String, dynamic>.from(
          (response['components'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
        _responseModal = Map<String, dynamic>.from(
          (response['modal'] as Map?)?.cast<String, dynamic>() ?? const {},
        );
        _responseWorkflow = _normalizeWorkflow(
          Map<String, dynamic>.from(
            (response['workflow'] as Map?)?.cast<String, dynamic>() ??
                _defaultWorkflow(),
          ),
        );
        _normalizeLegacySimpleResponseType();
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
        _captureInitialEditSnapshot();
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
        final editorMode =
            persistedEditorMode == _editorModeSimple
                ? _editorModeSimple
                : _editorModeAdvanced;
        final simpleConfig = _normalizeSimpleConfig(
          Map<String, dynamic>.from(
            (normalizedData['simpleConfig'] as Map?)?.cast<String, dynamic>() ??
                const {},
          ),
        );
        final response = Map<String, dynamic>.from(
          (normalizedData["response"] as Map?)?.cast<String, dynamic>() ??
              const {},
        );
        final embeds = normalizeResponseEmbedsPayload(
          response['embeds'],
          legacySingleEmbed: response['embed'],
        );

        if (!mounted) return;
        setState(() {
          _editorMode = editorMode;
          _executionMode = executionMode;
          _folder = (normalized['folder'] ?? '').toString().trim();
          _folderController.text = _folder;
          _bdfdScriptContent =
              (normalizedData['bdfdScriptContent'] ?? '').toString();
          _bdfdScriptController.text = _bdfdScriptContent;
          _bdfdCompileResult = _bdfdCompiler.compile(_bdfdScriptContent);
          _legacyModeEnabled = normalizedData['legacyModeEnabled'] == true;
          _localOnlyCommand =
              normalizedData['legacyLocalOnly'] == true ||
              normalizedData['localOnly'] == true;
          _legacyPrefixOverride =
              (normalizedData['legacyPrefixOverride'] ?? '').toString();
          final loadedLegacyResponseTarget =
              (normalizedData['legacyResponseTarget'] ?? 'reply').toString();
          _legacyResponseTarget =
              loadedLegacyResponseTarget == 'channelSend'
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
          _applySimpleConfig(simpleConfig);
          _responseType = (response['type'] ?? 'normal').toString();
          if (_legacyModeEnabled && _responseType == 'modal') {
            _responseType = 'normal';
          }
          _response = (response["text"] ?? "").toString();
          _responseController.text = _response;
          _responseEmbeds = embeds.take(10).toList();
          _responseComponents = Map<String, dynamic>.from(
            (response['components'] as Map?)?.cast<String, dynamic>() ??
                const {},
          );
          _responseModal = Map<String, dynamic>.from(
            (response['modal'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
          _responseWorkflow = _normalizeWorkflow(
            Map<String, dynamic>.from(
              (response['workflow'] as Map?)?.cast<String, dynamic>() ??
                  _defaultWorkflow(),
            ),
          );
          _normalizeLegacySimpleResponseType();
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
        setState(() {
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
            _captureInitialEditSnapshot();
          }
        });
        return;
      }

      final currentCommand = command;
      if (!mounted) return;
      setState(() {
        _commandName = currentCommand.name;
        _commandDescription = currentCommand.description;
        _commandType = currentCommand.type;
        final storedOptions =
            data is Map
                ? Map<String, dynamic>.from(
                  data.cast<String, dynamic>(),
                )['options']
                : null;
        if (storedOptions is List) {
          _options = deserializeCommandOptions(storedOptions);
        } else if (currentCommand.options != null) {
          _options = currentCommand.options!
              .map(_buildOptionFromApplicationOption)
              .toList(growable: false);
        } else {
          _options = [];
        }
        _integrationTypes =
            currentCommand.integrationTypes.map((e) {
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
          _defaultMemberPermissions =
              currentCommand.defaultMemberPermissions!.value.toString();
        }
        if (!_supportsSimpleMode) {
          _editorMode = _editorModeAdvanced;
        }
        if (_containsHierarchyOption(_options)) {
          _editorMode = _editorModeAdvanced;
        }
        _syncSubcommandWorkflowRoutes();
        _captureInitialEditSnapshot();
        _isLoading = false;
      });
    } else {
      setState(() {
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

    final simpleValidationError =
        _isSimpleMode
            ? validateSimpleModeConfig(
              _simpleModeConfig,
              translate: AppStrings.t,
            )
            : null;
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

    if (client == null) {
      developer.log(
        '[_updateOrCreate] no Discord client — saving locally only (botId=$botId existingId=$existingStorageId localOnly=$_localOnlyCommand)',
        name: 'CommandCreatePage',
      );
      final localCommandId =
          existingStorageId ??
          (_localOnlyCommand
              ? _generateLegacyOnlyCommandId()
              : DateTime.now().microsecondsSinceEpoch.toString());
      developer.log(
        '[_updateOrCreate] saving local commandId=$localCommandId',
        name: 'CommandCreatePage',
      );
      await saveLocal(localCommandId);
      developer.log(
        '[_updateOrCreate] local save done, popping.',
        name: 'CommandCreatePage',
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      return;
    }

    try {
      if (_localOnlyCommand) {
        developer.log(
          '[_updateOrCreate] _localOnlyCommand=true, saving locally (botId=$botId existingId=$existingStorageId)',
          name: 'CommandCreatePage',
        );
        final localCommandId =
            existingStorageId ?? _generateLegacyOnlyCommandId();
        developer.log(
          '[_updateOrCreate] saving local commandId=$localCommandId',
          name: 'CommandCreatePage',
        );
        await saveLocal(localCommandId);
        developer.log(
          '[_updateOrCreate] local-only save done, popping.',
          name: 'CommandCreatePage',
        );
        if (!mounted) {
          return;
        }

        Navigator.pop(context);
        return;
      }

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
        developer.log(
          '[_updateOrCreate] triggering cloud sync after create (botId=$botId)',
          name: 'CommandCreatePage',
        );
        final cloudSyncOk = await _syncCommandChangesToCloud(botId: botId);
        developer.log(
          '[_updateOrCreate] cloud sync after create result=$cloudSyncOk (botId=$botId)',
          name: 'CommandCreatePage',
        );
        if (!cloudSyncOk && mounted) {
          developer.log(
            '[_updateOrCreate] showing cloud sync failure snackbar (create path, botId=$botId)',
            name: 'CommandCreatePage',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details(
                  'Cloud sync failed. Your command is saved locally but not yet deployed to Bot Creator servers.',
                ),
              ),
            ),
          );
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
        developer.log(
          '[_updateOrCreate] triggering cloud sync after update (botId=$botId)',
          name: 'CommandCreatePage',
        );
        final cloudSyncOk = await _syncCommandChangesToCloud(botId: botId);
        developer.log(
          '[_updateOrCreate] cloud sync after update result=$cloudSyncOk (botId=$botId)',
          name: 'CommandCreatePage',
        );
        if (!cloudSyncOk && mounted) {
          developer.log(
            '[_updateOrCreate] showing cloud sync failure snackbar (update path, botId=$botId)',
            name: 'CommandCreatePage',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details(
                  'Cloud sync failed. Your command is saved locally but not yet deployed to Bot Creator servers.',
                ),
              ),
            ),
          );
        }
      }
      developer.log(
        '[_updateOrCreate] SUCCESS — popping (botId=$botId commandName="$_commandName")',
        name: 'CommandCreatePage',
      );
      Navigator.pop(context);
    } catch (e) {
      developer.log(
        '[_updateOrCreate] EXCEPTION caught — falling back to local save (botId=$botId commandName="$_commandName"): $e',
        name: 'CommandCreatePage',
      );
      final localCommandId =
          existingStorageId ?? DateTime.now().microsecondsSinceEpoch.toString();
      developer.log(
        '[_updateOrCreate] fallback local save commandId=$localCommandId',
        name: 'CommandCreatePage',
      );
      await saveLocal(localCommandId);
      final errorText = context.tr.command_sync_failed_local('$e');
      final dialog = AlertDialog(
        title: Text(context.tr.error),
        content: Text(errorText),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final guardDiscardOnPop = _showEditShell && _isDirty;
    final showStickyEditSave =
        _showEditShell &&
        _isEditingExistingCommand &&
        !_isLoading &&
        !_isDataIncomplete;

    return PopScope(
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
          backgroundColor: AppTheme.brandPrimary,
          actions: [
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
                icon: const Icon(Icons.add),
                tooltip: context.tr.cmd_create_tooltip,
                onPressed: () {
                  if (_validateCommandInputs()) {
                    _updateOrCreate();
                  }
                },
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
        bottomNavigationBar:
            showStickyEditSave
                ? SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      border: Border(
                        top: BorderSide(
                          color: Theme.of(
                            context,
                          ).dividerColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _isDirty ? _saveExistingCommand : null,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          _isDirty
                              ? context.tr.edit_shell_save_changes
                              : context.tr.edit_shell_all_saved,
                        ),
                      ),
                    ),
                  ),
                )
                : null,
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentMaxWidth =
                  constraints.maxWidth >= 1200
                      ? 980.0
                      : (constraints.maxWidth >= 900 ? 860.0 : 680.0);

              return Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    showStickyEditSave ? 116 : 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentMaxWidth),
                    child:
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _isDataIncomplete
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warning,
                                    border: Border.all(color: AppTheme.warning),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.radiusMd,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppTheme.warning,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          context
                                              .tr
                                              .cmd_offline_incomplete_warning,
                                          style: TextStyle(
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
                                      _commandName.isNotEmpty
                                          ? _commandName
                                          : (_existingCommandStorageId ?? ''),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle:
                                        _commandDescription.isNotEmpty
                                            ? Text(_commandDescription)
                                            : null,
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.menu_book_outlined,
                                      ),
                                      tooltip: context.tr.cmd_show_variables,
                                      onPressed: _openDocumentationCenter,
                                    ),
                                  ),
                                ),
                              ],
                            )
                            : _buildBlockEditor(
                              contentMaxWidth: contentMaxWidth,
                            ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
