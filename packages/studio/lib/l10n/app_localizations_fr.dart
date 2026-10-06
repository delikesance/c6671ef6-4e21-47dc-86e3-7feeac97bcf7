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

  @override
  String get commonSaved => 'Enregistré';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get deleteIrreversible => 'Cette action est définitive.';

  @override
  String deleteNamedTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get commandNew => 'Nouvelle commande';

  @override
  String get commandSaved => 'Commande enregistrée.';

  @override
  String get commandChangedElsewhere =>
      'Ce bot a été modifié ailleurs (app ou autre session). Rechargez la commande avant d\'enregistrer.';

  @override
  String get scriptEdit => 'Modifier le script';

  @override
  String get commandTriggerHybrid => 'Slash + message texte';

  @override
  String get workflowNew => 'Nouveau workflow';

  @override
  String get workflowsEmpty =>
      'Aucun workflow. Créez-en un pour réutiliser une suite d\'actions ou réagir à un événement.';

  @override
  String get workflowSaved => 'Workflow enregistré.';

  @override
  String get workflowDeleteBody =>
      'Les commandes qui appellent ce workflow ne trouveront plus rien à exécuter.';

  @override
  String get workflowTypeGeneral => 'Général (appelé par une commande)';

  @override
  String get workflowCategory => 'Catégorie';

  @override
  String workflowScriptNotice(String mode) {
    return 'Ce workflow est écrit en $mode : le Studio ne modifie que les workflows visuels. Il reste enregistré tel quel.';
  }

  @override
  String get variablesGlobalSubtitle => 'Données mémorisées pour tout le bot.';

  @override
  String get variablesScopedHint =>
      'Une définition donne la valeur par défaut ; chaque serveur, salon ou membre garde ensuite sa propre valeur.';

  @override
  String get variableScopedRemoveNote =>
      'La définition est retirée ; les valeurs déjà mémorisées ne sont pas effacées.';

  @override
  String get copilotNoCredits =>
      'Crédits IA insuffisants. Rechargez-les depuis l\'app mobile.';

  @override
  String get copilotChatTooLong =>
      'Cette discussion est trop longue : démarrez-en une nouvelle.';

  @override
  String get copilotUnavailable =>
      'Le Copilote est indisponible pour le moment.';

  @override
  String get copilotGenerationFailed => 'La génération a échoué.';

  @override
  String get copilotDeleteChat => 'Supprimer la discussion';

  @override
  String copilotWants(String tool) {
    return 'Le Copilote veut : $tool';
  }

  @override
  String get dashboardRuns => 'Exécutions';

  @override
  String get dashboardSinceStart => 'Depuis le début';

  @override
  String get dashboardLatencyP50P95 => 'Latence P50 / P95';

  @override
  String get dashboardActivity => 'Activité';

  @override
  String get dashboardLanguages => 'Langues';

  @override
  String get dashboardNoRuns => 'Aucune exécution sur cette période.';

  @override
  String get dashboardNoActivity => 'Aucune activité sur cette période.';

  @override
  String get dashboardOneExecution => '1 exécution';

  @override
  String dashboardAgoDays(int days) {
    return 'il y a $days j';
  }

  @override
  String dashboardAgoHours(int hours) {
    return 'il y a $hours h';
  }

  @override
  String dashboardErrorRateOf(String rate) {
    return '$rate % d\'erreurs';
  }

  @override
  String dashboardLatencyPercentiles(int p50, int p95) {
    return 'P50 $p50 ms · P95 $p95 ms';
  }

  @override
  String get dashboardLatencyNone => 'latence —';

  @override
  String get botStopFailed => 'Impossible d\'arrêter le bot';

  @override
  String get botStartFailed => 'Impossible de lancer le bot';

  @override
  String get refusalNoFreeTimeTitle => 'Temps d\'hébergement épuisé';

  @override
  String get refusalNoFreeTimeBody =>
      'Ce bot n\'a plus de temps d\'hébergement gratuit. Regardez une publicité depuis l\'application mobile pour en gagner, ou passez Premium. Le Studio ne propose ni publicité ni achat.';

  @override
  String get authSessionExpired => 'Session expirée. Reconnectez-vous.';

  @override
  String authDiscordRefused(String reason) {
    return 'Connexion Discord refusée ($reason).';
  }

  @override
  String get authInvalidResponse => 'Réponse de connexion invalide. Réessayez.';

  @override
  String get validationCommandNameFormat =>
      'Nom invalide : minuscules, chiffres, « - » et « _ » uniquement, sans espace.';

  @override
  String validationDescriptionTooLong(int max) {
    return 'La description fait $max caractères au maximum.';
  }

  @override
  String get validationWorkflowNameRequired => 'Le nom du workflow est requis.';

  @override
  String validationWorkflowNameTooLong(int max) {
    return 'Le nom fait $max caractères au maximum.';
  }

  @override
  String validationWorkflowTooManyBlocks(int max) {
    return '$max blocs au maximum par workflow.';
  }

  @override
  String validationOptionNameInvalid(String name) {
    return 'Option « $name » : minuscules, chiffres, « - » et « _ », 32 caractères au plus.';
  }

  @override
  String validationOptionDescription(String name) {
    return 'Option « $name » : description requise (100 caractères au plus).';
  }

  @override
  String validationOptionRequiredOrder(String name) {
    return 'Les options obligatoires doivent précéder les facultatives (« $name »).';
  }

  @override
  String get schedulerPremiumOnly =>
      'Le planificateur est réservé aux comptes Premium. L\'abonnement se gère dans l\'app.';

  @override
  String get webhooksPremiumOnly =>
      'Les webhooks entrants sont réservés aux comptes Premium. L\'abonnement se gère dans l\'app.';
}
