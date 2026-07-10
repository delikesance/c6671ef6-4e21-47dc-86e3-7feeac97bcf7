import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeStoredWorkflowDefinition', () {
    test('promotes legacy event field into event workflow', () {
      final normalized = normalizeStoredWorkflowDefinition(<String, dynamic>{
        'name': 'Legacy Message Create',
        'event': 'messageCreate',
        'actions': <Map<String, dynamic>>[],
      });

      expect(normalized['workflowType'], workflowTypeEvent);
      expect(normalized['eventTrigger'], <String, dynamic>{
        'category': 'messages',
        'event': 'messageCreate',
      });
    });

    test('promotes legacy listenFor field into event workflow', () {
      final normalized = normalizeStoredWorkflowDefinition(<String, dynamic>{
        'name': 'Legacy Member Add',
        'listenFor': 'guildMemberAdd',
        'actions': <Map<String, dynamic>>[],
      });

      expect(normalized['workflowType'], workflowTypeEvent);
      expect(normalized['eventTrigger'], <String, dynamic>{
        'category': 'messages',
        'event': 'guildMemberAdd',
      });
    });

    test('normalizes executionMode and jsScriptContent', () {
      final normalized = normalizeStoredWorkflowDefinition(<String, dynamic>{
        'name': 'JS Event',
        'workflowType': workflowTypeEvent,
        'eventTrigger': <String, dynamic>{'event': 'messageCreate'},
        'executionMode': 'javascript',
        'jsScriptContent': 'await message.reply("hi");',
        'actions': <Map<String, dynamic>>[],
      });

      expect(normalized['executionMode'], workflowExecutionModeJavascript);
      expect(normalized['jsScriptContent'], 'await message.reply("hi");');
    });

    test('auto-promotes to javascript when jsScriptContent is present', () {
      final normalized = normalizeStoredWorkflowDefinition(<String, dynamic>{
        'name': 'Implicit JS',
        'workflowType': workflowTypeEvent,
        'eventTrigger': <String, dynamic>{'event': 'messageCreate'},
        'script': 'console.log("x");',
        'actions': <Map<String, dynamic>>[],
      });

      expect(normalized['executionMode'], workflowExecutionModeJavascript);
      expect(normalized['jsScriptContent'], 'console.log("x");');
    });
  });
}
