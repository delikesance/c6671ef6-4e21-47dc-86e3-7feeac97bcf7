import 'package:nyxx/nyxx.dart';
import '../engine/discord_entity_fetcher.dart';

num? _asNum(dynamic v) => v is num ? v : num.tryParse(v?.toString() ?? '');

/// Read-only Discord fixtures routed through the production entity fetcher.
/// Every unimplemented operation fails locally; no client is connected.
class EntityFixtureGateway implements NyxxGateway {
  EntityFixtureGateway(this.fixtures);
  final Map<String, dynamic> fixtures;
  final requests = <Map<String, String>>[];
  final errors = <String>[];
  @override
  GatewayClientOptions get options => const GatewayClientOptions();
  @override
  GatewayApiOptions get apiOptions =>
      GatewayApiOptions(token: 'sandbox', intents: GatewayIntents.none);
  @override
  ChannelManager get channels => _Channels(this);
  @override
  GuildManager get guilds => _Guilds(this);
  @override
  UserManager get users => _Users(this);
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Sandbox Discord access denied: ${invocation.memberName}',
  );
}

class _Users implements UserManager {
  _Users(this.gateway);
  final EntityFixtureGateway gateway;
  @override
  NyxxGateway get client => gateway;
  @override
  Future<List<UserGuild>> listCurrentUserGuilds({
    Snowflake? after,
    Snowflake? before,
    int? limit,
    bool? withCounts,
  }) async {
    gateway.requests.add({
      'operation': 'users.guilds',
      if (after != null) 'after': '$after',
      if (before != null) 'before': '$before',
    });
    final raw = gateway.fixtures['guilds'];
    if (raw is! Map) throw StateError('Missing sandbox guilds fixture');
    final entries = raw.entries.toList()
      ..sort(
        (a, b) => BigInt.parse(
          a.key.toString(),
        ).compareTo(BigInt.parse(b.key.toString())),
      );
    return entries
        .where((entry) {
          final id = Snowflake.parse(entry.key.toString());
          return (after == null || id.value > after.value) &&
              (before == null || id.value < before.value);
        })
        .take(limit ?? 200)
        .map((entry) {
          final row = entry.value as Map;
          return UserGuild(
            id: Snowflake.parse(entry.key.toString()),
            manager: gateway.guilds,
            name: row['name']?.toString() ?? 'guild-${entry.key}',
            iconHash: row['icon']?.toString(),
            bannerHash: row['banner']?.toString(),
            isOwnedByCurrentUser: false,
            currentUserPermissions: const Permissions(0),
            features: const GuildFeatures(0),
            approximateMemberCount: null,
            approximatePresenceCount: null,
          );
        })
        .toList();
  }

  @override
  Future<User> fetch(Snowflake id) async {
    gateway.requests.add({'operation': 'users.fetch', 'user_id': '$id'});
    final users = gateway.fixtures['users'];
    if (users is! Map) {
      final error = 'Missing sandbox users fixture';
      gateway.errors.add(error);
      throw StateError(error);
    }
    final raw = users[id.toString()];
    if (raw is! Map) throw const DiscordEntityNotFound();
    return User(
      manager: this,
      id: id,
      username: raw['username']?.toString() ?? 'user-$id',
      discriminator: raw['discriminator']?.toString() ?? '0',
      globalName: raw['global_name']?.toString(),
      avatarHash: raw['avatar']?.toString(),
      isBot: raw['bot'] == true,
      isSystem: false,
      hasMfaEnabled: false,
      bannerHash: raw['banner']?.toString(),
      accentColor: raw['accent_color'] == null
          ? null
          : DiscordColor(int.parse(raw['accent_color'].toString())),
      locale: null,
      flags: null,
      nitroType: NitroType.none,
      publicFlags: null,
      avatarDecorationHash: null,
      avatarDecorationData: null,
      primaryGuild: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox user operation denied');
}

class _Guilds implements GuildManager {
  _Guilds(this.gateway);
  final EntityFixtureGateway gateway;
  @override
  PartialGuild operator [](Snowflake id) => _Guild(gateway, id);
  @override
  Cache<Guild> get cache => _FixtureGuildCache(gateway);
  @override
  Future<Guild> get(Snowflake id) => fetch(id);
  @override
  Future<Ban> fetchBan(Snowflake id, Snowflake userId) async {
    gateway.requests.add({
      'operation': 'guilds.fetchBan',
      'guild_id': '$id',
      'user_id': '$userId',
    });
    final guild = (gateway.fixtures['guilds'] as Map?)?[id.toString()];
    final bans = guild is Map ? guild['bans'] : null;
    if (bans is! Map) {
      final error = 'Missing sandbox ban fixture for guild $id';
      gateway.errors.add(error);
      throw StateError(error);
    }
    if (!bans.containsKey(userId.toString())) {
      throw const DiscordEntityNotFound();
    }
    return Ban(
      reason: bans[userId.toString()]?.toString(),
      user: _FixtureBanUser(userId),
    );
  }

  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) async {
    gateway.requests.add({'operation': 'guilds.fetch', 'guild_id': '$id'});
    final guilds = gateway.fixtures['guilds'];
    if (guilds is! Map) {
      final error = 'Missing sandbox guild fixture';
      gateway.errors.add(error);
      throw StateError(error);
    }
    if (!guilds.containsKey(id.toString())) {
      throw const DiscordEntityNotFound();
    }
    return _FixtureGuild(gateway, id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox guild operation denied');
}

class _FixtureBanUser implements User {
  _FixtureBanUser(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox banned user field denied');
}

class _FixtureGuild implements Guild {
  _FixtureGuild(this.gateway, this.id);
  final EntityFixtureGateway gateway;
  @override
  final Snowflake id;
  Map get _row => (gateway.fixtures['guilds'] as Map)[id.toString()] as Map;
  @override
  String get name => _row['name']?.toString() ?? 'guild-$id';
  @override
  String? get description => _row['description']?.toString();
  @override
  String? get iconHash => _row['icon']?.toString();
  @override
  String? get bannerHash => _row['banner']?.toString();
  @override
  VerificationLevel get verificationLevel => VerificationLevel(
    int.parse((_row['verification_level'] ?? 0).toString()),
  );
  @override
  int? get premiumSubscriptionCount =>
      _row['premium_subscription_count'] == null
      ? null
      : int.parse(_row['premium_subscription_count'].toString());
  @override
  PremiumTier get premiumTier =>
      PremiumTier(int.parse((_row['premium_tier'] ?? 0).toString()));
  @override
  Duration get afkTimeout =>
      Duration(seconds: int.parse((_row['afk_timeout'] ?? 300).toString()));
  Snowflake? _channelSetting(String key) {
    final guild = (gateway.fixtures['guilds'] as Map)[id.toString()] as Map;
    final raw = guild[key];
    if (raw == null) return null;
    final parsed = int.tryParse(raw.toString());
    if (parsed == null || parsed <= 0) {
      throw StateError('Invalid sandbox guild channel ID: $key.');
    }
    return Snowflake(parsed);
  }

  @override
  Snowflake? get afkChannelId => _channelSetting('afk_channel_id');
  @override
  Snowflake? get rulesChannelId => _channelSetting('rules_channel_id');
  @override
  Snowflake? get systemChannelId => _channelSetting('system_channel_id');
  @override
  Snowflake get ownerId {
    final guild = (gateway.fixtures['guilds'] as Map?)?[id.toString()];
    return Snowflake.parse((guild as Map?)?['owner_id']?.toString() ?? '0');
  }

  @override
  List<Role> get roleList => _Roles(gateway, id).read();
  @override
  MemberManager get members => _Members(gateway, id);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox guild operation denied');
}

class _FixtureGuildCache implements Cache<Guild> {
  _FixtureGuildCache(this.gateway);
  final EntityFixtureGateway gateway;

  @override
  Iterable<Snowflake> get keys =>
      ((gateway.fixtures['guilds'] as Map?)?.keys ?? const <String>[]).map(
        (id) => Snowflake.parse(id.toString()),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox guild cache write denied');
}

class _Guild implements PartialGuild {
  _Guild(this.gateway, this.id);
  final EntityFixtureGateway gateway;
  @override
  final Snowflake id;
  @override
  RoleManager get roles => _Roles(gateway, id);
  @override
  MemberManager get members => _Members(gateway, id);
  @override
  GuildEmojiManager get emojis => _FixtureGuildEmojis(gateway, id);
  @override
  Future<Guild> get() => _Guilds(gateway).fetch(id);
  @override
  Future<List<GuildChannel>> fetchChannels() async {
    gateway.requests.add({'operation': 'guild.channels', 'guild_id': '$id'});
    return _Channels(gateway).read(id);
  }

  @override
  Future<ThreadList> listActiveThreads() async {
    gateway.requests.add({
      'operation': 'guild.activeThreads',
      'guild_id': '$id',
    });
    final guild = (gateway.fixtures['guilds'] as Map?)?['$id'];
    if (guild is! Map || guild['threads'] is! List) {
      throw StateError('Missing sandbox active thread fixture for guild $id');
    }
    final threads = (guild['threads'] as List)
        .map(
          (raw) => _FixtureThread(
            Map<String, dynamic>.from(raw as Map),
            id,
            gateway,
          ),
        )
        .where((t) => !t.isArchived)
        .toList();
    return ThreadList(threads: threads, members: const [], hasMore: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox guild operation denied');
}

class _FixtureGuildEmojis implements GuildEmojiManager {
  _FixtureGuildEmojis(this.gateway, this.guildId);
  final EntityFixtureGateway gateway;
  @override
  final Snowflake guildId;

  @override
  Future<List<GuildEmoji>> list() async {
    gateway.requests.add({'operation': 'guild.emojis', 'guild_id': '$guildId'});
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    if (guild is! Map || guild['emojis'] is! List) {
      final error = 'Missing sandbox emoji fixture for guild $guildId';
      gateway.errors.add(error);
      throw StateError(error);
    }
    return (guild['emojis'] as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return GuildEmoji(
        id: Snowflake.parse(row['id'].toString()),
        manager: this,
        name: row['name']?.toString(),
        roleIds: null,
        user: row['creator_id'] == null
            ? null
            : _FixtureBanUser(Snowflake.parse(row['creator_id'].toString())),
        requiresColons: true,
        isManaged: false,
        isAnimated: row['animated'] == true,
        isAvailable: true,
      );
    }).toList();
  }

  @override
  Future<GuildEmoji> fetch(Snowflake id) async {
    gateway.requests.add({
      'operation': 'guild.emojis.fetch',
      'guild_id': '$guildId',
      'emoji_id': '$id',
    });
    for (final emoji in await list()) {
      if (emoji.id == id) return emoji;
    }
    throw StateError('Missing sandbox emoji fixture $id in guild $guildId');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox emoji write denied');
}

class _Channels implements ChannelManager {
  _Channels(this.gateway);
  final EntityFixtureGateway gateway;

  @override
  PartialChannel operator [](Snowflake id) =>
      _FixtureTextChannel(gateway, id, this);

  List<GuildChannel> read(Snowflake guildId) {
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    if (guild is! Map || guild['channels'] is! List) {
      final error = 'Missing sandbox channel fixture for guild $guildId';
      gateway.errors.add(error);
      throw StateError(error);
    }
    return (guild['channels'] as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final type = row['type']?.toString() ?? 'text';
      final id = Snowflake.parse(row['id'].toString());
      final parent = row['parent_id'] == null
          ? null
          : Snowflake.parse(row['parent_id'].toString());
      if (type == 'category') {
        return GuildCategory(
          id: id,
          manager: this,
          guildId: guildId,
          isNsfw: row['nsfw'] == true,
          name: row['name'].toString(),
          parentId: parent,
          permissionOverwrites: _fixtureOverwrites(row),
          position: (_asNum(row['position']) ?? 0).toInt(),
        );
      }
      if (type == 'announcement') {
        return _FixtureGuildAnnouncementChannel(
          gateway: gateway,
          id: id,
          manager: this,
          guildId: guildId,
          name: row['name'].toString(),
          topic: row['topic']?.toString(),
          parentId: parent,
          position: (_asNum(row['position']) ?? 0).toInt(),
          isNsfw: row['nsfw'] == true,
          permissionOverwrites: _fixtureOverwrites(row),
          defaultAutoArchiveDuration: const Duration(days: 1),
          defaultThreadRateLimitPerUser: null,
          rateLimitPerUser: Duration(
            seconds: (_asNum(row['slowmode']) ?? 0).toInt(),
          ),
          lastMessageId: row['last_message_id'] == null
              ? null
              : Snowflake.parse(row['last_message_id'].toString()),
          lastPinTimestamp: row['last_pin_timestamp'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(row['last_pin_timestamp'].toString()),
                  isUtc: true,
                ),
        );
      }
      if (type == 'voice' || type == 'stage') {
        if (type == 'voice') {
          return _FixtureGuildVoiceChannel(
            gateway: gateway,
            id: id,
            manager: this,
            guildId: guildId,
            name: row['name'].toString(),
            parentId: parent,
            position: (_asNum(row['position']) ?? 0).toInt(),
            isNsfw: row['nsfw'] == true,
            permissionOverwrites: _fixtureOverwrites(row),
            bitrate: 64000,
            userLimit: 0,
            rtcRegion: null,
            videoQualityMode: VideoQualityMode.auto,
            rateLimitPerUser: Duration(
              seconds: (_asNum(row['slowmode']) ?? 0).toInt(),
            ),
            lastMessageId: row['last_message_id'] == null
                ? null
                : Snowflake.parse(row['last_message_id'].toString()),
            lastPinTimestamp: row['last_pin_timestamp'] == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(
                    int.parse(row['last_pin_timestamp'].toString()),
                    isUtc: true,
                  ),
          );
        }
        return _FixtureGuildStageChannel(
          gateway: gateway,
          id: id,
          manager: this,
          guildId: guildId,
          name: row['name'].toString(),
          parentId: parent,
          position: (_asNum(row['position']) ?? 0).toInt(),
          isNsfw: row['nsfw'] == true,
          permissionOverwrites: _fixtureOverwrites(row),
          bitrate: 64000,
          userLimit: 0,
          rtcRegion: null,
          videoQualityMode: VideoQualityMode.auto,
          rateLimitPerUser: Duration(
            seconds: (_asNum(row['slowmode']) ?? 0).toInt(),
          ),
          lastMessageId: row['last_message_id'] == null
              ? null
              : Snowflake.parse(row['last_message_id'].toString()),
          lastPinTimestamp: row['last_pin_timestamp'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(row['last_pin_timestamp'].toString()),
                  isUtc: true,
                ),
        );
      }
      if (type == 'forum') {
        return ForumChannel(
          id: id,
          manager: this,
          guildId: guildId,
          name: row['name'].toString(),
          topic: row['topic']?.toString(),
          parentId: parent,
          position: (_asNum(row['position']) ?? 0).toInt(),
          isNsfw: row['nsfw'] == true,
          permissionOverwrites: _fixtureOverwrites(row),
          defaultLayout: ForumLayout(0),
          rateLimitPerUser: Duration(
            seconds: (_asNum(row['slowmode']) ?? 0).toInt(),
          ),
          lastThreadId: null,
          lastPinTimestamp: row['last_pin_timestamp'] == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  int.parse(row['last_pin_timestamp'].toString()),
                  isUtc: true,
                ),
          flags: ChannelFlags(0),
          availableTags: const [],
          defaultReaction: null,
          defaultSortOrder: null,
          defaultAutoArchiveDuration: const Duration(days: 1),
          defaultThreadRateLimitPerUser: null,
        );
      }
      if (type != 'text') {
        throw StateError('Unsupported sandbox channel type: $type');
      }
      return _FixtureGuildTextChannel(
        gateway: gateway,
        id: id,
        manager: this,
        guildId: guildId,
        name: row['name'].toString(),
        topic: row['topic']?.toString(),
        parentId: parent,
        position: (_asNum(row['position']) ?? 0).toInt(),
        isNsfw: row['nsfw'] == true,
        rateLimitPerUser: Duration(
          seconds: (_asNum(row['slowmode']) ?? 0).toInt(),
        ),
        defaultAutoArchiveDuration: const Duration(days: 1),
        defaultThreadRateLimitPerUser: null,
        lastMessageId: row['last_message_id'] == null
            ? null
            : Snowflake.parse(row['last_message_id'].toString()),
        lastPinTimestamp: row['last_pin_timestamp'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (_asNum(row['last_pin_timestamp']) ?? 0).toInt(),
                isUtc: true,
              ),
        permissionOverwrites: _fixtureOverwrites(row),
      );
    }).toList();
  }

  @override
  Future<Channel> fetch(Snowflake id) async {
    gateway.requests.add({'operation': 'channels.fetch', 'channel_id': '$id'});
    final guilds = gateway.fixtures['guilds'];
    if (guilds is! Map || guilds.isEmpty) {
      final error = 'Missing sandbox channel fixture';
      gateway.errors.add(error);
      throw StateError(error);
    }
    for (final rawGuildId in guilds.keys) {
      final guildId = Snowflake.parse(rawGuildId.toString());
      for (final channel in read(guildId)) {
        if (channel.id == id) return channel;
      }
      final threads = (guilds[rawGuildId] as Map)['threads'];
      if (threads is List) {
        for (final row in threads) {
          final thread = _FixtureThread(
            Map<String, dynamic>.from(row as Map),
            guildId,
            gateway,
          );
          if (thread.id == id) return thread;
        }
      }
    }
    throw const DiscordEntityNotFound();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox channel write denied');
}

class _FixtureGuildTextChannel extends GuildTextChannel {
  _FixtureGuildTextChannel({
    required this.gateway,
    required super.id,
    required super.manager,
    required super.guildId,
    required super.name,
    required super.topic,
    required super.parentId,
    required super.position,
    required super.isNsfw,
    required super.permissionOverwrites,
    required super.defaultAutoArchiveDuration,
    required super.defaultThreadRateLimitPerUser,
    required super.rateLimitPerUser,
    required super.lastMessageId,
    required super.lastPinTimestamp,
  });
  final EntityFixtureGateway gateway;
  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
}

class _FixtureGuildAnnouncementChannel extends GuildAnnouncementChannel {
  _FixtureGuildAnnouncementChannel({
    required this.gateway,
    required super.id,
    required super.manager,
    required super.guildId,
    required super.name,
    required super.topic,
    required super.parentId,
    required super.position,
    required super.isNsfw,
    required super.permissionOverwrites,
    required super.defaultAutoArchiveDuration,
    required super.defaultThreadRateLimitPerUser,
    required super.rateLimitPerUser,
    required super.lastMessageId,
    required super.lastPinTimestamp,
  });
  final EntityFixtureGateway gateway;
  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
}

class _FixtureGuildVoiceChannel extends GuildVoiceChannel {
  _FixtureGuildVoiceChannel({
    required this.gateway,
    required super.id,
    required super.manager,
    required super.guildId,
    required super.name,
    required super.parentId,
    required super.position,
    required super.isNsfw,
    required super.permissionOverwrites,
    required super.bitrate,
    required super.userLimit,
    required super.rtcRegion,
    required super.videoQualityMode,
    required super.rateLimitPerUser,
    required super.lastMessageId,
    required super.lastPinTimestamp,
  });
  final EntityFixtureGateway gateway;
  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
}

class _FixtureGuildStageChannel extends GuildStageChannel {
  _FixtureGuildStageChannel({
    required this.gateway,
    required super.id,
    required super.manager,
    required super.guildId,
    required super.name,
    required super.parentId,
    required super.position,
    required super.isNsfw,
    required super.permissionOverwrites,
    required super.bitrate,
    required super.userLimit,
    required super.rtcRegion,
    required super.videoQualityMode,
    required super.rateLimitPerUser,
    required super.lastMessageId,
    required super.lastPinTimestamp,
  });
  final EntityFixtureGateway gateway;
  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
}

class _FixtureThread implements Thread {
  @override
  Duration? get rateLimitPerUser =>
      Duration(seconds: (_asNum(row['slowmode']) ?? 0).toInt());
  @override
  int get position => 0;
  _FixtureThread(this.row, this.guildId, this.gateway);
  final EntityFixtureGateway gateway;
  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
  @override
  Snowflake? get lastMessageId => row['last_message_id'] == null
      ? null
      : Snowflake.parse(row['last_message_id'].toString());
  @override
  DateTime? get lastPinTimestamp => row['last_pin_timestamp'] == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(
          int.parse(row['last_pin_timestamp'].toString()),
          isUtc: true,
        );
  @override
  final Snowflake guildId;
  @override
  ChannelType get type => switch (row['type']?.toString()) {
    'private_thread' || 'privateThread' || '12' => ChannelType.privateThread,
    'announcement_thread' ||
    'announcementThread' ||
    '10' => ChannelType.announcementThread,
    _ => ChannelType.publicThread,
  };
  @override
  String get name => row['name']?.toString() ?? 'thread-$id';
  @override
  bool get isNsfw => row['nsfw'] == true;
  final Map<String, dynamic> row;
  @override
  Snowflake get id => Snowflake.parse(row['id'].toString());
  @override
  Snowflake? get parentId => row['parent_id'] == null
      ? null
      : Snowflake.parse(row['parent_id'].toString());
  @override
  bool get isArchived => row['archived'] == true;
  @override
  bool get isLocked => row['locked'] == true;
  @override
  Snowflake get ownerId => Snowflake.parse((row['owner_id'] ?? 0).toString());
  @override
  int get messageCount => int.parse((row['message_count'] ?? 0).toString());
  @override
  int get approximateMemberCount =>
      int.parse((row['member_count'] ?? 0).toString());
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox thread operation denied');
}

class _FixtureTextChannel extends PartialTextChannel {
  _FixtureTextChannel(this.gateway, Snowflake id, ChannelManager manager)
    : super(id: id, manager: manager);
  final EntityFixtureGateway gateway;

  @override
  MessageManager get messages => _FixtureMessages(gateway, id);
}

class _FixtureMessages implements MessageManager {
  _FixtureMessages(this.gateway, this.channelId);
  final EntityFixtureGateway gateway;
  @override
  final Snowflake channelId;

  @override
  Future<List<User>> fetchReactions(
    Snowflake id,
    ReactionBuilder emoji, {
    Snowflake? after,
    int? limit,
  }) async {
    gateway.requests.add({
      'operation': 'messages.fetchReactions',
      'channel_id': '$channelId',
      'message_id': '$id',
      'emoji': emoji.build(),
      if (after != null) 'after': '$after',
      if (limit != null) 'limit': '$limit',
    });
    final messages = gateway.fixtures['messages'];
    final channel = messages is Map ? messages['$channelId'] : null;
    final raw = channel is Map ? channel['$id'] : null;
    if (raw is! Map) throw StateError('Reaction message fixture is required.');
    final reactions = raw['reactions'] ?? const [];
    if (reactions is! List) {
      throw StateError('Reaction list fixture is required.');
    }
    final ids = <int>{};
    for (final value in reactions) {
      if (value is! Map) throw StateError('Invalid reaction fixture.');
      final matches = emoji.id != null
          ? value['id']?.toString() == '${emoji.id}'
          : (value['id'] == null || value['id'].toString() == '0') &&
                value['emoji']?.toString() == emoji.name;
      if (!matches) continue;
      final users = value['users'];
      if (users is! List) {
        throw StateError('Reaction users fixture is required.');
      }
      for (final rawId in users) {
        final userId = int.tryParse(rawId.toString());
        if (userId == null || userId <= 0) {
          throw StateError('Invalid reaction user fixture.');
        }
        if (after == null || userId > after.value) ids.add(userId);
      }
    }
    final sorted = ids.toList()..sort();
    final users = <User>[];
    for (final user in sorted.take(limit ?? 25)) {
      users.add(await _Users(gateway).fetch(Snowflake(user)));
    }
    return users;
  }

  @override
  Future<Message> fetch(Snowflake id) async {
    gateway.requests.add({
      'operation': 'messages.fetch',
      'channel_id': '$channelId',
      'message_id': '$id',
    });
    final messages = gateway.fixtures['messages'];
    if (messages is! Map) {
      final error = 'Missing sandbox message fixture';
      gateway.errors.add(error);
      throw StateError(error);
    }
    final channelMessages = messages[channelId.toString()];
    final raw = channelMessages is Map ? channelMessages[id.toString()] : null;
    if (raw is! Map) {
      throw StateError('Message $id is absent from sandbox fixture');
    }
    return _FixtureMessage(
      id,
      channelId,
      raw['content']?.toString() ?? '',
      _FixtureMessageAuthor(
        Snowflake.parse(raw['author_id'].toString()),
        raw['author_name']?.toString() ?? '',
      ),
      (raw['attachments'] as List? ?? const [])
          .map((url) => _FixtureAttachment(Uri.parse(url.toString())))
          .toList(),
      (raw['reactions'] as List? ?? const []).map((rawReaction) {
        final row = Map<String, dynamic>.from(rawReaction as Map);
        return _FixtureReaction(
          (_asNum(row['count']) ?? 0).toInt(),
          _FixtureEmoji(
            Snowflake(int.tryParse(row['id']?.toString() ?? '') ?? 0),
            row['emoji']?.toString() ?? '',
          ),
        );
      }).toList(),
      (raw['embeds'] as List? ?? const [])
          .map(
            (rawEmbed) =>
                _readEmbed(Map<String, dynamic>.from(rawEmbed as Map)),
          )
          .toList(),
      raw,
      this,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox message write denied');
}

class _FixtureMessage implements Message {
  _FixtureMessage(
    this.id,
    this.channelId,
    this.content,
    this.author,
    this.attachments,
    this.reactions,
    this.embeds,
    this.row,
    this.fixtureManager,
  );
  final Map row;
  final MessageManager fixtureManager;
  @override
  List<Component>? get components => (row['components'] as List?)
      ?.map((raw) => _fixtureComponent(Map<String, dynamic>.from(raw as Map)))
      .toList();

  @override
  DateTime? get editedTimestamp => row['edited_timestamp'] == null
      ? null
      : DateTime.parse(row['edited_timestamp'].toString());
  @override
  MessageType get type => row['type'] == 'reply'
      ? MessageType.reply
      : MessageType((row['type'] as num?)?.toInt() ?? 0);
  @override
  MessageReference? get reference {
    final raw = row['message_reference'];
    if (raw is! Map) return null;
    return MessageReference(
      manager: fixtureManager,
      type: MessageReferenceType.defaultType,
      messageId: raw['message_id'] == null
          ? null
          : Snowflake.parse(raw['message_id'].toString()),
      channelId: raw['channel_id'] == null
          ? channelId
          : Snowflake.parse(raw['channel_id'].toString()),
      guildId: raw['guild_id'] == null
          ? null
          : Snowflake.parse(raw['guild_id'].toString()),
    );
  }

  @override
  final Snowflake id;
  @override
  final Snowflake channelId;
  @override
  final String content;
  @override
  final MessageAuthor author;
  @override
  final List<Attachment> attachments;
  @override
  final List<Reaction> reactions;
  @override
  final List<Embed> embeds;
  @override
  DateTime get timestamp => DateTime.utc(2025);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox message operation denied');
}

Embed _readEmbed(Map<String, dynamic> raw) {
  final rawFooter = raw['footer'];
  final footer = (rawFooter is Map ? rawFooter['text'] : rawFooter)?.toString();
  final rawImage = raw['image'];
  final image = (rawImage is Map ? rawImage['url'] : rawImage)?.toString();
  final color = raw['color'];
  return Embed(
    title: raw['title']?.toString(),
    type: EmbedType.rich,
    description: raw['description']?.toString(),
    url: null,
    timestamp: raw['timestamp'] == null
        ? null
        : DateTime.parse(raw['timestamp'].toString()),
    color: color == null
        ? null
        : DiscordColor(
            color is num
                ? color.toInt()
                : int.parse(color.toString().replaceFirst('#', ''), radix: 16),
          ),
    footer: footer == null
        ? null
        : EmbedFooter(text: footer, iconUrl: null, proxiedIconUrl: null),
    image: image == null
        ? null
        : EmbedImage(
            url: Uri.parse(image),
            proxiedUrl: null,
            height: null,
            width: null,
            flags: null,
            contentType: null,
            placeholder: null,
            placeholderVersion: null,
            description: null,
          ),
    thumbnail: null,
    video: null,
    provider: null,
    author: null,
    fields: null,
    flags: null,
  );
}

class _FixtureAttachment implements Attachment {
  _FixtureAttachment(this.url);
  @override
  final Uri url;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox attachment operation denied');
}

class _FixtureReaction implements Reaction {
  _FixtureReaction(this.count, this.emoji);
  @override
  final int count;
  @override
  final PartialEmoji emoji;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox reaction operation denied');
}

class _FixtureEmoji implements Emoji {
  _FixtureEmoji(this.id, this.name);
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox emoji operation denied');
}

class _FixtureMessageAuthor implements MessageAuthor {
  _FixtureMessageAuthor(this.id, this.username);
  @override
  final Snowflake id;
  @override
  final String username;
  @override
  String? get avatarHash => null;
  @override
  CdnAsset? get avatar => null;
}

class _Members implements MemberManager {
  _Members(this.gateway, this.guildId);
  final EntityFixtureGateway gateway;
  @override
  NyxxGateway get client => gateway;
  @override
  final Snowflake guildId;

  @override
  Future<Member> get(Snowflake id) => fetch(id);

  @override
  Future<List<Member>> list({int? limit, Snowflake? after}) async {
    gateway.requests.add({
      'operation': 'members.list',
      'guild_id': '$guildId',
      if (after != null) 'after': '$after',
    });
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    final members = guild is Map ? guild['members'] : null;
    if (members is! Map) {
      throw StateError('Member list requires guild members fixtures');
    }
    final ids =
        members.keys
            .map((raw) {
              final text = raw.toString();
              final id = RegExp(r'^[0-9]+$').hasMatch(text)
                  ? int.tryParse(text)
                  : null;
              if (id == null || id <= 0) {
                throw StateError('Invalid sandbox member ID: $text');
              }
              return id;
            })
            .where((id) => after == null || id > after.value)
            .toList()
          ..sort();
    final selected = limit == null ? ids : ids.take(limit);
    return Future.wait(selected.map((id) => fetch(Snowflake(id))));
  }

  @override
  Future<List<Member>> search(String query, {int? limit}) async {
    gateway.requests.add({
      'operation': 'members.search',
      'guild_id': '$guildId',
      'query': query,
    });
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    final members = guild is Map ? guild['members'] : null;
    final users = gateway.fixtures['users'];
    if (members is! Map || users is! Map) {
      throw StateError('Member search requires members and users fixtures');
    }
    final matches = <Member>[];
    for (final entry in members.entries) {
      final user = users[entry.key.toString()];
      final member = entry.value;
      if (user is! Map || member is! Map) continue;
      final username = user['username']?.toString() ?? '';
      final nickname = member['nick']?.toString() ?? '';
      if (username.toLowerCase().contains(query.toLowerCase()) ||
          nickname.toLowerCase().contains(query.toLowerCase())) {
        matches.add(await fetch(Snowflake.parse(entry.key.toString())));
        if (limit != null && matches.length >= limit) break;
      }
    }
    return matches;
  }

  @override
  Future<Member> fetch(Snowflake id) async {
    gateway.requests.add({
      'operation': 'members.fetch',
      'guild_id': '$guildId',
      'user_id': '$id',
    });
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    final members = guild is Map ? guild['members'] : null;
    if (members is! Map) {
      final error = 'Missing sandbox member fixture for guild $guildId';
      gateway.errors.add(error);
      throw StateError(error);
    }
    final raw = members[id.toString()];
    if (raw is! Map) {
      throw const DiscordEntityNotFound();
    }
    final row = Map<String, dynamic>.from(raw);
    return Member(
      id: id,
      manager: this,
      user:
          (gateway.fixtures['users'] as Map?)?.containsKey(id.toString()) ==
              true
          ? await _Users(gateway).fetch(id)
          : null,
      nick: row['nick']?.toString(),
      avatarHash: row['avatar']?.toString(),
      bannerHash: null,
      roleIds: (row['roles'] as List? ?? const [])
          .map((roleId) => Snowflake.parse(roleId.toString()))
          .toList(),
      joinedAt: row['joined_at'] == null
          ? DateTime.utc(2025)
          : DateTime.parse(row['joined_at'].toString()),
      premiumSince: row['premium_since'] == null
          ? null
          : DateTime.parse(row['premium_since'].toString()),
      isDeaf: false,
      isMute: false,
      flags: const MemberFlags(0),
      isPending: false,
      permissions: row['permissions'] == null
          ? null
          : Permissions(int.parse(row['permissions'].toString())),
      communicationDisabledUntil:
          (row['communication_disabled_until'] ?? row['timeout_until']) == null
          ? null
          : DateTime.parse(
              (row['communication_disabled_until'] ?? row['timeout_until'])
                  .toString(),
            ),
      avatarDecorationData: null,
      avatarDecorationHash: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox member write denied');
}

class _Roles implements RoleManager {
  _Roles(this.gateway, this.guildId);
  final EntityFixtureGateway gateway;
  @override
  final Snowflake guildId;
  List<Role> read() {
    final guild = (gateway.fixtures['guilds'] as Map?)?[guildId.toString()];
    if (guild is! Map || guild['roles'] is! List) {
      final error = 'Missing sandbox role fixture for guild $guildId';
      gateway.errors.add(error);
      throw StateError(error);
    }
    return (guild['roles'] as List).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      final color = DiscordColor((_asNum(row['color']) ?? 0).toInt());
      return Role(
        id: Snowflake.parse(row['id'].toString()),
        manager: this,
        name: row['name'].toString(),
        color: color,
        colors: RoleColors(primary: color, secondary: null, tertiary: null),
        isHoisted: row['hoist'] == true,
        iconHash: null,
        unicodeEmoji: null,
        position: (_asNum(row['position']) ?? 0).toInt(),
        permissions: Permissions(
          int.parse((row['permissions'] ?? '0').toString()),
        ),
        isMentionable: row['mentionable'] == true,
        tags: row['managed'] == true
            ? RoleTags(
                botId: null,
                integrationId: Snowflake(1),
                isPremiumSubscriber: false,
                subscriptionListingId: null,
                isAvailableForPurchase: false,
                isLinkedRole: false,
              )
            : null,
        flags: RoleFlags(0),
      );
    }).toList();
  }

  @override
  Future<List<Role>> list() async {
    gateway.requests.add({'operation': 'roles.list', 'guild_id': '$guildId'});
    return read();
  }

  @override
  Future<Role> fetch(Snowflake id) async {
    gateway.requests.add({
      'operation': 'roles.fetch',
      'guild_id': '$guildId',
      'role_id': '$id',
    });
    return read().firstWhere(
      (role) => role.id == id,
      orElse: () => throw StateError('Role $id is absent from fixture'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox role write denied');
}

List<PermissionOverwrite> _fixtureOverwrites(Map<String, dynamic> channel) {
  final raw = channel['permission_overwrites'];
  if (raw == null) return const [];
  if (raw is! List) throw StateError('Invalid sandbox permission overwrites.');
  int mask(Object? value) {
    final parsed = int.tryParse(value?.toString() ?? '0');
    if (parsed == null || parsed < 0) {
      throw StateError('Invalid sandbox permission mask.');
    }
    return parsed;
  }

  return List.unmodifiable(
    raw.map((entry) {
      final row = Map<String, dynamic>.from(entry as Map);
      final type = switch (row['type']) {
        0 || '0' || 'role' => PermissionOverwriteType.role,
        1 || '1' || 'member' => PermissionOverwriteType.member,
        _ => throw StateError('Invalid sandbox permission overwrite type.'),
      };
      return PermissionOverwrite(
        id: Snowflake.parse(row['id'].toString()),
        type: type,
        allow: Permissions(mask(row['allow'])),
        deny: Permissions(mask(row['deny'])),
      );
    }),
  );
}

Component _fixtureComponent(Map<String, dynamic> raw) {
  final id = (raw['id'] as num?)?.toInt() ?? 0;
  final type = ComponentType((raw['type'] as num).toInt());
  Emoji? emoji(dynamic value) {
    if (value is! Map) return null;
    return _FixtureEmoji(
      value['id'] == null
          ? Snowflake.zero
          : Snowflake.parse(value['id'].toString()),
      value['name']?.toString() ?? '',
    );
  }

  if (type == ComponentType.actionRow) {
    return ActionRowComponent(
      id: id,
      components: (raw['components'] as List)
          .map(
            (child) =>
                _fixtureComponent(Map<String, dynamic>.from(child as Map)),
          )
          .toList(),
    );
  }
  if (type == ComponentType.button) {
    return ButtonComponent(
      id: id,
      style: ButtonStyle((raw['style'] as num).toInt()),
      label: raw['label']?.toString(),
      emoji: emoji(raw['emoji']),
      customId: raw['custom_id']?.toString(),
      skuId: raw['sku_id'] == null
          ? null
          : Snowflake.parse(raw['sku_id'].toString()),
      url: raw['url'] == null ? null : Uri.parse(raw['url'].toString()),
      isDisabled: raw['disabled'] as bool?,
    );
  }
  if (const [
    ComponentType.stringSelect,
    ComponentType.userSelect,
    ComponentType.roleSelect,
    ComponentType.mentionableSelect,
    ComponentType.channelSelect,
  ].contains(type)) {
    return SelectMenuComponent(
      id: id,
      type: type,
      customId: raw['custom_id'].toString(),
      options: (raw['options'] as List?)
          ?.map(
            (option) => SelectMenuOption(
              label: option['label'].toString(),
              value: option['value'].toString(),
              description: option['description']?.toString(),
              emoji: emoji(option['emoji']),
              isDefault: option['default'] as bool?,
            ),
          )
          .toList(),
      channelTypes: (raw['channel_types'] as List?)
          ?.map((v) => ChannelType((v as num).toInt()))
          .toList(),
      placeholder: raw['placeholder']?.toString(),
      defaultValues: (raw['default_values'] as List?)
          ?.map(
            (v) => SelectMenuDefaultValue(
              id: Snowflake.parse(v['id'].toString()),
              type: SelectMenuDefaultValueType(v['type'].toString()),
            ),
          )
          .toList(),
      minValues: raw['min_values'] as int?,
      maxValues: raw['max_values'] as int?,
      isDisabled: raw['disabled'] as bool?,
      isRequired: raw['required'] as bool?,
    );
  }
  return UnknownComponent(type: type, id: id);
}
