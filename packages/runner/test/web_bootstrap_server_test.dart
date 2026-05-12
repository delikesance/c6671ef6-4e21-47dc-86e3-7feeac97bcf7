import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_shared/bot/json_variable_store.dart';
import 'package:bot_creator_runner/runner_bot_store.dart';
import 'package:bot_creator_runner/web_bootstrap_server.dart';
import 'package:bot_creator_runner/web_log_store.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

void main() {
  group('RunnerWebBootstrapServer', () {
    RunnerWebBootstrapServer? server;

    tearDown(() async {
      await server?.stop();
    });

    test(
      'loopback host without token allows protected status endpoint',
      () async {
        final port = await _allocatePort();
        server = RunnerWebBootstrapServer(
          host: '127.0.0.1',
          port: port,
          logStore: RunnerLogStore(),
        );
        await server!.start();

        final response = await http.get(
          Uri.parse('http://127.0.0.1:$port/status'),
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(
          (jsonDecode(response.body) as Map<String, dynamic>)['apiVersion'],
          2,
        );
      },
    );

    test(
      'requires bearer auth on protected endpoints when token configured',
      () async {
        final port = await _allocatePort();
        server = RunnerWebBootstrapServer(
          host: '127.0.0.1',
          port: port,
          apiToken: 'secret-token',
          logStore: RunnerLogStore(),
        );
        await server!.start();

        final noAuth = await http.get(
          Uri.parse('http://127.0.0.1:$port/status'),
        );
        final wrongAuth = await http.get(
          Uri.parse('http://127.0.0.1:$port/status'),
          headers: <String, String>{'authorization': 'Bearer wrong-token'},
        );
        final okAuth = await http.get(
          Uri.parse('http://127.0.0.1:$port/status'),
          headers: <String, String>{'authorization': 'Bearer secret-token'},
        );
        final health = await http.get(
          Uri.parse('http://127.0.0.1:$port/health'),
        );

        expect(noAuth.statusCode, HttpStatus.unauthorized);
        expect(wrongAuth.statusCode, HttpStatus.unauthorized);
        expect(okAuth.statusCode, HttpStatus.ok);
        expect(health.statusCode, HttpStatus.ok);
        expect((jsonDecode(health.body) as Map<String, dynamic>)['ok'], isTrue);
      },
    );

    test('supports variable endpoints for global/scoped data', () async {
      final port = await _allocatePort();
      final variableStore = JsonVariableStore();
      server = RunnerWebBootstrapServer(
        host: '127.0.0.1',
        port: port,
        logStore: RunnerLogStore(),
        variableStore: variableStore,
      );
      await server!.start();

      final base = Uri.parse('http://127.0.0.1:$port');
      const botId = 'bot-variables';

      final sync = await http.post(
        base.resolve('/bots/sync'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'botId': botId,
          'botName': 'Test Bot',
          'config': <String, dynamic>{
            'token': 'abc',
            'globalVariables': <String, dynamic>{'foo': 'bar'},
            'scopedVariableDefinitions': <Map<String, dynamic>>[
              <String, dynamic>{
                'scope': 'user',
                'key': 'coins',
                'defaultValue': 0,
                'valueType': 'number',
              },
            ],
          },
        }),
      );
      expect(sync.statusCode, HttpStatus.ok);

      final getGlobals = await http.get(
        base.resolve('/bots/$botId/variables/global'),
      );
      final globalsJson = Map<String, dynamic>.from(
        jsonDecode(getGlobals.body) as Map,
      );
      expect(getGlobals.statusCode, HttpStatus.ok);
      expect(globalsJson['variables']['foo'], 'bar');

      final setGlobal = await http.post(
        base.resolve('/bots/$botId/variables/global/set'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'key': 'hello', 'value': 42}),
      );
      expect(setGlobal.statusCode, HttpStatus.ok);

      final getGlobalsAfterSet = await http.get(
        base.resolve('/bots/$botId/variables/global'),
      );
      final globalsAfterSetJson = Map<String, dynamic>.from(
        jsonDecode(getGlobalsAfterSet.body) as Map,
      );
      expect(globalsAfterSetJson['variables']['hello'], 42);

      final removeGlobal = await http.post(
        base.resolve('/bots/$botId/variables/global/remove'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'key': 'hello'}),
      );
      expect(removeGlobal.statusCode, HttpStatus.ok);

      final defs = await http.get(
        base.resolve('/bots/$botId/variables/scoped-definitions'),
      );
      final defsJson = Map<String, dynamic>.from(jsonDecode(defs.body) as Map);
      expect(defs.statusCode, HttpStatus.ok);
      expect((defsJson['definitions'] as List).length, 1);

      final setDef = await http.post(
        base.resolve('/bots/$botId/variables/scoped-definitions/set'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'scope': 'user',
          'key': 'score',
          'defaultValue': 10,
          'valueType': 'number',
        }),
      );
      expect(setDef.statusCode, HttpStatus.ok);

      await variableStore.setScopedVariable(
        botId,
        'user',
        'u-score',
        'score',
        7,
      );
      await variableStore.setScopedVariable(
        botId,
        'user',
        'u-legacy-score',
        'bc_score',
        8,
      );

      final removeDef = await http.post(
        base.resolve('/bots/$botId/variables/scoped-definitions/remove'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'scope': 'user',
          'key': 'score',
          'purgeStoredValues': true,
        }),
      );
      expect(removeDef.statusCode, HttpStatus.ok);

      final purgedScoreValues = await http.get(
        base.resolve(
          '/bots/$botId/variables/scoped-values?scope=user&key=score',
        ),
      );
      final purgedScoreJson = Map<String, dynamic>.from(
        jsonDecode(purgedScoreValues.body) as Map,
      );
      expect(purgedScoreValues.statusCode, HttpStatus.ok);
      expect(purgedScoreJson['values'], isEmpty);

      await variableStore.setScopedVariable(botId, 'user', 'u1', 'coins', 99);
      await variableStore.setScopedVariable(
        botId,
        'user',
        'u2',
        'bc_legacy',
        'yes',
      );

      final scopedValues = await http.get(
        base.resolve(
          '/bots/$botId/variables/scoped-values?scope=user&key=coins',
        ),
      );
      final scopedJson = Map<String, dynamic>.from(
        jsonDecode(scopedValues.body) as Map,
      );
      expect(scopedValues.statusCode, HttpStatus.ok);
      expect(scopedJson['values']['u1'], 99);

      final legacyValues = await http.get(
        base.resolve(
          '/bots/$botId/variables/scoped-values?scope=user&key=legacy',
        ),
      );
      final legacyJson = Map<String, dynamic>.from(
        jsonDecode(legacyValues.body) as Map,
      );
      expect(legacyValues.statusCode, HttpStatus.ok);
      expect(legacyJson['values']['u2'], 'yes');
    });

    test(
      'syncs and deletes a single command without rebuilding payloads',
      () async {
        final port = await _allocatePort();
        server = RunnerWebBootstrapServer(
          host: '127.0.0.1',
          port: port,
          logStore: RunnerLogStore(),
        );
        await server!.start();

        final base = Uri.parse('http://127.0.0.1:$port');
        const botId = 'bot-command-sync';

        final initial = await http.post(
          base.resolve('/bots/sync'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'botName': 'Command Bot',
            'config': <String, dynamic>{
              'token': 'abc',
              'globalVariables': <String, dynamic>{'old_key': 'old_value'},
              'scopedVariableDefinitions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'key': 'score',
                  'scope': 'guild',
                  'defaultValue': 1,
                  'valueType': 'number',
                },
              ],
              'workflows': <Map<String, dynamic>>[
                <String, dynamic>{
                  'name': 'cleanup',
                  'workflowType': 'event',
                  'entryPoint': 'workflow_cleanup',
                  'arguments': <Map<String, dynamic>>[],
                  'actions': <Map<String, dynamic>>[],
                },
              ],
              'commands': <Map<String, dynamic>>[
                <String, dynamic>{
                  'id': 'cmd-1',
                  'name': 'first',
                  'type': 'chatInput',
                  'data': <String, dynamic>{'version': 1},
                },
              ],
            },
          }),
        );
        expect(initial.statusCode, HttpStatus.ok);

        final syncCommand = await http.post(
          base.resolve('/bots/$botId/commands/sync'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'commandId': 'cmd-2',
            'command': <String, dynamic>{
              'name': 'second',
              'type': 'chatInput',
              'data': <String, dynamic>{'version': 2},
            },
          }),
        );
        expect(syncCommand.statusCode, HttpStatus.ok);

        final syncedEntry = await RunnerBotStore().loadEntry(botId);
        expect(syncedEntry, isNotNull);
        final syncedCommands = syncedEntry!.config.commands;
        expect(syncedCommands.map((entry) => entry['id']).toList(), [
          'cmd-1',
          'cmd-2',
        ]);

        final deleteCommand = await http.post(
          base.resolve('/bots/$botId/commands/delete'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'commandId': 'cmd-1',
          }),
        );
        expect(deleteCommand.statusCode, HttpStatus.ok);

        final deletedEntry = await RunnerBotStore().loadEntry(botId);
        expect(deletedEntry, isNotNull);
        final remainingCommands = deletedEntry!.config.commands;
        expect(remainingCommands.map((entry) => entry['id']).toList(), [
          'cmd-2',
        ]);

        final workflowSync = await http.post(
          base.resolve('/bots/$botId/workflows/sync'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'workflowName': 'nightly-report',
            'workflow': <String, dynamic>{
              'workflowType': 'event',
              'entryPoint': 'workflow_nightly_report',
              'arguments': <Map<String, dynamic>>[],
              'actions': <Map<String, dynamic>>[],
            },
          }),
        );
        expect(workflowSync.statusCode, HttpStatus.ok);

        final workflowDelete = await http.post(
          base.resolve('/bots/$botId/workflows/delete'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'workflowName': 'cleanup',
          }),
        );
        expect(workflowDelete.statusCode, HttpStatus.ok);

        final renameGlobal = await http.post(
          base.resolve('/bots/$botId/variables/global/rename'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'oldKey': 'old_key',
            'newKey': 'new_key',
          }),
        );
        expect(renameGlobal.statusCode, HttpStatus.ok);

        final removeScopedDef = await http.post(
          base.resolve('/bots/$botId/variables/scoped-definitions/remove'),
          headers: const <String, String>{'content-type': 'application/json'},
          body: jsonEncode(<String, dynamic>{
            'botId': botId,
            'key': 'score',
            'scope': 'guild',
          }),
        );
        expect(removeScopedDef.statusCode, HttpStatus.ok);

        final configUpdatesEntry = await RunnerBotStore().loadEntry(botId);
        expect(configUpdatesEntry, isNotNull);
        final workflows = configUpdatesEntry!.config.workflows;
        expect(workflows.map((entry) => entry['name']).toList(), [
          'nightly-report',
        ]);

        final globals = configUpdatesEntry.config.globalVariables;
        expect(globals.containsKey('new_key'), isTrue);
        expect(globals.containsKey('old_key'), isFalse);

        final scopedDefs = configUpdatesEntry.config.scopedVariableDefinitions;
        expect(scopedDefs, isEmpty);
      },
    );

    test('exposes inbound webhook endpoint contract', () async {
      final port = await _allocatePort();
      server = RunnerWebBootstrapServer(
        host: '127.0.0.1',
        port: port,
        logStore: RunnerLogStore(),
      );
      await server!.start();

      final base = Uri.parse('http://127.0.0.1:$port');
      const botId = 'bot-inbound';

      final sync = await http.post(
        base.resolve('/bots/sync'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{
          'botId': botId,
          'botName': 'Inbound Bot',
          'config': <String, dynamic>{
            'token': 'abc',
            'inboundWebhooks': true,
            'inboundWebhookEndpoints': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 'wh_1',
                'path': 'orders',
                'workflowName': 'incoming',
                'secret': 'top-secret',
                'enabled': true,
              },
            ],
            'workflows': <Map<String, dynamic>>[
              <String, dynamic>{
                'name': 'incoming',
                'workflowType': 'general',
                'entryPoint': 'main',
                'actions': <Map<String, dynamic>>[],
              },
            ],
          },
        }),
      );
      expect(sync.statusCode, HttpStatus.ok);

      final noSecret = await http.post(
        base.resolve('/bots/$botId/inbound/orders'),
        headers: const <String, String>{'content-type': 'application/json'},
        body: jsonEncode(<String, dynamic>{'hello': 'world'}),
      );
      expect(noSecret.statusCode, HttpStatus.unauthorized);

      final response = await http.post(
        base.resolve('/bots/$botId/inbound/orders'),
        headers: const <String, String>{
          'content-type': 'application/json',
          'x-bot-webhook-secret': 'top-secret',
        },
        body: jsonEncode(<String, dynamic>{'hello': 'world'}),
      );

      expect(response.statusCode, HttpStatus.conflict);
      final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      expect((json['error'] ?? '').toString(), contains('not running'));
    });
  });
}

Future<int> _allocatePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}
