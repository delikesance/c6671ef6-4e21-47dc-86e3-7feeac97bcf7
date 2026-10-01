import 'dart:convert';

import '../types/action.dart';

/// Deterministic Lavalink fixture. It never opens a voice connection or
/// searches for tracks outside the caller-provided fixture.
class MusicFixture {
  MusicFixture(Map<String, dynamic> fixture)
    : tracks = Map<String, dynamic>.from(fixture['tracks'] as Map? ?? {}),
      userVoiceChannels = Map<String, dynamic>.from(
        fixture['userVoiceChannels'] as Map? ?? {},
      ),
      channelId = (fixture['channelId'] ?? '').toString(),
      volume = int.tryParse('${fixture['volume'] ?? 100}') ?? 100,
      position = int.tryParse('${fixture['position'] ?? 0}') ?? 0,
      paused = fixture['isPaused'] == true,
      loopMode = (fixture['loopMode'] ?? 'off').toString() {
    if (fixture['current'] is Map) {
      current = Map<String, dynamic>.from(fixture['current'] as Map);
    }
    for (final item in fixture['queue'] as List? ?? const []) {
      if (item is Map) queue.add(Map<String, dynamic>.from(item));
    }
  }

  final Map<String, dynamic> tracks;
  final Map<String, dynamic> userVoiceChannels;
  String channelId;
  Map<String, dynamic>? current;
  final List<Map<String, dynamic>> queue = [];
  int volume;
  int position;
  bool paused;
  String loopMode;

  void populate(Map<String, String> variables) {
    variables['lavalink.title'] = current?['title']?.toString() ?? '';
    variables['lavalink.author'] = current?['author']?.toString() ?? '';
    variables['lavalink.duration'] = current?['duration']?.toString() ?? '0';
    variables['lavalink.position'] = position.toString();
    variables['lavalink.queueSize'] = queue.length.toString();
    variables['lavalink.volume'] = volume.toString();
    variables['lavalink.isPaused'] = paused.toString();
    variables['lavalink.isLooping'] = (loopMode != 'off').toString();
    variables['lavalink.thumbnail'] = current?['thumbnail']?.toString() ?? '';
  }

  String? apply(
    BotCreatorActionType type,
    Map<String, dynamic> payload,
    Map<String, String> variables,
    List<Map<String, dynamic>> effects,
  ) {
    const supported = {
      BotCreatorActionType.playMusic,
      BotCreatorActionType.pauseMusic,
      BotCreatorActionType.resumeMusic,
      BotCreatorActionType.skipMusic,
      BotCreatorActionType.stopMusic,
      BotCreatorActionType.setMusicVolume,
      BotCreatorActionType.setMusicLoop,
      BotCreatorActionType.seekMusic,
      BotCreatorActionType.joinVoice,
      BotCreatorActionType.leaveVoice,
      BotCreatorActionType.getMusicInfo,
    };
    if (!supported.contains(type)) return null;

    String result = 'OK';
    switch (type) {
      case BotCreatorActionType.joinVoice:
      case BotCreatorActionType.playMusic:
        final explicit = (payload['channelId'] ?? '').toString();
        final userId =
            (payload['userId'] ??
                    variables['user.id'] ??
                    variables['author.id'] ??
                    '')
                .toString();
        final selected = explicit.isNotEmpty
            ? explicit
            : (userVoiceChannels[userId] ?? '').toString();
        if (int.tryParse(selected) == null) {
          throw StateError('Music simulation requires a voice channel fixture');
        }
        channelId = selected;
        if (type == BotCreatorActionType.playMusic) {
          final query = (payload['query'] ?? '').toString().trim();
          if (query.isEmpty) throw StateError('Query cannot be empty');
          final raw = tracks[query];
          if (raw is! Map) {
            throw StateError(
              'Music simulation requires a track fixture for $query',
            );
          }
          final track = Map<String, dynamic>.from(raw);
          if (current == null) {
            current = track;
            position = 0;
          } else {
            queue.add(track);
          }
          result = jsonEncode({
            'title': track['title']?.toString() ?? '',
            'author': track['author']?.toString() ?? '',
            'duration': track['duration']?.toString() ?? '0',
            'uri': track['uri']?.toString() ?? '',
            'thumbnail': track['thumbnail']?.toString() ?? '',
          });
        }
      case BotCreatorActionType.leaveVoice:
        channelId = '';
        current = null;
        queue.clear();
        position = 0;
        paused = false;
      case BotCreatorActionType.pauseMusic:
        if (current != null) paused = true;
      case BotCreatorActionType.resumeMusic:
        if (current != null) paused = false;
      case BotCreatorActionType.skipMusic:
        current = queue.isEmpty ? null : queue.removeAt(0);
        position = 0;
        paused = false;
      case BotCreatorActionType.stopMusic:
        current = null;
        queue.clear();
        position = 0;
        paused = false;
      case BotCreatorActionType.setMusicVolume:
        final parsed = int.tryParse('${payload['volume'] ?? ''}');
        if (parsed == null) throw StateError('Missing volume parameter');
        volume = parsed.clamp(0, 200);
      case BotCreatorActionType.setMusicLoop:
        final requested = (payload['loop'] ?? 'off')
            .toString()
            .toLowerCase()
            .trim();
        loopMode = switch (requested) {
          'track' => 'track',
          'queue' || 'true' || 'yes' => 'queue',
          'off' || 'false' || 'no' => 'off',
          _ => throw StateError('Loop mode must be off, track, or queue'),
        };
      case BotCreatorActionType.seekMusic:
        final parsed = int.tryParse('${payload['position'] ?? ''}');
        if (parsed == null) throw StateError('Missing position parameter');
        position =
            (payload['positionUnit'] == 'seconds' ? parsed * 1000 : parsed)
                .clamp(
                  0,
                  current == null
                      ? 0
                      : int.tryParse('${current!['duration']}') ?? 0,
                );
      case BotCreatorActionType.getMusicInfo:
        result = jsonEncode(
          current == null
              ? {'isPlaying': 'false'}
              : {
                  'isPlaying': 'true',
                  'title': current!['title']?.toString() ?? '',
                  'author': current!['author']?.toString() ?? '',
                  'duration': current!['duration']?.toString() ?? '0',
                  'position': position.toString(),
                  'queueSize': queue.length.toString(),
                  'volume': volume.toString(),
                  'isPaused': paused.toString(),
                  'isLooping': (loopMode != 'off').toString(),
                },
        );
      default:
        return null;
    }
    populate(variables);
    effects.add({
      'type': type.name,
      'channel_id': channelId,
      'title': current?['title']?.toString() ?? '',
      'queue_size': queue.length,
      'volume': volume,
      'position_ms': position,
      'paused': paused,
      'loop_mode': loopMode,
      'simulated': true,
    });
    return result;
  }
}
