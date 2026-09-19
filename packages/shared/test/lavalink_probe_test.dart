/// Tests du sondeur Lavalink (choix automatique du serveur).
///
/// AUCUN appel réseau réel : la liste publique et le test de connexion sont
/// simulés (fausse [LavalinkListService] + faux [LavalinkConnectionTester]).
library;

import 'dart:async';

import 'package:bot_creator_shared/services/lavalink_list_service.dart';
import 'package:bot_creator_shared/services/lavalink_probe.dart';
import 'package:test/test.dart';

// ─── Doublures ──────────────────────────────────────────────────────────────

/// Liste publique simulée : sert [entries] sans toucher au réseau.
class _FakeListService extends LavalinkListService {
  _FakeListService(this.entries);

  final List<LavalinkServerEntry> entries;
  int fetchCount = 0;

  @override
  Future<List<LavalinkServerEntry>> getServers({
    bool forceRefresh = false,
  }) async {
    fetchCount++;
    return entries;
  }
}

/// Liste publique en panne (l'appel lève) : le sondeur doit l'absorber.
class _ThrowingListService extends LavalinkListService {
  @override
  Future<List<LavalinkServerEntry>> getServers({
    bool forceRefresh = false,
  }) async {
    throw Exception('réseau coupé');
  }
}

LavalinkServerEntry _entry(
  String host, {
  String version = 'v4',
  int port = 2333,
  bool secure = false,
}) {
  return LavalinkServerEntry(
    uniqueId: host,
    identifier: host,
    host: host,
    port: port,
    password: 'pw-$host',
    secure: secure,
    version: version,
  );
}

/// Faux test de connexion : joue le script fourni et note les hôtes touchés.
LavalinkConnectionTester _fakeTester(
  Map<String, Future<String?> Function()> scripts, {
  List<String>? calls,
}) {
  return ({
    required String host,
    required int port,
    required String password,
    required bool useSsl,
  }) async {
    calls?.add(host);
    final script = scripts[host];
    if (script == null) return 'connexion refusée : $host';
    return script();
  };
}

/// Répond après [delay] (latence simulée).
Future<String?> _okAfter(Duration delay) async {
  await Future<void>.delayed(delay);
  return null;
}

/// Ne répond jamais (serveur injoignable).
Future<String?> _never() => Completer<String?>().future;

/// Répond une erreur immédiatement.
Future<String?> _refused() async => 'connexion refusée';

void main() {
  group('filtre v4', () {
    test('LavalinkServerEntry.isV4 ne garde que la version v4', () {
      expect(_entry('a', version: 'v4').isV4, isTrue);
      expect(_entry('b', version: 'V4').isV4, isTrue);
      expect(_entry('c', version: 'v3').isV4, isFalse);
      expect(_entry('d', version: 'v4.0').isV4, isFalse);
    });

    test('LavalinkListService.filterV4 retire les non-v4', () {
      final filtered = LavalinkListService.filterV4([
        _entry('keep.me', version: 'v4'),
        _entry('drop.me', version: 'v3'),
      ]);
      expect(filtered.map((e) => e.host).toList(), ['keep.me']);
    });
  });

  group('schéma figé (custom_servers)', () {
    test('lit les serveurs personnels du schéma figé', () {
      final targets = LavalinkProbeTarget.customServersFromJson([
        {
          'host': 'mon.lavalink.tld',
          'port': 2333,
          'password': 'secret',
          'secure': false,
        },
        {
          'host': 'ssl.lavalink.tld',
          'port': 443,
          'password': 'pw',
          'secure': true,
        },
      ]);

      expect(targets.length, 2);
      expect(targets.first.host, 'mon.lavalink.tld');
      expect(targets.first.port, 2333);
      expect(targets.first.password, 'secret');
      expect(targets.first.useSsl, isFalse);
      expect(targets.first.isCustom, isTrue);
      expect(targets[1].useSsl, isTrue);
    });

    test('tolère les entrées incomplètes sans lever', () {
      // port illisible => 2333, `secure` absent => false
      final fallback = LavalinkProbeTarget.tryFromCustomServerJson({
        'host': 'a.tld',
        'port': 'oups',
      });
      expect(fallback!.port, 2333);
      expect(fallback.useSsl, isFalse);

      // hôte vide => entrée ignorée
      expect(
        LavalinkProbeTarget.tryFromCustomServerJson({'host': '   '}),
        isNull,
      );
      expect(LavalinkProbeTarget.customServersFromJson(null), isEmpty);
      expect(
        LavalinkProbeTarget.customServersFromJson('pas une liste'),
        isEmpty,
      );

      // ancienne clé héritée encore relue
      expect(
        LavalinkProbeTarget.tryFromCustomServerJson({
          'host': 'a.tld',
          'useSsl': true,
        })!.useSsl,
        isTrue,
      );
    });
  });

  group('sondage', () {
    test('classe les serveurs qui répondent par latence croissante', () async {
      final calls = <String>[];
      final probe = LavalinkProbe(
        listService: _FakeListService([
          _entry('slow.example'),
          _entry('fast.example'),
          _entry('mid.example'),
        ]),
        tester: _fakeTester({
          'slow.example': () => _okAfter(const Duration(milliseconds: 120)),
          'mid.example': () => _okAfter(const Duration(milliseconds: 60)),
          'fast.example': () => _okAfter(const Duration(milliseconds: 20)),
        }, calls: calls),
        perServerBudget: const Duration(milliseconds: 800),
        totalBudget: const Duration(seconds: 3),
      );

      final ranked = await probe.probe(forceRefresh: true);

      expect(ranked.map((r) => r.target.host).toList(), [
        'fast.example',
        'mid.example',
        'slow.example',
      ]);
      // Tous les candidats sont testés, et en parallèle (pas l'un après l'autre).
      expect(calls.toSet(), {'slow.example', 'mid.example', 'fast.example'});
      for (var i = 1; i < ranked.length; i++) {
        expect(
          ranked[i].latency >= ranked[i - 1].latency,
          isTrue,
          reason: 'les latences doivent croître à partir du rang $i',
        );
      }
    });

    test('ignore les serveurs qui ne sont pas en v4', () async {
      final calls = <String>[];
      final probe = LavalinkProbe(
        listService: _FakeListService([
          _entry('v4.example', version: 'v4'),
          _entry('legacy.example', version: 'v3'),
        ]),
        tester: _fakeTester({
          'v4.example': () => _okAfter(const Duration(milliseconds: 20)),
          'legacy.example': () => _okAfter(const Duration(milliseconds: 20)),
        }, calls: calls),
        perServerBudget: const Duration(milliseconds: 500),
        totalBudget: const Duration(seconds: 2),
      );

      final ranked = await probe.probe(forceRefresh: true);

      expect(ranked.map((r) => r.target.host).toList(), ['v4.example']);
      expect(probe.lastTargetCount, 1);
      expect(calls, isNot(contains('legacy.example')));
    });

    test(
      'respecte le budget TOTAL, même si un serveur ne répond jamais',
      () async {
        final probe = LavalinkProbe(
          listService: _FakeListService([
            _entry('hangs.example'),
            _entry('fast.example'),
          ]),
          tester: _fakeTester({
            'hangs.example': _never,
            'fast.example': () => _okAfter(const Duration(milliseconds: 20)),
          }),
          // Budget par serveur volontairement PLUS LONG que le budget total :
          // seule la borne globale peut couper ce sondage.
          perServerBudget: const Duration(seconds: 30),
          totalBudget: const Duration(milliseconds: 300),
        );

        final stopwatch = Stopwatch()..start();
        final ranked = await probe.probe(forceRefresh: true);
        stopwatch.stop();

        expect(ranked.map((r) => r.target.host).toList(), ['fast.example']);
        expect(
          stopwatch.elapsedMilliseconds,
          lessThan(1500),
          reason: 'le sondage doit rendre la main autour de 300 ms',
        );
      },
    );

    test('coupe un serveur qui dépasse son budget individuel', () async {
      final probe = LavalinkProbe(
        listService: _FakeListService([_entry('hangs.example')]),
        tester: _fakeTester({'hangs.example': _never}),
        perServerBudget: const Duration(milliseconds: 150),
        totalBudget: const Duration(seconds: 30),
      );

      final stopwatch = Stopwatch()..start();
      final ranked = await probe.probe(forceRefresh: true);
      stopwatch.stop();

      expect(ranked, isEmpty);
      expect(
        stopwatch.elapsedMilliseconds,
        lessThan(1500),
        reason: 'le budget par serveur doit écourter l\'attente',
      );
    });

    test(
      'mémorise le classement et ne re-sonde pas avant expiration',
      () async {
        final calls = <String>[];
        final listService = _FakeListService([_entry('only.example')]);
        final probe = LavalinkProbe(
          listService: listService,
          tester: _fakeTester({
            'only.example': () => _okAfter(const Duration(milliseconds: 10)),
          }, calls: calls),
          perServerBudget: const Duration(milliseconds: 500),
          totalBudget: const Duration(seconds: 2),
          cacheTtl: const Duration(minutes: 10),
        );

        await probe.probe();
        expect(probe.sweepCount, 1);
        expect(probe.hasFreshCache, isTrue);
        final callsAfterFirst = calls.length;

        // Deuxième appel : servi par le cache, aucun nouveau test.
        final cached = await probe.probe();
        expect(cached.map((r) => r.target.host).toList(), ['only.example']);
        expect(probe.sweepCount, 1);
        expect(calls.length, callsAfterFirst);

        // Rafraîchissement forcé : on re-sonde.
        await probe.probe(forceRefresh: true);
        expect(probe.sweepCount, 2);
        expect(calls.length, greaterThan(callsAfterFirst));
      },
    );

    test(
      'échec total (aucun serveur ne répond) => liste vide, sans lever',
      () async {
        final probe = LavalinkProbe(
          listService: _FakeListService([_entry('dead.example')]),
          tester: _fakeTester({'dead.example': _refused}),
          perServerBudget: const Duration(milliseconds: 200),
          totalBudget: const Duration(seconds: 1),
        );

        final ranked = await probe.probe(forceRefresh: true);

        expect(ranked, isEmpty);
        expect(probe.cachedResults, isEmpty);
        expect(probe.hasFreshCache, isFalse);
        expect(probe.nextAfter(null), isNull);
        expect(await probe.findBestServer(), isNull);
      },
    );

    test('liste publique en erreur => liste vide, sans lever', () async {
      final probe = LavalinkProbe(
        listService: _ThrowingListService(),
        tester: _fakeTester({}),
        perServerBudget: const Duration(milliseconds: 100),
        totalBudget: const Duration(seconds: 1),
      );

      expect(await probe.probe(forceRefresh: true), isEmpty);
      expect(probe.sweepCount, 0);
    });
  });

  group('repli en cascade', () {
    /// Sondeur prêt à l'emploi : deux serveurs publics répondent (fast puis
    /// mid), et deux serveurs personnels servent de repli.
    Future<LavalinkProbe> buildProbe() async {
      final probe = LavalinkProbe(
        listService: _FakeListService([
          _entry('mid.example'),
          _entry('fast.example'),
        ]),
        tester: _fakeTester({
          'fast.example': () => _okAfter(const Duration(milliseconds: 20)),
          'mid.example': () => _okAfter(const Duration(milliseconds: 80)),
        }),
        perServerBudget: const Duration(milliseconds: 800),
        totalBudget: const Duration(seconds: 3),
      );
      await probe.probe(forceRefresh: true);
      return probe;
    }

    LavalinkProbeTarget perso(String host) =>
        LavalinkProbeTarget.custom(host: host, port: 2333, password: 'pw');

    test(
      'nextAfter donne le serveur suivant du classement, puis null',
      () async {
        final probe = await buildProbe();

        final first = probe.nextAfter(null);
        expect(first!.host, 'fast.example');

        final second = probe.nextAfter(first);
        expect(second!.host, 'mid.example');

        expect(probe.nextAfter(second), isNull);
      },
    );

    test('nextAfter bascule sur les serveurs personnels, puis null', () async {
      final probe = await buildProbe();
      final customs = [perso('perso1.example'), perso('perso2.example')];

      final first = probe.nextAfter(null, customServers: customs);
      expect(first!.host, 'fast.example');
      expect(first.isCustom, isFalse);

      final second = probe.nextAfter(first, customServers: customs);
      expect(second!.host, 'mid.example');

      // Classement épuisé : on passe aux serveurs de l'utilisateur.
      final third = probe.nextAfter(second, customServers: customs);
      expect(third!.host, 'perso1.example');
      expect(third.isCustom, isTrue);

      final fourth = probe.nextAfter(third, customServers: customs);
      expect(fourth!.host, 'perso2.example');

      expect(probe.nextAfter(fourth, customServers: customs), isNull);
    });

    test(
      'le repli personnel fonctionne même si la liste publique est morte',
      () async {
        final customs = [perso('perso1.example')];
        final probe = LavalinkProbe(
          listService: _FakeListService([_entry('dead.example')]),
          tester: _fakeTester({'dead.example': _refused}),
          perServerBudget: const Duration(milliseconds: 200),
          totalBudget: const Duration(seconds: 1),
        );

        await probe.probe(forceRefresh: true);

        expect(probe.nextAfter(null), isNull);
        expect(
          probe.nextAfter(null, customServers: customs)!.host,
          'perso1.example',
        );
        expect(
          (await probe.findBestServer(customServers: customs))!.host,
          'perso1.example',
        );
        expect(await probe.findBestServer(), isNull);
      },
    );

    test(
      'les serveurs personnels ne consomment pas le budget du sondage',
      () async {
        final calls = <String>[];
        final customs = [perso('perso1.example')];
        final probe = LavalinkProbe(
          listService: _FakeListService([_entry('fast.example')]),
          tester: _fakeTester({
            'fast.example': () => _okAfter(const Duration(milliseconds: 20)),
          }, calls: calls),
          perServerBudget: const Duration(milliseconds: 800),
          totalBudget: const Duration(seconds: 3),
        );

        await probe.probe(forceRefresh: true);
        probe.nextAfter(null, customServers: customs);

        // Le repli est rendu au demandeur, qui décidera de le tester : le
        // sondage ne pré-teste pas les serveurs personnels.
        expect(calls, isNot(contains('perso1.example')));
      },
    );

    test('failoverQueue avance puis s\'épuise', () async {
      final probe = await buildProbe();
      final queue = await probe.failoverQueue(
        customServers: [perso('perso1.example')],
      );

      expect(queue.length, 3);
      expect(queue.isEmpty, isFalse);
      expect(queue.next()!.host, 'fast.example');
      expect(queue.next()!.host, 'mid.example');
      expect(queue.next()!.host, 'perso1.example');
      expect(queue.next(), isNull);
      expect(queue.isExhausted, isTrue);
    });

    test('failoverQueue repart après un serveur donné (nextAfter)', () async {
      final probe = await buildProbe();
      final queue = await probe.failoverQueue(
        customServers: [perso('perso1.example')],
      );

      expect(queue.next()!.host, 'fast.example');
      expect(
        queue.nextAfter(probe.cachedResults.first.target)!.host,
        'mid.example',
      );
      expect(queue.next()!.host, 'perso1.example');
      expect(queue.next(), isNull);

      queue.reset();
      expect(queue.next()!.host, 'fast.example');
    });
  });
}
