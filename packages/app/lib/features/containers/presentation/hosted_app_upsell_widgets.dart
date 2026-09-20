import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscriptions_hub_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Premium upsell shown when free users hit the hosted-app container limit.
class HostedAppPremiumUpsell extends StatelessWidget {
  const HostedAppPremiumUpsell({
    super.key,
    this.compact = false,
    this.eligibility,
  });

  final bool compact;
  final HostedAppEligibility? eligibility;

  bool get _hasHostedAppSubscription => eligibility?.premium == true;

  bool get _canShowPurchase =>
      SubscriptionService.supportsNativeBilling && !_hasHostedAppSubscription;

  /// Le desktop n'a AUCUNE boutique native : il n'y a donc pas d'achat à
  /// proposer, mais les FORMULES restent consultables. L'écran desktop y renvoie
  /// explicitement au lieu de disparaître — et ne propose jamais de publicité,
  /// qui n'existe pas sur cette plateforme.
  bool get _isDesktop => isDesktopRunPlatform;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;

    if (_isDesktop) {
      if (compact) {
        return OutlinedButton.icon(
          onPressed: () => SubscriptionsHubPage.open(context),
          icon: const Icon(Icons.workspace_premium_outlined, color: Colors.teal),
          label: Text(tr.container_hosted_premium_view_btn),
        );
      }
      return Card(
        color: Colors.teal.withValues(alpha: 0.08),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.workspace_premium_outlined,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr.container_hosted_premium_host_anytime,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                tr.container_hosted_premium_desc,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => SubscriptionsHubPage.open(context),
                icon: const Icon(Icons.workspace_premium_outlined),
                label: Text(tr.container_hosted_premium_view_btn),
              ),
            ],
          ),
        ),
      );
    }

    if (!_canShowPurchase) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return FilledButton.tonalIcon(
        onPressed: () => HostedAppSubscriptionPage.show(context),
        icon: const Icon(Icons.storage_rounded, color: Colors.teal),
        label: Text(tr.container_hosted_premium_host_anytime_compact),
      );
    }

    return Card(
      color: Colors.teal.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.storage_rounded, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.container_hosted_premium_host_anytime,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tr.container_hosted_premium_desc,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => HostedAppSubscriptionPage.show(context),
              icon: const Icon(Icons.storage_rounded),
              label: Text(tr.container_hosted_premium_view_btn),
            ),
          ],
        ),
      ),
    );
  }
}

/// Free-tier hosting status + ad top-up controls.
class HostedAppFreeHostingBanner extends StatelessWidget {
  const HostedAppFreeHostingBanner({
    super.key,
    required this.eligibility,
    required this.claimingAd,
    required this.onWatchAd,
    this.showTopUpHint = false,
    this.expiresAt,
  });

  final HostedAppEligibility eligibility;
  final bool claimingAd;
  final VoidCallback? onWatchAd;
  final bool showTopUpHint;
  final DateTime? expiresAt;

  String? _formatExpiry(BuildContext context) {
    if (expiresAt == null) return null;
    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat.yMMMd(locale).add_jm().format(expiresAt!.toLocal());
    return context.tr.container_hosted_expires_at(formatted);
  }

  bool get _hasRemainingContainerTime {
    if (expiresAt == null) return false;
    return expiresAt!.toUtc().isAfter(DateTime.now().toUtc());
  }

  /// Le desktop ne diffuse AUCUNE publicité : il n'y a donc rien à « regarder
  /// pour gagner du temps ». Le temps d'hébergement y vient du SOLDE SERVEUR
  /// (`hosting_minutes_balance`), qui contient déjà les minutes gagnées par pub
  /// sur mobile — on l'affiche tel quel, et on ne propose jamais de pub.
  bool get _offersRewardedAds => !isDesktopRunPlatform;

  bool get _showsAdButton => _offersRewardedAds && onWatchAd != null;

  /// Message d'état. Sur desktop, il ne cite QUE des faits servis par le serveur
  /// (solde de minutes, plafond de la formule) : aucun libellé de publicité.
  String _statusMessage(
    AppLocalizations tr, {
    required bool atLimit,
    required bool hasRemainingTime,
    required int minutes,
    required int reward,
  }) {
    if (!_offersRewardedAds) {
      if (hasRemainingTime) return tr.container_hosted_resume_with_time;
      if (atLimit) return tr.container_deploy_blocked_container_limit;
      return tr.container_hosted_minutes_available(minutes);
    }
    return showTopUpHint
        ? tr.container_hosted_topup_ad_hint(reward)
        : hasRemainingTime
        ? tr.container_hosted_resume_with_time
        : atLimit
        ? tr.container_hosted_at_limit_open_detail(
            eligibility.activeContainers,
            eligibility.maxContainers,
          )
        : minutes > 0
        ? tr.container_hosted_minutes_available(minutes)
        : tr.container_hosted_watch_ad_earn(reward);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final atLimit = eligibility.activeContainers >= eligibility.maxContainers;
    final minutes = eligibility.hostingMinutesBalance;
    final reward = eligibility.adRewardMinutes;
    final expiry = _formatExpiry(context);
    final hasRemainingTime = _hasRemainingContainerTime;

    return Card(
      color: Colors.teal.withValues(alpha: 0.08),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr.container_hosted_free_title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (expiry != null) ...[
              Text(
                expiry,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              _statusMessage(
                tr,
                atLimit: atLimit,
                hasRemainingTime: hasRemainingTime,
                minutes: minutes,
                reward: reward,
              ),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (_showsAdButton) ...[
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: claimingAd ? null : onWatchAd,
                icon: claimingAd
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(tr.container_hosted_ad_button(reward)),
              ),
            ],
            if (_offersRewardedAds && minutes > 0 && showTopUpHint) ...[
              const SizedBox(height: 6),
              Text(
                tr.container_hosted_balance_after_ad(minutes),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
