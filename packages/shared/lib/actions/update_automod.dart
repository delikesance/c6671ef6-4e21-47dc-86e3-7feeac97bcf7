import 'package:nyxx/nyxx.dart';

import '../services/bot_automod_service.dart';

// The Discord logic lives in [BotAutoModService]; these functions are the historical entry
// points of the blocks and delegate to it.

Future<Map<String, String>> updateAutoModAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
}) => DiscordBotAutoModService(
  client,
).updateAutoMod(guildId: guildId, payload: payload);
