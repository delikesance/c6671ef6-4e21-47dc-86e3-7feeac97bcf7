import 'package:bot_creator_shared/engine/bdfd/visual/control_flow_logic.dart';
import 'package:bot_creator_shared/utils/runtime_cooldowns.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:test/test.dart';

Map<String, String> context({
  String user = '20',
  String guild = '10',
  String command = 'scolor',
}) => {'user.id': user, 'guild.id': guild, 'commandName': command};

Future<Map<String, String>> run(
  Map<String, String> vars, {
  String bot = 'bot',
  String scope = 'user',
  String duration = '1m',
  bool change = false,
  List<String>? messages,
}) async {
  final results = <String, String>{};
  await cooldownBlock(
    payload: {
      'scope': scope,
      'duration': duration,
      'key': RuntimeCooldowns.defaultVariable(scope),
      if (change) 'operation': 'change',
      'errorMessage': r'((cooldown.remaining)) seconds',
    },
    resultKey: 'cooldown',
    results: results,
    variables: vars,
    botId: bot,
    resolveValue: (input) => resolveTemplatePlaceholders(input, vars),
    executeActions: (actions) async {
      messages?.addAll(
        actions.map((action) => action.payload['content'] as String),
      );
      return {};
    },
  );
  return results;
}

void main() {
  setUp(RuntimeCooldowns.expirations.clear);
  test('user cooldown separates members and guilds', () async {
    expect((await run(context()))['cooldown'], 'SET');
    expect((await run(context(user: '21')))['cooldown'], 'SET');
    expect((await run(context(guild: '11')))['cooldown'], 'SET');
    expect((await run(context()))['__stopped__'], 'true');
  });
  test('guild cooldown is shared by members but separates guilds', () async {
    await run(context(), scope: 'guild');
    expect(
      (await run(context(user: '21'), scope: 'guild'))['cooldown'],
      'ACTIVE',
    );
    expect(
      (await run(context(guild: '11'), scope: 'guild'))['cooldown'],
      'SET',
    );
  });
  test(
    'global cooldown is shared across users and guilds for a command',
    () async {
      await run(context(), scope: 'global');
      expect(
        (await run(
          context(user: '21', guild: '11'),
          scope: 'global',
        ))['cooldown'],
        'ACTIVE',
      );
      expect(
        (await run(context(command: 'another'), scope: 'global'))['cooldown'],
        'SET',
      );
      expect(
        (await run(context(), scope: 'global', bot: 'another'))['cooldown'],
        'SET',
      );
    },
  );
  for (final scope in ['user', 'guild', 'global']) {
    test(
      'change modifies only an active $scope cooldown and can clear it',
      () async {
        final vars = context();
        await run(vars, scope: scope, change: true);
        expect(RuntimeCooldowns.expirations, isEmpty);
        await run(vars, scope: scope);
        final messages = <String>[];
        await run(vars, scope: scope, messages: messages);
        expect(double.parse(messages.single.split(' ').first), greaterThan(0));
        await run(vars, scope: scope, change: true, duration: '500ms');
        expect(
          double.parse(RuntimeCooldowns.query(vars)),
          inExclusiveRange(0, .501),
        );
        await run(vars, scope: scope, change: true, duration: '0s');
        expect(RuntimeCooldowns.query(vars), '0');
        expect((await run(vars, scope: scope))['cooldown'], 'SET');
      },
    );
  }
  test('expired cooldown is removed and no longer blocks execution', () async {
    final vars = context();
    await run(vars, duration: '10ms');
    await Future<void>.delayed(const Duration(milliseconds: 25));
    expect(RuntimeCooldowns.query(vars), '0');
    expect(RuntimeCooldowns.expirations, isEmpty);
    expect((await run(vars))['cooldown'], 'SET');
  });
  test('invalid duration cannot register a cooldown', () async {
    await expectLater(
      run(context(), duration: '2nonsense'),
      throwsFormatException,
    );
    expect(RuntimeCooldowns.expirations, isEmpty);
  });
}
