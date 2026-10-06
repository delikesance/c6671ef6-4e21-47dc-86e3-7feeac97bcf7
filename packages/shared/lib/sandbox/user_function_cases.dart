import 'function_suite.dart';

const _users = {
  'guilds': {
    '10': {
      'members': {
        '20': {'nick': 'Captain Alice'},
        '21': {'nick': 'Bobby'},
      },
    },
  },
  'users': {
    '20': {'username': 'alice', 'global_name': 'Alice'},
    '21': {'username': 'bob', 'bot': true},
  },
};

const sandboxUserFunctionCases = [
  SandboxFunctionCase(
    'finduser',
    r'$findUser[bob;no]',
    0,
    '21',
    scenario: {'entities': _users},
    expectedValues: {'/entity_requests/0/operation': 'members.list'},
  ),
  SandboxFunctionCase(
    'finduser',
    r'$findUser[<@21>;no]',
    0,
    '21',
    label: 'member mention',
    scenario: {'entities': _users},
  ),
  SandboxFunctionCase(
    'finduser',
    r'$findUser[missing;no]',
    0,
    '',
    label: 'no fallback when disabled',
    scenario: {'entities': _users},
  ),
  SandboxFunctionCase(
    'finduser',
    r'$findUser[missing]',
    0,
    '20',
    label: 'author fallback by default',
    scenario: {'entities': _users},
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[21]',
    0,
    'true',
    scenario: {'entities': _users},
    expectedValues: {
      '/entity_requests/0': {'operation': 'users.fetch', 'user_id': '21'},
    },
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[99]',
    0,
    'false',
    label: 'missing Discord user',
    scenario: {'entities': _users},
    expectedValues: {
      '/entity_requests/0': {'operation': 'users.fetch', 'user_id': '99'},
    },
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[invalid]',
    0,
    '',
    label: 'invalid user ID is rejected without a lookup',
    scenario: {'entities': _users},
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $userExists: Invalid user ID.',
      '/entity_requests': [],
    },
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[$message[user]]',
    0,
    'true',
    label: 'runtime user ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'entities': _users,
      'options': {'user': '20'},
    },
  ),
  SandboxFunctionCase(
    'dmchannelid',
    r'$dmChannelID',
    0,
    '555',
    scenario: {
      'variables': {'user.dmChannelId': '555'},
    },
    label: 'returns author DM channel ID',
  ),
  SandboxFunctionCase(
    'getcustomstatus',
    r'$getCustomStatus',
    0,
    'Coding',
    scenario: {
      'variables': {'user.customStatus': 'Coding'},
    },
    label: 'returns author custom status',
  ),
  SandboxFunctionCase(
    'getuserstatus',
    r'$getUserStatus',
    0,
    'online',
    scenario: {
      'variables': {'user.status': 'online'},
    },
    label: 'returns author status',
  ),
  SandboxFunctionCase(
    'hypesquad',
    r'$hypeSquad',
    0,
    'Bravery',
    scenario: {
      'variables': {'user.hypesquad': 'Bravery'},
    },
    label: 'returns author hypesquad house',
  ),
  SandboxFunctionCase(
    'isuserdmenabled',
    r'$isUserDMEnabled',
    0,
    'true',
    scenario: {
      'variables': {'user.dmEnabled': 'true'},
    },
    label: 'returns whether DMs are enabled',
  ),
  SandboxFunctionCase(
    'userbadges',
    r'$userBadges',
    0,
    'Active Developer',
    scenario: {
      'variables': {'user.badges': 'Active Developer'},
    },
    label: 'returns author user badges',
  ),
  SandboxFunctionCase(
    'userinfo',
    r'$userInfo[Username: {username} | ID: {ID} | Bot: {BOT} | Tag: {discriminator}]',
    0,
    '',
    scenario: {
      'entities': _users,
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {
      '/responses/0/payload/embeds/0/description':
          'Username: bob | ID: 21 | Bot: true | Tag: 0',
    },
    label: 'formats the first mentioned user into the embed description',
  ),
];
