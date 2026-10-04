import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:nyxx/nyxx.dart';

import 'variables_test_helpers.dart';

// Recording Discord gateway shared by the parity tests of channel / thread /
// guild blocks (waves 4-5). Reads come from the sandbox EntityFixtureGateway;
// every write is recorded, so the historical executor and the native engine can
// be compared over the same simulated Discord.

Map<String, dynamic> visualFixtures({
  int permissions = 8, // administrator
  bool owner = false,
}) => {
  'guilds': <String, dynamic>{
    '10': <String, dynamic>{
      'owner_id': owner ? '500' : '999',
      'roles': [
        {'id': '10', 'name': '@everyone', 'permissions': '0'},
        {'id': '63', 'name': 'bot', 'permissions': '$permissions'},
        {'id': '64', 'name': 'staff', 'permissions': '0'},
      ],
      'members': {
        '500': {
          'roles': ['63'],
        },
        '20': {'roles': <String>[]},
        '222': {'roles': <String>[]},
      },
      'channels': <Map<String, dynamic>>[
        {
          'id': '30',
          'name': 'chat',
          'type': 'text',
          'permission_overwrites': <Map<String, dynamic>>[],
        },
        {'id': '31', 'name': 'category', 'type': 'category'},
        {'id': '32', 'name': 'forum', 'type': 'forum'},
        {'id': '33', 'name': 'dup', 'type': 'text'},
        {'id': '34', 'name': 'dup', 'type': 'voice'},
      ],
      'threads': <Map<String, dynamic>>[],
    },
  },
};

class VisualBot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualUser implements User {
  VisualUser(this.username);
  @override
  final String username;
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualThread implements Thread {
  VisualThread(
    this.id,
    this.name, {
    this.type = ChannelType.publicThread,
    this.gateway,
  });
  final VisualGateway? gateway;
  @override
  Future<void> addThreadMember(Snowflake userId) async =>
      gateway?.record('addThreadMember', {'thread': '$id', 'user': '$userId'});
  @override
  Future<void> removeThreadMember(Snowflake userId) async => gateway?.record(
    'removeThreadMember',
    {'thread': '$id', 'user': '$userId'},
  );
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  final ChannelType type;
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualGateway implements NyxxGateway {
  VisualGateway({Map<String, dynamic>? data})
    : fixture = EntityFixtureGateway(data ?? visualFixtures()) {
    channelManager = VisualChannels(this);
    guildManager = VisualGuilds(this);
    userManager = VisualUsers(this);
  }
  final EntityFixtureGateway fixture;
  late final VisualChannels channelManager;
  late final VisualGuilds guildManager;
  late final VisualUsers userManager;

  /// Every write, in order, for comparison between the two paths.
  final writes = <Map<String, Object?>>[];

  /// Failure to inject on the next write of the named operation.
  final failures = <String, Object>{};
  Duration delay = Duration.zero;

  /// Commands `list()` reports for every guild.
  final commandRows = <VisualCommand>[];

  /// `guilds.fetch` returns a guild that records `leave()`.
  bool leaveOnFetch = false;

  void record(String operation, Map<String, Object?> data) {
    writes.add({'operation': operation, ...data});
    final failure = failures.remove(operation);
    if (failure != null) throw failure;
  }

  @override
  ChannelManager get channels => channelManager;
  @override
  GuildManager get guilds => guildManager;
  @override
  UserManager get users => userManager;
  @override
  PartialUser get user => VisualBot();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualUsers implements UserManager {
  VisualUsers(this.gateway);
  final VisualGateway gateway;
  @override
  Future<User> updateCurrentUser(UserUpdateBuilder builder) async {
    gateway.record('updateSelfUser', {'payload': builder.build()});
    return VisualUser(builder.build()['username']?.toString() ?? 'bot');
  }

  @override
  Future<void> leaveGuild(Snowflake id) async {
    gateway.record('leaveGuild', {'guild': '$id'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LeavingGuild implements Guild {
  _LeavingGuild(this.gateway, this.id);
  final VisualGateway gateway;
  @override
  final Snowflake id;
  @override
  Future<void> leave() => gateway.users.leaveGuild(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualCommand implements ApplicationCommand {
  VisualCommand(this.id, this.name);
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualCommands implements GuildApplicationCommandManager {
  VisualCommands(this.gateway, this.guild);
  final VisualGateway gateway;
  final Snowflake guild;
  @override
  Future<ApplicationCommand> create(ApplicationCommandBuilder builder) async {
    final payload = builder.build();
    gateway.record('createCommand', {
      'guild': '$guild',
      'name': payload['name'],
    });
    return VisualCommand(Snowflake(900), payload['name'].toString());
  }

  @override
  Future<List<ApplicationCommand>> list({bool? withLocalizations}) async =>
      gateway.commandRows.map((c) => c as ApplicationCommand).toList();

  @override
  Future<void> delete(Snowflake id) async {
    gateway.record('deleteCommand', {'guild': '$guild', 'id': '$id'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualGuildRef implements PartialGuild {
  VisualGuildRef(this.gateway, this.id);
  final VisualGateway gateway;
  @override
  final Snowflake id;
  PartialGuild get _inner => gateway.fixture.guilds[id];
  @override
  RoleManager get roles => _inner.roles;
  @override
  MemberManager get members => _inner.members;
  @override
  GuildApplicationCommandManager get commands => VisualCommands(gateway, id);
  @override
  Future<List<GuildChannel>> fetchChannels() => _inner.fetchChannels();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class VisualGuilds implements GuildManager {
  VisualGuilds(this.gateway);
  final VisualGateway gateway;
  final creations = <Map<String, dynamic>>[];
  @override
  PartialGuild operator [](Snowflake id) => VisualGuildRef(gateway, id);
  @override
  Cache<Guild> get cache => gateway.fixture.guilds.cache;
  @override
  Future<Guild> get(Snowflake id) => fetch(id);
  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) async {
    if (gateway.delay != Duration.zero) {
      await Future<void>.delayed(gateway.delay);
    }
    if (gateway.leaveOnFetch) return _LeavingGuild(gateway, id);
    return gateway.fixture.guilds.fetch(id, withCounts: withCounts);
  }

  @override
  Future<T> createGuildChannel<T extends GuildChannel>(
    Snowflake id,
    GuildChannelBuilder<T> builder, {
    String? auditLogReason,
  }) async {
    final payload = builder.build();
    creations.add({'payload': payload, 'reason': auditLogReason});
    gateway.record('createChannel', {
      'guild': '$id',
      'payload': payload,
      'reason': auditLogReason,
    });
    final channelId = '${799 + creations.length}';
    final rows =
        gateway.fixture.fixtures['guilds'][id.toString()]['channels'] as List;
    rows.add(<String, dynamic>{
      'id': channelId,
      'name': payload['name'],
      'type': switch (payload['type']) {
        0 => 'text',
        2 => 'voice',
        4 => 'category',
        5 => 'announcement',
        13 => 'stage',
        15 => 'forum',
        _ => 'bad',
      },
      if (payload.containsKey('parent_id')) 'parent_id': payload['parent_id'],
      if (payload.containsKey('topic')) 'topic': payload['topic'],
      if (payload.containsKey('nsfw')) 'nsfw': payload['nsfw'],
      if (payload.containsKey('rate_limit_per_user'))
        'slowmode': payload['rate_limit_per_user'],
    });
    return await gateway.fixture.channels.fetch(Snowflake.parse(channelId))
        as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A text channel whose own writes (threads, overwrites) hit the recorder.
class VisualTextChannel extends GuildTextChannel {
  VisualTextChannel(GuildTextChannel base, VisualChannels manager)
    : super(
        id: base.id,
        manager: manager,
        guildId: base.guildId,
        name: base.name,
        topic: base.topic,
        parentId: base.parentId,
        position: base.position,
        isNsfw: base.isNsfw,
        permissionOverwrites: base.permissionOverwrites,
        defaultAutoArchiveDuration: base.defaultAutoArchiveDuration,
        defaultThreadRateLimitPerUser: base.defaultThreadRateLimitPerUser,
        rateLimitPerUser: base.rateLimitPerUser,
        lastMessageId: base.lastMessageId,
        lastPinTimestamp: base.lastPinTimestamp,
      );
}

class VisualChannels implements ChannelManager {
  VisualChannels(this.gateway);
  final VisualGateway gateway;

  /// Channel ids that resolve to a thread.
  final threads = <Snowflake, Thread>{};

  Future<void> _wait() async {
    if (gateway.delay != Duration.zero) {
      await Future<void>.delayed(gateway.delay);
    }
  }

  @override
  Future<Channel> get(Snowflake id) => fetch(id);
  @override
  Future<Channel> fetch(Snowflake id) async {
    await _wait();
    final thread = threads[id];
    if (thread != null) return thread;
    final channel = await gateway.fixture.channels.fetch(id);
    if (channel is GuildTextChannel) return VisualTextChannel(channel, this);
    return channel;
  }

  @override
  Future<Channel> update(
    Snowflake id,
    UpdateBuilder<Channel> builder, {
    String? auditLogReason,
  }) async {
    gateway.record('updateChannel', {
      'id': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return fetch(id);
  }

  @override
  Future<Channel> delete(Snowflake id, {String? auditLogReason}) async {
    final channel = await fetch(id);
    gateway.record('deleteChannel', {'id': '$id', 'reason': auditLogReason});
    return channel;
  }

  @override
  Future<void> updatePermissionOverwrite(
    Snowflake id,
    PermissionOverwriteBuilder builder,
  ) async {
    gateway.record('editPermissions', {
      'id': '$id',
      'payload': builder.build(),
    });
  }

  @override
  Future<void> deletePermissionOverwrite(
    Snowflake id,
    Snowflake permissionId,
  ) async {
    gateway.record('deletePermission', {
      'id': '$id',
      'target': '$permissionId',
    });
  }

  @override
  Future<Thread> createThread(
    Snowflake id,
    ThreadBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('createThread', {
      'channel': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return VisualThread(Snowflake(700), builder.build()['name'].toString());
  }

  @override
  Future<Thread> createThreadFromMessage(
    Snowflake id,
    Snowflake messageId,
    ThreadFromMessageBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('createThreadFromMessage', {
      'channel': '$id',
      'message': '$messageId',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return VisualThread(Snowflake(701), builder.build()['name'].toString());
  }

  @override
  Future<void> addThreadMember(Snowflake id, Snowflake memberId) async {
    gateway.record('addThreadMember', {'thread': '$id', 'user': '$memberId'});
  }

  @override
  Future<void> removeThreadMember(Snowflake id, Snowflake memberId) async {
    gateway.record('removeThreadMember', {
      'thread': '$id',
      'user': '$memberId',
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A store that knows the bot's commands, for (un)registerGuildCommands.
class CommandStore extends MemoryBotDataStore {
  CommandStore(this.commands);
  final List<Map<String, dynamic>> commands;
  @override
  Future<List<Map<String, dynamic>>> getCommands(String botId) async =>
      commands;
}
