import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:test/test.dart';

Map<String, dynamic> _entities([Map<String, dynamic>? guild]) => {
  'guilds': {
    '10': {
      'channels': [
        {'id': '30', 'type': 'text', 'name': 'general'},
        {'id': '31', 'type': 'voice', 'name': 'vocal'},
        {'id': '32', 'type': 'voice', 'name': 'autre'},
      ],
      'roles': [
        {'id': '50', 'name': 'Mod'},
      ],
      'members': {
        '100': {
          'username': 'alice',
          'nick': 'Al',
          'roles': ['50'],
          'voice': {'channel_id': '31'},
        },
        '101': {'username': 'bob'},
      },
      'messages': {
        '30': [
          {
            'id': '900',
            'author_id': '100',
            'content': 'salut',
            'timestamp': '2026-01-01T00:00:00Z',
          },
        ],
      },
      ...?guild,
    },
  },
};

Future<Map<String, dynamic>> _run(
  List<Map<String, dynamic>> actions, {
  Map<String, dynamic>? guild,
}) => testCommandInSandbox({
  'actions': actions,
  'variables': {'guild.id': '10', 'channel.id': '30', 'bot.id': '999'},
  'entities': _entities(guild),
});

Map<String, dynamic> _a(
  String type,
  Map<String, dynamic> payload, [
  String key = 'r',
]) => {'type': type, 'key': key, 'payload': payload};

void main() {
  _guildMemberContext();
  test(
    'reads: getMessage, getMember and listMembers use the fixtures',
    () async {
      final r = await _run([
        _a('getMessage', {'messageId': '900'}, 'm'),
        _a('getMember', {'userId': '100'}, 'u'),
        _a('listMembers', {'query': 'bo'}, 'l'),
      ]);
      expect(r['success'], true, reason: '$r');
      expect(r['results']['m.content'], 'salut');
      expect(r['results']['m.authorUsername'], 'alice');
      expect(r['results']['u'], contains('"displayName":"Al"'));
      expect(r['results']['u'], contains('"roleIds":["50"]'));
      expect(
        r['results']['l'],
        allOf(contains('bob'), isNot(contains('alice'))),
      );
      expect(r['effects'], isEmpty);
    },
  );

  test('a missing fixture says exactly which key to provide', () async {
    final r = await testCommandInSandbox({
      'actions': [
        _a('getMessage', {'messageId': '1', 'channelId': '30'}),
      ],
      'variables': {'guild.id': '10'},
      'entities': {
        'guilds': {
          '10': {'members': <String, dynamic>{}},
        },
      },
    });
    expect(r['success'], false);
    expect(
      r['error'],
      contains('entities.guilds.<guildId>.messages.<channelId>'),
    );
    final bad = await _run([
      _a('getMember', {'userId': '777'}),
    ]);
    expect(bad['error'], contains('"777" is absent'));
  });

  test('polls: create validates, end changes the state', () async {
    final ok = await _run([
      _a('createPoll', {
        'question': 'Pizza ?',
        'answers': ['oui', 'non'],
        'durationHours': 2,
      }, 'p'),
    ]);
    expect(ok['success'], true, reason: '$ok');
    expect(ok['results']['p.pollId'], isNotEmpty);
    expect((ok['effects'] as List).single['type'], 'createPoll');
    for (final answers in [
      <String>['seul'],
      <String>[],
    ]) {
      final bad = await _run([
        _a('createPoll', {'question': 'Q', 'answers': answers}),
      ]);
      expect(bad['error'], contains('2 to 10 answers'));
    }
    final ended = await _run(
      [
        _a('endPoll', {'messageId': '901'}),
      ],
      guild: {
        'messages': {
          '30': [
            {
              'id': '901',
              'author_id': '999',
              'poll': {
                'question': 'Q',
                'answers': ['a', 'b'],
              },
            },
          ],
        },
      },
    );
    expect(ended['success'], true, reason: '$ended');
    expect(ended['results']['r'], 'ended');
    final twice = await _run(
      [
        _a('endPoll', {'messageId': '901'}, 'a'),
        _a('endPoll', {'messageId': '901'}, 'b'),
      ],
      guild: {
        'messages': {
          '30': [
            {
              'id': '901',
              'poll': {
                'question': 'Q',
                'answers': ['a', 'b'],
              },
            },
          ],
        },
      },
    );
    expect(twice['error'], contains('already ended'));
  });

  test('invites: create then get then delete in one run', () async {
    final r = await _run([
      _a('createInvite', {'maxAge': 3600, 'maxUses': 5}, 'i'),
      _a('getInvite', {'inviteCode': '((action.i.inviteCode))'}, 'g'),
      _a('deleteInvite', {'inviteCode': '((action.i.inviteCode))'}, 'd'),
    ]);
    expect(r['success'], true, reason: '$r');
    expect(r['results']['i.url'], startsWith('https://discord.gg/sbx'));
    expect(r['results']['g.channelId'], '30');
    expect(r['results']['d'], 'deleted');
    expect((r['effects'] as List).map((e) => e['type']), [
      'createInvite',
      'deleteInvite',
    ]);
    final bad = await _run([
      _a('createInvite', {'maxAge': 9999999}),
    ]);
    expect(bad['error'], contains('maxAge'));
    final missing = await _run(
      [
        _a('deleteInvite', {'inviteCode': 'nope'}),
      ],
      guild: {'invites': <String, dynamic>{}},
    );
    expect(missing['error'], contains('"nope" is absent'));
  });

  test(
    'voice: move, mute, deafen and disconnect follow the voice state',
    () async {
      final r = await _run([
        _a('moveToVoiceChannel', {
          'userId': '100',
          'targetChannelId': '32',
        }, 'm'),
        _a('serverMuteMember', {'userId': '100'}, 'x'),
        _a('serverDeafenMember', {'userId': '100', 'deaf': false}, 'y'),
        _a('disconnectFromVoice', {'userId': '100'}, 'd'),
      ]);
      expect(r['success'], true, reason: '$r');
      expect(
        [
          r['results']['m'],
          r['results']['x'],
          r['results']['y'],
          r['results']['d'],
        ],
        ['moved', 'muted', 'undeafened', 'disconnected'],
      );
      final effects = r['effects'] as List;
      expect(effects.first['before']['channel_id'], '31');
      expect(effects.first['after']['channel_id'], '32');
      final notInVoice = await _run([
        _a('disconnectFromVoice', {'userId': '101'}),
      ]);
      expect(notInVoice['error'], contains('not connected to a voice channel'));
      final textChannel = await _run([
        _a('moveToVoiceChannel', {'userId': '100', 'targetChannelId': '30'}),
      ]);
      expect(textChannel['error'], contains('not a voice channel'));
    },
  );

  test(
    'guild: updateGuild, emoji, onboarding and the unsupported onboarding edit',
    () async {
      final r = await _run(
        [
          _a('updateGuild', {
            'name': 'Nouveau nom',
            'description': 'desc',
          }, 'g'),
          _a('updateEmoji', {'emojiId': 'cat', 'name': 'chat'}, 'e'),
          _a('getGuildOnboarding', {}, 'o'),
        ],
        guild: {
          'emojis': [
            {'id': '8001', 'name': 'cat'},
          ],
          'onboarding': {
            'enabled': true,
            'default_channel_ids': ['30'],
          },
        },
      );
      expect(r['success'], true, reason: '$r');
      expect(r['results']['g'], '10');
      expect(r['results']['e.name'], 'chat');
      expect(r['results']['o.enabled'], 'true');
      expect((r['effects'] as List).first['after']['name'], 'Nouveau nom');
      final empty = await _run([_a('updateGuild', {})]);
      expect(empty['error'], contains('at least one field'));
      final edit = await _run([
        _a('updateGuildOnboarding', {'enabled': true}),
      ]);
      expect(
        edit['error'],
        contains('not supported by the current nyxx runtime'),
      );
    },
  );

  test('automod: create, list, update and delete rules', () async {
    final r = await _run([
      _a('createAutoModRule', {
        'name': 'Spam',
        'triggerType': 'keyword',
        'keywords': ['spam'],
      }, 'c'),
      _a('listAutoModRules', {}, 'l'),
      _a('updateAutoMod', {
        'filterWords': ['a'],
        'maxMentions': 4,
      }, 'u'),
      _a('deleteAutoModRule', {'ruleId': '((action.c.ruleId))'}, 'd'),
    ]);
    expect(r['success'], true, reason: '$r');
    expect(r['results']['l.count'], '1');
    expect(r['results']['d'], 'deleted');
    for (final bad in [
      {'name': ''},
      {'name': 'x', 'triggerType': 'nope'},
      {'name': 'x', 'triggerType': 'keyword'},
      {'name': 'x', 'triggerType': 'mentionSpam', 'mentionTotalLimit': 99},
      {'name': 'x', 'triggerType': 'spam', 'actionType': 'send_alert_message'},
    ]) {
      expect(
        (await _run([_a('createAutoModRule', bad)]))['success'],
        false,
        reason: '$bad',
      );
    }
  });

  test('webhooks: list, get and edit use the webhooks fixture', () async {
    final r = await _run(
      [
        _a('listWebhooks', {'channelId': '30'}, 'l'),
        _a('getWebhook', {'webhookId': '9001'}, 'g'),
        _a('editWebhook', {'webhookId': '9001', 'name': 'Renamed'}, 'e'),
      ],
      guild: {
        'webhooks': [
          {'id': '9001', 'name': 'Hook', 'channel_id': '30', 'token': 'tok'},
        ],
      },
    );
    expect(r['success'], true, reason: '$r');
    expect(r['results']['l'], contains('"hasToken":true'));
    expect(r['results']['e'], 'https://discord.com/api/webhooks/9001/tok');
    expect((r['effects'] as List).single['after']['name'], 'Renamed');
    final bad = await _run([
      _a('getWebhook', {'webhookId': '1'}),
    ]);
    expect(bad['error'], contains('entities.guilds.<guildId>.webhooks'));
  });

  test('edits: component messages and the interaction response', () async {
    final components = {
      'components': [
        {
          'type': 'actionRow',
          'components': [
            {'type': 'button', 'label': 'Ok', 'customId': 'ok'},
          ],
        },
      ],
    };
    final r = await _run(
      [
        _a('respondWithMessage', {'content': 'avant'}, 'a'),
        _a('editInteractionMessage', {
          'content': 'après',
          'clearEmbeds': true,
        }, 'e'),
        _a('editComponentV2', {
          'messageId': '901',
          'components': components,
        }, 'c'),
        _a('deleteChannelPermission', {
          'channelId': '30',
          'targetId': '50',
          'targetType': 'role',
        }, 'p'),
      ],
      guild: {
        'messages': {
          '30': [
            {'id': '901', 'author_id': '999', 'content': 'x'},
          ],
        },
      },
    );
    expect(r['success'], true, reason: '$r');
    final edit = (r['effects'] as List).firstWhere(
      (e) => e['type'] == 'editInteractionMessage',
    );
    expect(edit['before']['payload']['content'], 'avant');
    expect(edit['after']['payload']['content'], 'après');
    expect(r['results']['p'], 'deleted');
    final orphan = await _run([
      _a('editInteractionMessage', {'content': 'x'}),
    ]);
    expect(orphan['error'], contains('no interaction response to edit'));
  });

  test('actions left without simulation explain what to provide', () async {
    for (final entry in {
      'canvasCreateBlock': 'runtimeImageBlock.operations',
      'getMusicInfo': 'music',
      'playMusic': 'music',
    }.entries) {
      final r = await _run([_a(entry.key, {})]);
      expect(
        r['error'],
        allOf(contains('simulation fixture'), contains(entry.value)),
        reason: entry.key,
      );
    }
  });

  test(
    'every Blocks action is simulated, runs purely, or explains its fixture',
    () async {
      // Guard against new lacunes: an action added to the engine must either be handled by the
      // sandbox or carry a hint naming the fixture to provide.
      final generic = <String>[];
      for (final type in BotCreatorActionType.values) {
        final r = await _run([_a(type.name, {})]);
        final error = (r['error'] ?? '').toString();
        if (error.contains('requires an explicit simulation fixture')) {
          generic.add(type.name);
        }
      }
      expect(generic, isEmpty, reason: 'no fixture hint for: $generic');
    },
  );
}

void _guildMemberContext() {
  test(
    'a guildMember variable needs guildId:userId, with a message that says so',
    () async {
      Future<Map<String, dynamic>> read(String contextId) => _run([
        _a('getScopedVariable', {
          'scope': 'guildMember',
          'key': 'warns',
          'contextId': contextId,
        }),
      ]);
      final bare = await read('100');
      expect(bare['success'], false);
      expect(
        bare['error'],
        allOf(contains('<guildId>:<userId>'), contains('((guild.id)):')),
      );
      expect((await read('10:100'))['success'], true);
    },
  );
}
