import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/workflow_block_editor.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/entry_point_block.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'WorkflowBlockEditor on desktop displays entry point hat block and canvas without layout exception',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: WorkflowBlockEditor(
              botId: 'test_bot',
              eventCatalog: const [],
              eventCategories: const ['core'],
              eventsForCategory: (_) => const [],
              eventCategoryLabel: (_) => 'Core',
              buildVariableSuggestions:
                  ({
                    required String workflowType,
                    required List argumentDefinitions,
                    required Map<String, dynamic> eventTrigger,
                  }) async => const [],
              initial: {
                'name': 'Test Workflow',
                'type': 'general',
                'actions': [
                  {
                    'id': 'action_1',
                    'type': 'sendMessage',
                    'payload': {'content': 'Hello world'},
                  },
                ],
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(ScratchBlockCanvas), findsOneWidget);
      expect(find.byType(WorkflowEntryPointBlock), findsOneWidget);
      expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_box_outlined), findsOneWidget);
    },
  );
  testWidgets(
    'native workflow editor opens the saved source with native validation',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkflowBlockEditor(
              botId: 'test_bot',
              eventCatalog: const [],
              eventCategories: const ['core'],
              eventsForCategory: (_) => const [],
              eventCategoryLabel: (_) => 'Core',
              buildVariableSuggestions:
                  ({
                    required String workflowType,
                    required List argumentDefinitions,
                    required Map<String, dynamic> eventTrigger,
                  }) async => const [],
              initial: {
                'name': 'native',
                'executionMode': 'bdfd_script',
                'bdfdBackend': 'native-v1',
                'bdfdScriptContent': r'$kickMention',
                'actions': [],
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(r'Invalid argument count for $kickMention'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
