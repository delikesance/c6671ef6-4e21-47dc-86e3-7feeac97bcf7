// Sémantique du cache de *session* de `GuildDirectory`.
//
// Contrat verrouillé ici (demande produit : « actualisation des serveurs au
// chargement puis caching jusqu'au redémarrage de l'app ») :
//
//   * une seule requête HTTP par bot pour toute la session, quel que soit le
//     nombre de `load()` (carte bot de la Home, page « Serveurs », rebuilds) ;
//   * `refresh()` force une requête supplémentaire et remplace l'entrée ;
//   * un échec (token absent, transport en erreur, exception) ne met RIEN en
//     cache : le prochain `load()` retente réellement ;
//   * deux appels concurrents partagent la requête en vol ;
//   * l'état observable (`watch`) publie idle → loading → loaded|error, et
//     deux écrans abonnés ne déclenchent qu'une requête ;
//   * `clearCache()` repart de zéro (redémarrage applicatif).
//
// Aucun test ne touche le réseau : `httpGet` et `tokenResolver` sont injectés.
// Seul le test de transport réel ouvre un `HttpServer` sur la boucle locale.
import 'dart:async';
import 'dart:io';

import 'package:bot_creator/features/home/presentation/guild_avatar.dart';
import 'package:flutter_test/flutter_test.dart';

/// `HttpOverrides` neutres : rendent le vrai `HttpClient` (le binding de
/// `flutter_test` installe sinon un client bouchonné qui répond 400).
class _RealHttpOverrides extends HttpOverrides {}

/// Snowflakes réalistes (19 chiffres) pour un tri déterministe.
const String _guildA = '1000000000000000001';
const String _guildB = '1000000000000000002';

const String _botId = 'bot-1';
const String _endpoint = 'https://example.invalid/users/@me/guilds';

const String _alphaPayload = '[{"id":"$_guildA","name":"Alpha","icon":null}]';

/// Charge utile riche : icône, propriétaire et compteur de membres.
const String _bravoPayload =
    '[{"id":"$_guildB","name":"Bravo","icon":"deadbeef","owner":true,'
    '"approximate_member_count":42}]';

void main() {
  test('une seule requête HTTP par bot pour plusieurs load()', () async {
    var hits = 0;
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async {
        hits++;
        return _bravoPayload;
      },
    );

    final first = await directory.load(_botId);
    final second = await directory.load(_botId);
    final third = await directory.load(_botId);

    expect(hits, 1, reason: 'la session ne doit faire qu\'un GET par bot');
    expect(first, hasLength(1));
    expect(second.single.id, _guildB);
    expect(third, first);
    expect(second.single.isOwner, isTrue);
    expect(second.single.memberCount, 42);
  });

  test('refresh() force une seconde requête et remplace l\'entrée', () async {
    var hits = 0;
    var payload = _alphaPayload;
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async {
        hits++;
        return payload;
      },
    );

    expect((await directory.load(_botId)).single.id, _guildA);
    expect(hits, 1);

    // Côté Discord, la liste a changé : seul `refresh` la rapatrie.
    payload = _bravoPayload;
    expect((await directory.load(_botId)).single.id, _guildA);
    expect(hits, 1, reason: 'un load() de plus ne doit rien rejouer');

    final refreshed = await directory.refresh(_botId);
    expect(hits, 2);
    expect(refreshed.single.id, _guildB);

    // L'entrée de session a bien été remplacée : plus aucune requête ensuite.
    expect((await directory.load(_botId)).single.id, _guildB);
    expect(hits, 2);
  });

  test(
    'un échec réseau n\'est pas mis en cache et le prochain load retente',
    () async {
      var hits = 0;
      var failing = true;
      final directory = GuildDirectory(
        guildsEndpoint: _endpoint,
        tokenResolver: (_) async => 'bot-token',
        httpGet: (endpoint, token) async {
          hits++;
          return failing ? null : _alphaPayload;
        },
      );

      expect(await directory.load(_botId), isEmpty);
      expect(directory.watch(_botId).value.status, GuildsLoadStatus.error);

      // Rien n'a été mis en cache : le second appel retente vraiment.
      expect(await directory.load(_botId), isEmpty);
      expect(hits, 2);

      failing = false;
      expect(await directory.load(_botId), hasLength(1));
      expect(hits, 3);
      expect(directory.watch(_botId).value.status, GuildsLoadStatus.loaded);
    },
  );

  test('une exception du transport est avalée (jamais propagée)', () async {
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async => throw StateError('offline'),
    );

    expect(await directory.load(_botId), isEmpty);
    final state = directory.watch(_botId).value;
    expect(state.status, GuildsLoadStatus.error);
    expect(state.errorMessage, isNotNull);
  });

  test('deux load() concurrents partagent la requête en vol', () async {
    var hits = 0;
    final gate = Completer<void>();
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async {
        hits++;
        await gate.future;
        return _alphaPayload;
      },
    );

    final both = Future.wait([directory.load(_botId), directory.load(_botId)]);
    gate.complete();
    final results = await both;

    expect(hits, 1);
    expect(results.first, hasLength(1));
    expect(results.last, hasLength(1));
  });

  test(
    'l\'état partagé publie loading puis loaded, une fois par bot',
    () async {
      var hits = 0;
      final gate = Completer<void>();
      final directory = GuildDirectory(
        guildsEndpoint: _endpoint,
        tokenResolver: (_) async => 'bot-token',
        httpGet: (endpoint, token) async {
          hits++;
          await gate.future;
          return _alphaPayload;
        },
      );

      final seen = <GuildsLoadStatus>[];
      final state = directory.watch(_botId);
      state.addListener(() => seen.add(state.value.status));

      final loading = directory.load(_botId);
      expect(state.value.status, GuildsLoadStatus.loading);

      gate.complete();
      await loading;

      expect(state.value.isLoaded, isTrue);
      expect(state.value.guilds.single.id, _guildA);
      expect(seen, [GuildsLoadStatus.loading, GuildsLoadStatus.loaded]);

      // Deuxième « écran » : même objet d'état, aucune requête de plus.
      expect(directory.watch(_botId), same(state));
      await directory.load(_botId);
      expect(hits, 1);

      // Un identifiant vide ne crée jamais d'entrée.
      await directory.load('   ');
      expect(directory.watch(''), isNot(same(state)));
      expect(hits, 1);
    },
  );

  test('sans token configuré : aucune requête, état en erreur', () async {
    var hits = 0;
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => null,
      httpGet: (endpoint, token) async {
        hits++;
        return _alphaPayload;
      },
    );

    expect(await directory.load(_botId), isEmpty);
    expect(hits, 0);
    expect(directory.watch(_botId).value.status, GuildsLoadStatus.error);
  });

  test(
    'un résultat vide n\'est pas mis en cache (mais l\'état est publié)',
    () async {
      var hits = 0;
      final directory = GuildDirectory(
        guildsEndpoint: _endpoint,
        tokenResolver: (_) async => 'bot-token',
        httpGet: (endpoint, token) async {
          hits++;
          return '[]';
        },
      );

      expect(await directory.load(_botId), isEmpty);
      expect(await directory.load(_botId), isEmpty);
      expect(hits, 2, reason: 'une liste vide doit pouvoir être retentée');
      expect(directory.watch(_botId).value.status, GuildsLoadStatus.loaded);
    },
  );

  test(
    'clearCache() remet l\'état à idle et force une nouvelle requête',
    () async {
      var hits = 0;
      final directory = GuildDirectory(
        guildsEndpoint: _endpoint,
        tokenResolver: (_) async => 'bot-token',
        httpGet: (endpoint, token) async {
          hits++;
          return _alphaPayload;
        },
      );

      final state = directory.watch(_botId);
      await directory.load(_botId);
      expect(hits, 1);
      expect(state.value.isLoaded, isTrue);

      directory.clearCache();

      expect(state.value, GuildsLoadState.idle);
      await directory.load(_botId);
      expect(hits, 2);
    },
  );

  test('sérialise les requêtes (jamais deux en vol)', () async {
    var inFlight = 0;
    var maxInFlight = 0;
    final directory = GuildDirectory(
      guildsEndpoint: _endpoint,
      tokenResolver: (_) async => 'bot-token',
      httpGet: (endpoint, token) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        inFlight--;
        return _alphaPayload;
      },
    );

    await Future.wait([
      directory.load('bot-1'),
      directory.load('bot-2'),
      directory.load('bot-3'),
    ]);

    expect(maxInFlight, 1);
  });

  test(
    'transport HTTP réel : en-tête Bot envoyé, réponse parsée, un seul GET',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      String? authorization;
      String? withCounts;
      var requests = 0;
      server.listen((request) async {
        requests++;
        authorization = request.headers.value(HttpHeaders.authorizationHeader);
        withCounts = request.uri.queryParameters['with_counts'];
        request.response
          ..statusCode = 200
          ..write(_bravoPayload);
        await request.response.close();
      });

      final directory = GuildDirectory(
        guildsEndpoint:
            'http://127.0.0.1:${server.port}/users/@me/guilds?with_counts=true',
        tokenResolver: (_) async => 'secret-token',
      );

      // Client HTTP réel : `TestWidgetsFlutterBinding` bouchonne `HttpClient`.
      final guilds = await HttpOverrides.runWithHttpOverrides(
        () => directory.load('bot-1'),
        _RealHttpOverrides(),
      );
      final again = await directory.load('bot-1');

      expect(authorization, 'Bot secret-token');
      expect(withCounts, 'true');
      expect(guilds.single.id, _guildB);
      expect(again.single.id, _guildB);
      expect(requests, 1, reason: 'le second load doit venir de la session');
      expect(
        guilds.single.iconUrl,
        'https://cdn.discordapp.com/icons/$_guildB/deadbeef.png?size=128',
      );
    },
  );
}
