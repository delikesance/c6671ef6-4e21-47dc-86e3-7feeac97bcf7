import 'package:nyxx/nyxx.dart';
import '../engine/execution_budget.dart';
import 'bot_permission_query_service.dart';

Snowflake threadSnowflake(String raw) {
  final n = BigInt.tryParse(raw.trim());
  if (!RegExp(r'^[0-9]+$').hasMatch(raw.trim()) ||
      n == null ||
      n <= BigInt.zero ||
      n > (BigInt.one << 64) - BigInt.one) {
    throw ArgumentError('Invalid Discord ID.');
  }
  try {
    return Snowflake.parse(raw.trim());
  } on FormatException {
    throw ArgumentError('Discord ID exceeds the SDK integer range.');
  }
}

void _name(String name) {
  if (name.trim().isEmpty || name.length > 100) {
    throw ArgumentError('Thread name must contain 1 to 100 characters.');
  }
}

void _archive(int n) {
  if (!const [60, 1440, 4320, 10080].contains(n)) {
    throw ArgumentError('Invalid thread archive duration.');
  }
}

class ThreadCreation {
  const ThreadCreation({
    required this.name,
    required this.channelId,
    this.messageId,
    this.archiveMinutes = 60,
  });
  final String name, channelId;
  final String? messageId;
  final int archiveMinutes;
  void validate() {
    _name(name);
    threadSnowflake(channelId);
    _archive(archiveMinutes);
    if (messageId != null) threadSnowflake(messageId!);
  }
}

class ThreadModification {
  const ThreadModification({
    required this.threadId,
    this.name,
    this.archived,
    this.archiveMinutes,
    this.locked,
    this.slowmodeSeconds,
  });
  final String threadId;
  final String? name;
  final bool? archived, locked;
  final int? archiveMinutes, slowmodeSeconds;
  void validate() {
    threadSnowflake(threadId);
    if (name != null) _name(name!);
    if (archiveMinutes != null) _archive(archiveMinutes!);
    if (slowmodeSeconds != null &&
        (slowmodeSeconds! < 0 || slowmodeSeconds! > 21600)) {
      throw ArgumentError('Invalid thread slowmode.');
    }
  }

  bool get onlyUnarchive =>
      archived == false &&
      name == null &&
      archiveMinutes == null &&
      locked == null &&
      slowmodeSeconds == null;
  ThreadUpdateBuilder toBuilder() {
    final b = ThreadUpdateBuilder(
      name: name,
      isArchived: archived,
      isLocked: locked,
      autoArchiveDuration: archiveMinutes == null
          ? null
          : Duration(minutes: archiveMinutes!),
    );
    if (slowmodeSeconds != null) {
      b.rateLimitPerUser = Duration(seconds: slowmodeSeconds!);
    }
    return b;
  }
}

class ThreadMemberChange {
  const ThreadMemberChange({required this.threadId, required this.userId});
  final String threadId, userId;
  void validate() {
    threadSnowflake(threadId);
    threadSnowflake(userId);
  }
}

class BotThreadInfo {
  const BotThreadInfo({
    required this.id,
    required this.messageCount,
    required this.userCount,
  });
  final String id;
  final int messageCount, userCount;
}

abstract interface class BotThreadService {
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  });
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  });
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  });
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  });
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  });
}

class DiscordBotThreadService implements BotThreadService {
  const DiscordBotThreadService({
    required this.client,
    this.guildId,
    this.channelId,
  });
  final NyxxGateway client;
  final Snowflake? guildId, channelId;
  Future<Thread> _thread(String? raw, CommandExecutionBudget budget) async {
    final id = raw == null ? channelId : threadSnowflake(raw);
    if (id == null) throw StateError('A current thread is required.');
    final channel = await client.channels.fetch(id);
    budget.check();
    if (channel is! Thread) throw ArgumentError('Channel is not a thread.');
    return channel;
  }

  Future<BotMemberPermissions> _permissions(
    GuildChannel channel,
    CommandExecutionBudget budget,
  ) => DiscordBotPermissionQueryService(
    client: client,
    guildId: channel.guildId,
  ).memberPermissions(channelId: channel.id.toString(), budget: budget);
  void _require(
    BotMemberPermissions permissions,
    List<Flag<Permissions>> flags,
  ) {
    if (!permissions.hasAll([
      Permissions.viewChannel.value,
      ...flags.map((f) => f.value),
    ])) {
      throw StateError('Missing permissions for the thread operation.');
    }
  }

  /// Read-only preparation shared with fixture-backed mutation adapters.
  Future<GuildChannel> prepareThreadCreation(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final parent = await client.channels.fetch(
      threadSnowflake(change.channelId),
    );
    budget.check();
    if (parent is! GuildTextChannel && parent is! GuildAnnouncementChannel) {
      throw ArgumentError('Threads require a text or announcement parent.');
    }
    if (parent is GuildAnnouncementChannel && change.messageId == null) {
      throw ArgumentError('An announcement thread requires a source message.');
    }
    final channel = parent as GuildChannel;
    _require(await _permissions(channel, budget), [
      Permissions.createPublicThreads,
    ]);
    budget.check();
    return channel;
  });
  @override
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final channel = await prepareThreadCreation(change, budget: budget);
    budget.check();
    final Thread result;
    if (change.messageId == null) {
      result = await client.channels.createThread(
        channel.id,
        ThreadBuilder.publicThread(
          name: change.name,
          autoArchiveDuration: Duration(minutes: change.archiveMinutes),
        ),
      );
    } else {
      result = await client.channels.createThreadFromMessage(
        channel.id,
        threadSnowflake(change.messageId!),
        ThreadFromMessageBuilder(
          name: change.name,
          autoArchiveDuration: Duration(minutes: change.archiveMinutes),
        ),
      );
    }
    budget.check();
    return result.id.toString();
  });
  Future<Thread> prepareThreadModification(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final thread = await _thread(change.threadId, budget);
    if (thread.isArchived && change.archived != false) {
      throw StateError('An archived thread must be unarchived to edit it.');
    }
    if (change.locked == true && (change.archived ?? thread.isArchived)) {
      throw ArgumentError('Archived threads cannot be locked.');
    }
    _require(
      await _permissions(thread, budget),
      change.onlyUnarchive && !thread.isLocked
          ? [Permissions.sendMessages]
          : [Permissions.manageThreads],
    );
    budget.check();
    return thread;
  });
  @override
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final thread = await prepareThreadModification(change, budget: budget);
    budget.check();
    await client.channels.update(thread.id, change.toBuilder());
    budget.check();
  });
  Future<Thread> prepareThreadMemberChange(
    ThreadMemberChange change, {
    required bool remove,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    change.validate();
    final thread = await _thread(change.threadId, budget);
    if (thread.isArchived) throw StateError('Thread is archived.');
    final privateOwner =
        thread.type == ChannelType.privateThread &&
        thread.ownerId == client.user.id;
    _require(
      await _permissions(thread, budget),
      remove
          ? (privateOwner ? [] : [Permissions.manageThreads])
          : [Permissions.sendMessagesInThreads],
    );
    budget.check();
    return thread;
  });
  Future<void> _member(
    ThreadMemberChange change,
    bool remove,
    CommandExecutionBudget budget,
  ) => budget.run(() async {
    final thread = await prepareThreadMemberChange(
      change,
      remove: remove,
      budget: budget,
    );
    budget.check();
    if (remove) {
      await client.channels.removeThreadMember(
        thread.id,
        threadSnowflake(change.userId),
      );
    } else {
      await client.channels.addThreadMember(
        thread.id,
        threadSnowflake(change.userId),
      );
    }
    budget.check();
  });
  @override
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _member(change, false, budget);
  @override
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) => _member(change, true, budget);
  @override
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final thread = await _thread(threadId, budget);
    return BotThreadInfo(
      id: thread.id.toString(),
      messageCount: thread.messageCount,
      userCount: thread.approximateMemberCount,
    );
  });
}
