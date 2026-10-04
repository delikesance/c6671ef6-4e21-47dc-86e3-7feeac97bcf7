import 'package:nyxx/nyxx.dart';

import '../actions/lavalink_music.dart';
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

/// Production adapter over the shared Lavalink actions.
class DiscordBotMusicService implements BotMusicService {
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
}
