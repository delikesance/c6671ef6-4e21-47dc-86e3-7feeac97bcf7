import 'dart:async';

import 'package:bot_creator_shared/actions/handler.dart';
import 'package:bot_creator_shared/engine/bdfd/visual/action_translator.dart';
import 'package:bot_creator_shared/services/lavalink_service.dart';
import 'package:bot_creator_shared/types/action.dart';
import 'package:bot_creator_shared/utils/template_resolver.dart';
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';
import 'package:test/test.dart';

import 'helpers/variables_test_helpers.dart';
import 'helpers/visual_discord_gateway.dart';
import 'helpers/visual_parity_harness.dart'
    show SpyTranslator, visualAction, visualFixtures;

/// Parity of the music and voice blocks between the historical executor
/// (`executeLavalinkAction`) and `bc_<type>` on the native engine, over the same
/// simulated Lavalink service: calls made, `results` (including the swallowed
/// `'Error: ...'` results and `<key>.<prop>` keys), final variables and errors.

Track _track(String id) => Track.fromJson(<String, Object?>{
  'encoded': 'encoded-$id',
  'info': <String, Object?>{
    'identifier': id,
    'isSeekable': true,
    'author': 'auteur',
    'length': 183000,
    'isStream': false,
    'position': 0,
    'title': 'titre-$id',
    'uri': 'https://example.com/$id',
    'artworkUrl': 'https://example.com/$id.png',
    'sourceName': 'http',
  },
  'pluginInfo': <String, Object?>{},
  'userData': <String, Object?>{},
});

class _Output implements LavalinkAudioOutput {
  Track? _current;
  @override
  Future<void> play(Track track) async => _current = track;
  @override
  Future<void> stop() async => _current = null;
  @override
  Future<void> setPaused(bool paused) async {}
  @override
  Future<void> setVolume(int volume) async {}
  @override
  Future<void> seekTo(Duration position) async {}
  @override
  Future<void> disconnect() async {}
  @override
  Track? get currentTrack => _current;
  @override
  Duration get position => const Duration(seconds: 12);
  @override
  bool get isConnected => true;
}

/// Records every call; a method named in [failures] throws its value.
class _FakeLavalink implements LavalinkService {
  final calls = <String>[];
  final failures = <String, Object>{};
  Track? found = _track('found');
  LavalinkSession? current;

  void _call(String name, [String args = '']) {
    calls.add('$name($args)');
    final failure = failures[name];
    if (failure != null) throw failure;
  }

  @override
  Future<LavalinkSession> connect(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
  ) async {
    _call('connect', '$guildId,$channelId');
    return current ??= LavalinkSession(output: _Output());
  }

  @override
  Future<void> disconnect(Snowflake guildId) async =>
      _call('disconnect', '$guildId');
  @override
  Future<Track?> play(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
    String query,
  ) async {
    _call('play', '$guildId,$channelId,$query');
    return found;
  }

  @override
  Future<void> pause(Snowflake guildId) async => _call('pause');
  @override
  Future<void> resume(Snowflake guildId) async => _call('resume');
  @override
  Future<void> skip(Snowflake guildId) async => _call('skip');
  @override
  Future<void> stop(Snowflake guildId) async => _call('stop');
  @override
  Future<void> setVolume(Snowflake guildId, int volume) async =>
      _call('setVolume', '$volume');
  @override
  Future<void> setLoopMode(Snowflake guildId, String mode) async =>
      _call('setLoopMode', mode);
  @override
  Future<void> seekTo(Snowflake guildId, Duration position) async =>
      _call('seekTo', '${position.inMilliseconds}');
  @override
  LavalinkSession? session(Snowflake guildId) => current;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Outcome {
  _Outcome(this.service, this.results, this.variables, this.error, this.native);
  final _FakeLavalink service;
  final Map<String, String>? results;
  final Map<String, String> variables;
  final Object? error;
  final int native;
  String? get errorText =>
      error == null ? null : '${error.runtimeType}: $error';
}

Future<_Outcome> _execute(
  List<Action> actions, {
  required bool native,
  required void Function(_FakeLavalink service)? setup,
  required Map<String, String>? variables,
  required bool lavalink,
  required bool guild,
}) async {
  final service = _FakeLavalink();
  setup?.call(service);
  final values = <String, String>{'guild.id': '10', ...?variables};
  final spy = SpyTranslator();
  Map<String, String>? results;
  Object? error;
  try {
    results = await handleActions(
      VisualGateway(data: visualFixtures()),
      null,
      actions: actions,
      store: MemoryBotDataStore(),
      botId: 'bot',
      variables: values,
      fallbackGuildId: guild ? Snowflake(10) : null,
      resolveTemplate: (value) => resolveTemplatePlaceholders(value, values),
      lavalinkService: lavalink ? service : null,
      actionTranslator: native ? spy : const ActionTranslator.none(),
    );
  } catch (e) {
    error = e;
  }
  values.remove('execution.time');
  return _Outcome(service, results, values, error, spy.native);
}

Future<_Outcome> _parity(
  List<Action> actions, {
  void Function(_FakeLavalink service)? setup,
  Map<String, String>? variables,
  bool lavalink = true,
  bool guild = true,
}) async {
  Future<_Outcome> run(bool native) => _execute(
    actions.map((a) => Action.fromJson(a.toJson())).toList(),
    native: native,
    setup: setup,
    variables: variables,
    lavalink: lavalink,
    guild: guild,
  );
  final historical = await run(false);
  final native = await run(true);
  expect(historical.native, 0);
  expect(native.native, greaterThan(0), reason: 'must run natively');
  expect(native.service.calls, historical.service.calls, reason: 'calls');
  expect(native.results, historical.results, reason: 'results');
  expect(native.variables, historical.variables, reason: 'variables');
  expect(native.errorText, historical.errorText, reason: 'error');
  return native;
}

Action _a(
  BotCreatorActionType type, {
  String? key,
  Map<String, dynamic> payload = const {},
  Map<String, String> error = const {},
}) => visualAction(type, key: key, payload: payload, error: error);

void main() {
  group('playMusic', () {
    test('explicit channel: track data as JSON and sub-keys', () async {
      final outcome = await _parity(
        [
          _a(
            BotCreatorActionType.playMusic,
            key: 'p',
            payload: {'query': ' ((song)) ', 'channelId': '34'},
          ),
        ],
        variables: {'song': 'lofi'},
      );
      expect(outcome.service.calls, ['play(10,34,lofi)']);
      expect(outcome.results!['p.title'], 'titre-found');
      expect(outcome.results!['p.duration'], '183000');
      expect(outcome.results!['p'], contains('"author":"auteur"'));
    });

    test('empty query is a swallowed error result', () async {
      final outcome = await _parity([
        _a(
          BotCreatorActionType.playMusic,
          key: 'p',
          payload: {'query': '  ', 'channelId': '34'},
        ),
        _a(BotCreatorActionType.pauseMusic, key: 'after'),
      ]);
      expect(outcome.results!['p'], 'Error: Query cannot be empty');
      expect(outcome.results!['p.error'], 'Query cannot be empty');
      expect(outcome.results!['after'], 'OK');
    });

    test('user not in a voice channel / no channel at all', () async {
      await _parity(
        [
          _a(BotCreatorActionType.playMusic, key: 'p', payload: {'query': 'x'}),
        ],
        variables: {'user.id': '222'},
      );
      await _parity([
        _a(BotCreatorActionType.playMusic, key: 'p', payload: {'query': 'x'}),
      ]);
      await _parity(
        [
          _a(
            BotCreatorActionType.playMusic,
            key: 'p',
            payload: {'query': 'x', 'userId': '((who))'},
          ),
        ],
        variables: {'who': '222'},
      );
    });

    test('author fallbacks for the injected user id', () async {
      for (final variables in [
        {'author.id': '5'},
        {'userId': '6'},
        {'user.id': '', 'author.id': '7'},
      ]) {
        await _parity([
          _a(BotCreatorActionType.playMusic, key: 'p', payload: {'query': 'x'}),
        ], variables: variables);
      }
    });

    test('no track found, service failure', () async {
      await _parity([
        _a(
          BotCreatorActionType.playMusic,
          key: 'p',
          payload: {'query': 'x', 'channelId': '34'},
        ),
      ], setup: (s) => s.found = null);
      final outcome = await _parity([
        _a(
          BotCreatorActionType.playMusic,
          key: 'p',
          payload: {'query': 'x', 'channelId': '34'},
          error: {'mode': 'stop'},
        ),
        _a(BotCreatorActionType.stopMusic, key: 'next'),
      ], setup: (s) => s.failures['play'] = Exception('lavalink down'));
      expect(outcome.results!['p'], 'Error: Exception: lavalink down');
      expect(outcome.results!.containsKey('next'), isTrue);
    });

    test('invalid channel id is swallowed as well', () async {
      await _parity([
        _a(
          BotCreatorActionType.playMusic,
          key: 'p',
          payload: {'query': 'x', 'channelId': 'abc'},
        ),
      ]);
    });
  });

  group('controls', () {
    test('pause, resume, skip, stop, leave', () async {
      final outcome = await _parity([
        _a(BotCreatorActionType.pauseMusic, key: 'a'),
        _a(BotCreatorActionType.resumeMusic, key: 'b'),
        _a(BotCreatorActionType.skipMusic, key: 'c'),
        _a(BotCreatorActionType.stopMusic, key: 'd'),
        _a(BotCreatorActionType.leaveVoice, key: 'e'),
      ]);
      expect(outcome.results, {
        'a': 'OK',
        'b': 'OK',
        'c': 'OK',
        'd': 'OK',
        'e': 'OK',
      });
    });

    test('Lavalink errors never fail the block nor stop the list', () async {
      final outcome = await _parity(
        [
          _a(BotCreatorActionType.pauseMusic, key: 'a'),
          _a(BotCreatorActionType.skipMusic, key: 'b'),
        ],
        setup: (s) {
          s.failures['pause'] = StateError('no player');
          s.failures['skip'] = 'boom';
        },
      );
      expect(outcome.error, isNull);
      expect(outcome.results!['a'], 'Error: Bad state: no player');
      expect(outcome.results!['b'], 'Error: boom');
    });

    test('volume: number, string, template, missing, invalid', () async {
      for (final volume in <Object?>[80, '120', '((v))', '', null, 'loud']) {
        await _parity(
          [
            _a(
              BotCreatorActionType.setMusicVolume,
              key: 'v',
              payload: {'volume': volume},
            ),
          ],
          variables: {'v': '55'},
        );
      }
    });

    test('loop modes and invalid mode', () async {
      for (final loop in <Object?>[
        'off',
        'TRACK',
        'queue',
        'yes',
        'true',
        'no',
        'false',
        'nope',
        null,
        '((m))',
      ]) {
        await _parity(
          [
            _a(
              BotCreatorActionType.setMusicLoop,
              key: 'l',
              payload: {if (loop != null) 'loop': loop},
            ),
          ],
          variables: {'m': 'track'},
        );
      }
    });

    test('seek: milliseconds, seconds, missing', () async {
      for (final payload in <Map<String, dynamic>>[
        {'position': 5000},
        {'position': '30', 'positionUnit': 'seconds'},
        {'position': '((p))', 'positionUnit': 'seconds'},
        {},
        {'position': 'x'},
      ]) {
        await _parity(
          [_a(BotCreatorActionType.seekMusic, key: 's', payload: payload)],
          variables: {'p': '9'},
        );
      }
    });
  });

  group('joinVoice and getMusicInfo', () {
    test('join explicit, author injected, failure', () async {
      await _parity([
        _a(
          BotCreatorActionType.joinVoice,
          key: 'j',
          payload: {'channelId': '34'},
        ),
      ]);
      await _parity(
        [_a(BotCreatorActionType.joinVoice, key: 'j')],
        variables: {'user.id': '222'},
      );
      await _parity([_a(BotCreatorActionType.joinVoice, key: 'j')]);
      await _parity([
        _a(
          BotCreatorActionType.joinVoice,
          key: 'j',
          payload: {'channelId': '34'},
        ),
      ], setup: (s) => s.failures['connect'] = Exception('no lavalink'));
    });

    test('info without a session', () async {
      final outcome = await _parity([
        _a(BotCreatorActionType.getMusicInfo, key: 'i'),
      ]);
      expect(outcome.results!['i.isPlaying'], 'false');
    });

    test('info of a playing session', () async {
      final outcome = await _parity(
        [_a(BotCreatorActionType.getMusicInfo, key: 'i')],
        setup: (s) {
          final session = LavalinkSession(output: _Output());
          session.enqueue(_track('a'));
          s.current = session;
        },
      );
      expect(outcome.results!['i.title'], 'titre-a');
      expect(outcome.results!['i.isPlaying'], 'true');
      expect(outcome.results!['i.position'], '12000');
    });

    test('info failure', () async {
      await _parity([
        _a(BotCreatorActionType.getMusicInfo, key: 'i'),
      ], setup: (s) => s.current = _BrokenSession());
    });
  });

  group('environment edge cases', () {
    test('without a Lavalink service the historical error is kept', () async {
      for (final mode in ['stop', 'continue', '']) {
        final outcome = await _parity([
          _a(
            BotCreatorActionType.pauseMusic,
            key: 'a',
            error: {if (mode.isNotEmpty) 'mode': mode},
          ),
          _a(BotCreatorActionType.skipMusic, key: 'b'),
        ], lavalink: false);
        expect(
          '${outcome.results?['a'] ?? outcome.errorText}',
          contains('should have been handled by an executor'),
        );
      }
    });

    test('without a guild', () async {
      await _parity([
        _a(BotCreatorActionType.stopMusic, key: 'a'),
      ], guild: false);
    });

    test('results are usable by later actions', () async {
      final outcome = await _parity([
        _a(
          BotCreatorActionType.playMusic,
          key: 'p',
          payload: {'query': 'x', 'channelId': '34'},
        ),
        _a(
          BotCreatorActionType.setMusicVolume,
          key: 'v',
          payload: {'volume': '((action.p.duration))'},
        ),
      ]);
      expect(outcome.service.calls.last, 'setVolume(183000)');
    });
  });
}

class _BrokenSession implements LavalinkSession {
  @override
  bool get isPlaying => throw StateError('broken session');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
