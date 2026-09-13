import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator_shared/types/variable_suggestion.dart' as shared;
import 'package:bot_creator_shared/utils/variable_catalog.dart'
    show inferCategory;
import 'builder/action_types.dart';
import 'builder/action_type_extension.dart';
import 'builder/action_summary.dart';

import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/widgets/page_layout.dart';
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
  final bool isAutocompleteContext;
  final bool isModalContext;

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
    this.isAutocompleteContext = false,
    this.isModalContext = false,
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
    // Scan existing action IDs to prevent suffix collision with new actions
    int maxSuffix = -1;
    final seqIdRegex = RegExp(r'^action_(\d+)$');
    for (final action in widget.initialActions) {
      final rawId = (action['id'] ?? '').toString().trim();
      final match = seqIdRegex.firstMatch(rawId);
      if (match != null) {
        final val = int.tryParse(match.group(1) ?? '');
        if (val != null && val > maxSuffix) {
          maxSuffix = val;
        }
      }
    }
    if (maxSuffix >= 0) {
      _actionCounter = maxSuffix + 1;
    }

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

  void _removeAction(String actionId, {int? expectedIndex}) {
    setState(() {
      var index = _actions.indexWhere((action) => action.id == actionId);
      // Fallback: try runtimeId if id lookup fails or index mismatch
      if (index == -1 || (expectedIndex != null && index != expectedIndex)) {
        final byRuntimeId = _actions.indexWhere(
          (action) => action.runtimeId == actionId,
        );
        if (byRuntimeId != -1) {
          index = byRuntimeId;
        }
      }
      if (index != -1) {
        _actions.removeAt(index);
      }
      _fieldRefreshVersions.removeWhere(
        (compositeKey, _) => compositeKey.startsWith('$actionId::'),
      );
    });
    _triggerOnChanged();
  }

  void _pasteActionAt(int index, Map<String, dynamic> copiedActionJson) {
    setState(() {
      final newId = 'action_${_actionCounter++}';

      final clonedJson = Map<String, dynamic>.from(copiedActionJson);
      clonedJson['id'] = newId;
      clonedJson['key'] = newId;
      clonedJson['runtimeId'] = newId;

      if (clonedJson['payload'] is Map) {
        final payload = Map<String, dynamic>.from(clonedJson['payload'] as Map);
        payload['_actionId'] = newId;
        clonedJson['payload'] = payload;
      }

      final item = ActionItem.fromJson(clonedJson, fallbackId: newId);

      if (index >= _actions.length) {
        _actions.add(item);
      } else {
        _actions.insert(index, item);
      }
    });
    _triggerOnChanged();
  }

  void _duplicateAction(int index) {
    if (index >= 0 && index < _actions.length) {
      final actionJson = _actions[index].toJson();
      _pasteActionAt(index + 1, actionJson);
    }
  }

  void _pasteAction() async {
    final copied = await ActionClipboard.getCopiedAction();
    if (copied != null) {
      _pasteActionAt(_actions.length, copied);
    }
  }

  static String _localString(String val) => val;

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
          _actions[actionIndex].onErrorMode = value == 'continue'
              ? 'continue'
              : (value == 'jump'
                    ? 'jump'
                    : (value == 'skip' ? 'skip' : 'stop'));
          return;
        }

        if (key == '__onErrorJumpTarget__') {
          _actions[actionIndex].jumpToActionId = value?.toString();
          return;
        }

        if (key == '__onErrorSkipCount__') {
          _actions[actionIndex].skipCount =
              int.tryParse(value?.toString() ?? '') ?? 1;
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
            builder: (context) => AlertDialog(
              title: Text(context.tr.actions_missing_field_title),
              content: Text(
                context.tr.actions_missing_field_content(
                  action.type.displayName(context),
                  def.key,
                ),
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
    VariableSuggestionKind kind, {
    shared.VariableCategory category = shared.VariableCategory.other,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    bucket.putIfAbsent(trimmed, () {
      // Infer category from name prefix when none explicitly set.
      final effectiveCategory = category != shared.VariableCategory.other
          ? category
          : inferCategory(trimmed);
      return VariableSuggestion(
        name: trimmed,
        kind: kind,
        category: effectiveCategory,
      );
    });
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

    if (type == BotCreatorActionType.playMusic) {
      for (final name in <String>[
        'title',
        'author',
        'duration',
        'uri',
        'thumbnail',
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

    if (type == BotCreatorActionType.getMusicInfo) {
      for (final name in <String>[
        'isPlaying',
        'title',
        'author',
        'duration',
        'position',
        'queueSize',
        'volume',
        'isPaused',
        'isLooping',
        'thumbnail',
      ]) {
        final kind = (name == 'queueSize' || name == 'volume')
            ? VariableSuggestionKind.numeric
            : VariableSuggestionKind.nonNumeric;
        _addSuggestionIfMissing(bucket, 'action.$resultKey.$name', kind);
        _addSuggestionIfMissing(bucket, '$resultKey.$name', kind);
      }
    }

    // Temporary variables: when a setTemporaryVariable action is present,
    // expose its key as temp.<key> so it appears in autocomplete for
    // downstream blocks.
    if (type == BotCreatorActionType.setTemporaryVariable) {
      // Read key the same way the runtime executor does:
      // from the serialized payload, not from parameters.
      final serialized = action.toJson();
      final payload =
          serialized['payload'] as Map<String, dynamic>? ?? const {};
      final rawKey = (payload['key'] ?? '').toString().trim();
      if (rawKey.isNotEmpty) {
        // Strip bc_ prefix if present (matching runtime storage convention).
        final normalizedKey = rawKey.startsWith('bc_') && rawKey.length > 3
            ? rawKey.substring(3)
            : rawKey;
        _addSuggestionIfMissing(
          bucket,
          'temp.$normalizedKey',
          VariableSuggestionKind.unknown,
          category: shared.VariableCategory.temp,
        );
      }
    }

    // Modal input values: when respondWithModal is present, expose each
    // input's customId as a variable so downstream actions can reference
    // the submitted values via modal.<customId>.
    if (type == BotCreatorActionType.respondWithModal) {
      final modalJson = action.parameters['modal'] as Map<String, dynamic>?;
      if (modalJson != null) {
        final inputs =
            (modalJson['inputs'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>() ??
            const [];
        for (final input in inputs) {
          final customId = (input['customId'] ?? '').toString().trim();
          if (customId.isEmpty) continue;
          _addSuggestionIfMissing(
            bucket,
            'modal.$customId',
            VariableSuggestionKind.nonNumeric,
            category: shared.VariableCategory.interaction,
          );
          _addSuggestionIfMissing(
            bucket,
            'action.$resultKey.modal.$customId',
            VariableSuggestionKind.nonNumeric,
            category: shared.VariableCategory.interaction,
          );
        }
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
      merged.putIfAbsent(normalizedName, () {
        final cat = item.category != shared.VariableCategory.other
            ? item.category
            : inferCategory(normalizedName);
        return VariableSuggestion(
          name: normalizedName,
          kind: item.kind,
          category: cat,
        );
      });
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
        .where(_isActionAllowedInContext)
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
                      child: Center(child: Text(context.tr.actions_no_matches)),
                    )
                  else
                    ...actionsByCategory.entries.map(
                      (entry) => _buildActionCategory(entry.key, entry.value),
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
      case BotCreatorActionType.skipActions:
      case BotCreatorActionType.jumpToAction:
      case BotCreatorActionType.randomChoice:
        return 'Logic & Flow';
      case BotCreatorActionType.respondWithMessage:
      case BotCreatorActionType.respondWithComponentV2:
      case BotCreatorActionType.respondWithModal:
      case BotCreatorActionType.editInteractionMessage:
      case BotCreatorActionType.listenForButtonClick:
      case BotCreatorActionType.listenForSelectMenu:
      case BotCreatorActionType.listenForModalSubmit:
      case BotCreatorActionType.listenAndExecute:
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
      case BotCreatorActionType.attachImage:
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
      case BotCreatorActionType.runtimeImageBlock:
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
      case BotCreatorActionType.playMusic:
      case BotCreatorActionType.pauseMusic:
      case BotCreatorActionType.resumeMusic:
      case BotCreatorActionType.skipMusic:
      case BotCreatorActionType.stopMusic:
      case BotCreatorActionType.setMusicVolume:
      case BotCreatorActionType.setMusicLoop:
      case BotCreatorActionType.seekMusic:
      case BotCreatorActionType.getMusicInfo:
      case BotCreatorActionType.joinVoice:
      case BotCreatorActionType.leaveVoice:
        return 'Music';
      default:
        return 'Workflows';
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
              color: getCategoryColor(categoryName),
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
                color: getCategoryColor(categoryName),
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

  // La palette de catégories vit désormais dans UNE SEULE source
  // (`getCategoryColor` de `scratch_block_palette.dart`) : cette copie locale
  // avait divergé (elle ignorait Metadata/EntryPoint et rendait « Utilities »
  // en marron alors que la palette partagée le laissait en gris).

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
      case 'Music':
        final languageCode = Localizations.localeOf(context).languageCode;
        if (languageCode == 'fr') return 'Musique';
        if (languageCode == 'de') return 'Musik';
        if (languageCode == 'ja') return '音楽';
        if (languageCode == 'pt') return 'Música';
        if (languageCode == 'tr') return 'Müzik';
        return 'Music';
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
      case BotCreatorActionType.skipActions:
        return context.tr.action_description_skipActions;
      case BotCreatorActionType.jumpToAction:
        return context.tr.action_description_jumpToAction;
      case BotCreatorActionType.randomChoice:
        return context.tr.action_description_randomChoice;
      case BotCreatorActionType.pinMessage:
        return context.tr.action_description_pinMessage;
      case BotCreatorActionType.listMembers:
        return context.tr.action_description_listMembers;
      case BotCreatorActionType.sendWebhook:
        return context.tr.action_description_sendWebhook;
      case BotCreatorActionType.editWebhook:
        return context.tr.action_description_editWebhook;
      case BotCreatorActionType.listWebhooks:
        return context.tr.action_description_listWebhooks;
      case BotCreatorActionType.getWebhook:
        return context.tr.action_description_getWebhook;
      case BotCreatorActionType.getMember:
        return context.tr.action_description_getMember;
      case BotCreatorActionType.httpRequest:
        return context.tr.action_description_httpRequest;
      case BotCreatorActionType.setGlobalVariable:
        return context.tr.action_description_setGlobalVariable;
      case BotCreatorActionType.getGlobalVariable:
        return context.tr.action_description_getGlobalVariable;
      case BotCreatorActionType.removeGlobalVariable:
        return context.tr.action_description_removeGlobalVariable;
      case BotCreatorActionType.setScopedVariable:
        return context.tr.action_description_setScopedVariable;
      case BotCreatorActionType.setTemporaryVariable:
        return context.tr.action_description_setTemporaryVariable;
      case BotCreatorActionType.getScopedVariable:
        return context.tr.action_description_getScopedVariable;
      case BotCreatorActionType.removeScopedVariable:
        return context.tr.action_description_removeScopedVariable;
      case BotCreatorActionType.renameScopedVariable:
        return context.tr.action_description_renameScopedVariable;
      case BotCreatorActionType.listScopedVariableIndex:
        return context.tr.action_description_listScopedVariableIndex;
      case BotCreatorActionType.appendArrayElement:
        return context.tr.action_description_appendArrayElement;
      case BotCreatorActionType.removeArrayElement:
        return context.tr.action_description_removeArrayElement;
      case BotCreatorActionType.queryArray:
        return context.tr.action_description_queryArray;
      case BotCreatorActionType.runWorkflow:
        return context.tr.action_description_runWorkflow;
      case BotCreatorActionType.runBdfdScript:
        return context.tr.action_description_runBdfdScript;
      case BotCreatorActionType.respondWithMessage:
        return context.tr.action_description_respondWithMessage;
      case BotCreatorActionType.respondWithComponentV2:
        return context.tr.action_description_respondWithComponentV2;
      case BotCreatorActionType.respondWithModal:
        return context.tr.action_description_respondWithModal;
      case BotCreatorActionType.editInteractionMessage:
        return context.tr.action_description_editInteractionMessage;
      case BotCreatorActionType.listenForButtonClick:
        return context.tr.action_description_listenForButtonClick;
      case BotCreatorActionType.listenForSelectMenu:
        return context.tr.action_description_listenForSelectMenu;
      case BotCreatorActionType.listenForModalSubmit:
        return context.tr.action_description_listenForModalSubmit;
      case BotCreatorActionType.listenAndExecute:
        return context.tr.action_description_listenAndExecute;
      case BotCreatorActionType.respondWithAutocomplete:
        return context.tr.action_description_respondWithAutocomplete;
      case BotCreatorActionType.deferInteraction:
        return context.tr.action_description_deferInteraction;
      case BotCreatorActionType.stopUnless:
        return context.tr.action_description_stopUnless;
      case BotCreatorActionType.ifBlock:
        return context.tr.action_description_ifBlock;
      case BotCreatorActionType.calculate:
        return context.tr.action_description_calculate;
      case BotCreatorActionType.getMessage:
        return context.tr.action_description_getMessage;
      case BotCreatorActionType.unpinMessage:
        return context.tr.action_description_unpinMessage;
      case BotCreatorActionType.createPoll:
        return context.tr.action_description_createPoll;
      case BotCreatorActionType.endPoll:
        return context.tr.action_description_endPoll;
      case BotCreatorActionType.createInvite:
        return context.tr.action_description_createInvite;
      case BotCreatorActionType.deleteInvite:
        return context.tr.action_description_deleteInvite;
      case BotCreatorActionType.getInvite:
        return context.tr.action_description_getInvite;
      case BotCreatorActionType.moveToVoiceChannel:
        return context.tr.action_description_moveToVoiceChannel;
      case BotCreatorActionType.disconnectFromVoice:
        return context.tr.action_description_disconnectFromVoice;
      case BotCreatorActionType.serverMuteMember:
        return context.tr.action_description_serverMuteMember;
      case BotCreatorActionType.serverDeafenMember:
        return context.tr.action_description_serverDeafenMember;
      case BotCreatorActionType.createEmoji:
        return context.tr.action_description_createEmoji;
      case BotCreatorActionType.updateEmoji:
        return context.tr.action_description_updateEmoji;
      case BotCreatorActionType.deleteEmoji:
        return context.tr.action_description_deleteEmoji;
      case BotCreatorActionType.createAutoModRule:
        return context.tr.action_description_createAutoModRule;
      case BotCreatorActionType.deleteAutoModRule:
        return context.tr.action_description_deleteAutoModRule;
      case BotCreatorActionType.listAutoModRules:
        return context.tr.action_description_listAutoModRules;
      case BotCreatorActionType.getGuildOnboarding:
        return context.tr.action_description_getGuildOnboarding;
      case BotCreatorActionType.updateGuildOnboarding:
        return context.tr.action_description_updateGuildOnboarding;
      case BotCreatorActionType.updateSelfUser:
        return context.tr.action_description_updateSelfUser;
      case BotCreatorActionType.createThread:
        return context.tr.action_description_createThread;
      case BotCreatorActionType.addThreadMember:
        return context.tr.action_description_addThreadMember;
      case BotCreatorActionType.removeThreadMember:
        return context.tr.action_description_removeThreadMember;
      case BotCreatorActionType.editChannelPermissions:
        return context.tr.action_description_editChannelPermissions;
      case BotCreatorActionType.deleteChannelPermission:
        return context.tr.action_description_deleteChannelPermission;
      case BotCreatorActionType.sendComponentV2:
        return context.tr.action_description_sendComponentV2;
      case BotCreatorActionType.editComponentV2:
        return context.tr.action_description_editComponentV2;
      case BotCreatorActionType.createChannel:
        return context.tr.action_description_createChannel;
      case BotCreatorActionType.updateChannel:
        return context.tr.action_description_updateChannel;
      case BotCreatorActionType.removeChannel:
        return context.tr.action_description_removeChannel;
      case BotCreatorActionType.updateAutoMod:
        return context.tr.action_description_updateAutoMod;
      case BotCreatorActionType.updateGuild:
        return context.tr.action_description_updateGuild;
      case BotCreatorActionType.leaveGuild:
        return context.tr.action_description_leaveGuild;
      case BotCreatorActionType.deleteWebhook:
        return context.tr.action_description_deleteWebhook;
      case BotCreatorActionType.forLoop:
        return context.tr.action_description_forLoop;
      case BotCreatorActionType.jsonForEachLoop:
        return context.tr.action_description_jsonForEachLoop;
      case BotCreatorActionType.debugProfile:
        return context.tr.action_description_debugProfile;
      case BotCreatorActionType.log:
        return context.tr.action_description_log;
      case BotCreatorActionType.runtimeJsonBlock:
        return context.tr.action_description_runtimeJsonBlock;
      case BotCreatorActionType.runtimeImageBlock:
        return context.tr.action_description_runtimeImageBlock;
      case BotCreatorActionType.attachImage:
        return context.tr.action_description_attachImage;
      case BotCreatorActionType.registerGuildCommands:
        return context.tr.action_description_registerGuildCommands;
      case BotCreatorActionType.unregisterGuildCommands:
        return context.tr.action_description_unregisterGuildCommands;
      case BotCreatorActionType.playMusic:
        return context.tr.action_description_playMusic;
      case BotCreatorActionType.pauseMusic:
        return context.tr.action_description_pauseMusic;
      case BotCreatorActionType.resumeMusic:
        return context.tr.action_description_resumeMusic;
      case BotCreatorActionType.skipMusic:
        return context.tr.action_description_skipMusic;
      case BotCreatorActionType.stopMusic:
        return context.tr.action_description_stopMusic;
      case BotCreatorActionType.setMusicVolume:
        return context.tr.action_description_setMusicVolume;
      case BotCreatorActionType.setMusicLoop:
        return context.tr.action_description_setMusicLoop;
      case BotCreatorActionType.seekMusic:
        return context.tr.action_description_seekMusic;
      case BotCreatorActionType.getMusicInfo:
        return context.tr.action_description_getMusicInfo;
      case BotCreatorActionType.joinVoice:
        return context.tr.action_description_joinVoice;
      case BotCreatorActionType.leaveVoice:
        return context.tr.action_description_leaveVoice;
      case BotCreatorActionType.canvasCreateBlock:
        return context.tr.action_description_canvasCreateBlock;
      case BotCreatorActionType.canvasLoadImageBlock:
        return context.tr.action_description_canvasLoadImageBlock;
      case BotCreatorActionType.canvasDrawTextBlock:
        return context.tr.action_description_canvasDrawTextBlock;
      case BotCreatorActionType.canvasDrawCircleBlock:
        return context.tr.action_description_canvasDrawCircleBlock;
      case BotCreatorActionType.canvasDrawRectBlock:
        return context.tr.action_description_canvasDrawRectBlock;
      case BotCreatorActionType.canvasDrawLineBlock:
        return context.tr.action_description_canvasDrawLineBlock;
    }
  }

  /// Centralized action filtering based on the current builder context.
  /// Replaces scattered `.where()` clauses with a single decision point.
  bool _isActionAllowedInContext(BotCreatorActionType type) {
    // ── Listener actions (listenFor*) ──────────────────────────────────────
    // Component interaction listeners are configured through a separate
    // workflow-association UI, never as inline runtime actions.
    if (isListenerAction(type)) {
      return false;
    }

    // ── Autocomplete-only action ───────────────────────────────────────────
    // respondWithAutocomplete is only valid inside an autocomplete handler.
    if (isAutocompleteOnlyAction(type)) {
      return widget.isAutocompleteContext;
    }

    // ── Interaction-only actions ───────────────────────────────────────────
    // respondWithModal, deferInteraction, editInteractionMessage require an
    // active interaction (command response, modal submit, component handler).
    if (isInteractionOnlyAction(type)) {
      // Modal context: defer makes no sense — you can't defer a modal submission.
      if (widget.isModalContext &&
          type == BotCreatorActionType.deferInteraction) {
        return false;
      }
      return widget.isInteraction;
    }

    // ── Autocomplete context whitelist ─────────────────────────────────────
    // Inside an autocomplete handler, only data/logic actions are relevant.
    if (widget.isAutocompleteContext) {
      return _isAutocompleteContextAction(type);
    }

    // ── Modal/component submit: no nested modals ───────────────────────────
    // You cannot show a modal inside a modal submit handler.
    if (widget.isWorkflow &&
        widget.isInteraction &&
        type == BotCreatorActionType.respondWithModal) {
      return false;
    }

    return true;
  }

  /// Delegates to the top-level [isAutocompleteContextAction] in the palette file.
  bool _isAutocompleteContextAction(BotCreatorActionType type) {
    return isAutocompleteContextAction(type);
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
          Text(
            context.tr.actions_empty_title,
            style: const TextStyle(fontSize: 18, color: AppTheme.grey),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr.actions_empty_subtitle,
            style: TextStyle(color: AppTheme.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAddBlockButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: FutureBuilder<bool>(
        future: ActionClipboard.hasCopiedAction(),
        builder: (context, snapshot) {
          final hasCopied = snapshot.data ?? false;
          if (!hasCopied) {
            return OutlinedButton.icon(
              onPressed: _showAddActionDialog,
              icon: const Icon(Icons.add),
              label: Text(context.tr.scratch_add_block),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
            );
          }
          return Row(
            children: [
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: _showAddActionDialog,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr.scratch_add_block),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: _pasteAction,
                  icon: const Icon(Icons.paste),
                  label: Text(_localString('Paste')),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActionSequence({
    required EdgeInsets padding,
    bool showAddButton = true,
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
                  _removeAction(action.runtimeId, expectedIndex: absoluteIndex);
                }
              },
              onMoveUp: absoluteIndex > 0
                  ? () => _moveAction(absoluteIndex, absoluteIndex - 1)
                  : null,
              onMoveDown: absoluteIndex < _actions.length - 1
                  ? () => _moveAction(absoluteIndex, absoluteIndex + 1)
                  : null,
              onParameterChanged: (key, value) =>
                  _updateActionParameter(action.id, key, value),
              onSuggestionSelected: (key, value) => _updateActionParameter(
                action.id,
                key,
                value,
                forceFieldRefresh: true,
              ),
              fieldRefreshVersionOf: (paramKey) =>
                  _fieldRefreshVersions['${action.id}::$paramKey'] ?? 0,
              onEditNestedActions:
                  (current, suggestions, blockName, {onChanged}) async {
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
              allActions: _actions, // for Jump to action dropdown
              onPasteAbove: (copied) => _pasteActionAt(absoluteIndex, copied),
              onPasteBelow: (copied) =>
                  _pasteActionAt(absoluteIndex + 1, copied),
              onDuplicate: () => _duplicateAction(absoluteIndex),
            );
          },
        ),
      ],
      if (showAddButton) _buildAddBlockButton(),
    ];

    return PageContent(
      child: ScratchBlockCanvas(
        padding: padding,
        skipConnectorAfterIndices: skipConnectorAfterIndices,
        children: children,
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
                FutureBuilder<bool>(
                  future: ActionClipboard.hasCopiedAction(),
                  builder: (context, snapshot) {
                    final hasCopied = snapshot.data ?? false;
                    if (!hasCopied) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton.icon(
                        onPressed: _pasteAction,
                        icon: const Icon(Icons.paste),
                        label: Text(_localString('Paste')),
                      ),
                    );
                  },
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

    final textColor = isActive
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.editPath.isNotEmpty
              ? widget.editPath.last.split(' > ').last
              : context.tr.actions_builder_title,
        ),
        actions: [
          IconButton(
            onPressed: _saveActions,
            icon: Icon(widget.editPath.isNotEmpty ? Icons.check : Icons.save),
            tooltip: widget.editPath.isNotEmpty
                ? context.tr.common_ok
                : context.tr.actions_save_tooltip,
          ),
        ],
      ),
      floatingActionButton: _actions.isNotEmpty
          ? FloatingActionButton.extended(
              heroTag: null,
              onPressed: _saveActions,
              icon: Icon(widget.editPath.isNotEmpty ? Icons.check : Icons.save),
              label: Text(
                widget.editPath.isNotEmpty
                    ? context.tr.common_ok
                    : context.tr.actions_save_count(_actions.length),
              ),
              backgroundColor: widget.editPath.isNotEmpty
                  ? Theme.of(context).colorScheme.primary
                  : AppTheme.success,
              foregroundColor: Colors.white,
            )
          : null,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildBreadcrumbsHeader(context),
            _buildSequenceHeader(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop =
                      MediaQuery.of(context).size.width >= 800 &&
                      !Platform.environment.containsKey('FLUTTER_TEST');

                  final canvasWidget = _buildActionSequence(
                    // Marges horizontales communes ([PageContent]) ; la
                    // réserve basse du canvas reste locale.
                    padding: const EdgeInsets.only(top: 8, bottom: 88),
                    showAddButton: !isDesktop,
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 320,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            border: Border(
                              right: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                                width: 1,
                              ),
                            ),
                          ),
                          child: ScratchBlockPalette(
                            onActionSelected: _addAction,
                            isInteraction: widget.isInteraction,
                            isWorkflow: widget.isWorkflow,
                            isAutocompleteContext: widget.isAutocompleteContext,
                            isModalContext: widget.isModalContext,
                            popOnSelect: false,
                            enableDrag: false,
                          ),
                        ),
                        Expanded(child: canvasWidget),
                      ],
                    );
                  }

                  return canvasWidget;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
