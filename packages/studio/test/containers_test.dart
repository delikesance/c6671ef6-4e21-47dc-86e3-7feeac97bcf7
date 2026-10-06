import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/editor/studio_hosted_containers_host.dart';
import 'package:bot_creator_studio/src/platform/event_socket.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const _beatdock = 'ghcr.io/albertgmz/beatdock:latest';

Map<String, dynamic> _container(
  String id, {
  String state = 'RUNNING',
  String image = _beatdock,
  String? appId = '4242',
}) => {
  'id': id,
  'owner_id': '1',
  'image': image,
  'cpu_millis': 250,
  'memory_mb': 256,
  'memory_usage_bytes': 64 * 1024 * 1024,
  'storage_gb': 1,
  'state': state,
  'health_status': 'healthy',
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 5, minutes: 30))
      .toIso8601String(),
  'discord_application_id': ?appId,
};

/// Un Manager simulé : conteneurs, éligibilité, déploiement, identifiants de
/// registre, catalogue de modèles. Chaque requête est gardée pour être vérifiée.
class _Manager {
  _Manager({this.eligibility, List<Map<String, dynamic>>? containers})
    : containers = containers ?? [_container('c1')];

  Map<String, dynamic>? eligibility;
  final List<Map<String, dynamic>> containers;
  final credentials = <Map<String, dynamic>>[
    {
      'id': 'r1',
      'label': 'GHCR perso',
      'registry_host': 'ghcr.io',
      'username': 'bob',
    },
  ];
  bool runtimeCloudEnabled = true;
  final seen = <http.Request>[];

  static Map<String, dynamic> freeEligibility({
    int minutes = 60,
    int active = 1,
    int max = 3,
    bool canDeploy = true,
    String? blocked,
  }) => {
    'premium': false,
    'hosting_minutes_balance': minutes,
    'active_containers': active,
    'max_containers': max,
    'ad_reward_minutes': 60,
    'can_deploy': canDeploy,
    'allow_turnkey': true,
    'deploy_blocked_reason': ?blocked,
  };

  http.Client get client => MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    final m = r.method;
    if (p == '/gateway/runtime') {
      return _json({
        'plan': 'FREE',
        if (!runtimeCloudEnabled) 'premium_cloud_enabled': false,
      });
    }
    if (p == '/gateway/turnkey/templates') {
      return _json({
        'templates': [
          {
            'slug': 'beatdock',
            'name': 'BeatDock',
            'description': 'Bot musique',
            'image': _beatdock,
            'category': 'music',
            'env_fields_schema': [
              {'key': 'TOKEN', 'secret': true, 'required': true},
              {
                'key': 'DEFAULT_VOLUME',
                'label': 'Volume',
                'default_value': '50',
              },
              {'key': 'NODE_HOST', 'fixed': true, 'default_value': 'node.test'},
            ],
          },
        ],
      });
    }
    if (p == '/gateway/turnkey/validate-token') return _json({'ok': true});
    if (p == '/containers/eligibility') {
      return _json(eligibility ?? freeEligibility());
    }
    if (p == '/containers/deploy' && m == 'POST') {
      return _json({'job_id': 'j1', 'container_id': 'c9'});
    }
    if (p == '/containers' && m == 'GET') {
      return _json({'containers': containers});
    }
    if (p == '/registry-credentials' && m == 'GET') {
      return _json({'credentials': credentials});
    }
    if (p == '/registry-credentials' && m == 'POST') {
      final body = jsonDecode(r.body) as Map;
      final created = {
        'id': 'r2',
        'label': body['label'],
        'registry_host': body['registry_host'],
        'username': body['username'],
      };
      credentials.add(created);
      return _json(created);
    }
    if (p.startsWith('/registry-credentials/') && m == 'DELETE') {
      credentials.removeWhere((c) => '/registry-credentials/${c['id']}' == p);
      return _json({'ok': true});
    }
    final status = RegExp(r'^/containers/([^/]+)/status$').firstMatch(p);
    if (status != null) {
      final id = status.group(1);
      final found = containers.where((c) => c['id'] == id);
      if (found.isEmpty) return _json({'error': 'not_found'}, 404);
      return _json({...found.first, 'image': found.first['image']});
    }
    if (p.endsWith('/logs')) {
      return _json({
        'logs':
            '2026-09-19T10:00:00Z [INFO] bot pret\n'
            '2026-09-19T10:00:05Z [ERROR] connexion refusee\n',
      });
    }
    if (p.endsWith('/stop') ||
        p.endsWith('/start') ||
        p.endsWith('/ttl') ||
        m == 'DELETE') {
      return _json({'ok': true});
    }
    if (p.endsWith('/discord-identity')) {
      return _json({
        'bot_id': '77',
        'username': 'Beat',
        'invite_url': 'https://discord.com/api/oauth2/authorize?client_id=77',
      });
    }
    return _json({'ok': true});
  });

  StudioApi get api =>
      StudioApi(baseUrl: 'https://api.test', client: client)
        ..accessToken = ({bool force = false}) async => 'tok';

  Iterable<String> get calls => seen.map((r) => '${r.method} ${r.url.path}');

  http.Request first(String method, String path) =>
      seen.firstWhere((r) => r.method == method && r.url.path == path);
}

class _FakeSocket extends EventSocket {
  _FakeSocket({
    required super.url,
    required super.token,
    required super.onMessage,
    required super.onClosed,
    super.onData,
  });

  bool closedByHost = false;

  @override
  Future<void> connect() async {}

  @override
  void close() => closedByHost = true;

  void push(Map<String, dynamic> frame) {
    onMessage();
    onData?.call(jsonEncode(frame));
  }
}

void main() {
  tearDown(() => setCachedTurnkeyTemplates(const []));

  group('hôte des applications hébergées : format des appels', () {
    test('liste, éligibilité, statut et logs : routes et décodage', () async {
      final manager = _Manager();
      final host = StudioHostedContainersHost(manager.api);

      expect(await host.hasSession(), isTrue);
      final list = await host.listContainers();
      expect(list.single.id, 'c1');
      expect(list.single.isRunning, isTrue);
      expect(list.single.memoryUsageBytes, 64 * 1024 * 1024);
      expect(list.single.discordApplicationId, '4242');

      final elig = await host.eligibility();
      expect(elig.premium, isFalse);
      expect(elig.hostingMinutesBalance, 60);
      expect(elig.maxContainers, 3);
      expect(elig.canDeploy, isTrue);

      final status = await host.containerStatus('c1');
      expect(status['state'], 'RUNNING');
      expect(await host.containerLogs('c1', tail: 50), contains('bot pret'));

      expect(
        manager.calls,
        containsAllInOrder([
          'GET /containers',
          'GET /gateway/runtime',
          'GET /containers/eligibility',
          'GET /containers/c1/status',
          'GET /containers/c1/logs',
        ]),
      );
      expect(manager.first('GET', '/containers/c1/logs').url.query, 'tail=50');
      for (final r in manager.seen) {
        expect(r.headers['authorization'], 'Bearer tok', reason: r.url.path);
      }
    });

    test('démarrer, éteindre, supprimer et prolonger le TTL', () async {
      final manager = _Manager();
      final host = StudioHostedContainersHost(manager.api);

      await host.startContainer('c 1');
      await host.stopContainer('c1');
      await host.deleteContainer('c1');
      await host.extendContainerTtl('c1', 90);

      final start = manager.first('POST', '/containers/c%201/start');
      expect(jsonDecode(start.body), isEmpty);
      expect(manager.calls, contains('POST /containers/c1/stop'));
      expect(manager.calls, contains('DELETE /containers/c1'));
      final ttl = manager.first('PATCH', '/containers/c1/ttl');
      expect(jsonDecode(ttl.body), {'ttl_minutes': 90});
    });

    test('déployer = POST /containers/deploy avec l\'env du schéma', () async {
      final manager = _Manager();
      final host = StudioHostedContainersHost(manager.api);

      final result = await host.deployContainer(
        image: _beatdock,
        cpuMillis: 250,
        memoryMb: 256,
        storageGb: 1,
        env: const {'TOKEN': 'abc'},
      );
      expect(result['container_id'], 'c9');
      final post = manager.first('POST', '/containers/deploy');
      expect(jsonDecode(post.body), {
        'image': _beatdock,
        'cpu_millis': 250,
        'memory_mb': 256,
        'storage_gb': 1,
        'env': {'TOKEN': 'abc'},
      });
      expect(post.headers['authorization'], 'Bearer tok');
    });

    test('validation du token et catalogue : routes publiques', () async {
      final manager = _Manager();
      final host = StudioHostedContainersHost(manager.api);

      await host.validateDiscordToken('  secret.token  ');
      final templates = await host.fetchTurnkeyTemplates('fr');

      final validate = manager.first('POST', '/gateway/turnkey/validate-token');
      expect(jsonDecode(validate.body), {'bot_token': 'secret.token'});
      expect(validate.headers.containsKey('authorization'), isFalse);
      final catalogue = manager.first('GET', '/gateway/turnkey/templates');
      expect(catalogue.url.query, 'locale=fr');
      expect(catalogue.headers.containsKey('authorization'), isFalse);
      expect(
        HostedAppTemplate.fromJson(templates!.single).envFields,
        hasLength(3),
      );
    });

    test('identifiants de registre : CRUD, mot de passe jamais relu', () async {
      final manager = _Manager();
      final host = StudioHostedContainersHost(manager.api);

      final list = await host.listRegistryCredentials();
      expect(list.single.label, 'GHCR perso');
      expect(list.single.registryHost, 'ghcr.io');

      final created = await host.createRegistryCredential(
        label: 'Hub',
        registryHost: 'docker.io',
        username: 'al',
        password: 'pw',
      );
      expect(created.id, 'r2');
      final post = manager.first('POST', '/registry-credentials');
      expect(jsonDecode(post.body), {
        'label': 'Hub',
        'registry_host': 'docker.io',
        'username': 'al',
        'password': 'pw',
      });

      await host.updateRegistryCredential(
        'r1',
        label: 'GHCR',
        registryHost: 'ghcr.io',
        username: 'bob',
      );
      final patch = manager.first('PATCH', '/registry-credentials/r1');
      // Mot de passe laissé vide : la clé n'est pas envoyée (inchangé).
      expect(jsonDecode(patch.body), {
        'label': 'GHCR',
        'registry_host': 'ghcr.io',
        'username': 'bob',
      });

      await host.deleteRegistryCredential('r1');
      expect(manager.calls, contains('DELETE /registry-credentials/r1'));
    });

    test(
      'identité Discord : l\'échec du serveur garde statut et code',
      () async {
        final api = StudioApi(
          baseUrl: 'https://api.test',
          client: MockClient(
            (_) async => _json({
              'error': 'discord_identity_unavailable',
              'code': 'discord_identity_unavailable',
            }, 409),
          ),
        )..accessToken = ({bool force = false}) async => 'tok';
        final host = StudioHostedContainersHost(api);
        await expectLater(
          host.discordIdentity('c1'),
          throwsA(
            isA<HostedApiException>()
                .having((e) => e.statusCode, 'statusCode', 409)
                .having((e) => e.code, 'code', 'discord_identity_unavailable'),
          ),
        );

        final service = TurnkeyBotInviteService(
          host: host,
          openUrl: (_) async => true,
        );
        final outcome = await service.invite(
          ContainerInfo.fromJson(_container('c1', appId: null)),
        );
        expect(outcome, BotInviteOutcome.unavailable);
      },
    );

    test(
      'capacités : ni publicité, ni achat, ni bot local, ni assistant',
      () async {
        final host = StudioHostedContainersHost(_Manager().api);
        expect(host.canWatchAds, isFalse);
        expect(host.upsellMode, HostedUpsellMode.none);
        expect(host.canOpenCopilot, isFalse);
        expect(await host.localBots(), isEmpty);
        await expectLater(
          host.watchAdAndClaim(placement: 'hosted_app_topup'),
          throwsUnsupportedError,
        );
        expect(host.showsRegistryCredentials, isTrue);
      },
    );

    test('hébergement cloud coupé : lu une fois dans le runtime', () async {
      final manager = _Manager()..runtimeCloudEnabled = false;
      final host = StudioHostedContainersHost(manager.api);
      expect(host.premiumCloudDisabled, isFalse);
      await host.eligibility();
      await host.eligibility();
      expect(host.premiumCloudDisabled, isTrue);
      expect(
        manager.calls.where((c) => c == 'GET /gateway/runtime'),
        hasLength(1),
      );
    });
  });

  group('hôte des applications hébergées : temps réel', () {
    test('container.updated est décodé, le reste du canal ignoré', () async {
      final sockets = <_FakeSocket>[];
      final host = StudioHostedContainersHost(
        _Manager().api,
        socketFactory:
            ({
              required url,
              required token,
              required onMessage,
              required onData,
              required onClosed,
            }) {
              final s = _FakeSocket(
                url: url,
                token: token,
                onMessage: onMessage,
                onData: onData,
                onClosed: onClosed,
              );
              sockets.add(s);
              return s;
            },
      );
      final updates = <ContainerLiveUpdate>[];
      final sub = (await host.containerUpdates())!.listen(updates.add);
      await Future<void>.delayed(Duration.zero);

      expect(sockets.single.url, 'wss://api.test/gateway/bots/events');
      sockets.single
        ..push({'type': 'ping'})
        ..push({
          'type': 'bot.updated',
          'bot': {'bot_id': '1'},
        })
        ..push({
          'type': 'container.updated',
          'container': {
            'container_id': 'c1',
            'state': 'STOPPED',
            'health_status': 'unknown',
            'expires_at': '2026-10-06T10:00:00Z',
          },
        });
      await Future<void>.delayed(Duration.zero);

      expect(updates, hasLength(1));
      expect(updates.single.containerId, 'c1');
      expect(updates.single.state, 'STOPPED');
      expect(updates.single.expiresAt, DateTime.utc(2026, 10, 6, 10));

      await sub.cancel();
      expect(sockets.single.closedByHost, isTrue);
    });
  });

  group('écrans partagés montés sur le Manager', () {
    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            ...StudioLocalizations.localizationsDelegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          theme: AppTheme.darkTheme(),
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    // Les sondages réarment des minuteries : on démonte pour les libérer.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    }

    Future<AppLocalizations> fr() =>
        AppLocalizations.delegate.load(const Locale('fr'));

    testWidgets('la liste affiche le bot, son état et son temps restant', (
      tester,
    ) async {
      final manager = _Manager();
      final tr = await fr();
      await pump(
        tester,
        ContainerListPage(host: StudioHostedContainersHost(manager.api)),
      );

      expect(find.text(tr.container_list_title), findsOneWidget);
      expect(
        find.text(tr.container_deploy_template_easy_music),
        findsOneWidget,
      );
      expect(find.text(tr.container_state_running), findsOneWidget);
      expect(find.textContaining('64 / 256 MB'), findsOneWidget);
      expect(find.textContaining('5h'), findsOneWidget);
      // Compte gratuit sous son plafond : aucune offre ni action d'achat.
      expect(find.text(tr.container_hosted_premium_view_btn), findsNothing);
      expect(find.byTooltip(tr.registry_credentials_title), findsOneWidget);
      await close(tester);
    });

    testWidgets('aucun conteneur : état vide avec le bouton de déploiement', (
      tester,
    ) async {
      final manager = _Manager(containers: []);
      final tr = await fr();
      await pump(
        tester,
        ContainerListPage(host: StudioHostedContainersHost(manager.api)),
      );
      expect(find.text(tr.container_list_empty), findsOneWidget);
      expect(find.text(tr.container_list_deploy_btn), findsOneWidget);
      await close(tester);
    });

    testWidgets(
      'limite gratuite atteinte : message au lieu d\'un achat impossible',
      (tester) async {
        final manager = _Manager(
          eligibility: _Manager.freeEligibility(
            active: 1,
            max: 1,
            canDeploy: false,
            blocked: 'container_limit',
          ),
        );
        final tr = await fr();
        await pump(
          tester,
          ContainerListPage(host: StudioHostedContainersHost(manager.api)),
        );

        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pump();
        expect(find.text(tr.container_list_free_limit_reached), findsOneWidget);
        // Pas de déploiement ouvert, pas de FAB d'achat natif.
        expect(manager.calls, isNot(contains('POST /containers/deploy')));
        expect(find.byType(FloatingActionButton), findsNothing);
        await close(tester);
      },
    );

    testWidgets('le détail éteint le conteneur après confirmation', (
      tester,
    ) async {
      final manager = _Manager();
      final tr = await fr();
      await pump(
        tester,
        ContainerListPage(host: StudioHostedContainersHost(manager.api)),
      );

      await tester.tap(find.text(tr.container_deploy_template_easy_music));
      await tester.pumpAndSettle();
      // Détail : état, console de logs lue par l'API, invitation du bot.
      expect(find.text(tr.container_detail_console), findsOneWidget);
      expect(find.text('connexion refusee'), findsOneWidget);
      expect(find.text(tr.container_invite_btn), findsOneWidget);
      // Compte gratuit : pas de bouton « regarder une publicité ».
      expect(find.textContaining('Pub +'), findsNothing);
      expect(find.text(tr.container_hosted_free_title), findsOneWidget);

      await tester.tap(find.text(tr.container_detail_stop_title));
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.container_detail_stop_btn));
      await tester.pumpAndSettle();

      expect(manager.calls, contains('POST /containers/c1/stop'));
      await close(tester);
    });

    testWidgets(
      'inviter le bot ouvre le lien du serveur sans requête superflue',
      (tester) async {
        final manager = _Manager();
        final tr = await fr();
        final opened = <Uri>[];
        ExternalLinkOpener.current = (uri) async {
          opened.add(uri);
          return true;
        };
        addTearDown(() => ExternalLinkOpener.current = (_) async => false);
        await pump(
          tester,
          ContainerDetailPage(
            containerId: 'c1',
            host: StudioHostedContainersHost(manager.api),
          ),
        );
        await tester.tap(find.text(tr.container_invite_btn));
        await tester.pumpAndSettle();

        // L'application Discord est déjà connue du conteneur : lien direct.
        expect(opened.single.queryParameters['client_id'], '4242');
        expect(
          manager.calls.where((c) => c.endsWith('/discord-identity')),
          isEmpty,
        );
        await close(tester);
      },
    );

    testWidgets('le déploiement valide le token puis POST /containers/deploy', (
      tester,
    ) async {
      final manager = _Manager();
      final tr = await fr();
      await pump(
        tester,
        ContainerDeployPage(host: StudioHostedContainersHost(manager.api)),
      );

      // Le catalogue est lu à l'ouverture, dans la langue de l'écran.
      expect(
        manager.first('GET', '/gateway/turnkey/templates').url.query,
        'locale=fr',
      );
      expect(find.text(tr.container_deploy_title), findsOneWidget);
      // Compte gratuit sans appareil mobile : pas de bouton publicitaire.
      expect(find.textContaining('Pub +'), findsNothing);
      // Aucun bot local dans le Studio : pas de sélecteur, le token se colle.
      expect(find.text(tr.container_deploy_pick_bot), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, tr.app_bot_token),
        'MTIz.token.value',
      );
      final launch = find.text(tr.container_deploy_launch_btn);
      await tester.ensureVisible(launch);
      await tester.tap(launch);
      await tester.pumpAndSettle();

      final order = manager.calls.toList();
      expect(
        order.indexOf('POST /gateway/turnkey/validate-token'),
        lessThan(order.indexOf('POST /containers/deploy')),
      );
      final deploy = jsonDecode(
        manager.first('POST', '/containers/deploy').body,
      );
      expect(deploy['image'], _beatdock);
      expect(deploy['env'], {
        'TOKEN': 'MTIz.token.value',
        'DEFAULT_VOLUME': '50',
        'NODE_HOST': 'node.test',
      });
      // Succès : on arrive sur le détail du conteneur créé.
      expect(find.byType(ContainerDetailPage), findsOneWidget);
      expect(manager.calls, contains('GET /containers/c9/status'));
      await close(tester);
    });

    testWidgets('sans minutes d\'hébergement : bloqué, sans promesse de pub', (
      tester,
    ) async {
      final manager = _Manager(
        eligibility: _Manager.freeEligibility(
          minutes: 0,
          canDeploy: false,
          blocked: 'no_minutes',
        ),
      );
      final tr = await fr();
      await pump(
        tester,
        ContainerDeployPage(host: StudioHostedContainersHost(manager.api)),
      );
      // Même carte que l'app sur poste de travail : le solde serveur, sans pub.
      expect(find.text(tr.container_hosted_minutes_available(0)), findsWidgets);
      expect(find.textContaining('Pub +'), findsNothing);
      final launch = find.widgetWithText(
        FilledButton,
        tr.container_deploy_launch_btn,
      );
      await tester.ensureVisible(launch);
      expect(tester.widget<FilledButton>(launch).onPressed, isNull);
      await close(tester);
    });

    testWidgets('hébergement cloud coupé : l\'explication du serveur', (
      tester,
    ) async {
      final manager = _Manager(
        eligibility: _Manager.freeEligibility(
          minutes: 0,
          canDeploy: false,
          blocked: 'no_minutes',
        ),
      )..runtimeCloudEnabled = false;
      final tr = await fr();
      await pump(
        tester,
        ContainerDeployPage(host: StudioHostedContainersHost(manager.api)),
      );
      expect(
        find.text(tr.container_deploy_blocked_cloud_disabled),
        findsOneWidget,
      );
      await close(tester);
    });

    testWidgets('identifiants de registre : lister, ajouter, supprimer', (
      tester,
    ) async {
      final manager = _Manager();
      final tr = await fr();
      await pump(
        tester,
        RegistryCredentialsPage(host: StudioHostedContainersHost(manager.api)),
      );
      expect(find.text('GHCR perso'), findsOneWidget);
      expect(find.text('ghcr.io · bob'), findsOneWidget);

      await tester.tap(find.text(tr.registry_credentials_add));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Docker Hub');
      await tester.enterText(fields.at(1), 'docker.io');
      await tester.enterText(fields.at(2), 'alice');
      await tester.enterText(fields.at(3), 's3cret');
      await tester.tap(find.widgetWithText(FilledButton, tr.save));
      await tester.pumpAndSettle();

      final post = manager.first('POST', '/registry-credentials');
      expect(jsonDecode(post.body), {
        'label': 'Docker Hub',
        'registry_host': 'docker.io',
        'username': 'alice',
        'password': 's3cret',
      });
      expect(find.text('Docker Hub'), findsOneWidget);
      // Le mot de passe n'est jamais affiché ni relu.
      expect(find.textContaining('s3cret'), findsNothing);

      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(tr.delete).last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, tr.delete));
      await tester.pumpAndSettle();
      expect(manager.calls, contains('DELETE /registry-credentials/r1'));
      expect(find.text('GHCR perso'), findsNothing);
      await close(tester);
    });

    testWidgets('liste : un échec serveur est dit, avec un bouton réessayer', (
      tester,
    ) async {
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient((_) async => _json({'error': 'boom'}, 500)),
      )..accessToken = ({bool force = false}) async => 'tok';
      final tr = await fr();
      await pump(
        tester,
        ContainerListPage(host: StudioHostedContainersHost(api)),
      );
      expect(find.text(tr.container_list_error), findsOneWidget);
      expect(find.text(tr.container_list_retry), findsOneWidget);
      await close(tester);
    });
  });
}
