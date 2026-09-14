import 'dart:async';

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';

/// Why a purchase flow could not complete, as a closed list.
///
/// Every value is a bounded string that Firebase Analytics can aggregate and
/// group by. Raw store error codes and exceptions are never sent directly to
/// avoid unbounded parameter cardinality.
enum PurchaseFailureReason {
  /// The product entry from the store carries no Play offer token (issue e65c3fc0).
  offerTokenMissing('offer_token_missing'),

  /// The store (Play Store / App Store) is unavailable or disabled on this device.
  storeUnavailable('store_unavailable'),

  /// The requested product id was not found in the loaded store catalog.
  productUnavailable('product_unavailable'),

  /// The store rejected the launch of the purchase flow (e.g. buyNonConsumable returned false).
  purchaseStartFailed('purchase_start_failed'),

  /// The user dismissed the native store purchase sheet without completing.
  cancelled('cancelled'),

  /// The backend validation rejected the receipt / purchase token.
  verificationFailed('verification_failed'),

  /// Store communication or network error during the transaction.
  error('error'),

  /// Anything that cannot be classified into known reasons.
  unknown('unknown');

  const PurchaseFailureReason(this.wire);

  /// The string value sent to the analytics backend.
  final String wire;
}

/// The monetization funnel's events, following the app's taxonomy.
///
/// Funnel: `subscription_page_view` → `purchase_start` → `purchase_success` / `purchase_failed`.
///
/// Every event is routed through [AppAnalytics.logEvent] (Firebase on mobile,
/// PostHog on desktop).
class MonetizationFunnel {
  MonetizationFunnel._();

  /// Normalized product identifiers for the monetization funnel.
  static const String productMonthly = 'monthly';
  static const String productAnnual = 'annual';
  static const String productHostOne = 'host_one';
  static const String productHostTwo = 'host_two';

  /// Maps technical product IDs (e.g. `bot_creator_premium_annual`) to a stable,
  /// low-cardinality label for analytics console queries.
  static String normalizeProductId(String productId) {
    final lower = productId.toLowerCase();
    if (lower.contains('annual')) return productAnnual;
    if (lower.contains('monthly')) return productMonthly;
    if (lower.contains('two')) return productHostTwo;
    if (lower.contains('one')) return productHostOne;
    return lower;
  }

  /// The subscription page or paywall sheet was viewed.
  static Future<void> subscriptionPageView() =>
      AppAnalytics.logEvent(name: 'subscription_page_view');

  /// The purchase flow was initiated by the user.
  static Future<void> purchaseStart({required String product}) =>
      AppAnalytics.logEvent(
        name: 'purchase_start',
        parameters: <String, Object>{'product': normalizeProductId(product)},
      );

  /// The purchase completed and was verified by the server.
  static Future<void> purchaseSuccess({required String product}) =>
      AppAnalytics.logEvent(
        name: 'purchase_success',
        parameters: <String, Object>{'product': normalizeProductId(product)},
      );

  /// The purchase could not start or ended in an error / cancellation.
  static Future<void> purchaseFailed({
    required PurchaseFailureReason reason,
    String? product,
  }) => AppAnalytics.logEvent(
    name: 'purchase_failed',
    parameters: <String, Object>{
      'reason': reason.wire,
      if (product != null) 'product': normalizeProductId(product),
    },
  );

  /// Maps [SubscriptionPurchaseFailureReason] to [PurchaseFailureReason].
  static PurchaseFailureReason reasonFromPurchaseFailure(
    SubscriptionPurchaseFailureReason? reason,
  ) {
    return switch (reason) {
      SubscriptionPurchaseFailureReason.offerTokenMissing =>
        PurchaseFailureReason.offerTokenMissing,
      SubscriptionPurchaseFailureReason.storeUnavailable =>
        PurchaseFailureReason.storeUnavailable,
      SubscriptionPurchaseFailureReason.productUnavailable =>
        PurchaseFailureReason.productUnavailable,
      SubscriptionPurchaseFailureReason.purchaseStartFailed =>
        PurchaseFailureReason.purchaseStartFailed,
      null => PurchaseFailureReason.unknown,
    };
  }

  /// Classifies a raw error message onto [PurchaseFailureReason].
  static PurchaseFailureReason classifyError(Object? error) {
    final text = error?.toString().toLowerCase() ?? '';
    if (text.contains('offer') && text.contains('token')) {
      return PurchaseFailureReason.offerTokenMissing;
    }
    if (text.contains('cancel') || text.contains('user_canceled')) {
      return PurchaseFailureReason.cancelled;
    }
    if (text.contains('store_unavailable') ||
        text.contains('store unavailable') ||
        text.contains('billing_unavailable') ||
        text.contains('billing unavailable')) {
      return PurchaseFailureReason.storeUnavailable;
    }
    if (text.contains('item_unavailable') ||
        text.contains('item unavailable') ||
        text.contains('product_unavailable') ||
        text.contains('product unavailable')) {
      return PurchaseFailureReason.productUnavailable;
    }
    if (text.contains('verification') || text.contains('server')) {
      return PurchaseFailureReason.verificationFailed;
    }
    if (text.isNotEmpty) {
      return PurchaseFailureReason.error;
    }
    return PurchaseFailureReason.unknown;
  }
}
