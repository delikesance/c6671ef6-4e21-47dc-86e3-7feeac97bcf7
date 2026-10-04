import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/message_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/services/bot_message_query_service.dart';
import 'package:bot_creator_shared/services/bot_reaction_service.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Services
    implements BotMessageService, BotMessageQueryService, BotReactionService {
  final events = <String>[];
  bool failSend = false, failPin = false;
  String? actualChannel = '99';
  int sends = 0;
  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) async => throw UnimplementedError();
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    events.add('send:${request.payload['content']}');
    sends++;
    if (failSend) throw StateError('send failed');
    return BotMessageResult(
      messageId: '${100 + sends}',
      channelId: actualChannel,
    );
  }

  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) async {
    events.add('${change.kind.name}:${change.channelId}:${change.messageId}');
    if (failPin) throw StateError('pin failed');
  }

  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) async => throw UnimplementedError();
  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    events.add(
      'react:${request.target.channelId}:${request.target.messageId}:${request.emojis.join(',')}',
    );
  }

  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) async => throw UnimplementedError();
  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) async => throw UnimplementedError();
}

void main() {
  BdfdEngine engine(_Services service) => BdfdEngine(
    store: MemoryBotDataStore(),
    botId: 'bot',
    messages: service,
    messageQueries: service,
    reactions: service,
  );
  test(
    'main response pin and reactions use actual returned channel and response ID',
    () async {
      final service = _Services();
      await engine(service).execute(
        r'$pinMessage$addReactions[🔥;🎉]Main',
        context: BdfdContext(
          variables: {'channel.id': '30', 'message.id': '40'},
        ),
      );
      expect(service.events, ['send:Main', 'pin:99:101', 'react:99:101:🔥,🎉']);
    },
  );
  test(
    'standalone sendMessage does not consume deferred response hooks',
    () async {
      final service = _Services();
      await engine(
        service,
      ).execute(r'$pinMessage$addReactions[🔥]$sendMessage[Side]Main');
      expect(service.events, [
        'send:Side',
        'send:Main',
        'pin:99:102',
        'react:99:102:🔥',
      ]);
    },
  );
  test(
    'send failure detaches pending draft and hooks before awaiting',
    () async {
      final service = _Services()..failSend = true;
      final output = BdfdMessageOutput(
            service,
            messageQueries: service,
            reactions: service,
          ),
          context = BdfdContext();
      final location = BdfdLocation('x', 0);
      output.append('First');
      output.deferPin();
      output.deferReactions(['🔥']);
      await expectLater(
        output.flush(context, location),
        throwsA(isA<BdfdNativeError>()),
      );
      service.failSend = false;
      output.append('Second');
      await output.flush(context, location);
      expect(service.events, ['send:First', 'send:Second']);
    },
  );
  test(
    'post-send failure never repeats the message or remaining deferred effects',
    () async {
      final service = _Services()..failPin = true;
      final output = BdfdMessageOutput(
            service,
            messageQueries: service,
            reactions: service,
          ),
          context = BdfdContext();
      final location = BdfdLocation('x', 0);
      output.append('First');
      output.deferPin();
      output.deferReactions(['🔥']);
      await expectLater(
        output.flush(context, location),
        throwsA(isA<BdfdNativeError>()),
      );
      service.failPin = false;
      output.append('Second');
      await output.flush(context, location);
      expect(service.events, ['send:First', 'pin:99:101', 'send:Second']);
    },
  );
  test(
    'missing actual returned channel fails instead of using triggering channel',
    () async {
      final service = _Services()..actualChannel = null;
      await expectLater(
        engine(service).execute(
          r'$pinMessage'
          '\nMain',
          context: BdfdContext(variables: {'channel.id': '30'}),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'discard clears deferred effects and empty response does not synthesize a send',
    () async {
      final service = _Services();
      final output = BdfdMessageOutput(
            service,
            messageQueries: service,
            reactions: service,
          ),
          context = BdfdContext();
      final location = BdfdLocation('x', 0);
      output.deferPin();
      output.deferReactions(['🔥']);
      await output.flush(context, location);
      expect(service.events, isEmpty);
      output.append('Text');
      await output.flush(context, location);
      expect(service.events, ['send:Text']);
    },
  );
  test('guard replacement discards pending pin and reactions', () async {
    final service = _Services();
    await engine(
      service,
    ).execute(r'$pinMessage$addReactions[🔥]Secret$onlyIf[false;Denied]');
    expect(service.events, ['send:Denied']);
  });
  test(
    'validation includes message, reaction and member query registrations',
    () {
      expect(
        BdfdEngine.validation().supportedFunctions,
        containsAll([
          'getmessage',
          'pinmessage',
          'getembeddata',
          'addreactions',
          'memberscount',
        ]),
      );
    },
  );
}
