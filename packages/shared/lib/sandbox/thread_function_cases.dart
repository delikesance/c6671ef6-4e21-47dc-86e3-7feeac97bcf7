import 'function_suite.dart';

const _threadGuild = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
        {
          'id': '50',
          'name': 'Discussion',
          'type': 'thread',
          'parent_id': '30',
          'message_count': 12,
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
    '9002',
    scenario: {'entities': _threadGuild},
    expectedValues: {
      '/effects/0/type': 'createThread',
      '/effects/0/thread/name': 'Support',
      '/variables/thread.lastId': '9002',
    },
    label: 'creates a public thread and returns its ID',
  ),
  SandboxFunctionCase(
    'editthread',
    r'$editThread[50;Renamed;yes;1440;yes;5]',
    0,
    '',
    scenario: {'entities': _threadGuild},
    expectedValues: {
      '/effects/0/type': 'updateChannel',
      '/effects/0/after/name': 'Renamed',
      '/effects/0/after/archived': true,
      '/effects/0/after/locked': true,
    },
  ),
  SandboxFunctionCase(
    'threadaddmember',
    r'$threadAddMember[50;22]',
    0,
    '',
    scenario: {'entities': _threadGuild},
    expectedValues: {
      '/effects/0/type': 'addThreadMember',
      '/effects/0/after': ['20', '21', '22'],
    },
  ),
  SandboxFunctionCase(
    'threadremovemember',
    r'$threadRemoveMember[50;21]',
    0,
    '',
    scenario: {'entities': _threadGuild},
    expectedValues: {
      '/effects/0/type': 'removeThreadMember',
      '/effects/0/after': ['20'],
    },
  ),
  SandboxFunctionCase(
    'threadmessagecount',
    r'$threadMessageCount',
    0,
    '12',
    scenario: {
      'variables': {'thread.messageCount': '12'},
    },
    label: 'reads the count extracted from the current thread',
  ),
  SandboxFunctionCase(
    'threadusercount',
    r'$threadUserCount',
    0,
    '2',
    scenario: {
      'variables': {'thread.memberCount': '2'},
    },
    label: 'reads the approximate member count from the current thread',
  ),
];
