// POSTE DE TRAVAIL (desktop) CONNECTÉ : l'accès aux données du compte passe par le manager.
//
// Le propriétaire a signalé (et une sonde réelle l'a confirmé) qu'un poste de travail
// connecté n'affichait AUCUNE donnée du compte — ni le compte, ni les bots du compte,
// ni les conteneurs clé en main — alors que le serveur les renvoyait (`/auth/me`,
// `/gateway/bots`, `/containers`, `/gateway/snapshot` en 200 avec sa session).
//
// Cause : la garde de plateforme `_isDesktop` servait de verrou pour la DONNÉE.
// `_resolveGlobalMainApiClient()` / `_resolveMainApiClientForBot()` rendaient `null`
// sur un poste de travail, donc `_refreshTurnkeyContainers()` sortait sans rien charger,
// le compte et le snapshot n'étaient jamais récupérés, et `syncAllBotsFromManager()`
// tombait dans le repli « sync directe Discord des bots locaux ».
//
// Pourquoi ce test n'inspecte PAS les états internes de l'accueil : ce niveau-là prouve
// seulement que du code a été exécuté, pas que la question est partie. Ici on fait le
// trajet COMPLET — résolution du client comme le fait l'accueil, puis vraies requêtes
// HTTP contre un manager FACTICE sur la boucle locale qui journalise chaque chemin.
//
// L'affichage de la carte clé en main à partir de ces conteneurs reste couvert par
// `home_turnkey_list_test.dart` et `turnkey_bot_invite_button_test.dart`.
//
// Historique : un premier jet montait le VRAI `HomePage`. Ses minuteurs périodiques,
// son canal temps réel et le chargement des polices faisaient pendre le test (arrêté au
// bout de 9 minutes par le harnais, « did not complete »). Un test qui ne se termine pas
// n'est pas un test vert : on prouve la garantie au niveau où elle se décide.
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _botIdA = '111111111111111111';
const String _botIdB = '222222222222222222';
const String _botNameA = 'BeatBot';
const String _botNameB = 'ModBot';
const String _turnkeyImage = 'ghcr.io/albertgzmz/beatdock:latest';
const String _turnkeyContainerId = '95d85ac8-bd42-41c6-9392-3a1f0c9b7d21';

/// `HttpOverrides` neutres : rendent le vrai `HttpClient`. Le binding de `flutter_test`
/// installe sinon un client bouchonné qui répond 400 — on ne verrait jamais le manager
/// factice.
class _RealHttpOverrides extends HttpOverrides {}

/// Manager factice sur la boucle locale.
///
/// Son intérêt n'est pas la charge utile mais le JOURNAL des chemins demandés : c'est
/// la seule preuve non vacuousable que le poste de travail pose réellement la question
/// au manager (un test qui n'observerait qu'un état interne passerait même si la
/// requête n'était jamais partie).
class _FakeManager {
  _FakeManager._(this._server);

  static Future<_FakeManager> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final manager = _FakeManager._(server);
    server.listen(manager._handle, onError: (_) {});
    return manager;
  }

  final HttpServer _server;

  /// Une entrée par requête HTTP reçue, dans l'ordre (chemin seul).
  final List<String> paths = <String>[];

  /// Une entrée par requête dont l'en-tête `Authorization` portait la session.
  final List<String> authorizedPaths = <String>[];

  String get baseUrl => 'http://127.0.0.1:${_server.port}';

  bool asked(String path) => paths.contains(path);

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    paths.add(path);
    if ((request.headers.value(HttpHeaders.authorizationHeader) ?? '')
        .trim()
        .isNotEmpty) {
      authorizedPaths.add(path);
    }

    request.response
      ..statusCode = 200
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(_payloadFor(path)));
    await request.response.close();
  }

  Map<String, dynamic> _payloadFor(String path) {
    switch (path) {
      case '/gateway/bots':
        return <String, dynamic>{
          'bots': <dynamic>[
            _botPayload(_botIdA, _botNameA),
            _botPayload(_botIdB, _botNameB),
          ],
        };
      case '/containers':
        return <String, dynamic>{
          'containers': <dynamic>[_containerPayload()],
        };
      case '/auth/me':
        return <String, dynamic>{'account': _account(), 'plan': 'PREMIUM'};
      case '/gateway/plans':
        return <String, dynamic>{'plans': const <dynamic>[]};
      default:
        return const <String, dynamic>{};
    }
  }

  static Map<String, dynamic> _account() => <String, dynamic>{
    'plan': 'PREMIUM',
    'tier_code': 'PRO',
    'display_name': 'Pro',
    'max_bots': 5,
    'max_turnkey_bots': 2,
    'allow_own_bots': false,
    'allow_turnkey': true,
    'provider': 'apple_in_app',
    'expires_at': '2030-01-01T00:00:00Z',
  };

  /// Bot du compte tel que le renvoie `GET /gateway/bots`. Pas de `bot_token` : sans
  /// jeton, l'application ne part pas interroger Discord pendant le test.
  static Map<String, dynamic> _botPayload(String botId, String botName) {
    return <String, dynamic>{
      'bot_id': botId,
      'bot_name': botName,
      'desired_state': 'RUNNING',
      'last_runtime_state': 'running',
      'funding_mode': 'free',
      'free_minutes_balance': 42,
      'session_expires_at': '2030-01-01T00:00:00Z',
      'config': <String, dynamic>{'prefix': '!', 'intents': <String, bool>{}},
    };
  }

  static Map<String, dynamic> _containerPayload() {
    final now = DateTime.now().toUtc();
    return <String, dynamic>{
      'id': _turnkeyContainerId,
      'owner_id': 'owner-1',
      'swarm_service_id': 'svc-1',
      'image': _turnkeyImage,
      'cpu_millis': 250,
      'memory_mb': 256,
      'storage_gb': 1,
      'state': 'RUNNING',
      'health_status': 'healthy',
      'expires_at': now.add(const Duration(hours: 3)).toIso8601String(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    };
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  HttpOverrides? previousHttpOverrides;

  setUpAll(() async {
    // Les réglages (config manager, session, runners) vivent dans `SharedPreferences`,
    // mais `path_provider` peut être sollicité en chemin : on lui donne un dossier
    // temporaire plutôt que de laisser remonter une exception de canal.
    documentsDir = await Directory.systemTemp.createTemp(
      'desktop_manager_access_test_',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {
        // Fichiers encore verrouillés : sans importance pour le test.
      }
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // UN SEUL levier pour dire « nous sommes sur un poste de travail » : Flutter le
    // rapporte en `android` par défaut sous `flutter_test`, donc sans cette ligne le
    // code de `remote_runtime.dart` suivrait le chemin MOBILE et le test ne prouverait
    // rien du comportement desktop. Le seam `run_platform.dart` honore le même levier,
    // donc les deux notions de plateforme restent d'accord.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    // La config et la session sont mémorisées en statique : sans remise à zéro, la
    // session d'un test fuiterait dans le suivant et « hors connexion » ne testerait
    // plus rien.
    await MainApiSettingsStore.clearConfig();
    await MainApiSettingsStore.clearSession();
    MainApiClient.resetCircuitBreakers();
    previousHttpOverrides = HttpOverrides.current;
    HttpOverrides.global = _RealHttpOverrides();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    HttpOverrides.global = previousHttpOverrides;
  });

  test(
    'poste de travail connecté : le client manager est résolu et les données du compte sont demandées',
    () async {
      final manager = await _FakeManager.start();
      try {
        await MainApiSettingsStore.saveConfig(
          MainApiConfig(baseUrl: manager.baseUrl),
        );
        await MainApiSettingsStore.saveSession(
          MainApiSession(
            accessToken: 'session-desktop-test',
            expiresAt: DateTime.now().toUtc().add(const Duration(hours: 2)),
          ),
        );

        // Étape 1 : la résolution GLOBALE, exactement celle qu'utilise l'accueil pour le
        // compte, les bots du compte, les conteneurs clé en main et le snapshot.
        final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

        expect(
          runtime.source,
          RemoteRuntimeSource.manager,
          reason:
              'un poste de travail connecté doit résoudre le manager (sans quoi aucune '
              'donnée du compte ne peut être demandée)',
        );
        expect(runtime.client, isNotNull, reason: 'le client doit être utilisable');
        expect(runtime.blocksLocalFallback, isFalse);

        // Étape 2 : la donnée part RÉELLEMENT, avec le jeton de session. Le client
        // résolu pour le manager est le client concret `MainApiClient` — celui que
        // l'accueil utilise pour les bots du compte et les conteneurs clé en main.
        final client = runtime.client! as MainApiClient;
        final bots = await client.listBots();
        final containers = await client.listContainers();

        expect(
          manager.asked('/gateway/bots'),
          isTrue,
          reason: 'les bots du compte doivent être demandés (${manager.paths})',
        );
        expect(
          manager.asked('/containers'),
          isTrue,
          reason:
              'les conteneurs clé en main doivent être demandés (${manager.paths})',
        );
        expect(
          manager.authorizedPaths,
          containsAll(<String>['/gateway/bots', '/containers']),
          reason: 'les requêtes doivent porter la session du compte',
        );

        // Étape 3 : la réponse est COMPRISE par l'application, pas seulement reçue.
        expect(bots.length, 2);
        expect(containers.length, 1);
        expect(containers.single.id, _turnkeyContainerId);
        expect(containers.single.image, _turnkeyImage);
      } finally {
        await manager.close();
      }
    },
  );

  test(
    'poste de travail hors connexion : aucun aller-retour vers le manager',
    () async {
      final manager = await _FakeManager.start();
      try {
        // Manager configuré mais AUCUNE session : c'est l'état « pas connecté », que le
        // poste de travail doit continuer de supporter (bots locaux, runner embarqué).
        await MainApiSettingsStore.saveConfig(
          MainApiConfig(baseUrl: manager.baseUrl),
        );

        final runtime = await resolveRemoteRuntime(supportsManagerRuntime: true);

        expect(
          runtime.source,
          isNot(RemoteRuntimeSource.manager),
          reason:
              'hors connexion, le poste de travail ne doit pas être enfermé dans le '
              'manager : il reste sur le runner local ou le moteur embarqué',
        );
        expect(
          manager.paths,
          isEmpty,
          reason: 'aucune requête ne doit partir hors connexion (${manager.paths})',
        );
      } finally {
        await manager.close();
      }
    },
  );
}
