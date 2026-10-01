import 'package:nyxx/nyxx.dart';

import '../utils/global.dart';
import 'permission_checks.dart';

GuildTextChannelBuilder buildPrivateTicketChannel({
  required String name,
  required Snowflake guildId,
  required Snowflake categoryId,
  required Snowflake ownerId,
}) => GuildTextChannelBuilder(
  name: name,
  parentId: categoryId,
  permissionOverwrites: [
    PermissionOverwriteBuilder(
      id: guildId,
      type: PermissionOverwriteType.role,
      deny: Permissions(1024), // View Channel
    ),
    PermissionOverwriteBuilder(
      id: ownerId,
      type: PermissionOverwriteType.member,
      allow: Permissions(68608), // View, Send, Read Message History
    ),
  ],
);

/// Creates a private text ticket with its permission overwrites in the initial
/// Discord request, so the channel is never briefly public.
Future<Map<String, String>> createTicketChannel(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    final categoryRaw = resolve((payload['categoryId'] ?? '').toString());
    final ownerRaw = resolve((payload['ownerId'] ?? '').toString());
    final categoryId = int.tryParse(categoryRaw);
    final ownerId = int.tryParse(ownerRaw);
    final name = resolve((payload['name'] ?? '').toString()).trim();
    if (categoryId == null || ownerId == null || name.isEmpty) {
      return {'error': 'Ticket requires category ID, creator ID and name'};
    }
    final permissionError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.manageChannels],
      actionLabel: 'create tickets',
    );
    if (permissionError != null) return {'error': permissionError};

    final category = await fetchChannelCached(client, Snowflake(categoryId));
    if (category is! GuildCategory || category.guildId != guildId) {
      return {'error': 'Ticket category not found in this server'};
    }
    final guild = await fetchGuildCached(client, guildId);
    if (guild == null) return {'error': 'Guild not found'};
    final channel = await guild.createChannel(
      buildPrivateTicketChannel(
        name: name,
        guildId: guildId,
        categoryId: Snowflake(categoryId),
        ownerId: Snowflake(ownerId),
      ),
    );
    return {'channelId': channel.id.toString(), 'ownerId': ownerId.toString()};
  } catch (error) {
    return {'error': 'Failed to create ticket: $error'};
  }
}
