import 'package:nyxx/nyxx.dart';

// Fake Discord gateway recording role/member effects. Shared by the parity
// tests of visual actions: the historical executor and the native
// BotModerationService both end up here, so effects can be compared.
// (Same fixture as test/bot_moderation_service_test.dart.)

class FakeGateway implements NyxxGateway {
  final guild = FakeGuild();
  @override
  GuildManager get guilds => FakeGuildManager(guild);
  @override
  PartialUser get user => FakeUser();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

class FakeUser implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGuildManager implements GuildManager {
  FakeGuildManager(this.guild);
  final FakeGuild guild;
  @override
  Future<Guild> get(Snowflake id) async {
    guild.lookups++;
    return guild;
  }

  @override
  Future<List<Ban>> listBans(
    Snowflake id, {
    int? limit,
    Snowflake? after,
    Snowflake? before,
  }) async {
    guild.banCursors.add(after);
    if (guild.banListDelay != Duration.zero) {
      await Future<void>.delayed(guild.banListDelay);
    }
    if (guild.repeatBanPage) return guild.banPages.first;
    final index = guild.banPageIndex++;
    return index < guild.banPages.length ? guild.banPages[index] : [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeGuild implements Guild {
  final memberManager = FakeMembers();
  late final roleManager = FakeRoleManager(this);
  @override
  RoleManager get roles => roleManager;
  int lookups = 0;
  int permissions =
      Permissions.kickMembers.value | Permissions.banMembers.value;
  int botPosition = 10;
  int targetPosition = 1;
  int targetPermissions = 0;
  final extraRoles = <Role>[];
  RoleTags? targetTags;
  final banned = <Snowflake>[];
  final unbanned = <Snowflake>[];
  final banCursors = <Snowflake?>[];
  final banPages = <List<Ban>>[];
  int banPageIndex = 0;
  int unbanAttempts = 0;
  bool repeatBanPage = false;
  bool failUnban = false;
  Duration banListDelay = Duration.zero;
  String? reason;
  Duration? deleteDuration;
  @override
  Snowflake get id => Snowflake(10);
  @override
  Snowflake get ownerId => Snowflake(999);
  @override
  List<Role> get roleList => [
    FakeRole(10, 0, 0),
    FakeRole(63, botPosition, permissions),
    FakeRole(64, targetPosition, targetPermissions, targetTags),
    ...extraRoles,
  ];
  @override
  MemberManager get members => memberManager;
  @override
  Future<void> createBan(
    Snowflake userId, {
    Duration? deleteMessages,
    String? auditLogReason,
  }) async {
    banned.add(userId);
    reason = auditLogReason;
    deleteDuration = deleteMessages;
  }

  @override
  Future<void> deleteBan(Snowflake userId, {String? auditLogReason}) async {
    unbanAttempts++;
    if (failUnban) throw StateError('Discord refused unban');
    unbanned.add(userId);
    reason = auditLogReason;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRoleManager implements RoleManager {
  FakeRoleManager(this.guild);
  final FakeGuild guild;
  final writes = <Map<String, Object?>>[];
  Duration delay = Duration.zero;
  bool fail = false;
  @override
  Future<Role> create(RoleBuilder builder, {String? auditLogReason}) async {
    if (fail) throw StateError('Discord refused creation');
    writes.add({
      'operation': 'create',
      ...builder.build(),
      'reason': auditLogReason,
    });
    return FakeRole(65, 1, 0);
  }

  @override
  Future<Role> fetch(Snowflake id) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return guild.roleList.firstWhere((r) => r.id == id);
  }

  @override
  Future<Role> update(
    Snowflake id,
    RoleUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    if (fail) throw StateError('Discord refused update');
    writes.add({
      'operation': 'update',
      'id': '$id',
      ...builder.build(),
      'reason': auditLogReason,
    });
    return FakeRole(id.value, 1, 0);
  }

  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    if (fail) throw StateError('Discord refused deletion');
    writes.add({'operation': 'delete', 'id': '$id', 'reason': auditLogReason});
  }

  @override
  Future<List<Role>> updatePositions(
    Map<Snowflake, int> positions, {
    String? auditLogReason,
  }) async {
    writes.add({
      'operation': 'positions',
      'positions': positions.map((key, value) => MapEntry('$key', value)),
    });
    return guild.roleList;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRole implements Role {
  FakeRole(int id, this.position, int flags, [this.tags])
    : id = Snowflake(id),
      permissions = Permissions(flags);
  @override
  final Snowflake id;
  @override
  final int position;
  @override
  final Permissions permissions;
  @override
  final RoleTags? tags;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMembers implements MemberManager {
  final deleted = <Snowflake>[];
  final roleChanges = <Map<String, String?>>[];
  bool failRole = false;
  String? reason;
  Duration delay = Duration.zero;
  bool failDelete = false;
  int deleteAttempts = 0;
  final updates = <Map<String, Object?>>[];
  bool failUpdate = false;
  Object? targetError;
  bool targetSharesBotRole = false;
  int targetRoleId = 64;
  @override
  Future<Member> get(Snowflake id) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (id != Snowflake(500) && targetError != null) throw targetError!;
    return FakeMember(id, this);
  }

  @override
  PartialMember operator [](Snowflake id) => FakeMember(id, this);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMember implements Member {
  FakeMember(this.id, this.manager);
  @override
  final Snowflake id;
  @override
  final FakeMembers manager;
  @override
  List<Snowflake> get roleIds => [
    Snowflake(
      id == Snowflake(500) || manager.targetSharesBotRole
          ? 63
          : manager.targetRoleId,
    ),
  ];
  @override
  Future<Member> update(
    MemberUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    if (manager.failUpdate) throw StateError('Discord refused timeout');
    manager.updates.add({
      'userId': id.toString(),
      ...builder.build(),
      'reason': auditLogReason,
    });
    return this;
  }

  @override
  Future<void> addRole(Snowflake roleId, {String? auditLogReason}) async {
    if (manager.failRole) throw StateError('Discord refused role');
    manager.roleChanges.add({
      'operation': 'add',
      'user': '$id',
      'role': '$roleId',
      'reason': auditLogReason,
    });
  }

  @override
  Future<void> removeRole(Snowflake roleId, {String? auditLogReason}) async {
    if (manager.failRole) throw StateError('Discord refused role');
    manager.roleChanges.add({
      'operation': 'remove',
      'user': '$id',
      'role': '$roleId',
      'reason': auditLogReason,
    });
  }

  @override
  Future<void> delete({String? auditLogReason}) async {
    manager.deleteAttempts++;
    if (manager.failDelete) throw StateError('Discord refused');
    manager.deleted.add(id);
    manager.reason = auditLogReason;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
