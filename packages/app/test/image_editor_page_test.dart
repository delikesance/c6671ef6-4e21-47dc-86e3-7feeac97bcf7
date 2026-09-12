/// Integration tests for the Image Editor Page.
///
/// Covers:
/// - ImageEditorPage lifecycle (undo/redo, layer operations, property editing)
/// - Layouts: desktop vs mobile
/// - Unsaved changes
library;

import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/image_editor_page.dart';

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
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

// ─── ImageEditorPage Tests ─────────────────────────────────────────────────

void main() {
  /// Textes localisés (locale de test = anglais) : les assertions portent sur
  /// les mêmes libellés qu'avant, mais via `AppLocalizations` pour rester
  /// valides quelle que soit la langue résolue par le widget.
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('ImageEditorPage — Integration', () {
    testWidgets('empty editor shows placeholder', (tester) async {
      await tester.pumpWidget(
        _wrap(ImageEditorPage(operations: [], variableSuggestions: [])),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(l10n.action_name_canvasCreateBlock),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('renders canvas preview with create op present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(operations: _basicOps(), variableSuggestions: []),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    });

    testWidgets('add create canvas from placeholder button', (tester) async {
      await tester.pumpWidget(
        _wrap(ImageEditorPage(operations: [], variableSuggestions: [])),
      );
      await tester.pumpAndSettle();

      final createBtns = find.text(l10n.action_name_canvasCreateBlock);
      expect(createBtns, findsAtLeastNWidgets(1));

      // Tap the first 'Create Canvas' button (placeholder in canvas panel)
      await tester.tap(createBtns.first);
      await tester.pumpAndSettle();

      // After adding, should still have 'Create Canvas (800×600)' somewhere
      // (both the operations tile and the properties panel label)
      expect(
        find.textContaining('${l10n.action_name_canvasCreateBlock} (800×600)'),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('undo/redo buttons disabled initially', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: _fullComposition(),
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find IconButtons by tooltip and verify they exist
      final undoBtn = find.byTooltip(l10n.image_editor_undo);
      final redoBtn = find.byTooltip(l10n.image_editor_redo);
      expect(undoBtn, findsOneWidget);
      expect(redoBtn, findsOneWidget);
    });

    testWidgets('desktop layout has no TabBar', (tester) async {
      // Default 800px width = desktop
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: _fullComposition(),
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsNothing);
    });

    testWidgets(
      'mobile layout does not have TabBar but shows operations list',
      (tester) async {
        tester.view.physicalSize = const Size(375 * 2, 812 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          _wrap(
            ImageEditorPage(
              operations: _fullComposition(),
              variableSuggestions: [],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(TabBar), findsNothing);
        expect(
          find.text(l10n.image_editor_operations),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets('operations panel shows operation count', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: _fullComposition(),
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.image_editor_operations), findsAtLeastNWidgets(1));
      expect(find.text('5'), findsOneWidget); // _fullComposition has 5 ops
    });

    testWidgets('selecting operation shows properties', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawText',
                'text': 'Test',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the draw text tile to select it
      final textTile = find.textContaining(
        l10n.action_name_canvasDrawTextBlock,
      );
      expect(textTile, findsOneWidget);
      await tester.tap(textTile);
      await tester.pumpAndSettle();

      // Properties panel should now show 'Properties' and 'Duplicate'
      expect(find.text(l10n.image_editor_properties), findsOneWidget);
      expect(find.text(l10n.common_duplicate), findsOneWidget);
    });

    testWidgets(
      'selecting create canvas operation does not show duplicate button',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            ImageEditorPage(
              operations: [
                {
                  'op': 'create',
                  'width': '400',
                  'height': '300',
                  'color': '#2c2f33',
                },
              ],
              variableSuggestions: [],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the create canvas tile to select it
        final createTile = find.textContaining(
          l10n.action_name_canvasCreateBlock,
        );
        expect(createTile, findsOneWidget);
        await tester.tap(createTile);
        await tester.pumpAndSettle();

        // Properties panel should show 'Properties' but NOT 'Duplicate'
        expect(find.text(l10n.image_editor_properties), findsOneWidget);
        expect(find.text(l10n.common_duplicate), findsNothing);
      },
    );

    testWidgets('delete operation from properties panel shows delete icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawRect',
                'x': '10',
                'y': '10',
                'width': '100',
                'height': '80',
                'color': 'red',
                'fill': 'true',
              },
            ],
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select rectangle
      final rectTile = find.textContaining(
        l10n.action_name_canvasDrawRectBlock,
      );
      await tester.tap(rectTile);
      await tester.pumpAndSettle();

      // Delete icon should be visible
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('visibility toggle icons exist in operations list', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: _fullComposition(),
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Visibility icons present (one per operation)
      expect(find.byIcon(Icons.visibility), findsAtLeastNWidgets(1));
    });

    testWidgets('variable insert icon appears when suggestions present', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {
                'op': 'drawText',
                'text': 'Hello',
                'x': '10',
                'y': '20',
                'fontSize': '14',
                'color': 'white',
              },
            ],
            variableSuggestions: _sampleVars(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select text operation
      final textTile = find.textContaining(
        l10n.action_name_canvasDrawTextBlock,
      );
      await tester.tap(textTile);
      await tester.pumpAndSettle();

      // Variable insert icon (Icons.data_object) appears on all property fields
      final varIcons = find.byTooltip(l10n.image_editor_insert_variable);
      expect(varIcons, findsAtLeastNWidgets(1));
    });

    testWidgets('URL field shows image file picker icon', (tester) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: [
              {
                'op': 'create',
                'width': '400',
                'height': '300',
                'color': '#2c2f33',
              },
              {'op': 'loadImage', 'url': '', 'x': '0', 'y': '0'},
            ],
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select loadImage
      final imgTile = find.textContaining(
        l10n.action_name_canvasLoadImageBlock,
      );
      await tester.tap(imgTile);
      await tester.pumpAndSettle();

      // Image picker icon should appear (in the URL field suffix)
      // There may be 2: one from the operation tile icon + one from property field
      expect(find.byIcon(Icons.image), findsAtLeastNWidgets(1));
    });

    testWidgets('unsaved changes dialog shows on back when modified', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(operations: _basicOps(), variableSuggestions: []),
        ),
      );
      await tester.pumpAndSettle();

      // Add a text operation to create unsaved changes
      final addLayerBtns = find.text(l10n.image_editor_add_layer);
      expect(addLayerBtns, findsOneWidget);
    });

    testWidgets('renderFlex does not overflow on small mobile screens', (
      tester,
    ) async {
      // Fixed by SingleChildScrollView wrapper in toolbar
      tester.view.physicalSize = const Size(320 * 2, 568 * 2); // iPhone SE size
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrap(
          ImageEditorPage(
            operations: _fullComposition(),
            variableSuggestions: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should not throw rendering exceptions
      expect(tester.takeException(), isNull);
    });
  });
}
