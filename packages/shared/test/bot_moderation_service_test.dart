import 'package:bot_creator_shared/actions/ban_user.dart';
import 'package:bot_creator_shared/actions/add_role.dart';
import 'package:bot_creator_shared/actions/remove_role.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'helpers/variables_test_helpers.dart';
import 'package:bot_creator_shared/actions/kick_user.dart';
import 'package:bot_creator_shared/actions/unban_user.dart';
import 'package:bot_creator_shared/actions/mute_user.dart';
import 'package:bot_creator_shared/actions/unmute_user.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/services/role_definition.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _NoHydration implements ActionExecutionPolicy {
  @override
  bool get allowDiscordHydration => false;
  @override
  void checkBudget() {}
  @override
  void record(Map<String, dynamic> frame) {}
  @override
  Future<bool> intercept({
    required Action action,
    required String resultKey,
    required Map<String, String> results,
    required Map<String, String> variables,
    required String Function(String) resolveValue,
  }) async => false;
}

class _Gateway implements NyxxGateway {
  final guild = _Guild();
  @override
  GuildManager get guilds => _GuildManager(guild);
  @override
  PartialUser get user => _User();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

class _User implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuildManager implements GuildManager {
  _GuildManager(this.guild);
  final _Guild guild;
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

class _Guild implements Guild {
  final memberManager = _Members();
  late final roleManager = _RoleManager(this);
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
    _Role(10, 0, 0),
    _Role(63, botPosition, permissions),
    _Role(64, targetPosition, targetPermissions, targetTags),
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

class _RoleManager implements RoleManager {
  _RoleManager(this.guild);
  final _Guild guild;
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
    return _Role(65, 1, 0);
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
    return _Role(id.value, 1, 0);
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

class _Role implements Role {
  _Role(int id, this.position, int flags, [this.tags])
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

class _Members implements MemberManager {
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
    return _Member(id, this);
  }

  @override
  PartialMember operator [](Snowflake id) => _Member(id, this);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Member implements Member {
  _Member(this.id, this.manager);
  @override
  final Snowflake id;
  @override
  final _Members manager;
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

class _BanUser implements User {
  _BanUser(int id, this.username) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final String username;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Ban _ban(int id, String username) =>
    Ban(reason: 'Spam', user: _BanUser(id, username));
List<Ban> _fullPage() => List.generate(1000, (i) => _ban(10000 + i, 'user$i'));

class _DiscordError implements HttpResponseError {
  _DiscordError(this.statusCode, this.errorCode);
  @override
  final int statusCode;
  @override
  final int errorCode;
  @override
  String toString({bool short = false}) => 'Discord error $errorCode';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DiscordBotModerationService _service(_Gateway gateway) =>
    DiscordBotModerationService(client: gateway, guildId: Snowflake(10));

void main() {
  for (final operation in [
    BotModerationOperation.kick,
    BotModerationOperation.ban,
    BotModerationOperation.timeout,
    BotModerationOperation.untimeout,
  ]) {
    test(
      '$operation refuses an older member role at the same numeric position',
      () async {
        final gateway = _Gateway();
        gateway.guild.permissions |= Permissions.moderateMembers.value;
        gateway.guild.extraRoles.add(_Role(62, 10, 0));
        gateway.guild.memberManager.targetRoleId = 62;
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(operation: operation, userId: '222'),
            budget: CommandExecutionBudget(),
          ),
          throwsStateError,
        );
        expect(gateway.guild.memberManager.deleted, isEmpty);
        expect(gateway.guild.banned, isEmpty);
        expect(gateway.guild.memberManager.updates, isEmpty);
      },
    );
  }

  for (final operation in [
    BotModerationOperation.kick,
    BotModerationOperation.ban,
    BotModerationOperation.timeout,
    BotModerationOperation.untimeout,
  ]) {
    test(
      '$operation accepts a lower role sharing the bot position using ID order',
      () async {
        final gateway = _Gateway();
        gateway.guild.permissions |= Permissions.moderateMembers.value;
        gateway.guild.targetPosition = 10;
        expect(
          await _service(gateway).moderate(
            BotModerationRequest(operation: operation, userId: '222'),
            budget: CommandExecutionBudget(),
          ),
          '222',
        );
      },
    );
  }
  for (final operation in [
    BotModerationOperation.addRole,
    BotModerationOperation.removeRole,
    BotModerationOperation.updateRole,
    BotModerationOperation.deleteRole,
    BotModerationOperation.setUserRoles,
  ]) {
    test(
      '$operation uses ID order when a role has the same numeric position',
      () async {
        final gateway = _Gateway()
          ..guild.permissions = Permissions.manageRoles.value;
        gateway.guild.targetPosition = 10;
        final result = await _service(gateway).moderate(
          BotModerationRequest(
            operation: operation,
            userId: '222',
            roleId: '64',
            roleDefinition: RoleDefinition(name: 'Updated'),
            roleReplacement: RoleReplacement([]),
          ),
          budget: CommandExecutionBudget(),
        );
        expect(
          result,
          operation == BotModerationOperation.updateRole ||
                  operation == BotModerationOperation.deleteRole
              ? '64'
              : '222',
        );
      },
    );
  }
  for (final operation in [
    BotModerationOperation.addRole,
    BotModerationOperation.removeRole,
    BotModerationOperation.updateRole,
    BotModerationOperation.deleteRole,
    BotModerationOperation.setUserRoles,
  ]) {
    test(
      '$operation rejects an older role at the same numeric position',
      () async {
        final gateway = _Gateway()
          ..guild.permissions = Permissions.manageRoles.value;
        gateway.guild.extraRoles.add(_Role(62, 10, 0));
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: operation,
              userId: '222',
              roleId: '62',
              roleDefinition: RoleDefinition(name: 'Never'),
              roleReplacement: RoleReplacement(['62']),
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsStateError,
        );
        expect(gateway.guild.roleManager.writes, isEmpty);
        expect(gateway.guild.memberManager.roleChanges, isEmpty);
        expect(gateway.guild.memberManager.updates, isEmpty);
      },
    );
  }

  test(
    'replacement snapshots IDs and writes a deduplicated role list once',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      gateway.guild.extraRoles.add(_Role(65, 2, 0));
      final roles = ['65', '65'];
      final replacement = RoleReplacement(roles);
      roles.clear();
      expect(() => replacement.roleIds.clear(), throwsUnsupportedError);
      expect(
        await _service(gateway).moderate(
          BotModerationRequest(
            operation: BotModerationOperation.setUserRoles,
            userId: '999',
            roleReplacement: replacement,
            useDefaultReason: false,
          ),
          budget: CommandExecutionBudget(),
        ),
        '999',
      );
      expect(gateway.guild.memberManager.updates.single['roles'], ['65']);
      expect(gateway.guild.memberManager.updates.single['reason'], isNull);
    },
  );
  for (final failure in [
    'permission',
    'invalidID',
    'everyone',
    'missingRole',
    'addHigh',
    'removeHigh',
    'removeManaged',
    'missingMember',
  ]) {
    test('role replacement blocks $failure before any SDK update', () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      gateway.guild.extraRoles.add(_Role(65, failure == 'addHigh' ? 11 : 2, 0));
      var roles = ['65'];
      if (failure == 'permission') gateway.guild.permissions = 0;
      if (failure == 'invalidID') roles = ['bad'];
      if (failure == 'everyone') roles = ['10'];
      if (failure == 'missingRole') roles = ['12345'];
      if (failure == 'removeHigh') gateway.guild.targetPosition = 11;
      if (failure == 'removeManaged') {
        gateway.guild.targetTags = RoleTags(
          botId: Snowflake(7),
          integrationId: null,
          isPremiumSubscriber: false,
          subscriptionListingId: null,
          isAvailableForPurchase: false,
          isLinkedRole: false,
        );
      }
      if (failure == 'missingMember') {
        gateway.guild.memberManager.targetError = StateError('Member absent');
      }
      await expectLater(
        _service(gateway).moderate(
          BotModerationRequest(
            operation: BotModerationOperation.setUserRoles,
            userId: '222',
            roleReplacement: RoleReplacement(roles),
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.guild.memberManager.updates, isEmpty);
    });
  }
  test(
    'visual replacement clears roles and preserves its default reason',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      final result = await addRoleAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': '222', 'setRoles': []},
      );
      expect(result['status'], 'set');
      expect(result['roleId'], '');
      expect(gateway.guild.memberManager.updates.single['roles'], isEmpty);
      expect(
        gateway.guild.memberManager.updates.single['reason'],
        'Set roles via BotCreator action',
      );
    },
  );
  test(
    'visual replacement receives handler budget and cannot write after delayed read',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      gateway.guild.memberManager.delay = const Duration(milliseconds: 60);
      await expectLater(
        handleActions(
          gateway,
          null,
          actions: [
            Action(
              type: BotCreatorActionType.addRole,
              payload: {
                'userId': '222',
                'setRoles': ['64'],
              },
            ),
          ],
          store: MemoryBotDataStore(),
          botId: 'bot',
          variables: {'guild.id': '10'},
          fallbackGuildId: Snowflake(10),
          resolveTemplate: (v) => v,
          executionPolicy: _NoHydration(),
          throwOnError: true,
          executionBudget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(gateway.guild.memberManager.updates, isEmpty);
    },
  );

  test(
    'SDK role definitions create, update only provided fields, toggle and delete',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      final service = _service(gateway);
      Future<String> perform(
        BotModerationOperation op, [
        RoleDefinition? fields,
        String role = '64',
      ]) => service.moderate(
        BotModerationRequest(
          operation: op,
          userId: '',
          roleId: role,
          roleDefinition: fields,
          useDefaultReason: false,
        ),
        budget: CommandExecutionBudget(),
      );
      expect(
        await perform(
          BotModerationOperation.createRole,
          RoleDefinition(name: 'Staff', color: 255, hoist: true),
        ),
        '65',
      );
      await perform(
        BotModerationOperation.updateRole,
        RoleDefinition(name: 'Renamed', mentionable: false),
      );
      gateway.guild.targetPermissions = Permissions.kickMembers.value;
      await perform(
        BotModerationOperation.updateRole,
        RoleDefinition(
          togglePermissions: [
            Permissions.kickMembers.value,
            Permissions.banMembers.value,
          ],
        ),
      );
      await perform(BotModerationOperation.deleteRole);
      final writes = gateway.guild.roleManager.writes;
      expect(writes[0], {
        'operation': 'create',
        'name': 'Staff',
        'colors': {'primary_color': 255},
        'hoist': true,
        'mentionable': false,
        'reason': null,
      });
      expect(writes[1], {
        'operation': 'update',
        'id': '64',
        'name': 'Renamed',
        'mentionable': false,
        'reason': null,
      });
      expect(writes[2]['permissions'], '${Permissions.banMembers.value}');
      expect(writes[3]['operation'], 'delete');
    },
  );
  test(
    'everyone permissions can be toggled but the role cannot be deleted',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      await _service(gateway).moderate(
        BotModerationRequest(
          operation: BotModerationOperation.updateRole,
          userId: '',
          roleId: '10',
          roleDefinition: RoleDefinition(
            togglePermissions: [Permissions.viewChannel.value],
          ),
        ),
        budget: CommandExecutionBudget(),
      );
      expect(
        gateway.guild.roleManager.writes.single['permissions'],
        '${Permissions.viewChannel.value}',
      );
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.deleteRole,
            userId: '',
            roleId: '10',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.guild.roleManager.writes, hasLength(1));
    },
  );
  test('role position is validated before modifying fields', () async {
    final gateway = _Gateway()
      ..guild.permissions = Permissions.manageRoles.value;
    await expectLater(
      _service(gateway).moderate(
        BotModerationRequest(
          operation: BotModerationOperation.updateRole,
          userId: '',
          roleId: '64',
          roleDefinition: RoleDefinition(name: 'Never', position: 10),
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsStateError,
    );
    expect(gateway.guild.roleManager.writes, isEmpty);
    await _service(gateway).moderate(
      BotModerationRequest(
        operation: BotModerationOperation.updateRole,
        userId: '',
        roleId: '64',
        roleDefinition: RoleDefinition(position: 2),
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.guild.roleManager.writes.map((w) => w['operation']), [
      'update',
      'positions',
    ]);
  });
  test(
    'late permission-toggle read cannot update after budget expiry',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      gateway.guild.roleManager.delay = const Duration(milliseconds: 60);
      await expectLater(
        _service(gateway).moderate(
          BotModerationRequest(
            operation: BotModerationOperation.updateRole,
            userId: '',
            roleId: '64',
            roleDefinition: RoleDefinition(
              togglePermissions: [Permissions.kickMembers.value],
            ),
          ),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(gateway.guild.roleManager.writes, isEmpty);
    },
  );
  test(
    'role definition data is immutable and invalid fields never access Discord',
    () async {
      final flags = [Permissions.kickMembers.value];
      final fields = RoleDefinition(togglePermissions: flags);
      flags.clear();
      expect(fields.togglePermissions, [Permissions.kickMembers.value]);
      expect(() => fields.togglePermissions!.clear(), throwsUnsupportedError);
      final gateway = _Gateway();
      for (final invalid in [
        RoleDefinition(name: ''),
        RoleDefinition(color: -1),
        RoleDefinition(position: -1),
        RoleDefinition(togglePermissions: []),
      ]) {
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: BotModerationOperation.updateRole,
              userId: '',
              roleId: '64',
              roleDefinition: invalid,
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsStateError,
        );
      }
      expect(gateway.guild.lookups, 0);
    },
  );
  for (final op in [
    BotModerationOperation.createRole,
    BotModerationOperation.updateRole,
    BotModerationOperation.deleteRole,
  ]) {
    test('$op propagates Discord failure without retry', () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      gateway.guild.roleManager.fail = true;
      await expectLater(
        _service(gateway).moderate(
          BotModerationRequest(
            operation: op,
            userId: '',
            roleId: '64',
            roleDefinition: RoleDefinition(name: 'Staff', color: 255),
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.guild.roleManager.writes, isEmpty);
    });
  }

  for (final operation in [
    BotModerationOperation.addRole,
    BotModerationOperation.removeRole,
  ]) {
    test(
      '$operation assigns lower roles to the owner without a member hierarchy gate',
      () async {
        final gateway = _Gateway()
          ..guild.permissions = Permissions.manageRoles.value;
        await _service(gateway).moderate(
          BotModerationRequest(
            operation: operation,
            userId: '999',
            roleId: '64',
            useDefaultReason: false,
          ),
          budget: CommandExecutionBudget(),
        );
        expect(gateway.guild.memberManager.roleChanges.single, {
          'operation': operation == BotModerationOperation.addRole
              ? 'add'
              : 'remove',
          'user': '999',
          'role': '64',
          'reason': null,
        });
      },
    );
    for (final invalid in [
      'permission',
      'equal',
      'above',
      'everyone',
      'missing',
      'managed',
      'invalid',
    ]) {
      test('$operation blocks $invalid before SDK mutation', () async {
        final gateway = _Gateway()
          ..guild.permissions = Permissions.manageRoles.value;
        var role = '64';
        if (invalid == 'permission') gateway.guild.permissions = 0;
        if (invalid == 'equal') role = '63';
        if (invalid == 'above') gateway.guild.targetPosition = 11;
        if (invalid == 'everyone') role = '10';
        if (invalid == 'missing') role = '123';
        if (invalid == 'invalid') role = '0';
        if (invalid == 'managed') {
          gateway.guild.targetTags = RoleTags(
            botId: Snowflake(5),
            integrationId: null,
            isPremiumSubscriber: false,
            subscriptionListingId: null,
            isAvailableForPurchase: false,
            isLinkedRole: false,
          );
        }
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: operation,
              userId: '222',
              roleId: role,
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsStateError,
        );
        expect(gateway.guild.memberManager.roleChanges, isEmpty);
      });
    }
    test(
      '$operation respects deadline after a delayed permission read',
      () async {
        final gateway = _Gateway()
          ..guild.permissions = Permissions.manageRoles.value;
        gateway.guild.memberManager.delay = const Duration(milliseconds: 40);
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: operation,
              userId: '222',
              roleId: '64',
            ),
            budget: CommandExecutionBudget(
              limit: const Duration(milliseconds: 5),
            ),
          ),
          throwsA(isA<CommandExecutionTimeout>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(gateway.guild.memberManager.roleChanges, isEmpty);
      },
    );
  }
  test(
    'visual grants resolve evaluated role data once through the common transport',
    () async {
      final gateway = _Gateway()
        ..guild.permissions = Permissions.manageRoles.value;
      var resolutions = 0;
      String resolve(String input) {
        resolutions++;
        return input == 'target'
            ? '222'
            : input == 'role'
            ? '64'
            : input;
      }

      final result = await addRoleAction(
        gateway,
        guildId: Snowflake(10),
        payload: {
          'userId': 'target',
          'roleId': 'role',
          'reason': r'$kick[999]',
        },
        resolve: resolve,
      );
      expect(result['status'], 'added');
      expect(resolutions, 3);
      expect(
        gateway.guild.memberManager.roleChanges.single['reason'],
        r'$kick[999]',
      );
      expect(
        (await removeRoleAction(
          gateway,
          guildId: Snowflake(10),
          payload: {'userId': '', 'memberId': '222', 'roleId': '64'},
        ))['status'],
        'removed',
      );
      expect(
        gateway.guild.memberManager.roleChanges.last['reason'],
        'Remove role via BotCreator action',
      );
    },
  );

  for (final operation in [
    BotModerationOperation.kick,
    BotModerationOperation.ban,
  ]) {
    test(
      '${operation.name} blocks empty/invalid targets without Discord effects',
      () async {
        final gateway = _Gateway();
        for (final userId in ['', ' ', 'abc', '0', '-1']) {
          await expectLater(
            _service(gateway).moderate(
              BotModerationRequest(operation: operation, userId: userId),
              budget: CommandExecutionBudget(),
            ),
            throwsA(
              isA<StateError>().having(
                (e) => e.message,
                'message',
                'Missing or invalid userId',
              ),
            ),
          );
        }
        expect(gateway.guild.memberManager.deleted, isEmpty);
        expect(gateway.guild.banned, isEmpty);
        expect(gateway.guild.lookups, 0);
      },
    );
    for (final failure in [
      'permission',
      'owner',
      'equal role',
      'higher role',
    ]) {
      test('${operation.name} refuses $failure', () async {
        final gateway = _Gateway();
        if (failure == 'permission') gateway.guild.permissions = 0;
        if (failure == 'equal role') {
          gateway.guild.memberManager.targetSharesBotRole = true;
        }
        if (failure == 'higher role') gateway.guild.targetPosition = 11;
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: operation,
              userId: failure == 'owner' ? '999' : '222',
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(gateway.guild.memberManager.deleted, isEmpty);
        expect(gateway.guild.banned, isEmpty);
      });
    }
  }
  test(
    'block kick resolves once; typed service retains evaluated reason verbatim',
    () async {
      final gateway = _Gateway();
      final values = <String>[];
      final result = await kickUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': 'target', 'reason': 'reason'},
        resolve: (value) {
          values.add(value);
          return value == 'target'
              ? '222'
              : r'$sendMessage[never] ((temp.never))';
        },
      );
      expect(result, {'userId': '222'});
      expect(values, ['target', 'reason']);
      expect(gateway.guild.memberManager.deleted, [Snowflake(222)]);
      expect(
        gateway.guild.memberManager.reason,
        r'$sendMessage[never] ((temp.never))',
      );
      await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.kick,
          userId: '333',
        ),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.guild.memberManager.deleted, [
        Snowflake(222),
        Snowflake(333),
      ]);
      expect(gateway.guild.memberManager.reason, 'Kick via BotCreator action');
    },
  );
  test('block and typed ban share clamping and audit reason', () async {
    final gateway = _Gateway();
    final result = await banUserAction(
      gateway,
      guildId: Snowflake(10),
      payload: {'userId': '222', 'reason': ' Spam ', 'deleteMessageDays': '99'},
    );
    expect(result, {'userId': '222'});
    expect(gateway.guild.reason, 'Spam');
    expect(gateway.guild.deleteDuration, const Duration(days: 7));
    final target = await _service(gateway).moderate(
      const BotModerationRequest(
        operation: BotModerationOperation.ban,
        userId: '333',
        deleteMessageDays: -1,
      ),
      budget: CommandExecutionBudget(),
    );
    expect(target, '333');
    expect(gateway.guild.banned, [Snowflake(222), Snowflake(333)]);
    expect(gateway.guild.deleteDuration, Duration.zero);
    expect(gateway.guild.reason, 'Ban via BotCreator action');
  });
  test('missing guild preserves block error contract', () async {
    final gateway = _Gateway();
    expect(
      await kickUserAction(gateway, guildId: null, payload: {'userId': '222'}),
      {'error': 'Missing guildId', 'userId': ''},
    );
    expect(
      await banUserAction(gateway, guildId: null, payload: {'userId': '222'}),
      {'error': 'Missing guildId', 'userId': ''},
    );
  });
  test('SDK failure is reported once and never retried', () async {
    final gateway = _Gateway();
    gateway.guild.memberManager.failDelete = true;
    await expectLater(
      _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.kick,
          userId: '222',
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('Failed to kick user'),
        ),
      ),
    );
    expect(gateway.guild.memberManager.deleted, isEmpty);
    expect(gateway.guild.memberManager.deleteAttempts, 1);
  });
  test('expired budget prevents SDK access', () async {
    final gateway = _Gateway();
    await expectLater(
      _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.kick,
          userId: '222',
        ),
        budget: CommandExecutionBudget(limit: Duration.zero),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(gateway.guild.memberManager.deleted, isEmpty);
  });
  test('permission lookups finishing after timeout cannot moderate', () async {
    final gateway = _Gateway();
    gateway.guild.memberManager.delay = const Duration(milliseconds: 40);
    await expectLater(
      _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.kick,
          userId: '222',
        ),
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    // Let the underlying SDK lookups finish after the timeout response.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(gateway.guild.memberManager.deleted, isEmpty);
  });
  test(
    'ban of a definite nonmember is permitted; kick is still rejected',
    () async {
      final gateway = _Gateway();
      gateway.guild.memberManager.targetError = _DiscordError(404, 10007);
      final target = await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.ban,
          userId: '444',
        ),
        budget: CommandExecutionBudget(),
      );
      expect(target, '444');
      expect(gateway.guild.banned, [Snowflake(444)]);
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.kick,
            userId: '444',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.guild.memberManager.deleted, isEmpty);
    },
  );
  test(
    'ban lookup permission and unknown-user errors never permit mutation',
    () async {
      for (final error in [
        _DiscordError(403, 50013),
        _DiscordError(404, 10013),
        StateError('network'),
      ]) {
        final gateway = _Gateway();
        gateway.guild.memberManager.targetError = error;
        await expectLater(
          _service(gateway).moderate(
            const BotModerationRequest(
              operation: BotModerationOperation.ban,
              userId: '444',
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(gateway.guild.banned, isEmpty);
      }
    },
  );
  test(
    'native empty reason can omit audit log reason while block defaults remain',
    () async {
      final gateway = _Gateway();
      for (final operation in [
        BotModerationOperation.kick,
        BotModerationOperation.ban,
      ]) {
        await _service(gateway).moderate(
          BotModerationRequest(
            operation: operation,
            userId: '222',
            useDefaultReason: false,
          ),
          budget: CommandExecutionBudget(),
        );
      }
      expect(gateway.guild.memberManager.reason, isNull);
      expect(gateway.guild.reason, isNull);
    },
  );
  test(
    'unban ID ignores owner and hierarchy while retaining ban permission',
    () async {
      final gateway = _Gateway();
      gateway.guild.targetPosition = 100;
      final target = await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.unban,
          userId: '999',
          useDefaultReason: false,
        ),
        budget: CommandExecutionBudget(),
      );
      expect(target, '999');
      expect(gateway.guild.unbanned, [Snowflake(999)]);
      expect(gateway.guild.reason, isNull);
      expect(gateway.guild.banCursors, isEmpty);
    },
  );
  test(
    'visual unban resolves ID and audit reason once before shared transport',
    () async {
      final gateway = _Gateway();
      final resolved = <String>[];
      expect(
        await unbanUserAction(
          gateway,
          guildId: Snowflake(10),
          payload: {'userId': 'id', 'reason': 'reason'},
          resolve: (value) {
            resolved.add(value);
            return value == 'id' ? '222' : r'$kick[333] ((temp.reason))';
          },
        ),
        {'userId': '222'},
      );
      expect(resolved, ['id', 'reason']);
      expect(gateway.guild.unbanned, [Snowflake(222)]);
      expect(gateway.guild.reason, r'$kick[333] ((temp.reason))');
    },
  );
  test(
    'unban searches all ban pages case-insensitively with monotonic cursor',
    () async {
      final gateway = _Gateway();
      gateway.guild.banPages.addAll([
        _fullPage(),
        [_ban(12000, 'Target')],
      ]);
      final target = await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.unban,
          userId: '',
          username: ' target ',
        ),
        budget: CommandExecutionBudget(),
      );
      expect(target, '12000');
      expect(gateway.guild.banCursors, [null, Snowflake(10999)]);
      expect(gateway.guild.unbanned, [Snowflake(12000)]);
      expect(gateway.guild.reason, 'Unban via BotCreator action');
    },
  );
  test('visual username unban retains invalid-ID fallback contract', () async {
    final gateway = _Gateway();
    gateway.guild.banPages.add([_ban(222, 'Target')]);
    expect(
      await unbanUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': 'invalid', 'username': 'TARGET'},
      ),
      {'userId': '222'},
    );
    expect(gateway.guild.unbanned, [Snowflake(222)]);
  });
  test(
    'missing username cannot unban and repeated ban pages terminate',
    () async {
      final gateway = _Gateway();
      gateway.guild.banPages.add(_fullPage());
      gateway.guild.repeatBanPage = true;
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.unban,
            userId: '',
            username: 'missing',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Banned user not found',
          ),
        ),
      );
      expect(gateway.guild.banCursors, [null, Snowflake(10999)]);
      expect(gateway.guild.unbanned, isEmpty);
    },
  );
  test('unban permission failure prevents both lookup and mutation', () async {
    final gateway = _Gateway();
    gateway.guild.permissions = Permissions.kickMembers.value;
    await expectLater(
      _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.unban,
          userId: '',
          username: 'target',
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.guild.banCursors, isEmpty);
    expect(gateway.guild.unbanned, isEmpty);
  });
  test(
    'unban missing targets are rejected without selecting any author',
    () async {
      final gateway = _Gateway();
      for (final target in ['', '0', '-1', 'invalid']) {
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: BotModerationOperation.unban,
              userId: target,
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
      }
      expect(gateway.guild.unbanned, isEmpty);
      expect(gateway.guild.lookups, 0);
    },
  );
  test('unban SDK errors are reported once without retries', () async {
    final gateway = _Gateway();
    gateway.guild.failUnban = true;
    await expectLater(
      _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.unban,
          userId: '222',
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.guild.unbanAttempts, 1);
    expect(gateway.guild.unbanned, isEmpty);
  });
  test(
    'unban page completing after timeout cannot initiate next page or mutation',
    () async {
      final gateway = _Gateway();
      gateway.guild.banListDelay = const Duration(milliseconds: 60);
      gateway.guild.banPages.add(_fullPage());
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.unban,
            userId: '',
            username: 'missing',
          ),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.guild.banCursors, [null]);
      expect(gateway.guild.unbanned, isEmpty);
    },
  );
  for (final type in [
    BotCreatorActionType.kickUser,
    BotCreatorActionType.banUser,
    BotCreatorActionType.unbanUser,
    BotCreatorActionType.muteUser,
    BotCreatorActionType.unmuteUser,
    BotCreatorActionType.addRole,
    BotCreatorActionType.removeRole,
  ]) {
    test(
      'visual $type propagates budget to prevent mutation after a delayed lookup',
      () async {
        final gateway = _Gateway();
        gateway.guild.permissions |=
            Permissions.moderateMembers.value | Permissions.manageRoles.value;
        if (type == BotCreatorActionType.unbanUser) {
          gateway.guild.banListDelay = const Duration(milliseconds: 80);
          gateway.guild.banPages.add(_fullPage());
        } else {
          gateway.guild.memberManager.delay = const Duration(milliseconds: 80);
        }
        await expectLater(
          handleActions(
            gateway,
            null,
            actions: [
              Action(
                type: type,
                payload: type == BotCreatorActionType.unbanUser
                    ? {'username': 'missing'}
                    : {'userId': '222', 'roleId': '64'},
              ),
            ],
            store: MemoryBotDataStore(),
            botId: 'bot',
            variables: {'guild.id': '10'},
            fallbackGuildId: Snowflake(10),
            resolveTemplate: (value) => value,
            executionPolicy: _NoHydration(),
            throwOnError: true,
            executionBudget: CommandExecutionBudget(
              limit: const Duration(milliseconds: 50),
            ),
          ),
          throwsA(isA<CommandExecutionTimeout>()),
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(gateway.guild.memberManager.deleted, isEmpty);
        expect(gateway.guild.banned, isEmpty);
        expect(gateway.guild.unbanned, isEmpty);
        expect(gateway.guild.memberManager.updates, isEmpty);
        expect(gateway.guild.memberManager.roleChanges, isEmpty);
        if (type == BotCreatorActionType.unbanUser) {
          expect(gateway.guild.banCursors, [null]);
        }
      },
    );
  }
  test(
    'timeout SDK updates the deadline and clears it with explicit null',
    () async {
      final gateway = _Gateway();
      gateway.guild.permissions = Permissions.moderateMembers.value;
      final before = DateTime.now().toUtc();
      await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.timeout,
          userId: '222',
          duration: Duration(minutes: 5),
          clampTimeout: false,
          useDefaultReason: false,
        ),
        budget: CommandExecutionBudget(),
      );
      final update = gateway.guild.memberManager.updates.single;
      final until = DateTime.parse(
        update['communication_disabled_until'] as String,
      );
      expect(until.difference(before).inSeconds, inInclusiveRange(300, 301));
      expect(update['reason'], isNull);
      await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.untimeout,
          userId: '222',
          useDefaultReason: false,
        ),
        budget: CommandExecutionBudget(),
      );
      final cleared = gateway.guild.memberManager.updates.last;
      expect(cleared.containsKey('communication_disabled_until'), true);
      expect(cleared['communication_disabled_until'], isNull);
    },
  );
  test(
    'visual timeout preserves duration precedence, fallback, limits and result status',
    () async {
      final gateway = _Gateway();
      gateway.guild.permissions = Permissions.moderateMembers.value;
      final result = await muteUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {
          'memberId': '222',
          'durationSeconds': '5',
          'durationMinutes': '7',
        },
      );
      expect(result['status'], 'muted');
      expect(result['userId'], '222');
      expect(
        visualTimeoutDuration({'duration': 'bad'}),
        const Duration(minutes: 10),
      );
      expect(
        visualTimeoutDuration({'duration': '2h'}),
        const Duration(hours: 2),
      );
      final now = DateTime.utc(2026);
      expect(
        const BotModerationRequest(
          operation: BotModerationOperation.timeout,
          userId: '222',
          duration: Duration(days: 50),
        ).timeoutDeadline(now),
        now.add(const Duration(days: 28)),
      );
      expect(
        const BotModerationRequest(
          operation: BotModerationOperation.timeout,
          userId: '222',
          duration: Duration.zero,
        ).timeoutDeadline(now),
        now.add(const Duration(seconds: 1)),
      );
      expect(
        await unmuteUserAction(
          gateway,
          guildId: Snowflake(10),
          payload: {'memberId': '222'},
        ),
        {'userId': '222', 'status': 'unmuted'},
      );
      expect(
        gateway.guild.memberManager.updates.last['reason'],
        'Remove timeout via BotCreator action',
      );
    },
  );
  test(
    'visual timeout validates an explicit datetime and preserves its UTC deadline',
    () async {
      final gateway = _Gateway();
      gateway.guild.permissions = Permissions.moderateMembers.value;
      final until = DateTime.now().toUtc().add(const Duration(hours: 1));
      final result = await muteUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': '222', 'until': until.toIso8601String()},
      );
      expect(result['until'], until.toIso8601String());
      final invalid = await muteUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': '222', 'until': 'not a date'},
      );
      expect(invalid['error'], 'Invalid until datetime format');
      expect(gateway.guild.memberManager.updates, hasLength(1));
    },
  );
  for (final operation in [
    BotModerationOperation.timeout,
    BotModerationOperation.untimeout,
  ]) {
    for (final failure in ['permission', 'owner', 'role', 'administrator']) {
      test('$operation denies $failure without an SDK update', () async {
        final gateway = _Gateway();
        gateway.guild.permissions = Permissions.moderateMembers.value;
        if (failure == 'permission') gateway.guild.permissions = 0;
        if (failure == 'role') {
          gateway.guild.memberManager.targetSharesBotRole = true;
        }
        if (failure == 'administrator') {
          gateway.guild.targetPermissions = Permissions.administrator.value;
        }
        await expectLater(
          _service(gateway).moderate(
            BotModerationRequest(
              operation: operation,
              userId: failure == 'owner' ? '999' : '222',
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(gateway.guild.memberManager.updates, isEmpty);
        expect(gateway.guild.memberManager.roleChanges, isEmpty);
      });
    }
  }
  for (final permission in [
    0,
    Permissions.kickMembers.value,
    Permissions.administrator.value,
  ]) {
    test(
      'kickMention author permission $permission is independent of bot permission',
      () async {
        final gateway = _Gateway();
        gateway.guild.targetPermissions = permission;
        final operation = _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.kick,
            userId: '222',
            kickPermissionActorId: '444',
          ),
          budget: CommandExecutionBudget(),
        );
        if (permission == 0) {
          await expectLater(operation, throwsA(isA<StateError>()));
          expect(gateway.guild.memberManager.deleted, isEmpty);
        } else {
          await operation;
          expect(gateway.guild.memberManager.deleted, [Snowflake(222)]);
        }
      },
    );
  }
  test(
    'kickMention owner author is permitted but empty actor never bypasses checks',
    () async {
      final gateway = _Gateway();
      await _service(gateway).moderate(
        const BotModerationRequest(
          operation: BotModerationOperation.kick,
          userId: '222',
          kickPermissionActorId: '999',
        ),
        budget: CommandExecutionBudget(),
      );
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.kick,
            userId: '333',
            kickPermissionActorId: '',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.guild.memberManager.deleted, [Snowflake(222)]);
    },
  );
  test(
    'visual kick payload resolves author permission marker before transport',
    () async {
      final gateway = _Gateway();
      final result = await kickUserAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'userId': '222', 'kickPermissionActorId': 'actor'},
        resolve: (value) => value == 'actor' ? '444' : value,
      );
      expect(result['error'], contains('command author'));
      expect(gateway.guild.memberManager.deleted, isEmpty);
    },
  );
  test(
    'late author permission check cannot kick after budget expiration',
    () async {
      final gateway = _Gateway();
      gateway.guild.targetPermissions = Permissions.kickMembers.value;
      gateway.guild.memberManager.delay = const Duration(milliseconds: 80);
      await expectLater(
        _service(gateway).moderate(
          const BotModerationRequest(
            operation: BotModerationOperation.kick,
            userId: '222',
            kickPermissionActorId: '444',
          ),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 50),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.guild.memberManager.deleted, isEmpty);
    },
  );
}
