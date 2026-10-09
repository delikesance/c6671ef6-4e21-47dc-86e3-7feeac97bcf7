// Preuve de la garde « le serveur a avancé » de la poussée COMPLÈTE
// (`POST /gateway/bots/sync`, issue #280).
//
// Le manager n'accepte aucune révision attendue sur cette route : une poussée
// remplace le document entier. Une commande créée ou éditée dans le Studio
// (qui écrit avec une précondition) disparaîtrait donc à la poussée suivante du
// mobile. La garde, côté client, lit la révision et la liste v2 AVANT de pousser.
//
// Ce que ce fichier prouve (le client HTTP simule le manager, comme dans
// `bot_config_overshrink_confirmation_test.dart`) :
//   (a) le serveur porte une commande absente en local ET sa révision diffère de
//       la dernière vue : la poussée est BLOQUÉE (aucun POST de synchro) ;
//   (b) même révision : la poussée part ;
//   (c) `overwriteServerChanges: true` : la poussée part malgré le conflit ;
//   (d) la lecture v2 échoue (serveur ancien, hors ligne) : la poussée part
//       comme avant ;
//   (e) après une poussée réussie la révision est retenue : la suivante ne se
//       bloque pas sur notre propre écriture ;
//   (f) l'orchestration pose la question et ne rejoue en écrasant que sur accord.
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
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

/// Manager simulé : [commandsStatus] != 200 fait échouer la liste v2 ;
/// [revision] est la révision rendue par la liste, qui porte une commande
/// ajoutée au Studio (`cmd-studio`).
MainApiClient _client(
  String botId,
  List<http.Request> sink, {
  String revision = 'r2',
  int commandsStatus = 200,
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
    if (request.method == 'GET' &&
        request.url.path == '/api/v2/bots/$botId/commands') {
      if (commandsStatus != 200) {
        return http.Response('{"message":"nope"}', commandsStatus);
      }
      return http.Response(
        jsonEncode(<String, dynamic>{
          'bot_id': botId,
          'revision': revision,
          'commands': <Map<String, String>>[
            <String, String>{'id': 'cmd-local', 'name': 'ping'},
            <String, String>{'id': 'cmd-studio', 'name': 'from-studio'},
          ],
        }),
        200,
      );
    }
    if (_isSyncPost(request)) {
      return http.Response('{"ok":true}', 200);
    }
    return http.Response('{}', 200);
  }),
);

int _syncCount(List<http.Request> requests) =>
    requests.where(_isSyncPost).length;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('(a) commande serveur absente + révision différente: bloqué', () async {
    final requests = <http.Request>[];
    final client = _client('ahead-a', requests);
    client.rememberServerRevision('ahead-a', 'r1');

    await expectLater(
      client.syncBot('ahead-a', 'Bot', _payload(), force: true),
      throwsA(
        isA<BotConfigServerAheadException>()
            .having((e) => e.serverRevision, 'serverRevision', 'r2')
            .having((e) => e.knownRevision, 'knownRevision', 'r1')
            .having(
              (e) => e.serverOnlyCommandIds,
              'serverOnlyCommandIds',
              <String>['cmd-studio'],
            ),
      ),
    );
    expect(_syncCount(requests), 0, reason: 'rien ne doit partir');
  });

  test('(b) même révision: la poussée part', () async {
    final requests = <http.Request>[];
    final client = _client('ahead-b', requests);
    client.rememberServerRevision('ahead-b', 'r2');

    await client.syncBot('ahead-b', 'Bot', _payload(), force: true);
    expect(_syncCount(requests), 1);
  });

  test(
    '(c) overwriteServerChanges: la poussée part malgré le conflit',
    () async {
      final requests = <http.Request>[];
      final client = _client('ahead-c', requests);
      client.rememberServerRevision('ahead-c', 'r1');

      await client.syncBot(
        'ahead-c',
        'Bot',
        _payload(),
        force: true,
        overwriteServerChanges: true,
      );
      expect(_syncCount(requests), 1);
      // Et le corps n'a aucun champ inconnu du manager (DisallowUnknownFields).
      final body =
          jsonDecode(requests.firstWhere(_isSyncPost).body)
              as Map<String, dynamic>;
      expect(body.keys, isNot(contains('expectRevision')));
      expect(body.keys, isNot(contains('overwriteServerChanges')));
    },
  );

  test('(d) lecture v2 en échec (serveur ancien): la poussée part', () async {
    final requests = <http.Request>[];
    final client = _client('ahead-d', requests, commandsStatus: 404);

    await client.syncBot('ahead-d', 'Bot', _payload(), force: true);
    expect(_syncCount(requests), 1);
  });

  test('(e) la révision est retenue après une poussée réussie', () async {
    final requests = <http.Request>[];
    final client = _client('ahead-e', requests);

    // Première poussée: acceptée en connaissance de cause.
    await client.syncBot(
      'ahead-e',
      'Bot',
      _payload(),
      force: true,
      overwriteServerChanges: true,
    );
    // Seconde, sans l'indicateur: la révision rendue après la première est
    // retenue, donc pas de faux positif.
    await client.syncBot('ahead-e', 'Bot', _payload(), force: true);
    expect(_syncCount(requests), 2);
  });

  test(
    '(f) la question est posée; rejeu en écrasant sur accord seulement',
    () async {
      for (final accept in <bool>[false, true]) {
        final requests = <http.Request>[];
        final id = 'ahead-f-$accept';
        final client = _client(id, requests);
        client.rememberServerRevision(id, 'r1');
        var asked = 0;

        final outcome = await pushBotConfigToleratingOvershrink(
          push: (confirm) => client.syncBot(
            id,
            'Bot',
            _payload(),
            force: true,
            confirmOvershrink: confirm,
          ),
          askConfirmation: () async => false,
          askServerAheadConfirmation: (_) async {
            asked++;
            return accept;
          },
          pushOverwritingServer: (confirm) => client.syncBot(
            id,
            'Bot',
            _payload(),
            force: true,
            confirmOvershrink: confirm,
            overwriteServerChanges: true,
          ),
        );

        expect(asked, 1);
        expect(
          outcome,
          accept
              ? BotConfigPushOutcome.sent
              : BotConfigPushOutcome.serverAheadDeclined,
        );
        expect(_syncCount(requests), accept ? 1 : 0);
      }
    },
  );
}
