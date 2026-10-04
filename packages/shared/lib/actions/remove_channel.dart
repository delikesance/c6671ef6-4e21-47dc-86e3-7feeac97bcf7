import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../services/bot_channel_mutation_service.dart';

Future<Map<String, String>> removeChannel(
  NyxxGateway client,
  Snowflake channelId, {
  CommandExecutionBudget? budget,
  String? reason,
}) => removeChannelWith(
  DiscordBotChannelMutationService(client),
  channelId,
  budget: budget,
  reason: reason,
);

/// [removeChannel] over any [BotChannelMutationService].
Future<Map<String, String>> removeChannelWith(
  BotChannelMutationService service,
  Snowflake channelId, {
  CommandExecutionBudget? budget,
  String? reason,
}) async {
  try {
    await service.deleteChannel(
      ChannelDeletion(channelId: '$channelId', reason: reason),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': '$channelId'};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to delete channel: $error', 'channelId': ''};
  }
}
