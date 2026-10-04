import 'function_suite.dart';

final sandboxTimeFunctionCases = [
  for (final item in [
    ('day', 1, 31),
    ('year', 1970, 9999),
    ('hour', 0, 23),
    ('minute', 0, 59),
    ('second', 0, 59),
  ])
    SandboxFunctionCase(
      item.$1,
      '\$and[\$isInteger[\$${item.$1}];\$checkCondition[\$${item.$1}>=${item.$2}];\$checkCondition[\$${item.$1}<=${item.$3}]]',
      0,
      'true',
      label: 'integer component in valid calendar range',
    ),
  SandboxFunctionCase(
    'month',
    r'$checkCondition[$charCount[$month]>=3]',
    0,
    'true',
    label: 'current month is returned as its English name',
  ),
  SandboxFunctionCase(
    'date',
    r'$charCount[$date]',
    0,
    '10',
    label: 'runtime YYYY-MM-DD output',
  ),
  SandboxFunctionCase(
    'time',
    r'$time[Asia/Tokyo]$charCount[$date]',
    0,
    '10',
    label: 'timezone argument is accepted and produces no output',
  ),
  SandboxFunctionCase(
    'gettimestamp',
    r'$and[$isInteger[$getTimestamp];$checkCondition[$getTimestamp>0];$checkCondition[$getTimestamp<$getTimestampMs]]',
    0,
    'true',
    label: 'epoch seconds, not milliseconds',
  ),
  SandboxFunctionCase(
    'gettimestampms',
    r'$and[$isInteger[$getTimestampMs];$checkCondition[$getTimestampMs>0];$checkCondition[$getTimestampMs>$getTimestamp]]',
    0,
    'true',
    label: 'epoch milliseconds, not seconds',
  ),
  SandboxFunctionCase(
    'executiontime',
    r'$wait[30ms]$and[$isInteger[$executionTime];$checkCondition[$executionTime>=0]]',
    0,
    'true',
    label: 'elapsed milliseconds are an integer; waits are simulated delays',
    expectedValues: {'/effects/0/type': 'replyIn', '/effects/0/delay_ms': 30},
  ),
  SandboxFunctionCase(
    'gettimestampms',
    r'$var[first;$getTimestampMs]$wait[30ms]$checkCondition[$sub[$getTimestampMs;$var[first]]>=0]',
    0,
    'true',
    label: 'clock never moves backwards across a simulated wait',
  ),
  SandboxFunctionCase(
    'and',
    r'$and[$checkCondition[$day>=1];$checkCondition[$hour<=23]]',
    0,
    'true',
    label: 'nested comparisons remain independent',
  ),
  SandboxFunctionCase(
    'and',
    r'$and[$checkCondition[$day<0];$checkCondition[$hour<=23]]',
    0,
    'false',
    label: 'nested false comparison stops conjunction',
  ),
  SandboxFunctionCase(
    'hostingexpiretime',
    r'$hostingExpireTime',
    0,
    '2026-12-31',
    scenario: {
      'variables': {'hosting.expireTime': '2026-12-31'},
    },
    label: 'returns bot hosting expiration time',
  ),
  SandboxFunctionCase(
    'premiumexpiretime',
    r'$premiumExpireTime',
    0,
    '2026-12-31',
    scenario: {
      'variables': {'premium.expireTime': '2026-12-31'},
    },
    label: 'returns bot premium expiration time',
  ),
];
