import 'dart:convert';

import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/visual_golden.dart';
import 'helpers/visual_message_gateway.dart' hide messageParity;
import 'helpers/visual_message_gateway.dart' as gw show messageParity;
import 'helpers/visual_parity_harness.dart' show visualAction;

final _golden = GoldenFile('visual_message_send');

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

/// Parity of the sending blocks (wave 3, lot b) between the historical
/// executors and `bc_<type>` on the native engine, over the same recording
/// Discord: sendMessage, sendDm and editMessage.

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
}) => visualAction(type, key: key, payload: payload, error: error);

const _send = BotCreatorActionType.sendMessage;
const _dm = BotCreatorActionType.sendDm;
const _edit = BotCreatorActionType.editMessage;

final _embed = {
  'title': 'Hello ((name))',
  'description': 'Body',
  'color': '#ff0000',
  'footer': {'text': 'foot'},
  'fields': [
    {'name': 'a', 'value': '((name))', 'inline': true},
  ],
};

final _buttons = {
  'components': [
    {
      'type': 'actionRow',
      'components': [
        {'type': 'button', 'label': 'Go', 'style': 'primary', 'customId': 'go'},
      ],
    },
  ],
};

void main() {
  group('sendMessage parity', () {
    test('sends content and records the message id everywhere', () async {
      final outcome = await messageParity(
        [
          _a(_send, {'channelId': '30', 'content': 'Hi ((name))'}, key: 's'),
        ],
        variables: {'name': 'Ana'},
      );
      expect(outcome.results, {'s': '9000'});
      expect(outcome.variables['s.messageId'], '9000');
      expect(outcome.variables['last.response.id'], '9000');
      expect(outcome.variables['lastSentMessageId'], '9000');
      expect((outcome.writes.single['payload'] as Map)['content'], 'Hi Ana');
    });

    test('embeds, components and allowed mentions payloads', () async {
      await messageParity(
        [
          _a(_send, {
            'channelId': '30',
            'content': 'x',
            'embeds': [_embed, _embed],
            'components': _buttons,
            'allowedMentions': {'parse': <String>[]},
          }, key: 's'),
        ],
        variables: {'name': 'Ana'},
      );
    });

    test('rich component V2 mode', () async {
      await messageParity([
        _a(_send, {
          'channelId': '30',
          'messageMode': 'componentV2',
          'componentV2': {
            'components': [
              {'type': 'textDisplay', 'content': 'V2 text'},
            ],
          },
        }, key: 's'),
      ]);
    });

    test('reply, crosspost and typing target types', () async {
      await messageParity(
        [
          _a(_send, {
            'channelId': '30',
            'targetType': 'reply',
            'messageId': '((m))',
            'content': 'reply',
          }, key: 'r'),
          _a(_send, {
            'channelId': '30',
            'targetType': 'crosspost',
            'messageId': '40',
          }, key: 'c'),
          _a(_send, {'channelId': '30', 'targetType': 'typing'}, key: 't'),
        ],
        variables: {'m': '41'},
      );
    });

    test('direct message target', () async {
      final outcome = await messageParity(
        [
          _a(_send, {
            'targetType': 'user',
            'userId': '((u))',
            'content': 'psst',
          }, key: 'd'),
        ],
        variables: {'u': '20'},
      );
      expect(outcome.writes.map((w) => w['operation']), ['createDm', 'send']);
    });

    test('fallback channel when none is given', () async {
      await messageParity([
        _a(_send, {'content': 'fallback'}, key: 's'),
      ], fallbackChannelId: Snowflake(35));
    });

    test('canvas attachments are consumed by the send', () async {
      final outcome = await messageParity(
        [
          _a(_send, {'channelId': '30', 'content': ''}, key: 's'),
          _a(_send, {'channelId': '30', 'content': 'again'}, key: 'again'),
        ],
        variables: {
          'temp._canvasAttachment_card': base64Encode([1, 2, 3]),
        },
      );
      final sends = outcome.writes.where((w) => w['operation'] == 'send');
      expect(sends.first['attachments'], ['card.png:3']);
      expect(sends.last['attachments'], isEmpty);
      expect(
        outcome.variables.containsKey('temp._canvasAttachment_card'),
        isFalse,
      );
    });

    test(
      'empty content is skipped silently, with and without blanks',
      () async {
        final outcome = await messageParity([
          _a(_send, {'channelId': '30', 'content': ''}, key: 'a'),
          _a(_send, {'channelId': '30', 'content': '((missing))'}, key: 'b'),
        ]);
        expect(outcome.results, {'a': '', 'b': ''});
        expect(outcome.writes, isEmpty);
        expect(outcome.variables.containsKey('last.response.id'), isFalse);
      },
    );

    test('errors', () async {
      for (final payload in [
        <String, dynamic>{'content': 'no channel'},
        {'channelId': '31', 'content': 'not text'},
        {'channelId': '999', 'content': 'unknown'},
        {'targetType': 'user', 'userId': 'x', 'content': 'bad'},
        {'channelId': '30', 'targetType': 'crosspost'},
        {'channelId': '31', 'targetType': 'crosspost', 'messageId': '4'},
      ]) {
        final outcome = await messageParity([_a(_send, payload)]);
        expect(outcome.error, isNotNull, reason: '$payload');
      }
    });

    test('a Discord failure surfaces its message', () async {
      final outcome = await messageParity([
        _a(_send, {'channelId': '30', 'content': 'x'}),
      ], setup: (g) => g.failures['send'] = StateError('50013 Missing Access'));
      expect(outcome.errorText, contains('Failed to send message'));
    });

    test('permission pre-check, but not for direct messages', () async {
      final denied = await messageParity([
        _a(_send, {'channelId': '30', 'content': 'x'}),
      ], permissions: 0);
      expect(denied.errorText, contains('send messages'));
      await messageParity([
        _a(_send, {'targetType': 'user', 'userId': '20', 'content': 'x'}),
      ], permissions: 0);
    });

    test('error modes and results used by later actions', () async {
      final outcome = await messageParity([
        _a(
          _send,
          {'channelId': '999', 'content': 'x'},
          error: {'mode': 'continue'},
        ),
        _a(_send, {'channelId': '30', 'content': 'first'}, key: 'first'),
        _a(_send, {
          'channelId': '30',
          'targetType': 'reply',
          'messageId': '((first))',
          'content': 'to ((action.first))',
        }, key: 'second'),
      ]);
      expect(outcome.results!['second'], '9001');
    });

    test('inside ifBlock, loop and try/catch', () async {
      final outcome = await messageParity([
        _a(BotCreatorActionType.forLoop, {
          'mode': 'simple',
          'iterations': '2',
          'bodyActions': [
            _a(_send, {
              'channelId': '30',
              'content': 'n=((_loop.index))',
            }, key: 'm').toJson(),
          ],
        }, key: 'loop'),
        _a(BotCreatorActionType.ifBlock, {
          'tryCatch': true,
          'thenActions': [
            _a(_send, {'channelId': '31', 'content': 'x'}, key: 'bad').toJson(),
          ],
          'elseActions': [
            _a(_send, {
              'channelId': '30',
              'content': 'caught ((error.message))',
            }, key: 'ok').toJson(),
          ],
        }, key: 'try'),
      ], nativePrograms: 2);
      expect(outcome.writes.length, 3);
    });

    test(
      'suppressErrors sends its message and embed natively and immediately',
      () async {
        Action block() => _a(BotCreatorActionType.ifBlock, {
          'variable': 'x',
          'operator': 'equals',
          'value': '1',
          'suppressErrors': true,
          'suppressErrorsMessage': 'Oops ((name))',
          'suppressErrorsEmbed': {'title': 'Failed', 'description': 'd'},
          'thenActions': [
            _a(_send, {'channelId': '31', 'content': 'x'}, key: 'bad').toJson(),
          ],
        }, key: 'cond');
        final variables = {'x': '1', 'name': 'Ana'};
        // Through the interaction (first response, then a follow-up).
        final viaInteraction = await messageParity(
          [
            block(),
            _a(_send, {'channelId': '30', 'content': 'after'}, key: 'after'),
          ],
          variables: variables,
          makeInteraction: FakeInteraction.new,
          nativePrograms: 2,
        );
        expect(viaInteraction.error, isNull);
        expect(viaInteraction.interaction!.calls.first['op'], 'respond');
        // Without an interaction: the resolved fallback channel receives it.
        final viaChannel = await messageParity(
          [block()],
          variables: variables,
          fallbackChannelId: Snowflake(30),
          nativePrograms: 1,
        );
        expect(viaChannel.writes.single['channel'], '30');
        // Both fail the same way when there is nowhere to answer.
        final nowhere = await messageParity([block()], variables: variables);
        expect(nowhere.errorText, contains('No channelId available'));
      },
    );
  });

  group('sendDm parity', () {
    test('one recipient, a list, mirrors', () async {
      final outcome = await messageParity(
        [
          _a(_dm, {'userId': '20', 'content': 'hi ((n))'}, key: 'one'),
          _a(_dm, {
            'userIds': ['20', '((u))'],
            'content': 'all',
          }, key: 'many'),
        ],
        variables: {'n': 'Ana', 'u': '222'},
      );
      expect(outcome.variables['many.messageId'], isNotEmpty);
      expect(outcome.variables['last.response.id'], outcome.results!['many']);
    });

    test('embed and canvas attachment', () async {
      await messageParity(
        [
          _a(_dm, {
            'userId': '20',
            'content': '',
            'embeds': [_embed],
          }, key: 'e'),
        ],
        variables: {
          'name': 'Ana',
          'temp._canvasAttachment_x': base64Encode([9]),
        },
      );
    });

    test('errors', () async {
      for (final payload in [
        <String, dynamic>{'content': 'x'},
        {'userId': 'x', 'content': 'x'},
        {
          'userIds': ['20', ''],
          'content': 'x',
        },
        {'userId': '20', 'content': ''},
      ]) {
        final outcome = await messageParity([_a(_dm, payload)]);
        expect(outcome.error, isNotNull, reason: '$payload');
      }
    });
  });

  group('editMessage parity', () {
    test('edits content, embeds and components', () async {
      await messageParity(
        [
          _a(_edit, {
            'channelId': '30',
            'messageId': '41',
            'content': 'edited ((name))',
          }, key: 'a'),
          _a(_edit, {
            'channelId': '30',
            'messageId': '41',
            'embeds': [_embed],
            'components': _buttons,
          }, key: 'b'),
          _a(_edit, {
            'channelId': '30',
            'messageId': '41',
            'clearEmbeds': true,
            'clearComponents': true,
          }, key: 'c'),
        ],
        variables: {'name': 'Ana'},
      );
    });

    test('message id from an earlier result', () async {
      final outcome = await messageParity([
        _a(_send, {'channelId': '30', 'content': 'one'}, key: 'first'),
        _a(_edit, {
          'channelId': '30',
          'messageId': '40',
          'content': 'x ((first))',
        }, key: 'e'),
      ]);
      expect(outcome.results!['e'], '40');
    });

    test('delayed edit is scheduled', () async {
      final outcome = await messageParity([
        _a(_edit, {
          'channelId': '30',
          'messageId': '41',
          'bdfdDelayedEdit': true,
          'delay': '1h',
          'content': 'later',
        }, key: 'e'),
      ]);
      expect(outcome.results, {'e': 'scheduled'});
      expect(outcome.variables['action.e.status'], 'scheduled');
    });

    test('errors', () async {
      for (final payload in [
        <String, dynamic>{'content': 'x'},
        {'channelId': '31', 'messageId': '40', 'content': 'x'},
        {'channelId': '30', 'messageId': '999', 'content': 'x'},
        {
          'channelId': '30',
          'messageId': '41',
          'bdfdDelayedEdit': true,
          'delay': '5h',
          'content': 'x',
        },
        {
          'channelId': '30',
          'bdfdDelayedEdit': true,
          'delay': '1s',
          'content': 'x',
        },
      ]) {
        final outcome = await messageParity([_a(_edit, payload)]);
        expect(outcome.error, isNotNull, reason: '$payload');
      }
    });
  });
}
