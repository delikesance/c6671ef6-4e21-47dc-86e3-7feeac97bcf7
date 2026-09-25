// LE DÉPÔT DE DONNÉES D'UN BOT : LES SIX PROPRIÉTÉS QUI COMPTENT.
//
// Ce fichier teste le SEUL endroit de l'application qui choisit le format
// (/api/v2 ou document entier). Ce choix ne doit jamais pouvoir bloquer une
// sauvegarde, et chaque test correspond à une façon de le casser :
//
//  (a) la capacité est SONDÉE, pas supposée — présente, la lecture passe par v2 ;
//  (b) ABSENTE (404/405), tout passe en legacy — c'est un ancien serveur, cas
//      nominal, pas une panne ;
//  (c) un 409 rend ConflictStale SANS rien perdre : le travail local est intact
//      et AUCUNE poussée de document entier n'est rejouée derrière (ce serait
//      exactement l'écrasement que le 409 vient d'empêcher) ;
//  (d) un 404 À L'ÉCRITURE désarme la v2 et rejoue en legacy tout de suite : un
//      ancien serveur ne doit jamais faire perdre une sauvegarde ;
//  (e) une panne TRANSITOIRE part en file SI une file existe — et sans file, le
//      dépôt relaye l'erreur au lieu de prétendre avoir gardé la commande ;
//  (f) la précondition `If-Match` est celle que le dépôt CONNAÎT (issue d'une
//      lecture), entre guillemets, et ABSENTE quand aucune révision n'est connue.
//
// Le transport est simulé (MockClient) et le client est le VRAI : ce qui est
// testé est donc l'ensemble client + dépôt, pas une doublure de confort.

import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  /// Le document ENTIER d'un bot : ce que le chemin legacy télécharge.
  String legacyDocument() => jsonEncode(<String, dynamic>{
    'prefix': '!',
    'commands': <dynamic>[
      <String, dynamic>{
        'id': 'cmd-1',
        'name': 'ping',
        'data': <String, dynamic>{'response': 'pong'},
      },
    ],
  });

  /// Les capacités telles que `GET /api/v2/capabilities` les rend.
  String capabilitiesJson({bool history = true}) => jsonEncode(<String, dynamic>{
    'granular_api': '1',
    'config_revision_aware': true,
    'command_history': history,
    'command_history_limit': history ? 5 : 0,
  });

  /// Monte un dépôt sur un transport simulé. Rend aussi les requêtes vues et les
  /// poussées legacy RÉELLEMENT demandées (le chemin existant est injecté : sans
  /// cela, il faudrait monter le batcher et la base locale pour le savoir).
  ({BotDataRepository repository, List<http.Request> requests, List<String> legacyPushes})
      buildRepository(
    Future<http.Response> Function(http.Request request) handler, {
    void Function(OfflineCommandWrite write)? onQueue,
    bool withQueue = true,
  }) {
    final requests = <http.Request>[];
    final legacyPushes = <String>[];
    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      retryDelay: Duration.zero,
      httpClient: MockClient((request) async {
        requests.add(request);
        return handler(request);
      }),
    );
    return (
      repository: BotDataRepository(
        client: client,
        legacyPusher: (botId) async => legacyPushes.add(botId),
        offlineQueueHook: withQueue
            ? (write) async => onQueue?.call(write)
            : null,
      ),
      requests: requests,
      legacyPushes: legacyPushes,
    );
  }

  CommandDetail detail() => CommandDetail(
        botId: 'bot-1',
        commandId: 'cmd-1',
        raw: <String, dynamic>{'id': 'cmd-1', 'name': 'ping'},
      );

  test('(a) capacite presente : la lecture passe par /api/v2', () async {
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response(capabilitiesJson(), 200);
      }
      if (request.url.path == '/api/v2/bots/bot-1/commands') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'bot_id': 'bot-1',
            'revision': 'rev-1',
            'commands': <dynamic>[
              <String, dynamic>{
                'id': 'cmd-1',
                'name': 'ping',
                'trigger': 'ping',
                'content_hash': 'h1',
              },
            ],
          }),
          200,
        );
      }
      return http.Response(legacyDocument(), 200);
    });

    final capabilities = await built.repository.probe();
    expect(capabilities, isNotNull, reason: 'la sonde doit armer la v2');
    expect(built.repository.isGranularEnabled, isTrue);
    expect(built.repository.hasProbed, isTrue);

    final page = await built.repository.listCommands('bot-1');
    expect(page.commands.map((command) => command.id), <String>['cmd-1']);
    expect(
      built.requests.map((request) => request.url.path),
      contains('/api/v2/bots/bot-1/commands'),
      reason: 'la liste doit venir de la v2, pas du document entier',
    );
    // La lecture est le moment où l'application APPREND la révision.
    expect(built.repository.revisionFor('bot-1'), 'rev-1');
  });

  test('(b) capacite absente (404) : lecture ET ecriture restent en legacy',
      () async {
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response('not found', 404);
      }
      // Le chemin legacy lit un DOCUMENT en deux temps : l'URL auprès du
      // manager, puis le contenu depuis R2. Le mock doit donc servir les deux,
      // sinon le test échouerait sur le transport et non sur le comportement.
      if (request.url.path == '/gateway/bots/bot-1/config') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'configUrl': 'https://r2.example.com/configs/bot-1.json',
          }),
          200,
        );
      }
      if (request.url.host == 'r2.example.com') {
        return http.Response(legacyDocument(), 200);
      }
      return http.Response(legacyDocument(), 200);
    });

    expect(await built.repository.probe(), isNull);
    expect(built.repository.isGranularEnabled, isFalse);

    final page = await built.repository.listCommands('bot-1');
    expect(page.commands.map((command) => command.id), <String>['cmd-1'],
        reason: 'la liste legacy vient du document entier');

    final outcome = await built.repository.saveCommand('bot-1', detail());
    expect(outcome, isA<SavedLegacy>());
    expect(built.legacyPushes, <String>['bot-1'],
        reason: 'sans v2, la sauvegarde doit passer par le chemin legacy');
    expect(
      built.requests.any((request) => request.method == 'PATCH'),
      isFalse,
      reason: 'aucune écriture ne doit partir vers /api/v2 quand elle est absente',
    );
  });

  test('(c) un 409 rend ConflictStale SANS rien perdre ni rejouer', () async {
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response(capabilitiesJson(), 200);
      }
      if (request.method == 'PATCH') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'code': 'bot_config_revision_conflict',
            'message':
                'bot_config_revision_conflict: bot bot-1 is at revision "rev-serveur", the client expected "rev-client"; nothing was written',
          }),
          409,
        );
      }
      return http.Response(legacyDocument(), 200);
    });
    await built.repository.probe();
    await built.repository.listCommands('bot-1');

    final outcome = await built.repository.saveCommand('bot-1', detail());

    expect(outcome, isA<ConflictStale>());
    expect(
      (outcome as ConflictStale).currentRevision,
      'rev-serveur',
      reason:
          'la révision courante est extraite du message borné du serveur, sinon l’interface ne peut pas proposer de recharger',
    );
    expect(
      built.legacyPushes,
      isEmpty,
      reason:
          'rejouer un document entier derrière un 409 est exactement l’écrasement que le 409 vient d’empêcher',
    );
  });

  test('(d) un 404 a l ecriture desarme la v2 et rejoue en legacy', () async {
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response(capabilitiesJson(), 200);
      }
      if (request.method == 'PATCH') {
        return http.Response('not found', 404);
      }
      return http.Response(legacyDocument(), 200);
    });
    await built.repository.probe();

    final outcome = await built.repository.saveCommand('bot-1', detail());

    expect(outcome, isA<SavedLegacy>(),
        reason: 'la commande doit partir quand même, par le document entier');
    expect(built.legacyPushes, <String>['bot-1']);
    expect(built.repository.isGranularEnabled, isFalse,
        reason: 'la v2 doit être désarmée : le serveur ne connaît pas la route');
  });

  test('(e) panne transitoire : en file si elle existe, relayee sinon',
      () async {
    final queued = <OfflineCommandWrite>[];
    final built = buildRepository(
      (request) async {
        if (request.url.path == '/api/v2/capabilities') {
          return http.Response(capabilitiesJson(), 200);
        }
        throw const SocketException('network is down');
      },
      onQueue: queued.add,
    );
    await built.repository.probe();

    final outcome = await built.repository.saveCommand('bot-1', detail());
    expect(outcome, isA<QueuedOffline>());
    expect(queued, hasLength(1));
    expect(queued.single.botId, 'bot-1');
    expect(queued.single.commandId, 'cmd-1');
    expect(queued.single.command['name'], 'ping');

    // SANS file installée : on RELAIE l'erreur au lieu de prétendre avoir gardé
    // la commande. « En attente » alors que rien n'est gardé ferait disparaître
    // le travail de l'utilisateur au premier redémarrage.
    final withoutQueue = buildRepository(
      (request) async {
        if (request.url.path == '/api/v2/capabilities') {
          return http.Response(capabilitiesJson(), 200);
        }
        throw const SocketException('network is down');
      },
      withQueue: false,
    );
    await withoutQueue.repository.probe();
    await expectLater(
      withoutQueue.repository.saveCommand('bot-1', detail()),
      throwsA(isA<SocketException>()),
    );
  });

  test('(f) If-Match : la revision connue, entre guillemets ; absente sinon',
      () async {
    final headers = <String, String?>{};
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response(capabilitiesJson(), 200);
      }
      if (request.url.path == '/api/v2/bots/bot-1/commands') {
        return http.Response(
          jsonEncode(<String, dynamic>{
            'bot_id': 'bot-1',
            'revision': 'rev-1',
            'commands': <dynamic>[],
          }),
          200,
        );
      }
      if (request.method == 'PATCH') {
        headers['if-match'] = request.headers['If-Match'];
        return http.Response(
          jsonEncode(<String, dynamic>{
            'revision': 'rev-2',
            'command': <String, dynamic>{'id': 'cmd-1'},
            'history_id': 'v-9',
            'runner_synced': true,
          }),
          200,
        );
      }
      return http.Response(legacyDocument(), 200);
    });
    await built.repository.probe();
    // Avant toute lecture : aucune révision connue, donc AUCUNE précondition.
    await built.repository.saveCommand('bot-1', detail());
    expect(headers['if-match'], isNull,
        reason:
            'sans révision connue, écrire sans précondition est le cas nominal — le serveur accepte');

    // Après une lecture, l'écriture porte la révision APPRISE, entre guillemets.
    await built.repository.listCommands('bot-1');
    final outcome = await built.repository.saveCommand('bot-1', detail());
    expect(headers['if-match'], '"rev-1"',
        reason:
            'le standard HTTP veut la valeur entre guillemets, et la précondition doit venir de la MÉMOIRE du dépôt');
    expect(outcome, isA<SavedGranular>());
    expect((outcome as SavedGranular).revision, 'rev-2');
    expect(outcome.historyId, 'v-9');
    expect(built.repository.revisionFor('bot-1'), 'rev-2',
        reason: 'l’écriture apprend la nouvelle révision pour l’écriture suivante');
  });

  test('(g) rejeu : la precondition CONSERVEE prime sur la memoire vide', () async {
    // LE CAS DE PRODUCTION : l'application a redemarre, la memoire du depot est
    // vide. Une commande mise en file pendant la panne est rejouee : sans la
    // revision conservee avec elle, le rejeu partirait SANS precondition et
    // ecraserait en silence une version distante plus recente.
    final headers = <String?>[];
    final built = buildRepository((request) async {
      if (request.url.path == '/api/v2/capabilities') {
        return http.Response(capabilitiesJson(), 200);
      }
      if (request.method == 'PATCH') {
        headers.add(request.headers['If-Match']);
        return http.Response(
          jsonEncode(<String, dynamic>{
            'revision': 'rev-2',
            'command': <String, dynamic>{'id': 'cmd-1'},
            'history_id': 'v-9',
            'runner_synced': true,
          }),
          200,
        );
      }
      return http.Response(legacyDocument(), 200);
    });
    await built.repository.probe();
    expect(built.repository.revisionFor('bot-1'), isNull,
        reason: 'apres un redemarrage, le depot ne connait AUCUNE revision');

    // Une entree mise en file par une version anterieure au schema v7 : elle ne
    // porte aucune precondition, et on ne lui en invente pas une.
    await built.repository.saveCommand('bot-1', detail(), ifMatch: null);
    expect(headers.single, isNull,
        reason: 'sans precondition conservee, on garde le comportement d origine');

    // Une entree qui porte sa revision : c'est ELLE qui part, pas la memoire.
    await built.repository.saveCommand('bot-1', detail(), ifMatch: 'rev-7');
    expect(headers.last, '"rev-7"',
        reason: 'le rejeu doit refuser d ecraser une version distante plus recente');
  });
}
