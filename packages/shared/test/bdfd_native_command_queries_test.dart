import 'package:bot_creator_shared/utils/command_invocation_metadata.dart';
import 'package:bot_creator_shared/engine/bdfd/command_query_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_command_query_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Queries implements BotCommandQueryService {
  final requests = <String>[];
  @override
  Future<List<BotCommandDefinition>> commands({
    required CommandExecutionBudget budget,
  }) async {
    requests.add('commands');
    return const [
      BotCommandDefinition('!help'),
      BotCommandDefinition(r'$var[bad;yes]'),
    ];
  }

  @override
  Future<List<BotGlobalSlashCommand>> globalSlashCommands({
    required CommandExecutionBudget budget,
  }) async {
    requests.add('global');
    return const [BotGlobalSlashCommand(id: '100', name: 'help')];
  }

  @override
  Future<String> invite({required CommandExecutionBudget budget}) async =>
      'configured-url';
  @override
  Future<void> leaveGuild(
    String? guildId, {
    required CommandExecutionBudget budget,
  }) async {
    requests.add('leave:$guildId');
  }
}

class _Store extends MemoryBotDataStore {
  bool? forceRefresh;
  List<Map<String, dynamic>> rows = [
    {
      'name': 'HELP',
      'data': {'triggerType': 'prefix'},
    },
    {
      'name': 'second',
      'data': {
        'triggerType': 'hybrid',
        'legacyPrefixOverride': 'Alias',
        'legacyAliases': ['extra'],
      },
    },
    {
      'name': 'slash',
      'data': {'triggerType': 'slash'},
    },
  ];
  @override
  Future<Map<String, dynamic>> getApp(String botId) async => {'prefix': '?'};
  @override
  Future<List<Map<String, dynamic>>> listAppCommands(
    String botId, {
    bool forceRefresh = false,
  }) async {
    this.forceRefresh = forceRefresh;
    return rows;
  }
}

class _Command implements ApplicationCommand {
  _Command(this.name, this.type, int id) : id = Snowflake(id);
  @override
  final String name;
  @override
  final ApplicationCommandType type;
  @override
  final Snowflake id;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Commands implements GlobalApplicationCommandManager {
  int reads = 0;
  @override
  Future<List<ApplicationCommand>> list({bool? withLocalizations}) async {
    reads++;
    return [
      _Command('help', ApplicationCommandType.chatInput, 100),
      _Command('User menu', ApplicationCommandType.user, 101),
      _Command('Message menu', ApplicationCommandType.message, 102),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Application implements Application {
  @override
  Snowflake get id => Snowflake(555);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Users implements UserManager {
  final leaves = <Snowflake>[];
  @override
  Future<void> leaveGuild(Snowflake guildId) async {
    leaves.add(guildId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Client implements NyxxGateway {
  @override
  final _Commands commands = _Commands();
  @override
  final _Users users = _Users();
  @override
  final application = _Application();
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected SDK call ${invocation.memberName}');
}

BdfdEngine _engine(BotCommandQueryService service) => BdfdEngine(
  store: MemoryBotDataStore(),
  botId: 'bot',
  functions: bdfdCommandQueryFunctions(service),
);
void main() {
  test(
    'invocation adapter preserves stored name, alias and folder as data',
    () async {
      final metadata = buildCommandInvocationMetadata({
        'id': 'stable-command-id',
        'name': r'$var[spoof;yes]',
        'folder': 'Moderation/Subfolder',
        'data': {
          'legacyPrefixOverride': 'kick',
          'legacyAliases': ['remove'],
        },
      }, trigger: '?Remove');
      expect(metadata['command.id'], 'stable-command-id');
      final context = BdfdContext(variables: metadata);
      expect(
        await _engine(_Queries()).execute(
          r'$commandName|$commandTrigger|$commandFolder',
          context: context,
        ),
        r'$var[spoof;yes]|?Remove|Moderation/Subfolder',
      );
      expect(context.temporaryVariables, isEmpty);
      expect(
        buildCommandInvocationMetadata({
          'name': 'help',
        }, trigger: '/help')['command.folder'],
        '',
      );
    },
  );

  test(
    'command definitions and global slash list are distinct and never reparsed',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      final context = BdfdContext();
      expect(
        await engine.execute(r'$botCommands[|]', context: context),
        r'!help|$var[bad;yes]',
      );
      expect(context.temporaryVariables, isEmpty);
      expect(
        await engine.execute(
          r'$commandsCount/$slashCommandsCount/$slashID[help]',
        ),
        '2/1/100',
      );
      expect(service.requests, ['commands', 'commands', 'global', 'global']);
    },
  );
  test(
    'invocation metadata uses command ID rather than interaction event ID',
    () async {
      final service = _Queries();
      final context = BdfdContext(
        variables: {
          'command.name': '!Example',
          'command.trigger': '!alias',
          'command.folder': 'Moderation',
          'interaction.command.id': '100',
          'interaction.id': '999',
        },
      );
      expect(
        await _engine(service).execute(
          r'$commandName/$commandTrigger/$commandFolder/$slashID',
          context: context,
        ),
        '!Example/!alias/Moderation/100',
      );
      expect(service.requests, isEmpty);
      expect(
        await _engine(service).execute(
          r'$commandTrigger/$commandFolder',
          context: BdfdContext(
            variables: {'command.trigger': '', 'command.folder': ''},
          ),
        ),
        '/',
      );
    },
  );
  test(
    'missing invocation metadata and absent slash name produce clear errors',
    () async {
      final engine = _engine(_Queries());
      for (final source in [
        r'$commandName',
        r'$commandTrigger',
        r'$commandFolder',
        r'$slashID',
        r'$slashID[missing]',
        r'$slashID[]',
        r'$botCommands[]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test(
    'arity preflight prevents leave effect before malformed known function',
    () async {
      final service = _Queries();
      await expectLater(
        _engine(service).execute(r'$botLeave[55]$commandsCount[bad]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.requests, isEmpty);
    },
  );
  test(
    'unknown arguments stay opaque and known effects retain program order',
    () async {
      final service = _Queries();
      final engine = _engine(service);
      expect(
        await engine.execute(r'$getBotInvite$unknown[$botLeave[55]]'),
        r'configured-url$unknown[$botLeave[55]]',
      );
      expect(service.requests, isEmpty);
      expect(await engine.execute(r'$botLeave$botLeave[00055]'), '');
      expect(service.requests, ['leave:null', 'leave:55']);
    },
  );
  test(
    'leave IDs are required valid snowflakes when bracket form is used',
    () async {
      final service = _Queries();
      for (final id in ['', '0', '-1', 'abc', '9223372036854775808']) {
        await expectLater(
          _engine(service).execute('\$botLeave[$id]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(service.requests, isEmpty);
    },
  );
  test('cancelled budget prevents all service operations', () async {
    final service = _Queries();
    final budget = CommandExecutionBudget(limit: Duration.zero);
    await expectLater(
      _engine(
        service,
      ).execute(r'$botLeave[55]', context: BdfdContext(budget: budget)),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(service.requests, isEmpty);
  });
  test(
    'SDK reads fresh globals filtering context menus and never guild commands',
    () async {
      final client = _Client();
      final service = DiscordBotCommandQueryService(
        client: client,
        store: _Store(),
        botId: '555',
      );
      final budget = CommandExecutionBudget();
      final first = await service.globalSlashCommands(budget: budget);
      expect(first.map((row) => row.name), ['help']);
      expect(first.single.id, '100');
      await service.globalSlashCommands(budget: budget);
      expect(client.commands.reads, 2);
    },
  );
  test(
    'store definitions reflect product prefix/hybrid override and omit alias duplication',
    () async {
      final store = _Store();
      final service = DiscordBotCommandQueryService(
        client: _Client(),
        store: store,
        botId: '555',
      );
      expect(
        (await service.commands(
          budget: CommandExecutionBudget(),
        )).map((row) => row.name),
        ['?help', '?alias', 'slash'],
      );
      expect(store.forceRefresh, isTrue);
      store.rows = [
        {
          'name': 'new',
          'data': {'triggerType': 'prefix'},
        },
      ];
      expect(
        (await service.commands(budget: CommandExecutionBudget())).single.name,
        '?new',
      );
    },
  );
  test(
    'SDK invite matches configured product policy and leave calls real SDK API',
    () async {
      final client = _Client();
      final service = DiscordBotCommandQueryService(
        client: client,
        store: _Store(),
        botId: '555',
        guildId: Snowflake(50),
        invitePermissions: 1024,
      );
      final budget = CommandExecutionBudget();
      expect(
        await service.invite(budget: budget),
        'https://discord.com/api/oauth2/authorize?client_id=555&scope=bot+applications.commands&permissions=1024',
      );
      await service.leaveGuild(null, budget: budget);
      await service.leaveGuild('51', budget: budget);
      expect(client.users.leaves, [Snowflake(50), Snowflake(51)]);
    },
  );
}
