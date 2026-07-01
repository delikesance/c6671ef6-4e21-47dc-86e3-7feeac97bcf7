import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
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

  @override
  Widget build(BuildContext context) {
    if (!_canShowPurchase) {
      return const SizedBox.shrink();
    }

    final tr = context.tr;

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

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final atLimit = eligibility.activeContainers >= eligibility.maxContainers;
    final minutes = eligibility.hostingMinutesBalance;
    final reward = eligibility.adRewardMinutes;
    final expiry = _formatExpiry(context);

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
              showTopUpHint
                  ? tr.container_hosted_topup_ad_hint(reward)
                  : atLimit
                  ? tr.container_hosted_at_limit_open_detail(
                      eligibility.activeContainers,
                      eligibility.maxContainers,
                    )
                  : minutes > 0
                  ? tr.container_hosted_minutes_available(minutes)
                  : tr.container_hosted_watch_ad_earn(reward),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
            if (onWatchAd != null) ...[
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
            if (minutes > 0 && showTopUpHint) ...[
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
