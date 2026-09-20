import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_session_restore.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/runner_client.dart';
import 'package:bot_creator/core/network/runner_settings.dart';
import 'package:bot_creator/core/storage/runtime_preferences.dart';
import 'package:bot_creator/features/bot_editor/logic/runtime_engine.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;

class ResolvedRemoteRuntime {
  const ResolvedRemoteRuntime({
    required this.source,
    this.client,
    this.detailLabel,
    this.unavailableReason,
  });

  final RemoteRuntimeSource source;
  final RemoteRuntimeClient? client;
  final String? detailLabel;
  final String? unavailableReason;

  bool get isLocal => source == RemoteRuntimeSource.local;

  bool get isRemote => client != null;

  bool get isManager => source == RemoteRuntimeSource.manager;

  bool get isRunner => source == RemoteRuntimeSource.runner;

  bool get blocksLocalFallback =>
      source == RemoteRuntimeSource.manager && client == null;
}

String _runtimeCopy({required String fr, required String en}) {
  final lang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
  return lang.startsWith('fr') ? fr : en;
}

Future<ResolvedRemoteRuntime> resolveRemoteRuntime({
  required bool supportsManagerRuntime,
  String? botId,
  Duration getTimeout = const Duration(seconds: 30),
  Duration postTimeout = const Duration(seconds: 90),
  RemoteRuntimeSource? forcedSource,
}) async {
  // Choix EXPLICITE de l'utilisateur (pop-up de démarrage) : il prime sur
  // l'association du bot. C'est ce qui rend vraie la promesse de l'écran — « en
  // local » démarre en local même si le bot est associé au manager, et « sur le
  // serveur » vise le manager même sans association. Sans ce passage, la pop-up
  // serait purement décorative et le bot repartirait là où l'association décide.
  if (forcedSource == RemoteRuntimeSource.local) {
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }
  if (forcedSource == RemoteRuntimeSource.manager) {
    final forcedConfig = await MainApiSettingsStore.loadConfig();
    final forcedSession = await MainApiSettingsStore.loadSession();
    if (forcedConfig.isConfigured &&
        forcedSession != null &&
        !forcedSession.isExpired) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.manager,
        client: MainApiClient(
          baseUrl: forcedConfig.baseUrl,
          accessToken: forcedSession.accessToken,
          timeout: postTimeout,
        ),
        detailLabel: forcedConfig.baseUrl,
      );
    }
    // Session perdue entre la question et la réponse : on retombe en local plutôt
    // que d'échouer — la pop-up n'a proposé ce choix qu'avec une session valide.
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  if (kIsWeb) {
    final runnerConfig = await RunnerSettings.getConfig();
    if (runnerConfig != null) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.runner,
        client: runnerConfig.createClient(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
        detailLabel: runnerConfig.name ?? runnerConfig.url,
      );
    }
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  final platform = defaultTargetPlatform;
  final isIOS = platform == TargetPlatform.iOS;
  final isAndroid = platform == TargetPlatform.android;
  final isDesktop =
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;
  final effectiveSupportsManagerRuntime = supportsManagerRuntime;

  // Le poste de travail n'est plus exclu du manager : la plateforme ne verrouille
  // plus l'ACCÈS AUX DONNÉES du compte (solde, bots, conteneurs clé en main, snapshot).
  // Ce qui décide d'un PILOTAGE à distance, c'est l'association du bot
  // (`RunnerSettings.getAssociatedRunnerId(botId) == 'manager'`), traitée ci-dessous —
  // pas l'OS. Un bot non associé reste donc exécuté en local (runner embarqué).

  // 1. Check for explicit bot association first (overrides global preferences)
  if (botId != null) {
    final associatedId = RunnerSettings.getAssociatedRunnerId(botId);
    if (associatedId == 'manager' && effectiveSupportsManagerRuntime) {
      final mainApiConfig = await MainApiSettingsStore.loadConfig();
      final mainApiSession = await MainApiSettingsStore.loadSession();

      if (mainApiConfig.isConfigured &&
          mainApiSession != null &&
          !mainApiSession.isExpired) {
        return ResolvedRemoteRuntime(
          source: RemoteRuntimeSource.manager,
          client: MainApiClient(
            baseUrl: mainApiConfig.baseUrl,
            accessToken: mainApiSession.accessToken,
            timeout: postTimeout,
          ),
          detailLabel: mainApiConfig.baseUrl,
        );
      }
    } else if (associatedId != null && associatedId != 'local') {
      final runners = await RunnerSettings.getRunners();
      final match = runners.where((r) => r.id == associatedId);
      if (match.isNotEmpty) {
        final config = match.first;
        var useAssociation = true;
        if (isDesktop) {
          final engine = await getBotRuntimeEngine(botId);
          if (engine == runtimeEngineJavascript &&
              !RunnerSettings.supportsJavascriptRunner(config)) {
            useAssociation = false;
          }
        }
        if (useAssociation) {
          final hydrated = await RunnerSettings.hydrateRunnerConnectionConfig(
            config,
          );
          if (hydrated == null) {
            return const ResolvedRemoteRuntime(
              source: RemoteRuntimeSource.local,
            );
          }
          return ResolvedRemoteRuntime(
            source: RemoteRuntimeSource.runner,
            client: hydrated.createClient(
              getTimeout: getTimeout,
              postTimeout: postTimeout,
            ),
            detailLabel: hydrated.name ?? hydrated.url,
          );
        }
      }
    }
  }

  if (!effectiveSupportsManagerRuntime) {
    final runnerConfig = botId != null
        ? await RunnerSettings.resolveConfigForBot(botId)
        : await RunnerSettings.getConfig();
    if (runnerConfig != null) {
      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.runner,
        client: runnerConfig.createClient(
          getTimeout: getTimeout,
          postTimeout: postTimeout,
        ),
        detailLabel: runnerConfig.name ?? runnerConfig.url,
      );
    }
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  if (isAndroid && await RuntimePreferences.isMobileLocalHostingEnabled()) {
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  final mainApiConfig = await MainApiSettingsStore.loadConfig();
  final mainApiSession = await MainApiSettingsStore.loadSession();

  if (mainApiConfig.isConfigured) {
    final session = await loadMainApiSession();

    if (session != null && !session.isExpired) {
      // Sur un poste de travail, une résolution PAR BOT qui n'a pas été associée au
      // manager (branche 1 ci-dessus, non prise) reste LOCALE : sinon un bot pensé pour
      // le runner embarqué partirait sur les serveurs Bot Creator simplement parce
      // qu'un compte est connecté. La résolution GLOBALE (`botId == null` : compte,
      // solde, conteneurs, snapshot, état d'exécution) et toutes les plateformes
      // mobiles gardent le manager comme source de vérité.
      if (botId == null || !isDesktop) {
        return ResolvedRemoteRuntime(
          source: RemoteRuntimeSource.manager,
          client: MainApiClient(
            baseUrl: mainApiConfig.baseUrl,
            accessToken: session.accessToken,
            timeout: postTimeout,
          ),
          detailLabel: mainApiConfig.baseUrl,
        );
      }
    }

    // Poste de travail sans session exploitable : le manager ne doit pas devenir une
    // prison. Un bot SANS association au manager continue de tourner en LOCAL (runner
    // embarqué), donc on laisse la résolution descendre vers le repli runner/local au
    // lieu de bloquer le repli local comme sur mobile. Sur mobile le comportement est
    // inchangé : sans compte connecté, c'est le manager (à reconnecter) qui porte le
    // message, et le repli local est explicitement interdit.
    if (!isDesktop) {
      final unavailableReason = mainApiSession == null
          ? (isIOS
                ? _runtimeCopy(
                    fr: 'Le mode local n\'est pas pris en charge sur iOS. Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                    en: 'Local mode is not supported on iOS. Sign in to Bot Creator in Settings before starting this bot.',
                  )
                : _runtimeCopy(
                    fr: 'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                    en: 'Sign in to Bot Creator in Settings before starting this bot.',
                  ))
          : _runtimeCopy(
              fr: 'Votre session Bot Creator a expire. Reconnectez-vous dans les parametres pour demarrer ce bot.',
              en: 'Your Bot Creator session expired. Sign in again in Settings to start this bot.',
            );

      return ResolvedRemoteRuntime(
        source: RemoteRuntimeSource.manager,
        detailLabel: mainApiConfig.baseUrl,
        unavailableReason: unavailableReason,
      );
    }
  }

  if (isIOS) {
    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.manager,
      unavailableReason: _runtimeCopy(
        fr: 'Le mode local n\'est pas pris en charge sur iOS. Configurez Bot Creator pour demarrer ce bot.',
        en: 'Local mode is not supported on iOS. Configure Bot Creator to start this bot.',
      ),
    );
  }

  final runnerConfig = botId != null
      ? await RunnerSettings.resolveConfigForBot(botId)
      : await RunnerSettings.getConfig();
  if (runnerConfig != null) {
    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.runner,
      client: runnerConfig.createClient(
        getTimeout: getTimeout,
        postTimeout: postTimeout,
      ),
      detailLabel: runnerConfig.name ?? runnerConfig.url,
    );
  }

  return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
}

Future<String> describeManagerRuntimeFailure(
  MainApiClient client,
  Object error,
) async {
  bool isInvalidBotId(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('invalid bot_id') ||
        normalized.contains('invalid bot id') ||
        normalized.contains('invalid_bot_id');
  }

  final originalError = error.toString();

  // La formule du compte prime : inutile d'interroger le diagnostic du runner,
  // le refus vient du plan et l'offre est la seule issue.
  if (planLimitRefusalFromError(error) != null) {
    return _runtimeCopy(
      fr: 'Votre formule ne permet pas ce demarrage. Consultez les offres pour changer de formule.',
      en: 'Your plan does not allow this start. Check the plans to upgrade your formula.',
    );
  }

  if (isInvalidBotId(originalError)) {
    return _runtimeCopy(
      fr: 'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Erreur initiale : $error',
      en: 'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Original error: $error',
    );
  }

  try {
    final info = await client.getRunnerInfo();
    final deployed = info['deployed'] == true;
    final runner = (info['runner'] is Map)
        ? Map<String, dynamic>.from(info['runner'] as Map)
        : const <String, dynamic>{};
    final latestDeployJob = (info['latest_deploy_job'] is Map)
        ? Map<String, dynamic>.from(info['latest_deploy_job'] as Map)
        : const <String, dynamic>{};

    final jobStatus = (latestDeployJob['status'] ?? '').toString().trim();
    final jobError = (latestDeployJob['error'] ?? '').toString().trim();
    final runnerState = (runner['state'] ?? '').toString().trim();
    final healthStatus = (runner['health_status'] ?? '').toString().trim();

    if (isInvalidBotId(jobError)) {
      return _runtimeCopy(
        fr: 'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Details : $jobError',
        en: 'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Details: $jobError',
      );
    }

    if (!deployed) {
      return _runtimeCopy(
        fr: 'Les serveurs Bot Creator ne sont pas encore prets pour ce bot. Erreur initiale : $error',
        en: 'Bot Creator servers are not ready for this bot yet. Original error: $error',
      );
    }
    if (jobStatus == 'QUEUED' || jobStatus == 'RUNNING') {
      return _runtimeCopy(
        fr: 'Le demarrage sur les serveurs Bot Creator est encore en cours ($jobStatus). Le traitement peut etre en attente ou toujours en cours. Erreur initiale : $error',
        en: 'Bot Creator server startup is still in progress ($jobStatus). Processing may still be queued or running. Original error: $error',
      );
    }
    if (jobStatus == 'FAILED') {
      final suffix = jobError.isEmpty ? '' : ' Details: $jobError';
      return _runtimeCopy(
        fr: 'Le demarrage sur les serveurs Bot Creator a echoue.$suffix Erreur initiale : $error',
        en: 'Bot Creator server startup failed.$suffix Original error: $error',
      );
    }
    if (healthStatus.toLowerCase() == 'unreachable' ||
        runnerState.toUpperCase() == 'DEGRADED') {
      return _runtimeCopy(
        fr: 'Les serveurs Bot Creator sont temporairement injoignables. Erreur initiale : $error',
        en: 'Bot Creator servers are temporarily unreachable. Original error: $error',
      );
    }
  } catch (_) {
    // Fall back to the original error when the diagnostic endpoint is unavailable.
  }
  return _runtimeCopy(
    fr: 'La requete vers les serveurs Bot Creator a echoue : $error',
    en: 'Request to Bot Creator servers failed: $error',
  );
}

bool isPendingFreeRuntimeCreditError(Object error) {
  final normalized = error.toString().toLowerCase();
  return normalized.contains('bot_free_time_required') ||
      normalized.contains('free runtime credits before start');
}

/// Refus de démarrage dû à la formule du compte (403 du manager).
///
/// Le serveur est seul juge des quotas : quand il refuse, l'écran doit proposer
/// l'offre plutôt qu'afficher un message technique.
enum PlanLimitRefusal {
  excludesOwnBots,
  botQuotaReached,
  excludesTurnkey,
  turnkeyQuotaReached,
}

/// Détecte un refus lié à la formule depuis l'erreur renvoyée par le manager.
///
/// On matche le message servi par l'API (que l'application remonte telle quelle)
/// **et** les codes d'erreur, au cas où le code serait renvoyé à la place.
PlanLimitRefusal? planLimitRefusalFromError(Object error) {
  final normalized = error.toString().toLowerCase();
  bool has(List<String> needles) => needles.any(normalized.contains);

  if (has(const ['does not include personal bots', 'own_bots_not_allowed'])) {
    return PlanLimitRefusal.excludesOwnBots;
  }
  if (has(const ['personal bot limit reached', 'bot_quota_reached'])) {
    return PlanLimitRefusal.botQuotaReached;
  }
  if (has(const ['does not include turnkey apps', 'turnkey_not_allowed'])) {
    return PlanLimitRefusal.excludesTurnkey;
  }
  if (has(const ['turnkey app limit reached', 'turnkey_quota_reached'])) {
    return PlanLimitRefusal.turnkeyQuotaReached;
  }
  return null;
}

bool isPendingManagerRunnerError(Object error) {
  final normalized = error.toString().toLowerCase();
  return normalized.contains('runner_not_deployed') ||
      normalized.contains('runner is not deployed') ||
      normalized.contains('runner_unreachable') ||
      normalized.contains('runner is unreachable');
}

Future<void> startManagerBotWithCreditRetry({
  required MainApiClient client,
  required String botId,
  String? botName,
  Duration timeout = const Duration(seconds: 15),
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);

  while (true) {
    try {
      await client.startBot(botId, botName: botName);
      return;
    } catch (error) {
      if (!isPendingFreeRuntimeCreditError(error) &&
              !isPendingManagerRunnerError(error) ||
          DateTime.now().isAfter(deadline)) {
        rethrow;
      }
      await Future<void>.delayed(retryDelay);
    }
  }
}
