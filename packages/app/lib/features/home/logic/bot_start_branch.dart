// LA branche de démarrage réellement empruntée — nommée là où elle est décidée.
//
// Pourquoi ce fichier existe : la console du propriétaire a montré, le même soir,
// « clic=serveurs Bot Creator » suivi de « branche=LOCAL (desktop) ». Le libellé ne
// mentait pas sur un mot : c'est le DÉMARRAGE qui avait changé de camp sans le dire,
// et la trace annonçait ensuite la branche locale comme si elle avait été voulue.
// Deux choses sont donc écrites ici, une seule fois, pour être prouvées par un test :
//   * le NOM de chaque branche, produit par une table et jamais recomposé à la main ;
//   * la GARDE qui interdit toute exécution locale quand l'utilisateur a choisi les
//     serveurs Bot Creator — le seul repli qui n'a pas le droit d'exister, puisqu'il
//     exécute sur la machine de l'utilisateur autre chose que ce qu'il a choisi.
//
// Ce que ce fichier ne fait pas : il n'imprime rien, ne lit rien et n'appelle rien.
// Il rend des textes ; l'appelant les écrit dans la trace de démarrage.

/// La branche de code réellement empruntée par une tentative de démarrage.
enum BotStartBranch {
  /// Pilotage distant : le compte, la session, le snapshot et la demande de
  /// démarrage partent aux serveurs Bot Creator.
  server,

  /// Moteur JS embarqué de CE poste, atteint par un client de runner.
  localJsEngine,

  /// Runner configuré qui n'est PAS celui embarqué au poste : le bot s'exécute
  /// ailleurs, sur une machine choisie par l'utilisateur. L'appeler « LOCAL »
  /// aurait été le mensonge suivant.
  configuredRunner,

  /// Moteur local du poste (Dart), sans client distant.
  localDesktop,

  /// Service d'avant-plan du mobile.
  mobile,
}

/// Le texte EXACT de la trace de branche (le journal ajoute `[demarrage]`).
///
/// Une seule table pour tout le dépôt : c'est elle que le test interroge, donc aucun
/// libellé ne peut être recomposé ailleurs à la main et diverger de celui-ci.
String botStartBranchTrace(BotStartBranch branch) {
  return switch (branch) {
    BotStartBranch.server => 'branche=SERVEUR',
    BotStartBranch.localJsEngine => 'branche=LOCAL (moteur JS embarque)',
    BotStartBranch.configuredRunner =>
      'branche=RUNNER (moteur JS, machine configuree)',
    BotStartBranch.localDesktop => 'branche=LOCAL (desktop)',
    BotStartBranch.mobile => 'branche=MOBILE',
  };
}

/// La branche décidée par les MÊMES tests que le code de démarrage.
///
/// L'ordre est celui du code, pas une préférence : un client distant présent gagne
/// (« pilotage »), et sans client restent le mobile puis le moteur du poste. Le
/// libellé ne peut donc pas annoncer une branche que le code n'emprunte pas.
BotStartBranch resolveBotStartBranch({
  required bool hasRemoteClient,
  required bool clientIsManager,
  required bool runnerIsEmbedded,
  required bool supportsForegroundTask,
  required bool engineIsJavascript,
}) {
  if (hasRemoteClient) {
    if (clientIsManager) {
      return BotStartBranch.server;
    }
    return runnerIsEmbedded
        ? BotStartBranch.localJsEngine
        : BotStartBranch.configuredRunner;
  }
  if (supportsForegroundTask) {
    return BotStartBranch.mobile;
  }
  return engineIsJavascript
      ? BotStartBranch.localJsEngine
      : BotStartBranch.localDesktop;
}

/// Le PLAN d'un démarrage : où l'on va, et si ce chemin est PERMIS.
///
/// [refusalTrace] non nul veut dire « on s'arrête » : l'appelant écrit la trace,
/// explique à l'utilisateur, et ne poursuit AUCUNE branche.
class BotStartPlan {
  const BotStartPlan({
    required this.branch,
    required this.branchTrace,
    this.refusalTrace,
    this.serverUnavailableDetail,
  });

  /// Branche décidée par [resolveBotStartBranch] — celle que le code emprunte.
  final BotStartBranch branch;

  /// Ligne de trace à écrire quand le démarrage est permis.
  final String branchTrace;

  /// Ligne de trace à écrire À LA PLACE de [branchTrace] quand il ne l'est pas.
  final String? refusalTrace;

  /// Ce que le serveur a dit de son indisponibilité, s'il l'a dit.
  final String? serverUnavailableDetail;

  /// Vrai quand le démarrage peut poursuivre dans [branch].
  bool get allowed => refusalTrace == null;
}

/// Décide le plan d'un démarrage, à partir des mêmes entrées que le code.
///
/// [serverChosen] est le CHOIX de l'utilisateur (pop-up de démarrage). Il est le
/// seul verrou absolu : quand il vaut `true`, [BotStartBranch.server] est la seule
/// branche permise. Un client distant absent, une session expirée, un serveur qui
/// refuse ou une demande qui échoue s'EXPLIQUENT et ARRÊTENT le démarrage. Replier
/// en local sans le dire, c'est exécuter sur la machine de l'utilisateur autre chose
/// que ce qu'il a choisi — c'est le défaut mesuré, et il n'est pas repris ici.
///
/// Aucune exception à cette règle n'est prévue : il n'y a pas de cas où démarrer
/// localement serait préférable à dire la vérité.
BotStartPlan planBotStart({
  required bool serverChosen,
  required bool hasRemoteClient,
  required bool clientIsManager,
  required bool runnerIsEmbedded,
  required bool supportsForegroundTask,
  required bool engineIsJavascript,
  required String serverUnavailableDetail,
}) {
  final branch = resolveBotStartBranch(
    hasRemoteClient: hasRemoteClient,
    clientIsManager: clientIsManager,
    runnerIsEmbedded: runnerIsEmbedded,
    supportsForegroundTask: supportsForegroundTask,
    engineIsJavascript: engineIsJavascript,
  );
  final branchTrace = botStartBranchTrace(branch);
  if (!serverChosen || branch == BotStartBranch.server) {
    return BotStartPlan(
      branch: branch,
      branchTrace: branchTrace,
      serverUnavailableDetail: serverUnavailableDetail,
    );
  }
  return BotStartPlan(
    branch: branch,
    branchTrace: branchTrace,
    refusalTrace: _refusalTrace(serverUnavailableDetail, branch),
    serverUnavailableDetail: serverUnavailableDetail,
  );
}

/// L'explication écrite dans la console : ce qui manque, où le code allait, et le
/// fait qu'aucune exécution locale n'a été entamée. Jamais un jeton, jamais un corps
/// de réponse — une raison applicative suffit.
String _refusalTrace(String detail, BotStartBranch branch) {
  final trimmed = detail.trim();
  final reason = trimmed.isEmpty ? 'serveur indisponible' : trimmed;
  final avoided = switch (branch) {
    BotStartBranch.mobile => 'aucun demarrage mobile',
    _ => 'aucune execution locale',
  };
  return 'REFUS : serveurs Bot Creator choisis ($reason) -> $avoided (arret)';
}
