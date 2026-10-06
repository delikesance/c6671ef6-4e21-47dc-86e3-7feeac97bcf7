import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:flutter/foundation.dart';

class BlueprintBranchLocation {
  final Map<String, dynamic> parentAction;
  final String branchKey; // 'thenActions', 'elseActions', or 'elseIfConditions'
  final int? elseIfIndex;
  final List<Map<String, dynamic>> branchList;
  final int indexInBranch;
  final Map<String, dynamic> targetAction;

  BlueprintBranchLocation({
    required this.parentAction,
    required this.branchKey,
    this.elseIfIndex,
    required this.branchList,
    required this.indexInBranch,
    required this.targetAction,
  });

  void updateParentBranch(List<Map<String, dynamic>> updatedList) {
    final payload = Map<String, dynamic>.from(
      (parentAction['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    if (branchKey == 'elseIfConditions' && elseIfIndex != null) {
      final elseIfList = (payload['elseIfConditions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (elseIfIndex! >= 0 && elseIfIndex! < elseIfList.length) {
        final condition = Map<String, dynamic>.from(elseIfList[elseIfIndex!]);
        condition['actions'] = updatedList;
        elseIfList[elseIfIndex!] = condition;
        payload['elseIfConditions'] = elseIfList;
      }
    } else {
      payload[branchKey] = updatedList;
    }
    parentAction['payload'] = payload;
  }
}

BlueprintBranchLocation? findActionInBranchTrees(
  List<Map<String, dynamic>> actions,
  String targetId,
) {
  for (final action in actions) {
    final payload = (action['payload'] as Map?)?.cast<String, dynamic>();
    if (payload != null) {
      for (final branchKey in const ['thenActions', 'elseActions']) {
        final listRaw = payload[branchKey];
        if (listRaw is List) {
          final branchList = listRaw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          for (int i = 0; i < branchList.length; i++) {
            final item = branchList[i];
            if (item['id'] == targetId || item['key'] == targetId) {
              return BlueprintBranchLocation(
                parentAction: action,
                branchKey: branchKey,
                branchList: branchList,
                indexInBranch: i,
                targetAction: item,
              );
            }
          }
          final nested = findActionInBranchTrees(branchList, targetId);
          if (nested != null) return nested;
        }
      }

      final elseIfRaw = payload['elseIfConditions'];
      if (elseIfRaw is List) {
        final elseIfList = elseIfRaw
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        for (int k = 0; k < elseIfList.length; k++) {
          final cond = elseIfList[k];
          final condActionsRaw = cond['actions'];
          if (condActionsRaw is List) {
            final branchList = condActionsRaw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            for (int i = 0; i < branchList.length; i++) {
              final item = branchList[i];
              if (item['id'] == targetId || item['key'] == targetId) {
                return BlueprintBranchLocation(
                  parentAction: action,
                  branchKey: 'elseIfConditions',
                  elseIfIndex: k,
                  branchList: branchList,
                  indexInBranch: i,
                  targetAction: item,
                );
              }
            }
            final nested = findActionInBranchTrees(branchList, targetId);
            if (nested != null) return nested;
          }
        }
      }
    }
  }
  return null;
}

Map<String, dynamic>? removeActionFromTree(
  List<Map<String, dynamic>> rootActions,
  String actionId,
) {
  final rootIdx = rootActions.indexWhere(
    (a) => a['id'] == actionId || a['key'] == actionId,
  );
  if (rootIdx != -1) {
    return rootActions.removeAt(rootIdx);
  }

  final loc = findActionInBranchTrees(rootActions, actionId);
  if (loc != null) {
    final list = loc.branchList;
    final removed = list.removeAt(loc.indexInBranch);
    loc.updateParentBranch(list);
    return removed;
  }

  return null;
}

void connectWorkflowPins({
  required List<Map<String, dynamic>> actions,
  required Set<String> severedConnectionIds,
  required String fromNodeId,
  required String fromPinId,
  required String toNodeId,
  required String toPinId,
  VoidCallback? onPersist,
}) {
  // Un-sever any previously severed connections between these nodes
  severedConnectionIds.removeWhere(
    (id) =>
        (id.contains(fromNodeId) && id.contains(toNodeId)) ||
        (id.contains(toNodeId) && id.contains(fromNodeId)),
  );

  // 0. Handle connecting from Entry Point (__entry_point__)
  if (fromNodeId == '__entry_point__') {
    var toIndex = actions.indexWhere((a) => a['id'] == toNodeId);
    if (toIndex == -1) {
      final extracted = removeActionFromTree(actions, toNodeId);
      if (extracted != null) {
        actions.insert(0, extracted);
        onPersist?.call();
        return;
      }
    } else {
      final item = actions.removeAt(toIndex);
      actions.insert(0, item);
      onPersist?.call();
      return;
    }
  }

  // 1. Check if connecting from then_out, else_out, or elseif_out_k of an IF block
  if (fromPinId == 'then_out' ||
      fromPinId == 'else_out' ||
      fromPinId.startsWith('elseif_out_')) {
    Map<String, dynamic>? fromAction;
    final rootFromIdx = actions.indexWhere((a) => a['id'] == fromNodeId);
    if (rootFromIdx != -1) {
      fromAction = actions[rootFromIdx];
    } else {
      final nestedLoc = findActionInBranchTrees(actions, fromNodeId);
      if (nestedLoc != null) {
        fromAction = nestedLoc.targetAction;
      }
    }

    if (fromAction != null &&
        fromAction['type'] == BotCreatorActionType.ifBlock.name) {
      final toAction = removeActionFromTree(actions, toNodeId);
      if (toAction != null) {
        final payload = Map<String, dynamic>.from(
          (fromAction['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        );

        if (fromPinId.startsWith('elseif_out_')) {
          final k =
              int.tryParse(fromPinId.replaceFirst('elseif_out_', '')) ?? 0;
          final elseIfList = List<Map<String, dynamic>>.from(
            (payload['elseIfConditions'] as List?)?.map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ) ??
                const [],
          );
          if (k < elseIfList.length) {
            final branchActions = List<Map<String, dynamic>>.from(
              (elseIfList[k]['actions'] as List?)?.map(
                    (e) => Map<String, dynamic>.from(e as Map),
                  ) ??
                  const [],
            );
            branchActions.add(toAction);
            elseIfList[k]['actions'] = branchActions;
            payload['elseIfConditions'] = elseIfList;
            fromAction['payload'] = payload;
            onPersist?.call();
            return;
          }
        } else {
          final branchKey = fromPinId == 'then_out'
              ? 'thenActions'
              : 'elseActions';
          final branchList = List<Map<String, dynamic>>.from(
            (payload[branchKey] as List?)?.map(
                  (e) => Map<String, dynamic>.from(e as Map),
                ) ??
                const [],
          );
          branchList.add(toAction);
          payload[branchKey] = branchList;
          fromAction['payload'] = payload;
          onPersist?.call();
          return;
        }
      }
    }
  }

  // 2. Check if connecting from a node that is inside an IF branch
  final fromBranchLoc = findActionInBranchTrees(actions, fromNodeId);
  if (fromBranchLoc != null && fromPinId == 'exec_out') {
    final toAction = removeActionFromTree(actions, toNodeId);
    if (toAction != null) {
      final list = fromBranchLoc.branchList;
      list.insert(fromBranchLoc.indexInBranch + 1, toAction);
      fromBranchLoc.updateParentBranch(list);
      onPersist?.call();
      return;
    }
  }

  // 3. Connect between root actions (standard sequential flow)
  final fromIndex = actions.indexWhere((a) => a['id'] == fromNodeId);
  var toIndex = actions.indexWhere((a) => a['id'] == toNodeId);
  if (toIndex == -1) {
    final extracted = removeActionFromTree(actions, toNodeId);
    if (extracted != null) {
      final targetIdx = fromIndex != -1 ? fromIndex + 1 : actions.length;
      actions.insert(targetIdx.clamp(0, actions.length), extracted);
      onPersist?.call();
      return;
    }
  } else if (fromIndex != -1) {
    final item = actions.removeAt(toIndex);
    final newIndex = actions.indexWhere((a) => a['id'] == fromNodeId);
    actions.insert((newIndex + 1).clamp(0, actions.length), item);
    onPersist?.call();
  }
}
