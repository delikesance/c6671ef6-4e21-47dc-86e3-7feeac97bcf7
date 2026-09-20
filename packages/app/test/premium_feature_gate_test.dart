// La règle produit « où le bot s'exécute décide du cadrage premium » est écrite UNE
// fois (`premium_feature_gate.dart`) : ce test la verrouille par table, et surtout il
// verrouille ce qu'elle NE débloque PAS.
//
// Origine : sur un poste de travail, l'app affichait « 🔒 Disponible avec Bot Creator
// PREMIUM » sur des fonctions qui s'exécutent chez l'utilisateur (musique, planificateur,
// statistiques, rejeu de débogueur). Le propriétaire du produit a tranché : « quasiment
// toutes les features premium sont activées sur Desktop, excepté le Running côté
// serveur ». Le verrou était posé par PLATEFORME alors que la cause est l'ENDROIT
// D'EXÉCUTION — un bot parti sur Bot Creator Server reste donc cadré par la formule,
// même depuis un poste de travail.

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RunnerSettings.resetAssociationsForTests();
    PremiumCapabilities.debugPremiumBypass = false;
    SubscriptionService.debugSetDesktopForTests(true);
    // Formule CONNUE et gratuite : sans elle, un poste de travail hors ligne se déclare
    // premium (repli assumé) et les tests passeraient pour la mauvaise raison.
    await SubscriptionService.applyPushedAccountState(
      const <String, dynamic>{'plan': 'FREE'},
    );
  });

  tearDown(() {
    PremiumCapabilities.debugPremiumBypass = false;
    SubscriptionService.debugSetDesktopForTests(null);
    RunnerSettings.resetAssociationsForTests();
  });

  group('décision pure', () {
    test('la formule suffit toujours, quel que soit l’endroit d’exécution', () {
      expect(
        premiumFeatureAvailable(
          runsOnThisDevice: false,
          supportsDesktopLocalRun: false,
          subscribed: true,
        ),
        isTrue,
      );
    });

    test('poste de travail + bot exécuté ici → disponible sans abonnement', () {
      expect(
        premiumFeatureAvailable(
          runsOnThisDevice: true,
          supportsDesktopLocalRun: true,
          subscribed: false,
        ),
        isTrue,
      );
    });

    test('poste de travail + bot sur Bot Creator Server → cadré par la formule', () {
      expect(
        premiumFeatureAvailable(
          runsOnThisDevice: false,
          supportsDesktopLocalRun: true,
          subscribed: false,
        ),
        isFalse,
      );
    });

    test('mobile → comportement inchangé (formule exigée)', () {
      expect(
        premiumFeatureAvailable(
          runsOnThisDevice: true,
          supportsDesktopLocalRun: false,
          subscribed: false,
        ),
        isFalse,
      );
    });
  });

  group('où tourne le bot', () {
    test('aucune association → cet appareil (le runner embarqué est le défaut)', () {
      expect(botRunsOnThisDevice('bot-jamais-demarre'), isTrue);
    });

    test('démarrage local explicite → cet appareil', () {
      RunnerSettings.associateBotWithRunner('bot-local', kLocalRunAssociation);

      expect(botRunsOnThisDevice('bot-local'), isTrue);
    });

    test('bot parti sur Bot Creator Server → pas cet appareil', () {
      RunnerSettings.associateBotWithRunner('bot-heberge', kManagerRunAssociation);

      expect(botRunsOnThisDevice('bot-heberge'), isFalse);
    });

    test('identifiant vide ou absent → on n’affirme pas « local »', () {
      expect(botRunsOnThisDevice(null), isFalse);
      expect(botRunsOnThisDevice('   '), isFalse);
    });
  });

  group('point d’entrée des écrans', () {
    test('capacité exécutée par l’appareil : débloquée sur un poste, bot local', () {
      expect(
        premiumCapabilityAvailableForBot(
          PremiumCapability.schedulerTriggers,
          botId: 'bot-local',
        ),
        isTrue,
      );
    });

    test('la même capacité reste cadrée quand le bot tourne sur le serveur', () {
      RunnerSettings.associateBotWithRunner('bot-heberge', kManagerRunAssociation);

      expect(
        premiumCapabilityAvailableForBot(
          PremiumCapability.schedulerTriggers,
          botId: 'bot-heberge',
        ),
        isFalse,
      );
    });

    test('hors poste de travail, rien n’est débloqué par l’exécution locale', () {
      SubscriptionService.debugSetDesktopForTests(false);

      expect(
        premiumCapabilityAvailableForBot(
          PremiumCapability.schedulerTriggers,
          botId: 'bot-local',
        ),
        isFalse,
      );
    });

    // Le point le plus important de ce fichier : la règle ne doit RIEN ouvrir dont
    // l'exécution dépend du serveur. La liste est fermée par construction, et ce test
    // échouera si quelqu'un y ajoute un jour une capacité serveur.
    test('liste FERMÉE : webhooks entrants et hébergement cloud restent cadrés', () {
      expect(
        premiumCapabilityAvailableForBot(
          PremiumCapability.inboundWebhooks,
          botId: 'bot-local',
        ),
        isFalse,
        reason: 'un bot local n’a pas d’adresse publique : rien ne peut y entrer',
      );
      expect(
        premiumCapabilityAvailableForBot(
          PremiumCapability.hostedApps,
          botId: 'bot-local',
        ),
        isFalse,
        reason: 'l’hébergement est le « excepté le Running côté serveur »',
      );
      expect(kDeviceExecutedCapabilities, isNot(contains(PremiumCapability.inboundWebhooks)));
      expect(kDeviceExecutedCapabilities, isNot(contains(PremiumCapability.hostedApps)));
    });

    test('les quatre capacités exécutées par l’appareil sont bien déclarées', () {
      expect(kDeviceExecutedCapabilities, <PremiumCapability>{
        PremiumCapability.lavalinkAudio,
        PremiumCapability.schedulerTriggers,
        PremiumCapability.analyticsExpanded,
        PremiumCapability.visualDebuggerReplay,
      });
    });
  });

  // Un écran ouvert dont le plafond local reste à 0 est pire qu'un cadenas : le bouton
  // « Ajouter » est là, et chaque création est refusée. Le plafond suit donc la même
  // règle que l'accès (voir `database.saveScheduledTrigger`).
  group('plafond local', () {
    test('le plafond de la formule payante reste accessible sans abonnement', () {
      expect(
        PremiumCapabilities.premiumLimitFor(PremiumCapability.schedulerTriggers),
        10,
        reason: 'le chiffre produit vit à un seul endroit',
      );
      expect(
        PremiumCapabilities.limitFor(PremiumCapability.schedulerTriggers),
        0,
        reason: 'la formule du compte, elle, ne change pas : un compte gratuit reste à 0',
      );
      expect(
        PremiumCapabilities.limitFor(PremiumCapability.hostedApps),
        1,
        reason: 'l’hébergement garde son plafond gratuit, il n’est pas débloqué',
      );
    });
  });
}
