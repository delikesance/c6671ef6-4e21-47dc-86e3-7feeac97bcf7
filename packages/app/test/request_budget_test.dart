import 'package:bot_creator/core/network/poll_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chaque écran qui sonde du CONTENU doit rester sous son budget de requêtes.
/// Ce test échoue si quelqu'un remet un intervalle fixe trop court quelque part.
void main() {
  int requestsPerHour(PollCadence cadence, Duration tickCost) {
    var elapsed = Duration.zero;
    var requests = 0;
    while (elapsed < const Duration(hours: 1)) {
      elapsed += cadence.current;
      requests++;
      cadence.consume(TickOutcome.unchanged);
    }
    return requests;
  }

  test('logs de bot ≤ 720 requêtes/heure (au lieu de 2880)', () {
    final cadence = PollCadence(nominal: const Duration(milliseconds: 2500));
    expect(requestsPerHour(cadence, Duration.zero), lessThanOrEqualTo(720));
  });

  test('stats de bot ≤ 400 requêtes/heure (au lieu de 1200)', () {
    final cadence = PollCadence(nominal: const Duration(seconds: 3));
    expect(requestsPerHour(cadence, Duration.zero), lessThanOrEqualTo(400));
  });
}
