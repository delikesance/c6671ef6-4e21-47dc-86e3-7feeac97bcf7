import 'function_suite.dart';

const roleEntityFixture = {
  'guilds': {
    '10': {
      'roles': [
        {
          'id': '60',
          'name': 'Cor Branca',
          'color': 16777215,
          'position': 4,
          'permissions': '8',
          'hoist': true,
          'mentionable': false,
        },
        {
          'id': '61',
          'name': 'Cor Preta',
          'color': 0,
          'position': 3,
          'permissions': '0',
          'hoist': false,
          'mentionable': true,
        },
      ],
    },
  },
};

final sandboxRoleFunctionCases = [
  SandboxFunctionCase(
    'rolename',
    r'$for[id;$message[a];$message[b]]$roleName[$id]$endfor',
    0,
    'Cor BrancaCor Preta',
    label: 'target changes on each iteration',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'entities': roleEntityFixture,
      'options': {'a': '60', 'b': '61'},
    },
  ),
  for (final item in [
    ('roleid', r'$roleID[Cor Branca]', '60'),
    ('findrole', r'$findRole[Cor Preta]', '61'),
    ('rolename', r'$roleName[60]', 'Cor Branca'),
    ('roleperms', r'$rolePerms[10;60]', 'Administrator'),
    ('roleposition', r'$rolePosition[60]', '1'),
    ('getrolecolor', r'$getRoleColor[60]', 'FFFFFF'),
    ('ishoisted', r'$isHoisted[60]', 'true'),
    ('ismentionable', r'$isMentionable[60]', 'false'),
    ('roleexists', r'$roleExists[60]', 'true'),
    ('roleexists', r'$roleExists[999]', 'false'),
  ])
    SandboxFunctionCase(
      item.$1,
      item.$2,
      0,
      item.$3,
      label: 'production fetcher with role fixtures',
      scenario: {'entities': roleEntityFixture},
    ),
  SandboxFunctionCase(
    'roleinfo',
    r'$roleInfo[Name: {name} | ID: {ID} | Hoisted: {hoist} | Mentionable: {mentionable} | Color: {color} | Position: {position}]',
    0,
    '',
    label: 'formats the mentioned role into the embed description',
    scenario: {
      'variables': {'message.roleMentions[0]': '60'},
      'entities': roleEntityFixture,
    },
    expectedValues: {
      '/responses/0/payload/embeds/0/description':
          'Name: Cor Branca | ID: 60 | Hoisted: true | Mentionable: false | Color: FFFFFF | Position: 1',
    },
  ),
  SandboxFunctionCase(
    'roleid',
    r'$roleID[$message[name]]',
    0,
    '60',
    label: 'runtime name',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'entities': roleEntityFixture,
      'options': {'name': 'Cor Branca'},
    },
  ),
  SandboxFunctionCase(
    'rolename',
    r'$roleName[$message[role]]',
    0,
    'Cor Preta',
    label: 'runtime ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'entities': roleEntityFixture,
      'options': {'role': '61'},
    },
  ),
  SandboxFunctionCase(
    'roleid',
    r'$roleID[absent]',
    0,
    '',
    label: 'missing name',
    scenario: {'entities': roleEntityFixture},
  ),
  SandboxFunctionCase(
    'getrolecolor',
    r'$getRoleColor[61]',
    0,
    '000000',
    label: 'black color',
    scenario: {'entities': roleEntityFixture},
  ),
];
