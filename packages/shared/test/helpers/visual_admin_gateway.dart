import 'package:nyxx/nyxx.dart';

// Recording Discord for the parity tests of the poll / voice / AutoMod / guild
// settings / onboarding blocks (wave 9b). The bot (id 500) owns role 63 whose
// permission mask is configurable; every write is recorded in `writes`, in
// order, so the historical block functions and the native engine can be
// compared over the same simulated Discord.

class AdminRole implements Role {
  AdminRole(int id, int mask)
    : id = Snowflake(id),
      permissions = Permissions(mask);
  @override
  final Snowflake id;
  @override
  final Permissions permissions;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminMember implements Member {
  AdminMember(this.roleIds);
  @override
  final List<Snowflake> roleIds;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminMembers implements MemberManager {
  AdminMembers(this.gateway);
  final AdminGateway gateway;
  @override
  Future<Member> get(Snowflake id) async =>
      AdminMember(id == Snowflake(500) ? [Snowflake(63)] : <Snowflake>[]);
  @override
  Future<Member> update(
    Snowflake id,
    MemberUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('updateMember', {
      'user': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return get(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminRule implements AutoModerationRule {
  AdminRule(this.gateway, int id, this.name, {this.isEnabled = true})
    : id = Snowflake(id);
  final AdminGateway gateway;
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  final bool isEnabled;
  @override
  TriggerType get triggerType => TriggerType.keyword;
  @override
  Future<AutoModerationRule> update(
    UpdateBuilder<AutoModerationRule> builder, {
    String? auditLogReason,
  }) async {
    gateway.record('updateRule', {
      'id': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminAutoMod implements AutoModerationManager {
  AdminAutoMod(this.gateway);
  final AdminGateway gateway;
  @override
  Future<List<AutoModerationRule>> list() async => gateway.rules;
  @override
  Future<AutoModerationRule> create(
    AutoModerationRuleBuilder builder, {
    String? auditLogReason,
  }) async {
    final payload = builder.build();
    gateway.record('createRule', {
      'payload': payload,
      'reason': auditLogReason,
    });
    return AdminRule(gateway, 950, payload['name'].toString());
  }

  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    gateway.record('deleteRule', {'id': '$id', 'reason': auditLogReason});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminOption implements OnboardingPromptOption {
  @override
  Snowflake get id => Snowflake(3);
  @override
  String get title => 'Gamer';
  @override
  String? get description => null;
  @override
  List<Snowflake> get channelIds => [Snowflake(30)];
  @override
  List<Snowflake> get roleIds => [Snowflake(64)];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminPrompt implements OnboardingPrompt {
  @override
  Snowflake get id => Snowflake(2);
  @override
  String get title => 'Pick';
  @override
  OnboardingPromptType get type => OnboardingPromptType.multipleChoice;
  @override
  bool get isRequired => true;
  @override
  bool get isSingleSelect => false;
  @override
  bool get isInOnboarding => true;
  @override
  List<OnboardingPromptOption> get options => [AdminOption()];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminOnboarding implements Onboarding {
  AdminOnboarding(this.isEnabled);
  @override
  final bool isEnabled;
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  List<Snowflake> get defaultChannelIds => [Snowflake(30)];
  @override
  OnboardingMode get mode => OnboardingMode.defaultMode;
  @override
  List<OnboardingPrompt> get prompts => [AdminPrompt()];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminGuild implements Guild {
  AdminGuild(this.gateway, this.id, {this.name = 'Guild', this.description});
  final AdminGateway gateway;
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  final String? description;
  @override
  Snowflake get ownerId => Snowflake(gateway.botOwnsGuild ? 500 : 999);
  @override
  List<Role> get roleList => [
    AdminRole(10, 0),
    AdminRole(63, gateway.permissions),
  ];
  @override
  MemberManager get members => AdminMembers(gateway);
  @override
  AutoModerationManager get autoModerationRules => AdminAutoMod(gateway);
  @override
  Future<Onboarding> fetchOnboarding() async {
    gateway.record('fetchOnboarding', {});
    return AdminOnboarding(gateway.onboardingEnabled);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminMessage implements Message {
  AdminMessage(int id) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminMessages implements MessageManager {
  AdminMessages(this.gateway, this.channel);
  final AdminGateway gateway;
  final Snowflake channel;
  @override
  Future<Message> endPoll(Snowflake id) async {
    gateway.record('endPoll', {'channel': '$channel', 'message': '$id'});
    return AdminMessage(id.value);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminTextChannel implements TextChannel {
  AdminTextChannel(this.gateway, this.id);
  final AdminGateway gateway;
  @override
  final Snowflake id;
  @override
  MessageManager get messages => AdminMessages(gateway, id);
  @override
  Future<Message> sendMessage(MessageBuilder builder) async {
    gateway.record('sendMessage', {
      'channel': '$id',
      'payload': builder.build(),
    });
    return AdminMessage(800 + gateway.writes.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminVoiceChannel implements Channel {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminChannels implements ChannelManager {
  AdminChannels(this.gateway);
  final AdminGateway gateway;
  @override
  Future<Channel> get(Snowflake id) async {
    if (id == Snowflake(34)) return AdminVoiceChannel();
    if (id == Snowflake(404)) throw StateError('Unknown Channel');
    return AdminTextChannel(gateway, id);
  }

  @override
  Future<Channel> fetch(Snowflake id) => get(id);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminGuilds implements GuildManager {
  AdminGuilds(this.gateway);
  final AdminGateway gateway;
  @override
  Future<Guild> get(Snowflake id) async {
    if (id != Snowflake(10)) throw StateError('Unknown Guild');
    return AdminGuild(gateway, id);
  }

  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) => get(id);
  @override
  Future<Guild> update(
    Snowflake id,
    GuildUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    gateway.record('updateGuild', {
      'id': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    final name = builder.build()['name']?.toString() ?? 'Guild';
    return AdminGuild(gateway, id, name: name, description: 'desc');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminBot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AdminGateway implements NyxxGateway {
  AdminGateway({this.permissions = 8});

  /// Permission mask of the bot's role.
  int permissions;
  bool botOwnsGuild = false;
  bool onboardingEnabled = true;
  final rules = <AutoModerationRule>[];

  /// Every write, in order, for comparison between the two paths.
  final writes = <Map<String, Object?>>[];

  /// Failure to inject on the next write of the named operation.
  final failures = <String, Object>{};

  void record(String operation, Map<String, Object?> data) {
    writes.add({'operation': operation, ...data});
    final failure = failures.remove(operation);
    if (failure != null) throw failure;
  }

  @override
  ChannelManager get channels => AdminChannels(this);
  @override
  GuildManager get guilds => AdminGuilds(this);
  @override
  PartialUser get user => AdminBot();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
