import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/l10n/app_localizations_fr.dart';
import 'package:bot_creator_studio/src/api/start_refusal.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/screens/bots_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

StudioApi _api(MockClient client) =>
    StudioApi(baseUrl: 'https://api.test', client: client)
      ..accessToken = ({bool force = false}) async => 'tok';

void main() {
  test('liste : état déduit comme dans l\'app', () async {
    final api = _api(
      MockClient(
        (_) async => http.Response('''
{"bots":[
 {"bot_id":"1","bot_name":"A","runtime_state":"running"},
 {"bot_id":"2","bot_name":"B","desired_state":"RUNNING","runtime_state":"error"},
 {"bot_id":"3","bot_name":"C","desired_state":"RUNNING"},
 {"bot_id":"4","bot_name":"D"}
]}''', 200),
      ),
    );
    final bots = await api.listBots();
    expect(bots.map((b) => b.running), [true, false, true, false]);
    expect(bots.map((b) => b.stateKnown), [true, true, true, false]);
  });

  test('start : réessaie un refus transitoire puis réussit', () async {
    var calls = 0;
    final api = _api(
      MockClient((request) async {
        expect(request.url.path, '/gateway/bots/42/start');
        calls++;
        return calls < 3
            ? http.Response(
                '{"error":"credits","code":"bot_free_time_required"}',
                409,
              )
            : http.Response('{}', 200);
      }),
    );
    await api.startBot('42', botName: 'Bot', retryDelay: Duration.zero);
    expect(calls, 3);
  });

  test('start : un refus de quota n\'est jamais rejoué', () async {
    var calls = 0;
    final api = _api(
      MockClient((_) async {
        calls++;
        return http.Response(
          '{"error":"nope","code":"bot_quota_reached"}',
          403,
        );
      }),
    );
    Object? caught;
    try {
      await api.startBot('42', retryDelay: Duration.zero);
    } catch (e) {
      caught = e;
    }
    expect(calls, 1);
    expect(StartRefusal.fromError(caught!), StartRefusal.botQuotaReached);
  });

  test('refus : le code fait foi, la phrase sert de repli', () {
    StudioApiException e(String msg, [String? code]) =>
        StudioApiException(msg, statusCode: 403, code: code);
    expect(
      StartRefusal.fromError(e('x', 'own_bots_not_allowed')),
      StartRefusal.excludesOwnBots,
    );
    expect(
      StartRefusal.fromError(e('Turnkey app limit reached')),
      StartRefusal.turnkeyQuotaReached,
    );
    expect(StartRefusal.fromError(e('boom')), isNull);
  });

  test('refus : titres et textes traduits dans chaque langue', () {
    for (final code in ['de', 'en', 'fr', 'ja', 'pt', 'tr']) {
      final locale = Locale(code);
      final l = lookupStudioLocalizations(locale);
      final tr = lookupAppLocalizations(locale);
      for (final refusal in StartRefusal.values) {
        expect(refusal.title(l, tr), isNotEmpty, reason: '$code/$refusal');
        expect(refusal.body(l, tr), isNotEmpty, reason: '$code/$refusal');
      }
    }
    final fr = lookupStudioLocalizations(const Locale('fr'));
    final trFr = lookupAppLocalizations(const Locale('fr'));
    expect(
      StartRefusal.botQuotaReached.title(fr, trFr),
      'Limite de bots en marche atteinte',
    );
  });

  test('stop : POST /stop', () async {
    String? path;
    final api = _api(
      MockClient((request) async {
        path = request.url.path;
        return http.Response('{}', 200);
      }),
    );
    await api.stopBot('7');
    expect(path, '/gateway/bots/7/stop');
  });

  final l = StudioLocalizationsFr();

  test('case hébergement : illimité, restant, préservé', () {
    const running = StudioBot(id: '1', name: 'A', running: true);
    const stopped = StudioBot(id: '1', name: 'A');
    final now = DateTime(2026, 1, 1, 12);
    expect(hostingCopy(l, running, null), isNull);
    expect(
      hostingCopy(
        l,
        running,
        const StudioBotRuntime(premiumFunded: true),
      )!.label,
      'Hébergement inclus',
    );
    final left = hostingCopy(
      l,
      running,
      StudioBotRuntime(sessionExpiresAt: now.add(const Duration(minutes: 90))),
      now: now,
    )!;
    expect(left.label, 'Temps restant');
    expect(left.value, '1 h 30 min');
    final kept = hostingCopy(
      l,
      stopped,
      const StudioBotRuntime(freeMinutes: 45),
    )!;
    expect(kept.label, 'Temps préservé');
    expect(kept.value, 'Réserve : 45 min');
  });

  test(
    'avatar : lu dans la config du bot, résolu sur le CDN Discord',
    () async {
      final api = _api(
        MockClient(
          (_) async => http.Response('''
{"bots":[
 {"bot_id":"7","bot_name":"A","config":{"avatar_hash":"abc123"}},
 {"bot_id":"8","bot_name":"B","avatar_url":"https://img.test/b.png"},
 {"bot_id":"9","bot_name":"C"}
]}''', 200),
        ),
      );
      final bots = await api.listBots();
      expect(
        bots[0].avatarUrl,
        'https://cdn.discordapp.com/avatars/7/abc123.png?size=128',
      );
      expect(bots[1].avatarUrl, 'https://img.test/b.png');
      expect(bots[2].avatarUrl, isNull);
      // La relecture de /status ne perd pas l'avatar.
      expect(bots[0].copyWith(running: true).avatarUrl, bots[0].avatarUrl);
    },
  );

  test(
    'décompte : échéance du serveur, sinon solde compté depuis la lecture',
    () {
      final l = lookupStudioLocalizations(const Locale('fr'));
      const running = StudioBot(id: '1', name: 'A', running: true);
      final now = DateTime(2026, 1, 1, 12);
      final deadline = now.add(const Duration(hours: 2));
      expect(
        hostingCopy(
          l,
          running,
          StudioBotRuntime(sessionExpiresAt: deadline),
          now: now,
        )!.deadline,
        deadline,
      );
      expect(
        hostingCopy(
          l,
          running,
          const StudioBotRuntime(freeMinutes: 90),
          now: now,
        )!.deadline,
        now.add(const Duration(minutes: 90)),
      );
      // Bot arrêté : la réserve ne s'écoule pas.
      expect(
        hostingCopy(
          l,
          const StudioBot(id: '1', name: 'A'),
          const StudioBotRuntime(freeMinutes: 90),
          now: now,
        )!.deadline,
        isNull,
      );
    },
  );

  test('refus nommés : capacité, mise à jour, config refusée', () {
    StudioApiException e(String msg, String code, int status) =>
        StudioApiException(msg, statusCode: status, code: code);
    expect(
      StartRefusal.fromError(e('x', 'runner_capacity', 503)),
      StartRefusal.runnerCapacity,
    );
    expect(
      StartRefusal.fromError(e('x', 'runner_updating', 503)),
      StartRefusal.runnerUpdating,
    );
    expect(
      StartRefusal.fromError(
        e(
          'Invalid config: commands[1].script: Required',
          'invalid_bot_config',
          422,
        ),
      ),
      StartRefusal.invalidConfig,
    );
  });
}
