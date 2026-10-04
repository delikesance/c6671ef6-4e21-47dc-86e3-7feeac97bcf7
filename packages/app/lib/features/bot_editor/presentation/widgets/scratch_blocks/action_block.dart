import 'package:flutter/material.dart';

import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_type_extension.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_card.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'scratch_block.dart';
import 'scratch_block_palette.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

String _localString(String val) => val;

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
    this.allActions,
    this.onPasteAbove,
    this.onPasteBelow,
    this.onDuplicate,
    this.onOpenDocs,
    this.dragHandle,
    this.readOnly = false,
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
    String blockName, {
    void Function(List<Map<String, dynamic>>)? onChanged,
  })?
  onEditNestedActions;
  final List<ActionItem>? allActions;
  final Function(Map<String, dynamic> copiedAction)? onPasteAbove;
  final Function(Map<String, dynamic> copiedAction)? onPasteBelow;
  final VoidCallback? onDuplicate;
  final VoidCallback? onOpenDocs;
  final Widget? dragHandle;

  /// Displays the real editor block without editing or management controls.
  final bool readOnly;

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
    final colorScheme = Theme.of(context).colorScheme;

    final trailingWidget = PopupMenuButton<String>(
      icon: AppIcon.fromMaterial(
        Icons.more_vert,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: _localString('More actions'),
      onSelected: (value) async {
        if (value == 'move_up') {
          widget.onMoveUp?.call();
        } else if (value == 'move_down') {
          widget.onMoveDown?.call();
        } else if (value == 'copy') {
          await ActionClipboard.copyAction(widget.action.toJson());
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_localString('Action copied to clipboard')),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        } else if (value == 'duplicate') {
          widget.onDuplicate?.call();
        } else if (value == 'paste_above') {
          final copied = await ActionClipboard.getCopiedAction();
          if (copied != null) {
            widget.onPasteAbove?.call(copied);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_localString('No action in clipboard')),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            }
          }
        } else if (value == 'paste_below') {
          final copied = await ActionClipboard.getCopiedAction();
          if (copied != null) {
            widget.onPasteBelow?.call(copied);
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_localString('No action in clipboard')),
                  duration: const Duration(milliseconds: 1500),
                ),
              );
            }
          }
        } else if (value == 'docs') {
          widget.onOpenDocs?.call();
        }
      },
      itemBuilder: (context) => [
        if (widget.onMoveUp != null)
          PopupMenuItem(
            value: 'move_up',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.fromMaterial(Icons.arrow_upward, size: 18),
                const SizedBox(width: 12),
                Text(_localString('Move up')),
              ],
            ),
          ),
        if (widget.onMoveDown != null)
          PopupMenuItem(
            value: 'move_down',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.fromMaterial(Icons.arrow_downward, size: 18),
                const SizedBox(width: 12),
                Text(_localString('Move down')),
              ],
            ),
          ),
        PopupMenuItem(
          value: 'copy',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon.fromMaterial(Icons.copy, size: 18),
              const SizedBox(width: 12),
              Text(_localString('Copy action')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'duplicate',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon.fromMaterial(Icons.copy_all, size: 18),
              const SizedBox(width: 12),
              Text(_localString('Duplicate')),
            ],
          ),
        ),
        if (widget.onOpenDocs != null) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'docs',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppIcon.fromMaterial(
                  Icons.help_outline_rounded,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(_localString('Documentation & guides')),
              ],
            ),
          ),
        ],
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'paste_above',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon.fromMaterial(Icons.vertical_align_top, size: 18),
              const SizedBox(width: 12),
              Text(_localString('Paste Above')),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'paste_below',
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppIcon.fromMaterial(Icons.vertical_align_bottom, size: 18),
              const SizedBox(width: 12),
              Text(_localString('Paste Below')),
            ],
          ),
        ),
      ],
    );

    return ScratchBlock(
      color: color,
      title: widget.action.type.displayName(context),
      icon: widget.action.type.icon,
      isFinal: finalBlock,
      collapsed: _collapsed,
      onToggleCollapse: () => setState(() => _collapsed = !_collapsed),
      onDelete: widget.readOnly ? null : widget.onRemove,
      badge: ScratchBlockBadge(label: category, color: color),
      trailing: widget.readOnly ? null : trailingWidget,
      dragHandle: widget.readOnly ? null : widget.dragHandle,
      child: ExcludeFocus(
        excluding: widget.readOnly,
        child: IgnorePointer(
          ignoring: widget.readOnly,
          child: ActionCard(
            action: widget.action,
            index: widget.index,
            totalCount: widget.totalCount,
            actionKey: widget.action.actionKey,
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
            allActions: widget.allActions,
          ),
        ),
      ),
    );
  }
}
