import 'dart:convert';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/home.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_logs_console_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Bug utilisateur (desktop, capture à l'appui) : le panneau de logs d'un bot
/// hébergé affichait « Aucun log pour le moment — En attente d'événements en
/// direct... » avec un badge LIVE, alors que le bot tournait bien sur les
/// serveurs Bot Creator. Il attendait donc un flux PUSSÉ qui n'arrive jamais.
///
/// Correctif verrouillé ici : la console LIT les logs du bot hébergé
/// (`GET /gateway/bots/{id}/logs`, scope `read:bots`, la route que le manager
/// expose déjà et que la page des logs consomme), le flux en direct ne restant
/// qu'un bonus. Aucun transport réel : le faux serveur est un `MockClient`.
/// Chaque test utilise SON bot : le magasin de logs est global au processus, et
/// deux tests sur le même identifiant se marcheraient dessus (des lignes laissées
/// par le premier feraient croire au second que la console n'est pas vide).
const String _botId = '424242424242424242';
const String _emptyBotId = '515151515151515151';
const String _localBotId = '616161616161616161';

/// Faux serveur : un VRAI `MainApiClient` branché sur un `MockClient`, qui
/// compte les requêtes reçues. Rien ne sort de la machine.
class _FakeServer {
  _FakeServer({this.lines = const <String>[]});

  /// Ce que le serveur rend dans `lines`.
  List<String> lines;

  /// URLs réellement demandées — c'est la preuve d'absence de requête en local.
  final List<Uri> requested = <Uri>[];

  int get requestCount => requested.length;

  late final MainApiClient client = MainApiClient(
    baseUrl: 'https://api.example.com',
    accessToken: 'jeton-de-test',
    httpClient: MockClient((request) async {
      requested.add(request.url);
      return http.Response(
        jsonEncode(<String, dynamic>{'lines': lines}),
        200,
        headers: <String, String>{'content-type': 'application/json'},
      );
    }),
  );
}

Widget _hostApp(Widget child) {
  return MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

/// Le panneau tel qu'il est monté dans l'éditeur : le scope résout la source,
/// la carte dessine. `fillHeight` est nécessaire pour voir le sous-titre d'état
/// vide (c'est la mise en page desktop, celle du défaut constaté).
Widget _panel({
  required _FakeServer server,
  required RemoteRuntimeSource source,
  String botId = _botId,
  bool withClient = true,
}) {
  return BotServerLogsScope(
    botId: botId,
    runtimeResolver: () async => ResolvedRemoteRuntime(
      source: source,
      client: withClient ? server.client : null,
    ),
    builder: (context, serverLogs) => BotHomeLiveConsoleCard(
      botId: botId,
      isLive: true,
      fillHeight: true,
      serverLogs: serverLogs,
      onOpenLogs: () {},
    ),
  );
}

/// Démonte le panneau : sans cela, le minuteur de relecture survivrait à
/// l'arbre de widgets (« A Timer is still pending after the widget tree was
/// disposed »).
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'bot hébergé : les lignes LUES sur le serveur s\'affichent (le flux restant un bonus)',
    (tester) async {
      final server = _FakeServer(
        lines: const <String>[
          '[12:00:01] bot en ligne',
          '[12:00:02] 1 guilde rejointe',
        ],
      );

      await tester.pumpWidget(
        _hostApp(
          SizedBox(
            height: 400,
            child: _panel(
              server: server,
              source: RemoteRuntimeSource.manager,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        server.requested.first.path,
        '/gateway/bots/$_botId/logs',
        reason:
            'le panneau doit LIRE les logs du bot hébergé : requêtes reçues '
            '${server.requested}',
      );
      expect(
        find.textContaining('bot en ligne'),
        findsOneWidget,
        reason: 'la ligne lue sur le serveur n\'est pas affichée',
      );
      expect(find.textContaining('1 guilde rejointe'), findsOneWidget);
      expect(
        find.textContaining('En attente d\'événements en direct'),
        findsNothing,
        reason:
            'le panneau affiche encore l\'attente d\'un flux alors que la '
            'lecture serveur a rendu des lignes',
      );

      // Le flux en direct reste un BONUS : une ligne poussée s'ajoute aux lignes
      // lues au lieu de les remplacer.
      appendBotLog(
        'ligne poussee par le flux',
        botId: _botId,
        source: RemoteRuntimeSource.manager,
      );
      await tester.pump();
      await tester.pump();

      expect(find.textContaining('ligne poussee par le flux'), findsOneWidget);
      expect(
        find.textContaining('bot en ligne'),
        findsOneWidget,
        reason:
            'la ligne lue a disparu quand le flux a poussé : le flux ne doit '
            'pas écraser la lecture',
      );

      await _unmount(tester);
    },
  );

  testWidgets(
    'bot hébergé sans ligne : l\'état vide dit la vérité et non « en attente »',
    (tester) async {
      final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
      final server = _FakeServer(lines: const <String>[]);

      await tester.pumpWidget(
        _hostApp(
          SizedBox(
            height: 400,
            child: _panel(
              server: server,
              source: RemoteRuntimeSource.manager,
              botId: _emptyBotId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(server.requestCount, greaterThanOrEqualTo(1));
      expect(
        find.text(l10n.bot_logs_server_empty),
        findsOneWidget,
        reason:
            'le serveur a répondu une liste vide : le panneau doit dire qu\'il '
            'n\'y a rien à afficher',
      );
      expect(
        find.textContaining('En attente d\'événements en direct'),
        findsNothing,
        reason:
            'le panneau laisse croire qu\'un flux poussé va finir par arriver '
            'alors qu\'il a déjà lu une liste vide',
      );

      await _unmount(tester);
    },
  );

  testWidgets(
    'bot exécuté en local : AUCUNE requête serveur, les logs locaux restent affichés',
    (tester) async {
      // Contrôle de vacuité : le même harnais, en source serveur, émet bien une
      // requête. Sans lui, « zéro requête en local » ne prouverait rien.
      final control = _FakeServer(lines: const <String>['ligne de controle']);
      await tester.pumpWidget(
        _hostApp(
          SizedBox(
            height: 400,
            child: _panel(
              server: control,
              source: RemoteRuntimeSource.manager,
              botId: _localBotId,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        control.requestCount,
        greaterThanOrEqualTo(1),
        reason:
            'contrôle cassé : le harnais n\'émet aucune requête même en source '
            'serveur, le test « local » plus bas serait donc vide de sens',
      );
      await _unmount(tester);

      // 1. Le cas réel : source locale, aucun client manager.
      final local = _FakeServer(lines: const <String>['jamais lu']);
      appendBotLog('ligne du process local', botId: _localBotId);
      await tester.pumpWidget(
        _hostApp(
          SizedBox(
            height: 400,
            child: _panel(
              server: local,
              source: RemoteRuntimeSource.local,
              botId: _localBotId,
              withClient: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        local.requestCount,
        0,
        reason:
            'un bot exécuté en local ne doit PAS lire le serveur (requêtes '
            'reçues : ${local.requested})',
      );
      expect(
        find.textContaining('ligne du process local'),
        findsOneWidget,
        reason: 'les logs du process local doivent rester visibles',
      );
      await _unmount(tester);

      // 2. Entrée hostile : une source locale qui porterait quand même un client.
      //    On l'attache EXPRÈS, sinon le zéro ci-dessus serait trivial (aucun
      //    client à appeler) au lieu de prouver le garde-fou de SOURCE.
      final hostile = _FakeServer(lines: const <String>['jamais lu non plus']);
      await tester.pumpWidget(
        _hostApp(
          SizedBox(
            height: 400,
            child: _panel(
              server: hostile,
              source: RemoteRuntimeSource.local,
              botId: _localBotId,
              withClient: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        hostile.requestCount,
        0,
        reason:
            'même avec un client disponible, une source locale ne doit émettre '
            'aucune requête (requêtes reçues : ${hostile.requested})',
      );
      await _unmount(tester);
    },
  );
}
