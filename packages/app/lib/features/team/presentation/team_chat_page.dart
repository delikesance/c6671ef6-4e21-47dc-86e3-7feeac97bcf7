// L'écran « Équipe et tchat » d'un bot vit dans `bot_creator_ui` (le Studio
// affiche le même). Ce fichier n'en garde que l'adaptateur de l'app :
// `MainApiClient` pour le serveur et le canal temps réel du compte, et le jeton
// local du bot (`appManager`) pour lire l'équipe du portail Discord et résoudre
// les pseudonymes.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bot_creator/core/network/gateway_bot_events.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/main.dart' show appManager;
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class TeamChatPage extends StatelessWidget {
  const TeamChatPage({
    super.key,
    required this.botId,
    this.client,
    this.portalLookup,
  });

  final String botId;

  /// Client injectable (tests) : par défaut la page résout le runtime commun
  /// ([resolveRemoteRuntime]), comme les autres onglets.
  final MainApiClient? client;

  /// Lecture de l'équipe du portail Discord, injectable (tests). Par défaut
  /// [getDiscordApplicationOwnerMetadata] — la seule source de vérité du
  /// portail, l'app ne réimplémente aucun appel Discord.
  final Future<DiscordApplicationOwnerMetadata?> Function(String botToken)?
  portalLookup;

  @override
  Widget build(BuildContext context) => ui.TeamChatPage(
    botId: botId,
    host: AppTeamChatHost(client: client, portalLookup: portalLookup),
  );
}

/// Le tchat d'équipe tel que l'app le lit : par `MainApiClient`, avec le canal
/// d'événements du compte pour le temps réel.
class AppTeamChatHost extends ui.TeamChatHost {
  AppTeamChatHost({this.client, this.portalLookup});

  final MainApiClient? client;
  final Future<DiscordApplicationOwnerMetadata?> Function(String botToken)?
  portalLookup;

  MainApiClient? _client;

  /// Client du runtime courant : le tchat d'équipe est une donnée du COMPTE
  /// (partagée entre appareils), donc il n'a de sens que côté manager.
  @override
  Future<bool> prepare(String botId) async {
    _client = await _resolveClient(botId);
    return _client != null;
  }

  Future<MainApiClient?> _resolveClient(String botId) async {
    if (client != null) return client;
    final remoteRuntime = await resolveRemoteRuntime(
      supportsManagerRuntime: supportsManagerRuntime,
      botId: botId,
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 30),
    );
    final resolved = remoteRuntime.client;
    return resolved is MainApiClient ? resolved : null;
  }

  MainApiClient get _api {
    final api = _client;
    if (api == null) throw StateError('TeamChatHost.prepare was not awaited');
    return api;
  }

  @override
  Future<List<ui.BotCollaborator>> collaborators(String botId) async => [
    for (final raw in await _api.listTeamCollaborators(botId))
      ui.BotCollaborator.fromJson(raw),
  ];

  @override
  Future<List<ui.TeamChatMessage>> messages(String botId) async => [
    for (final raw in await _api.listTeamChatMessages(botId))
      ui.TeamChatMessage.fromJson(raw),
  ];

  @override
  Future<ui.BotPermissions?> myPermissions(String botId) async {
    final raw = await _api.fetchMyTeamPermissions(botId);
    return raw == null ? null : ui.BotPermissions.fromJson(raw);
  }

  @override
  Future<ui.TeamChatMessage?> postMessage(String botId, String content) async =>
      ui.teamChatMessageFromPostResponse(
        await _api.sendTeamChatMessage(botId, content),
      );

  @override
  Future<void> upsertCollaborator(
    String botId,
    String userId,
    ui.BotPermissions permissions,
  ) => _api.upsertTeamCollaborator(botId, userId, permissions.toJson());

  @override
  Future<void> removeCollaborator(String botId, String userId) =>
      _api.removeTeamCollaborator(botId, userId);

  /// Le canal d'événements du compte ([GatewayBotEventsSession]) : un message ou
  /// un changement de droits apparaît sans rechargement et sans sondage. À la
  /// reconnexion, l'écran relit la conversation pour rattraper les messages
  /// manqués.
  @override
  Stream<ui.TeamChatEvent> events(String botId) {
    final session = _api.connectGatewayBotEvents();
    StreamSubscription<GatewayBotEvent>? events;
    StreamSubscription<bool>? connection;
    late final StreamController<ui.TeamChatEvent> controller;
    controller = StreamController<ui.TeamChatEvent>(
      sync: true,
      onListen: () {
        events = session.events.listen((event) {
          switch (event.type) {
            case GatewayBotEventType.teamChatMessage:
              final message = event.teamMessage;
              if (message != null) {
                controller.add(ui.TeamChatMessageEvent(message));
              }
            case GatewayBotEventType.teamMembersUpdated:
              controller.add(
                ui.TeamMembersChangedEvent(event.teamMembersBotId),
              );
            default:
              break;
          }
        });
        connection = session.connectionChanges.listen((connected) {
          if (connected) controller.add(const ui.TeamChatResyncEvent());
        });
      },
      onCancel: () async {
        await events?.cancel();
        await connection?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<String> currentUserName() async {
    final session = await MainApiSettingsStore.loadSession();
    return session?.username ?? '';
  }

  @override
  Future<ui.TeamPortalInfo?> portalTeam(String botId) async {
    final token = await _botToken(botId);
    if (token.isEmpty) return null;
    final lookup = portalLookup ?? getDiscordApplicationOwnerMetadata;
    final metadata = await lookup(token);
    if (metadata == null) return null;
    return ui.TeamPortalInfo(
      ownerId: metadata.ownerId,
      ownerUsername: metadata.ownerUsername,
      ownerAvatar: metadata.ownerAvatar,
      teamId: metadata.teamId,
      teamName: metadata.teamName,
      teamOwnerUserId: metadata.teamOwnerUserId,
      teamOwnerUsername: metadata.teamOwnerUsername,
      teamMembers: metadata.teamMembersInfo,
      memberIds: metadata.ownerCandidateIds.toSet(),
    );
  }

  @override
  Future<ui.TeamUserProfile?> lookupUser(String botId, String userId) async {
    final token = await _botToken(botId);
    if (token.isEmpty) return null;
    try {
      final http = HttpClient();
      final request = await http.getUrl(
        Uri.parse('https://discord.com/api/v10/users/$userId'),
      );
      request.headers.set(HttpHeaders.authorizationHeader, 'Bot $token');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      final data = jsonDecode(await utf8.decodeStream(response));
      if (data is! Map) return null;
      return ui.TeamUserProfile(
        name: (data['global_name'] ?? data['username'] ?? '').toString(),
        avatarId: (data['avatar'] ?? '').toString(),
      );
    } catch (_) {
      // Ignoré si réseau indisponible
      return null;
    }
  }

  /// Jeton du bot, lu exactement comme les autres écrans (stockage local du bot,
  /// jamais journalisé).
  Future<String> _botToken(String botId) async {
    try {
      final app = await appManager.getApp(botId);
      return (app['token'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }
}
