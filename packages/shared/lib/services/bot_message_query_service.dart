import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'bot_permission_query_service.dart';

Snowflake messageQuerySnowflake(String raw) {
  final n = int.tryParse(raw.trim());
  if (!RegExp(r'^[0-9]+$').hasMatch(raw.trim()) || n == null || n <= 0) {
    throw ArgumentError('Invalid Discord ID.');
  }
  return Snowflake(n);
}

class BotMessageEmbed {
  const BotMessageEmbed({
    this.title,
    this.description,
    this.footer,
    this.colorHex,
    this.image,
    this.timestamp,
  });
  final String? title, description, footer, colorHex, image, timestamp;
}

class BotMessageSnapshot {
  const BotMessageSnapshot({
    required this.id,
    required this.channelId,
    required this.content,
    required this.authorId,
    required this.username,
    required this.avatarUrl,
    this.attachmentUrls = const [],
    this.embeds = const [],
    this.editedTimestamp,
    this.repliedMessageId,
  });
  final String id, channelId, content, authorId, username, avatarUrl;
  final List<String> attachmentUrls;
  final List<BotMessageEmbed> embeds;
  final DateTime? editedTimestamp;
  final String? repliedMessageId;
}

class BotMessageChannelSnapshot {
  const BotMessageChannelSnapshot({this.lastMessageId, this.lastPinTimestamp});
  final String? lastMessageId;
  final DateTime? lastPinTimestamp;
}

class MessageEdit {
  const MessageEdit({
    required this.content,
    this.title,
    this.description,
    this.color,
    this.footer,
    this.replaceEmbed = false,
  });
  final String content;
  final String? title, description, footer;
  final int? color;
  final bool replaceEmbed;
  void validate() {
    if (content.length > 2000 ||
        (title?.length ?? 0) > 256 ||
        (description?.length ?? 0) > 4096 ||
        (footer?.length ?? 0) > 2048) {
      throw ArgumentError('Message edit text exceeds Discord limits.');
    }
    if (color != null && (color! < 0 || color! > 0xffffff)) {
      throw ArgumentError('Invalid embed color.');
    }
    if ((title?.length ?? 0) +
            (description?.length ?? 0) +
            (footer?.length ?? 0) >
        6000) {
      throw ArgumentError('Embed text exceeds Discord limits.');
    }
  }

  MessageUpdateBuilder toBuilder() {
    final builder = MessageUpdateBuilder(content: content);
    if (replaceEmbed) {
      final embed = EmbedBuilder(
        title: title == null || title!.isEmpty ? null : title,
        description: description == null || description!.isEmpty
            ? null
            : description,
        color: color == null ? null : DiscordColor(color!),
        footer: footer == null || footer!.isEmpty
            ? null
            : EmbedFooterBuilder(text: footer!),
      );
      builder.embeds = embed.build().isEmpty ? [] : [embed];
    }
    return builder;
  }
}

enum MessageMutationKind { delete, pin, unpin, publish, edit }

class MessageMutation {
  const MessageMutation({
    required this.kind,
    required this.channelId,
    required this.messageId,
    this.edit,
  });
  final MessageMutationKind kind;
  final String channelId, messageId;
  final MessageEdit? edit;
  void validate() {
    messageQuerySnowflake(channelId);
    messageQuerySnowflake(messageId);
    if (kind == MessageMutationKind.edit) {
      if (edit == null) throw ArgumentError('Message edit data required.');
      edit!.validate();
    }
  }
}

abstract interface class BotMessageQueryService {
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  });
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  });
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  });
}

class DiscordBotMessageQueryService implements BotMessageQueryService {
  const DiscordBotMessageQueryService({required this.client});
  final NyxxGateway client;
  Future<({TextChannel channel, Message message})> _fetch(
    String channelId,
    String messageId,
    CommandExecutionBudget budget,
  ) async {
    final channel = await client.channels.fetch(
      messageQuerySnowflake(channelId),
    );
    budget.check();
    if (channel is! TextChannel) {
      throw ArgumentError('Channel does not support messages.');
    }
    final message = await channel.messages.fetch(
      messageQuerySnowflake(messageId),
    );
    budget.check();
    return (channel: channel, message: message);
  }

  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final channel = await client.channels.fetch(
      messageQuerySnowflake(channelId),
    );
    budget.check();
    if (channel is! TextChannel) {
      throw ArgumentError('Channel does not support messages.');
    }
    return BotMessageChannelSnapshot(
      lastMessageId: channel.lastMessageId?.toString(),
      lastPinTimestamp: channel.lastPinTimestamp,
    );
  });
  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final fetched = await _fetch(channelId, messageId, budget),
        message = fetched.message;
    return BotMessageSnapshot(
      id: message.id.toString(),
      channelId: message.channelId.toString(),
      content: message.content,
      editedTimestamp: message.editedTimestamp,
      repliedMessageId: message.type == MessageType.reply
          ? message.reference?.messageId?.toString()
          : null,
      authorId: message.author.id.toString(),
      username: message.author.username,
      avatarUrl: message.author.avatar?.url.toString() ?? '',
      attachmentUrls: message.attachments
          .map((a) => a.url.toString())
          .toList(growable: false),
      embeds: message.embeds
          .map(
            (e) => BotMessageEmbed(
              title: e.title,
              description: e.description,
              footer: e.footer?.text,
              colorHex: e.color?.value.toRadixString(16).padLeft(6, '0'),
              image: e.image?.url.toString(),
              timestamp: e.timestamp?.toUtc().toIso8601String(),
            ),
          )
          .toList(growable: false),
    );
  });

  /// Reads and validates only; sandbox adapters can apply the write separately.
  Future<({TextChannel channel, Message message})> prepareMessageMutation(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final fetched = await _fetch(change.channelId, change.messageId, budget);
    final channel = fetched.channel, message = fetched.message;
    if (change.kind == MessageMutationKind.edit &&
        message.author.id != client.user.id) {
      throw StateError('Only the bot own messages can be edited.');
    }
    if (change.kind == MessageMutationKind.publish &&
        channel is! GuildAnnouncementChannel) {
      throw ArgumentError('Publishing requires an announcement channel.');
    }
    if (channel is GuildChannel) {
      final permissions = await DiscordBotPermissionQueryService(
        client: client,
        guildId: (channel as GuildChannel).guildId,
      ).memberPermissions(channelId: change.channelId, budget: budget);
      final own = message.author.id == client.user.id;
      final required = <int>[
        Permissions.viewChannel.value,
        if (change.kind == MessageMutationKind.delete && !own)
          Permissions.manageMessages.value,
        if (change.kind == MessageMutationKind.pin ||
            change.kind == MessageMutationKind.unpin)
          Permissions.pinMessages.value,
        if (change.kind == MessageMutationKind.publish)
          Permissions.sendMessages.value,
        if (change.kind == MessageMutationKind.publish && !own)
          Permissions.manageMessages.value,
      ];
      if (!permissions.hasAll(required)) {
        throw StateError('Missing permissions for the message operation.');
      }
    } else if (change.kind == MessageMutationKind.delete &&
        message.author.id != client.user.id) {
      throw StateError(
        'Cannot delete another user message in a direct message.',
      );
    }
    budget.check();
    return fetched;
  });
  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final fetched = await prepareMessageMutation(change, budget: budget);
    budget.check();
    final manager = fetched.channel.messages, id = fetched.message.id;
    switch (change.kind) {
      case MessageMutationKind.delete:
        await manager.delete(id);
      case MessageMutationKind.pin:
        await manager.pin(id);
      case MessageMutationKind.unpin:
        await manager.unpin(id);
      case MessageMutationKind.publish:
        await manager.crosspost(id);
      case MessageMutationKind.edit:
        await manager.update(id, change.edit!.toBuilder());
    }
    budget.check();
  });
}

/// Main response outputs defer pinning until the real response ID exists.
abstract interface class BotDeferredMessageOutput {
  void deferPin();
}
