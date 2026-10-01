import 'function_suite.dart';

const sandboxMiscFunctionCases = [
  SandboxFunctionCase(
    'changeusername',
    r'$changeUsername[NewBot]$botName',
    0,
    'NewBot',
    scenario: {
      'variables': {'bot.username': 'OldBot'},
    },
    expectedValues: {
      '/effects/0/type': 'updateSelfUser',
      '/effects/0/before': 'OldBot',
      '/effects/0/after': 'NewBot',
    },
  ),
  SandboxFunctionCase(
    'changeusernamewithid',
    r'$changeUsernameWithID[999;Renamed]$botName',
    0,
    'Renamed',
    scenario: {
      'variables': {'bot.id': '999', 'bot.username': 'OldBot'},
    },
    expectedValues: {'/effects/0/user_id': '999'},
    label: 'the supplied ID may select the bot itself',
  ),
  SandboxFunctionCase(
    'changeusernamewithid',
    r'$changeUsernameWithID[21;WrongName]',
    0,
    '',
    scenario: {
      'variables': {'bot.id': '999'},
    },
    expectedValues: {
      '/success': false,
      '/error':
          'Bad state: A bot token cannot change another user’s global username',
      '/effects': [],
    },
    label: 'another user’s global username is outside bot-token capability',
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
    r'$debug$setVar[after;yes]done',
    0,
    'done',
    label: 'debug profiling leaves subsequent execution intact',
    expectedValues: {
      '/trace/0/actionType': 'debugProfile',
      '/storage_after/global/after': 'yes',
    },
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
    r'$botNode OK',
    0,
    ' OK',
    label: 'bot node placeholder returns empty compatibility text',
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
