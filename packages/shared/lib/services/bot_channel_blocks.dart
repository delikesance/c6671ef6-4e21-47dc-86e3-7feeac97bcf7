import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import '../utils/bdfd_duration_parser.dart';
import '../utils/permission_flags.dart'
    show computeAllowBitmask, computeDenyBitmask;
import 'bot_channel_mutation_service.dart';
import 'bot_channel_permission_service.dart';

// Payload-to-request of the channel blocks (createChannel, updateChannel,
// removeChannel, slowmode, editChannelPermissions), shared by the native
// `bc_*` handlers (engine/bdfd/visual/channel_actions.dart) and by the
// gateway-bound entry points below. Each `...With` variant takes the service,
// so the native engine runs them over the execution's own service. Results are
// the block's maps (`{'error': ...}` on failure).

bool? _toBoolStrict(dynamic value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true') {
    return true;
  }
  if (text == 'false') {
    return false;
  }
  return null;
}

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

bool? _toBool(dynamic value) {
  if (value is bool) {
    return value;
  }
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes' || text == 'y') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no' || text == 'n') {
    return false;
  }
  return null;
}

Duration? _parseDuration(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return Duration(seconds: value.toInt());
  }

  final text = value.toString().trim();
  if (text.isEmpty) {
    return null;
  }

  final asInt = int.tryParse(text);
  if (asInt != null) {
    return Duration(seconds: asInt);
  }

  final match = RegExp(r'^(\d+)\s*([smhd])$').firstMatch(text.toLowerCase());
  if (match == null) {
    return null;
  }

  final amount = int.parse(match.group(1)!);
  final unit = match.group(2)!;
  switch (unit) {
    case 's':
      return Duration(seconds: amount);
    case 'm':
      return Duration(minutes: amount);
    case 'h':
      return Duration(hours: amount);
    case 'd':
      return Duration(days: amount);
    default:
      return null;
  }
}

ChannelType _channelTypeFromRaw(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'voice':
      return ChannelType.guildVoice;
    case 'announcement':
      return ChannelType.guildAnnouncement;
    case 'stage':
      return ChannelType.guildStageVoice;
    case 'forum':
      return ChannelType.guildForum;
    case 'category':
      return ChannelType.guildCategory;
    case 'text':
    default:
      return ChannelType.guildText;
  }
}

String _typeName(ChannelType type) => switch (type) {
  ChannelType.guildText => 'text',
  ChannelType.guildVoice => 'voice',
  ChannelType.guildStageVoice => 'stage',
  ChannelType.guildForum => 'forum',
  ChannelType.guildCategory => 'category',
  ChannelType.guildAnnouncement => 'announcement',
  _ => throw ArgumentError('Unsupported channel type.'),
};

Future<Map<String, String>> createChannel(
  NyxxGateway client,
  String name, {
  required Snowflake guildId,
  ChannelType type = ChannelType.guildText,
  CommandExecutionBudget? budget,
}) async {
  try {
    final id = await DiscordBotChannelMutationService(client).createChannel(
      ChannelCreation(guildId: '$guildId', name: name, type: _typeName(type)),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': id};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to create channel: $error', 'channelId': ''};
  }
}

Future<Map<String, String>> createChannelAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) => createChannelActionWith(
  DiscordBotChannelMutationService(client),
  guildId: '$guildId',
  payload: payload,
  resolve: resolve,
  budget: budget,
);

/// [createChannelAction] over any [BotChannelMutationService]: the historical
/// executor passes the Discord adapter, the native `bc_createChannel` the
/// execution's own service.
Future<Map<String, String>> createChannelActionWith(
  BotChannelMutationService service, {
  required String guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) async {
  final name = resolve((payload['name'] ?? '').toString()).trim();
  final type = _typeName(
    _channelTypeFromRaw(resolve((payload['type'] ?? 'text').toString())),
  );
  final category = resolve((payload['categoryId'] ?? '').toString()).trim();
  final topic = resolve((payload['topic'] ?? '').toString()).trim();
  final slowmode = _parseDuration(
    resolve((payload['slowmode'] ?? '').toString()),
  );
  final nsfw = _toBool(resolve((payload['nsfw'] ?? '').toString()));
  final reason = resolve((payload['reason'] ?? '').toString());
  try {
    final id = await service.createChannel(
      ChannelCreation(
        guildId: guildId,
        name: name,
        type: type,
        categoryId: category.isEmpty || type == 'category' ? null : category,
        topic:
            topic.isEmpty ||
                !const ['text', 'forum', 'announcement'].contains(type)
            ? null
            : topic,
        isNsfw: type == 'category' ? null : nsfw,
        slowmodeSeconds:
            const ['text', 'forum', 'voice', 'stage'].contains(type)
            ? slowmode?.inSeconds
            : null,
        reason: reason.isEmpty ? null : reason,
      ),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': id};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to create channel: $error', 'channelId': ''};
  }
}

int? _parseArchiveMinutes(dynamic value) {
  if (value == null) {
    return null;
  }
  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == '!unchanged') {
    return null;
  }
  final parsed = int.tryParse(text);
  if (parsed == null) {
    return null;
  }
  const allowed = <int>[60, 1440, 4320, 10080];
  return allowed.reduce(
    (prev, curr) => (curr - parsed).abs() < (prev - parsed).abs() ? curr : prev,
  );
}

Future<Map<String, String>> updateChannelAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => updateChannelActionWith(
  DiscordBotChannelMutationService(client),
  payload: payload,
  resolve: resolve,
  budget: budget,
);

/// [updateChannelAction] over any [BotChannelMutationService].
Future<Map<String, String>> updateChannelActionWith(
  BotChannelMutationService service, {
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) async {
  resolve ??= (s) => s;
  try {
    String value(String key) => resolve!((payload[key] ?? '').toString());
    final channelId = value('channelId').trim();
    final name = value('name').trim();
    final topic = value('topic');
    final nsfw = _toBoolStrict(value('nsfw'));
    final position = int.tryParse(value('position'));
    final category = _toSnowflake(value('categoryId'));
    final slowmode = _parseDuration(value('slowmode'));
    final archived = _toBoolStrict(value('archived'));
    final locked = _toBoolStrict(value('locked'));
    final archiveMinutes = _parseArchiveMinutes(value('autoArchiveDuration'));
    final reason = value('reason');
    await service.modifyChannel(
      ChannelModification(
        channelId: channelId,
        name: name.isEmpty || name == '!unchanged' ? null : name,
        topic: topic.isEmpty || topic == '!unchanged' ? null : topic,
        isNsfw: nsfw,
        position: position,
        categoryId: category?.toString(),
        slowmodeSeconds: slowmode?.inSeconds,
        isArchived: archived,
        isLocked: locked,
        autoArchiveMinutes: archiveMinutes,
        reason: reason.isEmpty ? null : reason,
      ),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': '${int.parse(channelId)}', 'status': 'updated'};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to update channel: $error', 'channelId': ''};
  }
}

Future<Map<String, String>> removeChannel(
  NyxxGateway client,
  Snowflake channelId, {
  CommandExecutionBudget? budget,
  String? reason,
}) => removeChannelWith(
  DiscordBotChannelMutationService(client),
  channelId,
  budget: budget,
  reason: reason,
);

/// [removeChannel] over any [BotChannelMutationService].
Future<Map<String, String>> removeChannelWith(
  BotChannelMutationService service,
  Snowflake channelId, {
  CommandExecutionBudget? budget,
  String? reason,
}) async {
  try {
    await service.deleteChannel(
      ChannelDeletion(channelId: '$channelId', reason: reason),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {'channelId': '$channelId'};
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to delete channel: $error', 'channelId': ''};
  }
}

Future<Map<String, String>> slowmodeAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) => slowmodeActionWith(
  DiscordBotChannelMutationService(client),
  payload: payload,
  resolve: resolve,
  budget: budget,
);

/// [slowmodeAction] over any [BotChannelMutationService].
Future<Map<String, String>> slowmodeActionWith(
  BotChannelMutationService service, {
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) async {
  final id = resolve(payload['channelId']?.toString() ?? '');
  final duration = parseBdfdDuration(
    resolve(payload['duration']?.toString() ?? '0s'),
  );
  final reason = resolve(payload['reason']?.toString() ?? '');
  if (duration == null ||
      duration.isNegative ||
      duration > const Duration(hours: 6)) {
    return {'error': 'Slowmode duration must be between 0 and 6 hours'};
  }
  try {
    final change = SlowmodeChange(
      channelId: id,
      seconds: duration.inSeconds,
      reason: reason.isEmpty ? null : reason,
    );
    await service.setSlowmode(
      change,
      budget: budget ?? CommandExecutionBudget(),
    );
    return {
      'channelId': '${int.parse(id.trim())}',
      'duration': '${change.seconds}',
    };
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to set slowmode: $error'};
  }
}

/// Resolve allow/deny bitmasks from a payload.
///
/// Supports both the new [permissionFlags] map format and the legacy
/// integer-string format. Returns (allow, deny) as [Permissions].
(Permissions, Permissions) _resolvePermissionBitmasks(
  Map<String, dynamic> payload,
  String Function(String) resolve,
) {
  // New format: 'permissions' Map<String, String>
  final permStates = payload['permissions'];
  if (permStates is Map && permStates.isNotEmpty) {
    final allowKeys = <String>{};
    final denyKeys = <String>{};
    permStates.forEach((key, value) {
      final state = resolve(value.toString());
      if (state == 'allow') {
        allowKeys.add(key.toString());
      } else if (state == 'deny') {
        denyKeys.add(key.toString());
      }
    });
    return (
      Permissions(computeAllowBitmask(allowKeys)),
      Permissions(computeDenyBitmask(denyKeys)),
    );
  }

  // Legacy format: 'allow' and 'deny' as integer strings
  final allowRaw =
      int.tryParse(resolve((payload['allow'] ?? '0').toString())) ?? 0;
  final denyRaw =
      int.tryParse(resolve((payload['deny'] ?? '0').toString())) ?? 0;
  return (Permissions(allowRaw), Permissions(denyRaw));
}

/// Edits a permission overwrite for a channel.
///
/// Payload fields:
/// - `channelId` — channel to edit (required)
/// - `targetId` — user or role ID (required, ignored when targetType is 'everyone')
/// - `targetType` — 'member', 'role', or 'everyone' (default 'member')
/// - `allow` — permissions bitmask to allow (as string integer, default '0')
/// - `deny` — permissions bitmask to deny (as string integer, default '0')
/// - `permissions` — (new format) Map of permission key → 'allow'/'deny'/'unset'
/// - `reason` — audit log reason
///
/// Returns `{'channelId', 'targetId', 'status': 'updated'}` or `{'error': '...'}`.
Future<Map<String, String>> editChannelPermissionsAction(
  NyxxGateway client, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) => editChannelPermissionsActionWith(
  DiscordBotChannelPermissionService(client),
  payload: payload,
  fallbackChannelId: fallbackChannelId,
  resolve: resolve,
  budget: budget,
);

/// [editChannelPermissionsAction] over any [BotChannelPermissionService].
Future<Map<String, String>> editChannelPermissionsActionWith(
  BotChannelPermissionService service, {
  required Map<String, dynamic> payload,
  Snowflake? fallbackChannelId,
  required String Function(String) resolve,
  CommandExecutionBudget? budget,
}) async {
  try {
    final rawChannel = resolve((payload['channelId'] ?? '').toString()).trim();
    final channel = rawChannel.isEmpty
        ? fallbackChannelId?.toString() ?? ''
        : rawChannel;
    var targetType = resolve(
      (payload['targetType'] ?? 'member').toString(),
    ).trim().toLowerCase();
    if (targetType == 'user') targetType = 'member';
    final targetId = targetType == 'everyone'
        ? null
        : resolve((payload['targetId'] ?? '').toString()).trim();
    final masks = _resolvePermissionBitmasks(payload, resolve);
    final result = await service.editPermissions(
      ChannelPermissionChange(
        channelId: channel,
        targetId: targetId,
        targetType: targetType,
        allow: masks.$1.value,
        deny: masks.$2.value,
        replace: true,
      ),
      budget: budget ?? CommandExecutionBudget(),
    );
    return {
      'channelId': result.channelId,
      'targetId': result.targetId,
      'status': 'updated',
    };
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to edit channel permissions: $error'};
  }
}
