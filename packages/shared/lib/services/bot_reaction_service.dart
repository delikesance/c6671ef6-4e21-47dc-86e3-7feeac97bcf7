import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'bdfd_reaction_emoji_aliases.dart';
import 'bot_guild_query_service.dart';
import 'bot_permission_query_service.dart';

class BotReactionTarget {
  const BotReactionTarget({required this.channelId, required this.messageId});
  final String channelId;
  final String messageId;
  void validate() {
    _id(channelId);
    _id(messageId);
  }
}

class BotReactionAddRequest {
  BotReactionAddRequest({
    required this.target,
    required Iterable<String> emojis,
  }) : emojis = List.unmodifiable(emojis);
  final BotReactionTarget target;
  final List<String> emojis;
}

class BotReactionClearRequest {
  const BotReactionClearRequest({required this.target, this.emoji});
  final BotReactionTarget target;

  /// Null clears all reactions; otherwise clear all users for this emoji.
  final String? emoji;
}

class BotReactionQuery {
  const BotReactionQuery({required this.target, required this.emoji});
  final BotReactionTarget target;
  final String emoji;
}

class BotReactionUser {
  const BotReactionUser({
    required this.id,
    required this.username,
    this.discriminator = '0',
  });
  final String id;
  final String username;
  final String discriminator;
  String get tag => discriminator == '0' || discriminator.isEmpty
      ? username
      : '$username#$discriminator';
}

abstract interface class BotReactionService {
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  });
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  });
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  });
}

/// Pure normalization can run before a response ID exists.
String normalizeBotReactionEmoji(String raw) {
  final value = raw.trim();
  if (value.isEmpty) throw ArgumentError('An emoji is required.');
  if (value.startsWith(':') && value.endsWith(':')) {
    final alias = bdfdReactionEmojiAliases[value];
    if (alias == null) throw ArgumentError('Unknown BDFD emoji alias.');
    return alias;
  }
  if (RegExp(r'^\d+$').hasMatch(value)) {
    _id(value);
    return value;
  }
  if (value.startsWith('<')) {
    final match = RegExp(r'^<a?:([^:<>\s]+):(\d+)>$').firstMatch(value);
    if (match == null) throw ArgumentError('Invalid custom emoji.');
    _id(match[2]!);
    return value;
  }
  // The API remains authoritative for Unicode emoji validity.
  if (!value.runes.any((rune) => rune > 127)) {
    throw ArgumentError('Invalid Unicode emoji.');
  }
  return value;
}

class PreparedBotReactionAdd {
  PreparedBotReactionAdd(
    this.manager,
    this.messageId,
    Iterable<ReactionBuilder> emojis,
  ) : emojis = List.unmodifiable(emojis);
  final MessageManager manager;
  final Snowflake messageId;
  final List<ReactionBuilder> emojis;
}

class PreparedBotReactionClear {
  const PreparedBotReactionClear(this.manager, this.messageId, this.emoji);
  final MessageManager manager;
  final Snowflake messageId;
  final ReactionBuilder? emoji;
}

Future<({TextChannel channel, Message message})> _message(
  NyxxGateway client,
  BotReactionTarget target,
  CommandExecutionBudget budget,
) async {
  target.validate();
  budget.check();
  final channel = await client.channels.fetch(_id(target.channelId));
  budget.check();
  if (channel is! TextChannel) {
    throw StateError('Reactions require a message channel.');
  }
  final message = await channel.messages.fetch(_id(target.messageId));
  budget.check();
  return (channel: channel, message: message);
}

Future<ReactionBuilder> _emoji(
  NyxxGateway client,
  String raw,
  Message message,
  CommandExecutionBudget budget,
) async {
  final value = normalizeBotReactionEmoji(raw);
  final custom = RegExp(r'^<a?:([^:<>\s]+):(\d+)>$').firstMatch(value);
  if (custom != null) {
    return ReactionBuilder(name: custom[1]!, id: _id(custom[2]!));
  }
  if (!RegExp(r'^\d+$').hasMatch(value)) {
    return ReactionBuilder(name: value, id: null);
  }
  final selected = _id(value);
  // Reading an existing custom reaction needs no origin-guild lookup.
  for (final reaction in message.reactions) {
    budget.check();
    final emoji = reaction.emoji;
    if (emoji is Emoji && emoji.id == selected && emoji.name != null) {
      return ReactionBuilder(name: emoji.name!, id: selected);
    }
  }
  final guilds = await DiscordBotGuildQueryService(
    client: client,
  ).guilds(budget: budget);
  for (final guild in guilds) {
    budget.check();
    final emojis = await client.guilds[_id(guild.id)].emojis.list();
    budget.check();
    for (final emoji in emojis) {
      budget.check();
      if (emoji.id == selected && emoji.name != null) {
        return ReactionBuilder(name: emoji.name!, id: selected);
      }
    }
  }
  throw ArgumentError('Custom emoji is unavailable to the bot.');
}

Future<void> _permissions(
  NyxxGateway client,
  TextChannel channel,
  List<int> flags,
  CommandExecutionBudget budget,
  BotPermissionQueryService? permissions,
) async {
  if (channel is! GuildChannel) return;
  final service =
      permissions ?? DiscordBotPermissionQueryService(client: client);
  final value = await service.memberPermissions(
    channelId: '${channel.id}',
    budget: budget,
  );
  budget.check();
  if (!value.hasAll(flags)) {
    throw StateError('Missing channel permissions for reactions.');
  }
}

/// Preparation performs only reads and validation; reusable by sandbox adapters.
Future<PreparedBotReactionAdd> prepareBotReactionAdd(
  NyxxGateway client,
  BotReactionAddRequest request, {
  required CommandExecutionBudget budget,
  BotPermissionQueryService? permissions,
}) => budget.run(() async {
  request.target.validate();
  if (request.emojis.isEmpty) {
    throw ArgumentError('At least one emoji is required.');
  }
  final normalized = <String>[];
  for (final raw in request.emojis) {
    budget.check();
    normalized.add(normalizeBotReactionEmoji(raw));
  }
  final target = await _message(client, request.target, budget);
  final emojis = <ReactionBuilder>[];
  var needsAdd = false;
  for (final raw in normalized) {
    budget.check();
    final emoji = await _emoji(client, raw, target.message, budget);
    emojis.add(emoji);
    var exists = false;
    for (final reaction in target.message.reactions) {
      budget.check();
      final current = reaction.emoji;
      if (reaction.count > 0 &&
          (emoji.id != null
              ? current.id == emoji.id
              : current is Emoji &&
                    current.id == Snowflake.zero &&
                    current.name == emoji.name)) {
        exists = true;
      }
    }
    if (!exists) {
      needsAdd = true;
    }
  }
  await _permissions(
    client,
    target.channel,
    [
      Permissions.readMessageHistory.value,
      if (needsAdd) Permissions.addReactions.value,
    ],
    budget,
    permissions,
  );
  return PreparedBotReactionAdd(
    target.channel.messages,
    _id(request.target.messageId),
    emojis,
  );
});

Future<PreparedBotReactionClear> prepareBotReactionClear(
  NyxxGateway client,
  BotReactionClearRequest request, {
  required CommandExecutionBudget budget,
  BotPermissionQueryService? permissions,
}) => budget.run(() async {
  request.target.validate();
  final normalized = request.emoji == null
      ? null
      : normalizeBotReactionEmoji(request.emoji!);
  final target = await _message(client, request.target, budget);
  final emoji = normalized == null
      ? null
      : await _emoji(client, normalized, target.message, budget);
  await _permissions(
    client,
    target.channel,
    [Permissions.manageMessages.value],
    budget,
    permissions,
  );
  return PreparedBotReactionClear(
    target.channel.messages,
    _id(request.target.messageId),
    emoji,
  );
});

class DiscordBotReactionService implements BotReactionService {
  const DiscordBotReactionService({required this.client});
  final NyxxGateway client;
  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareBotReactionAdd(
      client,
      request,
      budget: budget,
    );
    for (final emoji in prepared.emojis) {
      budget.check();
      await prepared.manager.addReaction(prepared.messageId, emoji);
      budget.check();
    }
  });
  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final prepared = await prepareBotReactionClear(
      client,
      request,
      budget: budget,
    );
    budget.check();
    if (prepared.emoji == null) {
      await prepared.manager.deleteAllReactions(prepared.messageId);
    } else {
      await prepared.manager.deleteReaction(
        prepared.messageId,
        prepared.emoji!,
      );
    }
    budget.check();
  });
  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final normalized = normalizeBotReactionEmoji(query.emoji);
    final target = await _message(client, query.target, budget);
    final emoji = await _emoji(client, normalized, target.message, budget);
    final result = <String, BotReactionUser>{};
    Snowflake? after;
    while (true) {
      budget.check();
      final page = await target.channel.messages.fetchReactions(
        _id(query.target.messageId),
        emoji,
        after: after,
        limit: 100,
      );
      budget.check();
      Snowflake? highest = after;
      for (final user in page) {
        budget.check();
        result['${user.id}'] = BotReactionUser(
          id: '${user.id}',
          username: user.username,
          discriminator: user.discriminator,
        );
        if (highest == null || user.id.value > highest.value) {
          highest = user.id;
        }
      }
      if (page.length < 100) break;
      if (highest == null || highest == after) {
        throw StateError('Reaction pagination did not advance.');
      }
      after = highest;
    }
    return List.unmodifiable(result.values);
  });
}

Snowflake _id(String value) {
  final raw = value.trim();
  final parsed = RegExp(r'^[0-9]+$').hasMatch(raw) ? int.tryParse(raw) : null;
  if (parsed == null || parsed <= 0) throw ArgumentError('Invalid Discord ID.');
  return Snowflake(parsed);
}
