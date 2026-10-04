import 'package:flutter/material.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/models/types/app_emoji.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'blueprint_models.dart';
import 'blueprint_layout_engine.dart';
import 'blueprint_graph_painter.dart';
import 'blueprint_minimap.dart';
import 'blueprint_node_widget.dart';
import 'blueprint_inspector_panel.dart';
import 'blueprint_context_menu.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Full interactive 2D Blueprint Node Graph Canvas for Desktop Bot Creator.
///
/// Features:
/// - Infinite canvas navigation (pan anywhere, zoom 0.15x to 3.0x).
/// - Origin coordinate (0, 0) anchored at first block.
/// - Drag & drop action cards from palette onto canvas at mouse position.
/// - Right-click on grid or wire-drop in empty space opens "Spawn Action" context search.
/// - Interactive cable wiring: drag from Pin Out to Pin In to connect.
/// - Cable selection and deletion with Delete / Backspace or Right-click "Break Links".
class BlueprintGraphCanvas extends StatefulWidget {
  final String commandName;
  final bool isInteraction;
  final List<ActionItem> actions;
  final Function(
    BotCreatorActionType type,
    Offset canvasPosition, {
    String? connectFromNodeId,
    String? connectFromPinId,
    BlueprintPinDirection? connectFromPinDirection,
  })
  onAddActionAt;
  final Function(int index, String key, dynamic value) onParameterChanged;
  final Function(int index, String key, dynamic value) onSuggestionSelected;
  final Function(String nodeId, int? index) onRemoveAction;
  final Function(int index) onDuplicateAction;
  final Function(
    String fromNodeId,
    String fromPinId,
    String toNodeId,
    String toPinId,
  )?
  onConnectPins;
  final Map<String, Offset>? customNodePositions;
  final Set<String>? severedConnectionIds;
  final Function(String nodeId, Offset position)? onNodeMoved;
  final void Function(
    String connectionId, {
    String? fromNodeId,
    String? fromPinId,
    String? toNodeId,
    String? toPinId,
    Offset? toNodePosition,
    Map<String, Offset>? allNodePositions,
  })?
  onDisconnectConnection;
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

  const BlueprintGraphCanvas({
    super.key,
    required this.commandName,
    required this.isInteraction,
    required this.actions,
    required this.onAddActionAt,
    required this.onParameterChanged,
    required this.onSuggestionSelected,
    required this.onRemoveAction,
    required this.onDuplicateAction,
    this.customNodePositions,
    this.severedConnectionIds,
    this.onNodeMoved,
    this.onConnectPins,
    this.onDisconnectConnection,
    required this.fieldRefreshVersionOf,
    this.variableSuggestions = const [],
    this.emojiSuggestions,
    this.botIdForConfig,
    this.onEditNestedActions,
  });

  @override
  State<BlueprintGraphCanvas> createState() => _BlueprintGraphCanvasState();
}

class _BlueprintGraphCanvasState extends State<BlueprintGraphCanvas> {
  final TransformationController _transformController =
      TransformationController();
  final FocusNode _keyboardFocusNode = FocusNode();
  final Map<String, Offset> _customNodePositions = {};
  final Set<String> _severedConnectionIds = {};
  final List<BlueprintConnection> _customConnections = [];

  String? _selectedNodeId;
  String? _selectedConnectionId;

  // Active cable drag state
  BlueprintPin? _draggingPin;
  String? _draggingFromNodeId;
  Offset? _draggingWireTarget; // Global canvas space

  // Context menu state
  Offset? _contextMenuScreenPos;
  Offset? _contextMenuCanvasPos;
  String? _pendingConnectNodeId;
  BlueprintPin? _pendingConnectPin;

  /// Virtual canvas workspace size.
  static const double _canvasSize = 200000.0;
  static const Offset _canvasOrigin = Offset(_canvasSize / 2, _canvasSize / 2);

  BlueprintGraphData? _lastBuiltGraph;
  List<BlueprintConnection> _lastConnections = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _centerCanvas();
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _centerCanvas() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final viewHeight = renderBox?.hasSize == true
        ? renderBox!.size.height
        : 600.0;

    final targetX = -_canvasOrigin.dx + 80.0;
    final targetY = -_canvasOrigin.dy + (viewHeight / 2) - 60.0;

    _transformController.value = Matrix4.identity()
      ..translateByDouble(targetX, targetY, 0.0, 1.0)
      ..scaleByDouble(1.0, 1.0, 1.0, 1.0);
  }

  Size _viewportSize() {
    final renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.hasSize == true ? renderBox!.size : const Size(800, 600);
  }

  /// Moves the view so [canvasPoint] sits at the center, keeping the zoom.
  void _centerOn(Offset canvasPoint, Size viewport) {
    final scale = _transformController.value.getMaxScaleOnAxis();
    final global = canvasPoint + _canvasOrigin;
    _transformController.value = Matrix4.identity()
      ..translateByDouble(
        viewport.width / 2 - global.dx * scale,
        viewport.height / 2 - global.dy * scale,
        0.0,
        1.0,
      )
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }

  Offset _screenToCanvas(Offset screenOffset) {
    final matrix = _transformController.value;
    final inv = Matrix4.inverted(matrix);
    final transformed = MatrixUtils.transformPoint(inv, screenOffset);
    return Offset(
      transformed.dx - _canvasOrigin.dx,
      transformed.dy - _canvasOrigin.dy,
    );
  }

  Offset _canvasToScreen(Offset canvasOffset) {
    final matrix = _transformController.value;
    final globalCanvasPos = Offset(
      canvasOffset.dx + _canvasOrigin.dx,
      canvasOffset.dy + _canvasOrigin.dy,
    );
    return MatrixUtils.transformPoint(matrix, globalCanvasPos);
  }

  Offset _globalToCanvas(Offset globalPosition) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPosition);
      return _screenToCanvas(localPos);
    }
    return _screenToCanvas(globalPosition);
  }

  void _handlePinDragRelease([Offset? releaseCanvasPos]) {
    final canvasPos = releaseCanvasPos ?? _draggingWireTarget;
    final fromId = _draggingFromNodeId;
    final fromPin = _draggingPin;

    if (fromId == null || fromPin == null || canvasPos == null) {
      setState(() {
        _draggingPin = null;
        _draggingFromNodeId = null;
        _draggingWireTarget = null;
      });
      return;
    }

    // Find if dropped onto an input pin of another node
    BlueprintNodeData? hitNode;
    BlueprintPin? hitPin;

    final currentGraph = _lastBuiltGraph;
    if (currentGraph != null) {
      for (final n in currentGraph.nodes) {
        if (n.id == fromId) continue;
        for (final p in n.inPins) {
          final pinPos = n.getPinCanvasPosition(p.id);
          if ((canvasPos - pinPos).distance < 32.0) {
            hitNode = n;
            hitPin = p;
            break;
          }
        }
        if (hitNode != null) break;
      }
    }

    if (hitNode != null && hitPin != null) {
      final toId = hitNode.id;
      // Clear severed connection status between these nodes
      _severedConnectionIds.removeWhere(
        (id) =>
            (id.contains(fromId) && id.contains(toId)) ||
            (id.contains(toId) && id.contains(fromId)),
      );
      final newConn = BlueprintConnection(
        id: 'conn_${fromId}_to_${toId}_${DateTime.now().microsecondsSinceEpoch}',
        fromNodeId: fromId,
        fromPinId: fromPin.id,
        toNodeId: toId,
        toPinId: hitPin.id,
      );
      setState(() {
        _customConnections.add(newConn);
      });
      if (widget.onConnectPins != null) {
        widget.onConnectPins!(fromId, fromPin.id, toId, hitPin.id);
      }
    } else {
      // Dropped in empty space: open Unreal spawn action context menu if dragged sufficiently
      final fromN = currentGraph?.nodes.cast<BlueprintNodeData?>().firstWhere(
        (n) => n?.id == fromId,
        orElse: () => null,
      );
      final startPos = fromN?.getPinCanvasPosition(fromPin.id) ?? canvasPos;
      if ((canvasPos - startPos).distance > 30.0) {
        final screenPos = _canvasToScreen(canvasPos);
        setState(() {
          _contextMenuScreenPos = screenPos;
          _contextMenuCanvasPos = canvasPos;
          _pendingConnectNodeId = fromId;
          _pendingConnectPin = fromPin;
        });
      }
    }

    setState(() {
      _draggingPin = null;
      _draggingFromNodeId = null;
      _draggingWireTarget = null;
    });
  }

  void _deleteSelectedConnection() {
    if (_selectedConnectionId != null) {
      final connId = _selectedConnectionId!;
      _severedConnectionIds.add(connId);

      final conn = _lastConnections.cast<BlueprintConnection?>().firstWhere(
        (c) => c?.id == connId,
        orElse: () => null,
      );

      final toNode = conn != null && _lastBuiltGraph != null
          ? _lastBuiltGraph!.nodes.cast<BlueprintNodeData?>().firstWhere(
              (n) => n?.id == conn.toNodeId,
              orElse: () => null,
            )
          : null;

      final allPositions = _lastBuiltGraph != null
          ? {for (final n in _lastBuiltGraph!.nodes) n.id: n.position}
          : null;

      if (widget.onDisconnectConnection != null) {
        widget.onDisconnectConnection!(
          connId,
          fromNodeId: conn?.fromNodeId,
          fromPinId: conn?.fromPinId,
          toNodeId: conn?.toNodeId,
          toPinId: conn?.toPinId,
          toNodePosition: toNode?.position,
          allNodePositions: allPositions,
        );
      }
      setState(() {
        _customConnections.removeWhere((c) => c.id == connId);
        _selectedConnectionId = null;
      });
    }
  }

  void _deleteSelectedNode() {
    if (_selectedNodeId != null && _selectedNodeId != '__entry_point__') {
      final nodeId = _selectedNodeId!;
      final node = _lastBuiltGraph?.nodes.cast<BlueprintNodeData?>().firstWhere(
        (n) => n?.id == nodeId,
        orElse: () => null,
      );
      widget.onRemoveAction(nodeId, node?.actionIndex);
      setState(() {
        _selectedNodeId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = HomeTokens.of(context).accentRing;

    // Sync external custom positions and severed connections if provided
    if (widget.customNodePositions != null) {
      for (final entry in widget.customNodePositions!.entries) {
        _customNodePositions.putIfAbsent(entry.key, () => entry.value);
      }
    }
    if (widget.severedConnectionIds != null) {
      _severedConnectionIds.clear();
      _severedConnectionIds.addAll(widget.severedConnectionIds!);
    }

    // Build graph with entry point at (0, 0)
    final baseGraph = BlueprintLayoutEngine.buildGraph(
      context: context,
      commandName: widget.commandName,
      isInteraction: widget.isInteraction,
      actions: widget.actions,
      customPositions: _customNodePositions,
    );
    _lastBuiltGraph = baseGraph;

    // Clean up temporary custom connections once incorporated into baseGraph
    _customConnections.removeWhere(
      (c) => baseGraph.connections.any(
        (bc) => bc.fromNodeId == c.fromNodeId && bc.toNodeId == c.toNodeId,
      ),
    );

    // Merge default layout connections with user connections, filtering out severed connections
    final allConnections = <BlueprintConnection>[
      ...baseGraph.connections.where(
        (c) =>
            !_severedConnectionIds.contains(c.id) &&
            !_customConnections.any((uc) => uc.id == c.id),
      ),
      ..._customConnections.where((c) => !_severedConnectionIds.contains(c.id)),
    ];
    _lastConnections = allConnections;

    final selectedNode = _selectedNodeId != null
        ? baseGraph.nodes.cast<BlueprintNodeData?>().firstWhere(
            (n) => n?.id == _selectedNodeId,
            orElse: () => null,
          )
        : null;

    final selectedConn = _selectedConnectionId != null
        ? allConnections.cast<BlueprintConnection?>().firstWhere(
            (c) => c?.id == _selectedConnectionId,
            orElse: () => null,
          )
        : null;

    Offset? selectedConnMidScreen;
    if (selectedConn != null) {
      final fromN = baseGraph.nodes.cast<BlueprintNodeData?>().firstWhere(
        (n) => n?.id == selectedConn.fromNodeId,
        orElse: () => null,
      );
      final toN = baseGraph.nodes.cast<BlueprintNodeData?>().firstWhere(
        (n) => n?.id == selectedConn.toNodeId,
        orElse: () => null,
      );
      if (fromN != null && toN != null) {
        final startCanvas = fromN.getPinCanvasPosition(selectedConn.fromPinId);
        final endCanvas = toN.getPinCanvasPosition(selectedConn.toPinId);
        final midCanvas = Offset(
          (startCanvas.dx + endCanvas.dx) / 2,
          (startCanvas.dy + endCanvas.dy) / 2,
        );
        selectedConnMidScreen = _canvasToScreen(midCanvas);
      }
    }

    return ClipRect(
      child: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.delete ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_selectedConnectionId != null) {
                _deleteSelectedConnection();
                return KeyEventResult.handled;
              }
              if (_selectedNodeId != null &&
                  _selectedNodeId != '__entry_point__') {
                _deleteSelectedNode();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: DragTarget<BotCreatorActionType>(
          onWillAcceptWithDetails: (details) => true,
          onAcceptWithDetails: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox != null) {
              final localPos = renderBox.globalToLocal(details.offset);
              final canvasPos = _screenToCanvas(localPos);
              widget.onAddActionAt(details.data, canvasPos);
            }
          },
          builder: (context, candidateData, rejectedData) {
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // ── Infinite 2D Zoomable & Pannable Canvas View ──
                Positioned.fill(
                  child: GestureDetector(
                    onTapDown: (details) {
                      _keyboardFocusNode.requestFocus();
                      setState(() {
                        _contextMenuScreenPos = null;
                        _contextMenuCanvasPos = null;
                        _pendingConnectNodeId = null;
                        _pendingConnectPin = null;
                        _selectedNodeId = null;

                        // Check if a connection cable was tapped
                        final localCanvasPos =
                            _screenToCanvas(details.localPosition) +
                            _canvasOrigin;
                        final hitConn = allConnections
                            .cast<BlueprintConnection?>()
                            .firstWhere((c) {
                              if (c == null) return false;
                              final fromN = baseGraph.nodes
                                  .cast<BlueprintNodeData?>()
                                  .firstWhere(
                                    (n) => n?.id == c.fromNodeId,
                                    orElse: () => null,
                                  );
                              final toN = baseGraph.nodes
                                  .cast<BlueprintNodeData?>()
                                  .firstWhere(
                                    (n) => n?.id == c.toNodeId,
                                    orElse: () => null,
                                  );
                              if (fromN == null || toN == null) return false;
                              final start =
                                  fromN.getPinCanvasPosition(c.fromPinId) +
                                  _canvasOrigin;
                              final end =
                                  toN.getPinCanvasPosition(c.toPinId) +
                                  _canvasOrigin;
                              return BlueprintGraphPainter.isPointNearCurve(
                                point: localCanvasPos,
                                start: start,
                                end: end,
                                hitDistance: 20.0,
                              );
                            }, orElse: () => null);

                        _selectedConnectionId = hitConn?.id;
                      });
                    },
                    onSecondaryTapDown: (details) {
                      final canvasPos = _screenToCanvas(details.localPosition);
                      final localCanvasPos = canvasPos + _canvasOrigin;

                      // If right-clicked on a connection cable, cut it immediately
                      final hitConn = allConnections
                          .cast<BlueprintConnection?>()
                          .firstWhere((c) {
                            if (c == null) return false;
                            final fromN = baseGraph.nodes
                                .cast<BlueprintNodeData?>()
                                .firstWhere(
                                  (n) => n?.id == c.fromNodeId,
                                  orElse: () => null,
                                );
                            final toN = baseGraph.nodes
                                .cast<BlueprintNodeData?>()
                                .firstWhere(
                                  (n) => n?.id == c.toNodeId,
                                  orElse: () => null,
                                );
                            if (fromN == null || toN == null) return false;
                            final start =
                                fromN.getPinCanvasPosition(c.fromPinId) +
                                _canvasOrigin;
                            final end =
                                toN.getPinCanvasPosition(c.toPinId) +
                                _canvasOrigin;
                            return BlueprintGraphPainter.isPointNearCurve(
                              point: localCanvasPos,
                              start: start,
                              end: end,
                              hitDistance: 20.0,
                            );
                          }, orElse: () => null);

                      if (hitConn != null) {
                        setState(() {
                          _selectedConnectionId = hitConn.id;
                        });
                        _deleteSelectedConnection();
                        return;
                      }

                      setState(() {
                        _contextMenuScreenPos = details.localPosition;
                        _contextMenuCanvasPos = canvasPos;
                        _pendingConnectNodeId = null;
                        _pendingConnectPin = null;
                      });
                    },
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // 0. Dynamic Infinite Grid Painter (renders on full viewport, culls offscreen lines)
                        Positioned.fill(
                          child: ValueListenableBuilder<Matrix4>(
                            valueListenable: _transformController,
                            builder: (context, matrix, _) {
                              return CustomPaint(
                                painter: BlueprintInfiniteGridPainter(
                                  transform: matrix,
                                  canvasOrigin: _canvasOrigin,
                                  accentColor: accent,
                                ),
                              );
                            },
                          ),
                        ),
                        // 1. Interactive Canvas Workspace
                        InteractiveViewer(
                          transformationController: _transformController,
                          constrained: false,
                          boundaryMargin: const EdgeInsets.all(double.infinity),
                          minScale: 0.15,
                          maxScale: 3.0,
                          child: SizedBox(
                            width: _canvasSize,
                            height: _canvasSize,
                            child: Stack(
                              children: [
                                // 1. Cables Painter (transparent background, only Béziers)
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: BlueprintGraphPainter(
                                      nodes: baseGraph.nodes,
                                      connections: allConnections,
                                      selectedNodeId: _selectedNodeId,
                                      selectedConnectionId:
                                          _selectedConnectionId,
                                      canvasOrigin: _canvasOrigin,
                                      accentColor: accent,
                                      activeDraftConnection:
                                          _draggingPin != null &&
                                              _draggingFromNodeId != null
                                          ? BlueprintConnection(
                                              id: 'draft_conn',
                                              fromNodeId: _draggingFromNodeId!,
                                              fromPinId: _draggingPin!.id,
                                              toNodeId: '',
                                              toPinId: '',
                                            )
                                          : null,
                                      activeDraftTarget:
                                          _draggingWireTarget != null
                                          ? _draggingWireTarget! + _canvasOrigin
                                          : null,
                                    ),
                                  ),
                                ),

                                // 2. Interactive Blueprint Nodes
                                for (final node in baseGraph.nodes)
                                  Positioned(
                                    left: _canvasOrigin.dx + node.position.dx,
                                    top: _canvasOrigin.dy + node.position.dy,
                                    child: BlueprintNodeWidget(
                                      data: node,
                                      isSelected: node.id == _selectedNodeId,
                                      onSelect: () {
                                        setState(() {
                                          _selectedNodeId = node.id;
                                          _selectedConnectionId = null;
                                        });
                                      },
                                      onDragDelta: (delta) {
                                        setState(() {
                                          final current = node.position;
                                          final next = current + delta;
                                          _customNodePositions[node.id] = next;
                                          node.position = next;
                                        });
                                        if (widget.onNodeMoved != null) {
                                          widget.onNodeMoved!(
                                            node.id,
                                            node.position,
                                          );
                                        }
                                      },
                                      onPinStartDrag: (pin, pinCanvasPos) {
                                        setState(() {
                                          _draggingPin = pin;
                                          _draggingFromNodeId = node.id;
                                          _draggingWireTarget = pinCanvasPos;
                                        });
                                      },
                                      onPinDragUpdate: (globalPosition) {
                                        final canvasPos = _globalToCanvas(
                                          globalPosition,
                                        );
                                        setState(() {
                                          _draggingWireTarget = canvasPos;
                                        });
                                      },
                                      onPinDragEnd: () {
                                        _handlePinDragRelease();
                                      },
                                      onPinDragCancel: () {
                                        setState(() {
                                          _draggingPin = null;
                                          _draggingFromNodeId = null;
                                          _draggingWireTarget = null;
                                        });
                                      },
                                      onBreakPinLinks: (pin) {
                                        final matchingConns = allConnections
                                            .where(
                                              (c) =>
                                                  (c.fromNodeId == node.id &&
                                                      c.fromPinId == pin.id) ||
                                                  (c.toNodeId == node.id &&
                                                      c.toPinId == pin.id),
                                            )
                                            .toList();
                                        final allPositions = {
                                          for (final n in baseGraph.nodes)
                                            n.id: n.position,
                                        };
                                        for (final c in matchingConns) {
                                          _severedConnectionIds.add(c.id);
                                          final toNode = baseGraph.nodes
                                              .cast<BlueprintNodeData?>()
                                              .firstWhere(
                                                (n) => n?.id == c.toNodeId,
                                                orElse: () => null,
                                              );
                                          if (widget.onDisconnectConnection !=
                                              null) {
                                            widget.onDisconnectConnection!(
                                              c.id,
                                              fromNodeId: c.fromNodeId,
                                              fromPinId: c.fromPinId,
                                              toNodeId: c.toNodeId,
                                              toPinId: c.toPinId,
                                              toNodePosition: toNode?.position,
                                              allNodePositions: allPositions,
                                            );
                                          }
                                        }
                                        setState(() {
                                          _customConnections.removeWhere(
                                            (c) =>
                                                (c.fromNodeId == node.id &&
                                                    c.fromPinId == pin.id) ||
                                                (c.toNodeId == node.id &&
                                                    c.toPinId == pin.id),
                                          );
                                          if (matchingConns.any(
                                            (c) =>
                                                c.id == _selectedConnectionId,
                                          )) {
                                            _selectedConnectionId = null;
                                          }
                                        });
                                      },
                                      onDelete: !node.isEntryPoint
                                          ? () {
                                              widget.onRemoveAction(
                                                node.id,
                                                node.actionIndex,
                                              );
                                              if (_selectedNodeId == node.id) {
                                                setState(() {
                                                  _selectedNodeId = null;
                                                });
                                              }
                                            }
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Wire Dragging Global Listener Overlay (fallback capture) ──
                if (_draggingPin != null)
                  Positioned.fill(
                    child: Listener(
                      behavior: HitTestBehavior.translucent,
                      onPointerMove: (event) {
                        final canvasPos = _screenToCanvas(event.localPosition);
                        setState(() {
                          _draggingWireTarget = canvasPos;
                        });
                      },
                      onPointerUp: (event) {
                        final canvasPos = _screenToCanvas(event.localPosition);
                        _handlePinDragRelease(canvasPos);
                      },
                    ),
                  ),

                // ── Floating Zoom Controls & Coordinates HUD ──
                Positioned(
                  left: 20,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16181E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const AppIcon.fromMaterial(
                            Icons.zoom_in,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: context.tr.image_editor_zoom_in,
                          onPressed: () {
                            final matrix = _transformController.value.clone()
                              ..scaleByDouble(1.2, 1.2, 1.0, 1.0);
                            _transformController.value = matrix;
                          },
                        ),
                        IconButton(
                          icon: const AppIcon.fromMaterial(
                            Icons.zoom_out,
                            color: Colors.white70,
                            size: 20,
                          ),
                          tooltip: context.tr.image_editor_zoom_out,
                          onPressed: () {
                            final matrix = _transformController.value.clone()
                              ..scaleByDouble(0.8, 0.8, 1.0, 1.0);
                            _transformController.value = matrix;
                          },
                        ),
                        ValueListenableBuilder<Matrix4>(
                          valueListenable: _transformController,
                          builder: (context, matrix, _) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${(matrix.getMaxScaleOnAxis() * 100).round()} %',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                          child: VerticalDivider(
                            color: Colors.white24,
                            width: 8,
                          ),
                        ),
                        IconButton(
                          onPressed: _centerCanvas,
                          tooltip: context.tr.blueprint_origin_label,
                          icon: AppIcon.fromMaterial(
                            Icons.my_location,
                            color: accent,
                            size: 18,
                          ),
                        ),
                        if (_selectedConnectionId != null) ...[
                          const SizedBox(
                            height: 20,
                            child: VerticalDivider(
                              color: Colors.white24,
                              width: 8,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _deleteSelectedConnection,
                            icon: const AppIcon.fromMaterial(
                              Icons.link_off,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                            label: Text(
                              context.tr.blueprint_cut_link,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.redAccent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Minimap ──
                if (baseGraph.nodes.isNotEmpty)
                  Positioned(
                    right: 20,
                    bottom: 20,
                    child: ValueListenableBuilder<Matrix4>(
                      valueListenable: _transformController,
                      builder: (context, matrix, _) {
                        final viewport = _viewportSize();
                        return BlueprintMinimap(
                          nodes: baseGraph.nodes,
                          transform: matrix,
                          viewportSize: viewport,
                          canvasOrigin: _canvasOrigin,
                          accentColor: accent,
                          onNavigate: (point) => _centerOn(point, viewport),
                        );
                      },
                    ),
                  ),

                // ── Floating Action: Cut Selected Wire at Midpoint ──
                if (selectedConn != null && selectedConnMidScreen != null)
                  Positioned(
                    left: selectedConnMidScreen.dx - 45,
                    top: selectedConnMidScreen.dy - 16,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _deleteSelectedConnection,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon.fromMaterial(
                                Icons.link_off,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                context.tr.menu_cut,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Right-hand Inspector Panel ──
                if (selectedNode != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: BlueprintInspectorPanel(
                      node: selectedNode,
                      onClose: () {
                        setState(() {
                          _selectedNodeId = null;
                        });
                      },
                      onParameterChanged: (key, value) {
                        if (selectedNode.actionIndex != null) {
                          widget.onParameterChanged(
                            selectedNode.actionIndex!,
                            key,
                            value,
                          );
                        }
                      },
                      onSuggestionSelected: (key, value) {
                        if (selectedNode.actionIndex != null) {
                          widget.onSuggestionSelected(
                            selectedNode.actionIndex!,
                            key,
                            value,
                          );
                        }
                      },
                      fieldRefreshVersionOf: widget.fieldRefreshVersionOf,
                      variableSuggestions: widget.variableSuggestions,
                      emojiSuggestions: widget.emojiSuggestions,
                      botIdForConfig: widget.botIdForConfig,
                      onEditNestedActions: widget.onEditNestedActions,
                      allActions: widget.actions,
                      onDelete: !selectedNode.isEntryPoint
                          ? () {
                              widget.onRemoveAction(
                                selectedNode.id,
                                selectedNode.actionIndex,
                              );
                              setState(() {
                                _selectedNodeId = null;
                              });
                            }
                          : null,
                    ),
                  ),

                // ── Unreal Context Menu (Right Click / Cable Drop) ──
                if (_contextMenuScreenPos != null &&
                    _contextMenuCanvasPos != null)
                  BlueprintContextMenu(
                    position: _contextMenuScreenPos!,
                    isInteraction: widget.isInteraction,
                    onActionSelected: (type) {
                      final targetPos = _contextMenuCanvasPos!;
                      final fromNodeId = _pendingConnectNodeId;
                      final fromPin = _pendingConnectPin;
                      setState(() {
                        _contextMenuScreenPos = null;
                        _contextMenuCanvasPos = null;
                        _pendingConnectNodeId = null;
                        _pendingConnectPin = null;
                      });
                      widget.onAddActionAt(
                        type,
                        targetPos,
                        connectFromNodeId: fromNodeId,
                        connectFromPinId: fromPin?.id,
                        connectFromPinDirection: fromPin?.direction,
                      );
                    },
                    onDismiss: () {
                      setState(() {
                        _contextMenuScreenPos = null;
                        _contextMenuCanvasPos = null;
                        _pendingConnectNodeId = null;
                        _pendingConnectPin = null;
                      });
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
