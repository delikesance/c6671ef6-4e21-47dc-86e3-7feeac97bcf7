/// Contrat entre les écrans « Abonnements » (hub, offres, carte des réglages —
/// partagés) et la façon dont chaque client lit et achète une formule : l'app
/// passe par les services de facturation natifs (App Store / Google Play) et
/// `MainApiClient`, le Studio par `StudioApi` en LECTURE SEULE.
///
/// Le Manager n'offre AUCUN paiement web (ses routes de facturation sont les
/// webhooks des boutiques et la vérification de reçus : `/billing/verify`,
/// `/billing/consumable/verify`) : acheter, restaurer et gérer un abonnement
/// sont donc des CAPACITÉS à valeur par défaut « non ». L'écran masque alors
/// l'action et dit, avec la phrase que l'app emploie quand les achats ne sont
/// pas possibles sur la plateforme (`subscription_not_available_on_platform`),
/// où s'achète une formule. Tout ce que le serveur expose (formule, plafonds,
/// échéance, couverture d'hébergement, catalogue d'offres) reste affiché.
library;

import 'package:flutter/widgets.dart';

import 'commerce_models.dart';
import 'premium_features.dart';

/// Cadence d'un abonnement Bot Premium acheté dans une boutique.
enum BotStoreCadence { monthly, annual }

/// Palier d'une formule d'hébergement achetée dans une boutique.
enum HostedStoreTier { oneApp, twoApps }

/// Quel abonnement ouvrir dans la gestion de la boutique.
enum SubscriptionKind { botPremium, hostedApp }

/// L'état des deux abonnements à un instant donné. Les valeurs viennent du
/// SERVEUR (formule du compte, éligibilité à l'hébergement) ; l'app y ajoute ce
/// qu'un reçu de boutique prouve localement.
class SubscriptionsSnapshot {
  const SubscriptionsSnapshot({
    this.botActive = false,
    this.planDisplayName,
    this.planMaxBots,
    this.botStoreCadence,
    this.botExpiresAt,
    this.botServerGranted = false,
    this.botHasStoreSubscription = false,
    this.canUpgradeBotToAnnual = false,
    this.hostedActive = false,
    this.hostedServerGranted = false,
    this.hostedMaxContainers,
    this.hostedStoreTier,
    this.hostedStoreExpiresAt,
    this.hostingCoverageExpiresAt,
    this.hostingCoveragePermanent = false,
    this.canUpgradeHostedToTwoApps = false,
  });

  /// Bot Premium actif (formule du serveur, sinon reçu de boutique).
  final bool botActive;

  /// Nom que le serveur donne à la formule (« Pro », « Host One App »…).
  final String? planDisplayName;

  /// Plafond de bots de la formule (`0` = illimité, `null` = non renseigné).
  final int? planMaxBots;
  final BotStoreCadence? botStoreCadence;
  final DateTime? botExpiresAt;

  /// Formule accordée par le serveur (administrateur), pas par un achat.
  final bool botServerGranted;

  /// L'abonnement vient d'un achat de boutique (donc gérable dans la boutique).
  final bool botHasStoreSubscription;
  final bool canUpgradeBotToAnnual;

  final bool hostedActive;

  /// L'hébergement est ouvert par la formule du compte (pas par un reçu).
  final bool hostedServerGranted;

  /// Plafond d'applications hébergées fixé par la formule.
  final int? hostedMaxContainers;
  final HostedStoreTier? hostedStoreTier;
  final DateTime? hostedStoreExpiresAt;

  /// Fin de la couverture hébergement connue du serveur ; avec
  /// [hostingCoveragePermanent] faux, une échéance absente veut dire
  /// « inconnue » : l'écran n'affirme rien.
  final DateTime? hostingCoverageExpiresAt;
  final bool hostingCoveragePermanent;
  final bool canUpgradeHostedToTwoApps;
}

abstract class SubscriptionsHost {
  const SubscriptionsHost();

  // ── Lectures ───────────────────────────────────────────────────────────────

  /// L'état connu SANS réseau (ce que l'hôte a déjà relevé) : l'écran s'en sert
  /// avant la fin de [refresh], pour ne pas afficher « non abonné » le temps
  /// d'une requête.
  SubscriptionsSnapshot get current => const SubscriptionsSnapshot();

  /// Relit l'état auprès du serveur (et des boutiques quand l'hôte en a), puis
  /// le rend. Ne lève pas : un serveur injoignable laisse l'état précédent.
  Future<SubscriptionsSnapshot> refresh();

  /// Le catalogue commercial publié (`GET /gateway/commerce/catalog`). `null` :
  /// rien de publié, pas de session ou serveur injoignable.
  Future<CommerceCatalog?> loadCommerce() async => null;

  // ── Achats (capacités) ─────────────────────────────────────────────────────

  /// La plateforme sait-elle acheter, restaurer et gérer un abonnement ? Faux
  /// (Studio) : aucun bouton d'achat, la mention
  /// `subscription_not_available_on_platform` à la place.
  bool get canPurchase => false;

  /// Le bot Premium est-il actif MAINTENANT ? Lecture en direct (sans réseau)
  /// pour que l'écran d'offres se ferme dès que l'achat aboutit.
  bool get isBotSubscribed => false;

  /// Passe l'abonnement Bot Premium en annuel. Rend la clé d'erreur à afficher
  /// (`subscription_error_*`), ou `null` quand l'achat a démarré.
  Future<String?> upgradeBotToAnnual() async => 'subscription_error';

  /// Passe l'hébergement en formule « deux applications » (même contrat).
  Future<String?> upgradeHostedToTwoApps() async => 'subscription_error';

  /// Restaure les achats de boutique (Bot Premium et hébergement) et laisse le
  /// temps au flux d'achats de livrer les reçus rejoués.
  Future<void> restorePurchases() async {}

  /// Ouvre la gestion de l'abonnement dans la boutique.
  Future<void> manageSubscription(SubscriptionKind kind) async {}

  /// Ouvre l'écran d'achat de la formule d'hébergement.
  void openHostedPurchase(BuildContext context) {}

  // ── Écran d'offres (SubscriptionPage) ─────────────────────────────────────

  /// `ios` / `android` : la plateforme dont on lit les liaisons de produits du
  /// catalogue. `null` : aucune boutique ici.
  String? get storePlatform => null;

  /// Charge les produits de boutique des offres du catalogue (prix).
  Future<void> prepareOffers(CommerceCatalog catalog) async {}

  /// Le prix de boutique d'une offre du catalogue. `null` : produit absent de
  /// la boutique, donc non achetable.
  String? priceForOffer(CommerceOffer offer) => null;

  /// Lance l'achat d'une offre du catalogue (clé d'erreur ou `null`).
  Future<String?> purchaseOffer(CommerceOffer offer) async =>
      'subscription_error';

  /// Repli sans catalogue publié : prix de boutique d'une cadence ([fallback]
  /// quand la boutique ne le donne pas).
  String priceForBotPlan(BotStoreCadence cadence, String fallback) => fallback;

  /// Économie de l'annuel face au mensuel, en pourcent (`null` : pas assez).
  int? annualSavingsPercent() => null;

  /// Lance l'achat d'une cadence (clé d'erreur ou `null`).
  Future<String?> purchaseBotPlan(BotStoreCadence cadence) async =>
      'subscription_error';

  /// Restaure les achats Bot Premium ; rend vrai si le compte est abonné
  /// ensuite.
  Future<bool> restoreBotPurchases() async => false;

  /// Relit le statut Bot Premium auprès du serveur (à l'ouverture de l'écran).
  Future<void> refreshBotPremium() async {}

  /// Les avantages pas encore déployés portent un badge « bientôt ».
  bool isFeatureComingSoon(PremiumCapability capability) => false;

  /// Conditions d'utilisation de la boutique (`null` : pas de lien).
  String? get termsUrl => null;

  // ── Crédits IA ────────────────────────────────────────────────────────────

  /// L'écran des crédits IA (portefeuille, historique) est-il accessible ?
  bool get canOpenAiCredits => false;

  /// La roulette et les publicités récompensées existent-elles sur cet hôte ?
  /// Change le libellé de l'entrée du hub (« crédits IA et roulette »).
  bool get hasRewardedAds => false;

  void openAiCredits(BuildContext context) {}
}
