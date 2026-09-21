import 'dart:convert';

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
String deduplicateCommandName(String name, Set<String> usedNames) {
  if (usedNames.add(name)) return name;
  var suffix = 2;
  var candidate = '${name}_$suffix';
  while (!usedNames.add(candidate)) {
    suffix += 1;
    candidate = '${name}_$suffix';
  }
  debugPrint('[buildJsBotPayload] Duplicate "$name" -> "$candidate".');
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
