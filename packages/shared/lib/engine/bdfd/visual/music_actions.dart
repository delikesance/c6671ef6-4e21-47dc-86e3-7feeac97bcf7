import '../../../services/bot_music_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Music and voice blocks on the native engine: playMusic, pauseMusic,
/// resumeMusic, skipMusic, stopMusic, setMusicVolume, setMusicLoop, seekMusic,
/// getMusicInfo, joinVoice and leaveVoice.
///
/// Parity with the historical `executeLavalinkAction` branch of `handleActions`:
///   - `playMusic` / `joinVoice` without `userId` and `channelId` get the
///     author's id injected (interaction user, then `user.id`, `author.id`,
///     `userId`) so the user's voice channel can be resolved;
///   - string payload values are resolved one by one (no deep resolution);
///   - Lavalink failures never fail the block: `results[key]` becomes
///     `'Error: ...'` (see [applyLavalinkResult], shared with the historical
///     loop), plus the `results['<key>.<prop>']` keys; the error mode is never
///     consulted for them;
///   - without a Lavalink service the historical loop reaches its dispatch
///     `switch` and throws the same [StateError] text.
/// The effects go through [BotMusicBlockService] (the production adapter runs
/// the shared `lavalink_music_actions.dart` actions that BDFD's `$playMusic` family
/// uses as well), so BDFD's own throwing contract is untouched.
final Map<BotCreatorActionType, ActionHandler> musicActionHandlers = {
  for (final type in musicActionTypes) type: _music,
};

/// The historical loop records these through an executor (always traced).
const Set<BotCreatorActionType> musicActionTypes = {
  BotCreatorActionType.playMusic,
  BotCreatorActionType.pauseMusic,
  BotCreatorActionType.resumeMusic,
  BotCreatorActionType.skipMusic,
  BotCreatorActionType.stopMusic,
  BotCreatorActionType.setMusicVolume,
  BotCreatorActionType.setMusicLoop,
  BotCreatorActionType.seekMusic,
  BotCreatorActionType.getMusicInfo,
  BotCreatorActionType.joinVoice,
  BotCreatorActionType.leaveVoice,
};

bool _always(Action action) => true;

/// Every payload of these types runs natively.
final Map<BotCreatorActionType, bool Function(Action)> musicLeafPredicates = {
  for (final type in musicActionTypes) type: _always,
};

BotMusicOperation? _operation(BotCreatorActionType type) => switch (type) {
  BotCreatorActionType.playMusic => BotMusicOperation.play,
  BotCreatorActionType.pauseMusic => BotMusicOperation.pause,
  BotCreatorActionType.resumeMusic => BotMusicOperation.resume,
  BotCreatorActionType.skipMusic => BotMusicOperation.skip,
  BotCreatorActionType.stopMusic => BotMusicOperation.stop,
  BotCreatorActionType.setMusicVolume => BotMusicOperation.volume,
  BotCreatorActionType.setMusicLoop => BotMusicOperation.loop,
  BotCreatorActionType.seekMusic => BotMusicOperation.seek,
  BotCreatorActionType.joinVoice => BotMusicOperation.join,
  BotCreatorActionType.leaveVoice => BotMusicOperation.leave,
  _ => null, // getMusicInfo
};

Future<String?> _music(ActionCall call) async {
  final env = call.env;
  final lavalink = env.lavalinkService;
  if (lavalink == null) {
    throw StateError(
      'Action ${call.type.name} should have been handled by an executor '
      'before switch dispatch.',
    );
  }
  final raw = Map<String, dynamic>.from(call.payload);
  if (call.type == BotCreatorActionType.playMusic ||
      call.type == BotCreatorActionType.joinVoice) {
    final userId = raw['userId']?.toString().trim();
    final channelId = raw['channelId']?.toString().trim();
    if ((userId == null || userId.isEmpty) &&
        (channelId == null || channelId.isEmpty)) {
      final author =
          env.interaction?.user?.id.toString() ??
          env.variables['user.id'] ??
          env.variables['author.id'] ??
          env.variables['userId'];
      if (author != null && author.isNotEmpty) {
        raw['userId'] = author;
        env.onLog?.call(
          'Lavalink: auto-injected userId=$author for action ${call.type.name}',
        );
      } else {
        env.onLog?.call(
          'Lavalink: could not resolve userId — '
          'interaction=${env.interaction != null}, '
          'userId=${env.variables['userId']}',
        );
      }
    }
  }
  final payload = <String, dynamic>{
    for (final entry in raw.entries)
      entry.key: entry.value is String
          ? call.resolve(entry.value as String)
          : entry.value,
  };
  // Same dereferences as the historical call (`guildId!`, `client`).
  final service = DiscordBotMusicService(
    client: env.client!,
    guildId: env.guildSnowflake!,
    lavalink: lavalink,
  );
  final operation = _operation(call.type);
  final result = operation == null
      ? await service.info(payload)
      : await service.execute(operation, payload);
  final results = call.sink.scope(call.path);
  applyLavalinkResult(result, results, call.key);
  return results[call.key] ?? '';
}
