import '../../services/bot_music_service.dart';
import 'program.dart';
import 'runtime.dart';

/// BotCreator extension (not in the BDFD wiki): voice and playback control
/// through Lavalink. Arguments are evaluated data; effects go through
/// [BotMusicService]. Without a configured service every call fails clearly.
Map<String, BdfdNativeFunction> bdfdMusicFunctions([BotMusicService? service]) {
  Future<String> perform(BdfdInvocation call, BotMusicRequest request) async {
    if (service == null) {
      throw BdfdNativeError('Music service is not configured.', call.location);
    }
    try {
      await call.context.budget.run(
        () => service.perform(request, budget: call.context.budget),
      );
    } on StateError catch (error) {
      throw BdfdNativeError(error.message, call.location);
    }
    return '';
  }

  String author(BdfdInvocation call) =>
      call.context.variables['user.id'] ??
      call.context.variables['author.id'] ??
      '';

  BdfdNativeFunction simple(BotMusicOperation operation) => BdfdNativeFunction(
    minArguments: 0,
    maxArguments: 0,
    handler: (call) => perform(call, BotMusicRequest(operation)),
  );

  return {
    'joinvoice': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 1,
      handler: (call) async {
        final channel = call.argumentCount > 0
            ? (await call.argument(0)).trim()
            : '';
        if (channel.isNotEmpty && (int.tryParse(channel) ?? 0) <= 0) {
          throw BdfdNativeError('Invalid voice channel ID.', call.location);
        }
        return perform(
          call,
          BotMusicRequest(
            BotMusicOperation.join,
            channelId: channel,
            userId: channel.isEmpty ? author(call) : '',
          ),
        );
      },
    ),
    'leavevoice': simple(BotMusicOperation.leave),
    // $playMusic[Query;(Voice channel ID);(User ID)]: without a channel the
    // voice channel of the given user (default: the author) is used.
    'playmusic': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 3,
      handler: (call) async {
        final query = (await call.argument(0)).trim();
        if (query.isEmpty) {
          throw BdfdNativeError('Music query is required.', call.location);
        }
        final channel = call.argumentCount > 1
            ? (await call.argument(1)).trim()
            : '';
        var user = call.argumentCount > 2
            ? (await call.argument(2)).trim()
            : '';
        if (channel.isNotEmpty && (int.tryParse(channel) ?? 0) <= 0) {
          throw BdfdNativeError('Invalid voice channel ID.', call.location);
        }
        if (user.isNotEmpty && (int.tryParse(user) ?? 0) <= 0) {
          throw BdfdNativeError('Invalid user ID.', call.location);
        }
        if (channel.isEmpty && user.isEmpty) user = author(call);
        return perform(
          call,
          BotMusicRequest(
            BotMusicOperation.play,
            query: query,
            channelId: channel,
            userId: channel.isEmpty ? user : '',
          ),
        );
      },
    ),
    'pausemusic': simple(BotMusicOperation.pause),
    'resumemusic': simple(BotMusicOperation.resume),
    'skipmusic': simple(BotMusicOperation.skip),
    'stopmusic': simple(BotMusicOperation.stop),
    'setmusicvolume': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final volume = int.tryParse((await call.argument(0)).trim());
        if (volume == null || volume < 0 || volume > 200) {
          throw BdfdNativeError(
            'Volume must be between 0 and 200.',
            call.location,
          );
        }
        return perform(
          call,
          BotMusicRequest(BotMusicOperation.volume, volume: volume),
        );
      },
    ),
    'setmusicloop': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final mode = (await call.argument(0)).trim().toLowerCase();
        if (!const [
          'off',
          'track',
          'queue',
          'yes',
          'no',
          'true',
          'false',
        ].contains(mode)) {
          throw BdfdNativeError(
            'Loop mode must be off, track, or queue.',
            call.location,
          );
        }
        return perform(
          call,
          BotMusicRequest(BotMusicOperation.loop, loop: mode),
        );
      },
    ),
    // BDFD-style seconds; the transport converts them to milliseconds.
    'seekmusic': BdfdNativeFunction(
      minArguments: 1,
      maxArguments: 1,
      handler: (call) async {
        final seconds = int.tryParse((await call.argument(0)).trim());
        if (seconds == null || seconds < 0) {
          throw BdfdNativeError(
            'Seek position must be a non-negative number of seconds.',
            call.location,
          );
        }
        return perform(
          call,
          BotMusicRequest(BotMusicOperation.seek, positionSeconds: seconds),
        );
      },
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
      handler: (call) async =>
          call.context.variables['lavalink.duration'] ?? '0',
    ),
    'lavalinkposition': BdfdNativeFunction(
      minArguments: 0,
      maxArguments: 0,
      handler: (call) async =>
          call.context.variables['lavalink.position'] ?? '0',
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
      handler: (call) async =>
          call.context.variables['lavalink.volume'] ?? '100',
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
}
