import 'function_suite.dart';
import 'message_mutation_function_cases.dart' show messageMutationEntityFixture;

const sandboxMessageFunctionCases = [
  SandboxFunctionCase(
    'dm',
    r'$dm Hello privately',
    0,
    ' Hello privately',
    label: 'direct messages the user who runs the command',
    expectedValues: {
      '/responses/0/destination': 'user',
      '/responses/0/payload/userId': '20',
    },
  ),
  SandboxFunctionCase(
    'dm',
    r'$dm[21]Private notice',
    0,
    'Private notice',
    label: 'optional user ID selects the recipient',
    expectedValues: {
      '/responses/0/destination': 'user',
      '/responses/0/payload/userId': '21',
    },
  ),
  SandboxFunctionCase(
    'dm',
    r'$dm[]Private notice',
    0,
    'Private notice',
    label: 'empty bracket falls back to the command author',
    expectedValues: {'/responses/0/payload/userId': '20'},
  ),
  SandboxFunctionCase(
    'sendembedmessage',
    r'$sendEmbedMessage[30;Above;Heading;https://example.com/title;Body;7EFF88;Author;https://example.com/a.png;Footer;https://example.com/f.png;https://example.com/t.png;https://example.com/i.png;no;no]',
    0,
    'Above',
    expectedValues: {
      '/responses/0/payload/channelId': '30',
      '/responses/0/payload/embeds/0/title': 'Heading',
      '/responses/0/payload/embeds/0/url': 'https://example.com/title',
      '/responses/0/payload/embeds/0/description': 'Body',
      '/responses/0/payload/embeds/0/color': '#7EFF88',
      '/responses/0/payload/embeds/0/author/name': 'Author',
      '/responses/0/payload/embeds/0/author/icon_url':
          'https://example.com/a.png',
      '/responses/0/payload/embeds/0/footer/text': 'Footer',
      '/responses/0/payload/embeds/0/footer/icon_url':
          'https://example.com/f.png',
      '/responses/0/payload/embeds/0/thumbnail/url':
          'https://example.com/t.png',
      '/responses/0/payload/embeds/0/image/url': 'https://example.com/i.png',
    },
  ),
  SandboxFunctionCase(
    'sendembedmessage',
    r'$sendEmbedMessage[30;;Heading;;Body;#AABBCC;;;;;;;no;yes]',
    0,
    '\n100000',
    label: 'return message ID when requested',
    expectedValues: {'/responses/1/payload/content': '100000'},
  ),
  SandboxFunctionCase(
    'removelinks',
    'A cool link: https://botdesignerdiscord.com/'
        r'$removeLinks',
    0,
    'A cool link: ',
    label: 'wiki example',
  ),
  SandboxFunctionCase(
    'allowusermentions',
    r'$allowUserMentions[$message[id]]$sendMessage[hello]',
    0,
    'hello',
    label: 'explicit sendMessage',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'id': '20'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/users': ['20'],
      '/responses/0/payload/allowedMentions/parse': ['roles'],
    },
  ),
  SandboxFunctionCase(
    'usechannel',
    r'$useChannel[$message[channel]]$sendMessage[hello]',
    0,
    'hello',
    label: 'explicit sendMessage',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '40'},
    },
    expectedValues: {'/responses/0/payload/channelId': '40'},
  ),
  SandboxFunctionCase(
    'ephemeral',
    r'$ephemeral$message[value]',
    'private',
    'private',
    expectedValues: {'/responses/0/payload/ephemeral': true},
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'tts',
    r'$tts$message[value]',
    'spoken',
    'spoken',
    expectedValues: {'/responses/0/payload/tts': true},
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'nomention',
    r'$nomention$message[value]',
    '<@20>',
    '<@20>',
    expectedValues: {'/responses/0/payload/allowedMentions/parse': []},
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'allowmention',
    r'$allowMention$message[value]',
    '<@20>',
    '<@20>',
    label: r'mentions in $message stay raw text',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'allowusermentions',
    r'$allowUserMentions[$message[id]]hello',
    0,
    'hello',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'id': '20'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/users': ['20'],
      '/responses/0/payload/allowedMentions/parse': ['roles'],
    },
  ),
  SandboxFunctionCase(
    'allowrolementions',
    r'$allowRoleMentions[$message[id]]hello',
    0,
    'hello',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'id': '40'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/roles': ['40'],
      '/responses/0/payload/allowedMentions/parse': ['users'],
    },
  ),
  SandboxFunctionCase(
    'deletein',
    r'$deleteIn[$message[delay]]hello',
    0,
    'hello',
    scenario: {
      'entities': messageMutationEntityFixture,
      'variables': {'interaction.isSlash': 'true', 'bot.id': '98'},
      'options': {'delay': '5s'},
    },
    expectedValues: {
      '/effects/0/type': 'deleteMessage',
      '/effects/0/channel_id': '30',
      '/effects/0/message_id': '100000',
    },
  ),
  SandboxFunctionCase(
    'reply',
    r'$reply[$message[channel];$message[message]]hello',
    0,
    'hello',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '30', 'message': '50'},
    },
    expectedValues: {
      '/responses/0/payload/targetType': 'reply',
      '/responses/0/payload/channelId': '30',
      '/responses/0/payload/messageId': '50',
    },
  ),
  SandboxFunctionCase(
    'replyin',
    r'$replyIn[$message[delay]]hello',
    0,
    'hello',
    scenario: {
      'options': {'delay': '5s'},
      'variables': {'interaction.isSlash': 'true'},
    },
    expectedValues: {'/effects/0/type': 'replyIn', '/effects/0/delay_ms': 5000},
  ),
  SandboxFunctionCase(
    'sendmessage',
    r'$sendMessage[$message[value]]',
    'hello',
    'hello',
    label: 'sends a new channel message, not the command response',
    expectedValues: {'/responses/0/type': 'sendMessage'},
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'channelsendmessage',
    r'$channelSendMessage[$message[channel];hello]',
    0,
    'hello',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '30'},
    },
    expectedValues: {
      '/responses/0/payload/targetType': 'channel',
      '/responses/0/payload/channelId': '30',
    },
  ),
  SandboxFunctionCase(
    'usechannel',
    r'$useChannel[$message[channel]]hello',
    0,
    'hello',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'channel': '40'},
    },
    expectedValues: {'/responses/0/payload/channelId': '40'},
  ),
  SandboxFunctionCase(
    'removelinks',
    r'$removeLinks$message[value]',
    'before https://example.com after',
    'before  after',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
];
