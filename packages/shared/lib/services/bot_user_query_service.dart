import 'package:nyxx/nyxx.dart';

import '../engine/execution_budget.dart';

class BotUser {
  const BotUser({
    required this.id,
    required this.username,
    required this.avatarUrl,
    this.globalName,
    this.discriminator = '0',
    this.isBot = false,
    this.bannerUrl,
    this.bannerColor,
  });

  final String id;
  final String username;
  final String? globalName;
  final String discriminator;
  final bool isBot;
  final String avatarUrl;
  final String? bannerUrl;
  final int? bannerColor;

  String get displayName => globalName ?? username;
}

class BotUserMember {
  const BotUserMember({
    required this.id,
    this.nickname,
    this.joinedAt,
    this.avatarUrl,
  });

  final String id;
  final String? nickname;
  final DateTime? joinedAt;
  final String? avatarUrl;
}

abstract interface class BotUserQueryService {
  /// A missing Discord user returns null; network and authorization errors do not.
  Future<BotUser?> user(
    String userId, {
    required CommandExecutionBudget budget,
  });

  /// Membership in the adapter's current guild, with the same error distinction.
  Future<BotUserMember?> member(
    String userId, {
    required CommandExecutionBudget budget,
  });
}

class DiscordBotUserQueryService implements BotUserQueryService {
  const DiscordBotUserQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;

  Snowflake _id(String raw) {
    final value = raw.trim();
    final parsed = RegExp(r'^[0-9]+$').hasMatch(value)
        ? int.tryParse(value)
        : null;
    if (parsed == null || parsed <= 0) throw ArgumentError('Invalid user ID.');
    return Snowflake(parsed);
  }

  @override
  Future<BotUser?> user(
    String userId, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final id = _id(userId);
    User user;
    try {
      user = await client.users.fetch(id);
    } on HttpResponseError catch (error) {
      budget.check();
      if (error.statusCode == 404 && error.errorCode == 10013) return null;
      rethrow;
    }
    budget.check();
    return BotUser(
      id: '${user.id}',
      username: user.username,
      globalName: user.globalName,
      discriminator: user.discriminator,
      isBot: user.isBot,
      avatarUrl: user.avatar.url.toString(),
      bannerUrl: user.banner?.url.toString(),
      bannerColor: user.accentColor?.value,
    );
  });

  @override
  Future<BotUserMember?> member(
    String userId, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final id = _id(userId);
    final selectedGuild =
        guildId ?? (throw StateError('Member lookup requires a guild.'));
    Member member;
    try {
      member = await client.guilds[selectedGuild].members.fetch(id);
    } on HttpResponseError catch (error) {
      budget.check();
      if (error.statusCode == 404 && error.errorCode == 10007) return null;
      rethrow;
    }
    budget.check();
    return BotUserMember(
      id: '${member.id}',
      nickname: member.nick,
      joinedAt: member.joinedAt.isBefore(DateTime.utc(2015))
          ? null
          : member.joinedAt,
      avatarUrl: member.avatar?.url.toString(),
    );
  });
}
