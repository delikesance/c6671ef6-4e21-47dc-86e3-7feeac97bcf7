// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class StudioLocalizationsFr extends StudioLocalizations {
  StudioLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get navHome => 'Accueil';

  @override
  String get navDocs => 'Documentation';

  @override
  String get navSettings => 'Paramètres';

  @override
  String get navBack => 'Retour';

  @override
  String get navCommands => 'Commandes';

  @override
  String get navCommandsShort => 'Cmd';

  @override
  String get navCopilot => 'Copilote IA';

  @override
  String get navFlows => 'Flux';

  @override
  String get navVars => 'Vars';

  @override
  String get navSched => 'Planif';

  @override
  String get navHooks => 'Webhooks entrants';

  @override
  String get navEmojis => 'Émojis';

  @override
  String get navTeam => 'Équipe';

  @override
  String get navGuilds => 'Serveurs';

  @override
  String get navDashboard => 'Tableau de bord';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'Mode débutant';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => 'Rechercher';

  @override
  String get modulesGroupCreate => 'Création';

  @override
  String get modulesGroupAutomation => 'Automatisation';

  @override
  String get modulesGroupManagement => 'Gestion';

  @override
  String get modulesGroupTools => 'Outils';

  @override
  String get modulesWorkflows => 'Workflows';

  @override
  String get modulesVariables => 'Variables';

  @override
  String get modulesEmojis => 'Émoticônes';

  @override
  String get modulesScheduler => 'Planificateur';

  @override
  String get modulesDescWorkflows => 'Automatisez vos actions et événements';

  @override
  String get modulesDescVariables =>
      'Données mémorisées : tout le bot, serveur, membre…';

  @override
  String get modulesDescEmojis => 'Emojis applicatifs du bot';

  @override
  String get modulesDescScheduler => 'Exécute un workflow toutes les X min';

  @override
  String get modulesDescHooks => 'Appels HTTP routés vers un workflow';

  @override
  String get modulesDescTeam => 'Collaborateurs et tchat d\'équipe';

  @override
  String get modulesDescGuilds => 'Serveurs où le bot est présent';

  @override
  String get modulesDescDashboard => 'Usage des commandes sur 24 h, 7 j, 30 j';

  @override
  String get modulesDescCopilot => 'Assistant pour créer vos commandes';

  @override
  String get beginnerOnHint => 'Affichage des onglets essentiels uniquement';

  @override
  String get beginnerOffHint => 'Affichage de toutes les fonctionnalités';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonRefresh => 'Actualiser';

  @override
  String get commonSend => 'Envoyer';

  @override
  String get statusOnline => 'En ligne';

  @override
  String get statusStopped => 'Arrêté';

  @override
  String get loadError => 'Erreur de chargement';

  @override
  String get comingSoonBody =>
      'Cette section arrive bientôt dans le Studio. Elle reste disponible dans l\'app Bot Creator.';

  @override
  String get comingSoonShort => 'Disponible bientôt dans le Studio.';

  @override
  String get appTitle => 'Bot Creator Studio';

  @override
  String get loginSubtitle =>
      'Connectez-vous avec Discord pour accéder à vos bots. Le Studio demande toujours une connexion valide.';

  @override
  String get loginDiscord => 'Se connecter avec Discord';

  @override
  String get accountTitle => 'Compte';

  @override
  String get accountSignedIn => 'Connecté avec Discord';

  @override
  String accountSignedInAs(String name) {
    return 'Connecté avec Discord : $name';
  }

  @override
  String get accountPlanPremium => 'Formule Premium';

  @override
  String get accountPlanFree =>
      'Formule gratuite : l\'abonnement se gère depuis l\'application mobile.';

  @override
  String get accountSignOut => 'Se déconnecter';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get languageSystem => 'Système';

  @override
  String get botsOverline => 'Mes projets';

  @override
  String get botsTitle => 'Mes bots';

  @override
  String get botsCreate => 'Créer un bot';

  @override
  String get botsManage => 'Gérer';

  @override
  String get botStop => 'Arrêter';

  @override
  String get botStart => 'Lancer le bot';

  @override
  String get botsEmptyTitle => 'Vous n\'avez pas encore d\'applications.';

  @override
  String get botsEmptyHint =>
      'Créez votre premier bot depuis l\'app Bot Creator : il apparaîtra ici.';

  @override
  String get hostingIncludedTitle => 'Hébergement inclus';

  @override
  String get hostingIncludedValue => 'Illimité avec ton abonnement';

  @override
  String get hostingRemainingTitle => 'Temps restant';

  @override
  String get hostingExpired => 'Hébergement expiré';

  @override
  String get hostingSessionActive => 'Session active';

  @override
  String get hostingSessionActiveOnline => 'Session active (en ligne)';

  @override
  String get hostingPreservedTitle => 'Temps préservé';

  @override
  String hostingReserve(String time) {
    return 'Réserve : $time';
  }

  @override
  String get hostingReserveAvailable => 'Réserve disponible (en pause)';

  @override
  String get hostingPreservedDetail =>
      'Le temps est préservé tant que le bot est arrêté.';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createBotToken => 'Jeton du bot Discord';

  @override
  String get createBotTokenHint =>
      'Il est envoyé en HTTPS au serveur Bot Creator et jamais conservé dans le navigateur.';

  @override
  String createBotValidNamed(String name) {
    return 'Jeton valide : $name';
  }

  @override
  String createBotValidId(String id) {
    return 'Jeton valide (ID $id)';
  }

  @override
  String get createBotSamplePing => 'Ajouter une commande /ping d\'exemple';

  @override
  String get createBotBusy =>
      'Création en cours : cela peut prendre jusqu\'à deux minutes. Ne fermez pas cette page.';

  @override
  String get createBotVerify => 'Vérifier le jeton';

  @override
  String get createBotSubmit => 'Créer le bot';

  @override
  String get createBotSyncBusy =>
      'Une synchronisation de ce bot est déjà en cours. Patientez quelques minutes.';

  @override
  String get createBotNoId =>
      'Impossible de lire l\'identifiant du bot à partir de ce jeton.';

  @override
  String get overviewLogs => 'Journaux';

  @override
  String overviewLogsUnavailable(String error) {
    return 'Journaux indisponibles : $error';
  }

  @override
  String get overviewNoLogs => 'Aucun journal pour le moment.';

  @override
  String get commandsSearch => 'Rechercher des commandes...';

  @override
  String get commandsEmpty =>
      'Aucune commande pour l\'instant. Créez-en une depuis l\'app Bot Creator.';

  @override
  String get commandsNoMatch =>
      'Aucune commande ne correspond aux filtres actuels.';

  @override
  String get teamSubtitle => 'Collaborateurs et tchat d\'équipe.';

  @override
  String get teamChatTitle => 'Tchat d\'équipe';

  @override
  String get teamNoChatAccess =>
      'Le propriétaire ne vous a pas donné accès au tchat.';

  @override
  String get teamNoMessages => 'Aucun message.';

  @override
  String get teamWriteHint => 'Écrire un message…';

  @override
  String get teamOwner => 'Propriétaire';

  @override
  String get teamNoPermissions => 'Aucun droit particulier';

  @override
  String get teamRemove => 'Retirer de l\'équipe';

  @override
  String get teamPermEditCommands => 'Modifier les commandes';

  @override
  String get teamPermStartStop => 'Lancer / arrêter';

  @override
  String get teamPermClaimAds => 'Gagner du temps (pubs)';

  @override
  String get teamPermInvite => 'Inviter';

  @override
  String get premiumHint =>
      'Ton compte est en formule gratuite : l\'abonnement s\'active depuis l\'application mobile (le Studio n\'affiche ni publicité ni achat).';

  @override
  String get featureSchedulerTitle => 'Déclencheurs planifiés';

  @override
  String get featureSchedulerDesc =>
      'Exécute des workflows automatiquement toutes les X minutes (jusqu\'à 10 actifs).';

  @override
  String get featureAnalyticsTitle => 'Analytics Premium';

  @override
  String get featureAnalyticsDesc =>
      'Débloquez le taux d\'erreur, les percentiles de latence et les insights de localisation.';

  @override
  String get featureHooksTitle => 'Webhooks entrants';

  @override
  String get featureHooksDesc =>
      'Crée des endpoints webhook sécurisés et route les appels vers les workflows.';
}
