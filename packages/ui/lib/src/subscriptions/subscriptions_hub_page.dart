import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'commerce_models.dart';
import 'subscription_page.dart';
import 'subscriptions_host.dart';

/// Page centrale listant l'abonnement Bot Premium et la formule d'hébergement,
/// avec ce que chacune accorde. Partagée entre l'app et le Studio ; ce que la
/// plateforme ne sait pas faire (acheter, restaurer, gérer) est une capacité du
/// [SubscriptionsHost] et l'écran masque l'action.
class SubscriptionsHubPage extends StatefulWidget {
  const SubscriptionsHubPage({required this.host, super.key});

  final SubscriptionsHost host;

  static Future<void> open(BuildContext context, SubscriptionsHost host) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => SubscriptionsHubPage(host: host)),
    );
  }

  @override
  State<SubscriptionsHubPage> createState() => _SubscriptionsHubPageState();
}

class _SubscriptionsHubPageState extends State<SubscriptionsHubPage> {
  bool _loading = true;
  bool _busy = false;
  CommerceCatalog? _commerce;
  late SubscriptionsSnapshot _snapshot = widget.host.current;

  SubscriptionsHost get _host => widget.host;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final results = await Future.wait<Object?>([
      _host.refresh(),
      _host.loadCommerce(),
    ]);
    if (!mounted) return;
    setState(() {
      _snapshot = results[0]! as SubscriptionsSnapshot;
      _commerce = results[1] as CommerceCatalog?;
      _loading = false;
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _upgrade(Future<String?> Function() purchase) async {
    await _runBusy(() async {
      final errorKey = await purchase();
      if (errorKey != null && mounted) _showError(errorKey);
    });
  }

  Future<void> _restoreAll() async {
    await _runBusy(() async {
      await _host.restorePurchases();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr.subscription_restore)),
        );
      }
    });
  }

  void _showError(String messageKey) {
    final tr = context.tr;
    final text = switch (messageKey) {
      'subscription_error_store_unavailable' =>
        tr.subscription_error_store_unavailable,
      'subscription_error_product_unavailable' =>
        tr.subscription_error_product_unavailable,
      'subscription_error_purchase_start_failed' =>
        tr.subscription_error_purchase_start_failed,
      _ => tr.subscription_error,
    };
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: Colors.red));
  }

  String _formatExpiry(BuildContext context, DateTime? expiresAt) {
    if (expiresAt == null) return context.tr.subscriptions_hub_permanent;
    final localized = expiresAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(localized);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localized));
    return context.tr.subscriptions_hub_expires_at(date, time);
  }

  /// Durée de la couverture hébergement. Un reçu du store porte sa propre échéance ;
  /// quand c'est une FORMULE serveur qui couvre, c'est le serveur qui sait — et s'il
  /// ne dit rien, on n'affiche RIEN. La carte annonçait « Permanent (no expiration) »
  /// dès que l'échéance était inconnue, y compris sur un octroi qui expirait : une
  /// affirmation fausse à l'écran.
  String? _hostingExpiryText(BuildContext context) {
    final s = _snapshot;
    if (s.hostedServerGranted) {
      final serverExpiry = s.hostingCoverageExpiresAt;
      if (serverExpiry != null) return _formatExpiry(context, serverExpiry);
      return s.hostingCoveragePermanent
          ? context.tr.subscriptions_hub_permanent
          : null;
    }
    return _formatExpiry(context, s.hostedStoreExpiresAt);
  }

  String _botPlanLabel(AppLocalizations tr) {
    final s = _snapshot;
    final maxBots = s.planMaxBots;
    final botsLimit = maxBots == null
        ? null
        : (maxBots == 0
              ? tr.subscriptions_hub_unlimited_bots
              : tr.subscriptions_hub_bots_max(maxBots));
    final customDisplayName = s.planDisplayName;

    // Le nom de la formule s'affiche sur la carte dont elle porte l'offre. Une formule qui
    // inclut les applications hébergées (type « Host One App ») est une offre d'hébergement :
    // son nom va sur la carte du bas. Sans cette règle, l'écran présentait une formule
    // d'applications hébergées comme l'abonnement Bot Premium — ici on n'annonce plus que la
    // capacité bot, qui elle est bien accordée.
    final nameBelongsToHostedCard = s.hostedServerGranted;

    if (customDisplayName != null &&
        customDisplayName.trim().isNotEmpty &&
        !nameBelongsToHostedCard) {
      return botsLimit == null
          ? customDisplayName
          : '$customDisplayName ($botsLimit)';
    }
    if (botsLimit != null) {
      return botsLimit;
    }
    return switch (s.botStoreCadence) {
      BotStoreCadence.annual => tr.subscription_active_annual,
      BotStoreCadence.monthly => tr.subscription_active_monthly,
      null => tr.subscription_plan_label,
    };
  }

  String _hostedPlanLabel(AppLocalizations tr) {
    final s = _snapshot;
    // Droit accordé par la formule du compte : c'est son nom qui décrit ce que l'utilisateur
    // a, avec le plafond qu'elle fixe (le serveur applique exactement ce chiffre au
    // démarrage).
    if (s.hostedServerGranted) {
      final formulaName = s.planDisplayName?.trim();
      final capability = switch (s.hostedMaxContainers) {
        null => null,
        1 => tr.hosted_app_subscription_one_app_title,
        _ => tr.hosted_app_subscription_two_app_title,
      };
      if (formulaName != null && formulaName.isNotEmpty) {
        return capability == null ? formulaName : '$formulaName · $capability';
      }
      if (capability != null) {
        return capability;
      }
    }
    return switch (s.hostedStoreTier) {
      HostedStoreTier.oneApp => tr.hosted_app_subscription_one_app_title,
      HostedStoreTier.twoApps => tr.hosted_app_subscription_two_app_title,
      null => tr.hosted_app_subscription_title,
    };
  }

  bool get _hasRewardedAiOffer =>
      _commerce?.offers.any(
        (o) =>
            o.kind == 'rewarded_ai' &&
            o.visible(DateTime.now(), {'commerce.ai_rewards.v1'}),
      ) ==
      true;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final s = _snapshot;
    final botActive = s.botActive;
    final hostedActive = s.hostedActive;
    final canPurchase = _host.canPurchase;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.subscriptions_hub_title),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _refresh,
            icon: const AppIcon.fromMaterial(Icons.refresh),
            tooltip: tr.common_refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  // Sans achat possible, les offres restent LISIBLES : le bouton
                  // ouvre la même page, en lecture seule.
                  if (_commerce != null || !canPurchase)
                    OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () => SubscriptionPage.show(context, _host),
                      child: Text(tr.plan_limit_view_offers),
                    ),
                  if (_host.canOpenAiCredits && _hasRewardedAiOffer)
                    ListTile(
                      leading: const AppIcon.fromMaterial(Icons.auto_awesome),
                      title: Text(
                        _host.hasRewardedAds
                            ? tr.subscriptions_hub_ai_credits_roulette
                            : tr.ai_credits_title,
                      ),
                      onTap: () => _host.openAiCredits(context),
                    ),
                  Text(
                    tr.subscriptions_hub_subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SubscriptionSectionCard(
                    icon: Icons.workspace_premium_rounded,
                    iconColor: AppTheme.premiumGold,
                    title: tr.subscriptions_hub_bot_premium_section,
                    description: tr.subscriptions_hub_bot_premium_desc,
                    isActive: botActive,
                    activeLabel: botActive ? _botPlanLabel(tr) : null,
                    expiryText: botActive
                        ? _formatExpiry(context, s.botExpiresAt)
                        : null,
                    statusActiveLabel: tr.subscriptions_hub_status_active,
                    statusInactiveLabel: tr.subscriptions_hub_status_inactive,
                    managedByServerNote: botActive && s.botServerGranted
                        ? tr.subscriptions_hub_managed_by_server
                        : null,
                    primaryActionLabel: !canPurchase
                        ? null
                        : botActive
                        ? (s.botHasStoreSubscription
                              ? tr.subscription_manage
                              : null)
                        : tr.subscriptions_hub_subscribe,
                    onPrimaryAction: !canPurchase
                        ? null
                        : botActive
                        ? (s.botHasStoreSubscription
                              ? () => _host.manageSubscription(
                                  SubscriptionKind.botPremium,
                                )
                              : null)
                        : () => SubscriptionPage.show(context, _host),
                    secondaryActionLabel: canPurchase && s.canUpgradeBotToAnnual
                        ? tr.subscription_upgrade_annual
                        : null,
                    onSecondaryAction: canPurchase && s.canUpgradeBotToAnnual
                        ? () => _upgrade(_host.upgradeBotToAnnual)
                        : null,
                    busy: _busy,
                  ),
                  const SizedBox(height: 16),
                  _SubscriptionSectionCard(
                    icon: Icons.storage_rounded,
                    iconColor: Colors.teal,
                    title: tr.subscriptions_hub_hosted_section,
                    description: tr.subscriptions_hub_hosted_desc,
                    isActive: hostedActive,
                    activeLabel: hostedActive ? _hostedPlanLabel(tr) : null,
                    expiryText: hostedActive
                        ? _hostingExpiryText(context)
                        : null,
                    statusActiveLabel: tr.subscriptions_hub_status_active,
                    statusInactiveLabel: tr.subscriptions_hub_status_inactive,
                    // Même information que sur la carte du haut : quand c'est une formule
                    // serveur qui ouvre le droit, l'utilisateur doit savoir qu'il n'a rien
                    // à gérer dans le store (et que « Gérer » ne le concernera pas).
                    managedByServerNote: s.hostedServerGranted
                        ? tr.subscriptions_hub_managed_by_server
                        : null,
                    primaryActionLabel: !canPurchase
                        ? null
                        : hostedActive
                        ? tr.subscription_manage
                        : tr.subscriptions_hub_subscribe,
                    onPrimaryAction: !canPurchase
                        ? null
                        : hostedActive
                        ? () => _host.manageSubscription(
                            SubscriptionKind.hostedApp,
                          )
                        : () => _host.openHostedPurchase(context),
                    secondaryActionLabel:
                        canPurchase && s.canUpgradeHostedToTwoApps
                        ? tr.subscription_upgrade_two_apps
                        : null,
                    onSecondaryAction:
                        canPurchase && s.canUpgradeHostedToTwoApps
                        ? () => _upgrade(_host.upgradeHostedToTwoApps)
                        : null,
                    busy: _busy,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    canPurchase
                        ? tr.subscription_manage_cancel_hint
                        : tr.subscription_not_available_on_platform,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (canPurchase) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: _busy ? null : _restoreAll,
                        icon: const AppIcon.fromMaterial(Icons.restore),
                        label: Text(tr.subscription_restore),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// Une formule du catalogue serveur : ce qu'elle permet, et l'action possible.
///
/// C'est le serveur qui décide de la liste : une formule sans SKU (accordée à la
/// main par un administrateur) apparaît ici sans bouton d'achat.
class _SubscriptionSectionCard extends StatelessWidget {
  const _SubscriptionSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.isActive,
    required this.statusActiveLabel,
    required this.statusInactiveLabel,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.activeLabel,
    this.expiryText,
    this.managedByServerNote,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.busy = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final bool isActive;
  final String? activeLabel;
  final String? expiryText;
  final String? managedByServerNote;
  final String statusActiveLabel;
  final String statusInactiveLabel;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppIcon.fromMaterial(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isActive ? Colors.green : colorScheme.outline)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isActive ? statusActiveLabel : statusInactiveLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? Colors.green.shade700
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            if (isActive && activeLabel != null) ...[
              const SizedBox(height: 16),
              Text(
                context.tr.subscription_active_label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                activeLabel!,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              if (expiryText != null && expiryText!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  expiryText!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (managedByServerNote != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    managedByServerNote!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
            if ((primaryActionLabel != null && onPrimaryAction != null) ||
                (secondaryActionLabel != null &&
                    onSecondaryAction != null)) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (primaryActionLabel != null && onPrimaryAction != null)
                    FilledButton(
                      onPressed: busy ? null : onPrimaryAction,
                      child: Text(primaryActionLabel!),
                    ),
                  if (secondaryActionLabel != null && onSecondaryAction != null)
                    OutlinedButton(
                      onPressed: busy ? null : onSecondaryAction,
                      child: Text(secondaryActionLabel!),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// La carte « Abonnements et facturation » des réglages : un résumé des deux
/// abonnements et l'entrée vers le hub. Même carte dans l'app et le Studio.
class SubscriptionsSettingsCard extends StatefulWidget {
  const SubscriptionsSettingsCard({
    required this.host,
    required this.onOpen,
    super.key,
  });

  final SubscriptionsHost host;

  /// Ouvre le hub (l'hôte décide comment : l'app garde son repli
  /// « indisponible sur cette plateforme »).
  final Future<void> Function(BuildContext context) onOpen;

  @override
  State<SubscriptionsSettingsCard> createState() =>
      _SubscriptionsSettingsCardState();
}

class _SubscriptionsSettingsCardState extends State<SubscriptionsSettingsCard> {
  late SubscriptionsSnapshot _snapshot = widget.host.current;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    final snapshot = await widget.host.refresh();
    if (mounted) setState(() => _snapshot = snapshot);
  }

  String _summary(BuildContext context) {
    final tr = context.tr;
    final bot = _snapshot.botActive;
    final hosted = _snapshot.hostedActive;
    if (bot && hosted) {
      return tr.subscriptions_hub_summary_both;
    }
    if (bot) {
      return tr.subscriptions_hub_summary_bot_only;
    }
    if (hosted) {
      return tr.subscriptions_hub_summary_hosted_only;
    }
    return tr.subscriptions_hub_summary_none;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await widget.onOpen(context);
          if (mounted) {
            await _refresh();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const AppIcon.fromMaterial(
                Icons.subscriptions_outlined,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr.subscriptions_hub_open_settings,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _summary(context),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppIcon.fromMaterial(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
