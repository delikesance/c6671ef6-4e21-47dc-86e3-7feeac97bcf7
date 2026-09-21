// L'accueil câblait le canal temps réel en RECRÉANT la session à chaque appel
// (`initState`, puis chaque reprise d'application) et en annulant les abonnements de la
// précédente. Le canal en place — celui qui porte l'état des bots et du compte — était
// donc détruit en boucle : dans les journaux de l'utilisateur, une alternance sans fin
// « canal temps réel rétabli » / « indisponible », et un indicateur de connexion qui
// retombait à « Hors ligne » alors que le serveur exécutait bien les bots.
//
// Ces tests montent le VRAI `HomePage` et passent par la VRAIE méthode de câblage de
// l'accueil, par son déclencheur de production : la reprise d'application
// (`didChangeAppLifecycleState`). Pour le MÊME serveur, un appel de plus ne doit RIEN
// recréer et ne rien casser ; pour un autre serveur, l'ancienne session doit être
// réellement LIBÉRÉE (WebSocket fermée).
//
// Aucun réseau réel : le canal est un faux WebSocket piloté par le test, et le client
// manager est injecté par la couture `debugGatewayEventsClientOverride`.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/gateway_bot_events.dart';
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
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Message `account.updated` poussé par le serveur : c'est l'observable du test — s'il
/// n'atteint plus l'application, c'est que l'abonnement au canal a été cassé.
String accountUpdatedEvent() => jsonEncode(<String, dynamic>{
  'type': 'account.updated',
  'owner_id': 'owner-1',
  'account': <String, dynamic>{
    'plan': 'PREMIUM',
    'tier_code': 'PRO',
    'display_name': 'Pro',
    'max_bots': 5,
    'max_turnkey_bots': 2,
    'allow_own_bots': true,
    'allow_turnkey': true,
  },
});

/// Client manager de test : seule sa `baseUrl` compte pour l'accueil (elle identifie le
/// serveur), et aucune requête HTTP n'est émise sur ce chemin.
MainApiClient testManagerClient(String baseUrl) =>
    MainApiClient(baseUrl: baseUrl, accessToken: 'token-de-test');

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late List<_FakeChannel> channels;

  setUpAll(() async {
    // Le vrai `HomePage` est monté : il lui faut une base SQLite (sqflite ffi) et un
    // dossier `path_provider` simulé, comme le shell de l'application.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp(
      'gateway_events_idempotence_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
    // Aucune requête réseau pour les polices : le flag fait échouer une famille non
    // bundlée au lieu d'un fetch silencieux, impossible en test.
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
    await SubscriptionService.debugResetForTests();
    SubscriptionService.debugSetDesktopForTests(false);
    SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
    // Les coutures de test ne doivent jamais fuiter d'un test à l'autre.
    HomePageState.debugSnapshotFetcherOverride = null;
    HomePageState.debugGatewayEventsClientOverride = testManagerClient(
      'http://manager.test',
    );
    HomePageState.debugGatewaySessionsCreated = 0;
    // Repli par bot neutralisé : les déclencheurs de repli de l'accueil ne doivent pas se
    // mettre à travailler pendant qu'on observe le canal temps réel.
    HomePageState.debugPerBotRefreshOverride = () async {};
    channels = <_FakeChannel>[];
    GatewayBotEventsManager.debugConnectorOverride = (Uri uri) {
      final channel = _FakeChannel(uri);
      channels.add(channel);
      return channel;
    };
  });

  tearDown(() {
    HomePageState.debugSnapshotFetcherOverride = null;
    HomePageState.debugGatewayEventsClientOverride = null;
    HomePageState.debugPerBotRefreshOverride = null;
    GatewayBotEventsManager.debugConnectorOverride = null;
    // Les sessions sont gardées à l'échelle du processus : sans cette remise à zéro, la
    // session d'un test resterait vivante dans le suivant.
    GatewayBotEventsManager.resetForTest();
  });

  /// Monte le vrai `HomePage`, exécute [body] sur son état, puis démonte l'arbre.
  ///
  /// Le démontage a lieu DANS le corps du test : le `Timer.periodic` de 15 s de l'accueil
  /// et le timer du service de rich presence seraient sinon vus comme « A Timer is still
  /// pending even after the widget tree was disposed ».
  Future<void> runHomePage(
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
      await tester.pump(const Duration(seconds: 12));
      await tester.pump();
    }
  }

  /// Laisse tourner les microtâches d'un câblage sans avancer d'une seconde d'horloge
  /// simulée : « immédiat » ne veut pas dire « au tick suivant ».
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  /// Rejoue une reprise d'application : c'est le déclencheur de production du second
  /// appel au câblage, celui qui détruisait le canal vivant.
  void resumeApp(WidgetTester tester) {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  group('câblage du canal temps réel de l\'accueil', () {
    testWidgets('le premier appel câble UNE session vivante sur le serveur', (
      tester,
    ) async {
      await runHomePage(tester, (state) async {
        resumeApp(tester);
        await settle(tester);

        expect(
          HomePageState.debugGatewaySessionsCreated,
          1,
          reason: 'le premier appel câble le canal une fois, ni zéro ni deux',
        );
        final session = state.debugGatewayEventsSession;
        expect(session, isNotNull, reason: 'la session portée par l\'accueil existe');
        expect(channels, hasLength(1), reason: 'un seul WebSocket ouvert');
        expect(session!.wsUrl.path, '/gateway/bots/events');
        expect(
          session.isConnected,
          isTrue,
          reason: 'la poignée de main est acceptée : le canal est VIVANT',
        );
        expect(channels.single.sinkClosed, isFalse);
      });
    });

    testWidgets(
      'un second appel pour le MÊME serveur ne recrée RIEN et laisse le canal vivant',
      (tester) async {
        await runHomePage(tester, (state) async {
          resumeApp(tester);
          await settle(tester);
          final session = state.debugGatewayEventsSession!;
          expect(HomePageState.debugGatewaySessionsCreated, 1);
          expect(session.isConnected, isTrue);
          final channel = channels.single;

          // SECOND appel du câblage : la reprise d'application.
          resumeApp(tester);
          await settle(tester);

          expect(
            HomePageState.debugGatewaySessionsCreated,
            1,
            reason:
                'un second appel pour le MÊME serveur ne doit câbler aucune session de '
                'plus : c\'est exactement le défaut (une session neuve à chaque reprise, '
                'donc un canal détruit en boucle)',
          );
          expect(
            state.debugGatewayEventsSession,
            same(session),
            reason: 'la session vivante est conservée telle quelle',
          );
          expect(
            session.isConnected,
            isTrue,
            reason: 'le canal en place ne doit pas être fermé',
          );
          expect(
            channel.sinkClosed,
            isFalse,
            reason: 'la WebSocket vivante ne doit pas être fermée par un second appel',
          );
          expect(channels, hasLength(1), reason: 'aucun second canal ouvert');

          // Contre-épreuve : le canal conservé est bien CELUI de l'accueil, donc les
          // événements du serveur l'atteignent encore après le second appel.
          channel.push(accountUpdatedEvent());
          await settle(tester);
          expect(
            SubscriptionService.isSubscribed,
            isTrue,
            reason:
                'l\'abonnement vivant reçoit toujours les événements poussés après le '
                'second appel',
          );
          expect(SubscriptionService.activePlanDisplayName, 'Pro');
        });
      },
    );

    testWidgets(
      'changer de serveur libère l\'ancienne session et en câble une neuve',
      (tester) async {
        await runHomePage(tester, (state) async {
          resumeApp(tester);
          await settle(tester);
          final first = state.debugGatewayEventsSession!;
          final firstChannel = channels.single;
          expect(HomePageState.debugGatewaySessionsCreated, 1);

          // Autre serveur (ou autre compte) : la clé d'identité du client change.
          HomePageState.debugGatewayEventsClientOverride = testManagerClient(
            'http://autre-manager.test',
          );
          resumeApp(tester);
          await settle(tester);

          expect(
            HomePageState.debugGatewaySessionsCreated,
            2,
            reason: 'un autre serveur impose une session neuve',
          );
          final second = state.debugGatewayEventsSession;
          expect(second, isNotNull);
          expect(second, isNot(same(first)));
          expect(second!.wsUrl.host, 'autre-manager.test');
          expect(channels, hasLength(2), reason: 'le canal du nouveau serveur est ouvert');

          // Les libérations (annulation des abonnements, fermeture de la WebSocket) se
          // terminent en horloge RÉELLE : c'est le seul moment où l'accueil les laisse
          // courir — il ne les attend jamais, sinon un flux qui ne rend pas la main
          // gèlerait le câblage du nouveau serveur.
          await tester.runAsync(() async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          });
          await tester.pump();

          expect(
            firstChannel.sinkClosed,
            isTrue,
            reason:
                'l\'ancienne session est DÉTRUITE (WebSocket fermée), pas seulement '
                'débranchée de ses abonnements',
          );
          expect(
            first.isConnected,
            isFalse,
            reason: 'l\'ancienne session ne peut plus se dire connectée',
          );
        });
      },
    );
  });
}

/// Faux canal WebSocket : la poignée de main est acceptée d'emblée (le canal est donc
/// « vivant » dès l'ouverture) et les messages entrants sont poussés par le test — aucun
/// réseau réel, aucun délai réel.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri) {
    _ready.complete();
  }

  final Uri uri;
  final StreamController<dynamic> incoming =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();
  final Completer<void> _ready = Completer<void>();

  /// Pousse un message du serveur dans le canal.
  void push(String raw) => incoming.add(raw);

  /// Vrai si la session a réellement FERMÉ la WebSocket (`sink.close`), ce qui distingue
  /// « session libérée » de « abonnements simplement annulés ».
  bool get sinkClosed => _sink.closed;

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<dynamic> get stream => incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _FakeSink implements WebSocketSink {
  bool closed = false;

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  Future<void> get done => Future<void>.value();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
