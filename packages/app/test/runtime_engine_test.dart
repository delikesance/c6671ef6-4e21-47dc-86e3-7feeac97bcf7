import 'dart:io';

import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
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
  const botId = 'runtime-engine-test-bot';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp('runtime_engine_test');
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
    final app = <String, dynamic>{
      'id': botId,
      'username': 'TestBot',
      'token': 'test-token',
      'runtimeEngine': runtimeEngineDart,
      'scheduledTriggers': <Map<String, dynamic>>[
        <String, dynamic>{
          'workflowName': 'wf1',
          'everyMinutes': 5,
          'enabled': true,
        },
      ],
      'inboundWebhooks': <Map<String, dynamic>>[
        <String, dynamic>{'name': 'hook1'},
      ],
      'globalVariables': <String, dynamic>{'foo': 'bar'},
      'workflows': <Map<String, dynamic>>[],
    };
    await appManager.saveApp(botId, app);

    await appManager.saveAppCommand(botId, 'cmd-1', <String, dynamic>{
      'id': 'cmd-1',
      'name': 'ping',
      'description': 'Ping',
      'type': 'chatInput',
      'data': <String, dynamic>{},
    });

    await appManager.saveWorkflow(
      botId,
      name: 'wf1',
      actions: <Map<String, dynamic>>[
        <String, dynamic>{'type': 'sendMessage', 'content': 'hi'},
      ],
    );
  });

  test('clearBotAutomationData removes commands workflows and automation metadata', () async {
    await clearBotAutomationData(botId);

    final commands = await appManager.listAppCommands(botId);
    expect(commands, isEmpty);

    final workflows = await appManager.getWorkflows(botId);
    expect(workflows, isEmpty);

    final app = await appManager.getApp(botId);
    expect(app['scheduledTriggers'], isEmpty);
    expect(app['inboundWebhooks'], isEmpty);
    expect(app['inboundWebhookEndpoints'], isEmpty);
    expect(app['globalVariables'], isEmpty);

    final commandFile = File('${await appManager.path}/apps/$botId/cmd-1.json');
    expect(await commandFile.exists(), isFalse);
  });

  test('deleteAllDiscordApplicationCommands no-ops without token', () async {
    const noTokenBotId = 'runtime-engine-no-token-bot';
    await appManager.saveApp(noTokenBotId, <String, dynamic>{
      'id': noTokenBotId,
      'username': 'TestBot',
      'token': '',
    });

    expect(await deleteAllDiscordApplicationCommands(noTokenBotId), 0);
  });

  test('switchBotRuntimeEngine updates engine after clearing automation data', () async {
    await switchBotRuntimeEngine(
      botId,
      runtimeEngineJavascript,
      supportsManagerRuntime: false,
    );

    expect(await getBotRuntimeEngine(botId), runtimeEngineJavascript);
    expect(await appManager.listAppCommands(botId), isEmpty);
    expect(await appManager.getWorkflows(botId), isEmpty);

    final app = await appManager.getApp(botId);
    expect(app['scheduledTriggers'], isEmpty);
    expect(app['globalVariables'], isEmpty);
  });
}
