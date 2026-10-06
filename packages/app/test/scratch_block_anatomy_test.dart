import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/action_block_summary.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/scratch_blocks/scratch_block.dart';
import 'package:bot_creator_shared/types/action.dart' show BotCreatorActionType;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, ScratchBlock block) =>
    tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(body: block),
      ),
    );

ScratchBlock _block({
  bool selected = false,
  bool hasError = false,
  bool disabled = false,
}) => ScratchBlock(
  color: const Color(0xFF38BDF8),
  title: 'Get Score · Joueur A',
  icon: Icons.http,
  overline: 'http & variables',
  summary: 'score.a ← GET /scores/a',
  selected: selected,
  hasError: hasError,
  disabled: disabled,
  child: const SizedBox(),
);

void main() {
  testWidgets('bloc : surtitre en majuscules, titre complet et résumé', (
    tester,
  ) async {
    await _pump(tester, _block());
    expect(find.text('HTTP & VARIABLES'), findsOneWidget);
    expect(find.text('Get Score · Joueur A'), findsOneWidget);
    expect(find.text('score.a ← GET /scores/a'), findsOneWidget);
  });

  testWidgets('bloc : états erreur et désactivé', (tester) async {
    await _pump(tester, _block(hasError: true));
    final box = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(ScratchBlock),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(
      ((box.decoration! as BoxDecoration).border! as Border).top.color,
      AppTheme.statusError,
    );
    await _pump(tester, _block(disabled: true));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0.5);
  });

  test('résumé : variable ← méthode URL', () {
    final action = ActionItem(
      id: 'a',
      type: BotCreatorActionType.httpRequest,
      parameters: {'url': '/scores/a', 'method': 'get'},
      actionKey: 'score.a',
    );
    expect(summarizeActionBlock(action), 'score.a ← GET /scores/a');
  });
}
