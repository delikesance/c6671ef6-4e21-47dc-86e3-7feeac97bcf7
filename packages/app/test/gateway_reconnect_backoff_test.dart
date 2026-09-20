import 'dart:async';
import 'dart:math';

import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Le canal temps réel ne doit jamais marteler une infrastructure qui refuse
/// (400/502/réseau) : les tentatives s'espacent, une connexion réussie remet le
/// compteur à zéro, et une panne ne produit qu'une ligne de journal.
///
/// Toute la partie « boucle » tourne sur l'horloge simulée de `testWidgets` :
/// aucun réseau réel, aucune attente réelle.
void main() {
  group('politique de retrait progressif', () {
    test('les paliers doublent puis se plafonnent à 60 s', () {
      final backoff = GatewayReconnectBackoff(jitterRatio: 0, random: Random(1));

      final delays = <int>[
        for (var i = 0; i < 9; i++) backoff.nextDelay().inSeconds,
      ];

      expect(delays, <int>[1, 2, 4, 8, 16, 32, 60, 60, 60]);
      expect(backoff.failures, 9);
    });

    test('un refus net du serveur démarre au plancher et double', () {
      final backoff = GatewayReconnectBackoff(jitterRatio: 0, random: Random(1));

      final delays = <int>[
        for (var i = 0; i < 5; i++) backoff.nextDelay(refused: true).inSeconds,
      ];

      // 400/403/404 : inutile de retenter à 1 s et 2 s, la route refuse.
      expect(delays, <int>[10, 20, 40, 60, 60]);
    });

    test('la variation reste légère autour du palier', () {
      final backoff = GatewayReconnectBackoff(random: Random(3));
      const basesInSeconds = <int>[1, 2, 4, 8, 16, 32, 60, 60];

      for (final base in basesInSeconds) {
        final delay = backoff.nextDelay();
        expect(
          delay.inMilliseconds,
          inInclusiveRange((base * 850).floor(), (base * 1150).ceil()),
          reason: 'palier $base s',
        );
      }
    });

    test('deux appareils ne retentent pas au même instant', () {
      final delays = <int>{
        for (var seed = 0; seed < 8; seed++)
          GatewayReconnectBackoff(random: Random(seed)).nextDelay().inMilliseconds,
      };

      expect(delays.length, greaterThan(1));
    });

    test('une connexion réussie remet le compteur à zéro', () {
      final backoff = GatewayReconnectBackoff(jitterRatio: 0, random: Random(1));
      for (var i = 0; i < 3; i++) {
        backoff.nextDelay();
      }
      expect(backoff.failures, 3);

      backoff.reset();

      expect(backoff.failures, 0);
      expect(backoff.nextDelay().inSeconds, 1);
    });
  });

  group('boucle de reconnexion du canal temps réel', () {
    late List<_FakeChannel> channels;
    late List<String> logs;
    late GatewayBotEventsSession session;

    setUp(() {
      channels = <_FakeChannel>[];
      logs = <String>[];
      session = GatewayBotEventsSession(
        wsUrl: Uri.parse('ws://manager.test/gateway/bots/events'),
        headers: const <String, String>{'authorization': 'Bearer test'},
        // Sans variation : les paliers attendus sont exacts.
        backoff: GatewayReconnectBackoff(jitterRatio: 0, random: Random(1)),
        logger: logs.add,
        connector: (Uri uri) {
          final channel = _FakeChannel(uri);
          channels.add(channel);
          return channel;
        },
      );
    });

    tearDown(() async {
      await session.dispose();
    });

    testWidgets('les tentatives s\'espacent au lieu de marteler le serveur', (
      WidgetTester tester,
    ) async {
      session.start();
      await tester.pump();
      expect(channels, hasLength(1), reason: 'première tentative immédiate');

      // Le défaut de production : un 400 instantané sur la mise à niveau.
      channels.last.refuseUpgrade();
      await tester.pump();
      expect(session.isConnected, isFalse);
      expect(session.reconnectFailures, 1);

      // Refus net : premier palier à 10 s, rien avant.
      await tester.pump(const Duration(milliseconds: 9900));
      expect(channels, hasLength(1), reason: 'aucune tentative à pleine vitesse');
      await tester.pump(const Duration(milliseconds: 200));
      expect(channels, hasLength(2));
      expect(
        session.reconnectFailures,
        1,
        reason:
            'le compteur compte les ÉCHECS consécutifs, pas les tentatives : la '
            'deuxième tentative vient d\'être lancée, elle n\'a pas encore échoué',
      );

      // Deuxième palier : 20 s.
      channels.last.refuseUpgrade();
      await tester.pump(const Duration(milliseconds: 19800));
      expect(channels, hasLength(2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(channels, hasLength(3));

      // Troisième palier : 40 s.
      channels.last.refuseUpgrade();
      await tester.pump(const Duration(milliseconds: 39800));
      expect(channels, hasLength(3));
      await tester.pump(const Duration(milliseconds: 300));
      expect(channels, hasLength(4));

      // Au-delà : une tentative par minute au maximum.
      channels.last.refuseUpgrade();
      await tester.pump(const Duration(minutes: 5));
      final attemptsInFiveMinutes = channels.length - 4;
      expect(
        attemptsInFiveMinutes,
        lessThanOrEqualTo(6),
        reason: 'plafond à 60 s : au plus ~1 tentative par minute',
      );
      // Contre-épreuve : une boucle immédiate produirait des milliers de canaux.
      expect(channels.length, lessThan(12));
    });

    testWidgets('une connexion réussie remet le compteur à zéro', (
      WidgetTester tester,
    ) async {
      session.start();
      await tester.pump();
      expect(channels, hasLength(1));

      // Premier échec réseau (pas un refus de la route) : palier de 1 s.
      channels.last.dropWithError(Exception('réseau coupé'));
      await tester.pump();
      expect(session.reconnectFailures, 1);

      await tester.pump(const Duration(milliseconds: 900));
      expect(channels, hasLength(1));
      await tester.pump(const Duration(milliseconds: 200));
      expect(channels, hasLength(2));

      // Deuxième tentative acceptée : le compteur repart de zéro.
      channels.last.acceptUpgrade();
      await tester.pump();
      expect(session.isConnected, isTrue);
      expect(session.reconnectFailures, 0);
      expect(logs.last, contains('rétabli'));

      // Nouvelle coupure : on repart du premier palier (1 s), pas du suivant.
      channels.last.dropWithError(Exception('réseau coupé'));
      await tester.pump();
      expect(session.reconnectFailures, 1);
      await tester.pump(const Duration(milliseconds: 900));
      expect(channels, hasLength(2), reason: 'pas de palier hérité de la panne précédente');
      await tester.pump(const Duration(milliseconds: 200));
      expect(channels, hasLength(3));
    });

    testWidgets('une panne ne journalise qu\'une ligne, plus une à la reprise', (
      WidgetTester tester,
    ) async {
      session.start();
      await tester.pump();

      channels.last.refuseUpgrade();
      await tester.pump();
      expect(logs, hasLength(1));

      // Les tentatives suivantes échouent aussi : silence complet.
      await tester.pump(const Duration(seconds: 11));
      expect(channels, hasLength(2));
      channels.last.refuseUpgrade();
      await tester.pump();
      await tester.pump(const Duration(seconds: 21));
      expect(channels, hasLength(3));
      channels.last.refuseUpgrade();
      await tester.pump();
      expect(logs, hasLength(1), reason: 'une ligne par panne, pas par tentative');

      // Reprise : la tentative SUIVANTE est acceptée. Il faut un nouveau canal, car un
      // canal déjà refusé ne peut plus être accepté (sa poignée de main est terminée en
      // erreur) : c'est le palier d'après (40 s) qui rétablit le canal.
      await tester.pump(const Duration(seconds: 41));
      expect(channels, hasLength(4));
      channels.last.acceptUpgrade();
      await tester.pump();
      expect(logs, hasLength(2));
      expect(logs.last, contains('rétabli'));
    });

    testWidgets('le canal reste utilisable après une reprise (événements livrés)', (
      WidgetTester tester,
    ) async {
      final received = <GatewayBotEvent>[];
      session.events.listen(received.add);

      session.start();
      await tester.pump();
      channels.last.refuseUpgrade();
      await tester.pump();
      await tester.pump(const Duration(seconds: 11));
      expect(channels, hasLength(2));

      channels.last.acceptUpgrade();
      await tester.pump();
      channels.last.incoming.add('{"type":"ping","owner_id":"owner-1"}');
      await tester.pump();

      expect(received, hasLength(1));
      expect(received.single.type, GatewayBotEventType.ping);
    });
  });
}

/// Faux canal WebSocket : la poignée de main est pilotée par le test, donc
/// aucun réseau réel n'est touché et aucun délai réel n'est attendu.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel(this.uri);

  final Uri uri;
  final StreamController<dynamic> incoming =
      StreamController<dynamic>.broadcast();
  final _FakeSink _sink = _FakeSink();
  final Completer<void> _ready = Completer<void>();

  /// Le serveur (ou un intermédiaire) refuse la mise à niveau : c'est le message
  /// exact que remonte `dart:io` pour un 400/403/404.
  void refuseUpgrade() {
    if (_ready.isCompleted) return;
    _ready.completeError(
      WebSocketChannelException(
        "WebSocketException: Connection to '$uri' was not upgraded to websocket",
      ),
    );
  }

  void acceptUpgrade() {
    if (_ready.isCompleted) return;
    _ready.complete();
  }

  void dropWithError(Object error) => incoming.addError(error);

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
