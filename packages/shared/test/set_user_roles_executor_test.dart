import 'package:bot_creator_shared/services/bot_moderation_blocks.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Gateway implements NyxxGateway {
  _Gateway(this.guild);
  final _Guild guild;
  @override
  GuildManager get guilds => _GuildManager(guild);
  @override
  PartialUser get user => _User(Snowflake(500));
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected gateway access: ${invocation.memberName}');
}

class _User implements PartialUser {
  _User(this.id);
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected user access');
}

class _GuildManager implements GuildManager {
  _GuildManager(this.guild);
  final _Guild guild;
  @override
  Future<Guild> get(Snowflake id) async => guild;
  @override
  PartialGuild operator [](Snowflake id) => guild;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected guild manager access');
}

class _Guild implements Guild {
  _Guild(this.memberManager);
  final _Members memberManager;
  final _RoleManager roleManager = _RoleManager();
  @override
  Snowflake get id => Snowflake(10);
  @override
  Snowflake get ownerId => Snowflake(999);
  @override
  List<Role> get roleList => [
    _Role(Snowflake(10), const Permissions(0)),
    _Role(Snowflake(63), Permissions(Permissions.manageRoles.value)),
    _Role(Snowflake(60), const Permissions(0)),
    _Role(Snowflake(62), const Permissions(0)),
  ];
  @override
  MemberManager get members => memberManager;
  @override
  RoleManager get roles => roleManager;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected guild access: ${invocation.memberName}');
}

class _RoleManager implements RoleManager {
  Map<String, Object?>? created;
  Map<String, Object?>? updated;
  Snowflake? deleted;
  @override
  Future<Role> create(RoleBuilder builder, {String? auditLogReason}) async {
    created = builder.build();
    return _Role(Snowflake(70), const Permissions(0));
  }

  @override
  Future<Role> fetch(Snowflake id) async => _Role(id, const Permissions(0));
  @override
  Future<Role> update(
    Snowflake id,
    RoleUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    updated = builder.build();
    return _Role(id, const Permissions(0));
  }

  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    deleted = id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected role manager access');
}

class _Role implements Role {
  _Role(this.id, this.permissions);
  @override
  final Snowflake id;
  @override
  final Permissions permissions;
  @override
  int get position => id == Snowflake(63)
      ? 10
      : id == Snowflake(10)
      ? 0
      : 1;
  @override
  RoleTags? get tags => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected role access');
}

class _Members implements MemberManager {
  _Members(this.target);
  final _Target target;
  @override
  Future<Member> get(Snowflake id) async => _BotMember(id);
  @override
  PartialMember operator [](Snowflake id) => target;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected member manager access');
}

class _BotMember implements Member {
  _BotMember(this.id);
  @override
  final Snowflake id;
  @override
  List<Snowflake> get roleIds => id == Snowflake(500) ? [Snowflake(63)] : [];
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected bot member access');
}

class _Target implements PartialMember {
  @override
  Snowflake get id => Snowflake(20);
  List<Snowflake>? updatedRoles;
  String? reason;
  @override
  Future<Member> update(
    MemberUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    updatedRoles = builder.roleIds;
    reason = auditLogReason;
    return _BotMember(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
    'Unexpected target member access: ${invocation.memberName}',
  );
}

void main() {
  test(
    'setRoles replaces roles through the production member update API',
    () async {
      final target = _Target();
      final gateway = _Gateway(_Guild(_Members(target)));
      final result = await addRoleAction(
        gateway,
        guildId: Snowflake(10),
        payload: {
          'userId': '20',
          'setRoles': ['((opts.white))', '62'],
        },
        resolve: (value) => value == '((opts.white))' ? '60' : value,
      );
      expect(result['status'], 'set');
      expect(target.updatedRoles, [Snowflake(60), Snowflake(62)]);
      expect(target.reason, isNotEmpty);
    },
  );
  test('invalid replacement role rejects the update before writing', () async {
    final target = _Target();
    final gateway = _Gateway(_Guild(_Members(target)));
    final result = await addRoleAction(
      gateway,
      guildId: Snowflake(10),
      payload: {
        'userId': '20',
        'setRoles': ['60', 'invalid'],
      },
    );
    expect(result['error'], contains('invalid role ID'));
    expect(target.updatedRoles, isNull);
  });
  test('createRole uses the production role creation API', () async {
    final guild = _Guild(_Members(_Target()));
    final result = await addRoleAction(
      _Gateway(guild),
      guildId: Snowflake(10),
      payload: {
        'createNew': true,
        'name': 'Cor Verde',
        'color': '#00FF00',
        'hoist': true,
        'mentionable': false,
      },
    );
    expect(result['roleId'], '70');
    expect(guild.roleManager.created?['name'], 'Cor Verde');
    expect(
      (guild.roleManager.created?['colors'] as Map)['primary_color'],
      65280,
    );
    expect(guild.roleManager.created?['hoist'], true);
  });
  test('modifyRolePerms toggles the role permission mask', () async {
    final guild = _Guild(_Members(_Target()));
    final result = await addRoleAction(
      _Gateway(guild),
      guildId: Snowflake(10),
      payload: {
        'roleId': '60',
        'modifyPermissions': ['admin'],
      },
    );
    expect(result['status'], 'updated');
    expect(guild.roleManager.updated?['permissions'], '8');
  });
  test('deleteRole uses the production role deletion API', () async {
    final guild = _Guild(_Members(_Target()));
    final result = await removeRoleAction(
      _Gateway(guild),
      guildId: Snowflake(10),
      payload: {'roleId': '60', 'deleteRole': true},
    );
    expect(result['status'], 'deleted');
    expect(guild.roleManager.deleted, Snowflake(60));
  });
}
