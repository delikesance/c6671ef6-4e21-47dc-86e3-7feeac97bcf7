import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/blueprint/blueprint_graph_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktopSize = Size(1400, 900);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'WorkflowBlockEditor on desktop displays Blocs/Blueprint switcher and toggles to BlueprintGraphCanvas',
    (tester) async {
      tester.view.physicalSize = _desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: WorkflowBlockEditor(
            botId: 'test_bot',
            eventCatalog: const [],
            eventCategories: const ['Members'],
            eventsForCategory: (_) => const [],
            eventCategoryLabel: (c) => c,
            buildVariableSuggestions:
                ({
                  required workflowType,
                  required argumentDefinitions,
                  required eventTrigger,
                }) async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // On desktop width >= 1000 in test mode, the toggle should be visible
      expect(find.text('Blocs'), findsOneWidget);
      expect(find.text('Blueprint'), findsOneWidget);

      // Initially in 'linear' (Blocs) mode
      expect(find.byType(ScratchBlockCanvas), findsOneWidget);
      expect(find.byType(BlueprintGraphCanvas), findsNothing);

      // Tap on 'Blueprint' segment
      await tester.tap(find.text('Blueprint'));
      await tester.pumpAndSettle();

      // Should now display BlueprintGraphCanvas
      expect(find.byType(BlueprintGraphCanvas), findsOneWidget);
      expect(find.byType(ScratchBlockCanvas), findsNothing);

      // Switch back to 'Blocs'
      await tester.tap(find.text('Blocs'));
      await tester.pumpAndSettle();

      expect(find.byType(ScratchBlockCanvas), findsOneWidget);
      expect(find.byType(BlueprintGraphCanvas), findsNothing);
    },
  );
}
