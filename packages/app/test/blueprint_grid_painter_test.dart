import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_graph_painter.dart';

void main() {
  test(
    'BlueprintInfiniteGridPainter paints dynamically and handles LOD scaling',
    () {
      final painter = BlueprintInfiniteGridPainter(
        transform: Matrix4.identity(),
        canvasOrigin: const Offset(50000, 50000),
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1920, 1080);

      // Should paint viewport cleanly at 1.0 scale
      expect(() => painter.paint(canvas, size), returnsNormally);

      // Repaint check
      final newPainterSame = BlueprintInfiniteGridPainter(
        transform: Matrix4.identity(),
        canvasOrigin: const Offset(50000, 50000),
      );
      expect(painter.shouldRepaint(newPainterSame), isFalse);

      final newPainterMoved = BlueprintInfiniteGridPainter(
        transform: Matrix4.identity()
          ..translateByDouble(-10000.0, -10000.0, 0.0, 1.0),
        canvasOrigin: const Offset(50000, 50000),
      );
      expect(painter.shouldRepaint(newPainterMoved), isTrue);

      // Test extreme zoom out (LOD culling of 25px grid)
      final zoomedOutPainter = BlueprintInfiniteGridPainter(
        transform: Matrix4.identity()..scaleByDouble(0.2, 0.2, 1.0, 1.0),
        canvasOrigin: const Offset(50000, 50000),
      );
      expect(() => zoomedOutPainter.paint(canvas, size), returnsNormally);

      // Test extreme panning
      final farPannedPainter = BlueprintInfiniteGridPainter(
        transform: Matrix4.identity()
          ..translateByDouble(-500000.0, 800000.0, 0.0, 1.0),
        canvasOrigin: const Offset(50000, 50000),
      );
      expect(() => farPannedPainter.paint(canvas, size), returnsNormally);
    },
  );
}
