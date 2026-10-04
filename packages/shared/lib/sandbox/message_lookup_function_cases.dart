import 'function_suite.dart';

const _messages = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
      ],
    },
  },
  'users': {
    '20': {'username': 'alice', 'discriminator': '0'},
    '21': {'username': 'bob', 'discriminator': '0'},
  },
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
          {
            'emoji': '👍',
            'count': 2,
            'users': ['20', '21'],
          },
          {
            'emoji': '👎',
            'count': 1,
            'users': ['21'],
          },
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
    r'$input[name]',
    0,
    'Hello World',
    label: 'text submitted in the modal input with that ID',
    scenario: {
      'variables': {'modal.name': 'Hello World'},
    },
  ),
  SandboxFunctionCase(
    'input',
    r'$input[name]',
    0,
    '',
    label: 'an input that was not submitted is an error, not empty text',
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $input: Modal input is unavailable: name.',
    },
  ),
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
    r'$authorOfMessage[30;51]',
    0,
    '88',
    label: 'specified message author differs from command author',
    scenario: {'entities': _messages},
    expectedValues: {
      '/entity_requests/1/operation': 'messages.fetch',
      '/entity_requests/1/message_id': '51',
    },
  ),
  SandboxFunctionCase(
    'authorofmessage',
    r'$authorOfMessage[30;$message[message]]',
    0,
    '88',
    label: 'dynamic message ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'authorofmessage',
    r'$authorOfMessage[30;52]',
    0,
    '',
    label: 'missing target is an error and never the command author',
    scenario: {'entities': _messages},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $authorOfMessage: Message 52 is absent from sandbox fixture',
    },
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[30;51]',
    0,
    'Target text',
    label: 'fetches specified channel and message',
    scenario: {'entities': _messages},
    expectedValues: {
      '/entity_requests/0/operation': 'channels.fetch',
      '/entity_requests/0/channel_id': '30',
      '/entity_requests/1/message_id': '51',
    },
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[30;51;authorID]|$getMessage[30;51;username]',
    0,
    '88|Other user',
    label: 'documented properties',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[$message[channel];$message[message]]',
    0,
    'Target text',
    label: 'dynamic channel and message IDs',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '30', 'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'getmessage',
    r'$getMessage[30;52]',
    0,
    '',
    label: 'deleted message is an error rather than empty content',
    scenario: {'entities': _messages},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $getMessage: Message 52 is absent from sandbox fixture',
    },
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
    r'$getAttachments[0]|$getAttachments[1]',
    0,
    'https://cdn.example/a.png|https://cdn.example/b.pdf',
    label: 'zero-based attachment index of the current message',
    scenario: {
      'entities': _messages,
      'variables': {'message.id': '51'},
    },
    expectedValues: {'/entity_requests/1/message_id': '51'},
  ),
  SandboxFunctionCase(
    'getattachments',
    r'$getAttachments[2]',
    0,
    '',
    label: 'index beyond the attachments is an error',
    scenario: {
      'entities': _messages,
      'variables': {'message.id': '51'},
    },
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $getAttachments: Attachment index is out of range.',
    },
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;51;, ;👍]',
    0,
    'alice, bob',
    label: 'lists the users who reacted with one emoji',
    scenario: {'entities': _messages},
    expectedValues: {'/entity_requests/1/message_id': '51'},
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;51;, ;✅]',
    0,
    '',
    label: 'emoji nobody reacted with lists no users',
    scenario: {'entities': _messages},
  ),
  SandboxFunctionCase(
    'getreactions',
    r'$getReactions[30;52;, ;👍]',
    0,
    '',
    label: 'missing message is an error',
    scenario: {'entities': _messages},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $getReactions: Bad state: Message 52 is absent from sandbox fixture',
    },
  ),
  SandboxFunctionCase(
    'userreacted',
    r'$userReacted[30;51;20;👍]|$userReacted[30;51;20;👎]',
    0,
    'true|false',
    label: 'checks if user reacted to message with emoji',
    scenario: {'entities': _messages},
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
      expectedValues: {'/entity_requests/1/message_id': '51'},
    ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[$message[channel];$message[message];2;title]',
    0,
    'Second title',
    label: 'dynamic IDs and second embed',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '30', 'message': '51'},
      'entities': _messages,
    },
  ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[30;51;3;title]',
    0,
    '',
    label: 'out-of-range embed is an error',
    scenario: {'entities': _messages},
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $getEmbedData: Embed index is out of range.',
    },
  ),
  SandboxFunctionCase(
    'getembeddata',
    r'$getEmbedData[30;52;1;title]',
    0,
    '',
    label: 'deleted message is an error',
    scenario: {'entities': _messages},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $getEmbedData: Message 52 is absent from sandbox fixture',
    },
  ),
];
