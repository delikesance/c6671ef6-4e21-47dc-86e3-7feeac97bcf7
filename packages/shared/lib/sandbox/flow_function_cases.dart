import 'function_suite.dart';

final sandboxFlowFunctionCases = [
  for (final name in ['cooldown', 'globalcooldown', 'servercooldown'])
    SandboxFunctionCase(
      name,
      '\$$name[1m]\$setVar[first;yes]\$$name[1m;blocked]\$setVar[second;bad]',
      0,
      'blocked',
      label: 'second use stops before storage mutation',
      expectedValues: {
        '/storage_after/global': {'first': 'yes'},
        '/stopped': true,
      },
    ),
  for (final name in ['user', 'normal', 'server', 'global', ''])
    SandboxFunctionCase(
      'getcooldown',
      name.isEmpty ? r'$getCooldown' : '\$getCooldown[$name]',
      0,
      '0',
      label: 'no active cooldown: $name',
    ),
  SandboxFunctionCase(
    'getcooldown',
    r'$cooldown[1m]$checkCondition[$getCooldown[user]>0]',
    0,
    'true',
    label: 'active cooldown is readable',
  ),
  SandboxFunctionCase(
    'getcooldown',
    r'$cooldown[1m]$cooldown[1m;$checkCondition[$getCooldown[user]>0]]',
    0,
    'true',
    label: 'inside the error message',
  ),
  SandboxFunctionCase(
    'changecooldowntime',
    r'$cooldown[1m]$changeCooldownTime[0s]$getCooldown',
    0,
    '0',
    label: 'clear latest cooldown',
  ),
  SandboxFunctionCase(
    'changecooldowntime',
    r'$serverCooldown[1m]$changeCooldownTime[1s]$checkCondition[$getCooldown[server]<=1]',
    0,
    'true',
    label: 'reduce server cooldown',
  ),
  SandboxFunctionCase(
    'changecooldowntime',
    r'$changeCooldownTime[1m]$getCooldown',
    0,
    '0',
    label: 'no cooldown is not created',
  ),
  SandboxFunctionCase(
    'wait',
    r'$wait[0s]$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {'/storage_after/global/after': 'yes'},
  ),
  SandboxFunctionCase(
    'wait',
    r'$wait[$message[delay]]done',
    0,
    'done',
    label: 'runtime duration',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'delay': '10ms'},
    },
  ),
  SandboxFunctionCase(
    'skipactions',
    r'$skipActions[1]$setVar[skipped;bad]$setVar[kept;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global': {'kept': 'yes'},
    },
  ),
  SandboxFunctionCase(
    'skipactions',
    r'$skipActions[$message[count]]$setVar[skipped;bad]$setVar[kept;yes]done',
    0,
    'done',
    label: 'runtime count',
    scenario: {
      'variables': {'interaction.isSlash': 'true'},
      'options': {'count': 1},
    },
    expectedValues: {
      '/storage_after/global': {'kept': 'yes'},
    },
  ),
  SandboxFunctionCase(
    'jumptoaction',
    r'$jumpToAction[3]$setVar[skipped;bad]$setVar[kept;yes]done',
    0,
    'done',
    expectedValues: {
      '/storage_after/global': {'kept': 'yes'},
    },
  ),
  SandboxFunctionCase(
    'c',
    r'$c[ignored comment]response',
    0,
    'response',
    expectedValues: {'/responses/0/type': 'respondWithMessage'},
  ),
  SandboxFunctionCase(
    'defer',
    r'$defer[true]$sendMessage[after]',
    0,
    '\nafter',
    expectedValues: {
      '/responses/0/type': 'deferInteraction',
      '/responses/0/payload/ephemeral': true,
    },
  ),
  SandboxFunctionCase(
    'uptime',
    r'$uptime',
    0,
    '01:02:03',
    scenario: {
      'variables': {'bot.uptime': '3723000'},
    },
  ),
  for (final item in [
    ('commandname', 'commandName', 'scolor'),
    ('commandtrigger', 'commandName', 'scolor'),
    ('commandtype', 'commandType', 'chatInput'),
    ('commandfolder', 'command.folder', 'Utilities'),
    ('customid', 'interaction.customId', 'select_colors'),
    ('slashid', 'interaction.id', '555'),
  ])
    SandboxFunctionCase(
      item.$1,
      '\$${item.$1}',
      0,
      item.$3,
      scenario: {
        'variables': {item.$2: item.$3},
      },
    ),
];
