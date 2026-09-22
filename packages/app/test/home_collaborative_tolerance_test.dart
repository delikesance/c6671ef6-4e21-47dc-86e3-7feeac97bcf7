// Tolérance au SERVEUR PLUS ANCIEN : le déploiement roulant est réel, donc une
// version du manager antérieure au partage peut répondre à `GET /gateway/bots`
// sans le champ `is_collaborative` (ou avec une valeur d'un autre type, un JSON
// relâché). Le client ne doit alors PAS lever, PAS convertir, et rendre un
// ensemble VIDE : tout reste dans « My bots », aucun faux positif de section
// partagée, et l'accueil n'écrase rien.
//
// Montage : client HTTP simulé, comme `test/bot_payload_guard_test.dart` et
// `test/main_api_client_test.dart` — aucun transport réel, chaque requête émise
// est inspectée.
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/home/logic/home_project_split.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Faux manager : sert une liste de bots sur `GET /gateway/bots` et garde trace
/// des requêtes réellement émises.
class _FauxManager {
  _FauxManager(this.body);

  /// Corps JSON complet de la réponse (permet de tester une charge SANS la clé
  /// `bots`, pas seulement une liste vide).
  final Map<String, dynamic> body;

  final List<http.Request> requests = <http.Request>[];

  http.Client client() => MockClient((request) async {
    requests.add(request);
    return http.Response(
      jsonEncode(body),
      // 200 TOUJOURS : un serveur plus ancien n'est pas un serveur en panne.
      200,
      headers: <String, String>{'content-type': 'application/json'},
    );
  });
}

/// Bot tel qu'un serveur plus ancien le renvoie : ni `is_collaborative`, ni
/// droits — seulement son identité.
Map<String, dynamic> _bot(String id, {String? ownerId}) {
  final bot = <String, dynamic>{'bot_id': id, 'name': 'Bot $id'};
  if (ownerId != null) {
    bot['owner_id'] = ownerId;
  }
  return bot;
}

MainApiClient _client(_FauxManager manager, String baseUrl) => MainApiClient(
  baseUrl: baseUrl,
  accessToken: 'jeton-de-test',
  httpClient: manager.client(),
);

void main() {
  test('sans `is_collaborative` : ensemble vide, aucune exception, tout reste '
      'dans « My bots »', () async {
    final bots = <Map<String, dynamic>>[
      _bot('1', ownerId: 'proprietaire-1'),
      _bot('2'),
      _bot('3', ownerId: 'proprietaire-3'),
    ];
    final manager = _FauxManager(<String, dynamic>{'bots': bots});
    final client = _client(manager, 'https://home-tolerance-1.example.com');

    // Aucun `try` : une exception ici ferait échouer le test — c'est la preuve
    // « aucune exception ».
    final owners = await client.fetchCollaborativeBotOwners();

    debugPrint(
      '[PREUVE] serveur sans `is_collaborative` : owners=$owners / '
      'requêtes=${manager.requests.length}',
    );
    expect(owners, isEmpty);

    // Conséquence sur l'accueil : rien ne bascule en « Shared with me ».
    final split = splitHomeProjects(bots, owners.keys.toSet());
    debugPrint(
      '[PREUVE] sections : owned=${split.owned.length} '
      'shared=${split.shared.length}',
    );
    expect(split.shared, isEmpty);
    expect(split.owned, hasLength(3));

    // Un seul appel, sur la route de la liste.
    expect(manager.requests, hasLength(1));
    expect(manager.requests.single.method, 'GET');
    expect(manager.requests.single.url.path, '/gateway/bots');
  });

  test('`is_collaborative: true` => présent ; `false` => absent', () async {
    final manager = _FauxManager(<String, dynamic>{
      'bots': <Map<String, dynamic>>[
        <String, dynamic>{
          ..._bot('partage-1', ownerId: 'proprietaire-1'),
          'is_collaborative': true,
        },
        <String, dynamic>{
          ..._bot('ami-2', ownerId: 'proprietaire-2'),
          'is_collaborative': false,
        },
        <String, dynamic>{..._bot('partage-3'), 'is_collaborative': true},
      ],
    });
    final client = _client(manager, 'https://home-tolerance-2.example.com');

    final owners = await client.fetchCollaborativeBotOwners();

    debugPrint('[PREUVE] marquage explicite : owners=$owners');
    expect(owners.keys, unorderedEquals(<String>['partage-1', 'partage-3']));
    expect(owners['partage-1'], 'proprietaire-1');
    // Propriétaire non annoncé : chaîne vide, jamais une invention locale.
    expect(owners['partage-3'], '');
    expect(owners.containsKey('ami-2'), isFalse);
  });

  test('valeur non booléenne (`"true"` chaîne) : traitée comme ABSENTE, sans '
      'crash ni conversion', () async {
    final manager = _FauxManager(<String, dynamic>{
      'bots': <Map<String, dynamic>>[
        <String, dynamic>{..._bot('chaîne-true'), 'is_collaborative': 'true'},
        <String, dynamic>{..._bot('entier-1'), 'is_collaborative': 1},
        <String, dynamic>{..._bot('nul'), 'is_collaborative': null},
        <String, dynamic>{..._bot('vrai-booléen'), 'is_collaborative': true},
      ],
    });
    final client = _client(manager, 'https://home-tolerance-3.example.com');

    final owners = await client.fetchCollaborativeBotOwners();

    debugPrint('[PREUVE] valeurs non booléennes : owners=$owners');
    expect(owners.keys, <String>['vrai-booléen']);
  });

  test('charge sans clé `bots` : ensemble vide, aucune exception', () async {
    final manager = _FauxManager(<String, dynamic>{'ok': true});
    final client = _client(manager, 'https://home-tolerance-4.example.com');

    final owners = await client.fetchCollaborativeBotOwners();

    debugPrint('[PREUVE] charge sans clé `bots` : owners=$owners');
    expect(owners, isEmpty);
  });
}
