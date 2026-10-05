// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class StudioLocalizationsEn extends StudioLocalizations {
  StudioLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navDocs => 'Documentation';

  @override
  String get navSettings => 'Settings';

  @override
  String get navBack => 'Back';

  @override
  String get navCommands => 'Commands';

  @override
  String get navCommandsShort => 'Cmd';

  @override
  String get navCopilot => 'AI copilot';

  @override
  String get navFlows => 'Flow';

  @override
  String get navVars => 'Vars';

  @override
  String get navSched => 'Sched';

  @override
  String get navHooks => 'Inbound webhooks';

  @override
  String get navEmojis => 'Emoji';

  @override
  String get navTeam => 'Team';

  @override
  String get navGuilds => 'Servers';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navModules => 'Modules';

  @override
  String get navBeginner => 'Beginner mode';

  @override
  String get modulesTitle => 'Modules';

  @override
  String get modulesSearch => 'Search';

  @override
  String get modulesGroupCreate => 'Create';

  @override
  String get modulesGroupAutomation => 'Automation';

  @override
  String get modulesGroupManagement => 'Management';

  @override
  String get modulesGroupTools => 'Tools';

  @override
  String get modulesWorkflows => 'Workflows';

  @override
  String get modulesVariables => 'Variables';

  @override
  String get modulesEmojis => 'Emojis';

  @override
  String get modulesScheduler => 'Scheduler';

  @override
  String get modulesDescWorkflows => 'Automate your actions and events';

  @override
  String get modulesDescVariables =>
      'Remembered data: whole bot, server, member…';

  @override
  String get modulesDescEmojis => 'The bot\'s application emojis';

  @override
  String get modulesDescScheduler => 'Runs a workflow every X minutes';

  @override
  String get modulesDescHooks => 'HTTP calls routed to a workflow';

  @override
  String get modulesDescTeam => 'Collaborators and team chat';

  @override
  String get modulesDescGuilds => 'Servers where the bot is present';

  @override
  String get modulesDescDashboard => 'Command usage over 24 h, 7 d, 30 d';

  @override
  String get modulesDescCopilot => 'Assistant to build your commands';

  @override
  String get beginnerOnHint => 'Showing essential tabs only';

  @override
  String get beginnerOffHint => 'Showing all features';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonClose => 'Close';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonRefresh => 'Refresh';

  @override
  String get commonSend => 'Send';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusStopped => 'Stopped';

  @override
  String get loadError => 'Loading error';

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
  String get loginDiscord => 'Connect with Discord';

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
  String get accountSignOut => 'Sign out';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get botsOverline => 'My projects';

  @override
  String get botsTitle => 'My bots';

  @override
  String get botsCreate => 'Create a bot';

  @override
  String get botsManage => 'Manage';

  @override
  String get botStop => 'Stop';

  @override
  String get botStart => 'Start Bot';

  @override
  String get botsEmptyTitle => 'You don\'t have any apps yet.';

  @override
  String get botsEmptyHint =>
      'Create your first bot from the Bot Creator app: it will show up here.';

  @override
  String get hostingIncludedTitle => 'Hosting included';

  @override
  String get hostingIncludedValue => 'Unlimited with your subscription';

  @override
  String get hostingRemainingTitle => 'Time left';

  @override
  String get hostingExpired => 'Hosting expired';

  @override
  String get hostingSessionActive => 'Active session';

  @override
  String get hostingSessionActiveOnline => 'Active session (online)';

  @override
  String get hostingPreservedTitle => 'Time preserved';

  @override
  String hostingReserve(String time) {
    return 'Reserve: $time';
  }

  @override
  String get hostingReserveAvailable => 'Banked time (paused)';

  @override
  String get hostingPreservedDetail =>
      'Time is preserved while the bot is stopped.';

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
  String get createBotSamplePing => 'Add a sample /ping command';

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
  String get commandsSearch => 'Search commands...';

  @override
  String get commandsEmpty =>
      'No commands yet. Create one from the Bot Creator app.';

  @override
  String get commandsNoMatch => 'No commands match the current filters.';

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
  String get teamOwner => 'Owner';

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
  String get featureSchedulerTitle => 'Scheduler triggers';

  @override
  String get featureSchedulerDesc =>
      'Run workflows automatically every X minutes (up to 10 active).';

  @override
  String get featureAnalyticsTitle => 'Premium analytics';

  @override
  String get featureAnalyticsDesc =>
      'Unlock error rate, latency percentiles, and locale insights.';

  @override
  String get featureHooksTitle => 'Inbound webhooks';

  @override
  String get featureHooksDesc =>
      'Create secure webhook endpoints and route calls to workflows.';
}
