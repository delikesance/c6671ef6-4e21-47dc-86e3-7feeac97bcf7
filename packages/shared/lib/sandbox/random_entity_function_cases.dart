import 'function_suite.dart';

const _oneTextChannel = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '31', 'name': 'logs', 'type': 'text'},
      ],
    },
  },
};

const _oneCategory = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '40', 'name': 'Information', 'type': 'category'},
      ],
    },
  },
};

const _oneRole = {
  'guilds': {
    '10': {
      'roles': [
        {'id': '80', 'name': 'Visitor'},
      ],
    },
  },
};

const _oneMember = {
  'guilds': {
    '10': {
      'members': {
        '80': {'nick': 'Visitor'},
      },
    },
  },
};

final sandboxRandomEntityFunctionCases = [
  SandboxFunctionCase(
    'randomuserid',
    r'$randomUserID',
    0,
    '80',
    label: 'chooses a guild member instead of the command author',
    scenario: {'entities': _oneMember},
    expectedValues: {'/entity_requests/0/operation': 'members.list'},
  ),
  SandboxFunctionCase(
    'randomuser',
    r'$randomUser',
    0,
    'Visitor',
    scenario: {'entities': _oneMember},
  ),
  SandboxFunctionCase(
    'randommention',
    r'$randomMention',
    0,
    '<@80>',
    scenario: {'entities': _oneMember},
  ),
  for (final name in ['randomuserid', 'randomuser', 'randommention'])
    SandboxFunctionCase(
      name,
      '\$$name',
      0,
      '',
      label: 'no server members returns empty',
      scenario: {
        'entities': {
          'guilds': {
            '10': {'members': <String, dynamic>{}},
          },
        },
      },
    ),
  SandboxFunctionCase(
    'randomguildid',
    r'$randomGuildID',
    0,
    '11',
    label: 'chooses from bot guilds, not the current guild',
    scenario: {
      'entities': {
        'guilds': {'11': <String, dynamic>{}},
      },
    },
  ),
  SandboxFunctionCase(
    'randomguildid',
    r'$randomGuildID',
    0,
    '',
    label: 'no cached guilds returns empty',
    scenario: {
      'entities': {'guilds': <String, dynamic>{}},
    },
  ),
  SandboxFunctionCase(
    'randomchannelid',
    r'$randomChannelID',
    0,
    '31',
    label: 'chooses from server channels, not the current channel',
    scenario: {'entities': _oneTextChannel},
  ),
  SandboxFunctionCase(
    'randomcategoryid',
    r'$randomCategoryID',
    0,
    '40',
    label: 'chooses a category, not the current parent',
    scenario: {'entities': _oneCategory},
  ),
  SandboxFunctionCase(
    'randomcategoryid',
    r'$channelName[$randomCategoryID]',
    0,
    'Information',
    label: 'random category is usable in a nested channel lookup',
    scenario: {'entities': _oneCategory},
  ),
  SandboxFunctionCase(
    'randomcategoryid',
    r'$randomCategoryID',
    0,
    '',
    label: 'no categories returns empty',
    scenario: {'entities': _oneTextChannel},
  ),
  SandboxFunctionCase(
    'randomroleid',
    r'$randomRoleID',
    0,
    '80',
    label: 'chooses from server roles, not member roles',
    scenario: {'entities': _oneRole},
  ),
  SandboxFunctionCase(
    'randomroleid',
    r'$roleName[$randomRoleID]',
    0,
    'Visitor',
    label: 'random role is usable in a nested role lookup',
    scenario: {'entities': _oneRole},
  ),
  SandboxFunctionCase(
    'randomroleid',
    r'$randomRoleID',
    0,
    '',
    label: 'no roles returns empty',
    scenario: {
      'entities': {
        'guilds': {
          '10': {'roles': []},
        },
      },
    },
  ),
];
