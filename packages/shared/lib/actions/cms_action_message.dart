import 'dart:convert';

import 'package:bot_creator_shared/actions/send_message.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:nyxx/nyxx.dart';

/// Global variable key for a CMS action module message template.
String cmsActionVariableKey(String moduleId) => 'cms.$moduleId.action';

/// Guild-scoped CMS field key.
String cmsFieldVariableKey(String moduleId, String fieldId) =>
    'cms.$moduleId.$fieldId';

/// Substitutes `{{field_id}}` placeholders using [fieldValues].
String substituteCmsPlaceholders(
  String input,
  Map<String, String> fieldValues,
) {
  var out = input;
  for (final entry in fieldValues.entries) {
    out = out.replaceAll('{{${entry.key}}}', entry.value);
  }
  // Clear unresolved placeholders.
  out = out.replaceAll(RegExp(r'\{\{[a-zA-Z0-9_-]+\}\}'), '');
  return out;
}

Map<String, dynamic> _asStringKeyedMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((k, v) => MapEntry(k.toString(), v));
  }
  if (raw is String && raw.trim().isNotEmpty) {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
  }
  return <String, dynamic>{};
}

String _stringifyFieldValue(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is bool || value is num) return value.toString();
  return jsonEncode(value);
}

/// Loads `cms.{module}.action` (global) and guild field values, then sends the
/// templated Discord message via [sendMessageToChannel].
///
/// Field placeholders use `{{field_id}}` and resolve from guild-scoped
/// `cms.{module}.{field}` variables projected by the Creator Console.
Future<Map<String, String>> sendCmsModuleActionMessage({
  required NyxxGateway client,
  required BotDataStore store,
  required String botId,
  required String moduleId,
  required String guildId,
  required Snowflake channelId,
  Map<String, String>? extraPlaceholders,
}) async {
  final rawAction = await store.getGlobalVariable(
    botId,
    cmsActionVariableKey(moduleId),
  );
  if (rawAction == null) {
    return {
      'error': 'CMS action template not found for module $moduleId',
      'messageId': '',
    };
  }
  final action = _asStringKeyedMap(rawAction);
  final guildVars = await store.getScopedVariables(botId, 'guild', guildId);
  final fields = <String, String>{};
  final prefix = 'cms.$moduleId.';
  for (final entry in guildVars.entries) {
    if (!entry.key.startsWith(prefix)) continue;
    final fieldId = entry.key.substring(prefix.length);
    if (fieldId.isEmpty || fieldId == 'action') continue;
    fields[fieldId] = _stringifyFieldValue(entry.value);
  }
  if (extraPlaceholders != null) {
    fields.addAll(extraPlaceholders);
  }

  String resolve(String input) => substituteCmsPlaceholders(input, fields);

  final content = resolve((action['content'] ?? '').toString());
  final payload = <String, dynamic>{
    if (action['embeds'] != null) 'embeds': action['embeds'],
    if (action['components'] != null) 'components': action['components'],
  };

  return sendMessageToChannel(
    client,
    channelId,
    content: content,
    payload: payload,
    resolve: resolve,
    botId: botId,
    guildId: guildId,
  );
}
