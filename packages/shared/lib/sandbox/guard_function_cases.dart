import 'function_suite.dart';

/// Permission, role and channel guards read production-shaped entity fixtures
/// (guild roles, members and channels), never ad-hoc context variables. The
/// invoking author is member 20 and the bot is member 98 of guild 10.
Map<String, dynamic> _guild({
  List<Map<String, dynamic>> roles = const [],
  Map<String, dynamic> members = const {},
  List<Map<String, dynamic>> channels = const [],
}) => {
  'guilds': {
    '10': {
      'owner_id': '99',
      'roles': [
        {'id': '10', 'name': '@everyone', 'position': 0, 'permissions': '0'},
        ...roles,
      ],
      'members': {
        '20': {'roles': <String>[]},
        '98': {'roles': <String>[]},
        '99': {'roles': <String>[]},
        ...members,
      },
      'channels': channels.isEmpty
          ? [
              {'id': '30', 'name': 'general', 'type': 'text'},
            ]
          : channels,
    },
  },
};

Map<String, dynamic> _member(List<String> roles) => {'roles': roles};

/// A guild where member 20 holds [permissions] through one role.
Map<String, dynamic> _withPermissions(
  String permissions, {
  String user = '20',
}) => _guild(
  roles: [
    {'id': '70', 'name': 'Staff', 'position': 1, 'permissions': permissions},
  ],
  members: {
    user: _member(['70']),
  },
);

/// A guild where member 20 holds [roleIds]; names mirror the ID in the script.
Map<String, dynamic> _withRoles(List<String> roleIds) => _guild(
  roles: [
    {'id': '12', 'name': 'Moderator', 'position': 3, 'permissions': '0'},
    {'id': '112', 'name': 'JuniorModerator', 'position': 2, 'permissions': '0'},
    {'id': '99', 'name': 'Member', 'position': 1, 'permissions': '0'},
  ],
  members: {'20': _member(roleIds)},
);

Map<String, dynamic> _withChannel(Map<String, dynamic> channel) => _guild(
  channels: [
    {'id': '40', 'name': 'Text', 'type': 'category'},
    {'id': '41', 'name': 'Voice', 'type': 'category'},
    {'id': '30', 'name': 'general', 'type': 'text', ...channel},
  ],
);

Map<String, dynamic> _scenario(
  Map<String, dynamic> entities, {
  Map<String, dynamic> variables = const {},
  Map<String, dynamic> options = const {},
}) => {
  'entities': entities,
  'variables': {'bot.id': '98', ...variables},
  if (options.isNotEmpty) 'options': options,
};

const _manageMessages = 8192; // 1 << 13
const _kickMembers = 2;
const _viewChannel = 1024;
const _manageGuild = 32;
const _administrator = 8;

/// Both branches execute the real guards and check that denied commands cannot
/// perform the storage write following the guard.
final _guards = <(String, String, Map<String, dynamic>, Map<String, dynamic>)>[
  (
    'onlyif',
    r'$onlyIf[$message[value]>0;Access denied.]',
    {
      'options': {'value': 1},
      'variables': {'interaction.isSlash': 'true'},
    },
    {
      'options': {'value': -1},
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  (
    'onlyadmin',
    r'$onlyAdmin[Access denied.]',
    _scenario(_withPermissions('$_administrator')),
    _scenario(_withPermissions('$_manageGuild')),
  ),
  (
    'onlynsfw',
    r'$onlyNSFW[Access denied.]',
    _scenario(_withChannel({'nsfw': true})),
    _scenario(_withChannel({'nsfw': false})),
  ),
  (
    'onlyforids',
    r'$onlyForIDs[20;Access denied.]',
    {
      'variables': {'author.id': '20'},
    },
    {
      'variables': {'author.id': '21'},
    },
  ),
  (
    'onlyforchannels',
    r'$onlyForChannels[30;Access denied.]',
    {
      'variables': {'channel.id': '30'},
    },
    {
      'variables': {'channel.id': '31'},
    },
  ),
  (
    'onlyforservers',
    r'$onlyForServers[10;Access denied.]',
    {
      'variables': {'guild.id': '10'},
    },
    {
      'variables': {'guild.id': '11'},
    },
  ),
  (
    'onlyforcategories',
    r'$onlyForCategories[40;Access denied.]',
    _scenario(_withChannel({'parent_id': '40'})),
    _scenario(_withChannel({'parent_id': '41'})),
  ),
  (
    'onlyforusers',
    r'$onlyForUsers[Alice;Access denied.]',
    {
      'variables': {'author.username': 'Alice'},
    },
    {
      'variables': {'author.username': 'Bob'},
    },
  ),
  (
    'onlyforroleids',
    r'$onlyForRoleIDs[12;Access denied.]',
    _scenario(_withRoles(['12', '99'])),
    _scenario(_withRoles(['112', '99'])),
  ),
  (
    'onlyforroles',
    r'$onlyForRoles[Moderator;Access denied.]',
    _scenario(_withRoles(['12', '99'])),
    _scenario(_withRoles(['112', '99'])),
  ),
  (
    'ignorechannels',
    r'$ignoreChannels[30;Access denied.]',
    {
      'variables': {'channel.id': '31'},
    },
    {
      'variables': {'channel.id': '30'},
    },
  ),
  (
    'blacklistids',
    r'$blacklistIDs[20;Access denied.]',
    {
      'variables': {'author.id': '21'},
    },
    {
      'variables': {'author.id': '20'},
    },
  ),
  (
    'blacklistrolesids',
    r'$blacklistRolesIDs[12;Access denied.]',
    _scenario(_withRoles(['112', '99'])),
    _scenario(_withRoles(['12', '99'])),
  ),
  (
    'blacklistroles',
    r'$blacklistRoles[Moderator;Access denied.]',
    _scenario(_withRoles(['112', '99'])),
    _scenario(_withRoles(['12', '99'])),
  ),
  (
    'blacklistservers',
    r'$blacklistServers[10;Access denied.]',
    {
      'variables': {'guild.id': '11'},
    },
    {
      'variables': {'guild.id': '10'},
    },
  ),
  (
    'blacklistusers',
    r'$blacklistUsers[Alice;Access denied.]',
    {
      'variables': {'author.username': 'Bob'},
    },
    {
      'variables': {'author.username': 'Alice'},
    },
  ),
  (
    'onlyperms',
    r'$onlyPerms[ManageMessages;KickMembers;Access denied.]',
    _scenario(_withPermissions('${_manageMessages | _kickMembers}')),
    _scenario(_withPermissions('$_manageMessages')),
  ),
  (
    'onlybotperms',
    r'$onlyBotPerms[ManageMessages;Access denied.]',
    _scenario(_withPermissions('$_manageMessages', user: '98')),
    _scenario(_withPermissions('$_manageGuild', user: '98')),
  ),
  (
    'onlybotchannelperms',
    r'$onlyBotChannelPerms[$channelID;ManageMessages;Access denied.]',
    _scenario(
      _withPermissions('${_manageMessages | _viewChannel}', user: '98'),
    ),
    _scenario(_withPermissions('${_manageGuild | _viewChannel}', user: '98')),
  ),
  (
    'onlyifmessagecontains',
    r'$onlyIfMessageContains[$message[value];hello;Access denied.]',
    {
      'options': {'value': 'Hello Alice'},
      'variables': {'interaction.isSlash': 'true'},
    },
    {
      'options': {'value': 'Goodbye Alice'},
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  (
    'enabled',
    r'$enabled[$message[value];Access denied.]',
    {
      'options': {'value': 'yes'},
      'variables': {'interaction.isSlash': 'true'},
    },
    {
      'options': {'value': 'no'},
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
];

final sandboxGuardFunctionCases = [
  SandboxFunctionCase(
    'onlyforusers',
    r'$onlyForUsers[$message[name];Access denied.]allowed',
    0,
    'allowed',
    label: 'dynamic username',
    scenario: {
      'options': {'name': 'Alice'},
      'variables': {'interaction.isSlash': 'true', 'author.username': 'aLiCe'},
    },
  ),
  SandboxFunctionCase(
    'onlyifmessagecontains',
    r'$onlyIfMessageContains[$message[text];$message[word];Access denied.]allowed',
    0,
    'allowed',
    label: 'dynamic word',
    scenario: {
      'options': {'text': 'Hello\nAlice', 'word': 'HELLO'},
      'variables': {'interaction.isSlash': 'true'},
    },
  ),
  SandboxFunctionCase(
    'onlyadmin',
    r'$onlyAdmin[Access denied.]allowed',
    0,
    'allowed',
    label: 'guild owner',
    scenario: _scenario(_guild(), variables: {'author.id': '99'}),
  ),
  SandboxFunctionCase(
    'onlyperms',
    r'$onlyPerms[ManageMessages;Access denied.]allowed',
    0,
    'Access denied.',
    label: 'other permission bits do not satisfy the requirement',
    scenario: _scenario(_withPermissions('$_viewChannel')),
    expectedValues: {'/stopped': true},
  ),
  SandboxFunctionCase(
    'hasperms',
    r'result=$hasPerms[$message[target];ManageMessages]',
    0,
    'result=false',
    label: 'another member cannot use the author permissions',
    scenario: {
      'options': {'target': '21'},
      'entities': _guild(
        roles: [
          {'id': '70', 'name': 'Staff', 'position': 1, 'permissions': '8'},
        ],
        members: {
          '20': _member(['70']),
          '21': _member([]),
        },
      ),
      'variables': {'interaction.isSlash': 'true', 'bot.id': '98'},
    },
    expectedValues: {'/storage_after/scoped': {}},
  ),
  for (final guard in _guards)
    for (final allowed in [true, false])
      SandboxFunctionCase(
        guard.$1,
        '${guard.$2}'
        r'$setVar[touched;yes]allowed',
        0,
        allowed ? 'allowed' : 'Access denied.',
        label: allowed ? 'allowed' : 'denied',
        scenario: {
          ...(allowed ? guard.$3 : guard.$4),
          'global': {'touched': 'no'},
        },
        expectedValues: {
          '/storage_after/global/touched': allowed ? 'yes' : 'no',
          '/stopped': !allowed,
        },
      ),
  for (final function in ['checkuserperms', 'checkusersperms', 'hasperms'])
    for (final allowed in [true, false])
      SandboxFunctionCase(
        function,
        'result=\$$function[20;ManageMessages]',
        0,
        'result=$allowed',
        label: allowed ? 'allowed' : 'denied',
        scenario: _scenario(
          _withPermissions('${allowed ? _manageMessages : _viewChannel}'),
        ),
        expectedValues: {'/storage_after/scoped': {}},
      ),
  SandboxFunctionCase(
    'onlyperms',
    r'$onlyPerms[ManageMessages;Access denied.]allowed',
    0,
    'allowed',
    label: 'administrator',
    scenario: _scenario(_withPermissions('$_administrator')),
  ),
  SandboxFunctionCase(
    'onlyadmin',
    r'$onlyAdmin[Access denied.]allowed',
    0,
    'Access denied.',
    label: 'other permissions do not imply administrator',
    scenario: _scenario(_withPermissions('${_manageGuild | _manageMessages}')),
    expectedValues: {'/stopped': true},
  ),
  SandboxFunctionCase(
    'checkuserperms',
    r'result=$checkUserPerms[$message[target];ManageMessages]',
    0,
    'result=true',
    label: 'target user',
    scenario: {
      'options': {'target': '21'},
      'entities': _withPermissions('$_manageMessages', user: '21'),
      'variables': {'interaction.isSlash': 'true', 'bot.id': '98'},
    },
    expectedValues: {'/storage_after/scoped': {}},
  ),
];
