import 'dart:convert';
import 'dart:io';

import 'package:bot_creator_runner/runner_bot_store.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:test/test.dart';

void main() {
  group('RunnerBotStore zero-secret persistence', () {
    late Directory tempDir;
    late RunnerBotStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('runner-bot-store-test-');
      store = RunnerBotStore(dataDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'strips token and secrets when saving to disk, but retains them in RAM',
      () async {
        const botId = 'bot-123';
        const botName = 'Secret Bot';
        const secretToken = 'super-secret-discord-token-xyz';

        const config = BotConfig(
          token: secretToken,
          prefix: '!',
          lavalinkConfig: LavalinkConfig(
            host: 'lavalink.internal',
            port: 2333,
            password: 'lavalink-password-123',
          ),
        );

        await store.save(botId, botName, config);

        // Verify the disk file contains ZERO plaintext secrets
        final safeBotId = botId.replaceAll(RegExp(r'[^\w\-]'), '_');
        final diskFile = File('${tempDir.path}/$safeBotId/config.json');
        expect(await diskFile.exists(), isTrue);

        final diskRaw = await diskFile.readAsString();
        final diskJson = jsonDecode(diskRaw) as Map<String, dynamic>;
        final diskConfig = diskJson['config'] as Map<String, dynamic>;

        expect(diskConfig['token'], equals(''));
        expect(diskRaw.contains(secretToken), isFalse);
        expect(diskRaw.contains('lavalink-password-123'), isFalse);

        // Verify loadEntry re-hydrates the token in memory
        final entry = await store.loadEntry(botId);
        expect(entry, isNotNull);
        expect(entry!.config.token, equals(secretToken));
        expect(
          entry.config.lavalinkConfig?.password,
          equals('lavalink-password-123'),
        );

        // Also verify listAll provides re-hydrated entry
        final all = await store.listAll();
        expect(all.length, equals(1));
        expect(all.first.config.token, equals(secretToken));
      },
    );
  });
}
