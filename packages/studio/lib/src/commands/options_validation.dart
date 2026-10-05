/// Erreur lisible sur une liste d'options, ou `null` si Discord l'acceptera.
String? validateOptions(List<Map<String, dynamic>> options) {
  if (options.length > 25) return '25 options au maximum.';
  final seen = <String>{};
  var optionalSeen = false;
  for (final o in options) {
    final name = '${o['name'] ?? ''}'.trim();
    if (!RegExp(r'^[-_\p{L}\p{N}]{1,32}$', unicode: true).hasMatch(name) ||
        name != name.toLowerCase()) {
      return 'Option « $name » : minuscules, chiffres, « - » et « _ », 32 caractères au plus.';
    }
    if (!seen.add(name)) return 'Option « $name » en double.';
    final d = '${o['description'] ?? ''}'.trim();
    if (d.isEmpty || d.length > 100) {
      return 'Option « $name » : description requise (100 caractères au plus).';
    }
    final required = o['required'] == true;
    if (required && optionalSeen) {
      return 'Les options obligatoires doivent précéder les facultatives (« $name »).';
    }
    if (!required) optionalSeen = true;
  }
  return null;
}

/// Édite les options simples d'une commande (texte, nombre, utilisateur, salon…).
/// Les options à structure (sous-commandes, choix, bornes) ne sont pas modifiées
/// ici : elles sont conservées telles quelles. Rend la nouvelle liste, ou `null`.
