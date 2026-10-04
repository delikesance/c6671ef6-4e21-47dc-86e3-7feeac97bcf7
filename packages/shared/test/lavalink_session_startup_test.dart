/// Démarrage Lavalink : la passerelle Discord ne doit JAMAIS être retenue.
///
/// Bug de conception corrigé dans la refonte : la phase de sélection du serveur
/// Lavalink s'exécute AVANT `Nyxx.connectGateway`. Si elle attendait une liste
/// publique qui ne répond pas, le bot ne se connectait jamais à Discord. Le
/// contrat vérifié ici :
/// - le sondage est coupé au budget [BotSession.lavalinkSelectionTimeout]
///   (4 s par défaut) — jamais attendu ;
/// - le sondage abandonné poursuit sa route en tâche de fond (il alimentera le
///   cache du démarrage suivant) ;
/// - quand aucun serveur n'est retenu, `buildGatewayPlugins()` ne contient
///   AUCUN plugin Lavalink : la passerelle se connecte sans musique.
///
/// Aucun réseau : ni liste publique, ni serveur Lavalink réels.
library;

import 'dart:async';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/engine/bot_engine_callbacks.dart';
import 'package:bot_creator_shared/engine/bot_session.dart';
import 'package:bot_creator_shared/services/lavalink_probe.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:test/test.dart';

/// Magasin de bot factice : le démarrage Lavalink ne lit RIEN dedans, il ne
/// doit donc jamais être sollicité.
class _UntouchedBotDataStore implements BotDataStore {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw UnimplementedError(
      'BotDataStore.${invocation.memberName} ne doit pas être appelé '
      'par la phase Lavalink',
    );
  }
}

/// Sondeur dont la « liste » ne rend JAMAIS la main : c'est le cas qui bloquait
/// le démarrage. La sélection reste en attente pour toujours.
class _HangingProbe extends LavalinkProbe {
  final Completer<LavalinkProbeTarget?> _never =
      Completer<LavalinkProbeTarget?>();

  bool called = false;

  /// Vrai tant que la sélection n'a pas rendu la main (tâche de fond).
  bool get isStillPending => !_never.isCompleted;

  @override
  Future<LavalinkProbeTarget?> findBestServer({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
    bool forceRefresh = false,
  }) {
    called = true;
    return _never.future;
  }
}

/// Sondeur qui répond immédiatement un serveur fixe (ou rien).
class _FixedProbe extends LavalinkProbe {
  _FixedProbe(this.target);

  final LavalinkProbeTarget? target;
  int calls = 0;

  @override
  Future<LavalinkProbeTarget?> findBestServer({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
    bool forceRefresh = false,
  }) async {
    calls++;
    return target;
  }
}

/// Sondeur qui échoue. [late] = l'erreur arrive après coup (future), sinon elle
/// est lancée dans l'appel lui-même.
class _FailingProbe extends LavalinkProbe {
  _FailingProbe({this.late = true});

  final bool late;

  @override
  Future<LavalinkProbeTarget?> findBestServer({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
    bool forceRefresh = false,
  }) {
    if (late) {
      return Future<LavalinkProbeTarget?>.error(StateError('sondage cassé'));
    }
    throw StateError('sondage cassé');
  }
}

/// Test de connexion REST factice : aucun réseau.
class _FakeTester {
  _FakeTester(this.answer);

  final String? Function(LavalinkProbeTarget target) answer;
  final List<LavalinkProbeTarget> calls = <LavalinkProbeTarget>[];

  Future<String?> call({
    required String host,
    required int port,
    required String password,
    required bool useSsl,
  }) async {
    final target = LavalinkProbeTarget(
      host: host,
      port: port,
      password: password,
      useSsl: useSsl,
    );
    calls.add(target);
    return answer(target);
  }
}

LavalinkConfig _configWithPersonalServer() => const LavalinkConfig(
  customServers: <LavalinkServerConfig>[
    LavalinkServerConfig(
      host: 'lavalink.perso',
      port: 2333,
      password: 'mot-de-passe',
    ),
  ],
  host: 'lavalink.perso',
  port: 2333,
  password: 'mot-de-passe',
);

BotSession _session({
  LavalinkProbe? probe,
  LavalinkConnectionTester? tester,
  Duration? selectionTimeout,
  List<String>? logs,
  _UntouchedBotDataStore? store,
}) {
  return BotSession(
    botId: 'bot-test',
    token: 'token-factice',
    store: store ?? _UntouchedBotDataStore(),
    callbacks: BotEngineCallbacks(
      onLog: (message, {required String botId}) => logs?.add(message),
    ),
    lavalinkProbe: probe,
    lavalinkConnectionTester: tester,
    lavalinkSelectionTimeout: selectionTimeout ?? const Duration(seconds: 4),
  );
}

void main() {
  group('démarrage Lavalink — la passerelle Discord n\'attend jamais', () {
    test('le budget de sélection vaut 4 s par défaut', () {
      final logs = <String>[];
      final session = _session(logs: logs);

      expect(
        session.lavalinkSelectionTimeout,
        const Duration(seconds: 4),
        reason: 'borne dure de la phase Lavalink avant la connexion Discord',
      );
      expect(
        logs,
        isEmpty,
        reason: 'construire une session ne journalise rien',
      );
    });

    test('une liste qui ne rend jamais la main est COUPÉE au budget', () async {
      final probe = _HangingProbe();
      final store = _UntouchedBotDataStore();
      final logs = <String>[];
      final session = _session(
        probe: probe,
        store: store,
        selectionTimeout: const Duration(milliseconds: 250),
        logs: logs,
      );

      final stopwatch = Stopwatch()..start();
      final plugin = await session.prepareLavalinkPlugin(
        _configWithPersonalServer(),
      );
      stopwatch.stop();

      expect(probe.called, isTrue, reason: 'la sélection a bien été lancée');
      expect(
        plugin,
        isNull,
        reason: 'aucun serveur retenu => musique indisponible, pas d\'erreur',
      );
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: 'l\'appelant rend la main au budget, il n\'attend pas la liste',
      );
      expect(
        probe.isStillPending,
        isTrue,
        reason: 'la sélection abandonnée continue en tâche de fond',
      );
      expect(session.selectedServer, isNull);
      expect(store.calls, 0, reason: 'aucune lecture du magasin');
      expect(
        logs.join('\n'),
        contains('musique indisponible'),
        reason: 'l\'utilisateur doit voir pourquoi la musique est absente',
      );
      expect(
        BotSession.buildGatewayPlugins(
          lavalinkPlugin: plugin,
        ).whereType<LavalinkPlugin>(),
        isEmpty,
        reason: 'la passerelle Discord part donc SANS plugin Lavalink',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
      'avec le budget PAR DÉFAUT (4 s), le démarrage est coupé quand même',
      () async {
        final probe = _HangingProbe();
        final session = _session(probe: probe);

        final stopwatch = Stopwatch()..start();
        final plugin = await session.prepareLavalinkPlugin(
          _configWithPersonalServer(),
        );
        stopwatch.stop();

        expect(plugin, isNull);
        expect(
          stopwatch.elapsed,
          greaterThanOrEqualTo(const Duration(milliseconds: 3500)),
          reason: 'la sélection a réellement attendu son budget',
        );
        expect(
          stopwatch.elapsed,
          lessThan(const Duration(seconds: 8)),
          reason: 'puis elle a été coupée : jamais les 8 s du sondage complet',
        );
        expect(probe.isStillPending, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('un sondage en échec est avalé, jamais propagé', () async {
      for (final late in <bool>[true, false]) {
        final session = _session(probe: _FailingProbe(late: late));
        final plugin = await session.prepareLavalinkPlugin(
          _configWithPersonalServer(),
        );
        expect(plugin, isNull, reason: 'échec du sondage (late=$late)');
        expect(session.selectedServer, isNull);
      }
    });

    test('musique désactivée : aucun sondage, aucun plugin', () async {
      final probe = _FixedProbe(null);
      final session = _session(probe: probe);

      final plugin = await session.prepareLavalinkPlugin(
        const LavalinkConfig(enabled: false),
      );

      expect(plugin, isNull);
      expect(probe.calls, 0, reason: 'interrupteur à off => on ne sonde rien');
      expect(
        BotSession.buildGatewayPlugins(lavalinkPlugin: plugin),
        hasLength(2),
      );
    });

    test(
      'aucune configuration Lavalink : aucun sondage, aucun plugin',
      () async {
        final probe = _FixedProbe(null);
        final session = _session(probe: probe);

        expect(await session.prepareLavalinkPlugin(null), isNull);
        expect(probe.calls, 0);
      },
    );

    test(
      'un serveur qui ne répond pas au test REST ne donne aucun plugin',
      () async {
        final target = LavalinkProbeTarget.custom(
          host: 'lavalink.perso',
          port: 2333,
          password: 'mot-de-passe',
        );
        final tester = _FakeTester((_) => 'Connexion refusée');
        final logs = <String>[];
        final session = _session(
          probe: _FixedProbe(target),
          tester: tester.call,
          logs: logs,
        );

        final plugin = await session.prepareLavalinkPlugin(
          _configWithPersonalServer(),
        );

        expect(plugin, isNull);
        expect(
          tester.calls,
          hasLength(1),
          reason: 'le repli est revérifié en REST',
        );
        expect(session.selectedServer, isNull);
        expect(logs.join('\n'), contains('musique indisponible'));
      },
    );

    test(
      'un serveur qui répond est retenu et transmis à la passerelle',
      () async {
        final target = LavalinkProbeTarget.custom(
          host: 'lavalink.perso',
          port: 2333,
          password: 'mot-de-passe',
        );
        final tester = _FakeTester((_) => null);
        final logs = <String>[];
        final session = _session(
          probe: _FixedProbe(target),
          tester: tester.call,
          logs: logs,
        );

        final plugin = await session.prepareLavalinkPlugin(
          _configWithPersonalServer(),
        );

        expect(plugin, isNotNull);
        expect(session.selectedServer?.endpoint, 'lavalink.perso:2333');
        expect(tester.calls.single.host, 'lavalink.perso');
        expect(logs.join('\n'), contains('plugin prêt'));

        final plugins = BotSession.buildGatewayPlugins(lavalinkPlugin: plugin);
        expect(
          plugins.whereType<LavalinkPlugin>(),
          hasLength(1),
          reason: 'le contrôle par whereType n\'est pas vide par construction',
        );
      },
    );
  });

  group('buildGatewayPlugins — le plugin Lavalink est optionnel', () {
    test('sans serveur retenu : aucun plugin Lavalink dans la passerelle', () {
      final plugins = BotSession.buildGatewayPlugins();

      expect(plugins.whereType<LavalinkPlugin>(), isEmpty);
      expect(
        plugins,
        hasLength(2),
        reason: 'logging + cliIntegration seulement',
      );
    });

    test('sans serveur retenu explicite (null) : même résultat', () {
      expect(
        BotSession.buildGatewayPlugins(
          lavalinkPlugin: null,
        ).whereType<LavalinkPlugin>(),
        isEmpty,
      );
    });
  });
}
