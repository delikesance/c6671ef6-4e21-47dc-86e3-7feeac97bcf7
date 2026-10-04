import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

import 'helpers/golden_expectations.dart';
import 'helpers/visual_parity_harness.dart' show visualAction;
import 'helpers/visual_resource_gateway.dart';

/// Parity of the webhook, emoji, member and invite blocks (wave 9a) between the
/// historical executors and `bc_<type>` on the native engine, over the same
/// recording Discord.

Action _a(
  BotCreatorActionType type,
  Map<String, dynamic> payload, {
  String? key,
  Map<String, String> error = const {},
}) => visualAction(type, key: key, payload: payload, error: error);

// 1x1 transparent PNG.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

const _errorModes = [
  {'mode': 'continue'},
  {'mode': 'skip', 'skipCount': '1'},
  {'mode': 'jump', 'jumpToActionId': 'end'},
];

void main() {
  useGolden('resource');
  group('webhook blocks', () {
    gtest('sendWebhook by id+token, by url, with templates', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.sendWebhook, {
            'webhookId': '70',
            'token': 'tok',
            'content': 'hello ((who))',
            'username': 'Bot',
            'wait': 'true',
            'embeds': [
              {'title': 'T', 'description': 'D', 'color': '#ff0000'},
            ],
          }, key: 'a'),
          _a(BotCreatorActionType.sendWebhook, {
            'webhookUrl': 'https://discord.com/api/webhooks/71/tok2',
            'content': 'x',
            'threadId': '30',
          }, key: 'b'),
        ],
        variables: {'who': 'world'},
      );
      expect(outcome.results, {'a': '70', 'b': '71'});
      expect(outcome.gateway.writes, hasLength(2));
    });

    gtest('sendWebhook errors', () async {
      for (final payload in [
        {'content': 'x'},
        {'webhookId': '70', 'content': 'x'},
      ]) {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.sendWebhook, payload),
        ]);
        expect(outcome.errorText, contains('Missing webhookId/token'));
      }
    });

    gtest('editWebhook, deleteWebhook and getWebhook', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.editWebhook, {
            'webhookId': '((id))',
            'token': 'tok',
            'name': 'renamed',
            'channelId': '30',
            'reason': 'because',
          }, key: 'edit'),
          _a(BotCreatorActionType.getWebhook, {
            'webhookUrl': 'https://discord.com/api/webhooks/70/tok',
          }, key: 'get'),
          _a(BotCreatorActionType.deleteWebhook, {
            'webhookId': '70',
            'reason': 'bye',
          }, key: 'del'),
        ],
        variables: {'id': '70'},
      );
      expect(outcome.results!['get'], contains('"name":"hook"'));
      // The webhook URL is a `Uri`: it must be serialized as a string.
      expect(
        outcome.results!['get'],
        contains('"url":"https://discord.com/api/webhooks/70/tok"'),
      );
      expect(outcome.results!['del'], '70');
    });

    gtest(
      'listWebhooks by channel, by guild and with the fallback channel',
      () async {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.listWebhooks, {'channelId': '30'}, key: 'c'),
          _a(BotCreatorActionType.listWebhooks, {}, key: 'g'),
          _a(BotCreatorActionType.listWebhooks, {'guildId': '10'}, key: 'h'),
        ]);
        expect(outcome.results!['c'], contains('"id":"70"'));
        expect(
          outcome.results!['c'],
          contains('"url":"https://discord.com/api/webhooks/70/tok"'),
        );
        await resourceParity([
          _a(BotCreatorActionType.listWebhooks, {}, key: 'f'),
        ], fallbackChannelId: Snowflake(30));
        await resourceParity([
          _a(BotCreatorActionType.listWebhooks, {}, key: 'none'),
        ], guild: false);
      },
    );

    gtest('permission pre-check of listWebhooks', () async {
      final outcome = await resourceParity([
        _a(BotCreatorActionType.listWebhooks, {'channelId': '30'}),
      ], permissions: 0);
      expect(outcome.errorText, contains('list webhooks'));
      expect(outcome.gateway.writes, isEmpty);
    });

    gtest('failures: unknown webhook, missing ids', () async {
      for (final action in [
        _a(BotCreatorActionType.getWebhook, {'webhookId': '999'}),
        _a(BotCreatorActionType.getWebhook, {}),
        _a(BotCreatorActionType.editWebhook, {}),
        _a(BotCreatorActionType.deleteWebhook, {}),
      ]) {
        final outcome = await resourceParity([action]);
        expect(outcome.error, isNotNull);
      }
      final failing = await resourceParity([
        _a(BotCreatorActionType.deleteWebhook, {'webhookId': '70'}),
      ], setup: (g) => g.failures['deleteWebhook'] = StateError('denied'));
      expect(failing.errorText, contains('Failed to delete webhook'));
    });

    gtest('error modes behave like the loop', () async {
      for (final error in _errorModes) {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.getWebhook, {
            'webhookId': '999',
          }, error: error),
          _a(BotCreatorActionType.getWebhook, {
            'webhookId': '70',
          }, key: 'skipped'),
          _a(BotCreatorActionType.getWebhook, {'webhookId': '70'}, key: 'end'),
        ]);
        expect(outcome.error, isNull);
      }
    });

    gtest('inside an ifBlock the block is native too', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.ifBlock, {
            'variable': 'x',
            'operator': 'equals',
            'value': '1',
            'thenActions': [
              _a(BotCreatorActionType.listWebhooks, {}, key: 'l').toJson(),
            ],
          }, key: 'cond'),
        ],
        variables: {'x': '1'},
        nativePrograms: 1,
        fallbackChannelId: Snowflake(30),
      );
      expect(outcome.results!['cond.l'], contains('"id":"70"'));
    });
  });

  group('emoji blocks', () {
    gtest('createEmoji, updateEmoji and deleteEmoji', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.createEmoji, {
            'name': 'party',
            'imageBase64': _png,
            'roles': ['64'],
            'reason': 'new',
          }, key: 'c'),
          _a(BotCreatorActionType.updateEmoji, {
            'emojiId': '80',
            'name': '((n))',
            'roles': '64,65',
          }, key: 'u'),
          _a(BotCreatorActionType.deleteEmoji, {'emojiId': '80'}, key: 'd'),
          _a(BotCreatorActionType.deleteEmoji, {'emojiId': 'smile'}, key: 'dn'),
        ],
        variables: {'n': 'renamed'},
      );
      expect(outcome.results!['c.emojiId'], '81');
      expect(outcome.results!['c'], contains('"status":"created"'));
      expect(outcome.results!['d.status'], 'deleted');
      expect(outcome.results!['dn.emojiId'], '80');
    });

    gtest('errors: guild, name, image, id, unknown name, permission', () async {
      for (final action in [
        _a(BotCreatorActionType.createEmoji, {'imageBase64': _png}),
        _a(BotCreatorActionType.createEmoji, {'name': 'x'}),
        _a(BotCreatorActionType.updateEmoji, {'name': 'x'}),
        _a(BotCreatorActionType.deleteEmoji, {}),
        _a(BotCreatorActionType.deleteEmoji, {'emojiId': 'nope'}),
      ]) {
        final outcome = await resourceParity([action]);
        expect(outcome.error, isNotNull);
      }
      final noGuild = await resourceParity([
        _a(BotCreatorActionType.deleteEmoji, {'emojiId': '80'}),
      ], guild: false);
      expect(noGuild.errorText, contains('requires a guild context'));
      final denied = await resourceParity([
        _a(BotCreatorActionType.deleteEmoji, {'emojiId': '80'}),
      ], permissions: 0);
      expect(denied.errorText, contains('manage emojis'));
      final failing = await resourceParity([
        _a(BotCreatorActionType.deleteEmoji, {'emojiId': '80'}),
      ], setup: (g) => g.failures['deleteEmoji'] = StateError('rate limited'));
      expect(failing.errorText, contains('Failed to delete emoji'));
    });

    gtest('error modes behave like the loop', () async {
      for (final error in _errorModes) {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.deleteEmoji, {}, error: error),
          _a(BotCreatorActionType.deleteEmoji, {
            'emojiId': '80',
          }, key: 'skipped'),
          _a(BotCreatorActionType.deleteEmoji, {'emojiId': '80'}, key: 'end'),
        ]);
        expect(outcome.error, isNull);
      }
    });
  });

  group('member blocks', () {
    gtest('listMembers lists, limits, searches, paginates', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.listMembers, {}, key: 'all'),
          _a(BotCreatorActionType.listMembers, {'limit': '((n))'}, key: 'one'),
          _a(BotCreatorActionType.listMembers, {'after': '20'}, key: 'after'),
          _a(BotCreatorActionType.listMembers, {'query': 'alice'}, key: 'q'),
        ],
        variables: {'n': '1'},
      );
      expect(outcome.results!['all'], contains('"userId":"20"'));
    });

    gtest('listMembers errors: no guild', () async {
      final outcome = await resourceParity([
        _a(BotCreatorActionType.listMembers, {}),
      ], guild: false);
      expect(outcome.errorText, contains('Missing guildId'));
    });

    gtest('getMember by userId, memberId, template; errors', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.getMember, {'userId': '20'}, key: 'u'),
          _a(BotCreatorActionType.getMember, {'memberId': '((m))'}, key: 'm'),
        ],
        variables: {'m': '222'},
      );
      expect(outcome.results!['u'], contains('"nick":"Twenty"'));
      for (final payload in [
        <String, dynamic>{},
        {'userId': '12345'},
      ]) {
        final failed = await resourceParity([
          _a(BotCreatorActionType.getMember, payload),
        ]);
        expect(failed.error, isNotNull);
      }
    });

    gtest('error modes behave like the loop', () async {
      for (final error in _errorModes) {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.getMember, {}, error: error),
          _a(BotCreatorActionType.getMember, {'userId': '20'}, key: 'skipped'),
          _a(BotCreatorActionType.getMember, {'userId': '20'}, key: 'end'),
        ]);
        expect(outcome.error, isNull);
      }
    });
  });

  group('invite blocks', () {
    gtest('createInvite mirrors its fields into variables', () async {
      final outcome = await resourceParity([
        _a(BotCreatorActionType.createInvite, {
          'channelId': '30',
          'maxAge': '3600',
          'maxUses': '5',
          'temporary': 'true',
          'unique': '1',
          'reason': 'r',
        }, key: 'inv'),
        _a(BotCreatorActionType.createInvite, {}, key: 'fallback'),
      ], fallbackChannelId: Snowflake(30));
      expect(outcome.results!['inv'], 'newcode');
      expect(outcome.variables['inv.url'], 'https://discord.gg/newcode');
    });

    gtest('getInvite and deleteInvite', () async {
      final outcome = await resourceParity(
        [
          _a(BotCreatorActionType.getInvite, {'inviteCode': '((c))'}, key: 'g'),
          _a(BotCreatorActionType.deleteInvite, {
            'inviteCode': 'abc',
            'reason': 'x',
          }, key: 'd'),
        ],
        variables: {'c': 'abc'},
      );
      expect(outcome.results, {'g': 'abc', 'd': 'deleted'});
      expect(outcome.variables['g.expiresAt'], '2030-01-02T00:00:00.000Z');
    });

    gtest('errors: channel, code, permission, discord failure', () async {
      for (final action in [
        _a(BotCreatorActionType.createInvite, {}),
        _a(BotCreatorActionType.createInvite, {'channelId': '31'}),
        _a(BotCreatorActionType.getInvite, {}),
        _a(BotCreatorActionType.getInvite, {'inviteCode': 'zzz'}),
        _a(BotCreatorActionType.deleteInvite, {}),
      ]) {
        final outcome = await resourceParity([action]);
        expect(outcome.error, isNotNull);
      }
      for (final action in [
        _a(BotCreatorActionType.createInvite, {'channelId': '30'}),
        _a(BotCreatorActionType.deleteInvite, {'inviteCode': 'abc'}),
      ]) {
        final outcome = await resourceParity([action], permissions: 0);
        expect(outcome.errorText, contains('invites'));
      }
      final failing = await resourceParity([
        _a(BotCreatorActionType.deleteInvite, {'inviteCode': 'abc'}),
      ], setup: (g) => g.failures['deleteInvite'] = StateError('nope'));
      expect(failing.errorText, contains('Failed to delete invite'));
    });

    gtest('error modes behave like the loop', () async {
      for (final error in _errorModes) {
        final outcome = await resourceParity([
          _a(BotCreatorActionType.getInvite, {}, error: error),
          _a(BotCreatorActionType.getInvite, {
            'inviteCode': 'abc',
          }, key: 'skipped'),
          _a(BotCreatorActionType.getInvite, {'inviteCode': 'abc'}, key: 'end'),
        ]);
        expect(outcome.error, isNull);
      }
    });
  });

  group('trace bookkeeping', () {
    gtest(
      'a numeric result is the "last message" only where the loop did',
      () async {
        // deleteWebhook traces always (webhook executor); getInvite is a
        // switch-handled type that traces only under a debug profile.
        final webhook = await resourceParity([
          _a(BotCreatorActionType.deleteWebhook, {'webhookId': '70'}),
        ]);
        expect(webhook.variables['lastMessageId'], '70');
        final invite = await resourceParity([
          _a(BotCreatorActionType.getInvite, {'inviteCode': '12345'}),
        ]);
        expect(invite.variables.containsKey('lastMessageId'), isFalse);
      },
    );
  });
}
