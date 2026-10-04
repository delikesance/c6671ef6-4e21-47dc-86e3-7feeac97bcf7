import 'function_suite.dart';

const _emojiGuilds = {
  'guilds': {
    '10': {
      'roles': [
        {'id': '80', 'name': 'Bot', 'permissions': '8'},
      ],
      'members': {
        '98': {
          'roles': ['80'],
        },
      },
      'emojis': [
        {'id': '70', 'name': 'Wave', 'animated': false},
        {'id': '71', 'name': 'Dance', 'animated': true},
      ],
    },
    '11': {
      'emojis': [
        {'id': '72', 'name': 'Other', 'animated': false},
      ],
    },
  },
};

const sandboxEmojiFunctionCases = [
  SandboxFunctionCase(
    'addemoji',
    r'$addEmoji[TestSmile;https://example.invalid/smile.png;yes]',
    0,
    '<:TestSmile:300000>',
    label:
        'creates an emoji from an explicit image fixture and returns its tag',
    scenario: {
      'variables': {'bot.id': '98'},
      'entities': {
        'guilds': {
          '10': {
            'roles': [
              {'id': '80', 'name': 'Bot', 'permissions': '8'},
            ],
            'members': {
              '98': {
                'roles': ['80'],
              },
            },
            'emojis': <Map<String, dynamic>>[],
          },
        },
      },
      // The production image loader fetches the URL; the fixture serves a
      // 1x1 PNG.
      'http': [
        {
          'url': 'https://example.invalid/smile.png',
          'headers': {'content-type': 'image/png'},
          'bodyBase64':
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
        },
      ],
    },
    expectedValues: {
      '/effects/0/type': 'httpRequest',
      '/effects/1/type': 'createEmoji',
      '/effects/1/after/name': 'TestSmile',
      '/effects/1/after/animated': false,
      '/effects/1/image_url': 'https://example.invalid/smile.png',
    },
  ),
  SandboxFunctionCase(
    'removeemoji',
    r'$removeEmoji[70]',
    0,
    '',
    label: 'removes an emoji by ID',
    scenario: {
      'variables': {'bot.id': '98'},
      'entities': _emojiGuilds,
    },
    expectedValues: {
      '/effects/0/type': 'deleteEmoji',
      '/effects/0/emoji_id': '70',
      '/effects/0/before/name': 'Wave',
    },
  ),
  SandboxFunctionCase(
    'customemoji',
    r'$customEmoji[Wave]',
    0,
    '<:Wave:70>',
    label: 'finds a static custom emoji by name',
    scenario: {'entities': _emojiGuilds},
    expectedValues: {'/entity_requests/0/operation': 'guild.emojis'},
  ),
  SandboxFunctionCase(
    'customemoji',
    r'$customEmoji[$message[name]]',
    0,
    '<a:Dance:71>',
    label: 'dynamic name finds an animated emoji',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'name': 'Dance'},
      'entities': _emojiGuilds,
    },
  ),
  SandboxFunctionCase(
    'customemoji',
    r'$customEmoji[Absent]',
    0,
    '',
    label: 'missing emoji resolves empty',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojiexists',
    r'$emojiExists[70]',
    0,
    'true',
    label: 'existing ID',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojiexists',
    r'$emojiExists[999]',
    0,
    'false',
    label: 'missing ID',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojiexists',
    r'$emojiExists[Wave]',
    0,
    'false',
    label: 'BDFD requires an ID, not the name',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojiname',
    r'$emojiName[$message[id]]',
    0,
    'Dance',
    label: 'dynamic emoji ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'id': '71'},
      'entities': _emojiGuilds,
    },
  ),
  SandboxFunctionCase(
    'emojiname',
    r'$emojiName[72]',
    0,
    'Other',
    label: 'ID from another guild accessible to the bot',
    scenario: {'entities': _emojiGuilds},
    expectedValues: {
      '/entity_requests/0/operation': 'guild.emojis',
      '/entity_requests/1/operation': 'users.guilds',
      '/entity_requests/2/guild_id': '11',
    },
  ),
  SandboxFunctionCase(
    'emojiname',
    r'$emojiName[999]',
    0,
    '',
    label: 'unknown ID is an error',
    scenario: {'entities': _emojiGuilds},
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $emojiName: Emoji not found.',
    },
  ),
  SandboxFunctionCase(
    'isemojianimated',
    r'$isEmojiAnimated[70]',
    0,
    'false',
    label: 'static emoji',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'isemojianimated',
    r'$isEmojiAnimated[71]',
    0,
    'true',
    label: 'animated emoji',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojicount',
    r'$emojiCount',
    0,
    '2',
    label: 'current server count includes static and animated',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojicount',
    r'$emojiCount[11]',
    0,
    '1',
    label: 'explicit guild count',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'emojicount',
    r'$emojiCount[$message[guild]]',
    0,
    '1',
    label: 'dynamic guild ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'guild': '11'},
      'entities': _emojiGuilds,
    },
  ),
  SandboxFunctionCase(
    'emotecount',
    r'$emoteCount',
    0,
    '2',
    label: 'current server alias',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'serveremojis',
    r'$serverEmojis[10;, ]',
    0,
    '<:Wave:70>, <a:Dance:71>',
    label: 'uses supplied separator and guild',
    scenario: {'entities': _emojiGuilds},
  ),
  SandboxFunctionCase(
    'serveremojis',
    r'$serverEmojis[$message[guild];|]',
    0,
    '<:Other:72>',
    label: 'dynamic guild ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'guild': '11'},
      'entities': _emojiGuilds,
    },
  ),
];
