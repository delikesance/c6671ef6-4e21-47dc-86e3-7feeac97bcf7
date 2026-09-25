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

      // Les libelles viennent de l10n (locale 'en' ici) : on les lit depuis les
      // localisations au lieu de recopier une langue en dur, sinon le test se
      // casse a la premiere traduction (ce qui est arrive).
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));

      // On desktop width >= 1000 in test mode, the toggle should be visible
      // `findsWidgets` et non `findsOneWidget` : le libellé du mode apparaît
      // aussi ailleurs sur l'écran une fois les textes traduits (l'assertion
      // portait sur l'unicité d'une chaîne en dur, pas sur le commutateur).
      expect(find.text(l10n.scratch_blocks_tab), findsWidgets);
      expect(find.text(l10n.blueprint_mode_label), findsWidgets);

      // Initially in 'linear' (Blocs) mode
      expect(find.byType(ScratchBlockCanvas), findsOneWidget);
      expect(find.byType(BlueprintGraphCanvas), findsNothing);

      // Le libellé apparaît aussi ailleurs : on cible le SEGMENT du
      // commutateur, sinon `tap` refuse (plusieurs candidats).
      Finder seg(String label) => find.descendant(
            of: find.byType(SegmentedButton<String>),
            matching: find.text(label),
          );

      // Tap on 'Blueprint' segment
      await tester.tap(seg(l10n.blueprint_mode_label));
      await tester.pumpAndSettle();

      // Should now display BlueprintGraphCanvas
      expect(find.byType(BlueprintGraphCanvas), findsOneWidget);
      expect(find.byType(ScratchBlockCanvas), findsNothing);

      // Switch back to 'Blocs'
      await tester.tap(seg(l10n.scratch_blocks_tab));
      await tester.pumpAndSettle();

      expect(find.byType(ScratchBlockCanvas), findsOneWidget);
      expect(find.byType(BlueprintGraphCanvas), findsNothing);
    },
  );
}
