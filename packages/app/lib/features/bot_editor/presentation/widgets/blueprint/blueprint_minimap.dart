import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'blueprint_models.dart';

/// Overview of the whole Blueprint graph with the visible area outlined.
///
/// Tapping or dragging inside it moves the view to that point.
class BlueprintMinimap extends StatelessWidget {
  const BlueprintMinimap({
    super.key,
    required this.nodes,
    required this.transform,
    required this.viewportSize,
    required this.canvasOrigin,
    required this.accentColor,
    required this.onNavigate,
  });

  /// Nodes to draw, positioned in canvas coordinates (relative to the origin).
  final List<BlueprintNodeData> nodes;

  /// Current transform of the canvas viewer.
  final Matrix4 transform;

  /// Size of the visible canvas area on screen.
  final Size viewportSize;

  /// Offset of the canvas origin inside the virtual workspace.
  final Offset canvasOrigin;

  /// Theme action accent, used for the visible-area outline.
  final Color accentColor;

  /// Called with the canvas point the view should be centered on.
  final ValueChanged<Offset> onNavigate;

  static const Size size = Size(180, 112);
  static const double _padding = 8;

  Rect _viewportRect() {
    final inv = Matrix4.tryInvert(transform);
    if (inv == null) return Rect.zero;
    final topLeft = MatrixUtils.transformPoint(inv, Offset.zero) - canvasOrigin;
    final bottomRight =
        MatrixUtils.transformPoint(
          inv,
          Offset(viewportSize.width, viewportSize.height),
        ) -
        canvasOrigin;
    return Rect.fromPoints(topLeft, bottomRight);
  }

  Rect _worldBounds(Rect viewport) {
    var bounds = viewport;
    for (final node in nodes) {
      bounds = bounds.expandToInclude(
        Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        ),
      );
    }
    return bounds.inflate(40);
  }

  @override
  Widget build(BuildContext context) {
    final viewport = _viewportRect();
    final world = _worldBounds(viewport);
    final mapping = _MinimapMapping(world, size, _padding);

    void navigate(Offset local) => onNavigate(mapping.toWorld(local));

    return GestureDetector(
      onTapDown: (details) => navigate(details.localPosition),
      onPanUpdate: (details) => navigate(details.localPosition),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: size.width,
          height: size.height,
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
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: CustomPaint(
              painter: _MinimapPainter(
                nodes: nodes,
                viewport: viewport,
                mapping: mapping,
                accentColor: accentColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Linear mapping between canvas coordinates and minimap pixels.
class _MinimapMapping {
  _MinimapMapping(this.world, Size size, double padding) {
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;
    scale = math.min(
      usableW / math.max(world.width, 1),
      usableH / math.max(world.height, 1),
    );
    offset = Offset(
      padding + (usableW - world.width * scale) / 2,
      padding + (usableH - world.height * scale) / 2,
    );
  }

  final Rect world;
  late final double scale;
  late final Offset offset;

  Offset toMap(Offset point) => (point - world.topLeft) * scale + offset;

  Offset toWorld(Offset local) => (local - offset) / scale + world.topLeft;

  Rect rectToMap(Rect rect) =>
      Rect.fromPoints(toMap(rect.topLeft), toMap(rect.bottomRight));
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.nodes,
    required this.viewport,
    required this.mapping,
    required this.accentColor,
  });

  final List<BlueprintNodeData> nodes;
  final Rect viewport;
  final _MinimapMapping mapping;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final node in nodes) {
      final rect = mapping.rectToMap(
        Rect.fromLTWH(
          node.position.dx,
          node.position.dy,
          node.size.width,
          node.size.height,
        ),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        Paint()..color = node.headerColor.withValues(alpha: 0.75),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        mapping.rectToMap(viewport),
        const Radius.circular(4),
      ),
      Paint()
        ..color = accentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MinimapPainter oldDelegate) => true;
}
