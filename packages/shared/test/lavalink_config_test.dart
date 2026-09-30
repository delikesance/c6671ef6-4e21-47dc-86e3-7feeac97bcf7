import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:test/test.dart';

/// Fabrique un serveur personnel du schéma figé.
Map<String, dynamic> _server(
  String host, {
  Object? port = 2333,
  String password = 'secret',
  Object? secure,
}) {
  return <String, dynamic>{
    'host': host,
    'port': port,
    'password': password,
    'secure': ?secure,
  };
}

void main() {
  group('LavalinkConfig — schéma figé (enabled + custom_servers)', () {
    test('lit enabled et la liste des serveurs personnels', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          _server('mon.lavalink.tld'),
          _server(
            'repli.lavalink.tld',
            port: 443,
            password: 'p2',
            secure: true,
          ),
        ],
      });

      expect(config.enabled, isTrue);
      expect(config.customServers, hasLength(2));
      expect(config.customServers.first.host, 'mon.lavalink.tld');
      expect(config.customServers.first.port, 2333);
      expect(config.customServers.first.password, 'secret');
      expect(config.customServers.first.secure, isFalse);
      expect(config.customServers[1].secure, isTrue);
      expect(config.customServers[1].port, 443);
    });

    test('le premier serveur personnel est le miroir des champs hérités', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          _server('a.tld', port: 8080, password: 'pw', secure: true),
        ],
      });

      expect(config.host, 'a.tld');
      expect(config.port, 8080);
      expect(config.password, 'pw');
      expect(config.useSsl, isTrue);
      expect(config.primaryServer?.host, 'a.tld');
      expect(config.hasCustomServers, isTrue);
    });

    test('aucun `enabled` et aucun serveur => musique désactivée', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'custom_servers': <dynamic>[],
      });

      expect(config.enabled, isFalse);
      expect(config.customServers, isEmpty);
    });

    test(
      '`enabled: false` explicite reste désactivé même avec des serveurs',
      () {
        final config = LavalinkConfig.fromJson(<String, dynamic>{
          'enabled': false,
          'custom_servers': <dynamic>[_server('a.tld')],
        });

        expect(config.enabled, isFalse);
        expect(config.customServers, hasLength(1));
      },
    );

    test('`secure` vaut false par défaut et relit les alias hérités', () {
      final defaults = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[_server('a.tld')],
      });
      expect(defaults.customServers.single.secure, isFalse);

      final alias = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          <String, dynamic>{'host': 'b.tld', 'useSsl': true},
        ],
      });
      expect(alias.customServers.single.secure, isTrue);
    });

    test(
      'un serveur sans hôte est ignoré, un port illisible retombe sur 2333',
      () {
        final config = LavalinkConfig.fromJson(<String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[
            <String, dynamic>{'port': 2333, 'password': 'orphelin'},
            <String, dynamic>{'host': 'bon.tld', 'port': 'pas-un-port'},
          ],
        });

        expect(config.customServers, hasLength(1));
        expect(config.customServers.single.host, 'bon.tld');
        expect(config.customServers.single.port, 2333);
      },
    );
  });

  group('LavalinkConfig — rétrocompatibilité de l\'ancienne forme', () {
    test(
      'un serveur unique en clair devient custom_servers[0] ET reste actif',
      () {
        final config = LavalinkConfig.fromJson(<String, dynamic>{
          'host': 'ancien.lavalink.tld',
          'port': 2334,
          'password': 'pwd',
          'useSsl': true,
        });

        // Le point capital : un bot déjà configuré ne perd pas sa musique.
        expect(config.enabled, isTrue);
        expect(config.customServers, hasLength(1));

        final server = config.customServers.single;
        expect(server.host, 'ancien.lavalink.tld');
        expect(server.port, 2334);
        expect(server.password, 'pwd');
        expect(server.secure, isTrue);
        expect(config.host, 'ancien.lavalink.tld');
        expect(config.useSsl, isTrue);
      },
    );

    test('l\'ancienne forme garde ses alias ssl et secure', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'host': 'a.tld',
        'ssl': true,
      });
      expect(config.enabled, isTrue);
      expect(config.customServers.single.secure, isTrue);

      final viaSecure = LavalinkConfig.fromJson(<String, dynamic>{
        'host': 'b.tld',
        'secure': true,
      });
      expect(viaSecure.customServers.single.secure, isTrue);
    });

    test('un hôte hérité vide ne vaut pas « activé »', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{'host': '   '});
      expect(config.enabled, isFalse);
      expect(config.customServers, isEmpty);
    });

    test('l\'ancienne construction Dart reste active (runner, app)', () {
      const legacy = LavalinkConfig(host: 'localhost', port: 2333);
      expect(legacy.enabled, isTrue);
      expect(legacy.customServers, isEmpty);
      expect(() => legacy.validate(), returnsNormally);
    });
  });

  group('LavalinkConfig — écriture et comparaison', () {
    test('toJson écrit le schéma figé ET la forme héritée', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[_server('a.tld')],
      });

      final json = config.toJson();
      expect(json['enabled'], isTrue);
      expect((json['custom_servers'] as List).single['host'], 'a.tld');
      // Un lecteur plus ancien retrouve un serveur exploitable.
      expect(json['host'], 'a.tld');
      expect(json['port'], 2333);
    });

    test('aller-retour JSON : les réglages sont conservés', () {
      final config = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          _server('a.tld', port: 2333, secure: false),
          _server('b.tld', port: 443, password: 'p2', secure: true),
        ],
      });

      final again = LavalinkConfig.fromJson(config.toJson());
      expect(again.sameSettingsAs(config), isTrue);
      expect(again.enabled, isTrue);
      expect(again.customServers.map((s) => s.secure), <bool>[false, true]);
    });

    test(
      'sameSettingsAs détecte un changement d\'interrupteur ou de serveur',
      () {
        final base = LavalinkConfig.fromJson(<String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[_server('a.tld')],
        });
        final disabled = LavalinkConfig.fromJson(<String, dynamic>{
          'enabled': false,
          'custom_servers': <dynamic>[_server('a.tld')],
        });
        final otherHost = LavalinkConfig.fromJson(<String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[_server('b.tld')],
        });

        expect(base.sameSettingsAs(disabled), isFalse);
        expect(base.sameSettingsAs(otherHost), isFalse);
        expect(base.sameSettingsAs(base), isTrue);
      },
    );

    test('validate ne se plaint pas d\'une musique désactivée', () {
      final disabled = LavalinkConfig.fromJson(<String, dynamic>{
        'enabled': false,
      });
      expect(disabled.validate, returnsNormally);
    });

    test('validate refuse un serveur personnel mal formé', () {
      const bad = LavalinkConfig(
        enabled: true,
        customServers: <LavalinkServerConfig>[
          LavalinkServerConfig(host: '', port: 2333),
        ],
      );
      expect(bad.validate, throwsArgumentError);

      const badPort = LavalinkConfig(
        enabled: true,
        customServers: <LavalinkServerConfig>[
          LavalinkServerConfig(host: 'a.tld', port: 70000),
        ],
      );
      expect(badPort.validate, throwsArgumentError);
    });
  });

  group('BotConfig — les deux générations de configuration Lavalink', () {
    test('lit la clé `lavalink` du schéma figé', () {
      final config = BotConfig.fromJson(<String, dynamic>{
        'token': 't',
        'lavalink': <String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[_server('a.tld')],
        },
      });

      expect(config.lavalinkConfig, isNotNull);
      expect(config.lavalinkConfig!.enabled, isTrue);
      expect(config.lavalinkConfig!.customServers.single.host, 'a.tld');
    });

    test('lit toujours la clé historique `lavalinkConfig`', () {
      final config = BotConfig.fromJson(<String, dynamic>{
        'token': 't',
        'lavalinkConfig': <String, dynamic>{'host': 'old.tld', 'port': 2333},
      });

      expect(config.lavalinkConfig!.enabled, isTrue);
      expect(config.lavalinkConfig!.customServers.single.host, 'old.tld');
    });

    test('la clé historique gagne si les deux sont présentes', () {
      final config = BotConfig.fromJson(<String, dynamic>{
        'token': 't',
        'lavalinkConfig': <String, dynamic>{'host': 'historique.tld'},
        'lavalink': <String, dynamic>{'enabled': false},
      });

      expect(config.lavalinkConfig!.host, 'historique.tld');
      expect(config.lavalinkConfig!.enabled, isTrue);
    });

    test('un bot hérité ne perd ni sa musique ni son serveur après export', () {
      final legacy = BotConfig.fromJson(<String, dynamic>{
        'token': 't',
        'lavalinkConfig': <String, dynamic>{
          'host': 'musique.tld',
          'port': 2333,
          'password': 'pw',
        },
      });
      expect(legacy.lavalinkConfig!.enabled, isTrue);

      final reimported = BotConfig.fromJson(legacy.toJson());
      expect(reimported.lavalinkConfig!.enabled, isTrue);
      expect(
        reimported.lavalinkConfig!.customServers.single.host,
        'musique.tld',
      );
      expect(reimported.lavalinkConfig!.customServers.single.password, 'pw');
    });

    test('aucune clé Lavalink => musique absente', () {
      final config = BotConfig.fromJson(<String, dynamic>{'token': 't'});
      expect(config.lavalinkConfig, isNull);
    });

    test('une configuration désactivée passe la validation', () {
      final config = BotConfig.fromJson(<String, dynamic>{
        'token': 't',
        'lavalink': <String, dynamic>{'enabled': false},
      });
      expect(config.validate, returnsNormally);
    });
  });
}
