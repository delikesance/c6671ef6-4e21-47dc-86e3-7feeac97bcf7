// Preuve de la précondition `expectRevision` de la poussée COMPLÈTE
// (`POST /gateway/bots/sync`) : le Studio ou un autre appareil qui écrit entre
// notre lecture et notre poussée ne doit plus être écrasé en silence.
//
//   (a) serveur qui l'annonce : la poussée porte la révision vue ;
//   (b) serveur ancien (pas de sonde) : aucun champ ajouté (le manager ancien
//       rejette les champs inconnus) ;
//   (c) 409 bot_config_revision_conflict : traité comme « le serveur a avancé »
//       (la question est posée, rien n'est écrasé) ;
//   (d) la révision rendue par la poussée est retenue sans aller-retour.
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _payload() => <String, dynamic>{
  'runtimeEngine': 'javascript',
  'commands': <dynamic>[
    <String, dynamic>{'id': 'cmd-local', 'name': 'ping', 'script': 'reply();'},
  ],
  'events': <dynamic>[],
};

bool _isSyncPost(http.Request r) =>
    r.method == 'POST' && r.url.path.endsWith('/bots/sync');

MainApiClient _client(
  String botId,
  List<http.Request> sink, {
  bool announceFullPush = true,
  bool conflict = false,
  String? pushedRevision,
}) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    if (request.method == 'POST' &&
        request.url.path.endsWith('/presign-config')) {
      return http.Response(
        jsonEncode(<String, String>{
          'botId': botId,
          'configUrl': 'https://cdn.example.com/configs/$botId.json',
          'uploadUrl': 'https://cdn.example.com/upload/$botId',
        }),
        200,
      );
    }
    if (request.url.host == 'cdn.example.com') {
      return http.Response('{}', 200);
    }
    if (request.method == 'GET' && request.url.path == '/api/v2/capabilities') {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'granular_api': '1',
          'config_revision_aware': true,
          'command_history': false,
          'command_history_limit': 0,
          if (announceFullPush) 'full_push_revision': true,
        }),
        200,
      );
    }
    if (request.method == 'GET' &&
        request.url.path == '/api/v2/bots/$botId/commands') {
      return http.Response(
        jsonEncode(<String, dynamic>{
          'bot_id': botId,
          'revision': 'r2',
          'commands': <Map<String, String>>[
            <String, String>{'id': 'cmd-local', 'name': 'ping'},
          ],
        }),
        200,
      );
    }
    if (_isSyncPost(request)) {
      if (conflict) {
        return http.Response(
          jsonEncode(<String, String>{
            'code': 'bot_config_revision_conflict',
            'message': 'stale',
          }),
          409,
        );
      }
      return http.Response(
        jsonEncode(<String, dynamic>{
          'ok': true,
          'runner_synced': true,
          'config_revision': ?pushedRevision,
        }),
        200,
      );
    }
    return http.Response('{}', 200);
  }),
);

Map<String, dynamic> _syncBody(List<http.Request> requests) =>
    jsonDecode(requests.firstWhere(_isSyncPost).body) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('(a) le serveur l\'annonce: la poussée porte la révision vue', () async {
    final requests = <http.Request>[];
    final client = _client('fp-a', requests);
    client.rememberServerRevision('fp-a', 'r2');

    await client.syncBot('fp-a', 'Bot', _payload(), force: true);
    expect(_syncBody(requests)['expectRevision'], 'r2');
  });

  test('(b) serveur ancien: aucun champ ajouté à la poussée', () async {
    final requests = <http.Request>[];
    final client = _client('fp-b', requests, announceFullPush: false);
    client.rememberServerRevision('fp-b', 'r2');

    await client.syncBot('fp-b', 'Bot', _payload(), force: true);
    expect(_syncBody(requests).keys, isNot(contains('expectRevision')));
  });

  test(
    '(c) 409 de révision: le serveur a avancé, rien n\'est écrasé',
    () async {
      final requests = <http.Request>[];
      final client = _client('fp-c', requests, conflict: true);
      client.rememberServerRevision('fp-c', 'r2');

      await expectLater(
        client.syncBot('fp-c', 'Bot', _payload(), force: true),
        throwsA(isA<BotConfigServerAheadException>()),
      );
      // Écraser en connaissance de cause reste possible, sans précondition.
      final overwrite = _client('fp-c2', <http.Request>[]);
      await overwrite.syncBot(
        'fp-c2',
        'Bot',
        _payload(),
        force: true,
        overwriteServerChanges: true,
      );
    },
  );

  test('(d) la révision rendue par la poussée est retenue', () async {
    final requests = <http.Request>[];
    final client = _client('fp-d', requests, pushedRevision: 'r3');
    client.rememberServerRevision('fp-d', 'r2');

    await client.syncBot('fp-d', 'Bot', _payload(), force: true);
    expect(client.knownRevisionOf('fp-d'), 'r3');
  });
}
