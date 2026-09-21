import 'package:bot_creator/core/i18n/i18n.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/features/subscriptions/logic/premium_feature_gate.dart';

/// Qui exécute VIVEMENT un bot, du point de vue des écrans.
///
/// Pourquoi cette brique existe : la carte d'accueil et la page de détail d'un
/// bot répondaient chacune à la question « où tourne ce bot ? » avec sa propre
/// condition — sept copies divergentes de cette même question existent déjà dans
/// ce dépôt. Résultat mesuré par le propriétaire : un bot exécuté par le POSTE
/// s'affichait « Serveurs Bot Creator » avec une échéance d'hébergement en 2038,
/// calculée depuis le SOLDE de minutes cloud. Une échéance pour un bot qui ne
/// consomme pas ce solde est un mensonge d'affichage.
///
/// La règle est donc écrite UNE fois ici, et les deux écrans l'appellent :
///   * l'association du bot (`RunnerSettings`, corrigée par le canal temps réel
///     quand le serveur annonce un bot en marche) est la seule trace de l'endroit
///     où il s'exécute ;
///   * un bot associé à ce poste — ou jamais associé — tourne ici, même si le
///     serveur déclare sa propre session arrêtée ;
///   * le cloud suppose DEUX faits concordants : association `manager` ET état
///     vivant en marche.
///
/// Ce qui n'est JAMAIS utilisé comme indice : la présence d'un solde de minutes,
/// ni un repli serveur par défaut. Un solde non nul ne prouve pas qu'un bot
/// tourne quelque part ; il prouve seulement qu'il reste des minutes.
enum BotRunOrigin {
  /// Le bot tourne sur le poste de l'utilisateur : il ne consomme PAS le solde
  /// cloud, donc aucune échéance d'hébergement ne doit être affichée.
  thisDevice,

  /// Le bot tourne sur les serveurs Bot Creator : c'est le SEUL cas qui a une
  /// échéance / un temps restant de session.
  botCreatorServers,

  /// Rien ne l'exécute : ni source cloud, ni échéance trompeuse.
  stopped,
}

extension BotRunOriginHosting on BotRunOrigin {
  /// Vrai seulement pour une exécution RÉELLEMENT hébergée par les serveurs
  /// Bot Creator : c'est la condition unique du bloc d'échéance.
  bool get isHostedRemotely => this == BotRunOrigin.botCreatorServers;

  /// Vrai quand c'est la machine de l'utilisateur qui exécute le bot.
  bool get runsOnThisDevice => this == BotRunOrigin.thisDevice;
}

/// Source d'exécution VIVANTE de [botId].
///
/// [serverReportsRunning] est l'état vivant annoncé par le serveur pour CE bot
/// (canal temps réel ou statut interrogé) — jamais la simple présence d'un
/// solde, jamais une association seule pour affirmer le cloud.
BotRunOrigin resolveBotRunOrigin({
  required String? botId,
  required bool serverReportsRunning,
}) {
  final id = botId?.trim() ?? '';
  // Un identifiant inconnu ne permet d'affirmer ni « ici » ni « là-bas ».
  if (id.isEmpty) {
    return BotRunOrigin.stopped;
  }
  if (botRunsOnThisDevice(id)) {
    return BotRunOrigin.thisDevice;
  }
  // Association `manager` : il faut EN PLUS que le serveur le fasse tourner,
  // sinon le bot est simplement arrêté (aucune échéance à montrer).
  return serverReportsRunning
      ? BotRunOrigin.botCreatorServers
      : BotRunOrigin.stopped;
}

/// Même résolution, mais SEULEMENT sur un poste de travail.
///
/// `null` ailleurs : le mobile garde son affichage historique (décision produit,
/// verrouillée par des tests), donc aucun écran ne change de règle sans le dire.
/// Renvoyer `null` plutôt qu'une valeur « par défaut » évite qu'un écran mobile
/// emprunte silencieusement la nouvelle règle : l'appelant doit traiter le cas.
BotRunOrigin? desktopBotRunOrigin({
  required String? botId,
  required bool serverReportsRunning,
}) {
  if (!isDesktopRunPlatform) {
    return null;
  }
  return resolveBotRunOrigin(
    botId: botId,
    serverReportsRunning: serverReportsRunning,
  );
}

/// Libellé de source à afficher, ou `null` quand rien n'exécute le bot.
///
/// Le libellé du cloud (`runner_source_manager`) est celui déjà utilisé pour
/// nommer les serveurs Bot Creator : le réécrire ailleurs rouvrirait la porte
/// aux affichages divergents.
String? botRunSourceLabel(AppLocalizations tr, BotRunOrigin origin) {
  return switch (origin) {
    BotRunOrigin.thisDevice => tr.runner_source_this_device,
    BotRunOrigin.botCreatorServers => tr.runner_source_manager,
    BotRunOrigin.stopped => null,
  };
}
