import 'function_suite.dart';

/// Nicknames are changed through the production moderation checks against
/// guild member fixtures; the bot needs a numeric ID.
const _nicknameFixture = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {'id': '70', 'name': 'Bot', 'position': 1, 'permissions': '8'},
      ],
      'members': {
        '20': {'roles': <String>[], 'nick': 'Old'},
        '21': {'roles': <String>[]},
        '98': {
          'roles': ['70'],
        },
        '99': {'roles': <String>[]},
      },
    },
  },
  'users': {
    '20': {'username': 'alice', 'discriminator': '0'},
    '21': {'username': 'bob', 'discriminator': '0'},
  },
};

const sandboxMiscFunctionCases = [
  SandboxFunctionCase(
    'changeusername',
    r'$changeUsername[NewNick]',
    0,
    '',
    label: 'without a mention it changes the nickname of the command author',
    scenario: {
      'entities': _nicknameFixture,
      'variables': {'bot.id': '98'},
    },
    expectedValues: {
      '/effects/0/type': 'setNickname',
      '/effects/0/user_id': '20',
      '/effects/0/before': 'Old',
      '/effects/0/after': 'NewNick',
    },
  ),
  SandboxFunctionCase(
    'changeusername',
    r'$changeUsername[Mentioned]',
    0,
    '',
    label: 'changes the nickname of the mentioned user',
    scenario: {
      'entities': _nicknameFixture,
      'variables': {'bot.id': '98', 'message.mentions': '21'},
    },
    expectedValues: {
      '/effects/0/type': 'setNickname',
      '/effects/0/user_id': '21',
      '/effects/0/after': 'Mentioned',
    },
  ),
  SandboxFunctionCase(
    'changeusernamewithid',
    r'$changeUsernameWithID[21;Hello %username%]',
    0,
    '',
    label: '%username% is replaced by the real username',
    scenario: {
      'entities': _nicknameFixture,
      'variables': {'bot.id': '98'},
    },
    expectedValues: {
      '/effects/0/type': 'setNickname',
      '/effects/0/user_id': '21',
      '/effects/0/after': 'Hello bob',
    },
  ),
  SandboxFunctionCase(
    'changeusernamewithid',
    r'$changeUsernameWithID[21;This nickname is far longer than thirty-two characters]',
    0,
    '',
    label: 'nicknames beyond 32 characters are an error',
    scenario: {
      'entities': _nicknameFixture,
      'variables': {'bot.id': '98'},
    },
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $changeUsernameWithID: Nickname must contain 1 to 32 characters.',
      '/effects': [],
    },
  ),
  SandboxFunctionCase(
    'botleave',
    r'$botLeave[10]',
    0,
    '',
    scenario: {
      'entities': {
        'guilds': {
          '10': {'name': 'Current'},
        },
      },
    },
    expectedValues: {
      '/effects/0/type': 'leaveGuild',
      '/effects/0/guild_id': '10',
    },
  ),
  SandboxFunctionCase(
    'bottyping',
    r'$botTyping',
    0,
    '',
    label: 'emits a typing indicator without posting a message',
    expectedValues: {
      '/responses': [],
      '/effects/0/type': 'typing',
      '/effects/0/channel_id': '30',
    },
  ),
  SandboxFunctionCase(
    'debug',
    r'$debug[on]$setVar[after;yes]done',
    0,
    'done',
    label: 'debug leaves subsequent execution intact',
    expectedValues: {'/storage_after/global/after': 'yes'},
  ),
  SandboxFunctionCase(
    'alternativeparsing',
    r'$alternativeparsing OK',
    0,
    ' OK',
    label: 'compatibility parser flag no-op',
  ),
  SandboxFunctionCase(
    'botlistdescription',
    r'$botListDescription[A helpful bot] OK',
    0,
    ' OK',
    label: 'bot list description flag no-op',
  ),
  SandboxFunctionCase(
    'botlisthide',
    r'$botListHide OK',
    0,
    ' OK',
    label: 'hide from bot list flag no-op',
  ),
  SandboxFunctionCase(
    'botnode',
    r"The bot's node ID: $botNode",
    0,
    "The bot's node ID: 21",
    label: 'returns the node the bot runs on',
    scenario: {
      'variables': {'bot.node': '21'},
    },
  ),
  SandboxFunctionCase(
    'disableinnerspaceremoval',
    r'$disableInnerSpaceRemoval OK',
    0,
    ' OK',
    label: 'disable inner space removal flag no-op',
  ),
  SandboxFunctionCase(
    'disablespecialescaping',
    r'$disableSpecialEscaping OK',
    0,
    ' OK',
    label: 'disable special escaping flag no-op',
  ),
  SandboxFunctionCase(
    'ignorelinks',
    r'$ignoreLinks OK',
    0,
    ' OK',
    label: 'ignore links flag no-op',
  ),
  SandboxFunctionCase(
    'optoff',
    r'$optOff OK',
    0,
    ' OK',
    label: 'opt-off flag no-op',
  ),
  SandboxFunctionCase(
    'suppresserrorlogging',
    r'$suppressErrorLogging OK',
    0,
    ' OK',
    label: 'suppress error logging flag no-op',
  ),
  SandboxFunctionCase(
    'logquota',
    r'$logQuota',
    0,
    '100',
    scenario: {
      'variables': {'log.quota': '100'},
    },
    label: 'returns remaining log quota',
  ),
];
