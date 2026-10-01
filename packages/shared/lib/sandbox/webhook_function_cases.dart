import 'function_suite.dart';

const _url = 'https://discord.com/api/webhooks/90/sandbox-token';

final sandboxWebhookFunctionCases = [
  SandboxFunctionCase(
    'webhookcreate',
    r'$webhookCreate[30;News]',
    0,
    'https://discord.com/api/webhooks/9001/sandbox-token-9001',
    label: 'creates a webhook and returns its URL',
    scenario: {
      'entities': {
        'guilds': {
          '10': {
            'channels': [
              {'id': '30', 'name': 'general', 'type': 'text'},
            ],
          },
        },
      },
    },
    expectedValues: {
      '/effects/0/type': 'createWebhook',
      '/effects/0/channel_id': '30',
      '/effects/0/name': 'News',
    },
  ),
  SandboxFunctionCase(
    'webhookdelete',
    r'$webhookDelete[90;sandbox-token]',
    0,
    '',
    label: 'deletes by explicit ID and token',
    expectedValues: {
      '/effects/0/type': 'deleteWebhook',
      '/effects/0/webhook_id': '90',
    },
  ),
  SandboxFunctionCase(
    'webhookcreate',
    r'$setVar[hook;$webhookCreate[30;News]]$webhookSend[$getVar[hook];Ready]',
    0,
    '',
    label: 'created URL can be stored and sent to',
    scenario: {
      'entities': {
        'guilds': {
          '10': {
            'channels': [
              {'id': '30', 'name': 'general', 'type': 'text'},
            ],
          },
        },
      },
    },
    expectedValues: {
      '/effects/0/type': 'createWebhook',
      '/effects/1/type': 'sendWebhook',
      '/effects/1/payload/content': 'Ready',
    },
  ),
  SandboxFunctionCase(
    'webhooksend',
    r'$webhookSend[' + _url + r';((opts.content))]',
    0,
    '',
    scenario: {
      'options': {'content': 'Hello from sandbox'},
    },
    expectedValues: {
      '/effects/0/type': 'sendWebhook',
      '/effects/0/webhook_id': '90',
      '/effects/0/payload/content': 'Hello from sandbox',
      '/effects/0/simulated': true,
    },
  ),
  SandboxFunctionCase(
    'webhookcontent',
    r'$webhookContent[((opts.content))]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: {
      'options': {'content': 'Staged content'},
    },
    expectedValues: {'/effects/0/payload/content': 'Staged content'},
  ),
  SandboxFunctionCase(
    'webhooktitle',
    r'$webhookTitle[((opts.title))]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: {
      'options': {'title': 'Notice'},
    },
    expectedValues: {'/effects/0/payload/embeds/0/title': 'Notice'},
  ),
  SandboxFunctionCase(
    'webhookdescription',
    r'$webhookDescription[((opts.body))]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: {
      'options': {'body': 'Detailed notice'},
    },
    expectedValues: {
      '/effects/0/payload/embeds/0/description': 'Detailed notice',
    },
  ),
  SandboxFunctionCase(
    'webhookcolor',
    r'$webhookColor[#5865F2]$webhookSend[' + _url + r';]',
    0,
    '',
    expectedValues: {'/effects/0/payload/embeds/0/color': 5793266},
  ),
  SandboxFunctionCase(
    'webhookfooter',
    r'$webhookFooter[Footer text]$webhookSend[' + _url + r';]',
    0,
    '',
    expectedValues: {'/effects/0/payload/embeds/0/footer/text': 'Footer text'},
  ),
  SandboxFunctionCase(
    'webhookusername',
    r'$webhookUsername[((opts.name))]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: {
      'options': {'name': 'Announcer'},
    },
    expectedValues: {'/effects/0/username': 'Announcer'},
  ),
  SandboxFunctionCase(
    'webhookavatarurl',
    r'$webhookAvatarURL[https://example.com/avatar.png]$webhookSend[' +
        _url +
        r';]',
    0,
    '',
    expectedValues: {'/effects/0/avatar_url': 'https://example.com/avatar.png'},
  ),
  SandboxFunctionCase(
    'webhooktitle',
    r'$webhookTitle[First]$webhookSend[' +
        _url +
        r';]$webhookSend[' +
        _url +
        r';Second]',
    0,
    '',
    label: 'staged fields reset after a send',
    expectedValues: {
      '/effects/0/payload/embeds/0/title': 'First',
      '/effects/1/payload/content': 'Second',
    },
  ),
];
