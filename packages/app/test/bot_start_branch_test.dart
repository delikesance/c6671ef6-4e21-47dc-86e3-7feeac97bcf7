// L'INSTRUMENT DE VÉRITÉ DU PROPRIÉTAIRE, utilisé comme observable.
//
// Sa console a montré, le même soir : « clic=serveurs Bot Creator », puis
// « branche=LOCAL (desktop) », puis un bot qui démarre bien EN LOCAL, et enfin
// « LOCAL=arrete SERVEUR=desired=STOPPED runtime=stopped -> demarre nulle part (echec) »
// alors que le bot tournait. Trois affirmations fausses, dans le seul instrument qui
// sert à diagnostiquer un démarrage.
//
// Ce test ne recopie aucune de ces phrases : il les FABRIQUE avec les fonctions que la
// production appelle (`resolveRemoteRuntime`, `planBotStart`, `botStartBranchTrace`,
// `requestManagerBotStartWithTraces`, `formatBotStartRealityLog`) et il les CAPTURE là
// où l'utilisateur les lit — `debugPrint`, la console de `flutter run`.
//
// Le vrai `HomePage` n'est pas monté ici : ses minuteurs périodiques et son canal temps
// réel font pendre le harnais (constat consigné dans `home_desktop_manager_data_test.dart`).
// La garantie est donc prouvée au niveau où elle se décide — la garde, la branche, la
// demande au serveur — avec un manager FACTICE (`MockClient`), jamais un vrai réseau.
//
// NON-VACUITÉ : neutraliser la garde (faire rendre à `planBotStart` un plan toujours
// permis) fait échouer le premier scénario sur « aucune ligne branche=LOCAL ».
import 'dart:convert';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot.dart';
import 'package:bot_creator/features/home/logic/bot_start_branch.dart';
import 'package:bot_creator/features/home/logic/bot_start_outcome.dart';
import 'package:bot_creator/features/home/logic/bot_start_server_request.dart';
import 'package:bot_creator/features/home/logic/bot_start_target.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _botId = '1350824555119382678';
const String _botName = 'Nyxx';
const String _jetonDeSession = 'jeton-de-session-qui-ne-doit-jamais-sortir';

/// La console : ce que `debugPrint` reçoit, c'est-à-dire exactement ce que
/// l'utilisateur lit dans `flutter run`.
class _Console {
  final List<String> lignes = <String>[];
  DebugPrintCallback? _precedent;

  void capturer() {
    _precedent = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) lignes.add(message);
    };
  }

  void restaurer() {
    final precedent = _precedent;
    if (precedent != null) debugPrint = precedent;
    _precedent = null;
  }

  /// Les lignes de DÉMARRAGE, dans l'ordre d'écriture.
  List<String> get demarrage =>
      lignes.where((l) => l.startsWith('[demarrage]')).toList(growable: false);

  bool contient(String extrait) =>
      demarrage.any((ligne) => ligne.contains(extrait));
}

/// Manager factice : compte les chemins demandés et répond ce qu'on lui dit.
class _ServeurFactice {
  _ServeurFactice({this.statut = 200, this.erreur});

  final int statut;
  final String? erreur;
  final List<String> demandes = <String>[];

  late final MainApiClient client = MainApiClient(
    baseUrl: 'https://manager-factice.test',
    accessToken: _jetonDeSession,
    httpClient: MockClient((request) async {
      demandes.add('${request.method} ${request.url.path}');
      if (statut != 200) {
        return http.Response(
          jsonEncode(<String, dynamic>{'error': erreur}),
          statut,
        );
      }
      return http.Response(jsonEncode(<String, dynamic>{}), 200);
    }),
  );
}

Future<void> _connecterLeCompte({required bool sessionValide}) async {
  await MainApiSettingsStore.saveConfig(
    const MainApiConfig(baseUrl: 'https://manager-factice.test'),
  );
  if (!sessionValide) {
    return;
  }
  await MainApiSettingsStore.saveSession(
    MainApiSession(
      accessToken: _jetonDeSession,
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  );
}

/// Rejoue la SÉQUENCE de la page : geste, choix, résolutions AVEC le choix, garde,
/// branche, demande au serveur. Chaque étape appelle la fonction de production.
Future<void> _demarrer({
  required _Console console,
  required BotStartTarget choix,
  required bool compteConnecte,
  required bool sessionValide,
  MainApiClient? serveurFactice,
}) async {
  final forcedSource = choix == BotStartTarget.local
      ? RemoteRuntimeSource.local
      : RemoteRuntimeSource.manager;

  appendBotStartTrace('bouton presse bot=$_botId enMarche=false', botId: _botId);
  appendBotStartTrace(
    'clic=${choix == BotStartTarget.local ? 'ce poste' : 'serveurs Bot Creator'}',
    botId: _botId,
  );

  ResolvedRemoteRuntime runtime;
  if (serveurFactice != null) {
    runtime = ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.manager,
      client: serveurFactice,
      detailLabel: 'manager-factice',
    );
  } else {
    // Les DEUX résolutions de la page, toutes deux AVEC le choix de l'utilisateur :
    // une résolution qui perd le choix est ce qui repliait « serveurs » en local.
    runtime = await resolveRemoteRuntime(
      supportsManagerRuntime: true,
      botId: _botId,
      forcedSource: forcedSource,
    );
    runtime = await resolveRemoteRuntime(
      supportsManagerRuntime: true,
      botId: _botId,
      forcedSource: forcedSource,
    );
  }
  if (!compteConnecte && serveurFactice == null) {
    // Rien à résoudre : le compte n'est même pas configuré.
  }

  final plan = planBotStart(
    serverChosen: forcedSource == RemoteRuntimeSource.manager,
    hasRemoteClient: runtime.client != null,
    clientIsManager: runtime.client is MainApiClient,
    runnerIsEmbedded:
        RunnerSettings.getAssociatedRunnerId(_botId) ==
        RunnerSettings.embeddedRunnerId,
    supportsForegroundTask: false,
    // Le scénario mesuré : le moteur Dart du poste, choisi par défaut.
    engineIsJavascript: false,
    serverUnavailableDetail: runtime.unavailableReason ?? '',
  );
  if (!plan.allowed) {
    appendBotStartTrace(plan.refusalTrace!, botId: _botId);
    return; // On s'arrête : aucune branche n'est poursuivie.
  }

  appendBotStartTrace(botStartBranchTrace(plan.branch), botId: _botId);

  final client = runtime.client;
  if (client is MainApiClient) {
    await requestManagerBotStartWithTraces(
      client: client,
      botId: _botId,
      botName: _botName,
      trace: (message) => appendBotStartTrace(message, botId: _botId),
    );
  }
}

String _journalDe(_Console console) => console.demarrage.join('\n');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Console console;

  setUp(() {
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    RunnerSettings.resetAssociationsForTests();
    console = _Console()..capturer();
  });

  tearDown(() => console.restaurer());

  group('serveurs Bot Creator choisis : jamais d execution locale', () {
    test('compte absent -> on explique, et AUCUNE ligne branche=LOCAL', () async {
      await _demarrer(
        console: console,
        choix: BotStartTarget.server,
        compteConnecte: false,
        sessionValide: false,
      );

      expect(
        console.contient('REFUS : serveurs Bot Creator choisis'),
        isTrue,
        reason: 'l echec doit etre explique:\n${_journalDe(console)}',
      );
      expect(
        console.contient('branche=LOCAL'),
        isFalse,
        reason: 'aucune ligne branche=LOCAL ne doit apparaitre:\n'
            '${_journalDe(console)}',
      );
      expect(console.contient('branche=SERVEUR'), isFalse);
      expect(console.contient('serveur: demande envoyee'), isFalse);
    });

    test('session expiree -> on explique, et AUCUNE ligne branche=LOCAL', () async {
      await _connecterLeCompte(sessionValide: false);

      await _demarrer(
        console: console,
        choix: BotStartTarget.server,
        compteConnecte: true,
        sessionValide: false,
      );

      expect(console.contient('REFUS : serveurs Bot Creator choisis'), isTrue);
      expect(console.contient('branche=LOCAL'), isFalse);
    });

    test('serveur qui accepte -> la demande part, la branche est SERVEUR', () async {
      final serveur = _ServeurFactice();

      await _demarrer(
        console: console,
        choix: BotStartTarget.server,
        compteConnecte: true,
        sessionValide: true,
        serveurFactice: serveur.client,
      );

      expect(serveur.demandes, contains('POST /gateway/bots/$_botId/start'));
      expect(console.contient('serveur: demande envoyee'), isTrue);
      expect(console.contient('branche=SERVEUR'), isTrue);
      expect(console.contient('serveur: accepte'), isTrue);
      expect(console.contient('branche=LOCAL'), isFalse);
    });

    test('serveur qui refuse (403) -> code et message ecrits, pas de local', () async {
      final serveur = _ServeurFactice(
        statut: 403,
        erreur: 'your plan does not include personal bots',
      );

      await expectLater(
        _demarrer(
          console: console,
          choix: BotStartTarget.server,
          compteConnecte: true,
          sessionValide: true,
          serveurFactice: serveur.client,
        ),
        throwsA(isA<MainApiClientException>()),
      );

      expect(console.contient('serveur: demande envoyee'), isTrue);
      expect(console.contient('branche=SERVEUR'), isTrue);
      expect(
        console.contient(
          'serveur: REFUSE (403: your plan does not include personal bots)',
        ),
        isTrue,
        reason: _journalDe(console),
      );
      expect(console.contient('branche=LOCAL'), isFalse);
      expect(console.contient('serveur: accepte'), isFalse);
    });

    test('aucun jeton ne sort dans la console, meme en cas de refus', () async {
      final serveur = _ServeurFactice(statut: 403, erreur: 'refus de formule');

      await expectLater(
        _demarrer(
          console: console,
          choix: BotStartTarget.server,
          compteConnecte: true,
          sessionValide: true,
          serveurFactice: serveur.client,
        ),
        throwsA(isA<MainApiClientException>()),
      );

      expect(_journalDe(console).contains(_jetonDeSession), isFalse);
    });
  });

  group('ce poste choisi : la branche locale est bien empruntee', () {
    test('bot associe au manager : le CHOIX fait demarrer en local', () async {
      await _connecterLeCompte(sessionValide: true);
      RunnerSettings.associateBotWithRunner(_botId, 'manager');

      // Sans choix, la même entrée part sur les serveurs : c'est le contraste qui
      // prouve que c'est bien le CHOIX qui décide, et qu'il n'est plus perdu.
      final sansChoix = await resolveRemoteRuntime(
        supportsManagerRuntime: true,
        botId: _botId,
      );
      expect(sansChoix.client, isNotNull);

      await _demarrer(
        console: console,
        choix: BotStartTarget.local,
        compteConnecte: true,
        sessionValide: true,
      );

      expect(
        console.contient('branche=LOCAL (desktop)'),
        isTrue,
        reason: _journalDe(console),
      );
      expect(console.contient('branche=SERVEUR'), isFalse);
      expect(console.contient('serveur: demande envoyee'), isFalse);
    });
  });

  group('les libelles de branche', () {
    test('SERVEUR et LOCAL desktop sont nommes sans ambiguite', () {
      expect(botStartBranchTrace(BotStartBranch.server), 'branche=SERVEUR');
      expect(
        botStartBranchTrace(BotStartBranch.localDesktop),
        'branche=LOCAL (desktop)',
      );
      expect(
        botStartBranchTrace(BotStartBranch.localJsEngine),
        'branche=LOCAL (moteur JS embarque)',
      );
      expect(botStartBranchTrace(BotStartBranch.mobile), 'branche=MOBILE');
      expect(
        botStartBranchTrace(BotStartBranch.configuredRunner),
        'branche=RUNNER (moteur JS, machine configuree)',
      );
    });

    test('cinq branches, cinq libelles distincts', () {
      final libelles = BotStartBranch.values.map(botStartBranchTrace).toSet();
      expect(libelles.length, BotStartBranch.values.length);
    });

    test('le mobile et les deux runners sont eux aussi refuses au choix serveur',
        () {
      // Une entrée par branche LOCALE possible : les mêmes tests que le code.
      final cas = <BotStartBranch, ({bool client, bool manager, bool runner, bool mobile, bool js})>{
        BotStartBranch.mobile: (client: false, manager: false, runner: false, mobile: true, js: false),
        BotStartBranch.localJsEngine: (client: false, manager: false, runner: false, mobile: false, js: true),
        BotStartBranch.localDesktop: (client: false, manager: false, runner: false, mobile: false, js: false),
        BotStartBranch.configuredRunner: (client: true, manager: false, runner: false, mobile: false, js: false),
      };

      for (final entree in cas.entries) {
        final refus = planBotStart(
          serverChosen: true,
          hasRemoteClient: entree.value.client,
          clientIsManager: entree.value.manager,
          runnerIsEmbedded: entree.value.runner,
          supportsForegroundTask: entree.value.mobile,
          engineIsJavascript: entree.value.js,
          serverUnavailableDetail: 'session absente',
        );
        expect(refus.branch, entree.key);
        expect(refus.allowed, isFalse, reason: '${entree.key} doit etre refusee');
        expect(refus.refusalTrace, contains('serveurs Bot Creator choisis'));
      }
    });
  });

  group('la ligne de realite dit la verite', () {
    test('demarrage desktop : LOCAL=enMarche, jamais un faux echec', () {
      final localRunning = thisMachineExecutesBot(
        desktopEngineSession: true,
        mobileSession: false,
        embeddedRunnerSession: false,
      );
      expect(
        formatBotStartRealityLog(
          moment: '+5s',
          localRunning: localRunning,
          serverRunning: false,
          serverBotEntry: <String, dynamic>{
            'desired_state': 'STOPPED',
            'runtime_state': 'stopped',
          },
        ),
        '+5s : LOCAL=enMarche SERVEUR=desired=STOPPED runtime=stopped '
        '-> demarre sur ce poste',
      );
    });

    test('un ecran qui ne voit pas l execution locale ne suffit plus', () {
      // Le geste et l'association ne sont PAS des faits d'exécution : seuls les
      // signaux produits par le démarrage local comptent.
      expect(
        thisMachineExecutesBot(
          desktopEngineSession: false,
          mobileSession: false,
          embeddedRunnerSession: false,
        ),
        isFalse,
      );
      expect(
        thisMachineExecutesBot(
          desktopEngineSession: false,
          mobileSession: false,
          embeddedRunnerSession: true,
        ),
        isTrue,
      );
    });
  });
}
