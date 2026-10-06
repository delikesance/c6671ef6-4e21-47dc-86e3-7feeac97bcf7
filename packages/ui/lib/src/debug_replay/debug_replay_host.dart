/// Contrat entre l'écran « Rejeu du débogueur » (partagé) et la façon dont
/// chaque client parle au runtime : l'app lit d'abord le runner configuré
/// (`RunnerClient`) puis, à défaut, la mémoire locale de l'appareil ; le Studio
/// passe par `StudioApi`, donc par le Manager qui relaie vers le runner du bot.
library;

import 'package:flutter/widgets.dart';

import 'debug_replay_models.dart';

abstract class DebugReplayHost {
  const DebugReplayHost();

  /// Le compte a-t-il droit au rejeu (capturer, ouvrir le détail) ? Faux :
  /// l'écran reste lisible mais verrouillé, avec [buildUpgradeAction] sous la
  /// carte d'offre. Seule la formule du compte (vérité serveur) en décide.
  bool hasCapability(String? botId);

  /// Ce qui remplace l'action d'achat dans la carte premium : un bouton
  /// d'abonnement dans l'app, la mention « l'abonnement se gère depuis
  /// l'application » dans le Studio.
  Widget buildUpgradeAction(BuildContext context);

  /// Lit les rejeux capturés du bot sur le serveur. `null` = AUCUN serveur à
  /// interroger (l'app sans runner configuré) : l'écran lit alors la mémoire
  /// locale ([localReplays]). Lève si le serveur est injoignable ou refuse.
  Future<DebugReplaySnapshot?> fetchReplays(String botId, {int limit = 30});

  /// Efface les rejeux capturés sur le serveur.
  Future<void> clearReplays(String botId);

  /// Active ou coupe la capture sur le serveur ; rend l'état que le serveur
  /// annonce ensuite.
  Future<bool> setCapturing(String botId, bool enabled);

  // ── Source locale (l'app qui exécute le bot sur l'appareil) ────────────────
  //
  // Le Studio n'a rien d'exécuté localement : les valeurs par défaut suffisent.

  /// Une mémoire locale existe-t-elle ? Si oui, un serveur injoignable la
  /// laisse prendre le relais ; sinon l'écran continue d'interroger le serveur
  /// (le bot peut démarrer plus tard).
  bool get hasLocalSource => false;

  bool get localCapturing => false;

  List<DebugReplayRecord> get localReplays => const <DebugReplayRecord>[];

  Stream<List<DebugReplayRecord>> get localReplaysStream =>
      const Stream<List<DebugReplayRecord>>.empty();

  void setLocalCapturing(bool enabled) {}

  void clearLocalReplays() {}
}
