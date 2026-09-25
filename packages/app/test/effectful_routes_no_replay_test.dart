// LES ROUTES À EFFET NE SE REJOUENT PAS.
//
// Le défaut de `_post` est `retryOnFailure = true` avec `_maxRetries = 3` : un
// 5xx, un dépassement de délai ou une coupure réseau envoient JUSQU'À QUATRE
// fois la même action. C'est acceptable pour une lecture, pas pour une action
// dont l'effet est visible côté serveur — le journal de production a gardé la
// trace de poussées de configuration doublées (100 Ko renvoyés, puis 409
// `bot_sync_in_progress` sur les envois suivants), et trois routes restaient au
// défaut :
//
//   - `POST /containers/deploy` : le manager n'a AUCUNE clé d'idempotence sur
//     cette route (`DeployContainer` → `Compute.Deploy`, plus
//     `FreeHostedApp.OnDeployed`). Un rejeu crée un SECOND conteneur, facturé, et
//     reconsomme les minutes offertes.
//   - `POST /registry-credentials` : chaque appel crée une ligne. Un rejeu
//     laisse des doublons d'identifiants indistinguables dans la liste.
//   - `POST /gateway/bots/{id}/start` : action à effet côté serveur (le manager
//     provisionne/réconcilie l'exécution du bot).
//
// Ce fichier prouve les deux faces de la règle : ces trois routes n'émettent
// qu'UNE requête, et une route idempotente garde ses reprises (sinon on aurait
// simplement supprimé le mécanisme de reprise sans s'en apercevoir).
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le même client que la production, avec une reprise à 1 ms (aucune attente
/// réelle) et une couche HTTP qui ENREGISTRE chaque requête émise.
MainApiClient _client(
  List<http.Request> sink, {
  required http.Response Function(http.Request request) respond,
}) {
  return MainApiClient(
    baseUrl: 'https://api.example.com',
    accessToken: 'token',
    retryDelay: const Duration(milliseconds: 1),
    httpClient: MockClient((request) async {
      sink.add(request);
      return respond(request);
    }),
  );
}

http.Response _failure(http.Request request) => http.Response(
  jsonEncode(<String, dynamic>{
    'code': 'internal_error',
    'message': 'panne temporaire',
  }),
  503,
  headers: <String, String>{'content-type': 'application/json'},
);

List<http.Request> _calls(List<http.Request> sink, String path) =>
    sink.where((request) => request.url.path == path).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
  });

  test('POST /containers/deploy n\'est pas rejoué (un conteneur par appel)', () async {
    final sink = <http.Request>[];
    final client = _client(sink, respond: _failure);

    await expectLater(
      client.deployContainer(image: 'img:1', cpuMillis: 1000, memoryMb: 512),
      throwsA(isA<Exception>()),
    );

    expect(
      _calls(sink, '/containers/deploy').length,
      1,
      reason:
          'un rejeu crée un second conteneur FACTURÉ : le manager n\'a pas de clé d\'idempotence ici',
    );
  });

  test('POST /registry-credentials n\'est pas rejoué (une ligne par appel)', () async {
    final sink = <http.Request>[];
    final client = _client(sink, respond: _failure);

    await expectLater(
      client.createRegistryCredential(
        label: 'ghcr',
        registryHost: 'ghcr.io',
        username: 'moi',
        password: 'secret',
      ),
      throwsA(isA<Exception>()),
    );

    expect(
      _calls(sink, '/registry-credentials').length,
      1,
      reason: 'un rejeu laisse des doublons d\'identifiants dans la liste',
    );
  });

  test('POST /gateway/bots/{id}/start n\'est pas rejoué', () async {
    final sink = <http.Request>[];
    final client = _client(sink, respond: _failure);

    await expectLater(
      client.startBot('bot-1'),
      throwsA(isA<Exception>()),
    );

    expect(
      _calls(sink, '/gateway/bots/bot-1/start').length,
      1,
      reason: 'démarrer un bot est une action à effet, pas une lecture',
    );
  });

  test('une route idempotente garde ses reprises (1 + 3 par défaut)', () async {
    final sink = <http.Request>[];
    final client = _client(sink, respond: _failure);

    await expectLater(
      client.claimHostedAppAd(
        placement: 'deploy',
        rewardId: 'reward-1',
        idempotencyKey: 'key-1',
      ),
      throwsA(isA<Exception>()),
    );

    expect(
      _calls(sink, '/containers/claim-ad').length,
      4,
      reason:
          'le rejeu reste le comportement par défaut : cette route porte une clé d\'idempotence',
    );
  });
}
