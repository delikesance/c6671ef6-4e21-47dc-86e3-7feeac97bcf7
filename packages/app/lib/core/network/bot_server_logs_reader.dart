import 'dart:async';

import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:flutter/foundation.dart';

/// État d'une lecture des logs d'un bot hébergé sur les serveurs Bot Creator.
@immutable
class BotServerLogsState {
  const BotServerLogsState({
    this.lines = const <String>[],
    this.readFromServer = false,
    this.readFailed = false,
  });

  /// Lignes telles que le serveur les a rendues.
  final List<String> lines;

  /// `true` dès qu'une lecture serveur a abouti — même si elle n'a rien rendu.
  final bool readFromServer;

  /// `true` quand la dernière tentative de lecture a échoué.
  final bool readFailed;

  /// Le serveur a RÉPONDU, et il n'y a rien à afficher.
  ///
  /// C'est ce cas précis qui doit produire un état vide honnête : « rien à
  /// afficher » n'est pas « rien reçu encore ». Laisser un « en attente
  /// d'événements en direct » devant une liste vide déjà lue fait attendre
  /// quelque chose qui n'arrivera pas.
  bool get isEmptyFromServer => readFromServer && lines.isEmpty;
}

/// Fusionne les lignes LUES sur le serveur et celles POUSSÉES par le flux.
///
/// La lecture fait autorité : c'est elle qui remplit le panneau d'un bot hébergé
/// même quand aucun flux ne pousse rien. Le flux reste un BONUS — ses lignes
/// absentes de la lecture sont ajoutées à la suite, sans doublon exact.
List<String> mergeBotLogLines({
  required List<String> readFromServer,
  required List<String> live,
}) {
  if (readFromServer.isEmpty) {
    return live;
  }
  if (live.isEmpty) {
    return readFromServer;
  }
  final known = readFromServer.toSet();
  final bonus = <String>[
    for (final line in live)
      if (!known.contains(line)) line,
  ];
  if (bonus.isEmpty) {
    return readFromServer;
  }
  return <String>[...readFromServer, ...bonus];
}

/// Lit les logs d'un bot hébergé (`GET /gateway/bots/{id}/logs`) au lieu
/// d'attendre un flux PUSSÉ qui n'arrive jamais.
///
/// POURQUOI cette classe existe : le panneau de logs d'un bot hébergé affichait
/// « En attente d'événements en direct… » avec un badge LIVE, alors que le bot
/// tournait bien sur les serveurs Bot Creator. Or le manager EXPOSE ces lignes en
/// LECTURE (route `GET /gateway/bots/{id}/logs`, scope `read:bots`) : elles
/// étaient lisibles, encore fallait-il les lire. Le flux en direct reste un
/// bonus — s'il pousse quelque chose, l'affichage l'ajoute ; s'il ne pousse rien,
/// les lignes lues s'affichent quand même.
///
/// Le client utilisé est celui que `resolveRemoteRuntime` a déjà construit pour
/// ce bot : aucune URL n'est fabriquée ici, et la lecture passe par la MÊME
/// méthode que la page des logs ([RemoteRuntimeClient.getLogs]).
class BotServerLogsReader {
  BotServerLogsReader({
    required this.botId,
    required this.runtime,
    this.limit = 300,
    this.interval = const Duration(seconds: 5),
  });

  final String? botId;

  /// Runtime résolu pour ce bot : c'est lui qui dit QUI exécute le bot, donc d'où
  /// ses logs doivent être lus.
  final ResolvedRemoteRuntime runtime;

  /// Profondeur de lecture, alignée sur la page des logs.
  final int limit;

  /// Cadence du rafraîchissement tant que le panneau est visible.
  final Duration interval;

  /// Dernier état publié ; le panneau s'y abonne.
  final ValueNotifier<BotServerLogsState> state =
      ValueNotifier<BotServerLogsState>(const BotServerLogsState());

  /// Nombre de lectures réellement adressées au serveur. Les tests s'en servent
  /// pour prouver qu'un bot exécuté en local n'émet AUCUNE requête.
  int serverReadCount = 0;

  Timer? _timer;
  bool _reading = false;
  bool _disposed = false;

  /// Seule situation où lire a un sens : le bot tourne sur les serveurs Bot
  /// Creator (`manager`) et une session a fourni un client.
  ///
  /// Un bot exécuté en LOCAL n'a pas de client manager : sa source reste le
  /// process de ce poste, et le panneau garde son comportement d'origine. Un bot
  /// hébergé sur un `runner` n'est pas concerné non plus : ses logs ont leur
  /// propre route et c'est la page des logs qui les sonde, pas ce lecteur.
  bool get shouldReadFromServer =>
      runtime.source == RemoteRuntimeSource.manager && runtime.client != null;

  /// Première lecture immédiate, puis rafraîchissement périodique. Sans source
  /// serveur, ne fait STRICTEMENT rien : aucune requête, aucun minuteur armé.
  void start() {
    if (_disposed || !shouldReadFromServer) {
      return;
    }
    unawaited(refresh());
    _timer = Timer.periodic(interval, (_) => unawaited(refresh()));
  }

  /// Une lecture des logs du bot hébergé.
  ///
  /// `readFromServer` n'est posé que sur une lecture RÉUSSIE : c'est lui qui
  /// autorise l'état vide honnête, et il ne doit donc jamais être posé par un
  /// échec.
  Future<void> refresh() async {
    final client = runtime.client;
    final id = botId?.trim() ?? '';
    if (_disposed || !shouldReadFromServer || client == null || id.isEmpty) {
      return;
    }
    // Deux ticks ne doivent pas se chevaucher : le second republierait la même
    // liste et ferait clignoter l'état pour rien.
    if (_reading) {
      return;
    }
    _reading = true;
    serverReadCount++;
    try {
      final lines = await client.getLogs(botId: id, limit: limit);
      if (_disposed) {
        return;
      }
      state.value = BotServerLogsState(lines: lines, readFromServer: true);
    } catch (_) {
      if (_disposed) {
        return;
      }
      // La cause n'est ni affichée ni journalisée : un log de bot peut contenir
      // des secrets échappés, et un message d'erreur peut recracher la réponse
      // du serveur telle quelle. Le panneau se contente de dire que la lecture a
      // échoué, sans jamais laisser filtrer de valeur.
      state.value = const BotServerLogsState(readFailed: true);
    } finally {
      _reading = false;
    }
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    state.dispose();
  }
}
