library;

import 'package:bot_creator_shared/services/bot_music_service.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';

export 'package:bot_creator_shared/services/bot_music_service.dart'
    show applyLavalinkResult;

/// Historical dispatch of the Lavalink music actions; delegates to
/// [DiscordBotMusicService] (the logic lives in services/).
/// Returns true if the action type was handled, false otherwise.
Future<bool> executeLavalinkAction({
  required BotCreatorActionType type,
  required NyxxGateway client,
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  required Map<String, String> results,
  required String resultKey,
  required LavalinkService lavalinkService,
}) async {
  final service = DiscordBotMusicService(
    client: client,
    guildId: guildId,
    lavalink: lavalinkService,
  );
  final Map<String, String> result;
  switch (type) {
    case BotCreatorActionType.getMusicInfo:
      result = await service.info(payload);
    case BotCreatorActionType.playMusic:
      result = await service.execute(BotMusicOperation.play, payload);
    case BotCreatorActionType.pauseMusic:
      result = await service.execute(BotMusicOperation.pause, payload);
    case BotCreatorActionType.resumeMusic:
      result = await service.execute(BotMusicOperation.resume, payload);
    case BotCreatorActionType.skipMusic:
      result = await service.execute(BotMusicOperation.skip, payload);
    case BotCreatorActionType.stopMusic:
      result = await service.execute(BotMusicOperation.stop, payload);
    case BotCreatorActionType.setMusicVolume:
      result = await service.execute(BotMusicOperation.volume, payload);
    case BotCreatorActionType.setMusicLoop:
      result = await service.execute(BotMusicOperation.loop, payload);
    case BotCreatorActionType.seekMusic:
      result = await service.execute(BotMusicOperation.seek, payload);
    case BotCreatorActionType.joinVoice:
      result = await service.execute(BotMusicOperation.join, payload);
    case BotCreatorActionType.leaveVoice:
      result = await service.execute(BotMusicOperation.leave, payload);
    default:
      return false;
  }
  applyLavalinkResult(result, results, resultKey);
  return true;
}
