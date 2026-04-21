import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });

  tearDown(() async {
    debugDefaultTargetPlatformOverride = null;
    SubscriptionService.debugSetNativeBillingSourceOfTruth(null);
    await SubscriptionService.debugResetForTests();
  });

  test('mobile premium comes from the local store cache only', () async {
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
}
