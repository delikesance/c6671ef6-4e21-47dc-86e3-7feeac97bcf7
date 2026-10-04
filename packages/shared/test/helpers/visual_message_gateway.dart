import 'package:bot_creator_shared/actions/execution_policy.dart';
import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/bot/bot_data_store.dart';
import 'package:bot_creator_shared/engine/bdfd/program.dart' show BdfdLocation;
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'variables_test_helpers.dart';
import 'visual_discord_gateway.dart';
import 'visual_parity_harness.dart' show SpyTranslator;
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';

// Recording Discord for the parity tests of the messaging / interaction blocks
// (wave 3): a text channel that records sends, edits, pins, reactions and
// deletions, direct messages, and an interaction that records its responses.
// Guild lookups and permissions come from the shared VisualGateway fixtures.

/// Fixed for the whole run so both paths read the same value (and recent
/// enough for the bulk-delete path).
final DateTime _stamp = DateTime.now().toUtc();

class FakeAuthor implements User {
  FakeAuthor(int id, {this.isBot = false, this.username = 'author'})
    : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final bool isBot;
  @override
  final String username;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMessage implements Message {
  FakeMessage(
    this.gateway,
    this.channelId,
    int id, {
    this.content = '',
    FakeAuthor? author,
    this.isPinned = false,
    DateTime? timestamp,
  }) : id = Snowflake(id),
       author = author ?? FakeAuthor(20),
       timestamp = timestamp ?? _stamp;
  final MessageGateway gateway;
  @override
  final Snowflake channelId;
  @override
  final Snowflake id;
  @override
  final String content;
  @override
  final MessageAuthor author;
  @override
  final bool isPinned;
  @override
  final DateTime timestamp;
  @override
  List<Component>? get components => null;

  Map<String, Object?> _ref(String op, [Map<String, Object?>? extra]) => {
    'channel': '$channelId',
    'message': '$id',
    ...?extra,
  };

  @override
  Future<void> pin({String? auditLogReason}) async =>
      gateway.record('pin', _ref('pin', {'reason': auditLogReason}));
  @override
  Future<void> unpin({String? auditLogReason}) async =>
      gateway.record('unpin', _ref('unpin', {'reason': auditLogReason}));
  @override
  Future<void> delete({String? auditLogReason}) async =>
      gateway.record('delete', _ref('delete'));
  @override
  Future<void> react(ReactionBuilder emoji) async => gateway.record(
    'react',
    _ref('react', {'emoji': '${emoji.name}:${emoji.id}'}),
  );
  @override
  Future<void> deleteReaction(
    ReactionBuilder emoji, {
    Snowflake? userId,
  }) async => gateway.record(
    'deleteReaction',
    _ref('deleteReaction', {
      'emoji': '${emoji.name}:${emoji.id}',
      'user': '$userId',
    }),
  );
  @override
  Future<void> deleteOwnReaction(ReactionBuilder emoji) async => gateway.record(
    'deleteOwnReaction',
    _ref('deleteOwnReaction', {'emoji': '${emoji.name}:${emoji.id}'}),
  );
  @override
  Future<void> deleteAllReactions() async =>
      gateway.record('deleteAllReactions', _ref('deleteAllReactions'));
  @override
  Future<void> crosspost() async =>
      gateway.record('crosspost', _ref('crosspost'));
  @override
  Future<Message> edit(MessageUpdateBuilder builder) async {
    gateway.record('edit', _ref('edit', {'payload': builder.build()}));
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeMessages implements MessageManager {
  FakeMessages(this.channel);
  final FakeTextChannel channel;
  MessageGateway get gateway => channel.gateway;
  @override
  Future<Message> fetch(Snowflake id) async {
    final message = channel.stored[id];
    if (message == null) throw StateError('Unknown message $id');
    return message;
  }

  @override
  Future<Message> get(Snowflake id) => fetch(id);
  @override
  PartialMessage operator [](Snowflake id) =>
      channel.stored[id] ?? FakeMessage(gateway, channel.id, id.value);
  @override
  Future<List<Message>> fetchMany({
    Snowflake? around,
    Snowflake? before,
    Snowflake? after,
    int? limit,
  }) async {
    final all = channel.stored.values.toList()
      ..sort((a, b) => b.id.value.compareTo(a.id.value));
    return [
      for (final message in all)
        if (before == null || message.id.value < before.value) message,
    ].take(limit ?? 50).toList();
  }

  @override
  Future<void> bulkDelete(
    Iterable<Snowflake> ids, {
    String? auditLogReason,
  }) async => gateway.record('bulkDelete', {
    'channel': '${channel.id}',
    'ids': [for (final id in ids) '$id'],
  });
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTextChannel implements TextChannel {
  FakeTextChannel(this.gateway, int id) : id = Snowflake(id);
  final MessageGateway gateway;
  @override
  final Snowflake id;
  final stored = <Snowflake, FakeMessage>{};
  @override
  late final MessageManager messages = FakeMessages(this);

  @override
  Future<Message> sendMessage(MessageBuilder builder) async {
    final id = gateway.nextMessageId++;
    gateway.record('send', {
      'channel': '${this.id}',
      'payload': builder.build(),
      'attachments': [
        for (final a in builder.attachments ?? const <AttachmentBuilder>[])
          '${a.fileName}:${a.data.length}',
      ],
    });
    return FakeMessage(gateway, this.id, id);
  }

  @override
  Future<void> triggerTyping() async =>
      gateway.record('typing', {'channel': '$id'});
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MessageUsers extends VisualUsers {
  MessageUsers(MessageGateway super.gateway);
  @override
  Future<DmChannel> createDm(Snowflake userId) async {
    final gateway = this.gateway as MessageGateway;
    gateway.record('createDm', {'user': '$userId'});
    final channel = gateway.dm(userId);
    return channel as DmChannel;
  }
}

class FakeDm extends FakeTextChannel implements DmChannel {
  FakeDm(super.gateway, super.id);
}

class MessageChannels extends VisualChannels {
  MessageChannels(MessageGateway super.gateway);
  @override
  Future<Channel> fetch(Snowflake id) async {
    final channel = (gateway as MessageGateway).textChannels[id];
    if (channel != null) return channel;
    return super.fetch(id);
  }

  @override
  Future<Channel> get(Snowflake id) => fetch(id);
}

class MessageGateway extends VisualGateway {
  MessageGateway({super.data}) {
    for (final id in [30, 35]) {
      textChannels[Snowflake(id)] = FakeTextChannel(this, id);
    }
    final chat = textChannels[Snowflake(30)]!;
    for (final id in [40, 41, 42, 43]) {
      chat.stored[Snowflake(id)] = FakeMessage(
        this,
        chat.id,
        id,
        content: 'message $id',
        author: FakeAuthor(id == 41 ? 500 : 20, isBot: id == 41),
        isPinned: id == 42,
      );
    }
    _channels = MessageChannels(this);
    _users = MessageUsers(this);
  }
  final textChannels = <Snowflake, FakeTextChannel>{};
  final dms = <Snowflake, FakeDm>{};
  int nextMessageId = 9000;
  late final MessageChannels _channels;
  late final MessageUsers _users;

  FakeDm dm(Snowflake user) => dms.putIfAbsent(user, () {
    final channel = FakeDm(this, 7000 + user.value % 1000);
    textChannels[channel.id] = channel;
    return channel;
  });

  @override
  ChannelManager get channels => _channels;
  @override
  UserManager get users => _users;
}

/// Interaction answering through the nyxx response API; records each call.
class FakeInteraction implements MessageResponse {
  FakeInteraction({this.acknowledged = false});
  final calls = <Map<String, Object?>>[];
  bool acknowledged;
  int nextId = 8000;
  bool failAcknowledge = false;

  @override
  bool get isAcknowledged => acknowledged;
  @override
  Snowflake? get guildId => Snowflake(10);
  @override
  Snowflake? get channelId => Snowflake(30);
  @override
  PartialChannel? get channel => null;
  @override
  Message? get message => null;

  @override
  Future<InteractionCallbackResponse?> acknowledge({
    bool? isEphemeral,
    bool? withResponse,
  }) async {
    calls.add({'op': 'acknowledge', 'ephemeral': isEphemeral});
    if (failAcknowledge) throw StateError('already acknowledged');
    acknowledged = true;
    return null;
  }

  @override
  Future<InteractionCallbackResponse?> respond(
    MessageBuilder builder, {
    bool? isEphemeral,
    bool? withResponse,
  }) async {
    calls.add({'op': 'respond', 'payload': builder.build()});
    acknowledged = true;
    return null;
  }

  @override
  Future<Message> fetchOriginalResponse() async {
    calls.add({'op': 'fetchOriginal'});
    return FakeMessage(MessageGateway(), Snowflake(30), nextId++);
  }

  @override
  Future<Message> updateOriginalResponse(MessageUpdateBuilder builder) async {
    calls.add({'op': 'updateOriginal', 'payload': builder.build()});
    return FakeMessage(MessageGateway(), Snowflake(30), nextId++);
  }

  @override
  Future<Message> createFollowup(
    MessageBuilder builder, {
    bool? isEphemeral,
  }) async {
    calls.add({
      'op': 'followup',
      'ephemeral': isEphemeral,
      'payload': builder.build(),
    });
    return FakeMessage(MessageGateway(), Snowflake(30), nextId++);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Effects compared by the tests: every recorded write and interaction call.
class MessageEffects {
  MessageEffects(this.writes, this.interaction);
  final List<Map<String, Object?>> writes;
  final List<Map<String, Object?>> interaction;
  @override
  String toString() => 'writes=$writes interaction=$interaction';
  @override
  bool operator ==(Object other) =>
      other is MessageEffects &&
      '$writes' == '${other.writes}' &&
      '$interaction' == '${other.interaction}';
  @override
  int get hashCode => Object.hash('$writes', '$interaction');
}

class MessageOutcome {
  MessageOutcome(
    this.gateway,
    this.interaction,
    this.results,
    this.variables,
    this.error,
    this.native,
    this.context,
  );
  final MessageGateway gateway;
  final FakeInteraction? interaction;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;
  final BdfdContext context;
  List<Map<String, Object?>> get writes => gateway.writes;
  String? get errorText =>
      error == null ? null : '${error.runtimeType}: $error';
}

Future<MessageOutcome> _run(
  List<Action> actions, {
  required bool native,
  required MessageGateway Function() makeGateway,
  FakeInteraction Function()? makeInteraction,
  void Function(MessageGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  ActionExecutionPolicy? policy,
  Snowflake? fallbackChannelId,
  BdfdContext Function(Map<String, String> variables)? makeContext,
}) async {
  final gateway = makeGateway();
  setup?.call(gateway);
  final interaction = makeInteraction?.call();
  final values = <String, String>{
    'guild.id': '10',
    'bot.id': '500',
    ...?variables,
  };
  final context = makeContext?.call(values) ?? BdfdContext(variables: values);
  final spy = SpyTranslator();
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      gateway,
      interaction,
      actions: actions,
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: values,
      fallbackGuildId: guild ? Snowflake(10) : null,
      fallbackChannelId: fallbackChannelId,
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      executionPolicy: policy,
      throwOnError: throwOnError,
      bdfdContext: context,
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return MessageOutcome(
    gateway,
    interaction,
    results,
    values,
    error,
    spy.native,
    context,
  );
}

/// Both paths over the same simulated Discord (and interaction); everything
/// observable is compared. Returns the native outcome.
Future<MessageOutcome> messageParity(
  List<Action> actions, {
  int permissions = 8,
  void Function(MessageGateway gateway)? setup,
  FakeInteraction Function()? makeInteraction,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  Snowflake? fallbackChannelId,
  bool expectNative = true,
  int? nativePrograms,
}) async {
  Future<MessageOutcome> run(bool native) => _run(
    actions.map((a) => Action.fromJson(a.toJson())).toList(),
    native: native,
    makeGateway: () =>
        MessageGateway(data: visualFixtures(permissions: permissions)),
    makeInteraction: makeInteraction,
    setup: setup,
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    fallbackChannelId: fallbackChannelId,
  );
  final historical = await run(false);
  final native = await run(true);
  expect(historical.native, 0);
  if (nativePrograms != null) {
    expect(native.native, nativePrograms);
  } else if (expectNative) {
    expect(native.native, greaterThan(0), reason: 'must run natively');
  } else {
    expect(native.native, 0, reason: 'must stay historical');
  }
  expect(native.writes, historical.writes, reason: 'effects');
  expect(
    native.interaction?.calls,
    historical.interaction?.calls,
    reason: 'interaction calls',
  );
  expect(
    [native.context.response.acknowledged, native.context.response.originalResponseCompleted],
    [historical.context.response.acknowledged, historical.context.response.originalResponseCompleted],
    reason: 'host response state',
  );
  expect(native.results, historical.results, reason: 'results');
  expect(native.variables, historical.variables, reason: 'variables');
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}

/// A BDFD output that counts what the host script's draft receives.
class DraftSpy implements BdfdOutput {
  final appended = <String>[];
  int flushes = 0;
  int discards = 0;
  @override
  void append(String text) => appended.add(text);
  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async =>
      flushes++;
  @override
  void discard() => discards++;
}

/// Runs [actions] natively inside a host script context holding [draft].
Future<MessageOutcome> runWithDraft(
  List<Action> actions,
  DraftSpy draft, {
  FakeInteraction Function()? makeInteraction,
  Map<String, String>? variables,
}) => _run(
  actions.map((a) => Action.fromJson(a.toJson())).toList(),
  native: true,
  makeGateway: () => MessageGateway(data: visualFixtures()),
  makeInteraction: makeInteraction,
  variables: variables,
  makeContext: (values) => BdfdContext(variables: values)..output = draft,
);
