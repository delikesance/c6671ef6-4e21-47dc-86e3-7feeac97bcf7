// Preuve des deux propriétés d'une POUSSÉE de configuration côté client
// (`/gateway/bots/sync`, `/gateway/bots/discord/save`) :
//
//   1. le budget de poussée est RESPECTÉ — il doit être supérieur au budget
//      d'attente du serveur (~2 min), sinon le client ferme la connexion
//      pendant que le serveur travaille encore (journalisé côté serveur en
//      499 / « context canceled ») et la poussée est perdue ;
//   2. un échec APRÈS l'upload du document n'est PAS rejoué : renvoyer les
//      100 Ko de configuration pendant que le serveur traite encore la première
//      doublait la charge, relançait l'attente de pool, et se heurtait au verrou
//      de synchro par bot (409 bot_sync_in_progress).
//
// Le repli « legacy direct sync » reste, lui, réservé au cas pour lequel il
// existe : un stockage d'objets injoignable.
//
// POURQUOI le budget est injecté : le budget réel est de quatre minutes. Un test
// qui le subirait attendrait quatre minutes de vraie horloge ; il l'abaisse donc
// et vérifie ce qui compte — que le budget est respecté, et qu'un échec n'est
// pas rejoué. Le défaut de production reste identique.
import 'dart:async';
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _botId = 'push-no-replay-bot';
const String _uploadUrl = 'https://storage.example.com/upload/config.json';
const String _configUrl =
    'https://configs.example.com/configs/push-no-replay-bot.json';

/// Une configuration PLAUSIBLE : la garde anti-config-vide refuse une charge
/// sans commande, et ce test parle du réseau, pas d'elle.
Map<String, dynamic> _config() => <String, dynamic>{
  'prefix': '!',
  'commands': <dynamic>[
    <String, dynamic>{'name': 'ping'},
  ],
};

http.Response _json(Map<String, dynamic> body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: <String, String>{'content-type': 'application/json'},
);

/// Un client dont la couche HTTP ENREGISTRE chaque requête émise, avec une
/// poussée bornée à [pushBudget] et une reprise à 1 ms (aucune attente réelle).
MainApiClient _client(
  List<http.Request> sink, {
  required Duration pushBudget,
  required FutureOr<http.Response> Function(http.Request request) onSync,
  FutureOr<http.Response> Function(http.Request request)? onUpload,
  Duration? globalTimeout,
  int Function(http.Request request)? onPresignStatus,
}) {
  return MainApiClient(
    baseUrl: 'https://api.example.com',
    accessToken: 'token',
    timeout: globalTimeout,
    retryDelay: const Duration(milliseconds: 1),
    pushTimeout: pushBudget,
    httpClient: MockClient((request) async {
      sink.add(request);
      if (request.method == 'PUT') {
        return onUpload == null
            ? http.Response('', 200)
            : await onUpload(request);
      }
      switch (request.url.path) {
        case '/gateway/bots/presign-config':
          return _json(<String, dynamic>{
            'botId': _botId,
            'configUrl': _configUrl,
            'uploadUrl': _uploadUrl,
          }, onPresignStatus?.call(request) ?? 200);
        case '/gateway/bots/sync':
        case '/bots/sync':
          return onSync(request);
        default:
          return http.Response('not found', 404);
      }
    }),
  );
}

List<http.Request> _calls(List<http.Request> sink, String path) =>
    sink.where((request) => request.url.path == path).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test(
    'un échec de synchro après l\'upload n\'est PAS rejoué (1 seul envoi)',
    () async {
      final sink = <http.Request>[];
      final client = _client(
        sink,
        pushBudget: const Duration(seconds: 2),
        onSync: (_) => _json(<String, dynamic>{
          'code': 'internal_error',
          'message': 'context canceled',
        }, 500),
      );

      await expectLater(
        client.syncBot(_botId, 'PushBot', _config(), force: true),
        throwsA(isA<Exception>()),
      );

      final syncCalls = _calls(sink, '/gateway/bots/sync');
      expect(
        syncCalls.length,
        1,
        reason: 'une poussée ne se rejoue pas : $syncCalls',
      );
      // Le corps porte l'URL du document, PAS la configuration : un repli
      // (« config ») ferait repartir les 100 Ko.
      expect(syncCalls.single.body.contains('"configUrl"'), isTrue);
      expect(syncCalls.single.body.contains('"config"'), isFalse);
      expect(_calls(sink, '/gateway/bots/presign-config').length, 1);
      expect(
        sink.where((request) => request.method == 'PUT').length,
        1,
        reason: 'le document ne doit être téléversé qu\'une fois',
      );
    },
  );

  test(
    'un stockage d\'objets injoignable, lui, garde son repli direct',
    () async {
      final sink = <http.Request>[];
      final client = _client(
        sink,
        pushBudget: const Duration(seconds: 2),
        onUpload: (_) => http.Response('', 500),
        onSync: (_) => _json(<String, dynamic>{'ok': true}, 200),
      );

      await client.syncBot(_botId, 'PushBot', _config(), force: true);

      final syncCalls = _calls(sink, '/gateway/bots/sync');
      expect(syncCalls.length, 1);
      expect(
        syncCalls.single.body.contains('"config"'),
        isTrue,
        reason:
            'le repli direct doit porter la configuration : '
            '${syncCalls.single.body}',
      );
      expect(syncCalls.single.body.contains('"configUrl"'), isFalse);
    },
  );

  test('le budget de poussée est appliqué : pas le timeout global', () async {
    final sink = <http.Request>[];
    final client = _client(
      sink,
      // Le timeout global (30 s en production) abandonnerait ici.
      globalTimeout: const Duration(milliseconds: 120),
      pushBudget: const Duration(seconds: 2),
      onSync: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        return _json(<String, dynamic>{'ok': true}, 200);
      },
    );

    await client.syncBot(_botId, 'PushBot', _config(), force: true);

    expect(_calls(sink, '/gateway/bots/sync').length, 1);
  });

  test(
    'le budget de poussée est BORNÉ : un dépassement abandonne une fois',
    () async {
      final sink = <http.Request>[];
      final client = _client(
        sink,
        pushBudget: const Duration(milliseconds: 150),
        onSync: (_) async {
          await Future<void>.delayed(const Duration(milliseconds: 600));
          return _json(<String, dynamic>{'ok': true}, 200);
        },
      );

      await expectLater(
        client.syncBot(_botId, 'PushBot', _config(), force: true),
        throwsA(isA<TimeoutException>()),
      );

      expect(
        _calls(sink, '/gateway/bots/sync').length,
        1,
        reason: 'même un dépassement ne doit PAS être rejoué',
      );
    },
  );

  test('les routes NON-poussées gardent leurs reprises', () async {
    final sink = <http.Request>[];
    var presignAttempts = 0;
    final client = _client(
      sink,
      pushBudget: const Duration(seconds: 2),
      onSync: (_) => _json(<String, dynamic>{'ok': true}, 200),
      onPresignStatus: (_) => ++presignAttempts == 1 ? 503 : 200,
    );

    final ticket = await client.presignBotConfig(botId: _botId);
    expect(ticket.configUrl, _configUrl);
    expect(
      _calls(sink, '/gateway/bots/presign-config').length,
      2,
      reason: 'une lecture sans effet doit encore être reprise',
    );
  });
}
