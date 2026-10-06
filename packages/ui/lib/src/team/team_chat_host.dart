/// Contrat entre l'écran « Équipe et tchat » d'un bot (partagé) et la façon dont
/// chaque client parle au serveur : l'app passe par `MainApiClient` (et lit le
/// portail Discord avec le jeton local du bot), le Studio par `StudioApi` (le
/// Manager garde le jeton : il lit lui-même l'équipe du portail et les
/// pseudonymes Discord, `GET …/team/portal` et `GET …/team/users/{id}`).
library;

import 'team_models.dart';

abstract class TeamChatHost {
  const TeamChatHost();

  /// Prépare l'hôte pour [botId] (résolution du client, session…). `false` = le
  /// tchat n'a pas de serveur à qui parler : l'écran le dit au lieu de charger.
  /// Le tchat d'équipe est une donnée du COMPTE, partagée entre appareils : il
  /// n'a de sens que côté Manager.
  Future<bool> prepare(String botId);

  /// Le propriétaire et les collaborateurs du bot. Lève si injoignable.
  Future<List<BotCollaborator>> collaborators(String botId);

  /// Le fil du tchat, dans l'ordre que le serveur rend (l'écran le trie du plus
  /// ancien au plus récent). Lève si injoignable.
  Future<List<TeamChatMessage>> messages(String botId);

  /// Droits EFFECTIFS du lecteur sur ce bot (`my_permissions`). `null` = le
  /// serveur n'annonce aucun droit : INCONNUS, l'écran masque alors les
  /// contrôles de gestion. Peut lever, avec le même effet.
  Future<BotPermissions?> myPermissions(String botId);

  /// Publie un message et rend celui que le serveur a créé, ou `null` quand la
  /// réponse ne le porte pas (il arrivera alors par [events]). Lève en cas
  /// d'échec : l'écran réessaie.
  Future<TeamChatMessage?> postMessage(String botId, String content);

  /// Ajoute un collaborateur, ou remplace ses droits s'il est déjà membre.
  Future<void> upsertCollaborator(
    String botId,
    String userId,
    BotPermissions permissions,
  );

  Future<void> removeCollaborator(String botId, String userId);

  /// Le temps réel : messages et changements d'équipe poussés par le serveur,
  /// et [TeamChatResyncEvent] quand l'écran doit relire la conversation. Écouté
  /// une seule fois par écran ; annuler l'abonnement libère tout.
  Stream<TeamChatEvent> events(String botId);

  /// Nom d'affichage du lecteur, pour ses messages en cours d'envoi.
  Future<String> currentUserName();

  /// L'équipe du portail développeur Discord du bot, en lecture seule. `null` =
  /// inconnue (jeton absent, rien d'exploitable chez Discord) : aucune mise en
  /// garde n'est alors affichée, une absence ne se suppose pas. Peut lever si
  /// Discord est injoignable : l'écran l'ignore, pour la même raison.
  Future<TeamPortalInfo?> portalTeam(String botId) async => null;

  /// Pseudonyme et avatar Discord d'un utilisateur du fil qui n'est ni membre ni
  /// dans le portail. `null` = non résolu (l'identifiant reste affiché).
  Future<TeamUserProfile?> lookupUser(String botId, String userId) async =>
      null;
}
