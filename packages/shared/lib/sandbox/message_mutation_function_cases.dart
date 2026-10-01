import 'function_suite.dart';

const _messageMutation = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '30', 'name': 'news', 'type': 'announcement'},
      ],
      'messages': {
        '30': [
          {
            'id': '101',
            'author_id': '20',
            'reactions': {
              '👍': ['20', 'sandbox'],
              '✨': ['21'],
            },
          },
          {'id': '102', 'author_id': '21'},
          {
            'id': '103',
            'author_id': 'sandbox',
            'content': 'Old',
            'pinned': true,
            'components': [
              {
                'type': 'actionRow',
                'components': [
                  {'type': 'button', 'customId': 'approve', 'label': 'Approve'},
                  {'type': 'button', 'customId': 'deny', 'label': 'Deny'},
                ],
              },
              {
                'type': 'actionRow',
                'components': [
                  {'type': 'selectMenu', 'customId': 'choices'},
                ],
              },
            ],
          },
        ],
      },
    },
  },
};

const sandboxMessageMutationFunctionCases = [
  SandboxFunctionCase(
    'removeallcomponents',
    r'$removeAllComponents',
    0,
    '',
    scenario: {
      'entities': _messageMutation,
      'variables': {'interaction.messageId': '103'},
    },
    expectedValues: {
      '/effects/0/type': 'editMessage',
      '/effects/0/message_id': '103',
      '/effects/0/after/components': [],
    },
  ),
  SandboxFunctionCase(
    'removebuttons',
    r'$removeButtons[103]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/after/components/0/components/0/customId': 'choices',
      '/effects/0/after/components/0/components/0/type': 'selectMenu',
    },
  ),
  SandboxFunctionCase(
    'removecomponent',
    r'$removeComponent[approve;103]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/after/components/0/components/0/customId': 'deny',
      '/effects/0/after/components/1/components/0/customId': 'choices',
    },
  ),
  SandboxFunctionCase(
    'addreactions',
    r'$addReactions[👍;✨]Hello',
    0,
    'Hello',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'addReaction',
      '/effects/0/message_id': '100000',
      '/effects/0/after/👍': ['sandbox'],
      '/effects/0/after/✨': ['sandbox'],
    },
  ),
  SandboxFunctionCase(
    'addcmdreactions',
    r'$addCmdReactions[✅]',
    0,
    '',
    scenario: {
      'entities': _messageMutation,
      'variables': {'message.id': '101'},
    },
    expectedValues: {
      '/effects/0/message_id': '101',
      '/effects/0/after/✅': ['sandbox'],
    },
  ),
  SandboxFunctionCase(
    'addmessagereactions',
    r'$addMessageReactions[30;102;👍;✨]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/message_id': '102',
      '/effects/0/after/👍': ['sandbox'],
      '/effects/0/after/✨': ['sandbox'],
    },
  ),
  SandboxFunctionCase(
    'clearreactions',
    r'$clearReactions[30;101;👍]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/after': {
        '✨': ['21'],
      },
    },
  ),
  SandboxFunctionCase(
    'clearreactions',
    r'$clearReactions[30;101;!all]',
    0,
    '',
    label: 'clear every emoji when explicitly requested',
    scenario: {'entities': _messageMutation},
    expectedValues: {'/effects/0/after': {}},
  ),
  SandboxFunctionCase(
    'removereaction',
    r'$removeReaction[30;101;👍]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/after/👍': ['20'],
    },
  ),
  SandboxFunctionCase(
    'deletemessage',
    r'$deleteMessage[30;102]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'deleteMessages',
      '/effects/0/channel_id': '30',
      '/effects/0/deleted_ids': ['102'],
      '/effects/0/remaining_ids': ['101', '103'],
      '/effects/0/simulated': true,
    },
  ),
  SandboxFunctionCase(
    'deletecommand',
    r'$deletecommand',
    0,
    '',
    scenario: {
      'entities': _messageMutation,
      'variables': {'message.id': '101'},
    },
    expectedValues: {
      '/effects/0/type': 'deleteTrigger',
      '/effects/0/deleted_ids': ['101'],
      '/effects/0/remaining_ids': ['102', '103'],
    },
  ),
  SandboxFunctionCase(
    'editmessage',
    r'$editMessage[30;103;Updated]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'editMessage',
      '/effects/0/message_id': '103',
      '/effects/0/before/content': 'Old',
      '/effects/0/after/content': 'Updated',
    },
  ),
  SandboxFunctionCase(
    'editmessage',
    r'$editMessage[30;103;Updated;News;Details;#336699;Done]',
    0,
    '',
    label: 'optional embed fields reach the edited message',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/after/content': 'Updated',
      '/effects/0/after/embeds/0/title': 'News',
      '/effects/0/after/embeds/0/description': 'Details',
      '/effects/0/after/embeds/0/color': '#336699',
      '/effects/0/after/embeds/0/footer/text': 'Done',
    },
  ),
  SandboxFunctionCase(
    'editin',
    r'$editIn[5s;Updated]Original',
    0,
    'Original',
    label: 'schedules an edit of the bot response',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'scheduleEditMessage',
      '/effects/0/message_id': '100000',
      '/effects/0/delay_ms': 5000,
      '/effects/0/before/content': 'Original',
      '/effects/0/scheduled/content': 'Updated',
    },
  ),
  SandboxFunctionCase(
    'editembedin',
    r'$editEmbedIn[5s;News;Details;Done;#336699]Original',
    0,
    'Original',
    label: 'schedules embed fields in documented order',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'scheduleEditMessage',
      '/effects/0/message_id': '100000',
      '/effects/0/delay_ms': 5000,
      '/effects/0/scheduled/embeds/0/title': 'News',
      '/effects/0/scheduled/embeds/0/description': 'Details',
      '/effects/0/scheduled/embeds/0/footer/text': 'Done',
      '/effects/0/scheduled/embeds/0/color': '#336699',
    },
  ),
  SandboxFunctionCase(
    'pinmessage',
    r'$pinMessage[30;102]',
    0,
    '',
    label: 'pins an explicitly addressed message',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'pinMessage',
      '/effects/0/message_id': '102',
      '/effects/0/after/pinned': true,
    },
  ),
  SandboxFunctionCase(
    'pinmessage',
    r'$pinMessage Hello',
    0,
    ' Hello',
    label: 'simple form pins the bot response after it is sent',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'pinMessage',
      '/effects/0/message_id': '100000',
      '/effects/0/after/content': ' Hello',
      '/effects/0/after/pinned': true,
      '/variables/last.response.id': '100000',
    },
  ),
  SandboxFunctionCase(
    'unpinmessage',
    r'$unpinMessage[30;103]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'unpinMessage',
      '/effects/0/message_id': '103',
      '/effects/0/before/pinned': true,
      '/effects/0/after/pinned': false,
    },
  ),
  SandboxFunctionCase(
    'publishmessage',
    r'$publishMessage[30;103]',
    0,
    '',
    scenario: {'entities': _messageMutation},
    expectedValues: {
      '/effects/0/type': 'publishMessage',
      '/effects/0/message_id': '103',
      '/effects/0/after/published': true,
    },
  ),
];
