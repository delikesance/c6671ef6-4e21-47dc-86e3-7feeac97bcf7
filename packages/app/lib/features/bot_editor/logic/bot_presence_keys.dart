/// Les activités (statuts tournants) d'un bot sont stockées sous DEUX clés :
///
/// * `activities` : écrite par la page Paramètres, et lue EN PREMIER par l'app
///   (`activities ?? statuses`) ;
/// * `statuses` : la seule clé que porte la config du Manager
///   (`BotConfig.toJson`) et que lit le runner.
///
/// Une config distante ne contient donc que `statuses`. Fusionnée telle quelle
/// dans les données locales, elle laissait les anciennes `activities` masquer
/// les nouvelles : un pull ne changeait ni l'écran Paramètres ni le statut du
/// bot local. Tout code qui importe des activités doit passer par ici pour que
/// les deux clés disent la même chose.
///
/// Copie dans [target] les activités de [incoming] sous les deux clés. Sans
/// aucune des deux clés dans [incoming] (serveur ancien, fichier partiel),
/// [target] est laissé intact. Rend `true` si [target] a été modifié.
bool mirrorPresenceActivities(
  Map<String, dynamic> target,
  Map<String, dynamic> incoming,
) {
  // `statuses` d'abord : c'est ce que le runner exécute réellement.
  final raw = incoming.containsKey('statuses')
      ? incoming['statuses']
      : incoming['activities'];
  if (raw is! List) return false;

  final entries = <Map<String, dynamic>>[
    for (final item in raw.whereType<Map>())
      _withNameAndText(Map<String, dynamic>.from(item)),
  ];
  target['activities'] = entries;
  target['statuses'] = [for (final e in entries) Map<String, dynamic>.of(e)];
  return true;
}

/// Les anciennes entrées portent `text`, les nouvelles `name` : on garde les
/// deux, comme `BotStatusConfig.toJson`.
Map<String, dynamic> _withNameAndText(Map<String, dynamic> entry) {
  final name = (entry['name'] ?? entry['text'] ?? '').toString();
  entry['name'] = name;
  entry['text'] = name;
  return entry;
}
