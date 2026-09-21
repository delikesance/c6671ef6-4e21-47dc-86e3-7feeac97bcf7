// Le BALAYAGE d'identité : demander à Discord le vrai nom des bots du compte dont le nom
// local n'en est pas un — y compris, et surtout, pour un bot HÉBERGÉ.
//
// Pourquoi un fichier à part : réparer UN bot (`bot_identity_sync.dart`) suppose un jeton
// déjà en main. Ici, on s'occupe de l'OBTENIR quand ce poste ne l'a pas, ce qui est le cas
// NORMAL d'un bot hébergé : le manager RÉDIGE `bot_token` dans ses listes (« Zero plaintext
// token in summary lists ») et le jeton vit chiffré côté compte. Sans ce détour, la
// réparation n'avait rien à présenter à Discord et le nom restait l'ID à l'écran — le défaut
// constaté par le propriétaire, alors que la récupération de l'identité, elle, existait déjà.
//
// Ce que ce fichier tient par l'exécution :
//   * le jeton n'est redemandé qu'à la SEULE route qui le rend
//     (`POST /gateway/bots/{id}/token`), via `recoverBotTokenForIdentity`, donc avec la garde
//     « une tentative par bot et par lancement » déjà en place : aucune seconde
//     infrastructure, aucun second export d'un même jeton, aucune rafale ;
//   * un échec de cette reprise (hors ligne, 404, 409, 5xx) ne casse rien et n'invente rien :
//     il est journalisé court — sans jeton, ni entier ni tronqué —, l'écran n'attend jamais
//     rien, la synchro des bots se poursuit, et la prochaine session retentera ;
//   * un nom qui est un nom n'est jamais réécrit : la condition « vide ou égal à l'ID » est
//     réévaluée sur la fiche, dans `refreshBotIdentityFromDiscord`.
import 'dart:developer' as developer;

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_identity_sync.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_token_auto_recovery.dart';
import 'package:http/http.dart' as http;

/// Balayage de synchro : pour chaque bot du compte dont le nom local n'en est pas un,
/// récupère l'identité réelle — au plus une fois par bot et par lancement.
///
/// [localAppOf] rend la fiche DÉJÀ écrite sur ce poste (nom et jeton), relue à chaque bot :
/// c'est la seule source du jeton, que le manager ne renvoie jamais, et une relecture voit
/// la fiche réparée par le bot précédent. Un bot sans fiche locale est ignoré (la synchro
/// l'écrira de toute façon).
///
/// [client] est le client du COMPTE. C'est par lui que le jeton d'un bot HÉBERGÉ — qui n'en
/// a aucun sur ce poste — est repris (`POST /gateway/bots/{id}/token`) AVANT d'interroger
/// Discord. `null` (hors ligne, compte non configuré) : rien ne part et aucune tentative
/// n'est consommée, pour qu'une reconnexion rende la reprise possible.
///
/// Les tentatives sont espacées comme celles de la reprise de jeton : Discord tolère mal une
/// rafale, et un 429 serait un échec fabriqué par le client lui-même.
Future<List<BotIdentitySyncOutcome>> refreshBotIdentitiesFromDiscord({
  required List<Map<String, dynamic>> accountBots,
  required Future<Map<String, dynamic>> Function(String botId) localAppOf,
  MainApiClient? client,
  http.Client? httpClient,
  Duration betweenAttempts = const Duration(milliseconds: 300),
}) async {
  final outcomes = <BotIdentitySyncOutcome>[];
  for (final bot in accountBots) {
    final botId = (bot['bot_id'] ?? '').toString().trim();
    if (botId.isEmpty) continue;
    final Map<String, dynamic> local;
    try {
      local = await localAppOf(botId);
    } catch (_) {
      continue;
    }
    // Nom déjà réel : ce n'est pas une tentative, donc cela ne consomme pas la comptabilité
    // du lancement.
    if (!botNameHidesIdentity(local['name']?.toString(), botId)) continue;

    if ((local['token'] ?? '').toString().trim().isEmpty) {
      // Aucun jeton sur ce poste. Sans compte joint, rien ne part — le comportement d'un
      // poste sans compte reste celui d'avant. Avec, on reprend le jeton par la route
      // dédiée : c'est exactement ce qui manquait pour un bot hébergé.
      if (client == null) continue;
      if (outcomes.isNotEmpty) {
        await Future<void>.delayed(betweenAttempts);
      }
      try {
        await recoverBotTokenForIdentity(
          client: client,
          botId: botId,
          accountBot: bot,
        );
      } catch (error) {
        // Une erreur d'ICI ne doit jamais faire échouer la synchro des bots : on la
        // journalise court et on passe au bot suivant. Seul le TYPE de l'erreur est
        // journalisé — un message d'erreur peut recopier ce qui l'a causée, et un jeton ne
        // doit jamais finir dans un journal, ni entier ni tronqué.
        developer.log(
          'Bot token recovery for the identity request failed for bot $botId '
          '(${error.runtimeType}); the sync continues.',
          name: 'BotIdentityScan',
        );
      }
    } else if (outcomes.isNotEmpty) {
      await Future<void>.delayed(betweenAttempts);
    }

    // La fiche est relue par `refreshBotIdentityFromDiscord` : si la reprise vient d'y
    // écrire un jeton, c'est LUI qui interroge Discord ; sinon l'issue dit honnêtement
    // `noToken` — aucune requête, aucun nom inventé.
    outcomes.add(
      await refreshBotIdentityFromDiscord(
        botId: botId,
        httpClient: httpClient,
      ),
    );
  }
  return outcomes;
}
