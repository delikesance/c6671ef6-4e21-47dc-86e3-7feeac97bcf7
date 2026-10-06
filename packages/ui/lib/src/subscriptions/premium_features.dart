import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

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

/// La liste exhaustive des avantages Premium, dans l'ordre d'affichage de l'écran
/// d'abonnement.
final List<PremiumFeatureDefinition> premiumFeatureDefinitions = [
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
