import 'function_suite.dart';

/// Native message mutations run against read-only fixtures that the sandbox
/// then mutates in memory: the bot member needs a numeric ID, a role with the
/// required permissions and a channel, exactly like a production bot.
const messageMutationEntityFixture = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {'id': '70', 'name': 'Bot', 'position': 1, 'permissions': '8'},
      ],
      'members': {
        '98': {
          'roles': ['70'],
        },
        '99': {'roles': <String>[]},
      },
      'channels': [
        {'id': '30', 'name': 'news', 'type': 'announcement'},
      ],
    },
  },
  'users': {
    '20': {'username': 'alice', 'discriminator': '0'},
    '21': {'username': 'bob', 'discriminator': '0'},
  },
  'messages': {
    '30': {
      '101': {
        'author_id': '20',
        'content': 'Trigger',
        'reactions': [
          {
            'emoji': '👍',
            'count': 2,
            'users': ['20', '98'],
          },
          {
            'emoji': '✨',
            'count': 1,
            'users': ['21'],
          },
        ],
      },
      '102': {'author_id': '21', 'content': 'Other'},
      '103': {
        'author_id': '98',
        'content': 'Old',
        'pinned': true,
        'components': [
          {
            'type': 1,
            'components': [
              {
                'type': 2,
                'style': 1,
                'custom_id': 'approve',
                'label': 'Approve',
              },
              {'type': 2, 'style': 4, 'custom_id': 'deny', 'label': 'Deny'},
            ],
          },
          {
            'type': 1,
            'components': [
              {
                'type': 3,
                'custom_id': 'choices',
                'options': [
                  {'label': 'One', 'value': '1'},
                ],
              },
            ],
          },
        ],
      },
    },
  },
};

const _mutationScenario = {
  'entities': messageMutationEntityFixture,
  'variables': {'bot.id': '98'},
};

const sandboxMessageMutationFunctionCases = [
  SandboxFunctionCase(
    'removeallcomponents',
    r'$removeAllComponents[103]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editComponents',
      '/effects/0/message_id': '103',
      '/effects/0/components': [],
    },
  ),
  SandboxFunctionCase(
    'removebuttons',
    r'$removeButtons[103]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editComponents',
      '/effects/0/components/0/components/0/custom_id': 'choices',
      '/effects/0/components/0/components/0/type': 3,
    },
  ),
  SandboxFunctionCase(
    'removecomponent',
    r'$removeComponent[approve;103]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editComponents',
      '/effects/0/components/0/components/0/custom_id': 'deny',
      '/effects/0/components/1/components/0/custom_id': 'choices',
    },
  ),
  SandboxFunctionCase(
    'addreactions',
    r'$addReactions[👍;✨]Hello',
    0,
    'Hello',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'addReaction',
      '/effects/0/message_id': '100000',
      '/effects/0/after/0/emoji': '👍',
      '/effects/0/after/0/users': ['98'],
      '/effects/1/message_id': '100000',
      '/effects/1/after/1/emoji': '✨',
      '/effects/1/after/1/users': ['98'],
    },
  ),
  SandboxFunctionCase(
    'addcmdreactions',
    r'$addCmdReactions[✅]',
    0,
    '',
    scenario: {
      'entities': messageMutationEntityFixture,
      'variables': {'bot.id': '98', 'message.id': '101'},
    },
    expectedValues: {
      '/effects/0/type': 'addReaction',
      '/effects/0/message_id': '101',
      '/effects/0/after/2/emoji': '✅',
      '/effects/0/after/2/users': ['98'],
    },
  ),
  SandboxFunctionCase(
    'addmessagereactions',
    r'$addMessageReactions[30;102;👍;✨]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/message_id': '102',
      '/effects/0/after/0/emoji': '👍',
      '/effects/1/message_id': '102',
      '/effects/1/after/1/emoji': '✨',
      '/effects/1/after/1/users': ['98'],
    },
  ),
  SandboxFunctionCase(
    'clearreactions',
    r'$clearReactions[30;101;👍]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'clearReactions',
      '/effects/0/after': [
        {
          'emoji': '✨',
          'count': 1,
          'users': ['21'],
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'clearreactions',
    r'$clearReactions[30;101;!all]',
    0,
    '',
    label: 'clear every emoji when explicitly requested',
    scenario: _mutationScenario,
    expectedValues: {'/effects/0/emoji': '!all', '/effects/0/after': []},
  ),
  SandboxFunctionCase(
    'removereaction',
    r'$removeReaction[30;101;20;👍]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'clearReactions',
      '/effects/0/after': [
        {
          'emoji': '✨',
          'count': 1,
          'users': ['21'],
        },
      ],
    },
  ),
  SandboxFunctionCase(
    'deletemessage',
    r'$deleteMessage[30;102]$getMessage[30;101]',
    0,
    'Trigger',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'deleteMessage',
      '/effects/0/channel_id': '30',
      '/effects/0/message_id': '102',
      '/effects/0/simulated': true,
    },
  ),
  SandboxFunctionCase(
    'deletemessage',
    r'$deleteMessage[30;102]$getMessage[30;102]',
    0,
    '',
    label: 'the deleted message can no longer be fetched',
    scenario: _mutationScenario,
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:23 $getMessage: Message 102 is absent from sandbox fixture',
    },
  ),
  SandboxFunctionCase(
    'deletecommand',
    r'$deletecommand',
    0,
    '',
    scenario: {
      'entities': messageMutationEntityFixture,
      'variables': {'bot.id': '98', 'message.id': '101'},
    },
    expectedValues: {
      '/effects/0/type': 'deleteMessage',
      '/effects/0/channel_id': '30',
      '/effects/0/message_id': '101',
    },
  ),
  SandboxFunctionCase(
    'editmessage',
    r'$editMessage[30;103;Updated]$getMessage[30;103]',
    0,
    'Updated',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editMessage',
      '/effects/0/message_id': '103',
    },
  ),
  SandboxFunctionCase(
    'editmessage',
    r'$editMessage[30;103;Updated;News;Details;#336699;Done]$getEmbedData[30;103;1;title]/$getEmbedData[30;103;1;description]/$getEmbedData[30;103;1;color]/$getEmbedData[30;103;1;footer]',
    0,
    'News/Details/336699/Done',
    label: 'optional embed fields reach the edited message',
    scenario: _mutationScenario,
    expectedValues: {'/effects/0/type': 'editMessage'},
  ),
  SandboxFunctionCase(
    'editin',
    r'$editIn[5s;Updated]Original',
    0,
    'Original',
    label: 'schedules an edit of the bot response',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editMessage',
      '/effects/0/message_id': '100000',
    },
  ),
  SandboxFunctionCase(
    'editembedin',
    r'$editEmbedIn[5s;News;Details;Done;#336699]Original',
    0,
    'Original',
    label: 'schedules embed fields in documented order',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'editMessage',
      '/effects/0/message_id': '100000',
    },
  ),
  SandboxFunctionCase(
    'pinmessage',
    r'$pinMessage Hello',
    0,
    ' Hello',
    label: 'pins the bot response after it is sent',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'pinMessage',
      '/effects/0/channel_id': '30',
      '/effects/0/message_id': '100000',
      '/results/last.response.id': '100000',
    },
  ),
  SandboxFunctionCase(
    'unpinmessage',
    r'$unpinMessage[30;103]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'unpinMessage',
      '/effects/0/message_id': '103',
    },
  ),
  SandboxFunctionCase(
    'publishmessage',
    r'$publishMessage[30;103]',
    0,
    '',
    scenario: _mutationScenario,
    expectedValues: {
      '/effects/0/type': 'publishMessage',
      '/effects/0/message_id': '103',
    },
  ),
];
