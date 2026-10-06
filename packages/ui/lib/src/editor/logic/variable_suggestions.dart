import 'package:bot_creator_shared/utils/variable_catalog.dart';

import '../models/variable_suggestion.dart';

/// Suggestions de variables d'un éditeur d'actions : le catalogue du moteur
/// (contexte, membre, serveur, message… + arguments), celles de l'événement
/// d'un workflow, les variables globales (`global.<clé>`), les variables à
/// portée (`<portée>.<clé>`) et les clés des actions (`<clé>.body`).
List<VariableSuggestion> buildVariableSuggestions({
  Iterable<String> argumentNames = const [],
  String? eventName,
  Iterable<String> globalKeys = const [],
  Iterable<({String scope, String key})> scoped = const [],
  Iterable<String> actionKeys = const [],
}) {
  final byName = <String, VariableSuggestion>{};
  void add(VariableSuggestion s) => byName.putIfAbsent(s.name, () => s);

  VariableCatalog.getAlwaysAvailableSuggestions(
    argumentNames: argumentNames.toList(),
  ).forEach(add);
  VariableCatalog.getBaseHydratedSuggestions().forEach(add);
  if (eventName != null && eventName.isNotEmpty) {
    VariableCatalog.getSuggestionsForEvent(eventName).forEach(add);
  }

  void addName(String name) => add(
    VariableSuggestion(
      name: name,
      kind: VariableSuggestionKind.unknown,
      description: variableDescription(name),
      category: inferCategory(name),
    ),
  );
  for (final key in globalKeys) {
    if (key.trim().isNotEmpty) addName('global.${key.trim()}');
  }
  for (final def in scoped) {
    if (def.scope.trim().isNotEmpty && def.key.trim().isNotEmpty) {
      addName('${def.scope.trim()}.${def.key.trim()}');
    }
  }
  for (final key in actionKeys) {
    if (key.trim().isNotEmpty) addName('${key.trim()}.body');
  }
  return byName.values.toList();
}
