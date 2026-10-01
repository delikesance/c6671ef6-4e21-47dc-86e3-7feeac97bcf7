import 'function_suite.dart';

const _moderation = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '60', 'name': 'Muted', 'position': 1, 'permissions': '0'},
      ],
      'members': {
        '20': {'roles': <String>[]},
        '21': {'roles': <String>[]},
      },
      'bans': {'22': 'Previous violation'},
      'ban_users': {'22': 'troublemaker'},
    },
  },
};

const _messages = {
  'guilds': {
    '10': {
      'messages': {
        '30': [
          {'id': '104', 'author_id': '21', 'pinned': false},
          {'id': '103', 'author_id': '20', 'pinned': true},
          {'id': '102', 'author_id': '21', 'pinned': false},
          {'id': '101', 'author_id': '20', 'pinned': false},
        ],
      },
    },
  },
};

const sandboxModerationFunctionCases = [
  SandboxFunctionCase(
    'setnickname',
    r'$setNickname[New Name;21]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'setNickname',
      '/effects/0/user_id': '21',
      '/effects/0/before': null,
      '/effects/0/after': 'New Name',
      '/variables/member[21].nick': 'New Name',
    },
  ),
  SandboxFunctionCase(
    'unban',
    r'$unban',
    0,
    '',
    label: 'resolves a banned username from the command message',
    scenario: {
      'entities': _moderation,
      'variables': {'message.content': 'troublemaker'},
    },
    expectedValues: {
      '/effects/0/type': 'unbanUser',
      '/effects/0/user_id': '22',
      '/effects/0/before/ban_reason': 'Previous violation',
      '/effects/0/after/ban_reason': null,
    },
  ),
  SandboxFunctionCase(
    'isbanned',
    r'$banID[Spam;21]$isBanned[21]',
    0,
    'true',
    label: 'query observes a simulated ban in the same command',
    scenario: {'entities': _moderation},
    expectedValues: {'/effects/0/after/ban_reason': 'Spam'},
  ),
  SandboxFunctionCase(
    'istimedout',
    r'$timeout[15m;21]$isTimedOut[21]',
    0,
    'true',
    label: 'query observes a simulated timeout in the same command',
    scenario: {'entities': _moderation},
    expectedValues: {'/effects/0/after/member/timeout_seconds': 900},
  ),
  SandboxFunctionCase(
    'isbanned',
    r'$isBanned[22]',
    0,
    'true',
    label: 'reads ban state through the fixture gateway',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/entity_requests/0/operation': 'guilds.fetchBan',
      '/variables/member[22].isBanned': 'true',
    },
  ),
  SandboxFunctionCase(
    'isbanned',
    r'$isBanned[21]',
    0,
    'false',
    label: 'an unbanned user has a negative lookup',
    scenario: {'entities': _moderation},
    expectedValues: {'/variables/member[21].isBanned': 'false'},
  ),
  SandboxFunctionCase(
    'getbanreason',
    r'$getBanReason[22]',
    0,
    'Previous violation',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/entity_requests/0/operation': 'guilds.fetchBan',
      '/variables/ban.reason[22]': 'Previous violation',
    },
  ),
  SandboxFunctionCase(
    'getbanreason',
    r'$getBanReason[22;10]',
    0,
    'Previous violation',
    label: 'explicit guild ID',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/entity_requests/0/guild_id': '10',
      '/variables/ban.reason[22;10]': 'Previous violation',
    },
  ),
  SandboxFunctionCase(
    'getbanreason',
    r'$getBanReason[((opts.user))]',
    0,
    'Previous violation',
    label: 'dynamic user ID in a nested placeholder',
    scenario: {
      'entities': _moderation,
      'options': {'user': '22'},
    },
    expectedValues: {'/entity_requests/0/user_id': '22'},
  ),
  SandboxFunctionCase(
    'clear',
    r'$clear[2;21;no]',
    0,
    '',
    label: 'deletes only matching user messages and preserves pinned messages',
    scenario: {'entities': _messages},
    expectedValues: {
      '/effects/0/type': 'deleteMessages',
      '/effects/0/deleted_ids': ['104', '102'],
      '/effects/0/remaining_ids': ['103', '101'],
      '/effects/0/only_user_id': '21',
      '/effects/0/remove_pinned': false,
    },
  ),
  SandboxFunctionCase(
    'clear',
    r'$clear',
    0,
    '',
    label: 'simple form uses the first command argument',
    scenario: {
      'entities': _messages,
      'variables': {'message.content': '2'},
    },
    expectedValues: {
      '/effects/0/deleted_ids': ['104', '103'],
      '/effects/0/deleted_count': 2,
    },
  ),
  SandboxFunctionCase(
    'istimedout',
    r'$isTimedOut[21]',
    0,
    'true',
    label: 'future member timeout is fetched through the entity gateway',
    scenario: {
      'entities': {
        'guilds': {
          '10': {
            'owner_id': '99',
            'roles': <Map<String, dynamic>>[],
            'members': {
              '21': {
                'roles': <String>[],
                'timeout_until': '2099-01-01T00:00:00Z',
              },
            },
          },
        },
      },
    },
    expectedValues: {
      '/entity_requests/0/operation': 'members.fetch',
      '/variables/member[21].isTimedOut': 'true',
    },
  ),
  SandboxFunctionCase(
    'istimedout',
    r'$isTimedOut[21]',
    0,
    'false',
    label: 'expired timeout resolves false',
    scenario: {
      'entities': {
        'guilds': {
          '10': {
            'owner_id': '99',
            'roles': <Map<String, dynamic>>[],
            'members': {
              '21': {
                'roles': <String>[],
                'timeout_until': '2020-01-01T00:00:00Z',
              },
            },
          },
        },
      },
    },
    expectedValues: {'/variables/member[21].isTimedOut': 'false'},
  ),
  SandboxFunctionCase(
    'ban',
    r'$ban[Spam]',
    0,
    '',
    scenario: {
      'entities': _moderation,
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {
      '/effects/0/type': 'banUser',
      '/effects/0/user_id': '21',
      '/effects/0/after/ban_reason': 'Spam',
      '/effects/0/after/member': null,
      '/effects/0/simulated': true,
    },
  ),
  SandboxFunctionCase(
    'banid',
    r'$banID[Spam;21]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'banUser',
      '/effects/0/user_id': '21',
      '/effects/0/after/ban_reason': 'Spam',
    },
  ),
  SandboxFunctionCase(
    'banid',
    r'$banID',
    0,
    '',
    label: 'simple form reads last message argument',
    scenario: {
      'entities': _moderation,
      'variables': {'message.content': '!ban 21'},
    },
    expectedValues: {'/effects/0/user_id': '21'},
  ),
  SandboxFunctionCase(
    'unbanid',
    r'$unbanID[22]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'unbanUser',
      '/effects/0/user_id': '22',
      '/effects/0/before/ban_reason': 'Previous violation',
      '/effects/0/after/ban_reason': null,
    },
  ),
  SandboxFunctionCase(
    'unbanid',
    r'$unbanID',
    0,
    '',
    label: 'simple form reads last message argument',
    scenario: {
      'entities': _moderation,
      'variables': {'message.content': '!unban 22'},
    },
    expectedValues: {'/effects/0/user_id': '22'},
  ),
  SandboxFunctionCase(
    'kick',
    r'$kick[21;Raid]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'kickUser',
      '/effects/0/user_id': '21',
      '/effects/0/reason': 'Raid',
      '/effects/0/after/member': null,
    },
  ),
  SandboxFunctionCase(
    'kickmention',
    r'$kickMention[Raid]',
    0,
    '',
    scenario: {
      'entities': _moderation,
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {
      '/effects/0/type': 'kickUser',
      '/effects/0/user_id': '21',
      '/effects/0/reason': 'Raid',
    },
  ),
  SandboxFunctionCase(
    'timeout',
    r'$timeout[15m;21]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'muteUser',
      '/effects/0/after/member/timeout_seconds': 900,
    },
  ),
  SandboxFunctionCase(
    'untimeout',
    r'$untimeout[21]',
    0,
    '',
    scenario: {'entities': _moderation},
    expectedValues: {
      '/effects/0/type': 'unmuteUser',
      '/effects/0/user_id': '21',
      '/effects/0/after/member': {'roles': <String>[]},
    },
  ),
  SandboxFunctionCase(
    'mute',
    r'$mute[Muted]',
    0,
    '',
    scenario: {
      'entities': _moderation,
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {
      '/effects/0/type': 'addRole',
      '/effects/0/user_id': '21',
      '/effects/0/role_ids': ['60'],
    },
  ),
  SandboxFunctionCase(
    'unmute',
    r'$unmute[Muted]',
    0,
    '',
    scenario: {
      'entities': {
        'guilds': {
          '10': {
            'owner_id': '99',
            'roles': [
              {'id': '60', 'name': 'Muted', 'position': 1, 'permissions': '0'},
            ],
            'members': {
              '21': {
                'roles': ['60'],
              },
            },
            'bans': <String, String>{},
          },
        },
      },
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {
      '/effects/0/type': 'removeRole',
      '/effects/0/user_id': '21',
      '/effects/0/after': <String>[],
    },
  ),
  SandboxFunctionCase(
    'registerguildcommands',
    r'$registerGuildCommands[10]',
    0,
    '',
    label: 'registers commands for a guild',
    expectedValues: {
      '/effects/0/type': 'registerGuildCommands',
      '/effects/0/guild_id': '10',
    },
  ),
  SandboxFunctionCase(
    'unregisterguildcommands',
    r'$unregisterGuildCommands[10]',
    0,
    '',
    label: 'unregisters commands for a guild',
    expectedValues: {
      '/effects/0/type': 'unregisterGuildCommands',
      '/effects/0/guild_id': '10',
    },
  ),
];
