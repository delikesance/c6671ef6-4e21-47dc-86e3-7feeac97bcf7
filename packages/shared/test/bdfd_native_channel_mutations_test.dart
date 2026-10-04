import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_channel_mutation_service.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/actions/slowmode.dart';
import 'package:bot_creator_shared/actions/remove_channel.dart';
import 'package:bot_creator_shared/actions/update_channel.dart';
import 'package:bot_creator_shared/actions/create_channel.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Mutations implements BotChannelMutationService {
  final changes = <SlowmodeChange>[];
  final budgets = <CommandExecutionBudget>[];
  final creations = <ChannelCreation>[];
  @override
  Future<String> createChannel(
    ChannelCreation change, {
    required CommandExecutionBudget budget,
  }) async {
    creations.add(change);
    budgets.add(budget);
    return '800';
  }

  final modifications = <ChannelModification>[];
  @override
  Future<void> modifyChannel(
    ChannelModification change, {
    required CommandExecutionBudget budget,
  }) async {
    modifications.add(change);
    budgets.add(budget);
  }

  final deletions = <ChannelDeletion>[];
  @override
  Future<void> deleteChannel(
    ChannelDeletion change, {
    required CommandExecutionBudget budget,
  }) async {
    deletions.add(change);
    budgets.add(budget);
  }

  @override
  Future<void> setSlowmode(
    SlowmodeChange change, {
    required CommandExecutionBudget budget,
  }) async {
    changes.add(change);
    budgets.add(budget);
  }
}

Map<String, dynamic> fixtures({int permission = 17179870224}) => {
  'guilds': <String, dynamic>{
    '10': <String, dynamic>{
      'owner_id': '999',
      'roles': [
        {'id': '10', 'name': '@everyone', 'permissions': '0'},
        {'id': '63', 'name': 'bot', 'permissions': '$permission'},
      ],
      'members': {
        '500': {
          'roles': ['63'],
        },
      },
      'channels': <Map<String, dynamic>>[
        {'id': '30', 'name': 'chat', 'type': 'text'},
        {'id': '31', 'name': 'category', 'type': 'category'},
        {'id': '32', 'name': 'forum', 'type': 'forum'},
      ],
      'threads': <Map<String, dynamic>>[
        {'id': '501', 'parent_id': '32'},
      ],
    },
  },
};

class _Bot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway(Map<String, dynamic> data) : fixtures = EntityFixtureGateway(data) {
    manager = _Writes(fixtures);
    guildManager = _GuildWrites(fixtures);
  }
  final EntityFixtureGateway fixtures;
  late final _Writes manager;
  late final _GuildWrites guildManager;
  @override
  PartialUser get user => _Bot();
  @override
  GuildManager get guilds => guildManager;
  @override
  ChannelManager get channels => manager;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuildWrites implements GuildManager {
  _GuildWrites(this.gateway);
  final EntityFixtureGateway gateway;
  final creations = <Map<String, dynamic>>[];
  Duration delay = Duration.zero;
  bool fail = false;
  @override
  Future<Guild> get(Snowflake id) => fetch(id);
  @override
  Future<Guild> fetch(Snowflake id, {bool? withCounts}) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return await gateway.guilds.fetch(id, withCounts: withCounts);
  }

  @override
  PartialGuild operator [](Snowflake id) => gateway.guilds[id];
  @override
  Future<T> createGuildChannel<T extends GuildChannel>(
    Snowflake id,
    GuildChannelBuilder<T> builder, {
    String? auditLogReason,
  }) async {
    final payload = builder.build();
    creations.add({
      'guild_id': '$id',
      'payload': payload,
      'reason': auditLogReason,
    });
    if (fail) throw StateError('Discord refused creation');
    final channelId = '${799 + creations.length}';
    final rows = gateway.fixtures['guilds'][id.toString()]['channels'] as List;
    rows.add(<String, dynamic>{
      'id': channelId,
      'name': payload['name'],
      'type': switch (payload['type']) {
        0 => 'text',
        2 => 'voice',
        4 => 'category',
        5 => 'announcement',
        13 => 'stage',
        15 => 'forum',
        _ => 'bad',
      },
      if (payload.containsKey('parent_id')) 'parent_id': payload['parent_id'],
      if (payload.containsKey('topic')) 'topic': payload['topic'],
      if (payload.containsKey('nsfw')) 'nsfw': payload['nsfw'],
      if (payload.containsKey('rate_limit_per_user'))
        'slowmode': payload['rate_limit_per_user'],
    });
    return await gateway.channels.fetch(Snowflake.parse(channelId)) as T;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Writes implements ChannelManager {
  _Writes(this.gateway);
  final EntityFixtureGateway gateway;
  final changes = <Map<String, dynamic>>[];
  final deletions = <String>[];
  @override
  Future<Channel> delete(Snowflake id, {String? auditLogReason}) async {
    deletions.add('$id');
    if (fail) throw StateError('Discord refused deletion');
    return await gateway.channels.fetch(id);
  }

  Duration delay = Duration.zero;
  bool fail = false;
  Channel? overrideChannel;
  @override
  Future<Channel> fetch(Snowflake id) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return overrideChannel ?? await gateway.channels.fetch(id);
  }

  @override
  Future<Channel> update(
    Snowflake id,
    UpdateBuilder<Channel> builder, {
    String? auditLogReason,
  }) async {
    changes.add({
      'id': '$id',
      'payload': builder.build(),
      'reason': auditLogReason,
    });
    if (fail) throw StateError('Discord refused update');
    return overrideChannel ?? await gateway.channels.fetch(id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Announcement implements GuildAnnouncementChannel {
  @override
  List<PermissionOverwrite> get permissionOverwrites => const [];
  @override
  Snowflake get id => Snowflake(40);
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Voice implements GuildVoiceChannel {
  @override
  Snowflake get id => Snowflake(60);
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  List<PermissionOverwrite> get permissionOverwrites => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stage implements GuildStageChannel {
  @override
  Snowflake get id => Snowflake(61);
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  List<PermissionOverwrite> get permissionOverwrites => const [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'native aggregate creation is visible to its shared query service',
    () async {
      final gateway = _Gateway(fixtures());
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      );
      expect(
        await engine.execute(
          r'$createChannel[new;text]$channelID[new]',
          context: BdfdContext(variables: {'guild.id': '10'}),
        ),
        '800',
      );
      expect(gateway.guildManager.creations, hasLength(1));
      expect(gateway.manager.changes, isEmpty);
    },
  );
  test(
    'native createChannel follows required wiki arguments and returns no text',
    () async {
      final service = _Mutations();
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelMutations: service,
      );
      final context = BdfdContext(variables: {'guild.id': '10'});
      expect(
        await engine.execute(r'$createChannel[new;TEXT;31]', context: context),
        '',
      );
      final request = service.creations.single;
      expect(
        [request.guildId, request.name, request.type, request.categoryId],
        ['10', 'new', 'text', '31'],
      );
      expect(identical(service.budgets.single, context.budget), true);
      service.creations.clear();
      for (final source in [
        r'$createChannel[name]',
        r'$createChannel[;text]',
        r'$createChannel[name;]',
        r'$createChannel[name;announcement]',
        r'$createChannel[name;unknown]',
        r'$createChannel[name;text;]',
        r'$createChannel[name;text;-1]',
        r'$createChannel[name;category;31]',
        r'$createChannel[name;text;31;extra]',
      ]) {
        await expectLater(
          engine.execute(source, context: context),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.creations, isEmpty);
      }
      await expectLater(
        engine.execute(r'$createChannel[name;text]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.creations, isEmpty);
      expect(
        await engine.execute(r'$unknown[$createChannel[never;text]]'),
        r'$unknown[$createChannel[never;text]]',
      );
      expect(service.creations, isEmpty);
      expect(
        () => BdfdEngine.validation().prepare(r'$createChannel[name;text]'),
        returnsNormally,
      );
    },
  );
  for (final entry in {
    'text': 0,
    'voice': 2,
    'category': 4,
    'stage': 13,
    'forum': 15,
  }.entries) {
    test(
      'SDK and sandbox create official type ${entry.key} with fresh queries',
      () async {
        final gateway = _Gateway(fixtures());
        final request = ChannelCreation(
          guildId: '10',
          name: 'new',
          type: entry.key,
          categoryId: entry.key == 'category' ? null : '31',
        );
        final id = await DiscordBotChannelMutationService(
          gateway,
        ).createChannel(request, budget: CommandExecutionBudget());
        expect(id, '800');
        expect(gateway.guildManager.creations.single['payload'], {
          'name': 'new',
          'type': entry.value,
          if (entry.key != 'category') 'parent_id': '31',
        });
        expect(gateway.manager.changes, isEmpty);
        final script =
            '\$createChannel[new;${entry.key}${entry.key == 'category' ? '' : ';31'}]\$channelType[\$channelID[new]]|\$channelCount';
        final result = await testCommandInSandbox({
          'script': script,
          'bdfdBackend': 'native-v1',
          'variables': {'guild.id': '10', 'bot.id': '500'},
          'entities': fixtures(),
        });
        expect(result['success'], true, reason: '$result');
        expect(result['responses'][0]['payload']['content'], '${entry.key}|5');
        expect((result['effects'] as List).single['type'], 'createChannel');
      },
    );
  }
  test(
    'typed creation rejects invalid fields before reads or writes',
    () async {
      final gateway = _Gateway(fixtures());
      for (final request in [
        const ChannelCreation(guildId: '0', name: 'new', type: 'text'),
        const ChannelCreation(guildId: '10', name: '', type: 'text'),
        ChannelCreation(guildId: '10', name: 'x' * 101, type: 'text'),
        const ChannelCreation(guildId: '10', name: 'new', type: 'bad'),
        const ChannelCreation(
          guildId: '10',
          name: 'new',
          type: 'text',
          categoryId: 'bad',
        ),
        const ChannelCreation(
          guildId: '10',
          name: 'new',
          type: 'category',
          isNsfw: false,
        ),
        const ChannelCreation(
          guildId: '10',
          name: 'new',
          type: 'voice',
          topic: 'bad',
        ),
        const ChannelCreation(
          guildId: '10',
          name: 'new',
          type: 'text',
          slowmodeSeconds: 21601,
        ),
      ]) {
        await expectLater(
          DiscordBotChannelMutationService(
            gateway,
          ).createChannel(request, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
        expect(gateway.fixtures.requests, isEmpty);
        expect(gateway.guildManager.creations, isEmpty);
      }
    },
  );
  test(
    'creation refuses wrong category type and foreign guild before POST',
    () async {
      final data = fixtures();
      data['guilds']['20'] = fixtures()['guilds']['10'];
      data['guilds']['20']['channels'] = <Map<String, dynamic>>[
        {'id': '41', 'name': 'other', 'type': 'category'},
      ];
      final gateway = _Gateway(data);
      for (final category in ['30', '41']) {
        await expectLater(
          DiscordBotChannelMutationService(gateway).createChannel(
            ChannelCreation(
              guildId: '10',
              name: 'new',
              type: 'text',
              categoryId: category,
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsArgumentError,
        );
        expect(gateway.guildManager.creations, isEmpty);
      }
    },
  );
  test(
    'creation needs guild permission even when category grants manage channels',
    () async {
      final data = fixtures(permission: 0);
      data['guilds']['10']['channels'][1]['permission_overwrites'] = [
        <String, dynamic>{'id': '500', 'type': 1, 'allow': '1040'},
      ];
      final gateway = _Gateway(data);
      await expectLater(
        DiscordBotChannelMutationService(gateway).createChannel(
          const ChannelCreation(
            guildId: '10',
            name: 'new',
            type: 'text',
            categoryId: '31',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.guildManager.creations, isEmpty);
      final result = await testCommandInSandbox({
        'script': r'$createChannel[new;text;31]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
    },
  );
  test('creation owner bypass and SDK errors do not retry', () async {
    final data = fixtures(permission: 0);
    data['guilds']['10']['owner_id'] = '500';
    final gateway = _Gateway(data);
    expect(
      await DiscordBotChannelMutationService(gateway).createChannel(
        const ChannelCreation(guildId: '10', name: 'new', type: 'text'),
        budget: CommandExecutionBudget(),
      ),
      '800',
    );
    gateway.guildManager.fail = true;
    await expectLater(
      DiscordBotChannelMutationService(gateway).createChannel(
        const ChannelCreation(guildId: '10', name: 'another', type: 'text'),
        budget: CommandExecutionBudget(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.guildManager.creations, hasLength(2));
  });
  test(
    'SDK and visual creation expiration prevents POST after late guild read',
    () async {
      final gateway = _Gateway(fixtures());
      gateway.guildManager.delay = const Duration(milliseconds: 50);
      await expectLater(
        DiscordBotChannelMutationService(gateway).createChannel(
          const ChannelCreation(guildId: '10', name: 'new', type: 'text'),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await expectLater(
        createChannelAction(
          gateway,
          guildId: Snowflake(10),
          payload: {'name': 'new'},
          resolve: (s) => s,
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.guildManager.creations, isEmpty);
    },
  );
  test(
    'visual creation includes all options in a single POST and preserves result',
    () async {
      final gateway = _Gateway(fixtures());
      final resolved = <String>[];
      final result = await createChannelAction(
        gateway,
        guildId: Snowflake(10),
        payload: {
          'name': 'new',
          'type': 'text',
          'categoryId': '31',
          'topic': 'topic',
          'nsfw': 'yes',
          'slowmode': '5s',
          'reason': 'audit',
        },
        resolve: (s) {
          resolved.add(s);
          return s;
        },
      );
      expect(result, {'channelId': '800'});
      expect(resolved, ['new', 'text', '31', 'topic', '5s', 'yes', 'audit']);
      expect(gateway.guildManager.creations.single['payload'], {
        'name': 'new',
        'type': 0,
        'parent_id': '31',
        'topic': 'topic',
        'nsfw': true,
        'rate_limit_per_user': 5,
      });
      expect(gateway.guildManager.creations.single['reason'], 'audit');
      expect(gateway.manager.changes, isEmpty);
    },
  );
  test(
    'sandbox channel IDs avoid collisions across guilds and creation obeys limit',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'].add(<String, dynamic>{
        'id': '60',
        'name': 'existing',
        'type': 'text',
      });
      final result = await testCommandInSandbox({
        'script': r'$createChannel[new;text]$channelID[new]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '61');
      final full = fixtures();
      full['guilds']['10']['channels'] = <Map<String, dynamic>>[
        for (var i = 0; i < 500; i++)
          {'id': '${1000 + i}', 'name': 'c$i', 'type': 'text'},
      ];
      final denied = await testCommandInSandbox({
        'script': r'$createChannel[new;text]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': full,
      });
      expect(denied['success'], false);
      expect(denied['effects'], isEmpty);
    },
  );
  test(
    'voice and stage modifications include SDK-missing rate field and require connect',
    () async {
      for (final target in <GuildChannel>[_Voice(), _Stage()]) {
        final gateway = _Gateway(fixtures(permission: 1049616));
        gateway.manager.overrideChannel = target;
        await DiscordBotChannelMutationService(gateway).modifyChannel(
          ChannelModification(
            channelId: '${target.id}',
            name: 'new',
            isNsfw: false,
            slowmodeSeconds: 5,
          ),
          budget: CommandExecutionBudget(),
        );
        expect(gateway.manager.changes.single['payload'], {
          'name': 'new',
          'nsfw': false,
          'rate_limit_per_user': 5,
        });
        gateway.manager.changes.clear();
        await expectLater(
          DiscordBotChannelMutationService(gateway).modifyChannel(
            ChannelModification(
              channelId: '${target.id}',
              topic: 'unsupported',
            ),
            budget: CommandExecutionBudget(),
          ),
          throwsArgumentError,
        );
        expect(gateway.manager.changes, isEmpty);
        final denied = _Gateway(fixtures(permission: 1040));
        denied.manager.overrideChannel = target;
        await expectLater(
          DiscordBotChannelMutationService(denied).modifyChannel(
            ChannelModification(channelId: '${target.id}', name: 'new'),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(denied.manager.changes, isEmpty);
      }
    },
  );
  test(
    'typed modification rejects invalid names positions duration and IDs before reads',
    () async {
      final gateway = _Gateway(fixtures());
      for (final change in [
        const ChannelModification(channelId: '0'),
        const ChannelModification(channelId: '30', categoryId: 'bad'),
        const ChannelModification(channelId: '30', name: ''),
        ChannelModification(channelId: '30', name: 'x' * 101),
        const ChannelModification(channelId: '30', position: -1),
        const ChannelModification(channelId: '30', slowmodeSeconds: 21601),
        const ChannelModification(channelId: '30', autoArchiveMinutes: 7),
      ]) {
        await expectLater(
          DiscordBotChannelMutationService(
            gateway,
          ).modifyChannel(change, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
        expect(gateway.fixtures.requests, isEmpty);
        expect(gateway.manager.changes, isEmpty);
      }
    },
  );
  test('visual modification propagates timeout without later write', () async {
    final gateway = _Gateway(fixtures());
    gateway.manager.delay = const Duration(milliseconds: 50);
    await expectLater(
      updateChannelAction(
        gateway,
        payload: {'channelId': '30', 'name': 'new'},
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(gateway.manager.changes, isEmpty);
  });
  test(
    'native modifyChannel follows wiki argument order unchanged and one-based position',
    () async {
      final service = _Mutations();
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelMutations: service,
      );
      final context = BdfdContext();
      expect(
        await engine.execute(
          r'$modifyChannel[30;renamed;new topic;yes;1;31]',
          context: context,
        ),
        '',
      );
      final change = service.modifications.single;
      expect(change.channelId, '30');
      expect(change.name, 'renamed');
      expect(change.topic, 'new topic');
      expect(change.isNsfw, true);
      expect(change.position, 0);
      expect(change.categoryId, '31');
      expect(identical(service.budgets.single, context.budget), true);
      service.modifications.clear();
      await engine.execute(
        r'$modifyChannel[30;!unchanged;!unchanged;!unchanged;!unchanged;!unchanged]',
      );
      final unchanged = service.modifications.single;
      expect([
        unchanged.name,
        unchanged.topic,
        unchanged.isNsfw,
        unchanged.position,
        unchanged.categoryId,
      ], everyElement(isNull));
      service.modifications.clear();
      await engine.execute(r'$modifyChannel[30;!unchanged;;no]');
      expect(service.modifications.single.topic, '');
      expect(service.modifications.single.isNsfw, false);
    },
  );
  test(
    'native invalid modifications and unknown wrappers never call adapter',
    () async {
      final service = _Mutations();
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelMutations: service,
      );
      for (final code in [
        r'$modifyChannel',
        r'$modifyChannel[]',
        r'$modifyChannel[-1]',
        r'$modifyChannel[30;n;t;maybe]',
        r'$modifyChannel[30;n;t;yes;0]',
        r'$modifyChannel[30;n;t;yes;1;bad]',
        r'$modifyChannel[30;n;t;yes;1;31;extra]',
      ]) {
        await expectLater(
          engine.execute(code),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.modifications, isEmpty);
      }
      expect(
        await engine.execute(r'$unknown[$modifyChannel[30;never]]'),
        r'$unknown[$modifyChannel[30;never]]',
      );
      expect(service.modifications, isEmpty);
      expect(
        () => BdfdEngine.validation().prepare(r'$modifyChannel[30;name]'),
        returnsNormally,
      );
    },
  );
  test(
    'SDK rename omits unchanged nullable fields and empty modification skips PATCH',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'][0].addAll({
        'parent_id': '31',
        'topic': 'keep',
        'slowmode': 50,
      });
      final gateway = _Gateway(data);
      final service = DiscordBotChannelMutationService(gateway);
      await service.modifyChannel(
        const ChannelModification(channelId: '30', name: 'new'),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.changes.single['payload'], {'name': 'new'});
      await service.modifyChannel(
        const ChannelModification(channelId: '30'),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.changes, hasLength(1));
      await service.modifyChannel(
        const ChannelModification(
          channelId: '30',
          topic: '',
          isNsfw: false,
          position: 0,
          categoryId: '31',
        ),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.changes.last['payload'], {
        'topic': '',
        'nsfw': false,
        'position': 0,
        'parent_id': '31',
      });
    },
  );
  test(
    'SDK validates category ownership and unsupported field combinations',
    () async {
      final data = fixtures();
      data['guilds']['20'] = fixtures()['guilds']['10'];
      data['guilds']['20']['channels'] = <Map<String, dynamic>>[
        {'id': '41', 'name': 'foreign category', 'type': 'category'},
      ];
      final gateway = _Gateway(data);
      final service = DiscordBotChannelMutationService(gateway);
      for (final change in [
        const ChannelModification(channelId: '30', categoryId: '32'),
        const ChannelModification(channelId: '30', categoryId: '41'),
        const ChannelModification(channelId: '31', categoryId: '31'),
        const ChannelModification(channelId: '31', topic: 'bad'),
        const ChannelModification(channelId: '501', position: 0),
        const ChannelModification(channelId: '30', isArchived: true),
        ChannelModification(channelId: '30', topic: 'x' * 1025),
      ]) {
        await expectLater(
          service.modifyChannel(change, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
        expect(gateway.manager.changes, isEmpty);
      }
    },
  );
  test('SDK forum topic and thread controls preserve exact fields', () async {
    final gateway = _Gateway(fixtures());
    final service = DiscordBotChannelMutationService(gateway);
    await service.modifyChannel(
      ChannelModification(
        channelId: '32',
        topic: 'x' * 4096,
        slowmodeSeconds: 0,
      ),
      budget: CommandExecutionBudget(),
    );
    expect((gateway.manager.changes.single['payload'] as Map).keys, [
      'topic',
      'rate_limit_per_user',
    ]);
    await service.modifyChannel(
      const ChannelModification(
        channelId: '501',
        name: 'new thread',
        isLocked: false,
        isArchived: false,
        autoArchiveMinutes: 60,
        slowmodeSeconds: 5,
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.changes.last['payload'], {
      'name': 'new thread',
      'archived': false,
      'locked': false,
      'auto_archive_duration': 60,
      'rate_limit_per_user': 5,
    });
  });
  test(
    'SDK refuses archived thread edits unless request explicitly unarchives',
    () async {
      final data = fixtures();
      data['guilds']['10']['threads'][0]['archived'] = true;
      final gateway = _Gateway(data);
      final service = DiscordBotChannelMutationService(gateway);
      await expectLater(
        service.modifyChannel(
          const ChannelModification(channelId: '501', name: 'new'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.manager.changes, isEmpty);
      await service.modifyChannel(
        const ChannelModification(
          channelId: '501',
          name: 'new',
          isArchived: false,
        ),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.changes.single['payload'], {
        'name': 'new',
        'archived': false,
      });
    },
  );
  test(
    'modification permissions deadlines and failed writes block further effects',
    () async {
      final denied = _Gateway(fixtures(permission: 1024));
      await expectLater(
        DiscordBotChannelMutationService(denied).modifyChannel(
          const ChannelModification(channelId: '30', name: 'new'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(denied.manager.changes, isEmpty);
      final gateway = _Gateway(fixtures());
      gateway.manager.delay = const Duration(milliseconds: 50);
      await expectLater(
        DiscordBotChannelMutationService(gateway).modifyChannel(
          const ChannelModification(channelId: '30', name: 'new'),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.manager.changes, isEmpty);
      gateway.manager.delay = Duration.zero;
      gateway.manager.fail = true;
      await expectLater(
        DiscordBotChannelMutationService(gateway).modifyChannel(
          const ChannelModification(channelId: '30', name: 'new'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.manager.changes, hasLength(1));
    },
  );
  test(
    'visual update resolves once delegates preserves result and audit reason',
    () async {
      final gateway = _Gateway(fixtures());
      final resolved = <String>[];
      final result = await updateChannelAction(
        gateway,
        payload: {
          'channelId': '30',
          'name': 'new',
          'topic': '',
          'reason': 'audit',
        },
        resolve: (value) {
          resolved.add(value);
          return value;
        },
      );
      expect(result, {'channelId': '30', 'status': 'updated'});
      expect(resolved.where((v) => v == '30'), hasLength(1));
      expect(resolved.where((v) => v == 'new'), hasLength(1));
      expect(gateway.manager.changes.single['payload'], {'name': 'new'});
      expect(gateway.manager.changes.single['reason'], 'audit');
    },
  );
  test('native sandbox modifications are reflected in later reads', () async {
    final result = await testCommandInSandbox({
      'script':
          r'$modifyChannel[30;new;topic;yes;1;31]$channelName[30]|$channelTopic|$isNSFW[30]|$channelPosition[30]|$parentID[30]',
      'bdfdBackend': 'native-v1',
      'variables': {'guild.id': '10', 'channel.id': '30', 'bot.id': '500'},
      'entities': fixtures(),
    });
    expect(result['success'], true, reason: '$result');
    expect(result['responses'][0]['payload']['content'], 'new|topic|true|0|31');
    expect((result['effects'] as List).single['type'], 'updateChannel');
  });
  test(
    'sandbox unchanged fields preserve parent topic and slowmode and denied edit has no effects',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'][0].addAll({
        'parent_id': '31',
        'topic': 'keep',
        'slowmode': 50,
      });
      final result = await testCommandInSandbox({
        'script':
            r'$modifyChannel[30;new;!unchanged;!unchanged;!unchanged;!unchanged]$channelTopic|$parentID[30]|$getSlowmode[30]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'channel.id': '30', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'keep|31|50');
      final denied = await testCommandInSandbox({
        'script': r'$modifyChannel[30;new]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(permission: 0),
      });
      expect(denied['success'], false);
      expect(denied['effects'], isEmpty);
    },
  );
  test('typed deletion rejects invalid IDs before reading Discord', () async {
    final gateway = _Gateway(fixtures());
    for (final id in ['', 'bad', '0', '-1']) {
      await expectLater(
        DiscordBotChannelMutationService(gateway).deleteChannel(
          ChannelDeletion(channelId: id),
          budget: CommandExecutionBudget(),
        ),
        throwsArgumentError,
      );
    }
    expect(gateway.fixtures.requests, isEmpty);
    expect(gateway.manager.deletions, isEmpty);
  });
  test(
    'deletion uses the target guild permission even with another current guild',
    () async {
      Map<String, dynamic> data() {
        final value = fixtures();
        value['guilds']['20'] = fixtures(permission: 0)['guilds']['10'];
        value['guilds']['20']['roles'][0]['id'] = '20';
        value['guilds']['20']['channels'] = <Map<String, dynamic>>[
          {'id': '40', 'name': 'other', 'type': 'text'},
        ];
        value['guilds']['20']['threads'] = <Map<String, dynamic>>[];
        return value;
      }

      final gateway = _Gateway(data());
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      );
      await expectLater(
        engine.execute(r'$deleteChannels[40]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(gateway.manager.deletions, isEmpty);
      final result = await testCommandInSandbox({
        'script': r'$deleteChannels[40]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data(),
      });
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'batch deletion stops at denied target and reports already performed effects',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'][2]['permission_overwrites'] = [
        <String, dynamic>{'id': '500', 'type': 1, 'deny': '16'},
      ];
      final result = await testCommandInSandbox({
        'script': r'$deleteChannels[30;32;31]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], false);
      expect((result['effects'] as List).map((e) => e['channel_id']), ['30']);
      final rows = data['guilds']['10']['channels'] as List;
      // Sandbox owns a copy: verify results through the emitted effects, not input mutation.
      expect(rows.map((row) => row['id']), ['30', '31', '32']);
    },
  );
  test(
    'native deletion validates every argument before writes and deduplicates IDs',
    () async {
      final service = _Mutations();
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelMutations: service,
      );
      final context = BdfdContext();
      expect(
        await engine.execute(r'$deleteChannels[30;32;030]', context: context),
        '',
      );
      expect(service.deletions.map((d) => d.channelId), ['30', '32']);
      expect(service.budgets.every((b) => identical(b, context.budget)), true);
      service.deletions.clear();
      for (final code in [
        r'$deleteChannels[30;bad]',
        r'$deleteChannels[30;]',
        r'$deleteChannels[-1]',
        r'$deleteChannels',
      ]) {
        await expectLater(
          engine.execute(code),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.deletions, isEmpty);
      }
      expect(
        await engine.execute(r'$unknown[$deleteChannels[30]]'),
        r'$unknown[$deleteChannels[30]]',
      );
      expect(service.deletions, isEmpty);
      expect(
        () => BdfdEngine.validation().prepare(
          r'$deleteChannels[30]$deleteChannelsByName[chat]',
        ),
        returnsNormally,
      );
    },
  );
  test('by-name deletion requires query capability during preflight', () {
    final engine = BdfdEngine(
      store: MemoryBotDataStore(),
      botId: 'bot',
      channelMutations: _Mutations(),
    );
    expect(
      () => engine.prepare(r'$deleteChannelsByName[chat]'),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test(
    'native by-name deletion matches all exact names in the current guild',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'].add(<String, dynamic>{
        'id': '40',
        'name': 'chat',
        'type': 'text',
      });
      final gateway = _Gateway(data);
      final engine = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      );
      expect(await engine.execute(r'$deleteChannelsByName[chat;chat]'), '');
      expect(gateway.manager.deletions, ['30', '40']);
      for (final code in [
        r'$deleteChannelsByName[Chat]',
        r'$deleteChannelsByName[chat;]',
        r'$deleteChannelsByName[]',
      ]) {
        gateway.manager.deletions.clear();
        await expectLater(
          engine.execute(code),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(gateway.manager.deletions, isEmpty);
      }
    },
  );
  test(
    'SDK deletion checks target permissions and permits archived threads',
    () async {
      final data = fixtures();
      data['guilds']['10']['threads'][0]['archived'] = true;
      final gateway = _Gateway(data);
      final service = DiscordBotChannelMutationService(gateway);
      await service.deleteChannel(
        const ChannelDeletion(channelId: '501'),
        budget: CommandExecutionBudget(),
      );
      await service.deleteChannel(
        const ChannelDeletion(channelId: '31'),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.deletions, ['501', '31']);
      final denied = _Gateway(fixtures(permission: 1024));
      await expectLater(
        DiscordBotChannelMutationService(denied).deleteChannel(
          const ChannelDeletion(channelId: '30'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(denied.manager.deletions, isEmpty);
    },
  );
  test(
    'SDK deletion stops after expired reads and does not retry failed writes',
    () async {
      final gateway = _Gateway(fixtures());
      gateway.manager.delay = const Duration(milliseconds: 50);
      await expectLater(
        DiscordBotChannelMutationService(gateway).deleteChannel(
          const ChannelDeletion(channelId: '30'),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.manager.deletions, isEmpty);
      gateway.manager.delay = Duration.zero;
      gateway.manager.fail = true;
      await expectLater(
        DiscordBotChannelMutationService(gateway).deleteChannel(
          const ChannelDeletion(channelId: '30'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.manager.deletions, ['30']);
    },
  );
  test('visual deletion delegates and preserves result and timeout', () async {
    final gateway = _Gateway(fixtures());
    expect(
      await removeChannel(
        gateway,
        Snowflake(30),
        budget: CommandExecutionBudget(),
      ),
      {'channelId': '30'},
    );
    expect(gateway.manager.deletions, ['30']);
    gateway.manager.delay = const Duration(milliseconds: 50);
    await expectLater(
      removeChannel(
        gateway,
        Snowflake(32),
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
  });
  test(
    'sandbox by-name deletions remove every match and later queries are fresh',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'].add(<String, dynamic>{
        'id': '40',
        'name': 'chat',
        'type': 'text',
      });
      final result = await testCommandInSandbox({
        'script':
            r'$deleteChannelsByName[chat;chat]$channelExists[30]|$channelExists[40]|$channelCount',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'false|false|3');
      expect((result['effects'] as List).map((e) => e['channel_id']), [
        '30',
        '40',
      ]);
    },
  );
  test(
    'sandbox deleting a category keeps children and detaches their parent',
    () async {
      final data = fixtures();
      data['guilds']['10']['channels'][0]['parent_id'] = '31';
      final result = await testCommandInSandbox({
        'script':
            r'$deleteChannels[31]$channelExists[31]|$channelExists[30]|$parentID[30]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'false|true|');
    },
  );
  test(
    'sandbox deletes parent threads and blocks permission denial without effects',
    () async {
      final result = await testCommandInSandbox({
        'script': r'$deleteChannels[32]$channelExists[501]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(),
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'false');
      final denied = await testCommandInSandbox({
        'script': r'$deleteChannels[30]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(permission: 0),
      });
      expect(denied['success'], false);
      expect(denied['effects'], isEmpty);
    },
  );
  Map<String, dynamic> overwrite(
    String id,
    int type, {
    int allow = 0,
    int deny = 0,
  }) => {'id': id, 'type': type, 'allow': '$allow', 'deny': '$deny'};
  final permissionCases =
      <
        ({String name, int base, List<Map<String, dynamic>> rows, bool allowed})
      >[
        (
          name: 'channel grant without guild manage channels',
          base: 1024,
          rows: [overwrite('63', 0, allow: 16)],
          allowed: true,
        ),
        (
          name: 'everyone denial beats guild grant',
          base: 1040,
          rows: [overwrite('10', 0, deny: 16)],
          allowed: false,
        ),
        (
          name: 'role grant beats everyone denial',
          base: 1040,
          rows: [overwrite('10', 0, deny: 16), overwrite('63', 0, allow: 16)],
          allowed: true,
        ),
        (
          name: 'combined role allow beats another role denial',
          base: 1024,
          rows: [overwrite('63', 0, deny: 16), overwrite('64', 0, allow: 16)],
          allowed: true,
        ),
        (
          name: 'member denial beats role grant',
          base: 1024,
          rows: [overwrite('63', 0, allow: 16), overwrite('500', 1, deny: 16)],
          allowed: false,
        ),
        (
          name: 'member grant beats role denial',
          base: 1040,
          rows: [overwrite('500', 1, allow: 16), overwrite('63', 0, deny: 16)],
          allowed: true,
        ),
        (
          name: 'unrelated grants do not authorize bot',
          base: 1024,
          rows: [overwrite('65', 0, allow: 16), overwrite('501', 1, allow: 16)],
          allowed: false,
        ),
        (
          name: 'view denial blocks channel management',
          base: 1040,
          rows: [overwrite('500', 1, deny: 1024)],
          allowed: false,
        ),
        (
          name: 'administrator bypasses channel denials',
          base: 8,
          rows: [overwrite('500', 1, deny: 1040)],
          allowed: true,
        ),
      ];
  for (final scenario in permissionCases) {
    test('SDK and native sandbox agree: ${scenario.name}', () async {
      Map<String, dynamic> data() {
        final value = fixtures(permission: scenario.base);
        final guild = value['guilds']['10'];
        guild['roles'].add({'id': '64', 'name': 'second', 'permissions': '0'});
        guild['members']['500']['roles'].add('64');
        guild['channels'][0]['permission_overwrites'] = scenario.rows;
        return value;
      }

      final gateway = _Gateway(data());
      final call = DiscordBotChannelMutationService(gateway).setSlowmode(
        const SlowmodeChange(channelId: '30', seconds: 5),
        budget: CommandExecutionBudget(),
      );
      if (scenario.allowed) {
        await call;
      } else {
        await expectLater(call, throwsA(isA<StateError>()));
      }
      expect(gateway.manager.changes.length, scenario.allowed ? 1 : 0);
      final result = await testCommandInSandbox({
        'script': r'$slowmode[30;5]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data(),
      });
      expect(result['success'], scenario.allowed, reason: '$result');
      expect((result['effects'] as List).length, scenario.allowed ? 1 : 0);
    });
  }
  for (final owner in [false, true]) {
    test(
      'thread inherits parent overwrites with owner bypass=$owner',
      () async {
        Map<String, dynamic> data() {
          final value = fixtures();
          final guild = value['guilds']['10'];
          if (owner) guild['owner_id'] = '500';
          guild['channels'][2]['permission_overwrites'] = [
            overwrite('500', 1, deny: 16),
          ];
          return value;
        }

        final gateway = _Gateway(data());
        final call = DiscordBotChannelMutationService(gateway).setSlowmode(
          const SlowmodeChange(channelId: '501', seconds: 5),
          budget: CommandExecutionBudget(),
        );
        if (owner) {
          await call;
        } else {
          await expectLater(call, throwsA(isA<StateError>()));
        }
        expect(gateway.manager.changes.length, owner ? 1 : 0);
        final result = await testCommandInSandbox({
          'script': r'$slowmode[501;5]',
          'bdfdBackend': 'native-v1',
          'variables': {'guild.id': '10', 'bot.id': '500'},
          'entities': data(),
        });
        expect(result['success'], owner, reason: '$result');
        expect((result['effects'] as List).length, owner ? 1 : 0);
      },
    );
  }
  for (final archived in [false, true]) {
    test(
      'thread blocks missing manage threads or archived state: $archived',
      () async {
        Map<String, dynamic> data() {
          final value = fixtures(permission: archived ? 17179870224 : 1040);
          value['guilds']['10']['threads'][0]['archived'] = archived;
          return value;
        }

        final gateway = _Gateway(data());
        await expectLater(
          DiscordBotChannelMutationService(gateway).setSlowmode(
            const SlowmodeChange(channelId: '501', seconds: 5),
            budget: CommandExecutionBudget(),
          ),
          throwsA(isA<StateError>()),
        );
        expect(gateway.manager.changes, isEmpty);
        final result = await testCommandInSandbox({
          'script': r'$slowmode[501;5]',
          'bdfdBackend': 'native-v1',
          'variables': {'guild.id': '10', 'bot.id': '500'},
          'entities': data(),
        });
        expect(result['success'], false, reason: '$result');
        expect(result['effects'], isEmpty);
      },
    );
  }
  test('desynchronized child ignores category overwrites', () async {
    final data = fixtures();
    final rows = data['guilds']['10']['channels'];
    rows[0]['parent_id'] = '31';
    rows[1]['permission_overwrites'] = [overwrite('500', 1, deny: 1040)];
    final gateway = _Gateway(data);
    await DiscordBotChannelMutationService(gateway).setSlowmode(
      const SlowmodeChange(channelId: '30', seconds: 5),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.changes, hasLength(1));
  });
  test('invalid fixture overwrites fail before mutation', () async {
    final data = fixtures();
    data['guilds']['10']['channels'][0]['permission_overwrites'] = [
      overwrite('63', 7, allow: 16),
    ];
    final result = await testCommandInSandbox({
      'script': r'$slowmode[30;5]',
      'bdfdBackend': 'native-v1',
      'variables': {'guild.id': '10', 'bot.id': '500'},
      'entities': data,
    });
    expect(result['success'], false);
    expect(result['effects'], isEmpty);
  });
  test(
    'announcement updates send only the rate-limit field without changing channel type',
    () async {
      final gateway = _Gateway(fixtures());
      gateway.manager.overrideChannel = _Announcement();
      await DiscordBotChannelMutationService(gateway).setSlowmode(
        const SlowmodeChange(channelId: '40', seconds: 5),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.changes.single['payload'], {
        'rate_limit_per_user': 5,
      });
    },
  );
  test(
    'permission is checked in the target channel guild rather than the current guild',
    () async {
      final data = fixtures();
      (data['guilds'] as Map)['20'] = <String, dynamic>{
        'owner_id': '999',
        'roles': [
          {'id': '20', 'name': '@everyone', 'permissions': '0'},
        ],
        'members': {
          '500': {'roles': <String>[]},
        },
        'channels': [
          {'id': '40', 'name': 'remote', 'type': 'text'},
        ],
      };
      final gateway = _Gateway(data);
      final native = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      );
      await expectLater(
        native.execute(r'$slowmode[40;5]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(gateway.manager.changes, isEmpty);
    },
  );
  test(
    'native slowmode follows the wiki order duration units limit and disable',
    () async {
      final service = _Mutations();
      final context = BdfdContext();
      final native = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        channelMutations: service,
      );
      expect(
        await native.execute(
          r'$slowmode[30;5]$slowmode[30;10s]$slowmode[30;40m]$slowmode[30;6h]$slowmode[30;0s]',
          context: context,
        ),
        '',
      );
      expect(service.changes.map((c) => c.seconds), [5, 10, 2400, 21600, 0]);
      expect(service.changes.map((c) => c.channelId), everyElement('30'));
      expect(service.changes.map((c) => c.reason), everyElement(isNull));
      expect(service.budgets, everyElement(same(context.budget)));
    },
  );
  test(
    'invalid IDs durations and arity never call the mutation service',
    () async {
      for (final source in [
        r'$slowmode[;5]',
        r'$slowmode[bad;5]',
        r'$slowmode[30;]',
        r'$slowmode[30;-1]',
        r'$slowmode[30;6h1s]',
        r'$slowmode[30;bad]',
        r'$slowmode[30]',
        r'$slowmode[30;5;reason]',
      ]) {
        final service = _Mutations();
        final native = BdfdEngine(
          store: MemoryBotDataStore(),
          botId: 'bot',
          channelMutations: service,
        );
        await expectLater(
          native.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.changes, isEmpty);
      }
    },
  );
  test(
    'unknown wrappers remain opaque and unsupported mutation capabilities fail preflight',
    () async {
      final native = BdfdEngine(store: MemoryBotDataStore(), botId: 'bot');
      expect(
        await native.execute(r'$unknown[$slowmode[;bad]]'),
        r'$unknown[$slowmode[;bad]]',
      );
      expect(
        () => native.prepare(r'$slowmode[30;5]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(
        () => BdfdEngine.validation().prepare(r'$slowmode[30;5]'),
        returnsNormally,
      );
    },
  );
  test(
    'SDK uses typed builders and a single update for text forum and thread channels',
    () async {
      final gateway = _Gateway(fixtures());
      final service = DiscordBotChannelMutationService(gateway);
      for (final id in ['30', '32', '501']) {
        await service.setSlowmode(
          SlowmodeChange(channelId: id, seconds: 5),
          budget: CommandExecutionBudget(),
        );
      }
      expect(gateway.manager.changes.map((c) => c['id']), ['30', '32', '501']);
      expect(
        gateway.manager.changes.map((c) => c['payload']['rate_limit_per_user']),
        [5, 5, 5],
      );
    },
  );
  test(
    'SDK permissions unsupported types and invalid typed requests block writes',
    () async {
      final denied = _Gateway(fixtures(permission: 0));
      await expectLater(
        DiscordBotChannelMutationService(denied).setSlowmode(
          const SlowmodeChange(channelId: '30', seconds: 5),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(denied.manager.changes, isEmpty);
      final gateway = _Gateway(fixtures());
      final service = DiscordBotChannelMutationService(gateway);
      await expectLater(
        service.setSlowmode(
          const SlowmodeChange(channelId: '31', seconds: 5),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      for (final change in [
        const SlowmodeChange(channelId: '', seconds: 5),
        const SlowmodeChange(channelId: '30', seconds: -1),
        const SlowmodeChange(channelId: '30', seconds: 21601),
      ]) {
        await expectLater(
          service.setSlowmode(change, budget: CommandExecutionBudget()),
          throwsArgumentError,
        );
      }
      expect(gateway.manager.changes, isEmpty);
    },
  );
  test(
    'SDK deadline blocks writes after a late channel read and errors are never retried',
    () async {
      final gateway = _Gateway(fixtures());
      gateway.manager.delay = const Duration(milliseconds: 50);
      await expectLater(
        DiscordBotChannelMutationService(gateway).setSlowmode(
          const SlowmodeChange(channelId: '30', seconds: 5),
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.manager.changes, isEmpty);
      gateway.manager.delay = Duration.zero;
      gateway.manager.fail = true;
      await expectLater(
        DiscordBotChannelMutationService(gateway).setSlowmode(
          const SlowmodeChange(channelId: '30', seconds: 5),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.manager.changes, hasLength(1));
    },
  );
  test(
    'visual slowmode resolves its payload once and delegates to the shared service',
    () async {
      final gateway = _Gateway(fixtures());
      final resolved = <String>[];
      final result = await slowmodeAction(
        gateway,
        guildId: Snowflake(10),
        payload: {'channelId': '30', 'duration': '5s', 'reason': 'audit'},
        resolve: (value) {
          resolved.add(value);
          return value;
        },
      );
      expect(result, {'channelId': '30', 'duration': '5'});
      expect(resolved, ['30', '5s', 'audit']);
      expect(gateway.manager.changes.single['reason'], 'audit');
    },
  );
  test(
    'native aggregate exposes channel mutations independently of role writes',
    () async {
      final gateway = _Gateway(fixtures());
      final native = BdfdEngine(
        store: MemoryBotDataStore(),
        botId: 'bot',
        moderation: DiscordBotModerationService(
          client: gateway,
          guildId: Snowflake(10),
        ),
      );
      expect(await native.execute(r'$slowmode[30;0]'), '');
      expect(
        gateway.manager.changes.single['payload']['rate_limit_per_user'],
        0,
      );
    },
  );
  test(
    'sandbox mutations are permission checked and fresh queries observe the result',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$slowmode[30;10s]$getSlowmode[30]|$slowmode[32;0]$getSlowmode[32]|$slowmode[501;5]$getSlowmode[501]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(),
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '10|0|5');
      expect((result['effects'] as List).map((e) => e['type']), [
        'slowmode',
        'slowmode',
        'slowmode',
      ]);
      final denied = await testCommandInSandbox({
        'script': r'$slowmode[30;5]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(permission: 0),
      });
      expect(denied['success'], false);
      expect(denied['effects'], isEmpty);
    },
  );
}
