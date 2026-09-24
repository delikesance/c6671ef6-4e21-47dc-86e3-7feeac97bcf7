// Preuve du pendant SERVEUR de la garde anti-config-vide : le manager peut
// refuser une poussée par `409 bot_config_overshrink` — une suppression MASSIVE,
// mais peut-être volontaire. Le serveur n'applique rien et a restauré la
// configuration précédente : ce n'est ni une panne, ni une erreur de l'app,
// c'est une QUESTION à poser.
//
// Ce que ce fichier prouve, au niveau où chaque propriété se décide :
//   (a) le 409 PRÉCIS déclenche la demande — le code serveur est exposé
//       (`MainApiClientException.code`) et le refus se reconnaît sans deviner ;
//   (b) sur accord, la MÊME poussée est REJOUÉE avec `confirmOvershrink: true`
//       (le corps de la requête est inspecté) ;
//   (c) sur annulation, AUCUNE requête n'est émise après le refus et la
//       configuration locale est INCHANGÉE ;
//   (d) un autre 409 ou une autre erreur ne déclenche PAS ce dialogue, et le
//       refus n'est pas présenté comme une panne serveur.
//
// LIMITE ASSUMÉE : `AppHomePage` (et ses `part` home.sync/home.logic) n'est pas
// montable dans ce dépôt. Le dialogue est donc prouvé via la brique extraite
// (`showBotConfigOvershrinkConfirmation`) montée dans un `MaterialApp`, et
// l'enchaînement « refus → demande → rejeu » via
// `pushBotConfigToleratingOvershrink`, qui est EXACTEMENT la fonction appelée par
// l'écran (le seul écart est le transport, remplacé par un client HTTP simulé).
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/core/utils/bot_payload_guard.dart';
import 'package:bot_creator/features/bot_editor/presentation/widgets/bot_config_overshrink_dialog.dart';
import 'package:bot_creator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

const String _botId = 'overshrink-confirmation-bot';
const String _botName = 'OvershrinkBot';

/// Les 6 langues servies par l'application.
const List<String> _locales = <String>['en', 'fr', 'de', 'ja', 'pt', 'tr'];

/// Messages du manager tels qu'ils partent réellement (`domain.APIError`) : le
/// code applicatif ET la phrase qui porte les deux tailles.
const String _overshrinkMessage =
    'bot_config_overshrink: existing config is 1044565 bytes but the incoming '
    'config is 487 bytes (refused below 2048 bytes or 20% of the existing '
    'config)';

/// Le 409 exact du contrat, tel que `_parseResponse` le construit.
MainApiClientException _overshrinkError() => const MainApiClientException(
  _overshrinkMessage,
  statusCode: 409,
  code: botConfigOvershrinkErrorCode,
);

/// Un `409` d'une AUTRE nature, servi par le même serveur sur la même route.
MainApiClientException _otherConflictError() => const MainApiClientException(
  'bot_config_unreadable: the stored bot configuration could not be read',
  statusCode: 409,
  code: 'bot_config_unreadable',
);

/// Charge de bot VALIDE (la garde anti-config-vide ne doit pas interférer) et
/// nettement plus petite que la configuration protégée côté serveur.
Map<String, dynamic> _validPayload() => <String, dynamic>{
  'runtimeEngine': 'javascript',
  'commands': <dynamic>[
    <String, dynamic>{'name': 'ping', 'script': 'reply();'},
  ],
  'events': <dynamic>[],
};

bool _isSyncPost(http.Request request) =>
    request.method == 'POST' && request.url.path.endsWith('/bots/sync');

/// Client dont la couche HTTP simule le manager : sur `/gateway/bots/sync`, la
/// poussée est refusée tant que le corps ne porte pas `confirmOvershrink: true`.
MainApiClient _overshrinkClient(List<http.Request> sink) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    if (request.method == 'POST' &&
        request.url.path.endsWith('/presign-config')) {
      return http.Response(
        jsonEncode(<String, String>{
          'botId': _botId,
          'configUrl': 'https://cdn.example.com/configs/$_botId.json',
          'uploadUrl': 'https://cdn.example.com/upload/$_botId',
        }),
        200,
      );
    }
    if (request.url.host == 'cdn.example.com') {
      return http.Response('{}', 200);
    }
    if (_isSyncPost(request)) {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (body['confirmOvershrink'] != true) {
        return http.Response(
          jsonEncode(<String, String>{
            'code': botConfigOvershrinkErrorCode,
            'message': _overshrinkMessage,
            'request_id': 'req-1',
          }),
          409,
        );
      }
      return http.Response('{"ok":true}', 200);
    }
    return http.Response('{}', 200);
  }),
);

/// Client qui refuse TOUT, avec l'erreur fournie.
MainApiClient _refusingClient(
  List<http.Request> sink,
  MainApiClientException conflict,
) => MainApiClient(
  baseUrl: 'https://api.example.com',
  accessToken: 'token',
  httpClient: MockClient((request) async {
    sink.add(request);
    if (request.method == 'POST' &&
        request.url.path.endsWith('/presign-config')) {
      return http.Response(
        jsonEncode(<String, String>{
          'botId': _botId,
          'configUrl': 'https://cdn.example.com/configs/$_botId.json',
          'uploadUrl': 'https://cdn.example.com/upload/$_botId',
        }),
        200,
      );
    }
    if (request.url.host == 'cdn.example.com') {
      return http.Response('{}', 200);
    }
    return http.Response(
      jsonEncode(<String, String>{
        'code': conflict.code ?? '',
        'message': conflict.message,
      }),
      conflict.statusCode ?? 500,
    );
  }),
);

/// Corps JSON des POST `/gateway/bots/sync`, dans l'ordre d'émission.
List<Map<String, dynamic>> _syncBodies(List<http.Request> requests) => requests
    .where(_isSyncPost)
    .map((request) => jsonDecode(request.body) as Map<String, dynamic>)
    .toList();

/// Réplique EXACTE de l'enchaînement de `_AppHomePageSync._pushPayloadToManager`
/// (mêmes fonctions, transport seul simulé).
class _PushHarness extends StatefulWidget {
  const _PushHarness({required this.push, required this.onResult});

  final Future<void> Function(bool confirmOvershrink) push;
  final void Function(Object result) onResult;

  @override
  State<_PushHarness> createState() => _PushHarnessState();
}

class _PushHarnessState extends State<_PushHarness> {
  Future<void> _run() async {
    try {
      final outcome = await pushBotConfigToleratingOvershrink(
        push: widget.push,
        askConfirmation: () => showBotConfigOvershrinkConfirmation(context),
      );
      widget.onResult(outcome);
    } catch (error) {
      widget.onResult(error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: _run,
          child: const Text('push'),
        ),
      ),
    );
  }
}

Widget _harnessApp({
  required String locale,
  required Future<void> Function(bool confirmOvershrink) push,
  required void Function(Object result) onResult,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: _PushHarness(push: push, onResult: onResult),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp('overshrink_push');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, (call) async {
          return documentsDir.path;
        });
    appManager = AppManager();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pathProviderChannel, null);
    if (await documentsDir.exists()) {
      try {
        await documentsDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await appManager.deleteAppCommands(_botId);
    await appManager.saveApp(_botId, <String, dynamic>{
      'id': _botId,
      'username': _botName,
      'token': 'test-token',
      'runtimeEngine': 'javascript',
      'workflows': <Map<String, dynamic>>[],
    });
    await appManager.saveAppCommand(_botId, 'cmd-keep', <String, dynamic>{
      'id': 'cmd-keep',
      'name': 'ping',
      'type': 'chatInput',
      'data': <String, dynamic>{
        'executionMode': 'javascript',
        'jsScriptContent': 'await interaction.reply("pong");',
      },
    });
  });

  group('(a) le 409 précis se reconnaît au code du serveur', () {
    test('ce 409 précis est reconnu, un autre 409 ou une panne non', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      expect(isBotConfigOvershrinkRefusal(_overshrinkError()), isTrue);
      expect(
        isBotConfigOvershrinkRefusal(_otherConflictError()),
        isFalse,
        reason: "un 409 d'une autre nature ne doit pas ouvrir ce dialogue",
      );
      expect(
        isBotConfigOvershrinkRefusal(
          const MainApiClientException('boom', statusCode: 500),
        ),
        isFalse,
      );
      // Le STATUT porte la décision, pas le code : une panne serveur qui
      // recopierait le même code (ou le même texte, via une passerelle qui ne
      // rend que le message) ne doit PAS se transformer en question posée à
      // l'utilisateur. Rien n'a été refusé volontairement, il n'y a rien à
      // confirmer — et lui proposer de « supprimer quand même » devant une panne
      // serait un mensonge.
      expect(
        isBotConfigOvershrinkRefusal(
          const MainApiClientException(
            'boom',
            statusCode: 500,
            code: botConfigOvershrinkErrorCode,
          ),
        ),
        isFalse,
        reason:
            'un 500 portant le même CODE ne doit pas ouvrir le dialogue : seul un 409 est une question',
      );
      expect(
        isBotConfigOvershrinkRefusal(
          const MainApiClientException(
            '$botConfigOvershrinkErrorCode: existing config is 1044565 bytes',
            statusCode: 500,
          ),
        ),
        isFalse,
        reason:
            'un 500 dont le MESSAGE contient le code ne doit pas ouvrir le dialogue non plus',
      );
      expect(
        isBotConfigOvershrinkRefusal(Exception('reseau')),
        isFalse,
        reason: 'une panne réseau ne doit pas passer pour une suppression',
      );
      // Le refus LOCAL (charge vide) reste distinct : il n'a jamais atteint le
      // réseau, il n'y a rien à demander.
      expect(
        localizedBotConfigOvershrinkNothingSent(
          l10n,
          const DegenerateBotPayloadException('syncBot'),
        ),
        isNull,
      );
      expect(
        localizedBotPayloadRefusalMessage(l10n, _overshrinkError()),
        isNull,
        reason: 'les deux refus ne doivent pas se confondre',
      );
      // Et la phrase du refus serveur est bien servie pour ce 409 précis.
      expect(
        localizedBotConfigOvershrinkNothingSent(l10n, _overshrinkError()),
        l10n.bot_config_overshrink_body,
      );
    });

    test('le code du serveur remonte dans l’exception du client', () async {
      final requests = <http.Request>[];
      final failure = await _catching(
        () => _overshrinkClient(
          requests,
        ).syncBot(_botId, _botName, _validPayload(), force: true),
      );

      expect(failure, isA<MainApiClientException>());
      expect(isBotConfigOvershrinkRefusal(failure!), isTrue);
      final exception = failure as MainApiClientException;
      expect(exception.statusCode, 409);
      expect(exception.code, botConfigOvershrinkErrorCode);
      debugPrint('[PREUVE] exception du 409 = $exception (code=${exception.code})');
    });

    test('les 4 phrases sont traduites dans les 6 langues', () async {
      final titles = <String, String>{};
      final bodies = <String, String>{};
      for (final code in _locales) {
        final l10n = await AppLocalizations.delegate.load(Locale(code));
        final confirmation = localizedBotConfigOvershrinkConfirmation(l10n);
        expect(confirmation.title.trim(), isNotEmpty);
        expect(confirmation.body.trim(), isNotEmpty);
        expect(confirmation.confirmLabel.trim(), isNotEmpty);
        expect(confirmation.keepLocalLabel.trim(), isNotEmpty);
        titles[code] = confirmation.title;
        bodies[code] = confirmation.body;
      }
      debugPrint('[PREUVE] titres = $titles');
      debugPrint('[PREUVE] corps = $bodies');
      // Une traduction RÉELLE n'est pas l'anglais recopié.
      expect(titles['fr'], isNot(titles['en']));
      expect(bodies['de'], isNot(bodies['en']));
      expect(bodies['ja'], isNot(bodies['en']));
      expect(titles['pt'], isNot(titles['en']));
      expect(bodies['tr'], isNot(bodies['en']));
      // La phrase dit les deux faits que l'utilisateur ne peut pas deviner :
      // rien n'a été envoyé, et sa configuration locale est intacte.
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      expect(en.bot_config_overshrink_body, contains('Nothing has been sent'));
      expect(en.bot_config_overshrink_body, contains('intact'));
    });
  });

  group('(b) sur accord, la MÊME poussée est rejouée avec le drapeau', () {
    test('le corps inspecté porte confirmOvershrink: true au rejeu', () async {
      final requests = <http.Request>[];
      var asked = 0;

      final outcome = await pushBotConfigToleratingOvershrink(
        push: (confirmOvershrink) => _overshrinkClient(requests).syncBot(
          _botId,
          _botName,
          _validPayload(),
          force: true,
          confirmOvershrink: confirmOvershrink,
        ),
        askConfirmation: () async {
          asked++;
          return true;
        },
      );

      expect(outcome, BotConfigPushOutcome.sent);
      expect(asked, 1, reason: 'la question est posée une fois, pas deux');

      final syncBodies = _syncBodies(requests);
      debugPrint('[PREUVE] corps des POST /gateway/bots/sync = $syncBodies');
      expect(syncBodies, isNotEmpty);
      // Rien ne part AVANT l'accord : aucune requête ne porte le drapeau.
      expect(
        syncBodies.take(syncBodies.length - 1).every(
          (body) => body.containsKey('confirmOvershrink') == false,
        ),
        isTrue,
        reason: 'le drapeau ne doit apparaître qu’après un accord explicite',
      );
      // Le rejeu : le drapeau du contrat, et la même poussée.
      final replayed = syncBodies.last;
      expect(replayed['confirmOvershrink'], isTrue);
      expect(replayed['botId'], _botId);
      expect(replayed['botName'], _botName);
    });

    test('le plancher absolu ne rouvre pas de dialogue', () async {
      final requests = <http.Request>[];
      var asked = 0;

      final outcome = await pushBotConfigToleratingOvershrink(
        push: (confirmOvershrink) => _refusingClient(
          requests,
          _overshrinkError(),
        ).syncBot(
          _botId,
          _botName,
          _validPayload(),
          force: true,
          confirmOvershrink: confirmOvershrink,
        ),
        askConfirmation: () async {
          asked++;
          return true;
        },
      );

      expect(outcome, BotConfigPushOutcome.overshrinkFloorRefused);
      expect(asked, 1, reason: 'on ne redemande pas ce qui vient d’être accepté');
    });
  });

  group('(c) sur annulation : aucune requête, local inchangé', () {
    test('rien ne part et la configuration locale reste identique', () async {
      final appBefore = await appManager.getApp(_botId);
      final commandsBefore = await appManager.listAppCommands(_botId);
      final requests = <http.Request>[];
      var asked = 0;
      var requestsWhenAsked = -1;

      final outcome = await pushBotConfigToleratingOvershrink(
        push: (confirmOvershrink) => _overshrinkClient(requests).syncBot(
          _botId,
          _botName,
          _validPayload(),
          force: true,
          confirmOvershrink: confirmOvershrink,
        ),
        askConfirmation: () async {
          asked++;
          requestsWhenAsked = requests.length;
          return false;
        },
      );

      expect(outcome, BotConfigPushOutcome.keptLocal);
      expect(asked, 1);
      // AUCUNE requête après le refus.
      debugPrint(
        '[PREUVE] requêtes à la question=$requestsWhenAsked, '
        'total après annulation=${requests.length}',
      );
      expect(requests.length, requestsWhenAsked);
      // Et surtout : aucune requête ne porte le drapeau.
      expect(
        _syncBodies(requests).every(
          (body) => body.containsKey('confirmOvershrink') == false,
        ),
        isTrue,
      );
      // La copie locale est INCHANGÉE, à l'entrée près.
      expect(await appManager.getApp(_botId), appBefore);
      expect(
        (await appManager.listAppCommands(_botId)).map((c) => c['id']).toList(),
        commandsBefore.map((c) => c['id']).toList(),
      );
    });
  });

  group('(d) un autre refus ne déclenche pas ce dialogue', () {
    test('409 bot_config_unreadable : remonté tel quel, aucune question', () async {
      final l10n = await AppLocalizations.delegate.load(const Locale('en'));
      final requests = <http.Request>[];
      var asked = 0;

      final failure = await _catching(
        () => pushBotConfigToleratingOvershrink(
          push: (confirmOvershrink) => _refusingClient(
            requests,
            _otherConflictError(),
          ).syncBot(
            _botId,
            _botName,
            _validPayload(),
            force: true,
            confirmOvershrink: confirmOvershrink,
          ),
          askConfirmation: () async {
            asked++;
            return true;
          },
        ),
      );

      expect(failure, isA<MainApiClientException>());
      expect((failure as MainApiClientException).statusCode, 409);
      expect(asked, 0, reason: 'la question ne se pose que pour ce 409 précis');
      expect(localizedBotConfigOvershrinkNothingSent(l10n, failure), isNull);
    });

    test('une panne serveur (500) remonte, sans question', () async {
      final requests = <http.Request>[];
      var asked = 0;

      final failure = await _catching(
        () => pushBotConfigToleratingOvershrink(
          push: (confirmOvershrink) => _refusingClient(
            requests,
            const MainApiClientException('internal_error', statusCode: 500),
          ).syncBot(
            _botId,
            _botName,
            _validPayload(),
            force: true,
            confirmOvershrink: confirmOvershrink,
          ),
          askConfirmation: () async {
            asked++;
            return true;
          },
        ),
      );

      expect(failure, isA<MainApiClientException>());
      expect((failure as MainApiClientException).statusCode, 500);
      expect(asked, 0);
    });
  });

  group('dialogue : ce qu’il dit et ce qu’il rend', () {
    testWidgets('sur accord : les 4 phrases s’affichent et le rejeu part', (
      tester,
    ) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final pushes = <bool>[];
      Object? result;

      await tester.pumpWidget(
        _harnessApp(
          locale: 'fr',
          push: (confirmOvershrink) async {
            pushes.add(confirmOvershrink);
            if (!confirmOvershrink) {
              throw _overshrinkError();
            }
          },
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      // Le dialogue dit ce qui compte : la question, et rien n'est encore parti.
      expect(find.text(fr.bot_config_overshrink_title), findsOneWidget);
      expect(find.text(fr.bot_config_overshrink_body), findsOneWidget);
      expect(find.text(fr.bot_config_overshrink_send_anyway), findsOneWidget);
      expect(find.text(fr.bot_config_overshrink_keep_local), findsOneWidget);
      debugPrint('[PREUVE] dialogue affiché = ${fr.bot_config_overshrink_body}');

      await tester.tap(find.text(fr.bot_config_overshrink_send_anyway));
      await tester.pumpAndSettle();

      expect(pushes, <bool>[false, true]);
      expect(result, BotConfigPushOutcome.sent);
    });

    testWidgets('sur annulation : le dialogue rend false et rien n’est rejoué', (
      tester,
    ) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      final pushes = <bool>[];
      Object? result;

      await tester.pumpWidget(
        _harnessApp(
          locale: 'fr',
          push: (confirmOvershrink) async {
            pushes.add(confirmOvershrink);
            if (!confirmOvershrink) {
              throw _overshrinkError();
            }
          },
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(fr.bot_config_overshrink_keep_local));
      await tester.pumpAndSettle();

      expect(result, BotConfigPushOutcome.keptLocal);
      expect(pushes, <bool>[false], reason: 'aucun rejeu après annulation');
    });

    testWidgets('un AUTRE 409 n’ouvre aucun dialogue', (tester) async {
      final fr = await AppLocalizations.delegate.load(const Locale('fr'));
      Object? result;

      await tester.pumpWidget(
        _harnessApp(
          locale: 'fr',
          push: (confirmOvershrink) async => throw _otherConflictError(),
          onResult: (value) => result = value,
        ),
      );

      await tester.tap(find.text('push'));
      await tester.pumpAndSettle();

      expect(find.text(fr.bot_config_overshrink_title), findsNothing);
      expect(find.text(fr.bot_config_overshrink_body), findsNothing);
      expect(result, isA<MainApiClientException>());
    });
  });
}

/// Appelle [body] et rend l'erreur attrapée — ou `null` si rien n'a levé.
Future<Object?> _catching(Future<Object?> Function() body) async {
  try {
    return await body();
  } catch (error) {
    return error;
  }
}
