import 'package:bot_creator/features/home/logic/bot_run_source.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';

/// Ce qu'un écran a le DROIT d'offrir pour obtenir du temps d'hébergement.
///
/// Pourquoi une décision partagée : l'écran de bot offrait « + Ajouter du temps »
/// sur un poste de travail, alors que la pub récompensée est un geste MOBILE —
/// le flux publicitaire répond « rien à faire » hors Android/iOS. Le bouton
/// promettait donc un geste impossible. Et un abonné, dont l'abonnement retire
/// justement les pubs, voyait quand même le bouton ET le compte à rebours.
enum HostingTimeOffer {
  /// Abonné (abonnement qui retire les pubs), ou hébergement déjà payé par la
  /// formule : rien n'expire et rien n'est à obtenir. Prime sur tout le reste,
  /// poste de travail compris — un abonné sur un poste lit « illimité », pas
  /// l'explication des pubs.
  unlimited,

  /// Poste de travail sans abonnement : les pubs récompensées se regardent dans
  /// l'application mobile. L'écran EXPLIQUE au lieu d'offrir un geste
  /// impossible — le temps crédité par pub, lui, compte partout.
  adsOnMobileOnly,

  /// Mobile sans abonnement : le bouton historique, inchangé. C'est le seul
  /// endroit où une pub récompensée peut réellement être regardée.
  addTime,
}

/// Quelle échéance un écran a-t-il le DROIT d'annoncer ?
enum HostingDeadline {
  /// Aucune : ce bot ne consomme pas le solde cloud (il tourne sur ce poste, ou
  /// nulle part). Ni date ni durée d'hébergement ne doivent apparaître.
  none,

  /// L'échéance RÉELLE annoncée par le serveur (`session_expires_at`).
  serverProvided,

  /// Le serveur n'a annoncé aucune échéance : on écrit le temps restant (le
  /// solde). Jamais une date — 138 mois de stock ne font pas le 14 février 2038.
  balanceOnly,
}

/// Décision complète pour un écran : ce qu'il peut offrir, et ce qu'il peut
/// annoncer comme échéance.
///
/// Les deux questions restent séparées parce qu'elles n'ont pas la même réponse
/// au même endroit : un abonné sur un poste n'a rien à obtenir (offre) et son
/// hébergement n'expire pas (échéance) ; un bot hébergé sur ce même poste a une
/// échéance réelle mais offre, au mieux, une explication.
class HostingTimePlan {
  const HostingTimePlan({required this.offer, required this.deadline});

  final HostingTimeOffer offer;
  final HostingDeadline deadline;

  /// État « illimité » : ni bouton, ni compte à rebours.
  bool get showsUnlimitedState => offer == HostingTimeOffer.unlimited;

  /// Le bouton « Ajouter du temps » — mobile non abonné uniquement.
  bool get showsAddTimeButton => offer == HostingTimeOffer.addTime;

  /// Ligne d'explication « les pubs se regardent sur mobile ».
  bool get showsMobileAdsExplanation =>
      offer == HostingTimeOffer.adsOnMobileOnly;

  /// La date affichée vient du SERVEUR, et de lui seul.
  bool get showsServerDeadline => deadline == HostingDeadline.serverProvided;

  /// La carte d'hébergement a-t-elle quelque chose à DIRE ici ?
  ///
  /// Vrai pour un abonné (dire « illimité ») ou pour un bot réellement hébergé
  /// (son échéance / son temps restant). Faux pour un bot que ce poste exécute :
  /// il ne consomme pas le solde cloud, donc il n'a ni échéance ni réserve à
  /// annoncer.
  bool get showsHostingCard =>
      showsUnlimitedState || deadline != HostingDeadline.none;
}

/// Ce que la carte a le droit d'ÉCRIRE — une seule vérité à la fois.
///
/// C'est cette décision qui tue le mensonge d'origine : l'écran calculait une
/// date (`DateTime.now().add(Duration(minutes: solde))`) quand le serveur
/// n'annonçait rien, et présentait donc un STOCK de 138 mois comme une échéance.
enum HostingCardCopy {
  /// Abonné : l'état « illimité », et aucun décompte.
  unlimited,

  /// L'échéance RÉELLE, celle que le serveur a fournie.
  serverDeadline,

  /// Le TEMPS RESTANT (le solde), quand le serveur n'annonce aucune échéance.
  /// Une durée, jamais une date.
  remainingTime,

  /// Bot arrêté : la réserve attend, rien ne se consomme.
  preservedTime,
}

/// Décision PURE du contenu écrit par la carte d'hébergement.
///
/// [plan] doit être celui d'un écran qui a le droit de montrer la carte
/// (`HostingTimePlan.showsHostingCard`) : un bot exécuté par ce poste n'a, lui,
/// rien à annoncer.
HostingCardCopy resolveHostingCardCopy(
  HostingTimePlan plan, {
  required bool botLaunched,
  required DateTime? serverSessionExpiresAt,
}) {
  if (plan.showsUnlimitedState) {
    return HostingCardCopy.unlimited;
  }
  if (botLaunched && plan.showsServerDeadline && serverSessionExpiresAt != null) {
    return HostingCardCopy.serverDeadline;
  }
  return botLaunched
      ? HostingCardCopy.remainingTime
      : HostingCardCopy.preservedTime;
}

/// Décision PURE de l'offre — trois entrées, aucune dépendance à l'état global.
///
/// [hasNoAds] : l'abonnement en cours retire-t-il les pubs (voir
/// [hasNoAdsEntitlement]) ?
/// [premiumFunded] : le serveur dit-il que l'hébergement de ce bot est déjà payé
/// par la formule (`funding_mode == 'premium'`) ? Dans ce cas il n'y a rien à
/// gagner, et annoncer « 0 minute restante » serait faux.
HostingTimeOffer resolveHostingTimeOffer({
  required bool isDesktop,
  required bool hasNoAds,
  required bool premiumFunded,
}) {
  if (hasNoAds || premiumFunded) {
    return HostingTimeOffer.unlimited;
  }
  return isDesktop ? HostingTimeOffer.adsOnMobileOnly : HostingTimeOffer.addTime;
}

/// Décision PURE de l'échéance.
///
/// [runOrigin] vient de `desktopBotRunOrigin` : `null` HORS poste de travail, où
/// le mobile garde sa règle historique (la carte n'y est rendue que pour un bot
/// lancé). Sur un poste, seule une exécution par les serveurs Bot Creator
/// consomme le solde : c'est la seule qui a une échéance à annoncer.
HostingDeadline resolveHostingDeadline({
  required BotRunOrigin? runOrigin,
  required bool serverProvidesDeadline,
}) {
  if (runOrigin != null && !runOrigin.isHostedRemotely) {
    return HostingDeadline.none;
  }
  return serverProvidesDeadline
      ? HostingDeadline.serverProvided
      : HostingDeadline.balanceOnly;
}

/// La garde « l'abonnement en cours retire les pubs ».
///
/// `PremiumCapabilities.noAds` est LA capacité nommée pour ça dans la matrice
/// (`subscription_feature_no_ads_*`) : elle porte la vérité serveur
/// (`SubscriptionService.isSubscribed`) et respecte le seul levier de test
/// existant. La définir ailleurs rouvrirait la porte à sept définitions
/// divergentes d'« abonné », exactement ce qui a déjà coûté cher dans ce dépôt.
bool hasNoAdsEntitlement() =>
    PremiumCapabilities.hasCapability(PremiumCapability.noAds);

/// Plan d'affichage du temps d'hébergement sur un POSTE DE TRAVAIL.
///
/// `null` hors poste de travail : le mobile garde son affichage historique
/// (décision produit, verrouillée par des tests), donc aucun écran ne change de
/// règle sans le dire. C'est la même discipline que `desktopBotRunOrigin`.
HostingTimePlan? desktopHostingTimePlan({
  required String? botId,
  required bool serverReportsRunning,
  required DateTime? serverSessionExpiresAt,
  required bool premiumFunded,
}) {
  final runOrigin = desktopBotRunOrigin(
    botId: botId,
    serverReportsRunning: serverReportsRunning,
  );
  if (runOrigin == null) {
    return null;
  }
  return HostingTimePlan(
    offer: resolveHostingTimeOffer(
      isDesktop: true,
      hasNoAds: hasNoAdsEntitlement(),
      premiumFunded: premiumFunded,
    ),
    deadline: resolveHostingDeadline(
      runOrigin: runOrigin,
      serverProvidesDeadline: serverSessionExpiresAt != null,
    ),
  );
}
