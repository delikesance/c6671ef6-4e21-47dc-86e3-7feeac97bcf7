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
    expectedValues: {
      '/entity_requests/0/operation': 'members.search',
      '/variables/userFind[bob;no].id': '21',
    },
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
      '/variables/user[21].exists': 'true',
    },
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[99]',
    0,
    'false',
    label: 'missing Discord user',
    scenario: {'entities': _users},
    expectedValues: {'/variables/user[99].exists': 'false'},
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[invalid]',
    0,
    'false',
    label: 'invalid user ID',
    scenario: {'entities': _users},
    expectedValues: {'/entity_requests': []},
  ),
  SandboxFunctionCase(
    'userexists',
    r'$userExists[((opts.user))]',
    0,
    'true',
    label: 'runtime user ID',
    scenario: {
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
    r'$userInfo[20]',
    0,
    'Alice Info',
    scenario: {
      'variables': {'user[20].info': 'Alice Info'},
    },
    label: 'returns user summary info',
  ),
];
