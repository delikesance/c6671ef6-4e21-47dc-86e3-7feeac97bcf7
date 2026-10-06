import 'function_suite.dart';

const _threadGuild = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {'id': '70', 'name': 'Bot', 'position': 10, 'permissions': '8'},
      ],
      'members': {
        '20': {'roles': <String>[]},
        '21': {'roles': <String>[]},
        '22': {'roles': <String>[]},
        '51': {
          'roles': ['70'],
        },
      },
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
      ],
      'threads': [
        {
          'id': '50',
          'name': 'Discussion',
          'type': 'public_thread',
          'parent_id': '30',
          'message_count': 12,
          'member_count': 2,
          'members': ['20', '21'],
          'archived': false,
          'locked': false,
        },
      ],
    },
  },
};

const sandboxThreadFunctionCases = [
  SandboxFunctionCase(
    'startthread',
    r'$startThread[Support;30;;;yes]',
    0,
    '200000',
    scenario: {
      'variables': {'bot.id': '51'},
      'entities': _threadGuild,
    },
    expectedValues: {
      '/effects/0/type': 'startThread',
      '/effects/0/thread_id': '200000',
      '/effects/0/after/name': 'Support',
    },
    label: 'creates a public thread and returns its ID',
  ),
  SandboxFunctionCase(
    'editthread',
    r'$editThread[50;Renamed;no;1440;yes;5]',
    0,
    '',
    scenario: {
      'variables': {'bot.id': '51'},
      'entities': _threadGuild,
    },
    expectedValues: {
      '/effects/0/type': 'editThread',
      '/effects/0/after/name': 'Renamed',
      '/effects/0/after/archived': false,
      '/effects/0/after/locked': true,
    },
  ),
  SandboxFunctionCase(
    'threadaddmember',
    r'$threadAddMember[50;22]',
    0,
    '',
    scenario: {
      'variables': {'bot.id': '51'},
      'entities': _threadGuild,
    },
    expectedValues: {
      '/effects/0/type': 'threadAddMember',
      '/effects/0/after/members': ['20', '21', '22'],
    },
  ),
  SandboxFunctionCase(
    'threadremovemember',
    r'$threadRemoveMember[50;21]',
    0,
    '',
    scenario: {
      'variables': {'bot.id': '51'},
      'entities': _threadGuild,
    },
    expectedValues: {
      '/effects/0/type': 'threadRemoveMember',
      '/effects/0/after/members': ['20'],
    },
  ),
  SandboxFunctionCase(
    'threadmessagecount',
    r'$threadMessageCount',
    0,
    '12',
    scenario: {
      'entities': _threadGuild,
      'variables': {'bot.id': '51', 'channel.id': '50'},
    },
    label: 'reads the count extracted from the current thread',
  ),
  SandboxFunctionCase(
    'threadusercount',
    r'$threadUserCount',
    0,
    '2',
    scenario: {
      'entities': _threadGuild,
      'variables': {'bot.id': '51', 'channel.id': '50'},
    },
    label: 'reads the approximate member count from the current thread',
  ),
];
