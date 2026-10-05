import 'dart:async';
import 'dart:io';

import 'package:bot_creator/core/analytics/monetization_funnel.dart';
import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';

import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/commerce_catalog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/features/documentation/documentation_urls.dart';

import 'package:bot_creator/core/widgets/app_icon.dart';

/// Full-screen page (or bottom-sheet) for purchasing a premium subscription.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  /// Show the subscription page as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    if (!SubscriptionService.supportsNativeBilling) {
      // Repli explicite : sans `ScaffoldMessenger` (arbre pas encore monté,
      // écran détaché), l'échec est JOURNALISÉ — jamais avalé par un `?.` muet.
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) {
        unawaited(
          AppDiagnostics.logInfo(
            'Subscriptions: platform-unavailable message not shown '
            '(no ScaffoldMessenger)',
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(context.tr.subscription_not_available_on_platform),
          ),
        );
      }
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
      builder: (_) => const SubscriptionPage(),
    );
  }

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _purchasing = false;
  String? _error;
  CommerceCatalog? _catalog;
  bool _catalogLoading = true;
  bool? _subscribedOnOpen;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshEffectivePremiumStatus());
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    CommerceCatalog? catalog;
    try {
      catalog = await CommerceCatalog.load();
      final platform = Platform.isIOS ? 'ios' : 'android';
      final ids =
          catalog?.offers
              .where((o) => o.kind == 'subscription')
              .map((o) => o.nativeBinding(platform)?.productId)
              .whereType<String>()
              .toSet() ??
          <String>{};
      if (ids.isNotEmpty) await SubscriptionService.loadCatalogProducts(ids);
    } catch (_) {
      // A published catalog remains visible when the payment store is unavailable.
    }
    if (mounted) {
      setState(() {
        _catalog = catalog;
        _catalogLoading = false;
      });
    }
  }

  Future<void> _buyOffer(CommerceBinding binding) async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final result = await SubscriptionService.purchaseProduct(
        binding.productId,
        basePlanId: binding.basePlanId,
      );
      if (!result.started && mounted) {
        setState(
          () => _error = subscriptionPurchaseErrorKey(result.failureReason),
        );
      }
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  List<Widget> _remoteOffers(BuildContext context) {
    final catalog = _catalog!;
    final platform = Platform.isIOS ? 'ios' : 'android';
    final locale = Localizations.localeOf(context).toLanguageTag();
    final widgets = <Widget>[];
    for (final offer in catalog.offers) {
      if (offer.kind != 'subscription' ||
          !offer.visible(DateTime.now(), {'commerce.subscription.v1'})) {
        continue;
      }
      final text = offer.text(locale, catalog.defaultLocale)!;
      final binding = offer.nativeBinding(platform);
      final product = binding == null
          ? null
          : SubscriptionService.selectPurchaseCandidate(
              SubscriptionService.products,
              binding.productId,
              basePlanId: binding.basePlanId,
            );
      widgets.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text.title, style: Theme.of(context).textTheme.titleLarge),
                if (text.description.isNotEmpty) Text(text.description),
                for (final benefit in text.benefits)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const AppIcon.fromMaterial(Icons.check, size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(benefit)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                _PlanCard(
                  title: text.title,
                  price:
                      product?.price ??
                      context.tr.subscription_error_product_unavailable,
                  period: offer.period == 'year'
                      ? context.tr.subscription_per_year
                      : context.tr.subscription_per_month,
                  isPrimary: widgets.isEmpty,
                  onTap: _purchasing || product == null || binding == null
                      ? null
                      : () => _buyOffer(binding),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (widgets.isEmpty) {
      widgets.add(Text(context.tr.subscription_error_product_unavailable));
    }
    return widgets;
  }

  Future<void> _refreshEffectivePremiumStatus() async {
    await SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true);
    _subscribedOnOpen ??= SubscriptionService.isSubscribed;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _buy({required bool annual}) async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final result = annual
          ? await SubscriptionService.purchaseAnnual()
          : await SubscriptionService.purchaseMonthly();

      if (!result.started && mounted) {
        setState(
          () => _error = subscriptionPurchaseErrorKey(result.failureReason),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
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
      await SubscriptionService.restorePurchases();
      // Wait a moment for the stream to deliver restored purchases.
      await Future<void>.delayed(const Duration(seconds: 5));
      await _refreshEffectivePremiumStatus();
      if (mounted) {
        if (SubscriptionService.isSubscribed) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allFeatures = PremiumCapabilities.getAllFeaturesForSubscription();

    // Close automatically when subscription becomes active.
    if (_subscribedOnOpen == false && SubscriptionService.isSubscribed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        final savingsPercent = _calculateAnnualSavingsPercent();
        final annualBadge = savingsPercent != null
            ? context.tr.subscription_save_badge(savingsPercent)
            : null;

        return SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(
            24,
            12,
            24,
            32 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            children: [
              // Drag handle
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

              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.premiumGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const AppIcon.fromMaterial(
                  Icons.workspace_premium_rounded,
                  size: 48,
                  color: AppTheme.premiumGold,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                context.tr.subscription_title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr.subscription_subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              if (_catalogLoading)
                const CircularProgressIndicator()
              else if (_catalog != null)
                ..._remoteOffers(context)
              else ...[
                // Benefits (exhaustive premium feature list)
                ...allFeatures.asMap().entries.map((entry) {
                  final feature = entry.value;
                  final comingSoon = PremiumCapabilities.isFeatureComingSoon(
                    feature.capability,
                  );
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: entry.key == allFeatures.length - 1 ? 0 : 10,
                    ),
                    child: _BenefitRow(
                      icon: feature.icon,
                      text: feature.title(context.tr),
                      subtitle: feature.description(context.tr),
                      comingSoon: comingSoon,
                    ),
                  );
                }),
                const SizedBox(height: 28),

                // Annual plan (recommended)
                _PlanCard(
                  title: context.tr.subscription_annual_title,
                  price: _priceForProduct(kAnnualSubscriptionId, '59,99 €'),
                  period: context.tr.subscription_per_year,
                  badge: annualBadge,
                  isPrimary: true,
                  onTap: _purchasing ? null : () => _buy(annual: true),
                ),
                const SizedBox(height: 12),

                // Monthly plan
                _PlanCard(
                  title: context.tr.subscription_monthly_title,
                  price: _priceForProduct(kMonthlySubscriptionId, '5,99 €'),
                  period: context.tr.subscription_per_month,
                  isPrimary: false,
                  onTap: _purchasing ? null : () => _buy(annual: false),
                ),
              ],
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

              const SizedBox(height: 8),

              // Restore purchases
              TextButton(
                onPressed: _purchasing ? null : _restore,
                child: Text(context.tr.subscription_restore),
              ),
              const SizedBox(height: 8),

              // Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegalLink(
                    label: context.tr.subscription_terms,
                    url: _termsUrl,
                  ),
                  const SizedBox(width: 16),
                  _LegalLink(
                    label: context.tr.subscription_privacy,
                    url: _privacyUrl,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _priceForProduct(String productId, String fallback) {
    final product = SubscriptionService.products.cast<dynamic>().firstWhere(
      (p) => p.id == productId,
      orElse: () => null,
    );
    if (product != null) return product.price as String;
    return fallback;
  }

  double? _extractPriceAmount(String productId, String fallback) {
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

  int? _calculateAnnualSavingsPercent() {
    final annualAmount = _extractPriceAmount(kAnnualSubscriptionId, '59,99 €');
    final monthlyAmount = _extractPriceAmount(kMonthlySubscriptionId, '5,99 €');
    return SubscriptionService.calculateAnnualSavingsPercent(
      annualPrice: annualAmount,
      monthlyPrice: monthlyAmount,
      minThresholdPercent: 10,
    );
  }

  static String get _termsUrl {
    if (!kIsWeb && Platform.isIOS) {
      return 'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
    }
    return 'https://play.google.com/intl/en_us/about/play-terms/';
  }

  static const String _privacyUrl = privacyPolicyUrl;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({
    required this.icon,
    required this.text,
    required this.subtitle,
    this.comingSoon = false,
  });

  final IconData icon;
  final String text;
  final String subtitle;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIcon.fromMaterial(icon, size: 22, color: AppTheme.premiumGold),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (comingSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusPill,
                        ),
                      ),
                      child: Text(
                        context.tr.subscription_feature_coming_soon,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.period,
    required this.isPrimary,
    this.badge,
    this.onTap,
  });

  final String title;
  final String price;
  final String period;
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
            ? const BorderSide(color: AppTheme.premiumGold, width: 2)
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
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
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
                              color: AppTheme.premiumGold,
                              borderRadius: BorderRadius.circular(
                                AppTheme.radiusPill,
                              ),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      period,
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
                  color: isPrimary ? AppTheme.premiumGold : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.url});
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          decoration: TextDecoration.underline,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
