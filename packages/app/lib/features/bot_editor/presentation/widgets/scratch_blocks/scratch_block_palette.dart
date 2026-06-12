import 'package:bot_creator/core/i18n/extensions.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';

import 'package:bot_creator/core/theme/app_theme.dart';

/// Category metadata used by the palette.
class BlockCategory {
  const BlockCategory({
    required this.name,
    required this.color,
    required this.icon,
  });

  final String name;
  final Color color;
  final IconData icon;
}

/// Returns `true` for action types that are terminal / final blocks —
/// i.e. they respond to an interaction and nothing should follow them.
bool isFinalAction(BotCreatorActionType type) {
  switch (type) {
    case BotCreatorActionType.respondWithMessage:
    case BotCreatorActionType.respondWithComponentV2:
    case BotCreatorActionType.respondWithModal:
    case BotCreatorActionType.respondWithAutocomplete:
    case BotCreatorActionType.deferInteraction:
      return true;
    default:
      return false;
  }
}

/// Maps an action type to its category name.
String getCategoryForAction(BotCreatorActionType type) {
  switch (type) {
    case BotCreatorActionType.sendMessage:
    case BotCreatorActionType.editMessage:
    case BotCreatorActionType.deleteMessages:
    case BotCreatorActionType.pinMessage:
    case BotCreatorActionType.getMessage:
    case BotCreatorActionType.unpinMessage:
    case BotCreatorActionType.createPoll:
    case BotCreatorActionType.endPoll:
    case BotCreatorActionType.deleteTrigger:
    case BotCreatorActionType.attachImage:
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
    case BotCreatorActionType.moveToVoiceChannel:
    case BotCreatorActionType.disconnectFromVoice:
    case BotCreatorActionType.serverMuteMember:
    case BotCreatorActionType.serverDeafenMember:
    case BotCreatorActionType.createAutoModRule:
    case BotCreatorActionType.deleteAutoModRule:
    case BotCreatorActionType.listAutoModRules:
    case BotCreatorActionType.setNickname:
    case BotCreatorActionType.slowmode:
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
    case BotCreatorActionType.getGuildOnboarding:
    case BotCreatorActionType.updateGuildOnboarding:
    case BotCreatorActionType.updateSelfUser:
      return 'Guild & Members';
    case BotCreatorActionType.httpRequest:
    case BotCreatorActionType.setGlobalVariable:
    case BotCreatorActionType.getGlobalVariable:
    case BotCreatorActionType.removeGlobalVariable:
    case BotCreatorActionType.setScopedVariable:
    case BotCreatorActionType.setTemporaryVariable:
    case BotCreatorActionType.getScopedVariable:
    case BotCreatorActionType.removeScopedVariable:
    case BotCreatorActionType.renameScopedVariable:
    case BotCreatorActionType.listScopedVariableIndex:
    case BotCreatorActionType.appendArrayElement:
    case BotCreatorActionType.removeArrayElement:
    case BotCreatorActionType.queryArray:
      return 'HTTP & Variables';
    case BotCreatorActionType.runWorkflow:
    case BotCreatorActionType.runBdfdScript:
    case BotCreatorActionType.debugProfile:
    case BotCreatorActionType.log:
    case BotCreatorActionType.runtimeJsonBlock:
    case BotCreatorActionType.runtimeImageBlock:
    case BotCreatorActionType.canvasCreateBlock:
    case BotCreatorActionType.canvasLoadImageBlock:
    case BotCreatorActionType.canvasDrawTextBlock:
    case BotCreatorActionType.canvasDrawCircleBlock:
    case BotCreatorActionType.canvasDrawRectBlock:
    case BotCreatorActionType.canvasDrawLineBlock:
    case BotCreatorActionType.registerGuildCommands:
    case BotCreatorActionType.unregisterGuildCommands:
      return 'Workflows';
    case BotCreatorActionType.stopUnless:
    case BotCreatorActionType.ifBlock:
    case BotCreatorActionType.forLoop:
    case BotCreatorActionType.jsonForEachLoop:
    case BotCreatorActionType.calculate:
    case BotCreatorActionType.cooldown:
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
    case BotCreatorActionType.listenAndExecute:
    case BotCreatorActionType.respondWithAutocomplete:
    case BotCreatorActionType.deferInteraction:
    case BotCreatorActionType.sendDm:
      return 'Interactions';
  }
}

/// Localizes a category name for display.
String localizeCategory(BuildContext context, String category) {
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

/// Returns the accent [Color] for a given category name.
Color getCategoryColor(String category) {
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
    case 'HTTP & Variables':
      return Colors.cyan;
    case 'Workflows':
      return AppTheme.brandPrimary;
    case 'Logic & Flow':
      return Colors.pink;
    case 'Interactions':
      return AppTheme.premiumGold;
    // Fixed blocks
    case 'Metadata':
      return AppTheme.info;
    case 'EntryPoint':
      return Colors.lime.shade700;
    default:
      return AppTheme.grey;
  }
}

/// Returns the [IconData] for a category.
IconData getCategoryIcon(String category) {
  switch (category) {
    case 'Messages':
      return Icons.message;
    case 'Reactions':
      return Icons.emoji_emotions;
    case 'Channels':
      return Icons.tag;
    case 'Moderation':
      return Icons.shield;
    case 'Components':
      return Icons.widgets;
    case 'Webhooks':
      return Icons.webhook;
    case 'Guild & Members':
      return Icons.groups;
    case 'HTTP & Variables':
      return Icons.http;
    case 'Workflows':
      return Icons.account_tree;
    case 'Logic & Flow':
      return Icons.fork_right;
    case 'Interactions':
      return Icons.touch_app;
    default:
      return Icons.extension;
  }
}
/// Returns true for actions that are ONLY meaningful with a Discord
/// interaction (slash command / component callback). These are hidden
/// from prefix-command and event-workflow editors.
///
/// Note: [respondWithMessage] and [respondWithComponentV2] are intentionally
/// NOT in this list — they fall back to a plain channel send when no
/// interaction is present and therefore work in all contexts.
bool isInteractionOnlyAction(BotCreatorActionType type) {
  switch (type) {
    case BotCreatorActionType.respondWithModal:
    case BotCreatorActionType.deferInteraction:
    case BotCreatorActionType.editInteractionMessage:
      return true;
    default:
      return false;
  }
}

/// Returns true for actions that only make sense inside an autocomplete handler.
bool isAutocompleteOnlyAction(BotCreatorActionType type) {
  return type == BotCreatorActionType.respondWithAutocomplete;
}

/// Returns true for actions that are allowed in an autocomplete handler context.
/// Only data fetching (HTTP, variables), logic (conditions, loops, math),
/// debugging, and the essential [respondWithAutocomplete] are included.
bool isAutocompleteContextAction(BotCreatorActionType type) {
  switch (type) {
    // ── Essential autocomplete response ──
    case BotCreatorActionType.respondWithAutocomplete:
    // ── Data fetching ──
    case BotCreatorActionType.httpRequest:
    // ── Variables ──
    case BotCreatorActionType.setGlobalVariable:
    case BotCreatorActionType.getGlobalVariable:
    case BotCreatorActionType.removeGlobalVariable:
    case BotCreatorActionType.setScopedVariable:
    case BotCreatorActionType.getScopedVariable:
    case BotCreatorActionType.removeScopedVariable:
    case BotCreatorActionType.renameScopedVariable:
    case BotCreatorActionType.listScopedVariableIndex:
    case BotCreatorActionType.setTemporaryVariable:
    // ── Array operations ──
    case BotCreatorActionType.appendArrayElement:
    case BotCreatorActionType.removeArrayElement:
    case BotCreatorActionType.queryArray:
    // ── Math ──
    case BotCreatorActionType.calculate:
    // ── JSON processing ──
    case BotCreatorActionType.runtimeJsonBlock:
    // ── Scripting ──
    case BotCreatorActionType.runBdfdScript:
    // ── Control flow ──
    case BotCreatorActionType.ifBlock:
    case BotCreatorActionType.stopUnless:
    case BotCreatorActionType.forLoop:
    case BotCreatorActionType.jsonForEachLoop:
    case BotCreatorActionType.randomChoice:
    // ── Execution control ──
    case BotCreatorActionType.stop:
    case BotCreatorActionType.wait:
    case BotCreatorActionType.cooldown:
    // ── Debugging ──
    case BotCreatorActionType.log:
    case BotCreatorActionType.debugProfile:
      return true;
    default:
      return false;
  }
}

bool isListenerAction(BotCreatorActionType type) {
  switch (type) {
    case BotCreatorActionType.listenForButtonClick:
    case BotCreatorActionType.listenForSelectMenu:
    case BotCreatorActionType.listenForModalSubmit:
    case BotCreatorActionType.listenAndExecute:
      return true;
    default:
      return false;
  }
}

/// Returns true for deprecated canvas visual block types that should
/// no longer appear in the scratch block palette.
bool _isCanvasAction(BotCreatorActionType type) {
  switch (type) {
    case BotCreatorActionType.canvasCreateBlock:
    case BotCreatorActionType.canvasLoadImageBlock:
    case BotCreatorActionType.canvasDrawTextBlock:
    case BotCreatorActionType.canvasDrawCircleBlock:
    case BotCreatorActionType.canvasDrawRectBlock:
    case BotCreatorActionType.canvasDrawLineBlock:
      return true;
    default:
      return false;
  }
}

/// A bottom sheet / dialog that lists all available action block types grouped
/// by category. The user taps one to add it to the canvas.
class ScratchBlockPalette extends StatefulWidget {
  const ScratchBlockPalette({
    super.key,
    required this.onActionSelected,
    this.isInteraction = true,
    this.isWorkflow = false,
    this.isAutocompleteContext = false,
    this.isModalContext = false,
    this.popOnSelect = true,
  });

  final ValueChanged<BotCreatorActionType> onActionSelected;
  final bool isInteraction;
  final bool isWorkflow;

  /// When true, shows the "Respond with autocomplete" action (only valid
  /// inside an autocomplete handler workflow).
  final bool isAutocompleteContext;

  /// When true, hides "Defer Interaction" (modals can't be deferred).
  final bool isModalContext;

  /// When true, Navigator.pop(context) is called automatically when an action is selected.
  final bool popOnSelect;

  @override
  State<ScratchBlockPalette> createState() => _ScratchBlockPaletteState();
}

class _ScratchBlockPaletteState extends State<ScratchBlockPalette> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final actionsByCategory = <String, List<BotCreatorActionType>>{};

    for (final actionType in BotCreatorActionType.values) {

      if (_searchQuery.isNotEmpty &&
          !actionType
              .displayName(context)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase())) {
        continue;
      }
      if (isListenerAction(actionType)) {
        continue;
      }
      if (!widget.isInteraction && !widget.isWorkflow && isInteractionOnlyAction(actionType)) {
        continue;
      }
      // Autocomplete response is only valid inside an autocomplete handler.
      if (!widget.isAutocompleteContext && isAutocompleteOnlyAction(actionType)) {
        continue;
      }
      // Autocomplete context: only show data/logic + respondWithAutocomplete.
      if (widget.isAutocompleteContext && !isAutocompleteContextAction(actionType)) {
        continue;
      }
      // Modal context: deferInteraction doesn't make sense for modals.
      if (widget.isModalContext && actionType == BotCreatorActionType.deferInteraction) {
        continue;
      }
      // Skip deprecated canvas visual blocks.
      if (_isCanvasAction(actionType)) {
        continue;
      }
      final category = getCategoryForAction(actionType);

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
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: context.tr.actions_search_hint,
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        // ── Categories ──
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [
              if (actionsByCategory.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Center(
                    child: Text(
                      context.tr.actions_no_matches,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                for (final entry in actionsByCategory.entries)
                  _CategorySection(
                    category: entry.key,
                    actions: entry.value,
                    onActionSelected: (type) {
                      widget.onActionSelected(type);
                      if (widget.popOnSelect) {
                        Navigator.pop(context);
                      }
                    },
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.actions,
    required this.onActionSelected,
  });

  final String category;
  final List<BotCreatorActionType> actions;
  final ValueChanged<BotCreatorActionType> onActionSelected;

  @override
  Widget build(BuildContext context) {
    final color = getCategoryColor(category);
    final icon = getCategoryIcon(category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                localizeCategory(context, category),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...actions.map((type) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 2),
            child: ListTile(
              dense: true,
              leading: Icon(type.icon, size: 20, color: color),
              title: Text(
                type.displayName(context),
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () => onActionSelected(type),
            ),
          );
        }),
      ],
    );
  }
}

/// Shows the [ScratchBlockPalette] as a bottom sheet or dialog depending on
/// screen width.
void showBlockPalette(
  BuildContext context, {
  required ValueChanged<BotCreatorActionType> onActionSelected,
  bool isInteraction = true,
  bool isWorkflow = false,
  bool isAutocompleteContext = false,
  bool isModalContext = false,
}) {
  final isMobile = MediaQuery.of(context).size.width < 600;

  if (isMobile) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SafeArea(
            top: false,
            child: ScratchBlockPalette(
              onActionSelected: onActionSelected,
              isInteraction: isInteraction,
              isWorkflow: isWorkflow,
              isAutocompleteContext: isAutocompleteContext,
              isModalContext: isModalContext,
            ),
          ),
        );
      },
    );
  } else {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final maxHeight = MediaQuery.of(dialogContext).size.height * 0.8;
        return AlertDialog(
          title: Text(context.tr.actions_add_new_title),
          content: SizedBox(
            width: 500,
            height: maxHeight,
            child: ScratchBlockPalette(
              onActionSelected: onActionSelected,
              isInteraction: isInteraction,
              isWorkflow: isWorkflow,
              isAutocompleteContext: isAutocompleteContext,
              isModalContext: isModalContext,
            ),
          ),
        );
      },
    );
  }
}
