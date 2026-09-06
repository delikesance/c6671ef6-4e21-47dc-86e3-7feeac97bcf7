import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('subscriptionPurchaseErrorKey', () {
    test('returns store unavailable key', () {
      expect(
        subscriptionPurchaseErrorKey(
          SubscriptionPurchaseFailureReason.storeUnavailable,
        ),
        'subscription_error_store_unavailable',
      );
    });

    test('returns product unavailable key', () {
      expect(
        subscriptionPurchaseErrorKey(
          SubscriptionPurchaseFailureReason.productUnavailable,
        ),
        'subscription_error_product_unavailable',
      );
    });

    test('returns purchase start failed key', () {
      expect(
        subscriptionPurchaseErrorKey(
          SubscriptionPurchaseFailureReason.purchaseStartFailed,
        ),
        'subscription_error_purchase_start_failed',
      );
    });

    test('returns generic key when reason is null', () {
      expect(subscriptionPurchaseErrorKey(null), 'subscription_error');
    });
  });

  group('calculateAnnualSavingsPercent', () {
    test(
      'calculates correct savings for 59.99 annual and 5.99 monthly (~17%)',
      () {
        final savings = SubscriptionService.calculateAnnualSavingsPercent(
          annualPrice: 59.99,
          monthlyPrice: 5.99,
        );
        expect(savings, equals(17));
      },
    );

    test('returns null when savings are below 10% threshold', () {
      // 12 * 5.99 = 71.88, annual 68.00 -> ~5.4% savings
      final savings = SubscriptionService.calculateAnnualSavingsPercent(
        annualPrice: 68.0,
        monthlyPrice: 5.99,
        minThresholdPercent: 10,
      );
      expect(savings, isNull);
    });

    test(
      'returns null when annual price is higher than 12 monthly payments',
      () {
        final savings = SubscriptionService.calculateAnnualSavingsPercent(
          annualPrice: 80.0,
          monthlyPrice: 5.99,
        );
        expect(savings, isNull);
      },
    );

    test('returns null when prices are missing or invalid', () {
      expect(
        SubscriptionService.calculateAnnualSavingsPercent(
          annualPrice: null,
          monthlyPrice: 5.99,
        ),
        isNull,
      );
      expect(
        SubscriptionService.calculateAnnualSavingsPercent(
          annualPrice: 59.99,
          monthlyPrice: null,
        ),
        isNull,
      );
      expect(
        SubscriptionService.calculateAnnualSavingsPercent(
          annualPrice: 59.99,
          monthlyPrice: 0.0,
        ),
        isNull,
      );
    });

    test('returns exact percentage when at or above threshold', () {
      // 12 * 10 = 120, annual = 90 -> 25% savings
      final savings = SubscriptionService.calculateAnnualSavingsPercent(
        annualPrice: 90.0,
        monthlyPrice: 10.0,
      );
      expect(savings, equals(25));
    });
  });
}
