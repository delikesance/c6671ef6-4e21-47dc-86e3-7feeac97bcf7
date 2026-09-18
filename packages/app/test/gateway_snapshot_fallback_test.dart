// Le repli HTTP de l'accueil (WebSocket coupée) faisait UNE requête PAR bot toutes les
// 60 s. Ces tests verrouillent son remplacement par le snapshot agrégé
// (`GET /gateway/snapshot`) : un appel ramène tout l'état, le `304` évite de tout
// réappliquer quand rien n'a changé, et — exigence non négociable — un `404`
// (manager plus ancien) fait retomber sur le chemin historique « une requête par bot ».
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Charge utile servie par `GET /gateway/snapshot` : les mêmes clés que celles poussées
/// par le canal temps réel (contrat partagé entre les deux sources).
Map<String, dynamic> snapshotPayload() => <String, dynamic>{
  'account': <String, dynamic>{
    'plan': 'PREMIUM',
    'tier_code': 'PRO',
    'display_name': 'Pro',
    'max_bots': 5,
    'max_turnkey_bots': 2,
    'allow_own_bots': false,
    'allow_turnkey': true,
    'provider': 'apple_in_app',
    'expires_at': '2030-01-01T00:00:00Z',
  },
  'bots': <dynamic>[
    <String, dynamic>{
      'bot_id': 'bot-1',
      'bot_name': 'Bot',
      'desired_state': 'RUNNING',
      'last_runtime_state': 'running',
      'funding_mode': 'free',
      'free_minutes_balance': 42,
      'session_expires_at': '2030-01-01T00:00:00Z',
    },
  ],
  'containers': const <dynamic>[],
};

/// Client factice du repli : il COMPTE les appels, car le sujet du test est le nombre de
/// requêtes (1 au lieu de N) et le fait que rien n'est appliqué sur un 304.
class FakeSnapshotFetcher {
  FakeSnapshotFetcher({
    this.payload,
    this.returnNotModified = false,
    this.error,
  });

  /// `null` = charge utile par défaut de [snapshotPayload].
  final Map<String, dynamic>? payload;

  /// `true` = le serveur répond `304` ; le client rend alors `null`.
  final bool returnNotModified;

  /// Exception simulée : `MainApiClientException(statusCode: 404)` = manager ancien.
  final Object? error;

  int calls = 0;
  final List<String?> etags = <String?>[];

  Future<GatewaySnapshotResponse?> call({String? etag}) async {
    calls++;
    etags.add(etag);
    final failure = error;
    if (failure != null) throw failure;
    if (returnNotModified) return null;
    return GatewaySnapshotResponse(
      payload: payload ?? snapshotPayload(),
      etag: 'W/"v1"',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // L'état de formule est statique : sans remise à zéro, le PREMIUM appliqué par un
    // test fuiterait dans le suivant (et masquerait un « rien n'est appliqué »).
    await SubscriptionService.debugResetForTests();
    SubscriptionService.debugSetDesktopForTests(false);
    SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
  });

  group('client API — GET /gateway/snapshot', () {
    test('un 200 rend la charge utile et l\'ETag, et envoie If-None-Match', () async {
      final requests = <http.Request>[];
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode(snapshotPayload()),
            200,
            headers: <String, String>{
              'content-type': 'application/json',
              // Go renvoie l'entête en majuscules : la lecture ne doit pas en dépendre.
              'ETag': 'W/"v7"',
            },
          );
        }),
      );

      final snapshot = await client.getGatewaySnapshotWithEtag(etag: 'W/"v6"');

      expect(requests, hasLength(1));
      expect(requests.single.url.path, '/gateway/snapshot');
      expect(requests.single.headers['If-None-Match'], 'W/"v6"');
      expect(snapshot, isNotNull);
      expect(snapshot!.etag, 'W/"v7"');
      expect(snapshot.payload['bots'], hasLength(1));

      // La variante sans ETag porte exactement la même charge utile.
      final payload = await client.getGatewaySnapshot();
      expect(payload?['bots'], hasLength(1));
      expect(payload?.containsKey('account'), isTrue);
    });

    test('un 304 rend null (rien à réappliquer) sans lever', () async {
      var calls = 0;
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          calls++;
          return http.Response(
            '',
            304,
            headers: <String, String>{'ETag': 'W/"v7"'},
          );
        }),
      );

      expect(await client.getGatewaySnapshot(etag: 'W/"v7"'), isNull);
      expect(await client.getGatewaySnapshotWithEtag(etag: 'W/"v7"'), isNull);
      expect(calls, 2);
    });

    test('un 404 lève une exception porteuse du statut (manager ancien)', () async {
      var calls = 0;
      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          calls++;
          return http.Response('{"error":"not_found"}', 404);
        }),
      );

      await expectLater(
        client.getGatewaySnapshotWithEtag(),
        throwsA(
          isA<MainApiClientException>().having(
            (error) => error.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      expect(calls, 1, reason: 'un 404 est définitif : aucune reprise automatique');
    });
  });

  group('repli de l\'accueil', () {
    test('un 200 applique les bots et le compte, en une seule requête', () async {
      final fetcher = FakeSnapshotFetcher();
      final applied = <HomeSnapshotData>[];
      var perBotRequests = 0;

      final outcome = await refreshHomeFromGatewaySnapshot(
        fetchSnapshot: fetcher.call,
        etag: null,
        applySnapshot: (snapshot) async {
          applied.add(snapshot);
          final account = snapshot.account;
          if (account != null) {
            // Exactement ce que fait `_applyPushedAccount` côté accueil.
            await SubscriptionService.applyPushedAccountState(
              account.toRuntimeMap(),
            );
          }
        },
        fallbackToPerBotRefresh: () async {
          perBotRequests++;
        },
      );

      expect(outcome, HomeSnapshotOutcome.applied);
      expect(fetcher.calls, 1, reason: 'une requête pour tout l\'état');
      expect(fetcher.etags.single, isNull, reason: 'aucun ETag au premier appel');
      expect(applied, hasLength(1));
      expect(applied.single.bots, hasLength(1));
      expect(applied.single.bots.single.botId, 'bot-1');
      expect(applied.single.bots.single.isRunning, isTrue);
      expect(applied.single.etag, 'W/"v1"');
      // Le compte est bien appliqué : la formule PREMIUM du snapshot prend effet.
      expect(SubscriptionService.isSubscribed, isTrue);
      expect(SubscriptionService.activePlanDisplayName, 'Pro');
      expect(SubscriptionService.activePlanMaxBots, 5);
      expect(perBotRequests, 0, reason: 'aucun repli par bot sur un 200');
    });

    test('un 304 n\'applique rien et ne casse rien', () async {
      final fetcher = FakeSnapshotFetcher(returnNotModified: true);
      var applied = 0;
      var perBotRequests = 0;

      final outcome = await refreshHomeFromGatewaySnapshot(
        fetchSnapshot: fetcher.call,
        etag: 'W/"v1"',
        applySnapshot: (snapshot) async {
          applied++;
        },
        fallbackToPerBotRefresh: () async {
          perBotRequests++;
        },
      );

      expect(outcome, HomeSnapshotOutcome.notModified);
      expect(fetcher.calls, 1);
      expect(fetcher.etags.single, 'W/"v1"');
      expect(applied, 0, reason: 'un 304 ne réapplique rien : c\'est le but de l\'ETag');
      expect(perBotRequests, 0);
      expect(SubscriptionService.isSubscribed, isFalse);
    });

    test('un 404 (manager plus ancien) retombe sur une requête par bot', () async {
      final fetcher = FakeSnapshotFetcher(
        error: const MainApiClientException(
          'GET /gateway/snapshot failed with 404',
          statusCode: 404,
        ),
      );
      var applied = 0;
      var perBotRefreshes = 0;

      final outcome = await refreshHomeFromGatewaySnapshot(
        fetchSnapshot: fetcher.call,
        etag: 'W/"v1"',
        applySnapshot: (snapshot) async {
          applied++;
        },
        fallbackToPerBotRefresh: () async {
          perBotRefreshes++;
        },
      );

      expect(outcome, HomeSnapshotOutcome.fellBack);
      expect(perBotRefreshes, 1, reason: 'le chemin historique doit bien s\'exécuter');
      expect(applied, 0, reason: 'rien n\'est appliqué depuis un snapshot inexistant');
    });

    test('une panne réseau retombe aussi sur le repli historique', () async {
      final fetcher = FakeSnapshotFetcher(
        error: http.ClientException('connection refused'),
      );
      var perBotRefreshes = 0;

      final outcome = await refreshHomeFromGatewaySnapshot(
        fetchSnapshot: fetcher.call,
        etag: null,
        applySnapshot: (snapshot) async {},
        fallbackToPerBotRefresh: () async {
          perBotRefreshes++;
        },
      );

      expect(outcome, HomeSnapshotOutcome.fellBack);
      expect(perBotRefreshes, 1);
    });

    test('cinq ticks sans changement : cinq requêtes de snapshot, une application', () async {
      final payload = snapshotPayload();
      var requests = 0;
      var applied = 0;
      var perBotRequests = 0;
      // Mémorisation de l'ETag : c'est le rôle de `_snapshotEtag` dans l'accueil.
      String? etag;

      Future<GatewaySnapshotResponse?> fetch({String? etag}) async {
        requests++;
        if (etag == 'W/"v1"') return null; // 304 : rien n'a changé
        return GatewaySnapshotResponse(payload: payload, etag: 'W/"v1"');
      }

      for (var tick = 0; tick < 5; tick++) {
        final outcome = await refreshHomeFromGatewaySnapshot(
          fetchSnapshot: fetch,
          etag: etag,
          applySnapshot: (snapshot) async {
            applied++;
            etag = snapshot.etag ?? etag;
          },
          fallbackToPerBotRefresh: () async {
            // 3 bots : c'est ce que coûtait un tick de l'ancien repli (N requêtes).
            perBotRequests += 3;
          },
        );
        expect(outcome, isNot(HomeSnapshotOutcome.fellBack));
      }

      expect(requests, 5, reason: 'une requête par tick, pas une par bot');
      expect(applied, 1, reason: 'les quatre ticks suivants sont des 304');
      expect(perBotRequests, 0, reason: 'l\'ancien repli aurait fait 5 × 3 = 15 requêtes');
    });
  });
}
