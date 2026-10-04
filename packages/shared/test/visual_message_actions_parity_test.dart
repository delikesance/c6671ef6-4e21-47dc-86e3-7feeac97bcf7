import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_golden.dart';
import 'helpers/visual_message_gateway.dart' hide messageParity;
import 'helpers/visual_message_gateway.dart' as gw show messageParity;
import 'helpers/visual_parity_harness.dart' show visualAction;

final _golden = GoldenFile('visual_message_actions');

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
  final outcome = await gw.messageParity(
    actions,
    permissions: permissions,
    setup: setup,
    makeInteraction: makeInteraction,
    variables: variables,
    guild: guild,
    throwOnError: throwOnError,
    fallbackChannelId: fallbackChannelId,
    expectNative: expectNative,
    nativePrograms: nativePrograms,
    compareHistorical: parityWithHistorical,
  );
  _golden.expectMessage(outcome);
  return outcome;
}

/// Parity of the messaging blocks (wave 3, lot a) between the historical
/// executors and `bc_<type>` on the native engine, over the same recording
/// Discord: addReaction, removeReaction, clearAllReactions, pinMessage,
/// unpinMessage, deleteMessages, deleteTrigger and getMessage.

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

void main() {
  group('addReaction parity', () {
    const type = BotCreatorActionType.addReaction;
    test('adds one emoji and a list, custom emoji escaping cleaned', () async {
      final outcome = await messageParity([
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '👍',
        }, key: 'one'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emojis': ['<;:party:123>;', '🎉;🔥'],
        }, key: 'many'),
      ]);
      expect(outcome.results, {'one': 'OK', 'many': 'OK'});
      expect(outcome.writes.map((w) => w['emoji']), [
        '👍:null',
        'party:123',
        '🎉:null',
        '🔥:null',
      ]);
    });

    test('templates, fallback channel and result placeholders', () async {
      await messageParity(
        [
          _a(type, {'messageId': '((msg))', 'emoji': '((e))'}, key: 'r'),
        ],
        variables: {'msg': '41', 'e': '❤'},
        fallbackChannelId: Snowflake(30),
      );
    });

    test(
      'errors: missing ids, bad emoji, unknown message, partial failure',
      () async {
        for (final payload in [
          {'emoji': '👍'},
          {'channelId': '30', 'messageId': 'x', 'emoji': '👍'},
          {'channelId': '30', 'messageId': '40', 'emoji': ' '},
          {'channelId': '31', 'messageId': '40', 'emoji': '👍'},
          {'channelId': '30', 'messageId': '999', 'emoji': '👍'},
        ]) {
          final outcome = await messageParity([_a(type, payload, key: 'r')]);
          expect(outcome.error, isNotNull, reason: '$payload');
        }
      },
    );

    test('a Discord failure on the second emoji aggregates', () async {
      final outcome = await messageParity([
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emojis': ['👍', '🔥'],
        }),
      ], setup: (g) => g.failures['react'] = StateError('rate limited'));
      expect(outcome.errorText, contains('Failed to add some reactions'));
    });

    test('permission pre-check', () async {
      final outcome = await messageParity([
        _a(type, {'channelId': '30', 'messageId': '40', 'emoji': '👍'}),
      ], permissions: 0);
      expect(outcome.errorText, contains('add reactions'));
      expect(outcome.writes, isEmpty);
    });

    test('error modes continue, skip and jump behave like the loop', () async {
      for (final error in [
        {'mode': 'continue'},
        {'mode': 'skip', 'skipCount': '1'},
        {'mode': 'jump', 'jumpToActionId': 'end'},
      ]) {
        final outcome = await messageParity([
          _a(type, {
            'channelId': '30',
            'messageId': '999',
            'emoji': '👍',
          }, error: error),
          _a(type, {
            'channelId': '30',
            'messageId': '40',
            'emoji': '1',
          }, key: 'skipped'),
          _a(type, {
            'channelId': '30',
            'messageId': '41',
            'emoji': '2',
          }, key: 'end'),
        ]);
        expect(outcome.error, isNull);
      }
    });

    test('inside an ifBlock the block is native too', () async {
      final outcome = await messageParity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'x',
            'operator': 'equals',
            'value': '1',
            'thenActions': [
              _a(type, {
                'channelId': '30',
                'messageId': '40',
                'emoji': '👍',
              }, key: 'r').toJson(),
            ],
          }, key: 'cond'),
        ],
        variables: {'x': '1'},
        nativePrograms: 1,
      );
      expect(outcome.results!['cond.r'], 'OK');
    });
  });

  group('removeReaction parity', () {
    const type = BotCreatorActionType.removeReaction;
    test('removes a reaction of a user, of anybody, or the bot own', () async {
      await messageParity([
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '👍',
          'userId': '20',
        }, key: 'u'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '<a:wave:99>',
        }, key: 'all'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '🔥',
          'removeOwn': true,
        }, key: 'own'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '🔥',
          'removeOwn': true,
          'userId': '20',
        }, key: 'both'),
      ]);
    });
    test('errors', () async {
      for (final payload in [
        {'emoji': '👍'},
        {'channelId': '30', 'messageId': '40', 'emoji': ''},
        {'channelId': '31', 'messageId': '40', 'emoji': '👍'},
        {'channelId': '30', 'messageId': '123', 'emoji': '👍'},
      ]) {
        final outcome = await messageParity([_a(type, payload)]);
        expect(outcome.error, isNotNull);
      }
    });
    test('does not run the guild permission pre-check', () async {
      final outcome = await messageParity([
        _a(type, {'channelId': '30', 'messageId': '40', 'emoji': '👍'}),
      ], permissions: 0);
      expect(outcome.error, isNull);
    });
  });

  group('clearAllReactions parity', () {
    const type = BotCreatorActionType.clearAllReactions;
    test('clears everything, or one emoji', () async {
      await messageParity([
        _a(type, {'channelId': '30', 'messageId': '40'}, key: 'a'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '!all',
        }, key: 'b'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '🔥',
        }, key: 'c'),
        _a(type, {
          'channelId': '30',
          'messageId': '40',
          'emoji': '<:x:7>',
        }, key: 'd'),
      ]);
    });
    test('errors and permission', () async {
      for (final payload in [
        {'messageId': '40'},
        {'channelId': '31', 'messageId': '40'},
        {'channelId': '30', 'messageId': '123'},
      ]) {
        final outcome = await messageParity([_a(type, payload)]);
        expect(outcome.error, isNotNull);
      }
      final denied = await messageParity([
        _a(type, {'channelId': '30', 'messageId': '40'}),
      ], permissions: 0);
      expect(denied.errorText, contains('clear reactions'));
    });
  });

  group('pinMessage / unpinMessage parity', () {
    test('pin and unpin with and without a reason', () async {
      final outcome = await messageParity([
        _a(BotCreatorActionType.pinMessage, {
          'channelId': '30',
          'messageId': '40',
        }, key: 'p1'),
        _a(BotCreatorActionType.pinMessage, {
          'channelId': '30',
          'messageId': '41',
          'reason': ' why ',
        }, key: 'p2'),
        _a(BotCreatorActionType.unpinMessage, {
          'channelId': '30',
          'messageId': '42',
        }, key: 'u1'),
        _a(BotCreatorActionType.unpinMessage, {
          'channelId': '30',
          'messageId': '43',
          'reason': 'bye',
        }, key: 'u2'),
      ]);
      expect(outcome.results, {
        'p1': '40',
        'p2': '41',
        'u1': 'unpinned',
        'u2': 'unpinned',
      });
      // Switch-handled historically: no "last message" bookkeeping.
      expect(outcome.variables.containsKey('lastSentMessageId'), isFalse);
    });

    test(
      'the loop fallback channel differs: pin raw, unpin resolved',
      () async {
        // No interaction: both raw. They still use the explicit fallback.
        await messageParity([
          _a(BotCreatorActionType.pinMessage, {'messageId': '40'}, key: 'p'),
          _a(BotCreatorActionType.unpinMessage, {'messageId': '42'}, key: 'u'),
        ], fallbackChannelId: Snowflake(30));
      },
    );

    test('with an interaction channel only unpin finds it', () async {
      for (final type in [
        BotCreatorActionType.pinMessage,
        BotCreatorActionType.unpinMessage,
      ]) {
        await messageParity([
          _a(type, {'messageId': '40'}, key: 'x'),
        ], makeInteraction: FakeInteraction.new);
      }
    });

    test('errors and permissions', () async {
      for (final type in [
        BotCreatorActionType.pinMessage,
        BotCreatorActionType.unpinMessage,
      ]) {
        for (final payload in [
          {'channelId': '30'},
          {'messageId': '40'},
          {'channelId': '31', 'messageId': '40'},
        ]) {
          final outcome = await messageParity([_a(type, payload)]);
          expect(outcome.error, isNotNull);
        }
        final denied = await messageParity([
          _a(type, {'channelId': '30', 'messageId': '40'}),
        ], permissions: 0);
        expect(denied.errorText, contains('I do not have permission'));
      }
    });

    test('nested in a loop the block is native', () async {
      await messageParity([
        _a(BotCreatorActionType.forLoop, {
          'mode': 'simple',
          'iterations': '2',
          'bodyActions': [
            _a(BotCreatorActionType.pinMessage, {
              'channelId': '30',
              'messageId': '40',
            }, key: 'p').toJson(),
          ],
        }, key: 'loop'),
      ], nativePrograms: 1);
    });
  });

  group('deleteMessages parity', () {
    const type = BotCreatorActionType.deleteMessages;
    test('single message, bulk count, filters and flags', () async {
      final cases = <Map<String, dynamic>>[
        {'channelId': '30', 'messageId': '40'},
        {'channelId': '30', 'messageCount': 3},
        {'channelId': '30', 'count': '2', 'onlyUserId': '20'},
        {'channelId': '30', 'messageCount': 4, 'filterBots': 'true'},
        {'channelId': '30', 'messageCount': 4, 'filterUsers': 'true'},
        {'channelId': '30', 'messageCount': 4, 'removePinned': 'no'},
        {'channelId': '30', 'messageCount': 2, 'beforeMessageId': '43'},
        {
          'channelId': '30',
          'messageCount': 2,
          'beforeMessageId': '43',
          'deleteItself': 'yes',
        },
        {'channelId': '30', 'messageCount': 2, 'reason': ' tidy '},
        {'channelId': '30', 'messageCount': '((n))'},
        {'channelId': '30', 'messageCount': 2, 'bdfdClear': true},
      ];
      for (final payload in cases) {
        final outcome = await messageParity(
          [_a(type, payload, key: 'd')],
          variables: {'n': '2'},
        );
        expect(outcome.error, isNull, reason: '$payload');
      }
    });

    test('mirrors count and mode into variables', () async {
      final outcome = await messageParity([
        _a(type, {
          'channelId': '30',
          'messageCount': 3,
          'deleteItself': 'true',
        }, key: 'd'),
      ]);
      expect(outcome.variables['d.count'], '3');
      expect(outcome.variables['action.d.mode'], 'bulk');
      expect(outcome.variables['d.deleteItself'], 'true');
    });

    test('delayed deletion is scheduled', () async {
      final outcome = await messageParity([
        _a(type, {
          'channelId': '30',
          'messageCount': 2,
          'delay': '1h',
        }, key: 'd'),
      ]);
      expect(outcome.results, {'d': 'scheduled'});
      expect(outcome.variables['action.d.status'], 'scheduled');
    });

    test('errors', () async {
      for (final payload in [
        <String, dynamic>{},
        {'channelId': '30', 'messageCount': 0, 'bdfdClear': true},
        {'channelId': '30', 'messageCount': 101, 'bdfdClear': true},
        {'channelId': '31', 'messageCount': 2},
        {'channelId': '30'},
      ]) {
        final outcome = await messageParity([_a(type, payload)]);
        expect(outcome.error, isNotNull, reason: '$payload');
      }
      final denied = await messageParity([
        _a(type, {'channelId': '30', 'messageCount': 2}),
      ], permissions: 0);
      expect(denied.errorText, contains('delete messages'));
    });
  });

  group('deleteTrigger parity', () {
    const type = BotCreatorActionType.deleteTrigger;
    test('deletes the trigger message', () async {
      final outcome = await messageParity(
        [_a(type, {}, key: 't')],
        variables: {'message.id': '40', 'channel.id': '30'},
      );
      expect(outcome.results, {'t': '40'});
    });
    test('NOT_FOUND, INVALID_CHANNEL and swallowed failures', () async {
      expect((await messageParity([_a(type, {}, key: 't')])).results, {
        't': 'NOT_FOUND',
      });
      expect(
        (await messageParity(
          [_a(type, {}, key: 't')],
          variables: {'message.id': '40', 'channel.id': '31'},
        )).results,
        {'t': 'INVALID_CHANNEL'},
      );
      expect(
        (await messageParity(
          [_a(type, {}, key: 't')],
          variables: {'message.id': '999', 'channel.id': '30'},
        )).results,
        {'t': '999'},
      );
      expect(
        (await messageParity(
          [_a(type, {}, key: 't')],
          variables: {'messageId': '40'},
          fallbackChannelId: Snowflake(30),
        )).results,
        {'t': '40'},
      );
    });
  });

  group('getMessage parity', () {
    const type = BotCreatorActionType.getMessage;
    test('stores every field', () async {
      final outcome = await messageParity([
        _a(type, {'channelId': '30', 'messageId': '41'}, key: 'm'),
      ]);
      expect(outcome.results, {'m': '41'});
      expect(outcome.variables['m.content'], 'message 41');
      expect(outcome.variables['m.authorId'], '500');
      expect(outcome.variables['m.authorUsername'], 'author');
      expect(outcome.variables['m.messageId'], '41');
      expect(outcome.variables['lastSentMessageId'], '41');
    });
    test('placeholders and errors', () async {
      await messageParity(
        [
          _a(type, {'messageId': '((id))'}, key: 'm'),
        ],
        variables: {'id': '40'},
        fallbackChannelId: Snowflake(30),
      );
      for (final payload in [
        <String, dynamic>{},
        {'channelId': '30'},
        {'channelId': '31', 'messageId': '40'},
        {'channelId': '30', 'messageId': '999'},
      ]) {
        final outcome = await messageParity([_a(type, payload)]);
        expect(outcome.error, isNotNull);
      }
    });
  });

  group('lot a mixed with control flow', () {
    test('suppressErrors swallows a failing reaction natively', () async {
      final outcome = await messageParity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'x',
            'operator': 'equals',
            'value': '1',
            'suppressErrors': true,
            'thenActions': [
              _a(BotCreatorActionType.addReaction, {
                'channelId': '30',
                'messageId': '999',
                'emoji': '👍',
              }, key: 'r').toJson(),
            ],
          }, key: 'cond'),
        ],
        variables: {'x': '1'},
        nativePrograms: 1,
      );
      expect(outcome.error, isNull);
    });
    test('try/catch exposes the error text', () async {
      await messageParity([
        _a(BotCreatorActionType.ifBlock, {
          'tryCatch': true,
          'thenActions': [
            _a(BotCreatorActionType.pinMessage, {
              'channelId': '30',
              'messageId': '999',
            }, key: 'p').toJson(),
          ],
          'elseActions': [
            _a(BotCreatorActionType.addReaction, {
              'channelId': '30',
              'messageId': '40',
              'emoji': '((error.message))',
            }, key: 'r').toJson(),
          ],
        }, key: 'try'),
      ], nativePrograms: 1);
    });
  });
}
