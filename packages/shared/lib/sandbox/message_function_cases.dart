import 'function_suite.dart';

const sandboxMessageFunctionCases = [
  SandboxFunctionCase(
    'dm',
    r'$dm Hello privately',
    0,
    ' Hello privately',
    expectedValues: {
      '/responses/0/type': 'sendDm',
      '/responses/0/payload/userId': '20',
      '/effects/0/type': 'sendDm',
    },
  ),
  SandboxFunctionCase(
    'dm',
    r'$dm[20;21]Private notice',
    0,
    'Private notice\nPrivate notice',
    label: 'send response to every listed recipient',
    expectedValues: {
      '/responses/0/payload/userId': '20',
      '/responses/1/payload/userId': '21',
    },
  ),
  SandboxFunctionCase(
    'dm',
    r'$dm[]Mentioned recipient',
    0,
    'Mentioned recipient',
    label: 'empty bracket targets the mentioned user',
    scenario: {
      'variables': {'message.mentions[0]': '21'},
    },
    expectedValues: {'/responses/0/payload/userId': '21'},
  ),
  SandboxFunctionCase(
    'sendembedmessage',
    r'$sendEmbedMessage[30;Above;Heading;https://example.com/title;Body;7EFF88;Author;https://example.com/a.png;Footer;https://example.com/f.png;https://example.com/t.png;https://example.com/i.png;yes;no]',
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
      '/responses/0/payload/embeds/0/timestamp': 'now',
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
    r'$removeLinks$sendMessage[((opts.value))]',
    'before https://example.com after',
    'before  after',
    label: 'explicit sendMessage',
  ),
  SandboxFunctionCase(
    'allowusermentions',
    r'$allowUserMentions[((opts.id))]$sendMessage[hello]',
    0,
    'hello',
    label: 'explicit sendMessage',
    scenario: {
      'options': {'id': '20'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/users': ['20'],
      '/responses/0/payload/allowedMentions/parse': ['roles'],
    },
  ),
  SandboxFunctionCase(
    'usechannel',
    r'$useChannel[((opts.channel))]$sendMessage[hello]',
    0,
    'hello',
    label: 'explicit sendMessage',
    scenario: {
      'options': {'channel': '40'},
    },
    expectedValues: {'/responses/0/payload/channelId': '40'},
  ),
  SandboxFunctionCase(
    'ephemeral',
    r'$ephemeral$sendMessage[((opts.value))]',
    'private',
    'private',
    expectedValues: {'/responses/0/payload/ephemeral': true},
  ),
  SandboxFunctionCase(
    'tts',
    r'$tts((opts.value))',
    'spoken',
    'spoken',
    expectedValues: {'/responses/0/payload/tts': true},
  ),
  SandboxFunctionCase(
    'nomention',
    r'$nomention((opts.value))',
    '<@20>',
    '<@20>',
    expectedValues: {'/responses/0/payload/allowedMentions/parse': []},
  ),
  SandboxFunctionCase(
    'allowmention',
    r'$nomention$allowMention((opts.value))',
    '<@20>',
    '<@20>',
    expectedValues: {
      '/responses/0/payload/allowedMentions/parse': ['users', 'roles'],
    },
  ),
  SandboxFunctionCase(
    'allowusermentions',
    r'$allowUserMentions[((opts.id))]hello',
    0,
    'hello',
    scenario: {
      'options': {'id': '20'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/users': ['20'],
      '/responses/0/payload/allowedMentions/parse': ['roles'],
    },
  ),
  SandboxFunctionCase(
    'allowrolementions',
    r'$allowRoleMentions[((opts.id))]hello',
    0,
    'hello',
    scenario: {
      'options': {'id': '40'},
    },
    expectedValues: {
      '/responses/0/payload/allowedMentions/roles': ['40'],
      '/responses/0/payload/allowedMentions/parse': ['users'],
    },
  ),
  SandboxFunctionCase(
    'deletein',
    r'$deleteIn[((opts.delay))]hello',
    0,
    'hello',
    scenario: {
      'options': {'delay': '5s'},
    },
    expectedValues: {'/responses/0/payload/deleteAfter': '5s'},
  ),
  SandboxFunctionCase(
    'reply',
    r'$reply[((opts.channel));((opts.message))]hello',
    0,
    'hello',
    scenario: {
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
    r'$replyIn[((opts.delay));hello]',
    0,
    'hello',
    scenario: {
      'options': {'delay': '5s'},
      'variables': {'message.id': '50'},
    },
    expectedValues: {
      '/responses/0/payload/targetType': 'reply',
      '/responses/0/payload/channelId': '30',
      '/responses/0/payload/messageId': '50',
      '/responses/0/payload/delay': '5s',
    },
  ),
  SandboxFunctionCase(
    'sendmessage',
    r'$sendMessage[((opts.value))]',
    'hello',
    'hello',
    expectedValues: {'/responses/0/type': 'respondWithMessage'},
  ),
  SandboxFunctionCase(
    'channelsendmessage',
    r'$channelSendMessage[((opts.channel));hello]',
    0,
    'hello',
    scenario: {
      'options': {'channel': '30'},
    },
    expectedValues: {
      '/responses/0/payload/targetType': 'channel',
      '/responses/0/payload/channelId': '30',
    },
  ),
  SandboxFunctionCase(
    'usechannel',
    r'$useChannel[((opts.channel))]hello',
    0,
    'hello',
    scenario: {
      'options': {'channel': '40'},
    },
    expectedValues: {'/responses/0/payload/channelId': '40'},
  ),
  SandboxFunctionCase(
    'removelinks',
    r'$removeLinks((opts.value))',
    'before https://example.com after',
    'before  after',
  ),
];
