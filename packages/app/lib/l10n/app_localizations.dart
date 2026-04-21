import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator'**
  String get app_title;

  /// No description provided for @onboarding_welcome_title.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Bot Creator'**
  String get onboarding_welcome_title;

  /// No description provided for @onboarding_welcome_desc.
  ///
  /// In en, this message translates to:
  /// **'Create your first Discord bot in 3 simple steps. We\'ll guide you through each step.'**
  String get onboarding_welcome_desc;

  /// No description provided for @onboarding_welcome_start.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_welcome_start;

  /// No description provided for @onboarding_welcome_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_welcome_skip;

  /// No description provided for @onboarding_create_title.
  ///
  /// In en, this message translates to:
  /// **'Step 1: Create a Bot'**
  String get onboarding_create_title;

  /// No description provided for @onboarding_create_desc.
  ///
  /// In en, this message translates to:
  /// **'Get your Discord token'**
  String get onboarding_create_desc;

  /// No description provided for @onboarding_create_steps.
  ///
  /// In en, this message translates to:
  /// **'1. Go to Discord Developer Portal\n2. Create a new app\n3. Copy the bot token\n4. Paste it below'**
  String get onboarding_create_steps;

  /// No description provided for @onboarding_create_tip.
  ///
  /// In en, this message translates to:
  /// **'💡 Tip: Never share your token! It gives full access to your bot.'**
  String get onboarding_create_tip;

  /// No description provided for @onboarding_create_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Tutorial: How to get a token'**
  String get onboarding_create_tutorial;

  /// No description provided for @onboarding_create_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_create_button;

  /// No description provided for @onboarding_command_title.
  ///
  /// In en, this message translates to:
  /// **'Step 2: Add a Command'**
  String get onboarding_command_title;

  /// No description provided for @onboarding_command_desc.
  ///
  /// In en, this message translates to:
  /// **'Create your first command'**
  String get onboarding_command_desc;

  /// No description provided for @onboarding_command_text.
  ///
  /// In en, this message translates to:
  /// **'Commands are the heart of your bot. They allow users to interact with your bot via Discord.'**
  String get onboarding_command_text;

  /// No description provided for @onboarding_command_example.
  ///
  /// In en, this message translates to:
  /// **'Example:\n/hello → Bot replies \"Hello! 👋\"'**
  String get onboarding_command_example;

  /// No description provided for @onboarding_command_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_command_button;

  /// No description provided for @onboarding_start_title.
  ///
  /// In en, this message translates to:
  /// **'Step 3: Start the Bot'**
  String get onboarding_start_title;

  /// No description provided for @onboarding_start_desc.
  ///
  /// In en, this message translates to:
  /// **'Launch your bot!'**
  String get onboarding_start_desc;

  /// No description provided for @onboarding_start_text.
  ///
  /// In en, this message translates to:
  /// **'Click the \"Start\" button on your bot card. Then test your command in Discord!'**
  String get onboarding_start_text;

  /// No description provided for @onboarding_start_tip.
  ///
  /// In en, this message translates to:
  /// **'✨ Great! You\'ve created your first Discord bot. You can now add more commands and customize it!'**
  String get onboarding_start_tip;

  /// No description provided for @onboarding_start_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboarding_start_button;

  /// No description provided for @onboarding_success_title.
  ///
  /// In en, this message translates to:
  /// **'Congratulations! 🎉'**
  String get onboarding_success_title;

  /// No description provided for @onboarding_success_desc.
  ///
  /// In en, this message translates to:
  /// **'Your Discord bot is ready to go!'**
  String get onboarding_success_desc;

  /// No description provided for @onboarding_success_whatsnext.
  ///
  /// In en, this message translates to:
  /// **'What\'s next?'**
  String get onboarding_success_whatsnext;

  /// No description provided for @onboarding_success_tip1.
  ///
  /// In en, this message translates to:
  /// **'Add more commands'**
  String get onboarding_success_tip1;

  /// No description provided for @onboarding_success_tip2.
  ///
  /// In en, this message translates to:
  /// **'Create workflows'**
  String get onboarding_success_tip2;

  /// No description provided for @onboarding_success_tip3.
  ///
  /// In en, this message translates to:
  /// **'Backup your data'**
  String get onboarding_success_tip3;

  /// No description provided for @onboarding_success_button.
  ///
  /// In en, this message translates to:
  /// **'Start!'**
  String get onboarding_success_button;

  /// No description provided for @app_create_new.
  ///
  /// In en, this message translates to:
  /// **'Create a new App'**
  String get app_create_new;

  /// No description provided for @app_create_page_title.
  ///
  /// In en, this message translates to:
  /// **'Create a bot'**
  String get app_create_page_title;

  /// No description provided for @app_create_hero_title.
  ///
  /// In en, this message translates to:
  /// **'Connect your Discord bot'**
  String get app_create_hero_title;

  /// No description provided for @app_create_hero_desc.
  ///
  /// In en, this message translates to:
  /// **'A guided setup to open the right pages, copy your token and import the bot safely.'**
  String get app_create_hero_desc;

  /// No description provided for @app_resources_title.
  ///
  /// In en, this message translates to:
  /// **'Guided setup'**
  String get app_resources_title;

  /// No description provided for @app_resources_desc.
  ///
  /// In en, this message translates to:
  /// **'These actions open the official pages you need before saving your bot here.'**
  String get app_resources_desc;

  /// No description provided for @app_open_discord_portal.
  ///
  /// In en, this message translates to:
  /// **'Open Discord Developer Portal'**
  String get app_open_discord_portal;

  /// No description provided for @app_open_discord_portal_desc.
  ///
  /// In en, this message translates to:
  /// **'Create your application and enable the bot section.'**
  String get app_open_discord_portal_desc;

  /// No description provided for @app_open_token_tutorial.
  ///
  /// In en, this message translates to:
  /// **'Read the token tutorial'**
  String get app_open_token_tutorial;

  /// No description provided for @app_open_token_tutorial_desc.
  ///
  /// In en, this message translates to:
  /// **'A step-by-step guide to generate and copy your bot token.'**
  String get app_open_token_tutorial_desc;

  /// No description provided for @app_external_link_badge.
  ///
  /// In en, this message translates to:
  /// **'External link'**
  String get app_external_link_badge;

  /// No description provided for @app_token_section_title.
  ///
  /// In en, this message translates to:
  /// **'Paste your bot token'**
  String get app_token_section_title;

  /// No description provided for @app_token_section_desc.
  ///
  /// In en, this message translates to:
  /// **'Once the token is copied, paste it below to add your bot to the app.'**
  String get app_token_section_desc;

  /// No description provided for @app_token_field_helper.
  ///
  /// In en, this message translates to:
  /// **'Paste the token exactly as provided by Discord.'**
  String get app_token_field_helper;

  /// No description provided for @app_token_security_hint.
  ///
  /// In en, this message translates to:
  /// **'Keep this token private. Anyone with it can control your bot.'**
  String get app_token_security_hint;

  /// No description provided for @app_show_token.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get app_show_token;

  /// No description provided for @app_hide_token.
  ///
  /// In en, this message translates to:
  /// **'Hide token'**
  String get app_hide_token;

  /// No description provided for @app_save_bot.
  ///
  /// In en, this message translates to:
  /// **'Add bot'**
  String get app_save_bot;

  /// No description provided for @app_open_link_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to open this external page.'**
  String get app_open_link_error;

  /// No description provided for @app_how_to_create_token.
  ///
  /// In en, this message translates to:
  /// **'How to create a Bot Token?'**
  String get app_how_to_create_token;

  /// No description provided for @app_bot_token.
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get app_bot_token;

  /// No description provided for @app_enter_token.
  ///
  /// In en, this message translates to:
  /// **'Enter your bot token here'**
  String get app_enter_token;

  /// No description provided for @app_note.
  ///
  /// In en, this message translates to:
  /// **'Note: You need to create a new App in the Discord Developer Portal and get your bot token.'**
  String get app_note;

  /// No description provided for @app_save.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get app_save;

  /// No description provided for @app_sync_manager_title.
  ///
  /// In en, this message translates to:
  /// **'Bot already managed'**
  String get app_sync_manager_title;

  /// No description provided for @app_sync_manager_desc.
  ///
  /// In en, this message translates to:
  /// **'This bot is already stored on Bot Creator Manager. Connect with Discord to sync all your bots automatically?'**
  String get app_sync_manager_desc;

  /// No description provided for @app_sync_manager_manual.
  ///
  /// In en, this message translates to:
  /// **'Keep local'**
  String get app_sync_manager_manual;

  /// No description provided for @app_sync_manager_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect Discord'**
  String get app_sync_manager_connect;

  /// No description provided for @app_no_apps.
  ///
  /// In en, this message translates to:
  /// **'No applications found'**
  String get app_no_apps;

  /// No description provided for @app_loading_error.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get app_loading_error;

  /// No description provided for @app_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create a bot'**
  String get app_create_button;

  /// No description provided for @home_tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home_tab;

  /// No description provided for @commands_tab.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commands_tab;

  /// No description provided for @commands_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Cmd'**
  String get commands_tab_short;

  /// No description provided for @globals_tab.
  ///
  /// In en, this message translates to:
  /// **'Globals'**
  String get globals_tab;

  /// No description provided for @globals_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Vars'**
  String get globals_tab_short;

  /// No description provided for @workflows_tab.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows_tab;

  /// No description provided for @workflows_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Flow'**
  String get workflows_tab_short;

  /// No description provided for @scheduler_tab.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler_tab;

  /// No description provided for @scheduler_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Sched'**
  String get scheduler_tab_short;

  /// No description provided for @emojis_tab.
  ///
  /// In en, this message translates to:
  /// **'Emojis'**
  String get emojis_tab;

  /// No description provided for @emojis_tab_short.
  ///
  /// In en, this message translates to:
  /// **'Emoji'**
  String get emojis_tab_short;

  /// No description provided for @emojis_title.
  ///
  /// In en, this message translates to:
  /// **'Application Emojis'**
  String get emojis_title;

  /// No description provided for @emojis_empty.
  ///
  /// In en, this message translates to:
  /// **'No emojis yet. Upload one to get started.'**
  String get emojis_empty;

  /// No description provided for @emojis_upload.
  ///
  /// In en, this message translates to:
  /// **'Upload Emoji'**
  String get emojis_upload;

  /// No description provided for @emojis_upload_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Emoji name (letters, numbers, _)'**
  String get emojis_upload_name_hint;

  /// No description provided for @emojis_upload_pick_image.
  ///
  /// In en, this message translates to:
  /// **'Pick Image'**
  String get emojis_upload_pick_image;

  /// No description provided for @emojis_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Emoji'**
  String get emojis_delete_confirm_title;

  /// No description provided for @emojis_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'Delete :{name}: ? This action cannot be undone.'**
  String emojis_delete_confirm_body(String name);

  /// No description provided for @emojis_rename_title.
  ///
  /// In en, this message translates to:
  /// **'Rename Emoji'**
  String get emojis_rename_title;

  /// No description provided for @emojis_rename_hint.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get emojis_rename_hint;

  /// No description provided for @emojis_loading_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to load emojis'**
  String get emojis_loading_error;

  /// No description provided for @emojis_upload_error.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String emojis_upload_error(String error);

  /// No description provided for @emojis_delete_error.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String emojis_delete_error(String error);

  /// No description provided for @emojis_rename_error.
  ///
  /// In en, this message translates to:
  /// **'Rename failed: {error}'**
  String emojis_rename_error(String error);

  /// No description provided for @settings_tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_tab;

  /// No description provided for @more_tab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more_tab;

  /// No description provided for @quick_access_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quick_access_title;

  /// No description provided for @more_options_title.
  ///
  /// In en, this message translates to:
  /// **'More Options'**
  String get more_options_title;

  /// No description provided for @no_more_options.
  ///
  /// In en, this message translates to:
  /// **'No other options available'**
  String get no_more_options;

  /// No description provided for @settings_theme_switch_light.
  ///
  /// In en, this message translates to:
  /// **'Switch to light mode'**
  String get settings_theme_switch_light;

  /// No description provided for @settings_theme_switch_dark.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark mode'**
  String get settings_theme_switch_dark;

  /// No description provided for @settings_appearance_title.
  ///
  /// In en, this message translates to:
  /// **'Appearance & language'**
  String get settings_appearance_title;

  /// No description provided for @settings_language_title.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language_title;

  /// No description provided for @settings_language_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used by the app.'**
  String get settings_language_desc;

  /// No description provided for @settings_language_system.
  ///
  /// In en, this message translates to:
  /// **'Automatic (device)'**
  String get settings_language_system;

  /// No description provided for @settings_language_updated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get settings_language_updated;

  /// No description provided for @settings_debug_title.
  ///
  /// In en, this message translates to:
  /// **'Debug tools'**
  String get settings_debug_title;

  /// No description provided for @settings_debug_desc.
  ///
  /// In en, this message translates to:
  /// **'Reset local preferences or replay onboarding for testing.'**
  String get settings_debug_desc;

  /// No description provided for @settings_reset_preferences.
  ///
  /// In en, this message translates to:
  /// **'Reset preferences'**
  String get settings_reset_preferences;

  /// No description provided for @settings_reset_preferences_desc.
  ///
  /// In en, this message translates to:
  /// **'Reset theme, language and onboarding progress.'**
  String get settings_reset_preferences_desc;

  /// No description provided for @settings_replay_onboarding.
  ///
  /// In en, this message translates to:
  /// **'Replay onboarding'**
  String get settings_replay_onboarding;

  /// No description provided for @settings_replay_onboarding_desc.
  ///
  /// In en, this message translates to:
  /// **'Reset onboarding and launch it again now.'**
  String get settings_replay_onboarding_desc;

  /// No description provided for @settings_debug_premium_bypass.
  ///
  /// In en, this message translates to:
  /// **'Premium bypass'**
  String get settings_debug_premium_bypass;

  /// No description provided for @settings_debug_premium_bypass_desc.
  ///
  /// In en, this message translates to:
  /// **'Unlock all Premium features without a subscription (debug only).'**
  String get settings_debug_premium_bypass_desc;

  /// No description provided for @settings_preferences_reset_done.
  ///
  /// In en, this message translates to:
  /// **'Preferences reset'**
  String get settings_preferences_reset_done;

  /// No description provided for @settings_backup_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Backup and Restore'**
  String get settings_backup_restore_title;

  /// No description provided for @settings_backup_restore_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage your data synchronization with Google Drive'**
  String get settings_backup_restore_desc;

  /// No description provided for @settings_snapshot_preview_title.
  ///
  /// In en, this message translates to:
  /// **'Snapshot Preview'**
  String get settings_snapshot_preview_title;

  /// No description provided for @settings_snapshot_id.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String settings_snapshot_id(String id);

  /// No description provided for @settings_snapshot_label.
  ///
  /// In en, this message translates to:
  /// **'Label: {label}'**
  String settings_snapshot_label(String label);

  /// No description provided for @settings_snapshot_created_at.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String settings_snapshot_created_at(String date);

  /// No description provided for @settings_snapshot_files_size.
  ///
  /// In en, this message translates to:
  /// **'Files: {count} • Size: {size}'**
  String settings_snapshot_files_size(String count, String size);

  /// No description provided for @settings_snapshot_apps_count.
  ///
  /// In en, this message translates to:
  /// **'Apps: {count}'**
  String settings_snapshot_apps_count(String count);

  /// No description provided for @settings_snapshot_apps_list.
  ///
  /// In en, this message translates to:
  /// **'Apps in this snapshot'**
  String get settings_snapshot_apps_list;

  /// No description provided for @settings_snapshot_no_metadata.
  ///
  /// In en, this message translates to:
  /// **'No app metadata available.'**
  String get settings_snapshot_no_metadata;

  /// No description provided for @settings_snapshot_delete_loading.
  ///
  /// In en, this message translates to:
  /// **'Deleting snapshot…'**
  String get settings_snapshot_delete_loading;

  /// No description provided for @settings_snapshot_deleted.
  ///
  /// In en, this message translates to:
  /// **'Snapshot deleted'**
  String get settings_snapshot_deleted;

  /// No description provided for @settings_snapshot_restore_loading.
  ///
  /// In en, this message translates to:
  /// **'Restoring snapshot…'**
  String get settings_snapshot_restore_loading;

  /// No description provided for @settings_restore_snapshot.
  ///
  /// In en, this message translates to:
  /// **'Restore This Snapshot'**
  String get settings_restore_snapshot;

  /// No description provided for @settings_diagnostics_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Startup Diagnostics'**
  String get settings_diagnostics_dialog_title;

  /// No description provided for @settings_diagnostics_copied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard'**
  String get settings_diagnostics_copied;

  /// No description provided for @settings_drive_title.
  ///
  /// In en, this message translates to:
  /// **'Google Drive Connection'**
  String get settings_drive_title;

  /// No description provided for @settings_drive_desc.
  ///
  /// In en, this message translates to:
  /// **'Connect your Google Drive account to sync your data'**
  String get settings_drive_desc;

  /// No description provided for @settings_drive_connect_loading.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Google Drive…'**
  String get settings_drive_connect_loading;

  /// No description provided for @settings_drive_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Drive'**
  String get settings_drive_connected;

  /// No description provided for @settings_drive_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect to Google Drive'**
  String get settings_drive_connect;

  /// No description provided for @settings_drive_status_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get settings_drive_status_connected;

  /// No description provided for @settings_drive_disconnect_loading.
  ///
  /// In en, this message translates to:
  /// **'Disconnecting…'**
  String get settings_drive_disconnect_loading;

  /// No description provided for @settings_drive_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from Google Drive'**
  String get settings_drive_disconnected;

  /// No description provided for @settings_drive_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get settings_drive_disconnect;

  /// No description provided for @settings_runner_title.
  ///
  /// In en, this message translates to:
  /// **'Runner API'**
  String get settings_runner_title;

  /// No description provided for @settings_runner_desc.
  ///
  /// In en, this message translates to:
  /// **'Connect the app to a Bot Creator Runner. Remote runners should stay on trusted networks and use a bearer token.'**
  String get settings_runner_desc;

  /// No description provided for @settings_runner_url_hint.
  ///
  /// In en, this message translates to:
  /// **'http://192.168.1.x:8080'**
  String get settings_runner_url_hint;

  /// No description provided for @settings_runner_token_label.
  ///
  /// In en, this message translates to:
  /// **'Runner API token'**
  String get settings_runner_token_label;

  /// No description provided for @settings_runner_token_hint.
  ///
  /// In en, this message translates to:
  /// **'Bearer token (optional on localhost)'**
  String get settings_runner_token_hint;

  /// No description provided for @settings_runner_save.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settings_runner_save;

  /// No description provided for @settings_runner_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_runner_clear;

  /// No description provided for @settings_runner_saved.
  ///
  /// In en, this message translates to:
  /// **'Runner settings saved'**
  String get settings_runner_saved;

  /// No description provided for @settings_runner_cleared.
  ///
  /// In en, this message translates to:
  /// **'Runner settings cleared'**
  String get settings_runner_cleared;

  /// No description provided for @settings_runner_url_save.
  ///
  /// In en, this message translates to:
  /// **'Save URL'**
  String get settings_runner_url_save;

  /// No description provided for @settings_runner_url_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get settings_runner_url_clear;

  /// No description provided for @settings_runner_url_saved.
  ///
  /// In en, this message translates to:
  /// **'Runner URL saved'**
  String get settings_runner_url_saved;

  /// No description provided for @settings_runner_url_cleared.
  ///
  /// In en, this message translates to:
  /// **'Runner URL cleared'**
  String get settings_runner_url_cleared;

  /// No description provided for @settings_runner_check.
  ///
  /// In en, this message translates to:
  /// **'Check connection'**
  String get settings_runner_check;

  /// No description provided for @settings_runner_connected.
  ///
  /// In en, this message translates to:
  /// **'Runner reachable ✓'**
  String get settings_runner_connected;

  /// No description provided for @settings_runner_auth_failed.
  ///
  /// In en, this message translates to:
  /// **'Runner rejected the API token'**
  String get settings_runner_auth_failed;

  /// No description provided for @settings_runner_unreachable.
  ///
  /// In en, this message translates to:
  /// **'Runner unreachable'**
  String get settings_runner_unreachable;

  /// No description provided for @settings_runner_connecting.
  ///
  /// In en, this message translates to:
  /// **'Checking connection…'**
  String get settings_runner_connecting;

  /// No description provided for @settings_runner_active.
  ///
  /// In en, this message translates to:
  /// **'Active Runner API: {url}'**
  String settings_runner_active(String url);

  /// No description provided for @settings_runner_disable_temp.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable Runner'**
  String get settings_runner_disable_temp;

  /// No description provided for @settings_runner_disable_temp_desc.
  ///
  /// In en, this message translates to:
  /// **'Keep Runner settings but force local mode until re-enabled.'**
  String get settings_runner_disable_temp_desc;

  /// No description provided for @settings_runner_temporarily_disabled.
  ///
  /// In en, this message translates to:
  /// **'Runner temporarily disabled (local mode active)'**
  String get settings_runner_temporarily_disabled;

  /// No description provided for @settings_runner_temporarily_disabled_saved.
  ///
  /// In en, this message translates to:
  /// **'Runner temporarily disabled'**
  String get settings_runner_temporarily_disabled_saved;

  /// No description provided for @settings_runner_reenabled.
  ///
  /// In en, this message translates to:
  /// **'Runner re-enabled'**
  String get settings_runner_reenabled;

  /// No description provided for @settings_discord_rpc_title.
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence'**
  String get settings_discord_rpc_title;

  /// No description provided for @settings_discord_rpc_desc.
  ///
  /// In en, this message translates to:
  /// **'Publish Bot Creator desktop activity to the local Discord client. Bot Creator always uses the built-in Discord application and sends SET_ACTIVITY directly over local IPC when enabled.'**
  String get settings_discord_rpc_desc;

  /// No description provided for @settings_discord_rpc_enable.
  ///
  /// In en, this message translates to:
  /// **'Enable Discord Rich Presence'**
  String get settings_discord_rpc_enable;

  /// No description provided for @settings_discord_rpc_client_id_hint.
  ///
  /// In en, this message translates to:
  /// **'1350824555119382678'**
  String get settings_discord_rpc_client_id_hint;

  /// No description provided for @settings_discord_rpc_client_id_helper.
  ///
  /// In en, this message translates to:
  /// **'This ID is fixed in Bot Creator and cannot be changed from settings.'**
  String get settings_discord_rpc_client_id_helper;

  /// No description provided for @settings_discord_rpc_client_secret_label.
  ///
  /// In en, this message translates to:
  /// **'Discord application client secret (optional)'**
  String get settings_discord_rpc_client_secret_label;

  /// No description provided for @settings_discord_rpc_client_secret_hint.
  ///
  /// In en, this message translates to:
  /// **'Client secret'**
  String get settings_discord_rpc_client_secret_hint;

  /// No description provided for @settings_discord_rpc_client_secret_helper.
  ///
  /// In en, this message translates to:
  /// **'Optional advanced fallback for a confidential-client flow handled locally.'**
  String get settings_discord_rpc_client_secret_helper;

  /// No description provided for @settings_discord_rpc_broker_label.
  ///
  /// In en, this message translates to:
  /// **'OAuth broker URL (advanced, optional)'**
  String get settings_discord_rpc_broker_label;

  /// No description provided for @settings_discord_rpc_broker_hint.
  ///
  /// In en, this message translates to:
  /// **'https://auth.example.com'**
  String get settings_discord_rpc_broker_hint;

  /// No description provided for @settings_discord_rpc_save.
  ///
  /// In en, this message translates to:
  /// **'Save settings'**
  String get settings_discord_rpc_save;

  /// No description provided for @settings_discord_rpc_saved.
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence settings saved'**
  String get settings_discord_rpc_saved;

  /// No description provided for @settings_discord_rpc_connect.
  ///
  /// In en, this message translates to:
  /// **'Refresh presence'**
  String get settings_discord_rpc_connect;

  /// No description provided for @settings_discord_rpc_authorize.
  ///
  /// In en, this message translates to:
  /// **'Authorize'**
  String get settings_discord_rpc_authorize;

  /// No description provided for @settings_discord_rpc_complete_authorization.
  ///
  /// In en, this message translates to:
  /// **'Complete authorization'**
  String get settings_discord_rpc_complete_authorization;

  /// No description provided for @settings_discord_rpc_authorization_pending_exchange.
  ///
  /// In en, this message translates to:
  /// **'Authorization code received'**
  String get settings_discord_rpc_authorization_pending_exchange;

  /// No description provided for @settings_discord_rpc_open_ipc.
  ///
  /// In en, this message translates to:
  /// **'Open local IPC'**
  String get settings_discord_rpc_open_ipc;

  /// No description provided for @settings_discord_rpc_ipc_open.
  ///
  /// In en, this message translates to:
  /// **'Local IPC already open'**
  String get settings_discord_rpc_ipc_open;

  /// No description provided for @settings_discord_rpc_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Close IPC'**
  String get settings_discord_rpc_disconnect;

  /// No description provided for @settings_discord_rpc_user.
  ///
  /// In en, this message translates to:
  /// **'Authorized user: {user}'**
  String settings_discord_rpc_user(String user);

  /// No description provided for @settings_discord_rpc_endpoint.
  ///
  /// In en, this message translates to:
  /// **'IPC endpoint: {endpoint}'**
  String settings_discord_rpc_endpoint(String endpoint);

  /// No description provided for @settings_discord_rpc_last_error.
  ///
  /// In en, this message translates to:
  /// **'Last error: {error}'**
  String settings_discord_rpc_last_error(String error);

  /// No description provided for @settings_discord_rpc_enable_first.
  ///
  /// In en, this message translates to:
  /// **'Enable Discord Rich Presence first'**
  String get settings_discord_rpc_enable_first;

  /// No description provided for @settings_discord_rpc_client_id_required.
  ///
  /// In en, this message translates to:
  /// **'Discord application client ID required'**
  String get settings_discord_rpc_client_id_required;

  /// No description provided for @settings_discord_rpc_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get settings_discord_rpc_disabled;

  /// No description provided for @settings_discord_rpc_platform_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Discord Rich Presence is desktop only'**
  String get settings_discord_rpc_platform_unsupported;

  /// No description provided for @settings_discord_rpc_transport_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Discord transport is not supported on this platform yet'**
  String get settings_discord_rpc_transport_unsupported;

  /// No description provided for @settings_discord_rpc_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Client ID required'**
  String get settings_discord_rpc_not_configured;

  /// No description provided for @settings_discord_rpc_broker_required.
  ///
  /// In en, this message translates to:
  /// **'Client ID is enough for the public-client flow; broker URL and client secret are optional fallbacks'**
  String get settings_discord_rpc_broker_required;

  /// No description provided for @settings_discord_rpc_disconnected.
  ///
  /// In en, this message translates to:
  /// **'IPC closed'**
  String get settings_discord_rpc_disconnected;

  /// No description provided for @settings_discord_rpc_needs_authorization.
  ///
  /// In en, this message translates to:
  /// **'Authorization required'**
  String get settings_discord_rpc_needs_authorization;

  /// No description provided for @settings_discord_rpc_authorization_code_pending_exchange.
  ///
  /// In en, this message translates to:
  /// **'Authorization code cached; retry to finish the token exchange'**
  String get settings_discord_rpc_authorization_code_pending_exchange;

  /// No description provided for @settings_discord_rpc_ipc_connected_auth_required.
  ///
  /// In en, this message translates to:
  /// **'Local Discord IPC connected; no OAuth HTTP request sent yet, authentication still required'**
  String get settings_discord_rpc_ipc_connected_auth_required;

  /// No description provided for @settings_discord_rpc_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Discord…'**
  String get settings_discord_rpc_connecting;

  /// No description provided for @settings_discord_rpc_authorizing.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Discord authorization…'**
  String get settings_discord_rpc_authorizing;

  /// No description provided for @settings_discord_rpc_exchanging_code.
  ///
  /// In en, this message translates to:
  /// **'Completing OAuth exchange…'**
  String get settings_discord_rpc_exchanging_code;

  /// No description provided for @settings_discord_rpc_authenticating.
  ///
  /// In en, this message translates to:
  /// **'Authenticating with Discord…'**
  String get settings_discord_rpc_authenticating;

  /// No description provided for @settings_discord_rpc_connected.
  ///
  /// In en, this message translates to:
  /// **'Presence sent to Discord'**
  String get settings_discord_rpc_connected;

  /// No description provided for @settings_discord_rpc_error.
  ///
  /// In en, this message translates to:
  /// **'Discord RPC error'**
  String get settings_discord_rpc_error;

  /// No description provided for @settings_data_operations_title.
  ///
  /// In en, this message translates to:
  /// **'Data Operations'**
  String get settings_data_operations_title;

  /// No description provided for @settings_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settings_export;

  /// No description provided for @settings_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settings_import;

  /// No description provided for @settings_export_app_data.
  ///
  /// In en, this message translates to:
  /// **'Export App Data'**
  String get settings_export_app_data;

  /// No description provided for @settings_import_app_data.
  ///
  /// In en, this message translates to:
  /// **'Import App Data'**
  String get settings_import_app_data;

  /// No description provided for @settings_export_loading.
  ///
  /// In en, this message translates to:
  /// **'Exporting…'**
  String get settings_export_loading;

  /// No description provided for @settings_import_loading.
  ///
  /// In en, this message translates to:
  /// **'Importing…'**
  String get settings_import_loading;

  /// No description provided for @settings_recovery_title.
  ///
  /// In en, this message translates to:
  /// **'Recovery Pro'**
  String get settings_recovery_title;

  /// No description provided for @settings_enable_auto_backup.
  ///
  /// In en, this message translates to:
  /// **'Enable auto-backup'**
  String get settings_enable_auto_backup;

  /// No description provided for @settings_enable_auto_backup_desc.
  ///
  /// In en, this message translates to:
  /// **'Create versioned snapshots automatically when due.'**
  String get settings_enable_auto_backup_desc;

  /// No description provided for @settings_auto_backup_interval.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup interval'**
  String get settings_auto_backup_interval;

  /// No description provided for @settings_auto_backup_every_6h.
  ///
  /// In en, this message translates to:
  /// **'Every 6h'**
  String get settings_auto_backup_every_6h;

  /// No description provided for @settings_auto_backup_every_12h.
  ///
  /// In en, this message translates to:
  /// **'Every 12h'**
  String get settings_auto_backup_every_12h;

  /// No description provided for @settings_auto_backup_every_24h.
  ///
  /// In en, this message translates to:
  /// **'Every 24h'**
  String get settings_auto_backup_every_24h;

  /// No description provided for @settings_auto_backup_every_72h.
  ///
  /// In en, this message translates to:
  /// **'Every 72h'**
  String get settings_auto_backup_every_72h;

  /// No description provided for @settings_last_auto_backup_never.
  ///
  /// In en, this message translates to:
  /// **'Last auto-backup: never'**
  String get settings_last_auto_backup_never;

  /// No description provided for @settings_last_auto_backup_at.
  ///
  /// In en, this message translates to:
  /// **'Last auto-backup: {date}'**
  String settings_last_auto_backup_at(String date);

  /// No description provided for @settings_snapshot_create_loading.
  ///
  /// In en, this message translates to:
  /// **'Creating snapshot…'**
  String get settings_snapshot_create_loading;

  /// No description provided for @settings_manual_snapshot_label.
  ///
  /// In en, this message translates to:
  /// **'Manual snapshot'**
  String get settings_manual_snapshot_label;

  /// No description provided for @settings_snapshot_created_message.
  ///
  /// In en, this message translates to:
  /// **'Snapshot created: {id}'**
  String settings_snapshot_created_message(String id);

  /// No description provided for @settings_backup_now.
  ///
  /// In en, this message translates to:
  /// **'Backup now'**
  String get settings_backup_now;

  /// No description provided for @settings_run_auto_backup_now.
  ///
  /// In en, this message translates to:
  /// **'Run auto-backup now'**
  String get settings_run_auto_backup_now;

  /// No description provided for @settings_auto_backup_check_loading.
  ///
  /// In en, this message translates to:
  /// **'Auto-backup check…'**
  String get settings_auto_backup_check_loading;

  /// No description provided for @settings_snapshots_title.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get settings_snapshots_title;

  /// No description provided for @settings_snapshots_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh snapshots'**
  String get settings_snapshots_refresh;

  /// No description provided for @settings_snapshots_delete_all.
  ///
  /// In en, this message translates to:
  /// **'Delete all snapshots'**
  String get settings_snapshots_delete_all;

  /// No description provided for @settings_snapshots_delete_all_title.
  ///
  /// In en, this message translates to:
  /// **'Delete all snapshots'**
  String get settings_snapshots_delete_all_title;

  /// No description provided for @settings_snapshots_delete_all_confirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete {count} snapshot(s)? This action cannot be undone.'**
  String settings_snapshots_delete_all_confirm(String count);

  /// No description provided for @settings_snapshots_delete_all_loading.
  ///
  /// In en, this message translates to:
  /// **'Deleting all snapshots…'**
  String get settings_snapshots_delete_all_loading;

  /// No description provided for @settings_snapshots_delete_all_done.
  ///
  /// In en, this message translates to:
  /// **'{count} snapshot(s) deleted.'**
  String settings_snapshots_delete_all_done(String count);

  /// No description provided for @settings_snapshots_delete_select_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete a selected snapshot'**
  String get settings_snapshots_delete_select_tooltip;

  /// No description provided for @settings_snapshots_delete_select_title.
  ///
  /// In en, this message translates to:
  /// **'Delete a snapshot'**
  String get settings_snapshots_delete_select_title;

  /// No description provided for @settings_snapshots_delete_select_desc.
  ///
  /// In en, this message translates to:
  /// **'Select the snapshot to remove (oldest first).'**
  String get settings_snapshots_delete_select_desc;

  /// No description provided for @settings_snapshots_delete_one_confirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete \"{label}\"? This action cannot be undone.'**
  String settings_snapshots_delete_one_confirm(String label);

  /// No description provided for @settings_snapshots_refresh_loading.
  ///
  /// In en, this message translates to:
  /// **'Refreshing snapshots…'**
  String get settings_snapshots_refresh_loading;

  /// No description provided for @settings_snapshots_empty.
  ///
  /// In en, this message translates to:
  /// **'No snapshots found yet.'**
  String get settings_snapshots_empty;

  /// No description provided for @settings_snapshot_list_entry.
  ///
  /// In en, this message translates to:
  /// **'{date} • {count} files • {size}'**
  String settings_snapshot_list_entry(String date, String count, String size);

  /// No description provided for @settings_diagnostics_section_title.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics'**
  String get settings_diagnostics_section_title;

  /// No description provided for @settings_diagnostics_page_title.
  ///
  /// In en, this message translates to:
  /// **'Application Logs'**
  String get settings_diagnostics_page_title;

  /// No description provided for @settings_diagnostics_page_scope_note.
  ///
  /// In en, this message translates to:
  /// **'Shows app diagnostics logs only (bot logs are excluded).'**
  String get settings_diagnostics_page_scope_note;

  /// No description provided for @settings_diagnostics_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh logs'**
  String get settings_diagnostics_refresh;

  /// No description provided for @settings_diagnostics_copy_all.
  ///
  /// In en, this message translates to:
  /// **'Copy all logs'**
  String get settings_diagnostics_copy_all;

  /// No description provided for @settings_diagnostics_empty.
  ///
  /// In en, this message translates to:
  /// **'No application logs yet.'**
  String get settings_diagnostics_empty;

  /// No description provided for @settings_view_startup_logs.
  ///
  /// In en, this message translates to:
  /// **'View startup logs'**
  String get settings_view_startup_logs;

  /// No description provided for @settings_clear_logs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get settings_clear_logs;

  /// No description provided for @settings_logs_cleared.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics log cleared'**
  String get settings_logs_cleared;

  /// No description provided for @settings_legal_title.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get settings_legal_title;

  /// No description provided for @settings_legal_desc.
  ///
  /// In en, this message translates to:
  /// **'Review how your data is handled and stored.'**
  String get settings_legal_desc;

  /// No description provided for @settings_privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settings_privacy_policy;

  /// No description provided for @settings_compatibility_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD compatibility snapshot'**
  String get settings_compatibility_title;

  /// No description provided for @settings_compatibility_desc.
  ///
  /// In en, this message translates to:
  /// **'A quick view of feature coverage for users moving from BDFD.'**
  String get settings_compatibility_desc;

  /// No description provided for @settings_compatibility_status_supported.
  ///
  /// In en, this message translates to:
  /// **'Supported'**
  String get settings_compatibility_status_supported;

  /// No description provided for @settings_compatibility_status_partial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get settings_compatibility_status_partial;

  /// No description provided for @settings_compatibility_status_missing.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get settings_compatibility_status_missing;

  /// No description provided for @settings_compatibility_item_workflows_title.
  ///
  /// In en, this message translates to:
  /// **'Workflow builder'**
  String get settings_compatibility_item_workflows_title;

  /// No description provided for @settings_compatibility_item_workflows_desc.
  ///
  /// In en, this message translates to:
  /// **'Visual command and response workflows are available.'**
  String get settings_compatibility_item_workflows_desc;

  /// No description provided for @settings_compatibility_item_variables_title.
  ///
  /// In en, this message translates to:
  /// **'Runtime variables and templates'**
  String get settings_compatibility_item_variables_title;

  /// No description provided for @settings_compatibility_item_variables_desc.
  ///
  /// In en, this message translates to:
  /// **'Dynamic variables and template helpers are supported.'**
  String get settings_compatibility_item_variables_desc;

  /// No description provided for @settings_compatibility_item_events_title.
  ///
  /// In en, this message translates to:
  /// **'Event coverage'**
  String get settings_compatibility_item_events_title;

  /// No description provided for @settings_compatibility_item_events_desc.
  ///
  /// In en, this message translates to:
  /// **'Most common events are supported, some are runtime-limited.'**
  String get settings_compatibility_item_events_desc;

  /// No description provided for @settings_compatibility_item_runner_title.
  ///
  /// In en, this message translates to:
  /// **'Runner architecture'**
  String get settings_compatibility_item_runner_title;

  /// No description provided for @settings_compatibility_item_runner_desc.
  ///
  /// In en, this message translates to:
  /// **'Remote runner is available, multi-runner support is in progress.'**
  String get settings_compatibility_item_runner_desc;

  /// No description provided for @settings_compatibility_item_bdscript_title.
  ///
  /// In en, this message translates to:
  /// **'BDScript function parity'**
  String get settings_compatibility_item_bdscript_title;

  /// No description provided for @settings_compatibility_item_bdscript_desc.
  ///
  /// In en, this message translates to:
  /// **'Full coverage of the BDFD function catalog.'**
  String get settings_compatibility_item_bdscript_desc;

  /// No description provided for @settings_compatibility_note.
  ///
  /// In en, this message translates to:
  /// **'This snapshot is intentionally high-level and will evolve with releases.'**
  String get settings_compatibility_note;

  /// No description provided for @settings_compatibility_open_functions.
  ///
  /// In en, this message translates to:
  /// **'View compatible functions'**
  String get settings_compatibility_open_functions;

  /// No description provided for @settings_compatibility_functions_title.
  ///
  /// In en, this message translates to:
  /// **'Compatible BDFD Functions'**
  String get settings_compatibility_functions_title;

  /// No description provided for @settings_compatibility_functions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Functions currently implemented and usable in Bot Creator BDFD mode.'**
  String get settings_compatibility_functions_subtitle;

  /// No description provided for @settings_compatibility_functions_matrix_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Diff view between Bot Creator implementation and BDFD reference functions.'**
  String get settings_compatibility_functions_matrix_subtitle;

  /// No description provided for @settings_compatibility_functions_count.
  ///
  /// In en, this message translates to:
  /// **'Compatible functions: {count}'**
  String settings_compatibility_functions_count(String count);

  /// No description provided for @settings_compatibility_functions_count_bot_creator.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator supported: {count}'**
  String settings_compatibility_functions_count_bot_creator(String count);

  /// No description provided for @settings_compatibility_functions_count_bdfd.
  ///
  /// In en, this message translates to:
  /// **'BDFD reference total: {count}'**
  String settings_compatibility_functions_count_bdfd(String count);

  /// No description provided for @settings_compatibility_functions_count_both.
  ///
  /// In en, this message translates to:
  /// **'Supported on both: {count}'**
  String settings_compatibility_functions_count_both(String count);

  /// No description provided for @settings_compatibility_functions_count_missing.
  ///
  /// In en, this message translates to:
  /// **'Missing in Bot Creator: {count}'**
  String settings_compatibility_functions_count_missing(String count);

  /// No description provided for @settings_compatibility_functions_count_bot_only.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only: {count}'**
  String settings_compatibility_functions_count_bot_only(String count);

  /// No description provided for @settings_compatibility_functions_note.
  ///
  /// In en, this message translates to:
  /// **'This page is generated from the current implementation scope and will grow over time.'**
  String get settings_compatibility_functions_note;

  /// No description provided for @settings_compatibility_functions_matrix_note.
  ///
  /// In en, this message translates to:
  /// **'BDFD-only entries are functions listed in the provided BDFD catalog but not currently implemented in Bot Creator.'**
  String get settings_compatibility_functions_matrix_note;

  /// No description provided for @settings_compatibility_functions_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search a function (example: \$userJoined)'**
  String get settings_compatibility_functions_search_hint;

  /// No description provided for @settings_compatibility_functions_section_both.
  ///
  /// In en, this message translates to:
  /// **'Supported on Bot Creator and BDFD'**
  String get settings_compatibility_functions_section_both;

  /// No description provided for @settings_compatibility_functions_section_bot_only.
  ///
  /// In en, this message translates to:
  /// **'Supported on Bot Creator only'**
  String get settings_compatibility_functions_section_bot_only;

  /// No description provided for @settings_compatibility_functions_section_bot_only_note.
  ///
  /// In en, this message translates to:
  /// **'Loop helpers are currently Bot Creator specific.'**
  String get settings_compatibility_functions_section_bot_only_note;

  /// No description provided for @settings_compatibility_functions_section_missing.
  ///
  /// In en, this message translates to:
  /// **'Available on BDFD but missing in Bot Creator'**
  String get settings_compatibility_functions_section_missing;

  /// No description provided for @settings_compatibility_functions_empty.
  ///
  /// In en, this message translates to:
  /// **'No function in this section.'**
  String get settings_compatibility_functions_empty;

  /// No description provided for @settings_compatibility_functions_category_guards.
  ///
  /// In en, this message translates to:
  /// **'Guards and permissions'**
  String get settings_compatibility_functions_category_guards;

  /// No description provided for @settings_compatibility_functions_category_control.
  ///
  /// In en, this message translates to:
  /// **'Control flow'**
  String get settings_compatibility_functions_category_control;

  /// No description provided for @settings_compatibility_functions_category_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get settings_compatibility_functions_category_messages;

  /// No description provided for @settings_compatibility_functions_category_embeds.
  ///
  /// In en, this message translates to:
  /// **'Embeds'**
  String get settings_compatibility_functions_category_embeds;

  /// No description provided for @settings_compatibility_functions_category_components.
  ///
  /// In en, this message translates to:
  /// **'Components / Interactions'**
  String get settings_compatibility_functions_category_components;

  /// No description provided for @settings_compatibility_functions_category_logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get settings_compatibility_functions_category_logging;

  /// No description provided for @settings_compatibility_functions_category_json.
  ///
  /// In en, this message translates to:
  /// **'JSON helpers'**
  String get settings_compatibility_functions_category_json;

  /// No description provided for @settings_compatibility_functions_category_http.
  ///
  /// In en, this message translates to:
  /// **'HTTP helpers'**
  String get settings_compatibility_functions_category_http;

  /// No description provided for @settings_compatibility_functions_category_variables.
  ///
  /// In en, this message translates to:
  /// **'Scoped variables'**
  String get settings_compatibility_functions_category_variables;

  /// No description provided for @settings_compatibility_functions_category_threads.
  ///
  /// In en, this message translates to:
  /// **'Threads'**
  String get settings_compatibility_functions_category_threads;

  /// No description provided for @settings_compatibility_functions_category_runtime.
  ///
  /// In en, this message translates to:
  /// **'Runtime placeholders'**
  String get settings_compatibility_functions_category_runtime;

  /// No description provided for @settings_ads_privacy_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage ad privacy choices'**
  String get settings_ads_privacy_manage;

  /// No description provided for @settings_ads_privacy_not_required.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options are not required right now'**
  String get settings_ads_privacy_not_required;

  /// No description provided for @settings_ads_privacy_loading.
  ///
  /// In en, this message translates to:
  /// **'Checking ad privacy settings...'**
  String get settings_ads_privacy_loading;

  /// No description provided for @settings_ads_privacy_opened.
  ///
  /// In en, this message translates to:
  /// **'Ad privacy options opened'**
  String get settings_ads_privacy_opened;

  /// No description provided for @settings_ads_privacy_open_error.
  ///
  /// In en, this message translates to:
  /// **'Could not open ad privacy options'**
  String get settings_ads_privacy_open_error;

  /// No description provided for @action_name_deleteMessages.
  ///
  /// In en, this message translates to:
  /// **'Delete Messages'**
  String get action_name_deleteMessages;

  /// No description provided for @action_name_createChannel.
  ///
  /// In en, this message translates to:
  /// **'Create Channel'**
  String get action_name_createChannel;

  /// No description provided for @action_name_updateChannel.
  ///
  /// In en, this message translates to:
  /// **'Update Channel'**
  String get action_name_updateChannel;

  /// No description provided for @action_name_removeChannel.
  ///
  /// In en, this message translates to:
  /// **'Remove Channel'**
  String get action_name_removeChannel;

  /// No description provided for @action_name_sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get action_name_sendMessage;

  /// No description provided for @action_name_editMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Message'**
  String get action_name_editMessage;

  /// No description provided for @action_name_addReaction.
  ///
  /// In en, this message translates to:
  /// **'Add Reaction'**
  String get action_name_addReaction;

  /// No description provided for @action_name_removeReaction.
  ///
  /// In en, this message translates to:
  /// **'Remove Reaction'**
  String get action_name_removeReaction;

  /// No description provided for @action_name_clearAllReactions.
  ///
  /// In en, this message translates to:
  /// **'Clear All Reactions'**
  String get action_name_clearAllReactions;

  /// No description provided for @action_name_banUser.
  ///
  /// In en, this message translates to:
  /// **'Ban User'**
  String get action_name_banUser;

  /// No description provided for @action_name_unbanUser.
  ///
  /// In en, this message translates to:
  /// **'Unban User'**
  String get action_name_unbanUser;

  /// No description provided for @action_name_kickUser.
  ///
  /// In en, this message translates to:
  /// **'Kick User'**
  String get action_name_kickUser;

  /// No description provided for @action_name_muteUser.
  ///
  /// In en, this message translates to:
  /// **'Mute User'**
  String get action_name_muteUser;

  /// No description provided for @action_name_unmuteUser.
  ///
  /// In en, this message translates to:
  /// **'Unmute User'**
  String get action_name_unmuteUser;

  /// No description provided for @action_name_addRole.
  ///
  /// In en, this message translates to:
  /// **'Add Role'**
  String get action_name_addRole;

  /// No description provided for @action_name_removeRole.
  ///
  /// In en, this message translates to:
  /// **'Remove Role'**
  String get action_name_removeRole;

  /// No description provided for @action_name_pinMessage.
  ///
  /// In en, this message translates to:
  /// **'Pin Message'**
  String get action_name_pinMessage;

  /// No description provided for @action_name_updateAutoMod.
  ///
  /// In en, this message translates to:
  /// **'Update AutoMod'**
  String get action_name_updateAutoMod;

  /// No description provided for @action_name_updateGuild.
  ///
  /// In en, this message translates to:
  /// **'Update Guild'**
  String get action_name_updateGuild;

  /// No description provided for @action_name_listMembers.
  ///
  /// In en, this message translates to:
  /// **'List Members'**
  String get action_name_listMembers;

  /// No description provided for @action_name_getMember.
  ///
  /// In en, this message translates to:
  /// **'Get Member'**
  String get action_name_getMember;

  /// No description provided for @action_name_sendComponentV2.
  ///
  /// In en, this message translates to:
  /// **'Send Component V2'**
  String get action_name_sendComponentV2;

  /// No description provided for @action_name_editComponentV2.
  ///
  /// In en, this message translates to:
  /// **'Edit Component V2'**
  String get action_name_editComponentV2;

  /// No description provided for @action_name_sendWebhook.
  ///
  /// In en, this message translates to:
  /// **'Send Webhook'**
  String get action_name_sendWebhook;

  /// No description provided for @action_name_editWebhook.
  ///
  /// In en, this message translates to:
  /// **'Edit Webhook'**
  String get action_name_editWebhook;

  /// No description provided for @action_name_deleteWebhook.
  ///
  /// In en, this message translates to:
  /// **'Delete Webhook'**
  String get action_name_deleteWebhook;

  /// No description provided for @action_name_listWebhooks.
  ///
  /// In en, this message translates to:
  /// **'List Webhooks'**
  String get action_name_listWebhooks;

  /// No description provided for @action_name_getWebhook.
  ///
  /// In en, this message translates to:
  /// **'Get Webhook'**
  String get action_name_getWebhook;

  /// No description provided for @action_name_httpRequest.
  ///
  /// In en, this message translates to:
  /// **'HTTP Request'**
  String get action_name_httpRequest;

  /// No description provided for @action_name_setGlobalVariable.
  ///
  /// In en, this message translates to:
  /// **'Set Global Variable'**
  String get action_name_setGlobalVariable;

  /// No description provided for @action_name_getGlobalVariable.
  ///
  /// In en, this message translates to:
  /// **'Get Global Variable'**
  String get action_name_getGlobalVariable;

  /// No description provided for @action_name_removeGlobalVariable.
  ///
  /// In en, this message translates to:
  /// **'Remove Global Variable'**
  String get action_name_removeGlobalVariable;

  /// No description provided for @action_name_setScopedVariable.
  ///
  /// In en, this message translates to:
  /// **'Set Scoped Variable'**
  String get action_name_setScopedVariable;

  /// No description provided for @action_name_getScopedVariable.
  ///
  /// In en, this message translates to:
  /// **'Get Scoped Variable'**
  String get action_name_getScopedVariable;

  /// No description provided for @action_name_removeScopedVariable.
  ///
  /// In en, this message translates to:
  /// **'Remove Scoped Variable'**
  String get action_name_removeScopedVariable;

  /// No description provided for @action_name_renameScopedVariable.
  ///
  /// In en, this message translates to:
  /// **'Rename Scoped Variable'**
  String get action_name_renameScopedVariable;

  /// No description provided for @action_name_listScopedVariableIndex.
  ///
  /// In en, this message translates to:
  /// **'List Scoped Variable Index'**
  String get action_name_listScopedVariableIndex;

  /// No description provided for @action_name_appendArrayElement.
  ///
  /// In en, this message translates to:
  /// **'Append Array Element'**
  String get action_name_appendArrayElement;

  /// No description provided for @action_name_removeArrayElement.
  ///
  /// In en, this message translates to:
  /// **'Remove Array Element'**
  String get action_name_removeArrayElement;

  /// No description provided for @action_name_queryArray.
  ///
  /// In en, this message translates to:
  /// **'Query Array'**
  String get action_name_queryArray;

  /// No description provided for @action_name_runWorkflow.
  ///
  /// In en, this message translates to:
  /// **'Run Workflow'**
  String get action_name_runWorkflow;

  /// No description provided for @action_name_runBdfdScript.
  ///
  /// In en, this message translates to:
  /// **'Run BDFD Script'**
  String get action_name_runBdfdScript;

  /// No description provided for @action_name_respondWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Respond with Message'**
  String get action_name_respondWithMessage;

  /// No description provided for @action_name_respondWithComponentV2.
  ///
  /// In en, this message translates to:
  /// **'Respond with Component V2'**
  String get action_name_respondWithComponentV2;

  /// No description provided for @action_name_respondWithModal.
  ///
  /// In en, this message translates to:
  /// **'Respond with Modal'**
  String get action_name_respondWithModal;

  /// No description provided for @action_name_editInteractionMessage.
  ///
  /// In en, this message translates to:
  /// **'Edit Interaction Message'**
  String get action_name_editInteractionMessage;

  /// No description provided for @action_name_listenForButtonClick.
  ///
  /// In en, this message translates to:
  /// **'Listen for Button Click'**
  String get action_name_listenForButtonClick;

  /// No description provided for @action_name_listenForSelectMenu.
  ///
  /// In en, this message translates to:
  /// **'Listen for Select Menu'**
  String get action_name_listenForSelectMenu;

  /// No description provided for @action_name_listenForModalSubmit.
  ///
  /// In en, this message translates to:
  /// **'Listen for Modal Submit'**
  String get action_name_listenForModalSubmit;

  /// No description provided for @action_name_respondWithAutocomplete.
  ///
  /// In en, this message translates to:
  /// **'Respond with Autocomplete'**
  String get action_name_respondWithAutocomplete;

  /// No description provided for @action_name_stopUnless.
  ///
  /// In en, this message translates to:
  /// **'Stop Unless Condition'**
  String get action_name_stopUnless;

  /// No description provided for @action_name_ifBlock.
  ///
  /// In en, this message translates to:
  /// **'IF / ELSE Block'**
  String get action_name_ifBlock;

  /// No description provided for @action_name_calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get action_name_calculate;

  /// No description provided for @action_name_getMessage.
  ///
  /// In en, this message translates to:
  /// **'Get Message'**
  String get action_name_getMessage;

  /// No description provided for @action_name_unpinMessage.
  ///
  /// In en, this message translates to:
  /// **'Unpin Message'**
  String get action_name_unpinMessage;

  /// No description provided for @action_name_createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create Poll'**
  String get action_name_createPoll;

  /// No description provided for @action_name_endPoll.
  ///
  /// In en, this message translates to:
  /// **'End Poll'**
  String get action_name_endPoll;

  /// No description provided for @action_name_createInvite.
  ///
  /// In en, this message translates to:
  /// **'Create Invite'**
  String get action_name_createInvite;

  /// No description provided for @action_name_deleteInvite.
  ///
  /// In en, this message translates to:
  /// **'Delete Invite'**
  String get action_name_deleteInvite;

  /// No description provided for @action_name_getInvite.
  ///
  /// In en, this message translates to:
  /// **'Get Invite'**
  String get action_name_getInvite;

  /// No description provided for @action_name_moveToVoiceChannel.
  ///
  /// In en, this message translates to:
  /// **'Move to Voice Channel'**
  String get action_name_moveToVoiceChannel;

  /// No description provided for @action_name_disconnectFromVoice.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from Voice'**
  String get action_name_disconnectFromVoice;

  /// No description provided for @action_name_serverMuteMember.
  ///
  /// In en, this message translates to:
  /// **'Server Mute Member'**
  String get action_name_serverMuteMember;

  /// No description provided for @action_name_serverDeafenMember.
  ///
  /// In en, this message translates to:
  /// **'Server Deafen Member'**
  String get action_name_serverDeafenMember;

  /// No description provided for @action_name_createEmoji.
  ///
  /// In en, this message translates to:
  /// **'Create Emoji'**
  String get action_name_createEmoji;

  /// No description provided for @action_name_updateEmoji.
  ///
  /// In en, this message translates to:
  /// **'Update Emoji'**
  String get action_name_updateEmoji;

  /// No description provided for @action_name_deleteEmoji.
  ///
  /// In en, this message translates to:
  /// **'Delete Emoji'**
  String get action_name_deleteEmoji;

  /// No description provided for @action_name_createAutoModRule.
  ///
  /// In en, this message translates to:
  /// **'Create AutoMod Rule'**
  String get action_name_createAutoModRule;

  /// No description provided for @action_name_deleteAutoModRule.
  ///
  /// In en, this message translates to:
  /// **'Delete AutoMod Rule'**
  String get action_name_deleteAutoModRule;

  /// No description provided for @action_name_listAutoModRules.
  ///
  /// In en, this message translates to:
  /// **'List AutoMod Rules'**
  String get action_name_listAutoModRules;

  /// No description provided for @action_name_getGuildOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Get Guild Onboarding'**
  String get action_name_getGuildOnboarding;

  /// No description provided for @action_name_updateGuildOnboarding.
  ///
  /// In en, this message translates to:
  /// **'Update Guild Onboarding'**
  String get action_name_updateGuildOnboarding;

  /// No description provided for @action_name_updateSelfUser.
  ///
  /// In en, this message translates to:
  /// **'Update Self User (Bot Profile)'**
  String get action_name_updateSelfUser;

  /// No description provided for @action_name_createThread.
  ///
  /// In en, this message translates to:
  /// **'Create Thread'**
  String get action_name_createThread;

  /// No description provided for @action_name_editChannelPermissions.
  ///
  /// In en, this message translates to:
  /// **'Edit Channel Permissions'**
  String get action_name_editChannelPermissions;

  /// No description provided for @action_name_deleteChannelPermission.
  ///
  /// In en, this message translates to:
  /// **'Delete Channel Permission'**
  String get action_name_deleteChannelPermission;

  /// No description provided for @home_token_missing.
  ///
  /// In en, this message translates to:
  /// **'Token not found for {botName}'**
  String home_token_missing(String botName);

  /// No description provided for @home_log_start_requested.
  ///
  /// In en, this message translates to:
  /// **'Bot start requested'**
  String get home_log_start_requested;

  /// No description provided for @home_log_stop_requested.
  ///
  /// In en, this message translates to:
  /// **'Bot stop requested'**
  String get home_log_stop_requested;

  /// No description provided for @home_notification_permission_required.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to start the bot.'**
  String get home_notification_permission_required;

  /// No description provided for @home_foreground_service_not_started.
  ///
  /// In en, this message translates to:
  /// **'The foreground service did not start.'**
  String get home_foreground_service_not_started;

  /// No description provided for @home_log_desktop_stop_requested.
  ///
  /// In en, this message translates to:
  /// **'Desktop bot stop requested'**
  String get home_log_desktop_stop_requested;

  /// No description provided for @home_unknown_app.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get home_unknown_app;

  /// No description provided for @home_status_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get home_status_online;

  /// No description provided for @home_status_offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get home_status_offline;

  /// No description provided for @home_server_count_one.
  ///
  /// In en, this message translates to:
  /// **'{count} server'**
  String home_server_count_one(String count);

  /// No description provided for @home_server_count_other.
  ///
  /// In en, this message translates to:
  /// **'{count} servers'**
  String home_server_count_other(String count);

  /// No description provided for @home_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get home_stop;

  /// No description provided for @home_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get home_start;

  /// No description provided for @home_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get home_manage;

  /// No description provided for @home_logs_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Bot logs'**
  String get home_logs_tooltip;

  /// No description provided for @rewarded_start_title.
  ///
  /// In en, this message translates to:
  /// **'Support Bot Creator'**
  String get rewarded_start_title;

  /// No description provided for @rewarded_start_message.
  ///
  /// In en, this message translates to:
  /// **'This ad helps fund the app and can only appear when you press Start. If no ad can be shown, the bot will still start normally.'**
  String get rewarded_start_message;

  /// No description provided for @rewarded_start_watch.
  ///
  /// In en, this message translates to:
  /// **'Watch ad'**
  String get rewarded_start_watch;

  /// No description provided for @rewarded_start_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get rewarded_start_continue;

  /// No description provided for @rewarded_start_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get rewarded_start_skip;

  /// No description provided for @rewarded_start_thanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your support!'**
  String get rewarded_start_thanks;

  /// No description provided for @ads_consent_title.
  ///
  /// In en, this message translates to:
  /// **'Ads consent'**
  String get ads_consent_title;

  /// No description provided for @ads_consent_message.
  ///
  /// In en, this message translates to:
  /// **'To comply with GDPR, we need your consent before showing ads. You can continue using the app even if you refuse.'**
  String get ads_consent_message;

  /// No description provided for @ads_consent_accept.
  ///
  /// In en, this message translates to:
  /// **'I accept'**
  String get ads_consent_accept;

  /// No description provided for @ads_consent_refuse.
  ///
  /// In en, this message translates to:
  /// **'I refuse'**
  String get ads_consent_refuse;

  /// No description provided for @ads_consent_refused_info.
  ///
  /// In en, this message translates to:
  /// **'Ad consent declined. The bot will still start normally.'**
  String get ads_consent_refused_info;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @error_with_details.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error_with_details(String error);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @bot_home_start.
  ///
  /// In en, this message translates to:
  /// **'Start Bot'**
  String get bot_home_start;

  /// No description provided for @bot_home_starting.
  ///
  /// In en, this message translates to:
  /// **'Starting…'**
  String get bot_home_starting;

  /// No description provided for @bot_home_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop Bot'**
  String get bot_home_stop;

  /// No description provided for @bot_home_ios_notice_title.
  ///
  /// In en, this message translates to:
  /// **'Local iOS constraint'**
  String get bot_home_ios_notice_title;

  /// No description provided for @bot_home_ios_notice_content.
  ///
  /// In en, this message translates to:
  /// **'In local mode, iOS may suspend the app in the background. The bot can start, but keeping the Discord connection alive is not guaranteed like it is with a Runner.'**
  String get bot_home_ios_notice_content;

  /// No description provided for @bot_home_view_logs.
  ///
  /// In en, this message translates to:
  /// **'View bot logs'**
  String get bot_home_view_logs;

  /// No description provided for @bot_home_view_stats.
  ///
  /// In en, this message translates to:
  /// **'View bot stats'**
  String get bot_home_view_stats;

  /// No description provided for @bot_home_view_replay.
  ///
  /// In en, this message translates to:
  /// **'View debugger replays'**
  String get bot_home_view_replay;

  /// No description provided for @bot_home_section_monitoring.
  ///
  /// In en, this message translates to:
  /// **'MONITORING'**
  String get bot_home_section_monitoring;

  /// No description provided for @bot_home_section_tools.
  ///
  /// In en, this message translates to:
  /// **'TOOLS'**
  String get bot_home_section_tools;

  /// No description provided for @bot_home_section_danger.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get bot_home_section_danger;

  /// No description provided for @bot_home_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync App'**
  String get bot_home_sync;

  /// No description provided for @bot_home_sync_success.
  ///
  /// In en, this message translates to:
  /// **'App synced successfully'**
  String get bot_home_sync_success;

  /// No description provided for @bot_home_invite.
  ///
  /// In en, this message translates to:
  /// **'Invite Bot'**
  String get bot_home_invite;

  /// No description provided for @bot_home_invite_error.
  ///
  /// In en, this message translates to:
  /// **'Could not open invite link'**
  String get bot_home_invite_error;

  /// No description provided for @bot_home_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete App'**
  String get bot_home_delete;

  /// No description provided for @bot_home_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this app?'**
  String get bot_home_delete_confirm;

  /// No description provided for @bot_home_start_error.
  ///
  /// In en, this message translates to:
  /// **'Could not start: {error}'**
  String bot_home_start_error(String error);

  /// No description provided for @bot_home_log_start.
  ///
  /// In en, this message translates to:
  /// **'Bot start requested'**
  String get bot_home_log_start;

  /// No description provided for @bot_home_log_stop.
  ///
  /// In en, this message translates to:
  /// **'Bot stop requested'**
  String get bot_home_log_stop;

  /// No description provided for @bot_home_log_desktop_stop.
  ///
  /// In en, this message translates to:
  /// **'Desktop bot stop requested'**
  String get bot_home_log_desktop_stop;

  /// No description provided for @bot_home_notif_required.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required to start the bot service.'**
  String get bot_home_notif_required;

  /// No description provided for @bot_home_service_not_started.
  ///
  /// In en, this message translates to:
  /// **'Foreground service did not start.'**
  String get bot_home_service_not_started;

  /// No description provided for @bot_home_token_invalid_title.
  ///
  /// In en, this message translates to:
  /// **'Token seems invalid'**
  String get bot_home_token_invalid_title;

  /// No description provided for @bot_home_token_invalid_content.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to Discord with the provided token. It may be invalid or revoked. Do you want to start the bot anyway?'**
  String get bot_home_token_invalid_content;

  /// No description provided for @bot_offline_token_desc.
  ///
  /// In en, this message translates to:
  /// **'Token invalid or missing. Enter a new Discord bot token to restore the connection.'**
  String get bot_offline_token_desc;

  /// No description provided for @cmd_offline_incomplete_warning.
  ///
  /// In en, this message translates to:
  /// **'This command could not be fully loaded (offline or token invalid). Connect a valid token to edit.'**
  String get cmd_offline_incomplete_warning;

  /// No description provided for @bot_settings_token_mismatch_title.
  ///
  /// In en, this message translates to:
  /// **'Different bot detected'**
  String get bot_settings_token_mismatch_title;

  /// No description provided for @bot_settings_token_mismatch_content.
  ///
  /// In en, this message translates to:
  /// **'This token belongs to bot {newId}, but the current data is for bot {oldId}. Commands and settings may not match. Continue anyway?'**
  String bot_settings_token_mismatch_content(String newId, String oldId);

  /// No description provided for @bot_settings_token_mismatch_confirm.
  ///
  /// In en, this message translates to:
  /// **'Replace token anyway'**
  String get bot_settings_token_mismatch_confirm;

  /// No description provided for @bot_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Application Settings'**
  String get bot_settings_title;

  /// No description provided for @bot_settings_workflow_docs.
  ///
  /// In en, this message translates to:
  /// **'Documentation Center'**
  String get bot_settings_workflow_docs;

  /// No description provided for @bot_settings_workflow_docs_desc.
  ///
  /// In en, this message translates to:
  /// **'Centralized documentation for commands, workflows, runtime variables, and execution behavior.'**
  String get bot_settings_workflow_docs_desc;

  /// No description provided for @bot_settings_export_import.
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get bot_settings_export_import;

  /// No description provided for @bot_settings_export_import_desc.
  ///
  /// In en, this message translates to:
  /// **'Export or import your bot configuration as a ZIP file.'**
  String get bot_settings_export_import_desc;

  /// No description provided for @bot_settings_app_flags.
  ///
  /// In en, this message translates to:
  /// **'Application Flags'**
  String get bot_settings_app_flags;

  /// No description provided for @bot_settings_gateway_intents.
  ///
  /// In en, this message translates to:
  /// **'Gateway Intents Configuration'**
  String get bot_settings_gateway_intents;

  /// No description provided for @bot_settings_gateway_intents_desc.
  ///
  /// In en, this message translates to:
  /// **'Select which intents your bot needs. Configure these in the Discord Developer Portal.'**
  String get bot_settings_gateway_intents_desc;

  /// No description provided for @bot_settings_token_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Token'**
  String get bot_settings_token_title;

  /// No description provided for @bot_settings_update_token.
  ///
  /// In en, this message translates to:
  /// **'Update Bot Token'**
  String get bot_settings_update_token;

  /// No description provided for @bot_settings_token_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your bot token here'**
  String get bot_settings_token_hint;

  /// No description provided for @bot_settings_save_success.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get bot_settings_save_success;

  /// No description provided for @bot_settings_save_token_btn.
  ///
  /// In en, this message translates to:
  /// **'Save token and intents'**
  String get bot_settings_save_token_btn;

  /// No description provided for @bot_settings_save_token_only_btn.
  ///
  /// In en, this message translates to:
  /// **'Save token'**
  String get bot_settings_save_token_only_btn;

  /// No description provided for @bot_settings_save_intents_btn.
  ///
  /// In en, this message translates to:
  /// **'Save intents'**
  String get bot_settings_save_intents_btn;

  /// No description provided for @bot_settings_save_profile_status_btn.
  ///
  /// In en, this message translates to:
  /// **'Save profile and statuses'**
  String get bot_settings_save_profile_status_btn;

  /// No description provided for @bot_settings_save_token_caption.
  ///
  /// In en, this message translates to:
  /// **'Token changes are protected. Click \"Edit token\" first, then save.'**
  String get bot_settings_save_token_caption;

  /// No description provided for @bot_settings_save_intents_caption.
  ///
  /// In en, this message translates to:
  /// **'This only updates gateway intents configuration.'**
  String get bot_settings_save_intents_caption;

  /// No description provided for @bot_settings_save_profile_caption.
  ///
  /// In en, this message translates to:
  /// **'This applies username/avatar instantly and saves status rotation.'**
  String get bot_settings_save_profile_caption;

  /// No description provided for @bot_settings_token_saved.
  ///
  /// In en, this message translates to:
  /// **'Token saved successfully'**
  String get bot_settings_token_saved;

  /// No description provided for @bot_settings_intents_saved.
  ///
  /// In en, this message translates to:
  /// **'Intents saved successfully'**
  String get bot_settings_intents_saved;

  /// No description provided for @bot_settings_profile_saved.
  ///
  /// In en, this message translates to:
  /// **'Profile/statuses applied successfully'**
  String get bot_settings_profile_saved;

  /// No description provided for @bot_settings_edit_token_btn.
  ///
  /// In en, this message translates to:
  /// **'Edit token'**
  String get bot_settings_edit_token_btn;

  /// No description provided for @bot_settings_cancel_token_edit_btn.
  ///
  /// In en, this message translates to:
  /// **'Cancel token edit'**
  String get bot_settings_cancel_token_edit_btn;

  /// No description provided for @bot_settings_token_hidden_desc.
  ///
  /// In en, this message translates to:
  /// **'Token input is hidden by default for safety.'**
  String get bot_settings_token_hidden_desc;

  /// No description provided for @bot_settings_token_required.
  ///
  /// In en, this message translates to:
  /// **'Bot token is required.'**
  String get bot_settings_token_required;

  /// No description provided for @bot_settings_save_token_first.
  ///
  /// In en, this message translates to:
  /// **'Please save the token first before applying profile/status changes.'**
  String get bot_settings_save_token_first;

  /// No description provided for @bot_settings_profile_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Profile'**
  String get bot_settings_profile_title;

  /// No description provided for @bot_settings_username_override.
  ///
  /// In en, this message translates to:
  /// **'Username override'**
  String get bot_settings_username_override;

  /// No description provided for @bot_settings_username_hint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to keep current username'**
  String get bot_settings_username_hint;

  /// No description provided for @bot_settings_avatar_local_path.
  ///
  /// In en, this message translates to:
  /// **'Avatar local file path'**
  String get bot_settings_avatar_local_path;

  /// No description provided for @bot_settings_avatar_path_hint.
  ///
  /// In en, this message translates to:
  /// **'/absolute/path/to/avatar.png'**
  String get bot_settings_avatar_path_hint;

  /// No description provided for @bot_settings_browse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get bot_settings_browse;

  /// No description provided for @bot_settings_avatar_selected_file.
  ///
  /// In en, this message translates to:
  /// **'Selected file: {path}'**
  String bot_settings_avatar_selected_file(String path);

  /// No description provided for @bot_settings_avatar_preview_label.
  ///
  /// In en, this message translates to:
  /// **'Avatar preview'**
  String get bot_settings_avatar_preview_label;

  /// No description provided for @bot_settings_avatar_preview_error.
  ///
  /// In en, this message translates to:
  /// **'Unable to preview image'**
  String get bot_settings_avatar_preview_error;

  /// No description provided for @bot_settings_avatar_unsupported_format.
  ///
  /// In en, this message translates to:
  /// **'Unsupported avatar format: {ext}. Supported formats: {formats}.'**
  String bot_settings_avatar_unsupported_format(String ext, String formats);

  /// No description provided for @bot_settings_avatar_clear_selection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get bot_settings_avatar_clear_selection;

  /// No description provided for @bot_settings_presence_status_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Presence Status'**
  String get bot_settings_presence_status_title;

  /// No description provided for @bot_settings_presence_status_label.
  ///
  /// In en, this message translates to:
  /// **'Presence'**
  String get bot_settings_presence_status_label;

  /// No description provided for @bot_settings_presence_online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get bot_settings_presence_online;

  /// No description provided for @bot_settings_presence_idle.
  ///
  /// In en, this message translates to:
  /// **'Idle (Away)'**
  String get bot_settings_presence_idle;

  /// No description provided for @bot_settings_presence_dnd.
  ///
  /// In en, this message translates to:
  /// **'Do Not Disturb'**
  String get bot_settings_presence_dnd;

  /// No description provided for @bot_settings_presence_invisible.
  ///
  /// In en, this message translates to:
  /// **'Invisible'**
  String get bot_settings_presence_invisible;

  /// No description provided for @bot_settings_status_rotation_title.
  ///
  /// In en, this message translates to:
  /// **'Activities Rotation'**
  String get bot_settings_status_rotation_title;

  /// No description provided for @bot_settings_status_rotation_desc.
  ///
  /// In en, this message translates to:
  /// **'Add one or more activities. Each activity needs a type, name, and min/max interval (seconds).'**
  String get bot_settings_status_rotation_desc;

  /// No description provided for @bot_settings_add_status.
  ///
  /// In en, this message translates to:
  /// **'Add activity'**
  String get bot_settings_add_status;

  /// No description provided for @bot_settings_status_item_title.
  ///
  /// In en, this message translates to:
  /// **'Activity {index}'**
  String bot_settings_status_item_title(String index);

  /// No description provided for @bot_settings_remove_status.
  ///
  /// In en, this message translates to:
  /// **'Remove activity'**
  String get bot_settings_remove_status;

  /// No description provided for @bot_settings_status_type_label.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get bot_settings_status_type_label;

  /// No description provided for @bot_settings_status_type_playing.
  ///
  /// In en, this message translates to:
  /// **'Playing'**
  String get bot_settings_status_type_playing;

  /// No description provided for @bot_settings_status_type_streaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming'**
  String get bot_settings_status_type_streaming;

  /// No description provided for @bot_settings_status_type_listening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get bot_settings_status_type_listening;

  /// No description provided for @bot_settings_status_type_watching.
  ///
  /// In en, this message translates to:
  /// **'Watching'**
  String get bot_settings_status_type_watching;

  /// No description provided for @bot_settings_status_type_competing.
  ///
  /// In en, this message translates to:
  /// **'Competing'**
  String get bot_settings_status_type_competing;

  /// No description provided for @bot_settings_status_text_label.
  ///
  /// In en, this message translates to:
  /// **'Activity name'**
  String get bot_settings_status_text_label;

  /// No description provided for @bot_settings_activity_state_label.
  ///
  /// In en, this message translates to:
  /// **'Activity state (optional)'**
  String get bot_settings_activity_state_label;

  /// No description provided for @bot_settings_activity_url_label.
  ///
  /// In en, this message translates to:
  /// **'Stream URL (for streaming)'**
  String get bot_settings_activity_url_label;

  /// No description provided for @bot_settings_status_min_interval.
  ///
  /// In en, this message translates to:
  /// **'Min interval (s)'**
  String get bot_settings_status_min_interval;

  /// No description provided for @bot_settings_status_max_interval.
  ///
  /// In en, this message translates to:
  /// **'Max interval (s)'**
  String get bot_settings_status_max_interval;

  /// No description provided for @bot_logs_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Logs'**
  String get bot_logs_title;

  /// No description provided for @bot_logs_disable_debug.
  ///
  /// In en, this message translates to:
  /// **'Disable debug logs'**
  String get bot_logs_disable_debug;

  /// No description provided for @bot_logs_enable_debug.
  ///
  /// In en, this message translates to:
  /// **'Enable debug logs'**
  String get bot_logs_enable_debug;

  /// No description provided for @bot_logs_copied.
  ///
  /// In en, this message translates to:
  /// **'Logs copied'**
  String get bot_logs_copied;

  /// No description provided for @bot_logs_oldest_first.
  ///
  /// In en, this message translates to:
  /// **'Show oldest first'**
  String get bot_logs_oldest_first;

  /// No description provided for @bot_logs_newest_first.
  ///
  /// In en, this message translates to:
  /// **'Show newest first'**
  String get bot_logs_newest_first;

  /// No description provided for @bot_logs_filter_count.
  ///
  /// In en, this message translates to:
  /// **'Number of displayed logs'**
  String get bot_logs_filter_count;

  /// No description provided for @bot_logs_show_n.
  ///
  /// In en, this message translates to:
  /// **'Show {count} logs'**
  String bot_logs_show_n(String count);

  /// No description provided for @bot_logs_show_all.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get bot_logs_show_all;

  /// No description provided for @bot_logs_empty.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get bot_logs_empty;

  /// No description provided for @bot_logs_show_more.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get bot_logs_show_more;

  /// No description provided for @bot_logs_show_less.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get bot_logs_show_less;

  /// No description provided for @bot_logs_ram.
  ///
  /// In en, this message translates to:
  /// **'Bot process RAM: {memory}'**
  String bot_logs_ram(String memory);

  /// No description provided for @bot_logs_ram_estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated bot RAM: {memory}'**
  String bot_logs_ram_estimated(String memory);

  /// No description provided for @bot_logs_go_to_latest.
  ///
  /// In en, this message translates to:
  /// **'Go to latest log'**
  String get bot_logs_go_to_latest;

  /// No description provided for @bot_logs_go_to_bottom.
  ///
  /// In en, this message translates to:
  /// **'Go to bottom'**
  String get bot_logs_go_to_bottom;

  /// No description provided for @bot_logs_raw_mode.
  ///
  /// In en, this message translates to:
  /// **'Compact raw logs'**
  String get bot_logs_raw_mode;

  /// No description provided for @bot_logs_rich_mode.
  ///
  /// In en, this message translates to:
  /// **'Rich formatted logs'**
  String get bot_logs_rich_mode;

  /// No description provided for @debug_replay_title.
  ///
  /// In en, this message translates to:
  /// **'Debugger Replay'**
  String get debug_replay_title;

  /// No description provided for @debug_replay_start_capture.
  ///
  /// In en, this message translates to:
  /// **'Enable capture'**
  String get debug_replay_start_capture;

  /// No description provided for @debug_replay_stop_capture.
  ///
  /// In en, this message translates to:
  /// **'Disable capture'**
  String get debug_replay_stop_capture;

  /// No description provided for @debug_replay_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear replays'**
  String get debug_replay_clear;

  /// No description provided for @debug_replay_clear_title.
  ///
  /// In en, this message translates to:
  /// **'Clear replays'**
  String get debug_replay_clear_title;

  /// No description provided for @debug_replay_clear_confirm.
  ///
  /// In en, this message translates to:
  /// **'All recorded replays will be deleted. Continue?'**
  String get debug_replay_clear_confirm;

  /// No description provided for @debug_replay_empty_capturing.
  ///
  /// In en, this message translates to:
  /// **'Capturing… Run a command to record a replay.'**
  String get debug_replay_empty_capturing;

  /// No description provided for @debug_replay_empty_idle.
  ///
  /// In en, this message translates to:
  /// **'Capture is off. Enable it and run a command to record a replay.'**
  String get debug_replay_empty_idle;

  /// No description provided for @debug_replay_premium_title.
  ///
  /// In en, this message translates to:
  /// **'Visual Debugger Replay'**
  String get debug_replay_premium_title;

  /// No description provided for @debug_replay_premium_desc.
  ///
  /// In en, this message translates to:
  /// **'Record and replay your command executions step by step. See exactly what each action did, how long it took, and where errors occurred.'**
  String get debug_replay_premium_desc;

  /// No description provided for @debug_replay_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get debug_replay_overview;

  /// No description provided for @debug_replay_play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get debug_replay_play;

  /// No description provided for @debug_replay_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get debug_replay_pause;

  /// No description provided for @debug_replay_step_first.
  ///
  /// In en, this message translates to:
  /// **'First step'**
  String get debug_replay_step_first;

  /// No description provided for @debug_replay_step_last.
  ///
  /// In en, this message translates to:
  /// **'Last step'**
  String get debug_replay_step_last;

  /// No description provided for @debug_replay_step_back.
  ///
  /// In en, this message translates to:
  /// **'Previous step'**
  String get debug_replay_step_back;

  /// No description provided for @debug_replay_step_forward.
  ///
  /// In en, this message translates to:
  /// **'Next step'**
  String get debug_replay_step_forward;

  /// No description provided for @debug_replay_duration_label.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get debug_replay_duration_label;

  /// No description provided for @debug_replay_result_label.
  ///
  /// In en, this message translates to:
  /// **'RESULT'**
  String get debug_replay_result_label;

  /// No description provided for @debug_replay_result_empty.
  ///
  /// In en, this message translates to:
  /// **'(no result)'**
  String get debug_replay_result_empty;

  /// No description provided for @debug_replay_start_offset.
  ///
  /// In en, this message translates to:
  /// **'+{ms} ms from start'**
  String debug_replay_start_offset(String ms);

  /// No description provided for @debug_replay_loop_info.
  ///
  /// In en, this message translates to:
  /// **'Loop depth {depth}, iteration {iteration}'**
  String debug_replay_loop_info(String depth, String iteration);

  /// No description provided for @debug_replay_variables_label.
  ///
  /// In en, this message translates to:
  /// **'VARIABLES'**
  String get debug_replay_variables_label;

  /// No description provided for @debug_replay_variables_empty.
  ///
  /// In en, this message translates to:
  /// **'(no variables)'**
  String get debug_replay_variables_empty;

  /// No description provided for @bot_stats_title.
  ///
  /// In en, this message translates to:
  /// **'Bot Stats'**
  String get bot_stats_title;

  /// No description provided for @bot_stats_ram_process.
  ///
  /// In en, this message translates to:
  /// **'Bot process RAM'**
  String get bot_stats_ram_process;

  /// No description provided for @bot_stats_ram_estimated.
  ///
  /// In en, this message translates to:
  /// **'Bot RAM only (estimated)'**
  String get bot_stats_ram_estimated;

  /// No description provided for @bot_stats_cpu.
  ///
  /// In en, this message translates to:
  /// **'Bot process CPU'**
  String get bot_stats_cpu;

  /// No description provided for @bot_stats_storage.
  ///
  /// In en, this message translates to:
  /// **'Bot storage (app data)'**
  String get bot_stats_storage;

  /// No description provided for @bot_stats_source_runner_api.
  ///
  /// In en, this message translates to:
  /// **'Source: Runner API'**
  String get bot_stats_source_runner_api;

  /// No description provided for @bot_stats_source_local_hosting.
  ///
  /// In en, this message translates to:
  /// **'Source: Local Hosting'**
  String get bot_stats_source_local_hosting;

  /// No description provided for @bot_stats_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes: CPU available on Android/Linux. Storage = bot data files in the app.'**
  String get bot_stats_notes;

  /// No description provided for @bot_stats_collecting.
  ///
  /// In en, this message translates to:
  /// **'Collecting…'**
  String get bot_stats_collecting;

  /// No description provided for @commands_title.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get commands_title;

  /// No description provided for @commands_empty.
  ///
  /// In en, this message translates to:
  /// **'No commands found'**
  String get commands_empty;

  /// No description provided for @commands_error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String commands_error(String error);

  /// No description provided for @commands_create_button.
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get commands_create_button;

  /// No description provided for @commands_move_to_folder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get commands_move_to_folder;

  /// No description provided for @commands_remove_from_folder.
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get commands_remove_from_folder;

  /// No description provided for @commands_new_folder_hint.
  ///
  /// In en, this message translates to:
  /// **'New folder name'**
  String get commands_new_folder_hint;

  /// No description provided for @commands_folder_label.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get commands_folder_label;

  /// No description provided for @commands_folder_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional folder name'**
  String get commands_folder_hint;

  /// No description provided for @commands_create_folder.
  ///
  /// In en, this message translates to:
  /// **'Create folder'**
  String get commands_create_folder;

  /// No description provided for @commands_rename_folder.
  ///
  /// In en, this message translates to:
  /// **'Rename folder'**
  String get commands_rename_folder;

  /// No description provided for @commands_delete_folder.
  ///
  /// In en, this message translates to:
  /// **'Delete folder'**
  String get commands_delete_folder;

  /// No description provided for @commands_delete_folder_desc.
  ///
  /// In en, this message translates to:
  /// **'The commands inside this folder will not be deleted, only un-foldered.'**
  String get commands_delete_folder_desc;

  /// No description provided for @commands_reorder_title.
  ///
  /// In en, this message translates to:
  /// **'Organize commands'**
  String get commands_reorder_title;

  /// No description provided for @commands_no_folder.
  ///
  /// In en, this message translates to:
  /// **'No folder'**
  String get commands_no_folder;

  /// No description provided for @export_import_title.
  ///
  /// In en, this message translates to:
  /// **'Export / Import'**
  String get export_import_title;

  /// No description provided for @export_section_title.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export_section_title;

  /// No description provided for @export_section_desc.
  ///
  /// In en, this message translates to:
  /// **'Export selected sections of your bot as a ZIP file. The bot token is never included.'**
  String get export_section_desc;

  /// No description provided for @export_commands.
  ///
  /// In en, this message translates to:
  /// **'Commands'**
  String get export_commands;

  /// No description provided for @export_workflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get export_workflows;

  /// No description provided for @export_status.
  ///
  /// In en, this message translates to:
  /// **'Status & Activities'**
  String get export_status;

  /// No description provided for @export_global_variables.
  ///
  /// In en, this message translates to:
  /// **'Global Variables'**
  String get export_global_variables;

  /// No description provided for @export_button.
  ///
  /// In en, this message translates to:
  /// **'Export ZIP'**
  String get export_button;

  /// No description provided for @import_section_title.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_section_title;

  /// No description provided for @import_section_desc.
  ///
  /// In en, this message translates to:
  /// **'Import a previously exported ZIP file. Conflicts can be resolved per item.'**
  String get import_section_desc;

  /// No description provided for @import_pick_file.
  ///
  /// In en, this message translates to:
  /// **'Select ZIP file'**
  String get import_pick_file;

  /// No description provided for @import_button.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import_button;

  /// No description provided for @import_overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get import_overwrite;

  /// No description provided for @import_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get import_skip;

  /// No description provided for @globals_title.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get globals_title;

  /// No description provided for @globals_empty.
  ///
  /// In en, this message translates to:
  /// **'No global variables yet'**
  String get globals_empty;

  /// No description provided for @globals_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a variable to store persistent data accessible by all commands.'**
  String get globals_empty_subtitle;

  /// No description provided for @globals_add.
  ///
  /// In en, this message translates to:
  /// **'Add Variable'**
  String get globals_add;

  /// No description provided for @globals_add_global.
  ///
  /// In en, this message translates to:
  /// **'Add Global Variable'**
  String get globals_add_global;

  /// No description provided for @globals_add_scoped.
  ///
  /// In en, this message translates to:
  /// **'Add Scoped Variable'**
  String get globals_add_scoped;

  /// No description provided for @globals_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Variable'**
  String get globals_edit;

  /// No description provided for @globals_edit_global.
  ///
  /// In en, this message translates to:
  /// **'Edit Global Variable'**
  String get globals_edit_global;

  /// No description provided for @globals_edit_scoped.
  ///
  /// In en, this message translates to:
  /// **'Edit Scoped Variable'**
  String get globals_edit_scoped;

  /// No description provided for @globals_key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get globals_key;

  /// No description provided for @globals_key_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. prefix, level, welcome_message'**
  String get globals_key_hint;

  /// No description provided for @globals_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get globals_value;

  /// No description provided for @globals_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Variable'**
  String get globals_delete_title;

  /// No description provided for @globals_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{key}\"?'**
  String globals_delete_confirm(String key);

  /// No description provided for @globals_search.
  ///
  /// In en, this message translates to:
  /// **'Search variables…'**
  String get globals_search;

  /// No description provided for @globals_mode_global.
  ///
  /// In en, this message translates to:
  /// **'Global'**
  String get globals_mode_global;

  /// No description provided for @globals_mode_scoped.
  ///
  /// In en, this message translates to:
  /// **'Scoped'**
  String get globals_mode_scoped;

  /// No description provided for @globals_help_global.
  ///
  /// In en, this message translates to:
  /// **'Shared across all commands. Access via \$getVar[key].'**
  String get globals_help_global;

  /// No description provided for @globals_help_scoped.
  ///
  /// In en, this message translates to:
  /// **'Stored per context (server, user, channel…). Each entry keeps a distinct value per Discord context.'**
  String get globals_help_scoped;

  /// No description provided for @globals_source_local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get globals_source_local;

  /// No description provided for @globals_source_runner.
  ///
  /// In en, this message translates to:
  /// **'Runner: {name}'**
  String globals_source_runner(String name);

  /// No description provided for @globals_value_auto_type_hint.
  ///
  /// In en, this message translates to:
  /// **'Value is auto-typed (number, boolean, JSON).'**
  String get globals_value_auto_type_hint;

  /// No description provided for @globals_copy_value.
  ///
  /// In en, this message translates to:
  /// **'Copy value'**
  String get globals_copy_value;

  /// No description provided for @globals_no_default.
  ///
  /// In en, this message translates to:
  /// **'No default value'**
  String get globals_no_default;

  /// No description provided for @globals_dialog_global_desc.
  ///
  /// In en, this message translates to:
  /// **'Global variables are shared across all commands and servers.'**
  String get globals_dialog_global_desc;

  /// No description provided for @globals_dialog_scoped_desc.
  ///
  /// In en, this message translates to:
  /// **'A scoped variable stores a separate value per {scope} context.'**
  String globals_dialog_scoped_desc(String scope);

  /// No description provided for @globals_dialog_ref_preview.
  ///
  /// In en, this message translates to:
  /// **'Usage: \$getVar[{ref}]'**
  String globals_dialog_ref_preview(String ref);

  /// No description provided for @scoped_title.
  ///
  /// In en, this message translates to:
  /// **'Scoped Variables'**
  String get scoped_title;

  /// No description provided for @scoped_empty.
  ///
  /// In en, this message translates to:
  /// **'No scoped variables defined'**
  String get scoped_empty;

  /// No description provided for @scoped_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scoped variables store a value per Discord context (user, server…). They are populated by the bot at runtime.'**
  String get scoped_empty_subtitle;

  /// No description provided for @scoped_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Scoped Variable'**
  String get scoped_delete_title;

  /// No description provided for @scoped_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{key}\" and all its stored runtime data?'**
  String scoped_delete_confirm(String key);

  /// No description provided for @scoped_default_value.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get scoped_default_value;

  /// No description provided for @scoped_default_value_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get scoped_default_value_hint;

  /// No description provided for @scoped_scope.
  ///
  /// In en, this message translates to:
  /// **'Scope'**
  String get scoped_scope;

  /// No description provided for @scoped_scope_help.
  ///
  /// In en, this message translates to:
  /// **'The entity level at which the variable is stored.'**
  String get scoped_scope_help;

  /// No description provided for @scoped_ref.
  ///
  /// In en, this message translates to:
  /// **'Reference: {ref}'**
  String scoped_ref(String ref);

  /// No description provided for @scoped_ref_legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy: {ref}'**
  String scoped_ref_legacy(String ref);

  /// No description provided for @scoped_runtime_title.
  ///
  /// In en, this message translates to:
  /// **'Runtime data — \"{key}\"'**
  String scoped_runtime_title(String key);

  /// No description provided for @scoped_runtime_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Scope: {scope} · {count} context(s) found'**
  String scoped_runtime_subtitle(String scope, String count);

  /// No description provided for @scoped_runtime_empty.
  ///
  /// In en, this message translates to:
  /// **'No runtime data.\nThis key will be populated by the bot at execution.'**
  String get scoped_runtime_empty;

  /// No description provided for @scoped_runtime_copy_all.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get scoped_runtime_copy_all;

  /// No description provided for @scoped_runtime_search.
  ///
  /// In en, this message translates to:
  /// **'Search by ID or name…'**
  String get scoped_runtime_search;

  /// No description provided for @scoped_explore_runtime.
  ///
  /// In en, this message translates to:
  /// **'Explore runtime data'**
  String get scoped_explore_runtime;

  /// No description provided for @globals_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get globals_refresh;

  /// No description provided for @globals_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get globals_retry;

  /// No description provided for @globals_scope_guild.
  ///
  /// In en, this message translates to:
  /// **'guild'**
  String get globals_scope_guild;

  /// No description provided for @globals_scope_user.
  ///
  /// In en, this message translates to:
  /// **'user'**
  String get globals_scope_user;

  /// No description provided for @globals_scope_channel.
  ///
  /// In en, this message translates to:
  /// **'channel'**
  String get globals_scope_channel;

  /// No description provided for @globals_scope_guildMember.
  ///
  /// In en, this message translates to:
  /// **'guildMember'**
  String get globals_scope_guildMember;

  /// No description provided for @globals_scope_message.
  ///
  /// In en, this message translates to:
  /// **'message'**
  String get globals_scope_message;

  /// No description provided for @workflows_title.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get workflows_title;

  /// No description provided for @workflows_empty.
  ///
  /// In en, this message translates to:
  /// **'No workflows yet'**
  String get workflows_empty;

  /// No description provided for @workflows_create.
  ///
  /// In en, this message translates to:
  /// **'Create Workflow'**
  String get workflows_create;

  /// No description provided for @workflows_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Workflow'**
  String get workflows_edit;

  /// No description provided for @workflows_name.
  ///
  /// In en, this message translates to:
  /// **'Workflow Name'**
  String get workflows_name;

  /// No description provided for @workflows_entry_point.
  ///
  /// In en, this message translates to:
  /// **'Default Entry Point'**
  String get workflows_entry_point;

  /// No description provided for @workflows_entry_point_hint.
  ///
  /// In en, this message translates to:
  /// **'Used if caller does not override it'**
  String get workflows_entry_point_hint;

  /// No description provided for @workflows_arguments.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get workflows_arguments;

  /// No description provided for @workflows_arg_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workflows_arg_name;

  /// No description provided for @workflows_arg_default.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get workflows_arg_default;

  /// No description provided for @workflows_arg_required_short.
  ///
  /// In en, this message translates to:
  /// **'Req'**
  String get workflows_arg_required_short;

  /// No description provided for @workflows_arg_hint.
  ///
  /// In en, this message translates to:
  /// **'Arguments become runtime variables as ((arg.name)) and ((workflow.arg.name)).'**
  String get workflows_arg_hint;

  /// No description provided for @workflows_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get workflows_continue;

  /// No description provided for @workflows_add_arg.
  ///
  /// In en, this message translates to:
  /// **'Add argument'**
  String get workflows_add_arg;

  /// No description provided for @workflows_docs_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Open documentation center'**
  String get workflows_docs_tooltip;

  /// No description provided for @workflows_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) • entry: {entry} • args: {args}'**
  String workflows_subtitle(String count, String entry, String args);

  /// No description provided for @workflows_event_subtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) • Listen for: {event}'**
  String workflows_event_subtitle(String count, String event);

  /// No description provided for @workflows_general_section.
  ///
  /// In en, this message translates to:
  /// **'General Workflows'**
  String get workflows_general_section;

  /// No description provided for @workflows_event_section.
  ///
  /// In en, this message translates to:
  /// **'Event Workflows'**
  String get workflows_event_section;

  /// No description provided for @workflows_type_title.
  ///
  /// In en, this message translates to:
  /// **'Workflow type'**
  String get workflows_type_title;

  /// No description provided for @workflows_type_general.
  ///
  /// In en, this message translates to:
  /// **'General workflow'**
  String get workflows_type_general;

  /// No description provided for @workflows_type_general_desc.
  ///
  /// In en, this message translates to:
  /// **'Reusable logic called from commands, buttons, modals, or other workflows.'**
  String get workflows_type_general_desc;

  /// No description provided for @workflows_type_event.
  ///
  /// In en, this message translates to:
  /// **'Event workflow'**
  String get workflows_type_event;

  /// No description provided for @workflows_type_event_desc.
  ///
  /// In en, this message translates to:
  /// **'Automatically reacts when Discord emits an event.'**
  String get workflows_type_event_desc;

  /// No description provided for @workflows_type_badge_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get workflows_type_badge_general;

  /// No description provided for @workflows_type_badge_event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get workflows_type_badge_event;

  /// No description provided for @workflows_listen_for.
  ///
  /// In en, this message translates to:
  /// **'Listen for'**
  String get workflows_listen_for;

  /// No description provided for @workflows_event_category.
  ///
  /// In en, this message translates to:
  /// **'Event category'**
  String get workflows_event_category;

  /// No description provided for @workflows_event_hint.
  ///
  /// In en, this message translates to:
  /// **'Choose the Discord event that should trigger this workflow.'**
  String get workflows_event_hint;

  /// No description provided for @workflows_event_preview.
  ///
  /// In en, this message translates to:
  /// **'Listen for: {event}'**
  String workflows_event_preview(String event);

  /// No description provided for @workflows_event_available_vars.
  ///
  /// In en, this message translates to:
  /// **'Available variables'**
  String get workflows_event_available_vars;

  /// No description provided for @workflows_event_category_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get workflows_event_category_messages;

  /// No description provided for @workflows_event_category_members.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get workflows_event_category_members;

  /// No description provided for @workflows_event_category_channels.
  ///
  /// In en, this message translates to:
  /// **'Channels'**
  String get workflows_event_category_channels;

  /// No description provided for @workflows_event_category_invites.
  ///
  /// In en, this message translates to:
  /// **'Invites'**
  String get workflows_event_category_invites;

  /// No description provided for @workflows_event_message_create.
  ///
  /// In en, this message translates to:
  /// **'Message Create'**
  String get workflows_event_message_create;

  /// No description provided for @workflows_event_message_create_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a new message is created.'**
  String get workflows_event_message_create_desc;

  /// No description provided for @workflows_event_message_update.
  ///
  /// In en, this message translates to:
  /// **'Message Update'**
  String get workflows_event_message_update;

  /// No description provided for @workflows_event_message_update_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever an existing message is edited.'**
  String get workflows_event_message_update_desc;

  /// No description provided for @workflows_event_message_delete.
  ///
  /// In en, this message translates to:
  /// **'Message Delete'**
  String get workflows_event_message_delete;

  /// No description provided for @workflows_event_message_delete_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a message is deleted.'**
  String get workflows_event_message_delete_desc;

  /// No description provided for @workflows_event_member_join.
  ///
  /// In en, this message translates to:
  /// **'Member Join'**
  String get workflows_event_member_join;

  /// No description provided for @workflows_event_member_join_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a member joins the guild.'**
  String get workflows_event_member_join_desc;

  /// No description provided for @workflows_event_member_remove.
  ///
  /// In en, this message translates to:
  /// **'Member Remove'**
  String get workflows_event_member_remove;

  /// No description provided for @workflows_event_member_remove_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a member leaves or is removed from the guild.'**
  String get workflows_event_member_remove_desc;

  /// No description provided for @workflows_event_channel_update.
  ///
  /// In en, this message translates to:
  /// **'Channel Update'**
  String get workflows_event_channel_update;

  /// No description provided for @workflows_event_channel_update_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever a channel is updated.'**
  String get workflows_event_channel_update_desc;

  /// No description provided for @workflows_event_invite_create.
  ///
  /// In en, this message translates to:
  /// **'Invite Create'**
  String get workflows_event_invite_create;

  /// No description provided for @workflows_event_invite_create_desc.
  ///
  /// In en, this message translates to:
  /// **'Triggered whenever an invite is created.'**
  String get workflows_event_invite_create_desc;

  /// No description provided for @workflows_import_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Import workflows'**
  String get workflows_import_tooltip;

  /// No description provided for @workflows_export_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy workflows'**
  String get workflows_export_tooltip;

  /// No description provided for @workflows_copy_none.
  ///
  /// In en, this message translates to:
  /// **'No workflows to copy.'**
  String get workflows_copy_none;

  /// No description provided for @workflows_copy_done_json.
  ///
  /// In en, this message translates to:
  /// **'Workflows copied as JSON.'**
  String get workflows_copy_done_json;

  /// No description provided for @workflows_copy_done_base64.
  ///
  /// In en, this message translates to:
  /// **'Workflows copied as Base64.'**
  String get workflows_copy_done_base64;

  /// No description provided for @workflows_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete workflow'**
  String get workflows_delete_title;

  /// No description provided for @workflows_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String workflows_delete_confirm(String name);

  /// No description provided for @workflows_export_json.
  ///
  /// In en, this message translates to:
  /// **'Copy as JSON'**
  String get workflows_export_json;

  /// No description provided for @workflows_export_json_desc.
  ///
  /// In en, this message translates to:
  /// **'Readable and easy to edit.'**
  String get workflows_export_json_desc;

  /// No description provided for @workflows_export_base64.
  ///
  /// In en, this message translates to:
  /// **'Copy as Base64'**
  String get workflows_export_base64;

  /// No description provided for @workflows_export_base64_desc.
  ///
  /// In en, this message translates to:
  /// **'Convenient for compact sharing.'**
  String get workflows_export_base64_desc;

  /// No description provided for @workflows_import_title.
  ///
  /// In en, this message translates to:
  /// **'Import workflows'**
  String get workflows_import_title;

  /// No description provided for @workflows_import_desc.
  ///
  /// In en, this message translates to:
  /// **'Paste a JSON payload or Base64(JSON) exported from Bot Creator.'**
  String get workflows_import_desc;

  /// No description provided for @workflows_import_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Paste the JSON or Base64 here...'**
  String get workflows_import_input_hint;

  /// No description provided for @workflows_import_overwrite.
  ///
  /// In en, this message translates to:
  /// **'Replace when the name already exists'**
  String get workflows_import_overwrite;

  /// No description provided for @workflows_import_action.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get workflows_import_action;

  /// No description provided for @workflows_import_empty.
  ///
  /// In en, this message translates to:
  /// **'No data to import.'**
  String get workflows_import_empty;

  /// No description provided for @workflows_import_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Use JSON or Base64(JSON).'**
  String get workflows_import_invalid_format;

  /// No description provided for @workflows_import_no_valid.
  ///
  /// In en, this message translates to:
  /// **'No valid workflow found.'**
  String get workflows_import_no_valid;

  /// No description provided for @workflows_import_done.
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) imported.'**
  String workflows_import_done(String count);

  /// No description provided for @workflows_move_to_folder.
  ///
  /// In en, this message translates to:
  /// **'Move to folder'**
  String get workflows_move_to_folder;

  /// No description provided for @workflows_remove_from_folder.
  ///
  /// In en, this message translates to:
  /// **'Remove from folder'**
  String get workflows_remove_from_folder;

  /// No description provided for @workflows_new_folder_hint.
  ///
  /// In en, this message translates to:
  /// **'New folder name'**
  String get workflows_new_folder_hint;

  /// No description provided for @workflows_folder_label.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get workflows_folder_label;

  /// No description provided for @workflows_folder_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional folder name'**
  String get workflows_folder_hint;

  /// No description provided for @cmd_error_fill_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get cmd_error_fill_fields;

  /// No description provided for @cmd_variables_title.
  ///
  /// In en, this message translates to:
  /// **'Command Variables'**
  String get cmd_variables_title;

  /// No description provided for @cmd_show_variables.
  ///
  /// In en, this message translates to:
  /// **'Open variable documentation'**
  String get cmd_show_variables;

  /// No description provided for @cmd_create_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get cmd_create_tooltip;

  /// No description provided for @cmd_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete command'**
  String get cmd_delete_tooltip;

  /// No description provided for @cmd_editor_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Editing mode'**
  String get cmd_editor_mode_title;

  /// No description provided for @cmd_editor_mode_simple.
  ///
  /// In en, this message translates to:
  /// **'Simplified mode'**
  String get cmd_editor_mode_simple;

  /// No description provided for @cmd_editor_mode_advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced mode'**
  String get cmd_editor_mode_advanced;

  /// No description provided for @cmd_editor_mode_simple_desc.
  ///
  /// In en, this message translates to:
  /// **'Build a command quickly with guided options and preconfigured actions.'**
  String get cmd_editor_mode_simple_desc;

  /// No description provided for @cmd_editor_mode_advanced_desc.
  ///
  /// In en, this message translates to:
  /// **'Full editor with custom response, options, and action builder.'**
  String get cmd_editor_mode_advanced_desc;

  /// No description provided for @cmd_editor_mode_switch_adv.
  ///
  /// In en, this message translates to:
  /// **'Switch to advanced mode'**
  String get cmd_editor_mode_switch_adv;

  /// No description provided for @cmd_editor_mode_switch_adv_title.
  ///
  /// In en, this message translates to:
  /// **'Switch to advanced mode?'**
  String get cmd_editor_mode_switch_adv_title;

  /// No description provided for @cmd_editor_mode_switch_adv_content.
  ///
  /// In en, this message translates to:
  /// **'This switch is one-way for this command. You won’t be able to return to simplified mode.'**
  String get cmd_editor_mode_switch_adv_content;

  /// No description provided for @cmd_editor_mode_switch_adv_confirm.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get cmd_editor_mode_switch_adv_confirm;

  /// No description provided for @cmd_editor_mode_locked.
  ///
  /// In en, this message translates to:
  /// **'Advanced mode is locked for this command.'**
  String get cmd_editor_mode_locked;

  /// No description provided for @cmd_execution_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Execution mode'**
  String get cmd_execution_mode_title;

  /// No description provided for @cmd_execution_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Command metadata stays in the visual builder. Choose how the command body should run.'**
  String get cmd_execution_mode_desc;

  /// No description provided for @cmd_execution_mode_workflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow mode'**
  String get cmd_execution_mode_workflow;

  /// No description provided for @cmd_execution_mode_workflow_desc.
  ///
  /// In en, this message translates to:
  /// **'Use the existing visual response and action builder.'**
  String get cmd_execution_mode_workflow_desc;

  /// No description provided for @cmd_execution_mode_workflow_note.
  ///
  /// In en, this message translates to:
  /// **'Workflow mode is the current production path and remains fully supported.'**
  String get cmd_execution_mode_workflow_note;

  /// No description provided for @cmd_execution_mode_bdfd.
  ///
  /// In en, this message translates to:
  /// **'BDFD Script mode'**
  String get cmd_execution_mode_bdfd;

  /// No description provided for @cmd_execution_mode_bdfd_desc.
  ///
  /// In en, this message translates to:
  /// **'Write the command body as BDFD-style script while keeping command definition visual.'**
  String get cmd_execution_mode_bdfd_desc;

  /// No description provided for @cmd_execution_mode_bdfd_note.
  ///
  /// In en, this message translates to:
  /// **'The script is compiled to internal actions. Diagnostics are shown while editing; invalid scripts fail when the command runs.'**
  String get cmd_execution_mode_bdfd_note;

  /// No description provided for @cmd_bdfd_script_label.
  ///
  /// In en, this message translates to:
  /// **'BDFD script body'**
  String get cmd_bdfd_script_label;

  /// No description provided for @cmd_bdfd_script_hint.
  ///
  /// In en, this message translates to:
  /// **'\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator'**
  String get cmd_bdfd_script_hint;

  /// No description provided for @cmd_bdfd_diagnostics_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD diagnostics'**
  String get cmd_bdfd_diagnostics_title;

  /// No description provided for @cmd_bdfd_diagnostics_clean.
  ///
  /// In en, this message translates to:
  /// **'No issue detected in the current script.'**
  String get cmd_bdfd_diagnostics_clean;

  /// No description provided for @cmd_bdfd_diagnostics_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get cmd_bdfd_diagnostics_error;

  /// No description provided for @cmd_bdfd_diagnostics_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get cmd_bdfd_diagnostics_warning;

  /// No description provided for @cmd_bdfd_script_empty_error.
  ///
  /// In en, this message translates to:
  /// **'BDFD script body cannot be empty.'**
  String get cmd_bdfd_script_empty_error;

  /// No description provided for @cmd_bdfd_script_validation_error.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script still contains diagnostics:'**
  String get cmd_bdfd_script_validation_error;

  /// No description provided for @cmd_bdfd_autocomplete_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD prefix autocomplete'**
  String get cmd_bdfd_autocomplete_title;

  /// No description provided for @cmd_bdfd_autocomplete_hint.
  ///
  /// In en, this message translates to:
  /// **'Type \$ and start writing a function name to get quick script suggestions.'**
  String get cmd_bdfd_autocomplete_hint;

  /// No description provided for @workflow_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Workflow mode'**
  String get workflow_mode_title;

  /// No description provided for @workflow_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose between a visual action builder or a full BDFD scripting editor.'**
  String get workflow_mode_desc;

  /// No description provided for @workflow_mode_visual.
  ///
  /// In en, this message translates to:
  /// **'Visual'**
  String get workflow_mode_visual;

  /// No description provided for @workflow_mode_bdfd.
  ///
  /// In en, this message translates to:
  /// **'BDFD Script'**
  String get workflow_mode_bdfd;

  /// No description provided for @workflow_mode_visual_note.
  ///
  /// In en, this message translates to:
  /// **'Build your workflow visually by adding individual actions with the card editor.'**
  String get workflow_mode_visual_note;

  /// No description provided for @workflow_mode_bdfd_note.
  ///
  /// In en, this message translates to:
  /// **'Write your entire workflow as a single BDFD script. The script is compiled and validated in real time.'**
  String get workflow_mode_bdfd_note;

  /// No description provided for @workflow_bdfd_editor_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD Script Editor'**
  String get workflow_bdfd_editor_title;

  /// No description provided for @workflow_bdfd_editor_desc.
  ///
  /// In en, this message translates to:
  /// **'Write the complete BDFD code for this workflow response. Diagnostics are displayed live.'**
  String get workflow_bdfd_editor_desc;

  /// No description provided for @bdfd_editor_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD Editor'**
  String get bdfd_editor_title;

  /// No description provided for @bdfd_editor_tap_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to open editor'**
  String get bdfd_editor_tap_hint;

  /// No description provided for @bdfd_editor_wrap_toggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle line wrapping'**
  String get bdfd_editor_wrap_toggle;

  /// No description provided for @bdfd_editor_diagnostics_toggle.
  ///
  /// In en, this message translates to:
  /// **'Toggle diagnostics panel'**
  String get bdfd_editor_diagnostics_toggle;

  /// No description provided for @bdfd_editor_empty.
  ///
  /// In en, this message translates to:
  /// **'Empty script — start typing to see diagnostics.'**
  String get bdfd_editor_empty;

  /// No description provided for @bdfd_editor_docs.
  ///
  /// In en, this message translates to:
  /// **'BDFD Functions Reference'**
  String get bdfd_editor_docs;

  /// No description provided for @bdfd_docs_title.
  ///
  /// In en, this message translates to:
  /// **'BDFD Docs'**
  String get bdfd_docs_title;

  /// No description provided for @bdfd_docs_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search functions…'**
  String get bdfd_docs_search_hint;

  /// No description provided for @bdfd_docs_empty.
  ///
  /// In en, this message translates to:
  /// **'No matching functions.'**
  String get bdfd_docs_empty;

  /// No description provided for @bdfd_docs_syntax.
  ///
  /// In en, this message translates to:
  /// **'SYNTAX'**
  String get bdfd_docs_syntax;

  /// No description provided for @bdfd_docs_parameters.
  ///
  /// In en, this message translates to:
  /// **'PARAMETERS'**
  String get bdfd_docs_parameters;

  /// No description provided for @bdfd_docs_no_params.
  ///
  /// In en, this message translates to:
  /// **'No parameters — use as \$functionName'**
  String get bdfd_docs_no_params;

  /// No description provided for @bdfd_docs_category_messages.
  ///
  /// In en, this message translates to:
  /// **'Messages & Content'**
  String get bdfd_docs_category_messages;

  /// No description provided for @bdfd_docs_category_embeds.
  ///
  /// In en, this message translates to:
  /// **'Embeds'**
  String get bdfd_docs_category_embeds;

  /// No description provided for @bdfd_docs_category_components.
  ///
  /// In en, this message translates to:
  /// **'Components'**
  String get bdfd_docs_category_components;

  /// No description provided for @bdfd_docs_category_modals.
  ///
  /// In en, this message translates to:
  /// **'Modals'**
  String get bdfd_docs_category_modals;

  /// No description provided for @bdfd_docs_category_control.
  ///
  /// In en, this message translates to:
  /// **'Control Flow'**
  String get bdfd_docs_category_control;

  /// No description provided for @bdfd_docs_category_guards.
  ///
  /// In en, this message translates to:
  /// **'Guards & Permissions'**
  String get bdfd_docs_category_guards;

  /// No description provided for @bdfd_docs_category_moderation.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get bdfd_docs_category_moderation;

  /// No description provided for @bdfd_docs_category_variables.
  ///
  /// In en, this message translates to:
  /// **'Variables'**
  String get bdfd_docs_category_variables;

  /// No description provided for @bdfd_docs_category_json.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get bdfd_docs_category_json;

  /// No description provided for @bdfd_docs_category_http.
  ///
  /// In en, this message translates to:
  /// **'HTTP Requests'**
  String get bdfd_docs_category_http;

  /// No description provided for @bdfd_docs_category_math.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get bdfd_docs_category_math;

  /// No description provided for @bdfd_docs_category_text.
  ///
  /// In en, this message translates to:
  /// **'Text & Strings'**
  String get bdfd_docs_category_text;

  /// No description provided for @bdfd_docs_category_channels.
  ///
  /// In en, this message translates to:
  /// **'Channels & Threads'**
  String get bdfd_docs_category_channels;

  /// No description provided for @bdfd_docs_category_roles.
  ///
  /// In en, this message translates to:
  /// **'Roles'**
  String get bdfd_docs_category_roles;

  /// No description provided for @bdfd_docs_category_reactions.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get bdfd_docs_category_reactions;

  /// No description provided for @bdfd_docs_category_cooldowns.
  ///
  /// In en, this message translates to:
  /// **'Cooldowns'**
  String get bdfd_docs_category_cooldowns;

  /// No description provided for @bdfd_docs_category_webhooks.
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get bdfd_docs_category_webhooks;

  /// No description provided for @bdfd_docs_category_leaderboards.
  ///
  /// In en, this message translates to:
  /// **'Leaderboards'**
  String get bdfd_docs_category_leaderboards;

  /// No description provided for @bdfd_docs_category_tickets.
  ///
  /// In en, this message translates to:
  /// **'Tickets'**
  String get bdfd_docs_category_tickets;

  /// No description provided for @bdfd_docs_category_misc.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get bdfd_docs_category_misc;

  /// No description provided for @bdfd_docs_desc_for.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Repeats a block of code N times.\n\nSimple: \$for[5]...\$endfor → the body is repeated 5 times (max 100). You can use \$i for the current index (starting at 0) and \$loopCount for the total.\n\nC-style: \$for[i=0;i<10;i++]...\$endfor → classic for loop with init, condition and update. Supports ++, --, +=, -=, *=.\n\nIf the iteration count is dynamic (e.g. \$for[\$args[1]]), the loop runs at runtime instead of compile-time.'**
  String get bdfd_docs_desc_for;

  /// No description provided for @bdfd_docs_desc_loop.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Alias for \$for. See \$for for details. Use \$endloop to close the block.'**
  String get bdfd_docs_desc_loop;

  /// No description provided for @bdfd_docs_desc_callworkflow.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Calls another workflow by name and passes arguments.\n\nSyntax: \$callWorkflow[myWorkflow;key1=value1;key2=value2]\n\nThe called workflow can read arguments and return a value via \$workflowResponse.'**
  String get bdfd_docs_desc_callworkflow;

  /// No description provided for @bdfd_docs_desc_workflowresponse.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator only — Returns the response from the last \$callWorkflow.\n\nUse \$workflowResponse[] for the full response, or \$workflowResponse[property] to access a specific field.'**
  String get bdfd_docs_desc_workflowresponse;

  /// No description provided for @bdfd_docs_desc_eval.
  ///
  /// In en, this message translates to:
  /// **'Executes a BDFD script string at runtime. The code passed as argument is re-compiled and executed dynamically. Useful for running user-provided or variable-based scripts.'**
  String get bdfd_docs_desc_eval;

  /// No description provided for @bdfd_docs_desc_if.
  ///
  /// In en, this message translates to:
  /// **'Conditional block. Supports nesting and rich operators: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUsage:\n\$if[\$authorID==123456]\n  Hello admin!\n\$elseif[\$hasRole[789]]\n  Hello member!\n\$else\n  Hello guest!\n\$endif'**
  String get bdfd_docs_desc_if;

  /// No description provided for @bdfd_docs_desc_elseif.
  ///
  /// In en, this message translates to:
  /// **'Adds an alternative condition inside an \$if block. Must appear between \$if and \$else/\$endif.'**
  String get bdfd_docs_desc_elseif;

  /// No description provided for @bdfd_docs_desc_try.
  ///
  /// In en, this message translates to:
  /// **'Wraps a block for error handling.\n\nUsage:\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  Request failed!\n\$endtry\n\nIf any function in the \$try block fails, execution jumps to \$catch.'**
  String get bdfd_docs_desc_try;

  /// No description provided for @bdfd_docs_desc_stop.
  ///
  /// In en, this message translates to:
  /// **'Immediately stops execution of the current script. No further actions after \$stop will run.'**
  String get bdfd_docs_desc_stop;

  /// No description provided for @bdfd_docs_desc_suppresserrors.
  ///
  /// In en, this message translates to:
  /// **'Prevents error messages from being sent to the user. If any action fails, the error is silently suppressed.'**
  String get bdfd_docs_desc_suppresserrors;

  /// No description provided for @bdfd_docs_desc_embedsuppresserrors.
  ///
  /// In en, this message translates to:
  /// **'Same as \$suppressErrors — suppresses all error messages silently.'**
  String get bdfd_docs_desc_embedsuppresserrors;

  /// No description provided for @bdfd_docs_desc_and.
  ///
  /// In en, this message translates to:
  /// **'Logical AND — combines multiple conditions. All must be true.\n\nUsage: \$if[\$and[\$authorID==123;\$hasRole[456]]]'**
  String get bdfd_docs_desc_and;

  /// No description provided for @bdfd_docs_desc_or.
  ///
  /// In en, this message translates to:
  /// **'Logical OR — combines multiple conditions. At least one must be true.\n\nUsage: \$if[\$or[\$authorID==123;\$authorID==456]]]'**
  String get bdfd_docs_desc_or;

  /// No description provided for @bdfd_docs_desc_awaitfunc.
  ///
  /// In en, this message translates to:
  /// **'Registers a callback that waits for a user response.\n\nUsage: \$awaitFunc[name;userID (opt);channelID (opt)]\n\nThe awaited function is stored and triggered when the target user sends a message in the target channel.'**
  String get bdfd_docs_desc_awaitfunc;

  /// No description provided for @bdfd_docs_desc_defer.
  ///
  /// In en, this message translates to:
  /// **'Defers the interaction response, giving you more time to process. The user sees a \"Bot is thinking…\" message. Use before long operations like HTTP requests.'**
  String get bdfd_docs_desc_defer;

  /// No description provided for @bdfd_docs_desc_ephemeral.
  ///
  /// In en, this message translates to:
  /// **'Makes the response visible only to the user who triggered the command. Must be placed before any response content.'**
  String get bdfd_docs_desc_ephemeral;

  /// No description provided for @bdfd_docs_desc_jsonparse.
  ///
  /// In en, this message translates to:
  /// **'Parses a JSON string into memory for manipulation. All JSON operations (\$jsonSet, \$json, etc.) operate on this parsed context.\n\nStatic JSON is resolved at compile-time for better performance.'**
  String get bdfd_docs_desc_jsonparse;

  /// No description provided for @bdfd_docs_desc_jsonset.
  ///
  /// In en, this message translates to:
  /// **'Sets a value in the current JSON context. Supports dot-notation paths.\n\nUsage: \$jsonSet[user.name;John]\n\nThe change is applied in memory — use \$jsonStringify to get the result.'**
  String get bdfd_docs_desc_jsonset;

  /// No description provided for @bdfd_docs_desc_jsonstringify.
  ///
  /// In en, this message translates to:
  /// **'Converts the current JSON context back to a string. Use after \$jsonParse and \$jsonSet operations to output the result.'**
  String get bdfd_docs_desc_jsonstringify;

  /// No description provided for @bdfd_docs_desc_httpget.
  ///
  /// In en, this message translates to:
  /// **'Sends an HTTP GET request to the given URL. Use \$httpAddHeader before to set headers. Use \$httpResult to read the response.\n\nAll HTTP methods (GET, POST, PUT, PATCH, DELETE) follow the same pattern.'**
  String get bdfd_docs_desc_httpget;

  /// No description provided for @bdfd_docs_desc_httpaddheader.
  ///
  /// In en, this message translates to:
  /// **'Adds a header to the next HTTP request. Headers are accumulated until the next \$httpGet/\$httpPost/etc.\n\nUsage: \$httpAddHeader[Authorization;Bearer token123]'**
  String get bdfd_docs_desc_httpaddheader;

  /// No description provided for @bdfd_docs_desc_httpresult.
  ///
  /// In en, this message translates to:
  /// **'Returns the body of the last HTTP response. Optionally pass a JSON path to extract a specific field.\n\nUsage: \$httpResult[] for the full body, or \$httpResult[data.name] for a nested field.'**
  String get bdfd_docs_desc_httpresult;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @cmd_simple_actions_title.
  ///
  /// In en, this message translates to:
  /// **'Simplified actions'**
  String get cmd_simple_actions_title;

  /// No description provided for @cmd_simple_actions_desc.
  ///
  /// In en, this message translates to:
  /// **'Select what this command should do. Options are generated automatically.'**
  String get cmd_simple_actions_desc;

  /// No description provided for @cmd_simple_group_moderation_title.
  ///
  /// In en, this message translates to:
  /// **'Moderation'**
  String get cmd_simple_group_moderation_title;

  /// No description provided for @cmd_simple_group_moderation_desc.
  ///
  /// In en, this message translates to:
  /// **'Member and moderation actions with guided options.'**
  String get cmd_simple_group_moderation_desc;

  /// No description provided for @cmd_simple_group_messages_title.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get cmd_simple_group_messages_title;

  /// No description provided for @cmd_simple_group_messages_desc.
  ///
  /// In en, this message translates to:
  /// **'Message and channel actions that work in the current context.'**
  String get cmd_simple_group_messages_desc;

  /// No description provided for @cmd_simple_group_utility_title.
  ///
  /// In en, this message translates to:
  /// **'Utility'**
  String get cmd_simple_group_utility_title;

  /// No description provided for @cmd_simple_group_utility_desc.
  ///
  /// In en, this message translates to:
  /// **'Helpful extras such as invites and polls.'**
  String get cmd_simple_group_utility_desc;

  /// No description provided for @cmd_simple_action_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete messages'**
  String get cmd_simple_action_delete;

  /// No description provided for @cmd_simple_action_delete_desc.
  ///
  /// In en, this message translates to:
  /// **'Delete messages in the current channel (optional /count).'**
  String get cmd_simple_action_delete_desc;

  /// No description provided for @cmd_simple_action_kick.
  ///
  /// In en, this message translates to:
  /// **'Kick user'**
  String get cmd_simple_action_kick;

  /// No description provided for @cmd_simple_action_kick_desc.
  ///
  /// In en, this message translates to:
  /// **'Kick the selected /user from the server.'**
  String get cmd_simple_action_kick_desc;

  /// No description provided for @cmd_simple_action_ban.
  ///
  /// In en, this message translates to:
  /// **'Ban user'**
  String get cmd_simple_action_ban;

  /// No description provided for @cmd_simple_action_ban_desc.
  ///
  /// In en, this message translates to:
  /// **'Ban the selected /user from the server.'**
  String get cmd_simple_action_ban_desc;

  /// No description provided for @cmd_simple_action_unban.
  ///
  /// In en, this message translates to:
  /// **'Unban user'**
  String get cmd_simple_action_unban;

  /// No description provided for @cmd_simple_action_unban_desc.
  ///
  /// In en, this message translates to:
  /// **'Unban a user with a provided /user_id string.'**
  String get cmd_simple_action_unban_desc;

  /// No description provided for @cmd_simple_action_mute.
  ///
  /// In en, this message translates to:
  /// **'Mute user'**
  String get cmd_simple_action_mute;

  /// No description provided for @cmd_simple_action_mute_desc.
  ///
  /// In en, this message translates to:
  /// **'Temporarily mute the selected /user.'**
  String get cmd_simple_action_mute_desc;

  /// No description provided for @cmd_simple_action_unmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute user'**
  String get cmd_simple_action_unmute;

  /// No description provided for @cmd_simple_action_unmute_desc.
  ///
  /// In en, this message translates to:
  /// **'Remove the timeout from the selected /user.'**
  String get cmd_simple_action_unmute_desc;

  /// No description provided for @cmd_simple_action_add_role.
  ///
  /// In en, this message translates to:
  /// **'Add role'**
  String get cmd_simple_action_add_role;

  /// No description provided for @cmd_simple_action_add_role_desc.
  ///
  /// In en, this message translates to:
  /// **'Give the selected /role to the selected /user.'**
  String get cmd_simple_action_add_role_desc;

  /// No description provided for @cmd_simple_action_remove_role.
  ///
  /// In en, this message translates to:
  /// **'Remove role'**
  String get cmd_simple_action_remove_role;

  /// No description provided for @cmd_simple_action_remove_role_desc.
  ///
  /// In en, this message translates to:
  /// **'Remove the selected /role from the selected /user.'**
  String get cmd_simple_action_remove_role_desc;

  /// No description provided for @cmd_simple_action_send_message.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get cmd_simple_action_send_message;

  /// No description provided for @cmd_simple_action_send_message_desc.
  ///
  /// In en, this message translates to:
  /// **'Send an additional message in the current channel.'**
  String get cmd_simple_action_send_message_desc;

  /// No description provided for @cmd_simple_action_pin.
  ///
  /// In en, this message translates to:
  /// **'Pin message'**
  String get cmd_simple_action_pin;

  /// No description provided for @cmd_simple_action_pin_desc.
  ///
  /// In en, this message translates to:
  /// **'Pin a message in the current channel using /message_id.'**
  String get cmd_simple_action_pin_desc;

  /// No description provided for @cmd_simple_action_unpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin message'**
  String get cmd_simple_action_unpin;

  /// No description provided for @cmd_simple_action_unpin_desc.
  ///
  /// In en, this message translates to:
  /// **'Unpin a message in the current channel using /message_id.'**
  String get cmd_simple_action_unpin_desc;

  /// No description provided for @cmd_simple_action_create_invite.
  ///
  /// In en, this message translates to:
  /// **'Create invite'**
  String get cmd_simple_action_create_invite;

  /// No description provided for @cmd_simple_action_create_invite_desc.
  ///
  /// In en, this message translates to:
  /// **'Create an invite for the current channel or an optional /channel.'**
  String get cmd_simple_action_create_invite_desc;

  /// No description provided for @cmd_simple_action_create_poll.
  ///
  /// In en, this message translates to:
  /// **'Create poll'**
  String get cmd_simple_action_create_poll;

  /// No description provided for @cmd_simple_action_create_poll_desc.
  ///
  /// In en, this message translates to:
  /// **'Create a poll with a dynamic /question and fixed answer choices.'**
  String get cmd_simple_action_create_poll_desc;

  /// No description provided for @cmd_simple_action_send_message_label.
  ///
  /// In en, this message translates to:
  /// **'Action message'**
  String get cmd_simple_action_send_message_label;

  /// No description provided for @cmd_simple_action_send_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Message sent by the Send Message action'**
  String get cmd_simple_action_send_message_hint;

  /// No description provided for @cmd_simple_execution_title.
  ///
  /// In en, this message translates to:
  /// **'Execution settings'**
  String get cmd_simple_execution_title;

  /// No description provided for @cmd_simple_execution_desc.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune the generated actions without leaving simplified mode.'**
  String get cmd_simple_execution_desc;

  /// No description provided for @cmd_simple_action_reason_label.
  ///
  /// In en, this message translates to:
  /// **'Audit log reason'**
  String get cmd_simple_action_reason_label;

  /// No description provided for @cmd_simple_action_reason_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional reason shared by moderation actions'**
  String get cmd_simple_action_reason_hint;

  /// No description provided for @cmd_simple_action_delete_default_count_label.
  ///
  /// In en, this message translates to:
  /// **'Default delete count'**
  String get cmd_simple_action_delete_default_count_label;

  /// No description provided for @cmd_simple_action_delete_default_count_hint.
  ///
  /// In en, this message translates to:
  /// **'Used when /count is not provided'**
  String get cmd_simple_action_delete_default_count_hint;

  /// No description provided for @cmd_simple_action_ban_delete_days_label.
  ///
  /// In en, this message translates to:
  /// **'Ban delete message days'**
  String get cmd_simple_action_ban_delete_days_label;

  /// No description provided for @cmd_simple_action_ban_delete_days_hint.
  ///
  /// In en, this message translates to:
  /// **'0 to 7 days of recent messages to delete'**
  String get cmd_simple_action_ban_delete_days_hint;

  /// No description provided for @cmd_simple_action_mute_duration_label.
  ///
  /// In en, this message translates to:
  /// **'Mute duration'**
  String get cmd_simple_action_mute_duration_label;

  /// No description provided for @cmd_simple_action_mute_duration_hint.
  ///
  /// In en, this message translates to:
  /// **'Examples: 10m, 2h, 1d, or raw seconds'**
  String get cmd_simple_action_mute_duration_hint;

  /// No description provided for @cmd_simple_generated_options.
  ///
  /// In en, this message translates to:
  /// **'Generated command options'**
  String get cmd_simple_generated_options;

  /// No description provided for @cmd_simple_generated_none.
  ///
  /// In en, this message translates to:
  /// **'No options generated yet. Select at least one action.'**
  String get cmd_simple_generated_none;

  /// No description provided for @cmd_simple_option_user.
  ///
  /// In en, this message translates to:
  /// **'/user (User)'**
  String get cmd_simple_option_user;

  /// No description provided for @cmd_simple_option_role.
  ///
  /// In en, this message translates to:
  /// **'/role (Role)'**
  String get cmd_simple_option_role;

  /// No description provided for @cmd_simple_option_count.
  ///
  /// In en, this message translates to:
  /// **'/count (Integer)'**
  String get cmd_simple_option_count;

  /// No description provided for @cmd_simple_option_user_id.
  ///
  /// In en, this message translates to:
  /// **'/user_id (Text)'**
  String get cmd_simple_option_user_id;

  /// No description provided for @cmd_simple_option_message_id.
  ///
  /// In en, this message translates to:
  /// **'/message_id (Text)'**
  String get cmd_simple_option_message_id;

  /// No description provided for @cmd_simple_option_channel.
  ///
  /// In en, this message translates to:
  /// **'/channel (Channel)'**
  String get cmd_simple_option_channel;

  /// No description provided for @cmd_simple_option_question.
  ///
  /// In en, this message translates to:
  /// **'/question (Text)'**
  String get cmd_simple_option_question;

  /// No description provided for @cmd_simple_option_user_desc.
  ///
  /// In en, this message translates to:
  /// **'Target user'**
  String get cmd_simple_option_user_desc;

  /// No description provided for @cmd_simple_option_role_desc.
  ///
  /// In en, this message translates to:
  /// **'Target role'**
  String get cmd_simple_option_role_desc;

  /// No description provided for @cmd_simple_option_count_desc.
  ///
  /// In en, this message translates to:
  /// **'Number of messages to delete'**
  String get cmd_simple_option_count_desc;

  /// No description provided for @cmd_simple_option_user_id_desc.
  ///
  /// In en, this message translates to:
  /// **'User ID to unban'**
  String get cmd_simple_option_user_id_desc;

  /// No description provided for @cmd_simple_option_message_id_desc.
  ///
  /// In en, this message translates to:
  /// **'Message ID to target'**
  String get cmd_simple_option_message_id_desc;

  /// No description provided for @cmd_simple_option_channel_desc.
  ///
  /// In en, this message translates to:
  /// **'Optional channel override for invite creation'**
  String get cmd_simple_option_channel_desc;

  /// No description provided for @cmd_simple_option_question_desc.
  ///
  /// In en, this message translates to:
  /// **'Poll question'**
  String get cmd_simple_option_question_desc;

  /// No description provided for @cmd_simple_invite_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Invite settings'**
  String get cmd_simple_invite_settings_title;

  /// No description provided for @cmd_simple_invite_settings_desc.
  ///
  /// In en, this message translates to:
  /// **'Defaults used by the generated Create Invite action.'**
  String get cmd_simple_invite_settings_desc;

  /// No description provided for @cmd_simple_invite_max_age_label.
  ///
  /// In en, this message translates to:
  /// **'Invite expiry (seconds)'**
  String get cmd_simple_invite_max_age_label;

  /// No description provided for @cmd_simple_invite_max_age_hint.
  ///
  /// In en, this message translates to:
  /// **'0 for no expiry, up to 604800'**
  String get cmd_simple_invite_max_age_hint;

  /// No description provided for @cmd_simple_invite_max_uses_label.
  ///
  /// In en, this message translates to:
  /// **'Max uses'**
  String get cmd_simple_invite_max_uses_label;

  /// No description provided for @cmd_simple_invite_max_uses_hint.
  ///
  /// In en, this message translates to:
  /// **'0 for unlimited uses'**
  String get cmd_simple_invite_max_uses_hint;

  /// No description provided for @cmd_simple_invite_temporary_label.
  ///
  /// In en, this message translates to:
  /// **'Temporary membership'**
  String get cmd_simple_invite_temporary_label;

  /// No description provided for @cmd_simple_invite_temporary_desc.
  ///
  /// In en, this message translates to:
  /// **'Members are removed if they leave before getting a role.'**
  String get cmd_simple_invite_temporary_desc;

  /// No description provided for @cmd_simple_invite_unique_label.
  ///
  /// In en, this message translates to:
  /// **'Force unique invite'**
  String get cmd_simple_invite_unique_label;

  /// No description provided for @cmd_simple_invite_unique_desc.
  ///
  /// In en, this message translates to:
  /// **'Always create a new invite instead of reusing an existing one.'**
  String get cmd_simple_invite_unique_desc;

  /// No description provided for @cmd_simple_poll_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Poll settings'**
  String get cmd_simple_poll_settings_title;

  /// No description provided for @cmd_simple_poll_settings_desc.
  ///
  /// In en, this message translates to:
  /// **'Defaults used by the generated Create Poll action.'**
  String get cmd_simple_poll_settings_desc;

  /// No description provided for @cmd_simple_poll_answers_label.
  ///
  /// In en, this message translates to:
  /// **'Poll answers'**
  String get cmd_simple_poll_answers_label;

  /// No description provided for @cmd_simple_poll_answers_hint.
  ///
  /// In en, this message translates to:
  /// **'One answer per line, or use commas. Minimum 2, maximum 10.'**
  String get cmd_simple_poll_answers_hint;

  /// No description provided for @cmd_simple_poll_duration_label.
  ///
  /// In en, this message translates to:
  /// **'Poll duration (hours)'**
  String get cmd_simple_poll_duration_label;

  /// No description provided for @cmd_simple_poll_duration_hint.
  ///
  /// In en, this message translates to:
  /// **'From 1 to 168 hours'**
  String get cmd_simple_poll_duration_hint;

  /// No description provided for @cmd_simple_poll_multiselect_label.
  ///
  /// In en, this message translates to:
  /// **'Allow multiple answers'**
  String get cmd_simple_poll_multiselect_label;

  /// No description provided for @cmd_simple_poll_multiselect_desc.
  ///
  /// In en, this message translates to:
  /// **'Users can select more than one choice.'**
  String get cmd_simple_poll_multiselect_desc;

  /// No description provided for @cmd_simple_response_title.
  ///
  /// In en, this message translates to:
  /// **'Final response'**
  String get cmd_simple_response_title;

  /// No description provided for @cmd_simple_response_desc.
  ///
  /// In en, this message translates to:
  /// **'Message sent back to the user after actions are executed.'**
  String get cmd_simple_response_desc;

  /// No description provided for @cmd_simple_response_visibility_label.
  ///
  /// In en, this message translates to:
  /// **'Response visibility'**
  String get cmd_simple_response_visibility_label;

  /// No description provided for @cmd_simple_response_visibility_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get cmd_simple_response_visibility_public;

  /// No description provided for @cmd_simple_response_visibility_ephemeral.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral'**
  String get cmd_simple_response_visibility_ephemeral;

  /// No description provided for @cmd_simple_response_hint.
  ///
  /// In en, this message translates to:
  /// **'Done ✅'**
  String get cmd_simple_response_hint;

  /// No description provided for @cmd_simple_response_embeds_title.
  ///
  /// In en, this message translates to:
  /// **'Response embeds'**
  String get cmd_simple_response_embeds_title;

  /// No description provided for @cmd_simple_response_embeds_desc.
  ///
  /// In en, this message translates to:
  /// **'Optional embeds sent with the final response.'**
  String get cmd_simple_response_embeds_desc;

  /// No description provided for @cmd_simple_conflict_ban_unban.
  ///
  /// In en, this message translates to:
  /// **'Ban user and Unban user cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_ban_unban;

  /// No description provided for @cmd_simple_conflict_mute_unmute.
  ///
  /// In en, this message translates to:
  /// **'Mute user and Unmute user cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_mute_unmute;

  /// No description provided for @cmd_simple_conflict_pin_unpin.
  ///
  /// In en, this message translates to:
  /// **'Pin message and Unpin message cannot be enabled together in simplified mode.'**
  String get cmd_simple_conflict_pin_unpin;

  /// No description provided for @cmd_simple_invite_max_age_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invite expiry must be a number between 0 and 604800 seconds.'**
  String get cmd_simple_invite_max_age_invalid;

  /// No description provided for @cmd_simple_invite_max_uses_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invite max uses must be a number between 0 and 1000000.'**
  String get cmd_simple_invite_max_uses_invalid;

  /// No description provided for @cmd_simple_poll_answers_invalid.
  ///
  /// In en, this message translates to:
  /// **'Poll answers must contain between 2 and 10 non-empty choices.'**
  String get cmd_simple_poll_answers_invalid;

  /// No description provided for @cmd_simple_poll_duration_invalid.
  ///
  /// In en, this message translates to:
  /// **'Poll duration must be a number between 1 and 168 hours.'**
  String get cmd_simple_poll_duration_invalid;

  /// No description provided for @cmd_simple_send_message_required.
  ///
  /// In en, this message translates to:
  /// **'Please fill the action message before saving.'**
  String get cmd_simple_send_message_required;

  /// No description provided for @support_card_title.
  ///
  /// In en, this message translates to:
  /// **'Support & Community'**
  String get support_card_title;

  /// No description provided for @support_card_desc.
  ///
  /// In en, this message translates to:
  /// **'A question, a bug, a suggestion? Come chat with the team and the community.'**
  String get support_card_desc;

  /// No description provided for @support_join_discord.
  ///
  /// In en, this message translates to:
  /// **'Join the Discord server'**
  String get support_join_discord;

  /// No description provided for @support_discord_badge.
  ///
  /// In en, this message translates to:
  /// **'Official support'**
  String get support_discord_badge;

  /// No description provided for @home_empty_support_hint.
  ///
  /// In en, this message translates to:
  /// **'Need help getting started?'**
  String get home_empty_support_hint;

  /// No description provided for @home_empty_support_btn.
  ///
  /// In en, this message translates to:
  /// **'Join our Discord'**
  String get home_empty_support_btn;

  /// No description provided for @error_invalid_count.
  ///
  /// In en, this message translates to:
  /// **'Count must be greater than 0.'**
  String get error_invalid_count;

  /// No description provided for @error_invalid_channel_type.
  ///
  /// In en, this message translates to:
  /// **'Channel is not a text channel.'**
  String get error_invalid_channel_type;

  /// No description provided for @error_network_timeout.
  ///
  /// In en, this message translates to:
  /// **'The action timed out. Please try again.'**
  String get error_network_timeout;

  /// No description provided for @error_delete_messages_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete messages.'**
  String get error_delete_messages_failed;

  /// No description provided for @doc_center_title.
  ///
  /// In en, this message translates to:
  /// **'Documentation Center'**
  String get doc_center_title;

  /// No description provided for @doc_center_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search commands, workflows, variables, actions, intents, or examples...'**
  String get doc_center_search_hint;

  /// No description provided for @doc_center_clear_search.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get doc_center_clear_search;

  /// No description provided for @doc_center_empty.
  ///
  /// In en, this message translates to:
  /// **'No documentation entry matches your search.'**
  String get doc_center_empty;

  /// No description provided for @doc_kind_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get doc_kind_all;

  /// No description provided for @doc_kind_event.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get doc_kind_event;

  /// No description provided for @doc_kind_action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get doc_kind_action;

  /// No description provided for @doc_kind_template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get doc_kind_template;

  /// No description provided for @doc_kind_runtime.
  ///
  /// In en, this message translates to:
  /// **'Runtime'**
  String get doc_kind_runtime;

  /// No description provided for @doc_required_intents.
  ///
  /// In en, this message translates to:
  /// **'Required Intents'**
  String get doc_required_intents;

  /// No description provided for @doc_available_variables.
  ///
  /// In en, this message translates to:
  /// **'Available Variables'**
  String get doc_available_variables;

  /// No description provided for @doc_example.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get doc_example;

  /// No description provided for @doc_common_section_best_use_cases.
  ///
  /// In en, this message translates to:
  /// **'Best Use Cases'**
  String get doc_common_section_best_use_cases;

  /// No description provided for @doc_common_section_important_notes.
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get doc_common_section_important_notes;

  /// No description provided for @doc_template_variables_title.
  ///
  /// In en, this message translates to:
  /// **'Template Variables'**
  String get doc_template_variables_title;

  /// No description provided for @doc_template_variables_subtitle.
  ///
  /// In en, this message translates to:
  /// **'How dynamic placeholders are resolved.'**
  String get doc_template_variables_subtitle;

  /// No description provided for @doc_template_variables_summary.
  ///
  /// In en, this message translates to:
  /// **'Runtime resolves placeholders using current event/interaction context, workflow args, and global vars.'**
  String get doc_template_variables_summary;

  /// No description provided for @doc_template_variables_section_sources_title.
  ///
  /// In en, this message translates to:
  /// **'Variable Sources'**
  String get doc_template_variables_section_sources_title;

  /// No description provided for @doc_template_variables_section_sources_l1.
  ///
  /// In en, this message translates to:
  /// **'Command variables: commandName, commandId, commandType, target.*, opts.*.'**
  String get doc_template_variables_section_sources_l1;

  /// No description provided for @doc_template_variables_section_sources_l2.
  ///
  /// In en, this message translates to:
  /// **'Event variables: event.*, message.*, reaction.*, voice.*, role.*, etc.'**
  String get doc_template_variables_section_sources_l2;

  /// No description provided for @doc_template_variables_section_sources_l3.
  ///
  /// In en, this message translates to:
  /// **'Workflow variables: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*'**
  String get doc_template_variables_section_sources_l3;

  /// No description provided for @doc_template_variables_section_sources_l4.
  ///
  /// In en, this message translates to:
  /// **'Global variables: global.<key>'**
  String get doc_template_variables_section_sources_l4;

  /// No description provided for @doc_template_variables_section_sources_l5.
  ///
  /// In en, this message translates to:
  /// **'Action outputs: action.<key> when available.'**
  String get doc_template_variables_section_sources_l5;

  /// No description provided for @doc_template_variables_section_builtin_title.
  ///
  /// In en, this message translates to:
  /// **'Built-in Command Variables'**
  String get doc_template_variables_section_builtin_title;

  /// No description provided for @doc_template_variables_section_types_title.
  ///
  /// In en, this message translates to:
  /// **'Command Types'**
  String get doc_template_variables_section_types_title;

  /// No description provided for @doc_template_variables_section_types_l1.
  ///
  /// In en, this message translates to:
  /// **'Slash commands use commandType = chatInput and expose opts.<option> variables.'**
  String get doc_template_variables_section_types_l1;

  /// No description provided for @doc_template_variables_section_types_l2.
  ///
  /// In en, this message translates to:
  /// **'User commands use commandType = user and expose target.user.* variables.'**
  String get doc_template_variables_section_types_l2;

  /// No description provided for @doc_template_variables_section_types_l3.
  ///
  /// In en, this message translates to:
  /// **'Message commands use commandType = message and expose target.message.* variables.'**
  String get doc_template_variables_section_types_l3;

  /// No description provided for @doc_template_variables_section_types_l4.
  ///
  /// In en, this message translates to:
  /// **'Subcommands still expose their arguments through opts.*.'**
  String get doc_template_variables_section_types_l4;

  /// No description provided for @doc_template_variables_section_fallbacks_title.
  ///
  /// In en, this message translates to:
  /// **'Fallbacks and Paths'**
  String get doc_template_variables_section_fallbacks_title;

  /// No description provided for @doc_template_variables_section_fallbacks_l1.
  ///
  /// In en, this message translates to:
  /// **'Use ((opts.user|userName)) to fall back when an option is missing.'**
  String get doc_template_variables_section_fallbacks_l1;

  /// No description provided for @doc_template_variables_section_fallbacks_l2.
  ///
  /// In en, this message translates to:
  /// **'Use JSONPath syntax on action outputs: ((myHttp.body.\$.data[0].id)); arrays and objects stay queryable.'**
  String get doc_template_variables_section_fallbacks_l2;

  /// No description provided for @doc_template_variables_section_fallbacks_l3.
  ///
  /// In en, this message translates to:
  /// **'Functions like length(...), join(...), formatEach(...), and embedFields(...) are also supported; unknown variables still resolve to an empty string.'**
  String get doc_template_variables_section_fallbacks_l3;

  /// No description provided for @doc_template_variables_example.
  ///
  /// In en, this message translates to:
  /// **'Hello ((target.user.username|userName))\nPlayers: ((join(scores.items.\$, \", \")))\nFields JSON: ((embedFields(scores.items.\$, \"\'{name}\'\", \"\'{score}\'\", true)))'**
  String doc_template_variables_example(Object name, Object score);

  /// No description provided for @doc_template_functions_title.
  ///
  /// In en, this message translates to:
  /// **'Template Functions'**
  String get doc_template_functions_title;

  /// No description provided for @doc_template_functions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Transform and compare data inside ((...)) expressions.'**
  String get doc_template_functions_subtitle;

  /// No description provided for @doc_template_functions_summary.
  ///
  /// In en, this message translates to:
  /// **'Use template functions to normalize text, inspect arrays, build output blocks, and add lightweight randomness.'**
  String get doc_template_functions_summary;

  /// No description provided for @doc_template_functions_section_string_title.
  ///
  /// In en, this message translates to:
  /// **'String Helpers'**
  String get doc_template_functions_section_string_title;

  /// No description provided for @doc_template_functions_section_string_l1.
  ///
  /// In en, this message translates to:
  /// **'lowercase(source) / lower(source): convert text to lowercase.'**
  String get doc_template_functions_section_string_l1;

  /// No description provided for @doc_template_functions_section_string_l2.
  ///
  /// In en, this message translates to:
  /// **'uppercase(source) / upper(source): convert text to uppercase.'**
  String get doc_template_functions_section_string_l2;

  /// No description provided for @doc_template_functions_section_string_l3.
  ///
  /// In en, this message translates to:
  /// **'trim(source): remove leading and trailing spaces.'**
  String get doc_template_functions_section_string_l3;

  /// No description provided for @doc_template_functions_section_string_l4.
  ///
  /// In en, this message translates to:
  /// **'replace(source, search, replacement) and contains(source, needle) for substitutions and checks.'**
  String get doc_template_functions_section_string_l4;

  /// No description provided for @doc_template_functions_section_array_title.
  ///
  /// In en, this message translates to:
  /// **'Array and Aggregate Helpers'**
  String get doc_template_functions_section_array_title;

  /// No description provided for @doc_template_functions_section_array_l1.
  ///
  /// In en, this message translates to:
  /// **'length(source), at(source, index), first(source), last(source).'**
  String get doc_template_functions_section_array_l1;

  /// No description provided for @doc_template_functions_section_array_l2.
  ///
  /// In en, this message translates to:
  /// **'slice(source, start, end?) and join(source, separator).'**
  String get doc_template_functions_section_array_l2;

  /// No description provided for @doc_template_functions_section_array_l3.
  ///
  /// In en, this message translates to:
  /// **'sum(source): adds numeric items and ignores non-numeric values.'**
  String get doc_template_functions_section_array_l3;

  /// No description provided for @doc_template_functions_section_array_l4.
  ///
  /// In en, this message translates to:
  /// **'formatEach(...) and embedFields(...) format object arrays for text and embeds.'**
  String get doc_template_functions_section_array_l4;

  /// No description provided for @doc_template_functions_section_random_title.
  ///
  /// In en, this message translates to:
  /// **'Random Helpers'**
  String get doc_template_functions_section_random_title;

  /// No description provided for @doc_template_functions_section_random_l1.
  ///
  /// In en, this message translates to:
  /// **'coin() and random(): return \"true\" or \"\" for conditional branching.'**
  String get doc_template_functions_section_random_l1;

  /// No description provided for @doc_template_functions_section_random_l2.
  ///
  /// In en, this message translates to:
  /// **'randomchoice(a, b, ...) and randomint(min, max).'**
  String get doc_template_functions_section_random_l2;

  /// No description provided for @doc_template_functions_section_notes_title.
  ///
  /// In en, this message translates to:
  /// **'Important Notes'**
  String get doc_template_functions_section_notes_title;

  /// No description provided for @doc_template_functions_section_notes_l1.
  ///
  /// In en, this message translates to:
  /// **'Function names are case-insensitive.'**
  String get doc_template_functions_section_notes_l1;

  /// No description provided for @doc_template_functions_section_notes_l2.
  ///
  /// In en, this message translates to:
  /// **'Unknown functions or invalid arguments resolve to an empty string.'**
  String get doc_template_functions_section_notes_l2;

  /// No description provided for @doc_template_functions_section_notes_l3.
  ///
  /// In en, this message translates to:
  /// **'Use fallback syntax with | at root level: ((replace(name, \"_\", \" \")|Unknown)).'**
  String get doc_template_functions_section_notes_l3;

  /// No description provided for @doc_template_functions_section_notes_l4.
  ///
  /// In en, this message translates to:
  /// **'Arrays and objects returned by functions are serialized as JSON text.'**
  String get doc_template_functions_section_notes_l4;

  /// No description provided for @doc_template_functions_example.
  ///
  /// In en, this message translates to:
  /// **'Normalized: ((uppercase(trim(userName))))\nHas admin role: ((contains(userRole, \"admin\")))\nTop score: ((first(scores.\$)))\nTotal score: ((sum(scores.\$)))'**
  String get doc_template_functions_example;

  /// No description provided for @doc_template_advanced_variables_title.
  ///
  /// In en, this message translates to:
  /// **'Template Advanced Variables'**
  String get doc_template_advanced_variables_title;

  /// No description provided for @doc_template_advanced_variables_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Additional runtime keys available in specific contexts.'**
  String get doc_template_advanced_variables_subtitle;

  /// No description provided for @doc_template_advanced_variables_summary.
  ///
  /// In en, this message translates to:
  /// **'These keys are generated from interaction payloads and channel/guild/user runtime details, depending on the event or command type.'**
  String get doc_template_advanced_variables_summary;

  /// No description provided for @doc_template_advanced_variables_section_interaction_title.
  ///
  /// In en, this message translates to:
  /// **'Interaction Metadata'**
  String get doc_template_advanced_variables_section_interaction_title;

  /// No description provided for @doc_template_advanced_variables_section_interaction_l1.
  ///
  /// In en, this message translates to:
  /// **'interaction.kind identifies the incoming interaction mode (button, select, modal, command, autocomplete).'**
  String get doc_template_advanced_variables_section_interaction_l1;

  /// No description provided for @doc_template_advanced_variables_section_interaction_l2.
  ///
  /// In en, this message translates to:
  /// **'interaction.values and interaction.values.count are populated for select menus.'**
  String get doc_template_advanced_variables_section_interaction_l2;

  /// No description provided for @doc_template_advanced_variables_section_interaction_l3.
  ///
  /// In en, this message translates to:
  /// **'interaction.command.name and interaction.command.id are useful for diagnostics and routing checks.'**
  String get doc_template_advanced_variables_section_interaction_l3;

  /// No description provided for @doc_template_advanced_variables_section_channel_guild_title.
  ///
  /// In en, this message translates to:
  /// **'Channel and Guild Details'**
  String get doc_template_advanced_variables_section_channel_guild_title;

  /// No description provided for @doc_template_advanced_variables_section_channel_guild_l1.
  ///
  /// In en, this message translates to:
  /// **'channel.kind, channel.position, channel.bitrate, and channel.userLimit are context-dependent channel details.'**
  String get doc_template_advanced_variables_section_channel_guild_l1;

  /// No description provided for @doc_template_advanced_variables_section_channel_guild_l2.
  ///
  /// In en, this message translates to:
  /// **'Thread contexts can expose channel.thread.* values (archived, locked, ownerId, autoArchiveDuration).'**
  String get doc_template_advanced_variables_section_channel_guild_l2;

  /// No description provided for @doc_template_advanced_variables_section_channel_guild_l3.
  ///
  /// In en, this message translates to:
  /// **'guild.kind helps distinguish partial/full guild payloads in advanced workflows.'**
  String get doc_template_advanced_variables_section_channel_guild_l3;

  /// No description provided for @doc_template_advanced_variables_section_aliases_title.
  ///
  /// In en, this message translates to:
  /// **'User and Member Aliases'**
  String get doc_template_advanced_variables_section_aliases_title;

  /// No description provided for @doc_template_advanced_variables_section_aliases_l1.
  ///
  /// In en, this message translates to:
  /// **'Structured user aliases (user.id, user.username, user.tag, user.avatar, user.banner) are available in many command contexts.'**
  String get doc_template_advanced_variables_section_aliases_l1;

  /// No description provided for @doc_template_advanced_variables_section_aliases_l2.
  ///
  /// In en, this message translates to:
  /// **'member.id can be useful when both user and guild-member context are needed.'**
  String get doc_template_advanced_variables_section_aliases_l2;

  /// No description provided for @doc_template_advanced_variables_example.
  ///
  /// In en, this message translates to:
  /// **'Kind: ((interaction.kind))\nSelected count: ((interaction.values.count|0))\nThread owner: ((channel.thread.ownerId|unknown))\nGuild payload kind: ((guild.kind|n/a))'**
  String get doc_template_advanced_variables_example;

  /// No description provided for @doc_runtime_action_outputs_title.
  ///
  /// In en, this message translates to:
  /// **'Runtime Action Outputs'**
  String get doc_runtime_action_outputs_title;

  /// No description provided for @doc_runtime_action_outputs_subtitle.
  ///
  /// In en, this message translates to:
  /// **'How action result keys are exposed as runtime variables.'**
  String get doc_runtime_action_outputs_subtitle;

  /// No description provided for @doc_runtime_action_outputs_summary.
  ///
  /// In en, this message translates to:
  /// **'Most actions write a primary result key and may also expose prefixed fields under action.<resultKey>.* depending on the executor.'**
  String get doc_runtime_action_outputs_summary;

  /// No description provided for @doc_runtime_action_outputs_section_patterns_title.
  ///
  /// In en, this message translates to:
  /// **'Output Patterns'**
  String get doc_runtime_action_outputs_section_patterns_title;

  /// No description provided for @doc_runtime_action_outputs_section_patterns_l1.
  ///
  /// In en, this message translates to:
  /// **'Primary output is usually stored as <resultKey>.'**
  String get doc_runtime_action_outputs_section_patterns_l1;

  /// No description provided for @doc_runtime_action_outputs_section_patterns_l2.
  ///
  /// In en, this message translates to:
  /// **'Many executors also expose action.<resultKey>.* fields for clarity and namespacing.'**
  String get doc_runtime_action_outputs_section_patterns_l2;

  /// No description provided for @doc_runtime_action_outputs_section_patterns_l3.
  ///
  /// In en, this message translates to:
  /// **'Some fields are mirrored with and without the action. prefix.'**
  String get doc_runtime_action_outputs_section_patterns_l3;

  /// No description provided for @doc_runtime_action_outputs_section_common_fields_title.
  ///
  /// In en, this message translates to:
  /// **'Common Output Fields'**
  String get doc_runtime_action_outputs_section_common_fields_title;

  /// No description provided for @doc_runtime_action_outputs_section_common_fields_l1.
  ///
  /// In en, this message translates to:
  /// **'HTTP actions: status, body, jsonPath.'**
  String get doc_runtime_action_outputs_section_common_fields_l1;

  /// No description provided for @doc_runtime_action_outputs_section_common_fields_l2.
  ///
  /// In en, this message translates to:
  /// **'Messaging/list actions: count, mode, deleteItself, deleteResponse.'**
  String get doc_runtime_action_outputs_section_common_fields_l2;

  /// No description provided for @doc_runtime_action_outputs_section_common_fields_l3.
  ///
  /// In en, this message translates to:
  /// **'Array actions: items, length, removed, total.'**
  String get doc_runtime_action_outputs_section_common_fields_l3;

  /// No description provided for @doc_runtime_action_outputs_section_common_fields_l4.
  ///
  /// In en, this message translates to:
  /// **'Other executors may expose result or messageId fields.'**
  String get doc_runtime_action_outputs_section_common_fields_l4;

  /// No description provided for @doc_runtime_action_outputs_section_caveats_title.
  ///
  /// In en, this message translates to:
  /// **'Caveats'**
  String get doc_runtime_action_outputs_section_caveats_title;

  /// No description provided for @doc_runtime_action_outputs_section_caveats_l1.
  ///
  /// In en, this message translates to:
  /// **'Not every action exposes every suffix; availability is executor-specific.'**
  String get doc_runtime_action_outputs_section_caveats_l1;

  /// No description provided for @doc_runtime_action_outputs_section_caveats_l2.
  ///
  /// In en, this message translates to:
  /// **'For portability, prefer fallback expressions when reading optional output fields.'**
  String get doc_runtime_action_outputs_section_caveats_l2;

  /// No description provided for @doc_runtime_action_outputs_section_caveats_l3.
  ///
  /// In en, this message translates to:
  /// **'If a key is missing, template resolution returns an empty string.'**
  String get doc_runtime_action_outputs_section_caveats_l3;

  /// No description provided for @doc_runtime_action_outputs_example.
  ///
  /// In en, this message translates to:
  /// **'Status: ((action.http.status|http.status|unknown))\nBody: ((action.http.body|http.body))\nDeleted: ((cleanup.count|0))\nTotal: ((page.total|0))'**
  String get doc_runtime_action_outputs_example;

  /// No description provided for @doc_interaction_commands_title.
  ///
  /// In en, this message translates to:
  /// **'Interaction Commands'**
  String get doc_interaction_commands_title;

  /// No description provided for @doc_interaction_commands_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Slash, user and message command runtime behavior.'**
  String get doc_interaction_commands_subtitle;

  /// No description provided for @doc_interaction_commands_summary.
  ///
  /// In en, this message translates to:
  /// **'Application commands are executed through a shared interaction path, with runtime variables depending on the Discord command type.'**
  String get doc_interaction_commands_summary;

  /// No description provided for @doc_interaction_commands_section_execution_title.
  ///
  /// In en, this message translates to:
  /// **'Execution Model'**
  String get doc_interaction_commands_section_execution_title;

  /// No description provided for @doc_interaction_commands_section_execution_l1.
  ///
  /// In en, this message translates to:
  /// **'Slash, user and message commands all enter the runner as application command interactions.'**
  String get doc_interaction_commands_section_execution_l1;

  /// No description provided for @doc_interaction_commands_section_execution_l2.
  ///
  /// In en, this message translates to:
  /// **'The runner matches commands by Discord command id, then validates stored type vs incoming type.'**
  String get doc_interaction_commands_section_execution_l2;

  /// No description provided for @doc_interaction_commands_section_execution_l3.
  ///
  /// In en, this message translates to:
  /// **'A type mismatch is logged as warning but does not hard-stop execution.'**
  String get doc_interaction_commands_section_execution_l3;

  /// No description provided for @doc_interaction_commands_section_per_type_title.
  ///
  /// In en, this message translates to:
  /// **'Per-Type Variables'**
  String get doc_interaction_commands_section_per_type_title;

  /// No description provided for @doc_interaction_commands_section_per_type_l1.
  ///
  /// In en, this message translates to:
  /// **'chatInput: opts.* for parameters and subcommands.'**
  String get doc_interaction_commands_section_per_type_l1;

  /// No description provided for @doc_interaction_commands_section_per_type_l2.
  ///
  /// In en, this message translates to:
  /// **'user: target.user.* and target.member.* when available.'**
  String get doc_interaction_commands_section_per_type_l2;

  /// No description provided for @doc_interaction_commands_section_per_type_l3.
  ///
  /// In en, this message translates to:
  /// **'message: target.message.* including content and author id when resolved.'**
  String get doc_interaction_commands_section_per_type_l3;

  /// No description provided for @doc_interaction_commands_section_builtin_title.
  ///
  /// In en, this message translates to:
  /// **'Built-in Command Variables'**
  String get doc_interaction_commands_section_builtin_title;

  /// No description provided for @doc_interaction_commands_section_guidance_title.
  ///
  /// In en, this message translates to:
  /// **'Authoring Guidance'**
  String get doc_interaction_commands_section_guidance_title;

  /// No description provided for @doc_interaction_commands_section_guidance_l1.
  ///
  /// In en, this message translates to:
  /// **'Write conditional logic against commandType or interaction.command.type.'**
  String get doc_interaction_commands_section_guidance_l1;

  /// No description provided for @doc_interaction_commands_section_guidance_l2.
  ///
  /// In en, this message translates to:
  /// **'Prefer fallback syntax when sharing a template between slash and non-slash commands, and use autocomplete.query inside dedicated autocomplete workflows.'**
  String get doc_interaction_commands_section_guidance_l2;

  /// No description provided for @doc_interaction_commands_section_guidance_l3.
  ///
  /// In en, this message translates to:
  /// **'Keep templates portable by avoiding event-only names inside command workflows; dynamic autocomplete requires a general workflow ending with respondWithAutocomplete.'**
  String get doc_interaction_commands_section_guidance_l3;

  /// No description provided for @doc_interaction_commands_example.
  ///
  /// In en, this message translates to:
  /// **'Autocomplete workflow:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'{name}\' value=\'{id}\''**
  String doc_interaction_commands_example(Object id, Object name);

  /// No description provided for @doc_event_message_create_title.
  ///
  /// In en, this message translates to:
  /// **'Event: messageCreate'**
  String get doc_event_message_create_title;

  /// No description provided for @doc_event_message_create_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered for each newly created message.'**
  String get doc_event_message_create_subtitle;

  /// No description provided for @doc_event_message_create_summary.
  ///
  /// In en, this message translates to:
  /// **'Use this event for moderation, keyword pipelines, auto-replies, command-style parsing, and analytics.'**
  String get doc_event_message_create_summary;

  /// No description provided for @doc_event_message_create_intent_1.
  ///
  /// In en, this message translates to:
  /// **'Guild Messages'**
  String get doc_event_message_create_intent_1;

  /// No description provided for @doc_event_message_create_intent_2.
  ///
  /// In en, this message translates to:
  /// **'Message Content'**
  String get doc_event_message_create_intent_2;

  /// No description provided for @doc_event_message_create_best_use_l1.
  ///
  /// In en, this message translates to:
  /// **'Detect commands typed without slash commands.'**
  String get doc_event_message_create_best_use_l1;

  /// No description provided for @doc_event_message_create_best_use_l2.
  ///
  /// In en, this message translates to:
  /// **'Apply anti-spam filters before answering.'**
  String get doc_event_message_create_best_use_l2;

  /// No description provided for @doc_event_message_create_best_use_l3.
  ///
  /// In en, this message translates to:
  /// **'Route to reusable workflows based on first word or mention.'**
  String get doc_event_message_create_best_use_l3;

  /// No description provided for @doc_event_message_create_notes_l1.
  ///
  /// In en, this message translates to:
  /// **'If Message Content intent is off, content-dependent conditions can fail.'**
  String get doc_event_message_create_notes_l1;

  /// No description provided for @doc_event_message_create_notes_l2.
  ///
  /// In en, this message translates to:
  /// **'message.content[index] is word-based and capped by runtime extraction.'**
  String get doc_event_message_create_notes_l2;

  /// No description provided for @doc_event_message_create_notes_l3.
  ///
  /// In en, this message translates to:
  /// **'author.isBot can help avoid bot loops.'**
  String get doc_event_message_create_notes_l3;

  /// No description provided for @doc_event_message_create_example.
  ///
  /// In en, this message translates to:
  /// **'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nThen: runWorkflow -> ticket_manager entry=create'**
  String get doc_event_message_create_example;

  /// No description provided for @doc_runtime_execution_flow_title.
  ///
  /// In en, this message translates to:
  /// **'Runtime Execution Flow'**
  String get doc_runtime_execution_flow_title;

  /// No description provided for @doc_runtime_execution_flow_subtitle.
  ///
  /// In en, this message translates to:
  /// **'How event workflows are selected and executed.'**
  String get doc_runtime_execution_flow_subtitle;

  /// No description provided for @doc_runtime_execution_flow_summary.
  ///
  /// In en, this message translates to:
  /// **'When an event arrives, runtime matches configured workflows by eventTrigger.event then executes actions with context variables.'**
  String get doc_runtime_execution_flow_summary;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_title.
  ///
  /// In en, this message translates to:
  /// **'Pipeline'**
  String get doc_runtime_execution_flow_section_pipeline_title;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_l1.
  ///
  /// In en, this message translates to:
  /// **'1) Receive gateway event.'**
  String get doc_runtime_execution_flow_section_pipeline_l1;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_l2.
  ///
  /// In en, this message translates to:
  /// **'2) Build context variables map.'**
  String get doc_runtime_execution_flow_section_pipeline_l2;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_l3.
  ///
  /// In en, this message translates to:
  /// **'3) Match workflows by event name.'**
  String get doc_runtime_execution_flow_section_pipeline_l3;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_l4.
  ///
  /// In en, this message translates to:
  /// **'4) Merge global variables.'**
  String get doc_runtime_execution_flow_section_pipeline_l4;

  /// No description provided for @doc_runtime_execution_flow_section_pipeline_l5.
  ///
  /// In en, this message translates to:
  /// **'5) Execute actions sequentially with conditions.'**
  String get doc_runtime_execution_flow_section_pipeline_l5;

  /// No description provided for @doc_runtime_execution_flow_section_parity_title.
  ///
  /// In en, this message translates to:
  /// **'Parity Rule'**
  String get doc_runtime_execution_flow_section_parity_title;

  /// No description provided for @doc_runtime_execution_flow_section_parity_l1.
  ///
  /// In en, this message translates to:
  /// **'Variables should be identical between local app runtime and runner runtime.'**
  String get doc_runtime_execution_flow_section_parity_l1;

  /// No description provided for @doc_runtime_execution_flow_section_parity_l2.
  ///
  /// In en, this message translates to:
  /// **'Use same variable names in conditions to stay portable.'**
  String get doc_runtime_execution_flow_section_parity_l2;

  /// No description provided for @template_gallery_title.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get template_gallery_title;

  /// No description provided for @template_gallery_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick-start your bot with a ready-made template.'**
  String get template_gallery_subtitle;

  /// No description provided for @template_gallery_apply.
  ///
  /// In en, this message translates to:
  /// **'Use this template'**
  String get template_gallery_apply;

  /// No description provided for @template_gallery_apply_success.
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) and {wCount} workflow(s) added from template.'**
  String template_gallery_apply_success(String count, String wCount);

  /// No description provided for @template_gallery_apply_error.
  ///
  /// In en, this message translates to:
  /// **'Failed to apply template: {error}'**
  String template_gallery_apply_error(String error);

  /// No description provided for @template_gallery_commands_count.
  ///
  /// In en, this message translates to:
  /// **'{count} command(s)'**
  String template_gallery_commands_count(String count);

  /// No description provided for @template_gallery_workflows_count.
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s)'**
  String template_gallery_workflows_count(String count);

  /// No description provided for @template_gallery_empty.
  ///
  /// In en, this message translates to:
  /// **'No templates available.'**
  String get template_gallery_empty;

  /// No description provided for @template_gallery_already_exists.
  ///
  /// In en, this message translates to:
  /// **'Command \"{name}\" already exists and was skipped.'**
  String template_gallery_already_exists(String name);

  /// No description provided for @template_gallery_sync_warning.
  ///
  /// In en, this message translates to:
  /// **'Commands saved locally. Start your bot to register them on Discord.'**
  String get template_gallery_sync_warning;

  /// No description provided for @template_welcome_name.
  ///
  /// In en, this message translates to:
  /// **'Welcome Bot'**
  String get template_welcome_name;

  /// No description provided for @template_welcome_description.
  ///
  /// In en, this message translates to:
  /// **'Greet new members, say hello, and show server info.'**
  String get template_welcome_description;

  /// No description provided for @template_moderation_name.
  ///
  /// In en, this message translates to:
  /// **'Moderation Bot'**
  String get template_moderation_name;

  /// No description provided for @template_moderation_description.
  ///
  /// In en, this message translates to:
  /// **'Ban, kick, mute members and clear messages.'**
  String get template_moderation_description;

  /// No description provided for @template_utility_name.
  ///
  /// In en, this message translates to:
  /// **'Utility Bot'**
  String get template_utility_name;

  /// No description provided for @template_utility_description.
  ///
  /// In en, this message translates to:
  /// **'Ping, avatar lookup, and bot-says commands.'**
  String get template_utility_description;

  /// No description provided for @template_fun_name.
  ///
  /// In en, this message translates to:
  /// **'Fun Bot'**
  String get template_fun_name;

  /// No description provided for @template_fun_description.
  ///
  /// In en, this message translates to:
  /// **'Coin flip, polls, and magic 8-ball.'**
  String get template_fun_description;

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard_title;

  /// No description provided for @dashboard_no_data.
  ///
  /// In en, this message translates to:
  /// **'No command usage data yet. Run your bot to start tracking.'**
  String get dashboard_no_data;

  /// No description provided for @dashboard_total.
  ///
  /// In en, this message translates to:
  /// **'Total commands'**
  String get dashboard_total;

  /// No description provided for @dashboard_period_24h.
  ///
  /// In en, this message translates to:
  /// **'Last 24h'**
  String get dashboard_period_24h;

  /// No description provided for @dashboard_period_7d.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get dashboard_period_7d;

  /// No description provided for @dashboard_period_30d.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get dashboard_period_30d;

  /// No description provided for @dashboard_top_commands.
  ///
  /// In en, this message translates to:
  /// **'Top commands'**
  String get dashboard_top_commands;

  /// No description provided for @dashboard_top_locales.
  ///
  /// In en, this message translates to:
  /// **'Top locales'**
  String get dashboard_top_locales;

  /// No description provided for @dashboard_execution_health_title.
  ///
  /// In en, this message translates to:
  /// **'Execution health'**
  String get dashboard_execution_health_title;

  /// No description provided for @dashboard_failed_commands.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get dashboard_failed_commands;

  /// No description provided for @dashboard_error_rate.
  ///
  /// In en, this message translates to:
  /// **'Error rate'**
  String get dashboard_error_rate;

  /// No description provided for @dashboard_p50_latency.
  ///
  /// In en, this message translates to:
  /// **'Latency p50'**
  String get dashboard_p50_latency;

  /// No description provided for @dashboard_p95_latency.
  ///
  /// In en, this message translates to:
  /// **'Latency p95'**
  String get dashboard_p95_latency;

  /// No description provided for @dashboard_premium_analytics_title.
  ///
  /// In en, this message translates to:
  /// **'Premium analytics'**
  String get dashboard_premium_analytics_title;

  /// No description provided for @dashboard_premium_analytics_desc.
  ///
  /// In en, this message translates to:
  /// **'Unlock error rate, latency percentiles, and locale insights.'**
  String get dashboard_premium_analytics_desc;

  /// No description provided for @dashboard_timeline.
  ///
  /// In en, this message translates to:
  /// **'Usage over time'**
  String get dashboard_timeline;

  /// No description provided for @dashboard_executions.
  ///
  /// In en, this message translates to:
  /// **'{count} executions'**
  String dashboard_executions(String count);

  /// No description provided for @dashboard_selected_period_total.
  ///
  /// In en, this message translates to:
  /// **'{count} in selected period'**
  String dashboard_selected_period_total(String count);

  /// No description provided for @dashboard_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading stats...'**
  String get dashboard_loading;

  /// No description provided for @dashboard_error.
  ///
  /// In en, this message translates to:
  /// **'Could not load stats: {error}'**
  String dashboard_error(String error);

  /// No description provided for @dashboard_refresh_sources_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh execution servers'**
  String get dashboard_refresh_sources_tooltip;

  /// No description provided for @dashboard_requires_runner.
  ///
  /// In en, this message translates to:
  /// **'Connect to a runner to see command usage stats.'**
  String get dashboard_requires_runner;

  /// No description provided for @dashboard_single_runner_notice.
  ///
  /// In en, this message translates to:
  /// **'Stats shown are from the currently configured runner only. If you run bots on multiple runners, this view may be incomplete.'**
  String get dashboard_single_runner_notice;

  /// No description provided for @runner_source_label.
  ///
  /// In en, this message translates to:
  /// **'Runner: {name}'**
  String runner_source_label(String name);

  /// No description provided for @runner_source_local.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get runner_source_local;

  /// No description provided for @runner_source_all.
  ///
  /// In en, this message translates to:
  /// **'All runners'**
  String get runner_source_all;

  /// No description provided for @runner_select_source.
  ///
  /// In en, this message translates to:
  /// **'Select runner'**
  String get runner_select_source;

  /// No description provided for @logs_runner_source.
  ///
  /// In en, this message translates to:
  /// **'Logs from: {name}'**
  String logs_runner_source(String name);

  /// No description provided for @settings_version_title.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version_title;

  /// No description provided for @settings_app_version.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settings_app_version;

  /// No description provided for @settings_runner_version.
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get settings_runner_version;

  /// No description provided for @settings_runner_not_connected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get settings_runner_not_connected;

  /// No description provided for @premium_card_title.
  ///
  /// In en, this message translates to:
  /// **'Remove Ads'**
  String get premium_card_title;

  /// No description provided for @premium_card_desc.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to remove all ads and start your bots instantly, without any popup.'**
  String get premium_card_desc;

  /// No description provided for @premium_card_button.
  ///
  /// In en, this message translates to:
  /// **'See plans'**
  String get premium_card_button;

  /// No description provided for @premium_active_title.
  ///
  /// In en, this message translates to:
  /// **'Premium active'**
  String get premium_active_title;

  /// No description provided for @premium_active_desc.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your support! All ads are disabled.'**
  String get premium_active_desc;

  /// No description provided for @subscription_title.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get subscription_title;

  /// No description provided for @subscription_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to unlock all premium features.'**
  String get subscription_subtitle;

  /// No description provided for @subscription_plan_label.
  ///
  /// In en, this message translates to:
  /// **'Premium Basic'**
  String get subscription_plan_label;

  /// No description provided for @subscription_plan_desc.
  ///
  /// In en, this message translates to:
  /// **'Remove ads and get access to all current and upcoming premium features.'**
  String get subscription_plan_desc;

  /// No description provided for @subscription_success.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Premium! All ads have been removed.'**
  String get subscription_success;

  /// No description provided for @subscription_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get subscription_manage;

  /// No description provided for @subscription_active_label.
  ///
  /// In en, this message translates to:
  /// **'Active plan:'**
  String get subscription_active_label;

  /// No description provided for @subscription_active_annual.
  ///
  /// In en, this message translates to:
  /// **'Premium — Annual'**
  String get subscription_active_annual;

  /// No description provided for @subscription_active_monthly.
  ///
  /// In en, this message translates to:
  /// **'Premium — Monthly'**
  String get subscription_active_monthly;

  /// No description provided for @subscription_benefit_no_ads.
  ///
  /// In en, this message translates to:
  /// **'No ads anywhere in the app'**
  String get subscription_benefit_no_ads;

  /// No description provided for @subscription_benefit_fast_start.
  ///
  /// In en, this message translates to:
  /// **'Bots start instantly, no popup'**
  String get subscription_benefit_fast_start;

  /// No description provided for @subscription_benefit_support.
  ///
  /// In en, this message translates to:
  /// **'Support independent development'**
  String get subscription_benefit_support;

  /// No description provided for @subscription_feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get subscription_feature_coming_soon;

  /// No description provided for @subscription_feature_no_ads_title.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get subscription_feature_no_ads_title;

  /// No description provided for @subscription_feature_no_ads_desc.
  ///
  /// In en, this message translates to:
  /// **'Remove all ad placements across the app experience.'**
  String get subscription_feature_no_ads_desc;

  /// No description provided for @subscription_feature_instant_start_title.
  ///
  /// In en, this message translates to:
  /// **'Instant start'**
  String get subscription_feature_instant_start_title;

  /// No description provided for @subscription_feature_instant_start_desc.
  ///
  /// In en, this message translates to:
  /// **'Start bots immediately without rewarded ad interruption.'**
  String get subscription_feature_instant_start_desc;

  /// No description provided for @subscription_feature_analytics_title.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get subscription_feature_analytics_title;

  /// No description provided for @subscription_feature_analytics_desc.
  ///
  /// In en, this message translates to:
  /// **'Access error rate, latency percentiles, and locale insights.'**
  String get subscription_feature_analytics_desc;

  /// No description provided for @subscription_feature_scheduler_title.
  ///
  /// In en, this message translates to:
  /// **'Scheduler triggers'**
  String get subscription_feature_scheduler_title;

  /// No description provided for @subscription_feature_scheduler_desc.
  ///
  /// In en, this message translates to:
  /// **'Run workflows automatically every X minutes (up to 10 active).'**
  String get subscription_feature_scheduler_desc;

  /// No description provided for @subscription_feature_webhooks_title.
  ///
  /// In en, this message translates to:
  /// **'Inbound webhooks'**
  String get subscription_feature_webhooks_title;

  /// No description provided for @subscription_feature_webhooks_desc.
  ///
  /// In en, this message translates to:
  /// **'Create secure webhook endpoints and route calls to workflows.'**
  String get subscription_feature_webhooks_desc;

  /// No description provided for @subscription_feature_debug_replay_title.
  ///
  /// In en, this message translates to:
  /// **'Visual debug replay'**
  String get subscription_feature_debug_replay_title;

  /// No description provided for @subscription_feature_debug_replay_desc.
  ///
  /// In en, this message translates to:
  /// **'Record and replay command actions step by step for debugging.'**
  String get subscription_feature_debug_replay_desc;

  /// No description provided for @subscription_feature_auto_sharding_title.
  ///
  /// In en, this message translates to:
  /// **'Automatic sharding'**
  String get subscription_feature_auto_sharding_title;

  /// No description provided for @subscription_feature_auto_sharding_desc.
  ///
  /// In en, this message translates to:
  /// **'Scale large bots by distributing load across shard workers.'**
  String get subscription_feature_auto_sharding_desc;

  /// No description provided for @subscription_feature_auto_restart_title.
  ///
  /// In en, this message translates to:
  /// **'Automatic restart'**
  String get subscription_feature_auto_restart_title;

  /// No description provided for @subscription_feature_auto_restart_desc.
  ///
  /// In en, this message translates to:
  /// **'Restart the bot automatically when a full restart is required.'**
  String get subscription_feature_auto_restart_desc;

  /// No description provided for @subscription_annual_title.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get subscription_annual_title;

  /// No description provided for @subscription_monthly_title.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscription_monthly_title;

  /// No description provided for @subscription_per_year.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get subscription_per_year;

  /// No description provided for @subscription_per_month.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get subscription_per_month;

  /// No description provided for @subscription_save_badge.
  ///
  /// In en, this message translates to:
  /// **'SAVE 67%'**
  String get subscription_save_badge;

  /// No description provided for @subscription_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get subscription_restore;

  /// No description provided for @subscription_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get subscription_terms;

  /// No description provided for @subscription_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get subscription_privacy;

  /// No description provided for @subscription_error.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be completed. Please try again.'**
  String get subscription_error;

  /// No description provided for @subscription_error_store_unavailable.
  ///
  /// In en, this message translates to:
  /// **'The App Store is currently unavailable. Please try again in a moment.'**
  String get subscription_error_store_unavailable;

  /// No description provided for @subscription_error_product_unavailable.
  ///
  /// In en, this message translates to:
  /// **'This plan is currently unavailable. Please try again later.'**
  String get subscription_error_product_unavailable;

  /// No description provided for @subscription_error_purchase_start_failed.
  ///
  /// In en, this message translates to:
  /// **'Purchase could not be started. Please try again.'**
  String get subscription_error_purchase_start_failed;

  /// No description provided for @subscription_restored.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored successfully!'**
  String get subscription_restored;

  /// No description provided for @subscription_restore_not_found.
  ///
  /// In en, this message translates to:
  /// **'No active subscription found.'**
  String get subscription_restore_not_found;

  /// No description provided for @subscription_not_available_on_platform.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions are currently available on mobile only.'**
  String get subscription_not_available_on_platform;

  /// No description provided for @subscription_unavailable_platform.
  ///
  /// In en, this message translates to:
  /// **'Not available on this platform.'**
  String get subscription_unavailable_platform;

  /// No description provided for @action_name_addThreadMember.
  ///
  /// In en, this message translates to:
  /// **'Add Thread Member'**
  String get action_name_addThreadMember;

  /// No description provided for @action_name_removeThreadMember.
  ///
  /// In en, this message translates to:
  /// **'Remove Thread Member'**
  String get action_name_removeThreadMember;

  /// No description provided for @template_gallery_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove Template'**
  String get template_gallery_remove_title;

  /// No description provided for @template_gallery_nothing_to_remove.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remove for {name}.'**
  String template_gallery_nothing_to_remove(String name);

  /// No description provided for @template_gallery_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all commands and workflows from this template?'**
  String get template_gallery_remove_confirm;

  /// No description provided for @template_gallery_removed.
  ///
  /// In en, this message translates to:
  /// **'Template commands and workflows removed.'**
  String get template_gallery_removed;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get common_remove;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get common_apply;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get common_enabled;

  /// No description provided for @common_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get common_import;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_move_up.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get common_move_up;

  /// No description provided for @common_move_down.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get common_move_down;

  /// No description provided for @common_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get common_name;

  /// No description provided for @common_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get common_value;

  /// No description provided for @common_key.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get common_key;

  /// No description provided for @common_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get common_type;

  /// No description provided for @common_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get common_required;

  /// No description provided for @common_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get common_description;

  /// No description provided for @common_default.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get common_default;

  /// No description provided for @common_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_pick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get common_pick;

  /// No description provided for @common_add_argument.
  ///
  /// In en, this message translates to:
  /// **'Add Argument'**
  String get common_add_argument;

  /// No description provided for @common_add_option.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get common_add_option;

  /// No description provided for @common_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get common_refresh;

  /// No description provided for @common_refresh_workflows.
  ///
  /// In en, this message translates to:
  /// **'Refresh workflows'**
  String get common_refresh_workflows;

  /// No description provided for @common_search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get common_search;

  /// No description provided for @common_workflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get common_workflow;

  /// No description provided for @common_static_options.
  ///
  /// In en, this message translates to:
  /// **'Static Options'**
  String get common_static_options;

  /// No description provided for @common_manage_workflows.
  ///
  /// In en, this message translates to:
  /// **'Manage Workflows'**
  String get common_manage_workflows;

  /// No description provided for @doc_event_reaction_add_title.
  ///
  /// In en, this message translates to:
  /// **'Event: messageReactionAdd'**
  String get doc_event_reaction_add_title;

  /// No description provided for @doc_event_reaction_add_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a user adds a reaction to a message.'**
  String get doc_event_reaction_add_subtitle;

  /// No description provided for @doc_event_reaction_add_summary.
  ///
  /// In en, this message translates to:
  /// **'Ideal for button-like UX without components, vote systems, role menus, and lightweight approvals.'**
  String get doc_event_reaction_add_summary;

  /// No description provided for @doc_event_reaction_add_intent.
  ///
  /// In en, this message translates to:
  /// **'Guild Message Reactions'**
  String get doc_event_reaction_add_intent;

  /// No description provided for @doc_event_reaction_add_best_use_l1.
  ///
  /// In en, this message translates to:
  /// **'Approve/reject flows with unicode emoji.'**
  String get doc_event_reaction_add_best_use_l1;

  /// No description provided for @doc_event_reaction_add_best_use_l2.
  ///
  /// In en, this message translates to:
  /// **'Multi-step polls using custom emoji IDs.'**
  String get doc_event_reaction_add_best_use_l2;

  /// No description provided for @doc_event_reaction_add_best_use_l3.
  ///
  /// In en, this message translates to:
  /// **'Quick moderation signals from staff channels.'**
  String get doc_event_reaction_add_best_use_l3;

  /// No description provided for @doc_event_reaction_add_notes_l1.
  ///
  /// In en, this message translates to:
  /// **'reaction.emoji.id can be empty for unicode emoji.'**
  String get doc_event_reaction_add_notes_l1;

  /// No description provided for @doc_event_reaction_add_notes_l2.
  ///
  /// In en, this message translates to:
  /// **'Use reaction.emoji.name for generic matching.'**
  String get doc_event_reaction_add_notes_l2;

  /// No description provided for @doc_event_reaction_add_notes_l3.
  ///
  /// In en, this message translates to:
  /// **'Use reaction.emoji.id for strict custom emoji matching.'**
  String get doc_event_reaction_add_notes_l3;

  /// No description provided for @doc_event_reaction_add_example.
  ///
  /// In en, this message translates to:
  /// **'Guard: ((reaction.emoji.name)) equals ✅\nAction: addRole -> user=((userId)) role=((global.approvedRoleId))'**
  String get doc_event_reaction_add_example;

  /// No description provided for @doc_event_poll_vote_add_title.
  ///
  /// In en, this message translates to:
  /// **'Event: messagePollVoteAdd'**
  String get doc_event_poll_vote_add_title;

  /// No description provided for @doc_event_poll_vote_add_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a user votes on a poll answer.'**
  String get doc_event_poll_vote_add_subtitle;

  /// No description provided for @doc_event_poll_vote_add_summary.
  ///
  /// In en, this message translates to:
  /// **'Useful for score tracking, role assignment by poll option, and survey processing.'**
  String get doc_event_poll_vote_add_summary;

  /// No description provided for @doc_event_poll_vote_add_intent.
  ///
  /// In en, this message translates to:
  /// **'Guild Messages'**
  String get doc_event_poll_vote_add_intent;

  /// No description provided for @doc_event_poll_vote_add_best_use_l1.
  ///
  /// In en, this message translates to:
  /// **'Map each answer id to a different action branch.'**
  String get doc_event_poll_vote_add_best_use_l1;

  /// No description provided for @doc_event_poll_vote_add_best_use_l2.
  ///
  /// In en, this message translates to:
  /// **'Track poll participation per channel or user group.'**
  String get doc_event_poll_vote_add_best_use_l2;

  /// No description provided for @doc_event_poll_vote_add_notes_l1.
  ///
  /// In en, this message translates to:
  /// **'poll.answer.id is the most stable key for routing.'**
  String get doc_event_poll_vote_add_notes_l1;

  /// No description provided for @doc_event_poll_vote_add_notes_l2.
  ///
  /// In en, this message translates to:
  /// **'poll.question is optional and may be empty depending on payload.'**
  String get doc_event_poll_vote_add_notes_l2;

  /// No description provided for @doc_event_voice_state_update_title.
  ///
  /// In en, this message translates to:
  /// **'Event: voiceStateUpdate'**
  String get doc_event_voice_state_update_title;

  /// No description provided for @doc_event_voice_state_update_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered when voice state changes for a user.'**
  String get doc_event_voice_state_update_subtitle;

  /// No description provided for @doc_event_voice_state_update_summary.
  ///
  /// In en, this message translates to:
  /// **'Use this for auto-moderation in voice channels, attendance checks, and voice automation.'**
  String get doc_event_voice_state_update_summary;

  /// No description provided for @doc_event_voice_state_update_intent.
  ///
  /// In en, this message translates to:
  /// **'Guilds'**
  String get doc_event_voice_state_update_intent;

  /// No description provided for @doc_event_voice_state_update_section_title.
  ///
  /// In en, this message translates to:
  /// **'Typical Automations'**
  String get doc_event_voice_state_update_section_title;

  /// No description provided for @doc_event_voice_state_update_automations_l1.
  ///
  /// In en, this message translates to:
  /// **'Detect self-mute/self-deafen policy violations.'**
  String get doc_event_voice_state_update_automations_l1;

  /// No description provided for @doc_event_voice_state_update_automations_l2.
  ///
  /// In en, this message translates to:
  /// **'Trigger welcome message on voice join for support channels.'**
  String get doc_event_voice_state_update_automations_l2;

  /// No description provided for @doc_event_voice_state_update_automations_l3.
  ///
  /// In en, this message translates to:
  /// **'Log leave/join patterns using channel changes.'**
  String get doc_event_voice_state_update_automations_l3;

  /// No description provided for @doc_event_user_update_title.
  ///
  /// In en, this message translates to:
  /// **'Event: userUpdate'**
  String get doc_event_user_update_title;

  /// No description provided for @doc_event_user_update_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered when user profile data changes.'**
  String get doc_event_user_update_subtitle;

  /// No description provided for @doc_event_user_update_summary.
  ///
  /// In en, this message translates to:
  /// **'Useful for profile-change auditing and username/avatar-driven triggers.'**
  String get doc_event_user_update_summary;

  /// No description provided for @doc_event_user_update_notes_l1.
  ///
  /// In en, this message translates to:
  /// **'No channel context for this event in most cases.'**
  String get doc_event_user_update_notes_l1;

  /// No description provided for @doc_event_user_update_notes_l2.
  ///
  /// In en, this message translates to:
  /// **'Prefer logging + moderation alerts over direct user-facing replies.'**
  String get doc_event_user_update_notes_l2;

  /// No description provided for @doc_event_audit_log_create_title.
  ///
  /// In en, this message translates to:
  /// **'Event: guildAuditLogCreate'**
  String get doc_event_audit_log_create_title;

  /// No description provided for @doc_event_audit_log_create_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Triggered when a new audit log entry is created.'**
  String get doc_event_audit_log_create_subtitle;

  /// No description provided for @doc_event_audit_log_create_summary.
  ///
  /// In en, this message translates to:
  /// **'High-value event for administrative security monitoring.'**
  String get doc_event_audit_log_create_summary;

  /// No description provided for @doc_event_audit_log_create_best_use_l1.
  ///
  /// In en, this message translates to:
  /// **'Alert staff on sensitive actions (role delete, webhook create, ban, etc.).'**
  String get doc_event_audit_log_create_best_use_l1;

  /// No description provided for @doc_event_audit_log_create_best_use_l2.
  ///
  /// In en, this message translates to:
  /// **'Route specific action types to dedicated workflows.'**
  String get doc_event_audit_log_create_best_use_l2;

  /// No description provided for @doc_action_stop_unless_title.
  ///
  /// In en, this message translates to:
  /// **'Action: stopUnless'**
  String get doc_action_stop_unless_title;

  /// No description provided for @doc_action_stop_unless_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Guard clause that stops workflow when condition fails.'**
  String get doc_action_stop_unless_subtitle;

  /// No description provided for @doc_action_stop_unless_summary.
  ///
  /// In en, this message translates to:
  /// **'Use it at the top of workflows to prevent unnecessary actions when context does not match.'**
  String get doc_action_stop_unless_summary;

  /// No description provided for @doc_action_stop_unless_section_operators.
  ///
  /// In en, this message translates to:
  /// **'Supported Operators'**
  String get doc_action_stop_unless_section_operators;

  /// No description provided for @doc_action_stop_unless_operators_l1.
  ///
  /// In en, this message translates to:
  /// **'equals, notEquals, contains, notContains, startsWith, endsWith'**
  String get doc_action_stop_unless_operators_l1;

  /// No description provided for @doc_action_stop_unless_operators_l2.
  ///
  /// In en, this message translates to:
  /// **'greaterThan, lessThan, greaterOrEqual, lessOrEqual'**
  String get doc_action_stop_unless_operators_l2;

  /// No description provided for @doc_action_stop_unless_operators_l3.
  ///
  /// In en, this message translates to:
  /// **'isEmpty, isNotEmpty, matches'**
  String get doc_action_stop_unless_operators_l3;

  /// No description provided for @doc_action_stop_unless_section_format.
  ///
  /// In en, this message translates to:
  /// **'Condition Variable Format'**
  String get doc_action_stop_unless_section_format;

  /// No description provided for @doc_action_stop_unless_format_l1.
  ///
  /// In en, this message translates to:
  /// **'You can use raw keys: message.content[0]'**
  String get doc_action_stop_unless_format_l1;

  /// No description provided for @doc_action_stop_unless_format_l2.
  ///
  /// In en, this message translates to:
  /// **'You can use wrapped variables: ((message.content[0]))'**
  String get doc_action_stop_unless_format_l2;

  /// No description provided for @doc_action_stop_unless_format_l3.
  ///
  /// In en, this message translates to:
  /// **'Both are resolved by runtime.'**
  String get doc_action_stop_unless_format_l3;

  /// No description provided for @doc_action_stop_unless_example.
  ///
  /// In en, this message translates to:
  /// **'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅'**
  String get doc_action_stop_unless_example;

  /// No description provided for @doc_action_if_block_title.
  ///
  /// In en, this message translates to:
  /// **'Action: ifBlock'**
  String get doc_action_if_block_title;

  /// No description provided for @doc_action_if_block_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Branch execution between THEN, ELSE IF and ELSE nested action lists.'**
  String get doc_action_if_block_subtitle;

  /// No description provided for @doc_action_if_block_summary.
  ///
  /// In en, this message translates to:
  /// **'Use this to keep a single workflow while handling several outcomes based on runtime state.'**
  String get doc_action_if_block_summary;

  /// No description provided for @doc_action_if_block_section_execution.
  ///
  /// In en, this message translates to:
  /// **'Execution Model'**
  String get doc_action_if_block_section_execution;

  /// No description provided for @doc_action_if_block_execution_l1.
  ///
  /// In en, this message translates to:
  /// **'Condition is evaluated once.'**
  String get doc_action_if_block_execution_l1;

  /// No description provided for @doc_action_if_block_execution_l2.
  ///
  /// In en, this message translates to:
  /// **'The first matching branch executes: THEN, then ELSE IF blocks in order, then ELSE.'**
  String get doc_action_if_block_execution_l2;

  /// No description provided for @doc_action_if_block_execution_l3.
  ///
  /// In en, this message translates to:
  /// **'Nested actions can include runWorkflow, API calls, and interaction replies.'**
  String get doc_action_if_block_execution_l3;

  /// No description provided for @doc_action_run_workflow_title.
  ///
  /// In en, this message translates to:
  /// **'Action: runWorkflow'**
  String get doc_action_run_workflow_title;

  /// No description provided for @doc_action_run_workflow_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Calls another workflow with entry point and arguments.'**
  String get doc_action_run_workflow_subtitle;

  /// No description provided for @doc_action_run_workflow_summary.
  ///
  /// In en, this message translates to:
  /// **'Core composition primitive to split business logic into reusable units.'**
  String get doc_action_run_workflow_summary;

  /// No description provided for @doc_action_run_workflow_section_practices.
  ///
  /// In en, this message translates to:
  /// **'Best Practices'**
  String get doc_action_run_workflow_section_practices;

  /// No description provided for @doc_action_run_workflow_practices_l1.
  ///
  /// In en, this message translates to:
  /// **'Keep top-level workflow thin and delegate to domain workflows.'**
  String get doc_action_run_workflow_practices_l1;

  /// No description provided for @doc_action_run_workflow_practices_l2.
  ///
  /// In en, this message translates to:
  /// **'Pass explicit arguments instead of relying on implicit globals.'**
  String get doc_action_run_workflow_practices_l2;

  /// No description provided for @doc_action_run_workflow_practices_l3.
  ///
  /// In en, this message translates to:
  /// **'Use entry points to model sub-routines (create, close, assign, escalate).'**
  String get doc_action_run_workflow_practices_l3;

  /// No description provided for @doc_action_http_request_title.
  ///
  /// In en, this message translates to:
  /// **'Action: httpRequest'**
  String get doc_action_http_request_title;

  /// No description provided for @doc_action_http_request_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Executes an external HTTP call inside a workflow.'**
  String get doc_action_http_request_subtitle;

  /// No description provided for @doc_action_http_request_summary.
  ///
  /// In en, this message translates to:
  /// **'Use this for webhooks, internal APIs, moderation services, AI endpoints, and integrations.'**
  String get doc_action_http_request_summary;

  /// No description provided for @doc_action_http_request_section_checklist.
  ///
  /// In en, this message translates to:
  /// **'Reliability Checklist'**
  String get doc_action_http_request_section_checklist;

  /// No description provided for @doc_action_http_request_checklist_l1.
  ///
  /// In en, this message translates to:
  /// **'Set explicit timeout and retries in your service layer when possible.'**
  String get doc_action_http_request_checklist_l1;

  /// No description provided for @doc_action_http_request_checklist_l2.
  ///
  /// In en, this message translates to:
  /// **'Store API keys in globals or secure backend, never hardcode tokens.'**
  String get doc_action_http_request_checklist_l2;

  /// No description provided for @doc_action_http_request_checklist_l3.
  ///
  /// In en, this message translates to:
  /// **'Validate status code and response body before next actions.'**
  String get doc_action_http_request_checklist_l3;

  /// No description provided for @embed_color_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Pick embed color'**
  String get embed_color_picker_title;

  /// No description provided for @embed_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete embed'**
  String get embed_delete_title;

  /// No description provided for @embed_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This embed will be removed. Continue?'**
  String get embed_delete_confirm;

  /// No description provided for @embed_field_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete field'**
  String get embed_field_delete_title;

  /// No description provided for @embed_field_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This field will be removed from the embed. Continue?'**
  String get embed_field_delete_confirm;

  /// No description provided for @embed_response_header.
  ///
  /// In en, this message translates to:
  /// **'Response Embeds ({count}/{max})'**
  String embed_response_header(int count, int max);

  /// No description provided for @embed_add_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add embed'**
  String get embed_add_tooltip;

  /// No description provided for @embed_empty_message.
  ///
  /// In en, this message translates to:
  /// **'No embeds. You can add up to {max} embeds.'**
  String embed_empty_message(int max);

  /// No description provided for @embed_number.
  ///
  /// In en, this message translates to:
  /// **'Embed #{index}'**
  String embed_number(int index);

  /// No description provided for @embed_label_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get embed_label_title;

  /// No description provided for @embed_label_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get embed_label_url;

  /// No description provided for @embed_label_timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp (ISO8601)'**
  String get embed_label_timestamp;

  /// No description provided for @embed_label_color.
  ///
  /// In en, this message translates to:
  /// **'Color (int or #hex)'**
  String get embed_label_color;

  /// No description provided for @embed_section_footer.
  ///
  /// In en, this message translates to:
  /// **'Footer'**
  String get embed_section_footer;

  /// No description provided for @embed_label_footer_text.
  ///
  /// In en, this message translates to:
  /// **'Footer Text'**
  String get embed_label_footer_text;

  /// No description provided for @embed_label_footer_icon.
  ///
  /// In en, this message translates to:
  /// **'Footer Icon URL'**
  String get embed_label_footer_icon;

  /// No description provided for @embed_section_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get embed_section_author;

  /// No description provided for @embed_label_author_name.
  ///
  /// In en, this message translates to:
  /// **'Author Name'**
  String get embed_label_author_name;

  /// No description provided for @embed_label_author_url.
  ///
  /// In en, this message translates to:
  /// **'Author URL'**
  String get embed_label_author_url;

  /// No description provided for @embed_label_author_icon.
  ///
  /// In en, this message translates to:
  /// **'Author Icon URL'**
  String get embed_label_author_icon;

  /// No description provided for @embed_section_media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get embed_section_media;

  /// No description provided for @embed_label_image_url.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get embed_label_image_url;

  /// No description provided for @embed_label_thumbnail_url.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get embed_label_thumbnail_url;

  /// No description provided for @embed_fields_header.
  ///
  /// In en, this message translates to:
  /// **'Fields ({count}/25)'**
  String embed_fields_header(int count);

  /// No description provided for @embed_fields_empty.
  ///
  /// In en, this message translates to:
  /// **'No fields yet.'**
  String get embed_fields_empty;

  /// No description provided for @embed_field_number.
  ///
  /// In en, this message translates to:
  /// **'Field #{index}'**
  String embed_field_number(int index);

  /// No description provided for @embed_label_inline.
  ///
  /// In en, this message translates to:
  /// **'Inline'**
  String get embed_label_inline;

  /// No description provided for @embed_label_dynamic_fields.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Fields Template'**
  String get embed_label_dynamic_fields;

  /// No description provided for @component_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove component'**
  String get component_remove_title;

  /// No description provided for @component_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'This component will be removed from the layout. Continue?'**
  String get component_remove_confirm;

  /// No description provided for @component_label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get component_label;

  /// No description provided for @component_style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get component_style;

  /// No description provided for @component_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get component_url;

  /// No description provided for @component_custom_id_required.
  ///
  /// In en, this message translates to:
  /// **'Custom ID *'**
  String get component_custom_id_required;

  /// No description provided for @component_validation_required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get component_validation_required;

  /// No description provided for @component_workflow_optional.
  ///
  /// In en, this message translates to:
  /// **'Call Workflow (optional)'**
  String get component_workflow_optional;

  /// No description provided for @component_workflow_click_hint.
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name to run on click'**
  String get component_workflow_click_hint;

  /// No description provided for @component_workflow_select_hint.
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name to run on selection'**
  String get component_workflow_select_hint;

  /// No description provided for @component_custom_id.
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get component_custom_id;

  /// No description provided for @component_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get component_placeholder;

  /// No description provided for @component_options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get component_options;

  /// No description provided for @component_markdown_content.
  ///
  /// In en, this message translates to:
  /// **'Markdown Content'**
  String get component_markdown_content;

  /// No description provided for @component_visible_divider.
  ///
  /// In en, this message translates to:
  /// **'Visible Divider Line'**
  String get component_visible_divider;

  /// No description provided for @component_spacing_small.
  ///
  /// In en, this message translates to:
  /// **'Small Spacing'**
  String get component_spacing_small;

  /// No description provided for @component_spacing_large.
  ///
  /// In en, this message translates to:
  /// **'Large Spacing'**
  String get component_spacing_large;

  /// No description provided for @component_section_text_displays.
  ///
  /// In en, this message translates to:
  /// **'Text Displays'**
  String get component_section_text_displays;

  /// No description provided for @component_add_text_display.
  ///
  /// In en, this message translates to:
  /// **'Add Text Display'**
  String get component_add_text_display;

  /// No description provided for @component_section_accessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory Node (Optional)'**
  String get component_section_accessory;

  /// No description provided for @component_accent_color.
  ///
  /// In en, this message translates to:
  /// **'Accent Color (Hex, e.g. FF0000)'**
  String get component_accent_color;

  /// No description provided for @component_pick_accent_color.
  ///
  /// In en, this message translates to:
  /// **'Pick Accent Color'**
  String get component_pick_accent_color;

  /// No description provided for @component_add_child.
  ///
  /// In en, this message translates to:
  /// **'Add Child Component'**
  String get component_add_child;

  /// No description provided for @component_checked_by_default.
  ///
  /// In en, this message translates to:
  /// **'Checked by default'**
  String get component_checked_by_default;

  /// No description provided for @component_add_radio_option.
  ///
  /// In en, this message translates to:
  /// **'Add Radio Option'**
  String get component_add_radio_option;

  /// No description provided for @component_add_media_item.
  ///
  /// In en, this message translates to:
  /// **'Add Media Item'**
  String get component_add_media_item;

  /// No description provided for @component_not_implemented.
  ///
  /// In en, this message translates to:
  /// **'Editor not implemented yet'**
  String get component_not_implemented;

  /// No description provided for @component_choose_color.
  ///
  /// In en, this message translates to:
  /// **'Choose Color'**
  String get component_choose_color;

  /// No description provided for @component_label_title.
  ///
  /// In en, this message translates to:
  /// **'Label Title'**
  String get component_label_title;

  /// No description provided for @component_workflow_args_title.
  ///
  /// In en, this message translates to:
  /// **'Workflow Call Arguments'**
  String get component_workflow_args_title;

  /// No description provided for @component_workflow_args_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: ticketId = ((opts.ticket))'**
  String get component_workflow_args_hint;

  /// No description provided for @autocomplete_workflow_label.
  ///
  /// In en, this message translates to:
  /// **'Autocomplete Workflow'**
  String get autocomplete_workflow_label;

  /// No description provided for @autocomplete_loading.
  ///
  /// In en, this message translates to:
  /// **'Loading workflows…'**
  String get autocomplete_loading;

  /// No description provided for @autocomplete_no_workflows.
  ///
  /// In en, this message translates to:
  /// **'No saved workflows found'**
  String get autocomplete_no_workflows;

  /// No description provided for @autocomplete_select_workflow.
  ///
  /// In en, this message translates to:
  /// **'Select a saved workflow'**
  String get autocomplete_select_workflow;

  /// No description provided for @autocomplete_type_name.
  ///
  /// In en, this message translates to:
  /// **'Or type workflow name'**
  String get autocomplete_type_name;

  /// No description provided for @workflow_entry_point.
  ///
  /// In en, this message translates to:
  /// **'Entry Point'**
  String get workflow_entry_point;

  /// No description provided for @workflow_arguments_section.
  ///
  /// In en, this message translates to:
  /// **'Workflow Arguments'**
  String get workflow_arguments_section;

  /// No description provided for @hint_use_variables.
  ///
  /// In en, this message translates to:
  /// **'Use variables/templates if needed'**
  String get hint_use_variables;

  /// No description provided for @autocomplete_dynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Autocomplete'**
  String get autocomplete_dynamic;

  /// No description provided for @autocomplete_dynamic_desc.
  ///
  /// In en, this message translates to:
  /// **'Resolve choices from a workflow instead of static values.'**
  String get autocomplete_dynamic_desc;

  /// No description provided for @autocomplete_filter_hint.
  ///
  /// In en, this message translates to:
  /// **'Suggestions are filtered by what the user types.'**
  String get autocomplete_filter_hint;

  /// No description provided for @option_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete option'**
  String get option_delete_title;

  /// No description provided for @option_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This option will be removed. Continue?'**
  String get option_delete_confirm;

  /// No description provided for @option_desc_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a description for the option'**
  String get option_desc_required;

  /// No description provided for @option_delete_argument_title.
  ///
  /// In en, this message translates to:
  /// **'Delete argument'**
  String get option_delete_argument_title;

  /// No description provided for @option_delete_argument_confirm.
  ///
  /// In en, this message translates to:
  /// **'This argument will be removed. Continue?'**
  String get option_delete_argument_confirm;

  /// No description provided for @option_static_label_n.
  ///
  /// In en, this message translates to:
  /// **'Label {index}'**
  String option_static_label_n(int index);

  /// No description provided for @option_static_value_n.
  ///
  /// In en, this message translates to:
  /// **'Value {index}'**
  String option_static_value_n(int index);

  /// No description provided for @option_delete_choice_title.
  ///
  /// In en, this message translates to:
  /// **'Delete option'**
  String get option_delete_choice_title;

  /// No description provided for @option_delete_choice_confirm.
  ///
  /// In en, this message translates to:
  /// **'This choice will be removed. Continue?'**
  String get option_delete_choice_confirm;

  /// No description provided for @option_default_name.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String option_default_name(int index);

  /// No description provided for @option_min_value.
  ///
  /// In en, this message translates to:
  /// **'Min Value'**
  String get option_min_value;

  /// No description provided for @option_max_value.
  ///
  /// In en, this message translates to:
  /// **'Max Value'**
  String get option_max_value;

  /// No description provided for @option_add_localizations.
  ///
  /// In en, this message translates to:
  /// **'Add Localizations'**
  String get option_add_localizations;

  /// No description provided for @option_select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get option_select_language;

  /// No description provided for @option_delete_localization_title.
  ///
  /// In en, this message translates to:
  /// **'Delete localization'**
  String get option_delete_localization_title;

  /// No description provided for @option_delete_localization_confirm.
  ///
  /// In en, this message translates to:
  /// **'This localization entry will be removed. Continue?'**
  String get option_delete_localization_confirm;

  /// No description provided for @option_localized_name.
  ///
  /// In en, this message translates to:
  /// **'Localized Name'**
  String get option_localized_name;

  /// No description provided for @option_localized_description.
  ///
  /// In en, this message translates to:
  /// **'Localized Description'**
  String get option_localized_description;

  /// No description provided for @option_choice_number.
  ///
  /// In en, this message translates to:
  /// **'Choice {index}'**
  String option_choice_number(int index);

  /// No description provided for @option_choice_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete choice'**
  String get option_choice_delete_title;

  /// No description provided for @option_choice_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This choice will be removed. Continue?'**
  String get option_choice_delete_confirm;

  /// No description provided for @option_choice_name.
  ///
  /// In en, this message translates to:
  /// **'Choice Name'**
  String get option_choice_name;

  /// No description provided for @option_choice_value.
  ///
  /// In en, this message translates to:
  /// **'Choice Value'**
  String get option_choice_value;

  /// No description provided for @option_add_choice.
  ///
  /// In en, this message translates to:
  /// **'Add Choice'**
  String get option_add_choice;

  /// No description provided for @option_subcommands.
  ///
  /// In en, this message translates to:
  /// **'SubCommands'**
  String get option_subcommands;

  /// No description provided for @option_subcommand_options.
  ///
  /// In en, this message translates to:
  /// **'SubCommand Options'**
  String get option_subcommand_options;

  /// No description provided for @action_options_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Action options'**
  String get action_options_tooltip;

  /// No description provided for @action_remove_menu.
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get action_remove_menu;

  /// No description provided for @action_order_tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: use arrows to change action order.'**
  String get action_order_tip;

  /// No description provided for @action_key_field.
  ///
  /// In en, this message translates to:
  /// **'Action Key'**
  String get action_key_field;

  /// No description provided for @action_on_error.
  ///
  /// In en, this message translates to:
  /// **'On Error'**
  String get action_on_error;

  /// No description provided for @action_error_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get action_error_stop;

  /// No description provided for @action_error_continue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get action_error_continue;

  /// No description provided for @action_advanced_settings.
  ///
  /// In en, this message translates to:
  /// **'Advanced settings'**
  String get action_advanced_settings;

  /// No description provided for @action_status_enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get action_status_enabled;

  /// No description provided for @action_status_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get action_status_disabled;

  /// No description provided for @action_remove_title.
  ///
  /// In en, this message translates to:
  /// **'Remove action'**
  String get action_remove_title;

  /// No description provided for @action_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'This action will be removed from the workflow. Continue?'**
  String get action_remove_confirm;

  /// No description provided for @action_store_results.
  ///
  /// In en, this message translates to:
  /// **'Store results in global variables'**
  String get action_store_results;

  /// No description provided for @action_http_test_button.
  ///
  /// In en, this message translates to:
  /// **'Send Test Request & Auto-Detect Routes'**
  String get action_http_test_button;

  /// No description provided for @action_http_test_title.
  ///
  /// In en, this message translates to:
  /// **'Test Request Results'**
  String get action_http_test_title;

  /// No description provided for @action_http_status.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String action_http_status(String status);

  /// No description provided for @action_http_paths_parsed.
  ///
  /// In en, this message translates to:
  /// **'{count} paths parsed'**
  String action_http_paths_parsed(int count);

  /// No description provided for @action_http_response_body.
  ///
  /// In en, this message translates to:
  /// **'Response Body (Raw):'**
  String get action_http_response_body;

  /// No description provided for @action_literal.
  ///
  /// In en, this message translates to:
  /// **'Literal'**
  String get action_literal;

  /// No description provided for @action_dynamic.
  ///
  /// In en, this message translates to:
  /// **'Dynamic'**
  String get action_dynamic;

  /// No description provided for @action_add_else_if.
  ///
  /// In en, this message translates to:
  /// **'Add ELSE IF'**
  String get action_add_else_if;

  /// No description provided for @action_remove_else_if.
  ///
  /// In en, this message translates to:
  /// **'Remove ELSE IF'**
  String get action_remove_else_if;

  /// No description provided for @action_condition_variable.
  ///
  /// In en, this message translates to:
  /// **'Condition Variable'**
  String get action_condition_variable;

  /// No description provided for @action_condition_value.
  ///
  /// In en, this message translates to:
  /// **'Condition Value'**
  String get action_condition_value;

  /// No description provided for @action_else_if_label.
  ///
  /// In en, this message translates to:
  /// **'ELSE IF {index} — actions'**
  String action_else_if_label(int index);

  /// No description provided for @action_expression.
  ///
  /// In en, this message translates to:
  /// **'Expression'**
  String get action_expression;

  /// No description provided for @action_edit_param.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String action_edit_param(String name);

  /// No description provided for @action_choose_param.
  ///
  /// In en, this message translates to:
  /// **'Choose {name}'**
  String action_choose_param(String name);

  /// No description provided for @action_format_json.
  ///
  /// In en, this message translates to:
  /// **'Format JSON'**
  String get action_format_json;

  /// No description provided for @action_add_header.
  ///
  /// In en, this message translates to:
  /// **'Add header'**
  String get action_add_header;

  /// No description provided for @action_clear_all.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get action_clear_all;

  /// No description provided for @action_refresh_keys.
  ///
  /// In en, this message translates to:
  /// **'Refresh keys'**
  String get action_refresh_keys;

  /// No description provided for @action_manage_variable_keys.
  ///
  /// In en, this message translates to:
  /// **'Manage Variable Keys'**
  String get action_manage_variable_keys;

  /// No description provided for @validation_command_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a command name'**
  String get validation_command_name_required;

  /// No description provided for @validation_awaited_callback_local_only.
  ///
  /// In en, this message translates to:
  /// **'Awaited callbacks require a local-only Legacy Command.'**
  String get validation_awaited_callback_local_only;

  /// No description provided for @validation_awaited_callback_length.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback trigger must be at most {max} characters long'**
  String validation_awaited_callback_length(int max);

  /// No description provided for @validation_awaited_callback_format.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback must use \$awaitedCommand[name;filter] or \$awaitedCommandError[name].'**
  String get validation_awaited_callback_format;

  /// No description provided for @validation_command_name_length.
  ///
  /// In en, this message translates to:
  /// **'Command name must be at most {max} characters long'**
  String validation_command_name_length(int max);

  /// No description provided for @validation_command_name_no_spaces.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot contain spaces'**
  String get validation_command_name_no_spaces;

  /// No description provided for @validation_command_name_invalid_chars.
  ///
  /// In en, this message translates to:
  /// **'Command name can only contain letters, numbers, and underscores'**
  String get validation_command_name_invalid_chars;

  /// No description provided for @validation_command_name_no_underscore.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an underscore'**
  String get validation_command_name_no_underscore;

  /// No description provided for @validation_command_name_no_exclamation.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an exclamation mark'**
  String get validation_command_name_no_exclamation;

  /// No description provided for @validation_command_name_no_slash.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a slash'**
  String get validation_command_name_no_slash;

  /// No description provided for @validation_command_name_no_hash.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a hash'**
  String get validation_command_name_no_hash;

  /// No description provided for @validation_command_name_no_at.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an at sign'**
  String get validation_command_name_no_at;

  /// No description provided for @validation_command_name_no_ampersand.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with an ampersand'**
  String get validation_command_name_no_ampersand;

  /// No description provided for @validation_command_name_no_percent.
  ///
  /// In en, this message translates to:
  /// **'Command name cannot start with a percent sign'**
  String get validation_command_name_no_percent;

  /// No description provided for @validation_legacy_chat_input_only.
  ///
  /// In en, this message translates to:
  /// **'Legacy mode is only available for chat input commands.'**
  String get validation_legacy_chat_input_only;

  /// No description provided for @validation_modal_not_legacy.
  ///
  /// In en, this message translates to:
  /// **'Modal responses are not supported in legacy command mode.'**
  String get validation_modal_not_legacy;

  /// No description provided for @validation_legacy_only_requires_legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy-only commands require legacy mode to be enabled.'**
  String get validation_legacy_only_requires_legacy;

  /// No description provided for @validation_legacy_only_new_or_local.
  ///
  /// In en, this message translates to:
  /// **'Legacy-only mode can only be used for new commands or existing local commands.'**
  String get validation_legacy_only_new_or_local;

  /// No description provided for @validation_invalid_permissions.
  ///
  /// In en, this message translates to:
  /// **'Invalid default member permissions bitfield. Use a positive integer or leave empty.'**
  String get validation_invalid_permissions;

  /// No description provided for @scheduler_no_workflows.
  ///
  /// In en, this message translates to:
  /// **'Create at least one workflow before adding a schedule.'**
  String get scheduler_no_workflows;

  /// No description provided for @scheduler_add_title.
  ///
  /// In en, this message translates to:
  /// **'Add schedule'**
  String get scheduler_add_title;

  /// No description provided for @scheduler_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit schedule'**
  String get scheduler_edit_title;

  /// No description provided for @scheduler_label_hint.
  ///
  /// In en, this message translates to:
  /// **'Optional display label'**
  String get scheduler_label_hint;

  /// No description provided for @scheduler_label_field.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get scheduler_label_field;

  /// No description provided for @scheduler_every_minutes.
  ///
  /// In en, this message translates to:
  /// **'Every (minutes)'**
  String get scheduler_every_minutes;

  /// No description provided for @scheduler_invalid_minutes.
  ///
  /// In en, this message translates to:
  /// **'Every minutes must be greater than 0.'**
  String get scheduler_invalid_minutes;

  /// No description provided for @scheduler_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Scheduler limit reached ({limit}).'**
  String scheduler_limit_reached(int limit);

  /// No description provided for @scheduler_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save schedule: {error}'**
  String scheduler_save_failed(String error);

  /// No description provided for @scheduler_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete schedule'**
  String get scheduler_delete_title;

  /// No description provided for @scheduler_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\" schedule?'**
  String scheduler_delete_confirm(String label);

  /// No description provided for @scheduler_page_title.
  ///
  /// In en, this message translates to:
  /// **'Scheduler'**
  String get scheduler_page_title;

  /// No description provided for @scheduler_add_trigger.
  ///
  /// In en, this message translates to:
  /// **'Add trigger'**
  String get scheduler_add_trigger;

  /// No description provided for @scheduler_triggers_count.
  ///
  /// In en, this message translates to:
  /// **'Triggers: {count}{limit}'**
  String scheduler_triggers_count(int count, String limit);

  /// No description provided for @scheduler_empty.
  ///
  /// In en, this message translates to:
  /// **'No scheduled triggers yet.'**
  String get scheduler_empty;

  /// No description provided for @webhooks_no_workflows.
  ///
  /// In en, this message translates to:
  /// **'Create at least one workflow before adding an inbound webhook.'**
  String get webhooks_no_workflows;

  /// No description provided for @webhooks_add_title.
  ///
  /// In en, this message translates to:
  /// **'Add inbound webhook'**
  String get webhooks_add_title;

  /// No description provided for @webhooks_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit inbound webhook'**
  String get webhooks_edit_title;

  /// No description provided for @webhooks_path_label.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get webhooks_path_label;

  /// No description provided for @webhooks_path_hint.
  ///
  /// In en, this message translates to:
  /// **'orders/new'**
  String get webhooks_path_hint;

  /// No description provided for @webhooks_target_label.
  ///
  /// In en, this message translates to:
  /// **'Workflow target'**
  String get webhooks_target_label;

  /// No description provided for @webhooks_secret_label.
  ///
  /// In en, this message translates to:
  /// **'Webhook secret'**
  String get webhooks_secret_label;

  /// No description provided for @webhooks_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get webhooks_generate;

  /// No description provided for @webhooks_limit_reached.
  ///
  /// In en, this message translates to:
  /// **'Inbound webhook limit reached ({limit}).'**
  String webhooks_limit_reached(int limit);

  /// No description provided for @webhooks_path_exists.
  ///
  /// In en, this message translates to:
  /// **'This path already exists. Choose another one.'**
  String get webhooks_path_exists;

  /// No description provided for @webhooks_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save inbound webhook: {error}'**
  String webhooks_save_failed(String error);

  /// No description provided for @webhooks_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete inbound webhook?'**
  String get webhooks_delete_title;

  /// No description provided for @webhooks_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{label}\"? This cannot be undone.'**
  String webhooks_delete_confirm(String label);

  /// No description provided for @webhooks_delete_confirm_no_label.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get webhooks_delete_confirm_no_label;

  /// No description provided for @webhooks_runner_url_required.
  ///
  /// In en, this message translates to:
  /// **'Configure a Runner URL first to copy the full webhook URL.'**
  String get webhooks_runner_url_required;

  /// No description provided for @webhooks_missing_data.
  ///
  /// In en, this message translates to:
  /// **'Webhook path or secret is missing.'**
  String get webhooks_missing_data;

  /// No description provided for @webhooks_copied.
  ///
  /// In en, this message translates to:
  /// **'Full webhook URL copied.'**
  String get webhooks_copied;

  /// No description provided for @webhooks_invalid_runner_url.
  ///
  /// In en, this message translates to:
  /// **'Runner URL is invalid.'**
  String get webhooks_invalid_runner_url;

  /// No description provided for @webhooks_page_title.
  ///
  /// In en, this message translates to:
  /// **'Inbound Webhooks'**
  String get webhooks_page_title;

  /// No description provided for @webhooks_add_action.
  ///
  /// In en, this message translates to:
  /// **'Add webhook'**
  String get webhooks_add_action;

  /// No description provided for @webhooks_empty.
  ///
  /// In en, this message translates to:
  /// **'No inbound webhooks yet.'**
  String get webhooks_empty;

  /// No description provided for @webhooks_workflow_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Workflow: {workflow}'**
  String webhooks_workflow_subtitle(String workflow);

  /// No description provided for @webhooks_copy_url.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get webhooks_copy_url;

  /// No description provided for @webhooks_copy_path.
  ///
  /// In en, this message translates to:
  /// **'Copy path'**
  String get webhooks_copy_path;

  /// No description provided for @webhooks_copy_secret.
  ///
  /// In en, this message translates to:
  /// **'Copy secret'**
  String get webhooks_copy_secret;

  /// No description provided for @webhooks_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get webhooks_actions;

  /// No description provided for @command_legacy_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Enable legacy mode on this command'**
  String get command_legacy_mode_title;

  /// No description provided for @command_legacy_mode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses positional options (example: !config #channel).'**
  String get command_legacy_mode_subtitle;

  /// No description provided for @command_legacy_prefix_title.
  ///
  /// In en, this message translates to:
  /// **'Legacy Prefix Mode'**
  String get command_legacy_prefix_title;

  /// No description provided for @command_legacy_prefix_desc.
  ///
  /// In en, this message translates to:
  /// **'Handle commands from messageCreate using <prefix><command>.'**
  String get command_legacy_prefix_desc;

  /// No description provided for @command_prefix_override_label.
  ///
  /// In en, this message translates to:
  /// **'Prefix override (optional)'**
  String get command_prefix_override_label;

  /// No description provided for @command_prefix_override_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: ? or ((guild.prefix | !))'**
  String get command_prefix_override_hint;

  /// No description provided for @command_legacy_response_label.
  ///
  /// In en, this message translates to:
  /// **'Legacy response mode'**
  String get command_legacy_response_label;

  /// No description provided for @command_response_mode_reply.
  ///
  /// In en, this message translates to:
  /// **'message.reply'**
  String get command_response_mode_reply;

  /// No description provided for @command_response_mode_channel.
  ///
  /// In en, this message translates to:
  /// **'message.channel.send'**
  String get command_response_mode_channel;

  /// No description provided for @command_modal_disabled_legacy.
  ///
  /// In en, this message translates to:
  /// **'Modals are disabled in legacy mode.'**
  String get command_modal_disabled_legacy;

  /// No description provided for @command_target_subcommand.
  ///
  /// In en, this message translates to:
  /// **'Target subcommand'**
  String get command_target_subcommand;

  /// No description provided for @command_unsaved_title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get command_unsaved_title;

  /// No description provided for @command_unsaved_confirm.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them?'**
  String get command_unsaved_confirm;

  /// No description provided for @command_unsaved_keep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get command_unsaved_keep;

  /// No description provided for @command_error_missing_bot_id.
  ///
  /// In en, this message translates to:
  /// **'Missing bot id for local command save.'**
  String get command_error_missing_bot_id;

  /// No description provided for @command_import_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Import command payload'**
  String get command_import_tooltip;

  /// No description provided for @command_export_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Export command payload'**
  String get command_export_tooltip;

  /// No description provided for @actions_missing_field_title.
  ///
  /// In en, this message translates to:
  /// **'Missing Required Field'**
  String get actions_missing_field_title;

  /// No description provided for @actions_no_matches.
  ///
  /// In en, this message translates to:
  /// **'No actions match your search.'**
  String get actions_no_matches;

  /// No description provided for @actions_add_new_title.
  ///
  /// In en, this message translates to:
  /// **'Add New Action'**
  String get actions_add_new_title;

  /// No description provided for @actions_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search actions...'**
  String get actions_search_hint;

  /// No description provided for @actions_add_label.
  ///
  /// In en, this message translates to:
  /// **'Add Action'**
  String get actions_add_label;

  /// No description provided for @actions_builder_title.
  ///
  /// In en, this message translates to:
  /// **'Actions Builder'**
  String get actions_builder_title;

  /// No description provided for @actions_save_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Save Actions'**
  String get actions_save_tooltip;

  /// No description provided for @actions_key_label.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String actions_key_label(String key);

  /// No description provided for @modal_remove_field_title.
  ///
  /// In en, this message translates to:
  /// **'Remove modal field'**
  String get modal_remove_field_title;

  /// No description provided for @modal_remove_field_confirm.
  ///
  /// In en, this message translates to:
  /// **'This field will be removed from the modal. Continue?'**
  String get modal_remove_field_confirm;

  /// No description provided for @modal_title_label.
  ///
  /// In en, this message translates to:
  /// **'Modal Title'**
  String get modal_title_label;

  /// No description provided for @modal_custom_id_label.
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get modal_custom_id_label;

  /// No description provided for @modal_custom_id_hint.
  ///
  /// In en, this message translates to:
  /// **'Used to identify this modal'**
  String get modal_custom_id_hint;

  /// No description provided for @modal_workflow_submit.
  ///
  /// In en, this message translates to:
  /// **'Workflow to run on submit (optional)'**
  String get modal_workflow_submit;

  /// No description provided for @modal_add_text_input.
  ///
  /// In en, this message translates to:
  /// **'Add Text Input'**
  String get modal_add_text_input;

  /// No description provided for @modal_field_default_label.
  ///
  /// In en, this message translates to:
  /// **'Field {index}'**
  String modal_field_default_label(int index);

  /// No description provided for @modal_style.
  ///
  /// In en, this message translates to:
  /// **'Style:'**
  String get modal_style;

  /// No description provided for @modal_default_value.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get modal_default_value;

  /// No description provided for @command_legacy_preset_title.
  ///
  /// In en, this message translates to:
  /// **'Legacy preset'**
  String get command_legacy_preset_title;

  /// No description provided for @command_legacy_preset_desc.
  ///
  /// In en, this message translates to:
  /// **'Generate an internal awaited callback trigger and switch this command to the required local legacy setup.'**
  String get command_legacy_preset_desc;

  /// No description provided for @command_awaited_preset_button.
  ///
  /// In en, this message translates to:
  /// **'Use Awaited Callback Preset'**
  String get command_awaited_preset_button;

  /// No description provided for @command_awaited_preset_active.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback preset'**
  String get command_awaited_preset_active;

  /// No description provided for @command_edit_raw_name.
  ///
  /// In en, this message translates to:
  /// **'Edit Raw Name'**
  String get command_edit_raw_name;

  /// No description provided for @command_awaited_preset_desc.
  ///
  /// In en, this message translates to:
  /// **'The command name is generated for you and saved as an internal legacy callback.'**
  String get command_awaited_preset_desc;

  /// No description provided for @command_awaited_success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get command_awaited_success;

  /// No description provided for @command_awaited_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get command_awaited_error;

  /// No description provided for @command_awaited_name_label.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback name'**
  String get command_awaited_name_label;

  /// No description provided for @command_awaited_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: say'**
  String get command_awaited_name_hint;

  /// No description provided for @command_awaited_filter_label.
  ///
  /// In en, this message translates to:
  /// **'Filter (optional)'**
  String get command_awaited_filter_label;

  /// No description provided for @command_awaited_filter_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: <numeric> or <yes/no/cancel>'**
  String get command_awaited_filter_hint;

  /// No description provided for @command_info_title.
  ///
  /// In en, this message translates to:
  /// **'Command Info'**
  String get command_info_title;

  /// No description provided for @command_info_desc.
  ///
  /// In en, this message translates to:
  /// **'Basic metadata and availability'**
  String get command_info_desc;

  /// No description provided for @command_name_label.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get command_name_label;

  /// No description provided for @command_name_generated.
  ///
  /// In en, this message translates to:
  /// **'Generated by the awaited callback preset.'**
  String get command_name_generated;

  /// No description provided for @command_type_label.
  ///
  /// In en, this message translates to:
  /// **'Command Type'**
  String get command_type_label;

  /// No description provided for @command_type_slash.
  ///
  /// In en, this message translates to:
  /// **'Slash Command'**
  String get command_type_slash;

  /// No description provided for @command_type_legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy Command'**
  String get command_type_legacy;

  /// No description provided for @command_type_user.
  ///
  /// In en, this message translates to:
  /// **'User Command'**
  String get command_type_user;

  /// No description provided for @command_type_message.
  ///
  /// In en, this message translates to:
  /// **'Message Command'**
  String get command_type_message;

  /// No description provided for @command_integration_guild.
  ///
  /// In en, this message translates to:
  /// **'Guild Install'**
  String get command_integration_guild;

  /// No description provided for @command_integration_user.
  ///
  /// In en, this message translates to:
  /// **'User Install'**
  String get command_integration_user;

  /// No description provided for @command_context_guild.
  ///
  /// In en, this message translates to:
  /// **'Guild'**
  String get command_context_guild;

  /// No description provided for @command_context_bot_dm.
  ///
  /// In en, this message translates to:
  /// **'Bot DM'**
  String get command_context_bot_dm;

  /// No description provided for @command_context_group_dm.
  ///
  /// In en, this message translates to:
  /// **'Group DM / Other'**
  String get command_context_group_dm;

  /// No description provided for @command_permissions_title.
  ///
  /// In en, this message translates to:
  /// **'Select permissions'**
  String get command_permissions_title;

  /// No description provided for @command_prefix_helper.
  ///
  /// In en, this message translates to:
  /// **'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))'**
  String get command_prefix_helper;

  /// No description provided for @actions_title.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions_title;

  /// No description provided for @actions_description.
  ///
  /// In en, this message translates to:
  /// **'Build runtime actions for this command'**
  String get actions_description;

  /// No description provided for @actions_active_route.
  ///
  /// In en, this message translates to:
  /// **'Active route: {label}'**
  String actions_active_route(String label);

  /// No description provided for @actions_build_button.
  ///
  /// In en, this message translates to:
  /// **'Build Actions ({count})'**
  String actions_build_button(int count);

  /// No description provided for @actions_save_workflow_title.
  ///
  /// In en, this message translates to:
  /// **'Save as Workflow'**
  String get actions_save_workflow_title;

  /// No description provided for @actions_workflow_name_label.
  ///
  /// In en, this message translates to:
  /// **'Workflow name'**
  String get actions_workflow_name_label;

  /// No description provided for @actions_global_variables.
  ///
  /// In en, this message translates to:
  /// **'Global Variables'**
  String get actions_global_variables;

  /// No description provided for @actions_workflows.
  ///
  /// In en, this message translates to:
  /// **'Workflows'**
  String get actions_workflows;

  /// No description provided for @wizard_quick_start_applied.
  ///
  /// In en, this message translates to:
  /// **'Quick start applied to the command draft.'**
  String get wizard_quick_start_applied;

  /// No description provided for @wizard_advanced_trigger.
  ///
  /// In en, this message translates to:
  /// **'Advanced trigger settings'**
  String get wizard_advanced_trigger;

  /// No description provided for @wizard_edit_reply.
  ///
  /// In en, this message translates to:
  /// **'Edit reply details'**
  String get wizard_edit_reply;

  /// No description provided for @wizard_quick_starts.
  ///
  /// In en, this message translates to:
  /// **'Quick starts'**
  String get wizard_quick_starts;

  /// No description provided for @wizard_apply_quick_start.
  ///
  /// In en, this message translates to:
  /// **'Apply quick start to draft'**
  String get wizard_apply_quick_start;

  /// No description provided for @wizard_code_advanced.
  ///
  /// In en, this message translates to:
  /// **'Code / Advanced'**
  String get wizard_code_advanced;

  /// No description provided for @serialization_export_json_title.
  ///
  /// In en, this message translates to:
  /// **'Export command as JSON'**
  String get serialization_export_json_title;

  /// No description provided for @serialization_export_json_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Copy readable JSON to clipboard'**
  String get serialization_export_json_subtitle;

  /// No description provided for @serialization_export_base64_title.
  ///
  /// In en, this message translates to:
  /// **'Export command as Base64'**
  String get serialization_export_base64_title;

  /// No description provided for @serialization_import_title.
  ///
  /// In en, this message translates to:
  /// **'Import command'**
  String get serialization_import_title;

  /// No description provided for @serialization_import_desc.
  ///
  /// In en, this message translates to:
  /// **'Paste a command payload (JSON or Base64).'**
  String get serialization_import_desc;

  /// No description provided for @serialization_invalid_format.
  ///
  /// In en, this message translates to:
  /// **'Invalid command payload format.'**
  String get serialization_invalid_format;

  /// No description provided for @serialization_invalid_structure.
  ///
  /// In en, this message translates to:
  /// **'Invalid command payload structure.'**
  String get serialization_invalid_structure;

  /// No description provided for @serialization_imported.
  ///
  /// In en, this message translates to:
  /// **'Command imported into editor.'**
  String get serialization_imported;

  /// No description provided for @response_workflow_title.
  ///
  /// In en, this message translates to:
  /// **'Response Workflow'**
  String get response_workflow_title;

  /// No description provided for @response_workflow_auto_defer.
  ///
  /// In en, this message translates to:
  /// **'Auto defer if actions exist'**
  String get response_workflow_auto_defer;

  /// No description provided for @response_workflow_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get response_workflow_public;

  /// No description provided for @response_workflow_error_policy.
  ///
  /// In en, this message translates to:
  /// **'Error policy'**
  String get response_workflow_error_policy;

  /// No description provided for @response_workflow_enable_condition.
  ///
  /// In en, this message translates to:
  /// **'Enable condition'**
  String get response_workflow_enable_condition;

  /// No description provided for @response_workflow_mode_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get response_workflow_mode_normal;

  /// No description provided for @response_workflow_mode_component.
  ///
  /// In en, this message translates to:
  /// **'Component'**
  String get response_workflow_mode_component;

  /// No description provided for @response_workflow_mode_modal.
  ///
  /// In en, this message translates to:
  /// **'Modal'**
  String get response_workflow_mode_modal;

  /// No description provided for @response_workflow_revert_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Revert all changes'**
  String get response_workflow_revert_tooltip;

  /// No description provided for @response_workflow_then_text.
  ///
  /// In en, this message translates to:
  /// **'THEN response text (optional)'**
  String get response_workflow_then_text;

  /// No description provided for @response_workflow_else_text.
  ///
  /// In en, this message translates to:
  /// **'ELSE response text (optional)'**
  String get response_workflow_else_text;

  /// No description provided for @recovery_label.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get recovery_label;

  /// No description provided for @recovery_title.
  ///
  /// In en, this message translates to:
  /// **'Recovery mode'**
  String get recovery_title;

  /// No description provided for @recovery_retry_discord.
  ///
  /// In en, this message translates to:
  /// **'Retry Discord connection'**
  String get recovery_retry_discord;

  /// No description provided for @recovery_delete_bot.
  ///
  /// In en, this message translates to:
  /// **'Delete bot locally'**
  String get recovery_delete_bot;

  /// No description provided for @nav_webhooks.
  ///
  /// In en, this message translates to:
  /// **'Webhooks'**
  String get nav_webhooks;

  /// No description provided for @nav_webhooks_compact.
  ///
  /// In en, this message translates to:
  /// **'Hooks'**
  String get nav_webhooks_compact;

  /// No description provided for @reply_configure_workflow.
  ///
  /// In en, this message translates to:
  /// **'Configure Response Workflow'**
  String get reply_configure_workflow;

  /// No description provided for @reply_buttons_optional.
  ///
  /// In en, this message translates to:
  /// **'Buttons & Select Menus (optional)'**
  String get reply_buttons_optional;

  /// No description provided for @reply_mode_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard Message'**
  String get reply_mode_standard;

  /// No description provided for @reply_mode_layout.
  ///
  /// In en, this message translates to:
  /// **'Layout Mode'**
  String get reply_mode_layout;

  /// No description provided for @reply_mode_modal.
  ///
  /// In en, this message translates to:
  /// **'Modal Form'**
  String get reply_mode_modal;

  /// No description provided for @emojis_rename_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get emojis_rename_tooltip;

  /// No description provided for @emojis_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get emojis_delete_tooltip;

  /// No description provided for @component_remove_row_title.
  ///
  /// In en, this message translates to:
  /// **'Remove action row'**
  String get component_remove_row_title;

  /// No description provided for @component_add_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Component'**
  String get component_add_tooltip;

  /// No description provided for @component_add_root.
  ///
  /// In en, this message translates to:
  /// **'Add Root Component'**
  String get component_add_root;

  /// No description provided for @edit_shell_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get edit_shell_save_changes;

  /// No description provided for @edit_shell_all_saved.
  ///
  /// In en, this message translates to:
  /// **'All changes saved'**
  String get edit_shell_all_saved;

  /// No description provided for @edit_shell_local_only.
  ///
  /// In en, this message translates to:
  /// **'Local-only'**
  String get edit_shell_local_only;

  /// No description provided for @edit_shell_local_draft.
  ///
  /// In en, this message translates to:
  /// **'Local draft'**
  String get edit_shell_local_draft;

  /// No description provided for @edit_shell_unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get edit_shell_unsaved;

  /// No description provided for @edit_shell_untitled_command.
  ///
  /// In en, this message translates to:
  /// **'Untitled command'**
  String get edit_shell_untitled_command;

  /// No description provided for @edit_shell_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Settings and inputs are at the top. Actions and reply follow below.'**
  String get edit_shell_subtitle;

  /// No description provided for @edit_shell_routes_count.
  ///
  /// In en, this message translates to:
  /// **'{count} route(s)'**
  String edit_shell_routes_count(int count);

  /// No description provided for @edit_shell_command_settings.
  ///
  /// In en, this message translates to:
  /// **'Command settings'**
  String get edit_shell_command_settings;

  /// No description provided for @edit_shell_command_settings_desc.
  ///
  /// In en, this message translates to:
  /// **'Metadata, availability, permissions, and folder placement.'**
  String get edit_shell_command_settings_desc;

  /// No description provided for @edit_shell_trigger_inputs.
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get edit_shell_trigger_inputs;

  /// No description provided for @edit_shell_trigger_inputs_desc.
  ///
  /// In en, this message translates to:
  /// **'Adjust command options, trigger behavior, and execution mode.'**
  String get edit_shell_trigger_inputs_desc;

  /// No description provided for @edit_shell_command_body.
  ///
  /// In en, this message translates to:
  /// **'Command body'**
  String get edit_shell_command_body;

  /// No description provided for @edit_shell_type_legacy.
  ///
  /// In en, this message translates to:
  /// **'Legacy command'**
  String get edit_shell_type_legacy;

  /// No description provided for @edit_shell_type_user.
  ///
  /// In en, this message translates to:
  /// **'User command'**
  String get edit_shell_type_user;

  /// No description provided for @edit_shell_type_message.
  ///
  /// In en, this message translates to:
  /// **'Message command'**
  String get edit_shell_type_message;

  /// No description provided for @edit_shell_type_slash.
  ///
  /// In en, this message translates to:
  /// **'Slash command'**
  String get edit_shell_type_slash;

  /// No description provided for @edit_shell_type_command.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get edit_shell_type_command;

  /// No description provided for @wizard_step_infos.
  ///
  /// In en, this message translates to:
  /// **'Infos'**
  String get wizard_step_infos;

  /// No description provided for @wizard_step_trigger_inputs.
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get wizard_step_trigger_inputs;

  /// No description provided for @wizard_step_reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get wizard_step_reply;

  /// No description provided for @wizard_step_actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get wizard_step_actions;

  /// No description provided for @wizard_step_review.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get wizard_step_review;

  /// No description provided for @review_info_title.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get review_info_title;

  /// No description provided for @review_name_untitled.
  ///
  /// In en, this message translates to:
  /// **'(untitled)'**
  String get review_name_untitled;

  /// No description provided for @review_name_line.
  ///
  /// In en, this message translates to:
  /// **'Name: {name}'**
  String review_name_line(String name);

  /// No description provided for @review_type_line.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String review_type_line(String type);

  /// No description provided for @review_description_line.
  ///
  /// In en, this message translates to:
  /// **'Description: {desc}'**
  String review_description_line(String desc);

  /// No description provided for @review_folder_line.
  ///
  /// In en, this message translates to:
  /// **'Folder: {folder}'**
  String review_folder_line(String folder);

  /// No description provided for @review_options_count.
  ///
  /// In en, this message translates to:
  /// **'{count} option(s)'**
  String review_options_count(int count);

  /// No description provided for @review_subcommand_routes.
  ///
  /// In en, this message translates to:
  /// **'{count} subcommand route(s)'**
  String review_subcommand_routes(int count);

  /// No description provided for @review_legacy_mode.
  ///
  /// In en, this message translates to:
  /// **'Legacy mode enabled'**
  String get review_legacy_mode;

  /// No description provided for @review_local_only.
  ///
  /// In en, this message translates to:
  /// **'Local-only command'**
  String get review_local_only;

  /// No description provided for @review_trigger_inputs_title.
  ///
  /// In en, this message translates to:
  /// **'Trigger & Inputs'**
  String get review_trigger_inputs_title;

  /// No description provided for @review_reply_title.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get review_reply_title;

  /// No description provided for @review_actions_title.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get review_actions_title;

  /// No description provided for @wizard_save_command.
  ///
  /// In en, this message translates to:
  /// **'Save command'**
  String get wizard_save_command;

  /// No description provided for @wizard_create_command.
  ///
  /// In en, this message translates to:
  /// **'Create command'**
  String get wizard_create_command;

  /// No description provided for @wizard_reply_summary.
  ///
  /// In en, this message translates to:
  /// **'Reply summary'**
  String get wizard_reply_summary;

  /// No description provided for @wizard_legacy_options_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Legacy command options and local-only behavior'**
  String get wizard_legacy_options_subtitle;

  /// No description provided for @wizard_quick_start_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Use the legacy simple builder as a starting point, then apply it to the shared draft.'**
  String get wizard_quick_start_subtitle;

  /// No description provided for @wizard_bdfd_mode_enabled.
  ///
  /// In en, this message translates to:
  /// **'BDFD script mode enabled'**
  String get wizard_bdfd_mode_enabled;

  /// No description provided for @wizard_visual_mode_enabled.
  ///
  /// In en, this message translates to:
  /// **'Visual workflow mode enabled'**
  String get wizard_visual_mode_enabled;

  /// No description provided for @wizard_command_body.
  ///
  /// In en, this message translates to:
  /// **'Command body'**
  String get wizard_command_body;

  /// No description provided for @response_mode_layout.
  ///
  /// In en, this message translates to:
  /// **'Layout mode'**
  String get response_mode_layout;

  /// No description provided for @response_mode_modal.
  ///
  /// In en, this message translates to:
  /// **'Modal form'**
  String get response_mode_modal;

  /// No description provided for @response_mode_standard.
  ///
  /// In en, this message translates to:
  /// **'Standard message'**
  String get response_mode_standard;

  /// No description provided for @response_visibility_ephemeral.
  ///
  /// In en, this message translates to:
  /// **'ephemeral'**
  String get response_visibility_ephemeral;

  /// No description provided for @response_visibility_public.
  ///
  /// In en, this message translates to:
  /// **'public'**
  String get response_visibility_public;

  /// No description provided for @response_embeds_count.
  ///
  /// In en, this message translates to:
  /// **'{count} embed(s)'**
  String response_embeds_count(int count);

  /// No description provided for @response_interactive_components.
  ///
  /// In en, this message translates to:
  /// **'interactive components'**
  String get response_interactive_components;

  /// No description provided for @command_options_title.
  ///
  /// In en, this message translates to:
  /// **'Command Options'**
  String get command_options_title;

  /// No description provided for @command_options_slash_params.
  ///
  /// In en, this message translates to:
  /// **'Slash-command parameters'**
  String get command_options_slash_params;

  /// No description provided for @command_options_legacy_params.
  ///
  /// In en, this message translates to:
  /// **'Legacy positional parameters (ordered: required then optional)'**
  String get command_options_legacy_params;

  /// No description provided for @legacy_prefix_mode_title.
  ///
  /// In en, this message translates to:
  /// **'Legacy Prefix Mode'**
  String get legacy_prefix_mode_title;

  /// No description provided for @legacy_prefix_mode_desc.
  ///
  /// In en, this message translates to:
  /// **'Handle commands from messageCreate using <prefix><command>.'**
  String get legacy_prefix_mode_desc;

  /// No description provided for @legacy_prefix_mode_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Uses positional options (example: !config #channel).'**
  String get legacy_prefix_mode_subtitle;

  /// No description provided for @legacy_prefix_override_label.
  ///
  /// In en, this message translates to:
  /// **'Prefix override (optional)'**
  String get legacy_prefix_override_label;

  /// No description provided for @legacy_prefix_override_hint.
  ///
  /// In en, this message translates to:
  /// **'Example: ? or ((guild.prefix | !))'**
  String get legacy_prefix_override_hint;

  /// No description provided for @legacy_response_mode_label.
  ///
  /// In en, this message translates to:
  /// **'Legacy response mode'**
  String get legacy_response_mode_label;

  /// No description provided for @command_type_locked.
  ///
  /// In en, this message translates to:
  /// **'Command type cannot be changed after creation.'**
  String get command_type_locked;

  /// No description provided for @local_command_title.
  ///
  /// In en, this message translates to:
  /// **'Local Command (Do not register on Discord)'**
  String get local_command_title;

  /// No description provided for @local_command_desc.
  ///
  /// In en, this message translates to:
  /// **'Store command only in Bot Creator. You can dynamically register it on Specific Guilds using BDFD \$registerGuildCommands.'**
  String get local_command_desc;

  /// No description provided for @local_command_awaited_desc.
  ///
  /// In en, this message translates to:
  /// **'Awaited callback presets stay local because they are internal runtime callbacks.'**
  String get local_command_awaited_desc;

  /// No description provided for @command_integration_label.
  ///
  /// In en, this message translates to:
  /// **'Where this command can be used'**
  String get command_integration_label;

  /// No description provided for @command_scope_label.
  ///
  /// In en, this message translates to:
  /// **'Scope of the command (Contexts)'**
  String get command_scope_label;

  /// No description provided for @command_permissions_label.
  ///
  /// In en, this message translates to:
  /// **'Default Member Permissions (optional)'**
  String get command_permissions_label;

  /// No description provided for @command_permissions_none.
  ///
  /// In en, this message translates to:
  /// **'No selection (everyone can use command)'**
  String get command_permissions_none;

  /// No description provided for @command_permissions_count.
  ///
  /// In en, this message translates to:
  /// **'{count} permission(s) selected'**
  String command_permissions_count(int count);

  /// No description provided for @command_permissions_bitfield.
  ///
  /// In en, this message translates to:
  /// **'Calculated Permission Bitfield'**
  String get command_permissions_bitfield;

  /// No description provided for @command_permissions_bitfield_helper.
  ///
  /// In en, this message translates to:
  /// **'Automatically computed from selected permissions.'**
  String get command_permissions_bitfield_helper;

  /// No description provided for @command_permissions_unknown_bits.
  ///
  /// In en, this message translates to:
  /// **'Warning: unknown permission bits detected from saved data and preserved: {bits}'**
  String command_permissions_unknown_bits(String bits);

  /// No description provided for @command_permissions_admin_warning.
  ///
  /// In en, this message translates to:
  /// **'Administrator selected: this bypasses other permission checks.'**
  String get command_permissions_admin_warning;

  /// No description provided for @command_permissions_tip.
  ///
  /// In en, this message translates to:
  /// **'Tip: leave all unchecked to make the command available to everyone by default.'**
  String get command_permissions_tip;

  /// No description provided for @workflow_saved_snackbar.
  ///
  /// In en, this message translates to:
  /// **'Workflow \"{name}\" saved ({count} action(s)).'**
  String workflow_saved_snackbar(String name, int count);

  /// No description provided for @reply_command_reply_title.
  ///
  /// In en, this message translates to:
  /// **'Command Reply'**
  String get reply_command_reply_title;

  /// No description provided for @reply_choose_type.
  ///
  /// In en, this message translates to:
  /// **'Choose the type of response to send'**
  String get reply_choose_type;

  /// No description provided for @reply_mode_standard_desc.
  ///
  /// In en, this message translates to:
  /// **'Text, embeds and optional buttons / select menus'**
  String get reply_mode_standard_desc;

  /// No description provided for @reply_mode_layout_desc.
  ///
  /// In en, this message translates to:
  /// **'Discord\'s rich layout system — containers, media, text & forms'**
  String get reply_mode_layout_desc;

  /// No description provided for @reply_mode_modal_desc.
  ///
  /// In en, this message translates to:
  /// **'Pop-up dialog with text input fields'**
  String get reply_mode_modal_desc;

  /// No description provided for @reply_response_workflow.
  ///
  /// In en, this message translates to:
  /// **'Response Workflow'**
  String get reply_response_workflow;

  /// No description provided for @reply_response_text_label.
  ///
  /// In en, this message translates to:
  /// **'Response Text'**
  String get reply_response_text_label;

  /// No description provided for @reply_response_text_helper.
  ///
  /// In en, this message translates to:
  /// **'Used as slash-command reply text. Supports ((variable)) syntax.'**
  String get reply_response_text_helper;

  /// No description provided for @reply_buttons_desc.
  ///
  /// In en, this message translates to:
  /// **'Add interactive buttons or dropdowns to this message'**
  String get reply_buttons_desc;

  /// No description provided for @reply_active_route.
  ///
  /// In en, this message translates to:
  /// **'Active route: {label}'**
  String reply_active_route(String label);

  /// No description provided for @workflow_visibility_ephemeral.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral'**
  String get workflow_visibility_ephemeral;

  /// No description provided for @workflow_visibility_public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get workflow_visibility_public;

  /// No description provided for @workflow_auto_defer.
  ///
  /// In en, this message translates to:
  /// **'Auto defer'**
  String get workflow_auto_defer;

  /// No description provided for @workflow_manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get workflow_manual;

  /// No description provided for @workflow_condition_on.
  ///
  /// In en, this message translates to:
  /// **'Condition on'**
  String get workflow_condition_on;

  /// No description provided for @workflow_condition_off.
  ///
  /// In en, this message translates to:
  /// **'Condition off'**
  String get workflow_condition_off;

  /// No description provided for @workflow_auto_defer_actions.
  ///
  /// In en, this message translates to:
  /// **'Auto defer if actions'**
  String get workflow_auto_defer_actions;

  /// No description provided for @workflow_no_auto_defer.
  ///
  /// In en, this message translates to:
  /// **'No auto defer'**
  String get workflow_no_auto_defer;

  /// No description provided for @workflow_condition_on_upper.
  ///
  /// In en, this message translates to:
  /// **'Condition ON'**
  String get workflow_condition_on_upper;

  /// No description provided for @workflow_condition_off_upper.
  ///
  /// In en, this message translates to:
  /// **'Condition OFF'**
  String get workflow_condition_off_upper;

  /// No description provided for @actions_summary_bdfd.
  ///
  /// In en, this message translates to:
  /// **'BDFD script | {lines} line(s) | {diagnostics} diagnostic(s)'**
  String actions_summary_bdfd(int lines, int diagnostics);

  /// No description provided for @actions_summary_routes.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) on active route | {routes} route(s)'**
  String actions_summary_routes(int count, int routes);

  /// No description provided for @actions_summary_configured.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) configured'**
  String actions_summary_configured(int count);

  /// No description provided for @reply_editor_title.
  ///
  /// In en, this message translates to:
  /// **'Reply Details'**
  String get reply_editor_title;

  /// No description provided for @bdfd_editor_ux_title.
  ///
  /// In en, this message translates to:
  /// **'Editor UX'**
  String get bdfd_editor_ux_title;

  /// No description provided for @bdfd_editor_includes.
  ///
  /// In en, this message translates to:
  /// **'Includes:'**
  String get bdfd_editor_includes;

  /// No description provided for @bdfd_editor_auto_indent.
  ///
  /// In en, this message translates to:
  /// **'• Smart auto indentation on Enter'**
  String get bdfd_editor_auto_indent;

  /// No description provided for @bdfd_editor_indent_guides.
  ///
  /// In en, this message translates to:
  /// **'• Live indentation guides'**
  String get bdfd_editor_indent_guides;

  /// No description provided for @bdfd_editor_quick_keys.
  ///
  /// In en, this message translates to:
  /// **'• Mobile quick-keys for BDFD symbols'**
  String get bdfd_editor_quick_keys;

  /// No description provided for @bdfd_editor_toggle_indent.
  ///
  /// In en, this message translates to:
  /// **'Toggle indentation guides'**
  String get bdfd_editor_toggle_indent;

  /// No description provided for @startup_error_title.
  ///
  /// In en, this message translates to:
  /// **'Startup Error'**
  String get startup_error_title;

  /// No description provided for @startup_failed_message.
  ///
  /// In en, this message translates to:
  /// **'Bot Creator failed to start on this device.'**
  String get startup_failed_message;

  /// No description provided for @startup_copy_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Copy diagnostics'**
  String get startup_copy_diagnostics;

  /// No description provided for @startup_refresh_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Refresh diagnostics'**
  String get startup_refresh_diagnostics;

  /// No description provided for @startup_diagnostics_copied.
  ///
  /// In en, this message translates to:
  /// **'Diagnostics copied to clipboard'**
  String get startup_diagnostics_copied;

  /// No description provided for @export_failed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String export_failed(String error);

  /// No description provided for @import_parse_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse ZIP: {error}'**
  String import_parse_failed(String error);

  /// No description provided for @import_nothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing imported.'**
  String get import_nothing;

  /// No description provided for @import_failed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String import_failed(String error);

  /// No description provided for @workflows_no_match.
  ///
  /// In en, this message translates to:
  /// **'No workflows match the current filters.'**
  String get workflows_no_match;

  /// No description provided for @settings_run_diagnostics.
  ///
  /// In en, this message translates to:
  /// **'Run Diagnostics'**
  String get settings_run_diagnostics;

  /// No description provided for @settings_open_ad_inspector.
  ///
  /// In en, this message translates to:
  /// **'Open Ad Inspector'**
  String get settings_open_ad_inspector;

  /// No description provided for @settings_builtin_help.
  ///
  /// In en, this message translates to:
  /// **'Built-in legacy !help command'**
  String get settings_builtin_help;

  /// No description provided for @drive_manual_backup.
  ///
  /// In en, this message translates to:
  /// **'Manual backup'**
  String get drive_manual_backup;

  /// No description provided for @drive_legacy_snapshot.
  ///
  /// In en, this message translates to:
  /// **'Legacy snapshot'**
  String get drive_legacy_snapshot;

  /// No description provided for @commands_filter_template.
  ///
  /// In en, this message translates to:
  /// **'Template'**
  String get commands_filter_template;

  /// No description provided for @commands_filter_legacy_local.
  ///
  /// In en, this message translates to:
  /// **'Legacy local'**
  String get commands_filter_legacy_local;

  /// No description provided for @workflows_no_matches.
  ///
  /// In en, this message translates to:
  /// **'No workflows match the current filters.'**
  String get workflows_no_matches;

  /// No description provided for @common_disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get common_disabled;

  /// No description provided for @common_label.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get common_label;

  /// No description provided for @common_custom_id.
  ///
  /// In en, this message translates to:
  /// **'Custom ID'**
  String get common_custom_id;

  /// No description provided for @common_custom_id_required.
  ///
  /// In en, this message translates to:
  /// **'Custom ID *'**
  String get common_custom_id_required;

  /// No description provided for @common_placeholder.
  ///
  /// In en, this message translates to:
  /// **'Placeholder'**
  String get common_placeholder;

  /// No description provided for @common_style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get common_style;

  /// No description provided for @common_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get common_url;

  /// No description provided for @common_operator.
  ///
  /// In en, this message translates to:
  /// **'Operator'**
  String get common_operator;

  /// No description provided for @component_on_click_workflow.
  ///
  /// In en, this message translates to:
  /// **'On click, the workflow'**
  String get component_on_click_workflow;

  /// No description provided for @component_on_select_workflow.
  ///
  /// In en, this message translates to:
  /// **'On select, the workflow'**
  String get component_on_select_workflow;

  /// No description provided for @component_new_option.
  ///
  /// In en, this message translates to:
  /// **'New Option'**
  String get component_new_option;

  /// No description provided for @component_component_to_wrap.
  ///
  /// In en, this message translates to:
  /// **'Component to Wrap:'**
  String get component_component_to_wrap;

  /// No description provided for @component_radio_options.
  ///
  /// In en, this message translates to:
  /// **'Radio Options'**
  String get component_radio_options;

  /// No description provided for @component_checkbox_options.
  ///
  /// In en, this message translates to:
  /// **'Checkbox Options'**
  String get component_checkbox_options;

  /// No description provided for @component_add_checkbox_option.
  ///
  /// In en, this message translates to:
  /// **'Add Checkbox Option'**
  String get component_add_checkbox_option;

  /// No description provided for @component_new_radio.
  ///
  /// In en, this message translates to:
  /// **'New Radio'**
  String get component_new_radio;

  /// No description provided for @component_new_checkbox.
  ///
  /// In en, this message translates to:
  /// **'New Checkbox'**
  String get component_new_checkbox;

  /// No description provided for @component_file_url.
  ///
  /// In en, this message translates to:
  /// **'File URL'**
  String get component_file_url;

  /// No description provided for @component_thumbnail_url.
  ///
  /// In en, this message translates to:
  /// **'Thumbnail URL'**
  String get component_thumbnail_url;

  /// No description provided for @component_media_url.
  ///
  /// In en, this message translates to:
  /// **'Image / Video URL'**
  String get component_media_url;

  /// No description provided for @component_media_urls.
  ///
  /// In en, this message translates to:
  /// **'Media URLs'**
  String get component_media_urls;

  /// No description provided for @workflow_entry_point_optional.
  ///
  /// In en, this message translates to:
  /// **'Entry Point (optional)'**
  String get workflow_entry_point_optional;

  /// No description provided for @workflow_entry_point_helper.
  ///
  /// In en, this message translates to:
  /// **'Defaults to workflow entry point when empty'**
  String get workflow_entry_point_helper;

  /// No description provided for @workflow_set_call_args.
  ///
  /// In en, this message translates to:
  /// **'Set Call Arguments'**
  String get workflow_set_call_args;

  /// No description provided for @workflow_edit_call_args.
  ///
  /// In en, this message translates to:
  /// **'Edit Call Arguments ({count})'**
  String workflow_edit_call_args(int count);

  /// No description provided for @workflow_root_json_error.
  ///
  /// In en, this message translates to:
  /// **'Root must be a JSON object'**
  String get workflow_root_json_error;

  /// No description provided for @workflow_on_submit_info.
  ///
  /// In en, this message translates to:
  /// **'On submit, workflow \"{name}\" will run (entry: {entry}, args: {args}).'**
  String workflow_on_submit_info(String name, String entry, String args);

  /// No description provided for @workflow_no_workflow_note.
  ///
  /// In en, this message translates to:
  /// **'Note: If no workflow is selected, submitting this modal will do nothing.'**
  String get workflow_no_workflow_note;

  /// No description provided for @workflow_hint_name.
  ///
  /// In en, this message translates to:
  /// **'e.g. handle_form_submit'**
  String get workflow_hint_name;

  /// No description provided for @action_position.
  ///
  /// In en, this message translates to:
  /// **'Action {index}/{total}'**
  String action_position(int index, int total);

  /// No description provided for @action_provide_valid_url.
  ///
  /// In en, this message translates to:
  /// **'Please provide a valid URL.'**
  String get action_provide_valid_url;

  /// No description provided for @action_hint_duration.
  ///
  /// In en, this message translates to:
  /// **'e.g., 5m, 1h, 30s'**
  String get action_hint_duration;

  /// No description provided for @action_hint_enter_type.
  ///
  /// In en, this message translates to:
  /// **'Enter {type}'**
  String action_hint_enter_type(String type);

  /// No description provided for @action_hint_emoji.
  ///
  /// In en, this message translates to:
  /// **'Enter emoji or :name:'**
  String get action_hint_emoji;

  /// No description provided for @action_hint_color.
  ///
  /// In en, this message translates to:
  /// **'#FFFFFF or rgb(255,255,255)'**
  String get action_hint_color;

  /// No description provided for @action_hint_workflow.
  ///
  /// In en, this message translates to:
  /// **'Saved workflow name'**
  String get action_hint_workflow;

  /// No description provided for @action_hint_variable_key.
  ///
  /// In en, this message translates to:
  /// **'Select variable key'**
  String get action_hint_variable_key;

  /// No description provided for @action_hint_condition_var.
  ///
  /// In en, this message translates to:
  /// **'Use ((variableName)) or a runtime value'**
  String get action_hint_condition_var;

  /// No description provided for @action_hint_condition_value.
  ///
  /// In en, this message translates to:
  /// **'Value to compare against'**
  String get action_hint_condition_value;

  /// No description provided for @action_add_new_item.
  ///
  /// In en, this message translates to:
  /// **'Add new item'**
  String get action_add_new_item;

  /// No description provided for @action_key_value_pairs.
  ///
  /// In en, this message translates to:
  /// **'Key / Value pairs'**
  String get action_key_value_pairs;

  /// No description provided for @action_edit_nested.
  ///
  /// In en, this message translates to:
  /// **'Edit {count}'**
  String action_edit_nested(int count);

  /// No description provided for @action_edit_nested_parens.
  ///
  /// In en, this message translates to:
  /// **'Edit ({count})'**
  String action_edit_nested_parens(int count);

  /// No description provided for @action_no_items_tap_edit.
  ///
  /// In en, this message translates to:
  /// **'No items - tap edit to add'**
  String get action_no_items_tap_edit;

  /// No description provided for @action_no_actions_yet.
  ///
  /// In en, this message translates to:
  /// **'No actions in this branch yet.'**
  String get action_no_actions_yet;

  /// No description provided for @action_and_more.
  ///
  /// In en, this message translates to:
  /// **'… and {count} more'**
  String action_and_more(int count);

  /// No description provided for @action_no_else_if_yet.
  ///
  /// In en, this message translates to:
  /// **'No ELSE IF branches yet. Add one to test more conditions before ELSE.'**
  String get action_no_else_if_yet;

  /// No description provided for @action_no_headers_tap_edit.
  ///
  /// In en, this message translates to:
  /// **'No headers - tap edit to add'**
  String get action_no_headers_tap_edit;

  /// No description provided for @action_no_args_tap_edit.
  ///
  /// In en, this message translates to:
  /// **'No arguments - tap edit to add'**
  String get action_no_args_tap_edit;

  /// No description provided for @action_no_properties_tap_edit.
  ///
  /// In en, this message translates to:
  /// **'No properties - tap edit to configure'**
  String get action_no_properties_tap_edit;

  /// No description provided for @action_http_headers_title.
  ///
  /// In en, this message translates to:
  /// **'HTTP Headers (Key/Value pairs)'**
  String get action_http_headers_title;

  /// No description provided for @action_bulk_import_hint.
  ///
  /// In en, this message translates to:
  /// **'Bulk import (Paste headers like Key: Value)'**
  String get action_bulk_import_hint;

  /// No description provided for @action_json_editor_hint.
  ///
  /// In en, this message translates to:
  /// **'JSON object editor (supports nested objects/arrays)'**
  String get action_json_editor_hint;

  /// No description provided for @action_edit_raw_json.
  ///
  /// In en, this message translates to:
  /// **'Edit Raw JSON'**
  String get action_edit_raw_json;

  /// No description provided for @action_preview_json.
  ///
  /// In en, this message translates to:
  /// **'Preview Highlighted JSON'**
  String get action_preview_json;

  /// No description provided for @action_cannot_format_json.
  ///
  /// In en, this message translates to:
  /// **'Cannot format: Invalid JSON'**
  String get action_cannot_format_json;

  /// No description provided for @action_root_must_json.
  ///
  /// In en, this message translates to:
  /// **'Root must be a JSON object'**
  String get action_root_must_json;

  /// No description provided for @action_dynamic_numeric.
  ///
  /// In en, this message translates to:
  /// **'Dynamic numeric suggestions'**
  String get action_dynamic_numeric;

  /// No description provided for @action_dynamic_variable.
  ///
  /// In en, this message translates to:
  /// **'Dynamic variable suggestions'**
  String get action_dynamic_variable;

  /// No description provided for @action_dynamic_bool_hint.
  ///
  /// In en, this message translates to:
  /// **'true/false or ((variable))'**
  String get action_dynamic_bool_hint;

  /// No description provided for @action_dynamic_multiselect_hint.
  ///
  /// In en, this message translates to:
  /// **'Dynamic value (supports ((...)))'**
  String get action_dynamic_multiselect_hint;

  /// No description provided for @action_dynamic_id_hint.
  ///
  /// In en, this message translates to:
  /// **'Dynamic {type} (supports ((...)))'**
  String action_dynamic_id_hint(String type);

  /// No description provided for @action_loading_keys.
  ///
  /// In en, this message translates to:
  /// **'Loading keys...'**
  String get action_loading_keys;

  /// No description provided for @action_no_saved_keys.
  ///
  /// In en, this message translates to:
  /// **'No saved keys found. Keys are created automatically on first access.'**
  String get action_no_saved_keys;

  /// No description provided for @action_select_stored_key.
  ///
  /// In en, this message translates to:
  /// **'Select a stored key (bc_ prefix is optional)'**
  String get action_select_stored_key;

  /// No description provided for @action_select_saved_key.
  ///
  /// In en, this message translates to:
  /// **'Select a saved key'**
  String get action_select_saved_key;

  /// No description provided for @action_static_badge.
  ///
  /// In en, this message translates to:
  /// **'(static)'**
  String get action_static_badge;

  /// No description provided for @action_or_type_workflow.
  ///
  /// In en, this message translates to:
  /// **'Or type workflow name'**
  String get action_or_type_workflow;

  /// No description provided for @modal_builder_title.
  ///
  /// In en, this message translates to:
  /// **'Modal Builder'**
  String get modal_builder_title;

  /// No description provided for @modal_inputs_count.
  ///
  /// In en, this message translates to:
  /// **'{count}/5 inputs'**
  String modal_inputs_count(int count);

  /// No description provided for @modal_input_index.
  ///
  /// In en, this message translates to:
  /// **'Input {index}'**
  String modal_input_index(int index);

  /// No description provided for @settings_legacy_prefix.
  ///
  /// In en, this message translates to:
  /// **'Legacy command prefix'**
  String get settings_legacy_prefix;

  /// No description provided for @settings_legacy_prefix_hint.
  ///
  /// In en, this message translates to:
  /// **'!, ? or ((guild.prefix | user.prefix | !))'**
  String get settings_legacy_prefix_hint;

  /// No description provided for @settings_legacy_prefix_helper.
  ///
  /// In en, this message translates to:
  /// **'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))'**
  String get settings_legacy_prefix_helper;

  /// No description provided for @settings_builtin_help_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Mandatory feature with explicit toggle. Disable it if you only want custom help behavior.'**
  String get settings_builtin_help_subtitle;

  /// No description provided for @settings_status_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'This status entry will be removed. Continue?'**
  String get settings_status_remove_confirm;

  /// No description provided for @webhooks_count.
  ///
  /// In en, this message translates to:
  /// **'Webhooks: {count}{limit}'**
  String webhooks_count(int count, String limit);

  /// No description provided for @webhooks_path_copied.
  ///
  /// In en, this message translates to:
  /// **'Path copied.'**
  String get webhooks_path_copied;

  /// No description provided for @webhooks_secret_copied.
  ///
  /// In en, this message translates to:
  /// **'Secret copied.'**
  String get webhooks_secret_copied;

  /// No description provided for @scheduler_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Workflow: {workflow} • Every {minutes} min'**
  String scheduler_subtitle(String workflow, int minutes);

  /// No description provided for @import_summary_commands_imported.
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) imported'**
  String import_summary_commands_imported(int count);

  /// No description provided for @import_summary_commands_skipped.
  ///
  /// In en, this message translates to:
  /// **'{count} command(s) skipped'**
  String import_summary_commands_skipped(int count);

  /// No description provided for @import_summary_workflows_imported.
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) imported'**
  String import_summary_workflows_imported(int count);

  /// No description provided for @import_summary_workflows_skipped.
  ///
  /// In en, this message translates to:
  /// **'{count} workflow(s) skipped'**
  String import_summary_workflows_skipped(int count);

  /// No description provided for @import_summary_status_imported.
  ///
  /// In en, this message translates to:
  /// **'status imported'**
  String get import_summary_status_imported;

  /// No description provided for @import_summary_variables_imported.
  ///
  /// In en, this message translates to:
  /// **'variables imported'**
  String get import_summary_variables_imported;

  /// No description provided for @command_subcommand_workflow_title.
  ///
  /// In en, this message translates to:
  /// **'SubCommand Workflow'**
  String get command_subcommand_workflow_title;

  /// No description provided for @command_subcommand_workflow_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose which subcommand you are configuring.'**
  String get command_subcommand_workflow_desc;

  /// No description provided for @command_sync_failed_local.
  ///
  /// In en, this message translates to:
  /// **'Saved locally. Discord sync failed: {error}'**
  String command_sync_failed_local(String error);

  /// No description provided for @command_description_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a command description'**
  String get command_description_required;

  /// No description provided for @command_description_length.
  ///
  /// In en, this message translates to:
  /// **'Command description must be at most 100 characters long'**
  String get command_description_length;

  /// No description provided for @response_workflow_deferred_reply.
  ///
  /// In en, this message translates to:
  /// **'Deferred reply'**
  String get response_workflow_deferred_reply;

  /// No description provided for @response_workflow_auto_defer_desc.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge quickly, execute actions, then edit final response.'**
  String get response_workflow_auto_defer_desc;

  /// No description provided for @response_workflow_visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get response_workflow_visibility;

  /// No description provided for @response_workflow_ephemeral_only_user.
  ///
  /// In en, this message translates to:
  /// **'Ephemeral (only command user)'**
  String get response_workflow_ephemeral_only_user;

  /// No description provided for @response_workflow_error_policy_desc.
  ///
  /// In en, this message translates to:
  /// **'When an action fails, edit the deferred message with an error.'**
  String get response_workflow_error_policy_desc;

  /// No description provided for @response_workflow_conditional_title.
  ///
  /// In en, this message translates to:
  /// **'Conditional response (MVP)'**
  String get response_workflow_conditional_title;

  /// No description provided for @response_workflow_condition_desc.
  ///
  /// In en, this message translates to:
  /// **'If variable exists and is not empty => use THEN text, otherwise ELSE text.'**
  String get response_workflow_condition_desc;

  /// No description provided for @response_workflow_variable_key.
  ///
  /// In en, this message translates to:
  /// **'Variable key (ex: opts.userId)'**
  String get response_workflow_variable_key;

  /// No description provided for @commands_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search commands...'**
  String get commands_search_hint;

  /// No description provided for @commands_all_folders.
  ///
  /// In en, this message translates to:
  /// **'All folders'**
  String get commands_all_folders;

  /// No description provided for @commands_no_match_filters.
  ///
  /// In en, this message translates to:
  /// **'No commands match the current filters.'**
  String get commands_no_match_filters;

  /// No description provided for @actions_search_sequence_hint.
  ///
  /// In en, this message translates to:
  /// **'Search actions in this sequence...'**
  String get actions_search_sequence_hint;

  /// No description provided for @actions_sequence_count.
  ///
  /// In en, this message translates to:
  /// **'{count} action(s) in sequence'**
  String actions_sequence_count(int count);

  /// No description provided for @actions_save_count.
  ///
  /// In en, this message translates to:
  /// **'Save {count} Actions'**
  String actions_save_count(int count);

  /// No description provided for @actions_step_label.
  ///
  /// In en, this message translates to:
  /// **'Step {index}/{total}'**
  String actions_step_label(int index, int total);

  /// No description provided for @option_type_string.
  ///
  /// In en, this message translates to:
  /// **'String'**
  String get option_type_string;

  /// No description provided for @option_type_integer.
  ///
  /// In en, this message translates to:
  /// **'Integer'**
  String get option_type_integer;

  /// No description provided for @option_type_boolean.
  ///
  /// In en, this message translates to:
  /// **'Boolean'**
  String get option_type_boolean;

  /// No description provided for @option_type_user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get option_type_user;

  /// No description provided for @option_type_channel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get option_type_channel;

  /// No description provided for @option_type_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get option_type_role;

  /// No description provided for @option_type_mentionable.
  ///
  /// In en, this message translates to:
  /// **'Mentionable'**
  String get option_type_mentionable;

  /// No description provided for @option_type_number.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get option_type_number;

  /// No description provided for @option_type_attachment.
  ///
  /// In en, this message translates to:
  /// **'Attachment'**
  String get option_type_attachment;

  /// No description provided for @option_type_subcommand.
  ///
  /// In en, this message translates to:
  /// **'SubCommand'**
  String get option_type_subcommand;

  /// No description provided for @option_type_subcommand_group.
  ///
  /// In en, this message translates to:
  /// **'SubCommand Group'**
  String get option_type_subcommand_group;

  /// No description provided for @option_type_unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get option_type_unknown;

  /// No description provided for @option_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name for the option'**
  String get option_name_required;

  /// No description provided for @option_name_max_length.
  ///
  /// In en, this message translates to:
  /// **'Option name must be at most 32 characters long'**
  String get option_name_max_length;

  /// No description provided for @option_name_invalid_chars.
  ///
  /// In en, this message translates to:
  /// **'Option name can only contain letters, numbers, and underscores'**
  String get option_name_invalid_chars;

  /// No description provided for @option_name_invalid_start.
  ///
  /// In en, this message translates to:
  /// **'Option name starts with an unsupported character'**
  String get option_name_invalid_start;

  /// No description provided for @option_name_duplicate.
  ///
  /// In en, this message translates to:
  /// **'This name is already used at this level'**
  String get option_name_duplicate;

  /// No description provided for @option_label_number.
  ///
  /// In en, this message translates to:
  /// **'Label {index}'**
  String option_label_number(int index);

  /// No description provided for @option_value_number.
  ///
  /// In en, this message translates to:
  /// **'Value {index}'**
  String option_value_number(int index);

  /// No description provided for @validation_option_max_entries.
  ///
  /// In en, this message translates to:
  /// **'Each option level supports at most 25 entries.'**
  String get validation_option_max_entries;

  /// No description provided for @validation_option_no_mix_top_level.
  ///
  /// In en, this message translates to:
  /// **'Top-level options cannot mix subcommands/groups with regular options.'**
  String get validation_option_no_mix_top_level;

  /// No description provided for @validation_option_group_only_subcommands.
  ///
  /// In en, this message translates to:
  /// **'A SubCommandGroup can only contain SubCommand options.'**
  String get validation_option_group_only_subcommands;

  /// No description provided for @validation_option_subcommand_no_nested.
  ///
  /// In en, this message translates to:
  /// **'A SubCommand cannot contain nested SubCommand or SubCommandGroup.'**
  String get validation_option_subcommand_no_nested;

  /// No description provided for @validation_option_name_required.
  ///
  /// In en, this message translates to:
  /// **'Every option must have a name.'**
  String get validation_option_name_required;

  /// No description provided for @validation_option_name_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate option name \"{name}\" at the same level.'**
  String validation_option_name_duplicate(String name);

  /// No description provided for @validation_option_description_required.
  ///
  /// In en, this message translates to:
  /// **'Every option must have a description.'**
  String get validation_option_description_required;

  /// No description provided for @validation_option_leaf_no_nested.
  ///
  /// In en, this message translates to:
  /// **'Regular options cannot contain nested options.'**
  String get validation_option_leaf_no_nested;

  /// No description provided for @validation_option_hierarchy_not_required.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot be marked as required.'**
  String get validation_option_hierarchy_not_required;

  /// No description provided for @validation_option_hierarchy_no_choices.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot define choices.'**
  String get validation_option_hierarchy_no_choices;

  /// No description provided for @validation_option_hierarchy_no_min_max.
  ///
  /// In en, this message translates to:
  /// **'SubCommand and SubCommandGroup cannot define min/max values.'**
  String get validation_option_hierarchy_no_min_max;

  /// No description provided for @validation_option_group_top_level_only.
  ///
  /// In en, this message translates to:
  /// **'SubCommandGroup is only allowed at the top level.'**
  String get validation_option_group_top_level_only;

  /// No description provided for @validation_option_subcommand_depth.
  ///
  /// In en, this message translates to:
  /// **'SubCommand nesting depth exceeds Discord limits.'**
  String get validation_option_subcommand_depth;

  /// No description provided for @bdfd_compile_error_simple.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script could not be compiled.'**
  String get bdfd_compile_error_simple;

  /// No description provided for @bdfd_compile_error_detailed.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script could not be compiled:\n{summary}'**
  String bdfd_compile_error_detailed(String summary);

  /// No description provided for @command_not_found.
  ///
  /// In en, this message translates to:
  /// **'Command not found'**
  String get command_not_found;

  /// No description provided for @legacy_bdfd_run_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to run BDFD script for command \"{command}\": {error}'**
  String legacy_bdfd_run_failed(String command, String error);

  /// No description provided for @component_empty_option.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get component_empty_option;

  /// No description provided for @component_unknown_component.
  ///
  /// In en, this message translates to:
  /// **'Unknown component'**
  String get component_unknown_component;

  /// No description provided for @common_bot.
  ///
  /// In en, this message translates to:
  /// **'Bot'**
  String get common_bot;

  /// No description provided for @command_payload_hint.
  ///
  /// In en, this message translates to:
  /// **'Command payload'**
  String get command_payload_hint;

  /// No description provided for @workflows_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search workflows...'**
  String get workflows_search_hint;

  /// No description provided for @component_default_option_label.
  ///
  /// In en, this message translates to:
  /// **'Option'**
  String get component_default_option_label;

  /// No description provided for @component_default_choice_label.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get component_default_choice_label;

  /// No description provided for @command_execution_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while executing this command.'**
  String get command_execution_error;

  /// No description provided for @bdfd_runtime_execution_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while executing this BDFD script.'**
  String get bdfd_runtime_execution_error;

  /// No description provided for @bdfd_compiled_no_actions.
  ///
  /// In en, this message translates to:
  /// **'This BDFD script compiled successfully but did not produce any action.'**
  String get bdfd_compiled_no_actions;

  /// No description provided for @embed_section_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get embed_section_color;

  /// No description provided for @embed_section_timestamp.
  ///
  /// In en, this message translates to:
  /// **'Timestamp'**
  String get embed_section_timestamp;

  /// No description provided for @embed_section_fields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get embed_section_fields;

  /// No description provided for @embed_section_dynamic_fields.
  ///
  /// In en, this message translates to:
  /// **'Dynamic Fields'**
  String get embed_section_dynamic_fields;

  /// No description provided for @embed_add_field.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get embed_add_field;

  /// No description provided for @embed_add_section.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get embed_add_section;

  /// No description provided for @common_add_section.
  ///
  /// In en, this message translates to:
  /// **'Add Section'**
  String get common_add_section;

  /// No description provided for @component_block_workflow.
  ///
  /// In en, this message translates to:
  /// **'Workflow'**
  String get component_block_workflow;

  /// No description provided for @component_block_label_style.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get component_block_label_style;

  /// No description provided for @notion_filter_add.
  ///
  /// In en, this message translates to:
  /// **'Add Filter'**
  String get notion_filter_add;

  /// No description provided for @notion_filter_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get notion_filter_type;

  /// No description provided for @notion_create_workflow_from_query.
  ///
  /// In en, this message translates to:
  /// **'Create workflow \"{query}\"'**
  String notion_create_workflow_from_query(String query);

  /// No description provided for @commands_create_from_query.
  ///
  /// In en, this message translates to:
  /// **'Create command \"{query}\"'**
  String commands_create_from_query(String query);

  /// No description provided for @commands_filter_type_label.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get commands_filter_type_label;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
