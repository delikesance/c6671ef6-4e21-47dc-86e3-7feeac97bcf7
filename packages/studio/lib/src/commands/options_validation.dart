import 'validation_problem.dart';

/// Refus sur une liste d'options, ou `null` si Discord l'acceptera.
ValidationProblem? validateOptions(List<Map<String, dynamic>> options) {
  if (options.length > 25) {
    return const ValidationProblem(ValidationKind.optionsTooMany, max: 25);
  }
  final seen = <String>{};
  var optionalSeen = false;
  for (final o in options) {
    final name = '${o['name'] ?? ''}'.trim();
    if (!RegExp(r'^[-_\p{L}\p{N}]{1,32}$', unicode: true).hasMatch(name) ||
        name != name.toLowerCase()) {
      return ValidationProblem(ValidationKind.optionNameInvalid, name: name);
    }
    if (!seen.add(name)) {
      return ValidationProblem(ValidationKind.optionDuplicate, name: name);
    }
    final d = '${o['description'] ?? ''}'.trim();
    if (d.isEmpty || d.length > 100) {
      return ValidationProblem(
        ValidationKind.optionDescriptionInvalid,
        name: name,
      );
    }
    final required = o['required'] == true;
    if (required && optionalSeen) {
      return ValidationProblem(ValidationKind.optionRequiredOrder, name: name);
    }
    if (!required) optionalSeen = true;
  }
  return null;
}

/// Édite les options simples d'une commande (texte, nombre, utilisateur, salon…).
/// Les options à structure (sous-commandes, choix, bornes) ne sont pas modifiées
/// ici : elles sont conservées telles quelles. Rend la nouvelle liste, ou `null`.
