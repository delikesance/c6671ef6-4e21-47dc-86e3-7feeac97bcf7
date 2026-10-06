/// Contrat entre les écrans « Applications hébergées » (liste, détail, déploiement,
/// identifiants de registre — partagés) et la façon dont chaque client parle au
/// Manager : l'app passe par `MainApiClient` (session locale, publicités
/// récompensées, achat natif), le Studio par `StudioApi`.
///
/// Tout ce que la plateforme ne peut pas faire est une CAPACITÉ à valeur par
/// défaut « non » : l'écran masque alors l'action, exactement comme l'app le
/// fait quand elle n'a pas de publicité ou de boutique.
library;

import 'package:flutter/widgets.dart';

import 'hosted_models.dart';

abstract class HostedContainersHost {
  const HostedContainersHost();

  // ── Session ────────────────────────────────────────────────────────────────

  /// Une session Manager exploitable existe-t-elle ? Faux : la liste dit
  /// « connectez-vous » au lieu d'interroger le serveur.
  Future<bool> hasSession();

  // ── Lectures ───────────────────────────────────────────────────────────────

  /// `GET /containers`.
  Future<List<ContainerInfo>> listContainers();

  /// `GET /containers/eligibility`.
  Future<HostedAppEligibility> eligibility();

  /// `GET /containers/{id}/status` : le statut brut (`state`, `image`,
  /// `health_status`, `expires_at`, `memory_mb`, `cpu_millis`…).
  Future<Map<String, dynamic>> containerStatus(String id);

  /// `GET /containers/{id}/logs?tail=` : le tampon texte des derniers logs.
  Future<String> containerLogs(String id, {int tail = 200});

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> startContainer(String id);

  Future<void> stopContainer(String id);

  Future<void> deleteContainer(String id);

  /// `PATCH /containers/{id}/ttl` : ajoute [minutes] d'hébergement.
  Future<void> extendContainerTtl(String id, int minutes);

  /// `POST /containers/{id}/discord-identity`. Une réponse d'échec du serveur
  /// DOIT être levée en [HostedApiException] (statut et code conservés) : c'est
  /// ce qui distingue « 409 : token révoqué » de « route absente » ou d'une
  /// panne réseau.
  Future<DiscordBotIdentity> discordIdentity(String id);

  /// Validation technique du token Discord (`POST /gateway/turnkey/validate-token`).
  Future<void> validateDiscordToken(String botToken);

  /// `POST /containers/deploy` : rend le corps du serveur (`container_id`…).
  /// Jamais rejoué : chaque appel crée un conteneur facturé.
  Future<Map<String, dynamic>> deployContainer({
    required String image,
    required int cpuMillis,
    required int memoryMb,
    required int storageGb,
    required Map<String, String> env,
  });

  // ── Identifiants de registre privé (côté serveur uniquement) ──────────────

  Future<List<RegistryCredential>> listRegistryCredentials();

  Future<RegistryCredential> createRegistryCredential({
    required String label,
    required String registryHost,
    required String username,
    required String password,
  });

  /// [password] `null` = le mot de passe reste inchangé.
  Future<RegistryCredential> updateRegistryCredential(
    String id, {
    required String label,
    required String registryHost,
    required String username,
    String? password,
  });

  Future<void> deleteRegistryCredential(String id);

  // ── Catalogue de modèles ──────────────────────────────────────────────────

  /// Le catalogue de modèles clé en main servi par le Manager pour [locale]
  /// (`GET /gateway/turnkey/templates`). `null` = l'hôte tient déjà son cache à
  /// jour (l'app le rafraîchit en tâche de fond) : l'écran garde ce qu'il a.
  Future<List<Map<String, dynamic>>?> fetchTurnkeyTemplates(
    String locale,
  ) async => null;

  // ── Temps réel ─────────────────────────────────────────────────────────────

  /// Les mises à jour d'état de conteneur poussées par le Manager
  /// (`container.updated`). `null` = pas de canal : la page ne compte que sur
  /// son sondage de secours.
  Future<Stream<ContainerLiveUpdate>?> containerUpdates() async => null;

  // ── Publicités récompensées ───────────────────────────────────────────────

  /// L'appareil peut-il diffuser une publicité récompensée ? Faux sur le poste
  /// de travail et dans le Studio : le temps d'hébergement y vient du SOLDE
  /// serveur (minutes déjà gagnées sur mobile), et aucune action « regarder une
  /// publicité » n'est proposée.
  bool get canWatchAds => false;

  /// Regarde une publicité puis réclame les minutes (`POST /containers/claim-ad`),
  /// et les applique au conteneur si [applyToContainer]. `null` = abandon sans
  /// erreur. Seulement appelée quand [canWatchAds] est vrai.
  Future<HostedAppAdTopUpResult?> watchAdAndClaim({
    required String placement,
    String? containerId,
    bool applyToContainer = false,
  }) async => throw UnsupportedError('Rewarded ads are not available here.');

  // ── Offres et formules ────────────────────────────────────────────────────

  /// Ce que les cartes d'offre peuvent proposer : achat natif, simple
  /// consultation des formules, ou rien.
  HostedUpsellMode get upsellMode => HostedUpsellMode.none;

  /// Ouvre l'écran d'achat de la formule d'hébergement ([HostedUpsellMode.purchase]).
  void openSubscription(BuildContext context) {}

  /// Ouvre les formules ([HostedUpsellMode.plans]).
  void openPlans(BuildContext context) {}

  /// Le serveur a-t-il coupé l'hébergement cloud sur ce déploiement
  /// (`premium_cloud_enabled: false`) ? Les blocages « pas de minutes / formule »
  /// sont alors expliqués par ce fait, sans promesse d'une publicité ou d'un achat.
  bool get premiumCloudDisabled => false;

  // ── Bots locaux (source du token au déploiement) ──────────────────────────

  /// Les bots configurés sur l'appareil, avec leur token. Vide dans le Studio :
  /// le token se colle à la main.
  Future<List<HostedLocalBot>> localBots() async => const <HostedLocalBot>[];

  // ── Extras de la plateforme ───────────────────────────────────────────────

  /// L'écran des identifiants de registre est-il proposé depuis la liste ?
  /// (Dans l'app il n'a pas de point d'entrée ; le Studio l'expose.)
  bool get showsRegistryCredentials => false;

  /// Un assistant IA est-il proposé sur un conteneur ? Faux : le bouton n'est
  /// pas affiché.
  bool get canOpenCopilot => false;

  /// Ouvre l'assistant IA sur un conteneur (seulement si [canOpenCopilot]).
  void openCopilot(BuildContext context, String containerId, String title) {}

  /// Une invitation du bot a été ouverte (analytique de l'app).
  Future<void> logBotInvited({
    required String botId,
    required String containerId,
  }) async {}
}
