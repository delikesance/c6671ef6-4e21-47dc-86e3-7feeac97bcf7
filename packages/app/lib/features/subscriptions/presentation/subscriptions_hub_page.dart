import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/theme/app_theme.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_billing_catalog.dart';
import 'package:bot_creator/features/subscriptions/logic/hosted_app_subscription_service.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_management_links.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscription_page.dart';
import 'package:flutter/material.dart';

/// Central page listing bot premium and hosted-app subscriptions.
class SubscriptionsHubPage extends StatefulWidget {
  const SubscriptionsHubPage({super.key});

  static Future<void> open(BuildContext context) {
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
    return Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => const SubscriptionsHubPage()),
    );
  }

  @override
  State<SubscriptionsHubPage> createState() => _SubscriptionsHubPageState();
}

class _SubscriptionsHubPageState extends State<SubscriptionsHubPage> {
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _loading = true);
    await Future.wait([
      SubscriptionService.resolveEffectivePremiumStatus(forceRefresh: true),
      HostedAppSubscriptionService.resolveEffectiveHostedAppStatus(
        forceRefresh: true,
      ),
      _registerPurchasableProducts(),
    ]);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  /// Récupère les SKUs que le serveur rattache aux formules, pour que le store les
  /// reconnaisse lors de l'achat et de la validation des reçus.
  ///
  /// C'est le SEUL usage du catalogue côté application : le mapping serveur décrit des
  /// capacités (à quelle formule correspond quel achat, quels droits en découlent), jamais
  /// une liste d'offres à afficher. Les offres montrées à l'utilisateur sont une
  /// fonctionnalité de l'application (voir les deux cartes de cet écran et
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

  Future<void> _upgradeBotToAnnual() async {
    await _runBusy(() async {
      final result = await SubscriptionService.purchaseAnnual();
      if (!result.started && mounted) {
        _showError(subscriptionPurchaseErrorKey(result.failureReason));
      }
    });
  }

  Future<void> _upgradeHostedToTwoApps() async {
    await _runBusy(() async {
      final result = await HostedAppSubscriptionService.purchaseTwoApps();
      if (!result.started && mounted) {
        _showError(subscriptionPurchaseErrorKey(result.failureReason));
      }
    });
  }

  Future<void> _restoreAll() async {
    await _runBusy(() async {
      await SubscriptionService.restorePurchases();
      await HostedAppSubscriptionService.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 4));
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
    if (HostedAppSubscriptionService.hasServerGrantedHostedApps) {
      final serverExpiry =
          HostedAppSubscriptionService.hostingCoverageExpiresAt;
      if (serverExpiry != null) return _formatExpiry(context, serverExpiry);
      return HostedAppSubscriptionService.hostingCoveragePermanent
          ? context.tr.subscriptions_hub_permanent
          : null;
    }
    return _formatExpiry(
      context,
      HostedAppSubscriptionService.subscriptionExpiresAt,
    );
  }

  String _botPlanLabel(AppLocalizations tr) {
    final maxBots = SubscriptionService.activePlanMaxBots;
    final botsLimit = maxBots == null
        ? null
        : (maxBots == 0
              ? tr.subscriptions_hub_unlimited_bots
              : '$maxBots bots max');
    final customDisplayName = SubscriptionService.activePlanDisplayName;

    // Le nom de la formule s'affiche sur la carte dont elle porte l'offre. Une formule qui
    // inclut les applications hébergées (type « Host One App ») est une offre d'hébergement :
    // son nom va sur la carte du bas. Sans cette règle, l'écran présentait une formule
    // d'applications hébergées comme l'abonnement Bot Premium — ici on n'annonce plus que la
    // capacité bot, qui elle est bien accordée.
    final nameBelongsToHostedCard =
        HostedAppSubscriptionService.hasServerGrantedHostedApps;

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
    final productId = SubscriptionService.activeProductId;
    if (productId == kAnnualSubscriptionId) {
      return tr.subscription_active_annual;
    }
    if (productId == kMonthlySubscriptionId) {
      return tr.subscription_active_monthly;
    }
    return tr.subscription_plan_label;
  }

  String _hostedPlanLabel(AppLocalizations tr) {
    // Droit accordé par la formule du compte : c'est son nom qui décrit ce que l'utilisateur
    // a, avec le plafond qu'elle fixe (le serveur applique exactement ce chiffre au
    // démarrage).
    if (HostedAppSubscriptionService.hasServerGrantedHostedApps) {
      final formulaName = SubscriptionService.activePlanDisplayName?.trim();
      final maxContainers = HostedAppSubscriptionService.serverMaxContainers;
      final capability = switch (maxContainers) {
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
    return switch (hostedAppTierFromCanonicalProductId(
      HostedAppSubscriptionService.activeProductId,
    )) {
      HostedAppTier.oneApp => tr.hosted_app_subscription_one_app_title,
      HostedAppTier.twoApps => tr.hosted_app_subscription_two_app_title,
      null => tr.hosted_app_subscription_title,
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final botActive = SubscriptionService.isSubscribed;
    final hostedActive = HostedAppSubscriptionService.isSubscribed;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.subscriptions_hub_title),
        actions: [
          IconButton(
            onPressed: _loading || _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: tr.common_refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
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
                        ? _formatExpiry(
                            context,
                            SubscriptionService.subscriptionExpiresAt,
                          )
                        : null,
                    statusActiveLabel: tr.subscriptions_hub_status_active,
                    statusInactiveLabel: tr.subscriptions_hub_status_inactive,
                    managedByServerNote:
                        botActive && SubscriptionService.isServerGranted
                        ? tr.subscriptions_hub_managed_by_server
                        : null,
                    primaryActionLabel: botActive
                        ? (SubscriptionService.hasNativeStoreSubscription
                              ? tr.subscription_manage
                              : null)
                        : tr.subscriptions_hub_subscribe,
                    onPrimaryAction: botActive
                        ? (SubscriptionService.hasNativeStoreSubscription
                              ? () => openSubscriptionManagement(
                                  kind: SubscriptionProductKind.botPremium,
                                  storeProductId:
                                      SubscriptionService.activeProductId,
                                )
                              : null)
                        : () => SubscriptionPage.show(context),
                    secondaryActionLabel: SubscriptionService.canUpgradeToAnnual
                        ? tr.subscription_upgrade_annual
                        : null,
                    onSecondaryAction: SubscriptionService.canUpgradeToAnnual
                        ? _upgradeBotToAnnual
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
                    managedByServerNote:
                        HostedAppSubscriptionService.hasServerGrantedHostedApps
                        ? tr.subscriptions_hub_managed_by_server
                        : null,
                    primaryActionLabel: hostedActive
                        ? tr.subscription_manage
                        : tr.subscriptions_hub_subscribe,
                    onPrimaryAction: hostedActive
                        ? () => openSubscriptionManagement(
                            kind: SubscriptionProductKind.hostedApp,
                            storeProductId:
                                HostedAppSubscriptionService.activeProductId,
                          )
                        : () => HostedAppSubscriptionPage.show(context),
                    secondaryActionLabel:
                        HostedAppSubscriptionService.canUpgradeToTwoApps
                        ? tr.subscription_upgrade_two_apps
                        : null,
                    onSecondaryAction:
                        HostedAppSubscriptionService.canUpgradeToTwoApps
                        ? _upgradeHostedToTwoApps
                        : null,
                    busy: _busy,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    tr.subscription_manage_cancel_hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: _busy ? null : _restoreAll,
                      icon: const Icon(Icons.restore),
                      label: Text(tr.subscription_restore),
                    ),
                  ),
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
                Icon(icon, color: iconColor, size: 28),
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
