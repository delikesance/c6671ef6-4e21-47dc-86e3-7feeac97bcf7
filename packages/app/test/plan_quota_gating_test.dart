// Les quotas d'une formule sont des quotas de DÉMARRAGE appliqués par le
// serveur (403). Ces tests verrouillent le miroir côté application — l'écran
// doit griser et expliquer exactement ce que le serveur refuse — ainsi que la
// lecture des données servies (runtime, éligibilité hébergée, catalogue).
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/plan_limit_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('quota de bots perso au démarrage', () {
    test('sans données serveur, on ne bloque rien en local', () {
      SubscriptionService.debugSetPlanQuotasForTests(
        fromServer: false,
        maxBots: 0,
        allowOwnBots: false,
      );

      expect(SubscriptionService.ownBotStartBlock(runningBots: 12), isNull);
    });

    test('une formule sans bots perso refuse tout démarrage', () {
      SubscriptionService.debugSetPlanQuotasForTests(
        maxBots: 0,
        allowOwnBots: false,
      );

      expect(
        SubscriptionService.ownBotStartBlock(runningBots: 0),
        PlanLimitBlock.planExcludesOwnBots,
      );
    });

    test('le quota compte les bots en marche, pas les bots configurés', () {
      SubscriptionService.debugSetPlanQuotasForTests(maxBots: 2);

      expect(SubscriptionService.ownBotStartBlock(runningBots: 0), isNull);
      expect(SubscriptionService.ownBotStartBlock(runningBots: 1), isNull);
      expect(
        SubscriptionService.ownBotStartBlock(runningBots: 2),
        PlanLimitBlock.planBotQuotaReached,
      );
    });

    test('0 = illimité, et un quota inconnu ne bloque rien', () {
      SubscriptionService.debugSetPlanQuotasForTests(maxBots: 0);
      expect(SubscriptionService.ownBotStartBlock(runningBots: 50), isNull);

      SubscriptionService.debugSetPlanQuotasForTests(maxBots: null);
      expect(SubscriptionService.ownBotStartBlock(runningBots: 50), isNull);
    });
  });

  group('quota de clé en main au démarrage', () {
    test('une formule sans clé en main bloque le déploiement', () {
      SubscriptionService.debugSetPlanQuotasForTests(
        allowTurnkey: false,
        maxTurnkeyBots: 0,
      );

      expect(
        SubscriptionService.turnkeyStartBlock(activeApps: 0),
        PlanLimitBlock.planExcludesTurnkey,
      );
    });

    test('le plafond de la formule prime sur le nombre d apps actives', () {
      SubscriptionService.debugSetPlanQuotasForTests(
        maxTurnkeyBots: 1,
        allowTurnkey: true,
      );

      expect(SubscriptionService.turnkeyStartBlock(activeApps: 0), isNull);
      expect(
        SubscriptionService.turnkeyStartBlock(activeApps: 1),
        PlanLimitBlock.planTurnkeyQuotaReached,
      );
    });
  });

  group('refus serveur (403) reconnu par l application', () {
    test('les messages servis par l API sont reconnus', () {
      expect(
        planLimitRefusalFromError(
          'MainApiClientException: this plan does not include personal bots',
        ),
        PlanLimitRefusal.excludesOwnBots,
      );
      expect(
        planLimitRefusalFromError(
          'personal bot limit reached for this plan: stop another bot or upgrade',
        ),
        PlanLimitRefusal.botQuotaReached,
      );
      expect(
        planLimitRefusalFromError('this plan does not include turnkey apps'),
        PlanLimitRefusal.excludesTurnkey,
      );
      expect(
        planLimitRefusalFromError('turnkey app limit reached for this plan'),
        PlanLimitRefusal.turnkeyQuotaReached,
      );
    });

    test('les codes seuls sont reconnus aussi', () {
      expect(
        planLimitRefusalFromError('{"code":"bot_quota_reached"}'),
        PlanLimitRefusal.botQuotaReached,
      );
      expect(
        planLimitRefusalFromError('{"code":"own_bots_not_allowed"}'),
        PlanLimitRefusal.excludesOwnBots,
      );
    });

    test('une panne ordinaire reste une panne ordinaire', () {
      expect(planLimitRefusalFromError('runner_unreachable'), isNull);
      expect(planLimitRefusalFromError('bot_free_time_required'), isNull);
    });

    test('chaque refus serveur a la même explication que le blocage local', () {
      expect(
        PlanLimitDialog.blockFromRefusal(PlanLimitRefusal.excludesOwnBots),
        PlanLimitBlock.planExcludesOwnBots,
      );
      expect(
        PlanLimitDialog.blockFromRefusal(PlanLimitRefusal.botQuotaReached),
        PlanLimitBlock.planBotQuotaReached,
      );
      expect(
        PlanLimitDialog.blockFromRefusal(PlanLimitRefusal.excludesTurnkey),
        PlanLimitBlock.planExcludesTurnkey,
      );
      expect(
        PlanLimitDialog.blockFromRefusal(PlanLimitRefusal.turnkeyQuotaReached),
        PlanLimitBlock.planTurnkeyQuotaReached,
      );
    });
  });

  group('données servies par le serveur', () {
    test('l éligibilité hébergée porte la formule, pas l achat store', () {
      final eligibility = HostedAppEligibility.fromJson(<String, dynamic>{
        'premium': true,
        'active_containers': 1,
        'can_deploy': false,
        'max_containers': 1,
        'deploy_blocked_reason': 'plan_not_included',
        'allow_turnkey': false,
        'plan_tier_code': 'OWN_ONLY',
      });

      expect(eligibility.maxContainers, 1);
      expect(eligibility.allowTurnkey, isFalse);
      expect(eligibility.isBlockedByPlan, isTrue);
      expect(eligibility.planTierCode, 'OWN_ONLY');
    });

    test('sans champ, on n interdit rien (serveur ancien)', () {
      final eligibility = HostedAppEligibility.fromJson(<String, dynamic>{
        'can_deploy': true,
      });

      expect(eligibility.allowTurnkey, isTrue);
      expect(eligibility.isBlockedByPlan, isFalse);
      expect(eligibility.planTierCode, isNull);
    });

    test('le catalogue expose les formules et la formule courante', () {
      final catalog = PlanCatalogInfo.fromJson(<String, dynamic>{
        'plans': <dynamic>[
          <String, dynamic>{
            'code': 'STARTER',
            'display_name': 'Starter',
            'max_bots': 5,
            'max_turnkey_bots': 2,
            'allow_turnkey': true,
            'allow_own_bots': true,
            'product_ids': <dynamic>['starter_monthly'],
          },
          <String, dynamic>{
            'code': 'HOSTED_APP_ONES',
            'display_name': 'Clé en main',
            'max_bots': 0,
            'max_turnkey_bots': 1,
            'allow_turnkey': true,
            'allow_own_bots': false,
            'product_ids': <dynamic>[],
          },
        ],
        'current': <String, dynamic>{'tier_code': 'FREE', 'active': false},
      });

      expect(catalog.currentTierCode, 'FREE');
      expect(catalog.plans, hasLength(2));
      expect(catalog.plans.first.isPurchasable, isTrue);
      expect(catalog.plans.first.maxBots, 5);

      // Formule sans SKU : visible, mais non achetable (accordée à la main).
      final turnkeyOnly = catalog.plans.last;
      expect(turnkeyOnly.allowOwnBots, isFalse);
      expect(turnkeyOnly.maxBots, 0);
      expect(turnkeyOnly.isPurchasable, isFalse);
    });
  });
}
