import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/hash_util.dart';
import 'package:bot_creator/features/copilot/logic/copilot_library.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const botId = '1350824555119382678';

Map<String, dynamic> entry({
  String mode = 'bdfd_script',
  String script = r'$setUserVar[coins;7]$getUserVar[coins] role {{id_1}}',
  List actions = const [],
  List options = const [],
}) => {
  'id': 'entry-1',
  'name': 'coins',
  'description': 'Give coins',
  'mode': mode,
  'script': script,
  'actions': actions,
  'options': options,
  'placeholders': ['{{id_1}}'],
};

void main() {
  group('deriveLibraryCommandArgs', () {
    test('fills placeholders and applies replacements, template first', () {
      final args = deriveLibraryCommandArgs(
        entry(),
        botId: botId,
        name: 'wallet',
        values: {'{{id_1}}': '223456789012345678'},
        replacements: [
          {'find': 'coins;7', 'replace': 'coins;10'},
        ],
      );
      expect(
        args['script'],
        r'$setUserVar[coins;10]$getUserVar[coins] role 223456789012345678',
      );
      expect(args['description'], 'Give coins');
      expect(args['name'], 'wallet');
      expect(args['execution_mode'], 'bdfd_script');
      expect(args.containsKey('actions_json'), isFalse);
    });

    test(
      'values may be keyed with or without braces and also fill options',
      () {
        final args = deriveLibraryCommandArgs(
          entry(
            options: [
              {
                'name': 'who',
                'type': 'string',
                'choices': [
                  {'name': 'mod', 'value': '{{id_1}}'},
                ],
              },
            ],
          ),
          botId: botId,
          name: 'wallet',
          description: 'Custom',
          values: {'id_1': '223456789012345678'},
        );
        expect(args['description'], 'Custom');
        expect(
          (args['options'] as List).single['choices'].single['value'],
          '223456789012345678',
        );
      },
    );

    test(
      'a replacement can introduce a placeholder; replacement text is literal',
      () {
        final args = deriveLibraryCommandArgs(
          entry(),
          botId: botId,
          name: 'wallet',
          values: {
            '{{id_1}}': '223456789012345678',
            '{{id_2}}': '323456789012345678',
          },
          replacements: [
            {'find': 'coins;7', 'replace': r'$1;{{id_2}}'},
          ],
        );
        expect(args['script'], contains(r'$setUserVar[$1;323456789012345678]'));
      },
    );

    test('refuses missing or invalid values and unknown replacements', () {
      expect(
        () => deriveLibraryCommandArgs(entry(), botId: botId, name: 'x'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('{{id_1}}'),
          ),
        ),
      );
      expect(
        () => deriveLibraryCommandArgs(
          entry(),
          botId: botId,
          name: 'x',
          values: {'{{id_1}}': 'not-an-id'},
        ),
        throwsFormatException,
      );
      expect(
        () => deriveLibraryCommandArgs(
          entry(),
          botId: botId,
          name: 'x',
          values: {'{{id_1}}': '223456789012345678'},
          replacements: [
            {'find': 'absent', 'replace': 'x'},
          ],
        ),
        throwsFormatException,
      );
      expect(
        () => deriveLibraryCommandArgs(
          entry(mode: 'python'),
          botId: botId,
          name: 'x',
        ),
        throwsFormatException,
      );
    });

    test('workflow entries are returned as actions_json', () {
      final args = deriveLibraryCommandArgs(
        entry(
          mode: 'workflow',
          script: '',
          actions: [
            {
              'type': 'respond',
              'payload': {'content': 'pong {{id_1}}'},
            },
          ],
        ),
        botId: botId,
        name: 'ping',
        values: {'{{id_1}}': '223456789012345678'},
      );
      expect(args.containsKey('script'), isFalse);
      expect(
        jsonDecode(args['actions_json'] as String).single['payload']['content'],
        'pong 223456789012345678',
      );
    });
  });

  group('patchCopilotScript', () {
    const script = r'$title[Ping]$description[Pong $ping ms]$color[#5865F2]';
    test('applies unique edits in order, inserting text literally', () {
      expect(
        patchCopilotScript(script, [
          {'find': r'Pong $ping ms', 'replace': r'Latency: $ping ms ($1)'},
          {'find': '#5865F2', 'replace': '#FF0000'},
        ]),
        r'$title[Ping]$description[Latency: $ping ms ($1)]$color[#FF0000]',
      );
    });

    test('refuses an edit that is absent, ambiguous or a no-op', () {
      expect(
        () => patchCopilotScript(script, [
          {'find': 'missing', 'replace': 'x'},
        ]),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'm',
            contains('not found'),
          ),
        ),
      );
      expect(
        () => patchCopilotScript(r'$a[x]$b[x]', [
          {'find': 'x', 'replace': 'y'},
        ]),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'm',
            contains('2 times'),
          ),
        ),
      );
      expect(
        () => patchCopilotScript(script, [
          {'find': 'Ping', 'replace': 'Ping'},
        ]),
        throwsFormatException,
      );
    });

    test('nothing is applied when a later edit fails', () {
      // The function is pure: the original string is never mutated, the caller gets an exception.
      final original = script;
      expect(
        () => patchCopilotScript(original, [
          {'find': 'Ping', 'replace': 'Pang'},
          {'find': 'missing', 'replace': 'x'},
        ]),
        throwsFormatException,
      );
      expect(original, script);
    });
  });

  test('copilotCommandScript reads the mode and source, per route', () {
    final command = {
      'data': {
        'executionMode': 'bdfd_script',
        'bdfdScriptContent': 'top',
        'subcommandWorkflows': {
          'a': {'executionMode': 'javascript', 'jsScriptContent': 'js body'},
        },
      },
    };
    expect(copilotCommandScript(command).script, 'top');
    final route = copilotCommandScript(command, route: 'a');
    expect((route.mode, route.script), ('javascript', 'js body'));
    expect(
      () => copilotCommandScript(command, route: 'missing'),
      throwsStateError,
    );
  });

  group('library tools through the MCP bridge', () {
    late Directory storage;
    late CopilotMcp bridge;
    late _Api api;
    final discord = _Discord();
    var calls = 0;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      SharedPreferences.setMockInitialValues({});
      storage = await Directory.systemTemp.createTemp('copilot_library_');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (_) async => storage.path,
          );
      await AppManager().createOrUpdateApp(
        id: Snowflake.parse(botId),
        username: 'TestBot',
        token: 'fake-token',
        intents: {},
        prefix: '!',
      );
      api = _Api();
      bridge = CopilotMcp(
        api,
        botId: botId,
        approve: (_, _) async => true,
        discordConnect: (_) async => discord,
      );
      await bridge.initialize();
    });
    tearDownAll(() async => bridge.close());

    Future<Map> call(String tool, Map<String, dynamic> args) async {
      // library_search and library_get are not bot-scoped: their schema has no bot_id.
      final scoped = !tool.startsWith('library_');
      final result = await bridge.call(tool, {
        if (scoped) 'bot_id': botId,
        ...args,
      }, callID: 'library-${++calls}');
      return jsonDecode((result['content'] as List).single['text'] as String)
          as Map;
    }

    test('search and get are marked as untrusted reference data', () async {
      api.entries['entry-1'] = entry();
      final found = await call('library_search', {'query': 'coins'});
      expect(found['untrusted_reference_data'], true);
      expect((found['results'] as List).single['id'], 'entry-1');
      final got = await call('library_get', {'id': 'entry-1'});
      expect(got['untrusted_reference_data'], true);
      expect(got['entry']['script'], contains('{{id_1}}'));
    });

    test(
      'creating from an entry sends only the differences and registers the derived command',
      () async {
        api.entries['entry-1'] = entry();
        final created = await call('local_create_command_from_library', {
          'library_id': 'entry-1',
          'name': 'wallet',
          'values': {'{{id_1}}': '223456789012345678'},
          'replacements': [
            {'find': 'coins;7', 'replace': 'coins;10'},
          ],
        });
        expect(created['created'], true);
        expect(created['derived_from_library'], 'entry-1');
        expect(discord.commands.created.single.name, 'wallet');
        final saved = await AppManager().getAppCommand(
          botId,
          created['command_id'] as String,
        );
        expect(
          saved['data']['bdfdScriptContent'],
          r'$setUserVar[coins;10]$getUserVar[coins] role 223456789012345678',
        );
        await Future<void>.delayed(Duration.zero);
        expect(api.used, [
          'entry-1',
        ], reason: 'the use is recorded as a ranking signal');
      },
    );

    test(
      'a derivation with a missing ID fails before anything reaches Discord',
      () async {
        api.entries['entry-1'] = entry();
        final before = discord.commands.created.length;
        await expectLater(
          call('local_create_command_from_library', {
            'library_id': 'entry-1',
            'name': 'broken',
          }),
          throwsFormatException,
        );
        expect(discord.commands.created.length, before);
      },
    );

    test(
      'patching rewrites only what changed, keeps the revision rule and rejects workflows',
      () async {
        const id = 'patch-target';
        await AppManager().saveAppCommand(botId, id, {
          'id': id,
          'name': 'patch',
          'description': 'd',
          'data': {
            'executionMode': 'bdfd_script',
            'bdfdScriptContent': r'$setUserVar[coins;7]$getUserVar[coins]',
            'actions': [],
          },
        });
        final current = await AppManager().getAppCommand(botId, id);
        final revision = HashUtil.calculateHash(current);

        await expectLater(
          call('local_patch_command_execution', {
            'command_id': id,
            'expected_revision': 'stale',
            'edits': [
              {'find': 'coins;7', 'replace': 'coins;9'},
            ],
          }),
          throwsStateError,
        );
        await expectLater(
          call('local_patch_command_execution', {
            'command_id': id,
            'expected_revision': revision,
            'edits': [
              {'find': 'absent', 'replace': 'x'},
            ],
          }),
          throwsFormatException,
        );
        expect(
          (await AppManager().getAppCommand(
            botId,
            id,
          ))['data']['bdfdScriptContent'],
          r'$setUserVar[coins;7]$getUserVar[coins]',
          reason: 'a refused patch must write nothing',
        );

        final patched = await call('local_patch_command_execution', {
          'command_id': id,
          'expected_revision': revision,
          'edits': [
            {'find': 'coins;7', 'replace': 'coins;9'},
          ],
        });
        expect(patched['saved'], true);
        final after = await AppManager().getAppCommand(botId, id);
        expect(
          after['data']['bdfdScriptContent'],
          r'$setUserVar[coins;9]$getUserVar[coins]',
        );
        expect(patched['revision'], HashUtil.calculateHash(after));

        await AppManager().saveAppCommand(botId, 'wf', {
          'id': 'wf',
          'name': 'wf',
          'description': 'd',
          'data': {
            'executionMode': 'workflow',
            'actions': [
              {
                'type': 'respond',
                'payload': {'content': 'x'},
              },
            ],
          },
        });
        await expectLater(
          call('local_patch_command_execution', {
            'command_id': 'wf',
            'expected_revision': HashUtil.calculateHash(
              await AppManager().getAppCommand(botId, 'wf'),
            ),
            'edits': [
              {'find': 'x', 'replace': 'y'},
            ],
          }),
          throwsStateError,
        );
      },
    );
  });
}

class _Api extends MainApiClient {
  _Api() : super(baseUrl: 'https://manager.example', accessToken: 'test');
  final entries = <String, Map<String, dynamic>>{};
  final used = <String>[];
  @override
  Future<Map<String, dynamic>> searchAILibrary(
    String query, {
    String? mode,
    int? limit,
  }) async => {
    'results': [
      for (final e in entries.values) {'id': e['id'], 'name': e['name']},
    ],
  };
  @override
  Future<Map<String, dynamic>> getAILibraryEntry(String id) async =>
      entries[id]!;
  @override
  Future<Map<String, dynamic>> markAILibraryUsed(String id) async {
    used.add(id);
    return {'ok': true};
  }

  @override
  Future<bool> syncCommandWithStatus(
    String id,
    String name,
    String command,
    Map<String, dynamic> payload,
  ) async => true;
}

class _User implements User {
  @override
  Snowflake get id => Snowflake.parse(botId);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Command implements ApplicationCommand {
  _Command(this.name, this.description, this.type, this.id);
  @override
  final String name;
  @override
  final String description;
  @override
  final ApplicationCommandType type;
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Commands implements GlobalApplicationCommandManager {
  final created = <_Command>[];
  @override
  Future<List<ApplicationCommand>> list({bool? withLocalizations}) async => [];
  @override
  Future<ApplicationCommand> create(ApplicationCommandBuilder builder) async {
    final command = _Command(
      builder.name,
      builder.description ?? '',
      builder.type,
      Snowflake(1450824555119382678 + created.length),
    );
    created.add(command);
    return command;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Discord implements NyxxRest {
  @override
  final _Commands commands = _Commands();
  @override
  PartialUser get user => _User();
  @override
  Future<void> close() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
