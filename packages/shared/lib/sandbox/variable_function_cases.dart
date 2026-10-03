import 'function_suite.dart';

final sandboxVariableFunctionCases = [
  for (final item in [
    ('resetuservar', 'getUserVar', 'guildMember', '10:20', '10:21', ';21'),
    ('resetservervar', 'getServerVar', 'guild', '10', '11', ';11'),
    ('resetguildvar', 'getGuildVar', 'guild', '10', '11', ';11'),
    ('resetchannelvar', 'getChannelVar', 'channel', '30', '31', ';31'),
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
    for (final hasDefault in [false, true])
      SandboxFunctionCase(
        item.$1,
        '\$var[before;\$${item.$2}[score]]\$${item.$1}[score]\$var[before]|\$${item.$2}[score]',
        0,
        hasDefault ? '9|7' : '9|',
        label: hasDefault
            ? 'restore default immediately'
            : 'remove without stale cached read',
        scenario: {
          'scoped': {
            item.$3: {
              item.$4: {'score': 9},
              item.$5: {'score': 80},
            },
          },
          if (hasDefault)
            'definitions': [
              {'scope': item.$3, 'key': 'score', 'defaultValue': 7},
            ],
        },
        expectedValues: {
          '/storage_after/scoped/${item.$3}/${item.$4}': hasDefault
              ? {'score': 7}
              : {},
          '/storage_after/scoped/${item.$3}/${item.$5}':
              item.$1 == 'resetuservar'
              ? (hasDefault ? {'score': 7} : {})
              : {'score': 80},
        },
      ),
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
    r'$resetUserVar[((opts.key))]$getUserVar[score]',
    0,
    '0',
    label: 'dynamic key and zero default',
    scenario: {
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
    r'$var[Name;first]$var[NAME;second]$var[name]',
    0,
    'second',
    label: 'case-insensitive overwrite',
  ),
  SandboxFunctionCase(
    'var',
    r'$var[value;one;two;three]$var[value]',
    0,
    'one;two;three',
    label: 'semicolon value is preserved',
  ),
  SandboxFunctionCase(
    'varexists',
    r'$var[Empty;]$varExists[((opts.key))]|$varExists[missing]',
    0,
    'true|false',
    label: 'empty temporary value exists',
    scenario: {
      'options': {'key': 'eMpTy'},
    },
  ),
  SandboxFunctionCase(
    'varexists',
    r'$setVar[persistent;1]$varExists[persistent]',
    0,
    'false',
    label: 'persistent variable is outside temporary scope',
  ),
  SandboxFunctionCase(
    'varexisterror',
    r'$varExistError[missing]done',
    0,
    'done',
    label: 'documented compatibility no-op',
    expectedValues: {'/storage_after/global': {}, '/stopped': false},
  ),
  SandboxFunctionCase(
    'listvar',
    r'$var[first;one]$var[second;]$listVar',
    0,
    'first: "one", second: ""',
    label: 'names and values, including empty values',
  ),
  SandboxFunctionCase(
    'listvar',
    r'$setVar[hidden;5]$var[item;yes]$listVar[((opts.separator))]',
    0,
    'item: "yes"',
    label: 'persistent values and engine metadata excluded',
    scenario: {
      'options': {'separator': ' | '},
    },
  ),
  SandboxFunctionCase(
    'listvar',
    r'$var[first;one]$var[second;two]$listVar[\n]',
    0,
    'first: "one"\nsecond: "two"',
    label: 'newline separator',
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$var[item;yes]$variablesCount|$variablesCount[temp]|$variablesCount[global]|$variablesCount[user]|$variablesCount[server]',
    0,
    '6|1|2|2|1',
    label: 'all scopes with deduplicated aliases',
    scenario: {
      'global': {'coins': 5, 'level': 0},
      'scoped': {
        'user': {
          '20': {'a': 1, 'b': 2},
        },
        'guild': {
          '10': {'c': 3},
        },
      },
    },
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$var[Name;first]$var[NAME;second]$variablesCount[temp]',
    0,
    '1',
    label: 'case variants count once',
  ),
  SandboxFunctionCase(
    'listvar',
    r'$enableDecimals[yes]$var[_private;1]$listVar',
    0,
    '_private: "1"',
    label: 'user underscore name is distinct from engine metadata',
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$enableDecimals[yes]$var[_private;1]$variablesCount[temp]',
    0,
    '1',
    label: 'internal decimal flag is excluded',
  ),
  SandboxFunctionCase(
    'variablescount',
    r'$resetUserVar[score]$variablesCount[guildMember]',
    0,
    '0',
    label: 'removed aliases are no longer active',
    scenario: {
      'scoped': {
        'guildMember': {
          '10:20': {'score': 9},
        },
      },
    },
  ),
  SandboxFunctionCase(
    'resetuservar',
    r'$resetUserVar[score;21]$getUserVar[score;21]|$getUserVar[score]',
    0,
    '|9',
    label: 'foreign removal preserves author cache',
    scenario: {
      'scoped': {
        'guildMember': {
          '10:20': {'score': 9},
          '10:21': {'score': 80},
        },
      },
    },
    expectedValues: {
      '/storage_after/scoped/guildMember/10:21': {},
      '/storage_after/scoped/guildMember/10:20/score': 9,
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
    'var',
    r'$var[BC_score;first]$var[score;second]$var[BC_score]|$var[score]',
    0,
    'second|second',
    label: 'legacy prefixed alias stays consistent',
  ),
  SandboxFunctionCase(
    'varexists',
    r'$var[score;]$varExists[BC_score]',
    0,
    'true',
    label: 'legacy prefixed name',
  ),
  SandboxFunctionCase(
    'getleaderboardposition',
    r'$getLeaderboardPosition[score;20;desc]',
    0,
    '1',
    scenario: {
      'variables': {'leaderboard.position': '1'},
    },
    label: 'returns leaderboard rank for user',
  ),
  SandboxFunctionCase(
    'getleaderboardvalue',
    r'$getLeaderboardValue[score;1;desc]',
    0,
    '100',
    scenario: {
      'variables': {'leaderboard.value': '100'},
    },
    label: 'returns leaderboard score at position',
  ),
  SandboxFunctionCase(
    'globaluserleaderboard',
    r'$globalUserLeaderboard[score]',
    0,
    '1. Alice - 100\n2. Bob - 80',
    scenario: {
      'variables': {
        'globalUserLeaderboard[score]': '1. Alice - 100\n2. Bob - 80',
      },
    },
    label: 'formats global user leaderboard',
  ),
  SandboxFunctionCase(
    'serverleaderboard',
    r'$serverLeaderboard[score]',
    0,
    '1. Guild A - 500\n2. Guild B - 300',
    scenario: {
      'variables': {
        'serverLeaderboard[score]': '1. Guild A - 500\n2. Guild B - 300',
      },
    },
    label: 'formats server leaderboard',
  ),
  SandboxFunctionCase(
    'userleaderboard',
    r'$userLeaderboard[score]',
    0,
    '1. Alice - 100\n2. Bob - 80',
    scenario: {
      'variables': {'userLeaderboard[score]': '1. Alice - 100\n2. Bob - 80'},
    },
    label: 'formats guild user leaderboard',
  ),
];
