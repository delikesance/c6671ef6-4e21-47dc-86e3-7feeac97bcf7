import 'package:nyxx/nyxx.dart';

import '../services/bot_poll_service.dart';

// The Discord logic lives in [BotPollService]; these functions are the historical entry
// points of the blocks and delegate to it.

/// Creates a Discord poll in a channel.
///
/// Payload fields:
/// - `channelId` — target channel
/// - `question` — poll question (required)
/// - `answers` — JSON array of answer strings, e.g. `["Yes","No"]` (required, max 10)
/// - `durationHours` — duration in hours (1–168, default 24)
/// - `allowMultiselect` — whether users can pick multiple answers (default false)
///
/// Returns `{'messageId', 'pollId'}` or `{'error': '...'}`.
Future<Map<String, String>> createPollAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  required String Function(String) resolve,
}) => DiscordBotPollService(client).createPoll(
  payload: payload,
  fallbackChannelId: fallbackChannelId,
  resolve: resolve,
);

/// Immediately ends an active poll on a message.
///
/// Payload fields:
/// - `channelId` — channel containing the poll message
/// - `messageId` — message ID of the poll
///
/// Returns `{'messageId', 'status': 'ended'}` or `{'error': '...'}`.
Future<Map<String, String>> endPollAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  String Function(String)? resolve,
}) => DiscordBotPollService(client).endPoll(
  payload: payload,
  fallbackChannelId: fallbackChannelId,
  resolve: resolve,
);
