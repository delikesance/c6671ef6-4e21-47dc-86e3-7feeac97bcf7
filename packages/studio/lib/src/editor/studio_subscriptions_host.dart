import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;
import 'package:flutter/material.dart';

import '../api/studio_api.dart';

/// Les abonnements tels que le Studio les lit : formule et plafonds du compte
/// (`GET /gateway/runtime`), couverture d'hébergement (`GET
/// /containers/eligibility`) et catalogue d'offres (`GET
/// /gateway/commerce/catalog`), tous avec le jeton Discord du Studio. Les écrans
/// (`SubscriptionsHubPage`, `SubscriptionPage`, carte des réglages) sont ceux de
/// l'app.
///
/// LECTURE SEULE, et c'est un fait du Manager et non un choix du Studio : ses
/// routes de facturation sont les webhooks des boutiques (`/billing/webhook/
/// {kofi,admob,playstore,apple}`) et la vérification de reçus (`/billing/verify`,
/// `/billing/consumable/verify`) — aucune session de paiement ni portail web (la
/// seule intégration de paiement par carte, côté serveur, sert le CMS des
/// créateurs, pas les formules du compte). `canPurchase` reste donc à « non » :
/// l'écran masque achat, restauration et gestion, et dit — avec la phrase de
/// l'app pour les plateformes sans boutique — que l'abonnement s'active sur
/// mobile.
class StudioSubscriptionsHost extends SubscriptionsHost {
  StudioSubscriptionsHost(this.api);

  final StudioApi api;

  SubscriptionsSnapshot _last = const SubscriptionsSnapshot();

  @override
  SubscriptionsSnapshot get current => _last;

  @override
  Future<SubscriptionsSnapshot> refresh() async {
    final results = await Future.wait<Map<String, dynamic>?>([
      _tryRead(api.runtime),
      _tryRead(api.containerEligibilityWire),
    ]);
    final runtime = results[0];
    final eligibility = results[1];
    if (runtime == null && eligibility == null) return _last;
    return _last = _snapshot(runtime, eligibility);
  }

  /// Un serveur injoignable (ou une route absente) laisse l'état précédent :
  /// le Studio n'affirme rien qu'il n'a pas lu.
  Future<Map<String, dynamic>?> _tryRead(
    Future<Map<String, dynamic>> Function() read,
  ) async {
    try {
      return await read();
    } catch (_) {
      return null;
    }
  }

  SubscriptionsSnapshot _snapshot(
    Map<String, dynamic>? runtime,
    Map<String, dynamic>? eligibility,
  ) {
    // Même lecture que l'app (`_isPremiumPlan`) : la première clé reconnue
    // décide ; une formule inconnue vaut gratuite (le Studio ne présume jamais
    // Premium).
    var premium = false;
    for (final key in const ['plan', 'account_plan', 'subscription_plan']) {
      final raw = runtime?[key]?.toString().trim().toUpperCase();
      if (raw == 'PREMIUM') {
        premium = true;
        break;
      }
      if (raw == 'FREE') break;
    }
    final provider = runtime?['provider']?.toString();
    final maxBots = runtime?['max_bots'];
    final displayName = runtime?['display_name']?.toString();
    final elig = eligibility == null
        ? null
        : HostedAppEligibility.fromJson(eligibility);
    // Comme l'app : `premium` distingue une formule payante du socle gratuit
    // (le serveur répond 1 / vrai par défaut quand aucune formule n'est connue).
    final hostedGranted =
        elig != null &&
        elig.premium &&
        elig.allowTurnkey &&
        elig.maxContainers > 0;
    return SubscriptionsSnapshot(
      botActive: premium,
      planDisplayName: displayName == null || displayName.isEmpty
          ? null
          : displayName,
      planMaxBots: maxBots is num ? maxBots.toInt() : null,
      botExpiresAt: premium
          ? DateTime.tryParse(runtime?['expires_at']?.toString() ?? '')?.toUtc()
          : null,
      // Un abonnement de boutique n'est « géré par le serveur » que dans le
      // sens où le serveur le relève ; seul un octroi (administrateur,
      // formule) l'est vraiment.
      botServerGranted:
          premium && provider != 'google_play' && provider != 'apple_in_app',
      hostedActive: hostedGranted,
      hostedServerGranted: hostedGranted,
      hostedMaxContainers: elig?.maxContainers,
      hostingCoverageExpiresAt: elig?.hostingExpiresAt,
      hostingCoveragePermanent: elig?.hostingPermanent ?? false,
    );
  }

  @override
  Future<CommerceCatalog?> loadCommerce() async {
    try {
      final catalog = CommerceCatalog.fromJson(await api.commerceCatalogWire());
      return catalog.published ? catalog : null;
    } catch (_) {
      return null;
    }
  }

  @override
  bool get canOpenAiCredits => true;

  @override
  void openAiCredits(BuildContext context) => openStudioAiCredits(context, api);
}

/// Ouvre l'écran « Crédits IA » de l'app, sur le portefeuille du Manager.
Future<void> openStudioAiCredits(BuildContext context, StudioApi api) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => AICreditsPage(host: StudioAiCreditsHost(api)),
    ),
  );
}

/// Les crédits IA tels que le Studio les lit : portefeuille et historique, en
/// lecture. Ni roulette, ni publicité, ni achat de pack (aucun paiement web) :
/// les capacités de l'hôte restent à leur valeur par défaut et l'écran masque
/// ces blocs. Pas d'ouverture de la conversation d'une ligne : le Copilote du
/// Studio n'ouvre pas une discussion par son identifiant.
class StudioAiCreditsHost extends AiCreditsHost {
  const StudioAiCreditsHost(this.api);

  final StudioApi api;

  @override
  Future<Map<String, dynamic>> wallet() => api.aiWallet();

  @override
  Future<Map<String, dynamic>> ledger({int offset = 0}) =>
      api.aiLedgerWire(offset: offset);
}

/// Donne l'hôte des abonnements aux écrans du Studio (refus de formule,
/// verrous Premium) sans le faire passer par chaque constructeur.
class StudioSubscriptionsScope extends InheritedWidget {
  const StudioSubscriptionsScope({
    super.key,
    required this.host,
    required super.child,
  });

  final StudioSubscriptionsHost host;

  /// `null` hors de la coque (tests d'écrans isolés) : l'appelant n'affiche
  /// alors pas d'entrée vers les formules.
  static StudioSubscriptionsHost? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<StudioSubscriptionsScope>()
      ?.host;

  @override
  bool updateShouldNotify(StudioSubscriptionsScope oldWidget) =>
      host != oldWidget.host;
}

/// Ouvre le hub des abonnements (si la coque en fournit un).
Future<void> openStudioSubscriptions(BuildContext context) async {
  final host = StudioSubscriptionsScope.maybeOf(context);
  if (host == null) return;
  await SubscriptionsHubPage.open(context, host);
}
