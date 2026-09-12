import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/js_bot_payload_builder.dart';
import 'package:bot_creator/features/bot_editor/logic/normalize_command_data.dart';
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
  late AppManager appManager;
  const botId = '123456789012345678';

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues(const {});
    documentsDir = await Directory.systemTemp.createTemp(
      'command_name_integrity_test',
    );
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
    await appManager.saveApp(botId, <String, dynamic>{
      'id': botId,
      'name': 'TestBot',
      'token': 'test_token',
      'workflows': <Map<String, dynamic>>[],
      'globalVariables': <String, dynamic>{},
      'intents': <String, bool>{},
    });

    final existingCmds = await appManager.listAppCommands(botId);
    for (final cmd in existingCmds) {
      await appManager.deleteAppCommand(botId, cmd['id'].toString());
    }
  });

  test(
    'saveAppCommand with a missing name never persists the literal "unknown"',
    () async {
      await appManager.saveAppCommand(botId, 'cmd_nameless', {
        'id': 'cmd_nameless',
        'type': 'command',
        'script': 'await interaction.reply("hi");',
        'data': {'commandType': 'chatInput', 'executionMode': 'javascript'},
      });

      final commands = await appManager.listAppCommands(
        botId,
        forceRefresh: true,
      );
      expect(commands, hasLength(1));

      final name = commands.single['name'].toString();
      expect(name, isNotEmpty);
      expect(name, isNot(equals('unknown')));
    },
  );

  test('two nameless commands in one bot get two different names', () async {
    await appManager.saveAppCommand(botId, 'cmd_alpha', {
      'id': 'cmd_alpha',
      'type': 'command',
      'script': 'await interaction.reply("a");',
      'data': {'commandType': 'chatInput', 'executionMode': 'javascript'},
    });
    await appManager.saveAppCommand(botId, 'cmd_beta', {
      'id': 'cmd_beta',
      'type': 'command',
      'script': 'await interaction.reply("b");',
      'data': {'commandType': 'chatInput', 'executionMode': 'javascript'},
    });

    final commands = await appManager.listAppCommands(
      botId,
      forceRefresh: true,
    );
    expect(commands, hasLength(2));

    final names = commands.map((c) => c['name'].toString()).toList();
    for (final name in names) {
      expect(name, isNotEmpty);
      expect(name, isNot(equals('unknown')));
    }
    expect(names.toSet(), hasLength(2));
  });

  test(
    'normalizeCommandData preserves the root name of a remote-JS-shaped map',
    () async {
      final normalized = normalizeCommandData(<String, dynamic>{
        'id': 'x',
        'type': 'command',
        'name': 'greet',
        'script': 'await interaction.reply("hello");',
        'data': {'commandType': 'chatInput'},
      });

      expect(normalized['name'], 'greet');
      expect(normalized['id'], 'x');
      expect(normalized['data'], isA<Map>());
    },
  );

  test(
    'buildJsBotPayload never emits two commands with the same name',
    () async {
      await appManager.saveAppCommand(botId, 'cmd_dup_one', {
        'id': 'cmd_dup_one',
        'type': 'command',
        'name': 'dup',
        'data': {
          'commandType': 'chatInput',
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("one");',
        },
      });
      await appManager.saveAppCommand(botId, 'cmd_dup_two', {
        'id': 'cmd_dup_two',
        'type': 'command',
        'name': 'dup',
        'data': {
          'commandType': 'chatInput',
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("two");',
        },
      });
      await appManager.saveAppCommand(botId, 'cmd_blank', {
        'id': 'cmd_blank',
        'type': 'command',
        'data': {
          'commandType': 'chatInput',
          'executionMode': 'javascript',
          'jsScriptContent': 'await interaction.reply("blank");',
        },
      });

      final payload = await buildJsBotPayload(botId);
      final commands = (payload['commands'] as List).cast<Map>();

      expect(commands, hasLength(3));

      final names = commands.map((c) => c['name'].toString()).toList();
      for (final name in names) {
        expect(name.trim(), isNotEmpty);
      }
      expect(names.toSet(), hasLength(names.length));
    },
  );
}
