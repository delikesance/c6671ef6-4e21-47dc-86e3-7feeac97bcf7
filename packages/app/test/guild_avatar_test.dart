// Tests des avatars de serveurs de la ligne « Actif sur N serveurs ».
//
// Aucun test ne touche le réseau :
//   * `TestWidgetsFlutterBinding` bloque déjà tout HTTP réel (réponse 400) et
//     `Image.network` bascule alors sur son `errorBuilder` ;
//   * le chargeur REST est injecté (`remoteLoader`) dans tous les cas où la
//     liste de serveurs n'est pas fournie par le gateway.
//
// Contrat verrouillé ici :
//   * l'URL d'icône Discord (`discordGuildIconUrl`) — `.png?size=128`, `.gif`
//     pour les icônes animées (`a_...`), `null` quand l'icône est inconnue ;
//   * jamais de lettre tirée d'une *seed* : sans serveur connu on rend une
//     icône neutre, avec un serveur connu on rend sa vraie initiale ;
//   * la préférence pour le cache du gateway (aucun appel REST s'il est peuplé) ;
//   * la consommation de l'état *partagé de session* (`GuildDirectory.watch`) :
//     si la session a déjà chargé les serveurs, la carte les peint sans aucune
//     requête ; pendant le chargement elle rend son repli neutre (et jamais de
//     lettre inventée).
//
// Les autres contrats sont verrouillés dans des fichiers dédiés :
//   * `guilds_session_cache_test.dart` — cache de session de `GuildDirectory`
//     (une requête HTTP par bot et par lancement, `refresh()`, erreurs non
//     mises en cache, requêtes en vol partagées, sérialisation) ;
//   * `image_disk_cache_test.dart` — cache disque des icônes (zéro GET au
//     second appel, purge LRU, repli réseau).
import 'dart:async';

import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:bot_creator/features/home/presentation/home_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Snowflakes réalistes (19 chiffres) pour un tri déterministe.
const String _guildA = '1000000000000000001';
const String _guildB = '1000000000000000002';
const String _guildC = '1000000000000000003';

/// Endpoint factice : une requête réelle échouerait aussitôt (jamais appelé).
const String _fakeEndpoint = 'https://example.invalid/users/@me/guilds';

const GuildAvatarInfo _guildWithIcon = GuildAvatarInfo(
  id: _guildA,
  name: 'Serveur Alpha',
  iconHash: 'abc123',
);

const GuildAvatarInfo _guildWithoutIcon = GuildAvatarInfo(
  id: _guildB,
  name: 'Bravo',
);

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// Répertoire factice : chaque GET compte et renvoie un seul serveur (Bravo).
GuildDirectory _countingDirectory({required void Function() onFetch}) =>
    GuildDirectory(
      guildsEndpoint: _fakeEndpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async {
        onFetch();
        return '[{"id":"$_guildB","name":"Bravo","icon":null}]';
      },
    );

void main() {
  setUpAll(() {
    // Convention du dépôt : la typo est bundlée, jamais récupérée au runtime.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('discordGuildIconUrl', () {
    test('construit une URL CDN png en size=128 par défaut', () {
      expect(
        discordGuildIconUrl(_guildA, 'abc123'),
        'https://cdn.discordapp.com/icons/$_guildA/abc123.png?size=128',
      );
    });

    test('utilise le gif pour une icône animée (hash a_...)', () {
      expect(
        discordGuildIconUrl(_guildA, 'a_animatedhash', size: 64),
        'https://cdn.discordapp.com/icons/$_guildA/a_animatedhash.gif?size=64',
      );
    });

    test('renvoie null sans hash, sans id, ou avec un id non snowflake', () {
      expect(discordGuildIconUrl(_guildA, null), isNull);
      expect(discordGuildIconUrl(_guildA, '   '), isNull);
      expect(discordGuildIconUrl(null, 'abc123'), isNull);
      expect(discordGuildIconUrl('', 'abc123'), isNull);
      expect(discordGuildIconUrl('DM', 'abc123'), isNull);
      expect(discordGuildIconUrl('1234567890 ', ' abc '), isNotNull);
    });
  });

  group('guildAvatarInitial', () {
    test('prend la première lettre du vrai nom du serveur', () {
      expect(guildAvatarInitial('Serveur Alpha'), 'S');
      expect(guildAvatarInitial('  bravo '), 'B');
      expect(guildAvatarInitial(null), isNull);
      expect(guildAvatarInitial('   '), isNull);
    });

    test("ne coupe pas une paire de substitution en deux", () {
      expect(guildAvatarInitial('🎮 Serveur'), '🎮');
    });
  });

  group('parseGuildsApiPayload', () {
    test('mappe id / name / icon de GET /users/@me/guilds', () {
      final guilds = parseGuildsApiPayload(
        '[{"id":"$_guildB","name":"Bravo","icon":null},'
        '{"id":"$_guildA","name":"Alpha","icon":"hash_a"}]',
      );

      expect(guilds, hasLength(2));
      // Tri déterministe par id croissant : Alpha (…01) avant Bravo (…02).
      expect(guilds.first.id, _guildA);
      expect(guilds.first.iconUrl, contains('/icons/$_guildA/hash_a.png'));
      expect(guilds.last.id, _guildB);
      expect(guilds.last.iconUrl, isNull);
      expect(guilds.last.name, 'Bravo');
    });

    test('ignore les entrées sans id et les charges utiles illisibles', () {
      expect(
        parseGuildsApiPayload(
          '[{"name":"sans id"},{"id":"$_guildC","name":"C"}]',
        ),
        hasLength(1),
      );
      expect(parseGuildsApiPayload('not json'), isEmpty);
      expect(parseGuildsApiPayload('{"id":"x"}'), isEmpty);
    });

    test('conserve owner et approximate_member_count quand ils existent', () {
      final guilds = parseGuildsApiPayload(
        '[{"id":"$_guildA","name":"Alpha","icon":null,"owner":true,'
        '"approximate_member_count":1234},'
        '{"id":"$_guildB","name":"Bravo","owner":false}]',
      );

      expect(guilds.first.isOwner, isTrue);
      expect(guilds.first.memberCount, 1234);
      expect(guilds.last.isOwner, isFalse);
      expect(guilds.last.memberCount, isNull);
    });
  });

  group('sortGuildsForDisplay', () {
    test('est stable quel que soit l\'ordre de la source', () {
      final fromGatewayOrder = sortGuildsForDisplay([
        _guildWithoutIcon,
        _guildWithIcon,
        const GuildAvatarInfo(id: _guildC, name: 'Charlie'),
      ]);
      final reversed = sortGuildsForDisplay([
        const GuildAvatarInfo(id: _guildC, name: 'Charlie'),
        _guildWithIcon,
        _guildWithoutIcon,
      ]);

      expect(
        fromGatewayOrder.map((g) => g.id),
        orderedEquals(reversed.map((g) => g.id)),
      );
      expect(fromGatewayOrder.first.id, _guildA);
    });
  });

  group('guildPresenceSlotCount', () {
    test('suit la silhouette historique quand aucun serveur n\'est connu', () {
      expect(guildPresenceSlotCount(guildCount: 0, knownGuilds: 0), 1);
      expect(guildPresenceSlotCount(guildCount: 1, knownGuilds: 0), 1);
      expect(guildPresenceSlotCount(guildCount: 2, knownGuilds: 0), 2);
      expect(guildPresenceSlotCount(guildCount: 42, knownGuilds: 0), 2);
    });

    test('affiche les vrais serveurs, bornés par le compteur et par 2', () {
      expect(guildPresenceSlotCount(guildCount: 5, knownGuilds: 2), 2);
      expect(guildPresenceSlotCount(guildCount: 5, knownGuilds: 7), 2);
      expect(guildPresenceSlotCount(guildCount: 1, knownGuilds: 3), 1);
      expect(guildPresenceSlotCount(guildCount: 0, knownGuilds: 1), 1);
    });
  });

  group('GuildAvatarStrip', () {
    testWidgets('affiche un avatar par serveur connu, sans exception', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GuildAvatarStrip(
            botId: _guildA,
            guildCount: 2,
            guilds: <GuildAvatarInfo>[_guildWithIcon, _guildWithoutIcon],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GuildAvatarStrip), findsOneWidget);
      // `HomeBotAvatar` est réutilisé (même contrat de chargement/repli).
      expect(find.byType(HomeBotAvatar), findsNWidgets(2));
      expect(tester.takeException(), isNull);

      // Le réseau est coupé en test (HTTP 400) : les deux icônes basculent sur
      // leur repli, donc sur la vraie initiale des serveurs.
      await tester.pump();
      expect(find.text('S'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('ne fabrique aucune lettre sans serveur connu', (tester) async {
      var loaderCalls = 0;
      await tester.pumpWidget(
        _wrap(
          GuildAvatarStrip(
            botId: _guildA,
            guildCount: 2,
            remoteLoader: (botId) async {
              loaderCalls++;
              return const <GuildAvatarInfo>[];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loaderCalls, 1);
      expect(find.byType(HomeBotAvatar), findsNWidgets(2));
      // Repli neutre : icône serveur, aucun texte (donc aucune lettre).
      expect(find.byIcon(Icons.dns_rounded), findsNWidgets(2));
      expect(find.byType(Text), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('un seul cercle neutre quand le compteur est à zéro', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          GuildAvatarStrip(
            botId: _guildA,
            guildCount: 0,
            remoteLoader: (_) async => const <GuildAvatarInfo>[],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeBotAvatar), findsOneWidget);
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
    });

    testWidgets('préfère le cache du gateway et n\'appelle pas le REST', (
      tester,
    ) async {
      var loaderCalls = 0;
      await tester.pumpWidget(
        _wrap(
          GuildAvatarStrip(
            botId: _guildA,
            guildCount: 2,
            guilds: const <GuildAvatarInfo>[_guildWithIcon, _guildWithoutIcon],
            remoteLoader: (_) async {
              loaderCalls++;
              return const <GuildAvatarInfo>[];
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(loaderCalls, 0);
      expect(find.byType(HomeBotAvatar), findsNWidgets(2));
    });

    testWidgets('adopte la liste REST quand elle arrive après coup', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          GuildAvatarStrip(
            botId: _guildA,
            guildCount: 3,
            remoteLoader: (_) async => const <GuildAvatarInfo>[
              _guildWithIcon,
              _guildWithoutIcon,
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeBotAvatar), findsNWidgets(2));
      expect(find.text('S'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets(
      'peint la liste de session déjà chargée sans nouvelle requête',
      (tester) async {
        var hits = 0;
        final directory = _countingDirectory(onFetch: () => hits++);
        // La page « Serveurs » (ou une autre carte) a déjà rempli la session.
        await directory.load(_guildA);
        expect(hits, 1);

        await tester.pumpWidget(
          _wrap(
            GuildAvatarStrip(
              botId: _guildA,
              guildCount: 1,
              directory: directory,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(hits, 1, reason: 'une seule requête pour toute la session');
        expect(find.byType(HomeBotAvatar), findsOneWidget);
        expect(find.text('B'), findsOneWidget);
      },
    );

    testWidgets('pendant le chargement : repli neutre, puis avatars, un GET', (
      tester,
    ) async {
      var hits = 0;
      final gate = Completer<void>();
      final directory = GuildDirectory(
        guildsEndpoint: _fakeEndpoint,
        tokenResolver: (_) async => 'bot-token',
        httpGet: (endpoint, token) async {
          hits++;
          await gate.future;
          return '[{"id":"$_guildA","name":"Serveur Alpha","icon":null},'
              '{"id":"$_guildB","name":"Bravo","icon":null}]';
        },
      );

      await tester.pumpWidget(
        _wrap(
          GuildAvatarStrip(botId: _guildA, guildCount: 2, directory: directory),
        ),
      );
      await tester.pump();

      // État `loading` : deux cercles neutres, aucune lettre inventée.
      expect(find.byIcon(Icons.dns_rounded), findsNWidgets(2));
      expect(find.byType(Text), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(hits, 1);
      expect(find.text('S'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });
  });
}
