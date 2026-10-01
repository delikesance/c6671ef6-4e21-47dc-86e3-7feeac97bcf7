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
    r'$for[id;((opts.a));((opts.b))]$roleName[$id]$endfor',
    0,
    'Cor Branca\nCor Preta',
    label: 'target changes on each iteration',
    scenario: {
      'entities': roleEntityFixture,
      'options': {'a': '60', 'b': '61'},
    },
  ),
  for (final item in [
    ('roleid', r'$roleID[Cor Branca]', '60'),
    ('findrole', r'$findRole[Cor Preta]', '61'),
    ('rolename', r'$roleName[60]', 'Cor Branca'),
    ('roleperms', r'$rolePerms[60]', '8'),
    ('roleposition', r'$rolePosition[60]', '4'),
    ('getrolecolor', r'$getRoleColor[60]', 'ffffff'),
    ('ishoisted', r'$isHoisted[60]', 'true'),
    ('ismentionable', r'$isMentionable[60]', 'false'),
    ('roleexists', r'$roleExists[60]', 'true'),
    ('roleexists', r'$roleExists[999]', 'false'),
    ('roleinfo', r'$roleInfo[60;name]', 'Cor Branca'),
    (
      'roleinfo',
      r'$roleInfo[60]',
      '{"id":"60","name":"Cor Branca","color":"ffffff","position":4,"permissions":"8","mentionable":false,"hoist":true}',
    ),
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
    'roleid',
    r'$roleID[((opts.name))]',
    0,
    '60',
    label: 'runtime name',
    scenario: {
      'entities': roleEntityFixture,
      'options': {'name': 'Cor Branca'},
    },
  ),
  SandboxFunctionCase(
    'rolename',
    r'$roleName[((opts.role))]',
    0,
    'Cor Preta',
    label: 'runtime ID',
    scenario: {
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
