import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/bot_editor/logic/legacy_user_variable_migration.dart';
import 'package:flutter_test/flutter_test.dart';

const bot = '123456789012345';

class _Store implements AppManager {
  _Store(this.directory);
  final Directory directory;
  Map<String, dynamic> config = {
    'id': bot,
    'token': 'not-for-backups',
    'bdfdUserVariableSemantics': 1,
    'workflows': [],
  };
  bool interrupt = true;
  int saves = 0;
  @override
  Future<String> get path async => directory.path;
  @override
  Future<Map<String, dynamic>> getApp(String id) async => Map.of(config);
  @override
  Future<void> saveApp(
    String id,
    Map<String, dynamic> value, {
    bool notifyRuntime = true,
  }) async {
    final backup = File(
      '${directory.path}/apps/$bot/migrations/bdfd-global-user-scripts-v1.json',
    );
    expect(await backup.exists(), true);
    if (interrupt) throw StateError('simulated interruption');
    saves++;
    config = Map.of(value);
  }

  @override
  Future<void> invalidatePayloadCache(String id) async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'archives scripts, resumes safely, activates last and never accesses variable storage',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bdfd_global_migration_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = _Store(directory);
      final command = File('${directory.path}/apps/$bot/command.json');
      await command.parent.create(recursive: true);
      await command.writeAsString(
        jsonEncode({
          'name': 'balance',
          'data': {'bdfdScriptContent': r'$getUserVar[coins]'},
        }),
      );
      await expectLater(
        migrateLocalLegacyUserVariables(
          store: store,
          botId: bot,
          isBotRunning: () => false,
        ),
        throwsStateError,
      );
      expect(store.config['bdfdUserVariableSemantics'], 1);
      expect(
        jsonDecode(await command.readAsString())['data']['bdfdScriptContent'],
        r'$getVar[coins;$authorID]',
      );
      final backup = File(
        '${directory.path}/apps/$bot/migrations/bdfd-global-user-scripts-v1.json',
      );
      final archive = await backup.readAsString();
      expect(archive.contains('not-for-backups'), false);
      store.interrupt = false;
      final result = await migrateLocalLegacyUserVariables(
        store: store,
        botId: bot,
        isBotRunning: () => false,
      );
      expect(result.commands, 1);
      expect(result.calls, 1);
      expect(store.config['bdfdUserVariableSemantics'], 2);
      expect(store.saves, 1);
      expect(await backup.readAsString(), archive);
      await migrateLocalLegacyUserVariables(
        store: store,
        botId: bot,
        isBotRunning: () => false,
      );
      expect(store.saves, 1);
      expect(await backup.readAsString(), archive);
      await command.writeAsString(
        jsonEncode({
          'data': {'bdfdScriptContent': 'user edited'},
        }),
      );
      await expectLater(
        migrateLocalLegacyUserVariables(
          store: store,
          botId: bot,
          isBotRunning: () => false,
        ),
        throwsStateError,
      );
      expect(
        jsonDecode(await command.readAsString())['data']['bdfdScriptContent'],
        'user edited',
      );
    },
  );

  test(
    'running and already official bots are rejected before archiving',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bdfd_migration_guard_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = _Store(directory);
      await expectLater(
        migrateLocalLegacyUserVariables(
          store: store,
          botId: bot,
          isBotRunning: () => true,
        ),
        throwsStateError,
      );
      store.config['bdfdUserVariableSemantics'] = 2;
      await expectLater(
        migrateLocalLegacyUserVariables(
          store: store,
          botId: bot,
          isBotRunning: () => false,
        ),
        throwsStateError,
      );
      expect(await directory.list(recursive: true).toList(), isEmpty);
    },
  );

  test(
    'dynamic scripts are rejected before any archive, write or activation',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'bdfd_dynamic_guard_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = _Store(directory);
      final command = File('${directory.path}/apps/$bot/command.json');
      await command.parent.create(recursive: true);
      final source = jsonEncode({
        'data': {'bdfdScriptContent': r'$eval[$getVar[code]]'},
      });
      await command.writeAsString(source);
      await expectLater(
        migrateLocalLegacyUserVariables(
          store: store,
          botId: bot,
          isBotRunning: () => false,
        ),
        throwsFormatException,
      );
      expect(await command.readAsString(), source);
      expect(store.config['bdfdUserVariableSemantics'], 1);
      expect(
        await Directory('${directory.path}/apps/$bot/migrations').exists(),
        false,
      );
    },
  );
}
