// LA FILE HORS-LIGNE : CINQ PROPRIÉTÉS, ET CE QU'ELLES EMPÊCHENT.
//
// La file existe pour une seule raison : qu'une panne réseau ne fasse plus
// disparaître le travail de l'utilisateur. Chaque test correspond donc à une
// façon de perdre ce travail — ou de le perdre en croyant le garder :
//
//  (a) la mise en file écrit UNE ligne par commande, et la dernière édition
//      gagne (LWW) : deux commandes du même bot ne s'écrasent pas, et rééditer
//      la même commande ne laisse pas deux entrées ;
//  (b) un vidage réussi rejoue par le MÊME `saveCommand` que la sauvegarde
//      normale, puis retire la ligne — la boucle complète est exercée, du
//      refus réseau à l'écriture acceptée par le serveur ;
//  (c) un rejeu qui ÉCHOUE incrémente `attempts`, garde la ligne, et
//      n'empêche PAS les autres entrées de partir ;
//  (d) au bout de N essais, l'entrée n'est plus rejouée mais RESTE visible,
//      avec son erreur et son compteur — rien n'est supprimé en silence ;
//  (e) une entrée au `payload_json` corrompu ne fait pas tomber le vidage des
//      autres, et n'est pas jetée pour autant.
//
// Et deux propriétés de structure, qui sont des exigences du lot :
//  • la table vit dans la MÊME base que les variables (`databases/variables.db`) ;
//  • les trois déclencheurs (réseau, premier plan, poussée réussie) vident la
//    file sans jamais la vider deux fois en même temps.
//
// SQLite EST monté pour de vrai (sqflite ffi), comme dans le reste de la suite :
// une file testée sur une doublure ne dirait rien de sa clé primaire, de son
// UPSERT ni de sa tolérance aux lignes corrompues — c'est-à-dire rien de ce qui
// compte ici.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/storage/command_outbox_store.dart';
import 'package:bot_creator/core/storage/sqlite_variable_store.dart';
import 'package:bot_creator/core/storage/variables_database.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _botId = 'bot-outbox';
const String _commandId = 'cmd-1';

/// Les capacités telles que `GET /api/v2/capabilities` les rend : c'est ce qui
/// ARME la granularité dans le dépôt (sans sonde, tout passe en legacy).
String _capabilitiesJson() => jsonEncode(<String, dynamic>{
  'granular_api': '1',
  'config_revision_aware': true,
  'command_history': true,
  'command_history_limit': 5,
});

Map<String, dynamic> _commandPayload(String name) => <String, dynamic>{
  'id': _commandId,
  'name': name,
  'data': <String, dynamic>{'response': 'pong'},
};

CommandDetail _detail() => CommandDetail(
  botId: _botId,
  commandId: _commandId,
  raw: _commandPayload('ping'),
);

OfflineCommandWrite _write({
  String commandId = _commandId,
  Map<String, dynamic>? command,
  String botId = _botId,
}) => OfflineCommandWrite(
  botId: botId,
  commandId: commandId,
  command: command ?? _commandPayload('ping'),
);

/// Attend qu'une condition devienne vraie, horloge RÉELLE (les vidages passent
/// par des entrées/sorties SQLite asynchrones : un `pump` de temps simulé ne
/// les ferait pas avancer).
Future<void> _waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
  String reason = 'condition non atteinte',
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail(reason);
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Un dossier NEUF par test : la base est ouverte par chemin, et deux tests
    // qui partageraient le même fichier se contamineraient par leurs lignes.
    documentsDir = await Directory.systemTemp.createTemp('command_outbox');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    MainApiClient.resetCircuitBreakers();
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  // ─── (a) La mise en file ──────────────────────────────────────────────────

  group('(a) mise en file', () {
    test('une écriture = une ligne, avec sa charge utile et son horodatage',
        () async {
      final store = CommandOutboxStore();
      await store.enqueue(_write(command: _commandPayload('premier')));

      final entries = await store.entries();
      expect(entries, hasLength(1));
      expect(entries.single.botId, _botId);
      expect(entries.single.commandId, _commandId);
      expect(entries.single.attempts, 0);
      expect(entries.single.lastError, isEmpty);
      expect(entries.single.command, _commandPayload('premier'));
      expect(entries.single.payloadHash, isNotEmpty);
      expect(entries.single.createdAt, greaterThan(0));
    });

    test("deux mises en file de la MÊME commande n'en laissent qu'une, la "
        'dernière (LWW)', () async {
      final store = CommandOutboxStore();
      await store.enqueue(_write(command: _commandPayload('premier')));
      await store.enqueue(_write(command: _commandPayload('second')));

      final entries = await store.entries();
      expect(entries, hasLength(1), reason: 'la clé primaire est (bot, commande)');
      expect(
        entries.single.command,
        _commandPayload('second'),
        reason: 'le dernier qui écrit gagne, par commande',
      );
      expect(await store.count(), 1);
    });

    test('deux commandes DIFFÉRENTES du même bot ne s\'écrasent pas', () async {
      final store = CommandOutboxStore();
      await store.enqueue(_write(commandId: 'cmd-a'));
      await store.enqueue(_write(commandId: 'cmd-b'));

      expect(await store.count(), 2, reason: 'la granularité est par commande');
    });

    test('la même charge utile remise en file après un échec ne remet PAS le '
        'compteur à zéro', () async {
      final store = CommandOutboxStore();
      await store.enqueue(_write());
      await store.recordAttemptFailure(
        botId: _botId,
        commandId: _commandId,
        error: 'réseau coupé',
      );

      await store.enqueue(_write());

      final entry = await store.find(_botId, _commandId);
      expect(
        entry!.attempts,
        1,
        reason: "sans cela, remettre en file la même écriture rendrait "
            "l'abandon au bout de N essais inatteignable",
      );
      expect(entry.lastError, 'réseau coupé');
    });

    test('une charge utile DIFFÉRENTE repart à zéro (nouvelle écriture)',
        () async {
      final store = CommandOutboxStore();
      await store.enqueue(_write(command: _commandPayload('premier')));
      await store.recordAttemptFailure(
        botId: _botId,
        commandId: _commandId,
        error: 'réseau coupé',
      );

      await store.enqueue(_write(command: _commandPayload('deuxieme')));

      final entry = await store.find(_botId, _commandId);
      expect(entry!.attempts, 0);
      expect(entry.lastError, isEmpty);
    });

    test('une clé vide est refusée plutôt que stockée en fantôme', () async {
      final store = CommandOutboxStore();
      await expectLater(
        store.enqueue(_write(botId: '  ')),
        throwsArgumentError,
      );
    });
  });

  // ─── (b) Le vidage réussi ─────────────────────────────────────────────────

  group('(b) vidage réussi', () {
    test('la boucle complète : refus réseau → file → vidage → saveCommand → '
        'ligne retirée', () async {
      var online = true;
      final requests = <http.Request>[];
      final repository = BotDataRepository(
        client: MainApiClient(
          baseUrl: 'https://api.example.com',
          accessToken: 'token',
          retryDelay: Duration.zero,
          httpClient: MockClient((request) async {
            if (!online) {
              throw const SocketException('réseau coupé');
            }
            requests.add(request);
            final path = request.url.path;
            if (path == '/api/v2/capabilities') {
              return http.Response(_capabilitiesJson(), 200);
            }
            if (request.method == 'PATCH') {
              return http.Response(
                jsonEncode(<String, dynamic>{
                  'bot_id': _botId,
                  'revision': 'rev-2',
                  'command': _commandPayload('ping'),
                  'history_id': 'hist-1',
                  'runner_synced': true,
                }),
                200,
              );
            }
            return http.Response('{}', 200);
          }),
        ),
        // Le repli legacy est injecté : s'il était appelé, ce test le verrait.
        legacyPusher: (botId) async {
          requests.add(
            http.Request('POST', Uri.parse('https://legacy.invalid/$botId')),
          );
        },
      );
      final store = CommandOutboxStore();
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: repository.saveCommand,
      );
      // LE HOOK EST CELUI DU DÉPÔT : c'est le contrat entre le lot précédent
      // (qui a posé le champ) et celui-ci (qui l'implémente).
      repository.offlineQueueHook = store.enqueue;

      await repository.probe();
      expect(repository.isGranularEnabled, isTrue);

      // 1. Hors-ligne : la sauvegarde échoue, la commande part en file.
      online = false;
      final outcome = await repository.saveCommand(_botId, _detail());
      expect(outcome, isA<QueuedOffline>());
      expect(await store.count(), 1);
      expect(
        (await store.find(_botId, _commandId))!.command,
        _commandPayload('ping'),
      );

      // 2. Le réseau revient (l'application remet aussi ses disjoncteurs à
      //    zéro au réveil : c'est ce que fait `home_page.dart` sur resume).
      online = true;
      MainApiClient.resetCircuitBreakers();
      requests.clear();

      final report = await drainer.drain();

      expect(report.replayed, 1);
      expect(report.failed, 0);
      expect(report.remaining, 0);
      expect(await store.count(), 0, reason: 'la ligne est retirée après succès');

      final patch = requests.where((request) => request.method == 'PATCH');
      expect(patch, hasLength(1), reason: 'le rejeu passe par /api/v2');
      expect(
        patch.first.url.path,
        '/api/v2/bots/$_botId/commands/$_commandId',
      );
      expect(
        patch.first.body.contains('pong'),
        isTrue,
        reason: 'la charge utile rejouée est celle mise en file',
      );
    });

    test('un vidage sans rien à faire ne fait aucun appel', () async {
      final store = CommandOutboxStore();
      final calls = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          calls.add(command.commandId);
          return const SavedLegacy();
        },
      );

      final report = await drainer.drain();
      expect(calls, isEmpty);
      expect(report.replayed, 0);
      expect(report.remaining, 0);
      expect(report.isSilent, isTrue);
    });
  });

  // ─── (c) L'échec de rejeu ─────────────────────────────────────────────────

  group('(c) rejeu en échec', () {
    test("incrémente attempts, garde la ligne, et n'empêche PAS les autres de "
        'partir', () async {
      final store = CommandOutboxStore();
      final replayed = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          replayed.add(command.commandId);
          if (command.commandId == 'cmd-boom') {
            throw StateError('écriture refusée par le serveur');
          }
          return const SavedGranular(
            revision: 'rev',
            historyId: 'h',
            runnerSynced: true,
          );
        },
      );

      // La commande qui explose est mise en file EN PREMIER : elle est donc
      // rejouée en premier, et c'est bien elle qui ne doit rien bloquer.
      await store.enqueue(_write(commandId: 'cmd-boom'));
      await store.enqueue(_write(commandId: 'cmd-fine'));

      final report = await drainer.drain();

      expect(replayed, <String>['cmd-boom', 'cmd-fine'],
          reason: 'les autres entrées partent, et dans l\'ordre de mise en file');
      expect(report.failed, 1);
      expect(report.replayed, 1);
      expect(report.remaining, 1);

      final kept = await store.find(_botId, 'cmd-boom');
      expect(kept, isNotNull, reason: "rien n'est supprimé quand le rejeu échoue");
      expect(kept!.attempts, 1);
      expect(kept.lastError, contains('écriture refusée'));
      expect(await store.find(_botId, 'cmd-fine'), isNull);
    });

    test('un conflit de révision compte comme un échec, sans clobber', () async {
      final store = CommandOutboxStore();
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async => const ConflictStale(
          currentRevision: 'rev-ailleurs',
        ),
      );
      await store.enqueue(_write());

      final report = await drainer.drain();

      expect(report.failed, 1);
      final entry = await store.find(_botId, _commandId);
      expect(entry!.attempts, 1);
      expect(entry.lastError, commandOutboxStaleConflictError);
    });

    test('un réseau encore absent ne compte PAS comme un échec : la ligne est '
        'intacte et le vidage s\'arrête', () async {
      final store = CommandOutboxStore();
      final replayed = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          replayed.add(command.commandId);
          return const QueuedOffline();
        },
      );
      await store.enqueue(_write(commandId: 'cmd-a'));
      await store.enqueue(_write(commandId: 'cmd-b'));

      final report = await drainer.drain();

      expect(report.stoppedOffline, isTrue);
      expect(report.failed, 0, reason: "hors-ligne n'est pas un échec de rejeu");
      expect(report.deferred, 2);
      expect(replayed, <String>['cmd-a'],
          reason: 'inutile d\'enchaîner les délais : le réseau est global');
      expect(await store.count(), 2, reason: 'les deux lignes sont conservées');
      final kept = await store.find(_botId, 'cmd-a');
      expect(kept!.attempts, 0, reason: 'le compteur ne bouge pas');
      expect(kept.lastError, isEmpty);
    });
  });

  // ─── (d) L'abandon, par commande ──────────────────────────────────────────

  group('(d) abandon par commande', () {
    test('au bout de N essais, plus rejouée mais TOUJOURS visible', () async {
      final store = CommandOutboxStore();
      var replayCalls = 0;
      final drainer = CommandOutboxDrainer(
        store: store,
        maxAttempts: 2,
        replay: (botId, command) async {
          replayCalls++;
          throw StateError('toujours refusé');
        },
      );
      await store.enqueue(_write());

      await drainer.drain();
      await drainer.drain();
      final third = await drainer.drain();

      expect(replayCalls, 2, reason: 'N essais, pas N+1');
      expect(third.abandoned, 1);
      expect(third.failed, 0);
      expect(third.remaining, 1);

      final entries = await store.entries();
      expect(entries, hasLength(1), reason: "elle n'est pas jetée en silence");
      expect(entries.single.attempts, 2);
      expect(entries.single.lastError, isNotEmpty);
      expect(entries.single.isAbandonedAt(2), isTrue);
      expect(entries.single.isReplayableAt(2), isFalse);
    });

    test("une nouvelle édition rouvre l'entrée abandonnée", () async {
      final store = CommandOutboxStore();
      final drainer = CommandOutboxDrainer(
        store: store,
        maxAttempts: 1,
        replay: (botId, command) async => throw StateError('refusé'),
      );
      await store.enqueue(_write(command: _commandPayload('premier')));
      await drainer.drain();
      expect((await store.find(_botId, _commandId))!.attempts, 1);

      // L'utilisateur réessaie : c'est une écriture NOUVELLE, elle repart.
      await store.enqueue(_write(command: _commandPayload('corrige')));

      final entry = await store.find(_botId, _commandId);
      expect(entry!.attempts, 0);
      expect(entry.isReplayableAt(1), isTrue);
    });

    test('l\'abandon ne touche QUE la commande concernée', () async {
      final store = CommandOutboxStore();
      final replayed = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        maxAttempts: 1,
        replay: (botId, command) async {
          if (command.commandId == 'cmd-abandon') {
            throw StateError('refusé pour toujours');
          }
          replayed.add(command.commandId);
          return const SavedLegacy();
        },
      );
      await store.enqueue(_write(commandId: 'cmd-abandon'));
      await store.enqueue(_write(commandId: 'cmd-vivante'));
      await drainer.drain();

      expect(await store.find(_botId, 'cmd-abandon'), isNotNull);
      expect(await store.find(_botId, 'cmd-vivante'), isNull);

      // Un second vidage part bien pour la commande vivante, qui a été rééditée.
      await store.enqueue(_write(commandId: 'cmd-vivante'));
      final second = await drainer.drain();
      expect(second.replayed, 1);
      expect(replayed, <String>['cmd-vivante', 'cmd-vivante']);
      expect(second.abandoned, 1, reason: 'l\'abandonnée reste comptée, visible');
    });
  });

  // ─── (e) L'entrée corrompue ───────────────────────────────────────────────

  group('(e) entrée corrompue', () {
    test('ne fait pas tomber le vidage des autres, et n\'est pas jetée',
        () async {
      final store = CommandOutboxStore();
      final replayed = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          replayed.add(command.commandId);
          return const SavedLegacy();
        },
      );

      // Une ligne écrite DIRECTEMENT dans la table, comme le ferait une
      // écriture interrompue : c'est le seul moyen d'obtenir un payload
      // illisible — `enqueue` refuse par construction d'en produire un.
      final db = await openVariablesDatabase();
      await db.insert(commandOutboxTableName, <String, Object?>{
        'bot_id': _botId,
        'command_id': 'cmd-corrompue',
        'payload_hash': 'peu-importe',
        'payload_json': '{"id": "cmd-corrompue", ', // tronqué
        'attempts': 0,
        'last_error': '',
        'created_at': 1,
      });
      await store.enqueue(_write(commandId: 'cmd-saine'));

      final report = await drainer.drain();

      expect(report.unreadable, 1);
      expect(report.replayed, 1, reason: 'la saine part malgré la corrompue');
      expect(replayed, <String>['cmd-saine']);
      expect(report.remaining, 1);

      final corrompue = await store.find(_botId, 'cmd-corrompue');
      expect(corrompue, isNotNull, reason: "elle n'est pas silencieusement jetée");
      expect(corrompue!.isReadable, isFalse);
      expect(corrompue.command, isNull);
      expect(corrompue.lastError, commandOutboxUnreadablePayloadError);
      expect(
        corrompue.attempts,
        1,
        reason: "son compteur monte : sinon elle serait retentée sans fin",
      );
      // La charge utile d'origine est CONSERVÉE telle quelle : un humain
      // pourra la lire dans la base pour comprendre ce qui s'est passé.
      expect(corrompue.payloadJson, contains('cmd-corrompue'));
    });

    test('une entrée corrompue arrive elle aussi au bout de ses essais',
        () async {
      final store = CommandOutboxStore();
      final drainer = CommandOutboxDrainer(
        store: store,
        maxAttempts: 2,
        replay: (botId, command) async => const SavedLegacy(),
      );
      final db = await openVariablesDatabase();
      await db.insert(commandOutboxTableName, <String, Object?>{
        'bot_id': _botId,
        'command_id': 'cmd-corrompue',
        'payload_hash': 'peu-importe',
        'payload_json': 'pas du json du tout',
        'attempts': 0,
        'last_error': '',
        'created_at': 1,
      });

      await drainer.drain();
      await drainer.drain();
      final third = await drainer.drain();

      expect(third.unreadable, 0);
      expect(third.abandoned, 1);
      final corrompue = await store.find(_botId, 'cmd-corrompue');
      expect(corrompue!.attempts, 2);
      expect(corrompue.lastError, commandOutboxUnreadablePayloadError);
    });
  });

  // ─── La base partagée ─────────────────────────────────────────────────────

  group('schéma et base', () {
    test('la table vit dans la MÊME base que les variables', () async {
      final variableStore = SqliteVariableStore();
      await variableStore.init();
      await variableStore.setGlobalVariable('bot-base', 'compteur', 7);

      final store = CommandOutboxStore();
      await store.enqueue(_write());

      // Les deux tables sont visibles depuis LE MÊME descripteur : si la file
      // avait sa propre base, `variables` serait absente d'ici.
      final db = await openVariablesDatabase();
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name IN ('variables', 'command_outbox')",
      );
      expect(
        tables.map((row) => row['name']).toSet(),
        <Object?>{'variables', commandOutboxTableName},
      );

      // Et le fichier est bien celui des variables.
      final file = File('${documentsDir.path}/databases/variables.db');
      expect(await file.exists(), isTrue);

      // Les deux accès fonctionnent côte à côte, sans se gêner.
      expect(await variableStore.getGlobalVariable('bot-base', 'compteur'), 7);
      expect(await store.count(), 1);
    });

    test("le schéma de la table est exactement celui du plan (§5.2)", () async {
      final db = await openVariablesDatabase();
      final rows = await db.rawQuery(
        "SELECT sql FROM sqlite_master WHERE type = 'table' AND name = ?",
        <Object?>[commandOutboxTableName],
      );
      final sql = (rows.first['sql'] as String).replaceAll(RegExp(r'\s+'), ' ');
      for (final column in <String>[
        'bot_id',
        'command_id',
        'payload_hash',
        'payload_json',
        'attempts',
        'last_error',
        'created_at',
      ]) {
        expect(sql, contains(column), reason: 'colonne manquante : $column');
      }
      expect(sql, contains('PRIMARY KEY (bot_id, command_id)'));
    });
  });

  // ─── Les déclencheurs ─────────────────────────────────────────────────────

  group('déclencheurs', () {
    /// Un coordinateur branché sur une file qui contient une entrée.
    Future<({CommandOutboxCoordinator coordinator, List<String> seen})>
        buildCoordinator() async {
      final store = CommandOutboxStore();
      final seen = <String>[];
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          seen.add(command.commandId);
          return const SavedLegacy();
        },
      );
      await store.enqueue(_write());
      return (
        coordinator: CommandOutboxCoordinator(
          drainer: drainer,
          attachLifecycle: true,
        ),
        seen: seen,
      );
    }

    test('le retour au premier plan déclenche le vidage', () async {
      final built = await buildCoordinator();
      addTearDown(built.coordinator.dispose);
      expect(built.coordinator.isLifecycleAttached, isTrue);

      built.coordinator.didChangeAppLifecycleState(AppLifecycleState.resumed);

      await _waitFor(
        () => built.coordinator.lastReport != null,
        reason: 'le réveil doit déclencher un vidage',
      );
      expect(built.coordinator.lastReport!.replayed, 1);
      expect(built.seen, <String>[_commandId]);
    });

    test('le retour de connectivité déclenche le vidage', () async {
      final built = await buildCoordinator();
      addTearDown(built.coordinator.dispose);

      await built.coordinator.onConnectivityRestored();

      expect(built.coordinator.lastReport!.replayed, 1);
      expect(built.seen, <String>[_commandId]);
    });

    test('une poussée réussie déclenche le vidage', () async {
      final built = await buildCoordinator();
      addTearDown(built.coordinator.dispose);

      await built.coordinator.afterPushOrPullSucceeded(_botId);

      expect(built.coordinator.lastReport!.replayed, 1);
    });

    test('le crochet de poussée est branché puis débranché', () async {
      final built = await buildCoordinator();
      expect(onBotDocumentPushed, isNull, reason: 'inerte par défaut');
      built.coordinator.attachDocumentPushHook();
      expect(onBotDocumentPushed, isNotNull);

      // Exactement le chemin de `_executeSync` : le crochet, puis le vidage.
      await onBotDocumentPushed!(_botId);
      expect(built.coordinator.lastReport!.replayed, 1);

      built.coordinator.dispose();
      expect(onBotDocumentPushed, isNull);
    });

    test('deux vidages simultanés ne rejouent pas deux fois la même écriture',
        () async {
      final store = CommandOutboxStore();
      final gate = Completer<void>();
      var calls = 0;
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async {
          calls++;
          await gate.future;
          return const SavedLegacy();
        },
      );
      await store.enqueue(_write());

      final first = drainer.drain();
      final second = drainer.drain();

      expect(identical(first, second), isTrue,
          reason: 'le second appel reçoit l\'exécution en cours');
      expect(drainer.isDraining, isTrue);
      gate.complete();
      final report = await first;
      await second;

      expect(calls, 1);
      expect(report.replayed, 1);
      expect(drainer.isDraining, isFalse);
      expect(await store.count(), 0);
    });

    test('un vidage impossible ne remonte pas dans le cycle de vie', () async {
      // La base est INJOIGNABLE : c'est le pire cas d'un déclencheur, celui
      // qui ne doit jamais faire remonter une exception depuis un cycle de vie.
      final store = CommandOutboxStore(
        open: () async => throw StateError('base indisponible'),
      );
      final drainer = CommandOutboxDrainer(
        store: store,
        replay: (botId, command) async => const SavedLegacy(),
      );
      final coordinator = CommandOutboxCoordinator(drainer: drainer);

      await coordinator.onAppResumed();

      expect(
        coordinator.lastReport,
        isNull,
        reason: 'aucun rapport inventé : le vidage n\'a pas eu lieu',
      );
    });
  });
}
