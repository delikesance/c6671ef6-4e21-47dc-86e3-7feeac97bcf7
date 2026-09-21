// URL d'invitation Discord d'un bot, en UN seul endroit.
//
// Deux chemins invitent un bot dans un serveur (bots locaux, bots clé en main
// hébergés) : sans helper partagé, chacun recomposait son URL et les scopes
// divergeaient — un bot invité sans `applications.commands` rejoint le serveur
// mais ses commandes slash restent indisponibles, sans que rien ne le signale.

/// Ouvre un lien dans le navigateur du système.
///
/// Type injectable : les tests observent l'URL réellement ouverte (et comptent
/// les ouvertures) sans lancer de navigateur.
typedef DiscordUrlOpener = Future<bool> Function(Uri uri);

/// Scopes demandés : `bot` fait entrer le bot dans le serveur,
/// `applications.commands` y autorise l'enregistrement de ses commandes slash.
/// Séparateur `+` : c'est la forme que Discord lui-même rend dans `invite_url`.
const String _botScopes = 'bot+applications.commands';

/// Permission `ADMINISTRATEUR` (8) : un bot clé en main arrive prêt à écrire et
/// à modérer, sans que l'utilisateur ait à cocher des cases de permissions.
const int _invitePermissions = 8;

/// URL d'invitation OAuth2 du bot portant [applicationId].
///
/// Chaîne vide quand l'identifiant est vide : il n'y a alors rien à ouvrir, et
/// `Uri.parse('')` fabriquerait une URL relative silencieusement inutile.
String buildDiscordInviteUrl(String applicationId) {
  final id = applicationId.trim();
  if (id.isEmpty) return '';
  return 'https://discord.com/api/oauth2/authorize'
      '?client_id=$id'
      '&scope=$_botScopes'
      '&permissions=$_invitePermissions';
}

/// Même URL que [buildDiscordInviteUrl], prête à être ouverte.
///
/// `null` quand l'identifiant est vide.
Uri? discordInviteUri(String applicationId) {
  final url = buildDiscordInviteUrl(applicationId);
  return url.isEmpty ? null : Uri.parse(url);
}
