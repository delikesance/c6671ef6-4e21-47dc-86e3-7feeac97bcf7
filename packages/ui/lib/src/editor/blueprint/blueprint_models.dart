import 'package:flutter/material.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import '../catalog/action_types.dart';

/// Pin type for Blueprint node connection endpoints.
enum BlueprintPinType {
  /// Execution flow pin (white triangle/pentagon).
  flow,

  /// Conditional branch execution pin (True/False).
  branch,
}

/// Pin direction (input vs output).
enum BlueprintPinDirection { input, output }

/// Represents an execution connection point on a node.
class BlueprintPin {
  final String id;
  final String label;
  final BlueprintPinDirection direction;
  final BlueprintPinType type;
  final Color? customColor;

  const BlueprintPin({
    required this.id,
    required this.label,
    required this.direction,
    this.type = BlueprintPinType.flow,
    this.customColor,
  });
}

/// Represents a single visual node in the 2D Blueprint canvas.
class BlueprintNodeData {
  final String id;
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color headerColor;

  /// Surtitre de catégorie (affiché en majuscules au-dessus du titre).
  final String? overline;
  final bool isEntryPoint;
  final BotCreatorActionType? actionType;
  final ActionItem? actionItem;
  final int? actionIndex;
  final List<BlueprintPin> inPins;
  final List<BlueprintPin> outPins;

  /// Dynamic position in canvas coordinates (mutable for dragging).
  Offset position;

  /// Measured size of the node widget (cached for cable attachment point calculations).
  Size size;

  BlueprintNodeData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.headerColor,
    this.overline,
    this.isEntryPoint = false,
    this.actionType,
    this.actionItem,
    this.actionIndex,
    required this.inPins,
    required this.outPins,
    required this.position,
    this.size = const Size(240, 100),
  });

  /// Hauteur de l'en-tête de nœud (pastille 30 + marges), partagée avec le widget.
  static const double headerHeight = 46.0;

  /// Calculates the local offset of a pin relative to this node.
  Offset getPinOffset(String pinId) {
    // En-tête : pastille + surtitre + titre (voir [headerHeight]), marge
    // verticale de 6, chaque broche fait 24px de haut centrée à 12px.
    const headerH = headerHeight;
    const padTop = 6.0;
    const pinH = 24.0;
    const halfPin = pinH / 2; // 12px

    final inIndex = inPins.indexWhere((p) => p.id == pinId);
    if (inIndex != -1) {
      // Input pins on the left edge (x = 0)
      return Offset(0, headerH + padTop + (inIndex * pinH) + halfPin);
    }

    final outIndex = outPins.indexWhere((p) => p.id == pinId);
    if (outIndex != -1) {
      // Output pins on the right edge (x = size.width)
      return Offset(size.width, headerH + padTop + (outIndex * pinH) + halfPin);
    }

    // Default fallback to center of respective edge
    return Offset(size.width, size.height / 2);
  }

  /// Calculates the absolute canvas position of a pin.
  Offset getPinCanvasPosition(String pinId) {
    return position + getPinOffset(pinId);
  }
}

/// Connection wire between two pins in the Blueprint graph.
class BlueprintConnection {
  final String id;
  final String fromNodeId;
  final String fromPinId;
  final String toNodeId;
  final String toPinId;
  final Color color;

  const BlueprintConnection({
    required this.id,
    required this.fromNodeId,
    required this.fromPinId,
    required this.toNodeId,
    required this.toPinId,
    this.color = Colors.white,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlueprintConnection &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
