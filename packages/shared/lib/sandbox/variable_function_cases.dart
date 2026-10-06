import 'function_suite.dart';

const _leaderUsers = {
  'users': {
    '20': {'username': 'alice'},
    '21': {'username': 'bob'},
  },
};

final sandboxVariableFunctionCases = [
  SandboxFunctionCase(
    'resetglobaluservar',
    r'$resetGlobalUserVar[score;20]|$getVar[score;20]|$getVar[score;21]',
    0,
    '|7|80',
    label: 'with a user ID, resets only that user in the global-user storage',
    scenario: {
      'scoped': {
        'user': {
          '20': {'score': 9},
          '21': {'score': 80},
        },
      },
      'definitions': [
        {'scope': 'user', 'key': 'score', 'defaultValue': 7},
      ],
    },
    expectedValues: {
      '/storage_after/scoped/user/20/score': 7,
      '/storage_after/scoped/user/21/score': 80,
    },
  ),
  SandboxFunctionCase(
    'resetglobaluservar',
    r'$resetGlobalUserVar[score]|$getVar[score;20]|$getVar[score;21]',
    0,
    '|7|7',
    label: 'without a user ID, resets the variable for every user',
    scenario: {
      'scoped': {
        'user': {
          '20': {'score': 9},
          '21': {'score': 80},
        },
      },
      'definitions': [
        {'scope': 'user', 'key': 'score', 'defaultValue': 7},
      ],
    },
    expectedValues: {
      '/storage_after/scoped/user/20/score': 7,
      '/storage_after/scoped/user/21/score': 7,
    },
  ),
  // Wiki: resets to the app-declared default for every context (or only the
  // provided user for user-scoped functions).
  for (final item in [
    ('resetuservar', 'getUserVar', 'guildMember', '10:20', '10:21', ';21'),
    ('resetservervar', 'getServerVar', 'guild', '10', '11', ''),
    ('resetguildvar', 'getGuildVar', 'guild', '10', '11', ''),
    ('resetchannelvar', 'getChannelVar', 'channel', '30', '31', ''),
    (
      'resetmembervar',
      'getMemberVar',
      'guildMember',
      '10:20',
      '10:21',
      ';21;10',
    ),
    (
      'resetguildmembervar',
      'getGuildMemberVar',
      'guildMember',
      '10:20',
      '10:21',
      ';21;10',
    ),
  ]) ...[
    SandboxFunctionCase(
      item.$1,
      '\$var[before;\$${item.$2}[score]]\$${item.$1}[score]\$var[before]|\$${item.$2}[score]',
      0,
      '9|7',
      label: 'restores the declared default for every context',
      scenario: {
        'scoped': {
          item.$3: {
            item.$4: {'score': 9},
            item.$5: {'score': 80},
          },
        },
        'definitions': [
          {'scope': item.$3, 'key': 'score', 'defaultValue': 7},
        ],
      },
      expectedValues: {
        '/storage_after/scoped/${item.$3}/${item.$4}/score': 7,
        '/storage_after/scoped/${item.$3}/${item.$5}/score': 7,
      },
    ),
    if (item.$6.isNotEmpty)
      SandboxFunctionCase(
        item.$1,
        '\$var[before;\$${item.$2}[score${item.$6}]]\$${item.$1}[score${item.$6}]\$var[before]|\$${item.$2}[score${item.$6}]|\$${item.$2}[score]',
        0,
        '80|7|9',
        label: 'explicit target preserves author context',
        scenario: {
          'scoped': {
            item.$3: {
              item.$4: {'score': 9},
              item.$5: {'score': 80},
            },
          },
          'definitions': [
            {'scope': item.$3, 'key': 'score', 'defaultValue': 7},
          ],
        },
        expectedValues: {
          '/storage_after/scoped/${item.$3}/${item.$4}/score': 9,
          '/storage_after/scoped/${item.$3}/${item.$5}/score': 7,
        },
      ),
  ],
  SandboxFunctionCase(
    'resetuservar',
    r'$resetUserVar[score]',
    0,
    '',
    label: 'a variable without a declared default is rejected',
    scenario: {
      'scoped': {
        'guildMember': {
          '10:20': {'score': 9},
        },
      },
    },
    expectedValues: {
      '/success': false,
      '/error':
          'BDFD L1:1 \$resetUserVar: No declared default for guildMember variable "score".',
    },
  ),
  SandboxFunctionCase(
    'resetuservar',
    r'$resetUserVar[$message[key]]$getUserVar[score]',
    0,
    '0',
    label: 'dynamic key and zero default',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'key': 'score'},
      'scoped': {
        'guildMember': {
          '10:20': {'score': 9},
        },
      },
      'definitions': [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': 0},
      ],
    },
    expectedValues: {'/storage_after/scoped/guildMember/10:20/score': 0},
  ),
  SandboxFunctionCase(
    'var',
    r'$var[Name;first]$var[Name;second]$var[Name]',
    0,
    'second',
    label: 'overwrite keeps the latest value',
  ),
  SandboxFunctionCase(
    'var',
    r'$var[Name;first]$var[NAME;second]$var[Name]|$var[NAME]',
    0,
    'first|second',
    label: 'names are case-sensitive',
  ),
  SandboxFunctionCase(
    'var',
    r'$var[missing]done',
    0,
    'done',
    label: 'unset temporary variable is empty',
  ),
  SandboxFunctionCase(
    'varexists',
    r'$varExists[score]|$varExists[missing]',
    0,
    'true|false',
    label: 'checks variables declared in the app',
    scenario: {
      'definitions': [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': 0},
      ],
    },
  ),
  SandboxFunctionCase(
    'varexisterror',
    r'$varExistError[missing;Add the variable in the app.]done',
    0,
    'Add the variable in the app.',
    label: 'returns the custom error when the variable is not declared',
    expectedValues: {'/stopped': true},
  ),
  SandboxFunctionCase(
    'varexisterror',
    r'$varExistError[score;Add the variable in the app.]done',
    0,
    'done',
    label: 'continues when the variable is declared',
    scenario: {
      'definitions': [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': 0},
      ],
    },
    expectedValues: {'/stopped': false},
  ),
  SandboxFunctionCase(
    'listvar',
    r'$listVar',
    0,
    'score, coins',
    label: 'names of declared variables',
    scenario: {
      'definitions': [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': 0},
        {'scope': 'guild', 'key': 'coins', 'defaultValue': 0},
      ],
    },
  ),
  SandboxFunctionCase(
    'listvar',
    r'$listVar[$message[separator]]',
    0,
    'score | coins',
    label: 'custom separator',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'separator': ' | '},
      'definitions': [
        {'scope': 'guildMember', 'key': 'score', 'defaultValue': 0},
        {'scope': 'guild', 'key': 'coins', 'defaultValue': 0},
      ],
    },
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$variablesCount[user]|$variablesCount[server]|$variablesCount[channel]|$variablesCount[globaluser]',
    0,
    '2|1|2|1',
    label: 'counts declared variables per type',
    scenario: {
      'definitions': [
        {'scope': 'guildMember', 'key': 'a', 'defaultValue': 0},
        {'scope': 'guildMember', 'key': 'b', 'defaultValue': 0},
        {'scope': 'guild', 'key': 'c', 'defaultValue': 0},
        {'scope': 'channel', 'key': 'd', 'defaultValue': 0},
        {'scope': 'channel', 'key': 'e', 'defaultValue': 0},
        {'scope': 'user', 'key': 'f', 'defaultValue': 0},
      ],
    },
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$variablesCount[unknown]',
    0,
    '',
    label: 'unknown type is rejected',
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $variablesCount: Unknown variable type.',
    },
  ),
  SandboxFunctionCase(
    'enabledecimals',
    r'$enableDecimals[yes]$var[value;0.5]$sum[$var[value];0.25]',
    0,
    '0.75',
    label: 'decimal flag applies to runtime math',
  ),
  SandboxFunctionCase(
    'var',
    r'$var[debug_last_var;mine]$setUserVar[score;9]$var[debug_last_var]',
    0,
    'mine',
    label: 'engine diagnostics cannot overwrite user temporary value',
  ),
  SandboxFunctionCase(
    'getleaderboardposition',
    r'$getLeaderboardPosition[globalUser;coins;desc;21]|$getLeaderboardPosition[globalUser;coins;asc;21]|$getLeaderboardPosition[globalUser;coins;desc]',
    0,
    '2|1|1',
    scenario: {
      'entities': _leaderUsers,
      'scoped': {
        'user': {
          '20': {'coins': 100},
          '21': {'coins': 80},
        },
      },
    },
    label: 'returns leaderboard rank for a user, defaulting to the author',
  ),
  SandboxFunctionCase(
    'getleaderboardvalue',
    r'$getLeaderboardValue[globalUser;coins;desc;1;value]|$getLeaderboardValue[globalUser;coins;desc;2;id]|$getLeaderboardValue[globalUser;coins;desc;1]',
    0,
    '100|21|alice - 100',
    scenario: {
      'entities': _leaderUsers,
      'scoped': {
        'user': {
          '20': {'coins': 100},
          '21': {'coins': 80},
        },
      },
    },
    label: 'returns the value, ID or label at a leaderboard position',
  ),
  SandboxFunctionCase(
    'globaluserleaderboard',
    r'$globalUserLeaderboard[coins;desc]',
    0,
    '',
    scenario: {
      'entities': _leaderUsers,
      'scoped': {
        'user': {
          '20': {'coins': 100},
          '21': {'coins': 80},
        },
      },
    },
    expectedValues: {
      '/responses/0/payload/embeds/0/description':
          '1. alice - 100\n2. bob - 80',
    },
    label: 'formats global user leaderboard',
  ),
  SandboxFunctionCase(
    'userleaderboard',
    r'$userLeaderboard[score;asc]',
    0,
    '',
    scenario: {
      'entities': _leaderUsers,
      'scoped': {
        'guildMember': {
          '10:20': {'score': 100},
          '10:21': {'score': 80},
          '11:20': {'score': 5},
        },
      },
    },
    expectedValues: {
      '/responses/0/payload/embeds/0/description':
          '1. bob - 80\n2. alice - 100',
    },
    label: 'formats the current guild user leaderboard in ascending order',
  ),
  SandboxFunctionCase(
    'serverleaderboard',
    r'$serverLeaderboard[score]',
    0,
    '',
    scenario: {
      'entities': {
        'guilds': {
          '10': {'name': 'Guild A'},
          '11': {'name': 'Guild B'},
        },
      },
      'scoped': {
        'guild': {
          '10': {'score': 500},
          '11': {'score': 300},
        },
      },
    },
    expectedValues: {
      '/responses/0/payload/embeds/0/description':
          '1. Guild A - 500\n2. Guild B - 300',
    },
    label: 'formats server leaderboard',
  ),
];
