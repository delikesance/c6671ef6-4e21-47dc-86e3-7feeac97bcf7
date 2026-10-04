import 'package:nyxx/nyxx.dart';

import '../services/bot_automod_service.dart';

// The Discord logic lives in [BotAutoModService]; these functions are the historical entry
// points of the blocks and delegate to it.

/// Creates a new AutoMod rule.
///
/// Payload fields:
/// - `name` — rule name (required)
/// - `triggerType` — one of: keyword, spam, keywordPreset, mentionSpam (required)
/// - `eventType` — message_send (default)
/// - `keywords` — list of keywords to filter (for keyword trigger)
/// - `keywordPresets` — list of presets: profanity, sexualContent, slurs
/// - `regexPatterns` — list of regex patterns
/// - `allowedWords` — words exempt from filtering
/// - `mentionTotalLimit` — max mentions for mentionSpam trigger
/// - `actionType` — block_message (default), send_alert_message, timeout
/// - `alertChannelId` — channel for alert messages
/// - `timeoutDuration` — timeout in seconds (for timeout action)
/// - `exemptRoles` — role IDs exempt from the rule
/// - `exemptChannels` — channel IDs exempt from the rule
/// - `enabled` — whether rule is enabled (default true)
/// - `reason` — audit log reason
///
/// Returns `{'ruleId', 'name', 'status': 'created'}` or `{'error': '...'}`.
Future<Map<String, String>> createAutoModRuleAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotAutoModService(
  client,
).createAutoModRule(guildId: guildId, payload: payload, resolve: resolve);

/// Deletes an AutoMod rule.
///
/// Payload fields:
/// - `ruleId` — rule ID to delete (required)
/// - `reason` — audit log reason
///
/// Returns `{'ruleId', 'status': 'deleted'}` or `{'error': '...'}`.
Future<Map<String, String>> deleteAutoModRuleAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotAutoModService(
  client,
).deleteAutoModRule(guildId: guildId, payload: payload, resolve: resolve);

/// Lists all AutoMod rules in a guild.
///
/// Returns `{'rulesJson': '[{...}]', 'count': 'N'}` or `{'error': '...'}`.
Future<Map<String, String>> listAutoModRulesAction(
  NyxxGateway client, {
  required Snowflake? guildId,
}) => DiscordBotAutoModService(client).listAutoModRules(guildId: guildId);
