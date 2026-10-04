import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'permission_checks.dart';

class SlowmodeChange {
  const SlowmodeChange({
    required this.channelId,
    required this.seconds,
    this.reason,
  });
  final String channelId;
  final int seconds;
  final String? reason;
  void validate() {
    final id = int.tryParse(channelId.trim());
    if (id == null || id <= 0) throw ArgumentError('Invalid channel ID.');
    if (seconds < 0 || seconds > 21600) {
      throw ArgumentError('Slowmode must be between 0 and 21600 seconds.');
    }
  }
}

class ChannelDeletion {
  const ChannelDeletion({required this.channelId, this.reason});
  final String channelId;
  final String? reason;
  void validate() {
    final id = int.tryParse(channelId.trim());
    if (id == null || id <= 0) throw ArgumentError('Invalid channel ID.');
  }
}

class ChannelCreation {
  const ChannelCreation({
    required this.guildId,
    required this.name,
    required this.type,
    this.categoryId,
    this.topic,
    this.isNsfw,
    this.slowmodeSeconds,
    this.reason,
  });
  final String guildId;
  final String name;
  final String type;
  final String? categoryId;
  final String? topic;
  final bool? isNsfw;
  final int? slowmodeSeconds;
  final String? reason;
  void validate() {
    ChannelDeletion(channelId: guildId).validate();
    if (name.trim().isEmpty || name.length > 100) {
      throw ArgumentError('Channel name must contain 1 to 100 characters.');
    }
    if (!const [
      'text',
      'voice',
      'stage',
      'forum',
      'category',
      'announcement',
    ].contains(type)) {
      throw ArgumentError('Unsupported channel type.');
    }
    if (categoryId != null) {
      ChannelDeletion(channelId: categoryId!).validate();
      if (type == 'category') {
        throw ArgumentError('Categories cannot have a parent category.');
      }
    }
    if (topic != null &&
        (!const ['text', 'announcement', 'forum'].contains(type) ||
            topic!.length > (type == 'forum' ? 4096 : 1024))) {
      throw ArgumentError('Topic is unsupported or too long.');
    }
    if (isNsfw != null && type == 'category') {
      throw ArgumentError('NSFW is unsupported for categories.');
    }
    if (slowmodeSeconds != null &&
        (!const ['text', 'voice', 'stage', 'forum'].contains(type) ||
            slowmodeSeconds! < 0 ||
            slowmodeSeconds! > 21600)) {
      throw ArgumentError('Invalid slowmode for this channel type.');
    }
  }
}

class _ChannelCreationBuilder extends GuildChannelBuilder<GuildChannel> {
  _ChannelCreationBuilder(ChannelCreation change)
    : _change = change,
      super(
        name: change.name,
        type: switch (change.type) {
          'text' => ChannelType.guildText,
          'voice' => ChannelType.guildVoice,
          'stage' => ChannelType.guildStageVoice,
          'forum' => ChannelType.guildForum,
          'category' => ChannelType.guildCategory,
          'announcement' => ChannelType.guildAnnouncement,
          _ => throw ArgumentError('Unsupported channel type.'),
        },
      );
  final ChannelCreation _change;
  @override
  Map<String, Object?> build() => {
    ...super.build(),
    if (_change.categoryId != null)
      'parent_id': '${Snowflake.parse(_change.categoryId!.trim())}',
    if (_change.topic != null) 'topic': _change.topic,
    if (_change.isNsfw != null) 'nsfw': _change.isNsfw,
    if (_change.slowmodeSeconds != null)
      'rate_limit_per_user': _change.slowmodeSeconds,
  };
}

Future<GuildChannelBuilder<GuildChannel>> prepareChannelCreation(
  NyxxGateway client,
  ChannelCreation change, {
  required CommandExecutionBudget budget,
}) => budget.run(() async {
  change.validate();
  final guildId = Snowflake.parse(change.guildId.trim());
  final error = await checkBotGuildPermission(
    client,
    guildId: guildId,
    requiredPermissions: [Permissions.manageChannels],
    actionLabel: 'create channels',
    budget: budget,
  );
  if (error != null) throw StateError(error);
  if (change.categoryId != null) {
    final category = await client.channels.fetch(
      Snowflake.parse(change.categoryId!.trim()),
    );
    budget.check();
    if (category is! GuildCategory || category.guildId != guildId) {
      throw ArgumentError('Parent must be a category in the target guild.');
    }
  }
  return _ChannelCreationBuilder(change);
});

class ChannelModification {
  const ChannelModification({
    required this.channelId,
    this.name,
    this.topic,
    this.isNsfw,
    this.position,
    this.categoryId,
    this.slowmodeSeconds,
    this.isArchived,
    this.isLocked,
    this.autoArchiveMinutes,
    this.reason,
  });
  final String channelId;
  final String? name;
  final String? topic;
  final bool? isNsfw;

  /// Discord's zero-based position. BDFD converts its one-based argument.
  final int? position;
  final String? categoryId;
  final int? slowmodeSeconds;
  final bool? isArchived;
  final bool? isLocked;
  final int? autoArchiveMinutes;
  final String? reason;
  void validate() {
    ChannelDeletion(channelId: channelId).validate();
    if (categoryId != null) ChannelDeletion(channelId: categoryId!).validate();
    if (name != null && (name!.isEmpty || name!.length > 100)) {
      throw ArgumentError('Channel name must contain 1 to 100 characters.');
    }
    if (position != null && position! < 0) {
      throw ArgumentError('Invalid channel position.');
    }
    if (slowmodeSeconds != null &&
        (slowmodeSeconds! < 0 || slowmodeSeconds! > 21600)) {
      throw ArgumentError('Slowmode must be between 0 and 21600 seconds.');
    }
    if (autoArchiveMinutes != null &&
        !const [60, 1440, 4320, 10080].contains(autoArchiveMinutes)) {
      throw ArgumentError('Invalid auto archive duration.');
    }
  }
}

/// Shared preparation for Discord transport and fixture simulation.
Future<({GuildChannel channel, UpdateBuilder<Channel> builder})>
prepareChannelUpdate(
  NyxxGateway client,
  ChannelModification change, {
  required CommandExecutionBudget budget,
}) => budget.run(() async {
  change.validate();
  final channel = await client.channels.fetch(
    Snowflake.parse(change.channelId.trim()),
  );
  budget.check();
  if (channel is! GuildChannel) {
    throw StateError('Modification requires a guild channel.');
  }
  final thread = channel is Thread;
  if (thread && channel.isArchived && change.isArchived != false) {
    throw StateError(
      'Cannot modify an archived thread without unarchiving it.',
    );
  }
  if (!thread &&
      (change.isArchived != null ||
          change.isLocked != null ||
          change.autoArchiveMinutes != null)) {
    throw ArgumentError('Archive options require a thread.');
  }
  if (thread &&
      (change.topic != null ||
          change.isNsfw != null ||
          change.position != null ||
          change.categoryId != null)) {
    throw ArgumentError('These fields are unsupported for threads.');
  }
  final hasTopic =
      channel is GuildTextChannel ||
      channel is GuildAnnouncementChannel ||
      channel is ForumChannel;
  if (change.topic != null &&
      (!hasTopic ||
          change.topic!.length > (channel is ForumChannel ? 4096 : 1024))) {
    throw ArgumentError('Topic is unsupported or too long for this channel.');
  }
  final hasNsfw =
      hasTopic || channel is GuildVoiceChannel || channel is GuildStageChannel;
  if (change.isNsfw != null && !hasNsfw) {
    throw ArgumentError('NSFW is unsupported for this channel.');
  }
  if (!hasNsfw && change.categoryId != null) {
    throw ArgumentError('Parent category is unsupported for this channel.');
  }
  if (change.slowmodeSeconds != null &&
      !(thread ||
          channel is GuildTextChannel ||
          channel is ForumChannel ||
          channel is GuildVoiceChannel ||
          channel is GuildStageChannel)) {
    throw ArgumentError('Slowmode is unsupported for this channel.');
  }
  final error = await checkBotChannelPermission(
    client,
    channel: channel,
    requiredPermissions: [
      Permissions.manageChannels,
      if (thread) Permissions.manageThreads,
      if (channel is GuildVoiceChannel || channel is GuildStageChannel)
        Permissions.connect,
    ],
    actionLabel: 'modify channels',
    budget: budget,
  );
  if (error != null) throw StateError(error);
  final parent = change.categoryId == null
      ? null
      : Snowflake.parse(change.categoryId!.trim());
  if (parent != null) {
    final category = await client.channels.fetch(parent);
    budget.check();
    if (category is! GuildCategory || category.guildId != channel.guildId) {
      throw ArgumentError('Parent must be a category in the target guild.');
    }
  }
  final rate = change.slowmodeSeconds == null
      ? null
      : Duration(seconds: change.slowmodeSeconds!);
  final UpdateBuilder<Channel> builder = switch (channel) {
    Thread _ => ThreadUpdateBuilder(
      name: change.name,
      isArchived: change.isArchived,
      isLocked: change.isLocked,
      autoArchiveDuration: change.autoArchiveMinutes == null
          ? null
          : Duration(minutes: change.autoArchiveMinutes!),
      rateLimitPerUser: rate,
    ),
    GuildTextChannel _ => GuildTextChannelUpdateBuilder(
      name: change.name,
      topic: change.topic,
      isNsfw: change.isNsfw,
      position: change.position,
      parentId: parent,
      rateLimitPerUser: rate,
    ),
    GuildAnnouncementChannel _ => GuildTextChannelUpdateBuilder(
      name: change.name,
      topic: change.topic,
      isNsfw: change.isNsfw,
      position: change.position,
      parentId: parent,
      rateLimitPerUser: rate,
    ),
    ForumChannel _ => ForumChannelUpdateBuilder(
      name: change.name,
      topic: change.topic,
      isNsfw: change.isNsfw,
      position: change.position,
      parentId: parent,
      rateLimitPerUser: rate,
    ),
    GuildVoiceChannel _ => GuildVoiceChannelUpdateBuilder(
      name: change.name,
      isNsfw: change.isNsfw,
      position: change.position,
      parentId: parent,
    ),
    GuildStageChannel _ => GuildStageChannelUpdateBuilder(
      name: change.name,
      isNsfw: change.isNsfw,
      position: change.position,
      parentId: parent,
    ),
    GuildCategory _ => GuildCategoryUpdateBuilder(
      name: change.name,
      position: change.position,
    ),
    _ => GuildChannelUpdateBuilder<GuildChannel>(
      name: change.name,
      position: change.position,
    ),
  };
  final patch = <String, Object?>{
    if ((channel is GuildVoiceChannel || channel is GuildStageChannel) &&
        rate != null)
      'rate_limit_per_user': rate.inSeconds,
  };
  return (channel: channel, builder: _ChannelPatchBuilder(builder, patch));
});

class _ChannelPatchBuilder extends UpdateBuilder<Channel> {
  const _ChannelPatchBuilder(this.base, this.patch);
  final UpdateBuilder<Channel> base;
  final Map<String, Object?> patch;
  @override
  Map<String, Object?> build() => {
    for (final entry in base.build().entries)
      if (entry.value != null) entry.key: entry.value,
    ...patch,
  };
}

abstract interface class BotChannelMutationService {
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  });
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  });
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  });
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  });
}

class DiscordBotChannelMutationService implements BotChannelMutationService {
  const DiscordBotChannelMutationService(this.client);
  final NyxxGateway client;
  @override
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final builder = await prepareChannelCreation(
      client,
      change,
      budget: budget,
    );
    budget.check();
    final channel = await client.guilds.createGuildChannel(
      Snowflake.parse(change.guildId.trim()),
      builder,
      auditLogReason: change.reason,
    );
    budget.check();
    return '${channel.id}';
  });
  @override
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareChannelUpdate(client, change, budget: budget);
    if (prepared.builder.build().isEmpty) return;
    budget.check();
    await client.channels.update(
      prepared.channel.id,
      prepared.builder,
      auditLogReason: change.reason,
    );
    budget.check();
  });
  @override
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final id = Snowflake.parse(change.channelId.trim());
    final channel = await client.channels.fetch(id);
    budget.check();
    if (channel is! GuildChannel) {
      throw StateError('Channel deletion requires a guild channel.');
    }
    final error = await checkBotChannelPermission(
      client,
      channel: channel,
      requiredPermissions: [
        Permissions.manageChannels,
        if (channel is Thread) Permissions.manageThreads,
      ],
      actionLabel: 'delete channels',
      budget: budget,
    );
    if (error != null) throw StateError(error);
    budget.check();
    await client.channels.delete(id, auditLogReason: change.reason);
    budget.check();
  });
  @override
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final id = Snowflake.parse(change.channelId.trim());
    final channel = await client.channels.fetch(id);
    budget.check();
    if (channel is! GuildChannel) {
      throw StateError('Slowmode requires a guild channel.');
    }
    if (channel is Thread && channel.isArchived) {
      throw StateError('Cannot change slowmode on an archived thread.');
    }
    final duration = Duration(seconds: change.seconds);
    final UpdateBuilder<Channel> builder = switch (channel) {
      GuildTextChannel _ => GuildTextChannelUpdateBuilder(
        rateLimitPerUser: duration,
      ),
      // The announcement builder lacks this field. This PATCH sends no type.
      GuildAnnouncementChannel _ => GuildTextChannelUpdateBuilder(
        rateLimitPerUser: duration,
      ),
      ForumChannel _ => ForumChannelUpdateBuilder(rateLimitPerUser: duration),
      Thread _ => ThreadUpdateBuilder(rateLimitPerUser: duration),
      _ => throw StateError('Slowmode is unsupported for this channel type.'),
    };
    final error = await checkBotChannelPermission(
      client,
      channel: channel,
      requiredPermissions: [
        Permissions.manageChannels,
        if (channel is Thread) Permissions.manageThreads,
      ],
      actionLabel: 'set slowmode',
      budget: budget,
    );
    if (error != null) throw StateError(error);
    budget.check();
    await client.channels.update(id, builder, auditLogReason: change.reason);
    budget.check();
  });
}
