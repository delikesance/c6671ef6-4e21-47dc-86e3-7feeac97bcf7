import 'package:nyxx/nyxx.dart';

import '../services/bot_emoji_block_service.dart';

/// Creates a guild emoji. See [BotEmojiBlockService.create].
Future<Map<String, String>> createEmojiAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotEmojiBlockService(
  client,
).create(guildId: guildId, payload: payload, resolve: resolve);

/// Updates a guild emoji. See [BotEmojiBlockService.update].
Future<Map<String, String>> updateEmojiAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotEmojiBlockService(
  client,
).update(guildId: guildId, payload: payload, resolve: resolve);

/// Deletes a guild emoji. See [BotEmojiBlockService.delete].
Future<Map<String, String>> deleteEmojiAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotEmojiBlockService(
  client,
).delete(guildId: guildId, payload: payload, resolve: resolve);
