import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_summary.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/builder/action_types.dart';
import 'package:bot_creator/core/models/types/action.dart';
import 'package:flutter_test/flutter_test.dart';

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
    test('summarizes runWorkflow entry point and arguments', () {
      final summary = summarizeActionItem(
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
      expect(summary.summary, 'Run nightly_sync -> bootstrap');
      expect(summary.meta, contains('2 arg(s)'));
      expect(summary.isEnabled, isTrue);
    });

    test('summarizes ifBlock nested branches', () {
      final summary = summarizeActionItem(
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
      expect(summary.summary, 'If ((member.id)) equals 42');
      expect(summary.meta, <String>['2 then', '1 else-if', '1 else']);
    });

    test('summarizes button listener and disabled state', () {
      final summary = summarizeActionItem(
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

      expect(summary.summary, 'Button ticket.close -> close_ticket');
      expect(summary.outputKey, 'listener_1');
      expect(summary.isEnabled, isFalse);
    });

    test('falls back to action id when key is blank', () {
      final summary = summarizeActionItem(
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
      expect(summary.summary, 'Send to same channel: Hello there');
    });
  });
}
