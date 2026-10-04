import 'package:nyxx/nyxx.dart';

import '../utils/global.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return Snowflake(parsed);
}

Snowflake? resolveInviteChannelId({
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  Snowflake? fallbackChannelId,
}) {
  final explicitChannelId = _toSnowflake(
    resolve((payload['channelId'] ?? '').toString()),
  );
  return explicitChannelId ?? fallbackChannelId;
}

String buildInviteUrl(String inviteCode) => 'https://discord.gg/$inviteCode';

/// Invite operations of the visual blocks `createInvite`, `deleteInvite` and
/// `getInvite`. Each returns the block's own result map (`{'error': ...}` on
/// failure) so the historical action functions and the hidden `bc_*` functions
/// share one implementation.
abstract interface class BotInviteService {
  Future<Map<String, String>> create({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
    Snowflake? fallbackChannelId,
  });
  Future<Map<String, String>> delete({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> fetch({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  });
}

class DiscordBotInviteService implements BotInviteService {
  const DiscordBotInviteService(this.client);
  final NyxxGateway client;

  ///
  @override
  Future<Map<String, String>> create({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
    Snowflake? fallbackChannelId,
  }) async {
    try {
      final channelId = resolveInviteChannelId(
        payload: payload,
        resolve: resolve,
        fallbackChannelId: fallbackChannelId,
      );
      if (channelId == null) {
        return {'error': 'Missing or invalid channelId for createInvite'};
      }

      final maxAge =
          int.tryParse(resolve((payload['maxAge'] ?? '86400').toString())) ??
          86400;
      final maxUses =
          int.tryParse(resolve((payload['maxUses'] ?? '0').toString())) ?? 0;

      final temporaryRaw = resolve(
        (payload['temporary'] ?? 'false').toString(),
      ).toLowerCase();
      final temporary = temporaryRaw == 'true' || temporaryRaw == '1';

      final uniqueRaw = resolve(
        (payload['unique'] ?? 'false').toString(),
      ).toLowerCase();
      final unique = uniqueRaw == 'true' || uniqueRaw == '1';

      final reason = resolve((payload['reason'] ?? '').toString()).trim();

      final channel = await fetchChannelCached(client, channelId);
      if (channel is! GuildChannel) {
        return {'error': 'Channel is not a guild channel'};
      }

      final invite = await channel.createInvite(
        InviteBuilder(
          maxAge: Duration(seconds: maxAge),
          maxUses: maxUses,
          isTemporary: temporary,
          isUnique: unique,
        ),
        auditLogReason: reason.isNotEmpty ? reason : null,
      );

      final inviteUrl = buildInviteUrl(invite.code);
      return {
        'inviteCode': invite.code,
        'invite_url': inviteUrl,
        'url': inviteUrl,
        'channelId': invite.channel.id.toString(),
        'guildId': invite.guild?.id.toString() ?? '',
      };
    } catch (e) {
      return {'error': 'Failed to create invite: $e'};
    }
  }

  ///
  @override
  Future<Map<String, String>> delete({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    try {
      final code = resolve((payload['inviteCode'] ?? '').toString()).trim();
      if (code.isEmpty) {
        return {'error': 'inviteCode is required for deleteInvite'};
      }

      final reason = resolve((payload['reason'] ?? '').toString()).trim();

      await client.invites.delete(
        code,
        auditLogReason: reason.isNotEmpty ? reason : null,
      );
      return {'inviteCode': code, 'status': 'deleted'};
    } catch (e) {
      return {'error': 'Failed to delete invite: $e'};
    }
  }

  ///
  @override
  Future<Map<String, String>> fetch({
    required Map<String, dynamic> payload,
    required String Function(String) resolve,
  }) async {
    try {
      final code = resolve((payload['inviteCode'] ?? '').toString()).trim();
      if (code.isEmpty) {
        return {'error': 'inviteCode is required for getInvite'};
      }

      final invite = await client.invites.fetch(code);
      return {
        'inviteCode': invite.code,
        'guildId': invite.guild?.id.toString() ?? '',
        'channelId': invite.channel.id.toString(),
        'expiresAt': invite.expiresAt?.toIso8601String() ?? '',
      };
    } catch (e) {
      return {'error': 'Failed to get invite: $e'};
    }
  }
}
