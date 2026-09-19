/// Sondeur Lavalink : le bot essaie lui-même les serveurs publics et garde
/// le plus rapide à répondre, avec les serveurs personnels en repli.
///
/// Principe (cf. plan « Lavalink automatique ») :
/// 1. récupérer la liste publique (cache 5 min du [LavalinkListService]) ;
/// 2. ne garder que les entrées `v4` (protocole REST `/v4`) ;
/// 3. tester tous les candidats EN PARALLÈLE, avec un budget court par serveur
///    (~2,5 s) et un budget TOTAL borné (~8 s) ;
/// 4. classer les survivants par latence croissante et mémoriser le classement
///    (~10 min) pour ne pas re-sonder à chaque démarrage ;
/// 5. exposer le repli en cascade : classement public, puis les serveurs
///    PERSONNELS de l'utilisateur, puis `null`.
///
/// Aucune méthode publique ne lève : une musique indisponible est un état
/// normal, le bot Discord doit continuer à tourner.
library;

import 'dart:async';

import 'package:bot_creator_shared/services/lavalink_list_service.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';

/// Signature d'un test de connexion à un serveur Lavalink.
///
/// Retourne `null` si le serveur répond, sinon un message d'échec.
/// Compatible telle quelle avec [LavalinkService.testConnection].
typedef LavalinkConnectionTester =
    Future<String?> Function({
      required String host,
      required int port,
      required String password,
      required bool useSsl,
    });

/// Implémentation par défaut : le test qui existe déjà dans le paquet.
Future<String?> _defaultConnectionTester({
  required String host,
  required int port,
  required String password,
  required bool useSsl,
}) {
  return LavalinkService.testConnection(
    host: host,
    port: port,
    password: password,
    useSsl: useSsl,
  );
}

/// Message interne servant de sentinelle lorsqu'un serveur dépasse le budget
/// qui lui était alloué.
const String _probeTimeout = '__probe_timeout__';

/// Un candidat au sondage : une entrée de la liste publique ou un serveur
/// personnel de l'utilisateur (repli).
class LavalinkProbeTarget {
  final String host;
  final int port;
  final String password;
  final bool useSsl;

  /// Identifiant lisible (identifiant public ou « perso »).
  final String label;

  /// Vrai quand le serveur vient de la liste personnelle de l'utilisateur.
  final bool isCustom;

  /// Version déclarée (v4 pour la liste publique, vide pour un serveur perso).
  final String version;

  const LavalinkProbeTarget({
    required this.host,
    required this.port,
    required this.password,
    required this.useSsl,
    this.label = '',
    this.isCustom = false,
    this.version = '',
  });

  /// Construit un candidat depuis une entrée de la liste publique.
  factory LavalinkProbeTarget.fromPublicEntry(LavalinkServerEntry entry) {
    return LavalinkProbeTarget(
      host: entry.host,
      port: entry.port,
      password: entry.password,
      useSsl: entry.secure,
      label: entry.identifier.isEmpty ? entry.host : entry.identifier,
      isCustom: false,
      version: entry.version,
    );
  }

  /// Construit un candidat depuis un serveur personnel (`custom_servers`).
  factory LavalinkProbeTarget.custom({
    required String host,
    required int port,
    required String password,
    bool useSsl = false,
    String label = '',
  }) {
    return LavalinkProbeTarget(
      host: host,
      port: port,
      password: password,
      useSsl: useSsl,
      label: label.isEmpty ? host : label,
      isCustom: true,
      version: '',
    );
  }

  /// Construit un candidat depuis une entrée `custom_servers` du schéma de
  /// configuration FIGÉ (`host` / `port` / `password` / `secure`).
  ///
  /// `secure` a pour défaut `false` ; le port retombe sur 2333 s'il est
  /// illisible. Retourne `null` si l'hôte est vide : un repli inutilisable est
  /// simplement ignoré plutôt que de faire échouer le démarrage.
  static LavalinkProbeTarget? tryFromCustomServerJson(
    Map<String, dynamic> json,
  ) {
    final host = (json['host'] ?? '').toString().trim();
    if (host.isEmpty) return null;

    final parsedPort = int.tryParse((json['port'] ?? '').toString().trim());
    final port = (parsedPort == null || parsedPort < 1 || parsedPort > 65535)
        ? 2333
        : parsedPort;

    return LavalinkProbeTarget(
      host: host,
      port: port,
      password: (json['password'] ?? '').toString(),
      // `secure` est la clé du schéma figé ; `useSsl`/`ssl` restent relus pour
      // ne pas casser une configuration héritée.
      useSsl:
          json['secure'] == true ||
          json['useSsl'] == true ||
          json['ssl'] == true,
      label: host,
      isCustom: true,
    );
  }

  /// Traduit une liste `custom_servers` du schéma figé en candidats de repli,
  /// dans leur ordre d'essai.
  static List<LavalinkProbeTarget> customServersFromJson(Object? rawList) {
    if (rawList is! List) return const <LavalinkProbeTarget>[];
    final targets = <LavalinkProbeTarget>[];
    for (final entry in rawList.whereType<Map>()) {
      final target = tryFromCustomServerJson(Map<String, dynamic>.from(entry));
      if (target != null) targets.add(target);
    }
    return targets;
  }

  /// Deux serveurs sont « le même point de terminaison » quand hôte, port et
  /// SSL coïncident — c'est ce qui permet au repli de se situer dans le
  /// classement, sans dépendre du mot de passe.
  bool sameEndpointAs(LavalinkProbeTarget other) {
    return host.toLowerCase() == other.host.toLowerCase() &&
        port == other.port &&
        useSsl == other.useSsl;
  }

  /// Représentation courte pour les journaux.
  String get endpoint => '$host:$port${useSsl ? ' (ssl)' : ''}';

  @override
  String toString() =>
      'LavalinkProbeTarget($endpoint${isCustom ? ', perso' : ''})';
}

/// Résultat d'un sondage réussi : la cible et la latence mesurée.
class LavalinkProbeResult {
  final LavalinkProbeTarget target;
  final Duration latency;

  const LavalinkProbeResult({required this.target, required this.latency});

  @override
  String toString() =>
      'LavalinkProbeResult(${target.endpoint}, ${latency.inMilliseconds} ms)';
}

/// Petite file d'attente de repli construite sur l'ordre du sondeur.
///
/// Avance serveur par serveur et retourne `null` quand tout est épuisé.
class LavalinkFailoverQueue {
  final List<LavalinkProbeTarget> order;
  int _cursor = -1;

  LavalinkFailoverQueue(List<LavalinkProbeTarget> order)
    : order = List<LavalinkProbeTarget>.unmodifiable(order);

  bool get isEmpty => order.isEmpty;

  /// Vrai quand plus aucun serveur ne reste à essayer.
  bool get isExhausted => _cursor + 1 >= order.length;

  int get length => order.length;

  /// Serveur suivant de l'ordre, ou `null` si la file est épuisée.
  LavalinkProbeTarget? next() {
    if (isExhausted) return null;
    _cursor++;
    return order[_cursor];
  }

  /// Repositionne la file juste après [previous] puis renvoie le suivant.
  LavalinkProbeTarget? nextAfter(LavalinkProbeTarget previous) {
    final index = order.indexWhere((target) => target.sameEndpointAs(previous));
    _cursor = index;
    return next();
  }

  /// Repart du début (premier serveur du classement).
  void reset() => _cursor = -1;
}

/// Sonde la liste publique Lavalink et expose le repli en cascade.
class LavalinkProbe {
  /// Budget alloué à un serveur (~2,5 s).
  static const Duration defaultPerServerBudget = Duration(milliseconds: 2500);

  /// Budget TOTAL du sondage (~8 s) : borne dure, jamais dépassée.
  static const Duration defaultTotalBudget = Duration(seconds: 8);

  /// Durée de mémorisation du classement (~10 min).
  static const Duration defaultCacheTtl = Duration(minutes: 10);

  final LavalinkListService _listService;
  final LavalinkConnectionTester _tester;

  final Duration perServerBudget;
  final Duration totalBudget;
  final Duration cacheTtl;
  final void Function(String message)? onLog;

  List<LavalinkProbeResult> _cachedResults = const <LavalinkProbeResult>[];
  DateTime? _cachedAt;

  /// Nombre de sondages RÉELS effectués (les réponses servies par le cache ne
  /// comptent pas) — utile au diagnostic et aux tests.
  int sweepCount = 0;

  /// Nombre de candidats testés lors du dernier sondage réel.
  int lastTargetCount = 0;

  LavalinkProbe({
    LavalinkListService? listService,
    LavalinkConnectionTester tester = _defaultConnectionTester,
    this.perServerBudget = defaultPerServerBudget,
    this.totalBudget = defaultTotalBudget,
    this.cacheTtl = defaultCacheTtl,
    this.onLog,
  }) : _listService = listService ?? LavalinkListService(),
       // ignore: prefer_initializing_formals
       _tester = tester;

  /// Classement mémorisé, du plus rapide au plus lent (vide si inconnu).
  List<LavalinkProbeResult> get cachedResults => _cachedResults;

  /// Vrai quand le classement mémorisé est encore valide.
  bool get hasFreshCache {
    if (_cachedResults.isEmpty || _cachedAt == null) return false;
    return DateTime.now().difference(_cachedAt!) < cacheTtl;
  }

  /// Oublie le classement mémorisé (le prochain [probe] sondera à nouveau).
  void clearCache() {
    _cachedResults = const <LavalinkProbeResult>[];
    _cachedAt = null;
  }

  /// Sonde la liste publique et retourne les serveurs `v4` qui ont répondu,
  /// classés par latence croissante.
  ///
  /// Sert le classement mémorisé (cache ~10 min) sauf si [forceRefresh].
  /// Ne lève jamais : en cas d'échec total, retourne une liste vide.
  Future<List<LavalinkProbeResult>> probe({bool forceRefresh = false}) async {
    if (!forceRefresh && hasFreshCache) {
      return _cachedResults;
    }

    final List<LavalinkServerEntry> entries;
    try {
      entries = await _listService.getServers(forceRefresh: forceRefresh);
    } catch (error) {
      onLog?.call('Lavalink probe : liste publique indisponible ($error)');
      return _cachedResults;
    }

    final v4Entries = LavalinkListService.filterV4(entries);
    final targets = v4Entries
        .map(LavalinkProbeTarget.fromPublicEntry)
        .toList(growable: false);

    final stopwatch = Stopwatch()..start();
    final results = await _sweep(targets);
    stopwatch.stop();

    sweepCount++;
    lastTargetCount = targets.length;

    // Les serveurs qui répondent sont classés du plus rapide au plus lent.
    results.sort((a, b) => a.latency.compareTo(b.latency));

    onLog?.call(
      'Lavalink probe : ${results.length}/${targets.length} serveur(s) v4 '
      'ont répondu en ${stopwatch.elapsedMilliseconds} ms',
    );

    // Un échec total n'est pas mémorisé : le prochain démarrage réessaiera.
    if (results.isNotEmpty) {
      _cachedResults = List<LavalinkProbeResult>.unmodifiable(results);
      _cachedAt = DateTime.now();
    }
    return _cachedResults;
  }

  /// Ordre de repli complet : classement public (latence croissante), puis les
  /// serveurs personnels de l'utilisateur dans l'ordre fourni.
  List<LavalinkProbeTarget> failoverOrder({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
  }) {
    return <LavalinkProbeTarget>[
      ..._cachedResults.map((result) => result.target),
      ...customServers,
    ];
  }

  /// Serveur suivant de la cascade : le classement public d'abord, puis les
  /// serveurs personnels, puis `null` quand tout est épuisé.
  ///
  /// [previous] à `null` renvoie le premier candidat (le vainqueur).
  LavalinkProbeTarget? nextAfter(
    LavalinkProbeTarget? previous, {
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
  }) {
    final order = failoverOrder(customServers: customServers);
    if (order.isEmpty) return null;
    if (previous == null) return order.first;
    final index = order.indexWhere((target) => target.sameEndpointAs(previous));
    if (index == -1) return order.first;
    if (index + 1 >= order.length) return null;
    return order[index + 1];
  }

  /// Construit la petite file d'attente de repli (même ordre que [nextAfter]).
  Future<LavalinkFailoverQueue> failoverQueue({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
    bool forceRefresh = false,
  }) async {
    await probe(forceRefresh: forceRefresh);
    return LavalinkFailoverQueue(failoverOrder(customServers: customServers));
  }

  /// Meilleur serveur disponible : le plus rapide de la liste publique, ou à
  /// défaut le premier serveur personnel, ou `null` si rien n'est disponible.
  Future<LavalinkProbeTarget?> findBestServer({
    List<LavalinkProbeTarget> customServers = const <LavalinkProbeTarget>[],
    bool forceRefresh = false,
  }) async {
    final ranked = await probe(forceRefresh: forceRefresh);
    if (ranked.isNotEmpty) return ranked.first.target;
    return customServers.isEmpty ? null : customServers.first;
  }

  /// Teste les candidats en parallèle, sous budget total borné.
  ///
  /// Chaque candidat a son propre budget ([perServerBudget]) ; l'ensemble est
  /// de toute façon coupé par [totalBudget]. Les réponses arrivées après la
  /// coupure sont ignorées : on ne bloque jamais l'appelant.
  Future<List<LavalinkProbeResult>> _sweep(
    List<LavalinkProbeTarget> targets,
  ) async {
    if (targets.isEmpty) return <LavalinkProbeResult>[];

    final results = <LavalinkProbeResult>[];
    final done = Completer<void>();
    var settled = false;
    var pending = targets.length;

    void finish() {
      if (!done.isCompleted) done.complete();
    }

    for (final target in targets) {
      unawaited(
        _probeOne(target).then((result) {
          if (!settled && result != null) results.add(result);
          pending--;
          if (pending == 0) finish();
        }),
      );
    }

    // Borne dure : même si un client HTTP ignore le budget par serveur, le
    // sondage rend la main ici.
    final watchdog = Timer(totalBudget, finish);
    await done.future;
    settled = true;
    watchdog.cancel();

    return results;
  }

  /// Teste un candidat. Ne lève jamais ; retourne `null` s'il ne répond pas
  /// dans son budget.
  Future<LavalinkProbeResult?> _probeOne(LavalinkProbeTarget target) async {
    final stopwatch = Stopwatch()..start();
    try {
      final error = await _tester(
        host: target.host,
        port: target.port,
        password: target.password,
        useSsl: target.useSsl,
      ).timeout(perServerBudget, onTimeout: () => _probeTimeout);

      stopwatch.stop();
      if (error != null) {
        onLog?.call('Lavalink probe : ${target.endpoint} a échoué ($error)');
        return null;
      }
      return LavalinkProbeResult(target: target, latency: stopwatch.elapsed);
    } catch (error) {
      onLog?.call('Lavalink probe : ${target.endpoint} a échoué ($error)');
      return null;
    }
  }
}
