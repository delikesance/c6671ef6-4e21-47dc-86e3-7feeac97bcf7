import 'package:flutter/material.dart';

import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_card.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'scratch_block.dart';
import 'scratch_block_palette.dart';

/// A user-added action block in the Scratch-like canvas.
///
/// Wraps the existing [ActionCard] inside a [ScratchBlock] with the
/// category-appropriate colour and action icon.
class ActionBlock extends StatefulWidget {
  const ActionBlock({
    super.key,
    required this.action,
    required this.index,
    required this.totalCount,
    required this.onRemove,
    required this.onParameterChanged,
    required this.onSuggestionSelected,
    required this.fieldRefreshVersionOf,
    this.onMoveUp,
    this.onMoveDown,
    this.variableSuggestions = const [],
    this.emojiSuggestions,
    this.botIdForConfig,
    this.onEditNestedActions,
  });

  final ActionItem action;
  final int index;
  final int totalCount;
  final VoidCallback onRemove;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final Function(String key, dynamic value) onParameterChanged;
  final Function(String key, dynamic value) onSuggestionSelected;
  final int Function(String paramKey) fieldRefreshVersionOf;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final String? botIdForConfig;
  final Future<List<Map<String, dynamic>>?> Function(
    List<Map<String, dynamic>> current,
    List<VariableSuggestion> suggestions,
  )?
  onEditNestedActions;

  @override
  State<ActionBlock> createState() => _ActionBlockState();
}

class _ActionBlockState extends State<ActionBlock> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final category = getCategoryForAction(widget.action.type);
    final color = getCategoryColor(category);
    final finalBlock = isFinalAction(widget.action.type);

    return ScratchBlock(
      color: color,
      title: widget.action.type.displayName,
      icon: widget.action.type.icon,
      isFinal: finalBlock,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      onDelete: widget.onRemove,
      onMoveUp: widget.onMoveUp,
      onMoveDown: widget.onMoveDown,
      badge: ScratchBlockBadge(label: category, color: color),
      child: ActionCard(
        action: widget.action,
        index: widget.index,
        totalCount: widget.totalCount,
        actionKey: widget.action.id,
        onRemove: widget.onRemove,
        onMoveUp: widget.onMoveUp,
        onMoveDown: widget.onMoveDown,
        onParameterChanged: widget.onParameterChanged,
        onSuggestionSelected: widget.onSuggestionSelected,
        fieldRefreshVersionOf: widget.fieldRefreshVersionOf,
        variableSuggestions: widget.variableSuggestions,
        emojiSuggestions: widget.emojiSuggestions,
        botIdForConfig: widget.botIdForConfig,
        onEditNestedActions: widget.onEditNestedActions,
        // Hide ActionCard's own header/controls since ScratchBlock provides them.
        showHeader: false,
        showPositionLabel: false,
        showManagementControls: false,
      ),
    );
  }
}
