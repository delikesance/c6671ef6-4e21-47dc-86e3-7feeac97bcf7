import 'package:nyxx/nyxx.dart';

import '../services/bot_invite_service.dart';

export '../services/bot_invite_service.dart'
    show buildInviteUrl, resolveInviteChannelId;

/// Creates an invite for a channel. Payload: `channelId` (default: current
/// channel), `maxAge` (default 86400), `maxUses`, `temporary`, `unique`,
/// `reason`. See [BotInviteService].
Future<Map<String, String>> createInviteAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  Snowflake? fallbackChannelId,
}) => DiscordBotInviteService(client).create(
  payload: payload,
  resolve: resolve,
  fallbackChannelId: fallbackChannelId,
);

/// Deletes an invite by its `inviteCode`.
Future<Map<String, String>> deleteInviteAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) =>
    DiscordBotInviteService(client).delete(payload: payload, resolve: resolve);

/// Fetches an invite by its `inviteCode`.
Future<Map<String, String>> getInviteAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotInviteService(client).fetch(payload: payload, resolve: resolve);
