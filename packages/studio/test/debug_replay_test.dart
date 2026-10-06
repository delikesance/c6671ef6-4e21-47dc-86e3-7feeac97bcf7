import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/auth/studio_session.dart';
import 'package:bot_creator_studio/src/editor/studio_debug_replay_host.dart';
import 'package:bot_creator_studio/src/premium/studio_feature.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Map<String, dynamic> _replay(String label, {bool error = false}) => {
  'commandLabel': label,
  'triggeredAt': DateTime.utc(2026, 10, 3, 10).toIso8601String(),
  'botId': 'b1',
  'totalMs': 42,
  'frames': [
    {
      'actionType': 'sendMessage',
      'startMs': 0,
      'durationMs': 30,
      'result': 'ok',
      'variablesBefore': {'a': '1'},
      'variablesAfter': {'a': '2'},
    },
    {
      'actionType': 'respondWithMessage',
      'startMs': 30,
      'durationMs': 12,
      'result': error ? 'Error: boom' : 'sent',
    },
  ],
};

/// Un Manager simulé qui relaie le runner : rejeux, capture, effacement.
class _Manager {
  _Manager({this.status = 200});

  /// Statut des lectures (409 = le bot n'est pas lancé).
  int status;
  bool capturing = false;
  bool cleared = false;
  final seen = <http.Request>[];

  http.Client get client => MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p.endsWith('/debug-replays') && r.method == 'GET') {
      if (status != 200) return _json({'error': 'bot is not running'}, status);
      return _json({
        'botId': 'b1',
        'capturing': capturing,
        'replays': cleared
            ? []
            : [_replay('ping'), _replay('boom', error: true)],
      });
    }
    if (p.endsWith('/debug-replays/capture') && r.method == 'POST') {
      capturing = (jsonDecode(r.body) as Map)['enabled'] == true;
      return _json({'ok': true, 'capturing': capturing});
    }
    if (p.endsWith('/debug-replays/clear') && r.method == 'POST') {
      cleared = true;
      return _json({'ok': true});
    }
    return _json({'ok': true});
  });

  StudioApi get api =>
      StudioApi(baseUrl: 'https://api.test', client: client)
        ..accessToken = ({bool force = false}) async => 'tok';

  Iterable<String> get calls => seen.map(
    (r) =>
        '${r.method} ${r.url.path}${r.url.query.isEmpty ? '' : '?${r.url.query}'}',
  );
}

void main() {
  group('hôte du rejeu : format des appels', () {
    test(
      'lire = GET ?limit=30, les rejeux sont décodés comme dans l\'app',
      () async {
        final manager = _Manager();
        final host = StudioDebugReplayHost(
          manager.api,
          plan: StudioPlan.premium,
        );

        final snapshot = await host.fetchReplays('b1');
        expect(manager.calls, ['GET /gateway/bots/b1/debug-replays?limit=30']);
        expect(manager.seen.single.headers['authorization'], 'Bearer tok');
        expect(snapshot!.capturing, isFalse);
        expect(snapshot.replays.map((r) => r.commandLabel), ['ping', 'boom']);
        expect(snapshot.replays.first.actionCount, 2);
        expect(snapshot.replays.first.totalMs, 42);
        expect(snapshot.replays.first.hasError, isFalse);
        expect(snapshot.replays.last.hasError, isTrue);
        expect(snapshot.replays.first.frames.first.variablesAfter, {'a': '2'});
      },
    );

    test(
      'capture = POST {enabled}, l\'état annoncé par le runner est rendu',
      () async {
        final manager = _Manager();
        final host = StudioDebugReplayHost(
          manager.api,
          plan: StudioPlan.premium,
        );

        expect(await host.setCapturing('b1', true), isTrue);
        expect(await host.setCapturing('b1', false), isFalse);
        expect(manager.seen[0].method, 'POST');
        expect(
          manager.seen[0].url.path,
          '/gateway/bots/b1/debug-replays/capture',
        );
        expect(jsonDecode(manager.seen[0].body), {'enabled': true});
        expect(jsonDecode(manager.seen[1].body), {'enabled': false});
      },
    );

    test('effacer = POST …/clear avec un corps vide', () async {
      final manager = _Manager();
      await StudioDebugReplayHost(
        manager.api,
        plan: StudioPlan.premium,
      ).clearReplays('b 1');
      final clear = manager.seen.single;
      expect(clear.method, 'POST');
      expect(clear.url.path, '/gateway/bots/b%201/debug-replays/clear');
      expect(jsonDecode(clear.body), isEmpty);
    });

    test('compte gratuit : rien n\'est demandé au Manager', () async {
      final manager = _Manager();
      final host = StudioDebugReplayHost(manager.api, plan: StudioPlan.free);
      expect(host.hasCapability('b1'), isFalse);
      expect(await host.fetchReplays('b1'), isNull);
      expect(manager.seen, isEmpty);
      expect(StudioFeature.debugReplay.isPremium, isTrue);
    });

    test('le Studio n\'a aucune mémoire locale de rejeux', () {
      final host = StudioDebugReplayHost(
        _Manager().api,
        plan: StudioPlan.premium,
      );
      expect(host.hasLocalSource, isFalse);
      expect(host.localReplays, isEmpty);
      expect(host.localCapturing, isFalse);
    });
  });

  group('écran partagé monté sur le Manager', () {
    Future<void> pump(
      WidgetTester tester,
      _Manager manager, {
      StudioPlan plan = StudioPlan.premium,
    }) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...StudioLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: AppTheme.darkTheme(),
          home: DebugReplayPage(
            botId: 'b1',
            host: StudioDebugReplayHost(manager.api, plan: plan),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Le sondage réarme une minuterie : on démonte la page pour la libérer.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    testWidgets('liste les rejeux, ouvre le détail et rejoue les étapes', (
      tester,
    ) async {
      final manager = _Manager();
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pump(tester, manager);

      expect(find.text('/ping'), findsOneWidget);
      expect(find.text('/boom'), findsOneWidget);
      expect(
        find.textContaining(fr.debug_replay_summary(2, 42)),
        findsNWidgets(2),
      );

      await tester.tap(find.text('/ping'));
      await tester.pumpAndSettle();
      // Vue d'ensemble : les deux étapes ; un tap ouvre le détail de l'étape.
      expect(find.text('Send Message'), findsOneWidget);
      expect(find.text('Respond With Message'), findsOneWidget);
      await tester.tap(find.text('Send Message'));
      await tester.pumpAndSettle();
      expect(find.text(fr.debug_replay_result_label), findsOneWidget);
      expect(find.text('ok'), findsOneWidget);
      expect(find.text(fr.debug_replay_variables_label), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('/ping'), findsOneWidget);
      await close(tester);
    });

    testWidgets(
      'capturer envoie {enabled: true} et reflète l\'état du runner',
      (tester) async {
        final manager = _Manager();
        final fr = await AppLocalizations.delegate.load(const Locale('fr'));
        await pump(tester, manager);

        await tester.tap(find.byTooltip(fr.debug_replay_start_capture));
        await tester.pumpAndSettle();

        final post = manager.seen.firstWhere((r) => r.method == 'POST');
        expect(post.url.path, '/gateway/bots/b1/debug-replays/capture');
        expect(jsonDecode(post.body), {'enabled': true});
        expect(manager.capturing, isTrue);
        expect(find.byTooltip(fr.debug_replay_stop_capture), findsOneWidget);
        await close(tester);
      },
    );

    testWidgets('effacer demande confirmation puis POST …/clear', (
      tester,
    ) async {
      final manager = _Manager();
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pump(tester, manager);

      await tester.tap(find.byTooltip(fr.debug_replay_clear));
      await tester.pumpAndSettle();
      expect(find.text(fr.debug_replay_clear_confirm), findsOneWidget);
      expect(manager.seen.where((r) => r.method == 'POST'), isEmpty);

      await tester.tap(find.text(fr.delete));
      await tester.pumpAndSettle();

      expect(
        manager.calls,
        contains('POST /gateway/bots/b1/debug-replays/clear'),
      );
      expect(find.text('/ping'), findsNothing);
      expect(find.text(fr.debug_replay_empty_idle), findsOneWidget);
      await close(tester);
    });

    testWidgets(
      'compte gratuit : offre premium, aucune requête, pas de capture',
      (tester) async {
        final manager = _Manager();
        final fr = await AppLocalizations.delegate.load(const Locale('fr'));
        final studio = await StudioLocalizations.delegate.load(
          const Locale('fr'),
        );
        await pump(tester, manager, plan: StudioPlan.free);

        expect(find.text(fr.debug_replay_premium_title), findsOneWidget);
        expect(find.text(fr.debug_replay_premium_desc), findsOneWidget);
        expect(find.text(studio.premiumHint), findsOneWidget);
        expect(find.byTooltip(fr.debug_replay_start_capture), findsNothing);
        expect(find.text(fr.debug_replay_start_capture), findsNothing);
        expect(manager.seen, isEmpty);
        await close(tester);
      },
    );

    testWidgets('bot arrêté : message d\'indisponibilité, puis les rejeux '
        'apparaissent quand le bot répond', (tester) async {
      final manager = _Manager(status: 409);
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      await pump(tester, manager);

      expect(find.text(fr.debug_replay_unavailable), findsOneWidget);
      expect(find.text(fr.debug_replay_start_capture), findsNothing);

      manager.status = 200;
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.text(fr.debug_replay_unavailable), findsNothing);
      expect(find.text('/ping'), findsOneWidget);
      await close(tester);
    });
  });
}
