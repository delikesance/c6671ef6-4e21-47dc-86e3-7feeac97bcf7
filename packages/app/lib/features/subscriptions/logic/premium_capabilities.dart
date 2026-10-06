import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart'
    show PremiumCapability, PremiumFeatureDefinition, premiumFeatureDefinitions;
import 'package:flutter/foundation.dart';

// L'énumération des capacités, la définition d'un avantage et la liste exhaustive
// affichée par l'écran d'abonnement vivent dans `bot_creator_ui` (partagées avec le
// Studio) ; l'app y garde les règles de plafond et de déploiement.
export 'package:bot_creator_ui/src/subscriptions/premium_features.dart'
    show PremiumCapability, PremiumFeatureDefinition;

/// Centralized premium capability matrix used to gate paid features.
class PremiumCapabilities {
  PremiumCapabilities._();

  // Rollout flags for roadmap capabilities. Keep disabled until implemented.
  static const Map<PremiumCapability, bool> _rolloutEnabled = {
    PremiumCapability.noAds: true,
    PremiumCapability.instantStart: true,
    PremiumCapability.analyticsExpanded: true,
    PremiumCapability.schedulerTriggers: true,
    PremiumCapability.inboundWebhooks: true,
    PremiumCapability.visualDebuggerReplay: true,
    PremiumCapability.autoSharding: true,
    PremiumCapability.autoRestart: true,
    PremiumCapability.lavalinkAudio: true,
    PremiumCapability.hostedApps: true,
  };

  static bool get isPremiumUser =>
      (kDebugMode && debugPremiumBypass) || SubscriptionService.isSubscribed;

  /// Debug-only toggle that bypasses Premium gating for all features.
  /// Only effective when [kDebugMode] is true.
  static bool debugPremiumBypass = false;

  static bool isCapabilityRolledOut(PremiumCapability capability) {
    return _rolloutEnabled[capability] ?? false;
  }

  static bool get hostedAppsRolloutEnabled =>
      isCapabilityRolledOut(PremiumCapability.hostedApps);

  static bool hasCapability(PremiumCapability capability) {
    if (capability == PremiumCapability.noAds ||
        capability == PremiumCapability.instantStart) {
      return isPremiumUser;
    }
    if (capability == PremiumCapability.hostedApps) {
      return isPremiumUser && isCapabilityRolledOut(capability);
    }
    return isPremiumUser && isCapabilityRolledOut(capability);
  }

  static List<PremiumFeatureDefinition> getAllFeaturesForSubscription() {
    return List<PremiumFeatureDefinition>.unmodifiable(
      premiumFeatureDefinitions,
    );
  }

  static bool isFeatureComingSoon(PremiumCapability capability) {
    return !isCapabilityRolledOut(capability);
  }

  static int limitFor(PremiumCapability capability) =>
      _limitFor(capability, premium: isPremiumUser);

  /// Le plafond de la formule PAYANTE, quelle que soit la formule actuelle du compte.
  ///
  /// Sert à la règle « ce que l'appareil exécute ne dépend pas de la formule » : quand
  /// le bot tourne sur la machine de l'utilisateur, la capacité n'est plus une ressource
  /// du serveur. Ouvrir l'écran sans relever le plafond laisserait un bouton « Ajouter »
  /// visible qui refuse toute création — pire qu'un cadenas. Le chiffre reste ICI, à un
  /// seul endroit : personne ne le recopie ailleurs.
  static int premiumLimitFor(PremiumCapability capability) =>
      _limitFor(capability, premium: true);

  static int _limitFor(PremiumCapability capability, {required bool premium}) {
    switch (capability) {
      case PremiumCapability.noAds:
      case PremiumCapability.instantStart:
        return premium ? 1 : 0;
      case PremiumCapability.analyticsExpanded:
        return premium ? 1 : 0;
      case PremiumCapability.schedulerTriggers:
        return premium ? 10 : 0;
      case PremiumCapability.inboundWebhooks:
        return premium ? 5 : 0;
      case PremiumCapability.visualDebuggerReplay:
        return premium ? 1 : 0;
      case PremiumCapability.autoSharding:
        return premium ? 1 : 0;
      case PremiumCapability.autoRestart:
        return premium ? 1 : 0;
      case PremiumCapability.lavalinkAudio:
        return premium ? 1 : 0;
      case PremiumCapability.hostedApps:
        return premium ? 2 : 1;
    }
  }

  static bool get canShowPurchaseUI =>
      SubscriptionService.supportsNativeBilling && !isPremiumUser;
}
