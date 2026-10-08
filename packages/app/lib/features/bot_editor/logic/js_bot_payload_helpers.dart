import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Aides de construction de la charge utile JS, extraites de
/// `js_bot_payload_builder.dart` pour que ce dernier reste court et lisible.
///
/// POURQUOI ces fonctions sont ici et non dans le constructeur : elles sont
/// pures (aucune lecture de stockage) et donc testables isolement ; les garder
/// dans un fichier dédié évite de faire grossir le constructeur de charge, qui
/// porte déjà la garde anti-charge-vide.

/// Traduit les actions d'un workflow (moteur dart) en un script JS minimal.
///
/// Rend `null` quand AUCUNE action ne dit quelque chose : c'est ce `null` qui
/// alimente la garde anti-charge-vide (une commande sans script est sautée).
String? synthesizeJsFromWorkflowActions(
  List<dynamic> actions, {
  bool preferMessage = false,
}) {
  for (final raw in actions) {
    if (raw is! Map) {
      continue;
    }
    final type = (raw['type'] ?? '').toString();
    if (type != 'respondWithMessage' && type != 'sendMessage') {
      continue;
    }
    final payload = Map<String, dynamic>.from(
      (raw['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
    final content = (payload['content'] ?? '').toString();
    if (content.trim().isEmpty) {
      continue;
    }
    final ephemeral = payload['ephemeral'] == true;
    if (preferMessage) {
      return 'await message.reply(${jsonEncode(content)});';
    }
    if (ephemeral) {
      return 'await interaction.reply({ content: ${jsonEncode(content)}, ephemeral: true });';
    }
    return 'await interaction.reply(${jsonEncode(content)});';
  }
  return null;
}

/// Ajoute un suffixe numérique (`name`, `name_2`, ...) en cas de collision, pour
/// que la charge utile ne contienne jamais deux noms identiques (le runner JS
/// refuse cela avec un 400).
///
/// Filet de sécurité pour les configs existantes : l'éditeur refuse désormais
/// les doublons (voir [isCommandNameTaken]). Chaque renommage est signalé en
/// avertissement et via [onRenamed].
String deduplicateCommandName(
  String name,
  Set<String> usedNames, {
  void Function(String original, String renamed)? onRenamed,
}) {
  // Le runner compare `trim().toLowerCase()` : « Ping » et « ping » sont un
  // doublon pour lui. Le schéma limite aussi le nom à 32 caractères, suffixe
  // compris.
  String fit(String base, String suffix) {
    final room = 32 - suffix.length;
    final head = base.length > room ? base.substring(0, room) : base;
    return '$head$suffix';
  }

  final trimmed = name.trim();
  var candidate = fit(trimmed, '');
  if (usedNames.add(candidate.toLowerCase())) return candidate;
  var suffix = 2;
  candidate = fit(trimmed, '_$suffix');
  while (!usedNames.add(candidate.toLowerCase())) {
    suffix += 1;
    candidate = fit(trimmed, '_$suffix');
  }
  final message =
      'Duplicate command name "$name" renamed to "$candidate" in the payload.';
  debugPrint('[buildJsBotPayload] WARNING: $message');
  developer.log(message, name: 'buildJsBotPayload', level: 900);
  onRenamed?.call(name, candidate);
  return candidate;
}

/// Vrai si [name] est déjà pris par une autre commande (comparaison
/// `trim().toLowerCase()`, comme le runner). Renommer vers son propre nom reste
/// permis : l'appelant retire le nom courant de [existingNames].
bool isCommandNameTaken(String name, Iterable<String> existingNames) {
  final key = name.trim().toLowerCase();
  if (key.isEmpty) return false;
  return existingNames.any((e) => e.trim().toLowerCase() == key);
}

/// Nom libre proposé pour une copie : `<nom>_copie`, puis `<nom>_copie_2`, ...
/// (32 caractères max, suffixe compris).
String suggestDuplicateCommandName(
  String name,
  Iterable<String> existingNames, {
  String copySuffix = '_copie',
}) {
  String fit(String suffix) {
    final base = name.trim();
    final room = 32 - suffix.length;
    return '${base.length > room ? base.substring(0, room) : base}$suffix';
  }

  var candidate = fit(copySuffix);
  var n = 2;
  while (isCommandNameTaken(candidate, existingNames)) {
    candidate = fit('${copySuffix}_$n');
    n += 1;
  }
  return candidate;
}

/// Ramène un type de commande stocké à l'un des trois types Discord acceptés.
String resolveDiscordCommandType(Object? rawCommandType) {
  final raw = (rawCommandType ?? 'chatInput').toString().trim().toLowerCase();
  if (raw == 'user' || raw == 'usercommand' || raw == 'user_command') {
    return 'user';
  }
  if (raw == 'message' || raw == 'messagecommand' || raw == 'message_command') {
    return 'message';
  }
  return 'chatInput';
}
