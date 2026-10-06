import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of StudioLocalizations
/// returned by `StudioLocalizations.of(context)`.
///
/// Applications need to include `StudioLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: StudioLocalizations.localizationsDelegates,
///   supportedLocales: StudioLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the StudioLocalizations.supportedLocales
/// property.
abstract class StudioLocalizations {
  StudioLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static StudioLocalizations of(BuildContext context) {
    return Localizations.of<StudioLocalizations>(context, StudioLocalizations)!;
  }

  static const LocalizationsDelegate<StudioLocalizations> delegate =
      _StudioLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
    Locale('pt'),
    Locale('tr'),
  ];

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navDocs.
  ///
  /// In en, this message translates to:
  /// **'Documentation'**
  String get navDocs;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @navBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get navBack;

  /// No description provided for @navCommands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get navCommands;

  /// No description provided for @navCommandsShort.
  ///
  /// In en, this message translates to:
  /// **'Cmd'**
  String get navCommandsShort;

  /// No description provided for @navCopilot.
  ///
  /// In en, this message translates to:
  /// **'AI copilot'**
  String get navCopilot;

  /// No description provided for @navFlows.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get navFlows;

  /// No description provided for @navVars.
  ///
  /// In en, this message translates to:
  /// **'Vars'**
  String get navVars;

  /// No description provided for @navSched.
  ///
  /// In en, this message translates to:
  /// **'Sched'**
  String get navSched;

  /// No description provided for @navHooks.
  ///
  /// In en, this message translates to:
  /// **'Inbound webhooks'**
  String get navHooks;

  /// No description provided for @navEmojis.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get navEmojis;

  /// No description provided for @navTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get navTeam;

  /// No description provided for @navGuilds.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get navGuilds;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navReplay.
  ///
  /// In en, this message translates to:
  /// **'Debugger Replay'**
  String get navReplay;

  /// No description provided for @navModules.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get navModules;

  /// No description provided for @navBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner mode'**
  String get navBeginner;

  /// No description provided for @modulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Modules'**
  String get modulesTitle;

  /// No description provided for @modulesSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get modulesSearch;

  /// No description provided for @modulesGroupCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get modulesGroupCreate;

  /// No description provided for @modulesGroupAutomation.
  ///
  /// In en, this message translates to:
  /// **'Automation'**
  String get modulesGroupAutomation;

  /// No description provided for @modulesGroupManagement.
  ///
  /// In en, this message translates to:
  /// **'Management'**
  String get modulesGroupManagement;

  /// No description provided for @modulesGroupTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get modulesGroupTools;

  /// No description provided for @modulesWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get modulesWorkflows;

  /// No description provided for @modulesVariables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get modulesVariables;

  /// No description provided for @modulesEmojis.
  ///
  /// In en, this message translates to:
  /// **'Emojis'**
  String get modulesEmojis;

  /// No description provided for @modulesScheduler.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get modulesScheduler;

  /// No description provided for @modulesDescWorkflows.
  ///
  /// In en, this message translates to:
  /// **'Automate your actions and events'**
  String get modulesDescWorkflows;

  /// No description provided for @modulesDescVariables.
  ///
  /// In en, this message translates to:
  /// **'Remembered data: whole bot, server, member…'**
  String get modulesDescVariables;

  /// No description provided for @modulesDescEmojis.
  ///
  /// In en, this message translates to:
  /// **'The bot\'s application emojis'**
  String get modulesDescEmojis;

  /// No description provided for @modulesDescScheduler.
  ///
  /// In en, this message translates to:
  /// **'Runs a workflow every X minutes'**
  String get modulesDescScheduler;

  /// No description provided for @modulesDescHooks.
  ///
  /// In en, this message translates to:
  /// **'HTTP calls routed to a workflow'**
  String get modulesDescHooks;

  /// No description provided for @modulesDescTeam.
  ///
  /// In en, this message translates to:
  /// **'Collaborators and team chat'**
  String get modulesDescTeam;

  /// No description provided for @modulesDescGuilds.
  ///
  /// In en, this message translates to:
  /// **'Servers where the bot is present'**
  String get modulesDescGuilds;

  /// No description provided for @modulesDescDashboard.
  ///
  /// In en, this message translates to:
  /// **'Command usage over 24 h, 7 d, 30 d'**
  String get modulesDescDashboard;

  /// No description provided for @modulesDescReplay.
  ///
  /// In en, this message translates to:
  /// **'Step-by-step replays of command runs'**
  String get modulesDescReplay;

  /// No description provided for @modulesDescCopilot.
  ///
  /// In en, this message translates to:
  /// **'Assistant to build your commands'**
  String get modulesDescCopilot;

  /// No description provided for @beginnerOnHint.
  ///
  /// In en, this message translates to:
  /// **'Showing essential tabs only'**
  String get beginnerOnHint;

  /// No description provided for @beginnerOffHint.
  ///
  /// In en, this message translates to:
  /// **'Showing all features'**
  String get beginnerOffHint;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get commonRefresh;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get loadError;

  /// No description provided for @comingSoonBody.
  ///
  /// In en, this message translates to:
  /// **'This section is coming soon to Studio. It is still available in the Bot Creator app.'**
  String get comingSoonBody;

  /// No description provided for @comingSoonShort.
  ///
  /// In en, this message translates to:
  /// **'Coming soon to Studio.'**
  String get comingSoonShort;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Studio'**
  String get appTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Discord to access your bots. Studio always requires a valid sign-in.'**
  String get loginSubtitle;

  /// No description provided for @loginDiscord.
  ///
  /// In en, this message translates to:
  /// **'Connect with Discord'**
  String get loginDiscord;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Discord'**
  String get accountSignedIn;

  /// No description provided for @accountSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in with Discord: {name}'**
  String accountSignedInAs(String name);

  /// No description provided for @accountPlanPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium plan'**
  String get accountPlanPremium;

  /// No description provided for @accountPlanFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan: manage your subscription from the mobile app.'**
  String get accountPlanFree;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @botsOverline.
  ///
  /// In en, this message translates to:
  /// **'My projects'**
  String get botsOverline;

  /// No description provided for @botsTitle.
  ///
  /// In en, this message translates to:
  /// **'My bots'**
  String get botsTitle;

  /// No description provided for @botsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a bot'**
  String get botsCreate;

  /// No description provided for @botsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get botsManage;

  /// No description provided for @botStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get botStop;

  /// No description provided for @botStart.
  ///
  /// In en, this message translates to:
  /// **'Start Bot'**
  String get botStart;

  /// No description provided for @botsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any apps yet.'**
  String get botsEmptyTitle;

  /// No description provided for @botsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Create your first bot from the Bot Creator app: it will show up here.'**
  String get botsEmptyHint;

  /// No description provided for @hostingIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'Hosting included'**
  String get hostingIncludedTitle;

  /// No description provided for @hostingIncludedValue.
  ///
  /// In en, this message translates to:
  /// **'Unlimited with your subscription'**
  String get hostingIncludedValue;

  /// No description provided for @hostingRemainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get hostingRemainingTitle;

  /// No description provided for @hostingExpired.
  ///
  /// In en, this message translates to:
  /// **'Hosting expired'**
  String get hostingExpired;

  /// No description provided for @hostingSessionActive.
  ///
  /// In en, this message translates to:
  /// **'Active session'**
  String get hostingSessionActive;

  /// No description provided for @hostingSessionActiveOnline.
  ///
  /// In en, this message translates to:
  /// **'Active session (online)'**
  String get hostingSessionActiveOnline;

  /// No description provided for @hostingPreservedTitle.
  ///
  /// In en, this message translates to:
  /// **'Time preserved'**
  String get hostingPreservedTitle;

  /// No description provided for @hostingReserve.
  ///
  /// In en, this message translates to:
  /// **'Reserve: {time}'**
  String hostingReserve(String time);

  /// No description provided for @hostingReserveAvailable.
  ///
  /// In en, this message translates to:
  /// **'Banked time (paused)'**
  String get hostingReserveAvailable;

  /// No description provided for @hostingPreservedDetail.
  ///
  /// In en, this message translates to:
  /// **'Time is preserved while the bot is stopped.'**
  String get hostingPreservedDetail;

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, String minutes);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @createBotToken.
  ///
  /// In en, this message translates to:
  /// **'Discord bot token'**
  String get createBotToken;

  /// No description provided for @createBotTokenHint.
  ///
  /// In en, this message translates to:
  /// **'It is sent over HTTPS to the Bot Creator server and never kept in the browser.'**
  String get createBotTokenHint;

  /// No description provided for @createBotValidNamed.
  ///
  /// In en, this message translates to:
  /// **'Valid token: {name}'**
  String createBotValidNamed(String name);

  /// No description provided for @createBotValidId.
  ///
  /// In en, this message translates to:
  /// **'Valid token (ID {id})'**
  String createBotValidId(String id);

  /// No description provided for @createBotSamplePing.
  ///
  /// In en, this message translates to:
  /// **'Add a sample /ping command'**
  String get createBotSamplePing;

  /// No description provided for @createBotBusy.
  ///
  /// In en, this message translates to:
  /// **'Creating the bot: this can take up to two minutes. Do not close this page.'**
  String get createBotBusy;

  /// No description provided for @createBotVerify.
  ///
  /// In en, this message translates to:
  /// **'Check token'**
  String get createBotVerify;

  /// No description provided for @createBotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create bot'**
  String get createBotSubmit;

  /// No description provided for @createBotSyncBusy.
  ///
  /// In en, this message translates to:
  /// **'This bot is already being synchronized. Please wait a few minutes.'**
  String get createBotSyncBusy;

  /// No description provided for @createBotNoId.
  ///
  /// In en, this message translates to:
  /// **'Could not read the bot ID from this token.'**
  String get createBotNoId;

  /// No description provided for @overviewLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get overviewLogs;

  /// No description provided for @overviewLogsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Logs unavailable: {error}'**
  String overviewLogsUnavailable(String error);

  /// No description provided for @overviewNoLogs.
  ///
  /// In en, this message translates to:
  /// **'No logs yet.'**
  String get overviewNoLogs;

  /// No description provided for @commandsSearch.
  ///
  /// In en, this message translates to:
  /// **'Search commands...'**
  String get commandsSearch;

  /// No description provided for @commandsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No commands yet. Create one from the Bot Creator app.'**
  String get commandsEmpty;

  /// No description provided for @commandsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No commands match the current filters.'**
  String get commandsNoMatch;

  /// No description provided for @premiumHint.
  ///
  /// In en, this message translates to:
  /// **'Your account is on the free plan: subscriptions are activated from the mobile app (Studio shows no ads or purchases).'**
  String get premiumHint;

  /// No description provided for @featureSchedulerTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduler triggers'**
  String get featureSchedulerTitle;

  /// No description provided for @featureSchedulerDesc.
  ///
  /// In en, this message translates to:
  /// **'Run workflows automatically every X minutes (up to 10 active).'**
  String get featureSchedulerDesc;

  /// No description provided for @featureAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Premium analytics'**
  String get featureAnalyticsTitle;

  /// No description provided for @featureAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Unlock error rate, latency percentiles, and locale insights.'**
  String get featureAnalyticsDesc;

  /// No description provided for @featureHooksTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbound webhooks'**
  String get featureHooksTitle;

  /// No description provided for @featureHooksDesc.
  ///
  /// In en, this message translates to:
  /// **'Create secure webhook endpoints and route calls to workflows.'**
  String get featureHooksDesc;

  /// No description provided for @featureReplayTitle.
  ///
  /// In en, this message translates to:
  /// **'Visual debug replay'**
  String get featureReplayTitle;

  /// No description provided for @featureReplayDesc.
  ///
  /// In en, this message translates to:
  /// **'Record and replay command actions step by step for debugging.'**
  String get featureReplayDesc;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get commonSaved;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @deleteIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action is permanent.'**
  String get deleteIrreversible;

  /// No description provided for @deleteNamedTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteNamedTitle(String name);

  /// No description provided for @commandNew.
  ///
  /// In en, this message translates to:
  /// **'New command'**
  String get commandNew;

  /// No description provided for @commandSaved.
  ///
  /// In en, this message translates to:
  /// **'Command saved.'**
  String get commandSaved;

  /// No description provided for @commandChangedElsewhere.
  ///
  /// In en, this message translates to:
  /// **'This bot was modified elsewhere (app or another session). Reload the command before saving.'**
  String get commandChangedElsewhere;

  /// No description provided for @scriptEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit script'**
  String get scriptEdit;

  /// No description provided for @commandTriggerHybrid.
  ///
  /// In en, this message translates to:
  /// **'Slash + text message'**
  String get commandTriggerHybrid;

  /// No description provided for @workflowNew.
  ///
  /// In en, this message translates to:
  /// **'New workflow'**
  String get workflowNew;

  /// No description provided for @workflowsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workflows. Create one to reuse a sequence of actions or react to an event.'**
  String get workflowsEmpty;

  /// No description provided for @workflowSaved.
  ///
  /// In en, this message translates to:
  /// **'Workflow saved.'**
  String get workflowSaved;

  /// No description provided for @workflowDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Commands that call this workflow will no longer find anything to run.'**
  String get workflowDeleteBody;

  /// No description provided for @workflowTypeGeneral.
  ///
  /// In en, this message translates to:
  /// **'General (called by a command)'**
  String get workflowTypeGeneral;

  /// No description provided for @workflowCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get workflowCategory;

  /// No description provided for @workflowScriptNotice.
  ///
  /// In en, this message translates to:
  /// **'This workflow is written in {mode}: Studio only edits visual workflows. It stays saved as is.'**
  String workflowScriptNotice(String mode);

  /// No description provided for @variablesGlobalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Data remembered for the whole bot.'**
  String get variablesGlobalSubtitle;

  /// No description provided for @variablesScopedHint.
  ///
  /// In en, this message translates to:
  /// **'A definition sets the default value; each server, channel or member then keeps its own value.'**
  String get variablesScopedHint;

  /// No description provided for @variableScopedRemoveNote.
  ///
  /// In en, this message translates to:
  /// **'The definition is removed; values already stored are not erased.'**
  String get variableScopedRemoveNote;

  /// No description provided for @copilotNoCredits.
  ///
  /// In en, this message translates to:
  /// **'Not enough AI credits. Top them up from the mobile app.'**
  String get copilotNoCredits;

  /// No description provided for @copilotChatTooLong.
  ///
  /// In en, this message translates to:
  /// **'This conversation is too long: start a new one.'**
  String get copilotChatTooLong;

  /// No description provided for @copilotUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The Copilot is unavailable right now.'**
  String get copilotUnavailable;

  /// No description provided for @copilotGenerationFailed.
  ///
  /// In en, this message translates to:
  /// **'Generation failed.'**
  String get copilotGenerationFailed;

  /// No description provided for @copilotDeleteChat.
  ///
  /// In en, this message translates to:
  /// **'Delete conversation'**
  String get copilotDeleteChat;

  /// No description provided for @copilotWants.
  ///
  /// In en, this message translates to:
  /// **'The Copilot wants to: {tool}'**
  String copilotWants(String tool);

  /// No description provided for @dashboardRuns.
  ///
  /// In en, this message translates to:
  /// **'Executions'**
  String get dashboardRuns;

  /// No description provided for @dashboardSinceStart.
  ///
  /// In en, this message translates to:
  /// **'Since the start'**
  String get dashboardSinceStart;

  /// No description provided for @dashboardLatencyP50P95.
  ///
  /// In en, this message translates to:
  /// **'Latency P50 / P95'**
  String get dashboardLatencyP50P95;

  /// No description provided for @dashboardActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get dashboardActivity;

  /// No description provided for @dashboardLanguages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get dashboardLanguages;

  /// No description provided for @dashboardNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No executions in this period.'**
  String get dashboardNoRuns;

  /// No description provided for @dashboardNoActivity.
  ///
  /// In en, this message translates to:
  /// **'No activity in this period.'**
  String get dashboardNoActivity;

  /// No description provided for @dashboardOneExecution.
  ///
  /// In en, this message translates to:
  /// **'1 execution'**
  String get dashboardOneExecution;

  /// No description provided for @dashboardAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String dashboardAgoDays(int days);

  /// No description provided for @dashboardAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h ago'**
  String dashboardAgoHours(int hours);

  /// No description provided for @dashboardErrorRateOf.
  ///
  /// In en, this message translates to:
  /// **'{rate} % errors'**
  String dashboardErrorRateOf(String rate);

  /// No description provided for @dashboardLatencyPercentiles.
  ///
  /// In en, this message translates to:
  /// **'P50 {p50} ms · P95 {p95} ms'**
  String dashboardLatencyPercentiles(int p50, int p95);

  /// No description provided for @dashboardLatencyNone.
  ///
  /// In en, this message translates to:
  /// **'latency —'**
  String get dashboardLatencyNone;

  /// No description provided for @botStopFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not stop the bot'**
  String get botStopFailed;

  /// No description provided for @botStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not start the bot'**
  String get botStartFailed;

  /// No description provided for @refusalNoFreeTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hosting time used up'**
  String get refusalNoFreeTimeTitle;

  /// No description provided for @refusalNoFreeTimeBody.
  ///
  /// In en, this message translates to:
  /// **'This bot has no free hosting time left. Watch an ad from the mobile app to earn some, or go Premium. Studio offers no ads or purchases.'**
  String get refusalNoFreeTimeBody;

  /// No description provided for @authSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please sign in again.'**
  String get authSessionExpired;

  /// No description provided for @authDiscordRefused.
  ///
  /// In en, this message translates to:
  /// **'Discord sign-in refused ({reason}).'**
  String authDiscordRefused(String reason);

  /// No description provided for @authInvalidResponse.
  ///
  /// In en, this message translates to:
  /// **'Invalid sign-in response. Please try again.'**
  String get authInvalidResponse;

  /// No description provided for @validationCommandNameFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid name: lowercase letters, digits, “-” and “_” only, no spaces.'**
  String get validationCommandNameFormat;

  /// No description provided for @validationDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'The description must be at most {max} characters.'**
  String validationDescriptionTooLong(int max);

  /// No description provided for @validationWorkflowNameRequired.
  ///
  /// In en, this message translates to:
  /// **'The workflow name is required.'**
  String get validationWorkflowNameRequired;

  /// No description provided for @validationWorkflowNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'The name must be at most {max} characters.'**
  String validationWorkflowNameTooLong(int max);

  /// No description provided for @validationWorkflowTooManyBlocks.
  ///
  /// In en, this message translates to:
  /// **'At most {max} blocks per workflow.'**
  String validationWorkflowTooManyBlocks(int max);

  /// No description provided for @validationOptionNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Option “{name}”: lowercase letters, digits, “-” and “_”, 32 characters at most.'**
  String validationOptionNameInvalid(String name);

  /// No description provided for @validationOptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Option “{name}”: description required (100 characters at most).'**
  String validationOptionDescription(String name);

  /// No description provided for @validationOptionRequiredOrder.
  ///
  /// In en, this message translates to:
  /// **'Required options must come before optional ones (“{name}”).'**
  String validationOptionRequiredOrder(String name);

  /// No description provided for @schedulerPremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'The scheduler is reserved for Premium accounts. The subscription is managed in the app.'**
  String get schedulerPremiumOnly;

  /// No description provided for @webhooksPremiumOnly.
  ///
  /// In en, this message translates to:
  /// **'Inbound webhooks are reserved for Premium accounts. The subscription is managed in the app.'**
  String get webhooksPremiumOnly;
}

class _StudioLocalizationsDelegate
    extends LocalizationsDelegate<StudioLocalizations> {
  const _StudioLocalizationsDelegate();

  @override
  Future<StudioLocalizations> load(Locale locale) {
    return SynchronousFuture<StudioLocalizations>(
      lookupStudioLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'fr',
    'ja',
    'pt',
    'tr',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_StudioLocalizationsDelegate old) => false;
}

StudioLocalizations lookupStudioLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return StudioLocalizationsDe();
    case 'en':
      return StudioLocalizationsEn();
    case 'fr':
      return StudioLocalizationsFr();
    case 'ja':
      return StudioLocalizationsJa();
    case 'pt':
      return StudioLocalizationsPt();
    case 'tr':
      return StudioLocalizationsTr();
  }

  throw FlutterError(
    'StudioLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
