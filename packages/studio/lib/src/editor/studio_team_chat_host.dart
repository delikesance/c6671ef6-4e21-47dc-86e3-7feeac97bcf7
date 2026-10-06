import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_ui/bot_creator_ui.dart';

import '../api/studio_api.dart';
import '../platform/event_socket.dart';

/// Fabrique du canal temps réel (injectable : les tests y branchent un faux).
typedef TeamEventSocketFactory =
    EventSocket Function({
      required String url,
      required Future<String?> Function() token,
      required void Function() onMessage,
      required void Function(String data) onData,
      required void Function() onClosed,
    });

EventSocket _webSocket({
  required String url,
  required Future<String?> Function() token,
  required void Function() onMessage,
  required void Function(String data) onData,
  required void Function() onClosed,
}) => EventSocket(
  url: url,
  token: token,
  onMessage: onMessage,
  onData: onData,
  onClosed: onClosed,
);

/// Le tchat d'équipe tel que le Studio le lit : par l'API du Manager. L'écran
/// (`TeamChatPage`) est celui de l'app.
///
/// Le Studio n'a ni jeton de bot ni appel direct à Discord : pas d'équipe du
/// portail ni de recherche d'utilisateur (les valeurs par défaut de l'hôte,
/// `null`) — le Manager reste le seul à parler à Discord.
class StudioTeamChatHost extends TeamChatHost {
  StudioTeamChatHost(
    this.api, {
    this.userName,
    this.pollInterval = const Duration(seconds: 12),
    TeamEventSocketFactory? socketFactory,
  }) : _socketFactory = socketFactory ?? _webSocket;

  final StudioApi api;

  /// Nom de l'utilisateur connecté, pour ses messages en cours d'envoi.
  final String? userName;

  /// Relecture périodique tant que le canal temps réel n'est pas établi.
  final Duration pollInterval;

  final TeamEventSocketFactory _socketFactory;

  @override
  Future<bool> prepare(String botId) async => true;

  @override
  Future<List<BotCollaborator>> collaborators(String botId) async {
    final json = await api.teamCollaboratorsWire(botId);
    final raw = json['collaborators'];
    return [
      if (raw is List)
        for (final item in raw.whereType<Map>())
          BotCollaborator.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<List<TeamChatMessage>> messages(String botId) async => [
    for (final raw in await api.teamChatWire(botId))
      TeamChatMessage.fromJson(raw),
  ];

  /// Le bloc `my_permissions` de la route d'équipe ; absent = droits inconnus.
  @override
  Future<BotPermissions?> myPermissions(String botId) async {
    final raw = (await api.teamCollaboratorsWire(botId))['my_permissions'];
    return raw is Map
        ? BotPermissions.fromJson(Map<String, dynamic>.from(raw))
        : null;
  }

  @override
  Future<TeamChatMessage?> postMessage(String botId, String content) async =>
      teamChatMessageFromPostResponse(await api.postTeamChat(botId, content));

  @override
  Future<void> upsertCollaborator(
    String botId,
    String userId,
    BotPermissions permissions,
  ) => api.upsertCollaborator(botId, userId, permissions.toJson());

  @override
  Future<void> removeCollaborator(String botId, String userId) =>
      api.removeCollaborator(botId, userId);

  @override
  Future<String> currentUserName() async => userName ?? '';

  /// Le canal temps réel du Manager (WebSocket du navigateur, jeton dans le
  /// sous-protocole). Tant qu'il n'est pas établi — serveur sans le
  /// sous-protocole, proxy qui coupe, hors navigateur —, l'écran est invité à
  /// relire la conversation à intervalle : le tchat reste vivant, plus lentement.
  @override
  Stream<TeamChatEvent> events(String botId) {
    late final StreamController<TeamChatEvent> controller;
    EventSocket? socket;
    Timer? poll;
    Timer? reconnect;
    var live = false;
    var wasDown = false;
    var attempt = 0;
    var closed = false;

    void connect() {
      socket?.close();
      final next = _socketFactory(
        url: api.eventsUrl,
        token: api.freshToken,
        onMessage: () {
          if (closed) return;
          attempt = 0;
          if (!live) {
            live = true;
            // Reconnecté après une coupure : rattraper les messages manqués.
            if (wasDown) controller.add(const TeamChatResyncEvent());
          }
        },
        onData: (data) {
          if (closed) return;
          final event = _decode(data);
          if (event != null) controller.add(event);
        },
        onClosed: () {
          if (closed) return;
          live = false;
          wasDown = true;
          final delay = Duration(seconds: (5 * (1 << attempt)).clamp(5, 60));
          attempt = (attempt + 1).clamp(0, 4);
          reconnect?.cancel();
          reconnect = Timer(delay, () {
            if (!closed) connect();
          });
        },
      );
      socket = next;
      unawaited(next.connect());
    }

    controller = StreamController<TeamChatEvent>(
      onListen: () {
        connect();
        poll = Timer.periodic(pollInterval, (_) {
          if (!live && !closed) controller.add(const TeamChatResyncEvent());
        });
      },
      onCancel: () {
        closed = true;
        poll?.cancel();
        reconnect?.cancel();
        socket?.close();
      },
    );
    return controller.stream;
  }

  /// Un message du canal : un événement d'équipe, ou `null` (instantané,
  /// ping, type inconnu, texte illisible).
  static TeamChatEvent? _decode(String data) {
    try {
      final json = jsonDecode(data);
      if (json is! Map) return null;
      return TeamChatEvent.fromWire(Map<String, dynamic>.from(json));
    } catch (_) {
      return null;
    }
  }
}
