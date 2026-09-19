import 'package:bot_creator/core/network/poll_cadence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PollCadence', () {
    test('la première mesure est immédiate', () {
      final cadence = PollCadence(nominal: const Duration(seconds: 3));
      expect(cadence.nextDelay(TickOutcome.changed), Duration.zero);
    });

    test('un tick sans changement double le délai jusqu\'au plafond', () {
      final cadence = PollCadence(
        nominal: const Duration(seconds: 3),
        ceiling: const Duration(seconds: 10),
      );
      cadence.consume(TickOutcome.unchanged);
      expect(cadence.current, const Duration(seconds: 3));
      cadence.consume(TickOutcome.unchanged);
      expect(cadence.current, const Duration(seconds: 6));
      cadence.consume(TickOutcome.unchanged);
      expect(cadence.current, const Duration(seconds: 10));
      cadence.consume(TickOutcome.unchanged);
      expect(cadence.current, const Duration(seconds: 10));
    });

    test('un changement retombe immédiatement à la valeur nominale', () {
      final cadence = PollCadence(
        nominal: const Duration(seconds: 3),
        ceiling: const Duration(seconds: 10),
      );
      cadence.consume(TickOutcome.unchanged);
      cadence.consume(TickOutcome.unchanged);
      cadence.consume(TickOutcome.unchanged);
      cadence.consume(TickOutcome.changed);
      expect(cadence.current, const Duration(seconds: 3));
    });

    test('le budget sur 60 s respecte la cible', () {
      // 20 ticks sans changement à 3 s de nominal, plafond 10 s.
      final cadence = PollCadence(
        nominal: const Duration(seconds: 3),
        ceiling: const Duration(seconds: 10),
      );
      var elapsed = Duration.zero;
      var requests = 0;
      for (var i = 0; i < 60; i++) {
        elapsed += cadence.current;
        if (elapsed > const Duration(seconds: 60)) break;
        requests++;
        cadence.consume(TickOutcome.unchanged);
      }
      expect(requests, lessThanOrEqualTo(8));
    });
  });
}
