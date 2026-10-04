import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:test/test.dart';
import 'package:nyxx/nyxx.dart';
import 'helpers/variables_test_helpers.dart';

class _Messages implements BotMessageService {
  final requests = <BotMessageRequest>[];
  bool fail = false;
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    requests.add(request);
    if (fail) throw StateError('Discord unavailable');
    return BotMessageResult(messageId: '${requests.length}');
  }
}

class _Interaction implements MessageResponse {
  bool isAcknowledged = false;
  int acknowledgements = 0;
  int deletions = 0;
  Duration delay = Duration.zero;
  final updates = <MessageUpdateBuilder>[];
  final followups = <MessageBuilder>[];
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
    acknowledgements++;
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    isAcknowledged = true;
    return null;
  }

  @override
  Future<void> deleteOriginalResponse() async {
    deletions++;
  }

  @override
  Future<Message> updateOriginalResponse(MessageUpdateBuilder builder) async {
    updates.add(builder);
    return _Message();
  }

  @override
  Future<Message> createFollowup(
    MessageBuilder builder, {
    bool? isEphemeral,
  }) async {
    followups.add(builder);
    return _Message();
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
  test('versioned selection rejects unknown values instead of guessing', () {
    expect(BdfdBackend.parse(null), BdfdBackend.legacy);
    expect(BdfdBackend.parse('legacy-v1'), BdfdBackend.legacy);
    expect(BdfdBackend.parse('native-v1'), BdfdBackend.native);
    for (final value in ['native', 'v2', false, 123]) {
      expect(() => BdfdBackend.parse(value), throwsFormatException);
    }
  });
  test(
    'unset or explicit legacy backend retains the original raw source',
    () async {
      final messages = _Messages();
      final source = r'$unknown[$sendMessage[no]] ((argument))';
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
      );
      final legacySources = <String>[];
      var prepared = 0;
      for (final backend in [null, 'legacy-v1']) {
        expect(
          await execution.execute(
            source,
            backend: backend,
            executeLegacy: (source) async {
              legacySources.add(source);
            },
            onNativePrepared: () async {
              prepared++;
            },
          ),
          isNull,
        );
      }
      expect(legacySources, [source, source]);
      expect(prepared, 0);
      expect(messages.requests, isEmpty);
    },
  );
  test('native prepares before acknowledgement then executes directly', () async {
    final messages = _Messages();
    final store = MemoryBotDataStore();
    var legacy = 0;
    var prepared = 0;
    final variables = <String, String>{
      'guild.id': '10',
      'author.id': '20',
      'message.content': 'hello world',
    };
    final execution = BdfdScriptExecution(
      store: store,
      botId: 'bot',
      variables: variables,
      messages: messages,
    );
    await execution.execute(
      r'$textSplit[$message; ]$setUserVar[word;$splitText[2]]$sendMessage[$getUserVar[word];yes]',
      backend: 'native-v1',
      executeLegacy: (_) async {
        legacy++;
      },
      onNativePrepared: () async {
        expect(messages.requests, isEmpty);
        expect(store.scopedVariables, isEmpty);
        prepared++;
      },
    );
    expect(prepared, 1);
    expect(legacy, 0);
    expect(messages.requests.map((r) => r.payload['content']), ['world', '1']);
    expect(store.scopedVariables['guildMember']!['10:20']!['word'], 'world');
  });
  test(
    'unsupported native capabilities fail before acknowledgement or effects',
    () async {
      final messages = _Messages();
      var legacy = 0;
      var prepared = 0;
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[must not send]$ban[123]',
          backend: 'native-v1',
          executeLegacy: (_) async {
            legacy++;
          },
          onNativePrepared: () async {
            prepared++;
          },
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(prepared, 0);
      expect(legacy, 0);
      expect(messages.requests, isEmpty);
    },
  );
  test(
    'unknown functions are opaque and accepted on the native entry point',
    () async {
      final messages = _Messages();
      var legacy = 0;
      final source = r'$unknown[$sendMessage[must not send]]';
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
      );
      await execution.execute(
        source,
        backend: 'native-v1',
        executeLegacy: (_) async {
          legacy++;
        },
      );
      expect(legacy, 0);
      expect(messages.requests.single.payload['content'], source);
    },
  );
  test(
    'native effects are never replayed on the legacy backend after failure',
    () async {
      final messages = _Messages()..fail = true;
      var legacy = 0;
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[once]$sendMessage[never]',
          backend: 'native-v1',
          executeLegacy: (_) async {
            legacy++;
          },
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(legacy, 0);
      expect(messages.requests.map((r) => r.payload['content']), ['once']);
    },
  );
  test(
    'unknown backend fails before either execution path or acknowledgement',
    () async {
      final messages = _Messages();
      var legacy = 0;
      var prepared = 0;
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[never]',
          backend: 'invalid',
          executeLegacy: (_) async {
            legacy++;
          },
          onNativePrepared: () async {
            prepared++;
          },
        ),
        throwsFormatException,
      );
      expect(legacy, 0);
      expect(prepared, 0);
      expect(messages.requests, isEmpty);
    },
  );
  test(
    'native preparation hook consumes the same deadline as the script',
    () async {
      final messages = _Messages();
      final context = BdfdContext(
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 15)),
      );
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: context.variables,
        messages: messages,
        context: context,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[never]',
          backend: 'native-v1',
          executeLegacy: (_) async {},
          onNativePrepared: () =>
              Future<void>.delayed(const Duration(milliseconds: 50)),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(messages.requests, isEmpty);
    },
  );
  test(
    'native slash channel-only output removes its deferred placeholder',
    () async {
      final interaction = _Interaction();
      final messages = _Messages();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
        interaction: interaction,
      );
      await execution.execute(
        r'$sendMessage[one]$sendMessage[two]',
        backend: 'native-v1',
        executeLegacy: (_) async {
          fail('Unexpected legacy execution');
        },
      );
      expect(interaction.acknowledgements, 1);
      expect(interaction.deletions, 1);
      expect(messages.requests.map((r) => r.payload['content']), [
        'one',
        'two',
      ]);
    },
  );
  test(
    'native original slash response completes its defer and is retained',
    () async {
      final interaction = _Interaction();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        interaction: interaction,
        messages: DiscordBotMessageService(
          botId: 'bot',
          interaction: interaction,
        ),
      );
      await execution.execute(
        'visible',
        backend: 'native-v1',
        executeLegacy: (_) async {
          fail('Unexpected legacy execution');
        },
      );
      expect(interaction.acknowledgements, 1);
      expect(interaction.deletions, 0);
      expect(interaction.updates.single.content, 'visible');
      expect(execution.context.response.originalResponseCompleted, true);
    },
  );
  test(
    'native ephemeral followup also removes only its pending original',
    () async {
      final interaction = _Interaction();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        interaction: interaction,
        messages: DiscordBotMessageService(
          botId: 'bot',
          interaction: interaction,
        ),
      );
      await execution.execute(
        r'$ephemeral private',
        backend: 'native-v1',
        executeLegacy: (_) async {
          fail('Unexpected legacy execution');
        },
      );
      expect(interaction.deletions, 1);
      expect(interaction.followups.single.content, ' private');
      expect(execution.context.response.originalResponseCompleted, false);
    },
  );
  test(
    'an existing original response belongs to its caller and is never deleted',
    () async {
      final interaction = _Interaction()..isAcknowledged = true;
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: _Messages(),
        interaction: interaction,
      );
      await execution.execute(
        r'$sendMessage[one]',
        backend: 'native-v1',
        executeLegacy: (_) async {},
      );
      expect(interaction.acknowledgements, 0);
      expect(interaction.deletions, 0);
    },
  );
  test(
    'native capability rejection occurs before actual slash acknowledgement',
    () async {
      final interaction = _Interaction();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: _Messages(),
        interaction: interaction,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[never]$ban[123]',
          backend: 'native-v1',
          executeLegacy: (_) async {
            fail('Unexpected legacy execution');
          },
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(interaction.acknowledgements, 0);
      expect(interaction.deletions, 0);
    },
  );
  test(
    'late slash acknowledgement is cleaned without executing script effects',
    () async {
      final interaction = _Interaction()
        ..delay = const Duration(milliseconds: 50);
      final messages = _Messages();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 15)),
        messages: messages,
        interaction: interaction,
      );
      await expectLater(
        execution.execute(
          r'$sendMessage[never]',
          backend: 'native-v1',
          executeLegacy: (_) async {
            fail('Unexpected legacy execution');
          },
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      await Future<void>.delayed(const Duration(milliseconds: 70));
      expect(interaction.acknowledgements, 1);
      expect(interaction.deletions, 1);
      expect(messages.requests, isEmpty);
    },
  );
}
