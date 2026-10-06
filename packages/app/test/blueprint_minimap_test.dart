import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_minimap.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  BlueprintNodeData node(String id, Offset position) => BlueprintNodeData(
    id: id,
    title: id,
    icon: Icons.bolt,
    headerColor: Colors.orange,
    inPins: const [],
    outPins: const [],
    position: position,
  );

  testWidgets('tapping the minimap navigates inside the graph bounds', (
    tester,
  ) async {
    Offset? navigatedTo;
    final nodes = [node('a', Offset.zero), node('b', const Offset(1200, 400))];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BlueprintMinimap(
              nodes: nodes,
              transform: Matrix4.identity(),
              viewportSize: const Size(400, 300),
              canvasOrigin: Offset.zero,
              accentColor: Colors.purple,
              onNavigate: (point) => navigatedTo = point,
            ),
          ),
        ),
      ),
    );

    final minimap = find.byType(BlueprintMinimap);
    expect(minimap, findsOneWidget);
    expect(tester.getSize(minimap), BlueprintMinimap.size);

    // Right edge of the minimap maps to the far right of the graph.
    final rect = tester.getRect(minimap);
    await tester.tapAt(Offset(rect.right - 10, rect.center.dy));
    expect(navigatedTo, isNotNull);
    expect(navigatedTo!.dx, greaterThan(1000));

    // Left edge maps to the start of the graph.
    await tester.tapAt(Offset(rect.left + 10, rect.center.dy));
    expect(navigatedTo!.dx, lessThan(100));
  });
}
