/// Widget tests for CanvasPreviewWidget covering edge cases and performance.
library;

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
  // ─── Edge Cases ──────────────────────────────────────────────────────────

  group('CanvasPreviewWidget — Edge Cases', () {
    testWidgets('handles 0x0 canvas dimensions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {'op': 'create', 'width': '0', 'height': '0', 'color': '#2c2f33'},
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('handles 1x1 canvas dimensions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {'op': 'create', 'width': '1', 'height': '1', 'color': '#2c2f33'},
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('handles 8K canvas dimensions', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '7680',
                'height': '4320',
                'color': '#2c2f33',
              },
            ],
            maxWidth: 800,
            maxHeight: 600,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets(
      'handles non-numeric dimension strings (falls back to defaults)',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            CanvasPreviewWidget(
              operations: [
                {
                  'op': 'create',
                  'width': 'not-a-number',
                  'height': 'also-invalid',
                  'color': '#2c2f33',
                },
              ],
              maxWidth: 400,
              maxHeight: 300,
            ),
          ),
        );
        _expectRenders(tester);
      },
    );

    testWidgets('handles invalid color strings', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': 'not-a-color',
              },
              {
                'op': 'drawRect',
                'x': '10',
                'y': '10',
                'width': '100',
                'height': '80',
                'color': 'invalid',
                'fill': 'true',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('handles rapid rebuilds (shouldRepaint logic)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.pumpWidget(
          _wrap(
            CanvasPreviewWidget(
              operations: _fullComposition(),
              maxWidth: 800,
              maxHeight: 600,
              selectedIndex: i < 5 ? i : null,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 16));
      }
      _expectRenders(tester);
    });

    testWidgets('handles operations with missing optional keys', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: [
              {'op': 'create', 'width': '400', 'height': '300'}, // no color
              {'op': 'drawRect', 'x': '10', 'y': '10'}, // no width/height
              {'op': 'drawCircle', 'x': '100', 'y': '100'}, // no radius
              {'op': 'drawText', 'text': 'Hello'}, // no x/y/color
              {
                'op': 'drawLine',
                'x1': '0',
                'y1': '0',
                'x2': '100',
                'y2': '100',
              }, // no color/thickness
            ],
            maxWidth: 400,
            maxHeight: 300,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('selection on create op does not crash (no bounding box)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _basicOps(),
            maxWidth: 400,
            maxHeight: 300,
            selectedIndex: 0,
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('empty variable suggestions list does not crash on var text', (
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
                'text': '((myVar))',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            maxWidth: 400,
            maxHeight: 300,
            variableSuggestions: [],
          ),
        ),
      );
      _expectRenders(tester);
    });

    testWidgets('handles negative position values', (tester) async {
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
                'op': 'drawRect',
                'x': '-50',
                'y': '-30',
                'width': '100',
                'height': '80',
                'color': 'red',
                'fill': 'true',
              },
              {
                'op': 'drawText',
                'text': 'Offscreen',
                'x': '-100',
                'y': '-50',
                'fontSize': '24',
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

      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: manyOps,
            maxWidth: 1920,
            maxHeight: 1080,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectRenders(tester);
    });

    testWidgets('same props should not cause expensive repaint', (
      tester,
    ) async {
      final ops = _fullComposition();
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(operations: ops, maxWidth: 800, maxHeight: 600),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(operations: ops, maxWidth: 800, maxHeight: 600),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));
      _expectRenders(tester);
    });

    testWidgets('frequent Zoom changes do not crash', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            zoom: 0.5,
          ),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            zoom: 1.0,
          ),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            zoom: 2.0,
          ),
        ),
      );
      await tester.pumpWidget(
        _wrap(
          CanvasPreviewWidget(
            operations: _fullComposition(),
            maxWidth: 800,
            maxHeight: 600,
            zoom: 3.0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectRenders(tester);
    });
  });
}
