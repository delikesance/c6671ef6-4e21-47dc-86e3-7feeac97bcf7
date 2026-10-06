import 'dart:async';

import 'package:flutter/material.dart';

import '../docs/documentation_urls.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../utils/external_link.dart';
import '../widgets/app_icon.dart';
import 'commerce_models.dart';
import 'premium_features.dart';
import 'subscriptions_host.dart';

/// Page (feuille modale) des offres Premium : ce que l'abonnement apporte et,
/// quand l'hôte sait acheter ([SubscriptionsHost.canPurchase]), les prix et
/// l'achat. Sans achat possible (Studio), les offres et leurs avantages restent
/// lisibles, avec la phrase « disponible sur mobile seulement » de l'app.
class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({required this.host, super.key});

  final SubscriptionsHost host;

  /// Affiche la page des offres en feuille modale.
  static Future<void> show(BuildContext context, SubscriptionsHost host) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SubscriptionPage(host: host),
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

  SubscriptionsHost get _host => widget.host;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshEffectivePremiumStatus());
    unawaited(_loadCatalog());
  }

  Future<void> _loadCatalog() async {
    CommerceCatalog? catalog;
    try {
      catalog = await _host.loadCommerce();
      if (catalog != null && _host.canPurchase) {
        await _host.prepareOffers(catalog);
      }
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

  /// Une clé `subscription_error_*` du contrat d'hôte, en texte localisé.
  String _errorText(String key) {
    final tr = context.tr;
    return switch (key) {
      'subscription_error_store_unavailable' =>
        tr.subscription_error_store_unavailable,
      'subscription_error_product_unavailable' =>
        tr.subscription_error_product_unavailable,
      'subscription_error_purchase_start_failed' =>
        tr.subscription_error_purchase_start_failed,
      _ => tr.subscription_error,
    };
  }

  Future<void> _purchase(Future<String?> Function() start) async {
    if (_purchasing) return;
    setState(() {
      _purchasing = true;
      _error = null;
    });
    try {
      final errorKey = await start();
      if (errorKey != null && mounted) {
        setState(() => _error = _errorText(errorKey));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _purchasing = false);
    }
  }

  /// Les offres visibles de l'abonnement Bot Premium dans le catalogue publié.
  List<CommerceOffer> _visibleOffers() => [
    for (final offer in _catalog?.offers ?? const <CommerceOffer>[])
      if (offer.kind == 'subscription' &&
          offer.visible(DateTime.now(), {'commerce.subscription.v1'}))
        offer,
  ];

  List<Widget> _remoteOffers(BuildContext context, List<CommerceOffer> offers) {
    final catalog = _catalog!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final canPurchase = _host.canPurchase;
    final widgets = <Widget>[];
    for (final offer in offers) {
      final text = offer.text(locale, catalog.defaultLocale)!;
      final price = canPurchase ? _host.priceForOffer(offer) : null;
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
                if (canPurchase) ...[
                  const SizedBox(height: 12),
                  _PlanCard(
                    title: text.title,
                    price:
                        price ??
                        context.tr.subscription_error_product_unavailable,
                    period: offer.period == 'year'
                        ? context.tr.subscription_per_year
                        : context.tr.subscription_per_month,
                    isPrimary: widgets.isEmpty,
                    onTap: _purchasing || price == null
                        ? null
                        : () => _purchase(() => _host.purchaseOffer(offer)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Future<void> _refreshEffectivePremiumStatus() async {
    await _host.refreshBotPremium();
    _subscribedOnOpen ??= _host.isBotSubscribed;
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _restore() async {
    setState(() {
      _purchasing = true;
      _error = null;
    });

    try {
      final restored = await _host.restoreBotPurchases();
      if (mounted) {
        if (restored) {
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

  List<Widget> _featureList(BuildContext context) {
    final allFeatures = premiumFeatureDefinitions;
    return [
      // Benefits (exhaustive premium feature list)
      ...allFeatures.asMap().entries.map((entry) {
        final feature = entry.value;
        final comingSoon = _host.isFeatureComingSoon(feature.capability);
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPurchase = _host.canPurchase;

    // Close automatically when subscription becomes active.
    if (_subscribedOnOpen == false && _host.isBotSubscribed) {
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
        final savingsPercent = canPurchase
            ? _host.annualSavingsPercent()
            : null;
        final annualBadge = savingsPercent != null
            ? context.tr.subscription_save_badge(savingsPercent)
            : null;
        final offers = _visibleOffers();
        // Catalogue publié : ses offres. Sans catalogue (ou, en lecture seule,
        // sans offre visible) : la liste exhaustive des avantages.
        final showOffers =
            !_catalogLoading &&
            _catalog != null &&
            (canPurchase || offers.isNotEmpty);

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
              else if (showOffers) ...[
                ..._remoteOffers(context, offers),
                if (canPurchase && offers.isEmpty)
                  Text(context.tr.subscription_error_product_unavailable),
              ] else ...[
                ..._featureList(context),
                if (canPurchase) ...[
                  const SizedBox(height: 28),

                  // Annual plan (recommended)
                  _PlanCard(
                    title: context.tr.subscription_annual_title,
                    price: _host.priceForBotPlan(
                      BotStoreCadence.annual,
                      '59,99 €',
                    ),
                    period: context.tr.subscription_per_year,
                    badge: annualBadge,
                    isPrimary: true,
                    onTap: _purchasing
                        ? null
                        : () => _purchase(
                            () => _host.purchaseBotPlan(BotStoreCadence.annual),
                          ),
                  ),
                  const SizedBox(height: 12),

                  // Monthly plan
                  _PlanCard(
                    title: context.tr.subscription_monthly_title,
                    price: _host.priceForBotPlan(
                      BotStoreCadence.monthly,
                      '5,99 €',
                    ),
                    period: context.tr.subscription_per_month,
                    isPrimary: false,
                    onTap: _purchasing
                        ? null
                        : () => _purchase(
                            () =>
                                _host.purchaseBotPlan(BotStoreCadence.monthly),
                          ),
                  ),
                ],
              ],
              const SizedBox(height: 16),

              if (!canPurchase)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    context.tr.subscription_not_available_on_platform,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

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
              if (canPurchase)
                TextButton(
                  onPressed: _purchasing ? null : _restore,
                  child: Text(context.tr.subscription_restore),
                ),
              const SizedBox(height: 8),

              // Legal links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_host.termsUrl != null) ...[
                    _LegalLink(
                      label: context.tr.subscription_terms,
                      url: _host.termsUrl!,
                    ),
                    const SizedBox(width: 16),
                  ],
                  _LegalLink(
                    label: context.tr.subscription_privacy,
                    url: privacyPolicyUrl,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
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
      onTap: () => openExternalUrl(Uri.parse(url)),
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
