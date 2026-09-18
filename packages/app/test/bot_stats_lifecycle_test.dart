// Le sondage de l'écran Stats est adaptatif (`PollCadence`) et piloté par un timer RÉARMÉ
// à chaque tick (`_statsPollTimer`), jamais par un `Timer.periodic`. Deux comportements de
// cycle de vie n'étaient jusqu'ici validés que par `flutter analyze` :
//
//   1. passage en arrière-plan : le timer est annulé et RIEN n'est réarmé (pas de sondage
//      pour un écran que personne ne regarde) ;
//   2. retour au premier plan : cadence remise au nominal ET tick IMMÉDIAT (l'utilisateur
//      qui revient ne doit pas attendre 3 s pour voir une donnée fraîche).
//
// Ces deux effets vivent dans un `State` privé, sans client injectable : le seul moyen de
// les prouver est de monter le VRAI `BotStatsPage` (comme
// `gateway_snapshot_fallback_test.dart` monte le vrai `HomePage`) et d'observer ses ticks
// via `BotStatsPage.debugStatsTicks`, compteur pur qui ne conditionne aucun comportement.
//
// Le quatrième invariant — « aucun timer orphelin » — n'a pas d'assertion dédiée : le
// harnais démonte l'arbre en fin de test puis échoue avec « A Timer is still pending even
// after the widget tree was disposed » si un timer a survécu au `dispose` (ou a été réarmé
// après lui). Chaque test se termine donc par un démontage explicite suivi d'une avance
// d'horloge, ce qui rend l'invariant mordant.
//
// Particularité d'environnement, à connaître avant de toucher à ces tests : avant d'armer
// son premier timer, l'écran résout sa source de métriques, et cette résolution lit SQLite
// (`getBotRuntimeEngine`). C'est du VRAI asynchrone, que la zone simulée de `flutter_test`
// ne fait pas avancer (`pump` n'élapse que l'horloge simulée) : d'où la fenêtre de temps
// réel (`runAsync`) de `waitForFirstTick`, bornée et documentée.
import 'dart:io';

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/bot_editor/presentation/screens/bot_sub_pages/bot_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const MethodChannel _pathProviderChannel = MethodChannel(
  'plugins.flutter.io/path_provider',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;

  setUpAll(() async {
    // Comme le test du repli de l'accueil qui monte le vrai `HomePage` : la page passe par
    // la base SQLite (`AppManager`), il lui faut donc sqflite ffi et un dossier
    // `path_provider` simulé.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    documentsDir = await Directory.systemTemp.createTemp(
      'bot_stats_lifecycle_test_',
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
        // Fichiers SQLite verrouillés : sans importance pour le test.
      }
    }
  });

  setUp(() {
    // La page lit ses préférences (source du runner, hôte local mobile) : sans valeurs
    // simulées, `SharedPreferences.getInstance()` passerait par un canal absent.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Compteur statique : sans remise à zéro, un test contaminerait le suivant (et
    // masquerait un tick manquant).
    BotStatsPage.debugStatsTicks = 0;
  });

  /// Monte le VRAI écran Stats et attend que le sondage ait réellement démarré.
  Future<void> mountStatsPage(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme(),
        home: const BotStatsPage(botId: 'bot-1'),
      ),
    );
    await settle(tester);
    await waitForFirstTick(tester);
  }

  /// Démontage explicite, puis avance d'horloge : c'est ce couple qui fait échouer le test
  /// si le `dispose` de l'écran laisse un timer derrière lui (ou si un tick en vol en
  /// réarme un après coup).
  Future<void> disposeStatsPage(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));
  }

  testWidgets('au premier plan, l\'écran sonde tant que le temps avance', (
    tester,
  ) async {
    await mountStatsPage(tester);
    expect(
      BotStatsPage.debugStatsTicks,
      greaterThan(0),
      reason: 'le montage doit amorcer le sondage',
    );

    // Le sondage CONTINUE ensuite : sur une minute d'horloge simulée, plusieurs ticks. On
    // ne verrouille pas un nombre exact — la cadence s'espace quand rien ne change
    // (`PollCadence` : 3 s → 6 s → plafond 10 s) — mais la répétition est le sujet.
    final ticksApresLeDemarrage = BotStatsPage.debugStatsTicks;
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
    }
    expect(
      BotStatsPage.debugStatsTicks,
      greaterThan(ticksApresLeDemarrage + 2),
      reason: 'le timer réarmé doit enchaîner les ticks, pas s\'arrêter au premier',
    );

    await disposeStatsPage(tester);
  });

  testWidgets('l\'arrière-plan met le sondage en pause', (tester) async {
    await mountStatsPage(tester);
    final ticksAvantPause = BotStatsPage.debugStatsTicks;
    expect(ticksAvantPause, greaterThan(0));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);

    // Deux minutes d'horloge simulée en arrière-plan : le compteur ne bouge PLUS. C'est la
    // propriété de pause : le timer est annulé et la branche `else` n'en réarme aucun.
    await tester.pump(const Duration(minutes: 2));
    await settle(tester);
    expect(
      BotStatsPage.debugStatsTicks,
      ticksAvantPause,
      reason: 'aucun tick ne doit partir tant que l\'application est en arrière-plan',
    );

    await disposeStatsPage(tester);
  });

  testWidgets('la reprise relance le sondage immédiatement, puis au nominal', (
    tester,
  ) async {
    await mountStatsPage(tester);
    // On laisse d'abord la cadence s'espacer (en test, le tick suivant part au plafond de
    // 10 s) : c'est ce qui rend le réveil observable, car sans la remise au nominal le
    // prochain tick tomberait à 10 s et non à 3 s.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(seconds: 10));
      await settle(tester);
    }

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);
    final ticksEnPause = BotStatsPage.debugStatsTicks;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // 10 ms de temps simulé, très en dessous des 3 s nominales : le tick est donc compté
    // IMMÉDIATEMENT (l'incrément a lieu dans l'appel de cycle de vie lui-même).
    await tester.pump(const Duration(milliseconds: 10));
    expect(
      BotStatsPage.debugStatsTicks,
      ticksEnPause + 1,
      reason: 'le retour au premier plan doit sonder sans attendre la cadence',
    );

    // Et le sondage reprend au rythme nominal : un tick à 3 s, là où le plafond de 10 s
    // (cadence en arrière-plan) imposerait d'attendre bien plus longtemps.
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
    expect(
      BotStatsPage.debugStatsTicks,
      ticksEnPause + 2,
      reason: 'la cadence doit être revenue au nominal à la reprise',
    );

    // La CONTINUITÉ au-delà de ces deux ticks n'est pas affirmée ici : chaque tick attend
    // une lecture SQLite qui ne se résout pas toujours en temps simulé (voir l'en-tête du
    // fichier), donc un tick en vol peut retarder le suivant. C'est le premier test
    // (« au premier plan, l'écran sonde tant que le temps avance ») qui couvre la
    // répétition du sondage.

    await disposeStatsPage(tester);
  });

  testWidgets('un démontage après reprise ne laisse aucun timer orphelin', (
    tester,
  ) async {
    await mountStatsPage(tester);
    // L'écran reprend : l'écoute de cycle de vie vient de sonder, donc un timer est armé au
    // moment du démontage — c'est exactement la situation où un `dispose` incomplet
    // laisserait une minuterie pendante.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await settle(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 10));

    // Si le `dispose` n'annulait pas ce timer, ou si le tick en vol le réarmait après coup,
    // l'invariant de `flutter_test` échouerait ici avec « A Timer is still pending even
    // after the widget tree was disposed ».
    await disposeStatsPage(tester);
  });
}

/// Laisse tourner les microtâches (fin d'un tick, réarmement du timer) sans avancer d'une
/// seconde d'horloge simulée : « immédiat » ne veut pas dire « au tick suivant ».
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

/// Attend le premier tick de sondage.
///
/// L'écran n'arme son timer qu'une fois sa source de métriques résolue, et cette résolution
/// lit SQLite (`getBotRuntimeEngine`). C'est du VRAI asynchrone, que la zone simulée de
/// `flutter_test` ne fait pas avancer (`pump` n'élapse que l'horloge simulée) : d'où cette
/// fenêtre bornée de temps réel (`runAsync`), suivie d'une avance d'horloge simulée de la
/// cadence nominale pour faire partir le tick dès que le timer est armé.
Future<void> waitForFirstTick(WidgetTester tester) async {
  for (var i = 0; i < 40 && BotStatsPage.debugStatsTicks == 0; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(seconds: 3));
    await settle(tester);
  }
  expect(
    BotStatsPage.debugStatsTicks,
    greaterThan(0),
    reason: 'l\'écran doit finir par armer son premier timer de sondage',
  );
}
