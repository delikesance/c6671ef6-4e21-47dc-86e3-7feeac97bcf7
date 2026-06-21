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

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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

  /// Add ELSE IF
  ///
  /// In en, this message translates to:
  /// **'Add ELSE IF'**
  String get action_add_else_if;

  /// Add header
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get action_add_header;

  /// Add new item
  ///
  /// In en, this message translates to:
  /// **'Add new item'**
  String get action_add_new_item;

  /// Advanced settings
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get action_advanced_settings;

  /// … and {count} more
  ///
  /// In en, this message translates to:
  /// **'… and {count} more'**
  String action_and_more(int count);

  /// Bulk import (Paste headers like Key: Value)
  ///
  /// In en, this message translates to:
  /// **'Bulk import (Paste headers like Key: Value)'**
  String get action_bulk_import_hint;

  /// Cannot format: Invalid JSON
  ///
  /// In en, this message translates to:
  /// **'Cannot format: Invalid JSON'**
  String get action_cannot_format_json;

  /// Channels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get action_category_channels;

  /// Components
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get action_category_components;

  /// Guild & Members
  ///
  /// In en, this message translates to:
  /// **'Guild & Members'**
  String get action_category_guild_members;

  /// HTTP & Variables
  ///
  /// In en, this message translates to:
  /// **'HTTP & Variables'**
  String get action_category_http_variables;

  /// Interactions
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get action_category_interactions;

  /// Logic & Flow
  ///
  /// In en, this message translates to:
  /// **'Logic & Flow'**
  String get action_category_logic_flow;

  /// Messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get action_category_messages;

  /// Moderation
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get action_category_moderation;

  /// Lavalink music key: action_category_music
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get action_category_music;

  /// Reactions
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get action_category_reactions;

  /// Webhooks
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get action_category_webhooks;

  /// Workflows
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get action_category_workflows;

  /// Choose {name}
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String action_choose_param(String name);

  /// Clear all
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get action_clear_all;

  /// Condition Value
  ///
  /// In en, this message translates to:
  /// **'Condition Value'**
  String get action_condition_value;

  /// Condition Variable
  ///
  /// In en, this message translates to:
  /// **'Condition Variable'**
  String get action_condition_variable;

  /// Add an emoji reaction to a message
  ///
  /// In en, this message translates to:
  /// **'Add an emoji reaction to a message'**
  String get action_description_addReaction;

  /// Assign a role to a member
  ///
  /// In en, this message translates to:
  /// **'Assign a role to a member'**
  String get action_description_addRole;

  /// Action description for addThreadMember
  ///
  /// In en, this message translates to:
  /// **'Add a member to a thread'**
  String get action_description_addThreadMember;

  /// Action description for appendArrayElement
  ///
  /// In en, this message translates to:
  /// **'Append a new element into a global or scoped JSON array'**
  String get action_description_appendArrayElement;

  /// Action description for attachImage
  ///
  /// In en, this message translates to:
  /// **'Attach an image file to the message response (URL, data URL, or base64)'**
  String get action_description_attachImage;

  /// Permanently ban a user from the server
  ///
  /// In en, this message translates to:
  /// **'Permanently ban a user from the server'**
  String get action_description_banUser;

  /// Action description for calculate
  ///
  /// In en, this message translates to:
  /// **'Perform math operations and store result'**
  String get action_description_calculate;

  /// Action description for canvasCreateBlock
  ///
  /// In en, this message translates to:
  /// **'Create a blank image canvas'**
  String get action_description_canvasCreateBlock;

  /// Action description for canvasDrawCircleBlock
  ///
  /// In en, this message translates to:
  /// **'Draw a circle on the image canvas'**
  String get action_description_canvasDrawCircleBlock;

  /// Action description for canvasDrawLineBlock
  ///
  /// In en, this message translates to:
  /// **'Draw a line on the canvas'**
  String get action_description_canvasDrawLineBlock;

  /// Action description for canvasDrawRectBlock
  ///
  /// In en, this message translates to:
  /// **'Draw a rectangle on the image canvas'**
  String get action_description_canvasDrawRectBlock;

  /// Action description for canvasDrawTextBlock
  ///
  /// In en, this message translates to:
  /// **'Draw text on the image canvas with styling options'**
  String get action_description_canvasDrawTextBlock;

  /// Action description for canvasLoadImageBlock
  ///
  /// In en, this message translates to:
  /// **'Load an image from a URL or source into canvas'**
  String get action_description_canvasLoadImageBlock;

  /// Remove all reactions from a message
  ///
  /// In en, this message translates to:
  /// **'Remove all reactions from a message'**
  String get action_description_clearAllReactions;

  /// Apply a command cooldown for the user or server
  ///
  /// In en, this message translates to:
  /// **'Apply a command cooldown for the user or server'**
  String get action_description_cooldown;

  /// Action description for createAutoModRule
  ///
  /// In en, this message translates to:
  /// **'Create a guild auto-moderation rule'**
  String get action_description_createAutoModRule;

  /// Action description for createChannel
  ///
  /// In en, this message translates to:
  /// **'Create a new channel'**
  String get action_description_createChannel;

  /// Action description for createEmoji
  ///
  /// In en, this message translates to:
  /// **'Create a guild emoji from image data'**
  String get action_description_createEmoji;

  /// Action description for createInvite
  ///
  /// In en, this message translates to:
  /// **'Create a new invite link for a channel'**
  String get action_description_createInvite;

  /// Action description for createPoll
  ///
  /// In en, this message translates to:
  /// **'Create a poll message in a channel'**
  String get action_description_createPoll;

  /// Action description for createThread
  ///
  /// In en, this message translates to:
  /// **'Create a thread in a supported text channel'**
  String get action_description_createThread;

  /// Action description for debugProfile
  ///
  /// In en, this message translates to:
  /// **'Generate execution profile and diagnostics info'**
  String get action_description_debugProfile;

  /// Action description for deferInteraction
  ///
  /// In en, this message translates to:
  /// **'Defer the interaction response to prevent Discord timeout'**
  String get action_description_deferInteraction;

  /// Action description for deleteAutoModRule
  ///
  /// In en, this message translates to:
  /// **'Delete an auto-moderation rule'**
  String get action_description_deleteAutoModRule;

  /// Action description for deleteChannelPermission
  ///
  /// In en, this message translates to:
  /// **'Delete a channel permission overwrite'**
  String get action_description_deleteChannelPermission;

  /// Action description for deleteEmoji
  ///
  /// In en, this message translates to:
  /// **'Delete a guild emoji'**
  String get action_description_deleteEmoji;

  /// Action description for deleteInvite
  ///
  /// In en, this message translates to:
  /// **'Delete an existing invite by code'**
  String get action_description_deleteInvite;

  /// Delete one or more messages
  ///
  /// In en, this message translates to:
  /// **'Delete one or more messages'**
  String get action_description_deleteMessages;

  /// Delete the message that triggered this command
  ///
  /// In en, this message translates to:
  /// **'Delete the message that triggered this command'**
  String get action_description_deleteTrigger;

  /// Action description for deleteWebhook
  ///
  /// In en, this message translates to:
  /// **'Delete a webhook'**
  String get action_description_deleteWebhook;

  /// Action description for disconnectFromVoice
  ///
  /// In en, this message translates to:
  /// **'Disconnect a member from voice'**
  String get action_description_disconnectFromVoice;

  /// Action description for editChannelPermissions
  ///
  /// In en, this message translates to:
  /// **'Create or update channel permission overwrites'**
  String get action_description_editChannelPermissions;

  /// Action description for editComponentV2
  ///
  /// In en, this message translates to:
  /// **'Edit existing components'**
  String get action_description_editComponentV2;

  /// Action description for editInteractionMessage
  ///
  /// In en, this message translates to:
  /// **'Edit the deferred or original interaction response'**
  String get action_description_editInteractionMessage;

  /// Edit an existing message
  ///
  /// In en, this message translates to:
  /// **'Edit an existing message'**
  String get action_description_editMessage;

  /// Action description for editWebhook
  ///
  /// In en, this message translates to:
  /// **'Edit an existing Webhook'**
  String get action_description_editWebhook;

  /// Action description for endPoll
  ///
  /// In en, this message translates to:
  /// **'End an active poll message immediately'**
  String get action_description_endPoll;

  /// Action description for forLoop
  ///
  /// In en, this message translates to:
  /// **'Loop through a range of numbers (for loop)'**
  String get action_description_forLoop;

  /// Action description for getGlobalVariable
  ///
  /// In en, this message translates to:
  /// **'Read a global variable and inject into runtime variables'**
  String get action_description_getGlobalVariable;

  /// Action description for getGuildOnboarding
  ///
  /// In en, this message translates to:
  /// **'Fetch current guild onboarding configuration'**
  String get action_description_getGuildOnboarding;

  /// Action description for getInvite
  ///
  /// In en, this message translates to:
  /// **'Fetch invite information by code'**
  String get action_description_getInvite;

  /// Action description for getMember
  ///
  /// In en, this message translates to:
  /// **'Get member information'**
  String get action_description_getMember;

  /// Action description for getMessage
  ///
  /// In en, this message translates to:
  /// **'Fetch a message and expose its fields'**
  String get action_description_getMessage;

  /// Lavalink music key: action_description_getMusicInfo
  ///
  /// In en, this message translates to:
  /// **'Retrieve info about the currently playing track'**
  String get action_description_getMusicInfo;

  /// Action description for getScopedVariable
  ///
  /// In en, this message translates to:
  /// **'Read a scoped variable and inject into runtime variables'**
  String get action_description_getScopedVariable;

  /// Action description for getWebhook
  ///
  /// In en, this message translates to:
  /// **'Get Webhook information by ID'**
  String get action_description_getWebhook;

  /// Action description for httpRequest
  ///
  /// In en, this message translates to:
  /// **'Send HTTP request with dynamic URL, method, headers and body'**
  String get action_description_httpRequest;

  /// Action description for ifBlock
  ///
  /// In en, this message translates to:
  /// **'Conditional branching: run different actions based on a condition'**
  String get action_description_ifBlock;

  /// Jump to an action
  ///
  /// In en, this message translates to:
  /// **'Jump to a specific action by key, ID, or position'**
  String get action_description_jumpToAction;

  /// Lavalink music key: action_description_joinVoice
  ///
  /// In en, this message translates to:
  /// **'Join a voice channel'**
  String get action_description_joinVoice;

  /// Action description for jsonForEachLoop
  ///
  /// In en, this message translates to:
  /// **'Loop through each element of a JSON array or object (forEach)'**
  String get action_description_jsonForEachLoop;

  /// Kick a member from the server
  ///
  /// In en, this message translates to:
  /// **'Kick a member from the server'**
  String get action_description_kickUser;

  /// Action description for leaveGuild
  ///
  /// In en, this message translates to:
  /// **'Make the bot leave the guild/server'**
  String get action_description_leaveGuild;

  /// Lavalink music key: action_description_leaveVoice
  ///
  /// In en, this message translates to:
  /// **'Leave the voice channel and destroy the player'**
  String get action_description_leaveVoice;

  /// Action description for listAutoModRules
  ///
  /// In en, this message translates to:
  /// **'List all auto-moderation rules in guild'**
  String get action_description_listAutoModRules;

  /// Action description for listMembers
  ///
  /// In en, this message translates to:
  /// **'List members in a guild with options'**
  String get action_description_listMembers;

  /// Action description for listScopedVariableIndex
  ///
  /// In en, this message translates to:
  /// **'List indexed scoped values sorted by value with offset and limit'**
  String get action_description_listScopedVariableIndex;

  /// Action description for listWebhooks
  ///
  /// In en, this message translates to:
  /// **'List all Webhooks in a channel or guild'**
  String get action_description_listWebhooks;

  /// Action description for listenAndExecute
  ///
  /// In en, this message translates to:
  /// **'Register a workflow to run when a button is clicked, select menu is used, or modal is submitted'**
  String get action_description_listenAndExecute;

  /// Action description for listenForButtonClick
  ///
  /// In en, this message translates to:
  /// **'Register a workflow to run when a button is clicked'**
  String get action_description_listenForButtonClick;

  /// Action description for listenForModalSubmit
  ///
  /// In en, this message translates to:
  /// **'Register a workflow to run when a modal is submitted'**
  String get action_description_listenForModalSubmit;

  /// Action description for listenForSelectMenu
  ///
  /// In en, this message translates to:
  /// **'Register a workflow to run when a select menu is used'**
  String get action_description_listenForSelectMenu;

  /// Action description for log
  ///
  /// In en, this message translates to:
  /// **'Print or store diagnostic message to action logs'**
  String get action_description_log;

  /// Action description for moveToVoiceChannel
  ///
  /// In en, this message translates to:
  /// **'Move a member to a specific voice channel'**
  String get action_description_moveToVoiceChannel;

  /// Temporarily exclude (timeout) a member
  ///
  /// In en, this message translates to:
  /// **'Temporarily exclude (timeout) a member'**
  String get action_description_muteUser;

  /// Lavalink music key: action_description_pauseMusic
  ///
  /// In en, this message translates to:
  /// **'Pause the current track'**
  String get action_description_pauseMusic;

  /// Action description for pinMessage
  ///
  /// In en, this message translates to:
  /// **'Pin a message in a channel'**
  String get action_description_pinMessage;

  /// Lavalink music key: action_description_playMusic
  ///
  /// In en, this message translates to:
  /// **'Play a track by search query or URL'**
  String get action_description_playMusic;

  /// Action description for queryArray
  ///
  /// In en, this message translates to:
  /// **'Filter, sort and page any runtime JSON array'**
  String get action_description_queryArray;

  /// Pick a random item from a list and store it in a variable
  ///
  /// In en, this message translates to:
  /// **'Pick a random item from a list and store it in a variable'**
  String get action_description_randomChoice;

  /// Action description for registerGuildCommands
  ///
  /// In en, this message translates to:
  /// **'Register application commands to a guild'**
  String get action_description_registerGuildCommands;

  /// Action description for removeArrayElement
  ///
  /// In en, this message translates to:
  /// **'Remove one element from a global or scoped JSON array by index'**
  String get action_description_removeArrayElement;

  /// Action description for removeChannel
  ///
  /// In en, this message translates to:
  /// **'Delete a channel'**
  String get action_description_removeChannel;

  /// Action description for removeGlobalVariable
  ///
  /// In en, this message translates to:
  /// **'Delete a global variable'**
  String get action_description_removeGlobalVariable;

  /// Remove a reaction from a message
  ///
  /// In en, this message translates to:
  /// **'Remove a reaction from a message'**
  String get action_description_removeReaction;

  /// Remove a role from a member
  ///
  /// In en, this message translates to:
  /// **'Remove a role from a member'**
  String get action_description_removeRole;

  /// Action description for removeScopedVariable
  ///
  /// In en, this message translates to:
  /// **'Delete a scoped variable'**
  String get action_description_removeScopedVariable;

  /// Action description for removeThreadMember
  ///
  /// In en, this message translates to:
  /// **'Remove a member from a thread'**
  String get action_description_removeThreadMember;

  /// Action description for renameScopedVariable
  ///
  /// In en, this message translates to:
  /// **'Rename a scoped variable key'**
  String get action_description_renameScopedVariable;

  /// Action description for respondWithAutocomplete
  ///
  /// In en, this message translates to:
  /// **'Reply to a Discord autocomplete interaction with up to 25 dynamic choices'**
  String get action_description_respondWithAutocomplete;

  /// Action description for respondWithComponentV2
  ///
  /// In en, this message translates to:
  /// **'Reply to command with buttons/select menus'**
  String get action_description_respondWithComponentV2;

  /// Action description for respondWithMessage
  ///
  /// In en, this message translates to:
  /// **'Reply to command with a normal message'**
  String get action_description_respondWithMessage;

  /// Action description for respondWithModal
  ///
  /// In en, this message translates to:
  /// **'Show a modal dialog to the user'**
  String get action_description_respondWithModal;

  /// Lavalink music key: action_description_resumeMusic
  ///
  /// In en, this message translates to:
  /// **'Resume a paused track'**
  String get action_description_resumeMusic;

  /// Action description for runBdfdScript
  ///
  /// In en, this message translates to:
  /// **'Compile and run a BDFD script inline as workflow actions'**
  String get action_description_runBdfdScript;

  /// Action description for runWorkflow
  ///
  /// In en, this message translates to:
  /// **'Execute a saved workflow (supports entry point + arguments)'**
  String get action_description_runWorkflow;

  /// Action description for runtimeImageBlock
  ///
  /// In en, this message translates to:
  /// **'Run block of image canvas processing actions'**
  String get action_description_runtimeImageBlock;

  /// Action description for runtimeJsonBlock
  ///
  /// In en, this message translates to:
  /// **'Run block of JSON processing actions'**
  String get action_description_runtimeJsonBlock;

  /// Lavalink music key: action_description_seekMusic
  ///
  /// In en, this message translates to:
  /// **'Seek to a position in the current track'**
  String get action_description_seekMusic;

  /// Action description for sendComponentV2
  ///
  /// In en, this message translates to:
  /// **'Send interactive components'**
  String get action_description_sendComponentV2;

  /// Send a private message to a specific user
  ///
  /// In en, this message translates to:
  /// **'Send a private message to a specific user'**
  String get action_description_sendDm;

  /// Send a message to a specific channel
  ///
  /// In en, this message translates to:
  /// **'Send a message to a specific channel'**
  String get action_description_sendMessage;

  /// Action description for sendWebhook
  ///
  /// In en, this message translates to:
  /// **'Send message via Webhook'**
  String get action_description_sendWebhook;

  /// Action description for serverDeafenMember
  ///
  /// In en, this message translates to:
  /// **'Server-deafen or undeafen a member'**
  String get action_description_serverDeafenMember;

  /// Action description for serverMuteMember
  ///
  /// In en, this message translates to:
  /// **'Server-mute or unmute a member'**
  String get action_description_serverMuteMember;

  /// Action description for setGlobalVariable
  ///
  /// In en, this message translates to:
  /// **'Create or update a global variable for this bot'**
  String get action_description_setGlobalVariable;

  /// Lavalink music key: action_description_setMusicLoop
  ///
  /// In en, this message translates to:
  /// **'Enable or disable looping of the queue'**
  String get action_description_setMusicLoop;

  /// Lavalink music key: action_description_setMusicVolume
  ///
  /// In en, this message translates to:
  /// **'Set the player volume (0 to 200)'**
  String get action_description_setMusicVolume;

  /// Change a server member's nickname
  ///
  /// In en, this message translates to:
  /// **'Change a server member\'s nickname'**
  String get action_description_setNickname;

  /// Action description for setScopedVariable
  ///
  /// In en, this message translates to:
  /// **'Create or update a scoped variable (guild/user/channel/guildMember/message)'**
  String get action_description_setScopedVariable;

  /// Action description for setTemporaryVariable
  ///
  /// In en, this message translates to:
  /// **'Create or update a temporary variable in local execution'**
  String get action_description_setTemporaryVariable;

  /// Skip a number of actions
  ///
  /// In en, this message translates to:
  /// **'Skip a specified number of subsequent actions'**
  String get action_description_skipActions;

  /// Lavalink music key: action_description_skipMusic
  ///
  /// In en, this message translates to:
  /// **'Skip to the next track in the queue'**
  String get action_description_skipMusic;

  /// Set the slowmode duration for a channel
  ///
  /// In en, this message translates to:
  /// **'Set the slowmode duration for a channel'**
  String get action_description_slowmode;

  /// Immediately stop the execution of the current workflow
  ///
  /// In en, this message translates to:
  /// **'Immediately stop the execution of the current workflow'**
  String get action_description_stop;

  /// Lavalink music key: action_description_stopMusic
  ///
  /// In en, this message translates to:
  /// **'Stop playback and clear the queue'**
  String get action_description_stopMusic;

  /// Action description for stopUnless
  ///
  /// In en, this message translates to:
  /// **'Stop the workflow if a condition is not met (guard/filter)'**
  String get action_description_stopUnless;

  /// Revoke a user's ban
  ///
  /// In en, this message translates to:
  /// **'Revoke a user\'s ban'**
  String get action_description_unbanUser;

  /// Remove temporary exclusion from a member
  ///
  /// In en, this message translates to:
  /// **'Remove temporary exclusion from a member'**
  String get action_description_unmuteUser;

  /// Action description for unpinMessage
  ///
  /// In en, this message translates to:
  /// **'Unpin a message in a channel'**
  String get action_description_unpinMessage;

  /// Action description for unregisterGuildCommands
  ///
  /// In en, this message translates to:
  /// **'Unregister application commands from a guild'**
  String get action_description_unregisterGuildCommands;

  /// Action description for updateAutoMod
  ///
  /// In en, this message translates to:
  /// **'Update auto-moderation settings'**
  String get action_description_updateAutoMod;

  /// Action description for updateChannel
  ///
  /// In en, this message translates to:
  /// **'Update channel settings'**
  String get action_description_updateChannel;

  /// Action description for updateEmoji
  ///
  /// In en, this message translates to:
  /// **'Update guild emoji name or role access'**
  String get action_description_updateEmoji;

  /// Action description for updateGuild
  ///
  /// In en, this message translates to:
  /// **'Update guild settings'**
  String get action_description_updateGuild;

  /// Action description for updateGuildOnboarding
  ///
  /// In en, this message translates to:
  /// **'Update guild onboarding configuration'**
  String get action_description_updateGuildOnboarding;

  /// Action description for updateSelfUser
  ///
  /// In en, this message translates to:
  /// **'Update current bot user profile (username/avatar)'**
  String get action_description_updateSelfUser;

  /// Pause the workflow execution for a specific duration
  ///
  /// In en, this message translates to:
  /// **'Pause the workflow execution for a specific duration'**
  String get action_description_wait;

  /// Dynamic
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get action_dynamic;

  /// true/false or ((variable))
  ///
  /// In en, this message translates to:
  /// **'true/false or ((variable))'**
  String get action_dynamic_bool_hint;

  /// Dynamic {type} (supports ((...)))
  ///
  /// In en, this message translates to:
  /// **'Dynamic {type} (supports ((...)))'**
  String action_dynamic_id_hint(String type);

  /// Dynamic value (supports ((...)))
  ///
  /// In en, this message translates to:
  /// **'Dynamic value (supports ((...)))'**
  String get action_dynamic_multiselect_hint;

  /// Dynamic numeric suggestions
  ///
  /// In en, this message translates to:
  /// **'Dynamic numeric suggestions'**
  String get action_dynamic_numeric;

  /// Dynamic variable suggestions
  ///
  /// In en, this message translates to:
  /// **'Dynamic variable suggestions'**
  String get action_dynamic_variable;

  /// Edit {count}
  ///
  /// In en, this message translates to:
  /// **'Edit {count}'**
  String action_edit_nested(int count);

  /// Edit ({count})
  ///
  /// In en, this message translates to:
  /// **'Edit ({count})'**
  String action_edit_nested_parens(int count);

  /// Edit {name}
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String action_edit_param(String name);

  /// Edit Raw JSON
  ///
  /// In en, this message translates to:
  /// **'Edit Raw JSON'**
  String get action_edit_raw_json;

  /// ELSE IF {index} — actions
  ///
  /// In en, this message translates to:
  /// **'ELSE IF {index} — actions'**
  String action_else_if_label(int index);

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get action_error_continue;

  /// Stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get action_error_stop;

  /// Expression
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get action_expression;

  /// Format JSON
  ///
  /// In en, this message translates to:
  /// **'Format JSON'**
  String get action_format_json;

  /// #FFFFFF or rgb(255,255,255)
  ///
  /// In en, this message translates to:
  /// **'#FFFFFF or rgb(255,255,255)'**
  String get action_hint_color;

  /// Value to compare against
  ///
  /// In en, this message translates to:
  /// **'Value to compare against'**
  String get action_hint_condition_value;

  /// Use ((variableName)) or a runtime value
  ///
  /// In en, this message translates to:
  /// **'Use ((variableName)) or a runtime value'**
  String get action_hint_condition_var;

  /// Message to send if on cooldown (supports %time%)
  ///
  /// In en, this message translates to:
  /// **'Message to send if on cooldown (supports %time%)'**
  String get action_hint_cooldown_error;

  /// Duration (e.g. 10s, 5m)
  ///
  /// In en, this message translates to:
  /// **'Duration (e.g. 10s, 5m)'**
  String get action_hint_cooldown_time;

  /// e.g., 5m, 1h, 30s
  ///
  /// In en, this message translates to:
  /// **'e.g., 5m, 1h, 30s'**
  String get action_hint_duration;

  /// Emoji (e.g. 🪜) or <:name:id>
  ///
  /// In en, this message translates to:
  /// **'Emoji (e.g. 🪜) or <:name:id>'**
  String get action_hint_emoji;

  /// Enter {type}
  ///
  /// In en, this message translates to:
  /// **'Enter {type}'**
  String action_hint_enter_type(String type);

  /// List of choices (separated by ;)
  ///
  /// In en, this message translates to:
  /// **'List of choices (separated by ;)'**
  String get action_hint_random_choices;

  /// Variable name to store the result
  ///
  /// In en, this message translates to:
  /// **'Variable name to store the result'**
  String get action_hint_random_var;

  /// Select variable key
  ///
  /// In en, this message translates to:
  /// **'Select variable key'**
  String get action_hint_variable_key;

  /// Saved workflow name
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name'**
  String get action_hint_workflow;

  /// HTTP Headers (Key/Value pairs)
  ///
  /// In en, this message translates to:
  /// **'HTTP Headers (Key/Value pairs)'**
  String get action_http_headers_title;

  /// {count} paths parsed
  ///
  /// In en, this message translates to:
  /// **'{count} paths parsed'**
  String action_http_paths_parsed(int count);

  /// Response Body (Raw):
  ///
  /// In en, this message translates to:
  /// **'Response Body (Raw):'**
  String get action_http_response_body;

  /// Status: {status}
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String action_http_status(int status);

  /// Send Test Request & Auto-Detect Routes
  ///
  /// In en, this message translates to:
  /// **'Send Test Request & Auto-Detect Routes'**
  String get action_http_test_button;

  /// Test Request Results
  ///
  /// In en, this message translates to:
  /// **'Test Request Results'**
  String get action_http_test_title;

  /// JSON object editor (supports nested objects/arrays)
  ///
  /// In en, this message translates to:
  /// **'JSON object editor (supports nested objects/arrays)'**
  String get action_json_editor_hint;

  /// Action Key
  ///
  /// In en, this message translates to:
  /// **'Action Key'**
  String get action_key_field;

  /// Key / Value pairs
  ///
  /// In en, this message translates to:
  /// **'Key / Value pairs'**
  String get action_key_value_pairs;

  /// Literal
  ///
  /// In en, this message translates to:
  /// **'Literal'**
  String get action_literal;

  /// Loading keys...
  ///
  /// In en, this message translates to:
  /// **'Loading keys...'**
  String get action_loading_keys;

  /// Manage Variable Keys
  ///
  /// In en, this message translates to:
  /// **'Manage Variable Keys'**
  String get action_manage_variable_keys;

  /// Add Reaction
  ///
  /// In en, this message translates to:
  /// **'Add Reaction'**
  String get action_name_addReaction;

  /// Add Role
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get action_name_addRole;

  /// Add Thread Member
  ///
  /// In en, this message translates to:
  /// **'Add Thread Member'**
  String get action_name_addThreadMember;

  /// Append Array Element
  ///
  /// In en, this message translates to:
  /// **'Append Array Element'**
  String get action_name_appendArrayElement;

  /// Attach Image
  ///
  /// In en, this message translates to:
  /// **'Attach Image'**
  String get action_name_attachImage;

  /// Ban User
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get action_name_banUser;

  /// Calculate
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get action_name_calculate;

  /// Create Canvas
  ///
  /// In en, this message translates to:
  /// **'Create Canvas'**
  String get action_name_canvasCreateBlock;

  /// Draw Circle
  ///
  /// In en, this message translates to:
  /// **'Draw Circle'**
  String get action_name_canvasDrawCircleBlock;

  /// Action name for canvasDrawLineBlock
  ///
  /// In en, this message translates to:
  /// **'Draw Line'**
  String get action_name_canvasDrawLineBlock;

  /// Draw Rectangle
  ///
  /// In en, this message translates to:
  /// **'Draw Rectangle'**
  String get action_name_canvasDrawRectBlock;

  /// Draw Text
  ///
  /// In en, this message translates to:
  /// **'Draw Text'**
  String get action_name_canvasDrawTextBlock;

  /// Load Image
  ///
  /// In en, this message translates to:
  /// **'Load Image'**
  String get action_name_canvasLoadImageBlock;

  /// Clear All Reactions
  ///
  /// In en, this message translates to:
  /// **'Clear All Reactions'**
  String get action_name_clearAllReactions;

  /// Cooldown
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get action_name_cooldown;

  /// Create AutoMod Rule
  ///
  /// In en, this message translates to:
  /// **'Create AutoMod Rule'**
  String get action_name_createAutoModRule;

  /// Create Channel
  ///
  /// In en, this message translates to:
  /// **'Create Channel'**
  String get action_name_createChannel;

  /// Create Emoji
  ///
  /// In en, this message translates to:
  /// **'Create Emoji'**
  String get action_name_createEmoji;

  /// Create Invite
  ///
  /// In en, this message translates to:
  /// **'Create Invite'**
  String get action_name_createInvite;

  /// Create Poll
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get action_name_createPoll;

  /// Create Thread
  ///
  /// In en, this message translates to:
  /// **'Create Thread'**
  String get action_name_createThread;

  /// Debug Profile
  ///
  /// In en, this message translates to:
  /// **'Debug Profile'**
  String get action_name_debugProfile;

  /// Action name for deferInteraction
  ///
  /// In en, this message translates to:
  /// **'Defer Interaction'**
  String get action_name_deferInteraction;

  /// Delete AutoMod Rule
  ///
  /// In en, this message translates to:
  /// **'Delete AutoMod Rule'**
  String get action_name_deleteAutoModRule;

  /// Delete Channel Permission
  ///
  /// In en, this message translates to:
  /// **'Delete Channel Permission'**
  String get action_name_deleteChannelPermission;

  /// Delete Emoji
  ///
  /// In en, this message translates to:
  /// **'Delete Emoji'**
  String get action_name_deleteEmoji;

  /// Delete Invite
  ///
  /// In en, this message translates to:
  /// **'Delete Invite'**
  String get action_name_deleteInvite;

  /// Delete Messages
  ///
  /// In en, this message translates to:
  /// **'Delete Messages'**
  String get action_name_deleteMessages;

  /// Delete Trigger Message
  ///
  /// In en, this message translates to:
  /// **'Delete Trigger Message'**
  String get action_name_deleteTrigger;

  /// Delete Webhook
  ///
  /// In en, this message translates to:
  /// **'Delete Webhook'**
  String get action_name_deleteWebhook;

  /// Disconnect from Voice
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Voice'**
  String get action_name_disconnectFromVoice;

  /// Edit Channel Permissions
  ///
  /// In en, this message translates to:
  /// **'Edit Channel Permissions'**
  String get action_name_editChannelPermissions;

  /// Edit Component V2
  ///
  /// In en, this message translates to:
  /// **'Edit Component V2'**
  String get action_name_editComponentV2;

  /// Edit Interaction Message
  ///
  /// In en, this message translates to:
  /// **'Edit Interaction Message'**
  String get action_name_editInteractionMessage;

  /// Edit Message
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get action_name_editMessage;

  /// Edit Webhook
  ///
  /// In en, this message translates to:
  /// **'Edit Webhook'**
  String get action_name_editWebhook;

  /// End Poll
  ///
  /// In en, this message translates to:
  /// **'End Poll'**
  String get action_name_endPoll;

  /// For Loop
  ///
  /// In en, this message translates to:
  /// **'For Loop'**
  String get action_name_forLoop;

  /// Get Global Variable
  ///
  /// In en, this message translates to:
  /// **'Get Global Variable'**
  String get action_name_getGlobalVariable;

  /// Get Guild Onboarding
  ///
  /// In en, this message translates to:
  /// **'Get Guild Onboarding'**
  String get action_name_getGuildOnboarding;

  /// Get Invite
  ///
  /// In en, this message translates to:
  /// **'Get Invite'**
  String get action_name_getInvite;

  /// Get Member
  ///
  /// In en, this message translates to:
  /// **'Get Member'**
  String get action_name_getMember;

  /// Get Message
  ///
  /// In en, this message translates to:
  /// **'Get Message'**
  String get action_name_getMessage;

  /// Lavalink music key: action_name_getMusicInfo
  ///
  /// In en, this message translates to:
  /// **'Get Music Info'**
  String get action_name_getMusicInfo;

  /// Get Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Get Scoped Variable'**
  String get action_name_getScopedVariable;

  /// Get Webhook
  ///
  /// In en, this message translates to:
  /// **'Get Webhook'**
  String get action_name_getWebhook;

  /// HTTP Request
  ///
  /// In en, this message translates to:
  /// **'HTTP Request'**
  String get action_name_httpRequest;

  /// IF / ELSE Block
  ///
  /// In en, this message translates to:
  /// **'IF / ELSE Block'**
  String get action_name_ifBlock;

  /// Jump to an action
  ///
  /// In en, this message translates to:
  /// **'Jump to Action'**
  String get action_name_jumpToAction;

  /// Lavalink music key: action_name_joinVoice
  ///
  /// In en, this message translates to:
  /// **'Join Voice Channel'**
  String get action_name_joinVoice;

  /// JSON For Each Loop
  ///
  /// In en, this message translates to:
  /// **'JSON For Each Loop'**
  String get action_name_jsonForEachLoop;

  /// Kick User
  ///
  /// In en, this message translates to:
  /// **'Kick User'**
  String get action_name_kickUser;

  /// Action name for leaveGuild
  ///
  /// In en, this message translates to:
  /// **'Leave Server'**
  String get action_name_leaveGuild;

  /// Lavalink music key: action_name_leaveVoice
  ///
  /// In en, this message translates to:
  /// **'Leave Voice Channel'**
  String get action_name_leaveVoice;

  /// List AutoMod Rules
  ///
  /// In en, this message translates to:
  /// **'List AutoMod Rules'**
  String get action_name_listAutoModRules;

  /// List Members
  ///
  /// In en, this message translates to:
  /// **'List Members'**
  String get action_name_listMembers;

  /// List Scoped Variable Index
  ///
  /// In en, this message translates to:
  /// **'List Scoped Variable Index'**
  String get action_name_listScopedVariableIndex;

  /// List Webhooks
  ///
  /// In en, this message translates to:
  /// **'List Webhooks'**
  String get action_name_listWebhooks;

  /// Action name for listenAndExecute
  ///
  /// In en, this message translates to:
  /// **'Listen and Execute'**
  String get action_name_listenAndExecute;

  /// Listen for Button Click
  ///
  /// In en, this message translates to:
  /// **'Listen for Button Click'**
  String get action_name_listenForButtonClick;

  /// Listen for Modal Submit
  ///
  /// In en, this message translates to:
  /// **'Listen for Modal Submit'**
  String get action_name_listenForModalSubmit;

  /// Listen for Select Menu
  ///
  /// In en, this message translates to:
  /// **'Listen for Select Menu'**
  String get action_name_listenForSelectMenu;

  /// Log Message
  ///
  /// In en, this message translates to:
  /// **'Log Message'**
  String get action_name_log;

  /// Move to Voice Channel
  ///
  /// In en, this message translates to:
  /// **'Move to Voice Channel'**
  String get action_name_moveToVoiceChannel;

  /// Mute User
  ///
  /// In en, this message translates to:
  /// **'Mute User'**
  String get action_name_muteUser;

  /// Lavalink music key: action_name_pauseMusic
  ///
  /// In en, this message translates to:
  /// **'Pause Music'**
  String get action_name_pauseMusic;

  /// Pin Message
  ///
  /// In en, this message translates to:
  /// **'Pin Message'**
  String get action_name_pinMessage;

  /// Lavalink music key: action_name_playMusic
  ///
  /// In en, this message translates to:
  /// **'Play Music'**
  String get action_name_playMusic;

  /// Query Array
  ///
  /// In en, this message translates to:
  /// **'Query Array'**
  String get action_name_queryArray;

  /// Random Choice
  ///
  /// In en, this message translates to:
  /// **'Random Choice'**
  String get action_name_randomChoice;

  /// Register Guild Commands
  ///
  /// In en, this message translates to:
  /// **'Register Guild Commands'**
  String get action_name_registerGuildCommands;

  /// Remove Array Element
  ///
  /// In en, this message translates to:
  /// **'Remove Array Element'**
  String get action_name_removeArrayElement;

  /// Remove Channel
  ///
  /// In en, this message translates to:
  /// **'Remove Channel'**
  String get action_name_removeChannel;

  /// Remove Global Variable
  ///
  /// In en, this message translates to:
  /// **'Remove Global Variable'**
  String get action_name_removeGlobalVariable;

  /// Remove Reaction
  ///
  /// In en, this message translates to:
  /// **'Remove Reaction'**
  String get action_name_removeReaction;

  /// Remove Role
  ///
  /// In en, this message translates to:
  /// **'Remove Role'**
  String get action_name_removeRole;

  /// Remove Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Remove Scoped Variable'**
  String get action_name_removeScopedVariable;

  /// Remove Thread Member
  ///
  /// In en, this message translates to:
  /// **'Remove Thread Member'**
  String get action_name_removeThreadMember;

  /// Rename Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Rename Scoped Variable'**
  String get action_name_renameScopedVariable;

  /// Respond with Autocomplete
  ///
  /// In en, this message translates to:
  /// **'Respond with Autocomplete'**
  String get action_name_respondWithAutocomplete;

  /// Respond with Component V2
  ///
  /// In en, this message translates to:
  /// **'Respond with Component V2'**
  String get action_name_respondWithComponentV2;

  /// Respond with Message
  ///
  /// In en, this message translates to:
  /// **'Respond with Message'**
  String get action_name_respondWithMessage;

  /// Respond with Modal
  ///
  /// In en, this message translates to:
  /// **'Respond with Modal'**
  String get action_name_respondWithModal;

  /// Lavalink music key: action_name_resumeMusic
  ///
  /// In en, this message translates to:
  /// **'Resume Music'**
  String get action_name_resumeMusic;

  /// Run BDFD Script
  ///
  /// In en, this message translates to:
  /// **'Run BDFD Script'**
  String get action_name_runBdfdScript;

  /// Run Workflow
  ///
  /// In en, this message translates to:
  /// **'Run Workflow'**
  String get action_name_runWorkflow;

  /// Execute Image Canvas
  ///
  /// In en, this message translates to:
  /// **'Execute Image Canvas'**
  String get action_name_runtimeImageBlock;

  /// Execute JSON Operations
  ///
  /// In en, this message translates to:
  /// **'Execute JSON Operations'**
  String get action_name_runtimeJsonBlock;

  /// Lavalink music key: action_name_seekMusic
  ///
  /// In en, this message translates to:
  /// **'Seek Music Position'**
  String get action_name_seekMusic;

  /// Send Component V2
  ///
  /// In en, this message translates to:
  /// **'Send Component V2'**
  String get action_name_sendComponentV2;

  /// Send Direct Message
  ///
  /// In en, this message translates to:
  /// **'Send Direct Message'**
  String get action_name_sendDm;

  /// Send Message
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get action_name_sendMessage;

  /// Send Webhook
  ///
  /// In en, this message translates to:
  /// **'Send Webhook'**
  String get action_name_sendWebhook;

  /// Server Deafen Member
  ///
  /// In en, this message translates to:
  /// **'Server Deafen Member'**
  String get action_name_serverDeafenMember;

  /// Server Mute Member
  ///
  /// In en, this message translates to:
  /// **'Server Mute Member'**
  String get action_name_serverMuteMember;

  /// Set Global Variable
  ///
  /// In en, this message translates to:
  /// **'Set Global Variable'**
  String get action_name_setGlobalVariable;

  /// Lavalink music key: action_name_setMusicLoop
  ///
  /// In en, this message translates to:
  /// **'Set Music Loop'**
  String get action_name_setMusicLoop;

  /// Lavalink music key: action_name_setMusicVolume
  ///
  /// In en, this message translates to:
  /// **'Set Music Volume'**
  String get action_name_setMusicVolume;

  /// Set Nickname
  ///
  /// In en, this message translates to:
  /// **'Set Nickname'**
  String get action_name_setNickname;

  /// Set Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Set Scoped Variable'**
  String get action_name_setScopedVariable;

  /// Set Temporary Variable
  ///
  /// In en, this message translates to:
  /// **'Set Temporary Variable'**
  String get action_name_setTemporaryVariable;

  /// Skip N actions
  ///
  /// In en, this message translates to:
  /// **'Skip Actions'**
  String get action_name_skipActions;

  /// Lavalink music key: action_name_skipMusic
  ///
  /// In en, this message translates to:
  /// **'Skip Music'**
  String get action_name_skipMusic;

  /// Slowmode
  ///
  /// In en, this message translates to:
  /// **'Slowmode'**
  String get action_name_slowmode;

  /// Stop Execution
  ///
  /// In en, this message translates to:
  /// **'Stop Execution'**
  String get action_name_stop;

  /// Lavalink music key: action_name_stopMusic
  ///
  /// In en, this message translates to:
  /// **'Stop Music'**
  String get action_name_stopMusic;

  /// Stop Unless Condition
  ///
  /// In en, this message translates to:
  /// **'Stop Unless Condition'**
  String get action_name_stopUnless;

  /// Unban User
  ///
  /// In en, this message translates to:
  /// **'Unban User'**
  String get action_name_unbanUser;

  /// Unmute User
  ///
  /// In en, this message translates to:
  /// **'Unmute User'**
  String get action_name_unmuteUser;

  /// Unpin Message
  ///
  /// In en, this message translates to:
  /// **'Unpin Message'**
  String get action_name_unpinMessage;

  /// Unregister Guild Commands
  ///
  /// In en, this message translates to:
  /// **'Unregister Guild Commands'**
  String get action_name_unregisterGuildCommands;

  /// Update AutoMod
  ///
  /// In en, this message translates to:
  /// **'Update AutoMod'**
  String get action_name_updateAutoMod;

  /// Update Channel
  ///
  /// In en, this message translates to:
  /// **'Update Channel'**
  String get action_name_updateChannel;

  /// Update Emoji
  ///
  /// In en, this message translates to:
  /// **'Update Emoji'**
  String get action_name_updateEmoji;

  /// Update Guild
  ///
  /// In en, this message translates to:
  /// **'Update Guild'**
  String get action_name_updateGuild;

  /// Update Guild Onboarding
  ///
  /// In en, this message translates to:
  /// **'Update Guild Onboarding'**
  String get action_name_updateGuildOnboarding;

  /// Update Self User (Bot Profile)
  ///
  /// In en, this message translates to:
  /// **'Update Self User (Bot Profile)'**
  String get action_name_updateSelfUser;

  /// Wait
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get action_name_wait;

  /// No actions in this branch yet.
  ///
  /// In en, this message translates to:
  /// **'No actions in this branch yet.'**
  String get action_no_actions_yet;

  /// No arguments - tap edit to add
  ///
  /// In en, this message translates to:
  /// **'No arguments - tap edit to add'**
  String get action_no_args_tap_edit;

  /// No ELSE IF branches yet. Add one to test more conditions before ELSE.
  ///
  /// In en, this message translates to:
  /// **'No ELSE IF branches yet. Add one to test more conditions before ELSE.'**
  String get action_no_else_if_yet;

  /// No headers - tap edit to add
  ///
  /// In en, this message translates to:
  /// **'No headers - tap edit to add'**
  String get action_no_headers_tap_edit;

  /// No items - tap edit to add
  ///
  /// In en, this message translates to:
  /// **'No items - tap edit to add'**
  String get action_no_items_tap_edit;

  /// No properties - tap edit to configure
  ///
  /// In en, this message translates to:
  /// **'No properties - tap edit to configure'**
  String get action_no_properties_tap_edit;

  /// No saved keys found. Keys are created automatically on first access.
  ///
  /// In en, this message translates to:
  /// **'No saved keys found. Keys are created automatically on first access.'**
  String get action_no_saved_keys;

  /// On Error
  ///
  /// In en, this message translates to:
  /// **'On Error'**
  String get action_on_error;

  /// Action options
  ///
  /// In en, this message translates to:
  /// **'Action options'**
  String get action_options_tooltip;

  /// Or type workflow name
  ///
  /// In en, this message translates to:
  /// **'Or type workflow name'**
  String get action_or_type_workflow;

  /// Tip: use arrows to change action order.
  ///
  /// In en, this message translates to:
  /// **'Tip: use arrows to change action order.'**
  String get action_order_tip;

  /// Action {index}/{total}
  ///
  /// In en, this message translates to:
  /// **'Action {index}/{total}'**
  String action_position(int index, int total);

  /// Preview Highlighted JSON
  ///
  /// In en, this message translates to:
  /// **'Preview Highlighted JSON'**
  String get action_preview_json;

  /// Please provide a valid URL.
  ///
  /// In en, this message translates to:
  /// **'Please provide a valid URL.'**
  String get action_provide_valid_url;

  /// Refresh keys
  ///
  /// In en, this message translates to:
  /// **'Refresh keys'**
  String get action_refresh_keys;

  /// This action will be removed from the workflow. Continue?
  ///
  /// In en, this message translates to:
  /// **'This action will be removed from the workflow. Continue?'**
  String get action_remove_confirm;

  /// Remove ELSE IF
  ///
  /// In en, this message translates to:
  /// **'Remove ELSE IF'**
  String get action_remove_else_if;

  /// Remove action
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get action_remove_menu;

  /// Remove action
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get action_remove_title;

  /// Root must be a JSON object
  ///
  /// In en, this message translates to:
  /// **'Root must be a JSON object'**
  String get action_root_must_json;

  /// Select a saved key
  ///
  /// In en, this message translates to:
  /// **'Select a saved key'**
  String get action_select_saved_key;

  /// Select a stored key (bc_ prefix is optional)
  ///
  /// In en, this message translates to:
  /// **'Select a stored key (bc_ prefix is optional)'**
  String get action_select_stored_key;

  /// (static)
  ///
  /// In en, this message translates to:
  /// **'(static)'**
  String get action_static_badge;

  /// Disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get action_status_disabled;

  /// Enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get action_status_enabled;

  /// Store results in global variables
  ///
  /// In en, this message translates to:
  /// **'Store results in global variables'**
  String get action_store_results;

  /// Active route: {label}
  ///
  /// In en, this message translates to:
  /// **'Active route: {label}'**
  String actions_active_route(String label);

  /// Add Action
  ///
  /// In en, this message translates to:
  /// **'Add Action'**
  String get actions_add_label;

  /// Add New Action
  ///
  /// In en, this message translates to:
  /// **'Add New Action'**
  String get actions_add_new_title;

  /// Build Actions ({count})
  ///
  /// In en, this message translates to:
  /// **'Build Actions ({count})'**
  String actions_build_button(int count);

  /// Empty state subtitle in action builder
  ///
  /// In en, this message translates to:
  /// **'Add an action, then open it to configure details.'**
  String get actions_empty_subtitle;

  /// Empty state title in action builder
  ///
  /// In en, this message translates to:
  /// **'No actions yet'**
  String get actions_empty_title;

  /// Actions Builder
  ///
  /// In en, this message translates to:
  /// **'Actions Builder'**
  String get actions_builder_title;

  /// Build runtime actions for this command
  ///
  /// In en, this message translates to:
  /// **'Build runtime actions for this command'**
  String get actions_description;

  /// Global Variables
  ///
  /// In en, this message translates to:
  /// **'Global Variables'**
  String get actions_global_variables;

  /// Key: {key}
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String actions_key_label(String key);

  /// Missing required field message with placeholders
  ///
  /// In en, this message translates to:
  /// **'\"{action}\": \"{field}\" is required.'**
  String actions_missing_field_content(String action, String field);

  /// Missing Field
  ///
  /// In en, this message translates to:
  /// **'Missing Field'**
  String get actions_missing_field_title;

  /// No matches found
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get actions_no_matches;

  /// Save {count} actions
  ///
  /// In en, this message translates to:
  /// **'Save {count} actions'**
  String actions_save_count(int count);

  /// Save Actions
  ///
  /// In en, this message translates to:
  /// **'Save Actions'**
  String get actions_save_tooltip;

  /// Save as Workflow
  ///
  /// In en, this message translates to:
  /// **'Save as Workflow'**
  String get actions_save_workflow_title;

  /// Search actions...
  ///
  /// In en, this message translates to:
  /// **'Search actions...'**
  String get actions_search_hint;

  /// Search sequence...
  ///
  /// In en, this message translates to:
  /// **'Search sequence...'**
  String get actions_search_sequence_hint;

  /// {count, plural, =0{No actions} =1{1 action} other{{count} actions}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No actions} =1{1 action} other{{count} actions}}'**
  String actions_sequence_count(int count);

  /// Step {index} of {total}
  ///
  /// In en, this message translates to:
  /// **'Step {index} of {total}'**
  String actions_step_label(int index, int total);

  /// BDFD script | {lines} line(s) | {diagnostics} diagnostic(s)
  ///
  /// In en, this message translates to:
  /// **'BDFD script | {lines} line(s) | {diagnostics} diagnostic(s)'**
  String actions_summary_bdfd(int lines, int diagnostics);

  /// {count} action(s) configured
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) configured'**
  String actions_summary_configured(int count);

  /// Dart script | {lines} line(s) | {diagnostics} diagnostic(s)
  ///
  /// In en, this message translates to:
  /// **'Dart script | {lines} line(s) | {diagnostics} diagnostic(s)'**
  String actions_summary_dart(int lines, int diagnostics);

  /// {count} action(s) on active route | {routes} route(s)
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) on active route | {routes} route(s)'**
  String actions_summary_routes(int count, int routes);

  /// Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions_title;

  /// Workflow name
  ///
  /// In en, this message translates to:
  /// **'Workflow name'**
  String get actions_workflow_name_label;

  /// Workflows
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get actions_workflows;

  /// I accept
  ///
  /// In en, this message translates to:
  /// **'I accept'**
  String get ads_consent_accept;

  /// To comply with GDPR, we need your consent before showing ads. You can continue using the app even if you refuse.
  ///
  /// In en, this message translates to:
  /// **'To comply with GDPR, we need your consent before showing ads. You can continue using the app even if you refuse.'**
  String get ads_consent_message;

  /// I refuse
  ///
  /// In en, this message translates to:
  /// **'I refuse'**
  String get ads_consent_refuse;

  /// Ad consent declined. The bot will still start normally.
  ///
  /// In en, this message translates to:
  /// **'Ad consent declined. The bot will still start normally.'**
  String get ads_consent_refused_info;

  /// Ads consent
  ///
  /// In en, this message translates to:
  /// **'Ads consent'**
  String get ads_consent_title;

  /// Bot Token
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get app_bot_token;

  /// Create a bot
  ///
  /// In en, this message translates to:
  /// **'Create a bot'**
  String get app_create_button;

  /// A guided setup to open the right pages, copy your token and import the bot safely.
  ///
  /// In en, this message translates to:
  /// **'A guided setup to open the right pages, copy your token and import the bot safely.'**
  String get app_create_hero_desc;

  /// Connect your Discord bot
  ///
  /// In en, this message translates to:
  /// **'Connect your Discord bot'**
  String get app_create_hero_title;

  /// Create a new App
  ///
  /// In en, this message translates to:
  /// **'Create a new App'**
  String get app_create_new;

  /// Create a bot
  ///
  /// In en, this message translates to:
  /// **'Create a bot'**
  String get app_create_page_title;

  /// Enter your bot token here
  ///
  /// In en, this message translates to:
  /// **'Enter your bot token here'**
  String get app_enter_token;

  /// External link
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get app_external_link_badge;

  /// Hide token
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get app_hide_token;

  /// How to create a Bot Token?
  ///
  /// In en, this message translates to:
  /// **'How to create a Bot Token?'**
  String get app_how_to_create_token;

  /// Loading error
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get app_loading_error;

  /// You don't have any apps yet.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any apps yet.'**
  String get app_no_apps;

  /// Note: You need to create a new App in the Discord Developer Portal and get your bot token.
  ///
  /// In en, this message translates to:
  /// **'Note: You need to create a new App in the Discord Developer Portal and get your bot token.'**
  String get app_note;

  /// Open Discord Developer Portal
  ///
  /// In en, this message translates to:
  /// **'Open Discord Developer Portal'**
  String get app_open_discord_portal;

  /// Create your application and enable the bot section.
  ///
  /// In en, this message translates to:
  /// **'Create your application and enable the bot section.'**
  String get app_open_discord_portal_desc;

  /// Unable to open this external page.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this external page.'**
  String get app_open_link_error;

  /// Read the token tutorial
  ///
  /// In en, this message translates to:
  /// **'Read the token tutorial'**
  String get app_open_token_tutorial;

  /// A step-by-step guide to generate and copy your bot token.
  ///
  /// In en, this message translates to:
  /// **'A step-by-step guide to generate and copy your bot token.'**
  String get app_open_token_tutorial_desc;

  /// These actions open the official pages you need before saving your bot here.
  ///
  /// In en, this message translates to:
  /// **'These actions open the official pages you need before saving your bot here.'**
  String get app_resources_desc;

  /// Guided setup
  ///
  /// In en, this message translates to:
  /// **'Guided setup'**
  String get app_resources_title;

  /// Save Changes
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get app_save;

  /// Add bot
  ///
  /// In en, this message translates to:
  /// **'Add bot'**
  String get app_save_bot;

  /// Show token
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get app_show_token;

  /// Connect Discord
  ///
  /// In en, this message translates to:
  /// **'Connect Discord'**
  String get app_sync_manager_connect;

  /// This bot is already stored on Bot Creator Manager. Connect with Discord to sync all your bots automatically?
  ///
  /// In en, this message translates to:
  /// **'This bot is already stored on Bot Creator Manager. Connect with Discord to sync all your bots automatically?'**
  String get app_sync_manager_desc;

  /// Keep local
  ///
  /// In en, this message translates to:
  /// **'Keep local'**
  String get app_sync_manager_manual;

  /// Bot already managed
  ///
  /// In en, this message translates to:
  /// **'Bot already managed'**
  String get app_sync_manager_title;

  /// Bot Creator
  ///
  /// In en, this message translates to:
  /// **'Bot Creator'**
  String get app_title;

  /// Token invalid error message with tutorial recommendation
  ///
  /// In en, this message translates to:
  /// **'The provided Discord token is invalid or has been revoked. We recommend following the tutorial to generate a valid token.'**
  String get app_token_invalid_content;

  /// Invalid token error dialog title
  ///
  /// In en, this message translates to:
  /// **'Invalid Token'**
  String get app_token_invalid_title;

  /// Paste the token exactly as provided by Discord.
  ///
  /// In en, this message translates to:
  /// **'Paste the token exactly as provided by Discord.'**
  String get app_token_field_helper;

  /// Once the token is copied, paste it below to add your bot to the app.
  ///
  /// In en, this message translates to:
  /// **'Once the token is copied, paste it below to add your bot to the app.'**
  String get app_token_section_desc;

  /// Paste your bot token
  ///
  /// In en, this message translates to:
  /// **'Paste your bot token'**
  String get app_token_section_title;

  /// Keep this token private. Anyone with it can control your bot.
  ///
  /// In en, this message translates to:
  /// **'Keep this token private. Anyone with it can control your bot.'**
  String get app_token_security_hint;

  /// Dynamic Autocomplete
  ///
  /// In en, this message translates to:
  /// **'Dynamic Autocomplete'**
  String get autocomplete_dynamic;

  /// Resolve choices from a workflow instead of static values.
  ///
  /// In en, this message translates to:
  /// **'Resolve choices from a workflow instead of static values.'**
  String get autocomplete_dynamic_desc;

  /// Suggestions are filtered by what the user types.
  ///
  /// In en, this message translates to:
  /// **'Suggestions are filtered by what the user types.'**
  String get autocomplete_filter_hint;

  /// Loading workflows…
  ///
  /// In en, this message translates to:
  /// **'Loading workflows…'**
  String get autocomplete_loading;

  /// No saved workflows found
  ///
  /// In en, this message translates to:
  /// **'No saved workflows found'**
  String get autocomplete_no_workflows;

  /// Select a saved workflow
  ///
  /// In en, this message translates to:
  /// **'Select a saved workflow'**
  String get autocomplete_select_workflow;

  /// Or type workflow name
  ///
  /// In en, this message translates to:
  /// **'Or type workflow name'**
  String get autocomplete_type_name;

  /// Autocomplete Workflow
  ///
  /// In en, this message translates to:
  /// **'Autocomplete Workflow'**
  String get autocomplete_workflow_label;

  /// Backup completed: {id}
  ///
  /// In en, this message translates to:
  /// **'Backup completed: {id}'**
  String backup_completed(String id);

  /// Backup failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backup_failed(String error);

  /// This BDFD script could not be compiled:
  /// {summary}
  ///
  /// In en, this message translates to:
  /// **'This BDFD script could not be compiled:\n{summary}'**
  String bdfd_compile_error_detailed(String summary);

  /// This BDFD script could not be compiled.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script could not be compiled.'**
  String get bdfd_compile_error_simple;

  /// This BDFD script compiled successfully but did not produce any action.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script compiled successfully but did not produce any action.'**
  String get bdfd_compiled_no_actions;

  /// Channels & Threads
  ///
  /// In en, this message translates to:
  /// **'Channels & Threads'**
  String get bdfd_docs_category_channels;

  /// Components
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get bdfd_docs_category_components;

  /// Control Flow
  ///
  /// In en, this message translates to:
  /// **'Control Flow'**
  String get bdfd_docs_category_control;

  /// Cooldowns
  ///
  /// In en, this message translates to:
  /// **'Cooldowns'**
  String get bdfd_docs_category_cooldowns;

  /// Embeds
  ///
  /// In en, this message translates to:
  /// **'Embeds'**
  String get bdfd_docs_category_embeds;

  /// Guards & Permissions
  ///
  /// In en, this message translates to:
  /// **'Guards & Permissions'**
  String get bdfd_docs_category_guards;

  /// HTTP Requests
  ///
  /// In en, this message translates to:
  /// **'HTTP Requests'**
  String get bdfd_docs_category_http;

  /// JSON
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get bdfd_docs_category_json;

  /// Leaderboards
  ///
  /// In en, this message translates to:
  /// **'Leaderboards'**
  String get bdfd_docs_category_leaderboards;

  /// Math
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get bdfd_docs_category_math;

  /// Messages & Content
  ///
  /// In en, this message translates to:
  /// **'Messages & Content'**
  String get bdfd_docs_category_messages;

  /// Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get bdfd_docs_category_misc;

  /// Modals
  ///
  /// In en, this message translates to:
  /// **'Modals'**
  String get bdfd_docs_category_modals;

  /// Moderation
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get bdfd_docs_category_moderation;

  /// Reactions
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get bdfd_docs_category_reactions;

  /// Roles
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get bdfd_docs_category_roles;

  /// Text & Strings
  ///
  /// In en, this message translates to:
  /// **'Text & Strings'**
  String get bdfd_docs_category_text;

  /// Tickets
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get bdfd_docs_category_tickets;

  /// Variables
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get bdfd_docs_category_variables;

  /// Webhooks
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get bdfd_docs_category_webhooks;

  /// Logical AND — combines multiple conditions. All must be true.
  ///
  /// Usage: $if[$and[$authorID==123;$hasRole[456]]]
  ///
  /// In en, this message translates to:
  /// **'Logical AND — combines multiple conditions. All must be true.\n\nUsage: \$if[\$and[\$authorID==123;\$hasRole[456]]]'**
  String get bdfd_docs_desc_and;

  /// Registers a callback that waits for a user response.
  ///
  /// Usage: $awaitFunc[name;userID (opt);channelID (opt)]
  ///
  /// The awaited function is stored and triggered when the target user sends a message in the target channel.
  ///
  /// In en, this message translates to:
  /// **'Registers a callback that waits for a user response.\n\nUsage: \$awaitFunc[name;userID (opt);channelID (opt)]\n\nThe awaited function is stored and triggered when the target user sends a message in the target channel.'**
  String get bdfd_docs_desc_awaitfunc;

  /// Bot Creator only — Calls another workflow by name and passes arguments.
  ///
  /// Syntax: $callWorkflow[myWorkflow;key1=value1;key2=value2]
  ///
  /// The called workflow can read arguments and return a value via $workflowResponse.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Calls another workflow by name and passes arguments.\n\nSyntax: \$callWorkflow[myWorkflow;key1=value1;key2=value2]\n\nThe called workflow can read arguments and return a value via \$workflowResponse.'**
  String get bdfd_docs_desc_callworkflow;

  /// Defers the interaction response, giving you more time to process. The user sees a "Bot is thinking…" message. Use before long operations like HTTP requests.
  ///
  /// In en, this message translates to:
  /// **'Defers the interaction response, giving you more time to process. The user sees a \"Bot is thinking…\" message. Use before long operations like HTTP requests.'**
  String get bdfd_docs_desc_defer;

  /// Adds an alternative condition inside an $if block. Must appear between $if and $else/$endif.
  ///
  /// In en, this message translates to:
  /// **'Adds an alternative condition inside an \$if block. Must appear between \$if and \$else/\$endif.'**
  String get bdfd_docs_desc_elseif;

  /// Same as $suppressErrors — suppresses all error messages silently.
  ///
  /// In en, this message translates to:
  /// **'Same as \$suppressErrors — suppresses all error messages silently.'**
  String get bdfd_docs_desc_embedsuppresserrors;

  /// Makes the response visible only to the user who triggered the command. Must be placed before any response content.
  ///
  /// In en, this message translates to:
  /// **'Makes the response visible only to the user who triggered the command. Must be placed before any response content.'**
  String get bdfd_docs_desc_ephemeral;

  /// Executes a BDFD script string at runtime. The code passed as argument is re-compiled and executed dynamically. Useful for running user-provided or variable-based scripts.
  ///
  /// In en, this message translates to:
  /// **'Executes a BDFD script string at runtime. The code passed as argument is re-compiled and executed dynamically. Useful for running user-provided or variable-based scripts.'**
  String get bdfd_docs_desc_eval;

  /// Bot Creator only — Repeats a block of code N times.
  ///
  /// Simple: $for[5]...$endfor → the body is repeated 5 times (max 100). You can use $i for the current index (starting at 0) and $loopCount for the total.
  ///
  /// C-style: $for[i=0;i<10;i++]...$endfor → classic for loop with init, condition and update. Supports ++, --, +=, -=, *=.
  ///
  /// If the iteration count is dynamic (e.g. $for[$args[1]]), the loop runs at runtime instead of compile-time.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Repeats a block of code N times.\n\nSimple: \$for[5]...\$endfor → the body is repeated 5 times (max 100). You can use \$i for the current index (starting at 0) and \$loopCount for the total.\n\nC-style: \$for[i=0;i<10;i++]...\$endfor → classic for loop with init, condition and update. Supports ++, --, +=, -=, *=.\n\nIf the iteration count is dynamic (e.g. \$for[\$args[1]]), the loop runs at runtime instead of compile-time.'**
  String get bdfd_docs_desc_for;

  /// Adds a header to the next HTTP request. Headers are accumulated until the next $httpGet/$httpPost/etc.
  ///
  /// Usage: $httpAddHeader[Authorization;Bearer token123]
  ///
  /// In en, this message translates to:
  /// **'Adds a header to the next HTTP request. Headers are accumulated until the next \$httpGet/\$httpPost/etc.\n\nUsage: \$httpAddHeader[Authorization;Bearer token123]'**
  String get bdfd_docs_desc_httpaddheader;

  /// Sends an HTTP GET request to the given URL. Use $httpAddHeader before to set headers. Use $httpResult to read the response.
  ///
  /// All HTTP methods (GET, POST, PUT, PATCH, DELETE) follow the same pattern.
  ///
  /// In en, this message translates to:
  /// **'Sends an HTTP GET request to the given URL. Use \$httpAddHeader before to set headers. Use \$httpResult to read the response.\n\nAll HTTP methods (GET, POST, PUT, PATCH, DELETE) follow the same pattern.'**
  String get bdfd_docs_desc_httpget;

  /// Returns the body of the last HTTP response. Optionally pass a JSON path to extract a specific field.
  ///
  /// Usage: $httpResult[] for the full body, or $httpResult[data.name] for a nested field.
  ///
  /// In en, this message translates to:
  /// **'Returns the body of the last HTTP response. Optionally pass a JSON path to extract a specific field.\n\nUsage: \$httpResult[] for the full body, or \$httpResult[data.name] for a nested field.'**
  String get bdfd_docs_desc_httpresult;

  /// Conditional block. Supports nesting and rich operators: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.
  ///
  /// Usage:
  /// $if[$authorID==123456]
  ///   Hello admin!
  /// $elseif[$hasRole[789]]
  ///   Hello member!
  /// $else
  ///   Hello guest!
  /// $endif
  ///
  /// In en, this message translates to:
  /// **'Conditional block. Supports nesting and rich operators: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUsage:\n\$if[\$authorID==123456]\n  Hello admin!\n\$elseif[\$hasRole[789]]\n  Hello member!\n\$else\n  Hello guest!\n\$endif'**
  String get bdfd_docs_desc_if;

  /// Parses a JSON string into memory for manipulation. All JSON operations ($jsonSet, $json, etc.) operate on this parsed context.
  ///
  /// Static JSON is resolved at compile-time for better performance.
  ///
  /// In en, this message translates to:
  /// **'Parses a JSON string into memory for manipulation. All JSON operations (\$jsonSet, \$json, etc.) operate on this parsed context.\n\nStatic JSON is resolved at compile-time for better performance.'**
  String get bdfd_docs_desc_jsonparse;

  /// Sets a value in the current JSON context. Supports dot-notation paths.
  ///
  /// Usage: $jsonSet[user.name;John]
  ///
  /// The change is applied in memory — use $jsonStringify to get the result.
  ///
  /// In en, this message translates to:
  /// **'Sets a value in the current JSON context. Supports dot-notation paths.\n\nUsage: \$jsonSet[user.name;John]\n\nThe change is applied in memory — use \$jsonStringify to get the result.'**
  String get bdfd_docs_desc_jsonset;

  /// Converts the current JSON context back to a string. Use after $jsonParse and $jsonSet operations to output the result.
  ///
  /// In en, this message translates to:
  /// **'Converts the current JSON context back to a string. Use after \$jsonParse and \$jsonSet operations to output the result.'**
  String get bdfd_docs_desc_jsonstringify;

  /// Bot Creator only — Alias for $for. See $for for details. Use $endloop to close the block.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Alias for \$for. See \$for for details. Use \$endloop to close the block.'**
  String get bdfd_docs_desc_loop;

  /// Logical OR — combines multiple conditions. At least one must be true.
  ///
  /// Usage: $if[$or[$authorID==123;$authorID==456]]]
  ///
  /// In en, this message translates to:
  /// **'Logical OR — combines multiple conditions. At least one must be true.\n\nUsage: \$if[\$or[\$authorID==123;\$authorID==456]]]'**
  String get bdfd_docs_desc_or;

  /// Immediately stops execution of the current script. No further actions after $stop will run.
  ///
  /// In en, this message translates to:
  /// **'Immediately stops execution of the current script. No further actions after \$stop will run.'**
  String get bdfd_docs_desc_stop;

  /// Prevents error messages from being sent to the user. If any action fails, the error is silently suppressed.
  ///
  /// In en, this message translates to:
  /// **'Prevents error messages from being sent to the user. If any action fails, the error is silently suppressed.'**
  String get bdfd_docs_desc_suppresserrors;

  /// Wraps a block for error handling.
  ///
  /// Usage:
  /// $try
  ///   $httpGet[https://api.example.com/data]
  /// $catch
  ///   Request failed!
  /// $endtry
  ///
  /// If any function in the $try block fails, execution jumps to $catch.
  ///
  /// In en, this message translates to:
  /// **'Wraps a block for error handling.\n\nUsage:\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  Request failed!\n\$endtry\n\nIf any function in the \$try block fails, execution jumps to \$catch.'**
  String get bdfd_docs_desc_try;

  /// No description provided for @bdfd_docs_desc_url.
  ///
  /// In en, this message translates to:
  /// **'Encodes or decodes text for use in URLs. Use \'encode\' to make text URL-safe, or \'decode\' to revert it.\n\nUsage: \$url[encode;Hello world!!]'**
  String get bdfd_docs_desc_url;

  /// Bot Creator only — Returns the response from the last $callWorkflow.
  ///
  /// Use $workflowResponse[] for the full response, or $workflowResponse[property] to access a specific field.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Returns the response from the last \$callWorkflow.\n\nUse \$workflowResponse[] for the full response, or \$workflowResponse[property] to access a specific field.'**
  String get bdfd_docs_desc_workflowresponse;

  /// No matching functions.
  ///
  /// In en, this message translates to:
  /// **'No matching functions.'**
  String get bdfd_docs_empty;

  /// No parameters — use as $functionName
  ///
  /// In en, this message translates to:
  /// **'No parameters — use as \$functionName'**
  String get bdfd_docs_no_params;

  /// PARAMETERS
  ///
  /// In en, this message translates to:
  /// **'PARAMETERS'**
  String get bdfd_docs_parameters;

  /// Search functions…
  ///
  /// In en, this message translates to:
  /// **'Search functions…'**
  String get bdfd_docs_search_hint;

  /// SYNTAX
  ///
  /// In en, this message translates to:
  /// **'SYNTAX'**
  String get bdfd_docs_syntax;

  /// BDFD Docs
  ///
  /// In en, this message translates to:
  /// **'BDFD Docs'**
  String get bdfd_docs_title;

  /// • Smart auto indentation on Enter
  ///
  /// In en, this message translates to:
  /// **'• Smart auto indentation on Enter'**
  String get bdfd_editor_auto_indent;

  /// Toggle diagnostics panel
  ///
  /// In en, this message translates to:
  /// **'Toggle diagnostics panel'**
  String get bdfd_editor_diagnostics_toggle;

  /// BDFD Functions Reference
  ///
  /// In en, this message translates to:
  /// **'BDFD Functions Reference'**
  String get bdfd_editor_docs;

  /// Empty script — start typing to see diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Empty script — start typing to see diagnostics.'**
  String get bdfd_editor_empty;

  /// Includes:
  ///
  /// In en, this message translates to:
  /// **'Includes:'**
  String get bdfd_editor_includes;

  /// • Live indentation guides
  ///
  /// In en, this message translates to:
  /// **'• Live indentation guides'**
  String get bdfd_editor_indent_guides;

  /// • Mobile quick-keys for BDFD symbols
  ///
  /// In en, this message translates to:
  /// **'• Mobile quick-keys for BDFD symbols'**
  String get bdfd_editor_quick_keys;

  /// Tap to open editor
  ///
  /// In en, this message translates to:
  /// **'Tap to open editor'**
  String get bdfd_editor_tap_hint;

  /// BDFD Editor
  ///
  /// In en, this message translates to:
  /// **'BDFD Editor'**
  String get bdfd_editor_title;

  /// Toggle indentation guides
  ///
  /// In en, this message translates to:
  /// **'Toggle indentation guides'**
  String get bdfd_editor_toggle_indent;

  /// Editor UX
  ///
  /// In en, this message translates to:
  /// **'Editor UX'**
  String get bdfd_editor_ux_title;

  /// Toggle line wrapping
  ///
  /// In en, this message translates to:
  /// **'Toggle line wrapping'**
  String get bdfd_editor_wrap_toggle;

  /// An error occurred while executing this BDFD script.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while executing this BDFD script.'**
  String get bdfd_runtime_execution_error;

  /// Create my first command
  ///
  /// In en, this message translates to:
  /// **'Create my first command'**
  String get bot_home_create_command;

  /// Customize my bot
  ///
  /// In en, this message translates to:
  /// **'Customize my bot'**
  String get bot_home_customize;

  /// Delete App
  ///
  /// In en, this message translates to:
  /// **'Delete App'**
  String get bot_home_delete;

  /// Are you sure you want to delete this app?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this app?'**
  String get bot_home_delete_confirm;

  /// Invite Bot
  ///
  /// In en, this message translates to:
  /// **'Invite Bot'**
  String get bot_home_invite;

  /// Could not open invite link
  ///
  /// In en, this message translates to:
  /// **'Could not open invite link'**
  String get bot_home_invite_error;

  /// In local mode, iOS may suspend the app in the background. The bot can start, but keeping the Discord connection alive is not guaranteed like it is with a Runner.
  ///
  /// In en, this message translates to:
  /// **'In local mode, iOS may suspend the app in the background. The bot can start, but keeping the Discord connection alive is not guaranteed like it is with a Runner.'**
  String get bot_home_ios_notice_content;

  /// Local iOS constraint
  ///
  /// In en, this message translates to:
  /// **'Local iOS constraint'**
  String get bot_home_ios_notice_title;

  /// Desktop bot stop requested
  ///
  /// In en, this message translates to:
  /// **'Desktop bot stop requested'**
  String get bot_home_log_desktop_stop;

  /// Bot start requested
  ///
  /// In en, this message translates to:
  /// **'Bot start requested'**
  String get bot_home_log_start;

  /// Bot stop requested
  ///
  /// In en, this message translates to:
  /// **'Bot stop requested'**
  String get bot_home_log_stop;

  /// Notification permission is required to start the bot service.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to start the bot service.'**
  String get bot_home_notif_required;

  /// DANGER ZONE
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get bot_home_section_danger;

  /// GETTING STARTED
  ///
  /// In en, this message translates to:
  /// **'GETTING STARTED'**
  String get bot_home_section_getting_started;

  /// MONITORING
  ///
  /// In en, this message translates to:
  /// **'MONITORING'**
  String get bot_home_section_monitoring;

  /// TOOLS
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get bot_home_section_tools;

  /// Foreground service did not start.
  ///
  /// In en, this message translates to:
  /// **'Foreground service did not start.'**
  String get bot_home_service_not_started;

  /// Start Bot
  ///
  /// In en, this message translates to:
  /// **'Start Bot'**
  String get bot_home_start;

  /// Could not start: {error}
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String bot_home_start_error(String error);

  /// Starting…
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get bot_home_starting;

  /// Stop Bot
  ///
  /// In en, this message translates to:
  /// **'Stop Bot'**
  String get bot_home_stop;

  /// Sync App
  ///
  /// In en, this message translates to:
  /// **'Sync App'**
  String get bot_home_sync;

  /// App synced successfully
  ///
  /// In en, this message translates to:
  /// **'App synced successfully'**
  String get bot_home_sync_success;

  /// Pull App
  ///
  /// In en, this message translates to:
  /// **'Pull from Cloud'**
  String get bot_home_pull;

  /// Push App
  ///
  /// In en, this message translates to:
  /// **'Push to Cloud'**
  String get bot_home_push;

  /// App pulled successfully
  ///
  /// In en, this message translates to:
  /// **'App pulled from cloud successfully'**
  String get bot_home_pull_success;

  /// App pushed successfully
  ///
  /// In en, this message translates to:
  /// **'App pushed to cloud successfully'**
  String get bot_home_push_success;

  /// Version history action button
  ///
  /// In en, this message translates to:
  /// **'Version History'**
  String get bot_home_version_history;

  /// Version history page title
  ///
  /// In en, this message translates to:
  /// **'Version History'**
  String get bot_config_versions_title;

  /// No versions found message
  ///
  /// In en, this message translates to:
  /// **'No previous versions found'**
  String get bot_config_versions_empty;

  /// Restore version button
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get bot_config_versions_restore;

  /// Confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Restore this version? Your current config will be backed up first.'**
  String get bot_config_versions_restore_confirm;

  /// Version restored success message
  ///
  /// In en, this message translates to:
  /// **'Configuration restored successfully!'**
  String get bot_config_versions_restored;

  /// Failed to load versions error
  ///
  /// In en, this message translates to:
  /// **'Failed to load versions'**
  String get bot_config_versions_error;

  /// Failed to restore version error
  ///
  /// In en, this message translates to:
  /// **'Failed to restore version'**
  String get bot_config_versions_restore_error;

  /// Pull dialog: changes to apply header
  ///
  /// In en, this message translates to:
  /// **'Changes to apply:'**
  String get bot_home_pull_dialog_changes;

  /// Pull dialog: local device label
  ///
  /// In en, this message translates to:
  /// **'Local (Device)'**
  String get bot_home_pull_dialog_local;

  /// Pull dialog: local-only count label
  ///
  /// In en, this message translates to:
  /// **'local-only (kept)'**
  String get bot_home_pull_dialog_local_only;

  /// Pull dialog: local commands will be preserved notice
  ///
  /// In en, this message translates to:
  /// **'local command(s) not on remote will be preserved.'**
  String get bot_home_pull_dialog_local_preserved;

  /// Pull dialog: new commands count label
  ///
  /// In en, this message translates to:
  /// **'new command(s)'**
  String get bot_home_pull_dialog_new_commands;

  /// Pull dialog: remote cloud label
  ///
  /// In en, this message translates to:
  /// **'Remote (Cloud)'**
  String get bot_home_pull_dialog_remote;

  /// Pull dialog: unchanged count label
  ///
  /// In en, this message translates to:
  /// **'unchanged'**
  String get bot_home_pull_dialog_unchanged;

  /// Pull dialog: already up to date message
  ///
  /// In en, this message translates to:
  /// **'Already up to date — no changes needed.'**
  String get bot_home_pull_dialog_up_to_date;

  /// Pull dialog: updated commands count label
  ///
  /// In en, this message translates to:
  /// **'updated command(s)'**
  String get bot_home_pull_dialog_updated_commands;

  /// Push refused: config empty or corrupted
  ///
  /// In en, this message translates to:
  /// **'Refusing to push: local config is empty or corrupted. Check your commands.'**
  String get bot_home_push_refused_empty;

  /// Unable to connect to Discord with the provided token. It may be invalid or revoked. Do you want to start the bot anyway?
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to Discord with the provided token. It may be invalid or revoked. Do you want to start the bot anyway?'**
  String get bot_home_token_invalid_content;

  /// Token seems invalid
  ///
  /// In en, this message translates to:
  /// **'Token seems invalid'**
  String get bot_home_token_invalid_title;

  /// View bot logs
  ///
  /// In en, this message translates to:
  /// **'View bot logs'**
  String get bot_home_view_logs;

  /// View debugger replays
  ///
  /// In en, this message translates to:
  /// **'View debugger replays'**
  String get bot_home_view_replay;

  /// View bot stats
  ///
  /// In en, this message translates to:
  /// **'View bot stats'**
  String get bot_home_view_stats;

  /// Logs copied
  ///
  /// In en, this message translates to:
  /// **'Logs copied'**
  String get bot_logs_copied;

  /// Disable debug logs
  ///
  /// In en, this message translates to:
  /// **'Disable debug logs'**
  String get bot_logs_disable_debug;

  /// No logs yet
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get bot_logs_empty;

  /// Enable debug logs
  ///
  /// In en, this message translates to:
  /// **'Enable debug logs'**
  String get bot_logs_enable_debug;

  /// Number of displayed logs
  ///
  /// In en, this message translates to:
  /// **'Number of displayed logs'**
  String get bot_logs_filter_count;

  /// Go to bottom
  ///
  /// In en, this message translates to:
  /// **'Go to bottom'**
  String get bot_logs_go_to_bottom;

  /// Go to latest log
  ///
  /// In en, this message translates to:
  /// **'Go to latest log'**
  String get bot_logs_go_to_latest;

  /// Show newest first
  ///
  /// In en, this message translates to:
  /// **'Show newest first'**
  String get bot_logs_newest_first;

  /// Show oldest first
  ///
  /// In en, this message translates to:
  /// **'Show oldest first'**
  String get bot_logs_oldest_first;

  /// Bot process RAM: {memory}
  ///
  /// In en, this message translates to:
  /// **'Bot process RAM: {memory}'**
  String bot_logs_ram(String memory);

  /// Estimated bot RAM: {memory}
  ///
  /// In en, this message translates to:
  /// **'Estimated bot RAM: {memory}'**
  String bot_logs_ram_estimated(String memory);

  /// Compact raw logs
  ///
  /// In en, this message translates to:
  /// **'Compact raw logs'**
  String get bot_logs_raw_mode;

  /// Rich formatted logs
  ///
  /// In en, this message translates to:
  /// **'Rich formatted logs'**
  String get bot_logs_rich_mode;

  /// Show all
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get bot_logs_show_all;

  /// Show less
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get bot_logs_show_less;

  /// Show more
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get bot_logs_show_more;

  /// Show {count} logs
  ///
  /// In en, this message translates to:
  /// **'Show {count} logs'**
  String bot_logs_show_n(int count);

  /// Bot Logs
  ///
  /// In en, this message translates to:
  /// **'Bot Logs'**
  String get bot_logs_title;

  /// Token invalid or missing. Enter a new Discord bot token to restore the connection.
  ///
  /// In en, this message translates to:
  /// **'Token invalid or missing. Enter a new Discord bot token to restore the connection.'**
  String get bot_offline_token_desc;

  /// Activity state (optional)
  ///
  /// In en, this message translates to:
  /// **'Activity state (optional)'**
  String get bot_settings_activity_state_label;

  /// Stream URL (for streaming)
  ///
  /// In en, this message translates to:
  /// **'Stream URL (for streaming)'**
  String get bot_settings_activity_url_label;

  /// Add activity
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get bot_settings_add_status;

  /// Application Flags
  ///
  /// In en, this message translates to:
  /// **'Application Flags'**
  String get bot_settings_app_flags;

  /// Clear selection
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get bot_settings_avatar_clear_selection;

  /// Important notice about profile change persistence
  ///
  /// In en, this message translates to:
  /// **'Important: Profile changes (username and avatar) will only be applied to Discord when you click \'Save profile and statuses\' at the bottom.'**
  String get bot_settings_avatar_important_note;

  /// Avatar local file path
  ///
  /// In en, this message translates to:
  /// **'Avatar local file path'**
  String get bot_settings_avatar_local_path;

  /// Placeholder when no new avatar image is selected
  ///
  /// In en, this message translates to:
  /// **'No new image selected. Click Browse to choose one.'**
  String get bot_settings_avatar_none_selected;

  /// /absolute/path/to/avatar.png
  ///
  /// In en, this message translates to:
  /// **'/absolute/path/to/avatar.png'**
  String get bot_settings_avatar_path_hint;

  /// Unable to preview image
  ///
  /// In en, this message translates to:
  /// **'Unable to preview image'**
  String get bot_settings_avatar_preview_error;

  /// Avatar preview
  ///
  /// In en, this message translates to:
  /// **'Avatar preview'**
  String get bot_settings_avatar_preview_label;

  /// Label for selected avatar image
  ///
  /// In en, this message translates to:
  /// **'Selected image:'**
  String get bot_settings_avatar_selected;

  /// Selected file: {path}
  ///
  /// In en, this message translates to:
  /// **'Selected file: {path}'**
  String bot_settings_avatar_selected_file(String path);

  /// Unsupported avatar format: {ext}. Supported formats: {formats}.
  ///
  /// In en, this message translates to:
  /// **'Unsupported avatar format: {ext}. Supported formats: {formats}.'**
  String bot_settings_avatar_unsupported_format(String ext, String formats);

  /// Browse
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get bot_settings_browse;

  /// Cancel token edit
  ///
  /// In en, this message translates to:
  /// **'Cancel token edit'**
  String get bot_settings_cancel_token_edit_btn;

  /// Danger zone title
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get bot_settings_danger_zone;

  /// Delete bot title
  ///
  /// In en, this message translates to:
  /// **'Delete Bot'**
  String get bot_settings_delete_bot;

  /// Delete bot button label
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get bot_settings_delete_bot_btn;

  /// Delete bot description
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All local data and remote configurations will be permanently removed.'**
  String get bot_settings_delete_bot_desc;

  /// Confirmation description for deletion
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete bot {id}? All data will be lost.'**
  String bot_settings_delete_desc(String id);

  /// Confirmation title for deletion
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get bot_settings_delete_title;

  /// Edit token
  ///
  /// In en, this message translates to:
  /// **'Edit token'**
  String get bot_settings_edit_token_btn;

  /// Export / Import
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get bot_settings_export_import;

  /// Export or import your bot configuration as a ZIP file.
  ///
  /// In en, this message translates to:
  /// **'Export or import your bot configuration as a ZIP file.'**
  String get bot_settings_export_import_desc;

  /// Gateway Intents Configuration
  ///
  /// In en, this message translates to:
  /// **'Gateway Intents Configuration'**
  String get bot_settings_gateway_intents;

  /// Select which intents your bot needs. Configure these in the Discord Developer Portal.
  ///
  /// In en, this message translates to:
  /// **'Select which intents your bot needs. Configure these in the Discord Developer Portal.'**
  String get bot_settings_gateway_intents_desc;

  /// Intents saved successfully
  ///
  /// In en, this message translates to:
  /// **'Intents saved successfully'**
  String get bot_settings_intents_saved;

  /// Message shown when no activities are configured for the bot
  ///
  /// In en, this message translates to:
  /// **'No activities configured'**
  String get bot_settings_no_activities;

  /// Do Not Disturb
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get bot_settings_presence_dnd;

  /// Idle (Away)
  ///
  /// In en, this message translates to:
  /// **'Idle (Away)'**
  String get bot_settings_presence_idle;

  /// Invisible
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get bot_settings_presence_invisible;

  /// Online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get bot_settings_presence_online;

  /// Presence
  ///
  /// In en, this message translates to:
  /// **'Presence'**
  String get bot_settings_presence_status_label;

  /// Bot Presence Status
  ///
  /// In en, this message translates to:
  /// **'Bot Presence Status'**
  String get bot_settings_presence_status_title;

  /// Profile/statuses applied successfully
  ///
  /// In en, this message translates to:
  /// **'Profile/statuses applied successfully'**
  String get bot_settings_profile_saved;

  /// Bot Profile
  ///
  /// In en, this message translates to:
  /// **'Bot Profile'**
  String get bot_settings_profile_title;

  /// Remove activity
  ///
  /// In en, this message translates to:
  /// **'Remove activity'**
  String get bot_settings_remove_status;

  /// Save intents
  ///
  /// In en, this message translates to:
  /// **'Save intents'**
  String get bot_settings_save_intents_btn;

  /// This only updates gateway intents configuration.
  ///
  /// In en, this message translates to:
  /// **'This only updates gateway intents configuration.'**
  String get bot_settings_save_intents_caption;

  /// This applies username/avatar instantly and saves status rotation.
  ///
  /// In en, this message translates to:
  /// **'This applies username/avatar instantly and saves status rotation.'**
  String get bot_settings_save_profile_caption;

  /// Save profile and statuses
  ///
  /// In en, this message translates to:
  /// **'Save profile and statuses'**
  String get bot_settings_save_profile_status_btn;

  /// Settings saved successfully
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get bot_settings_save_success;

  /// Save token and intents
  ///
  /// In en, this message translates to:
  /// **'Save token and intents'**
  String get bot_settings_save_token_btn;

  /// Token changes are protected. Click "Edit token" first, then save.
  ///
  /// In en, this message translates to:
  /// **'Token changes are protected. Click \"Edit token\" first, then save.'**
  String get bot_settings_save_token_caption;

  /// Please save the token first before applying profile/status changes.
  ///
  /// In en, this message translates to:
  /// **'Please save the token first before applying profile/status changes.'**
  String get bot_settings_save_token_first;

  /// Save token
  ///
  /// In en, this message translates to:
  /// **'Save token'**
  String get bot_settings_save_token_only_btn;

  /// Activity {index}
  ///
  /// In en, this message translates to:
  /// **'Activity {index}'**
  String bot_settings_status_item_title(int index);

  /// Max interval (s)
  ///
  /// In en, this message translates to:
  /// **'Max interval (s)'**
  String get bot_settings_status_max_interval;

  /// Min interval (s)
  ///
  /// In en, this message translates to:
  /// **'Min interval (s)'**
  String get bot_settings_status_min_interval;

  /// Add one or more activities. Each activity needs a type, name, and min/max interval (seconds).
  ///
  /// In en, this message translates to:
  /// **'Add one or more activities. Each activity needs a type, name, and min/max interval (seconds).'**
  String get bot_settings_status_rotation_desc;

  /// Activities Rotation
  ///
  /// In en, this message translates to:
  /// **'Activities Rotation'**
  String get bot_settings_status_rotation_title;

  /// Activity name
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get bot_settings_status_text_label;

  /// Competing
  ///
  /// In en, this message translates to:
  /// **'Competing'**
  String get bot_settings_status_type_competing;

  /// Type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get bot_settings_status_type_label;

  /// Listening
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get bot_settings_status_type_listening;

  /// Playing
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get bot_settings_status_type_playing;

  /// Streaming
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get bot_settings_status_type_streaming;

  /// Watching
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get bot_settings_status_type_watching;

  /// Advanced & maintenance tab in bot settings
  ///
  /// In en, this message translates to:
  /// **'Advanced & Maintenance'**
  String get bot_settings_tab_advanced;

  /// General tab in bot settings
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get bot_settings_tab_general;

  /// Intents & privileges tab in bot settings
  ///
  /// In en, this message translates to:
  /// **'Intents & Privileges'**
  String get bot_settings_tab_intents;

  /// Presence & status tab in bot settings
  ///
  /// In en, this message translates to:
  /// **'Presence & Status'**
  String get bot_settings_tab_presence;

  /// Customize Bot / Profile
  ///
  /// In en, this message translates to:
  /// **'Customize Bot / Profile'**
  String get bot_settings_title;

  /// Token input is hidden by default for safety.
  ///
  /// In en, this message translates to:
  /// **'Token input is hidden by default for safety.'**
  String get bot_settings_token_hidden_desc;

  /// Enter your bot token here
  ///
  /// In en, this message translates to:
  /// **'Enter your bot token here'**
  String get bot_settings_token_hint;

  /// Replace token anyway
  ///
  /// In en, this message translates to:
  /// **'Replace token anyway'**
  String get bot_settings_token_mismatch_confirm;

  /// This token belongs to bot {newId}, but the current data is for bot {oldId}. Commands and settings may not match. Continue anyway?
  ///
  /// In en, this message translates to:
  /// **'This token belongs to bot {newId}, but the current data is for bot {oldId}. Commands and settings may not match. Continue anyway?'**
  String bot_settings_token_mismatch_content(String newId, String oldId);

  /// Different bot detected
  ///
  /// In en, this message translates to:
  /// **'Different bot detected'**
  String get bot_settings_token_mismatch_title;

  /// Bot token is required.
  ///
  /// In en, this message translates to:
  /// **'Bot token is required.'**
  String get bot_settings_token_required;

  /// Token saved successfully
  ///
  /// In en, this message translates to:
  /// **'Token saved successfully'**
  String get bot_settings_token_saved;

  /// Bot Token
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get bot_settings_token_title;

  /// Update Bot Token
  ///
  /// In en, this message translates to:
  /// **'Update Bot Token'**
  String get bot_settings_update_token;

  /// Leave empty to keep current username
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current username'**
  String get bot_settings_username_hint;

  /// Username override
  ///
  /// In en, this message translates to:
  /// **'Username override'**
  String get bot_settings_username_override;

  /// Documentation Center
  ///
  /// In en, this message translates to:
  /// **'Documentation Center'**
  String get bot_settings_workflow_docs;

  /// Centralized documentation for commands, workflows, runtime variables, and execution behavior.
  ///
  /// In en, this message translates to:
  /// **'Centralized documentation for commands, workflows, runtime variables, and execution behavior.'**
  String get bot_settings_workflow_docs_desc;

  /// Collecting…
  ///
  /// In en, this message translates to:
  /// **'Collecting…'**
  String get bot_stats_collecting;

  /// Bot process CPU
  ///
  /// In en, this message translates to:
  /// **'Bot process CPU'**
  String get bot_stats_cpu;

  /// Notes: CPU available on Android/Linux. Storage = bot data files in the app.
  ///
  /// In en, this message translates to:
  /// **'Notes: CPU available on Android/Linux. Storage = bot data files in the app.'**
  String get bot_stats_notes;

  /// Bot RAM only (estimated)
  ///
  /// In en, this message translates to:
  /// **'Bot RAM only (estimated)'**
  String get bot_stats_ram_estimated;

  /// Bot process RAM
  ///
  /// In en, this message translates to:
  /// **'Bot process RAM'**
  String get bot_stats_ram_process;

  /// Source: Local Hosting
  ///
  /// In en, this message translates to:
  /// **'Source: Local Hosting'**
  String get bot_stats_source_local_hosting;

  /// Source: Runner API
  ///
  /// In en, this message translates to:
  /// **'Source: Runner API'**
  String get bot_stats_source_runner_api;

  /// Bot storage (app data)
  ///
  /// In en, this message translates to:
  /// **'Bot storage (app data)'**
  String get bot_stats_storage;

  /// Bot Stats
  ///
  /// In en, this message translates to:
  /// **'Bot Stats'**
  String get bot_stats_title;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Type $ and start writing a function name to get quick script suggestions.
  ///
  /// In en, this message translates to:
  /// **'Type \$ and start writing a function name to get quick script suggestions.'**
  String get cmd_bdfd_autocomplete_hint;

  /// BDFD prefix autocomplete
  ///
  /// In en, this message translates to:
  /// **'BDFD prefix autocomplete'**
  String get cmd_bdfd_autocomplete_title;

  /// No issue detected in the current script.
  ///
  /// In en, this message translates to:
  /// **'No issue detected in the current script.'**
  String get cmd_bdfd_diagnostics_clean;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cmd_bdfd_diagnostics_error;

  /// BDFD diagnostics
  ///
  /// In en, this message translates to:
  /// **'BDFD diagnostics'**
  String get cmd_bdfd_diagnostics_title;

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get cmd_bdfd_diagnostics_warning;

  /// BDFD script body cannot be empty.
  ///
  /// In en, this message translates to:
  /// **'BDFD script body cannot be empty.'**
  String get cmd_bdfd_script_empty_error;

  /// $nomention\n$if[$hasPerms[$authorID;administrator]==true]\nHello from Bot Creator
  ///
  /// In en, this message translates to:
  /// **'\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator'**
  String get cmd_bdfd_script_hint;

  /// BDFD script body
  ///
  /// In en, this message translates to:
  /// **'BDFD script body'**
  String get cmd_bdfd_script_label;

  /// This BDFD script still contains diagnostics:
  ///
  /// In en, this message translates to:
  /// **'This BDFD script still contains diagnostics:'**
  String get cmd_bdfd_script_validation_error;

  /// Create command
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get cmd_create_tooltip;

  /// No issue detected in the current Dart script.
  ///
  /// In en, this message translates to:
  /// **'No issue detected in the current Dart script.'**
  String get cmd_dart_diagnostics_clean;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cmd_dart_diagnostics_error;

  /// Dart diagnostics
  ///
  /// In en, this message translates to:
  /// **'Dart diagnostics'**
  String get cmd_dart_diagnostics_title;

  /// Warning
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get cmd_dart_diagnostics_warning;

  /// return "Hello from Dart Direct";
  ///
  /// In en, this message translates to:
  /// **'return \"Hello from Dart Direct\";'**
  String get cmd_dart_script_hint;

  /// Dart script body
  ///
  /// In en, this message translates to:
  /// **'Dart script body'**
  String get cmd_dart_script_label;

  /// Batch delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete {count} commands?'**
  String cmd_batch_delete_confirm(int count);

  /// No description provided for @cmd_batch_delete_success.
  ///
  /// In en, this message translates to:
  /// **'{count} commands deleted'**
  String cmd_batch_delete_success(Object count);

  /// No description provided for @cmd_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete command \"{name}\"?'**
  String cmd_delete_confirm(Object name);

  /// No description provided for @cmd_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Command \"{name}\" deleted'**
  String cmd_delete_success(Object name);

  /// Delete command
  ///
  /// In en, this message translates to:
  /// **'Delete command'**
  String get cmd_delete_tooltip;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get cmd_deploy_close_button;

  /// Secure synchronization with your online space
  ///
  /// In en, this message translates to:
  /// **'Secure synchronization with your online space'**
  String get cmd_deploy_cloud_sync_subtitle;

  /// Cloud Backup
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get cmd_deploy_cloud_sync_title;

  /// Subtitle showing command name under configuration
  ///
  /// In en, this message translates to:
  /// **'Configuration of /{name}'**
  String cmd_deploy_config_subtitle(String name);

  /// Publishing command to Discord API
  ///
  /// In en, this message translates to:
  /// **'Publishing command to Discord API'**
  String get cmd_deploy_discord_sync_subtitle;

  /// Discord Sync
  ///
  /// In en, this message translates to:
  /// **'Discord Sync'**
  String get cmd_deploy_discord_sync_title;

  /// Deployment failed
  ///
  /// In en, this message translates to:
  /// **'Deployment failed'**
  String get cmd_deploy_failed_title;

  /// Instant update of your bot runner
  ///
  /// In en, this message translates to:
  /// **'Instant update of your bot runner'**
  String get cmd_deploy_hot_reload_subtitle;

  /// Hot Reload
  ///
  /// In en, this message translates to:
  /// **'Hot Reload'**
  String get cmd_deploy_hot_reload_title;

  /// Deployment in progress...
  ///
  /// In en, this message translates to:
  /// **'Deployment in progress...'**
  String get cmd_deploy_in_progress_title;

  /// Saving command to device
  ///
  /// In en, this message translates to:
  /// **'Saving command to device'**
  String get cmd_deploy_local_save_subtitle;

  /// Local Save
  ///
  /// In en, this message translates to:
  /// **'Local Save'**
  String get cmd_deploy_local_save_title;

  /// Applying hot reload configuration
  ///
  /// In en, this message translates to:
  /// **'Applying hot reload configuration'**
  String get cmd_deploy_reload_bot_subtitle;

  /// Reloading Bot
  ///
  /// In en, this message translates to:
  /// **'Reloading Bot'**
  String get cmd_deploy_reload_bot_title;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get cmd_deploy_retry_button;

  /// Deployment successful!
  ///
  /// In en, this message translates to:
  /// **'Deployment successful!'**
  String get cmd_deploy_success_title;

  /// Success message shown when command deployed successfully
  ///
  /// In en, this message translates to:
  /// **'Command \"{name}\" deployed and active!'**
  String cmd_deploy_success_toast(String name);

  /// Advanced mode
  ///
  /// In en, this message translates to:
  /// **'Advanced mode'**
  String get cmd_editor_mode_advanced;

  /// Full editor with custom response, options, and action builder.
  ///
  /// In en, this message translates to:
  /// **'Full editor with custom response, options, and action builder.'**
  String get cmd_editor_mode_advanced_desc;

  /// Advanced mode is locked for this command.
  ///
  /// In en, this message translates to:
  /// **'Advanced mode is locked for this command.'**
  String get cmd_editor_mode_locked;

  /// Simplified mode
  ///
  /// In en, this message translates to:
  /// **'Simplified mode'**
  String get cmd_editor_mode_simple;

  /// Build a command quickly with guided options and preconfigured actions.
  ///
  /// In en, this message translates to:
  /// **'Build a command quickly with guided options and preconfigured actions.'**
  String get cmd_editor_mode_simple_desc;

  /// Switch to advanced mode
  ///
  /// In en, this message translates to:
  /// **'Switch to advanced mode'**
  String get cmd_editor_mode_switch_adv;

  /// Switch
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get cmd_editor_mode_switch_adv_confirm;

  /// This switch is one-way for this command. You won’t be able to return to simplified mode.
  ///
  /// In en, this message translates to:
  /// **'This switch is one-way for this command. You won’t be able to return to simplified mode.'**
  String get cmd_editor_mode_switch_adv_content;

  /// Switch to advanced mode?
  ///
  /// In en, this message translates to:
  /// **'Switch to advanced mode?'**
  String get cmd_editor_mode_switch_adv_title;

  /// Editing mode
  ///
  /// In en, this message translates to:
  /// **'Editing mode'**
  String get cmd_editor_mode_title;

  /// Please fill all fields
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get cmd_error_fill_fields;

  /// BDFD Script mode
  ///
  /// In en, this message translates to:
  /// **'BDFD Script mode'**
  String get cmd_execution_mode_bdfd;

  /// Write the command body as BDFD-style script while keeping command definition visual.
  ///
  /// In en, this message translates to:
  /// **'Write the command body as BDFD-style script while keeping command definition visual.'**
  String get cmd_execution_mode_bdfd_desc;

  /// The script is compiled to internal actions. Diagnostics are shown while editing; invalid scripts fail when the command runs.
  ///
  /// In en, this message translates to:
  /// **'The script is compiled to internal actions. Diagnostics are shown while editing; invalid scripts fail when the command runs.'**
  String get cmd_execution_mode_bdfd_note;

  /// Dart Direct mode
  ///
  /// In en, this message translates to:
  /// **'Dart Direct mode'**
  String get cmd_execution_mode_dart;

  /// Write the command body directly in Dart with runtime diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Write the command body directly in Dart with runtime diagnostics.'**
  String get cmd_execution_mode_dart_desc;

  /// Dart code is compiled at runtime through the sandboxed engine. Keep scripts deterministic and return a value when needed.
  ///
  /// In en, this message translates to:
  /// **'Dart code is compiled at runtime through the sandboxed engine. Keep scripts deterministic and return a value when needed.'**
  String get cmd_execution_mode_dart_note;

  /// Label for JavaScript execution mode radio option
  ///
  /// In en, this message translates to:
  /// **'JavaScript'**
  String get cmd_execution_mode_javascript;

  /// Description for JavaScript execution mode radio option
  ///
  /// In en, this message translates to:
  /// **'Write custom JS code for this command.'**
  String get cmd_execution_mode_javascript_desc;

  /// Information note for JavaScript execution mode
  ///
  /// In en, this message translates to:
  /// **'All BDFD functions are available as async JS functions. Use ctx.authorId, ctx.channelId, vars[\'key\'] to access context and variables.'**
  String get cmd_execution_mode_javascript_note;

  /// Command metadata stays in the visual builder. Choose how the command body should run.
  ///
  /// In en, this message translates to:
  /// **'Command metadata stays in the visual builder. Choose how the command body should run.'**
  String get cmd_execution_mode_desc;

  /// Execution mode
  ///
  /// In en, this message translates to:
  /// **'Execution mode'**
  String get cmd_execution_mode_title;

  /// Workflow mode
  ///
  /// In en, this message translates to:
  /// **'Workflow mode'**
  String get cmd_execution_mode_workflow;

  /// Use the existing visual response and action builder.
  ///
  /// In en, this message translates to:
  /// **'Use the existing visual response and action builder.'**
  String get cmd_execution_mode_workflow_desc;

  /// Workflow mode is the current production path and remains fully supported.
  ///
  /// In en, this message translates to:
  /// **'Workflow mode is the current production path and remains fully supported.'**
  String get cmd_execution_mode_workflow_note;

  /// Migrate
  ///
  /// In en, this message translates to:
  /// **'Migrate'**
  String get cmd_migrate_bdfd_to_dart_action;

  /// Generate a Dart migration scaffold from your current BDFD script.
  ///
  /// In en, this message translates to:
  /// **'Generate a Dart migration scaffold from your current BDFD script.'**
  String get cmd_migrate_bdfd_to_dart_desc;

  /// This command could not be fully loaded (offline or token invalid). Connect a valid token to edit.
  ///
  /// In en, this message translates to:
  /// **'This command could not be fully loaded (offline or token invalid). Connect a valid token to edit.'**
  String get cmd_offline_incomplete_warning;

  /// Open variable documentation
  ///
  /// In en, this message translates to:
  /// **'Open variable documentation'**
  String get cmd_show_variables;

  /// Add role
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get cmd_simple_action_add_role;

  /// Give the selected /role to the selected /user.
  ///
  /// In en, this message translates to:
  /// **'Give the selected /role to the selected /user.'**
  String get cmd_simple_action_add_role_desc;

  /// Ban user
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get cmd_simple_action_ban;

  /// 0 to 7 days of recent messages to delete
  ///
  /// In en, this message translates to:
  /// **'0 to 7 days of recent messages to delete'**
  String get cmd_simple_action_ban_delete_days_hint;

  /// Ban delete message days
  ///
  /// In en, this message translates to:
  /// **'Ban delete message days'**
  String get cmd_simple_action_ban_delete_days_label;

  /// Ban the selected /user from the server.
  ///
  /// In en, this message translates to:
  /// **'Ban the selected /user from the server.'**
  String get cmd_simple_action_ban_desc;

  /// Create invite
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get cmd_simple_action_create_invite;

  /// Create an invite for the current channel or an optional /channel.
  ///
  /// In en, this message translates to:
  /// **'Create an invite for the current channel or an optional /channel.'**
  String get cmd_simple_action_create_invite_desc;

  /// Create poll
  ///
  /// In en, this message translates to:
  /// **'Create poll'**
  String get cmd_simple_action_create_poll;

  /// Create a poll with a dynamic /question and fixed answer choices.
  ///
  /// In en, this message translates to:
  /// **'Create a poll with a dynamic /question and fixed answer choices.'**
  String get cmd_simple_action_create_poll_desc;

  /// Delete messages
  ///
  /// In en, this message translates to:
  /// **'Delete messages'**
  String get cmd_simple_action_delete;

  /// Used when /count is not provided
  ///
  /// In en, this message translates to:
  /// **'Used when /count is not provided'**
  String get cmd_simple_action_delete_default_count_hint;

  /// Default delete count
  ///
  /// In en, this message translates to:
  /// **'Default delete count'**
  String get cmd_simple_action_delete_default_count_label;

  /// Delete messages in the current channel (optional /count).
  ///
  /// In en, this message translates to:
  /// **'Delete messages in the current channel (optional /count).'**
  String get cmd_simple_action_delete_desc;

  /// Kick user
  ///
  /// In en, this message translates to:
  /// **'Kick user'**
  String get cmd_simple_action_kick;

  /// Kick the selected /user from the server.
  ///
  /// In en, this message translates to:
  /// **'Kick the selected /user from the server.'**
  String get cmd_simple_action_kick_desc;

  /// Mute user
  ///
  /// In en, this message translates to:
  /// **'Mute user'**
  String get cmd_simple_action_mute;

  /// Temporarily mute the selected /user.
  ///
  /// In en, this message translates to:
  /// **'Temporarily mute the selected /user.'**
  String get cmd_simple_action_mute_desc;

  /// Examples: 10m, 2h, 1d, or raw seconds
  ///
  /// In en, this message translates to:
  /// **'Examples: 10m, 2h, 1d, or raw seconds'**
  String get cmd_simple_action_mute_duration_hint;

  /// Mute duration
  ///
  /// In en, this message translates to:
  /// **'Mute duration'**
  String get cmd_simple_action_mute_duration_label;

  /// Pin message
  ///
  /// In en, this message translates to:
  /// **'Pin message'**
  String get cmd_simple_action_pin;

  /// Pin a message in the current channel using /message_id.
  ///
  /// In en, this message translates to:
  /// **'Pin a message in the current channel using /message_id.'**
  String get cmd_simple_action_pin_desc;

  /// Optional reason shared by moderation actions
  ///
  /// In en, this message translates to:
  /// **'Optional reason shared by moderation actions'**
  String get cmd_simple_action_reason_hint;

  /// Audit log reason
  ///
  /// In en, this message translates to:
  /// **'Audit log reason'**
  String get cmd_simple_action_reason_label;

  /// Remove role
  ///
  /// In en, this message translates to:
  /// **'Remove role'**
  String get cmd_simple_action_remove_role;

  /// Remove the selected /role from the selected /user.
  ///
  /// In en, this message translates to:
  /// **'Remove the selected /role from the selected /user.'**
  String get cmd_simple_action_remove_role_desc;

  /// Send message
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get cmd_simple_action_send_message;

  /// Send an additional message in the current channel.
  ///
  /// In en, this message translates to:
  /// **'Send an additional message in the current channel.'**
  String get cmd_simple_action_send_message_desc;

  /// Message sent by the Send Message action
  ///
  /// In en, this message translates to:
  /// **'Message sent by the Send Message action'**
  String get cmd_simple_action_send_message_hint;

  /// Action message
  ///
  /// In en, this message translates to:
  /// **'Action message'**
  String get cmd_simple_action_send_message_label;

  /// Unban user
  ///
  /// In en, this message translates to:
  /// **'Unban user'**
  String get cmd_simple_action_unban;

  /// Unban a user with a provided /user_id string.
  ///
  /// In en, this message translates to:
  /// **'Unban a user with a provided /user_id string.'**
  String get cmd_simple_action_unban_desc;

  /// Unmute user
  ///
  /// In en, this message translates to:
  /// **'Unmute user'**
  String get cmd_simple_action_unmute;

  /// Remove the timeout from the selected /user.
  ///
  /// In en, this message translates to:
  /// **'Remove the timeout from the selected /user.'**
  String get cmd_simple_action_unmute_desc;

  /// Unpin message
  ///
  /// In en, this message translates to:
  /// **'Unpin message'**
  String get cmd_simple_action_unpin;

  /// Unpin a message in the current channel using /message_id.
  ///
  /// In en, this message translates to:
  /// **'Unpin a message in the current channel using /message_id.'**
  String get cmd_simple_action_unpin_desc;

  /// Select what this command should do. Options are generated automatically.
  ///
  /// In en, this message translates to:
  /// **'Select what this command should do. Options are generated automatically.'**
  String get cmd_simple_actions_desc;

  /// Simplified actions
  ///
  /// In en, this message translates to:
  /// **'Simplified actions'**
  String get cmd_simple_actions_title;

  /// Ban user and Unban user cannot be enabled together in simplified mode.
  ///
  /// In en, this message translates to:
  /// **'Ban user and Unban user cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_ban_unban;

  /// Mute user and Unmute user cannot be enabled together in simplified mode.
  ///
  /// In en, this message translates to:
  /// **'Mute user and Unmute user cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_mute_unmute;

  /// Pin message and Unpin message cannot be enabled together in simplified mode.
  ///
  /// In en, this message translates to:
  /// **'Pin message and Unpin message cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_pin_unpin;

  /// Fine-tune the generated actions without leaving simplified mode.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the generated actions without leaving simplified mode.'**
  String get cmd_simple_execution_desc;

  /// Execution settings
  ///
  /// In en, this message translates to:
  /// **'Execution settings'**
  String get cmd_simple_execution_title;

  /// No options generated yet. Select at least one action.
  ///
  /// In en, this message translates to:
  /// **'No options generated yet. Select at least one action.'**
  String get cmd_simple_generated_none;

  /// Generated command options
  ///
  /// In en, this message translates to:
  /// **'Generated command options'**
  String get cmd_simple_generated_options;

  /// Message and channel actions that work in the current context.
  ///
  /// In en, this message translates to:
  /// **'Message and channel actions that work in the current context.'**
  String get cmd_simple_group_messages_desc;

  /// Messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get cmd_simple_group_messages_title;

  /// Member and moderation actions with guided options.
  ///
  /// In en, this message translates to:
  /// **'Member and moderation actions with guided options.'**
  String get cmd_simple_group_moderation_desc;

  /// Moderation
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get cmd_simple_group_moderation_title;

  /// Helpful extras such as invites and polls.
  ///
  /// In en, this message translates to:
  /// **'Helpful extras such as invites and polls.'**
  String get cmd_simple_group_utility_desc;

  /// Utility
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get cmd_simple_group_utility_title;

  /// 0 for no expiry, up to 604800
  ///
  /// In en, this message translates to:
  /// **'0 for no expiry, up to 604800'**
  String get cmd_simple_invite_max_age_hint;

  /// Invite expiry must be a number between 0 and 604800 seconds.
  ///
  /// In en, this message translates to:
  /// **'Invite expiry must be a number between 0 and 604800 seconds.'**
  String get cmd_simple_invite_max_age_invalid;

  /// Invite expiry (seconds)
  ///
  /// In en, this message translates to:
  /// **'Invite expiry (seconds)'**
  String get cmd_simple_invite_max_age_label;

  /// 0 for unlimited uses
  ///
  /// In en, this message translates to:
  /// **'0 for unlimited uses'**
  String get cmd_simple_invite_max_uses_hint;

  /// Invite max uses must be a number between 0 and 1000000.
  ///
  /// In en, this message translates to:
  /// **'Invite max uses must be a number between 0 and 1000000.'**
  String get cmd_simple_invite_max_uses_invalid;

  /// Max uses
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get cmd_simple_invite_max_uses_label;

  /// Defaults used by the generated Create Invite action.
  ///
  /// In en, this message translates to:
  /// **'Defaults used by the generated Create Invite action.'**
  String get cmd_simple_invite_settings_desc;

  /// Invite settings
  ///
  /// In en, this message translates to:
  /// **'Invite settings'**
  String get cmd_simple_invite_settings_title;

  /// Members are removed if they leave before getting a role.
  ///
  /// In en, this message translates to:
  /// **'Members are removed if they leave before getting a role.'**
  String get cmd_simple_invite_temporary_desc;

  /// Temporary membership
  ///
  /// In en, this message translates to:
  /// **'Temporary membership'**
  String get cmd_simple_invite_temporary_label;

  /// Always create a new invite instead of reusing an existing one.
  ///
  /// In en, this message translates to:
  /// **'Always create a new invite instead of reusing an existing one.'**
  String get cmd_simple_invite_unique_desc;

  /// Force unique invite
  ///
  /// In en, this message translates to:
  /// **'Force unique invite'**
  String get cmd_simple_invite_unique_label;

  /// /channel (Channel)
  ///
  /// In en, this message translates to:
  /// **'/channel (Channel)'**
  String get cmd_simple_option_channel;

  /// Optional channel override for invite creation
  ///
  /// In en, this message translates to:
  /// **'Optional channel override for invite creation'**
  String get cmd_simple_option_channel_desc;

  /// /count (Integer)
  ///
  /// In en, this message translates to:
  /// **'/count (Integer)'**
  String get cmd_simple_option_count;

  /// Number of messages to delete
  ///
  /// In en, this message translates to:
  /// **'Number of messages to delete'**
  String get cmd_simple_option_count_desc;

  /// /message_id (Text)
  ///
  /// In en, this message translates to:
  /// **'/message_id (Text)'**
  String get cmd_simple_option_message_id;

  /// Message ID to target
  ///
  /// In en, this message translates to:
  /// **'Message ID to target'**
  String get cmd_simple_option_message_id_desc;

  /// /question (Text)
  ///
  /// In en, this message translates to:
  /// **'/question (Text)'**
  String get cmd_simple_option_question;

  /// Poll question
  ///
  /// In en, this message translates to:
  /// **'Poll question'**
  String get cmd_simple_option_question_desc;

  /// /role (Role)
  ///
  /// In en, this message translates to:
  /// **'/role (Role)'**
  String get cmd_simple_option_role;

  /// Target role
  ///
  /// In en, this message translates to:
  /// **'Target role'**
  String get cmd_simple_option_role_desc;

  /// /user (User)
  ///
  /// In en, this message translates to:
  /// **'/user (User)'**
  String get cmd_simple_option_user;

  /// Target user
  ///
  /// In en, this message translates to:
  /// **'Target user'**
  String get cmd_simple_option_user_desc;

  /// /user_id (Text)
  ///
  /// In en, this message translates to:
  /// **'/user_id (Text)'**
  String get cmd_simple_option_user_id;

  /// User ID to unban
  ///
  /// In en, this message translates to:
  /// **'User ID to unban'**
  String get cmd_simple_option_user_id_desc;

  /// One answer per line, or use commas. Minimum 2, maximum 10.
  ///
  /// In en, this message translates to:
  /// **'One answer per line, or use commas. Minimum 2, maximum 10.'**
  String get cmd_simple_poll_answers_hint;

  /// Poll answers must contain between 2 and 10 non-empty choices.
  ///
  /// In en, this message translates to:
  /// **'Poll answers must contain between 2 and 10 non-empty choices.'**
  String get cmd_simple_poll_answers_invalid;

  /// Poll answers
  ///
  /// In en, this message translates to:
  /// **'Poll answers'**
  String get cmd_simple_poll_answers_label;

  /// From 1 to 168 hours
  ///
  /// In en, this message translates to:
  /// **'From 1 to 168 hours'**
  String get cmd_simple_poll_duration_hint;

  /// Poll duration must be a number between 1 and 168 hours.
  ///
  /// In en, this message translates to:
  /// **'Poll duration must be a number between 1 and 168 hours.'**
  String get cmd_simple_poll_duration_invalid;

  /// Poll duration (hours)
  ///
  /// In en, this message translates to:
  /// **'Poll duration (hours)'**
  String get cmd_simple_poll_duration_label;

  /// Users can select more than one choice.
  ///
  /// In en, this message translates to:
  /// **'Users can select more than one choice.'**
  String get cmd_simple_poll_multiselect_desc;

  /// Allow multiple answers
  ///
  /// In en, this message translates to:
  /// **'Allow multiple answers'**
  String get cmd_simple_poll_multiselect_label;

  /// Defaults used by the generated Create Poll action.
  ///
  /// In en, this message translates to:
  /// **'Defaults used by the generated Create Poll action.'**
  String get cmd_simple_poll_settings_desc;

  /// Poll settings
  ///
  /// In en, this message translates to:
  /// **'Poll settings'**
  String get cmd_simple_poll_settings_title;

  /// Message sent back to the user after actions are executed.
  ///
  /// In en, this message translates to:
  /// **'Message sent back to the user after actions are executed.'**
  String get cmd_simple_response_desc;

  /// Optional embeds sent with the final response.
  ///
  /// In en, this message translates to:
  /// **'Optional embeds sent with the final response.'**
  String get cmd_simple_response_embeds_desc;

  /// Response embeds
  ///
  /// In en, this message translates to:
  /// **'Response embeds'**
  String get cmd_simple_response_embeds_title;

  /// Done ✅
  ///
  /// In en, this message translates to:
  /// **'Done ✅'**
  String get cmd_simple_response_hint;

  /// Final response
  ///
  /// In en, this message translates to:
  /// **'Final response'**
  String get cmd_simple_response_title;

  /// Ephemeral
  ///
  /// In en, this message translates to:
  /// **'Ephemeral'**
  String get cmd_simple_response_visibility_ephemeral;

  /// Response visibility
  ///
  /// In en, this message translates to:
  /// **'Response visibility'**
  String get cmd_simple_response_visibility_label;

  /// Public
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get cmd_simple_response_visibility_public;

  /// Please fill the action message before saving.
  ///
  /// In en, this message translates to:
  /// **'Please fill the action message before saving.'**
  String get cmd_simple_send_message_required;

  /// Command Variables
  ///
  /// In en, this message translates to:
  /// **'Command Variables'**
  String get cmd_variables_title;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get command_awaited_error;

  /// Example: <numeric> or <yes/no/cancel>
  ///
  /// In en, this message translates to:
  /// **'Example: <numeric> or <yes/no/cancel>'**
  String get command_awaited_filter_hint;

  /// Filter (optional)
  ///
  /// In en, this message translates to:
  /// **'Filter (optional)'**
  String get command_awaited_filter_label;

  /// Example: say
  ///
  /// In en, this message translates to:
  /// **'Example: say'**
  String get command_awaited_name_hint;

  /// Awaited callback name
  ///
  /// In en, this message translates to:
  /// **'Awaited callback name'**
  String get command_awaited_name_label;

  /// Awaited callback preset
  ///
  /// In en, this message translates to:
  /// **'Awaited callback preset'**
  String get command_awaited_preset_active;

  /// Use Awaited Callback Preset
  ///
  /// In en, this message translates to:
  /// **'Use Awaited Callback Preset'**
  String get command_awaited_preset_button;

  /// The command name is generated for you and saved as an internal legacy callback.
  ///
  /// In en, this message translates to:
  /// **'The command name is generated for you and saved as an internal legacy callback.'**
  String get command_awaited_preset_desc;

  /// Success
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get command_awaited_success;

  /// Bot DM
  ///
  /// In en, this message translates to:
  /// **'Bot DM'**
  String get command_context_bot_dm;

  /// Group DM / Other
  ///
  /// In en, this message translates to:
  /// **'Group DM / Other'**
  String get command_context_group_dm;

  /// Guild
  ///
  /// In en, this message translates to:
  /// **'Guild'**
  String get command_context_guild;

  /// Command description must be at most 100 characters long
  ///
  /// In en, this message translates to:
  /// **'Command description must be at most 100 characters long'**
  String get command_description_length;

  /// Please enter a command description
  ///
  /// In en, this message translates to:
  /// **'Please enter a command description'**
  String get command_description_required;

  /// Edit Raw Name
  ///
  /// In en, this message translates to:
  /// **'Edit Raw Name'**
  String get command_edit_raw_name;

  /// Missing bot id for local command save.
  ///
  /// In en, this message translates to:
  /// **'Missing bot id for local command save.'**
  String get command_error_missing_bot_id;

  /// An error occurred while executing this command.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while executing this command.'**
  String get command_execution_error;

  /// Export command payload
  ///
  /// In en, this message translates to:
  /// **'Export command payload'**
  String get command_export_tooltip;

  /// Import command payload
  ///
  /// In en, this message translates to:
  /// **'Import command payload'**
  String get command_import_tooltip;

  /// Basic metadata and availability
  ///
  /// In en, this message translates to:
  /// **'Basic metadata and availability'**
  String get command_info_desc;

  /// Command Info
  ///
  /// In en, this message translates to:
  /// **'Command Info'**
  String get command_info_title;

  /// Guild Install
  ///
  /// In en, this message translates to:
  /// **'Guild Install'**
  String get command_integration_guild;

  /// Where this command can be used
  ///
  /// In en, this message translates to:
  /// **'Where this command can be used'**
  String get command_integration_label;

  /// User Install
  ///
  /// In en, this message translates to:
  /// **'User Install'**
  String get command_integration_user;

  /// Uses positional options (example: !config #channel).
  ///
  /// In en, this message translates to:
  /// **'Uses positional options (example: !config #channel).'**
  String get command_legacy_mode_subtitle;

  /// Enable legacy mode on this command
  ///
  /// In en, this message translates to:
  /// **'Enable legacy mode on this command'**
  String get command_legacy_mode_title;

  /// Handle commands from messageCreate using <prefix><command>.
  ///
  /// In en, this message translates to:
  /// **'Handle commands from messageCreate using <prefix><command>.'**
  String get command_legacy_prefix_desc;

  /// Legacy Prefix Mode
  ///
  /// In en, this message translates to:
  /// **'Legacy Prefix Mode'**
  String get command_legacy_prefix_title;

  /// Generate an internal awaited callback trigger and switch this command to the required local legacy setup.
  ///
  /// In en, this message translates to:
  /// **'Generate an internal awaited callback trigger and switch this command to the required local legacy setup.'**
  String get command_legacy_preset_desc;

  /// Legacy preset
  ///
  /// In en, this message translates to:
  /// **'Legacy preset'**
  String get command_legacy_preset_title;

  /// Legacy response mode
  ///
  /// In en, this message translates to:
  /// **'Legacy response mode'**
  String get command_legacy_response_label;

  /// Modals are disabled in legacy mode.
  ///
  /// In en, this message translates to:
  /// **'Modals are disabled in legacy mode.'**
  String get command_modal_disabled_legacy;

  /// Generated by the awaited callback preset.
  ///
  /// In en, this message translates to:
  /// **'Generated by the awaited callback preset.'**
  String get command_name_generated;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get command_name_label;

  /// Command not found
  ///
  /// In en, this message translates to:
  /// **'Command not found'**
  String get command_not_found;

  /// Legacy positional parameters (ordered: required then optional)
  ///
  /// In en, this message translates to:
  /// **'Legacy positional parameters (ordered: required then optional)'**
  String get command_options_legacy_params;

  /// Slash-command parameters
  ///
  /// In en, this message translates to:
  /// **'Slash-command parameters'**
  String get command_options_slash_params;

  /// Command Options
  ///
  /// In en, this message translates to:
  /// **'Command Options'**
  String get command_options_title;

  /// Command payload
  ///
  /// In en, this message translates to:
  /// **'Command payload'**
  String get command_payload_hint;

  /// Administrator selected: this bypasses other permission checks.
  ///
  /// In en, this message translates to:
  /// **'Administrator selected: this bypasses other permission checks.'**
  String get command_permissions_admin_warning;

  /// Calculated Permission Bitfield
  ///
  /// In en, this message translates to:
  /// **'Calculated Permission Bitfield'**
  String get command_permissions_bitfield;

  /// Automatically computed from selected permissions.
  ///
  /// In en, this message translates to:
  /// **'Automatically computed from selected permissions.'**
  String get command_permissions_bitfield_helper;

  /// {count} permission(s) selected
  ///
  /// In en, this message translates to:
  /// **'{count} permission(s) selected'**
  String command_permissions_count(int count);

  /// Default Member Permissions (optional)
  ///
  /// In en, this message translates to:
  /// **'Default Member Permissions (optional)'**
  String get command_permissions_label;

  /// No selection (everyone can use command)
  ///
  /// In en, this message translates to:
  /// **'No selection (everyone can use command)'**
  String get command_permissions_none;

  /// Tip: leave all unchecked to make the command available to everyone by default.
  ///
  /// In en, this message translates to:
  /// **'Tip: leave all unchecked to make the command available to everyone by default.'**
  String get command_permissions_tip;

  /// Select permissions
  ///
  /// In en, this message translates to:
  /// **'Select permissions'**
  String get command_permissions_title;

  /// Warning: unknown permission bits detected from saved data and preserved: {bits}
  ///
  /// In en, this message translates to:
  /// **'Warning: unknown permission bits detected from saved data and preserved: {bits}'**
  String command_permissions_unknown_bits(String bits);

  /// Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))
  ///
  /// In en, this message translates to:
  /// **'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))'**
  String get command_prefix_helper;

  /// Example: ? or ((guild.prefix | !))
  ///
  /// In en, this message translates to:
  /// **'Example: ? or ((guild.prefix | !))'**
  String get command_prefix_override_hint;

  /// Prefix override (optional)
  ///
  /// In en, this message translates to:
  /// **'Prefix override (optional)'**
  String get command_prefix_override_label;

  /// message.channel.send
  ///
  /// In en, this message translates to:
  /// **'message.channel.send'**
  String get command_response_mode_channel;

  /// message.reply
  ///
  /// In en, this message translates to:
  /// **'message.reply'**
  String get command_response_mode_reply;

  /// Scope of the command (Contexts)
  ///
  /// In en, this message translates to:
  /// **'Scope of the command (Contexts)'**
  String get command_scope_label;

  /// Choose which subcommand you are configuring.
  ///
  /// In en, this message translates to:
  /// **'Choose which subcommand you are configuring.'**
  String get command_subcommand_workflow_desc;

  /// SubCommand Workflow
  ///
  /// In en, this message translates to:
  /// **'SubCommand Workflow'**
  String get command_subcommand_workflow_title;

  /// Saved locally. Discord sync failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Discord sync failed: {error}'**
  String command_sync_failed_local(String error);

  /// Target subcommand
  ///
  /// In en, this message translates to:
  /// **'Target subcommand'**
  String get command_target_subcommand;

  /// Command Type
  ///
  /// In en, this message translates to:
  /// **'Command Type'**
  String get command_type_label;

  /// Legacy Command
  ///
  /// In en, this message translates to:
  /// **'Legacy Command'**
  String get command_type_legacy;

  /// Command type cannot be changed after creation.
  ///
  /// In en, this message translates to:
  /// **'Command type cannot be changed after creation.'**
  String get command_type_locked;

  /// Message Command
  ///
  /// In en, this message translates to:
  /// **'Message Command'**
  String get command_type_message;

  /// Slash Command
  ///
  /// In en, this message translates to:
  /// **'Slash Command'**
  String get command_type_slash;

  /// User Command
  ///
  /// In en, this message translates to:
  /// **'User Command'**
  String get command_type_user;

  /// You have unsaved changes. Discard them?
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them?'**
  String get command_unsaved_confirm;

  /// Keep editing
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get command_unsaved_keep;

  /// Unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get command_unsaved_title;

  /// All folders
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get commands_all_folders;

  /// Create command
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get commands_create_button;

  /// Create folder
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get commands_create_folder;

  /// Create command "{query}"
  ///
  /// In en, this message translates to:
  /// **'Create command \"{query}\"'**
  String commands_create_from_query(String query);

  /// Delete folder
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get commands_delete_folder;

  /// The commands inside this folder will not be deleted, only un-foldered.
  ///
  /// In en, this message translates to:
  /// **'The commands inside this folder will not be deleted, only un-foldered.'**
  String get commands_delete_folder_desc;

  /// No commands found
  ///
  /// In en, this message translates to:
  /// **'No commands found'**
  String get commands_empty;

  /// Error: {error}
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commands_error(String error);

  /// Legacy local
  ///
  /// In en, this message translates to:
  /// **'Legacy local'**
  String get commands_filter_legacy_local;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get commands_filter_template;

  /// Type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commands_filter_type_label;

  /// Optional folder name
  ///
  /// In en, this message translates to:
  /// **'Optional folder name'**
  String get commands_folder_hint;

  /// Folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get commands_folder_label;

  /// Move to folder
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get commands_move_to_folder;

  /// New folder name
  ///
  /// In en, this message translates to:
  /// **'New folder name'**
  String get commands_new_folder_hint;

  /// No folder
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get commands_no_folder;

  /// No commands match the current filters.
  ///
  /// In en, this message translates to:
  /// **'No commands match the current filters.'**
  String get commands_no_match_filters;

  /// Remove from folder
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get commands_remove_from_folder;

  /// Rename folder
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get commands_rename_folder;

  /// Organize commands
  ///
  /// In en, this message translates to:
  /// **'Organize commands'**
  String get commands_reorder_title;

  /// Search commands...
  ///
  /// In en, this message translates to:
  /// **'Search commands...'**
  String get commands_search_hint;

  /// Commands
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commands_tab;

  /// Cmd
  ///
  /// In en, this message translates to:
  /// **'Cmd'**
  String get commands_tab_short;

  /// Commands
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commands_title;

  /// Add Argument
  ///
  /// In en, this message translates to:
  /// **'Add Argument'**
  String get common_add_argument;

  /// Add Option
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get common_add_option;

  /// Add Section
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get common_add_section;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// Apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply;

  /// Back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// Bot
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get common_bot;

  /// Cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// Close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// Custom ID
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get common_custom_id;

  /// Custom ID *
  ///
  /// In en, this message translates to:
  /// **'Custom ID *'**
  String get common_custom_id_required;

  /// Default
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get common_default;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// Description
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get common_description;

  /// Disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get common_disabled;

  /// Edit
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// Enabled
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get common_enabled;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get common_import;

  /// Key
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get common_key;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get common_label;

  /// Manage Workflows
  ///
  /// In en, this message translates to:
  /// **'Manage Workflows'**
  String get common_manage_workflows;

  /// Move down
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get common_move_down;

  /// Move up
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get common_move_up;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// Next
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// None
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get common_none;

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// Operator
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get common_operator;

  /// Pick
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get common_pick;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get common_placeholder;

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// Refresh workflows
  ///
  /// In en, this message translates to:
  /// **'Refresh workflows'**
  String get common_refresh_workflows;

  /// Remove
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// Required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// Search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// Static Options
  ///
  /// In en, this message translates to:
  /// **'Static Options'**
  String get common_static_options;

  /// Style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get common_style;

  /// Type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get common_type;

  /// URL
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get common_url;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get common_value;

  /// Workflow
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get common_workflow;

  /// Accent Color (Hex, e.g. FF0000)
  ///
  /// In en, this message translates to:
  /// **'Accent Color (Hex, e.g. FF0000)'**
  String get component_accent_color;

  /// Add Checkbox Option
  ///
  /// In en, this message translates to:
  /// **'Add Checkbox Option'**
  String get component_add_checkbox_option;

  /// Add Child Component
  ///
  /// In en, this message translates to:
  /// **'Add Child Component'**
  String get component_add_child;

  /// Add Media Item
  ///
  /// In en, this message translates to:
  /// **'Add Media Item'**
  String get component_add_media_item;

  /// Add Radio Option
  ///
  /// In en, this message translates to:
  /// **'Add Radio Option'**
  String get component_add_radio_option;

  /// Add Root Component
  ///
  /// In en, this message translates to:
  /// **'Add Root Component'**
  String get component_add_root;

  /// Add Text Display
  ///
  /// In en, this message translates to:
  /// **'Add Text Display'**
  String get component_add_text_display;

  /// Add Component
  ///
  /// In en, this message translates to:
  /// **'Add Component'**
  String get component_add_tooltip;

  /// Style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get component_block_label_style;

  /// Workflow
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get component_block_workflow;

  /// Checkbox Options
  ///
  /// In en, this message translates to:
  /// **'Checkbox Options'**
  String get component_checkbox_options;

  /// Checked by default
  ///
  /// In en, this message translates to:
  /// **'Checked by default'**
  String get component_checked_by_default;

  /// Choose Color
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get component_choose_color;

  /// Component to Wrap:
  ///
  /// In en, this message translates to:
  /// **'Component to Wrap:'**
  String get component_component_to_wrap;

  /// Custom ID
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get component_custom_id;

  /// Custom ID *
  ///
  /// In en, this message translates to:
  /// **'Custom ID *'**
  String get component_custom_id_required;

  /// Choice
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get component_default_choice_label;

  /// Option
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get component_default_option_label;

  /// Empty
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get component_empty_option;

  /// File URL
  ///
  /// In en, this message translates to:
  /// **'File URL'**
  String get component_file_url;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get component_label;

  /// Label Title
  ///
  /// In en, this message translates to:
  /// **'Label Title'**
  String get component_label_title;

  /// Markdown Content
  ///
  /// In en, this message translates to:
  /// **'Markdown Content'**
  String get component_markdown_content;

  /// Max Selections
  ///
  /// In en, this message translates to:
  /// **'Max Selections'**
  String get component_max_selections;

  /// Image / Video URL
  ///
  /// In en, this message translates to:
  /// **'Image / Video URL'**
  String get component_media_url;

  /// Media URLs
  ///
  /// In en, this message translates to:
  /// **'Media URLs'**
  String get component_media_urls;

  /// Min Selections
  ///
  /// In en, this message translates to:
  /// **'Min Selections'**
  String get component_min_selections;

  /// New Checkbox
  ///
  /// In en, this message translates to:
  /// **'New Checkbox'**
  String get component_new_checkbox;

  /// New Option
  ///
  /// In en, this message translates to:
  /// **'New Option'**
  String get component_new_option;

  /// New Radio
  ///
  /// In en, this message translates to:
  /// **'New Radio'**
  String get component_new_radio;

  /// Editor not implemented yet
  ///
  /// In en, this message translates to:
  /// **'Editor not implemented yet'**
  String get component_not_implemented;

  /// On click, the workflow
  ///
  /// In en, this message translates to:
  /// **'On click, the workflow'**
  String get component_on_click_workflow;

  /// On select, the workflow
  ///
  /// In en, this message translates to:
  /// **'On select, the workflow'**
  String get component_on_select_workflow;

  /// Options
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get component_options;

  /// Pick Accent Color
  ///
  /// In en, this message translates to:
  /// **'Pick Accent Color'**
  String get component_pick_accent_color;

  /// Placeholder
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get component_placeholder;

  /// Radio Options
  ///
  /// In en, this message translates to:
  /// **'Radio Options'**
  String get component_radio_options;

  /// This component will be removed from the layout. Continue?
  ///
  /// In en, this message translates to:
  /// **'This component will be removed from the layout. Continue?'**
  String get component_remove_confirm;

  /// Remove action row
  ///
  /// In en, this message translates to:
  /// **'Remove action row'**
  String get component_remove_row_title;

  /// Remove component
  ///
  /// In en, this message translates to:
  /// **'Remove component'**
  String get component_remove_title;

  /// Accessory Node (Optional)
  ///
  /// In en, this message translates to:
  /// **'Accessory Node (Optional)'**
  String get component_section_accessory;

  /// Text Displays
  ///
  /// In en, this message translates to:
  /// **'Text Displays'**
  String get component_section_text_displays;

  /// Selection Range
  ///
  /// In en, this message translates to:
  /// **'Selection Range'**
  String get component_selection_range;

  /// Large Spacing
  ///
  /// In en, this message translates to:
  /// **'Large Spacing'**
  String get component_spacing_large;

  /// Small Spacing
  ///
  /// In en, this message translates to:
  /// **'Small Spacing'**
  String get component_spacing_small;

  /// Style
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get component_style;

  /// Thumbnail URL
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get component_thumbnail_url;

  /// Unknown component
  ///
  /// In en, this message translates to:
  /// **'Unknown component'**
  String get component_unknown_component;

  /// URL
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get component_url;

  /// Required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get component_validation_required;

  /// Component value hint
  ///
  /// In en, this message translates to:
  /// **'Component value hint'**
  String get component_value_hint;

  /// Visible Divider Line
  ///
  /// In en, this message translates to:
  /// **'Visible Divider Line'**
  String get component_visible_divider;

  /// Example: ticketId = ((opts.ticket))
  ///
  /// In en, this message translates to:
  /// **'Example: ticketId = ((opts.ticket))'**
  String get component_workflow_args_hint;

  /// Workflow Call Arguments
  ///
  /// In en, this message translates to:
  /// **'Workflow Call Arguments'**
  String get component_workflow_args_title;

  /// Saved workflow name to run on click
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name to run on click'**
  String get component_workflow_click_hint;

  /// Call Workflow (optional)
  ///
  /// In en, this message translates to:
  /// **'Call Workflow (optional)'**
  String get component_workflow_optional;

  /// Saved workflow name to run on selection
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name to run on selection'**
  String get component_workflow_select_hint;

  /// Confirm
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Copy
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Create
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Empty script — start typing to see Dart diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Empty script — start typing to see Dart diagnostics.'**
  String get dart_editor_empty;

  /// Tap to open Dart editor
  ///
  /// In en, this message translates to:
  /// **'Tap to open Dart editor'**
  String get dart_editor_tap_hint;

  /// Dart Editor
  ///
  /// In en, this message translates to:
  /// **'Dart Editor'**
  String get dart_editor_title;

  /// Analysis Period
  ///
  /// In en, this message translates to:
  /// **'Analysis Period'**
  String get dashboard_analysis_period;

  /// Could not load stats: {error}
  ///
  /// In en, this message translates to:
  /// **'Could not load stats: {error}'**
  String dashboard_error(String error);

  /// Error rate
  ///
  /// In en, this message translates to:
  /// **'Error rate'**
  String get dashboard_error_rate;

  /// Execution health
  ///
  /// In en, this message translates to:
  /// **'Execution health'**
  String get dashboard_execution_health_title;

  /// {count} executions
  ///
  /// In en, this message translates to:
  /// **'{count} executions'**
  String dashboard_executions(int count);

  /// Failed
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get dashboard_failed_commands;

  /// Loading stats...
  ///
  /// In en, this message translates to:
  /// **'Loading stats...'**
  String get dashboard_loading;

  /// No command usage data yet. Run your bot to start tracking.
  ///
  /// In en, this message translates to:
  /// **'No command usage data yet. Run your bot to start tracking.'**
  String get dashboard_no_data;

  /// Latency p50
  ///
  /// In en, this message translates to:
  /// **'Latency p50'**
  String get dashboard_p50_latency;

  /// Latency p95
  ///
  /// In en, this message translates to:
  /// **'Latency p95'**
  String get dashboard_p95_latency;

  /// Last 24h
  ///
  /// In en, this message translates to:
  /// **'Last 24h'**
  String get dashboard_period_24h;

  /// Last 30 days
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get dashboard_period_30d;

  /// Last 7 days
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboard_period_7d;

  /// Unlock error rate, latency percentiles, and locale insights.
  ///
  /// In en, this message translates to:
  /// **'Unlock error rate, latency percentiles, and locale insights.'**
  String get dashboard_premium_analytics_desc;

  /// Premium analytics
  ///
  /// In en, this message translates to:
  /// **'Premium analytics'**
  String get dashboard_premium_analytics_title;

  /// Refresh execution servers
  ///
  /// In en, this message translates to:
  /// **'Refresh execution servers'**
  String get dashboard_refresh_sources_tooltip;

  /// Connect to a runner to see command usage stats.
  ///
  /// In en, this message translates to:
  /// **'Connect to a runner to see command usage stats.'**
  String get dashboard_requires_runner;

  /// {count} in selected period
  ///
  /// In en, this message translates to:
  /// **'{count} in selected period'**
  String dashboard_selected_period_total(int count);

  /// Stats shown are from the currently configured runner only. If you run bots on multiple runners, this view may be incomplete.
  ///
  /// In en, this message translates to:
  /// **'Stats shown are from the currently configured runner only. If you run bots on multiple runners, this view may be incomplete.'**
  String get dashboard_single_runner_notice;

  /// Usage over time
  ///
  /// In en, this message translates to:
  /// **'Usage over time'**
  String get dashboard_timeline;

  /// Dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_title;

  /// Top commands
  ///
  /// In en, this message translates to:
  /// **'Top commands'**
  String get dashboard_top_commands;

  /// Top locales
  ///
  /// In en, this message translates to:
  /// **'Top locales'**
  String get dashboard_top_locales;

  /// Total commands
  ///
  /// In en, this message translates to:
  /// **'Total commands'**
  String get dashboard_total;

  /// Clear replays
  ///
  /// In en, this message translates to:
  /// **'Clear replays'**
  String get debug_replay_clear;

  /// All recorded replays will be deleted. Continue?
  ///
  /// In en, this message translates to:
  /// **'All recorded replays will be deleted. Continue?'**
  String get debug_replay_clear_confirm;

  /// Clear replays
  ///
  /// In en, this message translates to:
  /// **'Clear replays'**
  String get debug_replay_clear_title;

  /// DURATION
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get debug_replay_duration_label;

  /// Capturing… Run a command to record a replay.
  ///
  /// In en, this message translates to:
  /// **'Capturing… Run a command to record a replay.'**
  String get debug_replay_empty_capturing;

  /// Capture is off. Enable it and run a command to record a replay.
  ///
  /// In en, this message translates to:
  /// **'Capture is off. Enable it and run a command to record a replay.'**
  String get debug_replay_empty_idle;

  /// Loop depth {depth}, iteration {iteration}
  ///
  /// In en, this message translates to:
  /// **'Loop depth {depth}, iteration {iteration}'**
  String debug_replay_loop_info(int depth, int iteration);

  /// Overview
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get debug_replay_overview;

  /// Pause
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get debug_replay_pause;

  /// Play
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get debug_replay_play;

  /// Record and replay your command executions step by step. See exactly what each action did, how long it took, and where errors occurred.
  ///
  /// In en, this message translates to:
  /// **'Record and replay your command executions step by step. See exactly what each action did, how long it took, and where errors occurred.'**
  String get debug_replay_premium_desc;

  /// Visual Debugger Replay
  ///
  /// In en, this message translates to:
  /// **'Visual Debugger Replay'**
  String get debug_replay_premium_title;

  /// (no result)
  ///
  /// In en, this message translates to:
  /// **'(no result)'**
  String get debug_replay_result_empty;

  /// RESULT
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get debug_replay_result_label;

  /// Enable capture
  ///
  /// In en, this message translates to:
  /// **'Enable capture'**
  String get debug_replay_start_capture;

  /// +{ms} ms from start
  ///
  /// In en, this message translates to:
  /// **'+{ms} ms from start'**
  String debug_replay_start_offset(int ms);

  /// Previous step
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get debug_replay_step_back;

  /// First step
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get debug_replay_step_first;

  /// Next step
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get debug_replay_step_forward;

  /// Last step
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get debug_replay_step_last;

  /// Disable capture
  ///
  /// In en, this message translates to:
  /// **'Disable capture'**
  String get debug_replay_stop_capture;

  /// Debugger Replay
  ///
  /// In en, this message translates to:
  /// **'Debugger Replay'**
  String get debug_replay_title;

  /// (no variables)
  ///
  /// In en, this message translates to:
  /// **'(no variables)'**
  String get debug_replay_variables_empty;

  /// VARIABLES
  ///
  /// In en, this message translates to:
  /// **'VARIABLES'**
  String get debug_replay_variables_label;

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Set explicit timeout and retries in your service layer when possible.
  ///
  /// In en, this message translates to:
  /// **'Set explicit timeout and retries in your service layer when possible.'**
  String get doc_action_http_request_checklist_l1;

  /// Store API keys in globals or secure backend, never hardcode tokens.
  ///
  /// In en, this message translates to:
  /// **'Store API keys in globals or secure backend, never hardcode tokens.'**
  String get doc_action_http_request_checklist_l2;

  /// Validate status code and response body before next actions.
  ///
  /// In en, this message translates to:
  /// **'Validate status code and response body before next actions.'**
  String get doc_action_http_request_checklist_l3;

  /// Reliability Checklist
  ///
  /// In en, this message translates to:
  /// **'Reliability Checklist'**
  String get doc_action_http_request_section_checklist;

  /// Executes an external HTTP call inside a workflow.
  ///
  /// In en, this message translates to:
  /// **'Executes an external HTTP call inside a workflow.'**
  String get doc_action_http_request_subtitle;

  /// Use this for webhooks, internal APIs, moderation services, AI endpoints, and integrations.
  ///
  /// In en, this message translates to:
  /// **'Use this for webhooks, internal APIs, moderation services, AI endpoints, and integrations.'**
  String get doc_action_http_request_summary;

  /// Action: httpRequest
  ///
  /// In en, this message translates to:
  /// **'Action: httpRequest'**
  String get doc_action_http_request_title;

  /// Condition is evaluated once.
  ///
  /// In en, this message translates to:
  /// **'Condition is evaluated once.'**
  String get doc_action_if_block_execution_l1;

  /// The first matching branch executes: THEN, then ELSE IF blocks in order, then ELSE.
  ///
  /// In en, this message translates to:
  /// **'The first matching branch executes: THEN, then ELSE IF blocks in order, then ELSE.'**
  String get doc_action_if_block_execution_l2;

  /// Nested actions can include runWorkflow, API calls, and interaction replies.
  ///
  /// In en, this message translates to:
  /// **'Nested actions can include runWorkflow, API calls, and interaction replies.'**
  String get doc_action_if_block_execution_l3;

  /// Execution Model
  ///
  /// In en, this message translates to:
  /// **'Execution Model'**
  String get doc_action_if_block_section_execution;

  /// Branch execution between THEN, ELSE IF and ELSE nested action lists.
  ///
  /// In en, this message translates to:
  /// **'Branch execution between THEN, ELSE IF and ELSE nested action lists.'**
  String get doc_action_if_block_subtitle;

  /// Use this to keep a single workflow while handling several outcomes based on runtime state.
  ///
  /// In en, this message translates to:
  /// **'Use this to keep a single workflow while handling several outcomes based on runtime state.'**
  String get doc_action_if_block_summary;

  /// Action: ifBlock
  ///
  /// In en, this message translates to:
  /// **'Action: ifBlock'**
  String get doc_action_if_block_title;

  /// Keep top-level workflow thin and delegate to domain workflows.
  ///
  /// In en, this message translates to:
  /// **'Keep top-level workflow thin and delegate to domain workflows.'**
  String get doc_action_run_workflow_practices_l1;

  /// Pass explicit arguments instead of relying on implicit globals.
  ///
  /// In en, this message translates to:
  /// **'Pass explicit arguments instead of relying on implicit globals.'**
  String get doc_action_run_workflow_practices_l2;

  /// Use entry points to model sub-routines (create, close, assign, escalate).
  ///
  /// In en, this message translates to:
  /// **'Use entry points to model sub-routines (create, close, assign, escalate).'**
  String get doc_action_run_workflow_practices_l3;

  /// Best Practices
  ///
  /// In en, this message translates to:
  /// **'Best Practices'**
  String get doc_action_run_workflow_section_practices;

  /// Calls another workflow with entry point and arguments.
  ///
  /// In en, this message translates to:
  /// **'Calls another workflow with entry point and arguments.'**
  String get doc_action_run_workflow_subtitle;

  /// Core composition primitive to split business logic into reusable units.
  ///
  /// In en, this message translates to:
  /// **'Core composition primitive to split business logic into reusable units.'**
  String get doc_action_run_workflow_summary;

  /// Action: runWorkflow
  ///
  /// In en, this message translates to:
  /// **'Action: runWorkflow'**
  String get doc_action_run_workflow_title;

  /// condition.variable = ((reaction.emoji.name))
  /// condition.operator = equals
  /// condition.value = ✅
  ///
  /// In en, this message translates to:
  /// **'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅'**
  String get doc_action_stop_unless_example;

  /// You can use raw keys: message.content[0]
  ///
  /// In en, this message translates to:
  /// **'You can use raw keys: message.content[0]'**
  String get doc_action_stop_unless_format_l1;

  /// You can use wrapped variables: ((message.content[0]))
  ///
  /// In en, this message translates to:
  /// **'You can use wrapped variables: ((message.content[0]))'**
  String get doc_action_stop_unless_format_l2;

  /// Both are resolved by runtime.
  ///
  /// In en, this message translates to:
  /// **'Both are resolved by runtime.'**
  String get doc_action_stop_unless_format_l3;

  /// equals, notEquals, contains, notContains, startsWith, endsWith
  ///
  /// In en, this message translates to:
  /// **'equals, notEquals, contains, notContains, startsWith, endsWith'**
  String get doc_action_stop_unless_operators_l1;

  /// greaterThan, lessThan, greaterOrEqual, lessOrEqual
  ///
  /// In en, this message translates to:
  /// **'greaterThan, lessThan, greaterOrEqual, lessOrEqual'**
  String get doc_action_stop_unless_operators_l2;

  /// isEmpty, isNotEmpty, matches
  ///
  /// In en, this message translates to:
  /// **'isEmpty, isNotEmpty, matches'**
  String get doc_action_stop_unless_operators_l3;

  /// Condition Variable Format
  ///
  /// In en, this message translates to:
  /// **'Condition Variable Format'**
  String get doc_action_stop_unless_section_format;

  /// Supported Operators
  ///
  /// In en, this message translates to:
  /// **'Supported Operators'**
  String get doc_action_stop_unless_section_operators;

  /// Guard clause that stops workflow when condition fails.
  ///
  /// In en, this message translates to:
  /// **'Guard clause that stops workflow when condition fails.'**
  String get doc_action_stop_unless_subtitle;

  /// Use it at the top of workflows to prevent unnecessary actions when context does not match.
  ///
  /// In en, this message translates to:
  /// **'Use it at the top of workflows to prevent unnecessary actions when context does not match.'**
  String get doc_action_stop_unless_summary;

  /// Action: stopUnless
  ///
  /// In en, this message translates to:
  /// **'Action: stopUnless'**
  String get doc_action_stop_unless_title;

  /// Available Variables
  ///
  /// In en, this message translates to:
  /// **'Available Variables'**
  String get doc_available_variables;

  /// Clear search
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get doc_center_clear_search;

  /// No documentation entry matches your search.
  ///
  /// In en, this message translates to:
  /// **'No documentation entry matches your search.'**
  String get doc_center_empty;

  /// Search commands, workflows, variables, actions, intents, or examples...
  ///
  /// In en, this message translates to:
  /// **'Search commands, workflows, variables, actions, intents, or examples...'**
  String get doc_center_search_hint;

  /// Documentation Center
  ///
  /// In en, this message translates to:
  /// **'Documentation Center'**
  String get doc_center_title;

  /// Best Use Cases
  ///
  /// In en, this message translates to:
  /// **'Best Use Cases'**
  String get doc_common_section_best_use_cases;

  /// Important Notes
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get doc_common_section_important_notes;

  /// Alert staff on sensitive actions (role delete, webhook create, ban, etc.).
  ///
  /// In en, this message translates to:
  /// **'Alert staff on sensitive actions (role delete, webhook create, ban, etc.).'**
  String get doc_event_audit_log_create_best_use_l1;

  /// Route specific action types to dedicated workflows.
  ///
  /// In en, this message translates to:
  /// **'Route specific action types to dedicated workflows.'**
  String get doc_event_audit_log_create_best_use_l2;

  /// Triggered when a new audit log entry is created.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a new audit log entry is created.'**
  String get doc_event_audit_log_create_subtitle;

  /// High-value event for administrative security monitoring.
  ///
  /// In en, this message translates to:
  /// **'High-value event for administrative security monitoring.'**
  String get doc_event_audit_log_create_summary;

  /// Event: guildAuditLogCreate
  ///
  /// In en, this message translates to:
  /// **'Event: guildAuditLogCreate'**
  String get doc_event_audit_log_create_title;

  /// Detect commands typed without slash commands.
  ///
  /// In en, this message translates to:
  /// **'Detect commands typed without slash commands.'**
  String get doc_event_message_create_best_use_l1;

  /// Apply anti-spam filters before answering.
  ///
  /// In en, this message translates to:
  /// **'Apply anti-spam filters before answering.'**
  String get doc_event_message_create_best_use_l2;

  /// Route to reusable workflows based on first word or mention.
  ///
  /// In en, this message translates to:
  /// **'Route to reusable workflows based on first word or mention.'**
  String get doc_event_message_create_best_use_l3;

  /// Guard: ((message.isBot)) equals false
  /// Guard: ((message.content[0])) equals !ticket
  /// Then: runWorkflow -> ticket_manager entry=create
  ///
  /// In en, this message translates to:
  /// **'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nThen: runWorkflow -> ticket_manager entry=create'**
  String get doc_event_message_create_example;

  /// Guild Messages
  ///
  /// In en, this message translates to:
  /// **'Guild Messages'**
  String get doc_event_message_create_intent_1;

  /// Message Content
  ///
  /// In en, this message translates to:
  /// **'Message Content'**
  String get doc_event_message_create_intent_2;

  /// If Message Content intent is off, content-dependent conditions can fail.
  ///
  /// In en, this message translates to:
  /// **'If Message Content intent is off, content-dependent conditions can fail.'**
  String get doc_event_message_create_notes_l1;

  /// message.content[index] is word-based and capped by runtime extraction.
  ///
  /// In en, this message translates to:
  /// **'message.content[index] is word-based and capped by runtime extraction.'**
  String get doc_event_message_create_notes_l2;

  /// author.isBot can help avoid bot loops.
  ///
  /// In en, this message translates to:
  /// **'author.isBot can help avoid bot loops.'**
  String get doc_event_message_create_notes_l3;

  /// Triggered for each newly created message.
  ///
  /// In en, this message translates to:
  /// **'Triggered for each newly created message.'**
  String get doc_event_message_create_subtitle;

  /// Use this event for moderation, keyword pipelines, auto-replies, command-style parsing, and analytics.
  ///
  /// In en, this message translates to:
  /// **'Use this event for moderation, keyword pipelines, auto-replies, command-style parsing, and analytics.'**
  String get doc_event_message_create_summary;

  /// Event: messageCreate
  ///
  /// In en, this message translates to:
  /// **'Event: messageCreate'**
  String get doc_event_message_create_title;

  /// Map each answer id to a different action branch.
  ///
  /// In en, this message translates to:
  /// **'Map each answer id to a different action branch.'**
  String get doc_event_poll_vote_add_best_use_l1;

  /// Track poll participation per channel or user group.
  ///
  /// In en, this message translates to:
  /// **'Track poll participation per channel or user group.'**
  String get doc_event_poll_vote_add_best_use_l2;

  /// Guild Messages
  ///
  /// In en, this message translates to:
  /// **'Guild Messages'**
  String get doc_event_poll_vote_add_intent;

  /// poll.answer.id is the most stable key for routing.
  ///
  /// In en, this message translates to:
  /// **'poll.answer.id is the most stable key for routing.'**
  String get doc_event_poll_vote_add_notes_l1;

  /// poll.question is optional and may be empty depending on payload.
  ///
  /// In en, this message translates to:
  /// **'poll.question is optional and may be empty depending on payload.'**
  String get doc_event_poll_vote_add_notes_l2;

  /// Triggered when a user votes on a poll answer.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a user votes on a poll answer.'**
  String get doc_event_poll_vote_add_subtitle;

  /// Useful for score tracking, role assignment by poll option, and survey processing.
  ///
  /// In en, this message translates to:
  /// **'Useful for score tracking, role assignment by poll option, and survey processing.'**
  String get doc_event_poll_vote_add_summary;

  /// Event: messagePollVoteAdd
  ///
  /// In en, this message translates to:
  /// **'Event: messagePollVoteAdd'**
  String get doc_event_poll_vote_add_title;

  /// Approve/reject flows with unicode emoji.
  ///
  /// In en, this message translates to:
  /// **'Approve/reject flows with unicode emoji.'**
  String get doc_event_reaction_add_best_use_l1;

  /// Multi-step polls using custom emoji IDs.
  ///
  /// In en, this message translates to:
  /// **'Multi-step polls using custom emoji IDs.'**
  String get doc_event_reaction_add_best_use_l2;

  /// Quick moderation signals from staff channels.
  ///
  /// In en, this message translates to:
  /// **'Quick moderation signals from staff channels.'**
  String get doc_event_reaction_add_best_use_l3;

  /// Guard: ((reaction.emoji.name)) equals ✅
  /// Action: addRole -> user=((userId)) role=((global.approvedRoleId))
  ///
  /// In en, this message translates to:
  /// **'Guard: ((reaction.emoji.name)) equals ✅\nAction: addRole -> user=((userId)) role=((global.approvedRoleId))'**
  String get doc_event_reaction_add_example;

  /// Guild Message Reactions
  ///
  /// In en, this message translates to:
  /// **'Guild Message Reactions'**
  String get doc_event_reaction_add_intent;

  /// reaction.emoji.id can be empty for unicode emoji.
  ///
  /// In en, this message translates to:
  /// **'reaction.emoji.id can be empty for unicode emoji.'**
  String get doc_event_reaction_add_notes_l1;

  /// Use reaction.emoji.name for generic matching.
  ///
  /// In en, this message translates to:
  /// **'Use reaction.emoji.name for generic matching.'**
  String get doc_event_reaction_add_notes_l2;

  /// Use reaction.emoji.id for strict custom emoji matching.
  ///
  /// In en, this message translates to:
  /// **'Use reaction.emoji.id for strict custom emoji matching.'**
  String get doc_event_reaction_add_notes_l3;

  /// Triggered when a user adds a reaction to a message.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a user adds a reaction to a message.'**
  String get doc_event_reaction_add_subtitle;

  /// Ideal for button-like UX without components, vote systems, role menus, and lightweight approvals.
  ///
  /// In en, this message translates to:
  /// **'Ideal for button-like UX without components, vote systems, role menus, and lightweight approvals.'**
  String get doc_event_reaction_add_summary;

  /// Event: messageReactionAdd
  ///
  /// In en, this message translates to:
  /// **'Event: messageReactionAdd'**
  String get doc_event_reaction_add_title;

  /// No channel context for this event in most cases.
  ///
  /// In en, this message translates to:
  /// **'No channel context for this event in most cases.'**
  String get doc_event_user_update_notes_l1;

  /// Prefer logging + moderation alerts over direct user-facing replies.
  ///
  /// In en, this message translates to:
  /// **'Prefer logging + moderation alerts over direct user-facing replies.'**
  String get doc_event_user_update_notes_l2;

  /// Triggered when user profile data changes.
  ///
  /// In en, this message translates to:
  /// **'Triggered when user profile data changes.'**
  String get doc_event_user_update_subtitle;

  /// Useful for profile-change auditing and username/avatar-driven triggers.
  ///
  /// In en, this message translates to:
  /// **'Useful for profile-change auditing and username/avatar-driven triggers.'**
  String get doc_event_user_update_summary;

  /// Event: userUpdate
  ///
  /// In en, this message translates to:
  /// **'Event: userUpdate'**
  String get doc_event_user_update_title;

  /// Detect self-mute/self-deafen policy violations.
  ///
  /// In en, this message translates to:
  /// **'Detect self-mute/self-deafen policy violations.'**
  String get doc_event_voice_state_update_automations_l1;

  /// Trigger welcome message on voice join for support channels.
  ///
  /// In en, this message translates to:
  /// **'Trigger welcome message on voice join for support channels.'**
  String get doc_event_voice_state_update_automations_l2;

  /// Log leave/join patterns using channel changes.
  ///
  /// In en, this message translates to:
  /// **'Log leave/join patterns using channel changes.'**
  String get doc_event_voice_state_update_automations_l3;

  /// Guilds
  ///
  /// In en, this message translates to:
  /// **'Guilds'**
  String get doc_event_voice_state_update_intent;

  /// Typical Automations
  ///
  /// In en, this message translates to:
  /// **'Typical Automations'**
  String get doc_event_voice_state_update_section_title;

  /// Triggered when voice state changes for a user.
  ///
  /// In en, this message translates to:
  /// **'Triggered when voice state changes for a user.'**
  String get doc_event_voice_state_update_subtitle;

  /// Use this for auto-moderation in voice channels, attendance checks, and voice automation.
  ///
  /// In en, this message translates to:
  /// **'Use this for auto-moderation in voice channels, attendance checks, and voice automation.'**
  String get doc_event_voice_state_update_summary;

  /// Event: voiceStateUpdate
  ///
  /// In en, this message translates to:
  /// **'Event: voiceStateUpdate'**
  String get doc_event_voice_state_update_title;

  /// Example
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get doc_example;

  /// Autocomplete workflow:
  /// query = ((autocomplete.query))
  /// queryArray -> items=((httpSearch.body))
  /// respondWithAutocomplete -> label='{name}' value='{id}'
  ///
  /// In en, this message translates to:
  /// **'Autocomplete workflow:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'{name}\' value=\'{id}\''**
  String doc_interaction_commands_example(String name, String id);

  /// Built-in Command Variables
  ///
  /// In en, this message translates to:
  /// **'Built-in Command Variables'**
  String get doc_interaction_commands_section_builtin_title;

  /// Slash, user and message commands all enter the runner as application command interactions.
  ///
  /// In en, this message translates to:
  /// **'Slash, user and message commands all enter the runner as application command interactions.'**
  String get doc_interaction_commands_section_execution_l1;

  /// The runner matches commands by Discord command id, then validates stored type vs incoming type.
  ///
  /// In en, this message translates to:
  /// **'The runner matches commands by Discord command id, then validates stored type vs incoming type.'**
  String get doc_interaction_commands_section_execution_l2;

  /// A type mismatch is logged as warning but does not hard-stop execution.
  ///
  /// In en, this message translates to:
  /// **'A type mismatch is logged as warning but does not hard-stop execution.'**
  String get doc_interaction_commands_section_execution_l3;

  /// Execution Model
  ///
  /// In en, this message translates to:
  /// **'Execution Model'**
  String get doc_interaction_commands_section_execution_title;

  /// Write conditional logic against commandType or interaction.command.type.
  ///
  /// In en, this message translates to:
  /// **'Write conditional logic against commandType or interaction.command.type.'**
  String get doc_interaction_commands_section_guidance_l1;

  /// Prefer fallback syntax when sharing a template between slash and non-slash commands, and use autocomplete.query inside dedicated autocomplete workflows.
  ///
  /// In en, this message translates to:
  /// **'Prefer fallback syntax when sharing a template between slash and non-slash commands, and use autocomplete.query inside dedicated autocomplete workflows.'**
  String get doc_interaction_commands_section_guidance_l2;

  /// Keep templates portable by avoiding event-only names inside command workflows; dynamic autocomplete requires a general workflow ending with respondWithAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Keep templates portable by avoiding event-only names inside command workflows; dynamic autocomplete requires a general workflow ending with respondWithAutocomplete.'**
  String get doc_interaction_commands_section_guidance_l3;

  /// Authoring Guidance
  ///
  /// In en, this message translates to:
  /// **'Authoring Guidance'**
  String get doc_interaction_commands_section_guidance_title;

  /// chatInput: opts.* for parameters and subcommands.
  ///
  /// In en, this message translates to:
  /// **'chatInput: opts.* for parameters and subcommands.'**
  String get doc_interaction_commands_section_per_type_l1;

  /// user: target.user.* and target.member.* when available.
  ///
  /// In en, this message translates to:
  /// **'user: target.user.* and target.member.* when available.'**
  String get doc_interaction_commands_section_per_type_l2;

  /// message: target.message.* including content and author id when resolved.
  ///
  /// In en, this message translates to:
  /// **'message: target.message.* including content and author id when resolved.'**
  String get doc_interaction_commands_section_per_type_l3;

  /// Per-Type Variables
  ///
  /// In en, this message translates to:
  /// **'Per-Type Variables'**
  String get doc_interaction_commands_section_per_type_title;

  /// Slash, user and message command runtime behavior.
  ///
  /// In en, this message translates to:
  /// **'Slash, user and message command runtime behavior.'**
  String get doc_interaction_commands_subtitle;

  /// Application commands are executed through a shared interaction path, with runtime variables depending on the Discord command type.
  ///
  /// In en, this message translates to:
  /// **'Application commands are executed through a shared interaction path, with runtime variables depending on the Discord command type.'**
  String get doc_interaction_commands_summary;

  /// Interaction Commands
  ///
  /// In en, this message translates to:
  /// **'Interaction Commands'**
  String get doc_interaction_commands_title;

  /// Action
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get doc_kind_action;

  /// All
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get doc_kind_all;

  /// Event
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get doc_kind_event;

  /// Runtime
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get doc_kind_runtime;

  /// Template
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get doc_kind_template;

  /// Required Intents
  ///
  /// In en, this message translates to:
  /// **'Required Intents'**
  String get doc_required_intents;

  /// Status: ((action.http.status|http.status|unknown))
  /// Body: ((action.http.body|http.body))
  /// Deleted: ((cleanup.count|0))
  /// Total: ((page.total|0))
  ///
  /// In en, this message translates to:
  /// **'Status: ((action.http.status|http.status|unknown))\nBody: ((action.http.body|http.body))\nDeleted: ((cleanup.count|0))\nTotal: ((page.total|0))'**
  String get doc_runtime_action_outputs_example;

  /// Not every action exposes every suffix; availability is executor-specific.
  ///
  /// In en, this message translates to:
  /// **'Not every action exposes every suffix; availability is executor-specific.'**
  String get doc_runtime_action_outputs_section_caveats_l1;

  /// For portability, prefer fallback expressions when reading optional output fields.
  ///
  /// In en, this message translates to:
  /// **'For portability, prefer fallback expressions when reading optional output fields.'**
  String get doc_runtime_action_outputs_section_caveats_l2;

  /// If a key is missing, template resolution returns an empty string.
  ///
  /// In en, this message translates to:
  /// **'If a key is missing, template resolution returns an empty string.'**
  String get doc_runtime_action_outputs_section_caveats_l3;

  /// Caveats
  ///
  /// In en, this message translates to:
  /// **'Caveats'**
  String get doc_runtime_action_outputs_section_caveats_title;

  /// HTTP actions: status, body, jsonPath.
  ///
  /// In en, this message translates to:
  /// **'HTTP actions: status, body, jsonPath.'**
  String get doc_runtime_action_outputs_section_common_fields_l1;

  /// Messaging/list actions: count, mode, deleteItself, deleteResponse.
  ///
  /// In en, this message translates to:
  /// **'Messaging/list actions: count, mode, deleteItself, deleteResponse.'**
  String get doc_runtime_action_outputs_section_common_fields_l2;

  /// Array actions: items, length, removed, total.
  ///
  /// In en, this message translates to:
  /// **'Array actions: items, length, removed, total.'**
  String get doc_runtime_action_outputs_section_common_fields_l3;

  /// Other executors may expose result or messageId fields.
  ///
  /// In en, this message translates to:
  /// **'Other executors may expose result or messageId fields.'**
  String get doc_runtime_action_outputs_section_common_fields_l4;

  /// Common Output Fields
  ///
  /// In en, this message translates to:
  /// **'Common Output Fields'**
  String get doc_runtime_action_outputs_section_common_fields_title;

  /// Primary output is usually stored as <resultKey>.
  ///
  /// In en, this message translates to:
  /// **'Primary output is usually stored as <resultKey>.'**
  String get doc_runtime_action_outputs_section_patterns_l1;

  /// Many executors also expose action.<resultKey>.* fields for clarity and namespacing.
  ///
  /// In en, this message translates to:
  /// **'Many executors also expose action.<resultKey>.* fields for clarity and namespacing.'**
  String get doc_runtime_action_outputs_section_patterns_l2;

  /// Some fields are mirrored with and without the action. prefix.
  ///
  /// In en, this message translates to:
  /// **'Some fields are mirrored with and without the action. prefix.'**
  String get doc_runtime_action_outputs_section_patterns_l3;

  /// Output Patterns
  ///
  /// In en, this message translates to:
  /// **'Output Patterns'**
  String get doc_runtime_action_outputs_section_patterns_title;

  /// How action result keys are exposed as runtime variables.
  ///
  /// In en, this message translates to:
  /// **'How action result keys are exposed as runtime variables.'**
  String get doc_runtime_action_outputs_subtitle;

  /// Most actions write a primary result key and may also expose prefixed fields under action.<resultKey>.* depending on the executor.
  ///
  /// In en, this message translates to:
  /// **'Most actions write a primary result key and may also expose prefixed fields under action.<resultKey>.* depending on the executor.'**
  String get doc_runtime_action_outputs_summary;

  /// Runtime Action Outputs
  ///
  /// In en, this message translates to:
  /// **'Runtime Action Outputs'**
  String get doc_runtime_action_outputs_title;

  /// Variables should be identical between local app runtime and runner runtime.
  ///
  /// In en, this message translates to:
  /// **'Variables should be identical between local app runtime and runner runtime.'**
  String get doc_runtime_execution_flow_section_parity_l1;

  /// Use same variable names in conditions to stay portable.
  ///
  /// In en, this message translates to:
  /// **'Use same variable names in conditions to stay portable.'**
  String get doc_runtime_execution_flow_section_parity_l2;

  /// Parity Rule
  ///
  /// In en, this message translates to:
  /// **'Parity Rule'**
  String get doc_runtime_execution_flow_section_parity_title;

  /// 1) Receive gateway event.
  ///
  /// In en, this message translates to:
  /// **'1) Receive gateway event.'**
  String get doc_runtime_execution_flow_section_pipeline_l1;

  /// 2) Build context variables map.
  ///
  /// In en, this message translates to:
  /// **'2) Build context variables map.'**
  String get doc_runtime_execution_flow_section_pipeline_l2;

  /// 3) Match workflows by event name.
  ///
  /// In en, this message translates to:
  /// **'3) Match workflows by event name.'**
  String get doc_runtime_execution_flow_section_pipeline_l3;

  /// 4) Merge global variables.
  ///
  /// In en, this message translates to:
  /// **'4) Merge global variables.'**
  String get doc_runtime_execution_flow_section_pipeline_l4;

  /// 5) Execute actions sequentially with conditions.
  ///
  /// In en, this message translates to:
  /// **'5) Execute actions sequentially with conditions.'**
  String get doc_runtime_execution_flow_section_pipeline_l5;

  /// Pipeline
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get doc_runtime_execution_flow_section_pipeline_title;

  /// How event workflows are selected and executed.
  ///
  /// In en, this message translates to:
  /// **'How event workflows are selected and executed.'**
  String get doc_runtime_execution_flow_subtitle;

  /// When an event arrives, runtime matches configured workflows by eventTrigger.event then executes actions with context variables.
  ///
  /// In en, this message translates to:
  /// **'When an event arrives, runtime matches configured workflows by eventTrigger.event then executes actions with context variables.'**
  String get doc_runtime_execution_flow_summary;

  /// Runtime Execution Flow
  ///
  /// In en, this message translates to:
  /// **'Runtime Execution Flow'**
  String get doc_runtime_execution_flow_title;

  /// Kind: ((interaction.kind))
  /// Selected count: ((interaction.values.count|0))
  /// Thread owner: ((channel.thread.ownerId|unknown))
  /// Guild payload kind: ((guild.kind|n/a))
  ///
  /// In en, this message translates to:
  /// **'Kind: ((interaction.kind))\nSelected count: ((interaction.values.count|0))\nThread owner: ((channel.thread.ownerId|unknown))\nGuild payload kind: ((guild.kind|n/a))'**
  String get doc_template_advanced_variables_example;

  /// Structured user aliases (user.id, user.username, user.tag, user.avatar, user.banner) are available in many command contexts.
  ///
  /// In en, this message translates to:
  /// **'Structured user aliases (user.id, user.username, user.tag, user.avatar, user.banner) are available in many command contexts.'**
  String get doc_template_advanced_variables_section_aliases_l1;

  /// member.id can be useful when both user and guild-member context are needed.
  ///
  /// In en, this message translates to:
  /// **'member.id can be useful when both user and guild-member context are needed.'**
  String get doc_template_advanced_variables_section_aliases_l2;

  /// User and Member Aliases
  ///
  /// In en, this message translates to:
  /// **'User and Member Aliases'**
  String get doc_template_advanced_variables_section_aliases_title;

  /// channel.kind, channel.position, channel.bitrate, and channel.userLimit are context-dependent channel details.
  ///
  /// In en, this message translates to:
  /// **'channel.kind, channel.position, channel.bitrate, and channel.userLimit are context-dependent channel details.'**
  String get doc_template_advanced_variables_section_channel_guild_l1;

  /// Thread contexts can expose channel.thread.* values (archived, locked, ownerId, autoArchiveDuration).
  ///
  /// In en, this message translates to:
  /// **'Thread contexts can expose channel.thread.* values (archived, locked, ownerId, autoArchiveDuration).'**
  String get doc_template_advanced_variables_section_channel_guild_l2;

  /// guild.kind helps distinguish partial/full guild payloads in advanced workflows.
  ///
  /// In en, this message translates to:
  /// **'guild.kind helps distinguish partial/full guild payloads in advanced workflows.'**
  String get doc_template_advanced_variables_section_channel_guild_l3;

  /// Channel and Guild Details
  ///
  /// In en, this message translates to:
  /// **'Channel and Guild Details'**
  String get doc_template_advanced_variables_section_channel_guild_title;

  /// interaction.kind identifies the incoming interaction mode (button, select, modal, command, autocomplete).
  ///
  /// In en, this message translates to:
  /// **'interaction.kind identifies the incoming interaction mode (button, select, modal, command, autocomplete).'**
  String get doc_template_advanced_variables_section_interaction_l1;

  /// interaction.values and interaction.values.count are populated for select menus.
  ///
  /// In en, this message translates to:
  /// **'interaction.values and interaction.values.count are populated for select menus.'**
  String get doc_template_advanced_variables_section_interaction_l2;

  /// interaction.command.name and interaction.command.id are useful for diagnostics and routing checks.
  ///
  /// In en, this message translates to:
  /// **'interaction.command.name and interaction.command.id are useful for diagnostics and routing checks.'**
  String get doc_template_advanced_variables_section_interaction_l3;

  /// Interaction Metadata
  ///
  /// In en, this message translates to:
  /// **'Interaction Metadata'**
  String get doc_template_advanced_variables_section_interaction_title;

  /// Additional runtime keys available in specific contexts.
  ///
  /// In en, this message translates to:
  /// **'Additional runtime keys available in specific contexts.'**
  String get doc_template_advanced_variables_subtitle;

  /// These keys are generated from interaction payloads and channel/guild/user runtime details, depending on the event or command type.
  ///
  /// In en, this message translates to:
  /// **'These keys are generated from interaction payloads and channel/guild/user runtime details, depending on the event or command type.'**
  String get doc_template_advanced_variables_summary;

  /// Template Advanced Variables
  ///
  /// In en, this message translates to:
  /// **'Template Advanced Variables'**
  String get doc_template_advanced_variables_title;

  /// Normalized: ((uppercase(trim(userName))))
  /// Has admin role: ((contains(userRole, "admin")))
  /// Top score: ((first(scores.$)))
  /// Total score: ((sum(scores.$)))
  ///
  /// In en, this message translates to:
  /// **'Normalized: ((uppercase(trim(userName))))\nHas admin role: ((contains(userRole, \"admin\")))\nTop score: ((first(scores.\$)))\nTotal score: ((sum(scores.\$)))'**
  String get doc_template_functions_example;

  /// length(source), at(source, index), first(source), last(source).
  ///
  /// In en, this message translates to:
  /// **'length(source), at(source, index), first(source), last(source).'**
  String get doc_template_functions_section_array_l1;

  /// slice(source, start, end?) and join(source, separator).
  ///
  /// In en, this message translates to:
  /// **'slice(source, start, end?) and join(source, separator).'**
  String get doc_template_functions_section_array_l2;

  /// sum(source): adds numeric items and ignores non-numeric values.
  ///
  /// In en, this message translates to:
  /// **'sum(source): adds numeric items and ignores non-numeric values.'**
  String get doc_template_functions_section_array_l3;

  /// formatEach(...) and embedFields(...) format object arrays for text and embeds.
  ///
  /// In en, this message translates to:
  /// **'formatEach(...) and embedFields(...) format object arrays for text and embeds.'**
  String get doc_template_functions_section_array_l4;

  /// Array and Aggregate Helpers
  ///
  /// In en, this message translates to:
  /// **'Array and Aggregate Helpers'**
  String get doc_template_functions_section_array_title;

  /// Function names are case-insensitive.
  ///
  /// In en, this message translates to:
  /// **'Function names are case-insensitive.'**
  String get doc_template_functions_section_notes_l1;

  /// Unknown functions or invalid arguments resolve to an empty string.
  ///
  /// In en, this message translates to:
  /// **'Unknown functions or invalid arguments resolve to an empty string.'**
  String get doc_template_functions_section_notes_l2;

  /// Use fallback syntax with | at root level: ((replace(name, "_", " ")|Unknown)).
  ///
  /// In en, this message translates to:
  /// **'Use fallback syntax with | at root level: ((replace(name, \"_\", \" \")|Unknown)).'**
  String get doc_template_functions_section_notes_l3;

  /// Arrays and objects returned by functions are serialized as JSON text.
  ///
  /// In en, this message translates to:
  /// **'Arrays and objects returned by functions are serialized as JSON text.'**
  String get doc_template_functions_section_notes_l4;

  /// Important Notes
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get doc_template_functions_section_notes_title;

  /// coin() and random(): return "true" or "" for conditional branching.
  ///
  /// In en, this message translates to:
  /// **'coin() and random(): return \"true\" or \"\" for conditional branching.'**
  String get doc_template_functions_section_random_l1;

  /// randomchoice(a, b, ...) and randomint(min, max).
  ///
  /// In en, this message translates to:
  /// **'randomchoice(a, b, ...) and randomint(min, max).'**
  String get doc_template_functions_section_random_l2;

  /// Random Helpers
  ///
  /// In en, this message translates to:
  /// **'Random Helpers'**
  String get doc_template_functions_section_random_title;

  /// lowercase(source) / lower(source): convert text to lowercase.
  ///
  /// In en, this message translates to:
  /// **'lowercase(source) / lower(source): convert text to lowercase.'**
  String get doc_template_functions_section_string_l1;

  /// uppercase(source) / upper(source): convert text to uppercase.
  ///
  /// In en, this message translates to:
  /// **'uppercase(source) / upper(source): convert text to uppercase.'**
  String get doc_template_functions_section_string_l2;

  /// trim(source): remove leading and trailing spaces.
  ///
  /// In en, this message translates to:
  /// **'trim(source): remove leading and trailing spaces.'**
  String get doc_template_functions_section_string_l3;

  /// replace(source, search, replacement) and contains(source, needle) for substitutions and checks.
  ///
  /// In en, this message translates to:
  /// **'replace(source, search, replacement) and contains(source, needle) for substitutions and checks.'**
  String get doc_template_functions_section_string_l4;

  /// String Helpers
  ///
  /// In en, this message translates to:
  /// **'String Helpers'**
  String get doc_template_functions_section_string_title;

  /// Transform and compare data inside ((...)) expressions.
  ///
  /// In en, this message translates to:
  /// **'Transform and compare data inside ((...)) expressions.'**
  String get doc_template_functions_subtitle;

  /// Use template functions to normalize text, inspect arrays, build output blocks, and add lightweight randomness.
  ///
  /// In en, this message translates to:
  /// **'Use template functions to normalize text, inspect arrays, build output blocks, and add lightweight randomness.'**
  String get doc_template_functions_summary;

  /// Template Functions
  ///
  /// In en, this message translates to:
  /// **'Template Functions'**
  String get doc_template_functions_title;

  /// Hello ((target.user.username|userName))
  /// Players: ((join(scores.items.$, ", ")))
  /// Fields JSON: ((embedFields(scores.items.$, "'{name}'", "'{score}'", true)))
  ///
  /// In en, this message translates to:
  /// **'Hello ((target.user.username|userName))\nPlayers: ((join(scores.items.\$, \", \")))\nFields JSON: ((embedFields(scores.items.\$, \"\'{name}\'\", \"\'{score}\'\", true)))'**
  String doc_template_variables_example(String name, String score);

  /// Built-in Command Variables
  ///
  /// In en, this message translates to:
  /// **'Built-in Command Variables'**
  String get doc_template_variables_section_builtin_title;

  /// Use ((opts.user|userName)) to fall back when an option is missing.
  ///
  /// In en, this message translates to:
  /// **'Use ((opts.user|userName)) to fall back when an option is missing.'**
  String get doc_template_variables_section_fallbacks_l1;

  /// Use JSONPath syntax on action outputs: ((myHttp.body.$.data[0].id)); arrays and objects stay queryable.
  ///
  /// In en, this message translates to:
  /// **'Use JSONPath syntax on action outputs: ((myHttp.body.\$.data[0].id)); arrays and objects stay queryable.'**
  String get doc_template_variables_section_fallbacks_l2;

  /// Functions like length(...), join(...), formatEach(...), and embedFields(...) are also supported; unknown variables still resolve to an empty string.
  ///
  /// In en, this message translates to:
  /// **'Functions like length(...), join(...), formatEach(...), and embedFields(...) are also supported; unknown variables still resolve to an empty string.'**
  String get doc_template_variables_section_fallbacks_l3;

  /// Fallbacks and Paths
  ///
  /// In en, this message translates to:
  /// **'Fallbacks and Paths'**
  String get doc_template_variables_section_fallbacks_title;

  /// Command variables: commandName, commandId, commandType, target.*, opts.*.
  ///
  /// In en, this message translates to:
  /// **'Command variables: commandName, commandId, commandType, target.*, opts.*.'**
  String get doc_template_variables_section_sources_l1;

  /// Event variables: event.*, message.*, reaction.*, voice.*, role.*, etc.
  ///
  /// In en, this message translates to:
  /// **'Event variables: event.*, message.*, reaction.*, voice.*, role.*, etc.'**
  String get doc_template_variables_section_sources_l2;

  /// Workflow variables: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*
  ///
  /// In en, this message translates to:
  /// **'Workflow variables: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*'**
  String get doc_template_variables_section_sources_l3;

  /// Global variables: global.<key>
  ///
  /// In en, this message translates to:
  /// **'Global variables: global.<key>'**
  String get doc_template_variables_section_sources_l4;

  /// Action outputs: action.<key> when available.
  ///
  /// In en, this message translates to:
  /// **'Action outputs: action.<key> when available.'**
  String get doc_template_variables_section_sources_l5;

  /// Variable Sources
  ///
  /// In en, this message translates to:
  /// **'Variable Sources'**
  String get doc_template_variables_section_sources_title;

  /// Slash commands use commandType = chatInput and expose opts.<option> variables.
  ///
  /// In en, this message translates to:
  /// **'Slash commands use commandType = chatInput and expose opts.<option> variables.'**
  String get doc_template_variables_section_types_l1;

  /// User commands use commandType = user and expose target.user.* variables.
  ///
  /// In en, this message translates to:
  /// **'User commands use commandType = user and expose target.user.* variables.'**
  String get doc_template_variables_section_types_l2;

  /// Message commands use commandType = message and expose target.message.* variables.
  ///
  /// In en, this message translates to:
  /// **'Message commands use commandType = message and expose target.message.* variables.'**
  String get doc_template_variables_section_types_l3;

  /// Subcommands still expose their arguments through opts.*.
  ///
  /// In en, this message translates to:
  /// **'Subcommands still expose their arguments through opts.*.'**
  String get doc_template_variables_section_types_l4;

  /// Command Types
  ///
  /// In en, this message translates to:
  /// **'Command Types'**
  String get doc_template_variables_section_types_title;

  /// How dynamic placeholders are resolved.
  ///
  /// In en, this message translates to:
  /// **'How dynamic placeholders are resolved.'**
  String get doc_template_variables_subtitle;

  /// Runtime resolves placeholders using current event/interaction context, workflow args, and global vars.
  ///
  /// In en, this message translates to:
  /// **'Runtime resolves placeholders using current event/interaction context, workflow args, and global vars.'**
  String get doc_template_variables_summary;

  /// Template Variables
  ///
  /// In en, this message translates to:
  /// **'Template Variables'**
  String get doc_template_variables_title;

  /// Done
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Download completed: {id}
  ///
  /// In en, this message translates to:
  /// **'Download completed: {id}'**
  String download_completed(String id);

  /// Download failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String download_failed(String error);

  /// Download completed (legacy backup)
  ///
  /// In en, this message translates to:
  /// **'Download completed (legacy backup)'**
  String get download_legacy_backup;

  /// Legacy snapshot
  ///
  /// In en, this message translates to:
  /// **'Legacy snapshot'**
  String get drive_legacy_snapshot;

  /// Manual backup
  ///
  /// In en, this message translates to:
  /// **'Manual backup'**
  String get drive_manual_backup;

  /// All changes saved
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get edit_shell_all_saved;

  /// Command body
  ///
  /// In en, this message translates to:
  /// **'Command body'**
  String get edit_shell_command_body;

  /// Command settings
  ///
  /// In en, this message translates to:
  /// **'Command settings'**
  String get edit_shell_command_settings;

  /// Metadata, availability, permissions, and folder placement.
  ///
  /// In en, this message translates to:
  /// **'Metadata, availability, permissions, and folder placement.'**
  String get edit_shell_command_settings_desc;

  /// Local draft
  ///
  /// In en, this message translates to:
  /// **'Local draft'**
  String get edit_shell_local_draft;

  /// Local-only
  ///
  /// In en, this message translates to:
  /// **'Local-only'**
  String get edit_shell_local_only;

  /// {count} route(s)
  ///
  /// In en, this message translates to:
  /// **'{count} route(s)'**
  String edit_shell_routes_count(int count);

  /// Save changes
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get edit_shell_save_changes;

  /// Settings and inputs are at the top. Actions and reply follow below.
  ///
  /// In en, this message translates to:
  /// **'Settings and inputs are at the top. Actions and reply follow below.'**
  String get edit_shell_subtitle;

  /// Trigger & Inputs
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get edit_shell_trigger_inputs;

  /// Adjust command options, trigger behavior, and execution mode.
  ///
  /// In en, this message translates to:
  /// **'Adjust command options, trigger behavior, and execution mode.'**
  String get edit_shell_trigger_inputs_desc;

  /// Command
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get edit_shell_type_command;

  /// Legacy command
  ///
  /// In en, this message translates to:
  /// **'Legacy command'**
  String get edit_shell_type_legacy;

  /// Message command
  ///
  /// In en, this message translates to:
  /// **'Message command'**
  String get edit_shell_type_message;

  /// Slash command
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get edit_shell_type_slash;

  /// User command
  ///
  /// In en, this message translates to:
  /// **'User command'**
  String get edit_shell_type_user;

  /// Unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get edit_shell_unsaved;

  /// Untitled command
  ///
  /// In en, this message translates to:
  /// **'Untitled command'**
  String get edit_shell_untitled_command;

  /// Add Field
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get embed_add_field;

  /// Add Section
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get embed_add_section;

  /// Add embed
  ///
  /// In en, this message translates to:
  /// **'Add embed'**
  String get embed_add_tooltip;

  /// Pick embed color
  ///
  /// In en, this message translates to:
  /// **'Pick embed color'**
  String get embed_color_picker_title;

  /// No description provided for @embed_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This embed will be removed. Continue?'**
  String get embed_delete_confirm;

  /// Delete embed
  ///
  /// In en, this message translates to:
  /// **'Delete embed'**
  String get embed_delete_title;

  /// No embeds. You can add up to {max} embeds.
  ///
  /// In en, this message translates to:
  /// **'No embeds. You can add up to {max} embeds.'**
  String embed_empty_message(int max);

  /// This field will be removed from the embed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This field will be removed from the embed. Continue?'**
  String get embed_field_delete_confirm;

  /// Delete field
  ///
  /// In en, this message translates to:
  /// **'Delete field'**
  String get embed_field_delete_title;

  /// Field #{index}
  ///
  /// In en, this message translates to:
  /// **'Field #{index}'**
  String embed_field_number(int index);

  /// No fields yet.
  ///
  /// In en, this message translates to:
  /// **'No fields yet.'**
  String get embed_fields_empty;

  /// Fields ({count}/25)
  ///
  /// In en, this message translates to:
  /// **'Fields ({count}/25)'**
  String embed_fields_header(int count);

  /// Author Icon URL
  ///
  /// In en, this message translates to:
  /// **'Author Icon URL'**
  String get embed_label_author_icon;

  /// Author Name
  ///
  /// In en, this message translates to:
  /// **'Author Name'**
  String get embed_label_author_name;

  /// Author URL
  ///
  /// In en, this message translates to:
  /// **'Author URL'**
  String get embed_label_author_url;

  /// Color (int or #hex)
  ///
  /// In en, this message translates to:
  /// **'Color (int or #hex)'**
  String get embed_label_color;

  /// Dynamic Fields Template
  ///
  /// In en, this message translates to:
  /// **'Dynamic Fields Template'**
  String get embed_label_dynamic_fields;

  /// Footer Icon URL
  ///
  /// In en, this message translates to:
  /// **'Footer Icon URL'**
  String get embed_label_footer_icon;

  /// Footer Text
  ///
  /// In en, this message translates to:
  /// **'Footer Text'**
  String get embed_label_footer_text;

  /// Image URL
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get embed_label_image_url;

  /// Inline
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get embed_label_inline;

  /// Thumbnail URL
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get embed_label_thumbnail_url;

  /// Timestamp (ISO8601)
  ///
  /// In en, this message translates to:
  /// **'Timestamp (ISO8601)'**
  String get embed_label_timestamp;

  /// Title
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get embed_label_title;

  /// URL
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get embed_label_url;

  /// Embed #{index}
  ///
  /// In en, this message translates to:
  /// **'Embed #{index}'**
  String embed_number(int index);

  /// Response Embeds ({count}/{max})
  ///
  /// In en, this message translates to:
  /// **'Response Embeds ({count}/{max})'**
  String embed_response_header(int count, int max);

  /// Author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get embed_section_author;

  /// Color
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get embed_section_color;

  /// Dynamic Fields
  ///
  /// In en, this message translates to:
  /// **'Dynamic Fields'**
  String get embed_section_dynamic_fields;

  /// Fields
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get embed_section_fields;

  /// Footer
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get embed_section_footer;

  /// Media
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get embed_section_media;

  /// Timestamp
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get embed_section_timestamp;

  /// Delete :{name}: ? This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete :{name}: ? This action cannot be undone.'**
  String emojis_delete_confirm_body(String name);

  /// Delete Emoji
  ///
  /// In en, this message translates to:
  /// **'Delete Emoji'**
  String get emojis_delete_confirm_title;

  /// Delete failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String emojis_delete_error(String error);

  /// Delete
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get emojis_delete_tooltip;

  /// No emojis yet. Upload one to get started.
  ///
  /// In en, this message translates to:
  /// **'No emojis yet. Upload one to get started.'**
  String get emojis_empty;

  /// Failed to load emojis
  ///
  /// In en, this message translates to:
  /// **'Failed to load emojis'**
  String get emojis_loading_error;

  /// Rename failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Rename failed: {error}'**
  String emojis_rename_error(String error);

  /// New name
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get emojis_rename_hint;

  /// Rename Emoji
  ///
  /// In en, this message translates to:
  /// **'Rename Emoji'**
  String get emojis_rename_title;

  /// Rename
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get emojis_rename_tooltip;

  /// Emojis
  ///
  /// In en, this message translates to:
  /// **'Emojis'**
  String get emojis_tab;

  /// Emoji
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojis_tab_short;

  /// Application Emojis
  ///
  /// In en, this message translates to:
  /// **'Application Emojis'**
  String get emojis_title;

  /// Upload Emoji
  ///
  /// In en, this message translates to:
  /// **'Upload Emoji'**
  String get emojis_upload;

  /// Upload failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String emojis_upload_error(String error);

  /// Emoji name (letters, numbers, _)
  ///
  /// In en, this message translates to:
  /// **'Emoji name (letters, numbers, _)'**
  String get emojis_upload_name_hint;

  /// Pick Image
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get emojis_upload_pick_image;

  /// Error
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Failed to delete messages.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete messages.'**
  String get error_delete_messages_failed;

  /// Channel is not a text channel.
  ///
  /// In en, this message translates to:
  /// **'Channel is not a text channel.'**
  String get error_invalid_channel_type;

  /// Count must be greater than 0.
  ///
  /// In en, this message translates to:
  /// **'Count must be greater than 0.'**
  String get error_invalid_count;

  /// The action timed out. Please try again.
  ///
  /// In en, this message translates to:
  /// **'The action timed out. Please try again.'**
  String get error_network_timeout;

  /// Error: {error}
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_with_details(String error);

  /// Export ZIP
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get export_button;

  /// Commands
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get export_commands;

  /// Export failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String export_failed(String error);

  /// File picker is already open
  ///
  /// In en, this message translates to:
  /// **'File picker is already open'**
  String get export_file_picker_busy;

  /// Global Variables
  ///
  /// In en, this message translates to:
  /// **'Global Variables'**
  String get export_global_variables;

  /// Export / Import
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get export_import_title;

  /// Export selected sections of your bot as a ZIP file. The bot token is never included.
  ///
  /// In en, this message translates to:
  /// **'Export selected sections of your bot as a ZIP file. The bot token is never included.'**
  String get export_section_desc;

  /// Export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export_section_title;

  /// Status & Activities
  ///
  /// In en, this message translates to:
  /// **'Status & Activities'**
  String get export_status;

  /// Workflows
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get export_workflows;

  /// Add Variable
  ///
  /// In en, this message translates to:
  /// **'Add Variable'**
  String get globals_add;

  /// Add Global Variable
  ///
  /// In en, this message translates to:
  /// **'Add Global Variable'**
  String get globals_add_global;

  /// Add Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Add Scoped Variable'**
  String get globals_add_scoped;

  /// Copy value
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get globals_copy_value;

  /// Delete "{key}"?
  ///
  /// In en, this message translates to:
  /// **'Delete \"{key}\"?'**
  String globals_delete_confirm(String key);

  /// Delete Variable
  ///
  /// In en, this message translates to:
  /// **'Delete Variable'**
  String get globals_delete_title;

  /// Global variables are shared across all commands and servers.
  ///
  /// In en, this message translates to:
  /// **'Global variables are shared across all commands and servers.'**
  String get globals_dialog_global_desc;

  /// Usage: $getVar[{ref}]
  ///
  /// In en, this message translates to:
  /// **'Usage: \$getVar[{ref}]'**
  String globals_dialog_ref_preview(String ref);

  /// A scoped variable stores a separate value per {scope} context.
  ///
  /// In en, this message translates to:
  /// **'A scoped variable stores a separate value per {scope} context.'**
  String globals_dialog_scoped_desc(String scope);

  /// Edit Variable
  ///
  /// In en, this message translates to:
  /// **'Edit Variable'**
  String get globals_edit;

  /// Edit Global Variable
  ///
  /// In en, this message translates to:
  /// **'Edit Global Variable'**
  String get globals_edit_global;

  /// Edit Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Edit Scoped Variable'**
  String get globals_edit_scoped;

  /// No global variables yet
  ///
  /// In en, this message translates to:
  /// **'No global variables yet'**
  String get globals_empty;

  /// Add a variable to store persistent data accessible by all commands.
  ///
  /// In en, this message translates to:
  /// **'Add a variable to store persistent data accessible by all commands.'**
  String get globals_empty_subtitle;

  /// Shared across all commands. Access via $getVar[key].
  ///
  /// In en, this message translates to:
  /// **'Shared across all commands. Access via \$getVar[key].'**
  String get globals_help_global;

  /// Stored per context (server, user, channel…). Each entry keeps a distinct value per Discord context.
  ///
  /// In en, this message translates to:
  /// **'Stored per context (server, user, channel…). Each entry keeps a distinct value per Discord context.'**
  String get globals_help_scoped;

  /// Key
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get globals_key;

  /// e.g. prefix, level, welcome_message
  ///
  /// In en, this message translates to:
  /// **'e.g. prefix, level, welcome_message'**
  String get globals_key_hint;

  /// Global
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globals_mode_global;

  /// Scoped
  ///
  /// In en, this message translates to:
  /// **'Scoped'**
  String get globals_mode_scoped;

  /// No default value
  ///
  /// In en, this message translates to:
  /// **'No default value'**
  String get globals_no_default;

  /// Refresh
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get globals_refresh;

  /// Retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get globals_retry;

  /// channel
  ///
  /// In en, this message translates to:
  /// **'channel'**
  String get globals_scope_channel;

  /// guild
  ///
  /// In en, this message translates to:
  /// **'guild'**
  String get globals_scope_guild;

  /// guildMember
  ///
  /// In en, this message translates to:
  /// **'guildMember'**
  String get globals_scope_guildMember;

  /// message
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get globals_scope_message;

  /// user
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get globals_scope_user;

  /// Search variables…
  ///
  /// In en, this message translates to:
  /// **'Search variables…'**
  String get globals_search;

  /// Local
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get globals_source_local;

  /// Runner: {name}
  ///
  /// In en, this message translates to:
  /// **'Runner: {name}'**
  String globals_source_runner(String name);

  /// Globals
  ///
  /// In en, this message translates to:
  /// **'Globals'**
  String get globals_tab;

  /// Vars
  ///
  /// In en, this message translates to:
  /// **'Vars'**
  String get globals_tab_short;

  /// Variables
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get globals_title;

  /// Value
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get globals_value;

  /// Value is auto-typed (number, boolean, JSON).
  ///
  /// In en, this message translates to:
  /// **'Value is auto-typed (number, boolean, JSON).'**
  String get globals_value_auto_type_hint;

  /// Servers page text key
  ///
  /// In en, this message translates to:
  /// **'The bot is not in any server.\nInvite it to a server to see it here.'**
  String get guilds_empty_state;

  /// Leave confirmation dialogue message
  ///
  /// In en, this message translates to:
  /// **'Leave \"{name}\"?\nThe bot will be removed from this server. You can re-invite it later from the Discord developer portal.'**
  String guilds_leave_confirm(String name);

  /// Error notification when leaving server fails
  ///
  /// In en, this message translates to:
  /// **'Failed to leave: {error}'**
  String guilds_leave_failed(String error);

  /// Servers page text key
  ///
  /// In en, this message translates to:
  /// **'Leave Server'**
  String get guilds_leave_title;

  /// Servers page text key
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get guilds_leave_tooltip;

  /// Success notification after leaving server
  ///
  /// In en, this message translates to:
  /// **'Left \"{name}\".'**
  String guilds_left_success(String name);

  /// Approximate members count in a guild
  ///
  /// In en, this message translates to:
  /// **'~{count} members'**
  String guilds_members_count_other(int count);

  /// Servers page text key
  ///
  /// In en, this message translates to:
  /// **'👑 Owner'**
  String get guilds_owner_label;

  /// Number of servers the bot is in
  ///
  /// In en, this message translates to:
  /// **'{count} servers'**
  String guilds_server_count_other(int count);

  /// No description provided for @guilds_tab.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get guilds_tab;

  /// No description provided for @guilds_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get guilds_tab_short;

  /// Use variables/templates if needed
  ///
  /// In en, this message translates to:
  /// **'Use variables/templates if needed'**
  String get hint_use_variables;

  /// Add Time
  ///
  /// In en, this message translates to:
  /// **'Add Time'**
  String get home_add_time;

  /// Discord Support
  ///
  /// In en, this message translates to:
  /// **'Discord Support'**
  String get home_empty_support_btn;

  /// Need help? Join our community!
  ///
  /// In en, this message translates to:
  /// **'Need help? Join our community!'**
  String get home_empty_support_hint;

  /// The foreground service did not start.
  ///
  /// In en, this message translates to:
  /// **'The foreground service did not start.'**
  String get home_foreground_service_not_started;

  /// Hosting expired
  ///
  /// In en, this message translates to:
  /// **'Hosting expired'**
  String get home_hosting_expired;

  /// Hosting left: {time}
  ///
  /// In en, this message translates to:
  /// **'Hosting left: {time}'**
  String home_hosting_time_left(String time);

  /// Desktop bot stop requested
  ///
  /// In en, this message translates to:
  /// **'Desktop bot stop requested'**
  String get home_log_desktop_stop_requested;

  /// Bot start requested
  ///
  /// In en, this message translates to:
  /// **'Bot start requested'**
  String get home_log_start_requested;

  /// Bot stop requested
  ///
  /// In en, this message translates to:
  /// **'Bot stop requested'**
  String get home_log_stop_requested;

  /// View Logs
  ///
  /// In en, this message translates to:
  /// **'View Logs'**
  String get home_logs_tooltip;

  /// Manage
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get home_manage;

  /// Notification permission is required to start the bot.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to start the bot.'**
  String get home_notification_permission_required;

  /// {count} server
  ///
  /// In en, this message translates to:
  /// **'{count} server'**
  String home_server_count_one(int count);

  /// {count} servers
  ///
  /// In en, this message translates to:
  /// **'{count} servers'**
  String home_server_count_other(int count);

  /// Start
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get home_start;

  /// Start (Watch Ad)
  ///
  /// In en, this message translates to:
  /// **'Start (Watch Ad)'**
  String get home_start_ads;

  /// Start (Premium)
  ///
  /// In en, this message translates to:
  /// **'Start (Premium)'**
  String get home_start_premium;

  /// Offline
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get home_status_offline;

  /// Online
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get home_status_online;

  /// Stop
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get home_stop;

  /// Sync failed
  ///
  /// In en, this message translates to:
  /// **'Sync failed'**
  String get home_sync_failed;

  /// Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_tab;

  /// Succesfully added Time
  ///
  /// In en, this message translates to:
  /// **'Succesfully added Time'**
  String get home_time_added;

  /// Token not found for {botName}
  ///
  /// In en, this message translates to:
  /// **'Token not found for {botName}'**
  String home_token_missing(String botName);

  /// Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get home_unknown_app;

  /// Button label to create a new image canvas
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get image_editor_create;

  /// Prompt shown when no canvas operations exist yet
  ///
  /// In en, this message translates to:
  /// **'Create Image Canvas'**
  String get image_editor_create_canvas;

  /// Button label to edit existing canvas operations (count)
  ///
  /// In en, this message translates to:
  /// **'Edit Canvas ({count} ops)'**
  String image_editor_edit_canvas(int count);

  /// Button label to open the image editor for existing canvas
  ///
  /// In en, this message translates to:
  /// **'Open Editor'**
  String get image_editor_open;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_button;

  /// Import failed: {error}
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String import_failed(String error);

  /// Nothing imported.
  ///
  /// In en, this message translates to:
  /// **'Nothing imported.'**
  String get import_nothing;

  /// Overwrite
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get import_overwrite;

  /// Failed to parse ZIP: {error}
  ///
  /// In en, this message translates to:
  /// **'Failed to parse ZIP: {error}'**
  String import_parse_failed(String error);

  /// Select ZIP file
  ///
  /// In en, this message translates to:
  /// **'Select ZIP file'**
  String get import_pick_file;

  /// Import a previously exported ZIP file. Conflicts can be resolved per item.
  ///
  /// In en, this message translates to:
  /// **'Import a previously exported ZIP file. Conflicts can be resolved per item.'**
  String get import_section_desc;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_section_title;

  /// Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get import_skip;

  /// {count} command(s) imported
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) imported'**
  String import_summary_commands_imported(int count);

  /// {count} command(s) skipped
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) skipped'**
  String import_summary_commands_skipped(int count);

  /// status imported
  ///
  /// In en, this message translates to:
  /// **'status imported'**
  String get import_summary_status_imported;

  /// variables imported
  ///
  /// In en, this message translates to:
  /// **'variables imported'**
  String get import_summary_variables_imported;

  /// {count} workflow(s) imported
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) imported'**
  String import_summary_workflows_imported(int count);

  /// {count} workflow(s) skipped
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) skipped'**
  String import_summary_workflows_skipped(int count);

  /// Hint text in the JavaScript editor field
  ///
  /// In en, this message translates to:
  /// **'// Write your JavaScript bot command here...'**
  String get js_editor_hint;

  /// Short label for JavaScript execution mode SegmentedButton
  ///
  /// In en, this message translates to:
  /// **'JS'**
  String get js_editor_segmented_label;

  /// Card subtitle in the JavaScript editor shell
  ///
  /// In en, this message translates to:
  /// **'Write custom JavaScript for this command'**
  String get js_editor_subtitle;

  /// Card title in the JavaScript editor shell
  ///
  /// In en, this message translates to:
  /// **'JavaScript Editor'**
  String get js_editor_title;

  /// Failed to run BDFD script for command "{command}": {error}
  ///
  /// In en, this message translates to:
  /// **'Failed to run BDFD script for command \"{command}\": {error}'**
  String legacy_bdfd_run_failed(String command, String error);

  /// Handle commands from messageCreate using <prefix><command>.
  ///
  /// In en, this message translates to:
  /// **'Handle commands from messageCreate using <prefix><command>.'**
  String get legacy_prefix_mode_desc;

  /// Uses positional options (example: !config #channel).
  ///
  /// In en, this message translates to:
  /// **'Uses positional options (example: !config #channel).'**
  String get legacy_prefix_mode_subtitle;

  /// Legacy Prefix Mode
  ///
  /// In en, this message translates to:
  /// **'Legacy Prefix Mode'**
  String get legacy_prefix_mode_title;

  /// Example: ? or ((guild.prefix | !))
  ///
  /// In en, this message translates to:
  /// **'Example: ? or ((guild.prefix | !))'**
  String get legacy_prefix_override_hint;

  /// Prefix override (optional)
  ///
  /// In en, this message translates to:
  /// **'Prefix override (optional)'**
  String get legacy_prefix_override_label;

  /// Body text for the legacy response deprecation banner (full size)
  ///
  /// In en, this message translates to:
  /// **'Some commands still use the old response format. Open them in the editor and re-save to activate the new format.'**
  String get legacy_response_banner_body;

  /// Tooltip for the dismiss button on the legacy response deprecation banner
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get legacy_response_banner_dismiss;

  /// Button label to migrate all legacy commands
  ///
  /// In en, this message translates to:
  /// **'Migrate all'**
  String get legacy_response_banner_migrate;

  /// Error message when migration fails
  ///
  /// In en, this message translates to:
  /// **'Migration failed'**
  String get legacy_response_banner_migrate_failed;

  /// Message showing how many commands were migrated
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 command migrated} other{{count} commands migrated}}'**
  String legacy_response_banner_migrated(int count);

  /// Message shown when no commands need migration
  ///
  /// In en, this message translates to:
  /// **'No commands need migration'**
  String get legacy_response_banner_migrated_none;

  /// Loading state while migrating commands
  ///
  /// In en, this message translates to:
  /// **'Migrating...'**
  String get legacy_response_banner_migrating;

  /// Short body text for the legacy response deprecation banner (small screens)
  ///
  /// In en, this message translates to:
  /// **'Open and re-save your commands to migrate to the new format.'**
  String get legacy_response_banner_short_body;

  /// Short title for the legacy response deprecation banner (small screens)
  ///
  /// In en, this message translates to:
  /// **'Command update available'**
  String get legacy_response_banner_short_title;

  /// Full title for the legacy response deprecation banner
  ///
  /// In en, this message translates to:
  /// **'Command response format update'**
  String get legacy_response_banner_title;

  /// Legacy response mode
  ///
  /// In en, this message translates to:
  /// **'Legacy response mode'**
  String get legacy_response_mode_label;

  /// Awaited callback presets stay local because they are internal runtime callbacks.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback presets stay local because they are internal runtime callbacks.'**
  String get local_command_awaited_desc;

  /// Store command only in Bot Creator. You can dynamically register it on Specific Guilds using BDFD $registerGuildCommands.
  ///
  /// In en, this message translates to:
  /// **'Store command only in Bot Creator. You can dynamically register it on Specific Guilds using BDFD \$registerGuildCommands.'**
  String get local_command_desc;

  /// Local Command (Do not register on Discord)
  ///
  /// In en, this message translates to:
  /// **'Local Command (Do not register on Discord)'**
  String get local_command_title;

  /// Logs from: {name}
  ///
  /// In en, this message translates to:
  /// **'Logs from: {name}'**
  String logs_runner_source(String name);

  /// No description provided for @marketplace_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get marketplace_about;

  /// No description provided for @marketplace_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get marketplace_add;

  /// No description provided for @marketplace_api_unavailable.
  ///
  /// In en, this message translates to:
  /// **'API client not available'**
  String get marketplace_api_unavailable;

  /// No description provided for @marketplace_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply Template'**
  String get marketplace_apply;

  /// No description provided for @marketplace_apply_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply: {error}'**
  String marketplace_apply_error(Object error);

  /// No description provided for @marketplace_apply_success.
  ///
  /// In en, this message translates to:
  /// **'Template applied successfully!'**
  String get marketplace_apply_success;

  /// No description provided for @marketplace_apply_success_skipped.
  ///
  /// In en, this message translates to:
  /// **'{addedCount} command(s) added, {skippedCount} skipped (duplicates).'**
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  );

  /// No description provided for @marketplace_applying.
  ///
  /// In en, this message translates to:
  /// **'Applying...'**
  String get marketplace_applying;

  /// No description provided for @marketplace_by_author.
  ///
  /// In en, this message translates to:
  /// **'by {author} · v{version}'**
  String marketplace_by_author(Object author, Object version);

  /// No description provided for @marketplace_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get marketplace_cancel;

  /// No description provided for @marketplace_command_preview_actions.
  ///
  /// In en, this message translates to:
  /// **'{count} actions'**
  String marketplace_command_preview_actions(Object count);

  /// No description provided for @marketplace_command_preview_no_actions.
  ///
  /// In en, this message translates to:
  /// **'No actions'**
  String get marketplace_command_preview_no_actions;

  /// No description provided for @marketplace_command_preview_options.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String marketplace_command_preview_options(Object count);

  /// No description provided for @marketplace_command_preview_type_message.
  ///
  /// In en, this message translates to:
  /// **'Message context menu'**
  String get marketplace_command_preview_type_message;

  /// No description provided for @marketplace_command_preview_type_slash.
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get marketplace_command_preview_type_slash;

  /// No description provided for @marketplace_command_preview_type_user.
  ///
  /// In en, this message translates to:
  /// **'User context menu'**
  String get marketplace_command_preview_type_user;

  /// No description provided for @marketplace_commands_label.
  ///
  /// In en, this message translates to:
  /// **'Commands ({count})'**
  String marketplace_commands_label(Object count);

  /// No description provided for @marketplace_config_hint.
  ///
  /// In en, this message translates to:
  /// **'Fill in the required values before applying this template.'**
  String get marketplace_config_hint;

  /// No description provided for @marketplace_config_required.
  ///
  /// In en, this message translates to:
  /// **'Configuration Required'**
  String get marketplace_config_required;

  /// No description provided for @marketplace_conflict_apply_choice.
  ///
  /// In en, this message translates to:
  /// **'Apply ({count} template)'**
  String marketplace_conflict_apply_choice(Object count);

  /// Label for keeping the local version of a command
  ///
  /// In en, this message translates to:
  /// **'Keep Local'**
  String get marketplace_conflict_keep_local;

  /// No description provided for @marketplace_conflict_local_info.
  ///
  /// In en, this message translates to:
  /// **'Local ({count} actions)'**
  String marketplace_conflict_local_info(Object count);

  /// Subtitle explaining that some commands conflict with local ones
  ///
  /// In en, this message translates to:
  /// **'Some template commands already exist. Choose which version to keep:'**
  String get marketplace_conflict_subtitle;

  /// No description provided for @marketplace_conflict_template_info.
  ///
  /// In en, this message translates to:
  /// **'Template ({count} actions)'**
  String marketplace_conflict_template_info(Object count);

  /// Title for the conflict resolution dialog when applying a template
  ///
  /// In en, this message translates to:
  /// **'Command Conflicts'**
  String get marketplace_conflict_title;

  /// Label for using the template version of a command
  ///
  /// In en, this message translates to:
  /// **'Use Template'**
  String get marketplace_conflict_use_template;

  /// No description provided for @marketplace_connect_discord.
  ///
  /// In en, this message translates to:
  /// **'Connect with Discord'**
  String get marketplace_connect_discord;

  /// No description provided for @marketplace_connect_manager.
  ///
  /// In en, this message translates to:
  /// **'Connect to Manager to access the Marketplace.'**
  String get marketplace_connect_manager;

  /// No description provided for @marketplace_connect_publish.
  ///
  /// In en, this message translates to:
  /// **'Connect to Manager to publish a template.'**
  String get marketplace_connect_publish;

  /// No description provided for @marketplace_count.
  ///
  /// In en, this message translates to:
  /// **'{count} template(s)'**
  String marketplace_count(Object count);

  /// No description provided for @marketplace_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get marketplace_delete;

  /// No description provided for @marketplace_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String marketplace_delete_confirm(Object name);

  /// No description provided for @marketplace_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Template'**
  String get marketplace_delete_confirm_title;

  /// No description provided for @marketplace_delete_success.
  ///
  /// In en, this message translates to:
  /// **'Template deleted.'**
  String get marketplace_delete_success;

  /// No description provided for @marketplace_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get marketplace_edit;

  /// No description provided for @marketplace_edit_hint.
  ///
  /// In en, this message translates to:
  /// **'To edit, re-publish from your bot\'s command list with the same name.'**
  String get marketplace_edit_hint;

  /// No description provided for @marketplace_empty.
  ///
  /// In en, this message translates to:
  /// **'No templates yet.\nBe the first to publish!'**
  String get marketplace_empty;

  /// No description provided for @marketplace_load_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data: {error}'**
  String marketplace_load_error(Object error);

  /// No description provided for @marketplace_login_hint.
  ///
  /// In en, this message translates to:
  /// **'You must connect your Discord account to access the Marketplace.'**
  String get marketplace_login_hint;

  /// No description provided for @marketplace_login_instructions.
  ///
  /// In en, this message translates to:
  /// **'Please authenticate via Discord to continue using the Marketplace.'**
  String get marketplace_login_instructions;

  /// No description provided for @marketplace_login_required.
  ///
  /// In en, this message translates to:
  /// **'Discord connection required'**
  String get marketplace_login_required;

  /// No description provided for @marketplace_login_success.
  ///
  /// In en, this message translates to:
  /// **'Discord connected successfully!'**
  String get marketplace_login_success;

  /// No description provided for @marketplace_login_title.
  ///
  /// In en, this message translates to:
  /// **'Connect to Manager'**
  String get marketplace_login_title;

  /// No description provided for @marketplace_more.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String marketplace_more(Object count);

  /// No description provided for @marketplace_my_templates.
  ///
  /// In en, this message translates to:
  /// **'My Templates'**
  String get marketplace_my_templates;

  /// No description provided for @marketplace_no_results.
  ///
  /// In en, this message translates to:
  /// **'No templates match \"{query}\"'**
  String marketplace_no_results(Object query);

  /// No description provided for @marketplace_no_variables.
  ///
  /// In en, this message translates to:
  /// **'No global variables defined.'**
  String get marketplace_no_variables;

  /// No description provided for @marketplace_publish_add_variable.
  ///
  /// In en, this message translates to:
  /// **'Add custom variable'**
  String get marketplace_publish_add_variable;

  /// No description provided for @marketplace_publish_add_variable_title.
  ///
  /// In en, this message translates to:
  /// **'Add Variable'**
  String get marketplace_publish_add_variable_title;

  /// No description provided for @marketplace_publish_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get marketplace_publish_back;

  /// No description provided for @marketplace_publish_button.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get marketplace_publish_button;

  /// No description provided for @marketplace_publish_category_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. ai, moderation, fun'**
  String get marketplace_publish_category_hint;

  /// No description provided for @marketplace_publish_category_label.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get marketplace_publish_category_label;

  /// No description provided for @marketplace_publish_commands.
  ///
  /// In en, this message translates to:
  /// **'Commands ({count})'**
  String marketplace_publish_commands(Object count);

  /// No description provided for @marketplace_publish_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'A one-line summary shown in the marketplace'**
  String get marketplace_publish_desc_hint;

  /// No description provided for @marketplace_publish_desc_label.
  ///
  /// In en, this message translates to:
  /// **'Short description'**
  String get marketplace_publish_desc_label;

  /// No description provided for @marketplace_publish_desc_long_hint.
  ///
  /// In en, this message translates to:
  /// **'Detailed usage instructions, markdown supported...'**
  String get marketplace_publish_desc_long_hint;

  /// No description provided for @marketplace_publish_desc_long_label.
  ///
  /// In en, this message translates to:
  /// **'Full documentation (optional)'**
  String get marketplace_publish_desc_long_label;

  /// No description provided for @marketplace_publish_deselect_all.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get marketplace_publish_deselect_all;

  /// No description provided for @marketplace_publish_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to publish: {error}'**
  String marketplace_publish_error(Object error);

  /// No description provided for @marketplace_publish_metadata.
  ///
  /// In en, this message translates to:
  /// **'Template Details'**
  String get marketplace_publish_metadata;

  /// No description provided for @marketplace_publish_metadata_hint.
  ///
  /// In en, this message translates to:
  /// **'Describe your template so others can find and use it.'**
  String get marketplace_publish_metadata_hint;

  /// No description provided for @marketplace_publish_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AI Moderation Bot'**
  String get marketplace_publish_name_hint;

  /// No description provided for @marketplace_publish_name_label.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get marketplace_publish_name_label;

  /// No description provided for @marketplace_publish_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get marketplace_publish_next;

  /// No description provided for @marketplace_publish_no_content.
  ///
  /// In en, this message translates to:
  /// **'No commands or workflows to publish.\nCreate some first!'**
  String get marketplace_publish_no_content;

  /// No description provided for @marketplace_publish_required_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields (Template name, Short description, Version) before publishing.'**
  String get marketplace_publish_required_fields;

  /// No description provided for @marketplace_publish_select.
  ///
  /// In en, this message translates to:
  /// **'Select what to include'**
  String get marketplace_publish_select;

  /// No description provided for @marketplace_publish_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get marketplace_publish_select_all;

  /// No description provided for @marketplace_publish_select_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick commands, workflows, or both. Each becomes part of the template.'**
  String get marketplace_publish_select_hint;

  /// No description provided for @marketplace_publish_success.
  ///
  /// In en, this message translates to:
  /// **'Template published successfully!'**
  String get marketplace_publish_success;

  /// No description provided for @marketplace_publish_summary.
  ///
  /// In en, this message translates to:
  /// **'Template Summary'**
  String get marketplace_publish_summary;

  /// No description provided for @marketplace_publish_tags_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. openai, chatbot, moderation'**
  String get marketplace_publish_tags_hint;

  /// No description provided for @marketplace_publish_tags_label.
  ///
  /// In en, this message translates to:
  /// **'Tags (comma separated)'**
  String get marketplace_publish_tags_label;

  /// No description provided for @marketplace_publish_title.
  ///
  /// In en, this message translates to:
  /// **'Publish Template'**
  String get marketplace_publish_title;

  /// No description provided for @marketplace_publish_user_must_define.
  ///
  /// In en, this message translates to:
  /// **'User must define this value'**
  String get marketplace_publish_user_must_define;

  /// No description provided for @marketplace_publish_user_must_define_hint.
  ///
  /// In en, this message translates to:
  /// **'The user will be prompted to fill it in before applying'**
  String get marketplace_publish_user_must_define_hint;

  /// No description provided for @marketplace_publish_variable_desc_hint.
  ///
  /// In en, this message translates to:
  /// **'What this variable is for'**
  String get marketplace_publish_variable_desc_hint;

  /// No description provided for @marketplace_publish_variable_desc_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get marketplace_publish_variable_desc_label;

  /// No description provided for @marketplace_publish_variable_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. TOKEN_OPENAI'**
  String get marketplace_publish_variable_name_hint;

  /// No description provided for @marketplace_publish_variable_name_label.
  ///
  /// In en, this message translates to:
  /// **'Variable name'**
  String get marketplace_publish_variable_name_label;

  /// No description provided for @marketplace_publish_variables.
  ///
  /// In en, this message translates to:
  /// **'Global Variables'**
  String get marketplace_publish_variables;

  /// No description provided for @marketplace_publish_variables_hint.
  ///
  /// In en, this message translates to:
  /// **'Include variables and mark which ones the user must fill in.'**
  String get marketplace_publish_variables_hint;

  /// No description provided for @marketplace_publish_version_label.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get marketplace_publish_version_label;

  /// No description provided for @marketplace_publish_workflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows ({count})'**
  String marketplace_publish_workflows(Object count);

  /// No description provided for @marketplace_publishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing...'**
  String get marketplace_publishing;

  /// No description provided for @marketplace_rate_success.
  ///
  /// In en, this message translates to:
  /// **'Rating submitted!'**
  String get marketplace_rate_success;

  /// No description provided for @marketplace_rate_title.
  ///
  /// In en, this message translates to:
  /// **'Rate this template'**
  String get marketplace_rate_title;

  /// No description provided for @marketplace_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get marketplace_retry;

  /// No description provided for @marketplace_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search templates...'**
  String get marketplace_search_hint;

  /// No description provided for @marketplace_title.
  ///
  /// In en, this message translates to:
  /// **'Marketplace'**
  String get marketplace_title;

  /// No description provided for @marketplace_variable_required.
  ///
  /// In en, this message translates to:
  /// **'{name} is required'**
  String marketplace_variable_required(Object name);

  /// No description provided for @marketplace_variables_label.
  ///
  /// In en, this message translates to:
  /// **'Pre-configured Variables'**
  String get marketplace_variables_label;

  /// No description provided for @marketplace_workflows_label.
  ///
  /// In en, this message translates to:
  /// **'Workflows ({count})'**
  String marketplace_workflows_label(Object count);

  /// Add Text Input
  ///
  /// In en, this message translates to:
  /// **'Add Text Input'**
  String get modal_add_text_input;

  /// Modal Builder
  ///
  /// In en, this message translates to:
  /// **'Modal Builder'**
  String get modal_builder_title;

  /// Used to identify this modal
  ///
  /// In en, this message translates to:
  /// **'Used to identify this modal'**
  String get modal_custom_id_hint;

  /// Custom ID
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get modal_custom_id_label;

  /// Default value
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get modal_default_value;

  /// Field {index}
  ///
  /// In en, this message translates to:
  /// **'Field {index}'**
  String modal_field_default_label(int index);

  /// Input {index}
  ///
  /// In en, this message translates to:
  /// **'Input {index}'**
  String modal_input_index(int index);

  /// {count}/5 inputs
  ///
  /// In en, this message translates to:
  /// **'{count}/5 inputs'**
  String modal_inputs_count(int count);

  /// This field will be removed from the modal. Continue?
  ///
  /// In en, this message translates to:
  /// **'This field will be removed from the modal. Continue?'**
  String get modal_remove_field_confirm;

  /// Remove modal field
  ///
  /// In en, this message translates to:
  /// **'Remove modal field'**
  String get modal_remove_field_title;

  /// Style:
  ///
  /// In en, this message translates to:
  /// **'Style:'**
  String get modal_style;

  /// Modal Title
  ///
  /// In en, this message translates to:
  /// **'Modal Title'**
  String get modal_title_label;

  /// Workflow to run on submit (optional)
  ///
  /// In en, this message translates to:
  /// **'Workflow to run on submit (optional)'**
  String get modal_workflow_submit;

  /// More Options
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get more_options_title;

  /// More
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more_tab;

  /// Webhooks
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get nav_webhooks;

  /// Hooks
  ///
  /// In en, this message translates to:
  /// **'Hooks'**
  String get nav_webhooks_compact;

  /// No other options available
  ///
  /// In en, this message translates to:
  /// **'No other options available'**
  String get no_more_options;

  /// Create workflow "{query}"
  ///
  /// In en, this message translates to:
  /// **'Create workflow \"{query}\"'**
  String notion_create_workflow_from_query(String query);

  /// Add Filter
  ///
  /// In en, this message translates to:
  /// **'Add Filter'**
  String get notion_filter_add;

  /// Type
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notion_filter_type;

  /// OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_command_button;

  /// Create your first command
  ///
  /// In en, this message translates to:
  /// **'Create your first command'**
  String get onboarding_command_desc;

  /// Example:
  /// /hello → Bot replies "Hello! 👋"
  ///
  /// In en, this message translates to:
  /// **'Example:\n/hello → Bot replies \"Hello! 👋\"'**
  String get onboarding_command_example;

  /// Commands are the heart of your bot. They allow users to interact with your bot via Discord.
  ///
  /// In en, this message translates to:
  /// **'Commands are the heart of your bot. They allow users to interact with your bot via Discord.'**
  String get onboarding_command_text;

  /// Step 2: Add a Command
  ///
  /// In en, this message translates to:
  /// **'Step 2: Add a Command'**
  String get onboarding_command_title;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_create_button;

  /// Get your Discord token
  ///
  /// In en, this message translates to:
  /// **'Get your Discord token'**
  String get onboarding_create_desc;

  /// 1. Go to Discord Developer Portal
  /// 2. Create a new app
  /// 3. Copy the bot token
  /// 4. Paste it below
  ///
  /// In en, this message translates to:
  /// **'1. Go to Discord Developer Portal\n2. Create a new app\n3. Copy the bot token\n4. Paste it below'**
  String get onboarding_create_steps;

  /// 💡 Tip: Never share your token! It gives full access to your bot.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: Never share your token! It gives full access to your bot.'**
  String get onboarding_create_tip;

  /// Step 1: Create a Bot
  ///
  /// In en, this message translates to:
  /// **'Step 1: Create a Bot'**
  String get onboarding_create_title;

  /// Tutorial: How to get a token
  ///
  /// In en, this message translates to:
  /// **'Tutorial: How to get a token'**
  String get onboarding_create_tutorial;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_start_button;

  /// Launch your bot!
  ///
  /// In en, this message translates to:
  /// **'Launch your bot!'**
  String get onboarding_start_desc;

  /// Click the "Start" button on your bot card. Then test your command in Discord!
  ///
  /// In en, this message translates to:
  /// **'Click the \"Start\" button on your bot card. Then test your command in Discord!'**
  String get onboarding_start_text;

  /// ✨ Great! You've created your first Discord bot. You can now add more commands and customize it!
  ///
  /// In en, this message translates to:
  /// **'✨ Great! You\'ve created your first Discord bot. You can now add more commands and customize it!'**
  String get onboarding_start_tip;

  /// Step 3: Start the Bot
  ///
  /// In en, this message translates to:
  /// **'Step 3: Start the Bot'**
  String get onboarding_start_title;

  /// Start!
  ///
  /// In en, this message translates to:
  /// **'Start!'**
  String get onboarding_success_button;

  /// Your Discord bot is ready to go!
  ///
  /// In en, this message translates to:
  /// **'Your Discord bot is ready to go!'**
  String get onboarding_success_desc;

  /// Add more commands
  ///
  /// In en, this message translates to:
  /// **'Add more commands'**
  String get onboarding_success_tip1;

  /// Create workflows
  ///
  /// In en, this message translates to:
  /// **'Create workflows'**
  String get onboarding_success_tip2;

  /// Backup your data
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get onboarding_success_tip3;

  /// Congratulations! 🎉
  ///
  /// In en, this message translates to:
  /// **'Congratulations! 🎉'**
  String get onboarding_success_title;

  /// What's next?
  ///
  /// In en, this message translates to:
  /// **'What\'s next?'**
  String get onboarding_success_whatsnext;

  /// Create your first Discord bot in 3 simple steps. We'll guide you through each step.
  ///
  /// In en, this message translates to:
  /// **'Create your first Discord bot in 3 simple steps. We\'ll guide you through each step.'**
  String get onboarding_welcome_desc;

  /// Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_welcome_skip;

  /// Get Started
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_welcome_start;

  /// Welcome to Bot Creator
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bot Creator'**
  String get onboarding_welcome_title;

  /// Add Choice
  ///
  /// In en, this message translates to:
  /// **'Add Choice'**
  String get option_add_choice;

  /// Add Localizations
  ///
  /// In en, this message translates to:
  /// **'Add Localizations'**
  String get option_add_localizations;

  /// This choice will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This choice will be removed. Continue?'**
  String get option_choice_delete_confirm;

  /// Delete choice
  ///
  /// In en, this message translates to:
  /// **'Delete choice'**
  String get option_choice_delete_title;

  /// Choice Name
  ///
  /// In en, this message translates to:
  /// **'Choice Name'**
  String get option_choice_name;

  /// Choice {index}
  ///
  /// In en, this message translates to:
  /// **'Choice {index}'**
  String option_choice_number(int index);

  /// Choice Value
  ///
  /// In en, this message translates to:
  /// **'Choice Value'**
  String get option_choice_value;

  /// Option {index}
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String option_default_name(int index);

  /// This argument will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This argument will be removed. Continue?'**
  String get option_delete_argument_confirm;

  /// Delete argument
  ///
  /// In en, this message translates to:
  /// **'Delete argument'**
  String get option_delete_argument_title;

  /// This choice will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This choice will be removed. Continue?'**
  String get option_delete_choice_confirm;

  /// Delete option
  ///
  /// In en, this message translates to:
  /// **'Delete option'**
  String get option_delete_choice_title;

  /// This option will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This option will be removed. Continue?'**
  String get option_delete_confirm;

  /// This localization entry will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This localization entry will be removed. Continue?'**
  String get option_delete_localization_confirm;

  /// Delete localization
  ///
  /// In en, this message translates to:
  /// **'Delete localization'**
  String get option_delete_localization_title;

  /// Delete option
  ///
  /// In en, this message translates to:
  /// **'Delete option'**
  String get option_delete_title;

  /// Please enter a description for the option
  ///
  /// In en, this message translates to:
  /// **'Please enter a description for the option'**
  String get option_desc_required;

  /// Label {index}
  ///
  /// In en, this message translates to:
  /// **'Label {index}'**
  String option_label_number(int index);

  /// Localized Description
  ///
  /// In en, this message translates to:
  /// **'Localized Description'**
  String get option_localized_description;

  /// Localized Name
  ///
  /// In en, this message translates to:
  /// **'Localized Name'**
  String get option_localized_name;

  /// Max Value
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get option_max_value;

  /// Min Value
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get option_min_value;

  /// This name is already used at this level
  ///
  /// In en, this message translates to:
  /// **'This name is already used at this level'**
  String get option_name_duplicate;

  /// Option name can only contain letters, numbers, and underscores
  ///
  /// In en, this message translates to:
  /// **'Option name can only contain letters, numbers, and underscores'**
  String get option_name_invalid_chars;

  /// Option name starts with an unsupported character
  ///
  /// In en, this message translates to:
  /// **'Option name starts with an unsupported character'**
  String get option_name_invalid_start;

  /// Option name must be at most 32 characters long
  ///
  /// In en, this message translates to:
  /// **'Option name must be at most 32 characters long'**
  String get option_name_max_length;

  /// Please enter a name for the option
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the option'**
  String get option_name_required;

  /// Select Language
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get option_select_language;

  /// Label {index}
  ///
  /// In en, this message translates to:
  /// **'Label {index}'**
  String option_static_label_n(int index);

  /// Value {index}
  ///
  /// In en, this message translates to:
  /// **'Value {index}'**
  String option_static_value_n(int index);

  /// SubCommand Options
  ///
  /// In en, this message translates to:
  /// **'SubCommand Options'**
  String get option_subcommand_options;

  /// SubCommands
  ///
  /// In en, this message translates to:
  /// **'SubCommands'**
  String get option_subcommands;

  /// Attachment
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get option_type_attachment;

  /// Boolean
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get option_type_boolean;

  /// Channel
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get option_type_channel;

  /// Integer
  ///
  /// In en, this message translates to:
  /// **'Integer'**
  String get option_type_integer;

  /// Mentionable
  ///
  /// In en, this message translates to:
  /// **'Mentionable'**
  String get option_type_mentionable;

  /// Number
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get option_type_number;

  /// Role
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get option_type_role;

  /// String
  ///
  /// In en, this message translates to:
  /// **'String'**
  String get option_type_string;

  /// SubCommand
  ///
  /// In en, this message translates to:
  /// **'SubCommand'**
  String get option_type_subcommand;

  /// SubCommand Group
  ///
  /// In en, this message translates to:
  /// **'SubCommand Group'**
  String get option_type_subcommand_group;

  /// Unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get option_type_unknown;

  /// User
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get option_type_user;

  /// Value {index}
  ///
  /// In en, this message translates to:
  /// **'Value {index}'**
  String option_value_number(int index);

  /// Thank you for your support! All ads are disabled.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support! All ads are disabled.'**
  String get premium_active_desc;

  /// Premium active
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premium_active_title;

  /// See plans
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get premium_card_button;

  /// Subscribe to remove all ads and start your bots instantly, without any popup.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to remove all ads and start your bots instantly, without any popup.'**
  String get premium_card_desc;

  /// Remove Ads
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get premium_card_title;

  /// Quick Access
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quick_access_title;

  /// Delete bot locally
  ///
  /// In en, this message translates to:
  /// **'Delete bot locally'**
  String get recovery_delete_bot;

  /// Recovery
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery_label;

  /// Retry Discord connection
  ///
  /// In en, this message translates to:
  /// **'Retry Discord connection'**
  String get recovery_retry_discord;

  /// Recovery mode
  ///
  /// In en, this message translates to:
  /// **'Recovery mode'**
  String get recovery_title;

  /// Active route: {label}
  ///
  /// In en, this message translates to:
  /// **'Active route: {label}'**
  String reply_active_route(String label);

  /// Add interactive buttons or dropdowns to this message
  ///
  /// In en, this message translates to:
  /// **'Add interactive buttons or dropdowns to this message'**
  String get reply_buttons_desc;

  /// Buttons & Select Menus (optional)
  ///
  /// In en, this message translates to:
  /// **'Buttons & Select Menus (optional)'**
  String get reply_buttons_optional;

  /// Choose the type of response to send
  ///
  /// In en, this message translates to:
  /// **'Choose the type of response to send'**
  String get reply_choose_type;

  /// Command Reply
  ///
  /// In en, this message translates to:
  /// **'Command Reply'**
  String get reply_command_reply_title;

  /// Configure Response Workflow
  ///
  /// In en, this message translates to:
  /// **'Configure Response Workflow'**
  String get reply_configure_workflow;

  /// Reply Details
  ///
  /// In en, this message translates to:
  /// **'Reply Details'**
  String get reply_editor_title;

  /// Layout Mode
  ///
  /// In en, this message translates to:
  /// **'Layout Mode'**
  String get reply_mode_layout;

  /// Discord's rich layout system — containers, media, text & forms
  ///
  /// In en, this message translates to:
  /// **'Discord\'s rich layout system — containers, media, text & forms'**
  String get reply_mode_layout_desc;

  /// Modal Form
  ///
  /// In en, this message translates to:
  /// **'Modal Form'**
  String get reply_mode_modal;

  /// Pop-up dialog with text input fields
  ///
  /// In en, this message translates to:
  /// **'Pop-up dialog with text input fields'**
  String get reply_mode_modal_desc;

  /// Standard Message
  ///
  /// In en, this message translates to:
  /// **'Standard Message'**
  String get reply_mode_standard;

  /// Text, embeds and optional buttons / select menus
  ///
  /// In en, this message translates to:
  /// **'Text, embeds and optional buttons / select menus'**
  String get reply_mode_standard_desc;

  /// Used as slash-command reply text. Supports ((variable)) syntax.
  ///
  /// In en, this message translates to:
  /// **'Used as slash-command reply text. Supports ((variable)) syntax.'**
  String get reply_response_text_helper;

  /// Response Text
  ///
  /// In en, this message translates to:
  /// **'Response Text'**
  String get reply_response_text_label;

  /// Response Workflow
  ///
  /// In en, this message translates to:
  /// **'Response Workflow'**
  String get reply_response_workflow;

  /// {count} embed(s)
  ///
  /// In en, this message translates to:
  /// **'{count} embed(s)'**
  String response_embeds_count(int count);

  /// interactive components
  ///
  /// In en, this message translates to:
  /// **'interactive components'**
  String get response_interactive_components;

  /// Layout mode
  ///
  /// In en, this message translates to:
  /// **'Layout mode'**
  String get response_mode_layout;

  /// Modal form
  ///
  /// In en, this message translates to:
  /// **'Modal form'**
  String get response_mode_modal;

  /// Standard message
  ///
  /// In en, this message translates to:
  /// **'Standard message'**
  String get response_mode_standard;

  /// ephemeral
  ///
  /// In en, this message translates to:
  /// **'ephemeral'**
  String get response_visibility_ephemeral;

  /// public
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get response_visibility_public;

  /// Auto defer if actions exist
  ///
  /// In en, this message translates to:
  /// **'Auto defer if actions exist'**
  String get response_workflow_auto_defer;

  /// Acknowledge quickly, execute actions, then edit final response.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge quickly, execute actions, then edit final response.'**
  String get response_workflow_auto_defer_desc;

  /// If variable exists and is not empty => use THEN text, otherwise ELSE text.
  ///
  /// In en, this message translates to:
  /// **'If variable exists and is not empty => use THEN text, otherwise ELSE text.'**
  String get response_workflow_condition_desc;

  /// Conditional response (MVP)
  ///
  /// In en, this message translates to:
  /// **'Conditional response (MVP)'**
  String get response_workflow_conditional_title;

  /// Deferred reply
  ///
  /// In en, this message translates to:
  /// **'Deferred reply'**
  String get response_workflow_deferred_reply;

  /// ELSE response text (optional)
  ///
  /// In en, this message translates to:
  /// **'ELSE response text (optional)'**
  String get response_workflow_else_text;

  /// Enable condition
  ///
  /// In en, this message translates to:
  /// **'Enable condition'**
  String get response_workflow_enable_condition;

  /// Ephemeral (only command user)
  ///
  /// In en, this message translates to:
  /// **'Ephemeral (only command user)'**
  String get response_workflow_ephemeral_only_user;

  /// Error policy
  ///
  /// In en, this message translates to:
  /// **'Error policy'**
  String get response_workflow_error_policy;

  /// When an action fails, edit the deferred message with an error.
  ///
  /// In en, this message translates to:
  /// **'When an action fails, edit the deferred message with an error.'**
  String get response_workflow_error_policy_desc;

  /// Component
  ///
  /// In en, this message translates to:
  /// **'Component'**
  String get response_workflow_mode_component;

  /// Modal
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get response_workflow_mode_modal;

  /// Normal
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get response_workflow_mode_normal;

  /// Public
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get response_workflow_public;

  /// Revert all changes
  ///
  /// In en, this message translates to:
  /// **'Revert all changes'**
  String get response_workflow_revert_tooltip;

  /// THEN response text (optional)
  ///
  /// In en, this message translates to:
  /// **'THEN response text (optional)'**
  String get response_workflow_then_text;

  /// Response Workflow
  ///
  /// In en, this message translates to:
  /// **'Response Workflow'**
  String get response_workflow_title;

  /// Variable key (ex: opts.userId)
  ///
  /// In en, this message translates to:
  /// **'Variable key (ex: opts.userId)'**
  String get response_workflow_variable_key;

  /// Visibility
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get response_workflow_visibility;

  /// Restore completed
  ///
  /// In en, this message translates to:
  /// **'Restore completed'**
  String get restore_completed;

  /// Restore completed (SQLite runtime restored, restart recommended)
  ///
  /// In en, this message translates to:
  /// **'Restore completed (SQLite runtime restored, restart recommended)'**
  String get restore_runtime_db_recommended;

  /// Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get review_actions_title;

  /// Description: {desc}
  ///
  /// In en, this message translates to:
  /// **'Description: {desc}'**
  String review_description_line(String desc);

  /// Folder: {folder}
  ///
  /// In en, this message translates to:
  /// **'Folder: {folder}'**
  String review_folder_line(String folder);

  /// Info
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get review_info_title;

  /// Legacy mode enabled
  ///
  /// In en, this message translates to:
  /// **'Legacy mode enabled'**
  String get review_legacy_mode;

  /// Local-only command
  ///
  /// In en, this message translates to:
  /// **'Local-only command'**
  String get review_local_only;

  /// Name: {name}
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String review_name_line(String name);

  /// (untitled)
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get review_name_untitled;

  /// {count} option(s)
  ///
  /// In en, this message translates to:
  /// **'{count} option(s)'**
  String review_options_count(int count);

  /// Reply
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get review_reply_title;

  /// {count} subcommand route(s)
  ///
  /// In en, this message translates to:
  /// **'{count} subcommand route(s)'**
  String review_subcommand_routes(int count);

  /// Trigger & Inputs
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get review_trigger_inputs_title;

  /// Type: {type}
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String review_type_line(String type);

  /// Please watch the entire ad to start your hosting session.
  ///
  /// In en, this message translates to:
  /// **'Please watch the entire ad to start your hosting session.'**
  String get rewarded_start_complete_ad;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get rewarded_start_continue;

  /// An ad is required to start this hosting session. This helps fund the project. Premium users can skip this.
  ///
  /// In en, this message translates to:
  /// **'An ad is required to start this hosting session. This helps fund the project. Premium users can skip this.'**
  String get rewarded_start_message;

  /// No ad available right now. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'No ad available right now. Please try again later.'**
  String get rewarded_start_no_ad_available;

  /// Skip
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get rewarded_start_skip;

  /// Thanks for your support!
  ///
  /// In en, this message translates to:
  /// **'Thanks for your support!'**
  String get rewarded_start_thanks;

  /// Ad Required
  ///
  /// In en, this message translates to:
  /// **'Ad Required'**
  String get rewarded_start_title;

  /// Watch ad
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get rewarded_start_watch;

  /// Select runner
  ///
  /// In en, this message translates to:
  /// **'Select runner'**
  String get runner_select_source;

  /// All runners
  ///
  /// In en, this message translates to:
  /// **'All runners'**
  String get runner_source_all;

  /// Runner: {name}
  ///
  /// In en, this message translates to:
  /// **'Runner: {name}'**
  String runner_source_label(String name);

  /// Local
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get runner_source_local;

  /// Bot Creator servers
  ///
  /// In en, this message translates to:
  /// **'Bot Creator servers'**
  String get runner_source_manager;

  /// Sign in to Bot Creator in Settings to load stats from Bot Creator servers.
  ///
  /// In en, this message translates to:
  /// **'Sign in to Bot Creator in Settings to load stats from Bot Creator servers.'**
  String get runner_source_manager_unavailable;

  /// Save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Add schedule
  ///
  /// In en, this message translates to:
  /// **'Add schedule'**
  String get scheduler_add_title;

  /// Add trigger
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get scheduler_add_trigger;

  /// Delete "{label}" schedule?
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\" schedule?'**
  String scheduler_delete_confirm(String label);

  /// Delete schedule
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get scheduler_delete_title;

  /// Edit schedule
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get scheduler_edit_title;

  /// No scheduled triggers yet.
  ///
  /// In en, this message translates to:
  /// **'No scheduled triggers yet.'**
  String get scheduler_empty;

  /// Every (minutes)
  ///
  /// In en, this message translates to:
  /// **'Every (minutes)'**
  String get scheduler_every_minutes;

  /// Every minutes must be greater than 0.
  ///
  /// In en, this message translates to:
  /// **'Every minutes must be greater than 0.'**
  String get scheduler_invalid_minutes;

  /// Label
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get scheduler_label_field;

  /// Optional display label
  ///
  /// In en, this message translates to:
  /// **'Optional display label'**
  String get scheduler_label_hint;

  /// Scheduler limit reached ({limit}).
  ///
  /// In en, this message translates to:
  /// **'Scheduler limit reached ({limit}).'**
  String scheduler_limit_reached(int limit);

  /// Create at least one workflow before adding a schedule.
  ///
  /// In en, this message translates to:
  /// **'Create at least one workflow before adding a schedule.'**
  String get scheduler_no_workflows;

  /// Scheduler
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler_page_title;

  /// Failed to save schedule: {error}
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule: {error}'**
  String scheduler_save_failed(String error);

  /// Workflow: {workflow} • Every {minutes} min
  ///
  /// In en, this message translates to:
  /// **'Workflow: {workflow} • Every {minutes} min'**
  String scheduler_subtitle(String workflow, int minutes);

  /// Scheduler
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler_tab;

  /// Sched
  ///
  /// In en, this message translates to:
  /// **'Sched'**
  String get scheduler_tab_short;

  /// Triggers: {count}{limit}
  ///
  /// In en, this message translates to:
  /// **'Triggers: {count}{limit}'**
  String scheduler_triggers_count(int count, String limit);

  /// Default value
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get scoped_default_value;

  /// Optional
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get scoped_default_value_hint;

  /// Delete "{key}" and all its stored runtime data?
  ///
  /// In en, this message translates to:
  /// **'Delete \"{key}\" and all its stored runtime data?'**
  String scoped_delete_confirm(String key);

  /// Delete Scoped Variable
  ///
  /// In en, this message translates to:
  /// **'Delete Scoped Variable'**
  String get scoped_delete_title;

  /// No scoped variables defined
  ///
  /// In en, this message translates to:
  /// **'No scoped variables defined'**
  String get scoped_empty;

  /// Scoped variables store a value per Discord context (user, server…). They are populated by the bot at runtime.
  ///
  /// In en, this message translates to:
  /// **'Scoped variables store a value per Discord context (user, server…). They are populated by the bot at runtime.'**
  String get scoped_empty_subtitle;

  /// Explore runtime data
  ///
  /// In en, this message translates to:
  /// **'Explore runtime data'**
  String get scoped_explore_runtime;

  /// Reference: {ref}
  ///
  /// In en, this message translates to:
  /// **'Reference: {ref}'**
  String scoped_ref(String ref);

  /// Legacy: {ref}
  ///
  /// In en, this message translates to:
  /// **'Legacy: {ref}'**
  String scoped_ref_legacy(String ref);

  /// Copy all
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get scoped_runtime_copy_all;

  /// No runtime data.
  /// This key will be populated by the bot at execution.
  ///
  /// In en, this message translates to:
  /// **'No runtime data.\nThis key will be populated by the bot at execution.'**
  String get scoped_runtime_empty;

  /// Search by ID or name…
  ///
  /// In en, this message translates to:
  /// **'Search by ID or name…'**
  String get scoped_runtime_search;

  /// Scope: {scope} · {count} context(s) found
  ///
  /// In en, this message translates to:
  /// **'Scope: {scope} · {count} context(s) found'**
  String scoped_runtime_subtitle(String scope, int count);

  /// Runtime data — "{key}"
  ///
  /// In en, this message translates to:
  /// **'Runtime data — \"{key}\"'**
  String scoped_runtime_title(String key);

  /// Scope
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scoped_scope;

  /// The entity level at which the variable is stored.
  ///
  /// In en, this message translates to:
  /// **'The entity level at which the variable is stored.'**
  String get scoped_scope_help;

  /// Scoped Variables
  ///
  /// In en, this message translates to:
  /// **'Scoped Variables'**
  String get scoped_title;

  /// Add block
  ///
  /// In en, this message translates to:
  /// **'Add block'**
  String get scratch_add_block;

  /// BDFD Script
  ///
  /// In en, this message translates to:
  /// **'BDFD Script'**
  String get scratch_bdfd_script;

  /// Command Trigger
  ///
  /// In en, this message translates to:
  /// **'Command Trigger'**
  String get scratch_block_entry_point;

  /// Metadata
  ///
  /// In en, this message translates to:
  /// **'Metadata'**
  String get scratch_block_metadata;

  /// Required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get scratch_block_required;

  /// Dart Script
  ///
  /// In en, this message translates to:
  /// **'Dart Script'**
  String get scratch_dart_script;

  /// Event trigger
  ///
  /// In en, this message translates to:
  /// **'Event trigger'**
  String get scratch_entry_event_trigger;

  /// Function
  ///
  /// In en, this message translates to:
  /// **'Function'**
  String get scratch_entry_function;

  /// Slash Command (/)
  ///
  /// In en, this message translates to:
  /// **'Slash Command (/)'**
  String get scratch_entry_interaction;

  /// Text Message
  ///
  /// In en, this message translates to:
  /// **'Text Message'**
  String get scratch_entry_message;

  /// Scratch entry point hint
  ///
  /// In en, this message translates to:
  /// **'Scratch entry point hint'**
  String get scratch_entry_point_hint;

  /// Entry point name
  ///
  /// In en, this message translates to:
  /// **'Entry point name'**
  String get scratch_entry_point_label;

  /// When does this command run?
  ///
  /// In en, this message translates to:
  /// **'When does this command run?'**
  String get scratch_entry_point_listen;

  /// Event category
  ///
  /// In en, this message translates to:
  /// **'Event category'**
  String get scratch_event_category;

  /// Event name
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get scratch_event_name;

  /// Event variables
  ///
  /// In en, this message translates to:
  /// **'Event variables'**
  String get scratch_event_variables;

  /// How is the command built?
  ///
  /// In en, this message translates to:
  /// **'How is the command built?'**
  String get scratch_execution_mode;

  /// Legacy configuration
  ///
  /// In en, this message translates to:
  /// **'Legacy configuration'**
  String get scratch_legacy_config;

  /// Advanced settings
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get scratch_meta_advanced;

  /// Command description
  ///
  /// In en, this message translates to:
  /// **'Command description'**
  String get scratch_meta_desc_hint;

  /// Command name
  ///
  /// In en, this message translates to:
  /// **'Command name'**
  String get scratch_meta_name_hint;

  /// Command type
  ///
  /// In en, this message translates to:
  /// **'Command type'**
  String get scratch_meta_type_label;

  /// Message command
  ///
  /// In en, this message translates to:
  /// **'Message command'**
  String get scratch_meta_type_message;

  /// Triggered from the message context menu.
  ///
  /// In en, this message translates to:
  /// **'Triggered from the message context menu.'**
  String get scratch_meta_type_message_desc;

  /// Prefix command
  ///
  /// In en, this message translates to:
  /// **'Prefix command'**
  String get scratch_meta_type_prefix;

  /// Triggered by a text prefix (e.g. !help).
  ///
  /// In en, this message translates to:
  /// **'Triggered by a text prefix (e.g. !help).'**
  String get scratch_meta_type_prefix_desc;

  /// Slash command
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get scratch_meta_type_slash;

  /// Triggered by typing / in Discord.
  ///
  /// In en, this message translates to:
  /// **'Triggered by typing / in Discord.'**
  String get scratch_meta_type_slash_desc;

  /// User command
  ///
  /// In en, this message translates to:
  /// **'User command'**
  String get scratch_meta_type_user;

  /// Triggered from the user context menu.
  ///
  /// In en, this message translates to:
  /// **'Triggered from the user context menu.'**
  String get scratch_meta_type_user_desc;

  /// BDFD Code
  ///
  /// In en, this message translates to:
  /// **'BDFD Code'**
  String get scratch_mode_bdfd;

  /// Visual (Blocks)
  ///
  /// In en, this message translates to:
  /// **'Visual (Blocks)'**
  String get scratch_mode_blocks;

  /// Dart
  ///
  /// In en, this message translates to:
  /// **'Dart'**
  String get scratch_mode_dart;

  /// Response
  ///
  /// In en, this message translates to:
  /// **'Response'**
  String get scratch_response_block;

  /// Components
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get scratch_response_components;

  /// Edit response
  ///
  /// In en, this message translates to:
  /// **'Edit response'**
  String get scratch_response_edit;

  /// Add argument
  ///
  /// In en, this message translates to:
  /// **'Add argument'**
  String get scratch_workflow_add_argument;

  /// Arguments (Variables)
  ///
  /// In en, this message translates to:
  /// **'Arguments (Variables)'**
  String get scratch_workflow_arguments;

  /// Workflow Settings
  ///
  /// In en, this message translates to:
  /// **'Workflow Settings'**
  String get scratch_workflow_metadata;

  /// Workflow Name
  ///
  /// In en, this message translates to:
  /// **'Workflow Name'**
  String get scratch_workflow_name;

  /// Workflow Type
  ///
  /// In en, this message translates to:
  /// **'Workflow Type'**
  String get scratch_workflow_type;

  /// Event-driven
  ///
  /// In en, this message translates to:
  /// **'Event-driven'**
  String get scratch_workflow_type_event;

  /// General
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get scratch_workflow_type_general;

  /// Export command as Base64
  ///
  /// In en, this message translates to:
  /// **'Export command as Base64'**
  String get serialization_export_base64_title;

  /// Copy readable JSON to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copy readable JSON to clipboard'**
  String get serialization_export_json_subtitle;

  /// Export command as JSON
  ///
  /// In en, this message translates to:
  /// **'Export command as JSON'**
  String get serialization_export_json_title;

  /// Paste a command payload (JSON or Base64).
  ///
  /// In en, this message translates to:
  /// **'Paste a command payload (JSON or Base64).'**
  String get serialization_import_desc;

  /// Import command
  ///
  /// In en, this message translates to:
  /// **'Import command'**
  String get serialization_import_title;

  /// Command imported into editor.
  ///
  /// In en, this message translates to:
  /// **'Command imported into editor.'**
  String get serialization_imported;

  /// Invalid command payload format.
  ///
  /// In en, this message translates to:
  /// **'Invalid command payload format.'**
  String get serialization_invalid_format;

  /// Invalid command payload structure.
  ///
  /// In en, this message translates to:
  /// **'Invalid command payload structure.'**
  String get serialization_invalid_structure;

  /// Sign in to Bot Creator with Discord
  ///
  /// In en, this message translates to:
  /// **'Sign in to Bot Creator with Discord'**
  String get settings_account_connect_label;

  /// Account connected. Your bots and data are now synced with Bot Creator.
  ///
  /// In en, this message translates to:
  /// **'Account connected. Your bots and data are now synced with Bot Creator.'**
  String get settings_account_connected_hint;

  /// Sign out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settings_account_disconnect_label;

  /// Your Bot Creator account is created automatically when you add a bot. Then sign in with Discord to recover your bots on this device.
  ///
  /// In en, this message translates to:
  /// **'Your Bot Creator account is created automatically when you add a bot. Then sign in with Discord to recover your bots on this device.'**
  String get settings_account_disconnected_hint;

  /// Account connected
  ///
  /// In en, this message translates to:
  /// **'Account connected'**
  String get settings_account_status_connected;

  /// Not signed in
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get settings_account_status_disconnected;

  /// Checking ad privacy settings...
  ///
  /// In en, this message translates to:
  /// **'Checking ad privacy settings...'**
  String get settings_ads_privacy_loading;

  /// Manage ad privacy choices
  ///
  /// In en, this message translates to:
  /// **'Manage ad privacy choices'**
  String get settings_ads_privacy_manage;

  /// Ad privacy options are not required right now
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options are not required right now'**
  String get settings_ads_privacy_not_required;

  /// Could not open ad privacy options
  ///
  /// In en, this message translates to:
  /// **'Could not open ad privacy options'**
  String get settings_ads_privacy_open_error;

  /// Ad privacy options opened
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options opened'**
  String get settings_ads_privacy_opened;

  /// App
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settings_app_version;

  /// Appearance & language
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get settings_appearance_title;

  /// Auto-backup check…
  ///
  /// In en, this message translates to:
  /// **'Auto-backup check…'**
  String get settings_auto_backup_check_loading;

  /// Every 12h
  ///
  /// In en, this message translates to:
  /// **'Every 12h'**
  String get settings_auto_backup_every_12h;

  /// Every 24h
  ///
  /// In en, this message translates to:
  /// **'Every 24h'**
  String get settings_auto_backup_every_24h;

  /// Every 6h
  ///
  /// In en, this message translates to:
  /// **'Every 6h'**
  String get settings_auto_backup_every_6h;

  /// Every 72h
  ///
  /// In en, this message translates to:
  /// **'Every 72h'**
  String get settings_auto_backup_every_72h;

  /// Auto-backup interval
  ///
  /// In en, this message translates to:
  /// **'Auto-backup interval'**
  String get settings_auto_backup_interval;

  /// Backup now
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get settings_backup_now;

  /// Manage your data synchronization with Google Drive
  ///
  /// In en, this message translates to:
  /// **'Manage your data synchronization with Google Drive'**
  String get settings_backup_restore_desc;

  /// Backup and Restore
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get settings_backup_restore_title;

  /// Built-in legacy !help command
  ///
  /// In en, this message translates to:
  /// **'Built-in legacy !help command'**
  String get settings_builtin_help;

  /// Mandatory feature with explicit toggle. Disable it if you only want custom help behavior.
  ///
  /// In en, this message translates to:
  /// **'Mandatory feature with explicit toggle. Disable it if you only want custom help behavior.'**
  String get settings_builtin_help_subtitle;

  /// Clear logs
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get settings_clear_logs;

  /// Mobile bots now use Bot Creator servers.
  ///
  /// In en, this message translates to:
  /// **'Mobile bots now use Bot Creator servers.'**
  String get settings_cloud_hosting_enabled;

  /// A quick view of feature coverage for users moving from BDFD.
  ///
  /// In en, this message translates to:
  /// **'A quick view of feature coverage for users moving from BDFD.'**
  String get settings_compatibility_desc;

  /// Components / Interactions
  ///
  /// In en, this message translates to:
  /// **'Components / Interactions'**
  String get settings_compatibility_functions_category_components;

  /// Control flow
  ///
  /// In en, this message translates to:
  /// **'Control flow'**
  String get settings_compatibility_functions_category_control;

  /// Embeds
  ///
  /// In en, this message translates to:
  /// **'Embeds'**
  String get settings_compatibility_functions_category_embeds;

  /// Guards and permissions
  ///
  /// In en, this message translates to:
  /// **'Guards and permissions'**
  String get settings_compatibility_functions_category_guards;

  /// HTTP helpers
  ///
  /// In en, this message translates to:
  /// **'HTTP helpers'**
  String get settings_compatibility_functions_category_http;

  /// JSON helpers
  ///
  /// In en, this message translates to:
  /// **'JSON helpers'**
  String get settings_compatibility_functions_category_json;

  /// Logging
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get settings_compatibility_functions_category_logging;

  /// Messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settings_compatibility_functions_category_messages;

  /// Runtime placeholders
  ///
  /// In en, this message translates to:
  /// **'Runtime placeholders'**
  String get settings_compatibility_functions_category_runtime;

  /// Threads
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get settings_compatibility_functions_category_threads;

  /// Scoped variables
  ///
  /// In en, this message translates to:
  /// **'Scoped variables'**
  String get settings_compatibility_functions_category_variables;

  /// Compatible functions: {count}
  ///
  /// In en, this message translates to:
  /// **'Compatible functions: {count}'**
  String settings_compatibility_functions_count(int count);

  /// BDFD reference total: {count}
  ///
  /// In en, this message translates to:
  /// **'BDFD reference total: {count}'**
  String settings_compatibility_functions_count_bdfd(int count);

  /// Bot Creator supported: {count}
  ///
  /// In en, this message translates to:
  /// **'Bot Creator supported: {count}'**
  String settings_compatibility_functions_count_bot_creator(int count);

  /// Bot Creator only: {count}
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only: {count}'**
  String settings_compatibility_functions_count_bot_only(int count);

  /// Supported on both: {count}
  ///
  /// In en, this message translates to:
  /// **'Supported on both: {count}'**
  String settings_compatibility_functions_count_both(int count);

  /// Missing in Bot Creator: {count}
  ///
  /// In en, this message translates to:
  /// **'Missing in Bot Creator: {count}'**
  String settings_compatibility_functions_count_missing(int count);

  /// No function in this section.
  ///
  /// In en, this message translates to:
  /// **'No function in this section.'**
  String get settings_compatibility_functions_empty;

  /// BDFD-only entries are functions listed in the provided BDFD catalog but not currently implemented in Bot Creator.
  ///
  /// In en, this message translates to:
  /// **'BDFD-only entries are functions listed in the provided BDFD catalog but not currently implemented in Bot Creator.'**
  String get settings_compatibility_functions_matrix_note;

  /// Diff view between Bot Creator implementation and BDFD reference functions.
  ///
  /// In en, this message translates to:
  /// **'Diff view between Bot Creator implementation and BDFD reference functions.'**
  String get settings_compatibility_functions_matrix_subtitle;

  /// This page is generated from the current implementation scope and will grow over time.
  ///
  /// In en, this message translates to:
  /// **'This page is generated from the current implementation scope and will grow over time.'**
  String get settings_compatibility_functions_note;

  /// Search a function (example: $userJoined)
  ///
  /// In en, this message translates to:
  /// **'Search a function (example: \$userJoined)'**
  String get settings_compatibility_functions_search_hint;

  /// Supported on Bot Creator only
  ///
  /// In en, this message translates to:
  /// **'Supported on Bot Creator only'**
  String get settings_compatibility_functions_section_bot_only;

  /// Loop helpers are currently Bot Creator specific.
  ///
  /// In en, this message translates to:
  /// **'Loop helpers are currently Bot Creator specific.'**
  String get settings_compatibility_functions_section_bot_only_note;

  /// Supported on Bot Creator and BDFD
  ///
  /// In en, this message translates to:
  /// **'Supported on Bot Creator and BDFD'**
  String get settings_compatibility_functions_section_both;

  /// Available on BDFD but missing in Bot Creator
  ///
  /// In en, this message translates to:
  /// **'Available on BDFD but missing in Bot Creator'**
  String get settings_compatibility_functions_section_missing;

  /// Functions currently implemented and usable in Bot Creator BDFD mode.
  ///
  /// In en, this message translates to:
  /// **'Functions currently implemented and usable in Bot Creator BDFD mode.'**
  String get settings_compatibility_functions_subtitle;

  /// Compatible BDFD Functions
  ///
  /// In en, this message translates to:
  /// **'Compatible BDFD Functions'**
  String get settings_compatibility_functions_title;

  /// Full coverage of the BDFD function catalog.
  ///
  /// In en, this message translates to:
  /// **'Full coverage of the BDFD function catalog.'**
  String get settings_compatibility_item_bdscript_desc;

  /// BDScript function parity
  ///
  /// In en, this message translates to:
  /// **'BDScript function parity'**
  String get settings_compatibility_item_bdscript_title;

  /// Most common events are supported, some are runtime-limited.
  ///
  /// In en, this message translates to:
  /// **'Most common events are supported, some are runtime-limited.'**
  String get settings_compatibility_item_events_desc;

  /// Event coverage
  ///
  /// In en, this message translates to:
  /// **'Event coverage'**
  String get settings_compatibility_item_events_title;

  /// Remote runner is available, multi-runner support is in progress.
  ///
  /// In en, this message translates to:
  /// **'Remote runner is available, multi-runner support is in progress.'**
  String get settings_compatibility_item_runner_desc;

  /// Runner architecture
  ///
  /// In en, this message translates to:
  /// **'Runner architecture'**
  String get settings_compatibility_item_runner_title;

  /// Dynamic variables and template helpers are supported.
  ///
  /// In en, this message translates to:
  /// **'Dynamic variables and template helpers are supported.'**
  String get settings_compatibility_item_variables_desc;

  /// Runtime variables and templates
  ///
  /// In en, this message translates to:
  /// **'Runtime variables and templates'**
  String get settings_compatibility_item_variables_title;

  /// Visual command and response workflows are available.
  ///
  /// In en, this message translates to:
  /// **'Visual command and response workflows are available.'**
  String get settings_compatibility_item_workflows_desc;

  /// Workflow builder
  ///
  /// In en, this message translates to:
  /// **'Workflow builder'**
  String get settings_compatibility_item_workflows_title;

  /// This snapshot is intentionally high-level and will evolve with releases.
  ///
  /// In en, this message translates to:
  /// **'This snapshot is intentionally high-level and will evolve with releases.'**
  String get settings_compatibility_note;

  /// View compatible functions
  ///
  /// In en, this message translates to:
  /// **'View compatible functions'**
  String get settings_compatibility_open_functions;

  /// Missing
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get settings_compatibility_status_missing;

  /// Partial
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get settings_compatibility_status_partial;

  /// Supported
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get settings_compatibility_status_supported;

  /// BDFD compatibility snapshot
  ///
  /// In en, this message translates to:
  /// **'BDFD compatibility snapshot'**
  String get settings_compatibility_title;

  /// Data Operations
  ///
  /// In en, this message translates to:
  /// **'Data Operations'**
  String get settings_data_operations_title;

  /// Reset local preferences or replay onboarding for testing.
  ///
  /// In en, this message translates to:
  /// **'Reset local preferences or replay onboarding for testing.'**
  String get settings_debug_desc;

  /// Premium bypass
  ///
  /// In en, this message translates to:
  /// **'Premium bypass'**
  String get settings_debug_premium_bypass;

  /// Unlock all Premium features without a subscription (debug only).
  ///
  /// In en, this message translates to:
  /// **'Unlock all Premium features without a subscription (debug only).'**
  String get settings_debug_premium_bypass_desc;

  /// Debug tools
  ///
  /// In en, this message translates to:
  /// **'Debug tools'**
  String get settings_debug_title;

  /// Diagnostics copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard'**
  String get settings_diagnostics_copied;

  /// Copy all logs
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get settings_diagnostics_copy_all;

  /// Startup Diagnostics
  ///
  /// In en, this message translates to:
  /// **'Startup Diagnostics'**
  String get settings_diagnostics_dialog_title;

  /// No application logs yet.
  ///
  /// In en, this message translates to:
  /// **'No application logs yet.'**
  String get settings_diagnostics_empty;

  /// Shows app diagnostics logs only (bot logs are excluded).
  ///
  /// In en, this message translates to:
  /// **'Shows app diagnostics logs only (bot logs are excluded).'**
  String get settings_diagnostics_page_scope_note;

  /// Application Logs
  ///
  /// In en, this message translates to:
  /// **'Application Logs'**
  String get settings_diagnostics_page_title;

  /// Refresh logs
  ///
  /// In en, this message translates to:
  /// **'Refresh logs'**
  String get settings_diagnostics_refresh;

  /// Diagnostics
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settings_diagnostics_section_title;

  /// Authenticating with Discord…
  ///
  /// In en, this message translates to:
  /// **'Authenticating with Discord…'**
  String get settings_discord_rpc_authenticating;

  /// Authorization code cached; retry to finish the token exchange
  ///
  /// In en, this message translates to:
  /// **'Authorization code cached; retry to finish the token exchange'**
  String get settings_discord_rpc_authorization_code_pending_exchange;

  /// Authorization code received
  ///
  /// In en, this message translates to:
  /// **'Authorization code received'**
  String get settings_discord_rpc_authorization_pending_exchange;

  /// Authorize
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get settings_discord_rpc_authorize;

  /// Waiting for Discord authorization…
  ///
  /// In en, this message translates to:
  /// **'Waiting for Discord authorization…'**
  String get settings_discord_rpc_authorizing;

  /// https://auth.example.com
  ///
  /// In en, this message translates to:
  /// **'https://auth.example.com'**
  String get settings_discord_rpc_broker_hint;

  /// OAuth broker URL (advanced, optional)
  ///
  /// In en, this message translates to:
  /// **'OAuth broker URL (advanced, optional)'**
  String get settings_discord_rpc_broker_label;

  /// Client ID is enough for the public-client flow; broker URL and client secret are optional fallbacks
  ///
  /// In en, this message translates to:
  /// **'Client ID is enough for the public-client flow; broker URL and client secret are optional fallbacks'**
  String get settings_discord_rpc_broker_required;

  /// This ID is fixed in Bot Creator and cannot be changed from settings.
  ///
  /// In en, this message translates to:
  /// **'This ID is fixed in Bot Creator and cannot be changed from settings.'**
  String get settings_discord_rpc_client_id_helper;

  /// 1350824555119382678
  ///
  /// In en, this message translates to:
  /// **'1350824555119382678'**
  String get settings_discord_rpc_client_id_hint;

  /// Discord application client ID required
  ///
  /// In en, this message translates to:
  /// **'Discord application client ID required'**
  String get settings_discord_rpc_client_id_required;

  /// Optional advanced fallback for a confidential-client flow handled locally.
  ///
  /// In en, this message translates to:
  /// **'Optional advanced fallback for a confidential-client flow handled locally.'**
  String get settings_discord_rpc_client_secret_helper;

  /// Client secret
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get settings_discord_rpc_client_secret_hint;

  /// Discord application client secret (optional)
  ///
  /// In en, this message translates to:
  /// **'Discord application client secret (optional)'**
  String get settings_discord_rpc_client_secret_label;

  /// Complete authorization
  ///
  /// In en, this message translates to:
  /// **'Complete authorization'**
  String get settings_discord_rpc_complete_authorization;

  /// Refresh presence
  ///
  /// In en, this message translates to:
  /// **'Refresh presence'**
  String get settings_discord_rpc_connect;

  /// Presence sent to Discord
  ///
  /// In en, this message translates to:
  /// **'Presence sent to Discord'**
  String get settings_discord_rpc_connected;

  /// Connecting to Discord…
  ///
  /// In en, this message translates to:
  /// **'Connecting to Discord…'**
  String get settings_discord_rpc_connecting;

  /// Publish Bot Creator desktop activity to the local Discord client. Bot Creator always uses the built-in Discord application and sends SET_ACTIVITY directly over local IPC when enabled.
  ///
  /// In en, this message translates to:
  /// **'Publish Bot Creator desktop activity to the local Discord client. Bot Creator always uses the built-in Discord application and sends SET_ACTIVITY directly over local IPC when enabled.'**
  String get settings_discord_rpc_desc;

  /// Disabled
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settings_discord_rpc_disabled;

  /// Close IPC
  ///
  /// In en, this message translates to:
  /// **'Close IPC'**
  String get settings_discord_rpc_disconnect;

  /// IPC closed
  ///
  /// In en, this message translates to:
  /// **'IPC closed'**
  String get settings_discord_rpc_disconnected;

  /// Enable Discord Rich Presence
  ///
  /// In en, this message translates to:
  /// **'Enable Discord Rich Presence'**
  String get settings_discord_rpc_enable;

  /// Enable Discord Rich Presence first
  ///
  /// In en, this message translates to:
  /// **'Enable Discord Rich Presence first'**
  String get settings_discord_rpc_enable_first;

  /// IPC endpoint: {endpoint}
  ///
  /// In en, this message translates to:
  /// **'IPC endpoint: {endpoint}'**
  String settings_discord_rpc_endpoint(String endpoint);

  /// Discord RPC error
  ///
  /// In en, this message translates to:
  /// **'Discord RPC error'**
  String get settings_discord_rpc_error;

  /// Completing OAuth exchange…
  ///
  /// In en, this message translates to:
  /// **'Completing OAuth exchange…'**
  String get settings_discord_rpc_exchanging_code;

  /// Local Discord IPC connected; no OAuth HTTP request sent yet, authentication still required
  ///
  /// In en, this message translates to:
  /// **'Local Discord IPC connected; no OAuth HTTP request sent yet, authentication still required'**
  String get settings_discord_rpc_ipc_connected_auth_required;

  /// Local IPC already open
  ///
  /// In en, this message translates to:
  /// **'Local IPC already open'**
  String get settings_discord_rpc_ipc_open;

  /// Last error: {error}
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String settings_discord_rpc_last_error(String error);

  /// Authorization required
  ///
  /// In en, this message translates to:
  /// **'Authorization required'**
  String get settings_discord_rpc_needs_authorization;

  /// Client ID required
  ///
  /// In en, this message translates to:
  /// **'Client ID required'**
  String get settings_discord_rpc_not_configured;

  /// Open local IPC
  ///
  /// In en, this message translates to:
  /// **'Open local IPC'**
  String get settings_discord_rpc_open_ipc;

  /// Discord Rich Presence is desktop only
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence is desktop only'**
  String get settings_discord_rpc_platform_unsupported;

  /// Save settings
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settings_discord_rpc_save;

  /// Discord Rich Presence settings saved
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence settings saved'**
  String get settings_discord_rpc_saved;

  /// Discord Rich Presence
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence'**
  String get settings_discord_rpc_title;

  /// Discord transport is not supported on this platform yet
  ///
  /// In en, this message translates to:
  /// **'Discord transport is not supported on this platform yet'**
  String get settings_discord_rpc_transport_unsupported;

  /// Authorized user: {user}
  ///
  /// In en, this message translates to:
  /// **'Authorized user: {user}'**
  String settings_discord_rpc_user(String user);

  /// Connect to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Connect to Google Drive'**
  String get settings_drive_connect;

  /// Connecting to Google Drive…
  ///
  /// In en, this message translates to:
  /// **'Connecting to Google Drive…'**
  String get settings_drive_connect_loading;

  /// Connected to Google Drive
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Drive'**
  String get settings_drive_connected;

  /// Connect your Google Drive account to sync your data
  ///
  /// In en, this message translates to:
  /// **'Connect your Google Drive account to sync your data'**
  String get settings_drive_desc;

  /// Disconnect
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settings_drive_disconnect;

  /// Disconnecting…
  ///
  /// In en, this message translates to:
  /// **'Disconnecting…'**
  String get settings_drive_disconnect_loading;

  /// Disconnected from Google Drive
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Google Drive'**
  String get settings_drive_disconnected;

  /// Connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settings_drive_status_connected;

  /// Google Drive Connection
  ///
  /// In en, this message translates to:
  /// **'Google Drive Connection'**
  String get settings_drive_title;

  /// Enable auto-backup
  ///
  /// In en, this message translates to:
  /// **'Enable auto-backup'**
  String get settings_enable_auto_backup;

  /// Create versioned snapshots automatically when due.
  ///
  /// In en, this message translates to:
  /// **'Create versioned snapshots automatically when due.'**
  String get settings_enable_auto_backup_desc;

  /// On this platform, Bot Creator never hosts your bots. You can use your self-hosted runner or execute bots locally.
  ///
  /// In en, this message translates to:
  /// **'On this platform, Bot Creator never hosts your bots. You can use your self-hosted runner or execute bots locally.'**
  String get settings_execution_mode_desc;

  /// Bots now start locally. Runner settings stay stored and can be re-enabled anytime.
  ///
  /// In en, this message translates to:
  /// **'Bots now start locally. Runner settings stay stored and can be re-enabled anytime.'**
  String get settings_execution_mode_local_active;

  /// No runner is configured yet. The app stays local until you add one.
  ///
  /// In en, this message translates to:
  /// **'No runner is configured yet. The app stays local until you add one.'**
  String get settings_execution_mode_no_runner;

  /// The self-hosted runner is preferred. If no runner is configured, the app falls back to local.
  ///
  /// In en, this message translates to:
  /// **'The self-hosted runner is preferred. If no runner is configured, the app falls back to local.'**
  String get settings_execution_mode_runner_priority;

  /// Execution mode
  ///
  /// In en, this message translates to:
  /// **'Execution mode'**
  String get settings_execution_mode_title;

  /// Use a self-hosted runner
  ///
  /// In en, this message translates to:
  /// **'Use a self-hosted runner'**
  String get settings_execution_mode_use_runner;

  /// Export
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settings_export;

  /// Export App Data
  ///
  /// In en, this message translates to:
  /// **'Export App Data'**
  String get settings_export_app_data;

  /// Exporting…
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get settings_export_loading;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settings_import;

  /// Import App Data
  ///
  /// In en, this message translates to:
  /// **'Import App Data'**
  String get settings_import_app_data;

  /// Importing…
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get settings_import_loading;

  /// Choose the language used by the app.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by the app.'**
  String get settings_language_desc;

  /// Automatic (device)
  ///
  /// In en, this message translates to:
  /// **'Automatic (device)'**
  String get settings_language_system;

  /// Language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language_title;

  /// Language updated
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get settings_language_updated;

  /// Last auto-backup: {date}
  ///
  /// In en, this message translates to:
  /// **'Last auto-backup: {date}'**
  String settings_last_auto_backup_at(String date);

  /// Last auto-backup: never
  ///
  /// In en, this message translates to:
  /// **'Last auto-backup: never'**
  String get settings_last_auto_backup_never;

  /// Legacy command prefix
  ///
  /// In en, this message translates to:
  /// **'Legacy command prefix'**
  String get settings_legacy_prefix;

  /// Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))
  ///
  /// In en, this message translates to:
  /// **'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))'**
  String get settings_legacy_prefix_helper;

  /// !, ? or ((guild.prefix | user.prefix | !))
  ///
  /// In en, this message translates to:
  /// **'!, ? or ((guild.prefix | user.prefix | !))'**
  String get settings_legacy_prefix_hint;

  /// Review how your data is handled and stored.
  ///
  /// In en, this message translates to:
  /// **'Review how your data is handled and stored.'**
  String get settings_legal_desc;

  /// Legal
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settings_legal_title;

  /// Mobile bots now use your device for hosting.
  ///
  /// In en, this message translates to:
  /// **'Mobile bots now use your device for hosting.'**
  String get settings_local_hosting_enabled;

  /// Diagnostics log cleared
  ///
  /// In en, this message translates to:
  /// **'Diagnostics log cleared'**
  String get settings_logs_cleared;

  /// Bot Creator Server session is invalid or expired
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server session is invalid or expired'**
  String get settings_main_api_auth_failed;

  /// Check Bot Creator Server
  ///
  /// In en, this message translates to:
  /// **'Check Bot Creator Server'**
  String get settings_main_api_check;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_main_api_clear;

  /// Bot Creator Server settings cleared
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server settings cleared'**
  String get settings_main_api_cleared;

  /// Connect Discord account
  ///
  /// In en, this message translates to:
  /// **'Connect Discord account'**
  String get settings_main_api_connect_discord;

  /// Bot Creator Server reachable ✓
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server reachable ✓'**
  String get settings_main_api_connected;

  /// Discord account connected
  ///
  /// In en, this message translates to:
  /// **'Discord account connected'**
  String get settings_main_api_connected_discord;

  /// Connected as {user}
  ///
  /// In en, this message translates to:
  /// **'Connected as {user}'**
  String settings_main_api_connected_user(String user);

  /// Connect Bot Creator to your Bot Creator Server and sign in with Discord. The Discord client secret must stay on the backend.
  ///
  /// In en, this message translates to:
  /// **'Connect Bot Creator to your Bot Creator Server and sign in with Discord. The Discord client secret must stay on the backend.'**
  String get settings_main_api_desc;

  /// Discord login via Bot Creator Server is available on desktop only.
  ///
  /// In en, this message translates to:
  /// **'Discord login via Bot Creator Server is available on desktop only.'**
  String get settings_main_api_desktop_only;

  /// Disconnect account
  ///
  /// In en, this message translates to:
  /// **'Disconnect account'**
  String get settings_main_api_disconnect;

  /// Bot Creator Server URL required
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server URL required'**
  String get settings_main_api_not_configured;

  /// Save Bot Creator Server
  ///
  /// In en, this message translates to:
  /// **'Save Bot Creator Server'**
  String get settings_main_api_save;

  /// Bot Creator Server settings saved
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server settings saved'**
  String get settings_main_api_saved;

  /// Discord session active
  ///
  /// In en, this message translates to:
  /// **'Discord session active'**
  String get settings_main_api_session_connected;

  /// Discord session disconnected
  ///
  /// In en, this message translates to:
  /// **'Discord session disconnected'**
  String get settings_main_api_session_disconnected;

  /// Discord session expired
  ///
  /// In en, this message translates to:
  /// **'Discord session expired'**
  String get settings_main_api_session_expired;

  /// Bot Creator Server
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server'**
  String get settings_main_api_title;

  /// Bot Creator Server unreachable
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server unreachable'**
  String get settings_main_api_unreachable;

  /// https://api.example.com
  ///
  /// In en, this message translates to:
  /// **'https://api.example.com'**
  String get settings_main_api_url_hint;

  /// Bot Creator Server URL required
  ///
  /// In en, this message translates to:
  /// **'Bot Creator Server URL required'**
  String get settings_main_api_url_required;

  /// Discord user
  ///
  /// In en, this message translates to:
  /// **'Discord user'**
  String get settings_main_api_user_unknown;

  /// Manual snapshot
  ///
  /// In en, this message translates to:
  /// **'Manual snapshot'**
  String get settings_manual_snapshot_label;

  /// MEMBER
  ///
  /// In en, this message translates to:
  /// **'MEMBER'**
  String get settings_member_badge;

  /// No description provided for @settings_notifications_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose which types of push notifications you want to receive.'**
  String get settings_notifications_desc;

  /// No description provided for @settings_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settings_notifications_title;

  /// No description provided for @settings_notifications_topic_billing.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get settings_notifications_topic_billing;

  /// No description provided for @settings_notifications_topic_billing_desc.
  ///
  /// In en, this message translates to:
  /// **'Subscription renewal reminders and payment confirmations.'**
  String get settings_notifications_topic_billing_desc;

  /// No description provided for @settings_notifications_topic_botAlerts.
  ///
  /// In en, this message translates to:
  /// **'Bot Alerts'**
  String get settings_notifications_topic_botAlerts;

  /// No description provided for @settings_notifications_topic_botAlerts_desc.
  ///
  /// In en, this message translates to:
  /// **'Warnings when your bots go offline or encounter errors.'**
  String get settings_notifications_topic_botAlerts_desc;

  /// No description provided for @settings_notifications_topic_broadcast.
  ///
  /// In en, this message translates to:
  /// **'Broadcast'**
  String get settings_notifications_topic_broadcast;

  /// No description provided for @settings_notifications_topic_broadcast_desc.
  ///
  /// In en, this message translates to:
  /// **'Important announcements and news from Bot Creator.'**
  String get settings_notifications_topic_broadcast_desc;

  /// No description provided for @settings_notifications_topic_updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settings_notifications_topic_updates;

  /// No description provided for @settings_notifications_topic_updates_desc.
  ///
  /// In en, this message translates to:
  /// **'New features, app updates, and changelog highlights.'**
  String get settings_notifications_topic_updates_desc;

  /// Open Ad Inspector
  ///
  /// In en, this message translates to:
  /// **'Open Ad Inspector'**
  String get settings_open_ad_inspector;

  /// Button label to view open source licenses
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get settings_oss_licenses;

  /// OWNER
  ///
  /// In en, this message translates to:
  /// **'OWNER'**
  String get settings_owner_badge;

  /// Owner
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get settings_owner_fallback;

  /// Personal User
  ///
  /// In en, this message translates to:
  /// **'Personal User'**
  String get settings_personal_owner_fallback;

  /// Owner ID:
  ///
  /// In en, this message translates to:
  /// **'Owner ID: '**
  String get settings_personal_owner_id_label;

  /// Owner:
  ///
  /// In en, this message translates to:
  /// **'Owner: '**
  String get settings_personal_owner_label;

  /// Personal Ownership
  ///
  /// In en, this message translates to:
  /// **'Personal Ownership'**
  String get settings_personal_ownership;

  /// Preferences reset
  ///
  /// In en, this message translates to:
  /// **'Preferences reset'**
  String get settings_preferences_reset_done;

  /// Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacy_policy;

  /// View Raw JSON (RAW JSON)
  ///
  /// In en, this message translates to:
  /// **'View Raw JSON (RAW JSON)'**
  String get settings_raw_json_tile;

  /// Recovery Pro
  ///
  /// In en, this message translates to:
  /// **'Recovery Pro'**
  String get settings_recovery_title;

  /// Replay onboarding
  ///
  /// In en, this message translates to:
  /// **'Replay onboarding'**
  String get settings_replay_onboarding;

  /// Reset onboarding and launch it again now.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding and launch it again now.'**
  String get settings_replay_onboarding_desc;

  /// Reset preferences
  ///
  /// In en, this message translates to:
  /// **'Reset preferences'**
  String get settings_reset_preferences;

  /// Reset theme, language and onboarding progress.
  ///
  /// In en, this message translates to:
  /// **'Reset theme, language and onboarding progress.'**
  String get settings_reset_preferences_desc;

  /// Restore This Snapshot
  ///
  /// In en, this message translates to:
  /// **'Restore This Snapshot'**
  String get settings_restore_snapshot;

  /// Run auto-backup now
  ///
  /// In en, this message translates to:
  /// **'Run auto-backup now'**
  String get settings_run_auto_backup_now;

  /// Run Diagnostics
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostics'**
  String get settings_run_diagnostics;

  /// Active Runner API: {url}
  ///
  /// In en, this message translates to:
  /// **'Active Runner API: {url}'**
  String settings_runner_active(String url);

  /// Runner rejected the API token
  ///
  /// In en, this message translates to:
  /// **'Runner rejected the API token'**
  String get settings_runner_auth_failed;

  /// Check connection
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get settings_runner_check;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_runner_clear;

  /// Runner settings cleared
  ///
  /// In en, this message translates to:
  /// **'Runner settings cleared'**
  String get settings_runner_cleared;

  /// Runner reachable ✓
  ///
  /// In en, this message translates to:
  /// **'Runner reachable ✓'**
  String get settings_runner_connected;

  /// Checking connection…
  ///
  /// In en, this message translates to:
  /// **'Checking connection…'**
  String get settings_runner_connecting;

  /// Connect the app to a Bot Creator Runner. Remote runners should stay on trusted networks and use a bearer token.
  ///
  /// In en, this message translates to:
  /// **'Connect the app to a Bot Creator Runner. Remote runners should stay on trusted networks and use a bearer token.'**
  String get settings_runner_desc;

  /// Temporarily disable Runner
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable Runner'**
  String get settings_runner_disable_temp;

  /// Keep Runner settings but force local mode until re-enabled.
  ///
  /// In en, this message translates to:
  /// **'Keep Runner settings but force local mode until re-enabled.'**
  String get settings_runner_disable_temp_desc;

  /// Runner disconnected
  ///
  /// In en, this message translates to:
  /// **'Runner disconnected'**
  String get settings_runner_disconnected;

  /// Not connected
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settings_runner_not_connected;

  /// Runner re-enabled
  ///
  /// In en, this message translates to:
  /// **'Runner re-enabled'**
  String get settings_runner_reenabled;

  /// Save settings
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settings_runner_save;

  /// Runner settings saved
  ///
  /// In en, this message translates to:
  /// **'Runner settings saved'**
  String get settings_runner_saved;

  /// Runner temporarily disabled (local mode active)
  ///
  /// In en, this message translates to:
  /// **'Runner temporarily disabled (local mode active)'**
  String get settings_runner_temporarily_disabled;

  /// Runner temporarily disabled
  ///
  /// In en, this message translates to:
  /// **'Runner temporarily disabled'**
  String get settings_runner_temporarily_disabled_saved;

  /// Runner API
  ///
  /// In en, this message translates to:
  /// **'Runner API'**
  String get settings_runner_title;

  /// Bearer token (optional on localhost)
  ///
  /// In en, this message translates to:
  /// **'Bearer token (optional on localhost)'**
  String get settings_runner_token_hint;

  /// Runner API token
  ///
  /// In en, this message translates to:
  /// **'Runner API token'**
  String get settings_runner_token_label;

  /// Runner unreachable
  ///
  /// In en, this message translates to:
  /// **'Runner unreachable'**
  String get settings_runner_unreachable;

  /// Clear
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_runner_url_clear;

  /// Runner URL cleared
  ///
  /// In en, this message translates to:
  /// **'Runner URL cleared'**
  String get settings_runner_url_cleared;

  /// http://192.168.1.x:8080
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.x:8080'**
  String get settings_runner_url_hint;

  /// Save URL
  ///
  /// In en, this message translates to:
  /// **'Save URL'**
  String get settings_runner_url_save;

  /// Runner URL saved
  ///
  /// In en, this message translates to:
  /// **'Runner URL saved'**
  String get settings_runner_url_saved;

  /// Runner
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get settings_runner_version;

  /// Apps: {count}
  ///
  /// In en, this message translates to:
  /// **'Apps: {count}'**
  String settings_snapshot_apps_count(int count);

  /// Apps in this snapshot
  ///
  /// In en, this message translates to:
  /// **'Apps in this snapshot'**
  String get settings_snapshot_apps_list;

  /// Creating snapshot…
  ///
  /// In en, this message translates to:
  /// **'Creating snapshot…'**
  String get settings_snapshot_create_loading;

  /// Created: {date}
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String settings_snapshot_created_at(String date);

  /// Snapshot created: {id}
  ///
  /// In en, this message translates to:
  /// **'Snapshot created: {id}'**
  String settings_snapshot_created_message(String id);

  /// Deleting snapshot…
  ///
  /// In en, this message translates to:
  /// **'Deleting snapshot…'**
  String get settings_snapshot_delete_loading;

  /// Snapshot deleted
  ///
  /// In en, this message translates to:
  /// **'Snapshot deleted'**
  String get settings_snapshot_deleted;

  /// Files: {count} • Size: {size}
  ///
  /// In en, this message translates to:
  /// **'Files: {count} • Size: {size}'**
  String settings_snapshot_files_size(int count, String size);

  /// ID: {id}
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String settings_snapshot_id(String id);

  /// Label: {label}
  ///
  /// In en, this message translates to:
  /// **'Label: {label}'**
  String settings_snapshot_label(String label);

  /// {date} • {count} files • {size}
  ///
  /// In en, this message translates to:
  /// **'{date} • {count} files • {size}'**
  String settings_snapshot_list_entry(String date, int count, String size);

  /// No app metadata available.
  ///
  /// In en, this message translates to:
  /// **'No app metadata available.'**
  String get settings_snapshot_no_metadata;

  /// Snapshot Preview
  ///
  /// In en, this message translates to:
  /// **'Snapshot Preview'**
  String get settings_snapshot_preview_title;

  /// Restoring snapshot…
  ///
  /// In en, this message translates to:
  /// **'Restoring snapshot…'**
  String get settings_snapshot_restore_loading;

  /// Delete all snapshots
  ///
  /// In en, this message translates to:
  /// **'Delete all snapshots'**
  String get settings_snapshots_delete_all;

  /// Permanently delete {count} snapshot(s)? This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {count} snapshot(s)? This action cannot be undone.'**
  String settings_snapshots_delete_all_confirm(int count);

  /// {count} snapshot(s) deleted.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshot(s) deleted.'**
  String settings_snapshots_delete_all_done(int count);

  /// Deleting all snapshots…
  ///
  /// In en, this message translates to:
  /// **'Deleting all snapshots…'**
  String get settings_snapshots_delete_all_loading;

  /// Delete all snapshots
  ///
  /// In en, this message translates to:
  /// **'Delete all snapshots'**
  String get settings_snapshots_delete_all_title;

  /// Permanently delete "{label}"? This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \"{label}\"? This action cannot be undone.'**
  String settings_snapshots_delete_one_confirm(String label);

  /// Select the snapshot to remove (oldest first).
  ///
  /// In en, this message translates to:
  /// **'Select the snapshot to remove (oldest first).'**
  String get settings_snapshots_delete_select_desc;

  /// Delete a snapshot
  ///
  /// In en, this message translates to:
  /// **'Delete a snapshot'**
  String get settings_snapshots_delete_select_title;

  /// Delete a selected snapshot
  ///
  /// In en, this message translates to:
  /// **'Delete a selected snapshot'**
  String get settings_snapshots_delete_select_tooltip;

  /// No snapshots found yet.
  ///
  /// In en, this message translates to:
  /// **'No snapshots found yet.'**
  String get settings_snapshots_empty;

  /// Refresh snapshots
  ///
  /// In en, this message translates to:
  /// **'Refresh snapshots'**
  String get settings_snapshots_refresh;

  /// Refreshing snapshots…
  ///
  /// In en, this message translates to:
  /// **'Refreshing snapshots…'**
  String get settings_snapshots_refresh_loading;

  /// Snapshots
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get settings_snapshots_title;

  /// SOLO
  ///
  /// In en, this message translates to:
  /// **'SOLO'**
  String get settings_solo_pill;

  /// Recommended on Android and iOS. Logs, stats, and startup all go through Bot Creator.
  ///
  /// In en, this message translates to:
  /// **'Recommended on Android and iOS. Logs, stats, and startup all go through Bot Creator.'**
  String get settings_startup_mode_cloud_desc;

  /// Choose whether your bots start on Bot Creator servers or locally on this device.
  ///
  /// In en, this message translates to:
  /// **'Choose whether your bots start on Bot Creator servers or locally on this device.'**
  String get settings_startup_mode_desc;

  /// Local mode remains unavailable on iOS.
  ///
  /// In en, this message translates to:
  /// **'Local mode remains unavailable on iOS.'**
  String get settings_startup_mode_ios_unavailable;

  /// On iOS, local mode is not supported. Bots always use Bot Creator servers.
  ///
  /// In en, this message translates to:
  /// **'On iOS, local mode is not supported. Bots always use Bot Creator servers.'**
  String get settings_startup_mode_ios_warning;

  /// Bots now start locally on this device.
  ///
  /// In en, this message translates to:
  /// **'Bots now start locally on this device.'**
  String get settings_startup_mode_local_desc;

  /// Local mode is an advanced option intended for debugging or specific needs. For normal use, keep Bot Creator servers enabled.
  ///
  /// In en, this message translates to:
  /// **'Local mode is an advanced option intended for debugging or specific needs. For normal use, keep Bot Creator servers enabled.'**
  String get settings_startup_mode_local_warning;

  /// Bot startup mode
  ///
  /// In en, this message translates to:
  /// **'Bot startup mode'**
  String get settings_startup_mode_title;

  /// Use Bot Creator servers
  ///
  /// In en, this message translates to:
  /// **'Use Bot Creator servers'**
  String get settings_startup_mode_use_cloud;

  /// This status entry will be removed. Continue?
  ///
  /// In en, this message translates to:
  /// **'This status entry will be removed. Continue?'**
  String get settings_status_remove_confirm;

  /// Settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_tab;

  /// Team ID:
  ///
  /// In en, this message translates to:
  /// **'Team ID: '**
  String get settings_team_id_label;

  /// Number of team members
  ///
  /// In en, this message translates to:
  /// **'Team Members ({count})'**
  String settings_team_members_label(int count);

  /// Team Name:
  ///
  /// In en, this message translates to:
  /// **'Team Name: '**
  String get settings_team_name_label;

  /// Team Leader
  ///
  /// In en, this message translates to:
  /// **'Team Leader'**
  String get settings_team_owner_label;

  /// Team Ownership
  ///
  /// In en, this message translates to:
  /// **'Team Ownership'**
  String get settings_team_ownership;

  /// TEAM
  ///
  /// In en, this message translates to:
  /// **'TEAM'**
  String get settings_team_pill;

  /// Switch to dark mode
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get settings_theme_switch_dark;

  /// Switch to light mode
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get settings_theme_switch_light;

  /// Version
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version_title;

  /// View startup logs
  ///
  /// In en, this message translates to:
  /// **'View startup logs'**
  String get settings_view_startup_logs;

  /// Copy diagnostics
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get startup_copy_diagnostics;

  /// Diagnostics copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard'**
  String get startup_diagnostics_copied;

  /// Startup Error
  ///
  /// In en, this message translates to:
  /// **'Startup Error'**
  String get startup_error_title;

  /// Bot Creator failed to start on this device.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator failed to start on this device.'**
  String get startup_failed_message;

  /// Refresh diagnostics
  ///
  /// In en, this message translates to:
  /// **'Refresh diagnostics'**
  String get startup_refresh_diagnostics;

  /// Premium — Annual
  ///
  /// In en, this message translates to:
  /// **'Premium — Annual'**
  String get subscription_active_annual;

  /// Active plan:
  ///
  /// In en, this message translates to:
  /// **'Active plan:'**
  String get subscription_active_label;

  /// Premium — Monthly
  ///
  /// In en, this message translates to:
  /// **'Premium — Monthly'**
  String get subscription_active_monthly;

  /// Annual
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get subscription_annual_title;

  /// Bots start instantly, no popup
  ///
  /// In en, this message translates to:
  /// **'Bots start instantly, no popup'**
  String get subscription_benefit_fast_start;

  /// No ads anywhere in the app
  ///
  /// In en, this message translates to:
  /// **'No ads anywhere in the app'**
  String get subscription_benefit_no_ads;

  /// Support independent development
  ///
  /// In en, this message translates to:
  /// **'Support independent development'**
  String get subscription_benefit_support;

  /// Purchase could not be completed. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be completed. Please try again.'**
  String get subscription_error;

  /// This plan is currently unavailable. Please try again later.
  ///
  /// In en, this message translates to:
  /// **'This plan is currently unavailable. Please try again later.'**
  String get subscription_error_product_unavailable;

  /// Purchase could not be started. Please try again.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be started. Please try again.'**
  String get subscription_error_purchase_start_failed;

  /// The App Store is currently unavailable. Please try again in a moment.
  ///
  /// In en, this message translates to:
  /// **'The App Store is currently unavailable. Please try again in a moment.'**
  String get subscription_error_store_unavailable;

  /// Access error rate, latency percentiles, and locale insights.
  ///
  /// In en, this message translates to:
  /// **'Access error rate, latency percentiles, and locale insights.'**
  String get subscription_feature_analytics_desc;

  /// Advanced analytics
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get subscription_feature_analytics_title;

  /// Restart the bot automatically when a full restart is required.
  ///
  /// In en, this message translates to:
  /// **'Restart the bot automatically when a full restart is required.'**
  String get subscription_feature_auto_restart_desc;

  /// Automatic restart
  ///
  /// In en, this message translates to:
  /// **'Automatic restart'**
  String get subscription_feature_auto_restart_title;

  /// Scale large bots by distributing load across shard workers.
  ///
  /// In en, this message translates to:
  /// **'Scale large bots by distributing load across shard workers.'**
  String get subscription_feature_auto_sharding_desc;

  /// Automatic sharding
  ///
  /// In en, this message translates to:
  /// **'Automatic sharding'**
  String get subscription_feature_auto_sharding_title;

  /// Coming soon
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get subscription_feature_coming_soon;

  /// Record and replay command actions step by step for debugging.
  ///
  /// In en, this message translates to:
  /// **'Record and replay command actions step by step for debugging.'**
  String get subscription_feature_debug_replay_desc;

  /// Visual debug replay
  ///
  /// In en, this message translates to:
  /// **'Visual debug replay'**
  String get subscription_feature_debug_replay_title;

  /// Start bots immediately without rewarded ad interruption.
  ///
  /// In en, this message translates to:
  /// **'Start bots immediately without rewarded ad interruption.'**
  String get subscription_feature_instant_start_desc;

  /// Instant start
  ///
  /// In en, this message translates to:
  /// **'Instant start'**
  String get subscription_feature_instant_start_title;

  /// Lavalink audio module description
  ///
  /// In en, this message translates to:
  /// **'Play music and audio in Discord voice channels using Lavalink.'**
  String get subscription_feature_lavalink_desc;

  /// Lavalink audio module title
  ///
  /// In en, this message translates to:
  /// **'Lavalink audio support'**
  String get subscription_feature_lavalink_title;

  /// Remove all ad placements across the app experience.
  ///
  /// In en, this message translates to:
  /// **'Remove all ad placements across the app experience.'**
  String get subscription_feature_no_ads_desc;

  /// No ads
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get subscription_feature_no_ads_title;

  /// Run workflows automatically every X minutes (up to 10 active).
  ///
  /// In en, this message translates to:
  /// **'Run workflows automatically every X minutes (up to 10 active).'**
  String get subscription_feature_scheduler_desc;

  /// Scheduler triggers
  ///
  /// In en, this message translates to:
  /// **'Scheduler triggers'**
  String get subscription_feature_scheduler_title;

  /// Create secure webhook endpoints and route calls to workflows.
  ///
  /// In en, this message translates to:
  /// **'Create secure webhook endpoints and route calls to workflows.'**
  String get subscription_feature_webhooks_desc;

  /// Inbound webhooks
  ///
  /// In en, this message translates to:
  /// **'Inbound webhooks'**
  String get subscription_feature_webhooks_title;

  /// Manage subscription
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get subscription_manage;

  /// Monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscription_monthly_title;

  /// Subscriptions are currently available on mobile only.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are currently available on mobile only.'**
  String get subscription_not_available_on_platform;

  /// per month
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subscription_per_month;

  /// per year
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get subscription_per_year;

  /// Remove ads and get access to all current and upcoming premium features.
  ///
  /// In en, this message translates to:
  /// **'Remove ads and get access to all current and upcoming premium features.'**
  String get subscription_plan_desc;

  /// Premium Basic
  ///
  /// In en, this message translates to:
  /// **'Premium Basic'**
  String get subscription_plan_label;

  /// Privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get subscription_privacy;

  /// Restore purchases
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscription_restore;

  /// No active subscription found.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get subscription_restore_not_found;

  /// Subscription restored successfully!
  ///
  /// In en, this message translates to:
  /// **'Subscription restored successfully!'**
  String get subscription_restored;

  /// SAVE 67%
  ///
  /// In en, this message translates to:
  /// **'SAVE 67%'**
  String get subscription_save_badge;

  /// Choose a plan to unlock all premium features.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to unlock all premium features.'**
  String get subscription_subtitle;

  /// Welcome to Premium! All ads have been removed.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium! All ads have been removed.'**
  String get subscription_success;

  /// Terms of use
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get subscription_terms;

  /// Premium
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscription_title;

  /// Not available on this platform.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform.'**
  String get subscription_unavailable_platform;

  /// A question, a bug, a suggestion? Come chat with the team and the community.
  ///
  /// In en, this message translates to:
  /// **'A question, a bug, a suggestion? Come chat with the team and the community.'**
  String get support_card_desc;

  /// Support & Community
  ///
  /// In en, this message translates to:
  /// **'Support & Community'**
  String get support_card_title;

  /// Official support
  ///
  /// In en, this message translates to:
  /// **'Official support'**
  String get support_discord_badge;

  /// Join the Discord server
  ///
  /// In en, this message translates to:
  /// **'Join the Discord server'**
  String get support_join_discord;

  /// Coin flip, polls, and magic 8-ball.
  ///
  /// In en, this message translates to:
  /// **'Coin flip, polls, and magic 8-ball.'**
  String get template_fun_description;

  /// Fun Bot
  ///
  /// In en, this message translates to:
  /// **'Fun Bot'**
  String get template_fun_name;

  /// Command "{name}" already exists and was skipped.
  ///
  /// In en, this message translates to:
  /// **'Command \"{name}\" already exists and was skipped.'**
  String template_gallery_already_exists(String name);

  /// Use this template
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get template_gallery_apply;

  /// Failed to apply template: {error}
  ///
  /// In en, this message translates to:
  /// **'Failed to apply template: {error}'**
  String template_gallery_apply_error(String error);

  /// {count} command(s) and {wCount} workflow(s) added from template.
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) and {wCount} workflow(s) added from template.'**
  String template_gallery_apply_success(int count, int wCount);

  /// {count} command(s)
  ///
  /// In en, this message translates to:
  /// **'{count} command(s)'**
  String template_gallery_commands_count(int count);

  /// No templates available.
  ///
  /// In en, this message translates to:
  /// **'No templates available.'**
  String get template_gallery_empty;

  /// Nothing to remove for {name}.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remove for {name}.'**
  String template_gallery_nothing_to_remove(String name);

  /// Are you sure you want to remove all commands and workflows from this template?
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all commands and workflows from this template?'**
  String get template_gallery_remove_confirm;

  /// Remove Template
  ///
  /// In en, this message translates to:
  /// **'Remove Template'**
  String get template_gallery_remove_title;

  /// Template commands and workflows removed.
  ///
  /// In en, this message translates to:
  /// **'Template commands and workflows removed.'**
  String get template_gallery_removed;

  /// Quick-start your bot with a ready-made template.
  ///
  /// In en, this message translates to:
  /// **'Quick-start your bot with a ready-made template.'**
  String get template_gallery_subtitle;

  /// Commands saved locally. Start your bot to register them on Discord.
  ///
  /// In en, this message translates to:
  /// **'Commands saved locally. Start your bot to register them on Discord.'**
  String get template_gallery_sync_warning;

  /// Templates
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get template_gallery_title;

  /// {count} workflow(s)
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s)'**
  String template_gallery_workflows_count(int count);

  /// Ban, kick, mute members and clear messages.
  ///
  /// In en, this message translates to:
  /// **'Ban, kick, mute members and clear messages.'**
  String get template_moderation_description;

  /// Moderation Bot
  ///
  /// In en, this message translates to:
  /// **'Moderation Bot'**
  String get template_moderation_name;

  /// Ping, avatar lookup, and bot-says commands.
  ///
  /// In en, this message translates to:
  /// **'Ping, avatar lookup, and bot-says commands.'**
  String get template_utility_description;

  /// Utility Bot
  ///
  /// In en, this message translates to:
  /// **'Utility Bot'**
  String get template_utility_name;

  /// Greet new members, say hello, and show server info.
  ///
  /// In en, this message translates to:
  /// **'Greet new members, say hello, and show server info.'**
  String get template_welcome_description;

  /// Welcome Bot
  ///
  /// In en, this message translates to:
  /// **'Welcome Bot'**
  String get template_welcome_name;

  /// {count, plural, =0{0 days} =1{1 day} other{{count} days}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 days} =1{1 day} other{{count} days}}'**
  String unit_day(int count);

  /// {count, plural, =0{0 hours} =1{1 hour} other{{count} hours}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 hours} =1{1 hour} other{{count} hours}}'**
  String unit_hour(int count);

  /// {count, plural, =0{0 minutes} =1{1 minute} other{{count} minutes}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 minutes} =1{1 minute} other{{count} minutes}}'**
  String unit_minute(int count);

  /// {count, plural, =0{0 months} =1{1 month} other{{count} months}}
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 months} =1{1 month} other{{count} months}}'**
  String unit_month(int count);

  /// Awaited callback must use $awaitedCommand[name;filter] or $awaitedCommandError[name].
  ///
  /// In en, this message translates to:
  /// **'Awaited callback must use \$awaitedCommand[name;filter] or \$awaitedCommandError[name].'**
  String get validation_awaited_callback_format;

  /// Awaited callback trigger must be at most {max} characters long
  ///
  /// In en, this message translates to:
  /// **'Awaited callback trigger must be at most {max} characters long'**
  String validation_awaited_callback_length(int max);

  /// Awaited callbacks require a local-only Legacy Command.
  ///
  /// In en, this message translates to:
  /// **'Awaited callbacks require a local-only Legacy Command.'**
  String get validation_awaited_callback_local_only;

  /// Command name can only contain letters, numbers, and underscores
  ///
  /// In en, this message translates to:
  /// **'Command name can only contain letters, numbers, and underscores'**
  String get validation_command_name_invalid_chars;

  /// Command name must be at most {max} characters long
  ///
  /// In en, this message translates to:
  /// **'Command name must be at most {max} characters long'**
  String validation_command_name_length(int max);

  /// Command name cannot start with an ampersand
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an ampersand'**
  String get validation_command_name_no_ampersand;

  /// Command name cannot start with an at sign
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an at sign'**
  String get validation_command_name_no_at;

  /// Command name cannot start with an exclamation mark
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an exclamation mark'**
  String get validation_command_name_no_exclamation;

  /// Command name cannot start with a hash
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a hash'**
  String get validation_command_name_no_hash;

  /// Command name cannot start with a percent sign
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a percent sign'**
  String get validation_command_name_no_percent;

  /// Command name cannot start with a slash
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a slash'**
  String get validation_command_name_no_slash;

  /// Command name cannot contain spaces
  ///
  /// In en, this message translates to:
  /// **'Command name cannot contain spaces'**
  String get validation_command_name_no_spaces;

  /// Command name cannot start with an underscore
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an underscore'**
  String get validation_command_name_no_underscore;

  /// Please enter a command name
  ///
  /// In en, this message translates to:
  /// **'Please enter a command name'**
  String get validation_command_name_required;

  /// Interaction commands must include at least one response action (Respond with Message, Component V2, or Modal).
  ///
  /// In en, this message translates to:
  /// **'Interaction commands must include at least one response action (Respond with Message, Component V2, or Modal).'**
  String get validation_interaction_no_response;

  /// Short version: no response action
  ///
  /// In en, this message translates to:
  /// **'No response action'**
  String get validation_interaction_no_response_short;

  /// Invalid default member permissions bitfield. Use a positive integer or leave empty.
  ///
  /// In en, this message translates to:
  /// **'Invalid default member permissions bitfield. Use a positive integer or leave empty.'**
  String get validation_invalid_permissions;

  /// Legacy mode is only available for chat input commands.
  ///
  /// In en, this message translates to:
  /// **'Legacy mode is only available for chat input commands.'**
  String get validation_legacy_chat_input_only;

  /// Legacy-only mode can only be used for new commands or existing local commands.
  ///
  /// In en, this message translates to:
  /// **'Legacy-only mode can only be used for new commands or existing local commands.'**
  String get validation_legacy_only_new_or_local;

  /// Legacy-only commands require legacy mode to be enabled.
  ///
  /// In en, this message translates to:
  /// **'Legacy-only commands require legacy mode to be enabled.'**
  String get validation_legacy_only_requires_legacy;

  /// Modal responses are not supported in legacy command mode.
  ///
  /// In en, this message translates to:
  /// **'Modal responses are not supported in legacy command mode.'**
  String get validation_modal_not_legacy;

  /// Every option must have a description.
  ///
  /// In en, this message translates to:
  /// **'Every option must have a description.'**
  String get validation_option_description_required;

  /// A SubCommandGroup can only contain SubCommand options.
  ///
  /// In en, this message translates to:
  /// **'A SubCommandGroup can only contain SubCommand options.'**
  String get validation_option_group_only_subcommands;

  /// SubCommandGroup is only allowed at the top level.
  ///
  /// In en, this message translates to:
  /// **'SubCommandGroup is only allowed at the top level.'**
  String get validation_option_group_top_level_only;

  /// SubCommand and SubCommandGroup cannot define choices.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot define choices.'**
  String get validation_option_hierarchy_no_choices;

  /// SubCommand and SubCommandGroup cannot define min/max values.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot define min/max values.'**
  String get validation_option_hierarchy_no_min_max;

  /// SubCommand and SubCommandGroup cannot be marked as required.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot be marked as required.'**
  String get validation_option_hierarchy_not_required;

  /// Regular options cannot contain nested options.
  ///
  /// In en, this message translates to:
  /// **'Regular options cannot contain nested options.'**
  String get validation_option_leaf_no_nested;

  /// Each option level supports at most 25 entries.
  ///
  /// In en, this message translates to:
  /// **'Each option level supports at most 25 entries.'**
  String get validation_option_max_entries;

  /// Duplicate option name "{name}" at the same level.
  ///
  /// In en, this message translates to:
  /// **'Duplicate option name \"{name}\" at the same level.'**
  String validation_option_name_duplicate(String name);

  /// Every option must have a name.
  ///
  /// In en, this message translates to:
  /// **'Every option must have a name.'**
  String get validation_option_name_required;

  /// Top-level options cannot mix subcommands/groups with regular options.
  ///
  /// In en, this message translates to:
  /// **'Top-level options cannot mix subcommands/groups with regular options.'**
  String get validation_option_no_mix_top_level;

  /// SubCommand nesting depth exceeds Discord limits.
  ///
  /// In en, this message translates to:
  /// **'SubCommand nesting depth exceeds Discord limits.'**
  String get validation_option_subcommand_depth;

  /// A SubCommand cannot contain nested SubCommand or SubCommandGroup.
  ///
  /// In en, this message translates to:
  /// **'A SubCommand cannot contain nested SubCommand or SubCommandGroup.'**
  String get validation_option_subcommand_no_nested;

  /// Dynamic numeric suggestions
  ///
  /// In en, this message translates to:
  /// **'Dynamic numeric suggestions'**
  String get variable_autocomplete_numeric_title;

  /// Available variables — tap to insert
  ///
  /// In en, this message translates to:
  /// **'Available variables — tap to insert'**
  String get variable_autocomplete_title;

  /// Author
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get variable_category_author;

  /// Bot
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get variable_category_bot;

  /// Channel
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get variable_category_channel;

  /// Context
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get variable_category_context;

  /// Functions
  ///
  /// In en, this message translates to:
  /// **'Functions'**
  String get variable_category_functions;

  /// Server
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get variable_category_guild;

  /// Interaction
  ///
  /// In en, this message translates to:
  /// **'Interaction'**
  String get variable_category_interaction;

  /// Member
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get variable_category_member;

  /// Message
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get variable_category_message;

  /// Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get variable_category_other;

  /// Temporary
  ///
  /// In en, this message translates to:
  /// **'Temporary'**
  String get variable_category_temp;

  /// User
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get variable_category_user;

  /// Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get webhooks_actions;

  /// Add webhook
  ///
  /// In en, this message translates to:
  /// **'Add webhook'**
  String get webhooks_add_action;

  /// Add inbound webhook
  ///
  /// In en, this message translates to:
  /// **'Add inbound webhook'**
  String get webhooks_add_title;

  /// Full webhook URL copied.
  ///
  /// In en, this message translates to:
  /// **'Full webhook URL copied.'**
  String get webhooks_copied;

  /// Copy path
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get webhooks_copy_path;

  /// Copy secret
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get webhooks_copy_secret;

  /// Copy URL
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get webhooks_copy_url;

  /// Webhooks: {count}{limit}
  ///
  /// In en, this message translates to:
  /// **'Webhooks: {count}{limit}'**
  String webhooks_count(int count, String limit);

  /// Delete "{label}"? This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\"? This cannot be undone.'**
  String webhooks_delete_confirm(String label);

  /// This cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get webhooks_delete_confirm_no_label;

  /// Delete inbound webhook?
  ///
  /// In en, this message translates to:
  /// **'Delete inbound webhook?'**
  String get webhooks_delete_title;

  /// Edit inbound webhook
  ///
  /// In en, this message translates to:
  /// **'Edit inbound webhook'**
  String get webhooks_edit_title;

  /// No inbound webhooks yet.
  ///
  /// In en, this message translates to:
  /// **'No inbound webhooks yet.'**
  String get webhooks_empty;

  /// Generate
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get webhooks_generate;

  /// Runner URL is invalid.
  ///
  /// In en, this message translates to:
  /// **'Runner URL is invalid.'**
  String get webhooks_invalid_runner_url;

  /// Inbound webhook limit reached ({limit}).
  ///
  /// In en, this message translates to:
  /// **'Inbound webhook limit reached ({limit}).'**
  String webhooks_limit_reached(int limit);

  /// Webhook path or secret is missing.
  ///
  /// In en, this message translates to:
  /// **'Webhook path or secret is missing.'**
  String get webhooks_missing_data;

  /// Create at least one workflow before adding an inbound webhook.
  ///
  /// In en, this message translates to:
  /// **'Create at least one workflow before adding an inbound webhook.'**
  String get webhooks_no_workflows;

  /// Inbound Webhooks
  ///
  /// In en, this message translates to:
  /// **'Inbound Webhooks'**
  String get webhooks_page_title;

  /// Path copied.
  ///
  /// In en, this message translates to:
  /// **'Path copied.'**
  String get webhooks_path_copied;

  /// This path already exists. Choose another one.
  ///
  /// In en, this message translates to:
  /// **'This path already exists. Choose another one.'**
  String get webhooks_path_exists;

  /// orders/new
  ///
  /// In en, this message translates to:
  /// **'orders/new'**
  String get webhooks_path_hint;

  /// Path
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get webhooks_path_label;

  /// Configure a Runner URL first to copy the full webhook URL.
  ///
  /// In en, this message translates to:
  /// **'Configure a Runner URL first to copy the full webhook URL.'**
  String get webhooks_runner_url_required;

  /// Failed to save inbound webhook: {error}
  ///
  /// In en, this message translates to:
  /// **'Failed to save inbound webhook: {error}'**
  String webhooks_save_failed(String error);

  /// Secret copied.
  ///
  /// In en, this message translates to:
  /// **'Secret copied.'**
  String get webhooks_secret_copied;

  /// Webhook secret
  ///
  /// In en, this message translates to:
  /// **'Webhook secret'**
  String get webhooks_secret_label;

  /// Workflow target
  ///
  /// In en, this message translates to:
  /// **'Workflow target'**
  String get webhooks_target_label;

  /// Workflow: {workflow}
  ///
  /// In en, this message translates to:
  /// **'Workflow: {workflow}'**
  String webhooks_workflow_subtitle(String workflow);

  /// Advanced trigger settings
  ///
  /// In en, this message translates to:
  /// **'Advanced trigger settings'**
  String get wizard_advanced_trigger;

  /// Apply quick start to draft
  ///
  /// In en, this message translates to:
  /// **'Apply quick start to draft'**
  String get wizard_apply_quick_start;

  /// BDFD script mode enabled
  ///
  /// In en, this message translates to:
  /// **'BDFD script mode enabled'**
  String get wizard_bdfd_mode_enabled;

  /// Code / Advanced
  ///
  /// In en, this message translates to:
  /// **'Code / Advanced'**
  String get wizard_code_advanced;

  /// Command body
  ///
  /// In en, this message translates to:
  /// **'Command body'**
  String get wizard_command_body;

  /// Create command
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get wizard_create_command;

  /// Dart script mode enabled
  ///
  /// In en, this message translates to:
  /// **'Dart script mode enabled'**
  String get wizard_dart_mode_enabled;

  /// Edit reply details
  ///
  /// In en, this message translates to:
  /// **'Edit reply details'**
  String get wizard_edit_reply;

  /// Legacy command options and local-only behavior
  ///
  /// In en, this message translates to:
  /// **'Legacy command options and local-only behavior'**
  String get wizard_legacy_options_subtitle;

  /// Quick start applied to the command draft.
  ///
  /// In en, this message translates to:
  /// **'Quick start applied to the command draft.'**
  String get wizard_quick_start_applied;

  /// Use the legacy simple builder as a starting point, then apply it to the shared draft.
  ///
  /// In en, this message translates to:
  /// **'Use the legacy simple builder as a starting point, then apply it to the shared draft.'**
  String get wizard_quick_start_subtitle;

  /// Quick starts
  ///
  /// In en, this message translates to:
  /// **'Quick starts'**
  String get wizard_quick_starts;

  /// Reply summary
  ///
  /// In en, this message translates to:
  /// **'Reply summary'**
  String get wizard_reply_summary;

  /// Save command
  ///
  /// In en, this message translates to:
  /// **'Save command'**
  String get wizard_save_command;

  /// Actions
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get wizard_step_actions;

  /// Infos
  ///
  /// In en, this message translates to:
  /// **'Infos'**
  String get wizard_step_infos;

  /// Reply
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get wizard_step_reply;

  /// Review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get wizard_step_review;

  /// Trigger & Inputs
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get wizard_step_trigger_inputs;

  /// Visual workflow mode enabled
  ///
  /// In en, this message translates to:
  /// **'Visual workflow mode enabled'**
  String get wizard_visual_mode_enabled;

  /// Workflow argument (accessible via $arg)
  ///
  /// In en, this message translates to:
  /// **'Workflow argument (accessible via \$arg)'**
  String get workflow_argument_hint;

  /// Workflow Arguments
  ///
  /// In en, this message translates to:
  /// **'Workflow Arguments'**
  String get workflow_arguments_section;

  /// Auto defer
  ///
  /// In en, this message translates to:
  /// **'Auto defer'**
  String get workflow_auto_defer;

  /// Auto defer if actions
  ///
  /// In en, this message translates to:
  /// **'Auto defer if actions'**
  String get workflow_auto_defer_actions;

  /// Write the complete BDFD code for this workflow response. Diagnostics are displayed live.
  ///
  /// In en, this message translates to:
  /// **'Write the complete BDFD code for this workflow response. Diagnostics are displayed live.'**
  String get workflow_bdfd_editor_desc;

  /// BDFD Script Editor
  ///
  /// In en, this message translates to:
  /// **'BDFD Script Editor'**
  String get workflow_bdfd_editor_title;

  /// Condition off
  ///
  /// In en, this message translates to:
  /// **'Condition off'**
  String get workflow_condition_off;

  /// Condition OFF
  ///
  /// In en, this message translates to:
  /// **'Condition OFF'**
  String get workflow_condition_off_upper;

  /// Condition on
  ///
  /// In en, this message translates to:
  /// **'Condition on'**
  String get workflow_condition_on;

  /// Condition ON
  ///
  /// In en, this message translates to:
  /// **'Condition ON'**
  String get workflow_condition_on_upper;

  /// Write full Dart code for this workflow response. Diagnostics are displayed live.
  ///
  /// In en, this message translates to:
  /// **'Write full Dart code for this workflow response. Diagnostics are displayed live.'**
  String get workflow_dart_editor_desc;

  /// Dart Script Editor
  ///
  /// In en, this message translates to:
  /// **'Dart Script Editor'**
  String get workflow_dart_editor_title;

  /// Edit Call Arguments ({count})
  ///
  /// In en, this message translates to:
  /// **'Edit Call Arguments ({count})'**
  String workflow_edit_call_args(int count);

  /// Entry Point
  ///
  /// In en, this message translates to:
  /// **'Entry Point'**
  String get workflow_entry_point;

  /// Defaults to workflow entry point when empty
  ///
  /// In en, this message translates to:
  /// **'Defaults to workflow entry point when empty'**
  String get workflow_entry_point_helper;

  /// Entry Point (optional)
  ///
  /// In en, this message translates to:
  /// **'Entry Point (optional)'**
  String get workflow_entry_point_optional;

  /// e.g. handle_form_submit
  ///
  /// In en, this message translates to:
  /// **'e.g. handle_form_submit'**
  String get workflow_hint_name;

  /// Manual
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get workflow_manual;

  /// BDFD Script
  ///
  /// In en, this message translates to:
  /// **'BDFD Script'**
  String get workflow_mode_bdfd;

  /// Write your entire workflow as a single BDFD script. The script is compiled and validated in real time.
  ///
  /// In en, this message translates to:
  /// **'Write your entire workflow as a single BDFD script. The script is compiled and validated in real time.'**
  String get workflow_mode_bdfd_note;

  /// Dart Direct
  ///
  /// In en, this message translates to:
  /// **'Dart Direct'**
  String get workflow_mode_dart;

  /// Write your workflow in Dart. Diagnostics are updated while editing to catch errors early.
  ///
  /// In en, this message translates to:
  /// **'Write your workflow in Dart. Diagnostics are updated while editing to catch errors early.'**
  String get workflow_mode_dart_note;

  /// Choose between a visual action builder or a full BDFD scripting editor.
  ///
  /// In en, this message translates to:
  /// **'Choose between a visual action builder or a full BDFD scripting editor.'**
  String get workflow_mode_desc;

  /// Workflow mode
  ///
  /// In en, this message translates to:
  /// **'Workflow mode'**
  String get workflow_mode_title;

  /// Visual
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get workflow_mode_visual;

  /// Build your workflow visually by adding individual actions with the card editor.
  ///
  /// In en, this message translates to:
  /// **'Build your workflow visually by adding individual actions with the card editor.'**
  String get workflow_mode_visual_note;

  /// No auto defer
  ///
  /// In en, this message translates to:
  /// **'No auto defer'**
  String get workflow_no_auto_defer;

  /// Note: If no workflow is selected, submitting this modal will do nothing.
  ///
  /// In en, this message translates to:
  /// **'Note: If no workflow is selected, submitting this modal will do nothing.'**
  String get workflow_no_workflow_note;

  /// On submit, workflow "{name}" will run (entry: {entry}, args: {args}).
  ///
  /// In en, this message translates to:
  /// **'On submit, workflow \"{name}\" will run (entry: {entry}, args: {args}).'**
  String workflow_on_submit_info(String name, String entry, int args);

  /// Root must be a JSON object
  ///
  /// In en, this message translates to:
  /// **'Root must be a JSON object'**
  String get workflow_root_json_error;

  /// Workflow "{name}" saved ({count} action(s)).
  ///
  /// In en, this message translates to:
  /// **'Workflow \"{name}\" saved ({count} action(s)).'**
  String workflow_saved_snackbar(String name, int count);

  /// Set Call Arguments
  ///
  /// In en, this message translates to:
  /// **'Set Call Arguments'**
  String get workflow_set_call_args;

  /// Ephemeral
  ///
  /// In en, this message translates to:
  /// **'Ephemeral'**
  String get workflow_visibility_ephemeral;

  /// Public
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get workflow_visibility_public;

  /// Add argument
  ///
  /// In en, this message translates to:
  /// **'Add argument'**
  String get workflows_add_arg;

  /// Default value
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get workflows_arg_default;

  /// Arguments become runtime variables as ((arg.name)) and ((workflow.arg.name)).
  ///
  /// In en, this message translates to:
  /// **'Arguments become runtime variables as ((arg.name)) and ((workflow.arg.name)).'**
  String get workflows_arg_hint;

  /// Name
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workflows_arg_name;

  /// Req
  ///
  /// In en, this message translates to:
  /// **'Req'**
  String get workflows_arg_required_short;

  /// Arguments
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get workflows_arguments;

  /// Continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get workflows_continue;

  /// Workflows copied as Base64.
  ///
  /// In en, this message translates to:
  /// **'Workflows copied as Base64.'**
  String get workflows_copy_done_base64;

  /// Workflows copied as JSON.
  ///
  /// In en, this message translates to:
  /// **'Workflows copied as JSON.'**
  String get workflows_copy_done_json;

  /// No workflows to copy.
  ///
  /// In en, this message translates to:
  /// **'No workflows to copy.'**
  String get workflows_copy_none;

  /// Create Workflow
  ///
  /// In en, this message translates to:
  /// **'Create Workflow'**
  String get workflows_create;

  /// Are you sure you want to delete "{name}"? This action cannot be undone.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String workflows_delete_confirm(String name);

  /// Delete workflow
  ///
  /// In en, this message translates to:
  /// **'Delete workflow'**
  String get workflows_delete_title;

  /// Open documentation center
  ///
  /// In en, this message translates to:
  /// **'Open documentation center'**
  String get workflows_docs_tooltip;

  /// Edit Workflow
  ///
  /// In en, this message translates to:
  /// **'Edit Workflow'**
  String get workflows_edit;

  /// No workflows yet
  ///
  /// In en, this message translates to:
  /// **'No workflows yet'**
  String get workflows_empty;

  /// Default Entry Point
  ///
  /// In en, this message translates to:
  /// **'Default Entry Point'**
  String get workflows_entry_point;

  /// Used if caller does not override it
  ///
  /// In en, this message translates to:
  /// **'Used if caller does not override it'**
  String get workflows_entry_point_hint;

  /// Available variables
  ///
  /// In en, this message translates to:
  /// **'Available variables'**
  String get workflows_event_available_vars;

  /// Event category
  ///
  /// In en, this message translates to:
  /// **'Event category'**
  String get workflows_event_category;

  /// Channels
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get workflows_event_category_channels;

  /// Invites
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get workflows_event_category_invites;

  /// Members
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get workflows_event_category_members;

  /// Messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get workflows_event_category_messages;

  /// Channel Update
  ///
  /// In en, this message translates to:
  /// **'Channel Update'**
  String get workflows_event_channel_update;

  /// Triggered whenever a channel is updated.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a channel is updated.'**
  String get workflows_event_channel_update_desc;

  /// Choose the Discord event that should trigger this workflow.
  ///
  /// In en, this message translates to:
  /// **'Choose the Discord event that should trigger this workflow.'**
  String get workflows_event_hint;

  /// Invite Create
  ///
  /// In en, this message translates to:
  /// **'Invite Create'**
  String get workflows_event_invite_create;

  /// Triggered whenever an invite is created.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever an invite is created.'**
  String get workflows_event_invite_create_desc;

  /// Member Join
  ///
  /// In en, this message translates to:
  /// **'Member Join'**
  String get workflows_event_member_join;

  /// Triggered whenever a member joins the guild.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a member joins the guild.'**
  String get workflows_event_member_join_desc;

  /// Member Remove
  ///
  /// In en, this message translates to:
  /// **'Member Remove'**
  String get workflows_event_member_remove;

  /// Triggered whenever a member leaves or is removed from the guild.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a member leaves or is removed from the guild.'**
  String get workflows_event_member_remove_desc;

  /// Message Create
  ///
  /// In en, this message translates to:
  /// **'Message Create'**
  String get workflows_event_message_create;

  /// Triggered whenever a new message is created.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a new message is created.'**
  String get workflows_event_message_create_desc;

  /// Message Delete
  ///
  /// In en, this message translates to:
  /// **'Message Delete'**
  String get workflows_event_message_delete;

  /// Triggered whenever a message is deleted.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a message is deleted.'**
  String get workflows_event_message_delete_desc;

  /// Message Update
  ///
  /// In en, this message translates to:
  /// **'Message Update'**
  String get workflows_event_message_update;

  /// Triggered whenever an existing message is edited.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever an existing message is edited.'**
  String get workflows_event_message_update_desc;

  /// Listen for: {event}
  ///
  /// In en, this message translates to:
  /// **'Listen for: {event}'**
  String workflows_event_preview(String event);

  /// Event Workflows
  ///
  /// In en, this message translates to:
  /// **'Event Workflows'**
  String get workflows_event_section;

  /// {count} action(s) • Listen for: {event}
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) • Listen for: {event}'**
  String workflows_event_subtitle(int count, String event);

  /// Copy as Base64
  ///
  /// In en, this message translates to:
  /// **'Copy as Base64'**
  String get workflows_export_base64;

  /// Convenient for compact sharing.
  ///
  /// In en, this message translates to:
  /// **'Convenient for compact sharing.'**
  String get workflows_export_base64_desc;

  /// Copy as JSON
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get workflows_export_json;

  /// Readable and easy to edit.
  ///
  /// In en, this message translates to:
  /// **'Readable and easy to edit.'**
  String get workflows_export_json_desc;

  /// Copy workflows
  ///
  /// In en, this message translates to:
  /// **'Copy workflows'**
  String get workflows_export_tooltip;

  /// Optional folder name
  ///
  /// In en, this message translates to:
  /// **'Optional folder name'**
  String get workflows_folder_hint;

  /// Folder
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get workflows_folder_label;

  /// General Workflows
  ///
  /// In en, this message translates to:
  /// **'General Workflows'**
  String get workflows_general_section;

  /// Import
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get workflows_import_action;

  /// Paste a JSON payload or Base64(JSON) exported from Bot Creator.
  ///
  /// In en, this message translates to:
  /// **'Paste a JSON payload or Base64(JSON) exported from Bot Creator.'**
  String get workflows_import_desc;

  /// {count} workflow(s) imported.
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) imported.'**
  String workflows_import_done(int count);

  /// No data to import.
  ///
  /// In en, this message translates to:
  /// **'No data to import.'**
  String get workflows_import_empty;

  /// Paste the JSON or Base64 here...
  ///
  /// In en, this message translates to:
  /// **'Paste the JSON or Base64 here...'**
  String get workflows_import_input_hint;

  /// Invalid format. Use JSON or Base64(JSON).
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Use JSON or Base64(JSON).'**
  String get workflows_import_invalid_format;

  /// No valid workflow found.
  ///
  /// In en, this message translates to:
  /// **'No valid workflow found.'**
  String get workflows_import_no_valid;

  /// Replace when the name already exists
  ///
  /// In en, this message translates to:
  /// **'Replace when the name already exists'**
  String get workflows_import_overwrite;

  /// Import workflows
  ///
  /// In en, this message translates to:
  /// **'Import workflows'**
  String get workflows_import_title;

  /// Import workflows
  ///
  /// In en, this message translates to:
  /// **'Import workflows'**
  String get workflows_import_tooltip;

  /// Listen for
  ///
  /// In en, this message translates to:
  /// **'Listen for'**
  String get workflows_listen_for;

  /// Move to folder
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get workflows_move_to_folder;

  /// Workflow Name
  ///
  /// In en, this message translates to:
  /// **'Workflow Name'**
  String get workflows_name;

  /// New folder name
  ///
  /// In en, this message translates to:
  /// **'New folder name'**
  String get workflows_new_folder_hint;

  /// No workflows match the current filters.
  ///
  /// In en, this message translates to:
  /// **'No workflows match the current filters.'**
  String get workflows_no_match;

  /// No workflows match the current filters.
  ///
  /// In en, this message translates to:
  /// **'No workflows match the current filters.'**
  String get workflows_no_matches;

  /// Remove from folder
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get workflows_remove_from_folder;

  /// Search workflows...
  ///
  /// In en, this message translates to:
  /// **'Search workflows...'**
  String get workflows_search_hint;

  /// {count} action(s) • entry: {entry} • args: {args}
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) • entry: {entry} • args: {args}'**
  String workflows_subtitle(int count, String entry, String args);

  /// Workflows
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows_tab;

  /// Flow
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get workflows_tab_short;

  /// Workflows
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows_title;

  /// Event
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get workflows_type_badge_event;

  /// General
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get workflows_type_badge_general;

  /// Event workflow
  ///
  /// In en, this message translates to:
  /// **'Event workflow'**
  String get workflows_type_event;

  /// Automatically reacts when Discord emits an event.
  ///
  /// In en, this message translates to:
  /// **'Automatically reacts when Discord emits an event.'**
  String get workflows_type_event_desc;

  /// General workflow
  ///
  /// In en, this message translates to:
  /// **'General workflow'**
  String get workflows_type_general;

  /// Reusable logic called from commands, buttons, modals, or other workflows.
  ///
  /// In en, this message translates to:
  /// **'Reusable logic called from commands, buttons, modals, or other workflows.'**
  String get workflows_type_general_desc;

  /// Workflow type
  ///
  /// In en, this message translates to:
  /// **'Workflow type'**
  String get workflows_type_title;

  /// No description provided for @settings_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Synchronization'**
  String get settings_sync_title;

  /// No description provided for @settings_sync_force_title.
  ///
  /// In en, this message translates to:
  /// **'Force Sync Commands'**
  String get settings_sync_force_title;

  /// No description provided for @settings_sync_force_desc.
  ///
  /// In en, this message translates to:
  /// **'Deletes all Discord slash commands that are not defined locally in Bot Creator.'**
  String get settings_sync_force_desc;

  /// No description provided for @settings_sync_force_button.
  ///
  /// In en, this message translates to:
  /// **'Sync with Discord'**
  String get settings_sync_force_button;

  /// No description provided for @settings_sync_force_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Force Sync Commands'**
  String get settings_sync_force_dialog_title;

  /// No description provided for @settings_sync_force_dialog_desc.
  ///
  /// In en, this message translates to:
  /// **'This will delete all slash commands on Discord that are not defined locally in Bot Creator. Are you sure you want to continue?'**
  String get settings_sync_force_dialog_desc;

  /// No description provided for @settings_sync_force_dialog_confirm.
  ///
  /// In en, this message translates to:
  /// **'Force Sync'**
  String get settings_sync_force_dialog_confirm;

  /// No description provided for @settings_sync_force_success.
  ///
  /// In en, this message translates to:
  /// **'Force sync completed successfully. Deleted {count} legacy/untracked command(s) from Discord.'**
  String settings_sync_force_success(Object count);

  /// No description provided for @settings_sync_force_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to force sync: {error}'**
  String settings_sync_force_error(Object error);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
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
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
