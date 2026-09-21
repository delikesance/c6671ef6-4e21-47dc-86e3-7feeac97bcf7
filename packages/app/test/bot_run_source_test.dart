// L'interface doit dire QUI exécute le bot, et ne jamais afficher d'échéance
// d'hébergement pour un bot que le poste exécute lui-même.
//
// Bug d'origine (mesuré sur la machine de l'auteur) : bot associé `local`, stoppé côté
// serveur (`desired_state=STOPPED`), et la carte annonçait pourtant « Serveurs Bot
// Creator » avec une échéance en 2038 — calculée depuis le SOLDE de 5 997 142 minutes.
// Un stock n'est pas une échéance, et un bot local ne consomme pas le solde cloud.
//
// Les trois cas verrouillés ici sont ceux dictés par le propriétaire du produit :
//   A. ce poste   -> « Ce poste », aucune ligne d'expiration ;
//   B. serveur    -> « Serveurs Bot Creator » + l'échéance réelle ;
//   C. arrêté     -> état inactif, aucune échéance trompeuse.
// Le mobile, lui, ne doit pas changer de comportement.

import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/home/logic/bot_run_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppLocalizations tr;

  setUpAll(() async {
    tr = await AppLocalizations.delegate.load(const Locale('fr'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RunnerSettings.resetAssociationsForTests();
  });

  tearDown(RunnerSettings.resetAssociationsForTests);

  group('CAS A — le bot tourne sur ce poste', () {
    test('association locale + serveur arrêté -> « Ce poste », sans échéance', () {
      RunnerSettings.associateBotWithRunner('bot-local', 'local');

      final origin = resolveBotRunOrigin(
        botId: 'bot-local',
        serverReportsRunning: false,
      );

      expect(origin, BotRunOrigin.thisDevice);
      expect(origin.runsOnThisDevice, isTrue);
      expect(
        origin.isHostedRemotely,
        isFalse,
        reason: 'sans hébergement distant, aucune ligne d\'expiration ne doit être rendue',
      );
      expect(botRunSourceLabel(tr, origin), tr.runner_source_this_device);
      expect(botRunSourceLabel(tr, origin), 'Ce poste');
    });

    test('bot jamais démarré : le runner embarqué est le défaut sur ce poste', () {
      final origin = resolveBotRunOrigin(
        botId: 'bot-jamais-demarre',
        serverReportsRunning: false,
      );

      expect(origin, BotRunOrigin.thisDevice);
    });
  });

  group('CAS B — le bot tourne sur les serveurs Bot Creator', () {
    test('association manager + serveur en marche -> source serveur + échéance', () {
      RunnerSettings.associateBotWithRunner('bot-heberge', 'manager');

      final origin = resolveBotRunOrigin(
        botId: 'bot-heberge',
        serverReportsRunning: true,
      );

      expect(origin, BotRunOrigin.botCreatorServers);
      expect(origin.isHostedRemotely, isTrue);
      expect(origin.runsOnThisDevice, isFalse);
      expect(botRunSourceLabel(tr, origin), tr.runner_source_manager);
      expect(botRunSourceLabel(tr, origin), 'Serveurs Bot Creator');
    });
  });

  group('CAS C — le bot n’est exécuté nulle part', () {
    test('association manager mais serveur arrêté -> arrêté, aucune échéance', () {
      RunnerSettings.associateBotWithRunner('bot-heberge', 'manager');

      final origin = resolveBotRunOrigin(
        botId: 'bot-heberge',
        serverReportsRunning: false,
      );

      expect(origin, BotRunOrigin.stopped);
      expect(origin.isHostedRemotely, isFalse);
      expect(origin.runsOnThisDevice, isFalse);
      expect(
        botRunSourceLabel(tr, origin),
        isNull,
        reason: 'un bot arrêté ne se présente pas comme hébergé : l\'écran écrit son état',
      );
    });

    test('le solde de minutes ne décide JAMAIS de la source', () {
      // Le bug venait de là : 5 997 142 minutes affichées comme une échéance alors que
      // le bot tournait sur le poste. La source vient de qui exécute, jamais du stock.
      RunnerSettings.associateBotWithRunner('bot-local', 'local');

      final origin = resolveBotRunOrigin(
        botId: 'bot-local',
        serverReportsRunning: false,
      );

      expect(origin, BotRunOrigin.thisDevice);
      expect(botRunSourceLabel(tr, origin), isNot(tr.runner_source_manager));
    });
  });

  group('hors poste de travail', () {
    test('le mobile garde son comportement : aucune décision prise ici', () {
      // Deux moitiés de la garantie, dans l'ordre :
      //  1. hors poste de travail, la fonction rend null — les écrans mobiles retombent
      //     donc sur leur logique historique, au mot près ;
      //  2. sur un poste, elle décide.
      // Le seam est forcé dans les deux sens : sans ça, `isDesktopRunPlatform` retombe
      // sur le VRAI système d'exploitation de la machine de test (Linux), et le cas
      // « mobile » passerait pour la mauvaise raison.
      RunnerSettings.associateBotWithRunner('bot-local', 'local');

      final restoreMobile = debugOverrideDesktopPlatform(false);
      expect(
        desktopBotRunOrigin(botId: 'bot-local', serverReportsRunning: false),
        isNull,
        reason: 'hors poste de travail, rien ne doit être décidé',
      );
      restoreMobile();

      final restoreDesktop = debugOverrideDesktopPlatform(true);
      addTearDown(restoreDesktop);
      expect(
        desktopBotRunOrigin(botId: 'bot-local', serverReportsRunning: false),
        BotRunOrigin.thisDevice,
      );
    });
  });
}
