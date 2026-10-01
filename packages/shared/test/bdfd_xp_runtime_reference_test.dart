import 'dart:math' as math;

import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/actions/executors/control_flow_executor.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/bdfd_compiler.dart';
import 'package:bot_creator_shared/utils/bdfd_runtime_reference.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:bot_creator_shared/utils/runtime_variables.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';

class _NoDiscordGateway implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Fixture must not contact Discord: $invocation');
}

void main() {
  late MemoryBotDataStore store;
  var testNumber = 0;
  late String botId;
  final contexts = <Map<String, String>>[];

  setUp(() {
    botId = 'xp-test-${++testNumber}';
    store = MemoryBotDataStore(
      scopedDefinitions: [
        {
          'key': 'xp',
          'scope': 'guildMember',
          'defaultValue': 0,
          'valueType': 'number',
        },
        {
          'key': 'level',
          'scope': 'guildMember',
          'defaultValue': 0,
          'valueType': 'number',
        },
      ],
    );
  });
  tearDown(() {
    for (final variables in contexts) {
      ControlFlowExecutor.removeRuntimeCooldown(
        botId,
        'user',
        'user_cooldown',
        variables,
      );
    }
    contexts.clear();
  });

  Future<Map<String, String>> run(
    String source, {
    String guild = '10',
    String user = '20',
    String text = '',
    bool bot = false,
    bool omitResponse = false,
    Map<String, String> options = const {},
  }) async {
    final compiled = BdfdCompiler().compile(source);
    expect(compiled.hasErrors, false, reason: '${compiled.diagnostics}');
    final variables = <String, String>{
      'bot.id': botId,
      'guild.id': guild,
      'author.id': user,
      'user.id': user,
      'author.isBot': '$bot',
      'user.isBot': '$bot',
      'message.content': text,
      ...options,
    };
    contexts.add(variables);
    await hydrateRuntimeVariables(
      store: store,
      botId: botId,
      runtimeVariables: variables,
      guildContextId: guild,
      userContextId: user,
    );
    final result = await handleActions(
      _NoDiscordGateway(),
      null,
      actions: compiled.actions
          .where(
            (a) =>
                !omitResponse ||
                (a.type != BotCreatorActionType.respondWithMessage &&
                    a.type != BotCreatorActionType.sendMessage),
          )
          .toList(),
      store: store,
      botId: botId,
      variables: variables,
      resolveTemplate: (input) => resolveTemplatePlaceholders(input, variables),
      fallbackGuildId: guild.isEmpty ? null : Snowflake.parse(guild),
    );
    expect(result['error'], isNull, reason: '$result');
    return variables;
  }

  Future<dynamic> xp(String guild, String user) =>
      store.getScopedVariable(botId, 'guildMember', '$guild:$user', 'xp');

  test(
    'BDFD message workflow awards capped XP with member/server isolation',
    () async {
      await run(bdfdXpMessageWorkflow, text: 'a' * 11);
      expect(await xp('10', '20'), '2');
      await run(bdfdXpMessageWorkflow, text: 'a' * 500);
      expect(await xp('10', '20'), '2', reason: 'same member is on cooldown');
      await run(bdfdXpMessageWorkflow, guild: '11', text: 'a' * 500);
      expect(await xp('11', '20'), '30');
      await run(bdfdXpMessageWorkflow, user: '21', text: 'a');
      expect(await xp('10', '21'), '1');
    },
  );

  test(
    'blank, bot and DM messages do not award XP or consume the cooldown',
    () async {
      await run(bdfdXpMessageWorkflow, text: '   \n  ');
      await run(bdfdXpMessageWorkflow, text: 'hello', bot: true);
      await run(bdfdXpMessageWorkflow, guild: '', text: 'hello');
      expect(await xp('10', '20'), 0);
      await run(bdfdXpMessageWorkflow, text: 'hello');
      expect(await xp('10', '20'), '1');
    },
  );

  test(
    'level up carries remaining XP and /level uses exponential cost',
    () async {
      await store.setScopedVariable(botId, 'guildMember', '10:20', 'xp', 90);
      await run(bdfdXpMessageWorkflow, text: 'a' * 300);
      expect(await xp('10', '20'), '20');
      expect(
        await store.getScopedVariable(botId, 'guildMember', '10:20', 'level'),
        '1',
      );
      final variables = await run(bdfdXpLevelCommand, omitResponse: true);
      final response = BdfdCompiler().compile(bdfdXpLevelCommand).actions.last;
      expect(
        resolveTemplatePlaceholders(
          response.payload['content'] as String,
          variables,
        ),
        contains('Niveau 1 — 20 / 150 XP'),
      );
      final fresh = await run(
        bdfdXpLevelCommand,
        user: '22',
        omitResponse: true,
      );
      expect(fresh['temp.level'], '0');
      expect(fresh['temp.xp'], '0');
      expect(fresh['temp.required'], '100');
      await store.setScopedVariable(botId, 'guildMember', '10:20', 'level', 3);
      final higher = await run(bdfdXpLevelCommand, omitResponse: true);
      expect(higher['temp.required'], '338');
    },
  );

  test('concurrent messages award only once during the cooldown', () async {
    await Future.wait(
      List.generate(5, (_) => run(bdfdXpMessageWorkflow, text: 'a' * 300)),
    );
    expect(await xp('10', '20'), '30');
  });

  test(
    'numeric checks resolve slash options and temporary values at runtime',
    () async {
      final variables = await run(
        r'$var[gain;((opts.montant))]'
        r'$var[valid;$isNumber[$var[gain]]]'
        r'$var[rawValid;$isNumber[((opts.montant))]]'
        r'$var[integer;$isInteger[((opts.montant))]]',
        options: {'opts.montant': '100'},
      );
      expect(variables['temp.gain'], '100');
      expect(variables['temp.valid'], 'true');
      expect(variables['temp.rawValid'], 'true');
      expect(variables['temp.integer'], 'true');
    },
  );

  test('nested local message and explicit member getters resolve', () async {
    await store.setScopedVariable(botId, 'guildMember', '10:20', 'xp', 90);
    await store.setScopedVariable(botId, 'guildMember', '10:21', 'xp', 156);
    final variables = await run(
      r'$var[target;((opts.membre.id))]'
      r'$var[authorXp;$getGuildMemberVar[xp]]'
      r'$var[xp;$getGuildMemberVar[xp;$var[target]]]'
      r'$var[msg;XP ($var[xp]) / $getGuildMemberVar[xp;((opts.membre.id))]]'
      r'$reply$c[]$var[msg]',
      options: {'opts.membre.id': '21'},
      omitResponse: true,
    );
    expect(variables['temp.authorXp'], '90');
    expect(variables['temp.xp'], '156');
    expect(variables['temp.msg'], 'XP (156) / 156');
  });

  test(
    'repeated conditional level ups preserve surplus and current state',
    () async {
      await store.setScopedVariable(botId, 'guildMember', '10:20', 'xp', 156);
      await store.setScopedVariable(botId, 'guildMember', '10:20', 'level', 2);
      final variables = await run(
        r'$var[level;$getGuildMemberVar[level]]'
        r'$var[xp;$sum[$getGuildMemberVar[xp];((opts.montant))]]'
        r'$loop[10]'
        r'$var[required;$ceil[$calculate[100*(1.5^$var[level])]]]'
        r'$if[$var[xp]>=$var[required]]'
        r'$var[xp;$sub[$var[xp];$var[required]]]'
        r'$var[level;$sum[$var[level];1]]'
        r'$endif$endloop'
        r'$setGuildMemberVar[xp;$var[xp]]'
        r'$setGuildMemberVar[level;$var[level]]',
        options: {'opts.montant': '100'},
      );
      expect(variables['temp.level'], '3');
      expect(await xp('10', '20'), '31');
    },
  );

  test('args falls back to named slash options', () async {
    final variables = await run(
      r'$var[target;$args[0;membre.id]]$var[gain;$args[1;montant]]',
      options: {'opts.membre.id': '21', 'opts.montant': '100'},
    );
    expect(variables['temp.target'], '21');
    expect(variables['temp.gain'], '100');
  });

  for (final sample in [
    ('-12', 'true', 'true'),
    ('1.5', 'true', 'false'),
    ('abc', 'false', 'false'),
    ('', 'false', 'false'),
  ]) {
    test('runtime numeric checks validate "${sample.$1}"', () async {
      final variables = await run(
        r'$var[number;$isNumber[((opts.value))]]'
        r'$var[integer;$isInteger[((opts.value))]]',
        options: {'opts.value': sample.$1},
      );
      expect(variables['temp.number'], sample.$2);
      expect(variables['temp.integer'], sample.$3);
    });
  }

  test('boolean and hex checks also resolve runtime options', () async {
    final variables = await run(
      r'$var[boolean;$isBoolean[((opts.flag))]]'
      r'$var[hex;$isValidHex[((opts.color))]]',
      options: {'opts.flag': 'TRUE', 'opts.color': '#ff00aa'},
    );
    expect(variables['temp.boolean'], 'true');
    expect(variables['temp.hex'], 'true');
  });

  Future<List<String>> runAddXp({
    String amount = '100',
    String target = '21',
    bool admin = true,
  }) async {
    final variables = <String, String>{
      'guild.id': '10',
      'author.id': '20',
      'guild.ownerId': '99',
      'member.isAdmin': '$admin',
      'member.permissions': admin ? 'administrator' : '',
      'opts.membre.id': target,
      'opts.montant': amount,
    };
    await hydrateRuntimeVariables(
      store: store,
      botId: botId,
      runtimeVariables: variables,
      guildContextId: '10',
      userContextId: '20',
    );
    final compiled = BdfdCompiler().compile(bdfdXpAddCommand);
    expect(compiled.hasErrors, false, reason: '${compiled.diagnostics}');
    await hydrateActionPlaceholders(
      store: store,
      botId: botId,
      actions: compiled.actions,
      variables: variables,
    );
    final replies = <String>[];
    await executeCompiledActions(
      actions: compiled.actions,
      store: store,
      variables: variables,
      replies: replies,
    );
    return replies;
  }

  test(
    'admin XP command carries surplus to the targeted member only',
    () async {
      await store.setScopedVariable(botId, 'guildMember', '10:21', 'xp', 156);
      await store.setScopedVariable(botId, 'guildMember', '10:21', 'level', 2);
      final replies = await runAddXp();
      expect(await xp('10', '21'), '31');
      expect(
        await store.getScopedVariable(botId, 'guildMember', '10:21', 'level'),
        '3',
      );
      expect(await xp('10', '20'), 0);
      expect(replies.single, contains('niveau 2 ➜ 3 (31 XP restants)'));
      expect(replies.single, isNot(contains('((')));
    },
  );

  test(
    'admin XP command initializes a new member and crosses exact threshold',
    () async {
      final replies = await runAddXp();
      expect(await xp('10', '21'), '0');
      expect(
        await store.getScopedVariable(botId, 'guildMember', '10:21', 'level'),
        '1',
      );
      expect(replies.single, contains('niveau 0 ➜ 1 (0 XP restants)'));
    },
  );

  test('large awards cross all affordable levels without losing XP', () async {
    await runAddXp(amount: '100000');
    var remaining = 100000;
    var level = 0;
    var cost = 100;
    while (remaining >= cost) {
      remaining -= cost;
      level++;
      cost = (100 * math.pow(1.5, level)).ceil();
    }
    expect(await xp('10', '21'), '$remaining');
    expect(
      await store.getScopedVariable(botId, 'guildMember', '10:21', 'level'),
      '$level',
    );
    expect(level, greaterThan(10));
  });

  test('admin XP command denies non-admins before writes', () async {
    final replies = await runAddXp(admin: false);
    expect(replies.single, contains('administrateurs'));
    expect(await xp('10', '21'), 0);
  });

  for (final invalid in ['', 'abc', '0', '-1', '1.5']) {
    test('admin XP command rejects invalid amount "$invalid"', () async {
      final replies = await runAddXp(amount: invalid);
      expect(replies.single, contains('Indique un montant'));
      expect(await xp('10', '21'), 0);
    });
  }

  test(
    'admin XP command preserves corrupt balances for explicit repair',
    () async {
      await store.setScopedVariable(botId, 'guildMember', '10:21', 'xp', -307);
      await store.setScopedVariable(botId, 'guildMember', '10:21', 'level', 4);
      final replies = await runAddXp();
      expect(replies.single, contains('réparation'));
      expect(await xp('10', '21'), -307);
      expect(
        await store.getScopedVariable(botId, 'guildMember', '10:21', 'level'),
        4,
      );
    },
  );
}
