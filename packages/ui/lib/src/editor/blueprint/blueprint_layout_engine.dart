import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import '../catalog/action_types.dart';
import '../catalog/action_type_extension.dart';
import '../blocks/scratch_block_palette.dart';
import '../../theme/block_family.dart';
import './blueprint_models.dart';

/// Result produced by layout engine containing nodes and connection wires.
class BlueprintGraphData {
  final List<BlueprintNodeData> nodes;
  final List<BlueprintConnection> connections;

  const BlueprintGraphData({required this.nodes, required this.connections});
}

/// Automatically computes 2D coordinates and flow connections for actions.
class BlueprintLayoutEngine {
  static const double nodeWidth = 240.0;
  static const double nodeHeight = 124.0;
  static const double horizontalSpacing = 80.0;
  static const double verticalSpacing = 40.0;
  static const double startX = 0.0;
  static const double startY = 0.0;

  /// Builds the complete blueprint node graph from an entry point and actions list,
  /// expanding nested branch actions (thenActions, elseActions) into sub-nodes.
  static BlueprintGraphData buildGraph({
    required BuildContext context,
    required String commandName,
    required bool isInteraction,
    required List<ActionItem> actions,
    Map<String, Offset>? customPositions,
  }) {
    final nodes = <BlueprintNodeData>[];
    final connections = <BlueprintConnection>[];

    // 1. Create Entry Point / Trigger Node at (0, 0)
    final entryId = '__entry_point__';
    final entryPos = customPositions?[entryId] ?? const Offset(startX, startY);

    final entryNode = BlueprintNodeData(
      id: entryId,
      title: isInteraction ? '/$commandName' : '!$commandName (Prefix)',
      subtitle: isInteraction
          ? 'Discord Slash Command'
          : 'Message Text Command',
      icon: isInteraction ? Icons.terminal : Icons.chat_bubble_outline,
      headerColor: BlockFamily.events.color,
      overline: BlockFamily.events.label(context),
      isEntryPoint: true,
      inPins: const [],
      outPins: const [
        BlueprintPin(
          id: 'exec_out',
          label: 'Out',
          direction: BlueprintPinDirection.output,
          type: BlueprintPinType.flow,
        ),
      ],
      position: entryPos,
      size: const Size(nodeWidth, nodeHeight),
    );
    nodes.add(entryNode);

    var currentX = entryPos.dx + nodeWidth + horizontalSpacing;
    var currentY = entryPos.dy;
    var lastNodeId = entryId;
    var lastPinId = 'exec_out';

    // 2. Build Action Nodes & Connections
    for (var i = 0; i < actions.length; i++) {
      final action = actions[i];
      final actionId = action.id;
      final category = getCategoryForAction(action.type);
      final catColor = BlockFamily.fromCategoryName(category).color;

      final isIf = action.type == BotCreatorActionType.ifBlock;
      final isFinal = isFinalAction(action.type);

      // Extract nested actions if it's an IF block
      List<Map<String, dynamic>> thenList = [];
      List<Map<String, dynamic>> elseList = [];
      List<Map<String, dynamic>> elseIfList = [];
      if (isIf) {
        if (action.parameters['thenActions'] is List) {
          thenList = (action.parameters['thenActions'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (action.parameters['elseActions'] is List) {
          elseList = (action.parameters['elseActions'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (action.parameters['elseIfConditions'] is List) {
          elseIfList = (action.parameters['elseIfConditions'] as List)
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      // Pins definition
      final inPins = [
        const BlueprintPin(
          id: 'exec_in',
          label: 'In',
          direction: BlueprintPinDirection.input,
          type: BlueprintPinType.flow,
        ),
      ];

      final outPins = <BlueprintPin>[];
      if (isIf) {
        outPins.add(
          BlueprintPin(
            id: 'then_out',
            label: 'True (${thenList.length})',
            direction: BlueprintPinDirection.output,
            type: BlueprintPinType.branch,
            customColor: const Color(0xFF4CAF50),
          ),
        );

        for (var k = 0; k < elseIfList.length; k++) {
          final kActions =
              (elseIfList[k]['actions'] as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];
          outPins.add(
            BlueprintPin(
              id: 'elseif_out_$k',
              label: 'Else If ${k + 1} (${kActions.length})',
              direction: BlueprintPinDirection.output,
              type: BlueprintPinType.branch,
              customColor: const Color(0xFFFFA000),
            ),
          );
        }

        outPins.add(
          BlueprintPin(
            id: 'else_out',
            label: 'False (${elseList.length})',
            direction: BlueprintPinDirection.output,
            type: BlueprintPinType.branch,
            customColor: const Color(0xFFE53935),
          ),
        );
        outPins.add(
          const BlueprintPin(
            id: 'exec_out',
            label: 'Completed',
            direction: BlueprintPinDirection.output,
            type: BlueprintPinType.flow,
          ),
        );
      } else if (!isFinal) {
        outPins.add(
          const BlueprintPin(
            id: 'exec_out',
            label: 'Out',
            direction: BlueprintPinDirection.output,
            type: BlueprintPinType.flow,
          ),
        );
      }

      final subtitle = _computeActionSubtitle(action);
      final nodePos = customPositions?[actionId] ?? Offset(currentX, currentY);
      final ifHeight = math.max(130.0, 36.0 + (outPins.length * 28.0));

      final node = BlueprintNodeData(
        id: actionId,
        title: action.type.displayName(context),
        subtitle: subtitle,
        icon: action.type.icon,
        headerColor: catColor,
        overline: localizeCategory(context, category),
        isEntryPoint: false,
        actionType: action.type,
        actionItem: action,
        actionIndex: i,
        inPins: inPins,
        outPins: outPins,
        position: nodePos,
        size: Size(nodeWidth, isIf ? ifHeight : nodeHeight),
      );
      nodes.add(node);

      // Connect previous flow pin to this node's exec_in
      if (lastNodeId.isNotEmpty && lastPinId.isNotEmpty) {
        connections.add(
          BlueprintConnection(
            id: 'conn_${lastNodeId}_to_$actionId',
            fromNodeId: lastNodeId,
            fromPinId: lastPinId,
            toNodeId: actionId,
            toPinId: 'exec_in',
          ),
        );
      }

      // ── Handle Nested IF Branches (True & False) ──
      var branchMaxX = currentX;
      if (isIf) {
        // Build THEN (True) branch sub-nodes
        if (thenList.isNotEmpty) {
          var branchX = currentX + nodeWidth + horizontalSpacing;
          var branchY = currentY - (thenList.length * 70.0);
          var prevBranchNodeId = actionId;
          var prevBranchPinId = 'then_out';

          for (var t = 0; t < thenList.length; t++) {
            final tItem = ActionItem.fromJson(
              thenList[t],
              fallbackId: '${actionId}_then_$t',
            );
            final subNodeId = tItem.id;
            final subCat = getCategoryForAction(tItem.type);
            final subColor = BlockFamily.fromCategoryName(subCat).color;
            final subPos =
                customPositions?[subNodeId] ??
                Offset(branchX, branchY + (t * (nodeHeight + 20)));

            nodes.add(
              BlueprintNodeData(
                id: subNodeId,
                title: tItem.type.displayName(context),
                subtitle: _computeActionSubtitle(tItem),
                icon: tItem.type.icon,
                headerColor: subColor,
                overline: localizeCategory(context, subCat),
                actionType: tItem.type,
                actionItem: tItem,
                inPins: const [
                  BlueprintPin(
                    id: 'exec_in',
                    label: 'In',
                    direction: BlueprintPinDirection.input,
                  ),
                ],
                outPins: isFinalAction(tItem.type)
                    ? const []
                    : const [
                        BlueprintPin(
                          id: 'exec_out',
                          label: 'Out',
                          direction: BlueprintPinDirection.output,
                        ),
                      ],
                position: subPos,
                size: const Size(nodeWidth, nodeHeight),
              ),
            );

            connections.add(
              BlueprintConnection(
                id: 'conn_${prevBranchNodeId}_to_$subNodeId',
                fromNodeId: prevBranchNodeId,
                fromPinId: prevBranchPinId,
                toNodeId: subNodeId,
                toPinId: 'exec_in',
                color: const Color(0xFF4CAF50), // Green for TRUE branch
              ),
            );

            prevBranchNodeId = subNodeId;
            prevBranchPinId = 'exec_out';
            if (subPos.dx > branchMaxX) branchMaxX = subPos.dx;
            branchX += nodeWidth + horizontalSpacing;
          }
        }

        // Build ELSE IF branches sub-nodes
        for (var k = 0; k < elseIfList.length; k++) {
          final kRawActions = elseIfList[k]['actions'];
          final kActions =
              (kRawActions as List?)
                  ?.whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList() ??
              [];

          if (kActions.isNotEmpty) {
            var branchX = currentX + nodeWidth + horizontalSpacing;
            var branchY = currentY + ((k + 1) * 75.0);
            var prevBranchNodeId = actionId;
            var prevBranchPinId = 'elseif_out_$k';

            for (var a = 0; a < kActions.length; a++) {
              final aItem = ActionItem.fromJson(
                kActions[a],
                fallbackId: '${actionId}_elseif_${k}_$a',
              );
              final subNodeId = aItem.id;
              final subCat = getCategoryForAction(aItem.type);
              final subColor = BlockFamily.fromCategoryName(subCat).color;
              final subPos =
                  customPositions?[subNodeId] ??
                  Offset(branchX, branchY + (a * (nodeHeight + 20)));

              nodes.add(
                BlueprintNodeData(
                  id: subNodeId,
                  title: aItem.type.displayName(context),
                  subtitle: _computeActionSubtitle(aItem),
                  icon: aItem.type.icon,
                  headerColor: subColor,
                  overline: localizeCategory(context, subCat),
                  actionType: aItem.type,
                  actionItem: aItem,
                  inPins: const [
                    BlueprintPin(
                      id: 'exec_in',
                      label: 'In',
                      direction: BlueprintPinDirection.input,
                    ),
                  ],
                  outPins: isFinalAction(aItem.type)
                      ? const []
                      : const [
                          BlueprintPin(
                            id: 'exec_out',
                            label: 'Out',
                            direction: BlueprintPinDirection.output,
                          ),
                        ],
                  position: subPos,
                  size: const Size(nodeWidth, nodeHeight),
                ),
              );

              connections.add(
                BlueprintConnection(
                  id: 'conn_${prevBranchNodeId}_to_$subNodeId',
                  fromNodeId: prevBranchNodeId,
                  fromPinId: prevBranchPinId,
                  toNodeId: subNodeId,
                  toPinId: 'exec_in',
                  color: const Color(0xFFFFA000), // Amber for ELSE IF branch
                ),
              );

              prevBranchNodeId = subNodeId;
              prevBranchPinId = 'exec_out';
              if (subPos.dx > branchMaxX) branchMaxX = subPos.dx;
              branchX += nodeWidth + horizontalSpacing;
            }
          }
        }

        // Build ELSE (False) branch sub-nodes
        if (elseList.isNotEmpty) {
          var branchX = currentX + nodeWidth + horizontalSpacing;
          var branchY =
              currentY + ((elseIfList.length + 1) * 80.0) + nodeHeight;
          var prevBranchNodeId = actionId;
          var prevBranchPinId = 'else_out';

          for (var e = 0; e < elseList.length; e++) {
            final eItem = ActionItem.fromJson(
              elseList[e],
              fallbackId: '${actionId}_else_$e',
            );
            final subNodeId = eItem.id;
            final subCat = getCategoryForAction(eItem.type);
            final subColor = BlockFamily.fromCategoryName(subCat).color;
            final subPos =
                customPositions?[subNodeId] ??
                Offset(branchX, branchY + (e * (nodeHeight + 20)));

            nodes.add(
              BlueprintNodeData(
                id: subNodeId,
                title: eItem.type.displayName(context),
                subtitle: _computeActionSubtitle(eItem),
                icon: eItem.type.icon,
                headerColor: subColor,
                overline: localizeCategory(context, subCat),
                actionType: eItem.type,
                actionItem: eItem,
                inPins: const [
                  BlueprintPin(
                    id: 'exec_in',
                    label: 'In',
                    direction: BlueprintPinDirection.input,
                  ),
                ],
                outPins: isFinalAction(eItem.type)
                    ? const []
                    : const [
                        BlueprintPin(
                          id: 'exec_out',
                          label: 'Out',
                          direction: BlueprintPinDirection.output,
                        ),
                      ],
                position: subPos,
                size: const Size(nodeWidth, nodeHeight),
              ),
            );

            connections.add(
              BlueprintConnection(
                id: 'conn_${prevBranchNodeId}_to_$subNodeId',
                fromNodeId: prevBranchNodeId,
                fromPinId: prevBranchPinId,
                toNodeId: subNodeId,
                toPinId: 'exec_in',
                color: const Color(0xFFE53935), // Red for FALSE branch
              ),
            );

            prevBranchNodeId = subNodeId;
            prevBranchPinId = 'exec_out';
            if (subPos.dx > branchMaxX) branchMaxX = subPos.dx;
            branchX += nodeWidth + horizontalSpacing;
          }
        }
      }

      // Advance layout for next main flow node
      final stepOffset = (isIf && (thenList.isNotEmpty || elseList.isNotEmpty))
          ? (branchMaxX - currentX) + nodeWidth + horizontalSpacing
          : nodeWidth + horizontalSpacing;

      currentX += stepOffset;
      lastNodeId = actionId;
      lastPinId = isFinal ? '' : 'exec_out';
    }

    return BlueprintGraphData(nodes: nodes, connections: connections);
  }

  static String _computeActionSubtitle(ActionItem action) {
    switch (action.type) {
      case BotCreatorActionType.sendMessage:
      case BotCreatorActionType.respondWithMessage:
        final msg = action.parameters['message']?.toString() ?? '';
        return msg.isNotEmpty ? msg : 'Empty message';
      case BotCreatorActionType.httpRequest:
        final method = action.parameters['method']?.toString() ?? 'GET';
        final url = action.parameters['url']?.toString() ?? '';
        return '$method ${url.isNotEmpty ? url : 'https://...'}';
      case BotCreatorActionType.setGlobalVariable:
      case BotCreatorActionType.setScopedVariable:
        final name = action.parameters['name']?.toString() ?? 'var';
        return 'Set $name';
      case BotCreatorActionType.addRole:
      case BotCreatorActionType.removeRole:
        return 'Target member role';
      case BotCreatorActionType.ifBlock:
        final variable =
            action.parameters['condition.variable']?.toString() ??
            action.parameters['left']?.toString() ??
            '';
        final op =
            action.parameters['condition.operator']?.toString() ??
            action.parameters['operator']?.toString() ??
            '==';
        final value =
            action.parameters['condition.value']?.toString() ??
            action.parameters['right']?.toString() ??
            '';
        return variable.isNotEmpty ? '$variable $op $value' : 'Condition';
      default:
        return action.actionKey.isNotEmpty
            ? action.actionKey
            : action.type.name;
    }
  }
}
