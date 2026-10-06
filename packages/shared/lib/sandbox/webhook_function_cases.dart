import 'function_suite.dart';

const _url = 'https://discord.com/api/webhooks/90/sandbox-token';

const _webhookEntities = {
  'webhooks': {
    '90': {'channel_id': '30', 'name': 'Existing', 'token': 'sandbox-token'},
  },
};

const _webhookGuild = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {'id': '70', 'name': 'Bot', 'position': 10, 'permissions': '8'},
      ],
      'members': {
        '50': {
          'roles': ['70'],
        },
      },
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
      ],
    },
  },
};

const _hookScenario = {
  'variables': {'bot.id': '50'},
  'entities': {..._webhookGuild, ..._webhookEntities},
};

const _hookSlashScenario = {
  'variables': {'bot.id': '50', 'interaction.isSlash': 'true'},
  'entities': {..._webhookGuild, ..._webhookEntities},
};

final sandboxWebhookFunctionCases = [
  SandboxFunctionCase(
    'webhookcreate',
    r'$webhookCreate[30;News]',
    0,
    'https://discord.com/api/webhooks/9001/sandbox-token-9001',
    label: 'creates a webhook and returns its URL',
    scenario: {
      'variables': {'bot.id': '50'},
      'entities': _webhookGuild,
    },
    expectedValues: {
      '/effects/0/type': 'createWebhook',
      '/effects/0/channel_id': '30',
      '/effects/0/name': 'News',
    },
  ),
  SandboxFunctionCase(
    'webhookcreate',
    r'$setVar[hook;$webhookCreate[30;News]]$webhookSend[$getVar[hook];Ready]',
    0,
    '',
    label: 'created URL can be stored and sent to',
    scenario: {
      'variables': {'bot.id': '50'},
      'entities': _webhookGuild,
    },
    expectedValues: {
      '/effects/0/type': 'createWebhook',
      '/effects/1/type': 'sendWebhook',
      '/effects/1/payload/content': 'Ready',
    },
  ),
  SandboxFunctionCase(
    'webhookdelete',
    r'$webhookDelete[' + _url + r']',
    0,
    '',
    label: 'deletes by webhook URL',
    scenario: _hookScenario,
    expectedValues: {
      '/effects/0/type': 'deleteWebhook',
      '/effects/0/webhook_id': '90',
    },
  ),
  SandboxFunctionCase(
    'webhooksend',
    r'$webhookSend[' + _url + r';$message[content]]',
    0,
    '',
    scenario: {
      ..._hookSlashScenario,
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
    r'$webhookContent[' +
        _url +
        r';$message[content]]$webhookSend[' +
        _url +
        r';]',
    0,
    '',
    scenario: {
      ..._hookSlashScenario,
      'options': {'content': 'Staged content'},
    },
    expectedValues: {'/effects/0/payload/content': 'Staged content'},
  ),
  SandboxFunctionCase(
    'webhooktitle',
    r'$webhookTitle[' + _url + r';$message[title]]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: {
      ..._hookSlashScenario,
      'options': {'title': 'Notice'},
    },
    expectedValues: {'/effects/0/payload/embeds/0/title': 'Notice'},
  ),
  SandboxFunctionCase(
    'webhookdescription',
    r'$webhookDescription[' +
        _url +
        r';$message[body]]$webhookSend[' +
        _url +
        r';]',
    0,
    '',
    scenario: {
      ..._hookSlashScenario,
      'options': {'body': 'Detailed notice'},
    },
    expectedValues: {
      '/effects/0/payload/embeds/0/description': 'Detailed notice',
    },
  ),
  SandboxFunctionCase(
    'webhookcolor',
    r'$webhookColor[' +
        _url +
        r';#5865F2]$webhookDescription[' +
        _url +
        r';Colored]$webhookSend[' +
        _url +
        r';]',
    0,
    '',
    scenario: _hookScenario,
    expectedValues: {'/effects/0/payload/embeds/0/color': 5793266},
  ),
  SandboxFunctionCase(
    'webhookfooter',
    r'$webhookFooter[' + _url + r';Footer text]$webhookSend[' + _url + r';]',
    0,
    '',
    scenario: _hookScenario,
    expectedValues: {'/effects/0/payload/embeds/0/footer/text': 'Footer text'},
  ),
  SandboxFunctionCase(
    'webhookusername',
    r'$webhookUsername[' + _url + r';$message[name]]',
    0,
    '',
    scenario: {
      ..._hookSlashScenario,
      'options': {'name': 'Announcer'},
    },
    expectedValues: {
      '/effects/0/type': 'editWebhook',
      '/effects/0/name': 'Announcer',
    },
  ),
  SandboxFunctionCase(
    'webhookavatarurl',
    r'$webhookAvatarURL[' + _url + r';https://example.com/avatar.png]',
    0,
    '',
    scenario: {
      ..._hookScenario,
      'http': [
        {
          'url': 'https://example.com/avatar.png',
          'headers': {'content-type': 'image/png'},
          'bodyBase64':
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4z8DwHwAFAAH/iZk9HQAAAABJRU5ErkJggg==',
        },
      ],
    },
    expectedValues: {
      '/effects/1/type': 'editWebhook',
      '/effects/1/avatar_url': 'https://example.com/avatar.png',
    },
  ),
  SandboxFunctionCase(
    'webhooktitle',
    r'$webhookTitle[' +
        _url +
        r';First]$webhookSend[' +
        _url +
        r';]$webhookSend[' +
        _url +
        r';Second]',
    0,
    '',
    label: 'staged fields reset after a send',
    scenario: _hookScenario,
    expectedValues: {
      '/effects/0/payload/embeds/0/title': 'First',
      '/effects/1/payload/content': 'Second',
    },
  ),
];
