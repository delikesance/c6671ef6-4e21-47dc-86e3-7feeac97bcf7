import 'package:nyxx/nyxx.dart';

import '../services/bot_guild_admin_service.dart';

// The Discord logic lives in [BotGuildAdminService]; these functions are the historical entry
// points of the blocks and delegate to it.

Future<Map<String, String>> updateGuildAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) => DiscordBotGuildAdminService(
  client,
).updateGuild(guildId: guildId, payload: payload, resolve: resolve);
