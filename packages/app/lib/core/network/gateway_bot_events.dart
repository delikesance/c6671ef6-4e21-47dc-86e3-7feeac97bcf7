import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Parsed gateway bot payload from `/gateway/bots/events`.
class GatewayBotEventPayload {
  const GatewayBotEventPayload({
    required this.botId,
    this.botName = '',
    this.desiredState = '',
    this.lastRuntimeState = '',
    this.fundingMode = '',
    this.freeMinutesBalance = 0,
    this.sessionActive = false,
    this.sessionExpiresAt,
  });

  final String botId;
  final String botName;
  final String desiredState;
  final String lastRuntimeState;
  final String fundingMode;
  final int freeMinutesBalance;
  final bool sessionActive;
  final DateTime? sessionExpiresAt;

  bool get isRunning {
    final runtime = lastRuntimeState.trim().toLowerCase();
    if (runtime == 'running') return true;
    final desired = desiredState.trim().toUpperCase();
    return desired == 'RUNNING' && runtime != 'stopped' && runtime != 'error';
  }

  factory GatewayBotEventPayload.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['session_expires_at'] ?? json['sessionExpiresAt'];
    DateTime? expires;
    if (expiresRaw != null) {
      expires = DateTime.tryParse(expiresRaw.toString())?.toUtc();
    }
    return GatewayBotEventPayload(
      botId: (json['bot_id'] ?? json['botId'] ?? '').toString(),
      botName: (json['bot_name'] ?? json['botName'] ?? '').toString(),
      desiredState: (json['desired_state'] ?? json['desiredState'] ?? '')
          .toString(),
      lastRuntimeState:
          (json['last_runtime_state'] ?? json['lastRuntimeState'] ?? '')
              .toString(),
      fundingMode: (json['funding_mode'] ?? json['fundingMode'] ?? '')
          .toString()
          .trim()
          .toLowerCase(),
      freeMinutesBalance: _asInt(
        json['free_minutes_balance'] ?? json['freeMinutesBalance'],
      ),
      sessionActive:
          json['session_active'] == true ||
          json['sessionActive'] == true ||
          (json['session_active'] ?? json['sessionActive'])
                  ?.toString()
                  .toLowerCase() ==
              'true',
      sessionExpiresAt: expires,
    );
  }

  static int _asInt(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }
}

enum GatewayBotEventType { snapshot, botUpdated, botDeleted, ping, unknown }

class GatewayBotEvent {
  const GatewayBotEvent({
    required this.type,
    required this.ownerId,
    this.ts,
    this.bot,
    this.bots = const <GatewayBotEventPayload>[],
  });

  final GatewayBotEventType type;
  final String ownerId;
  final DateTime? ts;
  final GatewayBotEventPayload? bot;
  final List<GatewayBotEventPayload> bots;

  factory GatewayBotEvent.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? '').toString();
    final type = switch (typeRaw) {
      'snapshot' => GatewayBotEventType.snapshot,
      'bot.updated' ||
      'bot.config_updated' ||
      'bot.synced' => GatewayBotEventType.botUpdated,
      'bot.deleted' => GatewayBotEventType.botDeleted,
      'ping' => GatewayBotEventType.ping,
      _ => GatewayBotEventType.unknown,
    };
    final botRaw = json['bot'];
    GatewayBotEventPayload? bot;
    if (botRaw is Map) {
      bot = GatewayBotEventPayload.fromJson(
        Map<String, dynamic>.from(botRaw.cast<dynamic, dynamic>()),
      );
    }
    final botsRaw = json['bots'];
    final bots = <GatewayBotEventPayload>[];
    if (botsRaw is List) {
      for (final item in botsRaw) {
        if (item is Map) {
          bots.add(
            GatewayBotEventPayload.fromJson(
              Map<String, dynamic>.from(item.cast<dynamic, dynamic>()),
            ),
          );
        }
      }
    }
    final tsRaw = json['ts'];
    return GatewayBotEvent(
      type: type,
      ownerId: (json['owner_id'] ?? json['ownerId'] ?? '').toString(),
      ts: tsRaw == null ? null : DateTime.tryParse(tsRaw.toString())?.toUtc(),
      bot: bot,
      bots: bots,
    );
  }
}

typedef GatewayBotEventsConnector = WebSocketChannel Function(Uri uri);

/// Maintains a reconnecting WebSocket to `/gateway/bots/events`.
class GatewayBotEventsSession {
  GatewayBotEventsSession({
    required this.wsUrl,
    required Map<String, String> headers,
    this.connector,
  }) : headers = Map<String, String>.from(headers);

  final Uri wsUrl;
  final Map<String, String> headers;
  final GatewayBotEventsConnector? connector;

  final StreamController<GatewayBotEvent> _events =
      StreamController<GatewayBotEvent>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;
  int _attempt = 0;

  Stream<GatewayBotEvent> get events => _events.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;

  void start() {
    if (_disposed) return;
    unawaited(_connect());
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _setConnected(false);
    await _events.close();
    await _connection.close();
  }

  Future<void> _connect() async {
    if (_disposed) return;
    await _subscription?.cancel();
    try {
      await _channel?.sink.close();
    } catch (_) {}

    try {
      final connect =
          connector ??
          (Uri uri) => IOWebSocketChannel.connect(uri, headers: headers);
      final channel = connect(wsUrl);
      _channel = channel;
      _subscription = channel.stream.listen(
        _onMessage,
        onError: (Object error, StackTrace stack) {
          debugPrint('GatewayBotEventsSession error: $error');
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      _attempt = 0;
      _setConnected(true);
    } catch (error) {
      debugPrint('GatewayBotEventsSession connect failed: $error');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final decoded = raw is String
          ? jsonDecode(raw)
          : raw is List<int>
          ? jsonDecode(utf8.decode(raw))
          : raw;
      if (decoded is! Map) return;
      final event = GatewayBotEvent.fromJson(
        Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>()),
      );
      if (!_events.isClosed) {
        _events.add(event);
      }
    } catch (error) {
      debugPrint('GatewayBotEventsSession parse failed: $error');
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _setConnected(false);
    _reconnectTimer?.cancel();
    _attempt++;
    final seconds = min(30, pow(2, min(_attempt, 5)).toInt());
    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      unawaited(_connect());
    });
  }

  void _setConnected(bool value) {
    if (_connected == value) return;
    _connected = value;
    if (!_connection.isClosed) {
      _connection.add(value);
    }
  }
}

/// Process-wide session keyed by manager base URL.
class GatewayBotEventsManager {
  GatewayBotEventsManager._();

  static final Map<String, GatewayBotEventsSession> _sessions =
      <String, GatewayBotEventsSession>{};

  static GatewayBotEventsSession obtain({
    required String baseUrl,
    required Map<String, String> headers,
    GatewayBotEventsConnector? connector,
  }) {
    final key = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    final existing = _sessions[key];
    if (existing != null && !existing._disposed) {
      existing.headers
        ..clear()
        ..addAll(headers);
      return existing;
    }
    final wsBase = key.replaceFirst(RegExp(r'^http'), 'ws');
    final session = GatewayBotEventsSession(
      wsUrl: Uri.parse('$wsBase/gateway/bots/events'),
      headers: headers,
      connector: connector,
    );
    _sessions[key] = session;
    session.start();
    return session;
  }

  @visibleForTesting
  static void resetForTest() {
    for (final session in _sessions.values) {
      unawaited(session.dispose());
    }
    _sessions.clear();
  }
}
