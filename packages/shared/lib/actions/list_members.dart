import 'package:nyxx/nyxx.dart';

import '../services/bot_member_list_service.dart';

/// `listMembers` block. See [BotMemberListService.list].
Future<Map<String, String>> listMembersAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
}) => DiscordBotMemberListService(
  client,
).list(guildId: guildId, payload: payload);
