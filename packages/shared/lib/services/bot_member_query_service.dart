import 'package:nyxx/nyxx.dart';

import '../engine/execution_budget.dart';

class BotGuildMember {
  const BotGuildMember({
    required this.id,
    required this.username,
    this.nickname,
    this.isBot = false,
    this.roleIds = const [],
    this.premiumSince,
    this.communicationDisabledUntil,
  });
  final String id;
  final String username;
  final String? nickname;
  final bool isBot;
  final List<String> roleIds;
  final DateTime? premiumSince;
  final DateTime? communicationDisabledUntil;
}

abstract interface class BotMemberQueryService {
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<int> allGuildMembersCount({required CommandExecutionBudget budget});
}

class DiscordBotMemberQueryService implements BotMemberQueryService {
  const DiscordBotMemberQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;

  Snowflake _id(String raw, String kind) {
    final value = raw.trim();
    final number = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (number == null || number <= 0) throw ArgumentError('Invalid $kind ID.');
    return Snowflake(number);
  }

  Snowflake _guild(String? raw) => raw == null
      ? guildId ?? (throw StateError('Member lookup requires a guild.'))
      : _id(raw, 'guild');

  Future<BotGuildMember> _member(
    Member value,
    CommandExecutionBudget budget,
  ) async {
    final user = value.user ?? await client.users.fetch(value.id);
    budget.check();
    return BotGuildMember(
      id: '${value.id}',
      username: user.username,
      nickname: value.nick,
      isBot: user.isBot,
      roleIds: List.unmodifiable(value.roleIds.map((id) => '$id')),
      premiumSince: value.premiumSince,
      communicationDisabledUntil: value.communicationDisabledUntil,
    );
  }

  @override
  Future<BotGuildMember?> guildMember(
    String userId, {
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final id = _id(userId, 'user');
    final selectedGuild = _guild(guildId);
    Member member;
    try {
      member = await client.guilds[selectedGuild].members.fetch(id);
    } on HttpResponseError catch (error) {
      budget.check();
      if (error.statusCode == 404 && error.errorCode == 10007) return null;
      rethrow;
    }
    budget.check();
    return _member(member, budget);
  });

  @override
  Future<List<BotGuildMember>> guildMembers({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final selectedGuild = _guild(guildId);
    final manager = client.guilds[selectedGuild].members;
    final found = <Snowflake, BotGuildMember>{};
    Snowflake? after;
    while (true) {
      budget.check();
      final page = await manager.list(limit: 1000, after: after);
      budget.check();
      if (page.isEmpty) break;
      var last = page.first.id;
      for (final member in page) {
        budget.check();
        if (member.id.value > last.value) last = member.id;
        found[member.id] = await _member(member, budget);
      }
      if (after != null && last.value <= after.value) {
        throw StateError('Discord member pagination did not advance.');
      }
      if (page.length < 1000) break;
      after = last;
    }
    return List.unmodifiable(found.values);
  });

  @override
  Future<int> allGuildMembersCount({required CommandExecutionBudget budget}) =>
      budget.run(() async {
        final guilds = <Snowflake>{};
        Snowflake? after;
        while (true) {
          budget.check();
          final page = await client.users.listCurrentUserGuilds(
            limit: 200,
            after: after,
          );
          budget.check();
          if (page.isEmpty) break;
          var last = page.first.id;
          for (final guild in page) {
            budget.check();
            guilds.add(guild.id);
            if (guild.id.value > last.value) last = guild.id;
          }
          if (after != null && last.value <= after.value) {
            throw StateError('Discord guild pagination did not advance.');
          }
          if (page.length < 200) break;
          after = last;
        }
        var count = 0;
        for (final guild in guilds) {
          budget.check();
          count += (await guildMembers(
            guildId: '$guild',
            budget: budget,
          )).length;
        }
        return count;
      });
}
