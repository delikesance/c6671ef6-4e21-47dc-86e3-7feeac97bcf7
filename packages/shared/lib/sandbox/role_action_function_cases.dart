import 'function_suite.dart';

const _roleActions = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {
          'id': '60',
          'name': 'Cor Branca',
          'color': 1122867,
          'position': 3,
          'permissions': '0',
          'hoist': false,
          'mentionable': false,
        },
        {'id': '61', 'name': 'Cor Preta', 'position': 2, 'permissions': '0'},
        {'id': '62', 'name': 'Cor Azul', 'position': 1, 'permissions': '0'},
      ],
      'members': {
        '20': {
          'roles': ['61'],
        },
      },
    },
  },
};

const sandboxRoleActionFunctionCases = [
  SandboxFunctionCase(
    'giverole',
    r'$giveRole[((opts.user));((opts.role))]',
    0,
    '',
    label: 'dynamic user and role IDs are applied only to fixture state',
    scenario: {
      'options': {'user': '20', 'role': '60'},
      'entities': _roleActions,
    },
    expectedValues: {
      '/effects/0/type': 'addRole',
      '/effects/0/user_id': '20',
      '/effects/0/role_ids': ['60'],
      '/effects/0/after': ['61', '60'],
      '/effects/0/simulated': true,
    },
  ),
  SandboxFunctionCase(
    'giverole',
    r'$giveRole[60]',
    0,
    '',
    label: 'single role argument uses the command author',
    scenario: {'entities': _roleActions},
    expectedValues: {'/effects/0/user_id': '20'},
  ),
  SandboxFunctionCase(
    'takerole',
    r'$takeRole[20;61]',
    0,
    '',
    label: 'removes the specified role',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/type': 'removeRole',
      '/effects/0/before': ['61'],
      '/effects/0/after': [],
    },
  ),
  SandboxFunctionCase(
    'giveroles',
    r'$giveRoles[20;60;62]',
    0,
    '',
    label: 'each supplied role is added in order',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/role_ids': ['60'],
      '/effects/1/role_ids': ['62'],
      '/effects/1/after': ['61', '60', '62'],
    },
  ),
  SandboxFunctionCase(
    'takeroles',
    r'$takeRoles[20;61;62]',
    0,
    '',
    label: 'each supplied role is removed in order',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/role_ids': ['61'],
      '/effects/1/role_ids': ['62'],
      '/effects/1/after': [],
    },
  ),
  SandboxFunctionCase(
    'rolegrant',
    r'$roleGrant[20;+((opts.role));-61]',
    0,
    '',
    label: 'adds and removes roles in one command',
    scenario: {
      'options': {'role': '60'},
      'entities': _roleActions,
    },
    expectedValues: {
      '/effects/0/type': 'addRole',
      '/effects/1/type': 'removeRole',
      '/effects/1/after': ['60'],
    },
  ),
  SandboxFunctionCase(
    'setuserroles',
    r'$setUserRoles[20;((opts.white));62]',
    0,
    '',
    label: 'replaces old roles with dynamically supplied IDs',
    scenario: {
      'options': {'white': '60'},
      'entities': _roleActions,
    },
    expectedValues: {
      '/effects/0/type': 'setUserRoles',
      '/effects/0/before': ['61'],
      '/effects/0/after': ['60', '62'],
    },
  ),
  SandboxFunctionCase(
    'giverole',
    r'$giveRole[20;60]$hasRole[20;60]',
    0,
    'true',
    label: 'a subsequent role lookup observes the simulated write',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/after': ['61', '60'],
    },
  ),
  SandboxFunctionCase(
    'setuserroles',
    r'$setUserRoles[20;60]$hasRole[20;61]',
    0,
    'false',
    label: 'replacing roles removes the old role from later lookups',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/after': ['60'],
    },
  ),
  SandboxFunctionCase(
    'createrole',
    r'$createRole[((opts.name));#00FF00;yes;no]$roleID[((opts.name))]',
    0,
    '63',
    label: 'creates a role and exposes its dynamic name for a later lookup',
    scenario: {
      'options': {'name': 'Cor Verde'},
      'entities': _roleActions,
    },
    expectedValues: {
      '/effects/0/type': 'createRole',
      '/effects/0/after/name': 'Cor Verde',
      '/effects/0/after/color': 65280,
      '/effects/0/after/hoist': true,
    },
  ),
  SandboxFunctionCase(
    'deleterole',
    r'$deleteRole[62]$roleExists[62]',
    0,
    'false',
    label: 'deleted role becomes unavailable to later lookups',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/type': 'deleteRole',
      '/effects/0/role_id': '62',
      '/effects/0/after': null,
    },
  ),
  SandboxFunctionCase(
    'colorrole',
    r'$colorRole[((opts.color))]',
    0,
    '',
    label: 'changes the mentioned role color',
    scenario: {
      'options': {'color': '#FF0000'},
      'variables': {'message.roleMentions[0]': '60'},
      'entities': _roleActions,
    },
    expectedValues: {
      '/effects/0/type': 'colorRole',
      '/effects/0/role_id': '60',
      '/effects/0/after/color': 16711680,
    },
  ),
  SandboxFunctionCase(
    'modifyrole',
    r'$modifyRole[60;Blue;!unchanged;yes;!unchanged]$roleName[60]',
    0,
    'Blue',
    label: 'unchanged fields are preserved while name and hoist change',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/type': 'modifyRole',
      '/effects/0/after/color': 1122867,
      '/effects/0/after/hoist': true,
      '/effects/0/after/mentionable': false,
    },
  ),
  SandboxFunctionCase(
    'modifyroleperms',
    r'$modifyRolePerms[60;admin]$rolePerms[60]',
    0,
    '8',
    label: 'toggles administrator permission on',
    scenario: {'entities': _roleActions},
    expectedValues: {
      '/effects/0/type': 'modifyRolePerms',
      '/effects/0/after/permissions': '8',
    },
  ),
  SandboxFunctionCase(
    'modifyroleperms',
    r'$modifyRolePerms[60;admin]$modifyRolePerms[60;admin]$rolePerms[60]',
    0,
    '0',
    label: 'toggling twice restores the original permission',
    scenario: {'entities': _roleActions},
    expectedValues: {'/effects/1/after/permissions': '0'},
  ),
];
