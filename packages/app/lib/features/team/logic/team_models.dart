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
    this.authorUserId = '',
    this.authorDisplayName = '',
    this.content = '',
    required this.createdAt,
  });

  final int id;
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
      authorUserId: _asString(json['author_user_id']),
      authorDisplayName: _asString(json['author_display_name']),
      content: _asString(json['content']),
      createdAt: createdAt,
    );
  }
}

/// Chaîne défensive : `null` devient une chaîne vide, tout le reste passe par
/// `toString()` (un `int` de contenu reste lisible plutôt que de faire jeter).
String _asString(dynamic raw) => raw == null ? '' : raw.toString();

/// Entier défensif : un identifiant arrivé en chaîne (certains serveurs JSON
/// encodent les grands entiers ainsi) reste exploitable.
int _asInt(dynamic raw) {
  if (raw == null) return 0;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  return int.tryParse(raw.toString()) ?? 0;
}
