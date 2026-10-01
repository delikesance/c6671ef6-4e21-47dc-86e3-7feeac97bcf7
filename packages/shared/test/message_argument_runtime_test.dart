import 'package:bot_creator_shared/events/event_contexts.dart';
import 'package:bot_creator_shared/utils/message_runtime.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Gateway implements Gateway {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No gateway access');
}

class _Author implements MessageAuthor {
  @override
  Snowflake get id => Snowflake(20);
  @override
  String get username => 'Author';
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected author access');
}

class _MentionUser implements User {
  @override
  Snowflake get id => Snowflake(111);
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected user access');
}

class _Channel implements PartialTextChannel {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('No channel access');
}

class _Message implements Message {
  _Message(this.content);
  @override
  final String content;
  @override
  Snowflake get id => Snowflake(50);
  @override
  Snowflake get channelId => Snowflake(30);
  @override
  PartialTextChannel get channel => _Channel();
  @override
  MessageAuthor get author => _Author();
  @override
  List<User> get mentions => [_MentionUser()];
  @override
  List<Snowflake> get roleMentionIds => [Snowflake(333)];
  @override
  List<ChannelMention> get channelMentions => [];
  @override
  DateTime get timestamp => DateTime.utc(2026);
  @override
  DateTime? get editedTimestamp => null;
  @override
  MessageType get type => MessageType.normal;
  @override
  bool get isPinned => false;
  @override
  bool get mentionsEveryone => false;
  @override
  List<Attachment> get attachments => [];
  @override
  List<Embed> get embeds => [];
  @override
  Message? get referencedMessage => null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected message access');
}

void main() {
  test(
    'prefix argument fields exclude the command and retain all arguments',
    () {
      final args = List.generate(13, (i) => 'word${i + 1}');
      final variables = buildCommandArgumentRuntimeVariables(args);
      expect(variables['args.count'], '13');
      expect(variables['message.argCount'], '13');
      expect(variables['message.word.count'], '13');
      expect(variables['message.content[12]'], 'word13');
      expect(variables['args.13'], 'word13');
      expect(variables['13'], 'word13');
      expect(variables['message.args.last'], 'word13');
      expect(buildCommandArgumentRuntimeVariables([])['args.count'], '0');
      expect(buildCommandArgumentRuntimeVariables([])['message.args.last'], '');
    },
  );
  test(
    'real message extraction distinguishes channel, role and user mentions',
    () async {
      final context = buildMessageCreateEventContext(
        MessageCreateEvent(
          gateway: _Gateway(),
          guildId: Snowflake(10),
          member: null,
          mentions: [],
          message: _Message('<#555> <@111> <#666> <#555>'),
        ),
      );
      expect(context.variables['message.channelMentions'], '555,666');
      final result = await testCommandInSandbox({
        'script': r'$mentionedChannels[2]|$mentions|$mentionedRoles',
        'variables': context.variables,
      });
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], '666|111|333');
    },
  );
  test('empty event messages have no words', () {
    final context = buildMessageCreateEventContext(
      MessageCreateEvent(
        gateway: _Gateway(),
        guildId: null,
        member: null,
        mentions: [],
        message: _Message('  '),
      ),
    );
    expect(context.variables['message.word.count'], '0');
    expect(context.variables.containsKey('message.content[0]'), false);
  });
}
