import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/copilot/copilot_tools.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _Call {
  _Call(this.method, this.path, this.body);
  final String method;
  final String path;
  final Map<String, dynamic>? body;
}

(CopilotTools, List<_Call>) _tools(
  http.Response Function(http.Request r) respond,
) {
  final calls = <_Call>[];
  final api = StudioApi(
    baseUrl: 'https://api.test',
    client: MockClient((request) async {
      calls.add(
        _Call(
          request.method,
          request.url.path,
          request.body.isEmpty
              ? null
              : jsonDecode(request.body) as Map<String, dynamic>,
        ),
      );
      return respond(request);
    }),
  )..accessToken = ({bool force = false}) async => 'tok';
  return (CopilotTools(api), calls);
}

http.Response _json(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status);

String _text(Map<String, dynamic> result) =>
    (result['content'] as List).first['text'] as String;

void main() {
  test(
    'bot JavaScript : le script JavaScript est enregistré, les blocs refusés',
    () async {
      final calls = <Map<String, dynamic>>[];
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient((request) async {
          if (request.body.isNotEmpty) {
            calls.add(jsonDecode(request.body) as Map<String, dynamic>);
          }
          return http.Response(jsonEncode({'revision': 'r1'}), 200);
        }),
      )..accessToken = ({bool force = false}) async => 'tok';
      final tools = CopilotTools(api, javascript: true);

      final ok = await tools.run('local_create_command', {
        'bot_id': 'b1',
        'name': 'ping',
        'description': 'x',
        'script': 'await ctx.reply("pong")',
      });
      expect(ok['isError'], isNot(true), reason: _text(ok));
      final data = (calls.single['command'] as Map)['data'] as Map;
      expect(data['executionMode'], 'javascript');
      expect(data['jsScriptContent'], contains('pong'));

      final blocks = await tools.run('local_create_command', {
        'bot_id': 'b1',
        'name': 'ping2',
        'description': 'x',
        'execution_mode': 'workflow',
        'actions_json': '[]',
      });
      expect(blocks['isError'], isTrue);
      expect(_text(blocks), contains('JavaScript'));
      expect(calls, hasLength(1), reason: 'les blocs ne partent jamais');
    },
  );

  test('seuls les outils que le Studio sait exécuter sont annoncés', () {
    final names = CopilotTools.names;
    expect(names, contains('local_create_command'));
    expect(names, contains('local_create_workflow'));
    expect(names, contains('remote_start_bot'));
    expect(names, isNot(contains('local_validate_bdfd')));
    expect(names, isNot(contains('local_test_command')));
    expect(names, isNot(contains('local_start_bot')));
    expect(names, isNot(contains('local_update_command_options')));
    expect(CopilotTools.isMutating('local_create_command'), isTrue);
    expect(CopilotTools.isMutating('local_list_commands'), isFalse);
    expect(CopilotTools.serverSide, contains('remote_stop_bot'));
  });

  test('créer une commande : bloc visuel enregistré par la route v2', () async {
    final (tools, calls) = _tools((_) => _json({'revision': 'r2'}));
    final result = await tools.run('local_create_command', {
      'bot_id': 'b1',
      'name': 'ping',
      'description': 'Répond pong',
      'actions_json': jsonEncode([
        {
          'type': 'sendMessage',
          'payload': {'content': 'pong'},
        },
      ]),
    });
    expect(result['isError'], isNot(true), reason: _text(result));
    final patch = calls.single;
    expect(patch.method, 'PATCH');
    expect(patch.path, startsWith('/api/v2/bots/b1/commands/'));
    final command = patch.body!['command'] as Map<String, dynamic>;
    expect(command['name'], 'ping');
    expect(command['data']['executionMode'], 'workflow');
    expect(command['data']['actions'][0]['payload']['content'], 'pong');
    expect(jsonDecode(_text(result))['revision'], 'r2');
  });

  test('BDFD et JavaScript sont refusés avec une explication', () async {
    final (tools, calls) = _tools((_) => _json({}));
    final result = await tools.run('local_create_command', {
      'bot_id': 'b1',
      'name': 'ping',
      'description': 'x',
      'execution_mode': 'bdfd_script',
      'script': r'$sendMessage[pong]',
    });
    expect(result['isError'], isTrue);
    expect(_text(result), contains('visual'));
    expect(calls, isEmpty, reason: 'rien ne part vers le serveur');
  });

  test('actions invalides : refusées avant tout appel', () async {
    final (tools, calls) = _tools((_) => _json({}));
    final result = await tools.run('local_create_command', {
      'bot_id': 'b1',
      'name': 'ping',
      'description': 'x',
      'actions_json': '{"pas": "un tableau"}',
    });
    expect(result['isError'], isTrue);
    expect(calls, isEmpty);
  });

  test('créer un workflow événementiel', () async {
    final (tools, calls) = _tools((r) {
      if (r.url.path.endsWith('/bots')) return _json({'bots': []});
      return _json({'ok': true});
    });
    final result = await tools.run('local_create_workflow', {
      'bot_id': 'b1',
      'name': 'bienvenue',
      'workflow_type': 'event',
      'event_trigger': {'category': 'members', 'event': 'guildMemberAdd'},
      'actions': [
        {
          'type': 'sendMessage',
          'payload': {'content': 'Salut'},
        },
      ],
    });
    expect(result['isError'], isNot(true), reason: _text(result));
    final sync = calls.firstWhere((c) => c.path.endsWith('/workflows/sync'));
    expect(sync.body!['workflowName'], 'bienvenue');
    final workflow = sync.body!['workflow'] as Map<String, dynamic>;
    expect(workflow['eventTrigger']['event'], 'guildMemberAdd');
    expect(workflow['actions'], hasLength(1));
  });

  test('une révision périmée (409) est expliquée au modèle', () async {
    final (tools, _) = _tools((r) {
      if (r.method == 'GET') {
        return _json({
          'command': {
            'id': 'c1',
            'name': 'ping',
            'data': {'actions': []},
          },
          'revision': 'r1',
        });
      }
      return _json({
        'message': 'conflict',
        'code': 'bot_config_revision_conflict',
      }, 409);
    });
    final result = await tools.run('local_update_command_execution', {
      'bot_id': 'b1',
      'command_id': 'c1',
      'expected_revision': 'old',
      'actions_json': '[]',
    });
    expect(result['isError'], isTrue);
    expect(_text(result), contains('Stale revision'));
  });

  test('variable globale ou à portée', () async {
    final (tools, calls) = _tools((_) => _json({'ok': true}));
    await tools.run('local_set_variable', {
      'bot_id': 'b1',
      'key': 'score',
      'scope': 'global',
      'value': 3,
      'expected_revision': 'r',
    });
    await tools.run('local_set_variable', {
      'bot_id': 'b1',
      'key': 'xp',
      'scope': 'guildMember',
      'value': 0,
      'expected_revision': 'r',
    });
    expect(calls[0].path, endsWith('/variables/global/set'));
    expect(calls[1].path, endsWith('/variables/scoped-definitions/set'));
    expect(calls[1].body!['scope'], 'guildMember');
  });

  test('un outil inconnu est une erreur lisible, pas une exception', () async {
    final (tools, _) = _tools((_) => _json({}));
    final result = await tools.run('local_start_bot', {'bot_id': 'b1'});
    expect(result['isError'], isTrue);
  });
}
