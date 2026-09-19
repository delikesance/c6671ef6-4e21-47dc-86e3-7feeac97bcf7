// Page Lavalink = INTERRUPTEUR « Musique (Lavalink) » + serveurs de repli
// personnels (le bot essaie lui-même la liste publique). Ce test verrouille :
//   1. l'interrupteur : off → `enabled: false` ;
//   2. la section « Mes serveurs de repli » : ajout / retrait, saisie invalide
//      refusée ;
//   3. la règle premium de la maison : pour un compte non premium les contrôles
//      restent VISIBLES mais GRISÉS, avec la mention « 🔒 Disponible avec Bot
//      Creator PREMIUM » ;
//   4. le payload envoyé au manager : EXACTEMENT le schéma figé
//      {"enabled": bool, "custom_servers": [{host, port, password, secure}]},
//      et plus jamais l'ancienne forme `lavalinkConfig`.
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/bot_editor/logic/lavalink_config.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/lavalink_settings_section.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Key _enabledSwitch = Key('lavalink_enabled_switch');
const Key _addServer = Key('lavalink_add_server_button');
const Key _saveButton = Key('lavalink_save_button');

void main() {
  setUp(() {
    // Compte premium par défaut : les tests qui vérifient le verrouillage
    // non premium désactivent explicitement ce contournement.
    PremiumCapabilities.debugPremiumBypass = true;
  });

  tearDown(() {
    PremiumCapabilities.debugPremiumBypass = false;
    SubscriptionService.debugSetDesktopForTests(null);
  });

  Future<List<Map<String, dynamic>>> pumpSection(
    WidgetTester tester, {
    Map<String, dynamic>? initialConfig,
  }) async {
    final saved = <Map<String, dynamic>>[];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: LavalinkSettingsSection(
              initialConfig: initialConfig,
              onSave: (config) async => saved.add(config),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return saved;
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
  }

  group('payload conforme au schéma figé', () {
    test('le constructeur n’expose que enabled + custom_servers', () {
      final payload = buildLavalinkConfigPayload(
        enabled: true,
        customServers: <Map<String, dynamic>>[
          <String, dynamic>{
            'host': ' mon.lavalink.tld ',
            'port': 2333,
            'password': 'secret',
            'secure': false,
          },
        ],
      );

      expect(payload.keys.toSet(), <String>{'enabled', 'custom_servers'});
      expect(payload['enabled'], isTrue);
      final servers = payload['custom_servers'] as List<dynamic>;
      expect(servers, hasLength(1));
      expect((servers.single as Map).keys.toSet(), <String>{
        'host',
        'port',
        'password',
        'secure',
      });
      expect(servers.single, <String, dynamic>{
        'host': 'mon.lavalink.tld',
        'port': 2333,
        'password': 'secret',
        'secure': false,
      });
    });

    test('interrupteur off → enabled: false et plus aucun serveur', () {
      final payload = <String, dynamic>{'token': 'tok', 'isPremium': true};

      applyLavalinkSchema(payload, <String, dynamic>{
        'enabled': false,
        'custom_servers': <dynamic>[],
      });

      expect(payload['lavalink'], <String, dynamic>{
        'enabled': false,
        'custom_servers': <dynamic>[],
      });
    });

    test('l’ancienne forme `lavalinkConfig` est remplacée, jamais envoyée', () {
      final payload = <String, dynamic>{
        'token': 'tok',
        'lavalinkConfig': <String, dynamic>{
          'host': 'legacy.tld',
          'port': 2333,
          'password': 'p',
          'useSsl': true,
        },
      };

      applyLavalinkSchema(
        payload,
        payload['lavalinkConfig'] as Map<String, dynamic>,
      );

      expect(payload.containsKey('lavalinkConfig'), isFalse);
      expect(payload['lavalink'], <String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          <String, dynamic>{
            'host': 'legacy.tld',
            'port': 2333,
            'password': 'p',
            'secure': true,
          },
        ],
      });
    });

    test('le BotConfig de l’app n’embarque plus l’ancienne clé : seul '
        '`lavalink` sort', () {
      // Le chemin réel : BotConfig.toJson() puis applyLavalinkSchema.
      final payload = BotConfig(token: 'tok').toJson();

      expect(payload.containsKey('lavalinkConfig'), isFalse);

      applyLavalinkSchema(payload, <String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          <String, dynamic>{
            'host': 'repli.tld',
            'port': 443,
            'password': 'secret',
            'secure': true,
          },
        ],
      });

      expect(payload['lavalink'], <String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          <String, dynamic>{
            'host': 'repli.tld',
            'port': 443,
            'password': 'secret',
            'secure': true,
          },
        ],
      });
    });

    test('lecture de la nouvelle forme : enabled prime, port hors bornes '
        'retombe sur le port par défaut', () {
      final config = <String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[
          <String, dynamic>{
            'host': 'a.tld',
            'port': '70000',
            'password': 'x',
            'secure': true,
          },
          <String, dynamic>{'port': 2333},
        ],
      };

      expect(lavalinkEnabledFromConfig(config), isTrue);
      expect(lavalinkCustomServersFromConfig(config), <dynamic>[
        <String, dynamic>{
          'host': 'a.tld',
          'port': kLavalinkDefaultPort,
          'password': 'x',
          'secure': true,
        },
      ]);
      expect(lavalinkEnabledFromConfig(<String, dynamic>{}), isFalse);
      expect(lavalinkEnabledFromConfig(null), isFalse);
    });
  });

  group('interrupteur', () {
    testWidgets('off → la config enregistrée porte enabled: false', (
      tester,
    ) async {
      final saved = await pumpSection(
        tester,
        initialConfig: <String, dynamic>{'enabled': true, 'custom_servers': []},
      );

      final switchTile = tester.widget<SwitchListTile>(
        find.byKey(_enabledSwitch),
      );
      expect(switchTile.value, isTrue, reason: 'état persisté relu');

      await tapVisible(tester, find.byKey(_enabledSwitch));
      expect(
        tester.widget<SwitchListTile>(find.byKey(_enabledSwitch)).value,
        isFalse,
      );

      await tapVisible(tester, find.byKey(_saveButton));
      await tester.pump();

      expect(saved, hasLength(1));
      expect(saved.single, <String, dynamic>{
        'enabled': false,
        'custom_servers': <dynamic>[],
      });
    });

    testWidgets('aucun sélecteur de serveur public, aucun test de connexion', (
      tester,
    ) async {
      await pumpSection(tester);

      expect(find.byIcon(Icons.wifi_find), findsNothing);
      expect(find.byIcon(Icons.public), findsNothing);
      expect(find.byIcon(Icons.list), findsNothing);
    });
  });

  group('mes serveurs de repli', () {
    testWidgets('ajout d’un serveur → envoyé dans custom_servers', (
      tester,
    ) async {
      final saved = await pumpSection(tester);

      await tapVisible(tester, find.byKey(_addServer));
      await tester.enterText(
        find.byKey(const Key('lavalink_server_host_0')),
        'lavalink.example.com',
      );
      await tester.enterText(
        find.byKey(const Key('lavalink_server_port_0')),
        '443',
      );
      await tester.enterText(
        find.byKey(const Key('lavalink_server_password_0')),
        'secret',
      );
      await tapVisible(tester, find.byKey(const Key('lavalink_server_secure_0')));

      await tapVisible(tester, find.byKey(_saveButton));
      await tester.pump();

      expect(saved, hasLength(1));
      expect(saved.single, <String, dynamic>{
        'enabled': false,
        'custom_servers': <dynamic>[
          <String, dynamic>{
            'host': 'lavalink.example.com',
            'port': 443,
            'password': 'secret',
            'secure': true,
          },
        ],
      });
    });

    testWidgets('retrait d’un serveur → custom_servers vidé', (tester) async {
      final saved = await pumpSection(
        tester,
        initialConfig: <String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[
            <String, dynamic>{
              'host': 'repli.tld',
              'port': 2333,
              'password': 'p',
              'secure': false,
            },
          ],
        },
      );

      expect(find.byKey(const Key('lavalink_server_host_0')), findsOneWidget);

      await tapVisible(
        tester,
        find.byKey(const Key('lavalink_remove_server_0')),
      );

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(find.text(l10n.bot_settings_lavalink_no_fallback), findsOneWidget);

      await tapVisible(tester, find.byKey(_saveButton));
      await tester.pump();

      expect(saved.single, <String, dynamic>{
        'enabled': true,
        'custom_servers': <dynamic>[],
      });
    });

    testWidgets('saisie invalide (hôte vide) → rien n’est enregistré', (
      tester,
    ) async {
      final saved = await pumpSection(tester);

      await tapVisible(tester, find.byKey(_addServer));
      await tapVisible(tester, find.byKey(_saveButton));
      await tester.pump();

      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      expect(
        find.text(l10n.bot_settings_lavalink_invalid_server),
        findsOneWidget,
      );
      expect(saved, isEmpty);
    });
  });

  group('règle premium : visible mais grisé', () {
    testWidgets('compte non premium → cadenas, mention PREMIUM, contrôles '
        'désactivés mais présents', (tester) async {
      PremiumCapabilities.debugPremiumBypass = false;
      SubscriptionService.debugSetDesktopForTests(false);
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));

      await pumpSection(
        tester,
        initialConfig: <String, dynamic>{
          'enabled': true,
          'custom_servers': <dynamic>[
            <String, dynamic>{
              'host': 'repli.tld',
              'port': 2333,
              'password': 'p',
              'secure': false,
            },
          ],
        },
      );

      // Rien n'est masqué : les contrôles sont là…
      expect(find.byKey(_enabledSwitch), findsOneWidget);
      expect(find.byKey(_addServer), findsOneWidget);
      expect(find.byKey(_saveButton), findsOneWidget);
      expect(find.byKey(const Key('lavalink_server_host_0')), findsOneWidget);
      // …la mention premium et les cadenas aussi.
      expect(
        find.text(l10n.bot_settings_lavalink_premium_banner_title),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.lock), findsWidgets);

      // …mais tout est grisé.
      expect(
        tester.widget<SwitchListTile>(find.byKey(_enabledSwitch)).onChanged,
        isNull,
      );
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(_enabledSwitch))
            .value,
        isTrue,
        reason: 'l’état réel reste affiché, il n’est pas effacé',
      );
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('lavalink_server_host_0')))
            .enabled,
        isFalse,
      );
      expect(
        tester.widget<OutlinedButton>(find.byKey(_addServer)).onPressed,
        isNull,
      );
      expect(
        tester.widget<ElevatedButton>(find.byKey(_saveButton)).onPressed,
        isNull,
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('lavalink_server_secure_0')),
            )
            .onChanged,
        isNull,
      );
    });
  });
}
