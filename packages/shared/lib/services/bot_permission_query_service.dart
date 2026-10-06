import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'permission_checks.dart' show applyChannelOverwrites;

/// Computed flags and restrictions, independent from scripts and block payloads.
class BotMemberPermissions {
  const BotMemberPermissions(
    this.mask, {
    this.privileged = false,
    this.inChannel = false,
    this.inVoiceChannel = false,
    this.inThread = false,
  });
  final int mask;
  final bool privileged;
  final bool inChannel;
  final bool inVoiceChannel;
  final bool inThread;

  bool hasAll(Iterable<int> required) {
    if (privileged) return true;
    bool has(int flag) => (mask & flag) == flag;
    final flags = required.toList();
    if (!flags.every(has)) return false;
    if (flags.isEmpty || !inChannel) return true;
    if (!has(Permissions.viewChannel.value)) return false;
    final send = inThread
        ? Permissions.sendMessagesInThreads.value
        : Permissions.sendMessages.value;
    final dependsOnSend = {
      Permissions.mentionEveryone.value,
      Permissions.sendTtsMessages.value,
      Permissions.attachFiles.value,
      Permissions.embedLinks.value,
    };
    if (!has(send) && flags.any(dependsOnSend.contains)) return false;
    final dependsOnConnect = {
      Permissions.manageChannels.value,
      Permissions.manageRoles.value,
      Permissions.prioritySpeaker.value,
      Permissions.stream.value,
      Permissions.speak.value,
      Permissions.muteMembers.value,
      Permissions.deafenMembers.value,
      Permissions.moveMembers.value,
      Permissions.useVad.value,
      Permissions.requestToSpeak.value,
      Permissions.useSoundboard.value,
      Permissions.useExternalSounds.value,
      Permissions.setVoiceChannelStatus.value,
    };
    return !inVoiceChannel ||
        has(Permissions.connect.value) ||
        !flags.any(dependsOnConnect.contains);
  }
}

abstract interface class BotPermissionQueryService {
  /// Stored guild role flags, without expanding owner/admin or applying timeout.
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  });

  /// Null user selects the bot. Null channel selects the current guild.
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  });
}

class DiscordBotPermissionQueryService implements BotPermissionQueryService {
  const DiscordBotPermissionQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;

  Future<({Member member, int mask})> _memberRoles(
    Snowflake guild,
    Snowflake user,
    CommandExecutionBudget budget,
  ) async {
    final member = await client.guilds[guild].members.fetch(user);
    budget.check();
    final roles = await client.guilds[guild].roles.list();
    budget.check();
    final roleIds = member.roleIds.toSet()..add(guild);
    final mask = roles
        .where((role) => roleIds.contains(role.id))
        .fold<int>(0, (value, role) => value | role.permissions.value);
    return (member: member, mask: mask);
  }

  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final id = int.tryParse(userId.trim());
    if (id == null || id <= 0) throw ArgumentError('Invalid Discord ID.');
    final guild = guildId;
    if (guild == null) throw StateError('Permission lookup requires a guild.');
    return (await _memberRoles(guild, Snowflake(id), budget)).mask;
  });

  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    Snowflake parse(String value) {
      final id = int.tryParse(value.trim());
      if (id == null || id <= 0) throw ArgumentError('Invalid Discord ID.');
      return Snowflake(id);
    }

    final user = userId == null ? client.user.id : parse(userId);
    final channelSnowflake = channelId == null ? null : parse(channelId);
    GuildChannel? channel;
    if (channelSnowflake != null) {
      final fetched = await client.channels.fetch(channelSnowflake);
      budget.check();
      if (fetched is! GuildChannel) {
        throw StateError('Channel permissions require a guild channel.');
      }
      channel = fetched;
    }
    final selectedGuild = channel?.guildId ?? guildId;
    if (selectedGuild == null) {
      throw StateError('Permission lookup requires a guild.');
    }
    final guild = await client.guilds.fetch(selectedGuild);
    budget.check();
    if (guild.ownerId == user) {
      return const BotMemberPermissions(0, privileged: true);
    }
    final stored = await _memberRoles(selectedGuild, user, budget);
    final member = stored.member;
    final roleIds = member.roleIds.toSet()..add(selectedGuild);
    var mask = stored.mask;
    if ((mask & Permissions.administrator.value) != 0) {
      return BotMemberPermissions(mask, privileged: true);
    }
    if (channel != null) {
      Iterable<PermissionOverwrite> overwrites;
      if (channel is Thread) {
        final parentId = channel.parentId;
        if (parentId == null) throw StateError('Thread parent is missing.');
        final parent = await client.channels.fetch(parentId);
        budget.check();
        if (parent is! GuildChannel ||
            parent is Thread ||
            parent.guildId != selectedGuild) {
          throw StateError('Thread parent is invalid.');
        }
        overwrites = parent.permissionOverwrites;
      } else {
        overwrites = channel.permissionOverwrites;
      }
      mask = applyChannelOverwrites(
        base: Permissions(mask),
        guildId: selectedGuild,
        memberId: user,
        roleIds: roleIds,
        overwrites: overwrites,
      ).value;
    }
    final timeout = member.communicationDisabledUntil;
    if (timeout != null && timeout.isAfter(DateTime.now().toUtc())) {
      mask &=
          Permissions.viewChannel.value | Permissions.readMessageHistory.value;
    }
    return BotMemberPermissions(
      mask,
      inChannel: channel != null,
      inVoiceChannel:
          channel is GuildVoiceChannel || channel is GuildStageChannel,
      inThread: channel is Thread,
    );
  });
}
