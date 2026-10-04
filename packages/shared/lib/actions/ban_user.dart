import 'package:nyxx/nyxx.dart';

import '../services/bot_moderation_service.dart';
import '../engine/execution_budget.dart';
import 'handler_utils.dart';

/// Resolves block placeholders before invoking the shared moderation service.
Future<Map<String, String>> banUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) {
  final values = resolve == null
      ? payload
      : resolvePayloadValues(payload, resolve);
  return executeDiscordModeration(
    client,
    guildId: guildId,
    budget: budget,
    request: BotModerationRequest(
      operation: BotModerationOperation.ban,
      userId: values['userId']?.toString() ?? '',
      reason: values['reason']?.toString() ?? '',
      deleteMessageDays:
          int.tryParse((values['deleteMessageDays'] ?? '0').toString()) ?? 0,
    ),
  );
}
