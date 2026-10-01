import 'function_suite.dart';

/// Both branches execute the real guards and check that denied commands cannot
/// perform the storage write following the guard.
const _guards = [
  (
    'onlyif',
    r'$onlyIf[((opts.value))>0;Access denied.]',
    {
      'options': {'value': 1},
    },
    {
      'options': {'value': -1},
    },
  ),
  (
    'onlyadmin',
    r'$onlyAdmin[Access denied.]',
    {
      'variables': {'member.isAdmin': true},
    },
    {
      'variables': {'member.isAdmin': false},
    },
  ),
  (
    'onlynsfw',
    r'$onlyNSFW[Access denied.]',
    {
      'variables': {'channel.nsfw': true},
    },
    {
      'variables': {'channel.nsfw': false},
    },
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
    {
      'variables': {'channel.parentId': '40'},
    },
    {
      'variables': {'channel.parentId': '41'},
    },
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
    {
      'variables': {'member.roles': '12,99'},
    },
    {
      'variables': {'member.roles': '112,99'},
    },
  ),
  (
    'onlyforroles',
    r'$onlyForRoles[Moderator;Access denied.]',
    {
      'variables': {'member.roleNames': 'Moderator,Member'},
    },
    {
      'variables': {'member.roleNames': 'JuniorModerator,Member'},
    },
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
    'blacklistroleids',
    r'$blacklistRoleIDs[12;Access denied.]',
    {
      'variables': {'member.roles': '112,99'},
    },
    {
      'variables': {'member.roles': '12,99'},
    },
  ),
  (
    'blacklistrolesids',
    r'$blacklistRolesIDs[12;Access denied.]',
    {
      'variables': {'member.roles': '112,99'},
    },
    {
      'variables': {'member.roles': '12,99'},
    },
  ),
  (
    'blacklistroles',
    r'$blacklistRoles[Moderator;Access denied.]',
    {
      'variables': {'member.roleNames': 'JuniorModerator,Member'},
    },
    {
      'variables': {'member.roleNames': 'Moderator,Member'},
    },
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
    {
      'variables': {'member.permissions': 'managemessages,kickmembers'},
    },
    {
      'variables': {'member.permissions': 'managemessages'},
    },
  ),
  (
    'onlybotperms',
    r'$onlyBotPerms[ManageMessages;Access denied.]',
    {
      'variables': {'bot.permissions': 'managemessages'},
    },
    {
      'variables': {'bot.permissions': 'manageguild'},
    },
  ),
  (
    'onlybotchannelperms',
    r'$onlyBotChannelPerms[ManageMessages;Access denied.]',
    {
      'variables': {'bot.permissions': 'managemessages'},
    },
    {
      'variables': {'bot.permissions': 'manageguild'},
    },
  ),
  (
    'onlyifmessagecontains',
    r'$onlyIfMessageContains[((opts.value));hello;Access denied.]',
    {
      'options': {'value': 'Hello Alice'},
    },
    {
      'options': {'value': 'Goodbye Alice'},
    },
  ),
  (
    'enabled',
    r'$enabled[((opts.value));Access denied.]',
    {
      'options': {'value': 'yes'},
    },
    {
      'options': {'value': 'no'},
    },
  ),
];

final sandboxGuardFunctionCases = [
  SandboxFunctionCase(
    'onlyforusers',
    r'$onlyForUsers[((opts.name));Access denied.]allowed',
    0,
    'allowed',
    label: 'dynamic username',
    scenario: {
      'options': {'name': 'Alice'},
      'variables': {'author.username': 'aLiCe'},
    },
  ),
  SandboxFunctionCase(
    'onlyifmessagecontains',
    r'$onlyIfMessageContains[((opts.text));((opts.word));Access denied.]allowed',
    0,
    'allowed',
    label: 'dynamic word',
    scenario: {
      'options': {'text': 'Hello\nAlice', 'word': 'HELLO'},
    },
  ),
  SandboxFunctionCase(
    'onlyadmin',
    r'$onlyAdmin[Access denied.]allowed',
    0,
    'allowed',
    label: 'guild owner',
    scenario: {
      'variables': {'author.id': '99'},
    },
  ),
  SandboxFunctionCase(
    'onlyperms',
    r'$onlyPerms[ManageMessages;Access denied.]allowed',
    0,
    'Access denied.',
    label: 'lookalike permission',
    scenario: {
      'variables': {'member.permissions': 'notmanagemessages'},
    },
    expectedValues: {'/stopped': true},
  ),
  SandboxFunctionCase(
    'hasperms',
    r'result=$hasPerms[((opts.target));ManageMessages]',
    0,
    'result=false',
    label: 'unknown target cannot use author permissions',
    scenario: {
      'options': {'target': '21'},
      'variables': {'member.permissions': 'administrator'},
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
        scenario: {
          'variables': {
            'member.permissions': allowed ? 'managemessages' : 'viewchannel',
          },
        },
        expectedValues: {'/storage_after/scoped': {}},
      ),
  SandboxFunctionCase(
    'onlyperms',
    r'$onlyPerms[ManageMessages;Access denied.]allowed',
    0,
    'allowed',
    label: 'administrator',
    scenario: {
      'variables': {'member.permissions': 'administrator'},
    },
  ),
  SandboxFunctionCase(
    'onlyadmin',
    r'$onlyAdmin[Access denied.]allowed',
    0,
    'Access denied.',
    label: 'lookalike permission',
    scenario: {
      'variables': {'member.permissions': 'notadministrator'},
    },
    expectedValues: {'/stopped': true},
  ),
  SandboxFunctionCase(
    'checkuserperms',
    r'result=$checkUserPerms[((opts.target));ManageMessages]',
    0,
    'result=true',
    label: 'target user',
    scenario: {
      'options': {'target': '21'},
      'variables': {'permissions.byId.21': 'managemessages'},
    },
    expectedValues: {'/storage_after/scoped': {}},
  ),
];
