import 'package:bot_creator_shared/engine/bdfd/engine.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';
import 'helpers/variables_test_helpers.dart';

class _Messages implements BotMessageService {
  final sent = <BotMessageRequest>[];
  bool failNext = false;
  Duration delay = Duration.zero;
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    budget.check();
    sent.add(request);
    if (delay != Duration.zero) await Future<void>.delayed(delay);
    if (failNext) {
      failNext = false;
      throw StateError('Discord refused');
    }
    return BotMessageResult(messageId: '${sent.length}', acknowledged: true);
  }
}

BdfdEngine _engine(BotMessageService service) =>
    BdfdEngine(store: MemoryBotDataStore(), botId: 'bot', messages: service);

class _ChannelGateway implements NyxxGateway {
  final manager = _Channels();
  @override
  ChannelManager get channels => manager;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channels implements ChannelManager {
  final channel = _Channel();
  final requested = <Snowflake>[];
  @override
  Future<Channel> get(Snowflake id) async {
    requested.add(id);
    return channel;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channel implements TextChannel {
  final sentMessages = <MessageBuilder>[];
  @override
  Future<Message> sendMessage(MessageBuilder builder) async {
    sentMessages.add(builder);
    return _Message();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Interaction implements MessageResponse {
  final responses = <MessageBuilder>[];
  final followups = <MessageBuilder>[];
  final updates = <MessageUpdateBuilder>[];
  @override
  Snowflake? get guildId => Snowflake(10);
  @override
  Snowflake? get channelId => Snowflake(20);
  @override
  PartialChannel? get channel => null;
  @override
  Future<Message> updateOriginalResponse(MessageUpdateBuilder builder) async {
    updates.add(builder);
    return _Message();
  }

  bool isAcknowledged = false;
  @override
  Future<InteractionCallbackResponse?> respond(
    MessageBuilder builder, {
    bool? isEphemeral,
    bool? withResponse,
  }) async {
    responses.add(builder);
    isAcknowledged = true;
    return null;
  }

  @override
  Future<Message> fetchOriginalResponse() async => _Message();
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
  test(
    'unknown bodies and evaluated arguments stay opaque in responses',
    () async {
      final messages = _Messages();
      final engine = _engine(messages);
      final program = engine.prepare(
        r'$title[Score $sum[2;3]]Hello $unknown[$sendMessage[never]]',
      );
      expect(messages.sent, isEmpty);
      await engine.executeProgram(program);
      expect(messages.sent, hasLength(1));
      expect(
        messages.sent.single.payload['content'],
        r'Hello $unknown[$sendMessage[never]]',
      );
      expect(messages.sent.single.payload['embeds'], [
        {'title': 'Score 5'},
      ]);
    },
  );
  test('embeds collect fields from loops and selected branches', () async {
    final messages = _Messages();
    await _engine(messages).execute(
      r'$title[Items]$for[3]$addField[Item $i;$sum[$i;1];yes]$endfor$if[false]$description[never]$else$description[done]$endif',
    );
    expect(messages.sent, hasLength(1));
    final embed =
        (messages.sent.single.payload['embeds'] as List).single as Map;
    expect(embed['description'], 'done');
    expect(embed['fields'], [
      {'name': 'Item 0', 'value': '1', 'inline': true},
      {'name': 'Item 1', 'value': '2', 'inline': true},
      {'name': 'Item 2', 'value': '3', 'inline': true},
    ]);
  });
  test(
    'sendMessage sends independent channel messages and preserves main embed',
    () async {
      final messages = _Messages();
      final context = BdfdContext();
      await _engine(messages).execute(
        r'$nomention$ephemeral$title[main]$sendMessage[one]$sendMessage[two]final',
        context: context,
      );
      expect(messages.sent.map((m) => m.payload['content']), [
        'one',
        'two',
        'final',
      ]);
      expect(
        messages.sent.take(2).map((m) => m.destination),
        everyElement(BotMessageDestination.channel),
      );
      expect(messages.sent.first.payload.containsKey('embeds'), false);
      expect(messages.sent.last.payload['embeds'], [
        {'title': 'main'},
      ]);
      expect(messages.sent.first.payload['allowedMentions'], {'parse': []});
      expect(messages.sent.last.payload['ephemeral'], true);
      expect(context.results['last.response.id'], '3');
      expect(
        () => (messages.sent.last.payload['embeds'] as List).add({}),
        throwsUnsupportedError,
      );
    },
  );
  test(
    'eval flushes parent and child once and shares response state',
    () async {
      final messages = _Messages();
      final context = BdfdContext(
        temporaryVariables: {'code': r'child $sendMessage[!]'},
      );
      await _engine(
        messages,
      ).execute(r'parent $eval[$var[code]]tail', context: context);
      expect(messages.sent.map((m) => m.payload['content']), [
        'parent ',
        '!',
        'child ',
        'tail',
      ]);
      expect(context.response.messageId, '4');
    },
  );
  test('guard replaces draft and stop sends pending response', () async {
    final messages = _Messages();
    final engine = _engine(messages);
    await engine.execute(
      r'$title[private]secret$onlyIf[false;denied]unreachable',
    );
    expect(messages.sent.single.payload['content'], 'denied');
    expect(messages.sent.single.payload['embeds'], isEmpty);
    await engine.execute(r'visible$stop unreachable');
    expect(messages.sent.last.payload['content'], 'visible');
  });
  test('channel sends and switching preserve message order', () async {
    final messages = _Messages();
    await _engine(messages).execute(
      r'first$channelSendMessage[20;other;123]middle$useChannel[30]last',
    );
    expect(messages.sent.map((m) => m.payload['content']), [
      'first',
      'other',
      'middle',
      'last',
    ]);
    expect(messages.sent[1].destination, BotMessageDestination.channel);
    expect(messages.sent[1].payload['messageId'], '123');
    expect(messages.sent.last.payload['channelId'], '30');
  });
  test(
    'failed send is not replayed by catch and preserves source location',
    () async {
      final messages = _Messages()..failNext = true;
      await _engine(
        messages,
      ).execute(r'$try$sendMessage[once]$catch recovered$endtry');
      expect(messages.sent.map((m) => m.payload['content']), [
        'once',
        ' recovered',
      ]);
      messages.failNext = true;
      await expectLater(
        _engine(messages).execute(r'$sendMessage[bad]'),
        throwsA(
          isA<BdfdNativeError>().having(
            (e) => e.location.functionName,
            'function',
            r'$sendMessage',
          ),
        ),
      );
    },
  );
  test('preflight and final errors leave pending responses unsent', () async {
    final messages = _Messages();
    final engine = _engine(messages);
    await expectLater(
      engine.execute(r'pending$ban[123]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(messages.sent, isEmpty);
    final context = BdfdContext();
    await expectLater(
      engine.execute(r'pending$sum[invalid]', context: context),
      throwsA(isA<BdfdNativeError>()),
    );
    await engine.execute('fresh', context: context);
    expect(messages.sent.single.payload['content'], 'fresh');
  });
  test('deadline prevents late result publication and second send', () async {
    final messages = _Messages()..delay = const Duration(milliseconds: 50);
    final context = BdfdContext(
      budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
    );
    await expectLater(
      _engine(
        messages,
      ).execute(r'$sendMessage[first]$sendMessage[second]', context: context),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    await Future<void>.delayed(const Duration(milliseconds: 70));
    expect(messages.sent, hasLength(1));
    expect(context.response.messageId, isNull);
  });
  test(
    'Discord adapter shares acknowledgement and preserves returned data',
    () async {
      final interaction = _Interaction();
      final engine = _engine(
        DiscordBotMessageService(botId: 'bot', interaction: interaction),
      );
      final context = BdfdContext(
        temporaryVariables: {'value': r'$sendMessage[not code]'},
      );
      await engine.execute(r'$title[Report]$var[value]', context: context);
      expect(interaction.responses.single.content, r'$sendMessage[not code]');
      expect(interaction.responses.single.embeds!.single.title, 'Report');
      expect(context.response.messageId, '123');
      expect(context.response.acknowledged, true);
      await engine.execute(r'$ephemeral second', context: context);
      expect(interaction.responses, hasLength(1));
      expect(interaction.followups.single.content, ' second');
    },
  );
  test(
    'prefix reply and explicit reply use channel transport and message references',
    () async {
      final gateway = _ChannelGateway();
      final engine = _engine(
        DiscordBotMessageService(
          botId: 'bot',
          client: gateway,
          channelId: Snowflake(20),
          messageId: Snowflake(40),
        ),
      );
      await engine.execute(r'$reply$title[Prefix]hello');
      await engine.execute(r'$reply[30;50]other');
      expect(gateway.manager.requested, [Snowflake(20), Snowflake(30)]);
      expect(gateway.manager.channel.sentMessages.map((m) => m.content), [
        'hello',
        'other',
      ]);
      expect(
        gateway.manager.channel.sentMessages.first.referencedMessage!.messageId,
        Snowflake(40),
      );
      expect(
        gateway.manager.channel.sentMessages.last.referencedMessage!.messageId,
        Snowflake(50),
      );
    },
  );
  test('empty final drafts do not leak flags into a reused context', () async {
    final messages = _Messages();
    final engine = _engine(messages);
    final context = BdfdContext();
    await engine.execute(r'$ephemeral', context: context);
    await engine.execute('fresh', context: context);
    expect(messages.sent.single.payload['ephemeral'], false);
  });
  test(
    'sendMessage returns the ID only when requested and can store it',
    () async {
      final messages = _Messages();
      final engine = _engine(messages);
      final context = BdfdContext();
      expect(
        await engine.execute(
          r'$var[id;$sendMessage[first;yes]]$var[id]',
          context: context,
        ),
        '1',
      );
      expect(messages.sent.map((m) => m.payload['content']), ['first', '1']);
      expect(context.temporaryVariables['id'], '1');
      await engine.execute(r'$sendMessage[second]', context: context);
      expect(messages.sent.map((m) => m.payload['content']), [
        'first',
        '1',
        'second',
      ]);
    },
  );
  test(
    'sendMessage rejects empty content and invalid return ID flag before sending',
    () async {
      final messages = _Messages();
      final engine = _engine(messages);
      for (final source in [
        r'$sendMessage[;yes]',
        r'$sendMessage[test;maybe]',
      ]) {
        await expectLater(
          engine.execute(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
      expect(messages.sent, isEmpty);
    },
  );
  test(
    'sendMessage creates new channel messages even for slash interactions',
    () async {
      final gateway = _ChannelGateway();
      final interaction = _Interaction();
      final engine = _engine(
        DiscordBotMessageService(
          botId: 'bot',
          client: gateway,
          interaction: interaction,
        ),
      );
      await engine.execute(r'$sendMessage[one]$sendMessage[two]');
      expect(gateway.manager.channel.sentMessages.map((m) => m.content), [
        'one',
        'two',
      ]);
      expect(interaction.responses, isEmpty);
      expect(interaction.followups, isEmpty);
      await engine.execute(r'$useChannel[30]$sendMessage[redirected]');
      expect(gateway.manager.requested.last, Snowflake(30));
    },
  );
  test('native text and embeds are sent with the documented payload', () async {
    for (final source in [
      r'$title[Report]$description[Details]$footer[By bot]hello',
      r'$title[Other]$description[Second]content',
    ]) {
      final messages = _Messages();
      await _engine(messages).execute(source);
      final payload = messages.sent.single.payload;
      expect(
        payload['content'],
        source.endsWith('hello') ? 'hello' : 'content',
      );
      final embed = (payload['embeds'] as List).single as Map;
      expect(embed['title'], source.contains('Report') ? 'Report' : 'Other');
      expect(
        embed['description'],
        source.contains('Details') ? 'Details' : 'Second',
      );
      expect(
        (embed['footer'] as Map?)?['text'],
        source.contains('footer') ? 'By bot' : null,
      );
    }
  });
}
