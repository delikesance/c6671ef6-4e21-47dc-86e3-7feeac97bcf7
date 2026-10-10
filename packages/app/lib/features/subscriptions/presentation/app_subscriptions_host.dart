import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:bot_creator/features/subscriptions/logic/ai_reward_ad.dart';
import 'package:bot_creator/features/subscriptions/logic/commerce_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/consumable_purchase_service.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_billing_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_management_links.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/ai_credits_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

/// Les abonnements tels que l'app les lit et les achète : services de facturation
/// natifs (App Store / Google Play), formule du Manager par `MainApiClient`, et
/// reçus de boutique. Les écrans (`SubscriptionsHubPage`, `SubscriptionPage`,
/// carte des réglages) sont ceux du paquet `bot_creator_ui`, partagés avec le
/// Studio.
class AppSubscriptionsHost extends ui.SubscriptionsHost {
  const AppSubscriptionsHost();

  @override
  ui.SubscriptionsSnapshot get current {
    final hostedTier = switch (hostedAppTierFromCanonicalProductId(
      HostedAppSubscriptionService.activeProductId,
    )) {
      HostedAppTier.oneApp => ui.HostedStoreTier.oneApp,
      HostedAppTier.twoApps => ui.HostedStoreTier.twoApps,
      null => null,
    };
    final cadence = switch (SubscriptionService.activeProductId) {
      kAnnualSubscriptionId => ui.BotStoreCadence.annual,
      kMonthlySubscriptionId => ui.BotStoreCadence.monthly,
      _ => null,
    };
    return ui.SubscriptionsSnapshot(
      botActive: SubscriptionService.isSubscribed,
      planDisplayName: SubscriptionService.activePlanDisplayName,
      planMaxBots: SubscriptionService.activePlanMaxBots,
      botStoreCadence: cadence,
      botExpiresAt: SubscriptionService.subscriptionExpiresAt,
      botServerGranted: SubscriptionService.isServerGranted,
      botHasStoreSubscription: SubscriptionService.hasNativeStoreSubscription,
      canUpgradeBotToAnnual: SubscriptionService.canUpgradeToAnnual,
      hostedActive: HostedAppSubscriptionService.isSubscribed,
      hostedServerGranted:
          HostedAppSubscriptionService.hasServerGrantedHostedApps,
      hostedMaxContainers: HostedAppSubscriptionService.serverMaxContainers,
      hostedStoreTier: hostedTier,
      hostedStoreExpiresAt: HostedAppSubscriptionService.subscriptionExpiresAt,
      hostingCoverageExpiresAt:
          HostedAppSubscriptionService.hostingCoverageExpiresAt,
      hostingCoveragePermanent:
          HostedAppSubscriptionService.hostingCoveragePermanent,
      canUpgradeHostedToTwoApps:
          HostedAppSubscriptionService.canUpgradeToTwoApps,
    );
  }

  @override
  Future<ui.SubscriptionsSnapshot> refresh() async {
    await Future.wait([
      SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true),
      HostedAppSubscriptionService.resolveEffectiveHostedAppStatus(
        forceRefresh: true,
      ),
      _registerPurchasableProducts(),
    ]);
    return current;
  }

  /// Récupère les SKUs que le serveur rattache aux formules, pour que le store les
  /// reconnaisse lors de l'achat et de la validation des reçus.
  ///
  /// C'est le SEUL usage du catalogue côté application : le mapping serveur décrit des
  /// capacités (à quelle formule correspond quel achat, quels droits en découlent), jamais
  /// une liste d'offres à afficher. Les offres montrées à l'utilisateur sont une
  /// fonctionnalité de l'application (voir les deux cartes du hub et
  /// `SubscriptionPage`), pas un rendu de la configuration serveur : sinon renommer une
  /// formule en base changerait l'interface, et une formule sans SKU mappé produirait un
  /// bouton d'achat qui échoue.
  Future<void> _registerPurchasableProducts() async {
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured || session == null || session.isExpired) {
        return;
      }
      final client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      final catalog = await client.getGatewayPlans();
      SubscriptionService.registerPurchasableProductIds(
        catalog.plans.expand((plan) => plan.productIds),
      );
    } catch (_) {
      // Catalogue indisponible : l'application garde ses propres identifiants de produits
      // (constantes de `SubscriptionProductKind`), donc l'achat reste possible.
    }
  }

  @override
  Future<ui.CommerceCatalog?> loadCommerce() => loadCommerceCatalog();

  // ── Achats ────────────────────────────────────────────────────────────────

  /// Toujours vrai : les écrans d'abonnement de l'app ne s'ouvrent que là où la
  /// boutique native existe (`SubscriptionsHubPage.open`, `SubscriptionPage.show`
  /// et la carte des réglages refusent ailleurs avec « disponible sur mobile
  /// seulement »). Les ouvrir sans cette garde, c'est choisir de les montrer.
  @override
  bool get canPurchase => true;

  @override
  bool get isBotSubscribed => SubscriptionService.isSubscribed;

  @override
  Future<String?> upgradeBotToAnnual() async =>
      _errorKey(await SubscriptionService.purchaseAnnual());

  @override
  Future<String?> upgradeHostedToTwoApps() async =>
      _errorKey(await HostedAppSubscriptionService.purchaseTwoApps());

  String? _errorKey(SubscriptionPurchaseResult result) => result.started
      ? null
      : subscriptionPurchaseErrorKey(result.failureReason);

  @override
  Future<void> restorePurchases() async {
    await SubscriptionService.restorePurchases();
    await HostedAppSubscriptionService.restorePurchases();
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  @override
  Future<void> manageSubscription(ui.SubscriptionKind kind) async {
    switch (kind) {
      case ui.SubscriptionKind.botPremium:
        await openSubscriptionManagement(
          kind: SubscriptionProductKind.botPremium,
          storeProductId: SubscriptionService.activeProductId,
        );
      case ui.SubscriptionKind.hostedApp:
        await openSubscriptionManagement(
          kind: SubscriptionProductKind.hostedApp,
          storeProductId: HostedAppSubscriptionService.activeProductId,
        );
    }
  }

  @override
  void openHostedPurchase(BuildContext context) =>
      HostedAppSubscriptionPage.show(context);

  // ── Offres ────────────────────────────────────────────────────────────────

  @override
  String? get storePlatform {
    if (!SubscriptionService.supportsNativeBilling) return null;
    return Platform.isIOS ? 'ios' : 'android';
  }

  @override
  Future<void> prepareOffers(ui.CommerceCatalog catalog) async {
    final platform = storePlatform ?? (Platform.isIOS ? 'ios' : 'android');
    final ids = catalog.offers
        .where((o) => o.kind == 'subscription')
        .map((o) => o.nativeBinding(platform)?.productId)
        .whereType<String>()
        .toSet();
    if (ids.isNotEmpty) await SubscriptionService.loadCatalogProducts(ids);
  }

  @override
  String? priceForOffer(ui.CommerceOffer offer) {
    final platform = storePlatform;
    final binding = platform == null ? null : offer.nativeBinding(platform);
    if (binding == null) return null;
    return SubscriptionService.selectPurchaseCandidate(
      SubscriptionService.products,
      binding.productId,
      basePlanId: binding.basePlanId,
    )?.price;
  }

  @override
  Future<String?> purchaseOffer(ui.CommerceOffer offer) async {
    final platform = storePlatform;
    final binding = platform == null ? null : offer.nativeBinding(platform);
    if (binding == null) return 'subscription_error_product_unavailable';
    return _errorKey(
      await SubscriptionService.purchaseProduct(
        binding.productId,
        basePlanId: binding.basePlanId,
      ),
    );
  }

  static String _productId(ui.BotStoreCadence cadence) =>
      cadence == ui.BotStoreCadence.annual
      ? kAnnualSubscriptionId
      : kMonthlySubscriptionId;

  @override
  String priceForBotPlan(ui.BotStoreCadence cadence, String fallback) {
    final id = _productId(cadence);
    final product = SubscriptionService.products.cast<dynamic>().firstWhere(
      (p) => p.id == id,
      orElse: () => null,
    );
    if (product != null) return product.price as String;
    return fallback;
  }

  double? _priceAmount(String productId, String fallback) {
    final product = SubscriptionService.products.cast<dynamic>().firstWhere(
      (p) => p.id == productId,
      orElse: () => null,
    );
    if (product != null &&
        product.rawPrice != null &&
        (product.rawPrice as num) > 0) {
      return (product.rawPrice as num).toDouble();
    }
    final priceStr = product?.price as String? ?? fallback;
    final sanitized = priceStr
        .replaceAll(RegExp(r'[^\d,\.]'), '')
        .replaceAll(',', '.');
    return double.tryParse(sanitized);
  }

  @override
  int? annualSavingsPercent() =>
      SubscriptionService.calculateAnnualSavingsPercent(
        annualPrice: _priceAmount(kAnnualSubscriptionId, '59,99 €'),
        monthlyPrice: _priceAmount(kMonthlySubscriptionId, '5,99 €'),
        minThresholdPercent: 10,
      );

  @override
  Future<String?> purchaseBotPlan(ui.BotStoreCadence cadence) async =>
      _errorKey(
        cadence == ui.BotStoreCadence.annual
            ? await SubscriptionService.purchaseAnnual()
            : await SubscriptionService.purchaseMonthly(),
      );

  @override
  Future<bool> restoreBotPurchases() async {
    await SubscriptionService.restorePurchases();
    // Wait a moment for the stream to deliver restored purchases.
    await Future<void>.delayed(const Duration(seconds: 5));
    await refreshBotPremium();
    return SubscriptionService.isSubscribed;
  }

  @override
  Future<void> refreshBotPremium() async {
    await SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true);
  }

  @override
  bool isFeatureComingSoon(ui.PremiumCapability capability) =>
      PremiumCapabilities.isFeatureComingSoon(capability);

  @override
  String? get termsUrl => Platform.isIOS
      ? 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'
      : 'https://play.google.com/intl/en_us/about/play-terms/';

  // ── Crédits IA ────────────────────────────────────────────────────────────

  @override
  bool get canOpenAiCredits => true;

  @override
  bool get hasRewardedAds => Platform.isAndroid || Platform.isIOS;

  @override
  void openAiCredits(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AICreditsPage()));
  }
}

/// Les crédits IA tels que l'app les lit : `MainApiClient` (celui du Copilot
/// quand l'écran en reçoit un, sinon la session locale), publicités
/// récompensées, roulette et achat des packs en boutique.
class AppAiCreditsHost extends ui.AiCreditsHost {
  AppAiCreditsHost({this.api});

  final MainApiClient? api;

  MainApiClient? _client;
  String? _owner;

  Future<MainApiClient> _resolve() async {
    final cached = _client;
    if (cached != null) return cached;
    final given = api;
    if (given != null) {
      _owner = given.accountOwnerId;
      return _client = given;
    }
    final config = await MainApiSettingsStore.loadConfig();
    final session = await MainApiSettingsStore.loadSession();
    if (!config.isConfigured ||
        session == null ||
        session.isExpired ||
        session.userId == null) {
      throw StateError('Sign in to your Bot Creator account');
    }
    _owner = session.userId;
    return _client = MainApiClient(
      baseUrl: config.baseUrl,
      accessToken: session.accessToken,
    );
  }

  @override
  Future<Map<String, dynamic>> wallet() async =>
      (await _resolve()).getAIWallet();

  @override
  Future<Map<String, dynamic>> ledger({int offset = 0}) async =>
      (await _resolve()).getAILedger(offset: offset);

  // ── Roulette et publicités ────────────────────────────────────────────────

  @override
  String? get rewardsPlatform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return null;
  }

  @override
  Future<ui.AiRewardAdOutcome> watchRewardAd() async {
    final platform = rewardsPlatform;
    final client = await _resolve();
    final owner = _owner;
    if (platform == null || owner == null) {
      return ui.AiRewardAdOutcome.abandoned;
    }
    final ticket = await client.createAIRewardTicket(platform);
    final id = ticket['id'] as String;
    final bool completed;
    try {
      completed = await showAIRewardAd(
        adUnit: ticket['ad_unit'] as String,
        owner: owner,
        ticket: id,
      );
    } catch (_) {
      // Pas de pub (chargement échoué, délai dépassé) : sans ça le ticket
      // garde l'une des 3 pubs du jour pendant 15 minutes pour rien.
      await _releaseTicket(client, id);
      rethrow;
    }
    if (!completed) {
      await _releaseTicket(client, id);
      return ui.AiRewardAdOutcome.abandoned;
    }
    for (var attempt = 0; attempt < 20; attempt++) {
      final state = await client.getAIRewardTicket(id);
      if ((state['spins'] as num? ?? 0) > 0) {
        return ui.AiRewardAdOutcome.credited;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return ui.AiRewardAdOutcome.pending;
  }

  Future<void> _releaseTicket(MainApiClient client, String id) async {
    try {
      await client.cancelAIRewardTicket(id);
    } catch (_) {
      // Best effort : le ticket expire de lui-même.
    }
  }

  @override
  Future<Map<String, dynamic>> spin(String idempotencyKey) async =>
      (await _resolve()).spinAIRoulette(idempotencyKey);

  // ── Packs ─────────────────────────────────────────────────────────────────

  final Map<String, ConsumablePack> _packs = {};

  @override
  Future<List<ui.AiCreditsPack>> loadPacks(String locale) async {
    final packs = await ConsumablePurchaseService.loadPacks();
    _packs
      ..clear()
      ..addEntries(packs.map((p) => MapEntry(p.product.id, p)));
    return [
      for (final pack in packs)
        ui.AiCreditsPack(
          id: pack.product.id,
          title: pack.offer.text(locale, 'en')?.title ?? pack.product.title,
          price: pack.product.price,
          credits: pack.credits,
        ),
    ];
  }

  @override
  Future<bool> buyPack(ui.AiCreditsPack pack) async {
    final found = _packs[pack.id];
    if (found == null) return false;
    return ConsumablePurchaseService.buy(found);
  }

  @override
  Stream<ui.AiCreditsPackEvent> get packEvents =>
      ConsumablePurchaseService.events.map(
        (event) => switch (event.kind) {
          ConsumableEventKind.credited => ui.AiCreditsPackEvent.credited,
          ConsumableEventKind.failed => ui.AiCreditsPackEvent.failed,
          ConsumableEventKind.pending => ui.AiCreditsPackEvent.pending,
        },
      );

  // ── Conversation ──────────────────────────────────────────────────────────

  @override
  bool get canOpenConversation => true;

  @override
  void openConversation(BuildContext context, String conversationId) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            CopilotPage(api: _client, initialConversationId: conversationId),
      ),
    );
  }
}
