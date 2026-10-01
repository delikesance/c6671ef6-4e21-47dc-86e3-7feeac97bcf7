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
}
