import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/discord_application_commands.dart';
import 'package:bot_creator_shared/utils/application_command_lookup.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Discord implements DiscordApplicationCommandsApi {
  _Discord(this.id);
  String id;
  @override
  Future<List<DiscordRemoteCommand>> listCommands() async => [
    DiscordRemoteCommand(id: id, name: 'daily'),
  ];
  @override
  Future<DiscordRemoteCommand> createCommand(DiscordCommandPlan plan) async =>
      throw StateError('Existing command must not be recreated');
  @override
  Future<void> deleteCommand(String id) async =>
      throw StateError('Existing command must not be deleted');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory documents;
  late AppManager manager;
  const botId = 'identity-regression';
  const storageId = 'original-history-key';
  final original = <String, dynamic>{
    'id': storageId,
    'name': 'daily',
    'type': 'chatInput',
    'description': 'Daily reward',
    'data': <String, dynamic>{'actions': <dynamic>[]},
  };

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    documents = await Directory.systemTemp.createTemp('command_identity');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => documents.path);
    manager = AppManager();
  });
  setUp(() async => manager.invalidateRestoredCommandCaches());
  tearDown(() {
    AppManager.onAfterCommandDelete = null;
  });

  test('delete supplies separate IDs for runtime and Discord', () async {
    await manager.saveAppCommand('delete-bot', 'stable-key', {
      ...original,
      'discordId': 'live-discord-id',
    });
    String? runtimeId;
    String? registrationId;
    AppManager.onAfterCommandDelete = (bot, id, {String? discordId}) async {
      runtimeId = id;
      registrationId = discordId;
    };
    await manager.deleteAppCommand('delete-bot', 'stable-key');
    expect(runtimeId, 'stable-key');
    expect(registrationId, 'live-discord-id');
    expect(await manager.getAppCommand('delete-bot', 'stable-key'), isEmpty);
  });
  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    // SQLite may still own a file handle on Windows.
    try {
      await documents.delete(recursive: true);
    } on FileSystemException {
      // SQLite may retain its handle until the test process exits.
    }
  });

  test(
    'sync twice keeps file/history ID and updates the interaction binding',
    () async {
      await manager.saveAppCommand(botId, storageId, original);
      final api = _Discord('discord-first');
      final first = await reconcileDiscordCommandsForBot(botId, api: api);
      expect(first!.relinked, 1);
      api.id = 'discord-second';
      final second = await reconcileDiscordCommandsForBot(botId, api: api);
      expect(second!.relinked, 1);
      final commands = await manager.listAppCommands(botId, forceRefresh: true);
      expect(commands, hasLength(1));
      expect(commands.single['id'], storageId);
      expect(commands.single['discordId'], 'discord-second');
      expect(await manager.getAppCommand(botId, storageId), isNotEmpty);
      expect(await manager.getAppCommand(botId, 'discord-second'), isEmpty);
      expect(
        findApplicationCommand(
          commands,
          discordId: 'discord-second',
          name: 'daily',
          type: 'chatInput',
        ),
        same(commands.single),
      );
      final unchanged = await reconcileDiscordCommandsForBot(botId, api: api);
      expect(unchanged!.hasChanges, isFalse);
    },
  );

  test(
    'restore discards memory and archived payload caches before sync',
    () async {
      await manager.saveCachedPayload(botId, {
        'commands': [
          {...original, 'id': 'cached-id', 'name': 'cached-command'},
        ],
      });
      expect(
        (await manager.listAppCommands(botId)).single['name'],
        'cached-command',
      );
      // Backup extraction bypasses the command-save method.
      final root = await manager.path;
      final restoredFile = File('$root/apps/$botId/$storageId.json');
      await restoredFile.parent.create(recursive: true);
      await restoredFile.writeAsString(jsonEncode(original));
      await manager.invalidateRestoredCommandCaches();
      final restored = await manager.listAppCommands(botId);
      expect(restored.single['id'], storageId);
      expect(restored.single['name'], 'daily');
      expect(await File('$root/apps/$botId.payload.json').exists(), isFalse);
      final api = _Discord('after-restore');
      expect(
        (await reconcileDiscordCommandsForBot(botId, api: api))!.relinked,
        1,
      );
      expect((await manager.listAppCommands(botId)).single['id'], storageId);
    },
  );

  test(
    'old sync files with a stale embedded ID use their actual storage key',
    () async {
      final root = await manager.path;
      final file = File('$root/apps/old-sync/current-file.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode({...original, 'id': 'stale-embedded-id'}),
      );
      expect(
        (await manager.listAppCommands(
          'old-sync',
          forceRefresh: true,
        )).single['id'],
        'current-file',
      );
      expect(
        (await manager.getAppCommand('old-sync', 'current-file'))['id'],
        'current-file',
      );
    },
  );
}
