import 'dart:io';
import 'dart:convert';
import 'package:nyxx/nyxx.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
import 'package:bot_creator_shared/utils/command_trigger_type.dart';
import 'package:bot_creator_shared/utils/legacy_command_triggers.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';

import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
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
  const botId = 'restore-types-test-bot';

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
      'prefix': '?',
      'workflows': <Map<String, dynamic>>[],
    });
  });

  test(
    'JS mixed command export/JSON/import/export preserves invocation and source',
    () async {
      for (final mode in [
        'prefix',
        'slash',
        'hybrid',
        'none',
        'user',
        'message',
      ]) {
        await appManager.saveAppCommand(botId, mode, {
          'id': mode,
          'name': mode,
          'folder': 'Examples',
          'discordId': '123',
          'type': mode == 'user' || mode == 'message' ? mode : 'chatInput',
          'data': {
            if (mode == 'hybrid') 'triggerType': 'hybrid',
            'executionMode': 'javascript',
            'jsScriptContent': 'console.log("$mode");\nreturn;',
            'legacyModeEnabled': mode == 'prefix',
            'legacyLocalOnly': mode == 'prefix' || mode == 'none',
            'legacyPrefixOverride': mode == 'prefix' ? 'p' : '',
            'legacyAliases': mode == 'prefix' ? ['alias'] : [],
            'options': mode == 'slash'
                ? [
                    {
                      'name': 'query',
                      'type': 'string',
                      'description': 'Query',
                      'required': true,
                    },
                  ]
                : [],
          },
        });
      }
      final source = await buildJsBotPayload(botId);
      final remote = Map<String, dynamic>.from(
        jsonDecode(jsonEncode(source)) as Map,
      );
      await appManager.deleteAppCommands(botId);
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remote,
      );
      expect((await appManager.getApp(botId))['prefix'], '?');
      for (final kind in [
        'prefix',
        'slash',
        'hybrid',
        'none',
        'user',
        'message',
      ]) {
        final command = normalizeCommandData(
          await appManager.getAppCommand(botId, kind),
        );
        expect(
          commandTriggerType(command),
          ['user', 'message'].contains(kind) ? 'slash' : kind,
        );
        expect(
          command['data']['jsScriptContent'],
          'console.log("$kind");\nreturn;',
        );
        expect(command['folder'], 'Examples');
        final plan = discordCommandPlanFromStoredCommand(command);
        if (kind == 'prefix' || kind == 'none') {
          expect(plan, isNull);
        } else {
          expect(plan, isNotNull);
          expect(
            plan!.type,
            kind == 'user'
                ? ApplicationCommandType.user
                : kind == 'message'
                ? ApplicationCommandType.message
                : ApplicationCommandType.chatInput,
          );
        }
        if (kind == 'prefix') {
          expect(legacyCommandTriggerNames(command), ['p', 'alias']);
        }
        if (kind == 'slash') expect(command['data']['options'], hasLength(1));
      }
      final rebuilt = await buildJsBotPayload(botId);
      final byId = {for (final c in source['commands'] as List) c['id']: c};
      for (final command in rebuilt['commands'] as List) {
        final original = byId[command['id']];
        for (final key in [
          'triggerType',
          'discordType',
          'script',
          'aliases',
          'options',
          'prefixName',
          'folder',
          'discordId',
        ]) {
          expect(command[key], original[key], reason: '${command['id']} $key');
        }
      }
    },
  );

  test(
    'old flat JS preserves flags and ambiguous handlers remain hybrid',
    () async {
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: {
          'commands': [
            {
              'id': 'emptydata',
              'name': 'emptydata',
              'type': 'command',
              'data': {},
              'script': 'return;',
            },
            {
              'id': 'sourcedata',
              'name': 'sourcedata',
              'type': 'command',
              'data': {'jsScriptContent': 'return;'},
              'script': 'return;',
            },
            {
              'id': 'oldslash',
              'name': 'oldslash',
              'type': 'command',
              'legacyModeEnabled': false,
              'script': 'return;',
            },
            {
              'id': 'p',
              'name': 'p',
              'type': 'command',
              'discordType': 'chatInput',
              'legacyModeEnabled': true,
              'legacyPrefixOverride': 'old',
              'aliases': ['alias'],
              'script': 'await message.reply("ok");',
            },
            {
              'id': 'u',
              'name': 'u',
              'type': 'command',
              'discordType': 'user',
              'aliases': ['alias'],
              'script': 'return;',
            },
            {
              'id': 'm',
              'name': 'm',
              'type': 'command',
              'discordType': 'message',
              'triggerType': 'slash',
              'script': 'return;',
            },
            {
              'id': 'h',
              'name': 'h',
              'type': 'command',
              'triggerType': 'hybrid',
              'legacyModeEnabled': true,
              'script': 'return;',
            },
          ],
        },
      );
      expect(
        commandTriggerType(await appManager.getAppCommand(botId, 'oldslash')),
        'slash',
      );
      expect(
        commandTriggerType(await appManager.getAppCommand(botId, 'emptydata')),
        'hybrid',
      );
      expect(
        commandTriggerType(await appManager.getAppCommand(botId, 'sourcedata')),
        'hybrid',
      );
      final prefix = normalizeCommandData(
        await appManager.getAppCommand(botId, 'p'),
      );
      expect(commandTriggerType(prefix), 'prefix');
      expect(legacyCommandTriggerNames(prefix), ['old', 'alias']);
      final user = normalizeCommandData(
        await appManager.getAppCommand(botId, 'u'),
      );
      expect(user['type'], 'user');
      expect(commandTriggerType(user), 'hybrid');
      final message = normalizeCommandData(
        await appManager.getAppCommand(botId, 'm'),
      );
      expect(message['type'], 'message');
      expect(commandTriggerType(message), 'slash');
      expect(
        commandTriggerType(
          normalizeCommandData(await appManager.getAppCommand(botId, 'h')),
        ),
        'hybrid',
      );
      expect((await appManager.getApp(botId))['prefix'], '?');
    },
  );

  test(
    'nested Dart BotConfig roundtrip retains prefix flags and script',
    () async {
      final raw = BotConfig(
        token: '',
        prefix: 'custom!',
        commands: [
          {
            'id': 'dart-prefix',
            'name': 'dart-prefix',
            'type': 'chatInput',
            'data': {
              'legacyModeEnabled': true,
              'legacyLocalOnly': true,
              'legacyAliases': ['dp'],
              'executionMode': 'bdfd_script',
              'bdfdScriptContent': r'$sendMessage[hello]',
            },
          },
          {
            'id': 'dart-slash',
            'name': 'dart-slash',
            'type': 'chatInput',
            'data': {'legacyModeEnabled': false, 'legacyLocalOnly': false},
          },
          {
            'id': 'dart-hybrid',
            'name': 'dart-hybrid',
            'type': 'chatInput',
            'data': {'triggerType': 'hybrid'},
          },
        ],
      ).toJson();
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: Map<String, dynamic>.from(
          jsonDecode(jsonEncode(raw)) as Map,
        ),
      );
      expect((await appManager.getApp(botId))['prefix'], 'custom!');
      for (final kind in ['prefix', 'slash', 'hybrid']) {
        expect(
          commandTriggerType(
            await appManager.getAppCommand(botId, 'dart-$kind'),
          ),
          kind,
        );
      }
      expect(
        (await appManager.getAppCommand(
          botId,
          'dart-prefix',
        ))['data']['bdfdScriptContent'],
        r'$sendMessage[hello]',
      );
    },
  );

  test(
    'restoring an old cloud document without trigger info keeps local prefix commands',
    () async {
      await appManager.saveAppCommand(botId, 'old-prefix', {
        'id': 'old-prefix',
        'name': 'old-prefix',
        'type': 'chatInput',
        'data': {
          'executionMode': 'javascript',
          'jsScriptContent': 'return;',
          'legacyModeEnabled': true,
          'legacyLocalOnly': true,
          'legacyPrefixOverride': 'p',
          'legacyAliases': ['alias'],
        },
      });
      // Shape pushed by app versions that did not send any trigger info.
      final remote = <String, dynamic>{
        'commands': [
          {
            'id': 'old-prefix',
            'type': 'command',
            'name': 'old-prefix',
            'description': 'x',
            'discordType': 'chatInput',
            'aliases': <String>[],
            'options': <dynamic>[],
            'enabled': true,
            'script': 'return;',
          },
          {
            'id': 'brand-new',
            'type': 'command',
            'name': 'brand-new',
            'description': 'x',
            'discordType': 'chatInput',
            'script': 'return;',
          },
        ],
      };
      await applyManagerConfigToLocal(
        appManager: appManager,
        botId: botId,
        remoteConfig: remote,
      );
      final kept = await appManager.getAppCommand(botId, 'old-prefix');
      expect(commandTriggerType(kept), 'prefix');
      expect(kept['data']['legacyModeEnabled'], true);
      expect(kept['data']['legacyPrefixOverride'], 'p');
      expect(kept['data']['legacyAliases'], ['alias']);
      // No local copy: unchanged behaviour (old JS handlers stay hybrid).
      expect(
        commandTriggerType(await appManager.getAppCommand(botId, 'brand-new')),
        'hybrid',
      );
    },
  );
}
