import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/utils/global.dart';
import 'package:bot_creator_shared/actions/handler_utils.dart';
import 'permission_checks.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

Future<Map<String, String>> unbanUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) async {
  // Résoudre les variables dans le payload si une fonction resolve est fournie
  final resolvedPayload = resolve != null
      ? resolvePayloadValues(payload, resolve)
      : payload;

  try {
    if (guildId == null) {
      return {'error': 'Missing guildId', 'userId': ''};
    }

    final permError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.banMembers],
      actionLabel: 'unban this user',
    );
    if (permError != null) {
      return {'error': permError, 'userId': ''};
    }

    var userId = _toSnowflake(resolvedPayload['userId']);
    if (userId == null) {
      final username = resolvedPayload['username']?.toString().trim() ?? '';
      if (username.isNotEmpty) {
        Snowflake? cursor;
        while (true) {
          final page = await client.guilds.listBans(
            guildId,
            limit: 1000,
            after: cursor,
          );
          for (final ban in page) {
            if (ban.user.username.toLowerCase() == username.toLowerCase()) {
              userId = ban.user.id;
              break;
            }
          }
          if (userId != null || page.length < 1000) break;
          final next = page.last.user.id;
          if (next == cursor) break;
          cursor = next;
        }
      }
    }
    if (userId == null) {
      return {'error': 'Banned user not found', 'userId': ''};
    }

    final reason = resolvedPayload['reason']?.toString().trim();
    final guild = await fetchGuildCached(client, guildId);
    if (guild == null) return {'error': 'Guild not found', 'userId': ''};
    await guild.deleteBan(
      userId,
      auditLogReason: (reason != null && reason.isNotEmpty)
          ? reason
          : 'Unban via BotCreator action',
    );

    return {'userId': userId.toString()};
  } catch (error) {
    return {'error': 'Failed to unban user: $error', 'userId': ''};
  }
}
