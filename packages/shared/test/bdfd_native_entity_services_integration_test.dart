import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/entity_fixture_gateway.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

Map<String, dynamic> fixtures({int permissions = 8}) => {
  'users': {
    '999': {'username': 'Sandbox bot', 'bot': true},
    '20': {
      'username': 'Alice',
      'global_name': 'Display Alice',
      'avatar': 'custom',
      'banner': 'a_banner',
      'accent_color': 0xaabbcc,
    },
  },
  'guilds': {
    '10': {
      'name': 'Alpha',
      'owner_id': '99',
      'description': 'A guild',
      'verification_level': 3,
      'icon': 'icon',
      'banner': 'banner',
      'premium_subscription_count': 7,
      'premium_tier': 2,
      'afk_timeout': 600,
      'roles': [
        {'id': '10', 'name': '@everyone', 'permissions': 0},
        {'id': '5', 'name': 'Bot', 'permissions': permissions},
      ],
      'members': {
        '999': {
          'roles': ['5'],
        },
        '20': {
          'roles': [],
          'nick': 'Guild Alice',
          'avatar': 'member',
          'joined_at': '2022-08-16T08:39:00Z',
        },
      },
      'channels': [
        {
          'id': '30',
          'name': 'chat',
          'type': 'text',
          'permission_overwrites': [],
        },
      ],
      'threads': [
        {
          'id': '80',
          'name': 'existing',
          'parent_id': '30',
          'owner_id': '999',
          'message_count': 7,
          'member_count': 1,
          'members': ['999'],
          'archived': false,
          'locked': false,
        },
      ],
    },
    '11': {
      'name': 'Beta',
      'owner_id': '99',
      'premium_subscription_count': 0,
      'members': {},
      'roles': [],
      'channels': [],
      'threads': [],
    },
  },
  'messages': <String, dynamic>{
    '30': {
      '123': <String, dynamic>{
        'author_id': '20',
        'channel_id': '30',
        'content': 'source',
      },
    },
  },
};

Future<Map<String, dynamic>> run(
  String script,
  Map<String, dynamic> entities, {
  String channel = '30',
}) => testCommandInSandbox({
  'bdfdBackend': 'native-v1',
  'script': script,
  'variables': {'bot.id': '999', 'channel.id': channel},
  'entities': entities,
});

void main() {
  test(
    'fresh message queries support announcement voice stage and threads',
    () async {
      for (final type in ['announcement', 'voice', 'stage', 'thread']) {
        final entities = fixtures();
        final id = type == 'thread' ? '80' : '30';
        if (type == 'thread') {
          entities['messages']['80'] = {
            '123': entities['messages']['30']['123'],
          };
        } else {
          entities['guilds']['10']['channels'][0]['type'] = type;
        }
        final result = await run(
          r'$getMessage[' + id + r';123]',
          entities,
          channel: id,
        );
        expect(result['success'], true, reason: '$type: $result');
        expect(result['results']['output'], 'source');
      }
    },
  );
  test('message metadata reads channel and reply fixtures freshly', () async {
    final entities = fixtures();
    final channel = entities['guilds']['10']['channels'][0] as Map;
    channel['last_message_id'] = '123';
    channel['last_pin_timestamp'] = 1700000000000;
    final source = entities['messages']['30']['123'] as Map;
    source['edited_timestamp'] = '2023-11-14T22:13:20Z';
    source['type'] = 'reply';
    source['message_reference'] = {'message_id': '122'};
    final result = await testCommandInSandbox({
      'bdfdBackend': 'native-v1',
      'variables': {'bot.id': '999', 'channel.id': '30', 'message.id': '123'},
      'entities': entities,
      'script':
          r'$lastMessageID|$lastPinTimestamp|$isMessageEdited[30;123]|$messageEditedTimestamp[30;123]|$repliedMessageID',
    });
    expect(result['success'], true, reason: '$result');
    expect(result['results']['output'], '123|1700000000|true|1700000000|122');
    expect(result['effects'], isEmpty);
  });
  test('editing own message updates the shared query fixture', () async {
    final entities = fixtures();
    entities['messages']['30']['123']['author_id'] = '999';
    final result = await run(
      r'$editMessage[30;123;new;Title;Description;#aabbcc;Footer]'
      r'$getMessage[30;123]|$getEmbedData[30;123;1;title]|$isMessageEdited[30;123]',
      entities,
    );
    expect(result['success'], true, reason: '$result');
    expect(result['results']['output'], 'new|Title|true');
    expect(result['effects'].single['type'], 'editMessage');
  });
  test('administrator cannot edit another author message', () async {
    final result = await run(r'$editMessage[30;123;changed]', fixtures());
    expect(result['success'], false);
    expect(result['effects'], isEmpty);
  });
  test('message reads use fixture contents and author', () async {
    final result = await run(
      r'$getMessage[30;123]|$getMessage[30;123;authorID]|$authorOfMessage[30;123]',
      fixtures(),
    );
    expect(result['success'], true, reason: '$result');
    expect(result['results']['output'], 'source|20|20');
    expect(result['effects'], isEmpty);
  });
  test(
    'pin and reactions target the main reply after independent send',
    () async {
      final result = await run(
        r'$pinMessage$addReactions[✅]Main$sendMessage[Independent;no]',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      final responses = result['responses'] as List;
      expect(responses, hasLength(2));
      expect(responses.first['payload']['content'], 'Independent');
      expect(responses.last['payload']['content'], 'Main');
      for (final effect in result['effects'] as List) {
        expect(effect['message_id'], responses.last['id'], reason: '$effect');
      }
      expect(result['effects'], hasLength(2));
    },
  );
  test('message mutations are recorded only after permission checks', () async {
    final denied = await run(
      r'$deleteMessage[30;123]',
      fixtures(permissions: 0),
    );
    expect(denied['success'], false);
    expect(denied['effects'], isEmpty);
    final allowed = await run(r'$deleteMessage[30;123]', fixtures());
    expect(allowed['success'], true, reason: '$allowed');
    expect(allowed['effects'].single['type'], 'deleteMessage');
  });
  test('member queries use complete fixture membership', () async {
    final result = await run(
      r'$membersCount|$allMembersCount|$findUser[Alice;no]|$isBooster[20]|$isTimedOut[20]',
      fixtures(),
    );
    expect(result['success'], true, reason: '$result');
    expect(result['results']['output'], '2|2|20|false|false');
    expect(result['effects'], isEmpty);
  });
  test('native user queries use declared assets membership and joined date', () async {
    final result = await run(
      r'$userExists[20]|$username[20]|$displayName[20]|$nickname[20]|$discriminator[]|'
      r'$userJoined[20]|$userAvatar[20]|$authorAvatar|$userBanner[20]|$userBannerColor[20]|$userServerAvatar[20]',
      fixtures(),
    );
    expect(result['success'], true, reason: '$result');
    expect(
      result['results']['output'],
      'true|Alice|Display Alice|Guild Alice|0000|2022-08-16|'
      'https://cdn.discordapp.com/avatars/20/custom.png|https://cdn.discordapp.com/avatars/20/custom.png|'
      'https://cdn.discordapp.com/banners/20/a_banner.gif|AABBCC|https://cdn.discordapp.com/guilds/10/users/20/avatars/member.png',
    );
    expect(result['effects'], isEmpty);
  });
  test(
    'native guild queries read fixtures and distinguish absent entities',
    () async {
      final result = await run(
        r'$guildExists[10]|$guildExists[12]|$userExists[21]|$serverCount|$serverNames|'
        r'$serverOwner|$serverDescription|$serverVerificationLvl|$serverIcon|$guildBanner[10]|$boostCount|$boostLevel|$afkTimeout',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      expect(
        result['results']['output'],
        'true|false|false|2|Alpha, Beta|99|A guild|High|'
        'https://cdn.discordapp.com/icons/10/icon.png|https://cdn.discordapp.com/banners/10/banner.png|7|2|600',
      );
      expect(result['effects'], isEmpty);
    },
  );
  test('guild pagination reaches every fixture after 200 entries', () async {
    final result = await run(r'$serverCount', {
      'guilds': {
        for (var id = 1; id <= 201; id++) '$id': {'name': 'Guild $id'},
      },
    });
    expect(result['success'], true, reason: '$result');
    expect(result['results']['output'], '201');
    final requests = result['entity_requests'] as List;
    expect(
      requests.where((r) => r['operation'] == 'users.guilds'),
      hasLength(2),
    );
  });
  test('absent fixture population remains an error instead of false', () async {
    for (final script in [
      r'$userExists[20]',
      r'$guildExists[10]',
      r'$serverCount',
    ]) {
      final result = await run(script, {});
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], isEmpty);
    }
  });
  test(
    'thread lifecycle uses shared preparation and records fixture effects',
    () async {
      final result = await run(
        r'$var[t;$startThread[Created;30;;60;yes]]'
        r'$editThread[$var[t];Renamed;no;1440;no;5]'
        r'$threadAddMember[$var[t];20]$threadRemoveMember[$var[t];20]ID=$var[t]',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], 'ID=200000');
      final effects = result['effects'] as List;
      expect(effects.map((effect) => effect['type']), [
        'startThread',
        'editThread',
        'threadAddMember',
        'threadRemoveMember',
      ]);
      expect(effects[1]['after']['name'], 'Renamed');
      expect(effects[1]['after']['slowmode'], 5);
      expect(effects[2]['after']['members'], ['999', '20']);
      expect(effects[3]['after']['members'], ['999']);
    },
  );
  test(
    'thread counts use current thread without requiring a bot identity',
    () async {
      final result = await testCommandInSandbox({
        'bdfdBackend': 'native-v1',
        'script': r'$threadMessageCount|$threadUserCount',
        'variables': {'channel.id': '80'},
        'entities': fixtures(),
      });
      expect(result['success'], true, reason: '$result');
      expect(result['results']['output'], '7|1');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'thread permission failure occurs before any fixture mutation',
    () async {
      final result = await run(
        r'$startThread[Denied;30;]',
        fixtures(permissions: 0),
      );
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'message-backed thread identity is stable and a duplicate cannot be created',
    () async {
      final result = await run(
        r'$startThread[Source;30;123;60;yes]$startThread[Duplicate;30;123]',
        fixtures(),
      );
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], hasLength(1), reason: '$result');
      expect(result['effects'][0]['thread_id'], '123');
    },
  );
  test(
    'source message from another parent cannot create a simulated thread',
    () async {
      final data = fixtures();
      data['messages']['30']['123']['channel_id'] = '31';
      final result = await run(r'$startThread[Source;30;123]', data);
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'entity gateway remains read-only despite new service fixtures',
    () async {
      final gateway = EntityFixtureGateway(fixtures());
      await expectLater(
        Future.sync(
          () => gateway.channels.createThread(
            Snowflake(30),
            ThreadBuilder.publicThread(name: 'forbidden'),
          ),
        ),
        throwsA(isA<StateError>()),
      );
    },
  );
}
