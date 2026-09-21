// Politique de relance — test PUR avec HORLOGE INJECTÉE (aucun `sleep`,
// aucune plateforme, aucun pref).
//
// Deux comportements sont verrouillés ici :
//   1. une seule vérification par 24 h (sinon : un appel store à chaque
//      ouverture, et du réseau consommé pour rien) ;
//   2. un seul dialogue par version disponible (sinon : la même boîte
//      réapparaît à chaque lancement jusqu'à la mise à jour, ce qui est le
//      meilleur moyen de faire désinstaller une app).
import 'package:flutter_test/flutter_test.dart';

import 'package:bot_creator/features/app_update/logic/app_update_models.dart';

void main() {
  final reference = DateTime(2026, 9, 20, 10, 0, 0);

  AppUpdateCheckPolicy policyAt(DateTime now) =>
      AppUpdateCheckPolicy(clock: () => now);

  group('intervalle de vérification', () {
    test('la constante produit est bien 24 h', () {
      expect(kAppUpdateCheckInterval, const Duration(hours: 24));
      expect(AppUpdateCheckPolicy().interval, kAppUpdateCheckInterval);
    });

    test('première ouverture (aucun horodatage) → vérification due', () {
      expect(
        policyAt(reference).isCheckDue(lastCheckAt: null),
        isTrue,
      );
    });

    test('moins de 24 h depuis la dernière tentative → pas de vérification',
        () {
      final policy = policyAt(reference);
      expect(
        policy.isCheckDue(
          lastCheckAt: reference.subtract(const Duration(hours: 1)),
        ),
        isFalse,
      );
      expect(
        policy.isCheckDue(
          lastCheckAt: reference.subtract(const Duration(hours: 23, minutes: 59)),
        ),
        isFalse,
      );
    });

    test('exactement 24 h puis au-delà → vérification due', () {
      final policy = policyAt(reference);
      expect(
        policy.isCheckDue(lastCheckAt: reference.subtract(kAppUpdateCheckInterval)),
        isTrue,
      );
      expect(
        policy.isCheckDue(
          lastCheckAt: reference.subtract(const Duration(hours: 25)),
        ),
        isTrue,
      );
      expect(
        policy.isCheckDue(
          lastCheckAt: reference.subtract(const Duration(days: 30)),
        ),
        isTrue,
      );
    });

    test('horloge qui recule → pas de vérification (rien à corriger)', () {
      final policy = policyAt(reference);
      expect(
        policy.isCheckDue(
          lastCheckAt: reference.add(const Duration(hours: 3)),
        ),
        isFalse,
        reason: 'Un horodatage dans le futur (réglage manuel, restauration '
            'de sauvegarde) ne doit pas déclencher d\'appel store surprise.',
      );
      expect(
        policy.isCheckDue(lastCheckAt: reference),
        isFalse,
        reason: 'Même instant = déjà vérifié.',
      );
    });

    test('variante déterministe isCheckDueAt', () {
      final policy = policyAt(DateTime(2000, 1, 1));
      expect(
        policy.isCheckDueAt(now: reference, lastCheckAt: null),
        isTrue,
        reason: 'La variante explicite n\'utilise pas l\'horloge injectée.',
      );
      expect(
        policy.isCheckDueAt(
          now: reference,
          lastCheckAt: reference.subtract(const Duration(hours: 12)),
        ),
        isFalse,
      );
    });

    test('NON-VACUITÉ : sans la politique, toute ouverture appellerait le '
        'store', () {
      // 10 lancements dans l'heure qui suit : une seule vérification passe.
      final policy = policyAt(reference);
      var checks = 0;
      DateTime? lastCheck;
      for (var launch = 0; launch < 10; launch++) {
        final now = reference.add(Duration(minutes: 3 * launch));
        final localPolicy = AppUpdateCheckPolicy(clock: () => now);
        if (localPolicy.isCheckDue(lastCheckAt: lastCheck)) {
          checks++;
          lastCheck = now;
        }
      }
      expect(checks, 1);
      // Une politique qui répondrait toujours `true` ferait 10 appels.
      expect(policy.isCheckDue(lastCheckAt: reference.subtract(const Duration(hours: 23))), isFalse);
    });
  });

  group('une seule proposition par version', () {
    test('jamais proposée → proposition', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(comparisonKey: 'ios:2.2.0', lastPromptedKey: null),
        isTrue,
      );
    });

    test('même version déjà proposée → plus de dialogue', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(
          comparisonKey: 'ios:2.2.0',
          lastPromptedKey: 'ios:2.2.0',
        ),
        isFalse,
      );
    });

    test('version suivante (2.2.1 après 2.2.0) → nouveau dialogue', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(
          comparisonKey: 'ios:2.2.1',
          lastPromptedKey: 'ios:2.2.0',
        ),
        isTrue,
      );
      expect(
        policy.shouldPrompt(
          comparisonKey: 'play:95',
          lastPromptedKey: 'play:94',
        ),
        isTrue,
      );
    });

    test('clé absente ou vide → aucune proposition (sinon relance infinie)', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(comparisonKey: null, lastPromptedKey: null),
        isFalse,
      );
      expect(
        policy.shouldPrompt(comparisonKey: '', lastPromptedKey: null),
        isFalse,
      );
      expect(
        policy.shouldPrompt(comparisonKey: '   ', lastPromptedKey: null),
        isFalse,
      );
    });

    test('espaces normalisés : « 2.2.0 » et «  2.2.0  » = même version', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(
          comparisonKey: '  2.2.0  ',
          lastPromptedKey: '2.2.0',
        ),
        isFalse,
      );
    });

    test('la source fait partie de la clé : même version, autre source → '
        'proposition', () {
      final policy = policyAt(reference);
      expect(
        policy.shouldPrompt(
          comparisonKey: 'play:94',
          lastPromptedKey: 'ios:2.2.0',
        ),
        isTrue,
      );
    });

    test('NON-VACUITÉ : sans la déduplication, 5 lancements = 5 dialogues',
        () {
      const versionKey = 'ios:2.2.0';
      String? prompted;
      var dialogs = 0;
      for (var launch = 0; launch < 5; launch++) {
        if (policyAt(reference).shouldPrompt(
          comparisonKey: versionKey,
          lastPromptedKey: prompted,
        )) {
          dialogs++;
          prompted = versionKey; // ce que le service persiste
        }
      }
      expect(dialogs, 1);
    });
  });
}
