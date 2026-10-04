library;

import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_shared/actions/lavalink_music.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:nyxx/nyxx.dart';

/// Execute Lavalink music actions.
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
  Map<String, String> result;

  switch (type) {
    case BotCreatorActionType.playMusic:
      result = await playMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.pauseMusic:
      result = await pauseMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.resumeMusic:
      result = await resumeMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.skipMusic:
      result = await skipMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.stopMusic:
      result = await stopMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.setMusicVolume:
      result = await setMusicVolumeAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.setMusicLoop:
      result = await setMusicLoopAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.seekMusic:
      result = await seekMusicAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.getMusicInfo:
      result = await getMusicInfoAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.joinVoice:
      result = await joinVoiceAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    case BotCreatorActionType.leaveVoice:
      result = await leaveVoiceAction(
        client: client,
        guildId: guildId,
        payload: payload,
        lavalinkService: lavalinkService,
      );
    default:
      return false;
  }

  applyLavalinkResult(result, results, resultKey);
  return true;
}

/// Records the outcome of a Lavalink block in [results]: `results[key]` is
/// `'Error: ...'`, `'OK'` or the JSON of the result, and every property is also
/// stored as `results['<key>.<prop>']`. Shared by the historical loop and the
/// native `bc_*` music functions so both write identical keys.
void applyLavalinkResult(
  Map<String, String> result,
  Map<String, String> results,
  String resultKey,
) {
  // If there's an error, propagate it as the main result so callers can detect it.
  if (result.containsKey('error')) {
    results[resultKey] = 'Error: ${result['error']}';
  } else if (result.isEmpty) {
    // Actions like pause/resume/stop/skip return an empty map on success.
    results[resultKey] = 'OK';
  } else {
    // Encode the full result as JSON so ((action.<key>)) gives valid, parseable JSON.
    results[resultKey] = jsonEncode(result);
  }

  // Store each property individually so ((action.<key>.<prop>)) works directly.
  // e.g. ((action.play.title)), ((action.play.author)), ((action.play.duration))
  for (final entry in result.entries) {
    results['$resultKey.${entry.key}'] = entry.value;
  }
}
