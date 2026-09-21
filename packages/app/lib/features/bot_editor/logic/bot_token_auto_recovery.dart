import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_import.dart';

/// Reprise AUTOMATIQUE des jetons manquants sur ce poste, pour les bots du compte.
///
/// Pourquoi un module à part plutôt qu'une boucle dans `syncAllBotsFromManager` :
/// c'est ICI que se décide la garantie de débit demandée — au plus une tentative
/// par bot et par lancement, aucune rafale, rien hors ligne — et une décision ne
/// se prouve pas en montant la vraie page d'accueil : ses minuteurs périodiques et
/// son canal temps réel font pendre un test de widget. La synchro appelle cette
/// fonction, les tests l'appellent aussi : c'est le même code qui décide.
///
/// Ce module sert DEUX besoins, avec la même garde et la même route :
///   * équiper ce poste d'un jeton pour pouvoir EXÉCUTER le bot en local
///     ([recoverMissingBotTokens], tout le compte d'un coup) ;
///   * équiper ce poste d'un jeton pour pouvoir DEMANDER SON NOM au bot
///     ([recoverBotTokenForIdentity], un bot à la fois, à la demande du balayage
///     d'identité) — sans quoi un bot hébergé, dont le nom vaut son ID, restait
///     affiché sous son ID.
///
/// Ce qui déclenche une reprise, bot par bot :
///   (a) le bot est annoncé par le compte (il est dans [accountBots]) ;
///   (b) il n'a AUCUN jeton utilisable sur ce poste ([localTokenOf]) ;
///   (c) le serveur n'a rien livré dans sa réponse (`bot_token` vide) — le
///       manager RÉDIGE ce champ dans ses listes, donc « vide » est la norme ;
///   (d) le compte ne le dit PAS invalide (`token_invalid != true`) : reprendre
///       une credential morte ne donnerait rien.
///
/// Hors ligne ([client] nul), rien ne part : le comportement d'un poste sans
/// compte reste celui d'avant (bots locaux, runner embarqué).
///
/// Rend une issue par bot effectivement soumis à la reprise, dans l'ordre — de
/// quoi journaliser sans jamais manipuler la valeur d'un jeton.
Future<List<BotTokenImportOutcome>> recoverMissingBotTokens({
  required MainApiClient? client,
  required List<Map<String, dynamic>> accountBots,
  required String Function(String botId) localTokenOf,
  Duration betweenAttempts = const Duration(milliseconds: 300),
  Future<void> Function(String botId, String token)? onTokenStored,
}) async {
  final outcomes = <BotTokenImportOutcome>[];
  final activeClient = client;
  // (hors ligne) Aucun compte : aucune tentative, même pas la réservation d'un
  // identifiant, pour qu'une reconnexion rende la reprise possible.
  if (activeClient == null) return outcomes;

  final importer = BotTokenImporter(
    client: activeClient,
    // Transmis tel quel : c'est à l'appelant de décider si un jeton qui vient
    // d'arriver doit servir à interroger Discord sur le nom du bot (voir
    // `onTokenStored`). Sans rappel, rien ne change par rapport à avant.
    onTokenStored: onTokenStored,
  );
  for (final bot in accountBots) {
    final botId = (bot['bot_id'] ?? '').toString().trim();
    if (botId.isEmpty) continue;
    // (c) Le serveur a livré le jeton : la synchro l'écrit, il n'y a rien à
    // redemander. C'est le seul cas où `bot_token` est non vide.
    if ((bot['bot_token'] ?? '').toString().trim().isNotEmpty) continue;
    // (b) Ce poste a déjà un jeton utilisable : rien à reprendre.
    if (localTokenOf(botId).trim().isNotEmpty) continue;

    if (outcomes.isNotEmpty) {
      // Export par export, espacés : le seau du serveur en tolère dix par minute
      // et par propriétaire, une rafale au démarrage les ferait refuser en 429 —
      // ce qui serait un échec fabriqué par le client lui-même.
      await Future<void>.delayed(betweenAttempts);
    }

    outcomes.add(
      await importer.importAutomatically(
        botId: botId,
        // (d) Seul `token_invalid == true` interdit la tentative. Un champ
        // absent ou `false` laisse le serveur juger au moment de l'export.
        serverAnnouncesTokenValid: bot['token_invalid'] != true,
        // (b) déjà vérifié juste au-dessus : ce n'est pas [BotTokenImporter]
        // qui décide ici, c'est la synchro.
        hasLocalToken: false,
      ),
    );
  }
  return outcomes;
}

/// Reprend le jeton d'UN bot quand la seule raison de le vouloir est de DEMANDER
/// SON NOM à Discord.
///
/// Pourquoi elle existe à côté de [recoverMissingBotTokens] : un bot HÉBERGÉ n'a
/// aucun jeton sur ce poste (le manager le rédige volontairement dans ses listes),
/// et le balayage d'identité n'avait donc rien à présenter à Discord — un bot dont
/// le nom vaut son ID restait affiché sous son ID. C'est la MÊME reprise qui est
/// réutilisée ici : même route (`POST /gateway/bots/{id}/token`), même écriture par
/// le chemin unique, et surtout la MÊME garde « une tentative par bot et par
/// lancement » ([BotTokenImporter.importAutomatically]) — jamais une seconde
/// infrastructure, donc jamais de rafale ni de second export d'un même jeton.
///
/// [accountBot] est la charge utile du compte pour ce bot : elle seule sait si le
/// serveur annonce la credential invalide (`token_invalid`), et elle rend le jeton
/// (`bot_token`) quand le serveur a choisi de le livrer.
///
/// Rend `true` quand un jeton utilisable est désormais écrit sur ce poste. Rend
/// `false` — sans rien casser, sans rien inventer, sans exception — quand il n'y a
/// personne à qui demander (hors ligne), quand le compte annonce le jeton invalide,
/// quand la route refuse (404, 409, 500) ou qu'une tentative a déjà eu lieu dans ce
/// lancement : la prochaine session retentera.
///
/// Ne journalise ni ne rend jamais la VALEUR du jeton : seules les issues typées de
/// [BotTokenImporter] circulent.
Future<bool> recoverBotTokenForIdentity({
  required MainApiClient? client,
  required String botId,
  required Map<String, dynamic> accountBot,
}) async {
  // (hors ligne) Rien ne part, et rien n'est réservé : une reconnexion rendra la
  // reprise possible.
  final activeClient = client;
  if (activeClient == null) return false;
  // Le serveur a livré le jeton dans sa réponse : la synchro l'écrira, il n'y a rien
  // à redemander — et redemander consommerait le quota du propriétaire pour rien.
  if ((accountBot['bot_token'] ?? '').toString().trim().isNotEmpty) return false;

  final outcome = await BotTokenImporter(
    client: activeClient,
  ).importAutomatically(
    botId: botId,
    serverAnnouncesTokenValid: accountBot['token_invalid'] != true,
    // L'appelant n'appelle cette fonction QUE pour un bot dont la fiche locale n'a
    // aucun jeton (c'est lui qui l'a constaté) : la garde de débit, elle, reste
    // dans la brique, avec la revendication de la tentative AVANT l'appel réseau.
    hasLocalToken: false,
  );
  // `imported` est la seule issue qui garantit l'écriture d'un jeton ; toutes les
  // autres (déjà tenté, annoncé invalide, refus du serveur, panne) laissent la fiche
  // intacte — c'est voulu, et il n'y a rien de plus à tenter ici.
  return outcome == BotTokenImportOutcome.imported;
}
