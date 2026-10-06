// L'hôte des écrans « Applications hébergées » côté app : `MainApiClient` (la
// session Manager de l'appareil), les publicités récompensées de la boutique
// mobile, l'achat natif et les bots locaux (`AppManager`) comme source du token
// Discord. Les écrans, eux, vivent dans `bot_creator_ui` (le Studio affiche les
// mêmes).
library;

import 'package:bot_creator/core/analytics/analytics.dart';
import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/platform/run_platform.dart';
import 'package:bot_creator/core/storage/database.dart';
import 'package:bot_creator/features/containers/logic/hosted_app_hosting_actions.dart';
import 'package:bot_creator/features/copilot/presentation/copilot_page.dart';
import 'package:bot_creator/features/subscriptions/logic/subscription_service.dart';
import 'package:bot_creator/features/subscriptions/presentation/hosted_app_subscription_page.dart';
import 'package:bot_creator/features/subscriptions/presentation/subscriptions_hub_page.dart';
import 'package:bot_creator_ui/bot_creator_ui.dart' as ui;
import 'package:flutter/material.dart';

class AppHostedContainersHost extends ui.HostedContainersHost {
  /// [client] : un client déjà prêt (tests, écran parent). Sans lui, la session
  /// Manager stockée sur l'appareil est lue au premier appel.
  // ignore: prefer_initializing_formals
  AppHostedContainersHost({MainApiClient? client}) : _client = client;

  MainApiClient? _client;
  bool _resolved = false;
  String? _ownerId;

  /// Le client du Manager, créé au premier appel. `null` = aucune session.
  Future<MainApiClient?> _resolveClient() async {
    if (_client != null || _resolved) return _client;
    _resolved = true;
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (session != null && !session.isExpired && config.isConfigured) {
        _ownerId = session.userId;
        _client = MainApiClient(
          baseUrl: config.baseUrl,
          accessToken: session.accessToken,
        );
      }
    } catch (_) {}
    return _client;
  }

  Future<MainApiClient> _require() async {
    final client = await _resolveClient();
    if (client == null) {
      throw const ui.HostedApiException('Not signed in.');
    }
    return client;
  }

  @override
  Future<bool> hasSession() async => await _resolveClient() != null;

  @override
  Future<List<ui.ContainerInfo>> listContainers() async =>
      (await _require()).listContainers();

  @override
  Future<ui.HostedAppEligibility> eligibility() async =>
      (await _require()).getHostedAppEligibility();

  @override
  Future<Map<String, dynamic>> containerStatus(String id) async =>
      (await _require()).getContainerStatus(id);

  @override
  Future<String> containerLogs(String id, {int tail = 200}) async =>
      (await _require()).getContainerLogs(id, tail: tail);

  @override
  Future<void> startContainer(String id) async =>
      (await _require()).startContainer(id);

  @override
  Future<void> stopContainer(String id) async =>
      (await _require()).stopContainer(id);

  @override
  Future<void> deleteContainer(String id) async =>
      (await _require()).deleteContainer(id);

  @override
  Future<void> extendContainerTtl(String id, int minutes) async =>
      (await _require()).extendContainerTTL(id, minutes);

  @override
  Future<ui.DiscordBotIdentity> discordIdentity(String id) async {
    final client = await _require();
    try {
      return await client.fetchContainerDiscordIdentity(id);
    } on MainApiClientException catch (error) {
      throw ui.HostedApiException(
        error.message,
        statusCode: error.statusCode,
        code: error.code,
      );
    }
  }

  @override
  Future<void> validateDiscordToken(String botToken) async {
    await (await _require()).validateTurnkeyDiscordToken(botToken);
  }

  @override
  Future<Map<String, dynamic>> deployContainer({
    required String image,
    required int cpuMillis,
    required int memoryMb,
    required int storageGb,
    required Map<String, String> env,
  }) async => (await _require()).deployContainer(
    image: image,
    cpuMillis: cpuMillis,
    memoryMb: memoryMb,
    storageGb: storageGb,
    env: env,
  );

  @override
  Future<List<ui.RegistryCredential>> listRegistryCredentials() async =>
      (await _require()).listRegistryCredentials();

  @override
  Future<ui.RegistryCredential> createRegistryCredential({
    required String label,
    required String registryHost,
    required String username,
    required String password,
  }) async => (await _require()).createRegistryCredential(
    label: label,
    registryHost: registryHost,
    username: username,
    password: password,
  );

  @override
  Future<ui.RegistryCredential> updateRegistryCredential(
    String id, {
    required String label,
    required String registryHost,
    required String username,
    String? password,
  }) async => (await _require()).updateRegistryCredential(
    id,
    label: label,
    registryHost: registryHost,
    username: username,
    password: password,
  );

  @override
  Future<void> deleteRegistryCredential(String id) async =>
      (await _require()).deleteRegistryCredential(id);

  // Le catalogue de modèles est tenu à jour en tâche de fond par
  // `AccountSyncWorker` : l'écran garde le cache (`fetchTurnkeyTemplates` null).

  @override
  Future<Stream<ui.ContainerLiveUpdate>?> containerUpdates() async {
    final client = await _resolveClient();
    if (client == null) return null;
    return client
        .connectGatewayBotEvents()
        .events
        .where((event) => event.container != null)
        .map((event) {
          final container = event.container!;
          return ui.ContainerLiveUpdate(
            containerId: container.containerId,
            state: container.state,
            healthStatus: container.healthStatus,
            expiresAt: container.expiresAt,
          );
        });
  }

  /// Aucune publicité sur poste de travail : le temps d'hébergement y vient du
  /// SOLDE SERVEUR (minutes déjà gagnées sur mobile).
  @override
  bool get canWatchAds => !isDesktopRunPlatform;

  @override
  Future<ui.HostedAppAdTopUpResult?> watchAdAndClaim({
    required String placement,
    String? containerId,
    bool applyToContainer = false,
  }) async {
    final client = await _require();
    return HostedAppHostingActions.watchAdAndClaim(
      client: client,
      ownerId: _ownerId,
      placement: placement,
      containerId: containerId,
      applyToContainer: applyToContainer,
    );
  }

  @override
  ui.HostedUpsellMode get upsellMode {
    if (isDesktopRunPlatform) return ui.HostedUpsellMode.plans;
    return SubscriptionService.supportsNativeBilling
        ? ui.HostedUpsellMode.purchase
        : ui.HostedUpsellMode.none;
  }

  @override
  void openSubscription(BuildContext context) =>
      HostedAppSubscriptionPage.show(context);

  @override
  void openPlans(BuildContext context) => SubscriptionsHubPage.open(context);

  @override
  bool get premiumCloudDisabled => SubscriptionService.premiumCloudDisabled;

  @override
  Future<List<ui.HostedLocalBot>> localBots() async {
    final apps = await AppManager().getAllApps();
    final bots = <ui.HostedLocalBot>[];
    for (final raw in apps) {
      if (raw is! Map) continue;
      final app = Map<String, dynamic>.from(raw);
      final id = app['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      // Une entrée marquée clé en main n'est pas un bot configuré (nettoyée au
      // chargement par AppManager) : elle n'a rien à proposer comme token ici.
      if (AppManager.isTurnkeyAppEntry(app)) continue;
      final full = await AppManager().getApp(id);
      final token = full['token']?.toString() ?? '';
      if (token.isEmpty) continue;
      bots.add(
        ui.HostedLocalBot(
          id: id,
          name: app['name']?.toString() ?? id,
          token: token,
        ),
      );
    }
    return bots;
  }

  @override
  bool get canOpenCopilot => true;

  @override
  void openCopilot(BuildContext context, String containerId, String title) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CopilotPage(
          api: _client,
          botId: 'container:$containerId',
          botName: title,
          location: 'remote',
        ),
      ),
    );
  }

  @override
  Future<void> logBotInvited({
    required String botId,
    required String containerId,
  }) => AppAnalytics.logEvent(
    name: 'invite_bot',
    parameters: <String, Object>{
      'bot_id': botId,
      'container_id': containerId,
      'source': 'turnkey_container',
    },
  );
}
