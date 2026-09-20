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
}) async {
  final outcomes = <BotTokenImportOutcome>[];
  final activeClient = client;
  // (hors ligne) Aucun compte : aucune tentative, même pas la réservation d'un
  // identifiant, pour qu'une reconnexion rende la reprise possible.
  if (activeClient == null) return outcomes;

  final importer = BotTokenImporter(client: activeClient);
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
