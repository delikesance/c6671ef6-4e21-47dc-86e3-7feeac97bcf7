import 'function_suite.dart';

const _ticketGuild = {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        {'id': '70', 'name': 'Bot', 'position': 10, 'permissions': '8'},
      ],
      'members': {
        '20': {'roles': <String>[]},
        '50': {
          'roles': ['70'],
        },
      },
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
        {'id': '40', 'name': 'Support', 'type': 'category'},
        {'id': '41', 'name': 'ticket-20', 'type': 'text', 'parent_id': '40'},
      ],
    },
  },
};

const sandboxTicketFunctionCases = [
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[40;No subject;Welcome {subject};Created {channel};Failed]',
    0,
    'Welcome help\nCreated <#60>',
    scenario: {
      'entities': _ticketGuild,
      'variables': {'bot.id': '50', 'message.content': 'help'},
    },
    expectedValues: {
      '/effects/0/type': 'createChannel',
      '/effects/0/channel_id': '60',
      '/effects/0/after/name': 'ticket-test-user',
      '/effects/0/after/parent_id': '40',
      '/effects/0/after/permission_overwrites/0/id': '10',
      '/effects/0/after/permission_overwrites/0/deny': '1024',
      '/effects/0/after/permission_overwrites/1/id': '20',
      '/effects/0/after/permission_overwrites/1/allow': '68608',
      '/responses/0/payload/channelId': '60',
    },
    label: 'creates a private ticket and sends the in-ticket and user messages',
  ),
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[support;No subject given;Subject: {subject};Created!;Failed]',
    0,
    'Subject: No subject given\nCreated!',
    scenario: {
      'entities': _ticketGuild,
      'variables': {'bot.id': '50'},
    },
    expectedValues: {'/effects/0/after/parent_id': '40'},
    label:
        'resolves the category by name and falls back to the no-question text',
  ),
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[Missing;;Hi;Created!;Could not create the ticket.]',
    0,
    'Could not create the ticket.',
    scenario: {
      'entities': _ticketGuild,
      'variables': {'bot.id': '50'},
    },
    expectedValues: {'/effects': []},
    label: 'returns the error message when the category does not exist',
  ),
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[40;;Hi;;Failed;7]',
    0,
    'Hi',
    scenario: {
      'entities': _ticketGuild,
      'variables': {'bot.id': '50'},
    },
    expectedValues: {'/effects/0/after/name': 'ticket-7'},
    label: 'custom ticket number names the channel',
  ),
  SandboxFunctionCase(
    'isticket',
    r'$isTicket',
    0,
    'true',
    scenario: {
      'variables': {'channel.name': 'ticket-0001'},
    },
    label: 'detects the word ticket in the current channel name',
  ),
  SandboxFunctionCase(
    'isticket',
    r'$isTicket',
    0,
    'false',
    scenario: {
      'variables': {'channel.name': 'general'},
    },
    label: 'ordinary channels are not tickets',
  ),
  SandboxFunctionCase(
    'isticket',
    r'$isTicket[41]',
    0,
    'true',
    scenario: {'entities': _ticketGuild},
    label: 'checks the name of a specified channel',
  ),
  SandboxFunctionCase(
    'closeticket',
    r'$closeTicket[Not a ticket]',
    0,
    '',
    scenario: {
      'entities': _ticketGuild,
      'variables': {
        'bot.id': '50',
        'channel.id': '41',
        'channel.name': 'ticket-20',
      },
    },
    expectedValues: {
      '/effects/0/type': 'removeChannel',
      '/effects/0/channel_id': '41',
    },
    label: 'deletes a ticket channel',
  ),
  SandboxFunctionCase(
    'closeticket',
    r'$closeTicket[This is not a ticket]',
    0,
    'This is not a ticket',
    scenario: {
      'entities': _ticketGuild,
      'variables': {'bot.id': '50', 'channel.name': 'general'},
    },
    expectedValues: {'/effects': []},
    label: 'normal channel receives the requested error without deletion',
  ),
];
