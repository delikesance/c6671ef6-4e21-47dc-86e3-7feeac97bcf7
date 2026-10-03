import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_command.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/sandbox/function_suite.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // These tests exercise real loopback HTTP. Other HTTP requests use MockClient;
  // the public documentation smoke test requires the explicit LIVE_MCP flag.
  HttpOverrides.global = null;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test(
    'registry omits bulk fixtures and supports targeted function contracts',
    () async {
      final bridge = CopilotMcp(
        MainApiClient(baseUrl: 'https://manager.example'),
        approve: (_, _) async => false,
      );
      await bridge.initialize();
      addTearDown(bridge.close);
      final response = await bridge.call(
        'local_block_registry',
        {},
        callID: 'light-registry',
      );
      final raw = (response['content'] as List).single['text'] as String;
      final value = jsonDecode(raw) as Map;
      expect(
        (value['sandbox_functions'] as List).every(
          (entry) => !entry.containsKey('cases'),
        ),
        true,
      );
      expect(
        raw.length,
        lessThan(jsonEncode(sandboxFunctionCatalog()).length ~/ 5),
      );
      final targeted = await bridge.call('local_block_registry', {
        'functions': [r'$getVar', 'setuservar', 'unknown'],
        'include_examples': true,
      }, callID: 'targeted-registry');
      final details =
          jsonDecode((targeted['content'] as List).single['text'] as String)
              as Map;
      expect(details['functions'], ['getvar', 'setuservar']);
      expect(details['unknown_functions'], ['unknown']);
      expect(details['sandbox_functions'], hasLength(2));
      expect(details['sandbox_functions'][0]['cases'], isNotEmpty);
      await expectLater(
        bridge.call('local_block_registry', {
          'include_examples': true,
        }, callID: 'unbounded-examples'),
        throwsFormatException,
      );
    },
  );
  test(
    'Copilot executes sandbox drafts without approval or external requests',
    () async {
      final bridge = CopilotMcp(
        MainApiClient(
          baseUrl: 'https://manager.example',
          httpClient: MockClient(
            (_) async => throw StateError('No network allowed'),
          ),
        ),
        approve: (_, _) async => throw StateError('No approval needed'),
      );
      await bridge.initialize();
      final result = await bridge.call('local_test_command', {
        'script': r'$var[gain;$isNumber[((opts.amount))]]$reply$c[]$var[gain]',
        'scenario': {
          'options': {'amount': 100},
        },
      }, callID: 'sandbox');
      expect(result['isError'], false);
      final value = jsonDecode(result['content'][0]['text'] as String);
      expect(value['responses'][0]['payload']['content'], 'true');
      expect(value['discord_verified'], false);
      final simulatedHttp = await bridge.call('local_test_command', {
        'script':
            r'$httpGet[https://example.com/data]$httpStatus|$httpResult[value]',
        'scenario': {
          'http': [
            {
              'method': 'GET',
              'url': 'https://example.com/data',
              'status': 201,
              'body': {'value': 'simulated'},
            },
          ],
        },
      }, callID: 'simulated-http');
      expect(simulatedHttp['isError'], false);
      final httpValue = jsonDecode(
        simulatedHttp['content'][0]['text'] as String,
      );
      expect(httpValue['responses'][0]['payload']['content'], '201|simulated');
      expect(httpValue['effects'].single['simulated'], true);
      expect(httpValue['unused_http_fixtures'], 0);
      final role = await bridge.call('local_test_command', {
        'script': r'$roleID[((opts.color))]',
        'scenario': {
          'options': {'color': 'Cor Branca'},
          'entities': {
            'guilds': {
              '10': {
                'roles': [
                  {'id': '60', 'name': 'Cor Branca'},
                ],
              },
            },
          },
        },
        'expected_content': '60',
        'expected_values': {'/entity_requests/0/operation': 'roles.list'},
      }, callID: 'role-fixture');
      expect(role['isError'], false);
      final roleValue = jsonDecode(role['content'][0]['text'] as String);
      expect(roleValue['contract_passed'], true);
      expect(roleValue['discord_verified'], false);
      final blocked = await bridge.call('local_test_command', {
        'script': r'$httpGet[https://example.com]',
      }, callID: 'blocked-sandbox');
      expect(blocked['isError'], true);
    },
  );
  test(
    'Copilot checks embed contracts and reports incorrect output as an error',
    () async {
      final bridge = CopilotMcp(
        MainApiClient(
          baseUrl: 'https://manager.example',
          httpClient: MockClient(
            (_) async => throw StateError('No network allowed'),
          ),
        ),
        approve: (_, _) async => throw StateError('No approval needed'),
      );
      await bridge.initialize();
      for (final expected in ['Score', 'Wrong title']) {
        final response = await bridge.call('local_test_command', {
          'script': r'$title[((opts.title))]',
          'scenario': {
            'options': {'title': 'Score'},
          },
          'expected_content': '',
          'expected_values': {'/responses/0/payload/embeds/0/title': expected},
        }, callID: 'embed-$expected');
        final value = jsonDecode(response['content'][0]['text'] as String);
        expect(value['success'], true);
        expect(value['contract_passed'], expected == 'Score');
        expect(response['isError'], expected != 'Score');
        expect(value['contract_checks'][1]['actual'], 'Score');
      }
    },
  );
  test(
    'Copilot validates generated components without accessing Discord',
    () async {
      final bridge = CopilotMcp(
        MainApiClient(
          baseUrl: 'https://manager.example',
          httpClient: MockClient(
            (_) async => throw StateError('No network allowed'),
          ),
        ),
        approve: (_, _) async => throw StateError('No approval needed'),
      );
      await bridge.initialize();
      final response = await bridge.call('local_test_command', {
        'script':
            r'$newModal[form;Profile]$addModalTextInput[Name;;name;short;2;20;false]',
        'expected_content': '',
        'expected_values': {
          '/responses/0/api_modal/title': 'Profile',
          '/responses/0/api_modal/components/0/component/required': false,
        },
      }, callID: 'modal-contract');
      expect(response['isError'], false);
      final value = jsonDecode(response['content'][0]['text'] as String);
      expect(value['contract_passed'], true);
      expect(value['discord_verified'], false);
    },
  );
  test(
    'BDFD preflight rejects the reported ticket script without approval',
    () async {
      var approvals = 0;
      var requests = 0;
      final bridge = CopilotMcp(
        MainApiClient(
          baseUrl: 'https://manager.example',
          httpClient: MockClient((request) async {
            requests++;
            throw StateError(
              'Preflight must not contact Discord or the manager',
            );
          }),
        ),
        approve: (_, _) async {
          approvals++;
          return true;
        },
      );
      await bridge.initialize();
      const invalid = r'''$if[$isTicket==false]
$respondWithMessage[Only available in a ticket.;true]
$stop
$endif
$if[((opts.logs.id))!=]
$channelSendMessage[((opts.logs.id));Ticket closed by ((author.username)).]
$endif
$respondWithMessage[Closing in 3 seconds...;true]
$wait[3]
$closeTicket''';
      final rejected = await bridge.call('local_validate_bdfd', {
        'script': invalid,
      }, callID: 'invalid-ticket');
      expect(rejected['isError'], true);
      final rejectedValue =
          jsonDecode((rejected['content'] as List).single['text'] as String)
              as Map;
      expect(rejectedValue['valid'], false);
      expect(
        jsonEncode(rejectedValue['diagnostics']),
        contains(r'$respondWithMessage'),
      );
      expect(validateCopilotBdfd(r'$let[opener;$userID]')['valid'], false);
      final corrected = invalid
          .replaceAll(
            r'$respondWithMessage[Only available in a ticket.;true]',
            r'$ephemeral$sendMessage[Only available in a ticket.]',
          )
          .replaceAll(
            r'$respondWithMessage[Closing in 3 seconds...;true]',
            r'$ephemeral$sendMessage[Closing in 3 seconds...]',
          );
      final accepted = await bridge.call('local_validate_bdfd', {
        'script': corrected,
      }, callID: 'corrected-ticket');
      expect(accepted['isError'], false);
      final acceptedValue =
          jsonDecode((accepted['content'] as List).single['text'] as String)
              as Map;
      expect(acceptedValue['valid'], true);
      expect(acceptedValue['runtime_tested'], false);
      expect(approvals, 0);
      expect(requests, 0);
      expect(() => copilotExecutionData(invalid), throwsFormatException);
    },
  );
  test('closed compiler creates real blocks and refuses unknown functions', () {
    final actions = compileCopilotCommand('Hello world');
    final types = BotCreatorActionType.values.map((t) => t.name).toSet();
    expect(actions, isNotEmpty);
    expect(actions.every((a) => types.contains(a['type'])), isTrue);
    expect(
      () => compileCopilotCommand(r'$totallyInventedFunction[foo]'),
      throwsFormatException,
    );
    expect(
      () => compileCopilotCommand(r'$sendMessage['),
      throwsFormatException,
    );
  });
  test('saved BDFD stays source-only after command normalization', () {
    final command = normalizeCommandData({
      'name': 'hello',
      'type': 'chatInput',
      'data': copilotExecutionData('Hello'),
    });
    final data = command['data'] as Map;
    expect(data['executionMode'], 'bdfd_script');
    expect(data['bdfdScriptContent'], 'Hello');
    expect(data['actions'], isEmpty);
  });
  test('Copilot can save JavaScript and independent visual blocks', () {
    final js = copilotExecutionDataForMode(
      'javascript',
      script: 'await interaction.reply("Hello");',
    );
    expect(js['executionMode'], 'javascript');
    expect(js['jsScriptContent'], contains('interaction.reply'));
    expect(js['bdfdScriptContent'], '');
    expect(js['actions'], isEmpty);
    final workflow = copilotExecutionDataForMode(
      'workflow',
      actionsJson: jsonEncode([
        {
          'type': 'respondWithMessage',
          'payload': {'content': 'Hello'},
        },
      ]),
    );
    expect(workflow['executionMode'], 'workflow');
    expect((workflow['actions'] as List).single['type'], 'respondWithMessage');
    expect(workflow['jsScriptContent'], '');
    expect(workflow['bdfdScriptContent'], '');
    final updated = replaceCopilotExecution(
      {
        'id': 'command',
        'data': {'executionMode': 'workflow', 'actions': []},
      },
      HashUtil.calculateHash({
        'id': 'command',
        'data': {'executionMode': 'workflow', 'actions': []},
      }),
      '',
      executionMode: 'workflow',
      actionsJson: jsonEncode([
        {
          'type': 'respondWithMessage',
          'payload': {'content': 'Hello'},
        },
      ]),
    );
    expect((updated['data'] as Map)['executionMode'], 'workflow');
    expect(((updated['data'] as Map)['actions'] as List), hasLength(1));
    expect(
      () => copilotExecutionDataForMode(
        'workflow',
        actionsJson: '[{"type":"invented","payload":{}}]',
      ),
      throwsArgumentError,
    );
  });
  test('cloud command sync reports runner acknowledgement', () async {
    var synced = false;
    final api = MainApiClient(
      baseUrl: 'https://manager.example',
      accessToken: 'account-secret',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/gateway/bots/123456789012345/commands/sync');
        expect((jsonDecode(request.body) as Map)['commandId'], 'command');
        return http.Response(
          jsonEncode({'ok': true, 'persisted': true, 'runner_synced': synced}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    expect(
      await api.syncCommandWithStatus('123456789012345', 'Bot', 'command', {}),
      isFalse,
    );
    synced = true;
    expect(
      await api.syncCommandWithStatus('123456789012345', 'Bot', 'command', {}),
      isTrue,
    );
  });
  test(
    'workflow and variable sync require manager runtime acknowledgement',
    () async {
      var acknowledged = false;
      final paths = <String>[];
      final api = MainApiClient(
        baseUrl: 'https://manager.example',
        accessToken: 'account-secret',
        httpClient: MockClient((request) async {
          paths.add(request.url.path);
          final body = jsonDecode(request.body) as Map;
          if (request.url.path.endsWith('/workflows/sync')) {
            expect(body['workflowName'], 'welcome');
            expect(body['workflow'], {'name': 'welcome', 'actions': []});
          } else if (request.url.path.endsWith('/global/set')) {
            expect(body, {'key': 'count', 'value': 3});
          } else {
            expect(body['scope'], 'guild');
            expect(body['defaultValue'], 'hello');
            expect(body['valueType'], 'string');
          }
          return http.Response(
            jsonEncode({
              'ok': true,
              'persisted': true,
              'runner_synced': acknowledged,
            }),
            200,
          );
        }),
      );
      for (final state in [false, true]) {
        acknowledged = state;
        expect(
          await api.syncWorkflowWithStatus(
            '123456789012345',
            'Bot',
            'welcome',
            {'name': 'welcome', 'actions': []},
          ),
          state,
        );
        expect(
          await api.setVariableWithStatus('123456789012345', {
            'key': 'count',
            'scope': 'global',
            'value': 3,
          }),
          state,
        );
        expect(
          await api.setVariableWithStatus('123456789012345', {
            'key': 'greeting',
            'scope': 'guild',
            'value': 'hello',
          }),
          state,
        );
      }
      expect(paths.where((p) => p.endsWith('/workflows/sync')).length, 2);
    },
  );
  test(
    'execution-only edit preserves command identity and refuses stale revision',
    () {
      final command = {
        'id': 'stable',
        'discordId': '123456789012345',
        'name': 'hello',
        'description': 'Original',
        'data': {
          'defaultMemberPermissions': '8',
          'options': [
            {'name': 'target', 'type': 3},
          ],
          'response': {'text': 'Old response'},
          'actions': [],
        },
      };
      final hash = HashUtil.calculateHash(command);
      final updated = replaceCopilotExecution(command, hash, 'New response');
      expect(updated['id'], 'stable');
      expect(updated['discordId'], '123456789012345');
      expect(updated['name'], 'hello');
      final data = updated['data'] as Map;
      expect(data['defaultMemberPermissions'], '8');
      expect(data['options'], (command['data'] as Map)['options']);
      expect(data['bdfdScriptContent'], 'New response');
      expect(data['executionMode'], 'bdfd_script');
      expect(data['actions'], isEmpty);
      expect(data['response']['text'], '');
      expect(HashUtil.calculateHash(command), hash);
      expect(
        () => replaceCopilotExecution(updated, hash, 'Another edit'),
        throwsStateError,
      );
    },
  );
  test('subcommand edit changes only the explicitly chosen route', () {
    final command = {
      'id': 'command',
      'data': {
        'subcommandWorkflows': {
          'config/status': {'actions': []},
          'config/help': {'actions': []},
        },
      },
    };
    final revision = HashUtil.calculateHash(command);
    expect(
      () => replaceCopilotExecution(command, revision, 'hello'),
      throwsStateError,
    );
    final updated = replaceCopilotExecution(
      command,
      revision,
      'hello',
      route: 'config/status',
    );
    expect((updated['data'] as Map)['subcommandWorkflows']['config/help'], {
      'actions': [],
    });
    expect(
      (updated['data']
          as Map)['subcommandWorkflows']['config/status']['actions'],
      isEmpty,
    );
  });
  test('mutation approval and idempotency protect the remote API', () async {
    var calls = 0;
    var approvals = 0;
    var allowed = false;
    final api = MainApiClient(
      baseUrl: 'https://manager.example',
      accessToken: 'account-secret',
      httpClient: MockClient((r) async {
        calls++;
        expect(r.url.path, '/gateway/bots/123456789012345/stop');
        return http.Response('{}', 200);
      }),
    );
    final mcp = CopilotMcp(
      api,
      approve: (name, args) async {
        approvals++;
        return allowed;
      },
    );
    await mcp.initialize();
    final rejected = await mcp.call('remote_stop_bot', {
      'bot_id': '123456789012345',
    }, callID: 'rejected');
    expect(rejected['isError'], isTrue);
    expect(calls, 0);
    expect(approvals, 1);
    await expectLater(
      mcp.call('remote_stop_bot', {
        'bot_id': '123456789012345',
        'shell': 'bad',
      }, callID: 'invalid'),
      throwsFormatException,
    );
    expect(approvals, 1);
    allowed = true;
    await mcp.call('remote_stop_bot', {
      'bot_id': '123456789012345',
    }, callID: 'accepted');
    await mcp.call('remote_stop_bot', {
      'bot_id': '123456789012345',
    }, callID: 'accepted');
    expect(calls, 1);
    expect(approvals, 2);
    await mcp.close();
  });
  test(
    'documentation MCP handshake is separate from account credentials',
    () async {
      final methods = <String>[];
      final docs = MockClient((r) async {
        expect(r.headers['Authorization'], isNull);
        final request = jsonDecode(r.body) as Map;
        methods.add(request['method'] as String);
        if (request['id'] == null) return http.Response('', 202);
        return http.Response(
          jsonEncode({
            'jsonrpc': '2.0',
            'id': request['id'],
            'result': request['method'] == 'initialize'
                ? {'protocolVersion': '2025-11-25', 'capabilities': {}}
                : {
                    'content': [
                      {'type': 'text', 'text': 'Official documentation'},
                    ],
                  },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final mcp = CopilotMcp(
        MainApiClient(
          baseUrl: 'https://manager.example',
          accessToken: 'account-secret',
        ),
        approve: (_, _) async => false,
        documentationClient: docs,
      );
      await mcp.initialize();
      final result = await mcp.call('docs_get', {
        'slug': 'sendmessage',
      }, callID: 'documentation');
      expect(methods, [
        'initialize',
        'notifications/initialized',
        'tools/call',
      ]);
      expect(
        (result['content'] as List).first['text'],
        'Official documentation',
      );
      expect(
        mcp.tools.any((t) => t['name'].toString().contains('roulette')),
        isFalse,
      );
      await mcp.close();
    },
  );
  test(
    'local HTTP MCP enforces bearer authentication and rejects browser origins',
    () async {
      if (!(Platform.isWindows || Platform.isLinux || Platform.isMacOS)) return;
      final mcp = CopilotMcp(
        MainApiClient(baseUrl: 'https://manager.example'),
        approve: (_, _) async => false,
      );
      await mcp.initialize();
      await mcp.startServer();
      final uri = Uri.parse(mcp.endpoint!);
      final body = jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': 'initialize',
        'params': {},
      });
      expect((await http.post(uri, body: body)).statusCode, 401);
      expect(
        (await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer ${mcp.bearer}',
            'Origin': 'https://untrusted.example',
          },
          body: body,
        )).statusCode,
        403,
      );
      final valid = await http.post(
        uri,
        headers: {'Authorization': 'Bearer ${mcp.bearer}'},
        body: body,
      );
      expect(valid.statusCode, 200);
      expect(
        (jsonDecode(valid.body) as Map)['result']['serverInfo']['name'],
        'bot-creator-studio-bridge',
      );
      final rejected = await http.post(
        uri,
        headers: {'Authorization': 'Bearer ${mcp.bearer}'},
        body: jsonEncode({
          'jsonrpc': '2.0',
          'id': 2,
          'method': 'tools/call',
          'params': {
            'name': 'remote_stop_bot',
            'arguments': {'bot_id': 'invalid'},
          },
        }),
      );
      final diagnostic = (jsonDecode(rejected.body) as Map)['result'];
      expect(diagnostic['isError'], true);
      expect(diagnostic['content'][0]['text'], 'Invalid bot ID');
      await mcp.close();
    },
  );
  test('nested secrets are not exposed in MCP results', () {
    expect(
      CopilotMcp.redact({
        'token': 'secret',
        'data': {'Authorization': 'secret', 'name': 'bot'},
      }),
      {
        'data': {'name': 'bot'},
      },
    );
    expect(
      CopilotMcp.redact({
        'headers': '{"Authorization":"Bearer secret","Accept":"json"}',
      }),
      {'headers': '{"Accept":"json"}'},
    );
  });
  test(
    'live documentation MCP can be read through the application bridge',
    () async {
      final mcp = CopilotMcp(
        MainApiClient(baseUrl: 'https://api.bot-creator.fr'),
        approve: (_, _) async => false,
      );
      await mcp.initialize();
      try {
        final result = await mcp.call('docs_search', {
          'query': 'sendmessage',
          'limit': 5,
        }, callID: 'live-read');
        expect(result['isError'], isNot(true));
        expect(result['content'], isNotEmpty);
      } finally {
        await mcp.close();
      }
    },
    skip: !const bool.fromEnvironment('LIVE_MCP'),
  );
}
