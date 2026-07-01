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
  String get action_add_header => 'Ajouter un en-tÃƒÂªte';

  @override
  String get action_add_new_item => 'Ajouter un nouvel ÃƒÂ©lÃƒÂ©ment';

  @override
  String get action_advanced_settings => 'ParamÃƒÂ¨tres avancÃƒÂ©s';

  @override
  String action_and_more(int count) {
    return '... et $count de plus';
  }

  @override
  String get action_bulk_import_hint =>
      'Import en masse (collez des headers comme ClÃƒÂ©: Valeur)';

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
  String get action_category_moderation => 'ModÃƒÂ©ration';

  @override
  String get action_category_music => 'Musique';

  @override
  String get action_category_reactions => 'RÃƒÂ©actions';

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
      'Ajouter un emoji en rÃƒÂ©action ÃƒÂ  un message';

  @override
  String get action_description_addRole =>
      'Attribuer un rÃƒÂ´le ÃƒÂ  un membre';

  @override
  String get action_description_addThreadMember =>
      'Ajouter un membre ÃƒÂ  un fil de discussion';

  @override
  String get action_description_appendArrayElement =>
      'Ajouter un nouvel ÃƒÂ©lÃƒÂ©ment dans un tableau JSON global ou ÃƒÂ  portÃƒÂ©e';

  @override
  String get action_description_attachImage =>
      'Joindre un fichier image ÃƒÂ  la rÃƒÂ©ponse (URL, data URL ou base64)';

  @override
  String get action_description_banUser =>
      'Bannir dÃƒÂ©finitivement un utilisateur du serveur';

  @override
  String get action_description_calculate =>
      'Effectuer des opÃƒÂ©rations mathÃƒÂ©matiques et stocker le rÃƒÂ©sultat';

  @override
  String get action_description_canvasCreateBlock =>
      'CrÃƒÂ©er un canevas d\'image vierge';

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
      'Supprimer toutes les rÃƒÂ©actions d\'un message';

  @override
  String get action_description_cooldown =>
      'Applique un dÃƒÂ©lai d\'attente pour l\'utilisateur ou le serveur';

  @override
  String get action_description_createAutoModRule =>
      'CrÃƒÂ©er une rÃƒÂ¨gle de modÃƒÂ©ration automatique pour le serveur';

  @override
  String get action_description_createChannel => 'CrÃƒÂ©er un nouveau salon';

  @override
  String get action_description_createEmoji =>
      'CrÃƒÂ©er un emoji de serveur ÃƒÂ  partir de donnÃƒÂ©es d\'image';

  @override
  String get action_description_createInvite =>
      'CrÃƒÂ©er un nouveau lien d\'invitation pour un salon';

  @override
  String get action_description_createPoll =>
      'CrÃƒÂ©er un message de sondage dans un salon';

  @override
  String get action_description_createThread =>
      'CrÃƒÂ©er un fil de discussion dans un salon textuel pris en charge';

  @override
  String get action_description_debugProfile =>
      'GÃƒÂ©nÃƒÂ©rer un profil d\'exÃƒÂ©cution et des informations de diagnostic';

  @override
  String get action_description_deferInteraction =>
      'DiffÃƒÂ©rer la rÃƒÂ©ponse ÃƒÂ  l\'interaction pour ÃƒÂ©viter l\'expiration Discord';

  @override
  String get action_description_deleteAutoModRule =>
      'Supprimer une rÃƒÂ¨gle de modÃƒÂ©ration automatique';

  @override
  String get action_description_deleteChannelPermission =>
      'Supprimer une autorisation spÃƒÂ©cifique du salon';

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
      'Supprime le message qui a dÃƒÂ©clenchÃƒÂ© cette commande';

  @override
  String get action_description_deleteWebhook => 'Supprimer un Webhook';

  @override
  String get action_description_disconnectFromVoice =>
      'DÃƒÂ©conneter un membre du salon vocal';

  @override
  String get action_description_editChannelPermissions =>
      'CrÃƒÂ©er ou mettre ÃƒÂ  jour les autorisations spÃƒÂ©cifiques du salon';

  @override
  String get action_description_editComponentV2 =>
      'Modifier les composants existants';

  @override
  String get action_description_editInteractionMessage =>
      'Modifier la rÃƒÂ©ponse d\'interaction diffÃƒÂ©rÃƒÂ©e ou d\'origine';

  @override
  String get action_description_editMessage => 'Modifier un message existant';

  @override
  String get action_description_editWebhook => 'Modifier un Webhook existant';

  @override
  String get action_description_endPoll =>
      'Terminer immÃƒÂ©diatement un sondage actif';

  @override
  String get action_description_forLoop =>
      'Boucler sur une plage de nombres (boucle for)';

  @override
  String get action_description_getGlobalVariable =>
      'Lire une variable globale et l\'injecter dans les variables d\'exÃƒÂ©cution';

  @override
  String get action_description_getGuildOnboarding =>
      'RÃƒÂ©cupÃƒÂ©rer la configuration actuelle de l\'accueil du serveur';

  @override
  String get action_description_getInvite =>
      'RÃƒÂ©cupÃƒÂ©rer les informations de l\'invitation par code';

  @override
  String get action_description_getMember =>
      'Obtenir des informations sur un membre';

  @override
  String get action_description_getMessage =>
      'RÃƒÂ©cupÃƒÂ©rer un message et exposer ses champs';

  @override
  String get action_description_getMusicInfo =>
      'Obtenir des informations sur le morceau en cours de lecture';

  @override
  String get action_description_getScopedVariable =>
      'Lire une variable ÃƒÂ  portÃƒÂ©e et l\'injecter dans les variables d\'exÃƒÂ©cution';

  @override
  String get action_description_getWebhook =>
      'Obtenir les informations d\'un Webhook par ID';

  @override
  String get action_description_httpRequest =>
      'Envoyer une requÃƒÂªte HTTP avec URL, mÃƒÂ©thode, en-tÃƒÂªtes et corps dynamiques';

  @override
  String get action_description_ifBlock =>
      'Branchement conditionnel : exÃƒÂ©cuter diffÃƒÂ©rentes actions selon une condition';

  @override
  String get action_description_jumpToAction =>
      'Aller ÃƒÂ  une action spÃƒÂ©cifique par clÃƒÂ©, ID, ou position';

  @override
  String get action_description_joinVoice => 'Se connecter ÃƒÂ  un salon vocal';

  @override
  String get action_description_jsonForEachLoop =>
      'Boucler sur chaque ÃƒÂ©lÃƒÂ©ment d\'un tableau ou objet JSON (forEach)';

  @override
  String get action_description_kickUser => 'Expulser un membre du serveur';

  @override
  String get action_description_leaveGuild =>
      'Faire quitter le serveur/la guilde au bot';

  @override
  String get action_description_leaveVoice =>
      'Quitter le salon vocal et dÃƒÂ©connecter le lecteur';

  @override
  String get action_description_listAutoModRules =>
      'Lister toutes les rÃƒÂ¨gles de modÃƒÂ©ration automatique du serveur';

  @override
  String get action_description_listMembers =>
      'Lister les membres d\'un serveur avec des options';

  @override
  String get action_description_listScopedVariableIndex =>
      'Lister les valeurs indexÃƒÂ©es ÃƒÂ  portÃƒÂ©e triÃƒÂ©es par valeur avec dÃƒÂ©calage et limite';

  @override
  String get action_description_listWebhooks =>
      'Lister tous les Webhooks d\'un salon ou d\'un serveur';

  @override
  String get action_description_listenAndExecute =>
      'Enregistrer un workflow ÃƒÂ  exÃƒÂ©cuter lorsqu\'un bouton est cliquÃƒÂ©, un menu de sÃƒÂ©lection est utilisÃƒÂ© ou un modal est soumis';

  @override
  String get action_description_listenForButtonClick =>
      'Enregistrer un workflow ÃƒÂ  exÃƒÂ©cuter lorsqu\'un bouton est cliquÃƒÂ©';

  @override
  String get action_description_listenForModalSubmit =>
      'Enregistrer un workflow ÃƒÂ  exÃƒÂ©cuter lorsqu\'un modal est soumis';

  @override
  String get action_description_listenForSelectMenu =>
      'Enregistrer un workflow ÃƒÂ  exÃƒÂ©cuter lorsqu\'un menu de sÃƒÂ©lection est utilisÃƒÂ©';

  @override
  String get action_description_log =>
      'Imprimer ou stocker un message de diagnostic dans les journaux d\'actions';

  @override
  String get action_description_moveToVoiceChannel =>
      'DÃƒÂ©placer un membre vers un salon vocal spÃƒÂ©cifique';

  @override
  String get action_description_muteUser =>
      'Exclure temporairement (timeout) un membre';

  @override
  String get action_description_pauseMusic =>
      'Mettre en pause la lecture en cours';

  @override
  String get action_description_pinMessage =>
      'Ãƒâ€°pingler un message dans un salon';

  @override
  String get action_description_playMusic =>
      'Jouer un morceau par recherche ou URL';

  @override
  String get action_description_queryArray =>
      'Filtrer, trier et paginer tout tableau JSON d\'exÃƒÂ©cution';

  @override
  String get action_description_randomChoice =>
      'Choisit un ÃƒÂ©lÃƒÂ©ment alÃƒÂ©atoire dans une liste et le stocke dans une variable';

  @override
  String get action_description_registerGuildCommands =>
      'Enregistrer les commandes d\'application sur un serveur';

  @override
  String get action_description_removeArrayElement =>
      'Supprimer un ÃƒÂ©lÃƒÂ©ment d\'un tableau JSON global ou ÃƒÂ  portÃƒÂ©e par index';

  @override
  String get action_description_removeChannel => 'Supprimer un salon';

  @override
  String get action_description_removeGlobalVariable =>
      'Supprimer une variable globale';

  @override
  String get action_description_removeReaction =>
      'Retirer une rÃƒÂ©action d\'un message';

  @override
  String get action_description_removeRole =>
      'Retirer un rÃƒÂ´le ÃƒÂ  un membre';

  @override
  String get action_description_removeScopedVariable =>
      'Supprimer une variable ÃƒÂ  portÃƒÂ©e';

  @override
  String get action_description_removeThreadMember =>
      'Supprimer un membre d\'un fil de discussion';

  @override
  String get action_description_renameScopedVariable =>
      'Renommer la clÃƒÂ© d\'une variable ÃƒÂ  portÃƒÂ©e';

  @override
  String get action_description_respondWithAutocomplete =>
      'RÃƒÂ©pondre ÃƒÂ  une interaction d\'autocomplÃƒÂ©tion Discord avec jusqu\'ÃƒÂ  25 choix dynamiques';

  @override
  String get action_description_respondWithComponentV2 =>
      'RÃƒÂ©pondre ÃƒÂ  la commande avec des boutons/menus de sÃƒÂ©lection';

  @override
  String get action_description_respondWithMessage =>
      'RÃƒÂ©pondre ÃƒÂ  la commande avec un message normal';

  @override
  String get action_description_respondWithModal =>
      'Afficher une boÃƒÂ®te de dialogue modale ÃƒÂ  l\'utilisateur';

  @override
  String get action_description_resumeMusic =>
      'Reprendre la lecture d\'un morceau en pause';

  @override
  String get action_description_runBdfdScript =>
      'Compiler et exÃƒÂ©cuter un script BDFD en ligne comme actions de workflow';

  @override
  String get action_description_runWorkflow =>
      'ExÃƒÂ©cuter un workflow enregistrÃƒÂ© (prend en charge le point d\'entrÃƒÂ©e + arguments)';

  @override
  String get action_description_runtimeImageBlock =>
      'ExÃƒÂ©cuter un bloc d\'actions de traitement de canevas d\'image';

  @override
  String get action_description_runtimeJsonBlock =>
      'ExÃƒÂ©cuter un bloc d\'actions de traitement JSON';

  @override
  String get action_description_seekMusic =>
      'Positionner la lecture ÃƒÂ  un moment prÃƒÂ©cis';

  @override
  String get action_description_sendComponentV2 =>
      'Envoyer des composants interactifs';

  @override
  String get action_description_sendDm =>
      'Envoie un message privÃƒÂ© ÃƒÂ  un utilisateur spÃƒÂ©cifique';

  @override
  String get action_description_sendMessage =>
      'Envoyer un message dans un salon spÃƒÂ©cifique';

  @override
  String get action_description_sendWebhook => 'Envoyer un message via Webhook';

  @override
  String get action_description_serverDeafenMember =>
      'Assourdir ou rÃƒÂ©tablir l\'ouÃƒÂ¯e d\'un membre sur le serveur';

  @override
  String get action_description_serverMuteMember =>
      'Rendre muet ou rÃƒÂ©tablir le son d\'un membre sur le serveur';

  @override
  String get action_description_setGlobalVariable =>
      'CrÃƒÂ©er ou mettre ÃƒÂ  jour une variable globale pour ce bot';

  @override
  String get action_description_setMusicLoop =>
      'Activer ou dÃƒÂ©sactiver la lecture en boucle de la file';

  @override
  String get action_description_setMusicVolume =>
      'RÃƒÂ©gler le volume du lecteur (0 ÃƒÂ  200)';

  @override
  String get action_description_setNickname =>
      'Change le surnom d\'un membre du serveur';

  @override
  String get action_description_setScopedVariable =>
      'CrÃƒÂ©er ou mettre ÃƒÂ  jour une variable ÃƒÂ  portÃƒÂ©e (serveur/utilisateur/salon/membre/message)';

  @override
  String get action_description_setTemporaryVariable =>
      'CrÃƒÂ©er ou mettre ÃƒÂ  jour une variable temporaire dans l\'exÃƒÂ©cution locale';

  @override
  String get action_description_skipActions =>
      'Sauter un nombre spÃƒÂ©cifiÃƒÂ© d\'actions suivantes';

  @override
  String get action_description_skipMusic =>
      'Passer au morceau suivant dans la file';

  @override
  String get action_description_slowmode =>
      'DÃƒÂ©finit la durÃƒÂ©e du mode lent pour un salon';

  @override
  String get action_description_stop =>
      'ArrÃƒÂªte immÃƒÂ©diatement l\'exÃƒÂ©cution du workflow actuel';

  @override
  String get action_description_stopMusic =>
      'ArrÃƒÂªter la lecture et vider la file';

  @override
  String get action_description_stopUnless =>
      'ArrÃƒÂªter le workflow si une condition n\'est pas remplie (garde/filtre)';

  @override
  String get action_description_unbanUser =>
      'RÃƒÂ©voquer le bannissement d\'un utilisateur';

  @override
  String get action_description_unmuteUser =>
      'Retirer l\'exclusion temporaire d\'un membre';

  @override
  String get action_description_unpinMessage =>
      'DÃƒÂ©sÃƒÂ©pingler un message dans un salon';

  @override
  String get action_description_unregisterGuildCommands =>
      'DÃƒÂ©senregistrer les commandes d\'application d\'un serveur';

  @override
  String get action_description_updateAutoMod =>
      'Mettre ÃƒÂ  jour les paramÃƒÂ¨tres de modÃƒÂ©ration automatique';

  @override
  String get action_description_updateChannel =>
      'Mettre ÃƒÂ  jour les paramÃƒÂ¨tres du salon';

  @override
  String get action_description_updateEmoji =>
      'Mettre ÃƒÂ  jour le nom de l\'emoji ou l\'accÃƒÂ¨s aux rÃƒÂ´les du serveur';

  @override
  String get action_description_updateGuild =>
      'Mettre ÃƒÂ  jour les paramÃƒÂ¨tres du serveur';

  @override
  String get action_description_updateGuildOnboarding =>
      'Mettre ÃƒÂ  jour la configuration de l\'accueil du serveur';

  @override
  String get action_description_updateSelfUser =>
      'Mettre ÃƒÂ  jour le profil du bot (nom d\'utilisateur/avatar)';

  @override
  String get action_description_wait =>
      'Met en pause l\'exÃƒÂ©cution pour une durÃƒÂ©e prÃƒÂ©cise';

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
  String get action_dynamic_numeric => 'Suggestions numÃƒÂ©riques dynamiques';

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
    return 'SINON SI $index Ã¢â‚¬â€ actions';
  }

  @override
  String get action_error_continue => 'Continuer';

  @override
  String get action_error_stop => 'ArrÃƒÂªter';

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
      'Utiliser ((variableName)) ou une valeur d\'exÃƒÂ©cution';

  @override
  String get action_hint_cooldown_error =>
      'Message ÃƒÂ  envoyer si en cooldown (supporte %time%)';

  @override
  String get action_hint_cooldown_time => 'DurÃƒÂ©e (ex: 10s, 5m)';

  @override
  String get action_hint_duration => 'ex. 5m, 1h, 30s';

  @override
  String get action_hint_emoji => 'Ãƒâ€°moji (ex. Ã°Å¸ÂªÅ“) ou <:nom:id>';

  @override
  String action_hint_enter_type(String type) {
    return 'Saisir $type';
  }

  @override
  String get action_hint_random_choices =>
      'Liste de choix (sÃƒÂ©parÃƒÂ©s par ;)';

  @override
  String get action_hint_random_var =>
      'Nom de la variable pour stocker le rÃƒÂ©sultat';

  @override
  String get action_hint_variable_key =>
      'SÃƒÂ©lectionner une clÃƒÂ© de variable';

  @override
  String get action_hint_workflow => 'Nom du workflow enregistrÃƒÂ©';

  @override
  String get action_http_headers_title => 'Headers HTTP (paires clÃƒÂ©/valeur)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count chemins analysÃƒÂ©s';
  }

  @override
  String get action_http_response_body => 'Corps de la rÃƒÂ©ponse (brut) :';

  @override
  String action_http_status(int status) {
    return 'Statut : $status';
  }

  @override
  String get action_http_test_button =>
      'Envoyer une requÃƒÂªte test et dÃƒÂ©tecter les routes';

  @override
  String get action_http_test_title => 'RÃƒÂ©sultats de la requÃƒÂªte test';

  @override
  String get action_json_editor_hint =>
      'Ãƒâ€°diteur d\'objet JSON (supporte les objets/tableaux imbriquÃƒÂ©s)';

  @override
  String get action_key_field => 'ClÃƒÂ© d\'action';

  @override
  String get action_key_value_pairs => 'Paires clÃƒÂ© / valeur';

  @override
  String get action_literal => 'LittÃƒÂ©ral';

  @override
  String get action_loading_keys => 'Chargement des clÃƒÂ©s...';

  @override
  String get action_manage_variable_keys => 'GÃƒÂ©rer les clÃƒÂ©s de variables';

  @override
  String get action_name_addReaction => 'Ajouter une rÃƒÂ©action';

  @override
  String get action_name_addRole => 'Ajouter un rÃƒÂ´le';

  @override
  String get action_name_addThreadMember => 'Ajouter un membre au fil';

  @override
  String get action_name_appendArrayElement =>
      'Ajouter un ÃƒÂ©lÃƒÂ©ment ÃƒÂ  un tableau';

  @override
  String get action_name_attachImage => 'Joindre une image';

  @override
  String get action_name_banUser => 'Bannir un utilisateur';

  @override
  String get action_name_calculate => 'Calculer';

  @override
  String get action_name_canvasCreateBlock => 'CrÃƒÂ©er un canevas';

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
  String get action_name_clearAllReactions => 'Retirer toutes les rÃƒÂ©actions';

  @override
  String get action_name_cooldown => 'Cooldown';

  @override
  String get action_name_createAutoModRule => 'CrÃƒÂ©er une rÃƒÂ¨gle AutoMod';

  @override
  String get action_name_createChannel => 'CrÃƒÂ©er un salon';

  @override
  String get action_name_createEmoji => 'CrÃƒÂ©er un emoji';

  @override
  String get action_name_createInvite => 'CrÃƒÂ©er une invitation';

  @override
  String get action_name_createPoll => 'CrÃƒÂ©er un sondage';

  @override
  String get action_name_createThread => 'CrÃƒÂ©er un fil';

  @override
  String get action_name_debugProfile => 'Profil de dÃƒÂ©bogage';

  @override
  String get action_name_deferInteraction => 'DiffÃƒÂ©rer l\'interaction';

  @override
  String get action_name_deleteAutoModRule => 'Supprimer une rÃƒÂ¨gle AutoMod';

  @override
  String get action_name_deleteChannelPermission =>
      'Supprimer une permission du salon';

  @override
  String get action_name_deleteEmoji => 'Supprimer l\'ÃƒÂ©moji';

  @override
  String get action_name_deleteInvite => 'Supprimer une invitation';

  @override
  String get action_name_deleteMessages => 'Supprimer des messages';

  @override
  String get action_name_deleteTrigger => 'Supprimer le message dÃƒÂ©clencheur';

  @override
  String get action_name_deleteWebhook => 'Supprimer un webhook';

  @override
  String get action_name_disconnectFromVoice => 'DÃƒÂ©connecter du vocal';

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
  String get action_name_endPoll => 'ClÃƒÂ´turer un sondage';

  @override
  String get action_name_forLoop => 'Boucle Pour';

  @override
  String get action_name_getGlobalVariable => 'Lire une variable globale';

  @override
  String get action_name_getGuildOnboarding =>
      'RÃƒÂ©cupÃƒÂ©rer l\'onboarding serveur';

  @override
  String get action_name_getInvite => 'RÃƒÂ©cupÃƒÂ©rer une invitation';

  @override
  String get action_name_getMember => 'RÃƒÂ©cupÃƒÂ©rer un membre';

  @override
  String get action_name_getMessage => 'RÃƒÂ©cupÃƒÂ©rer un message';

  @override
  String get action_name_getMusicInfo => 'Obtenir les infos de la musique';

  @override
  String get action_name_getScopedVariable => 'Lire une variable scopÃƒÂ©e';

  @override
  String get action_name_getWebhook => 'RÃƒÂ©cupÃƒÂ©rer un webhook';

  @override
  String get action_name_httpRequest => 'RequÃƒÂªte HTTP';

  @override
  String get action_name_ifBlock => 'Bloc SI / SINON';

  @override
  String get action_name_jumpToAction => 'Aller ÃƒÂ  l\'action';

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
  String get action_name_listAutoModRules => 'Lister les rÃƒÂ¨gles AutoMod';

  @override
  String get action_name_listMembers => 'Lister les membres';

  @override
  String get action_name_listScopedVariableIndex =>
      'Lister un index de variable scopÃƒÂ©e';

  @override
  String get action_name_listWebhooks => 'Lister les webhooks';

  @override
  String get action_name_listenAndExecute => 'Ãƒâ€°couter et exÃƒÂ©cuter';

  @override
  String get action_name_listenForButtonClick => 'Ãƒâ€°couter un clic bouton';

  @override
  String get action_name_listenForModalSubmit =>
      'Ãƒâ€°couter une soumission de modal';

  @override
  String get action_name_listenForSelectMenu =>
      'Ãƒâ€°couter un menu de sÃƒÂ©lection';

  @override
  String get action_name_log => 'Log';

  @override
  String get action_name_moveToVoiceChannel => 'DÃƒÂ©placer vers un vocal';

  @override
  String get action_name_muteUser => 'Rendre muet un utilisateur';

  @override
  String get action_name_pauseMusic => 'Mettre en pause la musique';

  @override
  String get action_name_pinMessage => 'Ãƒâ€°pingler un message';

  @override
  String get action_name_playMusic => 'Jouer de la musique';

  @override
  String get action_name_queryArray => 'Interroger un tableau';

  @override
  String get action_name_randomChoice => 'Choix alÃƒÂ©atoire';

  @override
  String get action_name_registerGuildCommands => 'Enregistrer les commandes';

  @override
  String get action_name_removeArrayElement =>
      'Retirer un ÃƒÂ©lÃƒÂ©ment de tableau';

  @override
  String get action_name_removeChannel => 'Supprimer un salon';

  @override
  String get action_name_removeGlobalVariable =>
      'Supprimer une variable globale';

  @override
  String get action_name_removeReaction => 'Retirer une rÃƒÂ©action';

  @override
  String get action_name_removeRole => 'Retirer un rÃƒÂ´le';

  @override
  String get action_name_removeScopedVariable =>
      'Supprimer une variable scopÃƒÂ©e';

  @override
  String get action_name_removeThreadMember => 'Retirer un membre du fil';

  @override
  String get action_name_renameScopedVariable =>
      'Renommer une variable scopÃƒÂ©e';

  @override
  String get action_name_respondWithAutocomplete =>
      'RÃƒÂ©pondre avec l\'autocomplÃƒÂ©tion';

  @override
  String get action_name_respondWithComponentV2 =>
      'RÃƒÂ©pondre avec un composant V2';

  @override
  String get action_name_respondWithMessage => 'RÃƒÂ©pondre avec un message';

  @override
  String get action_name_respondWithModal => 'RÃƒÂ©pondre avec un modal';

  @override
  String get action_name_resumeMusic => 'Reprendre la musique';

  @override
  String get action_name_runBdfdScript => 'ExÃƒÂ©cuter un script BDFD';

  @override
  String get action_name_runWorkflow => 'ExÃƒÂ©cuter un workflow';

  @override
  String get action_name_runtimeImageBlock => 'Bloc Image d\'exÃƒÂ©cution';

  @override
  String get action_name_runtimeJsonBlock => 'Bloc JSON d\'exÃƒÂ©cution';

  @override
  String get action_name_seekMusic => 'Positionner la lecture de musique';

  @override
  String get action_name_sendComponentV2 => 'Envoyer un composant V2';

  @override
  String get action_name_sendDm => 'Envoyer un message privÃƒÂ© (MP)';

  @override
  String get action_name_sendMessage => 'Envoyer un message';

  @override
  String get action_name_sendWebhook => 'Envoyer un Webhook';

  @override
  String get action_name_serverDeafenMember => 'Assourdir cÃƒÂ´tÃƒÂ© serveur';

  @override
  String get action_name_serverMuteMember => 'Rendre muet cÃƒÂ´tÃƒÂ© serveur';

  @override
  String get action_name_setGlobalVariable => 'DÃƒÂ©finir une variable globale';

  @override
  String get action_name_setMusicLoop => 'RÃƒÂ©gler la lecture en boucle';

  @override
  String get action_name_setMusicVolume => 'RÃƒÂ©gler le volume de la musique';

  @override
  String get action_name_setNickname => 'Changer le surnom';

  @override
  String get action_name_setScopedVariable =>
      'DÃƒÂ©finir une variable scopÃƒÂ©e';

  @override
  String get action_name_setTemporaryVariable =>
      'DÃƒÂ©finir une variable temporaire';

  @override
  String get action_name_skipActions => 'Sauter N actions';

  @override
  String get action_name_skipMusic => 'Passer la musique';

  @override
  String get action_name_slowmode => 'Mode lent';

  @override
  String get action_name_stop => 'ArrÃƒÂªter l\'exÃƒÂ©cution';

  @override
  String get action_name_stopMusic => 'ArrÃƒÂªter la musique';

  @override
  String get action_name_stopUnless => 'ArrÃƒÂªter sauf si condition';

  @override
  String get action_name_unbanUser => 'DÃƒÂ©bannir un utilisateur';

  @override
  String get action_name_unmuteUser =>
      'RÃƒÂ©activer la parole d\'un utilisateur';

  @override
  String get action_name_unpinMessage => 'DÃƒÂ©sÃƒÂ©pingler un message';

  @override
  String get action_name_unregisterGuildCommands =>
      'DÃƒÂ©senregistrer les commandes';

  @override
  String get action_name_updateAutoMod => 'Mettre ÃƒÂ  jour AutoMod';

  @override
  String get action_name_updateChannel => 'Modifier un salon';

  @override
  String get action_name_updateEmoji => 'Modifier un emoji';

  @override
  String get action_name_updateGuild => 'Mettre ÃƒÂ  jour le serveur';

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
      'Aucun ÃƒÂ©lÃƒÂ©ment - appuyez sur modifier pour ajouter';

  @override
  String get action_no_properties_tap_edit =>
      'Aucune propriÃƒÂ©tÃƒÂ© - appuyez sur configurer';

  @override
  String get action_no_saved_keys =>
      'Aucune clÃƒÂ© trouvÃƒÂ©e. Les clÃƒÂ©s sont crÃƒÂ©ÃƒÂ©es automatiquement au premier accÃƒÂ¨s.';

  @override
  String get action_on_error => 'En cas d\'erreur';

  @override
  String get action_options_tooltip => 'Options de l\'action';

  @override
  String get action_or_type_workflow => 'Ou saisir le nom du workflow';

  @override
  String get action_order_tip =>
      'Astuce : utilisez les flÃƒÂ¨ches pour changer l\'ordre des actions.';

  @override
  String action_position(int index, int total) {
    return 'Action $index/$total';
  }

  @override
  String get action_preview_json => 'AperÃƒÂ§u JSON mis en forme';

  @override
  String get action_provide_valid_url => 'Veuillez fournir une URL valide.';

  @override
  String get action_refresh_keys => 'Actualiser les clÃƒÂ©s';

  @override
  String get action_remove_confirm =>
      'Cette action sera supprimÃƒÂ©e du workflow. Continuer ?';

  @override
  String get action_remove_else_if => 'Supprimer ELSE IF';

  @override
  String get action_remove_menu => 'Supprimer l\'action';

  @override
  String get action_remove_title => 'Supprimer l\'action';

  @override
  String get action_root_must_json => 'La racine doit ÃƒÂªtre un objet JSON';

  @override
  String get action_select_saved_key =>
      'SÃƒÂ©lectionner une clÃƒÂ© enregistrÃƒÂ©e';

  @override
  String get action_select_stored_key =>
      'SÃƒÂ©lectionner une clÃƒÂ© enregistrÃƒÂ©e (prÃƒÂ©fixe bc_ optionnel)';

  @override
  String get action_static_badge => '(statique)';

  @override
  String get action_status_disabled => 'DÃƒÂ©sactivÃƒÂ©';

  @override
  String get action_status_enabled => 'ActivÃƒÂ©';

  @override
  String get action_store_results =>
      'Stocker les rÃƒÂ©sultats dans les variables globales';

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
      'Ajoutez une action, puis ouvrez-la pour configurer les dÃƒÂ©tails.';

  @override
  String get actions_empty_title => 'Aucune action';

  @override
  String get actions_builder_title => 'Constructeur d\'actions';

  @override
  String get actions_description =>
      'Construire les actions d\'exÃƒÂ©cution pour cette commande';

  @override
  String get actions_global_variables => 'Variables globales';

  @override
  String actions_key_label(String key) {
    return 'ClÃƒÂ© : $key';
  }

  @override
  String actions_missing_field_content(String action, String field) {
    return '\"$action\" : \"$field\" est requis.';
  }

  @override
  String get actions_missing_field_title => 'Champ requis manquant';

  @override
  String get actions_no_matches =>
      'Aucune action ne correspond ÃƒÂ  votre recherche.';

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
      'Rechercher des actions dans cette sÃƒÂ©quence...';

  @override
  String actions_sequence_count(int count) {
    return '$count action(s) dans la sÃƒÂ©quence';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Ãƒâ€°tape $index/$total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'Script BDFD | $lines ligne(s) | $diagnostics diagnostic(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count action(s) configurÃƒÂ©e(s)';
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
      'Pour respecter le RGPD, nous avons besoin de votre consentement avant d\'afficher des publicitÃƒÂ©s. Vous pouvez continuer ÃƒÂ  utiliser l\'application mÃƒÂªme en refusant.';

  @override
  String get ads_consent_refuse => 'Je refuse';

  @override
  String get ads_consent_refused_info =>
      'Consentement pub refusÃƒÂ©. Le bot dÃƒÂ©marre normalement.';

  @override
  String get ads_consent_title => 'Consentement publicitaire';

  @override
  String get app_bot_token => 'Token du bot';

  @override
  String get app_create_button => 'CrÃƒÂ©er une application';

  @override
  String get app_create_hero_desc =>
      'Un parcours guidÃƒÂ© pour ouvrir les bonnes pages, copier votre token et importer le bot proprement.';

  @override
  String get app_create_hero_title => 'Connectez votre bot Discord';

  @override
  String get app_create_new => 'CrÃƒÂ©er une nouvelle application';

  @override
  String get app_create_page_title => 'CrÃƒÂ©er une application';

  @override
  String get app_enter_token => 'Entrez votre token du bot ici';

  @override
  String get app_external_link_badge => 'Lien externe';

  @override
  String get app_hide_token => 'Masquer le token';

  @override
  String get app_how_to_create_token => 'Comment crÃƒÂ©er un token de bot ?';

  @override
  String get app_loading_error => 'Erreur de chargement';

  @override
  String get app_no_apps => 'Vous n\'avez pas encore d\'applications.';

  @override
  String get app_note =>
      'Remarque: Vous devez crÃƒÂ©er une nouvelle application sur Discord Developer Portal et obtenir le token du bot.';

  @override
  String get app_open_discord_portal => 'Ouvrir Discord Developer Portal';

  @override
  String get app_open_discord_portal_desc =>
      'CrÃƒÂ©ez votre application et activez la section bot.';

  @override
  String get app_open_link_error => 'Impossible d\'ouvrir cette page externe.';

  @override
  String get app_open_token_tutorial => 'Lire le tutoriel du token';

  @override
  String get app_open_token_tutorial_desc =>
      'Un guide pas ÃƒÂ  pas pour gÃƒÂ©nÃƒÂ©rer et copier votre token de bot.';

  @override
  String get app_resources_desc =>
      'Ces actions ouvrent les pages officielles nÃƒÂ©cessaires avant d\'enregistrer votre bot ici.';

  @override
  String get app_resources_title => 'Parcours guidÃƒÂ©';

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
      'Ce bot est dÃƒÂ©jÃƒÂ  enregistrÃƒÂ© sur Bot Creator Manager. Connectez-vous avec Discord pour synchroniser tous vos bots automatiquement ?';

  @override
  String get app_sync_manager_manual => 'Garder local';

  @override
  String get app_sync_manager_title => 'Bot dÃƒÂ©jÃƒÂ  gÃƒÂ©rÃƒÂ©';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_invalid_content =>
      'Le token semble avoir ÃƒÂ©tÃƒÂ© rÃƒÂ©initialisÃƒÂ©. Veuillez fournir le nouveau token depuis le Discord Developer Portal.';

  @override
  String get app_token_invalid_title =>
      'RÃƒÂ©initialisation du token dÃƒÂ©tectÃƒÂ©e';

  @override
  String get app_token_field_helper =>
      'Collez le token exactement tel que fourni par Discord.';

  @override
  String get app_token_section_desc =>
      'Une fois le token copiÃƒÂ©, collez-le ci-dessous pour ajouter votre bot ÃƒÂ  l\'application.';

  @override
  String get app_token_section_title => 'Collez votre token de bot';

  @override
  String get app_token_security_hint =>
      'Gardez ce token privÃƒÂ©. Toute personne qui le possÃƒÂ¨de peut contrÃƒÂ´ler votre bot.';

  @override
  String get autocomplete_dynamic => 'AutocomplÃƒÂ©tion dynamique';

  @override
  String get autocomplete_dynamic_desc =>
      'RÃƒÂ©soudre les choix depuis un workflow au lieu de valeurs statiques.';

  @override
  String get autocomplete_filter_hint =>
      'Les suggestions sont filtrÃƒÂ©es selon ce que l\'utilisateur tape.';

  @override
  String get autocomplete_loading => 'Chargement des workflows...';

  @override
  String get autocomplete_no_workflows =>
      'Aucun workflow sauvegardÃƒÂ© trouvÃƒÂ©';

  @override
  String get autocomplete_select_workflow =>
      'SÃƒÂ©lectionnez un workflow sauvegardÃƒÂ©';

  @override
  String get autocomplete_type_name => 'Ou tapez le nom du workflow';

  @override
  String get autocomplete_workflow_label => 'Workflow d\'autocomplÃƒÂ©tion';

  @override
  String backup_completed(String id) {
    return 'Sauvegarde terminÃƒÂ©e : $id';
  }

  @override
  String backup_failed(String error) {
    return 'Sauvegarde ÃƒÂ©chouÃƒÂ©e : $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Ce script BDFD n\'a pas pu ÃƒÂªtre compilÃƒÂ© :\n$summary';
  }

  @override
  String get bdfd_compile_error_simple =>
      'Ce script BDFD n\'a pas pu ÃƒÂªtre compilÃƒÂ©.';

  @override
  String get bdfd_compiled_no_actions =>
      'Ce script BDFD a ÃƒÂ©tÃƒÂ© compilÃƒÂ© avec succÃƒÂ¨s mais n\'a produit aucune action.';

  @override
  String get bdfd_docs_category_channels => 'Salons & Threads';

  @override
  String get bdfd_docs_category_components => 'Composants';

  @override
  String get bdfd_docs_category_control => 'Flux de contrÃƒÂ´le';

  @override
  String get bdfd_docs_category_cooldowns => 'Cooldowns';

  @override
  String get bdfd_docs_category_embeds => 'Embeds';

  @override
  String get bdfd_docs_category_guards => 'Gardes & Permissions';

  @override
  String get bdfd_docs_category_http => 'RequÃƒÂªtes HTTP';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_leaderboards => 'Classements';

  @override
  String get bdfd_docs_category_math => 'MathÃƒÂ©matiques';

  @override
  String get bdfd_docs_category_messages => 'Messages & Contenu';

  @override
  String get bdfd_docs_category_misc => 'Autres';

  @override
  String get bdfd_docs_category_modals => 'Modales';

  @override
  String get bdfd_docs_category_moderation => 'ModÃƒÂ©ration';

  @override
  String get bdfd_docs_category_reactions => 'RÃƒÂ©actions';

  @override
  String get bdfd_docs_category_roles => 'RÃƒÂ´les';

  @override
  String get bdfd_docs_category_text => 'Texte & ChaÃƒÂ®nes';

  @override
  String get bdfd_docs_category_tickets => 'Tickets';

  @override
  String get bdfd_docs_category_variables => 'Variables';

  @override
  String get bdfd_docs_category_webhooks => 'Webhooks';

  @override
  String get bdfd_docs_desc_and =>
      'ET logique Ã¢â‚¬â€ combine plusieurs conditions. Toutes doivent ÃƒÂªtre vraies.\n\nUtilisation : \$if[\$and[\$authorID==123;\$hasRole[456]]]';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'Enregistre un callback qui attend une rÃƒÂ©ponse utilisateur.\n\nUtilisation : \$awaitFunc[nom;userID (opt);channelID (opt)]\n\nLa fonction attendue est stockÃƒÂ©e et dÃƒÂ©clenchÃƒÂ©e quand l\'utilisateur cible envoie un message dans le salon cible.';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Bot Creator uniquement Ã¢â‚¬â€ Appelle un autre workflow par nom et transmet des arguments.\n\nSyntaxe : \$callWorkflow[monWorkflow;clÃƒÂ©1=valeur1;clÃƒÂ©2=valeur2]\n\nLe workflow appelÃƒÂ© peut lire les arguments et retourner une valeur via \$workflowResponse.';

  @override
  String get bdfd_docs_desc_defer =>
      'DiffÃƒÂ¨re la rÃƒÂ©ponse ÃƒÂ  l\'interaction, vous donnant plus de temps. L\'utilisateur voit Ã‚Â« Le bot rÃƒÂ©flÃƒÂ©chit... Ã‚Â». Ãƒâ‚¬ utiliser avant les opÃƒÂ©rations longues comme les requÃƒÂªtes HTTP.';

  @override
  String get bdfd_docs_desc_elseif =>
      'Ajoute une condition alternative dans un bloc \$if. Doit apparaÃƒÂ®tre entre \$if et \$else/\$endif.';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      'Identique ÃƒÂ  \$suppressErrors Ã¢â‚¬â€ supprime tous les messages d\'erreur silencieusement.';

  @override
  String get bdfd_docs_desc_ephemeral =>
      'Rend la rÃƒÂ©ponse visible uniquement pour l\'utilisateur qui a dÃƒÂ©clenchÃƒÂ© la commande. Doit ÃƒÂªtre placÃƒÂ© avant tout contenu de rÃƒÂ©ponse.';

  @override
  String get bdfd_docs_desc_eval =>
      'ExÃƒÂ©cute une chaÃƒÂ®ne de script BDFD au runtime. Le code passÃƒÂ© en argument est recompilÃƒÂ© et exÃƒÂ©cutÃƒÂ© dynamiquement. Utile pour exÃƒÂ©cuter des scripts basÃƒÂ©s sur des variables.';

  @override
  String get bdfd_docs_desc_for =>
      'Bot Creator uniquement Ã¢â‚¬â€ RÃƒÂ©pÃƒÂ¨te un bloc de code N fois.\n\nSimple : \$for[5]...\$endfor Ã¢â€ â€™ le corps est rÃƒÂ©pÃƒÂ©tÃƒÂ© 5 fois (max 100). Utilisez \$i pour l\'index courant (ÃƒÂ  partir de 0) et \$loopCount pour le total.\n\nStyle C : \$for[i=0;i<10;i++]...\$endfor Ã¢â€ â€™ boucle for classique avec init, condition et mise ÃƒÂ  jour. Supporte ++, --, +=, -=, *=.\n\nSi le nombre d\'itÃƒÂ©rations est dynamique (ex : \$for[\$args[1]]), la boucle s\'exÃƒÂ©cute au runtime.';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      'Ajoute un en-tÃƒÂªte ÃƒÂ  la prochaine requÃƒÂªte HTTP. Les en-tÃƒÂªtes s\'accumulent jusqu\'au prochain \$httpGet/\$httpPost/etc.\n\nUtilisation : \$httpAddHeader[Authorization;Bearer token123]';

  @override
  String get bdfd_docs_desc_httpget =>
      'Envoie une requÃƒÂªte HTTP GET ÃƒÂ  l\'URL donnÃƒÂ©e. Utilisez \$httpAddHeader avant pour dÃƒÂ©finir les en-tÃƒÂªtes. Utilisez \$httpResult pour lire la rÃƒÂ©ponse.\n\nToutes les mÃƒÂ©thodes HTTP (GET, POST, PUT, PATCH, DELETE) suivent le mÃƒÂªme schÃƒÂ©ma.';

  @override
  String get bdfd_docs_desc_httpresult =>
      'Retourne le corps de la derniÃƒÂ¨re rÃƒÂ©ponse HTTP. Passez optionnellement un chemin JSON pour extraire un champ.\n\nUtilisation : \$httpResult[] pour le corps complet, ou \$httpResult[data.name] pour un champ imbriquÃƒÂ©.';

  @override
  String get bdfd_docs_desc_if =>
      'Bloc conditionnel. Supporte l\'imbrication et des opÃƒÂ©rateurs riches : ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUtilisation :\n\$if[\$authorID==123456]\n  Bonjour admin !\n\$elseif[\$hasRole[789]]\n  Bonjour membre !\n\$else\n  Bonjour invitÃƒÂ© !\n\$endif';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'Parse une chaÃƒÂ®ne JSON en mÃƒÂ©moire pour manipulation. Toutes les opÃƒÂ©rations JSON (\$jsonSet, \$json, etc.) agissent sur ce contexte.\n\nLe JSON statique est rÃƒÂ©solu au compile-time pour de meilleures performances.';

  @override
  String get bdfd_docs_desc_jsonset =>
      'DÃƒÂ©finit une valeur dans le contexte JSON courant. Supporte les chemins en notation pointÃƒÂ©e.\n\nUtilisation : \$jsonSet[user.name;John]\n\nLa modification est en mÃƒÂ©moire Ã¢â‚¬â€ utilisez \$jsonStringify pour obtenir le rÃƒÂ©sultat.';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      'Convertit le contexte JSON courant en chaÃƒÂ®ne de caractÃƒÂ¨res. Ãƒâ‚¬ utiliser aprÃƒÂ¨s \$jsonParse et \$jsonSet pour obtenir le rÃƒÂ©sultat.';

  @override
  String get bdfd_docs_desc_loop =>
      'Bot Creator uniquement Ã¢â‚¬â€ Alias de \$for. Voir \$for pour les dÃƒÂ©tails. Utilisez \$endloop pour fermer le bloc.';

  @override
  String get bdfd_docs_desc_or =>
      'OU logique Ã¢â‚¬â€ combine plusieurs conditions. Au moins une doit ÃƒÂªtre vraie.\n\nUtilisation : \$if[\$or[\$authorID==123;\$authorID==456]]]';

  @override
  String get bdfd_docs_desc_stop =>
      'ArrÃƒÂªte immÃƒÂ©diatement l\'exÃƒÂ©cution du script. Aucune action aprÃƒÂ¨s \$stop ne sera exÃƒÂ©cutÃƒÂ©e.';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'EmpÃƒÂªche l\'envoi des messages d\'erreur ÃƒÂ  l\'utilisateur. Si une action ÃƒÂ©choue, l\'erreur est supprimÃƒÂ©e silencieusement.';

  @override
  String get bdfd_docs_desc_try =>
      'Encadre un bloc pour la gestion d\'erreurs.\n\nUtilisation :\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  La requÃƒÂªte a ÃƒÂ©chouÃƒÂ© !\n\$endtry\n\nSi une fonction du bloc \$try ÃƒÂ©choue, l\'exÃƒÂ©cution passe au \$catch.';

  @override
  String get bdfd_docs_desc_url =>
      'Encode ou dÃƒÂ©code du texte pour une utilisation dans les URLs. Utilisez \'encode\' pour rendre le texte sÃƒÂ»r pour les URLs, ou \'decode\' pour l\'opÃƒÂ©ration inverse.\n\nUtilisation : \$url[encode;Hello world!!]';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Bot Creator uniquement Ã¢â‚¬â€ Retourne la rÃƒÂ©ponse du dernier \$callWorkflow.\n\nUtilisez \$workflowResponse[] pour la rÃƒÂ©ponse complÃƒÂ¨te, ou \$workflowResponse[propriÃƒÂ©tÃƒÂ©] pour un champ spÃƒÂ©cifique.';

  @override
  String get bdfd_docs_empty => 'Aucune fonction trouvÃƒÂ©e.';

  @override
  String get bdfd_docs_no_params =>
      'Aucun paramÃƒÂ¨tre Ã¢â‚¬â€ utiliser comme \$nomFonction';

  @override
  String get bdfd_docs_parameters => 'PARAMÃƒË†TRES';

  @override
  String get bdfd_docs_search_hint => 'Rechercher une fonction...';

  @override
  String get bdfd_docs_syntax => 'SYNTAXE';

  @override
  String get bdfd_docs_title => 'Docs BDFD';

  @override
  String get bdfd_editor_auto_indent =>
      'Ã¢â€šÂ¬Ã‚Â¢ Indentation automatique intelligente sur EntrÃƒÂ©e';

  @override
  String get bdfd_editor_diagnostics_toggle =>
      'Afficher/masquer le panneau de diagnostics';

  @override
  String get bdfd_editor_docs => 'RÃƒÂ©fÃƒÂ©rence des fonctions BDFD';

  @override
  String get bdfd_editor_empty =>
      'Script vide Ã¢â‚¬â€ commencez ÃƒÂ  ÃƒÂ©crire pour voir les diagnostics.';

  @override
  String get bdfd_editor_includes => 'Inclut :';

  @override
  String get bdfd_editor_indent_guides =>
      'Ã¢â€šÂ¬Ã‚Â¢ Guides d\'indentation en temps rÃƒÂ©el';

  @override
  String get bdfd_editor_quick_keys =>
      'Ã¢â€šÂ¬Ã‚Â¢ Touches rapides mobiles pour les symboles BDFD';

  @override
  String get bdfd_editor_tap_hint => 'Appuyez pour ouvrir l\'ÃƒÂ©diteur';

  @override
  String get bdfd_editor_title => 'Ãƒâ€°diteur BDFD';

  @override
  String get bdfd_editor_toggle_indent =>
      'Activer/dÃƒÂ©sactiver les guides d\'indentation';

  @override
  String get bdfd_editor_ux_title => 'UX de l\'ÃƒÂ©diteur';

  @override
  String get bdfd_editor_wrap_toggle =>
      'Activer/dÃƒÂ©sactiver le retour ÃƒÂ  la ligne';

  @override
  String get bdfd_runtime_execution_error =>
      'Une erreur est survenue lors de l\'exÃƒÂ©cution de ce script BDFD.';

  @override
  String get bot_home_create_command => 'CrÃƒÂ©er ma premiÃƒÂ¨re commande';

  @override
  String get bot_home_customize => 'Personnaliser mon bot';

  @override
  String get bot_home_delete => 'Supprimer l\'application';

  @override
  String get bot_home_delete_confirm =>
      'ÃƒÅ tes-vous sÃƒÂ»r de vouloir supprimer cette application ?';

  @override
  String get bot_home_invite => 'Inviter le bot';

  @override
  String get bot_home_invite_error =>
      'Impossible d\'ouvrir le lien d\'invitation';

  @override
  String get bot_home_ios_notice_content =>
      'En mode local, iOS peut suspendre l\'application en arriÃƒÂ¨re-plan. Le bot peut dÃƒÂ©marrer, mais le maintien de la connexion Discord n\'est pas garanti comme avec un Runner.';

  @override
  String get bot_home_ios_notice_title => 'Contrainte iOS locale';

  @override
  String get bot_home_log_desktop_stop => 'ArrÃƒÂªt du bot desktop demandÃƒÂ©';

  @override
  String get bot_home_log_start => 'DÃƒÂ©marrage du bot demandÃƒÂ©';

  @override
  String get bot_home_log_stop => 'ArrÃƒÂªt du bot demandÃƒÂ©';

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
      'Le service foreground n\'a pas dÃƒÂ©marrÃƒÂ©.';

  @override
  String get bot_home_start => 'Lancer le bot';

  @override
  String bot_home_start_error(String error) {
    return 'Impossible de dÃƒÂ©marrer : $error';
  }

  @override
  String get bot_home_starting => 'DÃƒÂ©marrage...';

  @override
  String get bot_home_stop => 'ArrÃƒÂªter le bot';

  @override
  String get bot_home_sync => 'Synchroniser l\'app';

  @override
  String get bot_home_sync_success =>
      'Application synchronisÃƒÂ©e avec succÃƒÂ¨s';

  @override
  String get bot_home_pull => 'TÃƒÂ©lÃƒÂ©charger du Cloud';

  @override
  String get bot_home_push => 'Envoyer vers le Cloud';

  @override
  String get bot_home_pull_success =>
      'Application tÃƒÂ©lÃƒÂ©chargÃƒÂ©e du cloud avec succÃƒÂ¨s';

  @override
  String get bot_home_push_success =>
      'Application envoyÃƒÂ©e vers le cloud avec succÃƒÂ¨s';

  @override
  String get bot_home_version_history => 'Historique des versions';

  @override
  String get bot_config_versions_title => 'Historique des versions';

  @override
  String get bot_config_versions_empty =>
      'Aucune version prÃƒÂ©cÃƒÂ©dente trouvÃƒÂ©e';

  @override
  String get bot_config_versions_restore => 'Restaurer';

  @override
  String get bot_config_versions_restore_confirm =>
      'Restaurer cette version ? Votre configuration actuelle sera sauvegardÃƒÂ©e d\'abord.';

  @override
  String get bot_config_versions_restored =>
      'Configuration restaurÃƒÂ©e avec succÃƒÂ¨s !';

  @override
  String get bot_config_versions_error =>
      'Ãƒâ€°chec du chargement des versions';

  @override
  String get bot_config_versions_restore_error =>
      'Ãƒâ€°chec de la restauration de la version';

  @override
  String get bot_home_pull_dialog_changes => 'Changements ÃƒÂ  appliquer :';

  @override
  String get bot_home_pull_dialog_local => 'Local (Appareil)';

  @override
  String get bot_home_pull_dialog_local_only =>
      'locale(s) uniquement (conservÃƒÂ©e(s))';

  @override
  String get bot_home_pull_dialog_local_preserved =>
      'commande(s) locale(s) absente(s) du cloud seront conservÃƒÂ©e(s).';

  @override
  String get bot_home_pull_dialog_new_commands => 'nouvelle(s) commande(s)';

  @override
  String get bot_home_pull_dialog_remote => 'Distant (Cloud)';

  @override
  String get bot_home_pull_dialog_unchanged => 'inchangÃƒÂ©e(s)';

  @override
  String get bot_home_pull_dialog_up_to_date =>
      'DÃƒÂ©jÃƒÂ  ÃƒÂ  jour Ã¢â‚¬â€ aucun changement nÃƒÂ©cessaire.';

  @override
  String get bot_home_pull_dialog_updated_commands =>
      'commande(s) mise(s) ÃƒÂ  jour';

  @override
  String get bot_home_push_refused_empty =>
      'Push refusÃƒÂ© : la configuration locale est vide ou corrompue. VÃƒÂ©rifiez vos commandes.';

  @override
  String get bot_home_token_invalid_content =>
      'Le token semble avoir ÃƒÂ©tÃƒÂ© rÃƒÂ©initialisÃƒÂ©. Veuillez fournir le nouveau token depuis le Discord Developer Portal. Voulez-vous quand mÃƒÂªme lancer le bot ?';

  @override
  String get bot_home_token_invalid_title =>
      'Le token semble avoir ÃƒÂ©tÃƒÂ© rÃƒÂ©initialisÃƒÂ©';

  @override
  String get bot_home_view_logs => 'Voir les logs du bot';

  @override
  String get bot_home_view_replay => 'Voir les replays du dÃƒÂ©bogueur';

  @override
  String get bot_home_view_stats => 'Voir les stats du bot';

  @override
  String get bot_logs_copied => 'Logs copiÃƒÂ©s';

  @override
  String get bot_logs_disable_debug => 'DÃƒÂ©sactiver les logs debug';

  @override
  String get bot_logs_empty => 'Aucun log pour le moment';

  @override
  String get bot_logs_enable_debug => 'Activer les logs debug';

  @override
  String get bot_logs_filter_count => 'Nombre de logs affichÃƒÂ©s';

  @override
  String get bot_logs_go_to_bottom => 'Aller en bas';

  @override
  String get bot_logs_go_to_latest => 'Aller au dernier log';

  @override
  String get bot_logs_newest_first => 'Afficher les plus rÃƒÂ©cents en premier';

  @override
  String get bot_logs_oldest_first => 'Afficher les plus anciens en premier';

  @override
  String bot_logs_ram(String memory) {
    return 'RAM du processus bot : $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'RAM bot estimÃƒÂ©e : $memory';
  }

  @override
  String get bot_logs_raw_mode => 'Logs bruts compacts';

  @override
  String get bot_logs_rich_mode => 'Logs formatÃƒÂ©s';

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
      'Ãƒâ€°tat de l\'activitÃƒÂ© (optionnel)';

  @override
  String get bot_settings_activity_url_label =>
      'URL de stream (pour streaming)';

  @override
  String get bot_settings_add_status => 'Ajouter une activitÃƒÂ©';

  @override
  String get bot_settings_app_flags => 'Indicateurs de l\'application';

  @override
  String get bot_settings_avatar_clear_selection => 'Effacer la selection';

  @override
  String get bot_settings_avatar_important_note =>
      'Important : Les changements de profil (nom et photo) ne seront appliquÃƒÂ©s sur Discord que lorsque vous cliquerez sur le bouton \'Sauvegarder le profil et les statuts\' tout en bas.';

  @override
  String get bot_settings_avatar_local_path => 'Chemin local de l\'avatar';

  @override
  String get bot_settings_avatar_none_selected =>
      'Aucune nouvelle image sÃƒÂ©lectionnÃƒÂ©e. Cliquez sur Parcourir pour en choisir une.';

  @override
  String get bot_settings_avatar_path_hint => '/chemin/absolu/vers/avatar.png';

  @override
  String get bot_settings_avatar_preview_error =>
      'Impossible d\'afficher l\'aperÃƒÂ§u de l\'image';

  @override
  String get bot_settings_avatar_preview_label => 'Apercu de l\'avatar';

  @override
  String get bot_settings_avatar_selected =>
      'Nouvelle image sÃƒÂ©lectionnÃƒÂ©e :';

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
  String get bot_settings_delete_bot_btn => 'Supprimer dÃƒÂ©finitivement';

  @override
  String get bot_settings_delete_bot_desc =>
      'Cette action est irrÃƒÂ©versible. Toutes les donnÃƒÂ©es locales et les configurations distantes seront supprimÃƒÂ©es.';

  @override
  String bot_settings_delete_desc(String id) {
    return 'Voulez-vous vraiment supprimer le bot $id ? Toutes les donnÃƒÂ©es seront perdues.';
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
      'SÃƒÂ©lectionnez les intents dont votre bot a besoin. Configurez-les sur le Discord Developer Portal.';

  @override
  String get bot_settings_intents_saved => 'Intents sauvegardes avec succes';

  @override
  String get bot_settings_lavalink_choose_server =>
      'Choisir un serveur public...';

  @override
  String get bot_settings_lavalink_host => 'HÃƒÂ´te';

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
      'DÃƒÂ©bloquez le support audio Lavalink pour votre bot.';

  @override
  String get bot_settings_lavalink_premium_banner_title =>
      'Ã°Å¸â€â€™ Disponible avec Bot Creator PREMIUM';

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
    return 'Port $port Ã¢â‚¬â€ $version';
  }

  @override
  String bot_settings_lavalink_servers_available(int count) {
    return '$count serveurs disponibles';
  }

  @override
  String get bot_settings_lavalink_ssl => 'Utiliser SSL/TLS';

  @override
  String get bot_settings_lavalink_ssl_subtitle =>
      'Connexion sÃƒÂ©curisÃƒÂ©e wss://';

  @override
  String get bot_settings_lavalink_success => 'Connexion rÃƒÂ©ussie !';

  @override
  String get bot_settings_lavalink_test_btn => 'Tester la connexion';

  @override
  String get bot_settings_lavalink_testing => 'Test en cours...';

  @override
  String get bot_settings_lavalink_view_offers => 'Voir les offres';

  @override
  String get bot_settings_no_activities => 'Aucune activitÃƒÂ© configurÃƒÂ©e';

  @override
  String get bot_settings_presence_dnd => 'Ne pas dÃƒÂ©ranger';

  @override
  String get bot_settings_presence_idle => 'Absent (Inactif)';

  @override
  String get bot_settings_presence_invisible => 'Invisible';

  @override
  String get bot_settings_presence_online => 'En ligne';

  @override
  String get bot_settings_presence_status_label => 'PrÃƒÂ©sence';

  @override
  String get bot_settings_presence_status_title =>
      'Statut de PrÃƒÂ©sence du Bot';

  @override
  String get bot_settings_profile_saved =>
      'Profil/statuts appliquÃƒÂ©s avec succÃƒÂ¨s';

  @override
  String get bot_settings_profile_title => 'Profil du bot';

  @override
  String get bot_settings_remove_status => 'Supprimer l\'activitÃƒÂ©';

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
  String get bot_settings_save_success =>
      'ParamÃƒÂ¨tres enregistrÃƒÂ©s avec succÃƒÂ¨s';

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
    return 'ActivitÃƒÂ© $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Intervalle max (s)';

  @override
  String get bot_settings_status_min_interval => 'Intervalle min (s)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Ajoutez une ou plusieurs activitÃƒÂ©s. Chaque activitÃƒÂ© nÃƒÂ©cessite un type, un nom et un intervalle min/max (secondes).';

  @override
  String get bot_settings_status_rotation_title => 'Rotation des activitÃƒÂ©s';

  @override
  String get bot_settings_status_text_label => 'Nom de l\'activitÃƒÂ©';

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
  String get bot_settings_tab_advanced => 'AvancÃƒÂ© & Maintenance';

  @override
  String get bot_settings_tab_general => 'GÃƒÂ©nÃƒÂ©ral';

  @override
  String get bot_settings_tab_intents => 'Intents & PrivilÃƒÂ¨ges';

  @override
  String get bot_settings_tab_lavalink => 'Lavalink';

  @override
  String get bot_settings_tab_presence => 'PrÃƒÂ©sence & Statut';

  @override
  String get bot_settings_title => 'Personnaliser le bot / Profil';

  @override
  String get bot_settings_token_hidden_desc =>
      'Le champ du token est masque par defaut pour plus de securite.';

  @override
  String get bot_settings_token_hint => 'Entrez votre token de bot ici';

  @override
  String get bot_settings_token_mismatch_confirm =>
      'Remplacer le token quand mÃƒÂªme';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Ce token appartient au bot $newId, mais les donnÃƒÂ©es actuelles concernent le bot $oldId. Les commandes et paramÃƒÂ¨tres peuvent ne pas correspondre. Continuer quand mÃƒÂªme ?';
  }

  @override
  String get bot_settings_token_mismatch_title =>
      'Bot diffÃƒÂ©rent dÃƒÂ©tectÃƒÂ©';

  @override
  String get bot_settings_token_required => 'Le token du bot est requis.';

  @override
  String get bot_settings_token_saved => 'Token sauvegarde avec succes';

  @override
  String get bot_settings_token_title => 'Token du bot';

  @override
  String get bot_settings_update_token => 'Mettre ÃƒÂ  jour le token du bot';

  @override
  String get bot_settings_username_hint =>
      'Laisser vide pour conserver le nom d\'utilisateur actuel';

  @override
  String get bot_settings_username_override =>
      'Nom d\'utilisateur personnalisÃƒÂ©';

  @override
  String get bot_settings_workflow_docs => 'Centre de documentation';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Documentation centralisÃƒÂ©e pour les commandes, workflows, variables runtime et comportement d\'exÃƒÂ©cution.';

  @override
  String get bot_stats_collecting => 'Collecte...';

  @override
  String get bot_stats_cpu => 'CPU du processus bot';

  @override
  String get bot_stats_notes =>
      'Notes : CPU disponible sur Android/Linux. Stockage = fichiers de donnÃƒÂ©es du bot dans l\'application.';

  @override
  String get bot_stats_ram_estimated => 'RAM bot uniquement (estimÃƒÂ©e)';

  @override
  String get bot_stats_ram_process => 'RAM du processus bot';

  @override
  String get bot_stats_source_local_hosting => 'Source : hÃƒÂ©bergement local';

  @override
  String get bot_stats_source_runner_api => 'Source : API Runner';

  @override
  String get bot_stats_storage => 'Stockage du bot (donnÃƒÂ©es app)';

  @override
  String get bot_stats_title => 'Statistiques du bot';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Tapez \$ puis le dÃƒÂ©but d\'une fonction pour afficher des suggestions rapides.';

  @override
  String get cmd_bdfd_autocomplete_title =>
      'Auto-complÃƒÂ©tion BDFD par prÃƒÂ©fixe';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Aucun problÃƒÂ¨me dÃƒÂ©tectÃƒÂ© dans le script courant.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Erreur';

  @override
  String get cmd_bdfd_diagnostics_title => 'Diagnostics BDFD';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Avertissement';

  @override
  String get cmd_bdfd_script_empty_error =>
      'Le corps du script BDFD ne peut pas ÃƒÂªtre vide.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'Corps du script BDFD';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Ce script BDFD contient encore des diagnostics :';

  @override
  String get cmd_create_tooltip => 'CrÃƒÂ©er la commande';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Aucun problÃƒÂ¨me dÃƒÂ©tectÃƒÂ© dans le script Dart courant.';

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
    return '$count commandes supprimÃƒÂ©es';
  }

  @override
  String cmd_delete_confirm(Object name) {
    return 'Supprimer la commande \"$name\" ?';
  }

  @override
  String cmd_delete_success(Object name) {
    return 'Commande \"$name\" supprimÃƒÂ©e';
  }

  @override
  String get cmd_delete_tooltip => 'Supprimer la commande';

  @override
  String get cmd_deploy_close_button => 'Fermer';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'Synchronisation sÃƒÂ©curisÃƒÂ©e dans votre espace en ligne';

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
  String get cmd_deploy_failed_title => 'Ãƒâ€°chec du dÃƒÂ©ploiement';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'Mise ÃƒÂ  jour instantanÃƒÂ©e du runner de votre bot';

  @override
  String get cmd_deploy_hot_reload_title => 'Rechargement ÃƒÂ  chaud';

  @override
  String get cmd_deploy_in_progress_title => 'DÃƒÂ©ploiement en cours...';

  @override
  String get cmd_deploy_local_save_subtitle =>
      'Enregistrement de la commande sur l\'appareil';

  @override
  String get cmd_deploy_local_save_title => 'Sauvegarde locale';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Application ÃƒÂ  chaud de la configuration';

  @override
  String get cmd_deploy_reload_bot_title => 'Rechargement du Bot';

  @override
  String get cmd_deploy_retry_button => 'RÃƒÂ©essayer';

  @override
  String get cmd_deploy_success_title => 'DÃƒÂ©ploiement rÃƒÂ©ussi !';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'Commande \"$name\" dÃƒÂ©ployÃƒÂ©e et active !';
  }

  @override
  String get cmd_editor_mode_advanced => 'Mode avancÃƒÂ©';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Ãƒâ€°diteur complet avec rÃƒÂ©ponse personnalisÃƒÂ©e, options et builder d\'actions.';

  @override
  String get cmd_editor_mode_locked =>
      'Le mode avancÃƒÂ© est verrouillÃƒÂ© pour cette commande.';

  @override
  String get cmd_editor_mode_simple => 'Mode simplifiÃƒÂ©';

  @override
  String get cmd_editor_mode_simple_desc =>
      'CrÃƒÂ©ez une commande rapidement avec des options guidÃƒÂ©es et des actions prÃƒÂ©configurÃƒÂ©es.';

  @override
  String get cmd_editor_mode_switch_adv => 'Passer en mode avancÃƒÂ©';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Passer';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Ce changement est dÃƒÂ©finitif pour cette commande. Vous ne pourrez plus revenir au mode simplifiÃƒÂ©.';

  @override
  String get cmd_editor_mode_switch_adv_title =>
      'Passer en mode avancÃƒÂ©Ã‚Â ?';

  @override
  String get cmd_editor_mode_title => 'Mode d\'ÃƒÂ©dition';

  @override
  String get cmd_error_fill_fields => 'Veuillez remplir tous les champs';

  @override
  String get cmd_execution_mode_bdfd => 'Mode script BDFD';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Ãƒâ€°crivez le corps de commande en script compatible BDFD tout en gardant la dÃƒÂ©finition visuelle.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'Le script est compilÃƒÂ© en actions internes. Les diagnostics sont affichÃƒÂ©s pendant l\'ÃƒÂ©dition ; les scripts invalides ÃƒÂ©chouent ÃƒÂ  l\'exÃƒÂ©cution.';

  @override
  String get cmd_execution_mode_dart => 'Mode Dart Direct';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Ãƒâ€°crivez directement le corps de commande en Dart avec diagnostics runtime.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Le code Dart est compilÃƒÂ© au runtime via un moteur sandboxÃƒÂ©. Gardez les scripts dÃƒÂ©terministes et retournez une valeur quand nÃƒÂ©cessaire.';

  @override
  String get cmd_execution_mode_javascript => 'JavaScript';

  @override
  String get cmd_execution_mode_javascript_desc =>
      'Ãƒâ€°crire du code JS personnalisÃƒÂ© pour cette commande.';

  @override
  String get cmd_execution_mode_javascript_note =>
      'Toutes les fonctions BDFD sont disponibles comme fonctions JS asynchrones. Utilisez ctx.authorId, ctx.channelId, vars[\'key\'] pour accÃƒÂ©der au contexte et aux variables.';

  @override
  String get cmd_execution_mode_desc =>
      'La dÃƒÂ©finition de commande reste dans le builder visuel. Choisissez ensuite comment exÃƒÂ©cuter le corps de la commande.';

  @override
  String get cmd_execution_mode_title => 'Mode d\'exÃƒÂ©cution';

  @override
  String get cmd_execution_mode_workflow => 'Mode workflow';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Utilise le builder visuel actuel pour la rÃƒÂ©ponse et les actions.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'Le mode workflow reste le chemin de production actuel et continue d\'ÃƒÂªtre totalement pris en charge.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrer';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'GÃƒÂ©nÃƒÂ©rer un squelette de migration Dart ÃƒÂ  partir du script BDFD actuel.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Cette commande n\'a pas pu ÃƒÂªtre entiÃƒÂ¨rement chargÃƒÂ©e (hors-ligne ou token invalide). Connectez un token valide pour modifier.';

  @override
  String get cmd_show_variables => 'Ouvrir la documentation des variables';

  @override
  String get cmd_simple_action_add_role => 'Ajouter un rÃƒÂ´le';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Attribue le /role sÃƒÂ©lectionnÃƒÂ© au /user sÃƒÂ©lectionnÃƒÂ©.';

  @override
  String get cmd_simple_action_ban => 'Bannir un utilisateur';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      'De 0 ÃƒÂ  7 jours de messages rÃƒÂ©cents';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Jours de messages ÃƒÂ  supprimer au ban';

  @override
  String get cmd_simple_action_ban_desc =>
      'Bannit le /user sÃƒÂ©lectionnÃƒÂ© du serveur.';

  @override
  String get cmd_simple_action_create_invite => 'CrÃƒÂ©er une invitation';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'CrÃƒÂ©e une invitation pour le salon courant ou un /channel optionnel.';

  @override
  String get cmd_simple_action_create_poll => 'CrÃƒÂ©er un sondage';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'CrÃƒÂ©e un sondage avec une /question dynamique et des rÃƒÂ©ponses fixes.';

  @override
  String get cmd_simple_action_delete => 'Supprimer des messages';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'UtilisÃƒÂ© si /count n\'est pas fourni';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Nombre par dÃƒÂ©faut ÃƒÂ  supprimer';

  @override
  String get cmd_simple_action_delete_desc =>
      'Supprime des messages dans le salon courant (option /count).';

  @override
  String get cmd_simple_action_kick => 'Expulser un utilisateur';

  @override
  String get cmd_simple_action_kick_desc =>
      'Expulse le /user sÃƒÂ©lectionnÃƒÂ© du serveur.';

  @override
  String get cmd_simple_action_mute => 'Rendre muet un utilisateur';

  @override
  String get cmd_simple_action_mute_desc =>
      'Rend temporairement muet le /user sÃƒÂ©lectionnÃƒÂ©.';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Exemples : 10m, 2h, 1d, ou secondes brutes';

  @override
  String get cmd_simple_action_mute_duration_label => 'DurÃƒÂ©e du mute';

  @override
  String get cmd_simple_action_pin => 'Ãƒâ€°pingler un message';

  @override
  String get cmd_simple_action_pin_desc =>
      'Ãƒâ€°pingle un message du salon courant via /message_id.';

  @override
  String get cmd_simple_action_reason_hint =>
      'Raison optionnelle partagÃƒÂ©e par les actions de modÃƒÂ©ration';

  @override
  String get cmd_simple_action_reason_label => 'Raison du log d\'audit';

  @override
  String get cmd_simple_action_remove_role => 'Retirer un rÃƒÂ´le';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Retire le /role sÃƒÂ©lectionnÃƒÂ© du /user sÃƒÂ©lectionnÃƒÂ©.';

  @override
  String get cmd_simple_action_send_message => 'Envoyer un message';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Envoie un message supplÃƒÂ©mentaire dans le salon courant.';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Message envoyÃƒÂ© par l\'action Send Message';

  @override
  String get cmd_simple_action_send_message_label => 'Message de l\'action';

  @override
  String get cmd_simple_action_unban => 'DÃƒÂ©bannir un utilisateur';

  @override
  String get cmd_simple_action_unban_desc =>
      'DÃƒÂ©bannit un utilisateur via une chaÃƒÂ®ne /user_id.';

  @override
  String get cmd_simple_action_unmute => 'Retirer le mute';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Retire le timeout du /user sÃƒÂ©lectionnÃƒÂ©.';

  @override
  String get cmd_simple_action_unpin => 'DÃƒÂ©sÃƒÂ©pingler un message';

  @override
  String get cmd_simple_action_unpin_desc =>
      'DÃƒÂ©sÃƒÂ©pingle un message du salon courant via /message_id.';

  @override
  String get cmd_simple_actions_desc =>
      'SÃƒÂ©lectionnez ce que la commande doit faire. Les options sont gÃƒÂ©nÃƒÂ©rÃƒÂ©es automatiquement.';

  @override
  String get cmd_simple_actions_title => 'Actions simplifiÃƒÂ©es';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Bannir un utilisateur et DÃƒÂ©bannir un utilisateur ne peuvent pas ÃƒÂªtre activÃƒÂ©s ensemble en mode simplifiÃƒÂ©.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Rendre muet un utilisateur et Retirer le mute ne peuvent pas ÃƒÂªtre activÃƒÂ©s ensemble en mode simplifiÃƒÂ©.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Ãƒâ€°pingler un message et DÃƒÂ©sÃƒÂ©pingler un message ne peuvent pas ÃƒÂªtre activÃƒÂ©s ensemble en mode simplifiÃƒÂ©.';

  @override
  String get cmd_simple_execution_desc =>
      'Affinez les actions gÃƒÂ©nÃƒÂ©rÃƒÂ©es sans quitter le mode simplifiÃƒÂ©.';

  @override
  String get cmd_simple_execution_title => 'RÃƒÂ©glages d\'exÃƒÂ©cution';

  @override
  String get cmd_simple_generated_none =>
      'Aucune option gÃƒÂ©nÃƒÂ©rÃƒÂ©e pour le moment. SÃƒÂ©lectionnez au moins une action.';

  @override
  String get cmd_simple_generated_options =>
      'Options de commande gÃƒÂ©nÃƒÂ©rÃƒÂ©es';

  @override
  String get cmd_simple_group_messages_desc =>
      'Actions liÃƒÂ©es aux messages et au salon courant.';

  @override
  String get cmd_simple_group_messages_title => 'Messages';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Actions de modÃƒÂ©ration et de gestion des membres avec options guidÃƒÂ©es.';

  @override
  String get cmd_simple_group_moderation_title => 'ModÃƒÂ©ration';

  @override
  String get cmd_simple_group_utility_desc =>
      'Fonctions utiles comme les invitations et les sondages.';

  @override
  String get cmd_simple_group_utility_title => 'Utilitaires';

  @override
  String get cmd_simple_invite_max_age_hint =>
      '0 pour aucune expiration, jusqu\'ÃƒÂ  604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'L\'expiration de l\'invitation doit ÃƒÂªtre un nombre entre 0 et 604800 secondes.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'Expiration de l\'invitation (secondes)';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 pour illimitÃƒÂ©';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Le nombre max d\'utilisations doit ÃƒÂªtre un nombre entre 0 et 1000000.';

  @override
  String get cmd_simple_invite_max_uses_label => 'Nombre max d\'utilisations';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Valeurs par dÃƒÂ©faut utilisÃƒÂ©es par l\'action Create Invite gÃƒÂ©nÃƒÂ©rÃƒÂ©e.';

  @override
  String get cmd_simple_invite_settings_title => 'RÃƒÂ©glages de l\'invitation';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Le membre est retirÃƒÂ© s\'il quitte avant de recevoir un rÃƒÂ´le.';

  @override
  String get cmd_simple_invite_temporary_label => 'AdhÃƒÂ©sion temporaire';

  @override
  String get cmd_simple_invite_unique_desc =>
      'CrÃƒÂ©e toujours une nouvelle invitation au lieu d\'en rÃƒÂ©utiliser une.';

  @override
  String get cmd_simple_invite_unique_label => 'Forcer une invitation unique';

  @override
  String get cmd_simple_option_channel => '/channel (Salon)';

  @override
  String get cmd_simple_option_channel_desc =>
      'Salon optionnel pour crÃƒÂ©er l\'invitation';

  @override
  String get cmd_simple_option_count => '/count (Entier)';

  @override
  String get cmd_simple_option_count_desc =>
      'Nombre de messages ÃƒÂ  supprimer';

  @override
  String get cmd_simple_option_message_id => '/message_id (Texte)';

  @override
  String get cmd_simple_option_message_id_desc => 'ID du message ciblÃƒÂ©';

  @override
  String get cmd_simple_option_question => '/question (Texte)';

  @override
  String get cmd_simple_option_question_desc => 'Question du sondage';

  @override
  String get cmd_simple_option_role => '/role (RÃƒÂ´le)';

  @override
  String get cmd_simple_option_role_desc => 'RÃƒÂ´le ciblÃƒÂ©';

  @override
  String get cmd_simple_option_user => '/user (Utilisateur)';

  @override
  String get cmd_simple_option_user_desc => 'Utilisateur ciblÃƒÂ©';

  @override
  String get cmd_simple_option_user_id => '/user_id (Texte)';

  @override
  String get cmd_simple_option_user_id_desc =>
      'ID utilisateur ÃƒÂ  dÃƒÂ©bannir';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Une rÃƒÂ©ponse par ligne, ou sÃƒÂ©parÃƒÂ©es par des virgules. Minimum 2, maximum 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Le sondage doit contenir entre 2 et 10 rÃƒÂ©ponses non vides.';

  @override
  String get cmd_simple_poll_answers_label => 'RÃƒÂ©ponses du sondage';

  @override
  String get cmd_simple_poll_duration_hint => 'De 1 ÃƒÂ  168 heures';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'La durÃƒÂ©e du sondage doit ÃƒÂªtre un nombre entre 1 et 168 heures.';

  @override
  String get cmd_simple_poll_duration_label => 'DurÃƒÂ©e du sondage (heures)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Les utilisateurs peuvent sÃƒÂ©lectionner plus d\'un choix.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Autoriser plusieurs rÃƒÂ©ponses';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Valeurs par dÃƒÂ©faut utilisÃƒÂ©es par l\'action Create Poll gÃƒÂ©nÃƒÂ©rÃƒÂ©e.';

  @override
  String get cmd_simple_poll_settings_title => 'RÃƒÂ©glages du sondage';

  @override
  String get cmd_simple_response_desc =>
      'Message renvoyÃƒÂ© ÃƒÂ  l\'utilisateur aprÃƒÂ¨s l\'exÃƒÂ©cution des actions.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Embeds optionnels envoyÃƒÂ©s avec la rÃƒÂ©ponse finale.';

  @override
  String get cmd_simple_response_embeds_title => 'Embeds de rÃƒÂ©ponse';

  @override
  String get cmd_simple_response_hint => 'TerminÃƒÂ© Ã¢Å“â€¦';

  @override
  String get cmd_simple_response_title => 'RÃƒÂ©ponse finale';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Ãƒâ€°phÃƒÂ©mÃƒÂ¨re';

  @override
  String get cmd_simple_response_visibility_label =>
      'VisibilitÃƒÂ© de la rÃƒÂ©ponse';

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
      'Le nom de la commande est gÃƒÂ©nÃƒÂ©rÃƒÂ© et enregistrÃƒÂ© comme callback legacy interne.';

  @override
  String get command_awaited_success => 'SuccÃƒÂ¨s';

  @override
  String get command_context_bot_dm => 'MP du bot';

  @override
  String get command_context_group_dm => 'DM de groupe / Autre';

  @override
  String get command_context_guild => 'Serveur';

  @override
  String get command_description_length =>
      'La description de commande doit contenir au maximum 100 caractÃƒÂ¨res';

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
      'Une erreur est survenue lors de l\'exÃƒÂ©cution de cette commande.';

  @override
  String get command_export_tooltip => 'Exporter le payload de la commande';

  @override
  String get command_import_tooltip => 'Importer un payload de commande';

  @override
  String get command_info_desc => 'MÃƒÂ©tadonnÃƒÂ©es et disponibilitÃƒÂ©';

  @override
  String get command_info_title => 'Info de la commande';

  @override
  String get command_integration_guild => 'Installation serveur';

  @override
  String get command_integration_label =>
      'OÃƒÂ¹ cette commande peut ÃƒÂªtre utilisÃƒÂ©e';

  @override
  String get command_integration_user => 'Installation utilisateur';

  @override
  String get command_legacy_mode_subtitle =>
      'Utilise des options positionnelles (exemple : !config #channel).';

  @override
  String get command_legacy_mode_title =>
      'Activer le mode legacy sur cette commande';

  @override
  String get command_legacy_prefix_desc =>
      'GÃƒÂ©rer les commandes de messageCreate avec <prÃƒÂ©fixe><commande>.';

  @override
  String get command_legacy_prefix_title => 'Mode prÃƒÂ©fixe legacy';

  @override
  String get command_legacy_preset_desc =>
      'GÃƒÂ©nÃƒÂ©rer un dÃƒÂ©clencheur de callback attendu interne et basculer cette commande vers la configuration legacy locale requise.';

  @override
  String get command_legacy_preset_title => 'Preset legacy';

  @override
  String get command_legacy_response_label => 'Mode de rÃƒÂ©ponse legacy';

  @override
  String get command_modal_disabled_legacy =>
      'Les modals sont dÃƒÂ©sactivÃƒÂ©s en mode legacy.';

  @override
  String get command_name_generated =>
      'GÃƒÂ©nÃƒÂ©rÃƒÂ© par le preset de callback attendu.';

  @override
  String get command_name_label => 'Nom';

  @override
  String get command_not_found => 'Commande introuvable';

  @override
  String get command_options_legacy_params =>
      'ParamÃƒÂ¨tres positionnels legacy (ordre : requis puis optionnels)';

  @override
  String get command_options_slash_params => 'ParamÃƒÂ¨tres de commande slash';

  @override
  String get command_options_title => 'Options de commande';

  @override
  String get command_payload_hint => 'Payload de commande';

  @override
  String get command_permissions_admin_warning =>
      'Administrateur sÃƒÂ©lectionnÃƒÂ© : cela contourne les autres vÃƒÂ©rifications de permissions.';

  @override
  String get command_permissions_bitfield =>
      'Champ de bits de permission calculÃƒÂ©';

  @override
  String get command_permissions_bitfield_helper =>
      'CalculÃƒÂ© automatiquement ÃƒÂ  partir des permissions sÃƒÂ©lectionnÃƒÂ©es.';

  @override
  String command_permissions_count(int count) {
    return '$count permission(s) sÃƒÂ©lectionnÃƒÂ©e(s)';
  }

  @override
  String get command_permissions_label =>
      'Permissions membres par dÃƒÂ©faut (optionnel)';

  @override
  String get command_permissions_none =>
      'Aucune sÃƒÂ©lection (tout le monde peut utiliser la commande)';

  @override
  String get command_permissions_tip =>
      'Astuce : laissez tout dÃƒÂ©cochÃƒÂ© pour rendre la commande disponible ÃƒÂ  tous par dÃƒÂ©faut.';

  @override
  String get command_permissions_title => 'SÃƒÂ©lectionner les permissions';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Attention : bits de permission inconnus dÃƒÂ©tectÃƒÂ©s dans les donnÃƒÂ©es sauvegardÃƒÂ©es et prÃƒÂ©servÃƒÂ©s : $bits';
  }

  @override
  String get command_prefix_helper =>
      'Supporte les templates et variables scopÃƒÂ©es (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'Remplacement du prÃƒÂ©fixe (optionnel)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'PortÃƒÂ©e de la commande (Contextes)';

  @override
  String get command_subcommand_workflow_desc =>
      'Choisissez le sous-commande que vous configurez.';

  @override
  String get command_subcommand_workflow_title => 'Workflow SubCommand';

  @override
  String command_sync_failed_local(String error) {
    return 'EnregistrÃƒÂ© localement. Ãƒâ€°chec de la synchronisation Discord : $error';
  }

  @override
  String get command_target_subcommand => 'Sous-commande cible';

  @override
  String get command_type_label => 'Type de commande';

  @override
  String get command_type_legacy => 'Commande Legacy';

  @override
  String get command_type_locked =>
      'Le type de commande ne peut pas ÃƒÂªtre changÃƒÂ© aprÃƒÂ¨s la crÃƒÂ©ation.';

  @override
  String get command_type_message => 'Commande Message';

  @override
  String get command_type_slash => 'Commande Slash';

  @override
  String get command_type_user => 'Commande Utilisateur';

  @override
  String get command_unsaved_confirm =>
      'Vous avez des modifications non enregistrÃƒÂ©es. Les abandonner ?';

  @override
  String get command_unsaved_keep => 'Continuer l\'ÃƒÂ©dition';

  @override
  String get command_unsaved_title => 'Modifications non enregistrÃƒÂ©es';

  @override
  String get commands_all_folders => 'Tous les dossiers';

  @override
  String get commands_create_button => 'CrÃƒÂ©er une commande';

  @override
  String get commands_create_folder => 'CrÃƒÂ©er un dossier';

  @override
  String commands_create_from_query(String query) {
    return 'CrÃƒÂ©er la commande \"$query\"';
  }

  @override
  String get commands_delete_folder => 'Supprimer le dossier';

  @override
  String get commands_delete_folder_desc =>
      'Les commandes de ce dossier ne seront pas supprimÃƒÂ©es, juste retirÃƒÂ©es du dossier.';

  @override
  String get commands_empty => 'Aucune commande trouvÃƒÂ©e';

  @override
  String commands_error(String error) {
    return 'Erreur : $error';
  }

  @override
  String get commands_filter_legacy_local => 'Ancien local';

  @override
  String get commands_filter_template => 'ModÃƒÂ¨le';

  @override
  String get commands_filter_type_label => 'Type';

  @override
  String get commands_folder_hint => 'Nom du dossier (optionnel)';

  @override
  String get commands_folder_label => 'Dossier';

  @override
  String get commands_move_to_folder => 'DÃƒÂ©placer dans un dossier';

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
  String get common_custom_id => 'ID personnalisÃƒÂ©';

  @override
  String get common_custom_id_required => 'ID personnalisÃƒÂ© *';

  @override
  String get common_default => 'DÃƒÂ©faut';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_description => 'Description';

  @override
  String get common_disabled => 'DÃƒÂ©sactivÃƒÂ©';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_enabled => 'ActivÃƒÂ©';

  @override
  String get common_import => 'Importer';

  @override
  String get common_key => 'ClÃƒÂ©';

  @override
  String get common_label => 'LibellÃƒÂ©';

  @override
  String get common_manage_workflows => 'GÃƒÂ©rer les workflows';

  @override
  String get common_move_down => 'DÃƒÂ©placer vers le bas';

  @override
  String get common_move_up => 'DÃƒÂ©placer vers le haut';

  @override
  String get common_name => 'Nom';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_none => 'Aucun';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => 'OpÃƒÂ©rateur';

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
  String get common_retry => 'RÃƒÂ©essayer';

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
      'Ajouter un bouton / menu de sÃƒÂ©lection';

  @override
  String get component_add_checkbox_option => 'Ajouter une option checkbox';

  @override
  String get component_add_child => 'Ajouter un composant enfant';

  @override
  String get component_add_media_item => 'Ajouter un ÃƒÂ©lÃƒÂ©ment mÃƒÂ©dia';

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
  String get component_checked_by_default => 'CochÃƒÂ© par dÃƒÂ©faut';

  @override
  String get component_choose_color => 'Choisir la couleur';

  @override
  String get component_component_to_wrap => 'Composant ÃƒÂ  envelopper :';

  @override
  String get component_configure_click_actions => 'Configurer les actions';

  @override
  String get component_configure_select_actions =>
      'Configurer les actions de sélection';

  @override
  String get component_custom_id => 'ID personnalisÃƒÂ©';

  @override
  String get component_custom_id_required => 'ID personnalisÃƒÂ© *';

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
  String get component_label => 'LibellÃƒÂ©';

  @override
  String get component_label_title => 'Titre du libellÃƒÂ©';

  @override
  String get component_markdown_content => 'Contenu Markdown';

  @override
  String get component_max_selections => 'SÃƒÂ©lections max';

  @override
  String get component_media_url => 'URL image / vidÃƒÂ©o';

  @override
  String get component_media_urls => 'URLs mÃƒÂ©dias';

  @override
  String get component_min_selections => 'SÃƒÂ©lections min';

  @override
  String get component_new_checkbox => 'Nouvelle checkbox';

  @override
  String get component_new_option => 'Nouvelle option';

  @override
  String get component_new_radio => 'Nouveau radio';

  @override
  String get component_not_implemented =>
      'Ãƒâ€°diteur pas encore implÃƒÂ©mentÃƒÂ©';

  @override
  String get component_on_click_workflow => 'Au clic, le workflow';

  @override
  String get component_on_select_workflow =>
      'Ãƒâ‚¬ la sÃƒÂ©lection, le workflow';

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
      'Ce composant sera supprimÃƒÂ© de la mise en page. Continuer ?';

  @override
  String get component_remove_row_title => 'Supprimer la ligne d\'action';

  @override
  String get component_remove_title => 'Supprimer le composant';

  @override
  String get component_section_accessory => 'NÃ…â€œud accessoire (optionnel)';

  @override
  String get component_section_text_displays => 'Affichages de texte';

  @override
  String get component_selection_range => 'Nombre de sÃƒÂ©lections';

  @override
  String get component_spacing_large => 'Espacement large';

  @override
  String get component_spacing_small => 'Espacement rÃƒÂ©duit';

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
  String get component_visible_divider => 'Ligne de sÃƒÂ©paration visible';

  @override
  String get component_workflow_args_hint =>
      'Exemple : ticketId = ((opts.ticket))';

  @override
  String get component_workflow_args_title => 'Arguments d\'appel du workflow';

  @override
  String get component_workflow_click_hint =>
      'Nom du workflow sauvegardÃƒÂ© ÃƒÂ  exÃƒÂ©cuter au clic';

  @override
  String get component_workflow_optional => 'Appeler un workflow (optionnel)';

  @override
  String get component_workflow_select_hint =>
      'Nom du workflow sauvegardÃƒÂ© ÃƒÂ  exÃƒÂ©cuter ÃƒÂ  la sÃƒÂ©lection';

  @override
  String get confirm => 'Confirmer';

  @override
  String get copy => 'Copier';

  @override
  String get create => 'CrÃƒÂ©er';

  @override
  String get dart_editor_empty =>
      'Script vide Ã¢â‚¬â€ commencez ÃƒÂ  ÃƒÂ©crire pour voir les diagnostics Dart.';

  @override
  String get dart_editor_tap_hint => 'Appuyez pour ouvrir l\'ÃƒÂ©diteur Dart';

  @override
  String get dart_editor_title => 'Ãƒâ€°diteur Dart';

  @override
  String get dashboard_analysis_period => 'PÃƒÂ©riode d\'analyse';

  @override
  String dashboard_error(String error) {
    return 'Impossible de charger les stats : $error';
  }

  @override
  String get dashboard_error_rate => 'Taux d\'erreur';

  @override
  String get dashboard_execution_health_title => 'SantÃƒÂ© des exÃƒÂ©cutions';

  @override
  String dashboard_executions(int count) {
    return '$count exÃƒÂ©cutions';
  }

  @override
  String get dashboard_failed_commands => 'Ãƒâ€°checs';

  @override
  String get dashboard_loading => 'Chargement des stats...';

  @override
  String get dashboard_no_data =>
      'Aucune donnÃƒÂ©e d\'utilisation. Lancez votre bot pour commencer le suivi.';

  @override
  String get dashboard_p50_latency => 'Latence p50';

  @override
  String get dashboard_p95_latency => 'Latence p95';

  @override
  String get dashboard_period_24h => 'DerniÃƒÂ¨res 24h';

  @override
  String get dashboard_period_30d => '30 derniers jours';

  @override
  String get dashboard_period_7d => '7 derniers jours';

  @override
  String get dashboard_premium_analytics_desc =>
      'DÃƒÂ©bloquez le taux d\'erreur, les percentiles de latence et les insights de localisation.';

  @override
  String get dashboard_premium_analytics_title => 'Analytics Premium';

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Actualiser les serveurs d\'exÃƒÂ©cution';

  @override
  String get dashboard_requires_runner =>
      'Connectez un runner pour voir les statistiques d\'utilisation.';

  @override
  String dashboard_selected_period_total(int count) {
    return '$count sur la pÃƒÂ©riode sÃƒÂ©lectionnÃƒÂ©e';
  }

  @override
  String get dashboard_single_runner_notice =>
      'Les stats affichÃƒÂ©es proviennent uniquement du runner actuellement configurÃƒÂ©. Si vous utilisez plusieurs runners, cette vue peut ÃƒÂªtre incomplÃƒÂ¨te.';

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
      'Tous les replays enregistrÃƒÂ©s seront supprimÃƒÂ©s. Continuer ?';

  @override
  String get debug_replay_clear_title => 'Effacer les replays';

  @override
  String get debug_replay_duration_label => 'DURÃƒâ€°E';

  @override
  String get debug_replay_empty_capturing =>
      'Capture en cours... Lancez une commande pour enregistrer un replay.';

  @override
  String get debug_replay_empty_idle =>
      'Capture dÃƒÂ©sactivÃƒÂ©e. Activez-la et lancez une commande pour enregistrer un replay.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Boucle profondeur $depth, itÃƒÂ©ration $iteration';
  }

  @override
  String get debug_replay_overview => 'Vue d\'ensemble';

  @override
  String get debug_replay_pause => 'Pause';

  @override
  String get debug_replay_play => 'Lire';

  @override
  String get debug_replay_premium_desc =>
      'Enregistrez et rejouez vos exÃƒÂ©cutions de commandes ÃƒÂ©tape par ÃƒÂ©tape. Voyez exactement ce que chaque action a fait, combien de temps elle a pris et oÃƒÂ¹ les erreurs se sont produites.';

  @override
  String get debug_replay_premium_title => 'Replay DÃƒÂ©bogueur Visuel';

  @override
  String get debug_replay_result_empty => '(aucun rÃƒÂ©sultat)';

  @override
  String get debug_replay_result_label => 'RÃƒâ€°SULTAT';

  @override
  String get debug_replay_start_capture => 'Activer la capture';

  @override
  String debug_replay_start_offset(int ms) {
    return '+$ms ms depuis le dÃƒÂ©but';
  }

  @override
  String get debug_replay_step_back => 'Ãƒâ€°tape prÃƒÂ©cÃƒÂ©dente';

  @override
  String get debug_replay_step_first => 'PremiÃƒÂ¨re ÃƒÂ©tape';

  @override
  String get debug_replay_step_forward => 'Ãƒâ€°tape suivante';

  @override
  String get debug_replay_step_last => 'DerniÃƒÂ¨re ÃƒÂ©tape';

  @override
  String get debug_replay_stop_capture => 'DÃƒÂ©sactiver la capture';

  @override
  String get debug_replay_title => 'Replay DÃƒÂ©bogueur';

  @override
  String get debug_replay_variables_empty => '(aucune variable)';

  @override
  String get debug_replay_variables_label => 'VARIABLES';

  @override
  String get delete => 'Supprimer';

  @override
  String get doc_action_http_request_checklist_l1 =>
      'DÃƒÂ©finissez un timeout et des retries explicites dans votre couche de services quand c\'est possible.';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'Stockez les clÃƒÂ©s API dans les globales ou un backend sÃƒÂ©curisÃƒÂ©, ne codez jamais les tokens en dur.';

  @override
  String get doc_action_http_request_checklist_l3 =>
      'Validez le code de statut et le corps de la rÃƒÂ©ponse avant les actions suivantes.';

  @override
  String get doc_action_http_request_section_checklist =>
      'Checklist de fiabilitÃƒÂ©';

  @override
  String get doc_action_http_request_subtitle =>
      'ExÃƒÂ©cute un appel HTTP externe dans un workflow.';

  @override
  String get doc_action_http_request_summary =>
      'Utilisez ceci pour les webhooks, APIs internes, services de modÃƒÂ©ration, endpoints IA et intÃƒÂ©grations.';

  @override
  String get doc_action_http_request_title => 'Action : httpRequest';

  @override
  String get doc_action_if_block_execution_l1 =>
      'La condition est ÃƒÂ©valuÃƒÂ©e une seule fois.';

  @override
  String get doc_action_if_block_execution_l2 =>
      'La premiÃƒÂ¨re branche correspondante s\'exÃƒÂ©cute : THEN, puis les blocs ELSE IF dans l\'ordre, puis ELSE.';

  @override
  String get doc_action_if_block_execution_l3 =>
      'Les actions imbriquÃƒÂ©es peuvent inclure runWorkflow, des appels API et des rÃƒÂ©ponses d\'interaction.';

  @override
  String get doc_action_if_block_section_execution =>
      'ModÃƒÂ¨le d\'exÃƒÂ©cution';

  @override
  String get doc_action_if_block_subtitle =>
      'Branche l\'exÃƒÂ©cution entre les listes d\'actions imbriquÃƒÂ©es THEN, ELSE IF et ELSE.';

  @override
  String get doc_action_if_block_summary =>
      'Utilisez ceci pour garder un seul workflow tout en gÃƒÂ©rant plusieurs rÃƒÂ©sultats selon l\'ÃƒÂ©tat d\'exÃƒÂ©cution.';

  @override
  String get doc_action_if_block_title => 'Action : ifBlock';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'Gardez le workflow principal lÃƒÂ©ger et dÃƒÂ©lÃƒÂ©guez aux workflows de domaine.';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      'Passez des arguments explicites au lieu de dÃƒÂ©pendre des globales implicites.';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'Utilisez les points d\'entrÃƒÂ©e pour modÃƒÂ©liser des sous-routines (create, close, assign, escalate).';

  @override
  String get doc_action_run_workflow_section_practices => 'Bonnes pratiques';

  @override
  String get doc_action_run_workflow_subtitle =>
      'Appelle un autre workflow avec un point d\'entrÃƒÂ©e et des arguments.';

  @override
  String get doc_action_run_workflow_summary =>
      'Primitive de composition pour dÃƒÂ©couper la logique mÃƒÂ©tier en unitÃƒÂ©s rÃƒÂ©utilisables.';

  @override
  String get doc_action_run_workflow_title => 'Action : runWorkflow';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = Ã¢Å“â€¦';

  @override
  String get doc_action_stop_unless_format_l1 =>
      'Vous pouvez utiliser des clÃƒÂ©s brutes : message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'Vous pouvez utiliser des variables encapsulÃƒÂ©es : ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 =>
      'Les deux sont rÃƒÂ©solus par le runtime.';

  @override
  String get doc_action_stop_unless_operators_l1 =>
      'ÃƒÂ©gal, nonÃƒâ€°gal, contient, neContientPas, commencePar, terminePar';

  @override
  String get doc_action_stop_unless_operators_l2 =>
      'plusGrandQue, plusPetitQue, supÃƒÂ©rieurOuÃƒâ€°gal, infÃƒÂ©rieurOuÃƒâ€°gal';

  @override
  String get doc_action_stop_unless_operators_l3 =>
      'estVide, nEstPasVide, correspond';

  @override
  String get doc_action_stop_unless_section_format =>
      'Format de la variable de condition';

  @override
  String get doc_action_stop_unless_section_operators =>
      'OpÃƒÂ©rateurs supportÃƒÂ©s';

  @override
  String get doc_action_stop_unless_subtitle =>
      'Clause de garde qui arrÃƒÂªte le workflow quand la condition ÃƒÂ©choue.';

  @override
  String get doc_action_stop_unless_summary =>
      'Utilisez-le en haut des workflows pour ÃƒÂ©viter les actions inutiles quand le contexte ne correspond pas.';

  @override
  String get doc_action_stop_unless_title => 'Action : stopUnless';

  @override
  String get doc_available_variables => 'Variables disponibles';

  @override
  String get doc_center_clear_search => 'Effacer la recherche';

  @override
  String get doc_center_empty =>
      'Aucune entrÃƒÂ©e de documentation ne correspond ÃƒÂ  votre recherche.';

  @override
  String get doc_center_search_hint =>
      'Rechercher des commandes, workflows, variables, actions, intents ou exemples...';

  @override
  String get doc_center_title => 'Centre de documentation';

  @override
  String get doc_common_section_best_use_cases => 'Cas d\'usage recommandÃƒÂ©s';

  @override
  String get doc_common_section_important_notes => 'Points importants';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      'Alerter le staff sur les actions sensibles (suppression de rÃƒÂ´le, crÃƒÂ©ation de webhook, ban, etc.).';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      'Router des types d\'actions spÃƒÂ©cifiques vers des workflows dÃƒÂ©diÃƒÂ©s.';

  @override
  String get doc_event_audit_log_create_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© quand une nouvelle entrÃƒÂ©e du journal d\'audit est crÃƒÂ©ÃƒÂ©e.';

  @override
  String get doc_event_audit_log_create_summary =>
      'Ãƒâ€°vÃƒÂ©nement ÃƒÂ  haute valeur pour la surveillance de sÃƒÂ©curitÃƒÂ© administrative.';

  @override
  String get doc_event_audit_log_create_title =>
      'Ãƒâ€°vÃƒÂ©nement : guildAuditLogCreate';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'DÃƒÂ©tecter des commandes tapÃƒÂ©es sans slash command.';

  @override
  String get doc_event_message_create_best_use_l2 =>
      'Appliquer des filtres anti-spam avant de rÃƒÂ©pondre.';

  @override
  String get doc_event_message_create_best_use_l3 =>
      'Router vers des workflows rÃƒÂ©utilisables selon le premier mot ou la mention.';

  @override
  String get doc_event_message_create_example =>
      'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nThen: runWorkflow -> ticket_manager entry=create';

  @override
  String get doc_event_message_create_intent_1 => 'Messages de serveur';

  @override
  String get doc_event_message_create_intent_2 => 'Contenu des messages';

  @override
  String get doc_event_message_create_notes_l1 =>
      'Si l\'intent Message Content est dÃƒÂ©sactivÃƒÂ©, les conditions basÃƒÂ©es sur le contenu peuvent ÃƒÂ©chouer.';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index] est basÃƒÂ© sur les mots et limitÃƒÂ© par l\'extraction runtime.';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBot aide ÃƒÂ  ÃƒÂ©viter les boucles entre bots.';

  @override
  String get doc_event_message_create_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© pour chaque nouveau message crÃƒÂ©ÃƒÂ©.';

  @override
  String get doc_event_message_create_summary =>
      'Utilisez cet ÃƒÂ©vÃƒÂ©nement pour la modÃƒÂ©ration, les pipelines de mots-clÃƒÂ©s, les auto-rÃƒÂ©ponses, le parsing style commande et l\'analytics.';

  @override
  String get doc_event_message_create_title =>
      'Ãƒâ€°vÃƒÂ©nement : messageCreate';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      'Associer chaque identifiant de rÃƒÂ©ponse ÃƒÂ  une branche d\'action diffÃƒÂ©rente.';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'Suivre la participation aux sondages par salon ou groupe d\'utilisateurs.';

  @override
  String get doc_event_poll_vote_add_intent => 'Messages de serveur';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.id est la clÃƒÂ© la plus stable pour le routage.';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.question est optionnel et peut ÃƒÂªtre vide selon le payload.';

  @override
  String get doc_event_poll_vote_add_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© quand un utilisateur vote sur une rÃƒÂ©ponse de sondage.';

  @override
  String get doc_event_poll_vote_add_summary =>
      'Utile pour le suivi des scores, l\'attribution de rÃƒÂ´les par option de sondage et le traitement des enquÃƒÂªtes.';

  @override
  String get doc_event_poll_vote_add_title =>
      'Ãƒâ€°vÃƒÂ©nement : messagePollVoteAdd';

  @override
  String get doc_event_reaction_add_best_use_l1 =>
      'Flux d\'approbation/rejet avec des emojis unicode.';

  @override
  String get doc_event_reaction_add_best_use_l2 =>
      'Sondages multi-ÃƒÂ©tapes utilisant des IDs d\'emojis personnalisÃƒÂ©s.';

  @override
  String get doc_event_reaction_add_best_use_l3 =>
      'Signaux de modÃƒÂ©ration rapides depuis les salons du staff.';

  @override
  String get doc_event_reaction_add_example =>
      'Guard : ((reaction.emoji.name)) equals Ã¢Å“â€¦\nAction : addRole -> user=((userId)) role=((global.approvedRoleId))';

  @override
  String get doc_event_reaction_add_intent => 'RÃƒÂ©actions de messages';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.id peut ÃƒÂªtre vide pour les emojis unicode.';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      'Utilisez reaction.emoji.name pour une correspondance gÃƒÂ©nÃƒÂ©rique.';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      'Utilisez reaction.emoji.id pour une correspondance stricte d\'emojis personnalisÃƒÂ©s.';

  @override
  String get doc_event_reaction_add_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© quand un utilisateur ajoute une rÃƒÂ©action ÃƒÂ  un message.';

  @override
  String get doc_event_reaction_add_summary =>
      'IdÃƒÂ©al pour une UX type bouton sans composants, les systÃƒÂ¨mes de vote, les menus de rÃƒÂ´les et les approbations lÃƒÂ©gÃƒÂ¨res.';

  @override
  String get doc_event_reaction_add_title =>
      'Ãƒâ€°vÃƒÂ©nement : messageReactionAdd';

  @override
  String get doc_event_user_update_notes_l1 =>
      'Pas de contexte de salon pour cet ÃƒÂ©vÃƒÂ©nement dans la plupart des cas.';

  @override
  String get doc_event_user_update_notes_l2 =>
      'PrivilÃƒÂ©giez la journalisation + alertes de modÃƒÂ©ration plutÃƒÂ´t que les rÃƒÂ©ponses directes ÃƒÂ  l\'utilisateur.';

  @override
  String get doc_event_user_update_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© quand les donnÃƒÂ©es du profil utilisateur changent.';

  @override
  String get doc_event_user_update_summary =>
      'Utile pour l\'audit des changements de profil et les dÃƒÂ©clencheurs basÃƒÂ©s sur le pseudo/avatar.';

  @override
  String get doc_event_user_update_title => 'Ãƒâ€°vÃƒÂ©nement : userUpdate';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      'DÃƒÂ©tecter les violations de politique de sourdine/dÃƒÂ©sactivation du son.';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'Envoyer un message de bienvenue ÃƒÂ  la connexion vocale pour les salons de support.';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'Journaliser les patterns d\'arrivÃƒÂ©e/dÃƒÂ©part via les changements de salon.';

  @override
  String get doc_event_voice_state_update_intent => 'Serveurs';

  @override
  String get doc_event_voice_state_update_section_title =>
      'Automatisations typiques';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'DÃƒÂ©clenchÃƒÂ© quand l\'ÃƒÂ©tat vocal change pour un utilisateur.';

  @override
  String get doc_event_voice_state_update_summary =>
      'Utilisez ceci pour la modÃƒÂ©ration automatique dans les salons vocaux, le suivi de prÃƒÂ©sence et l\'automatisation vocale.';

  @override
  String get doc_event_voice_state_update_title =>
      'Ãƒâ€°vÃƒÂ©nement : voiceStateUpdate';

  @override
  String get doc_example => 'Exemple';

  @override
  String doc_interaction_commands_example(String name, String id) {
    return 'Workflow d\'auto-complete :\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'$name\' value=\'$id\'';
  }

  @override
  String get doc_interaction_commands_section_builtin_title =>
      'Variables builtin de commande';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'Les commandes slash, user et message passent toutes par des interactions de commande applicative.';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'Le runner associe les commandes par id Discord, puis valide le type stockÃƒÂ© vs le type entrant.';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'Un mismatch de type est loggÃƒÂ© en warning mais ne bloque pas l\'exÃƒÂ©cution.';

  @override
  String get doc_interaction_commands_section_execution_title =>
      'ModÃƒÂ¨le d\'exÃƒÂ©cution';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'Ãƒâ€°crivez vos conditions avec commandType ou interaction.command.type.';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'PrÃƒÂ©fÃƒÂ©rez la syntaxe de fallback pour partager un template entre slash et non-slash, et utilisez autocomplete.query dans les workflows dÃƒÂ©diÃƒÂ©s ÃƒÂ  l\'auto-complete.';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'Gardez des templates portables en ÃƒÂ©vitant les variables propres aux events dans les workflows de commande ; l\'auto-complete dynamique doit finir par respondWithAutocomplete.';

  @override
  String get doc_interaction_commands_section_guidance_title =>
      'Recommandations d\'ÃƒÂ©criture';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput : opts.* pour les paramÃƒÂ¨tres et sous-commandes.';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user : target.user.* et target.member.* quand disponibles.';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message : target.message.* incluant le contenu et l\'id auteur quand rÃƒÂ©solus.';

  @override
  String get doc_interaction_commands_section_per_type_title =>
      'Variables par type';

  @override
  String get doc_interaction_commands_subtitle =>
      'Comportement runtime des commandes slash, user et message.';

  @override
  String get doc_interaction_commands_summary =>
      'Les commandes applicatives sont exÃƒÂ©cutÃƒÂ©es via un chemin d\'interaction commun, avec des variables runtime qui dÃƒÂ©pendent du type Discord.';

  @override
  String get doc_interaction_commands_title => 'Commandes d\'interaction';

  @override
  String get doc_kind_action => 'Action';

  @override
  String get doc_kind_all => 'Tout';

  @override
  String get doc_kind_event => 'Ãƒâ€°vÃƒÂ©nement';

  @override
  String get doc_kind_runtime => 'ExÃƒÂ©cution';

  @override
  String get doc_kind_template => 'ModÃƒÂ¨le';

  @override
  String get doc_required_intents => 'Intents requis';

  @override
  String get doc_runtime_action_outputs_example =>
      'Status : ((action.http.status|http.status|unknown))\nBody : ((action.http.body|http.body))\nSupprimes : ((cleanup.count|0))\nTotal : ((page.total|0))';

  @override
  String get doc_runtime_action_outputs_section_caveats_l1 =>
      'Toutes les actions n\'exposent pas tous les suffixes; cela depend de l\'executor.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l2 =>
      'Pour la portabilite, privilegiez les expressions avec fallback sur les champs optionnels.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l3 =>
      'Si une cle est absente, le template renvoie une chaine vide.';

  @override
  String get doc_runtime_action_outputs_section_caveats_title =>
      'Points d\'attention';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l1 =>
      'Actions HTTP : status, body, jsonPath.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l2 =>
      'Actions message/liste : count, mode, deleteItself, deleteResponse.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l3 =>
      'Actions tableau : items, length, removed, total.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l4 =>
      'D\'autres executors peuvent exposer result ou messageId.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_title =>
      'Champs de sortie frequents';

  @override
  String get doc_runtime_action_outputs_section_patterns_l1 =>
      'La sortie principale est generalement stockee dans <resultKey>.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l2 =>
      'Beaucoup d\'executors exposent aussi action.<resultKey>.* pour clarte et namespacing.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l3 =>
      'Certains champs existent a la fois avec et sans prefixe action.';

  @override
  String get doc_runtime_action_outputs_section_patterns_title =>
      'Patterns de sortie';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'Comment les resultKey d\'action sont exposes comme variables runtime.';

  @override
  String get doc_runtime_action_outputs_summary =>
      'La plupart des actions ecrivent une cle principale, et peuvent aussi exposer des champs prefixes sous action.<resultKey>.* selon l\'executor.';

  @override
  String get doc_runtime_action_outputs_title => 'Sorties runtime des actions';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      'Les variables doivent ÃƒÂªtre identiques entre runtime local app et runtime runner.';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      'Utilisez les mÃƒÂªmes noms de variables dans les conditions pour rester portable.';

  @override
  String get doc_runtime_execution_flow_section_parity_title =>
      'RÃƒÂ¨gle de paritÃƒÂ©';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) RÃƒÂ©ception de l\'ÃƒÂ©vÃƒÂ©nement gateway.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) Construction de la map de variables de contexte.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) Matching des workflows par nom d\'ÃƒÂ©vÃƒÂ©nement.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) Fusion des variables globales.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) ExÃƒÂ©cution sÃƒÂ©quentielle des actions avec conditions.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'Pipeline';

  @override
  String get doc_runtime_execution_flow_subtitle =>
      'Comment les workflows d\'ÃƒÂ©vÃƒÂ©nement sont sÃƒÂ©lectionnÃƒÂ©s et exÃƒÂ©cutÃƒÂ©s.';

  @override
  String get doc_runtime_execution_flow_summary =>
      'Quand un ÃƒÂ©vÃƒÂ©nement arrive, le runtime associe les workflows via eventTrigger.event puis exÃƒÂ©cute les actions avec les variables de contexte.';

  @override
  String get doc_runtime_execution_flow_title => 'Flux d\'exÃƒÂ©cution runtime';

  @override
  String get doc_template_advanced_variables_example =>
      'Type : ((interaction.kind))\nNb selection : ((interaction.values.count|0))\nOwner thread : ((channel.thread.ownerId|unknown))\nType payload guild : ((guild.kind|n/a))';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      'Les alias user structures (user.id, user.username, user.tag, user.avatar, user.banner) sont disponibles dans de nombreux contextes de commande.';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.id est utile quand vous combinez contexte utilisateur et membre de serveur.';

  @override
  String get doc_template_advanced_variables_section_aliases_title =>
      'Alias user et member';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l1 =>
      'channel.kind, channel.position, channel.bitrate et channel.userLimit sont des details de salon dependant du contexte.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l2 =>
      'Les contextes thread peuvent exposer channel.thread.* (archived, locked, ownerId, autoArchiveDuration).';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l3 =>
      'guild.kind aide a distinguer les payloads partiels/complets dans les workflows avances.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'Details channel et guild';

  @override
  String get doc_template_advanced_variables_section_interaction_l1 =>
      'interaction.kind indique le mode d\'interaction entrant (button, select, modal, command, autocomplete).';

  @override
  String get doc_template_advanced_variables_section_interaction_l2 =>
      'interaction.values et interaction.values.count sont remplis pour les menus select.';

  @override
  String get doc_template_advanced_variables_section_interaction_l3 =>
      'interaction.command.name et interaction.command.id sont utiles pour le diagnostic et le routage.';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'Metadonnees d\'interaction';

  @override
  String get doc_template_advanced_variables_subtitle =>
      'Cles runtime supplementaires disponibles selon le contexte.';

  @override
  String get doc_template_advanced_variables_summary =>
      'Ces cles sont generees a partir des payloads d\'interaction et des details runtime channel/guild/user, selon le type d\'event ou de commande.';

  @override
  String get doc_template_advanced_variables_title =>
      'Variables de template avancees';

  @override
  String get doc_template_functions_example =>
      'NormalisÃƒÂ© : ((uppercase(trim(userName))))\nRole admin : ((contains(userRole, \"admin\")))\nMeilleur score : ((first(scores.\$)))\nScore total : ((sum(scores.\$)))';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(source), at(source, index), first(source), last(source).';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(source, start, end?) et join(source, separator).';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(source) : additionne les valeurs numÃƒÂ©riques et ignore le reste.';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) et embedFields(...) formatent des tableaux d\'objets pour texte et embeds.';

  @override
  String get doc_template_functions_section_array_title =>
      'Helpers tableaux et agrÃƒÂ©gats';

  @override
  String get doc_template_functions_section_notes_l1 =>
      'Les noms de fonctions sont insensibles ÃƒÂ  la casse.';

  @override
  String get doc_template_functions_section_notes_l2 =>
      'Fonction inconnue ou arguments invalides : rendu en chaÃƒÂ®ne vide.';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'Utilisez les fallbacks avec | au niveau racine : ((replace(name, \"_\", \" \")|Inconnu)).';

  @override
  String get doc_template_functions_section_notes_l4 =>
      'Les tableaux et objets renvoyÃƒÂ©s sont sÃƒÂ©rialisÃƒÂ©s en texte JSON.';

  @override
  String get doc_template_functions_section_notes_title => 'Points importants';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() et random() : renvoient \"true\" ou \"\" pour les branches conditionnelles.';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) et randomint(min, max).';

  @override
  String get doc_template_functions_section_random_title =>
      'Helpers alÃƒÂ©atoires';

  @override
  String get doc_template_functions_section_string_l1 =>
      'lowercase(source) / lower(source) : convertit en minuscules.';

  @override
  String get doc_template_functions_section_string_l2 =>
      'uppercase(source) / upper(source) : convertit en majuscules.';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(source) : supprime les espaces au dÃƒÂ©but et ÃƒÂ  la fin.';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(source, search, replacement) et contains(source, needle) pour remplacer et tester.';

  @override
  String get doc_template_functions_section_string_title => 'Helpers texte';

  @override
  String get doc_template_functions_subtitle =>
      'Transformer et comparer des donnÃƒÂ©es dans les expressions ((...)).';

  @override
  String get doc_template_functions_summary =>
      'Les fonctions de template servent ÃƒÂ  normaliser du texte, manipuler des tableaux, formater des sorties et ajouter un peu d\'alÃƒÂ©atoire.';

  @override
  String get doc_template_functions_title => 'Fonctions de template';

  @override
  String doc_template_variables_example(String name, String score) {
    return 'Bonjour ((target.user.username|userName))\nJoueurs : ((join(scores.items.\$, \", \")))\nFields JSON : ((embedFields(scores.items.\$, \"\'$name\'\", \"\'$score\'\", true)))';
  }

  @override
  String get doc_template_variables_section_builtin_title =>
      'Variables builtin de commande';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'Utilisez ((opts.user|userName)) pour fallback si une option est absente.';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'Utilisez la syntaxe JSONPath sur les sorties d\'actions : ((myHttp.body.\$.data[0].id)) ; les tableaux et objets restent manipulables.';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'Les fonctions length(...), join(...), formatEach(...), et embedFields(...) sont aussi supportÃƒÂ©es ; une variable inconnue reste rÃƒÂ©solue en chaÃƒÂ®ne vide.';

  @override
  String get doc_template_variables_section_fallbacks_title =>
      'Fallbacks et chemins';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'Variables de commande : commandName, commandId, commandType, target.*, opts.*.';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'Variables d\'ÃƒÂ©vÃƒÂ©nement : event.*, message.*, reaction.*, voice.*, role.*, etc.';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'Variables de workflow : workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'Variables globales : global.<key>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'Sorties d\'actions : action.<key> quand disponibles.';

  @override
  String get doc_template_variables_section_sources_title =>
      'Sources de variables';

  @override
  String get doc_template_variables_section_types_l1 =>
      'Les commandes slash utilisent commandType = chatInput et exposent les variables opts.<option>.';

  @override
  String get doc_template_variables_section_types_l2 =>
      'Les commandes user utilisent commandType = user et exposent les variables target.user.*.';

  @override
  String get doc_template_variables_section_types_l3 =>
      'Les commandes message utilisent commandType = message et exposent les variables target.message.*.';

  @override
  String get doc_template_variables_section_types_l4 =>
      'Les sous-commandes exposent aussi leurs arguments via opts.*.';

  @override
  String get doc_template_variables_section_types_title => 'Types de commande';

  @override
  String get doc_template_variables_subtitle =>
      'Comment les placeholders dynamiques sont rÃƒÂ©solus.';

  @override
  String get doc_template_variables_summary =>
      'Le runtime rÃƒÂ©sout les placeholders selon le contexte courant (ÃƒÂ©vÃƒÂ©nement/interaction), les arguments de workflow et les variables globales.';

  @override
  String get doc_template_variables_title => 'Variables de template';

  @override
  String get done => 'TerminÃƒÂ©';

  @override
  String download_completed(String id) {
    return 'TÃƒÂ©lÃƒÂ©chargement terminÃƒÂ© : $id';
  }

  @override
  String download_failed(String error) {
    return 'Ãƒâ€°chec du tÃƒÂ©lÃƒÂ©chargement : $error';
  }

  @override
  String get download_legacy_backup =>
      'TÃƒÂ©lÃƒÂ©chargement terminÃƒÂ© (ancienne sauvegarde)';

  @override
  String get drive_legacy_snapshot => 'Snapshot legacy';

  @override
  String get drive_manual_backup => 'Sauvegarde manuelle';

  @override
  String get edit_shell_all_saved =>
      'Toutes les modifications sont enregistrÃƒÂ©es';

  @override
  String get edit_shell_command_body => 'Corps de la commande';

  @override
  String get edit_shell_command_settings => 'ParamÃƒÂ¨tres de la commande';

  @override
  String get edit_shell_command_settings_desc =>
      'MÃƒÂ©tadonnÃƒÂ©es, disponibilitÃƒÂ©, permissions et placement dans un dossier.';

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
      'Les paramÃƒÂ¨tres et les entrÃƒÂ©es sont en haut. Les actions et la rÃƒÂ©ponse suivent en dessous.';

  @override
  String get edit_shell_trigger_inputs => 'DÃƒÂ©clencheur et entrÃƒÂ©es';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Ajuster les options de la commande, le comportement du dÃƒÂ©clencheur et le mode d\'exÃƒÂ©cution.';

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
  String get edit_shell_unsaved => 'Modifications non enregistrÃƒÂ©es';

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
  String get embed_delete_confirm => 'Cet embed sera supprimÃƒÂ©. Continuer ?';

  @override
  String get embed_delete_title => 'Supprimer l\'embed';

  @override
  String embed_empty_message(int max) {
    return 'Aucun embed. Vous pouvez en ajouter jusqu\'ÃƒÂ  $max.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Ce champ sera supprimÃƒÂ© de l\'embed. Continuer ?';

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
  String get embed_label_author_icon => 'URL icÃƒÂ´ne de l\'auteur';

  @override
  String get embed_label_author_name => 'Nom de l\'auteur';

  @override
  String get embed_label_author_url => 'URL de l\'auteur';

  @override
  String get embed_label_color => 'Couleur (int ou #hex)';

  @override
  String get embed_label_dynamic_fields => 'ModÃƒÂ¨le de champs dynamiques';

  @override
  String get embed_label_footer_icon => 'URL icÃƒÂ´ne du pied de page';

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
  String get embed_label_title => 'Titre';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return 'IntÃƒÂ©gration #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return 'Embeds de rÃƒÂ©ponse ($count/$max)';
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
  String get embed_section_media => 'MÃƒÂ©dias';

  @override
  String get embed_section_timestamp => 'Horodatage';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Supprimer :$name: ? Cette action est irrÃƒÂ©versible.';
  }

  @override
  String get emojis_delete_confirm_title => 'Supprimer l\'emoji';

  @override
  String emojis_delete_error(String error) {
    return 'Ãƒâ€°chec de la suppression : $error';
  }

  @override
  String get emojis_delete_tooltip => 'Supprimer';

  @override
  String get emojis_empty =>
      'Aucun emoji pour l\'instant. Uploadez-en un pour commencer.';

  @override
  String get emojis_loading_error => 'Ãƒâ€°chec du chargement des emojis';

  @override
  String emojis_rename_error(String error) {
    return 'Ãƒâ€°chec du renommage : $error';
  }

  @override
  String get emojis_rename_hint => 'Nouveau nom';

  @override
  String get emojis_rename_title => 'Renommer l\'emoji';

  @override
  String get emojis_rename_tooltip => 'Renommer';

  @override
  String get emojis_tab => 'Ãƒâ€°moticÃƒÂ´nes';

  @override
  String get emojis_tab_short => 'Ãƒâ€°mojis';

  @override
  String get emojis_title => 'Emojis applicatifs';

  @override
  String get emojis_upload => 'Uploader un emoji';

  @override
  String emojis_upload_error(String error) {
    return 'Ãƒâ€°chec de l\'upload : $error';
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
      'Ãƒâ€°chec de la suppression des messages.';

  @override
  String get error_invalid_channel_type =>
      'Le salon n\'est pas un salon textuel.';

  @override
  String get error_invalid_count =>
      'Le nombre doit ÃƒÂªtre supÃƒÂ©rieur ÃƒÂ  0.';

  @override
  String get error_network_timeout =>
      'L\'action a expirÃƒÂ©. Veuillez rÃƒÂ©essayer.';

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
    return 'Ãƒâ€°chec de l\'export : $error';
  }

  @override
  String get export_file_picker_busy =>
      'Un sÃƒÂ©lecteur de fichier est dÃƒÂ©jÃƒÂ  ouvert';

  @override
  String get export_global_variables => 'Variables globales';

  @override
  String get export_import_title => 'Export / Import';

  @override
  String get export_section_desc =>
      'Exportez les sections sÃƒÂ©lectionnÃƒÂ©es de votre bot sous forme de fichier ZIP. Le token du bot n\'est jamais inclus.';

  @override
  String get export_section_title => 'Exporter';

  @override
  String get export_status => 'Statut & ActivitÃƒÂ©s';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get globals_add => 'Ajouter une variable';

  @override
  String get globals_add_global => 'Ajouter une variable globale';

  @override
  String get globals_add_scoped => 'Ajouter une variable scopÃƒÂ©e';

  @override
  String get globals_copy_value => 'Copier la valeur';

  @override
  String globals_delete_confirm(String key) {
    return 'Supprimer Ã‚Â« $key Ã‚Â» ?';
  }

  @override
  String get globals_delete_title => 'Supprimer la variable';

  @override
  String get globals_dialog_global_desc =>
      'Les variables globales sont partagÃƒÂ©es entre toutes les commandes et serveurs.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Usage : \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Une variable scopÃƒÂ©e stocke une valeur distincte par contexte $scope.';
  }

  @override
  String get globals_edit => 'Modifier une variable';

  @override
  String get globals_edit_global => 'Modifier la variable globale';

  @override
  String get globals_edit_scoped => 'Modifier la variable scopÃƒÂ©e';

  @override
  String get globals_empty => 'Aucune variable globale pour le moment';

  @override
  String get globals_empty_subtitle =>
      'Ajoutez une variable pour stocker des donnÃƒÂ©es persistantes accessibles par toutes les commandes.';

  @override
  String get globals_help_global =>
      'PartagÃƒÂ©es entre toutes les commandes. Accessibles via \$getVar[clÃƒÂ©].';

  @override
  String get globals_help_scoped =>
      'StockÃƒÂ©es par contexte (serveur, utilisateur, salon...). Chaque entrÃƒÂ©e conserve une valeur distincte par contexte Discord.';

  @override
  String get globals_key => 'ClÃƒÂ©';

  @override
  String get globals_key_hint => 'ex. prefix, level, welcome_message';

  @override
  String get globals_mode_global => 'Globale';

  @override
  String get globals_mode_scoped => 'ScopÃƒÂ©e';

  @override
  String get globals_no_default => 'Aucune valeur par dÃƒÂ©faut';

  @override
  String get globals_refresh => 'Actualiser';

  @override
  String get globals_retry => 'RÃƒÂ©essayer';

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
      'La valeur est auto-typÃƒÂ©e (nombre, boolÃƒÂ©en, JSON).';

  @override
  String get guilds_empty_state =>
      'Le bot n\'est dans aucun serveur.\nInvitez-le dans un serveur pour le voir ici.';

  @override
  String guilds_leave_confirm(String name) {
    return 'Quitter \"$name\" ?\nLe bot sera retirÃƒÂ© de ce serveur. Vous pourrez le rÃƒÂ©inviter plus tard depuis le portail dÃƒÂ©veloppeur Discord.';
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
    return 'Vous avez quittÃƒÂ© \"$name\".';
  }

  @override
  String guilds_members_count_other(int count) {
    return '~$count membres';
  }

  @override
  String get guilds_owner_label => 'Ã°Å¸â€˜â€˜ PropriÃƒÂ©taire';

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
      'Utilisez des variables/templates si nÃƒÂ©cessaire';

  @override
  String get home_add_time => 'Ajouter du temps';

  @override
  String get home_empty_support_btn => 'Support Discord';

  @override
  String get home_empty_support_hint =>
      'Besoin d\'aide ? Rejoignez notre communautÃƒÂ© !';

  @override
  String get home_foreground_service_not_started =>
      'Le service foreground n\'a pas dÃƒÂ©marrÃƒÂ©.';

  @override
  String get home_hosting_expired => 'HÃƒÂ©bergement expirÃƒÂ©';

  @override
  String home_hosting_time_left(String time) {
    return 'HÃƒÂ©bergement restant : $time';
  }

  @override
  String get home_log_desktop_stop_requested =>
      'ArrÃƒÂªt du bot desktop demandÃƒÂ©';

  @override
  String get home_log_start_requested => 'DÃƒÂ©marrage du bot demandÃƒÂ©';

  @override
  String get home_log_stop_requested => 'ArrÃƒÂªt du bot demandÃƒÂ©';

  @override
  String get home_logs_tooltip => 'Logs du bot';

  @override
  String get home_manage => 'GÃƒÂ©rer';

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
  String get home_start => 'DÃƒÂ©marrer';

  @override
  String get home_start_ads => 'DÃƒÂ©marrer (Voir Pub)';

  @override
  String get home_start_premium => 'DÃƒÂ©marrer (Premium)';

  @override
  String get home_status_offline => 'Hors ligne';

  @override
  String get home_status_online => 'En ligne';

  @override
  String get home_stop => 'ArrÃƒÂªter';

  @override
  String get home_sync_failed => 'ÃƒÂ©chec de la synchronisation';

  @override
  String get home_tab => 'Accueil';

  @override
  String get home_time_added => 'Temps ajoutÃƒÂ© avec succÃƒÂ¨s !';

  @override
  String home_token_missing(String botName) {
    return 'Token introuvable pour $botName';
  }

  @override
  String get home_unknown_app => 'Inconnu';

  @override
  String get image_editor_create => 'CrÃƒÂ©er';

  @override
  String get image_editor_create_canvas => 'CrÃƒÂ©er un canvas d\'image';

  @override
  String image_editor_edit_canvas(int count) {
    return 'Ãƒâ€°diter le canvas ($count opÃƒÂ©rations)';
  }

  @override
  String get image_editor_open => 'Ouvrir l\'ÃƒÂ©diteur';

  @override
  String get import_button => 'Importer';

  @override
  String import_failed(String error) {
    return 'Ãƒâ€°chec de l\'import : $error';
  }

  @override
  String get import_nothing => 'Rien n\'a ÃƒÂ©tÃƒÂ© importÃƒÂ©.';

  @override
  String get import_overwrite => 'Ãƒâ€°craser';

  @override
  String import_parse_failed(String error) {
    return 'Ãƒâ€°chec de l\'analyse du ZIP : $error';
  }

  @override
  String get import_pick_file => 'SÃƒÂ©lectionner un fichier ZIP';

  @override
  String get import_section_desc =>
      'Importez un fichier ZIP prÃƒÂ©cÃƒÂ©demment exportÃƒÂ©. Les conflits peuvent ÃƒÂªtre rÃƒÂ©solus par ÃƒÂ©lÃƒÂ©ment.';

  @override
  String get import_section_title => 'Importer';

  @override
  String get import_skip => 'Ignorer';

  @override
  String import_summary_commands_imported(int count) {
    return '$count commande(s) importÃƒÂ©e(s)';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count commande(s) ignorÃƒÂ©e(s)';
  }

  @override
  String get import_summary_status_imported => 'statut importÃƒÂ©';

  @override
  String get import_summary_variables_imported => 'variables importÃƒÂ©es';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) importÃƒÂ©(s)';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) ignorÃƒÂ©(s)';
  }

  @override
  String get js_editor_hint =>
      '// Ãƒâ€°crivez votre commande JavaScript ici...';

  @override
  String get js_editor_segmented_label => 'JS';

  @override
  String get js_editor_subtitle =>
      'Ãƒâ€°crire du JavaScript personnalisÃƒÂ© pour cette commande';

  @override
  String get js_editor_title => 'Ãƒâ€°diteur JavaScript';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'ÃƒÂ©chec d\'exÃƒÂ©cution du script BDFD pour la commande \"$command\" : $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'GÃƒÂ¨re les commandes depuis messageCreate avec <prÃƒÂ©fixe><commande>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Utilise des options positionnelles (exemple : !config #channel).';

  @override
  String get legacy_prefix_mode_title => 'Mode prÃƒÂ©fixe legacy';

  @override
  String get legacy_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label =>
      'Remplacement du prÃƒÂ©fixe (optionnel)';

  @override
  String get legacy_response_banner_body =>
      'Certaines commandes utilisent encore l\'ancien format de rÃƒÂ©ponse. Ouvrez-les dans l\'ÃƒÂ©diteur et re-sauvegardez-les pour activer le nouveau format.';

  @override
  String get legacy_response_banner_dismiss => 'Ignorer';

  @override
  String get legacy_response_banner_migrate => 'Tout migrer';

  @override
  String get legacy_response_banner_migrate_failed =>
      'Ãƒâ€°chec de la migration';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count commandes migrÃƒÂ©es',
      one: '1 commande migrÃƒÂ©e',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none =>
      'Aucune commande ÃƒÂ  migrer';

  @override
  String get legacy_response_banner_migrating => 'Migration en cours...';

  @override
  String get legacy_response_banner_short_body =>
      'Ouvrez et re-sauvegardez vos commandes pour migrer vers le nouveau format.';

  @override
  String get legacy_response_banner_short_title =>
      'Mise ÃƒÂ  jour des commandes disponible';

  @override
  String get legacy_response_banner_title =>
      'Mise ÃƒÂ  jour du format de rÃƒÂ©ponse des commandes';

  @override
  String get legacy_response_mode_label => 'Mode de rÃƒÂ©ponse legacy';

  @override
  String get local_command_awaited_desc =>
      'Les presets de callback awaitÃƒÂ©s restent locaux car ce sont des callbacks internes au runtime.';

  @override
  String get local_command_desc =>
      'Stocke la commande uniquement dans Bot Creator. Vous pouvez l\'enregistrer dynamiquement sur des serveurs spÃƒÂ©cifiques avec BDFD \$registerGuildCommands.';

  @override
  String get local_command_title =>
      'Commande locale (ne pas enregistrer sur Discord)';

  @override
  String logs_runner_source(String name) {
    return 'Logs de : $name';
  }

  @override
  String get marketplace_about => 'Ãƒâ‚¬ propos';

  @override
  String get marketplace_add => 'Ajouter';

  @override
  String get marketplace_api_unavailable => 'API client non disponible';

  @override
  String get marketplace_apply => 'Appliquer le template';

  @override
  String marketplace_apply_error(Object error) {
    return 'Ãƒâ€°chec de lÃ¢â‚¬â„¢application : $error';
  }

  @override
  String get marketplace_apply_success =>
      'Template appliquÃƒÂ© avec succÃƒÂ¨s !';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount commande(s) ajoutÃƒÂ©e(s), $skippedCount ignorÃƒÂ©e(s) (doublons).';
  }

  @override
  String get marketplace_applying => 'Application en cours...';

  @override
  String marketplace_by_author(Object author, Object version) {
    return 'par $author Ã‚Â· v$version';
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
      'Remplis les valeurs obligatoires avant dÃ¢â‚¬â„¢appliquer ce template.';

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
      'Certaines commandes du template existent dÃƒÂ©jÃƒÂ . Choisis quelle version garder :';

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'ModÃƒÂ¨le ($count actions)';
  }

  @override
  String get marketplace_conflict_title => 'Conflits de commandes';

  @override
  String get marketplace_conflict_use_template => 'Utiliser Template';

  @override
  String get marketplace_connect_discord => 'Se connecter avec Discord';

  @override
  String get marketplace_connect_manager =>
      'Connecte-toi au Manager pour accÃƒÂ©der au Marketplace.';

  @override
  String get marketplace_connect_publish =>
      'Connecte-toi au Manager pour publier un template.';

  @override
  String marketplace_count(Object count) {
    return '$count modÃƒÂ¨le(s)';
  }

  @override
  String get marketplace_delete => 'Supprimer';

  @override
  String marketplace_delete_confirm(Object name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ? Cette action est irrÃƒÂ©versible.';
  }

  @override
  String get marketplace_delete_confirm_title => 'Supprimer le template';

  @override
  String get marketplace_delete_success => 'Template supprimÃƒÂ©.';

  @override
  String get marketplace_edit => 'Modifier';

  @override
  String get marketplace_edit_hint =>
      'Pour modifier, republiez depuis la liste des commandes de votre bot avec le mÃƒÂªme nom.';

  @override
  String get marketplace_empty =>
      'Aucun template pour le moment.\nSois le premier ÃƒÂ  publier !';

  @override
  String marketplace_load_error(Object error) {
    return 'Ãƒâ€°chec du chargement : $error';
  }

  @override
  String get marketplace_login_hint =>
      'Vous devez connecter votre compte Discord pour accÃƒÂ©der au Marketplace.';

  @override
  String get marketplace_login_instructions =>
      'Veuillez vous authentifier via Discord pour continuer ÃƒÂ  utiliser le Marketplace.';

  @override
  String get marketplace_login_required => 'Connexion Discord requise';

  @override
  String get marketplace_login_success =>
      'Discord connectÃƒÂ© avec succÃƒÂ¨s !';

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
    return 'Aucun template ne correspond ÃƒÂ  \"$query\"';
  }

  @override
  String get marketplace_no_variables => 'Aucune variable globale dÃƒÂ©finie.';

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
  String get marketplace_publish_category_label => 'CatÃƒÂ©gorie';

  @override
  String marketplace_publish_commands(Object count) {
    return 'Commandes ($count)';
  }

  @override
  String get marketplace_publish_desc_hint =>
      'Un rÃƒÂ©sumÃƒÂ© dÃ¢â‚¬â„¢une ligne affichÃƒÂ© dans le marketplace';

  @override
  String get marketplace_publish_desc_label => 'Description courte';

  @override
  String get marketplace_publish_desc_long_hint =>
      'Instructions dÃ¢â‚¬â„¢utilisation dÃƒÂ©taillÃƒÂ©es, markdown supportÃƒÂ©...';

  @override
  String get marketplace_publish_desc_long_label =>
      'Documentation complÃƒÂ¨te (optionnel)';

  @override
  String get marketplace_publish_deselect_all => 'Tout dÃƒÂ©sÃƒÂ©lectionner';

  @override
  String marketplace_publish_error(Object error) {
    return 'Ãƒâ€°chec de la publication : $error';
  }

  @override
  String get marketplace_publish_metadata => 'DÃƒÂ©tails du template';

  @override
  String get marketplace_publish_metadata_hint =>
      'DÃƒÂ©cris ton template pour que dÃ¢â‚¬â„¢autres puissent le trouver et lÃ¢â‚¬â„¢utiliser.';

  @override
  String get marketplace_publish_name_hint => 'ex: Bot de ModÃƒÂ©ration IA';

  @override
  String get marketplace_publish_name_label => 'Nom du template';

  @override
  String get marketplace_publish_next => 'Suivant';

  @override
  String get marketplace_publish_no_content =>
      'Aucune commande ou workflow ÃƒÂ  publier.\nCrÃƒÂ©e-en dÃ¢â‚¬â„¢abord !';

  @override
  String get marketplace_publish_required_fields =>
      'Veuillez remplir tous les champs requis (Nom, Description courte, Version) avant de publier.';

  @override
  String get marketplace_publish_select => 'SÃƒÂ©lectionner le contenu';

  @override
  String get marketplace_publish_select_all => 'Tout sÃƒÂ©lectionner';

  @override
  String get marketplace_publish_select_hint =>
      'Choisis des commandes, des workflows, ou les deux.';

  @override
  String get marketplace_publish_success =>
      'Template publiÃƒÂ© avec succÃƒÂ¨s !';

  @override
  String get marketplace_publish_summary => 'RÃƒÂ©sumÃƒÂ© du template';

  @override
  String get marketplace_publish_tags_hint => 'ex: openai, chatbot, moderation';

  @override
  String get marketplace_publish_tags_label =>
      'Tags (sÃƒÂ©parÃƒÂ©s par des virgules)';

  @override
  String get marketplace_publish_title => 'Publier un template';

  @override
  String get marketplace_publish_user_must_define =>
      'LÃ¢â‚¬â„¢utilisateur doit dÃƒÂ©finir cette valeur';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'LÃ¢â‚¬â„¢utilisateur sera invitÃƒÂ© ÃƒÂ  la remplir avant dÃ¢â‚¬â„¢appliquer';

  @override
  String get marketplace_publish_variable_desc_hint =>
      'Ãƒâ‚¬ quoi sert cette variable';

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
      'Inclus des variables et indique lesquelles lÃ¢â‚¬â„¢utilisateur doit remplir.';

  @override
  String get marketplace_publish_version_label => 'Version';

  @override
  String marketplace_publish_workflows(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get marketplace_publishing => 'Publication en cours...';

  @override
  String get marketplace_rate_success => 'Note envoyÃƒÂ©e !';

  @override
  String get marketplace_rate_title => 'Noter ce template';

  @override
  String get marketplace_retry => 'RÃƒÂ©essayer';

  @override
  String get marketplace_search_hint => 'Rechercher des templates...';

  @override
  String get marketplace_title => 'MarchÃƒÂ©';

  @override
  String marketplace_variable_required(Object name) {
    return '$name est obligatoire';
  }

  @override
  String get marketplace_variables_label => 'Variables prÃƒÂ©-configurÃƒÂ©es';

  @override
  String marketplace_workflows_label(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get modal_add_text_input => 'Ajouter un champ texte';

  @override
  String get modal_builder_title => 'Constructeur de modal';

  @override
  String get modal_custom_id_hint => 'UtilisÃƒÂ© pour identifier ce modal';

  @override
  String get modal_custom_id_label => 'ID personnalisÃƒÂ©';

  @override
  String get modal_default_value => 'Valeur par dÃƒÂ©faut';

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
      'Ce champ sera supprimÃƒÂ© du modal. Continuer ?';

  @override
  String get modal_remove_field_title => 'Supprimer le champ modal';

  @override
  String get modal_style => 'Style :';

  @override
  String get modal_title_label => 'Titre du modal';

  @override
  String get modal_workflow_submit =>
      'Workflow ÃƒÂ  exÃƒÂ©cuter ÃƒÂ  la soumission (optionnel)';

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
    return 'CrÃƒÂ©er le workflow \"$query\"';
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
  String get onboarding_command_desc => 'CrÃƒÂ©ez votre premiÃƒÂ¨re commande';

  @override
  String get onboarding_command_example =>
      'Exemple:\n/hello Ã¢â€ â€™ Le bot rÃƒÂ©pond \"Bonjour! Ã°Å¸â€˜â€¹\"';

  @override
  String get onboarding_command_learn => 'Learn how commands work';

  @override
  String get onboarding_command_text =>
      'Les commandes sont le cÃ…â€œur de votre bot. Elles permettent aux utilisateurs d\'interagir avec votre bot via Discord.';

  @override
  String get onboarding_command_title => 'Ãƒâ€°tape 2: Ajouter une commande';

  @override
  String get onboarding_create_button => 'Continuer';

  @override
  String get onboarding_create_desc => 'Obtenez votre token Discord';

  @override
  String get onboarding_create_open_portal =>
      'Ouvrir le portail Discord Developer';

  @override
  String get onboarding_create_steps =>
      '1. Allez sur Discord Developer Portal\n2. CrÃƒÂ©ez une nouvelle app\n3. Copiez le token du bot\n4. Collez-le ci-dessous';

  @override
  String get onboarding_create_tip =>
      'Conseil: Ne partagez jamais votre token! Il donne accÃƒÂ¨s complet ÃƒÂ  votre bot.';

  @override
  String get onboarding_create_title => 'Ãƒâ€°tape 1: CrÃƒÂ©er un bot';

  @override
  String get onboarding_create_tutorial => 'Tutoriel: Comment obtenir un token';

  @override
  String get onboarding_remind_later => 'Me le rappeler plus tard';

  @override
  String get onboarding_skip_confirm => 'Skip onboarding';

  @override
  String get onboarding_skip_dialog_desc =>
      'You can resume where you left off next time, or skip the tour entirely.';

  @override
  String get onboarding_skip_dialog_title => 'Leave the onboarding?';

  @override
  String get onboarding_start_button => 'Continuer';

  @override
  String get onboarding_start_desc => 'Lancez votre bot!';

  @override
  String get onboarding_start_hint =>
      'Une fois ton bot crÃƒÂ©ÃƒÂ©, tu trouveras le bouton DÃƒÂ©marrer sur sa carte dans l\'application.';

  @override
  String get onboarding_start_text =>
      'Appuyez sur le bouton \"DÃƒÂ©marrer\" sur la carte de votre bot. Testez ensuite votre commande dans Discord!';

  @override
  String get onboarding_start_tip =>
      'Bravo! Vous avez crÃƒÂ©ÃƒÂ© votre premier bot Discord. Vous pouvez maintenant ajouter plus de commandes et le personnaliser!';

  @override
  String get onboarding_start_title => 'Ãƒâ€°tape 3: Lancer le bot';

  @override
  String onboarding_step_indicator(int current, int total) {
    return 'Ãƒâ€°tape $current sur $total';
  }

  @override
  String get onboarding_success_button => 'Commencer!';

  @override
  String get onboarding_success_desc =>
      'Votre bot Discord est maintenant prÃƒÂªt ÃƒÂ  l\'emploi!';

  @override
  String get onboarding_success_tip1 => 'Ajouter plus de commandes';

  @override
  String get onboarding_success_tip2 => 'CrÃƒÂ©er des workflows';

  @override
  String get onboarding_success_tip3 => 'Sauvegarder vos donnÃƒÂ©es';

  @override
  String get onboarding_success_title => 'Bravo!';

  @override
  String get onboarding_success_whatsnext => 'Que faire maintenant?';

  @override
  String get onboarding_welcome_desc =>
      'CrÃƒÂ©ez votre premier bot Discord en 3 ÃƒÂ©tapes simples. Nous vous guidons ÃƒÂ  travers chaque ÃƒÂ©tape.';

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
      'Ce choix sera supprimÃƒÂ©. Continuer ?';

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
      'Cet argument sera supprimÃƒÂ©. Continuer ?';

  @override
  String get option_delete_argument_title => 'Supprimer l\'argument';

  @override
  String get option_delete_choice_confirm =>
      'Ce choix sera supprimÃƒÂ©. Continuer ?';

  @override
  String get option_delete_choice_title => 'Supprimer l\'option';

  @override
  String get option_delete_confirm =>
      'Cette option sera supprimÃƒÂ©e. Continuer ?';

  @override
  String get option_delete_localization_confirm =>
      'Cette entrÃƒÂ©e de localisation sera supprimÃƒÂ©e. Continuer ?';

  @override
  String get option_delete_localization_title => 'Supprimer la localisation';

  @override
  String get option_delete_title => 'Supprimer l\'option';

  @override
  String get option_desc_required =>
      'Veuillez entrer une description pour l\'option';

  @override
  String option_label_number(int index) {
    return 'Ãƒâ€°tiquette $index';
  }

  @override
  String get option_localized_description => 'Description localisÃƒÂ©e';

  @override
  String get option_localized_name => 'Nom localisÃƒÂ©';

  @override
  String get option_max_value => 'Valeur max';

  @override
  String get option_min_value => 'Valeur min';

  @override
  String get option_name_duplicate =>
      'Ce nom est dÃƒÂ©jÃƒÂ  utilisÃƒÂ© ÃƒÂ  ce niveau';

  @override
  String get option_name_invalid_chars =>
      'Le nom de l\'option ne peut contenir que des lettres, chiffres et underscores';

  @override
  String get option_name_invalid_start =>
      'Le nom de l\'option commence par un caractÃƒÂ¨re non pris en charge';

  @override
  String get option_name_max_length =>
      'Le nom de l\'option doit contenir au maximum 32 caractÃƒÂ¨res';

  @override
  String get option_name_required => 'Veuillez saisir un nom pour l\'option';

  @override
  String get option_select_language => 'SÃƒÂ©lectionner la langue';

  @override
  String option_static_label_n(int index) {
    return 'LibellÃƒÂ© $index';
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
  String get option_type_attachment => 'PiÃƒÂ¨ce jointe';

  @override
  String get option_type_boolean => 'BoolÃƒÂ©en';

  @override
  String get option_type_channel => 'Canal';

  @override
  String get option_type_integer => 'Entier';

  @override
  String get option_type_mentionable => 'Mentionnable';

  @override
  String get option_type_number => 'Nombre';

  @override
  String get option_type_role => 'RÃƒÂ´le';

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
      'Merci pour votre soutien ! Toutes les publicitÃƒÂ©s sont dÃƒÂ©sactivÃƒÂ©es.';

  @override
  String get premium_active_title => 'Premium actif';

  @override
  String get premium_card_button => 'Voir les offres';

  @override
  String get premium_card_desc =>
      'Abonnez-vous pour supprimer toutes les publicitÃƒÂ©s et dÃƒÂ©marrer vos bots instantanÃƒÂ©ment, sans aucune pop-up.';

  @override
  String get premium_card_title => 'Supprimer les pubs';

  @override
  String get quick_access_title => 'AccÃƒÂ¨s rapide';

  @override
  String get recovery_delete_bot => 'Supprimer le bot localement';

  @override
  String get recovery_label => 'RÃƒÂ©cupÃƒÂ©ration';

  @override
  String get recovery_retry_discord => 'Retenter la connexion Discord';

  @override
  String get recovery_title => 'Mode rÃƒÂ©cupÃƒÂ©ration';

  @override
  String reply_active_route(String label) {
    return 'Route active : $label';
  }

  @override
  String get reply_buttons_desc =>
      'Ajouter des boutons interactifs ou des menus dÃƒÂ©roulants ÃƒÂ  ce message';

  @override
  String get reply_buttons_optional =>
      'Boutons et menus de sÃƒÂ©lection (optionnel)';

  @override
  String get reply_choose_type =>
      'Choisissez le type de rÃƒÂ©ponse ÃƒÂ  envoyer';

  @override
  String get reply_command_reply_title => 'RÃƒÂ©ponse de commande';

  @override
  String get reply_configure_workflow => 'Configurer le workflow de rÃƒÂ©ponse';

  @override
  String get reply_editor_title => 'DÃƒÂ©tails de la rÃƒÂ©ponse';

  @override
  String get reply_mode_layout => 'Mode mise en page';

  @override
  String get reply_mode_layout_desc =>
      'SystÃƒÂ¨me de mise en page riche de Discord Ã¢â‚¬â€ conteneurs, mÃƒÂ©dias, texte et formulaires';

  @override
  String get reply_mode_modal => 'Formulaire modal';

  @override
  String get reply_mode_modal_desc =>
      'FenÃƒÂªtre pop-up avec champs de saisie texte';

  @override
  String get reply_mode_standard => 'Message standard';

  @override
  String get reply_mode_standard_desc =>
      'Texte, embeds et boutons / menus de sÃƒÂ©lection optionnels';

  @override
  String get reply_response_text_helper =>
      'UtilisÃƒÂ© comme texte de rÃƒÂ©ponse de commande slash. Supporte la syntaxe ((variable)).';

  @override
  String get reply_response_text_label => 'Texte de rÃƒÂ©ponse';

  @override
  String get reply_response_workflow => 'Workflow de rÃƒÂ©ponse';

  @override
  String response_embeds_count(int count) {
    return '$count intÃƒÂ©gration(s)';
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
  String get response_visibility_ephemeral => 'ÃƒÂ©phÃƒÂ©mÃƒÂ¨re';

  @override
  String get response_visibility_public => 'public';

  @override
  String get response_workflow_auto_defer =>
      'Auto-defer si des actions existent';

  @override
  String get response_workflow_auto_defer_desc =>
      'Acquitter rapidement, exÃƒÂ©cuter les actions, puis modifier la rÃƒÂ©ponse finale.';

  @override
  String get response_workflow_condition_desc =>
      'Si la variable existe et n\'est pas vide => utiliser THEN, sinon ELSE.';

  @override
  String get response_workflow_conditional_title =>
      'RÃƒÂ©ponse conditionnelle (MVP)';

  @override
  String get response_workflow_deferred_reply => 'RÃƒÂ©ponse diffÃƒÂ©rÃƒÂ©e';

  @override
  String get response_workflow_else_text =>
      'Texte de rÃƒÂ©ponse ELSE (optionnel)';

  @override
  String get response_workflow_enable_condition => 'Activer la condition';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Ãƒâ€°phÃƒÂ©mÃƒÂ¨re (utilisateur de la commande uniquement)';

  @override
  String get response_workflow_error_policy => 'Politique d\'erreur';

  @override
  String get response_workflow_error_policy_desc =>
      'Quand une action ÃƒÂ©choue, modifier le message diffÃƒÂ©rÃƒÂ© avec une erreur.';

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
  String get response_workflow_then_text =>
      'Texte de rÃƒÂ©ponse THEN (optionnel)';

  @override
  String get response_workflow_title => 'Workflow de rÃƒÂ©ponse';

  @override
  String get response_workflow_variable_key =>
      'ClÃƒÂ© de variable (ex : opts.userId)';

  @override
  String get response_workflow_visibility => 'VisibilitÃƒÂ©';

  @override
  String get restore_completed => 'Restauration terminÃƒÂ©e';

  @override
  String get restore_runtime_db_recommended =>
      'Restauration terminÃƒÂ©e (Base SQLite restaurÃƒÂ©e, redÃƒÂ©marrage conseillÃƒÂ©)';

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
  String get review_legacy_mode => 'Mode legacy activÃƒÂ©';

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
  String get review_reply_title => 'RÃƒÂ©ponse';

  @override
  String review_subcommand_routes(int count) {
    return '$count route(s) de sous-commande';
  }

  @override
  String get review_trigger_inputs_title => 'DÃƒÂ©clencheur et entrÃƒÂ©es';

  @override
  String review_type_line(String type) {
    return 'Type : $type';
  }

  @override
  String get rewarded_start_complete_ad =>
      'Veuillez regarder la publicitÃƒÂ© en entier pour lancer votre session d\'hÃƒÂ©bergement.';

  @override
  String get rewarded_start_continue => 'Continuer';

  @override
  String get rewarded_start_message =>
      'Une publicitÃƒÂ© est requise pour lancer cette session d\'hÃƒÂ©bergement. Cela aide ÃƒÂ  financer le projet. Les utilisateurs Premium peuvent ignorer cela.';

  @override
  String get rewarded_start_no_ad_available =>
      'Aucune publicitÃƒÂ© disponible pour le moment. Veuillez rÃƒÂ©essayer plus tard.';

  @override
  String get rewarded_start_skip => 'Ignorer';

  @override
  String get rewarded_start_thanks => 'Merci pour votre soutien !';

  @override
  String get rewarded_start_title => 'Pub requise';

  @override
  String get rewarded_start_watch => 'Regarder la pub';

  @override
  String get runner_select_source => 'SÃƒÂ©lectionner le runner';

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
      'Connectez-vous ÃƒÂ  Bot Creator dans les paramÃƒÂ¨tres pour charger les statistiques depuis les serveurs Bot Creator.';

  @override
  String get save => 'Enregistrer';

  @override
  String get scheduler_add_title => 'Ajouter un planning';

  @override
  String get scheduler_add_trigger => 'Ajouter un dÃƒÂ©clencheur';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Supprimer le planning Ã‚Â« $label Ã‚Â» ?';
  }

  @override
  String get scheduler_delete_title => 'Supprimer le planning';

  @override
  String get scheduler_edit_title => 'Modifier le planning';

  @override
  String get scheduler_empty => 'Aucun dÃƒÂ©clencheur planifiÃƒÂ©.';

  @override
  String get scheduler_every_minutes => 'Toutes les (minutes)';

  @override
  String get scheduler_invalid_minutes =>
      'Les minutes doivent ÃƒÂªtre supÃƒÂ©rieures ÃƒÂ  0.';

  @override
  String get scheduler_label_field => 'LibellÃƒÂ©';

  @override
  String get scheduler_label_hint => 'LibellÃƒÂ© d\'affichage optionnel';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Limite du planificateur atteinte ($limit).';
  }

  @override
  String get scheduler_no_workflows =>
      'CrÃƒÂ©ez au moins un workflow avant d\'ajouter un planning.';

  @override
  String get scheduler_page_title => 'Planificateur';

  @override
  String scheduler_save_failed(String error) {
    return 'Ãƒâ€°chec de l\'enregistrement du planning : $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow : $workflow Ã¢â€šÂ¬Ã‚Â¢ Toutes les $minutes min';
  }

  @override
  String get scheduler_tab => 'Planificateur';

  @override
  String get scheduler_tab_short => 'Planif';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'DÃƒÂ©clencheurs : $count$limit';
  }

  @override
  String get scoped_default_value => 'Valeur par dÃƒÂ©faut';

  @override
  String get scoped_default_value_hint => 'Optionnel';

  @override
  String scoped_delete_confirm(String key) {
    return 'Supprimer Ã‚Â« $key Ã‚Â» et toutes ses donnÃƒÂ©es runtime stockÃƒÂ©es ?';
  }

  @override
  String get scoped_delete_title => 'Supprimer la variable scopÃƒÂ©e';

  @override
  String get scoped_empty => 'Aucune variable scopÃƒÂ©e dÃƒÂ©finie';

  @override
  String get scoped_empty_subtitle =>
      'Les variables scopÃƒÂ©es stockent une valeur par contexte Discord (utilisateur, serveur...). Elles sont peuplÃƒÂ©es par le bot ÃƒÂ  l\'exÃƒÂ©cution.';

  @override
  String get scoped_explore_runtime => 'Explorer les donnÃƒÂ©es runtime';

  @override
  String scoped_ref(String ref) {
    return 'RÃƒÂ©fÃƒÂ©rence : $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legacy : $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Tout copier';

  @override
  String get scoped_runtime_empty =>
      'Aucune donnÃƒÂ©e runtime.\nCette clÃƒÂ© sera peuplÃƒÂ©e par le bot ÃƒÂ  l\'exÃƒÂ©cution.';

  @override
  String get scoped_runtime_search => 'Rechercher par ID ou nom...';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Scope : $scope Ã‚Â· $count contexte(s) trouvÃƒÂ©(s)';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'DonnÃƒÂ©es runtime Ã¢â‚¬â€ Ã‚Â« $key Ã‚Â»';
  }

  @override
  String get scoped_scope => 'PortÃƒÂ©e';

  @override
  String get scoped_scope_help =>
      'Le niveau d\'entitÃƒÂ© auquel la variable est stockÃƒÂ©e.';

  @override
  String get scoped_title => 'Variables scopÃƒÂ©es';

  @override
  String get scratch_add_block => 'Ajouter un bloc';

  @override
  String get scratch_bdfd_script => 'Script BDFD';

  @override
  String get scratch_block_entry_point => 'Point de dÃƒÂ©part (DÃƒÂ©clencheur)';

  @override
  String get scratch_block_metadata => 'MÃƒÂ©tadonnÃƒÂ©es';

  @override
  String get scratch_block_required => 'Requis';

  @override
  String get scratch_blocks_tab => 'Blocs';

  @override
  String get scratch_custom_id_filter_desc =>
      'Ce workflow ne sera exÃƒÂ©cutÃƒÂ© que si le Custom ID du bouton cliquÃƒÂ© ou du modal soumis correspond exactement ÃƒÂ  l\'ID ci-dessus.';

  @override
  String get scratch_custom_id_filter_hint => 'ex : mon_bouton_id';

  @override
  String get scratch_custom_id_filter_label => 'Filtre Custom ID (optionnel)';

  @override
  String get scratch_dart_script => 'Script Dart';

  @override
  String get scratch_entry_event_trigger => 'DÃƒÂ©clencheur d\'ÃƒÂ©vÃƒÂ©nement';

  @override
  String get scratch_entry_function => 'Fonction';

  @override
  String get scratch_entry_interaction => 'Commande Slash (/)';

  @override
  String get scratch_entry_message => 'Message Texte';

  @override
  String get scratch_entry_point_hint => 'Indice du point d\'entrÃƒÂ©e scratch';

  @override
  String get scratch_entry_point_label => 'Nom du point d\'entrÃƒÂ©e';

  @override
  String get scratch_entry_point_listen =>
      'Quand est-ce que cette commande se lance ?';

  @override
  String get scratch_event_category => 'CatÃƒÂ©gorie d\'ÃƒÂ©vÃƒÂ©nement';

  @override
  String get scratch_event_name => 'Nom de l\'ÃƒÂ©vÃƒÂ©nement';

  @override
  String get scratch_event_variables => 'Variables d\'ÃƒÂ©vÃƒÂ©nement';

  @override
  String get scratch_execution_mode => 'Comment est construite la commande ?';

  @override
  String get scratch_legacy_config => 'Configuration hÃƒÂ©ritÃƒÂ©e';

  @override
  String get scratch_meta_advanced => 'ParamÃƒÂ¨tres avancÃƒÂ©s';

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
      'DÃƒÂ©clenchÃƒÂ©e depuis le menu contextuel message.';

  @override
  String get scratch_meta_type_prefix => 'Commande prÃƒÂ©fixe';

  @override
  String get scratch_meta_type_prefix_desc =>
      'DÃƒÂ©clenchÃƒÂ©e par un prÃƒÂ©fixe texte (ex : !help).';

  @override
  String get scratch_meta_type_slash => 'Commande slash';

  @override
  String get scratch_meta_type_slash_desc =>
      'DÃƒÂ©clenchÃƒÂ©e en tapant / dans Discord.';

  @override
  String get scratch_meta_type_user => 'Commande utilisateur';

  @override
  String get scratch_meta_type_user_desc =>
      'DÃƒÂ©clenchÃƒÂ©e depuis le menu contextuel utilisateur.';

  @override
  String get scratch_mode_bdfd => 'Code BDFD';

  @override
  String get scratch_mode_blocks => 'Visuel (Blocs)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => 'RÃƒÂ©ponse';

  @override
  String get scratch_response_components => 'Composants';

  @override
  String get scratch_response_edit => 'Modifier la rÃƒÂ©ponse';

  @override
  String get scratch_trigger_tab => 'DÃƒÂ©clencheur';

  @override
  String get scratch_wizard_actions_empty_desc =>
      'Ajoutez des blocs d\'actions ci-dessous pour configurer ce que fait votre bot.';

  @override
  String get scratch_wizard_actions_empty_title =>
      'Aucune action dÃƒÂ©finie pour le moment.';

  @override
  String get scratch_wizard_config_button_instruction =>
      'Configurez l\'ID du bouton ou du modal qui dÃƒÂ©clenchera ce workflow.';

  @override
  String get scratch_wizard_folder_hint => 'ex : administration';

  @override
  String get scratch_wizard_folder_label => 'Dossier (optionnel)';

  @override
  String get scratch_wizard_save_details => 'DÃƒÂ©tails d\'enregistrement';

  @override
  String get scratch_wizard_step_actions => 'Ãƒâ€°tape 3 : Actions';

  @override
  String get scratch_wizard_step_config => 'Ãƒâ€°tape 2 : Configuration';

  @override
  String get scratch_wizard_step_save => 'Ãƒâ€°tape 4 : Enregistrement';

  @override
  String get scratch_wizard_step_trigger => 'Ãƒâ€°tape 1 : DÃƒÂ©clencheur';

  @override
  String scratch_wizard_summary_actions_count(int count) {
    return '$count action(s) configurÃƒÂ©e(s)';
  }

  @override
  String get scratch_wizard_summary_title => 'RÃƒÂ©sumÃƒÂ© du Workflow';

  @override
  String scratch_wizard_summary_trigger_button(String id) {
    return 'Clic de bouton / Modal (Custom ID : \'$id\')';
  }

  @override
  String scratch_wizard_summary_trigger_event(String event) {
    return 'Ãƒâ€°vÃƒÂ©nement : $event';
  }

  @override
  String get scratch_wizard_summary_trigger_function =>
      'Fonction / Workflow GÃƒÂ©nÃƒÂ©ral';

  @override
  String get scratch_wizard_trigger_button_desc =>
      'Se dÃƒÂ©clenche lorsqu\'un utilisateur clique sur un bouton de message ou soumet un formulaire (modal).';

  @override
  String get scratch_wizard_trigger_button_title =>
      'Bouton ou Composant de message';

  @override
  String get scratch_wizard_trigger_event_desc =>
      'Se dÃƒÂ©clenche sur une action Discord spÃƒÂ©cifique (ex : nouveau membre rejoint, message supprimÃƒÂ©, rÃƒÂ´le modifiÃƒÂ©).';

  @override
  String get scratch_wizard_trigger_event_title => 'Ãƒâ€°vÃƒÂ©nement Discord';

  @override
  String get scratch_wizard_trigger_function_desc =>
      'ExÃƒÂ©cute le workflow en tant que fonction pouvant ÃƒÂªtre appelÃƒÂ©e par d\'autres dÃƒÂ©clencheurs.';

  @override
  String get scratch_wizard_trigger_function_title =>
      'Fonction ou DÃƒÂ©clencheur manuel';

  @override
  String get scratch_wizard_trigger_instruction =>
      'Choisissez l\'ÃƒÂ©vÃƒÂ©nement qui dÃƒÂ©clenchera ce scÃƒÂ©nario (workflow) :';

  @override
  String get scratch_wizard_workflow_name_hint => 'ex : reponse_bouton';

  @override
  String get scratch_wizard_workflow_name_label => 'Nom du workflow *';

  @override
  String get scratch_workflow_add_argument => 'Ajouter un argument';

  @override
  String get scratch_workflow_arguments => 'Arguments (Variables)';

  @override
  String get scratch_workflow_metadata => 'ParamÃƒÂ¨tres du workflow';

  @override
  String get scratch_workflow_name => 'Nom du workflow';

  @override
  String get scratch_workflow_type => 'Type de workflow';

  @override
  String get scratch_workflow_type_event => 'Ãƒâ€°vÃƒÂ©nement';

  @override
  String get scratch_workflow_type_general => 'GÃƒÂ©nÃƒÂ©ral';

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
  String get serialization_imported =>
      'Commande importÃƒÂ©e dans l\'ÃƒÂ©diteur.';

  @override
  String get serialization_invalid_format =>
      'Format de payload de commande invalide.';

  @override
  String get serialization_invalid_structure =>
      'Structure de payload de commande invalide.';

  @override
  String get settings_account_connect_label =>
      'Se connecter ÃƒÂ  Bot Creator avec Discord';

  @override
  String get settings_account_connected_hint =>
      'Compte connectÃƒÂ©. Vos bots et vos donnÃƒÂ©es sont synchronisÃƒÂ©s avec Bot Creator.';

  @override
  String get settings_account_disconnect_label => 'Se dÃƒÂ©connecter';

  @override
  String get settings_account_disconnected_hint =>
      'Votre compte Bot Creator est crÃƒÂ©ÃƒÂ© automatiquement quand vous ajoutez un bot. Connectez-vous ensuite avec Discord pour rÃƒÂ©cupÃƒÂ©rer vos bots sur cet appareil.';

  @override
  String get settings_account_status_connected => 'Compte connectÃƒÂ©';

  @override
  String get settings_account_status_disconnected => 'Compte non connectÃƒÂ©';

  @override
  String get settings_ads_privacy_loading =>
      'VÃƒÂ©rification des paramÃƒÂ¨tres de confidentialitÃƒÂ© pub...';

  @override
  String get settings_ads_privacy_manage =>
      'GÃƒÂ©rer les choix de confidentialitÃƒÂ© pub';

  @override
  String get settings_ads_privacy_not_required =>
      'Options de confidentialitÃƒÂ© pub non requises pour le moment';

  @override
  String get settings_ads_privacy_open_error =>
      'Impossible d\'ouvrir les options de confidentialitÃƒÂ© pub';

  @override
  String get settings_ads_privacy_opened =>
      'Options de confidentialitÃƒÂ© pub ouvertes';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_appearance_title => 'Apparence et langue';

  @override
  String get settings_auto_backup_check_loading =>
      'VÃƒÂ©rification auto-sauvegarde...';

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
      'GÃƒÂ©rez la synchronisation de vos donnÃƒÂ©es avec Google Drive';

  @override
  String get settings_backup_restore_title => 'Sauvegarde et restauration';

  @override
  String get settings_builtin_help => 'Commande !help legacy intÃƒÂ©grÃƒÂ©e';

  @override
  String get settings_builtin_help_subtitle =>
      'FonctionnalitÃƒÂ© obligatoire avec toggle explicite. DÃƒÂ©sactivez-la pour ne garder qu\'un comportement d\'aide personnalisÃƒÂ©.';

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
      'ContrÃƒÂ´le de flux';

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
    return 'Total rÃƒÂ©fÃƒÂ©rence BDFD : $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'SupportÃƒÂ©es sur Bot Creator : $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Exclusives Bot Creator : $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return 'SupportÃƒÂ©es sur les deux : $count';
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
      'Les entrÃƒÂ©es BDFD uniquement correspondent aux fonctions de la liste BDFD fournie qui ne sont pas encore implÃƒÂ©mentÃƒÂ©es dans Bot Creator.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Vue diff entre l\'implÃƒÂ©mentation Bot Creator et la rÃƒÂ©fÃƒÂ©rence des fonctions BDFD.';

  @override
  String get settings_compatibility_functions_note =>
      'Cette page reflÃƒÂ¨te l\'implÃƒÂ©mentation actuelle et ÃƒÂ©voluera au fil des mises ÃƒÂ  jour.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Rechercher une fonction (exemple : \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'SupportÃƒÂ©es uniquement sur Bot Creator';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Les helpers de boucle sont actuellement spÃƒÂ©cifiques ÃƒÂ  Bot Creator.';

  @override
  String get settings_compatibility_functions_section_both =>
      'SupportÃƒÂ©es sur Bot Creator et BDFD';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Disponibles sur BDFD mais manquantes sur Bot Creator';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Fonctions actuellement implÃƒÂ©mentÃƒÂ©es et utilisables dans le mode BDFD de Bot Creator.';

  @override
  String get settings_compatibility_functions_title =>
      'Fonctions BDFD compatibles';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Couverture complÃƒÂ¨te du catalogue de fonctions BDFD.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'ParitÃƒÂ© des fonctions BDScript';

  @override
  String get settings_compatibility_item_events_desc =>
      'Les ÃƒÂ©vÃƒÂ©nements courants sont couverts, certains restent limitÃƒÂ©s en runtime.';

  @override
  String get settings_compatibility_item_events_title =>
      'Couverture des ÃƒÂ©vÃƒÂ©nements';

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
      'Les workflows visuels de commandes et de rÃƒÂ©ponses sont disponibles.';

  @override
  String get settings_compatibility_item_workflows_title =>
      'Ãƒâ€°diteur de workflows';

  @override
  String get settings_compatibility_note =>
      'Cet aperÃƒÂ§u reste volontairement synthÃƒÂ©tique et ÃƒÂ©voluera par release.';

  @override
  String get settings_compatibility_open_functions =>
      'Voir les fonctions compatibles';

  @override
  String get settings_compatibility_status_missing => 'Absent';

  @override
  String get settings_compatibility_status_partial => 'Partiel';

  @override
  String get settings_compatibility_status_supported => 'SupportÃƒÂ©';

  @override
  String get settings_compatibility_title => 'AperÃƒÂ§u compatibilitÃƒÂ© BDFD';

  @override
  String get settings_data_operations_title => 'OpÃƒÂ©rations de donnÃƒÂ©es';

  @override
  String get settings_debug_desc =>
      'RÃƒÂ©initialise les prÃƒÂ©fÃƒÂ©rences locales ou relance l\'onboarding pour les tests.';

  @override
  String get settings_debug_premium_bypass => 'Bypass Premium';

  @override
  String get settings_debug_premium_bypass_desc =>
      'DÃƒÂ©bloque toutes les fonctionnalitÃƒÂ©s Premium sans abonnement (debug uniquement).';

  @override
  String get settings_debug_title => 'Outils de debug';

  @override
  String get settings_diagnostics_copied =>
      'Diagnostics copiÃƒÂ©s dans le presse-papiers';

  @override
  String get settings_diagnostics_copy_all => 'Copier tous les logs';

  @override
  String get settings_diagnostics_dialog_title => 'Diagnostics de dÃƒÂ©marrage';

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
      'Authentification auprÃƒÂ¨s de Discord...';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Code d\'autorisation en cache ; relancez pour terminer l\'ÃƒÂ©change du token';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Code d\'autorisation reÃƒÂ§u';

  @override
  String get settings_discord_rpc_authorize => 'Autoriser';

  @override
  String get settings_discord_rpc_authorizing =>
      'En attente de l\'autorisation Discord...';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'URL du broker OAuth (avancÃƒÂ©e, optionnelle)';

  @override
  String get settings_discord_rpc_broker_required =>
      'Le Client ID suffit pour le flow public client ; l\'URL du broker et le client secret restent optionnels';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Cet identifiant est fixÃƒÂ© dans Bot Creator et ne peut pas ÃƒÂªtre modifiÃƒÂ© depuis les paramÃƒÂ¨tres.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Le client ID Discord est requis';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Solution avancÃƒÂ©e optionnelle pour un flow confidentiel gÃƒÂ©rÃƒÂ© localement.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Client secret';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Client secret de l\'application Discord (optionnel)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Finaliser l\'autorisation';

  @override
  String get settings_discord_rpc_connect => 'RafraÃƒÂ®chir la prÃƒÂ©sence';

  @override
  String get settings_discord_rpc_connected =>
      'PrÃƒÂ©sence envoyÃƒÂ©e ÃƒÂ  Discord';

  @override
  String get settings_discord_rpc_connecting => 'Connexion ÃƒÂ  Discord...';

  @override
  String get settings_discord_rpc_desc =>
      'Publie l\'activitÃƒÂ© desktop de Bot Creator dans le client Discord local. Bot Creator utilise toujours l\'application Discord intÃƒÂ©grÃƒÂ©e et envoie SET_ACTIVITY directement via l\'IPC local quand l\'option est activÃƒÂ©e.';

  @override
  String get settings_discord_rpc_disabled => 'DÃƒÂ©sactivÃƒÂ©';

  @override
  String get settings_discord_rpc_disconnect => 'Fermer l\'IPC';

  @override
  String get settings_discord_rpc_disconnected => 'IPC fermÃƒÂ©';

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
      'Finalisation de l\'ÃƒÂ©change OAuth...';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'IPC Discord local connectÃƒÂ© ; aucune requÃƒÂªte OAuth HTTP envoyÃƒÂ©e pour l\'instant, authentification encore requise';

  @override
  String get settings_discord_rpc_ipc_open => 'IPC local dÃƒÂ©jÃƒÂ  ouvert';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'DerniÃƒÂ¨re erreur : $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization => 'Autorisation requise';

  @override
  String get settings_discord_rpc_not_configured => 'Client ID requis';

  @override
  String get settings_discord_rpc_open_ipc => 'Ouvrir l\'IPC local';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence est rÃƒÂ©servÃƒÂ© au desktop';

  @override
  String get settings_discord_rpc_save => 'Enregistrer';

  @override
  String get settings_discord_rpc_saved =>
      'ParamÃƒÂ¨tres Discord Rich Presence enregistrÃƒÂ©s';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Le transport Discord n\'est pas encore pris en charge sur cette plateforme';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Utilisateur autorisÃƒÂ© : $user';
  }

  @override
  String get settings_drive_connect => 'Connecter Google Drive';

  @override
  String get settings_drive_connect_loading => 'Connexion ÃƒÂ  Google Drive...';

  @override
  String get settings_drive_connected => 'ConnectÃƒÂ© ÃƒÂ  Google Drive';

  @override
  String get settings_drive_desc =>
      'Connectez votre compte Google Drive pour synchroniser vos donnÃƒÂ©es';

  @override
  String get settings_drive_disconnect => 'DÃƒÂ©connecter';

  @override
  String get settings_drive_disconnect_loading => 'DÃƒÂ©connexion en cours...';

  @override
  String get settings_drive_disconnected => 'DÃƒÂ©connectÃƒÂ© de Google Drive';

  @override
  String get settings_drive_status_connected => 'ConnectÃƒÂ©';

  @override
  String get settings_drive_title => 'Connexion Google Drive';

  @override
  String get settings_enable_auto_backup => 'Activer l\'auto-sauvegarde';

  @override
  String get settings_enable_auto_backup_desc =>
      'CrÃƒÂ©e automatiquement des snapshots versionnÃƒÂ©s lorsque nÃƒÂ©cessaire.';

  @override
  String get settings_execution_mode_desc =>
      'Sur cette plateforme, Bot Creator n\'hÃƒÂ©berge jamais vos bots. Vous pouvez utiliser votre runner self-hosted ou exÃƒÂ©cuter les bots localement.';

  @override
  String get settings_execution_mode_local_active =>
      'Les bots dÃƒÂ©marrent maintenant en local. La configuration runner reste en mÃƒÂ©moire et peut ÃƒÂªtre rÃƒÂ©activÃƒÂ©e ÃƒÂ  tout moment.';

  @override
  String get settings_execution_mode_no_runner =>
      'Aucun runner n\'est encore configurÃƒÂ©. L\'application restera en local tant que vous n\'en ajoutez pas un.';

  @override
  String get settings_execution_mode_runner_priority =>
      'Le runner self-hosted est prioritaire. Si aucun runner n\'est configurÃƒÂ©, l\'application repasse en local.';

  @override
  String get settings_execution_mode_title => 'Mode d\'exÃƒÂ©cution';

  @override
  String get settings_execution_mode_use_runner =>
      'Utiliser un runner self-hosted';

  @override
  String get settings_export => 'Exporter';

  @override
  String get settings_export_app_data => 'Exporter les donnÃƒÂ©es de l\'app';

  @override
  String get settings_export_loading => 'Export en cours...';

  @override
  String get settings_import => 'Importer';

  @override
  String get settings_import_app_data => 'Importer les donnÃƒÂ©es de l\'app';

  @override
  String get settings_import_loading => 'Import en cours...';

  @override
  String get settings_language_desc =>
      'Choisissez la langue utilisÃƒÂ©e par l\'application.';

  @override
  String get settings_language_system => 'Automatique (appareil)';

  @override
  String get settings_language_title => 'Langue';

  @override
  String get settings_language_updated => 'Langue mise ÃƒÂ  jour';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'DerniÃƒÂ¨re auto-sauvegarde : $date';
  }

  @override
  String get settings_last_auto_backup_never =>
      'DerniÃƒÂ¨re auto-sauvegarde : jamais';

  @override
  String get settings_legacy_prefix => 'PrÃƒÂ©fixe des commandes legacy';

  @override
  String get settings_legacy_prefix_helper =>
      'Supporte les templates et variables ÃƒÂ©tendues (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? ou ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Consultez la maniÃƒÂ¨re dont vos donnÃƒÂ©es sont traitÃƒÂ©es et stockÃƒÂ©es.';

  @override
  String get settings_legal_title => 'LÃƒÂ©gal';

  @override
  String get settings_local_hosting_enabled => 'HÃƒÂ©bergement local activÃƒÂ©';

  @override
  String get settings_logs_cleared => 'Logs de diagnostic effacÃƒÂ©s';

  @override
  String get settings_main_api_auth_failed =>
      'La session du serveur Bot Creator est invalide ou expirÃƒÂ©e';

  @override
  String get settings_main_api_check => 'Tester le serveur Bot Creator';

  @override
  String get settings_main_api_clear => 'Effacer';

  @override
  String get settings_main_api_cleared =>
      'ParamÃƒÂ¨tres du serveur Bot Creator effacÃƒÂ©s';

  @override
  String get settings_main_api_connect_discord => 'Connecter le compte Discord';

  @override
  String get settings_main_api_connected =>
      'Serveur Bot Creator accessible Ã¢Å“â€œ';

  @override
  String get settings_main_api_connected_discord =>
      'Compte Discord connectÃƒÂ©';

  @override
  String settings_main_api_connected_user(String user) {
    return 'ConnectÃƒÂ© en tant que $user';
  }

  @override
  String get settings_main_api_desc =>
      'Connectez Bot Creator aux serveurs Bot Creator puis connectez-vous avec Discord. Le secret client Discord doit rester cÃƒÂ´tÃƒÂ© backend.';

  @override
  String get settings_main_api_desktop_only =>
      'La connexion Discord via les serveurs Bot Creator est disponible uniquement sur desktop.';

  @override
  String get settings_main_api_disconnect => 'DÃƒÂ©connecter le compte';

  @override
  String get settings_main_api_not_configured =>
      'URL du serveur Bot Creator requise';

  @override
  String get settings_main_api_save => 'Enregistrer le serveur Bot Creator';

  @override
  String get settings_main_api_saved =>
      'ParamÃƒÂ¨tres du serveur Bot Creator enregistrÃƒÂ©s';

  @override
  String get settings_main_api_session_connected => 'Session Discord active';

  @override
  String get settings_main_api_session_disconnected =>
      'Session Discord dÃƒÂ©connectÃƒÂ©e';

  @override
  String get settings_main_api_session_expired => 'Session Discord expirÃƒÂ©e';

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
      'Avertissements lorsque vos bots se dÃƒÂ©connectent ou rencontrent des erreurs.';

  @override
  String get settings_notifications_topic_broadcast => 'Annonces';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Annonces importantes et actualitÃƒÂ©s de Bot Creator.';

  @override
  String get settings_notifications_topic_updates => 'Mises ÃƒÂ  jour';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Nouvelles fonctionnalitÃƒÂ©s, mises ÃƒÂ  jour et faits marquants.';

  @override
  String get settings_open_ad_inspector =>
      'Ouvrir l\'inspecteur de publicitÃƒÂ©s';

  @override
  String get settings_oss_licenses => 'Licences Open Source';

  @override
  String get settings_owner_badge => 'PROPRIÃƒâ€°TAIRE';

  @override
  String get settings_owner_fallback => 'PropriÃƒÂ©taire';

  @override
  String get settings_personal_owner_fallback => 'Utilisateur personnel';

  @override
  String get settings_personal_owner_id_label => 'ID PropriÃƒÂ©taire : ';

  @override
  String get settings_personal_owner_label => 'PropriÃƒÂ©taire : ';

  @override
  String get settings_personal_ownership => 'PropriÃƒÂ©tÃƒÂ© personnelle';

  @override
  String get settings_preferences_reset_done =>
      'PrÃƒÂ©fÃƒÂ©rences rÃƒÂ©initialisÃƒÂ©es';

  @override
  String get settings_privacy_policy => 'Politique de confidentialitÃƒÂ©';

  @override
  String get settings_raw_json_tile => 'Voir le JSON Brut (RAW JSON)';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'Relancer l\'onboarding';

  @override
  String get settings_replay_onboarding_desc =>
      'RÃƒÂ©initialise l\'onboarding et le relance immÃƒÂ©diatement.';

  @override
  String get settings_reset_preferences =>
      'RÃƒÂ©initialiser les prÃƒÂ©fÃƒÂ©rences';

  @override
  String get settings_reset_preferences_desc =>
      'RÃƒÂ©initialise le thÃƒÂ¨me, la langue et la progression de l\'onboarding.';

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
  String get settings_runner_auth_failed =>
      'Le runner a refusÃƒÂ© le jeton API';

  @override
  String get settings_runner_check => 'Tester la connexion';

  @override
  String get settings_runner_clear => 'Effacer';

  @override
  String get settings_runner_cleared => 'ParamÃƒÂ¨tres du runner effacÃƒÂ©s';

  @override
  String get settings_runner_connected => 'Runner accessible Ã¢Å“â€';

  @override
  String get settings_runner_connecting =>
      'VÃƒÂ©rification de la connexionÃ¢â‚¬Â¦';

  @override
  String get settings_runner_desc =>
      'Connecte l\'application ÃƒÂ  un Bot Creator Runner. Un runner distant doit rester sur un rÃƒÂ©seau de confiance et utiliser un jeton bearer.';

  @override
  String get settings_runner_disable_temp =>
      'DÃƒÂ©sactiver temporairement le Runner';

  @override
  String get settings_runner_disable_temp_desc =>
      'Conserve la configuration du Runner mais force le mode local jusqu\'ÃƒÂ  rÃƒÂ©activation.';

  @override
  String get settings_runner_disconnected => 'Runner dÃƒÂ©connectÃƒÂ©';

  @override
  String get settings_runner_not_connected => 'Non connectÃƒÂ©';

  @override
  String get settings_runner_reenabled => 'Runner rÃƒÂ©activÃƒÂ©';

  @override
  String get settings_runner_save => 'Enregistrer';

  @override
  String get settings_runner_saved => 'ParamÃƒÂ¨tres du runner enregistrÃƒÂ©s';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner temporairement dÃƒÂ©sactivÃƒÂ© (mode local actif)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner temporairement dÃƒÂ©sactivÃƒÂ©';

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
  String get settings_runner_url_cleared => 'URL du runner effacÃƒÂ©e';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'Enregistrer l\'URL';

  @override
  String get settings_runner_url_saved => 'URL du runner enregistrÃƒÂ©e';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps : $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps dans ce snapshot';

  @override
  String get settings_snapshot_create_loading => 'CrÃƒÂ©ation du snapshot...';

  @override
  String settings_snapshot_created_at(String date) {
    return 'CrÃƒÂ©ÃƒÂ© le : $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot crÃƒÂ©ÃƒÂ© : $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'Suppression du snapshot...';

  @override
  String get settings_snapshot_deleted => 'Snapshot supprimÃƒÂ©';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Fichiers : $count Ã¢â‚¬Â¢ Taille : $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID : $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'LibellÃƒÂ© : $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date Ã¢â‚¬Â¢ $count fichiers Ã¢â‚¬Â¢ $size';
  }

  @override
  String get settings_snapshot_no_metadata =>
      'Aucune mÃƒÂ©tadonnÃƒÂ©e d\'application disponible.';

  @override
  String get settings_snapshot_preview_title => 'AperÃƒÂ§u du snapshot';

  @override
  String get settings_snapshot_restore_loading => 'Restauration du snapshot...';

  @override
  String get settings_snapshots_delete_all => 'Supprimer tous les snapshots';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Supprimer dÃƒÂ©finitivement $count snapshot(s) ? Cette action est irrÃƒÂ©versible.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count snapshot(s) supprimÃƒÂ©(s).';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'Suppression de tous les snapshots...';

  @override
  String get settings_snapshots_delete_all_title =>
      'Supprimer tous les snapshots';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Supprimer dÃƒÂ©finitivement \"$label\" ? Cette action est irrÃƒÂ©versible.';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      'Choisissez le snapshot ÃƒÂ  supprimer (du plus ancien au plus rÃƒÂ©cent).';

  @override
  String get settings_snapshots_delete_select_title => 'Supprimer un snapshot';

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Supprimer un snapshot sÃƒÂ©lectionnÃƒÂ©';

  @override
  String get settings_snapshots_empty =>
      'Aucun snapshot trouvÃƒÂ© pour le moment.';

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
      'RecommandÃƒÂ© sur Android et iOS. Les logs, stats et dÃƒÂ©marrages passent par Bot Creator.';

  @override
  String get settings_startup_mode_desc =>
      'Choisissez si vos bots dÃƒÂ©marrent sur les serveurs Bot Creator ou en local sur cet appareil.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'Le mode local reste indisponible sur iOS.';

  @override
  String get settings_startup_mode_ios_warning =>
      'Sur iOS, le mode local n\'est pas pris en charge. Les bots utilisent toujours les serveurs Bot Creator.';

  @override
  String get settings_startup_mode_local_desc =>
      'Les bots dÃƒÂ©marrent maintenant en local sur cet appareil.';

  @override
  String get settings_startup_mode_local_warning =>
      'Le mode local est une option avancÃƒÂ©e rÃƒÂ©servÃƒÂ©e au debug ou ÃƒÂ  des besoins spÃƒÂ©cifiques. Pour un usage normal, laissez les serveurs Bot Creator actifs.';

  @override
  String get settings_startup_mode_title => 'Lancement des bots';

  @override
  String get settings_startup_mode_use_cloud =>
      'Utiliser les serveurs Bot Creator';

  @override
  String get settings_status_remove_confirm =>
      'Cette entrÃƒÂ©e de statut sera supprimÃƒÂ©e. Continuer ?';

  @override
  String get settings_tab => 'ParamÃƒÂ¨tres';

  @override
  String get settings_team_id_label => 'ID de l\'ÃƒÂ©quipe : ';

  @override
  String settings_team_members_label(int count) {
    return 'Membres de l\'ÃƒÂ©quipe ($count)';
  }

  @override
  String get settings_team_name_label => 'Nom de l\'ÃƒÂ©quipe : ';

  @override
  String get settings_team_owner_label => 'Chef d\'ÃƒÂ©quipe';

  @override
  String get settings_team_ownership => 'PropriÃƒÂ©tÃƒÂ© de l\'ÃƒÂ©quipe';

  @override
  String get settings_team_pill => 'Ãƒâ€°QUIPE';

  @override
  String get settings_theme_switch_dark => 'Passer en mode sombre';

  @override
  String get settings_theme_switch_light => 'Passer en mode clair';

  @override
  String get settings_version_title => 'Version';

  @override
  String get settings_view_startup_logs => 'Voir les logs de dÃƒÂ©marrage';

  @override
  String get startup_copy_diagnostics => 'Copier les diagnostics';

  @override
  String get startup_diagnostics_copied =>
      'Diagnostics copiÃƒÂ©s dans le presse-papiers';

  @override
  String get startup_error_title => 'Erreur de dÃƒÂ©marrage';

  @override
  String get startup_failed_message =>
      'Bot Creator n\'a pas pu dÃƒÂ©marrer sur cet appareil.';

  @override
  String get startup_refresh_diagnostics => 'Actualiser les diagnostics';

  @override
  String get subscription_active_annual => 'Premium Ã¢â‚¬â€ Annuel';

  @override
  String get subscription_active_label => 'Offre activeÃ‚Â :';

  @override
  String get subscription_active_monthly => 'Premium Ã¢â‚¬â€ Mensuel';

  @override
  String get subscription_annual_title => 'Annuel';

  @override
  String get subscription_benefit_fast_start =>
      'Bots dÃƒÂ©marrent instantanÃƒÂ©ment, sans pop-up';

  @override
  String get subscription_benefit_no_ads =>
      'Aucune pub dans toute l\'application';

  @override
  String get subscription_benefit_support =>
      'Soutenez le dÃƒÂ©veloppement indÃƒÂ©pendant';

  @override
  String get subscription_error =>
      'L\'achat n\'a pas pu ÃƒÂªtre finalisÃƒÂ©. Veuillez rÃƒÂ©essayer.';

  @override
  String get subscription_error_product_unavailable =>
      'Cette offre est actuellement indisponible. Veuillez rÃƒÂ©essayer plus tard.';

  @override
  String get subscription_error_purchase_start_failed =>
      'L\'achat n\'a pas pu dÃƒÂ©marrer. Veuillez rÃƒÂ©essayer.';

  @override
  String get subscription_error_store_unavailable =>
      'L\'App Store est temporairement indisponible. Veuillez rÃƒÂ©essayer dans un instant.';

  @override
  String get subscription_feature_analytics_desc =>
      'AccÃƒÂ©dez au taux d\'erreur, aux percentiles de latence et aux insights de locale.';

  @override
  String get subscription_feature_analytics_title => 'Analytique avancÃƒÂ©e';

  @override
  String get subscription_feature_auto_restart_desc =>
      'RedÃƒÂ©marre automatiquement le bot quand un redÃƒÂ©marrage complet est requis.';

  @override
  String get subscription_feature_auto_restart_title =>
      'RedÃƒÂ©marrage automatique';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'RÃƒÂ©partit la charge des gros bots entre plusieurs shards.';

  @override
  String get subscription_feature_auto_sharding_title => 'Sharding automatique';

  @override
  String get subscription_feature_coming_soon => 'BientÃƒÂ´t disponible';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Enregistre et rejoue les actions de commande ÃƒÂ©tape par ÃƒÂ©tape.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Replay visuel de debug';

  @override
  String get subscription_feature_instant_start_desc =>
      'Lance les bots immÃƒÂ©diatement sans interruption publicitaire.';

  @override
  String get subscription_feature_instant_start_title =>
      'DÃƒÂ©marrage instantanÃƒÂ©';

  @override
  String get subscription_feature_lavalink_desc =>
      'Jouez de la musique et de l\'audio dans les salons vocaux Discord avec Lavalink.';

  @override
  String get subscription_feature_lavalink_title => 'Module musique & audio';

  @override
  String get subscription_feature_no_ads_desc =>
      'Supprime toutes les insertions publicitaires dans l\'application.';

  @override
  String get subscription_feature_no_ads_title => 'Sans publicitÃƒÂ©';

  @override
  String get subscription_feature_scheduler_desc =>
      'ExÃƒÂ©cute des workflows automatiquement toutes les X minutes (jusqu\'ÃƒÂ  10 actifs).';

  @override
  String get subscription_feature_scheduler_title =>
      'DÃƒÂ©clencheurs planifiÃƒÂ©s';

  @override
  String get subscription_feature_webhooks_desc =>
      'CrÃƒÂ©e des endpoints webhook sÃƒÂ©curisÃƒÂ©s et route les appels vers les workflows.';

  @override
  String get subscription_feature_webhooks_title => 'Webhooks entrants';

  @override
  String get subscription_manage => 'GÃƒÂ©rer l\'abonnement';

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
      'Supprime les pubs et accÃƒÂ¨de ÃƒÂ  toutes les fonctionnalitÃƒÂ©s premium actuelles et ÃƒÂ  venir.';

  @override
  String get subscription_plan_label => 'Premium Basique';

  @override
  String get subscription_privacy => 'Politique de confidentialitÃƒÂ©';

  @override
  String get subscription_restore => 'Restaurer les achats';

  @override
  String get subscription_restore_not_found =>
      'Aucun abonnement actif trouvÃƒÂ©.';

  @override
  String get subscription_restored => 'Abonnement restaurÃƒÂ© avec succÃƒÂ¨s !';

  @override
  String get subscription_save_badge => '-67%';

  @override
  String get subscription_subtitle =>
      'Choisissez une offre pour dÃƒÂ©bloquer toutes les fonctionnalitÃƒÂ©s premium.';

  @override
  String get subscription_success =>
      'Bienvenue dans Premium ! Toutes les publicitÃƒÂ©s ont ÃƒÂ©tÃƒÂ© supprimÃƒÂ©es.';

  @override
  String get subscription_terms => 'Conditions d\'utilisation';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform =>
      'Non disponible sur cette plateforme.';

  @override
  String get support_card_desc =>
      'Une question, un bug, une suggestionÃ‚Â ? Venez discuter avec l\'ÃƒÂ©quipe et la communautÃƒÂ©.';

  @override
  String get support_card_title => 'Support & CommunautÃƒÂ©';

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
    return 'La commande \"$name\" existe dÃƒÂ©jÃƒÂ  et a ÃƒÂ©tÃƒÂ© ignorÃƒÂ©e.';
  }

  @override
  String get template_gallery_apply => 'Utiliser ce template';

  @override
  String template_gallery_apply_error(String error) {
    return 'Impossible d\'appliquer le template : $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return '$count commande(s) et $wCount workflow(s) ajoutÃƒÂ©s depuis le template.';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count commande(s)';
  }

  @override
  String get template_gallery_empty => 'Aucun template disponible.';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Rien ÃƒÂ  supprimer pour $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Voulez-vous vraiment supprimer toutes les commandes et workflows de ce modÃƒÂ¨le ?';

  @override
  String get template_gallery_remove_title => 'Supprimer le modÃƒÂ¨le';

  @override
  String get template_gallery_removed =>
      'Commandes et workflows du modÃƒÂ¨le supprimÃƒÂ©s.';

  @override
  String get template_gallery_subtitle =>
      'DÃƒÂ©marrez rapidement votre bot avec un template prÃƒÂªt ÃƒÂ  l\'emploi.';

  @override
  String get template_gallery_sync_warning =>
      'Commandes sauvegardÃƒÂ©es localement. DÃƒÂ©marrez votre bot pour les enregistrer sur Discord.';

  @override
  String get template_gallery_title => 'ModÃƒÂ¨les';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count workflow(s)';
  }

  @override
  String get template_moderation_description =>
      'Bannir, expulser, rendre muet et supprimer des messages.';

  @override
  String get template_moderation_name => 'Bot de modÃƒÂ©ration';

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
    return 'Le dÃƒÂ©clencheur de callback attendu doit contenir au maximum $max caractÃƒÂ¨res';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Les callbacks attendus nÃƒÂ©cessitent une commande Legacy locale uniquement.';

  @override
  String get validation_command_name_invalid_chars =>
      'Le nom de commande ne peut contenir que des lettres, chiffres et underscores';

  @override
  String validation_command_name_length(int max) {
    return 'Le nom de commande doit contenir au maximum $max caractÃƒÂ¨res';
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
      'Le nom de commande ne peut pas commencer par un diÃƒÂ¨se';

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
      'Les commandes d\'interaction doivent inclure au moins une action de rÃƒÂ©ponse (RÃƒÂ©pondre avec un message, Composant V2 ou Modal).';

  @override
  String get validation_interaction_no_response_short =>
      'Aucune action de rÃƒÂ©ponse';

  @override
  String get validation_invalid_permissions =>
      'Champ de bits de permissions par dÃƒÂ©faut invalide. Utilisez un entier positif ou laissez vide.';

  @override
  String get validation_legacy_chat_input_only =>
      'Le mode legacy est disponible uniquement pour les commandes de saisie.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Le mode legacy-only ne peut ÃƒÂªtre utilisÃƒÂ© que pour les nouvelles commandes ou les commandes locales existantes.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Les commandes legacy-only nÃƒÂ©cessitent que le mode legacy soit activÃƒÂ©.';

  @override
  String get validation_modal_not_legacy =>
      'Les rÃƒÂ©ponses modales ne sont pas supportÃƒÂ©es en mode commande legacy.';

  @override
  String get validation_option_description_required =>
      'La description de l\'option est requise.';

  @override
  String get validation_option_group_only_subcommands =>
      'Les groupes de sous-commandes ne peuvent contenir que des sous-commandes.';

  @override
  String get validation_option_group_top_level_only =>
      'Les groupes de sous-commandes ne peuvent ÃƒÂªtre qu\'au premier niveau.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'Les sous-commandes et groupes ne peuvent pas avoir de choix.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'Les sous-commandes et groupes ne peuvent pas avoir de valeurs min/max.';

  @override
  String get validation_option_hierarchy_not_required =>
      'Les sous-commandes et groupes ne peuvent pas ÃƒÂªtre marquÃƒÂ©s comme requis.';

  @override
  String get validation_option_leaf_no_nested =>
      'Les options feuilles ne peuvent pas avoir d\'options imbriquÃƒÂ©es.';

  @override
  String get validation_option_max_entries =>
      'Chaque niveau d\'option prend en charge au maximum 25 entrÃƒÂ©es.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Le nom de l\'option $name est dÃƒÂ©jÃƒÂ  utilisÃƒÂ© ÃƒÂ  ce niveau.';
  }

  @override
  String get validation_option_name_required =>
      'Le nom de l\'option est requis.';

  @override
  String get validation_option_no_mix_top_level =>
      'Les options de premier niveau ne peuvent pas mÃƒÂ©langer sous-commandes/groupes et options feuilles (chaÃƒÂ®ne, nombre, etc.).';

  @override
  String get validation_option_subcommand_depth =>
      'Les sous-commandes ne peuvent pas ÃƒÂªtre imbriquÃƒÂ©es ÃƒÂ  plus de 2 niveaux de profondeur.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Les sous-commandes ne peuvent pas contenir d\'autres sous-commandes ou groupes.';

  @override
  String get variable_autocomplete_numeric_title =>
      'Suggestions numÃƒÂ©riques dynamiques';

  @override
  String get variable_autocomplete_title =>
      'Variables disponibles Ã¢â‚¬â€ appuyez pour insÃƒÂ©rer';

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
  String get webhooks_copied => 'URL complÃƒÂ¨te du webhook copiÃƒÂ©e.';

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
    return 'Supprimer Ã‚Â« $label Ã‚Â» ? Cette action est irrÃƒÂ©versible.';
  }

  @override
  String get webhooks_delete_confirm_no_label =>
      'Cette action est irrÃƒÂ©versible.';

  @override
  String get webhooks_delete_title => 'Supprimer le webhook entrant ?';

  @override
  String get webhooks_edit_title => 'Modifier le webhook entrant';

  @override
  String get webhooks_empty => 'Aucun webhook entrant.';

  @override
  String get webhooks_generate => 'GÃƒÂ©nÃƒÂ©rer';

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
      'CrÃƒÂ©ez au moins un workflow avant d\'ajouter un webhook entrant.';

  @override
  String get webhooks_page_title => 'Webhooks entrants';

  @override
  String get webhooks_path_copied => 'Chemin copiÃƒÂ©.';

  @override
  String get webhooks_path_exists =>
      'Ce chemin existe dÃƒÂ©jÃƒÂ . Choisissez-en un autre.';

  @override
  String get webhooks_path_hint => 'orders/new';

  @override
  String get webhooks_path_label => 'Chemin';

  @override
  String get webhooks_runner_url_required =>
      'Configurez d\'abord une URL Runner pour copier l\'URL complÃƒÂ¨te du webhook.';

  @override
  String webhooks_save_failed(String error) {
    return 'Ãƒâ€°chec de l\'enregistrement du webhook entrant : $error';
  }

  @override
  String get webhooks_secret_copied => 'Secret copiÃƒÂ©.';

  @override
  String get webhooks_secret_label => 'Secret du webhook';

  @override
  String get webhooks_target_label => 'Workflow cible';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Workflow : $workflow';
  }

  @override
  String get wizard_advanced_trigger =>
      'ParamÃƒÂ¨tres de dÃƒÂ©clenchement avancÃƒÂ©s';

  @override
  String get wizard_apply_quick_start =>
      'Appliquer le dÃƒÂ©marrage rapide au brouillon';

  @override
  String get wizard_bdfd_mode_enabled => 'Mode script BDFD activÃƒÂ©';

  @override
  String get wizard_code_advanced => 'Code / AvancÃƒÂ©';

  @override
  String get wizard_command_body => 'Corps de la commande';

  @override
  String get wizard_create_command => 'CrÃƒÂ©er la commande';

  @override
  String get wizard_dart_mode_enabled => 'Mode script Dart activÃƒÂ©';

  @override
  String get wizard_edit_reply => 'Modifier les dÃƒÂ©tails de la rÃƒÂ©ponse';

  @override
  String get wizard_legacy_options_subtitle =>
      'Options de commande legacy et comportement local uniquement';

  @override
  String get wizard_quick_start_applied =>
      'DÃƒÂ©marrage rapide appliquÃƒÂ© au brouillon de commande.';

  @override
  String get wizard_quick_start_subtitle =>
      'Utilisez le constructeur simple legacy comme point de dÃƒÂ©part, puis appliquez-le au brouillon partagÃƒÂ©.';

  @override
  String get wizard_quick_starts => 'DÃƒÂ©marrages rapides';

  @override
  String get wizard_reply_summary => 'RÃƒÂ©sumÃƒÂ© de la rÃƒÂ©ponse';

  @override
  String get wizard_save_command => 'Enregistrer la commande';

  @override
  String get wizard_step_actions => 'Actions';

  @override
  String get wizard_step_infos => 'Infos';

  @override
  String get wizard_step_reply => 'RÃƒÂ©ponse';

  @override
  String get wizard_step_review => 'VÃƒÂ©rification';

  @override
  String get wizard_step_trigger_inputs => 'DÃƒÂ©clencheur et entrÃƒÂ©es';

  @override
  String get wizard_visual_mode_enabled => 'Mode workflow visuel activÃƒÂ©';

  @override
  String get workflow_argument_hint =>
      'Argument du workflow (accessible via \$arg)';

  @override
  String get workflow_arguments_section => 'Arguments du workflow';

  @override
  String get workflow_auto_defer => 'DiffÃƒÂ©rÃƒÂ© auto';

  @override
  String get workflow_auto_defer_actions => 'DiffÃƒÂ©rÃƒÂ© auto si actions';

  @override
  String get workflow_bdfd_editor_desc =>
      'Ãƒâ€°crivez le code BDFD complet pour cette rÃƒÂ©ponse workflow. Les diagnostics s\'affichent en direct.';

  @override
  String get workflow_bdfd_editor_title => 'Ãƒâ€°diteur de script BDFD';

  @override
  String get workflow_condition_off => 'Condition dÃƒÂ©sactivÃƒÂ©e';

  @override
  String get workflow_condition_off_upper => 'Condition DÃƒâ€°SACTIVÃƒâ€°E';

  @override
  String get workflow_condition_on => 'Condition activÃƒÂ©e';

  @override
  String get workflow_condition_on_upper => 'Condition ACTIVÃƒâ€°E';

  @override
  String get workflow_dart_editor_desc =>
      'Ãƒâ€°crivez le code Dart complet pour cette rÃƒÂ©ponse workflow. Les diagnostics s\'affichent en direct.';

  @override
  String get workflow_dart_editor_title => 'Ãƒâ€°diteur de script Dart';

  @override
  String workflow_edit_call_args(int count) {
    return 'Modifier les arguments d\'appel ($count)';
  }

  @override
  String get workflow_entry_point => 'Point d\'entrÃƒÂ©e';

  @override
  String get workflow_entry_point_helper =>
      'Par dÃƒÂ©faut, le point d\'entrÃƒÂ©e du workflow est utilisÃƒÂ©';

  @override
  String get workflow_entry_point_optional => 'Point d\'entrÃƒÂ©e (optionnel)';

  @override
  String get workflow_hint_name => 'ex. handle_form_submit';

  @override
  String get workflow_manual => 'Manuel';

  @override
  String get workflow_mode_bdfd => 'Script BDFD';

  @override
  String get workflow_mode_bdfd_note =>
      'Ãƒâ€°crivez l\'intÃƒÂ©gralitÃƒÂ© de votre workflow sous forme de script BDFD. Le script est compilÃƒÂ© et validÃƒÂ© en temps rÃƒÂ©el.';

  @override
  String get workflow_mode_dart => 'Dart Direct';

  @override
  String get workflow_mode_dart_note =>
      'Ãƒâ€°crivez votre workflow en Dart. Les diagnostics sont mis ÃƒÂ  jour pendant l\'ÃƒÂ©dition pour dÃƒÂ©tecter rapidement les erreurs.';

  @override
  String get workflow_mode_desc =>
      'Choisissez entre un ÃƒÂ©diteur visuel d\'actions ou un ÃƒÂ©diteur de script BDFD complet.';

  @override
  String get workflow_mode_title => 'Mode du workflow';

  @override
  String get workflow_mode_visual => 'Visuel';

  @override
  String get workflow_mode_visual_note =>
      'Construisez votre workflow visuellement en ajoutant des actions individuelles avec l\'ÃƒÂ©diteur de cartes.';

  @override
  String get workflow_no_auto_defer => 'Pas de diffÃƒÂ©rÃƒÂ© auto';

  @override
  String get workflow_no_workflow_note =>
      'Note : Si aucun workflow n\'est sÃƒÂ©lectionnÃƒÂ©, la soumission de ce modal ne fera rien.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'Ãƒâ‚¬ la soumission, le workflow \"$name\" sera exÃƒÂ©cutÃƒÂ© (entrÃƒÂ©e : $entry, args : $args).';
  }

  @override
  String get workflow_root_json_error => 'La racine doit ÃƒÂªtre un objet JSON';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" enregistrÃƒÂ© ($count action(s)).';
  }

  @override
  String get workflow_set_call_args => 'DÃƒÂ©finir les arguments d\'appel';

  @override
  String get workflow_visibility_ephemeral => 'Ãƒâ€°phÃƒÂ©mÃƒÂ¨re';

  @override
  String get workflow_visibility_public => 'Public';

  @override
  String get workflows_add_arg => 'Ajouter un argument';

  @override
  String get workflows_arg_default => 'Valeur par dÃƒÂ©faut';

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
  String get workflows_copy_done_base64 => 'Workflows copiÃƒÂ©s en Base64.';

  @override
  String get workflows_copy_done_json => 'Workflows copiÃƒÂ©s en JSON.';

  @override
  String get workflows_copy_none => 'Aucun workflow ÃƒÂ  copier.';

  @override
  String get workflows_create => 'CrÃƒÂ©er un workflow';

  @override
  String workflows_delete_confirm(String name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ? Cette action est irrÃƒÂ©versible.';
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
  String get workflows_entry_point => 'Point d\'entrÃƒÂ©e par dÃƒÂ©faut';

  @override
  String get workflows_entry_point_hint =>
      'UtilisÃƒÂ© si l\'appelant ne le remplace pas';

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
  String get workflows_event_channel_update => 'Mise ÃƒÂ  jour du salon';

  @override
  String get workflows_event_channel_update_desc =>
      'Declenche quand un salon est mis a jour.';

  @override
  String get workflows_event_hint =>
      'Choisissez l\'event Discord qui doit declencher ce workflow.';

  @override
  String get workflows_event_invite_create => 'CrÃƒÂ©ation d\'invitation';

  @override
  String get workflows_event_invite_create_desc =>
      'Declenche quand une invitation est creee.';

  @override
  String get workflows_event_member_join => 'ArrivÃƒÂ©e d\'un membre';

  @override
  String get workflows_event_member_join_desc =>
      'Declenche quand un membre rejoint le serveur.';

  @override
  String get workflows_event_member_remove => 'DÃƒÂ©part d\'un membre';

  @override
  String get workflows_event_member_remove_desc =>
      'Declenche quand un membre quitte le serveur ou en est retire.';

  @override
  String get workflows_event_message_create => 'CrÃƒÂ©ation de message';

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
    return '$count action(s) Ã¢â€šÂ¬Ã‚Â¢ Listen for : $event';
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
      'Colle un payload JSON ou Base64 (JSON) exportÃƒÂ© depuis Bot Creator.';

  @override
  String workflows_import_done(int count) {
    return '$count workflow(s) importÃƒÂ©(s).';
  }

  @override
  String get workflows_import_empty => 'Aucune donnÃƒÂ©e ÃƒÂ  importer.';

  @override
  String get workflows_import_input_hint => 'Colle ici le JSON ou le Base64...';

  @override
  String get workflows_import_invalid_format =>
      'Format invalide. Utilise JSON ou Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'Aucun workflow valide trouvÃƒÂ©.';

  @override
  String get workflows_import_overwrite => 'Remplacer si le nom existe';

  @override
  String get workflows_import_title => 'Importer des workflows';

  @override
  String get workflows_import_tooltip => 'Importer des workflows';

  @override
  String get workflows_listen_for => 'Ãƒâ€°couter';

  @override
  String get workflows_move_to_folder => 'DÃƒÂ©placer dans un dossier';

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
    return '$count action(s) Ã¢â€šÂ¬Ã‚Â¢ entrÃƒÂ©e : $entry Ã¢â€šÂ¬Ã‚Â¢ args : $args';
  }

  @override
  String get workflows_tab => 'Workflows';

  @override
  String get workflows_tab_short => 'Flux';

  @override
  String get workflows_title => 'Workflows';

  @override
  String get workflows_type_badge_event => 'Ãƒâ€°vÃƒÂ©nement';

  @override
  String get workflows_type_badge_general => 'GÃƒÂ©nÃƒÂ©ral';

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
      'Supprime toutes les commandes slash de Discord qui ne sont pas dÃƒÂ©finies localement dans Bot Creator.';

  @override
  String get settings_sync_force_button => 'Synchroniser avec Discord';

  @override
  String get settings_sync_force_dialog_title => 'Forcer la synchronisation';

  @override
  String get settings_sync_force_dialog_desc =>
      'Cela supprimera toutes les commandes slash sur Discord qui ne sont pas dÃƒÂ©finies localement dans Bot Creator. ÃƒÅ tes-vous sÃƒÂ»r de vouloir continuer ?';

  @override
  String get settings_sync_force_dialog_confirm => 'Forcer la synchro';

  @override
  String settings_sync_force_success(Object count) {
    return 'Synchronisation forcÃƒÂ©e rÃƒÂ©ussie. $count commande(s) obsolÃƒÂ¨te(s)/non suivies supprimÃƒÂ©e(s) de Discord.';
  }

  @override
  String settings_sync_force_error(Object error) {
    return 'Ãƒâ€°chec de la synchronisation forcÃƒÂ©e : $error';
  }

  @override
  String get app_create_select_type_title => 'Choisir le type d\'application';

  @override
  String get app_create_select_type_desc =>
      'SÃƒÂ©lectionnez le type d\'application que vous souhaitez crÃƒÂ©er pour commencer.';

  @override
  String get app_create_type_discord => 'Bot Discord';

  @override
  String get app_create_type_discord_desc =>
      'CrÃƒÂ©ez et configurez un bot Discord personnalisÃƒÂ© avec des actions, des ÃƒÂ©vÃƒÂ©nements et des calques de canvas.';

  @override
  String get app_create_type_hosted => 'Application HÃƒÂ©bergÃƒÂ©e (Docker)';

  @override
  String get app_create_type_hosted_desc =>
      'ExÃƒÂ©cutez une application, un serveur ou un script dans le langage de votre choix (NodeJS, Python, Java...). Envoyez vos fichiers et installez des paquets dans un conteneur sÃƒÂ©curisÃƒÂ©.';

  @override
  String get app_create_coming_soon => 'BientÃƒÂ´t disponible';

  @override
  String get app_create_sample_title => 'CrÃƒÂ©er une commande exemple';

  @override
  String app_create_sample_desc(String botName) {
    return 'Ajouter une commande /ping prÃƒÂªte ÃƒÂ  l\'emploi pour dÃƒÂ©marrer rapidement. Elle rÃƒÂ©pond \'Pong!\' et vous pouvez la modifier aprÃƒÂ¨s l\'avoir crÃƒÂ©ÃƒÂ©e.';
  }

  @override
  String get app_create_sample_skip => 'Passer';

  @override
  String get app_create_sample_confirm => 'Ajouter /ping';

  @override
  String get app_create_sample_success =>
      'Commande /ping crÃƒÂ©ÃƒÂ©e avec succÃƒÂ¨s !';

  @override
  String get commands_empty_title => 'CrÃƒÂ©e ta premiÃƒÂ¨re commande !';

  @override
  String get commands_empty_description =>
      'Une commande permet ÃƒÂ  ton bot de rÃƒÂ©pondre quand quelqu\'un tape /quelquechose sur Discord.';

  @override
  String get commands_empty_create_button => 'CrÃƒÂ©er une commande';

  @override
  String get commands_empty_marketplace_link =>
      'Ou pars d\'un template du Marketplace';

  @override
  String get command_created_success_title => 'Ta commande est prÃƒÂªte !';

  @override
  String get command_created_success_subtitle => 'Que veux-tu faire ensuite ?';

  @override
  String get command_created_start_bot => 'DÃƒÂ©marrer mon bot';

  @override
  String get command_created_start_bot_hint =>
      'Ouvre l\'onglet Accueil de ton bot et appuie sur DÃƒÂ©marrer pour le mettre en ligne.';

  @override
  String get command_created_invite => 'Inviter sur un serveur';

  @override
  String get command_created_invite_error =>
      'Impossible d\'ouvrir le lien d\'invitation.';

  @override
  String get command_created_create_another => 'CrÃƒÂ©er une autre commande';

  @override
  String get command_created_close => 'Fermer';

  @override
  String get beginner_mode_label => 'Mode dÃƒÂ©butant';

  @override
  String get beginner_mode_on_hint =>
      'Affichage des onglets essentiels uniquement';

  @override
  String get beginner_mode_off_hint =>
      'Affichage de toutes les fonctionnalitÃƒÂ©s';

  @override
  String get commands_empty_sample_ping =>
      'Ajouter une commande /ping d\'exemple';

  @override
  String get command_created_sample_success =>
      'Commande /ping crÃƒÂ©ÃƒÂ©e ! Elle rÃƒÂ©pond Ã‚Â« Pong ! Ã‚Â»';

  @override
  String get onboarding_create_now => 'CrÃƒÂ©er mon bot maintenant';

  @override
  String get onboarding_command_now => 'CrÃƒÂ©er ta premiÃƒÂ¨re commande';

  @override
  String get container_list_title => 'Applications HÃ©bergÃ©es';

  @override
  String get container_list_session_missing => 'Session indisponible';

  @override
  String get container_list_session_hint =>
      'Veuillez d\'abord vous connecter Ã  votre compte.';

  @override
  String get container_list_error => 'Ã‰chec du chargement des conteneurs';

  @override
  String get container_list_retry => 'RÃ©essayer';

  @override
  String get container_list_empty => 'Aucune application hÃ©bergÃ©e';

  @override
  String get container_list_empty_hint =>
      'DÃ©ployez votre premiÃ¨re application pour commencer.';

  @override
  String get container_list_deploy_btn => 'DÃ©ployer une Application';

  @override
  String get container_list_expired => 'ExpirÃ©';

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
  String get container_deploy_title => 'DÃ©ployer une Application';

  @override
  String get container_deploy_image_label => 'Image';

  @override
  String get container_deploy_image_hint => 'Nom de l\'image Docker avec tag';

  @override
  String get container_deploy_image_required => 'L\'image est requise';

  @override
  String get container_deploy_cpu_label => 'CPU (millis)';

  @override
  String get container_deploy_cpu_min => 'Min 128';

  @override
  String get container_deploy_memory_label => 'MÃ©moire (Mo)';

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
  String get container_deploy_env_key_hint => 'CLÃ‰';

  @override
  String get container_deploy_env_value_hint => 'valeur';

  @override
  String get container_deploy_submit => 'DÃ©ployer';

  @override
  String get container_deploy_submitting => 'DÃ©ploiement en cours...';

  @override
  String get container_deploy_not_auth => 'Non authentifiÃ©';

  @override
  String container_deploy_success(String containerId) {
    return 'DÃ©ploiement de $containerId en cours...';
  }

  @override
  String container_deploy_failed(String error) {
    return 'Ã‰chec du dÃ©ploiement : $error';
  }

  @override
  String get container_detail_state => 'Ã‰tat';

  @override
  String get container_detail_expires => 'Expire le';

  @override
  String get container_detail_extend_ttl => 'Prolonger la TTL';

  @override
  String get container_detail_stop_title => 'ArrÃªter le Conteneur';

  @override
  String get container_detail_stop_confirm =>
      'Cela va terminer le conteneur et ses donnÃ©es seront perdues.';

  @override
  String get container_detail_stop_btn => 'ArrÃªter';

  @override
  String get container_detail_stopped_ok => 'Conteneur arrÃªtÃ©';

  @override
  String get container_detail_update_resources =>
      'Mettre Ã  jour les Ressources';

  @override
  String get container_detail_update_btn => 'Mettre Ã  jour';

  @override
  String get container_detail_updated_ok => 'Ressources mises Ã  jour';

  @override
  String get container_detail_extend_hint => 'Minutes Ã  ajouter';

  @override
  String get container_detail_extend_btn => 'Prolonger';

  @override
  String get container_detail_extended_ok => 'TTL prolongÃ©e';

  @override
  String get container_detail_console => 'Console';

  @override
  String get container_detail_deploying =>
      'Le conteneur est en cours de dÃ©ploiement...';

  @override
  String container_detail_status_stopped(String state) {
    return 'Ce conteneur est $state.';
  }

  @override
  String get container_detail_not_connected => 'Non connectÃ©';

  @override
  String get container_detail_console_connecting => 'Connexion en cours...';

  @override
  String get container_detail_console_closed => '--- Connexion fermÃ©e ---';

  @override
  String get container_detail_console_hint => 'Tapez une commande...';

  @override
  String container_detail_failed(String error) {
    return 'Ã‰chec : $error';
  }

  @override
  String get container_state_running => 'En cours';

  @override
  String get container_state_pending => 'En attente';

  @override
  String get container_state_stopped => 'ArrÃªtÃ©';

  @override
  String get container_state_stopping => 'ArrÃªt en cours';

  @override
  String get container_state_failed => 'Ã‰chouÃ©';

  @override
  String get container_hosted_subtitle =>
      'DÃ©ployez et gÃ©rez des conteneurs Docker';

  @override
  String get container_premium_badge => 'Premium';

  @override
  String container_detail_title(String id) {
    return 'Conteneur $id';
  }
}
