import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../services/bot_moderation_service.dart';
import 'handler_utils.dart';

Future<Map<String, String>> unmuteUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) async {
  final values = resolve == null
      ? payload
      : resolvePayloadValues(payload, resolve);
  final id = int.tryParse(values['userId']?.toString() ?? '');
  final userId = id != null && id > 0
      ? id.toString()
      : values['memberId']?.toString() ?? '';
  return executeDiscordModeration(
    client,
    guildId: guildId,
    budget: budget,
    request: BotModerationRequest(
      operation: BotModerationOperation.untimeout,
      userId: userId,
      reason: values['reason']?.toString() ?? '',
    ),
  );
}
