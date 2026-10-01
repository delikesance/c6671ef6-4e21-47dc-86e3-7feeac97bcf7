import 'function_suite.dart';

const _messages = {
  'messages': {
    '30': {
      '51': {
        'content': 'Target text',
        'author_id': '88',
        'author_name': 'Other user',
        'attachments': [
          'https://cdn.example/a.png',
          'https://cdn.example/b.pdf',
        ],
        'reactions': [
          {'emoji': '👍', 'count': 4},
          {'emoji': '👎', 'count': 2},
        ],
        'embeds': [
          {
            'title': 'First title',
            'description': 'First description',
            'footer': 'First footer',
            'color': '00ff88',
            'image': 'https://cdn.example/first.png',
            'timestamp': '2025-01-02T03:04:05.000Z',
          },
          {'title': 'Second title'},
        ],
      },
    },
  },
};

final sandboxMessageLookupFunctionCases = [
  SandboxFunctionCase(
    'input',
    r'$input',
    0,
    'Hello World',
    label: 'text after the prefix and command name',
    scenario: {
      'variables': {'message.content': 'Hello World'},
    },
  ),
  SandboxFunctionCase('input', r'$input', 0, '', label: 'empty command input'),
  SandboxFunctionCase(
    'isslash',
    r'$isSlash',
    0,
    'false',
    label: 'prefix command is not a slash interaction',
  ),
  SandboxFunctionCase(
    'isslash',
    r'$isSlash',
    0,
    'true',
    label: 'slash interaction context',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'authorofmessage',
    r'$authorOfMessage[51]',
    0,
    '88',
    label: 'specified message author differs from command author',
    scenario: {'entities': _messages},
    expectedValues: {
      '/entity_requests/0/operation': 'messages.fetch',
      '/entity_requests/0/message_id': '51',
    },
  ),
  SandboxFunctionCase(
    'authorofmessage',
    r'$authorOfMessage[((opts.message))]',
    0,
    '88',
    label: 'dynamic message ID',
    scenario: {
      'options': {'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'authorofmessage',
    r'$authorOfMessage[52]',
    0,
    '',
    label: 'missing target does not use the command author',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[30;51]',
    0,
    'Target text',
    label: 'fetches specified channel and message',
    scenario: {'entities': _messages},
    expectedValues: {
      '/entity_requests/0/channel_id': '30',
      '/entity_requests/0/message_id': '51',
    },
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[((opts.channel));((opts.message))]',
    0,
    'Target text',
    label: 'dynamic channel and message IDs',
    scenario: {
      'options': {'channel': '30', 'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[30;52]',
    0,
    '',
    label: 'deleted message returns empty content',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getmessagevar',
    r'$getMessageVar[state;51]|$getMessageVar[state]',
    0,
    'target|current',
    label: 'explicit message ID preserves current message context',
    scenario: {
      'variables': {'message.id': '50'},
      'scoped': {
        'message': {
          '50': {'state': 'current'},
          '51': {'state': 'target'},
        },
      },
    },
  ),
  SandboxFunctionCase(
    'getattachments',
    r'$getAttachments[51]',
    0,
    'https://cdn.example/a.png, https://cdn.example/b.pdf',
    label: 'returns all URLs from the specified message',
    scenario: {'entities': _messages},
    expectedValues: {'/entity_requests/0/message_id': '51'},
  ),
  SandboxFunctionCase(
    'getattachments',
    r'$getAttachments[52]',
    0,
    '',
    label: 'missing message returns empty',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;51;👍]',
    0,
    '4',
    label: 'counts one emoji on the specified message',
    scenario: {'entities': _messages},
    expectedValues: {'/entity_requests/0/message_id': '51'},
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;51;✅]',
    0,
    '0',
    label: 'emoji with no reactions returns zero',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;52;👍]',
    0,
    '0',
    label: 'missing message returns zero',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'userreacted',
    r'$userReacted[30;51;20;👍]',
    0,
    'true',
    label: 'checks if user reacted to message with emoji',
    scenario: {
      'variables': {'userReacted[30;51;20;👍]': 'true'},
    },
  ),
  for (final entry in [
    ('title', 'First title'),
    ('description', 'First description'),
    ('footer', 'First footer'),
    ('color', '00ff88'),
    ('image', 'https://cdn.example/first.png'),
    ('timestamp', '2025-01-02T03:04:05.000Z'),
  ])
    SandboxFunctionCase(
      'getembeddata',
      '\$getEmbedData[30;51;1;${entry.$1}]',
      0,
      entry.$2,
      label: 'reads ${entry.$1} from the first embed (index one)',
      scenario: {'entities': _messages},
      expectedValues: {'/entity_requests/0/message_id': '51'},
    ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[((opts.channel));((opts.message));2;title]',
    0,
    'Second title',
    label: 'dynamic IDs and second embed',
    scenario: {
      'options': {'channel': '30', 'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[30;51;3;title]',
    0,
    '',
    label: 'out-of-range embed returns empty',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[30;52;1;title]',
    0,
    '',
    label: 'deleted message returns empty',
    scenario: {'entities': _messages},
  ),
];
