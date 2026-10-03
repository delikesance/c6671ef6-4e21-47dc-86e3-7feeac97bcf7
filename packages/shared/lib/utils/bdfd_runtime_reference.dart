/// Small, executable examples of this implementation's BDFD dialect. The
/// Copilot exposes these alongside syntax validation, without executing them
/// against the user's bot. Keep the XP example covered by the runtime tests.
const bdfdXpMessageWorkflow = r'''
$if[$guildID!=]
$if[$isBot==false]
$var[length;$charCount[$trimSpace[$message]]]
$if[$var[length]>0]
$cooldown[15s]
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

/// Administrator-only slash command. Do not repair legacy negative balances
/// by clamping them: the lost progression needs a separately reviewed repair.
const bdfdXpAddCommand = r"""
$onlyIf[$guildID!=;Utilise cette commande dans un serveur.]
$onlyAdmin[Cette commande est réservée aux administrateurs.]
$var[target;((opts.membre.id))]
$var[gain;((opts.montant))]
$onlyIf[$isInteger[$var[gain]]==true;Indique un montant d'XP entier valide.]
$onlyIf[$var[gain]>=1;Indique un montant d'XP positif.]
$var[level;$getGuildMemberVar[level;$var[target]]]
$var[xp;$getGuildMemberVar[xp;$var[target]]]
$onlyIf[$var[level]>=0;Le niveau stocké nécessite une réparation.]
$onlyIf[$var[xp]>=0;L'XP stocké nécessite une réparation.]
$var[oldLevel;$var[level]]
$var[xp;$sum[$var[xp];$var[gain]]]
$for[i=0;i<100;i++]
$var[required;$ceil[$calculate[100*(1.5^$var[level])]]]
$if[$var[xp]>=$var[required]]
$var[xp;$sub[$var[xp];$var[required]]]
$var[level;$sum[$var[level];1]]
$endif
$endfor
$var[required;$ceil[$calculate[100*(1.5^$var[level])]]]
$onlyIf[$var[xp]<$var[required];Le montant dépasse la limite de calcul.]
$setGuildMemberVar[xp;$var[xp];$var[target]]
$setGuildMemberVar[level;$var[level];$var[target]]
$reply$c[]✅ $var[gain] XP ajoutés à <@$var[target]> — niveau $var[oldLevel] ➜ $var[level] ($var[xp] XP restants).
""";

Map<String, dynamic> bdfdRuntimeReference({
  bool legacyUserVariables = false,
  bool includeExamples = true,
}) => {
  'execution_mode': 'bdfd_script',
  'bdfdUserVariableSemantics': legacyUserVariables ? 1 : 2,
  'user_functions': legacyUserVariables
      ? r'Legacy bot: $getUserVar/$setUserVar without an explicit guild use global-user storage. Do not assume current-server isolation. Use $getGuildMemberVar/$setGuildMemberVar for explicit server/member isolation.'
      : r'Official semantics: $getUserVar/$setUserVar use the current guild and author by default; $resetUserVar resets all members unless a user is given.',
  'storage': {
    'user': {
      'meaning':
          'Global-user values shared by a user across all servers. Existing user data remains here after migration.',
      'get': r'$getVar[key;userID]',
      'set': r'$setVar[key;value;userID]',
      'reset':
          r'$resetGlobalUserVar[key;optionalUserID] is a Bot Creator extension. It resets only that user (author by default), not all users.',
    },
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
  'slash_commands': {
    'options':
        r'Use ((opts.montant)) for a numeric option and ((opts.membre.id)) for a member ID. $args[index;optionName] also falls back to a named option; positional $args alone is empty in a slash invocation.',
    'response':
        r'$reply$c[] responds to the interaction. $var values and explicit scoped getters can be used directly in the response or when constructing another temporary variable, including inside parentheses.',
    'permissions':
        'Set default_member_permissions only on the intended command, and retain a runtime guard. Keep /level public; use permission 8 (Administrator) for the admin-only /addxp example.',
  },
  'validation':
      'Compilation checks syntax only. Do not claim successful runtime behavior or storage writes from compilation. Do not bypass a failing numeric check, hide unresolved output, or clamp a negative balance as a substitute for finding the cause.',
  'message_event': {
    'category': 'messages',
    'event': 'messageCreate',
    'content': r'$message',
    'author': r'$authorID',
    'guild': r'$guildID',
    'cooldown':
        r'$cooldown[15s] stops silently and is isolated by bot, member and server. Place it before writes. This cooldown is kept in memory and resets on runtime restart.',
    'requirements':
        'Guild message events and Message Content intent must be enabled in the bot configuration and Discord Developer Portal to inspect normal message text.',
  },
  if (includeExamples)
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
        'admin_command': {
          'name': 'addxp',
          'description': "Ajoute de l'XP à un membre du serveur",
          'default_member_permissions': '8',
          'options': [
            {'name': 'membre', 'type': 6, 'required': true},
            {'name': 'montant', 'type': 4, 'required': true, 'min_value': 1},
          ],
          'execution_mode': 'bdfd_script',
          'script': bdfdXpAddCommand,
        },
        'rules':
            'Starts at level 0. Trimmed message length earns ceil(length/10) XP, capped at 30; blank/bot/DM messages are ignored. Cooldown 15 seconds per server/member. Remaining XP carries over; the next level costs ceil(100*1.5^level). An award of at most 30 cannot cross more than one level because the minimum cost is 100.',
        'validation':
            'Development regression tests execute these examples with the shared runtime. Still call local_validate_bdfd on the exact proposed source. No live Discord test or installation is implied.',
      },
    },
};
