import 'dart:io';

import 'package:bot_creator/features/subscriptions/logic/hosted_app_billing_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:url_launcher/url_launcher.dart';

const String kAndroidPackageName = 'fr.botcreator.app';

enum SubscriptionProductKind {
  botPremium,
  hostedApp,
}

/// Opens the platform subscription management page (cancel / change billing).
Future<bool> openSubscriptionManagement({
  required SubscriptionProductKind kind,
  String? storeProductId,
}) async {
  final uri = subscriptionManagementUri(
    kind: kind,
    storeProductId: storeProductId,
  );
  if (uri == null) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Uri? subscriptionManagementUri({
  required SubscriptionProductKind kind,
  String? storeProductId,
}) {
  if (Platform.isIOS) {
    return Uri.parse('https://apps.apple.com/account/subscriptions');
  }
  if (Platform.isAndroid) {
    final sku = switch (kind) {
      SubscriptionProductKind.botPremium =>
        storeProductId?.trim().isNotEmpty == true
            ? storeProductId!.trim()
            : kMonthlySubscriptionId,
      SubscriptionProductKind.hostedApp => kGooglePlayHostedAppSubscriptionId,
    };
    return Uri.parse(
      'https://play.google.com/store/account/subscriptions'
      '?package=$kAndroidPackageName&sku=${Uri.encodeComponent(sku)}',
    );
  }
  return null;
}
