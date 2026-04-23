import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/runner_client.dart';
import 'package:bot_creator/utils/runner_settings.dart';
import 'package:bot_creator/utils/runtime_preferences.dart';
import 'package:bot_creator/utils/i18n.dart';
import 'package:flutter/foundation.dart';

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
  return AppStrings.currentLocale == AppLocale.fr ? fr : en;
}

Future<ResolvedRemoteRuntime> resolveRemoteRuntime({
  required bool supportsManagerRuntime,
  Duration getTimeout = const Duration(seconds: 30),
  Duration postTimeout = const Duration(seconds: 90),
}) async {
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

  if (!supportsManagerRuntime) {
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

  if (isAndroid && await RuntimePreferences.isMobileLocalHostingEnabled()) {
    return const ResolvedRemoteRuntime(source: RemoteRuntimeSource.local);
  }

  final mainApiConfig = await MainApiSettingsStore.loadConfig();
  final mainApiSession = await MainApiSettingsStore.loadSession();

  final isDesktop =
      platform == TargetPlatform.windows ||
      platform == TargetPlatform.linux ||
      platform == TargetPlatform.macOS;

  if (mainApiConfig.isConfigured && !isDesktop) {
    if (mainApiSession != null && !mainApiSession.isExpired) {
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

    final unavailableReason =
        mainApiSession == null
            ? (isIOS
                ? _runtimeCopy(
                  fr:
                      'Le mode local n\'est pas pris en charge sur iOS. Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en:
                      'Local mode is not supported on iOS. Sign in to Bot Creator in Settings before starting this bot.',
                )
                : _runtimeCopy(
                  fr:
                      'Connectez-vous a Bot Creator dans les parametres avant de demarrer ce bot.',
                  en:
                      'Sign in to Bot Creator in Settings before starting this bot.',
                ))
            : _runtimeCopy(
              fr:
                  'Votre session Bot Creator a expire. Reconnectez-vous dans les parametres pour demarrer ce bot.',
              en:
                  'Your Bot Creator session expired. Sign in again in Settings to start this bot.',
            );

    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.manager,
      detailLabel: mainApiConfig.baseUrl,
      unavailableReason: unavailableReason,
    );
  }

  if (isIOS) {
    return ResolvedRemoteRuntime(
      source: RemoteRuntimeSource.manager,
      unavailableReason: _runtimeCopy(
        fr:
            'Le mode local n\'est pas pris en charge sur iOS. Configurez Bot Creator pour demarrer ce bot.',
        en:
            'Local mode is not supported on iOS. Configure Bot Creator to start this bot.',
      ),
    );
  }

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
  if (isInvalidBotId(originalError)) {
    return _runtimeCopy(
      fr:
          'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Erreur initiale : $error',
      en:
          'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Original error: $error',
    );
  }

  try {
    final info = await client.getRunnerInfo();
    final deployed = info['deployed'] == true;
    final runner =
        (info['runner'] is Map)
            ? Map<String, dynamic>.from(info['runner'] as Map)
            : const <String, dynamic>{};
    final latestDeployJob =
        (info['latest_deploy_job'] is Map)
            ? Map<String, dynamic>.from(info['latest_deploy_job'] as Map)
            : const <String, dynamic>{};

    final jobStatus = (latestDeployJob['status'] ?? '').toString().trim();
    final jobError = (latestDeployJob['error'] ?? '').toString().trim();
    final runnerState = (runner['state'] ?? '').toString().trim();
    final healthStatus = (runner['health_status'] ?? '').toString().trim();

    if (isInvalidBotId(jobError)) {
      return _runtimeCopy(
        fr:
            'ID de bot invalide pour le demarrage sur les serveurs Bot Creator. Synchronisez/recree le bot puis reessayez. Details : $jobError',
        en:
            'Invalid bot ID for startup on Bot Creator servers. Sync/recreate the bot, then retry. Details: $jobError',
      );
    }

    if (!deployed) {
      return _runtimeCopy(
        fr:
            'Les serveurs Bot Creator ne sont pas encore prets pour ce bot. Erreur initiale : $error',
        en:
            'Bot Creator servers are not ready for this bot yet. Original error: $error',
      );
    }
    if (jobStatus == 'QUEUED' || jobStatus == 'RUNNING') {
      return _runtimeCopy(
        fr:
            'Le demarrage sur les serveurs Bot Creator est encore en cours ($jobStatus). Le traitement peut etre en attente ou toujours en cours. Erreur initiale : $error',
        en:
            'Bot Creator server startup is still in progress ($jobStatus). Processing may still be queued or running. Original error: $error',
      );
    }
    if (jobStatus == 'FAILED') {
      final suffix = jobError.isEmpty ? '' : ' Details: $jobError';
      return _runtimeCopy(
        fr:
            'Le demarrage sur les serveurs Bot Creator a echoue.$suffix Erreur initiale : $error',
        en: 'Bot Creator server startup failed.$suffix Original error: $error',
      );
    }
    if (healthStatus.toLowerCase() == 'unreachable' ||
        runnerState.toUpperCase() == 'DEGRADED') {
      return _runtimeCopy(
        fr:
            'Les serveurs Bot Creator sont temporairement injoignables. Erreur initiale : $error',
        en:
            'Bot Creator servers are temporarily unreachable. Original error: $error',
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
