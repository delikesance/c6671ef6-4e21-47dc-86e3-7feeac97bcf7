// ignore_for_file: avoid_print
import 'dart:io';

/// Migrates hardcoded UI strings to context.tr.key calls.
/// Run: dart run tools/migrate_hardcoded.dart
void main() {
  final base = 'lib';

  // Process each file
  for (final entry in _fileReplacements.entries) {
    final path = '$base/${entry.key}';
    final file = File(path);
    if (!file.existsSync()) {
      print('SKIP (not found): $path');
      continue;
    }
    var content = file.readAsStringSync();
    final original = content;
    var count = 0;

    // Ensure i18n import exists
    if (!content.contains("import") ||
        (!content.contains("i18n.dart") &&
            !content.contains('app_localizations.dart'))) {
      // Add import after last import line
      final importRegex = RegExp(r"^import\s+'[^']+';$", multiLine: true);
      final matches = importRegex.allMatches(content).toList();
      if (matches.isNotEmpty) {
        final lastImport = matches.last;
        final insertPos = lastImport.end;
        // Determine the right relative path
        final depth = entry.key.split('/').length - 1; // relative to lib/
        String importPath;
        if (depth == 1) {
          importPath = "import 'utils/i18n.dart';";
        } else if (depth == 2) {
          importPath = "import '../utils/i18n.dart';";
        } else if (depth == 3) {
          importPath = "import '../../utils/i18n.dart';";
        } else {
          importPath = "import '../../../utils/i18n.dart';";
        }
        if (!content.contains("i18n.dart")) {
          content =
              '${content.substring(0, insertPos)}\n$importPath${content.substring(insertPos)}';
          count++;
        }
      }
    }

    // Apply replacements
    for (final r in entry.value) {
      final old = r.old;
      final replacement = r.replacement;
      if (content.contains(old)) {
        content = content.replaceAll(old, replacement);
        count++;
      } else {
        print(
          '  WARN: not found in $path: ${old.substring(0, old.length.clamp(0, 60))}...',
        );
      }
    }

    if (content != original) {
      file.writeAsStringSync(content);
      print('OK ($count replacements): $path');
    } else {
      print('NO CHANGE: $path');
    }
  }

  print('\nDone!');
}

class R {
  final String old;
  final String replacement;
  const R(this.old, this.replacement);
}

final _fileReplacements = <String, List<R>>{
  // ============================================================
  // option_widget.dart
  // ============================================================
  'widgets/option_widget.dart': [
    R(
      "title: const Text('Delete option')",
      'title: Text(context.tr.option_delete_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("const Text('Type')", 'Text(context.tr.common_type)'),
    R("const Text('Required')", 'Text(context.tr.common_required)'),
    R(
      "title: const Text('Dynamic Autocomplete')",
      'title: Text(context.tr.autocomplete_dynamic)',
    ),
    R("label: Text('Workflow')", 'label: Text(context.tr.common_workflow)'),
    R(
      "label: Text('Static Options')",
      'label: Text(context.tr.common_static_options)',
    ),
    R(
      "tooltip: 'Refresh workflows'",
      'tooltip: context.tr.common_refresh_workflows',
    ),
    R("label: 'Value'", 'label: context.tr.common_value'),
    R("tooltip: 'Remove'", 'tooltip: context.tr.common_remove'),
    R(
      "label: const Text('Add Argument')",
      'label: Text(context.tr.common_add_argument)',
    ),
    R(
      "label: const Text('Add Option')",
      'label: Text(context.tr.common_add_option)',
    ),
    R(
      "title: const Text('Add Localizations')",
      'title: Text(context.tr.option_add_localizations)',
    ),
    R("Text('Add Choice')", 'Text(context.tr.option_add_choice)'),
    R("Text('Add Option')", 'Text(context.tr.common_add_option)'),
    // Autocomplete section
    R("'Loading workflows…'", 'context.tr.autocomplete_loading'),
    R("'No saved workflows found'", 'context.tr.autocomplete_no_workflows'),
    R("'Or type workflow name'", 'context.tr.autocomplete_type_name'),
    R("'Entry Point'", 'context.tr.workflow_entry_point'),
    R("'Workflow Arguments'", 'context.tr.workflow_arguments_section'),
    R("'Use variables/templates if needed'", 'context.tr.hint_use_variables'),
    R("'Autocomplete Workflow'", 'context.tr.autocomplete_workflow_label'),
    R("'Select a saved workflow'", 'context.tr.autocomplete_select_workflow'),
    // Delete dialogs
    R(
      "content: const Text('This option will be removed. Continue?')",
      'content: Text(context.tr.option_delete_confirm)',
    ),
    R(
      "'Please enter a description for the option'",
      'context.tr.option_desc_required',
    ),
    // Subtitle
    R(
      "'Resolve choices from a workflow instead of static values.'",
      'context.tr.autocomplete_dynamic_desc',
    ),
    // Static choices
    R(
      "'Suggestions are filtered by what the user types.'",
      'context.tr.autocomplete_filter_hint',
    ),
    // Delete argument
    R(
      "title: const Text('Delete argument')",
      "title: Text(context.tr.option_delete_argument_title)",
    ),
    R(
      "content: const Text('This argument will be removed. Continue?')",
      "content: Text(context.tr.option_delete_argument_confirm)",
    ),
    R("child: const Text('Delete')", "child: Text(context.tr.common_delete)"),
    // Delete static option
    R(
      "content: const Text('This choice will be removed. Continue?')",
      'content: Text(context.tr.option_delete_choice_confirm)',
    ),
    // Min/Max
    R("'Min Value'", 'context.tr.option_min_value'),
    R("'Max Value'", 'context.tr.option_max_value'),
    // Select Language
    R("'Select Language'", 'context.tr.option_select_language'),
    // Delete localization
    R(
      "title: const Text('Delete localization')",
      'title: Text(context.tr.option_delete_localization_title)',
    ),
    R(
      "content: const Text('This localization entry will be removed. Continue?')",
      'content: Text(context.tr.option_delete_localization_confirm)',
    ),
    R("'Localized Name'", 'context.tr.option_localized_name'),
    R("'Localized Description'", 'context.tr.option_localized_description'),
    // Choice
    R("'Delete choice'", 'context.tr.option_choice_delete_title'),
    R(
      "'This choice will be removed. Continue?'",
      'context.tr.option_choice_delete_confirm',
    ),
    R("'Choice Name'", 'context.tr.option_choice_name'),
    R("'Choice Value'", 'context.tr.option_choice_value'),
    R("'Add Choice'", 'context.tr.option_add_choice'),
    // Subcommands
    R("'SubCommands'", "context.tr.option_subcommands"),
    R("'SubCommand Options'", "context.tr.option_subcommand_options"),
  ],

  // ============================================================
  // component_node_editor.dart
  // ============================================================
  'widgets/component_v2_builder/component_node_editor.dart': [
    R(
      "title: const Text('Remove component')",
      'title: Text(context.tr.component_remove_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("child: const Text('Remove')", 'child: Text(context.tr.common_remove)'),
    R("tooltip: 'Move up'", 'tooltip: context.tr.common_move_up'),
    R("tooltip: 'Move down'", 'tooltip: context.tr.common_move_down'),
    R("tooltip: 'Remove'", 'tooltip: context.tr.common_remove'),
    R(
      "content: const Text('This component will be removed from the layout. Continue?')",
      'content: Text(context.tr.component_remove_confirm)',
    ),
    R(
      "return const Text('Editor not implemented yet')",
      'return Text(context.tr.component_not_implemented)',
    ),
    R("label: 'Label'", 'label: context.tr.component_label'),
    R("label: 'Style'", 'label: context.tr.component_style'),
    R("label: 'URL'", 'label: context.tr.component_url'),
    R("label: 'Custom ID *'", 'label: context.tr.component_custom_id_required'),
    R("'Required'", 'context.tr.component_validation_required'),
    R(
      "label: 'Call Workflow (optional)'",
      'label: context.tr.component_workflow_optional',
    ),
    R(
      "'Saved workflow name to run on click'",
      'context.tr.component_workflow_click_hint',
    ),
    R(
      "'Saved workflow name to run on selection'",
      'context.tr.component_workflow_select_hint',
    ),
    R("label: 'Custom ID'", 'label: context.tr.component_custom_id'),
    R("label: 'Placeholder'", 'label: context.tr.component_placeholder'),
    R(
      "label: const Text('Add Option'",
      'label: Text(context.tr.common_add_option',
    ),
    R(
      "const Text('Visible Divider Line')",
      'Text(context.tr.component_visible_divider)',
    ),
    R(
      "child: Text('Small Spacing')",
      'child: Text(context.tr.component_spacing_small)',
    ),
    R(
      "child: Text('Large Spacing')",
      'child: Text(context.tr.component_spacing_large)',
    ),
    R(
      "label: const Text('Add Text Display'",
      'label: Text(context.tr.component_add_text_display',
    ),
    R(
      "title: const Text('Pick Accent Color')",
      'title: Text(context.tr.component_pick_accent_color)',
    ),
    R("child: const Text('OK')", 'child: Text(context.tr.common_ok)'),
    R(
      "label: 'Accent Color (Hex, e.g. FF0000)'",
      'label: context.tr.component_accent_color',
    ),
    R("tooltip: 'Choose Color'", 'tooltip: context.tr.component_choose_color'),
    R(
      "label: 'Markdown Content'",
      'label: context.tr.component_markdown_content',
    ),
    R(
      "const Text('Checked by default')",
      'Text(context.tr.component_checked_by_default)',
    ),
    R(
      "label: const Text('Add Radio Option'",
      'label: Text(context.tr.component_add_radio_option',
    ),
    R(
      "label: const Text('Add Media Item'",
      'label: Text(context.tr.component_add_media_item',
    ),
    R(
      "tooltip: 'Add Child Component'",
      'tooltip: context.tr.component_add_child',
    ),
    R(
      "title: const Text('Workflow Call Arguments (JSON)')",
      'title: Text(context.tr.component_workflow_args_title)',
    ),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
    R(
      "label: const Text('Manage Workflows')",
      'label: Text(context.tr.common_manage_workflows)',
    ),
    R(
      "tooltip: 'Refresh workflows'",
      'tooltip: context.tr.common_refresh_workflows',
    ),
    R("label: 'Label Title'", 'label: context.tr.component_label_title'),
    R("label: 'Description'", 'label: context.tr.common_description'),
    // Options section
    R("'Options'", 'context.tr.component_options'),
    // Text Displays section
    R(
      "const Text('Text Displays')",
      'Text(context.tr.component_section_text_displays)',
    ),
    R(
      "const Text('Accessory Node (Optional)')",
      'Text(context.tr.component_section_accessory)',
    ),
    // Loading/No workflows
    R("'Loading workflows…'", 'context.tr.autocomplete_loading'),
    R("'No saved workflows found'", 'context.tr.autocomplete_no_workflows'),
    R("'Or type workflow name'", 'context.tr.autocomplete_type_name'),
    R("'Entry Point'", 'context.tr.workflow_entry_point'),
    R("'Workflow Arguments'", 'context.tr.workflow_arguments_section'),
    R("'Key'", 'context.tr.common_key'),
    R("'Value'", 'context.tr.common_value'),
    R("'Use variables/templates if needed'", 'context.tr.hint_use_variables'),
    R("'Autocomplete Workflow'", 'context.tr.autocomplete_workflow_label'),
    R("'Select a saved workflow'", 'context.tr.autocomplete_select_workflow'),
    R("label: 'Add Argument'", 'label: context.tr.common_add_argument'),
    // Autocomplete
    R(
      "title: const Text('Dynamic Autocomplete')",
      'title: Text(context.tr.autocomplete_dynamic)',
    ),
    R(
      "'Resolve choices from a workflow instead of static values.'",
      'context.tr.autocomplete_dynamic_desc',
    ),
  ],

  // ============================================================
  // modal_builder.dart
  // ============================================================
  'widgets/component_v2_builder/modal_builder.dart': [
    R(
      "title: const Text('Remove modal field')",
      'title: Text(context.tr.modal_remove_field_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("child: const Text('Remove')", 'child: Text(context.tr.common_remove)'),
    R(
      "content: const Text('This field will be removed from the modal. Continue?')",
      'content: Text(context.tr.modal_remove_field_confirm)',
    ),
    R(
      "title: const Text('Workflow Call Arguments (JSON)')",
      'title: Text(context.tr.component_workflow_args_title)',
    ),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
    R(
      "label: const Text('Manage Workflows')",
      'label: Text(context.tr.common_manage_workflows)',
    ),
    R(
      "label: const Text('Add Text Input')",
      'label: Text(context.tr.modal_add_text_input)',
    ),
    R(
      "const Text('Style:', style: TextStyle(fontSize: 12))",
      "Text(context.tr.modal_style, style: const TextStyle(fontSize: 12))",
    ),
    R(
      "const Text('Required', style: TextStyle(fontSize: 12))",
      "Text(context.tr.common_required, style: const TextStyle(fontSize: 12))",
    ),
    R("label: 'Modal Title'", 'label: context.tr.modal_title_label'),
    R("label: 'Custom ID'", 'label: context.tr.modal_custom_id_label'),
    R("'Used to identify this modal'", 'context.tr.modal_custom_id_hint'),
    R(
      "label: 'Workflow to run on submit (optional)'",
      'label: context.tr.modal_workflow_submit',
    ),
    R(
      "tooltip: 'Refresh workflows'",
      'tooltip: context.tr.common_refresh_workflows',
    ),
    R("label: 'Default value'", 'label: context.tr.modal_default_value'),
  ],

  // ============================================================
  // basic_info_card.dart
  // ============================================================
  'widgets/command_create_cards/basic_info_card.dart': [
    R(
      "label: const Text('Use Awaited Callback Preset')",
      'label: Text(context.tr.command_awaited_preset_button)',
    ),
    R(
      "child: const Text('Edit Raw Name')",
      'child: Text(context.tr.command_edit_raw_name)',
    ),
    R(
      "label: Text('Success')",
      'label: Text(context.tr.command_awaited_success)',
    ),
    R("label: Text('Error')", 'label: Text(context.tr.command_awaited_error)'),
    R(
      "child: Text('Slash Command')",
      'child: Text(context.tr.command_type_slash)',
    ),
    R(
      "child: Text('Legacy Command')",
      'child: Text(context.tr.command_type_legacy)',
    ),
    R(
      "child: Text('User Command')",
      'child: Text(context.tr.command_type_user)',
    ),
    R(
      "child: Text('Message Command')",
      'child: Text(context.tr.command_type_message)',
    ),
    R(
      "const Text('Guild Install')",
      'Text(context.tr.command_integration_guild)',
    ),
    R(
      "const Text('User Install')",
      'Text(context.tr.command_integration_user)',
    ),
    R("const Text('Guild')", 'Text(context.tr.command_context_guild)'),
    R("const Text('Bot DM')", 'Text(context.tr.command_context_bot_dm)'),
    R(
      "const Text('Group DM / Other')",
      'Text(context.tr.command_context_group_dm)',
    ),
    R(
      "title: const Text('Select permissions')",
      'title: Text(context.tr.command_permissions_title)',
    ),
    R("label: const Text('Clear')", 'label: Text(context.tr.common_clear)'),
    // Card titles & descriptions
    R("'Legacy preset'", "context.tr.command_legacy_preset_title"),
    R(
      "'Generate an internal awaited callback trigger and switch this command to the required local legacy setup.'",
      "context.tr.command_legacy_preset_desc",
    ),
    R("'Awaited callback preset'", "context.tr.command_awaited_preset_active"),
    R(
      "'The command name is generated for you and saved as an internal legacy callback.'",
      "context.tr.command_awaited_preset_desc",
    ),
    R("'Awaited callback name'", "context.tr.command_awaited_name_label"),
    R("'Example: say'", "context.tr.command_awaited_name_hint"),
    R("'Filter (optional)'", "context.tr.command_awaited_filter_label"),
    R(
      "'Example: <numeric> or <yes/no/cancel>'",
      "context.tr.command_awaited_filter_hint",
    ),
    R("'Command Info'", "context.tr.command_info_title"),
    R("'Basic metadata and availability'", "context.tr.command_info_desc"),
    R("'Name'", "context.tr.command_name_label"),
    R(
      "'Generated by the awaited callback preset.'",
      "context.tr.command_name_generated",
    ),
    R("'Command Type'", "context.tr.command_type_label"),
  ],

  // ============================================================
  // actions_card.dart
  // ============================================================
  'widgets/command_create_cards/actions_card.dart': [
    R(
      "title: const Text('Save as Workflow')",
      'title: Text(context.tr.actions_save_workflow_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
    R(
      "label: const Text('Save as Workflow')",
      'label: Text(context.tr.actions_save_workflow_title)',
    ),
    R(
      "label: const Text('Global Variables')",
      'label: Text(context.tr.actions_global_variables)',
    ),
    R(
      "label: const Text('Workflows')",
      'label: Text(context.tr.actions_workflows)',
    ),
    R("'Actions'", "context.tr.actions_title"),
    R(
      "'Build runtime actions for this command'",
      "context.tr.actions_description",
    ),
    R("'Workflow name'", "context.tr.actions_workflow_name_label"),
  ],

  // ============================================================
  // reply_card.dart
  // ============================================================
  'widgets/command_create_cards/reply_card.dart': [
    R(
      "label: const Text('Configure Response Workflow')",
      'label: Text(context.tr.reply_configure_workflow)',
    ),
    R(
      "title: const Text('Buttons & Select Menus (optional)')",
      'title: Text(context.tr.reply_buttons_optional)',
    ),
    R("label: 'Standard Message'", 'label: context.tr.reply_mode_standard'),
    R("label: 'Layout Mode'", 'label: context.tr.reply_mode_layout'),
    R("label: 'Modal Form'", 'label: context.tr.reply_mode_modal'),
  ],

  // ============================================================
  // normal_component_editor.dart
  // ============================================================
  'widgets/component_v2_builder/normal_component_editor.dart': [
    R(
      "title: const Text('Remove action row')",
      'title: Text(context.tr.component_remove_row_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("child: const Text('Remove')", 'child: Text(context.tr.common_remove)'),
    R("tooltip: 'Add Component'", 'tooltip: context.tr.component_add_child'),
  ],

  // ============================================================
  // component_v2_editor.dart
  // ============================================================
  'widgets/component_v2_builder/component_v2_editor.dart': [
    R(
      "tooltip: 'Add Root Component'",
      'tooltip: context.tr.component_add_root',
    ),
  ],

  // ============================================================
  // action_card.dart
  // ============================================================
  'routes/app/builder/action_card.dart': [
    R(
      "tooltip: 'Action options'",
      'tooltip: context.tr.action_options_tooltip',
    ),
    R("Text('Move up')", 'Text(context.tr.common_move_up)'),
    R("Text('Move down')", 'Text(context.tr.common_move_down)'),
    R("tooltip: 'Move up'", 'tooltip: context.tr.common_move_up'),
    R("tooltip: 'Move down'", 'tooltip: context.tr.common_move_down'),
    R("tooltip: 'Remove action'", 'tooltip: context.tr.action_remove_menu'),
    R("title: const Text('Enabled')", 'title: Text(context.tr.common_enabled)'),
    R("child: Text('Stop')", 'child: Text(context.tr.action_error_stop)'),
    R(
      "child: Text('Continue')",
      'child: Text(context.tr.action_error_continue)',
    ),
    R(
      "title: const Text('Advanced settings')",
      'title: Text(context.tr.action_advanced_settings)',
    ),
    R(
      "title: const Text('Remove action')",
      'title: Text(context.tr.action_remove_title)',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R("child: const Text('Remove')", 'child: Text(context.tr.common_remove)'),
    R(
      "content: const Text('This action will be removed from the workflow. Continue?')",
      'content: Text(context.tr.action_remove_confirm)',
    ),
    R(
      "title: const Text('Store results in global variables')",
      'title: Text(context.tr.action_store_results)',
    ),
    R(
      "label: const Text('Send Test Request & Auto-Detect Routes')",
      'label: Text(context.tr.action_http_test_button)',
    ),
    R("label: const Text('Literal')", 'label: Text(context.tr.action_literal)'),
    R("label: const Text('Dynamic')", 'label: Text(context.tr.action_dynamic)'),
    R(
      "label: const Text('Add ELSE IF')",
      'label: Text(context.tr.action_add_else_if)',
    ),
    R("tooltip: 'Remove ELSE IF'", 'tooltip: context.tr.action_remove_else_if'),
    R(
      "label: 'Condition Variable'",
      'label: context.tr.action_condition_variable',
    ),
    R("label: 'Condition Value'", 'label: context.tr.action_condition_value'),
    R("label: 'Expression'", 'label: context.tr.action_expression'),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
    R("child: const Text('OK')", 'child: Text(context.tr.common_ok)'),
    R(
      "label: const Text('Add argument')",
      'label: Text(context.tr.common_add_argument)',
    ),
    R(
      "label: const Text('Add header')",
      'label: Text(context.tr.action_add_header)',
    ),
    R(
      "child: const Text('Clear all')",
      'child: Text(context.tr.action_clear_all)',
    ),
    R("child: const Text('Import')", 'child: Text(context.tr.common_import)'),
    R("tooltip: 'Format JSON'", 'tooltip: context.tr.action_format_json'),
    R("tooltip: 'Refresh keys'", 'tooltip: context.tr.action_refresh_keys'),
    R(
      "tooltip: 'Refresh workflows'",
      'tooltip: context.tr.common_refresh_workflows',
    ),
    R(
      "label: const Text('Manage Variable Keys')",
      'label: Text(context.tr.action_manage_variable_keys)',
    ),
    R(
      "label: const Text('Manage Workflows')",
      'label: Text(context.tr.common_manage_workflows)',
    ),
    // Action Key
    R("'Action Key'", "context.tr.action_key_field"),
    R("'On Error'", "context.tr.action_on_error"),
    R(
      "'Tip: use arrows to change action order.'",
      "context.tr.action_order_tip",
    ),
  ],

  // ============================================================
  // builder.response.dart
  // ============================================================
  'routes/app/builder.response.dart': [
    R(
      "title: const Text('Missing Required Field')",
      'title: Text(context.tr.actions_missing_field_title)',
    ),
    R("child: const Text('OK')", 'child: Text(context.tr.common_ok)'),
    R("child: const Text('Close')", 'child: Text(context.tr.common_close)'),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R(
      "title: const Text('Add New Action')",
      'title: Text(context.tr.actions_add_new_title)',
    ),
    R(
      "const Center(child: Text('No actions match your search.'))",
      'Center(child: Text(context.tr.actions_no_matches))',
    ),
    R(
      "label: const Text('Add Action')",
      'label: Text(context.tr.actions_add_label)',
    ),
    R(
      "title: const Text('Actions Builder')",
      'title: Text(context.tr.actions_builder_title)',
    ),
    R("tooltip: 'Save Actions'", 'tooltip: context.tr.actions_save_tooltip'),
    R("'Search actions...'", "context.tr.actions_search_hint"),
  ],

  // ============================================================
  // command.create.wizard.dart
  // ============================================================
  'routes/app/command.create.wizard.dart': [
    R(
      "content: Text('Quick start applied to the command draft.')",
      'content: Text(context.tr.wizard_quick_start_applied)',
    ),
    R("label: const Text('Back')", 'label: Text(context.tr.common_back)'),
    R("label: const Text('Next')", 'label: Text(context.tr.common_next)'),
    R(
      "title: const Text('Advanced trigger settings')",
      'title: Text(context.tr.wizard_advanced_trigger)',
    ),
    R(
      "label: const Text('Edit reply details')",
      'label: Text(context.tr.wizard_edit_reply)',
    ),
    R(
      "title: const Text('Quick starts')",
      'title: Text(context.tr.wizard_quick_starts)',
    ),
    R(
      "label: const Text('Apply quick start to draft')",
      'label: Text(context.tr.wizard_apply_quick_start)',
    ),
    R(
      "title: const Text('Code / Advanced')",
      'title: Text(context.tr.wizard_code_advanced)',
    ),
  ],

  // ============================================================
  // command.create.serialization.dart
  // ============================================================
  'routes/app/command.create.serialization.dart': [
    R(
      "title: const Text('Export command as JSON')",
      'title: Text(context.tr.serialization_export_json_title)',
    ),
    R(
      "subtitle: const Text('Copy readable JSON to clipboard')",
      'subtitle: Text(context.tr.serialization_export_json_subtitle)',
    ),
    R(
      "title: const Text('Export command as Base64')",
      'title: Text(context.tr.serialization_export_base64_title)',
    ),
    R(
      "title: const Text('Import command')",
      'title: Text(context.tr.serialization_import_title)',
    ),
    R(
      "const Text('Paste a command payload (JSON or Base64).')",
      'Text(context.tr.serialization_import_desc)',
    ),
    R("child: const Text('Import')", 'child: Text(context.tr.common_import)'),
    R(
      "const SnackBar(content: Text('Invalid command payload format.'))",
      'SnackBar(content: Text(context.tr.serialization_invalid_format))',
    ),
    R(
      "const SnackBar(content: Text('Invalid command payload structure.'))",
      'SnackBar(content: Text(context.tr.serialization_invalid_structure))',
    ),
    R(
      "const SnackBar(content: Text('Command imported into editor.'))",
      'SnackBar(content: Text(context.tr.serialization_imported))',
    ),
    R("child: const Text('Cancel')", 'child: Text(context.tr.common_cancel)'),
    R(
      "tooltip: 'Import command payload'",
      'tooltip: context.tr.serialization_import_title',
    ),
    R(
      "tooltip: 'Export command payload'",
      'tooltip: context.tr.serialization_export_json_title',
    ),
  ],

  // ============================================================
  // command.create.edit_shell.dart
  // ============================================================
  'routes/app/command.create.edit_shell.dart': [
    R(
      "saveLabel: 'Save changes'",
      'saveLabel: context.tr.edit_shell_save_changes',
    ),
    R("label: 'Local-only'", 'label: context.tr.edit_shell_local_only'),
    R("label: 'Local draft'", 'label: context.tr.edit_shell_local_draft'),
    R("label: 'Unsaved changes'", 'label: context.tr.edit_shell_unsaved'),
  ],

  // ============================================================
  // command.reply_editor.dart
  // ============================================================
  'routes/app/command.reply_editor.dart': [
    R(
      "title: const Text('Reply Details')",
      'title: Text(context.tr.reply_editor_title)',
    ),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
  ],

  // ============================================================
  // command.create.dart (remaining hardcoded strings)
  // ============================================================
  'routes/app/command.create.dart': [
    R(
      "title: const Text('Enable legacy mode on this command')",
      'title: Text(context.tr.command_legacy_mode_title)',
    ),
    R(
      "child: Text('message.reply')",
      'child: Text(context.tr.command_response_mode_reply)',
    ),
    R(
      "child: Text('message.channel.send')",
      'child: Text(context.tr.command_response_mode_channel)',
    ),
    R(
      "title: const Text('Unsaved changes')",
      'title: Text(context.tr.command_unsaved_title)',
    ),
    R(
      "content: const Text('You have unsaved changes. Discard them?')",
      'content: Text(context.tr.command_unsaved_confirm)',
    ),
    R(
      "child: const Text('Keep editing')",
      'child: Text(context.tr.command_unsaved_keep)',
    ),
    R("title: const Text('Error')", 'title: Text(context.tr.error)'),
    R(
      "content: const Text('Missing bot id for local command save.')",
      'content: Text(context.tr.command_error_missing_bot_id)',
    ),
    R("child: const Text('OK')", 'child: Text(context.tr.common_ok)'),
    R(
      "tooltip: 'Import command payload'",
      "tooltip: context.tr.serialization_import_title",
    ),
    R(
      "tooltip: 'Export command payload'",
      "tooltip: context.tr.serialization_export_json_title",
    ),
  ],

  // ============================================================
  // command.response_workflow.dart (remaining strings)
  // ============================================================
  'routes/app/command.response_workflow.dart': [
    R(
      "title: const Text('Unsaved changes')",
      'title: Text(context.tr.command_unsaved_title)',
    ),
    R(
      "content: const Text('You have unsaved changes. Discard them?')",
      'content: Text(context.tr.command_unsaved_confirm)',
    ),
    R(
      "child: const Text('Keep editing')",
      'child: Text(context.tr.command_unsaved_keep)',
    ),
    R("child: const Text('Save')", 'child: Text(context.tr.common_save)'),
    R(
      "title: const Text('Auto defer if actions exist')",
      'title: Text(context.tr.response_workflow_auto_defer)',
    ),
    R(
      "child: Text('Public')",
      'child: Text(context.tr.response_workflow_public)',
    ),
    R(
      "title: Text('Error policy')",
      'title: Text(context.tr.response_workflow_error_policy)',
    ),
    R(
      "title: const Text('Enable condition')",
      'title: Text(context.tr.response_workflow_enable_condition)',
    ),
    R("label: 'Normal'", "label: context.tr.response_workflow_mode_normal"),
    R(
      "label: 'Component'",
      "label: context.tr.response_workflow_mode_component",
    ),
    R("label: 'Modal'", "label: context.tr.response_workflow_mode_modal"),
    R(
      "tooltip: 'Revert all changes'",
      "tooltip: context.tr.response_workflow_revert_tooltip",
    ),
    R("tooltip: 'Save'", "tooltip: context.tr.common_save"),
    R(
      "label: 'THEN response text (optional)'",
      "label: context.tr.response_workflow_then_text",
    ),
    R(
      "label: 'ELSE response text (optional)'",
      "label: context.tr.response_workflow_else_text",
    ),
  ],

  // ============================================================
  // app.dart (remaining strings)
  // ============================================================
  'routes/app.dart': [
    R(
      "title: const Text('Delete bot locally')",
      'title: Text(context.tr.recovery_delete_bot)',
    ),
    R(
      "appBar: AppBar(title: const Text('Recovery mode'))",
      'appBar: AppBar(title: Text(context.tr.recovery_title))',
    ),
    R(
      "label: const Text('Retry Discord connection')",
      'label: Text(context.tr.recovery_retry_discord)',
    ),
    R(
      "label: const Text('Delete bot locally')",
      'label: Text(context.tr.recovery_delete_bot)',
    ),
    R("label: 'Recovery'", "label: context.tr.recovery_label"),
    R("compactLabel: 'Recovery'", "compactLabel: context.tr.recovery_label"),
    R("label: 'Webhooks'", "label: context.tr.webhooks_page_title"),
    R("compactLabel: 'Hooks'", "compactLabel: context.tr.webhooks_page_title"),
  ],

  // ============================================================
  // bdfd_editor_page.dart (remaining strings)
  // ============================================================
  'widgets/bdfd_editor_page.dart': [
    R("const Text('Includes:')", 'Text(context.tr.bdfd_editor_includes)'),
    R("tooltip: 'Editor UX'", 'tooltip: context.tr.bdfd_editor_ux_title'),
    R(
      "tooltip: 'Toggle indentation guides'",
      'tooltip: context.tr.bdfd_editor_toggle_indent',
    ),
  ],

  // ============================================================
  // main.dart
  // ============================================================
  'main.dart': [
    R(
      "appBar: AppBar(title: const Text('Startup Error'))",
      'appBar: AppBar(title: Text(context.tr.startup_error_title))',
    ),
    R(
      "child: const Text('Copy diagnostics')",
      'child: Text(context.tr.startup_copy_diagnostics)',
    ),
    R(
      "child: const Text('Refresh diagnostics')",
      'child: Text(context.tr.startup_refresh_diagnostics)',
    ),
    R(
      "const SnackBar(content: Text('Diagnostics copied to clipboard'))",
      'SnackBar(content: Text(context.tr.startup_diagnostics_copied))',
    ),
  ],

  // ============================================================
  // emojis.page.dart (remaining strings)
  // ============================================================
  'routes/app/emojis.page.dart': [
    R("child: const Text('Retry')", 'child: Text(context.tr.common_retry)'),
    R("tooltip: 'Refresh'", 'tooltip: context.tr.common_refresh'),
    R("tooltip: 'Rename'", 'tooltip: context.tr.common_edit'),
    R("tooltip: 'Delete'", 'tooltip: context.tr.common_delete'),
  ],

  // ============================================================
  // settings.dart (remaining strings)
  // ============================================================
  'routes/settings.dart': [
    R(
      "label: const Text('Run Diagnostics')",
      'label: Text(context.tr.settings_run_diagnostics)',
    ),
    R(
      "label: const Text('Open Ad Inspector')",
      'label: Text(context.tr.settings_open_ad_inspector)',
    ),
    R(
      "title: const Text('Built-in legacy !help command')",
      'title: Text(context.tr.settings_builtin_help)',
    ),
  ],

  // ============================================================
  // workflows.page.dart (remaining UI strings, NOT event names)
  // ============================================================
  'routes/app/workflows.page.dart': [
    R("label: const Text('All')", 'label: Text(context.tr.common_all)'),
    R(
      "child: Text('No workflows match the current filters.')",
      'child: Text(context.tr.workflows_no_matches)',
    ),
    R("Text('Edit')", 'Text(context.tr.common_edit)'),
  ],

  // ============================================================
  // drive.dart
  // ============================================================
  'utils/drive.dart': [
    R("label: 'Manual backup'", 'label: context.tr.drive_manual_backup'),
    R("label: 'Legacy snapshot'", 'label: context.tr.drive_legacy_snapshot'),
  ],

  // ============================================================
  // commands.list.dart (remaining filter labels)
  // ============================================================
  'routes/app/commands.list.dart': [
    R("label: const Text('All')", 'label: Text(context.tr.common_all)'),
    R(
      "label: const Text('Slash')",
      'label: Text(context.tr.command_type_slash)',
    ),
    R("label: const Text('User')", 'label: Text(context.tr.command_type_user)'),
    R(
      "label: const Text('Message')",
      'label: Text(context.tr.command_type_message)',
    ),
    R(
      "label: const Text('Legacy')",
      'label: Text(context.tr.command_type_legacy)',
    ),
    R(
      "label: const Text('Template')",
      'label: Text(context.tr.commands_filter_template)',
    ),
    R(
      "label: const Text('Legacy local')",
      'label: Text(context.tr.commands_filter_legacy_local)',
    ),
  ],
};
