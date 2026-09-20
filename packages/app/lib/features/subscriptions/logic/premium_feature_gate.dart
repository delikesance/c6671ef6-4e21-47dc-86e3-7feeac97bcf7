import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_capabilities.dart';

/// RÈGLE PRODUIT (verbe dictée par le propriétaire) : sur un poste de travail,
/// les fonctionnalités premium sont DISPONIBLES — sans cadenas, sans bannière —
/// tant que le bot tourne sur la machine de l'utilisateur. Elles restent cadrées
/// par la formule du compte quand le bot tourne sur les serveurs Bot Creator
/// (« excepté le Running coté Serveur ») ou sur mobile.
///
/// Pourquoi une décision partagée plutôt qu'une condition par page : la cause du
/// verrou n'est PAS la plateforme, c'est l'ENDROIT où le bot s'exécute. Tant que
/// chaque page recopiait « suis-je premium ? », quatre pages pouvaient répondre
/// quatre choses différentes au même utilisateur, et une régression dans l'une
/// passait inaperçue. Ici la règle est écrite une fois, purement, et vérifiée
/// par une table de cas.
///
/// Ce que la règle NE débloque pas : les capacités dont l'exécution dépend du
/// serveur (hébergement cloud / clé en main, webhooks entrants — ils ont besoin
/// d'une adresse publique fournie par les serveurs Bot Creator). Elles sont
/// laissées de côté par `kDeviceExecutedCapabilities`, volontairement en
/// « fail-closed » : une capacité non déclarée garde la règle de la formule.

/// Association posée par `RunnerSettings` quand le bot part sur l'infrastructure
/// Bot Creator (démarrage distant, ou constat du canal temps réel).
const String kManagerRunAssociation = 'manager';

/// Association posée quand le démarrage visait explicitement ce poste.
const String kLocalRunAssociation = 'local';

/// Capacités dont l'EXÉCUTION a lieu sur l'appareil de l'utilisateur lorsque le
/// bot y tourne : la musique (le bot essaie lui-même ses serveurs de repli), le
/// planificateur, l'analytique du tableau de bord et le rejeu de debug.
///
/// Volontairement une liste fermée : une capacité absente d'ici n'est JAMAIS
/// débloquée par le seul fait de tourner en local (elle retombe sur la formule
/// du compte), donc l'ajout d'une future capacité serveur ne peut pas ouvrir un
/// droit par accident.
const Set<PremiumCapability> kDeviceExecutedCapabilities =
    <PremiumCapability>{
      PremiumCapability.lavalinkAudio,
      PremiumCapability.schedulerTriggers,
      PremiumCapability.analyticsExpanded,
      PremiumCapability.visualDebuggerReplay,
    };

/// Le bot [botId] tourne-t-il sur CET appareil ?
///
/// L'association du bot est la seule trace de l'endroit où il s'exécute : elle
/// est posée au démarrage (le choix local/serveur de l'utilisateur, ou le runner
/// retenu) et corrigée par le canal temps réel quand le serveur annonce un bot
/// en marche (`noteManagerReportedRuntime`).
///
/// Aucune association (`null`) = jamais démarré d'ici : sur un poste de travail,
/// le runner embarqué est le défaut, donc le bot partira bien sur cet appareil.
/// Un identifiant vide ne prouve rien : on n'affirme pas « local ».
bool botRunsOnThisDevice(String? botId) {
  final id = botId?.trim() ?? '';
  if (id.isEmpty) {
    return false;
  }
  final association = RunnerSettings.getAssociatedRunnerId(id);
  return association == null || association == kLocalRunAssociation;
}

/// Décision PURE : une capacité premium est-elle utilisable pour ce bot ?
///
/// Trois entrées, aucune dépendance à l'état global, donc testable par table :
///   * [subscribed] — la formule du compte (vérité serveur) : elle suffit toujours ;
///   * [supportsDesktopLocalRun] — la plateforme sait exécuter un bot sur la
///     machine de l'utilisateur. Volontairement limitée au poste de travail : le
///     mobile garde EXACTEMENT la règle actuelle (formule exigée), décision produit ;
///   * [runsOnThisDevice] — le bot tourne ici et non sur les serveurs Bot Creator.
bool premiumFeatureAvailable({
  required bool runsOnThisDevice,
  required bool supportsDesktopLocalRun,
  required bool subscribed,
}) {
  if (subscribed) {
    return true;
  }
  return supportsDesktopLocalRun && runsOnThisDevice;
}

/// Point d'entrée des écrans : la capacité [capability] est-elle utilisable pour
/// le bot [botId] ?
///
/// Les deux verrous restent séparés : le déploiement (la capacité est-elle
/// ouverte ?) et le droit (formule, ou exécution sur la machine de l'utilisateur).
/// Une capacité hors de [kDeviceExecutedCapabilities] retombe sur la matrice
/// historique, c'est-à-dire sur la formule du compte.
bool premiumCapabilityAvailableForBot(
  PremiumCapability capability, {
  required String? botId,
}) {
  if (!PremiumCapabilities.isCapabilityRolledOut(capability)) {
    return false;
  }
  if (!kDeviceExecutedCapabilities.contains(capability)) {
    return PremiumCapabilities.hasCapability(capability);
  }
  return premiumFeatureAvailable(
    runsOnThisDevice: botRunsOnThisDevice(botId),
    supportsDesktopLocalRun: isDesktopRunPlatform,
    subscribed: PremiumCapabilities.isPremiumUser,
  );
}
