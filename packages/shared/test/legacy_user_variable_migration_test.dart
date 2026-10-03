import 'dart:convert';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/sandbox_store.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/legacy_user_variable_migration.dart';
import 'package:bot_creator_shared/utils/runtime_variables.dart';
import 'package:test/test.dart';

const guild = '123456789012345';
const user = '234567890123456';

class _ConfigStore extends SandboxStore {
  _ConfigStore(this.config);
  final Map<String, dynamic> config;

  @override
  Future<Map<String, dynamic>> getApp(String botId) async => config;
}

void main() {
  test(
    'official user writes require a guild while global-user writes work in DMs',
    () async {
      final official = await testCommandInSandbox({
        'script': r'$setUserVar[coins;7]',
        'variables': {'guild.id': ''},
      });
      expect(official['success'], false);
      expect(
        official['storage_after']['scoped'].containsKey('guildMember'),
        false,
      );
      final global = await testCommandInSandbox({
        'script': r'$setVar[coins;7;$authorID]$getVar[coins;$authorID]',
        'variables': {'guild.id': ''},
      });
      expect(global['success'], true);
      expect(global['responses'][0]['payload']['content'], '7');
      expect(global['storage_after']['scoped']['user']['20']['coins'], '7');
    },
  );
  test(
    'official nested getters never hydrate or seed a global-user target',
    () async {
      final result = await testCommandInSandbox({
        'bdfdUserVariableSemantics': 2,
        'definitions': [
          {'scope': 'user', 'key': 'coins', 'defaultValue': 5},
          {'scope': 'guildMember', 'key': 'coins', 'defaultValue': 0},
        ],
        'scoped': {
          'user': {
            '20': {'coins': 9},
          },
        },
        'actions': [
          {
            'type': 'runBdfdScript',
            'payload': {'scriptContent': r'$getUserVar[coins;21]'},
          },
        ],
      });
      expect(result['success'], true);
      expect(result['responses'][0]['payload']['content'], '0');
      expect(
        result['storage_after']['scoped']['user'].containsKey('21'),
        false,
      );
    },
  );
  test('nested sandbox BDFD actions inherit the target dialect', () async {
    for (final version in [1, 2]) {
      final result = await testCommandInSandbox({
        'bdfdUserVariableSemantics': version,
        'actions': [
          {
            'type': 'runBdfdScript',
            'payload': {
              'scriptContent': r'$setUserVar[coins;7]$getUserVar[coins]',
            },
          },
        ],
      });
      expect(result['success'], true);
      final scoped = result['storage_after']['scoped'];
      expect(
        scoped[version == 1 ? 'user' : 'guildMember'][version == 1
            ? '20'
            : '10:20']['coins'],
        '7',
      );
    }
  });
  test(
    'runtime semantics preserve unversioned bots and activate version two',
    () async {
      final variables = <String, String>{};
      await injectBdfdUserVariableSemantics(
        store: _ConfigStore({}),
        botId: 'bot',
        runtimeVariables: variables,
      );
      expect(variables['bdfd.userVariableSemantics'], '1');
      await injectBdfdUserVariableSemantics(
        store: _ConfigStore({'bdfdUserVariableSemantics': 2}),
        botId: 'bot',
        runtimeVariables: variables,
      );
      expect(variables['bdfd.userVariableSemantics'], '2');
    },
  );

  test(
    'rewrites nested global-user calls and preserves explicit guilds and escapes',
    () {
      const source =
          r'\$getUserVar[escaped] $c[$getUserVar[comment]] '
          r'$setUserVar[coins;$sum[$getUserVar[coins];1]] '
          r'$getUserVar[coins;21;10] $getUserVar[coins; ; ]';
      final result = migrateLegacyUserVariableScript(source);
      expect(
        result.source,
        r'\$getUserVar[escaped] $c[$getUserVar[comment]] '
        r'$setVar[coins;$sum[$getVar[coins;$authorID];1];$authorID] '
        r'$getUserVar[coins;21;10] $getVar[coins;$authorID]',
      );
      expect(result.changes, 3);
      expect(migrateLegacyUserVariableScript(result.source).changes, 0);
      expect(
        () => migrateLegacyUserVariableScript(r'$eval[$getVar[code]]'),
        throwsFormatException,
      );
      expect(
        () => migrateLegacyUserVariableScript(r'$setUserVar[x;1'),
        throwsFormatException,
      );
    },
  );

  test(
    'configuration transformation never changes variables, metadata or JavaScript',
    () {
      final document = {
        'description': r'$getUserVar[notCode]',
        'scopedVariables': {
          'user': {
            user: {'coins': 42, 'text': r'$getUserVar[literal]'},
          },
        },
        'commands': [
          {
            'data': {'bdfdScriptContent': r'$getUserVar[coins]'},
          },
          {
            'data': {
              'executionMode': 'javascript',
              'scriptContent': r'$getUserVar[js]',
            },
          },
        ],
        'workflows': [
          {
            'actions': [
              {
                'type': 'runBdfdScript',
                'payload': {'scriptContent': r'$setUserVar[coins;2]'},
              },
            ],
          },
        ],
      };
      final before = jsonEncode(document);
      final result = migrateLegacyUserVariableDocument(document);
      expect(jsonEncode(document), before);
      expect(result.changes, 2);
      expect(result.document['scopedVariables'], document['scopedVariables']);
      expect(result.document['description'], document['description']);
      expect(result.document['commands'][1], (document['commands'] as List)[1]);
    },
  );

  test(
    'migration preserves legacy execution and reset without moving data',
    () async {
      const source =
          r'$resetUserVar[coins]$setUserVar[coins;$sum[$getUserVar[coins];1]]'
          r'$getUserVar[coins]|$getUserVar[coins;20;11]';
      final migrated = migrateLegacyUserVariableScript(source);
      final fixture = {
        'definitions': [
          {'scope': 'user', 'key': 'coins', 'defaultValue': 5},
        ],
        'scoped': {
          'user': {
            '20': {'coins': 42},
          },
          'guildMember': {
            '11:20': {'coins': 99},
          },
        },
      };
      final legacy = await testCommandInSandbox({
        ...fixture,
        'script': source,
        'bdfdUserVariableSemantics': 1,
      });
      final official = await testCommandInSandbox({
        ...fixture,
        'script': migrated.source,
        'bdfdUserVariableSemantics': 2,
      });
      expect(legacy['success'], true);
      expect(official['success'], true);
      expect(official['responses'], legacy['responses']);
      expect(official['storage_after'], legacy['storage_after']);
      expect(official['responses'][0]['payload']['content'], '6|99');
      expect(
        migrateLegacyUserVariableScript(r'$resetUserVar[coins;;11]').source,
        r'$resetGuildMemberVar[coins;$authorID;11]',
      );
    },
  );

  test('old and new dialect caches cannot contaminate each other', () {
    const script = r'$setUserVar[coins;1]$getUserVar[coins]';
    final official = BdfdCompiler().compile(script);
    final legacy = BdfdCompiler(legacyUserVariables: true).compile(script);
    expect(official.actions.first.payload['scope'], 'guildMember');
    expect(legacy.actions.first.payload['scope'], 'user');
    expect(
      BdfdCompiler().compile(script).actions.first.payload['scope'],
      'guildMember',
    );
    expect(BotConfig.fromJson({'token': 'x'}).bdfdUserVariableSemantics, 1);
    expect(const BotConfig(token: 'x').bdfdUserVariableSemantics, 2);
    expect(
      BotConfig.fromJson(
        const BotConfig(token: 'x').toJson(),
      ).copyWith(prefix: '?').bdfdUserVariableSemantics,
      2,
    );
  });

  test(
    'official functions isolate guilds while global-user values stay global',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$setUserVar[coins;1]$setUserVar[coins;2;;11]$setVar[coins;9;$authorID]$getUserVar[coins]|$getUserVar[coins;;11]|$getVar[coins;$authorID]',
      });
      expect(result['success'], true);
      expect(result['responses'][0]['payload']['content'], '1|2|9');
      expect(
        result['storage_after']['scoped']['guildMember']['10:20']['coins'],
        '1',
      );
      expect(
        result['storage_after']['scoped']['guildMember']['11:20']['coins'],
        '2',
      );
      expect(result['storage_after']['scoped']['user']['20']['coins'], '9');
    },
  );

  test(
    'resetUserVar resets all members, or just a provided user, without touching globals',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$resetUserVar[coins;21]$var[first;$getUserVar[coins]]$var[second;$getUserVar[coins;21]]$resetUserVar[coins]$var[first]|$var[second]$getUserVar[coins]',
        'definitions': [
          {'scope': 'guildMember', 'key': 'coins', 'defaultValue': 0},
        ],
        'scoped': {
          'guildMember': {
            '10:20': {'coins': 9},
            '10:21': {'coins': 8},
            '11:21': {'coins': 7},
          },
          'user': {
            '20': {'coins': 99},
          },
        },
      });
      expect(result['success'], true);
      expect(result['responses'][0]['payload']['content'], '9|00');
      expect(
        result['storage_after']['scoped']['guildMember']['11:21']['coins'],
        0,
      );
      expect(result['storage_after']['scoped']['user']['20']['coins'], 99);
    },
  );
  test(
    'resetUserVar includes every indexed page before modifying values',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$resetUserVar[coins]',
        'definitions': [
          {'scope': 'guildMember', 'key': 'coins', 'defaultValue': 0},
        ],
        'scoped': {
          'guildMember': {
            for (var i = 1; i <= 205; i++) '10:$i': {'coins': i},
          },
        },
      });
      expect(result['success'], true);
      final contexts = result['storage_after']['scoped']['guildMember'] as Map;
      expect(contexts, hasLength(205));
      expect(contexts.values.every((values) => values['coins'] == 0), true);
    },
  );
}
