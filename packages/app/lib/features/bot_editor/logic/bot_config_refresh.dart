import 'package:flutter/foundation.dart';

/// Signal « la configuration d'un bot vient d'être REMPLACÉE depuis le serveur ».
///
/// Posé au seul endroit qui remplace la copie locale d'un bot
/// (`applyManagerConfigToLocal`) : restauration de version, synchronisation
/// entrante, amorçage de session. Les écrans qui affichent cette copie (liste des
/// commandes, workflows, variables) s'y abonnent pour se recharger.
///
/// Sans ce signal, ils gardent l'état d'AVANT l'opération jusqu'à ce qu'on quitte
/// la page et qu'on la rouvre : c'est ce qui faisait qu'une restauration de
/// version ne se voyait pas dans la liste des commandes, qui continuait
/// d'afficher les commandes de l'ancien état.
class BotConfigRefreshNotifier extends ChangeNotifier {
  BotConfigRefreshNotifier._();

  static final BotConfigRefreshNotifier instance = BotConfigRefreshNotifier._();

  String? _botId;
  int _revision = 0;

  /// Dernier bot dont la configuration a été remplacée (`null` si jamais).
  String? get botId => _botId;

  /// Compteur monotone. Un abonné qui compare des états doit pouvoir distinguer
  /// deux remplacements successifs du MÊME bot : un `botId` identique ne
  /// signalerait rien de nouveau.
  int get revision => _revision;

  /// À appeler APRÈS que la copie locale a été remplacée — jamais pendant : les
  /// abonnés relisent le stockage et liraient un état à moitié écrit.
  void notifyConfigReplaced(String botId) {
    _botId = botId;
    _revision++;
    notifyListeners();
  }
}
