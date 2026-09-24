// LA COUCHE GRANULAIRE BRANCHÉE : LA GARDE, LA SONDE, LA FILE, LE SIGNAL.
//
// Ce fichier ne teste pas le dépôt ni la file (ils ont leur propre suite) : il
// teste le BRANCHEMENT — ce qui manquait. Cinq propriétés, et chacune
// correspond à une façon de livrer une couche inerte, ou pire, active sans
// droit :
//
//  (a) le dépôt est construit UNE fois, il est accessible à toute
//      l'application, la file est installée avec ses trois déclencheurs, et une
//      sonde qui rend 404 laisse la v2 DÉSARMÉE ;
//  (b) SANS v2 armée, la sauvegarde d'une commande n'émet AUCUNE requête vers
//      `/api/v2` : le chemin existant reste celui d'aujourd'hui, au caractère
//      près. C'est la règle non négociable du lot ;
//  (c) AVEC la v2 armée, la sauvegarde passe par le dépôt et produit le PATCH
//      granulaire, la commande ENVELOPPÉE ;
//  (d) une sonde qui LÈVE (500) laisse la v2 désarmée sans faire échouer le
//      lancement — le démarrage ne dépend d'aucune route d'API ;
//  (e) une panne transitoire pendant la sauvegarde REMPLIT LA FILE (le hook est
//      appelé) et la charge utile n'est pas perdue ;
//  (f) le « retour de connectivité » est un VRAI signal, pas une méthode
//      exposée dans le vide : la première requête qui aboutit après une panne
//      déclenche un vidage.
//
// CE QUI N'EST PAS TESTÉ ICI, ET POURQUOI : l'écran `command.create.dart` n'est
// pas montable en test (3 000 lignes, client Discord, base locale, i18n). Le
// point de branchement y appelle UNE fonction (`granularCommandSaveFor`) dont
// les deux réponses sont prouvées ici et dans `bot_data_repository_test.dart` ;
// ce qui reste non couvert est l'insertion de cet appel dans l'écran.

import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/bot_data_models.dart';
import 'package:bot_creator/core/network/bot_data_repository.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/storage/granular_data_layer.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _baseUrl = 'https://manager.test';
const String _botId = 'bot-granular';
const String _commandId = 'cmd-42';
const String _token = 'jeton-de-test';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json',
};

/// La sonde telle que la sert un serveur qui CONNAÎT la façade.
const String _capabilitiesOk =
    '{"granular_api":"1","config_revision_aware":true,'
    '"command_history":true,"command_history_limit":5}';

Map<String, dynamic> _commandPayload([String name = 'ping']) =>
    <String, dynamic>{
      'id': _commandId,
      'name': name,
      'data': <String, dynamic>{'response': 'pong'},
    };

/// Un manager simulé qui NOTE tout ce qu'on lui demande.
///
/// POURQUOI UN ENREGISTREUR ET PAS SEULEMENT DES RÉPONSES : la règle (b) est une
/// règle d'ABSENCE (« aucune requête vers `/api/v2` ») ; elle ne se prouve qu'en
/// regardant ce qui n'est pas parti.
class _FakeManager {
  /// 404 = le serveur d'aujourd'hui, qui ne connaît pas la façade. C'est le
  /// défaut, et c'est voulu : un test qui oublie de l'armer ne peut pas prouver
  /// par accident un comportement granulaire.
  int capabilitiesStatus = 404;

  /// Panne RÉSEAU sur l'écriture : aucune réponse HTTP, comme une coupure.
  bool patchWithoutResponse = false;

  final List<String> calls = <String>[];
  String? lastPatchBody;

  late final http.Client client = MockClient((request) async {
    final path = request.url.path;
    calls.add('${request.method} $path');
    if (path.endsWith('/api/v2/capabilities')) {
      if (capabilitiesStatus != 200) {
        return http.Response(
          '{"error":"route absente"}',
          capabilitiesStatus,
          headers: _jsonHeaders,
        );
      }
      return http.Response(_capabilitiesOk, 200, headers: _jsonHeaders);
    }
    if (request.method == 'PATCH' && path.contains('/api/v2/')) {
      lastPatchBody = request.body;
      if (patchWithoutResponse) {
        throw const SocketException('réseau coupé');
      }
      return http.Response(
        '{"revision":"rev-2","command":{"id":"$_commandId"},'
        '"history_id":"hist-1","runner_synced":false}',
        200,
        headers: _jsonHeaders,
      );
    }
    return http.Response('{}', 200, headers: _jsonHeaders);
  });

  List<String> get v2Calls =>
      calls.where((call) => call.contains('/api/v2')).toList();
}

/// Branche la construction du dépôt sur le manager simulé.
///
/// Le délai de reprise est ANNULÉ : sans ça, un test de panne attendrait sept
/// secondes de vraies horloges pour observer un refus définitif.
void _useFakeManager(_FakeManager manager) {
  debugClientFactory = (baseUrl, accessToken) => MainApiClient(
    baseUrl: baseUrl,
    accessToken: accessToken,
    httpClient: manager.client,
    retryDelay: Duration.zero,
  );
}

/// Pose une session valide et la configuration : c'est ce qui rend un manager
/// joignable. Sans session, la couche n'a rien à interroger (test dédié).
Future<void> _seedSession() async {
  await MainApiSettingsStore.saveConfig(const MainApiConfig(baseUrl: _baseUrl));
  await MainApiSettingsStore.saveSession(
    MainApiSession(
      accessToken: _token,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 7)),
      userId: '42',
    ),
  );
}

/// Attend qu'une condition devienne vraie, horloge RÉELLE (le vidage passe par
/// des entrées/sorties SQLite asynchrones).
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
    documentsDir = await Directory.systemTemp.createTemp('granular_layer');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    MainApiSettingsStore.invalidateSessionCache();
    // Le coffre sécurisé peut survivre aux préférences simulées : sans ce
    // nettoyage, un test « sans session » hériterait de celle du précédent et
    // passerait pour la mauvaise raison.
    await MainApiSettingsStore.clearSession();
    // Un disjoncteur ouvert par un test précédent court-circuiterait le suivant
    // AVANT sa requête : le symptôme serait un échec pour une raison étrangère
    // au comportement visé.
    MainApiClient.resetCircuitBreakers();
    resetGranularDataLayerForTest();
    onBotDocumentPushed = null;
  });

  tearDown(() async {
    resetGranularDataLayerForTest();
    onBotDocumentPushed = null;
    MainApiSettingsStore.invalidateSessionCache();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  // ─── (a) construction et sonde ────────────────────────────────────────────

  group('(a) construction et sonde', () {
    test('le dépôt est construit, accessible, et une sonde 404 désarme la v2',
        () async {
      final manager = _FakeManager();
      await _seedSession();
      _useFakeManager(manager);

      final repository = await ensureGranularDataLayer();

      expect(repository, isNotNull);
      expect(granularDataRepository, same(repository));
      expect(granularDataRepository!.client.baseUrl, _baseUrl);
      expect(
        repository!.hasProbed,
        isTrue,
        reason: 'un 404 est une RÉPONSE : la question a été posée',
      );
      expect(repository.capabilities, isNull);
      expect(isGranularSaveEnabled, isFalse);
      expect(
        manager.v2Calls,
        <String>['GET /api/v2/capabilities'],
        reason: 'UNE sonde, et rien d\'autre',
      );
    });

    test('la file hors-ligne est installée avec ses trois déclencheurs',
        () async {
      final manager = _FakeManager();
      await _seedSession();
      _useFakeManager(manager);

      await ensureGranularDataLayer();

      final coordinator = commandOutboxCoordinator;
      expect(coordinator, isNotNull, reason: 'sans lui la file n\'existe pas');
      expect(
        coordinator!.isLifecycleAttached,
        isTrue,
        reason: '(ii) retour au premier plan',
      );
      expect(
        onBotDocumentPushed,
        isNotNull,
        reason: '(iii) après une poussée réussie',
      );
      expect(
        granularDataRepository!.offlineQueueHook,
        isNotNull,
        reason: 'le hook de mise en file est posé sur le dépôt',
      );
      expect(commandOutboxStore, isNotNull);
    });

    test('une seconde initialisation (reprise) ne re-sonde pas le serveur',
        () async {
      final manager = _FakeManager();
      await _seedSession();
      _useFakeManager(manager);

      await ensureGranularDataLayer();
      await ensureGranularDataLayer();
      await ensureGranularDataLayer();

      expect(
        manager.v2Calls,
        hasLength(1),
        reason: 'la sonde est mise en cache : une reprise ne recoûte rien',
      );
    });

    test('sans session, rien n\'est construit — donc aucun appel réseau',
        () async {
      final manager = _FakeManager();
      _useFakeManager(manager);

      expect(await ensureGranularDataLayer(), isNull);
      expect(granularDataRepository, isNull);
      expect(commandOutboxCoordinator, isNull);
      expect(isGranularSaveEnabled, isFalse);
      expect(manager.calls, isEmpty);
    });
  });

  // ─── (b) le chemin d'aujourd'hui, inchangé ────────────────────────────────

  group('(b) sans v2 armée, le chemin existant est intact', () {
    test('la sauvegarde d\'une commande n\'émet AUCUNE requête /api/v2',
        () async {
      final manager = _FakeManager();
      await _seedSession();
      _useFakeManager(manager);
      await ensureGranularDataLayer();
      manager.calls.clear();

      final planned = granularCommandSaveFor(
        granularDataRepository,
        botId: _botId,
        commandId: _commandId,
        command: _commandPayload(),
      );

      expect(
        planned,
        isNull,
        reason: 'la garde rend null : l\'éditeur garde son appel d\'aujourd\'hui',
      );
      expect(
        manager.calls,
        isEmpty,
        reason: 'AUCUNE requête, ni vers /api/v2 ni ailleurs',
      );
    });

    test('un dépôt JAMAIS sondé ne déclenche rien non plus', () async {
      final manager = _FakeManager();
      final repository = BotDataRepository(
        client: MainApiClient(
          baseUrl: _baseUrl,
          accessToken: _token,
          httpClient: manager.client,
          retryDelay: Duration.zero,
        ),
      );

      expect(
        granularCommandSaveFor(
          repository,
          botId: _botId,
          commandId: _commandId,
          command: _commandPayload(),
        ),
        isNull,
        reason: 'sans sonde réussie, la v2 n\'a jamais le droit d\'écrire',
      );
      expect(manager.calls, isEmpty);
    });
  });

  // ─── (c) le chemin granulaire, quand il a le droit ────────────────────────

  group('(c) avec la v2 armée, la sauvegarde est granulaire', () {
    test('elle passe par le dépôt et produit le PATCH', () async {
      final manager = _FakeManager()..capabilitiesStatus = 200;
      await _seedSession();
      _useFakeManager(manager);
      await ensureGranularDataLayer();
      expect(isGranularSaveEnabled, isTrue);
      manager.calls.clear();

      final planned = granularCommandSaveFor(
        granularDataRepository,
        botId: _botId,
        commandId: _commandId,
        command: _commandPayload('pong'),
      );
      expect(planned, isNotNull, reason: 'la sonde a armé la v2');

      final outcome = await planned!;
      expect(outcome, isA<SavedGranular>());
      expect((outcome as SavedGranular).revision, 'rev-2');

      expect(manager.calls, <String>[
        'PATCH /api/v2/bots/$_botId/commands/$_commandId',
      ]);
      final body = jsonDecode(manager.lastPatchBody!) as Map<String, dynamic>;
      expect(
        body.keys,
        <String>['command'],
        reason: 'la commande est ENVELOPPÉE : le serveur refuse les champs '
            'inconnus, donc une faute de frappe doit être une erreur nommée',
      );
      expect(body['command'], _commandPayload('pong'));
    });
  });

  // ─── (d) une sonde qui échoue ne casse rien ───────────────────────────────

  group('(d) sonde en panne', () {
    test('un 500 laisse la v2 désarmée et ne fait pas échouer le lancement',
        () async {
      final manager = _FakeManager()..capabilitiesStatus = 500;
      await _seedSession();
      _useFakeManager(manager);

      // L'assertion est ici : cet appel REND, il ne lève pas.
      final repository = await ensureGranularDataLayer();

      expect(repository, isNotNull, reason: 'le dépôt existe, il sait se taire');
      expect(
        repository!.hasProbed,
        isFalse,
        reason: 'une sonde qui échoue n\'est PAS « sondé » — on reposera la '
            'question à la prochaine reprise',
      );
      expect(repository.capabilities, isNull);
      expect(isGranularSaveEnabled, isFalse);
      expect(
        commandOutboxCoordinator,
        isNotNull,
        reason: 'la file est installée même sans v2 : elle ne dépend pas d\'elle',
      );
      expect(
        granularCommandSaveFor(
          repository,
          botId: _botId,
          commandId: _commandId,
          command: _commandPayload(),
        ),
        isNull,
      );
      expect(
        manager.v2Calls.where((call) => call.endsWith('/capabilities')).length,
        greaterThan(1),
        reason: 'le client a bien réessayé avant de renoncer',
      );
    });
  });

  // ─── (e) panne transitoire : la file garde l'écriture ─────────────────────

  group('(e) panne transitoire pendant la sauvegarde', () {
    test('la file est remplie (hook appelé) et la charge utile est conservée',
        () async {
      final manager = _FakeManager()
        ..capabilitiesStatus = 200
        ..patchWithoutResponse = true;
      await _seedSession();
      _useFakeManager(manager);
      await ensureGranularDataLayer();

      final planned = granularCommandSaveFor(
        granularDataRepository,
        botId: _botId,
        commandId: _commandId,
        command: _commandPayload('derniere-edition'),
      );
      expect(planned, isNotNull);

      final outcome = await planned!;
      expect(
        outcome,
        isA<QueuedOffline>(),
        reason: 'une panne réseau part en file, elle ne remonte pas en panne',
      );

      final store = commandOutboxStore!;
      expect(await store.count(), 1, reason: 'le hook de file a été appelé');
      final entry = await store.find(_botId, _commandId);
      expect(entry, isNotNull);
      expect(
        entry!.command,
        _commandPayload('derniere-edition'),
        reason: 'la charge utile est CONSERVÉE : l\'écriture locale n\'est pas '
            'perdue, et le rejeu partira avec elle',
      );
    });
  });

  // ─── (f) le retour de connectivité est un vrai signal ─────────────────────

  group('(f) retour de connectivité', () {
    test('la première requête qui aboutit après une panne vide la file',
        () async {
      final manager = _FakeManager()..capabilitiesStatus = 500;
      await _seedSession();
      _useFakeManager(manager);
      await ensureGranularDataLayer();

      final coordinator = commandOutboxCoordinator!;
      expect(
        coordinator.lastReport,
        isNull,
        reason: 'aucun vidage n\'a encore eu lieu',
      );

      // Le réseau revient : la prochaine requête réussit.
      manager.capabilitiesStatus = 200;
      await granularDataRepository!.probe(force: true);

      await _waitFor(
        () => coordinator.lastReport != null,
        reason: 'le vidage n\'a PAS été déclenché par le retour du réseau',
      );
      expect(coordinator.lastReport!.remaining, 0);
    });
  });
}
