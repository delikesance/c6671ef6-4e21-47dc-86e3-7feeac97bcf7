import 'package:nyxx/nyxx.dart';

import '../services/bot_member_list_service.dart';

/// `getMember` block. See [BotMemberListService.get].
Future<Map<String, String>> getMemberAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
}) =>
    DiscordBotMemberListService(client).get(guildId: guildId, payload: payload);
