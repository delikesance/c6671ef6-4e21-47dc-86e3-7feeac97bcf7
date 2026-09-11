// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get action_add_else_if => 'Ajouter ELSE IF';

  @override
  String get action_add_header => 'Ajouter un en-tête';

  @override
  String get action_add_new_item => 'Ajouter un nouvel élément';

  @override
  String get action_advanced_settings => 'Paramètres avancés';

  @override
  String action_and_more(int count) {
    return '... et $count de plus';
  }

  @override
  String get action_bulk_import_hint =>
      'Import en masse (collez des headers comme Clé: Valeur)';

  @override
  String get action_cannot_format_json =>
      'Impossible de formater : JSON invalide';

  @override
  String get action_category_channels => 'Salons';

  @override
  String get action_category_components => 'Composants';

  @override
  String get action_category_guild_members => 'Serveur & Membres';

  @override
  String get action_category_http_variables => 'HTTP & Variables';

  @override
  String get action_category_interactions => 'Interactions';

  @override
  String get action_category_logic_flow => 'Logique & Flux';

  @override
  String get action_category_messages => 'Messages';

  @override
  String get action_category_moderation => 'Modération';

  @override
  String get action_category_music => 'Musique';

  @override
  String get action_category_reactions => 'Réactions';

  @override
  String get action_category_webhooks => 'Webhooks';

  @override
  String get action_category_workflows => 'Workflows';

  @override
  String action_choose_param(String name) {
    return 'Choisir $name';
  }

  @override
  String get action_clear_all => 'Tout effacer';

  @override
  String get action_condition_value => 'Valeur de condition';

  @override
  String get action_condition_variable => 'Variable de condition';

  @override
  String get action_description_addReaction =>
      'Ajouter un emoji en réaction à un message';

  @override
  String get action_description_addRole => 'Attribuer un rôle à un membre';

  @override
  String get action_description_addThreadMember =>
      'Ajouter un membre à un fil de discussion';

  @override
  String get action_description_appendArrayElement =>
      'Ajouter un nouvel élément dans un tableau JSON global ou à portée';

  @override
  String get action_description_attachImage =>
      'Joindre un fichier image à la réponse (URL, data URL ou base64)';

  @override
  String get action_description_banUser =>
      'Bannir définitivement un utilisateur du serveur';

  @override
  String get action_description_calculate =>
      'Effectuer des opérations mathématiques et stocker le résultat';

  @override
  String get action_description_canvasCreateBlock =>
      'Créer un canevas d\'image vierge';

  @override
  String get action_description_canvasDrawCircleBlock =>
      'Dessiner un cercle sur le canevas d\'image';

  @override
  String get action_description_canvasDrawLineBlock =>
      'Dessiner une ligne sur le canevas';

  @override
  String get action_description_canvasDrawRectBlock =>
      'Dessiner un rectangle sur le canevas d\'image';

  @override
  String get action_description_canvasDrawTextBlock =>
      'Dessiner du texte sur le canevas d\'image avec des options de style';

  @override
  String get action_description_canvasLoadImageBlock =>
      'Charger une image depuis une URL ou une source dans le canevas';

  @override
  String get action_description_clearAllReactions =>
      'Supprimer toutes les réactions d\'un message';

  @override
  String get action_description_cooldown =>
      'Applique un délai d\'attente pour l\'utilisateur ou le serveur';

  @override
  String get action_description_createAutoModRule =>
      'Créer une règle de modération automatique pour le serveur';

  @override
  String get action_description_createChannel => 'Créer un nouveau salon';

  @override
  String get action_description_createEmoji =>
      'Créer un emoji de serveur à partir de données d\'image';

  @override
  String get action_description_createInvite =>
      'Créer un nouveau lien d\'invitation pour un salon';

  @override
  String get action_description_createPoll =>
      'Créer un message de sondage dans un salon';

  @override
  String get action_description_createThread =>
      'Créer un fil de discussion dans un salon textuel pris en charge';

  @override
  String get action_description_debugProfile =>
      'Générer un profil d\'exécution et des informations de diagnostic';

  @override
  String get action_description_deferInteraction =>
      'Différer la réponse à l\'interaction pour éviter l\'expiration Discord';

  @override
  String get action_description_deleteAutoModRule =>
      'Supprimer une règle de modération automatique';

  @override
  String get action_description_deleteChannelPermission =>
      'Supprimer une autorisation spécifique du salon';

  @override
  String get action_description_deleteEmoji => 'Supprimer un emoji de serveur';

  @override
  String get action_description_deleteInvite =>
      'Supprimer une invitation existante par code';

  @override
  String get action_description_deleteMessages =>
      'Supprimer un ou plusieurs messages';

  @override
  String get action_description_deleteTrigger =>
      'Supprime le message qui a déclenché cette commande';

  @override
  String get action_description_deleteWebhook => 'Supprimer un Webhook';

  @override
  String get action_description_disconnectFromVoice =>
      'Déconneter un membre du salon vocal';

  @override
  String get action_description_editChannelPermissions =>
      'Créer ou mettre à jour les autorisations spécifiques du salon';

  @override
  String get action_description_editComponentV2 =>
      'Modifier les composants existants';

  @override
  String get action_description_editInteractionMessage =>
      'Modifier la réponse d\'interaction différée ou d\'origine';

  @override
  String get action_description_editMessage => 'Modifier un message existant';

  @override
  String get action_description_editWebhook => 'Modifier un Webhook existant';

  @override
  String get action_description_endPoll =>
      'Terminer immédiatement un sondage actif';

  @override
  String get action_description_forLoop =>
      'Boucler sur une plage de nombres (boucle for)';

  @override
  String get action_description_getGlobalVariable =>
      'Lire une variable globale et l\'injecter dans les variables d\'exécution';

  @override
  String get action_description_getGuildOnboarding =>
      'Récupérer la configuration actuelle de l\'accueil du serveur';

  @override
  String get action_description_getInvite =>
      'Récupérer les informations de l\'invitation par code';

  @override
  String get action_description_getMember =>
      'Obtenir des informations sur un membre';

  @override
  String get action_description_getMessage =>
      'Récupérer un message et exposer ses champs';

  @override
  String get action_description_getMusicInfo =>
      'Obtenir des informations sur le morceau en cours de lecture';

  @override
  String get action_description_getScopedVariable =>
      'Lire une variable à portée et l\'injecter dans les variables d\'exécution';

  @override
  String get action_description_getWebhook =>
      'Obtenir les informations d\'un Webhook par ID';

  @override
  String get action_description_httpRequest =>
      'Envoyer une requête HTTP avec URL, méthode, en-têtes et corps dynamiques';

  @override
  String get action_description_ifBlock =>
      'Branchement conditionnel : exécuter différentes actions selon une condition';

  @override
  String get action_description_jumpToAction =>
      'Aller à une action spécifique par clé, ID, ou position';

  @override
  String get action_description_joinVoice => 'Se connecter à un salon vocal';

  @override
  String get action_description_jsonForEachLoop =>
      'Boucler sur chaque élément d\'un tableau ou objet JSON (forEach)';

  @override
  String get action_description_kickUser => 'Expulser un membre du serveur';

  @override
  String get action_description_leaveGuild =>
      'Faire quitter le serveur/la guilde au bot';

  @override
  String get action_description_leaveVoice =>
      'Quitter le salon vocal et déconnecter le lecteur';

  @override
  String get action_description_listAutoModRules =>
      'Lister toutes les règles de modération automatique du serveur';

  @override
  String get action_description_listMembers =>
      'Lister les membres d\'un serveur avec des options';

  @override
  String get action_description_listScopedVariableIndex =>
      'Lister les valeurs indexées à portée triées par valeur avec décalage et limite';

  @override
  String get action_description_listWebhooks =>
      'Lister tous les Webhooks d\'un salon ou d\'un serveur';

  @override
  String get action_description_listenAndExecute =>
      'Enregistrer un workflow à exécuter lorsqu\'un bouton est cliqué, un menu de sélection est utilisé ou un modal est soumis';

  @override
  String get action_description_listenForButtonClick =>
      'Enregistrer un workflow à exécuter lorsqu\'un bouton est cliqué';

  @override
  String get action_description_listenForModalSubmit =>
      'Enregistrer un workflow à exécuter lorsqu\'un modal est soumis';

  @override
  String get action_description_listenForSelectMenu =>
      'Enregistrer un workflow à exécuter lorsqu\'un menu de sélection est utilisé';

  @override
  String get action_description_log =>
      'Imprimer ou stocker un message de diagnostic dans les journaux d\'actions';

  @override
  String get action_description_moveToVoiceChannel =>
      'Déplacer un membre vers un salon vocal spécifique';

  @override
  String get action_description_muteUser =>
      'Exclure temporairement (timeout) un membre';

  @override
  String get action_description_pauseMusic =>
      'Mettre en pause la lecture en cours';

  @override
  String get action_description_pinMessage =>
      'Épingler un message dans un salon';

  @override
  String get action_description_playMusic =>
      'Jouer un morceau par recherche ou URL';

  @override
  String get action_description_queryArray =>
      'Filtrer, trier et paginer tout tableau JSON d\'exécution';

  @override
  String get action_description_randomChoice =>
      'Choisit un élément aléatoire dans une liste et le stocke dans une variable';

  @override
  String get action_description_registerGuildCommands =>
      'Enregistrer les commandes d\'application sur un serveur';

  @override
  String get action_description_removeArrayElement =>
      'Supprimer un élément d\'un tableau JSON global ou à portée par index';

  @override
  String get action_description_removeChannel => 'Supprimer un salon';

  @override
  String get action_description_removeGlobalVariable =>
      'Supprimer une variable globale';

  @override
  String get action_description_removeReaction =>
      'Retirer une réaction d\'un message';

  @override
  String get action_description_removeRole => 'Retirer un rôle à un membre';

  @override
  String get action_description_removeScopedVariable =>
      'Supprimer une variable à portée';

  @override
  String get action_description_removeThreadMember =>
      'Supprimer un membre d\'un fil de discussion';

  @override
  String get action_description_renameScopedVariable =>
      'Renommer la clé d\'une variable à portée';

  @override
  String get action_description_respondWithAutocomplete =>
      'Répondre à une interaction d\'autocomplétion Discord avec jusqu\'à 25 choix dynamiques';

  @override
  String get action_description_respondWithComponentV2 =>
      'Répondre à la commande avec des boutons/menus de sélection';

  @override
  String get action_description_respondWithMessage =>
      'Répondre à la commande avec un message normal';

  @override
  String get action_description_respondWithModal =>
      'Afficher une boîte de dialogue modale à l\'utilisateur';

  @override
  String get action_description_resumeMusic =>
      'Reprendre la lecture d\'un morceau en pause';

  @override
  String get action_description_runBdfdScript =>
      'Compiler et exécuter un script BDFD en ligne comme actions de workflow';

  @override
  String get action_description_runWorkflow =>
      'Exécuter un workflow enregistré (prend en charge le point d\'entrée + arguments)';

  @override
  String get action_description_runtimeImageBlock =>
      'Exécuter un bloc d\'actions de traitement de canevas d\'image';

  @override
  String get action_description_runtimeJsonBlock =>
      'Exécuter un bloc d\'actions de traitement JSON';

  @override
  String get action_description_seekMusic =>
      'Positionner la lecture à un moment précis';

  @override
  String get action_description_sendComponentV2 =>
      'Envoyer des composants interactifs';

  @override
  String get action_description_sendDm =>
      'Envoie un message privé à un utilisateur spécifique';

  @override
  String get action_description_sendMessage =>
      'Envoyer un message dans un salon spécifique';

  @override
  String get action_description_sendWebhook => 'Envoyer un message via Webhook';

  @override
  String get action_description_serverDeafenMember =>
      'Assourdir ou rétablir l\'ouïe d\'un membre sur le serveur';

  @override
  String get action_description_serverMuteMember =>
      'Rendre muet ou rétablir le son d\'un membre sur le serveur';

  @override
  String get action_description_setGlobalVariable =>
      'Créer ou mettre à jour une variable globale pour ce bot';

  @override
  String get action_description_setMusicLoop =>
      'Activer ou désactiver la lecture en boucle de la file';

  @override
  String get action_description_setMusicVolume =>
      'Régler le volume du lecteur (0 à 200)';

  @override
  String get action_description_setNickname =>
      'Change le surnom d\'un membre du serveur';

  @override
  String get action_description_setScopedVariable =>
      'Créer ou mettre à jour une variable à portée (serveur/utilisateur/salon/membre/message)';

  @override
  String get action_description_setTemporaryVariable =>
      'Créer ou mettre à jour une variable temporaire dans l\'exécution locale';

  @override
  String get action_description_skipActions =>
      'Sauter un nombre spécifié d\'actions suivantes';

  @override
  String get action_description_skipMusic =>
      'Passer au morceau suivant dans la file';

  @override
  String get action_description_slowmode =>
      'Définit la durée du mode lent pour un salon';

  @override
  String get action_description_stop =>
      'Arrête immédiatement l\'exécution du workflow actuel';

  @override
  String get action_description_stopMusic =>
      'Arrêter la lecture et vider la file';

  @override
  String get action_description_stopUnless =>
      'Arrêter le workflow si une condition n\'est pas remplie (garde/filtre)';

  @override
  String get action_description_unbanUser =>
      'Révoquer le bannissement d\'un utilisateur';

  @override
  String get action_description_unmuteUser =>
      'Retirer l\'exclusion temporaire d\'un membre';

  @override
  String get action_description_unpinMessage =>
      'Désépingler un message dans un salon';

  @override
  String get action_description_unregisterGuildCommands =>
      'Désenregistrer les commandes d\'application d\'un serveur';

  @override
  String get action_description_updateAutoMod =>
      'Mettre à jour les paramètres de modération automatique';

  @override
  String get action_description_updateChannel =>
      'Mettre à jour les paramètres du salon';

  @override
  String get action_description_updateEmoji =>
      'Mettre à jour le nom de l\'emoji ou l\'accès aux rôles du serveur';

  @override
  String get action_description_updateGuild =>
      'Mettre à jour les paramètres du serveur';

  @override
  String get action_description_updateGuildOnboarding =>
      'Mettre à jour la configuration de l\'accueil du serveur';

  @override
  String get action_description_updateSelfUser =>
      'Mettre à jour le profil du bot (nom d\'utilisateur/avatar)';

  @override
  String get action_description_wait =>
      'Met en pause l\'exécution pour une durée précise';

  @override
  String get action_dynamic => 'Dynamique';

  @override
  String get action_dynamic_bool_hint => 'true/false ou ((variable))';

  @override
  String action_dynamic_id_hint(String type) {
    return '$type dynamique (supporte ((...)))';
  }

  @override
  String get action_dynamic_multiselect_hint =>
      'Valeur dynamique (supporte ((...)))';

  @override
  String get action_dynamic_numeric => 'Suggestions numériques dynamiques';

  @override
  String get action_dynamic_variable => 'Suggestions de variables dynamiques';

  @override
  String action_edit_nested(int count) {
    return 'Modifier $count';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Modifier ($count)';
  }

  @override
  String action_edit_param(String name) {
    return 'Modifier $name';
  }

  @override
  String get action_edit_raw_json => 'Modifier le JSON brut';

  @override
  String action_else_if_label(int index) {
    return 'SINON SI $index — actions';
  }

  @override
  String get action_error_continue => 'Continuer';

  @override
  String get action_error_stop => 'Arrêter';

  @override
  String get action_expression => 'Expression';

  @override
  String get action_format_json => 'Formater le JSON';

  @override
  String get action_hint_color => '#FFFFFF ou rgb(255,255,255)';

  @override
  String get action_hint_condition_value => 'Valeur de comparaison';

  @override
  String get action_hint_condition_var =>
      'Utiliser ((variableName)) ou une valeur d\'exécution';

  @override
  String get action_hint_cooldown_error =>
      'Message à envoyer si en cooldown (supporte %time%)';

  @override
  String get action_hint_cooldown_time => 'Durée (ex: 10s, 5m)';

  @override
  String get action_hint_duration => 'ex. 5m, 1h, 30s';

  @override
  String get action_hint_emoji => 'Émoji (ex. 🪜) ou <:nom:id>';

  @override
  String action_hint_enter_type(String type) {
    return 'Saisir $type';
  }

  @override
  String get action_hint_random_choices => 'Liste de choix (séparés par ;)';

  @override
  String get action_hint_random_var =>
      'Nom de la variable pour stocker le résultat';

  @override
  String get action_hint_variable_key => 'Sélectionner une clé de variable';

  @override
  String get action_hint_workflow => 'Nom du workflow enregistré';

  @override
  String get action_http_headers_title => 'Headers HTTP (paires clé/valeur)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count chemins analysés';
  }

  @override
  String get action_http_response_body => 'Corps de la réponse (brut) :';

  @override
  String action_http_status(int status) {
    return 'Statut : $status';
  }

  @override
  String get action_http_test_button =>
      'Envoyer une requête test et détecter les routes';

  @override
  String get action_http_test_title => 'Résultats de la requête test';

  @override
  String get action_json_editor_hint =>
      'Éditeur d\'objet JSON (supporte les objets/tableaux imbriqués)';

  @override
  String get action_key_field => 'Clé d\'action';

  @override
  String get action_key_value_pairs => 'Paires clé / valeur';

  @override
  String get action_literal => 'Littéral';

  @override
  String get action_loading_keys => 'Chargement des clés...';

  @override
  String get action_manage_variable_keys => 'Gérer les clés de variables';

  @override
  String get action_name_addReaction => 'Ajouter une réaction';

  @override
  String get action_name_addRole => 'Ajouter un rôle';

  @override
  String get action_name_addThreadMember => 'Ajouter un membre au fil';

  @override
  String get action_name_appendArrayElement =>
      'Ajouter un élément à un tableau';

  @override
  String get action_name_attachImage => 'Joindre une image';

  @override
  String get action_name_banUser => 'Bannir un utilisateur';

  @override
  String get action_name_calculate => 'Calculer';

  @override
  String get action_name_canvasCreateBlock => 'Créer un canevas';

  @override
  String get action_name_canvasDrawCircleBlock => 'Dessiner un cercle';

  @override
  String get action_name_canvasDrawLineBlock => 'Dessiner une ligne';

  @override
  String get action_name_canvasDrawRectBlock => 'Dessiner un rectangle';

  @override
  String get action_name_canvasDrawTextBlock => 'Dessiner du texte';

  @override
  String get action_name_canvasLoadImageBlock => 'Charger une image';

  @override
  String get action_name_clearAllReactions => 'Retirer toutes les réactions';

  @override
  String get action_name_cooldown => 'Cooldown';

  @override
  String get action_name_createAutoModRule => 'Créer une règle AutoMod';

  @override
  String get action_name_createChannel => 'Créer un salon';

  @override
  String get action_name_createEmoji => 'Créer un emoji';

  @override
  String get action_name_createInvite => 'Créer une invitation';

  @override
  String get action_name_createPoll => 'Créer un sondage';

  @override
  String get action_name_createThread => 'Créer un fil';

  @override
  String get action_name_debugProfile => 'Profil de débogage';

  @override
  String get action_name_deferInteraction => 'Différer l\'interaction';

  @override
  String get action_name_deleteAutoModRule => 'Supprimer une règle AutoMod';

  @override
  String get action_name_deleteChannelPermission =>
      'Supprimer une permission du salon';

  @override
  String get action_name_deleteEmoji => 'Supprimer l\'émoji';

  @override
  String get action_name_deleteInvite => 'Supprimer une invitation';

  @override
  String get action_name_deleteMessages => 'Supprimer des messages';

  @override
  String get action_name_deleteTrigger => 'Supprimer le message déclencheur';

  @override
  String get action_name_deleteWebhook => 'Supprimer un webhook';

  @override
  String get action_name_disconnectFromVoice => 'Déconnecter du vocal';

  @override
  String get action_name_editChannelPermissions =>
      'Modifier les permissions du salon';

  @override
  String get action_name_editComponentV2 => 'Modifier un composant V2';

  @override
  String get action_name_editInteractionMessage =>
      'Modifier le message d\'interaction';

  @override
  String get action_name_editMessage => 'Modifier un message';

  @override
  String get action_name_editWebhook => 'Modifier un webhook';

  @override
  String get action_name_endPoll => 'Clôturer un sondage';

  @override
  String get action_name_forLoop => 'Boucle Pour';

  @override
  String get action_name_getGlobalVariable => 'Lire une variable globale';

  @override
  String get action_name_getGuildOnboarding =>
      'Récupérer l\'onboarding serveur';

  @override
  String get action_name_getInvite => 'Récupérer une invitation';

  @override
  String get action_name_getMember => 'Récupérer un membre';

  @override
  String get action_name_getMessage => 'Récupérer un message';

  @override
  String get action_name_getMusicInfo => 'Obtenir les infos de la musique';

  @override
  String get action_name_getScopedVariable => 'Lire une variable scopée';

  @override
  String get action_name_getWebhook => 'Récupérer un webhook';

  @override
  String get action_name_httpRequest => 'Requête HTTP';

  @override
  String get action_name_ifBlock => 'Bloc SI / SINON';

  @override
  String get action_name_jumpToAction => 'Aller à l\'action';

  @override
  String get action_name_joinVoice => 'Rejoindre un salon vocal';

  @override
  String get action_name_jsonForEachLoop => 'Boucle Pour Chaque JSON';

  @override
  String get action_name_kickUser => 'Expulser un utilisateur';

  @override
  String get action_name_leaveGuild => 'Faire quitter le serveur';

  @override
  String get action_name_leaveVoice => 'Quitter le salon vocal';

  @override
  String get action_name_listAutoModRules => 'Lister les règles AutoMod';

  @override
  String get action_name_listMembers => 'Lister les membres';

  @override
  String get action_name_listScopedVariableIndex =>
      'Lister un index de variable scopée';

  @override
  String get action_name_listWebhooks => 'Lister les webhooks';

  @override
  String get action_name_listenAndExecute => 'Écouter et exécuter';

  @override
  String get action_name_listenForButtonClick => 'Écouter un clic bouton';

  @override
  String get action_name_listenForModalSubmit =>
      'Écouter une soumission de modal';

  @override
  String get action_name_listenForSelectMenu => 'Écouter un menu de sélection';

  @override
  String get action_name_log => 'Log';

  @override
  String get action_name_moveToVoiceChannel => 'Déplacer vers un vocal';

  @override
  String get action_name_muteUser => 'Rendre muet un utilisateur';

  @override
  String get action_name_pauseMusic => 'Mettre en pause la musique';

  @override
  String get action_name_pinMessage => 'Épingler un message';

  @override
  String get action_name_playMusic => 'Jouer de la musique';

  @override
  String get action_name_queryArray => 'Interroger un tableau';

  @override
  String get action_name_randomChoice => 'Choix aléatoire';

  @override
  String get action_name_registerGuildCommands => 'Enregistrer les commandes';

  @override
  String get action_name_removeArrayElement => 'Retirer un élément de tableau';

  @override
  String get action_name_removeChannel => 'Supprimer un salon';

  @override
  String get action_name_removeGlobalVariable =>
      'Supprimer une variable globale';

  @override
  String get action_name_removeReaction => 'Retirer une réaction';

  @override
  String get action_name_removeRole => 'Retirer un rôle';

  @override
  String get action_name_removeScopedVariable =>
      'Supprimer une variable scopée';

  @override
  String get action_name_removeThreadMember => 'Retirer un membre du fil';

  @override
  String get action_name_renameScopedVariable => 'Renommer une variable scopée';

  @override
  String get action_name_respondWithAutocomplete =>
      'Répondre avec l\'autocomplétion';

  @override
  String get action_name_respondWithComponentV2 =>
      'Répondre avec un composant V2';

  @override
  String get action_name_respondWithMessage => 'Répondre avec un message';

  @override
  String get action_name_respondWithModal => 'Répondre avec un modal';

  @override
  String get action_name_resumeMusic => 'Reprendre la musique';

  @override
  String get action_name_runBdfdScript => 'Exécuter un script BDFD';

  @override
  String get action_name_runWorkflow => 'Exécuter un workflow';

  @override
  String get action_name_runtimeImageBlock => 'Bloc Image d\'exécution';

  @override
  String get action_name_runtimeJsonBlock => 'Bloc JSON d\'exécution';

  @override
  String get action_name_seekMusic => 'Positionner la lecture de musique';

  @override
  String get action_name_sendComponentV2 => 'Envoyer un composant V2';

  @override
  String get action_name_sendDm => 'Envoyer un message privé (MP)';

  @override
  String get action_name_sendMessage => 'Envoyer un message';

  @override
  String get action_name_sendWebhook => 'Envoyer un Webhook';

  @override
  String get action_name_serverDeafenMember => 'Assourdir côté serveur';

  @override
  String get action_name_serverMuteMember => 'Rendre muet côté serveur';

  @override
  String get action_name_setGlobalVariable => 'Définir une variable globale';

  @override
  String get action_name_setMusicLoop => 'Régler la lecture en boucle';

  @override
  String get action_name_setMusicVolume => 'Régler le volume de la musique';

  @override
  String get action_name_setNickname => 'Changer le surnom';

  @override
  String get action_name_setScopedVariable => 'Définir une variable scopée';

  @override
  String get action_name_setTemporaryVariable =>
      'Définir une variable temporaire';

  @override
  String get action_name_skipActions => 'Sauter N actions';

  @override
  String get action_name_skipMusic => 'Passer la musique';

  @override
  String get action_name_slowmode => 'Mode lent';

  @override
  String get action_name_stop => 'Arrêter l\'exécution';

  @override
  String get action_name_stopMusic => 'Arrêter la musique';

  @override
  String get action_name_stopUnless => 'Arrêter sauf si condition';

  @override
  String get action_name_unbanUser => 'Débannir un utilisateur';

  @override
  String get action_name_unmuteUser => 'Réactiver la parole d\'un utilisateur';

  @override
  String get action_name_unpinMessage => 'Désépingler un message';

  @override
  String get action_name_unregisterGuildCommands =>
      'Désenregistrer les commandes';

  @override
  String get action_name_updateAutoMod => 'Mettre à jour AutoMod';

  @override
  String get action_name_updateChannel => 'Modifier un salon';

  @override
  String get action_name_updateEmoji => 'Modifier un emoji';

  @override
  String get action_name_updateGuild => 'Mettre à jour le serveur';

  @override
  String get action_name_updateGuildOnboarding =>
      'Modifier l\'onboarding serveur';

  @override
  String get action_name_updateSelfUser => 'Modifier le profil du bot';

  @override
  String get action_name_wait => 'Attendre';

  @override
  String get action_no_actions_yet => 'Aucune action dans cette branche.';

  @override
  String get action_no_args_tap_edit =>
      'Aucun argument - appuyez sur modifier pour ajouter';

  @override
  String get action_no_else_if_yet =>
      'Aucune branche ELSE IF. Ajoutez-en une pour tester plus de conditions avant le ELSE.';

  @override
  String get action_no_headers_tap_edit =>
      'Aucun header - appuyez sur modifier pour ajouter';

  @override
  String get action_no_items_tap_edit =>
      'Aucun élément - appuyez sur modifier pour ajouter';

  @override
  String get action_no_properties_tap_edit =>
      'Aucune propriété - appuyez sur configurer';

  @override
  String get action_no_saved_keys =>
      'Aucune clé trouvée. Les clés sont créées automatiquement au premier accès.';

  @override
  String get action_on_error => 'En cas d\'erreur';

  @override
  String get action_options_tooltip => 'Options de l\'action';

  @override
  String get action_or_type_workflow => 'Ou saisir le nom du workflow';

  @override
  String get action_order_tip =>
      'Astuce : utilisez les flèches pour changer l\'ordre des actions.';

  @override
  String action_position(int index, int total) {
    return 'Action $index/$total';
  }

  @override
  String get action_preview_json => 'Aperçu JSON mis en forme';

  @override
  String get action_provide_valid_url => 'Veuillez fournir une URL valide.';

  @override
  String get action_refresh_keys => 'Actualiser les clés';

  @override
  String get action_remove_confirm =>
      'Cette action sera supprimée du workflow. Continuer ?';

  @override
  String get action_remove_else_if => 'Supprimer ELSE IF';

  @override
  String get action_remove_menu => 'Supprimer l\'action';

  @override
  String get action_remove_title => 'Supprimer l\'action';

  @override
  String get action_root_must_json => 'La racine doit être un objet JSON';

  @override
  String get action_select_saved_key => 'Sélectionner une clé enregistrée';

  @override
  String get action_select_stored_key =>
      'Sélectionner une clé enregistrée (préfixe bc_ optionnel)';

  @override
  String get action_static_badge => '(statique)';

  @override
  String get action_status_disabled => 'Désactivé';

  @override
  String get action_status_enabled => 'Activé';

  @override
  String get action_store_results =>
      'Stocker les résultats dans les variables globales';

  @override
  String actions_active_route(String label) {
    return 'Route active : $label';
  }

  @override
  String get actions_add_label => 'Ajouter une action';

  @override
  String get actions_add_new_title => 'Ajouter une nouvelle action';

  @override
  String actions_build_button(int count) {
    return 'Construire les actions ($count)';
  }

  @override
  String get actions_empty_subtitle =>
      'Ajoutez une action, puis ouvrez-la pour configurer les détails.';

  @override
  String get actions_empty_title => 'Aucune action';

  @override
  String get actions_builder_title => 'Constructeur d\'actions';

  @override
  String get actions_description =>
      'Construire les actions d\'exécution pour cette commande';

  @override
  String get actions_global_variables => 'Variables globales';

  @override
  String actions_key_label(String key) {
    return 'Clé : $key';
  }

  @override
  String actions_missing_field_content(String action, String field) {
    return '\"$action\" : \"$field\" est requis.';
  }

  @override
  String get actions_missing_field_title => 'Champ requis manquant';

  @override
  String get actions_no_matches =>
      'Aucune action ne correspond à votre recherche.';

  @override
  String actions_save_count(int count) {
    return 'Enregistrer $count actions';
  }

  @override
  String get actions_save_tooltip => 'Enregistrer les actions';

  @override
  String get actions_save_workflow_title => 'Enregistrer comme workflow';

  @override
  String get actions_search_hint => 'Rechercher des actions...';

  @override
  String get actions_search_sequence_hint =>
      'Rechercher des actions dans cette séquence...';

  @override
  String actions_sequence_count(int count) {
    return '$count action(s) dans la séquence';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Étape $index/$total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'Script BDFD | $lines ligne(s) | $diagnostics diagnostic(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count action(s) configurée(s)';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Script Dart | $lines ligne(s) | $diagnostics diagnostic(s)';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count action(s) sur la route active | $routes route(s)';
  }

  @override
  String get actions_title => 'Actions';

  @override
  String get actions_workflow_name_label => 'Nom du workflow';

  @override
  String get actions_workflows => 'Workflows';

  @override
  String get ads_consent_accept => 'J\'accepte';

  @override
  String get ads_consent_message =>
      'Pour respecter le RGPD, nous avons besoin de votre consentement avant d\'afficher des publicités. Vous pouvez continuer à utiliser l\'application même en refusant.';

  @override
  String get ads_consent_refuse => 'Je refuse';

  @override
  String get ads_consent_refused_info =>
      'Consentement pub refusé. Le bot démarre normalement.';

  @override
  String get ads_consent_title => 'Consentement publicitaire';

  @override
  String get app_bot_token => 'Token du bot';

  @override
  String get app_create_button => 'Créer une application';

  @override
  String get app_create_hero_desc =>
      'Un parcours guidé pour ouvrir les bonnes pages, copier votre token et importer le bot proprement.';

  @override
  String get app_create_hero_title => 'Connectez votre bot Discord';

  @override
  String get app_create_new => 'Créer une nouvelle application';

  @override
  String get app_create_page_title => 'Créer une application';

  @override
  String get app_enter_token => 'Entrez votre token du bot ici';

  @override
  String get app_external_link_badge => 'Lien externe';

  @override
  String get app_hide_token => 'Masquer le token';

  @override
  String get app_how_to_create_token => 'Comment créer un token de bot ?';

  @override
  String get app_loading_error => 'Erreur de chargement';

  @override
  String get app_no_apps => 'Vous n\'avez pas encore d\'applications.';

  @override
  String get app_note =>
      'Remarque: Vous devez créer une nouvelle application sur Discord Developer Portal et obtenir le token du bot.';

  @override
  String get app_open_discord_portal => 'Ouvrir Discord Developer Portal';

  @override
  String get app_open_discord_portal_desc =>
      'Créez votre application et activez la section bot.';

  @override
  String get app_open_link_error => 'Impossible d\'ouvrir cette page externe.';

  @override
  String get app_open_token_tutorial => 'Lire le tutoriel du token';

  @override
  String get app_open_token_tutorial_desc =>
      'Un guide pas à pas pour générer et copier votre token de bot.';

  @override
  String get app_resources_desc =>
      'Ces actions ouvrent les pages officielles nécessaires avant d\'enregistrer votre bot ici.';

  @override
  String get app_resources_title => 'Parcours guidé';

  @override
  String get app_save => 'Enregistrer les modifications';

  @override
  String get app_save_bot => 'Ajouter le bot';

  @override
  String get app_show_token => 'Afficher le token';

  @override
  String get app_sync_manager_connect => 'Connecter Discord';

  @override
  String get app_sync_manager_desc =>
      'Ce bot est déjà enregistré sur Bot Creator Manager. Connectez-vous avec Discord pour synchroniser tous vos bots automatiquement ?';

  @override
  String get app_sync_manager_manual => 'Garder local';

  @override
  String get app_sync_manager_title => 'Bot déjà géré';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      'Le token semble avoir été réinitialisé. Veuillez fournir le nouveau token depuis le Discord Developer Portal.';

  @override
  String get app_token_invalid_title => 'Réinitialisation du token détectée';

  @override
  String get app_token_field_helper =>
      'Collez le token exactement tel que fourni par Discord.';

  @override
  String get app_token_section_desc =>
      'Une fois le token copié, collez-le ci-dessous pour ajouter votre bot à l\'application.';

  @override
  String get app_token_section_title => 'Collez votre token de bot';

  @override
  String get app_token_security_hint =>
      'Gardez ce token privé. Toute personne qui le possède peut contrôler votre bot.';

  @override
  String get autocomplete_dynamic => 'Autocomplétion dynamique';

  @override
  String get autocomplete_dynamic_desc =>
      'Résoudre les choix depuis un workflow au lieu de valeurs statiques.';

  @override
  String get autocomplete_filter_hint =>
      'Les suggestions sont filtrées selon ce que l\'utilisateur tape.';

  @override
  String get autocomplete_loading => 'Chargement des workflows...';

  @override
  String get autocomplete_no_workflows => 'Aucun workflow sauvegardé trouvé';

  @override
  String get autocomplete_select_workflow =>
      'Sélectionnez un workflow sauvegardé';

  @override
  String get autocomplete_type_name => 'Ou tapez le nom du workflow';

  @override
  String get autocomplete_workflow_label => 'Workflow d\'autocomplétion';

  @override
  String backup_completed(String id) {
    return 'Sauvegarde terminée : $id';
  }

  @override
  String backup_failed(String error) {
    return 'Sauvegarde échouée : $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Ce script BDFD n\'a pas pu être compilé :\n$summary';
  }

  @override
  String get bdfd_compile_error_simple =>
      'Ce script BDFD n\'a pas pu être compilé.';

  @override
  String get bdfd_compiled_no_actions =>
      'Ce script BDFD a été compilé avec succès mais n\'a produit aucune action.';

  @override
  String get bdfd_editor_auto_indent =>
      '€¢ Indentation automatique intelligente sur Entrée';

  @override
  String get bdfd_editor_diagnostics_toggle =>
      'Afficher/masquer le panneau de diagnostics';

  @override
  String get bdfd_editor_docs => 'Documentation';

  @override
  String get bdfd_editor_empty =>
      'Script vide — commencez à écrire pour voir les diagnostics.';

  @override
  String get bdfd_editor_includes => 'Inclut :';

  @override
  String get bdfd_editor_indent_guides =>
      '€¢ Guides d\'indentation en temps réel';

  @override
  String get bdfd_editor_quick_keys =>
      '€¢ Touches rapides mobiles pour les symboles BDFD';

  @override
  String get bdfd_editor_tap_hint => 'Appuyez pour ouvrir l\'éditeur';

  @override
  String get bdfd_editor_title => 'Éditeur BDFD';

  @override
  String get bdfd_editor_toggle_indent =>
      'Activer/désactiver les guides d\'indentation';

  @override
  String get bdfd_editor_ux_title => 'UX de l\'éditeur';

  @override
  String get bdfd_editor_wrap_toggle =>
      'Activer/désactiver le retour à la ligne';

  @override
  String get bdfd_runtime_execution_error =>
      'Une erreur est survenue lors de l\'exécution de ce script BDFD.';

  @override
  String get bot_home_create_command => 'Créer ma première commande';

  @override
  String get bot_home_customize => 'Personnaliser mon bot';

  @override
  String get bot_home_delete => 'Supprimer l\'application';

  @override
  String get bot_home_delete_confirm =>
      'Êtes-vous sûr de vouloir supprimer cette application ?';

  @override
  String get bot_home_invite => 'Inviter le bot';

  @override
  String get bot_home_invite_error =>
      'Impossible d\'ouvrir le lien d\'invitation';

  @override
  String get bot_home_ios_notice_content =>
      'En mode local, iOS peut suspendre l\'application en arrière-plan. Le bot peut démarrer, mais le maintien de la connexion Discord n\'est pas garanti comme avec un Runner.';

  @override
  String get bot_home_ios_notice_title => 'Contrainte iOS locale';

  @override
  String get bot_home_log_desktop_stop => 'Arrêt du bot desktop demandé';

  @override
  String get bot_home_log_start => 'Démarrage du bot demandé';

  @override
  String get bot_home_log_stop => 'Arrêt du bot demandé';

  @override
  String get bot_home_notif_required =>
      'La permission de notification est requise pour lancer le service du bot.';

  @override
  String get bot_home_section_danger => 'ZONE DE DANGER';

  @override
  String get bot_home_section_getting_started => 'PREMIERS PAS';

  @override
  String get bot_home_section_monitoring => 'SURVEILLANCE';

  @override
  String get bot_home_section_tools => 'OUTILS';

  @override
  String get bot_home_service_not_started =>
      'Le service foreground n\'a pas démarré.';

  @override
  String get bot_home_start => 'Lancer le bot';

  @override
  String bot_home_start_error(String error) {
    return 'Impossible de démarrer : $error';
  }

  @override
  String get bot_home_starting => 'Démarrage...';

  @override
  String get bot_home_stop => 'Arrêter le bot';

  @override
  String get bot_home_sync => 'Synchroniser l\'app';

  @override
  String get bot_home_sync_success => 'Application synchronisée avec succès';

  @override
  String get bot_home_pull => 'Télécharger du Cloud';

  @override
  String get bot_home_push => 'Envoyer vers le Cloud';

  @override
  String get bot_home_pull_success =>
      'Application téléchargée du cloud avec succès';

  @override
  String get bot_home_push_success =>
      'Application envoyée vers le cloud avec succès';

  @override
  String get bot_home_version_history => 'Historique des versions';

  @override
  String get bot_config_versions_title => 'Historique des versions';

  @override
  String get bot_config_versions_empty => 'Aucune version précédente trouvée';

  @override
  String get bot_config_versions_restore => 'Restaurer';

  @override
  String get bot_config_versions_restore_confirm =>
      'Restaurer cette version ? Votre configuration actuelle sera sauvegardée d\'abord.';

  @override
  String get bot_config_versions_restored =>
      'Configuration restaurée localement et dans le cloud.';

  @override
  String get bot_config_versions_error => 'Échec du chargement des versions';

  @override
  String get bot_config_versions_restore_error =>
      'Échec de la restauration de la version';

  @override
  String get bot_home_pull_dialog_changes => 'Changements à appliquer :';

  @override
  String get bot_home_pull_dialog_local => 'Local (Appareil)';

  @override
  String get bot_home_pull_dialog_local_only =>
      'locale(s) uniquement (conservée(s))';

  @override
  String get bot_home_pull_dialog_local_preserved =>
      'commande(s) locale(s) absente(s) du cloud seront conservée(s).';

  @override
  String get bot_home_pull_dialog_new_commands => 'nouvelle(s) commande(s)';

  @override
  String get bot_home_pull_dialog_remote => 'Distant (Cloud)';

  @override
  String get bot_home_pull_dialog_unchanged => 'inchangée(s)';

  @override
  String get bot_home_pull_dialog_up_to_date =>
      'Déjà à jour — aucun changement nécessaire.';

  @override
  String get bot_home_pull_dialog_updated_commands =>
      'commande(s) mise(s) à jour';

  @override
  String get bot_home_push_refused_empty =>
      'Push refusé : la configuration locale est vide ou corrompue. Vérifiez vos commandes.';

  @override
  String get bot_home_token_invalid_content =>
      'Le token semble avoir été réinitialisé. Veuillez fournir le nouveau token depuis le Discord Developer Portal. Voulez-vous quand même lancer le bot ?';

  @override
  String get bot_home_token_invalid_title =>
      'Le token semble avoir été réinitialisé';

  @override
  String get bot_home_view_logs => 'Voir les logs du bot';

  @override
  String get bot_home_view_replay => 'Voir les replays du débogueur';

  @override
  String get bot_home_view_stats => 'Voir les stats du bot';

  @override
  String get bot_logs_copied => 'Logs copiés';

  @override
  String get bot_logs_disable_debug => 'Désactiver les logs debug';

  @override
  String get bot_logs_empty => 'Aucun log pour le moment';

  @override
  String get bot_logs_enable_debug => 'Activer les logs debug';

  @override
  String get bot_logs_filter_count => 'Nombre de logs affichés';

  @override
  String get bot_logs_go_to_bottom => 'Aller en bas';

  @override
  String get bot_logs_go_to_latest => 'Aller au dernier log';

  @override
  String get bot_logs_newest_first => 'Afficher les plus récents en premier';

  @override
  String get bot_logs_oldest_first => 'Afficher les plus anciens en premier';

  @override
  String bot_logs_ram(String memory) {
    return 'RAM du processus bot : $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'RAM bot estimée : $memory';
  }

  @override
  String get bot_logs_raw_mode => 'Logs bruts compacts';

  @override
  String get bot_logs_rich_mode => 'Logs formatés';

  @override
  String get bot_logs_show_all => 'Afficher tout';

  @override
  String get bot_logs_show_less => 'Afficher moins';

  @override
  String get bot_logs_show_more => 'Afficher plus';

  @override
  String bot_logs_show_n(int count) {
    return 'Afficher $count logs';
  }

  @override
  String get bot_logs_title => 'Logs du bot';

  @override
  String get bot_offline_token_desc =>
      'Token invalide ou manquant. Entrez un nouveau token Discord pour retablir la connexion.';

  @override
  String get bot_settings_activity_state_label =>
      'État de l\'activité (optionnel)';

  @override
  String get bot_settings_activity_url_label =>
      'URL de stream (pour streaming)';

  @override
  String get bot_settings_add_status => 'Ajouter une activité';

  @override
  String get bot_settings_app_flags => 'Indicateurs de l\'application';

  @override
  String get bot_settings_avatar_clear_selection => 'Effacer la selection';

  @override
  String get bot_settings_avatar_important_note =>
      'Important : Les changements de profil (nom et photo) ne seront appliqués sur Discord que lorsque vous cliquerez sur le bouton \'Sauvegarder le profil et les statuts\' tout en bas.';

  @override
  String get bot_settings_avatar_local_path => 'Chemin local de l\'avatar';

  @override
  String get bot_settings_avatar_none_selected =>
      'Aucune nouvelle image sélectionnée. Cliquez sur Parcourir pour en choisir une.';

  @override
  String get bot_settings_avatar_path_hint => '/chemin/absolu/vers/avatar.png';

  @override
  String get bot_settings_avatar_preview_error =>
      'Impossible d\'afficher l\'aperçu de l\'image';

  @override
  String get bot_settings_avatar_preview_label => 'Apercu de l\'avatar';

  @override
  String get bot_settings_avatar_selected => 'Nouvelle image sélectionnée :';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Fichier selectionne : $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Format d\'avatar non supporte : $ext. Formats supportes : $formats.';
  }

  @override
  String get bot_settings_browse => 'Parcourir';

  @override
  String get bot_settings_cancel_token_edit_btn =>
      'Annuler la modification du token';

  @override
  String get bot_settings_danger_zone => 'Zone de danger';

  @override
  String get bot_settings_delete_bot => 'Supprimer le bot';

  @override
  String get bot_settings_delete_bot_btn => 'Supprimer définitivement';

  @override
  String get bot_settings_delete_bot_desc =>
      'Cette action est irréversible. Toutes les données locales et les configurations distantes seront supprimées.';

  @override
  String bot_settings_delete_desc(String id) {
    return 'Voulez-vous vraiment supprimer le bot $id ? Toutes les données seront perdues.';
  }

  @override
  String get bot_settings_delete_title => 'Confirmer la suppression';

  @override
  String get bot_settings_edit_token_btn => 'Modifier le token';

  @override
  String get bot_settings_export_import => 'Export / Import';

  @override
  String get bot_settings_export_import_desc =>
      'Exportez ou importez la configuration de votre bot sous forme de fichier ZIP.';

  @override
  String get bot_settings_gateway_intents =>
      'Configuration des Gateway Intents';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Sélectionnez les intents dont votre bot a besoin. Configurez-les sur le Discord Developer Portal.';

  @override
  String get bot_settings_intents_saved => 'Intents sauvegardes avec succes';

  @override
  String get bot_settings_intents_auto_enabled =>
      'Les intents privilegies ont ete actives automatiquement dans le Developer Portal.';

  @override
  String get bot_settings_intents_verified_bot_manual =>
      'Ce bot verifie necessite l\'activation manuelle des intents privilegies dans le Discord Developer Portal.';

  @override
  String get bot_settings_intents_auto_enable_failed =>
      'Token sauvegarde, mais les intents privilegies n\'ont pas pu etre actives automatiquement. Activez-les dans le Discord Developer Portal.';

  @override
  String get bot_settings_lavalink_choose_server =>
      'Choisir un serveur public...';

  @override
  String get bot_settings_lavalink_host => 'Hôte';

  @override
  String get bot_settings_lavalink_host_hint =>
      'localhost ou IP du serveur Lavalink';

  @override
  String get bot_settings_lavalink_password => 'Mot de passe';

  @override
  String get bot_settings_lavalink_password_hint => 'youshallnotpass';

  @override
  String get bot_settings_lavalink_port => 'Port';

  @override
  String get bot_settings_lavalink_port_hint => '2333';

  @override
  String get bot_settings_lavalink_premium_banner_desc =>
      'Débloquez le support audio Lavalink pour votre bot.';

  @override
  String get bot_settings_lavalink_premium_banner_title =>
      '🔒 Disponible avec Bot Creator PREMIUM';

  @override
  String get bot_settings_lavalink_public_servers => 'Serveurs publics';

  @override
  String get bot_settings_lavalink_save_btn => 'Enregistrer';

  @override
  String get bot_settings_lavalink_save_caption =>
      'Enregistrez cette configuration pour que le bot puisse se connecter au serveur Lavalink.';

  @override
  String get bot_settings_lavalink_section_title => 'Serveur Lavalink';

  @override
  String get bot_settings_lavalink_server_picker_title =>
      'Serveurs Lavalink publics';

  @override
  String bot_settings_lavalink_server_subtitle(String port, String version) {
    return 'Port $port — $version';
  }

  @override
  String bot_settings_lavalink_servers_available(int count) {
    return '$count serveurs disponibles';
  }

  @override
  String get bot_settings_lavalink_ssl => 'Utiliser SSL/TLS';

  @override
  String get bot_settings_lavalink_ssl_subtitle => 'Connexion sécurisée wss://';

  @override
  String get bot_settings_lavalink_success => 'Connexion réussie !';

  @override
  String get bot_settings_lavalink_test_btn => 'Tester la connexion';

  @override
  String get bot_settings_lavalink_testing => 'Test en cours...';

  @override
  String get bot_settings_lavalink_view_offers => 'Voir les offres';

  @override
  String get bot_settings_no_activities => 'Aucune activité configurée';

  @override
  String get bot_settings_presence_dnd => 'Ne pas déranger';

  @override
  String get bot_settings_presence_idle => 'Absent (Inactif)';

  @override
  String get bot_settings_presence_invisible => 'Invisible';

  @override
  String get bot_settings_presence_online => 'En ligne';

  @override
  String get bot_settings_presence_status_label => 'Présence';

  @override
  String get bot_settings_presence_status_title => 'Statut de Présence du Bot';

  @override
  String get bot_settings_profile_saved =>
      'Profil/statuts appliqués avec succès';

  @override
  String get bot_settings_profile_title => 'Profil du bot';

  @override
  String get bot_settings_remove_status => 'Supprimer l\'activité';

  @override
  String get bot_settings_save_intents_btn => 'Sauvegarder les intents';

  @override
  String get bot_settings_save_intents_caption =>
      'Cette action met a jour uniquement la configuration des intents.';

  @override
  String get bot_settings_save_profile_caption =>
      'Cette action applique le nom/avatar immediatement et enregistre la rotation des statuts.';

  @override
  String get bot_settings_save_profile_status_btn =>
      'Sauvegarder profil et statuts';

  @override
  String get bot_settings_save_success => 'Paramètres enregistrés avec succès';

  @override
  String get bot_settings_save_token_btn => 'Sauvegarder token et intents';

  @override
  String get bot_settings_save_token_caption =>
      'Le token est protege. Cliquez d\'abord sur \"Modifier le token\", puis sauvegardez.';

  @override
  String get bot_settings_save_token_first =>
      'Veuillez d\'abord sauvegarder le token avant d\'appliquer les changements de profil/statuts.';

  @override
  String get bot_settings_save_token_only_btn => 'Sauvegarder le token';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Activité $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Intervalle max (s)';

  @override
  String get bot_settings_status_min_interval => 'Intervalle min (s)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Ajoutez une ou plusieurs activités. Chaque activité nécessite un type, un nom et un intervalle min/max (secondes).';

  @override
  String get bot_settings_status_rotation_title => 'Rotation des activités';

  @override
  String get bot_settings_status_text_label => 'Nom de l\'activité';

  @override
  String get bot_settings_status_type_competing => 'Participe';

  @override
  String get bot_settings_status_type_label => 'Type';

  @override
  String get bot_settings_status_type_listening => 'Ecoute';

  @override
  String get bot_settings_status_type_playing => 'Joue a';

  @override
  String get bot_settings_status_type_streaming => 'Diffuse';

  @override
  String get bot_settings_status_type_watching => 'Regarde';

  @override
  String get bot_settings_tab_advanced => 'Avancé & Maintenance';

  @override
  String get bot_settings_tab_general => 'Général';

  @override
  String get bot_settings_tab_intents => 'Intents & Privilèges';

  @override
  String get bot_settings_tab_lavalink => 'Lavalink';

  @override
  String get bot_settings_tab_database => 'Base de données';

  @override
  String get bot_settings_database_section_title => 'Base de données externe';

  @override
  String get bot_settings_database_type_label => 'Type de base de données';

  @override
  String get bot_settings_database_type_none => 'Aucune (Désactivé)';

  @override
  String get bot_settings_database_type_postgres =>
      'PostgreSQL (mot-clé : pgsql)';

  @override
  String get bot_settings_database_type_mysql => 'MySQL (mot-clé : sql)';

  @override
  String get bot_settings_database_type_mongo => 'MongoDB (mot-clé : mongo)';

  @override
  String get bot_settings_database_info_postgres =>
      'Disponible dans vos scripts via le mot-clé global \"pgsql\" (ex : await pgsql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mysql =>
      'Disponible dans vos scripts via le mot-clé global \"sql\" (ex : await sql.query(\"SELECT * FROM users\")).';

  @override
  String get bot_settings_database_info_mongo =>
      'Disponible dans vos scripts via le mot-clé global \"mongo\" (ex : await mongo.collection(\"users\").find()).';

  @override
  String get bot_settings_database_uri_label => 'Chaîne de connexion (URI)';

  @override
  String get bot_settings_database_show_discrete_fields =>
      'Configurer les champs individuels (Hôte, Port, etc.)';

  @override
  String get bot_settings_database_hide_discrete_fields =>
      'Masquer les champs individuels';

  @override
  String get bot_settings_database_host => 'Hôte';

  @override
  String get bot_settings_database_host_hint => 'localhost ou adresse IP';

  @override
  String get bot_settings_database_port => 'Port';

  @override
  String get bot_settings_database_name => 'Nom de la base de données';

  @override
  String get bot_settings_database_name_hint => 'ex : bot_db';

  @override
  String get bot_settings_database_user => 'Utilisateur';

  @override
  String get bot_settings_database_user_hint => 'ex : root ou postgres';

  @override
  String get bot_settings_database_password => 'Mot de passe';

  @override
  String get bot_settings_database_ssl => 'Activer SSL / TLS';

  @override
  String get bot_settings_database_save_btn => 'Enregistrer la configuration';

  @override
  String get bot_settings_tab_presence => 'Présence & Statut';

  @override
  String get bot_settings_title => 'Personnaliser le bot / Profil';

  @override
  String get bot_settings_token_hidden_desc =>
      'Le champ du token est masque par defaut pour plus de securite.';

  @override
  String get bot_settings_token_hint => 'Entrez votre token de bot ici';

  @override
  String get bot_settings_token_mismatch_confirm =>
      'Remplacer le token quand même';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Ce token appartient au bot $newId, mais les données actuelles concernent le bot $oldId. Les commandes et paramètres peuvent ne pas correspondre. Continuer quand même ?';
  }

  @override
  String get bot_settings_token_mismatch_title => 'Bot différent détecté';

  @override
  String get bot_settings_token_required => 'Le token du bot est requis.';

  @override
  String get bot_settings_token_saved => 'Token sauvegarde avec succes';

  @override
  String get bot_settings_token_title => 'Token du bot';

  @override
  String get bot_settings_update_token => 'Mettre à jour le token du bot';

  @override
  String get bot_settings_username_hint =>
      'Laisser vide pour conserver le nom d\'utilisateur actuel';

  @override
  String get bot_settings_username_override =>
      'Nom d\'utilisateur personnalisé';

  @override
  String get bot_settings_workflow_docs => 'Documentation';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Guides, reference BDFD et documentation discord.js';

  @override
  String get bot_stats_collecting => 'Collecte...';

  @override
  String get bot_stats_cpu => 'CPU du processus bot';

  @override
  String get bot_stats_notes =>
      'Notes : CPU disponible sur Android/Linux. Stockage = fichiers de données du bot dans l\'application.';

  @override
  String get bot_stats_ram_estimated => 'RAM bot uniquement (estimée)';

  @override
  String get bot_stats_ram_process => 'RAM du processus bot';

  @override
  String get bot_stats_source_local_hosting => 'Source : hébergement local';

  @override
  String get bot_stats_source_runner_api => 'Source : API Runner';

  @override
  String get bot_stats_storage => 'Stockage du bot (données app)';

  @override
  String get bot_stats_title => 'Statistiques du bot';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Tapez \$ puis le début d\'une fonction pour afficher des suggestions rapides.';

  @override
  String get cmd_bdfd_autocomplete_title => 'Auto-complétion BDFD par préfixe';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Aucun problème détecté dans le script courant.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Erreur';

  @override
  String get cmd_bdfd_diagnostics_title => 'Diagnostics BDFD';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Avertissement';

  @override
  String get cmd_bdfd_script_empty_error =>
      'Le corps du script BDFD ne peut pas être vide.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'Corps du script BDFD';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Ce script BDFD contient encore des diagnostics :';

  @override
  String get cmd_create_tooltip => 'Créer la commande';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Aucun problème détecté dans le script Dart courant.';

  @override
  String get cmd_dart_diagnostics_error => 'Erreur';

  @override
  String get cmd_dart_diagnostics_title => 'Diagnostics Dart';

  @override
  String get cmd_dart_diagnostics_warning => 'Avertissement';

  @override
  String get cmd_dart_script_hint => 'return \"Hello from Dart Direct\";';

  @override
  String get cmd_dart_script_label => 'Corps du script Dart';

  @override
  String cmd_batch_delete_confirm(int count) {
    return 'Supprimer $count commandes ?';
  }

  @override
  String cmd_batch_delete_success(Object count) {
    return '$count commandes supprimées';
  }

  @override
  String cmd_delete_confirm(Object name) {
    return 'Supprimer la commande \"$name\" ?';
  }

  @override
  String cmd_delete_success(Object name) {
    return 'Commande \"$name\" supprimée';
  }

  @override
  String get cmd_delete_tooltip => 'Supprimer la commande';

  @override
  String get cmd_deploy_close_button => 'Fermer';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'Synchronisation sécurisée dans votre espace en ligne';

  @override
  String get cmd_deploy_cloud_sync_title => 'Sauvegarde Cloud';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return 'Configuration de /$name';
  }

  @override
  String get cmd_deploy_discord_sync_subtitle =>
      'Publication de la commande sur l\'API Discord';

  @override
  String get cmd_deploy_discord_sync_title => 'Synchronisation Discord';

  @override
  String get cmd_deploy_failed_title => 'Échec du déploiement';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'Mise à jour instantanée du runner de votre bot';

  @override
  String get cmd_deploy_hot_reload_title => 'Rechargement à chaud';

  @override
  String get cmd_deploy_in_progress_title => 'Déploiement en cours...';

  @override
  String get cmd_deploy_local_save_subtitle =>
      'Enregistrement de la commande sur l\'appareil';

  @override
  String get cmd_deploy_local_save_title => 'Sauvegarde locale';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Application à chaud de la configuration';

  @override
  String get cmd_deploy_reload_bot_title => 'Rechargement du Bot';

  @override
  String get cmd_deploy_retry_button => 'Réessayer';

  @override
  String get cmd_deploy_success_title => 'Déploiement réussi !';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'Commande \"$name\" déployée et active !';
  }

  @override
  String get cmd_editor_mode_advanced => 'Mode avancé';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Éditeur complet avec réponse personnalisée, options et builder d\'actions.';

  @override
  String get cmd_editor_mode_locked =>
      'Le mode avancé est verrouillé pour cette commande.';

  @override
  String get cmd_editor_mode_simple => 'Mode simplifié';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Créez une commande rapidement avec des options guidées et des actions préconfigurées.';

  @override
  String get cmd_editor_mode_switch_adv => 'Passer en mode avancé';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Passer';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Ce changement est définitif pour cette commande. Vous ne pourrez plus revenir au mode simplifié.';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Passer en mode avancé ?';

  @override
  String get cmd_editor_mode_title => 'Mode d\'édition';

  @override
  String get cmd_error_fill_fields => 'Veuillez remplir tous les champs';

  @override
  String get cmd_execution_mode_bdfd => 'Mode script BDFD';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Écrivez le corps de commande en script compatible BDFD tout en gardant la définition visuelle.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'Le script est compilé en actions internes. Les diagnostics sont affichés pendant l\'édition ; les scripts invalides échouent à l\'exécution.';

  @override
  String get cmd_execution_mode_dart => 'Mode Dart Direct';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Écrivez directement le corps de commande en Dart avec diagnostics runtime.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Le code Dart est compilé au runtime via un moteur sandboxé. Gardez les scripts déterministes et retournez une valeur quand nécessaire.';

  @override
  String get cmd_execution_mode_javascript => 'JavaScript';

  @override
  String get cmd_execution_mode_javascript_desc =>
      'Écrire du code JS personnalisé pour cette commande.';

  @override
  String get cmd_execution_mode_javascript_note =>
      'Toutes les fonctions BDFD sont disponibles comme fonctions JS asynchrones. Utilisez ctx.authorId, ctx.channelId, vars[\'key\'] pour accéder au contexte et aux variables.';

  @override
  String get cmd_execution_mode_desc =>
      'La définition de commande reste dans le builder visuel. Choisissez ensuite comment exécuter le corps de la commande.';

  @override
  String get cmd_execution_mode_title => 'Mode d\'exécution';

  @override
  String get cmd_execution_mode_workflow => 'Mode workflow';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Utilise le builder visuel actuel pour la réponse et les actions.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'Le mode workflow reste le chemin de production actuel et continue d\'être totalement pris en charge.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrer';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Générer un squelette de migration Dart à partir du script BDFD actuel.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Cette commande n\'a pas pu être entièrement chargée (hors-ligne ou token invalide). Connectez un token valide pour modifier.';

  @override
  String get cmd_show_variables => 'Ouvrir la documentation des variables';

  @override
  String get cmd_simple_action_add_role => 'Ajouter un rôle';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Attribue le /role sélectionné au /user sélectionné.';

  @override
  String get cmd_simple_action_ban => 'Bannir un utilisateur';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      'De 0 à 7 jours de messages récents';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Jours de messages à supprimer au ban';

  @override
  String get cmd_simple_action_ban_desc =>
      'Bannit le /user sélectionné du serveur.';

  @override
  String get cmd_simple_action_create_invite => 'Créer une invitation';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'Crée une invitation pour le salon courant ou un /channel optionnel.';

  @override
  String get cmd_simple_action_create_poll => 'Créer un sondage';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'Crée un sondage avec une /question dynamique et des réponses fixes.';

  @override
  String get cmd_simple_action_delete => 'Supprimer des messages';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Utilisé si /count n\'est pas fourni';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Nombre par défaut à supprimer';

  @override
  String get cmd_simple_action_delete_desc =>
      'Supprime des messages dans le salon courant (option /count).';

  @override
  String get cmd_simple_action_kick => 'Expulser un utilisateur';

  @override
  String get cmd_simple_action_kick_desc =>
      'Expulse le /user sélectionné du serveur.';

  @override
  String get cmd_simple_action_mute => 'Rendre muet un utilisateur';

  @override
  String get cmd_simple_action_mute_desc =>
      'Rend temporairement muet le /user sélectionné.';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Exemples : 10m, 2h, 1d, ou secondes brutes';

  @override
  String get cmd_simple_action_mute_duration_label => 'Durée du mute';

  @override
  String get cmd_simple_action_pin => 'Épingler un message';

  @override
  String get cmd_simple_action_pin_desc =>
      'Épingle un message du salon courant via /message_id.';

  @override
  String get cmd_simple_action_reason_hint =>
      'Raison optionnelle partagée par les actions de modération';

  @override
  String get cmd_simple_action_reason_label => 'Raison du log d\'audit';

  @override
  String get cmd_simple_action_remove_role => 'Retirer un rôle';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Retire le /role sélectionné du /user sélectionné.';

  @override
  String get cmd_simple_action_send_message => 'Envoyer un message';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Envoie un message supplémentaire dans le salon courant.';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Message envoyé par l\'action Send Message';

  @override
  String get cmd_simple_action_send_message_label => 'Message de l\'action';

  @override
  String get cmd_simple_action_unban => 'Débannir un utilisateur';

  @override
  String get cmd_simple_action_unban_desc =>
      'Débannit un utilisateur via une chaîne /user_id.';

  @override
  String get cmd_simple_action_unmute => 'Retirer le mute';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Retire le timeout du /user sélectionné.';

  @override
  String get cmd_simple_action_unpin => 'Désépingler un message';

  @override
  String get cmd_simple_action_unpin_desc =>
      'Désépingle un message du salon courant via /message_id.';

  @override
  String get cmd_simple_actions_desc =>
      'Sélectionnez ce que la commande doit faire. Les options sont générées automatiquement.';

  @override
  String get cmd_simple_actions_title => 'Actions simplifiées';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Bannir un utilisateur et Débannir un utilisateur ne peuvent pas être activés ensemble en mode simplifié.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Rendre muet un utilisateur et Retirer le mute ne peuvent pas être activés ensemble en mode simplifié.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Épingler un message et Désépingler un message ne peuvent pas être activés ensemble en mode simplifié.';

  @override
  String get cmd_simple_execution_desc =>
      'Affinez les actions générées sans quitter le mode simplifié.';

  @override
  String get cmd_simple_execution_title => 'Réglages d\'exécution';

  @override
  String get cmd_simple_generated_none =>
      'Aucune option générée pour le moment. Sélectionnez au moins une action.';

  @override
  String get cmd_simple_generated_options => 'Options de commande générées';

  @override
  String get cmd_simple_group_messages_desc =>
      'Actions liées aux messages et au salon courant.';

  @override
  String get cmd_simple_group_messages_title => 'Messages';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Actions de modération et de gestion des membres avec options guidées.';

  @override
  String get cmd_simple_group_moderation_title => 'Modération';

  @override
  String get cmd_simple_group_utility_desc =>
      'Fonctions utiles comme les invitations et les sondages.';

  @override
  String get cmd_simple_group_utility_title => 'Utilitaires';

  @override
  String get cmd_simple_invite_max_age_hint =>
      '0 pour aucune expiration, jusqu\'à 604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'L\'expiration de l\'invitation doit être un nombre entre 0 et 604800 secondes.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'Expiration de l\'invitation (secondes)';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 pour illimité';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Le nombre max d\'utilisations doit être un nombre entre 0 et 1000000.';

  @override
  String get cmd_simple_invite_max_uses_label => 'Nombre max d\'utilisations';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Valeurs par défaut utilisées par l\'action Create Invite générée.';

  @override
  String get cmd_simple_invite_settings_title => 'Réglages de l\'invitation';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Le membre est retiré s\'il quitte avant de recevoir un rôle.';

  @override
  String get cmd_simple_invite_temporary_label => 'Adhésion temporaire';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Crée toujours une nouvelle invitation au lieu d\'en réutiliser une.';

  @override
  String get cmd_simple_invite_unique_label => 'Forcer une invitation unique';

  @override
  String get cmd_simple_option_channel => '/channel (Salon)';

  @override
  String get cmd_simple_option_channel_desc =>
      'Salon optionnel pour créer l\'invitation';

  @override
  String get cmd_simple_option_count => '/count (Entier)';

  @override
  String get cmd_simple_option_count_desc => 'Nombre de messages à supprimer';

  @override
  String get cmd_simple_option_message_id => '/message_id (Texte)';

  @override
  String get cmd_simple_option_message_id_desc => 'ID du message ciblé';

  @override
  String get cmd_simple_option_question => '/question (Texte)';

  @override
  String get cmd_simple_option_question_desc => 'Question du sondage';

  @override
  String get cmd_simple_option_role => '/role (Rôle)';

  @override
  String get cmd_simple_option_role_desc => 'Rôle ciblé';

  @override
  String get cmd_simple_option_user => '/user (Utilisateur)';

  @override
  String get cmd_simple_option_user_desc => 'Utilisateur ciblé';

  @override
  String get cmd_simple_option_user_id => '/user_id (Texte)';

  @override
  String get cmd_simple_option_user_id_desc => 'ID utilisateur à débannir';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Une réponse par ligne, ou séparées par des virgules. Minimum 2, maximum 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Le sondage doit contenir entre 2 et 10 réponses non vides.';

  @override
  String get cmd_simple_poll_answers_label => 'Réponses du sondage';

  @override
  String get cmd_simple_poll_duration_hint => 'De 1 à 168 heures';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'La durée du sondage doit être un nombre entre 1 et 168 heures.';

  @override
  String get cmd_simple_poll_duration_label => 'Durée du sondage (heures)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Les utilisateurs peuvent sélectionner plus d\'un choix.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Autoriser plusieurs réponses';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Valeurs par défaut utilisées par l\'action Create Poll générée.';

  @override
  String get cmd_simple_poll_settings_title => 'Réglages du sondage';

  @override
  String get cmd_simple_response_desc =>
      'Message renvoyé à l\'utilisateur après l\'exécution des actions.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Embeds optionnels envoyés avec la réponse finale.';

  @override
  String get cmd_simple_response_embeds_title => 'Embeds de réponse';

  @override
  String get cmd_simple_response_hint => 'Terminé ✅';

  @override
  String get cmd_simple_response_title => 'Réponse finale';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Éphémère';

  @override
  String get cmd_simple_response_visibility_label => 'Visibilité de la réponse';

  @override
  String get cmd_simple_response_visibility_public => 'Publique';

  @override
  String get cmd_simple_send_message_required =>
      'Veuillez renseigner le message de l\'action avant de sauvegarder.';

  @override
  String get cmd_variables_title => 'Variables de la commande';

  @override
  String get command_awaited_error => 'Erreur';

  @override
  String get command_awaited_filter_hint =>
      'Exemple : <numeric> ou <yes/no/cancel>';

  @override
  String get command_awaited_filter_label => 'Filtre (optionnel)';

  @override
  String get command_awaited_name_hint => 'Exemple : say';

  @override
  String get command_awaited_name_label => 'Nom du callback attendu';

  @override
  String get command_awaited_preset_active => 'Preset de callback attendu';

  @override
  String get command_awaited_preset_button =>
      'Utiliser le preset de callback attendu';

  @override
  String get command_awaited_preset_desc =>
      'Le nom de la commande est généré et enregistré comme callback legacy interne.';

  @override
  String get command_awaited_success => 'Succès';

  @override
  String get command_context_bot_dm => 'MP du bot';

  @override
  String get command_context_group_dm => 'DM de groupe / Autre';

  @override
  String get command_context_guild => 'Serveur';

  @override
  String get command_description_length =>
      'La description de commande doit contenir au maximum 100 caractères';

  @override
  String get command_description_required =>
      'Veuillez saisir une description de commande';

  @override
  String get command_edit_raw_name => 'Modifier le nom brut';

  @override
  String get command_error_missing_bot_id =>
      'ID de bot manquant pour la sauvegarde de commande locale.';

  @override
  String get command_execution_error =>
      'Une erreur est survenue lors de l\'exécution de cette commande.';

  @override
  String get command_export_tooltip => 'Exporter le payload de la commande';

  @override
  String get command_import_tooltip => 'Importer un payload de commande';

  @override
  String get command_discord_rules_message_hint =>
      'Les commandes message apparaissent dans le menu contextuel d\'un message. Le nom peut contenir des espaces et des majuscules (1-32 car.). Discord n\'utilise pas de description.';

  @override
  String get command_discord_rules_slash_hint =>
      'Les commandes slash sont enregistrées sur Discord. Le nom doit être en minuscules (1-32 car.). La description est obligatoire (1-100 car.). La taille combinée nom, description et options ne peut pas dépasser 8000 caractères.';

  @override
  String get command_discord_rules_user_hint =>
      'Les commandes utilisateur apparaissent dans le menu contextuel d\'un utilisateur. Le nom peut contenir des espaces et des majuscules (1-32 car.). Discord n\'utilise pas de description.';

  @override
  String get command_info_desc => 'Métadonnées et disponibilité';

  @override
  String get command_info_title => 'Info de la commande';

  @override
  String get command_integration_guild => 'Installation serveur';

  @override
  String get command_integration_label =>
      'Où cette commande peut être utilisée';

  @override
  String get command_integration_user => 'Installation utilisateur';

  @override
  String get command_legacy_mode_subtitle =>
      'Exécutée depuis le chat avec le préfixe du bot (exemple : !config #channel).';

  @override
  String get command_legacy_mode_title =>
      'Activer le mode préfixe sur cette commande';

  @override
  String get command_legacy_prefix_desc =>
      'Déclenchée via messageCreate avec <préfixe><commande>.';

  @override
  String get command_legacy_prefix_title => 'Mode commande à préfixe';

  @override
  String get command_legacy_preset_desc =>
      'Générer un déclencheur de callback attendu interne pour une commande à préfixe locale uniquement.';

  @override
  String get command_legacy_preset_title => 'Preset préfixe';

  @override
  String get command_legacy_response_label => 'Mode de réponse préfixe';

  @override
  String get command_modal_disabled_legacy =>
      'Les modals sont désactivés en mode préfixe.';

  @override
  String get command_name_generated =>
      'Généré par le preset de callback attendu.';

  @override
  String get command_name_label => 'Nom';

  @override
  String get command_not_found => 'Commande introuvable';

  @override
  String get command_options_legacy_params =>
      'Paramètres positionnels à préfixe (ordre : requis puis optionnels)';

  @override
  String get command_options_slash_params => 'Paramètres de commande slash';

  @override
  String get command_options_title => 'Options de commande';

  @override
  String get command_payload_hint => 'Payload de commande';

  @override
  String get command_prefix_rules_hint =>
      'Les commandes à préfixe s\'exécutent depuis les messages du chat (ex. !ping) et ne sont pas enregistrées sur Discord. Les règles slash Discord ne s\'appliquent pas. La description est optionnelle.';

  @override
  String get command_permissions_admin_warning =>
      'Administrateur sélectionné : cela contourne les autres vérifications de permissions.';

  @override
  String get command_permissions_bitfield =>
      'Champ de bits de permission calculé';

  @override
  String get command_permissions_bitfield_helper =>
      'Calculé automatiquement à partir des permissions sélectionnées.';

  @override
  String command_permissions_count(int count) {
    return '$count permission(s) sélectionnée(s)';
  }

  @override
  String get command_permissions_label =>
      'Permissions membres par défaut (optionnel)';

  @override
  String get command_permissions_none =>
      'Aucune sélection (tout le monde peut utiliser la commande)';

  @override
  String get command_permissions_tip =>
      'Astuce : laissez tout décoché pour rendre la commande disponible à tous par défaut.';

  @override
  String get command_permissions_title => 'Sélectionner les permissions';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Attention : bits de permission inconnus détectés dans les données sauvegardées et préservés : $bits';
  }

  @override
  String get command_prefix_helper =>
      'Supporte les templates et variables scopées (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'Remplacement du préfixe (optionnel)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'Portée de la commande (Contextes)';

  @override
  String get command_subcommand_workflow_desc =>
      'Choisissez le sous-commande que vous configurez.';

  @override
  String get command_subcommand_workflow_title => 'Workflow SubCommand';

  @override
  String command_sync_failed_local(String error) {
    return 'Enregistré localement. Échec de la synchronisation Discord : $error';
  }

  @override
  String get command_cloud_sync_failed_saved =>
      'Enregistré sur Discord et localement. La sauvegarde cloud a échoué.';

  @override
  String get command_cloud_sync_retry => 'Réessayer la sync';

  @override
  String get cmd_block_editor_empty_title => 'Aucune action pour l\'instant';

  @override
  String get cmd_block_editor_empty_hint =>
      'Ajoutez un bloc d\'action pour définir ce que fait votre commande à l\'exécution.';

  @override
  String get cmd_block_editor_add_action => 'Ajouter une action';

  @override
  String cmd_block_editor_action_label(int index) {
    return 'Action $index';
  }

  @override
  String get command_target_subcommand => 'Sous-commande cible';

  @override
  String get command_type_label => 'Type de commande';

  @override
  String get command_type_legacy => 'Commande à préfixe';

  @override
  String get command_type_locked =>
      'Le type de commande ne peut pas être changé après la création.';

  @override
  String get command_type_message => 'Commande Message';

  @override
  String get command_type_slash => 'Commande Slash';

  @override
  String get command_type_user => 'Commande Utilisateur';

  @override
  String get command_unsaved_confirm =>
      'Vous avez des modifications non enregistrées. Les abandonner ?';

  @override
  String get command_unsaved_keep => 'Continuer l\'édition';

  @override
  String get command_unsaved_title => 'Modifications non enregistrées';

  @override
  String get commands_all_folders => 'Tous les dossiers';

  @override
  String get commands_create_button => 'Créer une commande';

  @override
  String get commands_create_folder => 'Créer un dossier';

  @override
  String commands_create_from_query(String query) {
    return 'Créer la commande \"$query\"';
  }

  @override
  String get commands_delete_folder => 'Supprimer le dossier';

  @override
  String get commands_delete_folder_desc =>
      'Les commandes de ce dossier ne seront pas supprimées, juste retirées du dossier.';

  @override
  String get commands_empty => 'Aucune commande trouvée';

  @override
  String commands_error(String error) {
    return 'Erreur : $error';
  }

  @override
  String get commands_filter_legacy_local => 'Ancien local';

  @override
  String get commands_filter_template => 'Modèle';

  @override
  String get commands_filter_type_label => 'Type';

  @override
  String get commands_folder_hint => 'Nom du dossier (optionnel)';

  @override
  String get commands_folder_label => 'Dossier';

  @override
  String get commands_move_to_folder => 'Déplacer dans un dossier';

  @override
  String get commands_new_folder_hint => 'Nom du nouveau dossier';

  @override
  String get commands_no_folder => 'Aucun dossier';

  @override
  String get commands_no_match_filters =>
      'Aucune commande ne correspond aux filtres actuels.';

  @override
  String get commands_remove_from_folder => 'Retirer du dossier';

  @override
  String get commands_rename_folder => 'Renommer le dossier';

  @override
  String get commands_reorder_title => 'Organiser les commandes';

  @override
  String get commands_search_hint => 'Rechercher des commandes...';

  @override
  String get commands_tab => 'Commandes';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get commands_title => 'Commandes';

  @override
  String get common_add_argument => 'Ajouter un argument';

  @override
  String get common_add_option => 'Ajouter une option';

  @override
  String get common_add_section => 'Ajouter une section';

  @override
  String get common_all => 'Tout';

  @override
  String get common_apply => 'Appliquer';

  @override
  String get common_back => 'Retour';

  @override
  String get common_bot => 'Bot';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_clear => 'Effacer';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_custom_id => 'ID personnalisé';

  @override
  String get common_custom_id_required => 'ID personnalisé *';

  @override
  String get common_default => 'Défaut';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_description => 'Description';

  @override
  String get common_disabled => 'Désactivé';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_enabled => 'Activé';

  @override
  String get common_import => 'Importer';

  @override
  String get common_key => 'Clé';

  @override
  String get common_label => 'Libellé';

  @override
  String get common_manage_workflows => 'Gérer les workflows';

  @override
  String get common_move_down => 'Déplacer vers le bas';

  @override
  String get common_move_up => 'Déplacer vers le haut';

  @override
  String get common_name => 'Nom';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_none => 'Aucun';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => 'Opérateur';

  @override
  String get common_pick => 'Choisir';

  @override
  String get common_placeholder => 'Texte indicatif';

  @override
  String get common_refresh => 'Actualiser';

  @override
  String get common_refresh_workflows => 'Actualiser les workflows';

  @override
  String get common_remove => 'Supprimer';

  @override
  String get common_required => 'Requis';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_static_options => 'Options statiques';

  @override
  String get common_style => 'Style';

  @override
  String get common_type => 'Type';

  @override
  String get common_url => 'URL';

  @override
  String get common_value => 'Valeur';

  @override
  String get common_workflow => 'Workflow';

  @override
  String get component_accent_color =>
      'Couleur d\'accentuation (Hex, ex. FF0000)';

  @override
  String get component_action_row => 'Ligne d\'action';

  @override
  String get component_add_action_row => 'Ajouter une ligne d\'action';

  @override
  String get component_add_button => 'Ajouter un bouton';

  @override
  String get component_add_button_or_select =>
      'Ajouter un bouton / menu de sélection';

  @override
  String get component_add_checkbox_option => 'Ajouter une option checkbox';

  @override
  String get component_add_child => 'Ajouter un composant enfant';

  @override
  String get component_add_media_item => 'Ajouter un élément média';

  @override
  String get component_add_radio_option => 'Ajouter une option radio';

  @override
  String get component_add_root => 'Ajouter un composant racine';

  @override
  String get component_add_text_display => 'Ajouter un affichage texte';

  @override
  String get component_add_tooltip => 'Ajouter un composant';

  @override
  String get component_block_label_style => 'Style';

  @override
  String get component_block_workflow => 'Workflow';

  @override
  String get component_button_default_label => 'Bouton';

  @override
  String get component_checkbox_options => 'Options checkbox';

  @override
  String get component_checked_by_default => 'Coché par défaut';

  @override
  String get component_choose_color => 'Choisir la couleur';

  @override
  String get component_component_to_wrap => 'Composant à envelopper :';

  @override
  String get component_configure_click_actions => 'Configurer les actions';

  @override
  String get component_configure_select_actions =>
      'Configurer les actions de sélection';

  @override
  String get component_custom_id => 'ID personnalisé';

  @override
  String get component_custom_id_required => 'ID personnalisé *';

  @override
  String get component_default_choice_label => 'Choix';

  @override
  String get component_default_option_label => 'Option';

  @override
  String get component_disabled_hint =>
      'Entrez true/false ou une variable comme ((user.bc_isVip))';

  @override
  String get component_empty_option => 'Vide';

  @override
  String get component_file_url => 'URL du fichier';

  @override
  String get component_label => 'Libellé';

  @override
  String get component_label_title => 'Titre du libellé';

  @override
  String get component_markdown_content => 'Contenu Markdown';

  @override
  String get component_max_selections => 'Sélections max';

  @override
  String get component_media_url => 'URL image / vidéo';

  @override
  String get component_media_urls => 'URLs médias';

  @override
  String get component_min_selections => 'Sélections min';

  @override
  String get component_new_checkbox => 'Nouvelle checkbox';

  @override
  String get component_new_option => 'Nouvelle option';

  @override
  String get component_new_radio => 'Nouveau radio';

  @override
  String get component_not_implemented => 'Éditeur pas encore implémenté';

  @override
  String get component_on_click_workflow => 'Au clic, le workflow';

  @override
  String get component_on_select_workflow => 'À la sélection, le workflow';

  @override
  String get component_options => 'Options';

  @override
  String get component_pick_accent_color =>
      'Choisir la couleur d\'accentuation';

  @override
  String get component_placeholder => 'Texte indicatif';

  @override
  String get component_radio_options => 'Options radio';

  @override
  String get component_remove_confirm =>
      'Ce composant sera supprimé de la mise en page. Continuer ?';

  @override
  String get component_remove_row_title => 'Supprimer la ligne d\'action';

  @override
  String get component_remove_title => 'Supprimer le composant';

  @override
  String get component_section_accessory => 'Nœud accessoire (optionnel)';

  @override
  String get component_section_text_displays => 'Affichages de texte';

  @override
  String get component_selection_range => 'Nombre de sélections';

  @override
  String get component_spacing_large => 'Espacement large';

  @override
  String get component_spacing_small => 'Espacement réduit';

  @override
  String get component_style => 'Style';

  @override
  String get component_thumbnail_url => 'URL de la miniature';

  @override
  String get component_unknown_component => 'Composant inconnu';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => 'Requis';

  @override
  String get component_value_hint => 'Indice de la valeur du composant';

  @override
  String get component_visible_divider => 'Ligne de séparation visible';

  @override
  String get component_workflow_args_hint =>
      'Exemple : ticketId = ((opts.ticket))';

  @override
  String get component_workflow_args_title => 'Arguments d\'appel du workflow';

  @override
  String get component_workflow_click_hint =>
      'Nom du workflow sauvegardé à exécuter au clic';

  @override
  String get component_workflow_optional => 'Appeler un workflow (optionnel)';

  @override
  String get component_workflow_select_hint =>
      'Nom du workflow sauvegardé à exécuter à la sélection';

  @override
  String get confirm => 'Confirmer';

  @override
  String get copy => 'Copier';

  @override
  String get create => 'Créer';

  @override
  String get dart_editor_empty =>
      'Script vide — commencez à écrire pour voir les diagnostics Dart.';

  @override
  String get dart_editor_tap_hint => 'Appuyez pour ouvrir l\'éditeur Dart';

  @override
  String get dart_editor_title => 'Éditeur Dart';

  @override
  String get dashboard_analysis_period => 'Période d\'analyse';

  @override
  String dashboard_error(String error) {
    return 'Impossible de charger les stats : $error';
  }

  @override
  String get dashboard_error_rate => 'Taux d\'erreur';

  @override
  String get dashboard_execution_health_title => 'Santé des exécutions';

  @override
  String dashboard_executions(int count) {
    return '$count exécutions';
  }

  @override
  String get dashboard_failed_commands => 'Échecs';

  @override
  String get dashboard_loading => 'Chargement des stats...';

  @override
  String get dashboard_no_data =>
      'Aucune donnée d\'utilisation. Lancez votre bot pour commencer le suivi.';

  @override
  String get dashboard_p50_latency => 'Latence p50';

  @override
  String get dashboard_p95_latency => 'Latence p95';

  @override
  String get dashboard_period_24h => 'Dernières 24h';

  @override
  String get dashboard_period_30d => '30 derniers jours';

  @override
  String get dashboard_period_7d => '7 derniers jours';

  @override
  String get dashboard_premium_analytics_desc =>
      'Débloquez le taux d\'erreur, les percentiles de latence et les insights de localisation.';

  @override
  String get dashboard_premium_analytics_title => 'Analytics Premium';

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Actualiser les serveurs d\'exécution';

  @override
  String get dashboard_requires_runner =>
      'Connectez un runner pour voir les statistiques d\'utilisation.';

  @override
  String dashboard_selected_period_total(int count) {
    return '$count sur la période sélectionnée';
  }

  @override
  String get dashboard_single_runner_notice =>
      'Les stats affichées proviennent uniquement du runner actuellement configuré. Si vous utilisez plusieurs runners, cette vue peut être incomplète.';

  @override
  String get dashboard_timeline => 'Utilisation dans le temps';

  @override
  String get dashboard_title => 'Tableau de bord';

  @override
  String get dashboard_top_commands => 'Top commandes';

  @override
  String get dashboard_top_locales => 'Top localisations';

  @override
  String get dashboard_total => 'Total commandes';

  @override
  String get debug_replay_clear => 'Effacer les replays';

  @override
  String get debug_replay_clear_confirm =>
      'Tous les replays enregistrés seront supprimés. Continuer ?';

  @override
  String get debug_replay_clear_title => 'Effacer les replays';

  @override
  String get debug_replay_duration_label => 'DURÉE';

  @override
  String get debug_replay_empty_capturing =>
      'Capture en cours... Lancez une commande pour enregistrer un replay.';

  @override
  String get debug_replay_empty_idle =>
      'Capture désactivée. Activez-la et lancez une commande pour enregistrer un replay.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Boucle profondeur $depth, itération $iteration';
  }

  @override
  String get debug_replay_overview => 'Vue d\'ensemble';

  @override
  String get debug_replay_pause => 'Pause';

  @override
  String get debug_replay_play => 'Lire';

  @override
  String get debug_replay_premium_desc =>
      'Enregistrez et rejouez vos exécutions de commandes étape par étape. Voyez exactement ce que chaque action a fait, combien de temps elle a pris et où les erreurs se sont produites.';

  @override
  String get debug_replay_premium_title => 'Replay Débogueur Visuel';

  @override
  String get debug_replay_result_empty => '(aucun résultat)';

  @override
  String get debug_replay_result_label => 'RÉSULTAT';

  @override
  String get debug_replay_start_capture => 'Activer la capture';

  @override
  String debug_replay_start_offset(int ms) {
    return '+$ms ms depuis le début';
  }

  @override
  String get debug_replay_step_back => 'Étape précédente';

  @override
  String get debug_replay_step_first => 'Première étape';

  @override
  String get debug_replay_step_forward => 'Étape suivante';

  @override
  String get debug_replay_step_last => 'Dernière étape';

  @override
  String get debug_replay_stop_capture => 'Désactiver la capture';

  @override
  String get debug_replay_title => 'Replay Débogueur';

  @override
  String get debug_replay_variables_empty => '(aucune variable)';

  @override
  String get debug_replay_variables_label => 'VARIABLES';

  @override
  String get delete => 'Supprimer';

  @override
  String get done => 'Terminé';

  @override
  String download_completed(String id) {
    return 'Téléchargement terminé : $id';
  }

  @override
  String download_failed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get download_legacy_backup =>
      'Téléchargement terminé (ancienne sauvegarde)';

  @override
  String get drive_legacy_snapshot => 'Snapshot legacy';

  @override
  String get drive_manual_backup => 'Sauvegarde manuelle';

  @override
  String get edit_shell_all_saved =>
      'Toutes les modifications sont enregistrées';

  @override
  String get edit_shell_command_body => 'Corps de la commande';

  @override
  String get edit_shell_command_settings => 'Paramètres de la commande';

  @override
  String get edit_shell_command_settings_desc =>
      'Métadonnées, disponibilité, permissions et placement dans un dossier.';

  @override
  String get edit_shell_local_draft => 'Brouillon local';

  @override
  String get edit_shell_local_only => 'Local uniquement';

  @override
  String edit_shell_routes_count(int count) {
    return '$count route(s)';
  }

  @override
  String get edit_shell_save_changes => 'Enregistrer les modifications';

  @override
  String get edit_shell_subtitle =>
      'Les paramètres et les entrées sont en haut. Les actions et la réponse suivent en dessous.';

  @override
  String get edit_shell_trigger_inputs => 'Déclencheur et entrées';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Ajuster les options de la commande, le comportement du déclencheur et le mode d\'exécution.';

  @override
  String get edit_shell_type_command => 'Commande';

  @override
  String get edit_shell_type_legacy => 'Commande legacy';

  @override
  String get edit_shell_type_message => 'Commande message';

  @override
  String get edit_shell_type_slash => 'Commande slash';

  @override
  String get edit_shell_type_user => 'Commande utilisateur';

  @override
  String get edit_shell_unsaved => 'Modifications non enregistrées';

  @override
  String get edit_shell_untitled_command => 'Commande sans titre';

  @override
  String get embed_add_field => 'Ajouter un champ';

  @override
  String get embed_add_section => 'Ajouter une section';

  @override
  String get embed_add_tooltip => 'Ajouter un embed';

  @override
  String get embed_color_picker_title => 'Choisir la couleur de l\'embed';

  @override
  String get embed_delete_confirm => 'Cet embed sera supprimé. Continuer ?';

  @override
  String get embed_delete_title => 'Supprimer l\'embed';

  @override
  String embed_empty_message(int max) {
    return 'Aucun embed. Vous pouvez en ajouter jusqu\'à $max.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Ce champ sera supprimé de l\'embed. Continuer ?';

  @override
  String get embed_field_delete_title => 'Supprimer le champ';

  @override
  String embed_field_number(int index) {
    return 'Champ #$index';
  }

  @override
  String get embed_fields_empty => 'Aucun champ.';

  @override
  String embed_fields_header(int count) {
    return 'Champs ($count/25)';
  }

  @override
  String get embed_label_author_icon => 'URL icône de l\'auteur';

  @override
  String get embed_label_author_name => 'Nom de l\'auteur';

  @override
  String get embed_label_author_url => 'URL de l\'auteur';

  @override
  String get embed_label_color => 'Couleur (int ou #hex)';

  @override
  String get embed_label_dynamic_fields => 'Modèle de champs dynamiques';

  @override
  String get embed_label_footer_icon => 'URL icône du pied de page';

  @override
  String get embed_label_footer_text => 'Texte du pied de page';

  @override
  String get embed_label_image_url => 'URL de l\'image';

  @override
  String get embed_label_inline => 'En ligne';

  @override
  String get embed_label_thumbnail_url => 'URL de la miniature';

  @override
  String get embed_label_timestamp => 'Horodatage (ISO8601)';

  @override
  String get embed_checkbox_current_timestamp => 'Horodatage actuel';

  @override
  String get embed_hint_timestamp =>
      'Affiche l\'heure courante à l\'exécution de la commande. Pour des secondes Unix dans le texte, utilisez ((timestamp)) dans les champs de message.';

  @override
  String get embed_label_title => 'Titre';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return 'Intégration #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return 'Embeds de réponse ($count/$max)';
  }

  @override
  String get embed_section_author => 'Auteur';

  @override
  String get embed_section_color => 'Couleur';

  @override
  String get embed_section_dynamic_fields => 'Champs dynamiques';

  @override
  String get embed_section_fields => 'Champs';

  @override
  String get embed_section_footer => 'Pied de page';

  @override
  String get embed_section_media => 'Médias';

  @override
  String get embed_section_timestamp => 'Horodatage';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Supprimer :$name: ? Cette action est irréversible.';
  }

  @override
  String get emojis_delete_confirm_title => 'Supprimer l\'emoji';

  @override
  String emojis_delete_error(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String get emojis_delete_tooltip => 'Supprimer';

  @override
  String get emojis_empty =>
      'Aucun emoji pour l\'instant. Uploadez-en un pour commencer.';

  @override
  String get emojis_loading_error => 'Échec du chargement des emojis';

  @override
  String emojis_rename_error(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get emojis_rename_hint => 'Nouveau nom';

  @override
  String get emojis_rename_title => 'Renommer l\'emoji';

  @override
  String get emojis_rename_tooltip => 'Renommer';

  @override
  String get emojis_tab => 'Émoticônes';

  @override
  String get emojis_tab_short => 'Émojis';

  @override
  String get emojis_title => 'Emojis applicatifs';

  @override
  String get emojis_upload => 'Uploader un emoji';

  @override
  String emojis_upload_error(String error) {
    return 'Échec de l\'upload : $error';
  }

  @override
  String get emojis_upload_name_hint =>
      'Nom de l\'emoji (lettres, chiffres, _)';

  @override
  String get emojis_upload_pick_image => 'Choisir une image';

  @override
  String get error => 'Erreur';

  @override
  String get error_delete_messages_failed =>
      'Échec de la suppression des messages.';

  @override
  String get error_invalid_channel_type =>
      'Le salon n\'est pas un salon textuel.';

  @override
  String get error_invalid_count => 'Le nombre doit être supérieur à 0.';

  @override
  String get error_network_timeout => 'L\'action a expiré. Veuillez réessayer.';

  @override
  String error_with_details(String error) {
    return 'Erreur : $error';
  }

  @override
  String get export_button => 'Exporter en ZIP';

  @override
  String get export_commands => 'Commandes';

  @override
  String export_failed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get export_file_picker_busy =>
      'Un sélecteur de fichier est déjà ouvert';

  @override
  String get export_global_variables => 'Variables globales';

  @override
  String get export_import_title => 'Export / Import';

  @override
  String get export_section_desc =>
      'Exportez les sections sélectionnées de votre bot sous forme de fichier ZIP. Le token du bot n\'est jamais inclus.';

  @override
  String get export_section_title => 'Exporter';

  @override
  String get export_status => 'Statut & Activités';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get globals_add => 'Ajouter une variable';

  @override
  String get globals_add_global => 'Ajouter une variable globale';

  @override
  String get globals_add_scoped => 'Ajouter une variable scopée';

  @override
  String get globals_copy_value => 'Copier la valeur';

  @override
  String globals_delete_confirm(String key) {
    return 'Supprimer « $key » ?';
  }

  @override
  String get globals_delete_title => 'Supprimer la variable';

  @override
  String get globals_dialog_global_desc =>
      'Les variables globales sont partagées entre toutes les commandes et serveurs.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Usage : \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Une variable scopée stocke une valeur distincte par contexte $scope.';
  }

  @override
  String get globals_edit => 'Modifier une variable';

  @override
  String get globals_edit_global => 'Modifier la variable globale';

  @override
  String get globals_edit_scoped => 'Modifier la variable scopée';

  @override
  String get globals_empty => 'Aucune variable globale pour le moment';

  @override
  String get globals_empty_subtitle =>
      'Ajoutez une variable pour stocker des données persistantes accessibles par toutes les commandes.';

  @override
  String get globals_help_global =>
      'Partagées entre toutes les commandes. Accessibles via \$getVar[clé].';

  @override
  String get globals_help_scoped =>
      'Stockées par contexte (serveur, utilisateur, salon...). Chaque entrée conserve une valeur distincte par contexte Discord.';

  @override
  String get globals_key => 'Clé';

  @override
  String get globals_key_hint => 'ex. prefix, level, welcome_message';

  @override
  String get globals_mode_global => 'Globale';

  @override
  String get globals_mode_scoped => 'Scopée';

  @override
  String get globals_no_default => 'Aucune valeur par défaut';

  @override
  String get globals_refresh => 'Actualiser';

  @override
  String get globals_retry => 'Réessayer';

  @override
  String get globals_scope_channel => 'salon';

  @override
  String get globals_scope_guild => 'serveur';

  @override
  String get globals_scope_guildMember => 'membre';

  @override
  String get globals_scope_message => 'message';

  @override
  String get globals_scope_user => 'utilisateur';

  @override
  String get globals_search => 'Rechercher des variables...';

  @override
  String get globals_source_local => 'Local';

  @override
  String globals_source_runner(String name) {
    return 'Runner : $name';
  }

  @override
  String get globals_tab => 'Globales';

  @override
  String get globals_tab_short => 'Vars';

  @override
  String get globals_title => 'Variables';

  @override
  String get globals_value => 'Valeur';

  @override
  String get globals_value_auto_type_hint =>
      'La valeur est auto-typée (nombre, booléen, JSON).';

  @override
  String get guilds_empty_state =>
      'Le bot n\'est dans aucun serveur.\nInvitez-le dans un serveur pour le voir ici.';

  @override
  String guilds_leave_confirm(String name) {
    return 'Quitter \"$name\" ?\nLe bot sera retiré de ce serveur. Vous pourrez le réinviter plus tard depuis le portail développeur Discord.';
  }

  @override
  String guilds_leave_failed(String error) {
    return 'Impossible de quitter : $error';
  }

  @override
  String get guilds_leave_title => 'Quitter le serveur';

  @override
  String get guilds_leave_tooltip => 'Quitter';

  @override
  String guilds_left_success(String name) {
    return 'Vous avez quitté \"$name\".';
  }

  @override
  String guilds_members_count_other(int count) {
    return '~$count membres';
  }

  @override
  String get guilds_owner_label => '👑 Propriétaire';

  @override
  String guilds_server_count_other(int count) {
    return '$count serveurs';
  }

  @override
  String get guilds_tab => 'Serveurs';

  @override
  String get guilds_tab_short => 'Serveurs';

  @override
  String get hint_use_variables =>
      'Utilisez des variables/templates si nécessaire';

  @override
  String get home_add_time => 'Ajouter du temps';

  @override
  String get home_overline => 'MES PROJETS';

  @override
  String get home_empty_support_btn => 'Support Discord';

  @override
  String get home_empty_support_hint =>
      'Besoin d\'aide ? Rejoignez notre communauté !';

  @override
  String get home_foreground_service_not_started =>
      'Le service foreground n\'a pas démarré.';

  @override
  String get home_hosting_expired => 'Hébergement expiré';

  @override
  String home_hosting_time_left(String time) {
    return 'Hébergement restant : $time';
  }

  @override
  String home_hosting_banked(String time) {
    return 'Réserve : $time';
  }

  @override
  String home_hosting_expires_today(String time) {
    return 'Expire aujourd\'hui à $time';
  }

  @override
  String home_hosting_expires_tomorrow(String time) {
    return 'Expire demain à $time';
  }

  @override
  String get home_hosting_time_preserved =>
      'Le temps est préservé tant que le bot est arrêté.';

  @override
  String get home_hosting_status_active => 'Session active (en ligne)';

  @override
  String get home_hosting_status_paused => 'Réserve disponible (en pause)';

  @override
  String get home_hosting_ad_history => 'Historique des pubs';

  @override
  String get home_hosting_ad_rewards_history_title =>
      'Historique des gains publicitaires';

  @override
  String get home_hosting_ad_history_error =>
      'Erreur lors du chargement de l\'historique';

  @override
  String get home_hosting_ad_history_empty =>
      'Aucun gain publicitaire récent enregistré pour ce bot.';

  @override
  String get home_log_desktop_stop_requested => 'Arrêt du bot desktop demandé';

  @override
  String get home_log_start_requested => 'Démarrage du bot demandé';

  @override
  String get home_log_stop_requested => 'Arrêt du bot demandé';

  @override
  String get home_logs_tooltip => 'Logs du bot';

  @override
  String get home_manage => 'Gérer';

  @override
  String get home_notification_permission_required =>
      'La permission de notification est requise pour lancer le bot.';

  @override
  String home_server_count_one(int count) {
    return '$count serveur';
  }

  @override
  String home_server_count_other(int count) {
    return '$count serveurs';
  }

  @override
  String get home_start => 'Démarrer';

  @override
  String get home_start_ads => 'Démarrer (Voir Pub)';

  @override
  String get home_start_premium => 'Démarrer (Premium)';

  @override
  String get home_status_offline => 'Hors ligne';

  @override
  String get home_status_online => 'En ligne';

  @override
  String get home_stop => 'Arrêter';

  @override
  String get home_sync_failed => 'échec de la synchronisation';

  @override
  String get home_tab => 'Accueil';

  @override
  String get home_time_added => 'Temps ajouté avec succès !';

  @override
  String home_token_missing(String botName) {
    return 'Token introuvable pour $botName';
  }

  @override
  String get home_unknown_app => 'Inconnu';

  @override
  String get image_editor_create => 'Créer';

  @override
  String get image_editor_create_canvas => 'Créer un canvas d\'image';

  @override
  String image_editor_edit_canvas(int count) {
    return 'Éditer le canvas ($count opérations)';
  }

  @override
  String get image_editor_open => 'Ouvrir l\'éditeur';

  @override
  String get import_button => 'Importer';

  @override
  String import_failed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get import_nothing => 'Rien n\'a été importé.';

  @override
  String get import_overwrite => 'Écraser';

  @override
  String import_parse_failed(String error) {
    return 'Échec de l\'analyse du ZIP : $error';
  }

  @override
  String get import_pick_file => 'Sélectionner un fichier ZIP';

  @override
  String get import_section_desc =>
      'Importez un fichier ZIP précédemment exporté. Les conflits peuvent être résolus par élément.';

  @override
  String get import_section_title => 'Importer';

  @override
  String get import_skip => 'Ignorer';

  @override
  String import_summary_commands_imported(int count) {
    return '$count commande(s) importée(s)';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count commande(s) ignorée(s)';
  }

  @override
  String get import_summary_status_imported => 'statut importé';

  @override
  String get import_summary_variables_imported => 'variables importées';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) importé(s)';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) ignoré(s)';
  }

  @override
  String get js_editor_hint => '// Écrivez votre commande JavaScript ici...';

  @override
  String get js_editor_segmented_label => 'JS';

  @override
  String get js_editor_subtitle =>
      'Écrire du JavaScript personnalisé pour cette commande';

  @override
  String get js_editor_title => 'Éditeur JavaScript';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'échec d\'exécution du script BDFD pour la commande \"$command\" : $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'Gère les commandes depuis messageCreate avec <préfixe><commande>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Utilise des options positionnelles (exemple : !config #channel).';

  @override
  String get legacy_prefix_mode_title => 'Mode préfixe legacy';

  @override
  String get legacy_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label =>
      'Remplacement du préfixe (optionnel)';

  @override
  String get legacy_response_banner_body =>
      'Certaines commandes utilisent encore l\'ancien format de réponse. Ouvrez-les dans l\'éditeur et re-sauvegardez-les pour activer le nouveau format.';

  @override
  String get legacy_response_banner_dismiss => 'Ignorer';

  @override
  String get legacy_response_banner_migrate => 'Tout migrer';

  @override
  String get legacy_response_banner_migrate_failed => 'Échec de la migration';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes migrées',
      one: '1 commande migrée',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none => 'Aucune commande à migrer';

  @override
  String get legacy_response_banner_migrating => 'Migration en cours...';

  @override
  String get legacy_response_banner_short_body =>
      'Ouvrez et re-sauvegardez vos commandes pour migrer vers le nouveau format.';

  @override
  String get legacy_response_banner_short_title =>
      'Mise à jour des commandes disponible';

  @override
  String get legacy_response_banner_title =>
      'Mise à jour du format de réponse des commandes';

  @override
  String get legacy_response_mode_label => 'Mode de réponse legacy';

  @override
  String get local_command_awaited_desc =>
      'Les presets de callback awaités restent locaux car ce sont des callbacks internes au runtime.';

  @override
  String get local_command_desc =>
      'Stocke la commande uniquement dans Bot Creator. Vous pouvez l\'enregistrer dynamiquement sur des serveurs spécifiques avec BDFD \$registerGuildCommands.';

  @override
  String get local_command_title =>
      'Commande locale (ne pas enregistrer sur Discord)';

  @override
  String logs_runner_source(String name) {
    return 'Logs de : $name';
  }

  @override
  String get marketplace_about => 'À propos';

  @override
  String get marketplace_add => 'Ajouter';

  @override
  String get marketplace_api_unavailable => 'API client non disponible';

  @override
  String get marketplace_apply => 'Appliquer le template';

  @override
  String marketplace_apply_error(Object error) {
    return 'Échec de l’application : $error';
  }

  @override
  String get marketplace_apply_success => 'Template appliqué avec succès !';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount commande(s) ajoutée(s), $skippedCount ignorée(s) (doublons).';
  }

  @override
  String get marketplace_applying => 'Application en cours...';

  @override
  String marketplace_by_author(Object author, Object version) {
    return 'par $author · v$version';
  }

  @override
  String get marketplace_cancel => 'Annuler';

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count actions';
  }

  @override
  String get marketplace_command_preview_no_actions => 'Aucune action';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count options';
  }

  @override
  String get marketplace_command_preview_type_message =>
      'Menu contextuel message';

  @override
  String get marketplace_command_preview_type_slash => 'Commande slash';

  @override
  String get marketplace_command_preview_type_user =>
      'Menu contextuel utilisateur';

  @override
  String marketplace_commands_label(Object count) {
    return 'Commandes ($count)';
  }

  @override
  String get marketplace_config_hint =>
      'Remplis les valeurs obligatoires avant d’appliquer ce template.';

  @override
  String get marketplace_config_required => 'Configuration requise';

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return 'Appliquer ($count template)';
  }

  @override
  String get marketplace_conflict_keep_local => 'Garder Local';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'Local ($count actions)';
  }

  @override
  String get marketplace_conflict_subtitle =>
      'Certaines commandes du template existent déjà. Choisis quelle version garder :';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'Modèle ($count actions)';
  }

  @override
  String get marketplace_conflict_title => 'Conflits de commandes';

  @override
  String get marketplace_conflict_use_template => 'Utiliser Template';

  @override
  String get marketplace_connect_discord => 'Se connecter avec Discord';

  @override
  String get marketplace_connect_manager =>
      'Connecte-toi au Manager pour accéder au Marketplace.';

  @override
  String get marketplace_connect_publish =>
      'Connecte-toi au Manager pour publier un template.';

  @override
  String marketplace_count(Object count) {
    return '$count modèle(s)';
  }

  @override
  String get marketplace_delete => 'Supprimer';

  @override
  String marketplace_delete_confirm(Object name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get marketplace_delete_confirm_title => 'Supprimer le template';

  @override
  String get marketplace_delete_success => 'Template supprimé.';

  @override
  String get marketplace_edit => 'Modifier';

  @override
  String get marketplace_edit_hint =>
      'Pour modifier, republiez depuis la liste des commandes de votre bot avec le même nom.';

  @override
  String get marketplace_empty =>
      'Aucun template pour le moment.\nSois le premier à publier !';

  @override
  String marketplace_load_error(Object error) {
    return 'Échec du chargement : $error';
  }

  @override
  String get marketplace_login_hint =>
      'Vous devez connecter votre compte Discord pour accéder au Marketplace.';

  @override
  String get marketplace_login_instructions =>
      'Veuillez vous authentifier via Discord pour continuer à utiliser le Marketplace.';

  @override
  String get marketplace_login_required => 'Connexion Discord requise';

  @override
  String get marketplace_login_success => 'Discord connecté avec succès !';

  @override
  String get marketplace_login_title => 'Connexion au Manager';

  @override
  String marketplace_more(Object count) {
    return '+$count de plus';
  }

  @override
  String get marketplace_my_templates => 'Mes Templates';

  @override
  String marketplace_no_results(Object query) {
    return 'Aucun template ne correspond à \"$query\"';
  }

  @override
  String get marketplace_no_variables => 'Aucune variable globale définie.';

  @override
  String get marketplace_publish_add_variable => 'Ajouter une variable';

  @override
  String get marketplace_publish_add_variable_title => 'Ajouter une variable';

  @override
  String get marketplace_publish_back => 'Retour';

  @override
  String get marketplace_publish_button => 'Publier';

  @override
  String get marketplace_publish_category_hint => 'ex: ai, moderation, fun';

  @override
  String get marketplace_publish_category_label => 'Catégorie';

  @override
  String marketplace_publish_commands(Object count) {
    return 'Commandes ($count)';
  }

  @override
  String get marketplace_publish_desc_hint =>
      'Un résumé d’une ligne affiché dans le marketplace';

  @override
  String get marketplace_publish_desc_label => 'Description courte';

  @override
  String get marketplace_publish_desc_long_hint =>
      'Instructions d’utilisation détaillées, markdown supporté...';

  @override
  String get marketplace_publish_desc_long_label =>
      'Documentation complète (optionnel)';

  @override
  String get marketplace_publish_deselect_all => 'Tout désélectionner';

  @override
  String marketplace_publish_error(Object error) {
    return 'Échec de la publication : $error';
  }

  @override
  String get marketplace_publish_metadata => 'Détails du template';

  @override
  String get marketplace_publish_metadata_hint =>
      'Décris ton template pour que d’autres puissent le trouver et l’utiliser.';

  @override
  String get marketplace_publish_name_hint => 'ex: Bot de Modération IA';

  @override
  String get marketplace_publish_name_label => 'Nom du template';

  @override
  String get marketplace_publish_next => 'Suivant';

  @override
  String get marketplace_publish_no_content =>
      'Aucune commande ou workflow à publier.\nCrée-en d’abord !';

  @override
  String get marketplace_publish_required_fields =>
      'Veuillez remplir tous les champs requis (Nom, Description courte, Version) avant de publier.';

  @override
  String get marketplace_publish_select => 'Sélectionner le contenu';

  @override
  String get marketplace_publish_select_all => 'Tout sélectionner';

  @override
  String get marketplace_publish_select_hint =>
      'Choisis des commandes, des workflows, ou les deux.';

  @override
  String get marketplace_publish_success => 'Template publié avec succès !';

  @override
  String get marketplace_publish_summary => 'Résumé du template';

  @override
  String get marketplace_publish_tags_hint => 'ex: openai, chatbot, moderation';

  @override
  String get marketplace_publish_tags_label =>
      'Tags (séparés par des virgules)';

  @override
  String get marketplace_publish_title => 'Publier un template';

  @override
  String get marketplace_publish_user_must_define =>
      'L’utilisateur doit définir cette valeur';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'L’utilisateur sera invité à la remplir avant d’appliquer';

  @override
  String get marketplace_publish_variable_desc_hint =>
      'À quoi sert cette variable';

  @override
  String get marketplace_publish_variable_desc_label => 'Description';

  @override
  String get marketplace_publish_variable_name_hint => 'ex: TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_name_label => 'Nom de la variable';

  @override
  String get marketplace_publish_variables => 'Variables globales';

  @override
  String get marketplace_publish_variables_hint =>
      'Inclus des variables et indique lesquelles l’utilisateur doit remplir.';

  @override
  String get marketplace_publish_version_label => 'Version';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get marketplace_publishing => 'Publication en cours...';

  @override
  String get marketplace_rate_success => 'Note envoyée !';

  @override
  String get marketplace_rate_title => 'Noter ce template';

  @override
  String get marketplace_retry => 'Réessayer';

  @override
  String get marketplace_search_hint => 'Rechercher des templates...';

  @override
  String get marketplace_title => 'Marché';

  @override
  String marketplace_variable_required(Object name) {
    return '$name est obligatoire';
  }

  @override
  String get marketplace_variables_label => 'Variables pré-configurées';

  @override
  String marketplace_workflows_label(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get modal_add_text_input => 'Ajouter un champ texte';

  @override
  String get modal_builder_title => 'Constructeur de modal';

  @override
  String get modal_custom_id_hint => 'Utilisé pour identifier ce modal';

  @override
  String get modal_custom_id_label => 'ID personnalisé';

  @override
  String get modal_default_value => 'Valeur par défaut';

  @override
  String modal_field_default_label(int index) {
    return 'Champ $index';
  }

  @override
  String modal_input_index(int index) {
    return 'Champ $index';
  }

  @override
  String modal_inputs_count(int count) {
    return '$count/5 champs';
  }

  @override
  String get modal_remove_field_confirm =>
      'Ce champ sera supprimé du modal. Continuer ?';

  @override
  String get modal_remove_field_title => 'Supprimer le champ modal';

  @override
  String get modal_style => 'Style :';

  @override
  String get modal_title_label => 'Titre du modal';

  @override
  String get modal_workflow_submit =>
      'Workflow à exécuter à la soumission (optionnel)';

  @override
  String get more_options_title => 'Plus d\'options';

  @override
  String get more_tab => 'Plus';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get no_more_options => 'Aucune autre option disponible';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'Créer le workflow \"$query\"';
  }

  @override
  String get notion_filter_add => 'Ajouter un filtre';

  @override
  String get notion_filter_type => 'Type';

  @override
  String get ok => 'OK';

  @override
  String get onboarding_command_button => 'Continuer';

  @override
  String get onboarding_command_desc => 'Créez votre première commande';

  @override
  String get onboarding_command_example =>
      'Exemple:\n/hello → Le bot répond \"Bonjour! 👋\"';

  @override
  String get onboarding_command_learn =>
      'Comprendre le fonctionnement des commandes';

  @override
  String get onboarding_command_text =>
      'Les commandes sont le cœur de votre bot. Elles permettent aux utilisateurs d\'interagir avec votre bot via Discord.';

  @override
  String get onboarding_command_title => 'Étape 2: Ajouter une commande';

  @override
  String get onboarding_create_button => 'Continuer';

  @override
  String get onboarding_create_desc => 'Obtenez votre token Discord';

  @override
  String get onboarding_create_open_portal =>
      'Ouvrir le portail Discord Developer';

  @override
  String get onboarding_create_steps =>
      '1. Allez sur Discord Developer Portal\n2. Créez une nouvelle app\n3. Copiez le token du bot\n4. Collez-le ci-dessous';

  @override
  String get onboarding_create_tip =>
      'Conseil: Ne partagez jamais votre token! Il donne accès complet à votre bot.';

  @override
  String get onboarding_create_title => 'Étape 1: Créer un bot';

  @override
  String get onboarding_create_tutorial => 'Tutoriel: Comment obtenir un token';

  @override
  String get onboarding_remind_later => 'Me le rappeler plus tard';

  @override
  String get onboarding_skip_confirm => 'Passer l\'introduction';

  @override
  String get onboarding_skip_dialog_desc =>
      'Vous pourrez reprendre là où vous vous êtes arrêté la prochaine fois, ou ignorer complètement la visite.';

  @override
  String get onboarding_skip_dialog_title => 'Quitter l\'introduction ?';

  @override
  String get onboarding_start_button => 'Continuer';

  @override
  String get onboarding_start_desc => 'Lancez votre bot!';

  @override
  String get onboarding_start_hint =>
      'Une fois ton bot créé, tu trouveras le bouton Démarrer sur sa carte dans l\'application.';

  @override
  String get onboarding_start_text =>
      'Appuyez sur le bouton \"Démarrer\" sur la carte de votre bot. Testez ensuite votre commande dans Discord!';

  @override
  String get onboarding_start_tip =>
      'Bravo! Vous avez créé votre premier bot Discord. Vous pouvez maintenant ajouter plus de commandes et le personnaliser!';

  @override
  String get onboarding_start_title => 'Étape 3: Lancer le bot';

  @override
  String onboarding_step_indicator(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboarding_success_button => 'Commencer!';

  @override
  String get onboarding_success_desc =>
      'Votre bot Discord est maintenant prêt à l\'emploi!';

  @override
  String get onboarding_success_tip1 => 'Ajouter plus de commandes';

  @override
  String get onboarding_success_tip2 => 'Créer des workflows';

  @override
  String get onboarding_success_tip3 => 'Sauvegarder vos données';

  @override
  String get onboarding_success_title => 'Bravo!';

  @override
  String get onboarding_success_whatsnext => 'Que faire maintenant?';

  @override
  String get onboarding_welcome_desc =>
      'Créez votre premier bot Discord en 3 étapes simples. Nous vous guidons à travers chaque étape.';

  @override
  String get onboarding_welcome_skip => 'Passer';

  @override
  String get onboarding_welcome_start => 'Commencer';

  @override
  String get onboarding_welcome_title => 'Bienvenue dans Bot Creator';

  @override
  String get option_add_choice => 'Ajouter un choix';

  @override
  String get option_add_localizations => 'Ajouter des localisations';

  @override
  String get option_choice_delete_confirm =>
      'Ce choix sera supprimé. Continuer ?';

  @override
  String get option_choice_delete_title => 'Supprimer le choix';

  @override
  String get option_choice_name => 'Nom du choix';

  @override
  String option_choice_number(int index) {
    return 'Choix $index';
  }

  @override
  String get option_choice_value => 'Valeur du choix';

  @override
  String option_default_name(int index) {
    return 'Option $index';
  }

  @override
  String get option_delete_argument_confirm =>
      'Cet argument sera supprimé. Continuer ?';

  @override
  String get option_delete_argument_title => 'Supprimer l\'argument';

  @override
  String get option_delete_choice_confirm =>
      'Ce choix sera supprimé. Continuer ?';

  @override
  String get option_delete_choice_title => 'Supprimer l\'option';

  @override
  String get option_delete_confirm =>
      'Cette option sera supprimée. Continuer ?';

  @override
  String get option_delete_localization_confirm =>
      'Cette entrée de localisation sera supprimée. Continuer ?';

  @override
  String get option_delete_localization_title => 'Supprimer la localisation';

  @override
  String get option_delete_title => 'Supprimer l\'option';

  @override
  String get option_desc_required =>
      'Veuillez entrer une description pour l\'option';

  @override
  String option_label_number(int index) {
    return 'Étiquette $index';
  }

  @override
  String get option_localized_description => 'Description localisée';

  @override
  String get option_localized_name => 'Nom localisé';

  @override
  String get option_max_value => 'Valeur max';

  @override
  String get option_min_value => 'Valeur min';

  @override
  String get option_name_duplicate => 'Ce nom est déjà utilisé à ce niveau';

  @override
  String get option_name_invalid_chars =>
      'Le nom de l\'option doit contenir 1-32 caractères en minuscules. Autorisés : lettres, chiffres, tirets, underscores et apostrophes.';

  @override
  String get option_name_invalid_start =>
      'Le nom de l\'option commence par un caractère non pris en charge';

  @override
  String get option_name_max_length =>
      'Le nom de l\'option doit contenir au maximum 32 caractères';

  @override
  String get option_name_required => 'Veuillez saisir un nom pour l\'option';

  @override
  String get option_select_language => 'Sélectionner la langue';

  @override
  String option_static_label_n(int index) {
    return 'Libellé $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Valeur $index';
  }

  @override
  String get option_subcommand_options => 'Options de sous-commande';

  @override
  String get option_subcommands => 'Sous-commandes';

  @override
  String get option_type_attachment => 'Pièce jointe';

  @override
  String get option_type_boolean => 'Booléen';

  @override
  String get option_type_channel => 'Canal';

  @override
  String get option_type_integer => 'Entier';

  @override
  String get option_type_mentionable => 'Mentionnable';

  @override
  String get option_type_number => 'Nombre';

  @override
  String get option_type_role => 'Rôle';

  @override
  String get option_type_string => 'Texte';

  @override
  String get option_type_subcommand => 'Sous-commande';

  @override
  String get option_type_subcommand_group => 'Groupe de sous-commandes';

  @override
  String get option_type_unknown => 'Inconnu';

  @override
  String get option_type_user => 'Utilisateur';

  @override
  String option_value_number(int index) {
    return 'Valeur $index';
  }

  @override
  String get premium_active_desc =>
      'Merci pour votre soutien ! Toutes les publicités sont désactivées.';

  @override
  String get premium_active_title => 'Premium actif';

  @override
  String get premium_card_button => 'Voir les offres';

  @override
  String get premium_card_desc =>
      'Abonnez-vous pour supprimer toutes les publicités et démarrer vos bots instantanément, sans aucune pop-up.';

  @override
  String get premium_card_title => 'Supprimer les pubs';

  @override
  String get quick_access_title => 'Accès rapide';

  @override
  String get recovery_delete_bot => 'Supprimer le bot localement';

  @override
  String get recovery_label => 'Récupération';

  @override
  String get recovery_retry_discord => 'Retenter la connexion Discord';

  @override
  String get recovery_title => 'Mode récupération';

  @override
  String reply_active_route(String label) {
    return 'Route active : $label';
  }

  @override
  String get reply_buttons_desc =>
      'Ajouter des boutons interactifs ou des menus déroulants à ce message';

  @override
  String get reply_buttons_optional =>
      'Boutons et menus de sélection (optionnel)';

  @override
  String get reply_choose_type => 'Choisissez le type de réponse à envoyer';

  @override
  String get reply_command_reply_title => 'Réponse de commande';

  @override
  String get reply_configure_workflow => 'Configurer le workflow de réponse';

  @override
  String get reply_editor_title => 'Détails de la réponse';

  @override
  String get reply_mode_layout => 'Mode mise en page';

  @override
  String get reply_mode_layout_desc =>
      'Système de mise en page riche de Discord — conteneurs, médias, texte et formulaires';

  @override
  String get reply_mode_modal => 'Formulaire modal';

  @override
  String get reply_mode_modal_desc =>
      'Fenêtre pop-up avec champs de saisie texte';

  @override
  String get reply_mode_standard => 'Message standard';

  @override
  String get reply_mode_standard_desc =>
      'Texte, embeds et boutons / menus de sélection optionnels';

  @override
  String get reply_response_text_helper =>
      'Utilisé comme texte de réponse de commande slash. Supporte la syntaxe ((variable)).';

  @override
  String get reply_response_text_label => 'Texte de réponse';

  @override
  String get reply_response_workflow => 'Workflow de réponse';

  @override
  String response_embeds_count(int count) {
    return '$count intégration(s)';
  }

  @override
  String get response_interactive_components => 'composants interactifs';

  @override
  String get response_mode_layout => 'Mode disposition';

  @override
  String get response_mode_modal => 'Formulaire modal';

  @override
  String get response_mode_standard => 'Message standard';

  @override
  String get response_visibility_ephemeral => 'éphémère';

  @override
  String get response_visibility_public => 'public';

  @override
  String get response_workflow_auto_defer =>
      'Auto-defer si des actions existent';

  @override
  String get response_workflow_auto_defer_desc =>
      'Acquitter rapidement, exécuter les actions, puis modifier la réponse finale.';

  @override
  String get response_workflow_condition_desc =>
      'Si la variable existe et n\'est pas vide => utiliser THEN, sinon ELSE.';

  @override
  String get response_workflow_conditional_title =>
      'Réponse conditionnelle (MVP)';

  @override
  String get response_workflow_deferred_reply => 'Réponse différée';

  @override
  String get response_workflow_else_text => 'Texte de réponse ELSE (optionnel)';

  @override
  String get response_workflow_enable_condition => 'Activer la condition';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Éphémère (utilisateur de la commande uniquement)';

  @override
  String get response_workflow_error_policy => 'Politique d\'erreur';

  @override
  String get response_workflow_error_policy_desc =>
      'Quand une action échoue, modifier le message différé avec une erreur.';

  @override
  String get response_workflow_mode_component => 'Composant';

  @override
  String get response_workflow_mode_modal => 'Modale';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_public => 'Public';

  @override
  String get response_workflow_revert_tooltip =>
      'Annuler toutes les modifications';

  @override
  String get response_workflow_then_text => 'Texte de réponse THEN (optionnel)';

  @override
  String get response_workflow_title => 'Workflow de réponse';

  @override
  String get response_workflow_variable_key =>
      'Clé de variable (ex : opts.userId)';

  @override
  String get response_workflow_visibility => 'Visibilité';

  @override
  String get restore_completed => 'Restauration terminée';

  @override
  String get restore_runtime_db_recommended =>
      'Restauration terminée (Base SQLite restaurée, redémarrage conseillé)';

  @override
  String get review_actions_title => 'Actions';

  @override
  String review_description_line(String desc) {
    return 'Description : $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Dossier : $folder';
  }

  @override
  String get review_info_title => 'Info';

  @override
  String get review_legacy_mode => 'Mode préfixe activé';

  @override
  String get review_local_only => 'Commande locale uniquement';

  @override
  String review_name_line(String name) {
    return 'Nom : $name';
  }

  @override
  String get review_name_untitled => '(sans titre)';

  @override
  String review_options_count(int count) {
    return '$count option(s)';
  }

  @override
  String get review_reply_title => 'Réponse';

  @override
  String review_subcommand_routes(int count) {
    return '$count route(s) de sous-commande';
  }

  @override
  String get review_trigger_inputs_title => 'Déclencheur et entrées';

  @override
  String review_type_line(String type) {
    return 'Type : $type';
  }

  @override
  String get rewarded_start_complete_ad =>
      'Veuillez regarder la publicité en entier pour lancer votre session d\'hébergement.';

  @override
  String get rewarded_start_continue => 'Continuer';

  @override
  String get rewarded_start_message =>
      'Une publicité est requise pour lancer cette session d\'hébergement. Cela aide à financer le projet. Les utilisateurs Premium peuvent ignorer cela.';

  @override
  String get rewarded_start_no_ad_available =>
      'Aucune publicité disponible pour le moment. Veuillez réessayer plus tard.';

  @override
  String get rewarded_start_skip => 'Ignorer';

  @override
  String get rewarded_start_thanks => 'Merci pour votre soutien !';

  @override
  String get rewarded_start_title => 'Pub requise';

  @override
  String get rewarded_start_watch => 'Regarder la pub';

  @override
  String get runner_select_source => 'Sélectionner le runner';

  @override
  String get runner_source_all => 'Tous les runners';

  @override
  String runner_source_label(String name) {
    return 'Runner : $name';
  }

  @override
  String get runner_source_local => 'Local';

  @override
  String get runner_source_manager => 'Serveurs Bot Creator';

  @override
  String get runner_source_manager_unavailable =>
      'Connectez-vous à Bot Creator dans les paramètres pour charger les statistiques depuis les serveurs Bot Creator.';

  @override
  String get save => 'Enregistrer';

  @override
  String get scheduler_add_title => 'Ajouter un planning';

  @override
  String get scheduler_add_trigger => 'Ajouter un déclencheur';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Supprimer le planning « $label » ?';
  }

  @override
  String get scheduler_delete_title => 'Supprimer le planning';

  @override
  String get scheduler_edit_title => 'Modifier le planning';

  @override
  String get scheduler_empty => 'Aucun déclencheur planifié.';

  @override
  String get scheduler_every_minutes => 'Toutes les (minutes)';

  @override
  String get scheduler_invalid_minutes =>
      'Les minutes doivent être supérieures à 0.';

  @override
  String get scheduler_label_field => 'Libellé';

  @override
  String get scheduler_label_hint => 'Libellé d\'affichage optionnel';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Limite du planificateur atteinte ($limit).';
  }

  @override
  String get scheduler_no_workflows =>
      'Créez au moins un workflow avant d\'ajouter un planning.';

  @override
  String get scheduler_page_title => 'Planificateur';

  @override
  String scheduler_save_failed(String error) {
    return 'Échec de l\'enregistrement du planning : $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow : $workflow €¢ Toutes les $minutes min';
  }

  @override
  String get scheduler_tab => 'Planificateur';

  @override
  String get scheduler_tab_short => 'Planif';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Déclencheurs : $count$limit';
  }

  @override
  String get scoped_default_value => 'Valeur par défaut';

  @override
  String get scoped_default_value_hint => 'Optionnel';

  @override
  String scoped_delete_confirm(String key) {
    return 'Supprimer « $key » et toutes ses données runtime stockées ?';
  }

  @override
  String get scoped_delete_title => 'Supprimer la variable scopée';

  @override
  String get scoped_empty => 'Aucune variable scopée définie';

  @override
  String get scoped_empty_subtitle =>
      'Les variables scopées stockent une valeur par contexte Discord (utilisateur, serveur...). Elles sont peuplées par le bot à l\'exécution.';

  @override
  String get scoped_explore_runtime => 'Explorer les données runtime';

  @override
  String scoped_ref(String ref) {
    return 'Référence : $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legacy : $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Tout copier';

  @override
  String get scoped_runtime_empty =>
      'Aucune donnée runtime.\nCette clé sera peuplée par le bot à l\'exécution.';

  @override
  String get scoped_runtime_search => 'Rechercher par ID ou nom...';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Scope : $scope · $count contexte(s) trouvé(s)';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Données runtime — « $key »';
  }

  @override
  String get scoped_scope => 'Portée';

  @override
  String get scoped_scope_help =>
      'Le niveau d\'entité auquel la variable est stockée.';

  @override
  String get scoped_title => 'Variables scopées';

  @override
  String get scratch_add_block => 'Ajouter un bloc';

  @override
  String get scratch_bdfd_script => 'Script BDFD';

  @override
  String get scratch_block_entry_point => 'Point de départ (Déclencheur)';

  @override
  String get scratch_block_metadata => 'Métadonnées';

  @override
  String get scratch_block_required => 'Requis';

  @override
  String get scratch_blocks_tab => 'Blocs';

  @override
  String get scratch_custom_id_filter_desc =>
      'Ce workflow ne sera exécuté que si le Custom ID du bouton cliqué ou du modal soumis correspond exactement à l\'ID ci-dessus.';

  @override
  String get scratch_custom_id_filter_hint => 'ex : mon_bouton_id';

  @override
  String get scratch_custom_id_filter_label => 'Filtre Custom ID (optionnel)';

  @override
  String get scratch_dart_script => 'Script Dart';

  @override
  String get scratch_entry_event_trigger => 'Déclencheur d\'événement';

  @override
  String get scratch_entry_function => 'Fonction';

  @override
  String get scratch_entry_interaction => 'Commande Slash (/)';

  @override
  String get scratch_entry_message => 'Message Texte';

  @override
  String get scratch_entry_point_hint => 'Indice du point d\'entrée scratch';

  @override
  String get scratch_entry_point_label => 'Nom du point d\'entrée';

  @override
  String get scratch_entry_point_listen =>
      'Quand est-ce que cette commande se lance ?';

  @override
  String get scratch_event_category => 'Catégorie d\'événement';

  @override
  String get scratch_event_name => 'Nom de l\'événement';

  @override
  String get scratch_event_variables => 'Variables d\'événement';

  @override
  String get scratch_execution_mode => 'Comment est construite la commande ?';

  @override
  String get scratch_legacy_config => 'Configuration héritée';

  @override
  String get scratch_meta_advanced => 'Paramètres avancés';

  @override
  String get scratch_meta_desc_hint => 'Description de la commande';

  @override
  String get scratch_meta_name_hint => 'Nom de la commande';

  @override
  String get scratch_meta_type_label => 'Type de commande';

  @override
  String get scratch_meta_type_message => 'Commande message';

  @override
  String get scratch_meta_type_message_desc =>
      'Déclenchée depuis le menu contextuel message.';

  @override
  String get scratch_meta_type_prefix => 'Commande préfixe';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Déclenchée par un préfixe texte (ex : !help).';

  @override
  String get scratch_meta_type_slash => 'Commande slash';

  @override
  String get scratch_meta_type_slash_desc =>
      'Déclenchée en tapant / dans Discord.';

  @override
  String get scratch_meta_type_user => 'Commande utilisateur';

  @override
  String get scratch_meta_type_user_desc =>
      'Déclenchée depuis le menu contextuel utilisateur.';

  @override
  String get scratch_mode_bdfd => 'Code BDFD';

  @override
  String get scratch_mode_blocks => 'Visuel (Blocs)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => 'Réponse';

  @override
  String get scratch_response_components => 'Composants';

  @override
  String get scratch_response_edit => 'Modifier la réponse';

  @override
  String get scratch_trigger_tab => 'Déclencheur';

  @override
  String get scratch_wizard_actions_empty_desc =>
      'Ajoutez des blocs d\'actions ci-dessous pour configurer ce que fait votre bot.';

  @override
  String get scratch_wizard_actions_empty_title =>
      'Aucune action définie pour le moment.';

  @override
  String get scratch_wizard_config_button_instruction =>
      'Configurez l\'ID du bouton ou du modal qui déclenchera ce workflow.';

  @override
  String get scratch_wizard_folder_hint => 'ex : administration';

  @override
  String get scratch_wizard_folder_label => 'Dossier (optionnel)';

  @override
  String get scratch_wizard_save_details => 'Détails d\'enregistrement';

  @override
  String get scratch_wizard_step_actions => 'Étape 3 : Actions';

  @override
  String get scratch_wizard_step_config => 'Étape 2 : Configuration';

  @override
  String get scratch_wizard_step_save => 'Étape 4 : Enregistrement';

  @override
  String get scratch_wizard_step_trigger => 'Étape 1 : Déclencheur';

  @override
  String scratch_wizard_summary_actions_count(int count) {
    return '$count action(s) configurée(s)';
  }

  @override
  String get scratch_wizard_summary_title => 'Résumé du Workflow';

  @override
  String scratch_wizard_summary_trigger_button(String id) {
    return 'Clic de bouton / Modal (Custom ID : \'$id\')';
  }

  @override
  String scratch_wizard_summary_trigger_event(String event) {
    return 'Événement : $event';
  }

  @override
  String get scratch_wizard_summary_trigger_function =>
      'Fonction / Workflow Général';

  @override
  String get scratch_wizard_trigger_button_desc =>
      'Se déclenche lorsqu\'un utilisateur clique sur un bouton de message ou soumet un formulaire (modal).';

  @override
  String get scratch_wizard_trigger_button_title =>
      'Bouton ou Composant de message';

  @override
  String get scratch_wizard_trigger_event_desc =>
      'Se déclenche sur une action Discord spécifique (ex : nouveau membre rejoint, message supprimé, rôle modifié).';

  @override
  String get scratch_wizard_trigger_event_title => 'Événement Discord';

  @override
  String get scratch_wizard_trigger_function_desc =>
      'Exécute le workflow en tant que fonction pouvant être appelée par d\'autres déclencheurs.';

  @override
  String get scratch_wizard_trigger_function_title =>
      'Fonction ou Déclencheur manuel';

  @override
  String get scratch_wizard_trigger_instruction =>
      'Choisissez l\'événement qui déclenchera ce scénario (workflow) :';

  @override
  String get scratch_wizard_workflow_name_hint => 'ex : reponse_bouton';

  @override
  String get scratch_wizard_workflow_name_label => 'Nom du workflow *';

  @override
  String get scratch_workflow_add_argument => 'Ajouter un argument';

  @override
  String get scratch_workflow_arguments => 'Arguments (Variables)';

  @override
  String get scratch_workflow_metadata => 'Paramètres du workflow';

  @override
  String get scratch_workflow_name => 'Nom du workflow';

  @override
  String get scratch_workflow_type => 'Type de workflow';

  @override
  String get scratch_workflow_type_event => 'Événement';

  @override
  String get scratch_workflow_type_general => 'Général';

  @override
  String get serialization_export_base64_title =>
      'Exporter la commande en Base64';

  @override
  String get serialization_export_json_subtitle =>
      'Copier le JSON lisible dans le presse-papiers';

  @override
  String get serialization_export_json_title => 'Exporter la commande en JSON';

  @override
  String get serialization_import_desc =>
      'Collez un payload de commande (JSON ou Base64).';

  @override
  String get serialization_import_title => 'Importer une commande';

  @override
  String get serialization_imported => 'Commande importée dans l\'éditeur.';

  @override
  String get serialization_invalid_format =>
      'Format de payload de commande invalide.';

  @override
  String get serialization_invalid_structure =>
      'Structure de payload de commande invalide.';

  @override
  String get settings_account_connect_label =>
      'Se connecter à Bot Creator avec Discord';

  @override
  String get settings_account_connected_hint =>
      'Compte connecté. Vos bots et vos données sont synchronisés avec Bot Creator.';

  @override
  String get settings_account_disconnect_label => 'Se déconnecter';

  @override
  String get settings_account_disconnected_hint =>
      'Votre compte Bot Creator est créé automatiquement quand vous ajoutez un bot. Connectez-vous ensuite avec Discord pour récupérer vos bots sur cet appareil.';

  @override
  String get settings_account_status_connected => 'Compte connecté';

  @override
  String get settings_account_status_disconnected => 'Compte non connecté';

  @override
  String get mobile_account_required_title => 'Connexion';

  @override
  String get mobile_account_required_body =>
      'Connectez-vous avec Discord ou par e-mail.';

  @override
  String get mobile_account_required_feature_bots =>
      'Synchroniser et restaurer vos bots depuis le cloud';

  @override
  String get mobile_account_required_feature_hosted =>
      'Déployer et gérer des applications hébergées';

  @override
  String get mobile_account_required_feature_recovery =>
      'Tout récupérer après réinstallation ou sur un nouveau téléphone';

  @override
  String mobile_account_required_failed(String error) {
    return 'Échec de la connexion Discord : $error';
  }

  @override
  String get mobile_login_or_divider => 'ou';

  @override
  String get mobile_login_show_email => 'Connexion par e-mail';

  @override
  String get mobile_login_hide_email => 'Masquer la connexion e-mail';

  @override
  String get mobile_login_email_title => 'Connexion par e-mail';

  @override
  String get mobile_login_email_hint =>
      'Utilisez l\'e-mail et le mot de passe de votre compte.';

  @override
  String get mobile_login_email => 'E-mail';

  @override
  String get mobile_login_password => 'Mot de passe';

  @override
  String get mobile_login_submit => 'Se connecter';

  @override
  String get mobile_login_invalid_credentials =>
      'E-mail ou mot de passe invalide.';

  @override
  String mobile_login_failed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get settings_alternative_login_title => 'Connexion alternative';

  @override
  String get settings_alternative_login_desc =>
      'Ajoutez un e-mail et un mot de passe pour vous connecter sans Discord.';

  @override
  String settings_alternative_login_current_email(String email) {
    return 'E-mail actuel : $email';
  }

  @override
  String get settings_alternative_login_current_password =>
      'Mot de passe actuel';

  @override
  String get settings_alternative_login_confirm_password =>
      'Confirmer le mot de passe';

  @override
  String get settings_alternative_login_update =>
      'Mettre à jour les identifiants';

  @override
  String get settings_add_credentials => 'Enregistrer les identifiants';

  @override
  String get settings_alternative_login_missing_fields =>
      'L\'e-mail et le mot de passe sont requis.';

  @override
  String get settings_alternative_login_password_mismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get settings_credentials_saved => 'Connexion alternative enregistrée.';

  @override
  String get settings_ads_privacy_loading =>
      'Vérification des paramètres de confidentialité pub...';

  @override
  String get settings_ads_privacy_manage =>
      'Gérer les choix de confidentialité pub';

  @override
  String get settings_ads_privacy_not_required =>
      'Options de confidentialité pub non requises pour le moment';

  @override
  String get settings_ads_privacy_open_error =>
      'Impossible d\'ouvrir les options de confidentialité pub';

  @override
  String get settings_ads_privacy_opened =>
      'Options de confidentialité pub ouvertes';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_appearance_title => 'Apparence et langue';

  @override
  String get settings_auto_backup_check_loading =>
      'Vérification auto-sauvegarde...';

  @override
  String get settings_auto_backup_every_12h => 'Toutes les 12 h';

  @override
  String get settings_auto_backup_every_24h => 'Toutes les 24 h';

  @override
  String get settings_auto_backup_every_6h => 'Toutes les 6 h';

  @override
  String get settings_auto_backup_every_72h => 'Toutes les 72 h';

  @override
  String get settings_auto_backup_interval => 'Intervalle d\'auto-sauvegarde';

  @override
  String get settings_backup_now => 'Sauvegarder maintenant';

  @override
  String get settings_backup_restore_desc =>
      'Gérez la synchronisation de vos données avec Google Drive';

  @override
  String get settings_backup_restore_title => 'Sauvegarde et restauration';

  @override
  String get settings_builtin_help => 'Commande !help legacy intégrée';

  @override
  String get settings_builtin_help_subtitle =>
      'Fonctionnalité obligatoire avec toggle explicite. Désactivez-la pour ne garder qu\'un comportement d\'aide personnalisé.';

  @override
  String get settings_clear_logs => 'Effacer les logs';

  @override
  String get settings_cloud_hosting_enabled =>
      'Les bots mobile utilisent maintenant les serveurs Bot Creator.';

  @override
  String get settings_compatibility_desc =>
      'Vue rapide de la couverture fonctionnelle pour les utilisateurs venant de BDFD.';

  @override
  String get settings_compatibility_functions_category_components =>
      'Composants / Interactions';

  @override
  String get settings_compatibility_functions_category_control =>
      'Contrôle de flux';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Gardes et permissions';

  @override
  String get settings_compatibility_functions_category_http => 'Helpers HTTP';

  @override
  String get settings_compatibility_functions_category_json => 'Helpers JSON';

  @override
  String get settings_compatibility_functions_category_logging =>
      'Journalisation';

  @override
  String get settings_compatibility_functions_category_messages => 'Messages';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Placeholders runtime';

  @override
  String get settings_compatibility_functions_category_threads => 'Fils';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Variables scopees';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'Fonctions compatibles : $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'Total référence BDFD : $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Supportées sur Bot Creator : $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Exclusives Bot Creator : $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return 'Supportées sur les deux : $count';
  }

  @override
  String settings_compatibility_functions_count_missing(int count) {
    return 'Manquantes sur Bot Creator : $count';
  }

  @override
  String get settings_compatibility_functions_empty =>
      'Aucune fonction dans cette section.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'Les entrées BDFD uniquement correspondent aux fonctions de la liste BDFD fournie qui ne sont pas encore implémentées dans Bot Creator.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Vue diff entre l\'implémentation Bot Creator et la référence des fonctions BDFD.';

  @override
  String get settings_compatibility_functions_note =>
      'Cette page reflète l\'implémentation actuelle et évoluera au fil des mises à jour.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Rechercher une fonction (exemple : \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Supportées uniquement sur Bot Creator';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Les helpers de boucle sont actuellement spécifiques à Bot Creator.';

  @override
  String get settings_compatibility_functions_section_both =>
      'Supportées sur Bot Creator et BDFD';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Disponibles sur BDFD mais manquantes sur Bot Creator';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Fonctions actuellement implémentées et utilisables dans le mode BDFD de Bot Creator.';

  @override
  String get settings_compatibility_functions_title =>
      'Fonctions BDFD compatibles';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Couverture complète du catalogue de fonctions BDFD.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'Parité des fonctions BDScript';

  @override
  String get settings_compatibility_item_events_desc =>
      'Les événements courants sont couverts, certains restent limités en runtime.';

  @override
  String get settings_compatibility_item_events_title =>
      'Couverture des événements';

  @override
  String get settings_compatibility_item_runner_desc =>
      'Le runner distant est disponible, le multi-runner est en cours.';

  @override
  String get settings_compatibility_item_runner_title => 'Architecture runner';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Les variables dynamiques et helpers de template sont pris en charge.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Variables runtime et templates';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Les workflows visuels de commandes et de réponses sont disponibles.';

  @override
  String get settings_compatibility_item_workflows_title =>
      'Éditeur de workflows';

  @override
  String get settings_compatibility_note =>
      'Cet aperçu reste volontairement synthétique et évoluera par release.';

  @override
  String get settings_compatibility_open_functions =>
      'Voir les fonctions compatibles';

  @override
  String get settings_compatibility_status_missing => 'Absent';

  @override
  String get settings_compatibility_status_partial => 'Partiel';

  @override
  String get settings_compatibility_status_supported => 'Supporté';

  @override
  String get settings_compatibility_title => 'Aperçu compatibilité BDFD';

  @override
  String get settings_data_operations_title => 'Opérations de données';

  @override
  String get settings_debug_desc =>
      'Réinitialise les préférences locales ou relance l\'onboarding pour les tests.';

  @override
  String get settings_debug_premium_bypass => 'Bypass Premium';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Débloque toutes les fonctionnalités Premium sans abonnement (debug uniquement).';

  @override
  String get settings_debug_title => 'Outils de debug';

  @override
  String get settings_diagnostics_copied =>
      'Diagnostics copiés dans le presse-papiers';

  @override
  String get settings_diagnostics_copy_all => 'Copier tous les logs';

  @override
  String get settings_diagnostics_dialog_title => 'Diagnostics de démarrage';

  @override
  String get settings_diagnostics_empty =>
      'Aucun log d\'application disponible pour le moment.';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Affiche uniquement les logs de diagnostic de l\'application (hors logs bot).';

  @override
  String get settings_diagnostics_page_title => 'Logs de l\'application';

  @override
  String get settings_diagnostics_refresh => 'Actualiser les logs';

  @override
  String get settings_diagnostics_section_title => 'Diagnostics';

  @override
  String get settings_discord_rpc_authenticating =>
      'Authentification auprès de Discord...';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Code d\'autorisation en cache ; relancez pour terminer l\'échange du token';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Code d\'autorisation reçu';

  @override
  String get settings_discord_rpc_authorize => 'Autoriser';

  @override
  String get settings_discord_rpc_authorizing =>
      'En attente de l\'autorisation Discord...';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'URL du broker OAuth (avancée, optionnelle)';

  @override
  String get settings_discord_rpc_broker_required =>
      'Le Client ID suffit pour le flow public client ; l\'URL du broker et le client secret restent optionnels';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Cet identifiant est fixé dans Bot Creator et ne peut pas être modifié depuis les paramètres.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Le client ID Discord est requis';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Solution avancée optionnelle pour un flow confidentiel géré localement.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Client secret';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Client secret de l\'application Discord (optionnel)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Finaliser l\'autorisation';

  @override
  String get settings_discord_rpc_connect => 'Rafraîchir la présence';

  @override
  String get settings_discord_rpc_connected => 'Présence envoyée à Discord';

  @override
  String get settings_discord_rpc_connecting => 'Connexion à Discord...';

  @override
  String get settings_discord_rpc_desc =>
      'Publie l\'activité desktop de Bot Creator dans le client Discord local. Bot Creator utilise toujours l\'application Discord intégrée et envoie SET_ACTIVITY directement via l\'IPC local quand l\'option est activée.';

  @override
  String get settings_discord_rpc_disabled => 'Désactivé';

  @override
  String get settings_discord_rpc_disconnect => 'Fermer l\'IPC';

  @override
  String get settings_discord_rpc_disconnected => 'IPC fermé';

  @override
  String get settings_discord_rpc_enable => 'Activer Discord Rich Presence';

  @override
  String get settings_discord_rpc_enable_first =>
      'Activez Discord Rich Presence d\'abord';

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'Point IPC : $endpoint';
  }

  @override
  String get settings_discord_rpc_error => 'Erreur Discord RPC';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'Finalisation de l\'échange OAuth...';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'IPC Discord local connecté ; aucune requête OAuth HTTP envoyée pour l\'instant, authentification encore requise';

  @override
  String get settings_discord_rpc_ipc_open => 'IPC local déjà ouvert';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Dernière erreur : $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization => 'Autorisation requise';

  @override
  String get settings_discord_rpc_not_configured => 'Client ID requis';

  @override
  String get settings_discord_rpc_open_ipc => 'Ouvrir l\'IPC local';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence est réservé au desktop';

  @override
  String get settings_discord_rpc_save => 'Enregistrer';

  @override
  String get settings_discord_rpc_saved =>
      'Paramètres Discord Rich Presence enregistrés';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Le transport Discord n\'est pas encore pris en charge sur cette plateforme';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Utilisateur autorisé : $user';
  }

  @override
  String get settings_drive_connect => 'Connecter Google Drive';

  @override
  String get settings_drive_connect_loading => 'Connexion à Google Drive...';

  @override
  String get settings_drive_connected => 'Connecté à Google Drive';

  @override
  String get settings_drive_desc =>
      'Connectez votre compte Google Drive pour synchroniser vos données';

  @override
  String get settings_drive_disconnect => 'Déconnecter';

  @override
  String get settings_drive_disconnect_loading => 'Déconnexion en cours...';

  @override
  String get settings_drive_disconnected => 'Déconnecté de Google Drive';

  @override
  String get settings_drive_status_connected => 'Connecté';

  @override
  String get settings_drive_title => 'Connexion Google Drive';

  @override
  String get settings_enable_auto_backup => 'Activer l\'auto-sauvegarde';

  @override
  String get settings_enable_auto_backup_desc =>
      'Crée automatiquement des snapshots versionnés lorsque nécessaire.';

  @override
  String get settings_execution_mode_desc =>
      'Sur cette plateforme, Bot Creator n\'héberge jamais vos bots. Vous pouvez utiliser votre runner self-hosted ou exécuter les bots localement.';

  @override
  String get settings_execution_mode_local_active =>
      'Les bots démarrent maintenant en local. La configuration runner reste en mémoire et peut être réactivée à tout moment.';

  @override
  String get settings_execution_mode_no_runner =>
      'Aucun runner n\'est encore configuré. L\'application restera en local tant que vous n\'en ajoutez pas un.';

  @override
  String get settings_execution_mode_runner_priority =>
      'Le runner self-hosted est prioritaire. Si aucun runner n\'est configuré, l\'application repasse en local.';

  @override
  String get settings_execution_mode_title => 'Mode d\'exécution';

  @override
  String get settings_execution_mode_use_runner =>
      'Utiliser un runner self-hosted';

  @override
  String get settings_export => 'Exporter';

  @override
  String get settings_export_app_data => 'Exporter les données de l\'app';

  @override
  String get settings_export_loading => 'Export en cours...';

  @override
  String get settings_import => 'Importer';

  @override
  String get settings_import_app_data => 'Importer les données de l\'app';

  @override
  String get settings_import_loading => 'Import en cours...';

  @override
  String get settings_language_desc =>
      'Choisissez la langue utilisée par l\'application.';

  @override
  String get settings_language_system => 'Automatique (appareil)';

  @override
  String get settings_language_title => 'Langue';

  @override
  String get settings_language_updated => 'Langue mise à jour';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Dernière auto-sauvegarde : $date';
  }

  @override
  String get settings_last_auto_backup_never =>
      'Dernière auto-sauvegarde : jamais';

  @override
  String get settings_legacy_prefix => 'Préfixe des commandes legacy';

  @override
  String get settings_legacy_prefix_helper =>
      'Supporte les templates et variables étendues (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? ou ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Consultez la manière dont vos données sont traitées et stockées.';

  @override
  String get settings_legal_title => 'Légal';

  @override
  String get settings_local_hosting_enabled => 'Hébergement local activé';

  @override
  String get settings_logs_cleared => 'Logs de diagnostic effacés';

  @override
  String get settings_main_api_auth_failed =>
      'La session du serveur Bot Creator est invalide ou expirée';

  @override
  String get settings_main_api_check => 'Tester le serveur Bot Creator';

  @override
  String get settings_main_api_clear => 'Effacer';

  @override
  String get settings_main_api_cleared =>
      'Paramètres du serveur Bot Creator effacés';

  @override
  String get settings_main_api_connect_discord => 'Connecter le compte Discord';

  @override
  String get settings_main_api_connected => 'Serveur Bot Creator accessible ✓';

  @override
  String get settings_main_api_connected_discord => 'Compte Discord connecté';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Connecté en tant que $user';
  }

  @override
  String get settings_main_api_desc =>
      'Connectez Bot Creator aux serveurs Bot Creator puis connectez-vous avec Discord. Le secret client Discord doit rester côté backend.';

  @override
  String get settings_main_api_desktop_only =>
      'La connexion Discord via les serveurs Bot Creator est disponible uniquement sur desktop.';

  @override
  String get settings_main_api_disconnect => 'Déconnecter le compte';

  @override
  String get settings_main_api_not_configured =>
      'URL du serveur Bot Creator requise';

  @override
  String get settings_main_api_save => 'Enregistrer le serveur Bot Creator';

  @override
  String get settings_main_api_saved =>
      'Paramètres du serveur Bot Creator enregistrés';

  @override
  String get settings_main_api_session_connected => 'Session Discord active';

  @override
  String get settings_main_api_session_disconnected =>
      'Session Discord déconnectée';

  @override
  String get settings_main_api_session_expired => 'Session Discord expirée';

  @override
  String get settings_main_api_title => 'Serveur Bot Creator';

  @override
  String get settings_main_api_unreachable =>
      'Serveur Bot Creator inaccessible';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required =>
      'URL du serveur Bot Creator requise';

  @override
  String get settings_main_api_user_unknown => 'Utilisateur Discord';

  @override
  String get settings_manual_snapshot_label => 'Snapshot manuel';

  @override
  String get settings_member_badge => 'MEMBRE';

  @override
  String get settings_notifications_desc =>
      'Choisissez les types de notifications push que vous souhaitez recevoir.';

  @override
  String get settings_notifications_title => 'Notifications';

  @override
  String get settings_notifications_topic_billing => 'Facturation';

  @override
  String get settings_notifications_topic_billing_desc =>
      'Rappels de renouvellement d\'abonnement et confirmations de paiement.';

  @override
  String get settings_notifications_topic_botAlerts => 'Alertes de bot';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'Avertissements lorsque vos bots se déconnectent ou rencontrent des erreurs.';

  @override
  String get settings_notifications_topic_broadcast => 'Annonces';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Annonces importantes et actualités de Bot Creator.';

  @override
  String get settings_notifications_topic_updates => 'Mises à jour';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Nouvelles fonctionnalités, mises à jour et faits marquants.';

  @override
  String get settings_open_ad_inspector => 'Ouvrir l\'inspecteur de publicités';

  @override
  String get settings_oss_licenses => 'Licences Open Source';

  @override
  String get settings_owner_badge => 'PROPRIÉTAIRE';

  @override
  String get settings_owner_fallback => 'Propriétaire';

  @override
  String get settings_personal_owner_fallback => 'Utilisateur personnel';

  @override
  String get settings_personal_owner_id_label => 'ID Propriétaire : ';

  @override
  String get settings_personal_owner_label => 'Propriétaire : ';

  @override
  String get settings_personal_ownership => 'Propriété personnelle';

  @override
  String get settings_preferences_reset_done => 'Préférences réinitialisées';

  @override
  String get settings_privacy_policy => 'Politique de confidentialité';

  @override
  String get settings_raw_json_tile => 'Voir le JSON Brut (RAW JSON)';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'Relancer l\'onboarding';

  @override
  String get settings_replay_onboarding_desc =>
      'Réinitialise l\'onboarding et le relance immédiatement.';

  @override
  String get settings_reset_preferences => 'Réinitialiser les préférences';

  @override
  String get settings_reset_preferences_desc =>
      'Réinitialise le thème, la langue et la progression de l\'onboarding.';

  @override
  String get settings_restore_snapshot => 'Restaurer ce snapshot';

  @override
  String get settings_run_auto_backup_now => 'Lancer l\'auto-sauvegarde';

  @override
  String get settings_run_diagnostics => 'Lancer les diagnostics';

  @override
  String settings_runner_active(String url) {
    return 'Runner API actif : $url';
  }

  @override
  String get settings_runner_auth_failed => 'Le runner a refusé le jeton API';

  @override
  String get settings_runner_check => 'Tester la connexion';

  @override
  String get settings_runner_clear => 'Effacer';

  @override
  String get settings_runner_cleared => 'Paramètres du runner effacés';

  @override
  String get settings_runner_connected => 'Runner accessible ✔';

  @override
  String get settings_runner_connecting => 'Vérification de la connexion…';

  @override
  String get settings_runner_desc =>
      'Connecte l\'application à un Bot Creator Runner. Un runner distant doit rester sur un réseau de confiance et utiliser un jeton bearer.';

  @override
  String get settings_runner_use_remote => 'Utiliser un runner distant';

  @override
  String get settings_runner_use_remote_desc =>
      'Connectez-vous à un Bot Creator Runner distant. Laissez désactivé pour exécuter les bots localement sur cet appareil.';

  @override
  String get settings_runner_disable_temp =>
      'Désactiver temporairement le Runner';

  @override
  String get settings_runner_disable_temp_desc =>
      'Conserve la configuration du Runner mais force le mode local jusqu\'à réactivation.';

  @override
  String get settings_runner_disconnected => 'Runner déconnecté';

  @override
  String get settings_runner_not_connected => 'Non connecté';

  @override
  String get settings_runner_reenabled => 'Runner réactivé';

  @override
  String get settings_runner_save => 'Enregistrer';

  @override
  String get settings_runner_saved => 'Paramètres du runner enregistrés';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner temporairement désactivé (mode local actif)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner temporairement désactivé';

  @override
  String get settings_runner_title => 'Runner API';

  @override
  String get settings_runner_token_hint =>
      'Jeton bearer (optionnel si le runner reste en localhost)';

  @override
  String get settings_runner_token_label => 'Jeton API du runner';

  @override
  String get settings_runner_unreachable => 'Runner inaccessible';

  @override
  String get settings_runner_url_clear => 'Effacer';

  @override
  String get settings_runner_url_cleared => 'URL du runner effacée';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'Enregistrer l\'URL';

  @override
  String get settings_runner_url_saved => 'URL du runner enregistrée';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String get settings_embedded_runner_title => 'Runner JS embarqué';

  @override
  String settings_embedded_runner_download_progress(
    String received,
    String total,
  ) {
    return '$received sur $total';
  }

  @override
  String settings_embedded_runner_download_indeterminate(String received) {
    return '$received téléchargés';
  }

  @override
  String get settings_embedded_runner_restart => 'Redémarrer';

  @override
  String get settings_embedded_runner_restart_success =>
      'Runner JS embarqué redémarré';

  @override
  String get settings_embedded_runner_restart_failed =>
      'Échec du redémarrage du runner JS embarqué';

  @override
  String get settings_embedded_runner_redownload => 'Retélécharger';

  @override
  String get settings_embedded_runner_redownload_success =>
      'Runner JS embarqué retéléchargé';

  @override
  String get settings_embedded_runner_redownload_failed =>
      'Échec du retéléchargement du runner JS embarqué';

  @override
  String get settings_embedded_runner_open_log => 'Ouvrir le log';

  @override
  String settings_embedded_runner_binary_info(String size, String path) {
    return 'Binaire : $size · $path';
  }

  @override
  String get settings_embedded_runner_status_running => 'En cours d\'exécution';

  @override
  String get settings_embedded_runner_status_stopped => 'Non démarré';

  @override
  String get settings_embedded_runner_status_failed => 'Échec';

  @override
  String get settings_embedded_runner_status_downloading => 'Téléchargement…';

  @override
  String settings_embedded_runner_running_at(String url) {
    return 'Actif sur $url';
  }

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps : $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps dans ce snapshot';

  @override
  String get settings_snapshot_create_loading => 'Création du snapshot...';

  @override
  String settings_snapshot_created_at(String date) {
    return 'Créé le : $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot créé : $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'Suppression du snapshot...';

  @override
  String get settings_snapshot_deleted => 'Snapshot supprimé';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Fichiers : $count • Taille : $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID : $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Libellé : $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date • $count fichiers • $size';
  }

  @override
  String get settings_snapshot_no_metadata =>
      'Aucune métadonnée d\'application disponible.';

  @override
  String get settings_snapshot_preview_title => 'Aperçu du snapshot';

  @override
  String get settings_snapshot_restore_loading => 'Restauration du snapshot...';

  @override
  String get settings_snapshots_delete_all => 'Supprimer tous les snapshots';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Supprimer définitivement $count snapshot(s) ? Cette action est irréversible.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count snapshot(s) supprimé(s).';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'Suppression de tous les snapshots...';

  @override
  String get settings_snapshots_delete_all_title =>
      'Supprimer tous les snapshots';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Supprimer définitivement \"$label\" ? Cette action est irréversible.';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      'Choisissez le snapshot à supprimer (du plus ancien au plus récent).';

  @override
  String get settings_snapshots_delete_select_title => 'Supprimer un snapshot';

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Supprimer un snapshot sélectionné';

  @override
  String get settings_snapshots_empty =>
      'Aucun snapshot trouvé pour le moment.';

  @override
  String get settings_snapshots_refresh => 'Actualiser les snapshots';

  @override
  String get settings_snapshots_refresh_loading =>
      'Actualisation des snapshots...';

  @override
  String get settings_snapshots_title => 'Sauvegardes';

  @override
  String get settings_solo_pill => 'SOLO';

  @override
  String get settings_startup_mode_cloud_desc =>
      'Recommandé sur Android et iOS. Les logs, stats et démarrages passent par Bot Creator.';

  @override
  String get settings_startup_mode_desc =>
      'Choisissez si vos bots démarrent sur les serveurs Bot Creator ou en local sur cet appareil.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'Le mode local reste indisponible sur iOS.';

  @override
  String get settings_startup_mode_ios_warning =>
      'Sur iOS, le mode local n\'est pas pris en charge. Les bots utilisent toujours les serveurs Bot Creator.';

  @override
  String get settings_startup_mode_local_desc =>
      'Les bots démarrent maintenant en local sur cet appareil.';

  @override
  String get settings_startup_mode_local_warning =>
      'Le mode local est une option avancée réservée au debug ou à des besoins spécifiques. Pour un usage normal, laissez les serveurs Bot Creator actifs.';

  @override
  String get settings_startup_mode_title => 'Lancement des bots';

  @override
  String get settings_startup_mode_use_cloud =>
      'Utiliser les serveurs Bot Creator';

  @override
  String get settings_status_remove_confirm =>
      'Cette entrée de statut sera supprimée. Continuer ?';

  @override
  String get settings_tab => 'Paramètres';

  @override
  String get settings_team_id_label => 'ID de l\'équipe : ';

  @override
  String settings_team_members_label(int count) {
    return 'Membres de l\'équipe ($count)';
  }

  @override
  String get settings_team_name_label => 'Nom de l\'équipe : ';

  @override
  String get settings_team_owner_label => 'Chef d\'équipe';

  @override
  String get settings_team_ownership => 'Propriété de l\'équipe';

  @override
  String get settings_team_pill => 'ÉQUIPE';

  @override
  String get settings_theme_switch_dark => 'Passer en mode sombre';

  @override
  String get settings_theme_switch_light => 'Passer en mode clair';

  @override
  String get settings_version_title => 'Version';

  @override
  String get settings_view_startup_logs => 'Voir les logs de démarrage';

  @override
  String get startup_copy_diagnostics => 'Copier les diagnostics';

  @override
  String get startup_diagnostics_copied =>
      'Diagnostics copiés dans le presse-papiers';

  @override
  String get startup_error_title => 'Erreur de démarrage';

  @override
  String get startup_failed_message =>
      'Bot Creator n\'a pas pu démarrer sur cet appareil.';

  @override
  String get startup_refresh_diagnostics => 'Actualiser les diagnostics';

  @override
  String get subscription_active_annual => 'Premium — Annuel';

  @override
  String get subscription_active_label => 'Offre active :';

  @override
  String get subscription_active_monthly => 'Premium — Mensuel';

  @override
  String get subscription_annual_title => 'Annuel';

  @override
  String get subscription_benefit_fast_start =>
      'Bots démarrent instantanément, sans pop-up';

  @override
  String get subscription_benefit_no_ads =>
      'Aucune pub dans toute l\'application';

  @override
  String get subscription_benefit_support =>
      'Soutenez le développement indépendant';

  @override
  String get subscription_error =>
      'L\'achat n\'a pas pu être finalisé. Veuillez réessayer.';

  @override
  String get subscription_error_product_unavailable =>
      'Cette offre est actuellement indisponible. Veuillez réessayer plus tard.';

  @override
  String get subscription_error_purchase_start_failed =>
      'L\'achat n\'a pas pu démarrer. Veuillez réessayer.';

  @override
  String get subscription_error_store_unavailable =>
      'L\'App Store est temporairement indisponible. Veuillez réessayer dans un instant.';

  @override
  String get subscription_feature_analytics_desc =>
      'Accédez au taux d\'erreur, aux percentiles de latence et aux insights de locale.';

  @override
  String get subscription_feature_analytics_title => 'Analytique avancée';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Redémarre automatiquement le bot quand un redémarrage complet est requis.';

  @override
  String get subscription_feature_auto_restart_title =>
      'Redémarrage automatique';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Répartit la charge des gros bots entre plusieurs shards.';

  @override
  String get subscription_feature_auto_sharding_title => 'Sharding automatique';

  @override
  String get subscription_feature_coming_soon => 'Bientôt disponible';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Enregistre et rejoue les actions de commande étape par étape.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Replay visuel de debug';

  @override
  String get subscription_feature_instant_start_desc =>
      'Lance les bots immédiatement sans interruption publicitaire.';

  @override
  String get subscription_feature_hosted_apps_title => 'Applications hébergées';

  @override
  String get subscription_feature_hosted_apps_desc =>
      'Déployez des conteneurs Docker avec un hébergement illimité — sans publicité.';

  @override
  String get subscription_feature_instant_start_title => 'Démarrage instantané';

  @override
  String get subscription_feature_lavalink_desc =>
      'Jouez de la musique et de l\'audio dans les salons vocaux Discord avec Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Module musique & audio';

  @override
  String get subscription_feature_no_ads_desc =>
      'Supprime toutes les insertions publicitaires dans l\'application.';

  @override
  String get subscription_feature_no_ads_title => 'Sans publicité';

  @override
  String get subscription_feature_scheduler_desc =>
      'Exécute des workflows automatiquement toutes les X minutes (jusqu\'à 10 actifs).';

  @override
  String get subscription_feature_scheduler_title => 'Déclencheurs planifiés';

  @override
  String get subscription_feature_webhooks_desc =>
      'Crée des endpoints webhook sécurisés et route les appels vers les workflows.';

  @override
  String get subscription_feature_webhooks_title => 'Webhooks entrants';

  @override
  String get subscription_manage => 'Gérer l\'abonnement';

  @override
  String get subscriptions_hub_title => 'Abonnements';

  @override
  String get subscriptions_hub_subtitle =>
      'Consultez et gérez vos offres Bot Premium et applications hébergées.';

  @override
  String get subscriptions_hub_open_settings => 'Abonnements et facturation';

  @override
  String get subscriptions_hub_bot_premium_section => 'Bot Premium';

  @override
  String get subscriptions_hub_bot_premium_desc =>
      'Supprimez les publicités et débloquez les fonctionnalités premium pour vos bots Discord.';

  @override
  String get subscriptions_hub_hosted_section => 'Applications hébergées';

  @override
  String get subscriptions_hub_hosted_desc =>
      'Exécutez des conteneurs Docker dans le cloud sans regarder de publicités.';

  @override
  String get subscriptions_hub_status_active => 'Actif';

  @override
  String get subscriptions_hub_status_inactive => 'Non abonné';

  @override
  String get subscriptions_hub_subscribe => 'S\'abonner';

  @override
  String get subscriptions_hub_summary_both =>
      'Bot Premium et applications hébergées actifs';

  @override
  String get subscriptions_hub_summary_bot_only => 'Bot Premium actif';

  @override
  String get subscriptions_hub_summary_hosted_only =>
      'Applications hébergées actives';

  @override
  String get subscriptions_hub_summary_none => 'Aucun abonnement actif';

  @override
  String subscriptions_hub_expires_at(String date, String time) {
    return 'Renouvelé jusqu\'au $date à $time';
  }

  @override
  String get subscription_upgrade_annual => 'Passer à l\'abonnement annuel';

  @override
  String get subscription_upgrade_two_apps => 'Passer à 2 conteneurs';

  @override
  String get subscription_manage_cancel_hint =>
      'Pour annuler ou modifier la facturation, utilisez Gérer l\'abonnement — cela ouvre l\'App Store ou Google Play.';

  @override
  String get subscription_monthly_title => 'Mensuel';

  @override
  String get subscription_not_available_on_platform =>
      'Les abonnements sont actuellement disponibles uniquement sur mobile.';

  @override
  String get subscription_per_month => 'par mois';

  @override
  String get subscription_per_year => 'par an';

  @override
  String get subscription_plan_desc =>
      'Supprime les pubs et accède à toutes les fonctionnalités premium actuelles et à venir.';

  @override
  String get subscription_plan_label => 'Premium Basique';

  @override
  String get subscription_privacy => 'Politique de confidentialité';

  @override
  String get subscription_restore => 'Restaurer les achats';

  @override
  String get subscription_restore_not_found => 'Aucun abonnement actif trouvé.';

  @override
  String get subscription_restored => 'Abonnement restauré avec succès !';

  @override
  String subscription_save_badge(int percent) {
    return '-$percent%';
  }

  @override
  String get subscription_subtitle =>
      'Choisissez une offre pour débloquer toutes les fonctionnalités premium.';

  @override
  String get subscription_success =>
      'Bienvenue dans Premium ! Toutes les publicités ont été supprimées.';

  @override
  String get subscription_terms => 'Conditions d\'utilisation';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform =>
      'Non disponible sur cette plateforme.';

  @override
  String get support_card_desc =>
      'Une question, un bug, une suggestion ? Venez discuter avec l\'équipe et la communauté.';

  @override
  String get support_card_title => 'Support & Communauté';

  @override
  String get support_discord_badge => 'Support officiel';

  @override
  String get support_join_discord => 'Rejoindre le serveur Discord';

  @override
  String get template_fun_description =>
      'Pile ou face, sondages et boule magique.';

  @override
  String get template_fun_name => 'Bot fun';

  @override
  String template_gallery_already_exists(String name) {
    return 'La commande \"$name\" existe déjà et a été ignorée.';
  }

  @override
  String get template_gallery_apply => 'Utiliser ce template';

  @override
  String template_gallery_apply_error(String error) {
    return 'Impossible d\'appliquer le template : $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return '$count commande(s) et $wCount workflow(s) ajoutés depuis le template.';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count commande(s)';
  }

  @override
  String get template_gallery_empty => 'Aucun template disponible.';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Rien à supprimer pour $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Voulez-vous vraiment supprimer toutes les commandes et workflows de ce modèle ?';

  @override
  String get template_gallery_remove_title => 'Supprimer le modèle';

  @override
  String get template_gallery_removed =>
      'Commandes et workflows du modèle supprimés.';

  @override
  String get template_gallery_subtitle =>
      'Démarrez rapidement votre bot avec un template prêt à l\'emploi.';

  @override
  String get template_gallery_sync_warning =>
      'Commandes sauvegardées localement. Démarrez votre bot pour les enregistrer sur Discord.';

  @override
  String get template_gallery_title => 'Modèles';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count workflow(s)';
  }

  @override
  String get template_moderation_description =>
      'Bannir, expulser, rendre muet et supprimer des messages.';

  @override
  String get template_moderation_name => 'Bot de modération';

  @override
  String get template_utility_description =>
      'Ping, affichage d\'avatar et commande say.';

  @override
  String get template_utility_name => 'Bot utilitaire';

  @override
  String get template_welcome_description =>
      'Accueillez les nouveaux membres, dites bonjour et affichez les infos du serveur.';

  @override
  String get template_welcome_name => 'Bot d\'accueil';

  @override
  String unit_day(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String unit_hour(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count heures',
      one: '1 heure',
      zero: '0 heure',
    );
    return '$_temp0';
  }

  @override
  String unit_minute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes',
      one: '1 minute',
      zero: '0 minute',
    );
    return '$_temp0';
  }

  @override
  String unit_month(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mois',
      one: '1 mois',
      zero: '0 mois',
    );
    return '$_temp0';
  }

  @override
  String get validation_awaited_callback_format =>
      'Le callback attendu doit utiliser \$awaitedCommand[name;filter] ou \$awaitedCommandError[name].';

  @override
  String validation_awaited_callback_length(int max) {
    return 'Le déclencheur de callback attendu doit contenir au maximum $max caractères';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Les callbacks attendus nécessitent une commande à préfixe locale uniquement.';

  @override
  String get validation_command_name_invalid_chars =>
      'Les noms slash doivent contenir 1-32 caractères en minuscules. Autorisés : lettres, chiffres, tirets, underscores et apostrophes.';

  @override
  String validation_command_name_length(int max) {
    return 'Le nom de commande doit contenir au maximum $max caractères';
  }

  @override
  String get validation_command_name_must_be_lowercase =>
      'Les noms slash doivent utiliser des minuscules lorsqu\'une variante minuscule existe.';

  @override
  String validation_command_payload_too_large(int current, int max) {
    return 'Cette commande slash dépasse la limite Discord de $max caractères ($current utilisés). Raccourcissez noms, descriptions, options ou choix.';
  }

  @override
  String get validation_command_name_no_ampersand =>
      'Le nom de commande ne peut pas commencer par une esperluette';

  @override
  String get validation_command_name_no_at =>
      'Le nom de commande ne peut pas commencer par un arobase';

  @override
  String get validation_command_name_no_exclamation =>
      'Le nom de commande ne peut pas commencer par un point d\'exclamation';

  @override
  String get validation_command_name_no_hash =>
      'Le nom de commande ne peut pas commencer par un dièse';

  @override
  String get validation_command_name_no_percent =>
      'Le nom de commande ne peut pas commencer par un signe pourcent';

  @override
  String get validation_command_name_no_slash =>
      'Le nom de commande ne peut pas commencer par un slash';

  @override
  String get validation_command_name_no_spaces =>
      'Le nom de commande ne peut pas contenir d\'espaces';

  @override
  String get validation_command_name_no_underscore =>
      'Le nom de commande ne peut pas commencer par un underscore';

  @override
  String get validation_command_name_required =>
      'Veuillez entrer un nom de commande';

  @override
  String get validation_interaction_no_response =>
      'Les commandes d\'interaction doivent inclure au moins une action de réponse (Répondre avec un message, Composant V2 ou Modal).';

  @override
  String get validation_interaction_no_response_short =>
      'Aucune action de réponse';

  @override
  String get validation_invalid_permissions =>
      'Champ de bits de permissions par défaut invalide. Utilisez un entier positif ou laissez vide.';

  @override
  String get validation_legacy_chat_input_only =>
      'Le mode préfixe est disponible uniquement pour les commandes de saisie.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Le mode legacy-only ne peut être utilisé que pour les nouvelles commandes ou les commandes locales existantes.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Les commandes locales uniquement nécessitent que le mode préfixe soit activé.';

  @override
  String get validation_modal_not_legacy =>
      'Les réponses modales ne sont pas supportées en mode commande legacy.';

  @override
  String get validation_option_description_required =>
      'La description de l\'option est requise.';

  @override
  String get validation_option_group_only_subcommands =>
      'Les groupes de sous-commandes ne peuvent contenir que des sous-commandes.';

  @override
  String get validation_option_group_top_level_only =>
      'Les groupes de sous-commandes ne peuvent être qu\'au premier niveau.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'Les sous-commandes et groupes ne peuvent pas avoir de choix.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'Les sous-commandes et groupes ne peuvent pas avoir de valeurs min/max.';

  @override
  String get validation_option_hierarchy_not_required =>
      'Les sous-commandes et groupes ne peuvent pas être marqués comme requis.';

  @override
  String get validation_option_leaf_no_nested =>
      'Les options feuilles ne peuvent pas avoir d\'options imbriquées.';

  @override
  String get validation_option_max_entries =>
      'Chaque niveau d\'option prend en charge au maximum 25 entrées.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Le nom de l\'option $name est déjà utilisé à ce niveau.';
  }

  @override
  String get validation_option_name_must_be_lowercase =>
      'Les noms d\'option doivent utiliser des minuscules lorsqu\'une variante minuscule existe.';

  @override
  String get validation_option_required_before_optional =>
      'Les options requises doivent être listées avant les options facultatives.';

  @override
  String get validation_option_name_required =>
      'Le nom de l\'option est requis.';

  @override
  String get validation_option_no_mix_top_level =>
      'Les options de premier niveau ne peuvent pas mélanger sous-commandes/groupes et options feuilles (chaîne, nombre, etc.).';

  @override
  String get validation_option_subcommand_depth =>
      'Les sous-commandes ne peuvent pas être imbriquées à plus de 2 niveaux de profondeur.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Les sous-commandes ne peuvent pas contenir d\'autres sous-commandes ou groupes.';

  @override
  String get variable_autocomplete_numeric_title =>
      'Suggestions numériques dynamiques';

  @override
  String get variable_autocomplete_title =>
      'Variables disponibles — appuyez pour insérer';

  @override
  String get variable_category_author => 'Auteur';

  @override
  String get variable_category_bot => 'Bot';

  @override
  String get variable_category_channel => 'Salon';

  @override
  String get variable_category_context => 'Contexte';

  @override
  String get variable_category_functions => 'Fonctions';

  @override
  String get variable_category_guild => 'Serveur';

  @override
  String get variable_category_interaction => 'Interaction';

  @override
  String get variable_category_member => 'Membre';

  @override
  String get variable_category_message => 'Message';

  @override
  String get variable_category_other => 'Autre';

  @override
  String get variable_category_temp => 'Temporaire';

  @override
  String get variable_category_user => 'Utilisateur';

  @override
  String get webhooks_actions => 'Actions';

  @override
  String get webhooks_add_action => 'Ajouter un webhook';

  @override
  String get webhooks_add_title => 'Ajouter un webhook entrant';

  @override
  String get webhooks_copied => 'URL complète du webhook copiée.';

  @override
  String get webhooks_copy_path => 'Copier le chemin';

  @override
  String get webhooks_copy_secret => 'Copier le secret';

  @override
  String get webhooks_copy_url => 'Copier l\'URL';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooks : $count$limit';
  }

  @override
  String webhooks_delete_confirm(String label) {
    return 'Supprimer « $label » ? Cette action est irréversible.';
  }

  @override
  String get webhooks_delete_confirm_no_label =>
      'Cette action est irréversible.';

  @override
  String get webhooks_delete_title => 'Supprimer le webhook entrant ?';

  @override
  String get webhooks_edit_title => 'Modifier le webhook entrant';

  @override
  String get webhooks_empty => 'Aucun webhook entrant.';

  @override
  String get webhooks_generate => 'Générer';

  @override
  String get webhooks_invalid_runner_url => 'L\'URL du Runner est invalide.';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Limite de webhooks entrants atteinte ($limit).';
  }

  @override
  String get webhooks_missing_data =>
      'Le chemin ou le secret du webhook est manquant.';

  @override
  String get webhooks_no_workflows =>
      'Créez au moins un workflow avant d\'ajouter un webhook entrant.';

  @override
  String get webhooks_page_title => 'Webhooks entrants';

  @override
  String get webhooks_path_copied => 'Chemin copié.';

  @override
  String get webhooks_path_exists =>
      'Ce chemin existe déjà. Choisissez-en un autre.';

  @override
  String get webhooks_path_hint => 'orders/new';

  @override
  String get webhooks_path_label => 'Chemin';

  @override
  String get webhooks_runner_url_required =>
      'Configurez d\'abord une URL Runner pour copier l\'URL complète du webhook.';

  @override
  String webhooks_save_failed(String error) {
    return 'Échec de l\'enregistrement du webhook entrant : $error';
  }

  @override
  String get webhooks_secret_copied => 'Secret copié.';

  @override
  String get webhooks_secret_label => 'Secret du webhook';

  @override
  String get webhooks_target_label => 'Workflow cible';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Workflow : $workflow';
  }

  @override
  String get wizard_advanced_trigger => 'Paramètres de déclenchement avancés';

  @override
  String get wizard_apply_quick_start =>
      'Appliquer le démarrage rapide au brouillon';

  @override
  String get wizard_bdfd_mode_enabled => 'Mode script BDFD activé';

  @override
  String get wizard_code_advanced => 'Code / Avancé';

  @override
  String get wizard_command_body => 'Corps de la commande';

  @override
  String get wizard_create_command => 'Créer la commande';

  @override
  String get wizard_dart_mode_enabled => 'Mode script Dart activé';

  @override
  String get wizard_edit_reply => 'Modifier les détails de la réponse';

  @override
  String get wizard_legacy_options_subtitle =>
      'Options de commande legacy et comportement local uniquement';

  @override
  String get wizard_quick_start_applied =>
      'Démarrage rapide appliqué au brouillon de commande.';

  @override
  String get wizard_quick_start_subtitle =>
      'Utilisez le constructeur simple legacy comme point de départ, puis appliquez-le au brouillon partagé.';

  @override
  String get wizard_quick_starts => 'Démarrages rapides';

  @override
  String get wizard_reply_summary => 'Résumé de la réponse';

  @override
  String get wizard_save_command => 'Enregistrer la commande';

  @override
  String get wizard_step_actions => 'Actions';

  @override
  String get wizard_step_infos => 'Infos';

  @override
  String get wizard_step_reply => 'Réponse';

  @override
  String get wizard_step_review => 'Vérification';

  @override
  String get wizard_step_trigger_inputs => 'Déclencheur et entrées';

  @override
  String get wizard_visual_mode_enabled => 'Mode workflow visuel activé';

  @override
  String get workflow_argument_hint =>
      'Argument du workflow (accessible via \$arg)';

  @override
  String get workflow_arguments_section => 'Arguments du workflow';

  @override
  String get workflow_auto_defer => 'Différé auto';

  @override
  String get workflow_auto_defer_actions => 'Différé auto si actions';

  @override
  String get workflow_bdfd_editor_desc =>
      'Écrivez le code BDFD complet pour cette réponse workflow. Les diagnostics s\'affichent en direct.';

  @override
  String get workflow_bdfd_editor_title => 'Éditeur de script BDFD';

  @override
  String get workflow_condition_off => 'Condition désactivée';

  @override
  String get workflow_condition_off_upper => 'Condition DÉSACTIVÉE';

  @override
  String get workflow_condition_on => 'Condition activée';

  @override
  String get workflow_condition_on_upper => 'Condition ACTIVÉE';

  @override
  String get workflow_dart_editor_desc =>
      'Écrivez le code Dart complet pour cette réponse workflow. Les diagnostics s\'affichent en direct.';

  @override
  String get workflow_dart_editor_title => 'Éditeur de script Dart';

  @override
  String workflow_edit_call_args(int count) {
    return 'Modifier les arguments d\'appel ($count)';
  }

  @override
  String get workflow_entry_point => 'Point d\'entrée';

  @override
  String get workflow_entry_point_helper =>
      'Par défaut, le point d\'entrée du workflow est utilisé';

  @override
  String get workflow_entry_point_optional => 'Point d\'entrée (optionnel)';

  @override
  String get workflow_hint_name => 'ex. handle_form_submit';

  @override
  String get workflow_manual => 'Manuel';

  @override
  String get workflow_mode_bdfd => 'Script BDFD';

  @override
  String get workflow_mode_bdfd_note =>
      'Écrivez l\'intégralité de votre workflow sous forme de script BDFD. Le script est compilé et validé en temps réel.';

  @override
  String get workflow_mode_dart => 'Dart Direct';

  @override
  String get workflow_mode_dart_note =>
      'Écrivez votre workflow en Dart. Les diagnostics sont mis à jour pendant l\'édition pour détecter rapidement les erreurs.';

  @override
  String get workflow_mode_desc =>
      'Choisissez entre un éditeur visuel d\'actions ou un éditeur de script BDFD complet.';

  @override
  String get workflow_mode_title => 'Mode du workflow';

  @override
  String get workflow_mode_visual => 'Visuel';

  @override
  String get workflow_mode_visual_note =>
      'Construisez votre workflow visuellement en ajoutant des actions individuelles avec l\'éditeur de cartes.';

  @override
  String get workflow_no_auto_defer => 'Pas de différé auto';

  @override
  String get workflow_no_workflow_note =>
      'Note : Si aucun workflow n\'est sélectionné, la soumission de ce modal ne fera rien.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'À la soumission, le workflow \"$name\" sera exécuté (entrée : $entry, args : $args).';
  }

  @override
  String get workflow_root_json_error => 'La racine doit être un objet JSON';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" enregistré ($count action(s)).';
  }

  @override
  String get workflow_set_call_args => 'Définir les arguments d\'appel';

  @override
  String get workflow_visibility_ephemeral => 'Éphémère';

  @override
  String get workflow_visibility_public => 'Public';

  @override
  String get workflows_add_arg => 'Ajouter un argument';

  @override
  String get workflows_arg_default => 'Valeur par défaut';

  @override
  String get workflows_arg_hint =>
      'Les arguments deviennent des variables runtime sous la forme ((arg.name)) et ((workflow.arg.name)).';

  @override
  String get workflows_arg_name => 'Nom';

  @override
  String get workflows_arg_required_short => 'Req';

  @override
  String get workflows_arguments => 'Arguments';

  @override
  String get workflows_continue => 'Continuer';

  @override
  String get workflows_copy_done_base64 => 'Workflows copiés en Base64.';

  @override
  String get workflows_copy_done_json => 'Workflows copiés en JSON.';

  @override
  String get workflows_copy_none => 'Aucun workflow à copier.';

  @override
  String get workflows_create => 'Créer un workflow';

  @override
  String workflows_delete_confirm(String name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get workflows_delete_title => 'Supprimer le workflow';

  @override
  String get workflows_docs_tooltip => 'Ouvrir le centre de documentation';

  @override
  String get workflows_edit => 'Modifier le workflow';

  @override
  String get workflows_empty => 'Aucun workflow pour le moment';

  @override
  String get workflows_entry_point => 'Point d\'entrée par défaut';

  @override
  String get workflows_entry_point_hint =>
      'Utilisé si l\'appelant ne le remplace pas';

  @override
  String get workflows_event_available_vars => 'Variables disponibles';

  @override
  String get workflows_event_category => 'Categorie d\'event';

  @override
  String get workflows_event_category_channels => 'Salons';

  @override
  String get workflows_event_category_invites => 'Invitations';

  @override
  String get workflows_event_category_members => 'Membres';

  @override
  String get workflows_event_category_messages => 'Messages';

  @override
  String get workflows_event_channel_update => 'Mise à jour du salon';

  @override
  String get workflows_event_channel_update_desc =>
      'Declenche quand un salon est mis a jour.';

  @override
  String get workflows_event_hint =>
      'Choisissez l\'event Discord qui doit declencher ce workflow.';

  @override
  String get workflows_event_invite_create => 'Création d\'invitation';

  @override
  String get workflows_event_invite_create_desc =>
      'Declenche quand une invitation est creee.';

  @override
  String get workflows_event_member_join => 'Arrivée d\'un membre';

  @override
  String get workflows_event_member_join_desc =>
      'Declenche quand un membre rejoint le serveur.';

  @override
  String get workflows_event_member_remove => 'Départ d\'un membre';

  @override
  String get workflows_event_member_remove_desc =>
      'Declenche quand un membre quitte le serveur ou en est retire.';

  @override
  String get workflows_event_message_create => 'Création de message';

  @override
  String get workflows_event_message_create_desc =>
      'Declenche quand un nouveau message est cree.';

  @override
  String get workflows_event_message_delete => 'Suppression de message';

  @override
  String get workflows_event_message_delete_desc =>
      'Declenche quand un message est supprime.';

  @override
  String get workflows_event_message_update => 'Modification de message';

  @override
  String get workflows_event_message_update_desc =>
      'Declenche quand un message existant est modifie.';

  @override
  String workflows_event_preview(String event) {
    return 'Listen for : $event';
  }

  @override
  String get workflows_event_section => 'Workflows d\'event';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count action(s) €¢ Listen for : $event';
  }

  @override
  String get workflows_export_base64 => 'Copier en Base64';

  @override
  String get workflows_export_base64_desc => 'Pratique pour partage compact.';

  @override
  String get workflows_export_json => 'Copier en JSON';

  @override
  String get workflows_export_json_desc => 'Lisible et modifiable facilement.';

  @override
  String get workflows_export_tooltip => 'Copier des workflows';

  @override
  String get workflows_folder_hint => 'Nom du dossier (optionnel)';

  @override
  String get workflows_folder_label => 'Dossier';

  @override
  String get workflows_general_section => 'Workflows generaux';

  @override
  String get workflows_import_action => 'Importer';

  @override
  String get workflows_import_desc =>
      'Colle un payload JSON ou Base64 (JSON) exporté depuis Bot Creator.';

  @override
  String workflows_import_done(int count) {
    return '$count workflow(s) importé(s).';
  }

  @override
  String get workflows_import_empty => 'Aucune donnée à importer.';

  @override
  String get workflows_import_input_hint => 'Colle ici le JSON ou le Base64...';

  @override
  String get workflows_import_invalid_format =>
      'Format invalide. Utilise JSON ou Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'Aucun workflow valide trouvé.';

  @override
  String get workflows_import_overwrite => 'Remplacer si le nom existe';

  @override
  String get workflows_import_title => 'Importer des workflows';

  @override
  String get workflows_import_tooltip => 'Importer des workflows';

  @override
  String get workflows_js_event_available_context_copy_hint =>
      'Appuyez pour copier dans votre script';

  @override
  String workflows_js_event_available_context_copied(String name) {
    return '$name copié';
  }

  @override
  String get workflows_js_event_available_context_sparse_note =>
      'Le premier argument de cet événement n’est pas lié en tant que message/interaction/member/channel/guild. Utilisez client et vos variables/db, ou consultez la doc Discord.js pour la charge utile complète.';

  @override
  String get workflows_js_event_available_context_subtitle =>
      'Ces globales sont injectées dans votre script pour cet événement. Utilisez les propriétés discord.js (ex. message.author.username), pas ((message.content)).';

  @override
  String get workflows_listen_for => 'Écouter';

  @override
  String get workflows_move_to_folder => 'Déplacer dans un dossier';

  @override
  String get workflows_name => 'Nom du workflow';

  @override
  String get workflows_new_folder_hint => 'Nom du nouveau dossier';

  @override
  String get workflows_no_match =>
      'Aucun workflow ne correspond aux filtres actuels.';

  @override
  String get workflows_no_matches =>
      'Aucun workflow ne correspond aux filtres.';

  @override
  String get workflows_remove_from_folder => 'Retirer du dossier';

  @override
  String get workflows_search_hint => 'Rechercher des workflows...';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count action(s) €¢ entrée : $entry €¢ args : $args';
  }

  @override
  String get workflows_tab => 'Workflows';

  @override
  String get workflows_tab_short => 'Flux';

  @override
  String get workflows_title => 'Workflows';

  @override
  String get workflows_type_badge_event => 'Événement';

  @override
  String get workflows_type_badge_general => 'Général';

  @override
  String get workflows_type_event => 'Workflow d\'event';

  @override
  String get workflows_type_event_desc =>
      'Se declenche automatiquement quand Discord emet un event.';

  @override
  String get workflows_type_general => 'Workflow general';

  @override
  String get workflows_type_general_desc =>
      'Logique reutilisable appelee depuis les commandes, boutons, modals ou autres workflows.';

  @override
  String get workflows_type_title => 'Type de workflow';

  @override
  String get settings_sync_title => 'Synchronisation';

  @override
  String get settings_sync_force_title =>
      'Forcer la synchronisation des commandes';

  @override
  String get settings_sync_force_desc =>
      'Supprime toutes les commandes slash de Discord qui ne sont pas définies localement dans Bot Creator.';

  @override
  String get settings_sync_force_button => 'Synchroniser avec Discord';

  @override
  String get settings_sync_force_dialog_title => 'Forcer la synchronisation';

  @override
  String get settings_sync_force_dialog_desc =>
      'Cela supprimera toutes les commandes slash sur Discord qui ne sont pas définies localement dans Bot Creator. Êtes-vous sûr de vouloir continuer ?';

  @override
  String get settings_sync_force_dialog_confirm => 'Forcer la synchro';

  @override
  String settings_sync_force_success(Object count) {
    return 'Synchronisation forcée réussie. $count commande(s) obsolète(s)/non suivies supprimée(s) de Discord.';
  }

  @override
  String settings_sync_force_error(Object error) {
    return 'Échec de la synchronisation forcée : $error';
  }

  @override
  String get settings_runtime_engine_switch_dialog_title =>
      'Changer le moteur d\'exécution ?';

  @override
  String get settings_runtime_engine_switch_dialog_desc =>
      'Cette action est destructive.\n\n• Votre configuration est sauvegardée dans le cloud avant toute suppression locale.\n• Le changement ne prendra effet qu\'après le redémarrage du bot.\n• Toutes les commandes, workflows et triggers planifiés locaux seront supprimés.\n• Toutes les commandes enregistrées sur Discord seront également supprimées.\n\nVous pourrez tout récupérer depuis l\'Historique des versions (restauration locale automatique).';

  @override
  String get settings_runtime_engine_switch_dialog_confirm =>
      'Changer le moteur';

  @override
  String get settings_runtime_engine_switch_success =>
      'Moteur d\'exécution mis à jour. Redémarrez le bot quand vous êtes prêt.';

  @override
  String settings_runtime_engine_switch_error(String error) {
    return 'Échec du changement de moteur : $error';
  }

  @override
  String get app_create_select_type_title => 'Choisir le type d\'application';

  @override
  String get app_create_select_type_desc =>
      'Sélectionnez le type d\'application que vous souhaitez créer pour commencer.';

  @override
  String get app_create_type_discord => 'Bot Discord';

  @override
  String get app_create_type_discord_desc =>
      'Créez et configurez un bot Discord personnalisé avec des actions, des événements et des calques de canvas.';

  @override
  String get app_create_type_hosted => 'Application Hébergée (Docker)';

  @override
  String get app_create_type_hosted_desc =>
      'Exécutez une application, un serveur ou un script dans le langage de votre choix (NodeJS, Python, Java...). Envoyez vos fichiers et installez des paquets dans un conteneur sécurisé.';

  @override
  String get app_create_coming_soon => 'Bientôt disponible';

  @override
  String get app_create_sample_title => 'Créer une commande exemple';

  @override
  String app_create_sample_desc(String botName) {
    return 'Ajouter une commande /ping prête à l\'emploi pour démarrer rapidement. Elle répond \'Pong!\' et vous pouvez la modifier après l\'avoir créée.';
  }

  @override
  String get app_create_sample_skip => 'Passer';

  @override
  String get app_create_sample_confirm => 'Ajouter /ping';

  @override
  String get app_create_sample_success => 'Commande /ping créée avec succès !';

  @override
  String get commands_empty_title => 'Crée ta première commande !';

  @override
  String get commands_empty_description =>
      'Une commande permet à ton bot de répondre quand quelqu\'un tape /quelquechose sur Discord.';

  @override
  String get commands_empty_create_button => 'Créer une commande';

  @override
  String get commands_empty_marketplace_link =>
      'Ou pars d\'un template du Marketplace';

  @override
  String get command_created_success_title => 'Ta commande est prête !';

  @override
  String get command_created_success_subtitle => 'Que veux-tu faire ensuite ?';

  @override
  String get command_created_start_bot => 'Démarrer mon bot';

  @override
  String get command_created_start_bot_hint =>
      'Ouvre l\'onglet Accueil de ton bot et appuie sur Démarrer pour le mettre en ligne.';

  @override
  String get command_created_invite => 'Inviter sur un serveur';

  @override
  String get command_created_invite_error =>
      'Impossible d\'ouvrir le lien d\'invitation.';

  @override
  String get command_created_create_another => 'Créer une autre commande';

  @override
  String get command_created_close => 'Fermer';

  @override
  String get beginner_mode_label => 'Mode débutant';

  @override
  String get beginner_mode_on_hint =>
      'Affichage des onglets essentiels uniquement';

  @override
  String get beginner_mode_off_hint =>
      'Affichage de toutes les fonctionnalités';

  @override
  String get commands_empty_sample_ping =>
      'Ajouter une commande /ping d\'exemple';

  @override
  String get command_created_sample_success =>
      'Commande /ping créée ! Elle répond « Pong ! »';

  @override
  String get onboarding_create_now => 'Créer mon bot maintenant';

  @override
  String get onboarding_command_now => 'Créer ta première commande';

  @override
  String get container_list_title => 'Bots Clé en main';

  @override
  String get container_list_session_missing => 'Session indisponible';

  @override
  String get container_list_session_hint =>
      'Veuillez d\'abord vous connecter à votre compte.';

  @override
  String get container_list_error => 'Échec du chargement des bots';

  @override
  String get container_list_retry => 'Réessayer';

  @override
  String get container_list_empty => 'Aucun bot clé en main';

  @override
  String get container_list_empty_hint =>
      'Déployez votre premier bot prêt à l\'emploi en 1 clic.';

  @override
  String get container_list_deploy_btn => 'Déployer un Bot Clé en main';

  @override
  String get container_list_unsupported_badge => 'Non supporté';

  @override
  String get container_list_expired => 'Expiré';

  @override
  String container_list_expiry_minutes(int minutes) {
    return '${minutes}m restantes';
  }

  @override
  String container_list_expiry_hours(int hours, int minutes) {
    return '${hours}h ${minutes}m restantes';
  }

  @override
  String container_list_expiry_days(int days, int hours) {
    return '${days}j ${hours}h restantes';
  }

  @override
  String get container_deploy_title => 'Déployer un Bot Clé en main';

  @override
  String get container_deploy_template_section => 'Modèle prêt à l\'emploi';

  @override
  String get container_deploy_managed_hosting => 'Hébergement managé 24/7';

  @override
  String get container_deploy_bot_config_section =>
      'Configuration du Bot Discord';

  @override
  String get container_deploy_paste_token_hint => 'Collez le token Discord ici';

  @override
  String get container_deploy_discord_prereqs => 'Prérequis Discord';

  @override
  String get container_deploy_launch_btn => 'Lancer le bot clé en main';

  @override
  String get container_deploy_image_label => 'Image';

  @override
  String get container_deploy_image_hint =>
      'Image Docker avec tag (ex. ghcr.io/albertgmz/beatdock:latest)';

  @override
  String get container_deploy_template_label => 'Modèle';

  @override
  String get container_deploy_template_easy_music => 'Bot musique simple';

  @override
  String get container_deploy_template_custom => 'Image personnalisée';

  @override
  String get container_deploy_easy_music_hint =>
      'Seul le token de votre bot Discord est requis. Utilise des serveurs Lavalink publics — pas de connexion au registre, de clés API ni de configuration supplémentaire.';

  @override
  String get container_deploy_pick_bot => 'Utiliser un bot existant';

  @override
  String get container_deploy_pick_bot_manual => 'Saisir le token manuellement';

  @override
  String get container_deploy_bot_token_hint =>
      'Créez un bot sur le portail développeur Discord, activez l\'intention Message Content, puis invitez-le sur votre serveur.';

  @override
  String get container_deploy_bot_token_required =>
      'Le token du bot Discord est requis';

  @override
  String get container_deploy_image_required => 'L\'image est requise';

  @override
  String get container_deploy_cpu_label => 'CPU (millis)';

  @override
  String get container_deploy_cpu_min => 'Min 128';

  @override
  String get container_deploy_memory_label => 'Mémoire (Mo)';

  @override
  String get container_deploy_memory_min => 'Min 128 Mo';

  @override
  String get container_deploy_storage_label => 'Stockage (Go)';

  @override
  String get container_deploy_storage_min => 'Min 1 Go';

  @override
  String get container_deploy_ttl_label => 'TTL (minutes)';

  @override
  String get container_deploy_ttl_min => 'Min 1 minute';

  @override
  String get container_deploy_env_label => 'Variables d\'environnement';

  @override
  String get container_deploy_env_key_hint => 'CLÉ';

  @override
  String get container_deploy_env_value_hint => 'valeur';

  @override
  String get container_deploy_submit => 'Déployer';

  @override
  String get container_deploy_submitting => 'Déploiement en cours...';

  @override
  String get container_deploy_not_auth => 'Non authentifié';

  @override
  String container_deploy_success(String containerId) {
    return 'Déploiement de $containerId en cours...';
  }

  @override
  String get container_deploy_submitted_starting =>
      'Application envoyée — démarrage en cours...';

  @override
  String container_deploy_failed(String error) {
    return 'Échec du déploiement : $error';
  }

  @override
  String get container_deploy_blocked_container_limit =>
      'Vous avez atteint votre limite d\'applications hébergées. Supprimez ou arrêtez une application existante pour libérer une place avant d\'en déployer une nouvelle.';

  @override
  String get container_deploy_blocked_no_minutes =>
      'Vous n\'avez plus de minutes d\'hébergement gratuites. Regardez une publicité récompensée pour en débloquer, ou passez à Premium pour un hébergement illimité.';

  @override
  String get container_deploy_blocked_eligibility_error =>
      'Impossible de vérifier si vous pouvez déployer pour le moment.';

  @override
  String container_deploy_ad_slot_full(int granted) {
    return '+$granted minutes d\'hébergement gagnées, mais votre emplacement de conteneur est toujours plein. Supprimez ou arrêtez une application existante pour en déployer une nouvelle.';
  }

  @override
  String get container_detail_state => 'État';

  @override
  String get container_detail_expires => 'Expire le';

  @override
  String get container_detail_extend_ttl => 'Prolonger la TTL';

  @override
  String get container_detail_stop_title => 'Éteindre le conteneur';

  @override
  String get container_detail_stop_confirm =>
      'Le conteneur sera éteint. L\'image et les variables d\'environnement sont conservées pour un redémarrage ultérieur.';

  @override
  String get container_detail_stop_btn => 'Éteindre';

  @override
  String get container_detail_stopped_ok => 'Conteneur éteint';

  @override
  String get container_detail_start_btn => 'Démarrer';

  @override
  String get container_detail_starting => 'Démarrage...';

  @override
  String get container_detail_started_ok => 'Démarrage du conteneur en cours';

  @override
  String get container_detail_delete_title => 'Supprimer le conteneur';

  @override
  String get container_detail_delete_confirm =>
      'Cela supprime définitivement le conteneur de la base de données et du cloud. Cette action est irréversible.';

  @override
  String get container_detail_delete_btn => 'Supprimer';

  @override
  String get container_detail_deleted_ok => 'Conteneur supprimé';

  @override
  String get container_detail_stopped_hint =>
      'Ce conteneur est éteint. Vous pouvez le redémarrer sans ressaisir les variables d\'environnement.';

  @override
  String get container_detail_update_resources =>
      'Mettre à jour les Ressources';

  @override
  String get container_detail_update_btn => 'Mettre à jour';

  @override
  String get container_detail_updated_ok => 'Ressources mises à jour';

  @override
  String get container_detail_extend_hint => 'Minutes à ajouter';

  @override
  String get container_detail_extend_btn => 'Prolonger';

  @override
  String get container_detail_extended_ok => 'TTL prolongée';

  @override
  String get container_detail_console => 'Console';

  @override
  String get container_detail_deploying =>
      'Le conteneur est en cours de déploiement...';

  @override
  String container_detail_status_stopped(String state) {
    return 'Ce conteneur est $state.';
  }

  @override
  String get container_detail_not_connected => 'Non connecté';

  @override
  String get container_detail_console_connecting => 'Connexion en cours...';

  @override
  String get container_detail_console_closed => '--- Connexion fermée ---';

  @override
  String get container_detail_console_hint => 'Tapez une commande...';

  @override
  String container_detail_failed(String error) {
    return 'Échec : $error';
  }

  @override
  String get container_state_running => 'En cours';

  @override
  String get container_state_pending => 'En attente';

  @override
  String get container_state_provisioning => 'Provisionnement';

  @override
  String get container_state_stopped => 'Arrêté';

  @override
  String get container_state_stopping => 'Arrêt en cours';

  @override
  String get container_state_failed => 'Échoué';

  @override
  String get container_health_image_pull_failed =>
      'Impossible de récupérer l\'image du conteneur. Vérifiez que le nom et le tag de l\'image sont corrects et que les identifiants de registre nécessaires sont configurés.';

  @override
  String get container_health_crash_loop =>
      'Le conteneur plante peu après son démarrage. Vérifiez vos variables d\'environnement et les journaux.';

  @override
  String get container_health_starting => 'Démarrage en cours...';

  @override
  String get container_hosted_subtitle =>
      'Déployez des bots prêts à l\'emploi (musique, etc.) en 1 clic';

  @override
  String get container_premium_badge => 'Premium';

  @override
  String container_detail_title(String id) {
    return 'Bot $id';
  }

  @override
  String get container_list_premium_host_anytime_tooltip =>
      'Premium — hébergez à tout moment';

  @override
  String get container_list_premium_host_anytime_fab =>
      'Héberger à tout moment';

  @override
  String get container_list_free_limit_reached =>
      'Limite gratuite atteinte (1 bot). Abonnez-vous pour en héberger plus.';

  @override
  String get container_hosted_premium_host_anytime => 'Hébergez à tout moment';

  @override
  String get container_hosted_premium_host_anytime_compact =>
      'S\'abonner — héberger à tout moment';

  @override
  String get container_hosted_premium_desc =>
      'Abonnez-vous pour héberger vos bots clé en main 24/7 — sans publicité.';

  @override
  String get container_hosted_premium_view_btn => 'Voir les offres';

  @override
  String get hosted_app_subscription_title => 'Bots Clé en main';

  @override
  String get hosted_app_subscription_subtitle =>
      'Hébergez vos bots prêts à l\'emploi dans le cloud 24/7 sans interruption.';

  @override
  String get hosted_app_subscription_benefit_unlimited =>
      'Temps d\'hébergement illimité';

  @override
  String get hosted_app_subscription_benefit_no_ads =>
      'Aucune publicité récompensée requise';

  @override
  String get hosted_app_subscription_one_app_title => '1 bot hébergé';

  @override
  String get hosted_app_subscription_one_app_desc =>
      'Hébergez un bot clé en main à tout moment';

  @override
  String get hosted_app_subscription_two_app_title => '2 bots hébergés';

  @override
  String get hosted_app_subscription_two_app_desc =>
      'Hébergez jusqu\'à deux bots clé en main';

  @override
  String get hosted_app_subscription_recommended => 'Meilleur choix';

  @override
  String get container_hosted_free_title =>
      'Hébergement gratuit (1 conteneur max)';

  @override
  String container_hosted_expires_at(String dateTime) {
    return 'Expire le $dateTime';
  }

  @override
  String container_hosted_topup_ad_hint(int reward) {
    return 'Regardez une pub pour ajouter $reward min à ce conteneur (cumulable).';
  }

  @override
  String container_hosted_at_limit_open_detail(int active, int max) {
    return 'Conteneur actif ($active/$max). Ouvrez-le pour prolonger avec une pub.';
  }

  @override
  String container_hosted_minutes_available(int minutes) {
    return '$minutes min d\'hébergement disponibles (cumulables).';
  }

  @override
  String get container_hosted_resume_with_time =>
      'Il vous reste du temps d\'hébergement sur ce conteneur. Appuyez sur Démarrer pour reprendre.';

  @override
  String container_hosted_watch_ad_earn(int reward) {
    return 'Regardez une pub pour gagner $reward min d\'hébergement.';
  }

  @override
  String container_hosted_ad_button(int reward) {
    return 'Pub +$reward min';
  }

  @override
  String container_hosted_balance_after_ad(int minutes) {
    return 'Solde après dernière pub : $minutes min';
  }

  @override
  String container_deploy_ad_unlock_success(int granted, int balance) {
    return '+$granted min d\'hébergement (total : $balance min).';
  }

  @override
  String container_deploy_ad_unlock_failed(String error) {
    return 'Échec du déblocage : $error';
  }

  @override
  String get container_deploy_requires_premium_or_ad =>
      'Abonnement Premium ou publicité requise pour déployer un conteneur.';

  @override
  String get container_deploy_premium_account => 'Compte Premium';

  @override
  String container_deploy_premium_containers(int max, int active) {
    return 'Jusqu\'à $max conteneurs actifs ($active/$max).';
  }

  @override
  String get container_deploy_ephemeral_storage =>
      'Stockage éphémère (pas de volume persistant)';

  @override
  String get container_deploy_private_image => 'Image privée';

  @override
  String get container_deploy_private_image_hint =>
      'Fournissez des identifiants de registre pour récupérer des images privées (ex. GHCR).';

  @override
  String get container_deploy_use_custom_credentials =>
      'Utiliser des identifiants personnalisés';

  @override
  String get container_deploy_registry_profile =>
      'Profil de registre enregistré';

  @override
  String get container_deploy_registry_profile_none => 'Sélectionner un profil';

  @override
  String container_deploy_registry_detected(String host) {
    return 'Registre : $host';
  }

  @override
  String get container_deploy_save_registry_auth =>
      'Enregistrer les identifiants pour réutilisation';

  @override
  String get container_deploy_registry_auth_required =>
      'Le nom d\'utilisateur et le mot de passe sont requis pour les images privées.';

  @override
  String get container_deploy_registry_profile_required =>
      'Sélectionnez un profil de registre enregistré ou utilisez des identifiants personnalisés.';

  @override
  String get registry_credentials_title => 'Identifiants de registre';

  @override
  String get registry_credentials_add => 'Ajouter des identifiants';

  @override
  String get registry_credentials_edit => 'Modifier les identifiants';

  @override
  String get registry_credentials_manage =>
      'Gérer les identifiants de registre';

  @override
  String get registry_credentials_empty =>
      'Aucun identifiant de registre enregistré pour le moment.';

  @override
  String get registry_credentials_label => 'Libellé';

  @override
  String get registry_credentials_label_required => 'Le libellé est requis';

  @override
  String get registry_credentials_host => 'Hôte du registre';

  @override
  String get registry_credentials_host_required =>
      'L\'hôte du registre est requis';

  @override
  String get registry_credentials_username => 'Nom d\'utilisateur';

  @override
  String get registry_credentials_username_required =>
      'Le nom d\'utilisateur est requis';

  @override
  String get registry_credentials_password => 'Mot de passe ou jeton';

  @override
  String get registry_credentials_password_required =>
      'Le mot de passe ou le jeton est requis';

  @override
  String get registry_credentials_password_hint =>
      'Jeton d\'accès personnel ou mot de passe du registre';

  @override
  String get registry_credentials_password_edit_hint =>
      'Laisser vide pour conserver le mot de passe actuel';

  @override
  String get registry_credentials_ghcr_hint =>
      'Pour GHCR, utilisez un PAT GitHub avec la portée read:packages.';

  @override
  String get registry_credentials_delete_title =>
      'Supprimer les identifiants ?';

  @override
  String registry_credentials_delete_body(String label) {
    return 'Supprimer « $label » ? Cette action est irréversible.';
  }

  @override
  String get registry_credentials_deleted =>
      'Identifiants de registre supprimés';

  @override
  String registry_credentials_delete_failed(String error) {
    return 'Échec de la suppression des identifiants : $error';
  }

  @override
  String registry_credentials_save_failed(String error) {
    return 'Échec de l\'enregistrement des identifiants : $error';
  }

  @override
  String container_detail_private_registry(String host, String username) {
    return 'Registre privé : $host · $username';
  }

  @override
  String container_detail_topup_applied(int minutes) {
    return '+$minutes min ajoutées à ce conteneur.';
  }

  @override
  String container_detail_topup_credited(int minutes) {
    return '+$minutes min créditées.';
  }

  @override
  String container_detail_apply_stored_minutes(int minutes) {
    return 'Appliquer $minutes min stockées';
  }

  @override
  String container_detail_minutes_applied(int minutes) {
    return '$minutes min appliquées.';
  }

  @override
  String get docs_hub_title => 'Documentation';

  @override
  String get docs_tab_guide => 'Guide';

  @override
  String get docs_tab_bot_creator => 'Docs Bot Creator';

  @override
  String get docs_tab_discordjs => 'discord.js';

  @override
  String get docs_webview_error => 'Impossible de charger la documentation';

  @override
  String get docs_webview_unavailable =>
      'L\'aperçu intégré de la documentation n\'est pas disponible sur cet appareil. Ouvrez la documentation dans votre navigateur.';

  @override
  String get docs_open_in_browser => 'Ouvrir dans le navigateur';

  @override
  String get docs_reload => 'Recharger';
}
