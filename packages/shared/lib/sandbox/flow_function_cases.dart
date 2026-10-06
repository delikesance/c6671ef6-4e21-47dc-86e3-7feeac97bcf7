import 'function_suite.dart';

/// Cooldown keys need the command the cooldown belongs to.
const _commandContext = {'command.id': '777'};

final sandboxFlowFunctionCases = [
  for (final name in ['cooldown', 'globalcooldown', 'servercooldown'])
    SandboxFunctionCase(
      name,
      '\$$name[1m;blocked]\$setVar[first;yes]\$$name[1m;blocked]\$setVar[second;bad]',
      0,
      'blocked',
      label: 'second use stops before storage mutation',
      scenario: {'variables': _commandContext},
      expectedValues: {
        '/storage_after/global': {'first': 'yes'},
        '/stopped': true,
      },
    ),
  for (final name in ['normal', 'server', 'global'])
    SandboxFunctionCase(
      'getcooldown',
      '\$getCooldown[$name]',
      0,
      '0',
      label: 'no active cooldown: $name',
      scenario: {'variables': _commandContext},
    ),
  SandboxFunctionCase(
    'getcooldown',
    r'$getCooldown[user]',
    0,
    '',
    label: 'cooldown type must be normal, server or global',
    scenario: {'variables': _commandContext},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $getCooldown: Cooldown type must be normal, server or global.',
    },
  ),
  SandboxFunctionCase(
    'getcooldown',
    r'$getCooldown',
    0,
    '',
    label: 'cooldown type is required',
    scenario: {'variables': _commandContext},
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $getCooldown: Invalid argument count for $getCooldown: 0.',
    },
  ),
  SandboxFunctionCase(
    'getcooldown',
    r'$cooldown[1m;wait]$checkCondition[$getCooldown[normal]>0]',
    0,
    'true',
    label: 'active cooldown is readable',
    scenario: {'variables': _commandContext},
  ),
  SandboxFunctionCase(
    'getcooldown',
    r'$cooldown[1m;wait]$cooldown[1m;$checkCondition[$getCooldown[normal]>0]]',
    0,
    'true',
    label: 'inside the error message',
    scenario: {'variables': _commandContext},
  ),
  SandboxFunctionCase(
    'changecooldowntime',
    r'$changeCooldownTime[D;H;Mins;Secs]$cooldown[1h;%time-h% of %time-m%]$cooldown[1h;%time-h% of %time-m%]',
    0,
    '1 H of 60 Mins',
    label: 'relabels the time units of cooldown messages',
    scenario: {'variables': _commandContext},
  ),
  SandboxFunctionCase(
    'changecooldowntime',
    r'$changeCooldownTime[;H;M;S]',
    0,
    '',
    label: 'labels must not be empty',
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $changeCooldownTime: Cooldown time labels must not be empty.',
    },
  ),
  SandboxFunctionCase(
    'wait',
    r'$wait[1ms]$setVar[after;yes]done',
    0,
    'done',
    expectedValues: {'/storage_after/global/after': 'yes'},
  ),
  SandboxFunctionCase(
    'wait',
    r'$wait[0s]$setVar[after;yes]done',
    0,
    '',
    label: 'duration must be positive',
    expectedValues: {
      '/success': false,
      '/error':
          r'BDFD L1:1 $wait: Duration must be positive and at most 40 minutes.',
    },
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
    'after',
    expectedValues: {
      '/effects/0/type': 'deferInteraction',
      '/effects/0/ephemeral': true,
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
  for (final item in <(String, Map<String, String>, String)>[
    ('commandname', {'commandName': 'scolor'}, 'scolor'),
    ('commandtrigger', {'command.trigger': 'scolor'}, 'scolor'),
    ('commandtype', {'commandType': 'chatInput'}, 'chatInput'),
    ('commandfolder', {'command.folder': 'Utilities'}, 'Utilities'),
    (
      'customid',
      {'interaction.type': '3', 'interaction.customId': 'select_colors'},
      'select_colors',
    ),
    ('slashid', {'interaction.command.id': '555'}, '555'),
  ])
    SandboxFunctionCase(
      item.$1,
      '\$${item.$1}',
      0,
      item.$3,
      scenario: {'variables': item.$2},
    ),
];
