import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/utils/global.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

Future<Map<String, String>> clearAllReactionsAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required Snowflake? fallbackChannelId,
}) async {
  try {
    final channelId = _toSnowflake(payload['channelId']) ?? fallbackChannelId;
    final messageId = _toSnowflake(payload['messageId']);
    if (channelId == null || messageId == null) {
      return {'error': 'Missing channelId/messageId', 'status': ''};
    }

    final channel = await fetchChannelCached(client, channelId);
    if (channel is! TextChannel) {
      return {'error': 'Channel is not a text channel', 'status': ''};
    }

    final message = await channel.messages.fetch(messageId);
    final emoji = (payload['emoji'] ?? '!all').toString().trim();
    if (emoji == '!all') {
      await message.deleteAllReactions();
    } else {
      final custom = RegExp(r'^<a?:([^:>]+):(\d+)>$').firstMatch(emoji);
      final reaction = custom == null
          ? ReactionBuilder(name: emoji, id: null)
          : ReactionBuilder(
              name: custom.group(1)!,
              id: Snowflake(int.parse(custom.group(2)!)),
            );
      await message.deleteReaction(reaction);
    }
    return {'status': 'OK'};
  } catch (error) {
    return {'error': 'Failed to clear reactions: $error', 'status': ''};
  }
}
