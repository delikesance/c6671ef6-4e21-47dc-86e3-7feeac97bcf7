/// Cadence de sondage adaptative partagée par tous les écrans à polling.
///
/// Principe : tant que la donnée ne change pas, on espace les requêtes (×2 jusqu'au
/// plafond) ; dès qu'elle change, on revient à l'intervalle nominal pour que
/// l'utilisateur voie la suite arriver tout de suite. Sondage et poussée ne sont pas
/// concurrents : ceci ne concerne que le contenu (logs, métriques), jamais l'état, qui
/// arrive par le canal temps réel.
class PollCadence {
  PollCadence({
    required this.nominal,
    this.ceiling = const Duration(seconds: 10),
  }) : assert(nominal > Duration.zero, 'nominal doit être > 0'),
       assert(ceiling >= nominal, 'ceiling doit être >= nominal'),
       _current = nominal;

  final Duration nominal;
  final Duration ceiling;

  Duration _current;

  /// Nombre de ticks consécutifs sans changement. Compté explicitement parce que
  /// `current` seul ne suffit pas à savoir où on en est dans la progression : on
  /// doit pouvoir distinguer la première accalmie d'un régime calme installé.
  int _unchangedTicks = 0;

  /// Délai à attendre avant le prochain tick.
  Duration get current => _current;

  /// Délai pour le tout premier tick : immédiat.
  Duration nextDelay(TickOutcome outcome) {
    consume(outcome);
    return Duration.zero;
  }

  /// Enregistre le résultat d'un tick et ajuste le délai suivant.
  void consume(TickOutcome outcome) {
    if (outcome == TickOutcome.changed) {
      _unchangedTicks = 0;
      _current = nominal;
      return;
    }
    _unchangedTicks++;
    // Un seul tick identique ne prouve rien : une unique accalmie ne doit pas déjà
    // coûter de la latence à l'utilisateur. On n'espace qu'à partir du deuxième tick
    // sans changement, et on atteint quand même le plafond au troisième.
    if (_unchangedTicks < 2) {
      _current = nominal;
      return;
    }
    final doubled = _current * 2;
    _current = doubled > ceiling ? ceiling : doubled;
  }

  /// Retour utilisateur (scroll, pull-to-refresh, action explicite) : on repart au
  /// nominal, la donnée change probablement tout de suite.
  void reset() {
    _unchangedTicks = 0;
    _current = nominal;
  }
}

/// Résultat d'un tick de sondage.
enum TickOutcome {
  /// La donnée a changé depuis le tick précédent.
  changed,

  /// La donnée est identique : on peut espacer.
  unchanged,
}
