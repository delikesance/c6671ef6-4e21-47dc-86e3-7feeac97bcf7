import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Store extends MemoryBotDataStore {
  final workflows = <String, Map<String, dynamic>>{};
  Duration delay = Duration.zero;
  @override
  Future<Map<String, dynamic>?> getWorkflowByName(
    String botId,
    String name,
  ) async {
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    return workflows[name];
  }

  void script(String name, String source) => workflows[name] = {
    'name': name,
    'executionMode': 'bdfd_script',
    'bdfdBackend': 'native-v1',
    'bdfdScriptContent': source,
  };
}

class _Messages implements BotMessageService {
  final sent = <String>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    sent.add(request.payload['content'].toString());
    return BotMessageResult(messageId: '${sent.length}');
  }
}

class _Gateway implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord access');
}

class _Interaction implements MessageResponse {
  bool isAcknowledged = false;
  int deleted = 0;
  final updates = <MessageUpdateBuilder>[];
  @override
  Snowflake? get guildId => Snowflake(10);
  @override
  Snowflake? get channelId => Snowflake(20);
  @override
  PartialChannel? get channel => null;
  @override
  Future<InteractionCallbackResponse?> acknowledge({
    bool? isEphemeral,
    bool? withResponse,
  }) async {
    isAcknowledged = true;
    return null;
  }

  @override
  Future<Message> updateOriginalResponse(MessageUpdateBuilder builder) async {
    updates.add(builder);
    return _Message();
  }

  @override
  Future<InteractionCallbackResponse?> respond(
    MessageBuilder builder, {
    bool? isEphemeral,
    bool? withResponse,
  }) async {
    isAcknowledged = true;
    updates.add(
      MessageUpdateBuilder(
        content: builder.content,
        embeds: builder.embeds,
        components: builder.components,
      ),
    );
    return null;
  }

  @override
  Future<Message> fetchOriginalResponse() async => _Message();

  @override
  Future<void> deleteOriginalResponse() async {
    deleted++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Message implements Message {
  @override
  Snowflake get id => Snowflake(123);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'native workflow shares variables JSON split responses and ordered output',
    () async {
      final store = _Store()
        ..script(
          'child',
          r'$var[x;changed]$jsonSet[n;2]$editSplitText[2;new]child',
        );
      final messages = _Messages();
      final context = BdfdContext();
      await BdfdEngine(store: store, botId: 'bot', messages: messages).execute(
        r'$jsonParse[{"n":1}]$textSplit[a,b;,]parent$callWorkflow[child]$var[x]:$json[n]:$splitText[2]:$workflowResponse',
        context: context,
      );
      expect(messages.sent, [
        'parent',
        'child',
        'changed:2:new:WORKFLOW_OK:main',
      ]);
      expect(context.activeWorkflows, isEmpty);
    },
  );
  test(
    'argument syntax is parsed before values and defaults required arguments are enforced',
    () async {
      final store = _Store()..script('child', r'$var[out;$message[name]]');
      store.workflows['child']!['arguments'] = [
        {'name': 'name', 'required': true},
      ];
      final context = BdfdContext(
        variables: {'interaction.isSlash': 'true'},
        temporaryVariables: {
          'data': r'other=hello $sendMessage[not code]; [x]',
        },
      );
      final engine = BdfdEngine(store: store, botId: 'bot');
      await engine.execute(
        r'$callWorkflow[child;name=$var[data]]',
        context: context,
      );
      expect(
        context.temporaryVariables['out'],
        context.temporaryVariables['data'],
      );
      await expectLater(
        engine.execute(r'$callWorkflow[child;$var[data]]', context: context),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'recursion carries workflow source and call stack and removes active entries',
    () async {
      final store = _Store()
        ..script('a', r'$callWorkflow[b]')
        ..script('b', r'$callWorkflow[a]');
      final context = BdfdContext();
      await expectLater(
        BdfdEngine(
          store: store,
          botId: 'bot',
        ).execute(r'$callWorkflow[a]', context: context),
        throwsA(
          isA<BdfdNativeError>().having(
            (e) => e.callStack.length,
            'call depth',
            greaterThanOrEqualTo(2),
          ),
        ),
      );
      expect(context.activeWorkflows, isEmpty);
    },
  );
  test(
    'failed lookup or child preflight does not flush parent text or start child effects',
    () async {
      final store = _Store()..script('bad', r'$sendMessage[never]$ban[1]');
      final messages = _Messages();
      final engine = BdfdEngine(store: store, botId: 'bot', messages: messages);
      for (final name in ['missing', 'bad']) {
        await expectLater(
          engine.execute('pending\$callWorkflow[$name]'),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(messages.sent, isEmpty);
    },
  );
  test(
    'workflow lookup shares deadline and late resolution cannot execute child',
    () async {
      final store = _Store()
        ..script('child', r'$setVar[bad;yes]')
        ..delay = const Duration(milliseconds: 50);
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 15)),
      );
      await expectLater(
        BdfdEngine(
          store: store,
          botId: 'bot',
        ).execute(r'$callWorkflow[child]', context: context),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(store.globalVariables, isEmpty);
    },
  );
  test(
    'native workflow guard stops caller without replaying child denial',
    () async {
      final store = _Store()..script('child', r'$onlyIf[false;denied]');
      final messages = _Messages();
      await BdfdEngine(
        store: store,
        botId: 'bot',
        messages: messages,
      ).execute(r'$callWorkflow[child]$setVar[after;bad]');
      expect(messages.sent, ['denied']);
      expect(store.globalVariables, isEmpty);
    },
  );
  test('native workflow explicitly refuses a legacy script backend', () async {
    final store = _Store()..script('child', r'$setVar[bad;yes]');
    store.workflows['child']!.remove('bdfdBackend');
    await expectLater(
      BdfdEngine(store: store, botId: 'bot').execute(r'$callWorkflow[child]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(store.globalVariables, isEmpty);
  });
  test(
    'native callWorkflow delegates actual visual actions through the handler',
    () async {
      final store = _Store();
      store.workflows['visual'] = {
        'name': 'visual',
        'actions': [
          Action(
            type: BotCreatorActionType.setTemporaryVariable,
            key: 'answer',
            payload: {'key': 'shared', 'value': 'visual'},
          ).toJson(),
        ],
      };
      final messages = _Messages();
      final variables = <String, String>{};
      await handleActions(
        _Gateway(),
        null,
        actions: [
          Action(
            type: BotCreatorActionType.runBdfdScript,
            payload: {
              'bdfdBackend': 'native-v1',
              'scriptContent':
                  r'$callWorkflow[visual]$var[shared]:$workflowResponse[answer]',
            },
          ),
        ],
        store: store,
        botId: 'bot',
        variables: variables,
        resolveTemplate: (s) => resolveTemplatePlaceholders(s, variables),
        bdfdMessages: messages,
        throwOnError: true,
      );
      expect(messages.sent, ['visual:OK']);
      expect(variables['temp.shared'], 'visual');
    },
  );
  test(
    'visual original response is retained by native slash lifecycle cleanup',
    () async {
      final store = _Store();
      store.workflows['visual'] = {
        'actions': [
          Action(
            type: BotCreatorActionType.respondWithMessage,
            payload: {'content': 'visible'},
          ).toJson(),
        ],
      };
      final interaction = _Interaction();
      final variables = <String, String>{};
      final execution = BdfdScriptExecution(
        store: store,
        botId: 'bot',
        variables: variables,
        interaction: interaction,
        messages: DiscordBotMessageService(
          botId: 'bot',
          interaction: interaction,
        ),
        runVisualWorkflow: (workflow, context) => handleActions(
          _Gateway(),
          interaction,
          actions: (workflow['actions'] as List)
              .map((a) => Action.fromJson(Map<String, dynamic>.from(a)))
              .toList(),
          store: store,
          botId: 'bot',
          variables: variables,
          resolveTemplate: (s) => s,
          bdfdContext: context,
          executionBudget: context.budget,
          workflowStack: context.activeWorkflows,
          throwOnError: true,
        ),
      );
      await execution.execute(r'$callWorkflow[visual]', backend: 'native-v1');
      expect(interaction.updates.single.content, 'visible');
      expect(interaction.deleted, 0);
      expect(execution.context.response.originalResponseCompleted, true);
    },
  );
}
