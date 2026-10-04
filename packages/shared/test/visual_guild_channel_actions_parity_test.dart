import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_discord_gateway.dart';
import 'helpers/variables_test_helpers.dart' show MemoryBotDataStore;
import 'helpers/visual_golden.dart';
import 'helpers/visual_parity_harness.dart';

/// Parity of the thread / guild / bot-profile / channel blocks between the
/// historical executors and `bc_<type>` on the native engine, over the same
/// recording Discord gateway: createThread, addThreadMember, removeThreadMember,
/// leaveGuild, updateSelfUser, register/unregisterGuildCommands, createChannel,
/// updateChannel, removeChannel, slowmode, editChannelPermissions and
/// deleteChannelPermission.

typedef _Out = Outcome<VisualGateway>;

final _commands = <Map<String, dynamic>>[
  for (final name in ['alpha', 'beta'])
    {
      'type': 'chatInput',
      'name': name,
      'description': 'The $name command',
      'data': {
        'legacyLocalOnly': true,
        'options': [
          {'type': 3, 'name': 'text', 'description': 'Text', 'required': true},
        ],
      },
    },
  {'type': 'chatInput', 'name': 'global', 'data': <String, dynamic>{}},
];

Future<_Out> _parity(
  List<Action> actions, {
  int permissions = 8,
  void Function(VisualGateway gateway)? setup,
  Map<String, String>? variables,
  bool guild = true,
  bool throwOnError = false,
  Duration? limit,
  Snowflake? fallbackChannelId,
  bool expectNative = true,
  int? nativePrograms,
}) async {
  final outcome = await visualParity<VisualGateway>(
    actions,
    makeGateway: () =>
        VisualGateway(data: visualFixtures(permissions: permissions)),
    effects: (g) => g.writes,
    setup: (g) {
      g.channelManager.threads[Snowflake(80)] = VisualThread(
        Snowflake(80),
        'old',
        gateway: g,
      );
      g.commandRows.addAll([VisualCommand(Snowflake(1), 'alpha')]);
      g.commandRows.add(VisualCommand(Snowflake(2), 'beta'));
      setup?.call(g);
    },
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    limit: limit,
    fallbackChannelId: fallbackChannelId,
    makeStore: () => CommandStore(_commands),
    expectNative: expectNative,
    nativePrograms: nativePrograms,
    compareHistorical: parityWithHistorical,
  );
  _golden.expectOutcome(outcome);
  return outcome;
}

/// A store whose channel `30` is (or is not) a ticket of owner `20`.
class _TicketStore extends MemoryBotDataStore {
  _TicketStore({bool ticket = false})
    : super(
        scopedVariables: {
          'channel': {
            if (ticket) '30': {'__ticket': true, '__ticket_owner': '20'},
          },
        },
      );
}

/// Parity over fresh [_TicketStore]s; [stores] collects them (the first is the
/// native run's).
Future<_Out> _parityWithStore(
  List<Action> actions, {
  bool ticket = false,
  Map<String, String>? variables,
  List<_TicketStore>? stores,
  bool createsOnGuild = false,
  Snowflake? fallbackChannelId,
}) async {
  final outcome = await visualParity<VisualGateway>(
    actions,
    makeGateway: () =>
        VisualGateway(data: visualFixtures())
          ..createChannelOnGuild = createsOnGuild,
    fallbackChannelId: fallbackChannelId,
    effects: (g) => g.writes,
    variables: variables,
    makeStore: () {
      final store = _TicketStore(ticket: ticket);
      stores?.add(store);
      return store;
    },
    compareHistorical: parityWithHistorical,
  );
  _golden.expectOutcome(outcome);
  return outcome;
}

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
  bool enabled = true,
}) => visualAction(
  type,
  key: key,
  payload: payload,
  error: error,
  enabled: enabled,
);

final _golden = GoldenFile('visual_guild_channel_actions');

void main() {
  group('createThread parity', () {
    const type = BotCreatorActionType.createThread;
    test('creates a public thread and mirrors its results', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30', 'name': ' Talk '}, key: 't'),
      ]);
      expect(outcome.results, {'t': '700'});
      expect(outcome.variables['t.threadId'], '700');
      expect(outcome.variables['t.name'], 'Talk');
      expect(outcome.variables['t.parentId'], '30');
      expect(outcome.variables['thread.lastId'], '700');
      expect(outcome.variables['thread.lastName'], 'Talk');
      // Switch-handled historically: no "last message" bookkeeping.
      expect(outcome.variables.containsKey('lastSentMessageId'), isFalse);
    });

    test('forwards type, slowmode, archive duration and reason', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'name': 'Private',
          'type': 'PRIVATE',
          'slowmode': '10',
          'autoArchiveDuration': '5000',
          'reason': ' Because ',
        }),
      ]);
      final write = outcome.gateway.writes.single;
      expect(write['reason'], 'Because');
      expect((write['payload'] as Map)['rate_limit_per_user'], 10);
    });

    test('creates a thread on a message', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'On message', 'messageId': '55'}),
      ]);
      expect(
        outcome.gateway.writes.single['operation'],
        'createThreadFromMessage',
      );
    });

    test('uses the fallback channel and resolves placeholders', () async {
      final outcome = await _parity(
        [
          _a(type, {'name': '((title))'}),
        ],
        variables: {'title': 'From var'},
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.variables['action_0.name'], 'From var');
    });

    test('later actions read earlier results', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'One'}, key: 'one'),
        _a(type, {'channelId': '30', 'name': 'Thread ((one))'}, key: 'two'),
      ]);
      expect(outcome.variables['two.name'], 'Thread 700');
    });

    test('reports its failures like the historical branch', () async {
      var outcome = await _parity([
        _a(type, {'name': 'x'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: channelId is required for createThread',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': ' '}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: name is required for createThread',
      );
      outcome = await _parity([
        _a(type, {'channelId': '31', 'name': 'x'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Channel does not support threads',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'x'}),
      ], permissions: 0);
      expect(
        outcome.error.toString(),
        startsWith('Exception: I do not have permission to create threads'),
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'x'}),
      ], setup: (g) => g.failures['createThread'] = StateError('refused'));
      expect(
        outcome.error.toString(),
        'Exception: Failed to create thread: Bad state: refused',
      );
      expect(outcome.variables['error.command'], type.name);
    });

    test('works without a guild context (no permission pre-check)', () async {
      final outcome = await _parity(
        [
          _a(type, {'channelId': '30', 'name': 'x'}),
        ],
        guild: false,
        permissions: 0,
      );
      expect(outcome.error, isNull);
    });

    test('error modes and disabled actions behave the same', () async {
      final outcome = await _parity([
        _a(type, {'name': 'x'}, key: 'bad', error: {'mode': 'continue'}),
        _a(type, {'channelId': '30', 'name': 'x'}, key: 'off', enabled: false),
        _a(type, {'channelId': '30', 'name': 'ok'}, key: 'ok'),
      ]);
      expect(outcome.results!['bad'], startsWith('Error: Exception: '));
      expect(outcome.results!['ok'], '700');
    });
  });

  for (final add in [true, false]) {
    final type = add
        ? BotCreatorActionType.addThreadMember
        : BotCreatorActionType.removeThreadMember;
    group('${type.name} parity', () {
      test('changes the member and mirrors threadId / userId', () async {
        final outcome = await _parity([
          _a(type, {'threadId': '80', 'userId': '222'}, key: 'm'),
        ]);
        expect(outcome.results, {'m': add ? 'ADDED' : 'REMOVED'});
        expect(outcome.variables['m.threadId'], '80');
        expect(outcome.variables['m.userId'], '222');
        expect(outcome.gateway.writes.single['operation'], type.name);
      });

      test('resolves placeholders', () async {
        final outcome = await _parity(
          [
            _a(type, {'threadId': '((t))', 'userId': '((u))'}),
          ],
          variables: {'t': '80', 'u': '333'},
        );
        expect(outcome.variables['action_0.userId'], '333');
      });

      test('reports its failures', () async {
        var outcome = await _parity([
          _a(type, {'threadId': '80'}),
        ]);
        expect(outcome.error, isA<Exception>());
        outcome = await _parity([
          _a(type, {'threadId': '30', 'userId': '222'}),
        ]);
        expect(
          outcome.error.toString(),
          'Exception: Provided channel is not a thread',
        );
        outcome = await _parity([
          _a(type, {'threadId': '80', 'userId': '222'}),
        ], permissions: 0);
        expect(
          outcome.error.toString(),
          startsWith('Exception: I do not have permission to'),
        );
        outcome = await _parity([
          _a(type, {'threadId': '80', 'userId': '222'}),
        ], setup: (g) => g.failures[type.name] = StateError('refused'));
        expect(outcome.error.toString(), contains('refused'));
      });
    });
  }

  group('leaveGuild parity', () {
    const type = BotCreatorActionType.leaveGuild;
    void leaver(VisualGateway g) => g.leaveOnFetch = true;
    test('leaves the current guild or the named one', () async {
      var outcome = await _parity([_a(type, {}, key: 'l')], setup: leaver);
      expect(outcome.results, {'l': '10'});
      expect(outcome.gateway.writes.single, {
        'operation': 'leaveGuild',
        'guild': '10',
      });
      outcome = await _parity(
        [
          _a(type, {'guildId': '((g))'}),
        ],
        setup: leaver,
        variables: {'g': '77'},
        guild: false,
      );
      expect(outcome.results, {'action_0': '77'});
    });

    test('fails without any guild and when Discord refuses', () async {
      var outcome = await _parity([_a(type, {})], guild: false);
      expect(outcome.error.toString(), 'Exception: Missing guildId');
      outcome = await _parity(
        [_a(type, {})],
        setup: (g) {
          leaver(g);
          g.failures['leaveGuild'] = StateError('refused');
        },
      );
      expect(
        outcome.error.toString(),
        'Exception: Failed to update guild: Bad state: refused',
      );
    });
  });

  group('updateSelfUser parity', () {
    const type = BotCreatorActionType.updateSelfUser;
    test('changes the username and mirrors the result', () async {
      final outcome = await _parity([
        _a(type, {'username': ' Neo '}, key: 'me'),
      ]);
      expect(outcome.results, {'me': 'updated'});
      expect(outcome.variables['me.username'], 'Neo');
      expect(outcome.variables['me.userId'], '500');
    });

    test('accepts the bot itself as target and an avatar payload', () async {
      final outcome = await _parity([
        _a(type, {
          'username': 'Neo',
          'targetUserId': '((bot.id))',
          'avatarBase64': '!!not base64!!',
        }),
      ]);
      expect(outcome.error, isNull);
    });

    test('refuses another user and an empty update', () async {
      var outcome = await _parity([
        _a(type, {'username': 'Neo', 'targetUserId': '999'}),
      ]);
      expect(outcome.error, isA<StateError>());
      expect(outcome.error.toString(), contains('cannot change another user'));
      outcome = await _parity([_a(type, {})]);
      expect(
        outcome.error.toString(),
        'Exception: At least one of username, avatarUrl, or avatarBase64 must be provided',
      );
      outcome = await _parity([
        _a(type, {'username': 'Neo'}),
      ], setup: (g) => g.failures['updateSelfUser'] = StateError('refused'));
      expect(
        outcome.error.toString(),
        'Exception: Failed to update self user: Bad state: refused',
      );
    });
  });

  group('guild commands parity', () {
    test('registers every local-only command', () async {
      final outcome = await _parity([
        _a(BotCreatorActionType.registerGuildCommands, {}, key: 'r'),
      ]);
      expect(outcome.results, {'r': '2'});
      expect(outcome.gateway.writes.map((w) => w['name']), ['alpha', 'beta']);
    });

    test('filters by name, never resolving the name list', () async {
      var outcome = await _parity([
        _a(BotCreatorActionType.registerGuildCommands, {
          'commandNames': ['beta', ' '],
        }),
      ]);
      expect(outcome.results, {'action_0': '1'});
      outcome = await _parity(
        [
          _a(BotCreatorActionType.registerGuildCommands, {
            'commandNames': ['((name))'],
          }),
        ],
        variables: {'name': 'alpha'},
      );
      expect(outcome.results, {'action_0': '0'});
    });

    test('targets the guild of the payload, else the current one', () async {
      final outcome = await _parity(
        [
          _a(BotCreatorActionType.registerGuildCommands, {'guildId': '((g))'}),
        ],
        variables: {'g': '77'},
        guild: false,
      );
      expect(outcome.gateway.writes.first['guild'], '77');
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(BotCreatorActionType.registerGuildCommands, {}),
      ], guild: false);
      expect(outcome.error.toString(), 'Exception: No guildId provided');
      outcome = await _parity([
        _a(BotCreatorActionType.registerGuildCommands, {}),
      ], setup: (g) => g.failures['createCommand'] = StateError('refused'));
      expect(
        outcome.error.toString(),
        'Exception: Failed to register alpha: Bad state: refused',
      );
    });

    test('unregisters all or only the named commands', () async {
      const type = BotCreatorActionType.unregisterGuildCommands;
      var outcome = await _parity([_a(type, {}, key: 'u')]);
      expect(outcome.results, {'u': '2'});
      outcome = await _parity([
        _a(type, {
          'commandNames': ['beta'],
        }),
      ]);
      expect(outcome.results, {'action_0': '1'});
      expect(outcome.gateway.writes.single['id'], '2');
      outcome = await _parity([_a(type, {})], guild: false);
      expect(outcome.error.toString(), 'Exception: No guildId provided');
      outcome = await _parity([
        _a(type, {}),
      ], setup: (g) => g.failures['deleteCommand'] = StateError('refused'));
      expect(
        outcome.error.toString(),
        'Exception: Failed to unregister commands: Bad state: refused',
      );
    });
  });

  group('createChannel parity', () {
    const type = BotCreatorActionType.createChannel;
    test('creates a text channel with every option', () async {
      final outcome = await _parity([
        _a(type, {
          'name': ' general ',
          'type': 'text',
          'categoryId': '31',
          'topic': ' Topic ',
          'nsfw': 'yes',
          'slowmode': '2m',
          'reason': 'Setup',
        }, key: 'c'),
      ]);
      expect(outcome.results, {'c': '800'});
      final write = outcome.gateway.writes.single;
      final payload = write['payload'] as Map;
      expect(payload['topic'], 'Topic');
      expect(payload['nsfw'], true);
      expect(payload['rate_limit_per_user'], 120);
      expect(payload['parent_id'], '31');
      expect(write['reason'], 'Setup');
    });

    test('adapts the options to each channel type', () async {
      for (final channelType in [
        'voice',
        'announcement',
        'stage',
        'forum',
        'category',
        'unknown',
      ]) {
        final outcome = await _parity([
          _a(type, {
            'name': 'x',
            'type': channelType,
            'topic': 't',
            'nsfw': 'true',
            'slowmode': '5',
            'categoryId': '31',
          }),
        ]);
        expect(outcome.error, isNull, reason: channelType);
      }
    });

    test('resolves placeholders and reads earlier results', () async {
      final outcome = await _parity(
        [
          _a(type, {'name': '((n))'}, key: 'first'),
          _a(type, {'name': 'copy-((first))'}),
        ],
        variables: {'n': 'room'},
      );
      expect(outcome.results, {'first': '800', 'action_1': '801'});
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'name': ''}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Failed to create channel: Invalid argument(s): Channel name must contain 1 to 100 characters.',
      );
      outcome = await _parity([
        _a(type, {'name': 'x'}),
      ], guild: false);
      expect(
        outcome.error.toString(),
        'Exception: This action requires a guild context',
      );
      outcome = await _parity([
        _a(type, {'name': 'x'}),
      ], permissions: 0);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'name': 'x', 'categoryId': '30'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'name': 'x'}),
      ], setup: (g) => g.failures['createChannel'] = StateError('refused'));
      expect(outcome.error.toString(), contains('refused'));
    });

    group('ticket', () {
      final payload = {
        'name': ' ticket-1 ',
        'isTicket': true,
        'categoryId': '31',
        'ownerId': '20',
      };

      test('creates a private channel and marks it in the store', () async {
        final stores = <_TicketStore>[];
        final outcome = await _parityWithStore(
          [_a(type, payload, key: 'tk')],
          stores: stores,
          createsOnGuild: true,
        );
        final store = stores.first;
        expect(outcome.error, isNull);
        expect(outcome.results, {'tk': '800'});
        final write = outcome.gateway.writes.single;
        expect(write['operation'], 'createChannel');
        final overwrites = (write['payload'] as Map)['permission_overwrites'];
        expect(overwrites, hasLength(2));
        expect(
          await store.getScopedVariable('bot', 'channel', '800', '__ticket'),
          true,
        );
        expect(
          await store.getScopedVariable(
            'bot',
            'channel',
            '800',
            '__ticket_owner',
          ),
          '20',
        );
      });

      test('reports its failures', () async {
        var outcome = await _parity([_a(type, payload)], guild: false);
        expect(outcome.error.toString(), contains('Tickets require a server'));
        outcome = await _parity([
          _a(type, {'name': 'x', 'isTicket': true}),
        ]);
        expect(
          outcome.error.toString(),
          contains('Ticket requires category ID, creator ID and name'),
        );
        outcome = await _parity([
          _a(type, {...payload, 'categoryId': '30'}),
        ]);
        expect(
          outcome.error.toString(),
          contains('Ticket category not found in this server'),
        );
      });
    });
  });

  group('updateChannel parity', () {
    const type = BotCreatorActionType.updateChannel;
    test('updates the named fields and returns the id', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': ' 30 ',
          'name': 'renamed',
          'topic': 'new topic',
          'nsfw': 'true',
          'position': '2',
          'categoryId': '31',
          'slowmode': '1h',
          'reason': 'Tidy',
        }, key: 'u'),
      ]);
      expect(outcome.results, {'u': '30'});
      expect(outcome.gateway.writes.single['reason'], 'Tidy');
    });

    test('the unchanged sentinel and empty fields change nothing', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'name': '!unchanged',
          'topic': '!unchanged',
        }),
        _a(type, {'channelId': '30'}, key: 'empty'),
      ]);
      expect(outcome.results!['empty'], '30');
      expect(outcome.gateway.writes, isEmpty);
    });

    test('resolves placeholders', () async {
      final outcome = await _parity(
        [
          _a(type, {'channelId': '((c))', 'name': '((n))'}),
        ],
        variables: {'c': '30', 'n': 'fromvar'},
      );
      expect(
        (outcome.gateway.writes.single['payload'] as Map)['name'],
        'fromvar',
      );
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'channelId': 'x'}),
      ]);
      expect(outcome.error, isA<Exception>());
      expect(
        outcome.error.toString(),
        startsWith('Exception: Failed to update channel: '),
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'archived': 'true'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'x'}),
      ], permissions: 0);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'x'}),
      ], setup: (g) => g.failures['updateChannel'] = StateError('refused'));
      expect(outcome.error.toString(), contains('refused'));
      outcome = await _parity([
        _a(type, {'channelId': '30', 'name': 'x'}, error: {'mode': 'continue'}),
        _a(type, {'channelId': '30', 'name': 'y'}, key: 'after'),
      ], setup: (g) => g.failures['updateChannel'] = StateError('refused'));
      expect(outcome.results!['action_0'], startsWith('Error: '));
      expect(outcome.results!['after'], '30');
    });
  });

  group('removeChannel parity', () {
    const type = BotCreatorActionType.removeChannel;
    test('deletes one channel and returns its id', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30'}, key: 'r'),
      ]);
      expect(outcome.results, {'r': '30'});
      expect(outcome.gateway.writes.single['operation'], 'deleteChannel');
    });

    test('deletes a list of ids, once each, returning the last', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'channelIds': ['30', '33', '30', '((extra))'],
          }),
        ],
        variables: {'extra': '34'},
      );
      expect(outcome.results, {'action_0': '34'});
      expect(outcome.gateway.writes.map((w) => w['id']), ['30', '33', '34']);
    });

    test('deletes channels by name (every match)', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'channelNames': ['dup', '((n))'],
          }),
        ],
        variables: {'n': 'chat'},
      );
      expect(outcome.results, {'action_0': '30'});
      expect(outcome.gateway.writes.map((w) => w['id']), ['33', '34', '30']);
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'channelId': 'abc'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Missing or invalid channelId for removeChannel',
      );
      outcome = await _parity([
        _a(type, {
          'channelNames': ['nothing'],
        }),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: No matching channels found for removeChannel',
      );
      outcome = await _parity([
        _a(type, {
          'channelNames': ['chat'],
        }),
      ], guild: false);
      expect(
        outcome.error.toString(),
        'Exception: Channel names require a guild',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30'}),
      ], permissions: 0);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30'}),
      ], setup: (g) => g.failures['deleteChannel'] = StateError('refused'));
      expect(outcome.error.toString(), contains('refused'));
      outcome = await _parity([_a(type, {})]);
      expect(outcome.error, isA<Exception>());
    });

    group('ticket close', () {
      test('the creator closes it and the markers go away', () async {
        final stores = <_TicketStore>[];
        final outcome = await _parityWithStore(
          [
            _a(type, {'channelId': '30', 'ticketClose': true}, key: 'c'),
          ],
          ticket: true,
          stores: stores,
          variables: {'author.id': '20', 'channel.isTicket': 'true'},
        );
        final store = stores.first;
        expect(outcome.error, isNull);
        expect(outcome.results, {'c': '30'});
        expect(outcome.gateway.writes.single['operation'], 'deleteChannel');
        expect(outcome.variables['channel.isTicket'], 'false');
        expect(
          await store.getScopedVariable('bot', 'channel', '30', '__ticket'),
          isNull,
        );
      });

      test('a stranger cannot close it', () async {
        final outcome = await _parityWithStore(
          [
            _a(type, {'channelId': '30', 'ticketClose': true}),
          ],
          ticket: true,
          variables: {'author.id': '77'},
        );
        expect(
          outcome.error.toString(),
          'Bad state: Only the ticket creator or staff can close it',
        );
        expect(outcome.gateway.writes, isEmpty);
      });

      test('staff can close it', () async {
        final outcome = await _parityWithStore(
          [
            _a(type, {'channelId': '30', 'ticketClose': true}),
          ],
          ticket: true,
          variables: {
            'author.id': '77',
            'member.permissions': 'ManageChannels',
          },
        );
        expect(outcome.error, isNull);
      });

      test('a channel that is not a ticket fails or answers', () async {
        var outcome = await _parityWithStore([
          _a(type, {'channelId': '30', 'ticketClose': true}),
        ]);
        expect(
          outcome.error.toString(),
          'Bad state: This channel is not a ticket',
        );
        outcome = await _parityWithStore([
          _a(type, {
            'channelId': '30',
            'ticketClose': true,
            'errorMessage': 'Not a ticket',
          }, key: 'c'),
        ], fallbackChannelId: Snowflake(30));
        // The answer is attempted (this gateway cannot send messages) and the
        // channel is not deleted.
        expect(outcome.error.toString(), contains('Failed to send message'));
        expect(outcome.gateway.writes, isEmpty);
      });
    });
  });

  group('slowmode parity', () {
    const type = BotCreatorActionType.slowmode;
    test('sets the slowmode of a channel', () async {
      for (final duration in ['5', '10s', '2m', '1h', '0s']) {
        final outcome = await _parity([
          _a(type, {'channelId': '30', 'duration': duration, 'reason': 'Calm'}),
        ]);
        expect(outcome.error, isNull, reason: duration);
        expect(outcome.results, {'action_0': '30'});
      }
    });

    test('resolves placeholders and defaults the duration to zero', () async {
      final outcome = await _parity(
        [
          _a(type, {'channelId': '((c))'}),
        ],
        variables: {'c': '30'},
      );
      expect(outcome.error, isNull);
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'channelId': '30', 'duration': '7h'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: Slowmode duration must be between 0 and 6 hours',
      );
      outcome = await _parity([
        _a(type, {'channelId': 'x', 'duration': '5'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '31', 'duration': '5'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'duration': '5'}),
      ], guild: false);
      expect(
        outcome.error.toString(),
        'Exception: This action requires a guild context',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'duration': '5'}),
      ], permissions: 0);
      expect(outcome.error, isA<Exception>());
    });
  });

  group('editChannelPermissions parity', () {
    const type = BotCreatorActionType.editChannelPermissions;
    test('edits an overwrite from allow / deny masks', () async {
      final outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'targetId': '64',
          'targetType': 'role',
          'allow': '1024',
          'deny': '2048',
        }, key: 'p'),
      ]);
      expect(outcome.results, {'p': 'updated'});
      expect(outcome.gateway.writes.single['operation'], 'editPermissions');
    });

    test('edits an overwrite from the permission map', () async {
      final outcome = await _parity(
        [
          _a(type, {
            'channelId': '30',
            'targetId': '20',
            'targetType': 'user',
            'permissions': {
              'viewChannel': 'allow',
              'sendMessages': '((state))',
              'addReactions': 'unset',
            },
          }),
        ],
        variables: {'state': 'deny'},
      );
      expect(outcome.error, isNull);
    });

    test('targets everyone and the fallback channel', () async {
      final outcome = await _parity([
        _a(type, {'targetType': 'everyone', 'allow': '1024'}),
      ], fallbackChannelId: Snowflake(30));
      expect(outcome.error, isNull);
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'targetId': '64'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': 'x'}),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {
          'channelId': '30',
          'targetId': '64',
          'allow': '1',
          'deny': '1',
        }),
      ]);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': '64', 'targetType': 'role'}),
      ], permissions: 0);
      expect(outcome.error, isA<Exception>());
      outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': '64', 'targetType': 'role'}),
      ], setup: (g) => g.failures['editPermissions'] = StateError('refused'));
      expect(outcome.error.toString(), contains('refused'));
    });
  });

  group('deleteChannelPermission parity', () {
    const type = BotCreatorActionType.deleteChannelPermission;
    test('deletes an overwrite', () async {
      final outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': '64'}, key: 'd'),
      ]);
      expect(outcome.results, {'d': 'deleted'});
      expect(outcome.gateway.writes.single, {
        'operation': 'deletePermission',
        'id': '30',
        'target': '64',
      });
    });

    test('targets everyone, resolves placeholders and the fallback', () async {
      var outcome = await _parity([
        _a(type, {'channelId': '30', 'targetType': 'everyone'}),
      ]);
      expect(outcome.gateway.writes.single['target'], '10');
      outcome = await _parity(
        [
          _a(type, {'targetId': '((t))'}),
        ],
        variables: {'t': '20'},
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.gateway.writes.single['target'], '20');
    });

    test('reports its failures', () async {
      var outcome = await _parity([
        _a(type, {'targetId': '64'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: channelId is required for deleteChannelPermission',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30'}),
      ]);
      expect(
        outcome.error.toString(),
        'Exception: targetId is required for deleteChannelPermission',
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': '64'}),
      ], permissions: 0);
      expect(
        outcome.error.toString(),
        startsWith('Exception: I do not have permission to delete channel'),
      );
      outcome = await _parity([
        _a(type, {'channelId': '30', 'targetId': '64'}),
      ], setup: (g) => g.failures['deletePermission'] = StateError('refused'));
      expect(
        outcome.error.toString(),
        'Exception: Failed to delete channel permission: Bad state: refused',
      );
      outcome = await _parity(
        [
          _a(type, {'channelId': '30', 'targetId': '64'}),
        ],
        guild: false,
        permissions: 0,
      );
      expect(outcome.error, isNull);
    });
  });

  group('inside blocks and policies', () {
    Action ifBlock(List<Action> then) => visualAction(
      BotCreatorActionType.ifBlock,
      key: 'gate',
      payload: {
        'variable': 'flag',
        'operator': 'equals',
        'value': 'yes',
        'thenActions': then.map((a) => a.toJson()).toList(),
      },
    );

    test(
      'native children publish results and mirrors under the block',
      () async {
        final outcome = await _parity(
          [
            ifBlock([
              _a(BotCreatorActionType.createThread, {
                'channelId': '30',
                'name': 'Nested',
              }, key: 'thread'),
              _a(BotCreatorActionType.updateChannel, {
                'channelId': '30',
                'name': 'n',
              }, key: 'chan'),
              _a(BotCreatorActionType.removeChannel, {
                'channelId': '33',
              }, key: 'gone'),
            ]),
          ],
          variables: {'flag': 'yes'},
          expectNative: true,
        );
        expect(outcome.results!['gate.thread'], '700');
        expect(outcome.variables['thread.name'], 'Nested');
      },
    );

    test(
      'a failing nested child ends the block like the historical loop',
      () async {
        final outcome = await _parity(
          [
            ifBlock([
              _a(BotCreatorActionType.createThread, {'name': 'no channel'}),
            ]),
          ],
          variables: {'flag': 'yes'},
        );
        expect(outcome.error.toString(), contains('channelId is required'));
      },
    );

    test('a policy that does not intercept still runs it natively', () async {
      final outcome = await visualParity<VisualGateway>(
        [
          _a(BotCreatorActionType.createThread, {
            'channelId': '30',
            'name': 'x',
          }),
          _a(BotCreatorActionType.slowmode, {
            'channelId': '30',
            'duration': '5',
          }),
        ],
        makeGateway: () => VisualGateway(),
        effects: (g) => g.writes,
        policy: NoHydrationPolicy(),
        compareHistorical: parityWithHistorical,
      );
      _golden.expectOutcome(outcome);
      expect(outcome.error, isNull);
    });
  });
}
