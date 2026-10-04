import 'runtime.dart';

Map<String, BdfdNativeFunction> bdfdMusicFunctions() => {
  'joinvoice': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'leavevoice': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'playmusic': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 3,
    handler: (call) async => '',
  ),
  'pausemusic': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'resumemusic': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'skipmusic': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'stopmusic': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => '',
  ),
  'setmusicvolume': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'setmusicloop': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'seekmusic': BdfdNativeFunction(
    minArguments: 1,
    maxArguments: 1,
    handler: (call) async => '',
  ),
  'lavalinkplaying': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['lavalink.title'] ?? '',
  ),
  'lavalinkauthor': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['lavalink.author'] ?? '',
  ),
  'lavalinkduration': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['lavalink.duration'] ?? '0',
  ),
  'lavalinkposition': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['lavalink.position'] ?? '0',
  ),
  'lavalinkqueuesize': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['lavalink.queueSize'] ?? '0',
  ),
  'lavalinkvolume': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async => call.context.variables['lavalink.volume'] ?? '100',
  ),
  'lavalinkispaused': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['lavalink.isPaused'] ?? 'false',
  ),
  'lavalinkislooping': BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) async =>
        call.context.variables['lavalink.isLooping'] ?? 'false',
  ),
};
