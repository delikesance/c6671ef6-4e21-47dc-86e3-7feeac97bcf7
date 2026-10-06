import 'package:nyxx/nyxx.dart';
import '../engine/discord_entity_fetcher.dart' show DiscordEntityNotFound;
import '../engine/execution_budget.dart';

/// List results contain identity/name only; individual reads contain details.
class BotGuild {
  const BotGuild({
    required this.id,
    required this.name,
    this.ownerId,
    this.description,
    this.verificationLevel,
    this.iconUrl,
    this.bannerUrl,
    this.boostCount,
    this.boostLevel,
    this.afkTimeoutSeconds,
  });
  final String id;
  final String name;
  final String? ownerId;
  final String? description;
  final int? verificationLevel;
  final String? iconUrl;
  final String? bannerUrl;
  final int? boostCount;
  final int? boostLevel;
  final int? afkTimeoutSeconds;
}

abstract interface class BotGuildQueryService {
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  });
  Future<List<BotGuild>> guilds({required CommandExecutionBudget budget});
}

class DiscordBotGuildQueryService implements BotGuildQueryService {
  const DiscordBotGuildQueryService({required this.client, this.guildId});
  final NyxxGateway client;
  final Snowflake? guildId;

  @override
  Future<BotGuild?> guild({
    String? guildId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final selected = guildId == null ? this.guildId : _id(guildId);
    if (selected == null) throw StateError('Guild lookup requires a guild.');
    try {
      final guild = await client.guilds.fetch(selected);
      budget.check();
      return BotGuild(
        id: '${guild.id}',
        name: guild.name,
        ownerId: '${guild.ownerId}',
        description: guild.description,
        verificationLevel: guild.verificationLevel.value,
        iconUrl: _asset('icons', guild.id, guild.iconHash),
        bannerUrl: _asset('banners', guild.id, guild.bannerHash),
        boostCount: guild.premiumSubscriptionCount,
        boostLevel: guild.premiumTier.value,
        afkTimeoutSeconds: guild.afkTimeout.inSeconds,
      );
    } on DiscordEntityNotFound {
      budget.check();
      return null;
    } on HttpResponseError catch (error) {
      budget.check();
      if (error.statusCode == 404 && error.errorCode == 10004 ||
          error.statusCode == 403 && error.errorCode == 50001) {
        return null;
      }
      rethrow;
    }
  });

  @override
  Future<List<BotGuild>> guilds({required CommandExecutionBudget budget}) =>
      budget.run(() async {
        final result = <String, BotGuild>{};
        Snowflake? after;
        while (true) {
          budget.check();
          final page = await client.users.listCurrentUserGuilds(
            after: after,
            limit: 200,
          );
          budget.check();
          Snowflake? highest = after;
          for (final guild in page) {
            budget.check();
            result['${guild.id}'] = BotGuild(
              id: '${guild.id}',
              name: guild.name,
            );
            if (highest == null || guild.id.value > highest.value) {
              highest = guild.id;
            }
          }
          if (page.length < 200) break;
          if (highest == null || highest == after) {
            throw StateError('Discord guild pagination did not advance.');
          }
          after = highest;
        }
        return List.unmodifiable(result.values);
      });
}

Snowflake _id(String raw) {
  final text = raw.trim();
  final value = RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
  if (value == null || value <= 0) throw ArgumentError('Invalid guild ID.');
  return Snowflake(value);
}

String? _asset(String type, Snowflake id, String? hash) => hash == null
    ? null
    : 'https://cdn.discordapp.com/$type/$id/$hash.${hash.startsWith('a_') ? 'gif' : 'png'}';
