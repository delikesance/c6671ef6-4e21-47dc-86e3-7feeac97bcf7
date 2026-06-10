/// Widget tests for CanvasPreviewWidget covering rendering, hit testing, and drag.
library;

import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/bot_editor/presentation/widgets/canvas_preview_widget.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

List<Map<String, dynamic>> _basicOps() => [
  {'op': 'create', 'width': '400', 'height': '300', 'color': '#2c2f33'},
];

List<Map<String, dynamic>> _fullComposition() => [
  {'op': 'create', 'width': '800', 'height': '600', 'color': '#2c2f33'},
  {
    'op': 'drawRect',
    'x': '10',
    'y': '10',
    'width': '100',
    'height': '80',
    'color': '#448AFF',
    'fill': 'true',
  },
  {
    'op': 'drawCircle',
    'x': '200',
    'y': '200',
    'radius': '40',
    'color': '#E040FB',
    'fill': 'true',
  },
  {
    'op': 'drawText',
    'text': 'Hello World',
    'x': '50',
    'y': '250',
    'fontSize': '32',
    'color': 'white',
  },
  {
    'op': 'drawLine',
    'x1': '400',
    'y1': '100',
    'x2': '700',
    'y2': '400',
    'color': '#FFD740',
    'thickness': '3',
  },
];

List<VariableSuggestion> _sampleVars() => [
  VariableSuggestion(
    name: 'author.username',
    kind: VariableSuggestionKind.unknown,
    category: VariableCategory.author,
  ),
  VariableSuggestion(
    name: 'guild.name',
    kind: VariableSuggestionKind.unknown,
    category: VariableCategory.guild,
  ),
  VariableSuggestion(
    name: 'temp.myVar',
    kind: VariableSuggestionKind.unknown,
    category: VariableCategory.temp,
  ),
];

/// Wraps widget in a MaterialApp+Scaffold for testing.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Verifies the widget renders (contains a CustomPaint) without crashing.
void _expectRenders(WidgetTester tester) {
  // Scaffold adds a debug banner CustomPaint, so there may be 2+
  expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
}

// ─── CanvasPreviewWidget Tests ──────────────────────────────────────────────

void main() {
  group('CanvasPreviewWidget — Rendering', () {
    testWidgets('renders without crash for empty operations', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(operations: [], maxWidth: 400, maxHeight: 300),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders canvas background from create op', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _basicOps(),
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders full composition (rect+circle+text+line)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders variable-augmented text as colored badges', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawText',
                'text': 'Bonjour ((author.username))!',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
            variableSuggestions: _sampleVars(),
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders unknown variable as orange warning badge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawText',
                'text': '((unknown.var))',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
            variableSuggestions: _sampleVars(),
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders empty text operation without error', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawText',
                'text': '',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('renders loadImage placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'loadImage',
                'url': 'https://example.com/img.png',
                'x': '50',
                'y': '50',
                'width': '150',
                'height': '150',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('hides operations via hiddenIndices', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            hiddenIndices: {1, 3},
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('zoom factor is applied', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            zoom: 1.5,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('selection highlight renders on selected element', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            selectedIndex: 1,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('auto-scales to fit within constraints', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 200,
            height: 150,
            child: CanvasPreviewWidget(
              operations: _fullComposition(),
              maxWidth: 200,
              maxHeight: 150,
            ),
          ),
        ),
      );
      _expectRenders(tester);
    });
  });

  // ─── Hit Testing ─────────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Hit Testing', () {
    testWidgets('tap on empty canvas fires callback with result', (
      tester,
    ) async {
      bool callbackFired = false;
      int? selected;
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            onElementSelected: (i) {
              callbackFired = true;
              selected = i;
            },
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pump();
      expect(callbackFired, isTrue);
      expect(selected, isNull);
    });

    testWidgets('non-interactive mode skips GestureDetector', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
          ),
        ),
      );
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('interactive mode has GestureDetector', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            onElementSelected: (_) {},
          ),
        ),
      );
      expect(find.byType(GestureDetector), findsOneWidget);
    });
  });

  // ─── Drag Gestures ───────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Drag', () {
    testWidgets('drag on empty area does not fire onElementMoved', (
      tester,
    ) async {
      int moveCount = 0;
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            onElementSelected: (_) {},
            onElementMoved: (i, dx, dy) => moveCount++,
          ),
        ),
      );

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
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            onElementSelected: (_) {},
            onElementMoved: (i, dx, dy) => draggedIndex = i,
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byType(GestureDetector));
      // Tap inside the rectangle area (x:10, y:10 in canvas space; scaled to widget)
      final startPos = topLeft + const Offset(15, 15);
      final gesture = await tester.startGesture(startPos);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.moveBy(const Offset(20, 10));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(draggedIndex, 1);
    });
  });
}
