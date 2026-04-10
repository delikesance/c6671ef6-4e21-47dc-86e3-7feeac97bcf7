import 'dart:io';

/// Migrates AppStrings.t('key') → context.tr.key
/// and AppStrings.tr('key', params: {...}) → context.tr.key(args...)
///
/// Run: dart run tools/migrate_appstrings.dart
void main() {
  // ── Method signatures for parameterised keys (from app_localizations.dart) ─
  // Maps method name → ordered list of parameter names
  final paramSignatures = <String, List<String>>{
    'emojis_delete_confirm_body': ['name'],
    'emojis_upload_error': ['error'],
    'emojis_delete_error': ['error'],
    'emojis_rename_error': ['error'],
    'settings_snapshot_id': ['id'],
    'settings_snapshot_label': ['label'],
    'settings_snapshot_created_at': ['date'],
    'settings_snapshot_files_size': ['count', 'size'],
    'settings_snapshot_apps_count': ['count'],
    'settings_runner_active': ['url'],
    'settings_discord_rpc_user': ['user'],
    'settings_discord_rpc_endpoint': ['endpoint'],
    'settings_discord_rpc_last_error': ['error'],
    'settings_last_auto_backup_at': ['date'],
    'settings_snapshot_created_message': ['id'],
    'settings_snapshots_delete_all_confirm': ['count'],
    'settings_snapshots_delete_all_done': ['count'],
    'settings_snapshots_delete_one_confirm': ['label'],
    'settings_snapshot_list_entry': ['date', 'count', 'size'],
    'settings_compatibility_functions_count': ['count'],
    'settings_compatibility_functions_count_bot_creator': ['count'],
    'settings_compatibility_functions_count_bdfd': ['count'],
    'settings_compatibility_functions_count_both': ['count'],
    'settings_compatibility_functions_count_missing': ['count'],
    'settings_compatibility_functions_count_bot_only': ['count'],
    'home_token_missing': ['botName'],
    'home_server_count_one': ['count'],
    'home_server_count_other': ['count'],
    'error_with_details': ['error'],
    'bot_home_start_error': ['error'],
    'bot_settings_token_mismatch_content': ['newId', 'oldId'],
    'bot_settings_avatar_selected_file': ['path'],
    'bot_settings_avatar_unsupported_format': ['ext', 'formats'],
    'bot_settings_status_item_title': ['index'],
    'bot_logs_show_n': ['count'],
    'bot_logs_ram': ['memory'],
    'bot_logs_ram_estimated': ['memory'],
    'debug_replay_start_offset': ['ms'],
    'debug_replay_loop_info': ['depth', 'iteration'],
    'commands_error': ['error'],
    'globals_delete_confirm': ['key'],
    'globals_source_runner': ['name'],
    'globals_dialog_scoped_desc': ['scope'],
    'globals_dialog_ref_preview': ['ref'],
    'scoped_delete_confirm': ['key'],
    'scoped_ref': ['ref'],
    'scoped_ref_legacy': ['ref'],
    'scoped_runtime_title': ['key'],
    'scoped_runtime_subtitle': ['scope', 'count'],
    'workflows_subtitle': ['count', 'entry', 'args'],
    'workflows_event_subtitle': ['count', 'event'],
    'workflows_event_preview': ['event'],
    'workflows_delete_confirm': ['name'],
    'workflows_import_done': ['count'],
    'doc_template_variables_example': ['name', 'score'],
    'doc_interaction_commands_example': ['name', 'id'],
    'template_gallery_apply_success': ['count', 'wCount'],
    'template_gallery_apply_error': ['error'],
    'template_gallery_commands_count': ['count'],
    'template_gallery_workflows_count': ['count'],
    'template_gallery_already_exists': ['name'],
    'dashboard_executions': ['count'],
    'dashboard_selected_period_total': ['count'],
    'dashboard_error': ['error'],
    'runner_source_label': ['name'],
    'logs_runner_source': ['name'],
    'template_gallery_nothing_to_remove': ['name'],
  };

  final files =
      Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.contains('l10n/'))
          .where((f) => !f.path.contains('trad/'))
          .where((f) => !f.path.endsWith('i18n.dart'))
          .toList();

  var totalT = 0;
  var totalTr = 0;
  var totalDoubleQuoted = 0;

  for (final file in files) {
    var content = file.readAsStringSync();
    var tCount = 0;
    var trCount = 0;

    // ── 1. Replace AppStrings.t('key') with context.tr.key ──────────────
    // Handles multiline, optional trailing comma
    // Single-quoted keys only (identifier chars)
    content = content.replaceAllMapped(
      RegExp(r"""AppStrings\.t\(\s*'([a-zA-Z_][a-zA-Z0-9_]*)'\s*,?\s*\)"""),
      (m) {
        tCount++;
        return 'context.tr.${m.group(1)}';
      },
    );

    // ── 1b. Double-quoted keys: AppStrings.t("key") ─────────────────────
    content = content.replaceAllMapped(
      RegExp(r'''AppStrings\.t\(\s*"([a-zA-Z_][a-zA-Z0-9_]*)"\s*,?\s*\)'''),
      (m) {
        totalDoubleQuoted++;
        tCount++;
        return 'context.tr.${m.group(1)}';
      },
    );

    // ── 2. Replace AppStrings.tr('key', params: {…}) ────────────────────
    // We use a two-pass approach: find the tr( call, extract key+params body,
    // then rebuild with positional args.
    final trPattern = RegExp(
      r"""AppStrings\.tr\(\s*'([a-zA-Z_][a-zA-Z0-9_]*)'\s*,\s*params\s*:\s*\{""",
    );

    while (trPattern.hasMatch(content)) {
      final match = trPattern.firstMatch(content)!;
      final key = match.group(1)!;
      final paramBodyStart = match.end; // right after the opening {

      // Find the matching closing } for the params map
      final closingBrace = _findMatchingBrace(content, paramBodyStart - 1);
      if (closingBrace == -1) {
        print(
          '  WARNING: Could not find matching } for tr($key) in ${file.path}',
        );
        break;
      }

      // Find the closing ) of the tr() call: skip whitespace/comma after }
      var trEnd = closingBrace + 1;
      while (trEnd < content.length &&
          (content[trEnd] == ' ' ||
              content[trEnd] == '\n' ||
              content[trEnd] == '\r' ||
              content[trEnd] == '\t' ||
              content[trEnd] == ',')) {
        trEnd++;
      }
      if (trEnd < content.length && content[trEnd] == ')') {
        trEnd++; // include the closing )
      }

      final paramBody = content.substring(paramBodyStart, closingBrace).trim();

      // Parse the params map: 'name': expression
      final params = _parseParamsMap(paramBody);

      // Get method signature
      final sig = paramSignatures[key];
      if (sig == null) {
        print(
          '  WARNING: No signature found for tr($key) in ${file.path}. Converting to simple getter.',
        );
        // No params in the generated method — treat as a simple getter
        content =
            '${content.substring(0, match.start)}context.tr.$key${content.substring(trEnd)}';
        tCount++;
        continue;
      }

      // Build positional args in signature order
      final args = <String>[];
      for (final paramName in sig) {
        final expr = params[paramName];
        if (expr == null) {
          print(
            '  WARNING: Missing param "$paramName" for tr($key) in ${file.path}',
          );
          args.add("'??? $paramName'");
        } else {
          args.add(expr);
        }
      }

      final replacement = 'context.tr.$key(${args.join(', ')})';
      content =
          content.substring(0, match.start) +
          replacement +
          content.substring(trEnd);
      trCount++;
    }

    if (tCount > 0 || trCount > 0) {
      file.writeAsStringSync(content);
      print(
        '${file.path}: $tCount .t() + $trCount .tr() = ${tCount + trCount} replacements',
      );
      totalT += tCount;
      totalTr += trCount;
    }
  }

  print('');
  print(
    'Total: $totalT .t() + $totalTr .tr() = ${totalT + totalTr} replacements',
  );
  if (totalDoubleQuoted > 0) {
    print('  (including $totalDoubleQuoted double-quoted keys)');
  }
}

/// Find the index of the closing brace matching the opening brace at [openIndex].
int _findMatchingBrace(String s, int openIndex) {
  var depth = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escaped = false;

  for (var i = openIndex; i < s.length; i++) {
    final c = s[i];

    if (escaped) {
      escaped = false;
      continue;
    }
    if (c == r'\') {
      escaped = true;
      continue;
    }

    if (inSingleQuote) {
      if (c == "'") inSingleQuote = false;
      continue;
    }
    if (inDoubleQuote) {
      if (c == '"') inDoubleQuote = false;
      continue;
    }

    if (c == "'") {
      inSingleQuote = true;
      continue;
    }
    if (c == '"') {
      inDoubleQuote = true;
      continue;
    }

    if (c == '{') {
      depth++;
    } else if (c == '}') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

/// Parse a Dart map literal body like:  'key1': expr1, 'key2': expr2
/// Returns a map of key → expression string.
Map<String, String> _parseParamsMap(String body) {
  final result = <String, String>{};
  // Split by top-level commas (not inside parens, brackets, quotes)
  final entries = _splitTopLevel(body, ',');

  for (final entry in entries) {
    final trimmed = entry.trim();
    if (trimmed.isEmpty) continue;

    // Match 'key': value
    final keyMatch = RegExp(r"""^'(\w+)'\s*:\s*""").firstMatch(trimmed);
    if (keyMatch == null) continue;

    final key = keyMatch.group(1)!;
    final value = trimmed.substring(keyMatch.end).trim();
    result[key] = value;
  }
  return result;
}

/// Split [s] by [delimiter] only at the top level (not inside (), [], {}, quotes).
List<String> _splitTopLevel(String s, String delimiter) {
  final parts = <String>[];
  var depth = 0;
  var inSingleQuote = false;
  var inDoubleQuote = false;
  var escaped = false;
  var start = 0;

  for (var i = 0; i < s.length; i++) {
    final c = s[i];

    if (escaped) {
      escaped = false;
      continue;
    }
    if (c == r'\') {
      escaped = true;
      continue;
    }

    if (inSingleQuote) {
      if (c == "'") inSingleQuote = false;
      continue;
    }
    if (inDoubleQuote) {
      if (c == '"') inDoubleQuote = false;
      continue;
    }

    if (c == "'") {
      inSingleQuote = true;
      continue;
    }
    if (c == '"') {
      inDoubleQuote = true;
      continue;
    }

    if (c == '(' || c == '[' || c == '{') {
      depth++;
    } else if (c == ')' || c == ']' || c == '}') {
      depth--;
    } else if (depth == 0 && s.substring(i).startsWith(delimiter)) {
      parts.add(s.substring(start, i));
      start = i + delimiter.length;
    }
  }
  parts.add(s.substring(start));
  return parts;
}
