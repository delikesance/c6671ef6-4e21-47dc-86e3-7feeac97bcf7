// Modèles de l'écran « Équipe et tchat » d'un bot, partagés entre l'app et le
// Studio. Le décodage est défensif : ces objets arrivent aussi par le canal
// temps réel, où une exception de parsing ferait tomber tout le flux.
library;

/// Droits d'un collaborateur sur un bot.
///
/// Décision produit : le partage d'un bot est granulaire. Un collaborateur
/// n'obtient que ce que le propriétaire lui a explicitement accordé, à une
/// exception près — voir [canViewChat].
class BotPermissions {
  const BotPermissions({
    this.canEditCommands = false,
    this.canStartStop = false,
    this.canClaimAds = false,
    this.canInvite = false,
    this.canViewChat = true,
  });

  final bool canEditCommands;
  final bool canStartStop;
  final bool canClaimAds;
  final bool canInvite;
  final bool canViewChat;

  /// Absence de clé = refus, SAUF can_view_chat : un serveur d'avant cette
  /// évolution ne renvoie pas le bloc et l'utilisateur doit garder l'accès au tchat.
  ///
  /// Aucun champ n'est lu par un cast qui pourrait lever (`as bool` sur une
  /// valeur inattendue) : un décodage qui jette fait tomber tout le flux
  /// WebSocket, donc tout champ illisible retombe sur le refus.
  factory BotPermissions.fromJson(Map<String, dynamic> json) => BotPermissions(
    canEditCommands: json['can_edit_commands'] == true,
    canStartStop: json['can_start_stop'] == true,
    canClaimAds: json['can_claim_ads'] == true,
    canInvite: json['can_invite'] == true,
    canViewChat: json['can_view_chat'] != false,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'can_edit_commands': canEditCommands,
    'can_start_stop': canStartStop,
    'can_claim_ads': canClaimAds,
    'can_invite': canInvite,
    'can_view_chat': canViewChat,
  };

  BotPermissions copyWith({
    bool? canEditCommands,
    bool? canStartStop,
    bool? canClaimAds,
    bool? canInvite,
    bool? canViewChat,
  }) => BotPermissions(
    canEditCommands: canEditCommands ?? this.canEditCommands,
    canStartStop: canStartStop ?? this.canStartStop,
    canClaimAds: canClaimAds ?? this.canClaimAds,
    canInvite: canInvite ?? this.canInvite,
    canViewChat: canViewChat ?? this.canViewChat,
  );
}

/// Un membre de l'équipe d'un bot : son identité, son rôle et les droits que le
/// propriétaire lui a accordés.
///
/// Le décodage est DÉFENSIF de bout en bout : ces objets arrivent aussi bien par
/// `GET /gateway/bots/{id}/team/collaborators` que par le canal temps réel, où
/// une exception de parsing ferait tomber tout le flux d'événements.
class BotCollaborator {
  const BotCollaborator({
    this.userId = '',
    this.role = 'collaborator',
    this.permissions = const BotPermissions(),
    this.displayName = '',
    this.isOwner = false,
    this.inDiscordTeam = false,
  });

  final String userId;
  final String role;
  final BotPermissions permissions;
  final String displayName;
  final bool isOwner;
  final bool inDiscordTeam;

  factory BotCollaborator.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'];
    var role = (json['role'] ?? '').toString().trim();
    if (role.isEmpty) {
      role = 'collaborator';
    }
    return BotCollaborator(
      userId: _asString(json['user_id']),
      role: role,
      permissions: permissionsRaw is Map
          ? BotPermissions.fromJson(
              Map<String, dynamic>.from(
                permissionsRaw.cast<dynamic, dynamic>(),
              ),
            )
          : const BotPermissions(),
      displayName: _asString(json['display_name']),
      isOwner: json['is_owner'] == true,
      inDiscordTeam: json['in_discord_team'] == true,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'user_id': userId,
    'role': role,
    'permissions': permissions.toJson(),
    'display_name': displayName,
    'is_owner': isOwner,
    'in_discord_team': inDiscordTeam,
  };
}

/// Un message du tchat d'équipe d'un bot, persisté côté serveur.
///
/// [createdAt] ne jette jamais : un horodatage absent ou illisible retombe sur
/// l'époque zéro. Un champ d'affichage ne doit pas faire tomber la conversation.
class TeamChatMessage {
  const TeamChatMessage({
    this.id = 0,
    this.botId,
    this.authorUserId = '',
    this.authorDisplayName = '',
    this.content = '',
    required this.createdAt,
  });

  final int id;

  /// Bot dont le fil porte ce message, quand le serveur le nomme (le même canal
  /// temps réel transporte les messages de tous les bots du compte).
  ///
  /// `null` = non nommé : le serveur ne l'a pas envoyé, ou l'a envoyé d'une
  /// forme illisible. L'appelant doit alors retomber sur son heuristique — c'est
  /// pourquoi l'absence se distingue d'une chaîne vide.
  final String? botId;

  final String authorUserId;
  final String authorDisplayName;
  final String content;
  final DateTime createdAt;

  factory TeamChatMessage.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['created_at'];
    var createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    if (createdRaw != null) {
      final parsed = createdRaw is int
          // Certains serveurs datent en epoch secondes, d'autres en millisecondes :
          // une valeur manifestement en secondes est convertie pour ne pas dater
          // les messages de 1970.
          ? DateTime.fromMillisecondsSinceEpoch(
              createdRaw.abs() < 100000000000 ? createdRaw * 1000 : createdRaw,
            )
          : DateTime.tryParse(createdRaw.toString());
      if (parsed != null) {
        createdAt = parsed.toUtc();
      }
    }
    return TeamChatMessage(
      id: _asInt(json['id']),
      botId: _asOptionalId(json['bot_id']),
      authorUserId: _asString(json['author_user_id']),
      authorDisplayName: _asString(json['author_display_name']),
      content: _asString(json['content']),
      createdAt: createdAt,
    );
  }
}

/// Le message créé que rend `POST …/team/chat` : sous `message` ou `data`, ou à
/// la racine. `null` quand il est vide — il arrivera alors par le temps réel.
TeamChatMessage? teamChatMessageFromPostResponse(
  Map<String, dynamic> response,
) {
  final raw = response['message'] ?? response['data'];
  final map = raw is Map
      ? Map<String, dynamic>.from(raw.cast<dynamic, dynamic>())
      : response;
  final message = TeamChatMessage.fromJson(map);
  return message.content.isEmpty ? null : message;
}

/// Chaîne défensive : `null` devient une chaîne vide, tout le reste passe par
/// `toString()` (un `int` de contenu reste lisible plutôt que de faire jeter).
String _asString(dynamic raw) => raw == null ? '' : raw.toString();

/// Identifiant OPTIONNEL : absent, vide ou d'un type inattendu vaut `null`
/// (« non nommé »), jamais une chaîne vide et jamais une exception — un
/// décodage qui jette ferait tomber tout le flux d'événements du compte.
String? _asOptionalId(dynamic raw) {
  if (raw is! String) return null;
  final trimmed = raw.trim();
  return trimmed.isEmpty ? null : trimmed;
}

/// Entier défensif : un identifiant arrivé en chaîne (certains serveurs JSON
/// encodent les grands entiers ainsi) reste exploitable.
int _asInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}

/// Ce que le canal temps réel dit à l'écran d'équipe d'un bot.
sealed class TeamChatEvent {
  const TeamChatEvent();

  /// Décode un événement du canal `/gateway/bots/events` tel que le serveur
  /// l'envoie (`team.chat.message`, `team.members.updated`). Tout le reste —
  /// type inconnu, forme illisible — vaut `null` : un serveur plus récent peut
  /// ajouter des événements sans casser l'écran.
  static TeamChatEvent? fromWire(Map<String, dynamic> json) {
    switch ((json['type'] ?? '').toString()) {
      case 'team.chat.message':
        final raw = json['team_message'];
        if (raw is! Map) return null;
        return TeamChatMessageEvent(
          TeamChatMessage.fromJson(Map<String, dynamic>.from(raw)),
        );
      case 'team.members.updated':
        final raw = json['team_members'];
        final botId = raw is Map ? (raw['bot_id'] ?? '').toString() : null;
        return TeamMembersChangedEvent(botId);
    }
    return null;
  }
}

/// Un message du tchat vient d'arriver (sur TOUS les appareils de l'équipe, y
/// compris celui qui l'a envoyé).
class TeamChatMessageEvent extends TeamChatEvent {
  const TeamChatMessageEvent(this.message);

  final TeamChatMessage message;
}

/// L'équipe d'un bot a changé (ajout, retrait, droits). [botId] nomme le bot
/// concerné ; `null` ou vide = non nommé, l'écran se rafraîchit par prudence.
class TeamMembersChangedEvent extends TeamChatEvent {
  const TeamMembersChangedEvent(this.botId);

  final String? botId;
}

/// Le canal a (re)démarré, ou ne peut pas garantir la livraison : l'écran doit
/// relire la conversation pour rattraper les messages manqués.
class TeamChatResyncEvent extends TeamChatEvent {
  const TeamChatResyncEvent();
}

/// Pseudonyme et avatar Discord d'un utilisateur, résolus par l'hôte.
class TeamUserProfile {
  const TeamUserProfile({this.name = '', this.avatarId = ''});

  final String name;
  final String avatarId;
}

/// L'équipe officielle du portail développeur Discord d'un bot, en lecture
/// seule : elle appartient à Discord, l'écran ne fait que la montrer.
class TeamPortalInfo {
  const TeamPortalInfo({
    this.ownerId = '',
    this.ownerUsername = '',
    this.ownerAvatar = '',
    this.teamId = '',
    this.teamName = '',
    this.teamOwnerUserId = '',
    this.teamOwnerUsername = '',
    this.teamMembers = const <Map<String, dynamic>>[],
    this.memberIds = const <String>{},
  });

  final String ownerId;
  final String ownerUsername;
  final String ownerAvatar;
  final String teamId;
  final String teamName;
  final String teamOwnerUserId;
  final String teamOwnerUsername;

  /// Membres de l'équipe : `id`, `username`, `avatar`, `role`.
  final List<Map<String, dynamic>> teamMembers;

  /// Tous les identifiants qui comptent comme « dans l'équipe du portail »
  /// (propriétaire, équipe, membres) : sert à prévenir quand un identifiant
  /// qu'on ajoute n'y figure pas.
  final Set<String> memberIds;
}
