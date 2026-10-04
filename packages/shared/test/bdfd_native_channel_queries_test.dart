import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/engine/discord_entity_fetcher.dart';
import 'package:bot_creator_shared/services/bot_channel_query_service.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Queries implements BotChannelQueryService {
  BotGuildChannelSettings settings = const BotGuildChannelSettings();
  final settingGuilds = <String?>[];
  @override
  Future<BotGuildChannelSettings> guildChannelSettings({
    String? guildId,
    required CommandExecutionBudget budget,
  }) async {
    settingGuilds.add(guildId);
    budgets.add(budget);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw StateError('Discord guild read refused');
    return settings;
  }

  final budgets = <CommandExecutionBudget>[];
  final ids = <String>[];
  final guilds = <String?>[];
  final withThreads = <bool>[];
  List<BotChannel> data = [
    const BotChannel(
      id: '30',
      name: 'chat',
      type: 'text',
      topic: r'$sendMessage[topic]',
      isNsfw: true,
    ),
    const BotChannel(id: '31', name: 'category', type: 'category'),
  ];
  bool fail = false;
  Duration delay = Duration.zero;
  int counts = 0;
  @override
  Future<int> countChannels({required CommandExecutionBudget budget}) async {
    counts++;
    budgets.add(budget);
    if (fail) throw StateError('Discord count refused');
    return data.length;
  }

  @override
  Future<BotChannel?> channel(
    String id, {
    required CommandExecutionBudget budget,
  }) async {
    budgets.add(budget);
    ids.add(id);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (fail) throw StateError('Discord read refused');
    return data.where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<BotChannel>> channels({
    String? guildId,
    bool includeActiveThreads = false,
    required CommandExecutionBudget budget,
  }) async {
    budgets.add(budget);
    guilds.add(guildId);
    withThreads.add(includeActiveThreads);
    if (fail) throw StateError('Discord list refused');
    return data;
  }
}

BdfdEngine _engine(_Queries q) =>
    BdfdEngine(store: MemoryBotDataStore(), botId: 'bot', channelQueries: q);
Map<String, dynamic> fixtures() => {
  'guilds': <String, dynamic>{
    '10': <String, dynamic>{
      'threads': <Map<String, dynamic>>[],
      'channels': <Map<String, dynamic>>[
        {
          'id': '30',
          'name': 'chat',
          'type': 'text',
          'topic': 'topic',
          'nsfw': true,
        },
        {'id': '31', 'name': 'category', 'type': 'category'},
      ],
    },
    '20': <String, dynamic>{
      'threads': <Map<String, dynamic>>[],
      'channels': <Map<String, dynamic>>[
        {'id': '40', 'name': 'remote', 'type': 'text'},
      ],
    },
  },
};

class _SdkChannel implements GuildChannel {
  @override
  int get position => 0;
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  Snowflake? get parentId => null;
  _SdkChannel(this.type);
  @override
  final ChannelType type;
  @override
  Snowflake get id => Snowflake(30);
  @override
  String get name => 'kind';
  @override
  bool get isNsfw => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway(this.read);
  final Future<Channel> Function() read;
  @override
  ChannelManager get channels => _Manager(read);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Manager implements ChannelManager {
  _Manager(this.read);
  final Future<Channel> Function() read;
  @override
  Future<Channel> fetch(Snowflake id) => read();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

class _DelayedGuild implements PartialGuild {
  _DelayedGuild(this.gateway);
  final EntityFixtureGateway gateway;
  int activeReads = 0;
  @override
  Future<List<GuildChannel>> fetchChannels() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return gateway.guilds[Snowflake(10)].fetchChannels();
  }

  @override
  Future<ThreadList> listActiveThreads() {
    activeReads++;
    return gateway.guilds[Snowflake(10)].listActiveThreads();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DelayedGuilds implements GuildManager {
  _DelayedGuilds(this.guild);
  final _DelayedGuild guild;
  @override
  PartialGuild operator [](Snowflake id) => guild;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _CountGateway implements NyxxGateway {
  _CountGateway(this.guild);
  final _DelayedGuild guild;
  @override
  GuildManager get guilds => _DelayedGuilds(guild);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, dynamic> forumFixtures() {
  final data = fixtures();
  (data['guilds']['10']['channels'] as List).add(<String, dynamic>{
    'id': '32',
    'name': 'forum',
    'type': 'forum',
    'topic': 'forum topic',
  });
  data['guilds']['10']['threads'] = <Map<String, dynamic>>[
    {'id': '501', 'parent_id': '32'},
    {'id': '501', 'parent_id': '32'},
    {'id': '502', 'parent_id': '32'},
    {'id': '503', 'parent_id': '32', 'archived': true},
    {'id': '504', 'parent_id': '30'},
    {'id': '505', 'parent_id': '999'},
  ];
  return data;
}

void main() {
  test(
    'special channel functions read settings with documented guild scope',
    () async {
      final queries = _Queries()
        ..settings = const BotGuildChannelSettings(
          afkId: '50',
          rulesId: '51',
          systemId: '52',
        );
      final context = BdfdContext();
      expect(
        await _engine(queries).execute(
          r'$afkChannelID|$rulesChannelID|$systemChannelID|$rulesChannelID[]|$rulesChannelID[20]',
          context: context,
        ),
        '50|51|52|51|51',
      );
      expect(queries.settingGuilds, [null, null, null, null, '20']);
      expect(queries.budgets.every((b) => identical(b, context.budget)), true);
      expect(
        queries.ids,
        isEmpty,
        reason: 'settings do not fetch the configured channel',
      );
    },
  );
  test(
    'missing special channels are errors handled by native try catch',
    () async {
      final queries = _Queries();
      for (final function in [
        'afkChannelID',
        'rulesChannelID',
        'systemChannelID',
      ]) {
        await expectLater(
          _engine(queries).execute('\$$function'),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(
          await _engine(
            queries,
          ).execute('\$try\$$function\$catch missing\$endtry'),
          ' missing',
        );
      }
    },
  );
  test('special and category invalid signatures reject before reads', () async {
    final queries = _Queries();
    final context = BdfdContext();
    for (final source in [
      r'$afkChannelID[10]',
      r'$systemChannelID[10]',
      r'$rulesChannelID[0]',
      r'$rulesChannelID[bad]',
      r'$rulesChannelID[10;20]',
      r'$randomCategoryID[0]',
      r'$randomCategoryID[bad]',
      r'$randomCategoryID[10;20]',
    ]) {
      await expectLater(
        _engine(queries).execute(source, context: context),
        throwsA(isA<BdfdNativeError>()),
        reason: source,
      );
    }
    expect(queries.settingGuilds, isEmpty);
    expect(queries.guilds, isEmpty);
    const opaque =
        r'$notReal[$afkChannelID;$rulesChannelID[20];$randomCategoryID]';
    expect(await _engine(queries).execute(opaque), opaque);
    expect(queries.budgets, isEmpty);
    BdfdEngine.validation().prepare(
      r'$afkChannelID$rulesChannelID[20]$systemChannelID$randomCategoryID[]',
    );
  });
  test(
    'randomCategoryID filters categories and forwards optional server',
    () async {
      final queries = _Queries()
        ..data = [
          const BotChannel(id: '30', name: 'chat', type: 'text'),
          const BotChannel(id: '31', name: 'category', type: 'category'),
          const BotChannel(id: '32', name: 'voice', type: 'voice'),
        ];
      final context = BdfdContext();
      expect(
        await _engine(queries).execute(
          r'$randomCategoryID|$randomCategoryID[]|$randomCategoryID[20]',
          context: context,
        ),
        '31|31|31',
      );
      expect(queries.guilds, [null, null, '20']);
      expect(queries.withThreads, [false, false, false]);
      expect(queries.budgets.every((b) => identical(b, context.budget)), true);
      queries.data = [const BotChannel(id: '30', name: 'chat', type: 'text')];
      expect(await _engine(queries).execute(r'$randomCategoryID'), '');
    },
  );
  test(
    'SDK settings read fresh guild metadata and preserve previous snapshot',
    () async {
      final data = fixtures();
      data['guilds']['10']['afk_channel_id'] = '50';
      data['guilds']['10']['rules_channel_id'] = '51';
      data['guilds']['10']['system_channel_id'] = '52';
      data['guilds']['20']['rules_channel_id'] = '61';
      final fixture = EntityFixtureGateway(data);
      final service = DiscordBotChannelQueryService(
        client: fixture,
        guildId: Snowflake(10),
      );
      final previous = await service.guildChannelSettings(
        budget: CommandExecutionBudget(),
      );
      expect(
        [previous.afkId, previous.rulesId, previous.systemId],
        ['50', '51', '52'],
      );
      data['guilds']['10']['system_channel_id'] = '53';
      expect(
        (await service.guildChannelSettings(
          budget: CommandExecutionBudget(),
        )).systemId,
        '53',
      );
      expect(previous.systemId, '52');
      expect(
        (await service.guildChannelSettings(
          guildId: '20',
          budget: CommandExecutionBudget(),
        )).rulesId,
        '61',
      );
      expect(fixture.requests, [
        {'operation': 'guilds.fetch', 'guild_id': '10'},
        {'operation': 'guilds.fetch', 'guild_id': '10'},
        {'operation': 'guilds.fetch', 'guild_id': '20'},
      ]);
    },
  );
  test(
    'SDK settings validate request and malformed fixtures without retry',
    () async {
      final data = fixtures();
      final fixture = EntityFixtureGateway(data);
      final service = DiscordBotChannelQueryService(
        client: fixture,
        guildId: Snowflake(10),
      );
      await expectLater(
        service.guildChannelSettings(
          guildId: '0',
          budget: CommandExecutionBudget(),
        ),
        throwsArgumentError,
      );
      await expectLater(
        DiscordBotChannelQueryService(
          client: fixture,
        ).guildChannelSettings(budget: CommandExecutionBudget()),
        throwsStateError,
      );
      expect(fixture.requests, isEmpty);
      data['guilds']['10']['rules_channel_id'] = 'bad';
      await expectLater(
        service.guildChannelSettings(budget: CommandExecutionBudget()),
        throwsStateError,
      );
      expect(fixture.requests, hasLength(1));
    },
  );
  test(
    'SDK aggregate registers settings functions and remote category lookup',
    () async {
      final data = fixtures();
      data['guilds']['10']['afk_channel_id'] = '50';
      data['guilds']['20']['rules_channel_id'] = '61';
      (data['guilds']['20']['channels'] as List).add({
        'id': '41',
        'name': 'remote category',
        'type': 'category',
      });
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: EntityFixtureGateway(data),
          guildId: Snowflake(10),
        ),
      );
      expect(
        await engine.execute(
          r'$afkChannelID|$rulesChannelID[20]|$randomCategoryID[20]',
        ),
        '50|61|41',
      );
    },
  );
  test(
    'sandbox settings and missing channel errors use shared native services',
    () async {
      final data = fixtures();
      data['guilds']['10']['afk_channel_id'] = '50';
      data['guilds']['20']['rules_channel_id'] = '61';
      final result = await testCommandInSandbox({
        'script':
            r'$afkChannelID|$rulesChannelID[20]|$try$systemChannelID$catch missing$endtry|$randomCategoryID',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '50|61| missing|31');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'special channel reads obey deadline and do not start later reads',
    () async {
      final queries = _Queries()..delay = const Duration(milliseconds: 50);
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      );
      await expectLater(
        _engine(
          queries,
        ).execute(r'$afkChannelID$rulesChannelID', context: context),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(queries.settingGuilds, [null]);
    },
  );
  test(
    'randomChannelID uses current guild list without active threads',
    () async {
      final queries = _Queries()
        ..data = [
          const BotChannel(id: '31', name: 'category', type: 'category'),
        ];
      final context = BdfdContext();
      expect(
        await _engine(queries).execute(r'$randomChannelID', context: context),
        '31',
      );
      expect(queries.guilds, [null]);
      expect(queries.withThreads, [false]);
      expect(identical(queries.budgets.single, context.budget), true);
      queries.data = [];
      expect(await _engine(queries).execute(r'$randomChannelID'), '');
    },
  );
  test(
    'randomChannelID refuses arguments and remains opaque under unknown wrapper',
    () async {
      final queries = _Queries();
      await expectLater(
        _engine(queries).execute(r'$randomChannelID[20]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        await _engine(queries).execute(r'$notReal[$randomChannelID]'),
        r'$notReal[$randomChannelID]',
      );
      expect(queries.guilds, isEmpty);
      BdfdEngine.validation().prepare(r'$randomChannelID');
    },
  );
  test(
    'SDK random channel candidates stay in current guild and exclude threads',
    () async {
      final fixture = EntityFixtureGateway(fixtures());
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelQueries: DiscordBotChannelQueryService(
          client: fixture,
          guildId: Snowflake(10),
        ),
      );
      expect(await engine.execute(r'$randomChannelID'), isIn(['30', '31']));
      expect(fixture.requests.where((r) => r['guild_id'] == '20'), isEmpty);
      expect(
        fixture.requests.where(
          (r) => r['operation'].toString().contains('threads'),
        ),
        isEmpty,
      );
    },
  );
  test(
    'slowmode is read in seconds from the current or explicit channel',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(
            id: '30',
            name: 'chat',
            type: 'text',
            slowmodeSeconds: 25,
          ),
          const BotChannel(id: '31', name: 'category', type: 'category'),
        ];
      final context = BdfdContext(variables: {'channel.id': '30'});
      expect(
        await _engine(
          q,
        ).execute(r'$getSlowmode|$getSlowmode[31]', context: context),
        '25|0',
      );
      expect(q.ids, ['30', '31']);
      expect(q.budgets, everyElement(same(context.budget)));
    },
  );
  test(
    'invalid slowmode IDs do not fall back to the current channel',
    () async {
      for (final source in [
        r'$getSlowmode[]',
        r'$getSlowmode[bad]',
        r'$getSlowmode[30;31]',
      ]) {
        final q = _Queries();
        await expectLater(
          _engine(q).execute(
            source,
            context: BdfdContext(variables: {'channel.id': '30'}),
          ),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(q.budgets, isEmpty);
      }
    },
  );
  test(
    'server channel existence uses only exact names or IDs in the current guild',
    () async {
      final q = _Queries();
      expect(
        await _engine(q).execute(
          r'$serverChannelExists[chat]|$serverChannelExists[31]|$serverChannelExists[40]|$serverChannelExists[chat*]|$serverChannelExists[.*]|$serverChannelExists[<#30>]|$serverChannelExists[]',
        ),
        'true|true|false|false|false|false|false',
      );
      expect(q.guilds, List.filled(6, null));
      expect(q.withThreads, everyElement(isTrue));
      expect(q.ids, isEmpty);
      q.budgets.clear();
      await expectLater(
        _engine(q).execute(r'$serverChannelExists[chat;20]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.budgets, isEmpty);
    },
  );
  test(
    'SDK slowmode snapshots cover text forums and active threads and stay fresh',
    () async {
      final data = forumFixtures();
      data['guilds']['10']['channels'][0]['slowmode'] = 15;
      data['guilds']['10']['channels'][2]['slowmode'] = 30;
      data['guilds']['10']['threads'][0]['slowmode'] = 5;
      final gateway = EntityFixtureGateway(data);
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
        await native.execute(
          r'$getSlowmode[30]|$getSlowmode[32]|$getSlowmode[501]|$serverChannelExists[501]|$serverChannelExists[40]',
        ),
        '15|30|5|true|false',
      );
      data['guilds']['10']['channels'][0]['slowmode'] = 0;
      expect(await native.execute(r'$getSlowmode[30]'), '0');
      final result = await testCommandInSandbox({
        'script':
            r'$getSlowmode|$getSlowmode[32]|$getSlowmode[501]|$serverChannelExists[501]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'channel.id': '30'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '0|30|5|true');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'server lookup errors remain errors and unknown wrappers never inspect slowmode arguments',
    () async {
      final q = _Queries()..fail = true;
      await expectLater(
        _engine(q).execute(r'$serverChannelExists[chat]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.guilds, [null]);
      q.budgets.clear();
      expect(
        await _engine(
          q,
        ).execute(r'$unknown[$getSlowmode[];$serverChannelExists[]]'),
        r'$unknown[$getSlowmode[];$serverChannelExists[]]',
      );
      expect(q.budgets, isEmpty);
    },
  );
  test('slowmode and server existence signatures validate without reads', () {
    expect(
      () => BdfdEngine.validation().prepare(
        r'$getSlowmode$getSlowmode[30]$serverChannelExists[]',
      ),
      returnsNormally,
    );
  });

  test(
    'categoryChannels supports all official output options and empty separators',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(
            id: '31',
            name: 'category',
            type: 'category',
            guildId: '10',
          ),
          const BotChannel(
            id: '30',
            name: 'chat',
            type: 'text',
            parentId: '31',
            guildId: '10',
          ),
          const BotChannel(
            id: '32',
            name: 'forum',
            type: 'forum',
            parentId: '31',
            guildId: '10',
          ),
          const BotChannel(
            id: '33',
            name: 'elsewhere',
            type: 'text',
            guildId: '10',
          ),
        ];
      final context = BdfdContext();
      expect(
        await _engine(q).execute(
          r'$categoryChannels[31;#]|$categoryChannels[31;;id]|$categoryChannels[31;#;mention]|$categoryChannels[31;ignored;count]',
          context: context,
        ),
        'chat#forum|3032|<#30>#<#32>|2',
      );
      expect(q.guilds, ['10', '10', '10', '10']);
      expect(q.withThreads, everyElement(isFalse));
      expect(q.budgets, everyElement(same(context.budget)));
    },
  );
  test('empty categories return empty lists and a count of zero', () async {
    final q = _Queries()
      ..data = [
        const BotChannel(
          id: '31',
          name: 'category',
          type: 'category',
          guildId: '10',
        ),
      ];
    expect(
      await _engine(
        q,
      ).execute(r'$categoryChannels[31;#]|$categoryChannels[31;#;count]'),
      '|0',
    );
  });
  test(
    'invalid category options and IDs are refused before any service reads',
    () async {
      for (final source in [
        r'$categoryChannels[31]',
        r'$categoryChannels[;#]',
        r'$categoryChannels[bad;#]',
        r'$categoryChannels[31;#;bad]',
        r'$categoryChannels[31;#;]',
        r'$categoryChannels[31;#;id;extra]',
      ]) {
        final q = _Queries();
        await expectLater(
          _engine(q).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(q.budgets, isEmpty);
      }
    },
  );
  test(
    'a missing category or another channel type never triggers a category list read',
    () async {
      final q = _Queries();
      await expectLater(
        _engine(q).execute(r'$categoryChannels[999;#]'),
        throwsA(isA<BdfdNativeError>()),
      );
      await expectLater(
        _engine(q).execute(r'$categoryChannels[30;#]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.guilds, isEmpty);
    },
  );
  test(
    'category output remains opaque even with function-looking names and separators',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(
            id: '31',
            name: 'category',
            type: 'category',
            guildId: '10',
          ),
          const BotChannel(
            id: '30',
            name: r'$unknown[$channelName[]]',
            type: 'text',
            parentId: '31',
          ),
          const BotChannel(
            id: '32',
            name: 'other',
            type: 'text',
            parentId: '31',
          ),
        ];
      expect(
        await _engine(
          q,
        ).execute(r'$categoryChannels[31;$unknown[$categoryChannels[bad]]]'),
        r'$unknown[$channelName[]]$unknown[$categoryChannels[bad]]other',
      );
    },
  );
  test(
    'positions use the current or explicit ID without fallback from empty arguments',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(id: '30', name: 'chat', type: 'text', position: 2),
          const BotChannel(
            id: '31',
            name: 'category',
            type: 'category',
            position: 0,
          ),
        ];
      expect(
        await _engine(q).execute(
          r'$channelPosition|$channelPosition[31]',
          context: BdfdContext(variables: {'channel.id': '30'}),
        ),
        '2|0',
      );
      q.budgets.clear();
      await expectLater(
        _engine(q).execute(r'$channelPosition[]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.budgets, isEmpty);
    },
  );
  test(
    'SDK and sandbox list the category owning guild even when the current guild differs',
    () async {
      final data = fixtures();
      (data['guilds']['20']['channels'] as List).add({
        'id': '41',
        'name': 'remote-category',
        'type': 'category',
      });
      data['guilds']['20']['channels'][0]['parent_id'] = '41';
      data['guilds']['20']['channels'][0]['position'] = 7;
      final gateway = EntityFixtureGateway(data);
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
        await native.execute(r'$categoryChannels[41;;id]|$channelPosition[40]'),
        '40|7',
      );
      expect(
        gateway.requests
            .where((r) => r['operation'] == 'guild.channels')
            .map((r) => r['guild_id']),
        ['20'],
      );
      final result = await testCommandInSandbox({
        'script':
            r'$categoryChannels[41;;mention]|$categoryChannels[41;;count]|$channelPosition',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'channel.id': '40'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '<#40>|1|7');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'validation registers category listing and position signatures without effects',
    () {
      expect(
        () => BdfdEngine.validation().prepare(
          r'$categoryChannels[31;;count]$channelPosition$channelPosition[30]',
        ),
        returnsNormally,
      );
    },
  );

  test(
    'current channel IDs follow DM semantics without any SDK reads',
    () async {
      final q = _Queries();
      for (final variables in [
        {'channel.id': '30', 'guild.id': ''},
        {'channel.id': '30', 'channel.type': 'dm'},
        {'channel.id': '30', 'channel.type': 'group_dm'},
      ]) {
        expect(
          await _engine(
            q,
          ).execute(r'$channelID', context: BdfdContext(variables: variables)),
          'none',
        );
        expect(
          await BdfdEngine(
            store: MemoryBotDataStore(),
            botId: 'bot',
          ).execute(r'$channelID', context: BdfdContext(variables: variables)),
          'none',
        );
      }
      expect(
        await _engine(q).execute(
          r'$channelID',
          context: BdfdContext(
            variables: {'channel.id': '30', 'guild.id': '10'},
          ),
        ),
        '30',
      );
      expect(q.budgets, isEmpty);
    },
  );
  test(
    'name lookups distinguish categories and never fall back on empty input',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(id: '30', name: 'same', type: 'text'),
          const BotChannel(id: '31', name: 'same', type: 'category'),
        ];
      expect(
        await _engine(
          q,
        ).execute(r'$channelID[same]|$categoryID[same]|$channelID[missing]'),
        '30|31|',
      );
      expect(q.withThreads, [true, false, true]);
      for (final source in [
        r'$channelID[]',
        r'$categoryID[]',
        r'$categoryID',
        r'$parentID[]',
      ]) {
        q.budgets.clear();
        await expectLater(
          _engine(q).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(q.budgets, isEmpty);
      }
    },
  );
  test(
    'findChannel accepts names IDs and mentions from the guild inventory only',
    () async {
      final q = _Queries();
      expect(
        await _engine(q).execute(
          r'$findChannel[chat]|$findChannel[30]|$findChannel[<#31>]|$findChannel[40]|$findChannel[]',
        ),
        '30|30|31||',
      );
      expect(q.ids, isEmpty);
      expect(q.guilds, [null, null, null, null]);
      expect(q.withThreads, everyElement(isTrue));
    },
  );
  test(
    'findChannel exact match precedes historical partial-name matching',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(id: '30', name: 'my-chat', type: 'text'),
          const BotChannel(id: '31', name: 'CHAT', type: 'text'),
        ];
      expect(
        await _engine(q).execute(r'$findChannel[chat]|$findChannel[my-]'),
        '31|30',
      );
    },
  );
  test(
    'parent IDs use the current or explicit channel and preserve empty parents',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(
            id: '30',
            name: 'chat',
            type: 'text',
            parentId: '31',
          ),
          const BotChannel(id: '31', name: 'category', type: 'category'),
        ];
      expect(
        await _engine(q).execute(
          r'$parentID|$parentID[31]',
          context: BdfdContext(variables: {'channel.id': '30'}),
        ),
        '31|',
      );
      expect(q.ids, ['30', '31']);
    },
  );
  test(
    'SDK and sandbox search active threads and exclude other guilds and archives',
    () async {
      final data = forumFixtures();
      data['guilds']['10']['threads'][0]['name'] = 'post';
      data['guilds']['10']['threads'][1]['name'] = 'post';
      final gateway = EntityFixtureGateway(data);
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
        await native.execute(
          r'$channelID[category]|$categoryID[category]|$findChannel[<#501>]|$findChannel[40]|$findChannel[503]|$parentID[501]',
        ),
        '31|31|501|||32',
      );
      final values = await service.channels(
        includeActiveThreads: true,
        budget: CommandExecutionBudget(),
      );
      expect(values.where((c) => c.id == '501'), hasLength(1));
      expect(values.where((c) => c.id == '503'), isEmpty);
      expect(values.first.guildId, '10');
      expect(() => values.clear(), throwsUnsupportedError);
      final result = await testCommandInSandbox({
        'script':
            r'$channelID[post]|$findChannel[<#501>]|$parentID[501]|$categoryID[category]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '501|501|32|31');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'name lookup failures remain errors and unknown search calls stay opaque',
    () async {
      final q = _Queries()..fail = true;
      await expectLater(
        _engine(q).execute(r'$findChannel[chat]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.guilds, [null]);
      q.budgets.clear();
      expect(
        await _engine(
          q,
        ).execute(r'$unknown[$channelID[];$findChannel[];$parentID[]]'),
        r'$unknown[$channelID[];$findChannel[];$parentID[]]',
      );
      expect(q.budgets, isEmpty);
    },
  );
  test('validation registers lookup signatures without accessing services', () {
    expect(
      () => BdfdEngine.validation().prepare(
        r'$channelID$channelID[chat]$findChannel[<#30>]$categoryID[category]$parentID$parentID[30]',
      ),
      returnsNormally,
    );
  });

  test(
    'an expired count budget prevents the second SDK read even after the first returns',
    () async {
      final guild = _DelayedGuild(EntityFixtureGateway(forumFixtures()));
      final service = DiscordBotChannelQueryService(
        client: _CountGateway(guild),
        guildId: Snowflake(10),
      );
      await expectLater(
        service.countChannels(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(guild.activeReads, 0);
    },
  );
  test(
    'native channel and category counts use the parent budget and official shapes',
    () async {
      final q = _Queries();
      final context = BdfdContext();
      expect(
        await _engine(q).execute(
          r'$channelCount|$categoryCount|$categoryCount[20]',
          context: context,
        ),
        '2|1|1',
      );
      expect(q.counts, 1);
      expect(q.guilds, [null, '20']);
      expect(q.budgets, everyElement(same(context.budget)));
    },
  );
  test(
    'count arguments fail before reads and unknown wrappers stay opaque',
    () async {
      final q = _Queries();
      for (final source in [
        r'$channelCount[10]',
        r'$categoryCount[]',
        r'$categoryCount[bad]',
        r'$categoryCount[10;20]',
      ]) {
        await expectLater(
          _engine(q).execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(
        await _engine(
          q,
        ).execute(r'$unknown[$channelCount[bad];$categoryCount[]]'),
        r'$unknown[$channelCount[bad];$categoryCount[]]',
      );
      expect(q.budgets, isEmpty);
    },
  );
  test(
    'SDK count includes categories and active forum posts with no duplicates',
    () async {
      final data = forumFixtures();
      final gateway = EntityFixtureGateway(data);
      final service = DiscordBotChannelQueryService(
        client: gateway,
        guildId: Snowflake(10),
      );
      expect(await service.countChannels(budget: CommandExecutionBudget()), 5);
      expect(gateway.requests.map((r) => r['operation']), [
        'guild.channels',
        'guild.activeThreads',
      ]);
      (data['guilds']['10']['threads'] as List)[2]['archived'] = true;
      expect(await service.countChannels(budget: CommandExecutionBudget()), 4);
    },
  );
  test('SDK count without forums does not query active threads', () async {
    final gateway = EntityFixtureGateway(fixtures());
    final service = DiscordBotChannelQueryService(
      client: gateway,
      guildId: Snowflake(10),
    );
    expect(await service.countChannels(budget: CommandExecutionBudget()), 2);
    expect(gateway.requests.map((r) => r['operation']), ['guild.channels']);
  });
  test(
    'SDK count fails when guild or required active thread data is missing',
    () async {
      final data = forumFixtures();
      (data['guilds']['10'] as Map).remove('threads');
      final gateway = EntityFixtureGateway(data);
      final service = DiscordBotChannelQueryService(
        client: gateway,
        guildId: Snowflake(10),
      );
      await expectLater(
        service.countChannels(budget: CommandExecutionBudget()),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        DiscordBotChannelQueryService(
          client: gateway,
        ).countChannels(budget: CommandExecutionBudget()),
        throwsA(isA<StateError>()),
      );
    },
  );
  test('sandbox counts and reads forums using the production services', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$channelCount|$categoryCount|$categoryCount[20]|$channelType[32]|$channelTopic|$channelNames[#]',
      'bdfdBackend': 'native-v1',
      'variables': {'guild.id': '10', 'channel.id': '32'},
      'entities': forumFixtures(),
    });
    expect(result['success'], true, reason: '$result');
    expect(
      result['responses'][0]['payload']['content'],
      '5|1|0|forum|forum topic|chat#category#forum',
    );
    expect(result['effects'], isEmpty);
  });
  test('counts are part of validation without any service execution', () {
    expect(
      () => BdfdEngine.validation().prepare(
        r'$channelCount$categoryCount$categoryCount[20]',
      ),
      returnsNormally,
    );
  });

  test('SDK channel types use the official BDFD labels', () async {
    for (final entry in {
      0: 'text',
      1: 'dm',
      2: 'voice',
      3: 'dm',
      4: 'category',
      5: 'announcement',
      10: 'thread',
      11: 'thread',
      12: 'thread',
      13: 'stage',
      15: 'forum',
    }.entries) {
      final service = DiscordBotChannelQueryService(
        client: _Gateway(() async => _SdkChannel(ChannelType(entry.key))),
      );
      expect(
        (await service.channel('30', budget: CommandExecutionBudget()))?.type,
        entry.value,
      );
    }
  });
  test(
    'SDK converts only a definite unknown channel into an absent result',
    () async {
      final absent = DiscordBotChannelQueryService(
        client: _Gateway(() async => throw _DiscordError(404, 10003)),
      );
      expect(
        await absent.channel('30', budget: CommandExecutionBudget()),
        isNull,
      );
      for (final error in [
        _DiscordError(403, 50001),
        _DiscordError(404, 10004),
        StateError('network failure'),
      ]) {
        final service = DiscordBotChannelQueryService(
          client: _Gateway(() async => throw error),
        );
        await expectLater(
          service.channel('30', budget: CommandExecutionBudget()),
          throwsA(same(error)),
        );
      }
    },
  );
  test(
    'channel reads use official argument shapes and the parent budget',
    () async {
      final q = _Queries();
      final context = BdfdContext(variables: {'channel.id': '30'});
      expect(
        await _engine(q).execute(
          r'$channelName[30]|$channelType[31]|$isNSFW[30]|$channelTopic|$channelExists[999]',
          context: context,
        ),
        r'chat|category|true|$sendMessage[topic]|false',
      );
      expect(q.budgets, everyElement(same(context.budget)));
      expect(q.ids, ['30', '31', '30', '30', '999']);
    },
  );
  test(
    'channel names retain empty separators and the explicit guild',
    () async {
      final q = _Queries();
      expect(
        await _engine(q).execute(r'$channelNames[]|$channelNames[#;20]'),
        'chatcategory|chat#category',
      );
      expect(q.guilds, [null, '20']);
    },
  );
  test('empty or non-ID existence queries return false without reads', () async {
    final q = _Queries();
    expect(
      await _engine(q).execute(
        r'$channelExists[]|$channelExists[name]|$channelExists[-1]|$channelExists[0]',
      ),
      'false|false|false|false',
    );
    expect(q.ids, isEmpty);
  });
  for (final source in [
    r'$channelName',
    r'$channelName[]',
    r'$channelType[bad]',
    r'$isNSFW[0]',
    r'$channelTopic[30]',
    r'$channelNames',
    r'$channelNames[#;]',
    r'$channelNames[#;bad]',
    r'$channelExists',
  ]) {
    test('$source fails before service reads', () async {
      final q = _Queries();
      await expectLater(
        _engine(q).execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.budgets, isEmpty);
    });
  }
  test(
    'missing channels are errors for fields, and missing current ID never falls back',
    () async {
      final q = _Queries();
      await expectLater(
        _engine(q).execute(r'$channelName[999]'),
        throwsA(isA<BdfdNativeError>()),
      );
      q.ids.clear();
      await expectLater(
        _engine(q).execute(r'$channelTopic'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(q.ids, isEmpty);
    },
  );
  test(
    'unknown wrappers are opaque and names are never reinterpreted',
    () async {
      final q = _Queries()
        ..data = [
          const BotChannel(
            id: '30',
            name: r'$unknown[$channelType[bad]]',
            type: 'text',
          ),
        ];
      expect(
        await _engine(q).execute(r'$unknown[$channelName[]]|$channelName[30]'),
        r'$unknown[$channelName[]]|$unknown[$channelType[bad]]',
      );
      expect(q.ids, ['30']);
    },
  );
  test('read failures are not converted to false or retried', () async {
    final q = _Queries()..fail = true;
    await expectLater(
      _engine(q).execute(r'$channelExists[30]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(q.ids, ['30']);
  });
  test('reads obey the execution deadline', () async {
    final q = _Queries()..delay = const Duration(milliseconds: 100);
    await expectLater(
      _engine(q).execute(
        r'$channelName[30]',
        context: BdfdContext(
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(q.ids, ['30']);
  });
  test(
    'SDK aggregate reads any accessible guild and snapshots are immutable',
    () async {
      final gateway = EntityFixtureGateway(fixtures());
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
        await native.execute(
          r'$channelExists[40]|$channelName[40]|$channelType[31]|$channelNames[#;20]',
        ),
        'true|remote|category|remote',
      );
      final channels = await service.channels(budget: CommandExecutionBudget());
      expect(channels.map((c) => c.name), ['chat', 'category']);
      expect(() => channels.clear(), throwsUnsupportedError);
      expect(
        await service.channel('999', budget: CommandExecutionBudget()),
        isNull,
      );
      await DiscordEntityFetcher.hydrateEntity(
        gateway,
        'categoryChannels',
        'all;#;10',
        {},
      );
      expect(
        gateway.requests.where((r) => r['operation'] == 'guild.channels'),
        isNotEmpty,
      );
    },
  );
  test(
    'sandbox uses real query services without moderation permissions',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$channelName[40]|$channelExists[999]|$channelNames[#;20]|$channelTopic|$isNSFW[30]',
        'bdfdBackend': 'native-v1',
        'variables': {'channel.id': '30'},
        'entities': fixtures(),
      });
      expect(result['success'], true, reason: '$result');
      expect(
        result['responses'][0]['payload']['content'],
        'remote|false|remote|topic|true',
      );
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'production validation registers channel queries without executing services',
    () {
      expect(
        () => BdfdEngine.validation().prepare(
          r'$channelName[30]$channelExists[]$channelType[31]$channelNames[;20]$isNSFW[30]$channelTopic',
        ),
        returnsNormally,
      );
    },
  );
}
