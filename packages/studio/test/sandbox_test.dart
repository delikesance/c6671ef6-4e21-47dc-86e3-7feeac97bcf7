import 'dart:convert';

import 'package:bot_creator_studio/l10n/app_localizations.dart';
import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/commands/command_draft.dart';
import 'package:bot_creator_studio/src/editor/studio_sandbox_host.dart';
import 'package:bot_creator_studio/src/screens/command_editor_page.dart';
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

/// The catalogue the runner serves: `SandboxFunctionCase.toJson()` for each case.
const _catalog = <Map<String, dynamic>>[
  {
    'function': 'onlyadmin',
    'label': 'allowed',
    'script': r'$onlyAdmin[Access denied.]ok',
    'expected': 'ok',
    'scenario': {
      'context': {'isAdmin': true},
    },
    'options': {'value': 'x', 'count': 2},
    'expectedValues': <String, dynamic>{},
  },
  {
    'function': 'onlyadmin',
    'label': 'denied',
    'script': r'$onlyAdmin[Access denied.]ok',
    'expected': 'Access denied.',
    'scenario': <String, dynamic>{},
    'options': {'value': 'x', 'count': 2},
    'expectedValues': <String, dynamic>{},
  },
  {
    'function': 'isnumber',
    'label': '',
    'script': r'$isNumber[$message[value]]',
    'expected': 'true',
    'scenario': <String, dynamic>{},
    'options': {'value': 42, 'count': 2},
    'expectedValues': <String, dynamic>{},
  },
];

/// A Manager that relays the sandbox to a runner, as seen from the Studio.
class _Manager {
  _Manager({this.status = 200, this.errorBody});

  /// Status of every sandbox call (503 = the bot has no reachable runner).
  int status;
  Map<String, dynamic>? errorBody;

  /// What the engine answers for a command run.
  Map<String, dynamic> result = {
    'success': true,
    'responses': [
      {
        'payload': {'content': 'Hello World'},
      },
    ],
    'effects': <dynamic>[],
    'trace': <dynamic>[],
    'diagnostics': <dynamic>[],
  };
  final seen = <http.Request>[];

  http.Client get client => MockClient((r) async {
    seen.add(r);
    final p = r.url.path;
    if (p.contains('/sandbox/')) {
      if (status != 200) {
        return _json(errorBody ?? {'error': 'nope', 'code': 'x'}, status);
      }
      if (p.endsWith('/sandbox/functions')) {
        return _json({'count': _catalog.length, 'cases': _catalog});
      }
      return _json(result);
    }
    if (p.endsWith('/scoped-definitions')) {
      return _json({
        'definitions': [
          {
            'key': 'xp',
            'scope': 'guildMember',
            'valueType': 'number',
            'defaultValue': 0,
          },
        ],
      });
    }
    return _json({});
  });

  StudioApi get api =>
      StudioApi(baseUrl: 'https://api.test', client: client)
        ..accessToken = ({bool force = false}) async => 'tok';

  Iterable<http.Request> get sandboxCalls =>
      seen.where((r) => r.url.path.contains('/sandbox/'));
}

Future<void> run(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Run test'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text('Run test'));
  await tester.pumpAndSettle();
}

void main() {
  group('hôte du bac à sable : format des appels', () {
    test(
      'exécuter = POST …/sandbox/command avec la demande du moteur',
      () async {
        final manager = _Manager();
        final host = StudioSandboxHost(manager.api, botId: 'b 1');
        expect(host.isRemote, isTrue);

        final request = {
          'script': r'Hello $message[name]',
          'bdfdBackend': 'native-v1',
          'options': {'name': 'World'},
          'variables': {'guild.id': '10', 'member.isAdmin': false},
          'definitions': <dynamic>[],
        };
        final result = await host.runCommand(request);

        final call = manager.sandboxCalls.single;
        expect(call.method, 'POST');
        expect(call.url.path, '/gateway/bots/b%201/sandbox/command');
        expect(call.headers['authorization'], 'Bearer tok');
        expect(call.headers['content-type'], contains('application/json'));
        expect(jsonDecode(call.body), request);
        expect(result['success'], isTrue);
        expect(result['responses'][0]['payload']['content'], 'Hello World');
      },
    );

    test('le catalogue = GET …/sandbox/functions, décodé en cas', () async {
      final manager = _Manager();
      final cases = await StudioSandboxHost(
        manager.api,
        botId: 'b1',
      ).loadFunctionCases();

      final call = manager.sandboxCalls.single;
      expect(call.method, 'GET');
      expect(call.url.path, '/gateway/bots/b1/sandbox/functions');
      expect(cases, hasLength(3));
      expect(cases.map((c) => c.label), ['allowed', 'denied', '']);
      expect(cases.first.scenario, {
        'context': {'isAdmin': true},
      });
      expect(cases.last.options, {'value': 42, 'count': 2});
      expect(cases[1].expected, 'Access denied.');
    });

    test(
      'pas de runner joignable = indisponible (409, 502, 503, runner_*)',
      () async {
        for (final (status, body) in [
          (409, {'error': 'x', 'code': 'bot_not_running'}),
          (
            502,
            {'code': 'runner_unreachable', 'message': 'runner is unreachable'},
          ),
          (503, {'code': 'runner_not_assigned', 'message': 'not assigned'}),
          (404, {'code': 'runner_not_deployed', 'message': 'not deployed'}),
        ]) {
          final host = StudioSandboxHost(
            _Manager(status: status, errorBody: body).api,
            botId: 'b1',
          );
          await expectLater(
            host.runCommand({'script': 'x'}),
            throwsA(isA<SandboxUnavailableException>()),
            reason: '$status',
          );
          await expectLater(
            host.loadFunctionCases(),
            throwsA(isA<SandboxUnavailableException>()),
            reason: '$status',
          );
        }
      },
    );

    test('les refus du runner gardent leur code', () async {
      for (final (status, code) in [
        (413, 'payload_too_large'),
        (504, 'sandbox_timeout'),
        (429, 'sandbox_busy'),
        (400, 'invalid_request'),
      ]) {
        final host = StudioSandboxHost(
          _Manager(
            status: status,
            errorBody: {'error': 'nope', 'code': code},
          ).api,
          botId: 'b1',
        );
        await expectLater(
          host.runCommand({'script': 'x'}),
          throwsA(
            isA<SandboxRunException>().having((e) => e.code, 'code', code),
          ),
          reason: '$status',
        );
      }
    });

    test(
      'un bot inaccessible (404 bot_not_found) n\'est PAS « démarrez le bot »',
      () async {
        final host = StudioSandboxHost(
          _Manager(
            status: 404,
            errorBody: {
              'code': 'bot_not_found',
              'message': 'bot is not accessible',
            },
          ).api,
          botId: 'b1',
        );
        await expectLater(
          host.runCommand({'script': 'x'}),
          throwsA(
            isA<StudioApiException>().having(
              (e) => e.code,
              'code',
              'bot_not_found',
            ),
          ),
        );
      },
    );
  });

  group('écrans partagés montés sur le Manager', () {
    Future<void> pump(WidgetTester tester, Widget home) async {
      tester.view.physicalSize = const Size(1000, 1600);
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
          locale: const Locale('en'),
          theme: AppTheme.darkTheme(),
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'tester une commande : la demande part au runner, le résultat s\'affiche',
      (tester) async {
        final manager = _Manager();
        await pump(
          tester,
          CommandSandboxPage(
            host: StudioSandboxHost(manager.api, botId: 'b1'),
            script: r'Hello $message[name]',
            options: const [
              {'name': 'name', 'type': 3, 'required': true},
            ],
            definitions: const [
              {'key': 'xp', 'scope': 'guildMember', 'defaultValue': 0},
            ],
          ),
        );
        expect(
          find.text(
            'Runner simulation · Discord and bot data remain untouched.',
          ),
          findsOneWidget,
        );

        await tester.enterText(find.widgetWithText(TextField, 'name'), 'World');
        await run(tester);

        final body = jsonDecode(manager.sandboxCalls.single.body) as Map;
        expect(body['script'], r'Hello $message[name]');
        expect(body['bdfdBackend'], 'native-v1');
        expect(body['options'], {'name': 'World'});
        expect(body['variables'], containsPair('guild.id', '10'));
        expect(body['variables'], containsPair('interaction.isSlash', 'true'));
        expect(body['definitions'], [
          {'key': 'xp', 'scope': 'guildMember', 'defaultValue': 0},
        ]);
        expect(find.text('Test executed'), findsOneWidget);
        expect(find.text('Hello World'), findsOneWidget);
      },
    );

    testWidgets('un bloc : actions envoyées, pas de script', (tester) async {
      final manager = _Manager();
      await pump(
        tester,
        CommandSandboxPage(
          host: StudioSandboxHost(manager.api, botId: 'b1'),
          actions: const [
            {
              'type': 'respondWithMessage',
              'payload': {'content': 'hi'},
            },
          ],
        ),
      );
      expect(find.text('1 configured action(s)'), findsOneWidget);
      await run(tester);

      final body = jsonDecode(manager.sandboxCalls.single.body) as Map;
      expect(body.containsKey('script'), isFalse);
      expect(body['actions'], [
        {
          'type': 'respondWithMessage',
          'payload': {'content': 'hi'},
        },
      ]);
    });

    testWidgets('le contrat est jugé sur le résultat du runner', (
      tester,
    ) async {
      final manager = _Manager();
      await pump(
        tester,
        CommandSandboxPage(
          host: StudioSandboxHost(manager.api, botId: 'b1'),
          script: 'x',
          expectedResponse: 'Something else',
        ),
      );
      await run(tester);
      expect(find.text('Test failed'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Result checks'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Result checks'), findsOneWidget);
    });

    testWidgets('bot arrêté : phrase localisée, pas de code HTTP', (
      tester,
    ) async {
      final manager = _Manager(
        status: 503,
        errorBody: {'code': 'runner_not_assigned', 'message': 'not assigned'},
      );
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await pump(
        tester,
        CommandSandboxPage(
          host: StudioSandboxHost(manager.api, botId: 'b1'),
          script: 'x',
        ),
      );
      await run(tester);
      expect(find.text(en.sandbox_unavailable), findsOneWidget);
      expect(find.textContaining('503'), findsNothing);
      expect(find.text('Test executed'), findsNothing);
    });

    testWidgets('corps trop gros / délai / saturation : phrases localisées', (
      tester,
    ) async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      for (final (status, code, text) in [
        (413, 'payload_too_large', en.sandbox_too_large),
        (504, 'sandbox_timeout', en.sandbox_timeout),
        (429, 'sandbox_busy', en.sandbox_busy),
      ]) {
        final manager = _Manager(
          status: status,
          errorBody: {'error': 'raw server text', 'code': code},
        );
        await pump(
          tester,
          CommandSandboxPage(
            host: StudioSandboxHost(manager.api, botId: 'b1'),
            script: 'x',
          ),
        );
        await run(tester);
        expect(find.text(text), findsOneWidget, reason: code);
        expect(find.text('raw server text'), findsNothing, reason: code);
      }
    });

    testWidgets('laboratoire : catalogue du runner, scénarios, puis test du cas', (
      tester,
    ) async {
      final manager = _Manager();
      await pump(
        tester,
        SandboxFunctionsPage(host: StudioSandboxHost(manager.api, botId: 'b1')),
      );
      expect(
        manager.sandboxCalls.single.url.path,
        '/gateway/bots/b1/sandbox/functions',
      );
      expect(
        find.text(
          '2 functions have 3 regression scenarios. The others remain to be verified.',
        ),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'onlyadmin');
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'$onlyadmin'));
      await tester.pumpAndSettle();
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.text('Denied'), findsOneWidget);

      await tester.tap(find.text('Denied'));
      await tester.pumpAndSettle();
      expect(find.text('Test script'), findsOneWidget);
      expect(find.text('Expected response: Access denied.'), findsOneWidget);

      // Le cas s'exécute sur le runner avec ses options et son scénario.
      await run(tester);
      final body = jsonDecode(manager.sandboxCalls.last.body) as Map;
      expect(
        manager.sandboxCalls.last.url.path,
        '/gateway/bots/b1/sandbox/command',
      );
      expect(body['script'], r'$onlyAdmin[Access denied.]ok');
      expect(body['options'], {'value': 'x', 'count': 2});
      // Réponse simulée « Hello World » ≠ « Access denied. » : le contrat échoue.
      expect(find.text('Test failed'), findsOneWidget);
    });

    testWidgets('laboratoire : le scénario du cas est transmis au moteur', (
      tester,
    ) async {
      final manager = _Manager();
      await pump(
        tester,
        SandboxFunctionsPage(host: StudioSandboxHost(manager.api, botId: 'b1')),
      );
      await tester.enterText(find.byType(TextField), 'onlyadmin');
      await tester.pumpAndSettle();
      await tester.tap(find.text(r'$onlyadmin'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Allowed'));
      await tester.pumpAndSettle();
      await run(tester);
      final body = jsonDecode(manager.sandboxCalls.last.body) as Map;
      expect(body['context'], {'isAdmin': true});
    });

    testWidgets('laboratoire : bot arrêté = phrase + Réessayer qui relit', (
      tester,
    ) async {
      final manager = _Manager(
        status: 409,
        errorBody: {'code': 'bot_not_running', 'message': 'bot is not running'},
      );
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await pump(
        tester,
        SandboxFunctionsPage(host: StudioSandboxHost(manager.api, botId: 'b1')),
      );
      expect(find.text(en.sandbox_unavailable), findsOneWidget);
      expect(find.byType(TextField), findsNothing);

      manager.status = 200;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.text(en.sandbox_unavailable), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(manager.sandboxCalls, hasLength(2));
    });
  });

  group('éditeur de commande', () {
    Future<void> pumpEditor(
      WidgetTester tester,
      _Manager manager,
      CommandDraft draft, {
      Size size = const Size(1000, 1600),
    }) async {
      tester.view.physicalSize = size;
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
          locale: const Locale('en'),
          theme: AppTheme.darkTheme(),
          home: Scaffold(
            body: CommandEditorPage(
              api: manager.api,
              bot: const StudioBot(id: 'b1', name: 'Bot'),
              command: const StudioCommand(id: 'c1', name: 'ping'),
              newDraft: draft,
              onClose: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets(
      'script BDFD : le bouton ouvre le bac à sable avec le brouillon',
      (tester) async {
        final manager = _Manager();
        final draft = CommandDraft.blank(name: 'ping', description: 'd')
          ..executionMode = 'bdfd_script'
          ..bdfdScript = r'$sendMessage[pong]';
        final en = await AppLocalizations.delegate.load(const Locale('en'));
        await pumpEditor(tester, manager, draft);

        await tester.tap(find.text(en.sandbox_test_tooltip));
        await tester.pumpAndSettle();
        expect(find.text('Test command'), findsOneWidget);

        await run(tester);
        final body = jsonDecode(manager.sandboxCalls.single.body) as Map;
        expect(body['script'], r'$sendMessage[pong]');
        expect(body.containsKey('actions'), isFalse);
        // Les définitions du bot viennent du Manager, au format du moteur.
        expect(body['definitions'], [
          {
            'key': 'xp',
            'scope': 'guildMember',
            'defaultValue': 0,
            'value_type': 'number',
          },
        ]);
        // Tester ne modifie ni n'enregistre rien.
        expect(draft.dirty, isTrue); // brouillon neuf, jamais enregistré
        expect(
          manager.seen.where((r) => r.method == 'PATCH' || r.method == 'PUT'),
          isEmpty,
        );
      },
    );

    testWidgets(
      'commande en blocs : les actions du brouillon partent, copiées',
      (tester) async {
        final manager = _Manager();
        final draft = CommandDraft.blank(name: 'ping', description: 'd')
          ..addAction({
            'type': 'respondWithMessage',
            'payload': {'content': 'pong'},
          });
        final en = await AppLocalizations.delegate.load(const Locale('en'));
        await pumpEditor(tester, manager, draft);

        await tester.tap(find.text(en.sandbox_test_tooltip));
        await tester.pumpAndSettle();
        await run(tester);

        final body = jsonDecode(manager.sandboxCalls.single.body) as Map;
        expect(body.containsKey('script'), isFalse);
        expect((body['actions'] as List).single['type'], 'respondWithMessage');
      },
    );

    testWidgets('téléphone : le bouton ne fait pas déborder l\'en-tête', (
      tester,
    ) async {
      final draft = CommandDraft.blank(name: 'ping', description: 'd')
        ..executionMode = 'bdfd_script';
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpEditor(tester, _Manager(), draft, size: const Size(390, 844));
      expect(find.text(en.sandbox_test_tooltip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('commande JavaScript : pas de bouton (comme dans l\'app)', (
      tester,
    ) async {
      final manager = _Manager();
      final draft = CommandDraft.blank(name: 'ping', description: 'd')
        ..executionMode = 'js_script';
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      await pumpEditor(tester, manager, draft);
      expect(find.text(en.sandbox_test_tooltip), findsNothing);
    });
  });
}
