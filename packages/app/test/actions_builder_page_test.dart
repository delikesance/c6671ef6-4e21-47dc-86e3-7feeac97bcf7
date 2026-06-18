import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder.response.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActionsBuilderPage ID Collision Prevention', () {
    testWidgets('avoids duplicate action IDs when initial actions contain action_1', (tester) async {
      // Set a larger viewport
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Arrange: Define initial actions with sequential IDs (specifically "action_1")
      final initialActions = <Map<String, dynamic>>[
        {
          'id': 'action_1',
          'type': BotCreatorActionType.runBdfdScript.name,
          'enabled': true,
          'key': 'action_1',
          'depend_on': <String>[],
          'error': {'mode': 'stop'},
          'payload': {
            'scriptContent': '\$gettimestamp',
            '_actionId': 'action_1',
          },
        }
      ];

      // 2. Act: Pump the ActionsBuilderPage
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ActionsBuilderPage(
              initialActions: initialActions,
              variableSuggestions: const [],
              isInteraction: true,
              isWorkflow: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial setup (should show one action block)
      expect(find.byType(ActionBlock), findsOneWidget);

      // Find the OutlinedButton that opens the add dialog
      final addBlockBtn = find.byType(OutlinedButton);
      expect(addBlockBtn, findsOneWidget);
      await tester.tap(addBlockBtn);
      await tester.pumpAndSettle();

      // Inside the modal, find the item for "Calculate" using its unique icon
      final calculateTile = find.byIcon(Icons.calculate);
      
      // Scroll the item into view
      await tester.ensureVisible(calculateTile);
      await tester.pumpAndSettle();
      
      expect(calculateTile, findsOneWidget);
      await tester.tap(calculateTile);
      await tester.pumpAndSettle();

      // Verify that we now have two ActionBlocks
      final actionBlocks = tester.widgetList<ActionBlock>(find.byType(ActionBlock)).toList();
      expect(actionBlocks.length, equals(2));

      // Retrieve the generated IDs
      final id1 = actionBlocks[0].action.id;
      final id2 = actionBlocks[1].action.id;

      print('First Action ID: $id1');
      print('Second Action ID: $id2');

      // Assert that their IDs are NOT equal, thereby preventing parameter update collisions!
      expect(id1, equals('action_1'));
      expect(id2, isNot(equals('action_1')));
    });
  });
}
