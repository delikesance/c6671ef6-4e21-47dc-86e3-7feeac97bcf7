import 'dart:convert';

import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/editor/studio_command_history_host.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(String body, [int status = 200]) => http.Response.bytes(
  utf8.encode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

StudioApi _api(List<http.Request> seen, {bool conflict = false}) => StudioApi(
  baseUrl: 'https://api.test',
  client: MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p.endsWith('/history') && r.method == 'GET') {
      return _json(
        '{"versions":[{"history_id":"h1","created_at":"2026-01-02T10:00:00Z",'
        '"size_bytes":120,"author_owner_id":"42"}]}',
      );
    }
    if (p.contains('/rollback/')) {
      return conflict
          ? _json('{"error":"stale","code":"revision_conflict"}', 409)
          : _json('{"revision":"r2"}');
    }
    if (p.endsWith('/history/h1')) {
      return _json('{"content":{"name":"ban"}}');
    }
    return _json('{}');
  }),
)..accessToken = ({bool force = false}) async => 'tok';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('fr'),
  theme: AppTheme.darkTheme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('la modale de l\'app liste les versions du Manager', (
    tester,
  ) async {
    final seen = <http.Request>[];
    final host = StudioCommandHistoryHost(_api(seen), revision: 'r1');
    await tester.pumpWidget(
      _host(CommandHistorySheet(botId: 'b', commandId: 'c', host: host)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('42'), findsOneWidget); // auteur
    expect(find.textContaining('120'), findsOneWidget); // taille
    expect(
      seen.any((r) => r.url.query.contains('limit=5')),
      isTrue,
      reason: 'cinq versions au plus, comme dans l\'app',
    );
  });

  test(
    'restauration : If-Match de la révision courante, puis restored',
    () async {
      final seen = <http.Request>[];
      final host = StudioCommandHistoryHost(_api(seen), revision: 'r1');
      final result = await host.restore('b', 'c', 'h1');
      expect(result.status, CommandRestoreStatus.restored);
      expect(host.restored, isTrue);
      expect(host.revision, 'r2');
      expect(seen.last.headers['if-match'], '"r1"');
    },
  );

  test(
    '409 = conflit (jamais une panne), rien n\'est marqué restauré',
    () async {
      final host = StudioCommandHistoryHost(
        _api(<http.Request>[], conflict: true),
        revision: 'r1',
      );
      final result = await host.restore('b', 'c', 'h1');
      expect(result.status, CommandRestoreStatus.conflict);
      expect(host.restored, isFalse);
    },
  );

  test('aperçu et suppression passent par les routes v2', () async {
    final seen = <http.Request>[];
    final host = StudioCommandHistoryHost(_api(seen));
    expect(await host.preview('b', 'c', 'h1'), {'name': 'ban'});
    await host.delete('b', 'c', 'h1');
    expect(seen.last.method, 'DELETE');
  });
}
