import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le canal temps réel remplace `/gateway/runtime` : il doit porter exactement la même
/// information, sans jamais casser un client plus ancien.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SubscriptionService.debugSetDesktopForTests(false);
    SubscriptionService.debugSetLocalSubscriptionForTests(active: false);
  });

  group('analyse des événements', () {
    test('un événement de compte est analysé', () {
      final event = GatewayBotEvent.fromJson({
        'type': 'account.updated',
        'owner_id': 'owner-1',
        'account': {
          'plan': 'PREMIUM',
          'tier_code': 'PRO',
          'display_name': 'Pro',
          'max_bots': 5,
          'max_turnkey_bots': 2,
          'allow_own_bots': false,
          'allow_turnkey': true,
          'provider': 'apple_in_app',
          'expires_at': '2030-01-01T00:00:00Z',
        },
      });

      expect(event.type, GatewayBotEventType.accountUpdated);
      final account = event.account;
      expect(account, isNotNull);
      expect(account!.plan, 'PREMIUM');
      expect(account.tierCode, 'PRO');
      expect(account.displayName, 'Pro');
      expect(account.maxBots, 5);
      expect(account.maxTurnkeyBots, 2);
      expect(account.allowOwnBots, isFalse);
      expect(account.allowTurnkey, isTrue);
      expect(account.provider, 'apple_in_app');
      expect(account.expiresAt, DateTime.utc(2030, 1, 1));
    });

    test('un événement de conteneur est analysé', () {
      final event = GatewayBotEvent.fromJson({
        'type': 'container.updated',
        'owner_id': 'owner-1',
        'container': {
          'container_id': 'container-1',
          'state': 'RUNNING',
          'health_status': 'healthy',
          'expires_at': '2030-01-01T00:00:00Z',
        },
      });

      expect(event.type, GatewayBotEventType.containerUpdated);
      expect(event.container?.containerId, 'container-1');
      expect(event.container?.state, 'RUNNING');
      expect(event.container?.healthStatus, 'healthy');
      expect(event.container?.expiresAt, DateTime.utc(2030, 1, 1));
    });

    test('un ancien instantané reste lisible (rétro-compatibilité)', () {
      // Charge utile d'un serveur d'avant les événements de compte : aucune clé
      // nouvelle, aucun champ à null dans le JSON d'origine.
      final event = GatewayBotEvent.fromJson({
        'type': 'snapshot',
        'owner_id': 'owner-1',
        'bots': [
          {
            'bot_id': 'bot-1',
            'bot_name': 'Bot',
            'desired_state': 'RUNNING',
            'last_runtime_state': 'running',
            'free_minutes_balance': 42,
          },
        ],
      });

      expect(event.type, GatewayBotEventType.snapshot);
      expect(event.bots, hasLength(1));
      expect(event.bots.first.botId, 'bot-1');
      expect(event.bots.first.freeMinutesBalance, 42);
      expect(event.account, isNull);
      expect(event.container, isNull);
    });

    test('un type inconnu est ignoré au lieu de faire échouer la lecture', () {
      final event = GatewayBotEvent.fromJson({
        'type': 'some.future.event',
        'owner_id': 'owner-1',
      });

      expect(event.type, GatewayBotEventType.unknown);
    });

    test('la projection vers la forme HTTP garde les mêmes clés', () {
      const account = GatewayAccountEventPayload(
        plan: 'PREMIUM',
        tierCode: 'STARTER',
        displayName: 'Starter',
        maxBots: 2,
        maxTurnkeyBots: 1,
        allowOwnBots: false,
        allowTurnkey: true,
        provider: 'google_play',
      );

      final runtime = account.toRuntimeMap();
      expect(runtime['plan'], 'PREMIUM');
      expect(runtime['tier_code'], 'STARTER');
      expect(runtime['display_name'], 'Starter');
      expect(runtime['max_bots'], 2);
      expect(runtime['max_turnkey_bots'], 1);
      expect(runtime['allow_own_bots'], isFalse);
      expect(runtime['allow_turnkey'], isTrue);
      expect(runtime['provider'], 'google_play');
      expect(runtime.containsKey('expires_at'), isTrue);
    });
  });

  group('application de l\'état poussé', () {
    test('une formule premium poussée débloque le premium sans HTTP', () async {
      await SubscriptionService.applyPushedAccountState(
        const GatewayAccountEventPayload(
          plan: 'PREMIUM',
          tierCode: 'PRO',
          displayName: 'Pro',
          maxBots: 5,
          maxTurnkeyBots: 2,
          allowOwnBots: false,
          allowTurnkey: true,
          provider: 'apple_in_app',
        ).toRuntimeMap(),
      );

      expect(SubscriptionService.isSubscribed, isTrue);
      expect(SubscriptionService.activePlanDisplayName, 'Pro');
      expect(SubscriptionService.activePlanTierCode, 'PRO');
      expect(SubscriptionService.activePlanMaxTurnkeyBots, 2);
      expect(SubscriptionService.activePlanAllowOwnBots, isFalse);
    });

    test('un retour en FREE poussé applique les quotas de la formule FREE', () async {
      await SubscriptionService.applyPushedAccountState(
        const GatewayAccountEventPayload(
          plan: 'PREMIUM',
          tierCode: 'PRO',
          maxTurnkeyBots: 2,
        ).toRuntimeMap(),
      );
      expect(SubscriptionService.isSubscribed, isTrue);

      await SubscriptionService.applyPushedAccountState(
        const GatewayAccountEventPayload(
          plan: 'FREE',
          maxBots: 1,
          maxTurnkeyBots: 0,
        ).toRuntimeMap(),
      );

      expect(SubscriptionService.isSubscribed, isFalse);
      expect(SubscriptionService.activePlanMaxBots, 1);
      expect(SubscriptionService.activePlanMaxTurnkeyBots, 0);
      expect(SubscriptionService.activePlanAllowOwnBots, isTrue);
    });
  });
}
