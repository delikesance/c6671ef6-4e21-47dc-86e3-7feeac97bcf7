import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_card.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native backend survives action serialization', () {
    final item = ActionItem(
      id: 'script',
      type: BotCreatorActionType.runBdfdScript,
      actionKey: '',
      parameters: {
        'scriptContent': r'$unknown[$createChannel[room;text]]',
        'bdfdBackend': 'native-v1',
      },
    );
    final roundTrip = ActionItem.fromJson(item.toJson());
    expect(roundTrip.parameters['bdfdBackend'], 'native-v1');
    expect(
      roundTrip.parameters['scriptContent'],
      r'$unknown[$createChannel[room;text]]',
    );
  });
  test('workflow normalization preserves explicit native mode and source', () {
    final normalized = normalizeStoredWorkflowDefinition({
      'name': 'native',
      'executionMode': 'bdfd_script',
      'bdfdBackend': 'native-v1',
      'bdfdScriptContent': r'$sendMessage[x]',
    });
    expect(normalized['executionMode'], 'bdfd_script');
    expect(normalized['bdfdBackend'], 'native-v1');
    expect(normalized['bdfdScriptContent'], r'$sendMessage[x]');
    expect(
      normalizeWorkflowExecutionMode('bdfd_script', supportsJavascript: false),
      'bdfd_script',
    );
  });
  test(
    'legacy workflow script aliases are normalized without losing native selection',
    () {
      final workflow = normalizeStoredWorkflowDefinition({
        'name': 'legacy-script',
        'scriptContent': r'$unknown[$createChannel[room;text]]',
        'bdfdBackend': 'native-v1',
      });
      expect(
        workflow['bdfdScriptContent'],
        r'$unknown[$createChannel[room;text]]',
      );
      expect(workflow['executionMode'], 'bdfd_script');
      expect(workflow['bdfdBackend'], 'native-v1');
    },
  );
  test(
    'legacy workflow script aliases are normalized without losing native selection',
    () {
      final workflow = normalizeStoredWorkflowDefinition({
        'name': 'legacy-script',
        'scriptContent': r'$unknown[$createChannel[room;text]]',
        'bdfdBackend': 'native-v1',
      });
      expect(
        workflow['bdfdScriptContent'],
        r'$unknown[$createChannel[room;text]]',
      );
      expect(workflow['executionMode'], 'bdfd_script');
      expect(workflow['bdfdBackend'], 'native-v1');
    },
  );
  testWidgets(
    'block shows native diagnostics and preserves opaque unknown calls',
    (tester) async {
      final item = ActionItem(
        id: 'script',
        type: BotCreatorActionType.runBdfdScript,
        actionKey: '',
        parameters: {
          'scriptContent': r'$kickMention',
          'bdfdBackend': 'native-v1',
        },
      );
      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return ActionCard(
                    action: item,
                    index: 0,
                    totalCount: 1,
                    onRemove: () {},
                    onParameterChanged: (key, value) =>
                        setState(() => item.parameters[key] = value),
                    onSuggestionSelected: (_, _) {},
                    fieldRefreshVersionOf: (_) => 0,
                    actionKey: '',
                    variableSuggestions: const [],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(r'Invalid argument count for $kickMention'),
        findsOneWidget,
      );
      rebuild(
        () => item.parameters['scriptContent'] =
            r'$unknown[$createChannel[room;text]]',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Unsupported native function'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
