import 'dart:async';
import 'dart:io';

import 'package:bot_creator/utils/app_diagnostics.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product identifiers — must match Google Play / App Store Connect.
const String kMonthlySubscriptionId = 'bot_creator_premium_monthly';
const String kAnnualSubscriptionId = 'bot_creator_premium_annual';
const Set<String> _kSubscriptionIds = {
  kMonthlySubscriptionId,
  kAnnualSubscriptionId,
};

enum SubscriptionPurchaseFailureReason {
  storeUnavailable,
  productUnavailable,
  purchaseStartFailed,
}

class SubscriptionPurchaseResult {
  const SubscriptionPurchaseResult._({
    required this.started,
    this.failureReason,
  });

  const SubscriptionPurchaseResult.started()
    : this._(started: true, failureReason: null);

  const SubscriptionPurchaseResult.failed(
    SubscriptionPurchaseFailureReason reason,
  ) : this._(started: false, failureReason: reason);

  final bool started;
  final SubscriptionPurchaseFailureReason? failureReason;
}

class SubscriptionService {
  SubscriptionService._();

  // ── Prefs keys ─────────────────────────────────────────────────────────────
  static const String _activeKey = 'subscription_active';
  static const String _productIdKey = 'subscription_product_id';
  static const String _expiresAtKey = 'subscription_expires_at';
  static const String _lastSyncKey = 'subscription_last_sync_at';


  // ── State ──────────────────────────────────────────────────────────────────
  static bool _initialized = false;
  static bool _isSubscribed = false;
  static String? _activeProductId;
  static DateTime? _subscriptionExpiresAt;
  static DateTime? _lastSyncAt;

  static bool? _managerPremiumOverride;
  static DateTime? _managerPremiumOverrideUpdatedAt;
  static DateTime? _lastLocalValidationAt;
  static bool? _debugForceNativeBillingSourceOfTruth;
  static Timer? _expiryTimer;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  static SharedPreferences? _prefs;

  /// Available products fetched from the store.
  static List<ProductDetails> products = [];

  /// Whether the store is available.
  static bool _storeAvailable = false;

  static const Duration _managerPremiumOverrideTtl = Duration(seconds: 20);
  static const Duration _localValidationTtl = Duration(hours: 6);

  static bool _isLocalSubscriptionActive() {
    if (!_isSubscribed) {
      return false;
    }
    final expiresAt = _subscriptionExpiresAt;
    if (expiresAt == null) {
      return true;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  static bool _hasFreshManagerOverride({bool forceRefresh = false}) {
    if (forceRefresh) {
      return false;
    }
    final updatedAt = _managerPremiumOverrideUpdatedAt;
    if (_managerPremiumOverride == null || updatedAt == null) {
      return false;
    }
    return DateTime.now().toUtc().difference(updatedAt) <=
        _managerPremiumOverrideTtl;
  }

  static bool _hasFreshLocalValidation({bool forceRefresh = false}) {
    if (forceRefresh) {
      return false;
    }
    final validatedAt = _lastLocalValidationAt;
    if (validatedAt == null) {
      return false;
    }
    return DateTime.now().toUtc().difference(validatedAt) <=
        _localValidationTtl;
  }

  static bool get _usesNativeBillingSourceOfTruth =>
      _debugForceNativeBillingSourceOfTruth ?? supportsNativeBilling;

  @visibleForTesting
  static void debugSetNativeBillingSourceOfTruth(bool? value) {
    _debugForceNativeBillingSourceOfTruth = value;
  }

  static bool? _isPremiumPlan(dynamic rawPlan) {
    if (rawPlan == null) {
      return null;
    }
    final normalized = rawPlan.toString().trim().toUpperCase();
    if (normalized.isEmpty) {
      return null;
    }
    if (normalized == 'PREMIUM') {
      return true;
    }
    if (normalized == 'FREE') {
      return false;
    }
    return null;
  }

  /// Whether the user holds an active premium subscription.
  static bool get isSubscribed {
    if (_usesNativeBillingSourceOfTruth) {
      return _isLocalSubscriptionActive();
    }
    if (_hasFreshManagerOverride()) {
      return _managerPremiumOverride!;
    }
    return _isLocalSubscriptionActive();
  }

  /// Whether native in-app subscriptions are available on this platform.
  static bool get supportsNativeBilling => _isSupportedPlatform;

  /// The active product ID (if subscribed).
  static String? get activeProductId => _activeProductId;

  /// The verified subscription expiration time, if known.
  static DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  // ── Initialisation ─────────────────────────────────────────────────────────

  static Future<void> initialize() async {
    if (_initialized || !_isSupportedPlatform) return;

    try {
      _prefs = await SharedPreferences.getInstance();

      // Read cached state immediately so the UI can render without delay.
      _isSubscribed = _prefs?.getBool(_activeKey) ?? false;
      _activeProductId = _prefs?.getString(_productIdKey);
      final expiresAtRaw = _prefs?.getString(_expiresAtKey);
      _subscriptionExpiresAt =
          expiresAtRaw == null
              ? null
              : DateTime.tryParse(expiresAtRaw)?.toUtc();

      final lastSyncRaw = _prefs?.getString(_lastSyncKey);
      _lastSyncAt =
          lastSyncRaw == null ? null : DateTime.tryParse(lastSyncRaw)?.toUtc();

      if (_isSubscribed && _subscriptionExpiresAt == null) {
        await _markExpired();
      } else if (_subscriptionExpiresAt != null &&
          _subscriptionExpiresAt!.isBefore(DateTime.now().toUtc())) {
        await _markExpired();
      } else {
        _scheduleExpirationTimer();
      }


      final iap = InAppPurchase.instance;
      _storeAvailable = await iap.isAvailable();
      if (!_storeAvailable) {
        unawaited(
          AppDiagnostics.logInfo('In-app purchase store not available'),
        );
        _initialized = true;
        return;
      }

      // Listen to purchase updates.
      _subscription = iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _subscription?.cancel(),
        onError: (Object error) {
          unawaited(
            AppDiagnostics.logError(
              'Purchase stream error',
              error,
              StackTrace.current,
              fatal: false,
            ),
          );
        },
      );

      // Query available products.
      final response = await iap.queryProductDetails(_kSubscriptionIds);
      if (response.notFoundIDs.isNotEmpty) {
        unawaited(
          AppDiagnostics.logInfo(
            'Some subscription IDs not found in store',
            data: {'ids': response.notFoundIDs.join(', ')},
          ),
        );
      }
      unawaited(
        AppDiagnostics.logInfo(
          'Store product catalog fetched',
          data: {
            'count': response.productDetails.length,
            'ids': response.productDetails.map((p) => p.id).join(', '),
          },
        ),
      );
      products = response.productDetails;

      // Restore previous purchases (required by Apple guidelines).
      await iap.restorePurchases();

      // Refresh on app resume to detect expired subscriptions.
      WidgetsBinding.instance.addObserver(_SubscriptionLifecycleObserver());

      _initialized = true;
      unawaited(
        AppDiagnostics.logInfo(
          'Subscription service initialized',
          data: {
            'storeAvailable': _storeAvailable,
            'products': products.length,
            'cachedActive': _isSubscribed,
          },
        ),
      );

      // Validate cached subscription against the store in the background.
      if (isSubscribed) {
        unawaited(refreshStatus());
        unawaited(syncStatusWithBackend());
      }
      unawaited(resolveEffectivePremiumStatus(forceRefresh: true));
    } catch (error, stack) {
      _initialized = true;
      unawaited(
        AppDiagnostics.logError(
          'Failed to initialize subscription service',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  // ── Purchase flow ──────────────────────────────────────────────────────────

  /// Start a monthly subscription purchase.
  static Future<SubscriptionPurchaseResult> purchaseMonthly() =>
      _purchase(kMonthlySubscriptionId);

  /// Start an annual subscription purchase.
  static Future<SubscriptionPurchaseResult> purchaseAnnual() =>
      _purchase(kAnnualSubscriptionId);

  static Future<SubscriptionPurchaseResult> _purchase(String productId) async {
    try {
      final iap = InAppPurchase.instance;
      var storeAvailable = _storeAvailable;

      if (!storeAvailable) {
        storeAvailable = await iap.isAvailable();
        _storeAvailable = storeAvailable;
      }

      if (!storeAvailable) {
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase blocked: store unavailable',
            data: {'product': productId},
          ),
        );
        return const SubscriptionPurchaseResult.failed(
          SubscriptionPurchaseFailureReason.storeUnavailable,
        );
      }

      unawaited(
        AppDiagnostics.logInfo(
          'Purchase attempt started',
          data: {'product': productId},
        ),
      );

      ProductDetails? product = products.cast<ProductDetails?>().firstWhere(
        (p) => p?.id == productId,
        orElse: () => null,
      );

      if (product == null) {
        final response = await iap.queryProductDetails(_kSubscriptionIds);
        if (response.error != null) {
          unawaited(
            AppDiagnostics.logInfo(
              'Purchase preflight product query error',
              data: {
                'product': productId,
                'error': response.error?.message ?? 'unknown',
              },
            ),
          );
        }
        if (response.notFoundIDs.isNotEmpty) {
          unawaited(
            AppDiagnostics.logInfo(
              'Purchase preflight product not found',
              data: {
                'product': productId,
                'notFound': response.notFoundIDs.join(', '),
              },
            ),
          );
        }
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase preflight store catalog snapshot',
            data: {
              'product': productId,
              'count': response.productDetails.length,
              'available': response.productDetails.map((p) => p.id).join(', '),
            },
          ),
        );
        products = response.productDetails;
        product = products.cast<ProductDetails?>().firstWhere(
          (p) => p?.id == productId,
          orElse: () => null,
        );
      }

      if (product == null) {
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase blocked: product unavailable',
            data: {'product': productId},
          ),
        );
        return const SubscriptionPurchaseResult.failed(
          SubscriptionPurchaseFailureReason.productUnavailable,
        );
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase could not be started',
            data: {'product': productId},
          ),
        );
        return const SubscriptionPurchaseResult.failed(
          SubscriptionPurchaseFailureReason.purchaseStartFailed,
        );
      }

      return const SubscriptionPurchaseResult.started();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Purchase preflight failed',
          error,
          stack,
          fatal: false,
          reason: 'product=$productId',
        ),
      );
      return const SubscriptionPurchaseResult.failed(
        SubscriptionPurchaseFailureReason.purchaseStartFailed,
      );
    }
  }

  /// Restore purchases — surfaces the store-native restore dialog on iOS.
  static Future<void> restorePurchases() async {
    if (!_storeAvailable) return;
    await InAppPurchase.instance.restorePurchases();
  }

  // ── Purchase handling ──────────────────────────────────────────────────────

  static Future<void> _handlePurchaseUpdates(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchase in purchaseDetailsList) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndDeliver(purchase);
        case PurchaseStatus.error:
          unawaited(
            AppDiagnostics.logInfo(
              'Purchase error',
              data: {
                'product': purchase.productID,
                'error': purchase.error?.message ?? 'unknown',
              },
            ),
          );
        case PurchaseStatus.canceled:
          break;
        case PurchaseStatus.pending:
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  static Future<void> _verifyAndDeliver(PurchaseDetails purchase) async {
    // For a "remove ads" feature with no server, client-side verification
    // via the store receipt is sufficient. The store guarantees the purchase
    // validity through the purchaseStream.
    if (_kSubscriptionIds.contains(purchase.productID)) {
      _isSubscribed = true;
      _activeProductId = purchase.productID;
      _managerPremiumOverride = null;
      _managerPremiumOverrideUpdatedAt = null;
      await _prefs?.setBool(_activeKey, true);
      await _prefs?.setString(_productIdKey, purchase.productID);
      final expiresAt = await _syncBillingEntitlement(purchase);
      if (expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc())) {
        await _markExpired();
        return;
      }
      _subscriptionExpiresAt = expiresAt.toUtc();
      _lastLocalValidationAt = DateTime.now().toUtc();
      await _prefs?.setString(
        _expiresAtKey,
        _subscriptionExpiresAt!.toIso8601String(),
      );
      _scheduleExpirationTimer();
      unawaited(
        AppDiagnostics.logInfo(
          'Subscription activated',
          data: {'product': purchase.productID},
        ),
      );
    }
  }

  static Future<DateTime?> _syncBillingEntitlement(
    PurchaseDetails purchase,
  ) async {
    final receipt = purchase.verificationData.serverVerificationData.trim();
    if (receipt.isEmpty) {
      return null;
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return null;
      }

      final client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      final provider = Platform.isIOS ? 'apple' : 'google';
      final response = await client.verifyBilling(
        provider: provider,
        receipt: receipt,
        transactionId: purchase.purchaseID,
      );
      final expiresAtRaw = response['expiresAt'] ?? response['expires_at'];
      final expiresAt =
          DateTime.tryParse(expiresAtRaw?.toString() ?? '')?.toUtc();
      unawaited(
        AppDiagnostics.logInfo(
          'Subscription synced to main API',
          data: {'product': purchase.productID, 'provider': provider},
        ),
      );
      return expiresAt;
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to sync subscription to main API',
          error,
          stack,
          fatal: false,
          reason: 'product=${purchase.productID}',
        ),
      );
      return null;
    }
  }

  /// Called when a subscription expires or is revoked.
  /// The store will stop sending restored purchases and we reset local state.
  static Future<void> _markExpired() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _isSubscribed = false;
    _activeProductId = null;
    _subscriptionExpiresAt = null;
    _lastLocalValidationAt = DateTime.now().toUtc();
    await _prefs?.setBool(_activeKey, false);
    await _prefs?.remove(_productIdKey);
    await _prefs?.remove(_expiresAtKey);
  }

  static Future<bool> refreshManagerPremiumStatus({
    MainApiClient? client,
    bool forceRefresh = false,
    bool preferLocalOnFailure = true,
  }) async {
    if (_usesNativeBillingSourceOfTruth) {
      return _isLocalSubscriptionActive();
    }
    final localPremium = _isLocalSubscriptionActive();
    if (_hasFreshManagerOverride(forceRefresh: forceRefresh)) {
      return _managerPremiumOverride!;
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured) {
        _managerPremiumOverride = null;
        _managerPremiumOverrideUpdatedAt = null;
        return localPremium;
      }

      if (session == null || session.isExpired) {
        if (!preferLocalOnFailure) {
          _managerPremiumOverride = false;
          _managerPremiumOverrideUpdatedAt = DateTime.now().toUtc();
          return false;
        }
        _managerPremiumOverride = null;
        _managerPremiumOverrideUpdatedAt = null;
        return localPremium;
      }

      final gatewayClient =
          client ??
          MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );

      final runtime = await gatewayClient.getGatewayRuntime();
      final plan =
          _isPremiumPlan(runtime['plan']) ??
          _isPremiumPlan(runtime['account_plan']) ??
          _isPremiumPlan(runtime['subscription_plan']);
      if (plan == null) {
        if (!preferLocalOnFailure) {
          _managerPremiumOverride = false;
          _managerPremiumOverrideUpdatedAt = DateTime.now().toUtc();
          return false;
        }
        _managerPremiumOverride = null;
        _managerPremiumOverrideUpdatedAt = null;
        return localPremium;
      }

      _managerPremiumOverride = plan;
      _managerPremiumOverrideUpdatedAt = DateTime.now().toUtc();
      if (!plan && localPremium) {
        await _markExpired();
      }
      return plan;
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to refresh premium status from manager runtime',
          error,
          stack,
          fatal: false,
        ),
      );
      if (!preferLocalOnFailure) {
        _managerPremiumOverride = false;
        _managerPremiumOverrideUpdatedAt = DateTime.now().toUtc();
        return false;
      }
      final managerOverride = _managerPremiumOverride;
      if (managerOverride != null) {
        return managerOverride;
      }
      return localPremium;
    }
  }

  /// Returns the effective premium state used by the app.
  ///
  /// When a valid manager session exists, the manager becomes the
  /// source of truth and local caches are refreshed against it before
  /// granting premium-only behavior such as ad-free starts.
  static Future<bool> resolveEffectivePremiumStatus({
    MainApiClient? client,
    bool forceRefresh = false,
  }) async {
    if (_usesNativeBillingSourceOfTruth) {
      _managerPremiumOverride = null;
      _managerPremiumOverrideUpdatedAt = null;
      await refreshStatus();
      return _isLocalSubscriptionActive();
    }
    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      _managerPremiumOverride = null;
      _managerPremiumOverrideUpdatedAt = null;
      return isSubscribed;
    }

    final session = await MainApiSettingsStore.loadSession();
    if (session == null || session.isExpired) {
      _managerPremiumOverride = null;
      _managerPremiumOverrideUpdatedAt = null;
      return isSubscribed;
    }

    return refreshManagerPremiumStatus(
      client: client,
      forceRefresh: forceRefresh,
      preferLocalOnFailure: false,
    );
  }

  /// Returns whether rewarded ads can be skipped for bot starts.
  ///
  /// This path is intentionally stricter than the generic premium UI:
  /// a valid manager session is authoritative, otherwise native billing
  /// must be verifiable on-device before ad-free access is granted.
  static Future<bool> canSkipRewardedAds({
    MainApiClient? client,
    bool forceRefresh = false,
    bool allowStoredManagerSession = true,
  }) async {
    if (_usesNativeBillingSourceOfTruth) {
      if (!_initialized) {
        await initialize();
      }
      if (!_storeAvailable) {
        return false;
      }
      if (!_hasFreshLocalValidation(forceRefresh: forceRefresh)) {
        await refreshStatus();
        _lastLocalValidationAt = DateTime.now().toUtc();
      }
      return _isLocalSubscriptionActive();
    }

    final config =
        allowStoredManagerSession
            ? await MainApiSettingsStore.loadConfig()
            : null;
    final session =
        allowStoredManagerSession
            ? await MainApiSettingsStore.loadSession()
            : null;
    if (client != null ||
        (config?.isConfigured == true &&
            session != null &&
            !session.isExpired)) {
      return refreshManagerPremiumStatus(
        client: client,
        forceRefresh: forceRefresh,
        preferLocalOnFailure: false,
      );
    }

    if (!_isSupportedPlatform) {
      return false;
    }
    if (!_initialized) {
      await initialize();
    }
    if (!_storeAvailable) {
      return false;
    }
    if (!_hasFreshLocalValidation(forceRefresh: forceRefresh)) {
      await refreshStatus();
      _lastLocalValidationAt = DateTime.now().toUtc();
    }
    return _isLocalSubscriptionActive();
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

  /// Re-validate subscription status against the store.
  /// Call periodically or on app resume to detect expirations.
  static Future<void> refreshStatus() async {
    if (!_storeAvailable || !_isSupportedPlatform) return;

    // Triggering restorePurchases will re-fire the purchaseStream with
    // any still-active subscriptions. If none come back, the subscription
    // has expired.
    final previouslySubscribed = _isSubscribed;
    // Temporarily mark as not subscribed; will be re-set if restore finds
    // an active subscription.
    _isSubscribed = false;
    _activeProductId = null;

    await InAppPurchase.instance.restorePurchases();

    // Give the stream a moment to deliver restored purchases.
    await Future<void>.delayed(const Duration(seconds: 2));
    _lastLocalValidationAt = DateTime.now().toUtc();

    if (!_isSubscribed && previouslySubscribed) {
      // No active subscription came back — mark as expired.
      await _markExpired();
      unawaited(AppDiagnostics.logInfo('Subscription expired or revoked'));
    }
  }

  /// Syncs the local subscription status with the backend.
  ///
  /// By default, the sync is throttled to once every 24 hours to reduce API
  /// load. Setting [force] to true bypasses this check.
  static Future<void> syncStatusWithBackend({bool force = false}) async {
    if (!_isSupportedPlatform) return;

    final now = DateTime.now().toUtc();
    final lastSync = _lastSyncAt;

    if (!force &&
        lastSync != null &&
        now.difference(lastSync) < const Duration(hours: 24)) {
      return;
    }

    try {
      final iap = InAppPurchase.instance;
      // Triggers purchase stream which eventually calls _syncBillingEntitlement.
      // This is the cleanest way to ensure we have a fresh receipt and sync it.
      await iap.restorePurchases();

      _lastSyncAt = now;
      await _prefs?.setString(_lastSyncKey, now.toIso8601String());

      unawaited(
        AppDiagnostics.logInfo(
          'Subscription status sync requested',
          data: {'force': force},
        ),
      );
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to trigger subscription sync',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static void dispose() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _subscription?.cancel();
    _subscription = null;
  }

  @visibleForTesting
  static Future<void> debugResetForTests() async {
    dispose();
    _initialized = false;
    _isSubscribed = false;
    _activeProductId = null;
    _subscriptionExpiresAt = null;
    _managerPremiumOverride = null;
    _managerPremiumOverrideUpdatedAt = null;
    _lastLocalValidationAt = null;
    _debugForceNativeBillingSourceOfTruth = null;
    _prefs = null;
    products = <ProductDetails>[];
    _storeAvailable = false;
  }

  @visibleForTesting
  static void debugSetLocalSubscriptionForTests({
    required bool active,
    String? productId,
    DateTime? expiresAt,
  }) {
    _isSubscribed = active;
    _activeProductId = active ? productId : null;
    _subscriptionExpiresAt = active ? expiresAt?.toUtc() : null;
    _initialized = true;
    _storeAvailable = true;
    _lastLocalValidationAt = DateTime.now().toUtc();
  }
}

class _SubscriptionLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(SubscriptionService.refreshStatus());
      unawaited(
        SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true),
      );
    }
  }
}
