import 'function_suite.dart';

const _track = {
  'title': 'Fixture Song',
  'author': 'Fixture Artist',
  'duration': 180000,
  'uri': 'https://example.invalid/song',
};

const _music = {
  'channelId': '40',
  'userVoiceChannels': {'20': '40', '21': '41'},
  'tracks': {'fixture song': _track},
  'current': _track,
  'queue': [_track],
  'volume': 55,
  'position': 12000,
  'isPaused': true,
  'loopMode': 'queue',
};

final sandboxMusicFunctionCases = [
  for (final item in [
    ('lavalinkplaying', 'Fixture Song'),
    ('lavalinkauthor', 'Fixture Artist'),
    ('lavalinkduration', '180000'),
    ('lavalinkposition', '12000'),
    ('lavalinkqueuesize', '1'),
    ('lavalinkvolume', '55'),
    ('lavalinkispaused', 'true'),
    ('lavalinkislooping', 'true'),
  ])
    SandboxFunctionCase(
      item.$1,
      '\$${item.$1}',
      0,
      item.$2,
      scenario: {'music': _music},
      label: 'reads the supplied music session',
    ),
  SandboxFunctionCase(
    'playmusic',
    r'$playMusic[fixture song]',
    0,
    '',
    scenario: {
      'music': {
        'userVoiceChannels': {'20': '40'},
        'tracks': {'fixture song': _track},
      },
    },
    expectedValues: {
      '/effects/0/type': 'playMusic',
      '/effects/0/channel_id': '40',
      '/effects/0/title': 'Fixture Song',
    },
    label: 'uses the author voice channel and fixture track',
  ),
  SandboxFunctionCase(
    'playmusic',
    r'$playMusic[fixture song;;21]',
    0,
    '',
    scenario: {
      'music': {
        'userVoiceChannels': {'21': '41'},
        'tracks': {'fixture song': _track},
      },
    },
    expectedValues: {'/effects/0/channel_id': '41'},
    label: 'third argument selects another user voice channel',
  ),
  SandboxFunctionCase(
    'joinvoice',
    r'$joinVoice[40]',
    0,
    '',
    scenario: {'music': {}},
    expectedValues: {'/effects/0/channel_id': '40'},
  ),
  SandboxFunctionCase(
    'leavevoice',
    r'$leaveVoice',
    0,
    '',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/channel_id': '', '/effects/0/title': ''},
  ),
  SandboxFunctionCase(
    'pausemusic',
    r'$pauseMusic$lavalinkIsPaused',
    0,
    'true',
    scenario: {
      'music': {..._music, 'isPaused': false},
    },
    expectedValues: {'/effects/0/paused': true},
  ),
  SandboxFunctionCase(
    'resumemusic',
    r'$resumeMusic$lavalinkIsPaused',
    0,
    'false',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/paused': false},
  ),
  SandboxFunctionCase(
    'skipmusic',
    r'$skipMusic$lavalinkQueueSize',
    0,
    '0',
    scenario: {'music': _music},
    expectedValues: {
      '/effects/0/title': 'Fixture Song',
      '/effects/0/queue_size': 0,
    },
  ),
  SandboxFunctionCase(
    'stopmusic',
    r'$stopMusic$lavalinkPlaying',
    0,
    '',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/title': ''},
  ),
  SandboxFunctionCase(
    'setmusicvolume',
    r'$setMusicVolume[75]$lavalinkVolume',
    0,
    '75',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/volume': 75},
  ),
  SandboxFunctionCase(
    'setmusicloop',
    r'$setMusicLoop[off]$lavalinkIsLooping',
    0,
    'false',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/loop_mode': 'off'},
  ),
  SandboxFunctionCase(
    'seekmusic',
    r'$seekMusic[15]$lavalinkPosition',
    0,
    '15000',
    scenario: {'music': _music},
    expectedValues: {'/effects/0/position_ms': 15000},
    label: 'BDFD seconds become Lavalink milliseconds',
  ),
];
