import 'dart:convert';
import 'dart:io';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/copilot/logic/copilot_mcp.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nyxx/nyxx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const botId = '1350824555119382678';

class _CloudApi extends MainApiClient {
  _CloudApi() : super(baseUrl: 'https://manager.example', accessToken: 'test');
  bool synced = true;
  final workflows = <Map<String, dynamic>>[];
  final commands = <Map<String, dynamic>>[];
  @override
  Future<bool> syncCommandWithStatus(
    String id,
    String name,
    String command,
    Map<String, dynamic> payload,
  ) async {
    commands.add(payload);
    return synced;
  }

  @override
  Future<bool> syncWorkflowWithStatus(
    String id,
    String name,
    String workflow,
    Map<String, dynamic> payload,
  ) async {
    workflows.add(payload);
    return synced;
  }

  @override
  Future<bool> setVariableWithStatus(
    String id,
    Map<String, dynamic> args,
  ) async => synced;
  @override
  Future<bool> syncBotConfigurationWithStatus(
    String id,
    String name,
    Map<String, dynamic> config,
  ) async => synced;
  @override
  Future<RunnerStatus> getStatus({String? botId}) async => RunnerStatus(
    running: true,
    bots: [RunnerBotRuntime(botId: botId!, botName: 'Bot', state: 'running')],
  );
}

class _DiscordUser implements User {
  _DiscordUser(this.username);
  @override
  final String username;
  @override
  Snowflake get id => Snowflake.parse(botId);
  @override
  String? get avatarHash => null;
  @override
  String get discriminator => '0';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DiscordCommand implements ApplicationCommand {
  @override
  Snowflake get id => Snowflake.parse('1450824555119382678');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DiscordCommands implements GlobalApplicationCommandManager {
  final requests = <Map<String, dynamic>>[];
  final ids = <Snowflake>[];
  @override
  Future<ApplicationCommand> update(
    Snowflake id,
    ApplicationCommandUpdateBuilder builder,
  ) async {
    ids.add(id);
    requests.add(builder.build());
    return _DiscordCommand();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DiscordUsers implements UserManager {
  final names = <String>[];
  @override
  Future<User> updateCurrentUser(UserUpdateBuilder builder) async {
    final name = builder.build()['username'] as String;
    names.add(name);
    return _DiscordUser(name);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Discord implements NyxxRest {
  @override
  final _DiscordCommands commands = _DiscordCommands();
  @override
  final _DiscordUsers users = _DiscordUsers();
  @override
  PartialUser get user => _DiscordUser('TestBot');
  @override
  Future<void> close() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;
  late CopilotMcp bridge;
  late _CloudApi api;
  final discord = _Discord();
  var calls = 0;
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    storage = await Directory.systemTemp.createTemp('copilot_storage_');
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
    api = _CloudApi();
    bridge = CopilotMcp(
      api,
      botId: botId,
      approve: (_, _) async => true,
      discordConnect: (_) async => discord,
    );
    await bridge.initialize();
  });
  tearDownAll(() async {
    await bridge.close();
  });
  Future<Map> call(String tool, Map<String, dynamic> args) async {
    final result = await bridge.call(tool, {
      'bot_id': botId,
      ...args,
    }, callID: 'test-${++calls}');
    return jsonDecode((result['content'] as List).single['text'] as String)
        as Map;
  }

  test(
    'argument edits patch the same Discord ID and retain saved BDFD execution',
    () async {
      api.synced = true;
      await AppManager().saveAppCommand(botId, 'hello', {
        'id': 'hello',
        'discordId': '1450824555119382678',
        'name': 'hello',
        'description': 'Hello',
        'data': {
          'executionMode': 'bdfd_script',
          'bdfdScriptContent': 'Hello',
          'actions': [],
          'defaultMemberPermissions': '8',
        },
      });
      final before = await call('local_get_command', {'command_id': 'hello'});
      final result = await call('local_update_command_options', {
        'command_id': 'hello',
        'expected_revision': before['revision'],
        'operation': 'add',
        'option_name': 'member',
        'option': {
          'type': 'user',
          'name': 'member',
          'description': 'Member',
          'required': true,
        },
      });
      expect(result['discord_updated'], true);
      expect(result['runner_synced'], true);
      expect(discord.commands.ids.last.toString(), '1450824555119382678');
      expect(discord.commands.requests.last.keys, ['options']);
      expect(
        discord.commands.requests.last['options'].single['name'],
        'member',
      );
      final stored = await AppManager().getAppCommand(botId, 'hello');
      expect(stored['data']['bdfdScriptContent'], 'Hello');
      expect(stored['data']['actions'], isEmpty);
      expect(stored['data']['defaultMemberPermissions'], '8');
      expect(api.commands.last['data']['options'].single['name'], 'member');
      await expectLater(
        call('local_update_command_options', {
          'command_id': 'hello',
          'expected_revision': before['revision'],
          'operation': 'remove',
          'option_name': 'member',
        }),
        throwsStateError,
      );
      expect(discord.commands.requests.length, 1);
    },
  );
  test(
    'profile edits use Discord current user and preserve other configuration',
    () async {
      final config = await call('local_get_bot_configuration', {});
      final before = await AppManager().getApp(botId);
      final result = await call('local_update_bot_profile', {
        'username': 'RenamedBot',
        'expected_revision': config['revisions']['profile'],
      });
      expect(discord.users.names.single, 'RenamedBot');
      expect(result['discord_updated'], true);
      final stored = await AppManager().getApp(botId);
      expect(stored['name'], 'RenamedBot');
      expect(stored['prefix'], before['prefix']);
      expect(stored['token'], before['token']);
      final reread = await call('local_get_bot_configuration', {});
      expect(reread['revisions']['profile'], result['revision']);
    },
  );

  test(
    'command settings survive Discord patch and normalized storage',
    () async {
      final before = await call('local_get_command', {'command_id': 'hello'});
      final result = await call('local_update_command_settings', {
        'command_id': 'hello',
        'expected_revision': before['revision'],
        'description': 'New description',
        'default_member_permissions': '16',
        'contexts': [0],
        'integration_types': [0],
      });
      expect(result['discord_updated'], true);
      final request = discord.commands.requests.last;
      expect(request['description'], 'New description');
      expect(request['default_member_permissions'], '16');
      expect(request['contexts'], [0]);
      expect(request['integration_types'], [0]);
      final stored = await AppManager().getAppCommand(botId, 'hello');
      expect(stored['description'], 'New description');
      expect(stored['data']['defaultMemberPermissions'], '16');
      expect(stored['data']['contexts'], [0]);
      expect(stored['data']['integrationTypes'], [0]);
      expect(stored['data']['bdfdScriptContent'], 'Hello');
    },
  );

  test(
    'unchanged command settings preserve storage and never contact Discord',
    () async {
      const commandId = 'noop-ping';
      await AppManager().saveAppCommand(botId, commandId, {
        'id': commandId,
        'discordId': '1450824555119382678',
        'name': 'ping',
        'description': 'ping',
        'data': {
          'executionMode': 'bdfd_script',
          'bdfdScriptContent': 'Pong!',
          'actions': [],
          'defaultMemberPermissions': '8',
          'contexts': [0],
          'integrationTypes': [0],
        },
      });
      final before = await call('local_get_command', {'command_id': commandId});
      final file = File('${storage.path}/apps/$botId/$commandId.json');
      final source = await file.readAsString();
      await file.setLastModified(DateTime.utc(2025, 1, 1));
      final modified = (await file.stat()).modified;
      final cloudCalls = api.commands.length;
      var connections = 0;
      final noopBridge = CopilotMcp(
        api,
        botId: botId,
        approve: (_, _) async => true,
        discordConnect: (_) async {
          connections++;
          throw StateError('No-op must not connect to Discord');
        },
      );
      await noopBridge.initialize();
      addTearDown(noopBridge.close);
      final args = <String, dynamic>{
        'bot_id': botId,
        'command_id': commandId,
        'expected_revision': before['revision'],
        'description': 'ping',
        'default_member_permissions': '8',
        'contexts': [0],
        'integration_types': [0],
      };
      final envelope = await noopBridge.call('local_update_command_settings', {
        'bot_id': botId,
        'command_id': commandId,
        'expected_revision': before['revision'],
        'description': 'ping',
      }, callID: 'noop-description');
      expect(
        await noopBridge.call(
          'local_update_command_settings',
          args,
          callID: 'noop-settings',
        ),
        envelope,
      );
      expect(envelope['isError'], isNot(true));
      final result =
          jsonDecode((envelope['content'] as List).single['text'] as String)
              as Map;
      expect(result['unchanged'], true);
      expect(result['saved'], false);
      expect(result['discord_updated'], false);
      expect(result.containsKey('runner_synced'), false);
      expect(result['revision'], before['revision']);
      expect(result['before'], before['command']);
      expect(result['after'], result['before']);
      expect(
        await noopBridge.call(
          'local_update_command_settings',
          args,
          callID: 'noop-settings',
        ),
        envelope,
      );
      await expectLater(
        noopBridge.call('local_update_command_settings', {
          ...args,
          'expected_revision': 'stale-revision',
        }, callID: 'noop-stale'),
        throwsStateError,
      );
      expect(connections, 0);
      expect(api.commands.length, cloudCalls);
      expect(await file.readAsString(), source);
      expect((await file.stat()).modified, modified);
    },
  );

  test(
    'create edit and reload a real workflow with revisions and cloud payload',
    () async {
      final created = await call('local_create_workflow', {
        'name': 'welcome',
        'execution_mode': 'workflow',
        'actions': [
          {
            'type': 'respondWithMessage',
            'payload': {'content': 'Hello'},
          },
        ],
      });
      expect(created['saved'], true);
      expect(created['runner_synced'], true);
      final read = await call('local_get_workflow', {'name': 'welcome'});
      expect(read['workflow']['actions'].single['payload']['content'], 'Hello');
      await call('local_update_workflow', {
        'name': 'welcome',
        'expected_revision': read['revision'],
        'actions': [
          {
            'type': 'respondWithMessage',
            'payload': {'content': 'Updated'},
          },
        ],
      });
      final reloaded = await AppManager().getWorkflowByName(botId, 'welcome');
      expect(reloaded!['actions'].single['payload']['content'], 'Updated');
      expect(
        api.workflows.last['actions'].single['payload']['content'],
        'Updated',
      );
      await expectLater(
        call('local_update_workflow', {
          'name': 'welcome',
          'expected_revision': read['revision'],
          'actions': [
            {
              'type': 'respondWithMessage',
              'payload': {'content': 'Stale'},
            },
          ],
        }),
        throwsStateError,
      );
      expect(
        (await AppManager().getWorkflowByName(
          botId,
          'welcome',
        ))!['actions'].single['payload']['content'],
        'Updated',
      );
    },
  );
  test(
    'variable tool persists scoped defaults and reports a pending cloud update',
    () async {
      final config = await call('local_get_bot_configuration', {});
      api.synced = false;
      final result = await call('local_set_variable', {
        'key': 'greeting',
        'scope': 'guild',
        'value': 'Hello',
        'expected_revision': config['revisions']['variables'],
      });
      expect(result['saved'], true);
      expect(result['runner_synced'], false);
      final definitions = await AppManager().getScopedVariableDefinitions(
        botId,
      );
      expect(definitions.single['defaultValue'], 'Hello');
      final reread = await call('local_get_bot_configuration', {});
      expect(reread['revisions']['variables'], result['revision']);
    },
  );

  test('presence persists with revision and cloud confirmation', () async {
    api.synced = true;
    final before = await call('local_get_bot_presence', {});
    final result = await call('local_update_bot_presence', {
      'expected_revision': before['revision'],
      'status': 'idle',
      'activities': [
        {
          'type': 'watching',
          'name': 'the server',
          'minIntervalSeconds': 30,
          'maxIntervalSeconds': 60,
        },
      ],
    });
    expect(result['runner_synced'], true);
    final reread = await call('local_get_bot_presence', {});
    expect(reread['presence']['presenceStatus'], 'idle');
    expect(reread['presence']['activities'].single['name'], 'the server');
    expect(reread['revision'], result['revision']);
  });

  test(
    'JS command sync sends the runtime handler and metadata for restoration',
    () async {
      final app = await AppManager().getApp(botId);
      final previousEngine = app['runtimeEngine'];
      app['runtimeEngine'] = 'javascript';
      await AppManager().saveApp(botId, app);
      try {
        await AppManager().saveAppCommand(botId, 'js-test', {
          'id': 'js-test',
          'name': 'js-test',
          'data': {
            'executionMode': 'javascript',
            'jsScriptContent': 'return 1;',
            'defaultMemberPermissions': '8',
            'contexts': [0],
          },
        });
        expect(await bridge.syncCloudCommand(botId, 'js-test'), true);
        expect(api.commands.last['script'], 'return 1;');
        expect(api.commands.last['defaultMemberPermissions'], '8');
        expect(api.commands.last['contexts'], [0]);
        expect(api.commands.last['data']['jsScriptContent'], 'return 1;');
        expect(api.commands.last['data']['executionMode'], 'javascript');
        final standalone = await call('local_create_workflow', {
          'name': 'js-template',
          'execution_mode': 'javascript',
          'script': 'return 1;',
        });
        expect(standalone['saved'], true);
        expect(standalone['activation_requires_trigger'], true);
        expect(standalone['runner_synced'], false);
      } finally {
        app['runtimeEngine'] = previousEngine;
        await AppManager().saveApp(botId, app);
      }
    },
  );

  test(
    'schedule and webhook tools persist references and keep credentials out of results',
    () async {
      final premiumBefore = PremiumCapabilities.debugPremiumBypass;
      PremiumCapabilities.debugPremiumBypass = true;
      try {
        var config = await call('local_get_bot_configuration', {});
        final scheduled = await call('local_update_scheduled_trigger', {
          'expected_revision': config['revisions']['scheduled_triggers'],
          'workflow_name': 'welcome',
          'every_minutes': 10,
          'enabled': true,
        });
        expect(scheduled['saved'], true);
        expect(
          (await AppManager().getScheduledTriggers(
            botId,
          )).single['workflowName'],
          'welcome',
        );
        config = await call('local_get_bot_configuration', {});
        final webhook = await call('local_update_inbound_webhook', {
          'expected_revision': config['revisions']['inbound_webhooks'],
          'workflow_name': 'welcome',
          'path': 'welcome',
          'enabled': true,
        });
        expect(webhook['saved'], true);
        final stored = (await AppManager().getInboundWebhooks(botId)).single;
        final secret = stored['secret'] as String;
        expect(secret.length, greaterThan(30));
        expect(jsonEncode(webhook), isNot(contains(secret)));
        config = await call('local_get_bot_configuration', {});
        expect(jsonEncode(config), isNot(contains(secret)));
        await call('local_update_inbound_webhook', {
          'expected_revision': config['revisions']['inbound_webhooks'],
          'webhook_id': stored['id'],
          'workflow_name': 'welcome',
          'path': 'welcome-updated',
          'enabled': false,
        });
        final changed = (await AppManager().getInboundWebhooks(botId)).single;
        expect(changed['secret'], secret);
        expect(changed['enabled'], false);
      } finally {
        PremiumCapabilities.debugPremiumBypass = premiumBefore;
      }
    },
  );
}
