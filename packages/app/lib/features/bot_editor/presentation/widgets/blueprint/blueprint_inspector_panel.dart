import 'package:flutter/material.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'blueprint_models.dart';

/// Right-hand drawer inspector panel to edit action parameters directly in Blueprint mode.
class BlueprintInspectorPanel extends StatelessWidget {
  final BlueprintNodeData node;
  final VoidCallback onClose;
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
  final VoidCallback? onDelete;

  const BlueprintInspectorPanel({
    super.key,
    required this.node,
    required this.onClose,
    required this.onParameterChanged,
    required this.onSuggestionSelected,
    required this.fieldRefreshVersionOf,
    this.variableSuggestions = const [],
    this.emojiSuggestions,
    this.botIdForConfig,
    this.onEditNestedActions,
    this.allActions,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(-3, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Inspector Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: node.headerColor.withValues(alpha: 0.15),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(node.icon, color: node.headerColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: context.tr.blueprint_close_inspector,
                  onPressed: onClose,
                ),
              ],
            ),
          ),

          // ── Inspector Body ──
          Expanded(
            child: node.actionItem != null
                ? SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: ActionCard(
                      key: ValueKey('blueprint-inspect-${node.actionItem!.id}'),
                      action: node.actionItem!,
                      index: node.actionIndex ?? 0,
                      totalCount: allActions?.length ?? 1,
                      actionKey: node.actionItem!.actionKey,
                      variableSuggestions: variableSuggestions,
                      emojiSuggestions: emojiSuggestions,
                      fieldRefreshVersionOf: fieldRefreshVersionOf,
                      onParameterChanged: onParameterChanged,
                      onSuggestionSelected: onSuggestionSelected,
                      onRemove: onDelete ?? () {},
                      botIdForConfig: botIdForConfig,
                      onEditNestedActions: onEditNestedActions,
                      allActions: allActions,
                      showHeader: false,
                      showManagementControls: false,
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(context.tr.blueprint_entry_point_hint,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
