/// Small, executable examples of this implementation's BDFD dialect. The
/// Copilot exposes these alongside syntax validation, without executing them
/// against the user's bot. Keep the XP example covered by the runtime tests.
const bdfdXpMessageWorkflow = r'''
$if[$guildID!=]
$if[$isBot==false]
$var[length;$charCount[$trimSpace[$message]]]
$if[$var[length]>0]
$cooldown[60s]
$var[gain;$min[30;$max[1;$ceil[$divide[$var[length];10]]]]]
$var[level;$getGuildMemberVar[level]]
$var[xp;$sum[$getGuildMemberVar[xp];$var[gain]]]
$var[required;$ceil[$calculate[100*(1.5^$var[level])]]]
$if[$var[xp]>=$var[required]]
$var[xp;$sub[$var[xp];$var[required]]]
$var[level;$sum[$var[level];1]]
$endif
$setGuildMemberVar[xp;$var[xp]]
$setGuildMemberVar[level;$var[level]]
$endif
$endif
$endif
''';

const bdfdXpLevelCommand = r'''
$onlyIf[$guildID!=;Utilise cette commande dans un serveur.]
$var[level;$getGuildMemberVar[level]]
$var[xp;$getGuildMemberVar[xp]]
$var[required;$ceil[$calculate[100*(1.5^$var[level])]]]
$reply$c[]Niveau $var[level] — $var[xp] / $var[required] XP
''';

Map<String, dynamic> bdfdRuntimeReference() => {
  'execution_mode': 'bdfd_script',
  'storage': {
    'guildMember': {
      'meaning': 'A separate value for each server/member pair.',
      'get': r'$getGuildMemberVar[key;optionalUserID;optionalGuildID]',
      'set': r'$setGuildMemberVar[key;value;optionalUserID;optionalGuildID]',
      'default_context':
          'Current server and author; no IDs need to be invented.',
      'defaults':
          'Declare numeric defaults with local_set_variable, scope guildMember, value_type number, value 0. An undefined getter returns an empty string, not zero.',
    },
  },
  'math': {
    'calculate':
        r'$calculate supports arithmetic + - * / % ^ and parentheses. Use separate $ceil/$floor/$min/$max functions; function calls such as log(...) inside $calculate are unsupported.',
    'log': r'$log is an action that writes to logs, not an inline logarithm.',
  },
  'message_event': {
    'category': 'messages',
    'event': 'messageCreate',
    'content': r'$message',
    'author': r'$authorID',
    'guild': r'$guildID',
    'cooldown':
        r'$cooldown[60s] stops silently and is isolated by bot, member and server. Place it before writes. This cooldown is kept in memory and resets on runtime restart.',
    'requirements':
        'Guild message events and Message Content intent must be enabled in the bot configuration and Discord Developer Portal to inspect normal message text.',
  },
  'examples': {
    'guild_xp': {
      'variables': [
        {
          'key': 'xp',
          'scope': 'guildMember',
          'value': 0,
          'value_type': 'number',
        },
        {
          'key': 'level',
          'scope': 'guildMember',
          'value': 0,
          'value_type': 'number',
        },
      ],
      'workflow': {
        'name': 'message_xp',
        'workflow_type': 'event',
        'event_trigger': {'category': 'messages', 'event': 'messageCreate'},
        'execution_mode': 'bdfd_script',
        'script': bdfdXpMessageWorkflow,
      },
      'command': {
        'name': 'level',
        'description': 'Affiche ton niveau et ta progression sur ce serveur',
        'execution_mode': 'bdfd_script',
        'script': bdfdXpLevelCommand,
      },
      'rules':
          'Starts at level 0. Trimmed message length earns ceil(length/10) XP, capped at 30; blank/bot/DM messages are ignored. Cooldown 60 seconds per server/member. Remaining XP carries over; the next level costs ceil(100*1.5^level). An award of at most 30 cannot cross more than one level because the minimum cost is 100.',
      'validation':
          'Development regression tests execute these examples with the shared runtime. Still call local_validate_bdfd on the exact proposed source. No live Discord test or installation is implied.',
    },
  },
};
