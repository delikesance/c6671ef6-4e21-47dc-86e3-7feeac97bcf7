import 'package:nyxx/nyxx.dart';

import '../services/bot_voice_service.dart';

// The Discord logic lives in [BotVoiceService]; these functions are the historical entry
// points of the blocks and delegate to it.

/// Moves a member to a voice channel.
///
/// Payload fields:
/// - `userId` — member to move (required)
/// - `targetChannelId` — destination voice channel (required)
/// - `reason` — audit log reason
///
/// Returns `{'userId', 'channelId', 'status': 'moved'}` or `{'error': '...'}`.
Future<Map<String, String>> moveToVoiceChannelAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotVoiceService(
  client,
).moveToVoiceChannel(guildId: guildId, payload: payload, resolve: resolve);

/// Disconnects a member from their current voice channel.
///
/// Payload fields:
/// - `userId` — member to disconnect (required)
/// - `reason` — audit log reason
///
/// Returns `{'userId', 'status': 'disconnected'}` or `{'error': '...'}`.
Future<Map<String, String>> disconnectFromVoiceAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotVoiceService(
  client,
).disconnectFromVoice(guildId: guildId, payload: payload, resolve: resolve);

/// Server-mutes or unmutes a guild member.
///
/// Payload fields:
/// - `userId` — member to (un)mute (required)
/// - `mute` — true to mute, false to unmute (required)
/// - `reason` — audit log reason
///
/// Returns `{'userId', 'status': 'muted' | 'unmuted'}` or `{'error': '...'}`.
Future<Map<String, String>> serverMuteMemberAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotVoiceService(
  client,
).serverMuteMember(guildId: guildId, payload: payload, resolve: resolve);

/// Server-deafens or undeafens a guild member.
///
/// Payload fields:
/// - `userId` — member to (un)deafen (required)
/// - `deaf` — true to deafen, false to undeafen (required)
/// - `reason` — audit log reason
///
/// Returns `{'userId', 'status': 'deafened' | 'undeafened'}` or `{'error': '...'}`.
Future<Map<String, String>> serverDeafenMemberAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotVoiceService(
  client,
).serverDeafenMember(guildId: guildId, payload: payload, resolve: resolve);
