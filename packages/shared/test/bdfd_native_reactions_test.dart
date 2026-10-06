import 'package:bot_creator_shared/engine/bdfd/program.dart';
import 'package:bot_creator_shared/engine/bdfd/reaction_functions.dart';
import 'package:bot_creator_shared/engine/bdfd/runtime.dart';
import 'package:bot_creator_shared/engine/execution_budget.dart';
import 'package:bot_creator_shared/services/bot_permission_query_service.dart';
import 'package:bot_creator_shared/services/bot_reaction_service.dart';
import 'package:bot_creator_shared/services/bdfd_reaction_emoji_aliases.dart';
import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

const _target = BotReactionTarget(channelId: '30', messageId: '40');

class _Service implements BotReactionService {
  final adds = <BotReactionAddRequest>[];
  final clears = <BotReactionClearRequest>[];
  final queries = <BotReactionQuery>[];
  final budgets = <CommandExecutionBudget>[];
  List<BotReactionUser> users = const [
    BotReactionUser(id: '20', username: 'Spen', discriminator: '0999'),
    BotReactionUser(id: '21', username: 'Wiki Bot', discriminator: '6295'),
    BotReactionUser(id: '22', username: 'newuser'),
  ];
  Object? error;
  @override
  Future<void> addReactions(
    BotReactionAddRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    adds.add(request);
    budgets.add(budget);
    if (error != null) throw error!;
  }

  @override
  Future<void> clearReactions(
    BotReactionClearRequest request, {
    required CommandExecutionBudget budget,
  }) async {
    clears.add(request);
    budgets.add(budget);
    if (error != null) throw error!;
  }

  @override
  Future<List<BotReactionUser>> reactionUsers(
    BotReactionQuery query, {
    required CommandExecutionBudget budget,
  }) async {
    queries.add(query);
    budgets.add(budget);
    if (error != null) throw error!;
    return users;
  }
}

class _Output implements BdfdOutput, BotDeferredReactionOutput {
  final registered = <List<String>>[];
  String text = '';
  @override
  void deferReactions(List<String> emojis) => registered.add(emojis);
  @override
  void append(String value) => text += value;
  @override
  void discard() => text = '';
  @override
  Future<void> flush(BdfdContext context, BdfdLocation location) async {}
}

BdfdRuntime _runtime(_Service service) =>
    BdfdRuntime(functions: bdfdReactionFunctions(service));

class _Emoji implements Emoji {
  _Emoji(int id, this.name) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  final String name;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Message implements Message {
  @override
  List<Reaction> reactions = [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _User implements User {
  _User(int id) : id = Snowflake(id);
  @override
  final Snowflake id;
  @override
  String get username => 'user$id';
  @override
  String get discriminator => '0';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messages implements MessageManager {
  final _Message message = _Message();
  int fetches = 0;
  final writes = <String>[];
  int? failAt;
  Duration writeDelay = Duration.zero;
  List<List<User>> pages = [[]];
  final cursors = <Snowflake?>[];
  final limits = <int?>[];
  @override
  Future<Message> fetch(Snowflake id) async {
    fetches++;
    return message;
  }

  @override
  Future<void> addReaction(Snowflake id, ReactionBuilder emoji) async {
    writes.add('add:$id:${emoji.build()}');
    if (writeDelay != Duration.zero) await Future<void>.delayed(writeDelay);
    if (failAt == writes.length) throw StateError('Write refused');
  }

  @override
  Future<void> deleteAllReactions(Snowflake id) async {
    writes.add('clear:$id');
  }

  @override
  Future<void> deleteReaction(Snowflake id, ReactionBuilder emoji) async {
    writes.add('clear:$id:${emoji.build()}');
  }

  @override
  Future<List<User>> fetchReactions(
    Snowflake id,
    ReactionBuilder emoji, {
    Snowflake? after,
    int? limit,
  }) async {
    cursors.add(after);
    limits.add(limit);
    return pages[(cursors.length - 1).clamp(0, pages.length - 1)];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Channel implements TextChannel {
  _Channel(this.messages);
  @override
  Snowflake get id => Snowflake(30);
  @override
  final _Messages messages;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _GuildChannel extends _Channel implements GuildChannel {
  _GuildChannel(super.messages);
}

class _Channels implements ChannelManager {
  _Channels(this.channel);
  Channel channel;
  int fetches = 0;
  @override
  Future<Channel> fetch(Snowflake id) async {
    fetches++;
    return channel;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Gateway implements NyxxGateway {
  _Gateway() {
    channels = _Channels(_Channel(messages));
  }
  final _Messages messages = _Messages();
  @override
  late final _Channels channels;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Permissions implements BotPermissionQueryService {
  int mask =
      Permissions.readMessageHistory.value |
      Permissions.addReactions.value |
      Permissions.manageMessages.value;
  final channelIds = <String?>[];
  @override
  Future<BotMemberPermissions> memberPermissions({
    String? userId,
    String? channelId,
    required CommandExecutionBudget budget,
  }) async {
    channelIds.add(channelId);
    return BotMemberPermissions(mask);
  }

  @override
  Future<int> storedMemberPermissions(
    String userId, {
    required CommandExecutionBudget budget,
  }) => throw UnimplementedError();
}

Reaction _reaction(int id, String name) => Reaction(
  count: 1,
  countDetails: ReactionCountDetails(burst: 0, normal: 1),
  me: false,
  meBurst: false,
  emoji: _Emoji(id, name),
  burstColors: [],
);

void main() {
  Map<String, dynamic> fixtures() => {
    'guilds': {
      '10': {
        'owner_id': '99',
        'name': 'Guild',
        'channels': [
          {'id': '30', 'name': 'chat', 'type': 'text'},
        ],
        'emojis': [
          {'id': '123', 'name': 'tip'},
        ],
      },
    },
    'users': {
      '20': {'username': 'Spen', 'discriminator': '0999'},
      '99': {'username': 'Bot', 'discriminator': '0'},
    },
    'messages': {
      '30': {
        '40': {
          'author_id': '20',
          'content': 'command',
          'reactions': <Map<String, dynamic>>[],
        },
      },
    },
  };
  Future<Map<String, dynamic>> sandbox(
    String script,
    Map<String, dynamic> entities,
  ) => testCommandInSandbox({
    'script': script,
    'bdfdBackend': 'native-v1',
    'variables': {
      'guild.id': '10',
      'channel.id': '30',
      'message.id': '40',
      'author.id': '20',
      'bot.id': '99',
    },
    'entities': entities,
  });
  test(
    'Sandbox native add command, explicit add, read users and clear share fixtures',
    () async {
      final result = await sandbox(
        r'$addCmdReactions[👍]$addMessageReactions[30;40;:x:]$userReacted[30;40;99;👍]|$getReactions[30;40;, ;👍]$clearReactions[30;40;:x:]$clearReactions[30;40;!all]',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'true|Bot');
      expect((result['effects'] as List).map((e) => e['type']), [
        'addReaction',
        'addReaction',
        'clearReactions',
        'clearReactions',
      ]);
      expect(result['effects'].last['after'], isEmpty);
    },
  );
  test(
    'Sandbox numeric custom ID finds origin guild emoji then reads it by ID',
    () async {
      final result = await sandbox(
        r'$addMessageReactions[30;40;123]$userReacted[30;40;99;123]|$getReactions[30;40;, ;123]',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], 'true|Bot');
      expect(result['effects'][0]['emoji'], 'tip:123');
      expect(
        (result['entity_requests'] as List).any(
          (r) => r['operation'] == 'guild.emojis',
        ),
        true,
      );
    },
  );
  test(
    'Sandbox response reactions use actual synthetic response ID rather than command',
    () async {
      final result = await sandbox(
        r'Yes or No?$addReactions[✅;:x:]',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      final id = result['responses'][0]['id'];
      expect((result['effects'] as List).map((e) => e['message_id']), [id, id]);
      expect(id, isNot('40'));
    },
  );
  test(
    'Sandbox rejected or unknown reaction call performs no simulated mutation',
    () async {
      final invalid = await sandbox(
        r'$addMessageReactions[30;40;👍;:unknown:]',
        fixtures(),
      );
      expect(invalid['success'], false);
      expect(invalid['effects'], isEmpty);
      final unknown = await sandbox(
        r'$futureReaction[$addMessageReactions[30;40;👍]]',
        fixtures(),
      );
      expect(unknown['success'], true);
      expect(unknown['effects'], isEmpty);
      expect(unknown['entity_requests'], isEmpty);
    },
  );
  test('official aliases normalize including x, heart and skin tone', () {
    expect(bdfdReactionEmojiAliases.length, 2776);
    expect(normalizeBotReactionEmoji(':x:'), '❌');
    expect(normalizeBotReactionEmoji(':heart:'), '❤️');
    expect(normalizeBotReactionEmoji(':white_check_mark:'), '✅');
    expect(normalizeBotReactionEmoji(' 👍 '), '👍');
    for (final value in ['', ':not_supported:', 'plain', '0', '<:bad:no>']) {
      expect(() => normalizeBotReactionEmoji(value), throwsArgumentError);
    }
  });
  test(
    'addReactions defers official example to future output without calling service',
    () async {
      final service = _Service();
      final output = _Output();
      final context = BdfdContext(output: output);
      await _runtime(
        service,
      ).execute(r'Yes or No?$addReactions[✅;:x:]', context: context);
      expect(output.registered, [
        ['✅', '❌'],
      ]);
      expect(service.adds, isEmpty);
      expect(context.response.messageId, isNull);
      expect(() => output.registered.single.add('👍'), throwsUnsupportedError);
    },
  );
  test(
    'deferred reactions preserve evaluated values after temporary variables change',
    () async {
      final output = _Output();
      await _runtime(_Service()).execute(
        r'$var[e;:heart:]$addReactions[$var[e]]$var[e;:x:]',
        context: BdfdContext(output: output),
      );
      expect(output.registered, [
        ['❤️'],
      ]);
    },
  );
  test(
    'deferred reactions without output fail instead of targeting command message',
    () async {
      final service = _Service();
      await expectLater(
        _runtime(service).execute(
          r'$addReactions[✅]',
          context: BdfdContext(
            variables: {'channel.id': '30', 'message.id': '40'},
          ),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.adds, isEmpty);
    },
  );
  test(
    'addCmdReactions targets invoking message; addMessageReactions uses explicit IDs',
    () async {
      final service = _Service();
      final context = BdfdContext(
        variables: {'channel.id': '30', 'message.id': '40'},
      );
      expect(
        await _runtime(service).execute(
          r'$addCmdReactions[❤️;:x:]$addMessageReactions[31;41;👍;<a:custom:123>]',
          context: context,
        ),
        '',
      );
      expect(service.adds.first.target.channelId, '30');
      expect(service.adds.first.target.messageId, '40');
      expect(service.adds.first.emojis, ['❤️', '❌']);
      expect(service.adds.last.target.channelId, '31');
      expect(service.adds.last.target.messageId, '41');
      expect(service.adds.last.emojis, ['👍', '<a:custom:123>']);
      expect(service.budgets.every((b) => identical(b, context.budget)), true);
    },
  );
  test('request copies mutable caller emoji list', () {
    final values = ['✅'];
    final request = BotReactionAddRequest(target: _target, emojis: values);
    values[0] = '❌';
    expect(request.emojis, ['✅']);
    expect(() => request.emojis[0] = '❌', throwsUnsupportedError);
  });
  test('all emoji arguments validated before first effect', () async {
    final service = _Service();
    await expectLater(
      _runtime(service).execute(r'$addMessageReactions[30;40;✅;]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(service.adds, isEmpty);
    await expectLater(
      _runtime(service).execute(r'$addCmdReactions[✅]'),
      throwsA(isA<BdfdNativeError>()),
    );
    expect(service.adds, isEmpty);
  });
  test(
    'clearReactions !all and specific emoji use exact documented three args',
    () async {
      final service = _Service();
      await _runtime(
        service,
      ).execute(r'$clearReactions[30;40;!all]$clearReactions[30;40;:x:]');
      expect(service.clears.map((r) => r.emoji), [null, '❌']);
      expect(
        () => _runtime(service).prepare(r'$clearReactions[30;40]'),
        throwsA(isA<BdfdNativeError>()),
      );
    },
  );
  test(
    'getReactions returns official screenshot user tags with exact separator',
    () async {
      final service = _Service();
      expect(
        await _runtime(service).execute(r'$getReactions[30;40;, ;👍]'),
        'Spen#0999, Wiki Bot#6295, newuser',
      );
      expect(service.queries.single.emoji, '👍');
      service.users = [];
      expect(
        await _runtime(service).execute(r'[$getReactions[30;40;|;👍]]'),
        '[]',
      );
    },
  );
  test(
    'userReacted compares IDs rather than usernames and never substitutes author',
    () async {
      final service = _Service();
      expect(
        await _runtime(
          service,
        ).execute(r'$userReacted[30;40;20;👍]|$userReacted[30;40;99;👍]'),
        'true|false',
      );
      await expectLater(
        _runtime(service).execute(
          r'$userReacted[30;40;;👍]',
          context: BdfdContext(variables: {'author.id': '20'}),
        ),
        throwsA(isA<BdfdNativeError>()),
      );
      expect(service.queries.length, 2);
    },
  );
  test(
    'query tags remain literal data; truly unknown call leaves nested effects opaque',
    () async {
      final service = _Service()
        ..users = const [BotReactionUser(id: '20', username: r'$var[bad;yes]')];
      final context = BdfdContext();
      expect(
        await _runtime(service).execute(
          r'$getReactions[30;40;|;👍]|$futureReaction[$addMessageReactions[30;40;👍]]',
          context: context,
        ),
        r'$var[bad;yes]|$futureReaction[$addMessageReactions[30;40;👍]]',
      );
      expect(context.temporaryVariables, isEmpty);
      expect(service.adds, isEmpty);
    },
  );
  test(
    'known removeReaction stays unsupported; bad query arities preflight before effects',
    () {
      for (final source in [
        r'$removeReaction[30;40;👍]',
        r'$getReactions[30;40;👍]',
        r'$userReacted[30;40;👍]',
        r'$addMessageReactions[30;40]',
      ]) {
        expect(
          () => _runtime(_Service()).prepare(source),
          throwsA(isA<BdfdNativeError>()),
        );
      }
    },
  );
  test('service errors remain catchable, never retried', () async {
    final service = _Service()..error = StateError('Denied');
    final result = await _runtime(service).execute(
      r'$try'
      '\n'
      r'$addMessageReactions[30;40;👍]'
      '\n'
      r'$catch'
      '\n'
      'Caught'
      '\n'
      r'$endtry',
    );
    expect(result, contains('Caught'));
    expect(service.adds.length, 1);
  });
  test('SDK add prepares full batch before writes and retains order', () async {
    final gateway = _Gateway();
    await DiscordBotReactionService(client: gateway).addReactions(
      BotReactionAddRequest(
        target: _target,
        emojis: ['👍', ':x:', '<:custom:123>'],
      ),
      budget: CommandExecutionBudget(),
    );
    expect(gateway.messages.writes, [
      'add:40:👍',
      'add:40:❌',
      'add:40:custom:123',
    ]);
    expect(gateway.messages.fetches, 1);
    expect(gateway.channels.fetches, 1);
  });
  test('SDK invalid later emoji prevents all writes and reads', () async {
    final gateway = _Gateway();
    await expectLater(
      DiscordBotReactionService(client: gateway).addReactions(
        BotReactionAddRequest(target: _target, emojis: ['👍', '']),
        budget: CommandExecutionBudget(),
      ),
      throwsArgumentError,
    );
    expect(gateway.messages.writes, isEmpty);
    expect(gateway.channels.fetches, 0);
  });
  test(
    'SDK partial add failure preserves first write, does not retry or roll back',
    () async {
      final gateway = _Gateway();
      gateway.messages.failAt = 2;
      await expectLater(
        DiscordBotReactionService(client: gateway).addReactions(
          BotReactionAddRequest(target: _target, emojis: ['👍', '❌', '✅']),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.messages.writes, ['add:40:👍', 'add:40:❌']);
    },
  );
  test('SDK late write response prevents following reactions', () async {
    final gateway = _Gateway();
    gateway.messages.writeDelay = const Duration(milliseconds: 50);
    await expectLater(
      DiscordBotReactionService(client: gateway).addReactions(
        BotReactionAddRequest(target: _target, emojis: ['👍', '❌']),
        budget: CommandExecutionBudget(limit: const Duration(milliseconds: 10)),
      ),
      throwsA(isA<CommandExecutionTimeout>()),
    );
    expect(gateway.messages.writes, ['add:40:👍']);
  });
  test(
    'SDK clear all uses deleteAllReactions; selected emoji clears all users for emoji',
    () async {
      final gateway = _Gateway();
      final service = DiscordBotReactionService(client: gateway);
      await service.clearReactions(
        const BotReactionClearRequest(target: _target),
        budget: CommandExecutionBudget(),
      );
      await service.clearReactions(
        const BotReactionClearRequest(target: _target, emoji: ':heart:'),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.messages.writes, ['clear:40', 'clear:40:❤️']);
    },
  );
  test(
    'numeric custom ID resolves existing message reaction name without guild lookup',
    () async {
      final gateway = _Gateway();
      gateway.messages.message.reactions = [_reaction(123, 'tip')];
      await DiscordBotReactionService(client: gateway).addReactions(
        BotReactionAddRequest(target: _target, emojis: ['123']),
        budget: CommandExecutionBudget(),
      );
      expect(gateway.messages.writes, ['add:40:tip:123']);
    },
  );
  test(
    'prepare helpers are read-only and check permission distinction existing vs new reaction',
    () async {
      final gateway = _Gateway();
      gateway.channels.channel = _GuildChannel(gateway.messages);
      final permissions = _Permissions()
        ..mask = Permissions.readMessageHistory.value;
      gateway.messages.message.reactions = [_reaction(0, '👍')];
      await prepareBotReactionAdd(
        gateway,
        BotReactionAddRequest(target: _target, emojis: ['👍']),
        budget: CommandExecutionBudget(),
        permissions: permissions,
      );
      expect(gateway.messages.writes, isEmpty);
      await expectLater(
        prepareBotReactionAdd(
          gateway,
          BotReactionAddRequest(target: _target, emojis: ['✅']),
          budget: CommandExecutionBudget(),
          permissions: permissions,
        ),
        throwsA(isA<StateError>()),
      );
      permissions.mask = Permissions.addReactions.value;
      await expectLater(
        prepareBotReactionAdd(
          gateway,
          BotReactionAddRequest(target: _target, emojis: ['👍']),
          budget: CommandExecutionBudget(),
          permissions: permissions,
        ),
        throwsA(isA<StateError>()),
      );
      permissions.mask = Permissions.manageMessages.value;
      await prepareBotReactionClear(
        gateway,
        const BotReactionClearRequest(target: _target),
        budget: CommandExecutionBudget(),
        permissions: permissions,
      );
      expect(permissions.channelIds, ['30', '30', '30', '30']);
      expect(gateway.messages.writes, isEmpty);
    },
  );
  test('SDK query paginates beyond 100 users and deduplicates IDs', () async {
    final gateway = _Gateway();
    gateway.messages.pages = [
      List.generate(100, (i) => _User(i + 1)),
      [_User(100), _User(101)],
    ];
    final result = await DiscordBotReactionService(client: gateway)
        .reactionUsers(
          const BotReactionQuery(target: _target, emoji: '👍'),
          budget: CommandExecutionBudget(),
        );
    expect(result.length, 101);
    expect(result.last.id, '101');
    expect(result.last.tag, 'user101');
    expect(gateway.messages.cursors.map((id) => id?.toString()), [null, '100']);
    expect(gateway.messages.limits, [100, 100]);
    expect(gateway.messages.writes, isEmpty);
    expect(() => result.clear(), throwsUnsupportedError);
  });
  test(
    'SDK full page with stagnant cursor errors instead of looping',
    () async {
      final gateway = _Gateway();
      gateway.messages.pages = [List.generate(100, (i) => _User(i + 1))];
      await expectLater(
        DiscordBotReactionService(client: gateway).reactionUsers(
          const BotReactionQuery(target: _target, emoji: '👍'),
          budget: CommandExecutionBudget(),
        ),
        throwsA(isA<StateError>()),
      );
      expect(gateway.messages.cursors.length, 2);
    },
  );
  test(
    'expired shared budget rejects preparation before reads or writes',
    () async {
      final gateway = _Gateway();
      await expectLater(
        prepareBotReactionAdd(
          gateway,
          BotReactionAddRequest(target: _target, emojis: ['👍']),
          budget: CommandExecutionBudget(limit: Duration.zero),
        ),
        throwsA(isA<CommandExecutionTimeout>()),
      );
      expect(gateway.channels.fetches, 0);
      expect(gateway.messages.writes, isEmpty);
    },
  );
}
