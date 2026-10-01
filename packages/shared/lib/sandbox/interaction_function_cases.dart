import 'function_suite.dart';

// Same flattened fields and JSON collections emitted by interaction events.
final sandboxInteractionFunctionCases = <SandboxFunctionCase>[
  const SandboxFunctionCase(
    'argcount',
    r'$argCount',
    0,
    '3',
    scenario: {
      'variables': {'message.content': 'one two three'},
    },
  ),
  const SandboxFunctionCase(
    'argcount',
    r'$argCount',
    0,
    '0',
    label: 'empty arguments',
  ),
  const SandboxFunctionCase(
    'argscheck',
    r'$argsCheck[>=;2;denied]$setVar[touched;yes]allowed',
    0,
    'allowed',
    scenario: {
      'variables': {'message.content': 'one two'},
    },
    expectedValues: {'/storage_after/global/touched': 'yes', '/stopped': false},
  ),
  const SandboxFunctionCase(
    'argscheck',
    r'$argsCheck[>=;2;denied]$setVar[touched;yes]allowed',
    0,
    'denied',
    label: 'rejected',
    scenario: {
      'variables': {'message.content': 'one'},
    },
    expectedValues: {'/storage_after/global': {}, '/stopped': true},
  ),
  const SandboxFunctionCase(
    'message',
    r'$message[2]',
    0,
    'two',
    scenario: {
      'variables': {'message.content': 'one two three'},
    },
  ),
  const SandboxFunctionCase(
    'message',
    r'$message[((opts.index))]',
    0,
    'two',
    label: 'runtime position',
    scenario: {
      'options': {'index': 2},
      'variables': {'message.content': 'one two three'},
    },
  ),
  const SandboxFunctionCase(
    'message',
    r'$message[((opts.start));((opts.end))]',
    0,
    'two three',
    label: 'runtime range',
    scenario: {
      'options': {'start': 2, 'end': 3},
      'variables': {'message.content': 'one two three four'},
    },
  ),
  const SandboxFunctionCase(
    'mentionedchannels',
    r'$mentionedChannels[((opts.index));((opts.fallback))]',
    0,
    '666',
    label: 'runtime index',
    scenario: {
      'options': {'index': 2, 'fallback': true},
      'variables': {
        'message.channelMentions': '555,666',
        'message.channelMentions[1]': '666',
      },
    },
  ),
  const SandboxFunctionCase(
    'mentioned',
    r'$mentioned[((opts.index));((opts.fallback))]',
    0,
    '222',
    label: 'runtime index',
    scenario: {
      'options': {'index': 2, 'fallback': false},
      'variables': {
        'message.mentions': '111,222',
        'message.mentions[1]': '222',
      },
    },
  ),
  const SandboxFunctionCase(
    'ismentioned',
    r'$isMentioned[((opts.user))]',
    0,
    'true',
    label: 'dynamically selected user is mentioned',
    scenario: {
      'options': {'user': '222'},
      'variables': {'message.mentions': '111,222'},
    },
  ),
  const SandboxFunctionCase(
    'ismentioned',
    r'$isMentioned[22]',
    0,
    'false',
    label: 'user ID must match a whole mention',
    scenario: {
      'variables': {'message.mentions': '111,222'},
    },
  ),
  for (final entry in const [
    (
      'getuserselectuserid',
      'getuserselectuserids',
      'interaction.userSelect',
      'userId',
      'userIds',
    ),
    (
      'getroleselectroleid',
      'getroleselectroleids',
      'interaction.roleSelect',
      'roleId',
      'roleIds',
    ),
    (
      'getchannelselectchannelid',
      'getchannelselectchannelids',
      'interaction.channelSelect',
      'channelId',
      'channelIds',
    ),
    (
      'getmentionableselectuserid',
      'getmentionableselectuserids',
      'interaction.mentionableSelect',
      'userId',
      'userIds',
    ),
    (
      'getstringselectvalue',
      'getstringselectvalues',
      'interaction.stringSelect',
      'value',
      'values',
    ),
  ]) ...[
    for (final index in [1, 2, 4])
      SandboxFunctionCase(
        entry.$1,
        '\$${entry.$1}[((opts.index))]',
        0,
        index == 1
            ? '111'
            : index == 2
            ? '222'
            : '',
        label: 'runtime index $index',
        scenario: {
          'options': {'index': index},
          'variables': {
            '${entry.$3}.${entry.$4}': '111',
            '${entry.$3}.${entry.$4}[1]': '111',
            '${entry.$3}.${entry.$4}[2]': '222',
            '__collection.${entry.$3}.${entry.$4}': '["111","222"]',
          },
        },
      ),
    SandboxFunctionCase(
      entry.$2,
      '\$${entry.$2}[((opts.separator))]',
      0,
      '111|222',
      label: 'runtime separator',
      scenario: {
        'options': {'separator': '|'},
        'variables': {
          '${entry.$3}.${entry.$5}': '111,222',
          '__collection.${entry.$3}.${entry.$5}': '["111","222"]',
        },
      },
    ),
  ],
  for (final entry in const [
    ('getstringselectvalues', 'interaction.stringSelect.values'),
    ('getchannelselectchannelids', 'interaction.channelSelect.channelIds'),
  ])
    SandboxFunctionCase(
      entry.$1,
      '\$${entry.$1}[((opts.separator));((opts.limit))]',
      0,
      '111',
      label: 'runtime limit',
      scenario: {
        'options': {'separator': '|', 'limit': 1},
        'variables': {
          entry.$2: '111,222',
          '__collection.${entry.$2}': '["111","222"]',
        },
      },
    ),
  const SandboxFunctionCase(
    'mentioned',
    r'$mentioned[2]',
    0,
    '222',
    scenario: {
      'variables': {
        'message.mentions': '111,222',
        'message.mentions[0]': '111',
        'message.mentions[1]': '222',
      },
    },
  ),
  const SandboxFunctionCase(
    'mentioned',
    r'$mentioned[3;yes]',
    0,
    '20',
    label: 'self fallback',
    scenario: {
      'variables': {
        'message.mentions': '111,222',
        'message.mentions[0]': '111',
        'message.mentions[1]': '222',
      },
    },
  ),
  const SandboxFunctionCase(
    'mentions',
    r'$mentions',
    0,
    '111,222',
    scenario: {
      'variables': {'message.mentions': '111,222'},
    },
  ),
  const SandboxFunctionCase(
    'mentionedroles',
    r'$mentionedRoles',
    0,
    '333,444',
    scenario: {
      'variables': {'message.roleMentions': '333,444'},
    },
  ),
  const SandboxFunctionCase(
    'mentionedchannels',
    r'$mentionedChannels[2]',
    0,
    '666',
    scenario: {
      'variables': {
        'message.mentions': '111,222',
        'message.mentions[1]': '222',
        'message.channelMentions': '555,666',
        'message.channelMentions[1]': '666',
      },
    },
  ),
  const SandboxFunctionCase(
    'mentionedchannels',
    r'$mentionedChannels[3;yes]',
    0,
    '30',
    label: 'channel fallback',
    scenario: {
      'variables': {'message.channelMentions': '555,666'},
    },
  ),
];
