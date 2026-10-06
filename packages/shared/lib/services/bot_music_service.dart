import 'dart:convert';

import 'package:nyxx/nyxx.dart';

import 'lavalink_music_actions.dart';
import '../engine/execution_budget.dart';
import 'lavalink_service.dart';

enum BotMusicOperation {
  join,
  leave,
  play,
  pause,
  resume,
  skip,
  stop,
  volume,
  loop,
  seek,
}

/// Evaluated music request. Values are data; no script is interpreted here.
class BotMusicRequest {
  const BotMusicRequest(
    this.operation, {
    this.query = '',
    this.channelId = '',
    this.userId = '',
    this.volume,
    this.loop = '',
    this.positionSeconds,
  });
  final BotMusicOperation operation;
  final String query;
  final String channelId;
  final String userId;
  final int? volume;
  final String loop;
  final int? positionSeconds;
}

abstract interface class BotMusicService {
  /// Performs one voice/playback operation. Failures throw [StateError].
  Future<void> perform(
    BotMusicRequest request, {
    required CommandExecutionBudget budget,
  });
}

/// Block-style music operations: the payload is the raw (resolved) block
/// payload and the outcome is the result map of the shared Lavalink actions
/// (`title`, `author`, ... on success, an `error` key on failure), never a
/// thrown error. This is what the visual `playMusic`, `pauseMusic`, ...,
/// `getMusicInfo`, `joinVoice` and `leaveVoice` blocks expose as
/// `((action.key.title))` and friends. [BotMusicService.perform] keeps its own
/// throwing contract for BDFD.
abstract interface class BotMusicBlockService {
  Future<Map<String, String>> execute(
    BotMusicOperation operation,
    Map<String, dynamic> payload,
  );

  /// Playback state of the current track (`isPlaying`, `title`, ...).
  Future<Map<String, String>> info(Map<String, dynamic> payload);
}

/// Production adapter over the shared Lavalink actions.
class DiscordBotMusicService implements BotMusicService, BotMusicBlockService {
  const DiscordBotMusicService({
    required this.client,
    required this.guildId,
    required this.lavalink,
  });
  final NyxxGateway client;
  final Snowflake? guildId;
  final LavalinkService lavalink;

  @override
  Future<void> perform(
    BotMusicRequest request, {
    required CommandExecutionBudget budget,
  }) => budget.run(() async {
    final guild = guildId;
    if (guild == null) throw StateError('Music requires a server.');
    final payload = <String, dynamic>{
      if (request.query.isNotEmpty) 'query': request.query,
      if (request.channelId.isNotEmpty) 'channelId': request.channelId,
      if (request.userId.isNotEmpty) 'userId': request.userId,
      if (request.volume != null) 'volume': request.volume,
      if (request.loop.isNotEmpty) 'loop': request.loop,
      if (request.positionSeconds != null) ...{
        'position': request.positionSeconds,
        'positionUnit': 'seconds',
      },
    };
    Future<Map<String, String>> run(
      Future<Map<String, String>> Function({
        required NyxxGateway client,
        required Snowflake guildId,
        Snowflake? channelId,
        required Map<String, dynamic> payload,
        required LavalinkService lavalinkService,
      })
      action,
    ) => action(
      client: client,
      guildId: guild,
      payload: payload,
      lavalinkService: lavalink,
    );
    final result = await switch (request.operation) {
      BotMusicOperation.join => run(joinVoiceAction),
      BotMusicOperation.leave => run(leaveVoiceAction),
      BotMusicOperation.play => run(playMusicAction),
      BotMusicOperation.pause => run(pauseMusicAction),
      BotMusicOperation.resume => run(resumeMusicAction),
      BotMusicOperation.skip => run(skipMusicAction),
      BotMusicOperation.stop => run(stopMusicAction),
      BotMusicOperation.volume => run(setMusicVolumeAction),
      BotMusicOperation.loop => run(setMusicLoopAction),
      BotMusicOperation.seek => run(seekMusicAction),
    };
    budget.check();
    if (result['error'] != null) throw StateError(result['error']!);
  });

  @override
  Future<Map<String, String>> execute(
    BotMusicOperation operation,
    Map<String, dynamic> payload,
  ) {
    final guild = guildId;
    if (guild == null) {
      // The historical loop dereferences the guild unconditionally.
      throw StateError('Music requires a server.');
    }
    final action = switch (operation) {
      BotMusicOperation.join => joinVoiceAction,
      BotMusicOperation.leave => leaveVoiceAction,
      BotMusicOperation.play => playMusicAction,
      BotMusicOperation.pause => pauseMusicAction,
      BotMusicOperation.resume => resumeMusicAction,
      BotMusicOperation.skip => skipMusicAction,
      BotMusicOperation.stop => stopMusicAction,
      BotMusicOperation.volume => setMusicVolumeAction,
      BotMusicOperation.loop => setMusicLoopAction,
      BotMusicOperation.seek => seekMusicAction,
    };
    return action(
      client: client,
      guildId: guild,
      payload: payload,
      lavalinkService: lavalink,
    );
  }

  @override
  Future<Map<String, String>> info(Map<String, dynamic> payload) {
    final guild = guildId;
    if (guild == null) throw StateError('Music requires a server.');
    return getMusicInfoAction(
      client: client,
      guildId: guild,
      payload: payload,
      lavalinkService: lavalink,
    );
  }
}

/// Records the outcome of a Lavalink block in [results]: `results[key]` is
/// `'Error: ...'`, `'OK'` or the JSON of the result, and every property is also
/// stored as `results['<key>.<prop>']`.
void applyLavalinkResult(
  Map<String, String> result,
  Map<String, String> results,
  String resultKey,
) {
  if (result.containsKey('error')) {
    // Propagated as the main result so callers can detect it.
    results[resultKey] = 'Error: ${result['error']}';
  } else if (result.isEmpty) {
    // pause/resume/stop/skip return an empty map on success.
    results[resultKey] = 'OK';
  } else {
    // Full JSON so ((action.<key>)) is parseable.
    results[resultKey] = jsonEncode(result);
  }
  // ((action.<key>.<prop>)) works directly, e.g. ((action.play.title)).
  for (final entry in result.entries) {
    results['$resultKey.${entry.key}'] = entry.value;
  }
}
