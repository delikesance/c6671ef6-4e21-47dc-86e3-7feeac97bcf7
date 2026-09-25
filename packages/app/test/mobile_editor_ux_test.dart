import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:bot_creator/core/models/types/variable_suggestion.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_canvas.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_connector.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block_palette.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/mobile_keyboard_accessory_bar.dart';

void main() {
  testWidgets('ScratchBlockConnector renders insert button when onInsert is provided', (tester) async {
    var insertTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ScratchBlockConnector(
              onInsert: () => insertTapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(insertTapped, isTrue);
  });

  testWidgets('ScratchBlockCanvas renders ReorderableListView when onReorder is provided', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScratchBlockCanvas(
            onReorder: (oldIdx, newIdx) {},
            children: const [
              Text('Block 1', key: ValueKey('b1')),
              Text('Block 2', key: ValueKey('b2')),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(ReorderableListView), findsOneWidget);
  });

  testWidgets('ScratchBlockPalette renders quick action chips and triggers selection', (tester) async {
    BotCreatorActionType? selected;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScratchBlockPalette(
            onActionSelected: (type) => selected = type,
            popOnSelect: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ActionChip), findsWidgets);
    // Tap on the first chip
    await tester.tap(find.byType(ActionChip).first);
    await tester.pump();

    expect(selected, isNotNull);
  });

  testWidgets('MobileKeyboardAccessoryBar renders quick syntax chips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        // La barre affiche des libelles TRADUITS (Insert Variable, Vars) : un
        // banc d'essai qui monte ce widget DOIT fournir les localisations, sinon
        // `AppLocalizations.of` ne rend rien et le widget ne se construit pas.
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: MobileKeyboardAccessoryBar(
            variableSuggestions: [
              VariableSuggestion(
                name: '((author.name))',
                kind: VariableSuggestionKind.nonNumeric,
                description: 'Author username',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text(r'$'), findsOneWidget);
    expect(find.text('['), findsOneWidget);
    expect(find.text(']'), findsOneWidget);
    expect(find.text('Vars'), findsOneWidget);
  });
}
