import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/bdfd/message_query_functions.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_message_query_service.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

class _Native implements BotMessageQueryService {
  @override
  Future<BotMessageChannelSnapshot> messageChannel(
    String channelId, {
    required CommandExecutionBudget budget,
  }) async {
    reads.add('channel:$channelId');
    return BotMessageChannelSnapshot(
      lastMessageId: '40',
      lastPinTimestamp: DateTime.fromMillisecondsSinceEpoch(
        1753454520000,
        isUtc: true,
      ),
    );
  }

  final reads = <String>[], writes = <MessageMutation>[];
  DateTime? edited;
  String? replied;
  @override
  Future<BotMessageSnapshot> message({
    required String channelId,
    required String messageId,
    required CommandExecutionBudget budget,
  }) async {
    reads.add('$channelId:$messageId');
    return BotMessageSnapshot(
      editedTimestamp: edited,
      repliedMessageId: replied,
      id: '40',
      channelId: '30',
      content: r'$literal[]',
      authorId: '20',
      username: 'bob',
      avatarUrl: 'https://example.com/avatar',
      attachmentUrls: ['https://example.com/a', 'https://example.com/b'],
      embeds: [
        BotMessageEmbed(
          title: 'Title',
          description: 'Body',
          footer: 'Footer',
          colorHex: '00aaff',
          image: 'https://example.com/image',
          timestamp: '2026-10-04T00:00:00.000Z',
        ),
        BotMessageEmbed(),
      ],
    );
  }

  @override
  Future<void> mutateMessage(
    MessageMutation change, {
    required CommandExecutionBudget budget,
  }) async {
    writes.add(change);
  }
}

class _Deferred implements BdfdOutput, BotDeferredMessageOutput {
  int pins = 0;
  @override
  void deferPin() {
    pins++;
  }

  @override
  void append(String text) {}
  @override
  void discard() {}
  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async {}
}

class _Author implements MessageAuthor {
  _Author(this.number);
  final int number;
  @override
  Snowflake get id => Snowflake(number);
  @override
  String get username => 'bob';
  @override
  CdnAsset? get avatar => null;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Attachment implements Attachment {
  @override
  Uri get url => Uri.parse('https://example.com/file');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Image implements EmbedImage {
  @override
  Uri get url => Uri.parse('https://example.com/embed');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Embed implements Embed {
  @override
  String get title => 'Title';
  @override
  String get description => 'Body';
  @override
  EmbedFooter get footer =>
      EmbedFooter(text: 'Footer', iconUrl: null, proxiedIconUrl: null);
  @override
  DiscordColor get color => const DiscordColor(0x00aaff);
  @override
  EmbedImage get image => _Image();
  @override
  DateTime get timestamp => DateTime.parse('2026-10-04T02:00:00+02:00');
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Message implements Message {
  DateTime? edited;
  bool reply = false;
  @override
  DateTime? get editedTimestamp => edited;
  @override
  MessageType get type => reply ? MessageType.reply : MessageType.normal;
  @override
  MessageReference? get reference => reply
      ? MessageReference(
          manager: _Messages(),
          type: MessageReferenceType.defaultType,
          messageId: Snowflake(39),
          channelId: Snowflake(30),
          guildId: Snowflake(10),
        )
      : null;
  int authorNumber = 20;
  @override
  Snowflake get id => Snowflake(40);
  @override
  Snowflake get channelId => Snowflake(30);
  @override
  String get content => 'hello';
  @override
  MessageAuthor get author => _Author(authorNumber);
  @override
  List<Attachment> get attachments => [_Attachment()];
  @override
  List<Embed> get embeds => [_Embed()];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Messages implements MessageManager {
  final message = _Message(), writes = <String>[];
  bool fail = false;
  @override
  Future<Message> fetch(Snowflake id) async => message;
  @override
  Future<void> delete(Snowflake id, {String? auditLogReason}) async {
    writes.add('delete:$id');
    if (fail) throw StateError('refused');
  }

  @override
  Future<void> pin(Snowflake id, {String? auditLogReason}) async {
    writes.add('pin:$id');
  }

  @override
  Future<void> unpin(Snowflake id, {String? auditLogReason}) async {
    writes.add('unpin:$id');
  }

  @override
  Future<Message> update(
    Snowflake id,
    MessageUpdateBuilder builder, {
    String? auditLogReason,
  }) async {
    writes.add('edit:$id');
    return message;
  }

  @override
  Future<Message> crosspost(Snowflake id) async {
    writes.add('publish:$id');
    return message;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Channel implements GuildAnnouncementChannel {
  @override
  Snowflake? get lastMessageId => Snowflake(40);
  @override
  DateTime? get lastPinTimestamp =>
      DateTime.fromMillisecondsSinceEpoch(1753454520000, isUtc: true);
  final messageManager = _Messages();
  @override
  Snowflake get id => Snowflake(30);
  @override
  Snowflake get guildId => Snowflake(10);
  @override
  MessageManager get messages => messageManager;
  @override
  List<PermissionOverwrite> get permissionOverwrites => [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Channels implements ChannelManager {
  final channel = _Channel();
  @override
  Future<Channel> fetch(Snowflake id) async => channel;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Bot implements PartialUser {
  @override
  Snowflake get id => Snowflake(500);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Gateway implements NyxxGateway {
  _Gateway({int permissions = 0, bool owner = true})
    : fixture = EntityFixtureGateway({
        'guilds': {
          '10': {
            'owner_id': owner ? '500' : '999',
            'roles': [
              {'id': '10', 'permissions': '$permissions'},
            ],
            'members': {
              '500': {'roles': <String>[]},
            },
          },
        },
      });
  final EntityFixtureGateway fixture;
  final manager = _Channels();
  @override
  ChannelManager get channels => manager;
  @override
  GuildManager get guilds => fixture.guilds;
  @override
  PartialUser get user => _Bot();
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  BdfdRuntime runtime(_Native service) =>
      BdfdRuntime(functions: bdfdMessageQueryFunctions(service));
  test(
    'getMessage defaults to content and preserves fetched opaque values',
    () async {
      final service = _Native();
      expect(
        await runtime(service).execute(r'$getMessage[30;40]'),
        r'$literal[]',
      );
      expect(
        await runtime(service).execute(
          r'$getMessage[30;40;authorID]/$getMessage[30;40;username]/$getMessage[30;40;avatar]',
        ),
        '20/bob/https://example.com/avatar',
      );
    },
  );
  test('authorOfMessage requires explicit pair', () async {
    final service = _Native();
    expect(await runtime(service).execute(r'$authorOfMessage[30;40]'), '20');
    expect(service.reads, ['30:40']);
  });
  test('attachments index zero references triggering message', () async {
    final service = _Native();
    expect(
      await runtime(service).execute(
        r'$getAttachments[0]/$getAttachments[1]',
        context: BdfdContext(
          variables: {'channel.id': '30', 'message.id': '40'},
        ),
      ),
      'https://example.com/a/https://example.com/b',
    );
    expect(service.reads, ['30:40', '30:40']);
  });
  for (final entry in {
    'title': 'Title',
    'description': 'Body',
    'footer': 'Footer',
    'color': '00aaff',
    'image': 'https://example.com/image',
    'timestamp': '2026-10-04T00:00:00.000Z',
  }.entries) {
    test('embed ${entry.key} uses one-based index', () async {
      expect(
        await runtime(
          _Native(),
        ).execute('\$getEmbedData[30;40;1;${entry.key}]'),
        entry.value,
      );
    });
  }
  test('absent embed properties return empty', () async {
    expect(
      await runtime(_Native()).execute(r'$getEmbedData[30;40;2;title]'),
      '',
    );
  });
  test('invalid properties and IDs reject before read or write', () async {
    final service = _Native();
    for (final source in [
      r'$getMessage[30;40;bad]',
      r'$getMessage[;40]',
      r'$getEmbedData[30;40;0;title]',
      r'$getEmbedData[30;40;1;bad]',
      r'$deleteMessage[30;]',
    ]) {
      await expectLater(
        runtime(service).execute(source),
        throwsA(isA<BdfdNativeError>()),
      );
    }
    expect(service.reads, isEmpty);
    expect(service.writes, isEmpty);
  });
  test('index out of range is an explicit error', () async {
    await expectLater(
      runtime(_Native()).execute(r'$getEmbedData[30;40;3;title]'),
      throwsA(isA<BdfdNativeError>()),
    );
    await expectLater(
      runtime(_Native()).execute(
        r'$getAttachments[2]',
        context: BdfdContext(
          variables: {'channel.id': '30', 'message.id': '40'},
        ),
      ),
      throwsA(isA<BdfdNativeError>()),
    );
  });
  test('mutations forward typed requests and no output', () async {
    final service = _Native();
    expect(
      await runtime(service).execute(
        r'$deleteMessage[30;40]$unpinMessage[30;40]$publishMessage[30;40]',
      ),
      '',
    );
    expect(service.writes.map((c) => c.kind), [
      MessageMutationKind.delete,
      MessageMutationKind.unpin,
      MessageMutationKind.publish,
    ]);
  });
  test(
    'pinMessage defers response pin instead of triggering message mutation',
    () async {
      final service = _Native(), output = _Deferred();
      await runtime(
        service,
      ).execute(r'$pinMessage', context: BdfdContext(output: output));
      expect(output.pins, 1);
      expect(service.writes, isEmpty);
    },
  );
  test('arity preflight prevents earlier mutation', () async {
    final service = _Native();
    await expectLater(
      runtime(service).execute(r'$deleteMessage[30;40]$getMessage[30]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(service.writes, isEmpty);
  });
  test('unknown functions do not evaluate mutation arguments', () async {
    final service = _Native();
    const source = r'$unknownMessage[$deleteMessage[30;40]]';
    expect(await runtime(service).execute(source), source);
    expect(service.writes, isEmpty);
  });
  test('SDK reads fresh snapshot and null webhook avatar', () async {
    final gateway = _Gateway();
    final result = await DiscordBotMessageQueryService(client: gateway).message(
      channelId: '30',
      messageId: '40',
      budget: CommandExecutionBudget(),
    );
    expect(result.content, 'hello');
    expect(result.authorId, '20');
    expect(result.avatarUrl, '');
    expect(result.attachmentUrls, ['https://example.com/file']);
    expect(result.embeds.single.colorHex, '00aaff');
    expect(result.embeds.single.timestamp, '2026-10-04T00:00:00.000Z');
    expect(result.embeds.single.footer, 'Footer');
    expect(result.embeds.single.image, 'https://example.com/embed');
  });
  test('SDK dispatches all mutation kinds exactly once', () async {
    final gateway = _Gateway();
    final service = DiscordBotMessageQueryService(client: gateway);
    for (final kind in MessageMutationKind.values.where(
      (k) => k != MessageMutationKind.edit,
    )) {
      await service.mutateMessage(
        MessageMutation(kind: kind, channelId: '30', messageId: '40'),
        budget: CommandExecutionBudget(),
      );
    }
    expect(gateway.manager.channel.messageManager.writes, [
      'delete:40',
      'pin:40',
      'unpin:40',
      'publish:40',
    ]);
  });
  test('delete own message requires no Manage Messages', () async {
    final gateway = _Gateway(
      owner: false,
      permissions: Permissions.viewChannel.value,
    );
    gateway.manager.channel.messageManager.message.authorNumber = 500;
    await DiscordBotMessageQueryService(client: gateway).mutateMessage(
      const MessageMutation(
        kind: MessageMutationKind.delete,
        channelId: '30',
        messageId: '40',
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.channel.messageManager.writes, ['delete:40']);
  });
  test('permission failures prevent message writes', () async {
    final gateway = _Gateway(
      owner: false,
      permissions: Permissions.viewChannel.value,
    );
    final service = DiscordBotMessageQueryService(client: gateway);
    for (final kind in MessageMutationKind.values.where(
      (k) => k != MessageMutationKind.edit,
    )) {
      await expectLater(
        service.mutateMessage(
          MessageMutation(kind: kind, channelId: '30', messageId: '40'),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
    }
    expect(gateway.manager.channel.messageManager.writes, isEmpty);
  });
  test(
    'SDK errors are not retried and expired budget writes nothing',
    () async {
      final gateway = _Gateway();
      gateway.manager.channel.messageManager.fail = true;
      final service = DiscordBotMessageQueryService(client: gateway);
      await expectLater(
        service.mutateMessage(
          const MessageMutation(
            kind: MessageMutationKind.delete,
            channelId: '30',
            messageId: '40',
          ),
          budget: CommandExecutionBudget(),
        ),
        throwsStateError,
      );
      expect(gateway.manager.channel.messageManager.writes, hasLength(1));
      await expectLater(
        service.mutateMessage(
          const MessageMutation(
            kind: MessageMutationKind.pin,
            channelId: '30',
            messageId: '40',
          ),
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(gateway.manager.channel.messageManager.writes, hasLength(1));
    },
  );
  test('current-channel metadata reads fresh channel snapshot', () async {
    final service = _Native();
    expect(
      await runtime(service).execute(
        r'$lastMessageID/$lastPinTimestamp',
        context: BdfdContext(variables: {'channel.id': '30'}),
      ),
      '40/1753454520',
    );
    expect(service.reads, ['channel:30', 'channel:30']);
  });
  test(
    'edited status and timestamp use explicit IDs; absent timestamp is empty',
    () async {
      final service = _Native();
      expect(
        await runtime(
          service,
        ).execute(r'$isMessageEdited[30;40]/$messageEditedTimestamp[30;40]'),
        'false/',
      );
      service.edited = DateTime.fromMillisecondsSinceEpoch(
        1753454520999,
        isUtc: true,
      );
      expect(
        await runtime(
          service,
        ).execute(r'$isMessageEdited[30;40]/$messageEditedTimestamp[30;40]'),
        'true/1753454520',
      );
    },
  );
  test(
    'repliedMessageID uses triggering message and empty when not reply',
    () async {
      final service = _Native(),
          context = BdfdContext(
            variables: {'channel.id': '30', 'message.id': '40'},
          );
      expect(
        await runtime(service).execute(r'$repliedMessageID', context: context),
        '',
      );
      service.replied = '39';
      expect(
        await runtime(service).execute(r'$repliedMessageID', context: context),
        '39',
      );
      expect(service.reads, ['30:40', '30:40']);
    },
  );
  test(
    'editMessage requires content position and accepts empty embed fields',
    () async {
      final service = _Native();
      await runtime(service).execute(r'$editMessage[30;40;new]');
      expect(service.writes.single.edit!.toBuilder().build(), {
        'content': 'new',
      });
      await runtime(
        service,
      ).execute(r'$editMessage[30;40;;Title;Body;#00aaff;Footer]');
      expect(service.writes.last.edit!.toBuilder().build(), {
        'content': '',
        'embeds': [
          {
            'title': 'Title',
            'description': 'Body',
            'color': 43775,
            'footer': {'text': 'Footer'},
          },
        ],
      });
      await runtime(service).execute(r'$editMessage[30;40;new;;;;]');
      expect(service.writes.last.edit!.toBuilder().build(), {
        'content': 'new',
        'embeds': [],
      });
    },
  );
  test(
    'edit integer color accepted and invalid color rejected before effects',
    () async {
      final service = _Native();
      await runtime(service).execute(r'$editMessage[30;40;new;;;255]');
      expect(service.writes.single.edit!.color, 255);
      await expectLater(
        runtime(service).execute(r'$editMessage[30;40;new;;;16777216]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.writes, hasLength(1));
    },
  );
  test(
    'metadata arity preflight prevents earlier edit and unknown aliases stay opaque',
    () async {
      final service = _Native();
      await expectLater(
        runtime(service).execute(r'$editMessage[30;40;new]$lastMessageID[30]'),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.writes, isEmpty);
      const source = r'$unknownMessageTimestamp[$editMessage[30;40;bad]]';
      expect(await runtime(service).execute(source), source);
      expect(service.writes, isEmpty);
    },
  );
  test('SDK channel and edited metadata uses fetched fields', () async {
    final gateway = _Gateway();
    gateway.manager.channel.messageManager.message.edited =
        DateTime.fromMillisecondsSinceEpoch(1753454520000, isUtc: true);
    final service = DiscordBotMessageQueryService(client: gateway),
        budget = CommandExecutionBudget();
    final channel = await service.messageChannel('30', budget: budget);
    expect(channel.lastMessageId, '40');
    expect(channel.lastPinTimestamp!.millisecondsSinceEpoch, 1753454520000);
    final message = await service.message(
      channelId: '30',
      messageId: '40',
      budget: budget,
    );
    expect(message.editedTimestamp!.millisecondsSinceEpoch, 1753454520000);
    expect(message.repliedMessageId, isNull);
    gateway.manager.channel.messageManager.message.reply = true;
    expect(
      (await service.message(
        channelId: '30',
        messageId: '40',
        budget: budget,
      )).repliedMessageId,
      '39',
    );
  });
  test('SDK edit rejects even administrator editing another author', () async {
    final gateway = _Gateway();
    final service = DiscordBotMessageQueryService(client: gateway);
    await expectLater(
      service.mutateMessage(
        const MessageMutation(
          kind: MessageMutationKind.edit,
          channelId: '30',
          messageId: '40',
          edit: MessageEdit(content: 'new'),
        ),
        budget: CommandExecutionBudget(),
      ),
      throwsStateError,
    );
    expect(gateway.manager.channel.messageManager.writes, isEmpty);
    gateway.manager.channel.messageManager.message.authorNumber = 500;
    await DiscordBotMessageQueryService(client: gateway).mutateMessage(
      const MessageMutation(
        kind: MessageMutationKind.edit,
        channelId: '30',
        messageId: '40',
        edit: MessageEdit(content: 'new'),
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.manager.channel.messageManager.writes, ['edit:40']);
  });
}
