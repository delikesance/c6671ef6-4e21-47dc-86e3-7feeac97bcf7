import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_configuration.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/command_option_serialization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final command = {
    'id': '123',
    'discordId': '123',
    'name': 'hello',
    'type': 'chatInput',
    'data': {
      'executionMode': 'bdfd_script',
      'bdfdScriptContent': 'Hello',
      'actions': [],
      'defaultMemberPermissions': '8',
      'options': [
        {
          'type': 'string',
          'name': 'text',
          'description': 'Text',
          'required': false,
        },
      ],
    },
  };
  Map<String, dynamic> edit(String op, String name, [Map? option]) => {
    'operation': op,
    'option_name': name,
    'expected_revision': HashUtil.calculateHash(command),
    'option': ?option,
  };
  test(
    'argument edits preserve identity, source and permissions and order required first',
    () {
      final updated = updateCopilotOptions(
        command,
        edit('add', 'member', {
          'type': 'user',
          'name': 'member',
          'description': 'Member',
          'required': true,
        }),
      );
      expect(updated['discordId'], '123');
      final data = updated['data'] as Map;
      expect(data['bdfdScriptContent'], 'Hello');
      expect(data['executionMode'], 'bdfd_script');
      expect(data['actions'], isEmpty);
      expect(data['defaultMemberPermissions'], '8');
      expect((data['options'] as List).first['name'], 'member');
      expect(((command['data'] as Map)['options'] as List).length, 1);
      final changed = updateCopilotOptions(
        command,
        edit('update', 'text', {'description': 'New'}),
      );
      expect(
        ((changed['data'] as Map)['options'] as List).single['description'],
        'New',
      );
      final removed = updateCopilotOptions(command, edit('remove', 'text'));
      expect((removed['data'] as Map)['options'], isEmpty);
    },
  );
  test('stale edits and invalid choices are rejected before mutation', () {
    expect(
      () => updateCopilotOptions(command, {
        ...edit('remove', 'text'),
        'expected_revision': 'stale',
      }),
      throwsStateError,
    );
    expect(
      () => validateCopilotOptions([
        {
          'type': 'integer',
          'name': 'amount',
          'description': 'Amount',
          'choices': [
            {'name': 'bad', 'value': 'x'},
          ],
        },
      ]),
      throwsFormatException,
    );
  });
  test(
    'option serialization retains string lengths and channel restrictions',
    () {
      final options = [
        {
          'type': 'string',
          'name': 'text',
          'description': 'Text',
          'minLength': 2,
          'maxLength': 40,
        },
        {
          'type': 'channel',
          'name': 'channel',
          'description': 'Channel',
          'channelTypes': [0, 2],
        },
      ];
      final roundtrip = serializeCommandOptions(
        deserializeCommandOptions(options),
      );
      expect(roundtrip.first['minLength'], 2);
      expect(roundtrip.first['maxLength'], 40);
      expect(roundtrip.last['channelTypes'], [0, 2]);
    },
  );
  test(
    'removing an argument referenced by retained BDFD source is refused',
    () {
      final referenced = copyCopilotMap(command);
      (referenced['data'] as Map)['bdfdScriptContent'] = r'$message[text]';
      expect(
        () => updateCopilotOptions(referenced, {
          ...edit('remove', 'text'),
          'expected_revision': HashUtil.calculateHash(referenced),
        }),
        throwsStateError,
      );
    },
  );
  test('workflow modes respect runtime and preserve existing source', () {
    expect(
      () => buildCopilotWorkflow({
        'name': 'test',
        'execution_mode': 'javascript',
        'script': 'return 1;',
      }, javascriptRuntime: false),
      throwsStateError,
    );
    final workflow = buildCopilotWorkflow(
      {'name': 'test'},
      existing: {'executionMode': 'javascript', 'jsScriptContent': 'return 1;'},
      javascriptRuntime: true,
    );
    expect(workflow['jsScriptContent'], 'return 1;');
    expect(workflow['actions'], isEmpty);
  });

  test(
    'existing serialized subcommands can be edited without losing route execution',
    () {
      final nested = copyCopilotMap(command);
      (nested['data'] as Map)['options'] = [
        {
          'type': 'subCommand',
          'name': 'welcome',
          'description': 'Welcome',
          'required': null,
          'options': [
            {
              'type': 'string',
              'name': 'text',
              'description': 'Text',
              'required': false,
            },
          ],
        },
      ];
      (nested['data'] as Map)['subcommandWorkflows'] = {
        'welcome': {
          'executionMode': 'bdfd_script',
          'bdfdScriptContent': 'Route source',
          'actions': [],
        },
      };
      final updated = updateCopilotOptions(nested, {
        'expected_revision': HashUtil.calculateHash(nested),
        'operation': 'add',
        'path': ['welcome'],
        'option_name': 'member',
        'option': {'type': 'user', 'name': 'member', 'description': 'Member'},
      });
      expect(updated['data']['options'].single['options'], hasLength(2));
      expect(
        updated['data']['subcommandWorkflows']['welcome']['bdfdScriptContent'],
        'Route source',
      );
      expect(updated['data']['options'].single.containsKey('required'), false);
    },
  );
  test(
    'nested catalogue schemas reject unknown keys and invalid enum values',
    () {
      final tools =
          jsonDecode(File('assets/copilot/tools.json').readAsStringSync())
              as List;
      final schema =
          tools.singleWhere(
                (t) => t['name'] == 'local_update_command_options',
              )['inputSchema']
              as Map<String, dynamic>;
      final args = {
        'bot_id': '123',
        'command_id': '123',
        ...edit('add', 'member', {
          'type': 'user',
          'name': 'member',
          'description': 'Member',
        }),
      };
      CopilotMcp.validateArguments(schema, args);
      expect(
        () => CopilotMcp.validateArguments(schema, {
          ...args,
          'operation': 'invented',
        }),
        throwsFormatException,
      );
      expect(
        () => CopilotMcp.validateArguments(schema, {
          ...args,
          'option': {'type': 'user', 'unknown': true},
        }),
        throwsFormatException,
      );
    },
  );
}
