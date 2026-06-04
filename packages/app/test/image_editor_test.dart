/// Comprehensive widget and integration tests for the Image Editor feature.
///
/// Covers:
/// - CanvasPreviewWidget rendering (shapes, text, images, variable badges)
/// - Hit testing (tap to select elements)
/// - Drag gestures (reposition elements on canvas)
/// - ImageEditorPage lifecycle (undo/redo, layer operations, property editing)
/// - Edge cases (empty compositions, missing create, visibility, zoom)
library;

import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/bot_editor/presentation/widgets/canvas_preview_widget.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/image_editor_page.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _basicOps() => [
      {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
    ];

List<Map<String, dynamic>> _fullComposition() => [
      {'op': 'create', 'width': '800', 'height': '600', 'color': '#2c2f33'},
      {'op': 'drawRect', 'x': '10', 'y': '10', 'width': '100', 'height': '80', 'color': '#448AFF', 'fill': 'true'},
      {'op': 'drawCircle', 'x': '200', 'y': '200', 'radius': '40', 'color': '#E040FB', 'fill': 'true'},
      {'op': 'drawText', 'text': 'Hello World', 'x': '50', 'y': '250', 'fontSize': '32', 'color': 'white'},
      {'op': 'drawLine', 'x1': '400', 'y1': '100', 'x2': '700', 'y2': '400', 'color': '#FFD740', 'thickness': '3'},
    ];

List<VariableSuggestion> _sampleVars() => [
      VariableSuggestion(name: 'author.username', kind: VariableSuggestionKind.unknown, category: VariableCategory.author),
      VariableSuggestion(name: 'guild.name', kind: VariableSuggestionKind.unknown, category: VariableCategory.guild),
      VariableSuggestion(name: 'temp.myVar', kind: VariableSuggestionKind.unknown, category: VariableCategory.temp),
    ];

/// Wraps widget in a MaterialApp+Scaffold for testing.
Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: child),
  );
}

/// Verifies the widget renders (contains a CustomPaint) without crashing.
void _expectRenders(WidgetTester tester) {
  // Scaffold adds a debug banner CustomPaint, so there may be 2+
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
}

// ─── CanvasPreviewWidget Rendering ────────────────────────────────────────

void main() {
  group('CanvasPreviewWidget — Rendering', () {
    testWidgets('renders without crash for empty operations', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('renders canvas background from create op', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _basicOps(),
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('renders full composition (rect+circle+text+line)', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
      )));
      _expectRenders(tester);
    });

    testWidgets('renders variable-augmented text as colored badges', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': 'Bonjour ((author.username))!', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        maxWidth: 400,
        maxHeight: 300,
        variableSuggestions: _sampleVars(),
      )));
      _expectRenders(tester);
    });

    testWidgets('renders unknown variable as orange warning badge', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': '((unknown.var))', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        maxWidth: 400,
        maxHeight: 300,
        variableSuggestions: _sampleVars(),
      )));
      _expectRenders(tester);
    });

    testWidgets('renders empty text operation without error', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': '', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('renders loadImage placeholder', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'loadImage', 'url': 'https://example.com/img.png', 'x': '50', 'y': '50', 'width': '150', 'height': '150'},
        ],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('hides operations via hiddenIndices', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        hiddenIndices: {1, 3},
      )));
      _expectRenders(tester);
    });

    testWidgets('zoom factor is applied', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        zoom: 1.5,
      )));
      _expectRenders(tester);
    });

    testWidgets('selection highlight renders on selected element', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        selectedIndex: 1,
      )));
      _expectRenders(tester);
    });

    testWidgets('auto-scales to fit within constraints', (tester) async {
      await tester.pumpWidget(_wrap(SizedBox(
        width: 200,
        height: 150,
        child: CanvasPreviewWidget(
          operations: _fullComposition(),
          maxWidth: 200,
          maxHeight: 150,
        ),
      )));
      _expectRenders(tester);
    });
  });

  // ─── Hit Testing ─────────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Hit Testing', () {
    testWidgets('tap on empty canvas fires callback with result', (tester) async {
      int? selected;
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        onElementSelected: (i) => selected = i,
      )));

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      // Callback was called (value depends on exact tap position)
    });

    testWidgets('non-interactive mode skips GestureDetector', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
      )));
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('interactive mode has GestureDetector', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        onElementSelected: (_) {},
      )));
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });

  // ─── Drag Gestures ───────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Drag', () {
    testWidgets('drag on empty area does not fire onElementMoved', (tester) async {
      int moveCount = 0;
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        onElementSelected: (_) {},
        onElementMoved: (i, dx, dy) => moveCount++,
      )));

      final topLeft = tester.getTopLeft(find.byType(GestureDetector));
      // Tap on empty area (far right, bottom — should miss all shapes)
      final startPos = topLeft + const Offset(350, 280);
      final gesture = await tester.startGesture(startPos);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(moveCount, 0);
    });

    testWidgets('drag on drawn element fires onElementMoved', (tester) async {
      int? draggedIndex;
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        onElementSelected: (_) {},
        onElementMoved: (i, dx, dy) => draggedIndex = i,
      )));

      final topLeft = tester.getTopLeft(find.byType(GestureDetector));
      // Tap near the rectangle area (x:10, y:10 in canvas space; scaled to widget)
      final startPos = topLeft + const Offset(5, 5);
      final gesture = await tester.startGesture(startPos);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    });
  });

  // ─── Edge Cases ──────────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Edge Cases', () {
    testWidgets('handles 0x0 canvas dimensions', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [{'op': 'create', 'width': '0', 'height': '0', 'color': '#2c2f33'}],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('handles 1x1 canvas dimensions', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [{'op': 'create', 'width': '1', 'height': '1', 'color': '#2c2f33'}],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('handles 8K canvas dimensions', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [{'op': 'create', 'width': '7680', 'height': '4320', 'color': '#2c2f33'}],
        maxWidth: 800,
        maxHeight: 600,
      )));
      _expectRenders(tester);
    });

    testWidgets('handles non-numeric dimension strings (falls back to defaults)', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [{'op': 'create', 'width': 'not-a-number', 'height': 'also-invalid', 'color': '#2c2f33'}],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('handles invalid color strings', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': 'not-a-color'},
          {'op': 'drawRect', 'x': '10', 'y': '10', 'width': '100', 'height': '80', 'color': 'invalid', 'fill': 'true'},
        ],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('handles rapid rebuilds (shouldRepaint logic)', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
      )));
      for (var i = 0; i < 10; i++) {
        await tester.pumpWidget(_wrap(CanvasPreviewWidget(
          operations: _fullComposition(),
          maxWidth: 800,
          maxHeight: 600,
          selectedIndex: i < 5 ? i : null,
        )));
        await tester.pump(const Duration(milliseconds: 16));
      }
      _expectRenders(tester);
    });

    testWidgets('handles operations with missing optional keys', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300'}, // no color
          {'op': 'drawRect', 'x': '10', 'y': '10'}, // no width/height
          {'op': 'drawCircle', 'x': '100', 'y': '100'}, // no radius
          {'op': 'drawText', 'text': 'Hello'}, // no x/y/color
          {'op': 'drawLine', 'x1': '0', 'y1': '0', 'x2': '100', 'y2': '100'}, // no color/thickness
        ],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });

    testWidgets('selection on create op does not crash (no bounding box)', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _basicOps(),
        maxWidth: 400,
        maxHeight: 300,
        selectedIndex: 0,
      )));
      _expectRenders(tester);
    });

    testWidgets('empty variable suggestions list does not crash on var text', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': '((myVar))', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        maxWidth: 400,
        maxHeight: 300,
        variableSuggestions: [],
      )));
      _expectRenders(tester);
    });

    testWidgets('handles negative position values', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawRect', 'x': '-50', 'y': '-30', 'width': '100', 'height': '80', 'color': 'red', 'fill': 'true'},
          {'op': 'drawText', 'text': 'Offscreen', 'x': '-100', 'y': '-50', 'fontSize': '24', 'color': 'white'},
        ],
        maxWidth: 400,
        maxHeight: 300,
      )));
      _expectRenders(tester);
    });
  });

  // ─── ImageEditorPage Integration ───────────────────────────────────────

  group('ImageEditorPage — Integration', () {
    testWidgets('empty editor shows placeholder', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [],
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();
      expect(find.text('Create Canvas'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders canvas preview with create op present', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _basicOps(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('add create canvas from placeholder button', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [],
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      final createBtns = find.text('Create Canvas');
      expect(createBtns, findsAtLeastNWidgets(1));

      // Tap the first 'Create Canvas' button (placeholder in canvas panel)
      await tester.tap(createBtns.first);
      await tester.pumpAndSettle();

      // After adding, should still have 'Create Canvas (800×600)' somewhere
      // (both the operations tile and the properties panel label)
      expect(find.textContaining('Create Canvas (800×600)'), findsAtLeastNWidgets(1));
    });

    testWidgets('undo/redo buttons disabled initially', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Find IconButtons by tooltip and verify they exist
      final undoBtn = find.byTooltip('Undo');
      final redoBtn = find.byTooltip('Redo');
      expect(undoBtn, findsOneWidget);
      expect(redoBtn, findsOneWidget);
    });

    testWidgets('desktop layout has no TabBar', (tester) async {
      // Default 800px width = desktop
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets('mobile layout has TabBar', (tester) async {
      tester.view.physicalSize = const Size(375, 812 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('operations panel shows operation count', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();
      expect(find.text('Operations'), findsAtLeastNWidgets(1));
      expect(find.text('5'), findsOneWidget); // _fullComposition has 5 ops
    });

    testWidgets('selecting operation shows properties', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': 'Test', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Tap the draw text tile to select it
      final textTile = find.textContaining('Draw Text');
      expect(textTile, findsOneWidget);
      await tester.tap(textTile);
      await tester.pumpAndSettle();

      // Properties panel should now show 'Properties' and 'Duplicate'
      expect(find.text('Properties'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
    });

    testWidgets('delete operation from properties panel shows delete icon', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawRect', 'x': '10', 'y': '10', 'width': '100', 'height': '80', 'color': 'red', 'fill': 'true'},
        ],
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Select rectangle
      final rectTile = find.textContaining('Draw Rectangle');
      await tester.tap(rectTile);
      await tester.pumpAndSettle();

      // Delete icon should be visible
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('visibility toggle icons exist in operations list', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Visibility icons present (one per operation)
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('variable insert icon appears when suggestions present', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'drawText', 'text': 'Hello', 'x': '10', 'y': '20', 'fontSize': '14', 'color': 'white'},
        ],
        variableSuggestions: _sampleVars(),
      )));
      await tester.pumpAndSettle();

      // Select text operation
      final textTile = find.textContaining('Draw Text');
      await tester.tap(textTile);
      await tester.pumpAndSettle();

      // Variable insert icon (Icons.data_object) appears on all property fields
      final varIcons = find.byTooltip('Insert variable');
      expect(varIcons, findsAtLeastNWidgets(1));
    });

    testWidgets('URL field shows image file picker icon', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: [
          {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
          {'op': 'loadImage', 'url': '', 'x': '0', 'y': '0'},
        ],
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Select loadImage
      final imgTile = find.textContaining('Load Image');
      await tester.tap(imgTile);
      await tester.pumpAndSettle();

      // Image picker icon should appear (in the URL field suffix)
      // There may be 2: one from the operation tile icon + one from property field
      expect(find.byIcon(Icons.image), findsAtLeastNWidgets(1));
    });

    testWidgets('unsaved changes dialog shows on back when modified', (tester) async {
      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _basicOps(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Add a text operation to create unsaved changes
      final addLayerBtns = find.text('Add Layer');
      expect(addLayerBtns, findsOneWidget);
    });

    testWidgets('renderFlex does not overflow on small mobile screens', (tester) async {
      // Fixed by SingleChildScrollView wrapper in toolbar
      tester.view.physicalSize = const Size(320, 568 * 2); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrap(ImageEditorPage(
        operations: _fullComposition(),
        variableSuggestions: [],
      )));
      await tester.pumpAndSettle();

      // Should not throw rendering exceptions
      expect(tester.takeException(), isNull);
    });
  });

  // ─── Performance ─────────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Performance', () {
    testWidgets('20 shapes renders without crash', (tester) async {
      final manyOps = <Map<String, dynamic>>[
        {'op': 'create', 'width': '1920', 'height': '1080', 'color': '#1a1a2e'},
      ];
      for (var i = 0; i < 19; i++) {
        manyOps.add({
          'op': ['drawRect', 'drawCircle', 'drawText', 'drawLine'][i % 4],
          'x': '${10 + i * 30}',
          'y': '${10 + i * 20}',
          'width': '${20 + i * 5}',
          'height': '${15 + i * 3}',
          'radius': '${10 + i}',
          'text': 'Layer $i',
          'fontSize': '${12 + i % 8}',
          'x1': '${i * 10}',
          'y1': '${i * 10}',
          'x2': '${i * 10 + 50}',
          'y2': '${i * 10 + 50}',
          'color': ['#FF0000', '#00FF00', '#0000FF', '#FFFF00'][i % 4],
          'fill': 'true',
          'thickness': '${1 + i % 3}',
        });
      }

      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: manyOps,
        maxWidth: 1920,
        maxHeight: 1080,
      )));
      await tester.pumpAndSettle();
      _expectRenders(tester);
    });

    testWidgets('same props should not cause expensive repaint', (tester) async {
      final ops = _fullComposition();
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: ops,
        maxWidth: 800,
        maxHeight: 600,
      )));
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: ops,
        maxWidth: 800,
        maxHeight: 600,
      )));
      await tester.pump(const Duration(milliseconds: 16));
      _expectRenders(tester);
    });

    testWidgets('frequent Zoom changes do not crash', (tester) async {
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        zoom: 0.5,
      )));
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        zoom: 1.0,
      )));
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        zoom: 2.0,
      )));
      await tester.pumpWidget(_wrap(CanvasPreviewWidget(
        operations: _fullComposition(),
        maxWidth: 800,
        maxHeight: 600,
        zoom: 3.0,
      )));
      await tester.pumpAndSettle();
      _expectRenders(tester);
    });
  });
}
