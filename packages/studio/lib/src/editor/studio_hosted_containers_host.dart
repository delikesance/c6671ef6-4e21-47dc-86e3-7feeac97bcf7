import 'dart:async';
import 'dart:convert';

import 'package:bot_creator_ui/bot_creator_ui.dart' hide StatusPill;

import '../api/studio_api.dart';
import '../platform/event_socket.dart';
import 'studio_team_chat_host.dart' show TeamEventSocketFactory;

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

/// Les applications hébergées (« bots clé en main ») telles que le Studio les lit :
/// par l'API du Manager, avec la session Discord du Studio. Les écrans
/// (`ContainerListPage`, `ContainerDetailPage`, `ContainerDeployPage`,
/// `RegistryCredentialsPage`) sont ceux de l'app.
///
/// Ce que le Studio ne peut pas faire est une capacité laissée à sa valeur par
/// défaut, et l'écran masque l'action exactement comme l'app le fait :
///
/// * pas de publicité récompensée (`canWatchAds` faux) — le temps d'hébergement
///   vient du solde serveur ;
/// * pas d'achat ni de consultation des formules (`upsellMode` aucun) — la
///   formule se gère depuis l'application ;
/// * pas de bot local : le token Discord se colle à la main (il ne quitte jamais
///   le navigateur que vers le Manager) ;
/// * pas d'assistant IA sur un conteneur.
///
/// Les identifiants de registre privé restent CÔTÉ SERVEUR : le Studio n'en garde
/// rien (ni `localStorage`, ni mémoire au-delà de la liste affichée), et le mot
/// de passe n'est jamais relu.
class StudioHostedContainersHost extends HostedContainersHost {
  StudioHostedContainersHost(this.api, {TeamEventSocketFactory? socketFactory})
    : _socketFactory = socketFactory ?? _webSocket;

  final StudioApi api;
  final TeamEventSocketFactory _socketFactory;

  bool _cloudDisabled = false;
  Future<void>? _runtimeRead;

  /// Lit une fois `premium_cloud_enabled` dans le résumé du runtime : un serveur
  /// qui a coupé l'hébergement cloud explique ainsi ses blocages (comme l'app).
  Future<void> _readRuntime() => _runtimeRead ??= () async {
    try {
      final runtime = await api.runtime();
      final raw =
          runtime['premium_cloud_enabled'] ?? runtime['premiumCloudEnabled'];
      _cloudDisabled = raw == false;
    } catch (_) {
      // Inconnu = on n'affirme rien : l'écran suit alors le verdict d'éligibilité.
    }
  }();

  @override
  bool get premiumCloudDisabled => _cloudDisabled;

  @override
  Future<bool> hasSession() async {
    final token = await api.freshToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<List<ContainerInfo>> listContainers() async {
    final json = await api.containersWire();
    final raw = json['containers'];
    return [
      if (raw is List)
        for (final item in raw.whereType<Map>())
          ContainerInfo.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<HostedAppEligibility> eligibility() async {
    await _readRuntime();
    return HostedAppEligibility.fromJson(await api.containerEligibilityWire());
  }

  @override
  Future<Map<String, dynamic>> containerStatus(String id) =>
      api.containerStatusWire(id);

  @override
  Future<String> containerLogs(String id, {int tail = 200}) =>
      api.containerLogs(id, tail: tail);

  @override
  Future<void> startContainer(String id) => api.startContainer(id);

  @override
  Future<void> stopContainer(String id) => api.stopContainer(id);

  @override
  Future<void> deleteContainer(String id) => api.deleteContainer(id);

  @override
  Future<void> extendContainerTtl(String id, int minutes) =>
      api.extendContainerTtl(id, minutes);

  @override
  Future<DiscordBotIdentity> discordIdentity(String id) async {
    try {
      return DiscordBotIdentity.fromJson(
        await api.containerDiscordIdentityWire(id),
      );
    } on StudioApiException catch (error) {
      throw HostedApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }

  @override
  Future<void> validateDiscordToken(String botToken) =>
      api.validateTurnkeyDiscordToken(botToken);

  @override
  Future<Map<String, dynamic>> deployContainer({
    required String image,
    required int cpuMillis,
    required int memoryMb,
    required int storageGb,
    required Map<String, String> env,
  }) => api.deployContainerWire(
    image: image,
    cpuMillis: cpuMillis,
    memoryMb: memoryMb,
    storageGb: storageGb,
    env: env,
  );

  @override
  Future<List<RegistryCredential>> listRegistryCredentials() async {
    final json = await api.registryCredentialsWire();
    final raw = json['credentials'];
    return [
      if (raw is List)
        for (final item in raw.whereType<Map>())
          RegistryCredential.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  @override
  Future<RegistryCredential> createRegistryCredential({
    required String label,
    required String registryHost,
    required String username,
    required String password,
  }) async => RegistryCredential.fromJson(
    await api.createRegistryCredentialWire(
      label: label,
      registryHost: registryHost,
      username: username,
      password: password,
    ),
  );

  @override
  Future<RegistryCredential> updateRegistryCredential(
    String id, {
    required String label,
    required String registryHost,
    required String username,
    String? password,
  }) async => RegistryCredential.fromJson(
    await api.updateRegistryCredentialWire(
      id,
      label: label,
      registryHost: registryHost,
      username: username,
      password: password,
    ),
  );

  @override
  Future<void> deleteRegistryCredential(String id) =>
      api.deleteRegistryCredential(id);

  /// Pas de tâche de fond dans le navigateur : le catalogue est lu à l'ouverture
  /// de l'écran de déploiement, dans la langue de l'écran.
  @override
  Future<List<Map<String, dynamic>>?> fetchTurnkeyTemplates(String locale) =>
      api.turnkeyTemplatesWire(locale);

  @override
  bool get showsRegistryCredentials => true;

  /// Le canal temps réel du Manager (`/gateway/bots/events`) : le jeton voyage
  /// dans le sous-protocole du WebSocket (un navigateur ne peut pas poser
  /// `Authorization`), jamais dans l'URL. Reconnexion avec retrait progressif ;
  /// le sondage de secours de la page couvre les coupures.
  @override
  Future<Stream<ContainerLiveUpdate>?> containerUpdates() async {
    EventSocket? socket;
    Timer? reconnect;
    var attempt = 0;
    var closed = false;
    late final StreamController<ContainerLiveUpdate> controller;

    void connect() {
      if (closed) return;
      socket?.close();
      final next = _socketFactory(
        url: api.eventsUrl,
        token: api.freshToken,
        onMessage: () => attempt = 0,
        onData: (data) {
          final update = _parseContainerEvent(data);
          if (update != null && !controller.isClosed) controller.add(update);
        },
        onClosed: () {
          if (closed) return;
          final delay = Duration(seconds: (5 * (1 << attempt)).clamp(5, 60));
          attempt = (attempt + 1).clamp(0, 4);
          reconnect?.cancel();
          reconnect = Timer(delay, connect);
        },
      );
      socket = next;
      next.connect();
    }

    controller = StreamController<ContainerLiveUpdate>(
      onListen: connect,
      onCancel: () {
        closed = true;
        reconnect?.cancel();
        socket?.close();
      },
    );
    return controller.stream;
  }
}

/// `container.updated` : `{type, container: {container_id, state, health_status,
/// expires_at}}`. Tout autre événement (bots, équipe, ping) est ignoré.
ContainerLiveUpdate? _parseContainerEvent(String data) {
  try {
    final json = jsonDecode(data);
    if (json is! Map || json['type'] != 'container.updated') return null;
    final raw = json['container'];
    if (raw is! Map) return null;
    final id = (raw['container_id'] ?? raw['containerId'] ?? '').toString();
    if (id.isEmpty) return null;
    final expires = raw['expires_at'] ?? raw['expiresAt'];
    return ContainerLiveUpdate(
      containerId: id,
      state: (raw['state'] ?? '').toString(),
      healthStatus: (raw['health_status'] ?? raw['healthStatus'] ?? '')
          .toString(),
      expiresAt: expires == null
          ? null
          : DateTime.tryParse(expires.toString())?.toUtc(),
    );
  } catch (_) {
    return null;
  }
}
