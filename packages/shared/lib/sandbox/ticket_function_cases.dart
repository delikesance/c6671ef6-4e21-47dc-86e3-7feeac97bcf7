import 'function_suite.dart';

const _ticketGuild = {
  'guilds': {
    '10': {
      'channels': [
        {'id': '30', 'name': 'general', 'type': 'text'},
        {'id': '40', 'name': 'Support', 'type': 'category'},
      ],
    },
  },
};

const sandboxTicketFunctionCases = [
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[40;support-Alice]',
    0,
    '62',
    scenario: {'entities': _ticketGuild},
    expectedValues: {
      '/effects/0/type': 'createTicket',
      '/effects/0/after/parent_id': '40',
      '/effects/0/after/permission_overwrites/10/viewChannel': 'deny',
      '/effects/0/after/permission_overwrites/20/viewChannel': 'allow',
      '/storage_after/scoped/channel/62/__ticket': true,
      '/storage_after/scoped/channel/62/__ticket_owner': '20',
    },
    label: 'creates a private ticket in the requested category',
  ),
  SandboxFunctionCase(
    'newticket',
    r'$newTicket[40;support-Alice;Welcome to your ticket]',
    0,
    'Welcome to your ticket\n62',
    scenario: {'entities': _ticketGuild},
    expectedValues: {
      '/responses/0/payload/channelId': '62',
      '/responses/0/payload/content': 'Welcome to your ticket',
    },
    label: 'sends the optional welcome message into the created ticket',
  ),
  SandboxFunctionCase(
    'isticket',
    r'$isTicket',
    0,
    'true',
    scenario: {
      'scoped': {
        'channel': {
          '30': {'__ticket': true, '__ticket_owner': '20'},
        },
      },
    },
    label: 'reads the persisted ticket marker of the current channel',
  ),
  SandboxFunctionCase(
    'isticket',
    r'$isTicket',
    0,
    'false',
    label: 'ordinary channels are not tickets',
  ),
  SandboxFunctionCase(
    'closeticket',
    r'$closeTicket',
    0,
    '',
    scenario: {
      'entities': _ticketGuild,
      'scoped': {
        'channel': {
          '30': {'__ticket': true, '__ticket_owner': '20'},
        },
      },
    },
    expectedValues: {
      '/effects/0/type': 'closeTicket',
      '/effects/0/channel_id': '30',
      '/storage_after/scoped/channel/30': {},
      '/variables/channel.isTicket': 'false',
    },
    label: 'deletes only a marked ticket owned by the caller',
  ),
  SandboxFunctionCase(
    'closeticket',
    r'$closeTicket[This is not a ticket]',
    0,
    'This is not a ticket',
    scenario: {'entities': _ticketGuild},
    expectedValues: {'/effects': []},
    label: 'normal channel receives the requested error without deletion',
  ),
];
