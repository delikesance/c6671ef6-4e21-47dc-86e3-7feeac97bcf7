import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void seedLocalPremiumCache() {
    SubscriptionService.debugSetLocalSubscriptionForTests(
      active: true,
      productId: kMonthlySubscriptionId,
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
  }

  setUp(() async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues(const <String, Object>{});
    await SubscriptionService.debugResetForTests();
    SubscriptionService.debugSetNativeBillingSourceOfTruth(true);
    SubscriptionService.debugSetDesktopForTests(false);
    // A test that fails a request opens the client's circuit breaker for the mock
    // host, and every later test in the file is then short-circuited before its
    // request is sent (it surfaced as "premium unexpectedly true" because the
    // refresh fell back to the local cache).
    MainApiClient.resetCircuitBreakers();
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    SubscriptionService.debugSetNativeBillingSourceOfTruth(null);
    SubscriptionService.debugSetDesktopForTests(null);
    await SubscriptionService.debugResetForTests();
  });

  test('mobile premium requires server-validated local cache', () async {
    seedLocalPremiumCache();

    final isPremium = await SubscriptionService.resolveEffectivePremiumStatus(
      forceRefresh: true,
    );

    expect(isPremium, isTrue);
    expect(SubscriptionService.isSubscribed, isTrue);
  });

  test(
    'mobile ignores manager premium when local entitlement is inactive',
    () async {
      final isPremium = await SubscriptionService.resolveEffectivePremiumStatus(
        forceRefresh: true,
      );

      expect(isPremium, isFalse);
      expect(SubscriptionService.isSubscribed, isFalse);
    },
  );

  test(
    'rewarded ads can be skipped when the local store says premium',
    () async {
      seedLocalPremiumCache();

      final canSkipAds = await SubscriptionService.canSkipRewardedAds(
        forceRefresh: true,
      );

      expect(canSkipAds, isTrue);
    },
  );

  test('rewarded ads cannot be skipped from manager premium alone', () async {
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );

    final canSkipAds = await SubscriptionService.canSkipRewardedAds(
      forceRefresh: true,
    );

    expect(canSkipAds, isFalse);
  });

  test(
    'rewarded ads ignore stored manager session when authoritative manager access is disabled',
    () async {
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
          userId: 'premium-user',
        ),
      );

      final canSkipAds = await SubscriptionService.canSkipRewardedAds(
        forceRefresh: true,
        allowStoredManagerSession: false,
      );

      expect(canSkipAds, isFalse);
    },
  );

  test('mobile clears local premium when manager runtime says free', () async {
    seedLocalPremiumCache();
    await MainApiSettingsStore.saveConfig(
      const MainApiConfig(baseUrl: 'https://api.example.com'),
    );
    await MainApiSettingsStore.saveSession(
      MainApiSession(
        accessToken: 'token',
        expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      ),
    );

    final client = MainApiClient(
      baseUrl: 'https://api.example.com',
      accessToken: 'token',
      httpClient: MockClient((request) async {
        if (request.url.path.endsWith('/gateway/runtime')) {
          return http.Response('{"plan":"FREE"}', 200);
        }
        return http.Response('not found', 404);
      }),
    );

    final isPremium = await SubscriptionService.refreshPremiumFromServer(
      client: client,
      forceRefresh: true,
    );

    expect(isPremium, isFalse);
    expect(SubscriptionService.isSubscribed, isFalse);
  });

  test(
    'mobile keeps local premium when manager session is unavailable',
    () async {
      seedLocalPremiumCache();

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        forceRefresh: true,
      );

      expect(isPremium, isTrue);
      expect(SubscriptionService.isSubscribed, isTrue);
    },
  );

  test(
    'mobile keeps local premium on transient network error during server refresh',
    () async {
      seedLocalPremiumCache();
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          throw const SocketException('Failed host lookup: api.example.com');
        }),
      );

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        client: client,
        forceRefresh: true,
      );

      expect(isPremium, isTrue);
      expect(SubscriptionService.isSubscribed, isTrue);
    },
  );

  test(
    'mobile keeps local premium when circuit breaker is open during server refresh',
    () async {
      seedLocalPremiumCache();
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      final failingClient = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          throw const SocketException('Failed host lookup: api.example.com');
        }),
      );
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          await failingClient.getGatewayRuntime();
        } catch (_) {}
      }

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        client: failingClient,
        forceRefresh: true,
      );

      expect(isPremium, isTrue);
      expect(SubscriptionService.isSubscribed, isTrue);
    },
  );

  test(
    'a store-confirmed purchase survives a manager that says free',
    () async {
      seedLocalPremiumCache();
      // The store still bills this account: the receipt replays and the manager
      // verifies it, so the "free" answer was stale, not the truth.
      SubscriptionService.debugStoreReverifyOverride = () async => true;
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/gateway/runtime')) {
            return http.Response('{"plan":"FREE"}', 200);
          }
          return http.Response('not found', 404);
        }),
      );

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        client: client,
        forceRefresh: true,
      );

      expect(
        isPremium,
        isTrue,
        reason:
            'a paying customer must not be thrown back to FREE because the '
            'manager had not seen the purchase yet',
      );
      expect(SubscriptionService.isSubscribed, isTrue);
    },
  );

  test(
    'an unconfirmed purchase is still cleared when the store stays silent',
    () async {
      seedLocalPremiumCache();
      SubscriptionService.debugStoreReverifyOverride = () async => false;
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/gateway/runtime')) {
            return http.Response('{"plan":"FREE"}', 200);
          }
          return http.Response('not found', 404);
        }),
      );

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        client: client,
        forceRefresh: true,
      );

      expect(isPremium, isFalse);
      expect(SubscriptionService.isSubscribed, isFalse);
    },
  );

  test(
    'a manager-granted plan replays the store when the device lost its proof',
    () async {
      // No cached local state at all: the account whose cache was wiped by an older
      // build on a stale "free" answer, while the manager still grants premium.
      var reverifyCalls = 0;
      SubscriptionService.debugStoreReverifyOverride = () async {
        reverifyCalls++;
        return false;
      };
      await MainApiSettingsStore.saveConfig(
        const MainApiConfig(baseUrl: 'https://api.example.com'),
      );
      await MainApiSettingsStore.saveSession(
        MainApiSession(
          accessToken: 'token',
          expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
        ),
      );

      final client = MainApiClient(
        baseUrl: 'https://api.example.com',
        accessToken: 'token',
        httpClient: MockClient((request) async {
          if (request.url.path.endsWith('/gateway/runtime')) {
            return http.Response('{"plan":"PREMIUM"}', 200);
          }
          return http.Response('not found', 404);
        }),
      );

      final isPremium = await SubscriptionService.refreshPremiumFromServer(
        client: client,
        forceRefresh: true,
      );

      expect(isPremium, isTrue);
      expect(
        reverifyCalls,
        1,
        reason:
            'the store must be replayed so the device rebuilds the proof it lost, '
            'otherwise a paying customer stays on "Not subscribed"',
      );
    },
  );

  test('monthly subscriptions estimate one calendar month from start', () {
    final expiresAt =
        SubscriptionService.debugEstimateSubscriptionExpiryForTests(
          productId: kMonthlySubscriptionId,
          startedAt: DateTime.utc(2026, 1, 31, 12),
        );

    expect(expiresAt, DateTime.utc(2026, 2, 28, 12));
  });

  test('annual subscriptions estimate one calendar year from start', () {
    final expiresAt =
        SubscriptionService.debugEstimateSubscriptionExpiryForTests(
          productId: kAnnualSubscriptionId,
          startedAt: DateTime.utc(2024, 2, 29, 8, 30),
        );

    expect(expiresAt, DateTime.utc(2025, 2, 28, 8, 30));
  });

  // Issue e65c3fc0: the annual subscription failed to launch on Play with
  // "INVALID_OFFER_TOKEN: Offer token null for product bot_creator_premium_annual
  // is not valid".
  group('Play purchase candidate selection', () {
    GooglePlayProductDetails inAppEntry(String id) {
      return GooglePlayProductDetails.fromProductDetails(
        ProductDetailsWrapper(
          description: id,
          name: id,
          productId: id,
          productType: ProductType.inapp,
          title: id,
          oneTimePurchaseOfferDetails: const OneTimePurchaseOfferDetailsWrapper(
            formattedPrice: '€59,99',
            priceAmountMicros: 59990000,
            priceCurrencyCode: 'EUR',
          ),
        ),
      ).single;
    }

    GooglePlayProductDetails subscriptionEntry(String id, String offerToken) {
      return GooglePlayProductDetails.fromProductDetails(
        ProductDetailsWrapper(
          description: id,
          name: id,
          productId: id,
          productType: ProductType.subs,
          title: id,
          subscriptionOfferDetails: <SubscriptionOfferDetailsWrapper>[
            SubscriptionOfferDetailsWrapper(
              basePlanId: 'annual',
              offerIdToken: offerToken,
              offerTags: const <String>[],
              pricingPhases: const <PricingPhaseWrapper>[
                PricingPhaseWrapper(
                  billingCycleCount: 0,
                  billingPeriod: 'P1Y',
                  formattedPrice: '€59,99',
                  priceAmountMicros: 59990000,
                  priceCurrencyCode: 'EUR',
                  recurrenceMode: RecurrenceMode.infiniteRecurring,
                ),
              ],
            ),
          ],
        ),
      ).single;
    }

    test('an entry built from the in-app query carries no offer token', () {
      expect(
        SubscriptionService.subscriptionOfferToken(
          inAppEntry(kAnnualSubscriptionId),
        ),
        isNull,
      );
      expect(
        SubscriptionService.subscriptionOfferToken(
          subscriptionEntry(kAnnualSubscriptionId, 'offer-annual'),
        ),
        'offer-annual',
      );
    });

    test('the purchasable entry wins over an earlier unusable one', () {
      // in_app_purchase_android asks Play for each id twice — once as an in-app
      // product, once as a subscription — and concatenates both answers, so the
      // first match for a subscription id can carry no offer token at all.
      final catalog = <ProductDetails>[
        inAppEntry(kAnnualSubscriptionId),
        subscriptionEntry(kAnnualSubscriptionId, 'offer-annual'),
      ];

      final selected = SubscriptionService.selectPurchaseCandidate(
        catalog,
        kAnnualSubscriptionId,
      );

      expect(selected, isNotNull);
      expect(selected!.id, kAnnualSubscriptionId);
      expect(
        SubscriptionService.subscriptionOfferToken(selected),
        'offer-annual',
      );
    });

    test('the first match is kept when nothing is purchasable', () {
      final catalog = <ProductDetails>[inAppEntry(kAnnualSubscriptionId)];

      expect(
        SubscriptionService.selectPurchaseCandidate(
          catalog,
          kAnnualSubscriptionId,
        ),
        same(catalog.single),
      );
    });

    test('an unknown product selects nothing', () {
      final catalog = <ProductDetails>[inAppEntry(kMonthlySubscriptionId)];

      expect(
        SubscriptionService.selectPurchaseCandidate(
          catalog,
          kAnnualSubscriptionId,
        ),
        isNull,
      );
    });
  });
}
