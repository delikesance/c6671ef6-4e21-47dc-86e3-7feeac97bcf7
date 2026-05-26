import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'builder/action_types.dart';
import 'builder/action_type_extension.dart';
import 'builder/action_summary.dart';

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';

export 'builder/action_types.dart';
export 'builder/action_type_extension.dart';
export 'builder/action_card.dart';

class ActionsBuilderPage extends StatefulWidget {
  final List<Map<String, dynamic>> initialActions;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final String? botIdForConfig;
  final List<String> editPath;
  final ValueChanged<List<Map<String, dynamic>>>? onChanged;
  final bool isInteraction;
  final bool isWorkflow;

  const ActionsBuilderPage({
    super.key,
    this.initialActions = const [],
    this.variableSuggestions = const [],
    this.emojiSuggestions,
    this.botIdForConfig,
    this.editPath = const [],
    this.onChanged,
    this.isInteraction = true,
    this.isWorkflow = false,
  });

  @override
  State<ActionsBuilderPage> createState() => _ActionsBuilderPageState();
}

class _ActionsBuilderPageState extends State<ActionsBuilderPage> {
  final List<ActionItem> _actions = [];
  final Map<String, int> _fieldRefreshVersions = {};
  int _actionCounter = 0;
  String _desktopActionSearch = '';

  @override
  void initState() {
    super.initState();
    for (final action in widget.initialActions) {
      final item = ActionItem.fromJson(
        action,
        fallbackId: 'action_$_actionCounter',
      );
      _actions.add(item);
      _actionCounter++;
    }
  }

  void _triggerOnChanged() {
    if (widget.onChanged != null) {
      final payload = _actions.map((action) => action.toJson()).toList();
      widget.onChanged!(payload);
    }
  }

  void _addAction(BotCreatorActionType type) {
    setState(() {
      final newId = 'action_${_actionCounter++}';
      _actions.add(
        ActionItem(
          id: newId,
          type: type,
          parameters: Map.from(type.defaultParameters),
          actionKey: newId,
        ),
      );
    });
    _triggerOnChanged();
  }

  void _removeAction(String actionId) {
    setState(() {
      final index = _actions.indexWhere((action) => action.id == actionId);
      if (index != -1) {
        _actions.removeAt(index);
      }
      _fieldRefreshVersions.removeWhere(
        (compositeKey, _) => compositeKey.startsWith('$actionId::'),
      );
    });
    _triggerOnChanged();
  }

  void _moveAction(int fromIndex, int toIndex) {
    if (fromIndex < 0 ||
        toIndex < 0 ||
        fromIndex >= _actions.length ||
        toIndex >= _actions.length ||
        fromIndex == toIndex) {
      return;
    }

    setState(() {
      final action = _actions.removeAt(fromIndex);
      _actions.insert(toIndex, action);
    });
    _triggerOnChanged();
  }

  void _updateActionParameter(
    String actionId,
    String key,
    dynamic value, {
    bool forceFieldRefresh = false,
  }) {
    setState(() {
      final actionIndex = _actions.indexWhere(
        (action) => action.id == actionId,
      );
      if (actionIndex != -1) {
        if (key == '__enabled__') {
          _actions[actionIndex].enabled = value == true;
          return;
        }

        if (key == '__onErrorMode__') {
          _actions[actionIndex].onErrorMode =
              value == 'continue' ? 'continue' : 'stop';
          return;
        }

        if (key == '__actionKey__') {
          _actions[actionIndex].actionKey = value.toString();
          return;
        }

        _actions[actionIndex].parameters[key] = value;

        // Strict mode partitioning: clear inactive mode data
        if (key == 'messageMode' || key == 'editMode') {
          if (value == 'message') {
            _actions[actionIndex].parameters.remove('componentV2');
          } else if (value == 'componentV2') {
            _actions[actionIndex].parameters.remove('embeds');
            _actions[actionIndex].parameters.remove('components');
          }
        }
        if (forceFieldRefresh) {
          final compositeKey = '$actionId::$key';
          _fieldRefreshVersions[compositeKey] =
              (_fieldRefreshVersions[compositeKey] ?? 0) + 1;
        }
      }
    });
    _triggerOnChanged();
  }

  void _saveActions() {
    for (final action in _actions) {
      for (final def in action.type.parameterDefinitions) {
        if (!def.required) {
          continue;
        }

        final value = action.parameters[def.key];
        if (value == null || (value is String && value.trim().isEmpty)) {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text(context.tr.actions_missing_field_title),
                  content: Text(
                    '${action.type.displayName(context)}: ${def.key} is required.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr.common_ok),
                    ),
                  ],
                ),
          );
          return;
        }
      }
    }

    final payload = _actions.map((action) => action.toJson()).toList();
    if (kDebugMode) {
      print('Saving actions payload: $payload');
    }
    Navigator.pop(context, payload);
  }

  String _resolvedActionResultKey(ActionItem action) {
    final raw = action.actionKey.trim();
    if (raw.isNotEmpty) {
      return raw;
    }
    return action.type.name;
  }

  void _addSuggestionIfMissing(
    Map<String, VariableSuggestion> bucket,
    String name,
    VariableSuggestionKind kind,
  ) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    bucket.putIfAbsent(
      trimmed,
      () => VariableSuggestion(name: trimmed, kind: kind),
    );
  }

  void _addActionOutputSuggestions(
    Map<String, VariableSuggestion> bucket,
    ActionItem action,
    String resultKey,
  ) {
    final type = action.type;

    if (type == BotCreatorActionType.httpRequest) {
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.status',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.body',
        VariableSuggestionKind.nonNumeric,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.jsonPath',
        VariableSuggestionKind.nonNumeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.status',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.body',
        VariableSuggestionKind.nonNumeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.jsonPath',
        VariableSuggestionKind.nonNumeric,
      );
    }

    if (type == BotCreatorActionType.appendArrayElement) {
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.length',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.length',
        VariableSuggestionKind.numeric,
      );
    }

    if (type == BotCreatorActionType.removeArrayElement) {
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.length',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.length',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.removed',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.removed',
        VariableSuggestionKind.unknown,
      );
    }

    if (type == BotCreatorActionType.queryArray ||
        type == BotCreatorActionType.listScopedVariableIndex) {
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.items',
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.count',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.count',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        'action.$resultKey.total',
        VariableSuggestionKind.numeric,
      );
      _addSuggestionIfMissing(
        bucket,
        '$resultKey.total',
        VariableSuggestionKind.numeric,
      );
    }

    if (type == BotCreatorActionType.createInvite) {
      for (final name in <String>[
        'inviteCode',
        'invite_url',
        'url',
        'channelId',
        'guildId',
      ]) {
        _addSuggestionIfMissing(
          bucket,
          'action.$resultKey.$name',
          VariableSuggestionKind.nonNumeric,
        );
        _addSuggestionIfMissing(
          bucket,
          '$resultKey.$name',
          VariableSuggestionKind.nonNumeric,
        );
      }
    }
  }

  List<VariableSuggestion> _buildMergedVariableSuggestions() {
    final merged = <String, VariableSuggestion>{};
    for (final item in widget.variableSuggestions) {
      final normalizedName = item.name.trim();
      if (normalizedName.isEmpty) {
        continue;
      }
      merged.putIfAbsent(
        normalizedName,
        () => VariableSuggestion(name: normalizedName, kind: item.kind),
      );
    }

    for (final action in _actions) {
      final resultKey = _resolvedActionResultKey(action);
      _addSuggestionIfMissing(
        merged,
        resultKey,
        VariableSuggestionKind.unknown,
      );
      _addSuggestionIfMissing(
        merged,
        'action.$resultKey',
        VariableSuggestionKind.unknown,
      );
      _addActionOutputSuggestions(merged, action, resultKey);
    }

    return merged.values.toList(growable: false);
  }



  void _showAddActionDialog() {
    final mediaQuery = MediaQuery.of(context);
    final isMobile = mediaQuery.size.width < 700;
    final availableActionTypes = BotCreatorActionType.values
        .where((type) => type != BotCreatorActionType.sendComponentV2)
        .where((type) {
          if (!widget.isInteraction) {
            return !isInteractionOnlyAction(type);
          }
          return true;
        })
        // Autocomplete response is only valid inside an autocomplete handler.
        .where((type) => !isAutocompleteOnlyAction(type))
        .toList(growable: false);
    String searchQuery = '';

    Widget selectorContent(
      BuildContext dialogContext,
      void Function(void Function()) setDialogState,
    ) {
      final actionsByCategory = <String, List<BotCreatorActionType>>{};

      for (final actionType in availableActionTypes) {
        if (searchQuery.isNotEmpty &&
            !actionType
                .displayName(context)
                .toLowerCase()
                .contains(searchQuery.toLowerCase())) {
          continue;
        }
        final category = _getCategoryForAction(actionType);
        actionsByCategory.putIfAbsent(category, () => <BotCreatorActionType>[]);
        actionsByCategory[category]!.add(actionType);
      }

      for (final entry in actionsByCategory.entries) {
        entry.value.sort(
          (a, b) => a.displayName(context).compareTo(b.displayName(context)),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: context.tr.actions_search_hint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setDialogState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actionsByCategory.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Center(
                        child: Text(context.tr.actions_no_matches),
                      ),
                    )
                  else
                    ...actionsByCategory.entries.map(
                      (entry) =>
                          _buildActionCategory(entry.key, entry.value),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isMobile)
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr.common_close),
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.tr.common_cancel),
              ),
            ),
        ],
      );
    }

    if (isMobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheetContext) {
          return FractionallySizedBox(
            heightFactor: 0.92,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: StatefulBuilder(
                  builder: (context, setDialogState) {
                    return selectorContent(context, setDialogState);
                  },
                ),
              ),
            ),
          );
        },
      );
      return;
    }

    final maxHeight = mediaQuery.size.height * 0.8;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr.actions_add_new_title),
              content: SizedBox(
                width: 620,
                height: maxHeight,
                child: selectorContent(context, setDialogState),
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryForAction(BotCreatorActionType type) {
    switch (type) {
      case BotCreatorActionType.wait:
      case BotCreatorActionType.stop:
      case BotCreatorActionType.randomChoice:
        return 'Logic & Flow';
      case BotCreatorActionType.respondWithMessage:
      case BotCreatorActionType.respondWithComponentV2:
      case BotCreatorActionType.respondWithModal:
      case BotCreatorActionType.editInteractionMessage:
      case BotCreatorActionType.listenForButtonClick:
      case BotCreatorActionType.listenForSelectMenu:
      case BotCreatorActionType.listenForModalSubmit:
      case BotCreatorActionType.respondWithAutocomplete:
      case BotCreatorActionType.deferInteraction:
      case BotCreatorActionType.sendDm:
        return 'Interactions';
      case BotCreatorActionType.sendMessage:
      case BotCreatorActionType.editMessage:
      case BotCreatorActionType.deleteMessages:
      case BotCreatorActionType.pinMessage:
      case BotCreatorActionType.unpinMessage:
      case BotCreatorActionType.getMessage:
      case BotCreatorActionType.deleteTrigger:
      case BotCreatorActionType.createPoll:
      case BotCreatorActionType.endPoll:
        return 'Messages';
      case BotCreatorActionType.addReaction:
      case BotCreatorActionType.removeReaction:
      case BotCreatorActionType.clearAllReactions:
        return 'Reactions';
      case BotCreatorActionType.createChannel:
      case BotCreatorActionType.updateChannel:
      case BotCreatorActionType.removeChannel:
      case BotCreatorActionType.createInvite:
      case BotCreatorActionType.deleteInvite:
      case BotCreatorActionType.getInvite:
      case BotCreatorActionType.createThread:
      case BotCreatorActionType.addThreadMember:
      case BotCreatorActionType.removeThreadMember:
      case BotCreatorActionType.editChannelPermissions:
      case BotCreatorActionType.deleteChannelPermission:
        return 'Channels';
      case BotCreatorActionType.banUser:
      case BotCreatorActionType.unbanUser:
      case BotCreatorActionType.kickUser:
      case BotCreatorActionType.muteUser:
      case BotCreatorActionType.unmuteUser:
      case BotCreatorActionType.addRole:
      case BotCreatorActionType.removeRole:
      case BotCreatorActionType.setNickname:
      case BotCreatorActionType.slowmode:
      case BotCreatorActionType.moveToVoiceChannel:
      case BotCreatorActionType.disconnectFromVoice:
      case BotCreatorActionType.serverMuteMember:
      case BotCreatorActionType.serverDeafenMember:
        return 'Moderation';
      case BotCreatorActionType.sendComponentV2:
      case BotCreatorActionType.editComponentV2:
        return 'Components';
      case BotCreatorActionType.sendWebhook:
      case BotCreatorActionType.editWebhook:
      case BotCreatorActionType.deleteWebhook:
      case BotCreatorActionType.listWebhooks:
      case BotCreatorActionType.getWebhook:
        return 'Webhooks';
      case BotCreatorActionType.updateGuild:
      case BotCreatorActionType.leaveGuild:
      case BotCreatorActionType.updateAutoMod:
      case BotCreatorActionType.listMembers:
      case BotCreatorActionType.getMember:
      case BotCreatorActionType.createEmoji:
      case BotCreatorActionType.updateEmoji:
      case BotCreatorActionType.deleteEmoji:
      case BotCreatorActionType.createAutoModRule:
      case BotCreatorActionType.deleteAutoModRule:
      case BotCreatorActionType.listAutoModRules:
      case BotCreatorActionType.getGuildOnboarding:
      case BotCreatorActionType.updateGuildOnboarding:
      case BotCreatorActionType.updateSelfUser:
        return 'Guild & Members';
      case BotCreatorActionType.httpRequest:
      case BotCreatorActionType.setGlobalVariable:
      case BotCreatorActionType.getGlobalVariable:
      case BotCreatorActionType.removeGlobalVariable:
      case BotCreatorActionType.setScopedVariable:
      case BotCreatorActionType.getScopedVariable:
      case BotCreatorActionType.removeScopedVariable:
      case BotCreatorActionType.renameScopedVariable:
      case BotCreatorActionType.listScopedVariableIndex:
      case BotCreatorActionType.appendArrayElement:
      case BotCreatorActionType.removeArrayElement:
      case BotCreatorActionType.queryArray:
      case BotCreatorActionType.setTemporaryVariable:
        return 'HTTP & Variables';
      case BotCreatorActionType.runWorkflow:
      case BotCreatorActionType.runBdfdScript:
      case BotCreatorActionType.debugProfile:
      case BotCreatorActionType.log:
      case BotCreatorActionType.runtimeJsonBlock:
      case BotCreatorActionType.registerGuildCommands:
      case BotCreatorActionType.unregisterGuildCommands:
        return 'Workflows';
      case BotCreatorActionType.stopUnless:
      case BotCreatorActionType.ifBlock:
      case BotCreatorActionType.forLoop:
      case BotCreatorActionType.jsonForEachLoop:
      case BotCreatorActionType.calculate:
      case BotCreatorActionType.cooldown:
        return 'Logic & Flow';
    }
  }

  Widget _buildActionCategory(
    String categoryName,
    List<BotCreatorActionType> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            _localizeCategory(categoryName),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _getCategoryColor(categoryName),
            ),
          ),
        ),
        ...actions.map((type) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              leading: Icon(
                type.icon,
                size: 20,
                color: _getCategoryColor(categoryName),
              ),
              title: Text(
                type.displayName(context),
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                _getActionDescription(type),
                style: const TextStyle(fontSize: 12, color: AppTheme.grey),
              ),
              onTap: () {
                Navigator.pop(context);
                _addAction(type);
              },
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Messages':
        return AppTheme.success;
      case 'Reactions':
        return AppTheme.warning;
      case 'Channels':
        return AppTheme.info;
      case 'Moderation':
        return AppTheme.error;
      case 'Components':
        return AppTheme.brandPrimary;
      case 'Webhooks':
        return Colors.teal;
      case 'Guild & Members':
        return Colors.indigo;
      case 'Utilities':
        return Colors.brown;
      case 'HTTP & Variables':
        return Colors.cyan;
      case 'Workflows':
        return AppTheme.brandPrimary;
      case 'Logic & Flow':
        return Colors.pink;
      case 'Interactions':
        return AppTheme.premiumGold;
      default:
        return AppTheme.grey;
    }
  }

  String _localizeCategory(String category) {
    switch (category) {
      case 'Messages':
        return context.tr.action_category_messages;
      case 'Reactions':
        return context.tr.action_category_reactions;
      case 'Channels':
        return context.tr.action_category_channels;
      case 'Moderation':
        return context.tr.action_category_moderation;
      case 'Components':
        return context.tr.action_category_components;
      case 'Webhooks':
        return context.tr.action_category_webhooks;
      case 'Guild & Members':
        return context.tr.action_category_guild_members;
      case 'HTTP & Variables':
        return context.tr.action_category_http_variables;
      case 'Workflows':
        return context.tr.action_category_workflows;
      case 'Logic & Flow':
        return context.tr.action_category_logic_flow;
      case 'Interactions':
        return context.tr.action_category_interactions;
      default:
        return category;
    }
  }

  String _getActionDescription(BotCreatorActionType type) {
    switch (type) {
      case BotCreatorActionType.sendMessage:
        return context.tr.action_description_sendMessage;
      case BotCreatorActionType.editMessage:
        return context.tr.action_description_editMessage;
      case BotCreatorActionType.deleteMessages:
        return context.tr.action_description_deleteMessages;
      case BotCreatorActionType.addReaction:
        return context.tr.action_description_addReaction;
      case BotCreatorActionType.removeReaction:
        return context.tr.action_description_removeReaction;
      case BotCreatorActionType.clearAllReactions:
        return context.tr.action_description_clearAllReactions;
      case BotCreatorActionType.banUser:
        return context.tr.action_description_banUser;
      case BotCreatorActionType.unbanUser:
        return context.tr.action_description_unbanUser;
      case BotCreatorActionType.kickUser:
        return context.tr.action_description_kickUser;
      case BotCreatorActionType.muteUser:
        return context.tr.action_description_muteUser;
      case BotCreatorActionType.unmuteUser:
        return context.tr.action_description_unmuteUser;
      case BotCreatorActionType.addRole:
        return context.tr.action_description_addRole;
      case BotCreatorActionType.removeRole:
        return context.tr.action_description_removeRole;
      case BotCreatorActionType.cooldown:
        return context.tr.action_description_cooldown;
      case BotCreatorActionType.wait:
        return context.tr.action_description_wait;
      case BotCreatorActionType.deleteTrigger:
        return context.tr.action_description_deleteTrigger;
      case BotCreatorActionType.sendDm:
        return context.tr.action_description_sendDm;
      case BotCreatorActionType.setNickname:
        return context.tr.action_description_setNickname;
      case BotCreatorActionType.slowmode:
        return context.tr.action_description_slowmode;
      case BotCreatorActionType.stop:
        return context.tr.action_description_stop;
      case BotCreatorActionType.randomChoice:
        return context.tr.action_description_randomChoice;
      case BotCreatorActionType.pinMessage:
        return 'Pin a message in a channel';
      case BotCreatorActionType.listMembers:
        return 'List members in a guild with options';
      case BotCreatorActionType.sendWebhook:
        return 'Send message via Webhook';
      case BotCreatorActionType.editWebhook:
        return 'Edit an existing Webhook';
      case BotCreatorActionType.listWebhooks:
        return 'List all Webhooks in a channel or guild';
      case BotCreatorActionType.getWebhook:
        return 'Get Webhook information by ID';
      case BotCreatorActionType.getMember:
        return 'Get member information';
      case BotCreatorActionType.httpRequest:
        return 'Send HTTP request with dynamic URL, method, headers and body';
      case BotCreatorActionType.setGlobalVariable:
        return 'Create or update a global variable for this bot';
      case BotCreatorActionType.getGlobalVariable:
        return 'Read a global variable and inject into runtime variables';
      case BotCreatorActionType.removeGlobalVariable:
        return 'Delete a global variable';
      case BotCreatorActionType.setScopedVariable:
        return 'Create or update a scoped variable (guild/user/channel/guildMember/message)';
      case BotCreatorActionType.setTemporaryVariable:
        return 'Create or update a temporary variable in local execution';
      case BotCreatorActionType.getScopedVariable:
        return 'Read a scoped variable and inject into runtime variables';
      case BotCreatorActionType.removeScopedVariable:
        return 'Delete a scoped variable';
      case BotCreatorActionType.renameScopedVariable:
        return 'Rename a scoped variable key';
      case BotCreatorActionType.listScopedVariableIndex:
        return 'List indexed scoped values sorted by value with offset and limit';
      case BotCreatorActionType.appendArrayElement:
        return 'Append a new element into a global or scoped JSON array';
      case BotCreatorActionType.removeArrayElement:
        return 'Remove one element from a global or scoped JSON array by index';
      case BotCreatorActionType.queryArray:
        return 'Filter, sort and page any runtime JSON array';
      case BotCreatorActionType.runWorkflow:
        return 'Execute a saved workflow (supports entry point + arguments)';
      case BotCreatorActionType.runBdfdScript:
        return 'Compile and run a BDFD script inline as workflow actions';
      case BotCreatorActionType.respondWithMessage:
        return 'Reply to command with a normal message';
      case BotCreatorActionType.respondWithComponentV2:
        return 'Reply to command with buttons/select menus';
      case BotCreatorActionType.respondWithModal:
        return 'Show a modal dialog to the user';
      case BotCreatorActionType.editInteractionMessage:
        return 'Edit the deferred or original interaction response';
      case BotCreatorActionType.listenForButtonClick:
        return 'Register a workflow to run when a button is clicked';
      case BotCreatorActionType.listenForSelectMenu:
        return 'Register a workflow to run when a select menu is used';
      case BotCreatorActionType.listenForModalSubmit:
        return 'Register a workflow to run when a modal is submitted';
      case BotCreatorActionType.respondWithAutocomplete:
        return 'Reply to a Discord autocomplete interaction with up to 25 dynamic choices';
      case BotCreatorActionType.deferInteraction:
        return 'Defer the interaction response to prevent Discord timeout';
      case BotCreatorActionType.stopUnless:
        return 'Stop the workflow if a condition is not met (guard/filter)';
      case BotCreatorActionType.ifBlock:
        return 'Conditional branching: run different actions based on a condition';
      case BotCreatorActionType.calculate:
        return 'Perform math operations and store result';
      case BotCreatorActionType.getMessage:
        return 'Fetch a message and expose its fields';
      case BotCreatorActionType.unpinMessage:
        return 'Unpin a message in a channel';
      case BotCreatorActionType.createPoll:
        return 'Create a poll message in a channel';
      case BotCreatorActionType.endPoll:
        return 'End an active poll message immediately';
      case BotCreatorActionType.createInvite:
        return 'Create a new invite link for a channel';
      case BotCreatorActionType.deleteInvite:
        return 'Delete an existing invite by code';
      case BotCreatorActionType.getInvite:
        return 'Fetch invite information by code';
      case BotCreatorActionType.moveToVoiceChannel:
        return 'Move a member to a specific voice channel';
      case BotCreatorActionType.disconnectFromVoice:
        return 'Disconnect a member from voice';
      case BotCreatorActionType.serverMuteMember:
        return 'Server-mute or unmute a member';
      case BotCreatorActionType.serverDeafenMember:
        return 'Server-deafen or undeafen a member';
      case BotCreatorActionType.createEmoji:
        return 'Create a guild emoji from image data';
      case BotCreatorActionType.updateEmoji:
        return 'Update guild emoji name or role access';
      case BotCreatorActionType.deleteEmoji:
        return 'Delete a guild emoji';
      case BotCreatorActionType.createAutoModRule:
        return 'Create a guild auto-moderation rule';
      case BotCreatorActionType.deleteAutoModRule:
        return 'Delete an auto-moderation rule';
      case BotCreatorActionType.listAutoModRules:
        return 'List all auto-moderation rules in guild';
      case BotCreatorActionType.getGuildOnboarding:
        return 'Fetch current guild onboarding configuration';
      case BotCreatorActionType.updateGuildOnboarding:
        return 'Update guild onboarding configuration';
      case BotCreatorActionType.updateSelfUser:
        return 'Update current bot user profile (username/avatar)';
      case BotCreatorActionType.createThread:
        return 'Create a thread in a supported text channel';
      case BotCreatorActionType.addThreadMember:
        return 'Add a member to a thread';
      case BotCreatorActionType.removeThreadMember:
        return 'Remove a member from a thread';
      case BotCreatorActionType.editChannelPermissions:
        return 'Create or update channel permission overwrites';
      case BotCreatorActionType.deleteChannelPermission:
        return 'Delete a channel permission overwrite';
      case BotCreatorActionType.sendComponentV2:
        return 'Send interactive components';
      case BotCreatorActionType.editComponentV2:
        return 'Edit existing components';
      case BotCreatorActionType.createChannel:
        return 'Create a new channel';
      case BotCreatorActionType.updateChannel:
        return 'Update channel settings';
      case BotCreatorActionType.removeChannel:
        return 'Delete a channel';
      case BotCreatorActionType.updateAutoMod:
        return 'Update auto-moderation settings';
      case BotCreatorActionType.updateGuild:
        return 'Update guild settings';
      case BotCreatorActionType.leaveGuild:
        return 'Make the bot leave the guild/server';
      case BotCreatorActionType.deleteWebhook:
        return 'Delete a webhook';
      case BotCreatorActionType.forLoop:
        return 'Loop through a range of numbers (for loop)';
      case BotCreatorActionType.jsonForEachLoop:
        return 'Loop through each element of a JSON array or object (forEach)';
      case BotCreatorActionType.debugProfile:
        return 'Generate execution profile and diagnostics info';
      case BotCreatorActionType.log:
        return 'Print or store diagnostic message to action logs';
      case BotCreatorActionType.runtimeJsonBlock:
        return 'Run block of JSON processing actions';
      case BotCreatorActionType.registerGuildCommands:
        return 'Register application commands to a guild';
      case BotCreatorActionType.unregisterGuildCommands:
        return 'Unregister application commands from a guild';
    }
  }

  List<ActionItem> _filteredActions() {
    final query = _desktopActionSearch.trim().toLowerCase();
    if (query.isEmpty) {
      return List<ActionItem>.from(_actions, growable: false);
    }
    return _actions
        .where((action) {
          final summary = summarizeActionItem(context, action);
          return summary.title.toLowerCase().contains(query) ||
              summary.summary.toLowerCase().contains(query) ||
              summary.outputKey.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_task, size: 64, color: AppTheme.grey),
          const SizedBox(height: 16),
          const Text(
            'No actions yet',
            style: TextStyle(fontSize: 18, color: AppTheme.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an action, then open it to configure details.',
            style: TextStyle(color: AppTheme.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBlockButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: OutlinedButton.icon(
        onPressed: _showAddActionDialog,
        icon: const Icon(Icons.add),
        label: Text(context.tr.scratch_add_block),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildActionSequence({
    required EdgeInsetsGeometry padding,
    required double maxContentWidth,
  }) {
    if (_actions.isEmpty) {
      return _buildEmptyState();
    }
    final filtered = _filteredActions();
    if (filtered.isEmpty) {
      return Center(child: Text(context.tr.actions_no_matches));
    }

    final mergedVariableSuggestions = _buildMergedVariableSuggestions();

    final skipConnectorAfterIndices = <int>{};
    for (int i = 0; i < filtered.length; i++) {
      if (isFinalAction(filtered[i].type)) {
        skipConnectorAfterIndices.add(i);
      }
    }

    final children = <Widget>[
      for (int i = 0; i < filtered.length; i++) ...[
        Builder(
          builder: (context) {
            final action = filtered[i];
            final absoluteIndex = _actions.indexOf(action);
            return ActionBlock(
              key: ValueKey('builder-action-${action.id}'),
              action: action,
              index: absoluteIndex,
              totalCount: _actions.length,
              variableSuggestions: mergedVariableSuggestions,
              emojiSuggestions: widget.emojiSuggestions,
              botIdForConfig: widget.botIdForConfig,
              onRemove: () async {
                final shouldDelete = await AppTheme.showConfirmDialog(
                  context,
                  title: context.tr.action_remove_title,
                  content: context.tr.action_remove_confirm,
                  confirmLabel: context.tr.common_remove,
                  isDestructive: true,
                );
                if (shouldDelete) {
                  _removeAction(action.id);
                }
              },
              onMoveUp: absoluteIndex > 0 ? () => _moveAction(absoluteIndex, absoluteIndex - 1) : null,
              onMoveDown: absoluteIndex < _actions.length - 1 ? () => _moveAction(absoluteIndex, absoluteIndex + 1) : null,
              onParameterChanged: (key, value) => _updateActionParameter(action.id, key, value),
              onSuggestionSelected: (key, value) => _updateActionParameter(action.id, key, value, forceFieldRefresh: true),
              fieldRefreshVersionOf: (paramKey) => _fieldRefreshVersions['${action.id}::$paramKey'] ?? 0,
              onEditNestedActions: (current, suggestions, blockName, {onChanged}) async {
                return await Navigator.push<List<Map<String, dynamic>>>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ActionsBuilderPage(
                      initialActions: current,
                      variableSuggestions: suggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      botIdForConfig: widget.botIdForConfig,
                      editPath: [...widget.editPath, blockName],
                      onChanged: onChanged,
                      isInteraction: widget.isInteraction,
                      isWorkflow: widget.isWorkflow,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
      _buildAddBlockButton(),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxContentWidth),
        child: ScratchBlockCanvas(
          padding: padding as EdgeInsets,
          skipConnectorAfterIndices: skipConnectorAfterIndices,
          children: children,
        ),
      ),
    );
  }

  Widget _buildSequenceHeader() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: (value) {
                setState(() {
                  _desktopActionSearch = value;
                });
              },
              decoration: InputDecoration(
                hintText: context.tr.actions_search_sequence_hint,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr.actions_sequence_count(_actions.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: _showAddActionDialog,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr.actions_add_label),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbsHeader(BuildContext context) {
    if (widget.editPath.isEmpty) {
      return const SizedBox.shrink();
    }

    final crumbs = [context.tr.actions_builder_title, ...widget.editPath];
    final allItems = <String>[];
    for (final crumb in crumbs) {
      if (crumb.contains(' > ')) {
        allItems.addAll(crumb.split(' > '));
      } else {
        allItems.add(crumb);
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (int i = 0; i < allItems.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
              _buildBreadcrumbItem(
                context,
                allItems[i],
                i == allItems.length - 1,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    String path,
    bool isActive,
  ) {
    final theme = Theme.of(context);

    Color? badgeColor;
    String upper = path.toUpperCase();
    if (upper.contains('THEN') || upper.contains('ALORS')) {
      badgeColor = AppTheme.success;
    } else if (upper.contains('ELSE') || upper.contains('SINON')) {
      badgeColor = AppTheme.warning;
    } else if (upper.contains('ELSE IF') || upper.contains('SINON SI')) {
      badgeColor = AppTheme.premiumGold;
    }

    if (badgeColor != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Text(
          path,
          style: TextStyle(
            color: badgeColor,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      );
    }

    final textColor =
        isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final fontWeight = isActive ? FontWeight.w600 : FontWeight.bold;

    return Text(
      path,
      style: TextStyle(
        color: textColor,
        fontWeight: fontWeight,
        fontSize: 12.5,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget saveButton() {
      return ElevatedButton.icon(
        onPressed: _saveActions,
        icon: const Icon(Icons.save),
        label: Text(context.tr.actions_save_count(_actions.length)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editPath.isNotEmpty
              ? widget.editPath.last.split(' > ').last
              : context.tr.actions_builder_title,
        ),
        actions: [
          if (widget.editPath.isEmpty)
            IconButton(
              onPressed: _saveActions,
              icon: const Icon(Icons.save),
              tooltip: context.tr.actions_save_tooltip,
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildBreadcrumbsHeader(context),
            _buildSequenceHeader(),
            Expanded(
              child: _buildActionSequence(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                maxContentWidth: 980,
              ),
            ),
            if (_actions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: widget.editPath.isNotEmpty
                      ? ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check),
                          label: Text(context.tr.common_ok),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                        )
                      : saveButton(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

