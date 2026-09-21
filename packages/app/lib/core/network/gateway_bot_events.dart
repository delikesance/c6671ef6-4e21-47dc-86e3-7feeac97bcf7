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

/// État de compte poussé par le canal temps réel (`account.updated`) : exactement ce
/// que renvoyait `GET /gateway/runtime`. Le serveur reste l'autorité — l'application
/// n'a plus besoin d'interroger l'API pour connaître sa formule.
class GatewayAccountEventPayload {
  const GatewayAccountEventPayload({
    this.plan = '',
    this.tierCode = '',
    this.displayName = '',
    this.maxBots = 0,
    this.maxTurnkeyBots = 0,
    this.allowOwnBots = true,
    this.allowTurnkey = true,
    this.provider = '',
    this.expiresAt,
  });

  final String plan;
  final String tierCode;
  final String displayName;
  final int maxBots;
  final int maxTurnkeyBots;
  final bool allowOwnBots;
  final bool allowTurnkey;
  final String provider;
  final DateTime? expiresAt;

  /// Projection vers la forme de `GET /gateway/runtime`, pour que les deux sources
  /// (poussée et interrogée) traversent exactement le même code d'application.
  Map<String, dynamic> toRuntimeMap() {
    return <String, dynamic>{
      'plan': plan,
      'tier_code': tierCode,
      'display_name': displayName,
      'max_bots': maxBots,
      'max_turnkey_bots': maxTurnkeyBots,
      'allow_own_bots': allowOwnBots,
      'allow_turnkey': allowTurnkey,
      'provider': provider,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  factory GatewayAccountEventPayload.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expires_at'] ?? json['expiresAt'];
    DateTime? expires;
    if (expiresRaw != null) {
      expires = DateTime.tryParse(expiresRaw.toString())?.toUtc();
    }
    return GatewayAccountEventPayload(
      plan: (json['plan'] ?? '').toString(),
      tierCode: (json['tier_code'] ?? json['tierCode'] ?? '').toString(),
      displayName: (json['display_name'] ?? json['displayName'] ?? '')
          .toString(),
      maxBots: GatewayBotEventPayload._asInt(
        json['max_bots'] ?? json['maxBots'],
      ),
      maxTurnkeyBots: GatewayBotEventPayload._asInt(
        json['max_turnkey_bots'] ?? json['maxTurnkeyBots'],
      ),
      allowOwnBots: _asBool(json['allow_own_bots'] ?? json['allowOwnBots']),
      allowTurnkey: _asBool(json['allow_turnkey'] ?? json['allowTurnkey']),
      provider: (json['provider'] ?? '').toString(),
      expiresAt: expires,
    );
  }

  static bool _asBool(dynamic raw) {
    if (raw == null) return true;
    if (raw is bool) return raw;
    return raw.toString().toLowerCase() != 'false';
  }
}

/// État d'une app hébergée poussé par le canal temps réel (`container.updated`) :
/// remplace le sondage du statut de conteneur.
class GatewayContainerEventPayload {
  const GatewayContainerEventPayload({
    required this.containerId,
    this.state = '',
    this.healthStatus = '',
    this.expiresAt,
  });

  final String containerId;
  final String state;
  final String healthStatus;
  final DateTime? expiresAt;

  factory GatewayContainerEventPayload.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['expires_at'] ?? json['expiresAt'];
    DateTime? expires;
    if (expiresRaw != null) {
      expires = DateTime.tryParse(expiresRaw.toString())?.toUtc();
    }
    return GatewayContainerEventPayload(
      containerId: (json['container_id'] ?? json['containerId'] ?? '')
          .toString(),
      state: (json['state'] ?? '').toString(),
      healthStatus: (json['health_status'] ?? json['healthStatus'] ?? '')
          .toString(),
      expiresAt: expires,
    );
  }
}

enum GatewayBotEventType {
  snapshot,
  botUpdated,
  botDeleted,
  accountUpdated,
  containerUpdated,
  ping,

  /// Type inconnu : ignoré silencieusement. C'est ce qui rend l'application
  /// rétro-compatible — un serveur plus récent peut ajouter des événements sans la
  /// casser, et un serveur plus ancien ne change rien à son comportement.
  unknown,
}

class GatewayBotEvent {
  const GatewayBotEvent({
    required this.type,
    required this.ownerId,
    this.ts,
    this.bot,
    this.bots = const <GatewayBotEventPayload>[],
    this.account,
    this.container,
  });

  final GatewayBotEventType type;
  final String ownerId;
  final DateTime? ts;
  final GatewayBotEventPayload? bot;
  final List<GatewayBotEventPayload> bots;
  final GatewayAccountEventPayload? account;
  final GatewayContainerEventPayload? container;

  factory GatewayBotEvent.fromJson(Map<String, dynamic> json) {
    final typeRaw = (json['type'] ?? '').toString();
    final type = switch (typeRaw) {
      'snapshot' => GatewayBotEventType.snapshot,
      'bot.updated' ||
      'bot.config_updated' ||
      'bot.synced' => GatewayBotEventType.botUpdated,
      'bot.deleted' => GatewayBotEventType.botDeleted,
      'account.updated' => GatewayBotEventType.accountUpdated,
      'container.updated' => GatewayBotEventType.containerUpdated,
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
    final accountRaw = json['account'];
    GatewayAccountEventPayload? account;
    if (accountRaw is Map) {
      account = GatewayAccountEventPayload.fromJson(
        Map<String, dynamic>.from(accountRaw.cast<dynamic, dynamic>()),
      );
    }
    final containerRaw = json['container'];
    GatewayContainerEventPayload? container;
    if (containerRaw is Map) {
      container = GatewayContainerEventPayload.fromJson(
        Map<String, dynamic>.from(containerRaw.cast<dynamic, dynamic>()),
      );
    }
    final tsRaw = json['ts'];
    return GatewayBotEvent(
      type: type,
      ownerId: (json['owner_id'] ?? json['ownerId'] ?? '').toString(),
      ts: tsRaw == null ? null : DateTime.tryParse(tsRaw.toString())?.toUtc(),
      bot: bot,
      bots: bots,
      account: account,
      container: container,
    );
  }
}

/// Politique de retrait progressif de la reconnexion du canal temps réel.
///
/// Une infrastructure qui refuse (400, 502, réseau coupé) ne doit pas être
/// martelée : chaque échec consécutif double l'attente, plafonnée à [maxDelay],
/// avec une légère variation aléatoire pour que tous les appareils d'un parc ne
/// retentent pas au même instant.
class GatewayReconnectBackoff {
  GatewayReconnectBackoff({
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.refusedFloor = const Duration(seconds: 10),
    this.jitterRatio = 0.15,
    Random? random,
  }) : _random = random ?? Random();

  /// Délai de la première reconnexion. La toute première tentative de [start]
  /// reste immédiate : c'est le premier échec qui déclenche ce délai.
  final Duration initialDelay;

  /// Plafond du délai entre deux tentatives.
  final Duration maxDelay;

  /// Plancher appliqué sur un refus net du serveur (poignée de main non mise à
  /// niveau : 400/403/404) : on saute les paliers courts au lieu de relancer à
  /// pleine vitesse une route qui refuse l'appel.
  final Duration refusedFloor;

  /// Amplitude de la variation aléatoire (0.15 = ±15 %).
  final double jitterRatio;

  final Random _random;
  int _failures = 0;

  /// Nombre d'échecs consécutifs par refus net (remis à zéro par tout autre
  /// échec ou par une connexion réussie).
  int _refusedRun = 0;

  /// Nombre d'échecs consécutifs depuis la dernière connexion réussie.
  int get failures => _failures;

  /// Délai avant la prochaine tentative ; l'échec est enregistré ici.
  ///
  /// Séquence sans variation : 1 s, 2 s, 4 s, 8 s, 16 s, 32 s, 60 s, 60 s…
  /// et sur refus net : 10 s, 20 s, 40 s, 60 s, 60 s…
  Duration nextDelay({bool refused = false}) {
    _failures++;
    _refusedRun = refused ? _refusedRun + 1 : 0;
    final exponent = min(_failures - 1, 6);
    var base = initialDelay * pow(2, exponent).toInt();
    if (_refusedRun > 0) {
      // Refus net : les paliers courts ne servent à rien, on repart du plancher
      // et on double à partir de là.
      final fromFloor = refusedFloor * pow(2, min(_refusedRun - 1, 6)).toInt();
      if (fromFloor > base) {
        base = fromFloor;
      }
    }
    if (base > maxDelay) {
      base = maxDelay;
    }
    final jitter = 1 + (2 * _random.nextDouble() - 1) * jitterRatio;
    final millis = (base.inMilliseconds * jitter).round();
    return Duration(milliseconds: millis < 50 ? 50 : millis);
  }

  /// Connexion réussie : le compteur repart de zéro.
  void reset() {
    _failures = 0;
    _refusedRun = 0;
  }
}

typedef GatewayBotEventsConnector = WebSocketChannel Function(Uri uri);

/// Maintains a reconnecting WebSocket to `/gateway/bots/events`.
class GatewayBotEventsSession {
  GatewayBotEventsSession({
    required this.wsUrl,
    required Map<String, String> headers,
    this.connector,
    GatewayReconnectBackoff? backoff,
    this.logger,
  }) : headers = Map<String, String>.from(headers),
       _backoff = backoff ?? GatewayReconnectBackoff();

  final Uri wsUrl;
  final Map<String, String> headers;
  final GatewayBotEventsConnector? connector;

  /// Retrait progressif injectable : les tests utilisent une horloge simulée.
  final GatewayReconnectBackoff _backoff;

  /// Journalisation minimale : une ligne au premier échec d'une panne, une
  /// ligne quand le canal repart, rien entre les deux. Une boucle de
  /// reconnexion ne doit ni inonder le journal ni alarmer l'utilisateur.
  final void Function(String message)? logger;

  final StreamController<GatewayBotEvent> _events =
      StreamController<GatewayBotEvent>.broadcast();
  final StreamController<bool> _connection = StreamController<bool>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposed = false;
  bool _connected = false;

  /// Identifie le canal courant : les rappels d'un canal abandonné (erreur,
  /// fermeture) sont ignorés, sinon un même échec programmerait plusieurs
  /// reconnexions et ferait grimper le compteur à tort.
  int _generation = 0;

  /// Vrai tant qu'une panne en cours a déjà été journalisée.
  bool _outageLogged = false;

  Stream<GatewayBotEvent> get events => _events.stream;
  Stream<bool> get connectionChanges => _connection.stream;
  bool get isConnected => _connected;

  /// Nombre d'échecs consécutifs de reconnexion (0 = canal sain).
  @visibleForTesting
  int get reconnectFailures => _backoff.failures;

  void start() {
    if (_disposed) return;
    unawaited(_connect());
  }

  Future<void> dispose() async {
    _disposed = true;
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _setConnected(false);
    await _events.close();
    await _connection.close();
  }

  Future<void> _connect() async {
    if (_disposed) return;
    final generation = ++_generation;
    // Le nettoyage de l'ancien canal ne doit JAMAIS retarder la reconnexion.
    // `StreamSubscription.cancel()` et `sink.close()` attendent parfois une
    // implémentation de flux qui ne rend jamais la main (contrôleur dont l'annulation
    // dépend d'un `onCancel` qui ne vient pas, socket à moitié morte) : les attendre
    // gèlerait la boucle de reconnexion pour toujours — exactement le défaut que ce
    // chantier corrige. On rend donc la main tout de suite ; les rappels tardifs de
    // l'ancien canal sont neutralisés par la garde de génération.
    final previousSubscription = _subscription;
    final previousChannel = _channel;
    _subscription = null;
    _channel = null;
    unawaited(previousSubscription?.cancel() ?? Future<void>.value());
    if (previousChannel != null) {
      unawaited(
        previousChannel.sink.close().catchError((Object _) {
          // Fermer un canal déjà mort n'est pas une erreur à remonter.
        }),
      );
    }
    if (_disposed || generation != _generation) return;

    final WebSocketChannel channel;
    try {
      final connect =
          connector ??
          (Uri uri) => IOWebSocketChannel.connect(
            uri,
            headers: headers,
            // Une poignée de main qui ne répond jamais ne doit pas geler la
            // reconnexion : sans délai, le canal resterait mort sans nouvel essai.
            connectTimeout: const Duration(seconds: 20),
            pingInterval: const Duration(seconds: 15),
          );
      channel = connect(wsUrl);
    } catch (error) {
      _handleFailure(generation, error);
      return;
    }
    _channel = channel;
    _subscription = channel.stream.listen(
      _onMessage,
      onError: (Object error, StackTrace stack) =>
          _handleFailure(generation, error),
      onDone: () => _handleFailure(generation, null),
      cancelOnError: true,
    );

    try {
      await channel.ready;
    } catch (error) {
      _handleFailure(generation, error);
      return;
    }
    if (_disposed || generation != _generation) return;
    // Poignée de main acceptée : c'est une connexion réellement réussie, le
    // compteur d'échecs repart de zéro.
    _handleEstablished(generation);
  }

  void _handleEstablished(int generation) {
    if (generation != _generation) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    final previousFailures = _backoff.failures;
    _backoff.reset();
    if (previousFailures > 0) {
      _outageLogged = false;
      _log(
        'GatewayBotEventsSession: canal temps réel rétabli '
        'après $previousFailures tentative(s)',
      );
    }
    _setConnected(true);
  }

  /// Échec (ou perte) de la connexion : on programme une reconnexion espacée.
  void _handleFailure(int generation, Object? error) {
    if (_disposed || generation != _generation) return;
    // Neutralise les autres rappels du même canal (erreur + fermeture + ready).
    _generation++;
    // Le CODE DE FERMETURE est la seule chose qui distingue « le serveur a ferme »
    // (1000 normal, 1001, 1008 politique…) d'une coupure reseau (1006). Sans lui,
    // un canal qui s'ouvre puis se ferme en boucle ne laisse aucune trace
    // exploitable : `onDone` ne porte aucune erreur, donc rien a afficher.
    //
    // Lecture DÉFENSIVE : un canal partiel (faux canal de test, implémentation qui
    // n'expose pas ces champs) peut lever ici, et un diagnostic ne doit JAMAIS
    // pouvoir casser la reconnexion — c'est exactement ce qu'il sert à observer.
    var closeDetail = '';
    try {
      final closeCode = _channel?.closeCode;
      final closeReason = _channel?.closeReason;
      if (closeCode != null) {
        closeDetail =
            ' (closeCode=$closeCode'
            '${closeReason == null || closeReason.isEmpty ? '' : ', raison="$closeReason"'})';
      }
    } catch (_) {
      closeDetail = '';
    }
    _setConnected(false);
    final refused = _isServerRefusal(error);
    final delay = _backoff.nextDelay(refused: refused);
    if (!_outageLogged) {
      _outageLogged = true;
      _log(
        'GatewayBotEventsSession: canal temps réel indisponible'
        '${refused ? ' (refus du serveur)' : ''}'
        '${error == null ? closeDetail : ' — $error'}'
        ' ; nouvelle tentative dans ${delay.inMilliseconds} ms',
      );
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      unawaited(_connect());
    });
  }

  /// Un refus net (400/403/404) ne relance pas la reconnexion à pleine vitesse.
  ///
  /// `dart:io` ne transmet pas le code HTTP d'une poignée de main refusée : il
  /// signale seulement que la réponse n'a pas mis la connexion à niveau. C'est
  /// exactement le cas observé en production (un intermédiaire qui ne transmet
  /// pas l'en-tête `Upgrade`), donc ce message vaut refus.
  static bool _isServerRefusal(Object? error) {
    if (error == null) return false;
    final text = error.toString().toLowerCase();
    if (text.contains('not upgraded to websocket')) return true;
    return RegExp(
      r'\[(?:400|403|404)\]'
      r'|status(?:code)?[=: ]+(?:400|403|404)'
      r'|(?:400|403|404)\s+(?:bad request|forbidden|not found)',
    ).hasMatch(text);
  }

  void _log(String message) {
    final sink = logger;
    if (sink != null) {
      sink(message);
    } else {
      debugPrint(message);
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

  /// Faux canal WebSocket imposé aux sessions obtenues en test.
  ///
  /// Sans cette couture, prouver la liaison au canal temps réel demanderait d'ouvrir
  /// une VRAIE socket : le test deviendrait dépendant du réseau, donc non déterministe.
  @visibleForTesting
  static GatewayBotEventsConnector? debugConnectorOverride;

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
      connector: connector ?? debugConnectorOverride,
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
