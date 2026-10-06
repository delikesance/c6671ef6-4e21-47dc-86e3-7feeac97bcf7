import 'package:bot_creator_shared/engine/bdfd/access_guard_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_channel_query_service.dart';
import 'package:bot_creator_shared/services/bot_permission_query_service.dart';
import 'package:bot_creator_shared/services/bot_role_query_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Services
    implements
        BotPermissionQueryService,
        BotRoleQueryService,
        BotChannelQueryService {
  int mask = 0;
  bool privileged = false;
  bool timeout = false;
  final users = <String?>[];
  final reads = <String>[];
  List<String> memberIds = ['12'];
  List<BotRole> guildRoles = const [
    BotRole(
      id: '10',
      name: '@everyone',
      color: 0,
      hoisted: false,
      mentionable: false,
    ),
    BotRole(
      id: '12',
      name: 'Moderator',
      color: 0,
      hoisted: false,
      mentionable: false,
    ),
    BotRole(
      id: '13',
      name: 'Admin',
      color: 0,
      hoisted: false,
      mentionable: false,
    ),
  ];
  final channelRows = <String, BotChannel>{
    '30': const BotChannel(
      id: '30',
      name: 'chat',
      type: 'text',
      guildId: '10',
      parentId: '40',
      isNsfw: true,
    ),
    '31': const BotChannel(
      id: '31',
      name: 'thread',
      type: 'thread',
      guildId: '10',
      parentId: '30',
    ),
  };
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async {
    reads.add('permissions');
    users.add(userId);
    if (timeout) throw const CommandExecutionTimeout(Duration.zero);
    return BotMemberPermissions(mask, privileged: privileged);
  }

  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) async => throw StateError('stored flags should not be used');
  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) async {
    reads.add('member');
    users.add(userId);
    return memberIds;
  }

  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    reads.add('roles');
    return guildRoles;
  }

  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    reads.add('channel:$id');
    return channelRows[id];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Output implements BdfdOutput {
  String text = '';
  int discards = 0;
  String flushed = '';
  @override
  void append(String value) => text += value;
  @override
  void discard() {
    text = '';
    discards++;
  }

  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async {
    flushed = text;
  }
}

const _variables = {
  'author.id': '20',
  'user.id': '21',
  'guild.id': '10',
  'channel.id': '30',
};
void main() {
  BdfdRuntime runtime(
    _Services services, {
    Map<String, BdfdNativeFunction> extra = const {},
  }) => BdfdRuntime(
    functions: {
      ...bdfdAccessGuardFunctions(
        permissions: services,
        roles: services,
        channels: services,
      ),
      ...extra,
    },
  );
  Future<String> run(_Services s, String script, {BdfdContext? context}) =>
      runtime(s).execute(
        script,
        context: context ?? BdfdContext(variables: {..._variables}),
      );
  for (final (name, allowed, denied) in [
    ('onlyForRoles', 'Moderator', 'Admin'),
    ('onlyForRoleIDs', '12', '13'),
    ('blackListRoles', 'Admin', 'Moderator'),
    ('blackListRolesIDs', '13', '12'),
    ('onlyForCategories', '40', '41'),
  ]) {
    test('$name matches any entry and stops replacing prior output', () async {
      final s = _Services();
      expect(await run(s, '\$$name[999;$allowed;Denied]OK'), 'OK');
      final context = BdfdContext(variables: {..._variables});
      expect(
        await run(
          s,
          'Before\$$name[999;$denied;Denied]Never',
          context: context,
        ),
        'Denied',
      );
      expect(context.stopped, true);
    });
    test('$name failure message is lazy and evaluated once', () async {
      var calls = 0;
      final rt = runtime(
        _Services(),
        extra: {
          'probe': BdfdNativeFunction(
            minArguments: 0,
            maxArguments: 0,
            handler: (_) {
              calls++;
              return r'$literal[]';
            },
          ),
        },
      );
      expect(
        await rt.execute(
          '\$$name[$allowed;\$probe]OK',
          context: BdfdContext(variables: {..._variables}),
        ),
        'OK',
      );
      expect(calls, 0);
      expect(
        await rt.execute(
          '\$$name[$denied;\$probe]Never',
          context: BdfdContext(variables: {..._variables}),
        ),
        r'$literal[]',
      );
      expect(calls, 1);
    });
  }
  test('role names use exact case and no ID alias', () async {
    expect(
      await run(_Services(), r'$onlyForRoles[moderator;Denied]OK'),
      'Denied',
    );
    expect(await run(_Services(), r'$onlyForRoles[12;Denied]OK'), 'Denied');
    expect(
      await run(_Services(), r'$onlyForRoles[ Moderator ;Denied]OK'),
      'OK',
    );
  });
  test('@everyone is implicit for role IDs and names', () async {
    final s = _Services()..memberIds = [];
    expect(
      await run(
        s,
        r'$onlyForRoleIDs[10;Denied]$onlyForRoles[@everyone;Denied]OK',
      ),
      'OK',
    );
  });
  test(
    'role IDs are canonical decimal and reject malformed candidates before reads',
    () async {
      expect(await run(_Services(), r'$onlyForRoleIDs[0012;Denied]OK'), 'OK');
      for (final id in ['0xC', '+12', '-1', '0']) {
        final s = _Services();
        await expectLater(
          run(s, '\$onlyForRoleIDs[$id;Denied]'),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(s.reads, isEmpty);
      }
    },
  );
  test(
    'empty list slots fail whitelist, pass blacklist without service reads',
    () async {
      final s = _Services();
      expect(await run(s, r'Before$onlyForRoles[;]Never'), '');
      expect(await run(s, r'$blackListRolesIDs[;Denied]OK'), 'OK');
      expect(await run(s, r'$onlyForCategories[;Denied]OK'), 'Denied');
      expect(s.reads, isEmpty);
    },
  );
  test(
    'author ID wins over fallback; missing identity is not inferred',
    () async {
      final s = _Services();
      await run(s, r'$onlyForRoleIDs[12;Denied]');
      expect(s.users, ['20']);
      await run(
        s,
        r'$onlyForRoleIDs[12;Denied]',
        context: BdfdContext(variables: {'user.id': '21'}),
      );
      expect(s.users.last, '21');
      await expectLater(
        run(s, r'$onlyForRoleIDs[12;Denied]', context: BdfdContext()),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'admin checks fresh effective permissions, owner/admin privilege and requested user',
    () async {
      final s = _Services();
      expect(await run(s, r'$isAdmin[22]|$onlyAdmin[Denied]OK'), 'Denied');
      s.mask = Permissions.administrator.value;
      expect(await run(s, r'$isAdmin[0022]|$onlyAdmin[Denied]OK'), 'true|OK');
      s.mask = 0;
      s.privileged = true;
      expect(await run(s, r'$isAdmin[22]'), 'true');
      expect(s.users, ['22', '20', '22', '20', '22']);
    },
  );
  for (final name in ['onlyAdmin', 'onlyNSFW']) {
    test(
      '$name lazy message and empty failure discard all buffered output',
      () async {
        var calls = 0;
        final s = _Services()..mask = Permissions.administrator.value;
        final rt = runtime(
          s,
          extra: {
            'probe': BdfdNativeFunction(
              minArguments: 0,
              maxArguments: 0,
              handler: (_) {
                calls++;
                return 'Denied';
              },
            ),
          },
        );
        expect(
          await rt.execute(
            '\$$name[\$probe]OK',
            context: BdfdContext(variables: {..._variables}),
          ),
          'OK',
        );
        expect(calls, 0);
        s.mask = 0;
        s.channelRows.clear();
        expect(
          await rt.execute(
            '\$$name[\$probe]Never',
            context: BdfdContext(variables: {..._variables}),
          ),
          'Denied',
        );
        expect(calls, 1);
        final output = _Output();
        expect(
          await rt.execute(
            'Before\$$name[]Never',
            context: BdfdContext(variables: {..._variables}, output: output),
          ),
          '',
        );
        expect(output.flushed, '');
        expect(output.discards, greaterThanOrEqualTo(1));
      },
    );
  }
  test(
    'NSFW and categories read fresh current channel rather than stale variables',
    () async {
      final s = _Services();
      expect(await run(s, r'$onlyNSFW[Denied]OK'), 'OK');
      s.channelRows['30'] = const BotChannel(
        id: '30',
        name: 'changed',
        type: 'text',
      );
      expect(await run(s, r'$onlyNSFW[Denied]OK'), 'Denied');
      expect(await run(s, r'$onlyForCategories[40;Denied]OK'), 'Denied');
      expect(s.reads, ['channel:30', 'channel:30', 'channel:30']);
    },
  );
  test(
    'thread resolves fresh parent NSFW and category, rejects mismatched guild',
    () async {
      final s = _Services();
      final context = BdfdContext(
        variables: {..._variables, 'channel.id': '31'},
      );
      expect(
        await run(
          s,
          r'$onlyNSFW[Denied]$onlyForCategories[40;Denied]OK',
          context: context,
        ),
        'OK',
      );
      expect(s.reads, ['channel:31', 'channel:30', 'channel:31', 'channel:30']);
      s.channelRows['30'] = const BotChannel(
        id: '30',
        name: 'wrong guild',
        type: 'text',
        guildId: '11',
        isNsfw: true,
        parentId: '40',
      );
      expect(
        await run(
          s,
          r'$onlyForCategories[40;Denied]OK',
          context: BdfdContext(variables: {..._variables, 'channel.id': '31'}),
        ),
        'Denied',
      );
    },
  );
  test(
    'known unsupported alias is not falsely registered; unknown arguments remain opaque',
    () async {
      final s = _Services();
      expect(
        bdfdAccessGuardFunctions(permissions: s, roles: s, channels: s),
        isNot(contains('blacklistroleids')),
      );
      expect(
        await run(s, r'$unknownGuard[$isAdmin[22]]'),
        r'$unknownGuard[$isAdmin[22]]',
      );
      expect(s.reads, isEmpty);
    },
  );
  test('exact official arity validated before reads', () async {
    for (final code in [
      r'$onlyAdmin',
      r'$onlyAdmin[x;y]',
      r'$onlyNSFW',
      r'$isAdmin',
      r'$isAdmin[]',
      r'$onlyForRoles[x]',
      r'$onlyForRoleIDs[x]',
      r'$onlyForCategories[40]',
    ]) {
      final s = _Services();
      await expectLater(run(s, code), throwsA(isA<BdfdNativeError>()));
      expect(s.reads, isEmpty);
    }
  });
  test(
    'shared deadline never becomes a success/failure-message branch',
    () async {
      final s = _Services()..timeout = true;
      await expectLater(
        run(s, r'$onlyAdmin[Denied]Never'),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await expectLater(
        run(
          s,
          r'$onlyNSFW[Denied]',
          context: BdfdContext(
            variables: {..._variables},
            budget: CommandExecutionBudget(limit: Duration.zero),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
    },
  );
}
