import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';

import '../bot/bot_data_store.dart';
import '../utils/global.dart';
import '../actions/handler_utils.dart'
    show parseSnowflake, resolvePayloadValues;
import 'permission_checks.dart';

// Discord logic of visual blocks whose payload is wider than any BDFD function:
// threads, nickname, guild command registration, bot profile, channel overwrite
// removal and private tickets. Plain functions over the gateway: no dependency on
// the historical action loop.

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) return null;
  return Snowflake(parsed);
}

/// Creates a thread in a channel.
///
/// Payload fields:
/// - `channelId` — parent channel (required if no fallback)
/// - `name` — thread name (required)
/// - `autoArchiveDuration` — in minutes: 60, 1440, 4320 or 10080 (default 1440)
/// - `type` — 'public' or 'private' (default 'public', ignored when messageId is set)
/// - `messageId` — if provided, creates a thread on that existing message
/// - `slowmode` — slowmode delay in seconds (0 = off)
/// - `reason` — audit log reason
///
/// Returns `{'threadId', 'name', 'parentId'}` or `{'error': '...'}`.
Future<Map<String, String>> createThreadAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  required String Function(String) resolve,
}) async {
  try {
    final channelId =
        _toSnowflake(resolve((payload['channelId'] ?? '').toString())) ??
        fallbackChannelId;
    if (channelId == null) {
      return {'error': 'channelId is required for createThread'};
    }

    final name = resolve((payload['name'] ?? '').toString()).trim();
    if (name.isEmpty) {
      return {'error': 'name is required for createThread'};
    }

    final rawDuration =
        int.tryParse(
          resolve((payload['autoArchiveDuration'] ?? '1440').toString()),
        ) ??
        1440;
    // Clamp to valid Discord values
    final archiveMinutes = [60, 1440, 4320, 10080].reduce(
      (prev, curr) =>
          (curr - rawDuration).abs() < (prev - rawDuration).abs() ? curr : prev,
    );
    final archiveDuration = Duration(minutes: archiveMinutes);

    final slowmode =
        int.tryParse(resolve((payload['slowmode'] ?? '0').toString())) ?? 0;
    final reason = resolve((payload['reason'] ?? '').toString()).trim();

    final messageId = _toSnowflake(
      resolve((payload['messageId'] ?? '').toString()),
    );

    final channel = await fetchChannelCached(client, channelId);

    Thread thread;
    if (messageId != null && channel is GuildTextChannel) {
      // Thread on an existing message
      thread = await channel.createThreadFromMessage(
        messageId,
        ThreadFromMessageBuilder(
          name: name,
          autoArchiveDuration: archiveDuration,
          rateLimitPerUser: slowmode > 0 ? Duration(seconds: slowmode) : null,
        ),
        auditLogReason: reason.isNotEmpty ? reason : null,
      );
    } else if (channel is GuildTextChannel) {
      final typeRaw = resolve(
        (payload['type'] ?? 'public').toString(),
      ).toLowerCase();
      final isPrivate = typeRaw == 'private';
      thread = await channel.createThread(
        isPrivate
            ? ThreadBuilder.privateThread(
                name: name,
                autoArchiveDuration: archiveDuration,
                rateLimitPerUser: slowmode > 0
                    ? Duration(seconds: slowmode)
                    : null,
              )
            : ThreadBuilder.publicThread(
                name: name,
                autoArchiveDuration: archiveDuration,
                rateLimitPerUser: slowmode > 0
                    ? Duration(seconds: slowmode)
                    : null,
              ),
        auditLogReason: reason.isNotEmpty ? reason : null,
      );
    } else {
      return {'error': 'Channel does not support threads'};
    }

    return {
      'threadId': thread.id.toString(),
      'name': thread.name,
      'parentId': channelId.toString(),
    };
  } catch (e) {
    return {'error': 'Failed to create thread: $e'};
  }
}

Future<Map<String, String>> addThreadMemberAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    final threadId = _toSnowflake(
      resolve((payload['threadId'] ?? '').toString()),
    );
    final userId = _toSnowflake(resolve((payload['userId'] ?? '').toString()));
    if (threadId == null || userId == null) {
      return {'error': 'threadId and userId are required for threadAddMember'};
    }

    final channel = await fetchChannelCached(client, threadId);
    if (channel is! Thread) {
      return {'error': 'Provided channel is not a thread'};
    }

    await channel.addThreadMember(userId);
    return {'threadId': threadId.toString(), 'userId': userId.toString()};
  } catch (e) {
    return {'error': 'Failed to add thread member: $e'};
  }
}

Future<Map<String, String>> removeThreadMemberAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    final threadId = _toSnowflake(
      resolve((payload['threadId'] ?? '').toString()),
    );
    final userId = _toSnowflake(resolve((payload['userId'] ?? '').toString()));
    if (threadId == null || userId == null) {
      return {
        'error': 'threadId and userId are required for threadRemoveMember',
      };
    }

    final channel = await fetchChannelCached(client, threadId);
    if (channel is! Thread) {
      return {'error': 'Provided channel is not a thread'};
    }

    await channel.removeThreadMember(userId);
    return {'threadId': threadId.toString(), 'userId': userId.toString()};
  } catch (e) {
    return {'error': 'Failed to remove thread member: $e'};
  }
}

Future<Map<String, String>> setNicknameAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) async {
  // Résoudre les variables dans le payload si une fonction resolve est fournie
  final resolvedPayload = resolve != null
      ? resolvePayloadValues(payload, resolve)
      : payload;

  final userId = parseSnowflake(resolvedPayload['userId']);
  if (userId == null) {
    return {'error': 'Invalid userId'};
  }

  final permError = await checkBotGuildPermission(
    client,
    guildId: guildId,
    requiredPermissions: [Permissions.manageNicknames],
    actionLabel: 'change nicknames',
  );
  if (permError != null) {
    return {'error': permError};
  }

  final nickname = resolvedPayload['nickname']?.toString() ?? '';
  final reason = resolvedPayload['reason']?.toString();

  try {
    final member = await client.guilds[guildId].members.fetch(userId);
    await member.update(
      MemberUpdateBuilder(nick: nickname),
      auditLogReason: reason,
    );
    return {'userId': userId.toString(), 'nickname': nickname};
  } catch (e) {
    return {'error': 'Failed to set nickname: $e'};
  }
}

Future<Map<String, String>> registerGuildCommandsAction(
  NyxxGateway client, {
  required String botId,
  required BotDataStore store,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
}) async {
  if (guildId == null) {
    return {'error': 'No guildId provided'};
  }

  final commands = await store.getCommands(botId);
  final providedCommandNames =
      (payload['commandNames'] as List<dynamic>?)
          ?.map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList() ??
      [];

  final matchingCommands = commands.where((cmd) {
    final type = cmd['type']?.toString();
    if (type != 'chatInput') return false;

    final rawData = cmd['data'];
    final data = (rawData is Map)
        ? Map<String, dynamic>.from(rawData.cast<String, dynamic>())
        : <String, dynamic>{};

    // Only fetch commands marked as localOnly.
    if (data['legacyLocalOnly'] != true) return false;

    final name = cmd['name']?.toString() ?? '';
    if (providedCommandNames.isNotEmpty) {
      if (!providedCommandNames.contains(name)) return false;
    }
    return true;
  }).toList();

  for (final cmd in matchingCommands) {
    final name = cmd['name']?.toString() ?? '';
    final description =
        cmd['description']?.toString() ?? 'No description provided';

    final rawData = cmd['data'];
    final data = (rawData is Map)
        ? Map<String, dynamic>.from(rawData.cast<String, dynamic>())
        : <String, dynamic>{};

    final optionsRaw = data['options'] as List<dynamic>? ?? [];

    final options = optionsRaw.map((opt) {
      final oMap = (opt is Map<String, dynamic>) ? opt : <String, dynamic>{};
      return CommandOptionBuilder(
        type: CommandOptionType(oMap['type'] as int? ?? 3),
        name: oMap['name']?.toString() ?? '',
        description: oMap['description']?.toString() ?? '',
        isRequired: oMap['required'] == true,
      );
    }).toList();

    try {
      await client.guilds[guildId].commands.create(
        ApplicationCommandBuilder.chatInput(
          name: name,
          description: description,
          options: options,
        ),
      );
    } catch (e) {
      return {'error': 'Failed to register $name: $e'};
    }
  }

  return {'status': 'OK', 'registered': matchingCommands.length.toString()};
}

Future<Map<String, String>> unregisterGuildCommandsAction(
  NyxxGateway client, {
  required String botId,
  required BotDataStore store,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
}) async {
  if (guildId == null) {
    return {'error': 'No guildId provided'};
  }

  final providedCommandNames =
      (payload['commandNames'] as List<dynamic>?)
          ?.map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList() ??
      [];

  try {
    final commandManager = client.guilds[guildId].commands;
    final currentCommands = await commandManager.list();

    int unregisteredCount = 0;

    for (final cmd in currentCommands) {
      if (providedCommandNames.isEmpty ||
          providedCommandNames.contains(cmd.name)) {
        await commandManager.delete(cmd.id);
        unregisteredCount++;
      }
    }

    return {'status': 'OK', 'unregistered': unregisteredCount.toString()};
  } catch (e) {
    return {'error': 'Failed to unregister commands: $e'};
  }
}

/// Updates the bot's own user profile.
///
/// Payload fields:
/// - `username` — new username (optional)
/// - `avatarUrl` — URL to download new avatar from (optional)
/// - `avatarBase64` — base64 image data (optional, used if avatarUrl is empty)
///
/// Returns `{'status': 'updated', 'username', 'userId'}` or `{'error': '...'}`.
Future<Map<String, String>> updateSelfUserAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) async {
  try {
    final username = resolve((payload['username'] ?? '').toString()).trim();
    final avatarUrl = resolve((payload['avatarUrl'] ?? '').toString()).trim();
    final avatarBase64 = resolve(
      (payload['avatarBase64'] ?? '').toString(),
    ).trim();

    if (username.isEmpty && avatarUrl.isEmpty && avatarBase64.isEmpty) {
      return {
        'error':
            'At least one of username, avatarUrl, or avatarBase64 must be provided',
      };
    }

    ImageBuilder? avatar;
    if (avatarBase64.isNotEmpty) {
      avatar = _imageFromBase64(avatarBase64);
    } else if (avatarUrl.isNotEmpty) {
      avatar = await _imageFromUrl(avatarUrl);
    }

    final builder = UserUpdateBuilder(
      username: username.isNotEmpty ? username : null,
      avatar: avatar,
    );

    final user = await client.users.updateCurrentUser(builder);
    return {
      'status': 'updated',
      'username': user.username,
      'userId': user.id.toString(),
    };
  } catch (e) {
    return {'error': 'Failed to update self user: $e'};
  }
}

ImageBuilder? _imageFromBase64(String base64Data) {
  try {
    String raw = base64Data.trim();
    String mime = 'image/png';
    if (raw.startsWith('data:')) {
      final semiColon = raw.indexOf(';');
      final comma = raw.indexOf(',');
      if (semiColon > 0 && comma > semiColon) {
        mime = raw.substring(5, semiColon);
        raw = raw.substring(comma + 1);
      }
    }
    final bytes = base64Decode(raw);
    return ImageBuilder(data: bytes, format: _mimeToFormat(mime));
  } catch (_) {
    return null;
  }
}

Future<ImageBuilder?> _imageFromUrl(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;
    final contentType = response.headers['content-type'] ?? 'image/png';
    return ImageBuilder(
      data: response.bodyBytes,
      format: _mimeToFormat(contentType),
    );
  } catch (_) {
    return null;
  }
}

String _mimeToFormat(String mime) {
  if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpeg';
  if (mime.contains('gif')) return 'gif';
  if (mime.contains('webp')) return 'webp';
  return 'png';
}

/// Deletes a permission overwrite from a channel.
///
/// Payload fields:
/// - `channelId` — channel to edit (required)
/// - `targetId` — user or role ID whose overwrite to delete (ignored when targetType is 'everyone')
/// - `targetType` — 'member', 'role', or 'everyone' (default 'member')
/// - `reason` — audit log reason
///
/// Returns `{'channelId', 'targetId', 'status': 'deleted'}` or `{'error': '...'}`.
Future<Map<String, String>> deleteChannelPermissionAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  required String Function(String) resolve,
}) async {
  try {
    final channelId =
        _toSnowflake(resolve((payload['channelId'] ?? '').toString())) ??
        fallbackChannelId;
    if (channelId == null) {
      return {'error': 'channelId is required for deleteChannelPermission'};
    }

    final targetTypeRaw = resolve(
      (payload['targetType'] ?? 'member').toString(),
    ).trim().toLowerCase();
    final isEveryone = targetTypeRaw == 'everyone';

    final String resolvedTargetId;
    if (isEveryone) {
      resolvedTargetId = resolve('((guild.id))');
    } else {
      resolvedTargetId = resolve((payload['targetId'] ?? '').toString());
    }
    final targetId = _toSnowflake(resolvedTargetId);
    if (targetId == null) {
      return {'error': 'targetId is required for deleteChannelPermission'};
    }

    final channel = await fetchChannelCached(client, channelId);
    if (channel is! GuildChannel) {
      return {'error': 'Channel is not a guild channel'};
    }

    await channel.deletePermissionOverwrite(targetId);

    return {
      'channelId': channelId.toString(),
      'targetId': targetId.toString(),
      'status': 'deleted',
    };
  } catch (e) {
    return {'error': 'Failed to delete channel permission: $e'};
  }
}

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
Future<Map<String, String>> createTicketChannelAction(
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
