import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/execution.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Gateway implements NyxxGateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected Discord call');
}

class _Messages implements BotMessageService {
  final sent = <String>[];
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    sent.add(request.payload['content'].toString());
    return BotMessageResult(messageId: '${sent.length}');
  }
}

void main() {
  test(
    'native entry-point replay captures effects once and restores prior observer',
    () async {
      final messages = _Messages();
      final observed = <BdfdTraceEvent>[];
      final context = BdfdContext(onTrace: observed.add);
      final observer = context.onTrace;
      List<Map<String, dynamic>>? captured;
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: context.variables,
        context: context,
        messages: messages,
        onReplayCaptured: (frames, _) => captured = frames,
      );
      await execution.execute(
        r'$sendMessage[once]$if[true]ok$endif',
        backend: 'native-v1',
      );
      expect(messages.sent, ['once', 'ok']);
      expect(context.onTrace, same(observer));
      expect(observed, isNotEmpty);
      expect(
        captured!.any((frame) => frame['nativeStatus'] == 'selected'),
        true,
      );
      expect(captured!.every((frame) => frame['backend'] == 'native-v1'), true);
    },
  );

  test('plain native text produces a completed program replay', () async {
    List<Map<String, dynamic>>? captured;
    final execution = BdfdScriptExecution(
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: {},
      onReplayCaptured: (frames, _) => captured = frames,
    );
    expect(
      await execution.execute('plain text', backend: 'native-v1'),
      'plain text',
    );
    expect(captured!.single['nativeStatus'], 'completed');
    expect(captured!.single['result'], 'plain text');
  });

  test('native preflight failure is captured without sending', () async {
    final messages = _Messages();
    List<Map<String, dynamic>>? captured;
    final execution = BdfdScriptExecution(
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: {},
      messages: messages,
      onReplayCaptured: (frames, _) => captured = frames,
    );
    await expectLater(
      execution.execute(
        r'$sendMessage[forbidden]$kick[20]',
        backend: 'native-v1',
      ),
      throwsA(isA<Exception>()),
    );
    expect(messages.sent, isEmpty);
    expect(captured!.single['nativeStatus'], 'error');
    expect(captured!.single['line'], 1);
  });

  test(
    'replay callback failure cannot retry or fail an executed native script',
    () async {
      final messages = _Messages();
      final execution = BdfdScriptExecution(
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        messages: messages,
        onReplayCaptured: (_, _) => throw StateError('capture failed'),
      );
      await execution.execute(r'$sendMessage[once]', backend: 'native-v1');
      expect(messages.sent, ['once']);
    },
  );

  test(
    'visual parent replay contains native calls from nested branches',
    () async {
      final messages = _Messages();
      List<Map<String, dynamic>>? captured;
      await handleActions(
        _Gateway(),
        null,
        store: MemoryBotDataStore(),
        botId: 'bot',
        variables: {},
        resolveTemplate: (s) => s,
        bdfdMessages: messages,
        onReplayCaptured: (frames, _) => captured = frames,
        actions: [
          Action(
            type: BotCreatorActionType.ifBlock,
            payload: {
              'condition': 'true',
              'thenActions': [
                Action(
                  type: BotCreatorActionType.runBdfdScript,
                  payload: {
                    'bdfdBackend': 'native-v1',
                    'scriptContent': r'$sendMessage[nested]',
                  },
                ).toJson(),
              ],
            },
          ),
        ],
      );
      expect(messages.sent, ['nested']);
      expect(
        captured!.any(
          (frame) =>
              frame['actionType'] == r'$sendMessage' &&
              frame['nativeStatus'] == 'returned',
        ),
        true,
      );
    },
  );
}
