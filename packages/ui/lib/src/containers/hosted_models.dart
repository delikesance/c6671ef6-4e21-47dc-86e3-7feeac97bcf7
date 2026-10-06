/// Modèles des applications hébergées (conteneurs « clé en main ») : ce que le
/// Manager rend pour `/containers`, `/containers/eligibility`,
/// `/registry-credentials`… Partagés entre l'app (qui les relit via
/// `MainApiClient`) et le Studio (via `StudioApi`) : un seul décodage.
library;

String? _normalize(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Information about a hosted container.
class RegistryCredential {
  const RegistryCredential({
    required this.id,
    required this.label,
    required this.registryHost,
    required this.username,
  });

  final String id;
  final String label;
  final String registryHost;
  final String username;

  factory RegistryCredential.fromJson(Map<String, dynamic> json) {
    return RegistryCredential(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      registryHost: (json['registry_host'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
    );
  }
}

class RegistryAuthInput {
  const RegistryAuthInput({
    required this.username,
    required this.password,
    this.registry,
  });

  final String? registry;
  final String username;
  final String password;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (registry != null && registry!.isNotEmpty) 'registry': registry,
    'username': username,
    'password': password,
  };
}

String detectRegistryHostFromImage(String image) {
  final trimmed = image.trim();
  if (trimmed.isEmpty) return '';
  var first = trimmed;
  final at = trimmed.indexOf('@');
  if (at > 0) first = trimmed.substring(0, at);
  final slash = first.indexOf('/');
  if (slash > 0) {
    final head = first.substring(0, slash);
    if (head.contains('.') || head == 'localhost') {
      return head.toLowerCase();
    }
  }
  return 'docker.io';
}

/// Information about a hosted container.
class ContainerInfo {
  final String id;
  final String ownerId;
  final String swarmServiceId;
  final String image;
  final int cpuMillis;
  final int memoryMb;
  final int memoryUsageBytes;
  final int storageGb;
  final Map<String, String> env;
  final String state;
  final int hostPort;
  final String nodeIp;
  final String? registryCredentialId;
  final String registryHost;
  final String registryUsername;
  final String healthStatus;
  final String statusCode;
  final String statusMessage;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Identifiant d'application Discord du bot que fait tourner ce conteneur,
  /// quand le serveur l'a déjà résolu (`discord_application_id`).
  ///
  /// ABSENT (`null`) pour les conteneurs déployés avant que le serveur ne
  /// mémorise l'identité : l'appelant fait alors résoudre l'identité par le
  /// serveur (`POST /containers/{id}/discord-identity`). C'est l'absence, et
  /// non une valeur vide, qui déclenche cette résolution.
  final String? discordApplicationId;
  final String? discordBotName;
  final String? discordBotAvatar;

  const ContainerInfo({
    required this.id,
    required this.ownerId,
    this.swarmServiceId = '',
    required this.image,
    required this.cpuMillis,
    required this.memoryMb,
    this.memoryUsageBytes = 0,
    required this.storageGb,
    this.env = const <String, String>{},
    required this.state,
    this.hostPort = 0,
    this.nodeIp = '',
    this.registryCredentialId,
    this.registryHost = '',
    this.registryUsername = '',
    this.healthStatus = '',
    this.statusCode = '',
    this.statusMessage = '',
    this.discordApplicationId,
    this.discordBotName,
    this.discordBotAvatar,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ContainerInfo.fromJson(Map<String, dynamic> json) {
    return ContainerInfo(
      id: (json['id'] ?? '').toString(),
      ownerId: (json['owner_id'] ?? '').toString(),
      swarmServiceId: (json['swarm_service_id'] ?? '').toString(),
      image: (json['image'] ?? '').toString(),
      cpuMillis: _parseInt(json['cpu_millis'], 0),
      memoryMb: _parseInt(json['memory_mb'], 0),
      memoryUsageBytes: _parseInt(json['memory_usage_bytes'], 0),
      storageGb: _parseInt(json['storage_gb'], 0),
      env: (json['env'] is Map<String, dynamic>
          ? (json['env'] as Map<String, dynamic>).map(
              (k, v) => MapEntry(k, v.toString()),
            )
          : <String, String>{}),
      state: (json['state'] ?? '').toString(),
      hostPort: _parseInt(json['host_port'], 0),
      nodeIp: (json['node_ip'] ?? '').toString(),
      registryCredentialId: json['registry_credential_id']?.toString(),
      registryHost: (json['registry_host'] ?? '').toString(),
      registryUsername: (json['registry_username'] ?? '').toString(),
      healthStatus: (json['health_status'] ?? '').toString(),
      statusCode: (json['status_code'] ?? '').toString(),
      statusMessage: (json['status_message'] ?? '').toString(),
      discordApplicationId: _parseOptionalId(json['discord_application_id']),
      discordBotName: json['discord_bot_name']?.toString(),
      discordBotAvatar: json['discord_bot_avatar']?.toString(),
      expiresAt: _parseDateTime(json['expires_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  String? get discordBotAvatarUrl {
    final avatar = discordBotAvatar?.trim() ?? '';
    if (avatar.isEmpty) return null;
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return avatar;
    }
    final appId = discordApplicationId?.trim() ?? '';
    if (appId.isNotEmpty) {
      return 'https://cdn.discordapp.com/avatars/$appId/$avatar.png?size=1024';
    }
    return null;
  }

  bool get isRunning => state == 'RUNNING';
  bool get isPending => state == 'PENDING';
  bool get isProvisioning => state == 'PROVISIONING' || state == 'PENDING';
  bool get isStopped => state == 'STOPPED' || state == 'STOPPING';
  bool get isFailed => state == 'FAILED';
  bool get isTerminal => isStopped || isFailed;
  bool get usesPrivateRegistry =>
      registryHost.isNotEmpty || registryUsername.isNotEmpty;

  static int parseInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic v, int fallback) => parseInt(v, fallback);

  /// Identifiant technique optionnel : `null` quand le serveur ne le renvoie
  /// pas, jamais une chaîne vide (voir [ContainerInfo.discordApplicationId]).
  static String? _parseOptionalId(dynamic v) {
    final value = v?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static DateTime _parseDateTime(dynamic v) {
    if (v is String) return DateTime.tryParse(v) ?? DateTime(0);
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    return DateTime(0);
  }
}

/// Identité Discord du bot que fait tourner un conteneur, telle que le serveur
/// la résout (`POST /containers/{id}/discord-identity`) : de quoi l'inviter
/// dans un serveur, `invite_url` étant prête à ouvrir.
class DiscordBotIdentity {
  const DiscordBotIdentity({
    required this.botId,
    this.username = '',
    this.avatar = '',
    this.inviteUrl = '',
  });

  /// ID Discord du bot (le `client_id` de l'URL d'invitation).
  final String botId;

  final String username;
  final String avatar;

  /// URL d'invitation composée par le serveur ; vide s'il ne l'a pas fournie.
  final String inviteUrl;

  factory DiscordBotIdentity.fromJson(Map<String, dynamic> json) {
    // Certaines routes enveloppent la charge utile sous `data` : on accepte les
    // deux formes plutôt que de rendre une identité vide sur une réponse saine.
    final nested = json['data'];
    final source = nested is Map ? Map<String, dynamic>.from(nested) : json;
    return DiscordBotIdentity(
      botId: (source['bot_id'] ?? '').toString().trim(),
      username: (source['username'] ?? '').toString(),
      avatar: (source['avatar'] ?? '').toString(),
      inviteUrl: (source['invite_url'] ?? '').toString().trim(),
    );
  }
}

class HostedAppEligibility {
  const HostedAppEligibility({
    required this.premium,
    required this.hostingMinutesBalance,
    required this.activeContainers,
    required this.canDeploy,
    required this.maxContainers,
    required this.adRewardMinutes,
    this.deployBlockedReason,
    this.allowTurnkey = true,
    this.planTierCode,
    this.hostingExpiresAt,
    this.hostingPermanent = false,
  });

  final bool premium;
  final int hostingMinutesBalance;
  final int activeContainers;
  final bool canDeploy;

  /// Plafond de conteneurs, fixé par la formule du compte côté serveur (elle
  /// prime sur l'abonnement store) : c'est exactement le chiffre appliqué au
  /// démarrage, donc celui que l'écran doit montrer.
  final int maxContainers;
  final int adRewardMinutes;

  /// La formule inclut-elle le clé en main / les applications hébergées ?
  final bool allowTurnkey;

  /// Code de la formule servie par le serveur (ex. `FREE`, `STARTER`, `PRO`).
  final String? planTierCode;

  /// Fin de la couverture hébergement, quand le serveur la connaît (échéance d'un
  /// abonnement ou du dernier octroi qui couvre).
  final DateTime? hostingExpiresAt;

  /// Vrai seulement quand le serveur dit que la couverture n'a PAS d'échéance
  /// (un octroi permanent). Les deux champs sont nuls/faux quand l'information
  /// manque : le client ne doit alors rien affirmer sur la durée.
  final bool hostingPermanent;

  /// `container_limit` | `no_minutes` | `plan_not_included` | null when
  /// [canDeploy] is true.
  final String? deployBlockedReason;

  bool get isBlockedByContainerLimit =>
      deployBlockedReason == 'container_limit';
  bool get isBlockedByNoMinutes => deployBlockedReason == 'no_minutes';
  bool get isBlockedByPlan => deployBlockedReason == 'plan_not_included';

  factory HostedAppEligibility.fromJson(Map<String, dynamic> json) {
    return HostedAppEligibility(
      premium: json['premium'] == true,
      hostingMinutesBalance: ContainerInfo.parseInt(
        json['hosting_minutes_balance'],
        0,
      ),
      activeContainers: ContainerInfo.parseInt(json['active_containers'], 0),
      canDeploy: json['can_deploy'] == true,
      maxContainers: ContainerInfo.parseInt(json['max_containers'], 1),
      adRewardMinutes: ContainerInfo.parseInt(json['ad_reward_minutes'], 60),
      deployBlockedReason: _normalize(
        json['deploy_blocked_reason']?.toString(),
      ),
      allowTurnkey: json['allow_turnkey'] != false,
      planTierCode: _normalize(json['plan_tier_code']?.toString()),
      hostingExpiresAt: DateTime.tryParse(
        json['hosting_expires_at']?.toString() ?? '',
      )?.toUtc(),
      hostingPermanent: json['hosting_permanent'] == true,
    );
  }
}

class HostedAppClaimAdResult {
  const HostedAppClaimAdResult({
    required this.grantedMinutes,
    required this.hostingMinutesBalance,
  });

  final int grantedMinutes;
  final int hostingMinutesBalance;

  factory HostedAppClaimAdResult.fromJson(Map<String, dynamic> json) {
    return HostedAppClaimAdResult(
      grantedMinutes: ContainerInfo.parseInt(json['granted_minutes'], 0),
      hostingMinutesBalance: ContainerInfo.parseInt(
        json['hosting_minutes_balance'],
        0,
      ),
    );
  }
}

/// Échec d'un appel au Manager, tel que les écrans partagés le lisent : de quoi
/// distinguer « le serveur a répondu (409, 404 avec code…) » d'une panne réseau,
/// sans connaître le client de l'hôte (`MainApiClientException` côté app,
/// `StudioApiException` côté Studio).
class HostedApiException implements Exception {
  const HostedApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => statusCode == null ? message : '[$statusCode] $message';
}

/// Résultat d'une publicité récompensée regardée pour du temps d'hébergement.
class HostedAppAdTopUpResult {
  const HostedAppAdTopUpResult({
    required this.grantedMinutes,
    required this.hostingMinutesBalance,
    this.appliedToContainer = false,
  });

  final int grantedMinutes;
  final int hostingMinutesBalance;
  final bool appliedToContainer;
}

/// État d'une app hébergée poussé par le canal temps réel
/// (`container.updated`) : remplace le sondage du statut.
class ContainerLiveUpdate {
  const ContainerLiveUpdate({
    required this.containerId,
    this.state = '',
    this.healthStatus = '',
    this.expiresAt,
  });

  final String containerId;
  final String state;
  final String healthStatus;
  final DateTime? expiresAt;
}

/// Un bot configuré sur l'appareil, proposé comme source du token Discord au
/// déploiement. Le Studio n'en a aucun : les tokens restent côté serveur.
class HostedLocalBot {
  const HostedLocalBot({
    required this.id,
    required this.name,
    required this.token,
  });

  final String id;
  final String name;
  final String token;
}

/// Ce que la carte d'offre d'hébergement a le droit de proposer.
enum HostedUpsellMode {
  /// Rien : la plateforme n'a aucun moyen d'achat ni de consultation (Studio).
  none,

  /// Achat natif de la formule d'hébergement (mobile avec boutique).
  purchase,

  /// Consultation des formules seulement (poste de travail : pas de boutique
  /// native, mais les offres restent lisibles).
  plans,
}
