import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Canonical tier IDs stored by the manager after verification.
const String kHostOneAppSubscriptionId = 'host_one_app';
const String kHostTwoAppSubscriptionId = 'host_two_app';

/// App Store Connect product IDs (match subscription group "Hosted Application Group").
const String kAppStoreHostOneAppId = kHostOneAppSubscriptionId;
const String kAppStoreHostTwoAppId = kHostTwoAppSubscriptionId;

/// Google Play subscription + base plan IDs (match Play Console "Hosted App !").
const String kGooglePlayHostedAppSubscriptionId = 'hosted_application';
const String kGooglePlayHostOneBasePlanId = 'host-one-app';
const String kGooglePlayHostTwoBasePlanId = 'host-two-app';

enum HostedAppTier { oneApp, twoApps }

String canonicalHostedAppProductId(HostedAppTier tier) {
  switch (tier) {
    case HostedAppTier.oneApp:
      return kHostOneAppSubscriptionId;
    case HostedAppTier.twoApps:
      return kHostTwoAppSubscriptionId;
  }
}

HostedAppTier? hostedAppTierFromCanonicalProductId(String? productId) {
  switch (productId?.trim()) {
    case kHostOneAppSubscriptionId:
      return HostedAppTier.oneApp;
    case kHostTwoAppSubscriptionId:
      return HostedAppTier.twoApps;
    default:
      return null;
  }
}

Set<String> hostedAppStoreQueryProductIds() {
  if (Platform.isIOS) {
    return {kAppStoreHostOneAppId, kAppStoreHostTwoAppId};
  }
  if (Platform.isAndroid) {
    return {kGooglePlayHostedAppSubscriptionId};
  }
  return const {};
}

bool isHostedAppStorePurchase(String productId) {
  final id = productId.trim();
  if (id == kGooglePlayHostedAppSubscriptionId) {
    return true;
  }
  return id == kHostOneAppSubscriptionId || id == kHostTwoAppSubscriptionId;
}

class HostedAppStoreListing {
  const HostedAppStoreListing({
    required this.tier,
    required this.productDetails,
    this.offerToken,
  });

  final HostedAppTier tier;
  final ProductDetails productDetails;
  final String? offerToken;
}

HostedAppStoreListing? findHostedAppListing(
  List<ProductDetails> products,
  HostedAppTier tier,
) {
  if (Platform.isIOS) {
    final productId = canonicalHostedAppProductId(tier);
    for (final product in products) {
      if (product.id == productId) {
        return HostedAppStoreListing(tier: tier, productDetails: product);
      }
    }
    return null;
  }

  if (!Platform.isAndroid) {
    return null;
  }

  final basePlanId = tier == HostedAppTier.oneApp
      ? kGooglePlayHostOneBasePlanId
      : kGooglePlayHostTwoBasePlanId;

  for (final product in products) {
    if (product.id != kGooglePlayHostedAppSubscriptionId) {
      continue;
    }
    if (product is! GooglePlayProductDetails) {
      continue;
    }
    final subscriptionIndex = product.subscriptionIndex;
    final offers = product.productDetails.subscriptionOfferDetails;
    if (subscriptionIndex == null || offers == null) {
      continue;
    }
    if (offers[subscriptionIndex].basePlanId == basePlanId) {
      return HostedAppStoreListing(
        tier: tier,
        productDetails: product,
        offerToken: product.offerToken,
      );
    }
  }
  return null;
}

PurchaseParam hostedAppPurchaseParam(
  HostedAppStoreListing listing, {
  String? accountUsername,
}) {
  if (Platform.isAndroid && listing.offerToken != null) {
    return GooglePlayPurchaseParam(
      productDetails: listing.productDetails,
      offerToken: listing.offerToken,
      applicationUserName: accountUsername,
    );
  }
  return PurchaseParam(
    productDetails: listing.productDetails,
    applicationUserName: accountUsername,
  );
}

String verifyBillingProductIdForListing(HostedAppStoreListing listing) {
  if (Platform.isAndroid) {
    return kGooglePlayHostedAppSubscriptionId;
  }
  return canonicalHostedAppProductId(listing.tier);
}
