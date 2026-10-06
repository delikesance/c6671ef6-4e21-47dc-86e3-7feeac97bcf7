import 'package:bot_creator_shared/engine/bdfd/message_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/timing_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_cooldown_service.dart';
import 'package:bot_creator_shared/services/bot_message_query_service.dart';
import 'package:bot_creator_shared/services/bot_message_service.dart';
import 'package:bot_creator_shared/services/bot_timing_service.dart';
import 'package:test/test.dart';

class _Messages implements BotMessageService, BotMessageQueryService {
  final sent = <BotMessageRequest>[];
  final mutations = <MessageMutation>[];
  bool failSend = false, failMutation = false;
  String? channel = '99';
  @override
  Future<BotMessageResult> send(
    BotMessageRequest request, {
    required CommandExecutionBudget budget,
    required Map<String, String> variables,
  }) async {
    sent.add(request);
    if (failSend) throw StateError('send failed');
    return BotMessageResult(
      messageId: '${100 + sent.length}',
      channelId: channel,
    );
  }

  @override
  Future<void> mutateMessage(
    MessageMutation request, {
    required CommandExecutionBudget budget,
  }) async {
    request.validate();
    mutations.add(request);
    if (failMutation) throw StateError('edit failed');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Delays implements BotDelayService {
  final recorded = <Duration>[];
  @override
  Future<void> delay(
    Duration duration, {
    required CommandExecutionBudget budget,
  }) async {
    budget.check();
    recorded.add(duration);
  }
}

void main() {
  late _Messages messages;
  late _Delays delays;
  late SandboxBotTimingService timing;
  late BdfdMessageOutput output;
  late BdfdRuntime runtime;
  BdfdContext context() => BdfdContext(
    output: output,
    variables: {'channel.id': '30', 'message.id': '40'},
  );
  Future<String> run(String source, {BdfdContext? ctx}) =>
      runtime.execute(source, context: ctx ?? context());
  setUp(() {
    messages = _Messages();
    delays = _Delays();
    timing = SandboxBotTimingService(messages);
    output = BdfdMessageOutput(
      messages,
      messageQueries: messages,
      timing: timing,
    );
    runtime = BdfdRuntime(
      functions: {
        ...bdfdMessageFunctions(),
        ...bdfdTimingFunctions(delays: delays, messages: messages),
        'deny': BdfdNativeFunction(
          minArguments: 0,
          maxArguments: 0,
          handler: (call) {
            call.stop('Denied');
          },
        ),
      },
    );
  });
  test(
    'deleteIn schedules actual response ID with same budget, sandbox applies on drain',
    () async {
      final ctx = context();
      expect(await run(r'$deleteIn[3s]Main', ctx: ctx), 'Main');
      expect(messages.sent.single.payload['content'], 'Main');
      expect(messages.mutations, isEmpty);
      expect(timing.pending.single.channelId, '99');
      expect(timing.pending.single.messageId, '101');
      expect(timing.pending.single.request.delay, const Duration(seconds: 3));
      expect(identical(timing.pending.single.budget, ctx.budget), true);
      await timing.drain();
      expect(messages.mutations.single.kind, MessageMutationKind.delete);
      expect(messages.mutations.single.channelId, '99');
      expect(messages.mutations.single.messageId, '101');
    },
  );
  test(
    'editIn freezes evaluated content and never reparses mutation text',
    () async {
      await run(r'$editIn[5s;$unknown[]]Old');
      await timing.drain();
      expect(messages.mutations.single.edit!.content, r'$unknown[]');
      expect(messages.mutations.single.edit!.replaceEmbed, false);
    },
  );
  test(
    'editEmbedIn handles optional empty fields and hex/integer color',
    () async {
      await run(r'$editEmbedIn[5s;New;Description;Footer;#abcdef]Old');
      await timing.drain();
      final edit = messages.mutations.single.edit!;
      expect(edit.title, 'New');
      expect(edit.description, 'Description');
      expect(edit.footer, 'Footer');
      expect(edit.color, 0xabcdef);
      expect(edit.content, '');
      expect(edit.replaceEmbed, true);
      await run(r'$editEmbedIn[1s;;Description;;255]Old');
      await timing.drain();
      expect(messages.mutations.last.edit!.color, 255);
      await run(r'$editEmbedIn[1s;Title]Old');
      await timing.drain();
      expect(messages.mutations.last.edit!.title, 'Title');
    },
  );
  test('standalone sendMessage does not consume deferred mutations', () async {
    await run(r'$deleteIn[3s]$sendMessage[Side]Main');
    expect(messages.sent.map((request) => request.payload['content']), [
      'Side',
      'Main',
    ]);
    expect(timing.pending.single.messageId, '102');
  });
  test('empty response discards pending mutations without send', () async {
    await run(r'$deleteIn[3s]');
    expect(messages.sent, isEmpty);
    expect(timing.pending, isEmpty);
    await run('Later');
    expect(messages.sent, hasLength(1));
    expect(timing.pending, isEmpty);
  });
  test('denial discard removes timings from replacement response', () async {
    await run(r'$deleteIn[3s]Private$deny');
    expect(messages.sent.single.payload['content'], 'Denied');
    expect(timing.pending, isEmpty);
  });
  test('send failure detaches timings and cannot replay jobs', () async {
    messages.failSend = true;
    await expectLater(
      run(r'$deleteIn[3s]First'),
      throwsA(isA<BdfdNativeError>()),
    );
    messages.failSend = false;
    await run('Second');
    expect(messages.sent, hasLength(2));
    expect(timing.pending, isEmpty);
  });
  test(
    'missing actual response channel errors instead of command-channel fallback',
    () async {
      messages.channel = null;
      await expectLater(
        run(r'$deleteIn[3s]Main'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(timing.pending, isEmpty);
      expect(messages.sent, hasLength(1));
    },
  );
  test('multiple mutations retain encounter order and response IDs', () async {
    await run(r'$editIn[2s;New]$deleteIn[3s]Old');
    expect(timing.pending.map((job) => job.request.delay.inSeconds), [2, 3]);
    await timing.drain();
    expect(messages.mutations.map((mutation) => mutation.kind), [
      MessageMutationKind.edit,
      MessageMutationKind.delete,
    ]);
    expect(
      messages.mutations.every((mutation) => mutation.messageId == '101'),
      true,
    );
  });
  test('replyIn delays execution with injectable sandbox clock', () async {
    expect(await run(r'$replyIn[3s]Main'), 'Main');
    expect(delays.recorded, [const Duration(seconds: 3)]);
    expect(messages.sent, hasLength(1));
  });
  test('deletecommand targets invoking message and is immediate', () async {
    await run(r'$deletecommand$deleteIn[3s]Main');
    expect(messages.mutations.single.channelId, '30');
    expect(messages.mutations.single.messageId, '40');
    expect(messages.mutations.single.kind, MessageMutationKind.delete);
    expect(timing.pending.single.messageId, '101');
  });
  test('deletecommand failures are catchable and never retried', () async {
    messages.failMutation = true;
    expect(
      await run(
        r'$try$deletecommand'
        '\nnever'
        r'$catch'
        '\nfallback'
        r'$endtry',
      ),
      '\nfallback',
    );
    expect(messages.mutations, hasLength(1));
  });
  test('invalid duration arity fields reject before any scheduling', () async {
    for (final source in [
      r'$deleteIn',
      r'$deleteIn[0]',
      r'$deleteIn[41m]',
      r'$deleteIn[-1s]',
      r'$editIn[1s;]',
      r'$editIn[1s;x;y]',
      r'$editEmbedIn[1s;;;;]',
      r'$editEmbedIn[1s;Title;;;bad]',
      r'$editEmbedIn[1s;Title;;;16777216]',
      r'$replyIn[0.5s]',
      r'$replyIn[41m]',
      r'$deletecommand[x]',
    ]) {
      await expectLater(
        run(source),
        throwsA(isA<BdfdNativeError>()),
        reason: source,
      );
    }
    expect(timing.pending, isEmpty);
    expect(delays.recorded, isEmpty);
    expect(messages.sent, isEmpty);
  });
  test('unknown wrappers keep effects opaque', () async {
    const code = r'$unknown[$deleteIn[3s]$deletecommand]';
    expect(await run(code), code);
    expect(timing.pending, isEmpty);
    expect(messages.mutations, isEmpty);
  });
  test(
    'live scheduler applies timed mutation and captures late failures',
    () async {
      final scheduler = RuntimeBotTimingService(messages);
      await scheduler.schedule(
        BotTimedMessageMutation(
          delay: const Duration(milliseconds: 5),
          delete: true,
        ),
        channelId: '30',
        messageId: '40',
        budget: CommandExecutionBudget(),
      );
      await scheduler.drain();
      expect(messages.mutations, hasLength(1));
      messages.failMutation = true;
      await scheduler.schedule(
        BotTimedMessageMutation(
          delay: const Duration(milliseconds: 5),
          delete: true,
        ),
        channelId: '30',
        messageId: '40',
        budget: CommandExecutionBudget(),
      );
      await scheduler.drain();
      expect(scheduler.failures.single.error, isA<StateError>());
      expect(messages.mutations, hasLength(2));
    },
  );
  test(
    'live scheduler shared deadline prevents later Discord mutation',
    () async {
      final scheduler = RuntimeBotTimingService(messages);
      final budget = CommandExecutionBudget(
        limit: const Duration(milliseconds: 10),
      );
      await scheduler.schedule(
        BotTimedMessageMutation(
          delay: const Duration(milliseconds: 30),
          delete: true,
        ),
        channelId: '30',
        messageId: '40',
        budget: budget,
      );
      await scheduler.drain();
      expect(messages.mutations, isEmpty);
      expect(scheduler.failures.single.error, isA<CommandExecutionTimeout>());
    },
  );
  test('runtime delay times out before following effects', () async {
    final rt = BdfdRuntime(
      functions: bdfdTimingFunctions(
        delays: const RuntimeBotDelayService(),
        messages: messages,
      ),
    );
    final ctx = BdfdContext(
      variables: context().variables,
      budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
    );
    await expectLater(
      rt.execute(r'$replyIn[1s]$deletecommand', context: ctx),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(messages.mutations, isEmpty);
  });
}
