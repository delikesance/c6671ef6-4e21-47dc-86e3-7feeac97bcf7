// Ce que le bot REÇOIT décide de ce qu'il s'autorise. Ces quatre drapeaux étaient figés
// sur la formule du compte : un bot exécuté sur la machine de l'utilisateur recevait donc
// « non premium », alors que rien n'y coûte au serveur. Ils suivent maintenant la même
// règle que les écrans (voir `premium_feature_gate`), et ce test la verrouille côté
// payload — pas seulement côté interface.

import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_payload_builder.dart';
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
    // premium (repli assumé) et le test ne prouverait plus la règle.
    await SubscriptionService.applyPushedAccountState(
      const <String, dynamic>{'plan': 'FREE'},
    );
  });

  tearDown(() {
    PremiumCapabilities.debugPremiumBypass = false;
    SubscriptionService.debugSetDesktopForTests(null);
    RunnerSettings.resetAssociationsForTests();
  });

  test('poste de travail + bot exécuté ici → le bot s’autorise ce qui tourne chez lui', () {
    final flags = premiumFlagsForBot('bot-local');

    expect(flags.isPremium, isTrue);
    expect(flags.autoSharding, isTrue);
    expect(flags.autoRestart, isTrue);
    expect(
      flags.inboundWebhooks,
      isFalse,
      reason: 'il faut une adresse publique fournie par Bot Creator : un bot local n’en a pas',
    );
  });

  test('bot hébergé sur Bot Creator Server → rien n’est débloqué par la machine', () {
    RunnerSettings.associateBotWithRunner('bot-heberge', kManagerRunAssociation);

    final flags = premiumFlagsForBot('bot-heberge');

    expect(flags.isPremium, isFalse);
    expect(flags.autoSharding, isFalse);
    expect(flags.autoRestart, isFalse);
    expect(flags.inboundWebhooks, isFalse);
  });

  test('mobile → formule exigée, comportement inchangé', () {
    SubscriptionService.debugSetDesktopForTests(false);

    final flags = premiumFlagsForBot('bot-mobile');

    expect(flags.isPremium, isFalse);
    expect(flags.autoSharding, isFalse);
    expect(flags.autoRestart, isFalse);
  });

  test('formule payante → tout est ouvert, partout', () async {
    PremiumCapabilities.debugPremiumBypass = true;

    final flags = premiumFlagsForBot('bot-heberge');

    expect(flags.isPremium, isTrue);
    expect(flags.autoSharding, isTrue);
    expect(flags.autoRestart, isTrue);
    expect(flags.inboundWebhooks, isTrue);
  });

  test('un bot jamais démarré part de cet appareil : le runner embarqué est le défaut', () {
    expect(botRunsOnThisDevice('bot-jamais-demarre'), isTrue);

    final flags = premiumFlagsForBot('bot-jamais-demarre');

    expect(flags.isPremium, isTrue);
  });
}
