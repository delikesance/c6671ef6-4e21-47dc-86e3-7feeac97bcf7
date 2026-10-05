// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class StudioLocalizationsDe extends StudioLocalizations {
  StudioLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get navHome => 'Startseite';

  @override
  String get navDocs => 'Dokumentation';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get navBack => 'Zurück';

  @override
  String get navCommands => 'Befehle';

  @override
  String get navCommandsShort => 'Cmd';

  @override
  String get navCopilot => 'KI-Copilot';

  @override
  String get navFlows => 'Flow';

  @override
  String get navVars => 'Var';

  @override
  String get navSched => 'Planer';

  @override
  String get navHooks => 'Inbound Webhooks';

  @override
  String get navEmojis => 'Emoji';

  @override
  String get navTeam => 'Team';

  @override
  String get navGuilds => 'Server';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'Anfängermodus';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => 'Suchen';

  @override
  String get modulesGroupCreate => 'Erstellen';

  @override
  String get modulesGroupAutomation => 'Automatisierung';

  @override
  String get modulesGroupManagement => 'Verwaltung';

  @override
  String get modulesGroupTools => 'Tools';

  @override
  String get modulesWorkflows => 'Workflows';

  @override
  String get modulesVariables => 'Globale Variablen';

  @override
  String get modulesEmojis => 'Emojis';

  @override
  String get modulesScheduler => 'Planer';

  @override
  String get modulesDescWorkflows =>
      'Automatisiere deine Aktionen und Ereignisse';

  @override
  String get modulesDescVariables => 'Für alle Befehle gemeinsam genutzt';

  @override
  String get modulesDescEmojis => 'Anwendungs-Emojis des Bots';

  @override
  String get modulesDescScheduler => 'Führt alle X Min. einen Workflow aus';

  @override
  String get modulesDescHooks =>
      'HTTP-Aufrufe, die an einen Workflow geleitet werden';

  @override
  String get modulesDescTeam => 'Mitarbeitende und Team-Chat';

  @override
  String get modulesDescGuilds => 'Server, auf denen der Bot ist';

  @override
  String get modulesDescDashboard => 'Command usage over 24 h, 7 d, 30 d';

  @override
  String get modulesDescCopilot => 'Assistant to build your commands';

  @override
  String get beginnerOnHint => 'Nessentielle Tabs werden angezeigt';

  @override
  String get beginnerOffHint => 'Alle Funktionen werden angezeigt';

  @override
  String get commonRetry => 'Wiederholen';

  @override
  String get commonClose => 'Schließen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonRefresh => 'Aktualisieren';

  @override
  String get commonSend => 'Send';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusStopped => 'Gestoppt';

  @override
  String get loadError => 'Fehler beim Laden';

  @override
  String get comingSoonBody =>
      'This section is coming soon to Studio. It is still available in the Bot Creator app.';

  @override
  String get comingSoonShort => 'Coming soon to Studio.';

  @override
  String get appTitle => 'Bot Creator Studio';

  @override
  String get loginSubtitle =>
      'Sign in with Discord to access your bots. Studio always requires a valid sign-in.';

  @override
  String get loginDiscord => 'Mit Discord verbinden';

  @override
  String get accountTitle => 'Account';

  @override
  String get accountSignedIn => 'Signed in with Discord';

  @override
  String accountSignedInAs(String name) {
    return 'Signed in with Discord: $name';
  }

  @override
  String get accountPlanPremium => 'Premium plan';

  @override
  String get accountPlanFree =>
      'Free plan: manage your subscription from the mobile app.';

  @override
  String get accountSignOut => 'Abmelden';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get botsOverline => 'My projects';

  @override
  String get botsTitle => 'Meine Bots';

  @override
  String get botsCreate => 'Bot erstellen';

  @override
  String get botsManage => 'Verwalten';

  @override
  String get botStop => 'Stopp';

  @override
  String get botStart => 'Bot starten';

  @override
  String get botsEmptyTitle => 'Sie haben noch keine Apps.';

  @override
  String get botsEmptyHint =>
      'Create your first bot from the Bot Creator app: it will show up here.';

  @override
  String get hostingIncludedTitle => 'Hosting inklusive';

  @override
  String get hostingIncludedValue => 'Unbegrenzt mit deinem Abo';

  @override
  String get hostingRemainingTitle => 'Verbleibende Zeit';

  @override
  String get hostingExpired => 'Hosting abgelaufen';

  @override
  String get hostingSessionActive => 'Aktive Sitzung';

  @override
  String get hostingSessionActiveOnline => 'Aktive Sitzung (online)';

  @override
  String get hostingPreservedTitle => 'Zeit erhalten';

  @override
  String hostingReserve(String time) {
    return 'Reserve: $time';
  }

  @override
  String get hostingReserveAvailable => 'Gespeicherte Zeit (pausiert)';

  @override
  String get hostingPreservedDetail =>
      'Die Zeit bleibt erhalten, solange der Bot gestoppt ist.';

  @override
  String durationHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get createBotToken => 'Discord bot token';

  @override
  String get createBotTokenHint =>
      'It is sent over HTTPS to the Bot Creator server and never kept in the browser.';

  @override
  String createBotValidNamed(String name) {
    return 'Valid token: $name';
  }

  @override
  String createBotValidId(String id) {
    return 'Valid token (ID $id)';
  }

  @override
  String get createBotSamplePing => 'Beispiel-/ping-Befehl hinzufügen';

  @override
  String get createBotBusy =>
      'Creating the bot: this can take up to two minutes. Do not close this page.';

  @override
  String get createBotVerify => 'Check token';

  @override
  String get createBotSubmit => 'Create bot';

  @override
  String get createBotSyncBusy =>
      'This bot is already being synchronized. Please wait a few minutes.';

  @override
  String get createBotNoId => 'Could not read the bot ID from this token.';

  @override
  String get overviewLogs => 'Logs';

  @override
  String overviewLogsUnavailable(String error) {
    return 'Logs unavailable: $error';
  }

  @override
  String get overviewNoLogs => 'No logs yet.';

  @override
  String get commandsSearch => 'Befehle suchen...';

  @override
  String get commandsEmpty =>
      'No commands yet. Create one from the Bot Creator app.';

  @override
  String get commandsNoMatch =>
      'Keine Befehle entsprechen den aktuellen Filtern.';

  @override
  String get teamSubtitle => 'Collaborators and team chat.';

  @override
  String get teamChatTitle => 'Team chat';

  @override
  String get teamNoChatAccess =>
      'The owner has not given you access to the chat.';

  @override
  String get teamNoMessages => 'No messages.';

  @override
  String get teamWriteHint => 'Write a message…';

  @override
  String get teamOwner => 'Besitzer';

  @override
  String get teamNoPermissions => 'No specific permissions';

  @override
  String get teamRemove => 'Remove from team';

  @override
  String get teamPermEditCommands => 'Edit commands';

  @override
  String get teamPermStartStop => 'Start / stop';

  @override
  String get teamPermClaimAds => 'Earn time (ads)';

  @override
  String get teamPermInvite => 'Invite';

  @override
  String get premiumHint =>
      'Your account is on the free plan: subscriptions are activated from the mobile app (Studio shows no ads or purchases).';

  @override
  String get featureSchedulerTitle => 'Scheduler-Trigger';

  @override
  String get featureSchedulerDesc =>
      'Workflows automatisch alle X Minuten ausführen (bis zu 10 aktive).';

  @override
  String get featureAnalyticsTitle => 'Premium-Analysen';

  @override
  String get featureAnalyticsDesc =>
      'Schalten Sie Fehlerrate, Latenz-Perzentile und Locale-Einblicke frei.';

  @override
  String get featureHooksTitle => 'Inbound Webhooks';

  @override
  String get featureHooksDesc =>
      'Erstellen Sie sichere Webhook-Endpunkte und leiten Sie Aufrufe an Workflows weiter.';
}
