// Le repli HTTP de l'accueil (WebSocket coupée) faisait UNE requête PAR bot toutes les
// 60 s. Ces tests verrouillent son remplacement par le snapshot agrégé
// (`GET /gateway/snapshot`) : un appel ramène tout l'état, le `304` évite de tout
// réappliquer quand rien n'a changé, et — exigence non négociable — un `404`
// (manager plus ancien) fait retomber sur le chemin historique « une requête par bot ».
//
// Les trois déclencheurs du repli sont couverts : le tick de 60 s (tests de la
// fonction), la reprise d'application et la perte de connexion WebSocket (tests de
// widget sur le vrai `HomePage`, qui appelaient encore une requête par bot).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/home/presentation/home_page.dart';
import 'package:bot_creator/features/onboarding/logic/onboarding_manager.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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
    this.gate,
  });

  /// `null` = charge utile par défaut de [snapshotPayload].
  final Map<String, dynamic>? payload;

  /// `true` = le serveur répond `304` ; le client rend alors `null`.
  final bool returnNotModified;

  /// Exception simulée : `MainApiClientException(statusCode: 404)` = manager ancien.
  final Object? error;

  /// Barrière optionnelle : l'appel est COMPTÉ puis reste en vol jusqu'à ce que le test
  /// la libère. C'est ce qu'il faut pour vérifier qu'un second déclencheur ne superpose
  /// pas un repli à celui déjà en cours.
  final Completer<void>? gate;

  int calls = 0;
  final List<String?> etags = <String?>[];

  Future<GatewaySnapshotResponse?> call({String? etag}) async {
    calls++;
    etags.add(etag);
    final pending = gate;
    if (pending != null) await pending.future;
    final failure = error;
    if (failure != null) throw failure;
    if (returnNotModified) return null;
    return GatewaySnapshotResponse(
      payload: payload ?? snapshotPayload(),
      etag: 'W/"v1"',
    );
  }
}

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    // Le vrai `HomePage` est monté par les tests de déclencheurs : il lui faut une base
    // SQLite (sqflite ffi) et un dossier `path_provider` simulé, comme le shell.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp(
      'gateway_snapshot_fallback_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
    // Aucune requête réseau pour les polices : les familles utilisées par l'accueil sont
    // bundlées en assets, et le flag fait échouer toute famille non bundlée au lieu d'un
    // fetch silencieux (indisponible en test).
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Fichiers SQLite verrouillés : sans importance pour le test.
      }
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // L'état de formule est statique : sans remise à zéro, le PREMIUM appliqué par un
    // test fuiterait dans le suivant (et masquerait un « rien n'est appliqué »).
    await SubscriptionService.debugResetForTests();
    SubscriptionService.debugSetDesktopForTests(false);
    SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
    // Les greffons de test ne doivent jamais fuiter d'un test à l'autre : un repli qui
    // partirait avec le client factice d'un test précédent fausserait le compte.
    HomePageState.debugSnapshotFetcherOverride = null;
    HomePageState.debugPerBotRefreshOverride = null;
  });

  /// Monte le vrai `HomePage`, exécute [body] sur son état, puis démonte l'arbre.
  ///
  /// Les deux déclencheurs sont des méthodes de cet état : « prouver le recâblage »
  /// demande donc l'arbre réel. Le démontage doit avoir lieu DANS le corps du test
  /// (avant la vérification des invariants de `flutter_test`) : le `Timer.periodic` de
  /// 15 s de l'accueil et le timer d'expiration de formule (le snapshot applique un plan
  /// PREMIUM dont l'échéance est en 2030) seraient sinon vus comme « A Timer is still
  /// pending even after the widget tree was disposed ».
  ///
  /// Aucun `debugDefaultTargetPlatformOverride` : l'accueil branche ses capacités sur
  /// `dart:io` (`Platform.isLinux`, …), déjà stable en test, et forcer la variable
  /// globale ferait échouer « a foundation debug variable was changed by the test ».
  Future<void> runHomePageTriggerTest(
    WidgetTester tester,
    Future<void> Function(HomePageState state) body,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          Provider(create: (_) => OnboardingManager(prefs)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: ThemeMode.dark,
          home: const HomePage(),
        ),
      ),
    );
    // `pump` borné (jamais `pumpAndSettle`) : l'accueil déclenche du réseau et un
    // `Timer.periodic`, `pumpAndSettle` ne se stabiliserait pas.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final state = tester.state<HomePageState>(find.byType(HomePage));
    try {
      await body(state);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      SubscriptionService.dispose();
      // Le service de rich presence (singleton global) programme un timer de ~10 s :
      // on avance l'horloge simulée pour le faire expirer avant les invariants finaux.
      await tester.pump(const Duration(seconds: 12));
      await tester.pump();
    }
  }

  /// Laisse tourner les microtâches d'un repli (résolution du client factice, application
  /// du compte) sans avancer d'une seconde d'horloge simulée : « immédiat » ne veut pas
  /// dire « au tick suivant ».
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  /// Rejoue une reprise d'application : l'accueil ne réagit qu'au passage à `resumed`
  /// (une reprise depuis `paused`, comme sur un vrai téléphone).
  void resumeApp(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

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

  // ── Les deux autres déclencheurs du repli ───────────────────────────────────────
  //
  // Le tick de 60 s ci-dessus passe par la fonction ; la reprise d'application et la
  // perte de connexion WebSocket, elles, appelaient `_initRunningState()` — une requête
  // PAR bot. Ces tests montent le vrai `HomePage` et déclenchent ses méthodes d'état :
  // rejouer la logique avec des doublures ne prouverait pas que l'accueil est recâblé.
  group('déclencheurs du repli (reprise d\'app, perte de WebSocket)', () {
    testWidgets(
      'une reprise d\'application part sur le snapshot : 1 requête, pas N',
      (tester) async {
        final fetcher = FakeSnapshotFetcher();
        var perBotRefreshes = 0;
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;
        HomePageState.debugPerBotRefreshOverride = () async {
          perBotRefreshes++;
        };

        await runHomePageTriggerTest(tester, (state) async {
          resumeApp(tester);
          // Quelques dizaines de millisecondes seulement : le snapshot doit partir tout
          // de suite, l'attente du tick de 60 s est justement ce qu'on supprime.
          await settle(tester);

          expect(fetcher.calls, 1, reason: 'une seule requête pour tout l\'état');
          expect(fetcher.etags.single, isNull, reason: 'premier appel : aucun ETag');
          expect(
            perBotRefreshes,
            0,
            reason: 'l\'ancien chemin faisait une requête par bot locale',
          );
          // Le snapshot est APPLIQUÉ (compte PREMIUM) : ce n'est pas qu'un appel réseau.
          expect(SubscriptionService.isSubscribed, isTrue);
          expect(SubscriptionService.activePlanDisplayName, 'Pro');
        });
      },
    );

    testWidgets(
      'une reprise d\'application dont le snapshot échoue retombe sur une requête '
      'par bot',
      (tester) async {
        final fetcher = FakeSnapshotFetcher(
          error: const MainApiClientException(
            'GET /gateway/snapshot failed with 404',
            statusCode: 404,
          ),
        );
        var perBotRefreshes = 0;
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;
        HomePageState.debugPerBotRefreshOverride = () async {
          perBotRefreshes++;
        };

        await runHomePageTriggerTest(tester, (state) async {
          resumeApp(tester);
          await settle(tester);

          expect(fetcher.calls, 1, reason: 'le snapshot n\'est tenté qu\'une fois');
          expect(
            perBotRefreshes,
            1,
            reason: 'manager plus ancien : le repli historique doit reprendre la main',
          );
          expect(
            SubscriptionService.isSubscribed,
            isFalse,
            reason: 'rien n\'est appliqué depuis un snapshot inexistant',
          );
        });
      },
    );

    testWidgets(
      'une perte de connexion WebSocket part sur le snapshot : 1 requête, pas N',
      (tester) async {
        final fetcher = FakeSnapshotFetcher();
        var perBotRefreshes = 0;
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;
        HomePageState.debugPerBotRefreshOverride = () async {
          perBotRefreshes++;
        };

        await runHomePageTriggerTest(tester, (state) async {
          // WebSocket vivante : l'état arrive par le canal temps réel, aucun repli HTTP.
          state.handleGatewayConnectionChange(true);
          await settle(tester);
          expect(fetcher.calls, 0, reason: 'pas de repli tant que la WebSocket tient');

          state.handleGatewayConnectionChange(false);
          await settle(tester);

          expect(fetcher.calls, 1, reason: 'une seule requête pour tout l\'état');
          expect(perBotRefreshes, 0);
          expect(SubscriptionService.isSubscribed, isTrue);
        });
      },
    );

    testWidgets(
      'une perte de connexion dont le snapshot échoue retombe sur une requête par bot',
      (tester) async {
        final fetcher = FakeSnapshotFetcher(
          error: http.ClientException('connection refused'),
        );
        var perBotRefreshes = 0;
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;
        HomePageState.debugPerBotRefreshOverride = () async {
          perBotRefreshes++;
        };

        await runHomePageTriggerTest(tester, (state) async {
          state.handleGatewayConnectionChange(false);
          await settle(tester);

          expect(fetcher.calls, 1);
          expect(
            perBotRefreshes,
            1,
            reason: 'panne réseau : le repli historique doit reprendre la main',
          );
        });
      },
    );

    testWidgets(
      'le garde de réentrance couvre les nouveaux déclencheurs : un repli en vol '
      'n\'est pas doublé',
      (tester) async {
        final gate = Completer<void>();
        final fetcher = FakeSnapshotFetcher(gate: gate);
        var perBotRefreshes = 0;
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;
        HomePageState.debugPerBotRefreshOverride = () async {
          perBotRefreshes++;
        };

        await runHomePageTriggerTest(tester, (state) async {
          // Premier repli (reprise d'app) laissé volontairement EN VOL.
          resumeApp(tester);
          await tester.pump();
          expect(fetcher.calls, 1);

          // Perte de connexion pendant ce vol : elle ne doit pas superposer un repli.
          state.handleGatewayConnectionChange(false);
          await settle(tester);
          expect(
            fetcher.calls,
            1,
            reason: 'le second déclencheur ne relance pas un snapshot déjà en cours',
          );
          expect(perBotRefreshes, 0);

          // Une fois le premier repli terminé, le garde se libère pour les suivants.
          gate.complete();
          await settle(tester);
          resumeApp(tester);
          await settle(tester);
          expect(fetcher.calls, 2, reason: 'le garde doit se relâcher après le repli');
        });
      },
    );

    testWidgets(
      'après un repli, le drapeau WebSocket reste à faux : le repli de secours '
      'continue de se relancer',
      (tester) async {
        final fetcher = FakeSnapshotFetcher();
        HomePageState.debugSnapshotFetcherOverride = fetcher.call;

        await runHomePageTriggerTest(tester, (state) async {
          resumeApp(tester);
          await settle(tester);
          expect(fetcher.calls, 1);

          // 61 s plus tard, le ticker de repli doit avoir refait des snapshots. C'est la
          // preuve que `_gatewayEventsConnected` est resté à faux après application :
          // s'il passait à vrai, le ticker se croirait reconnecté et ne relancerait
          // plus rien (l'accueil ne se rafraîchirait jamais tant que la WebSocket est
          // coupée). L'attente porte sur le FAIT (le repli se relance encore), pas sur
          // la cadence : elle était de 60 s, elle est de 15 s depuis la décision de
          // corriger plus vite un statut resté faux, et ce test n'a pas à la figer.
          await tester.pump(const Duration(seconds: 61));
          await settle(tester);
          expect(
            fetcher.calls,
            greaterThan(2),
            reason: 'le drapeau ne doit pas faire croire que la WebSocket est revenue',
          );
        });
      },
    );
  });
}
