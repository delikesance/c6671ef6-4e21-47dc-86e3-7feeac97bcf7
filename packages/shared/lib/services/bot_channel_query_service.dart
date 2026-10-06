import 'package:nyxx/nyxx.dart';
import '../engine/discord_entity_fetcher.dart' show DiscordEntityNotFound;
import '../engine/execution_budget.dart';

class BotChannel {
  const BotChannel({
    required this.id,
    required this.name,
    required this.type,
    this.topic = '',
    this.isNsfw = false,
    this.guildId,
    this.parentId,
    this.position,
    this.slowmodeSeconds = 0,
  });
  final String id;
  final String name;
  final String type;
  final String topic;
  final bool isNsfw;
  final String? guildId;
  final String? parentId;
  final int? position;
  final int slowmodeSeconds;
}

class BotGuildChannelSettings {
  const BotGuildChannelSettings({this.afkId, this.rulesId, this.systemId});
  final String? afkId;
  final String? rulesId;
  final String? systemId;
}

abstract interface class BotChannelQueryService {
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<int> countChannels({required CommandExecutionBudget budget});
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  });
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  });
}

Future<List<GuildChannel>> readDiscordChannels(
  NyxxGateway client,
  Snowflake guild,
) => client.guilds[guild].fetchChannels();

class DiscordBotChannelQueryService implements BotChannelQueryService {
  const DiscordBotChannelQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;
  @override
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final selected = guildId == null ? this.guildId : _id(guildId);
    if (selected == null) {
      throw StateError('Guild channel settings require a guild.');
    }
    final guild = await client.guilds.fetch(selected);
    budget.check();
    return BotGuildChannelSettings(
      afkId: guild.afkChannelId?.toString(),
      rulesId: guild.rulesChannelId?.toString(),
      systemId: guild.systemChannelId?.toString(),
    );
  });
  @override
  Future<int> countChannels({required CommandExecutionBudget budget}) =>
      budget.run(() async {
        final guild = guildId;
        if (guild == null) throw StateError('Channel count requires a guild.');
        final channels = await readDiscordChannels(client, guild);
        budget.check();
        final ids = channels.map((c) => c.id).toSet();
        final forums = channels
            .where((c) => c.type == ChannelType.guildForum)
            .map((c) => c.id)
            .toSet();
        if (forums.isEmpty) return ids.length;
        final active = await client.guilds[guild].listActiveThreads();
        budget.check();
        ids.addAll(
          active.threads
              .where((t) => !t.isArchived && forums.contains(t.parentId))
              .map((t) => t.id),
        );
        return ids.length;
      });
  Snowflake _id(String id) {
    final parsed = int.tryParse(id.trim());
    if (parsed == null || parsed <= 0) {
      throw ArgumentError('Invalid Discord ID.');
    }
    return Snowflake(parsed);
  }

  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    try {
      final result = await client.channels.fetch(_id(id));
      budget.check();
      return _snapshot(result);
    } on DiscordEntityNotFound {
      return null;
    } on HttpResponseError catch (error) {
      if (error.statusCode == 404 && error.errorCode == 10003) return null;
      rethrow;
    }
  });

  @override
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final guild = guildId == null ? this.guildId : _id(guildId);
    if (guild == null) throw StateError('Channel lookup requires a guild.');
    final result = await readDiscordChannels(client, guild);
    budget.check();
    final values = {for (final c in result) '${c.id}': _snapshot(c)};
    if (includeActiveThreads) {
      final active = await client.guilds[guild].listActiveThreads();
      budget.check();
      for (final thread in active.threads.where((t) => !t.isArchived)) {
        values['${thread.id}'] = _snapshot(thread);
      }
    }
    return List.unmodifiable(values.values);
  });
}

BotChannel _snapshot(Channel channel) => BotChannel(
  id: '${channel.id}',
  guildId: channel is GuildChannel ? '${channel.guildId}' : null,
  parentId: channel is GuildChannel ? channel.parentId?.toString() : null,
  position: channel is GuildChannel ? channel.position : null,
  name: channel is GuildChannel ? channel.name : 'DM',
  type: switch (channel.type.value) {
    0 => 'text',
    1 || 3 => 'dm',
    2 => 'voice',
    4 => 'category',
    5 => 'announcement',
    10 || 11 || 12 => 'thread',
    13 => 'stage',
    15 => 'forum',
    16 => 'media',
    _ => 'unknown',
  },
  topic: switch (channel) {
    GuildTextChannel c => c.topic ?? '',
    GuildAnnouncementChannel c => c.topic ?? '',
    ThreadsOnlyChannel c => c.topic ?? '',
    _ => '',
  },
  slowmodeSeconds: switch (channel) {
    TextChannel c => c.rateLimitPerUser?.inSeconds ?? 0,
    ThreadsOnlyChannel c => c.rateLimitPerUser?.inSeconds ?? 0,
    _ => 0,
  },
  isNsfw: channel is GuildChannel && channel.isNsfw,
);
