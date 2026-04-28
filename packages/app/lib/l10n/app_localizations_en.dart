// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Bot Creator';

  @override
  String get onboarding_welcome_title => 'Welcome to Bot Creator';

  @override
  String get onboarding_welcome_desc =>
      'Create your first Discord bot in 3 simple steps. We\'ll guide you through each step.';

  @override
  String get onboarding_welcome_start => 'Get Started';

  @override
  String get onboarding_welcome_skip => 'Skip';

  @override
  String get onboarding_create_title => 'Step 1: Create a Bot';

  @override
  String get onboarding_create_desc => 'Get your Discord token';

  @override
  String get onboarding_create_steps =>
      '1. Go to Discord Developer Portal\n2. Create a new app\n3. Copy the bot token\n4. Paste it below';

  @override
  String get onboarding_create_tip =>
      '💡 Tip: Never share your token! It gives full access to your bot.';

  @override
  String get onboarding_create_tutorial => 'Tutorial: How to get a token';

  @override
  String get onboarding_create_button => 'Continue';

  @override
  String get onboarding_command_title => 'Step 2: Add a Command';

  @override
  String get onboarding_command_desc => 'Create your first command';

  @override
  String get onboarding_command_text =>
      'Commands are the heart of your bot. They allow users to interact with your bot via Discord.';

  @override
  String get onboarding_command_example =>
      'Example:\n/hello → Bot replies \"Hello! 👋\"';

  @override
  String get onboarding_command_button => 'Continue';

  @override
  String get onboarding_start_title => 'Step 3: Start the Bot';

  @override
  String get onboarding_start_desc => 'Launch your bot!';

  @override
  String get onboarding_start_text =>
      'Click the \"Start\" button on your bot card. Then test your command in Discord!';

  @override
  String get onboarding_start_tip =>
      '✨ Great! You\'ve created your first Discord bot. You can now add more commands and customize it!';

  @override
  String get onboarding_start_button => 'Continue';

  @override
  String get onboarding_success_title => 'Congratulations! 🎉';

  @override
  String get onboarding_success_desc => 'Your Discord bot is ready to go!';

  @override
  String get onboarding_success_whatsnext => 'What\'s next?';

  @override
  String get onboarding_success_tip1 => 'Add more commands';

  @override
  String get onboarding_success_tip2 => 'Create workflows';

  @override
  String get onboarding_success_tip3 => 'Backup your data';

  @override
  String get onboarding_success_button => 'Start!';

  @override
  String get app_create_new => 'Create a new App';

  @override
  String get app_create_page_title => 'Create a bot';

  @override
  String get app_create_hero_title => 'Connect your Discord bot';

  @override
  String get app_create_hero_desc =>
      'A guided setup to open the right pages, copy your token and import the bot safely.';

  @override
  String get app_resources_title => 'Guided setup';

  @override
  String get app_resources_desc =>
      'These actions open the official pages you need before saving your bot here.';

  @override
  String get app_open_discord_portal => 'Open Discord Developer Portal';

  @override
  String get app_open_discord_portal_desc =>
      'Create your application and enable the bot section.';

  @override
  String get app_open_token_tutorial => 'Read the token tutorial';

  @override
  String get app_open_token_tutorial_desc =>
      'A step-by-step guide to generate and copy your bot token.';

  @override
  String get app_external_link_badge => 'External link';

  @override
  String get app_token_section_title => 'Paste your bot token';

  @override
  String get app_token_section_desc =>
      'Once the token is copied, paste it below to add your bot to the app.';

  @override
  String get app_token_field_helper =>
      'Paste the token exactly as provided by Discord.';

  @override
  String get app_token_security_hint =>
      'Keep this token private. Anyone with it can control your bot.';

  @override
  String get app_show_token => 'Show token';

  @override
  String get app_hide_token => 'Hide token';

  @override
  String get app_save_bot => 'Add bot';

  @override
  String get app_open_link_error => 'Unable to open this external page.';

  @override
  String get app_how_to_create_token => 'How to create a Bot Token?';

  @override
  String get app_bot_token => 'Bot Token';

  @override
  String get app_enter_token => 'Enter your bot token here';

  @override
  String get app_note =>
      'Note: You need to create a new App in the Discord Developer Portal and get your bot token.';

  @override
  String get app_save => 'Save Changes';

  @override
  String get app_sync_manager_title => 'Bot already managed';

  @override
  String get app_sync_manager_desc =>
      'This bot is already stored on Bot Creator Manager. Connect with Discord to sync all your bots automatically?';

  @override
  String get app_sync_manager_manual => 'Keep local';

  @override
  String get app_sync_manager_connect => 'Connect Discord';

  @override
  String get app_no_apps => 'No applications found';

  @override
  String get app_loading_error => 'Loading error';

  @override
  String get app_create_button => 'Create a bot';

  @override
  String get home_tab => 'Home';

  @override
  String get commands_tab => 'Commands';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get globals_tab => 'Globals';

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
  String get emojis_title => 'Application Emojis';

  @override
  String get emojis_empty => 'No emojis yet. Upload one to get started.';

  @override
  String get emojis_upload => 'Upload Emoji';

  @override
  String get emojis_upload_name_hint => 'Emoji name (letters, numbers, _)';

  @override
  String get emojis_upload_pick_image => 'Pick Image';

  @override
  String get emojis_delete_confirm_title => 'Delete Emoji';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Delete :$name: ? This action cannot be undone.';
  }

  @override
  String get emojis_rename_title => 'Rename Emoji';

  @override
  String get emojis_rename_hint => 'New name';

  @override
  String get emojis_loading_error => 'Failed to load emojis';

  @override
  String emojis_upload_error(String error) {
    return 'Upload failed: $error';
  }

  @override
  String emojis_delete_error(String error) {
    return 'Delete failed: $error';
  }

  @override
  String emojis_rename_error(String error) {
    return 'Rename failed: $error';
  }

  @override
  String get settings_tab => 'Settings';

  @override
  String get more_tab => 'More';

  @override
  String get quick_access_title => 'Quick Access';

  @override
  String get more_options_title => 'More Options';

  @override
  String get no_more_options => 'No other options available';

  @override
  String get settings_theme_switch_light => 'Switch to light mode';

  @override
  String get settings_theme_switch_dark => 'Switch to dark mode';

  @override
  String get settings_appearance_title => 'Appearance & language';

  @override
  String get settings_language_title => 'Language';

  @override
  String get settings_language_desc => 'Choose the language used by the app.';

  @override
  String get settings_language_system => 'Automatic (device)';

  @override
  String get settings_language_updated => 'Language updated';

  @override
  String get settings_debug_title => 'Debug tools';

  @override
  String get settings_debug_desc =>
      'Reset local preferences or replay onboarding for testing.';

  @override
  String get settings_reset_preferences => 'Reset preferences';

  @override
  String get settings_reset_preferences_desc =>
      'Reset theme, language and onboarding progress.';

  @override
  String get settings_replay_onboarding => 'Replay onboarding';

  @override
  String get settings_replay_onboarding_desc =>
      'Reset onboarding and launch it again now.';

  @override
  String get settings_debug_premium_bypass => 'Premium bypass';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Unlock all Premium features without a subscription (debug only).';

  @override
  String get settings_preferences_reset_done => 'Preferences reset';

  @override
  String get settings_backup_restore_title => 'Backup and Restore';

  @override
  String get settings_backup_restore_desc =>
      'Manage your data synchronization with Google Drive';

  @override
  String get settings_snapshot_preview_title => 'Snapshot Preview';

  @override
  String settings_snapshot_id(String id) {
    return 'ID: $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Label: $label';
  }

  @override
  String settings_snapshot_created_at(String date) {
    return 'Created: $date';
  }

  @override
  String settings_snapshot_files_size(String count, String size) {
    return 'Files: $count • Size: $size';
  }

  @override
  String settings_snapshot_apps_count(String count) {
    return 'Apps: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps in this snapshot';

  @override
  String get settings_snapshot_no_metadata => 'No app metadata available.';

  @override
  String get settings_snapshot_delete_loading => 'Deleting snapshot…';

  @override
  String get settings_snapshot_deleted => 'Snapshot deleted';

  @override
  String get settings_snapshot_restore_loading => 'Restoring snapshot…';

  @override
  String get settings_restore_snapshot => 'Restore This Snapshot';

  @override
  String get settings_diagnostics_dialog_title => 'Startup Diagnostics';

  @override
  String get settings_diagnostics_copied => 'Diagnostics copied to clipboard';

  @override
  String get settings_drive_title => 'Google Drive Connection';

  @override
  String get settings_drive_desc =>
      'Connect your Google Drive account to sync your data';

  @override
  String get settings_drive_connect_loading => 'Connecting to Google Drive…';

  @override
  String get settings_drive_connected => 'Connected to Google Drive';

  @override
  String get settings_drive_connect => 'Connect to Google Drive';

  @override
  String get settings_drive_status_connected => 'Connected';

  @override
  String get settings_drive_disconnect_loading => 'Disconnecting…';

  @override
  String get settings_drive_disconnected => 'Disconnected from Google Drive';

  @override
  String get settings_drive_disconnect => 'Disconnect';

  @override
  String get settings_runner_title => 'Runner API';

  @override
  String get settings_runner_desc =>
      'Connect the app to a Bot Creator Runner. Remote runners should stay on trusted networks and use a bearer token.';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_token_label => 'Runner API token';

  @override
  String get settings_runner_token_hint =>
      'Bearer token (optional on localhost)';

  @override
  String get settings_runner_save => 'Save settings';

  @override
  String get settings_runner_clear => 'Clear';

  @override
  String get settings_runner_saved => 'Runner settings saved';

  @override
  String get settings_runner_cleared => 'Runner settings cleared';

  @override
  String get settings_runner_url_save => 'Save URL';

  @override
  String get settings_runner_url_clear => 'Clear';

  @override
  String get settings_runner_url_saved => 'Runner URL saved';

  @override
  String get settings_runner_url_cleared => 'Runner URL cleared';

  @override
  String get settings_runner_check => 'Check connection';

  @override
  String get settings_runner_connected => 'Runner reachable ✓';

  @override
  String get settings_runner_auth_failed => 'Runner rejected the API token';

  @override
  String get settings_runner_unreachable => 'Runner unreachable';

  @override
  String get settings_runner_connecting => 'Checking connection…';

  @override
  String settings_runner_active(String url) {
    return 'Active Runner API: $url';
  }

  @override
  String get settings_runner_disable_temp => 'Temporarily disable Runner';

  @override
  String get settings_runner_disable_temp_desc =>
      'Keep Runner settings but force local mode until re-enabled.';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner temporarily disabled (local mode active)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner temporarily disabled';

  @override
  String get settings_runner_reenabled => 'Runner re-enabled';

  @override
  String get settings_main_api_title => 'Bot Creator Server';

  @override
  String get settings_main_api_desc =>
      'Connect Bot Creator to your Bot Creator Server and sign in with Discord. The Discord client secret must stay on the backend.';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_save => 'Save Bot Creator Server';

  @override
  String get settings_main_api_clear => 'Clear';

  @override
  String get settings_main_api_saved => 'Bot Creator Server settings saved';

  @override
  String get settings_main_api_cleared => 'Bot Creator Server settings cleared';

  @override
  String get settings_main_api_check => 'Check Bot Creator Server';

  @override
  String get settings_main_api_connected => 'Bot Creator Server reachable ✓';

  @override
  String get settings_main_api_unreachable => 'Bot Creator Server unreachable';

  @override
  String get settings_main_api_auth_failed =>
      'Bot Creator Server session is invalid or expired';

  @override
  String get settings_main_api_connect_discord => 'Connect Discord account';

  @override
  String get settings_main_api_disconnect => 'Disconnect account';

  @override
  String get settings_main_api_desktop_only =>
      'Discord login via Bot Creator Server is available on desktop only.';

  @override
  String get settings_main_api_not_configured =>
      'Bot Creator Server URL required';

  @override
  String get settings_main_api_session_connected => 'Discord session active';

  @override
  String get settings_main_api_session_disconnected =>
      'Discord session disconnected';

  @override
  String get settings_main_api_session_expired => 'Discord session expired';

  @override
  String get settings_main_api_url_required =>
      'Bot Creator Server URL required';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Connected as $user';
  }

  @override
  String get settings_main_api_user_unknown => 'Discord user';

  @override
  String get settings_main_api_connected_discord => 'Discord account connected';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_desc =>
      'Publish Bot Creator desktop activity to the local Discord client. Bot Creator always uses the built-in Discord application and sends SET_ACTIVITY directly over local IPC when enabled.';

  @override
  String get settings_discord_rpc_enable => 'Enable Discord Rich Presence';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'This ID is fixed in Bot Creator and cannot be changed from settings.';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Discord application client secret (optional)';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Client secret';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Optional advanced fallback for a confidential-client flow handled locally.';

  @override
  String get settings_discord_rpc_broker_label =>
      'OAuth broker URL (advanced, optional)';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_save => 'Save settings';

  @override
  String get settings_discord_rpc_saved =>
      'Discord Rich Presence settings saved';

  @override
  String get settings_discord_rpc_connect => 'Refresh presence';

  @override
  String get settings_discord_rpc_authorize => 'Authorize';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Complete authorization';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Authorization code received';

  @override
  String get settings_discord_rpc_open_ipc => 'Open local IPC';

  @override
  String get settings_discord_rpc_ipc_open => 'Local IPC already open';

  @override
  String get settings_discord_rpc_disconnect => 'Close IPC';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Authorized user: $user';
  }

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'IPC endpoint: $endpoint';
  }

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Last error: $error';
  }

  @override
  String get settings_discord_rpc_enable_first =>
      'Enable Discord Rich Presence first';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Discord application client ID required';

  @override
  String get settings_discord_rpc_disabled => 'Disabled';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence is desktop only';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Discord transport is not supported on this platform yet';

  @override
  String get settings_discord_rpc_not_configured => 'Client ID required';

  @override
  String get settings_discord_rpc_broker_required =>
      'Client ID is enough for the public-client flow; broker URL and client secret are optional fallbacks';

  @override
  String get settings_discord_rpc_disconnected => 'IPC closed';

  @override
  String get settings_discord_rpc_needs_authorization =>
      'Authorization required';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Authorization code cached; retry to finish the token exchange';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'Local Discord IPC connected; no OAuth HTTP request sent yet, authentication still required';

  @override
  String get settings_discord_rpc_connecting => 'Connecting to Discord…';

  @override
  String get settings_discord_rpc_authorizing =>
      'Waiting for Discord authorization…';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'Completing OAuth exchange…';

  @override
  String get settings_discord_rpc_authenticating =>
      'Authenticating with Discord…';

  @override
  String get settings_discord_rpc_connected => 'Presence sent to Discord';

  @override
  String get settings_discord_rpc_error => 'Discord RPC error';

  @override
  String get settings_data_operations_title => 'Data Operations';

  @override
  String get settings_export => 'Export';

  @override
  String get settings_import => 'Import';

  @override
  String get settings_export_app_data => 'Export App Data';

  @override
  String get settings_import_app_data => 'Import App Data';

  @override
  String get settings_export_loading => 'Exporting…';

  @override
  String get settings_import_loading => 'Importing…';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_enable_auto_backup => 'Enable auto-backup';

  @override
  String get settings_enable_auto_backup_desc =>
      'Create versioned snapshots automatically when due.';

  @override
  String get settings_auto_backup_interval => 'Auto-backup interval';

  @override
  String get settings_auto_backup_every_6h => 'Every 6h';

  @override
  String get settings_auto_backup_every_12h => 'Every 12h';

  @override
  String get settings_auto_backup_every_24h => 'Every 24h';

  @override
  String get settings_auto_backup_every_72h => 'Every 72h';

  @override
  String get settings_last_auto_backup_never => 'Last auto-backup: never';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Last auto-backup: $date';
  }

  @override
  String get settings_snapshot_create_loading => 'Creating snapshot…';

  @override
  String get settings_manual_snapshot_label => 'Manual snapshot';

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot created: $id';
  }

  @override
  String get settings_backup_now => 'Backup now';

  @override
  String get settings_run_auto_backup_now => 'Run auto-backup now';

  @override
  String get settings_auto_backup_check_loading => 'Auto-backup check…';

  @override
  String get settings_snapshots_title => 'Snapshots';

  @override
  String get settings_snapshots_refresh => 'Refresh snapshots';

  @override
  String get settings_snapshots_delete_all => 'Delete all snapshots';

  @override
  String get settings_snapshots_delete_all_title => 'Delete all snapshots';

  @override
  String settings_snapshots_delete_all_confirm(String count) {
    return 'Permanently delete $count snapshot(s)? This action cannot be undone.';
  }

  @override
  String get settings_snapshots_delete_all_loading => 'Deleting all snapshots…';

  @override
  String settings_snapshots_delete_all_done(String count) {
    return '$count snapshot(s) deleted.';
  }

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Delete a selected snapshot';

  @override
  String get settings_snapshots_delete_select_title => 'Delete a snapshot';

  @override
  String get settings_snapshots_delete_select_desc =>
      'Select the snapshot to remove (oldest first).';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Permanently delete \"$label\"? This action cannot be undone.';
  }

  @override
  String get settings_snapshots_refresh_loading => 'Refreshing snapshots…';

  @override
  String get settings_snapshots_empty => 'No snapshots found yet.';

  @override
  String settings_snapshot_list_entry(String date, String count, String size) {
    return '$date • $count files • $size';
  }

  @override
  String get settings_diagnostics_section_title => 'Diagnostics';

  @override
  String get settings_diagnostics_page_title => 'Application Logs';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Shows app diagnostics logs only (bot logs are excluded).';

  @override
  String get settings_diagnostics_refresh => 'Refresh logs';

  @override
  String get settings_diagnostics_copy_all => 'Copy all logs';

  @override
  String get settings_diagnostics_empty => 'No application logs yet.';

  @override
  String get settings_view_startup_logs => 'View startup logs';

  @override
  String get settings_clear_logs => 'Clear logs';

  @override
  String get settings_logs_cleared => 'Diagnostics log cleared';

  @override
  String get settings_legal_title => 'Legal';

  @override
  String get settings_legal_desc =>
      'Review how your data is handled and stored.';

  @override
  String get settings_privacy_policy => 'Privacy Policy';

  @override
  String get settings_compatibility_title => 'BDFD compatibility snapshot';

  @override
  String get settings_compatibility_desc =>
      'A quick view of feature coverage for users moving from BDFD.';

  @override
  String get settings_compatibility_status_supported => 'Supported';

  @override
  String get settings_compatibility_status_partial => 'Partial';

  @override
  String get settings_compatibility_status_missing => 'Missing';

  @override
  String get settings_compatibility_item_workflows_title => 'Workflow builder';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Visual command and response workflows are available.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Runtime variables and templates';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Dynamic variables and template helpers are supported.';

  @override
  String get settings_compatibility_item_events_title => 'Event coverage';

  @override
  String get settings_compatibility_item_events_desc =>
      'Most common events are supported, some are runtime-limited.';

  @override
  String get settings_compatibility_item_runner_title => 'Runner architecture';

  @override
  String get settings_compatibility_item_runner_desc =>
      'Remote runner is available, multi-runner support is in progress.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'BDScript function parity';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Full coverage of the BDFD function catalog.';

  @override
  String get settings_compatibility_note =>
      'This snapshot is intentionally high-level and will evolve with releases.';

  @override
  String get settings_compatibility_open_functions =>
      'View compatible functions';

  @override
  String get settings_compatibility_functions_title =>
      'Compatible BDFD Functions';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Functions currently implemented and usable in Bot Creator BDFD mode.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Diff view between Bot Creator implementation and BDFD reference functions.';

  @override
  String settings_compatibility_functions_count(String count) {
    return 'Compatible functions: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(String count) {
    return 'Bot Creator supported: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(String count) {
    return 'BDFD reference total: $count';
  }

  @override
  String settings_compatibility_functions_count_both(String count) {
    return 'Supported on both: $count';
  }

  @override
  String settings_compatibility_functions_count_missing(String count) {
    return 'Missing in Bot Creator: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(String count) {
    return 'Bot Creator only: $count';
  }

  @override
  String get settings_compatibility_functions_note =>
      'This page is generated from the current implementation scope and will grow over time.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'BDFD-only entries are functions listed in the provided BDFD catalog but not currently implemented in Bot Creator.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Search a function (example: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_both =>
      'Supported on Bot Creator and BDFD';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Supported on Bot Creator only';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Loop helpers are currently Bot Creator specific.';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Available on BDFD but missing in Bot Creator';

  @override
  String get settings_compatibility_functions_empty =>
      'No function in this section.';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Guards and permissions';

  @override
  String get settings_compatibility_functions_category_control =>
      'Control flow';

  @override
  String get settings_compatibility_functions_category_messages => 'Messages';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_components =>
      'Components / Interactions';

  @override
  String get settings_compatibility_functions_category_logging => 'Logging';

  @override
  String get settings_compatibility_functions_category_json => 'JSON helpers';

  @override
  String get settings_compatibility_functions_category_http => 'HTTP helpers';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Scoped variables';

  @override
  String get settings_compatibility_functions_category_threads => 'Threads';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Runtime placeholders';

  @override
  String get settings_ads_privacy_manage => 'Manage ad privacy choices';

  @override
  String get settings_ads_privacy_not_required =>
      'Ad privacy options are not required right now';

  @override
  String get settings_ads_privacy_loading => 'Checking ad privacy settings...';

  @override
  String get settings_ads_privacy_opened => 'Ad privacy options opened';

  @override
  String get settings_ads_privacy_open_error =>
      'Could not open ad privacy options';

  @override
  String get action_name_deleteMessages => 'Delete Messages';

  @override
  String get action_name_createChannel => 'Create Channel';

  @override
  String get action_name_updateChannel => 'Update Channel';

  @override
  String get action_name_removeChannel => 'Remove Channel';

  @override
  String get action_name_sendMessage => 'Send Message';

  @override
  String get action_name_editMessage => 'Edit Message';

  @override
  String get action_name_addReaction => 'Add Reaction';

  @override
  String get action_name_removeReaction => 'Remove Reaction';

  @override
  String get action_name_clearAllReactions => 'Clear All Reactions';

  @override
  String get action_name_banUser => 'Ban User';

  @override
  String get action_name_unbanUser => 'Unban User';

  @override
  String get action_name_kickUser => 'Kick User';

  @override
  String get action_name_muteUser => 'Mute User';

  @override
  String get action_name_unmuteUser => 'Unmute User';

  @override
  String get action_name_addRole => 'Add Role';

  @override
  String get action_name_removeRole => 'Remove Role';

  @override
  String get action_name_pinMessage => 'Pin Message';

  @override
  String get action_name_updateAutoMod => 'Update AutoMod';

  @override
  String get action_name_updateGuild => 'Update Guild';

  @override
  String get action_name_listMembers => 'List Members';

  @override
  String get action_name_getMember => 'Get Member';

  @override
  String get action_name_sendComponentV2 => 'Send Component V2';

  @override
  String get action_name_editComponentV2 => 'Edit Component V2';

  @override
  String get action_name_sendWebhook => 'Send Webhook';

  @override
  String get action_name_editWebhook => 'Edit Webhook';

  @override
  String get action_name_deleteWebhook => 'Delete Webhook';

  @override
  String get action_name_listWebhooks => 'List Webhooks';

  @override
  String get action_name_getWebhook => 'Get Webhook';

  @override
  String get action_name_httpRequest => 'HTTP Request';

  @override
  String get action_name_setGlobalVariable => 'Set Global Variable';

  @override
  String get action_name_getGlobalVariable => 'Get Global Variable';

  @override
  String get action_name_removeGlobalVariable => 'Remove Global Variable';

  @override
  String get action_name_setScopedVariable => 'Set Scoped Variable';

  @override
  String get action_name_getScopedVariable => 'Get Scoped Variable';

  @override
  String get action_name_removeScopedVariable => 'Remove Scoped Variable';

  @override
  String get action_name_renameScopedVariable => 'Rename Scoped Variable';

  @override
  String get action_name_listScopedVariableIndex =>
      'List Scoped Variable Index';

  @override
  String get action_name_appendArrayElement => 'Append Array Element';

  @override
  String get action_name_removeArrayElement => 'Remove Array Element';

  @override
  String get action_name_queryArray => 'Query Array';

  @override
  String get action_name_runWorkflow => 'Run Workflow';

  @override
  String get action_name_runBdfdScript => 'Run BDFD Script';

  @override
  String get action_name_respondWithMessage => 'Respond with Message';

  @override
  String get action_name_respondWithComponentV2 => 'Respond with Component V2';

  @override
  String get action_name_respondWithModal => 'Respond with Modal';

  @override
  String get action_name_editInteractionMessage => 'Edit Interaction Message';

  @override
  String get action_name_listenForButtonClick => 'Listen for Button Click';

  @override
  String get action_name_listenForSelectMenu => 'Listen for Select Menu';

  @override
  String get action_name_listenForModalSubmit => 'Listen for Modal Submit';

  @override
  String get action_name_respondWithAutocomplete => 'Respond with Autocomplete';

  @override
  String get action_name_stopUnless => 'Stop Unless Condition';

  @override
  String get action_name_ifBlock => 'IF / ELSE Block';

  @override
  String get action_name_calculate => 'Calculate';

  @override
  String get action_name_getMessage => 'Get Message';

  @override
  String get action_name_unpinMessage => 'Unpin Message';

  @override
  String get action_name_createPoll => 'Create Poll';

  @override
  String get action_name_endPoll => 'End Poll';

  @override
  String get action_name_createInvite => 'Create Invite';

  @override
  String get action_name_deleteInvite => 'Delete Invite';

  @override
  String get action_name_getInvite => 'Get Invite';

  @override
  String get action_name_moveToVoiceChannel => 'Move to Voice Channel';

  @override
  String get action_name_disconnectFromVoice => 'Disconnect from Voice';

  @override
  String get action_name_serverMuteMember => 'Server Mute Member';

  @override
  String get action_name_serverDeafenMember => 'Server Deafen Member';

  @override
  String get action_name_createEmoji => 'Create Emoji';

  @override
  String get action_name_updateEmoji => 'Update Emoji';

  @override
  String get action_name_deleteEmoji => 'Delete Emoji';

  @override
  String get action_name_createAutoModRule => 'Create AutoMod Rule';

  @override
  String get action_name_deleteAutoModRule => 'Delete AutoMod Rule';

  @override
  String get action_name_listAutoModRules => 'List AutoMod Rules';

  @override
  String get action_name_getGuildOnboarding => 'Get Guild Onboarding';

  @override
  String get action_name_updateGuildOnboarding => 'Update Guild Onboarding';

  @override
  String get action_name_updateSelfUser => 'Update Self User (Bot Profile)';

  @override
  String get action_name_createThread => 'Create Thread';

  @override
  String get action_name_editChannelPermissions => 'Edit Channel Permissions';

  @override
  String get action_name_deleteChannelPermission => 'Delete Channel Permission';

  @override
  String home_token_missing(String botName) {
    return 'Token not found for $botName';
  }

  @override
  String get home_log_start_requested => 'Bot start requested';

  @override
  String get home_log_stop_requested => 'Bot stop requested';

  @override
  String get home_notification_permission_required =>
      'Notification permission is required to start the bot.';

  @override
  String get home_foreground_service_not_started =>
      'The foreground service did not start.';

  @override
  String get home_log_desktop_stop_requested => 'Desktop bot stop requested';

  @override
  String get home_unknown_app => 'Unknown';

  @override
  String get home_status_online => 'Online';

  @override
  String get home_status_offline => 'Offline';

  @override
  String home_server_count_one(String count) {
    return '$count server';
  }

  @override
  String home_server_count_other(String count) {
    return '$count servers';
  }

  @override
  String get home_stop => 'Stop';

  @override
  String get home_start => 'Start';

  @override
  String get home_start_ads => 'Watch Ads to Start';

  @override
  String get home_start_premium => 'Start';

  @override
  String get home_add_time => 'Add Time';

  @override
  String home_hosting_time_left(String minutes) {
    return 'Hosting Time left: $minutes min';
  }

  @override
  String get home_manage => 'Manage';

  @override
  String get home_logs_tooltip => 'Bot logs';

  @override
  String get rewarded_start_title => 'Ad Required';

  @override
  String get rewarded_start_message =>
      'An ad is required to start this hosting session. This helps fund the project. Premium users can skip this.';

  @override
  String get rewarded_start_watch => 'Watch ad';

  @override
  String get rewarded_start_continue => 'Continue';

  @override
  String get rewarded_start_skip => 'Skip';

  @override
  String get rewarded_start_thanks => 'Thanks for your support!';

  @override
  String get ads_consent_title => 'Ads consent';

  @override
  String get ads_consent_message =>
      'To comply with GDPR, we need your consent before showing ads. You can continue using the app even if you refuse.';

  @override
  String get ads_consent_accept => 'I accept';

  @override
  String get ads_consent_refuse => 'I refuse';

  @override
  String get ads_consent_refused_info =>
      'Ad consent declined. The bot will still start normally.';

  @override
  String get error => 'Error';

  @override
  String error_with_details(String error) {
    return 'Error: $error';
  }

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get copy => 'Copy';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get confirm => 'Confirm';

  @override
  String get bot_home_start => 'Start Bot';

  @override
  String get bot_home_starting => 'Starting…';

  @override
  String get bot_home_stop => 'Stop Bot';

  @override
  String get bot_home_ios_notice_title => 'Local iOS constraint';

  @override
  String get bot_home_ios_notice_content =>
      'In local mode, iOS may suspend the app in the background. The bot can start, but keeping the Discord connection alive is not guaranteed like it is with a Runner.';

  @override
  String get bot_home_view_logs => 'View bot logs';

  @override
  String get bot_home_view_stats => 'View bot stats';

  @override
  String get bot_home_view_replay => 'View debugger replays';

  @override
  String get bot_home_section_getting_started => 'GETTING STARTED';

  @override
  String get bot_home_customize => 'Customize my bot';

  @override
  String get bot_home_create_command => 'Create my first command';

  @override
  String get bot_home_section_monitoring => 'MONITORING';

  @override
  String get bot_home_section_tools => 'TOOLS';

  @override
  String get bot_home_section_danger => 'DANGER ZONE';

  @override
  String get bot_home_sync => 'Sync App';

  @override
  String get bot_home_sync_success => 'App synced successfully';

  @override
  String get bot_home_invite => 'Invite Bot';

  @override
  String get bot_home_invite_error => 'Could not open invite link';

  @override
  String get bot_home_delete => 'Delete App';

  @override
  String get bot_home_delete_confirm =>
      'Are you sure you want to delete this app?';

  @override
  String bot_home_start_error(String error) {
    return 'Could not start: $error';
  }

  @override
  String get bot_home_log_start => 'Bot start requested';

  @override
  String get bot_home_log_stop => 'Bot stop requested';

  @override
  String get bot_home_log_desktop_stop => 'Desktop bot stop requested';

  @override
  String get bot_home_notif_required =>
      'Notification permission is required to start the bot service.';

  @override
  String get bot_home_service_not_started =>
      'Foreground service did not start.';

  @override
  String get bot_home_token_invalid_title => 'Token seems invalid';

  @override
  String get bot_home_token_invalid_content =>
      'Unable to connect to Discord with the provided token. It may be invalid or revoked. Do you want to start the bot anyway?';

  @override
  String get bot_offline_token_desc =>
      'Token invalid or missing. Enter a new Discord bot token to restore the connection.';

  @override
  String get cmd_offline_incomplete_warning =>
      'This command could not be fully loaded (offline or token invalid). Connect a valid token to edit.';

  @override
  String get bot_settings_token_mismatch_title => 'Different bot detected';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'This token belongs to bot $newId, but the current data is for bot $oldId. Commands and settings may not match. Continue anyway?';
  }

  @override
  String get bot_settings_token_mismatch_confirm => 'Replace token anyway';

  @override
  String get bot_settings_title => 'Customize Bot / Profile';

  @override
  String get bot_settings_workflow_docs => 'Documentation Center';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Centralized documentation for commands, workflows, runtime variables, and execution behavior.';

  @override
  String get bot_settings_export_import => 'Export / Import';

  @override
  String get bot_settings_export_import_desc =>
      'Export or import your bot configuration as a ZIP file.';

  @override
  String get bot_settings_app_flags => 'Application Flags';

  @override
  String get bot_settings_gateway_intents => 'Gateway Intents Configuration';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Select which intents your bot needs. Configure these in the Discord Developer Portal.';

  @override
  String get bot_settings_token_title => 'Bot Token';

  @override
  String get bot_settings_update_token => 'Update Bot Token';

  @override
  String get bot_settings_token_hint => 'Enter your bot token here';

  @override
  String get bot_settings_save_success => 'Settings saved successfully';

  @override
  String get bot_settings_save_token_btn => 'Save token and intents';

  @override
  String get bot_settings_save_token_only_btn => 'Save token';

  @override
  String get bot_settings_save_intents_btn => 'Save intents';

  @override
  String get bot_settings_save_profile_status_btn =>
      'Save profile and statuses';

  @override
  String get bot_settings_save_token_caption =>
      'Token changes are protected. Click \"Edit token\" first, then save.';

  @override
  String get bot_settings_save_intents_caption =>
      'This only updates gateway intents configuration.';

  @override
  String get bot_settings_save_profile_caption =>
      'This applies username/avatar instantly and saves status rotation.';

  @override
  String get bot_settings_token_saved => 'Token saved successfully';

  @override
  String get bot_settings_intents_saved => 'Intents saved successfully';

  @override
  String get bot_settings_profile_saved =>
      'Profile/statuses applied successfully';

  @override
  String get bot_settings_edit_token_btn => 'Edit token';

  @override
  String get bot_settings_cancel_token_edit_btn => 'Cancel token edit';

  @override
  String get bot_settings_token_hidden_desc =>
      'Token input is hidden by default for safety.';

  @override
  String get bot_settings_token_required => 'Bot token is required.';

  @override
  String get bot_settings_save_token_first =>
      'Please save the token first before applying profile/status changes.';

  @override
  String get bot_settings_profile_title => 'Bot Profile';

  @override
  String get bot_settings_username_override => 'Username override';

  @override
  String get bot_settings_username_hint =>
      'Leave empty to keep current username';

  @override
  String get bot_settings_avatar_local_path => 'Avatar local file path';

  @override
  String get bot_settings_avatar_path_hint => '/absolute/path/to/avatar.png';

  @override
  String get bot_settings_browse => 'Browse';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Selected file: $path';
  }

  @override
  String get bot_settings_avatar_preview_label => 'Avatar preview';

  @override
  String get bot_settings_avatar_preview_error => 'Unable to preview image';

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Unsupported avatar format: $ext. Supported formats: $formats.';
  }

  @override
  String get bot_settings_avatar_clear_selection => 'Clear selection';

  @override
  String get bot_settings_presence_status_title => 'Bot Presence Status';

  @override
  String get bot_settings_presence_status_label => 'Presence';

  @override
  String get bot_settings_presence_online => 'Online';

  @override
  String get bot_settings_presence_idle => 'Idle (Away)';

  @override
  String get bot_settings_presence_dnd => 'Do Not Disturb';

  @override
  String get bot_settings_presence_invisible => 'Invisible';

  @override
  String get bot_settings_status_rotation_title => 'Activities Rotation';

  @override
  String get bot_settings_status_rotation_desc =>
      'Add one or more activities. Each activity needs a type, name, and min/max interval (seconds).';

  @override
  String get bot_settings_add_status => 'Add activity';

  @override
  String bot_settings_status_item_title(String index) {
    return 'Activity $index';
  }

  @override
  String get bot_settings_remove_status => 'Remove activity';

  @override
  String get bot_settings_status_type_label => 'Type';

  @override
  String get bot_settings_status_type_playing => 'Playing';

  @override
  String get bot_settings_status_type_streaming => 'Streaming';

  @override
  String get bot_settings_status_type_listening => 'Listening';

  @override
  String get bot_settings_status_type_watching => 'Watching';

  @override
  String get bot_settings_status_type_competing => 'Competing';

  @override
  String get bot_settings_status_text_label => 'Activity name';

  @override
  String get bot_settings_activity_state_label => 'Activity state (optional)';

  @override
  String get bot_settings_activity_url_label => 'Stream URL (for streaming)';

  @override
  String get bot_settings_status_min_interval => 'Min interval (s)';

  @override
  String get bot_settings_status_max_interval => 'Max interval (s)';

  @override
  String get bot_logs_title => 'Bot Logs';

  @override
  String get bot_logs_disable_debug => 'Disable debug logs';

  @override
  String get bot_logs_enable_debug => 'Enable debug logs';

  @override
  String get bot_logs_copied => 'Logs copied';

  @override
  String get bot_logs_oldest_first => 'Show oldest first';

  @override
  String get bot_logs_newest_first => 'Show newest first';

  @override
  String get bot_logs_filter_count => 'Number of displayed logs';

  @override
  String bot_logs_show_n(String count) {
    return 'Show $count logs';
  }

  @override
  String get bot_logs_show_all => 'Show all';

  @override
  String get bot_logs_empty => 'No logs yet';

  @override
  String get bot_logs_show_more => 'Show more';

  @override
  String get bot_logs_show_less => 'Show less';

  @override
  String bot_logs_ram(String memory) {
    return 'Bot process RAM: $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'Estimated bot RAM: $memory';
  }

  @override
  String get bot_logs_go_to_latest => 'Go to latest log';

  @override
  String get bot_logs_go_to_bottom => 'Go to bottom';

  @override
  String get bot_logs_raw_mode => 'Compact raw logs';

  @override
  String get bot_logs_rich_mode => 'Rich formatted logs';

  @override
  String get debug_replay_title => 'Debugger Replay';

  @override
  String get debug_replay_start_capture => 'Enable capture';

  @override
  String get debug_replay_stop_capture => 'Disable capture';

  @override
  String get debug_replay_clear => 'Clear replays';

  @override
  String get debug_replay_clear_title => 'Clear replays';

  @override
  String get debug_replay_clear_confirm =>
      'All recorded replays will be deleted. Continue?';

  @override
  String get debug_replay_empty_capturing =>
      'Capturing… Run a command to record a replay.';

  @override
  String get debug_replay_empty_idle =>
      'Capture is off. Enable it and run a command to record a replay.';

  @override
  String get debug_replay_premium_title => 'Visual Debugger Replay';

  @override
  String get debug_replay_premium_desc =>
      'Record and replay your command executions step by step. See exactly what each action did, how long it took, and where errors occurred.';

  @override
  String get debug_replay_overview => 'Overview';

  @override
  String get debug_replay_play => 'Play';

  @override
  String get debug_replay_pause => 'Pause';

  @override
  String get debug_replay_step_first => 'First step';

  @override
  String get debug_replay_step_last => 'Last step';

  @override
  String get debug_replay_step_back => 'Previous step';

  @override
  String get debug_replay_step_forward => 'Next step';

  @override
  String get debug_replay_duration_label => 'DURATION';

  @override
  String get debug_replay_result_label => 'RESULT';

  @override
  String get debug_replay_result_empty => '(no result)';

  @override
  String debug_replay_start_offset(String ms) {
    return '+$ms ms from start';
  }

  @override
  String debug_replay_loop_info(String depth, String iteration) {
    return 'Loop depth $depth, iteration $iteration';
  }

  @override
  String get debug_replay_variables_label => 'VARIABLES';

  @override
  String get debug_replay_variables_empty => '(no variables)';

  @override
  String get bot_stats_title => 'Bot Stats';

  @override
  String get bot_stats_ram_process => 'Bot process RAM';

  @override
  String get bot_stats_ram_estimated => 'Bot RAM only (estimated)';

  @override
  String get bot_stats_cpu => 'Bot process CPU';

  @override
  String get bot_stats_storage => 'Bot storage (app data)';

  @override
  String get bot_stats_source_runner_api => 'Source: Runner API';

  @override
  String get bot_stats_source_local_hosting => 'Source: Local Hosting';

  @override
  String get bot_stats_notes =>
      'Notes: CPU available on Android/Linux. Storage = bot data files in the app.';

  @override
  String get bot_stats_collecting => 'Collecting…';

  @override
  String get commands_title => 'Commands';

  @override
  String get commands_empty => 'No commands found';

  @override
  String commands_error(String error) {
    return 'Error: $error';
  }

  @override
  String get commands_create_button => 'Create command';

  @override
  String get commands_move_to_folder => 'Move to folder';

  @override
  String get commands_remove_from_folder => 'Remove from folder';

  @override
  String get commands_new_folder_hint => 'New folder name';

  @override
  String get commands_folder_label => 'Folder';

  @override
  String get commands_folder_hint => 'Optional folder name';

  @override
  String get commands_create_folder => 'Create folder';

  @override
  String get commands_rename_folder => 'Rename folder';

  @override
  String get commands_delete_folder => 'Delete folder';

  @override
  String get commands_delete_folder_desc =>
      'The commands inside this folder will not be deleted, only un-foldered.';

  @override
  String get commands_reorder_title => 'Organize commands';

  @override
  String get commands_no_folder => 'No folder';

  @override
  String get export_import_title => 'Export / Import';

  @override
  String get export_section_title => 'Export';

  @override
  String get export_section_desc =>
      'Export selected sections of your bot as a ZIP file. The bot token is never included.';

  @override
  String get export_commands => 'Commands';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get export_status => 'Status & Activities';

  @override
  String get export_global_variables => 'Global Variables';

  @override
  String get export_button => 'Export ZIP';

  @override
  String get import_section_title => 'Import';

  @override
  String get import_section_desc =>
      'Import a previously exported ZIP file. Conflicts can be resolved per item.';

  @override
  String get import_pick_file => 'Select ZIP file';

  @override
  String get import_button => 'Import';

  @override
  String get import_overwrite => 'Overwrite';

  @override
  String get import_skip => 'Skip';

  @override
  String get globals_title => 'Variables';

  @override
  String get globals_empty => 'No global variables yet';

  @override
  String get globals_empty_subtitle =>
      'Add a variable to store persistent data accessible by all commands.';

  @override
  String get globals_add => 'Add Variable';

  @override
  String get globals_add_global => 'Add Global Variable';

  @override
  String get globals_add_scoped => 'Add Scoped Variable';

  @override
  String get globals_edit => 'Edit Variable';

  @override
  String get globals_edit_global => 'Edit Global Variable';

  @override
  String get globals_edit_scoped => 'Edit Scoped Variable';

  @override
  String get globals_key => 'Key';

  @override
  String get globals_key_hint => 'e.g. prefix, level, welcome_message';

  @override
  String get globals_value => 'Value';

  @override
  String get globals_delete_title => 'Delete Variable';

  @override
  String globals_delete_confirm(String key) {
    return 'Delete \"$key\"?';
  }

  @override
  String get globals_search => 'Search variables…';

  @override
  String get globals_mode_global => 'Global';

  @override
  String get globals_mode_scoped => 'Scoped';

  @override
  String get globals_help_global =>
      'Shared across all commands. Access via \$getVar[key].';

  @override
  String get globals_help_scoped =>
      'Stored per context (server, user, channel…). Each entry keeps a distinct value per Discord context.';

  @override
  String get globals_source_local => 'Local';

  @override
  String globals_source_runner(String name) {
    return 'Runner: $name';
  }

  @override
  String get globals_value_auto_type_hint =>
      'Value is auto-typed (number, boolean, JSON).';

  @override
  String get globals_copy_value => 'Copy value';

  @override
  String get globals_no_default => 'No default value';

  @override
  String get globals_dialog_global_desc =>
      'Global variables are shared across all commands and servers.';

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'A scoped variable stores a separate value per $scope context.';
  }

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Usage: \$getVar[$ref]';
  }

  @override
  String get scoped_title => 'Scoped Variables';

  @override
  String get scoped_empty => 'No scoped variables defined';

  @override
  String get scoped_empty_subtitle =>
      'Scoped variables store a value per Discord context (user, server…). They are populated by the bot at runtime.';

  @override
  String get scoped_delete_title => 'Delete Scoped Variable';

  @override
  String scoped_delete_confirm(String key) {
    return 'Delete \"$key\" and all its stored runtime data?';
  }

  @override
  String get scoped_default_value => 'Default value';

  @override
  String get scoped_default_value_hint => 'Optional';

  @override
  String get scoped_scope => 'Scope';

  @override
  String get scoped_scope_help =>
      'The entity level at which the variable is stored.';

  @override
  String scoped_ref(String ref) {
    return 'Reference: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legacy: $ref';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Runtime data — \"$key\"';
  }

  @override
  String scoped_runtime_subtitle(String scope, String count) {
    return 'Scope: $scope · $count context(s) found';
  }

  @override
  String get scoped_runtime_empty =>
      'No runtime data.\nThis key will be populated by the bot at execution.';

  @override
  String get scoped_runtime_copy_all => 'Copy all';

  @override
  String get scoped_runtime_search => 'Search by ID or name…';

  @override
  String get scoped_explore_runtime => 'Explore runtime data';

  @override
  String get globals_refresh => 'Refresh';

  @override
  String get globals_retry => 'Retry';

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
  String get workflows_empty => 'No workflows yet';

  @override
  String get workflows_create => 'Create Workflow';

  @override
  String get workflows_edit => 'Edit Workflow';

  @override
  String get workflows_name => 'Workflow Name';

  @override
  String get workflows_entry_point => 'Default Entry Point';

  @override
  String get workflows_entry_point_hint =>
      'Used if caller does not override it';

  @override
  String get workflows_arguments => 'Arguments';

  @override
  String get workflows_arg_name => 'Name';

  @override
  String get workflows_arg_default => 'Default value';

  @override
  String get workflows_arg_required_short => 'Req';

  @override
  String get workflows_arg_hint =>
      'Arguments become runtime variables as ((arg.name)) and ((workflow.arg.name)).';

  @override
  String get workflows_continue => 'Continue';

  @override
  String get workflows_add_arg => 'Add argument';

  @override
  String get workflows_docs_tooltip => 'Open documentation center';

  @override
  String workflows_subtitle(String count, String entry, String args) {
    return '$count action(s) • entry: $entry • args: $args';
  }

  @override
  String workflows_event_subtitle(String count, String event) {
    return '$count action(s) • Listen for: $event';
  }

  @override
  String get workflows_general_section => 'General Workflows';

  @override
  String get workflows_event_section => 'Event Workflows';

  @override
  String get workflows_type_title => 'Workflow type';

  @override
  String get workflows_type_general => 'General workflow';

  @override
  String get workflows_type_general_desc =>
      'Reusable logic called from commands, buttons, modals, or other workflows.';

  @override
  String get workflows_type_event => 'Event workflow';

  @override
  String get workflows_type_event_desc =>
      'Automatically reacts when Discord emits an event.';

  @override
  String get workflows_type_badge_general => 'General';

  @override
  String get workflows_type_badge_event => 'Event';

  @override
  String get workflows_listen_for => 'Listen for';

  @override
  String get workflows_event_category => 'Event category';

  @override
  String get workflows_event_hint =>
      'Choose the Discord event that should trigger this workflow.';

  @override
  String workflows_event_preview(String event) {
    return 'Listen for: $event';
  }

  @override
  String get workflows_event_available_vars => 'Available variables';

  @override
  String get workflows_event_category_messages => 'Messages';

  @override
  String get workflows_event_category_members => 'Members';

  @override
  String get workflows_event_category_channels => 'Channels';

  @override
  String get workflows_event_category_invites => 'Invites';

  @override
  String get workflows_event_message_create => 'Message Create';

  @override
  String get workflows_event_message_create_desc =>
      'Triggered whenever a new message is created.';

  @override
  String get workflows_event_message_update => 'Message Update';

  @override
  String get workflows_event_message_update_desc =>
      'Triggered whenever an existing message is edited.';

  @override
  String get workflows_event_message_delete => 'Message Delete';

  @override
  String get workflows_event_message_delete_desc =>
      'Triggered whenever a message is deleted.';

  @override
  String get workflows_event_member_join => 'Member Join';

  @override
  String get workflows_event_member_join_desc =>
      'Triggered whenever a member joins the guild.';

  @override
  String get workflows_event_member_remove => 'Member Remove';

  @override
  String get workflows_event_member_remove_desc =>
      'Triggered whenever a member leaves or is removed from the guild.';

  @override
  String get workflows_event_channel_update => 'Channel Update';

  @override
  String get workflows_event_channel_update_desc =>
      'Triggered whenever a channel is updated.';

  @override
  String get workflows_event_invite_create => 'Invite Create';

  @override
  String get workflows_event_invite_create_desc =>
      'Triggered whenever an invite is created.';

  @override
  String get workflows_import_tooltip => 'Import workflows';

  @override
  String get workflows_export_tooltip => 'Copy workflows';

  @override
  String get workflows_copy_none => 'No workflows to copy.';

  @override
  String get workflows_copy_done_json => 'Workflows copied as JSON.';

  @override
  String get workflows_copy_done_base64 => 'Workflows copied as Base64.';

  @override
  String get workflows_delete_title => 'Delete workflow';

  @override
  String workflows_delete_confirm(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get workflows_export_json => 'Copy as JSON';

  @override
  String get workflows_export_json_desc => 'Readable and easy to edit.';

  @override
  String get workflows_export_base64 => 'Copy as Base64';

  @override
  String get workflows_export_base64_desc => 'Convenient for compact sharing.';

  @override
  String get workflows_import_title => 'Import workflows';

  @override
  String get workflows_import_desc =>
      'Paste a JSON payload or Base64(JSON) exported from Bot Creator.';

  @override
  String get workflows_import_input_hint => 'Paste the JSON or Base64 here...';

  @override
  String get workflows_import_overwrite =>
      'Replace when the name already exists';

  @override
  String get workflows_import_action => 'Import';

  @override
  String get workflows_import_empty => 'No data to import.';

  @override
  String get workflows_import_invalid_format =>
      'Invalid format. Use JSON or Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'No valid workflow found.';

  @override
  String workflows_import_done(String count) {
    return '$count workflow(s) imported.';
  }

  @override
  String get workflows_move_to_folder => 'Move to folder';

  @override
  String get workflows_remove_from_folder => 'Remove from folder';

  @override
  String get workflows_new_folder_hint => 'New folder name';

  @override
  String get workflows_folder_label => 'Folder';

  @override
  String get workflows_folder_hint => 'Optional folder name';

  @override
  String get cmd_error_fill_fields => 'Please fill all fields';

  @override
  String get cmd_variables_title => 'Command Variables';

  @override
  String get cmd_show_variables => 'Open variable documentation';

  @override
  String get cmd_create_tooltip => 'Create command';

  @override
  String get cmd_delete_tooltip => 'Delete command';

  @override
  String get cmd_editor_mode_title => 'Editing mode';

  @override
  String get cmd_editor_mode_simple => 'Simplified mode';

  @override
  String get cmd_editor_mode_advanced => 'Advanced mode';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Build a command quickly with guided options and preconfigured actions.';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Full editor with custom response, options, and action builder.';

  @override
  String get cmd_editor_mode_switch_adv => 'Switch to advanced mode';

  @override
  String get cmd_editor_mode_switch_adv_title => 'Switch to advanced mode?';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'This switch is one-way for this command. You won’t be able to return to simplified mode.';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Switch';

  @override
  String get cmd_editor_mode_locked =>
      'Advanced mode is locked for this command.';

  @override
  String get cmd_execution_mode_title => 'Execution mode';

  @override
  String get cmd_execution_mode_desc =>
      'Command metadata stays in the visual builder. Choose how the command body should run.';

  @override
  String get cmd_execution_mode_workflow => 'Workflow mode';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Use the existing visual response and action builder.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'Workflow mode is the current production path and remains fully supported.';

  @override
  String get cmd_execution_mode_bdfd => 'BDFD Script mode';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Write the command body as BDFD-style script while keeping command definition visual.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'The script is compiled to internal actions. Diagnostics are shown while editing; invalid scripts fail when the command runs.';

  @override
  String get cmd_execution_mode_dart => 'Dart Direct mode';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Write the command body directly in Dart with runtime diagnostics.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Dart code is compiled at runtime through the sandboxed engine. Keep scripts deterministic and return a value when needed.';

  @override
  String get cmd_bdfd_script_label => 'BDFD script body';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHello from Bot Creator';

  @override
  String get cmd_bdfd_diagnostics_title => 'BDFD diagnostics';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'No issue detected in the current script.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Error';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Warning';

  @override
  String get cmd_bdfd_script_empty_error => 'BDFD script body cannot be empty.';

  @override
  String get cmd_bdfd_script_validation_error =>
      'This BDFD script still contains diagnostics:';

  @override
  String get cmd_dart_script_label => 'Dart script body';

  @override
  String get cmd_dart_script_hint => 'return \"Hello from Dart Direct\";';

  @override
  String get cmd_dart_diagnostics_title => 'Dart diagnostics';

  @override
  String get cmd_dart_diagnostics_clean =>
      'No issue detected in the current Dart script.';

  @override
  String get cmd_dart_diagnostics_error => 'Error';

  @override
  String get cmd_dart_diagnostics_warning => 'Warning';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Generate a Dart migration scaffold from your current BDFD script.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrate';

  @override
  String get cmd_bdfd_autocomplete_title => 'BDFD prefix autocomplete';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Type \$ and start writing a function name to get quick script suggestions.';

  @override
  String get workflow_mode_title => 'Workflow mode';

  @override
  String get workflow_mode_desc =>
      'Choose between a visual action builder or a full BDFD scripting editor.';

  @override
  String get workflow_mode_visual => 'Visual';

  @override
  String get workflow_mode_bdfd => 'BDFD Script';

  @override
  String get workflow_mode_dart => 'Dart Direct';

  @override
  String get workflow_mode_visual_note =>
      'Build your workflow visually by adding individual actions with the card editor.';

  @override
  String get workflow_mode_bdfd_note =>
      'Write your entire workflow as a single BDFD script. The script is compiled and validated in real time.';

  @override
  String get workflow_mode_dart_note =>
      'Write your workflow in Dart. Diagnostics are updated while editing to catch errors early.';

  @override
  String get workflow_bdfd_editor_title => 'BDFD Script Editor';

  @override
  String get workflow_bdfd_editor_desc =>
      'Write the complete BDFD code for this workflow response. Diagnostics are displayed live.';

  @override
  String get workflow_dart_editor_title => 'Dart Script Editor';

  @override
  String get workflow_dart_editor_desc =>
      'Write full Dart code for this workflow response. Diagnostics are displayed live.';

  @override
  String get bdfd_editor_title => 'BDFD Editor';

  @override
  String get bdfd_editor_tap_hint => 'Tap to open editor';

  @override
  String get bdfd_editor_wrap_toggle => 'Toggle line wrapping';

  @override
  String get bdfd_editor_diagnostics_toggle => 'Toggle diagnostics panel';

  @override
  String get bdfd_editor_empty =>
      'Empty script — start typing to see diagnostics.';

  @override
  String get dart_editor_title => 'Dart Editor';

  @override
  String get dart_editor_tap_hint => 'Tap to open Dart editor';

  @override
  String get dart_editor_empty =>
      'Empty script — start typing to see Dart diagnostics.';

  @override
  String get bdfd_editor_docs => 'BDFD Functions Reference';

  @override
  String get bdfd_docs_title => 'BDFD Docs';

  @override
  String get bdfd_docs_search_hint => 'Search functions…';

  @override
  String get scratch_block_metadata => 'Metadata';

  @override
  String get scratch_block_required => 'Required';

  @override
  String get scratch_block_entry_point => 'Command Trigger';

  @override
  String get scratch_entry_point_listen => 'When does this command run?';

  @override
  String get scratch_entry_interaction => 'Slash Command (/)';

  @override
  String get scratch_entry_message => 'Text Message';

  @override
  String get scratch_entry_point_label => 'Entry point name';

  @override
  String get scratch_execution_mode => 'How is the command built?';

  @override
  String get scratch_mode_blocks => 'Visual (Blocks)';

  @override
  String get scratch_mode_bdfd => 'BDFD Code';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_legacy_config => 'Legacy configuration';

  @override
  String get scratch_add_block => 'Add block';

  @override
  String get scratch_bdfd_script => 'BDFD Script';

  @override
  String get scratch_response_block => 'Response';

  @override
  String get scratch_response_components => 'Components';

  @override
  String get scratch_response_edit => 'Edit response';

  @override
  String get scratch_meta_name_hint => 'Command name';

  @override
  String get scratch_meta_desc_hint => 'Command description';

  @override
  String get scratch_meta_type_label => 'Command type';

  @override
  String get scratch_meta_type_slash => 'Slash command';

  @override
  String get scratch_meta_type_prefix => 'Prefix command';

  @override
  String get scratch_meta_type_user => 'User command';

  @override
  String get scratch_meta_type_message => 'Message command';

  @override
  String get scratch_meta_type_slash_desc =>
      'Triggered by typing / in Discord.';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Triggered by a text prefix (e.g. !help).';

  @override
  String get scratch_meta_type_user_desc =>
      'Triggered from the user context menu.';

  @override
  String get scratch_meta_type_message_desc =>
      'Triggered from the message context menu.';

  @override
  String get scratch_meta_advanced => 'Advanced settings';

  @override
  String get scratch_workflow_metadata => 'Workflow Settings';

  @override
  String get scratch_workflow_name => 'Workflow Name';

  @override
  String get scratch_workflow_type => 'Workflow Type';

  @override
  String get scratch_workflow_type_general => 'General';

  @override
  String get scratch_workflow_type_event => 'Event-driven';

  @override
  String get scratch_workflow_arguments => 'Arguments (Variables)';

  @override
  String get scratch_workflow_add_argument => 'Add argument';

  @override
  String get scratch_entry_event_trigger => 'Event trigger';

  @override
  String get scratch_entry_function => 'Function';

  @override
  String get scratch_event_category => 'Event category';

  @override
  String get scratch_event_name => 'Event name';

  @override
  String get scratch_event_variables => 'Event variables';

  @override
  String get bdfd_docs_empty => 'No matching functions.';

  @override
  String get bdfd_docs_syntax => 'SYNTAX';

  @override
  String get bdfd_docs_parameters => 'PARAMETERS';

  @override
  String get bdfd_docs_no_params => 'No parameters — use as \$functionName';

  @override
  String get bdfd_docs_category_messages => 'Messages & Content';

  @override
  String get bdfd_docs_category_embeds => 'Embeds';

  @override
  String get bdfd_docs_category_components => 'Components';

  @override
  String get bdfd_docs_category_modals => 'Modals';

  @override
  String get bdfd_docs_category_control => 'Control Flow';

  @override
  String get bdfd_docs_category_guards => 'Guards & Permissions';

  @override
  String get bdfd_docs_category_moderation => 'Moderation';

  @override
  String get bdfd_docs_category_variables => 'Variables';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_http => 'HTTP Requests';

  @override
  String get bdfd_docs_category_math => 'Math';

  @override
  String get bdfd_docs_category_text => 'Text & Strings';

  @override
  String get bdfd_docs_category_channels => 'Channels & Threads';

  @override
  String get bdfd_docs_category_roles => 'Roles';

  @override
  String get bdfd_docs_category_reactions => 'Reactions';

  @override
  String get bdfd_docs_category_cooldowns => 'Cooldowns';

  @override
  String get bdfd_docs_category_webhooks => 'Webhooks';

  @override
  String get bdfd_docs_category_leaderboards => 'Leaderboards';

  @override
  String get bdfd_docs_category_tickets => 'Tickets';

  @override
  String get bdfd_docs_category_misc => 'Other';

  @override
  String get bdfd_docs_desc_for =>
      'Bot Creator only — Repeats a block of code N times.\n\nSimple: \$for[5]...\$endfor → the body is repeated 5 times (max 100). You can use \$i for the current index (starting at 0) and \$loopCount for the total.\n\nC-style: \$for[i=0;i<10;i++]...\$endfor → classic for loop with init, condition and update. Supports ++, --, +=, -=, *=.\n\nIf the iteration count is dynamic (e.g. \$for[\$args[1]]), the loop runs at runtime instead of compile-time.';

  @override
  String get bdfd_docs_desc_loop =>
      'Bot Creator only — Alias for \$for. See \$for for details. Use \$endloop to close the block.';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Bot Creator only — Calls another workflow by name and passes arguments.\n\nSyntax: \$callWorkflow[myWorkflow;key1=value1;key2=value2]\n\nThe called workflow can read arguments and return a value via \$workflowResponse.';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Bot Creator only — Returns the response from the last \$callWorkflow.\n\nUse \$workflowResponse[] for the full response, or \$workflowResponse[property] to access a specific field.';

  @override
  String get bdfd_docs_desc_eval =>
      'Executes a BDFD script string at runtime. The code passed as argument is re-compiled and executed dynamically. Useful for running user-provided or variable-based scripts.';

  @override
  String get bdfd_docs_desc_if =>
      'Conditional block. Supports nesting and rich operators: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nUsage:\n\$if[\$authorID==123456]\n  Hello admin!\n\$elseif[\$hasRole[789]]\n  Hello member!\n\$else\n  Hello guest!\n\$endif';

  @override
  String get bdfd_docs_desc_elseif =>
      'Adds an alternative condition inside an \$if block. Must appear between \$if and \$else/\$endif.';

  @override
  String get bdfd_docs_desc_try =>
      'Wraps a block for error handling.\n\nUsage:\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  Request failed!\n\$endtry\n\nIf any function in the \$try block fails, execution jumps to \$catch.';

  @override
  String get bdfd_docs_desc_stop =>
      'Immediately stops execution of the current script. No further actions after \$stop will run.';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'Prevents error messages from being sent to the user. If any action fails, the error is silently suppressed.';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      'Same as \$suppressErrors — suppresses all error messages silently.';

  @override
  String get bdfd_docs_desc_and =>
      'Logical AND — combines multiple conditions. All must be true.\n\nUsage: \$if[\$and[\$authorID==123;\$hasRole[456]]]';

  @override
  String get bdfd_docs_desc_or =>
      'Logical OR — combines multiple conditions. At least one must be true.\n\nUsage: \$if[\$or[\$authorID==123;\$authorID==456]]]';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'Registers a callback that waits for a user response.\n\nUsage: \$awaitFunc[name;userID (opt);channelID (opt)]\n\nThe awaited function is stored and triggered when the target user sends a message in the target channel.';

  @override
  String get bdfd_docs_desc_defer =>
      'Defers the interaction response, giving you more time to process. The user sees a \"Bot is thinking…\" message. Use before long operations like HTTP requests.';

  @override
  String get bdfd_docs_desc_ephemeral =>
      'Makes the response visible only to the user who triggered the command. Must be placed before any response content.';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'Parses a JSON string into memory for manipulation. All JSON operations (\$jsonSet, \$json, etc.) operate on this parsed context.\n\nStatic JSON is resolved at compile-time for better performance.';

  @override
  String get bdfd_docs_desc_jsonset =>
      'Sets a value in the current JSON context. Supports dot-notation paths.\n\nUsage: \$jsonSet[user.name;John]\n\nThe change is applied in memory — use \$jsonStringify to get the result.';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      'Converts the current JSON context back to a string. Use after \$jsonParse and \$jsonSet operations to output the result.';

  @override
  String get bdfd_docs_desc_httpget =>
      'Sends an HTTP GET request to the given URL. Use \$httpAddHeader before to set headers. Use \$httpResult to read the response.\n\nAll HTTP methods (GET, POST, PUT, PATCH, DELETE) follow the same pattern.';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      'Adds a header to the next HTTP request. Headers are accumulated until the next \$httpGet/\$httpPost/etc.\n\nUsage: \$httpAddHeader[Authorization;Bearer token123]';

  @override
  String get bdfd_docs_desc_httpresult =>
      'Returns the body of the last HTTP response. Optionally pass a JSON path to extract a specific field.\n\nUsage: \$httpResult[] for the full body, or \$httpResult[data.name] for a nested field.';

  @override
  String get done => 'Done';

  @override
  String get cmd_simple_actions_title => 'Simplified actions';

  @override
  String get cmd_simple_actions_desc =>
      'Select what this command should do. Options are generated automatically.';

  @override
  String get cmd_simple_group_moderation_title => 'Moderation';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Member and moderation actions with guided options.';

  @override
  String get cmd_simple_group_messages_title => 'Messages';

  @override
  String get cmd_simple_group_messages_desc =>
      'Message and channel actions that work in the current context.';

  @override
  String get cmd_simple_group_utility_title => 'Utility';

  @override
  String get cmd_simple_group_utility_desc =>
      'Helpful extras such as invites and polls.';

  @override
  String get cmd_simple_action_delete => 'Delete messages';

  @override
  String get cmd_simple_action_delete_desc =>
      'Delete messages in the current channel (optional /count).';

  @override
  String get cmd_simple_action_kick => 'Kick user';

  @override
  String get cmd_simple_action_kick_desc =>
      'Kick the selected /user from the server.';

  @override
  String get cmd_simple_action_ban => 'Ban user';

  @override
  String get cmd_simple_action_ban_desc =>
      'Ban the selected /user from the server.';

  @override
  String get cmd_simple_action_unban => 'Unban user';

  @override
  String get cmd_simple_action_unban_desc =>
      'Unban a user with a provided /user_id string.';

  @override
  String get cmd_simple_action_mute => 'Mute user';

  @override
  String get cmd_simple_action_mute_desc =>
      'Temporarily mute the selected /user.';

  @override
  String get cmd_simple_action_unmute => 'Unmute user';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Remove the timeout from the selected /user.';

  @override
  String get cmd_simple_action_add_role => 'Add role';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Give the selected /role to the selected /user.';

  @override
  String get cmd_simple_action_remove_role => 'Remove role';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Remove the selected /role from the selected /user.';

  @override
  String get cmd_simple_action_send_message => 'Send message';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Send an additional message in the current channel.';

  @override
  String get cmd_simple_action_pin => 'Pin message';

  @override
  String get cmd_simple_action_pin_desc =>
      'Pin a message in the current channel using /message_id.';

  @override
  String get cmd_simple_action_unpin => 'Unpin message';

  @override
  String get cmd_simple_action_unpin_desc =>
      'Unpin a message in the current channel using /message_id.';

  @override
  String get cmd_simple_action_create_invite => 'Create invite';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'Create an invite for the current channel or an optional /channel.';

  @override
  String get cmd_simple_action_create_poll => 'Create poll';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'Create a poll with a dynamic /question and fixed answer choices.';

  @override
  String get cmd_simple_action_send_message_label => 'Action message';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Message sent by the Send Message action';

  @override
  String get cmd_simple_execution_title => 'Execution settings';

  @override
  String get cmd_simple_execution_desc =>
      'Fine-tune the generated actions without leaving simplified mode.';

  @override
  String get cmd_simple_action_reason_label => 'Audit log reason';

  @override
  String get cmd_simple_action_reason_hint =>
      'Optional reason shared by moderation actions';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Default delete count';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Used when /count is not provided';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Ban delete message days';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      '0 to 7 days of recent messages to delete';

  @override
  String get cmd_simple_action_mute_duration_label => 'Mute duration';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Examples: 10m, 2h, 1d, or raw seconds';

  @override
  String get cmd_simple_generated_options => 'Generated command options';

  @override
  String get cmd_simple_generated_none =>
      'No options generated yet. Select at least one action.';

  @override
  String get cmd_simple_option_user => '/user (User)';

  @override
  String get cmd_simple_option_role => '/role (Role)';

  @override
  String get cmd_simple_option_count => '/count (Integer)';

  @override
  String get cmd_simple_option_user_id => '/user_id (Text)';

  @override
  String get cmd_simple_option_message_id => '/message_id (Text)';

  @override
  String get cmd_simple_option_channel => '/channel (Channel)';

  @override
  String get cmd_simple_option_question => '/question (Text)';

  @override
  String get cmd_simple_option_user_desc => 'Target user';

  @override
  String get cmd_simple_option_role_desc => 'Target role';

  @override
  String get cmd_simple_option_count_desc => 'Number of messages to delete';

  @override
  String get cmd_simple_option_user_id_desc => 'User ID to unban';

  @override
  String get cmd_simple_option_message_id_desc => 'Message ID to target';

  @override
  String get cmd_simple_option_channel_desc =>
      'Optional channel override for invite creation';

  @override
  String get cmd_simple_option_question_desc => 'Poll question';

  @override
  String get cmd_simple_invite_settings_title => 'Invite settings';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Defaults used by the generated Create Invite action.';

  @override
  String get cmd_simple_invite_max_age_label => 'Invite expiry (seconds)';

  @override
  String get cmd_simple_invite_max_age_hint => '0 for no expiry, up to 604800';

  @override
  String get cmd_simple_invite_max_uses_label => 'Max uses';

  @override
  String get cmd_simple_invite_max_uses_hint => '0 for unlimited uses';

  @override
  String get cmd_simple_invite_temporary_label => 'Temporary membership';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Members are removed if they leave before getting a role.';

  @override
  String get cmd_simple_invite_unique_label => 'Force unique invite';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Always create a new invite instead of reusing an existing one.';

  @override
  String get cmd_simple_poll_settings_title => 'Poll settings';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Defaults used by the generated Create Poll action.';

  @override
  String get cmd_simple_poll_answers_label => 'Poll answers';

  @override
  String get cmd_simple_poll_answers_hint =>
      'One answer per line, or use commas. Minimum 2, maximum 10.';

  @override
  String get cmd_simple_poll_duration_label => 'Poll duration (hours)';

  @override
  String get cmd_simple_poll_duration_hint => 'From 1 to 168 hours';

  @override
  String get cmd_simple_poll_multiselect_label => 'Allow multiple answers';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Users can select more than one choice.';

  @override
  String get cmd_simple_response_title => 'Final response';

  @override
  String get cmd_simple_response_desc =>
      'Message sent back to the user after actions are executed.';

  @override
  String get cmd_simple_response_visibility_label => 'Response visibility';

  @override
  String get cmd_simple_response_visibility_public => 'Public';

  @override
  String get cmd_simple_response_visibility_ephemeral => 'Ephemeral';

  @override
  String get cmd_simple_response_hint => 'Done ✅';

  @override
  String get cmd_simple_response_embeds_title => 'Response embeds';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Optional embeds sent with the final response.';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Ban user and Unban user cannot be enabled together in simplified mode.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Mute user and Unmute user cannot be enabled together in simplified mode.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Pin message and Unpin message cannot be enabled together in simplified mode.';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'Invite expiry must be a number between 0 and 604800 seconds.';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Invite max uses must be a number between 0 and 1000000.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Poll answers must contain between 2 and 10 non-empty choices.';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'Poll duration must be a number between 1 and 168 hours.';

  @override
  String get cmd_simple_send_message_required =>
      'Please fill the action message before saving.';

  @override
  String get support_card_title => 'Support & Community';

  @override
  String get support_card_desc =>
      'A question, a bug, a suggestion? Come chat with the team and the community.';

  @override
  String get support_join_discord => 'Join the Discord server';

  @override
  String get support_discord_badge => 'Official support';

  @override
  String get home_empty_support_hint => 'Need help getting started?';

  @override
  String get home_empty_support_btn => 'Join our Discord';

  @override
  String get error_invalid_count => 'Count must be greater than 0.';

  @override
  String get error_invalid_channel_type => 'Channel is not a text channel.';

  @override
  String get error_network_timeout => 'The action timed out. Please try again.';

  @override
  String get error_delete_messages_failed => 'Failed to delete messages.';

  @override
  String get doc_center_title => 'Documentation Center';

  @override
  String get doc_center_search_hint =>
      'Search commands, workflows, variables, actions, intents, or examples...';

  @override
  String get doc_center_clear_search => 'Clear search';

  @override
  String get doc_center_empty => 'No documentation entry matches your search.';

  @override
  String get doc_kind_all => 'All';

  @override
  String get doc_kind_event => 'Event';

  @override
  String get doc_kind_action => 'Action';

  @override
  String get doc_kind_template => 'Template';

  @override
  String get doc_kind_runtime => 'Runtime';

  @override
  String get doc_required_intents => 'Required Intents';

  @override
  String get doc_available_variables => 'Available Variables';

  @override
  String get doc_example => 'Example';

  @override
  String get doc_common_section_best_use_cases => 'Best Use Cases';

  @override
  String get doc_common_section_important_notes => 'Important Notes';

  @override
  String get doc_template_variables_title => 'Template Variables';

  @override
  String get doc_template_variables_subtitle =>
      'How dynamic placeholders are resolved.';

  @override
  String get doc_template_variables_summary =>
      'Runtime resolves placeholders using current event/interaction context, workflow args, and global vars.';

  @override
  String get doc_template_variables_section_sources_title => 'Variable Sources';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'Command variables: commandName, commandId, commandType, target.*, opts.*.';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'Event variables: event.*, message.*, reaction.*, voice.*, role.*, etc.';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'Workflow variables: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'Global variables: global.<key>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'Action outputs: action.<key> when available.';

  @override
  String get doc_template_variables_section_builtin_title =>
      'Built-in Command Variables';

  @override
  String get doc_template_variables_section_types_title => 'Command Types';

  @override
  String get doc_template_variables_section_types_l1 =>
      'Slash commands use commandType = chatInput and expose opts.<option> variables.';

  @override
  String get doc_template_variables_section_types_l2 =>
      'User commands use commandType = user and expose target.user.* variables.';

  @override
  String get doc_template_variables_section_types_l3 =>
      'Message commands use commandType = message and expose target.message.* variables.';

  @override
  String get doc_template_variables_section_types_l4 =>
      'Subcommands still expose their arguments through opts.*.';

  @override
  String get doc_template_variables_section_fallbacks_title =>
      'Fallbacks and Paths';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'Use ((opts.user|userName)) to fall back when an option is missing.';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'Use JSONPath syntax on action outputs: ((myHttp.body.\$.data[0].id)); arrays and objects stay queryable.';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'Functions like length(...), join(...), formatEach(...), and embedFields(...) are also supported; unknown variables still resolve to an empty string.';

  @override
  String doc_template_variables_example(Object name, Object score) {
    return 'Hello ((target.user.username|userName))\nPlayers: ((join(scores.items.\$, \", \")))\nFields JSON: ((embedFields(scores.items.\$, \"\'$name\'\", \"\'$score\'\", true)))';
  }

  @override
  String get doc_template_functions_title => 'Template Functions';

  @override
  String get doc_template_functions_subtitle =>
      'Transform and compare data inside ((...)) expressions.';

  @override
  String get doc_template_functions_summary =>
      'Use template functions to normalize text, inspect arrays, build output blocks, and add lightweight randomness.';

  @override
  String get doc_template_functions_section_string_title => 'String Helpers';

  @override
  String get doc_template_functions_section_string_l1 =>
      'lowercase(source) / lower(source): convert text to lowercase.';

  @override
  String get doc_template_functions_section_string_l2 =>
      'uppercase(source) / upper(source): convert text to uppercase.';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(source): remove leading and trailing spaces.';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(source, search, replacement) and contains(source, needle) for substitutions and checks.';

  @override
  String get doc_template_functions_section_array_title =>
      'Array and Aggregate Helpers';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(source), at(source, index), first(source), last(source).';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(source, start, end?) and join(source, separator).';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(source): adds numeric items and ignores non-numeric values.';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) and embedFields(...) format object arrays for text and embeds.';

  @override
  String get doc_template_functions_section_random_title => 'Random Helpers';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() and random(): return \"true\" or \"\" for conditional branching.';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) and randomint(min, max).';

  @override
  String get doc_template_functions_section_notes_title => 'Important Notes';

  @override
  String get doc_template_functions_section_notes_l1 =>
      'Function names are case-insensitive.';

  @override
  String get doc_template_functions_section_notes_l2 =>
      'Unknown functions or invalid arguments resolve to an empty string.';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'Use fallback syntax with | at root level: ((replace(name, \"_\", \" \")|Unknown)).';

  @override
  String get doc_template_functions_section_notes_l4 =>
      'Arrays and objects returned by functions are serialized as JSON text.';

  @override
  String get doc_template_functions_example =>
      'Normalized: ((uppercase(trim(userName))))\nHas admin role: ((contains(userRole, \"admin\")))\nTop score: ((first(scores.\$)))\nTotal score: ((sum(scores.\$)))';

  @override
  String get doc_template_advanced_variables_title =>
      'Template Advanced Variables';

  @override
  String get doc_template_advanced_variables_subtitle =>
      'Additional runtime keys available in specific contexts.';

  @override
  String get doc_template_advanced_variables_summary =>
      'These keys are generated from interaction payloads and channel/guild/user runtime details, depending on the event or command type.';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'Interaction Metadata';

  @override
  String get doc_template_advanced_variables_section_interaction_l1 =>
      'interaction.kind identifies the incoming interaction mode (button, select, modal, command, autocomplete).';

  @override
  String get doc_template_advanced_variables_section_interaction_l2 =>
      'interaction.values and interaction.values.count are populated for select menus.';

  @override
  String get doc_template_advanced_variables_section_interaction_l3 =>
      'interaction.command.name and interaction.command.id are useful for diagnostics and routing checks.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'Channel and Guild Details';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l1 =>
      'channel.kind, channel.position, channel.bitrate, and channel.userLimit are context-dependent channel details.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l2 =>
      'Thread contexts can expose channel.thread.* values (archived, locked, ownerId, autoArchiveDuration).';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l3 =>
      'guild.kind helps distinguish partial/full guild payloads in advanced workflows.';

  @override
  String get doc_template_advanced_variables_section_aliases_title =>
      'User and Member Aliases';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      'Structured user aliases (user.id, user.username, user.tag, user.avatar, user.banner) are available in many command contexts.';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.id can be useful when both user and guild-member context are needed.';

  @override
  String get doc_template_advanced_variables_example =>
      'Kind: ((interaction.kind))\nSelected count: ((interaction.values.count|0))\nThread owner: ((channel.thread.ownerId|unknown))\nGuild payload kind: ((guild.kind|n/a))';

  @override
  String get doc_runtime_action_outputs_title => 'Runtime Action Outputs';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'How action result keys are exposed as runtime variables.';

  @override
  String get doc_runtime_action_outputs_summary =>
      'Most actions write a primary result key and may also expose prefixed fields under action.<resultKey>.* depending on the executor.';

  @override
  String get doc_runtime_action_outputs_section_patterns_title =>
      'Output Patterns';

  @override
  String get doc_runtime_action_outputs_section_patterns_l1 =>
      'Primary output is usually stored as <resultKey>.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l2 =>
      'Many executors also expose action.<resultKey>.* fields for clarity and namespacing.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l3 =>
      'Some fields are mirrored with and without the action. prefix.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_title =>
      'Common Output Fields';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l1 =>
      'HTTP actions: status, body, jsonPath.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l2 =>
      'Messaging/list actions: count, mode, deleteItself, deleteResponse.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l3 =>
      'Array actions: items, length, removed, total.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l4 =>
      'Other executors may expose result or messageId fields.';

  @override
  String get doc_runtime_action_outputs_section_caveats_title => 'Caveats';

  @override
  String get doc_runtime_action_outputs_section_caveats_l1 =>
      'Not every action exposes every suffix; availability is executor-specific.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l2 =>
      'For portability, prefer fallback expressions when reading optional output fields.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l3 =>
      'If a key is missing, template resolution returns an empty string.';

  @override
  String get doc_runtime_action_outputs_example =>
      'Status: ((action.http.status|http.status|unknown))\nBody: ((action.http.body|http.body))\nDeleted: ((cleanup.count|0))\nTotal: ((page.total|0))';

  @override
  String get doc_interaction_commands_title => 'Interaction Commands';

  @override
  String get doc_interaction_commands_subtitle =>
      'Slash, user and message command runtime behavior.';

  @override
  String get doc_interaction_commands_summary =>
      'Application commands are executed through a shared interaction path, with runtime variables depending on the Discord command type.';

  @override
  String get doc_interaction_commands_section_execution_title =>
      'Execution Model';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'Slash, user and message commands all enter the runner as application command interactions.';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'The runner matches commands by Discord command id, then validates stored type vs incoming type.';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'A type mismatch is logged as warning but does not hard-stop execution.';

  @override
  String get doc_interaction_commands_section_per_type_title =>
      'Per-Type Variables';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput: opts.* for parameters and subcommands.';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user: target.user.* and target.member.* when available.';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message: target.message.* including content and author id when resolved.';

  @override
  String get doc_interaction_commands_section_builtin_title =>
      'Built-in Command Variables';

  @override
  String get doc_interaction_commands_section_guidance_title =>
      'Authoring Guidance';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'Write conditional logic against commandType or interaction.command.type.';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'Prefer fallback syntax when sharing a template between slash and non-slash commands, and use autocomplete.query inside dedicated autocomplete workflows.';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'Keep templates portable by avoiding event-only names inside command workflows; dynamic autocomplete requires a general workflow ending with respondWithAutocomplete.';

  @override
  String doc_interaction_commands_example(Object id, Object name) {
    return 'Autocomplete workflow:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'$name\' value=\'$id\'';
  }

  @override
  String get doc_event_message_create_title => 'Event: messageCreate';

  @override
  String get doc_event_message_create_subtitle =>
      'Triggered for each newly created message.';

  @override
  String get doc_event_message_create_summary =>
      'Use this event for moderation, keyword pipelines, auto-replies, command-style parsing, and analytics.';

  @override
  String get doc_event_message_create_intent_1 => 'Guild Messages';

  @override
  String get doc_event_message_create_intent_2 => 'Message Content';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'Detect commands typed without slash commands.';

  @override
  String get doc_event_message_create_best_use_l2 =>
      'Apply anti-spam filters before answering.';

  @override
  String get doc_event_message_create_best_use_l3 =>
      'Route to reusable workflows based on first word or mention.';

  @override
  String get doc_event_message_create_notes_l1 =>
      'If Message Content intent is off, content-dependent conditions can fail.';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index] is word-based and capped by runtime extraction.';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBot can help avoid bot loops.';

  @override
  String get doc_event_message_create_example =>
      'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nThen: runWorkflow -> ticket_manager entry=create';

  @override
  String get doc_runtime_execution_flow_title => 'Runtime Execution Flow';

  @override
  String get doc_runtime_execution_flow_subtitle =>
      'How event workflows are selected and executed.';

  @override
  String get doc_runtime_execution_flow_summary =>
      'When an event arrives, runtime matches configured workflows by eventTrigger.event then executes actions with context variables.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'Pipeline';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) Receive gateway event.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) Build context variables map.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) Match workflows by event name.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) Merge global variables.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) Execute actions sequentially with conditions.';

  @override
  String get doc_runtime_execution_flow_section_parity_title => 'Parity Rule';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      'Variables should be identical between local app runtime and runner runtime.';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      'Use same variable names in conditions to stay portable.';

  @override
  String get template_gallery_title => 'Templates';

  @override
  String get template_gallery_subtitle =>
      'Quick-start your bot with a ready-made template.';

  @override
  String get template_gallery_apply => 'Use this template';

  @override
  String template_gallery_apply_success(String count, String wCount) {
    return '$count command(s) and $wCount workflow(s) added from template.';
  }

  @override
  String template_gallery_apply_error(String error) {
    return 'Failed to apply template: $error';
  }

  @override
  String template_gallery_commands_count(String count) {
    return '$count command(s)';
  }

  @override
  String template_gallery_workflows_count(String count) {
    return '$count workflow(s)';
  }

  @override
  String get template_gallery_empty => 'No templates available.';

  @override
  String template_gallery_already_exists(String name) {
    return 'Command \"$name\" already exists and was skipped.';
  }

  @override
  String get template_gallery_sync_warning =>
      'Commands saved locally. Start your bot to register them on Discord.';

  @override
  String get template_welcome_name => 'Welcome Bot';

  @override
  String get template_welcome_description =>
      'Greet new members, say hello, and show server info.';

  @override
  String get template_moderation_name => 'Moderation Bot';

  @override
  String get template_moderation_description =>
      'Ban, kick, mute members and clear messages.';

  @override
  String get template_utility_name => 'Utility Bot';

  @override
  String get template_utility_description =>
      'Ping, avatar lookup, and bot-says commands.';

  @override
  String get template_fun_name => 'Fun Bot';

  @override
  String get template_fun_description => 'Coin flip, polls, and magic 8-ball.';

  @override
  String get dashboard_title => 'Dashboard';

  @override
  String get dashboard_no_data =>
      'No command usage data yet. Run your bot to start tracking.';

  @override
  String get dashboard_total => 'Total commands';

  @override
  String get dashboard_period_24h => 'Last 24h';

  @override
  String get dashboard_period_7d => 'Last 7 days';

  @override
  String get dashboard_period_30d => 'Last 30 days';

  @override
  String get dashboard_top_commands => 'Top commands';

  @override
  String get dashboard_top_locales => 'Top locales';

  @override
  String get dashboard_execution_health_title => 'Execution health';

  @override
  String get dashboard_failed_commands => 'Failed';

  @override
  String get dashboard_error_rate => 'Error rate';

  @override
  String get dashboard_p50_latency => 'Latency p50';

  @override
  String get dashboard_p95_latency => 'Latency p95';

  @override
  String get dashboard_premium_analytics_title => 'Premium analytics';

  @override
  String get dashboard_premium_analytics_desc =>
      'Unlock error rate, latency percentiles, and locale insights.';

  @override
  String get dashboard_timeline => 'Usage over time';

  @override
  String dashboard_executions(String count) {
    return '$count executions';
  }

  @override
  String dashboard_selected_period_total(String count) {
    return '$count in selected period';
  }

  @override
  String get dashboard_loading => 'Loading stats...';

  @override
  String dashboard_error(String error) {
    return 'Could not load stats: $error';
  }

  @override
  String get dashboard_refresh_sources_tooltip => 'Refresh execution servers';

  @override
  String get dashboard_requires_runner =>
      'Connect to a runner to see command usage stats.';

  @override
  String get dashboard_single_runner_notice =>
      'Stats shown are from the currently configured runner only. If you run bots on multiple runners, this view may be incomplete.';

  @override
  String runner_source_label(String name) {
    return 'Runner: $name';
  }

  @override
  String get runner_source_local => 'Local';

  @override
  String get runner_source_all => 'All runners';

  @override
  String get runner_select_source => 'Select runner';

  @override
  String logs_runner_source(String name) {
    return 'Logs from: $name';
  }

  @override
  String get settings_version_title => 'Version';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String get settings_runner_not_connected => 'Not connected';

  @override
  String get premium_card_title => 'Remove Ads';

  @override
  String get premium_card_desc =>
      'Subscribe to remove all ads and start your bots instantly, without any popup.';

  @override
  String get premium_card_button => 'See plans';

  @override
  String get premium_active_title => 'Premium active';

  @override
  String get premium_active_desc =>
      'Thank you for your support! All ads are disabled.';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_subtitle =>
      'Choose a plan to unlock all premium features.';

  @override
  String get subscription_plan_label => 'Premium Basic';

  @override
  String get subscription_plan_desc =>
      'Remove ads and get access to all current and upcoming premium features.';

  @override
  String get subscription_success =>
      'Welcome to Premium! All ads have been removed.';

  @override
  String get subscription_manage => 'Manage subscription';

  @override
  String get subscription_active_label => 'Active plan:';

  @override
  String get subscription_active_annual => 'Premium — Annual';

  @override
  String get subscription_active_monthly => 'Premium — Monthly';

  @override
  String get subscription_benefit_no_ads => 'No ads anywhere in the app';

  @override
  String get subscription_benefit_fast_start =>
      'Bots start instantly, no popup';

  @override
  String get subscription_benefit_support => 'Support independent development';

  @override
  String get subscription_feature_coming_soon => 'Coming soon';

  @override
  String get subscription_feature_no_ads_title => 'No ads';

  @override
  String get subscription_feature_no_ads_desc =>
      'Remove all ad placements across the app experience.';

  @override
  String get subscription_feature_instant_start_title => 'Instant start';

  @override
  String get subscription_feature_instant_start_desc =>
      'Start bots immediately without rewarded ad interruption.';

  @override
  String get subscription_feature_analytics_title => 'Advanced analytics';

  @override
  String get subscription_feature_analytics_desc =>
      'Access error rate, latency percentiles, and locale insights.';

  @override
  String get subscription_feature_scheduler_title => 'Scheduler triggers';

  @override
  String get subscription_feature_scheduler_desc =>
      'Run workflows automatically every X minutes (up to 10 active).';

  @override
  String get subscription_feature_webhooks_title => 'Inbound webhooks';

  @override
  String get subscription_feature_webhooks_desc =>
      'Create secure webhook endpoints and route calls to workflows.';

  @override
  String get subscription_feature_debug_replay_title => 'Visual debug replay';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Record and replay command actions step by step for debugging.';

  @override
  String get subscription_feature_auto_sharding_title => 'Automatic sharding';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Scale large bots by distributing load across shard workers.';

  @override
  String get subscription_feature_auto_restart_title => 'Automatic restart';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Restart the bot automatically when a full restart is required.';

  @override
  String get subscription_annual_title => 'Annual';

  @override
  String get subscription_monthly_title => 'Monthly';

  @override
  String get subscription_per_year => 'per year';

  @override
  String get subscription_per_month => 'per month';

  @override
  String get subscription_save_badge => 'SAVE 67%';

  @override
  String get subscription_restore => 'Restore purchases';

  @override
  String get subscription_terms => 'Terms of use';

  @override
  String get subscription_privacy => 'Privacy policy';

  @override
  String get subscription_error =>
      'Purchase could not be completed. Please try again.';

  @override
  String get subscription_error_store_unavailable =>
      'The App Store is currently unavailable. Please try again in a moment.';

  @override
  String get subscription_error_product_unavailable =>
      'This plan is currently unavailable. Please try again later.';

  @override
  String get subscription_error_purchase_start_failed =>
      'Purchase could not be started. Please try again.';

  @override
  String get subscription_restored => 'Subscription restored successfully!';

  @override
  String get subscription_restore_not_found => 'No active subscription found.';

  @override
  String get subscription_not_available_on_platform =>
      'Subscriptions are currently available on mobile only.';

  @override
  String get subscription_unavailable_platform =>
      'Not available on this platform.';

  @override
  String get action_name_addThreadMember => 'Add Thread Member';

  @override
  String get action_name_removeThreadMember => 'Remove Thread Member';

  @override
  String get template_gallery_remove_title => 'Remove Template';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Nothing to remove for $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Are you sure you want to remove all commands and workflows from this template?';

  @override
  String get template_gallery_removed =>
      'Template commands and workflows removed.';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_ok => 'OK';

  @override
  String get common_save => 'Save';

  @override
  String get common_remove => 'Remove';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_apply => 'Apply';

  @override
  String get common_close => 'Close';

  @override
  String get common_back => 'Back';

  @override
  String get common_next => 'Next';

  @override
  String get common_enabled => 'Enabled';

  @override
  String get common_import => 'Import';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_move_up => 'Move up';

  @override
  String get common_move_down => 'Move down';

  @override
  String get common_name => 'Name';

  @override
  String get common_value => 'Value';

  @override
  String get common_key => 'Key';

  @override
  String get common_type => 'Type';

  @override
  String get common_required => 'Required';

  @override
  String get common_description => 'Description';

  @override
  String get common_default => 'Default';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_all => 'All';

  @override
  String get common_pick => 'Pick';

  @override
  String get common_add_argument => 'Add Argument';

  @override
  String get common_add_option => 'Add Option';

  @override
  String get common_refresh => 'Refresh';

  @override
  String get common_refresh_workflows => 'Refresh workflows';

  @override
  String get common_search => 'Search';

  @override
  String get common_workflow => 'Workflow';

  @override
  String get common_static_options => 'Static Options';

  @override
  String get common_manage_workflows => 'Manage Workflows';

  @override
  String get doc_event_reaction_add_title => 'Event: messageReactionAdd';

  @override
  String get doc_event_reaction_add_subtitle =>
      'Triggered when a user adds a reaction to a message.';

  @override
  String get doc_event_reaction_add_summary =>
      'Ideal for button-like UX without components, vote systems, role menus, and lightweight approvals.';

  @override
  String get doc_event_reaction_add_intent => 'Guild Message Reactions';

  @override
  String get doc_event_reaction_add_best_use_l1 =>
      'Approve/reject flows with unicode emoji.';

  @override
  String get doc_event_reaction_add_best_use_l2 =>
      'Multi-step polls using custom emoji IDs.';

  @override
  String get doc_event_reaction_add_best_use_l3 =>
      'Quick moderation signals from staff channels.';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.id can be empty for unicode emoji.';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      'Use reaction.emoji.name for generic matching.';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      'Use reaction.emoji.id for strict custom emoji matching.';

  @override
  String get doc_event_reaction_add_example =>
      'Guard: ((reaction.emoji.name)) equals ✅\nAction: addRole -> user=((userId)) role=((global.approvedRoleId))';

  @override
  String get doc_event_poll_vote_add_title => 'Event: messagePollVoteAdd';

  @override
  String get doc_event_poll_vote_add_subtitle =>
      'Triggered when a user votes on a poll answer.';

  @override
  String get doc_event_poll_vote_add_summary =>
      'Useful for score tracking, role assignment by poll option, and survey processing.';

  @override
  String get doc_event_poll_vote_add_intent => 'Guild Messages';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      'Map each answer id to a different action branch.';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'Track poll participation per channel or user group.';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.id is the most stable key for routing.';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.question is optional and may be empty depending on payload.';

  @override
  String get doc_event_voice_state_update_title => 'Event: voiceStateUpdate';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'Triggered when voice state changes for a user.';

  @override
  String get doc_event_voice_state_update_summary =>
      'Use this for auto-moderation in voice channels, attendance checks, and voice automation.';

  @override
  String get doc_event_voice_state_update_intent => 'Guilds';

  @override
  String get doc_event_voice_state_update_section_title =>
      'Typical Automations';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      'Detect self-mute/self-deafen policy violations.';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'Trigger welcome message on voice join for support channels.';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'Log leave/join patterns using channel changes.';

  @override
  String get doc_event_user_update_title => 'Event: userUpdate';

  @override
  String get doc_event_user_update_subtitle =>
      'Triggered when user profile data changes.';

  @override
  String get doc_event_user_update_summary =>
      'Useful for profile-change auditing and username/avatar-driven triggers.';

  @override
  String get doc_event_user_update_notes_l1 =>
      'No channel context for this event in most cases.';

  @override
  String get doc_event_user_update_notes_l2 =>
      'Prefer logging + moderation alerts over direct user-facing replies.';

  @override
  String get doc_event_audit_log_create_title => 'Event: guildAuditLogCreate';

  @override
  String get doc_event_audit_log_create_subtitle =>
      'Triggered when a new audit log entry is created.';

  @override
  String get doc_event_audit_log_create_summary =>
      'High-value event for administrative security monitoring.';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      'Alert staff on sensitive actions (role delete, webhook create, ban, etc.).';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      'Route specific action types to dedicated workflows.';

  @override
  String get doc_action_stop_unless_title => 'Action: stopUnless';

  @override
  String get doc_action_stop_unless_subtitle =>
      'Guard clause that stops workflow when condition fails.';

  @override
  String get doc_action_stop_unless_summary =>
      'Use it at the top of workflows to prevent unnecessary actions when context does not match.';

  @override
  String get doc_action_stop_unless_section_operators => 'Supported Operators';

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
      'Condition Variable Format';

  @override
  String get doc_action_stop_unless_format_l1 =>
      'You can use raw keys: message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'You can use wrapped variables: ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 =>
      'Both are resolved by runtime.';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅';

  @override
  String get doc_action_if_block_title => 'Action: ifBlock';

  @override
  String get doc_action_if_block_subtitle =>
      'Branch execution between THEN, ELSE IF and ELSE nested action lists.';

  @override
  String get doc_action_if_block_summary =>
      'Use this to keep a single workflow while handling several outcomes based on runtime state.';

  @override
  String get doc_action_if_block_section_execution => 'Execution Model';

  @override
  String get doc_action_if_block_execution_l1 => 'Condition is evaluated once.';

  @override
  String get doc_action_if_block_execution_l2 =>
      'The first matching branch executes: THEN, then ELSE IF blocks in order, then ELSE.';

  @override
  String get doc_action_if_block_execution_l3 =>
      'Nested actions can include runWorkflow, API calls, and interaction replies.';

  @override
  String get doc_action_run_workflow_title => 'Action: runWorkflow';

  @override
  String get doc_action_run_workflow_subtitle =>
      'Calls another workflow with entry point and arguments.';

  @override
  String get doc_action_run_workflow_summary =>
      'Core composition primitive to split business logic into reusable units.';

  @override
  String get doc_action_run_workflow_section_practices => 'Best Practices';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'Keep top-level workflow thin and delegate to domain workflows.';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      'Pass explicit arguments instead of relying on implicit globals.';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'Use entry points to model sub-routines (create, close, assign, escalate).';

  @override
  String get doc_action_http_request_title => 'Action: httpRequest';

  @override
  String get doc_action_http_request_subtitle =>
      'Executes an external HTTP call inside a workflow.';

  @override
  String get doc_action_http_request_summary =>
      'Use this for webhooks, internal APIs, moderation services, AI endpoints, and integrations.';

  @override
  String get doc_action_http_request_section_checklist =>
      'Reliability Checklist';

  @override
  String get doc_action_http_request_checklist_l1 =>
      'Set explicit timeout and retries in your service layer when possible.';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'Store API keys in globals or secure backend, never hardcode tokens.';

  @override
  String get doc_action_http_request_checklist_l3 =>
      'Validate status code and response body before next actions.';

  @override
  String get embed_color_picker_title => 'Pick embed color';

  @override
  String get embed_delete_title => 'Delete embed';

  @override
  String get embed_delete_confirm => 'This embed will be removed. Continue?';

  @override
  String get embed_field_delete_title => 'Delete field';

  @override
  String get embed_field_delete_confirm =>
      'This field will be removed from the embed. Continue?';

  @override
  String embed_response_header(int count, int max) {
    return 'Response Embeds ($count/$max)';
  }

  @override
  String get embed_add_tooltip => 'Add embed';

  @override
  String embed_empty_message(int max) {
    return 'No embeds. You can add up to $max embeds.';
  }

  @override
  String embed_number(int index) {
    return 'Embed #$index';
  }

  @override
  String get embed_label_title => 'Title';

  @override
  String get embed_label_url => 'URL';

  @override
  String get embed_label_timestamp => 'Timestamp (ISO8601)';

  @override
  String get embed_label_color => 'Color (int or #hex)';

  @override
  String get embed_section_footer => 'Footer';

  @override
  String get embed_label_footer_text => 'Footer Text';

  @override
  String get embed_label_footer_icon => 'Footer Icon URL';

  @override
  String get embed_section_author => 'Author';

  @override
  String get embed_label_author_name => 'Author Name';

  @override
  String get embed_label_author_url => 'Author URL';

  @override
  String get embed_label_author_icon => 'Author Icon URL';

  @override
  String get embed_section_media => 'Media';

  @override
  String get embed_label_image_url => 'Image URL';

  @override
  String get embed_label_thumbnail_url => 'Thumbnail URL';

  @override
  String embed_fields_header(int count) {
    return 'Fields ($count/25)';
  }

  @override
  String get embed_fields_empty => 'No fields yet.';

  @override
  String embed_field_number(int index) {
    return 'Field #$index';
  }

  @override
  String get embed_label_inline => 'Inline';

  @override
  String get embed_label_dynamic_fields => 'Dynamic Fields Template';

  @override
  String get component_remove_title => 'Remove component';

  @override
  String get component_remove_confirm =>
      'This component will be removed from the layout. Continue?';

  @override
  String get component_label => 'Label';

  @override
  String get component_style => 'Style';

  @override
  String get component_url => 'URL';

  @override
  String get component_custom_id_required => 'Custom ID *';

  @override
  String get component_validation_required => 'Required';

  @override
  String get component_workflow_optional => 'Call Workflow (optional)';

  @override
  String get component_workflow_click_hint =>
      'Saved workflow name to run on click';

  @override
  String get component_workflow_select_hint =>
      'Saved workflow name to run on selection';

  @override
  String get component_custom_id => 'Custom ID';

  @override
  String get component_placeholder => 'Placeholder';

  @override
  String get component_options => 'Options';

  @override
  String get component_markdown_content => 'Markdown Content';

  @override
  String get component_visible_divider => 'Visible Divider Line';

  @override
  String get component_spacing_small => 'Small Spacing';

  @override
  String get component_spacing_large => 'Large Spacing';

  @override
  String get component_section_text_displays => 'Text Displays';

  @override
  String get component_add_text_display => 'Add Text Display';

  @override
  String get component_section_accessory => 'Accessory Node (Optional)';

  @override
  String get component_accent_color => 'Accent Color (Hex, e.g. FF0000)';

  @override
  String get component_pick_accent_color => 'Pick Accent Color';

  @override
  String get component_add_child => 'Add Child Component';

  @override
  String get component_checked_by_default => 'Checked by default';

  @override
  String get component_add_radio_option => 'Add Radio Option';

  @override
  String get component_add_media_item => 'Add Media Item';

  @override
  String get component_not_implemented => 'Editor not implemented yet';

  @override
  String get component_choose_color => 'Choose Color';

  @override
  String get component_label_title => 'Label Title';

  @override
  String get component_workflow_args_title => 'Workflow Call Arguments';

  @override
  String get component_workflow_args_hint =>
      'Example: ticketId = ((opts.ticket))';

  @override
  String get autocomplete_workflow_label => 'Autocomplete Workflow';

  @override
  String get autocomplete_loading => 'Loading workflows…';

  @override
  String get autocomplete_no_workflows => 'No saved workflows found';

  @override
  String get autocomplete_select_workflow => 'Select a saved workflow';

  @override
  String get autocomplete_type_name => 'Or type workflow name';

  @override
  String get workflow_entry_point => 'Entry Point';

  @override
  String get workflow_arguments_section => 'Workflow Arguments';

  @override
  String get hint_use_variables => 'Use variables/templates if needed';

  @override
  String get autocomplete_dynamic => 'Dynamic Autocomplete';

  @override
  String get autocomplete_dynamic_desc =>
      'Resolve choices from a workflow instead of static values.';

  @override
  String get autocomplete_filter_hint =>
      'Suggestions are filtered by what the user types.';

  @override
  String get option_delete_title => 'Delete option';

  @override
  String get option_delete_confirm => 'This option will be removed. Continue?';

  @override
  String get option_desc_required =>
      'Please enter a description for the option';

  @override
  String get option_delete_argument_title => 'Delete argument';

  @override
  String get option_delete_argument_confirm =>
      'This argument will be removed. Continue?';

  @override
  String option_static_label_n(int index) {
    return 'Label $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Value $index';
  }

  @override
  String get option_delete_choice_title => 'Delete option';

  @override
  String get option_delete_choice_confirm =>
      'This choice will be removed. Continue?';

  @override
  String option_default_name(int index) {
    return 'Option $index';
  }

  @override
  String get option_min_value => 'Min Value';

  @override
  String get option_max_value => 'Max Value';

  @override
  String get option_add_localizations => 'Add Localizations';

  @override
  String get option_select_language => 'Select Language';

  @override
  String get option_delete_localization_title => 'Delete localization';

  @override
  String get option_delete_localization_confirm =>
      'This localization entry will be removed. Continue?';

  @override
  String get option_localized_name => 'Localized Name';

  @override
  String get option_localized_description => 'Localized Description';

  @override
  String option_choice_number(int index) {
    return 'Choice $index';
  }

  @override
  String get option_choice_delete_title => 'Delete choice';

  @override
  String get option_choice_delete_confirm =>
      'This choice will be removed. Continue?';

  @override
  String get option_choice_name => 'Choice Name';

  @override
  String get option_choice_value => 'Choice Value';

  @override
  String get option_add_choice => 'Add Choice';

  @override
  String get option_subcommands => 'SubCommands';

  @override
  String get option_subcommand_options => 'SubCommand Options';

  @override
  String get action_options_tooltip => 'Action options';

  @override
  String get action_remove_menu => 'Remove action';

  @override
  String get action_order_tip => 'Tip: use arrows to change action order.';

  @override
  String get action_key_field => 'Action Key';

  @override
  String get action_on_error => 'On Error';

  @override
  String get action_error_stop => 'Stop';

  @override
  String get action_error_continue => 'Continue';

  @override
  String get action_advanced_settings => 'Advanced settings';

  @override
  String get action_status_enabled => 'Enabled';

  @override
  String get action_status_disabled => 'Disabled';

  @override
  String get action_remove_title => 'Remove action';

  @override
  String get action_remove_confirm =>
      'This action will be removed from the workflow. Continue?';

  @override
  String get action_store_results => 'Store results in global variables';

  @override
  String get action_http_test_button =>
      'Send Test Request & Auto-Detect Routes';

  @override
  String get action_http_test_title => 'Test Request Results';

  @override
  String action_http_status(String status) {
    return 'Status: $status';
  }

  @override
  String action_http_paths_parsed(int count) {
    return '$count paths parsed';
  }

  @override
  String get action_http_response_body => 'Response Body (Raw):';

  @override
  String get action_literal => 'Literal';

  @override
  String get action_dynamic => 'Dynamic';

  @override
  String get action_add_else_if => 'Add ELSE IF';

  @override
  String get action_remove_else_if => 'Remove ELSE IF';

  @override
  String get action_condition_variable => 'Condition Variable';

  @override
  String get action_condition_value => 'Condition Value';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index — actions';
  }

  @override
  String get action_expression => 'Expression';

  @override
  String action_edit_param(String name) {
    return 'Edit $name';
  }

  @override
  String action_choose_param(String name) {
    return 'Choose $name';
  }

  @override
  String get action_format_json => 'Format JSON';

  @override
  String get action_add_header => 'Add header';

  @override
  String get action_clear_all => 'Clear all';

  @override
  String get action_refresh_keys => 'Refresh keys';

  @override
  String get action_manage_variable_keys => 'Manage Variable Keys';

  @override
  String get validation_command_name_required => 'Please enter a command name';

  @override
  String get validation_awaited_callback_local_only =>
      'Awaited callbacks require a local-only Legacy Command.';

  @override
  String validation_awaited_callback_length(int max) {
    return 'Awaited callback trigger must be at most $max characters long';
  }

  @override
  String get validation_awaited_callback_format =>
      'Awaited callback must use \$awaitedCommand[name;filter] or \$awaitedCommandError[name].';

  @override
  String validation_command_name_length(int max) {
    return 'Command name must be at most $max characters long';
  }

  @override
  String get validation_command_name_no_spaces =>
      'Command name cannot contain spaces';

  @override
  String get validation_command_name_invalid_chars =>
      'Command name can only contain letters, numbers, and underscores';

  @override
  String get validation_command_name_no_underscore =>
      'Command name cannot start with an underscore';

  @override
  String get validation_command_name_no_exclamation =>
      'Command name cannot start with an exclamation mark';

  @override
  String get validation_command_name_no_slash =>
      'Command name cannot start with a slash';

  @override
  String get validation_command_name_no_hash =>
      'Command name cannot start with a hash';

  @override
  String get validation_command_name_no_at =>
      'Command name cannot start with an at sign';

  @override
  String get validation_command_name_no_ampersand =>
      'Command name cannot start with an ampersand';

  @override
  String get validation_command_name_no_percent =>
      'Command name cannot start with a percent sign';

  @override
  String get validation_legacy_chat_input_only =>
      'Legacy mode is only available for chat input commands.';

  @override
  String get validation_modal_not_legacy =>
      'Modal responses are not supported in legacy command mode.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Legacy-only commands require legacy mode to be enabled.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Legacy-only mode can only be used for new commands or existing local commands.';

  @override
  String get validation_invalid_permissions =>
      'Invalid default member permissions bitfield. Use a positive integer or leave empty.';

  @override
  String get scheduler_no_workflows =>
      'Create at least one workflow before adding a schedule.';

  @override
  String get scheduler_add_title => 'Add schedule';

  @override
  String get scheduler_edit_title => 'Edit schedule';

  @override
  String get scheduler_label_hint => 'Optional display label';

  @override
  String get scheduler_label_field => 'Label';

  @override
  String get scheduler_every_minutes => 'Every (minutes)';

  @override
  String get scheduler_invalid_minutes =>
      'Every minutes must be greater than 0.';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Scheduler limit reached ($limit).';
  }

  @override
  String scheduler_save_failed(String error) {
    return 'Failed to save schedule: $error';
  }

  @override
  String get scheduler_delete_title => 'Delete schedule';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Delete \"$label\" schedule?';
  }

  @override
  String get scheduler_page_title => 'Scheduler';

  @override
  String get scheduler_add_trigger => 'Add trigger';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Triggers: $count$limit';
  }

  @override
  String get scheduler_empty => 'No scheduled triggers yet.';

  @override
  String get webhooks_no_workflows =>
      'Create at least one workflow before adding an inbound webhook.';

  @override
  String get webhooks_add_title => 'Add inbound webhook';

  @override
  String get webhooks_edit_title => 'Edit inbound webhook';

  @override
  String get webhooks_path_label => 'Path';

  @override
  String get webhooks_path_hint => 'orders/new';

  @override
  String get webhooks_target_label => 'Workflow target';

  @override
  String get webhooks_secret_label => 'Webhook secret';

  @override
  String get webhooks_generate => 'Generate';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Inbound webhook limit reached ($limit).';
  }

  @override
  String get webhooks_path_exists =>
      'This path already exists. Choose another one.';

  @override
  String webhooks_save_failed(String error) {
    return 'Failed to save inbound webhook: $error';
  }

  @override
  String get webhooks_delete_title => 'Delete inbound webhook?';

  @override
  String webhooks_delete_confirm(String label) {
    return 'Delete \"$label\"? This cannot be undone.';
  }

  @override
  String get webhooks_delete_confirm_no_label => 'This cannot be undone.';

  @override
  String get webhooks_runner_url_required =>
      'Configure a Runner URL first to copy the full webhook URL.';

  @override
  String get webhooks_missing_data => 'Webhook path or secret is missing.';

  @override
  String get webhooks_copied => 'Full webhook URL copied.';

  @override
  String get webhooks_invalid_runner_url => 'Runner URL is invalid.';

  @override
  String get webhooks_page_title => 'Inbound Webhooks';

  @override
  String get webhooks_add_action => 'Add webhook';

  @override
  String get webhooks_empty => 'No inbound webhooks yet.';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Workflow: $workflow';
  }

  @override
  String get webhooks_copy_url => 'Copy URL';

  @override
  String get webhooks_copy_path => 'Copy path';

  @override
  String get webhooks_copy_secret => 'Copy secret';

  @override
  String get webhooks_actions => 'Actions';

  @override
  String get command_legacy_mode_title => 'Enable legacy mode on this command';

  @override
  String get command_legacy_mode_subtitle =>
      'Uses positional options (example: !config #channel).';

  @override
  String get command_legacy_prefix_title => 'Legacy Prefix Mode';

  @override
  String get command_legacy_prefix_desc =>
      'Handle commands from messageCreate using <prefix><command>.';

  @override
  String get command_prefix_override_label => 'Prefix override (optional)';

  @override
  String get command_prefix_override_hint =>
      'Example: ? or ((guild.prefix | !))';

  @override
  String get command_legacy_response_label => 'Legacy response mode';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_modal_disabled_legacy =>
      'Modals are disabled in legacy mode.';

  @override
  String get command_target_subcommand => 'Target subcommand';

  @override
  String get command_unsaved_title => 'Unsaved changes';

  @override
  String get command_unsaved_confirm =>
      'You have unsaved changes. Discard them?';

  @override
  String get command_unsaved_keep => 'Keep editing';

  @override
  String get command_error_missing_bot_id =>
      'Missing bot id for local command save.';

  @override
  String get command_import_tooltip => 'Import command payload';

  @override
  String get command_export_tooltip => 'Export command payload';

  @override
  String get actions_missing_field_title => 'Missing Required Field';

  @override
  String get actions_no_matches => 'No actions match your search.';

  @override
  String get actions_add_new_title => 'Add New Action';

  @override
  String get actions_search_hint => 'Search actions...';

  @override
  String get actions_add_label => 'Add Action';

  @override
  String get actions_builder_title => 'Actions Builder';

  @override
  String get actions_save_tooltip => 'Save Actions';

  @override
  String actions_key_label(String key) {
    return 'Key: $key';
  }

  @override
  String get modal_remove_field_title => 'Remove modal field';

  @override
  String get modal_remove_field_confirm =>
      'This field will be removed from the modal. Continue?';

  @override
  String get modal_title_label => 'Modal Title';

  @override
  String get modal_custom_id_label => 'Custom ID';

  @override
  String get modal_custom_id_hint => 'Used to identify this modal';

  @override
  String get modal_workflow_submit => 'Workflow to run on submit (optional)';

  @override
  String get modal_add_text_input => 'Add Text Input';

  @override
  String modal_field_default_label(int index) {
    return 'Field $index';
  }

  @override
  String get modal_style => 'Style:';

  @override
  String get modal_default_value => 'Default value';

  @override
  String get command_legacy_preset_title => 'Legacy preset';

  @override
  String get command_legacy_preset_desc =>
      'Generate an internal awaited callback trigger and switch this command to the required local legacy setup.';

  @override
  String get command_awaited_preset_button => 'Use Awaited Callback Preset';

  @override
  String get command_awaited_preset_active => 'Awaited callback preset';

  @override
  String get command_edit_raw_name => 'Edit Raw Name';

  @override
  String get command_awaited_preset_desc =>
      'The command name is generated for you and saved as an internal legacy callback.';

  @override
  String get command_awaited_success => 'Success';

  @override
  String get command_awaited_error => 'Error';

  @override
  String get command_awaited_name_label => 'Awaited callback name';

  @override
  String get command_awaited_name_hint => 'Example: say';

  @override
  String get command_awaited_filter_label => 'Filter (optional)';

  @override
  String get command_awaited_filter_hint =>
      'Example: <numeric> or <yes/no/cancel>';

  @override
  String get command_info_title => 'Command Info';

  @override
  String get command_info_desc => 'Basic metadata and availability';

  @override
  String get command_name_label => 'Name';

  @override
  String get command_name_generated =>
      'Generated by the awaited callback preset.';

  @override
  String get command_type_label => 'Command Type';

  @override
  String get command_type_slash => 'Slash Command';

  @override
  String get command_type_legacy => 'Legacy Command';

  @override
  String get command_type_user => 'User Command';

  @override
  String get command_type_message => 'Message Command';

  @override
  String get command_integration_guild => 'Guild Install';

  @override
  String get command_integration_user => 'User Install';

  @override
  String get command_context_guild => 'Guild';

  @override
  String get command_context_bot_dm => 'Bot DM';

  @override
  String get command_context_group_dm => 'Group DM / Other';

  @override
  String get command_permissions_title => 'Select permissions';

  @override
  String get command_prefix_helper =>
      'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))';

  @override
  String get actions_title => 'Actions';

  @override
  String get actions_description => 'Build runtime actions for this command';

  @override
  String actions_active_route(String label) {
    return 'Active route: $label';
  }

  @override
  String actions_build_button(int count) {
    return 'Build Actions ($count)';
  }

  @override
  String get actions_save_workflow_title => 'Save as Workflow';

  @override
  String get actions_workflow_name_label => 'Workflow name';

  @override
  String get actions_global_variables => 'Global Variables';

  @override
  String get actions_workflows => 'Workflows';

  @override
  String get wizard_quick_start_applied =>
      'Quick start applied to the command draft.';

  @override
  String get wizard_advanced_trigger => 'Advanced trigger settings';

  @override
  String get wizard_edit_reply => 'Edit reply details';

  @override
  String get wizard_quick_starts => 'Quick starts';

  @override
  String get wizard_apply_quick_start => 'Apply quick start to draft';

  @override
  String get wizard_code_advanced => 'Code / Advanced';

  @override
  String get serialization_export_json_title => 'Export command as JSON';

  @override
  String get serialization_export_json_subtitle =>
      'Copy readable JSON to clipboard';

  @override
  String get serialization_export_base64_title => 'Export command as Base64';

  @override
  String get serialization_import_title => 'Import command';

  @override
  String get serialization_import_desc =>
      'Paste a command payload (JSON or Base64).';

  @override
  String get serialization_invalid_format => 'Invalid command payload format.';

  @override
  String get serialization_invalid_structure =>
      'Invalid command payload structure.';

  @override
  String get serialization_imported => 'Command imported into editor.';

  @override
  String get response_workflow_title => 'Response Workflow';

  @override
  String get response_workflow_auto_defer => 'Auto defer if actions exist';

  @override
  String get response_workflow_public => 'Public';

  @override
  String get response_workflow_error_policy => 'Error policy';

  @override
  String get response_workflow_enable_condition => 'Enable condition';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_mode_component => 'Component';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_revert_tooltip => 'Revert all changes';

  @override
  String get response_workflow_then_text => 'THEN response text (optional)';

  @override
  String get response_workflow_else_text => 'ELSE response text (optional)';

  @override
  String get recovery_label => 'Recovery';

  @override
  String get recovery_title => 'Recovery mode';

  @override
  String get recovery_retry_discord => 'Retry Discord connection';

  @override
  String get recovery_delete_bot => 'Delete bot locally';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get reply_configure_workflow => 'Configure Response Workflow';

  @override
  String get reply_buttons_optional => 'Buttons & Select Menus (optional)';

  @override
  String get reply_mode_standard => 'Standard Message';

  @override
  String get reply_mode_layout => 'Layout Mode';

  @override
  String get reply_mode_modal => 'Modal Form';

  @override
  String get emojis_rename_tooltip => 'Rename';

  @override
  String get emojis_delete_tooltip => 'Delete';

  @override
  String get component_remove_row_title => 'Remove action row';

  @override
  String get component_add_tooltip => 'Add Component';

  @override
  String get component_add_root => 'Add Root Component';

  @override
  String get edit_shell_save_changes => 'Save changes';

  @override
  String get edit_shell_all_saved => 'All changes saved';

  @override
  String get edit_shell_local_only => 'Local-only';

  @override
  String get edit_shell_local_draft => 'Local draft';

  @override
  String get edit_shell_unsaved => 'Unsaved changes';

  @override
  String get edit_shell_untitled_command => 'Untitled command';

  @override
  String get edit_shell_subtitle =>
      'Settings and inputs are at the top. Actions and reply follow below.';

  @override
  String edit_shell_routes_count(int count) {
    return '$count route(s)';
  }

  @override
  String get edit_shell_command_settings => 'Command settings';

  @override
  String get edit_shell_command_settings_desc =>
      'Metadata, availability, permissions, and folder placement.';

  @override
  String get edit_shell_trigger_inputs => 'Trigger & Inputs';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Adjust command options, trigger behavior, and execution mode.';

  @override
  String get edit_shell_command_body => 'Command body';

  @override
  String get edit_shell_type_legacy => 'Legacy command';

  @override
  String get edit_shell_type_user => 'User command';

  @override
  String get edit_shell_type_message => 'Message command';

  @override
  String get edit_shell_type_slash => 'Slash command';

  @override
  String get edit_shell_type_command => 'Command';

  @override
  String get wizard_step_infos => 'Infos';

  @override
  String get wizard_step_trigger_inputs => 'Trigger & Inputs';

  @override
  String get wizard_step_reply => 'Reply';

  @override
  String get wizard_step_actions => 'Actions';

  @override
  String get wizard_step_review => 'Review';

  @override
  String get review_info_title => 'Info';

  @override
  String get review_name_untitled => '(untitled)';

  @override
  String review_name_line(String name) {
    return 'Name: $name';
  }

  @override
  String review_type_line(String type) {
    return 'Type: $type';
  }

  @override
  String review_description_line(String desc) {
    return 'Description: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Folder: $folder';
  }

  @override
  String review_options_count(int count) {
    return '$count option(s)';
  }

  @override
  String review_subcommand_routes(int count) {
    return '$count subcommand route(s)';
  }

  @override
  String get review_legacy_mode => 'Legacy mode enabled';

  @override
  String get review_local_only => 'Local-only command';

  @override
  String get review_trigger_inputs_title => 'Trigger & Inputs';

  @override
  String get review_reply_title => 'Reply';

  @override
  String get review_actions_title => 'Actions';

  @override
  String get wizard_save_command => 'Save command';

  @override
  String get wizard_create_command => 'Create command';

  @override
  String get wizard_reply_summary => 'Reply summary';

  @override
  String get wizard_legacy_options_subtitle =>
      'Legacy command options and local-only behavior';

  @override
  String get wizard_quick_start_subtitle =>
      'Use the legacy simple builder as a starting point, then apply it to the shared draft.';

  @override
  String get wizard_bdfd_mode_enabled => 'BDFD script mode enabled';

  @override
  String get wizard_dart_mode_enabled => 'Dart script mode enabled';

  @override
  String get wizard_visual_mode_enabled => 'Visual workflow mode enabled';

  @override
  String get wizard_command_body => 'Command body';

  @override
  String get response_mode_layout => 'Layout mode';

  @override
  String get response_mode_modal => 'Modal form';

  @override
  String get response_mode_standard => 'Standard message';

  @override
  String get response_visibility_ephemeral => 'ephemeral';

  @override
  String get response_visibility_public => 'public';

  @override
  String response_embeds_count(int count) {
    return '$count embed(s)';
  }

  @override
  String get response_interactive_components => 'interactive components';

  @override
  String get command_options_title => 'Command Options';

  @override
  String get command_options_slash_params => 'Slash-command parameters';

  @override
  String get command_options_legacy_params =>
      'Legacy positional parameters (ordered: required then optional)';

  @override
  String get legacy_prefix_mode_title => 'Legacy Prefix Mode';

  @override
  String get legacy_prefix_mode_desc =>
      'Handle commands from messageCreate using <prefix><command>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Uses positional options (example: !config #channel).';

  @override
  String get legacy_prefix_override_label => 'Prefix override (optional)';

  @override
  String get legacy_prefix_override_hint =>
      'Example: ? or ((guild.prefix | !))';

  @override
  String get legacy_response_mode_label => 'Legacy response mode';

  @override
  String get command_type_locked =>
      'Command type cannot be changed after creation.';

  @override
  String get local_command_title =>
      'Local Command (Do not register on Discord)';

  @override
  String get local_command_desc =>
      'Store command only in Bot Creator. You can dynamically register it on Specific Guilds using BDFD \$registerGuildCommands.';

  @override
  String get local_command_awaited_desc =>
      'Awaited callback presets stay local because they are internal runtime callbacks.';

  @override
  String get command_integration_label => 'Where this command can be used';

  @override
  String get command_scope_label => 'Scope of the command (Contexts)';

  @override
  String get command_permissions_label =>
      'Default Member Permissions (optional)';

  @override
  String get command_permissions_none =>
      'No selection (everyone can use command)';

  @override
  String command_permissions_count(int count) {
    return '$count permission(s) selected';
  }

  @override
  String get command_permissions_bitfield => 'Calculated Permission Bitfield';

  @override
  String get command_permissions_bitfield_helper =>
      'Automatically computed from selected permissions.';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Warning: unknown permission bits detected from saved data and preserved: $bits';
  }

  @override
  String get command_permissions_admin_warning =>
      'Administrator selected: this bypasses other permission checks.';

  @override
  String get command_permissions_tip =>
      'Tip: leave all unchecked to make the command available to everyone by default.';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" saved ($count action(s)).';
  }

  @override
  String get reply_command_reply_title => 'Command Reply';

  @override
  String get reply_choose_type => 'Choose the type of response to send';

  @override
  String get reply_mode_standard_desc =>
      'Text, embeds and optional buttons / select menus';

  @override
  String get reply_mode_layout_desc =>
      'Discord\'s rich layout system — containers, media, text & forms';

  @override
  String get reply_mode_modal_desc => 'Pop-up dialog with text input fields';

  @override
  String get reply_response_workflow => 'Response Workflow';

  @override
  String get reply_response_text_label => 'Response Text';

  @override
  String get reply_response_text_helper =>
      'Used as slash-command reply text. Supports ((variable)) syntax.';

  @override
  String get reply_buttons_desc =>
      'Add interactive buttons or dropdowns to this message';

  @override
  String reply_active_route(String label) {
    return 'Active route: $label';
  }

  @override
  String get workflow_visibility_ephemeral => 'Ephemeral';

  @override
  String get workflow_visibility_public => 'Public';

  @override
  String get workflow_auto_defer => 'Auto defer';

  @override
  String get workflow_manual => 'Manual';

  @override
  String get workflow_condition_on => 'Condition on';

  @override
  String get workflow_condition_off => 'Condition off';

  @override
  String get workflow_auto_defer_actions => 'Auto defer if actions';

  @override
  String get workflow_no_auto_defer => 'No auto defer';

  @override
  String get workflow_condition_on_upper => 'Condition ON';

  @override
  String get workflow_condition_off_upper => 'Condition OFF';

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'BDFD script | $lines line(s) | $diagnostics diagnostic(s)';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Dart script | $lines line(s) | $diagnostics diagnostic(s)';
  }

  @override
  String get scratch_dart_script => 'Dart Script';

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count action(s) on active route | $routes route(s)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count action(s) configured';
  }

  @override
  String get reply_editor_title => 'Reply Details';

  @override
  String get bdfd_editor_ux_title => 'Editor UX';

  @override
  String get bdfd_editor_includes => 'Includes:';

  @override
  String get bdfd_editor_auto_indent => '• Smart auto indentation on Enter';

  @override
  String get bdfd_editor_indent_guides => '• Live indentation guides';

  @override
  String get bdfd_editor_quick_keys => '• Mobile quick-keys for BDFD symbols';

  @override
  String get bdfd_editor_toggle_indent => 'Toggle indentation guides';

  @override
  String get startup_error_title => 'Startup Error';

  @override
  String get startup_failed_message =>
      'Bot Creator failed to start on this device.';

  @override
  String get startup_copy_diagnostics => 'Copy diagnostics';

  @override
  String get startup_refresh_diagnostics => 'Refresh diagnostics';

  @override
  String get startup_diagnostics_copied => 'Diagnostics copied to clipboard';

  @override
  String export_failed(String error) {
    return 'Export failed: $error';
  }

  @override
  String import_parse_failed(String error) {
    return 'Failed to parse ZIP: $error';
  }

  @override
  String get import_nothing => 'Nothing imported.';

  @override
  String import_failed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get workflows_no_match => 'No workflows match the current filters.';

  @override
  String get settings_run_diagnostics => 'Run Diagnostics';

  @override
  String get settings_open_ad_inspector => 'Open Ad Inspector';

  @override
  String get settings_builtin_help => 'Built-in legacy !help command';

  @override
  String get drive_manual_backup => 'Manual backup';

  @override
  String get drive_legacy_snapshot => 'Legacy snapshot';

  @override
  String get commands_filter_template => 'Template';

  @override
  String get commands_filter_legacy_local => 'Legacy local';

  @override
  String get workflows_no_matches => 'No workflows match the current filters.';

  @override
  String get common_disabled => 'Disabled';

  @override
  String get common_label => 'Label';

  @override
  String get common_custom_id => 'Custom ID';

  @override
  String get common_custom_id_required => 'Custom ID *';

  @override
  String get common_placeholder => 'Placeholder';

  @override
  String get common_style => 'Style';

  @override
  String get common_url => 'URL';

  @override
  String get common_operator => 'Operator';

  @override
  String get component_on_click_workflow => 'On click, the workflow';

  @override
  String get component_on_select_workflow => 'On select, the workflow';

  @override
  String get component_new_option => 'New Option';

  @override
  String get component_component_to_wrap => 'Component to Wrap:';

  @override
  String get component_radio_options => 'Radio Options';

  @override
  String get component_checkbox_options => 'Checkbox Options';

  @override
  String get component_add_checkbox_option => 'Add Checkbox Option';

  @override
  String get component_new_radio => 'New Radio';

  @override
  String get component_new_checkbox => 'New Checkbox';

  @override
  String get component_file_url => 'File URL';

  @override
  String get component_thumbnail_url => 'Thumbnail URL';

  @override
  String get component_media_url => 'Image / Video URL';

  @override
  String get component_media_urls => 'Media URLs';

  @override
  String get workflow_entry_point_optional => 'Entry Point (optional)';

  @override
  String get workflow_entry_point_helper =>
      'Defaults to workflow entry point when empty';

  @override
  String get workflow_set_call_args => 'Set Call Arguments';

  @override
  String workflow_edit_call_args(int count) {
    return 'Edit Call Arguments ($count)';
  }

  @override
  String get workflow_root_json_error => 'Root must be a JSON object';

  @override
  String workflow_on_submit_info(String name, String entry, String args) {
    return 'On submit, workflow \"$name\" will run (entry: $entry, args: $args).';
  }

  @override
  String get workflow_no_workflow_note =>
      'Note: If no workflow is selected, submitting this modal will do nothing.';

  @override
  String get workflow_hint_name => 'e.g. handle_form_submit';

  @override
  String action_position(int index, int total) {
    return 'Action $index/$total';
  }

  @override
  String get action_provide_valid_url => 'Please provide a valid URL.';

  @override
  String get action_hint_duration => 'e.g., 5m, 1h, 30s';

  @override
  String action_hint_enter_type(String type) {
    return 'Enter $type';
  }

  @override
  String get action_hint_emoji => 'Enter emoji or :name:';

  @override
  String get action_hint_color => '#FFFFFF or rgb(255,255,255)';

  @override
  String get action_hint_workflow => 'Saved workflow name';

  @override
  String get action_hint_variable_key => 'Select variable key';

  @override
  String get action_hint_condition_var =>
      'Use ((variableName)) or a runtime value';

  @override
  String get action_hint_condition_value => 'Value to compare against';

  @override
  String get action_add_new_item => 'Add new item';

  @override
  String get action_key_value_pairs => 'Key / Value pairs';

  @override
  String action_edit_nested(int count) {
    return 'Edit $count';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Edit ($count)';
  }

  @override
  String get action_no_items_tap_edit => 'No items - tap edit to add';

  @override
  String get action_no_actions_yet => 'No actions in this branch yet.';

  @override
  String action_and_more(int count) {
    return '… and $count more';
  }

  @override
  String get action_no_else_if_yet =>
      'No ELSE IF branches yet. Add one to test more conditions before ELSE.';

  @override
  String get action_no_headers_tap_edit => 'No headers - tap edit to add';

  @override
  String get action_no_args_tap_edit => 'No arguments - tap edit to add';

  @override
  String get action_no_properties_tap_edit =>
      'No properties - tap edit to configure';

  @override
  String get action_http_headers_title => 'HTTP Headers (Key/Value pairs)';

  @override
  String get action_bulk_import_hint =>
      'Bulk import (Paste headers like Key: Value)';

  @override
  String get action_json_editor_hint =>
      'JSON object editor (supports nested objects/arrays)';

  @override
  String get action_edit_raw_json => 'Edit Raw JSON';

  @override
  String get action_preview_json => 'Preview Highlighted JSON';

  @override
  String get action_cannot_format_json => 'Cannot format: Invalid JSON';

  @override
  String get action_root_must_json => 'Root must be a JSON object';

  @override
  String get action_dynamic_numeric => 'Dynamic numeric suggestions';

  @override
  String get action_dynamic_variable => 'Dynamic variable suggestions';

  @override
  String get action_dynamic_bool_hint => 'true/false or ((variable))';

  @override
  String get action_dynamic_multiselect_hint =>
      'Dynamic value (supports ((...)))';

  @override
  String action_dynamic_id_hint(String type) {
    return 'Dynamic $type (supports ((...)))';
  }

  @override
  String get action_loading_keys => 'Loading keys...';

  @override
  String get action_no_saved_keys =>
      'No saved keys found. Keys are created automatically on first access.';

  @override
  String get action_select_stored_key =>
      'Select a stored key (bc_ prefix is optional)';

  @override
  String get action_select_saved_key => 'Select a saved key';

  @override
  String get action_static_badge => '(static)';

  @override
  String get action_or_type_workflow => 'Or type workflow name';

  @override
  String get modal_builder_title => 'Modal Builder';

  @override
  String modal_inputs_count(int count) {
    return '$count/5 inputs';
  }

  @override
  String modal_input_index(int index) {
    return 'Input $index';
  }

  @override
  String get settings_legacy_prefix => 'Legacy command prefix';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? or ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_helper =>
      'Supports templates and scoped variables (bc_ optional). Example: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_builtin_help_subtitle =>
      'Mandatory feature with explicit toggle. Disable it if you only want custom help behavior.';

  @override
  String get settings_status_remove_confirm =>
      'This status entry will be removed. Continue?';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooks: $count$limit';
  }

  @override
  String get webhooks_path_copied => 'Path copied.';

  @override
  String get webhooks_secret_copied => 'Secret copied.';

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow: $workflow • Every $minutes min';
  }

  @override
  String import_summary_commands_imported(int count) {
    return '$count command(s) imported';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count command(s) skipped';
  }

  @override
  String import_summary_workflows_imported(int count) {
    return '$count workflow(s) imported';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count workflow(s) skipped';
  }

  @override
  String get import_summary_status_imported => 'status imported';

  @override
  String get import_summary_variables_imported => 'variables imported';

  @override
  String get command_subcommand_workflow_title => 'SubCommand Workflow';

  @override
  String get command_subcommand_workflow_desc =>
      'Choose which subcommand you are configuring.';

  @override
  String command_sync_failed_local(String error) {
    return 'Saved locally. Discord sync failed: $error';
  }

  @override
  String get command_description_required =>
      'Please enter a command description';

  @override
  String get command_description_length =>
      'Command description must be at most 100 characters long';

  @override
  String get response_workflow_deferred_reply => 'Deferred reply';

  @override
  String get response_workflow_auto_defer_desc =>
      'Acknowledge quickly, execute actions, then edit final response.';

  @override
  String get response_workflow_visibility => 'Visibility';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Ephemeral (only command user)';

  @override
  String get response_workflow_error_policy_desc =>
      'When an action fails, edit the deferred message with an error.';

  @override
  String get response_workflow_conditional_title =>
      'Conditional response (MVP)';

  @override
  String get response_workflow_condition_desc =>
      'If variable exists and is not empty => use THEN text, otherwise ELSE text.';

  @override
  String get response_workflow_variable_key => 'Variable key (ex: opts.userId)';

  @override
  String get commands_search_hint => 'Search commands...';

  @override
  String get commands_all_folders => 'All folders';

  @override
  String get commands_no_match_filters =>
      'No commands match the current filters.';

  @override
  String get actions_search_sequence_hint =>
      'Search actions in this sequence...';

  @override
  String actions_sequence_count(int count) {
    return '$count action(s) in sequence';
  }

  @override
  String actions_save_count(int count) {
    return 'Save $count Actions';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Step $index/$total';
  }

  @override
  String get option_type_string => 'String';

  @override
  String get option_type_integer => 'Integer';

  @override
  String get option_type_boolean => 'Boolean';

  @override
  String get option_type_user => 'User';

  @override
  String get option_type_channel => 'Channel';

  @override
  String get option_type_role => 'Role';

  @override
  String get option_type_mentionable => 'Mentionable';

  @override
  String get option_type_number => 'Number';

  @override
  String get option_type_attachment => 'Attachment';

  @override
  String get option_type_subcommand => 'SubCommand';

  @override
  String get option_type_subcommand_group => 'SubCommand Group';

  @override
  String get option_type_unknown => 'Unknown';

  @override
  String get option_name_required => 'Please enter a name for the option';

  @override
  String get option_name_max_length =>
      'Option name must be at most 32 characters long';

  @override
  String get option_name_invalid_chars =>
      'Option name can only contain letters, numbers, and underscores';

  @override
  String get option_name_invalid_start =>
      'Option name starts with an unsupported character';

  @override
  String get option_name_duplicate => 'This name is already used at this level';

  @override
  String option_label_number(int index) {
    return 'Label $index';
  }

  @override
  String option_value_number(int index) {
    return 'Value $index';
  }

  @override
  String get validation_option_max_entries =>
      'Each option level supports at most 25 entries.';

  @override
  String get validation_option_no_mix_top_level =>
      'Top-level options cannot mix subcommands/groups with regular options.';

  @override
  String get validation_option_group_only_subcommands =>
      'A SubCommandGroup can only contain SubCommand options.';

  @override
  String get validation_option_subcommand_no_nested =>
      'A SubCommand cannot contain nested SubCommand or SubCommandGroup.';

  @override
  String get validation_option_name_required =>
      'Every option must have a name.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Duplicate option name \"$name\" at the same level.';
  }

  @override
  String get validation_option_description_required =>
      'Every option must have a description.';

  @override
  String get validation_option_leaf_no_nested =>
      'Regular options cannot contain nested options.';

  @override
  String get validation_option_hierarchy_not_required =>
      'SubCommand and SubCommandGroup cannot be marked as required.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'SubCommand and SubCommandGroup cannot define choices.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'SubCommand and SubCommandGroup cannot define min/max values.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup is only allowed at the top level.';

  @override
  String get validation_option_subcommand_depth =>
      'SubCommand nesting depth exceeds Discord limits.';

  @override
  String get bdfd_compile_error_simple =>
      'This BDFD script could not be compiled.';

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'This BDFD script could not be compiled:\n$summary';
  }

  @override
  String get command_not_found => 'Command not found';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'Failed to run BDFD script for command \"$command\": $error';
  }

  @override
  String get component_empty_option => 'Empty';

  @override
  String get component_unknown_component => 'Unknown component';

  @override
  String get common_bot => 'Bot';

  @override
  String get command_payload_hint => 'Command payload';

  @override
  String get workflows_search_hint => 'Search workflows...';

  @override
  String get component_default_option_label => 'Option';

  @override
  String get component_default_choice_label => 'Choice';

  @override
  String get command_execution_error =>
      'An error occurred while executing this command.';

  @override
  String get bdfd_runtime_execution_error =>
      'An error occurred while executing this BDFD script.';

  @override
  String get bdfd_compiled_no_actions =>
      'This BDFD script compiled successfully but did not produce any action.';

  @override
  String get embed_section_color => 'Color';

  @override
  String get embed_section_timestamp => 'Timestamp';

  @override
  String get embed_section_fields => 'Fields';

  @override
  String get embed_section_dynamic_fields => 'Dynamic Fields';

  @override
  String get embed_add_field => 'Add Field';

  @override
  String get embed_add_section => 'Add Section';

  @override
  String get common_add_section => 'Add Section';

  @override
  String get component_block_workflow => 'Workflow';

  @override
  String get component_block_label_style => 'Style';

  @override
  String get notion_filter_add => 'Add Filter';

  @override
  String get notion_filter_type => 'Type';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'Create workflow \"$query\"';
  }

  @override
  String commands_create_from_query(String query) {
    return 'Create command \"$query\"';
  }

  @override
  String get commands_filter_type_label => 'Type';
}
