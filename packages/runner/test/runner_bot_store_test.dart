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

  group('RunnerBotStore — le schéma Lavalink survit au disque', () {
    late Directory tempDir;
    late RunnerBotStore store;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('runner-bot-store-lava-');
      store = RunnerBotStore(dataDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    Future<Map<String, dynamic>> diskConfig(String botId) async {
      final safe = botId.replaceAll(RegExp(r'[^\w\-]'), '_');
      final raw = await File('${tempDir.path}/$safe/config.json').readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return json['config'] as Map<String, dynamic>;
    }

    test('la musique désactivée le reste après un redémarrage du runner', () async {
      const botId = 'bot-music-off';
      const config = BotConfig(
        token: 't',
        prefix: '!',
        lavalinkConfig: LavalinkConfig(enabled: false),
      );

      await store.save(botId, 'Musique off', config);

      final onDisk = await diskConfig(botId);
      expect(onDisk['lavalink']['enabled'], isFalse);

      // Nouveau store = mémoire vide : c'est le disque qui parle.
      final afterRestart = await RunnerBotStore(dataDir: tempDir.path).load(botId);
      expect(
        afterRestart?.lavalinkConfig?.enabled,
        isFalse,
        reason: 'avant le correctif, le disque relisait `enabled: true` de force',
      );
      // `toJson` réécrit toujours la forme héritée (host/port) ; elle est relue
      // en `custom_servers[0]`, mais l'interrupteur à `false` la rend inerte :
      // aucun sondage, aucun plugin (cf. lavalink_session_startup_test.dart).
    });

    test('les serveurs personnels survivent, leurs mots de passe restent hors disque', () async {
      const botId = 'bot-music-custom';
      const config = BotConfig(
        token: 't',
        prefix: '!',
        lavalinkConfig: LavalinkConfig(
          customServers: <LavalinkServerConfig>[
            LavalinkServerConfig(
              host: 'lavalink.perso',
              port: 2333,
              password: 'premier-secret',
              secure: true,
            ),
            LavalinkServerConfig(
              host: 'lavalink.repli',
              port: 8080,
              password: 'deuxieme-secret',
            ),
          ],
          host: 'lavalink.perso',
          port: 2333,
          password: 'premier-secret',
          useSsl: true,
        ),
      );

      await store.save(botId, 'Musique perso', config);

      final raw = await File(
        '${tempDir.path}/$botId/config.json',
      ).readAsString();
      expect(raw.contains('premier-secret'), isFalse);
      expect(raw.contains('deuxieme-secret'), isFalse);

      final onDisk = await diskConfig(botId);
      final schema = Map<String, dynamic>.from(
        onDisk['lavalink'] as Map<String, dynamic>,
      );
      expect(schema['enabled'], isTrue);
      final servers = schema['custom_servers'] as List<dynamic>;
      expect(servers, hasLength(2));
      expect((servers[0] as Map)['host'], 'lavalink.perso');
      expect((servers[0] as Map)['port'], 2333);
      expect((servers[1] as Map)['host'], 'lavalink.repli');

      // Sans redémarrage : la mémoire rend les secrets et le schéma complet.
      final inProcess = await store.load(botId);
      expect(inProcess?.lavalinkConfig?.enabled, isTrue);
      expect(inProcess?.lavalinkConfig?.customServers, hasLength(2));
      expect(
        inProcess?.lavalinkConfig?.customServers.first.password,
        'premier-secret',
      );

      // Après redémarrage : le schéma tient (le mot de passe viendra de la
      // prochaine synchro de l'app, jamais du disque).
      final afterRestart = await RunnerBotStore(dataDir: tempDir.path).load(botId);
      expect(afterRestart?.lavalinkConfig?.enabled, isTrue);
      expect(afterRestart?.lavalinkConfig?.customServers, hasLength(2));
      expect(afterRestart?.lavalinkConfig?.customServers.last.host, 'lavalink.repli');
    });

    test('l\'ancienne forme (serveur unique) est toujours lue', () async {
      const botId = 'bot-music-legacy';
      final file = File('${tempDir.path}/$botId/config.json');
      await file.parent.create(recursive: true);
      await file.writeAsString(
        jsonEncode(<String, dynamic>{
          'id': botId,
          'name': 'Héritée',
          'syncedAt': DateTime.utc(2026, 1, 1).toIso8601String(),
          'running': false,
          'config': <String, dynamic>{
            'token': '',
            // Ancienne forme : serveur unique en clair, aucune clé `enabled`.
            'lavalinkConfig': <String, dynamic>{
              'host': 'ancien.lavalink',
              'port': 2456,
              'password': '',
              'useSsl': true,
            },
          },
        }),
      );

      final loaded = await RunnerBotStore(dataDir: tempDir.path).load(botId);
      final lavalink = loaded?.lavalinkConfig;

      expect(lavalink, isNotNull);
      expect(lavalink?.enabled, isTrue, reason: 'ancienne forme = musique activée');
      expect(lavalink?.customServers, hasLength(1));
      expect(lavalink?.customServers.first.host, 'ancien.lavalink');
      expect(lavalink?.customServers.first.port, 2456);
      expect(lavalink?.customServers.first.secure, isTrue);
    });

    test('une config en RAM sans mot de passe de premier niveau gagne quand même', () async {
      const botId = 'bot-music-ram';
      // Ce que le disque contient : les serveurs perso, mots de passe vidés.
      await store.save(
        botId,
        'Ram',
        const BotConfig(
          token: 'secret-token',
          prefix: '!',
          lavalinkConfig: LavalinkConfig(
            enabled: true,
            customServers: <LavalinkServerConfig>[
              LavalinkServerConfig(
                host: 'lavalink.perso',
                port: 2333,
                password: 'sur-disque-vide',
              ),
            ],
            password: '',
          ),
        ),
      );

      // Deuxième sauvegarde : l'app renvoie la même config, mot de passe du
      // serveur vide (premier niveau), donc la RAM ne doit PAS être écartée.
      await store.save(
        botId,
        'Ram',
        const BotConfig(
          token: 'secret-token',
          prefix: '!',
          lavalinkConfig: LavalinkConfig(
            enabled: true,
            customServers: <LavalinkServerConfig>[
              LavalinkServerConfig(
                host: 'lavalink.en-ram',
                port: 7777,
                password: 'secret-de-la-ram',
              ),
            ],
            password: '',
          ),
        ),
      );

      final loaded = await store.load(botId);
      expect(loaded?.lavalinkConfig?.customServers.single.host, 'lavalink.en-ram');
      expect(loaded?.lavalinkConfig?.customServers.single.port, 7777);
      expect(
        loaded?.lavalinkConfig?.customServers.single.password,
        'secret-de-la-ram',
        reason: 'le mot de passe ne vit qu\'en RAM : il prouve que la RAM a gagné',
      );
    });
  });
}
