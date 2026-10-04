import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'blueprint_models.dart';

/// CustomPainter that renders an infinite Blueprint background grid and Bézier connection cables.
class BlueprintGraphPainter extends CustomPainter {
  final List<BlueprintNodeData> nodes;
  final List<BlueprintConnection> connections;
  final BlueprintConnection? activeDraftConnection;
  final Offset? activeDraftTarget;
  final String? hoveredPinId;
  final String? selectedNodeId;
  final String? selectedConnectionId;
  final Offset canvasOrigin;

  BlueprintGraphPainter({
    required this.nodes,
    required this.connections,
    this.activeDraftConnection,
    this.activeDraftTarget,
    this.hoveredPinId,
    this.selectedNodeId,
    this.selectedConnectionId,
    this.canvasOrigin = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Build fast lookup for nodes
    final nodeMap = <String, BlueprintNodeData>{};
    for (final node in nodes) {
      nodeMap[node.id] = node;
    }

    // 1. Draw connections (Bézier curves)
    for (final conn in connections) {
      final fromNode = nodeMap[conn.fromNodeId];
      final toNode = nodeMap[conn.toNodeId];
      if (fromNode == null || toNode == null) continue;

      final startPos =
          fromNode.getPinCanvasPosition(conn.fromPinId) + canvasOrigin;
      final endPos = toNode.getPinCanvasPosition(conn.toPinId) + canvasOrigin;

      final isConnSelected = conn.id == selectedConnectionId;
      final isNodeSelected =
          fromNode.id == selectedNodeId || toNode.id == selectedNodeId;

      _drawBezierCable(
        canvas: canvas,
        start: startPos,
        end: endPos,
        color: conn.color,
        isHighlighted: isConnSelected || isNodeSelected,
        isSelectedCable: isConnSelected,
      );
    }

    // 2. Draw active draft cable (if user is dragging a wire)
    if (activeDraftConnection != null && activeDraftTarget != null) {
      final fromNode = nodeMap[activeDraftConnection!.fromNodeId];
      if (fromNode != null) {
        final startPos =
            fromNode.getPinCanvasPosition(activeDraftConnection!.fromPinId) +
            canvasOrigin;
        _drawBezierCable(
          canvas: canvas,
          start: startPos,
          end: activeDraftTarget!,
          color: const Color(0xFFA78BFA),
          isDraft: true,
        );
      }
    }
  }

  void _drawBezierCable({
    required Canvas canvas,
    required Offset start,
    required Offset end,
    required Color color,
    bool isHighlighted = false,
    bool isSelectedCable = false,
    bool isDraft = false,
  }) {
    final dx = (end.dx - start.dx).abs();
    final tension = math.max(60.0, dx * 0.5);

    final cp1 = Offset(start.dx + tension, start.dy);
    final cp2 = Offset(end.dx - tension, end.dy);

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, end.dx, end.dy);

    // Glow / outline if highlighted or selected
    if (isHighlighted || isSelectedCable) {
      final glowPaint = Paint()
        ..color = isSelectedCable
            ? const Color(0xFFA78BFA).withValues(alpha: 0.6)
            : const Color(0xFFA78BFA).withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelectedCable ? 8.0 : 6.0
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, glowPaint);
    }

    // Main cable stroke
    final cablePaint = Paint()
      ..color = isDraft
          ? const Color(0xFFA78BFA)
          : (isSelectedCable
                ? const Color(0xFFA78BFA)
                : (isHighlighted
                      ? Colors.white
                      : color.withValues(alpha: 0.85)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelectedCable ? 3.5 : (isHighlighted ? 3.0 : 2.5)
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, cablePaint);

    // Downstream direction indicator dot/arrow at center of curve
    _drawArrowHead(canvas, cp2, end, cablePaint.color);
  }

  void _drawArrowHead(Canvas canvas, Offset cp2, Offset end, Color color) {
    final angle = math.atan2(end.dy - cp2.dy, end.dx - cp2.dx);
    const arrowSize = 6.0;

    final arrowPath = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - math.pi / 6),
        end.dy - arrowSize * math.sin(angle - math.pi / 6),
      )
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + math.pi / 6),
        end.dy - arrowSize * math.sin(angle + math.pi / 6),
      )
      ..close();

    final arrowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(arrowPath, arrowPaint);
  }

  /// Calculates whether a given point is near a Bézier curve.
  static bool isPointNearCurve({
    required Offset point,
    required Offset start,
    required Offset end,
    double hitDistance = 20.0,
  }) {
    final dx = (end.dx - start.dx).abs();
    final tension = math.max(60.0, dx * 0.5);
    final cp1 = Offset(start.dx + tension, start.dy);
    final cp2 = Offset(end.dx - tension, end.dy);

    // Sample 40 points along cubic Bézier for accurate hit testing
    for (double t = 0.0; t <= 1.0; t += 0.025) {
      final oneMinusT = 1.0 - t;
      final x =
          oneMinusT * oneMinusT * oneMinusT * start.dx +
          3 * oneMinusT * oneMinusT * t * cp1.dx +
          3 * oneMinusT * t * t * cp2.dx +
          t * t * t * end.dx;
      final y =
          oneMinusT * oneMinusT * oneMinusT * start.dy +
          3 * oneMinusT * oneMinusT * t * cp1.dy +
          3 * oneMinusT * t * t * cp2.dy +
          t * t * t * end.dy;

      final dist = (point - Offset(x, y)).distance;
      if (dist <= hitDistance) {
        return true;
      }
    }
    return false;
  }

  @override
  bool shouldRepaint(covariant BlueprintGraphPainter oldDelegate) {
    return true; // Fast redraw during drag & hover
  }
}

/// CustomPainter that renders a truly infinite Blueprint background grid dynamically for the visible viewport.
/// Off-screen grid lines are culled, and line density scales with zoom level (LOD) to save GPU/CPU draw calls.
class BlueprintInfiniteGridPainter extends CustomPainter {
  final Matrix4 transform;
  final Offset canvasOrigin;

  BlueprintInfiniteGridPainter({
    required this.transform,
    required this.canvasOrigin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    // 1. Fill visible viewport with Unreal Engine dark slate color
    final bgPaint = Paint()..color = const Color(0xFF0E0F13);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Compute visible canvas bounds using inverse transform
    final inv = Matrix4.tryInvert(transform);
    if (inv == null) return;

    final p0 = MatrixUtils.transformPoint(inv, Offset.zero);
    final p1 = MatrixUtils.transformPoint(inv, Offset(size.width, size.height));

    final minChildX = math.min(p0.dx, p1.dx);
    final maxChildX = math.max(p0.dx, p1.dx);
    final minChildY = math.min(p0.dy, p1.dy);
    final maxChildY = math.max(p0.dy, p1.dy);

    final minCanvasX = minChildX - canvasOrigin.dx;
    final maxCanvasX = maxChildX - canvasOrigin.dx;
    final minCanvasY = minChildY - canvasOrigin.dy;
    final maxCanvasY = maxChildY - canvasOrigin.dy;

    final scale = transform.getMaxScaleOnAxis();

    const smallStep = 25.0;
    const majorStep = 100.0;

    // LOD: When zoomed out, smoothly fade out small grid to avoid aliasing and save draw calls
    final subAlpha = ((scale - 0.35) / 0.25).clamp(0.0, 1.0);

    final smallGridPaint = Paint()
      ..color = const Color(0xFF161820).withValues(alpha: subAlpha)
      ..strokeWidth = 1.0;

    final majorGridPaint = Paint()
      ..color = const Color(0xFF1D2029)
      ..strokeWidth = 1.2;

    final originAxisPaint = Paint()
      ..color = const Color(0xFF2C303C)
      ..strokeWidth = 1.5;

    // Draw vertical lines
    if (subAlpha > 0.0) {
      final firstSmallX = (minCanvasX / smallStep).floor() * smallStep;
      final lastSmallX = (maxCanvasX / smallStep).ceil() * smallStep;
      for (double cx = firstSmallX; cx <= lastSmallX; cx += smallStep) {
        final isOrigin = cx.abs() < 0.5;
        final isMajor =
            (cx % majorStep).abs() < 0.5 || (cx.abs() % majorStep < 0.5);
        if (isOrigin || isMajor) continue;

        final childPos = Offset(cx + canvasOrigin.dx, 0);
        final screenX = MatrixUtils.transformPoint(transform, childPos).dx;
        canvas.drawLine(
          Offset(screenX, 0),
          Offset(screenX, size.height),
          smallGridPaint,
        );
      }
    }

    // Major vertical lines
    final firstMajorX = (minCanvasX / majorStep).floor() * majorStep;
    final lastMajorX = (maxCanvasX / majorStep).ceil() * majorStep;
    for (double cx = firstMajorX; cx <= lastMajorX; cx += majorStep) {
      final isOrigin = cx.abs() < 0.5;
      final childPos = Offset(cx + canvasOrigin.dx, 0);
      final screenX = MatrixUtils.transformPoint(transform, childPos).dx;
      final paint = isOrigin ? originAxisPaint : majorGridPaint;
      canvas.drawLine(Offset(screenX, 0), Offset(screenX, size.height), paint);
    }

    // Draw horizontal lines
    if (subAlpha > 0.0) {
      final firstSmallY = (minCanvasY / smallStep).floor() * smallStep;
      final lastSmallY = (maxCanvasY / smallStep).ceil() * smallStep;
      for (double cy = firstSmallY; cy <= lastSmallY; cy += smallStep) {
        final isOrigin = cy.abs() < 0.5;
        final isMajor =
            (cy % majorStep).abs() < 0.5 || (cy.abs() % majorStep < 0.5);
        if (isOrigin || isMajor) continue;

        final childPos = Offset(0, cy + canvasOrigin.dy);
        final screenY = MatrixUtils.transformPoint(transform, childPos).dy;
        canvas.drawLine(
          Offset(0, screenY),
          Offset(size.width, screenY),
          smallGridPaint,
        );
      }
    }

    // Major horizontal lines
    final firstMajorY = (minCanvasY / majorStep).floor() * majorStep;
    final lastMajorY = (maxCanvasY / majorStep).ceil() * majorStep;
    for (double cy = firstMajorY; cy <= lastMajorY; cy += majorStep) {
      final isOrigin = cy.abs() < 0.5;
      final childPos = Offset(0, cy + canvasOrigin.dy);
      final screenY = MatrixUtils.transformPoint(transform, childPos).dy;
      final paint = isOrigin ? originAxisPaint : majorGridPaint;
      canvas.drawLine(Offset(0, screenY), Offset(size.width, screenY), paint);
    }

    // Draw coordinate marker at origin (0, 0)
    final originScreenPos = MatrixUtils.transformPoint(
      transform,
      Offset(canvasOrigin.dx, canvasOrigin.dy),
    );
    if (originScreenPos.dx >= -20 &&
        originScreenPos.dx <= size.width + 20 &&
        originScreenPos.dy >= -20 &&
        originScreenPos.dy <= size.height + 20) {
      final originCenterPaint = Paint()
        ..color = const Color(0xFFA78BFA).withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(originScreenPos, 4.5, originCenterPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BlueprintInfiniteGridPainter oldDelegate) {
    return oldDelegate.transform != transform ||
        oldDelegate.canvasOrigin != canvasOrigin;
  }
}
