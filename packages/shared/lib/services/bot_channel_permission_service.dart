import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'permission_checks.dart';

class ChannelPermissionChange {
  const ChannelPermissionChange({
    required this.channelId,
    this.targetId,
    this.targetType = 'auto',
    required this.allow,
    required this.deny,
    this.neutral = 0,
    this.replace = false,
  });
  final String channelId;
  final String? targetId;
  final String targetType;
  final int allow;
  final int deny;
  final int neutral;
  final bool replace;
  void validate() {
    void id(String value) {
      final parsed = int.tryParse(value.trim());
      if (parsed == null || parsed <= 0) {
        throw ArgumentError('Invalid Discord ID.');
      }
    }

    id(channelId);
    if (!const ['auto', 'member', 'role', 'everyone'].contains(targetType)) {
      throw ArgumentError('Invalid permission target type.');
    }
    if (targetType != 'everyone') {
      if (targetId == null) {
        throw ArgumentError('Permission target is required.');
      }
      id(targetId!);
    }
    if (allow < 0 ||
        deny < 0 ||
        neutral < 0 ||
        (allow & deny) != 0 ||
        (allow & neutral) != 0 ||
        (deny & neutral) != 0) {
      throw ArgumentError('Invalid permission masks.');
    }
  }
}

class ChannelPermissionResult {
  const ChannelPermissionResult(this.channelId, this.targetId);
  final String channelId;
  final String targetId;
}

abstract interface class BotChannelPermissionService {
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  });
}

/// Prepare exactly one overwrite, preserving untouched flags for native edits.
Future<({GuildChannel channel, PermissionOverwriteBuilder builder})>
prepareChannelPermissions(
  NyxxGateway client,
  ChannelPermissionChange change, {
  required CommandExecutionBudget budget,
}) => budget.run(() async {
  change.validate();
  final channel = await client.channels.fetch(
    Snowflake.parse(change.channelId.trim()),
  );
  budget.check();
  if (channel is! GuildChannel || channel is Thread) {
    throw StateError('Overwrites require a non-thread guild channel.');
  }
  final error = await checkBotChannelPermission(
    client,
    channel: channel,
    requiredPermissions: [
      Permissions.manageRoles,
      if (channel is GuildVoiceChannel || channel is GuildStageChannel)
        Permissions.connect,
    ],
    actionLabel: 'edit channel permissions',
    budget: budget,
  );
  if (error != null) throw StateError(error);
  final target = change.targetType == 'everyone'
      ? channel.guildId
      : Snowflake.parse(change.targetId!.trim());
  if (target == channel.guildId && change.targetType == 'member') {
    throw ArgumentError(
      'The guild ID identifies the everyone role, not a member.',
    );
  }
  var type = PermissionOverwriteType.role;
  if (target != channel.guildId) {
    if (change.targetType == 'member') {
      type = PermissionOverwriteType.member;
    } else {
      final roles = await client.guilds[channel.guildId].roles.list();
      budget.check();
      final isRole = roles.any((role) => role.id == target);
      if (!isRole && change.targetType == 'role') {
        throw StateError('Role not found in the target guild.');
      }
      type = isRole
          ? PermissionOverwriteType.role
          : PermissionOverwriteType.member;
    }
    if (type == PermissionOverwriteType.member) {
      await client.guilds[channel.guildId].members.fetch(target);
      budget.check();
    }
  }
  var allow = change.allow;
  var deny = change.deny;
  if (!change.replace) {
    final existing = channel.permissionOverwrites
        .where((o) => o.id == target && o.type == type)
        .firstOrNull;
    final touched = change.allow | change.deny | change.neutral;
    allow |= (existing?.allow.value ?? 0) & ~touched;
    deny |= (existing?.deny.value ?? 0) & ~touched;
  }
  return (
    channel: channel,
    builder: PermissionOverwriteBuilder(
      id: target,
      type: type,
      allow: Permissions(allow),
      deny: Permissions(deny),
    ),
  );
});

class DiscordBotChannelPermissionService
    implements BotChannelPermissionService {
  const DiscordBotChannelPermissionService(this.client);
  final NyxxGateway client;
  @override
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareChannelPermissions(
      client,
      change,
      budget: budget,
    );
    budget.check();
    await client.channels.updatePermissionOverwrite(
      prepared.channel.id,
      prepared.builder,
    );
    budget.check();
    return ChannelPermissionResult(
      '${prepared.channel.id}',
      '${prepared.builder.id}',
    );
  });
}
