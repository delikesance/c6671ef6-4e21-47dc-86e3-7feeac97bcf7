import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/auth/studio_session.dart';
import 'package:bot_creator_studio/src/dashboard/command_stats.dart';
import 'package:bot_creator_studio/src/premium/studio_feature.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _snapshot = '''
{"botId":"b","hours":24,"totalAllTime":1234567,
 "commands":[{"command":"ping","count":10,"failed":1,"errorRatePct":10,"latencySamples":4,"avgLatencyMs":50,"p50LatencyMs":40,"p95LatencyMs":90},
             {"command":"ban","count":2}],
 "timeline":[{"hour":"100","count":3},{"hour":"102","count":4}],
 "locales":[{"locale":"fr","count":7}],
 "health":{"total":12,"failed":1,"errorRatePct":8.3,"p50LatencyMs":40,"p95LatencyMs":90}}''';

void main() {
  test('lecture du contrat du Manager', () async {
    final api = StudioApi(
      baseUrl: 'https://api.test',
      client: MockClient((r) async {
        expect(r.url.path, '/gateway/bots/b/command-stats');
        expect(r.url.queryParameters['hours'], '168');
        return http.Response(_snapshot, 200);
      }),
    )..accessToken = ({bool force = false}) async => 'tok';
    final stats = await api.commandStats('b', 168);
    expect(stats.totalAllTime, 1234567);
    expect(stats.commands.first.command, 'ping');
    expect(stats.commands.first.hasLatency, isTrue);
    expect(
      stats.commands.last.hasLatency,
      isFalse,
    ); // latence inconnue, pas 0 ms
    expect(stats.health.errorRatePct, 8.3);
    expect(stats.health.hasLatency, isTrue);
    expect(stats.timeline.first.hourBucket, 100);
    expect(stats.locales.single.locale, 'fr');
  });

  test('champs absents ou mal typés : zéro, jamais une exception', () {
    final stats = CommandStats.fromJson({
      'hours': '24',
      'commands': [
        {'command': 'x', 'count': '5'},
        'pas un objet',
      ],
      'health': 'oops',
    });
    expect(stats.hours, 24);
    expect(stats.commands.single.count, 5);
    expect(stats.health.total, 0);
    expect(stats.health.hasLatency, isFalse);
    expect(stats.timeline, isEmpty);
  });

  group('barres du graphique', () {
    // Le seau = heures depuis l'epoch ; « maintenant » tombe dans le seau 1000.
    final now = DateTime.fromMillisecondsSinceEpoch(
      1000 * 3600000 + 600000,
      isUtc: true,
    );

    test('24 h : 24 barres horaires, les trous comptent zéro', () {
      final bars = timelineBars(
        [
          const TimelineEntry(hourBucket: 1000, count: 5), // heure en cours
          const TimelineEntry(hourBucket: 990, count: 2),
          const TimelineEntry(
            hourBucket: 977,
            count: 9,
          ), // 1re heure de la fenêtre
          const TimelineEntry(hourBucket: 976, count: 99), // hors fenêtre
        ],
        24,
        now,
      );
      expect(bars.length, 24);
      expect(bars.last, 5);
      expect(bars[23 - 10], 2);
      expect(bars.first, 9);
      expect(bars.fold<int>(0, (a, b) => a + b), 16);
    });

    test(
      '7 jours : 7 barres journalières alignées sur la fin de la fenêtre',
      () {
        final bars = timelineBars(
          [
            const TimelineEntry(hourBucket: 1000, count: 1),
            const TimelineEntry(
              hourBucket: 977,
              count: 2,
            ), // veille, même seau de 24 h
            const TimelineEntry(hourBucket: 976, count: 4), // seau précédent
          ],
          168,
          now,
        );
        expect(bars.length, 7);
        expect(bars.last, 3); // 1000 et 977 : les 24 dernières heures
        expect(bars[5], 4);
      },
    );

    test('aucune donnée : toutes les barres à zéro', () {
      expect(timelineBars(const [], 24, now), everyElement(0));
    });
  });

  test('analytics détaillées : réservées au Premium', () {
    expect(StudioFeature.analytics.isAvailableFor(StudioPlan.free), isFalse);
    expect(StudioFeature.analytics.isAvailableFor(StudioPlan.premium), isTrue);
  });
}
