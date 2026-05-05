import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
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
}
