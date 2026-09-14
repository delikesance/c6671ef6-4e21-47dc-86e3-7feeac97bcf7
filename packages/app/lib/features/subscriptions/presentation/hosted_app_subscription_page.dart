import 'dart:async';

import 'package:bot_creator/core/analytics/monetization_funnel.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_billing_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for hosted Docker container subscriptions (host_one_app / host_two_app).
class HostedAppSubscriptionPage extends StatefulWidget {
  const HostedAppSubscriptionPage({super.key});

  static Future<void> show(BuildContext context) {
    if (!SubscriptionService.supportsNativeBilling) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(context.tr.subscription_not_available_on_platform),
        ),
      );
      return Future<void>.value();
    }

    unawaited(MonetizationFunnel.subscriptionPageView());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const HostedAppSubscriptionPage(),
    );
  }

  @override
  State<HostedAppSubscriptionPage> createState() =>
      _HostedAppSubscriptionPageState();
}

class _HostedAppSubscriptionPageState extends State<HostedAppSubscriptionPage> {
  bool _purchasing = false;
  String? _error;

  Future<void> _buy(String productId) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final result = productId == kHostTwoAppSubscriptionId
          ? await HostedAppSubscriptionService.purchaseTwoApps()
          : await HostedAppSubscriptionService.purchaseOneApp();

      if (!result.started && mounted) {
        setState(
          () => _error = subscriptionPurchaseErrorKey(result.failureReason),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      await HostedAppSubscriptionService.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 4));
      if (mounted) {
        if (HostedAppSubscriptionService.isSubscribed) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr.subscription_restored)),
          );
        } else {
          setState(() => _error = context.tr.subscription_restore_not_found);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  String _priceForTier(HostedAppTier tier, String fallback) {
    final listing = HostedAppSubscriptionService.listingFor(tier);
    if (listing != null) {
      return listing.productDetails.price;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tr = context.tr;

    if (HostedAppSubscriptionService.isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  size: 48,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tr.hosted_app_subscription_title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                tr.hosted_app_subscription_subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _BenefitRow(
                icon: Icons.all_inclusive,
                text: tr.hosted_app_subscription_benefit_unlimited,
              ),
              const SizedBox(height: 10),
              _BenefitRow(
                icon: Icons.block_rounded,
                text: tr.hosted_app_subscription_benefit_no_ads,
              ),
              const SizedBox(height: 24),
              _PlanCard(
                title: tr.hosted_app_subscription_two_app_title,
                subtitle: tr.hosted_app_subscription_two_app_desc,
                price: _priceForTier(HostedAppTier.twoApps, '—'),
                badge: tr.hosted_app_subscription_recommended,
                isPrimary: true,
                onTap: _purchasing
                    ? null
                    : () => _buy(kHostTwoAppSubscriptionId),
              ),
              const SizedBox(height: 12),
              _PlanCard(
                title: tr.hosted_app_subscription_one_app_title,
                subtitle: tr.hosted_app_subscription_one_app_desc,
                price: _priceForTier(HostedAppTier.oneApp, '—'),
                isPrimary: false,
                onTap: _purchasing
                    ? null
                    : () => _buy(kHostOneAppSubscriptionId),
              ),
              const SizedBox(height: 16),
              if (_purchasing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CircularProgressIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
              TextButton(
                onPressed: _purchasing ? null : _restore,
                child: Text(tr.subscription_restore),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.teal),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.isPrimary,
    this.badge,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String price;
  final String? badge;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isPrimary ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: isPrimary
            ? const BorderSide(color: Colors.teal, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.teal,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                price,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPrimary ? Colors.teal : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
