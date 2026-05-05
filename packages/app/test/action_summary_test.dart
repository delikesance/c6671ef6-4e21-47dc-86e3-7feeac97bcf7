import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_summary.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/core/models/types/action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

ActionItem _buildAction({
  required String id,
  required BotCreatorActionType type,
  Map<String, dynamic> parameters = const <String, dynamic>{},
  bool enabled = true,
}) {
  return ActionItem(
    id: id,
    type: type,
    enabled: enabled,
    parameters: Map<String, dynamic>.from(parameters),
  );
}

void main() {
  group('summarizeActionItem', () {
    testWidgets('summarizes runWorkflow entry point and arguments',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final summary = summarizeActionItem(
            context,
            _buildAction(
              id: 'action_1',
              type: BotCreatorActionType.runWorkflow,
              parameters: <String, dynamic>{
                'workflowName': 'nightly_sync',
                'entryPoint': 'bootstrap',
                'arguments': <String, dynamic>{'scope': 'guild', 'retry': '3'},
                'key': 'sync_result',
              },
            ),
          );

          expect(summary.outputKey, 'sync_result');
          expect(summary.summary, contains('Run nightly_sync'));
          expect(summary.meta, contains('2 arg(s)'));
          expect(summary.isEnabled, isTrue);

          return const SizedBox();
        }),
      ));
    });

    testWidgets('summarizes ifBlock nested branches', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final summary = summarizeActionItem(
            context,
            _buildAction(
              id: 'if_1',
              type: BotCreatorActionType.ifBlock,
              parameters: <String, dynamic>{
                'variable': '((member.id))',
                'operator': 'equals',
                'value': '42',
                'thenActions': <Map<String, dynamic>>[
                  <String, dynamic>{'type': 'sendMessage'},
                  <String, dynamic>{'type': 'addRole'},
                ],
                'elseIfConditions': <Map<String, dynamic>>[
                  <String, dynamic>{'variable': '((member.id))'},
                ],
                'elseActions': <Map<String, dynamic>>[
                  <String, dynamic>{'type': 'stopUnless'},
                ],
              },
            ),
          );

          expect(summary.outputKey, 'if_1');
          expect(summary.summary, contains('If ((member.id))'));
          expect(summary.meta, <String>['2 then', '1 else-if', '1 else']);

          return const SizedBox();
        }),
      ));
    });

    testWidgets('summarizes button listener and disabled state',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final summary = summarizeActionItem(
            context,
            _buildAction(
              id: 'listener_1',
              type: BotCreatorActionType.listenForButtonClick,
              enabled: false,
              parameters: <String, dynamic>{
                'customId': 'ticket.close',
                'workflowName': 'close_ticket',
              },
            ),
          );

          expect(summary.summary, contains('Button ticket.close'));
          expect(summary.outputKey, 'listener_1');
          expect(summary.isEnabled, isFalse);

          return const SizedBox();
        }),
      ));
    });

    testWidgets('falls back to action id when key is blank', (tester) async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (context) {
          final summary = summarizeActionItem(
            context,
            _buildAction(
              id: 'send_1',
              type: BotCreatorActionType.sendMessage,
              parameters: <String, dynamic>{
                'content': 'Hello there',
                'channelId': '',
                'key': '   ',
              },
            ),
          );

          expect(summary.outputKey, 'send_1');
          expect(summary.summary, contains('Send'));
          expect(summary.summary, contains('Hello there'));

          return const SizedBox();
        }),
      ));
    });
  });
}
