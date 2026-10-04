import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'visual_discord_gateway.dart';
import 'variables_test_helpers.dart';
import 'visual_parity_harness.dart' show Outcome, SpyTranslator;

// Recording Discord for the parity tests of the webhook, emoji, member and
// invite blocks (wave 9a). Guild/member/permission reads come from the shared
// VisualGateway fixtures; webhooks, invites and guild emojis are simulated and
// record every write.

Map<String, dynamic> resourceFixtures({int permissions = 8}) {
  final data = visualFixtures(permissions: permissions);
  final guild = ((data['guilds'] as Map)['10'] as Map).cast<String, dynamic>();
  (data['guilds'] as Map)['10'] = guild;
  guild['members'] = <String, dynamic>{
    ...(guild['members'] as Map).cast<String, dynamic>(),
    '20': {
      'roles': <String>['64'],
      'nick': 'Twenty',
    },
  };
  data['users'] = {
    '500': {'username': 'bot'},
    '20': {'username': 'alice', 'global_name': 'Alice'},
    '222': {'username': 'bob'},
  };
  return data;
}

class FakeWebhook implements Webhook {
  FakeWebhook(this.id, this.name, {this.channelId, this.token, this.guildId});
  @override
  final Snowflake id;
  @override
  final String? name;
  @override
  final Snowflake? channelId;
  @override
  final Snowflake? guildId;
  @override
  final String? token;
  @override
  WebhookType get type => WebhookType.incoming;
  @override
  // Null on purpose: the blocks `jsonEncode` the webhook and a real `Uri`
  // is not encodable (historical behaviour, kept by the native path).
  Uri? get url => null;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWebhooks implements WebhookManager {
  FakeWebhooks(this.gateway);
  final ResourceGateway gateway;
  final known = {
    Snowflake(70): FakeWebhook(
      Snowflake(70),
      'hook',
      channelId: Snowflake(30),
      guildId: Snowflake(10),
      token: 'tok',
    ),
  };
  @override
  Future<Webhook> fetch(Snowflake id, {String? token}) async {
    gateway.record('fetchWebhook', {'id': '$id', 'token': token});
    final hook = known[id];
    if (hook == null) throw StateError('Unknown webhook $id');
    return hook;
  }

  @override
  Future<Webhook> update(
    Snowflake id,
    WebhookUpdateBuilder builder, {
    String? token,
    String? auditLogReason,
  }) async {
    gateway.record('updateWebhook', {
      'id': '$id',
      'payload': builder.build(),
      'token': token,
      'reason': auditLogReason,
    });
    return FakeWebhook(
      id,
      builder.name ?? 'hook',
      channelId: Snowflake(30),
      token: token,
    );
  }

  @override
  Future<void> delete(
    Snowflake id, {
    String? token,
    String? auditLogReason,
  }) async => gateway.record('deleteWebhook', {
    'id': '$id',
    'token': token,
    'reason': auditLogReason,
  });
  @override
  Future<List<Webhook>> fetchChannelWebhooks(Snowflake channelId) async {
    gateway.record('channelWebhooks', {'channel': '$channelId'});
    return known.values.toList();
  }

  @override
  Future<List<Webhook>> fetchGuildWebhooks(Snowflake guildId) async {
    gateway.record('guildWebhooks', {'guild': '$guildId'});
    return known.values.toList();
  }

  @override
  Future<Message?> execute(
    Snowflake id,
    MessageBuilder builder, {
    required String token,
    bool? wait,
    Snowflake? threadId,
    String? username,
    String? avatarUrl,
    String? threadName,
    List<Snowflake>? appliedTags,
    bool? withComponents,
  }) async {
    gateway.record('executeWebhook', {
      'id': '$id',
      'token': token,
      'wait': wait,
      'thread': '$threadId',
      'username': username,
      'avatar': avatarUrl,
      'payload': builder.build(),
    });
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePartialChannel implements PartialChannel {
  FakePartialChannel(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePartialGuild implements PartialGuild {
  FakePartialGuild(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvite implements Invite {
  FakeInvite(this.code, this.channel, this.guild, [this.expiresAt]);
  @override
  final String code;
  @override
  final PartialChannel channel;
  @override
  final PartialGuild? guild;
  @override
  final DateTime? expiresAt;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeInvites implements InviteManager {
  FakeInvites(this.gateway);
  final ResourceGateway gateway;
  @override
  Future<Invite> fetch(
    String code, {
    bool? withCounts,
    bool? withExpiration,
    Snowflake? scheduledEventId,
  }) async {
    gateway.record('fetchInvite', {'code': code});
    if (code != 'abc' && code != '12345')
      throw StateError('Unknown invite $code');
    return FakeInvite(
      code,
      FakePartialChannel(Snowflake(30)),
      FakePartialGuild(Snowflake(10)),
      DateTime.utc(2030, 1, 2),
    );
  }

  @override
  Future<Invite> delete(String code, {String? auditLogReason}) async {
    gateway.record('deleteInvite', {'code': code, 'reason': auditLogReason});
    return FakeInvite(
      code,
      FakePartialChannel(Snowflake(30)),
      FakePartialGuild(Snowflake(10)),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A text channel whose invites hit the recorder.
class InviteTextChannel extends VisualTextChannel {
  InviteTextChannel(super.base, ResourceChannels super.manager);
  @override
  Future<Invite> createInvite(
    InviteBuilder builder, {
    String? auditLogReason,
  }) async {
    (manager as ResourceChannels).resources.record('createInvite', {
      'channel': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return FakeInvite(
      'newcode',
      FakePartialChannel(id),
      FakePartialGuild(Snowflake(10)),
    );
  }
}

class ResourceChannels extends VisualChannels {
  ResourceChannels(this.resources) : super(resources);
  final ResourceGateway resources;
  @override
  Future<Channel> fetch(Snowflake id) async {
    final channel = await super.fetch(id);
    if (channel is VisualTextChannel) return InviteTextChannel(channel, this);
    return channel;
  }
}

class FakeEmoji implements GuildEmoji {
  FakeEmoji(this.id, this.name, {this.isAnimated = false});
  @override
  final Snowflake id;
  @override
  final String? name;
  @override
  final bool? isAnimated;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeEmojis implements GuildEmojiManager {
  FakeEmojis(this.gateway);
  final ResourceGateway gateway;
  @override
  Future<GuildEmoji> create(
    EmojiBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('createEmoji', {
      'name': builder.name,
      'bytes': builder.image.data.length,
      'roles': builder.roles.map((r) => '$r').toList(),
      'reason': auditLogReason,
    });
    return FakeEmoji(Snowflake(81), builder.name);
  }

  @override
  Future<GuildEmoji> update(
    Snowflake id,
    EmojiUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('updateEmoji', {
      'id': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return FakeEmoji(id, builder.name ?? 'old');
  }

  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async =>
      gateway.record('deleteEmoji', {'id': '$id', 'reason': auditLogReason});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The fixture guild (roles, owner, members) plus guild emojis.
class ResourceGuild implements Guild {
  ResourceGuild(this.inner, this.gateway);
  final Guild inner;
  final ResourceGateway gateway;
  @override
  Snowflake get id => inner.id;
  @override
  Snowflake get ownerId => inner.ownerId;
  @override
  List<Role> get roleList => inner.roleList;
  @override
  MemberManager get members => inner.members;
  @override
  GuildEmojiManager get emojis => FakeEmojis(gateway);
  @override
  List<GuildEmoji> get emojiList => [FakeEmoji(Snowflake(80), 'smile')];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ResourceGuilds extends VisualGuilds {
  ResourceGuilds(ResourceGateway super.gateway);
  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) async => ResourceGuild(
    await super.fetch(id, withCounts: withCounts),
    gateway as ResourceGateway,
  );
}

class ResourceGateway extends VisualGateway {
  ResourceGateway({super.data});
  late final FakeWebhooks webhookManager = FakeWebhooks(this);
  late final FakeInvites inviteManager = FakeInvites(this);
  late final ResourceChannels resourceChannels = ResourceChannels(this);
  late final ResourceGuilds resourceGuilds = ResourceGuilds(this);
  @override
  WebhookManager get webhooks => webhookManager;
  @override
  InviteManager get invites => inviteManager;
  @override
  ChannelManager get channels => resourceChannels;
  @override
  GuildManager get guilds => resourceGuilds;
}

/// Runs [actions] through the historical executors and the native engine over
/// the same recording Discord and compares effects, results, variables and
/// error. Returns the native outcome.
Future<Outcome<ResourceGateway>> resourceParity(
  List<Action> actions, {
  int permissions = 8,
  void Function(ResourceGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  Snowflake? fallbackChannelId,
  bool expectNative = true,
  int? nativePrograms,
}) async {
  Future<Outcome<ResourceGateway>> run(bool native) async {
    final gateway = ResourceGateway(
      data: resourceFixtures(permissions: permissions),
    );
    setup?.call(gateway);
    final values = <String, String>{
      'guild.id': '10',
      'bot.id': '500',
      ...?variables,
    };
    final spy = SpyTranslator();
    Map<String, String>? results;
    Object? error;
    try {
      results = await handleActions(
        gateway,
        null,
        actions: actions.map((a) => Action.fromJson(a.toJson())).toList(),
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: values,
        fallbackGuildId: guild ? Snowflake(10) : null,
        fallbackChannelId: fallbackChannelId,
        resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
        actionTranslator: native ? spy : const ActionTranslator.none(),
      );
    } catch (e) {
      error = e;
    }
    values.remove('execution.time');
    return Outcome<ResourceGateway>(
      gateway,
      results,
      values,
      error,
      spy.native,
      gateway.writes,
    );
  }

  final historical = await run(false);
  final native = await run(true);
  expect(historical.native, 0);
  if (nativePrograms != null) {
    expect(native.native, nativePrograms);
  } else if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  expect(native.effects, historical.effects, reason: 'effects');
  expect(native.results, historical.results, reason: 'results');
  expect(native.variables, historical.variables, reason: 'variables');
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}
