import 'function_suite.dart';

const _guilds = {
  'guilds': {'10': <String, dynamic>{}, '11': <String, dynamic>{}},
};

const sandboxGuildLookupFunctionCases = [
  SandboxFunctionCase(
    'guildexists',
    r'$guildExists[11]',
    0,
    'true',
    label: 'bot belongs to specified server',
    scenario: {'entities': _guilds},
    expectedValues: {
      '/entity_requests/0/operation': 'guilds.fetch',
      '/entity_requests/0/guild_id': '11',
    },
  ),
  SandboxFunctionCase(
    'guildexists',
    r'$guildExists[12]',
    0,
    'false',
    label: 'bot does not belong to specified server',
    scenario: {'entities': _guilds},
  ),
  SandboxFunctionCase(
    'guildexists',
    r'$guildExists[not-an-id]',
    0,
    'false',
    label: 'invalid ID is not a guild lookup',
    scenario: {'entities': _guilds},
    expectedValues: {'/entity_requests': []},
  ),
  SandboxFunctionCase(
    'guildexists',
    r'$guildExists[$message[target]]',
    0,
    'true',
    label: 'dynamic guild ID',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'target': '11'},
      'entities': _guilds,
    },
  ),
  SandboxFunctionCase(
    'serverexists',
    r'$serverExists[12]',
    0,
    'false',
    label: 'server alias uses target ID',
    scenario: {'entities': _guilds},
  ),
  SandboxFunctionCase(
    'getinviteinfo',
    r'$getInviteInfo[xyz;uses]|$getInviteInfo[xyz;inviter]',
    0,
    '7|20',
    scenario: {
      'variables': {'invite[xyz].uses': '7', 'invite[xyz].inviter': '20'},
    },
    label: 'returns the requested invite property',
  ),
  SandboxFunctionCase(
    'getinviteinfo',
    r'$getInviteInfo[xyz;color]',
    0,
    '',
    label: 'unknown invite property is an error',
    expectedValues: {
      '/success': false,
      '/error': r'BDFD L1:1 $getInviteInfo: Unknown invite property.',
    },
  ),
  SandboxFunctionCase(
    'getserverinvite',
    r'$getServerInvite',
    0,
    'https://discord.gg/test',
    scenario: {
      'variables': {'guild.invite': 'https://discord.gg/test'},
    },
    label: 'returns the current server invite link',
  ),
  SandboxFunctionCase(
    'serverinfo',
    r'$serverInfo',
    0,
    'Server overview',
    scenario: {
      'variables': {'guild.info': 'Server overview'},
    },
    label: 'returns server info summary',
  ),
  SandboxFunctionCase(
    'serverregion',
    r'$serverRegion',
    0,
    'us-east',
    scenario: {
      'variables': {'guild.region': 'us-east'},
    },
    label: 'returns voice server region',
  ),
];
