import 'package:bot_creator_ui/bot_creator_ui.dart';
import 'package:flutter/material.dart';

/// Catégories de la palette d'actions, avec leur libellé français.
enum ActionCategory {
  messages('Messages', BlockFamily.messages, Icons.message_outlined),
  reactions('Réactions', BlockFamily.messages, Icons.emoji_emotions_outlined),
  channels('Salons', BlockFamily.moderation, Icons.tag),
  moderation('Modération', BlockFamily.moderation, Icons.shield_outlined),
  components('Composants', BlockFamily.messages, Icons.widgets_outlined),
  webhooks('Webhooks', BlockFamily.http, Icons.webhook_rounded),
  guild('Serveur & Membres', BlockFamily.moderation, Icons.groups_outlined),
  http('HTTP & Variables', BlockFamily.http, Icons.http),
  workflows('Workflows', BlockFamily.logic, Icons.account_tree_outlined),
  logic('Logique & Flux', BlockFamily.logic, Icons.fork_right),
  interactions('Interactions', BlockFamily.messages, Icons.touch_app_outlined),
  music('Musique', BlockFamily.data, Icons.music_note);

  const ActionCategory(this.label, this.family, this.icon);

  final String label;
  final BlockFamily family;
  final IconData icon;
}

class ActionInfo {
  const ActionInfo(this.label, this.category);

  final String label;
  final ActionCategory category;
}

/// Identifiant d'action (`ActionType.name`) -> libellé et catégorie, tels que
/// l'app les affiche (`app_fr.arb`, `getCategoryForAction`). Un type inconnu
/// retombe sur [infoFor] : bloc générique, jamais une erreur.
const Map<String, ActionInfo> actionCatalog = {
  // Messages
  'sendMessage': ActionInfo('Envoyer un message', ActionCategory.messages),
  'editMessage': ActionInfo('Modifier un message', ActionCategory.messages),
  'deleteMessages': ActionInfo(
    'Supprimer des messages',
    ActionCategory.messages,
  ),
  'pinMessage': ActionInfo('Épingler un message', ActionCategory.messages),
  'unpinMessage': ActionInfo('Désépingler un message', ActionCategory.messages),
  'getMessage': ActionInfo('Récupérer un message', ActionCategory.messages),
  'createPoll': ActionInfo('Créer un sondage', ActionCategory.messages),
  'endPoll': ActionInfo('Clôturer un sondage', ActionCategory.messages),
  'deleteTrigger': ActionInfo(
    'Supprimer le message déclencheur',
    ActionCategory.messages,
  ),
  'attachImage': ActionInfo('Joindre une image', ActionCategory.messages),
  // Réactions
  'addReaction': ActionInfo('Ajouter une réaction', ActionCategory.reactions),
  'removeReaction': ActionInfo(
    'Retirer une réaction',
    ActionCategory.reactions,
  ),
  'clearAllReactions': ActionInfo(
    'Retirer toutes les réactions',
    ActionCategory.reactions,
  ),
  // Salons
  'createChannel': ActionInfo('Créer un salon', ActionCategory.channels),
  'updateChannel': ActionInfo('Modifier un salon', ActionCategory.channels),
  'removeChannel': ActionInfo('Supprimer un salon', ActionCategory.channels),
  'createInvite': ActionInfo('Créer une invitation', ActionCategory.channels),
  'deleteInvite': ActionInfo(
    'Supprimer une invitation',
    ActionCategory.channels,
  ),
  'getInvite': ActionInfo('Récupérer une invitation', ActionCategory.channels),
  'createThread': ActionInfo('Créer un fil', ActionCategory.channels),
  'addThreadMember': ActionInfo(
    'Ajouter un membre au fil',
    ActionCategory.channels,
  ),
  'removeThreadMember': ActionInfo(
    'Retirer un membre du fil',
    ActionCategory.channels,
  ),
  'editChannelPermissions': ActionInfo(
    'Modifier les permissions du salon',
    ActionCategory.channels,
  ),
  'deleteChannelPermission': ActionInfo(
    'Supprimer une permission du salon',
    ActionCategory.channels,
  ),
  // Modération
  'banUser': ActionInfo('Bannir un utilisateur', ActionCategory.moderation),
  'unbanUser': ActionInfo('Débannir un utilisateur', ActionCategory.moderation),
  'kickUser': ActionInfo('Expulser un utilisateur', ActionCategory.moderation),
  'muteUser': ActionInfo(
    'Rendre muet un utilisateur',
    ActionCategory.moderation,
  ),
  'unmuteUser': ActionInfo(
    "Réactiver la parole d'un utilisateur",
    ActionCategory.moderation,
  ),
  'addRole': ActionInfo('Ajouter un rôle', ActionCategory.moderation),
  'removeRole': ActionInfo('Retirer un rôle', ActionCategory.moderation),
  'moveToVoiceChannel': ActionInfo(
    'Déplacer vers un vocal',
    ActionCategory.moderation,
  ),
  'disconnectFromVoice': ActionInfo(
    'Déconnecter du vocal',
    ActionCategory.moderation,
  ),
  'serverMuteMember': ActionInfo(
    'Rendre muet côté serveur',
    ActionCategory.moderation,
  ),
  'serverDeafenMember': ActionInfo(
    'Assourdir côté serveur',
    ActionCategory.moderation,
  ),
  'createAutoModRule': ActionInfo(
    'Créer une règle AutoMod',
    ActionCategory.moderation,
  ),
  'deleteAutoModRule': ActionInfo(
    'Supprimer une règle AutoMod',
    ActionCategory.moderation,
  ),
  'listAutoModRules': ActionInfo(
    'Lister les règles AutoMod',
    ActionCategory.moderation,
  ),
  'setNickname': ActionInfo('Changer le surnom', ActionCategory.moderation),
  'slowmode': ActionInfo('Mode lent', ActionCategory.moderation),
  // Composants
  'sendComponentV2': ActionInfo(
    'Envoyer un composant V2 (déprécié)',
    ActionCategory.components,
  ),
  'editComponentV2': ActionInfo(
    'Modifier un composant V2',
    ActionCategory.components,
  ),
  // Webhooks
  'sendWebhook': ActionInfo('Envoyer un Webhook', ActionCategory.webhooks),
  'editWebhook': ActionInfo('Modifier un webhook', ActionCategory.webhooks),
  'deleteWebhook': ActionInfo('Supprimer un webhook', ActionCategory.webhooks),
  'listWebhooks': ActionInfo('Lister les webhooks', ActionCategory.webhooks),
  'getWebhook': ActionInfo('Récupérer un webhook', ActionCategory.webhooks),
  // Serveur & Membres
  'updateGuild': ActionInfo('Mettre à jour le serveur', ActionCategory.guild),
  'leaveGuild': ActionInfo('Faire quitter le serveur', ActionCategory.guild),
  'updateAutoMod': ActionInfo('Mettre à jour AutoMod', ActionCategory.guild),
  'listMembers': ActionInfo('Lister les membres', ActionCategory.guild),
  'getMember': ActionInfo('Récupérer un membre', ActionCategory.guild),
  'createEmoji': ActionInfo('Créer un emoji', ActionCategory.guild),
  'updateEmoji': ActionInfo('Modifier un emoji', ActionCategory.guild),
  'deleteEmoji': ActionInfo("Supprimer l'émoji", ActionCategory.guild),
  'getGuildOnboarding': ActionInfo(
    "Récupérer l'onboarding serveur",
    ActionCategory.guild,
  ),
  'updateGuildOnboarding': ActionInfo(
    "Modifier l'onboarding serveur",
    ActionCategory.guild,
  ),
  'updateSelfUser': ActionInfo(
    'Modifier le profil du bot',
    ActionCategory.guild,
  ),
  // HTTP & Variables
  'httpRequest': ActionInfo('Requête HTTP', ActionCategory.http),
  'setGlobalVariable': ActionInfo(
    'Définir une variable (tout le bot)',
    ActionCategory.http,
  ),
  'getGlobalVariable': ActionInfo(
    'Lire une variable (tout le bot)',
    ActionCategory.http,
  ),
  'removeGlobalVariable': ActionInfo(
    'Supprimer une variable (tout le bot)',
    ActionCategory.http,
  ),
  'setScopedVariable': ActionInfo(
    'Définir une variable (par serveur, membre…)',
    ActionCategory.http,
  ),
  'setTemporaryVariable': ActionInfo(
    'Définir une variable temporaire',
    ActionCategory.http,
  ),
  'getScopedVariable': ActionInfo(
    'Lire une variable (par serveur, membre…)',
    ActionCategory.http,
  ),
  'removeScopedVariable': ActionInfo(
    'Supprimer une variable (par serveur, membre…)',
    ActionCategory.http,
  ),
  'renameScopedVariable': ActionInfo(
    'Renommer une variable (par serveur, membre…)',
    ActionCategory.http,
  ),
  'listScopedVariableIndex': ActionInfo(
    "Lister les valeurs d'une variable (par serveur, membre…)",
    ActionCategory.http,
  ),
  'appendArrayElement': ActionInfo(
    'Ajouter un élément à un tableau',
    ActionCategory.http,
  ),
  'removeArrayElement': ActionInfo(
    'Retirer un élément de tableau',
    ActionCategory.http,
  ),
  'queryArray': ActionInfo('Interroger un tableau', ActionCategory.http),
  // Workflows
  'runWorkflow': ActionInfo('Exécuter un workflow', ActionCategory.workflows),
  'runBdfdScript': ActionInfo(
    'Exécuter un script BDFD',
    ActionCategory.workflows,
  ),
  'debugProfile': ActionInfo('Profil de débogage', ActionCategory.workflows),
  'log': ActionInfo('Log', ActionCategory.workflows),
  'runtimeJsonBlock': ActionInfo(
    "Bloc JSON d'exécution",
    ActionCategory.workflows,
  ),
  'runtimeImageBlock': ActionInfo(
    "Bloc Image d'exécution",
    ActionCategory.workflows,
  ),
  'registerGuildCommands': ActionInfo(
    'Enregistrer les commandes',
    ActionCategory.workflows,
  ),
  'unregisterGuildCommands': ActionInfo(
    'Désenregistrer les commandes',
    ActionCategory.workflows,
  ),
  // Logique & Flux
  'ifBlock': ActionInfo('Bloc SI / SINON', ActionCategory.logic),
  'stopUnless': ActionInfo('Arrêter sauf si condition', ActionCategory.logic),
  'forLoop': ActionInfo('Boucle Pour', ActionCategory.logic),
  'jsonForEachLoop': ActionInfo(
    'Boucle Pour Chaque JSON',
    ActionCategory.logic,
  ),
  'calculate': ActionInfo('Calculer', ActionCategory.logic),
  'cooldown': ActionInfo('Cooldown', ActionCategory.logic),
  'wait': ActionInfo('Attendre', ActionCategory.logic),
  'stop': ActionInfo("Arrêter l'exécution", ActionCategory.logic),
  'skipActions': ActionInfo('Sauter N actions', ActionCategory.logic),
  'jumpToAction': ActionInfo("Aller à l'action", ActionCategory.logic),
  'randomChoice': ActionInfo('Choix aléatoire', ActionCategory.logic),
  // Interactions
  'respondWithMessage': ActionInfo(
    'Répondre avec un message',
    ActionCategory.interactions,
  ),
  'respondWithComponentV2': ActionInfo(
    'Répondre avec un composant V2',
    ActionCategory.interactions,
  ),
  'respondWithModal': ActionInfo(
    'Répondre avec un modal',
    ActionCategory.interactions,
  ),
  'editInteractionMessage': ActionInfo(
    "Modifier le message d'interaction",
    ActionCategory.interactions,
  ),
  'respondWithAutocomplete': ActionInfo(
    "Répondre avec l'autocomplétion",
    ActionCategory.interactions,
  ),
  'deferInteraction': ActionInfo(
    "Différer l'interaction",
    ActionCategory.interactions,
  ),
  'listenForButtonClick': ActionInfo(
    'Écouter un clic bouton',
    ActionCategory.interactions,
  ),
  'listenForSelectMenu': ActionInfo(
    'Écouter un menu de sélection',
    ActionCategory.interactions,
  ),
  'listenForModalSubmit': ActionInfo(
    'Écouter une soumission de modal',
    ActionCategory.interactions,
  ),
  'listenAndExecute': ActionInfo(
    'Écouter et exécuter',
    ActionCategory.interactions,
  ),
  'sendDm': ActionInfo(
    'Envoyer un message privé (MP)',
    ActionCategory.interactions,
  ),
  // Musique
  'playMusic': ActionInfo('Jouer de la musique', ActionCategory.music),
  'pauseMusic': ActionInfo('Mettre en pause la musique', ActionCategory.music),
  'resumeMusic': ActionInfo('Reprendre la musique', ActionCategory.music),
  'skipMusic': ActionInfo('Passer la musique', ActionCategory.music),
  'stopMusic': ActionInfo('Arrêter la musique', ActionCategory.music),
  'setMusicVolume': ActionInfo(
    'Régler le volume de la musique',
    ActionCategory.music,
  ),
  'setMusicLoop': ActionInfo(
    'Régler la lecture en boucle',
    ActionCategory.music,
  ),
  'seekMusic': ActionInfo(
    'Positionner la lecture de musique',
    ActionCategory.music,
  ),
  'getMusicInfo': ActionInfo(
    'Obtenir les infos de la musique',
    ActionCategory.music,
  ),
  'joinVoice': ActionInfo('Rejoindre un salon vocal', ActionCategory.music),
  'leaveVoice': ActionInfo('Quitter le salon vocal', ActionCategory.music),
};

/// Un type inconnu (action récente, sous-action de canvas…) s'affiche tel quel.
ActionInfo infoFor(String type) =>
    actionCatalog[type] ?? ActionInfo(type, ActionCategory.workflows);

/// Types qui terminent une exécution : aucun connecteur après eux en dernier.
const Set<String> finalActionTypes = {
  'respondWithMessage',
  'respondWithComponentV2',
  'respondWithModal',
  'respondWithAutocomplete',
  'deferInteraction',
};

/// Ligne mono sous le titre du bloc (`summarizeActionBlock` de l'app).
String? summarizeAction(Map<String, dynamic> action) {
  final type = '${action['type'] ?? ''}';
  final payload = action['payload'] is Map
      ? Map<String, dynamic>.from(action['payload'] as Map)
      : <String, dynamic>{};
  final key = '${action['key'] ?? ''}'.trim();

  String v(Object? value) =>
      (value ?? '').toString().replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  String cut(String s, int max) =>
      s.length <= max ? s : '${s.substring(0, max)}…';
  Object? first(List<String> keys) {
    for (final k in keys) {
      final value = payload[k];
      if (value != null && v(value).isNotEmpty) return value;
    }
    return null;
  }

  switch (type) {
    case 'httpRequest':
      final url = v(payload['url']);
      if (url.isEmpty) return null;
      final method = v(payload['method']).isEmpty
          ? 'GET'
          : v(payload['method']).toUpperCase();
      final line = '$method ${cut(url, 64)}';
      return key.isEmpty ? line : '$key ← $line';
    case 'setGlobalVariable':
    case 'setScopedVariable':
      final name = v(first(['name', 'key']));
      if (name.isEmpty) return null;
      final value = v(payload['value']);
      return value.isEmpty ? name : '$name ← ${cut(value, 40)}';
    case 'ifBlock':
      final left = v(first(['condition.variable', 'left']));
      if (left.isEmpty) return null;
      final op = v(payload['condition.operator'] ?? payload['operator']);
      final right = v(first(['condition.value', 'right']));
      return cut('$left ${op.isEmpty ? '==' : op} $right'.trim(), 64);
  }

  final text = v(first(['content', 'text', 'message']));
  if (text.isNotEmpty) return cut(text, 64);
  for (final entry in payload.entries) {
    if (entry.key == 'key' || entry.key.startsWith('_')) continue;
    if (entry.value is Map || entry.value is List) continue;
    final value = v(entry.value);
    if (value.isEmpty) continue;
    return cut('${entry.key}: $value', 64);
  }
  return key.isEmpty ? null : key;
}
