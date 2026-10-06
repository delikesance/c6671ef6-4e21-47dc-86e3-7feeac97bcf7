import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_permission_query_service.dart';
import 'package:bot_creator_shared/services/user_permissions.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Queries implements BotPermissionQueryService {
  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) async {
    users.add(userId);
    budgets.add(budget);
    return value.mask;
  }

  BotMemberPermissions value = const BotMemberPermissions(2);
  final users = <String?>[];
  final channels = <String?>[];
  final budgets = <CommandExecutionBudget>[];
  Duration delay = Duration.zero;
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async {
    users.add(userId);
    channels.add(channelId);
    budgets.add(budget);
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return value;
  }
}

BdfdEngine _engine(_Queries service) => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  permissionQueries: service,
);

Map<String, dynamic> _fixtures() => {
  'guilds': {
    '10': {
      'owner_id': '999',
      'roles': [
        {'id': '10', 'permissions': '1024'},
        {'id': '63', 'permissions': '268438528'},
        {'id': '64', 'permissions': '8'},
      ],
      'members': {
        '500': <String, dynamic>{
          'roles': ['63'],
        },
        '20': {'roles': <String>[]},
        '21': {
          'roles': ['64'],
        },
      },
      'channels': [
        {
          'id': '30',
          'type': 'text',
          'permission_overwrites': [
            {'id': '63', 'type': 0, 'deny': '2048', 'allow': '16'},
            {'id': '500', 'type': 1, 'allow': '2048', 'deny': '16'},
          ],
        },
        {'id': '31', 'type': 'voice'},
      ],
      'threads': [
        {'id': '501', 'parent_id': '30'},
      ],
    },
  },
};

class _Gateway implements NyxxGateway {
  _Gateway(this.fixture, {this.channelManager});
  final EntityFixtureGateway fixture;
  final ChannelManager? channelManager;
  @override
  GuildManager get guilds => fixture.guilds;
  @override
  ChannelManager get channels => channelManager ?? fixture.channels;
  @override
  PartialUser get user => _Bot();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowChannels implements ChannelManager {
  _SlowChannels(this.fixture);
  final EntityFixtureGateway fixture;
  @override
  Future<Channel> fetch(Snowflake id) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return fixture.channels.fetch(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'userPerms returns stored flags with exact limit and separator',
    () async {
      final service = _Queries()
        ..value = const BotMemberPermissions(3081, privileged: true);
      final context = BdfdContext();
      final engine = _engine(service);
      expect(
        await engine.execute(r'$userPerms[20;-1;, ]', context: context),
        'CREATE_INSTANT_INVITE, ADMINISTRATOR, VIEW_CHANNEL, SEND_MESSAGES',
      );
      expect(
        await engine.execute(r'$userPerms[20;2; / ]'),
        'CREATE_INSTANT_INVITE / ADMINISTRATOR',
      );
      expect(
        await engine.execute(r'$userPerms[20;100;]'),
        'CREATE_INSTANT_INVITEADMINISTRATORVIEW_CHANNELSEND_MESSAGES',
      );
      expect(await engine.execute(r'$userPerms[20;0;|]'), '');
      expect(
        service.channels,
        isEmpty,
        reason: 'display does not query effective permissions',
      );
      expect(identical(service.budgets.first, context.budget), true);
    },
  );
  test(
    'userPerms special Discord labels retain bit order and no extra spaces',
    () {
      final mask =
          Permissions.sendTtsMessages.value |
          Permissions.useVad.value |
          Permissions.viewCreatorMonetizationAnalytics.value |
          Permissions.bypassSlowmode.value;
      expect(
        formatUserPermissions(mask, amount: -1, separator: '|'),
        'SEND_TTS_MESSAGES|USE_VAD|VIEW_CREATOR_MONETIZATION_ANALYTICS|BYPASS_SLOWMODE',
      );
      expect(formatUserPermissions(0, amount: -1, separator: '|'), '');
    },
  );
  test(
    'invalid userPerms arity IDs and amount never read the adapter',
    () async {
      final service = _Queries();
      for (final source in [
        r'$userPerms',
        r'$userPerms[20]',
        r'$userPerms[20;-1]',
        r'$userPerms[20;-1;,;extra]',
        r'$userPerms[;-1;,]',
        r'$userPerms[0;-1;,]',
        r'$userPerms[20;;,]',
        r'$userPerms[20;-2;,]',
        r'$userPerms[20;1.5;,]',
      ]) {
        await expectLater(
          _engine(service).execute(source),
          throwsA(isA<BdfdNativeError>()),
          reason: source,
        );
      }
      expect(service.users, isEmpty);
      BdfdEngine.validation().prepare(r'$userPerms[20;-1;, ]');
    },
  );
  test('unknown wrapper preserves userPerms without reads', () async {
    final service = _Queries();
    const source = r'$notAFunction[$userPerms[20;-1;, ]]';
    expect(await _engine(service).execute(source), source);
    expect(service.users, isEmpty);
  });
  test(
    'SDK stored permissions retain owner admin and timed-out role flags',
    () async {
      final data = _fixtures();
      data['guilds']['10']['members']['999'] = <String, dynamic>{
        'roles': ['63'],
      };
      data['guilds']['10']['members']['500']['timeout_until'] = DateTime.now()
          .toUtc()
          .add(const Duration(days: 1))
          .toIso8601String();
      final service = DiscordBotPermissionQueryService(
        client: _Gateway(EntityFixtureGateway(data)),
        guildId: Snowflake(10),
      );
      expect(
        await service.storedMemberPermissions(
          '21',
          budget: CommandExecutionBudget(),
        ),
        1032,
      );
      expect(
        await service.storedMemberPermissions(
          '999',
          budget: CommandExecutionBudget(),
        ),
        268438528,
      );
      expect(
        await service.storedMemberPermissions(
          '500',
          budget: CommandExecutionBudget(),
        ),
        268438528,
      );
      expect(
        (await service.memberPermissions(
          budget: CommandExecutionBudget(),
        )).hasAll([2048]),
        false,
      );
    },
  );
  test(
    'SDK stored permission failures do not return an invented empty list',
    () async {
      final fixture = EntityFixtureGateway(_fixtures());
      final service = DiscordBotPermissionQueryService(
        client: _Gateway(fixture),
        guildId: Snowflake(10),
      );
      await expectLater(
        service.storedMemberPermissions('0', budget: CommandExecutionBudget()),
        throwsArgumentError,
      );
      expect(fixture.requests, isEmpty);
      await expectLater(
        service.storedMemberPermissions(
          '99999',
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<Exception>()),
      );
      expect(
        fixture.requests.where((r) => r['operation'] == 'roles.list'),
        isEmpty,
      );
    },
  );
  test(
    'sandbox userPerms shares SDK stored reads with explicit user selection',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$userPerms[21;-1;, ] | $userPerms[500;2;/]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': _fixtures(),
      });
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], isEmpty);
      expect(
        result['results']['output'],
        'ADMINISTRATOR, VIEW_CHANNEL | VIEW_CHANNEL/SEND_MESSAGES',
      );
    },
  );
  test(
    'checkUserPerms requires all flags and shares the invocation budget',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      final context = BdfdContext();
      expect(
        await engine.execute(
          r'$checkUserPerms[20;KICK] $checkUserPerms[20;kick;ban]',
          context: context,
        ),
        'true false',
      );
      expect(queries.users, ['20', '20']);
      expect(queries.channels, [null, null]);
      expect(queries.budgets.every((b) => identical(b, context.budget)), true);
    },
  );
  test('guards select author bot and target channel independently', () async {
    final queries = _Queries();
    final context = BdfdContext(
      variables: {'author.id': '20', 'channel.id': '30'},
    );
    expect(
      await _engine(queries).execute(
        r'$onlyPerms[kick;bad]$onlyBotPerms[kick;bad]$onlyBotChannelPerms[31;kick;bad]ok',
        context: context,
      ),
      'ok',
    );
    expect(queries.users, ['20', null, null]);
    expect(queries.channels, [null, null, '31']);
  });
  test(
    'denied guard evaluates error once and stops later effects even in try',
    () async {
      final queries = _Queries();
      final engine = _engine(queries);
      final context = BdfdContext();
      expect(
        await engine.execute(
          r'before$try$onlyBotPerms[ban;$var[count;1]denied]$var[after;bad]$catchcaught$endtry',
          context: context,
        ),
        'denied',
      );
      expect(context.stopped, true);
      expect(context.temporaryVariables['count'], '1');
      expect(context.temporaryVariables['after'], isNull);
    },
  );
  test('successful and empty guards keep their error argument lazy', () async {
    final queries = _Queries();
    final context = BdfdContext();
    expect(
      await _engine(queries).execute(
        r'$onlyBotPerms[kick;$var[bad;1]]$onlyPerms[;$var[bad;2]]ok',
        context: context,
      ),
      'ok',
    );
    expect(context.temporaryVariables['bad'], isNull);
    expect(queries.users, [null]);
  });
  test(
    'unknown wrapper leaves queries and error arguments untouched',
    () async {
      final queries = _Queries();
      const script = r'$notAFunction[$onlyBotPerms[ban;bad]]';
      expect(await _engine(queries).execute(script), script);
      expect(queries.users, isEmpty);
    },
  );
  test('invalid signatures permissions and IDs reject before querying', () async {
    final queries = _Queries();
    final engine = _engine(queries);
    for (final script in [
      r'$checkUserPerms[20]',
      r'$checkUserPerms[0;kick]',
      r'$checkUserPerms[20;]',
      r'$checkUserPerms[20;invented]',
      r'$checkUserPerms[20;+kick]',
      r'$onlyBotPerms[kick]',
      r'$onlyBotChannelPerms[30;kick]',
      r'$onlyBotChannelPerms[30;;bad]',
    ]) {
      await expectLater(
        engine.execute(script),
        throwsA(isA<BdfdNativeError>()),
        reason: script,
      );
    }
    expect(queries.users, isEmpty);
    BdfdEngine.validation().prepare(
      r'$checkUserPerms[20;kick]$onlyPerms[kick;]$onlyBotPerms[kick;]$onlyBotChannelPerms[30;kick;]',
    );
  });
  test(
    'SDK reads everyone and member roles, with owner and admin bypass',
    () async {
      final service = DiscordBotPermissionQueryService(
        client: _Gateway(EntityFixtureGateway(_fixtures())),
        guildId: Snowflake(10),
      );
      Future<BotMemberPermissions> read(String user) => service
          .memberPermissions(userId: user, budget: CommandExecutionBudget());
      expect((await read('20')).hasAll([1024]), true);
      expect((await read('20')).hasAll([2048]), false);
      expect((await read('21')).hasAll([268435456, 2048]), true);
      expect((await read('999')).hasAll([268435456, 2048]), true);
    },
  );
  test('SDK member overwrite wins and thread uses parent overwrites', () async {
    final fixture = EntityFixtureGateway(_fixtures());
    final service = DiscordBotPermissionQueryService(
      client: _Gateway(fixture),
      guildId: Snowflake(10),
    );
    for (final channel in ['30', '501']) {
      final value = await service.memberPermissions(
        channelId: channel,
        budget: CommandExecutionBudget(),
      );
      expect(value.hasAll([1024, 2048]), true);
      expect(value.hasAll([16]), false);
    }
    expect(
      fixture.requests.where(
        (r) => r['operation'] == 'channels.fetch' && r['channel_id'] == '30',
      ),
      hasLength(2),
    );
  });
  test('fresh reads observe changed fixture roles and timeout', () async {
    final data = _fixtures();
    final service = DiscordBotPermissionQueryService(
      client: _Gateway(EntityFixtureGateway(data)),
      guildId: Snowflake(10),
    );
    Future<BotMemberPermissions> read() =>
        service.memberPermissions(budget: CommandExecutionBudget());
    expect((await read()).hasAll([2048]), true);
    data['guilds']['10']['members']['500']['timeout_until'] = DateTime.now()
        .toUtc()
        .add(const Duration(days: 1))
        .toIso8601String();
    expect((await read()).hasAll([2048]), false);
    expect((await read()).hasAll([1024]), true);
    data['guilds']['10']['members']['500'].remove('timeout_until');
    data['guilds']['10']['roles'][1]['permissions'] = '268435456';
    expect((await read()).hasAll([2048]), false);
  });
  test(
    'channel restrictions cover visibility send dependencies and voice connect',
    () {
      expect(
        const BotMemberPermissions(2048, inChannel: true).hasAll([2048]),
        false,
      );
      expect(
        const BotMemberPermissions(17408, inChannel: true).hasAll([16384]),
        false,
      );
      expect(
        const BotMemberPermissions(
          17408,
          inChannel: true,
          privileged: true,
        ).hasAll([16384]),
        true,
      );
      expect(
        const BotMemberPermissions(
          1040,
          inChannel: true,
          inVoiceChannel: true,
        ).hasAll([16]),
        false,
      );
      expect(
        const BotMemberPermissions(
          1072,
          inChannel: true,
          inVoiceChannel: true,
        ).hasAll([32]),
        true,
      );
    },
  );
  test('SDK resolves channel owner guild instead of current guild', () async {
    final service = DiscordBotPermissionQueryService(
      client: _Gateway(EntityFixtureGateway(_fixtures())),
      guildId: Snowflake(99999),
    );
    expect(
      (await service.memberPermissions(
        channelId: '30',
        budget: CommandExecutionBudget(),
      )).hasAll([2048]),
      true,
    );
  });
  test('invalid request IDs cause no fixture reads', () async {
    final fixture = EntityFixtureGateway(_fixtures());
    final service = DiscordBotPermissionQueryService(client: _Gateway(fixture));
    await expectLater(
      service.memberPermissions(userId: '0', budget: CommandExecutionBudget()),
      throwsArgumentError,
    );
    await expectLater(
      service.memberPermissions(
        channelId: 'bad',
        budget: CommandExecutionBudget(),
      ),
      throwsArgumentError,
    );
    expect(fixture.requests, isEmpty);
  });
  test(
    'query deadline stops additional reads after a late channel fetch',
    () async {
      final fixture = EntityFixtureGateway(_fixtures());
      final service = DiscordBotPermissionQueryService(
        client: _Gateway(fixture, channelManager: _SlowChannels(fixture)),
        guildId: Snowflake(10),
      );
      await expectLater(
        service.memberPermissions(
          channelId: '30',
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(fixture.requests, hasLength(1));
      expect(fixture.requests.single['operation'], 'channels.fetch');
    },
  );
  test(
    'missing guild or malformed thread parent fails instead of authorizing',
    () async {
      final data = _fixtures();
      final service = DiscordBotPermissionQueryService(
        client: _Gateway(EntityFixtureGateway(data)),
      );
      await expectLater(
        service.memberPermissions(
          userId: '20',
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      data['guilds']['10']['threads'][0]['parent_id'] = '501';
      await expectLater(
        service.memberPermissions(
          channelId: '501',
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
    },
  );
  test(
    'empty channel convention uses the current invocation channel',
    () async {
      final queries = _Queries();
      await _engine(queries).execute(
        r'$onlyBotChannelPerms[;kick;bad]',
        context: BdfdContext(variables: {'channel.id': '30'}),
      );
      expect(queries.channels, ['30']);
    },
  );
  test(
    'permission guards validate and normalize context IDs before reads',
    () async {
      final queries = _Queries();
      for (final context in [
        BdfdContext(),
        BdfdContext(variables: {'author.id': '+20'}),
        BdfdContext(variables: {'author.id': '0', 'user.id': '20'}),
      ]) {
        await expectLater(
          _engine(
            queries,
          ).execute(r'$onlyPerms[kick;denied]', context: context),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      for (final channel in ['bad', '+30', '0', '']) {
        await expectLater(
          _engine(
            queries,
          ).execute('\$onlyBotChannelPerms[$channel;kick;denied]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(queries.users, isEmpty);
      await _engine(queries).execute(
        r'$onlyPerms[kick;denied]$onlyBotChannelPerms[0030;kick;denied]',
        context: BdfdContext(variables: {'user.id': '0020'}),
      );
      expect(queries.users, ['20', null]);
      expect(queries.channels, [null, '30']);
    },
  );
  test(
    'a late denied permission read never evaluates the failure message',
    () async {
      final queries = _Queries()..delay = const Duration(milliseconds: 50);
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      );
      await expectLater(
        _engine(
          queries,
        ).execute(r'$onlyBotPerms[ban;$var[late;1]denied]', context: context),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(context.temporaryVariables['late'], isNull);
      expect(context.stopped, false);
    },
  );
  test('aggregate exposes permission query capability', () async {
    final engine = BdfdEngine(
      store: MemoryBotDataStore(),
      botId: 'bot',
      moderation: DiscordBotModerationService(
        client: _Gateway(EntityFixtureGateway(_fixtures())),
        guildId: Snowflake(10),
      ),
    );
    expect(await engine.execute(r'$checkUserPerms[20;readmessages]'), 'true');
    expect(
      await engine.execute(r'$userPerms[21;-1;, ]'),
      'ADMINISTRATOR, VIEW_CHANNEL',
    );
  });
  test('sandbox permission edit changes subsequent guard outcome', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$onlyBotChannelPerms[30;sendmessages;first]$editChannelPerms[30;500;-sendmessages]$onlyBotChannelPerms[30;sendmessages;denied]$modifyChannel[30;never]',
      'bdfdBackend': 'native-v1',
      'variables': {'guild.id': '10', 'bot.id': '500'},
      'entities': _fixtures(),
    });
    expect(result['success'], true, reason: '$result');
    expect(result['effects'], hasLength(1));
    expect(result['results']['output'], 'denied');
  });
}
