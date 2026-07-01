import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:bot_creator/core/i18n/i18n.dart';

/// Centralized premium capability matrix used to gate paid features.
enum PremiumCapability {
  noAds,
  instantStart,
  analyticsExpanded,
  schedulerTriggers,
  inboundWebhooks,
  visualDebuggerReplay,
  autoSharding,

  /// Automatically restart the bot after a config change that cannot be
  /// hot-reloaded (e.g. gateway intent changes, new token).
  autoRestart,
  lavalinkAudio,

  /// Deploy and manage Docker containers (Hosted Applications).
  hostedApps,
}

class PremiumFeatureDefinition {
  const PremiumFeatureDefinition({
    required this.capability,
    required this.icon,
    required this.title,
    required this.description,
    this.coreBenefit = false,
  });

  final PremiumCapability capability;
  final IconData icon;
  final String Function(AppLocalizations tr) title;
  final String Function(AppLocalizations tr) description;

  /// Core benefits are always shown in the subscription list.
  final bool coreBenefit;
}

class PremiumCapabilities {
  PremiumCapabilities._();

  static final List<PremiumFeatureDefinition> _featureDefinitions = [
    PremiumFeatureDefinition(
      capability: PremiumCapability.noAds,
      icon: Icons.block_rounded,
      title: (tr) => tr.subscription_feature_no_ads_title,
      description: (tr) => tr.subscription_feature_no_ads_desc,
      coreBenefit: true,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.instantStart,
      icon: Icons.flash_on_rounded,
      title: (tr) => tr.subscription_feature_instant_start_title,
      description: (tr) => tr.subscription_feature_instant_start_desc,
      coreBenefit: true,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.analyticsExpanded,
      icon: Icons.insights_rounded,
      title: (tr) => tr.subscription_feature_analytics_title,
      description: (tr) => tr.subscription_feature_analytics_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.schedulerTriggers,
      icon: Icons.schedule_rounded,
      title: (tr) => tr.subscription_feature_scheduler_title,
      description: (tr) => tr.subscription_feature_scheduler_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.inboundWebhooks,
      icon: Icons.hub_rounded,
      title: (tr) => tr.subscription_feature_webhooks_title,
      description: (tr) => tr.subscription_feature_webhooks_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.visualDebuggerReplay,
      icon: Icons.play_circle_outline_rounded,
      title: (tr) => tr.subscription_feature_debug_replay_title,
      description: (tr) => tr.subscription_feature_debug_replay_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.autoSharding,
      icon: Icons.account_tree_rounded,
      title: (tr) => tr.subscription_feature_auto_sharding_title,
      description: (tr) => tr.subscription_feature_auto_sharding_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.autoRestart,
      icon: Icons.autorenew_rounded,
      title: (tr) => tr.subscription_feature_auto_restart_title,
      description: (tr) => tr.subscription_feature_auto_restart_desc,
    ),
    PremiumFeatureDefinition(
      capability: PremiumCapability.lavalinkAudio,
      icon: Icons.music_note_rounded,
      title: (tr) => tr.subscription_feature_lavalink_title,
      description: (tr) => tr.subscription_feature_lavalink_desc,
    ),
  ];

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

  static bool hasCapability(PremiumCapability capability) {
    if (capability == PremiumCapability.noAds ||
        capability == PremiumCapability.instantStart) {
      return isPremiumUser;
    }
    return isPremiumUser && isCapabilityRolledOut(capability);
  }

  static List<PremiumFeatureDefinition> getAllFeaturesForSubscription() {
    return List<PremiumFeatureDefinition>.unmodifiable(_featureDefinitions);
  }

  static bool isFeatureComingSoon(PremiumCapability capability) {
    return !isCapabilityRolledOut(capability);
  }

  static int limitFor(PremiumCapability capability) {
    switch (capability) {
      case PremiumCapability.noAds:
      case PremiumCapability.instantStart:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.analyticsExpanded:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.schedulerTriggers:
        return isPremiumUser ? 10 : 0;
      case PremiumCapability.inboundWebhooks:
        return isPremiumUser ? 5 : 0;
      case PremiumCapability.visualDebuggerReplay:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.autoSharding:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.autoRestart:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.lavalinkAudio:
        return isPremiumUser ? 1 : 0;
      case PremiumCapability.hostedApps:
        return isPremiumUser ? 2 : 0;
    }
  }

  static bool get canShowPurchaseUI =>
      SubscriptionService.supportsNativeBilling && !isPremiumUser;
}
