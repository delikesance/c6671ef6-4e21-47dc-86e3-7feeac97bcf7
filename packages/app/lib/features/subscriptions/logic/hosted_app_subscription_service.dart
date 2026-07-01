import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_billing_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/shared_purchase_stream.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-app purchases for hosted Docker containers (separate from bot Premium).
class HostedAppSubscriptionService {
  HostedAppSubscriptionService._();

  static const String _activeKey = 'hosted_app_subscription_active';
  static const String _serverValidatedKey =
      'hosted_app_subscription_server_validated';
  static const String _productIdKey = 'hosted_app_subscription_product_id';
  static const String _expiresAtKey = 'hosted_app_subscription_expires_at';
  static const Duration _serverSyncTtl = Duration(minutes: 15);

  static bool _initialized = false;
  static bool _isSubscribed = false;
  static bool _serverValidated = false;
  static String? _activeProductId;
  static DateTime? _subscriptionExpiresAt;
  static DateTime? _lastServerSyncAt;
  static Timer? _expiryTimer;
  static bool _purchaseHandlerRegistered = false;
  static SharedPreferences? _prefs;

  static List<ProductDetails> products = [];
  static bool _storeAvailable = false;
  static HostedAppTier? _pendingTier;

  static bool get isSubscribed => _isLocalSubscriptionActive();

  static String? get activeProductId => _activeProductId;

  static bool get canUpgradeToTwoApps =>
      isSubscribed && activeProductId == kHostOneAppSubscriptionId;

  static DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;

  static bool get canShowPurchaseUI =>
      SubscriptionService.supportsNativeBilling && !isSubscribed;

  static HostedAppStoreListing? listingFor(HostedAppTier tier) {
    return findHostedAppListing(products, tier);
  }

  static bool _isLocalSubscriptionActive() {
    if (!_isSubscribed || !_serverValidated) {
      return false;
    }
    final expiresAt = _subscriptionExpiresAt;
    if (expiresAt == null) {
      return true;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  static Future<void> initialize() async {
    if (_initialized || !SubscriptionService.supportsNativeBilling) {
      return;
    }

    try {
      _prefs = await SharedPreferences.getInstance();
      _isSubscribed = _prefs?.getBool(_activeKey) ?? false;
      _serverValidated = _prefs?.getBool(_serverValidatedKey) ?? false;
      _activeProductId = _prefs?.getString(_productIdKey);
      _subscriptionExpiresAt = _parseStoredDateTime(
        _prefs?.getString(_expiresAtKey),
      );

      if (!_isSubscribed) {
        _subscriptionExpiresAt = null;
      } else if (_subscriptionExpiresAt != null &&
          _subscriptionExpiresAt!.isBefore(DateTime.now().toUtc())) {
        await _markExpired();
      } else if (_isSubscribed) {
        _scheduleExpirationTimer();
      }

      final iap = InAppPurchase.instance;
      _storeAvailable = await iap.isAvailable();
      if (!_storeAvailable) {
        _initialized = true;
        return;
      }

      if (!_purchaseHandlerRegistered) {
        SharedPurchaseStream.instance.addHandler(_handlePurchaseUpdates);
        _purchaseHandlerRegistered = true;
      }

      await _refreshStoreCatalog();
      await iap.restorePurchases();

      WidgetsBinding.instance.addObserver(
        _HostedAppSubscriptionLifecycleObserver(),
      );

      _initialized = true;

      if (_isSubscribed) {
        unawaited(refreshStatus());
        unawaited(_revalidateCachedSubscription());
      }
      unawaited(refreshFromServer(forceRefresh: true));
    } catch (error, stack) {
      _initialized = true;
      unawaited(
        AppDiagnostics.logError(
          'Failed to initialize hosted app subscription service',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static Future<void> _refreshStoreCatalog() async {
    final response = await InAppPurchase.instance.queryProductDetails(
      hostedAppStoreQueryProductIds(),
    );
    products = response.productDetails;
  }

  static Future<SubscriptionPurchaseResult> purchaseOneApp() =>
      _purchase(HostedAppTier.oneApp);

  static Future<SubscriptionPurchaseResult> purchaseTwoApps() =>
      _purchase(HostedAppTier.twoApps);

  static Future<SubscriptionPurchaseResult> _purchase(HostedAppTier tier) async {
    if (!_storeAvailable) {
      return const SubscriptionPurchaseResult.failed(
        SubscriptionPurchaseFailureReason.storeUnavailable,
      );
    }

    var listing = listingFor(tier);
    if (listing == null) {
      await _refreshStoreCatalog();
      listing = listingFor(tier);
    }

    if (listing == null) {
      return const SubscriptionPurchaseResult.failed(
        SubscriptionPurchaseFailureReason.productUnavailable,
      );
    }

    _pendingTier = tier;
    final started = await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: hostedAppPurchaseParam(listing),
    );
    if (!started) {
      _pendingTier = null;
      return const SubscriptionPurchaseResult.failed(
        SubscriptionPurchaseFailureReason.purchaseStartFailed,
      );
    }
    return const SubscriptionPurchaseResult.started();
  }

  static Future<void> restorePurchases() async {
    if (!_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  static Future<void> refreshStatus() async {
    if (!_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 3));
  }

  /// Returns whether the user has an active hosted-app subscription.
  ///
  /// When a manager session exists, the server eligibility endpoint is
  /// authoritative and local caches are synced against it.
  static Future<bool> resolveEffectiveHostedAppStatus({
    MainApiClient? client,
    bool forceRefresh = false,
  }) async {
    final config = await MainApiSettingsStore.loadConfig();
    final session = await MainApiSettingsStore.loadSession();
    if (config.isConfigured && session != null && !session.isExpired) {
      return refreshFromServer(client: client, forceRefresh: forceRefresh);
    }

    if (!_hasFreshServerSync(forceRefresh: forceRefresh) && _storeAvailable) {
      await refreshStatus();
    }
    return isSubscribed;
  }

  /// Syncs local hosted-app subscription state with the manager.
  static Future<bool> refreshFromServer({
    MainApiClient? client,
    bool forceRefresh = false,
  }) async {
    if (_hasFreshServerSync(forceRefresh: forceRefresh)) {
      return isSubscribed;
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return isSubscribed;
      }

      final apiClient =
          client ??
          MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );
      final eligibility = await apiClient.getHostedAppEligibility();
      _lastServerSyncAt = DateTime.now().toUtc();

      if (!eligibility.premium) {
        if (_isSubscribed) {
          await _markExpired();
        }
        return false;
      }

      if (!_isSubscribed) {
        _isSubscribed = true;
        _serverValidated = true;
        await _prefs?.setBool(_activeKey, true);
        await _prefs?.setBool(_serverValidatedKey, true);
      }
      return true;
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to refresh hosted app subscription from server',
          error,
          stack,
          fatal: false,
        ),
      );
      return isSubscribed;
    }
  }

  static bool _hasFreshServerSync({bool forceRefresh = false}) {
    if (forceRefresh) {
      return false;
    }
    final lastSync = _lastServerSyncAt;
    if (lastSync == null) {
      return false;
    }
    return DateTime.now().toUtc().difference(lastSync) < _serverSyncTtl;
  }

  static Future<void> _revalidateCachedSubscription() async {
    if (!_isSubscribed || !_storeAvailable) {
      return;
    }

    await InAppPurchase.instance.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!_isSubscribed) {
      return;
    }

    if (_isLocalSubscriptionActive()) {
      return;
    }

    await _markExpired();
  }

  static void handleAppResumed() {
    unawaited(refreshStatus());
    unawaited(_revalidateCachedSubscription());
    unawaited(refreshFromServer(forceRefresh: true));
  }

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      if (!isHostedAppStorePurchase(purchase.productID)) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          _pendingTier = null;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  static Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    final pendingTier = _pendingTier;
    final listing =
        pendingTier == null ? null : listingFor(pendingTier);
    final verification = await _verifyPurchaseWithServer(
      purchase,
      listing: listing,
    );
    _pendingTier = null;
    if (!verification.active) {
      return;
    }

    final canonicalProductId =
        verification.canonicalProductId ??
        (pendingTier == null
            ? null
            : canonicalHostedAppProductId(pendingTier));
    if (canonicalProductId == null) {
      return;
    }

    _isSubscribed = true;
    _serverValidated = true;
    _activeProductId = canonicalProductId;
    await _prefs?.setBool(_activeKey, true);
    await _prefs?.setBool(_serverValidatedKey, true);
    await _prefs?.setString(_productIdKey, canonicalProductId);

    final expiresAt = verification.expiresAt;
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now().toUtc())) {
      await _markExpired();
      return;
    }
    _scheduleExpirationTimer();
    await _setSubscriptionExpiry(expiresAt);
  }

  static Future<({bool active, DateTime? expiresAt, String? canonicalProductId})>
  _verifyPurchaseWithServer(
    PurchaseDetails purchase, {
    HostedAppStoreListing? listing,
  }) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final serverVerificationData =
        Platform.isIOS
            ? (purchase.purchaseID ?? '').trim()
            : purchase.verificationData.serverVerificationData.trim();

    if (serverVerificationData.isEmpty) {
      return (active: false, expiresAt: null, canonicalProductId: null);
    }

    final verifyProductId =
        listing == null
            ? purchase.productID
            : verifyBillingProductIdForListing(listing);

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return (active: false, expiresAt: null, canonicalProductId: null);
      }

      final client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      final response = await client.verifyBilling(
        platform: platform,
        serverVerificationData: serverVerificationData,
        productId: verifyProductId,
        localTransactionId: purchase.purchaseID,
      );

      final activeRaw = response['active'];
      final active =
          activeRaw == true || activeRaw?.toString().toLowerCase() == 'true';
      DateTime? expiresAt;
      final rawExpiry = response['expires_at'] ?? response['expiresAt'];
      if (rawExpiry != null && rawExpiry.toString().trim().isNotEmpty) {
        expiresAt = DateTime.tryParse(rawExpiry.toString())?.toUtc();
      }

      final canonical =
          listing == null
              ? hostedAppTierFromCanonicalProductId(purchase.productID) ==
                      null
                  ? null
                  : purchase.productID
              : canonicalHostedAppProductId(listing.tier);

      return (
        active: active,
        expiresAt: expiresAt,
        canonicalProductId: active ? canonical : null,
      );
    } catch (_) {
      return (active: false, expiresAt: null, canonicalProductId: null);
    }
  }

  static Future<void> _markExpired() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _isSubscribed = false;
    _serverValidated = false;
    _activeProductId = null;
    await _setSubscriptionExpiry(null);
    await _prefs?.setBool(_activeKey, false);
    await _prefs?.setBool(_serverValidatedKey, false);
    await _prefs?.remove(_productIdKey);
  }

  static DateTime? _parseStoredDateTime(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toUtc();
  }

  static Future<void> _setSubscriptionExpiry(DateTime? expiresAt) async {
    _subscriptionExpiresAt = expiresAt?.toUtc();
    if (_subscriptionExpiresAt == null) {
      await _prefs?.remove(_expiresAtKey);
      return;
    }
    await _prefs?.setString(
      _expiresAtKey,
      _subscriptionExpiresAt!.toIso8601String(),
    );
  }

  static void _scheduleExpirationTimer() {
    _expiryTimer?.cancel();
    final expiresAt = _subscriptionExpiresAt;
    if (!_isSubscribed || expiresAt == null) {
      _expiryTimer = null;
      return;
    }

    final delay = expiresAt.difference(DateTime.now().toUtc());
    if (delay.isNegative || delay == Duration.zero) {
      unawaited(_markExpired());
      return;
    }

    _expiryTimer = Timer(delay, () {
      unawaited(_markExpired());
    });
  }

  static void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    if (_purchaseHandlerRegistered) {
      SharedPurchaseStream.instance.removeHandler(_handlePurchaseUpdates);
      _purchaseHandlerRegistered = false;
    }
  }
}

class _HostedAppSubscriptionLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      HostedAppSubscriptionService.handleAppResumed();
    }
  }
}
