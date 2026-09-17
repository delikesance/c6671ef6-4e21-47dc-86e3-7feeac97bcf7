import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/analytics/monetization_funnel.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/app_account_token.dart';
import 'package:bot_creator/features/subscriptions/logic/shared_purchase_stream.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
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
  offerTokenMissing,
  purchaseStartFailed,
}

String subscriptionPurchaseErrorKey(SubscriptionPurchaseFailureReason? reason) {
  switch (reason) {
    case SubscriptionPurchaseFailureReason.storeUnavailable:
      return 'subscription_error_store_unavailable';
    case SubscriptionPurchaseFailureReason.offerTokenMissing:
    case SubscriptionPurchaseFailureReason.productUnavailable:
      return 'subscription_error_product_unavailable';
    case SubscriptionPurchaseFailureReason.purchaseStartFailed:
      return 'subscription_error_purchase_start_failed';
    case null:
      return 'subscription_error';
  }
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
  static const String _serverValidatedKey = 'subscription_server_validated';
  static const String _productIdKey = 'subscription_product_id';
  static const String _expiresAtKey = 'subscription_expires_at';

  // ── State ──────────────────────────────────────────────────────────────────
  static bool _initialized = false;
  static bool _isSubscribed = false;
  static bool _serverValidated = false;
  static String? _activeProductId;
  static DateTime? _subscriptionExpiresAt;
  static DateTime? _lastSyncAt;

  static bool? _managerPremiumOverride;
  static DateTime? _managerPremiumOverrideUpdatedAt;
  static DateTime? _lastLocalValidationAt;
  static DateTime? _lastServerSyncAt;
  static bool? _debugForceNativeBillingSourceOfTruth;
  static bool? _debugForceDesktop;
  static Timer? _expiryTimer;
  static SharedPreferences? _prefs;
  static bool _purchaseHandlerRegistered = false;
  static DateTime? _lastTransientPremiumRefreshLogAt;
  static const Duration _transientPremiumRefreshLogCooldown = Duration(
    minutes: 2,
  );

  /// Available products fetched from the store.
  static List<ProductDetails> products = [];

  /// Whether the store is available.
  static bool _storeAvailable = false;

  static const Duration _managerPremiumOverrideTtl = Duration(seconds: 20);
  static const Duration _localValidationTtl = Duration(hours: 6);
  static const Duration _serverSyncTtl = Duration(minutes: 15);

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

  /// Debug-only, rate-limited — avoids log spam when offline or circuit is open.
  static void _logTransientPremiumRefreshDeferred() {
    if (!kDebugMode) {
      return;
    }
    final now = DateTime.now();
    if (_lastTransientPremiumRefreshLogAt != null &&
        now.difference(_lastTransientPremiumRefreshLogAt!) <
            _transientPremiumRefreshLogCooldown) {
      return;
    }
    _lastTransientPremiumRefreshLogAt = now;
    debugPrint(
      '[SubscriptionService] Premium refresh deferred (offline/unreachable).',
    );
  }

  static bool get _usesNativeBillingSourceOfTruth =>
      _debugForceNativeBillingSourceOfTruth ?? supportsNativeBilling;

  @visibleForTesting
  static void debugSetNativeBillingSourceOfTruth(bool? value) {
    _debugForceNativeBillingSourceOfTruth = value;
  }

  /// Test seam for the store round trip: production asks the platform store,
  /// which cannot answer inside a unit test. Returning true means "the store
  /// confirmed the purchase", exactly like a successful restore + verify.
  @visibleForTesting
  static Future<bool> Function()? debugStoreReverifyOverride;

  @visibleForTesting
  static void debugSetDesktopForTests(bool? value) {
    _debugForceDesktop = value;
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
    // Desktop platforms are premium by default.
    if (_isDesktop) return true;
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

  static bool get canUpgradeToAnnual =>
      isSubscribed && activeProductId == kMonthlySubscriptionId;

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
      // Read cached active state immediately so the UI can render without delay.
      _isSubscribed = _prefs?.getBool(_activeKey) ?? false;
      _serverValidated = _prefs?.getBool(_serverValidatedKey) ?? false;
      _activeProductId = _prefs?.getString(_productIdKey);
      _subscriptionExpiresAt = _parseStoredDateTime(
        _prefs?.getString(_expiresAtKey),
      );
      _lastSyncAt = null;

      if (!_isSubscribed) {
        _subscriptionExpiresAt = null;
      }

      if (_isSubscribed) {
        if (_subscriptionExpiresAt != null &&
            _subscriptionExpiresAt!.isBefore(DateTime.now().toUtc())) {
          await _markExpired();
        } else {
          _scheduleExpirationTimer();
        }
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

      // Listen to purchase updates via the shared hub (single IAP stream listener).
      if (!_purchaseHandlerRegistered) {
        SharedPurchaseStream.instance.addHandler(_handlePurchaseUpdates);
        _purchaseHandlerRegistered = true;
      }

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

      // Validate cached subscription against the store and manager in the background.
      if (_isSubscribed) {
        unawaited(refreshStatus());
        unawaited(syncStatusWithBackend());
        unawaited(_revalidateCachedSubscription());
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

      ProductDetails? product = selectPurchaseCandidate(products, productId);

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
        product = selectPurchaseCandidate(products, productId);
      }

      if (product == null) {
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase blocked: product unavailable',
            data: {'product': productId},
          ),
        );
        unawaited(
          MonetizationFunnel.purchaseFailed(
            reason: PurchaseFailureReason.productUnavailable,
            product: productId,
          ),
        );
        return const SubscriptionPurchaseResult.failed(
          SubscriptionPurchaseFailureReason.productUnavailable,
        );
      }

      // ── Android billing readiness check ───────────────────────────────
      // Before calling buyNonConsumable, verify that the Play Billing
      // client can actually handle subscription purchases.  On devices
      // where Play Services returns a null PendingIntent (outdated Play
      // Store, restricted account, etc.), this pre-check gives us a clean
      // failure path instead of crashing inside ProxyBillingActivity.
      if (Platform.isAndroid) {
        try {
          final androidAddition = iap
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
          final ready = await androidAddition.isFeatureSupported(
            BillingClientFeature.subscriptions,
          );
          if (!ready) {
            unawaited(
              AppDiagnostics.logInfo(
                'Purchase blocked: Play Billing subscriptions not supported',
                data: {'product': productId},
              ),
            );
            unawaited(
              MonetizationFunnel.purchaseFailed(
                reason: PurchaseFailureReason.storeUnavailable,
                product: productId,
              ),
            );
            return const SubscriptionPurchaseResult.failed(
              SubscriptionPurchaseFailureReason.storeUnavailable,
            );
          }
        } catch (error, stack) {
          // The feature-support check itself failed (e.g. billing client
          // disconnected).  Don't crash — let the purchase attempt proceed
          // but log the pre-check failure for diagnostics.
          unawaited(
            AppDiagnostics.logError(
              'Pre-purchase billing feature check failed (continuing anyway)',
              error,
              stack,
              fatal: false,
              reason: 'product=$productId',
            ),
          );
        }
      }

      final session = await MainApiSettingsStore.loadSession();
      final currentOwnerId = (session != null && !session.isExpired)
          ? session.userId?.trim()
          : null;
      // StoreKit2 only forwards this as `appAccountToken` when it parses as a
      // UUID (which is what the backend resolves the store notification with);
      // Play receives it as the obfuscated account id.
      final storeAccountToken = appAccountTokenForOwner(currentOwnerId);

      final PurchaseParam purchaseParam;
      if (Platform.isAndroid) {
        // Play Billing 5+ requires the offer token of the selected base plan
        // for a subscription. Building a GooglePlayPurchaseParam without one
        // makes the plugin throw
        // PlatformException(INVALID_OFFER_TOKEN, "Offer token null for product
        // <id> is not valid") and the purchase sheet never opens
        // (issue e65c3fc0).
        final offerToken = subscriptionOfferToken(product);
        if (offerToken == null) {
          unawaited(
            AppDiagnostics.logError(
              'Subscription carries no Play offer token; purchase not started',
              StateError('No subscriptionOfferDetails for $productId'),
              StackTrace.current,
              fatal: false,
              reason: 'product=$productId',
            ),
          );
          unawaited(
            MonetizationFunnel.purchaseFailed(
              reason: PurchaseFailureReason.offerTokenMissing,
              product: productId,
            ),
          );
          return const SubscriptionPurchaseResult.failed(
            SubscriptionPurchaseFailureReason.offerTokenMissing,
          );
        }
        purchaseParam = GooglePlayPurchaseParam(
          productDetails: product,
          applicationUserName: storeAccountToken,
          offerToken: offerToken,
        );
      } else {
        purchaseParam = PurchaseParam(
          productDetails: product,
          applicationUserName: storeAccountToken,
        );
      }
      unawaited(MonetizationFunnel.purchaseStart(product: productId));
      final started = await iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!started) {
        unawaited(
          AppDiagnostics.logInfo(
            'Purchase could not be started',
            data: {'product': productId},
          ),
        );
        unawaited(
          MonetizationFunnel.purchaseFailed(
            reason: PurchaseFailureReason.purchaseStartFailed,
            product: productId,
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
      unawaited(
        MonetizationFunnel.purchaseFailed(
          reason: PurchaseFailureReason.purchaseStartFailed,
          product: productId,
        ),
      );
      return const SubscriptionPurchaseResult.failed(
        SubscriptionPurchaseFailureReason.purchaseStartFailed,
      );
    }
  }

  /// Play Billing 5+ wants the base-plan offer token when buying a
  /// subscription. `null` means the entry cannot be purchased as a subscription
  /// — Play has no offer to launch.
  @visibleForTesting
  static String? subscriptionOfferToken(ProductDetails details) {
    if (details is! GooglePlayProductDetails) {
      return null;
    }
    final token = details.offerToken;
    if (token == null || token.isEmpty) {
      return null;
    }
    return token;
  }

  /// Picks the store entry to purchase for [productId].
  ///
  /// `in_app_purchase_android` queries every identifier twice — once as an
  /// in-app product and once as a subscription — and concatenates both
  /// responses, so one id can appear several times. The first match is not
  /// necessarily purchasable: an entry built from the in-app response carries a
  /// null `offerToken`, and handing that to Play fails the launch with
  /// `INVALID_OFFER_TOKEN` ("Offer token null for product ... is not valid",
  /// issue e65c3fc0). Prefer the entry that can actually be bought, i.e. the
  /// first one carrying an offer token, and fall back to the first match so
  /// non-Google stores keep their previous behaviour.
  @visibleForTesting
  static ProductDetails? selectPurchaseCandidate(
    List<ProductDetails> catalog,
    String productId,
  ) {
    ProductDetails? fallback;
    for (final ProductDetails details in catalog) {
      if (details.id != productId) {
        continue;
      }
      fallback ??= details;
      if (subscriptionOfferToken(details) != null) {
        return details;
      }
    }
    return fallback;
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
          break;
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
          unawaited(
            MonetizationFunnel.purchaseFailed(
              reason: MonetizationFunnel.classifyError(purchase.error?.message),
              product: purchase.productID,
            ),
          );
          break;
        case PurchaseStatus.canceled:
          unawaited(
            MonetizationFunnel.purchaseFailed(
              reason: PurchaseFailureReason.cancelled,
              product: purchase.productID,
            ),
          );
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
    if (!_kSubscriptionIds.contains(purchase.productID)) {
      return;
    }

    final verification = await _verifyPurchaseWithServer(purchase);
    if (!verification.active) {
      unawaited(
        AppDiagnostics.logInfo(
          'Subscription rejected until server verification succeeds',
          data: {
            'product': purchase.productID,
            'reason': verification.reason ?? 'inactive',
          },
        ),
      );
      unawaited(
        MonetizationFunnel.purchaseFailed(
          reason: PurchaseFailureReason.verificationFailed,
          product: purchase.productID,
        ),
      );
      return;
    }

    _isSubscribed = true;
    _serverValidated = true;
    _activeProductId = purchase.productID;
    _managerPremiumOverride = null;
    _managerPremiumOverrideUpdatedAt = null;
    await _prefs?.setBool(_activeKey, true);
    await _prefs?.setBool(_serverValidatedKey, true);
    await _prefs?.setString(_productIdKey, purchase.productID);

    final expiresAt =
        verification.expiresAt ??
        _estimateSubscriptionExpiryFromPurchase(purchase);
    if (expiresAt != null) {
      if (!expiresAt.isAfter(DateTime.now().toUtc())) {
        await _markExpired();
        return;
      }
      await _setSubscriptionExpiry(expiresAt);
    } else {
      await _setSubscriptionExpiry(null);
    }
    _scheduleExpirationTimer();
    _lastLocalValidationAt = DateTime.now().toUtc();
    unawaited(
      AppDiagnostics.logInfo(
        'Subscription activated after server verification',
        data: {'product': purchase.productID},
      ),
    );
    unawaited(MonetizationFunnel.purchaseSuccess(product: purchase.productID));
  }

  static Future<({bool active, DateTime? expiresAt, String? reason})>
  _verifyPurchaseWithServer(PurchaseDetails purchase) async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final serverVerificationData = Platform.isIOS
        ? (purchase.purchaseID ?? '').trim()
        : purchase.verificationData.serverVerificationData.trim();

    if (serverVerificationData.isEmpty) {
      return (active: false, expiresAt: null, reason: 'missing_receipt');
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return (
          active: false,
          expiresAt: null,
          reason: 'missing_manager_session',
        );
      }

      final client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      final response = await client.verifyBilling(
        platform: platform,
        serverVerificationData: serverVerificationData,
        productId: purchase.productID,
        localTransactionId: purchase.purchaseID,
        appAccountToken: appAccountTokenForOwner(session.userId),
      );

      final activeRaw = response['active'];
      final active =
          activeRaw == true || activeRaw?.toString().toLowerCase() == 'true';
      DateTime? expiresAt;
      final rawExpiry = response['expires_at'] ?? response['expiresAt'];
      if (rawExpiry != null && rawExpiry.toString().trim().isNotEmpty) {
        expiresAt = DateTime.tryParse(rawExpiry.toString())?.toUtc();
      }

      return (
        active: active,
        expiresAt: expiresAt,
        reason: active ? null : 'server_inactive',
      );
    } catch (error) {
      return (active: false, expiresAt: null, reason: error.toString());
    }
  }

  static Future<void> _revalidateCachedSubscription() async {
    if (!_isSupportedPlatform || !_isSubscribed) {
      return;
    }

    await InAppPurchase.instance.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 2));

    if (!_isSubscribed) {
      return;
    }

    if (_isLocalSubscriptionActive()) {
      _lastLocalValidationAt = DateTime.now().toUtc();
      return;
    }

    await _markExpired();
  }

  /// Asks the store to replay its purchases and waits for the shared purchase
  /// stream to verify them with the manager.
  ///
  /// Returns true as soon as the local state becomes active again. Bounded and rate
  /// limited on purpose: a genuinely expired subscription must not turn every
  /// refresh into a store round trip.
  static Future<bool> _reverifyFromStore() async {
    final override = debugStoreReverifyOverride;
    if (override != null) {
      return override();
    }
    final lastAttempt = _lastStoreReverifyAt;
    if (!_storeAvailable ||
        (lastAttempt != null &&
            DateTime.now().toUtc().difference(lastAttempt) <
                _storeReverifyCooldown)) {
      return false;
    }
    _lastStoreReverifyAt = DateTime.now().toUtc();

    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Store restore failed while the manager reported no premium',
          error,
          stack,
          fatal: false,
        ),
      );
      return false;
    }

    final deadline = DateTime.now().toUtc().add(_storeReverifyTimeout);
    while (DateTime.now().toUtc().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (_isLocalSubscriptionActive()) {
        return true;
      }
    }
    return _isLocalSubscriptionActive();
  }

  static const Duration _storeReverifyTimeout = Duration(seconds: 8);
  static const Duration _storeReverifyCooldown = Duration(minutes: 10);
  static DateTime? _lastStoreReverifyAt;

  /// Called when a subscription expires or is revoked.
  /// The store will stop sending restored purchases and we reset local state.
  static Future<void> _markExpired() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _isSubscribed = false;
    _serverValidated = false;
    _activeProductId = null;
    await _setSubscriptionExpiry(null);
    _lastLocalValidationAt = DateTime.now().toUtc();
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

  static DateTime? _estimateSubscriptionExpiryFromPurchase(
    PurchaseDetails purchase,
  ) {
    return _estimateSubscriptionExpiry(
      productId: purchase.productID,
      startedAt: _parsePurchaseStartAt(purchase) ?? DateTime.now().toUtc(),
    );
  }

  static DateTime? _estimateSubscriptionExpiry({
    required String productId,
    required DateTime startedAt,
  }) {
    final normalized = productId.trim().toLowerCase();
    final subscriptionStart = startedAt.toUtc();
    if (normalized.contains('annual') || normalized.contains('year')) {
      return _addCalendarMonths(subscriptionStart, 12);
    }
    if (normalized.contains('monthly') || normalized.contains('month')) {
      return _addCalendarMonths(subscriptionStart, 1);
    }
    return null;
  }

  static DateTime? _parsePurchaseStartAt(PurchaseDetails purchase) {
    final raw = purchase.transactionDate?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }

    final millis = int.tryParse(raw);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }

    return DateTime.tryParse(raw)?.toUtc();
  }

  static DateTime _addCalendarMonths(DateTime source, int monthsToAdd) {
    final totalMonths = source.month + monthsToAdd;
    final year = source.year + ((totalMonths - 1) ~/ 12);
    final month = ((totalMonths - 1) % 12) + 1;
    final day = source.day.clamp(1, _daysInMonth(year, month));
    return DateTime.utc(
      year,
      month,
      day,
      source.hour,
      source.minute,
      source.second,
      source.millisecond,
      source.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    if (month == DateTime.december) {
      return DateTime.utc(year + 1).subtract(const Duration(days: 1)).day;
    }
    return DateTime.utc(year, month + 1).subtract(const Duration(days: 1)).day;
  }

  static Future<bool> refreshManagerPremiumStatus({
    MainApiClient? client,
    bool forceRefresh = false,
    bool preferLocalOnFailure = true,
  }) async {
    if (_isDesktop) return true;
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
        // The device believes it is subscribed while the manager says otherwise:
        // usually the purchase was never verified for this account. Replay the store
        // receipt before erasing what we know, otherwise a paying customer lands on
        // "Not subscribed" until they restore by hand. The manager stays the only
        // grantor — it verifies the receipt it receives.
        if (await _reverifyFromStore()) {
          return true;
        }
        await _markExpired();
      } else if (plan && !localPremium && _usesNativeBillingSourceOfTruth) {
        // The manager grants premium but this device holds no local proof: its
        // cache was cleared (an older build wiped it on a stale "free" answer, or
        // the entitlement was repaired server-side). Replay the store receipt so
        // the app heals itself instead of asking a paying customer to restore by
        // hand. Fire and forget: the purchase stream verifies it and repopulates
        // the local state the mobile gate requires.
        unawaited(_reverifyFromStore());
      }
      return plan;
    } catch (error, stack) {
      if (AppDiagnostics.isTransientNetworkError(error)) {
        _logTransientPremiumRefreshDeferred();
      } else {
        unawaited(
          AppDiagnostics.logError(
            'Failed to refresh premium status from manager runtime',
            error,
            stack,
            fatal: false,
          ),
        );
      }
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

  /// Syncs local premium subscription state with the manager.
  ///
  /// When a valid manager session exists, the server plan is authoritative and
  /// can revoke a stale on-device premium cache (for example after admin revoke).
  static Future<bool> refreshPremiumFromServer({
    MainApiClient? client,
    bool forceRefresh = false,
  }) async {
    if (_isDesktop) {
      return true;
    }
    if (_hasFreshServerSync(forceRefresh: forceRefresh)) {
      return _isLocalSubscriptionActive();
    }

    final localPremium = _isLocalSubscriptionActive();

    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return localPremium;
      }

      final apiClient =
          client ??
          MainApiClient(
            baseUrl: config.baseUrl,
            accessToken: session.accessToken,
          );
      final runtime = await apiClient.getGatewayRuntime();
      _lastServerSyncAt = DateTime.now().toUtc();

      final plan =
          _isPremiumPlan(runtime['plan']) ??
          _isPremiumPlan(runtime['account_plan']) ??
          _isPremiumPlan(runtime['subscription_plan']);
      if (plan == null) {
        return localPremium;
      }

      _managerPremiumOverride = plan;
      _managerPremiumOverrideUpdatedAt = DateTime.now().toUtc();
      if (!plan && localPremium) {
        // The device believes it is subscribed while the manager says otherwise:
        // usually the purchase was never verified for this account. Replay the store
        // receipt before erasing what we know, otherwise a paying customer lands on
        // "Not subscribed" until they restore by hand. The manager stays the only
        // grantor — it verifies the receipt it receives.
        if (await _reverifyFromStore()) {
          return true;
        }
        await _markExpired();
      } else if (plan && !localPremium && _usesNativeBillingSourceOfTruth) {
        // The manager grants premium but this device holds no local proof: its
        // cache was cleared (an older build wiped it on a stale "free" answer, or
        // the entitlement was repaired server-side). Replay the store receipt so
        // the app heals itself instead of asking a paying customer to restore by
        // hand. Fire and forget: the purchase stream verifies it and repopulates
        // the local state the mobile gate requires.
        unawaited(_reverifyFromStore());
      }
      return plan;
    } catch (error, stack) {
      if (AppDiagnostics.isTransientNetworkError(error)) {
        _logTransientPremiumRefreshDeferred();
      } else {
        unawaited(
          AppDiagnostics.logError(
            'Failed to refresh premium subscription from server',
            error,
            stack,
            fatal: false,
          ),
        );
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
    if (_isDesktop) return true;
    if (_usesNativeBillingSourceOfTruth) {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (config.isConfigured && session != null && !session.isExpired) {
        return refreshPremiumFromServer(
          client: client,
          forceRefresh: forceRefresh,
        );
      }
      if (!_hasFreshLocalValidation(forceRefresh: forceRefresh)) {
        await refreshStatus();
      }
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
    if (_isDesktop) return true;
    if (_usesNativeBillingSourceOfTruth) {
      if (!_initialized) {
        await initialize();
      }
      if (allowStoredManagerSession) {
        final config = await MainApiSettingsStore.loadConfig();
        final session = await MainApiSettingsStore.loadSession();
        if (config.isConfigured && session != null && !session.isExpired) {
          return refreshPremiumFromServer(
            client: client,
            forceRefresh: forceRefresh,
          );
        }
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

    final config = allowStoredManagerSession
        ? await MainApiSettingsStore.loadConfig()
        : null;
    final session = allowStoredManagerSession
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

  /// Centralized helper to check if a user is Premium and can skip ads with a safety timeout.
  static Future<bool> canSkipRewardedAdsWithTimeout({
    MainApiClient? client,
    bool forceRefresh = false,
    bool allowStoredManagerSession = true,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    try {
      return await canSkipRewardedAds(
        client: client,
        forceRefresh: forceRefresh,
        allowStoredManagerSession: allowStoredManagerSession,
      ).timeout(timeout, onTimeout: () => false);
    } catch (_) {
      return false;
    }
  }

  static bool get _isDesktop {
    if (_debugForceDesktop != null) {
      return _debugForceDesktop!;
    }
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
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

    await InAppPurchase.instance.restorePurchases();

    // Give the stream a moment to deliver restored purchases.
    // We wait long enough to handle slower network responses on iOS/Android.
    await Future<void>.delayed(const Duration(seconds: 5));

    _lastLocalValidationAt = DateTime.now().toUtc();
  }

  static void handleAppResumed() {
    MainApiClient.resetCircuitBreakers();
    unawaited(refreshStatus());
    unawaited(_revalidateCachedSubscription());
    unawaited(refreshPremiumFromServer(forceRefresh: true));
    unawaited(resolveEffectivePremiumStatus(forceRefresh: true));
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
    if (_purchaseHandlerRegistered) {
      SharedPurchaseStream.instance.removeHandler(_handlePurchaseUpdates);
      _purchaseHandlerRegistered = false;
    }
  }

  @visibleForTesting
  static Future<void> debugResetForTests() async {
    dispose();
    _initialized = false;
    _isSubscribed = false;
    _serverValidated = false;
    _activeProductId = null;
    _subscriptionExpiresAt = null;
    _managerPremiumOverride = null;
    _managerPremiumOverrideUpdatedAt = null;
    _lastLocalValidationAt = null;
    _lastServerSyncAt = null;
    _debugForceNativeBillingSourceOfTruth = null;
    _debugForceDesktop = null;
    debugStoreReverifyOverride = null;
    _lastStoreReverifyAt = null;
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
    _serverValidated = active;
    _activeProductId = active ? productId : null;
    _subscriptionExpiresAt = active ? expiresAt?.toUtc() : null;
    _initialized = true;
    _storeAvailable = true;
    _lastLocalValidationAt = DateTime.now().toUtc();
  }

  @visibleForTesting
  static DateTime? debugEstimateSubscriptionExpiryForTests({
    required String productId,
    required DateTime startedAt,
  }) {
    return _estimateSubscriptionExpiry(
      productId: productId,
      startedAt: startedAt,
    );
  }

  /// Calculates the savings percentage of an annual subscription compared to 12 months.
  /// Returns null if savings are less than [minThresholdPercent] (default 10) or incoherent.
  static int? calculateAnnualSavingsPercent({
    required double? annualPrice,
    required double? monthlyPrice,
    int minThresholdPercent = 10,
  }) {
    if (annualPrice == null || monthlyPrice == null || monthlyPrice <= 0) {
      return null;
    }
    final annualFromMonthly = 12 * monthlyPrice;
    if (annualFromMonthly <= 0 || annualPrice >= annualFromMonthly) {
      return null;
    }
    final savingsPercent =
        ((annualFromMonthly - annualPrice) / annualFromMonthly * 100).round();
    if (savingsPercent < minThresholdPercent) {
      return null;
    }
    return savingsPercent;
  }
}

class _SubscriptionLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SubscriptionService.handleAppResumed();
    }
  }
}
