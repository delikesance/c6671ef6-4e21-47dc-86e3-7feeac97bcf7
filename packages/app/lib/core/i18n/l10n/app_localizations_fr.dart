// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get app_title => 'Bot Creator';

  @override
  String get onboarding_welcome_title => 'Bienvenue dans Bot Creator';

  @override
  String get onboarding_welcome_desc =>
      'Créez votre premier bot Discord en 3 étapes simples. Nous vous guidons à travers chaque étape.';

  @override
  String get onboarding_welcome_start => 'Commencer';

  @override
  String get onboarding_welcome_skip => 'Passer';

  @override
  String get onboarding_create_title => 'Étape 1: Créer un bot';

  @override
  String get onboarding_create_desc => 'Obtenez votre token Discord';

  @override
  String get onboarding_create_steps =>
      '1. Allez sur Discord Developer Portal\n2. Créez une nouvelle app\n3. Copiez le token du bot\n4. Collez-le ci-dessous';

  @override
  String get onboarding_create_tip =>
      '💡 Conseil: Ne partagez jamais votre token! Il donne accès complet à votre bot.';

  @override
  String get onboarding_create_tutorial => 'Tutoriel: Comment obtenir un token';

  @override
  String get onboarding_create_button => 'Continuer';

  @override
  String get onboarding_command_title => 'Étape 2: Ajouter une commande';

  @override
  String get onboarding_command_desc => 'Créez votre première commande';

  @override
  String get onboarding_command_text =>
      'Les commandes sont le cœur de votre bot. Elles permettent aux utilisateurs d\'interagir avec votre bot via Discord.';

  @override
  String get onboarding_command_example =>
      'Exemple:\n/hello → Le bot répond \"Bonjour! 👋\"';

  @override
  String get onboarding_command_button => 'Continuer';

  @override
  String get onboarding_start_title => 'Étape 3: Lancer le bot';

  @override
  String get onboarding_start_desc => 'Lancez votre bot!';

  @override
  String get onboarding_start_text =>
      'Appuyez sur le bouton \"Démarrer\" sur la carte de votre bot. Testez ensuite votre commande dans Discord!';

  @override
  String get onboarding_start_tip =>
      '✨ Bravo! Vous avez créé votre premier bot Discord. Vous pouvez maintenant ajouter plus de commandes et le personnaliser!';

  @override
  String get onboarding_start_button => 'Continuer';

  @override
  String get onboarding_success_title => 'Bravo! 🎉';

  @override
  String get onboarding_success_desc =>
      'Votre bot Discord est maintenant prêt à l\'emploi!';

  @override
  String get onboarding_success_whatsnext => 'Que faire maintenant?';

  @override
  String get onboarding_success_tip1 => 'Ajouter plus de commandes';

  @override
  String get onboarding_success_tip2 => 'Créer des workflows';

  @override
  String get onboarding_success_tip3 => 'Sauvegarder vos données';

  @override
  String get onboarding_success_button => 'Commencer!';

  @override
  String get app_create_new => 'Créer une nouvelle application';

  @override
  String get app_create_page_title => 'Créer un bot';

  @override
  String get app_create_hero_title => 'Connectez votre bot Discord';

  @override
  String get app_create_hero_desc =>
      'Un parcours guidé pour ouvrir les bonnes pages, copier votre token et importer le bot proprement.';

  @override
  String get app_resources_title => 'Parcours guidé';

  @override
  String get app_resources_desc =>
      'Ces actions ouvrent les pages officielles nécessaires avant d’enregistrer votre bot ici.';

  @override
  String get app_open_discord_portal => 'Ouvrir Discord Developer Portal';

  @override
  String get app_open_discord_portal_desc =>
      'Créez votre application et activez la section bot.';

  @override
  String get app_open_token_tutorial => 'Lire le tutoriel du token';

  @override
  String get app_open_token_tutorial_desc =>
      'Un guide pas à pas pour générer et copier votre token de bot.';

  @override
  String get app_external_link_badge => 'Lien externe';

  @override
  String get app_token_section_title => 'Collez votre token de bot';

  @override
  String get app_token_section_desc =>
      'Une fois le token copié, collez-le ci-dessous pour ajouter votre bot à l’application.';

  @override
  String get app_token_field_helper =>
      'Collez le token exactement tel que fourni par Discord.';

  @override
  String get app_token_security_hint =>
      'Gardez ce token privé. Toute personne qui le possède peut contrôler votre bot.';

  @override
  String get app_show_token => 'Afficher le token';

  @override
  String get app_hide_token => 'Masquer le token';

  @override
  String get app_save_bot => 'Ajouter le bot';

  @override
  String get app_open_link_error => 'Impossible d’ouvrir cette page externe.';

  @override
  String get app_how_to_create_token => 'Comment créer un token de bot ?';

  @override
  String get app_bot_token => 'Token du bot';

  @override
  String get app_enter_token => 'Entrez votre token du bot ici';

  @override
  String get app_note =>
      'Remarque: Vous devez créer une nouvelle application sur Discord Developer Portal et obtenir le token du bot.';

  @override
  String get app_save => 'Enregistrer les modifications';

  @override
  String get app_sync_manager_title => 'Bot déjà géré';

  @override
  String get app_sync_manager_desc =>
      'Ce bot est déjà enregistré sur Bot Creator Manager. Connectez-vous avec Discord pour synchroniser tous vos bots automatiquement ?';

  @override
  String get app_sync_manager_manual => 'Garder local';

  @override
  String get app_sync_manager_connect => 'Connecter Discord';

  @override
  String get app_no_apps => 'Aucune application trouvée';

  @override
  String get app_loading_error => 'Erreur de chargement';

  @override
  String get app_create_button => 'Créer un bot';

  @override
  String get home_tab => 'Accueil';

  @override
  String get commands_tab => 'Commandes';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get globals_tab => 'Globales';

  @override
  String get globals_tab_short => 'Vars';

  @override
  String get workflows_tab => 'Workflows';

  @override
  String get workflows_tab_short => 'Flow';

  @override
  String get scheduler_tab => 'Scheduler';

  @override
  String get scheduler_tab_short => 'Sched';

  @override
  String get emojis_tab => 'Emojis';

  @override
  String get emojis_tab_short => 'Emoji';

  @override
  String get emojis_title => 'Emojis applicatifs';

  @override
  String get emojis_empty =>
      'Aucun emoji pour l\'instant. Uploadez-en un pour commencer.';

  @override
  String get emojis_upload => 'Uploader un emoji';

  @override
  String get emojis_upload_name_hint =>
      'Nom de l\'emoji (lettres, chiffres, _)';

  @override
  String get emojis_upload_pick_image => 'Choisir une image';

  @override
  String get emojis_delete_confirm_title => 'Supprimer l\'emoji';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Supprimer :$name: ? Cette action est irréversible.';
  }

  @override
  String download_completed(String id) {
    return 'Download completed: $id';
  }

  @override
  String download_failed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get download_legacy_backup => 'Download completed (legacy backup)';

  @override
  String get restore_completed => 'Restore completed';

  @override
  String get restore_runtime_db_recommended =>
      'Restore completed (SQLite runtime restored, restart recommended)';

  @override
  String get emojis_rename_title => 'Renommer l\'emoji';

  @override
  String get emojis_rename_hint => 'Nouveau nom';

  @override
  String get emojis_loading_error => 'Échec du chargement des emojis';

  @override
  String emojis_upload_error(String error) {
    return 'Échec de l\'upload : $error';
  }

  @override
  String emojis_delete_error(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String emojis_rename_error(String error) {
    return 'Échec du renommage : $error';
  }

  @override
  String get settings_tab => 'Paramètres';

  @override
  String get more_tab => 'Plus';

  @override
  String get quick_access_title => 'Accès rapide';

  @override
  String get more_options_title => 'Plus d\'options';

  @override
  String get no_more_options => 'Aucune autre option disponible';

  @override
  String get settings_theme_switch_light => 'Passer en mode clair';

  @override
  String get settings_theme_switch_dark => 'Passer en mode sombre';

  @override
  String get settings_appearance_title => 'Apparence et langue';

  @override
  String get settings_language_title => 'Langue';

  @override
  String get settings_language_desc =>
      'Choisissez la langue utilisée par l’application.';

  @override
  String get settings_language_system => 'Automatique (appareil)';

  @override
  String get settings_language_updated => 'Langue mise à jour';

  @override
  String get settings_debug_title => 'Outils de debug';

  @override
  String get settings_debug_desc =>
      'Réinitialise les préférences locales ou relance l’onboarding pour les tests.';

  @override
  String get settings_reset_preferences => 'Réinitialiser les préférences';

  @override
  String get settings_reset_preferences_desc =>
      'Réinitialise le thème, la langue et la progression de l’onboarding.';

  @override
  String get settings_replay_onboarding => 'Relancer l’onboarding';

  @override
  String get settings_replay_onboarding_desc =>
      'Réinitialise l’onboarding et le relance immédiatement.';

  @override
  String get settings_debug_premium_bypass => 'Bypass Premium';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Débloque toutes les fonctionnalités Premium sans abonnement (debug uniquement).';

  @override
  String get settings_preferences_reset_done => 'Préférences réinitialisées';

  @override
  String get settings_backup_restore_title => 'Sauvegarde et restauration';

  @override
  String get settings_backup_restore_desc =>
      'Gérez la synchronisation de vos données avec Google Drive';

  @override
  String get settings_snapshot_preview_title => 'Aperçu du snapshot';

  @override
  String settings_snapshot_id(String id) {
    return 'ID : $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Libellé : $label';
  }

  @override
  String settings_snapshot_created_at(String date) {
    return 'Créé le : $date';
  }

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Fichiers : $count • Taille : $size';
  }

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps : $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps dans ce snapshot';

  @override
  String get settings_snapshot_no_metadata =>
      'Aucune métadonnée d’application disponible.';

  @override
  String get settings_snapshot_delete_loading => 'Suppression du snapshot…';

  @override
  String get settings_snapshot_deleted => 'Snapshot supprimé';

  @override
  String get settings_snapshot_restore_loading => 'Restauration du snapshot…';

  @override
  String get settings_restore_snapshot => 'Restaurer ce snapshot';

  @override
  String get settings_diagnostics_dialog_title => 'Diagnostics de démarrage';

  @override
  String get settings_diagnostics_copied =>
      'Diagnostics copiés dans le presse-papiers';

  @override
  String get settings_drive_title => 'Connexion Google Drive';

  @override
  String get settings_drive_desc =>
      'Connectez votre compte Google Drive pour synchroniser vos données';

  @override
  String get settings_drive_connect_loading => 'Connexion à Google Drive…';

  @override
  String get settings_drive_connected => 'Connecté à Google Drive';

  @override
  String get settings_drive_connect => 'Connecter Google Drive';

  @override
  String get settings_drive_status_connected => 'Connecté';

  @override
  String get settings_drive_disconnect_loading => 'Déconnexion en cours…';

  @override
  String get settings_drive_disconnected => 'Déconnecté de Google Drive';

  @override
  String get settings_drive_disconnect => 'Déconnecter';

  @override
  String get settings_runner_title => 'Runner API';

  @override
  String get settings_runner_desc =>
      'Connecte l\'application à un Bot Creator Runner. Un runner distant doit rester sur un réseau de confiance et utiliser un jeton bearer.';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_token_label => 'Jeton API du runner';

  @override
  String get settings_runner_token_hint =>
      'Jeton bearer (optionnel si le runner reste en localhost)';

  @override
  String get settings_runner_save => 'Enregistrer';

  @override
  String get settings_runner_clear => 'Effacer';

  @override
  String get settings_runner_saved => 'Paramètres du runner enregistrés';

  @override
  String get settings_runner_cleared => 'Paramètres du runner effacés';

  @override
  String get settings_runner_url_save => 'Enregistrer l\'URL';

  @override
  String get settings_runner_url_clear => 'Effacer';

  @override
  String get settings_runner_url_saved => 'URL du runner enregistrée';

  @override
  String get settings_runner_url_cleared => 'URL du runner effacée';

  @override
  String get settings_runner_check => 'Tester la connexion';

  @override
  String get settings_runner_connected => 'Runner accessible ✓';

  @override
  String get settings_runner_auth_failed => 'Le runner a refusé le jeton API';

  @override
  String get settings_runner_unreachable => 'Runner inaccessible';

  @override
  String get settings_runner_connecting => 'Vérification de la connexion…';

  @override
  String settings_runner_active(String url) {
    return 'Runner API actif : $url';
  }

  @override
  String get settings_runner_disable_temp =>
      'Désactiver temporairement le Runner';

  @override
  String get settings_runner_disable_temp_desc =>
      'Conserve la configuration du Runner mais force le mode local jusqu’à réactivation.';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner temporairement désactivé (mode local actif)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner temporairement désactivé';

  @override
  String get settings_runner_reenabled => 'Runner réactivé';

  @override
  String get settings_main_api_title => 'Serveur Bot Creator';

  @override
  String get settings_main_api_desc =>
      'Connectez Bot Creator aux serveurs Bot Creator puis connectez-vous avec Discord. Le secret client Discord doit rester côté backend.';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_save => 'Enregistrer le serveur Bot Creator';

  @override
  String get settings_main_api_clear => 'Effacer';

  @override
  String get settings_main_api_saved =>
      'Paramètres du serveur Bot Creator enregistrés';

  @override
  String get settings_main_api_cleared =>
      'Paramètres du serveur Bot Creator effacés';

  @override
  String get settings_main_api_check => 'Tester le serveur Bot Creator';

  @override
  String get settings_main_api_connected => 'Serveur Bot Creator accessible ✓';

  @override
  String get settings_main_api_unreachable =>
      'Serveur Bot Creator inaccessible';

  @override
  String get settings_main_api_auth_failed =>
      'La session du serveur Bot Creator est invalide ou expirée';

  @override
  String get settings_main_api_connect_discord => 'Connecter le compte Discord';

  @override
  String get settings_main_api_disconnect => 'Déconnecter le compte';

  @override
  String get settings_main_api_desktop_only =>
      'La connexion Discord via les serveurs Bot Creator est disponible uniquement sur desktop.';

  @override
  String get settings_main_api_not_configured =>
      'URL du serveur Bot Creator requise';

  @override
  String get settings_main_api_session_connected => 'Session Discord active';

  @override
  String get settings_main_api_session_disconnected =>
      'Session Discord déconnectée';

  @override
  String get settings_main_api_session_expired => 'Session Discord expirée';

  @override
  String get settings_main_api_url_required =>
      'URL du serveur Bot Creator requise';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Connecté en tant que $user';
  }

  @override
  String get settings_main_api_user_unknown => 'Utilisateur Discord';

  @override
  String get settings_main_api_connected_discord => 'Compte Discord connecté';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_desc =>
      'Publie l’activité desktop de Bot Creator dans le client Discord local. Bot Creator utilise toujours l’application Discord intégrée et envoie SET_ACTIVITY directement via l’IPC local quand l’option est activée.';

  @override
  String get settings_discord_rpc_enable => 'Activer Discord Rich Presence';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Cet identifiant est fixé dans Bot Creator et ne peut pas être modifié depuis les paramètres.';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Client secret de l’application Discord (optionnel)';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Client secret';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Solution avancée optionnelle pour un flow confidentiel géré localement.';

  @override
  String get settings_discord_rpc_broker_label =>
      'URL du broker OAuth (avancée, optionnelle)';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_save => 'Enregistrer';

  @override
  String get settings_discord_rpc_saved =>
      'Paramètres Discord Rich Presence enregistrés';

  @override
  String get settings_discord_rpc_connect => 'Rafraîchir la présence';

  @override
  String get settings_discord_rpc_authorize => 'Autoriser';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Finaliser l’autorisation';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Code d’autorisation reçu';

  @override
  String get settings_discord_rpc_open_ipc => 'Ouvrir l’IPC local';

  @override
  String get settings_discord_rpc_ipc_open => 'IPC local déjà ouvert';

  @override
  String get settings_discord_rpc_disconnect => 'Fermer l’IPC';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Utilisateur autorisé : $user';
  }

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'Point IPC : $endpoint';
  }

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Dernière erreur : $error';
  }

  @override
  String get settings_discord_rpc_enable_first =>
      'Activez Discord Rich Presence d’abord';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Le client ID Discord est requis';

  @override
  String get settings_discord_rpc_disabled => 'Désactivé';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence est réservé au desktop';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Le transport Discord n’est pas encore pris en charge sur cette plateforme';

  @override
  String get settings_discord_rpc_not_configured => 'Client ID requis';

  @override
  String get settings_discord_rpc_broker_required =>
      'Le Client ID suffit pour le flow public client ; l’URL du broker et le client secret restent optionnels';

  @override
  String get settings_discord_rpc_disconnected => 'IPC fermé';

  @override
  String get settings_discord_rpc_needs_authorization => 'Autorisation requise';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Code d’autorisation en cache ; relancez pour terminer l’échange du token';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'IPC Discord local connecté ; aucune requête OAuth HTTP envoyée pour l’instant, authentification encore requise';

  @override
  String get settings_discord_rpc_connecting => 'Connexion à Discord…';

  @override
  String get settings_discord_rpc_authorizing =>
      'En attente de l’autorisation Discord…';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'Finalisation de l’échange OAuth…';

  @override
  String get settings_discord_rpc_authenticating =>
      'Authentification auprès de Discord…';

  @override
  String get settings_discord_rpc_connected => 'Présence envoyée à Discord';

  @override
  String get settings_discord_rpc_error => 'Erreur Discord RPC';

  @override
  String get settings_data_operations_title => 'Opérations de données';

  @override
  String get settings_export => 'Exporter';

  @override
  String get settings_import => 'Importer';

  @override
  String get settings_export_app_data => 'Exporter les données de l’app';

  @override
  String get settings_import_app_data => 'Importer les données de l’app';

  @override
  String get settings_export_loading => 'Export en cours…';

  @override
  String get settings_import_loading => 'Import en cours…';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_enable_auto_backup => 'Activer l’auto-sauvegarde';

  @override
  String get settings_enable_auto_backup_desc =>
      'Crée automatiquement des snapshots versionnés lorsque nécessaire.';

  @override
  String get settings_auto_backup_interval => 'Intervalle d’auto-sauvegarde';

  @override
  String get settings_auto_backup_every_6h => 'Toutes les 6 h';

  @override
  String get settings_auto_backup_every_12h => 'Toutes les 12 h';

  @override
  String get settings_auto_backup_every_24h => 'Toutes les 24 h';

  @override
  String get settings_auto_backup_every_72h => 'Toutes les 72 h';

  @override
  String get settings_last_auto_backup_never =>
      'Dernière auto-sauvegarde : jamais';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Dernière auto-sauvegarde : $date';
  }

  @override
  String get settings_snapshot_create_loading => 'Création du snapshot…';

  @override
  String get settings_manual_snapshot_label => 'Snapshot manuel';

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot créé : $id';
  }

  @override
  String get settings_backup_now => 'Sauvegarder maintenant';

  @override
  String get settings_run_auto_backup_now => 'Lancer l’auto-sauvegarde';

  @override
  String get settings_auto_backup_check_loading =>
      'Vérification auto-sauvegarde…';

  @override
  String get settings_snapshots_title => 'Snapshots';

  @override
  String get settings_snapshots_refresh => 'Actualiser les snapshots';

  @override
  String get settings_snapshots_delete_all => 'Supprimer tous les snapshots';

  @override
  String get settings_snapshots_delete_all_title =>
      'Supprimer tous les snapshots';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Supprimer définitivement $count snapshot(s) ? Cette action est irréversible.';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'Suppression de tous les snapshots…';

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count snapshot(s) supprimé(s).';
  }

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Supprimer un snapshot sélectionné';

  @override
  String get settings_snapshots_delete_select_title => 'Supprimer un snapshot';

  @override
  String get settings_snapshots_delete_select_desc =>
      'Choisissez le snapshot à supprimer (du plus ancien au plus récent).';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Supprimer définitivement \"$label\" ? Cette action est irréversible.';
  }

  @override
  String get settings_snapshots_refresh_loading =>
      'Actualisation des snapshots…';

  @override
  String get settings_snapshots_empty =>
      'Aucun snapshot trouvé pour le moment.';

  @override
  String backup_completed(String id) {
    return 'Sauvegarde terminée : $id';
  }

  @override
  String backup_failed(String error) {
    return 'Sauvegarde terminée : $error';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date • $count fichiers • $size';
  }

  @override
  String get settings_diagnostics_section_title => 'Diagnostics';

  @override
  String get settings_diagnostics_page_title => 'Logs de l’application';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Affiche uniquement les logs de diagnostic de l’application (hors logs bot).';

  @override
  String get settings_diagnostics_refresh => 'Actualiser les logs';

  @override
  String get settings_diagnostics_copy_all => 'Copier tous les logs';

  @override
  String get settings_diagnostics_empty =>
      'Aucun log d’application disponible pour le moment.';

  @override
  String get settings_view_startup_logs => 'Voir les logs de démarrage';

  @override
  String get settings_clear_logs => 'Effacer les logs';

  @override
  String get settings_logs_cleared => 'Logs de diagnostic effacés';

  @override
  String get settings_legal_title => 'Légal';

  @override
  String get settings_legal_desc =>
      'Consultez la manière dont vos données sont traitées et stockées.';

  @override
  String get settings_privacy_policy => 'Politique de confidentialité';

  @override
  String get settings_compatibility_title => 'Aperçu compatibilité BDFD';

  @override
  String get settings_compatibility_desc =>
      'Vue rapide de la couverture fonctionnelle pour les utilisateurs venant de BDFD.';

  @override
  String get settings_compatibility_status_supported => 'Supporté';

  @override
  String get settings_compatibility_status_partial => 'Partiel';

  @override
  String get settings_compatibility_status_missing => 'Absent';

  @override
  String get settings_compatibility_item_workflows_title =>
      'Éditeur de workflows';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Les workflows visuels de commandes et de réponses sont disponibles.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Variables runtime et templates';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Les variables dynamiques et helpers de template sont pris en charge.';

  @override
  String get settings_compatibility_item_events_title =>
      'Couverture des événements';

  @override
  String get settings_compatibility_item_events_desc =>
      'Les événements courants sont couverts, certains restent limités en runtime.';

  @override
  String get settings_compatibility_item_runner_title => 'Architecture runner';

  @override
  String get settings_compatibility_item_runner_desc =>
      'Le runner distant est disponible, le multi-runner est en cours.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'Parité des fonctions BDScript';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Couverture complète du catalogue de fonctions BDFD.';

  @override
  String get settings_compatibility_note =>
      'Cet aperçu reste volontairement synthétique et évoluera par release.';

  @override
  String get settings_compatibility_open_functions =>
      'Voir les fonctions compatibles';

  @override
  String get settings_compatibility_functions_title =>
      'Fonctions BDFD compatibles';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Fonctions actuellement implémentées et utilisables dans le mode BDFD de Bot Creator.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Vue diff entre l\'implémentation Bot Creator et la référence des fonctions BDFD.';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'Fonctions compatibles : $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Supportées sur Bot Creator : $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'Total référence BDFD : $count';
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
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Exclusives Bot Creator : $count';
  }

  @override
  String get settings_compatibility_functions_note =>
      'Cette page reflète l’implémentation actuelle et évoluera au fil des mises à jour.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'Les entrées BDFD uniquement correspondent aux fonctions de la liste BDFD fournie qui ne sont pas encore implémentées dans Bot Creator.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Rechercher une fonction (exemple : \$userJoined)';

  @override
  String get settings_compatibility_functions_section_both =>
      'Supportées sur Bot Creator et BDFD';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Supportées uniquement sur Bot Creator';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Les helpers de boucle sont actuellement spécifiques à Bot Creator.';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Disponibles sur BDFD mais manquantes sur Bot Creator';

  @override
  String get settings_compatibility_functions_empty =>
      'Aucune fonction dans cette section.';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Gardes et permissions';

  @override
  String get settings_compatibility_functions_category_control =>
      'Contrôle de flux';

  @override
  String get settings_compatibility_functions_category_messages => 'Messages';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_components =>
      'Composants / Interactions';

  @override
  String get settings_compatibility_functions_category_logging =>
      'Journalisation';

  @override
  String get settings_compatibility_functions_category_json => 'Helpers JSON';

  @override
  String get settings_compatibility_functions_category_http => 'Helpers HTTP';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Variables scopees';

  @override
  String get settings_compatibility_functions_category_threads => 'Threads';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Placeholders runtime';

  @override
  String get settings_ads_privacy_manage =>
      'Gérer les choix de confidentialité pub';

  @override
  String get settings_ads_privacy_not_required =>
      'Options de confidentialité pub non requises pour le moment';

  @override
  String get settings_ads_privacy_loading =>
      'Vérification des paramètres de confidentialité pub...';

  @override
  String get settings_ads_privacy_opened =>
      'Options de confidentialité pub ouvertes';

  @override
  String get settings_ads_privacy_open_error =>
      'Impossible d’ouvrir les options de confidentialité pub';

  @override
  String get action_name_deleteMessages => 'Supprimer des messages';

  @override
  String get action_name_createChannel => 'Créer un salon';

  @override
  String get action_name_updateChannel => 'Modifier un salon';

  @override
  String get action_name_removeChannel => 'Supprimer un salon';

  @override
  String get action_name_sendMessage => 'Envoyer un message';

  @override
  String get action_name_editMessage => 'Modifier un message';

  @override
  String get action_name_addReaction => 'Ajouter une réaction';

  @override
  String get action_name_removeReaction => 'Retirer une réaction';

  @override
  String get action_name_clearAllReactions => 'Retirer toutes les réactions';

  @override
  String get action_name_banUser => 'Bannir un utilisateur';

  @override
  String get action_name_unbanUser => 'Débannir un utilisateur';

  @override
  String get action_name_kickUser => 'Expulser un utilisateur';

  @override
  String get action_name_muteUser => 'Rendre muet un utilisateur';

  @override
  String get action_name_unmuteUser => 'Réactiver la parole d\'un utilisateur';

  @override
  String get action_name_addRole => 'Ajouter un rôle';

  @override
  String get action_name_removeRole => 'Retirer un rôle';

  @override
  String get action_name_pinMessage => 'Épingler un message';

  @override
  String get action_name_updateAutoMod => 'Mettre à jour AutoMod';

  @override
  String get action_name_updateGuild => 'Mettre à jour le serveur';

  @override
  String get action_name_listMembers => 'Lister les membres';

  @override
  String get action_name_getMember => 'Récupérer un membre';

  @override
  String get action_name_sendComponentV2 => 'Envoyer un composant V2';

  @override
  String get action_name_editComponentV2 => 'Modifier un composant V2';

  @override
  String get action_name_sendWebhook => 'Envoyer via webhook';

  @override
  String get action_name_editWebhook => 'Modifier un webhook';

  @override
  String get action_name_deleteWebhook => 'Supprimer un webhook';

  @override
  String get action_name_listWebhooks => 'Lister les webhooks';

  @override
  String get action_name_getWebhook => 'Récupérer un webhook';

  @override
  String get action_name_httpRequest => 'Requête HTTP';

  @override
  String get action_name_setGlobalVariable => 'Définir une variable globale';

  @override
  String get action_name_getGlobalVariable => 'Lire une variable globale';

  @override
  String get action_name_removeGlobalVariable =>
      'Supprimer une variable globale';

  @override
  String get action_name_setScopedVariable => 'Définir une variable scopée';

  @override
  String get action_name_getScopedVariable => 'Lire une variable scopée';

  @override
  String get action_name_removeScopedVariable =>
      'Supprimer une variable scopée';

  @override
  String get action_name_renameScopedVariable => 'Renommer une variable scopée';

  @override
  String get action_name_listScopedVariableIndex =>
      'Lister un index de variable scopée';

  @override
  String get action_name_appendArrayElement =>
      'Ajouter un élément à un tableau';

  @override
  String get action_name_removeArrayElement => 'Retirer un élément de tableau';

  @override
  String get action_name_queryArray => 'Interroger un tableau';

  @override
  String get action_name_runWorkflow => 'Exécuter un workflow';

  @override
  String get action_name_runBdfdScript => 'Exécuter un script BDFD';

  @override
  String get action_name_respondWithMessage => 'Répondre avec un message';

  @override
  String get action_name_respondWithComponentV2 =>
      'Répondre avec un composant V2';

  @override
  String get action_name_respondWithModal => 'Répondre avec un modal';

  @override
  String get action_name_editInteractionMessage =>
      'Modifier le message d\'interaction';

  @override
  String get action_name_listenForButtonClick => 'Écouter un clic bouton';

  @override
  String get action_name_listenForSelectMenu => 'Écouter un menu de sélection';

  @override
  String get action_name_listenForModalSubmit =>
      'Écouter une soumission de modal';

  @override
  String get action_name_respondWithAutocomplete =>
      'Répondre avec un auto-complete';

  @override
  String get action_name_stopUnless => 'Arrêter sauf si condition';

  @override
  String get action_name_ifBlock => 'Bloc SI / SINON';

  @override
  String get action_name_calculate => 'Calculer';

  @override
  String get action_name_getMessage => 'Récupérer un message';

  @override
  String get action_name_unpinMessage => 'Désépingler un message';

  @override
  String get action_name_createPoll => 'Créer un sondage';

  @override
  String get action_name_endPoll => 'Clôturer un sondage';

  @override
  String get action_name_createInvite => 'Créer une invitation';

  @override
  String get action_name_deleteInvite => 'Supprimer une invitation';

  @override
  String get action_name_getInvite => 'Récupérer une invitation';

  @override
  String get action_name_moveToVoiceChannel => 'Déplacer vers un vocal';

  @override
  String get action_name_disconnectFromVoice => 'Déconnecter du vocal';

  @override
  String get action_name_serverMuteMember => 'Rendre muet côté serveur';

  @override
  String get action_name_serverDeafenMember => 'Assourdir côté serveur';

  @override
  String get action_name_createEmoji => 'Créer un emoji';

  @override
  String get action_name_updateEmoji => 'Modifier un emoji';

  @override
  String get action_name_deleteEmoji => 'Supprimer un emoji';

  @override
  String get action_name_createAutoModRule => 'Créer une règle AutoMod';

  @override
  String get action_name_deleteAutoModRule => 'Supprimer une règle AutoMod';

  @override
  String get action_name_listAutoModRules => 'Lister les règles AutoMod';

  @override
  String get action_name_getGuildOnboarding =>
      'Récupérer l\'onboarding serveur';

  @override
  String get action_name_updateGuildOnboarding =>
      'Modifier l\'onboarding serveur';

  @override
  String get action_name_updateSelfUser => 'Mettre à jour le profil du bot';

  @override
  String get action_name_createThread => 'Créer un fil';

  @override
  String get action_name_editChannelPermissions =>
      'Modifier les permissions du salon';

  @override
  String get action_name_deleteChannelPermission =>
      'Supprimer une permission du salon';

  @override
  String home_token_missing(String botName) {
    return 'Token introuvable pour $botName';
  }

  @override
  String get home_log_start_requested => 'Démarrage du bot demandé';

  @override
  String get home_log_stop_requested => 'Arrêt du bot demandé';

  @override
  String get home_notification_permission_required =>
      'La permission de notification est requise pour lancer le bot.';

  @override
  String get home_foreground_service_not_started =>
      'Le service foreground n’a pas démarré.';

  @override
  String get home_log_desktop_stop_requested => 'Arrêt du bot desktop demandé';

  @override
  String get home_unknown_app => 'Inconnu';

  @override
  String get home_status_online => 'En ligne';

  @override
  String get home_status_offline => 'Hors ligne';

  @override
  String home_server_count_one(int count) {
    return '$count serveur';
  }

  @override
  String home_server_count_other(int count) {
    return '$count serveurs';
  }

  @override
  String get home_stop => 'Arrêter';

  @override
  String get home_start => 'Lancer';

  @override
  String get home_start_ads => 'Regarder une pub pour lancer';

  @override
  String get home_start_premium => 'Lancer';

  @override
  String get home_add_time => 'Ajouter du temps';

  @override
  String home_hosting_time_left(int minutes) {
    return 'Temps d\'hébergement restant : $minutes min';
  }

  @override
  String get home_manage => 'Gérer';

  @override
  String get home_logs_tooltip => 'Logs du bot';

  @override
  String get rewarded_start_title => 'Pub requise';

  @override
  String get rewarded_start_message =>
      'Une publicité est requise pour lancer cette session d\'hébergement. Cela aide à financer le projet. Les utilisateurs Premium peuvent ignorer cela.';

  @override
  String get rewarded_start_watch => 'Regarder la pub';

  @override
  String get rewarded_start_continue => 'Continuer';

  @override
  String get rewarded_start_skip => 'Ignorer';

  @override
  String get rewarded_start_thanks => 'Merci pour votre soutien !';

  @override
  String get ads_consent_title => 'Consentement publicitaire';

  @override
  String get ads_consent_message =>
      'Pour respecter le RGPD, nous avons besoin de votre consentement avant d’afficher des publicités. Vous pouvez continuer à utiliser l’application même en refusant.';

  @override
  String get ads_consent_accept => 'J’accepte';

  @override
  String get ads_consent_refuse => 'Je refuse';

  @override
  String get ads_consent_refused_info =>
      'Consentement pub refusé. Le bot démarre normalement.';

  @override
  String get error => 'Erreur';

  @override
  String error_with_details(String error) {
    return 'Erreur : $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fermer';

  @override
  String get copy => 'Copier';

  @override
  String get delete => 'Supprimer';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get create => 'Créer';

  @override
  String get confirm => 'Confirmer';

  @override
  String get bot_home_start => 'Lancer le bot';

  @override
  String get bot_home_starting => 'Démarrage…';

  @override
  String get bot_home_stop => 'Arrêter le bot';

  @override
  String get bot_home_ios_notice_title => 'Contrainte iOS locale';

  @override
  String get bot_home_ios_notice_content =>
      'En mode local, iOS peut suspendre l’application en arrière-plan. Le bot peut démarrer, mais le maintien de la connexion Discord n’est pas garanti comme avec un Runner.';

  @override
  String get bot_home_view_logs => 'Voir les logs du bot';

  @override
  String get bot_home_view_stats => 'Voir les stats du bot';

  @override
  String get bot_home_view_replay => 'Voir les replays du débogueur';

  @override
  String get bot_home_section_getting_started => 'PREMIERS PAS';

  @override
  String get bot_home_customize => 'Personnaliser mon bot';

  @override
  String get bot_home_create_command => 'Créer ma première commande';

  @override
  String get bot_home_section_monitoring => 'MONITORING';

  @override
  String get bot_home_section_tools => 'OUTILS';

  @override
  String get bot_home_section_danger => 'ZONE DE DANGER';

  @override
  String get bot_home_sync => 'Synchroniser l’app';

  @override
  String get bot_home_sync_success => 'Application synchronisée avec succès';

  @override
  String get bot_home_invite => 'Inviter le bot';

  @override
  String get bot_home_invite_error =>
      'Impossible d’ouvrir le lien d’invitation';

  @override
  String get bot_home_delete => 'Supprimer l’application';

  @override
  String get bot_home_delete_confirm =>
      'Êtes-vous sûr de vouloir supprimer cette application ?';

  @override
  String bot_home_start_error(String error) {
    return 'Impossible de démarrer : $error';
  }

  @override
  String get bot_home_log_start => 'Démarrage du bot demandé';

  @override
  String get bot_home_log_stop => 'Arrêt du bot demandé';

  @override
  String get bot_home_log_desktop_stop => 'Arrêt du bot desktop demandé';

  @override
  String get bot_home_notif_required =>
      'La permission de notification est requise pour lancer le service du bot.';

  @override
  String get bot_home_service_not_started =>
      'Le service foreground n’a pas démarré.';

  @override
  String get bot_home_token_invalid_title => 'Token apparemment invalide';

  @override
  String get bot_home_token_invalid_content =>
      'Impossible de se connecter a Discord avec le token fourni. Il est peut-etre invalide ou revoque. Voulez-vous quand meme lancer le bot ?';

  @override
  String get bot_offline_token_desc =>
      'Token invalide ou manquant. Entrez un nouveau token Discord pour retablir la connexion.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Cette commande n\'a pas pu être entièrement chargée (hors-ligne ou token invalide). Connectez un token valide pour modifier.';

  @override
  String get bot_settings_token_mismatch_title => 'Bot différent détecté';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Ce token appartient au bot $newId, mais les données actuelles concernent le bot $oldId. Les commandes et paramètres peuvent ne pas correspondre. Continuer quand même ?';
  }

  @override
  String get bot_settings_token_mismatch_confirm =>
      'Remplacer le token quand même';

  @override
  String get bot_settings_title => 'Personnaliser le bot / Profil';

  @override
  String get bot_settings_workflow_docs => 'Centre de documentation';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Documentation centralisée pour les commandes, workflows, variables runtime et comportement d’exécution.';

  @override
  String get bot_settings_export_import => 'Export / Import';

  @override
  String get bot_settings_export_import_desc =>
      'Exportez ou importez la configuration de votre bot sous forme de fichier ZIP.';

  @override
  String get bot_settings_app_flags => 'Indicateurs de l’application';

  @override
  String get bot_settings_gateway_intents =>
      'Configuration des Gateway Intents';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Sélectionnez les intents dont votre bot a besoin. Configurez-les sur le Discord Developer Portal.';

  @override
  String get bot_settings_token_title => 'Token du bot';

  @override
  String get bot_settings_update_token => 'Mettre à jour le token du bot';

  @override
  String get bot_settings_token_hint => 'Entrez votre token de bot ici';

  @override
  String get bot_settings_save_success => 'Paramètres enregistrés avec succès';

  @override
  String get bot_settings_save_token_btn => 'Sauvegarder token et intents';

  @override
  String get bot_settings_save_token_only_btn => 'Sauvegarder le token';

  @override
  String get bot_settings_save_intents_btn => 'Sauvegarder les intents';

  @override
  String get bot_settings_save_profile_status_btn =>
      'Sauvegarder profil et statuts';

  @override
  String get bot_settings_save_token_caption =>
      'Le token est protege. Cliquez d\'abord sur \"Modifier le token\", puis sauvegardez.';

  @override
  String get bot_settings_save_intents_caption =>
      'Cette action met a jour uniquement la configuration des intents.';

  @override
  String get bot_settings_save_profile_caption =>
      'Cette action applique le nom/avatar immediatement et enregistre la rotation des statuts.';

  @override
  String get bot_settings_token_saved => 'Token sauvegarde avec succes';

  @override
  String get bot_settings_intents_saved => 'Intents sauvegardes avec succes';

  @override
  String get bot_settings_profile_saved =>
      'Profil/statuts appliqués avec succès';

  @override
  String get bot_settings_edit_token_btn => 'Modifier le token';

  @override
  String get bot_settings_cancel_token_edit_btn =>
      'Annuler la modification du token';

  @override
  String get bot_settings_token_hidden_desc =>
      'Le champ du token est masque par defaut pour plus de securite.';

  @override
  String get bot_settings_token_required => 'Le token du bot est requis.';

  @override
  String get bot_settings_save_token_first =>
      'Veuillez d\'abord sauvegarder le token avant d\'appliquer les changements de profil/statuts.';

  @override
  String get bot_settings_profile_title => 'Profil du bot';

  @override
  String get bot_settings_username_override =>
      'Nom d\'utilisateur personnalisé';

  @override
  String get bot_settings_username_hint =>
      'Laisser vide pour conserver le nom d\'utilisateur actuel';

  @override
  String get bot_settings_avatar_local_path => 'Chemin local de l\'avatar';

  @override
  String get bot_settings_avatar_path_hint => '/chemin/absolu/vers/avatar.png';

  @override
  String get bot_settings_browse => 'Parcourir';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Fichier selectionne : $path';
  }

  @override
  String get bot_settings_avatar_preview_label => 'Apercu de l\'avatar';

  @override
  String get bot_settings_avatar_preview_error =>
      'Impossible d\'afficher l\'aperçu de l\'image';

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Format d\'avatar non supporte : $ext. Formats supportes : $formats.';
  }

  @override
  String get bot_settings_avatar_clear_selection => 'Effacer la selection';

  @override
  String get bot_settings_presence_status_title => 'Statut de Présence du Bot';

  @override
  String get bot_settings_presence_status_label => 'Présence';

  @override
  String get bot_settings_presence_online => 'En ligne';

  @override
  String get bot_settings_presence_idle => 'Absent (Inactif)';

  @override
  String get bot_settings_presence_dnd => 'Ne pas déranger';

  @override
  String get bot_settings_presence_invisible => 'Invisible';

  @override
  String get bot_settings_status_rotation_title => 'Rotation des activités';

  @override
  String get bot_settings_status_rotation_desc =>
      'Ajoutez une ou plusieurs activités. Chaque activité nécessite un type, un nom et un intervalle min/max (secondes).';

  @override
  String get bot_settings_add_status => 'Ajouter une activité';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Activité $index';
  }

  @override
  String get bot_settings_remove_status => 'Supprimer l\'activité';

  @override
  String get bot_settings_status_type_label => 'Type';

  @override
  String get bot_settings_status_type_playing => 'Joue a';

  @override
  String get bot_settings_status_type_streaming => 'Diffuse';

  @override
  String get bot_settings_status_type_listening => 'Ecoute';

  @override
  String get bot_settings_status_type_watching => 'Regarde';

  @override
  String get bot_settings_status_type_competing => 'Participe';

  @override
  String get bot_settings_status_text_label => 'Nom de l\'activité';

  @override
  String get bot_settings_activity_state_label =>
      'État de l\'activité (optionnel)';

  @override
  String get bot_settings_activity_url_label =>
      'URL de stream (pour streaming)';

  @override
  String get bot_settings_status_min_interval => 'Intervalle min (s)';

  @override
  String get bot_settings_status_max_interval => 'Intervalle max (s)';

  @override
  String get bot_logs_title => 'Logs du bot';

  @override
  String get bot_logs_disable_debug => 'Désactiver les logs debug';

  @override
  String get bot_logs_enable_debug => 'Activer les logs debug';

  @override
  String get bot_logs_copied => 'Logs copiés';

  @override
  String get bot_logs_oldest_first => 'Afficher les plus anciens en premier';

  @override
  String get bot_logs_newest_first => 'Afficher les plus récents en premier';

  @override
  String get bot_logs_filter_count => 'Nombre de logs affichés';

  @override
  String bot_logs_show_n(int count) {
    return 'Afficher $count logs';
  }

  @override
  String get bot_logs_show_all => 'Afficher tout';

  @override
  String get bot_logs_empty => 'Aucun log pour le moment';

  @override
  String get bot_logs_show_more => 'Afficher plus';

  @override
  String get bot_logs_show_less => 'Afficher moins';

  @override
  String bot_logs_ram(String memory) {
    return 'RAM du processus bot : $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'RAM bot estimée : $memory';
  }

  @override
  String get bot_logs_go_to_latest => 'Aller au dernier log';

  @override
  String get bot_logs_go_to_bottom => 'Aller en bas';

  @override
  String get bot_logs_raw_mode => 'Logs bruts compacts';

  @override
  String get bot_logs_rich_mode => 'Logs formatés';

  @override
  String get debug_replay_title => 'Replay Débogueur';

  @override
  String get debug_replay_start_capture => 'Activer la capture';

  @override
  String get debug_replay_stop_capture => 'Désactiver la capture';

  @override
  String get debug_replay_clear => 'Effacer les replays';

  @override
  String get debug_replay_clear_title => 'Effacer les replays';

  @override
  String get debug_replay_clear_confirm =>
      'Tous les replays enregistrés seront supprimés. Continuer ?';

  @override
  String get debug_replay_empty_capturing =>
      'Capture en cours… Lancez une commande pour enregistrer un replay.';

  @override
  String get debug_replay_empty_idle =>
      'Capture désactivée. Activez-la et lancez une commande pour enregistrer un replay.';

  @override
  String get debug_replay_premium_title => 'Replay Débogueur Visuel';

  @override
  String get debug_replay_premium_desc =>
      'Enregistrez et rejouez vos exécutions de commandes étape par étape. Voyez exactement ce que chaque action a fait, combien de temps elle a pris et où les erreurs se sont produites.';

  @override
  String get debug_replay_overview => 'Vue d\'ensemble';

  @override
  String get debug_replay_play => 'Lire';

  @override
  String get debug_replay_pause => 'Pause';

  @override
  String get debug_replay_step_first => 'Première étape';

  @override
  String get debug_replay_step_last => 'Dernière étape';

  @override
  String get debug_replay_step_back => 'Étape précédente';

  @override
  String get debug_replay_step_forward => 'Étape suivante';

  @override
  String get debug_replay_duration_label => 'DURÉE';

  @override
  String get debug_replay_result_label => 'RÉSULTAT';

  @override
  String get debug_replay_result_empty => '(aucun résultat)';

  @override
  String debug_replay_start_offset(int ms) {
    return '+$ms ms depuis le début';
  }

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Boucle profondeur $depth, itération $iteration';
  }

  @override
  String get debug_replay_variables_label => 'VARIABLES';

  @override
  String get debug_replay_variables_empty => '(aucune variable)';

  @override
  String get bot_stats_title => 'Statistiques du bot';

  @override
  String get bot_stats_ram_process => 'RAM du processus bot';

  @override
  String get bot_stats_ram_estimated => 'RAM bot uniquement (estimée)';

  @override
  String get bot_stats_cpu => 'CPU du processus bot';

  @override
  String get bot_stats_storage => 'Stockage du bot (données app)';

  @override
  String get bot_stats_source_runner_api => 'Source : API Runner';

  @override
  String get bot_stats_source_local_hosting => 'Source : hébergement local';

  @override
  String get bot_stats_notes =>
      'Notes : CPU disponible sur Android/Linux. Stockage = fichiers de données du bot dans l’application.';

  @override
  String get bot_stats_collecting => 'Collecte…';

  @override
  String get commands_title => 'Commandes';

  @override
  String get commands_empty => 'Aucune commande trouvée';

  @override
  String commands_error(String error) {
    return 'Erreur : $error';
  }

  @override
  String get commands_create_button => 'Créer une commande';

  @override
  String get commands_move_to_folder => 'Déplacer dans un dossier';

  @override
  String get commands_remove_from_folder => 'Retirer du dossier';

  @override
  String get commands_new_folder_hint => 'Nom du nouveau dossier';

  @override
  String get commands_folder_label => 'Dossier';

  @override
  String get commands_folder_hint => 'Nom du dossier (optionnel)';

  @override
  String get commands_create_folder => 'Créer un dossier';

  @override
  String get commands_rename_folder => 'Renommer le dossier';

  @override
  String get commands_delete_folder => 'Supprimer le dossier';

  @override
  String get commands_delete_folder_desc =>
      'Les commandes de ce dossier ne seront pas supprimées, juste retirées du dossier.';

  @override
  String get commands_reorder_title => 'Organiser les commandes';

  @override
  String get commands_no_folder => 'Aucun dossier';

  @override
  String get export_import_title => 'Export / Import';

  @override
  String get export_section_title => 'Export';

  @override
  String get export_section_desc =>
      'Exportez les sections sélectionnées de votre bot sous forme de fichier ZIP. Le token du bot n\'est jamais inclus.';

  @override
  String get export_commands => 'Commandes';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get export_status => 'Statut & Activités';

  @override
  String get export_global_variables => 'Variables globales';

  @override
  String get export_button => 'Exporter en ZIP';

  @override
  String get import_section_title => 'Import';

  @override
  String get import_section_desc =>
      'Importez un fichier ZIP précédemment exporté. Les conflits peuvent être résolus par élément.';

  @override
  String get import_pick_file => 'Sélectionner un fichier ZIP';

  @override
  String get import_button => 'Importer';

  @override
  String get import_overwrite => 'Écraser';

  @override
  String get import_skip => 'Ignorer';

  @override
  String get globals_title => 'Variables';

  @override
  String get globals_empty => 'Aucune variable globale pour le moment';

  @override
  String get globals_empty_subtitle =>
      'Ajoutez une variable pour stocker des données persistantes accessibles par toutes les commandes.';

  @override
  String get globals_add => 'Ajouter une variable';

  @override
  String get globals_add_global => 'Ajouter une variable globale';

  @override
  String get globals_add_scoped => 'Ajouter une variable scopée';

  @override
  String get globals_edit => 'Modifier une variable';

  @override
  String get globals_edit_global => 'Modifier la variable globale';

  @override
  String get globals_edit_scoped => 'Modifier la variable scopée';

  @override
  String get globals_key => 'Clé';

  @override
  String get globals_key_hint => 'ex. prefix, level, welcome_message';

  @override
  String get globals_value => 'Valeur';

  @override
  String get globals_delete_title => 'Supprimer la variable';

  @override
  String globals_delete_confirm(String key) {
    return 'Supprimer « $key » ?';
  }

  @override
  String get globals_search => 'Rechercher des variables…';

  @override
  String get globals_mode_global => 'Globale';

  @override
  String get globals_mode_scoped => 'Scopée';

  @override
  String get globals_help_global =>
      'Partagées entre toutes les commandes. Accessibles via \$getVar[clé].';

  @override
  String get globals_help_scoped =>
      'Stockées par contexte (serveur, utilisateur, salon…). Chaque entrée conserve une valeur distincte par contexte Discord.';

  @override
  String get globals_source_local => 'Local';

  @override
  String globals_source_runner(String name) {
    return 'Runner : $name';
  }

  @override
  String get globals_value_auto_type_hint =>
      'La valeur est auto-typée (nombre, booléen, JSON).';

  @override
  String get globals_copy_value => 'Copier la valeur';

  @override
  String get globals_no_default => 'Aucune valeur par défaut';

  @override
  String get globals_dialog_global_desc =>
      'Les variables globales sont partagées entre toutes les commandes et serveurs.';

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Une variable scopée stocke une valeur distincte par contexte $scope.';
  }

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Usage : \$getVar[$ref]';
  }

  @override
  String get scoped_title => 'Variables scopées';

  @override
  String get scoped_empty => 'Aucune variable scopée définie';

  @override
  String get scoped_empty_subtitle =>
      'Les variables scopées stockent une valeur par contexte Discord (utilisateur, serveur…). Elles sont peuplées par le bot à l\'exécution.';

  @override
  String get scoped_delete_title => 'Supprimer la variable scopée';

  @override
  String scoped_delete_confirm(String key) {
    return 'Supprimer « $key » et toutes ses données runtime stockées ?';
  }

  @override
  String get scoped_default_value => 'Valeur par défaut';

  @override
  String get scoped_default_value_hint => 'Optionnel';

  @override
  String get scoped_scope => 'Scope';

  @override
  String get scoped_scope_help =>
      'Le niveau d\'entité auquel la variable est stockée.';

  @override
  String scoped_ref(String ref) {
    return 'Référence : $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legacy : $ref';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Données runtime — « $key »';
  }

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Scope : $scope · $count contexte(s) trouvé(s)';
  }

  @override
  String get scoped_runtime_empty =>
      'Aucune donnée runtime.\nCette clé sera peuplée par le bot à l\'exécution.';

  @override
  String get scoped_runtime_copy_all => 'Tout copier';

  @override
  String get scoped_runtime_search => 'Rechercher par ID ou nom…';

  @override
  String get scoped_explore_runtime => 'Explorer les données runtime';

  @override
  String get globals_refresh => 'Actualiser';

  @override
  String get globals_retry => 'Réessayer';

  @override
  String get globals_scope_guild => 'guild';

  @override
  String get globals_scope_user => 'user';

  @override
  String get globals_scope_channel => 'channel';

  @override
  String get globals_scope_guildMember => 'guildMember';

  @override
  String get globals_scope_message => 'message';

  @override
  String get workflows_title => 'Workflows';

  @override
  String get workflows_empty => 'Aucun workflow pour le moment';

  @override
  String get workflows_create => 'Créer un workflow';

  @override
  String get workflows_edit => 'Modifier le workflow';

  @override
  String get workflows_name => 'Nom du workflow';

  @override
  String get workflows_entry_point => 'Point d’entrée par défaut';

  @override
  String get workflows_entry_point_hint =>
      'Utilisé si l’appelant ne le remplace pas';

  @override
  String get workflows_arguments => 'Arguments';

  @override
  String get workflows_arg_name => 'Nom';

  @override
  String get workflows_arg_default => 'Valeur par défaut';

  @override
  String get workflows_arg_required_short => 'Req';

  @override
  String get workflows_arg_hint =>
      'Les arguments deviennent des variables runtime sous la forme ((arg.name)) et ((workflow.arg.name)).';

  @override
  String get workflows_continue => 'Continuer';

  @override
  String get workflows_add_arg => 'Ajouter un argument';

  @override
  String get workflows_docs_tooltip => 'Ouvrir le centre de documentation';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count action(s) • entrée : $entry • args : $args';
  }

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count action(s) • Listen for : $event';
  }

  @override
  String get workflows_general_section => 'Workflows generaux';

  @override
  String get workflows_event_section => 'Workflows d\'event';

  @override
  String get workflows_type_title => 'Type de workflow';

  @override
  String get workflows_type_general => 'Workflow general';

  @override
  String get workflows_type_general_desc =>
      'Logique reutilisable appelee depuis les commandes, boutons, modals ou autres workflows.';

  @override
  String get workflows_type_event => 'Workflow d\'event';

  @override
  String get workflows_type_event_desc =>
      'Se declenche automatiquement quand Discord emet un event.';

  @override
  String get workflows_type_badge_general => 'General';

  @override
  String get workflows_type_badge_event => 'Event';

  @override
  String get workflows_listen_for => 'Listen for';

  @override
  String get workflows_event_category => 'Categorie d\'event';

  @override
  String get workflows_event_hint =>
      'Choisissez l\'event Discord qui doit declencher ce workflow.';

  @override
  String workflows_event_preview(String event) {
    return 'Listen for : $event';
  }

  @override
  String get workflows_event_available_vars => 'Variables disponibles';

  @override
  String get workflows_event_category_messages => 'Messages';

  @override
  String get workflows_event_category_members => 'Membres';

  @override
  String get workflows_event_category_channels => 'Salons';

  @override
  String get workflows_event_category_invites => 'Invitations';

  @override
  String get workflows_event_message_create => 'Message Create';

  @override
  String get workflows_event_message_create_desc =>
      'Declenche quand un nouveau message est cree.';

  @override
  String get workflows_event_message_update => 'Message Update';

  @override
  String get workflows_event_message_update_desc =>
      'Declenche quand un message existant est modifie.';

  @override
  String get workflows_event_message_delete => 'Message Delete';

  @override
  String get workflows_event_message_delete_desc =>
      'Declenche quand un message est supprime.';

  @override
  String get workflows_event_member_join => 'Member Join';

  @override
  String get workflows_event_member_join_desc =>
      'Declenche quand un membre rejoint le serveur.';

  @override
  String get workflows_event_member_remove => 'Member Remove';

  @override
  String get workflows_event_member_remove_desc =>
      'Declenche quand un membre quitte le serveur ou en est retire.';

  @override
  String get workflows_event_channel_update => 'Channel Update';

  @override
  String get workflows_event_channel_update_desc =>
      'Declenche quand un salon est mis a jour.';

  @override
  String get workflows_event_invite_create => 'Invite Create';

  @override
  String get workflows_event_invite_create_desc =>
      'Declenche quand une invitation est creee.';

  @override
  String get workflows_import_tooltip => 'Importer des workflows';

  @override
  String get workflows_export_tooltip => 'Copier des workflows';

  @override
  String get workflows_copy_none => 'Aucun workflow à copier.';

  @override
  String get workflows_copy_done_json => 'Workflows copiés en JSON.';

  @override
  String get workflows_copy_done_base64 => 'Workflows copiés en Base64.';

  @override
  String get workflows_delete_title => 'Supprimer le workflow';

  @override
  String workflows_delete_confirm(String name) {
    return 'Voulez-vous vraiment supprimer \"$name\" ? Cette action est irréversible.';
  }

  @override
  String get workflows_export_json => 'Copier en JSON';

  @override
  String get workflows_export_json_desc => 'Lisible et modifiable facilement.';

  @override
  String get workflows_export_base64 => 'Copier en Base64';

  @override
  String get workflows_export_base64_desc => 'Pratique pour partage compact.';

  @override
  String get workflows_import_title => 'Importer des workflows';

  @override
  String get workflows_import_desc =>
      'Colle un payload JSON ou Base64 (JSON) exporté depuis Bot Creator.';

  @override
  String get workflows_import_input_hint => 'Colle ici le JSON ou le Base64...';

  @override
  String get workflows_import_overwrite => 'Remplacer si le nom existe';

  @override
  String get workflows_import_action => 'Importer';

  @override
  String get workflows_import_empty => 'Aucune donnée à importer.';

  @override
  String get workflows_import_invalid_format =>
      'Format invalide. Utilise JSON ou Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'Aucun workflow valide trouvé.';

  @override
  String workflows_import_done(int count) {
    return '$count workflow(s) importé(s).';
  }

  @override
  String get workflows_move_to_folder => 'Déplacer dans un dossier';

  @override
  String get workflows_remove_from_folder => 'Retirer du dossier';

  @override
  String get workflows_new_folder_hint => 'Nom du nouveau dossier';

  @override
  String get workflows_folder_label => 'Dossier';

  @override
  String get workflows_folder_hint => 'Nom du dossier (optionnel)';

  @override
  String get cmd_error_fill_fields => 'Veuillez remplir tous les champs';

  @override
  String get cmd_variables_title => 'Variables de la commande';

  @override
  String get cmd_show_variables => 'Ouvrir la documentation des variables';

  @override
  String get cmd_create_tooltip => 'Créer la commande';

  @override
  String get cmd_delete_tooltip => 'Supprimer la commande';

  @override
  String get cmd_editor_mode_title => 'Mode d’édition';

  @override
  String get cmd_editor_mode_simple => 'Mode simplifié';

  @override
  String get cmd_editor_mode_advanced => 'Mode avancé';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Créez une commande rapidement avec des options guidées et des actions préconfigurées.';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Éditeur complet avec réponse personnalisée, options et builder d’actions.';

  @override
  String get cmd_editor_mode_switch_adv => 'Passer en mode avancé';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Passer en mode avancé ?';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Ce changement est définitif pour cette commande. Vous ne pourrez plus revenir au mode simplifié.';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Passer';

  @override
  String get cmd_editor_mode_locked =>
      'Le mode avancé est verrouillé pour cette commande.';

  @override
  String get cmd_execution_mode_title => 'Mode d’exécution';

  @override
  String get cmd_execution_mode_desc =>
      'La définition de commande reste dans le builder visuel. Choisissez ensuite comment exécuter le corps de la commande.';

  @override
  String get cmd_execution_mode_workflow => 'Mode workflow';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Utilise le builder visuel actuel pour la réponse et les actions.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'Le mode workflow reste le chemin de production actuel et continue d’être totalement pris en charge.';

  @override
  String get cmd_execution_mode_bdfd => 'Mode script BDFD';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Écrivez le corps de commande en script compatible BDFD tout en gardant la définition visuelle.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'Le script est compilé en actions internes. Les diagnostics sont affichés pendant l’édition ; les scripts invalides échouent à l’exécution.';

  @override
  String get cmd_execution_mode_dart => 'Mode Dart Direct';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Écrivez directement le corps de commande en Dart avec diagnostics runtime.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Le code Dart est compilé au runtime via un moteur sandboxé. Gardez les scripts déterministes et retournez une valeur quand nécessaire.';

  @override
  String get cmd_bdfd_script_label => 'Corps du script BDFD';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator';

  @override
  String get cmd_bdfd_diagnostics_title => 'Diagnostics BDFD';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Aucun problème détecté dans le script courant.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Erreur';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Avertissement';

  @override
  String get cmd_bdfd_script_empty_error =>
      'Le corps du script BDFD ne peut pas être vide.';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Ce script BDFD contient encore des diagnostics :';

  @override
  String get cmd_dart_script_label => 'Corps du script Dart';

  @override
  String get cmd_dart_script_hint => 'return \"Hello from Dart Direct\";';

  @override
  String get cmd_dart_diagnostics_title => 'Diagnostics Dart';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Aucun problème détecté dans le script Dart courant.';

  @override
  String get cmd_dart_diagnostics_error => 'Erreur';

  @override
  String get cmd_dart_diagnostics_warning => 'Avertissement';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Générer un squelette de migration Dart à partir du script BDFD actuel.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrer';

  @override
  String get cmd_bdfd_autocomplete_title => 'Auto-complétion BDFD par préfixe';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Tapez \$ puis le début d’une fonction pour afficher des suggestions rapides.';

  @override
  String get workflow_mode_title => 'Mode du workflow';

  @override
  String get workflow_mode_desc =>
      'Choisissez entre un éditeur visuel d’actions ou un éditeur de script BDFD complet.';

  @override
  String get workflow_mode_visual => 'Visuel';

  @override
  String get workflow_mode_bdfd => 'Script BDFD';

  @override
  String get workflow_mode_dart => 'Dart Direct';

  @override
  String get workflow_mode_visual_note =>
      'Construisez votre workflow visuellement en ajoutant des actions individuelles avec l’éditeur de cartes.';

  @override
  String get workflow_mode_bdfd_note =>
      'Écrivez l’intégralité de votre workflow sous forme de script BDFD. Le script est compilé et validé en temps réel.';

  @override
  String get workflow_mode_dart_note =>
      'Écrivez votre workflow en Dart. Les diagnostics sont mis à jour pendant l’édition pour détecter rapidement les erreurs.';

  @override
  String get workflow_bdfd_editor_title => 'Éditeur de script BDFD';

  @override
  String get workflow_bdfd_editor_desc =>
      'Écrivez le code BDFD complet pour cette réponse workflow. Les diagnostics s’affichent en direct.';

  @override
  String get workflow_dart_editor_title => 'Éditeur de script Dart';

  @override
  String get workflow_dart_editor_desc =>
      'Écrivez le code Dart complet pour cette réponse workflow. Les diagnostics s’affichent en direct.';

  @override
  String get bdfd_editor_title => 'Éditeur BDFD';

  @override
  String get bdfd_editor_tap_hint => 'Appuyez pour ouvrir l’éditeur';

  @override
  String get bdfd_editor_wrap_toggle =>
      'Activer/désactiver le retour à la ligne';

  @override
  String get bdfd_editor_diagnostics_toggle =>
      'Afficher/masquer le panneau de diagnostics';

  @override
  String get bdfd_editor_empty =>
      'Script vide — commencez à écrire pour voir les diagnostics.';

  @override
  String get dart_editor_title => 'Éditeur Dart';

  @override
  String get dart_editor_tap_hint => 'Appuyez pour ouvrir l’éditeur Dart';

  @override
  String get dart_editor_empty =>
      'Script vide — commencez à écrire pour voir les diagnostics Dart.';

  @override
  String get bdfd_editor_docs => 'Référence des fonctions BDFD';

  @override
  String get bdfd_docs_title => 'Docs BDFD';

  @override
  String get bdfd_docs_search_hint => 'Rechercher une fonction…';

  @override
  String get scratch_block_metadata => 'Métadonnées';

  @override
  String get scratch_block_required => 'Requis';

  @override
  String get scratch_block_entry_point => 'Point de départ (Déclencheur)';

  @override
  String get scratch_entry_point_listen =>
      'Quand est-ce que cette commande se lance ?';

  @override
  String get scratch_entry_interaction => 'Commande Slash (/)';

  @override
  String get scratch_entry_message => 'Message Texte';

  @override
  String get scratch_entry_point_label => 'Nom du point d’entrée';

  @override
  String get scratch_execution_mode => 'Comment est construite la commande ?';

  @override
  String get scratch_mode_blocks => 'Visuel (Blocs)';

  @override
  String get scratch_mode_bdfd => 'Code BDFD';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_legacy_config => 'Configuration héritée';

  @override
  String get scratch_add_block => 'Ajouter un bloc';

  @override
  String get scratch_bdfd_script => 'Script BDFD';

  @override
  String get scratch_response_block => 'Réponse';

  @override
  String get scratch_response_components => 'Composants';

  @override
  String get scratch_response_edit => 'Modifier la réponse';

  @override
  String get scratch_meta_name_hint => 'Nom de la commande';

  @override
  String get scratch_meta_desc_hint => 'Description de la commande';

  @override
  String get scratch_meta_type_label => 'Type de commande';

  @override
  String get scratch_meta_type_slash => 'Commande slash';

  @override
  String get scratch_meta_type_prefix => 'Commande préfixe';

  @override
  String get scratch_meta_type_user => 'Commande utilisateur';

  @override
  String get scratch_meta_type_message => 'Commande message';

  @override
  String get scratch_meta_type_slash_desc =>
      'Déclenchée en tapant / dans Discord.';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Déclenchée par un préfixe texte (ex : !help).';

  @override
  String get scratch_meta_type_user_desc =>
      'Déclenchée depuis le menu contextuel utilisateur.';

  @override
  String get scratch_meta_type_message_desc =>
      'Déclenchée depuis le menu contextuel message.';

  @override
  String get scratch_meta_advanced => 'Paramètres avancés';

  @override
  String get scratch_workflow_metadata => 'Paramètres du workflow';

  @override
  String get scratch_workflow_name => 'Nom du workflow';

  @override
  String get scratch_workflow_type => 'Type de workflow';

  @override
  String get scratch_workflow_type_general => 'Général';

  @override
  String get scratch_workflow_type_event => 'Événement';

  @override
  String get scratch_workflow_arguments => 'Arguments (Variables)';

  @override
  String get scratch_workflow_add_argument => 'Ajouter un argument';

  @override
  String get scratch_entry_event_trigger => 'Déclencheur d’événement';

  @override
  String get scratch_entry_function => 'Fonction';

  @override
  String get scratch_event_category => 'Catégorie d’événement';

  @override
  String get scratch_event_name => 'Nom de l’événement';

  @override
  String get scratch_event_variables => 'Variables d’événement';

  @override
  String get bdfd_docs_empty => 'Aucune fonction trouvée.';

  @override
  String get bdfd_docs_syntax => 'SYNTAXE';

  @override
  String get bdfd_docs_parameters => 'PARAMÈTRES';

  @override
  String get bdfd_docs_no_params =>
      'Aucun paramètre — utiliser comme \$nomFonction';

  @override
  String get bdfd_docs_category_messages => 'Messages & Contenu';

  @override
  String get bdfd_docs_category_embeds => 'Embeds';

  @override
  String get bdfd_docs_category_components => 'Composants';

  @override
  String get bdfd_docs_category_modals => 'Modals';

  @override
  String get bdfd_docs_category_control => 'Flux de contrôle';

  @override
  String get bdfd_docs_category_guards => 'Gardes & Permissions';

  @override
  String get bdfd_docs_category_moderation => 'Modération';

  @override
  String get bdfd_docs_category_variables => 'Variables';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_http => 'Requêtes HTTP';

  @override
  String get bdfd_docs_category_math => 'Mathématiques';

  @override
  String get bdfd_docs_category_text => 'Texte & Chaînes';

  @override
  String get bdfd_docs_category_channels => 'Salons & Threads';

  @override
  String get bdfd_docs_category_roles => 'Rôles';

  @override
  String get bdfd_docs_category_reactions => 'Réactions';

  @override
  String get bdfd_docs_category_cooldowns => 'Cooldowns';

  @override
  String get bdfd_docs_category_webhooks => 'Webhooks';

  @override
  String get bdfd_docs_category_leaderboards => 'Classements';

  @override
  String get bdfd_docs_category_tickets => 'Tickets';

  @override
  String get bdfd_docs_category_misc => 'Autres';

  @override
  String get bdfd_docs_desc_for =>
      'Bot Creator uniquement — Répète un bloc de code N fois.\n\nSimple : \$for[5]...\$endfor → le corps est répété 5 fois (max 100). Utilisez \$i pour l\'index courant (à partir de 0) et \$loopCount pour le total.\n\nStyle C : \$for[i=0;i<10;i++]...\$endfor → boucle for classique avec init, condition et mise à jour. Supporte ++, --, +=, -=, *=.\n\nSi le nombre d\'itérations est dynamique (ex : \$for[\$args[1]]), la boucle s\'exécute au runtime.';

  @override
  String get bdfd_docs_desc_loop =>
      'Bot Creator uniquement — Alias de \$for. Voir \$for pour les détails. Utilisez \$endloop pour fermer le bloc.';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Bot Creator uniquement — Appelle un autre workflow par nom et transmet des arguments.\n\nSyntaxe : \$callWorkflow[monWorkflow;clé1=valeur1;clé2=valeur2]\n\nLe workflow appelé peut lire les arguments et retourner une valeur via \$workflowResponse.';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Bot Creator uniquement — Retourne la réponse du dernier \$callWorkflow.\n\nUtilisez \$workflowResponse[] pour la réponse complète, ou \$workflowResponse[propriété] pour un champ spécifique.';

  @override
  String get bdfd_docs_desc_eval =>
      'Exécute une chaîne de script BDFD au runtime. Le code passé en argument est recompilé et exécuté dynamiquement. Utile pour exécuter des scripts basés sur des variables.';

  @override
  String get bdfd_docs_desc_if =>
      'Bloc conditionnel. Supporte l\'imbrication et des opérateurs riches : ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUtilisation :\n\$if[\$authorID==123456]\n  Bonjour admin !\n\$elseif[\$hasRole[789]]\n  Bonjour membre !\n\$else\n  Bonjour invité !\n\$endif';

  @override
  String get bdfd_docs_desc_elseif =>
      'Ajoute une condition alternative dans un bloc \$if. Doit apparaître entre \$if et \$else/\$endif.';

  @override
  String get bdfd_docs_desc_try =>
      'Encadre un bloc pour la gestion d\'erreurs.\n\nUtilisation :\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  La requête a échoué !\n\$endtry\n\nSi une fonction du bloc \$try échoue, l\'exécution passe au \$catch.';

  @override
  String get bdfd_docs_desc_stop =>
      'Arrête immédiatement l\'exécution du script. Aucune action après \$stop ne sera exécutée.';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'Empêche l\'envoi des messages d\'erreur à l\'utilisateur. Si une action échoue, l\'erreur est supprimée silencieusement.';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      'Identique à \$suppressErrors — supprime tous les messages d\'erreur silencieusement.';

  @override
  String get bdfd_docs_desc_and =>
      'ET logique — combine plusieurs conditions. Toutes doivent être vraies.\n\nUtilisation : \$if[\$and[\$authorID==123;\$hasRole[456]]]';

  @override
  String get bdfd_docs_desc_or =>
      'OU logique — combine plusieurs conditions. Au moins une doit être vraie.\n\nUtilisation : \$if[\$or[\$authorID==123;\$authorID==456]]]';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'Enregistre un callback qui attend une réponse utilisateur.\n\nUtilisation : \$awaitFunc[nom;userID (opt);channelID (opt)]\n\nLa fonction attendue est stockée et déclenchée quand l\'utilisateur cible envoie un message dans le salon cible.';

  @override
  String get bdfd_docs_desc_defer =>
      'Diffère la réponse à l\'interaction, vous donnant plus de temps. L\'utilisateur voit « Le bot réfléchit… ». À utiliser avant les opérations longues comme les requêtes HTTP.';

  @override
  String get bdfd_docs_desc_ephemeral =>
      'Rend la réponse visible uniquement pour l\'utilisateur qui a déclenché la commande. Doit être placé avant tout contenu de réponse.';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'Parse une chaîne JSON en mémoire pour manipulation. Toutes les opérations JSON (\$jsonSet, \$json, etc.) agissent sur ce contexte.\n\nLe JSON statique est résolu au compile-time pour de meilleures performances.';

  @override
  String get bdfd_docs_desc_jsonset =>
      'Définit une valeur dans le contexte JSON courant. Supporte les chemins en notation pointée.\n\nUtilisation : \$jsonSet[user.name;John]\n\nLa modification est en mémoire — utilisez \$jsonStringify pour obtenir le résultat.';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      'Convertit le contexte JSON courant en chaîne de caractères. À utiliser après \$jsonParse et \$jsonSet pour obtenir le résultat.';

  @override
  String get bdfd_docs_desc_httpget =>
      'Envoie une requête HTTP GET à l\'URL donnée. Utilisez \$httpAddHeader avant pour définir les en-têtes. Utilisez \$httpResult pour lire la réponse.\n\nToutes les méthodes HTTP (GET, POST, PUT, PATCH, DELETE) suivent le même schéma.';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      'Ajoute un en-tête à la prochaine requête HTTP. Les en-têtes s\'accumulent jusqu\'au prochain \$httpGet/\$httpPost/etc.\n\nUtilisation : \$httpAddHeader[Authorization;Bearer token123]';

  @override
  String get bdfd_docs_desc_httpresult =>
      'Retourne le corps de la dernière réponse HTTP. Passez optionnellement un chemin JSON pour extraire un champ.\n\nUtilisation : \$httpResult[] pour le corps complet, ou \$httpResult[data.name] pour un champ imbriqué.';

  @override
  String get done => 'Terminé';

  @override
  String get cmd_simple_actions_title => 'Actions simplifiées';

  @override
  String get cmd_simple_actions_desc =>
      'Sélectionnez ce que la commande doit faire. Les options sont générées automatiquement.';

  @override
  String get cmd_simple_group_moderation_title => 'Modération';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Actions de modération et de gestion des membres avec options guidées.';

  @override
  String get cmd_simple_group_messages_title => 'Messages';

  @override
  String get cmd_simple_group_messages_desc =>
      'Actions liées aux messages et au salon courant.';

  @override
  String get cmd_simple_group_utility_title => 'Utilitaires';

  @override
  String get cmd_simple_group_utility_desc =>
      'Fonctions utiles comme les invitations et les sondages.';

  @override
  String get cmd_simple_action_delete => 'Supprimer des messages';

  @override
  String get cmd_simple_action_delete_desc =>
      'Supprime des messages dans le salon courant (option /count).';

  @override
  String get cmd_simple_action_kick => 'Expulser un utilisateur';

  @override
  String get cmd_simple_action_kick_desc =>
      'Expulse le /user sélectionné du serveur.';

  @override
  String get cmd_simple_action_ban => 'Bannir un utilisateur';

  @override
  String get cmd_simple_action_ban_desc =>
      'Bannit le /user sélectionné du serveur.';

  @override
  String get cmd_simple_action_unban => 'Débannir un utilisateur';

  @override
  String get cmd_simple_action_unban_desc =>
      'Débannit un utilisateur via une chaîne /user_id.';

  @override
  String get cmd_simple_action_mute => 'Rendre muet un utilisateur';

  @override
  String get cmd_simple_action_mute_desc =>
      'Rend temporairement muet le /user sélectionné.';

  @override
  String get cmd_simple_action_unmute => 'Retirer le mute';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Retire le timeout du /user sélectionné.';

  @override
  String get cmd_simple_action_add_role => 'Ajouter un rôle';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Attribue le /role sélectionné au /user sélectionné.';

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
  String get cmd_simple_action_pin => 'Épingler un message';

  @override
  String get cmd_simple_action_pin_desc =>
      'Épingle un message du salon courant via /message_id.';

  @override
  String get cmd_simple_action_unpin => 'Désépingler un message';

  @override
  String get cmd_simple_action_unpin_desc =>
      'Désépingle un message du salon courant via /message_id.';

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
  String get cmd_simple_action_send_message_label => 'Message de l’action';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Message envoyé par l’action Send Message';

  @override
  String get cmd_simple_execution_title => 'Réglages d’exécution';

  @override
  String get cmd_simple_execution_desc =>
      'Affinez les actions générées sans quitter le mode simplifié.';

  @override
  String get cmd_simple_action_reason_label => 'Raison du log d’audit';

  @override
  String get cmd_simple_action_reason_hint =>
      'Raison optionnelle partagée par les actions de modération';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Nombre par défaut à supprimer';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Utilisé si /count n’est pas fourni';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Jours de messages à supprimer au ban';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      'De 0 à 7 jours de messages récents';

  @override
  String get cmd_simple_action_mute_duration_label => 'Durée du mute';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Exemples : 10m, 2h, 1d, ou secondes brutes';

  @override
  String get cmd_simple_generated_options => 'Options de commande générées';

  @override
  String get cmd_simple_generated_none =>
      'Aucune option générée pour le moment. Sélectionnez au moins une action.';

  @override
  String get cmd_simple_option_user => '/user (Utilisateur)';

  @override
  String get cmd_simple_option_role => '/role (Rôle)';

  @override
  String get cmd_simple_option_count => '/count (Entier)';

  @override
  String get cmd_simple_option_user_id => '/user_id (Texte)';

  @override
  String get cmd_simple_option_message_id => '/message_id (Texte)';

  @override
  String get cmd_simple_option_channel => '/channel (Salon)';

  @override
  String get cmd_simple_option_question => '/question (Texte)';

  @override
  String get cmd_simple_option_user_desc => 'Utilisateur ciblé';

  @override
  String get cmd_simple_option_role_desc => 'Rôle ciblé';

  @override
  String get cmd_simple_option_count_desc => 'Nombre de messages à supprimer';

  @override
  String get cmd_simple_option_user_id_desc => 'ID utilisateur à débannir';

  @override
  String get cmd_simple_option_message_id_desc => 'ID du message ciblé';

  @override
  String get cmd_simple_option_channel_desc =>
      'Salon optionnel pour créer l’invitation';

  @override
  String get cmd_simple_option_question_desc => 'Question du sondage';

  @override
  String get cmd_simple_invite_settings_title => 'Réglages de l’invitation';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Valeurs par défaut utilisées par l’action Create Invite générée.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'Expiration de l’invitation (secondes)';

  @override
  String get cmd_simple_invite_max_age_hint =>
      '0 pour aucune expiration, jusqu’à 604800';

  @override
  String get cmd_simple_invite_max_uses_label => 'Nombre max d’utilisations';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 pour illimité';

  @override
  String get cmd_simple_invite_temporary_label => 'Adhésion temporaire';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Le membre est retiré s’il quitte avant de recevoir un rôle.';

  @override
  String get cmd_simple_invite_unique_label => 'Forcer une invitation unique';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Crée toujours une nouvelle invitation au lieu d’en réutiliser une.';

  @override
  String get cmd_simple_poll_settings_title => 'Réglages du sondage';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Valeurs par défaut utilisées par l’action Create Poll générée.';

  @override
  String get cmd_simple_poll_answers_label => 'Réponses du sondage';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Une réponse par ligne, ou séparées par des virgules. Minimum 2, maximum 10.';

  @override
  String get cmd_simple_poll_duration_label => 'Durée du sondage (heures)';

  @override
  String get cmd_simple_poll_duration_hint => 'De 1 à 168 heures';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Autoriser plusieurs réponses';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Les utilisateurs peuvent sélectionner plus d’un choix.';

  @override
  String get cmd_simple_response_title => 'Réponse finale';

  @override
  String get cmd_simple_response_desc =>
      'Message renvoyé à l’utilisateur après l’exécution des actions.';

  @override
  String get cmd_simple_response_visibility_label => 'Visibilité de la réponse';

  @override
  String get cmd_simple_response_visibility_public => 'Publique';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Éphémère';

  @override
  String get cmd_simple_response_hint => 'Terminé ✅';

  @override
  String get cmd_simple_response_embeds_title => 'Embeds de réponse';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Embeds optionnels envoyés avec la réponse finale.';

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
  String get cmd_simple_invite_max_age_invalid =>
      'L’expiration de l’invitation doit être un nombre entre 0 et 604800 secondes.';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Le nombre max d’utilisations doit être un nombre entre 0 et 1000000.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Le sondage doit contenir entre 2 et 10 réponses non vides.';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'La durée du sondage doit être un nombre entre 1 et 168 heures.';

  @override
  String get cmd_simple_send_message_required =>
      'Veuillez renseigner le message de l’action avant de sauvegarder.';

  @override
  String get support_card_title => 'Support & Communauté';

  @override
  String get support_card_desc =>
      'Une question, un bug, une suggestion ? Venez discuter avec l’équipe et la communauté.';

  @override
  String get support_join_discord => 'Rejoindre le serveur Discord';

  @override
  String get support_discord_badge => 'Support officiel';

  @override
  String get home_empty_support_hint => 'Besoin d’aide pour commencer ?';

  @override
  String get home_empty_support_btn => 'Rejoindre notre Discord';

  @override
  String get error_invalid_count => 'Le nombre doit être supérieur à 0.';

  @override
  String get error_invalid_channel_type =>
      'Le salon n’est pas un salon textuel.';

  @override
  String get error_network_timeout => 'L’action a expiré. Veuillez réessayer.';

  @override
  String get error_delete_messages_failed =>
      'Échec de la suppression des messages.';

  @override
  String get doc_center_title => 'Centre de documentation';

  @override
  String get doc_center_search_hint =>
      'Rechercher des commandes, workflows, variables, actions, intents ou exemples...';

  @override
  String get doc_center_clear_search => 'Effacer la recherche';

  @override
  String get doc_center_empty =>
      'Aucune entrée de documentation ne correspond à votre recherche.';

  @override
  String get doc_kind_all => 'Tout';

  @override
  String get doc_kind_event => 'Événement';

  @override
  String get doc_kind_action => 'Action';

  @override
  String get doc_kind_template => 'Template';

  @override
  String get doc_kind_runtime => 'Runtime';

  @override
  String get doc_required_intents => 'Intents requis';

  @override
  String get doc_available_variables => 'Variables disponibles';

  @override
  String get doc_example => 'Exemple';

  @override
  String get doc_common_section_best_use_cases => 'Cas d’usage recommandés';

  @override
  String get doc_common_section_important_notes => 'Points importants';

  @override
  String get doc_template_variables_title => 'Variables de template';

  @override
  String get doc_template_variables_subtitle =>
      'Comment les placeholders dynamiques sont résolus.';

  @override
  String get doc_template_variables_summary =>
      'Le runtime résout les placeholders selon le contexte courant (événement/interaction), les arguments de workflow et les variables globales.';

  @override
  String get doc_template_variables_section_sources_title =>
      'Sources de variables';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'Variables de commande : commandName, commandId, commandType, target.*, opts.*.';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'Variables d’événement : event.*, message.*, reaction.*, voice.*, role.*, etc.';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'Variables de workflow : workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'Variables globales : global.<key>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'Sorties d’actions : action.<key> quand disponibles.';

  @override
  String get doc_template_variables_section_builtin_title =>
      'Variables builtin de commande';

  @override
  String get doc_template_variables_section_types_title => 'Types de commande';

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
  String get doc_template_variables_section_fallbacks_title =>
      'Fallbacks et chemins';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'Utilisez ((opts.user|userName)) pour fallback si une option est absente.';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'Utilisez la syntaxe JSONPath sur les sorties d’actions : ((myHttp.body.\$.data[0].id)) ; les tableaux et objets restent manipulables.';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'Les fonctions length(...), join(...), formatEach(...), et embedFields(...) sont aussi supportées ; une variable inconnue reste résolue en chaîne vide.';

  @override
  String doc_template_variables_example(String name, String score) {
    return 'Bonjour ((target.user.username|userName))\nJoueurs : ((join(scores.items.\$, \", \")))\nFields JSON : ((embedFields(scores.items.\$, \"\'$name\'\", \"\'$score\'\", true)))';
  }

  @override
  String get doc_template_functions_title => 'Fonctions de template';

  @override
  String get doc_template_functions_subtitle =>
      'Transformer et comparer des données dans les expressions ((...)).';

  @override
  String get doc_template_functions_summary =>
      'Les fonctions de template servent à normaliser du texte, manipuler des tableaux, formater des sorties et ajouter un peu d’aléatoire.';

  @override
  String get doc_template_functions_section_string_title => 'Helpers texte';

  @override
  String get doc_template_functions_section_string_l1 =>
      'lowercase(source) / lower(source) : convertit en minuscules.';

  @override
  String get doc_template_functions_section_string_l2 =>
      'uppercase(source) / upper(source) : convertit en majuscules.';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(source) : supprime les espaces au début et à la fin.';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(source, search, replacement) et contains(source, needle) pour remplacer et tester.';

  @override
  String get doc_template_functions_section_array_title =>
      'Helpers tableaux et agrégats';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(source), at(source, index), first(source), last(source).';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(source, start, end?) et join(source, separator).';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(source) : additionne les valeurs numériques et ignore le reste.';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) et embedFields(...) formatent des tableaux d’objets pour texte et embeds.';

  @override
  String get doc_template_functions_section_random_title =>
      'Helpers aléatoires';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() et random() : renvoient \"true\" ou \"\" pour les branches conditionnelles.';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) et randomint(min, max).';

  @override
  String get doc_template_functions_section_notes_title => 'Points importants';

  @override
  String get doc_template_functions_section_notes_l1 =>
      'Les noms de fonctions sont insensibles à la casse.';

  @override
  String get doc_template_functions_section_notes_l2 =>
      'Fonction inconnue ou arguments invalides : rendu en chaîne vide.';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'Utilisez les fallbacks avec | au niveau racine : ((replace(name, \"_\", \" \")|Inconnu)).';

  @override
  String get doc_template_functions_section_notes_l4 =>
      'Les tableaux et objets renvoyés sont sérialisés en texte JSON.';

  @override
  String get doc_template_functions_example =>
      'Normalisé : ((uppercase(trim(userName))))\nRole admin : ((contains(userRole, \"admin\")))\nMeilleur score : ((first(scores.\$)))\nScore total : ((sum(scores.\$)))';

  @override
  String get doc_template_advanced_variables_title =>
      'Variables de template avancees';

  @override
  String get doc_template_advanced_variables_subtitle =>
      'Cles runtime supplementaires disponibles selon le contexte.';

  @override
  String get doc_template_advanced_variables_summary =>
      'Ces cles sont generees a partir des payloads d\'interaction et des details runtime channel/guild/user, selon le type d\'event ou de commande.';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'Metadonnees d\'interaction';

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
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'Details channel et guild';

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
  String get doc_template_advanced_variables_section_aliases_title =>
      'Alias user et member';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      'Les alias user structures (user.id, user.username, user.tag, user.avatar, user.banner) sont disponibles dans de nombreux contextes de commande.';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.id est utile quand vous combinez contexte utilisateur et membre de serveur.';

  @override
  String get doc_template_advanced_variables_example =>
      'Type : ((interaction.kind))\nNb selection : ((interaction.values.count|0))\nOwner thread : ((channel.thread.ownerId|unknown))\nType payload guild : ((guild.kind|n/a))';

  @override
  String get doc_runtime_action_outputs_title => 'Sorties runtime des actions';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'Comment les resultKey d\'action sont exposes comme variables runtime.';

  @override
  String get doc_runtime_action_outputs_summary =>
      'La plupart des actions ecrivent une cle principale, et peuvent aussi exposer des champs prefixes sous action.<resultKey>.* selon l\'executor.';

  @override
  String get doc_runtime_action_outputs_section_patterns_title =>
      'Patterns de sortie';

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
  String get doc_runtime_action_outputs_section_common_fields_title =>
      'Champs de sortie frequents';

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
  String get doc_runtime_action_outputs_section_caveats_title =>
      'Points d\'attention';

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
  String get doc_runtime_action_outputs_example =>
      'Status : ((action.http.status|http.status|unknown))\nBody : ((action.http.body|http.body))\nSupprimes : ((cleanup.count|0))\nTotal : ((page.total|0))';

  @override
  String get doc_interaction_commands_title => 'Commandes d’interaction';

  @override
  String get doc_interaction_commands_subtitle =>
      'Comportement runtime des commandes slash, user et message.';

  @override
  String get doc_interaction_commands_summary =>
      'Les commandes applicatives sont exécutées via un chemin d’interaction commun, avec des variables runtime qui dépendent du type Discord.';

  @override
  String get doc_interaction_commands_section_execution_title =>
      'Modèle d’exécution';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'Les commandes slash, user et message passent toutes par des interactions de commande applicative.';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'Le runner associe les commandes par id Discord, puis valide le type stocké vs le type entrant.';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'Un mismatch de type est loggé en warning mais ne bloque pas l’exécution.';

  @override
  String get doc_interaction_commands_section_per_type_title =>
      'Variables par type';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput : opts.* pour les paramètres et sous-commandes.';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user : target.user.* et target.member.* quand disponibles.';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message : target.message.* incluant le contenu et l’id auteur quand résolus.';

  @override
  String get doc_interaction_commands_section_builtin_title =>
      'Variables builtin de commande';

  @override
  String get doc_interaction_commands_section_guidance_title =>
      'Recommandations d’écriture';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'Écrivez vos conditions avec commandType ou interaction.command.type.';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'Préférez la syntaxe de fallback pour partager un template entre slash et non-slash, et utilisez autocomplete.query dans les workflows dédiés à l’auto-complete.';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'Gardez des templates portables en évitant les variables propres aux events dans les workflows de commande ; l’auto-complete dynamique doit finir par respondWithAutocomplete.';

  @override
  String doc_interaction_commands_example(String name, String id) {
    return 'Workflow d’auto-complete :\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'$name\' value=\'$id\'';
  }

  @override
  String get doc_event_message_create_title => 'Événement : messageCreate';

  @override
  String get doc_event_message_create_subtitle =>
      'Déclenché pour chaque nouveau message créé.';

  @override
  String get doc_event_message_create_summary =>
      'Utilisez cet événement pour la modération, les pipelines de mots-clés, les auto-réponses, le parsing style commande et l’analytics.';

  @override
  String get doc_event_message_create_intent_1 => 'Guild Messages';

  @override
  String get doc_event_message_create_intent_2 => 'Message Content';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'Détecter des commandes tapées sans slash command.';

  @override
  String get doc_event_message_create_best_use_l2 =>
      'Appliquer des filtres anti-spam avant de répondre.';

  @override
  String get doc_event_message_create_best_use_l3 =>
      'Router vers des workflows réutilisables selon le premier mot ou la mention.';

  @override
  String get doc_event_message_create_notes_l1 =>
      'Si l’intent Message Content est désactivé, les conditions basées sur le contenu peuvent échouer.';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index] est basé sur les mots et limité par l’extraction runtime.';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBot aide à éviter les boucles entre bots.';

  @override
  String get doc_event_message_create_example =>
      'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nThen: runWorkflow -> ticket_manager entry=create';

  @override
  String get doc_runtime_execution_flow_title => 'Flux d’exécution runtime';

  @override
  String get doc_runtime_execution_flow_subtitle =>
      'Comment les workflows d’événement sont sélectionnés et exécutés.';

  @override
  String get doc_runtime_execution_flow_summary =>
      'Quand un événement arrive, le runtime associe les workflows via eventTrigger.event puis exécute les actions avec les variables de contexte.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'Pipeline';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) Réception de l’événement gateway.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) Construction de la map de variables de contexte.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) Matching des workflows par nom d’événement.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) Fusion des variables globales.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) Exécution séquentielle des actions avec conditions.';

  @override
  String get doc_runtime_execution_flow_section_parity_title =>
      'Règle de parité';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      'Les variables doivent être identiques entre runtime local app et runtime runner.';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      'Utilisez les mêmes noms de variables dans les conditions pour rester portable.';

  @override
  String get template_gallery_title => 'Templates';

  @override
  String get template_gallery_subtitle =>
      'Démarrez rapidement votre bot avec un template prêt à l\'emploi.';

  @override
  String get template_gallery_apply => 'Utiliser ce template';

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return '$count commande(s) et $wCount workflow(s) ajoutés depuis le template.';
  }

  @override
  String template_gallery_apply_error(String error) {
    return 'Impossible d\'appliquer le template : $error';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count commande(s)';
  }

  @override
  String template_gallery_workflows_count(int count) {
    return '$count workflow(s)';
  }

  @override
  String get template_gallery_empty => 'Aucun template disponible.';

  @override
  String template_gallery_already_exists(String name) {
    return 'La commande \"$name\" existe déjà et a été ignorée.';
  }

  @override
  String get template_gallery_sync_warning =>
      'Commandes sauvegardées localement. Démarrez votre bot pour les enregistrer sur Discord.';

  @override
  String get template_welcome_name => 'Bot d\'accueil';

  @override
  String get template_welcome_description =>
      'Accueillez les nouveaux membres, dites bonjour et affichez les infos du serveur.';

  @override
  String get template_moderation_name => 'Bot de modération';

  @override
  String get template_moderation_description =>
      'Bannir, expulser, rendre muet et supprimer des messages.';

  @override
  String get template_utility_name => 'Bot utilitaire';

  @override
  String get template_utility_description =>
      'Ping, affichage d\'avatar et commande say.';

  @override
  String get template_fun_name => 'Bot fun';

  @override
  String get template_fun_description =>
      'Pile ou face, sondages et boule magique.';

  @override
  String get dashboard_title => 'Dashboard';

  @override
  String get dashboard_no_data =>
      'Aucune donnée d\'utilisation. Lancez votre bot pour commencer le suivi.';

  @override
  String get dashboard_total => 'Total commandes';

  @override
  String get dashboard_period_24h => 'Dernières 24h';

  @override
  String get dashboard_period_7d => '7 derniers jours';

  @override
  String get dashboard_period_30d => '30 derniers jours';

  @override
  String get dashboard_top_commands => 'Top commandes';

  @override
  String get dashboard_top_locales => 'Top localisations';

  @override
  String get dashboard_execution_health_title => 'Santé des exécutions';

  @override
  String get dashboard_failed_commands => 'Échecs';

  @override
  String get dashboard_error_rate => 'Taux d\'erreur';

  @override
  String get dashboard_p50_latency => 'Latence p50';

  @override
  String get dashboard_p95_latency => 'Latence p95';

  @override
  String get dashboard_premium_analytics_title => 'Analytics Premium';

  @override
  String get dashboard_premium_analytics_desc =>
      'Débloquez le taux d\'erreur, les percentiles de latence et les insights de localisation.';

  @override
  String get dashboard_timeline => 'Utilisation dans le temps';

  @override
  String dashboard_executions(int count) {
    return '$count exécutions';
  }

  @override
  String dashboard_selected_period_total(int count) {
    return '$count sur la période sélectionnée';
  }

  @override
  String get dashboard_loading => 'Chargement des stats...';

  @override
  String dashboard_error(String error) {
    return 'Impossible de charger les stats : $error';
  }

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Actualiser les serveurs d\'exécution';

  @override
  String get dashboard_requires_runner =>
      'Connectez un runner pour voir les statistiques d\'utilisation.';

  @override
  String get dashboard_single_runner_notice =>
      'Les stats affichées proviennent uniquement du runner actuellement configuré. Si vous utilisez plusieurs runners, cette vue peut être incomplète.';

  @override
  String runner_source_label(String name) {
    return 'Runner : $name';
  }

  @override
  String get runner_source_local => 'Local';

  @override
  String get runner_source_all => 'Tous les runners';

  @override
  String get runner_select_source => 'Sélectionner le runner';

  @override
  String logs_runner_source(String name) {
    return 'Logs de : $name';
  }

  @override
  String get settings_version_title => 'Version';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String get settings_runner_not_connected => 'Non connecté';

  @override
  String get premium_card_title => 'Supprimer les pubs';

  @override
  String get premium_card_desc =>
      'Abonnez-vous pour supprimer toutes les publicités et démarrer vos bots instantanément, sans aucune pop-up.';

  @override
  String get premium_card_button => 'Voir les offres';

  @override
  String get premium_active_title => 'Premium actif';

  @override
  String get premium_active_desc =>
      'Merci pour votre soutien ! Toutes les publicités sont désactivées.';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_subtitle =>
      'Choisissez une offre pour débloquer toutes les fonctionnalités premium.';

  @override
  String get subscription_plan_label => 'Premium Basique';

  @override
  String get subscription_plan_desc =>
      'Supprime les pubs et accède à toutes les fonctionnalités premium actuelles et à venir.';

  @override
  String get subscription_success =>
      'Bienvenue dans Premium ! Toutes les publicités ont été supprimées.';

  @override
  String get subscription_manage => 'Gérer l\'abonnement';

  @override
  String get subscription_active_label => 'Offre active :';

  @override
  String get subscription_active_annual => 'Premium — Annuel';

  @override
  String get subscription_active_monthly => 'Premium — Mensuel';

  @override
  String get subscription_benefit_no_ads =>
      'Aucune pub dans toute l\'application';

  @override
  String get subscription_benefit_fast_start =>
      'Bots démarrent instantanément, sans pop-up';

  @override
  String get subscription_benefit_support =>
      'Soutenez le développement indépendant';

  @override
  String get subscription_feature_coming_soon => 'Bientôt disponible';

  @override
  String get subscription_feature_no_ads_title => 'Sans publicité';

  @override
  String get subscription_feature_no_ads_desc =>
      'Supprime toutes les insertions publicitaires dans l\'application.';

  @override
  String get subscription_feature_instant_start_title => 'Démarrage instantané';

  @override
  String get subscription_feature_instant_start_desc =>
      'Lance les bots immédiatement sans interruption publicitaire.';

  @override
  String get subscription_feature_analytics_title => 'Analytique avancée';

  @override
  String get subscription_feature_analytics_desc =>
      'Accédez au taux d\'erreur, aux percentiles de latence et aux insights de locale.';

  @override
  String get subscription_feature_scheduler_title => 'Déclencheurs planifiés';

  @override
  String get subscription_feature_scheduler_desc =>
      'Exécute des workflows automatiquement toutes les X minutes (jusqu\'à 10 actifs).';

  @override
  String get subscription_feature_webhooks_title => 'Webhooks entrants';

  @override
  String get subscription_feature_webhooks_desc =>
      'Crée des endpoints webhook sécurisés et route les appels vers les workflows.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Replay visuel de debug';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Enregistre et rejoue les actions de commande étape par étape.';

  @override
  String get subscription_feature_auto_sharding_title => 'Sharding automatique';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Répartit la charge des gros bots entre plusieurs shards.';

  @override
  String get subscription_feature_auto_restart_title =>
      'Redémarrage automatique';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Redémarre automatiquement le bot quand un redémarrage complet est requis.';

  @override
  String get subscription_annual_title => 'Annuel';

  @override
  String get subscription_monthly_title => 'Mensuel';

  @override
  String get subscription_per_year => 'par an';

  @override
  String get subscription_per_month => 'par mois';

  @override
  String get subscription_save_badge => '-67%';

  @override
  String get subscription_restore => 'Restaurer les achats';

  @override
  String get subscription_terms => 'Conditions d\'utilisation';

  @override
  String get subscription_privacy => 'Politique de confidentialité';

  @override
  String get subscription_error =>
      'L\'achat n\'a pas pu être finalisé. Veuillez réessayer.';

  @override
  String get subscription_error_store_unavailable =>
      'L\'App Store est temporairement indisponible. Veuillez réessayer dans un instant.';

  @override
  String get subscription_error_product_unavailable =>
      'Cette offre est actuellement indisponible. Veuillez réessayer plus tard.';

  @override
  String get subscription_error_purchase_start_failed =>
      'L\'achat n\'a pas pu démarrer. Veuillez réessayer.';

  @override
  String get subscription_restored => 'Abonnement restauré avec succès !';

  @override
  String get subscription_restore_not_found => 'Aucun abonnement actif trouvé.';

  @override
  String get subscription_not_available_on_platform =>
      'Les abonnements sont actuellement disponibles uniquement sur mobile.';

  @override
  String get subscription_unavailable_platform =>
      'Non disponible sur cette plateforme.';

  @override
  String get action_name_addThreadMember => 'Ajouter un membre au fil';

  @override
  String get action_name_removeThreadMember => 'Retirer un membre du fil';

  @override
  String get template_gallery_remove_title => 'Supprimer le modèle';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Rien à supprimer pour $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Voulez-vous vraiment supprimer toutes les commandes et workflows de ce modèle ?';

  @override
  String get template_gallery_removed =>
      'Commandes et workflows du modèle supprimés.';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_ok => 'OK';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_remove => 'Supprimer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_apply => 'Appliquer';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_back => 'Retour';

  @override
  String get common_next => 'Suivant';

  @override
  String get common_enabled => 'Activé';

  @override
  String get common_import => 'Importer';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_move_up => 'Déplacer vers le haut';

  @override
  String get common_move_down => 'Déplacer vers le bas';

  @override
  String get common_name => 'Nom';

  @override
  String get common_value => 'Valeur';

  @override
  String get common_key => 'Clé';

  @override
  String get common_type => 'Type';

  @override
  String get common_required => 'Requis';

  @override
  String get common_description => 'Description';

  @override
  String get common_default => 'Défaut';

  @override
  String get common_clear => 'Effacer';

  @override
  String get common_all => 'Tout';

  @override
  String get common_pick => 'Choisir';

  @override
  String get common_add_argument => 'Ajouter un argument';

  @override
  String get common_add_option => 'Ajouter une option';

  @override
  String get common_refresh => 'Actualiser';

  @override
  String get common_refresh_workflows => 'Actualiser les workflows';

  @override
  String get common_search => 'Rechercher';

  @override
  String get common_workflow => 'Workflow';

  @override
  String get common_static_options => 'Options statiques';

  @override
  String get common_manage_workflows => 'Gérer les workflows';

  @override
  String get doc_event_reaction_add_title => 'Événement : messageReactionAdd';

  @override
  String get doc_event_reaction_add_subtitle =>
      'Déclenché quand un utilisateur ajoute une réaction à un message.';

  @override
  String get doc_event_reaction_add_summary =>
      'Idéal pour une UX type bouton sans composants, les systèmes de vote, les menus de rôles et les approbations légères.';

  @override
  String get doc_event_reaction_add_intent => 'Guild Message Reactions';

  @override
  String get doc_event_reaction_add_best_use_l1 =>
      'Flux d\'approbation/rejet avec des emojis unicode.';

  @override
  String get doc_event_reaction_add_best_use_l2 =>
      'Sondages multi-étapes utilisant des IDs d\'emojis personnalisés.';

  @override
  String get doc_event_reaction_add_best_use_l3 =>
      'Signaux de modération rapides depuis les salons du staff.';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.id peut être vide pour les emojis unicode.';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      'Utilisez reaction.emoji.name pour une correspondance générique.';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      'Utilisez reaction.emoji.id pour une correspondance stricte d\'emojis personnalisés.';

  @override
  String get doc_event_reaction_add_example =>
      'Guard : ((reaction.emoji.name)) equals ✅\nAction : addRole -> user=((userId)) role=((global.approvedRoleId))';

  @override
  String get doc_event_poll_vote_add_title => 'Événement : messagePollVoteAdd';

  @override
  String get doc_event_poll_vote_add_subtitle =>
      'Déclenché quand un utilisateur vote sur une réponse de sondage.';

  @override
  String get doc_event_poll_vote_add_summary =>
      'Utile pour le suivi des scores, l\'attribution de rôles par option de sondage et le traitement des enquêtes.';

  @override
  String get doc_event_poll_vote_add_intent => 'Guild Messages';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      'Associer chaque identifiant de réponse à une branche d\'action différente.';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'Suivre la participation aux sondages par salon ou groupe d\'utilisateurs.';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.id est la clé la plus stable pour le routage.';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.question est optionnel et peut être vide selon le payload.';

  @override
  String get doc_event_voice_state_update_title =>
      'Événement : voiceStateUpdate';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'Déclenché quand l\'état vocal change pour un utilisateur.';

  @override
  String get doc_event_voice_state_update_summary =>
      'Utilisez ceci pour la modération automatique dans les salons vocaux, le suivi de présence et l\'automatisation vocale.';

  @override
  String get doc_event_voice_state_update_intent => 'Guilds';

  @override
  String get doc_event_voice_state_update_section_title =>
      'Automatisations typiques';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      'Détecter les violations de politique de sourdine/désactivation du son.';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'Envoyer un message de bienvenue à la connexion vocale pour les salons de support.';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'Journaliser les patterns d\'arrivée/départ via les changements de salon.';

  @override
  String get doc_event_user_update_title => 'Événement : userUpdate';

  @override
  String get doc_event_user_update_subtitle =>
      'Déclenché quand les données du profil utilisateur changent.';

  @override
  String get doc_event_user_update_summary =>
      'Utile pour l\'audit des changements de profil et les déclencheurs basés sur le pseudo/avatar.';

  @override
  String get doc_event_user_update_notes_l1 =>
      'Pas de contexte de salon pour cet événement dans la plupart des cas.';

  @override
  String get doc_event_user_update_notes_l2 =>
      'Privilégiez la journalisation + alertes de modération plutôt que les réponses directes à l\'utilisateur.';

  @override
  String get doc_event_audit_log_create_title =>
      'Événement : guildAuditLogCreate';

  @override
  String get doc_event_audit_log_create_subtitle =>
      'Déclenché quand une nouvelle entrée du journal d\'audit est créée.';

  @override
  String get doc_event_audit_log_create_summary =>
      'Événement à haute valeur pour la surveillance de sécurité administrative.';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      'Alerter le staff sur les actions sensibles (suppression de rôle, création de webhook, ban, etc.).';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      'Router des types d\'actions spécifiques vers des workflows dédiés.';

  @override
  String get doc_action_stop_unless_title => 'Action : stopUnless';

  @override
  String get doc_action_stop_unless_subtitle =>
      'Clause de garde qui arrête le workflow quand la condition échoue.';

  @override
  String get doc_action_stop_unless_summary =>
      'Utilisez-le en haut des workflows pour éviter les actions inutiles quand le contexte ne correspond pas.';

  @override
  String get doc_action_stop_unless_section_operators => 'Opérateurs supportés';

  @override
  String get doc_action_stop_unless_operators_l1 =>
      'equals, notEquals, contains, notContains, startsWith, endsWith';

  @override
  String get doc_action_stop_unless_operators_l2 =>
      'greaterThan, lessThan, greaterOrEqual, lessOrEqual';

  @override
  String get doc_action_stop_unless_operators_l3 =>
      'isEmpty, isNotEmpty, matches';

  @override
  String get doc_action_stop_unless_section_format =>
      'Format de la variable de condition';

  @override
  String get doc_action_stop_unless_format_l1 =>
      'Vous pouvez utiliser des clés brutes : message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'Vous pouvez utiliser des variables encapsulées : ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 =>
      'Les deux sont résolus par le runtime.';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅';

  @override
  String get doc_action_if_block_title => 'Action : ifBlock';

  @override
  String get doc_action_if_block_subtitle =>
      'Branche l\'exécution entre les listes d\'actions imbriquées THEN, ELSE IF et ELSE.';

  @override
  String get doc_action_if_block_summary =>
      'Utilisez ceci pour garder un seul workflow tout en gérant plusieurs résultats selon l\'état d\'exécution.';

  @override
  String get doc_action_if_block_section_execution => 'Modèle d\'exécution';

  @override
  String get doc_action_if_block_execution_l1 =>
      'La condition est évaluée une seule fois.';

  @override
  String get doc_action_if_block_execution_l2 =>
      'La première branche correspondante s\'exécute : THEN, puis les blocs ELSE IF dans l\'ordre, puis ELSE.';

  @override
  String get doc_action_if_block_execution_l3 =>
      'Les actions imbriquées peuvent inclure runWorkflow, des appels API et des réponses d\'interaction.';

  @override
  String get doc_action_run_workflow_title => 'Action : runWorkflow';

  @override
  String get doc_action_run_workflow_subtitle =>
      'Appelle un autre workflow avec un point d\'entrée et des arguments.';

  @override
  String get doc_action_run_workflow_summary =>
      'Primitive de composition pour découper la logique métier en unités réutilisables.';

  @override
  String get doc_action_run_workflow_section_practices => 'Bonnes pratiques';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'Gardez le workflow principal léger et déléguez aux workflows de domaine.';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      'Passez des arguments explicites au lieu de dépendre des globales implicites.';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'Utilisez les points d\'entrée pour modéliser des sous-routines (create, close, assign, escalate).';

  @override
  String get doc_action_http_request_title => 'Action : httpRequest';

  @override
  String get doc_action_http_request_subtitle =>
      'Exécute un appel HTTP externe dans un workflow.';

  @override
  String get doc_action_http_request_summary =>
      'Utilisez ceci pour les webhooks, APIs internes, services de modération, endpoints IA et intégrations.';

  @override
  String get doc_action_http_request_section_checklist =>
      'Checklist de fiabilité';

  @override
  String get doc_action_http_request_checklist_l1 =>
      'Définissez un timeout et des retries explicites dans votre couche de services quand c\'est possible.';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'Stockez les clés API dans les globales ou un backend sécurisé, ne codez jamais les tokens en dur.';

  @override
  String get doc_action_http_request_checklist_l3 =>
      'Validez le code de statut et le corps de la réponse avant les actions suivantes.';

  @override
  String get embed_color_picker_title => 'Choisir la couleur de l\'embed';

  @override
  String get embed_delete_title => 'Supprimer l\'embed';

  @override
  String get embed_delete_confirm => 'Cet embed sera supprimé. Continuer ?';

  @override
  String get embed_field_delete_title => 'Supprimer le champ';

  @override
  String get embed_field_delete_confirm =>
      'Ce champ sera supprimé de l\'embed. Continuer ?';

  @override
  String embed_response_header(int count, int max) {
    return 'Embeds de réponse ($count/$max)';
  }

  @override
  String get embed_add_tooltip => 'Ajouter un embed';

  @override
  String embed_empty_message(int max) {
    return 'Aucun embed. Vous pouvez en ajouter jusqu\'à $max.';
  }

  @override
  String embed_number(int index) {
    return 'Embed #$index';
  }

  @override
  String get embed_label_title => 'Titre';

  @override
  String get embed_label_url => 'URL';

  @override
  String get embed_label_timestamp => 'Horodatage (ISO8601)';

  @override
  String get embed_label_color => 'Couleur (int ou #hex)';

  @override
  String get embed_section_footer => 'Pied de page';

  @override
  String get embed_label_footer_text => 'Texte du pied de page';

  @override
  String get embed_label_footer_icon => 'URL icône du pied de page';

  @override
  String get embed_section_author => 'Auteur';

  @override
  String get embed_label_author_name => 'Nom de l\'auteur';

  @override
  String get embed_label_author_url => 'URL de l\'auteur';

  @override
  String get embed_label_author_icon => 'URL icône de l\'auteur';

  @override
  String get embed_section_media => 'Médias';

  @override
  String get embed_label_image_url => 'URL de l\'image';

  @override
  String get embed_label_thumbnail_url => 'URL de la miniature';

  @override
  String embed_fields_header(int count) {
    return 'Champs ($count/25)';
  }

  @override
  String get embed_fields_empty => 'Aucun champ.';

  @override
  String embed_field_number(int index) {
    return 'Champ #$index';
  }

  @override
  String get embed_label_inline => 'En ligne';

  @override
  String get embed_label_dynamic_fields => 'Modèle de champs dynamiques';

  @override
  String get component_remove_title => 'Supprimer le composant';

  @override
  String get component_remove_confirm =>
      'Ce composant sera supprimé de la mise en page. Continuer ?';

  @override
  String get component_label => 'Libellé';

  @override
  String get component_style => 'Style';

  @override
  String get component_url => 'URL';

  @override
  String get component_custom_id_required => 'ID personnalisé *';

  @override
  String get component_validation_required => 'Requis';

  @override
  String get component_workflow_optional => 'Appeler un workflow (optionnel)';

  @override
  String get component_workflow_click_hint =>
      'Nom du workflow sauvegardé à exécuter au clic';

  @override
  String get component_workflow_select_hint =>
      'Nom du workflow sauvegardé à exécuter à la sélection';

  @override
  String get component_custom_id => 'ID personnalisé';

  @override
  String get component_placeholder => 'Texte indicatif';

  @override
  String get component_options => 'Options';

  @override
  String get component_markdown_content => 'Contenu Markdown';

  @override
  String get component_visible_divider => 'Ligne de séparation visible';

  @override
  String get component_spacing_small => 'Espacement réduit';

  @override
  String get component_spacing_large => 'Espacement large';

  @override
  String get component_section_text_displays => 'Affichages de texte';

  @override
  String get component_add_text_display => 'Ajouter un affichage texte';

  @override
  String get component_section_accessory => 'Nœud accessoire (optionnel)';

  @override
  String get component_accent_color =>
      'Couleur d\'accentuation (Hex, ex. FF0000)';

  @override
  String get component_pick_accent_color =>
      'Choisir la couleur d\'accentuation';

  @override
  String get component_add_child => 'Ajouter un composant enfant';

  @override
  String get component_checked_by_default => 'Coché par défaut';

  @override
  String get component_add_radio_option => 'Ajouter une option radio';

  @override
  String get component_add_media_item => 'Ajouter un élément média';

  @override
  String get component_not_implemented => 'Éditeur pas encore implémenté';

  @override
  String get component_choose_color => 'Choisir la couleur';

  @override
  String get component_label_title => 'Titre du libellé';

  @override
  String get component_workflow_args_title => 'Arguments d\'appel du workflow';

  @override
  String get component_workflow_args_hint =>
      'Exemple : ticketId = ((opts.ticket))';

  @override
  String get autocomplete_workflow_label => 'Workflow d\'autocomplétion';

  @override
  String get autocomplete_loading => 'Chargement des workflows…';

  @override
  String get autocomplete_no_workflows => 'Aucun workflow sauvegardé trouvé';

  @override
  String get autocomplete_select_workflow =>
      'Sélectionnez un workflow sauvegardé';

  @override
  String get autocomplete_type_name => 'Ou tapez le nom du workflow';

  @override
  String get workflow_entry_point => 'Point d\'entrée';

  @override
  String get workflow_arguments_section => 'Arguments du workflow';

  @override
  String get hint_use_variables =>
      'Utilisez des variables/templates si nécessaire';

  @override
  String get autocomplete_dynamic => 'Autocomplétion dynamique';

  @override
  String get autocomplete_dynamic_desc =>
      'Résoudre les choix depuis un workflow au lieu de valeurs statiques.';

  @override
  String get autocomplete_filter_hint =>
      'Les suggestions sont filtrées selon ce que l\'utilisateur tape.';

  @override
  String get option_delete_title => 'Supprimer l\'option';

  @override
  String get option_delete_confirm =>
      'Cette option sera supprimée. Continuer ?';

  @override
  String get option_desc_required =>
      'Veuillez entrer une description pour l\'option';

  @override
  String get option_delete_argument_title => 'Supprimer l\'argument';

  @override
  String get option_delete_argument_confirm =>
      'Cet argument sera supprimé. Continuer ?';

  @override
  String option_static_label_n(int index) {
    return 'Libellé $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Valeur $index';
  }

  @override
  String get option_delete_choice_title => 'Supprimer l\'option';

  @override
  String get option_delete_choice_confirm =>
      'Ce choix sera supprimé. Continuer ?';

  @override
  String option_default_name(int index) {
    return 'Option $index';
  }

  @override
  String get option_min_value => 'Valeur min';

  @override
  String get option_max_value => 'Valeur max';

  @override
  String get option_add_localizations => 'Ajouter des localisations';

  @override
  String get option_select_language => 'Sélectionner la langue';

  @override
  String get option_delete_localization_title => 'Supprimer la localisation';

  @override
  String get option_delete_localization_confirm =>
      'Cette entrée de localisation sera supprimée. Continuer ?';

  @override
  String get option_localized_name => 'Nom localisé';

  @override
  String get option_localized_description => 'Description localisée';

  @override
  String option_choice_number(int index) {
    return 'Choix $index';
  }

  @override
  String get option_choice_delete_title => 'Supprimer le choix';

  @override
  String get option_choice_delete_confirm =>
      'Ce choix sera supprimé. Continuer ?';

  @override
  String get option_choice_name => 'Nom du choix';

  @override
  String get option_choice_value => 'Valeur du choix';

  @override
  String get option_add_choice => 'Ajouter un choix';

  @override
  String get option_subcommands => 'Sous-commandes';

  @override
  String get option_subcommand_options => 'Options de sous-commande';

  @override
  String get action_options_tooltip => 'Options de l\'action';

  @override
  String get action_remove_menu => 'Supprimer l\'action';

  @override
  String get action_order_tip =>
      'Astuce : utilisez les flèches pour changer l\'ordre des actions.';

  @override
  String get action_key_field => 'Clé d\'action';

  @override
  String get action_on_error => 'En cas d\'erreur';

  @override
  String get action_error_stop => 'Arrêter';

  @override
  String get action_error_continue => 'Continuer';

  @override
  String get action_advanced_settings => 'Paramètres avancés';

  @override
  String get action_status_enabled => 'Activé';

  @override
  String get action_status_disabled => 'Désactivé';

  @override
  String get action_remove_title => 'Supprimer l\'action';

  @override
  String get action_remove_confirm =>
      'Cette action sera supprimée du workflow. Continuer ?';

  @override
  String get action_store_results =>
      'Stocker les résultats dans les variables globales';

  @override
  String get action_http_test_button =>
      'Envoyer une requête test et détecter les routes';

  @override
  String get action_http_test_title => 'Résultats de la requête test';

  @override
  String action_http_status(int status) {
    return 'Statut : $status';
  }

  @override
  String action_http_paths_parsed(int count) {
    return '$count chemins analysés';
  }

  @override
  String get action_http_response_body => 'Corps de la réponse (brut) :';

  @override
  String get action_literal => 'Littéral';

  @override
  String get action_dynamic => 'Dynamique';

  @override
  String get action_add_else_if => 'Ajouter ELSE IF';

  @override
  String get action_remove_else_if => 'Supprimer ELSE IF';

  @override
  String get action_condition_variable => 'Variable de condition';

  @override
  String get action_condition_value => 'Valeur de condition';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index — actions';
  }

  @override
  String get action_expression => 'Expression';

  @override
  String action_edit_param(String name) {
    return 'Modifier $name';
  }

  @override
  String action_choose_param(String name) {
    return 'Choisir $name';
  }

  @override
  String get action_format_json => 'Formater le JSON';

  @override
  String get action_add_header => 'Ajouter un en-tête';

  @override
  String get action_clear_all => 'Tout effacer';

  @override
  String get action_refresh_keys => 'Actualiser les clés';

  @override
  String get action_manage_variable_keys => 'Gérer les clés de variables';

  @override
  String get validation_command_name_required =>
      'Veuillez entrer un nom de commande';

  @override
  String get validation_awaited_callback_local_only =>
      'Les callbacks attendus nécessitent une commande Legacy locale uniquement.';

  @override
  String validation_awaited_callback_length(int max) {
    return 'Le déclencheur de callback attendu doit contenir au maximum $max caractères';
  }

  @override
  String get validation_awaited_callback_format =>
      'Le callback attendu doit utiliser \$awaitedCommand[name;filter] ou \$awaitedCommandError[name].';

  @override
  String validation_command_name_length(int max) {
    return 'Le nom de commande doit contenir au maximum $max caractères';
  }

  @override
  String get validation_command_name_no_spaces =>
      'Le nom de commande ne peut pas contenir d\'espaces';

  @override
  String get validation_command_name_invalid_chars =>
      'Le nom de commande ne peut contenir que des lettres, chiffres et underscores';

  @override
  String get validation_command_name_no_underscore =>
      'Le nom de commande ne peut pas commencer par un underscore';

  @override
  String get validation_command_name_no_exclamation =>
      'Le nom de commande ne peut pas commencer par un point d\'exclamation';

  @override
  String get validation_command_name_no_slash =>
      'Le nom de commande ne peut pas commencer par un slash';

  @override
  String get validation_command_name_no_hash =>
      'Le nom de commande ne peut pas commencer par un dièse';

  @override
  String get validation_command_name_no_at =>
      'Le nom de commande ne peut pas commencer par un arobase';

  @override
  String get validation_command_name_no_ampersand =>
      'Le nom de commande ne peut pas commencer par une esperluette';

  @override
  String get validation_command_name_no_percent =>
      'Le nom de commande ne peut pas commencer par un signe pourcent';

  @override
  String get validation_legacy_chat_input_only =>
      'Le mode legacy est disponible uniquement pour les commandes de saisie.';

  @override
  String get validation_modal_not_legacy =>
      'Les réponses modales ne sont pas supportées en mode commande legacy.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Les commandes legacy-only nécessitent que le mode legacy soit activé.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Le mode legacy-only ne peut être utilisé que pour les nouvelles commandes ou les commandes locales existantes.';

  @override
  String get validation_invalid_permissions =>
      'Champ de bits de permissions par défaut invalide. Utilisez un entier positif ou laissez vide.';

  @override
  String get scheduler_no_workflows =>
      'Créez au moins un workflow avant d\'ajouter un planning.';

  @override
  String get scheduler_add_title => 'Ajouter un planning';

  @override
  String get scheduler_edit_title => 'Modifier le planning';

  @override
  String get scheduler_label_hint => 'Libellé d\'affichage optionnel';

  @override
  String get scheduler_label_field => 'Libellé';

  @override
  String get scheduler_every_minutes => 'Toutes les (minutes)';

  @override
  String get scheduler_invalid_minutes =>
      'Les minutes doivent être supérieures à 0.';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Limite du planificateur atteinte ($limit).';
  }

  @override
  String scheduler_save_failed(String error) {
    return 'Échec de l\'enregistrement du planning : $error';
  }

  @override
  String get scheduler_delete_title => 'Supprimer le planning';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Supprimer le planning « $label » ?';
  }

  @override
  String get scheduler_page_title => 'Planificateur';

  @override
  String get scheduler_add_trigger => 'Ajouter un déclencheur';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Déclencheurs : $count$limit';
  }

  @override
  String get scheduler_empty => 'Aucun déclencheur planifié.';

  @override
  String get webhooks_no_workflows =>
      'Créez au moins un workflow avant d\'ajouter un webhook entrant.';

  @override
  String get webhooks_add_title => 'Ajouter un webhook entrant';

  @override
  String get webhooks_edit_title => 'Modifier le webhook entrant';

  @override
  String get webhooks_path_label => 'Chemin';

  @override
  String get webhooks_path_hint => 'orders/new';

  @override
  String get webhooks_target_label => 'Workflow cible';

  @override
  String get webhooks_secret_label => 'Secret du webhook';

  @override
  String get webhooks_generate => 'Générer';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Limite de webhooks entrants atteinte ($limit).';
  }

  @override
  String get webhooks_path_exists =>
      'Ce chemin existe déjà. Choisissez-en un autre.';

  @override
  String webhooks_save_failed(String error) {
    return 'Échec de l\'enregistrement du webhook entrant : $error';
  }

  @override
  String get webhooks_delete_title => 'Supprimer le webhook entrant ?';

  @override
  String webhooks_delete_confirm(String label) {
    return 'Supprimer « $label » ? Cette action est irréversible.';
  }

  @override
  String get webhooks_delete_confirm_no_label =>
      'Cette action est irréversible.';

  @override
  String get webhooks_runner_url_required =>
      'Configurez d\'abord une URL Runner pour copier l\'URL complète du webhook.';

  @override
  String get webhooks_missing_data =>
      'Le chemin ou le secret du webhook est manquant.';

  @override
  String get webhooks_copied => 'URL complète du webhook copiée.';

  @override
  String get webhooks_invalid_runner_url => 'L\'URL du Runner est invalide.';

  @override
  String get webhooks_page_title => 'Webhooks entrants';

  @override
  String get webhooks_add_action => 'Ajouter un webhook';

  @override
  String get webhooks_empty => 'Aucun webhook entrant.';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Workflow : $workflow';
  }

  @override
  String get webhooks_copy_url => 'Copier l\'URL';

  @override
  String get webhooks_copy_path => 'Copier le chemin';

  @override
  String get webhooks_copy_secret => 'Copier le secret';

  @override
  String get webhooks_actions => 'Actions';

  @override
  String get command_legacy_mode_title =>
      'Activer le mode legacy sur cette commande';

  @override
  String get command_legacy_mode_subtitle =>
      'Utilise des options positionnelles (exemple : !config #channel).';

  @override
  String get command_legacy_prefix_title => 'Mode préfixe legacy';

  @override
  String get command_legacy_prefix_desc =>
      'Gérer les commandes de messageCreate avec <préfixe><commande>.';

  @override
  String get command_prefix_override_label =>
      'Remplacement du préfixe (optionnel)';

  @override
  String get command_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get command_legacy_response_label => 'Mode de réponse legacy';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_modal_disabled_legacy =>
      'Les modals sont désactivés en mode legacy.';

  @override
  String get command_target_subcommand => 'Sous-commande cible';

  @override
  String get command_unsaved_title => 'Modifications non enregistrées';

  @override
  String get command_unsaved_confirm =>
      'Vous avez des modifications non enregistrées. Les abandonner ?';

  @override
  String get command_unsaved_keep => 'Continuer l\'édition';

  @override
  String get command_error_missing_bot_id =>
      'ID de bot manquant pour la sauvegarde de commande locale.';

  @override
  String get command_import_tooltip => 'Importer un payload de commande';

  @override
  String get command_export_tooltip => 'Exporter le payload de la commande';

  @override
  String get actions_missing_field_title => 'Champ requis manquant';

  @override
  String get actions_no_matches =>
      'Aucune action ne correspond à votre recherche.';

  @override
  String get actions_add_new_title => 'Ajouter une nouvelle action';

  @override
  String get actions_search_hint => 'Rechercher des actions…';

  @override
  String get actions_add_label => 'Ajouter une action';

  @override
  String get actions_builder_title => 'Constructeur d\'actions';

  @override
  String get actions_save_tooltip => 'Enregistrer les actions';

  @override
  String actions_key_label(String key) {
    return 'Clé : $key';
  }

  @override
  String get modal_remove_field_title => 'Supprimer le champ modal';

  @override
  String get modal_remove_field_confirm =>
      'Ce champ sera supprimé du modal. Continuer ?';

  @override
  String get modal_title_label => 'Titre du modal';

  @override
  String get modal_custom_id_label => 'ID personnalisé';

  @override
  String get modal_custom_id_hint => 'Utilisé pour identifier ce modal';

  @override
  String get modal_workflow_submit =>
      'Workflow à exécuter à la soumission (optionnel)';

  @override
  String get modal_add_text_input => 'Ajouter un champ texte';

  @override
  String modal_field_default_label(int index) {
    return 'Champ $index';
  }

  @override
  String get modal_style => 'Style :';

  @override
  String get modal_default_value => 'Valeur par défaut';

  @override
  String get command_legacy_preset_title => 'Preset legacy';

  @override
  String get command_legacy_preset_desc =>
      'Générer un déclencheur de callback attendu interne et basculer cette commande vers la configuration legacy locale requise.';

  @override
  String get command_awaited_preset_button =>
      'Utiliser le preset de callback attendu';

  @override
  String get command_awaited_preset_active => 'Preset de callback attendu';

  @override
  String get command_edit_raw_name => 'Modifier le nom brut';

  @override
  String get command_awaited_preset_desc =>
      'Le nom de la commande est généré et enregistré comme callback legacy interne.';

  @override
  String get command_awaited_success => 'Succès';

  @override
  String get command_awaited_error => 'Erreur';

  @override
  String get command_awaited_name_label => 'Nom du callback attendu';

  @override
  String get command_awaited_name_hint => 'Exemple : say';

  @override
  String get command_awaited_filter_label => 'Filtre (optionnel)';

  @override
  String get command_awaited_filter_hint =>
      'Exemple : <numeric> ou <yes/no/cancel>';

  @override
  String get command_info_title => 'Info de la commande';

  @override
  String get command_info_desc => 'Métadonnées et disponibilité';

  @override
  String get command_name_label => 'Nom';

  @override
  String get command_name_generated =>
      'Généré par le preset de callback attendu.';

  @override
  String get command_type_label => 'Type de commande';

  @override
  String get command_type_slash => 'Commande Slash';

  @override
  String get command_type_legacy => 'Commande Legacy';

  @override
  String get command_type_user => 'Commande Utilisateur';

  @override
  String get command_type_message => 'Commande Message';

  @override
  String get command_integration_guild => 'Installation serveur';

  @override
  String get command_integration_user => 'Installation utilisateur';

  @override
  String get command_context_guild => 'Serveur';

  @override
  String get command_context_bot_dm => 'MP du bot';

  @override
  String get command_context_group_dm => 'DM de groupe / Autre';

  @override
  String get command_permissions_title => 'Sélectionner les permissions';

  @override
  String get command_prefix_helper =>
      'Supporte les templates et variables scopées (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get actions_title => 'Actions';

  @override
  String get actions_description =>
      'Construire les actions d\'exécution pour cette commande';

  @override
  String actions_active_route(String label) {
    return 'Route active : $label';
  }

  @override
  String actions_build_button(int count) {
    return 'Construire les actions ($count)';
  }

  @override
  String get actions_save_workflow_title => 'Enregistrer comme workflow';

  @override
  String get actions_workflow_name_label => 'Nom du workflow';

  @override
  String get actions_global_variables => 'Variables globales';

  @override
  String get actions_workflows => 'Workflows';

  @override
  String get wizard_quick_start_applied =>
      'Démarrage rapide appliqué au brouillon de commande.';

  @override
  String get wizard_advanced_trigger => 'Paramètres de déclenchement avancés';

  @override
  String get wizard_edit_reply => 'Modifier les détails de la réponse';

  @override
  String get wizard_quick_starts => 'Démarrages rapides';

  @override
  String get wizard_apply_quick_start =>
      'Appliquer le démarrage rapide au brouillon';

  @override
  String get wizard_code_advanced => 'Code / Avancé';

  @override
  String get serialization_export_json_title => 'Exporter la commande en JSON';

  @override
  String get serialization_export_json_subtitle =>
      'Copier le JSON lisible dans le presse-papiers';

  @override
  String get serialization_export_base64_title =>
      'Exporter la commande en Base64';

  @override
  String get serialization_import_title => 'Importer une commande';

  @override
  String get serialization_import_desc =>
      'Collez un payload de commande (JSON ou Base64).';

  @override
  String get serialization_invalid_format =>
      'Format de payload de commande invalide.';

  @override
  String get serialization_invalid_structure =>
      'Structure de payload de commande invalide.';

  @override
  String get serialization_imported => 'Commande importée dans l\'éditeur.';

  @override
  String get response_workflow_title => 'Workflow de réponse';

  @override
  String get response_workflow_auto_defer =>
      'Auto-defer si des actions existent';

  @override
  String get response_workflow_public => 'Public';

  @override
  String get response_workflow_error_policy => 'Politique d\'erreur';

  @override
  String get response_workflow_enable_condition => 'Activer la condition';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_mode_component => 'Composant';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_revert_tooltip =>
      'Annuler toutes les modifications';

  @override
  String get response_workflow_then_text => 'Texte de réponse THEN (optionnel)';

  @override
  String get response_workflow_else_text => 'Texte de réponse ELSE (optionnel)';

  @override
  String get recovery_label => 'Récupération';

  @override
  String get recovery_title => 'Mode récupération';

  @override
  String get recovery_retry_discord => 'Retenter la connexion Discord';

  @override
  String get recovery_delete_bot => 'Supprimer le bot localement';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get reply_configure_workflow => 'Configurer le workflow de réponse';

  @override
  String get reply_buttons_optional =>
      'Boutons et menus de sélection (optionnel)';

  @override
  String get reply_mode_standard => 'Message standard';

  @override
  String get reply_mode_layout => 'Mode mise en page';

  @override
  String get reply_mode_modal => 'Formulaire modal';

  @override
  String get emojis_rename_tooltip => 'Renommer';

  @override
  String get emojis_delete_tooltip => 'Supprimer';

  @override
  String get component_remove_row_title => 'Supprimer la ligne d\'action';

  @override
  String get component_add_tooltip => 'Ajouter un composant';

  @override
  String get component_add_root => 'Ajouter un composant racine';

  @override
  String get edit_shell_save_changes => 'Enregistrer les modifications';

  @override
  String get edit_shell_all_saved =>
      'Toutes les modifications sont enregistrées';

  @override
  String get edit_shell_local_only => 'Local uniquement';

  @override
  String get edit_shell_local_draft => 'Brouillon local';

  @override
  String get edit_shell_unsaved => 'Modifications non enregistrées';

  @override
  String get edit_shell_untitled_command => 'Commande sans titre';

  @override
  String get edit_shell_subtitle =>
      'Les paramètres et les entrées sont en haut. Les actions et la réponse suivent en dessous.';

  @override
  String edit_shell_routes_count(int count) {
    return '$count route(s)';
  }

  @override
  String get edit_shell_command_settings => 'Paramètres de la commande';

  @override
  String get edit_shell_command_settings_desc =>
      'Métadonnées, disponibilité, permissions et placement dans un dossier.';

  @override
  String get edit_shell_trigger_inputs => 'Déclencheur et entrées';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Ajuster les options de la commande, le comportement du déclencheur et le mode d\'exécution.';

  @override
  String get edit_shell_command_body => 'Corps de la commande';

  @override
  String get edit_shell_type_legacy => 'Commande legacy';

  @override
  String get edit_shell_type_user => 'Commande utilisateur';

  @override
  String get edit_shell_type_message => 'Commande message';

  @override
  String get edit_shell_type_slash => 'Commande slash';

  @override
  String get edit_shell_type_command => 'Commande';

  @override
  String get wizard_step_infos => 'Infos';

  @override
  String get wizard_step_trigger_inputs => 'Déclencheur et entrées';

  @override
  String get wizard_step_reply => 'Réponse';

  @override
  String get wizard_step_actions => 'Actions';

  @override
  String get wizard_step_review => 'Vérification';

  @override
  String get review_info_title => 'Info';

  @override
  String get review_name_untitled => '(sans titre)';

  @override
  String review_name_line(String name) {
    return 'Nom : $name';
  }

  @override
  String review_type_line(String type) {
    return 'Type : $type';
  }

  @override
  String review_description_line(String desc) {
    return 'Description : $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Dossier : $folder';
  }

  @override
  String review_options_count(int count) {
    return '$count option(s)';
  }

  @override
  String review_subcommand_routes(int count) {
    return '$count route(s) de sous-commande';
  }

  @override
  String get review_legacy_mode => 'Mode legacy activé';

  @override
  String get review_local_only => 'Commande locale uniquement';

  @override
  String get review_trigger_inputs_title => 'Déclencheur et entrées';

  @override
  String get review_reply_title => 'Réponse';

  @override
  String get review_actions_title => 'Actions';

  @override
  String get wizard_save_command => 'Enregistrer la commande';

  @override
  String get wizard_create_command => 'Créer la commande';

  @override
  String get wizard_reply_summary => 'Résumé de la réponse';

  @override
  String get wizard_legacy_options_subtitle =>
      'Options de commande legacy et comportement local uniquement';

  @override
  String get wizard_quick_start_subtitle =>
      'Utilisez le constructeur simple legacy comme point de départ, puis appliquez-le au brouillon partagé.';

  @override
  String get wizard_bdfd_mode_enabled => 'Mode script BDFD activé';

  @override
  String get wizard_dart_mode_enabled => 'Mode script Dart activé';

  @override
  String get wizard_visual_mode_enabled => 'Mode workflow visuel activé';

  @override
  String get wizard_command_body => 'Corps de la commande';

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
  String response_embeds_count(int count) {
    return '$count embed(s)';
  }

  @override
  String get response_interactive_components => 'composants interactifs';

  @override
  String get command_options_title => 'Options de commande';

  @override
  String get command_options_slash_params => 'Paramètres de commande slash';

  @override
  String get command_options_legacy_params =>
      'Paramètres positionnels legacy (ordre : requis puis optionnels)';

  @override
  String get legacy_prefix_mode_title => 'Mode préfixe legacy';

  @override
  String get legacy_prefix_mode_desc =>
      'Gère les commandes depuis messageCreate avec <préfixe><commande>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Utilise des options positionnelles (exemple : !config #channel).';

  @override
  String get legacy_prefix_override_label =>
      'Remplacement du préfixe (optionnel)';

  @override
  String get legacy_prefix_override_hint =>
      'Exemple : ? ou ((guild.prefix | !))';

  @override
  String get legacy_response_mode_label => 'Mode de réponse legacy';

  @override
  String get command_type_locked =>
      'Le type de commande ne peut pas être changé après la création.';

  @override
  String get local_command_title =>
      'Commande locale (ne pas enregistrer sur Discord)';

  @override
  String get local_command_desc =>
      'Stocke la commande uniquement dans Bot Creator. Vous pouvez l\'enregistrer dynamiquement sur des serveurs spécifiques avec BDFD \$registerGuildCommands.';

  @override
  String get local_command_awaited_desc =>
      'Les presets de callback awaités restent locaux car ce sont des callbacks internes au runtime.';

  @override
  String get command_integration_label =>
      'Où cette commande peut être utilisée';

  @override
  String get command_scope_label => 'Portée de la commande (Contextes)';

  @override
  String get command_permissions_label =>
      'Permissions membres par défaut (optionnel)';

  @override
  String get command_permissions_none =>
      'Aucune sélection (tout le monde peut utiliser la commande)';

  @override
  String command_permissions_count(int count) {
    return '$count permission(s) sélectionnée(s)';
  }

  @override
  String get command_permissions_bitfield =>
      'Champ de bits de permission calculé';

  @override
  String get command_permissions_bitfield_helper =>
      'Calculé automatiquement à partir des permissions sélectionnées.';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Attention : bits de permission inconnus détectés dans les données sauvegardées et préservés : $bits';
  }

  @override
  String get command_permissions_admin_warning =>
      'Administrateur sélectionné : cela contourne les autres vérifications de permissions.';

  @override
  String get command_permissions_tip =>
      'Astuce : laissez tout décoché pour rendre la commande disponible à tous par défaut.';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" enregistré ($count action(s)).';
  }

  @override
  String get reply_command_reply_title => 'Réponse de commande';

  @override
  String get reply_choose_type => 'Choisissez le type de réponse à envoyer';

  @override
  String get reply_mode_standard_desc =>
      'Texte, embeds et boutons / menus de sélection optionnels';

  @override
  String get reply_mode_layout_desc =>
      'Système de mise en page riche de Discord — conteneurs, médias, texte et formulaires';

  @override
  String get reply_mode_modal_desc =>
      'Fenêtre pop-up avec champs de saisie texte';

  @override
  String get reply_response_workflow => 'Workflow de réponse';

  @override
  String get reply_response_text_label => 'Texte de réponse';

  @override
  String get reply_response_text_helper =>
      'Utilisé comme texte de réponse de commande slash. Supporte la syntaxe ((variable)).';

  @override
  String get reply_buttons_desc =>
      'Ajouter des boutons interactifs ou des menus déroulants à ce message';

  @override
  String reply_active_route(String label) {
    return 'Route active : $label';
  }

  @override
  String get workflow_visibility_ephemeral => 'Éphémère';

  @override
  String get workflow_visibility_public => 'Public';

  @override
  String get workflow_auto_defer => 'Différé auto';

  @override
  String get workflow_manual => 'Manuel';

  @override
  String get workflow_condition_on => 'Condition activée';

  @override
  String get workflow_condition_off => 'Condition désactivée';

  @override
  String get workflow_auto_defer_actions => 'Différé auto si actions';

  @override
  String get workflow_no_auto_defer => 'Pas de différé auto';

  @override
  String get workflow_condition_on_upper => 'Condition ACTIVÉE';

  @override
  String get workflow_condition_off_upper => 'Condition DÉSACTIVÉE';

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'Script BDFD | $lines ligne(s) | $diagnostics diagnostic(s)';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Script Dart | $lines ligne(s) | $diagnostics diagnostic(s)';
  }

  @override
  String get scratch_dart_script => 'Script Dart';

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count action(s) sur la route active | $routes route(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count action(s) configurée(s)';
  }

  @override
  String get reply_editor_title => 'Détails de la réponse';

  @override
  String get bdfd_editor_ux_title => 'UX de l\'éditeur';

  @override
  String get bdfd_editor_includes => 'Inclut :';

  @override
  String get bdfd_editor_auto_indent =>
      '• Indentation automatique intelligente sur Entrée';

  @override
  String get bdfd_editor_indent_guides =>
      '• Guides d\'indentation en temps réel';

  @override
  String get bdfd_editor_quick_keys =>
      '• Touches rapides mobiles pour les symboles BDFD';

  @override
  String get bdfd_editor_toggle_indent =>
      'Activer/désactiver les guides d\'indentation';

  @override
  String get startup_error_title => 'Erreur de démarrage';

  @override
  String get startup_failed_message =>
      'Bot Creator n\'a pas pu démarrer sur cet appareil.';

  @override
  String get startup_copy_diagnostics => 'Copier les diagnostics';

  @override
  String get startup_refresh_diagnostics => 'Actualiser les diagnostics';

  @override
  String get startup_diagnostics_copied =>
      'Diagnostics copiés dans le presse-papiers';

  @override
  String export_failed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String import_parse_failed(String error) {
    return 'Échec de l\'analyse du ZIP : $error';
  }

  @override
  String get import_nothing => 'Rien n\'a été importé.';

  @override
  String import_failed(String error) {
    return 'Échec de l\'import : $error';
  }

  @override
  String get workflows_no_match =>
      'Aucun workflow ne correspond aux filtres actuels.';

  @override
  String get settings_run_diagnostics => 'Lancer les diagnostics';

  @override
  String get settings_open_ad_inspector => 'Ouvrir l\'inspecteur de publicités';

  @override
  String get settings_builtin_help => 'Commande !help legacy intégrée';

  @override
  String get drive_manual_backup => 'Sauvegarde manuelle';

  @override
  String get drive_legacy_snapshot => 'Snapshot legacy';

  @override
  String get commands_filter_template => 'Modèle';

  @override
  String get commands_filter_legacy_local => 'Legacy local';

  @override
  String get workflows_no_matches =>
      'Aucun workflow ne correspond aux filtres.';

  @override
  String get common_disabled => 'Désactivé';

  @override
  String get common_label => 'Label';

  @override
  String get common_custom_id => 'ID personnalisé';

  @override
  String get common_custom_id_required => 'ID personnalisé *';

  @override
  String get common_placeholder => 'Placeholder';

  @override
  String get common_style => 'Style';

  @override
  String get common_url => 'URL';

  @override
  String get common_operator => 'Opérateur';

  @override
  String get component_on_click_workflow => 'Au clic, le workflow';

  @override
  String get component_on_select_workflow => 'À la sélection, le workflow';

  @override
  String get component_new_option => 'Nouvelle option';

  @override
  String get component_component_to_wrap => 'Composant à envelopper :';

  @override
  String get component_radio_options => 'Options radio';

  @override
  String get component_checkbox_options => 'Options checkbox';

  @override
  String get component_add_checkbox_option => 'Ajouter une option checkbox';

  @override
  String get component_new_radio => 'Nouveau radio';

  @override
  String get component_new_checkbox => 'Nouvelle checkbox';

  @override
  String get component_file_url => 'URL du fichier';

  @override
  String get component_thumbnail_url => 'URL de la miniature';

  @override
  String get component_media_url => 'URL image / vidéo';

  @override
  String get component_media_urls => 'URLs médias';

  @override
  String get workflow_entry_point_optional => 'Point d\'entrée (optionnel)';

  @override
  String get workflow_entry_point_helper =>
      'Par défaut, le point d\'entrée du workflow est utilisé';

  @override
  String get workflow_set_call_args => 'Définir les arguments d\'appel';

  @override
  String workflow_edit_call_args(int count) {
    return 'Modifier les arguments d\'appel ($count)';
  }

  @override
  String get workflow_root_json_error => 'La racine doit être un objet JSON';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'À la soumission, le workflow \"$name\" sera exécuté (entrée : $entry, args : $args).';
  }

  @override
  String get workflow_no_workflow_note =>
      'Note : Si aucun workflow n\'est sélectionné, la soumission de ce modal ne fera rien.';

  @override
  String get workflow_hint_name => 'ex. handle_form_submit';

  @override
  String action_position(int index, int total) {
    return 'Action $index/$total';
  }

  @override
  String get action_provide_valid_url => 'Veuillez fournir une URL valide.';

  @override
  String get action_hint_duration => 'ex. 5m, 1h, 30s';

  @override
  String action_hint_enter_type(String type) {
    return 'Saisir $type';
  }

  @override
  String get action_hint_emoji => 'Saisir un emoji ou :nom:';

  @override
  String get action_hint_color => '#FFFFFF ou rgb(255,255,255)';

  @override
  String get action_hint_workflow => 'Nom du workflow enregistré';

  @override
  String get action_hint_variable_key => 'Sélectionner une clé de variable';

  @override
  String get action_hint_condition_var =>
      'Utiliser ((variableName)) ou une valeur d\'exécution';

  @override
  String get action_hint_condition_value => 'Valeur de comparaison';

  @override
  String get action_add_new_item => 'Ajouter un nouvel élément';

  @override
  String get action_key_value_pairs => 'Paires clé / valeur';

  @override
  String action_edit_nested(int count) {
    return 'Modifier $count';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Modifier ($count)';
  }

  @override
  String get action_no_items_tap_edit =>
      'Aucun élément - appuyez sur modifier pour ajouter';

  @override
  String get action_no_actions_yet => 'Aucune action dans cette branche.';

  @override
  String action_and_more(int count) {
    return '… et $count de plus';
  }

  @override
  String get action_no_else_if_yet =>
      'Aucune branche ELSE IF. Ajoutez-en une pour tester plus de conditions avant le ELSE.';

  @override
  String get action_no_headers_tap_edit =>
      'Aucun header - appuyez sur modifier pour ajouter';

  @override
  String get action_no_args_tap_edit =>
      'Aucun argument - appuyez sur modifier pour ajouter';

  @override
  String get action_no_properties_tap_edit =>
      'Aucune propriété - appuyez sur configurer';

  @override
  String get action_http_headers_title => 'Headers HTTP (paires clé/valeur)';

  @override
  String get action_bulk_import_hint =>
      'Import en masse (collez des headers comme Clé: Valeur)';

  @override
  String get action_json_editor_hint =>
      'Éditeur d\'objet JSON (supporte les objets/tableaux imbriqués)';

  @override
  String get action_edit_raw_json => 'Modifier le JSON brut';

  @override
  String get action_preview_json => 'Aperçu JSON mis en forme';

  @override
  String get action_cannot_format_json =>
      'Impossible de formater : JSON invalide';

  @override
  String get action_root_must_json => 'La racine doit être un objet JSON';

  @override
  String get action_dynamic_numeric => 'Suggestions numériques dynamiques';

  @override
  String get action_dynamic_variable => 'Suggestions de variables dynamiques';

  @override
  String get action_dynamic_bool_hint => 'true/false ou ((variable))';

  @override
  String get action_dynamic_multiselect_hint =>
      'Valeur dynamique (supporte ((...)))';

  @override
  String action_dynamic_id_hint(String type) {
    return '$type dynamique (supporte ((...)))';
  }

  @override
  String get action_loading_keys => 'Chargement des clés...';

  @override
  String get action_no_saved_keys =>
      'Aucune clé trouvée. Les clés sont créées automatiquement au premier accès.';

  @override
  String get action_select_stored_key =>
      'Sélectionner une clé enregistrée (préfixe bc_ optionnel)';

  @override
  String get action_select_saved_key => 'Sélectionner une clé enregistrée';

  @override
  String get action_static_badge => '(statique)';

  @override
  String get action_or_type_workflow => 'Ou saisir le nom du workflow';

  @override
  String get modal_builder_title => 'Constructeur de modal';

  @override
  String modal_inputs_count(int count) {
    return '$count/5 champs';
  }

  @override
  String modal_input_index(int index) {
    return 'Champ $index';
  }

  @override
  String get settings_legacy_prefix => 'Préfixe des commandes legacy';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? ou ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_helper =>
      'Supporte les templates et variables étendues (bc_ optionnel). Exemple : ((guild.prefix | user.prefix | !))';

  @override
  String get settings_builtin_help_subtitle =>
      'Fonctionnalité obligatoire avec toggle explicite. Désactivez-la pour ne garder qu\'un comportement d\'aide personnalisé.';

  @override
  String get settings_status_remove_confirm =>
      'Cette entrée de statut sera supprimée. Continuer ?';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooks : $count$limit';
  }

  @override
  String get webhooks_path_copied => 'Chemin copié.';

  @override
  String get webhooks_secret_copied => 'Secret copié.';

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow : $workflow • Toutes les $minutes min';
  }

  @override
  String import_summary_commands_imported(int count) {
    return '$count commande(s) importée(s)';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count commande(s) ignorée(s)';
  }

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) importé(s)';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) ignoré(s)';
  }

  @override
  String get import_summary_status_imported => 'statut importé';

  @override
  String get import_summary_variables_imported => 'variables importées';

  @override
  String get command_subcommand_workflow_title => 'Workflow SubCommand';

  @override
  String get command_subcommand_workflow_desc =>
      'Choisissez le sous-commande que vous configurez.';

  @override
  String command_sync_failed_local(String error) {
    return 'Enregistré localement. Échec de la synchronisation Discord : $error';
  }

  @override
  String get command_description_required =>
      'Veuillez saisir une description de commande';

  @override
  String get command_description_length =>
      'La description de commande doit contenir au maximum 100 caractères';

  @override
  String get response_workflow_deferred_reply => 'Réponse différée';

  @override
  String get response_workflow_auto_defer_desc =>
      'Acquitter rapidement, exécuter les actions, puis modifier la réponse finale.';

  @override
  String get response_workflow_visibility => 'Visibilité';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Éphémère (utilisateur de la commande uniquement)';

  @override
  String get response_workflow_error_policy_desc =>
      'Quand une action échoue, modifier le message différé avec une erreur.';

  @override
  String get response_workflow_conditional_title =>
      'Réponse conditionnelle (MVP)';

  @override
  String get response_workflow_condition_desc =>
      'Si la variable existe et n\'est pas vide => utiliser THEN, sinon ELSE.';

  @override
  String get response_workflow_variable_key =>
      'Clé de variable (ex : opts.userId)';

  @override
  String get commands_search_hint => 'Rechercher des commandes...';

  @override
  String get commands_all_folders => 'Tous les dossiers';

  @override
  String get commands_no_match_filters =>
      'Aucune commande ne correspond aux filtres actuels.';

  @override
  String get actions_search_sequence_hint =>
      'Rechercher des actions dans cette séquence...';

  @override
  String actions_sequence_count(int count) {
    return '$count action(s) dans la séquence';
  }

  @override
  String actions_save_count(int count) {
    return 'Enregistrer $count actions';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Étape $index/$total';
  }

  @override
  String get option_type_string => 'Texte';

  @override
  String get option_type_integer => 'Entier';

  @override
  String get option_type_boolean => 'Booléen';

  @override
  String get option_type_user => 'Utilisateur';

  @override
  String get option_type_channel => 'Canal';

  @override
  String get option_type_role => 'Rôle';

  @override
  String get option_type_mentionable => 'Mentionnable';

  @override
  String get option_type_number => 'Nombre';

  @override
  String get option_type_attachment => 'Pièce jointe';

  @override
  String get option_type_subcommand => 'Sous-commande';

  @override
  String get option_type_subcommand_group => 'Groupe de sous-commandes';

  @override
  String get option_type_unknown => 'Inconnu';

  @override
  String get option_name_required => 'Veuillez saisir un nom pour l\'option';

  @override
  String get option_name_max_length =>
      'Le nom de l\'option doit contenir au maximum 32 caractères';

  @override
  String get option_name_invalid_chars =>
      'Le nom de l\'option ne peut contenir que des lettres, chiffres et underscores';

  @override
  String get option_name_invalid_start =>
      'Le nom de l\'option commence par un caractère non pris en charge';

  @override
  String get option_name_duplicate => 'Ce nom est déjà utilisé à ce niveau';

  @override
  String option_label_number(int index) {
    return 'Label $index';
  }

  @override
  String option_value_number(int index) {
    return 'Valeur $index';
  }

  @override
  String get validation_option_max_entries =>
      'Chaque niveau d\'option prend en charge au maximum 25 entrées.';

  @override
  String get validation_option_no_mix_top_level =>
      'Les options de premier niveau ne peuvent pas mélanger sous-commandes/groupes et options normales.';

  @override
  String get validation_option_group_only_subcommands =>
      'Un SubCommandGroup ne peut contenir que des options SubCommand.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Un SubCommand ne peut pas contenir de SubCommand ou SubCommandGroup imbriqué.';

  @override
  String get validation_option_name_required =>
      'Chaque option doit avoir un nom.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Nom d\'option dupliqué \"$name\" au même niveau.';
  }

  @override
  String get validation_option_description_required =>
      'Chaque option doit avoir une description.';

  @override
  String get validation_option_leaf_no_nested =>
      'Les options normales ne peuvent pas contenir d\'options imbriquées.';

  @override
  String get validation_option_hierarchy_not_required =>
      'SubCommand et SubCommandGroup ne peuvent pas être marqués requis.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'SubCommand et SubCommandGroup ne peuvent pas définir de choix.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'SubCommand et SubCommandGroup ne peuvent pas définir de min/max.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup est autorisé uniquement au premier niveau.';

  @override
  String get validation_option_subcommand_depth =>
      'La profondeur d\'imbrication des SubCommand dépasse les limites Discord.';

  @override
  String get bdfd_compile_error_simple =>
      'Ce script BDFD n\'a pas pu être compilé.';

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Ce script BDFD n\'a pas pu être compilé :\n$summary';
  }

  @override
  String get command_not_found => 'Commande introuvable';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'Échec d\'exécution du script BDFD pour la commande \"$command\" : $error';
  }

  @override
  String get component_empty_option => 'Vide';

  @override
  String get component_unknown_component => 'Composant inconnu';

  @override
  String get common_bot => 'Bot';

  @override
  String get command_payload_hint => 'Payload de commande';

  @override
  String get workflows_search_hint => 'Rechercher des workflows...';

  @override
  String get component_default_option_label => 'Option';

  @override
  String get component_default_choice_label => 'Choix';

  @override
  String get command_execution_error =>
      'Une erreur est survenue lors de l\'exécution de cette commande.';

  @override
  String get bdfd_runtime_execution_error =>
      'Une erreur est survenue lors de l\'exécution de ce script BDFD.';

  @override
  String get bdfd_compiled_no_actions =>
      'Ce script BDFD a été compilé avec succès mais n\'a produit aucune action.';

  @override
  String get embed_section_color => 'Couleur';

  @override
  String get embed_section_timestamp => 'Horodatage';

  @override
  String get embed_section_fields => 'Champs';

  @override
  String get embed_section_dynamic_fields => 'Champs dynamiques';

  @override
  String get embed_add_field => 'Ajouter un champ';

  @override
  String get embed_add_section => 'Ajouter une section';

  @override
  String get common_add_section => 'Ajouter une section';

  @override
  String get component_block_workflow => 'Workflow';

  @override
  String get component_block_label_style => 'Style';

  @override
  String get notion_filter_add => 'Ajouter un filtre';

  @override
  String get notion_filter_type => 'Type';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'Créer le workflow \"$query\"';
  }

  @override
  String commands_create_from_query(String query) {
    return 'Créer la commande \"$query\"';
  }

  @override
  String get commands_filter_type_label => 'Type';
}
