import 'dart:convert';

import 'package:nyxx/nyxx.dart';

import '../engine/execution_budget.dart';
import '../utils/interaction_ack_state.dart';
import 'respond_with_message.dart';
import 'send_message.dart';

enum BotMessageDestination { response, channel, user }

/// A snapshot of an evaluated Discord message, independent of block actions.
class BotMessageRequest {
  BotMessageRequest({
    this.destination = BotMessageDestination.response,
    required Map<String, dynamic> payload,
  }) : payload =
           _freeze(jsonDecode(jsonEncode(payload))) as Map<String, dynamic>;

  final BotMessageDestination destination;
  final Map<String, dynamic> payload;
}

dynamic _freeze(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.unmodifiable(
      value.map((key, item) => MapEntry(key.toString(), _freeze(item))),
    );
  }
  if (value is List) return List<dynamic>.unmodifiable(value.map(_freeze));
  return value;
}

class BotMessageResult {
  const BotMessageResult({
    this.messageId,
    this.channelId,
    this.acknowledged = false,
    this.originalResponseCompleted = false,
  });
  final String? messageId;
  final String? channelId;
  final bool acknowledged;
  final bool originalResponseCompleted;
}

abstract interface class BotMessageService {
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  });
}

/// Uses the same Discord transport as visual blocks, with already evaluated
/// values. Returned data is never interpreted as script or placeholders.
class DiscordBotMessageService implements BotMessageService {
  DiscordBotMessageService({
    required this.botId,
    this.client,
    this.interaction,
    this.channelId,
    this.messageId,
    this.guildId,
  });

  final String botId;
  final NyxxGateway? client;
  final Interaction? interaction;
  final Snowflake? channelId;
  final Snowflake? messageId;
  final String? guildId;

  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) => budget.run(() async {
    final Map<String, dynamic> result;
    if (request.destination == BotMessageDestination.response) {
      result = await respondWithMessage(
        interaction,
        payload: request.payload,
        resolve: (value) => value,
        botId: botId,
        client: client,
        fallbackChannelId: channelId,
        fallbackMessageId: messageId,
        variables: variables,
      );
    } else {
      if (client == null) throw StateError('A Discord client is required.');
      final target = request.payload['channelId']?.toString();
      final payload = Map<String, dynamic>.from(request.payload);
      if (request.destination == BotMessageDestination.user) {
        payload['targetType'] = 'user';
      }
      if (payload['replyToMessage'] == true) {
        if (messageId == null) {
          throw StateError('No message available to reply to.');
        }
        payload['targetType'] = 'reply';
        payload['messageId'] = messageId.toString();
      }
      result = await sendMessageToChannel(
        client!,
        target == null || target.isEmpty
            ? channelId ?? interaction?.channelId
            : Snowflake.parse(target),
        content: request.payload['content']?.toString() ?? '',
        payload: payload,
        resolve: (value) => value,
        botId: botId,
        guildId: guildId,
      );
    }
    budget.check();
    if (result['error'] != null) throw StateError(result['error'].toString());
    return BotMessageResult(
      messageId: result['messageId']?.toString(),
      channelId: result['channelId']?.toString(),
      acknowledged:
          interaction != null && isInteractionAcknowledged(interaction!),
      originalResponseCompleted: result['originalResponseCompleted'] == true,
    );
  });
}
