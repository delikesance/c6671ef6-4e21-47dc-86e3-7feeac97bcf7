import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:lavalink/lavalink.dart' hide VoiceState;
import 'package:nyxx/nyxx.dart';

import 'package:nyxx_lavalink/src/lavalink_player.dart';

/// An internal extension adding utility methods to [Stream].
extension StreamExtension<T> on Stream<T> {
  /// Equivalent to [Iterable.whereType].
  Stream<U> whereType<U>() => where((event) => event is U).cast<U>();
}

/// A plugin that adds Lavalink support to [NyxxGateway] clients.
class LavalinkPlugin extends NyxxPlugin<NyxxGateway> {
  /// The current version of `nyxx_lavalink`.
  static const version = '4.0.0-dev.1';

  /// The default client name used when connecting to lavalink.
  static const clientName = 'nyxx_lavalink/$version';

  /// The URI relative to which the Lavalink API is accessed.
  ///
  /// This URI must include the port on which the server is running. It must not include the `/v4` version suffix.
  final Uri base;

  /// The password to use when authenticating with the Lavalink server.
  final String password;

  /// A stream of messages received by Lavalink clients created by this plugin.
  Stream<LavalinkMessage> get onMessage => _messagesController.stream;
  final StreamController<LavalinkMessage> _messagesController = StreamController.broadcast();

  /// A stream of [StatsMessage]s received by Lavalink clients created by this plugin.
  Stream<StatsMessage> get onStats => onMessage.whereType<StatsMessage>();

  /// A stream of [LavalinkReadyMessage]s received by Lavalink clients created by this plugin.
  Stream<LavalinkReadyMessage> get onReady => onMessage.whereType<LavalinkReadyMessage>();

  /// A stream of [PlayerUpdateMessage]s received by Lavalink clients created by this plugin.
  Stream<PlayerUpdateMessage> get onPlayerUpdate => onMessage.whereType<PlayerUpdateMessage>();

  /// A stream of [LavalinkEvent]s received by Lavalink clients created by this plugin.
  Stream<LavalinkEvent> get onEvent => onMessage.whereType<LavalinkEvent>();

  /// A stream of [TrackEndEvent]s received by Lavalink clients created by this plugin.
  Stream<TrackEndEvent> get onTrackEnd => onEvent.whereType<TrackEndEvent>();

  /// A stream of [TrackExceptionEvent]s received by Lavalink clients created by this plugin.
  Stream<TrackExceptionEvent> get onTrackException => onEvent.whereType<TrackExceptionEvent>();

  /// A stream of [TrackStartEvent]s received by Lavalink clients created by this plugin.
  Stream<TrackStartEvent> get onTrackStart => onEvent.whereType<TrackStartEvent>();

  /// A stream of [TrackStuckEvent]s received by Lavalink clients created by this plugin.
  Stream<TrackStuckEvent> get onTrackStuck => onEvent.whereType<TrackStuckEvent>();

  /// A stream of [WebSocketClosedEvent]s received by Lavalink clients created by this plugin.
  Stream<WebSocketClosedEvent> get onWebsocketClosed => onEvent.whereType<WebSocketClosedEvent>();

  /// A stream of [LavalinkPlayer]s emitted when a Lavalink player connects to a voice channel.
  Stream<LavalinkPlayer> get onPlayerConnected => _playerConnectedController.stream;
  final StreamController<LavalinkPlayer> _playerConnectedController = StreamController.broadcast();

  final LavalinkClient? _customClient;

  /// Create a new [LavalinkPlugin].
  LavalinkPlugin({
    required this.base,
    required this.password,
  }) : _customClient = null;

  /// Create a new [LavalinkPlugin] that uses a custom [LavalinkClient].
  LavalinkPlugin.usingClient(LavalinkClient this._customClient)
      : base = _customClient.base,
        password = _customClient.password;

  @override
  NyxxPluginState<NyxxGateway, LavalinkPlugin> createState() => _LavalinkPluginState(this);

  /// Connect to a voice channel using Lavalink.
  ///
  /// The returned [LavalinkPlayer] can be used to control the player in the channel.
  Future<LavalinkPlayer> connect(NyxxGateway client, Snowflake channelId, Snowflake guildId) async {
    client.logger.fine('Lavalink: connect requested for channelId=$channelId, guildId=$guildId');
    client.gateway.updateVoiceState(
      guildId,
      GatewayVoiceStateBuilder(
        channelId: channelId,
        isMuted: false,
        isDeafened: false,
      ),
    );

    return await onPlayerConnected.firstWhere((player) => player.guildId == guildId);
  }

  Future<T> _withClient<T>(Future<T> Function(HttpLavalinkClient client) f) async {
    if (_customClient case final customClient?) {
      return f(customClient);
    } else {
      final client = HttpLavalinkClient(base: base, password: password);
      final result = await f(client);
      await client.close();
      return result;
    }
  }

  /// Load information about the track or tracks identified by [identifier].
  Future<LoadResult> loadTrack(String identifier) => _withClient((client) => client.loadTrack(identifier));

  /// Decode a base64-encoded [Track].
  Future<Track> decodeTrack(String encodedTrack) => _withClient((client) => client.decodeTrack(encodedTrack));

  /// Decode multiple base64-encoded [Track]s.
  Future<List<Track>> decodeTracks(List<String> encodedTracks) => _withClient((client) => client.decodeTracks(encodedTracks));

  /// Fetch information about the Lavalink server.
  Future<LavalinkInfo> fetchInfo() => _withClient((client) => client.getInfo());

  /// Fetch statistics about the Lavalink server.
  Future<LavalinkStats> fetchStats() => _withClient((client) => client.getStats());

  /// Fetch the current version of the Lavalink server.
  Future<String> fetchVersion() => _withClient((client) => client.getVersion());
}

class _LavalinkPluginState extends NyxxPluginState<NyxxGateway, LavalinkPlugin> {
  LavalinkClient? lavalinkClient;

  final Map<Snowflake, VoiceState> _voiceStates = {};
  final Map<Snowflake, VoiceServerUpdateEvent> _voiceServers = {};
  final Map<Snowflake, _SentVoiceState> _sentVoiceStates = {};

  _LavalinkPluginState(super.plugin);

  @override
  Future<void> afterConnect(NyxxGateway client) async {
    await super.afterConnect(client);

    lavalinkClient = plugin._customClient ??
        await LavalinkClient.connect(
          plugin.base,
          password: plugin.password,
          userId: client.user.id.toString(),
          clientName: LavalinkPlugin.clientName,
        );

    lavalinkClient!.connection.listen(
      plugin._messagesController.add,
      onError: plugin._messagesController.addError,
      cancelOnError: false,
    );

    client.onVoiceServerUpdate.listen((event) {
      client.logger.fine('Lavalink: onVoiceServerUpdate received for guildId=${event.guildId}');
      _voiceServers[event.guildId] = event;
      _tryUpdateVoiceState(client, event.guildId);
    });

    client.onVoiceStateUpdate.listen((event) async {
      if (event.state.userId != client.user.id) return;

      final guildId = event.state.guildId;
      if (guildId == null) return;

      client.logger.fine('Lavalink: onVoiceStateUpdate received for guildId=$guildId, channelId=${event.state.channelId}');
      if (event.state.channelId == null) {
        _voiceStates.remove(guildId);
        _voiceServers.remove(guildId);
        _sentVoiceStates.remove(guildId);
        try {
          await lavalinkClient!.deletePlayer(guildId.toString());
        } catch (_) {}
      } else {
        _voiceStates[guildId] = event.state;
        _tryUpdateVoiceState(client, guildId);
      }
    });

    client.onGuildCreate.listen((event) {
      if (event is! GuildCreateEvent) return;

      for (final state in event.voiceStates) {
        if (state.userId != client.user.id) continue;

        client.logger.fine('Lavalink: onGuildCreate voice state found for guildId=${event.guild.id}');
        _voiceStates[event.guild.id] = state;
        _tryUpdateVoiceState(client, event.guild.id);
        break;
      }
    });

    client.onGuildDelete.listen((event) {
      if (event.isUnavailable) return;

      _voiceServers.remove(event.guild.id);
      _voiceStates.remove(event.guild.id);
      _sentVoiceStates.remove(event.guild.id);
    });
  }

  Future<void> _tryUpdateVoiceState(NyxxGateway client, Snowflake guildId) async {
    final voiceState = _voiceStates[guildId];
    final voiceServer = _voiceServers[guildId];

    if (voiceState == null || voiceServer == null) return;

    final channelId = voiceState.channelId;
    if (channelId == null) {
      client.logger.warning('Lavalink: Voice state channelId is null for guild $guildId');
      return;
    }

    final rawEndpoint = voiceServer.endpoint;
    if (rawEndpoint == null) {
      client.logger.warning('Lavalink: Voice server endpoint is null for guild $guildId');
      return;
    }

    final endpoint = rawEndpoint;

    final currentVoice = _SentVoiceState(
      channelId: channelId,
      sessionId: voiceState.sessionId,
      token: voiceServer.token,
      endpoint: endpoint,
    );

    if (_sentVoiceStates[guildId] == currentVoice) {
      client.logger.fine('Lavalink: Voice state for guild $guildId has not changed, skipping update');
      return;
    }

    try {
      client.logger.fine('Lavalink: updating player for guild $guildId with endpoint=$endpoint, channelId=$channelId');

      final sessionId = lavalinkClient!.connection.sessionId;
      final uri = lavalinkClient!.base.resolve('/v4/sessions/$sessionId/players/$guildId');
      final body = {
        'voice': {
          'token': voiceServer.token,
          'endpoint': endpoint,
          'sessionId': voiceState.sessionId,
          'channelId': channelId.toString(),
        }
      };

      final response = await http.patch(
        uri,
        headers: {
          'Authorization': lavalinkClient!.password,
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 400) {
        throw http.ClientException(
          'Lavalink server returned status ${response.statusCode}: ${response.body}',
          uri,
        );
      }

      _sentVoiceStates[guildId] = currentVoice;
      client.logger.info('Lavalink: player update succeeded for guild $guildId');
      plugin._playerConnectedController.add(LavalinkPlayer(
        client: client,
        lavalinkClient: lavalinkClient!,
        plugin: plugin,
        guildId: guildId,
      ));
    } catch (e, stack) {
      client.logger.severe('Lavalink: updatePlayer failed with error: $e', e, stack);
    }
  }

  @override
  Future<void> beforeClose(NyxxGateway client) async {
    await super.beforeClose(client);
    if (plugin._customClient == null) {
      await lavalinkClient!.close();
    }
  }
}

class _SentVoiceState {
  final Snowflake channelId;
  final String sessionId;
  final String token;
  final String endpoint;

  _SentVoiceState({
    required this.channelId,
    required this.sessionId,
    required this.token,
    required this.endpoint,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SentVoiceState &&
          runtimeType == other.runtimeType &&
          channelId == other.channelId &&
          sessionId == other.sessionId &&
          token == other.token &&
          endpoint == other.endpoint;

  @override
  int get hashCode =>
      channelId.hashCode ^ sessionId.hashCode ^ token.hashCode ^ endpoint.hashCode;
}
