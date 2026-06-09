// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get action_add_else_if => 'ELSE IF hinzufügen';

  @override
  String get action_add_header => 'Header hinzufügen';

  @override
  String get action_add_new_item => 'Neues Element hinzufügen';

  @override
  String get action_advanced_settings => 'Erweiterte Einstellungen';

  @override
  String action_and_more(int count) {
    return '… und $count weitere';
  }

  @override
  String get action_bulk_import_hint =>
      'Massenimport (Header einfügen wie Schlüssel: Wert)';

  @override
  String get action_cannot_format_json =>
      'Formatieren nicht möglich: Ungültiges JSON';

  @override
  String get action_category_channels => 'Kanäle';

  @override
  String get action_category_components => 'Komponenten';

  @override
  String get action_category_guild_members => 'Server & Mitglieder';

  @override
  String get action_category_http_variables => 'HTTP & Variablen';

  @override
  String get action_category_interactions => 'Interaktionen';

  @override
  String get action_category_logic_flow => 'Logik & Ablauf';

  @override
  String get action_category_messages => 'Nachrichten';

  @override
  String get action_category_moderation => 'Moderation';

  @override
  String get action_category_reactions => 'Reaktionen';

  @override
  String get action_category_webhooks => 'Webhooks';

  @override
  String get action_category_workflows => 'Workflows';

  @override
  String action_choose_param(String name) {
    return '$name wählen';
  }

  @override
  String get action_clear_all => 'Alle löschen';

  @override
  String get action_condition_value => 'Bedingungswert';

  @override
  String get action_condition_variable => 'Bedingungsvariable';

  @override
  String get action_description_addReaction =>
      'Add an emoji reaction to a message';

  @override
  String get action_description_addRole => 'Assign a role to a member';

  @override
  String get action_description_banUser =>
      'Permanently ban a user from the guild';

  @override
  String get action_description_clearAllReactions =>
      'Clear all reactions from a message';

  @override
  String get action_description_cooldown =>
      'Apply a cooldown to the user or server';

  @override
  String get action_description_deleteMessages => 'Delete one or more messages';

  @override
  String get action_description_deleteTrigger =>
      'Delete the message that triggered this command';

  @override
  String get action_description_editMessage => 'Edit an existing message';

  @override
  String get action_description_kickUser => 'Remove a member from the guild';

  @override
  String get action_description_muteUser => 'Temporarily timeout a member';

  @override
  String get action_description_randomChoice =>
      'Pick a random item from a list';

  @override
  String get action_description_removeReaction =>
      'Remove a reaction from a message';

  @override
  String get action_description_removeRole => 'Remove a role from a member';

  @override
  String get action_description_sendDm => 'Send a direct message to a user';

  @override
  String get action_description_sendMessage => 'Send a message to a channel';

  @override
  String get action_description_setNickname => 'Change a member\'s nickname';

  @override
  String get action_description_slowmode =>
      'Set slowmode duration for a channel';

  @override
  String get action_description_stop => 'Stop the current workflow execution';

  @override
  String get action_description_unbanUser => 'Revoke a user\'s ban';

  @override
  String get action_description_unmuteUser => 'Remove timeout from a member';

  @override
  String get action_description_wait =>
      'Pause execution for a specific duration';

  @override
  String get action_dynamic => 'Dynamisch';

  @override
  String get action_dynamic_bool_hint => 'true/false oder ((variable))';

  @override
  String action_dynamic_id_hint(String type) {
    return 'Dynamische $type (unterstützt ((...)))';
  }

  @override
  String get action_dynamic_multiselect_hint =>
      'Dynamischer Wert (unterstützt ((...)))';

  @override
  String get action_dynamic_numeric => 'Dynamische numerische Vorschläge';

  @override
  String get action_dynamic_variable => 'Dynamische Variablenvorschläge';

  @override
  String action_edit_nested(int count) {
    return '$count bearbeiten';
  }

  @override
  String action_edit_nested_parens(int count) {
    return 'Bearbeiten ($count)';
  }

  @override
  String action_edit_param(String name) {
    return '$name bearbeiten';
  }

  @override
  String get action_edit_raw_json => 'Rohes JSON bearbeiten';

  @override
  String action_else_if_label(int index) {
    return 'ELSE IF $index — Aktionen';
  }

  @override
  String get action_error_continue => 'Fortfahren';

  @override
  String get action_error_stop => 'Stoppen';

  @override
  String get action_expression => 'Ausdruck';

  @override
  String get action_format_json => 'JSON formatieren';

  @override
  String get action_hint_color => '#FFFFFF oder rgb(255,255,255)';

  @override
  String get action_hint_condition_value => 'Wert zum Vergleichen';

  @override
  String get action_hint_condition_var =>
      'Verwenden Sie ((variableName)) oder einen Laufzeitwert';

  @override
  String get action_hint_cooldown_error =>
      'Benutzerdefinierte Fehlermeldung (unterstützt %time%)';

  @override
  String get action_hint_cooldown_time => 'Zeit (z. B. 10s, 1m)';

  @override
  String get action_hint_duration => 'z. B. 5m, 1h, 30s';

  @override
  String get action_hint_emoji => 'Emoji (z. B. 🪜) oder <:name:id>';

  @override
  String action_hint_enter_type(String type) {
    return '$type eingeben';
  }

  @override
  String get action_hint_random_choices => 'List of choices (separated by ;)';

  @override
  String get action_hint_random_var => 'Variable name to store the result';

  @override
  String get action_hint_variable_key => 'Variablenschlüssel auswählen';

  @override
  String get action_hint_workflow => 'Gespeicherter Workflow-Name';

  @override
  String get action_http_headers_title => 'HTTP-Header (Schlüssel/Wert Paare)';

  @override
  String action_http_paths_parsed(int count) {
    return '$count Pfade analysiert';
  }

  @override
  String get action_http_response_body => 'Antwortkörper (Rohdaten):';

  @override
  String action_http_status(int status) {
    return 'Status: $status';
  }

  @override
  String get action_http_test_button =>
      'Testanfrage senden & Routen automatisch erkennen';

  @override
  String get action_http_test_title => 'Ergebnisse der Testanfrage';

  @override
  String get action_json_editor_hint =>
      'JSON-Objekt-Editor (unterstützt verschachtelte Objekte/Arrays)';

  @override
  String get action_key_field => 'Aktionsschlüssel';

  @override
  String get action_key_value_pairs => 'Schlüssel / Wert Paare';

  @override
  String get action_literal => 'Literal';

  @override
  String get action_loading_keys => 'Schlüssel werden geladen...';

  @override
  String get action_manage_variable_keys => 'Variablenschlüssel verwalten';

  @override
  String get action_name_addReaction => 'Reaktion hinzufügen';

  @override
  String get action_name_addRole => 'Rolle hinzufügen';

  @override
  String get action_name_addThreadMember => 'Thread-Mitglied hinzufügen';

  @override
  String get action_name_appendArrayElement => 'Array-Element anhängen';

  @override
  String get action_name_attachImage => 'Bild anhängen';

  @override
  String get action_name_banUser => 'Benutzer bannen';

  @override
  String get action_name_calculate => 'Berechnen';

  @override
  String get action_name_canvasCreateBlock => 'Leinwand erstellen';

  @override
  String get action_name_canvasDrawCircleBlock => 'Kreis zeichnen';

  @override
  String get action_name_canvasDrawRectBlock => 'Rechteck zeichnen';

  @override
  String get action_name_canvasDrawTextBlock => 'Text zeichnen';

  @override
  String get action_name_canvasLoadImageBlock => 'Bild laden';

  @override
  String get action_name_clearAllReactions => 'Alle Reaktionen löschen';

  @override
  String get action_name_cooldown => 'Cooldown';

  @override
  String get action_name_createAutoModRule => 'AutoMod-Regel erstellen';

  @override
  String get action_name_createChannel => 'Kanal erstellen';

  @override
  String get action_name_createEmoji => 'Emoji erstellen';

  @override
  String get action_name_createInvite => 'Einladung erstellen';

  @override
  String get action_name_createPoll => 'Umfrage erstellen';

  @override
  String get action_name_createThread => 'Thread erstellen';

  @override
  String get action_name_deleteAutoModRule => 'AutoMod-Regel löschen';

  @override
  String get action_name_deleteChannelPermission => 'Kanalberechtigung löschen';

  @override
  String get action_name_deleteEmoji => 'Emoji löschen';

  @override
  String get action_name_deleteInvite => 'Einladung löschen';

  @override
  String get action_name_deleteMessages => 'Nachrichten löschen';

  @override
  String get action_name_deleteTrigger => 'Trigger löschen';

  @override
  String get action_name_deleteWebhook => 'Webhook löschen';

  @override
  String get action_name_debugProfile => 'Debug-Profil';

  @override
  String get action_name_disconnectFromVoice => 'Von Sprache trennen';

  @override
  String get action_name_editChannelPermissions =>
      'Kanalberechtigungen bearbeiten';

  @override
  String get action_name_editComponentV2 => 'Komponente V2 bearbeiten';

  @override
  String get action_name_editInteractionMessage =>
      'Interaktionsnachricht bearbeiten';

  @override
  String get action_name_editMessage => 'Nachricht bearbeiten';

  @override
  String get action_name_editWebhook => 'Webhook bearbeiten';

  @override
  String get action_name_endPoll => 'Umfrage beenden';

  @override
  String get action_name_forLoop => 'For-Schleife';

  @override
  String get action_name_getGlobalVariable => 'Globale Variable abrufen';

  @override
  String get action_name_getGuildOnboarding => 'Gilden-Onboarding abrufen';

  @override
  String get action_name_getInvite => 'Einladung abrufen';

  @override
  String get action_name_getMember => 'Mitglied abrufen';

  @override
  String get action_name_getMessage => 'Nachricht abrufen';

  @override
  String get action_name_getScopedVariable =>
      'Geltungsbereichsvariable abrufen';

  @override
  String get action_name_getWebhook => 'Webhook abrufen';

  @override
  String get action_name_httpRequest => 'HTTP-Anfrage';

  @override
  String get action_name_ifBlock => 'IF / ELSE Block';

  @override
  String get action_name_jsonForEachLoop => 'JSON Für Jedes Schleife';

  @override
  String get action_name_kickUser => 'Benutzer kicken';

  @override
  String get action_name_listAutoModRules => 'AutoMod-Regeln auflisten';

  @override
  String get action_name_listMembers => 'Mitglieder auflisten';

  @override
  String get action_name_listScopedVariableIndex =>
      'Geltungsbereichsvariablen-Index auflisten';

  @override
  String get action_name_listWebhooks => 'Webhooks auflisten';

  @override
  String get action_name_listenForButtonClick => 'Auf Button-Klick warten';

  @override
  String get action_name_listenForModalSubmit =>
      'Auf Modal-Übermittlung warten';

  @override
  String get action_name_listenForSelectMenu => 'Auf Auswahlmenü warten';

  @override
  String get action_name_log => 'Nachricht protokollieren';

  @override
  String get action_name_moveToVoiceChannel => 'In Sprachkanal verschieben';

  @override
  String get action_name_muteUser => 'Benutzer stummschalten';

  @override
  String get action_name_pinMessage => 'Nachricht anpinnen';

  @override
  String get action_name_queryArray => 'Array abfragen';

  @override
  String get action_name_randomChoice => 'Zufällige Auswahl';

  @override
  String get action_name_registerGuildCommands => 'Server-Befehle registrieren';

  @override
  String get action_name_removeArrayElement => 'Array-Element entfernen';

  @override
  String get action_name_removeChannel => 'Kanal entfernen';

  @override
  String get action_name_removeGlobalVariable => 'Globale Variable entfernen';

  @override
  String get action_name_removeReaction => 'Reaktion entfernen';

  @override
  String get action_name_removeRole => 'Rolle entfernen';

  @override
  String get action_name_removeScopedVariable =>
      'Geltungsbereichsvariable entfernen';

  @override
  String get action_name_removeThreadMember => 'Thread-Mitglied entfernen';

  @override
  String get action_name_renameScopedVariable =>
      'Geltungsbereichsvariable umbenennen';

  @override
  String get action_name_respondWithAutocomplete =>
      'Mit Autocomplete antworten';

  @override
  String get action_name_respondWithComponentV2 =>
      'Mit Komponente V2 antworten';

  @override
  String get action_name_respondWithMessage => 'Mit Nachricht antworten';

  @override
  String get action_name_respondWithModal => 'Mit Modal antworten';

  @override
  String get action_name_runBdfdScript => 'BDFD-Skript ausführen';

  @override
  String get action_name_runtimeJsonBlock => 'JSON-Operationen ausführen';

  @override
  String get action_name_runtimeImageBlock => 'Bildoperationen ausführen';

  @override
  String get action_name_runWorkflow => 'Workflow ausführen';

  @override
  String get action_name_sendComponentV2 => 'Komponente V2 senden';

  @override
  String get action_name_sendDm => 'DM senden';

  @override
  String get action_name_sendMessage => 'Nachricht senden';

  @override
  String get action_name_sendWebhook => 'Webhook senden';

  @override
  String get action_name_serverDeafenMember => 'Server-Taubschaltung Mitglied';

  @override
  String get action_name_serverMuteMember => 'Server-Stummschaltung Mitglied';

  @override
  String get action_name_setGlobalVariable => 'Globale Variable setzen';

  @override
  String get action_name_setNickname => 'Nickname setzen';

  @override
  String get action_name_setScopedVariable => 'Geltungsbereichsvariable setzen';

  @override
  String get action_name_setTemporaryVariable => 'Temporäre Variable setzen';

  @override
  String get action_name_slowmode => 'Slowmode';

  @override
  String get action_name_stop => 'Stoppen';

  @override
  String get action_name_stopUnless => 'Stoppen außer Bedingung erfüllt';

  @override
  String get action_name_unbanUser => 'Benutzer entbannen';

  @override
  String get action_name_unmuteUser => 'Benutzer lautschalten';

  @override
  String get action_name_unpinMessage => 'Nachricht lospinnen';

  @override
  String get action_name_unregisterGuildCommands =>
      'Server-Befehle deregistrieren';

  @override
  String get action_name_updateAutoMod => 'AutoMod aktualisieren';

  @override
  String get action_name_updateChannel => 'Kanal aktualisieren';

  @override
  String get action_name_updateEmoji => 'Emoji aktualisieren';

  @override
  String get action_name_updateGuild => 'Gilde aktualisieren';

  @override
  String get action_name_updateGuildOnboarding =>
      'Gilden-Onboarding aktualisieren';

  @override
  String get action_name_updateSelfUser =>
      'Eigenen Benutzer aktualisieren (Bot-Profil)';

  @override
  String get action_name_wait => 'Warten';

  @override
  String get action_no_actions_yet => 'Noch keine Aktionen in diesem Zweig.';

  @override
  String get action_no_args_tap_edit =>
      'Keine Argumente - zum Hinzufügen auf Bearbeiten tippen';

  @override
  String get action_no_else_if_yet =>
      'Noch keine ELSE IF-Zweige. Fügen Sie einen hinzu, um weitere Bedingungen vor ELSE zu prüfen.';

  @override
  String get action_no_headers_tap_edit =>
      'Keine Header - zum Hinzufügen auf Bearbeiten tippen';

  @override
  String get action_no_items_tap_edit =>
      'Keine Elemente - zum Hinzufügen auf Bearbeiten tippen';

  @override
  String get action_no_properties_tap_edit =>
      'Keine Eigenschaften - zum Konfigurieren auf Bearbeiten tippen';

  @override
  String get action_no_saved_keys =>
      'Keine gespeicherten Schlüssel gefunden. Schlüssel werden beim ersten Zugriff automatisch erstellt.';

  @override
  String get action_on_error => 'Bei Fehler';

  @override
  String get action_options_tooltip => 'Aktionsoptionen';

  @override
  String get action_or_type_workflow => 'Oder Workflow-Namen eingeben';

  @override
  String get action_order_tip =>
      'Tipp: Verwenden Sie die Pfeile, um die Reihenfolge der Aktionen zu ändern.';

  @override
  String action_position(int index, int total) {
    return 'Aktion $index/$total';
  }

  @override
  String get action_preview_json => 'Markiertes JSON in der Vorschau anzeigen';

  @override
  String get action_provide_valid_url => 'Bitte geben Sie eine gültige URL an.';

  @override
  String get action_refresh_keys => 'Schlüssel aktualisieren';

  @override
  String get action_remove_confirm =>
      'Diese Aktion wird aus dem Workflow entfernt. Fortfahren?';

  @override
  String get action_remove_else_if => 'ELSE IF entfernen';

  @override
  String get action_remove_menu => 'Aktion entfernen';

  @override
  String get action_remove_title => 'Aktion entfernen';

  @override
  String get action_root_must_json => 'Wurzel muss ein JSON-Objekt sein';

  @override
  String get action_select_saved_key => 'Gespeicherten Schlüssel auswählen';

  @override
  String get action_select_stored_key =>
      'Gespeicherten Schlüssel auswählen (bc_ Präfix ist optional)';

  @override
  String get action_static_badge => '(statisch)';

  @override
  String get action_status_disabled => 'Deaktiviert';

  @override
  String get action_status_enabled => 'Aktiviert';

  @override
  String get action_store_results =>
      'Ergebnisse in globalen Variablen speichern';

  @override
  String actions_active_route(String label) {
    return 'Aktive Route: $label';
  }

  @override
  String get actions_add_label => 'Aktion hinzufügen';

  @override
  String get actions_add_new_title => 'Neue Aktion hinzufügen';

  @override
  String actions_build_button(int count) {
    return 'Aktionen erstellen ($count)';
  }

  @override
  String get actions_builder_title => 'Aktions-Builder';

  @override
  String get actions_description =>
      'Erstellen Sie Laufzeitaktionen für diesen Befehl';

  @override
  String get actions_global_variables => 'Globale Variablen';

  @override
  String actions_key_label(String key) {
    return 'Schlüssel: $key';
  }

  @override
  String get actions_missing_field_title => 'Fehlendes Feld';

  @override
  String get actions_no_matches => 'Keine Treffer gefunden';

  @override
  String actions_save_count(int count) {
    return '$count Aktionen speichern';
  }

  @override
  String get actions_save_tooltip => 'Aktionen speichern';

  @override
  String get actions_save_workflow_title => 'Als Workflow speichern';

  @override
  String get actions_search_hint => 'Aktionen suchen...';

  @override
  String get actions_search_sequence_hint => 'Sequenz suchen...';

  @override
  String actions_sequence_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Aktionen',
      one: '1 Aktion',
      zero: 'Keine Aktionen',
    );
    return '$_temp0';
  }

  @override
  String actions_step_label(int index, int total) {
    return 'Schritt $index von $total';
  }

  @override
  String actions_summary_bdfd(int lines, int diagnostics) {
    return 'BDFD-Skript | $lines Zeile(n) | $diagnostics Diagnose(n)';
  }

  @override
  String actions_summary_configured(int count) {
    return '$count Aktion(en) konfiguriert';
  }

  @override
  String actions_summary_dart(int lines, int diagnostics) {
    return 'Dart-Skript | $lines Zeile(n) | $diagnostics Diagnose(n)';
  }

  @override
  String actions_summary_routes(int count, int routes) {
    return '$count Aktion(en) auf aktiver Route | $routes Route(n)';
  }

  @override
  String get actions_title => 'Aktionen';

  @override
  String get actions_workflow_name_label => 'Workflow-Name';

  @override
  String get actions_workflows => 'Workflows';

  @override
  String get ads_consent_accept => 'Ich akzeptiere';

  @override
  String get ads_consent_message =>
      'Um der DSGVO zu entsprechen, benötigen wir deine Einwilligung, bevor wir Anzeigen zeigen. Du kannst die App auch dann weiter nutzen, wenn du ablehnst.';

  @override
  String get ads_consent_refuse => 'Ich lehne ab';

  @override
  String get ads_consent_refused_info =>
      'Einwilligung zu Anzeigen abgelehnt. Der Bot startet trotzdem normal.';

  @override
  String get ads_consent_title => 'Einwilligung zu Anzeigen';

  @override
  String get app_bot_token => 'Bot-Token';

  @override
  String get app_create_button => 'Bot erstellen';

  @override
  String get app_create_hero_desc =>
      'Eine geführte Einrichtung, um die richtigen Seiten zu öffnen, Ihr Token zu kopieren und den Bot sicher zu importieren.';

  @override
  String get app_create_hero_title => 'Verbinden Sie Ihren Discord-Bot';

  @override
  String get app_create_new => 'Neue App erstellen';

  @override
  String get app_create_page_title => 'Bot erstellen';

  @override
  String get app_enter_token => 'Geben Sie hier Ihr Bot-Token ein';

  @override
  String get app_external_link_badge => 'Externer Link';

  @override
  String get app_hide_token => 'Token ausblenden';

  @override
  String get app_how_to_create_token => 'Wie erstelle ich ein Bot-Token?';

  @override
  String get app_loading_error => 'Fehler beim Laden';

  @override
  String get app_no_apps => 'Sie haben noch keine Apps.';

  @override
  String get app_note =>
      'Hinweis: Sie müssen eine neue App im Discord Developer Portal erstellen und Ihr Bot-Token erhalten.';

  @override
  String get app_open_discord_portal => 'Discord Developer Portal öffnen';

  @override
  String get app_open_discord_portal_desc =>
      'Erstellen Sie Ihre Anwendung und aktivieren Sie den Bot-Bereich.';

  @override
  String get app_open_link_error =>
      'Diese externe Seite kann nicht geöffnet werden.';

  @override
  String get app_open_token_tutorial => 'Token-Tutorial lesen';

  @override
  String get app_open_token_tutorial_desc =>
      'Eine Schritt-für-Schritt-Anleitung zum Generieren und Kopieren Ihres Bot-Tokens.';

  @override
  String get app_resources_desc =>
      'Diese Aktionen öffnen die offiziellen Seiten, die Sie benötigen, bevor Sie Ihren Bot hier speichern.';

  @override
  String get app_resources_title => 'Geführte Einrichtung';

  @override
  String get app_save => 'Änderungen speichern';

  @override
  String get app_save_bot => 'Bot hinzufügen';

  @override
  String get app_show_token => 'Token anzeigen';

  @override
  String get app_sync_manager_connect => 'Discord verbinden';

  @override
  String get app_sync_manager_desc =>
      'Dieser Bot ist bereits auf dem Bot Creator Manager gespeichert. Mit Discord verbinden, um alle Ihre Bots automatisch zu synchronisieren?';

  @override
  String get app_sync_manager_manual => 'Lokal behalten';

  @override
  String get app_sync_manager_title => 'Bot bereits verwaltet';

  @override
  String get app_title => 'Bot Creator';

  @override
  String get app_token_field_helper =>
      'Fügen Sie das Token genau so ein, wie es von Discord bereitgestellt wurde.';

  @override
  String get app_token_section_desc =>
      'Sobald das Token kopiert wurde, fügen Sie es unten ein, um Ihren Bot zur App hinzuzufügen.';

  @override
  String get app_token_section_title => 'Bot-Token einfügen';

  @override
  String get app_token_security_hint =>
      'Halten Sie dieses Token privat. Jeder, der es hat, kann Ihren Bot steuern.';

  @override
  String get autocomplete_dynamic => 'Dynamische Autovervollständigung';

  @override
  String get autocomplete_dynamic_desc =>
      'Auswahlmöglichkeiten aus einem Workflow statt aus statischen Werten auflösen.';

  @override
  String get autocomplete_filter_hint =>
      'Vorschläge werden nach der Eingabe des Benutzers gefiltert.';

  @override
  String get autocomplete_loading => 'Workflows werden geladen…';

  @override
  String get autocomplete_no_workflows =>
      'Keine gespeicherten Workflows gefunden';

  @override
  String get autocomplete_select_workflow => 'Gespeicherten Workflow auswählen';

  @override
  String get autocomplete_type_name => 'Oder Workflow-Namen eingeben';

  @override
  String get autocomplete_workflow_label => 'Autovervollständigungs-Workflow';

  @override
  String backup_completed(String id) {
    return 'Backup abgeschlossen: $id';
  }

  @override
  String backup_failed(String error) {
    return 'Backup fehlgeschlagen: $error';
  }

  @override
  String bdfd_compile_error_detailed(String summary) {
    return 'Dieses BDFD-Skript konnte nicht kompiliert werden:\n$summary';
  }

  @override
  String get bdfd_compile_error_simple =>
      'Dieses BDFD-Skript konnte nicht kompiliert werden.';

  @override
  String get bdfd_compiled_no_actions =>
      'Dieses BDFD-Skript wurde erfolgreich kompiliert, hat aber keine Aktion erzeugt.';

  @override
  String get bdfd_docs_category_channels => 'Kanäle & Threads';

  @override
  String get bdfd_docs_category_components => 'Komponenten';

  @override
  String get bdfd_docs_category_control => 'Kontrollfluss';

  @override
  String get bdfd_docs_category_cooldowns => 'Cooldowns';

  @override
  String get bdfd_docs_category_embeds => 'Embeds';

  @override
  String get bdfd_docs_category_guards => 'Guards & Berechtigungen';

  @override
  String get bdfd_docs_category_http => 'HTTP-Anfragen';

  @override
  String get bdfd_docs_category_json => 'JSON';

  @override
  String get bdfd_docs_category_leaderboards => 'Bestenlisten';

  @override
  String get bdfd_docs_category_math => 'Mathematik';

  @override
  String get bdfd_docs_category_messages => 'Nachrichten & Inhalt';

  @override
  String get bdfd_docs_category_misc => 'Sonstiges';

  @override
  String get bdfd_docs_category_modals => 'Modals';

  @override
  String get bdfd_docs_category_moderation => 'Moderation';

  @override
  String get bdfd_docs_category_reactions => 'Reaktionen';

  @override
  String get bdfd_docs_category_roles => 'Rollen';

  @override
  String get bdfd_docs_category_text => 'Text & Zeichenfolgen';

  @override
  String get bdfd_docs_category_tickets => 'Tickets';

  @override
  String get bdfd_docs_category_variables => 'Variablen';

  @override
  String get bdfd_docs_category_webhooks => 'Webhooks';

  @override
  String get bdfd_docs_desc_and =>
      'Logisches UND — kombiniert mehrere Bedingungen. Alle müssen wahr sein.\n\nVerwendung: \$if[\$and[\$authorID==123;\$hasRole[456]]]';

  @override
  String get bdfd_docs_desc_awaitfunc =>
      'Registriert einen Callback, der auf eine Benutzerantwort wartet.\n\nVerwendung: \$awaitFunc[name;userID (opt);channelID (opt)]\n\nDie erwartete Funktion wird gespeichert und ausgelöst, wenn der Zielbenutzer eine Nachricht im Zielkanal sendet.';

  @override
  String get bdfd_docs_desc_callworkflow =>
      'Nur Bot Creator — Ruft einen anderen Workflow namentlich auf und übergibt Argumente.\n\nSyntax: \$callWorkflow[meinWorkflow;schlüssel1=wert1;schlüssel2=wert2]\n\nDer aufgerufene Workflow kann Argumente lesen und einen Wert über \$workflowResponse zurückgeben.';

  @override
  String get bdfd_docs_desc_defer =>
      'Verzögert die Interaktionsantwort und gibt Ihnen mehr Zeit zur Verarbeitung. Der Benutzer sieht eine \"Bot denkt nach…\"-Nachricht. Vor langen Operationen wie HTTP-Anfragen verwenden.';

  @override
  String get bdfd_docs_desc_elseif =>
      'Fügt eine alternative Bedingung innerhalb eines \$if-Blocks hinzu. Muss zwischen \$if und \$else/\$endif erscheinen.';

  @override
  String get bdfd_docs_desc_embedsuppresserrors =>
      'Gleich wie \$suppressErrors — unterdrückt alle Fehlermeldungen lautlos.';

  @override
  String get bdfd_docs_desc_ephemeral =>
      'Macht die Antwort nur für den Benutzer sichtbar, der den Befehl ausgelöst hat. Muss vor jeglichem Antwortinhalt platziert werden.';

  @override
  String get bdfd_docs_desc_eval =>
      'Führt eine BDFD-Skript-Zeichenfolge zur Laufzeit aus. Der als Argument übergebene Code wird dynamisch neu kompiliert und ausgeführt. Nützlich für die Ausführung von benutzerdefinierten oder variablenbasierten Skripten.';

  @override
  String get bdfd_docs_desc_for =>
      'Nur Bot Creator — Wiederholt einen Codeblock N-mal.\n\nEinfach: \$for[5]...\$endfor → der Körper wird 5-mal wiederholt (max. 100). Sie können \$i für den aktuellen Index (beginnend bei 0) und \$loopCount für die Gesamtzahl verwenden.\n\nC-Style: \$for[i=0;i<10;i++]...\$endfor → klassische For-Schleife mit Initialisierung, Bedingung und Aktualisierung. Unterstützt ++, --, +=, -=, *. \n\nWenn die Iterationszahl dynamisch ist (z. B. \$for[\$args[1]]), wird die Schleife zur Laufzeit statt zur Kompilierzeit ausgeführt.';

  @override
  String get bdfd_docs_desc_httpaddheader =>
      'Fügt der nächsten HTTP-Anfrage einen Header hinzu. Header werden bis zum nächsten \$httpGet/\$httpPost/usw. gesammelt.\n\nVerwendung: \$httpAddHeader[Authorization;Bearer token123]';

  @override
  String get bdfd_docs_desc_httpget =>
      'Sendet eine HTTP GET-Anfrage an die angegebene URL. Verwenden Sie vorher \$httpAddHeader, um Header zu setzen. Verwenden Sie \$httpResult, um die Antwort zu lesen.\n\nAlle HTTP-Methoden (GET, POST, PUT, PATCH, DELETE) folgen demselben Muster.';

  @override
  String get bdfd_docs_desc_httpresult =>
      'Gibt den Körper der letzten HTTP-Antwort zurück. Übergeben Sie optional einen JSON-Pfad, um ein bestimmtes Feld zu extrahieren.\n\nVerwendung: \$httpResult[] für den vollständigen Körper oder \$httpResult[data.name] für ein verschachteltes Feld.';

  @override
  String get bdfd_docs_desc_if =>
      'Bedingter Block. Unterstützt Schachtelung und umfangreiche Operatoren: ==, !=, >=, <=, >, <, contains, startsWith, endsWith, notContains.\n\nVerwendung:\n\$if[\$authorID==123456]\n  Hallo Admin!\n\$elseif[\$hasRole[789]]\n  Hallo Mitglied!\n\$else\n  Hallo Gast!\n\$endif';

  @override
  String get bdfd_docs_desc_jsonparse =>
      'Analysiert eine JSON-Zeichenfolge in den Speicher zur Manipulation. Alle JSON-Operationen (\$jsonSet, \$json usw.) arbeiten in diesem analysierten Kontext.\n\nStatische JSON wird zur besseren Leistung zur Kompilierzeit aufgelöst.';

  @override
  String get bdfd_docs_desc_jsonset =>
      'Setzt einen Wert im aktuellen JSON-Kontext. Unterstützt Punkt-Notation für Pfade.\n\nVerwendung: \$jsonSet[user.name;John]\n\nDie Änderung wird im Speicher angewendet — verwenden Sie \$jsonStringify, um das Ergebnis zu erhalten.';

  @override
  String get bdfd_docs_desc_jsonstringify =>
      'Konvertiert den aktuellen JSON-Kontext zurück in eine Zeichenfolge. Nach \$jsonParse- und \$jsonSet-Operationen verwenden, um das Ergebnis auszugeben.';

  @override
  String get bdfd_docs_desc_loop =>
      'Nur Bot Creator — Alias für \$for. Siehe \$for für Details. Verwenden Sie \$endloop zum Schließen des Blocks.';

  @override
  String get bdfd_docs_desc_or =>
      'Logisches ODER — kombiniert mehrere Bedingungen. Mindestens eine muss wahr sein.\n\nVerwendung: \$if[\$or[\$authorID==123;\$authorID==456]]]';

  @override
  String get bdfd_docs_desc_stop =>
      'Stoppt sofort die Ausführung des aktuellen Skripts. Nach \$stop werden keine weiteren Aktionen ausgeführt.';

  @override
  String get bdfd_docs_desc_suppresserrors =>
      'Verhindert, dass Fehlermeldungen an den Benutzer gesendet werden. Wenn eine Aktion fehlschlägt, wird der Fehler lautlos unterdrückt.';

  @override
  String get bdfd_docs_desc_try =>
      'Umschließt einen Block zur Fehlerbehandlung.\n\nVerwendung:\n\$try\n  \$httpGet[https://api.example.com/data]\n\$catch\n  Anfrage fehlgeschlagen!\n\$endtry\n\nWenn eine Funktion im \$try-Block fehlschlägt, springt die Ausführung zu \$catch.';

  @override
  String get bdfd_docs_desc_workflowresponse =>
      'Nur Bot Creator — Gibt die Antwort des letzten \$callWorkflow zurück.\n\nVerwenden Sie \$workflowResponse[] für die vollständige Antwort oder \$workflowResponse[eigenschaft], um auf ein bestimmtes Feld zuzugreifen.';

  @override
  String get bdfd_docs_empty => 'Keine passenden Funktionen.';

  @override
  String get bdfd_docs_no_params =>
      'Keine Parameter — Verwendung als \$functionName';

  @override
  String get bdfd_docs_parameters => 'PARAMETER';

  @override
  String get bdfd_docs_search_hint => 'Funktionen suchen…';

  @override
  String get bdfd_docs_syntax => 'SYNTAX';

  @override
  String get bdfd_docs_title => 'BDFD-Dokumentation';

  @override
  String get bdfd_editor_auto_indent =>
      '• Intelligente automatische Einrückung bei Enter';

  @override
  String get bdfd_editor_diagnostics_toggle => 'Diagnose-Panel umschalten';

  @override
  String get bdfd_editor_docs => 'BDFD-Funktionsreferenz';

  @override
  String get bdfd_editor_empty =>
      'Leeres Skript — fangen Sie an zu tippen, um Diagnosen zu sehen.';

  @override
  String get bdfd_editor_includes => 'Beinhaltet:';

  @override
  String get bdfd_editor_indent_guides => '• Live-Einrückungshilfen';

  @override
  String get bdfd_editor_quick_keys =>
      '• Mobile Schnellwahltasten für BDFD-Symbole';

  @override
  String get bdfd_editor_tap_hint => 'Tippen zum Öffnen des Editors';

  @override
  String get bdfd_editor_title => 'BDFD-Editor';

  @override
  String get bdfd_editor_toggle_indent => 'Einrückungshilfen umschalten';

  @override
  String get bdfd_editor_ux_title => 'Editor UX';

  @override
  String get bdfd_editor_wrap_toggle => 'Zeilenumbruch umschalten';

  @override
  String get bdfd_runtime_execution_error =>
      'Beim Ausführen dieses BDFD-Skripts ist ein Fehler aufgetreten.';

  @override
  String get bot_home_create_command => 'Meinen ersten Befehl erstellen';

  @override
  String get bot_home_customize => 'Meinen Bot anpassen';

  @override
  String get bot_home_delete => 'App löschen';

  @override
  String get bot_home_delete_confirm =>
      'Sind Sie sicher, dass Sie diese App löschen möchten?';

  @override
  String get bot_home_invite => 'Bot einladen';

  @override
  String get bot_home_invite_error =>
      'Einladungslink konnte nicht geöffnet werden';

  @override
  String get bot_home_ios_notice_content =>
      'Im lokalen Modus kann iOS die App im Hintergrund anhalten. Der Bot kann starten, aber die Aufrechterhaltung der Discord-Verbindung ist nicht garantiert, wie es bei einem Runner der Fall ist.';

  @override
  String get bot_home_ios_notice_title => 'Lokale iOS-Einschränkung';

  @override
  String get bot_home_log_desktop_stop => 'Desktop-Bot-Stopp angefordert';

  @override
  String get bot_home_log_start => 'Bot-Start angefordert';

  @override
  String get bot_home_log_stop => 'Bot-Stopp angefordert';

  @override
  String get bot_home_notif_required =>
      'Benachrichtigungsberechtigung ist erforderlich, um den Bot-Dienst zu starten.';

  @override
  String get bot_home_section_danger => 'GEFAHRENZONE';

  @override
  String get bot_home_section_getting_started => 'ERSTE SCHRITTE';

  @override
  String get bot_home_section_monitoring => 'ÜBERWACHUNG';

  @override
  String get bot_home_section_tools => 'TOOLS';

  @override
  String get bot_home_service_not_started =>
      'Vordergrunddienst wurde nicht gestartet.';

  @override
  String get bot_home_start => 'Bot starten';

  @override
  String bot_home_start_error(String error) {
    return 'Konnte nicht gestartet werden: $error';
  }

  @override
  String get bot_home_starting => 'Startet…';

  @override
  String get bot_home_stop => 'Bot stoppen';

  @override
  String get bot_home_sync => 'App synchronisieren';

  @override
  String get bot_home_sync_success => 'App erfolgreich synchronisiert';

  @override
  String get bot_home_token_invalid_content =>
      'Verbindung zu Discord mit dem angegebenen Token nicht möglich. Es könnte ungültig oder widerrufen sein. Möchten Sie den Bot trotzdem starten?';

  @override
  String get bot_home_token_invalid_title => 'Token scheint ungültig zu sein';

  @override
  String get bot_home_view_logs => 'Bot-Protokolle anzeigen';

  @override
  String get bot_home_view_replay => 'Debugger-Replays anzeigen';

  @override
  String get bot_home_view_stats => 'Bot-Statistiken anzeigen';

  @override
  String get bot_logs_copied => 'Protokolle kopiert';

  @override
  String get bot_logs_disable_debug => 'Debug-Protokolle deaktivieren';

  @override
  String get bot_logs_empty => 'Noch keine Protokolle';

  @override
  String get bot_logs_enable_debug => 'Debug-Protokolle aktivieren';

  @override
  String get bot_logs_filter_count => 'Anzahl der angezeigten Protokolle';

  @override
  String get bot_logs_go_to_bottom => 'Nach unten gehen';

  @override
  String get bot_logs_go_to_latest => 'Zum neuesten Protokoll gehen';

  @override
  String get bot_logs_newest_first => 'Neueste zuerst anzeigen';

  @override
  String get bot_logs_oldest_first => 'Älteste zuerst anzeigen';

  @override
  String bot_logs_ram(String memory) {
    return 'Bot-Prozess RAM: $memory';
  }

  @override
  String bot_logs_ram_estimated(String memory) {
    return 'Geschätzter Bot-RAM: $memory';
  }

  @override
  String get bot_logs_raw_mode => 'Kompakte Rohprotokolle';

  @override
  String get bot_logs_rich_mode => 'Reichhaltig formatierte Protokolle';

  @override
  String get bot_logs_show_all => 'Alle anzeigen';

  @override
  String get bot_logs_show_less => 'Weniger anzeigen';

  @override
  String get bot_logs_show_more => 'Mehr anzeigen';

  @override
  String bot_logs_show_n(int count) {
    return '$count Protokolle anzeigen';
  }

  @override
  String get bot_logs_title => 'Bot-Protokolle';

  @override
  String get bot_offline_token_desc =>
      'Token ungültig oder fehlt. Geben Sie ein neues Discord-Bot-Token ein, um die Verbindung wiederherzustellen.';

  @override
  String get bot_settings_activity_state_label => 'Aktivitätsstatus (optional)';

  @override
  String get bot_settings_activity_url_label => 'Stream-URL (für Streaming)';

  @override
  String get bot_settings_add_status => 'Aktivität hinzufügen';

  @override
  String get bot_settings_app_flags => 'Anwendungs-Flags';

  @override
  String get bot_settings_avatar_clear_selection => 'Auswahl aufheben';

  @override
  String get bot_settings_avatar_local_path => 'Lokaler Dateipfad für Avatar';

  @override
  String get bot_settings_avatar_path_hint => '/absoluter/pfad/zu/avatar.png';

  @override
  String get bot_settings_avatar_preview_error => 'Bildvorschau nicht möglich';

  @override
  String get bot_settings_avatar_preview_label => 'Avatar-Vorschau';

  @override
  String bot_settings_avatar_selected_file(String path) {
    return 'Ausgewählte Datei: $path';
  }

  @override
  String bot_settings_avatar_unsupported_format(String ext, String formats) {
    return 'Nicht unterstütztes Avatar-Format: $ext. Unterstützte Formate: $formats.';
  }

  @override
  String get bot_settings_browse => 'Durchsuchen';

  @override
  String get bot_settings_cancel_token_edit_btn =>
      'Token-Bearbeitung abbrechen';

  @override
  String get bot_settings_danger_zone => 'Gefahrenzone';

  @override
  String get bot_settings_delete_bot => 'Bot löschen';

  @override
  String get bot_settings_delete_bot_btn => 'Endgültig löschen';

  @override
  String get bot_settings_delete_bot_desc =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Alle lokalen Daten und remote Konfigurationen werden dauerhaft entfernt.';

  @override
  String bot_settings_delete_desc(String id) {
    return 'Sind Sie sicher, dass Sie den Bot $id löschen möchten? Alle Daten gehen verloren.';
  }

  @override
  String get bot_settings_delete_title => 'Löschen bestätigen';

  @override
  String get bot_settings_edit_token_btn => 'Token bearbeiten';

  @override
  String get bot_settings_export_import => 'Export / Import';

  @override
  String get bot_settings_export_import_desc =>
      'Exportieren oder importieren Sie Ihre Bot-Konfiguration als ZIP-Datei.';

  @override
  String get bot_settings_gateway_intents => 'Gateway-Intents-Konfiguration';

  @override
  String get bot_settings_gateway_intents_desc =>
      'Wählen Sie aus, welche Intents Ihr Bot benötigt. Konfigurieren Sie diese im Discord Developer Portal.';

  @override
  String get bot_settings_intents_saved => 'Intents erfolgreich gespeichert';

  @override
  String get bot_settings_no_activities => 'Keine Aktivitäten konfiguriert';

  @override
  String get bot_settings_presence_dnd => 'Bitte nicht stören';

  @override
  String get bot_settings_presence_idle => 'Abwesend';

  @override
  String get bot_settings_presence_invisible => 'Unsichtbar';

  @override
  String get bot_settings_presence_online => 'Online';

  @override
  String get bot_settings_presence_status_label => 'Präsenz';

  @override
  String get bot_settings_presence_status_title => 'Bot-Präsenzstatus';

  @override
  String get bot_settings_profile_saved =>
      'Profil/Status erfolgreich angewendet';

  @override
  String get bot_settings_profile_title => 'Bot-Profil';

  @override
  String get bot_settings_remove_status => 'Aktivität entfernen';

  @override
  String get bot_settings_save_intents_btn => 'Intents speichern';

  @override
  String get bot_settings_save_intents_caption =>
      'Dies aktualisiert nur die Gateway-Intents-Konfiguration.';

  @override
  String get bot_settings_save_profile_caption =>
      'Dies übernimmt Benutzername/Avatar sofort und speichert die Statusrotation.';

  @override
  String get bot_settings_save_profile_status_btn =>
      'Profil und Status speichern';

  @override
  String get bot_settings_save_success =>
      'Einstellungen erfolgreich gespeichert';

  @override
  String get bot_settings_save_token_btn => 'Token und Intents speichern';

  @override
  String get bot_settings_save_token_caption =>
      'Token-Änderungen sind geschützt. Klicken Sie zuerst auf \"Token bearbeiten\" und speichern Sie dann.';

  @override
  String get bot_settings_save_token_first =>
      'Bitte speichern Sie zuerst das Token, bevor Sie Profil/Status-Änderungen vornehmen.';

  @override
  String get bot_settings_save_token_only_btn => 'Token speichern';

  @override
  String bot_settings_status_item_title(int index) {
    return 'Aktivität $index';
  }

  @override
  String get bot_settings_status_max_interval => 'Max. Intervall (s)';

  @override
  String get bot_settings_status_min_interval => 'Min. Intervall (s)';

  @override
  String get bot_settings_status_rotation_desc =>
      'Fügen Sie eine oder mehrere Aktivitäten hinzu. Jede Aktivität benötigt einen Typ, einen Namen und ein Min/Max-Intervall (Sekunden).';

  @override
  String get bot_settings_status_rotation_title => 'Aktivitäten-Rotation';

  @override
  String get bot_settings_status_text_label => 'Aktivitätsname';

  @override
  String get bot_settings_status_type_competing => 'Tritt an';

  @override
  String get bot_settings_status_type_label => 'Typ';

  @override
  String get bot_settings_status_type_listening => 'Hört zu';

  @override
  String get bot_settings_status_type_playing => 'Spielt';

  @override
  String get bot_settings_status_type_streaming => 'Streamt';

  @override
  String get bot_settings_status_type_watching => 'Schaut zu';

  @override
  String get bot_settings_title => 'Bot anpassen / Profil';

  @override
  String get bot_settings_token_hidden_desc =>
      'Die Token-Eingabe ist zur Sicherheit standardmäßig ausgeblendet.';

  @override
  String get bot_settings_token_hint => 'Geben Sie hier Ihr Bot-Token ein';

  @override
  String get bot_settings_token_mismatch_confirm => 'Token trotzdem ersetzen';

  @override
  String bot_settings_token_mismatch_content(String newId, String oldId) {
    return 'Dieses Token gehört zum Bot $newId, aber die aktuellen Daten sind für Bot $oldId. Befehle und Einstellungen stimmen möglicherweise nicht überein. Trotzdem fortfahren?';
  }

  @override
  String get bot_settings_token_mismatch_title => 'Anderer Bot erkannt';

  @override
  String get bot_settings_token_required => 'Bot-Token ist erforderlich.';

  @override
  String get bot_settings_token_saved => 'Token erfolgreich gespeichert';

  @override
  String get bot_settings_token_title => 'Bot-Token';

  @override
  String get bot_settings_update_token => 'Bot-Token aktualisieren';

  @override
  String get bot_settings_username_hint =>
      'Leer lassen, um den aktuellen Benutzernamen zu behalten';

  @override
  String get bot_settings_username_override => 'Benutzernamen überschreiben';

  @override
  String get bot_settings_workflow_docs => 'Dokumentationszentrum';

  @override
  String get bot_settings_workflow_docs_desc =>
      'Zentrale Dokumentation für Befehle, Workflows, Laufzeitvariablen und Ausführungsverhalten.';

  @override
  String get bot_stats_collecting => 'Wird gesammelt…';

  @override
  String get bot_stats_cpu => 'Bot-Prozess CPU';

  @override
  String get bot_stats_notes =>
      'Hinweise: CPU verfügbar unter Android/Linux. Speicher = Bot-Datendateien in der App.';

  @override
  String get bot_stats_ram_estimated => 'Nur Bot-RAM (geschätzt)';

  @override
  String get bot_stats_ram_process => 'Bot-Prozess RAM';

  @override
  String get bot_stats_source_local_hosting => 'Quelle: Lokales Hosting';

  @override
  String get bot_stats_source_runner_api => 'Quelle: Runner-API';

  @override
  String get bot_stats_storage => 'Bot-Speicher (App-Daten)';

  @override
  String get bot_stats_title => 'Bot-Statistiken';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get close => 'Schließen';

  @override
  String get cmd_bdfd_autocomplete_hint =>
      'Tippen Sie \$ und schreiben Sie einen Funktionsnamen, um schnelle Skriptvorschläge zu erhalten.';

  @override
  String get cmd_bdfd_autocomplete_title => 'BDFD-Präfix-Autovervollständigung';

  @override
  String get cmd_bdfd_diagnostics_clean =>
      'Kein Problem im aktuellen Skript erkannt.';

  @override
  String get cmd_bdfd_diagnostics_error => 'Fehler';

  @override
  String get cmd_bdfd_diagnostics_title => 'BDFD-Diagnose';

  @override
  String get cmd_bdfd_diagnostics_warning => 'Warnung';

  @override
  String get cmd_bdfd_script_empty_error =>
      'Der BDFD-Skriptkörper darf nicht leer sein.';

  @override
  String get cmd_bdfd_script_hint =>
      '\$nomention\\n\$if[\$hasPerms[\$authorID;administrator]==true]\\nHallo von Bot Creator';

  @override
  String get cmd_bdfd_script_label => 'BDFD-Skriptkörper';

  @override
  String get cmd_bdfd_script_validation_error =>
      'Dieses BDFD-Skript enthält noch Diagnosen:';

  @override
  String get cmd_create_tooltip => 'Befehl erstellen';

  @override
  String get cmd_dart_diagnostics_clean =>
      'Kein Problem im aktuellen Dart-Skript erkannt.';

  @override
  String get cmd_dart_diagnostics_error => 'Fehler';

  @override
  String get cmd_dart_diagnostics_title => 'Dart-Diagnose';

  @override
  String get cmd_dart_diagnostics_warning => 'Warnung';

  @override
  String get cmd_dart_script_hint => 'return \"Hallo von Dart Direct\";';

  @override
  String get cmd_dart_script_label => 'Dart-Skriptkörper';

  @override
  String get cmd_delete_tooltip => 'Befehl löschen';

  @override
  String get cmd_editor_mode_advanced => 'Erweiterter Modus';

  @override
  String get cmd_editor_mode_advanced_desc =>
      'Vollständiger Editor mit benutzerdefinierter Antwort, Optionen und Aktions-Builder.';

  @override
  String get cmd_editor_mode_locked =>
      'Der erweiterte Modus ist für diesen Befehl gesperrt.';

  @override
  String get cmd_editor_mode_simple => 'Vereinfachter Modus';

  @override
  String get cmd_editor_mode_simple_desc =>
      'Erstellen Sie schnell einen Befehl mit geführten Optionen und vorkonfigurierten Aktionen.';

  @override
  String get cmd_editor_mode_switch_adv => 'In den erweiterten Modus wechseln';

  @override
  String get cmd_editor_mode_switch_adv_confirm => 'Wechseln';

  @override
  String get cmd_editor_mode_switch_adv_content =>
      'Dieser Wechsel ist für diesen Befehl endgültig. Sie können nicht zum vereinfachten Modus zurückkehren.';

  @override
  String get cmd_editor_mode_switch_adv_title =>
      'In den erweiterten Modus wechseln?';

  @override
  String get cmd_editor_mode_title => 'Bearbeitungsmodus';

  @override
  String get cmd_error_fill_fields => 'Bitte füllen Sie alle Felder aus';

  @override
  String get cmd_execution_mode_bdfd => 'BDFD-Skriptmodus';

  @override
  String get cmd_execution_mode_bdfd_desc =>
      'Schreiben Sie den Befehlskörper als BDFD-Skript, während die Befehlsdefinition visuell bleibt.';

  @override
  String get cmd_execution_mode_bdfd_note =>
      'Das Skript wird in interne Aktionen kompiliert. Diagnosen werden während der Bearbeitung angezeigt; ungültige Skripte schlagen bei der Ausführung des Befehls fehl.';

  @override
  String get cmd_execution_mode_dart => 'Dart Direct-Modus';

  @override
  String get cmd_execution_mode_dart_desc =>
      'Schreiben Sie den Befehlskörper direkt in Dart mit Laufzeitdiagnose.';

  @override
  String get cmd_execution_mode_dart_note =>
      'Dart-Code wird zur Laufzeit durch die sandboxed Engine kompiliert. Halten Sie Skripte deterministisch und geben Sie bei Bedarf einen Wert zurück.';

  @override
  String get cmd_execution_mode_desc =>
      'Befehlsmetadaten bleiben im visuellen Builder. Wählen Sie aus, wie der Befehlskörper ausgeführt werden soll.';

  @override
  String get cmd_execution_mode_title => 'Ausführungsmodus';

  @override
  String get cmd_execution_mode_workflow => 'Workflow-Modus';

  @override
  String get cmd_execution_mode_workflow_desc =>
      'Verwenden Sie die vorhandene visuelle Antwort und den Aktions-Builder.';

  @override
  String get cmd_execution_mode_workflow_note =>
      'Der Workflow-Modus ist der aktuelle Produktionspfad und bleibt vollständig unterstützt.';

  @override
  String get cmd_migrate_bdfd_to_dart_action => 'Migrieren';

  @override
  String get cmd_migrate_bdfd_to_dart_desc =>
      'Generieren Sie ein Dart-Migrationsgerüst aus Ihrem aktuellen BDFD-Skript.';

  @override
  String get cmd_offline_incomplete_warning =>
      'Dieser Befehl konnte nicht vollständig geladen werden (offline oder Token ungültig). Verbinden Sie ein gültiges Token, um ihn zu bearbeiten.';

  @override
  String get cmd_show_variables => 'Variablendokumentation öffnen';

  @override
  String get cmd_simple_action_add_role => 'Rolle hinzufügen';

  @override
  String get cmd_simple_action_add_role_desc =>
      'Geben Sie dem ausgewählten /benutzer die ausgewählte /rolle.';

  @override
  String get cmd_simple_action_ban => 'Benutzer bannen';

  @override
  String get cmd_simple_action_ban_delete_days_hint =>
      '0 bis 7 Tage der letzten Nachrichten, die gelöscht werden sollen';

  @override
  String get cmd_simple_action_ban_delete_days_label =>
      'Tage für Nachrichtenlöschung bei Bann';

  @override
  String get cmd_simple_action_ban_desc =>
      'Bannen Sie den ausgewählten /benutzer vom Server.';

  @override
  String get cmd_simple_action_create_invite => 'Einladung erstellen';

  @override
  String get cmd_simple_action_create_invite_desc =>
      'Erstellen Sie eine Einladung für den aktuellen Kanal oder einen optionalen /kanal.';

  @override
  String get cmd_simple_action_create_poll => 'Umfrage erstellen';

  @override
  String get cmd_simple_action_create_poll_desc =>
      'Erstellen Sie eine Umfrage mit einer dynamischen /frage und festen Antwortmöglichkeiten.';

  @override
  String get cmd_simple_action_delete => 'Nachrichten löschen';

  @override
  String get cmd_simple_action_delete_default_count_hint =>
      'Wird verwendet, wenn /anzahl nicht angegeben ist';

  @override
  String get cmd_simple_action_delete_default_count_label =>
      'Standard-Löschzahl';

  @override
  String get cmd_simple_action_delete_desc =>
      'Löschen Sie Nachrichten im aktuellen Kanal (optional /anzahl).';

  @override
  String get cmd_simple_action_kick => 'Benutzer kicken';

  @override
  String get cmd_simple_action_kick_desc =>
      'Kicken Sie den ausgewählten /benutzer vom Server.';

  @override
  String get cmd_simple_action_mute => 'Benutzer stummschalten';

  @override
  String get cmd_simple_action_mute_desc =>
      'Schalten Sie den ausgewählten /benutzer vorübergehend stumm.';

  @override
  String get cmd_simple_action_mute_duration_hint =>
      'Beispiele: 10m, 2h, 1d oder rohe Sekunden';

  @override
  String get cmd_simple_action_mute_duration_label => 'Stummschaltungsdauer';

  @override
  String get cmd_simple_action_pin => 'Nachricht anpinnen';

  @override
  String get cmd_simple_action_pin_desc =>
      'Pinnen Sie eine Nachricht im aktuellen Kanal unter Verwendung von /nachrichten_id.';

  @override
  String get cmd_simple_action_reason_hint =>
      'Optionaler Grund, der von Moderationsaktionen geteilt wird';

  @override
  String get cmd_simple_action_reason_label => 'Audit-Log-Grund';

  @override
  String get cmd_simple_action_remove_role => 'Rolle entfernen';

  @override
  String get cmd_simple_action_remove_role_desc =>
      'Entfernen Sie die ausgewählte /rolle vom ausgewählten /benutzer.';

  @override
  String get cmd_simple_action_send_message => 'Nachricht senden';

  @override
  String get cmd_simple_action_send_message_desc =>
      'Senden Sie eine zusätzliche Nachricht im aktuellen Kanal.';

  @override
  String get cmd_simple_action_send_message_hint =>
      'Nachricht, die von der Aktion \'Nachricht senden\' gesendet wird';

  @override
  String get cmd_simple_action_send_message_label => 'Aktionsnachricht';

  @override
  String get cmd_simple_action_unban => 'Benutzer entbannen';

  @override
  String get cmd_simple_action_unban_desc =>
      'Entbannen Sie einen Benutzer mit einer angegebenen /benutzer_id Zeichenfolge.';

  @override
  String get cmd_simple_action_unmute => 'Benutzer lautschalten';

  @override
  String get cmd_simple_action_unmute_desc =>
      'Entfernen Sie die Zeitüberschreitung des ausgewählten /benutzer.';

  @override
  String get cmd_simple_action_unpin => 'Nachricht lospinnen';

  @override
  String get cmd_simple_action_unpin_desc =>
      'Lospinnen Sie eine Nachricht im aktuellen Kanal unter Verwendung von /nachrichten_id.';

  @override
  String get cmd_simple_actions_desc =>
      'Wählen Sie aus, was dieser Befehl tun soll. Optionen werden automatisch generiert.';

  @override
  String get cmd_simple_actions_title => 'Vereinfachte Aktionen';

  @override
  String get cmd_simple_conflict_ban_unban =>
      'Benutzer bannen und Benutzer entbannen können im vereinfachten Modus nicht zusammen aktiviert werden.';

  @override
  String get cmd_simple_conflict_mute_unmute =>
      'Benutzer stummschalten und Benutzer lautschalten können im vereinfachten Modus nicht zusammen aktiviert werden.';

  @override
  String get cmd_simple_conflict_pin_unpin =>
      'Nachricht anpinnen und Nachricht lospinnen können im vereinfachten Modus nicht zusammen aktiviert werden.';

  @override
  String get cmd_simple_execution_desc =>
      'Feinabstimmung der generierten Aktionen, ohne den vereinfachten Modus zu verlassen.';

  @override
  String get cmd_simple_execution_title => 'Ausführungseinstellungen';

  @override
  String get cmd_simple_generated_none =>
      'Noch keine Optionen generiert. Wählen Sie mindestens eine Aktion aus.';

  @override
  String get cmd_simple_generated_options => 'Generierte Befehlsoptionen';

  @override
  String get cmd_simple_group_messages_desc =>
      'Nachrichten- und Kanalaktionen, die im aktuellen Kontext funktionieren.';

  @override
  String get cmd_simple_group_messages_title => 'Nachrichten';

  @override
  String get cmd_simple_group_moderation_desc =>
      'Mitglieder- und Moderationsaktionen mit geführten Optionen.';

  @override
  String get cmd_simple_group_moderation_title => 'Moderation';

  @override
  String get cmd_simple_group_utility_desc =>
      'Hilfreiche Extras wie Einladungen und Umfragen.';

  @override
  String get cmd_simple_group_utility_title => 'Dienstprogramme';

  @override
  String get cmd_simple_invite_max_age_hint =>
      '0 für kein Ablaufdatum, bis zu 604800';

  @override
  String get cmd_simple_invite_max_age_invalid =>
      'Die Gültigkeitsdauer der Einladung muss eine Zahl zwischen 0 und 604800 Sekunden sein.';

  @override
  String get cmd_simple_invite_max_age_label =>
      'Gültigkeitsdauer der Einladung (Sekunden)';

  @override
  String get cmd_simple_invite_max_uses_hint =>
      '0 für unbegrenzte Verwendungen';

  @override
  String get cmd_simple_invite_max_uses_invalid =>
      'Die maximale Anzahl der Verwendungen muss eine Zahl zwischen 0 und 1000000 sein.';

  @override
  String get cmd_simple_invite_max_uses_label => 'Max. Verwendungen';

  @override
  String get cmd_simple_invite_settings_desc =>
      'Standardwerte für die generierte Aktion \'Einladung erstellen\'.';

  @override
  String get cmd_simple_invite_settings_title => 'Einladungseinstellungen';

  @override
  String get cmd_simple_invite_temporary_desc =>
      'Mitglieder werden entfernt, wenn sie gehen, bevor sie eine Rolle erhalten.';

  @override
  String get cmd_simple_invite_temporary_label => 'Temporäre Mitgliedschaft';

  @override
  String get cmd_simple_invite_unique_desc =>
      'Immer eine neue Einladung erstellen, statt eine vorhandene wiederzuverwenden.';

  @override
  String get cmd_simple_invite_unique_label =>
      'Einzigartige Einladung erzwingen';

  @override
  String get cmd_simple_option_channel => '/kanal (Kanal)';

  @override
  String get cmd_simple_option_channel_desc =>
      'Optionales Kanal-Override für die Einladungserstellung';

  @override
  String get cmd_simple_option_count => '/anzahl (Ganzzahl)';

  @override
  String get cmd_simple_option_count_desc =>
      'Anzahl der zu löschenden Nachrichten';

  @override
  String get cmd_simple_option_message_id => '/nachrichten_id (Text)';

  @override
  String get cmd_simple_option_message_id_desc => 'Ziel-Nachrichten-ID';

  @override
  String get cmd_simple_option_question => '/frage (Text)';

  @override
  String get cmd_simple_option_question_desc => 'Umfragefrage';

  @override
  String get cmd_simple_option_role => '/rolle (Rolle)';

  @override
  String get cmd_simple_option_role_desc => 'Zielrolle';

  @override
  String get cmd_simple_option_user => '/benutzer (Benutzer)';

  @override
  String get cmd_simple_option_user_desc => 'Zielbenutzer';

  @override
  String get cmd_simple_option_user_id => '/benutzer_id (Text)';

  @override
  String get cmd_simple_option_user_id_desc => 'Benutzer-ID zum Entbannen';

  @override
  String get cmd_simple_poll_answers_hint =>
      'Eine Antwort pro Zeile oder durch Kommas getrennt. Mindestens 2, maximal 10.';

  @override
  String get cmd_simple_poll_answers_invalid =>
      'Die Umfrageantworten müssen zwischen 2 und 10 nicht leere Auswahlmöglichkeiten enthalten.';

  @override
  String get cmd_simple_poll_answers_label => 'Umfrageantworten';

  @override
  String get cmd_simple_poll_duration_hint => 'Von 1 bis 168 Stunden';

  @override
  String get cmd_simple_poll_duration_invalid =>
      'Die Umfragedauer muss eine Zahl zwischen 1 und 168 Stunden sein.';

  @override
  String get cmd_simple_poll_duration_label => 'Umfragedauer (Stunden)';

  @override
  String get cmd_simple_poll_multiselect_desc =>
      'Benutzer können mehr als eine Antwort auswählen.';

  @override
  String get cmd_simple_poll_multiselect_label =>
      'Mehrfache Antworten erlauben';

  @override
  String get cmd_simple_poll_settings_desc =>
      'Standardwerte für die generierte Aktion \'Umfrage erstellen\'.';

  @override
  String get cmd_simple_poll_settings_title => 'Umfrageeinstellungen';

  @override
  String get cmd_simple_response_desc =>
      'Nachricht, die an den Benutzer zurückgesendet wird, nachdem die Aktionen ausgeführt wurden.';

  @override
  String get cmd_simple_response_embeds_desc =>
      'Optionale Embeds, die mit der endgültigen Antwort gesendet werden.';

  @override
  String get cmd_simple_response_embeds_title => 'Antwort-Embeds';

  @override
  String get cmd_simple_response_hint => 'Fertig ✅';

  @override
  String get cmd_simple_response_title => 'Endgültige Antwort';

  @override
  String get cmd_simple_response_visibility_ephemeral =>
      'Ephemeral (nur für dich)';

  @override
  String get cmd_simple_response_visibility_label => 'Sichtbarkeit der Antwort';

  @override
  String get cmd_simple_response_visibility_public => 'Öffentlich';

  @override
  String get cmd_simple_send_message_required =>
      'Bitte füllen Sie die Aktionsnachricht aus, bevor Sie speichern.';

  @override
  String get cmd_variables_title => 'Befehlsvariablen';

  @override
  String get command_awaited_error => 'Fehler';

  @override
  String get command_awaited_filter_hint =>
      'Beispiel: <numeric> oder <ja/nein/abbrechen>';

  @override
  String get command_awaited_filter_label => 'Filter (optional)';

  @override
  String get command_awaited_name_hint => 'Beispiel: sag';

  @override
  String get command_awaited_name_label => 'Name des erwarteten Callbacks';

  @override
  String get command_awaited_preset_active =>
      'Voreinstellung für erwarteten Callback aktiv';

  @override
  String get command_awaited_preset_button =>
      'Voreinstellung für erwarteten Callback verwenden';

  @override
  String get command_awaited_preset_desc =>
      'Der Befehlsname wird für Sie generiert und als interner Legacy-Callback gespeichert.';

  @override
  String get command_awaited_success => 'Erfolg';

  @override
  String get command_context_bot_dm => 'Bot-DM';

  @override
  String get command_context_group_dm => 'Gruppen-DM / Sonstiges';

  @override
  String get command_context_guild => 'Gilde';

  @override
  String get command_description_length =>
      'Die Befehlsbeschreibung darf höchstens 100 Zeichen lang sein';

  @override
  String get command_description_required =>
      'Bitte geben Sie eine Befehlsbeschreibung ein';

  @override
  String get command_edit_raw_name => 'Rohen Namen bearbeiten';

  @override
  String get command_error_missing_bot_id =>
      'Bot-ID für lokales Speichern des Befehls fehlt.';

  @override
  String get command_execution_error =>
      'Beim Ausführen dieses Befehls ist ein Fehler aufgetreten.';

  @override
  String get command_export_tooltip => 'Befehlsnutzlast exportieren';

  @override
  String get command_import_tooltip => 'Befehlsnutzlast importieren';

  @override
  String get command_info_desc => 'Grundlegende Metadaten und Verfügbarkeit';

  @override
  String get command_info_title => 'Befehlsinfo';

  @override
  String get command_integration_guild => 'Gilden-Installation';

  @override
  String get command_integration_label =>
      'Wo dieser Befehl verwendet werden kann';

  @override
  String get command_integration_user => 'Benutzer-Installation';

  @override
  String get command_legacy_mode_subtitle =>
      'Verwendet positionsabhängige Optionen (Beispiel: !config #kanal).';

  @override
  String get command_legacy_mode_title =>
      'Legacy-Modus für diesen Befehl aktivieren';

  @override
  String get command_legacy_prefix_desc =>
      'Behandelt Befehle aus messageCreate unter Verwendung von <präfix><befehl>.';

  @override
  String get command_legacy_prefix_title => 'Legacy-Präfix-Modus';

  @override
  String get command_legacy_preset_desc =>
      'Generieren Sie einen internen Auslöser für einen erwarteten Callback und schalten Sie diesen Befehl auf das erforderliche lokale Legacy-Setup um.';

  @override
  String get command_legacy_preset_title => 'Legacy-Voreinstellung';

  @override
  String get command_legacy_response_label => 'Legacy-Antwortmodus';

  @override
  String get command_modal_disabled_legacy =>
      'Modals sind im Legacy-Modus deaktiviert.';

  @override
  String get command_name_generated =>
      'Generiert durch die Voreinstellung für erwartete Callbacks.';

  @override
  String get command_name_label => 'Name';

  @override
  String get command_not_found => 'Befehl nicht gefunden';

  @override
  String get command_options_legacy_params =>
      'Legacy positionsabhängige Parameter (sortiert: erforderlich, dann optional)';

  @override
  String get command_options_slash_params => 'Slash-Befehl-Parameter';

  @override
  String get command_options_title => 'Befehlsoptionen';

  @override
  String get command_payload_hint => 'Befehlsnutzlast';

  @override
  String get command_permissions_admin_warning =>
      'Administrator ausgewählt: Dies umgeht andere Berechtigungsprüfungen.';

  @override
  String get command_permissions_bitfield =>
      'Berechnetes Berechtigungs-Bitfeld';

  @override
  String get command_permissions_bitfield_helper =>
      'Automatisch aus den ausgewählten Berechtigungen berechnet.';

  @override
  String command_permissions_count(int count) {
    return '$count Berechtigung(en) ausgewählt';
  }

  @override
  String get command_permissions_label =>
      'Standard-Mitgliedsberechtigungen (optional)';

  @override
  String get command_permissions_none =>
      'Keine Auswahl (jeder kann den Befehl verwenden)';

  @override
  String get command_permissions_tip =>
      'Tipp: Lassen Sie alle deaktiviert, um den Befehl standardmäßig für jeden verfügbar zu machen.';

  @override
  String get command_permissions_title => 'Berechtigungen auswählen';

  @override
  String command_permissions_unknown_bits(String bits) {
    return 'Warnung: Unbekannte Berechtigungsbits aus gespeicherten Daten erkannt und beibehalten: $bits';
  }

  @override
  String get command_prefix_helper =>
      'Unterstützt Vorlagen und Geltungsbereichsvariablen (bc_ optional). Beispiel: ((guild.prefix | user.prefix | !))';

  @override
  String get command_prefix_override_hint =>
      'Beispiel: ? oder ((guild.prefix | !))';

  @override
  String get command_prefix_override_label =>
      'Präfix-Überschreibung (optional)';

  @override
  String get command_response_mode_channel => 'message.channel.send';

  @override
  String get command_response_mode_reply => 'message.reply';

  @override
  String get command_scope_label => 'Geltungsbereich des Befehls (Kontexte)';

  @override
  String get command_subcommand_workflow_desc =>
      'Wählen Sie aus, welchen Unterbefehl Sie konfigurieren.';

  @override
  String get command_subcommand_workflow_title => 'Unterbefehl-Workflow';

  @override
  String command_sync_failed_local(String error) {
    return 'Lokal gespeichert. Discord-Synchronisierung fehlgeschlagen: $error';
  }

  @override
  String get command_target_subcommand => 'Ziel-Unterbefehl';

  @override
  String get command_type_label => 'Befehlstyp';

  @override
  String get command_type_legacy => 'Legacy-Befehl';

  @override
  String get command_type_locked =>
      'Der Befehlstyp kann nach der Erstellung nicht mehr geändert werden.';

  @override
  String get command_type_message => 'Nachrichtenbefehl';

  @override
  String get command_type_slash => 'Slash-Befehl';

  @override
  String get command_type_user => 'Benutzerbefehl';

  @override
  String get command_unsaved_confirm =>
      'Sie haben ungespeicherte Änderungen. Diese verwerfen?';

  @override
  String get command_unsaved_keep => 'Weiter bearbeiten';

  @override
  String get command_unsaved_title => 'Ungespeicherte Änderungen';

  @override
  String get commands_all_folders => 'Alle Ordner';

  @override
  String get commands_create_button => 'Befehl erstellen';

  @override
  String get commands_create_folder => 'Ordner erstellen';

  @override
  String commands_create_from_query(String query) {
    return 'Befehl \"$query\" erstellen';
  }

  @override
  String get commands_delete_folder => 'Ordner löschen';

  @override
  String get commands_delete_folder_desc =>
      'Die Befehle in diesem Ordner werden nicht gelöscht, nur aus dem Ordner entfernt.';

  @override
  String get commands_empty => 'Keine Befehle gefunden';

  @override
  String commands_error(String error) {
    return 'Fehler: $error';
  }

  @override
  String get commands_filter_legacy_local => 'Legacy lokal';

  @override
  String get commands_filter_template => 'Vorlage';

  @override
  String get commands_filter_type_label => 'Typ';

  @override
  String get commands_folder_hint => 'Optionaler Ordnername';

  @override
  String get commands_folder_label => 'Ordner';

  @override
  String get commands_move_to_folder => 'In Ordner verschieben';

  @override
  String get commands_new_folder_hint => 'Neuer Ordnername';

  @override
  String get commands_no_folder => 'Kein Ordner';

  @override
  String get commands_no_match_filters =>
      'Keine Befehle entsprechen den aktuellen Filtern.';

  @override
  String get commands_remove_from_folder => 'Aus Ordner entfernen';

  @override
  String get commands_rename_folder => 'Ordner umbenennen';

  @override
  String get commands_reorder_title => 'Befehle organisieren';

  @override
  String get commands_search_hint => 'Befehle suchen...';

  @override
  String get commands_tab => 'Befehle';

  @override
  String get commands_tab_short => 'Cmd';

  @override
  String get commands_title => 'Befehle';

  @override
  String get common_add_argument => 'Argument hinzufügen';

  @override
  String get common_add_option => 'Option hinzufügen';

  @override
  String get common_add_section => 'Abschnitt hinzufügen';

  @override
  String get common_all => 'Alle';

  @override
  String get common_apply => 'Anwenden';

  @override
  String get common_back => 'Zurück';

  @override
  String get common_bot => 'Bot';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_clear => 'Löschen';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_custom_id => 'Benutzerdefinierte ID';

  @override
  String get common_custom_id_required => 'Benutzerdefinierte ID *';

  @override
  String get common_default => 'Standard';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_description => 'Beschreibung';

  @override
  String get common_disabled => 'Deaktiviert';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_enabled => 'Aktiviert';

  @override
  String get common_import => 'Importieren';

  @override
  String get common_key => 'Schlüssel';

  @override
  String get common_label => 'Bezeichnung';

  @override
  String get common_manage_workflows => 'Workflows verwalten';

  @override
  String get common_move_down => 'Nach unten verschieben';

  @override
  String get common_move_up => 'Nach oben verschieben';

  @override
  String get common_name => 'Name';

  @override
  String get common_next => 'Weiter';

  @override
  String get common_none => 'Keine';

  @override
  String get common_ok => 'OK';

  @override
  String get common_operator => 'Operator';

  @override
  String get common_pick => 'Auswählen';

  @override
  String get common_placeholder => 'Platzhalter';

  @override
  String get common_refresh => 'Aktualisieren';

  @override
  String get common_refresh_workflows => 'Workflows aktualisieren';

  @override
  String get common_remove => 'Entfernen';

  @override
  String get common_required => 'Erforderlich';

  @override
  String get common_retry => 'Wiederholen';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_search => 'Suchen';

  @override
  String get common_static_options => 'Statische Optionen';

  @override
  String get common_style => 'Stil';

  @override
  String get common_type => 'Typ';

  @override
  String get common_url => 'URL';

  @override
  String get common_value => 'Wert';

  @override
  String get common_workflow => 'Workflow';

  @override
  String get component_accent_color => 'Akzentfarbe (Hex, z. B. FF0000)';

  @override
  String get component_add_checkbox_option => 'Checkbox-Option hinzufügen';

  @override
  String get component_add_child => 'Unterkomponente hinzufügen';

  @override
  String get component_add_media_item => 'Medienelement hinzufügen';

  @override
  String get component_add_radio_option => 'Radio-Option hinzufügen';

  @override
  String get component_add_root => 'Stammkomponente hinzufügen';

  @override
  String get component_add_text_display => 'Textanzeige hinzufügen';

  @override
  String get component_add_tooltip => 'Komponente hinzufügen';

  @override
  String get component_block_label_style => 'Stil';

  @override
  String get component_block_workflow => 'Workflow';

  @override
  String get component_checkbox_options => 'Checkbox-Optionen';

  @override
  String get component_checked_by_default => 'Standardmäßig ausgewählt';

  @override
  String get component_choose_color => 'Farbe wählen';

  @override
  String get component_component_to_wrap => 'Komponente zum Umschließen:';

  @override
  String get component_custom_id => 'Benutzerdefinierte ID';

  @override
  String get component_custom_id_required => 'Benutzerdefinierte ID *';

  @override
  String get component_default_choice_label => 'Auswahl';

  @override
  String get component_default_option_label => 'Option';

  @override
  String get component_empty_option => 'Leer';

  @override
  String get component_file_url => 'Datei-URL';

  @override
  String get component_label => 'Bezeichnung';

  @override
  String get component_label_title => 'Titel der Bezeichnung';

  @override
  String get component_markdown_content => 'Markdown-Inhalt';

  @override
  String get component_max_selections => 'Maximale Auswahl';

  @override
  String get component_media_url => 'Bild- / Video-URL';

  @override
  String get component_media_urls => 'Medien-URLs';

  @override
  String get component_min_selections => 'Minimale Auswahl';

  @override
  String get component_new_checkbox => 'Neue Checkbox';

  @override
  String get component_new_option => 'Neue Option';

  @override
  String get component_new_radio => 'Neue Radio-Option';

  @override
  String get component_not_implemented => 'Editor noch nicht implementiert';

  @override
  String get component_on_click_workflow => 'Bei Klick, der Workflow';

  @override
  String get component_on_select_workflow => 'Bei Auswahl, der Workflow';

  @override
  String get component_options => 'Optionen';

  @override
  String get component_pick_accent_color => 'Akzentfarbe wählen';

  @override
  String get component_placeholder => 'Platzhalter';

  @override
  String get component_radio_options => 'Radio-Optionen';

  @override
  String get component_remove_confirm =>
      'Diese Komponente wird aus dem Layout entfernt. Fortfahren?';

  @override
  String get component_remove_row_title => 'Aktionszeile entfernen';

  @override
  String get component_remove_title => 'Komponente entfernen';

  @override
  String get component_section_accessory => 'Zusatzknoten (optional)';

  @override
  String get component_section_text_displays => 'Textanzeigen';

  @override
  String get component_selection_range => 'Auswahlbereich';

  @override
  String get component_spacing_large => 'Großer Abstand';

  @override
  String get component_spacing_small => 'Kleiner Abstand';

  @override
  String get component_style => 'Stil';

  @override
  String get component_thumbnail_url => 'Thumbnail-URL';

  @override
  String get component_unknown_component => 'Unbekannte Komponente';

  @override
  String get component_url => 'URL';

  @override
  String get component_validation_required => 'Erforderlich';

  @override
  String get component_value_hint => 'Komponentenwert Hinweis';

  @override
  String get component_visible_divider => 'Sichtbare Trennlinie';

  @override
  String get component_workflow_args_hint =>
      'Beispiel: ticketId = ((opts.ticket))';

  @override
  String get component_workflow_args_title => 'Argumente für Workflow-Aufruf';

  @override
  String get component_workflow_click_hint =>
      'Gespeicherter Workflow-Name zur Ausführung bei Klick';

  @override
  String get component_workflow_optional => 'Workflow aufrufen (optional)';

  @override
  String get component_workflow_select_hint =>
      'Gespeicherter Workflow-Name zur Ausführung bei Auswahl';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get copy => 'Kopieren';

  @override
  String get create => 'Erstellen';

  @override
  String get dart_editor_empty =>
      'Leeres Skript — fangen Sie an zu tippen, um Dart-Diagnosen zu sehen.';

  @override
  String get dart_editor_tap_hint => 'Tippen zum Öffnen des Dart-Editors';

  @override
  String get dart_editor_title => 'Dart-Editor';

  @override
  String dashboard_error(String error) {
    return 'Statistiken konnten nicht geladen werden: $error';
  }

  @override
  String get dashboard_error_rate => 'Fehlerrate';

  @override
  String get dashboard_execution_health_title => 'Ausführungsstatus';

  @override
  String dashboard_executions(int count) {
    return '$count Ausführungen';
  }

  @override
  String get dashboard_failed_commands => 'Fehlgeschlagen';

  @override
  String get dashboard_loading => 'Statistiken werden geladen...';

  @override
  String get dashboard_no_data =>
      'Noch keine Befehlsnutzusedaten. Starten Sie Ihren Bot, um mit der Verfolgung zu beginnen.';

  @override
  String get dashboard_p50_latency => 'Latenz p50';

  @override
  String get dashboard_p95_latency => 'Latenz p95';

  @override
  String get dashboard_period_24h => 'Letzte 24 Std.';

  @override
  String get dashboard_period_30d => 'Letzte 30 Tage';

  @override
  String get dashboard_period_7d => 'Letzte 7 Tage';

  @override
  String get dashboard_premium_analytics_desc =>
      'Schalten Sie Fehlerrate, Latenz-Perzentile und Locale-Einblicke frei.';

  @override
  String get dashboard_premium_analytics_title => 'Premium-Analysen';

  @override
  String get dashboard_refresh_sources_tooltip =>
      'Ausführungsserver aktualisieren';

  @override
  String get dashboard_requires_runner =>
      'Verbinden Sie sich mit einem Runner, um Befehlsnutzungsstatistiken zu sehen.';

  @override
  String dashboard_selected_period_total(int count) {
    return '$count im gewählten Zeitraum';
  }

  @override
  String get dashboard_single_runner_notice =>
      'Die angezeigten Statistiken stammen nur vom aktuell konfigurierten Runner. Wenn Sie Bots auf mehreren Runnern betreiben, ist diese Ansicht möglicherweise unvollständig.';

  @override
  String get dashboard_timeline => 'Nutzung im Zeitverlauf';

  @override
  String get dashboard_title => 'Dashboard';

  @override
  String get dashboard_top_commands => 'Top-Befehle';

  @override
  String get dashboard_top_locales => 'Top-Locales';

  @override
  String get dashboard_total => 'Befehle gesamt';

  @override
  String get dashboard_analysis_period => 'Analysezeitraum';

  @override
  String get debug_replay_clear => 'Replays löschen';

  @override
  String get debug_replay_clear_confirm =>
      'Alle aufgezeichneten Replays werden gelöscht. Fortfahren?';

  @override
  String get debug_replay_clear_title => 'Replays löschen';

  @override
  String get debug_replay_duration_label => 'DAUER';

  @override
  String get debug_replay_empty_capturing =>
      'Aufnahme läuft… Führen Sie einen Befehl aus, um ein Replay aufzuzeichnen.';

  @override
  String get debug_replay_empty_idle =>
      'Aufnahme ist aus. Aktivieren Sie sie und führen Sie einen Befehl aus, um ein Replay aufzuzeichnen.';

  @override
  String debug_replay_loop_info(int depth, int iteration) {
    return 'Schleifentiefe $depth, Iteration $iteration';
  }

  @override
  String get debug_replay_overview => 'Übersicht';

  @override
  String get debug_replay_pause => 'Pause';

  @override
  String get debug_replay_play => 'Abspielen';

  @override
  String get debug_replay_premium_desc =>
      'Zeichnen Sie Ihre Befehlsausführungen auf und spielen Sie sie Schritt für Schritt ab. Sehen Sie genau, was jede Aktion bewirkt hat, wie lange sie gedauert hat und wo Fehler aufgetreten sind.';

  @override
  String get debug_replay_premium_title => 'Visuelle Debugger-Wiedergabe';

  @override
  String get debug_replay_result_empty => '(kein Ergebnis)';

  @override
  String get debug_replay_result_label => 'ERGEBNIS';

  @override
  String get debug_replay_start_capture => 'Aufnahme aktivieren';

  @override
  String debug_replay_start_offset(int ms) {
    return '+$ms ms ab Start';
  }

  @override
  String get debug_replay_step_back => 'Vorheriger Schritt';

  @override
  String get debug_replay_step_first => 'Erster Schritt';

  @override
  String get debug_replay_step_forward => 'Nächster Schritt';

  @override
  String get debug_replay_step_last => 'Letzter Schritt';

  @override
  String get debug_replay_stop_capture => 'Aufnahme deaktivieren';

  @override
  String get debug_replay_title => 'Debugger-Replay';

  @override
  String get debug_replay_variables_empty => '(keine Variablen)';

  @override
  String get debug_replay_variables_label => 'VARIABLEN';

  @override
  String get delete => 'Löschen';

  @override
  String get doc_action_http_request_checklist_l1 =>
      'Legen Sie explizite Timeouts und Wiederholungsversuche in Ihrer Serviceschicht fest, wenn möglich.';

  @override
  String get doc_action_http_request_checklist_l2 =>
      'Speichern Sie API-Keys in globalen Variablen oder in einem sicheren Backend, kodieren Sie Tokens niemals fest.';

  @override
  String get doc_action_http_request_checklist_l3 =>
      'Validieren Sie den Statuscode und den Antwortkörper vor den nächsten Aktionen.';

  @override
  String get doc_action_http_request_section_checklist =>
      'Zuverlässigkeits-Checkliste';

  @override
  String get doc_action_http_request_subtitle =>
      'Führt einen externen HTTP-Aufruf innerhalb eines Workflows aus.';

  @override
  String get doc_action_http_request_summary =>
      'Verwenden Sie dies für Webhooks, interne APIs, Moderationsdienste, KI-Endpunkte und Integrationen.';

  @override
  String get doc_action_http_request_title => 'Aktion: httpRequest';

  @override
  String get doc_action_if_block_execution_l1 =>
      'Die Bedingung wird einmal ausgewertet.';

  @override
  String get doc_action_if_block_execution_l2 =>
      'Der erste passende Zweig wird ausgeführt: THEN, dann ELSE IF-Blöcke nacheinander, dann ELSE.';

  @override
  String get doc_action_if_block_execution_l3 =>
      'Verschachtelte Aktionen können runWorkflow, API-Aufrufe und Interaktionsantworten enthalten.';

  @override
  String get doc_action_if_block_section_execution => 'Ausführungsmodell';

  @override
  String get doc_action_if_block_subtitle =>
      'Verzweigt die Ausführung zwischen verschachtelten THEN, ELSE IF und ELSE Aktionslisten.';

  @override
  String get doc_action_if_block_summary =>
      'Verwenden Sie dies, um einen einzigen Workflow beizubehalten, während Sie mehrere Ergebnisse basierend auf dem Laufzeitstatus behandeln.';

  @override
  String get doc_action_if_block_title => 'Aktion: ifBlock';

  @override
  String get doc_action_run_workflow_practices_l1 =>
      'Halten Sie den übergeordneten Workflow dünn und delegieren Sie an Domain-Workflows.';

  @override
  String get doc_action_run_workflow_practices_l2 =>
      'Übergeben Sie explizite Argumente, anstatt sich auf implizite globale Variablen zu verlassen.';

  @override
  String get doc_action_run_workflow_practices_l3 =>
      'Verwenden Sie Einstiegspunkte, um Unterroutinen abzubilden (erstellen, schließen, zuweisen, eskalieren).';

  @override
  String get doc_action_run_workflow_section_practices => 'Best Practices';

  @override
  String get doc_action_run_workflow_subtitle =>
      'Ruft einen anderen Workflow mit Einstiegspunkt und Argumenten auf.';

  @override
  String get doc_action_run_workflow_summary =>
      'Kernbaustein zur Aufteilung der Geschäftslogik in wiederverwendbare Einheiten.';

  @override
  String get doc_action_run_workflow_title => 'Aktion: runWorkflow';

  @override
  String get doc_action_stop_unless_example =>
      'condition.variable = ((reaction.emoji.name))\ncondition.operator = equals\ncondition.value = ✅';

  @override
  String get doc_action_stop_unless_format_l1 =>
      'Sie können rohe Schlüssel verwenden: message.content[0]';

  @override
  String get doc_action_stop_unless_format_l2 =>
      'Sie können umschlossene Variablen verwenden: ((message.content[0]))';

  @override
  String get doc_action_stop_unless_format_l3 =>
      'Beide werden von der Laufzeit aufgelöst.';

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
      'Format der Bedingungsvariablen';

  @override
  String get doc_action_stop_unless_section_operators =>
      'Unterstützte Operatoren';

  @override
  String get doc_action_stop_unless_subtitle =>
      'Schutz-Klausel, die den Workflow stoppt, wenn die Bedingung nicht erfüllt ist.';

  @override
  String get doc_action_stop_unless_summary =>
      'Verwenden Sie dies oben in Workflows, um unnötige Aktionen zu verhindern, wenn der Kontext nicht übereinstimmt.';

  @override
  String get doc_action_stop_unless_title => 'Aktion: stopUnless';

  @override
  String get doc_available_variables => 'Verfügbare Variablen';

  @override
  String get doc_center_clear_search => 'Suche löschen';

  @override
  String get doc_center_empty =>
      'Kein Dokumentationseintrag entspricht Ihrer Suche.';

  @override
  String get doc_center_search_hint =>
      'Suchen Sie nach Befehlen, Workflows, Variablen, Aktionen, Intents oder Beispielen...';

  @override
  String get doc_center_title => 'Dokumentationszentrum';

  @override
  String get doc_common_section_best_use_cases => 'Beste Anwendungsfälle';

  @override
  String get doc_common_section_important_notes => 'Wichtige Hinweise';

  @override
  String get doc_event_audit_log_create_best_use_l1 =>
      'Team bei sensiblen Aktionen benachrichtigen (Rolle löschen, Webhook erstellen, Bann usw.).';

  @override
  String get doc_event_audit_log_create_best_use_l2 =>
      'Bestimmte Aktionstypen an dedizierte Workflows weiterleiten.';

  @override
  String get doc_event_audit_log_create_subtitle =>
      'Wird ausgelöst, wenn ein neuer Audit-Log-Eintrag erstellt wird.';

  @override
  String get doc_event_audit_log_create_summary =>
      'Hochwertiges Ereignis für die administrative Sicherheitsüberwachung.';

  @override
  String get doc_event_audit_log_create_title =>
      'Ereignis: guildAuditLogCreate';

  @override
  String get doc_event_message_create_best_use_l1 =>
      'Erkennen von Befehlen, die ohne Slash-Befehle eingegeben wurden.';

  @override
  String get doc_event_message_create_best_use_l2 =>
      'Anwenden von Anti-Spam-Filtern vor der Beantwortung.';

  @override
  String get doc_event_message_create_best_use_l3 =>
      'Weiterleitung an wiederverwendbare Workflows basierend auf dem ersten Wort oder einer Erwähnung.';

  @override
  String get doc_event_message_create_example =>
      'Guard: ((message.isBot)) equals false\nGuard: ((message.content[0])) equals !ticket\nDann: runWorkflow -> ticket_manager entry=create';

  @override
  String get doc_event_message_create_intent_1 => 'Guild Messages';

  @override
  String get doc_event_message_create_intent_2 => 'Message Content';

  @override
  String get doc_event_message_create_notes_l1 =>
      'Wenn der Intent \'Message Content\' deaktiviert ist, können inhaltsabhängige Bedingungen fehlschlagen.';

  @override
  String get doc_event_message_create_notes_l2 =>
      'message.content[index] ist wortbasiert und wird durch die Laufzeitextraktion begrenzt.';

  @override
  String get doc_event_message_create_notes_l3 =>
      'author.isBot kann helfen, Bot-Schleifen zu vermeiden.';

  @override
  String get doc_event_message_create_subtitle =>
      'Wird für jede neu erstellte Nachricht ausgelöst.';

  @override
  String get doc_event_message_create_summary =>
      'Verwenden Sie dieses Ereignis für Moderation, Keyword-Pipelines, automatische Antworten, befehlsähnliches Parsen und Analysen.';

  @override
  String get doc_event_message_create_title => 'Ereignis: messageCreate';

  @override
  String get doc_event_poll_vote_add_best_use_l1 =>
      'Jeder Antwort-ID einen anderen Aktionszweig zuordnen.';

  @override
  String get doc_event_poll_vote_add_best_use_l2 =>
      'Umfrageteilnahme pro Kanal oder Benutzergruppe verfolgen.';

  @override
  String get doc_event_poll_vote_add_intent => 'Guild Messages';

  @override
  String get doc_event_poll_vote_add_notes_l1 =>
      'poll.answer.id ist der stabilste Schlüssel für das Routing.';

  @override
  String get doc_event_poll_vote_add_notes_l2 =>
      'poll.question ist optional und kann je nach Nutzlast leer sein.';

  @override
  String get doc_event_poll_vote_add_subtitle =>
      'Wird ausgelöst, wenn ein Benutzer für eine Umfrageantwort stimmt.';

  @override
  String get doc_event_poll_vote_add_summary =>
      'Nützlich für die Verfolgung von Ergebnissen, Rollenzuweisungen nach Umfrageoptionen und Umfrageverarbeitung.';

  @override
  String get doc_event_poll_vote_add_title => 'Ereignis: messagePollVoteAdd';

  @override
  String get doc_event_reaction_add_best_use_l1 =>
      'Genehmigungs-/Ablehnungs-Flows mit Unicode-Emojis.';

  @override
  String get doc_event_reaction_add_best_use_l2 =>
      'Mehrstufige Umfragen mit benutzerdefinierten Emoji-IDs.';

  @override
  String get doc_event_reaction_add_best_use_l3 =>
      'Schnelle Moderationssignale aus Team-Kanälen.';

  @override
  String get doc_event_reaction_add_example =>
      'Guard: ((reaction.emoji.name)) equals ✅\nAktion: addRole -> user=((userId)) role=((global.approvedRoleId))';

  @override
  String get doc_event_reaction_add_intent => 'Guild Message Reactions';

  @override
  String get doc_event_reaction_add_notes_l1 =>
      'reaction.emoji.id kann bei Unicode-Emojis leer sein.';

  @override
  String get doc_event_reaction_add_notes_l2 =>
      'Verwenden Sie reaction.emoji.name für allgemeines Matching.';

  @override
  String get doc_event_reaction_add_notes_l3 =>
      'Verwenden Sie reaction.emoji.id für striktes Matching benutzerdefinierter Emojis.';

  @override
  String get doc_event_reaction_add_subtitle =>
      'Wird ausgelöst, wenn ein Benutzer eine Reaktion zu einer Nachricht hinzufügt.';

  @override
  String get doc_event_reaction_add_summary =>
      'Ideal für Button-ähnliche UX ohne Komponenten, Abstimmungssysteme, Rollenmenüs und leichte Genehmigungsprozesse.';

  @override
  String get doc_event_reaction_add_title => 'Ereignis: messageReactionAdd';

  @override
  String get doc_event_user_update_notes_l1 =>
      'Meistens kein Kanalkontext für dieses Ereignis.';

  @override
  String get doc_event_user_update_notes_l2 =>
      'Bevorzugen Sie Protokollierung + Moderationswarnungen gegenüber direkten benutzerseitigen Antworten.';

  @override
  String get doc_event_user_update_subtitle =>
      'Wird ausgelöst, wenn sich Benutzerprofildaten ändern.';

  @override
  String get doc_event_user_update_summary =>
      'Nützlich für die Prüfung von Profiländerungen und Auslöser, die durch Benutzername/Avatar gesteuert werden.';

  @override
  String get doc_event_user_update_title => 'Ereignis: userUpdate';

  @override
  String get doc_event_voice_state_update_automations_l1 =>
      'Erkennen von Verstößen gegen Richtlinien zur Selbststummschaltung/Selbsttaubschaltung.';

  @override
  String get doc_event_voice_state_update_automations_l2 =>
      'Willkommensnachricht beim Beitritt zum Sprachkanal für Support-Kanäle auslösen.';

  @override
  String get doc_event_voice_state_update_automations_l3 =>
      'Muster beim Verlassen/Beitreten anhand von Kanaländerungen protokollieren.';

  @override
  String get doc_event_voice_state_update_intent => 'Guilds';

  @override
  String get doc_event_voice_state_update_section_title =>
      'Typische Automatisierungen';

  @override
  String get doc_event_voice_state_update_subtitle =>
      'Wird ausgelöst, wenn sich der Sprachstatus eines Benutzers ändert.';

  @override
  String get doc_event_voice_state_update_summary =>
      'Verwenden Sie dies für Auto-Moderation in Sprachkanälen, Anwesenheitskontrollen und Sprachautomatisierung.';

  @override
  String get doc_event_voice_state_update_title => 'Ereignis: voiceStateUpdate';

  @override
  String get doc_example => 'Beispiel';

  @override
  String doc_interaction_commands_example(String name, String id) {
    return 'Autovervollständigungs-Workflow:\nquery = ((autocomplete.query))\nqueryArray -> items=((httpSearch.body))\nrespondWithAutocomplete -> label=\'$name\' value=\'$id\'';
  }

  @override
  String get doc_interaction_commands_section_builtin_title =>
      'Integrierte Befehlsvariablen';

  @override
  String get doc_interaction_commands_section_execution_l1 =>
      'Slash-, Benutzer- und Nachrichtenbefehle gelangen alle als Anwendungsbefehl-Interaktionen in den Runner.';

  @override
  String get doc_interaction_commands_section_execution_l2 =>
      'Der Runner ordnet Befehle anhand der Discord-Befehls-ID zu und validiert dann den gespeicherten Typ gegenüber dem eingehenden Typ.';

  @override
  String get doc_interaction_commands_section_execution_l3 =>
      'Ein Typ-Mismatch wird als Warnung protokolliert, stoppt die Ausführung jedoch nicht hart.';

  @override
  String get doc_interaction_commands_section_execution_title =>
      'Ausführungsmodell';

  @override
  String get doc_interaction_commands_section_guidance_l1 =>
      'Schreiben Sie bedingte Logik gegen commandType oder interaction.command.type.';

  @override
  String get doc_interaction_commands_section_guidance_l2 =>
      'Bevorzugen Sie die Fallback-Syntax beim Teilen einer Vorlage zwischen Slash- und Nicht-Slash-Befehlen und verwenden Sie autocomplete.query innerhalb dedizierter Autovervollständigungs-Workflows.';

  @override
  String get doc_interaction_commands_section_guidance_l3 =>
      'Halten Sie Vorlagen portabel, indem Sie Ereignis-Namen innerhalb von Befehls-Workflows vermeiden; dynamische Autovervollständigung erfordert einen allgemeinen Workflow, der mit respondWithAutocomplete endet.';

  @override
  String get doc_interaction_commands_section_guidance_title =>
      'Anleitung zur Erstellung';

  @override
  String get doc_interaction_commands_section_per_type_l1 =>
      'chatInput: opts.* für Parameter und Unterbefehle.';

  @override
  String get doc_interaction_commands_section_per_type_l2 =>
      'user: target.user.* und target.member.*, falls verfügbar.';

  @override
  String get doc_interaction_commands_section_per_type_l3 =>
      'message: target.message.* einschließlich Inhalt und Autoren-ID, falls aufgelöst.';

  @override
  String get doc_interaction_commands_section_per_type_title =>
      'Variablen pro Typ';

  @override
  String get doc_interaction_commands_subtitle =>
      'Laufzeitverhalten von Slash-, Benutzer- und Nachrichtenbefehlen.';

  @override
  String get doc_interaction_commands_summary =>
      'Anwendungsbefehle werden über einen gemeinsamen Interaktionspfad ausgeführt, wobei die Laufzeitvariablen vom Discord-Befehlstyp abhängen.';

  @override
  String get doc_interaction_commands_title => 'Interaktionsbefehle';

  @override
  String get doc_kind_action => 'Aktion';

  @override
  String get doc_kind_all => 'Alle';

  @override
  String get doc_kind_event => 'Ereignis';

  @override
  String get doc_kind_runtime => 'Laufzeit';

  @override
  String get doc_kind_template => 'Vorlage';

  @override
  String get doc_required_intents => 'Erforderliche Intents';

  @override
  String get doc_runtime_action_outputs_example =>
      'Status: ((action.http.status|http.status|unknown))\nKörper: ((action.http.body|http.body))\nGelöscht: ((cleanup.count|0))\nGesamt: ((page.total|0))';

  @override
  String get doc_runtime_action_outputs_section_caveats_l1 =>
      'Nicht jede Aktion macht jedes Suffix verfügbar; die Verfügbarkeit ist executor-spezifisch.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l2 =>
      'Bevorzugen Sie für die Portabilität Fallback-Ausdrücke beim Lesen optionaler Ausgabefelder.';

  @override
  String get doc_runtime_action_outputs_section_caveats_l3 =>
      'Wenn ein Schlüssel fehlt, gibt die Vorlagenauflösung eine leere Zeichenfolge zurück.';

  @override
  String get doc_runtime_action_outputs_section_caveats_title => 'Vorbehalte';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l1 =>
      'HTTP-Aktionen: status, body, jsonPath.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l2 =>
      'Nachrichten-/Listenaktionen: count, mode, deleteItself, deleteResponse.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l3 =>
      'Array-Aktionen: items, length, removed, total.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_l4 =>
      'Andere Executoren können result- oder messageId-Felder verfügbar machen.';

  @override
  String get doc_runtime_action_outputs_section_common_fields_title =>
      'Gemeinsame Ausgabefelder';

  @override
  String get doc_runtime_action_outputs_section_patterns_l1 =>
      'Die primäre Ausgabe wird normalerweise als <resultKey> gespeichert.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l2 =>
      'Viele Executoren machen zur Klarheit und Namensraumtrennung auch action.<resultKey>.* Felder verfügbar.';

  @override
  String get doc_runtime_action_outputs_section_patterns_l3 =>
      'Einige Felder werden mit und ohne das action. Präfix gespiegelt.';

  @override
  String get doc_runtime_action_outputs_section_patterns_title =>
      'Ausgabemuster';

  @override
  String get doc_runtime_action_outputs_subtitle =>
      'Wie Aktionsergebnisschlüssel als Laufzeitvariablen verfügbar gemacht werden.';

  @override
  String get doc_runtime_action_outputs_summary =>
      'Die meisten Aktionen schreiben einen primären Ergebnisschlüssel und können je nach Executor auch Felder mit Präfix unter action.<resultKey>.* verfügbar machen.';

  @override
  String get doc_runtime_action_outputs_title => 'Laufzeit-Aktionsausgaben';

  @override
  String get doc_runtime_execution_flow_section_parity_l1 =>
      'Variablen sollten zwischen lokaler App-Laufzeit und Runner-Laufzeit identisch sein.';

  @override
  String get doc_runtime_execution_flow_section_parity_l2 =>
      'Verwenden Sie dieselben Variablennamen in Bedingungen, um portabel zu bleiben.';

  @override
  String get doc_runtime_execution_flow_section_parity_title => 'Paritätsregel';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l1 =>
      '1) Gateway-Ereignis empfangen.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l2 =>
      '2) Kontextvariablen-Map erstellen.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l3 =>
      '3) Workflows nach Ereignisname abgleichen.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l4 =>
      '4) Globale Variablen zusammenführen.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_l5 =>
      '5) Aktionen sequenziell mit Bedingungen ausführen.';

  @override
  String get doc_runtime_execution_flow_section_pipeline_title => 'Pipeline';

  @override
  String get doc_runtime_execution_flow_subtitle =>
      'Wie Ereignis-Workflows ausgewählt und ausgeführt werden.';

  @override
  String get doc_runtime_execution_flow_summary =>
      'Wenn ein Ereignis eintrifft, gleicht die Laufzeit konfigurierte Workflows über eventTrigger.event ab und führt dann Aktionen mit Kontextvariablen aus.';

  @override
  String get doc_runtime_execution_flow_title => 'Laufzeit-Ausführungsfluss';

  @override
  String get doc_template_advanced_variables_example =>
      'Typ: ((interaction.kind))\nAusgewählte Anzahl: ((interaction.values.count|0))\nThread-Besitzer: ((channel.thread.ownerId|unknown))\nGilden-Nutzlast-Typ: ((guild.kind|n/a))';

  @override
  String get doc_template_advanced_variables_section_aliases_l1 =>
      'Strukturierte Benutzer-Aliase (user.id, user.username, user.tag, user.avatar, user.banner) sind in vielen Befehlskontexten verfügbar.';

  @override
  String get doc_template_advanced_variables_section_aliases_l2 =>
      'member.id kann nützlich sein, wenn sowohl der Benutzer- als auch der Gildenmitglied-Kontext benötigt werden.';

  @override
  String get doc_template_advanced_variables_section_aliases_title =>
      'Benutzer- und Mitglieds-Aliase';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l1 =>
      'channel.kind, channel.position, channel.bitrate und channel.userLimit sind kontextabhängige Kanaldetails.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l2 =>
      'Thread-Kontexte können channel.thread.* Werte verfügbar machen (archived, locked, ownerId, autoArchiveDuration).';

  @override
  String get doc_template_advanced_variables_section_channel_guild_l3 =>
      'guild.kind hilft bei der Unterscheidung zwischen partiellen/vollständigen Gilden-Nutzlasten in erweiterten Workflows.';

  @override
  String get doc_template_advanced_variables_section_channel_guild_title =>
      'Kanal- und Gildendetails';

  @override
  String get doc_template_advanced_variables_section_interaction_l1 =>
      'interaction.kind identifiziert den eingehenden Interaktionsmodus (Button, Select, Modal, Command, Autocomplete).';

  @override
  String get doc_template_advanced_variables_section_interaction_l2 =>
      'interaction.values und interaction.values.count werden für Auswahlmenüs gefüllt.';

  @override
  String get doc_template_advanced_variables_section_interaction_l3 =>
      'interaction.command.name und interaction.command.id sind nützlich für Diagnosen und Routing-Prüfungen.';

  @override
  String get doc_template_advanced_variables_section_interaction_title =>
      'Interaktionsmetadaten';

  @override
  String get doc_template_advanced_variables_subtitle =>
      'Zusätzliche Laufzeit-Schlüssel, die in bestimmten Kontexten verfügbar sind.';

  @override
  String get doc_template_advanced_variables_summary =>
      'Diese Schlüssel werden aus Interaktionsnutzlasten und Laufzeitdetails von Kanälen/Gilden/Benutzern generiert, abhängig vom Ereignis- oder Befehlstyp.';

  @override
  String get doc_template_advanced_variables_title =>
      'Erweiterte Vorlagenvariablen';

  @override
  String get doc_template_functions_example =>
      'Normalisiert: ((uppercase(trim(userName))))\nHat Admin-Rolle: ((contains(userRole, \"admin\")))\nHöchste Punktzahl: ((first(scores.\$)))\nGesamtpunktzahl: ((sum(scores.\$)))';

  @override
  String get doc_template_functions_section_array_l1 =>
      'length(source), at(source, index), first(source), last(source).';

  @override
  String get doc_template_functions_section_array_l2 =>
      'slice(source, start, end?) und join(source, separator).';

  @override
  String get doc_template_functions_section_array_l3 =>
      'sum(source): addiert numerische Elemente und ignoriert nicht-numerische Werte.';

  @override
  String get doc_template_functions_section_array_l4 =>
      'formatEach(...) und embedFields(...) formatieren Objekt-Arrays für Text und Embeds.';

  @override
  String get doc_template_functions_section_array_title =>
      'Array- und Aggregat-Helfer';

  @override
  String get doc_template_functions_section_notes_l1 =>
      'Funktionsnamen sind nicht fallsensitiv.';

  @override
  String get doc_template_functions_section_notes_l2 =>
      'Unbekannte Funktionen oder ungültige Argumente werden in eine leere Zeichenfolge aufgelöst.';

  @override
  String get doc_template_functions_section_notes_l3 =>
      'Verwenden Sie die Fallback-Syntax mit | auf der Stammebene: ((replace(name, \"_\", \" \")|Unknown)).';

  @override
  String get doc_template_functions_section_notes_l4 =>
      'Von Funktionen zurückgegebene Arrays und Objekte werden als JSON-Text serialisiert.';

  @override
  String get doc_template_functions_section_notes_title => 'Wichtige Hinweise';

  @override
  String get doc_template_functions_section_random_l1 =>
      'coin() und random(): geben \"true\" oder \"\" für bedingte Verzweigungen zurück.';

  @override
  String get doc_template_functions_section_random_l2 =>
      'randomchoice(a, b, ...) und randomint(min, max).';

  @override
  String get doc_template_functions_section_random_title => 'Zufalls-Helfer';

  @override
  String get doc_template_functions_section_string_l1 =>
      'lowercase(source) / lower(source): Text in Kleinbuchstaben umwandeln.';

  @override
  String get doc_template_functions_section_string_l2 =>
      'uppercase(source) / upper(source): Text in Großbuchstaben umwandeln.';

  @override
  String get doc_template_functions_section_string_l3 =>
      'trim(source): führende und abschließende Leerzeichen entfernen.';

  @override
  String get doc_template_functions_section_string_l4 =>
      'replace(source, search, replacement) und contains(source, needle) für Ersetzungen und Prüfungen.';

  @override
  String get doc_template_functions_section_string_title =>
      'Zeichenfolgen-Helfer';

  @override
  String get doc_template_functions_subtitle =>
      'Daten innerhalb von ((...))-Ausdrücken transformieren und vergleichen.';

  @override
  String get doc_template_functions_summary =>
      'Verwenden Sie Vorlagenfunktionen, um Text zu normalisieren, Arrays zu inspizieren, Ausgabeblöcke zu erstellen und leichte Zufälligkeit hinzuzufügen.';

  @override
  String get doc_template_functions_title => 'Vorlagenfunktionen';

  @override
  String doc_template_variables_example(String name, String score) {
    return 'Hallo ((target.user.username|userName))\nSpieler: ((join(scores.items.\$, \", \")))\nFelder JSON: ((embedFields(scores.items.\$, \"\'$name\'\", \"\'$score\'\", true)))';
  }

  @override
  String get doc_template_variables_section_builtin_title =>
      'Integrierte Befehlsvariablen';

  @override
  String get doc_template_variables_section_fallbacks_l1 =>
      'Verwenden Sie ((opts.user|userName)), um einen Fallback bereitzustellen, wenn eine Option fehlt.';

  @override
  String get doc_template_variables_section_fallbacks_l2 =>
      'Verwenden Sie die JSONPath-Syntax bei Aktionsausgaben: ((myHttp.body.\$.data[0].id)); Arrays und Objekte bleiben abfragbar.';

  @override
  String get doc_template_variables_section_fallbacks_l3 =>
      'Funktionen wie length(...), join(...), formatEach(...) und embedFields(...) werden ebenfalls unterstützt; unbekannte Variablen werden weiterhin in eine leere Zeichenfolge aufgelöst.';

  @override
  String get doc_template_variables_section_fallbacks_title =>
      'Fallbacks und Pfade';

  @override
  String get doc_template_variables_section_sources_l1 =>
      'Befehlsvariablen: commandName, commandId, commandType, target.*, opts.*.';

  @override
  String get doc_template_variables_section_sources_l2 =>
      'Ereignisvariablen: event.*, message.*, reaction.*, voice.*, role.*, etc.';

  @override
  String get doc_template_variables_section_sources_l3 =>
      'Workflow-Variablen: workflow.name, workflow.entryPoint, arg.*, workflow.arg.*';

  @override
  String get doc_template_variables_section_sources_l4 =>
      'Globale Variablen: global.<key>';

  @override
  String get doc_template_variables_section_sources_l5 =>
      'Aktionsausgaben: action.<key>, falls verfügbar.';

  @override
  String get doc_template_variables_section_sources_title => 'Variablenquellen';

  @override
  String get doc_template_variables_section_types_l1 =>
      'Slash-Befehle verwenden commandType = chatInput und machen opts.<option> Variablen verfügbar.';

  @override
  String get doc_template_variables_section_types_l2 =>
      'Benutzerbefehle verwenden commandType = user und machen target.user.* Variablen verfügbar.';

  @override
  String get doc_template_variables_section_types_l3 =>
      'Nachrichtenbefehle verwenden commandType = message und machen target.message.* Variablen verfügbar.';

  @override
  String get doc_template_variables_section_types_l4 =>
      'Subcommands stellen ihre Argumente weiterhin über opts.* bereit.';

  @override
  String get doc_template_variables_section_types_title => 'Befehlstypen';

  @override
  String get doc_template_variables_subtitle =>
      'Wie dynamische Platzhalter aufgelöst werden.';

  @override
  String get doc_template_variables_summary =>
      'Die Laufzeit löst Platzhalter mithilfe des aktuellen Ereignis-/Interaktionskontexts, der Workflow-Argumente und der globalen Variablen auf.';

  @override
  String get doc_template_variables_title => 'Vorlagenvariablen';

  @override
  String get done => 'Fertig';

  @override
  String download_completed(String id) {
    return 'Download abgeschlossen: $id';
  }

  @override
  String download_failed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get download_legacy_backup => 'Download abgeschlossen (Legacy-Backup)';

  @override
  String get drive_legacy_snapshot => 'Legacy-Snapshot';

  @override
  String get drive_manual_backup => 'Manuelles Backup';

  @override
  String get edit_shell_all_saved => 'Alle Änderungen gespeichert';

  @override
  String get edit_shell_command_body => 'Befehlskörper';

  @override
  String get edit_shell_command_settings => 'Befehlseinstellungen';

  @override
  String get edit_shell_command_settings_desc =>
      'Metadaten, Verfügbarkeit, Berechtigungen und Ordnerplatzierung.';

  @override
  String get edit_shell_local_draft => 'Lokaler Entwurf';

  @override
  String get edit_shell_local_only => 'Nur lokal';

  @override
  String edit_shell_routes_count(int count) {
    return '$count Route(n)';
  }

  @override
  String get edit_shell_save_changes => 'Änderungen speichern';

  @override
  String get edit_shell_subtitle =>
      'Einstellungen und Eingaben befinden sich oben. Aktionen und Antwort folgen unten.';

  @override
  String get edit_shell_trigger_inputs => 'Auslöser & Eingaben';

  @override
  String get edit_shell_trigger_inputs_desc =>
      'Befehlsoptionen, Auslöseverhalten und Ausführungsmodus anpassen.';

  @override
  String get edit_shell_type_command => 'Befehl';

  @override
  String get edit_shell_type_legacy => 'Legacy-Befehl';

  @override
  String get edit_shell_type_message => 'Nachrichtenbefehl';

  @override
  String get edit_shell_type_slash => 'Slash-Befehl';

  @override
  String get edit_shell_type_user => 'Benutzerbefehl';

  @override
  String get edit_shell_unsaved => 'Ungespeicherte Änderungen';

  @override
  String get edit_shell_untitled_command => 'Unbenannter Befehl';

  @override
  String get embed_add_field => 'Feld hinzufügen';

  @override
  String get embed_add_section => 'Abschnitt hinzufügen';

  @override
  String get embed_add_tooltip => 'Embed hinzufügen';

  @override
  String get embed_color_picker_title => 'Embed-Farbe wählen';

  @override
  String get embed_delete_confirm => 'Dieses Embed wird entfernt. Fortfahren?';

  @override
  String get embed_delete_title => 'Embed löschen';

  @override
  String embed_empty_message(int max) {
    return 'Keine Embeds. Sie können bis zu $max Embeds hinzufügen.';
  }

  @override
  String get embed_field_delete_confirm =>
      'Dieses Feld wird aus dem Embed entfernt. Fortfahren?';

  @override
  String get embed_field_delete_title => 'Feld löschen';

  @override
  String embed_field_number(int index) {
    return 'Feld #$index';
  }

  @override
  String get embed_fields_empty => 'Noch keine Felder.';

  @override
  String embed_fields_header(int count) {
    return 'Felder ($count/25)';
  }

  @override
  String get embed_label_author_icon => 'URL für Autoren-Icon';

  @override
  String get embed_label_author_name => 'Autorenname';

  @override
  String get embed_label_author_url => 'Autoren-URL';

  @override
  String get embed_label_color => 'Farbe (Ganzzahl oder #hex)';

  @override
  String get embed_label_dynamic_fields => 'Vorlage für dynamische Felder';

  @override
  String get embed_label_footer_icon => 'URL für Fußzeilen-Icon';

  @override
  String get embed_label_footer_text => 'Fußzeilentext';

  @override
  String get embed_label_image_url => 'Bild-URL';

  @override
  String get embed_label_inline => 'Nebeneinander';

  @override
  String get embed_label_thumbnail_url => 'Thumbnail-URL';

  @override
  String get embed_label_timestamp => 'Zeitstempel (ISO8601)';

  @override
  String get embed_label_title => 'Titel';

  @override
  String get embed_label_url => 'URL';

  @override
  String embed_number(int index) {
    return 'Embed #$index';
  }

  @override
  String embed_response_header(int count, int max) {
    return 'Antwort-Embeds ($count/$max)';
  }

  @override
  String get embed_section_author => 'Autor';

  @override
  String get embed_section_color => 'Farbe';

  @override
  String get embed_section_dynamic_fields => 'Dynamische Felder';

  @override
  String get embed_section_fields => 'Felder';

  @override
  String get embed_section_footer => 'Fußzeile';

  @override
  String get embed_section_media => 'Medien';

  @override
  String get embed_section_timestamp => 'Zeitstempel';

  @override
  String emojis_delete_confirm_body(String name) {
    return 'Lösche :$name: ? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get emojis_delete_confirm_title => 'Emoji löschen';

  @override
  String emojis_delete_error(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get emojis_delete_tooltip => 'Löschen';

  @override
  String get emojis_empty =>
      'Noch keine Emojis. Laden Sie eines hoch, um loszulegen.';

  @override
  String get emojis_loading_error => 'Laden der Emojis fehlgeschlagen';

  @override
  String emojis_rename_error(String error) {
    return 'Umbenennen fehlgeschlagen: $error';
  }

  @override
  String get emojis_rename_hint => 'Neuer Name';

  @override
  String get emojis_rename_title => 'Emoji umbenennen';

  @override
  String get emojis_rename_tooltip => 'Umbenennen';

  @override
  String get emojis_tab => 'Emojis';

  @override
  String get emojis_tab_short => 'Emoji';

  @override
  String get emojis_title => 'Anwendungs-Emojis';

  @override
  String get emojis_upload => 'Emoji hochladen';

  @override
  String emojis_upload_error(String error) {
    return 'Upload fehlgeschlagen: $error';
  }

  @override
  String get emojis_upload_name_hint => 'Emoji-Name (Buchstaben, Zahlen, _)';

  @override
  String get emojis_upload_pick_image => 'Bild auswählen';

  @override
  String get error => 'Fehler';

  @override
  String get error_delete_messages_failed =>
      'Fehler beim Löschen der Nachrichten.';

  @override
  String get error_invalid_channel_type => 'Der Kanal ist kein Textkanal.';

  @override
  String get error_invalid_count => 'Die Anzahl muss größer als 0 sein.';

  @override
  String get error_network_timeout =>
      'Zeitüberschreitung der Aktion. Bitte versuchen Sie es erneut.';

  @override
  String error_with_details(String error) {
    return 'Fehler: $error';
  }

  @override
  String get export_button => 'ZIP exportieren';

  @override
  String get export_commands => 'Befehle';

  @override
  String export_failed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get export_global_variables => 'Globale Variablen';

  @override
  String get export_import_title => 'Export / Import';

  @override
  String get export_section_desc =>
      'Exportieren Sie ausgewählte Bereiche Ihres Bots als ZIP-Datei. Das Bot-Token ist niemals enthalten.';

  @override
  String get export_section_title => 'Exportieren';

  @override
  String get export_status => 'Status & Aktivitäten';

  @override
  String get export_workflows => 'Workflows';

  @override
  String get globals_add => 'Variable hinzufügen';

  @override
  String get globals_add_global => 'Globale Variable hinzufügen';

  @override
  String get globals_add_scoped => 'Geltungsbereichsvariable hinzufügen';

  @override
  String get globals_copy_value => 'Wert kopieren';

  @override
  String globals_delete_confirm(String key) {
    return 'Lösche \"$key\"?';
  }

  @override
  String get globals_delete_title => 'Variable löschen';

  @override
  String get globals_dialog_global_desc =>
      'Globale Variablen werden von allen Befehlen und Servern geteilt.';

  @override
  String globals_dialog_ref_preview(String ref) {
    return 'Verwendung: \$getVar[$ref]';
  }

  @override
  String globals_dialog_scoped_desc(String scope) {
    return 'Eine Geltungsbereichsvariable speichert einen separaten Wert pro $scope-Kontext.';
  }

  @override
  String get globals_edit => 'Variable bearbeiten';

  @override
  String get globals_edit_global => 'Globale Variable bearbeiten';

  @override
  String get globals_edit_scoped => 'Geltungsbereichsvariable bearbeiten';

  @override
  String get globals_empty => 'Noch keine globalen Variablen';

  @override
  String get globals_empty_subtitle =>
      'Fügen Sie eine Variable hinzu, um persistente Daten zu speichern, auf die alle Befehle zugreifen können.';

  @override
  String get globals_help_global =>
      'Wird von allen Befehlen geteilt. Zugriff über \$getVar[key].';

  @override
  String get globals_help_scoped =>
      'Wird pro Kontext gespeichert (Server, Benutzer, Kanal…). Jeder Eintrag behält einen eindeutigen Wert pro Discord-Kontext.';

  @override
  String get globals_key => 'Schlüssel';

  @override
  String get globals_key_hint => 'z. B. prefix, level, welcome_message';

  @override
  String get globals_mode_global => 'Global';

  @override
  String get globals_mode_scoped => 'Geltungsbereich';

  @override
  String get globals_no_default => 'Kein Standardwert';

  @override
  String get globals_refresh => 'Aktualisieren';

  @override
  String get globals_retry => 'Wiederholen';

  @override
  String get globals_scope_channel => 'Kanal';

  @override
  String get globals_scope_guild => 'Gilde';

  @override
  String get globals_scope_guildMember => 'Gildenmitglied';

  @override
  String get globals_scope_message => 'Nachricht';

  @override
  String get globals_scope_user => 'Benutzer';

  @override
  String get globals_search => 'Variablen suchen…';

  @override
  String get globals_source_local => 'Lokal';

  @override
  String globals_source_runner(String name) {
    return 'Runner: $name';
  }

  @override
  String get globals_tab => 'Global';

  @override
  String get globals_tab_short => 'Vars';

  @override
  String get globals_title => 'Variablen';

  @override
  String get globals_value => 'Wert';

  @override
  String get globals_value_auto_type_hint =>
      'Wert ist automatisch typisiert (Zahl, Boolean, JSON).';

  @override
  String get hint_use_variables =>
      'Verwenden Sie bei Bedarf Variablen/Vorlagen';

  @override
  String get home_add_time => 'Zeit hinzufügen';

  @override
  String get home_empty_support_btn => 'Discord-Support';

  @override
  String get home_empty_support_hint =>
      'Brauchen Sie Hilfe? Treten Sie unserer Community bei!';

  @override
  String get home_foreground_service_not_started =>
      'Der Vordergrunddienst wurde nicht gestartet.';

  @override
  String get home_hosting_expired => 'Hosting abgelaufen';

  @override
  String home_hosting_time_left(String time) {
    return 'Verbleibende Hosting-Zeit: $time';
  }

  @override
  String get home_log_desktop_stop_requested => 'Desktop-Bot-Stopp angefordert';

  @override
  String get home_log_start_requested => 'Bot-Start angefordert';

  @override
  String get home_log_stop_requested => 'Bot-Stopp angefordert';

  @override
  String get home_logs_tooltip => 'Protokolle anzeigen';

  @override
  String get home_manage => 'Verwalten';

  @override
  String get home_notification_permission_required =>
      'Benachrichtigungsberechtigung ist erforderlich, um den Bot zu starten.';

  @override
  String home_server_count_one(int count) {
    return '$count Server';
  }

  @override
  String home_server_count_other(int count) {
    return '$count Server';
  }

  @override
  String get home_start => 'Start';

  @override
  String get home_start_ads => 'Start (Anzeige ansehen)';

  @override
  String get home_start_premium => 'Start (Premium)';

  @override
  String get home_status_offline => 'Offline';

  @override
  String get home_status_online => 'Online';

  @override
  String get home_stop => 'Stopp';

  @override
  String get home_sync_failed => 'Synchronisierung fehlgeschlagen';

  @override
  String get home_tab => 'Home';

  @override
  String get home_time_added => 'Zeit erfolgreich hinzugefügt';

  @override
  String home_token_missing(String botName) {
    return 'Token für $botName nicht gefunden';
  }

  @override
  String get home_unknown_app => 'Unbekannt';

  @override
  String get import_button => 'Importieren';

  @override
  String import_failed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get import_nothing => 'Nichts importiert.';

  @override
  String get import_overwrite => 'Überschreiben';

  @override
  String import_parse_failed(String error) {
    return 'ZIP konnte nicht analysiert werden: $error';
  }

  @override
  String get import_pick_file => 'ZIP-Datei auswählen';

  @override
  String get import_section_desc =>
      'Importieren Sie eine zuvor exportierte ZIP-Datei. Konflikte können pro Element gelöst werden.';

  @override
  String get import_section_title => 'Importieren';

  @override
  String get import_skip => 'Überspringen';

  @override
  String import_summary_commands_imported(int count) {
    return '$count Befehl(e) importiert';
  }

  @override
  String import_summary_commands_skipped(int count) {
    return '$count Befehl(e) übersprungen';
  }

  @override
  String get import_summary_status_imported => 'Status importiert';

  @override
  String get import_summary_variables_imported => 'Variablen importiert';

  @override
  String import_summary_workflows_imported(int count) {
    return '$count Workflow(s) importiert';
  }

  @override
  String import_summary_workflows_skipped(int count) {
    return '$count Workflow(s) übersprungen';
  }

  @override
  String get image_editor_create => 'Erstellen';

  @override
  String get image_editor_create_canvas => 'Bild-Leinwand erstellen';

  @override
  String image_editor_edit_canvas(int count) {
    return 'Leinwand bearbeiten ($count Ops)';
  }

  @override
  String get image_editor_open => 'Editor öffnen';

  @override
  String legacy_bdfd_run_failed(String command, String error) {
    return 'Fehler beim Ausführen des BDFD-Skripts für den Befehl \"$command\": $error';
  }

  @override
  String get legacy_prefix_mode_desc =>
      'Behandelt Befehle aus messageCreate unter Verwendung von <präfix><befehl>.';

  @override
  String get legacy_prefix_mode_subtitle =>
      'Verwendet positionsabhängige Optionen (Beispiel: !config #kanal).';

  @override
  String get legacy_prefix_mode_title => 'Legacy-Präfix-Modus';

  @override
  String get legacy_prefix_override_hint =>
      'Beispiel: ? oder ((guild.prefix | !))';

  @override
  String get legacy_prefix_override_label => 'Präfix-Überschreibung (optional)';

  @override
  String get legacy_response_mode_label => 'Legacy-Antwortmodus';

  @override
  String get legacy_response_banner_body =>
      'Einige Befehle verwenden noch das alte Antwortformat. Öffnen Sie sie im Editor und speichern Sie sie erneut, um das neue Format zu aktivieren.';

  @override
  String get legacy_response_banner_dismiss => 'Schließen';

  @override
  String get legacy_response_banner_migrate => 'Alle migrieren';

  @override
  String legacy_response_banner_migrated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Befehle migriert',
      one: '1 Befehl migriert',
    );
    return '$_temp0';
  }

  @override
  String get legacy_response_banner_migrated_none =>
      'Keine Befehle zu migrieren';

  @override
  String get legacy_response_banner_migrate_failed =>
      'Migration fehlgeschlagen';

  @override
  String get legacy_response_banner_migrating => 'Wird migriert...';

  @override
  String get legacy_response_banner_short_body =>
      'Öffnen und speichern Sie Ihre Befehle erneut, um zum neuen Format zu migrieren.';

  @override
  String get legacy_response_banner_short_title =>
      'Befehlsaktualisierung verfügbar';

  @override
  String get legacy_response_banner_title =>
      'Aktualisierung des Befehlsantwortformats';

  @override
  String get local_command_awaited_desc =>
      'Voreinstellungen für erwartete Callbacks bleiben lokal, da es sich um interne Laufzeit-Callbacks handelt.';

  @override
  String get local_command_desc =>
      'Speichere den Befehl nur in Bot Creator. Du kannst ihn dynamisch auf bestimmten Gilden registrieren, indem du BDFD \$registerGuildCommands verwendest.';

  @override
  String get local_command_title =>
      'Lokaler Befehl (Nicht bei Discord registrieren)';

  @override
  String logs_runner_source(String name) {
    return 'Protokolle von: $name';
  }

  @override
  String get modal_add_text_input => 'Texteingabe hinzufügen';

  @override
  String get modal_builder_title => 'Modal-Builder';

  @override
  String get modal_custom_id_hint =>
      'Wird verwendet, um dieses Modal zu identifizieren';

  @override
  String get modal_custom_id_label => 'Benutzerdefinierte ID';

  @override
  String get modal_default_value => 'Standardwert';

  @override
  String modal_field_default_label(int index) {
    return 'Feld $index';
  }

  @override
  String modal_input_index(int index) {
    return 'Eingabe $index';
  }

  @override
  String modal_inputs_count(int count) {
    return '$count/5 Eingaben';
  }

  @override
  String get modal_remove_field_confirm =>
      'Dieses Feld wird aus dem Modal entfernt. Fortfahren?';

  @override
  String get modal_remove_field_title => 'Modal-Feld entfernen';

  @override
  String get modal_style => 'Stil:';

  @override
  String get modal_title_label => 'Modal-Titel';

  @override
  String get modal_workflow_submit =>
      'Workflow zur Ausführung bei Übermittlung (optional)';

  @override
  String get more_options_title => 'Weitere Optionen';

  @override
  String get more_tab => 'Mehr';

  @override
  String get nav_webhooks => 'Webhooks';

  @override
  String get nav_webhooks_compact => 'Hooks';

  @override
  String get no_more_options => 'Keine weiteren Optionen verfügbar';

  @override
  String notion_create_workflow_from_query(String query) {
    return 'Workflow \"$query\" erstellen';
  }

  @override
  String get notion_filter_add => 'Filter hinzufügen';

  @override
  String get notion_filter_type => 'Typ';

  @override
  String get ok => 'OK';

  @override
  String get onboarding_command_button => 'Weiter';

  @override
  String get onboarding_command_desc => 'Erstellen Sie Ihren ersten Befehl';

  @override
  String get onboarding_command_example =>
      'Beispiel:\n/hello → Bot antwortet \"Hallo! 👋\"';

  @override
  String get onboarding_command_text =>
      'Befehle sind das Herzstück Ihres Bots. Sie ermöglichen es Benutzern, über Discord mit Ihrem Bot zu interagieren.';

  @override
  String get onboarding_command_title => 'Schritt 2: Einen Befehl hinzufügen';

  @override
  String get onboarding_create_button => 'Weiter';

  @override
  String get onboarding_create_desc => 'Holen Sie sich Ihr Discord-Token';

  @override
  String get onboarding_create_steps =>
      '1. Gehen Sie zum Discord Developer Portal\n2. Erstellen Sie eine neue App\n3. Kopieren Sie das Bot-Token\n4. Fügen Sie es unten ein';

  @override
  String get onboarding_create_tip =>
      '💡 Tipp: Teilen Sie niemals Ihr Token! Es gibt vollen Zugriff auf Ihren Bot.';

  @override
  String get onboarding_create_title => 'Schritt 1: Einen Bot erstellen';

  @override
  String get onboarding_create_tutorial =>
      'Tutorial: So erhalten Sie ein Token';

  @override
  String get onboarding_start_button => 'Weiter';

  @override
  String get onboarding_start_desc => 'Starten Sie Ihren Bot!';

  @override
  String get onboarding_start_text =>
      'Klicken Sie auf die Schaltfläche \"Start\" auf Ihrer Bot-Karte. Testen Sie dann Ihren Befehl in Discord!';

  @override
  String get onboarding_start_tip =>
      '✨ Großartig! Sie haben Ihren ersten Discord-Bot erstellt. Sie können jetzt weitere Befehle hinzufügen und ihn anpassen!';

  @override
  String get onboarding_start_title => 'Schritt 3: Den Bot starten';

  @override
  String get onboarding_success_button => 'Starten!';

  @override
  String get onboarding_success_desc => 'Ihr Discord-Bot ist startklar!';

  @override
  String get onboarding_success_tip1 => 'Weitere Befehle hinzufügen';

  @override
  String get onboarding_success_tip2 => 'Workflows erstellen';

  @override
  String get onboarding_success_tip3 => 'Sichern Sie Ihre Daten';

  @override
  String get onboarding_success_title => 'Herzlichen Glückwunsch! 🎉';

  @override
  String get onboarding_success_whatsnext => 'Was kommt als Nächstes?';

  @override
  String get onboarding_welcome_desc =>
      'Erstellen Sie Ihren ersten Discord-Bot in 3 einfachen Schritten. Wir führen Sie durch jeden Schritt.';

  @override
  String get onboarding_welcome_skip => 'Überspringen';

  @override
  String get onboarding_welcome_start => 'Loslegen';

  @override
  String get onboarding_welcome_title => 'Willkommen bei Bot Creator';

  @override
  String get option_add_choice => 'Auswahl hinzufügen';

  @override
  String get option_add_localizations => 'Lokalisierungen hinzufügen';

  @override
  String get option_choice_delete_confirm =>
      'Diese Auswahl wird entfernt. Fortfahren?';

  @override
  String get option_choice_delete_title => 'Auswahl löschen';

  @override
  String get option_choice_name => 'Name der Auswahl';

  @override
  String option_choice_number(int index) {
    return 'Auswahl $index';
  }

  @override
  String get option_choice_value => 'Wert der Auswahl';

  @override
  String option_default_name(int index) {
    return 'Option $index';
  }

  @override
  String get option_delete_argument_confirm =>
      'Dieses Argument wird entfernt. Fortfahren?';

  @override
  String get option_delete_argument_title => 'Argument löschen';

  @override
  String get option_delete_choice_confirm =>
      'Diese Auswahl wird entfernt. Fortfahren?';

  @override
  String get option_delete_choice_title => 'Option löschen';

  @override
  String get option_delete_confirm => 'Diese Option wird entfernt. Fortfahren?';

  @override
  String get option_delete_localization_confirm =>
      'Dieser Lokalisierungseintrag wird entfernt. Fortfahren?';

  @override
  String get option_delete_localization_title => 'Lokalisierung löschen';

  @override
  String get option_delete_title => 'Option löschen';

  @override
  String get option_desc_required =>
      'Bitte geben Sie eine Beschreibung für die Option ein';

  @override
  String option_label_number(int index) {
    return 'Bezeichnung $index';
  }

  @override
  String get option_localized_description => 'Lokalisierte Beschreibung';

  @override
  String get option_localized_name => 'Lokalisierter Name';

  @override
  String get option_max_value => 'Max. Wert';

  @override
  String get option_min_value => 'Min. Wert';

  @override
  String get option_name_duplicate =>
      'Dieser Name wird auf dieser Ebene bereits verwendet';

  @override
  String get option_name_invalid_chars =>
      'Der Name der Option darf nur Buchstaben, Zahlen und Unterstriche enthalten';

  @override
  String get option_name_invalid_start =>
      'Der Name der Option beginnt mit einem nicht unterstützten Zeichen';

  @override
  String get option_name_max_length =>
      'Der Name der Option darf höchstens 32 Zeichen lang sein';

  @override
  String get option_name_required =>
      'Bitte geben Sie einen Namen für die Option ein';

  @override
  String get option_select_language => 'Sprache auswählen';

  @override
  String option_static_label_n(int index) {
    return 'Bezeichnung $index';
  }

  @override
  String option_static_value_n(int index) {
    return 'Wert $index';
  }

  @override
  String get option_subcommand_options => 'Optionen für Unterbefehl';

  @override
  String get option_subcommands => 'Unterbefehle';

  @override
  String get option_type_attachment => 'Anhang';

  @override
  String get option_type_boolean => 'Boolean';

  @override
  String get option_type_channel => 'Kanal';

  @override
  String get option_type_integer => 'Ganzzahl';

  @override
  String get option_type_mentionable => 'Erwähnbar';

  @override
  String get option_type_number => 'Nummer';

  @override
  String get option_type_role => 'Rolle';

  @override
  String get option_type_string => 'String';

  @override
  String get option_type_subcommand => 'Unterbefehl';

  @override
  String get option_type_subcommand_group => 'Unterbefehl-Gruppe';

  @override
  String get option_type_unknown => 'Unbekannt';

  @override
  String get option_type_user => 'Benutzer';

  @override
  String option_value_number(int index) {
    return 'Wert $index';
  }

  @override
  String get premium_active_desc =>
      'Vielen Dank für Ihre Unterstützung! Alle Anzeigen sind deaktiviert.';

  @override
  String get premium_active_title => 'Premium aktiv';

  @override
  String get premium_card_button => 'Pläne ansehen';

  @override
  String get premium_card_desc =>
      'Abonnieren Sie, um alle Anzeigen zu entfernen und Ihre Bots sofort ohne Pop-up zu starten.';

  @override
  String get premium_card_title => 'Anzeigen entfernen';

  @override
  String get quick_access_title => 'Schnellzugriff';

  @override
  String get recovery_delete_bot => 'Bot lokal löschen';

  @override
  String get recovery_label => 'Recovery';

  @override
  String get recovery_retry_discord => 'Discord-Verbindung erneut versuchen';

  @override
  String get recovery_title => 'Recovery-Modus';

  @override
  String reply_active_route(String label) {
    return 'Aktive Route: $label';
  }

  @override
  String get reply_buttons_desc =>
      'Fügen Sie dieser Nachricht interaktive Buttons oder Dropdowns hinzu';

  @override
  String get reply_buttons_optional => 'Buttons & Auswahlmenüs (optional)';

  @override
  String get reply_choose_type => 'Wählen Sie den Typ der zu sendenden Antwort';

  @override
  String get reply_command_reply_title => 'Befehlsantwort';

  @override
  String get reply_configure_workflow => 'Antwort-Workflow konfigurieren';

  @override
  String get reply_editor_title => 'Antwort-Details';

  @override
  String get reply_mode_layout => 'Layout-Modus';

  @override
  String get reply_mode_layout_desc =>
      'Discords reichhaltiges Layout-System — Container, Medien, Text & Formulare';

  @override
  String get reply_mode_modal => 'Modal-Formular';

  @override
  String get reply_mode_modal_desc => 'Pop-up-Dialog mit Texteingabefeldern';

  @override
  String get reply_mode_standard => 'Standard-Nachricht';

  @override
  String get reply_mode_standard_desc =>
      'Text, Embeds und optionale Buttons / Auswahlmenüs';

  @override
  String get reply_response_text_helper =>
      'Wird als Antworttext für Slash-Befehle verwendet. Unterstützt die ((variable)) Syntax.';

  @override
  String get reply_response_text_label => 'Antworttext';

  @override
  String get reply_response_workflow => 'Antwort-Workflow';

  @override
  String response_embeds_count(int count) {
    return '$count Embed(s)';
  }

  @override
  String get response_interactive_components => 'interaktive Komponenten';

  @override
  String get response_mode_layout => 'Layout-Modus';

  @override
  String get response_mode_modal => 'Modal-Formular';

  @override
  String get response_mode_standard => 'Standard-Nachricht';

  @override
  String get response_visibility_ephemeral => 'ephemeral';

  @override
  String get response_visibility_public => 'öffentlich';

  @override
  String get response_workflow_auto_defer =>
      'Automatisches Verzögern bei Aktionen';

  @override
  String get response_workflow_auto_defer_desc =>
      'Schnell quittieren, Aktionen ausführen, dann die endgültige Antwort bearbeiten.';

  @override
  String get response_workflow_condition_desc =>
      'Wenn die Variable existiert und nicht leer ist => THEN-Text verwenden, andernfalls ELSE-Text.';

  @override
  String get response_workflow_conditional_title => 'Bedingte Antwort (MVP)';

  @override
  String get response_workflow_deferred_reply => 'Verzögerte Antwort';

  @override
  String get response_workflow_else_text => 'ELSE Antworttext (optional)';

  @override
  String get response_workflow_enable_condition => 'Bedingung aktivieren';

  @override
  String get response_workflow_ephemeral_only_user =>
      'Ephemeral (nur für den Benutzer)';

  @override
  String get response_workflow_error_policy => 'Fehlerrichtlinie';

  @override
  String get response_workflow_error_policy_desc =>
      'Wenn eine Aktion fehlschlägt, bearbeiten Sie die verzögerte Nachricht mit einem Fehler.';

  @override
  String get response_workflow_mode_component => 'Komponente';

  @override
  String get response_workflow_mode_modal => 'Modal';

  @override
  String get response_workflow_mode_normal => 'Normal';

  @override
  String get response_workflow_public => 'Öffentlich';

  @override
  String get response_workflow_revert_tooltip =>
      'Alle Änderungen rückgängig machen';

  @override
  String get response_workflow_then_text => 'THEN Antworttext (optional)';

  @override
  String get response_workflow_title => 'Antwort-Workflow';

  @override
  String get response_workflow_variable_key =>
      'Variablenschlüssel (z. B. opts.userId)';

  @override
  String get response_workflow_visibility => 'Sichtbarkeit';

  @override
  String get restore_completed => 'Wiederherstellung abgeschlossen';

  @override
  String get restore_runtime_db_recommended =>
      'Wiederherstellung abgeschlossen (SQLite-Laufzeit wiederhergestellt, Neustart empfohlen)';

  @override
  String get review_actions_title => 'Aktionen';

  @override
  String review_description_line(String desc) {
    return 'Beschreibung: $desc';
  }

  @override
  String review_folder_line(String folder) {
    return 'Ordner: $folder';
  }

  @override
  String get review_info_title => 'Info';

  @override
  String get review_legacy_mode => 'Legacy-Modus aktiviert';

  @override
  String get review_local_only => 'Nur lokaler Befehl';

  @override
  String review_name_line(String name) {
    return 'Name: $name';
  }

  @override
  String get review_name_untitled => '(unbenannt)';

  @override
  String review_options_count(int count) {
    return '$count Option(en)';
  }

  @override
  String get review_reply_title => 'Antwort';

  @override
  String review_subcommand_routes(int count) {
    return '$count Unterbefehlsroute(n)';
  }

  @override
  String get review_trigger_inputs_title => 'Auslöser & Eingaben';

  @override
  String review_type_line(String type) {
    return 'Typ: $type';
  }

  @override
  String get rewarded_start_complete_ad =>
      'Bitte sehen Sie sich die gesamte Anzeige an, um Ihre Hosting-Sitzung zu starten.';

  @override
  String get rewarded_start_continue => 'Weiter';

  @override
  String get rewarded_start_message =>
      'Eine Anzeige ist erforderlich, um diese Hosting-Sitzung zu starten. Dies hilft, das Projekt zu finanzieren. Premium-Benutzer können dies überspringen.';

  @override
  String get rewarded_start_no_ad_available =>
      'Derzeit ist keine Anzeige verfügbar. Bitte versuchen Sie es später erneut.';

  @override
  String get rewarded_start_skip => 'Überspringen';

  @override
  String get rewarded_start_thanks => 'Danke für deine Unterstützung!';

  @override
  String get rewarded_start_title => 'Anzeige erforderlich';

  @override
  String get rewarded_start_watch => 'Anzeige ansehen';

  @override
  String get runner_select_source => 'Runner auswählen';

  @override
  String get runner_source_all => 'Alle Runner';

  @override
  String runner_source_label(String name) {
    return 'Runner: $name';
  }

  @override
  String get runner_source_local => 'Lokal';

  @override
  String get runner_source_manager => 'Bot Creator Server';

  @override
  String get runner_source_manager_unavailable =>
      'Melden Sie sich in den Einstellungen bei Bot Creator an, um Statistiken von den Bot Creator-Servern zu laden.';

  @override
  String get save => 'Speichern';

  @override
  String get scheduler_add_title => 'Zeitplan hinzufügen';

  @override
  String get scheduler_add_trigger => 'Auslöser hinzufügen';

  @override
  String scheduler_delete_confirm(String label) {
    return 'Zeitplan \"$label\" löschen?';
  }

  @override
  String get scheduler_delete_title => 'Zeitplan löschen';

  @override
  String get scheduler_edit_title => 'Zeitplan bearbeiten';

  @override
  String get scheduler_empty => 'Noch keine geplanten Auslöser.';

  @override
  String get scheduler_every_minutes => 'Alle (Minuten)';

  @override
  String get scheduler_invalid_minutes =>
      'Die Minuten müssen größer als 0 sein.';

  @override
  String get scheduler_label_field => 'Bezeichnung';

  @override
  String get scheduler_label_hint => 'Optionale Anzeigebezeichnung';

  @override
  String scheduler_limit_reached(int limit) {
    return 'Zeitplanlimit erreicht ($limit).';
  }

  @override
  String get scheduler_no_workflows =>
      'Erstellen Sie mindestens einen Workflow, bevor Sie einen Zeitplan hinzufügen.';

  @override
  String get scheduler_page_title => 'Scheduler';

  @override
  String scheduler_save_failed(String error) {
    return 'Fehler beim Speichern des Zeitplans: $error';
  }

  @override
  String scheduler_subtitle(String workflow, int minutes) {
    return 'Workflow: $workflow • Alle $minutes Min.';
  }

  @override
  String get scheduler_tab => 'Scheduler';

  @override
  String get scheduler_tab_short => 'Sched';

  @override
  String scheduler_triggers_count(int count, String limit) {
    return 'Auslöser: $count$limit';
  }

  @override
  String get scoped_default_value => 'Standardwert';

  @override
  String get scoped_default_value_hint => 'Optional';

  @override
  String scoped_delete_confirm(String key) {
    return 'Lösche \"$key\" und alle zugehörigen gespeicherten Laufzeitdaten?';
  }

  @override
  String get scoped_delete_title => 'Geltungsbereichsvariable löschen';

  @override
  String get scoped_empty => 'Keine Geltungsbereichsvariablen definiert';

  @override
  String get scoped_empty_subtitle =>
      'Geltungsbereichsvariablen speichern einen Wert pro Discord-Kontext (Benutzer, Server…). Sie werden vom Bot zur Laufzeit gefüllt.';

  @override
  String get scoped_explore_runtime => 'Laufzeitdaten erkunden';

  @override
  String scoped_ref(String ref) {
    return 'Referenz: $ref';
  }

  @override
  String scoped_ref_legacy(String ref) {
    return 'Legacy: $ref';
  }

  @override
  String get scoped_runtime_copy_all => 'Alle kopieren';

  @override
  String get scoped_runtime_empty =>
      'Keine Laufzeitdaten.\nDieser Schlüssel wird vom Bot bei der Ausführung gefüllt.';

  @override
  String get scoped_runtime_search => 'Nach ID oder Name suchen…';

  @override
  String scoped_runtime_subtitle(String scope, int count) {
    return 'Geltungsbereich: $scope · $count Kontext(e) gefunden';
  }

  @override
  String scoped_runtime_title(String key) {
    return 'Laufzeitdaten — \"$key\"';
  }

  @override
  String get scoped_scope => 'Geltungsbereich';

  @override
  String get scoped_scope_help =>
      'Die Entitätsebene, auf der die Variable gespeichert wird.';

  @override
  String get scoped_title => 'Geltungsbereichsvariablen';

  @override
  String get scratch_add_block => 'Block hinzufügen';

  @override
  String get scratch_bdfd_script => 'BDFD-Skript';

  @override
  String get scratch_block_entry_point => 'Befehlsauslöser';

  @override
  String get scratch_block_metadata => 'Metadaten';

  @override
  String get scratch_block_required => 'Erforderlich';

  @override
  String get scratch_dart_script => 'Dart-Skript';

  @override
  String get scratch_entry_event_trigger => 'Ereignisauslöser';

  @override
  String get scratch_entry_function => 'Funktion';

  @override
  String get scratch_entry_interaction => 'Slash-Befehl (/)';

  @override
  String get scratch_entry_message => 'Textnachricht';

  @override
  String get scratch_entry_point_hint => 'Scratch-Einstiegspunkt Hinweis';

  @override
  String get scratch_entry_point_label => 'Name des Einstiegspunkts';

  @override
  String get scratch_entry_point_listen =>
      'Wann wird dieser Befehl ausgeführt?';

  @override
  String get scratch_event_category => 'Ereigniskategorie';

  @override
  String get scratch_event_name => 'Ereignisname';

  @override
  String get scratch_event_variables => 'Ereignisvariablen';

  @override
  String get scratch_execution_mode => 'Wie wird der Befehl erstellt?';

  @override
  String get scratch_legacy_config => 'Legacy-Konfiguration';

  @override
  String get scratch_meta_advanced => 'Erweiterte Einstellungen';

  @override
  String get scratch_meta_desc_hint => 'Befehlsbeschreibung';

  @override
  String get scratch_meta_name_hint => 'Befehlsname';

  @override
  String get scratch_meta_type_label => 'Befehlstyp';

  @override
  String get scratch_meta_type_message => 'Nachrichtenbefehl';

  @override
  String get scratch_meta_type_message_desc =>
      'Wird über das Nachrichten-Kontextmenü ausgelöst.';

  @override
  String get scratch_meta_type_prefix => 'Präfix-Befehl';

  @override
  String get scratch_meta_type_prefix_desc =>
      'Wird durch ein Textpräfix ausgelöst (z. B. !help).';

  @override
  String get scratch_meta_type_slash => 'Slash-Befehl';

  @override
  String get scratch_meta_type_slash_desc =>
      'Wird durch Eingabe von / in Discord ausgelöst.';

  @override
  String get scratch_meta_type_user => 'Benutzerbefehl';

  @override
  String get scratch_meta_type_user_desc =>
      'Wird über das Benutzer-Kontextmenü ausgelöst.';

  @override
  String get scratch_mode_bdfd => 'BDFD-Code';

  @override
  String get scratch_mode_blocks => 'Visuell (Blöcke)';

  @override
  String get scratch_mode_dart => 'Dart';

  @override
  String get scratch_response_block => 'Antwort';

  @override
  String get scratch_response_components => 'Komponenten';

  @override
  String get scratch_response_edit => 'Antwort bearbeiten';

  @override
  String get scratch_workflow_add_argument => 'Argument hinzufügen';

  @override
  String get scratch_workflow_arguments => 'Argumente (Variablen)';

  @override
  String get scratch_workflow_metadata => 'Workflow-Einstellungen';

  @override
  String get scratch_workflow_name => 'Workflow-Name';

  @override
  String get scratch_workflow_type => 'Workflow-Typ';

  @override
  String get scratch_workflow_type_event => 'Ereignisgesteuert';

  @override
  String get scratch_workflow_type_general => 'Allgemein';

  @override
  String get serialization_export_base64_title =>
      'Befehl als Base64 exportieren';

  @override
  String get serialization_export_json_subtitle =>
      'Lesbares JSON in die Zwischenablage kopieren';

  @override
  String get serialization_export_json_title => 'Befehl als JSON exportieren';

  @override
  String get serialization_import_desc =>
      'Fügen Sie eine Befehlsnutzlast ein (JSON oder Base64).';

  @override
  String get serialization_import_title => 'Befehl importieren';

  @override
  String get serialization_imported => 'Befehl in den Editor importiert.';

  @override
  String get serialization_invalid_format =>
      'Ungültiges Format der Befehlsnutzlast.';

  @override
  String get serialization_invalid_structure =>
      'Ungültige Struktur der Befehlsnutzlast.';

  @override
  String get settings_account_connect_label =>
      'Bei Bot Creator mit Discord anmelden';

  @override
  String get settings_account_connected_hint =>
      'Konto verbunden. Ihre Bots und Daten sind jetzt mit Bot Creator synchronisiert.';

  @override
  String get settings_account_disconnect_label => 'Abmelden';

  @override
  String get settings_account_disconnected_hint =>
      'Ihr Bot Creator-Konto wird automatisch erstellt, wenn Sie einen Bot hinzufügen. Melden Sie sich dann mit Discord an, um Ihre Bots auf diesem Gerät wiederherzustellen.';

  @override
  String get settings_account_status_connected => 'Konto verbunden';

  @override
  String get settings_account_status_disconnected => 'Nicht angemeldet';

  @override
  String get settings_ads_privacy_loading =>
      'Werbedatenschutzeinstellungen werden geprüft...';

  @override
  String get settings_ads_privacy_manage =>
      'Werbedatenschutzeinstellungen verwalten';

  @override
  String get settings_ads_privacy_not_required =>
      'Werbedatenschutzoptionen sind derzeit nicht erforderlich';

  @override
  String get settings_ads_privacy_open_error =>
      'Werbedatenschutzoptionen konnten nicht geöffnet werden';

  @override
  String get settings_ads_privacy_opened => 'Werbedatenschutzoptionen geöffnet';

  @override
  String get settings_app_version => 'App';

  @override
  String get settings_appearance_title => 'Erscheinungsbild & Sprache';

  @override
  String get settings_auto_backup_check_loading => 'Auto-Backup-Prüfung…';

  @override
  String get settings_auto_backup_every_12h => 'Alle 12 Std.';

  @override
  String get settings_auto_backup_every_24h => 'Alle 24 Std.';

  @override
  String get settings_auto_backup_every_6h => 'Alle 6 Std.';

  @override
  String get settings_auto_backup_every_72h => 'Alle 72 Std.';

  @override
  String get settings_auto_backup_interval => 'Auto-Backup-Intervall';

  @override
  String get settings_backup_now => 'Jetzt sichern';

  @override
  String get settings_backup_restore_desc =>
      'Verwalten Sie Ihre Datensynchronisierung mit Google Drive';

  @override
  String get settings_backup_restore_title => 'Sichern und Wiederherstellen';

  @override
  String get settings_builtin_help => 'Integrierter Legacy !help Befehl';

  @override
  String get settings_builtin_help_subtitle =>
      'Obligatorische Funktion mit explizitem Umschalter. Deaktivieren Sie sie, wenn Sie nur ein benutzerdefiniertes Hilfe-Verhalten wünschen.';

  @override
  String get settings_clear_logs => 'Protokolle löschen';

  @override
  String get settings_cloud_hosting_enabled =>
      'Mobile Bots nutzen jetzt Bot Creator Server.';

  @override
  String get settings_compatibility_desc =>
      'Eine kurze Übersicht über die Funktionsabdeckung für Benutzer, die von BDFD kommen.';

  @override
  String get settings_compatibility_functions_category_components =>
      'Komponenten / Interaktionen';

  @override
  String get settings_compatibility_functions_category_control =>
      'Kontrollfluss';

  @override
  String get settings_compatibility_functions_category_embeds => 'Embeds';

  @override
  String get settings_compatibility_functions_category_guards =>
      'Guards und Berechtigungen';

  @override
  String get settings_compatibility_functions_category_http => 'HTTP-Helfer';

  @override
  String get settings_compatibility_functions_category_json => 'JSON-Helfer';

  @override
  String get settings_compatibility_functions_category_logging => 'Logging';

  @override
  String get settings_compatibility_functions_category_messages =>
      'Nachrichten';

  @override
  String get settings_compatibility_functions_category_runtime =>
      'Laufzeit-Platzhalter';

  @override
  String get settings_compatibility_functions_category_threads => 'Threads';

  @override
  String get settings_compatibility_functions_category_variables =>
      'Geltungsbereichsvariablen';

  @override
  String settings_compatibility_functions_count(int count) {
    return 'Kompatible Funktionen: $count';
  }

  @override
  String settings_compatibility_functions_count_bdfd(int count) {
    return 'BDFD-Referenz gesamt: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_creator(int count) {
    return 'Bot Creator unterstützt: $count';
  }

  @override
  String settings_compatibility_functions_count_bot_only(int count) {
    return 'Nur Bot Creator: $count';
  }

  @override
  String settings_compatibility_functions_count_both(int count) {
    return 'Auf beiden unterstützt: $count';
  }

  @override
  String settings_compatibility_functions_count_missing(int count) {
    return 'Fehlt in Bot Creator: $count';
  }

  @override
  String get settings_compatibility_functions_empty =>
      'Keine Funktion in diesem Abschnitt.';

  @override
  String get settings_compatibility_functions_matrix_note =>
      'BDFD-only Einträge sind Funktionen, die im bereitgestellten BDFD-Katalog aufgeführt, aber derzeit nicht in Bot Creator implementiert sind.';

  @override
  String get settings_compatibility_functions_matrix_subtitle =>
      'Diff-Ansicht zwischen Bot Creator-Implementierung und BDFD-Referenzfunktionen.';

  @override
  String get settings_compatibility_functions_note =>
      'Diese Seite wird aus dem aktuellen Implementierungsumfang generiert und wird im Laufe der Zeit wachsen.';

  @override
  String get settings_compatibility_functions_search_hint =>
      'Funktion suchen (Beispiel: \$userJoined)';

  @override
  String get settings_compatibility_functions_section_bot_only =>
      'Nur auf Bot Creator unterstützt';

  @override
  String get settings_compatibility_functions_section_bot_only_note =>
      'Loop-Helfer sind derzeit Bot Creator spezifisch.';

  @override
  String get settings_compatibility_functions_section_both =>
      'Unterstützt auf Bot Creator und BDFD';

  @override
  String get settings_compatibility_functions_section_missing =>
      'Auf BDFD verfügbar, fehlt aber in Bot Creator';

  @override
  String get settings_compatibility_functions_subtitle =>
      'Funktionen, die derzeit implementiert und im Bot Creator BDFD-Modus verwendbar sind.';

  @override
  String get settings_compatibility_functions_title =>
      'Kompatible BDFD-Funktionen';

  @override
  String get settings_compatibility_item_bdscript_desc =>
      'Vollständige Abdeckung des BDFD-Funktionskatalogs.';

  @override
  String get settings_compatibility_item_bdscript_title =>
      'BDScript Funktionsparität';

  @override
  String get settings_compatibility_item_events_desc =>
      'Die gängigsten Ereignisse werden unterstützt, einige sind laufzeitbeschränkt.';

  @override
  String get settings_compatibility_item_events_title => 'Ereignisabdeckung';

  @override
  String get settings_compatibility_item_runner_desc =>
      'Remote-Runner ist verfügbar, Multi-Runner-Unterstützung ist in Arbeit.';

  @override
  String get settings_compatibility_item_runner_title => 'Runner-Architektur';

  @override
  String get settings_compatibility_item_variables_desc =>
      'Dynamische Variablen und Vorlagen-Helfer werden unterstützt.';

  @override
  String get settings_compatibility_item_variables_title =>
      'Laufzeitvariablen und Vorlagen';

  @override
  String get settings_compatibility_item_workflows_desc =>
      'Visuelle Befehls- und Antwort-Workflows sind verfügbar.';

  @override
  String get settings_compatibility_item_workflows_title => 'Workflow-Builder';

  @override
  String get settings_compatibility_note =>
      'Dieser Snapshot ist absichtlich allgemein gehalten und wird sich mit den Releases weiterentwickeln.';

  @override
  String get settings_compatibility_open_functions =>
      'Kompatible Funktionen anzeigen';

  @override
  String get settings_compatibility_status_missing => 'Fehlt';

  @override
  String get settings_compatibility_status_partial => 'Teilweise';

  @override
  String get settings_compatibility_status_supported => 'Unterstützt';

  @override
  String get settings_compatibility_title => 'BDFD-Kompatibilitäts-Snapshot';

  @override
  String get settings_data_operations_title => 'Datenoperationen';

  @override
  String get settings_debug_desc =>
      'Lokale Einstellungen zurücksetzen oder Onboarding für Tests erneut abspielen.';

  @override
  String get settings_debug_premium_bypass => 'Premium-Bypass';

  @override
  String get settings_debug_premium_bypass_desc =>
      'Schalten Sie alle Premium-Funktionen ohne Abonnement frei (nur Debug).';

  @override
  String get settings_debug_title => 'Debug-Tools';

  @override
  String get settings_diagnostics_copied =>
      'Diagnose in die Zwischenablage kopiert';

  @override
  String get settings_diagnostics_copy_all => 'Alle Protokolle kopieren';

  @override
  String get settings_diagnostics_dialog_title => 'Startdiagnose';

  @override
  String get settings_diagnostics_empty => 'Noch keine Anwendungsprotokolle.';

  @override
  String get settings_diagnostics_page_scope_note =>
      'Zeigt nur App-Diagnoseprotokolle (Bot-Protokolle sind ausgeschlossen).';

  @override
  String get settings_diagnostics_page_title => 'Anwendungsprotokolle';

  @override
  String get settings_diagnostics_refresh => 'Protokolle aktualisieren';

  @override
  String get settings_diagnostics_section_title => 'Diagnose';

  @override
  String get settings_discord_rpc_authenticating =>
      'Authentifizierung bei Discord…';

  @override
  String get settings_discord_rpc_authorization_code_pending_exchange =>
      'Autorisierungscode zwischengespeichert; erneut versuchen, um den Token-Austausch abzuschließen';

  @override
  String get settings_discord_rpc_authorization_pending_exchange =>
      'Autorisierungscode erhalten';

  @override
  String get settings_discord_rpc_authorize => 'Autorisieren';

  @override
  String get settings_discord_rpc_authorizing =>
      'Warten auf Discord-Autorisierung…';

  @override
  String get settings_discord_rpc_broker_hint => 'https://auth.example.com';

  @override
  String get settings_discord_rpc_broker_label =>
      'OAuth-Broker-URL (erweitert, optional)';

  @override
  String get settings_discord_rpc_broker_required =>
      'Client-ID reicht für den öffentlichen Client-Flow aus; Broker-URL und Client Secret sind optionale Fallbacks';

  @override
  String get settings_discord_rpc_client_id_helper =>
      'Diese ID ist in Bot Creator fest hinterlegt und kann nicht über die Einstellungen geändert werden.';

  @override
  String get settings_discord_rpc_client_id_hint => '1350824555119382678';

  @override
  String get settings_discord_rpc_client_id_required =>
      'Discord-Anwendungs-Client-ID erforderlich';

  @override
  String get settings_discord_rpc_client_secret_helper =>
      'Optionaler erweiterter Fallback für einen vertraulichen Client-Flow, der lokal verarbeitet wird.';

  @override
  String get settings_discord_rpc_client_secret_hint => 'Client Secret';

  @override
  String get settings_discord_rpc_client_secret_label =>
      'Discord-Anwendung Client Secret (optional)';

  @override
  String get settings_discord_rpc_complete_authorization =>
      'Autorisierung abschließen';

  @override
  String get settings_discord_rpc_connect => 'Präsenz aktualisieren';

  @override
  String get settings_discord_rpc_connected => 'Präsenz an Discord gesendet';

  @override
  String get settings_discord_rpc_connecting =>
      'Verbindung zu Discord wird hergestellt…';

  @override
  String get settings_discord_rpc_desc =>
      'Veröffentlichen Sie Desktop-Aktivitäten von Bot Creator im lokalen Discord-Client. Bot Creator verwendet immer die integrierte Discord-Anwendung und sendet SET_ACTIVITY direkt über lokale IPC, wenn aktiviert.';

  @override
  String get settings_discord_rpc_disabled => 'Deaktiviert';

  @override
  String get settings_discord_rpc_disconnect => 'IPC schließen';

  @override
  String get settings_discord_rpc_disconnected => 'IPC geschlossen';

  @override
  String get settings_discord_rpc_enable => 'Discord Rich Presence aktivieren';

  @override
  String get settings_discord_rpc_enable_first =>
      'Zuerst Discord Rich Presence aktivieren';

  @override
  String settings_discord_rpc_endpoint(String endpoint) {
    return 'IPC-Endpunkt: $endpoint';
  }

  @override
  String get settings_discord_rpc_error => 'Discord RPC-Fehler';

  @override
  String get settings_discord_rpc_exchanging_code =>
      'OAuth-Austausch wird abgeschlossen…';

  @override
  String get settings_discord_rpc_ipc_connected_auth_required =>
      'Lokale Discord-IPC verbunden; noch keine OAuth-HTTP-Anfrage gesendet, Authentifizierung weiterhin erforderlich';

  @override
  String get settings_discord_rpc_ipc_open => 'Lokale IPC bereits offen';

  @override
  String settings_discord_rpc_last_error(String error) {
    return 'Letzter Fehler: $error';
  }

  @override
  String get settings_discord_rpc_needs_authorization =>
      'Autorisierung erforderlich';

  @override
  String get settings_discord_rpc_not_configured => 'Client-ID erforderlich';

  @override
  String get settings_discord_rpc_open_ipc => 'Lokale IPC öffnen';

  @override
  String get settings_discord_rpc_platform_unsupported =>
      'Discord Rich Presence ist nur für Desktop verfügbar';

  @override
  String get settings_discord_rpc_save => 'Einstellungen speichern';

  @override
  String get settings_discord_rpc_saved =>
      'Discord Rich Presence-Einstellungen gespeichert';

  @override
  String get settings_discord_rpc_title => 'Discord Rich Presence';

  @override
  String get settings_discord_rpc_transport_unsupported =>
      'Discord-Transport wird auf dieser Plattform noch nicht unterstützt';

  @override
  String settings_discord_rpc_user(String user) {
    return 'Autorisierter Benutzer: $user';
  }

  @override
  String get settings_drive_connect => 'Mit Google Drive verbinden';

  @override
  String get settings_drive_connect_loading =>
      'Verbindung zu Google Drive wird hergestellt…';

  @override
  String get settings_drive_connected => 'Mit Google Drive verbunden';

  @override
  String get settings_drive_desc =>
      'Verbinden Sie Ihr Google Drive Konto, um Ihre Daten zu synchronisieren';

  @override
  String get settings_drive_disconnect => 'Trennen';

  @override
  String get settings_drive_disconnect_loading => 'Trennung…';

  @override
  String get settings_drive_disconnected => 'Von Google Drive getrennt';

  @override
  String get settings_drive_status_connected => 'Verbunden';

  @override
  String get settings_drive_title => 'Google Drive Verbindung';

  @override
  String get settings_enable_auto_backup => 'Auto-Backup aktivieren';

  @override
  String get settings_enable_auto_backup_desc =>
      'Erstellt automatisch versionierte Snapshots, wenn fällig.';

  @override
  String get settings_execution_mode_desc =>
      'Auf dieser Plattform hostet Bot Creator niemals Ihre Bots. Sie können Ihren selbst gehosteten Runner verwenden oder Bots lokal ausführen.';

  @override
  String get settings_execution_mode_local_active =>
      'Bots starten jetzt lokal. Runner-Einstellungen bleiben gespeichert und können jederzeit wieder aktiviert werden.';

  @override
  String get settings_execution_mode_no_runner =>
      'Es ist noch kein Runner konfiguriert. Die App bleibt lokal, bis Sie einen hinzufügen.';

  @override
  String get settings_execution_mode_runner_priority =>
      'Der selbst gehostete Runner wird bevorzugt. Wenn kein Runner konfiguriert ist, fällt die App auf lokal zurück.';

  @override
  String get settings_execution_mode_title => 'Ausführungsmodus';

  @override
  String get settings_execution_mode_use_runner =>
      'Einen selbst gehosteten Runner verwenden';

  @override
  String get settings_export => 'Exportieren';

  @override
  String get settings_export_app_data => 'App-Daten exportieren';

  @override
  String get settings_export_loading => 'Exportieren…';

  @override
  String get settings_import => 'Importieren';

  @override
  String get settings_import_app_data => 'App-Daten importieren';

  @override
  String get settings_import_loading => 'Importieren…';

  @override
  String get settings_language_desc =>
      'Wählen Sie die von der App verwendete Sprache.';

  @override
  String get settings_language_system => 'Automatisch (Gerät)';

  @override
  String get settings_language_title => 'Sprache';

  @override
  String get settings_language_updated => 'Sprache aktualisiert';

  @override
  String settings_last_auto_backup_at(String date) {
    return 'Letztes Auto-Backup: $date';
  }

  @override
  String get settings_last_auto_backup_never => 'Letztes Auto-Backup: nie';

  @override
  String get settings_legacy_prefix => 'Präfix für Legacy-Befehle';

  @override
  String get settings_legacy_prefix_helper =>
      'Unterstützt Vorlagen und Geltungsbereichsvariablen (bc_ optional). Beispiel: ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legacy_prefix_hint =>
      '!, ? oder ((guild.prefix | user.prefix | !))';

  @override
  String get settings_legal_desc =>
      'Überprüfen Sie, wie Ihre Daten gehandhabt und gespeichert werden.';

  @override
  String get settings_legal_title => 'Rechtliches';

  @override
  String get settings_oss_licenses => 'Open-Source-Lizenzen';

  @override
  String get settings_local_hosting_enabled =>
      'Mobile Bots nutzen jetzt Ihr Gerät für das Hosting.';

  @override
  String get settings_logs_cleared => 'Diagnoseprotokoll gelöscht';

  @override
  String get settings_main_api_auth_failed =>
      'Bot Creator Server-Sitzung ist ungültig oder abgelaufen';

  @override
  String get settings_main_api_check => 'Bot Creator Server prüfen';

  @override
  String get settings_main_api_clear => 'Löschen';

  @override
  String get settings_main_api_cleared =>
      'Bot Creator Server-Einstellungen gelöscht';

  @override
  String get settings_main_api_connect_discord => 'Discord-Konto verbinden';

  @override
  String get settings_main_api_connected => 'Bot Creator Server erreichbar ✓';

  @override
  String get settings_main_api_connected_discord => 'Discord-Konto verbunden';

  @override
  String settings_main_api_connected_user(String user) {
    return 'Verbunden als $user';
  }

  @override
  String get settings_main_api_desc =>
      'Verbinden Sie Bot Creator mit Ihrem Bot Creator Server und melden Sie sich mit Discord an. Das Discord Client Secret muss auf dem Backend bleiben.';

  @override
  String get settings_main_api_desktop_only =>
      'Discord-Login über Bot Creator Server ist nur auf dem Desktop verfügbar.';

  @override
  String get settings_main_api_disconnect => 'Konto trennen';

  @override
  String get settings_main_api_not_configured =>
      'Bot Creator Server-URL erforderlich';

  @override
  String get settings_main_api_save => 'Bot Creator Server speichern';

  @override
  String get settings_main_api_saved =>
      'Bot Creator Server-Einstellungen gespeichert';

  @override
  String get settings_main_api_session_connected => 'Discord-Sitzung aktiv';

  @override
  String get settings_main_api_session_disconnected =>
      'Discord-Sitzung getrennt';

  @override
  String get settings_main_api_session_expired => 'Discord-Sitzung abgelaufen';

  @override
  String get settings_main_api_title => 'Bot Creator Server';

  @override
  String get settings_main_api_unreachable =>
      'Bot Creator Server nicht erreichbar';

  @override
  String get settings_main_api_url_hint => 'https://api.example.com';

  @override
  String get settings_main_api_url_required =>
      'Bot Creator Server-URL erforderlich';

  @override
  String get settings_main_api_user_unknown => 'Discord-Benutzer';

  @override
  String get settings_manual_snapshot_label => 'Manueller Snapshot';

  @override
  String get settings_notifications_desc =>
      'Wählen Sie aus, welche Push-Benachrichtigungen Sie erhalten möchten.';

  @override
  String get settings_notifications_title => 'Benachrichtigungen';

  @override
  String get settings_notifications_topic_billing => 'Abrechnung';

  @override
  String get settings_notifications_topic_billing_desc =>
      'Erinnerungen zur Abonnement-Verlängerung und Zahlungsbestätigungen.';

  @override
  String get settings_notifications_topic_botAlerts => 'Bot-Warnungen';

  @override
  String get settings_notifications_topic_botAlerts_desc =>
      'Warnungen, wenn Ihre Bots offline gehen oder Fehler auftreten.';

  @override
  String get settings_notifications_topic_broadcast => 'Ankündigungen';

  @override
  String get settings_notifications_topic_broadcast_desc =>
      'Wichtige Ankündigungen und Neuigkeiten von Bot Creator.';

  @override
  String get settings_notifications_topic_updates => 'Updates';

  @override
  String get settings_notifications_topic_updates_desc =>
      'Neue Funktionen, App-Updates und Changelog-Highlights.';

  @override
  String get settings_open_ad_inspector => 'Anzeigen-Inspektor öffnen';

  @override
  String get settings_preferences_reset_done => 'Einstellungen zurückgesetzt';

  @override
  String get settings_privacy_policy => 'Datenschutzerklärung';

  @override
  String get settings_recovery_title => 'Recovery Pro';

  @override
  String get settings_replay_onboarding => 'Onboarding erneut abspielen';

  @override
  String get settings_replay_onboarding_desc =>
      'Onboarding zurücksetzen und jetzt erneut starten.';

  @override
  String get settings_reset_preferences => 'Einstellungen zurücksetzen';

  @override
  String get settings_reset_preferences_desc =>
      'Design, Sprache und Onboarding-Fortschritt zurücksetzen.';

  @override
  String get settings_restore_snapshot => 'Diesen Snapshot wiederherstellen';

  @override
  String get settings_run_auto_backup_now => 'Auto-Backup jetzt ausführen';

  @override
  String get settings_run_diagnostics => 'Diagnose ausführen';

  @override
  String settings_runner_active(String url) {
    return 'Aktive Runner-API: $url';
  }

  @override
  String get settings_runner_auth_failed =>
      'Runner hat das API-Token abgelehnt';

  @override
  String get settings_runner_check => 'Verbindung prüfen';

  @override
  String get settings_runner_clear => 'Löschen';

  @override
  String get settings_runner_cleared => 'Runner-Einstellungen gelöscht';

  @override
  String get settings_runner_connected => 'Runner erreichbar ✓';

  @override
  String get settings_runner_connecting => 'Verbindung wird geprüft…';

  @override
  String get settings_runner_desc =>
      'Verbinden Sie die App mit einem Bot Creator Runner. Remote-Runner sollten in vertrauenswürdigen Netzwerken bleiben und ein Bearer-Token verwenden.';

  @override
  String get settings_runner_disable_temp =>
      'Runner vorübergehend deaktivieren';

  @override
  String get settings_runner_disable_temp_desc =>
      'Runner-Einstellungen beibehalten, aber lokalen Modus erzwingen, bis er wieder aktiviert wird.';

  @override
  String get settings_runner_disconnected => 'Runner getrennt';

  @override
  String get settings_runner_not_connected => 'Nicht verbunden';

  @override
  String get settings_runner_reenabled => 'Runner reaktiviert';

  @override
  String get settings_runner_save => 'Einstellungen speichern';

  @override
  String get settings_runner_saved => 'Runner-Einstellungen gespeichert';

  @override
  String get settings_runner_temporarily_disabled =>
      'Runner vorübergehend deaktiviert (lokaler Modus aktiv)';

  @override
  String get settings_runner_temporarily_disabled_saved =>
      'Runner vorübergehend deaktiviert';

  @override
  String get settings_runner_title => 'Runner-API';

  @override
  String get settings_runner_token_hint =>
      'Bearer-Token (optional auf localhost)';

  @override
  String get settings_runner_token_label => 'Runner API-Token';

  @override
  String get settings_runner_unreachable => 'Runner nicht erreichbar';

  @override
  String get settings_runner_url_clear => 'Löschen';

  @override
  String get settings_runner_url_cleared => 'Runner-URL gelöscht';

  @override
  String get settings_runner_url_hint => 'http://192.168.1.x:8080';

  @override
  String get settings_runner_url_save => 'URL speichern';

  @override
  String get settings_runner_url_saved => 'Runner-URL gespeichert';

  @override
  String get settings_runner_version => 'Runner';

  @override
  String settings_snapshot_apps_count(int count) {
    return 'Apps: $count';
  }

  @override
  String get settings_snapshot_apps_list => 'Apps in diesem Snapshot';

  @override
  String get settings_snapshot_create_loading => 'Snapshot wird erstellt…';

  @override
  String settings_snapshot_created_at(String date) {
    return 'Erstellt: $date';
  }

  @override
  String settings_snapshot_created_message(String id) {
    return 'Snapshot erstellt: $id';
  }

  @override
  String get settings_snapshot_delete_loading => 'Snapshot wird gelöscht…';

  @override
  String get settings_snapshot_deleted => 'Snapshot gelöscht';

  @override
  String settings_snapshot_files_size(int count, String size) {
    return 'Dateien: $count • Größe: $size';
  }

  @override
  String settings_snapshot_id(String id) {
    return 'ID: $id';
  }

  @override
  String settings_snapshot_label(String label) {
    return 'Bezeichnung: $label';
  }

  @override
  String settings_snapshot_list_entry(String date, int count, String size) {
    return '$date • $count Dateien • $size';
  }

  @override
  String get settings_snapshot_no_metadata => 'Keine App-Metadaten verfügbar.';

  @override
  String get settings_snapshot_preview_title => 'Snapshot-Vorschau';

  @override
  String get settings_snapshot_restore_loading =>
      'Snapshot wird wiederhergestellt…';

  @override
  String get settings_snapshots_delete_all => 'Alle Snapshots löschen';

  @override
  String settings_snapshots_delete_all_confirm(int count) {
    return 'Dauerhaft $count Snapshot(s) löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String settings_snapshots_delete_all_done(int count) {
    return '$count Snapshot(s) gelöscht.';
  }

  @override
  String get settings_snapshots_delete_all_loading =>
      'Alle Snapshots werden gelöscht…';

  @override
  String get settings_snapshots_delete_all_title => 'Alle Snapshots löschen';

  @override
  String settings_snapshots_delete_one_confirm(String label) {
    return 'Dauerhaft \"$label\" löschen? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get settings_snapshots_delete_select_desc =>
      'Wählen Sie den zu entfernenden Snapshot aus (ältester zuerst).';

  @override
  String get settings_snapshots_delete_select_title => 'Einen Snapshot löschen';

  @override
  String get settings_snapshots_delete_select_tooltip =>
      'Einen ausgewählten Snapshot löschen';

  @override
  String get settings_snapshots_empty => 'Noch keine Snapshots gefunden.';

  @override
  String get settings_snapshots_refresh => 'Snapshots aktualisieren';

  @override
  String get settings_snapshots_refresh_loading =>
      'Snapshots werden aktualisiert…';

  @override
  String get settings_snapshots_title => 'Snapshots';

  @override
  String get settings_startup_mode_cloud_desc =>
      'Empfohlen für Android und iOS. Protokolle, Statistiken und Start erfolgen über Bot Creator.';

  @override
  String get settings_startup_mode_desc =>
      'Wählen Sie, ob Ihre Bots auf Bot Creator-Servern oder lokal auf diesem Gerät starten.';

  @override
  String get settings_startup_mode_ios_unavailable =>
      'Der lokale Modus bleibt auf iOS nicht verfügbar.';

  @override
  String get settings_startup_mode_ios_warning =>
      'Auf iOS wird der lokale Modus nicht unterstützt. Bots verwenden immer Bot Creator-Server.';

  @override
  String get settings_startup_mode_local_desc =>
      'Bots starten jetzt lokal auf diesem Gerät.';

  @override
  String get settings_startup_mode_local_warning =>
      'Der lokale Modus ist eine erweiterte Option für Debugging oder spezifische Anforderungen. Lassen Sie für den normalen Gebrauch die Bot Creator-Server aktiviert.';

  @override
  String get settings_startup_mode_title => 'Bot-Startmodus';

  @override
  String get settings_startup_mode_use_cloud => 'Bot Creator-Server verwenden';

  @override
  String get settings_status_remove_confirm =>
      'Dieser Statuseintrag wird entfernt. Fortfahren?';

  @override
  String get settings_tab => 'Einstellungen';

  @override
  String get settings_theme_switch_dark => 'Zum dunklen Modus wechseln';

  @override
  String get settings_theme_switch_light => 'Zum hellen Modus wechseln';

  @override
  String get settings_version_title => 'Version';

  @override
  String get settings_view_startup_logs => 'Startprotokolle anzeigen';

  @override
  String get startup_copy_diagnostics => 'Diagnose kopieren';

  @override
  String get startup_diagnostics_copied =>
      'Diagnose in die Zwischenablage kopiert';

  @override
  String get startup_error_title => 'Startfehler';

  @override
  String get startup_failed_message =>
      'Bot Creator konnte auf diesem Gerät nicht gestartet werden.';

  @override
  String get startup_refresh_diagnostics => 'Diagnose aktualisieren';

  @override
  String get subscription_active_annual => 'Premium — Jährlich';

  @override
  String get subscription_active_label => 'Aktiver Plan:';

  @override
  String get subscription_active_monthly => 'Premium — Monatlich';

  @override
  String get subscription_annual_title => 'Jährlich';

  @override
  String get subscription_benefit_fast_start =>
      'Bots starten sofort, kein Pop-up';

  @override
  String get subscription_benefit_no_ads =>
      'Keine Anzeigen in der gesamten App';

  @override
  String get subscription_benefit_support =>
      'Unterstützen Sie die unabhängige Entwicklung';

  @override
  String get subscription_error =>
      'Kauf konnte nicht abgeschlossen werden. Bitte versuchen Sie es erneut.';

  @override
  String get subscription_error_product_unavailable =>
      'Dieser Plan ist derzeit nicht verfügbar. Bitte versuchen Sie es später erneut.';

  @override
  String get subscription_error_purchase_start_failed =>
      'Kauf konnte nicht gestartet werden. Bitte versuchen Sie es erneut.';

  @override
  String get subscription_error_store_unavailable =>
      'Der App Store ist derzeit nicht verfügbar. Bitte versuchen Sie es in einem Moment erneut.';

  @override
  String get subscription_feature_analytics_desc =>
      'Zugriff auf Fehlerrate, Latenz-Perzentile und Locale-Einblicke.';

  @override
  String get subscription_feature_analytics_title => 'Erweiterte Analysen';

  @override
  String get subscription_feature_auto_restart_desc =>
      'Den Bot automatisch neu starten, wenn ein vollständiger Neustart erforderlich ist.';

  @override
  String get subscription_feature_auto_restart_title =>
      'Automatischer Neustart';

  @override
  String get subscription_feature_auto_sharding_desc =>
      'Skalieren Sie große Bots, indem Sie die Last auf Shard-Worker verteilen.';

  @override
  String get subscription_feature_auto_sharding_title =>
      'Automatisches Sharding';

  @override
  String get subscription_feature_coming_soon => 'Demnächst verfügbar';

  @override
  String get subscription_feature_debug_replay_desc =>
      'Befehlsaktionen Schritt für Schritt aufzeichnen und zur Fehlersuche abspielen.';

  @override
  String get subscription_feature_debug_replay_title =>
      'Visuelle Debug-Wiedergabe';

  @override
  String get subscription_feature_instant_start_desc =>
      'Starten Sie Bots sofort ohne Unterbrechung durch belohnte Anzeigen.';

  @override
  String get subscription_feature_instant_start_title => 'Sofortiger Start';

  @override
  String get subscription_feature_no_ads_desc =>
      'Entfernen Sie alle Werbeplatzierungen in der gesamten App.';

  @override
  String get subscription_feature_no_ads_title => 'Keine Anzeigen';

  @override
  String get subscription_feature_scheduler_desc =>
      'Workflows automatisch alle X Minuten ausführen (bis zu 10 aktive).';

  @override
  String get subscription_feature_scheduler_title => 'Scheduler-Trigger';

  @override
  String get subscription_feature_webhooks_desc =>
      'Erstellen Sie sichere Webhook-Endpunkte und leiten Sie Aufrufe an Workflows weiter.';

  @override
  String get subscription_feature_webhooks_title => 'Inbound Webhooks';

  @override
  String get subscription_manage => 'Abonnement verwalten';

  @override
  String get subscription_monthly_title => 'Monatlich';

  @override
  String get subscription_not_available_on_platform =>
      'Abonnements sind derzeit nur auf dem Handy verfügbar.';

  @override
  String get subscription_per_month => 'pro Monat';

  @override
  String get subscription_per_year => 'pro Jahr';

  @override
  String get subscription_plan_desc =>
      'Anzeigen entfernen und Zugriff auf alle aktuellen und kommenden Premium-Funktionen erhalten.';

  @override
  String get subscription_plan_label => 'Premium Basic';

  @override
  String get subscription_privacy => 'Datenschutzerklärung';

  @override
  String get subscription_restore => 'Käufe wiederherstellen';

  @override
  String get subscription_restore_not_found =>
      'Kein aktives Abonnement gefunden.';

  @override
  String get subscription_restored =>
      'Abonnement erfolgreich wiederhergestellt!';

  @override
  String get subscription_save_badge => '67% SPAREN';

  @override
  String get subscription_subtitle =>
      'Wählen Sie einen Plan aus, um alle Premium-Funktionen freizuschalten.';

  @override
  String get subscription_success =>
      'Willkommen bei Premium! Alle Anzeigen wurden entfernt.';

  @override
  String get subscription_terms => 'Nutzungsbedingungen';

  @override
  String get subscription_title => 'Premium';

  @override
  String get subscription_unavailable_platform =>
      'Auf dieser Plattform nicht verfügbar.';

  @override
  String get support_card_desc =>
      'Eine Frage, ein Bug, ein Vorschlag? Kommen Sie und chatten Sie mit dem Team und der Community.';

  @override
  String get support_card_title => 'Support & Community';

  @override
  String get support_discord_badge => 'Offizieller Support';

  @override
  String get support_join_discord => 'Tritt dem Discord-Server bei';

  @override
  String get template_fun_description =>
      'Münzwurf, Umfragen und Wahrsagekugel.';

  @override
  String get template_fun_name => 'Fun-Bot';

  @override
  String template_gallery_already_exists(String name) {
    return 'Befehl \"$name\" existiert bereits und wurde übersprungen.';
  }

  @override
  String get template_gallery_apply => 'Diese Vorlage verwenden';

  @override
  String template_gallery_apply_error(String error) {
    return 'Vorlage konnte nicht angewendet werden: $error';
  }

  @override
  String template_gallery_apply_success(int count, int wCount) {
    return '$count Befehl(e) und $wCount Workflow(s) aus Vorlage hinzugefügt.';
  }

  @override
  String template_gallery_commands_count(int count) {
    return '$count Befehl(e)';
  }

  @override
  String get template_gallery_empty => 'Keine Vorlagen verfügbar.';

  @override
  String template_gallery_nothing_to_remove(String name) {
    return 'Nichts zu entfernen für $name.';
  }

  @override
  String get template_gallery_remove_confirm =>
      'Sind Sie sicher, dass Sie alle Befehle und Workflows aus dieser Vorlage entfernen möchten?';

  @override
  String get template_gallery_remove_title => 'Vorlage entfernen';

  @override
  String get template_gallery_removed =>
      'Vorlagenbefehle und -workflows entfernt.';

  @override
  String get template_gallery_subtitle =>
      'Starten Sie Ihren Bot schnell mit einer fertigen Vorlage.';

  @override
  String get template_gallery_sync_warning =>
      'Befehle lokal gespeichert. Starten Sie Ihren Bot, um sie bei Discord zu registrieren.';

  @override
  String get template_gallery_title => 'Vorlagen';

  @override
  String template_gallery_workflows_count(int count) {
    return '$count Workflow(s)';
  }

  @override
  String get template_moderation_description =>
      'Mitglieder bannen, kicken, stummschalten und Nachrichten löschen.';

  @override
  String get template_moderation_name => 'Moderations-Bot';

  @override
  String get template_utility_description =>
      'Ping, Avatar-Suche und Bot-sagt-Befehle.';

  @override
  String get template_utility_name => 'Utility-Bot';

  @override
  String get template_welcome_description =>
      'Begrüßen Sie neue Mitglieder, sagen Sie Hallo und zeigen Sie Server-Infos an.';

  @override
  String get template_welcome_name => 'Willkommens-Bot';

  @override
  String unit_day(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
      zero: '0 Tage',
    );
    return '$_temp0';
  }

  @override
  String unit_hour(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stunden',
      one: '1 Stunde',
      zero: '0 Stunden',
    );
    return '$_temp0';
  }

  @override
  String unit_minute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Minuten',
      one: '1 Minute',
      zero: '0 Minuten',
    );
    return '$_temp0';
  }

  @override
  String unit_month(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Monate',
      one: '1 Monat',
      zero: '0 Monate',
    );
    return '$_temp0';
  }

  @override
  String get validation_awaited_callback_format =>
      'Erwarteter Callback muss \$awaitedCommand[name;filter] oder \$awaitedCommandError[name] verwenden.';

  @override
  String validation_awaited_callback_length(int max) {
    return 'Der Auslöser für den erwarteten Callback darf höchstens $max Zeichen lang sein';
  }

  @override
  String get validation_awaited_callback_local_only =>
      'Erwartete Callbacks erfordern einen rein lokalen Legacy-Befehl.';

  @override
  String get validation_command_name_invalid_chars =>
      'Der Befehlsname darf nur Buchstaben, Zahlen und Unterstriche enthalten';

  @override
  String validation_command_name_length(int max) {
    return 'Der Befehlsname darf höchstens $max Zeichen lang sein';
  }

  @override
  String get validation_command_name_no_ampersand =>
      'Der Befehlsname darf nicht mit einem Ampersand beginnen';

  @override
  String get validation_command_name_no_at =>
      'Der Befehlsname darf nicht mit einem At-Zeichen beginnen';

  @override
  String get validation_command_name_no_exclamation =>
      'Der Befehlsname darf nicht mit einem Ausrufezeichen beginnen';

  @override
  String get validation_command_name_no_hash =>
      'Der Befehlsname darf nicht mit einer Raute beginnen';

  @override
  String get validation_command_name_no_percent =>
      'Der Befehlsname darf nicht mit einem Prozentzeichen beginnen';

  @override
  String get validation_command_name_no_slash =>
      'Der Befehlsname darf nicht mit einem Schrägstrich beginnen';

  @override
  String get validation_command_name_no_spaces =>
      'Der Befehlsname darf keine Leerzeichen enthalten';

  @override
  String get validation_command_name_no_underscore =>
      'Der Befehlsname darf nicht mit einem Unterstrich beginnen';

  @override
  String get validation_command_name_required =>
      'Bitte geben Sie einen Befehlsnamen ein';

  @override
  String get validation_interaction_no_response =>
      'Interaktionsbefehle müssen mindestens eine Antwortaktion enthalten (Mit Nachricht antworten, Komponente V2 oder Modal).';

  @override
  String get validation_interaction_no_response_short => 'Keine Antwortaktion';

  @override
  String get validation_invalid_permissions =>
      'Ungültiges Bitfeld für Standard-Mitgliedsberechtigungen. Verwenden Sie eine positive Ganzzahl oder lassen Sie es leer.';

  @override
  String get validation_legacy_chat_input_only =>
      'Der Legacy-Modus ist nur für Chat-Eingabebefehle verfügbar.';

  @override
  String get validation_legacy_only_new_or_local =>
      'Der Modus \'Nur Legacy\' kann nur für neue Befehle oder bestehende lokale Befehle verwendet werden.';

  @override
  String get validation_legacy_only_requires_legacy =>
      'Befehle im Modus \'Nur Legacy\' erfordern die Aktivierung des Legacy-Modus.';

  @override
  String get validation_modal_not_legacy =>
      'Modal-Antworten werden im Legacy-Befehlsmodus nicht unterstützt.';

  @override
  String get validation_option_description_required =>
      'Jede Option muss eine Beschreibung haben.';

  @override
  String get validation_option_group_only_subcommands =>
      'Eine SubCommandGroup kann nur Unterbefehlsoptionen enthalten.';

  @override
  String get validation_option_group_top_level_only =>
      'SubCommandGroup ist nur auf der obersten Ebene zulässig.';

  @override
  String get validation_option_hierarchy_no_choices =>
      'Unterbefehl und Unterbefehl-Gruppe können keine Auswahlmöglichkeiten definieren.';

  @override
  String get validation_option_hierarchy_no_min_max =>
      'Unterbefehl und Unterbefehl-Gruppe können keine Mindest-/Höchstwerte definieren.';

  @override
  String get validation_option_hierarchy_not_required =>
      'Unterbefehl und Unterbefehl-Gruppe können nicht als erforderlich markiert werden.';

  @override
  String get validation_option_leaf_no_nested =>
      'Reguläre Optionen können keine verschachtelten Optionen enthalten.';

  @override
  String get validation_option_max_entries =>
      'Jede Optionsebene unterstützt höchstens 25 Einträge.';

  @override
  String validation_option_name_duplicate(String name) {
    return 'Doppelter Optionsname \"$name\" auf derselben Ebene.';
  }

  @override
  String get validation_option_name_required =>
      'Jede Option muss einen Namen haben.';

  @override
  String get validation_option_no_mix_top_level =>
      'Optionen auf oberster Ebene dürfen Unterbefehle/-gruppen nicht mit regulären Optionen mischen.';

  @override
  String get validation_option_subcommand_depth =>
      'Die Verschachtelungstiefe der Unterbefehle überschreitet die Discord-Limits.';

  @override
  String get validation_option_subcommand_no_nested =>
      'Ein Unterbefehl kann keine verschachtelten Unterbefehle oder Unterbefehl-Gruppen enthalten.';

  @override
  String get webhooks_actions => 'Aktionen';

  @override
  String get webhooks_add_action => 'Webhook hinzufügen';

  @override
  String get webhooks_add_title => 'Inbound-Webhook hinzufügen';

  @override
  String get webhooks_copied => 'Vollständige Webhook-URL kopiert.';

  @override
  String get webhooks_copy_path => 'Pfad kopieren';

  @override
  String get webhooks_copy_secret => 'Secret kopieren';

  @override
  String get webhooks_copy_url => 'URL kopieren';

  @override
  String webhooks_count(int count, String limit) {
    return 'Webhooks: $count$limit';
  }

  @override
  String webhooks_delete_confirm(String label) {
    return 'Lösche \"$label\"? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get webhooks_delete_confirm_no_label =>
      'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get webhooks_delete_title => 'Inbound-Webhook löschen?';

  @override
  String get webhooks_edit_title => 'Inbound-Webhook bearbeiten';

  @override
  String get webhooks_empty => 'Noch keine Inbound-Webhooks.';

  @override
  String get webhooks_generate => 'Generieren';

  @override
  String get webhooks_invalid_runner_url => 'Runner-URL ist ungültig.';

  @override
  String webhooks_limit_reached(int limit) {
    return 'Inbound-Webhook-Limit erreicht ($limit).';
  }

  @override
  String get webhooks_missing_data => 'Webhook-Pfad oder Secret fehlt.';

  @override
  String get webhooks_no_workflows =>
      'Erstellen Sie mindestens einen Workflow, bevor Sie einen Inbound-Webhook hinzufügen.';

  @override
  String get webhooks_page_title => 'Inbound-Webhooks';

  @override
  String get webhooks_path_copied => 'Pfad kopiert.';

  @override
  String get webhooks_path_exists =>
      'Dieser Pfad existiert bereits. Wählen Sie einen anderen.';

  @override
  String get webhooks_path_hint => 'bestellungen/neu';

  @override
  String get webhooks_path_label => 'Pfad';

  @override
  String get webhooks_runner_url_required =>
      'Konfigurieren Sie zuerst eine Runner-URL, um die vollständige Webhook-URL zu kopieren.';

  @override
  String webhooks_save_failed(String error) {
    return 'Fehler beim Speichern des Inbound-Webhooks: $error';
  }

  @override
  String get webhooks_secret_copied => 'Secret kopiert.';

  @override
  String get webhooks_secret_label => 'Webhook-Secret';

  @override
  String get webhooks_target_label => 'Workflow-Ziel';

  @override
  String webhooks_workflow_subtitle(String workflow) {
    return 'Workflow: $workflow';
  }

  @override
  String get wizard_advanced_trigger => 'Erweiterte Auslösereinstellungen';

  @override
  String get wizard_apply_quick_start => 'Schnellstart auf Entwurf anwenden';

  @override
  String get wizard_bdfd_mode_enabled => 'BDFD-Skriptmodus aktiviert';

  @override
  String get wizard_code_advanced => 'Code / Erweitert';

  @override
  String get wizard_command_body => 'Befehlskörper';

  @override
  String get wizard_create_command => 'Befehl erstellen';

  @override
  String get wizard_dart_mode_enabled => 'Dart-Skriptmodus aktiviert';

  @override
  String get wizard_edit_reply => 'Antwortdetails bearbeiten';

  @override
  String get wizard_legacy_options_subtitle =>
      'Optionen für Legacy-Befehle und rein lokales Verhalten';

  @override
  String get wizard_quick_start_applied =>
      'Schnellstart auf den Befehlsentwurf angewendet.';

  @override
  String get wizard_quick_start_subtitle =>
      'Verwenden Sie den einfachen Legacy-Builder als Ausgangspunkt und wenden Sie ihn dann auf den gemeinsamen Entwurf an.';

  @override
  String get wizard_quick_starts => 'Schnellstarts';

  @override
  String get wizard_reply_summary => 'Antwort-Zusammenfassung';

  @override
  String get wizard_save_command => 'Befehl speichern';

  @override
  String get wizard_step_actions => 'Aktionen';

  @override
  String get wizard_step_infos => 'Infos';

  @override
  String get wizard_step_reply => 'Antwort';

  @override
  String get wizard_step_review => 'Überprüfung';

  @override
  String get wizard_step_trigger_inputs => 'Auslöser & Eingaben';

  @override
  String get wizard_visual_mode_enabled => 'Visueller Workflow-Modus aktiviert';

  @override
  String get workflow_argument_hint =>
      'Workflow-Argument (erreichbar über \$arg)';

  @override
  String get workflow_arguments_section => 'Workflow-Argumente';

  @override
  String get workflow_auto_defer => 'Automatisches Verzögern';

  @override
  String get workflow_auto_defer_actions => 'Auto-Verzögern bei Aktionen';

  @override
  String get workflow_bdfd_editor_desc =>
      'Schreiben Sie den vollständigen BDFD-Code für diese Workflow-Antwort. Diagnosen werden live angezeigt.';

  @override
  String get workflow_bdfd_editor_title => 'BDFD-Skript-Editor';

  @override
  String get workflow_condition_off => 'Bedingung aus';

  @override
  String get workflow_condition_off_upper => 'Bedingung AUS';

  @override
  String get workflow_condition_on => 'Bedingung an';

  @override
  String get workflow_condition_on_upper => 'Bedingung AN';

  @override
  String get workflow_dart_editor_desc =>
      'Schreiben Sie den vollständigen Dart-Code für diese Workflow-Antwort. Diagnosen werden live angezeigt.';

  @override
  String get workflow_dart_editor_title => 'Dart-Skript-Editor';

  @override
  String workflow_edit_call_args(int count) {
    return 'Aufruf-Argumente bearbeiten ($count)';
  }

  @override
  String get workflow_entry_point => 'Einstiegspunkt';

  @override
  String get workflow_entry_point_helper =>
      'Standardmäßig Workflow-Einstiegspunkt, wenn leer';

  @override
  String get workflow_entry_point_optional => 'Einstiegspunkt (optional)';

  @override
  String get workflow_hint_name => 'z. B. handle_form_submit';

  @override
  String get workflow_manual => 'Manuell';

  @override
  String get workflow_mode_bdfd => 'BDFD-Skript';

  @override
  String get workflow_mode_bdfd_note =>
      'Schreiben Sie Ihren gesamten Workflow als ein einziges BDFD-Skript. Das Skript wird in Echtzeit kompiliert und validiert.';

  @override
  String get workflow_mode_dart => 'Dart Direct';

  @override
  String get workflow_mode_dart_note =>
      'Schreiben Sie Ihren Workflow in Dart. Diagnosen werden während der Bearbeitung aktualisiert, um Fehler frühzeitig zu erkennen.';

  @override
  String get workflow_mode_desc =>
      'Wählen Sie zwischen einem visuellen Aktions-Builder oder einem vollständigen BDFD-Skript-Editor.';

  @override
  String get workflow_mode_title => 'Workflow-Modus';

  @override
  String get workflow_mode_visual => 'Visuell';

  @override
  String get workflow_mode_visual_note =>
      'Erstellen Sie Ihren Workflow visuell, indem Sie einzelne Aktionen mit dem Karten-Editor hinzufügen.';

  @override
  String get workflow_no_auto_defer => 'Kein Auto-Verzögern';

  @override
  String get workflow_no_workflow_note =>
      'Hinweis: Wenn kein Workflow ausgewählt ist, hat das Übermitteln dieses Modals keine Auswirkung.';

  @override
  String workflow_on_submit_info(String name, String entry, int args) {
    return 'Bei Übermittlung wird der Workflow \"$name\" ausgeführt (Einstieg: $entry, Arg.: $args).';
  }

  @override
  String get workflow_root_json_error => 'Wurzel muss ein JSON-Objekt sein';

  @override
  String workflow_saved_snackbar(String name, int count) {
    return 'Workflow \"$name\" gespeichert ($count Aktion(en)).';
  }

  @override
  String get workflow_set_call_args => 'Aufruf-Argumente setzen';

  @override
  String get workflow_visibility_ephemeral => 'Ephemeral';

  @override
  String get workflow_visibility_public => 'Öffentlich';

  @override
  String get workflows_add_arg => 'Argument hinzufügen';

  @override
  String get workflows_arg_default => 'Standardwert';

  @override
  String get workflows_arg_hint =>
      'Argumente werden zu Laufzeitvariablen als ((arg.name)) und ((workflow.arg.name)).';

  @override
  String get workflows_arg_name => 'Name';

  @override
  String get workflows_arg_required_short => 'Erf';

  @override
  String get workflows_arguments => 'Argumente';

  @override
  String get workflows_continue => 'Weiter';

  @override
  String get workflows_copy_done_base64 => 'Workflows als Base64 kopiert.';

  @override
  String get workflows_copy_done_json => 'Workflows als JSON kopiert.';

  @override
  String get workflows_copy_none => 'Keine Workflows zum Kopieren.';

  @override
  String get workflows_create => 'Workflow erstellen';

  @override
  String workflows_delete_confirm(String name) {
    return 'Sind Sie sicher, dass Sie \"$name\" löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get workflows_delete_title => 'Workflow löschen';

  @override
  String get workflows_docs_tooltip => 'Dokumentationszentrum öffnen';

  @override
  String get workflows_edit => 'Workflow bearbeiten';

  @override
  String get workflows_empty => 'Noch keine Workflows';

  @override
  String get workflows_entry_point => 'Standard-Einstiegspunkt';

  @override
  String get workflows_entry_point_hint =>
      'Wird verwendet, wenn der Aufrufer ihn nicht überschreibt';

  @override
  String get workflows_event_available_vars => 'Verfügbare Variablen';

  @override
  String get workflows_event_category => 'Ereigniskategorie';

  @override
  String get workflows_event_category_channels => 'Kanäle';

  @override
  String get workflows_event_category_invites => 'Einladungen';

  @override
  String get workflows_event_category_members => 'Mitglieder';

  @override
  String get workflows_event_category_messages => 'Nachrichten';

  @override
  String get workflows_event_channel_update => 'Kanal aktualisiert';

  @override
  String get workflows_event_channel_update_desc =>
      'Wird ausgelöst, wenn ein Kanal aktualisiert wird.';

  @override
  String get workflows_event_hint =>
      'Wählen Sie das Discord-Ereignis aus, das diesen Workflow auslösen soll.';

  @override
  String get workflows_event_invite_create => 'Einladung erstellt';

  @override
  String get workflows_event_invite_create_desc =>
      'Wird ausgelöst, wenn eine Einladung erstellt wird.';

  @override
  String get workflows_event_member_join => 'Mitglied tritt bei';

  @override
  String get workflows_event_member_join_desc =>
      'Wird ausgelöst, wenn ein Mitglied der Gilde beitritt.';

  @override
  String get workflows_event_member_remove => 'Mitglied entfernt';

  @override
  String get workflows_event_member_remove_desc =>
      'Wird ausgelöst, wenn ein Mitglied die Gilde verlässt oder entfernt wird.';

  @override
  String get workflows_event_message_create => 'Nachricht erstellt';

  @override
  String get workflows_event_message_create_desc =>
      'Wird ausgelöst, wenn eine neue Nachricht erstellt wird.';

  @override
  String get workflows_event_message_delete => 'Nachricht gelöscht';

  @override
  String get workflows_event_message_delete_desc =>
      'Wird ausgelöst, wenn eine Nachricht gelöscht wird.';

  @override
  String get workflows_event_message_update => 'Nachricht aktualisiert';

  @override
  String get workflows_event_message_update_desc =>
      'Wird ausgelöst, wenn eine vorhandene Nachricht bearbeitet wird.';

  @override
  String workflows_event_preview(String event) {
    return 'Lauscht auf: $event';
  }

  @override
  String get workflows_event_section => 'Ereignis-Workflows';

  @override
  String workflows_event_subtitle(int count, String event) {
    return '$count Aktion(en) • Lauscht auf: $event';
  }

  @override
  String get workflows_export_base64 => 'Als Base64 kopieren';

  @override
  String get workflows_export_base64_desc => 'Praktisch für kompaktes Teilen.';

  @override
  String get workflows_export_json => 'Als JSON kopieren';

  @override
  String get workflows_export_json_desc => 'Lesbar und leicht zu bearbeiten.';

  @override
  String get workflows_export_tooltip => 'Workflows kopieren';

  @override
  String get workflows_folder_hint => 'Optionaler Ordnername';

  @override
  String get workflows_folder_label => 'Ordner';

  @override
  String get workflows_general_section => 'Allgemeine Workflows';

  @override
  String get workflows_import_action => 'Importieren';

  @override
  String get workflows_import_desc =>
      'Fügen Sie eine JSON-Nutzlast oder Base64(JSON) ein, die von Bot Creator exportiert wurde.';

  @override
  String workflows_import_done(int count) {
    return '$count Workflow(s) importiert.';
  }

  @override
  String get workflows_import_empty => 'Keine Daten zum Importieren.';

  @override
  String get workflows_import_input_hint =>
      'Fügen Sie hier JSON oder Base64 ein...';

  @override
  String get workflows_import_invalid_format =>
      'Ungültiges Format. Verwenden Sie JSON oder Base64(JSON).';

  @override
  String get workflows_import_no_valid => 'Kein gültiger Workflow gefunden.';

  @override
  String get workflows_import_overwrite =>
      'Ersetzen, wenn der Name bereits existiert';

  @override
  String get workflows_import_title => 'Workflows importieren';

  @override
  String get workflows_import_tooltip => 'Workflows importieren';

  @override
  String get workflows_listen_for => 'Lauscht auf';

  @override
  String get workflows_move_to_folder => 'In Ordner verschieben';

  @override
  String get workflows_name => 'Workflow-Name';

  @override
  String get workflows_new_folder_hint => 'Neuer Ordnername';

  @override
  String get workflows_no_match =>
      'Keine Workflows entsprechen den aktuellen Filtern.';

  @override
  String get workflows_no_matches =>
      'Keine Workflows entsprechen den aktuellen Filtern.';

  @override
  String get workflows_remove_from_folder => 'Aus Ordner entfernen';

  @override
  String get workflows_search_hint => 'Workflows suchen...';

  @override
  String workflows_subtitle(int count, String entry, String args) {
    return '$count Aktion(en) • Einstieg: $entry • Arg.: $args';
  }

  @override
  String get workflows_tab => 'Workflows';

  @override
  String get workflows_tab_short => 'Flow';

  @override
  String get workflows_title => 'Workflows';

  @override
  String get workflows_type_badge_event => 'Ereignis';

  @override
  String get workflows_type_badge_general => 'Allgemein';

  @override
  String get workflows_type_event => 'Ereignis-Workflow';

  @override
  String get workflows_type_event_desc =>
      'Reagiert automatisch, wenn Discord ein Ereignis ausgibt.';

  @override
  String get workflows_type_general => 'Allgemeiner Workflow';

  @override
  String get workflows_type_general_desc =>
      'Wiederverwendbare Logik, die von Befehlen, Buttons, Modals oder anderen Workflows aufgerufen wird.';

  @override
  String get workflows_type_title => 'Workflow-Typ';

  @override
  String get settings_team_ownership => 'Teambesitz';

  @override
  String get settings_personal_ownership => 'Persönlicher Besitz';

  @override
  String get settings_team_pill => 'TEAM';

  @override
  String get settings_solo_pill => 'SOLO';

  @override
  String get settings_team_name_label => 'Teamname: ';

  @override
  String get settings_team_id_label => 'Team-ID: ';

  @override
  String get settings_team_owner_label => 'Teamleiter';

  @override
  String get settings_owner_fallback => 'Besitzer';

  @override
  String get settings_owner_badge => 'BESITZER';

  @override
  String settings_team_members_label(int count) {
    return 'Teammitglieder ($count)';
  }

  @override
  String get settings_personal_owner_label => 'Besitzer: ';

  @override
  String get settings_personal_owner_fallback => 'Persönlicher Benutzer';

  @override
  String get settings_personal_owner_id_label => 'Besitzer-ID: ';

  @override
  String get settings_raw_json_tile => 'Rohes JSON anzeigen (RAW JSON)';

  @override
  String get settings_member_badge => 'MITGLIED';

  @override
  String get cmd_deploy_local_save_title => 'Lokale Speicherung';

  @override
  String get cmd_deploy_local_save_subtitle => 'Befehl auf dem Gerät speichern';

  @override
  String get cmd_deploy_reload_bot_title => 'Bot neu laden';

  @override
  String get cmd_deploy_reload_bot_subtitle =>
      'Hot-Reload-Konfiguration anwenden';

  @override
  String get cmd_deploy_discord_sync_title => 'Discord-Synchronisation';

  @override
  String get cmd_deploy_discord_sync_subtitle =>
      'Befehl in der Discord-API veröffentlichen';

  @override
  String get cmd_deploy_cloud_sync_title => 'Cloud-Backup';

  @override
  String get cmd_deploy_cloud_sync_subtitle =>
      'Sichere Synchronisierung mit Ihrem Online-Speicher';

  @override
  String get cmd_deploy_hot_reload_title => 'Hot Reload';

  @override
  String get cmd_deploy_hot_reload_subtitle =>
      'Sofortige Aktualisierung Ihres Bot-Runners';

  @override
  String cmd_deploy_success_toast(String name) {
    return 'Befehl \"$name\" bereitgestellt und aktiv!';
  }

  @override
  String get cmd_deploy_success_title => 'Bereitstellung erfolgreich!';

  @override
  String get cmd_deploy_failed_title => 'Bereitstellung fehlgeschlagen';

  @override
  String get cmd_deploy_in_progress_title => 'Bereitstellung läuft...';

  @override
  String cmd_deploy_config_subtitle(String name) {
    return 'Konfiguration von /$name';
  }

  @override
  String get cmd_deploy_close_button => 'Schließen';

  @override
  String get cmd_deploy_retry_button => 'Wiederholen';

  @override
  String get variable_category_context => 'Kontext';

  @override
  String get variable_category_interaction => 'Interaktion';

  @override
  String get variable_category_bot => 'Bot';

  @override
  String get variable_category_guild => 'Server';

  @override
  String get variable_category_channel => 'Kanal';

  @override
  String get variable_category_member => 'Mitglied';

  @override
  String get variable_category_message => 'Nachricht';

  @override
  String get variable_category_author => 'Autor';

  @override
  String get variable_category_user => 'Benutzer';

  @override
  String get variable_category_temp => 'Temporär';

  @override
  String get variable_category_functions => 'Funktionen';

  @override
  String get variable_category_other => 'Andere';

  @override
  String get variable_autocomplete_title =>
      'Verfügbare Variablen — zum Einfügen tippen';

  @override
  String get variable_autocomplete_numeric_title =>
      'Dynamische numerische Vorschläge';

  @override
  String get bot_settings_tab_general => 'Allgemein';

  @override
  String get bot_settings_tab_presence => 'Präsenz & Status';

  @override
  String get bot_settings_tab_intents => 'Intents & Berechtigungen';

  @override
  String get bot_settings_tab_advanced => 'Erweitert & Wartung';

  @override
  String get bot_settings_avatar_selected => 'Ausgewähltes Bild:';

  @override
  String get bot_settings_avatar_none_selected =>
      'Kein neues Bild ausgewählt. Klicken Sie auf Durchsuchen, um eines auszuwählen.';

  @override
  String get bot_settings_avatar_important_note =>
      'Wichtig: Profiländerungen (Benutzername und Avatar) werden erst dann auf Discord angewendet, wenn Sie unten auf \'Profil und Status speichern\' klicken.';

  @override
  String get marketplace_title => 'Marktplatz';

  @override
  String get marketplace_search_hint => 'Vorlagen durchsuchen...';

  @override
  String get marketplace_empty =>
      'Noch keine Vorlagen.\nSei der Erste, der veröffentlicht!';

  @override
  String marketplace_no_results(Object query) {
    return 'Keine Vorlagen entsprechen \"$query\"';
  }

  @override
  String marketplace_count(Object count) {
    return '$count Vorlage(n)';
  }

  @override
  String get marketplace_retry => 'Wiederholen';

  @override
  String get marketplace_apply => 'Vorlage anwenden';

  @override
  String get marketplace_applying => 'Wird angewendet...';

  @override
  String get marketplace_apply_success => 'Vorlage erfolgreich angewendet!';

  @override
  String marketplace_apply_success_skipped(
    Object addedCount,
    Object skippedCount,
  ) {
    return '$addedCount Befehl(e) hinzugefügt, $skippedCount übersprungen (Duplikate).';
  }

  @override
  String marketplace_apply_error(Object error) {
    return 'Anwendung fehlgeschlagen: $error';
  }

  @override
  String get marketplace_login_required => 'Discord-Verbindung erforderlich';

  @override
  String get marketplace_login_hint =>
      'Du musst dein Discord-Konto verbinden, um auf den Marktplatz zuzugreifen.';

  @override
  String get marketplace_connect_discord => 'Mit Discord verbinden';

  @override
  String get marketplace_login_title => 'Mit Manager verbinden';

  @override
  String get marketplace_login_instructions =>
      'Bitte authentifiziere dich über Discord, um den Marktplatz weiter zu nutzen.';

  @override
  String get marketplace_rate_title => 'Diese Vorlage bewerten';

  @override
  String get marketplace_rate_success => 'Bewertung gesendet!';

  @override
  String get marketplace_edit => 'Bearbeiten';

  @override
  String get marketplace_delete => 'Löschen';

  @override
  String get marketplace_edit_hint =>
      'Zum Bearbeiten erneut aus der Befehlsliste deines Bots mit demselben Namen veröffentlichen.';

  @override
  String get marketplace_delete_confirm_title => 'Vorlage löschen';

  @override
  String marketplace_delete_confirm(Object name) {
    return 'Bist du sicher, dass du \"$name\" löschen möchtest? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get marketplace_delete_success => 'Vorlage gelöscht.';

  @override
  String get marketplace_my_templates => 'Meine Vorlagen';

  @override
  String get marketplace_login_success => 'Discord erfolgreich verbunden!';

  @override
  String get marketplace_config_required => 'Konfiguration erforderlich';

  @override
  String get marketplace_config_hint =>
      'Fülle die erforderlichen Werte aus, bevor du diese Vorlage anwendest.';

  @override
  String marketplace_variable_required(Object name) {
    return '$name ist erforderlich';
  }

  @override
  String get marketplace_about => 'Über';

  @override
  String marketplace_commands_label(Object count) {
    return 'Befehle ($count)';
  }

  @override
  String marketplace_workflows_label(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get marketplace_variables_label => 'Vorkonfigurierte Variablen';

  @override
  String marketplace_more(Object count) {
    return '+$count weitere';
  }

  @override
  String get marketplace_publish_title => 'Vorlage veröffentlichen';

  @override
  String get marketplace_publish_select => 'Inhalt auswählen';

  @override
  String get marketplace_publish_select_hint =>
      'Wähle Befehle, Workflows oder beides aus.';

  @override
  String marketplace_publish_commands(Object count) {
    return 'Befehle ($count)';
  }

  @override
  String marketplace_publish_workflows(Object count) {
    return 'Workflows ($count)';
  }

  @override
  String get marketplace_publish_variables => 'Globale Variablen';

  @override
  String get marketplace_publish_variables_hint =>
      'Füge Variablen hinzu und markiere, welche der Benutzer ausfüllen muss.';

  @override
  String get marketplace_publish_metadata => 'Vorlagendetails';

  @override
  String get marketplace_publish_metadata_hint =>
      'Beschreibe deine Vorlage, damit andere sie finden und nutzen können.';

  @override
  String get marketplace_publish_summary => 'Zusammenfassung';

  @override
  String get marketplace_publish_select_all => 'Alle auswählen';

  @override
  String get marketplace_publish_deselect_all => 'Alle abwählen';

  @override
  String get marketplace_publish_user_must_define =>
      'Benutzer muss diesen Wert festlegen';

  @override
  String get marketplace_publish_user_must_define_hint =>
      'Der Benutzer wird aufgefordert, diesen Wert vor der Anwendung einzugeben';

  @override
  String get marketplace_publish_add_variable => 'Variable hinzufügen';

  @override
  String get marketplace_publish_add_variable_title => 'Variable hinzufügen';

  @override
  String get marketplace_publish_name_label => 'Vorlagenname';

  @override
  String get marketplace_publish_name_hint => 'z.B. KI-Moderations-Bot';

  @override
  String get marketplace_publish_desc_label => 'Kurzbeschreibung';

  @override
  String get marketplace_publish_desc_hint =>
      'Eine einzeilige Zusammenfassung, die im Marktplatz angezeigt wird';

  @override
  String get marketplace_publish_desc_long_label =>
      'Vollständige Dokumentation (optional)';

  @override
  String get marketplace_publish_desc_long_hint =>
      'Detaillierte Nutzungsanweisungen, Markdown unterstützt...';

  @override
  String get marketplace_publish_category_label => 'Kategorie';

  @override
  String get marketplace_publish_category_hint => 'z.B. ai, moderation, fun';

  @override
  String get marketplace_publish_version_label => 'Version';

  @override
  String get marketplace_publish_tags_label => 'Tags (durch Kommas getrennt)';

  @override
  String get marketplace_publish_tags_hint =>
      'z.B. openai, chatbot, moderation';

  @override
  String get marketplace_publish_variable_name_label => 'Variablenname';

  @override
  String get marketplace_publish_variable_name_hint => 'z.B. TOKEN_OPENAI';

  @override
  String get marketplace_publish_variable_desc_label => 'Beschreibung';

  @override
  String get marketplace_publish_variable_desc_hint =>
      'Wofür diese Variable ist';

  @override
  String get marketplace_publish_success =>
      'Vorlage erfolgreich veröffentlicht!';

  @override
  String marketplace_publish_error(Object error) {
    return 'Veröffentlichung fehlgeschlagen: $error';
  }

  @override
  String get marketplace_publish_button => 'Veröffentlichen';

  @override
  String get marketplace_publishing => 'Wird veröffentlicht...';

  @override
  String get marketplace_publish_next => 'Weiter';

  @override
  String get marketplace_publish_back => 'Zurück';

  @override
  String get marketplace_publish_required_fields =>
      'Bitte füllen Sie alle Pflichtfelder aus (Name, Kurzbeschreibung, Version), bevor Sie veröffentlichen.';

  @override
  String get marketplace_publish_no_content =>
      'Keine Befehle oder Workflows zum Veröffentlichen.\nErstelle zuerst welche!';

  @override
  String get marketplace_no_variables => 'Keine globalen Variablen definiert.';

  @override
  String get marketplace_connect_manager =>
      'Verbinde dich mit dem Manager, um auf den Marktplatz zuzugreifen.';

  @override
  String get marketplace_connect_publish =>
      'Verbinde dich mit dem Manager, um eine Vorlage zu veröffentlichen.';

  @override
  String get marketplace_api_unavailable => 'API-Client nicht verfügbar';

  @override
  String marketplace_load_error(Object error) {
    return 'Laden fehlgeschlagen: $error';
  }

  @override
  String get marketplace_cancel => 'Abbrechen';

  @override
  String get marketplace_add => 'Hinzufügen';

  @override
  String marketplace_by_author(Object author, Object version) {
    return 'von $author · v$version';
  }

  @override
  String get marketplace_conflict_title => 'Command Conflicts';

  @override
  String get marketplace_conflict_subtitle =>
      'Some template commands already exist. Choose which version to keep:';

  @override
  String get marketplace_conflict_keep_local => 'Keep Local';

  @override
  String get marketplace_conflict_use_template => 'Use Template';

  @override
  String marketplace_conflict_local_info(Object count) {
    return 'Local ($count actions)';
  }

  @override
  String marketplace_conflict_template_info(Object count) {
    return 'Template ($count actions)';
  }

  @override
  String marketplace_conflict_apply_choice(Object count) {
    return 'Apply ($count template)';
  }

  @override
  String marketplace_command_preview_actions(Object count) {
    return '$count actions';
  }

  @override
  String get marketplace_command_preview_no_actions => 'No actions';

  @override
  String get marketplace_command_preview_type_slash => 'Slash command';

  @override
  String get marketplace_command_preview_type_user => 'User context menu';

  @override
  String get marketplace_command_preview_type_message => 'Message context menu';

  @override
  String marketplace_command_preview_options(Object count) {
    return '$count options';
  }

  @override
  String get guilds_tab => 'Server';

  @override
  String get guilds_tab_short => 'Server';
}
