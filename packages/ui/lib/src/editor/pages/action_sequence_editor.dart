import 'dart:convert';

import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/tr_extension.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_icon.dart';
import '../blocks/action_block.dart';
import '../blocks/scratch_block_canvas.dart';
import '../blocks/scratch_block_palette.dart';
import '../blueprint/blueprint_graph_canvas.dart';
import '../blueprint/blueprint_models.dart';
import '../blueprint/blueprint_tree_ops.dart';
import '../models/app_emoji.dart';
import '../models/variable_suggestion.dart';
import 'actions_builder_page.dart';

/// Vue d'une séquence d'actions : blocs empilés ou graphe Blueprint.
enum ActionSequenceView { blocks, blueprint }

/// Éditeur d'une séquence d'actions, identique à celui de l'app : palette
/// d'actions par catégorie à gauche, blocs [ActionBlock] ou graphe
/// [BlueprintGraphCanvas] au centre (bascule en haut), palette en feuille
/// modale sur téléphone.
///
/// Il travaille sur la forme JSON des actions (`id`, `type`, `payload`, …) et
/// notifie chaque changement par [onChanged] ; l'hôte garde la persistance.
/// [leading] reçoit les blocs fixes placés avant les actions (point d'entrée,
/// métadonnées) : ils défilent avec elles en vue « blocs ».
class ActionSequenceEditor extends StatefulWidget {
  const ActionSequenceEditor({
    super.key,
    required this.actions,
    required this.onChanged,
    this.title = 'command',
    this.isInteraction = true,
    this.isWorkflow = false,
    this.variableSuggestions = const [],
    this.emojiSuggestions,
    this.botId,
    this.leading = const [],
    this.wideBreakpoint = 800,
    this.initialView = ActionSequenceView.blocks,
  });

  final List<Map<String, dynamic>> actions;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  /// Nom affiché sur le nœud d'entrée du Blueprint.
  final String title;
  final bool isInteraction;
  final bool isWorkflow;
  final List<VariableSuggestion> variableSuggestions;
  final List<AppEmoji>? emojiSuggestions;
  final String? botId;
  final List<Widget> leading;
  final double wideBreakpoint;
  final ActionSequenceView initialView;

  @override
  State<ActionSequenceEditor> createState() => _ActionSequenceEditorState();
}

class _ActionSequenceEditorState extends State<ActionSequenceEditor> {
  late List<Map<String, dynamic>> _actions;
  late ActionSequenceView _view = widget.initialView;
  final Map<String, Offset> _positions = <String, Offset>{};
  final Set<String> _severed = <String>{};

  @override
  void initState() {
    super.initState();
    _actions = _copy(widget.actions);
  }

  @override
  void didUpdateWidget(covariant ActionSequenceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nouvelle séquence venue de l'extérieur (changement de commande) : on la
    // reprend ; les modifications locales, elles, passent déjà par onChanged.
    if (!identical(oldWidget.actions, widget.actions) &&
        jsonEncode(widget.actions) != jsonEncode(_actions)) {
      _actions = _copy(widget.actions);
      _positions.clear();
      _severed.clear();
    }
  }

  static List<Map<String, dynamic>> _copy(List<Map<String, dynamic>> source) =>
      (jsonDecode(jsonEncode(source)) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

  void _apply(VoidCallback change) {
    setState(change);
    widget.onChanged(_copy(_actions));
  }

  Map<String, dynamic> _newAction(BotCreatorActionType type) {
    final id = 'action_${DateTime.now().microsecondsSinceEpoch}';
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'enabled': true,
      'key': id,
      'depend_on': <String>[],
      'error': {'mode': 'stop'},
      'payload': Map<String, dynamic>.from(type.defaultParameters),
    };
  }

  Map<String, dynamic> _clone(Map<String, dynamic> source) {
    final copy = Map<String, dynamic>.from(jsonDecode(jsonEncode(source)));
    copy['id'] = 'action_${DateTime.now().microsecondsSinceEpoch}';
    return copy;
  }

  void _insert(int index, Map<String, dynamic> action) {
    _apply(() => _actions.insert(index.clamp(0, _actions.length), action));
  }

  void _openPalette({int? insertIndex}) {
    showBlockPalette(
      context,
      isInteraction: widget.isInteraction,
      onActionSelected: (type) {
        final action = _newAction(type);
        _apply(() {
          if (insertIndex != null &&
              insertIndex >= 0 &&
              insertIndex <= _actions.length) {
            _actions.insert(insertIndex, action);
          } else {
            _actions.add(action);
          }
        });
      },
    );
  }

  void _changeParameter(int index, String key, dynamic value) {
    _apply(() {
      final action = _actions[index];
      Map<String, dynamic> error() => Map<String, dynamic>.from(
        (action['error'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
      switch (key) {
        case '__enabled__':
          action['enabled'] = value == true;
        case '__onErrorMode__':
          action['error'] = error()
            ..['mode'] = switch (value) {
              'continue' => 'continue',
              'jump' => 'jump',
              'skip' => 'skip',
              _ => 'stop',
            };
        case '__onErrorJumpTarget__':
          action['error'] = error()..['jumpToActionId'] = value?.toString();
        case '__onErrorSkipCount__':
          action['error'] = error()..['skipCount'] = value?.toString();
        case '__actionKey__':
          action['key'] = value.toString();
        default:
          final payload = Map<String, dynamic>.from(
            (action['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
          payload[key] = value;
          action['payload'] = payload;
      }
    });
  }

  Future<List<Map<String, dynamic>>?> _editNested(
    List<Map<String, dynamic>> current,
    List<VariableSuggestion> suggestions,
    String blockName, {
    void Function(List<Map<String, dynamic>>)? onChanged,
  }) {
    return Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute<List<Map<String, dynamic>>>(
        builder: (_) => ActionsBuilderPage(
          initialActions: current,
          variableSuggestions: suggestions,
          emojiSuggestions: widget.emojiSuggestions,
          botIdForConfig: widget.botId,
          editPath: [widget.title, blockName],
          onChanged: onChanged,
          isInteraction: widget.isInteraction,
          isWorkflow: widget.isWorkflow,
        ),
      ),
    );
  }

  void _connect(String fromNode, String fromPin, String toNode, String toPin) {
    _apply(() {
      connectWorkflowPins(
        actions: _actions,
        severedConnectionIds: _severed,
        fromNodeId: fromNode,
        fromPinId: fromPin,
        toNodeId: toNode,
        toPinId: toPin,
        onPersist: () {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= widget.wideBreakpoint;
    if (!wide) return _blocksCanvas(wide: false);

    final blueprint = _view == ActionSequenceView.blueprint;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(right: BorderSide(color: scheme.outlineVariant)),
          ),
          child: ScratchBlockPalette(
            onActionSelected: (type) =>
                _apply(() => _actions.add(_newAction(type))),
            isInteraction: widget.isInteraction,
            isWorkflow: widget.isWorkflow,
            popOnSelect: false,
            enableDrag: blueprint,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  border: Border(
                    bottom: BorderSide(color: scheme.outlineVariant),
                  ),
                ),
                child: Row(
                  children: [
                    const Spacer(),
                    SegmentedButton<ActionSequenceView>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: ActionSequenceView.blocks,
                          icon: const AppIcon.fromMaterial(
                            Icons.view_agenda_outlined,
                            size: 16,
                          ),
                          label: Text(
                            context.tr.scratch_blocks_tab,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        ButtonSegment(
                          value: ActionSequenceView.blueprint,
                          icon: const AppIcon.fromMaterial(
                            Icons.hub_outlined,
                            size: 16,
                          ),
                          label: Text(
                            context.tr.blueprint_mode_label,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                      selected: {_view},
                      onSelectionChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() => _view = value.first);
                        }
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: blueprint
                    ? _blueprintCanvas()
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 860),
                          child: _blocksCanvas(wide: true),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<ActionItem> get _items => [
    for (var i = 0; i < _actions.length; i++)
      ActionItem.fromJson(_actions[i], fallbackId: 'action_$i'),
  ];

  Widget _blocksCanvas({required bool wide}) {
    final items = _items;
    final prefix = widget.leading;
    final firstActionIdx = prefix.length;
    final blocks = <Widget>[
      ...prefix,
      if (_actions.isEmpty) _emptyState(),
      for (var i = 0; i < items.length; i++)
        ActionBlock(
          key: ValueKey('action-block-${items[i].id}'),
          action: items[i],
          index: i,
          totalCount: items.length,
          variableSuggestions: widget.variableSuggestions,
          emojiSuggestions: widget.emojiSuggestions,
          botIdForConfig: widget.botId,
          allActions: items,
          dragHandle: !wide && items.length > 1
              ? ReorderableDragStartListener(
                  index: firstActionIdx + i,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: AppIcon.fromMaterial(
                      Icons.drag_indicator,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                )
              : null,
          onRemove: () => _apply(() => _actions.removeAt(i)),
          onPasteAbove: (copied) => _insert(i, _clone(copied)),
          onPasteBelow: (copied) => _insert(i + 1, _clone(copied)),
          onDuplicate: () => _insert(i + 1, _clone(_actions[i])),
          onMoveUp: i > 0
              ? () => _apply(() => _actions.insert(i - 1, _actions.removeAt(i)))
              : null,
          onMoveDown: i < items.length - 1
              ? () => _apply(() => _actions.insert(i + 1, _actions.removeAt(i)))
              : null,
          onParameterChanged: (key, value) => _changeParameter(i, key, value),
          onSuggestionSelected: (key, value) => _changeParameter(i, key, value),
          fieldRefreshVersionOf: (_) => 0,
          onEditNestedActions: _editNested,
        ),
      if (!wide) _addButton(),
    ];

    // Les blocs fixes (métadonnées, point de départ) ne reçoivent pas d'action
    // entre eux : seul le dernier, le point de départ, ouvre la palette.
    final skipConnectorAfter = <int>{
      for (var i = 0; i < firstActionIdx - 1; i++) i,
    };
    if (items.isNotEmpty) {
      final last = items.length - 1;
      if (isFinalAction(items[last].type)) {
        skipConnectorAfter.add(firstActionIdx + last);
      }
      if (!wide) {
        skipConnectorAfter
          ..add(blocks.length - 2)
          ..add(blocks.length - 1);
      }
    }

    return ScratchBlockCanvas(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      skipConnectorAfterIndices: skipConnectorAfter,
      onReorder: !wide && items.length > 1
          ? (oldIndex, newIndex) {
              final from = oldIndex - firstActionIdx;
              if (from < 0 || from >= items.length) return;
              var to = newIndex - firstActionIdx;
              if (oldIndex < newIndex) to -= 1;
              to = to.clamp(0, items.length - 1);
              if (to == from) return;
              HapticFeedback.selectionClick();
              _apply(() => _actions.insert(to, _actions.removeAt(from)));
            }
          : null,
      onInsertAfter: (canvasIndex) => _openPalette(
        insertIndex: canvasIndex < firstActionIdx
            ? 0
            : (canvasIndex - firstActionIdx + 1).clamp(0, _actions.length),
      ),
      children: blocks,
    );
  }

  Widget _emptyState() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            AppIcon.fromMaterial(
              Icons.touch_app_outlined,
              size: 32,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr.cmd_block_editor_empty_title,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              context.tr.cmd_block_editor_empty_hint,
              style: TextStyle(fontSize: 13, color: AppTheme.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openPalette,
              icon: const AppIcon.fromMaterial(Icons.add),
              label: Text(context.tr.cmd_block_editor_add_action),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addButton() => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: OutlinedButton.icon(
      onPressed: _openPalette,
      icon: const AppIcon.fromMaterial(Icons.add),
      label: Text(context.tr.scratch_add_block),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        ),
      ),
    ),
  );

  Widget _blueprintCanvas() {
    return BlueprintGraphCanvas(
      commandName: widget.title.isNotEmpty ? widget.title : 'command',
      isInteraction: widget.isInteraction,
      actions: _items,
      customNodePositions: _positions,
      severedConnectionIds: _severed,
      onNodeMoved: (nodeId, position) => _positions[nodeId] = position,
      onDisconnectConnection:
          (
            connectionId, {
            fromNodeId,
            fromPinId,
            toNodeId,
            toPinId,
            toNodePosition,
            allNodePositions,
          }) {
            _apply(() {
              _severed.add(connectionId);
              if (allNodePositions != null) {
                _positions.addAll(allNodePositions);
              } else if (toNodeId != null && toNodePosition != null) {
                _positions.putIfAbsent(toNodeId, () => toNodePosition);
              }
              if (toNodeId == null) return;
              // Un nœud détaché d'une branche (IF/ELSE) et sa chaîne remontent
              // à la racine.
              final loc = findActionInBranchTrees(_actions, toNodeId);
              if (loc == null) return;
              final branch = loc.branchList;
              final extracted = branch.sublist(loc.indexInBranch);
              branch.removeRange(loc.indexInBranch, branch.length);
              loc.updateParentBranch(branch);
              final lastBefore = _actions.isNotEmpty ? _actions.last : null;
              _actions.addAll(extracted);
              if (extracted.isEmpty) return;
              if (lastBefore != null) {
                _severed.add(
                  'conn_${lastBefore['id']}_to_${extracted.first['id']}',
                );
              }
              if (loc.parentAction['id'] != null) {
                _severed.add(
                  'conn_${loc.parentAction['id']}_to_${extracted.first['id']}',
                );
              }
            });
          },
      fieldRefreshVersionOf: (_) => 0,
      variableSuggestions: widget.variableSuggestions,
      emojiSuggestions: widget.emojiSuggestions,
      botIdForConfig: widget.botId,
      onEditNestedActions: _editNested,
      onParameterChanged: _changeParameter,
      onSuggestionSelected: _changeParameter,
      onRemoveAction: (nodeId, index) =>
          _apply(() => removeActionFromTree(_actions, nodeId)),
      onAddActionAt:
          (
            type,
            canvasPosition, {
            connectFromNodeId,
            connectFromPinId,
            connectFromPinDirection,
          }) {
            final action = _newAction(type);
            final id = action['id'] as String;
            _apply(() {
              _positions[id] = canvasPosition;
              _actions.add(action);
            });
            if (connectFromNodeId != null && connectFromPinId != null) {
              if (connectFromPinDirection == BlueprintPinDirection.input) {
                _connect(id, 'exec_out', connectFromNodeId, connectFromPinId);
              } else {
                _connect(connectFromNodeId, connectFromPinId, id, 'exec_in');
              }
            }
          },
      onConnectPins: _connect,
      onDuplicateAction: (index) => _insert(index + 1, _clone(_actions[index])),
    );
  }
}
