import 'package:flutter/foundation.dart';
import 'package:nyxx/nyxx.dart';

import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/logic/simple_mode.dart';
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
    this.editorMode = 'simple',
    this.executionMode = 'workflow',
    this.bdfdScriptContent = '',
    this.bdfdCompileResult,
    this.legacyModeEnabled = false,
    this.localOnlyCommand = false,
    this.folder = '',
    this.legacyPrefixOverride = '',
    this.legacyResponseTarget = 'reply',
    this.simpleDeleteMessages = false,
    this.simpleKickUser = false,
    this.simpleBanUser = false,
    this.simpleUnbanUser = false,
    this.simpleMuteUser = false,
    this.simpleUnmuteUser = false,
    this.simpleAddRole = false,
    this.simpleRemoveRole = false,
    this.simpleSendMessage = false,
    this.simplePinMessage = false,
    this.simpleUnpinMessage = false,
    this.simpleCreateInvite = false,
    this.simpleCreatePoll = false,
    this.simpleSendMessageText = '',
    this.simpleActionReason = '',
    this.simpleMuteDuration = '10m',
    this.simpleBanDeleteDays = '0',
    this.simpleDeleteMessagesDefaultCount = '1',
    this.simpleInviteMaxAge = '86400',
    this.simpleInviteMaxUses = '0',
    this.simpleInviteTemporary = false,
    this.simpleInviteUnique = false,
    this.simplePollAnswersText = 'Yes\nNo',
    this.simplePollDurationHours = '24',
    this.simplePollAllowMultiselect = false,
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
  final BdfdCompileResult? bdfdCompileResult;

  // ── Legacy mode ──
  final bool legacyModeEnabled;
  final bool localOnlyCommand;
  final String folder;
  final String legacyPrefixOverride;
  final String legacyResponseTarget;

  // ── Simple mode toggles ──
  final bool simpleDeleteMessages;
  final bool simpleKickUser;
  final bool simpleBanUser;
  final bool simpleUnbanUser;
  final bool simpleMuteUser;
  final bool simpleUnmuteUser;
  final bool simpleAddRole;
  final bool simpleRemoveRole;
  final bool simpleSendMessage;
  final bool simplePinMessage;
  final bool simpleUnpinMessage;
  final bool simpleCreateInvite;
  final bool simpleCreatePoll;
  final String simpleSendMessageText;
  final String simpleActionReason;
  final String simpleMuteDuration;
  final String simpleBanDeleteDays;
  final String simpleDeleteMessagesDefaultCount;
  final String simpleInviteMaxAge;
  final String simpleInviteMaxUses;
  final bool simpleInviteTemporary;
  final bool simpleInviteUnique;
  final String simplePollAnswersText;
  final String simplePollDurationHours;
  final bool simplePollAllowMultiselect;

  // ── Subcommand workflows ──
  final Map<String, Map<String, dynamic>> subcommandWorkflows;
  final String activeSubcommandRoute;
  final bool isApplyingWorkflowPayload;

  // ── Wizard ──
  final int currentEditorStep;
  final bool showQuickStartBuilder;
  final String initialEditSnapshot;

  // ── Derived getters ──

  bool get isSimpleMode => editorMode == 'simple';
  bool get isBdfdScriptMode => executionMode == 'bdfd_script';

  List<BdfdCompileDiagnostic> get bdfdDiagnostics =>
      bdfdCompileResult?.diagnostics ?? const <BdfdCompileDiagnostic>[];

  bool get hasBdfdCompileErrors => bdfdDiagnostics.any(
    (d) => d.severity == BdfdCompileDiagnosticSeverity.error,
  );

  bool get supportsCommandDescription =>
      commandType == ApplicationCommandType.chatInput;

  bool get supportsCommandOptions =>
      commandType == ApplicationCommandType.chatInput;

  bool get supportsSimpleMode =>
      commandType == ApplicationCommandType.chatInput;

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

  SimpleModeConfig get simpleModeConfig => SimpleModeConfig(
    deleteMessages: simpleDeleteMessages,
    kickUser: simpleKickUser,
    banUser: simpleBanUser,
    unbanUser: simpleUnbanUser,
    muteUser: simpleMuteUser,
    unmuteUser: simpleUnmuteUser,
    addRole: simpleAddRole,
    removeRole: simpleRemoveRole,
    sendMessage: simpleSendMessage,
    pinMessage: simplePinMessage,
    unpinMessage: simpleUnpinMessage,
    createInvite: simpleCreateInvite,
    createPoll: simpleCreatePoll,
    sendMessageText: simpleSendMessageText,
    actionReason: simpleActionReason,
    muteDuration: simpleMuteDuration,
    banDeleteMessageDays: simpleBanDeleteDays,
    deleteMessagesDefaultCount: simpleDeleteMessagesDefaultCount,
    inviteMaxAge: simpleInviteMaxAge,
    inviteMaxUses: simpleInviteMaxUses,
    inviteTemporary: simpleInviteTemporary,
    inviteUnique: simpleInviteUnique,
    pollAnswersText: simplePollAnswersText,
    pollDurationHours: simplePollDurationHours,
    pollAllowMultiselect: simplePollAllowMultiselect,
  );

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
    BdfdCompileResult? bdfdCompileResult,
    bool? legacyModeEnabled,
    bool? localOnlyCommand,
    String? folder,
    String? legacyPrefixOverride,
    String? legacyResponseTarget,
    bool? simpleDeleteMessages,
    bool? simpleKickUser,
    bool? simpleBanUser,
    bool? simpleUnbanUser,
    bool? simpleMuteUser,
    bool? simpleUnmuteUser,
    bool? simpleAddRole,
    bool? simpleRemoveRole,
    bool? simpleSendMessage,
    bool? simplePinMessage,
    bool? simpleUnpinMessage,
    bool? simpleCreateInvite,
    bool? simpleCreatePoll,
    String? simpleSendMessageText,
    String? simpleActionReason,
    String? simpleMuteDuration,
    String? simpleBanDeleteDays,
    String? simpleDeleteMessagesDefaultCount,
    String? simpleInviteMaxAge,
    String? simpleInviteMaxUses,
    bool? simpleInviteTemporary,
    bool? simpleInviteUnique,
    String? simplePollAnswersText,
    String? simplePollDurationHours,
    bool? simplePollAllowMultiselect,
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
      bdfdCompileResult: bdfdCompileResult ?? this.bdfdCompileResult,
      legacyModeEnabled: legacyModeEnabled ?? this.legacyModeEnabled,
      localOnlyCommand: localOnlyCommand ?? this.localOnlyCommand,
      folder: folder ?? this.folder,
      legacyPrefixOverride: legacyPrefixOverride ?? this.legacyPrefixOverride,
      legacyResponseTarget: legacyResponseTarget ?? this.legacyResponseTarget,
      simpleDeleteMessages: simpleDeleteMessages ?? this.simpleDeleteMessages,
      simpleKickUser: simpleKickUser ?? this.simpleKickUser,
      simpleBanUser: simpleBanUser ?? this.simpleBanUser,
      simpleUnbanUser: simpleUnbanUser ?? this.simpleUnbanUser,
      simpleMuteUser: simpleMuteUser ?? this.simpleMuteUser,
      simpleUnmuteUser: simpleUnmuteUser ?? this.simpleUnmuteUser,
      simpleAddRole: simpleAddRole ?? this.simpleAddRole,
      simpleRemoveRole: simpleRemoveRole ?? this.simpleRemoveRole,
      simpleSendMessage: simpleSendMessage ?? this.simpleSendMessage,
      simplePinMessage: simplePinMessage ?? this.simplePinMessage,
      simpleUnpinMessage: simpleUnpinMessage ?? this.simpleUnpinMessage,
      simpleCreateInvite: simpleCreateInvite ?? this.simpleCreateInvite,
      simpleCreatePoll: simpleCreatePoll ?? this.simpleCreatePoll,
      simpleSendMessageText:
          simpleSendMessageText ?? this.simpleSendMessageText,
      simpleActionReason: simpleActionReason ?? this.simpleActionReason,
      simpleMuteDuration: simpleMuteDuration ?? this.simpleMuteDuration,
      simpleBanDeleteDays: simpleBanDeleteDays ?? this.simpleBanDeleteDays,
      simpleDeleteMessagesDefaultCount:
          simpleDeleteMessagesDefaultCount ??
          this.simpleDeleteMessagesDefaultCount,
      simpleInviteMaxAge: simpleInviteMaxAge ?? this.simpleInviteMaxAge,
      simpleInviteMaxUses: simpleInviteMaxUses ?? this.simpleInviteMaxUses,
      simpleInviteTemporary:
          simpleInviteTemporary ?? this.simpleInviteTemporary,
      simpleInviteUnique: simpleInviteUnique ?? this.simpleInviteUnique,
      simplePollAnswersText:
          simplePollAnswersText ?? this.simplePollAnswersText,
      simplePollDurationHours:
          simplePollDurationHours ?? this.simplePollDurationHours,
      simplePollAllowMultiselect:
          simplePollAllowMultiselect ?? this.simplePollAllowMultiselect,
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
