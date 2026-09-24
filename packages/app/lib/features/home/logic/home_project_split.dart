/// Sépare les projets de l'accueil en « à moi » et « partagés avec moi ».
///
/// `collaborativeBotIds` vient du SERVEUR (le champ `is_collaborative` de
/// `GET /gateway/bots`) — jamais d'une heuristique locale : un bot qui
/// apparaîtrait dans les deux sections est un bug.
///
/// L'ordre d'entrée est préservé dans chaque section (l'accueil garde l'ordre
/// que la liste lui a donné). Un identifiant collaboratif qui ne correspond à
/// aucun projet est simplement ignoré, et un projet sans identifiant reste
/// dans « à moi » : dans les deux cas, rien ne jette — une entrée abîmée ne
/// doit pas faire disparaître l'écran d'accueil.
///
/// Fonction pure : aucun accès réseau, aucun import Flutter.
({List<Map<String, dynamic>> owned, List<Map<String, dynamic>> shared})
splitHomeProjects(
  List<Map<String, dynamic>> apps,
  Set<String> collaborativeBotIds,
) {
  final owned = <Map<String, dynamic>>[];
  final shared = <Map<String, dynamic>>[];

  for (final app in apps) {
    final id = (app['id'] ?? app['bot_id'])?.toString();
    if (id != null && id.isNotEmpty && collaborativeBotIds.contains(id)) {
      shared.add(app);
    } else {
      owned.add(app);
    }
  }

  return (owned: owned, shared: shared);
}
