import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'dart:math';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/discord_entity_fetcher.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/services/bot_role_query_service.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

const staff = BotRole(
  id: '64',
  name: 'Staff',
  color: 0xe67e22,
  hoisted: true,
  mentionable: false,
);
const user = BotRole(
  id: '65',
  name: 'User',
  color: 255,
  hoisted: false,
  mentionable: true,
);

class _Queries implements BotRoleQueryService {
  List<BotRole> data = [staff, user];
  final budgets = <CommandExecutionBudget>[];
  final users = <String>[];
  int reads = 0;
  final guilds = <String?>[];
  Duration delay = Duration.zero;
  bool fail = false;
  @override
  Future<List<BotRole>> roles({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    reads++;
    guilds.add(guildId);
    budgets.add(budget);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw StateError('Discord refused role read');
    return data;
  }

  @override
  Future<List<String>> memberRoleIds(
    String userId, {
    required CommandExecutionBudget budget,
  }) async {
    budgets.add(budget);
    users.add(userId);
    return ['65', '64'];
  }
}

BdfdEngine _engine(_Queries queries) =>
    BdfdEngine(store: MemoryBotDataStore(), botId: 'bot', roleQueries: queries);

Map<String, dynamic> entities() => {
  'guilds': {
    '10': {
      'owner_id': '999',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {
          'id': '63',
          'name': 'bot',
          'position': 10,
          'permissions': '${Permissions.manageRoles.value}',
        },
        {
          'id': '64',
          'name': 'Staff',
          'position': 1,
          'permissions': '0',
          'color': 0xe67e22,
          'hoist': true,
        },
        {
          'id': '65',
          'name': 'User',
          'position': 2,
          'permissions': '0',
          'color': 255,
          'mentionable': true,
        },
      ],
      'members': {
        '500': {
          'roles': ['63'],
        },
        '222': {
          'roles': ['65', '64'],
        },
      },
    },
  },
};
Future<Map<String, dynamic>> sandbox(
  String source,
  Map<String, dynamic> fixtures,
) => testCommandInSandbox({
  'script': source,
  'bdfdBackend': 'native-v1',
  'variables': {'guild.id': '10', 'bot.id': '500'},
  'entities': fixtures,
});
void main() {
  test(
    'sandbox role and random queries execute without block effects',
    () async {
      final data = entities();
      data['guilds']['10']['channels'] = [
        {'id': '31', 'name': 'category', 'type': 'category'},
      ];
      data['guilds']['20'] = <String, Object>{
        'owner_id': '999',
        'roles': [
          {'id': '20', 'name': '@everyone', 'permissions': '0'},
        ],
      };
      final result = await testCommandInSandbox({
        'script': r'$findRole[Staff]|$randomRoleID[20]|$randomChannelID',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '64|20|31');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'findRole resolves names IDs and mentions in current role list',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      expect(
        await engine.execute(
          r'$findRole[Staff]|$findRole[64]|$findRole[<@&65>]',
        ),
        '64|64|65',
      );
      expect(
        await engine.execute(
          r'$findRole[]|$findRole[missing]|$findRole[<@&999>]',
        ),
        '||',
      );
      expect(await engine.execute(r'$findRole[staff]'), '');
      expect(queries.guilds.every((g) => g == null), true);
      queries.data = [
        staff,
        const BotRole(
          id: '66',
          name: 'Staff',
          color: 0,
          hoisted: false,
          mentionable: false,
        ),
      ];
      expect(await engine.execute(r'$findRole[Staff]'), '64');
      expect(await engine.execute(r'$findRole[<@65>]'), '');
    },
  );
  test(
    'randomRoleID can select everyone and forwards optional guild',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '10',
            name: '@everyone',
            color: 0,
            hoisted: false,
            mentionable: false,
            isEveryone: true,
          ),
        ];
      final engine = _engine(queries);
      expect(
        await engine.execute(
          r'$randomRoleID|$randomRoleID[]|$randomRoleID[20]',
        ),
        '10|10|10',
      );
      expect(queries.guilds, [null, null, '20']);
      queries.data = [];
      expect(await engine.execute(r'$randomRoleID'), '');
    },
  );
  test(
    'random role choices share the invocation random stream through eval',
    () async {
      final queries = _Queries();
      final expected = Random(42);
      final context = BdfdContext(
        random: Random(42),
        temporaryVariables: {'code': r'$randomRoleID'},
      );
      final first = queries.data[expected.nextInt(2)].id;
      final second = queries.data[expected.nextInt(2)].id;
      expect(
        await _engine(
          queries,
        ).execute(r'$randomRoleID|$eval[$var[code]]', context: context),
        '$first|$second',
      );
      expect(queries.budgets.every((b) => identical(b, context.budget)), true);
    },
  );
  test(
    'role lookup invalid arity and random guild reject before reads',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      for (final script in [
        r'$findRole',
        r'$findRole[a;b]',
        r'$randomRoleID[0]',
        r'$randomRoleID[bad]',
        r'$randomRoleID[10;20]',
      ]) {
        await expectLater(
          engine.execute(script),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(
        await engine.execute(r'$notReal[$findRole[Staff];$randomRoleID]'),
        r'$notReal[$findRole[Staff];$randomRoleID]',
      );
      expect(queries.reads, 0);
      BdfdEngine.validation().prepare(r'$findRole[<@&64>]$randomRoleID[20]');
    },
  );
  test(
    'SDK random role guild selection reads the requested guild only',
    () async {
      final data = entities();
      data['guilds']['20'] = <String, Object>{
        'owner_id': '999',
        'roles': [
          {'id': '20', 'name': '@everyone', 'permissions': '0'},
        ],
      };
      final fixture = EntityFixtureGateway(data);
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        roleQueries: DiscordBotRoleQueryService(
          client: fixture,
          guildId: Snowflake(10),
        ),
      );
      expect(await engine.execute(r'$randomRoleID[20]'), '20');
      expect(fixture.requests.single, {
        'operation': 'roles.list',
        'guild_id': '20',
      });
      expect(await engine.execute(r'$findRole[<@&20>]'), '');
    },
  );
  test(
    'sandbox role permissions use an explicit guild and fresh role mutations',
    () async {
      final fixtures = entities();
      fixtures['guilds']['20'] = {
        'roles': [
          {'id': '20', 'name': '@everyone', 'permissions': '0'},
          {'id': '64', 'name': 'remote', 'permissions': '23'},
        ],
      };
      final remote = await testCommandInSandbox({
        'script': r'$rolePerms[20;64;#]',
        'bdfdBackend': 'native-v1',
        'entities': fixtures,
      });
      expect(remote['success'], true, reason: '$remote');
      expect(
        remote['responses'][0]['payload']['content'],
        'CreateInvite# KickMembers# BanMembers# ManageChannels',
      );
      final updated = await sandbox(
        r'$rolePerms[10;64]|$modifyRolePerms[64;admin]$rolePerms[10;64]',
        fixtures,
      );
      expect(updated['success'], true, reason: '$updated');
      expect(
        updated['responses'][0]['payload']['content'],
        'No Permissions|Administrator',
      );
    },
  );
  test(
    'role permissions include newer SDK flags without expanding them',
    () async {
      final queries = _Queries()
        ..data = [
          BotRole(
            id: '64',
            name: '',
            color: 0,
            hoisted: false,
            mentionable: false,
            permissions:
                Permissions.sendPolls.value | Permissions.createEvents.value,
          ),
        ];
      expect(
        await _engine(queries).execute(r'$rolePerms[10;64]'),
        'CreateEvents, SendPolls',
      );
    },
  );

  test('role permissions follow the wiki signature and example', () async {
    final queries = _Queries()
      ..data = [
        const BotRole(
          id: '64',
          name: 'example',
          color: 0,
          hoisted: false,
          mentionable: false,
          permissions: 23,
        ),
      ];
    expect(
      await _engine(queries).execute(r'$rolePerms[20;64;#]'),
      'CreateInvite# KickMembers# BanMembers# ManageChannels',
    );
    expect(
      await _engine(queries).execute(r'$rolePerms[20;64]'),
      'CreateInvite, KickMembers, BanMembers, ManageChannels',
    );
    expect(queries.guilds, ['20', '20']);
  });
  test(
    'role permissions do not expand Administrator or inherit everyone',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '64',
            name: 'admin',
            color: 0,
            hoisted: false,
            mentionable: false,
            permissions: 8,
          ),
          const BotRole(
            id: '65',
            name: 'none',
            color: 0,
            hoisted: false,
            mentionable: false,
          ),
          const BotRole(
            id: '10',
            name: '@everyone',
            color: 0,
            hoisted: false,
            mentionable: false,
            permissions: 2,
            isEveryone: true,
          ),
        ];
      expect(
        await _engine(queries).execute(r'$rolePerms[10;64]|$rolePerms[10;65]'),
        'Administrator|No Permissions',
      );
    },
  );
  test(
    'role permissions reject missing or invalid IDs before service reads',
    () async {
      for (final source in [
        r'$rolePerms[64]',
        r'$rolePerms[;64]',
        r'$rolePerms[invalid;64]',
        r'$rolePerms[10;]',
        r'$rolePerms[10;-1]',
        r'$rolePerms[10;64;#;extra]',
      ]) {
        final queries = _Queries();
        await expectLater(
          _engine(queries).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(queries.reads, 0);
      }
    },
  );
  test(
    'role permissions report missing roles and keep returned text opaque',
    () async {
      final queries = _Queries();
      await expectLater(
        _engine(queries).execute(r'$rolePerms[10;999]'),
        throwsA(isA<BdfdNativeError>()),
      );
      queries.data = [
        const BotRole(
          id: '64',
          name: '',
          color: 0,
          hoisted: false,
          mentionable: false,
          permissions: 6,
        ),
      ];
      expect(
        await _engine(
          queries,
        ).execute(r'$rolePerms[10;64;$unknown[$rolePerms[invalid]]]'),
        r'KickMembers$unknown[$rolePerms[invalid]] BanMembers',
      );
    },
  );
  test(
    'SDK roles use an explicit guild rather than the configured context',
    () async {
      final fixtures = entities();
      final guilds = fixtures['guilds'] as Map;
      guilds['20'] = {
        'roles': [
          {'id': '20', 'name': '@everyone', 'permissions': '0'},
          {'id': '64', 'name': 'remote', 'permissions': '6'},
        ],
      };
      final service = DiscordBotRoleQueryService(
        client: EntityFixtureGateway(fixtures),
        guildId: Snowflake(10),
      );
      final roles = await service.roles(
        guildId: '20',
        budget: CommandExecutionBudget(),
      );
      expect(roles.map((r) => r.name), ['@everyone', 'remote']);
      expect(roles.first.isEveryone, isTrue);
      expect(roles.last.permissions, 6);
      expect((await service.roles(budget: CommandExecutionBudget())).length, 4);
    },
  );

  test(
    'role inventory preserves service order and permission filters require every flag',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '64',
            name: 'kick',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 10,
            permissions: 2,
          ),
          const BotRole(
            id: '65',
            name: 'both',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 1,
            permissions: 6,
          ),
          const BotRole(
            id: '66',
            name: 'ban',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 20,
            permissions: 4,
          ),
        ];
      expect(
        await _engine(queries).execute(
          r'$roleCount|$roleNames|$highestRoleWithPerms[kick]|$lowestRoleWithPerms[kick]|$highestRoleWithPerms[kick;ban]|$lowestRoleWithPerms[kick;ban]',
        ),
        '3|kick,both,ban|64|65|65|65',
      );
    },
  );
  test(
    'Administrator satisfies role filters and default role can be the lowest match',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '10',
            name: '@everyone',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 0,
            isEveryone: true,
            permissions: 2,
          ),
          const BotRole(
            id: '64',
            name: 'admin',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 2,
            permissions: 8,
          ),
        ];
      expect(
        await _engine(queries).execute(
          r'$highestRoleWithPerms[kick;ban]|$lowestRoleWithPerms[kick]|$highestRoleWithPerms[admin]',
        ),
        '64|10|64',
      );
    },
  );
  test(
    'role permission filter returns empty when no role has all requested flags',
    () async {
      final queries = _Queries();
      expect(
        await _engine(
          queries,
        ).execute(r'$highestRoleWithPerms[kick]|$lowestRoleWithPerms[ban]'),
        '|',
      );
      queries.data = [];
      expect(
        await _engine(
          queries,
        ).execute(r'$roleCount|$roleNames|$lowestRoleWithPerms[kick]'),
        '0||',
      );
    },
  );
  for (final source in [
    r'$highestRoleWithPerms[]',
    r'$lowestRoleWithPerms[kick;bad]',
    r'$roleCount[x]',
    r'$roleNames[x]',
  ]) {
    test(
      '$source rejects its signature or invalid permissions before any read',
      () async {
        final queries = _Queries();
        await expectLater(
          _engine(queries).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(queries.reads, 0);
      },
    );
  }
  test(
    'unknown wrapper and function-looking inventory names remain opaque data',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '64',
            name: r'$kick[999]',
            color: 0,
            hoisted: false,
            mentionable: false,
          ),
        ];
      const source = r'$unknown[$roleCount$highestRoleWithPerms[kick]]';
      expect(await _engine(queries).execute(source), source);
      expect(queries.reads, 0);
      expect(await _engine(queries).execute(r'$roleNames'), r'$kick[999]');
    },
  );
  test(
    'SDK and sandbox role filters use fresh permissions after a toggle',
    () async {
      final data = entities();
      final result = await sandbox(
        r'$roleCount|$roleNames|$highestRoleWithPerms[kick]|$modifyRolePerms[64;kick]$highestRoleWithPerms[kick]|$lowestRoleWithPerms[kick]',
        data,
      );
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        '4|@everyone,bot,Staff,User||64|64',
      );
      expect((result['effects'] as List).single['type'], 'updateRole');
    },
  );
  test(
    'visual filtered role boundaries share tie order with the native service',
    () async {
      final data = entities();
      data['guilds']['10']['roles'][1]['permissions'] = '2';
      data['guilds']['10']['roles'][2]['permissions'] = '2';
      data['guilds']['10']['roles'][2]['position'] = 10;
      final gateway = EntityFixtureGateway(data);
      final variables = {'guild.id': '10'};
      await DiscordEntityFetcher.hydrateEntity(
        gateway,
        'roleBoundaryWithPerms',
        '10;highest;kick',
        variables,
      );
      await DiscordEntityFetcher.hydrateEntity(
        gateway,
        'roleBoundaryWithPerms',
        '10;lowest;kick',
        variables,
      );
      expect(variables['roleBoundaryWithPerms[10;highest;kick]'], '63');
      expect(variables['roleBoundaryWithPerms[10;lowest;kick]'], '64');
    },
  );

  test(
    'rank is counted from highest and ties use older role IDs without mutating snapshots',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '65',
            name: 'newer',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 10,
          ),
          const BotRole(
            id: '10',
            name: '@everyone',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 0,
            isEveryone: true,
          ),
          const BotRole(
            id: '64',
            name: 'older',
            color: 0,
            hoisted: false,
            mentionable: false,
            position: 10,
          ),
        ];
      final before = queries.data.toList();
      expect(
        await _engine(queries).execute(
          r'$rolePosition[64]|$rolePosition[65]|$rolePosition[10]|$highestRole|$lowestRole|$highestRole[222]|$lowestRole[222]',
        ),
        '1|2|3|64|10|64|10',
      );
      expect(queries.data, before);
      expect(queries.users, ['222', '222']);
    },
  );
  test(
    'hasRole uses explicit user and treats empty role as false without reading',
    () async {
      final queries = _Queries();
      expect(
        await _engine(
          queries,
        ).execute(r'$hasRole[222;64]|$hasRole[222;66]|$hasRole[222;]'),
        'true|false|false',
      );
      expect(queries.users, ['222', '222']);
    },
  );
  test(
    'everyone is a role of every member even when absent from SDK member role IDs',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '10',
            name: '@everyone',
            color: 0,
            hoisted: false,
            mentionable: false,
            isEveryone: true,
          ),
        ];
      expect(
        await _engine(
          queries,
        ).execute(r'$hasRole[222;10]|$highestRole[222]|$lowestRole[222]'),
        'true|10|10',
      );
    },
  );
  for (final source in [
    r'$highestRole[]',
    r'$lowestRole[]',
    r'$highestRole[bad]',
    r'$rolePosition[0]',
    r'$rolePosition[999]',
    r'$hasRole[;64]',
    r'$hasRole[222;bad]',
  ]) {
    test(
      '$source rejects invalid IDs with no implicit author/server fallback',
      () async {
        await expectLater(
          _engine(_Queries()).execute(
            source,
            context: BdfdContext(variables: {'author.id': '222'}),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
      },
    );
  }
  test(
    'boundary transport shared with visual hydration applies tie order and everyone',
    () async {
      final data = entities();
      data['guilds']['10']['roles'][2]['position'] = 10;
      final gateway = EntityFixtureGateway(data);
      final variables = {'guild.id': '10'};
      await DiscordEntityFetcher.hydrateEntity(
        gateway,
        'roleBoundary',
        '10;highest',
        variables,
      );
      await DiscordEntityFetcher.hydrateEntity(
        gateway,
        'roleBoundary',
        '10;lowest',
        variables,
      );
      expect(variables['roleBoundary[10;highest]'], '63');
      expect(variables['roleBoundary[10;lowest]'], '10');
    },
  );
  test(
    'sandbox membership and rank reflect typed SDK snapshot and role replacements',
    () async {
      final result = await sandbox(
        r'$hasRole[222;64]|$hasRole[222;10]|$rolePosition[65]|$rolePosition[64]|$highestRole|$lowestRole|$highestRole[222]|$lowestRole[222]|$setUserRoles[222;64]$hasRole[222;65]',
        entities(),
      );
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        'true|true|2|3|63|10|65|10|false',
      );
    },
  );

  test(
    'native role queries use the shared budget and wiki output formats',
    () async {
      final queries = _Queries();
      final context = BdfdContext();
      final source =
          r'$roleID[Staff]|$roleName[64]|$getRoleColor[64]|$getRoleColor[65]|$isHoisted[64]|$isMentionable[64]|$isMentionable[65]|$roleExists[64]|$roleExists[66]|$userRoles[222]';
      final native = _engine(queries);
      final program = native.prepare(source);
      expect(queries.reads, 0);
      expect(
        await native.executeProgram(program, context: context),
        '64|Staff|E67E22|0000FF|true|false|true|true|false|User\nStaff',
      );
      expect(queries.users, ['222']);
      expect(queries.budgets, everyElement(same(context.budget)));
    },
  );
  test(
    'empty or invalid roleExists is false without accessing Discord',
    () async {
      final queries = _Queries();
      expect(
        await _engine(
          queries,
        ).execute(r'$roleExists[]|$roleExists[bad]|$roleExists[0]'),
        'false|false|false',
      );
      expect(queries.reads, 0);
    },
  );
  test(
    'missing and ambiguous role names return empty rather than choosing a role',
    () async {
      final queries = _Queries()
        ..data = [
          staff,
          const BotRole(
            id: '66',
            name: 'Staff',
            color: 0,
            hoisted: false,
            mentionable: false,
          ),
        ];
      expect(
        await _engine(
          queries,
        ).execute(r'$roleID[Staff]|$roleID[Missing]|$roleID[]'),
        '||',
      );
    },
  );
  for (final source in [
    r'$roleName[]',
    r'$getRoleColor[bad]',
    r'$isHoisted[0]',
    r'$isMentionable[999]',
    r'$userRoles[]',
    r'$userRoles[bad]',
  ]) {
    test('$source reports a native source error', () async {
      await expectLater(
        _engine(_Queries()).execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    });
  }
  test(
    'unknown wrapper and returned function-looking names remain data',
    () async {
      final queries = _Queries()
        ..data = [
          const BotRole(
            id: '64',
            name: r'$kick[999]',
            color: 0,
            hoisted: false,
            mentionable: false,
          ),
        ];
      const source = r'$unknown[$roleID[Staff]]';
      expect(await _engine(queries).execute(source), source);
      expect(queries.reads, 0);
      expect(await _engine(queries).execute(r'$roleName[64]'), r'$kick[999]');
    },
  );
  test('read errors are catchable and not retried', () async {
    final queries = _Queries()..fail = true;
    expect(
      await _engine(queries).execute(r'$try$roleName[64]$catch caught $endtry'),
      ' caught ',
    );
    expect(queries.reads, 1);
  });
  test('role read obeys the parent execution deadline', () async {
    final queries = _Queries()..delay = const Duration(milliseconds: 60);
    await expectLater(
      _engine(queries).execute(
        r'$roleName[64]',
        context: BdfdContext(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(queries.reads, 1);
  });
  test(
    'Discord aggregate exposes typed queries without reading bot permissions',
    () async {
      final fixtures = entities();
      fixtures['guilds']['10']['roles'][1]['permissions'] = '0';
      final gateway = EntityFixtureGateway(fixtures);
      final service = DiscordBotModerationService(
        client: gateway,
        guildId: Snowflake(10),
      );
      final native = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: service,
      );
      expect(
        await native.execute(r'$roleName[64]|$userRoles[222]'),
        'Staff|User\nStaff',
      );
      expect(
        gateway.requests.where((r) => r['operation'] == 'roles.list'),
        hasLength(2),
      );
      final values = await service.roles(budget: CommandExecutionBudget());
      expect(() => values.clear(), throwsUnsupportedError);
      final ids = await service.memberRoleIds(
        '222',
        budget: CommandExecutionBudget(),
      );
      expect(() => ids.clear(), throwsUnsupportedError);
    },
  );
  test('visual entity hydration shares the role list transport', () async {
    final gateway = EntityFixtureGateway(entities());
    final variables = {'guild.id': '10'};
    await DiscordEntityFetcher.hydrateEntity(
      gateway,
      'role',
      'Staff',
      variables,
    );
    expect(variables['role[Staff].id'], '64');
    expect(
      gateway.requests.where((r) => r['operation'] == 'roles.list'),
      hasLength(1),
    );
  });
  test(
    'native sandbox reads created and modified roles from fresh fixture snapshots',
    () async {
      final result = await sandbox(
        r'$createRole[New;255]$roleID[New]|$modifyRole[64;Renamed]$roleName[64]|$setUserRoles[222;64]$userRoles[222]|$getRoleColor[65]',
        entities(),
      );
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        '66|Renamed|Renamed|0000FF',
      );
      expect((result['effects'] as List).map((e) => e['type']), [
        'createRole',
        'updateRole',
        'setUserRoles',
      ]);
    },
  );
  test(
    'native sandbox role reads require no moderation permission or bot ID',
    () async {
      final data = entities();
      data['guilds']['10']['roles'][1]['permissions'] = '0';
      final result = await testCommandInSandbox({
        'script': r'$roleName[64]|$userRoles[222]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'Staff|User\nStaff');
      expect(result['effects'], isEmpty);
    },
  );
  test('validation includes read signatures without accessing fixtures', () {
    final validator = BdfdEngine.validation();
    expect(
      validator.prepare(
        r'$roleID[Staff]$roleName[64]$getRoleColor[64]$isHoisted[64]$isMentionable[64]$roleExists[]$userRoles[222]',
      ),
      isNotNull,
    );
  });
}
