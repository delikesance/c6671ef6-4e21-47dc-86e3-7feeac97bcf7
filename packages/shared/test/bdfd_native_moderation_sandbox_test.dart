import 'package:bot_creator_shared/sandbox/command_sandbox.dart';
import 'package:bot_creator_shared/sandbox/moderation_function_cases.dart';
import 'package:nyxx/nyxx.dart';
import 'package:test/test.dart';

Map<String, dynamic> fixtures() => {
  'variables': {
    'bot.id': '500',
    'guild.id': '10',
    'author.id': '999',
    'message.mentions[0]': '222',
    'message.args.last': '333',
  },
  'entities': {
    'guilds': {
      '10': {
        'owner_id': '999',
        'roles': [
          {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': 0},
          {
            'id': '63',
            'name': 'bot',
            'position': 10,
            'permissions':
                Permissions.kickMembers.value | Permissions.banMembers.value,
          },
          {'id': '64', 'name': 'member', 'position': 1, 'permissions': 0},
        ],
        'members': {
          '500': {
            'roles': ['63'],
          },
          '222': {
            'roles': ['64'],
          },
          '333': {
            'roles': ['64'],
          },
          '999': {'roles': []},
        },
        'bans': <String, dynamic>{},
      },
    },
  },
};

Future<Map<String, dynamic>> run(String source, Map<String, dynamic> data) =>
    testCommandInSandbox({
      'script': source,
      'bdfdBackend': 'native-v1',
      ...data,
    });

void main() {
  test(
    'native sandbox kick permits newer equal-position role but refuses older one',
    () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'];
      guild['roles'][2]['position'] = 10;
      final permitted = await run(r'$kick[222]', data);
      expect(permitted['success'], true, reason: '$permitted');
      expect((permitted['effects'] as List).single['type'], 'kickUser');
      final denied = fixtures();
      final other = denied['entities']['guilds']['10'];
      other['roles'].add({
        'id': '62',
        'name': 'older',
        'position': 10,
        'permissions': 0,
      });
      other['members']['222']['roles'] = ['62'];
      final result = await run(r'$kick[222]', denied);
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'native role grant permits newer equal-position role but refuses older one',
    () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'];
      guild['roles'][1]['permissions'] = Permissions.manageRoles.value;
      guild['roles'][2]['position'] = 10;
      guild['roles'].add({
        'id': '62',
        'name': 'older',
        'position': 10,
        'permissions': 0,
      });
      final result = await run(
        r'$giveRole[333;64]$try$giveRole[333;62]$catch denied $endtry',
        data,
      );
      expect(result['success'], true, reason: '$result');
      expect((result['effects'] as List).single['role_id'], '64');
    },
  );

  test(
    'native replacement captures every role overwritten by the typed service',
    () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'];
      guild['roles'][1]['permissions'] = Permissions.manageRoles.value;
      guild['roles'].add({
        'id': '65',
        'name': 'new',
        'position': 2,
        'permissions': 0,
      });
      final result = await run(r'$setUserRoles[222;65;65]done', data);
      expect(result['success'], true, reason: '$result');
      final effect = (result['effects'] as List).single;
      expect(effect['type'], 'setUserRoles');
      expect(effect['backend'], 'native-v1');
      expect(effect['before']['member']['roles'], ['64']);
      expect(effect['after']['member']['roles'], ['65']);
      expect(effect['role_ids'], ['65']);
    },
  );
  for (final failure in [
    'permission',
    'removeHigh',
    'removeManaged',
    'missingRole',
    'everyone',
  ]) {
    test(
      'native replacement refuses $failure before overwriting member roles',
      () async {
        final data = fixtures();
        final guild = data['entities']['guilds']['10'];
        guild['roles'][1]['permissions'] = failure == 'permission'
            ? 0
            : Permissions.manageRoles.value;
        guild['roles'].add({
          'id': '65',
          'name': 'new',
          'position': 2,
          'permissions': 0,
        });
        if (failure == 'removeHigh') guild['roles'][2]['position'] = 11;
        if (failure == 'removeManaged') guild['roles'][2]['managed'] = true;
        final role = failure == 'missingRole'
            ? '12345'
            : failure == 'everyone'
            ? '10'
            : '65';
        final result = await run('\$setUserRoles[222;$role]', data);
        expect(result['success'], false, reason: '$result');
        expect(result['effects'], isEmpty);
      },
    );
  }

  test(
    'native role definitions preserve fields, toggle everyone and delete member grants',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['roles'][1]['permissions'] =
          Permissions.manageRoles.value;
      data['variables']['message.roleMentions'] = '64';
      final result = await run(
        r'$createRole[Staff;255;yes;no]$modifyRole[64;New name;!unchanged;!unchanged;yes]$modifyRolePerms[10;kick;ban;kick]$colorRole[#00FF00]$deleteRole[64]done',
        data,
      );
      expect(result['success'], true, reason: '$result');
      final effects = result['effects'] as List;
      expect(effects.map((e) => e['type']), [
        'createRole',
        'updateRole',
        'updateRole',
        'updateRole',
        'deleteRole',
      ]);
      expect(effects[0]['after']['name'], 'Staff');
      expect(effects[0]['after']['color'], 255);
      expect(effects[1]['after']['name'], 'New name');
      expect(effects[1]['after']['position'], 1);
      expect(effects[2]['after']['permissions'], '4');
      expect(effects[3]['after']['color'], 0x00ff00);
      expect(effects[4]['before']['name'], 'New name');
      expect(effects[4]['after'], isNull);
      expect(effects.map((e) => e['backend']), everyElement('native-v1'));
    },
  );
  for (final source in [
    r'$createRole[Staff;255]',
    r'$modifyRole[64;Name]',
    r'$modifyRolePerms[64;kick]',
    r'$deleteRole[64]',
  ]) {
    test(
      '$source requires Manage Roles before native sandbox mutations',
      () async {
        final result = await run(source, fixtures());
        expect(result['success'], false, reason: '$result');
        expect(result['effects'], isEmpty);
      },
    );
  }
  test(
    'native role update denies invalid position before changing name',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['roles'][1]['permissions'] =
          Permissions.manageRoles.value;
      final result = await run(
        r'$modifyRole[64;Never;!unchanged;!unchanged;!unchanged;10]',
        data,
      );
      expect(result['success'], false, reason: '$result');
      expect(result['effects'], isEmpty);
    },
  );

  test(
    'native role sandbox captures assignment states including owner and high member',
    () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'];
      guild['roles'][1]['permissions'] = Permissions.manageRoles.value;
      guild['roles'].add({
        'id': '65',
        'name': 'high member',
        'position': 15,
        'permissions': 0,
      });
      guild['members']['333']['roles'] = ['65'];
      final result = await run(
        r'$giveRole[999;64]$giveRole[333;64]$roleGrant[222;-64;+64]done',
        data,
      );
      expect(result['success'], true, reason: '$result');
      final effects = result['effects'] as List;
      expect(effects.map((e) => e['type']), [
        'addRole',
        'addRole',
        'removeRole',
        'addRole',
      ]);
      expect(effects[0]['after']['member']['roles'], ['64']);
      expect(effects[1]['after']['member']['roles'], ['65', '64']);
      expect(effects[2]['before']['member']['roles'], ['64']);
      expect(effects[2]['after']['member']['roles'], isEmpty);
      expect(effects[3]['after']['member']['roles'], ['64']);
    },
  );
  for (final failure in [
    'permission',
    'equal',
    'managed',
    'everyone',
    'missingMember',
  ]) {
    test(
      'native role sandbox blocks $failure without simulated mutation',
      () async {
        final data = fixtures();
        final guild = data['entities']['guilds']['10'];
        guild['roles'][1]['permissions'] = failure == 'permission'
            ? 0
            : Permissions.manageRoles.value;
        if (failure == 'managed') guild['roles'][2]['managed'] = true;
        final role = failure == 'everyone'
            ? '10'
            : failure == 'equal'
            ? '63'
            : '64';
        final user = failure == 'missingMember' ? '12345' : '222';
        final result = await run('\$giveRole[$user;$role]', data);
        expect(result['success'], false, reason: '$result');
        expect(result['effects'], isEmpty);
      },
    );
  }

  test(
    'native moderation uses fixture permission checks and records typed effects',
    () async {
      final result = await run(
        r'$kick[222;Spam]$banID[Raid;333]done',
        fixtures(),
      );
      expect(result['success'], true, reason: '$result');
      final effects = result['effects'] as List;
      expect(effects.map((e) => e['type']), ['kickUser', 'banUser']);
      expect(effects.map((e) => e['user_id']), ['222', '333']);
      expect(effects.map((e) => e['reason']), ['Spam', 'Raid']);
      expect(effects.map((e) => e['backend']), everyElement('native-v1'));
      expect(effects[0]['before']['member'], isNotNull);
      expect(effects[0]['after']['member'], isNull);
      expect(effects[1]['after']['ban_reason'], 'Raid');
      expect(result['responses'][0]['payload']['content'], 'done');
      expect(result['discord_verified'], false);
      expect(
        (result['entity_requests'] as List).where(
          (r) => r['operation'] == 'members.fetch',
        ),
        isNotEmpty,
      );
    },
  );
  test(
    'ban reason never becomes a target ID and empty banID selects last argument',
    () async {
      final result = await run(r'$ban[123]$banID[Other;]', fixtures());
      expect(result['success'], true, reason: '$result');
      expect((result['effects'] as List).map((e) => e['user_id']), [
        '222',
        '333',
      ]);
      expect((result['effects'] as List).map((e) => e['reason']), [
        '123',
        'Other',
      ]);
    },
  );
  for (final denial in ['permission', 'owner', 'equal role', 'higher role']) {
    test('native sandbox rejects $denial before mutation', () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'] as Map;
      if (denial == 'permission') guild['roles'][1]['permissions'] = 0;
      if (denial == 'equal role') guild['members']['222']['roles'] = ['63'];
      if (denial == 'higher role') guild['roles'][2]['position'] = 11;
      final result = await run(
        denial == 'owner' ? r'$kick' : r'$kick[222]',
        data,
      );
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
      expect(result['diagnostics'][0]['function'], r'$kick');
    });
  }
  test(
    'native sandbox requires explicit moderation fixtures and never contacts Discord',
    () async {
      final result = await run(r'$kick[222]', {});
      expect(result['success'], false);
      expect(result['error'], contains('Native moderation requires'));
      expect(result['effects'], isEmpty);
      expect(result['entity_requests'], isEmpty);
    },
  );
  test(
    'unknown wrapper keeps moderation calls intact without requiring fixtures',
    () async {
      const source = r'$unknown[$kick[222];$banID[Spam;333]]';
      final result = await run(source, {});
      expect(result['success'], true, reason: '$result');
      expect(result['responses'][0]['payload']['content'], source);
      expect(result['effects'], isEmpty);
    },
  );
  test(
    'native blocks nested in visual workflow retain moderation adapter',
    () async {
      final data = fixtures();
      data['workflows'] = [
        {
          'name': 'child',
          'actions': [
            {
              'type': 'runBdfdScript',
              'payload': {
                'bdfdBackend': 'native-v1',
                'scriptContent': r'$kick[222;workflow]',
              },
            },
          ],
        },
      ];
      final result = await run(r'$callWorkflow[child]done', data);
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], hasLength(1));
      expect(result['effects'][0]['user_id'], '222');
      expect(result['effects'][0]['reason'], 'workflow');
    },
  );
  test(
    'banID can ban an external user after permission and owner checks',
    () async {
      final result = await run(r'$banID[Spam;444]', fixtures());
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], hasLength(1));
      expect(result['effects'][0]['user_id'], '444');
      expect(result['effects'][0]['before']['member'], isNull);
    },
  );
  test(
    'native ban then unban records mutations once and updates ban variables',
    () async {
      final result = await run(r'$banID[Spam;444]$unbanID[444]', fixtures());
      expect(result['success'], true, reason: '$result');
      expect((result['effects'] as List).map((e) => e['type']), [
        'banUser',
        'unbanUser',
      ]);
      expect(result['effects'][1]['before']['ban_reason'], 'Spam');
      expect(result['effects'][1]['after']['ban_reason'], isNull);
      expect(result['effects'][1]['reason'], '');
      expect(result['variables']['member[444].isBanned'], 'false');
      expect(result['variables']['ban.reason[444]'], '');
    },
  );
  test(
    'username unban uses ban_users fixtures without changing existing member data',
    () async {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'] as Map;
      guild.remove(
        'owner_id',
      ); // Unban requires permission, not target hierarchy.
      guild['bans'] = {'222': 'Spam'};
      guild['ban_users'] = {'222': 'Target'};
      data['variables']['message.content'] = ' TARGET ';
      final result = await run(r'$unban', data);
      expect(result['success'], true, reason: '$result');
      final effect = result['effects'][0];
      expect(effect['type'], 'unbanUser');
      expect(effect['user_id'], '222');
      expect(effect['before']['member'], effect['after']['member']);
    },
  );
  test('native unban permission failure leaves bans intact', () async {
    final data = fixtures();
    data['entities']['guilds']['10']['roles'][1]['permissions'] =
        Permissions.kickMembers.value;
    data['entities']['guilds']['10']['bans'] = {'222': 'Spam'};
    final result = await run(r'$unbanID[222]', data);
    expect(result['success'], false);
    expect(result['effects'], isEmpty);
    expect(result['diagnostics'][0]['function'], r'$unbanID');
  });
  test('native username unban requires its mapping fixture', () async {
    final data = fixtures();
    data['variables']['message.content'] = 'Target';
    data['entities']['guilds']['10']['bans'] = {'222': 'Spam'};
    final result = await run(r'$unban', data);
    expect(result['success'], false);
    expect(result['error'], contains('ban_users fixtures'));
    expect(result['effects'], isEmpty);
  });
  test(
    'unban failures can be caught without replaying a prior successful unban',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['bans'] = {'222': 'Spam'};
      final result = await run(
        r'$unbanID[222]$try$unbanID[222]$catch$error$endtry',
        data,
      );
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], hasLength(1));
      expect(
        result['responses'][0]['payload']['content'],
        contains('Banned user not found'),
      );
    },
  );
  test(
    'unban adapters survive native blocks within a visual workflow',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['bans'] = {'222': 'Spam'};
      data['workflows'] = [
        {
          'name': 'child',
          'actions': [
            {
              'type': 'runBdfdScript',
              'payload': {
                'bdfdBackend': 'native-v1',
                'scriptContent': r'$unbanID[222]',
              },
            },
          ],
        },
      ];
      final result = await run(r'$callWorkflow[child]', data);
      expect(result['success'], true, reason: '$result');
      expect(result['effects'], hasLength(1));
      expect(result['effects'][0]['type'], 'unbanUser');
    },
  );
  test('username unban refuses invalid IDs in fixture mappings', () async {
    for (final id in ['0', '-1', 'invalid']) {
      final data = fixtures();
      final guild = data['entities']['guilds']['10'] as Map;
      guild['bans'] = {id: 'Spam'};
      guild['ban_users'] = {id: 'Target'};
      data['variables']['message.content'] = 'Target';
      final result = await run(r'$unban', data);
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
    }
  });
  test(
    'native timeout then untimeout preserves membership and clears timeout state',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['roles'][1]['permissions'] =
          Permissions.moderateMembers.value;
      final result = await run(r'$timeout[1h30m;222]$untimeout[222]', data);
      expect(result['success'], true, reason: '$result');
      final effects = result['effects'] as List;
      expect(effects.map((e) => e['type']), ['muteUser', 'unmuteUser']);
      expect(effects[0]['after']['member']['timeout_seconds'], 5400);
      expect(effects[1]['after']['member']['timeout_until'], isNull);
      expect(effects[1]['after']['member']['roles'], ['64']);
      expect(result['variables']['member[222].isTimedOut'], 'false');
      expect(effects[0]['reason'], '');
    },
  );
  test('native timeout simulates every indexed mention', () async {
    final data = fixtures();
    data['variables']['message.mentions[1]'] = '333';
    data['entities']['guilds']['10']['roles'][1]['permissions'] =
        Permissions.moderateMembers.value;
    final result = await run(r'$timeout[1m]', data);
    expect(result['success'], true, reason: '$result');
    expect((result['effects'] as List).map((e) => e['user_id']), [
      '222',
      '333',
    ]);
  });
  test(
    'native timeout refuses an administrator even below the bot role',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['roles'][1]['permissions'] =
          Permissions.moderateMembers.value;
      data['entities']['guilds']['10']['roles'][2]['permissions'] =
          Permissions.administrator.value;
      final result = await run(r'$timeout[1m;222]', data);
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
      expect(result['error'], contains('administrator'));
    },
  );
  test('native timeouts require moderate members permission', () async {
    final result = await run(r'$timeout[1m;222]', fixtures());
    expect(result['success'], false);
    expect(result['effects'], isEmpty);
  });
  test(
    'timeouts inside a nested native block retain the simulated service',
    () async {
      final data = fixtures();
      data['entities']['guilds']['10']['roles'][1]['permissions'] =
          Permissions.moderateMembers.value;
      data['workflows'] = [
        {
          'name': 'child',
          'actions': [
            {
              'type': 'runBdfdScript',
              'payload': {
                'bdfdBackend': 'native-v1',
                'scriptContent': r'$timeout[1m;222]',
              },
            },
          ],
        },
      ];
      final result = await run(r'$callWorkflow[child]', data);
      expect(result['success'], true, reason: '$result');
      expect(result['effects'][0]['after']['member']['timeout_seconds'], 60);
    },
  );
  for (final backend in ['native-v1', 'legacy-v1']) {
    test(
      '$backend kickMention checks author permission before simulating a kick',
      () async {
        final data = fixtures();
        data['variables']['author.id'] = '333';
        final denied = await testCommandInSandbox({
          'script': r'$kickMention[Spam]',
          'bdfdBackend': backend,
          ...data,
        });
        expect(denied['success'], false);
        expect(denied['effects'], isEmpty);
        data['entities']['guilds']['10']['roles'][2]['permissions'] =
            Permissions.kickMembers.value;
        final allowed = await testCommandInSandbox({
          'script': r'$kickMention[Spam]',
          'bdfdBackend': backend,
          ...data,
        });
        expect(allowed['success'], true, reason: '$allowed');
        expect(allowed['effects'][0]['user_id'], '222');
        expect(allowed['effects'][0]['reason'], 'Spam');
      },
    );
  }
  test(
    'kickMention still refuses owner target despite authorized owner author',
    () async {
      final data = fixtures();
      data['variables']['message.mentions[0]'] = '999';
      final result = await run(r'$kickMention[]', data);
      expect(result['success'], false);
      expect(result['effects'], isEmpty);
    },
  );
  test('canonical kickMention corpus fixture also runs natively', () async {
    final sample = sandboxModerationFunctionCases.firstWhere(
      (sample) => sample.function == 'kickmention',
    );
    final result = await run(r'$kickMention[Raid]', sample.scenario);
    expect(result['success'], true, reason: '$result');
    expect(result['effects'], hasLength(1));
    expect(result['effects'][0]['user_id'], '21');
    expect(result['effects'][0]['reason'], 'Raid');
  });
}
