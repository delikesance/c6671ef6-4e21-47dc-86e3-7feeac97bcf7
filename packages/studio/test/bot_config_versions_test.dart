import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/editor/studio_bot_config_versions_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _key = 'configs/b1/versions/2026-10-03T10h00m00s.json';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

StudioApi _api(
  List<http.Request> seen, {
  int restoreStatus = 200,
  String restoreCode = '',
  bool refuseUnlessForced = false,
}) => StudioApi(
  baseUrl: 'https://api.test',
  client: MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p.endsWith('/versions') && r.method == 'GET') {
      // Le Manager rend une LISTE nue, pas un objet.
      return _json([
        {'key': _key, 'size': 2048, 'time': '2026-10-03T10:00:00Z'},
      ]);
    }
    if (p.endsWith('/versions/content')) {
      return _json({
        'content': {
          'commands': [
            {'id': 'c1', 'name': 'ban'},
            {'id': 'c2', 'name': 'kick'},
          ],
        },
      });
    }
    if (p.endsWith('/versions') && r.method == 'DELETE') {
      return _json({'ok': true});
    }
    if (p.endsWith('/versions/checkpoint')) {
      return _json({
        'config': {'name': 'Bot'},
      });
    }
    if (p.endsWith('/versions/restore')) {
      if (refuseUnlessForced && !r.body.contains('confirmOvershrink')) {
        return _json({
          'error': 'too small',
          'code': 'bot_config_version_too_small',
        }, 409);
      }
      return restoreStatus == 200
          ? _json({'ok': true})
          : _json({
              'error': 'too small',
              if (restoreCode.isNotEmpty) 'code': restoreCode,
            }, restoreStatus);
    }
    if (p.endsWith('/commands')) {
      return _json({
        'commands': [
          {'id': 'c1', 'name': 'ban'},
        ],
      });
    }
    return _json({});
  }),
)..accessToken = ({bool force = false}) async => 'tok';

void main() {
  test('liste, aperçu et suppression : routes et format de l\'app', () async {
    final seen = <http.Request>[];
    final host = StudioBotConfigVersionsHost(_api(seen));

    final versions = await host.list('b1');
    expect(versions.single.key, _key);
    expect(versions.single.size, 2048);
    expect(seen.last.url.path, '/gateway/bots/b1/versions');

    expect(await host.commandNames('b1', _key), ['ban', 'kick']);
    expect(seen.last.url.path, '/gateway/bots/b1/versions/content');
    expect(seen.last.url.queryParameters['key'], _key);

    await host.delete('b1', _key);
    expect(seen.last.method, 'DELETE');
    expect(seen.last.url.path, '/gateway/bots/b1/versions');
    expect(seen.last.url.queryParameters['key'], _key);
  });

  test('checkpoint : POST vide, rend la config archivée', () async {
    final seen = <http.Request>[];
    final config = await _api(seen).checkpointBotConfig('b1');
    expect(config['name'], 'Bot');
    expect(seen.last.method, 'POST');
    expect(seen.last.url.path, '/gateway/bots/b1/versions/checkpoint');
    expect(jsonDecode(seen.last.body), isEmpty);
  });

  test(
    'restauration : clé, puis drapeau de forçage seulement si demandé',
    () async {
      final seen = <http.Request>[];
      final host = StudioBotConfigVersionsHost(_api(seen));

      final plain = await host.restore('b1', _key);
      expect(plain.status, BotConfigRestoreStatus.restored);
      expect(seen.last.url.path, '/gateway/bots/b1/versions/restore');
      expect(jsonDecode(seen.last.body), {'key': _key});

      await host.restore('b1', _key, confirmOvershrink: true);
      expect(jsonDecode(seen.last.body), {
        'key': _key,
        'confirmOvershrink': true,
      });

      expect(await host.currentCommandCount('b1'), 1);
      await host.applyRestoredLocally('b1'); // pas de copie locale : sans effet
    },
  );

  test(
    '409 bot_config_version_too_small = plancher, jamais une panne',
    () async {
      final host = StudioBotConfigVersionsHost(
        _api(
          <http.Request>[],
          restoreStatus: 409,
          restoreCode: 'bot_config_version_too_small',
        ),
      );
      final result = await host.restore('b1', _key);
      expect(result.status, BotConfigRestoreStatus.floorRefused);
    },
  );

  test('autre refus : échec avec la raison du serveur', () async {
    final host = StudioBotConfigVersionsHost(
      _api(<http.Request>[], restoreStatus: 500, restoreCode: 'boom'),
    );
    final result = await host.restore('b1', _key);
    expect(result.status, BotConfigRestoreStatus.failed);
    expect(result.reason, contains('HTTP 500'));
    expect(result.reason, contains('boom'));
  });

  testWidgets('l\'écran de l\'app liste les versions du Manager', (
    tester,
  ) async {
    final seen = <http.Request>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        theme: AppTheme.darkTheme(),
        home: BotConfigVersionsPage(
          botId: 'b1',
          host: StudioBotConfigVersionsHost(_api(seen)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(fr.bot_config_versions_title), findsOneWidget);
    expect(find.text('2.0 KB'), findsOneWidget);
    expect(find.text(fr.history_preview), findsOneWidget);
    expect(find.text(fr.bot_config_versions_restore), findsOneWidget);
  });

  testWidgets('version trop petite : on propose de forcer, puis on restaure', (
    tester,
  ) async {
    final seen = <http.Request>[];
    final fr = await AppLocalizations.delegate.load(const Locale('fr'));
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        theme: AppTheme.darkTheme(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => BotConfigVersionsPage(
                  botId: 'b1',
                  host: StudioBotConfigVersionsHost(
                    _api(seen, refuseUnlessForced: true),
                  ),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.bot_config_versions_restore));
    await tester.pumpAndSettle();
    // Confirmation : la version contient deux commandes.
    expect(find.text('• ban'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(FilledButton, fr.bot_config_versions_restore),
    );
    await tester.pumpAndSettle();
    // Refusée par le plancher : le dialogue de restauration forcée.
    expect(
      find.text(fr.bot_config_versions_force_restore_title),
      findsOneWidget,
    );
    await tester.tap(
      find.widgetWithText(
        FilledButton,
        fr.bot_config_versions_force_restore_confirm,
      ),
    );
    await tester.pumpAndSettle();
    // Comme dans l'app, la restauration forcée repasse par la confirmation.
    await tester.tap(
      find.widgetWithText(FilledButton, fr.bot_config_versions_restore),
    );
    await tester.pumpAndSettle();
    // Restaurée, l'écran se referme.
    expect(find.text(fr.bot_config_versions_title), findsNothing);
    final posts = seen
        .where((r) => r.url.path.endsWith('/versions/restore'))
        .toList();
    expect(posts, hasLength(2));
    expect(
      jsonDecode(posts.last.body),
      containsPair('confirmOvershrink', true),
    );
  });
}
