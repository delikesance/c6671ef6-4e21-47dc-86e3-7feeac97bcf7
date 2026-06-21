import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart';

import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';

/// Immutable state for the command editor.
///
/// Replaces the ~50 mutable fields previously in `_CommandCreatePageState`.
/// Use [CommandEditorNotifier] to mutate and notify listeners.
@immutable
class CommandEditorState {
  const CommandEditorState({
    this.commandName = '',
    this.commandDescription = '',
    this.commandType = ApplicationCommandType.chatInput,
    this.options = const [],
    this.response = '',
    this.responseType = 'message',
    this.responseEmbeds = const [],
    this.responseComponents = const {},
    this.responseModal = const {},
    this.actions = const [],
    this.responseWorkflow = const {},
    this.persistedGlobalVariableNames = const {},
    this.scopedVariableSuggestionNames = const {
      'guild.key',
      'user.key',
      'channel.key',
      'guildMember.key',
      'message.key',
    },
    this.isLoading = true,
    this.appEmojis = const [],
    this.isDataIncomplete = false,
    this.isLocalOnlyCommand = false,
    this.integrationTypes = const [ApplicationIntegrationType.guildInstall],
    this.contexts = const [InteractionContextType.guild],
    this.defaultMemberPermissions = '',
    this.editorMode = 'advanced',
    this.executionMode = 'workflow',
    this.bdfdScriptContent = '',
    this.jsScriptContent = '',
    this.bdfdCompileResult,
    this.legacyModeEnabled = false,
    this.localOnlyCommand = false,
    this.folder = '',
    this.legacyPrefixOverride = '',
    this.legacyResponseTarget = 'reply',
    this.subcommandWorkflows = const {},
    this.activeSubcommandRoute = '__root__',
    this.isApplyingWorkflowPayload = false,
    this.currentEditorStep = 0,
    this.showQuickStartBuilder = false,
    this.initialEditSnapshot = '',
  });

  // ── Core fields ──
  final String commandName;
  final String commandDescription;
  final ApplicationCommandType commandType;
  final List<CommandOptionBuilder> options;
  final String response;
  final String responseType;
  final List<Map<String, dynamic>> responseEmbeds;
  final Map<String, dynamic> responseComponents;
  final Map<String, dynamic> responseModal;
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic> responseWorkflow;

  // ── Variable suggestions ──
  final Set<String> persistedGlobalVariableNames;
  final Set<String> scopedVariableSuggestionNames;

  // ── Loading & error state ──
  final bool isLoading;
  final List<AppEmoji> appEmojis;
  final bool isDataIncomplete;
  final bool isLocalOnlyCommand;

  // ── Discord integration ──
  final List<ApplicationIntegrationType> integrationTypes;
  final List<InteractionContextType> contexts;
  final String defaultMemberPermissions;

  // ── Editor mode ──
  final String editorMode;
  final String executionMode;
  final String bdfdScriptContent;
  final String jsScriptContent;
  final BdfdCompileResult? bdfdCompileResult;

  // ── Legacy mode ──
  final bool legacyModeEnabled;
  final bool localOnlyCommand;
  final String folder;
  final String legacyPrefixOverride;
  final String legacyResponseTarget;

  // ── Subcommand workflows ──
  final Map<String, Map<String, dynamic>> subcommandWorkflows;
  final String activeSubcommandRoute;
  final bool isApplyingWorkflowPayload;

  // ── Wizard ──
  final int currentEditorStep;
  final bool showQuickStartBuilder;
  final String initialEditSnapshot;

  // ── Derived getters ──

  bool get isSimpleMode => false;
  bool get isBdfdScriptMode => executionMode == 'bdfd_script';
  bool get isJsScriptMode => false;

  List<BdfdCompileDiagnostic> get bdfdDiagnostics =>
      bdfdCompileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get hasBdfdCompileErrors => bdfdDiagnostics.any(
    (d) => d.severity == BdfdCompileDiagnosticSeverity.error,
  );

  bool get supportsCommandDescription =>
      commandType == ApplicationCommandType.chatInput;

  bool get supportsCommandOptions =>
      commandType == ApplicationCommandType.chatInput;

  bool get supportsSimpleMode => false;

  bool get allowModalResponses => !legacyModeEnabled;

  bool get allowsInternalLegacyCallbackNames =>
      commandType == ApplicationCommandType.chatInput &&
      legacyModeEnabled &&
      localOnlyCommand;

  int get commandNameMaxLength => allowsInternalLegacyCallbackNames ? 256 : 32;

  bool get isAwaitedCallbackCommand => _isAwaitedCallbackTrigger(commandName);

  bool get requiresCommandDescription =>
      supportsCommandDescription && !isAwaitedCallbackCommand;

  String get effectiveCommandDescription =>
      supportsCommandDescription ? commandDescription : '';

  bool get showEditShell => !isDataIncomplete && !isLoading;

  bool get isDirty {
    if (!showEditShell || initialEditSnapshot.isEmpty) return false;
    return true; // Computed externally via _buildEditSnapshot
  }

  CommandEditorState copyWith({
    String? commandName,
    String? commandDescription,
    ApplicationCommandType? commandType,
    List<CommandOptionBuilder>? options,
    String? response,
    String? responseType,
    List<Map<String, dynamic>>? responseEmbeds,
    Map<String, dynamic>? responseComponents,
    Map<String, dynamic>? responseModal,
    List<Map<String, dynamic>>? actions,
    Map<String, dynamic>? responseWorkflow,
    Set<String>? persistedGlobalVariableNames,
    Set<String>? scopedVariableSuggestionNames,
    bool? isLoading,
    List<AppEmoji>? appEmojis,
    bool? isDataIncomplete,
    bool? isLocalOnlyCommand,
    List<ApplicationIntegrationType>? integrationTypes,
    List<InteractionContextType>? contexts,
    String? defaultMemberPermissions,
    String? editorMode,
    String? executionMode,
    String? bdfdScriptContent,
    String? jsScriptContent,
    BdfdCompileResult? bdfdCompileResult,
    bool? legacyModeEnabled,
    bool? localOnlyCommand,
    String? folder,
    String? legacyPrefixOverride,
    String? legacyResponseTarget,
    Map<String, Map<String, dynamic>>? subcommandWorkflows,
    String? activeSubcommandRoute,
    bool? isApplyingWorkflowPayload,
    int? currentEditorStep,
    bool? showQuickStartBuilder,
    String? initialEditSnapshot,
  }) {
    return CommandEditorState(
      commandName: commandName ?? this.commandName,
      commandDescription: commandDescription ?? this.commandDescription,
      commandType: commandType ?? this.commandType,
      options: options ?? this.options,
      response: response ?? this.response,
      responseType: responseType ?? this.responseType,
      responseEmbeds: responseEmbeds ?? this.responseEmbeds,
      responseComponents: responseComponents ?? this.responseComponents,
      responseModal: responseModal ?? this.responseModal,
      actions: actions ?? this.actions,
      responseWorkflow: responseWorkflow ?? this.responseWorkflow,
      persistedGlobalVariableNames:
          persistedGlobalVariableNames ?? this.persistedGlobalVariableNames,
      scopedVariableSuggestionNames:
          scopedVariableSuggestionNames ?? this.scopedVariableSuggestionNames,
      isLoading: isLoading ?? this.isLoading,
      appEmojis: appEmojis ?? this.appEmojis,
      isDataIncomplete: isDataIncomplete ?? this.isDataIncomplete,
      isLocalOnlyCommand: isLocalOnlyCommand ?? this.isLocalOnlyCommand,
      integrationTypes: integrationTypes ?? this.integrationTypes,
      contexts: contexts ?? this.contexts,
      defaultMemberPermissions:
          defaultMemberPermissions ?? this.defaultMemberPermissions,
      editorMode: editorMode ?? this.editorMode,
      executionMode: executionMode ?? this.executionMode,
      bdfdScriptContent: bdfdScriptContent ?? this.bdfdScriptContent,
      jsScriptContent: jsScriptContent ?? this.jsScriptContent,
      bdfdCompileResult: bdfdCompileResult ?? this.bdfdCompileResult,
      legacyModeEnabled: legacyModeEnabled ?? this.legacyModeEnabled,
      localOnlyCommand: localOnlyCommand ?? this.localOnlyCommand,
      folder: folder ?? this.folder,
      legacyPrefixOverride: legacyPrefixOverride ?? this.legacyPrefixOverride,
      legacyResponseTarget: legacyResponseTarget ?? this.legacyResponseTarget,
      subcommandWorkflows: subcommandWorkflows ?? this.subcommandWorkflows,
      activeSubcommandRoute:
          activeSubcommandRoute ?? this.activeSubcommandRoute,
      isApplyingWorkflowPayload:
          isApplyingWorkflowPayload ?? this.isApplyingWorkflowPayload,
      currentEditorStep: currentEditorStep ?? this.currentEditorStep,
      showQuickStartBuilder:
          showQuickStartBuilder ?? this.showQuickStartBuilder,
      initialEditSnapshot: initialEditSnapshot ?? this.initialEditSnapshot,
    );
  }

  static final RegExp _awaitedCommandTriggerPattern = RegExp(
    r'^\$awaitedcommand\[(.+?);(.*)\]$',
    caseSensitive: false,
  );
  static final RegExp _awaitedCommandErrorTriggerPattern = RegExp(
    r'^\$awaitedcommanderror\[(.+?)\]$',
    caseSensitive: false,
  );

  static bool _isAwaitedCallbackTrigger(String value) {
    final normalized = value.trim();
    return _awaitedCommandTriggerPattern.hasMatch(normalized) ||
        _awaitedCommandErrorTriggerPattern.hasMatch(normalized);
  }
}
