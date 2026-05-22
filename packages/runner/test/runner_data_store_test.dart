import 'dart:io';

import 'package:bot_creator_runner/runner_data_store.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:test/test.dart';

void main() {
  group('RunnerDataStore', () {
    late Directory tempDir;
    late String originalCwd;

    setUp(() async {
      originalCwd = Directory.current.path;
      tempDir = await Directory.systemTemp.createTemp('runner-data-store-');
      Directory.current = tempDir.path;
    });

    tearDown(() async {
      Directory.current = originalCwd;
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('hydrates typed globals and synced scoped variables', () async {
      final store = RunnerDataStore(_testConfig());
      addTearDown(store.dispose);

      final globals = await store.getGlobalVariables('runner');
      final guildScoped = await store.getScopedVariables(
        'runner',
        'guild',
        'guild-1',
      );
      final memberScoped = await store.getScopedVariables(
        'runner',
        'guildMember',
        'guild-1:user-1',
      );

      expect(globals['enabled'], isTrue);
      expect(globals['count'], 3);
      expect(globals['meta'], <String, dynamic>{'mode': 'strict'});
      expect(guildScoped['score'], 9);
      expect(memberScoped['rank'], 'mod');
    });

    test('preserves runtime global writes across store re-open', () async {
      final firstStore = RunnerDataStore(_testConfig());
      await firstStore.getGlobalVariables('runner');
      await firstStore.setGlobalVariable('runner', 'count', 42);
      await firstStore.dispose();

      final secondStore = RunnerDataStore(_testConfig());
      addTearDown(secondStore.dispose);

      expect(await secondStore.getGlobalVariable('runner', 'count'), 42);
      expect(await secondStore.getGlobalVariable('runner', 'enabled'), isTrue);
    });

    test('updateConfig replaces configuration, commands, and workflows', () async {
      final initialConfig = BotConfig(
        token: 'token-1',
        commands: [
          {'id': 'cmd-1', 'name': 'help'}
        ],
        workflows: [
          {'name': 'wf-1'}
        ],
      );
      final store = RunnerDataStore(initialConfig);
      addTearDown(store.dispose);

      expect(await store.getCommands('runner'), hasLength(1));
      expect((await store.getCommands('runner'))[0]['name'], 'help');
      expect(await store.getWorkflows('runner'), hasLength(1));

      final updatedConfig = BotConfig(
        token: 'token-2',
        commands: [
          {'id': 'cmd-1', 'name': 'help'},
          {'id': 'cmd-2', 'name': 'settings'}
        ],
        workflows: [
          {'name': 'wf-1'},
          {'name': 'wf-2'}
        ],
      );

      store.updateConfig(updatedConfig);

      expect(await store.getCommands('runner'), hasLength(2));
      expect((await store.getCommands('runner'))[1]['name'], 'settings');
      expect(await store.getWorkflows('runner'), hasLength(2));
      expect((await store.getApp('runner'))['token'], 'token-2');
    });
  });
}

BotConfig _testConfig() {
  return BotConfig(
    token: 'discord-token',
    globalVariables: <String, dynamic>{
      'enabled': true,
      'count': 3,
      'meta': <String, dynamic>{'mode': 'strict'},
    },
    scopedVariables: <String, Map<String, Map<String, dynamic>>>{
      'guild': <String, Map<String, dynamic>>{
        'guild-1': <String, dynamic>{'score': 9},
      },
      'guildMember': <String, Map<String, dynamic>>{
        'guild-1:user-1': <String, dynamic>{'rank': 'mod'},
      },
    },
  );
}
