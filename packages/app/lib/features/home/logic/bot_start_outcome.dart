// Décision PURE : OÙ le bot a RÉELLEMENT démarré, quelques secondes après le geste.
//
// Pourquoi isoler cette décision : la réalité ne se lit pas sur une source mais sur
// DEUX, qui répondent des choses différentes — l'état local de l'application (le
// moteur embarqué, la session mobile, le runner JS) et l'état du compte côté serveur
// (`GET /gateway/bots`). Un utilisateur choisit « Démarrer sur Bot Creator Server » et
// constate un démarrage local : sans une phrase qui nomme l'issue, il n'y a rien à
// croire ni à contester. La décision est donc extraite ici, sans réseau, pour être
// prouvée par un test — et c'est bien cette fonction-là que le contrôle de production
// emprunte, jamais une copie.
//
// Ce fichier ne journalise rien : il rend une issue et une phrase.

/// Où le bot tourne vraiment, constaté après la tentative de démarrage.
enum BotStartOutcome {
  /// Seul ce poste exécute le bot (moteur JS embarqué, desktop ou mobile).
  onThisMachine,

  /// Seuls les serveurs Bot Creator exécutent le bot.
  onServers,

  /// Les deux exécutent le bot en même temps : deux sessions pour un seul jeton
  /// Discord, donc un défaut à voir plutôt qu'à ignorer.
  onBoth,

  /// Ni l'un ni l'autre : la tentative de démarrage n'a abouti nulle part.
  nowhere,

  /// L'état des serveurs n'a pas pu être lu (hors ligne, session absente, bot
  /// inconnu du compte) : l'issue n'est PAS décidable, et le dire vaut mieux que
  /// d'annoncer un démarrage local comme un échec serveur.
  serverStateUnreadable,
}

/// Décision pure : l'état local est un booléen ferme, l'état serveur peut être
/// inconnu (`null` = pas pu être lu).
BotStartOutcome resolveBotStartOutcome({
  required bool localRunning,
  required bool? serverRunning,
}) {
  if (serverRunning == null) {
    return BotStartOutcome.serverStateUnreadable;
  }
  if (localRunning && serverRunning) {
    return BotStartOutcome.onBoth;
  }
  if (localRunning) {
    return BotStartOutcome.onThisMachine;
  }
  if (serverRunning) {
    return BotStartOutcome.onServers;
  }
  return BotStartOutcome.nowhere;
}

/// La phrase qui nomme l'issue, telle qu'elle doit être lue dans la console.
/// Les trois issues attendues sont DISTINCTES : deux réalités différentes ne
/// peuvent pas partager un mot, sinon le diagnostic est faux.
String describeBotStartOutcome(BotStartOutcome outcome) {
  return switch (outcome) {
    BotStartOutcome.onThisMachine => 'demarre sur ce poste',
    BotStartOutcome.onServers => 'demarre sur les serveurs Bot Creator',
    BotStartOutcome.onBoth =>
      'demarre sur ce poste ET sur les serveurs Bot Creator',
    BotStartOutcome.nowhere => 'demarre nulle part (echec)',
    BotStartOutcome.serverStateUnreadable =>
      'indetermine : etat des serveurs non lu',
  };
}

/// Vrai si l'entrée de `GET /gateway/bots` dit que le SERVEUR exécute ce bot.
///
/// Contrat serveur repris tel quel : `runtime_state` (`running`/`stopped`) est
/// l'exécution réelle, `desired_state` (`RUNNING`/`STOPPED`) l'intention. Les deux sont
/// lus exactement comme le canal temps réel les lit déjà (`GatewayBotEventPayload.isRunning`)
/// pour que l'écran, le canal et ce journal ne puissent pas se contredire.
///
/// Une entrée absente (`null`) signifie que le bot n'est pas dans la liste du compte :
/// le serveur ne l'exécute donc pas. C'est différent d'un état ILLISIBLE, que l'appelant
/// exprime en passant `null` à [resolveBotStartOutcome].
bool serverBotIsRunning(Map<String, dynamic>? botEntry) {
  if (botEntry == null) {
    return false;
  }
  final runtime = _field(botEntry['runtime_state']).toLowerCase();
  if (runtime == 'running') {
    return true;
  }
  final desired = _field(botEntry['desired_state']).toUpperCase();
  return desired == 'RUNNING' && runtime != 'stopped' && runtime != 'error';
}

/// Vrai si CE POSTE exécute le bot, lu sur les FAITS d'exécution locale.
///
/// Pourquoi pas l'ensemble `_runningBotIds` de la page d'accueil, qui servait
/// jusqu'ici : c'est un état d'ÉCRAN, remplacé en bloc à chaque rafraîchissement de
/// liste et à chaque changement de bot courant. Mesuré chez le propriétaire : un bot
/// réellement démarré sur le poste (son gateway annonçait « Connected to Gateway »)
/// s'y lisait encore « arrete » cinq secondes plus tard, et la ligne de réalité
/// annonçait « demarre nulle part (echec) » — un faux échec sur un démarrage réussi,
/// qui envoie chercher la panne là où il n'y en a pas.
///
/// Les trois sources retenues sont celles que le DÉMARRAGE produit lui-même, et
/// chacune SURVIT à l'écran qui l'a lancé :
///   * une session du moteur desktop est ouverte pour ce bot : elle vit tant que le
///     gateway est connecté, et c'est elle que « démarrer en local » allume ;
///   * la session mobile (service d'avant-plan) tourne pour ce bot ;
///   * le runner JS embarqué est l'association enregistrée au démarrage réussi
///     (l'exécution est alors dans le processus du runner, pas dans cette app).
///
/// Aucune de ces sources n'est une intention : une association « manager », une
/// préférence, ou le fait d'avoir cliqué ne suffisent pas à dire « en marche ».
bool thisMachineExecutesBot({
  required bool desktopEngineSession,
  required bool mobileSession,
  required bool embeddedRunnerSession,
}) {
  return desktopEngineSession || mobileSession || embeddedRunnerSession;
}

/// Rend la ligne de journal du contrôle de réalité, SANS le préfixe `[demarrage]`
/// (ajouté par le journal).
///
/// Elle porte les deux états et l'issue, et RIEN d'autre : jamais un jeton, jamais un
/// corps de réponse. Le texte est assez explicite pour être compris sans le code.
String formatBotStartRealityLog({
  required String moment,
  required bool localRunning,
  required bool? serverRunning,
  Map<String, dynamic>? serverBotEntry,
}) {
  final String serverDetail;
  if (serverRunning == null) {
    serverDetail = 'inconnu (etat non lu)';
  } else {
    final desired = _field(serverBotEntry?['desired_state']);
    final runtime = _field(serverBotEntry?['runtime_state']);
    serverDetail =
        'desired=${desired.isEmpty ? '?' : desired.toUpperCase()} '
        'runtime=${runtime.isEmpty ? '?' : runtime.toLowerCase()}';
  }

  final outcome = resolveBotStartOutcome(
    localRunning: localRunning,
    serverRunning: serverRunning,
  );
  return '$moment : LOCAL=${localRunning ? 'enMarche' : 'arrete'} '
      'SERVEUR=$serverDetail -> ${describeBotStartOutcome(outcome)}';
}

String _field(Object? raw) => (raw ?? '').toString().trim();
