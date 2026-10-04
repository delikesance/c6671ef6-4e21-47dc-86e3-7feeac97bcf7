import 'package:nyxx/nyxx.dart';

import '../services/bot_moderation_service.dart';
import '../engine/execution_budget.dart';
import 'handler_utils.dart';

/// Resolves visual block data once before calling the shared transport.
Future<Map<String, String>> unbanUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) {
  final values = resolve == null
      ? payload
      : resolvePayloadValues(payload, resolve);
  final rawId = values['userId']?.toString() ?? '';
  final parsed = int.tryParse(rawId);
  // Preserve the historical username fallback for visual block payloads.
  return executeDiscordModeration(
    client,
    guildId: guildId,
    budget: budget,
    request: BotModerationRequest(
      operation: BotModerationOperation.unban,
      userId: parsed != null && parsed > 0 ? rawId : '',
      username: values['username']?.toString() ?? '',
      reason: values['reason']?.toString() ?? '',
    ),
  );
}
