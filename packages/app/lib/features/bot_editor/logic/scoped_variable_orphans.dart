// VALEURS ORPHELINES DE VARIABLES SCOPÉES — module PUR, sans Flutter, sans E/S.
//
// POURQUOI : la base d'un bot peut contenir des VALEURS scopées (écrites par le
// bot à l'exécution) alors qu'aucune DÉFINITION n'a jamais été déclarée. L'écran
// des variables n'itérait que sur les définitions : les données du propriétaire
// étaient donc invisibles dans l'app alors qu'elles partent bien au bot.
//
// Deux règles non négociables, appliquées ici et pas ailleurs :
//   1. on DÉDUIT un NOM, jamais une VALEUR : une entrée détectée ne porte aucun
//      `defaultValue` — en fabriquer un serait inventer une valeur ;
//   2. une déduction ne remplace JAMAIS une déclaration : dès qu'une définition
//      déclarée existe pour (portée, clé normalisée), la clé n'est pas listée
//      une seconde fois.
//
// Ces entrées servent UNIQUEMENT à l'affichage : rien n'est persisté, donc la
// charge utile du bot (`scopedVariableDefinitions`) et sa forme restent
// strictement identiques, et aucune donnée existante n'est supprimée.

/// Marqueur d'une entrée déduite d'une valeur existante. C'est le SEUL ajout
/// autorisé : il n'existe jamais sur une définition déclarée par l'utilisateur.
const String kScopedVariableDetectedFlag = 'detected';

/// Nombre de contextes qui portent réellement une valeur pour la clé détectée.
const String kScopedVariableStoredCountKey = 'storedValueCount';

/// Ramène une clé de variable scopée à sa forme de comparaison.
///
/// Les définitions sont stockées sans préfixe `bc_` et les valeurs peuvent
/// trainer l'ancien préfixe : sans cette normalisation, une variable déclarée
/// serait listée une fois de plus comme « détectée » (double affichage).
String normalizeScopedVariableLookupKey(String rawKey) {
  final trimmed = rawKey.trim();
  if (trimmed.startsWith('bc_') && trimmed.length > 3) {
    return trimmed.substring(3);
  }
  return trimmed;
}

/// Vrai quand [definition] est une entrée DÉTECTÉE (jamais une déclaration).
bool isDetectedScopedDefinition(Map<String, dynamic> definition) {
  return definition[kScopedVariableDetectedFlag] == true;
}

/// Clé de référence affichée à l'utilisateur : forme actuelle, sans `bc_`.
String scopedVariableReferenceKey(String rawKey) {
  return normalizeScopedVariableLookupKey(rawKey);
}

/// Clé de référence historique (préfixe `bc_`). Elle ne s'affiche que lorsqu'elle
/// diffère de la forme actuelle, c'est-à-dire pour les données écrites avant le
/// changement de nommage — c'est ce que fait l'écran depuis toujours.
String scopedVariableLegacyReferenceKey(String rawKey) {
  final key = scopedVariableReferenceKey(rawKey);
  if (key.isEmpty) return key;
  return 'bc_$key';
}

/// Clé de comparaison (portée, clé) — deux dimensions dans une seule chaîne.
String _lookupId(String scope, String key) => '${scope.trim()}\u0000$key';

/// Liste les clés qui ont une VALEUR mais AUCUNE définition déclarée.
///
/// [scopedValues] est la carte réellement stockée : portée → contexte → clés.
/// Retour : une entrée par (portée, clé) orpheline, triée, sous la forme
/// `{key, scope, detected: true, storedValueCount}`. Aucune valeur n'est
/// recopiée : l'écran n'affiche que ce qui existe, via l'explorateur existant.
List<Map<String, dynamic>> detectScopedOrphanDefinitions({
  required List<Map<String, dynamic>> declaredDefinitions,
  required Map<String, Map<String, Map<String, dynamic>>> scopedValues,
}) {
  final declared = <String>{};
  for (final definition in declaredDefinitions) {
    final key = normalizeScopedVariableLookupKey(
      (definition['key'] ?? '').toString(),
    );
    final scope = (definition['scope'] ?? '').toString().trim();
    if (key.isEmpty || scope.isEmpty) continue;
    declared.add(_lookupId(scope, key));
  }

  final scopes = scopedValues.keys.toList()..sort();
  final detected = <Map<String, dynamic>>[];
  for (final scope in scopes) {
    final scopeKey = scope.trim();
    if (scopeKey.isEmpty) continue;

    final contextValues = scopedValues[scope];
    if (contextValues == null || contextValues.isEmpty) continue;

    // Compte les contextes par clé : c'est la seule mesure qu'on affiche, et
    // elle vient des données stockées, jamais d'une estimation.
    final contextsPerKey = <String, int>{};
    for (final values in contextValues.values) {
      final seenInContext = <String>{};
      for (final rawKey in values.keys) {
        final key = normalizeScopedVariableLookupKey(rawKey);
        if (key.isEmpty || !seenInContext.add(key)) continue;
        contextsPerKey.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }

    final keys = contextsPerKey.keys.toList()..sort();
    for (final key in keys) {
      // Règle 2 : une définition déclarée du même nom prime, toujours.
      if (declared.contains(_lookupId(scopeKey, key))) continue;
      detected.add(<String, dynamic>{
        'key': key,
        'scope': scopeKey,
        kScopedVariableDetectedFlag: true,
        kScopedVariableStoredCountKey: contextsPerKey[key],
      });
    }
  }
  return detected;
}

/// Concatène déclarations puis déductions, sans écraser ni fusionner.
///
/// L'ordre compte pour l'affichage : dans chaque portée, ce que l'utilisateur a
/// déclaré reste en tête et les entrées détectées ferment la marche.
List<Map<String, dynamic>> mergeScopedDefinitions({
  required List<Map<String, dynamic>> declaredDefinitions,
  required List<Map<String, dynamic>> detectedDefinitions,
}) {
  return <Map<String, dynamic>>[
    ...declaredDefinitions,
    ...detectedDefinitions,
  ];
}

/// Filtre les entrées affichées (recherche sur la clé ou la portée).
///
/// Une recherche ne doit jamais faire disparaitre une donnée réelle : sans
/// requête, la liste est renvoyée telle quelle.
List<Map<String, dynamic>> filterScopedDefinitions({
  required List<Map<String, dynamic>> definitions,
  required String searchQuery,
}) {
  final query = searchQuery.trim().toLowerCase();
  if (query.isEmpty) return List<Map<String, dynamic>>.from(definitions);
  return definitions
      .where(
        (definition) =>
            (definition['key'] ?? '').toString().toLowerCase().contains(query) ||
            (definition['scope'] ?? '')
                .toString()
                .toLowerCase()
                .contains(query),
      )
      .toList(growable: false);
}

/// Groupe les entrées par portée, dans l'ordre [knownScopes] puis les portées
/// inconnues (triées), pour que l'affichage reste stable d'un chargement à
/// l'autre. Une portée sans entrée n'apparait pas : rien n'est inventé.
List<MapEntry<String, List<Map<String, dynamic>>>> groupScopedDefinitionsByScope({
  required List<Map<String, dynamic>> definitions,
  required List<String> knownScopes,
  required String searchQuery,
}) {
  final filtered = filterScopedDefinitions(
    definitions: definitions,
    searchQuery: searchQuery,
  );

  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final definition in filtered) {
    final scope = (definition['scope'] ?? '').toString().trim();
    if (scope.isEmpty) continue;
    (grouped[scope] ??= <Map<String, dynamic>>[]).add(definition);
  }

  final ordered = <MapEntry<String, List<Map<String, dynamic>>>>[];
  for (final scope in knownScopes) {
    final entries = grouped.remove(scope);
    if (entries != null && entries.isNotEmpty) {
      ordered.add(MapEntry<String, List<Map<String, dynamic>>>(scope, entries));
    }
  }

  final remaining = grouped.keys.toList()..sort();
  for (final scope in remaining) {
    ordered.add(
      MapEntry<String, List<Map<String, dynamic>>>(scope, grouped[scope]!),
    );
  }
  return ordered;
}
