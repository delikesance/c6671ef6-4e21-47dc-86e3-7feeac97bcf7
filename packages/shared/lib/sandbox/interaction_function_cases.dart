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
    r'$message[$message[1]]',
    0,
    'zero',
    label: 'runtime position read from another argument',
    scenario: {
      'variables': {'message.content': '2 zero two'},
    },
  ),
  const SandboxFunctionCase(
    'message',
    r'$message[$message[1];$message[2]]',
    0,
    '3 two',
    label: 'runtime range read from other arguments',
    scenario: {
      'variables': {'message.content': '2 3 two three'},
    },
  ),
  const SandboxFunctionCase(
    'mentionedchannels',
    r'$mentionedChannels[$message[1];$message[2]]',
    0,
    '666',
    label: 'runtime index and fallback',
    scenario: {
      'variables': {
        'message.content': '2 no',
        'message.channelMentions': '555,666',
        'message.channelMentions[1]': '666',
      },
    },
  ),
  const SandboxFunctionCase(
    'mentioned',
    r'$mentioned[$message[1];$message[2]]',
    0,
    '222',
    label: 'runtime index and fallback',
    scenario: {
      'variables': {
        'message.content': '2 no',
        'message.mentions': '111,222',
        'message.mentions[1]': '222',
      },
    },
  ),
  const SandboxFunctionCase(
    'ismentioned',
    r'$isMentioned[$message[1]]',
    0,
    'true',
    label: 'dynamically selected user is mentioned',
    scenario: {
      'variables': {'message.content': '222', 'message.mentions': '111,222'},
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
        '\$var[index;$index]\$${entry.$1}[\$var[index]]',
        0,
        index == 1
            ? '111'
            : index == 2
            ? '222'
            : '',
        label: 'runtime index $index',
        scenario: {
          'variables': {
            'interaction.type': '3',
            '${entry.$3}.${entry.$4}': '111',
            '${entry.$3}.${entry.$4}[1]': '111',
            '${entry.$3}.${entry.$4}[2]': '222',
            '__collection.${entry.$3}.${entry.$4}': '["111","222"]',
          },
        },
      ),
    SandboxFunctionCase(
      entry.$2,
      '\$var[separator;|]\$${entry.$2}[\$var[separator]]',
      0,
      '111|222',
      label: 'runtime separator',
      scenario: {
        'variables': {
          'interaction.type': '3',
          '${entry.$3}.${entry.$5}': '111,222',
          '__collection.${entry.$3}.${entry.$4}': '["111","222"]',
          '__collection.${entry.$3}.${entry.$5}': '["111","222"]',
        },
      },
    ),
  ],
  for (final entry in const [
    (
      'getstringselectvalues',
      'interaction.stringSelect.value',
      'interaction.stringSelect.values',
    ),
    (
      'getchannelselectchannelids',
      'interaction.channelSelect.channelId',
      'interaction.channelSelect.channelIds',
    ),
  ])
    SandboxFunctionCase(
      entry.$1,
      '\$var[separator;|]\$var[limit;1]\$${entry.$1}[\$var[separator];\$var[limit]]',
      0,
      '111',
      label: 'runtime limit',
      scenario: {
        'variables': {
          'interaction.type': '3',
          entry.$3: '111,222',
          '__collection.${entry.$2}': '["111","222"]',
          '__collection.${entry.$3}': '["111","222"]',
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
    r'$mentionedRoles[1]|$mentionedRoles[2]',
    0,
    '333|444',
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
