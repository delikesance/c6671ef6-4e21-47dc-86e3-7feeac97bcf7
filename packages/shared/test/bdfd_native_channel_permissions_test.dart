import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_channel_permission_service.dart';
import 'package:bot_creator_shared/services/bot_moderation_service.dart';
import 'package:bot_creator_shared/actions/channel_permissions.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

Map<String, dynamic> fixtures({int permissions = 268436480}) => {
  'guilds': <String, dynamic>{
    '10': <String, dynamic>{
      'owner_id': '999',
      'roles': [
        {'id': '10', 'name': '@everyone', 'permissions': '0'},
        {'id': '63', 'name': 'bot', 'permissions': '$permissions'},
      ],
      'members': {
        '500': {
          'roles': ['63'],
        },
        '20': {'roles': <String>[]},
      },
      'channels': <Map<String, dynamic>>[
        {
          'id': '30',
          'name': 'chat',
          'type': 'text',
          'permission_overwrites': <Map<String, dynamic>>[
            {'id': '63', 'type': 0, 'allow': '16', 'deny': '2048'},
          ],
        },
        {'id': '31', 'name': 'category', 'type': 'category'},
      ],
      'threads': <Map<String, dynamic>>[
        {'id': '501', 'parent_id': '30'},
      ],
    },
  },
};

class _Native implements BotChannelPermissionService {
  final calls = <ChannelPermissionChange>[];
  final budgets = <CommandExecutionBudget>[];
  @override
  Future<ChannelPermissionResult> editPermissions(
    ChannelPermissionChange change, {
    required CommandExecutionBudget budget,
  }) async {
    calls.add(change);
    budgets.add(budget);
    return ChannelPermissionResult(change.channelId, change.targetId ?? '10');
  }
}

class _Bot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway(Map<String, dynamic> data) : fixture = EntityFixtureGateway(data) {
    manager = _Writes(fixture);
  }
  final EntityFixtureGateway fixture;
  late final _Writes manager;
  @override
  ChannelManager get channels => manager;
  @override
  GuildManager get guilds => fixture.guilds;
  @override
  PartialUser get user => _Bot();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Writes implements ChannelManager {
  _Writes(this.fixture);
  final EntityFixtureGateway fixture;
  final writes = <Map<String, dynamic>>[];
  Duration delay = Duration.zero;
  bool fail = false;
  @override
  Future<Channel> fetch(Snowflake id) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return await fixture.channels.fetch(id);
  }

  @override
  Future<void> updatePermissionOverwrite(
    Snowflake id,
    PermissionOverwriteBuilder builder,
  ) async {
    final payload = builder.build();
    writes.add({'channel_id': '$id', ...payload});
    if (fail) throw StateError('Discord refused overwrite');
    final rows = fixture.fixtures['guilds']['10']['channels'] as List;
    final row = rows.firstWhere((r) => r['id'].toString() == '$id') as Map;
    final overwrites =
        row['permission_overwrites'] as List? ?? <Map<String, dynamic>>[];
    overwrites.removeWhere((r) => r['id'].toString() == '${builder.id}');
    overwrites.add(Map<String, dynamic>.from(payload));
    row['permission_overwrites'] = overwrites;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BdfdEngine _native(_Native service) => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  channelPermissions: service,
);

void main() {
  test(
    'native signatures order aliases and neutral mode match documented forms',
    () async {
      final service = _Native();
      final engine = _native(service);
      final context = BdfdContext();
      expect(
        await engine.execute(
          r'$editChannelPerms[30;63;+READMESSAGES;-sendmessages]',
          context: context,
        ),
        '',
      );
      expect(service.calls.single.allow, 1024);
      expect(service.calls.single.deny, 2048);
      expect(service.calls.single.targetId, '63');
      expect(identical(service.budgets.single, context.budget), true);
      service.calls.clear();
      await engine.execute(r'$modifyChannelPerms[30;/sendmessages;63]');
      expect(service.calls.single.neutral, 2048);
      expect(service.calls.single.allow, 0);
      expect(service.calls.single.deny, 0);
      service.calls.clear();
      await engine.execute(r'$editChannelPerms[30;;+readmessages]');
      expect(service.calls.single.targetType, 'everyone');
      expect(service.calls.single.targetId, isNull);
    },
  );
  test(
    'invalid permissions targets and arities never reach the adapter',
    () async {
      final service = _Native();
      final engine = _native(service);
      for (final code in [
        r'$editChannelPerms[30;63]',
        r'$editChannelPerms[30;bad;+readmessages]',
        r'$editChannelPerms[30;63;+readmessages;bad]',
        r'$editChannelPerms[30;63;/sendmessages]',
        r'$editChannelPerms[30;63;+madeup]',
        r'$modifyChannelPerms[30;;63]',
        r'$modifyChannelPerms[30;+sendmessages;]',
        r'$modifyChannelPerms[30;+sendmessages;63;extra]',
      ]) {
        await expectLater(
          engine.execute(code),
          throwsA(isA<BdfdNativeError>()),
        );
        expect(service.calls, isEmpty);
      }
      expect(
        await engine.execute(
          r'$unknown[$editChannelPerms[30;63;+readmessages]]',
        ),
        r'$unknown[$editChannelPerms[30;63;+readmessages]]',
      );
      expect(service.calls, isEmpty);
      expect(
        () => BdfdEngine.validation().prepare(
          r'$editChannelPerms[30;63;+readmessages]$modifyChannelPerms[30;/sendmessages;63]',
        ),
        returnsNormally,
      );
    },
  );
  test('last state wins when a native permission occurs repeatedly', () async {
    final service = _Native();
    await _native(
      service,
    ).execute(r'$editChannelPerms[30;63;+sendmessages;-sendmessages]');
    expect(service.calls.single.allow, 0);
    expect(service.calls.single.deny, 2048);
  });
  test(
    'SDK merges only touched flags and neutral removes both masks',
    () async {
      final gateway = _Gateway(fixtures());
      final service = DiscordBotChannelPermissionService(gateway);
      final result = await service.editPermissions(
        const ChannelPermissionChange(
          channelId: '30',
          targetId: '63',
          allow: 1024,
          deny: 0,
        ),
        budget: CommandExecutionBudget(),
      );
      expect(result.targetId, '63');
      expect(gateway.manager.writes.single, {
        'channel_id': '30',
        'id': '63',
        'type': 0,
        'allow': '1040',
        'deny': '2048',
      });
      await service.editPermissions(
        const ChannelPermissionChange(
          channelId: '30',
          targetId: '63',
          allow: 0,
          deny: 0,
          neutral: 2048,
        ),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.writes.last['allow'], '1040');
      expect(gateway.manager.writes.last['deny'], '0');
    },
  );
  test('SDK resolves everyone roles and members in the target guild', () async {
    final gateway = _Gateway(fixtures());
    final service = DiscordBotChannelPermissionService(gateway);
    await service.editPermissions(
      const ChannelPermissionChange(
        channelId: '30',
        targetType: 'everyone',
        allow: 0,
        deny: 2048,
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.writes.last['id'], '10');
    expect(gateway.manager.writes.last['type'], 0);
    await service.editPermissions(
      const ChannelPermissionChange(
        channelId: '30',
        targetId: '20',
        allow: 1024,
        deny: 0,
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.writes.last['type'], 1);
    for (final request in [
      const ChannelPermissionChange(
        channelId: '30',
        targetId: '9999',
        allow: 1,
        deny: 0,
      ),
      const ChannelPermissionChange(
        channelId: '30',
        targetId: '20',
        targetType: 'role',
        allow: 1,
        deny: 0,
      ),
    ]) {
      await expectLater(
        service.editPermissions(request, budget: CommandExecutionBudget()),
        throwsA(isA<Object>()),
      );
    }
    expect(gateway.manager.writes, hasLength(2));
  });
  test('typed invalid masks and IDs reject before Discord reads', () async {
    final gateway = _Gateway(fixtures());
    final service = DiscordBotChannelPermissionService(gateway);
    for (final request in [
      const ChannelPermissionChange(
        channelId: '0',
        targetId: '63',
        allow: 1,
        deny: 0,
      ),
      const ChannelPermissionChange(
        channelId: '30',
        targetId: '63',
        allow: 1,
        deny: 1,
      ),
      const ChannelPermissionChange(
        channelId: '30',
        targetId: '63',
        allow: -1,
        deny: 0,
      ),
    ]) {
      await expectLater(
        service.editPermissions(request, budget: CommandExecutionBudget()),
        throwsArgumentError,
      );
      expect(gateway.fixture.requests, isEmpty);
      expect(gateway.manager.writes, isEmpty);
    }
  });
  test('permission denial and thread targets block writes', () async {
    final denied = _Gateway(fixtures(permissions: 1024));
    await expectLater(
      DiscordBotChannelPermissionService(denied).editPermissions(
        const ChannelPermissionChange(
          channelId: '30',
          targetId: '63',
          allow: 1024,
          deny: 0,
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(denied.manager.writes, isEmpty);
    final gateway = _Gateway(fixtures());
    await expectLater(
      DiscordBotChannelPermissionService(gateway).editPermissions(
        const ChannelPermissionChange(
          channelId: '501',
          targetId: '63',
          allow: 1024,
          deny: 0,
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsA(isA<StateError>()),
    );
    expect(gateway.manager.writes, isEmpty);
  });
  test(
    'deadline prevents writes after late fetch and SDK failures never retry',
    () async {
      final gateway = _Gateway(fixtures());
      gateway.manager.delay = const Duration(milliseconds: 50);
      final service = DiscordBotChannelPermissionService(gateway);
      const request = ChannelPermissionChange(
        channelId: '30',
        targetId: '63',
        allow: 1024,
        deny: 0,
      );
      await expectLater(
        service.editPermissions(
          request,
          budget: CommandExecutionBudget(
            limit: const Duration(milliseconds: 10),
          ),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(gateway.manager.writes, isEmpty);
      gateway.manager.delay = Duration.zero;
      gateway.manager.fail = true;
      await expectLater(
        service.editPermissions(request, budget: CommandExecutionBudget()),
        throwsA(isA<StateError>()),
      );
      expect(gateway.manager.writes, hasLength(1));
    },
  );
  test(
    'visual permission snapshot replaces masks through the shared service',
    () async {
      final gateway = _Gateway(fixtures());
      final resolved = <String>[];
      final result = await editChannelPermissionsAction(
        gateway,
        payload: {
          'channelId': '30',
          'targetId': '63',
          'targetType': 'auto',
          'permissions': {'viewChannel': 'allow', 'sendMessages': 'deny'},
        },
        resolve: (s) {
          resolved.add(s);
          return s;
        },
      );
      expect(result, {
        'channelId': '30',
        'targetId': '63',
        'status': 'updated',
      });
      expect(gateway.manager.writes.single['allow'], '1024');
      expect(gateway.manager.writes.single['deny'], '2048');
      expect(resolved.where((s) => s == '30'), hasLength(1));
      expect(resolved.where((s) => s == '63'), hasLength(1));
    },
  );
  test(
    'sandbox permission changes affect the next permission guard and preserve untouched flags',
    () async {
      final result = await testCommandInSandbox({
        'script':
            r'$editChannelPerms[30;63;-readmessages]$modifyChannel[30;never]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': fixtures(),
      });
      expect(result['success'], false, reason: '$result');
      expect((result['effects'] as List), hasLength(1));
      expect(result['effects'][0]['overwrite']['allow'], '16');
      expect(result['effects'][0]['overwrite']['deny'], '3072');
    },
  );
  test(
    'native aggregate exposes permission edits independently from channel mutations',
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
        await engine.execute(r'$editChannelPerms[30;63;+readmessages]'),
        '',
      );
      expect(gateway.manager.writes, hasLength(1));
    },
  );
  for (final type in [0, '0', 'role']) {
    test('sandbox replaces existing overwrite with fixture type $type', () async {
      final data = fixtures();
      data['guilds']['10']['channels'][0]['permission_overwrites'][0]['type'] =
          type;
      final result = await testCommandInSandbox({
        'script':
            r'$modifyChannelPerms[30;/sendmessages;63]$editChannelPerms[30;63;+readmessages]',
        'bdfdBackend': 'native-v1',
        'variables': {'guild.id': '10', 'bot.id': '500'},
        'entities': data,
      });
      expect(result['success'], true, reason: '$result');
      final effects = result['effects'] as List;
      expect(effects, hasLength(2));
      expect(effects.last['overwrite']['allow'], '1040');
      expect(effects.last['overwrite']['deny'], '0');
    });
  }
  test('explicit member target cannot identify the everyone role', () async {
    final gateway = _Gateway(fixtures());
    await expectLater(
      DiscordBotChannelPermissionService(gateway).editPermissions(
        const ChannelPermissionChange(
          channelId: '30',
          targetId: '10',
          targetType: 'member',
          allow: 1024,
          deny: 0,
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsArgumentError,
    );
    expect(gateway.manager.writes, isEmpty);
  });
}
