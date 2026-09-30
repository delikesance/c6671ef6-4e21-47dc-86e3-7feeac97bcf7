import 'dart:io';

import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:bot_creator/features/bot_editor/logic/workflow_call.dart';
import 'package:bot_creator/main.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  const botId = 'js-payload-test-bot';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp('js_payload_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() async {
    await appManager.deleteAppCommands(botId);
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'username': 'JsBot',
      'token': 'test-token',
      'runtimeEngine': runtimeEngineJavascript,
      'prefix': '!',
      'workflows': <Map<String, dynamic>>[],
    });
  });

  test(
    'links scheduled and webhook handlers to the saved workflow source',
    () async {
      await appManager.saveWorkflow(
        botId,
        name: 'shared',
        actions: [],
        executionMode: workflowExecutionModeJavascript,
        jsScriptContent: 'console.log("linked");',
      );
      final app = await appManager.getApp(botId);
      app['scheduledTriggers'] = [
        {
          'id': 'scheduled',
          'workflowName': 'shared',
          'everyMinutes': 5,
          'enabled': true,
        },
      ];
      app['inboundWebhooks'] = [
        {
          'id': 'webhook',
          'workflowName': 'shared',
          'path': 'welcome',
          'secret': 'test-secret',
          'enabled': true,
        },
      ];
      await appManager.saveApp(botId, app);
      final payload = await buildJsBotPayload(botId);
      expect(
        (payload['scheduled'] as List).single['script'],
        'console.log("linked");',
      );
      expect(
        (payload['inboundWebhooks'] as List).single['script'],
        'console.log("linked");',
      );
      expect((payload['inboundWebhooks'] as List).single['path'], 'welcome');
    },
  );

  test(
    'retains command permissions and installation contexts in JS payload',
    () async {
      await appManager.saveAppCommand(botId, 'restricted', {
        'id': 'restricted',
        'name': 'restricted',
        'data': {
          'executionMode': 'javascript',
          'jsScriptContent': 'return;',
          'defaultMemberPermissions': '8',
          'contexts': [0],
          'integrationTypes': [0],
        },
      });
      final payload = await buildJsBotPayload(botId);
      final command = (payload['commands'] as List).single;
      expect(command['defaultMemberPermissions'], '8');
      expect(command['contexts'], [0]);
      expect(command['integrationTypes'], [0]);
    },
  );

  for (final enabled in [false, true]) {
    test(
      'legacy webhook flag $enabled preserves endpoint source and local data',
      () async {
        await appManager.saveAppCommand(botId, 'ping', {
          'id': 'ping',
          'name': 'ping',
          'data': {
            'executionMode': 'javascript',
            'jsScriptContent': 'await interaction.reply("pong");',
          },
        });
        final app = await appManager.getApp(botId);
        app['inboundWebhooks'] = enabled;
        app['inboundWebhookEndpoints'] = [
          {
            'id': 'welcome-hook',
            'path': 'welcome',
            'secret': 'test-secret',
            'script': 'console.log("welcome");',
          },
          false,
        ];
        app['globalVariables'] = {'keep': 'unchanged'};
        await appManager.saveApp(botId, app);
        final before = await appManager.getApp(botId);
        final commandsBefore = await appManager.listAppCommands(botId);

        final payload = await buildJsBotPayload(botId);

        final endpoints = payload['inboundWebhooks'] as List;
        expect(endpoints, hasLength(1));
        expect(endpoints.single['id'], 'welcome-hook');
        expect(endpoints.single['path'], 'welcome');
        expect(endpoints.single['script'], 'console.log("welcome");');
        expect(payload['commands'], hasLength(1));
        expect(payload['globalVariables'], {'keep': 'unchanged'});
        expect(await appManager.getApp(botId), before);
        expect(await appManager.listAppCommands(botId), commandsBefore);
      },
    );

    test('non-list webhook fields $enabled produce no endpoints', () async {
      await appManager.saveAppCommand(botId, 'ping', {
        'id': 'ping',
        'name': 'ping',
        'data': {
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("pong");',
        },
      });
      final app = await appManager.getApp(botId);
      app['inboundWebhooks'] = enabled;
      app['inboundWebhookEndpoints'] = enabled;
      await appManager.saveApp(botId, app);

      final payload = await buildJsBotPayload(botId);

      expect(payload['inboundWebhooks'], isEmpty);
      expect(payload['commands'], hasLength(1));
    });
  }

  test('includes javascript event workflows in payload events array', () async {
    await appManager.saveWorkflow(
      botId,
      name: 'on-message',
      actions: const <Map<String, dynamic>>[],
      workflowType: workflowTypeEvent,
      eventTrigger: <String, dynamic>{'event': 'messageCreate'},
      executionMode: workflowExecutionModeJavascript,
      jsScriptContent: 'await message.reply("hello");',
    );

    final payload = await buildJsBotPayload(botId);

    expect(payload['events'], hasLength(1));
    final event = (payload['events'] as List).first as Map<String, dynamic>;
    expect(event['name'], 'messageCreate');
    expect(event['script'], 'await message.reply("hello");');
    expect(payload.containsKey('prefix'), isFalse);
  });

  test('omits prefix when no legacy commands exist', () async {
    await appManager.saveWorkflow(
      botId,
      name: 'on-message',
      actions: const <Map<String, dynamic>>[],
      workflowType: workflowTypeEvent,
      eventTrigger: <String, dynamic>{'event': 'messageCreate'},
      executionMode: workflowExecutionModeJavascript,
      jsScriptContent: 'console.log(message.content);',
    );

    final payload = await buildJsBotPayload(botId);
    expect(payload.containsKey('prefix'), isFalse);
  });

  test(
    'includes prefix when slash commands exist and prefix is configured',
    () async {
      await appManager.saveAppCommand(botId, 'ping', <String, dynamic>{
        'id': 'ping',
        'name': 'ping',
        'enabled': true,
        'data': <String, dynamic>{
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("pong");',
        },
      });

      final payload = await buildJsBotPayload(botId);
      expect(payload['prefix'], '!');
    },
  );

  test('includes presence status and activities from bot settings', () async {
    await appManager.saveAppCommand(botId, 'ping', {
      'id': 'ping',
      'name': 'ping',
      'data': {'executionMode': 'javascript', 'jsScriptContent': 'return;'},
    });
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'username': 'JsBot',
      'token': 'test-token',
      'runtimeEngine': runtimeEngineJavascript,
      'presenceStatus': 'idle',
      'activities': <Map<String, dynamic>>[
        <String, dynamic>{'type': 'watching', 'name': 'the logs'},
      ],
      'workflows': <Map<String, dynamic>>[],
    });

    final payload = await buildJsBotPayload(botId);
    final presence = payload['presence'] as Map<String, dynamic>;
    expect(presence['status'], 'idle');
    expect(presence['activities'], hasLength(1));
    expect(
      (presence['activities'] as List).first as Map,
      equals(<String, dynamic>{'type': 'watching', 'name': 'the logs'}),
    );
  });

  test('includes command aliases in payload commands', () async {
    await appManager.saveAppCommand(botId, 'help', <String, dynamic>{
      'id': 'help',
      'name': 'help',
      'enabled': true,
      'data': <String, dynamic>{
        'executionMode': 'javascript',
        'jsScriptContent': 'await message.reply("help content");',
        'legacyAliases': ['h', '!aide', r'info{$t:5s}'],
      },
    });

    final payload = await buildJsBotPayload(botId);
    final commands = payload['commands'] as List;
    final helpCmd = commands.firstWhere((c) => c['name'] == 'help') as Map;
    expect(helpCmd['aliases'], containsAll(['h', 'aide', 'info']));
  });
}
