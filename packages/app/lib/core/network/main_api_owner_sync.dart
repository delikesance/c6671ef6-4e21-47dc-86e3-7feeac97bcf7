import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/core/network/remote_runtime.dart';

class MainApiOwnerResolution {
  const MainApiOwnerResolution({
    required this.ownerCandidates,
    required this.preferredOwnerId,
    required this.source,
  });

  final List<String> ownerCandidates;
  final String? preferredOwnerId;
  final String source;

  bool get hasOwner => ownerCandidates.isNotEmpty;
}

void _appendUniqueOwnerId(List<String> ownerIds, Object? raw) {
  final normalized = raw?.toString().trim() ?? '';
  if (normalized.isEmpty || ownerIds.contains(normalized)) {
    return;
  }
  ownerIds.add(normalized);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }
  return Map<String, dynamic>.from(value);
}

MainApiOwnerResolution resolveOwnerFromManagerBotPayload(
  Map<String, dynamic> bot,
) {
  final ownerIds = <String>[];
  final owner = _asMap(bot['owner']);
  final team = _asMap(bot['team']);

  _appendUniqueOwnerId(ownerIds, team['owner_user_id']);
  _appendUniqueOwnerId(ownerIds, team['ownerUserId']);
  _appendUniqueOwnerId(ownerIds, bot['owner_id']);
  _appendUniqueOwnerId(ownerIds, bot['ownerId']);
  _appendUniqueOwnerId(ownerIds, owner['id']);
  _appendUniqueOwnerId(ownerIds, owner['owner_id']);

  final preferred = ownerIds.isEmpty ? null : ownerIds.first;
  return MainApiOwnerResolution(
    ownerCandidates: ownerIds,
    preferredOwnerId: preferred,
    source: ownerIds.isEmpty ? 'none' : 'manager_payload',
  );
}

class MainApiOwnerSyncHelper {
  const MainApiOwnerSyncHelper({
    required this.resolveRuntime,
    required this.loadLocalBotById,
    required this.log,
  });

  final Future<ResolvedRemoteRuntime> Function({
    Duration getTimeout,
    Duration postTimeout,
  })
  resolveRuntime;
  final Future<Map<String, dynamic>> Function(String botId) loadLocalBotById;
  final void Function(String message) log;

  Future<MainApiOwnerResolution> resolveOwnerContext({
    required String botId,
    required Map<String, dynamic> managerBotPayload,
    required String? botToken,
  }) async {
    log(
      'resolveOwnerContext($botId) called: managerPayloadKeys=${managerBotPayload.keys.join(',')}, tokenPresent=${botToken?.trim().isNotEmpty == true}.',
    );
    final managerOwner = resolveOwnerFromManagerBotPayload(managerBotPayload);
    if (managerOwner.hasOwner) {
      log(
        'Owner context resolved from manager payload for $botId: ${managerOwner.ownerCandidates.join(',')}',
      );
      return managerOwner;
    }

    return const MainApiOwnerResolution(
      ownerCandidates: <String>[],
      preferredOwnerId: null,
      source: 'none',
    );
  }

  Future<bool> restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
  }) async {
    final trimmedToken = botToken?.trim() ?? '';
    log(
      'restoreMainApiSessionWithBotToken($botId) called: tokenPresent=${trimmedToken.isNotEmpty}.',
    );
    if (trimmedToken.isEmpty) {
      log('Manager session restore skipped for $botId: bot token is missing.');
      return false;
    }

    try {
      final config = await MainApiSettingsStore.loadConfig();
      if (!config.isConfigured) {
        log(
          'Manager session restore skipped for $botId: manager base URL is not configured.',
        );
        return false;
      }

      final client = MainApiClient(baseUrl: config.baseUrl);
      final session = await client.exchangeDiscordBotToken(
        botToken: trimmedToken,
      );

      await MainApiSettingsStore.saveBotTokenSession(session);
      log(
        'Manager session restored from bot token for $botId.',
      );
      return true;
    } catch (error) {
      log('Manager session restore failed for $botId: $error');
      return false;
    } finally {
      log('restoreMainApiSessionWithBotToken($botId) completed.');
    }
  }

  Future<MainApiClient?> resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
  }) async {
    log(
      'resolveMainApiClientForBot($botId) called: tokenProvided=${botToken?.trim().isNotEmpty == true}, attemptSessionRestore=$attemptSessionRestore.',
    );

    final config = await MainApiSettingsStore.loadConfig();
    if (!config.isConfigured) {
      log('resolveMainApiClientForBot($botId): Manager not configured, returning null.');
      return null;
    }

    var session = await MainApiSettingsStore.loadSession();
    if (session != null && session.isExpired && session.refreshToken != null) {
      try {
        log('resolveMainApiClientForBot($botId): session expired, attempting to refresh.');
        final client = MainApiClient(
          baseUrl: config.baseUrl,
          timeout: const Duration(seconds: 5),
        );
        final newSession = await client.refreshSession(
          refreshToken: session.refreshToken!,
        );
        await MainApiSettingsStore.saveBotTokenSession(newSession);
        session = newSession;
        log('resolveMainApiClientForBot($botId): session refreshed successfully.');
      } catch (error) {
        log('resolveMainApiClientForBot($botId): session refresh failed: $error');
      }
    }

    if (session != null && !session.isExpired) {
      log(
        'resolveMainApiClientForBot($botId): using active manager session directly.',
      );
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }

    var resolvedToken = botToken?.trim() ?? '';
    if (resolvedToken.isEmpty) {
      final app = await loadLocalBotById(botId);
      resolvedToken = (app['token'] ?? '').toString().trim();
      log(
        'resolveMainApiClientForBot($botId): loaded token from local app storage, tokenPresent=${resolvedToken.isNotEmpty}.',
      );
    }

    if (!attemptSessionRestore || resolvedToken.isEmpty) {
      log(
        'resolveMainApiClientForBot($botId): skipping restore (attemptSessionRestore=$attemptSessionRestore, tokenPresent=${resolvedToken.isNotEmpty}).',
      );
      return null;
    }

    final restored = await restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: resolvedToken,
    );
    if (!restored) {
      log('resolveMainApiClientForBot($botId): session restore failed.');
      return null;
    }

    session = await MainApiSettingsStore.loadSession();
    if (session != null && !session.isExpired) {
      log(
        'resolveMainApiClientForBot($botId) completed: restored manager client successfully.',
      );
      return MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
    }

    return null;
  }
}
