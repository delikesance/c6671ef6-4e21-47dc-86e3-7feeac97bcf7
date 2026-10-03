// Preuve de la MODALE D'HISTORIQUE d'une commande : cinq versions, une
// restauration confirmée, et un `409` traité comme un CONFLIT (jamais comme une
// panne réseau).
//
// Ce que ce fichier prouve, au niveau où chaque propriété se décide — la modale
// est montée SEULE (elle est autonome), le transport est simulé, le dépôt et
// les modèles sont les vrais objets de production :
//   (a) une liste de versions s'affiche avec ses métadonnées TRADUITES (date
//       localisée + auteur + taille, dans la langue de l'interface) ;
//   (b) une liste VIDE dit l'état LÉGITIME, et ne dit pas « indisponible » ;
//   (c) SANS v2 armée, la modale dit POURQUOI l'historique n'existe pas pour ce
//       client, et n'émet AUCUNE requête d'historique ;
//   (d) un `409` de restauration affiche l'état de CONFLIT et propose de
//       RECHARGER ; le rejeu part ensuite avec la révision réellement relue, et
//       jamais avec la périmée ;
//   (e) la restauration DEMANDE CONFIRMATION et n'écrase rien sans accord ;
//   (f) les 9 clés nouvelles sont traduites dans les 6 langues, et les
//       traductions ne sont pas l'anglais recopié.
//
// NON COUVERT ICI, ET DIT TEL QUEL :
//   - le contenu LOCAL de la commande n'est pas rafraîchi par une restauration
//     (limite assumée du lot : la modale n'écrit jamais dans le stockage local) ;
//   - aucune preuve de bout en bout contre un vrai serveur `/api/v2` : le
//     transport est simulé (le contrat HTTP est celui du dépôt, pas du réseau) ;
//   - le MODE HORS-LIGNE réel (socket coupée) n'est pas montable ici : la liste
//     indisponible est prouvée par la réponse serveur en échec, pas par une
//     coupure réseau.
import 'dart:convert';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/command_history_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/intl.dart';

const String _botId = 'history-bot';
const String _commandId = 'cmd-1';
const String _author = '724323829';

/// Les 6 langues servies par l'application.
const List<String> _locales = <String>['en', 'fr', 'de', 'ja', 'pt', 'tr'];

/// Le manager SIMULÉ : il ne connaît que les quatre routes que la modale
/// utilise, et il enregistre chaque requête pour qu'un test puisse prouver ce
/// qui a été émis — et surtout ce qui ne l'a pas été.
class _FakeManager {
  _FakeManager({
    this.capabilitiesAvailable = true,
    this.historyAvailable = true,
    this.versions = const <Map<String, dynamic>>[],
    this.rollbackRefusesOnce = false,
    this.rollbackFloorRefusesOnce = false,
    this.serverRevision = 'rev-server',
  });

  /// Le serveur connaît-il `/api/v2/capabilities` (v2 armée) ?
  bool capabilitiesAvailable;

  /// La route d'historique répond-elle (faux = hors-ligne / serveur en panne) ?
  bool historyAvailable;

  /// La lecture de la commande entière répond-elle ? (faux = le RECHARGEMENT
  /// échoue, ce qui doit empêcher tout rejeu à l'aveugle)
  bool commandReadAvailable = true;

  /// Les métadonnées servies par la route d'historique.
  List<Map<String, dynamic>> versions;

  /// Le premier `rollback` est-il refusé par un `409` de révision périmée ?
  bool rollbackRefusesOnce;

  /// Le premier `rollback` est-il refusé par le PLANCHER de plausibilité
  /// (`409 bot_config_version_too_small`) : la version visée est trop pauvre.
  bool rollbackFloorRefusesOnce;

  /// La révision que le serveur dira lors du RECHARGEMENT.
  String serverRevision = 'rev-server';

  /// Un hôte par banc de test : le disjoncteur et le cache de santé du client
  /// sont STATIQUES et indexés par URL de base. Les partager ferait dépendre
  /// chaque test des pannes des précédents.
  static int _hostCounter = 0;
  final String _host = 'api-${++_hostCounter}.example.com';

  final List<http.Request> requests = <http.Request>[];

  int get historyCalls =>
      requests.where((request) => request.url.path.endsWith('/history')).length;

  List<http.Request> get rollbackCalls => requests
      .where((request) => request.url.path.contains('/rollback/'))
      .toList(growable: false);

  /// Les lectures de la commande ENTIÈRE (`GET …/commands/{commandId}`).
  List<http.Request> get commandReads => requests
      .where(
        (request) =>
            request.method == 'GET' &&
            request.url.path == '/api/v2/bots/$_botId/commands/$_commandId',
      )
      .toList(growable: false);

  MainApiClient client() => MainApiClient(
    // HÔTE UNIQUE PAR BANC : le disjoncteur du client est STATIQUE et indexé par
    // baseUrl. Une URL partagée entre tests ferait qu'un 500 provoqué ici
    // ouvrirait le disjoncteur des tests voisins, et le test échouerait pour une
    // raison qui n'a rien à voir avec ce qu'il vérifie.
    baseUrl: 'https://$_host',
    accessToken: 'token',
    // Les 5xx sont réessayés par le client avec une base d'une seconde : sans ce
    // délai, un test qui provoque volontairement un échec attendrait pour rien.
    retryDelay: const Duration(milliseconds: 1),
    httpClient: MockClient(_handle),
  );

  Future<http.Response> _handle(http.Request request) async {
    requests.add(request);
    final path = request.url.path;

    if (path.endsWith('/api/v2/capabilities')) {
      if (!capabilitiesAvailable) {
        return http.Response(
          jsonEncode(<String, String>{
            'code': 'not_found',
            'message': 'no such route',
          }),
          404,
        );
      }
      return http.Response(
        jsonEncode(<String, dynamic>{
          'granular_api': '1',
          'config_revision_aware': true,
          'command_history': true,
          'command_history_limit': 5,
        }),
        200,
      );
    }

    if (path.endsWith('/history/h1')) {
      if (request.method == 'DELETE') {
        versions = [];
        return http.Response('{"ok":true}', 200);
      }
      return http.Response(
        '{"content":{"id":"cmd-1","reply":"saved-value"}}',
        200,
      );
    }

    if (path.endsWith('/history')) {
      if (!historyAvailable) {
        return http.Response(
          jsonEncode(<String, String>{
            'code': 'internal_error',
            'message': 'history store unreachable',
          }),
          500,
        );
      }
      return http.Response(
        jsonEncode(<String, dynamic>{'versions': versions}),
        200,
      );
    }

    if (path.contains('/rollback/')) {
      if (rollbackFloorRefusesOnce) {
        rollbackFloorRefusesOnce = false;
        // Le refus EXACT du serveur observé en vrai : la version visée pèse
        // moins que le plancher de plausibilité. Ce n'est pas une précondition
        // périmée — relire n'y changerait rien.
        return http.Response(
          jsonEncode(<String, String>{
            'code': 'bot_config_version_too_small',
            'message':
                'bot_config_version_too_small: version '
                'configs/1488275294295949504/versions/2026-09-21T02h37m50s.json '
                'is 1776 bytes (floor is 2048 bytes)',
          }),
          409,
        );
      }
      if (rollbackRefusesOnce) {
        rollbackRefusesOnce = false;
        // Le 409 exact du contrat : il PORTE la révision courante, et c'est ce
        // message que le dépôt relit pour la connaître.
        return http.Response(
          jsonEncode(<String, String>{
            'code': 'bot_config_revision_conflict',
            'message':
                'bot_config_revision_conflict: expected revision "rev-stale" '
                'but the document is at revision "$serverRevision"',
          }),
          409,
        );
      }
      return http.Response(
        jsonEncode(<String, dynamic>{
          'revision': 'rev-restored',
          'history_id': 'h-restored',
          'runner_synced': true,
        }),
        200,
      );
    }

    // Toute autre lecture : la commande ENTIÈRE, avec la révision du serveur.
    // Le drapeau existe pour qu'un test puisse rendre CETTE lecture impossible :
    // sans lui, « recharger avant d'écraser » ne pouvait pas échouer, donc le
    // chemin « on ne rejoue rien à l'aveugle » n'était pas exerçable.
    //
    // L'échec est un 404 PORTANT SON CODE, et pas un 500 : le client RÉESSAIE les
    // 5xx, donc un test qui compte les tentatives de relecture verrait le
    // compteur augmenter de plus d'un — et échouerait sur son propre comptage au
    // lieu de ce qu'il vérifie. Un 404 avec code est une réponse (la commande
    // n'est plus là), pas une panne.
    if (!commandReadAvailable) {
      return http.Response(
        jsonEncode(<String, String>{
          'code': 'bot_command_not_found',
          'message': 'the command does not exist in this bot',
        }),
        404,
      );
    }
    return http.Response(
      jsonEncode(<String, dynamic>{
        'revision': serverRevision,
        'command': <String, dynamic>{'id': _commandId, 'name': 'ping'},
      }),
      200,
    );
  }
}

Map<String, dynamic> _version({
  required String historyId,
  required String createdAt,
  String author = _author,
  int sizeBytes = 4096,
}) => <String, dynamic>{
  'history_id': historyId,
  'created_at': createdAt,
  'author_owner_id': author,
  'size_bytes': sizeBytes,
  'content_hash': 'hash-$historyId',
  'revision': 'rev-$historyId',
};

/// Pompe des images SANS exiger le repos : un indicateur de progression anime
/// en continu tant qu'une opération est en cours, donc `pumpAndSettle` ne se
/// reposerait jamais et ferait échouer le test pour une mauvaise raison.
Future<void> _pumpFrames(WidgetTester tester, {int frames = 24}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

Widget _sheetApp({
  required String locale,
  required String botId,
  required String commandId,
  required BotDataRepository? repository,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CommandHistorySheet(
      botId: botId,
      commandId: commandId,
      repository: repository,
    ),
  ),
);

Future<BotDataRepository> _armedRepository(_FakeManager manager) async {
  final repository = BotDataRepository(client: manager.client());
  await repository.probe();
  expect(
    repository.isGranularEnabled,
    isTrue,
    reason: 'le banc de test doit armer la v2 pour parler d\'historique',
  );
  return repository;
}

void main() {
  testWidgets(
    'preview reads saved content and deletion requires confirmation',
    (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(
        versions: [
          _version(historyId: 'h1', createdAt: '2026-10-03T10:00:00Z'),
        ],
      );
      final repository = await _armedRepository(manager);
      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(find.widgetWithText(TextButton, fr.history_preview));
      await _pumpFrames(tester);
      expect(find.textContaining('saved-value'), findsOneWidget);
      expect(manager.requests.where((r) => r.method != 'GET'), isEmpty);
      await tester.tap(find.byTooltip(fr.common_close).last);
      await _pumpFrames(tester);
      await tester.tap(find.byTooltip(fr.more_options_title));
      await _pumpFrames(tester);
      await tester.tap(find.text(fr.common_delete));
      await _pumpFrames(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, fr.common_cancel));
      await _pumpFrames(tester);
      expect(manager.requests.where((r) => r.method == 'DELETE'), isEmpty);
      await tester.tap(find.byTooltip(fr.more_options_title));
      await _pumpFrames(tester);
      await tester.tap(find.text(fr.common_delete));
      await _pumpFrames(tester);
      await tester.tap(find.widgetWithText(FilledButton, fr.common_delete));
      await _pumpFrames(tester);
      expect(
        manager.requests.where((r) => r.method == 'DELETE').single.url.path,
        '/api/v2/bots/$_botId/commands/$_commandId/history/h1',
      );
      expect(find.text(fr.command_history_empty), findsOneWidget);
      expect(manager.rollbackCalls, isEmpty);
    },
  );

  group('(a) la liste des versions', () {
    testWidgets('affiche date localisée, auteur et taille, dans la langue de '
        'l\'interface', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(
        versions: <Map<String, dynamic>>[
          _version(
            historyId: 'h3',
            createdAt: '2026-09-23T10:00:00Z',
            sizeBytes: 4096,
          ),
          _version(
            historyId: 'h2',
            createdAt: '2026-09-22T18:30:00Z',
            author: '999999',
            sizeBytes: 1,
          ),
        ],
      );
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      // Le titre vient de la clé, pas d'une chaîne en dur.
      expect(find.text(fr.command_history_title), findsOneWidget);

      // La ligne de métadonnées est LE FORMAT traduit : date localisée (fr),
      // auteur, et la taille avec son unité PLURIEL localisée.
      final createdAt = DateTime.parse('2026-09-23T10:00:00Z').toLocal();
      final expectedMeta = fr.command_history_version_meta(
        _author,
        DateFormat.yMd('fr').add_jm().format(createdAt),
        4096,
      );
      debugPrint('[PREUVE] ligne de métadonnées = $expectedMeta');
      expect(find.text(expectedMeta), findsOneWidget);
      expect(expectedMeta, contains('4096'));
      expect(expectedMeta, contains('octets'));
      // Le singulier est pris en charge par le même format.
      expect(find.textContaining('1 octet'), findsOneWidget);

      // Un bouton « Restaurer » par entrée, et rien qui ressemble à une erreur.
      expect(
        find.widgetWithText(TextButton, fr.command_history_restore),
        findsNWidgets(2),
      );
      expect(find.text(fr.command_history_empty), findsNothing);
      expect(find.text(fr.command_history_unavailable_no_v2), findsNothing);
      expect(find.text(fr.bot_config_versions_restore_error), findsNothing);

      // La limite demandée est celle du journal (5), pas une devinette.
      final historyRequest = manager.requests.firstWhere(
        (request) => request.url.path.endsWith('/history'),
      );
      expect(historyRequest.url.queryParameters['limit'], '5');
      debugPrint('[PREUVE] requêtes émises = ${manager.requests.length}');
    });

    testWidgets('l\'anglais sert « bytes » et non l\'unité française', (
      tester,
    ) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final manager = _FakeManager(
        versions: <Map<String, dynamic>>[
          _version(historyId: 'h1', createdAt: '2026-09-23T10:00:00Z'),
        ],
      );
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'en',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      final createdAt = DateTime.parse('2026-09-23T10:00:00Z').toLocal();
      final expectedMeta = en.command_history_version_meta(
        _author,
        DateFormat.yMd('en').add_jm().format(createdAt),
        4096,
      );
      debugPrint('[PREUVE] ligne de métadonnées (en) = $expectedMeta');
      expect(find.text(expectedMeta), findsOneWidget);
      expect(expectedMeta, contains('bytes'));
      expect(expectedMeta, isNot(contains('octets')));
    });
  });

  group('(b) la liste vide', () {
    testWidgets('dit l\'état légitime, pas une indisponibilité ni une panne', (
      tester,
    ) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(versions: const <Map<String, dynamic>>[]);
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(fr.command_history_empty), findsOneWidget);
      // Les deux autres messages de vide ne doivent PAS prendre sa place.
      expect(find.text(fr.command_history_unavailable_no_v2), findsNothing);
      expect(find.text(fr.command_history_unavailable_offline), findsNothing);
      expect(find.text(fr.bot_config_versions_restore_error), findsNothing);
      // Et la liste a bien été DEMANDÉE : « vide » veut dire « le serveur a
      // répondu, et il n'y a rien », pas « on n'a pas osé demander ».
      expect(manager.historyCalls, 1);
    });

    testWidgets('une liste NON RÉCUPÉRÉE n\'est pas affichée comme vide', (
      tester,
    ) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(historyAvailable: false);
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      // L'historique n'est pas cachable localement dans ce lot : la modale dit
      // qu'elle n'a pas pu le récupérer, elle ne bloque pas et ne ment pas.
      expect(find.text(fr.command_history_unavailable_offline), findsOneWidget);
      expect(find.text(fr.command_history_empty), findsNothing);
      debugPrint(
        '[PREUVE] liste indisponible = '
        '${fr.command_history_unavailable_offline}',
      );
    });
  });

  group('(c) sans v2 armée : la modale dit POURQUOI', () {
    testWidgets('aucun dépôt du tout (aucune session)', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: null,
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(fr.command_history_unavailable_no_v2), findsOneWidget);
      // Surtout PAS « aucune version » : l'utilisateur croirait que son bot n'a
      // jamais rien historisé.
      expect(find.text(fr.command_history_empty), findsNothing);
    });

    testWidgets('un serveur sans /api/v2 : la raison est dite, et AUCUNE '
        'requête d\'historique n\'est émise', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(capabilitiesAvailable: false);
      final repository = BotDataRepository(client: manager.client());
      await repository.probe();
      expect(repository.isGranularEnabled, isFalse);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      expect(find.text(fr.command_history_unavailable_no_v2), findsOneWidget);
      expect(find.text(fr.command_history_empty), findsNothing);
      expect(
        manager.historyCalls,
        0,
        reason:
            'sans v2 armée, la route d\'historique ne doit pas être appelée',
      );
      debugPrint(
        '[PREUVE] décision sans v2 = '
        '${fr.command_history_unavailable_no_v2}',
      );
    });
  });

  group('(d) le 409 de restauration est un CONFLIT, pas une panne', () {
    testWidgets('l\'état de conflit s\'affiche, puis « recharger et écraser » '
        'relit AVANT de rejouer avec la révision relue', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(
        rollbackRefusesOnce: true,
        serverRevision: 'rev-server',
        versions: <Map<String, dynamic>>[
          _version(historyId: 'h1', createdAt: '2026-09-23T10:00:00Z'),
        ],
      );
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      // 1. L'utilisateur choisit une version et confirme.
      await tester.tap(
        find.widgetWithText(TextButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);

      // 2. Le 409 est devenu l'ÉTAT DE CONFLIT, pas une erreur.
      expect(manager.rollbackCalls, hasLength(1));
      expect(
        manager.rollbackCalls.first.headers['if-match'],
        isNull,
        reason:
            'aucune révision n\'était connue : la 1re tentative part sans '
            'précondition, et c\'est le serveur qui refuse',
      );
      expect(find.text(fr.command_history_conflict), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, fr.command_history_conflict_reload),
        findsOneWidget,
      );
      expect(
        find.text(fr.bot_config_versions_restore_error),
        findsNothing,
        reason: 'un conflit ne doit JAMAIS être présenté comme un échec',
      );
      debugPrint('[PREUVE] conflit affiché = ${fr.command_history_conflict}');

      // 3. « Recharger et écraser » : une LECTURE d'abord…
      final readsBefore = manager.commandReads.length;
      await tester.tap(
        find.widgetWithText(FilledButton, fr.command_history_conflict_reload),
      );
      await _pumpFrames(tester);

      expect(
        manager.commandReads.length,
        readsBefore + 1,
        reason: 'recharger veut dire RELIRE la version serveur',
      );
      // …et c'est cette lecture qui précède le rejeu.
      final readIndex = manager.requests.lastIndexOf(manager.commandReads.last);
      final replayIndex = manager.requests.lastIndexOf(
        manager.rollbackCalls.last,
      );
      expect(readIndex, lessThan(replayIndex));
      expect(manager.rollbackCalls, hasLength(2));
      expect(
        manager.rollbackCalls.last.headers['if-match'],
        '"rev-server"',
        reason: 'le rejeu doit porter la révision RÉELLEMENT relue',
      );
      expect(
        manager.rollbackCalls.first.headers['if-match'],
        isNot(manager.rollbackCalls.last.headers['if-match']),
      );

      // 4. Le conflit est résolu (et non laissé à l'écran), sans erreur.
      expect(find.text(fr.command_history_conflict), findsNothing);
      expect(find.text(fr.bot_config_versions_restore_error), findsNothing);
    });

    testWidgets('un échec de RECHARGEMENT ne rejoue rien à l\'aveugle', (
      tester,
    ) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(
        rollbackRefusesOnce: true,
        versions: <Map<String, dynamic>>[
          _version(historyId: 'h1', createdAt: '2026-09-23T10:00:00Z'),
        ],
      );
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);
      await tester.tap(
        find.widgetWithText(TextButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);
      expect(find.text(fr.command_history_conflict), findsOneWidget);

      // La relecture ÉCHOUE (le serveur ne rend plus cette commande) : sur un
      // échec de relecture, rien ne doit être rejoué à l'aveugle — c'est le cas
      // qui protege l'utilisateur d'un écrasement avec une révision inventée.
      manager.commandReadAvailable = false;
      var reads = manager.commandReads.length;
      await tester.tap(
        find.widgetWithText(FilledButton, fr.command_history_conflict_reload),
      );
      await _pumpFrames(tester);
      expect(manager.commandReads.length, reads + 1);
      // Le rejeu NE DOIT PAS avoir lieu : rien n'est écrasé sans avoir relu.
      expect(manager.rollbackCalls, hasLength(1));
    });

    testWidgets(
      'un 409 de PLANCHER (version trop pauvre) est un REFUS nommé, pas un '
      'conflit : aucune relecture, un rejeu, la phrase du plancher',
      (tester) async {
        final fr = await AppLocalizations.delegate.load(const Locale('fr'));
        final manager = _FakeManager(
          rollbackFloorRefusesOnce: true,
          versions: <Map<String, dynamic>>[
            _version(historyId: 'h1', createdAt: '2026-09-21T02:37:50Z'),
          ],
        );
        final repository = await _armedRepository(manager);

        await tester.pumpWidget(
          _sheetApp(
            locale: 'fr',
            botId: _botId,
            commandId: _commandId,
            repository: repository,
          ),
        );
        await _pumpFrames(tester);

        // L'utilisateur choisit la version trop pauvre et confirme.
        await tester.tap(
          find.widgetWithText(TextButton, fr.command_history_restore),
        );
        await _pumpFrames(tester);
        await tester.tap(
          find.widgetWithText(FilledButton, fr.command_history_restore),
        );
        await _pumpFrames(tester);

        // La phrase dit le FOND (la version est trop réduite), et elle est
        // TRADUITE : recracher la phrase brute du serveur afficherait un chemin
        // de stockage interne en anglais.
        expect(
          find.text(fr.bot_config_versions_restore_too_small),
          findsOneWidget,
          reason:
              'le refus de plancher doit être nommé, pas résumé en « échec »',
        );
        // AUCUN dialogue de conflit : relire ne changerait rien, donc proposer
        // « recharger et écraser » enverrait l'utilisateur en boucle.
        expect(find.text(fr.command_history_conflict), findsNothing);
        expect(
          find.widgetWithText(FilledButton, fr.command_history_conflict_reload),
          findsNothing,
        );
        // Une seule écriture tentée, et aucune relecture.
        expect(manager.rollbackCalls, hasLength(1));
        expect(manager.commandReads, isEmpty);

        // 2. La décision revient à l'utilisateur : le bouton de restauration
        // FORCÉE est là (la version a déjà tourné pour ce bot).
        final forceButton = find.widgetWithText(
          FilledButton,
          fr.bot_config_versions_force_restore_confirm,
        );
        expect(forceButton, findsOneWidget);
        await tester.tap(forceButton);
        await _pumpFrames(tester);

        // 3. Le rejeu DEMANDE la restauration forcée — la preuve est dans le
        // corps de la requête, pas dans une intention.
        expect(manager.rollbackCalls, hasLength(2));
        expect(
          manager.rollbackCalls.last.body,
          contains('confirmOvershrink'),
          reason:
              'forcer la restauration se DEMANDE au serveur, ça ne se déduit pas',
        );
        // Le serveur accepte la restauration forcée : l'écran de refus disparaît.
        expect(
          find.text(fr.bot_config_versions_restore_too_small),
          findsNothing,
        );
        debugPrint(
          '[PREUVE] refus de plancher affiché = '
          '${fr.bot_config_versions_restore_too_small}',
        );
      },
    );
  });

  group('(e) la restauration demande confirmation', () {
    testWidgets('sans accord, AUCUNE écriture n\'est émise', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final manager = _FakeManager(
        versions: <Map<String, dynamic>>[
          _version(historyId: 'h1', createdAt: '2026-09-23T10:00:00Z'),
        ],
      );
      final repository = await _armedRepository(manager);

      await tester.pumpWidget(
        _sheetApp(
          locale: 'fr',
          botId: _botId,
          commandId: _commandId,
          repository: repository,
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(
        find.widgetWithText(TextButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);

      // La question est posée, et elle dit ce qui va être remplacé.
      expect(find.text(fr.command_history_restore_confirm), findsOneWidget);
      debugPrint(
        '[PREUVE] confirmation = ${fr.command_history_restore_confirm}',
      );

      await tester.tap(find.widgetWithText(OutlinedButton, fr.common_cancel));
      await _pumpFrames(tester);

      expect(
        manager.rollbackCalls,
        isEmpty,
        reason: 'refuser la confirmation ne doit écrire RIEN',
      );

      // Puis un accord explicite : là seulement, une écriture part.
      await tester.tap(
        find.widgetWithText(TextButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);
      await tester.tap(
        find.widgetWithText(FilledButton, fr.command_history_restore),
      );
      await _pumpFrames(tester);

      expect(manager.rollbackCalls, hasLength(1));
      expect(
        manager.rollbackCalls.single.url.path,
        contains('/rollback/h1'),
        reason: 'c\'est la version CHOISIE qui est restaurée',
      );
    });
  });

  group('(f) les clés existent dans les 6 langues', () {
    test('les 9 clés nouvelles sont traduites partout, et pas recopiées de '
        'l\'anglais', () async {
      final titles = <String, String>{};
      final conflicts = <String, String>{};

      for (final code in _locales) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        expect(l10n.command_history_title.trim(), isNotEmpty);
        expect(l10n.command_history_empty.trim(), isNotEmpty);
        expect(l10n.command_history_restore.trim(), isNotEmpty);
        expect(l10n.command_history_conflict.trim(), isNotEmpty);
        expect(l10n.command_history_conflict_reload.trim(), isNotEmpty);
        expect(l10n.command_history_unavailable_no_v2.trim(), isNotEmpty);
        expect(l10n.command_history_unavailable_offline.trim(), isNotEmpty);
        expect(l10n.command_history_restore_confirm.trim(), isNotEmpty);
        expect(
          l10n.command_history_version_meta('a', 'd', 2).trim(),
          isNotEmpty,
        );
        titles[code] = l10n.command_history_title;
        conflicts[code] = l10n.command_history_conflict;
      }

      debugPrint('[PREUVE] titres = $titles');
      // Une traduction RÉELLE n'est pas l'anglais recopié.
      expect(titles['fr'], isNot(titles['en']));
      expect(titles['de'], isNot(titles['en']));
      expect(titles['ja'], isNot(titles['en']));
      expect(titles['pt'], isNot(titles['en']));
      expect(titles['tr'], isNot(titles['en']));
      expect(conflicts['ja'], isNot(conflicts['en']));

      // Le format porte les trois métadonnées, dans les 6 langues.
      for (final code in _locales) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        final formatted = l10n.command_history_version_meta(
          'auteur',
          'date',
          3,
        );
        expect(formatted, contains('auteur'));
        expect(formatted, contains('date'));
        expect(formatted, contains('3'));
      }
    });
  });
}
