import 'package:nyxx/nyxx.dart';
import '../engine/discord_entity_fetcher.dart';

/// Read-only Discord fixtures routed through the production entity fetcher.
/// Every unimplemented operation fails locally; no client is connected.
class EntityFixtureGateway implements NyxxGateway {
  EntityFixtureGateway(this.fixtures);
  final Map<String, dynamic> fixtures;
  final requests = <Map<String, String>>[];
  final errors = <String>[];
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
      bannerHash: null,
      accentColor: null,
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
      throw StateError('Guild $id is absent from sandbox fixture');
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
  @override
  Snowflake get ownerId {
    final guild = (gateway.fixtures['guilds'] as Map?)?[id.toString()];
    return Snowflake.parse((guild as Map?)?['owner_id']?.toString() ?? '0');
  }

  @override
  List<Role> get roleList => _Roles(gateway, id).read();
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
        user: null,
        requiresColons: true,
        isManaged: false,
        isAnimated: row['animated'] == true,
        isAvailable: true,
      );
    }).toList();
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
          permissionOverwrites: const [],
          position: (row['position'] as num? ?? 0).toInt(),
        );
      }
      if (type != 'text') {
        throw StateError('Unsupported sandbox channel type: $type');
      }
      return GuildTextChannel(
        id: id,
        manager: this,
        guildId: guildId,
        name: row['name'].toString(),
        topic: row['topic']?.toString(),
        parentId: parent,
        position: (row['position'] as num? ?? 0).toInt(),
        isNsfw: row['nsfw'] == true,
        rateLimitPerUser: Duration(
          seconds: (row['slowmode'] as num? ?? 0).toInt(),
        ),
        defaultAutoArchiveDuration: const Duration(days: 1),
        defaultThreadRateLimitPerUser: null,
        lastMessageId: row['last_message_id'] == null
            ? null
            : Snowflake.parse(row['last_message_id'].toString()),
        lastPinTimestamp: row['last_pin_timestamp'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                (row['last_pin_timestamp'] as num).toInt(),
                isUtc: true,
              ),
        permissionOverwrites: const [],
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
    }
    throw StateError('Channel $id is absent from fixture');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Sandbox channel write denied');
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
          (row['count'] as num? ?? 0).toInt(),
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
  );
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
  final footer = raw['footer']?.toString();
  final image = raw['image']?.toString();
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
  final Snowflake guildId;

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
            .map((id) => int.tryParse(id.toString()))
            .whereType<int>()
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
      avatarHash: null,
      bannerHash: null,
      roleIds: (row['roles'] as List? ?? const [])
          .map((roleId) => Snowflake.parse(roleId.toString()))
          .toList(),
      joinedAt: DateTime.utc(2025),
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
      communicationDisabledUntil: row['timeout_until'] == null
          ? null
          : DateTime.parse(row['timeout_until'].toString()),
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
      final color = DiscordColor((row['color'] as num? ?? 0).toInt());
      return Role(
        id: Snowflake.parse(row['id'].toString()),
        manager: this,
        name: row['name'].toString(),
        color: color,
        colors: RoleColors(primary: color, secondary: null, tertiary: null),
        isHoisted: row['hoist'] == true,
        iconHash: null,
        unicodeEmoji: null,
        position: (row['position'] as num? ?? 0).toInt(),
        permissions: Permissions(
          int.parse((row['permissions'] ?? '0').toString()),
        ),
        isMentionable: row['mentionable'] == true,
        tags: null,
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
