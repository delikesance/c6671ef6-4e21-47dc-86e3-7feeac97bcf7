import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/logic/command_editor_state.dart';
import 'package:bot_creator/features/bot_editor/logic/simple_mode.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:nyxx/nyxx.dart';

/// Notifier for [CommandEditorState] — replaces the mutable fields and
/// `setState` calls in `_CommandCreatePageState`.
///
/// Usage:
/// ```dart
/// final notifier = context.watch<CommandEditorNotifier>();
/// final name = context.select((CommandEditorNotifier n) => n.state.commandName);
/// ```
class CommandEditorNotifier extends ChangeNotifier {
  CommandEditorNotifier({BdfdCompiler? bdfdCompiler})
    : _bdfdCompiler = bdfdCompiler ?? BdfdCompiler();

  final BdfdCompiler _bdfdCompiler;

  CommandEditorState _state = const CommandEditorState();
  CommandEditorState get state => _state;

  bool _batching = false;

  // ── Bulk state replacement (for initialization) ──

  void replaceState(CommandEditorState newState) {
    _state = newState;
    notifyListeners();
  }

  /// Executes [transform] to produce a new state, then notifies once.
  /// During the transform, individual setters will NOT notify.
  void batchUpdate(CommandEditorState Function(CommandEditorState) transform) {
    beginBatch();
    try {
      _state = transform(_state);
    } finally {
      endBatch();
    }
  }

  /// Suppresses notifications until [endBatch] is called.
  void beginBatch() {
    _batching = true;
  }

  /// Re-enables notifications and fires a single notification.
  void endBatch() {
    _batching = false;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_batching) return;
    super.notifyListeners();
  }

  // ── Granular updates ──

  void updateCommandName(String name) {
    _state = _state.copyWith(commandName: name);
    notifyListeners();
  }

  void updateCommandDescription(String description) {
    _state = _state.copyWith(commandDescription: description);
    notifyListeners();
  }

  void updateCommandType(ApplicationCommandType type) {
    _state = _state.copyWith(commandType: type);
    notifyListeners();
  }

  void updateOptions(List<CommandOptionBuilder> options) {
    _state = _state.copyWith(options: options);
    notifyListeners();
  }

  void updateResponse(String response) {
    _state = _state.copyWith(response: response);
    notifyListeners();
  }

  void updateResponseType(String type) {
    _state = _state.copyWith(responseType: type);
    notifyListeners();
  }

  void updateResponseEmbeds(List<Map<String, dynamic>> embeds) {
    _state = _state.copyWith(responseEmbeds: embeds);
    notifyListeners();
  }

  void updateResponseComponents(Map<String, dynamic> components) {
    _state = _state.copyWith(responseComponents: components);
    notifyListeners();
  }

  void updateResponseModal(Map<String, dynamic> modal) {
    _state = _state.copyWith(responseModal: modal);
    notifyListeners();
  }

  void updateActions(List<Map<String, dynamic>> actions) {
    _state = _state.copyWith(actions: actions);
    notifyListeners();
  }

  void addAction(Map<String, dynamic> action) {
    _state = _state.copyWith(actions: [..._state.actions, action]);
    notifyListeners();
  }

  void removeAction(int index) {
    if (index < 0 || index >= _state.actions.length) return;
    final newActions = List<Map<String, dynamic>>.from(_state.actions);
    newActions.removeAt(index);
    _state = _state.copyWith(actions: newActions);
    notifyListeners();
  }

  void moveActionUp(int index) {
    if (index <= 0 || index >= _state.actions.length) return;
    final newActions = List<Map<String, dynamic>>.from(_state.actions);
    final item = newActions.removeAt(index);
    newActions.insert(index - 1, item);
    _state = _state.copyWith(actions: newActions);
    notifyListeners();
  }

  void moveActionDown(int index) {
    if (index < 0 || index >= _state.actions.length - 1) return;
    final newActions = List<Map<String, dynamic>>.from(_state.actions);
    final item = newActions.removeAt(index);
    newActions.insert(index + 1, item);
    _state = _state.copyWith(actions: newActions);
    notifyListeners();
  }

  void updateResponseWorkflow(Map<String, dynamic> workflow) {
    _state = _state.copyWith(responseWorkflow: workflow);
    notifyListeners();
  }

  void updateEditorMode(String mode) {
    _state = _state.copyWith(editorMode: mode);
    notifyListeners();
  }

  void updateExecutionMode(String mode) {
    _state = _state.copyWith(executionMode: mode);
    notifyListeners();
  }

  void updateBdfdScriptContent(String content) {
    final result = _bdfdCompiler.compile(content);
    _state = _state.copyWith(
      bdfdScriptContent: content,
      bdfdCompileResult: result,
    );
    notifyListeners();
  }

  void refreshBdfdCompileResult(String source) {
    final result = _bdfdCompiler.compile(source);
    _state = _state.copyWith(
      bdfdScriptContent: source,
      bdfdCompileResult: result,
    );
    notifyListeners();
  }

  void updateLegacyModeEnabled(bool enabled) {
    _state = _state.copyWith(legacyModeEnabled: enabled);
    notifyListeners();
  }

  void updateLocalOnlyCommand(bool localOnly) {
    _state = _state.copyWith(localOnlyCommand: localOnly);
    notifyListeners();
  }

  void updateFolder(String folder) {
    _state = _state.copyWith(folder: folder);
    notifyListeners();
  }

  void updateLegacyPrefixOverride(String prefix) {
    _state = _state.copyWith(legacyPrefixOverride: prefix);
    notifyListeners();
  }

  void updateLegacyResponseTarget(String target) {
    _state = _state.copyWith(legacyResponseTarget: target);
    notifyListeners();
  }

  void updateIntegrationTypes(List<ApplicationIntegrationType> types) {
    _state = _state.copyWith(integrationTypes: types);
    notifyListeners();
  }

  void updateContexts(List<InteractionContextType> contexts) {
    _state = _state.copyWith(contexts: contexts);
    notifyListeners();
  }

  void updateDefaultMemberPermissions(String permissions) {
    _state = _state.copyWith(defaultMemberPermissions: permissions);
    notifyListeners();
  }

  void updateIsLoading(bool loading) {
    _state = _state.copyWith(isLoading: loading);
    notifyListeners();
  }

  void updateAppEmojis(List<AppEmoji> emojis) {
    _state = _state.copyWith(appEmojis: emojis);
    notifyListeners();
  }

  void updateIsDataIncomplete(bool incomplete) {
    _state = _state.copyWith(isDataIncomplete: incomplete);
    notifyListeners();
  }

  void updateIsLocalOnlyCommand(bool localOnly) {
    _state = _state.copyWith(isLocalOnlyCommand: localOnly);
    notifyListeners();
  }

  void updatePersistedGlobalVariableNames(Set<String> names) {
    _state = _state.copyWith(persistedGlobalVariableNames: names);
    notifyListeners();
  }

  void updateScopedVariableSuggestionNames(Set<String> names) {
    _state = _state.copyWith(scopedVariableSuggestionNames: names);
    notifyListeners();
  }

  void updateSubcommandWorkflows(Map<String, Map<String, dynamic>> workflows) {
    _state = _state.copyWith(subcommandWorkflows: workflows);
    notifyListeners();
  }

  void updateActiveSubcommandRoute(String route) {
    _state = _state.copyWith(activeSubcommandRoute: route);
    notifyListeners();
  }

  void updateIsApplyingWorkflowPayload(bool applying) {
    _state = _state.copyWith(isApplyingWorkflowPayload: applying);
    notifyListeners();
  }

  void updateCurrentEditorStep(int step) {
    _state = _state.copyWith(currentEditorStep: step);
    notifyListeners();
  }

  void updateShowQuickStartBuilder(bool show) {
    _state = _state.copyWith(showQuickStartBuilder: show);
    notifyListeners();
  }

  void updateInitialEditSnapshot(String snapshot) {
    _state = _state.copyWith(initialEditSnapshot: snapshot);
    notifyListeners();
  }

  // ── Simple mode updates ──

  void updateSimpleConfig(SimpleModeConfig config) {
    _state = _state.copyWith(
      simpleDeleteMessages: config.deleteMessages,
      simpleKickUser: config.kickUser,
      simpleBanUser: config.banUser,
      simpleUnbanUser: config.unbanUser,
      simpleMuteUser: config.muteUser,
      simpleUnmuteUser: config.unmuteUser,
      simpleAddRole: config.addRole,
      simpleRemoveRole: config.removeRole,
      simpleSendMessage: config.sendMessage,
      simplePinMessage: config.pinMessage,
      simpleUnpinMessage: config.unpinMessage,
      simpleCreateInvite: config.createInvite,
      simpleCreatePoll: config.createPoll,
      simpleSendMessageText: config.sendMessageText,
      simpleActionReason: config.actionReason,
      simpleMuteDuration: config.muteDuration,
      simpleBanDeleteDays: config.banDeleteMessageDays,
      simpleDeleteMessagesDefaultCount: config.deleteMessagesDefaultCount,
      simpleInviteMaxAge: config.inviteMaxAge,
      simpleInviteMaxUses: config.inviteMaxUses,
      simpleInviteTemporary: config.inviteTemporary,
      simpleInviteUnique: config.inviteUnique,
      simplePollAnswersText: config.pollAnswersText,
      simplePollDurationHours: config.pollDurationHours,
      simplePollAllowMultiselect: config.pollAllowMultiselect,
    );
    notifyListeners();
  }

  void updateSimpleToggle(String key, bool value) {
    switch (key) {
      case 'deleteMessages':
        _state = _state.copyWith(simpleDeleteMessages: value);
      case 'kickUser':
        _state = _state.copyWith(simpleKickUser: value);
      case 'banUser':
        _state = _state.copyWith(simpleBanUser: value);
      case 'unbanUser':
        _state = _state.copyWith(simpleUnbanUser: value);
      case 'muteUser':
        _state = _state.copyWith(simpleMuteUser: value);
      case 'unmuteUser':
        _state = _state.copyWith(simpleUnmuteUser: value);
      case 'addRole':
        _state = _state.copyWith(simpleAddRole: value);
      case 'removeRole':
        _state = _state.copyWith(simpleRemoveRole: value);
      case 'sendMessage':
        _state = _state.copyWith(simpleSendMessage: value);
      case 'pinMessage':
        _state = _state.copyWith(simplePinMessage: value);
      case 'unpinMessage':
        _state = _state.copyWith(simpleUnpinMessage: value);
      case 'createInvite':
        _state = _state.copyWith(simpleCreateInvite: value);
      case 'createPoll':
        _state = _state.copyWith(simpleCreatePoll: value);
    }
    notifyListeners();
  }

  // ── Snapshot helpers ──

  /// Builds a JSON snapshot of the current editor state for dirty-checking.
  String buildEditSnapshot() {
    final s = _state;
    final integrationTypes = s.integrationTypes
      .map(_integrationTypeToText)
      .toList(growable: false)..sort();
    final contexts = s.contexts.map(_contextTypeToText).toList(growable: false)
      ..sort();

    final snapshot = <String, dynamic>{
      'name': s.commandName,
      'description': s.effectiveCommandDescription,
      'commandType': _commandTypeToText(s.commandType),
      'folder': s.folder.trim(),
      'integrationTypes': integrationTypes,
      'contexts': contexts,
    };

    return jsonEncode(snapshot);
  }

  static String _commandTypeToText(ApplicationCommandType type) {
    switch (type) {
      case ApplicationCommandType.chatInput:
        return 'chatInput';
      case ApplicationCommandType.user:
        return 'user';
      case ApplicationCommandType.message:
        return 'message';
      default:
        return 'chatInput';
    }
  }

  static String _integrationTypeToText(ApplicationIntegrationType type) {
    switch (type) {
      case ApplicationIntegrationType.guildInstall:
        return 'guildInstall';
      case ApplicationIntegrationType.userInstall:
        return 'userInstall';
      default:
        return 'guildInstall';
    }
  }

  static String _contextTypeToText(InteractionContextType type) {
    switch (type) {
      case InteractionContextType.guild:
        return 'guild';
      case InteractionContextType.botDm:
        return 'botDm';
      case InteractionContextType.privateChannel:
        return 'privateChannel';
      default:
        return 'guild';
    }
  }
}
