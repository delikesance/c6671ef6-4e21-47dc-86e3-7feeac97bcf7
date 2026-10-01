/// Service that manages a Lavalink audio connection for a bot.
///
/// Wraps [LavalinkPlugin] from nyxx_lavalink and provides
/// queue management and track info used by actions and BDFD functions.
library;

import 'dart:async';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';
import 'package:nyxx_lavalink/nyxx_lavalink.dart';

/// Contrôles de lecture d'une session.
///
/// Fine abstraction au-dessus du player `nyxx_lavalink` : elle permet de
/// tester la file d'attente SANS serveur Lavalink (aucun réseau dans les tests).
abstract class LavalinkAudioOutput {
  Future<void> play(Track track);
  Future<void> stop();
  Future<void> setPaused(bool paused);
  Future<void> setVolume(int volume);
  Future<void> seekTo(Duration position);
  Future<void> disconnect();

  Track? get currentTrack;
  Duration get position;
  bool get isConnected;
}

/// Implémentation réelle : pilote le player de `nyxx_lavalink`.
class NyxxLavalinkOutput implements LavalinkAudioOutput {
  final LavalinkPlayer player;

  NyxxLavalinkOutput(this.player);

  @override
  Future<void> play(Track track) => player.play(track);

  @override
  Future<void> stop() => player.stopPlaying();

  @override
  Future<void> setPaused(bool paused) =>
      paused ? player.pause() : player.resume();

  @override
  Future<void> setVolume(int volume) => player.setVolume(volume);

  @override
  Future<void> seekTo(Duration position) => player.seekTo(position);

  @override
  Future<void> disconnect() => player.disconnect();

  @override
  Track? get currentTrack => player.currentTrack;

  @override
  Duration get position => player.state.position;

  @override
  bool get isConnected => player.state.isConnected;
}

/// File d'attente et état de lecture d'une guilde.
///
/// MODÈLE DE FILE — IL N'Y EN A QU'UN : la file locale ci-dessous.
/// `nyxx_lavalink` n'expose AUCUNE file (`LavalinkPlayer` ne connaît que le
/// morceau courant) : tenir une seconde file « côté player » était la source des
/// doublons et des skips qui rejouaient le même morceau. Règles explicites :
/// - `_entries[_cursor]` est LE morceau courant, un point c'est tout ;
/// - [enqueue] ajoute exactement une entrée et ne démarre la lecture que si
///   rien ne joue (aucune croissance parasite, aucun doublon) ;
/// - la fin d'un morceau (événement Lavalink) avance le curseur d'elle-même ;
/// - [skip] avance le curseur sans JAMAIS rejouer le morceau courant (`loop`
///   est un choix explicite et ne s'applique jamais à un skip) ;
/// - file épuisée → arrêt propre.
class LavalinkSession {
  LavalinkSession({
    required LavalinkAudioOutput output,
    Stream<String>? trackEndReasons,
    // ignore: prefer_initializing_formals
  }) : _output = output {
    if (trackEndReasons != null) bindTrackEnd(trackEndReasons);
  }

  /// Construit la session d'un player réel (fins de morceau comprises).
  factory LavalinkSession.fromPlayer(LavalinkPlayer player) {
    return LavalinkSession(
      output: NyxxLavalinkOutput(player),
      trackEndReasons: player.onTrackEnd.map((event) => event.reason),
    );
  }

  LavalinkAudioOutput _output;
  final List<Track> _entries = <Track>[];
  int _cursor = -1;

  /// Morceau demandé au player dont le démarrage n'est pas encore confirmé par
  /// un `TrackStart` : sans lui, deux `play` rapprochés croiraient que rien ne
  /// joue et remplaceraient le morceau précédent.
  Track? _pendingStart;

  StreamSubscription<String>? _trackEndSub;

  String loopMode = 'off';
  bool get loop => loopMode != 'off';
  int volume = 100;
  bool isPaused = false;

  /// Entrées de la file, dans l'ordre de lecture (le morceau courant inclus).
  List<Track> get entries => List<Track>.unmodifiable(_entries);

  /// Nombre total d'entrées (morceau courant compris).
  int get queueLength => _entries.length;

  /// Nombre de morceaux ENCORE à jouer, morceau courant exclu.
  ///
  /// C'est le nombre exposé par `((lavalink.queueSize))` : une file qui
  /// annonçait 15 ou 30 morceaux déjà joués n'avait aucun sens.
  int get queueSize {
    final remaining = _entries.length - (_cursor + 1);
    return remaining < 0 ? 0 : remaining;
  }

  /// Le morceau courant : le curseur local d'abord, puis la confirmation du
  /// player, puis le démarrage en cours.
  Track? get currentTrack {
    if (_cursor >= 0 && _cursor < _entries.length) return _entries[_cursor];
    return _output.currentTrack ?? _pendingStart;
  }

  bool get isPlaying => _output.currentTrack != null || _pendingStart != null;
  bool get isConnected => _output.isConnected;
  Duration get position => _output.position;

  bool get _hasActivePlayback =>
      _output.currentTrack != null || _pendingStart != null;

  /// Branche le flux des fins de morceau (raisons Lavalink) : la file avance
  /// toute seule, sans intervention.
  void bindTrackEnd(Stream<String> reasons) {
    unawaited(_trackEndSub?.cancel());
    _trackEndSub = reasons.listen(
      (reason) => unawaited(handleTrackEnd(reason)),
    );
  }

  /// Rebranche la session sur un nouveau player (changement de salon) en
  /// CONSERVANT la file et le curseur : rien n'est recopié, rien n'est dupliqué.
  void rebind({
    required LavalinkAudioOutput output,
    Stream<String>? trackEndReasons,
  }) {
    _output = output;
    if (trackEndReasons != null) bindTrackEnd(trackEndReasons);
  }

  /// Ajoute [track] à la file.
  ///
  /// Retourne `true` quand sa lecture a démarré immédiatement (rien ne jouait),
  /// `false` quand il attend son tour. Un appel = une entrée.
  Future<bool> enqueue(Track track) async {
    _entries.add(track);
    if (_hasActivePlayback) return false;
    _cursor = _entries.length - 1;
    await _startCurrent();
    return true;
  }

  /// Passe au morceau suivant. Ne rejoue JAMAIS le morceau courant — c'était le
  /// bug « $skipMusic relance la même chanson ». File épuisée → arrêt propre.
  ///
  /// La boucle n'est JAMAIS consultée ici : elle est réservée à l'enchaînement
  /// automatique ([handleTrackEnd]). Un skip sur le dernier morceau s'arrête.
  Future<void> skip() async {
    final next = _nextIndex(allowLoop: false);
    if (next == null) {
      // Curseur posé APRÈS la dernière entrée (comme en fin de morceau) : sinon
      // `currentTrack` continuerait de désigner un morceau qui ne joue plus.
      _cursor = _entries.isEmpty ? -1 : _entries.length;
      await _stopPlayback();
      return;
    }
    _cursor = next;
    await _startCurrent();
  }

  /// Fin de morceau signalée par Lavalink.
  ///
  /// `replaced` (morceau remplacé par un skip ou une nouvelle lecture) et
  /// `cleanup` (player détruit) sont ignorés : sinon on avancerait deux fois
  /// pour un seul morceau. Les autres raisons enchaînent sur le suivant ; si la
  /// boucle est active on repart du début, sinon la lecture s'arrête là.
  Future<void> handleTrackEnd(String reason) async {
    if (reason == 'replaced' || reason == 'cleanup') return;
    _pendingStart = null;

    if (loopMode == 'track' && _cursor >= 0 && _cursor < _entries.length) {
      await _startCurrent();
      return;
    }

    final next = _nextIndex(allowLoop: loopMode == 'queue');
    if (next == null) {
      if (loopMode == 'queue' && _entries.isNotEmpty) {
        _cursor = 0;
        await _startCurrent();
        return;
      }
      // File épuisée : le player s'est déjà arrêté tout seul.
      _cursor = _entries.isEmpty ? -1 : _entries.length;
      return;
    }
    _cursor = next;
    await _startCurrent();
  }

  Future<void> pause() async {
    await _output.setPaused(true);
    isPaused = true;
  }

  Future<void> resume() async {
    await _output.setPaused(false);
    isPaused = false;
  }

  Future<void> setVolume(int value) async {
    final clamped = value.clamp(0, 200);
    await _output.setVolume(clamped);
    volume = clamped;
  }

  void setLoop(bool value) {
    loopMode = value ? 'queue' : 'off';
  }

  void setLoopMode(String mode) {
    if (!{'off', 'track', 'queue'}.contains(mode)) {
      throw ArgumentError.value(mode, 'mode');
    }
    loopMode = mode;
  }

  Future<void> seekTo(Duration position) => _output.seekTo(position);

  /// Arrête la lecture et vide la file (remise à zéro de la source de vérité).
  Future<void> stop() async {
    _entries.clear();
    _cursor = -1;
    await _stopPlayback();
  }

  /// Détache le player et libère les ressources.
  Future<void> dispose() async {
    await _trackEndSub?.cancel();
    _trackEndSub = null;
    _entries.clear();
    _cursor = -1;
    _pendingStart = null;
    await _output.disconnect();
  }

  Future<void> _startCurrent() async {
    if (_cursor < 0 || _cursor >= _entries.length) return;
    final track = _entries[_cursor];
    // Posé AVANT l'appel réseau : deux demandes simultanées ne peuvent pas
    // démarrer deux morceaux à la fois.
    _pendingStart = track;
    await _output.play(track);
  }

  Future<void> _stopPlayback() async {
    _pendingStart = null;
    isPaused = false;
    await _output.stop();
  }

  /// Index du prochain morceau à jouer, ou `null` quand il n'y en a plus.
  ///
  /// [allowLoop] est réservé à l'enchaînement automatique : un skip ne doit
  /// jamais revenir au morceau courant, et une file d'un seul morceau ne le
  /// rejoue donc jamais.
  int? _nextIndex({required bool allowLoop}) {
    if (_entries.isEmpty) return null;
    final current = (_cursor >= 0 && _cursor < _entries.length)
        ? _entries[_cursor]
        : null;

    for (var i = _cursor + 1; i < _entries.length; i++) {
      if (!_sameTrack(_entries[i], current)) return i;
    }
    if (!allowLoop) return null;

    for (var i = 0; i < _entries.length; i++) {
      if (!_sameTrack(_entries[i], current)) return i;
    }
    return null;
  }

  /// Deux morceaux sont identiques quand leur charge utile encodée l'est.
  static bool _sameTrack(Track? a, Track? b) {
    if (a == null || b == null) return false;
    return a.encoded.isNotEmpty && a.encoded == b.encoded;
  }
}

/// Manages the Lavalink connection lifecycle and exposes player controls.
///
/// The [plugin] is created from a server retained by the auto-selection (or from
/// the bot's own fallback servers) and passed to the gateway via
/// `GatewayClientOptions(plugins: [plugin])` before using this service.
class LavalinkService {
  final LavalinkPlugin _plugin;
  final Map<Snowflake, LavalinkSession> _sessions = {};
  final void Function(String message)? onLog;

  LavalinkService({required LavalinkPlugin plugin, this.onLog})
    : _plugin = plugin; // ignore: prefer_initializing_formals

  /// Create a [LavalinkPlugin] from a config, or return null if no config is set.
  static LavalinkPlugin? createPlugin(LavalinkConfig? config) {
    if (config == null) return null;
    return createPluginForServer(
      host: config.host,
      port: config.port,
      password: config.password,
      useSsl: config.useSsl,
    );
  }

  /// Create a [LavalinkPlugin] for an explicit server (le serveur retenu par la
  /// sélection automatique, ou un serveur personnel de repli).
  /// Returns null when the host is empty.
  static LavalinkPlugin? createPluginForServer({
    required String host,
    required int port,
    required String password,
    required bool useSsl,
  }) {
    if (host.trim().isEmpty) return null;
    return LavalinkPlugin(
      base: Uri(scheme: useSsl ? 'https' : 'http', host: host, port: port),
      password: password,
    );
  }

  /// Wait for the Lavalink connection to be established, with a timeout.
  /// Throws [TimeoutException] if the server doesn't respond within 30 seconds.
  Future<void> waitForReady() async {
    await _plugin.onReady.first.timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          throw TimeoutException('Lavalink server did not respond within 30s'),
    );
  }

  /// Monitor Lavalink connection health — logs WS closures.
  void monitorHealth() {
    _plugin.onWebsocketClosed.listen((event) {
      onLog?.call(
        'Lavalink WebSocket closed: code=${event.code} reason=${event.reason}',
      );
    });
    _plugin.onTrackStuck.listen((event) {
      onLog?.call('Lavalink: track stuck — ${event.track.info.title}');
    });
    _plugin.onTrackException.listen((event) {
      onLog?.call(
        'Lavalink: track exception — ${event.exception.message ?? event.exception.cause}',
      );
    });
  }

  /// Connect to a voice channel and return the session.
  ///
  /// Une seule session par guilde : si le bot change de salon, la MÊME session
  /// est rebranchée sur le nouveau player. La file n'est jamais recopiée, donc
  /// jamais dupliquée.
  Future<LavalinkSession> connect(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
  ) async {
    final existing = _sessions[guildId];
    if (existing != null && _isInRequestedChannel(client, guildId, channelId)) {
      return existing;
    }

    onLog?.call(
      'Lavalink: connecting to voice channel $channelId in guild $guildId...',
    );
    final player = await _plugin
        .connect(client, channelId, guildId)
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () =>
              throw TimeoutException('Lavalink voice connection timed out'),
        )
        .catchError((e) {
          onLog?.call('Lavalink: connect failed — $e');
          throw Exception(
            'Failed to connect to voice channel via Lavalink. '
            'Make sure the Lavalink server is running and accessible.',
          );
        });

    final output = NyxxLavalinkOutput(player);
    final reasons = player.onTrackEnd.map((event) => event.reason);

    if (existing != null) {
      existing.rebind(output: output, trackEndReasons: reasons);
      return existing;
    }

    final session = LavalinkSession(output: output, trackEndReasons: reasons);
    _sessions[guildId] = session;
    return session;
  }

  /// Vrai quand la session est déjà branchée sur le salon demandé.
  ///
  /// Un état vocal non encore mis en cache (`null`) est traité comme « déjà
  /// bon » : le cache Discord retarde, et rebrancher le player à chaque lecture
  /// ne servirait à rien.
  bool _isInRequestedChannel(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
  ) {
    final session = _sessions[guildId];
    if (session == null || !session.isConnected) return false;
    final botChannelId =
        client.guilds.cache[guildId]?.voiceStates[client.user.id]?.channelId;
    return botChannelId == null || botChannelId == channelId;
  }

  /// Disconnect from a guild's voice channel.
  Future<void> disconnect(Snowflake guildId) async {
    final session = _sessions.remove(guildId);
    if (session != null) {
      await session.dispose();
    }
  }

  /// Get or create a session for a guild. Returns null if not connected.
  LavalinkSession? session(Snowflake guildId) => _sessions[guildId];

  // ─── Player controls ────────────────────────────────────────────────────

  /// Play a track by search query. Loads via Lavalink REST API.
  ///
  /// Le morceau est ajouté à la file de la session (une entrée, jamais deux) et
  /// ne démarre que si rien ne joue déjà.
  Future<Track?> play(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
    String query,
  ) async {
    final s = await _ensureSession(client, guildId, channelId);
    if (s == null) return null;

    final trimmedQuery = query.trim();
    final String identifier;
    if (trimmedQuery.startsWith('http://') ||
        trimmedQuery.startsWith('https://')) {
      identifier = trimmedQuery;
    } else {
      identifier = 'ytsearch:$trimmedQuery';
    }

    onLog?.call('Lavalink: searching/loading "$identifier"...');
    final result = await _plugin
        .loadTrack(identifier)
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw TimeoutException('Lavalink search timed out'),
        )
        .catchError((e) {
          onLog?.call('Lavalink: loadTrack failed — $e');
          throw Exception(
            'The Lavalink server did not respond correctly. '
            'Make sure it is running and accessible.',
          );
        });

    if (result is TrackLoadResult) {
      onLog?.call('Lavalink: found single track: ${result.data.info.title}');
      final track = result.data;
      await s.enqueue(track);
      return track;
    } else if (result is PlaylistLoadResult) {
      final tracks = result.data.tracks;
      if (tracks.isEmpty) return null;
      // N morceaux demandés = N entrées à jouer, dans l'ordre : le premier
      // démarre, les autres attendent leur tour.
      for (final track in tracks) {
        await s.enqueue(track);
      }
      onLog?.call(
        'Lavalink: playlist ajoutée — ${tracks.length} morceaux, '
        '${s.queueSize} en attente',
      );
      return s.currentTrack;
    } else if (result is SearchLoadResult) {
      onLog?.call('Lavalink: search results: ${result.data.length} tracks');
      final track = result.data.firstOrNull;
      if (track != null) {
        await s.enqueue(track);
        return track;
      }
    } else if (result is ErrorLoadResult) {
      onLog?.call(
        'Lavalink: load failed — ${result.data.message ?? result.data.cause}',
      );
      return null;
    } else if (result is EmptyLoadResult) {
      onLog?.call('Lavalink: no matches found for "$trimmedQuery"');
      return null;
    }

    onLog?.call(
      'Lavalink: no tracks found for "$trimmedQuery" (loadType: ${result.loadType})',
    );
    return null;
  }

  Future<void> pause(Snowflake guildId) async {
    final s = _sessions[guildId];
    if (s != null) {
      await s.pause();
    }
  }

  Future<void> resume(Snowflake guildId) async {
    final s = _sessions[guildId];
    if (s != null) {
      await s.resume();
    }
  }

  Future<void> skip(Snowflake guildId) async {
    final s = _sessions[guildId];
    if (s == null) return;
    await s.skip();
  }

  Future<void> stop(Snowflake guildId) async {
    final s = _sessions[guildId];
    if (s != null) {
      await s.stop();
    }
  }

  Future<void> setVolume(Snowflake guildId, int volume) async {
    final s = _sessions[guildId];
    if (s != null) {
      await s.setVolume(volume);
    }
  }

  Future<void> setLoop(Snowflake guildId, bool loop) async {
    final s = _sessions[guildId];
    if (s != null) s.setLoop(loop);
  }

  Future<void> setLoopMode(Snowflake guildId, String mode) async {
    final s = _sessions[guildId];
    if (s != null) s.setLoopMode(mode);
  }

  Future<void> seekTo(Snowflake guildId, Duration position) async {
    final s = _sessions[guildId];
    if (s != null) await s.seekTo(position);
  }

  /// Dispose all sessions. The plugin lifecycle is managed by the nyxx client.
  Future<void> dispose() async {
    for (final session in _sessions.values) {
      try {
        await session.dispose();
      } catch (_) {}
    }
    _sessions.clear();
  }

  /// Test connectivity to the configured Lavalink server.
  /// Returns null on success, or an error message string on failure.
  static Future<String?> testConnection({
    required String host,
    required int port,
    required String password,
    required bool useSsl,
  }) async {
    final uri = Uri(
      scheme: useSsl ? 'https' : 'http',
      host: host,
      port: port,
      path: '/v4/info',
    );

    final maskedPassword = password.isEmpty
        ? '[VIDE]'
        : (password.length > 4
              ? '${password.substring(0, 2)}***${password.substring(password.length - 2)}'
              : '***');

    print('Lavalink Connection Test: Starting...');
    print('Lavalink Connection Test: URL = $uri');
    print(
      'Lavalink Connection Test: Password = $maskedPassword (length: ${password.length})',
    );

    try {
      final response = await http
          .get(uri, headers: {'Authorization': password})
          .timeout(const Duration(seconds: 5));

      print(
        'Lavalink Connection Test: Response received. Status Code = ${response.statusCode}',
      );
      print('Lavalink Connection Test: Response Headers = ${response.headers}');
      print(
        'Lavalink Connection Test: Response Body = ${response.body.length > 200 ? "${response.body.substring(0, 200)}..." : response.body}',
      );

      if (response.statusCode == 200) {
        print('Lavalink Connection Test: SUCCESS');
        return null; // Success
      }
      print(
        'Lavalink Connection Test: FAILED with status code ${response.statusCode}',
      );
      return 'Erreur ${response.statusCode}';
    } on http.ClientException catch (e) {
      print(
        'Lavalink Connection Test: ClientException (Connection Refused): ${e.message}',
      );
      return 'Connexion refusée : ${e.message}';
    } on TimeoutException {
      print('Lavalink Connection Test: TimeoutException (5s exceeded)');
      return 'Délai dépassé (5s)';
    } catch (e) {
      print('Lavalink Connection Test: Unknown Error: $e');
      return e.toString();
    }
  }

  Future<LavalinkSession?> _ensureSession(
    NyxxGateway client,
    Snowflake guildId,
    Snowflake channelId,
  ) async {
    if (_isInRequestedChannel(client, guildId, channelId)) {
      return _sessions[guildId];
    }
    return await connect(client, guildId, channelId);
  }
}
