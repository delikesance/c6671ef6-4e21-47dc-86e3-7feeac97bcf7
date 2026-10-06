import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/thread_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_thread_service.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Native implements BotThreadService {
  final creations = <ThreadCreation>[],
      edits = <ThreadModification>[],
      members = <ThreadMemberChange>[];
  CommandExecutionBudget? budgetSeen;
  @override
  Future<String> startThread(
    ThreadCreation change, {
    required CommandExecutionBudget budget,
  }) async {
    creations.add(change);
    budgetSeen = budget;
    return '80';
  }

  @override
  Future<void> editThread(
    ThreadModification change, {
    required CommandExecutionBudget budget,
  }) async {
    edits.add(change);
  }

  @override
  Future<void> addThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) async {
    members.add(change);
  }

  @override
  Future<void> removeThreadMember(
    ThreadMemberChange change, {
    required CommandExecutionBudget budget,
  }) async {
    members.add(change);
  }

  @override
  Future<BotThreadInfo> threadInfo({
    String? threadId,
    required CommandExecutionBudget budget,
  }) async => const BotThreadInfo(id: '80', messageCount: 63, userCount: 50);
}

class _Thread implements Thread {
  bool archived = false, locked = false;
  ChannelType kind = ChannelType.publicThread;
  @override
  Snowflake get id => Snowflake(80);
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  Snowflake get parentId => Snowflake(30);
  @override
  Snowflake get ownerId => Snowflake(500);
  @override
  bool get isArchived => archived;
  @override
  bool get isLocked => locked;
  @override
  ChannelType get type => kind;
  @override
  int get messageCount => 63;
  @override
  int get approximateMemberCount => 50;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Bot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway({int permissions = 0, bool owner = true}) {
    fixture = EntityFixtureGateway({
      'guilds': {
        '10': {
          'owner_id': owner ? '500' : '999',
          'roles': [
            {'id': '10', 'permissions': '$permissions'},
          ],
          'members': {
            '500': {'roles': <String>[]},
          },
          'channels': [
            {
              'id': '30',
              'name': 'chat',
              'type': 'text',
              'permission_overwrites': <Map<String, dynamic>>[],
            },
          ],
        },
      },
    });
    manager = _Writes(fixture);
  }
  late EntityFixtureGateway fixture;
  late _Writes manager;
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
  final thread = _Thread();
  final writes = <Map<String, Object?>>[];
  bool fail = false;
  @override
  Future<Channel> fetch(Snowflake id) async =>
      id == thread.id ? thread : fixture.channels.fetch(id);
  @override
  Future<Thread> createThread(
    Snowflake id,
    ThreadBuilder builder, {
    String? auditLogReason,
  }) async {
    writes.add({'channel': '$id', ...builder.build()});
    return thread;
  }

  @override
  Future<Thread> createThreadFromMessage(
    Snowflake id,
    Snowflake messageId,
    ThreadFromMessageBuilder builder, {
    String? auditLogReason,
  }) async {
    writes.add({'channel': '$id', 'message': '$messageId', ...builder.build()});
    return thread;
  }

  @override
  Future<Channel> update(
    Snowflake id,
    UpdateBuilder<Channel> builder, {
    String? auditLogReason,
  }) async {
    writes.add(builder.build());
    if (fail) throw StateError('refused');
    return thread;
  }

  @override
  Future<void> addThreadMember(Snowflake id, Snowflake memberId) async {
    writes.add({'add': '$memberId'});
  }

  @override
  Future<void> removeThreadMember(Snowflake id, Snowflake memberId) async {
    writes.add({'remove': '$memberId'});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  BdfdRuntime native(_Native service) =>
      BdfdRuntime(functions: bdfdThreadFunctions(service));
  test('start defaults and explicit return preserve raw name', () async {
    final service = _Native(), context = BdfdContext();
    expect(
      await native(
        service,
      ).execute(r'$startThread[ Hello ;30;]', context: context),
      '',
    );
    expect(service.creations.single.name, ' Hello ');
    expect(service.creations.single.messageId, isNull);
    expect(service.creations.single.archiveMinutes, 60);
    expect(service.budgetSeen, same(context.budget));
    expect(
      await native(service).execute(r'$startThread[Hello;30;40;1440;yes]'),
      '80',
    );
    expect(service.creations.last.messageId, '40');
  });
  test('edit wiki example maps fields and unchanged markers', () async {
    final service = _Native();
    expect(
      await native(
        service,
      ).execute(r'$editThread[80;Cool Thread;no;!unchanged;!unchanged;5]'),
      '',
    );
    final change = service.edits.single;
    expect(change.name, 'Cool Thread');
    expect(change.archived, false);
    expect(change.archiveMinutes, isNull);
    expect(change.locked, isNull);
    expect(change.slowmodeSeconds, 5);
    expect(change.toBuilder().build(), {
      'name': 'Cool Thread',
      'archived': false,
      'rate_limit_per_user': 5,
    });
  });
  test('edit omissions leave SDK fields absent', () async {
    final service = _Native();
    await native(service).execute(r'$editThread[80]');
    expect(service.edits.single.toBuilder().build(), isEmpty);
  });
  test('members and current thread counts', () async {
    final service = _Native();
    expect(
      await native(service).execute(
        r'$threadAddMember[80;20]$threadRemoveMember[80;21]$threadMessageCount/$threadUserCount',
      ),
      '63/50',
    );
    expect(service.members.map((c) => c.userId), ['20', '21']);
  });
  test('invalid arguments rejected before service effects', () async {
    final service = _Native();
    for (final source in [
      r'$startThread[x;30;]',
      r'$startThread[x;30;;70]',
      r'$startThread[x;30;;60;true]',
      r'$editThread[80;;no]',
      r'$editThread[80;!unchanged;!unchanged;!unchanged;!unchanged;21601]',
      r'$threadAddMember[80;]',
    ]) {
      if (source == r'$startThread[x;30;]') continue;
      await expectLater(
        native(service).execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(service.creations, isEmpty);
    expect(service.edits, isEmpty);
    expect(service.members, isEmpty);
  });
  test('arity preflight prevents earlier creation', () async {
    final service = _Native();
    await expectLater(
      native(service).execute(r'$startThread[x;30;]$threadUserCount[80]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(service.creations, isEmpty);
  });
  test('unknown functions retain unexecuted arguments', () async {
    final service = _Native();
    const source = r'$unknownThread[$startThread[x;30;]]';
    expect(await native(service).execute(source), source);
    expect(service.creations, isEmpty);
  });
  test('SDK creates public threads with and without source messages', () async {
    final gateway = _Gateway(), budget = CommandExecutionBudget();
    final service = DiscordBotThreadService(
      client: gateway,
      channelId: Snowflake(80),
    );
    expect(
      await service.startThread(
        const ThreadCreation(name: 'new', channelId: '30'),
        budget: budget,
      ),
      '80',
    );
    expect(gateway.manager.writes.single, {
      'channel': '30',
      'name': 'new',
      'auto_archive_duration': 60,
      'type': 11,
    });
    await service.startThread(
      const ThreadCreation(
        name: 'linked',
        channelId: '30',
        messageId: '40',
        archiveMinutes: 1440,
      ),
      budget: budget,
    );
    expect(gateway.manager.writes.last, {
      'channel': '30',
      'message': '40',
      'name': 'linked',
      'auto_archive_duration': 1440,
    });
  });
  test(
    'SDK archived members reject without write or implicit unarchive',
    () async {
      final gateway = _Gateway();
      gateway.manager.thread.archived = true;
      final service = DiscordBotThreadService(client: gateway);
      await expectLater(
        service.addThreadMember(
          const ThreadMemberChange(threadId: '80', userId: '20'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      await expectLater(
        service.removeThreadMember(
          const ThreadMemberChange(threadId: '80', userId: '20'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.manager.writes, isEmpty);
    },
  );
  test(
    'SDK permissions prevent creation and adding or removing members',
    () async {
      final gateway = _Gateway(
        owner: false,
        permissions: Permissions.viewChannel.value,
      );
      final service = DiscordBotThreadService(client: gateway);
      await expectLater(
        service.startThread(
          const ThreadCreation(name: 'x', channelId: '30'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      await expectLater(
        service.addThreadMember(
          const ThreadMemberChange(threadId: '80', userId: '20'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      await expectLater(
        service.removeThreadMember(
          const ThreadMemberChange(threadId: '80', userId: '20'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.manager.writes, isEmpty);
    },
  );
  test('private creator can remove users without manage threads', () async {
    final gateway = _Gateway(
      owner: false,
      permissions: Permissions.viewChannel.value,
    );
    gateway.manager.thread.kind = ChannelType.privateThread;
    await DiscordBotThreadService(client: gateway).removeThreadMember(
      const ThreadMemberChange(threadId: '80', userId: '20'),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.writes.single, {'remove': '20'});
  });
  test(
    'SDK edit archived requires unarchive and lock disallows resulting archive',
    () async {
      final gateway = _Gateway();
      gateway.manager.thread.archived = true;
      final service = DiscordBotThreadService(client: gateway);
      await expectLater(
        service.editThread(
          const ThreadModification(threadId: '80', name: 'x'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      gateway.manager.thread.archived = false;
      await expectLater(
        service.editThread(
          const ThreadModification(
            threadId: '80',
            archived: true,
            locked: true,
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsArgumentError,
      );
      expect(gateway.manager.writes, isEmpty);
    },
  );
  test(
    'unarchive-only permits send messages; other edits require manage threads',
    () async {
      final gateway = _Gateway(
        owner: false,
        permissions:
            Permissions.viewChannel.value | Permissions.sendMessages.value,
      );
      gateway.manager.thread.archived = true;
      final service = DiscordBotThreadService(client: gateway);
      await service.editThread(
        const ThreadModification(threadId: '80', archived: false),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.manager.writes.single, {'archived': false});
      gateway.manager.thread.locked = true;
      await expectLater(
        service.editThread(
          const ThreadModification(threadId: '80', archived: false),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.manager.writes, hasLength(1));
    },
  );
  test('SDK count reads fresh metadata in current thread', () async {
    final gateway = _Gateway();
    final info = await DiscordBotThreadService(
      client: gateway,
      channelId: Snowflake(80),
    ).threadInfo(budget: CommandExecutionBudget());
    expect(info.messageCount, 63);
    expect(info.userCount, 50);
    await expectLater(
      DiscordBotThreadService(
        client: gateway,
        channelId: Snowflake(30),
      ).threadInfo(budget: CommandExecutionBudget()),
      throwsArgumentError,
    );
  });
  test(
    'SDK errors are not retried and expired budget prevents requests',
    () async {
      final gateway = _Gateway();
      gateway.manager.fail = true;
      final service = DiscordBotThreadService(client: gateway);
      await expectLater(
        service.editThread(
          const ThreadModification(threadId: '80', name: 'x'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.manager.writes, hasLength(1));
      await expectLater(
        service.startThread(
          const ThreadCreation(name: 'x', channelId: '30'),
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(gateway.manager.writes, hasLength(1));
    },
  );
}
