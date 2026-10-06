import 'package:bot_creator_studio/src/api/studio_api.dart';
import 'package:bot_creator_studio/src/auth/auth_controller.dart';
import 'package:bot_creator_studio/src/auth/studio_session.dart';
import 'package:bot_creator_studio/src/premium/premium_gate.dart';
import 'package:bot_creator_studio/src/premium/studio_feature.dart';
import 'package:bot_creator_studio/src/l10n_ext.dart';
import 'package:bot_creator_studio/src/locale_controller.dart';
import 'package:bot_creator_studio/src/studio_app.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

AuthController _controller(MockClient client) => AuthController(
  api: StudioApi(baseUrl: 'https://api.test', client: client),
  store: SessionStore(),
);

Future<void> _storeSession({bool expired = false}) async {
  final session = StudioSession(
    accessToken: 'tok',
    refreshToken: 'ref',
    expiresAt: DateTime.now().toUtc().add(
      expired ? const Duration(minutes: -5) : const Duration(hours: 1),
    ),
  );
  await SessionStore().save(session);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'l\'état OAuth à mémoriser est celui du serveur, pas celui envoyé',
    () async {
      final api = StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient(
          (_) async => http.Response(
            '{"authorization_url":"https://discord.com/oauth2/authorize?state=srv.signed",'
            '"state":"srv.signed"}',
            200,
          ),
        ),
      );
      final start = await api.startDiscordAuthorization(
        redirectUri: 'https://studio.test/',
        state: 'client-state',
      );
      expect(start.state, 'srv.signed');
      expect(start.url, contains('discord.com'));
    },
  );

  test(
    'sans champ state, on lit celui de l\'URL ; à défaut, le nôtre',
    () async {
      StudioApi withBody(String body) => StudioApi(
        baseUrl: 'https://api.test',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      final fromUrl = await withBody(
        '{"url":"https://discord.com/x?state=from-url"}',
      ).startDiscordAuthorization(redirectUri: 'r', state: 'mine');
      expect(fromUrl.state, 'from-url');
      final fallback = await withBody(
        '{"url":"https://discord.com/x"}',
      ).startDiscordAuthorization(redirectUri: 'r', state: 'mine');
      expect(fallback.state, 'mine');
    },
  );

  test('aucune feature premium sans compte premium', () {
    for (final f in StudioFeature.values.where((f) => f.isPremium)) {
      expect(f.isAvailableFor(StudioPlan.free), isFalse);
      expect(f.isAvailableFor(StudioPlan.premium), isTrue);
    }
  });

  test('sans session stockée : déconnecté, aucun appel API', () async {
    var calls = 0;
    final auth = _controller(
      MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
    );
    await auth.init();
    expect(auth.status, AuthStatus.signedOut);
    expect(calls, 0);
  });

  test('session stockée mais refusée par le serveur : déconnecté', () async {
    await _storeSession();
    final auth = _controller(
      MockClient((request) async {
        if (request.url.path == '/auth/refresh') {
          return http.Response('{"message":"revoked"}', 401);
        }
        return http.Response('{"message":"unauthorized"}', 401);
      }),
    );
    await auth.init();
    expect(auth.status, AuthStatus.signedOut);
    expect(auth.session, isNull);
    // Le motif est une clé, traduite à l'affichage par l'écran de connexion.
    expect(auth.issue, AuthIssue.sessionExpired);
  });

  test('session valide : connecté, plan lu depuis le serveur', () async {
    await _storeSession();
    final auth = _controller(
      MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer tok');
        if (request.url.path == '/gateway/runtime') {
          return http.Response('{"plan":"PREMIUM"}', 200);
        }
        return http.Response('{"id":"1"}', 200);
      }),
    );
    await auth.init();
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.plan, StudioPlan.premium);
  });

  test('plan inconnu : gratuit, jamais premium par défaut', () async {
    await _storeSession();
    final auth = _controller(MockClient((_) async => http.Response('{}', 200)));
    await auth.init();
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.plan, StudioPlan.free);
  });

  test('jeton expiré : rafraîchi avant validation', () async {
    await _storeSession(expired: true);
    final paths = <String>[];
    final auth = _controller(
      MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path == '/auth/refresh') {
          return http.Response(
            '{"accessToken":"new","refreshToken":"ref2","expiresIn":3600}',
            200,
          );
        }
        expect(request.headers['authorization'], 'Bearer new');
        return http.Response('{}', 200);
      }),
    );
    await auth.init();
    expect(paths.first, '/auth/refresh');
    expect(auth.status, AuthStatus.signedIn);
    expect(auth.session?.refreshToken, 'ref2');
  });

  test('panne réseau : erreur, pas de porte ouverte', () async {
    await _storeSession();
    final auth = _controller(MockClient((_) async => throw Exception('down')));
    await auth.init();
    expect(auth.status, AuthStatus.error);
  });

  testWidgets('déconnecté : seul l\'écran de connexion Discord est montré', (
    tester,
  ) async {
    final auth = _controller(MockClient((_) async => http.Response('{}', 200)));
    final locale = LocaleController();
    await locale.set(const Locale('fr'));
    await tester.pumpWidget(StudioApp(auth: auth, locale: locale));
    await tester.pumpAndSettle();
    expect(find.text('Se connecter avec Discord'), findsOneWidget);
    expect(find.text('Mes bots'), findsNothing);
  });

  testWidgets(
    'PremiumGate verrouille le planificateur pour un compte gratuit',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('fr'),
          localizationsDelegates: [
            ...StudioLocalizations.localizationsDelegates,
            AppLocalizations.delegate,
          ],
          supportedLocales: StudioLocalizations.supportedLocales,
          home: PremiumGate(
            feature: StudioFeature.scheduler,
            plan: StudioPlan.free,
            child: Text('contenu'),
          ),
        ),
      );
      expect(find.text('contenu'), findsNothing);
      expect(find.text('Déclencheurs planifiés'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    },
  );
}
