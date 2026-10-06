import 'package:bot_creator_shared/engine/bdfd/cooldown_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_cooldown_service.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

void main() {
  var now = 1000000;
  late MemoryBotDataStore store;
  late StoredBotCooldownService service;
  late BdfdRuntime runtime;
  BdfdContext context({
    String command = 'cmd',
    String user = '20',
    String guild = '10',
  }) => BdfdContext(
    variables: {'command.id': command, 'author.id': user, 'guild.id': guild},
  );
  setUp(() {
    now = 1000000;
    store = MemoryBotDataStore();
    service = StoredBotCooldownService(store, nowMilliseconds: () => now);
    runtime = BdfdRuntime(
      functions: bdfdCooldownFunctions(service, botId: 'bot'),
    );
  });
  Future<String> run(String source, {BdfdContext? ctx}) =>
      runtime.execute(source, context: ctx ?? context());
  for (final entry in {
    'cooldown': 'normal',
    'globalCooldown': 'global',
    'serverCooldown': 'server',
  }.entries) {
    test(
      '${entry.key} claims, reports remaining, stops and does not extend',
      () async {
        expect(await run('\$${entry.key}[30s;Wait %time%]OK'), 'OK');
        now += 5000;
        expect(
          await run(
            'Before\$${entry.key}[1h;Wait %time% / \$getCooldown[${entry.value}]]Never',
          ),
          'Wait 25 Seconds / 25',
        );
        now += 25000;
        expect(await run('\$getCooldown[${entry.value}]'), '0');
        expect(await run('\$${entry.key}[1s;Denied]OK'), 'OK');
      },
    );
  }
  test('normal cooldown isolates user guild command and bot', () async {
    const code = r'$cooldown[1m;denied]ok';
    expect(await run(code), 'ok');
    expect(await run(code, ctx: context(user: '21')), 'ok');
    expect(await run(code, ctx: context(guild: '11')), 'ok');
    expect(await run(code, ctx: context(command: 'other')), 'ok');
    final other = BdfdRuntime(
      functions: bdfdCooldownFunctions(service, botId: 'other'),
    );
    expect(await other.execute(code, context: context()), 'ok');
    expect(await run(code), 'denied');
  });
  test(
    'global crosses guilds for one user, server crosses users in one guild',
    () async {
      expect(await run(r'$globalCooldown[1m;denied]ok'), 'ok');
      expect(
        await run(r'$globalCooldown[1m;denied]ok', ctx: context(guild: '11')),
        'denied',
      );
      expect(
        await run(r'$globalCooldown[1m;denied]ok', ctx: context(user: '21')),
        'ok',
      );
      expect(await run(r'$serverCooldown[1m;denied]ok'), 'ok');
      expect(
        await run(r'$serverCooldown[1m;denied]ok', ctx: context(user: '21')),
        'denied',
      );
      expect(
        await run(r'$serverCooldown[1m;denied]ok', ctx: context(guild: '11')),
        'ok',
      );
    },
  );
  test('new service sees persisted cooldown without runtime state', () async {
    await run(r'$cooldown[1m;denied]');
    final fresh = BdfdRuntime(
      functions: bdfdCooldownFunctions(
        StoredBotCooldownService(store, nowMilliseconds: () => now),
        botId: 'bot',
      ),
    );
    expect(
      await fresh.execute(r'$getCooldown[normal]', context: context()),
      '60',
    );
    expect(await store.getGlobalVariables('bot'), isEmpty);
  });
  test(
    'simultaneous claims through separate services allow exactly one',
    () async {
      final key = BotCooldownKey(
        botId: 'bot',
        commandId: 'cmd',
        type: BotCooldownType.normal,
        userId: '20',
        guildId: '10',
      );
      final second = StoredBotCooldownService(
        store,
        nowMilliseconds: () => now,
      );
      final results = await Future.wait([
        service.acquire(
          key,
          const Duration(minutes: 1),
          budget: CommandExecutionBudget(),
        ),
        second.acquire(
          key,
          const Duration(minutes: 1),
          budget: CommandExecutionBudget(),
        ),
      ]);
      expect(
        results.where((duration) => duration == Duration.zero),
        hasLength(1),
      );
      expect(
        results.where((duration) => duration == const Duration(minutes: 1)),
        hasLength(1),
      );
    },
  );
  test(
    'message lazy once, earlier effects remain, later effects stop',
    () async {
      final calls = <String>[];
      runtime = BdfdRuntime(
        functions: {
          ...bdfdCooldownFunctions(service, botId: 'bot'),
          'probe': BdfdNativeFunction(
            minArguments: 1,
            maxArguments: 1,
            handler: (call) async {
              calls.add(await call.argument(0));
              return r'$cooldown[9s;bad]';
            },
          ),
        },
      );
      expect(await run(r'$cooldown[1m;$probe[error]]OK'), 'OK');
      expect(calls, isEmpty);
      expect(
        await run(r'$probe[before]$cooldown[1m;$probe[error]]$probe[after]'),
        r'$cooldown[9s;bad]',
      );
      expect(calls, ['before', 'error']);
    },
  );
  test('empty error is catchable and retains getCooldown in catch', () async {
    await run(r'$cooldown[30s;]');
    expect(
      await run(r'$try$cooldown[30s;]never$catch$getCooldown[normal]$endtry'),
      '30',
    );
  });
  test(
    'translations use official four labels and single-pass placeholders',
    () async {
      await run(r'$cooldown[10m;denied]');
      now += 6000;
      expect(
        await run(
          r'$changeCooldownTime[Jours;Heures;Mins;Secs]$cooldown[10m;%time% / %time-m% / %time-s%]',
        ),
        '9.9 Mins / 9.9 Mins / 594 Secs',
      );
      expect(
        await run(r'$changeCooldownTime[J;H;M;%time%]$cooldown[1m;%time-s%]'),
        '594 %time%',
      );
      expect(await run(r'$cooldown[1m;%time%]'), '9.9 Minutes');
    },
  );
  test(
    'invalid durations types arities identities never create cooldown',
    () async {
      for (final source in [
        r'$cooldown[1s]',
        r'$cooldown[;bad]',
        r'$cooldown[0s;bad]',
        r'$cooldown[-1s;bad]',
        r'$getCooldown',
        r'$getCooldown[Normal]',
        r'$changeCooldownTime[1h]',
        r'$changeCooldownTime[a;b;;d]',
      ]) {
        await expectLater(
          run(source),
          throwsA(isA<BdfdNativeError>()),
          reason: source,
        );
      }
      for (final vars in [
        {'command.id': 'cmd', 'guild.id': '10'},
        {'author.id': '20', 'guild.id': '10'},
        {'command.id': 'cmd', 'author.id': '+20', 'guild.id': '10'},
      ]) {
        await expectLater(
          run(r'$cooldown[1s;bad]', ctx: BdfdContext(variables: vars)),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(await run(r'$getCooldown[normal]'), '0');
    },
  );
  test('global works without guild; server without author', () async {
    expect(
      await run(
        r'$globalCooldown[1s;bad]OK',
        ctx: BdfdContext(variables: {'command.id': 'cmd', 'author.id': '20'}),
      ),
      'OK',
    );
    expect(
      await run(
        r'$serverCooldown[1s;bad]OK',
        ctx: BdfdContext(variables: {'command.id': 'cmd', 'guild.id': '10'}),
      ),
      'OK',
    );
  });
  test('unknown wrappers do not acquire cooldown', () async {
    const code = r'$unknown[$cooldown[1m;bad]]';
    expect(await run(code), code);
    expect(await run(r'$getCooldown[normal]'), '0');
  });
  test('expired budget does not persist a cooldown', () async {
    final ctx = BdfdContext(
      variables: context().variables,
      budget: CommandExecutionBudget(limit: Duration.zero),
    );
    await expectLater(
      run(r'$cooldown[1m;bad]', ctx: ctx),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(await run(r'$getCooldown[normal]'), '0');
  });
}
