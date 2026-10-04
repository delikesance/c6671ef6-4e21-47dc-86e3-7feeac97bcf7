import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../services/bot_moderation_service.dart';
import 'handler_utils.dart';

Future<Map<String, String>> muteUserAction(
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
  final rawUntil = values['until']?.toString().trim() ?? '';
  final until = rawUntil.isEmpty ? null : DateTime.tryParse(rawUntil);
  if (rawUntil.isNotEmpty && until == null) {
    return {'error': 'Invalid until datetime format', 'userId': ''};
  }
  return executeDiscordModeration(
    client,
    guildId: guildId,
    budget: budget,
    request: BotModerationRequest(
      operation: BotModerationOperation.timeout,
      userId: userId,
      reason: values['reason']?.toString() ?? '',
      duration: visualTimeoutDuration(values),
      until: until,
    ),
  );
}
