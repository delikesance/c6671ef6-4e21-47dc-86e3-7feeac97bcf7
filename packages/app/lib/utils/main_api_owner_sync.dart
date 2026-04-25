import 'package:bot_creator/utils/global.dart';
import 'package:bot_creator/utils/main_api_client.dart';
import 'package:bot_creator/utils/main_api_settings.dart';
import 'package:bot_creator/utils/remote_runtime.dart';

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

  _appendUniqueOwnerId(ownerIds, bot['owner_id']);
  _appendUniqueOwnerId(ownerIds, bot['ownerId']);
  _appendUniqueOwnerId(ownerIds, owner['id']);
  _appendUniqueOwnerId(ownerIds, owner['owner_id']);
  _appendUniqueOwnerId(ownerIds, team['owner_user_id']);
  _appendUniqueOwnerId(ownerIds, team['ownerUserId']);

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

  Future<DiscordApplicationOwnerMetadata?>
  resolveDiscordOwnerMetadataForBotStart({
    required String botId,
    required String? token,
  }) async {
    final trimmedToken = token?.trim() ?? '';
    if (trimmedToken.isEmpty) {
      log('Unable to resolve Discord owner for $botId: bot token is missing.');
      return null;
    }

    try {
      final metadata = await getDiscordApplicationOwnerMetadata(trimmedToken);
      if (metadata == null || metadata.ownerCandidateIds.isEmpty) {
        log(
          'Discord owner lookup via /applications/@me returned empty for $botId.',
        );
        return null;
      }

      log(
        'Discord owner metadata resolved via /applications/@me for $botId: ${metadata.candidatesLabel}',
      );
      return metadata;
    } catch (error) {
      log(
        'Discord owner lookup via /applications/@me failed for $botId: $error',
      );
      return null;
    }
  }

  Future<bool> restoreMainApiSessionWithBotToken({
    required String botId,
    required String? botToken,
    String? preferredOwnerId,
    Iterable<String> acceptableOwnerIds = const <String>[],
  }) async {
    final trimmedToken = botToken?.trim() ?? '';
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
      final normalizedPreferredOwner = preferredOwnerId?.trim() ?? '';
      final session = await client.exchangeDiscordBotToken(
        botToken: trimmedToken,
        preferredOwnerId:
            normalizedPreferredOwner.isEmpty ? null : normalizedPreferredOwner,
      );

      final normalizedSessionOwner = session.userId?.trim() ?? '';
      final normalizedAcceptableOwners =
          acceptableOwnerIds
              .map((ownerId) => ownerId.trim())
              .where((ownerId) => ownerId.isNotEmpty)
              .toSet();
      if (normalizedAcceptableOwners.isNotEmpty &&
          normalizedSessionOwner.isNotEmpty &&
          !normalizedAcceptableOwners.contains(normalizedSessionOwner)) {
        log(
          'Manager session restore rejected for $botId: owner mismatch expected=${normalizedAcceptableOwners.join(',')} actual=$normalizedSessionOwner.',
        );
        return false;
      }

      await MainApiSettingsStore.saveSession(session);
      log(
        'Manager session restored from bot token for $botId (owner=${normalizedSessionOwner.isEmpty ? 'unknown' : normalizedSessionOwner}).',
      );
      return true;
    } catch (error) {
      log('Manager session restore failed for $botId: $error');
      return false;
    }
  }

  Future<MainApiOwnerResolution> resolveOwnerContext({
    required String botId,
    required Map<String, dynamic> managerBotPayload,
    String? botToken,
  }) async {
    final managerOwner = resolveOwnerFromManagerBotPayload(managerBotPayload);
    if (managerOwner.hasOwner) {
      log(
        'Owner context resolved from manager payload for $botId: ${managerOwner.ownerCandidates.join(',')}',
      );
      return managerOwner;
    }

    final trimmedToken = botToken?.trim() ?? '';
    if (trimmedToken.isEmpty) {
      log(
        'Owner context missing for $botId: no manager owner and no token fallback.',
      );
      return const MainApiOwnerResolution(
        ownerCandidates: <String>[],
        preferredOwnerId: null,
        source: 'none',
      );
    }

    final metadata = await resolveDiscordOwnerMetadataForBotStart(
      botId: botId,
      token: trimmedToken,
    );
    final ownerCandidates = metadata?.ownerCandidateIds ?? const <String>[];
    final preferredOwnerId = metadata?.resolveOwnerId();
    if (ownerCandidates.isNotEmpty) {
      log(
        'Owner context resolved from /applications/@me for $botId: ${ownerCandidates.join(',')}',
      );
    }
    return MainApiOwnerResolution(
      ownerCandidates: ownerCandidates,
      preferredOwnerId: preferredOwnerId,
      source: ownerCandidates.isEmpty ? 'none' : 'token_fallback',
    );
  }

  Future<MainApiClient?> resolveMainApiClientForBot({
    required String botId,
    String? botToken,
    bool attemptSessionRestore = true,
    Iterable<String> ownerCandidatesOverride = const <String>[],
    String? preferredOwnerIdOverride,
  }) async {
    var runtime = await resolveRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    var resolvedToken = botToken?.trim() ?? '';
    if (resolvedToken.isEmpty) {
      final app = await loadLocalBotById(botId);
      resolvedToken = (app['token'] ?? '').toString().trim();
    }

    DiscordApplicationOwnerMetadata? ownerMetadata;
    var ownerCandidates = ownerCandidatesOverride
        .map((ownerId) => ownerId.trim())
        .where((ownerId) => ownerId.isNotEmpty)
        .toList(growable: false);

    if (ownerCandidates.isEmpty && resolvedToken.isNotEmpty) {
      ownerMetadata = await resolveDiscordOwnerMetadataForBotStart(
        botId: botId,
        token: resolvedToken,
      );
      ownerCandidates = ownerMetadata?.ownerCandidateIds ?? const <String>[];
    }

    final session = await MainApiSettingsStore.loadSession();
    final sessionOwnerId = session?.userId?.trim() ?? '';
    final directClient = runtime.client;
    final hasMatchingManagerSession =
        directClient is MainApiClient &&
        session != null &&
        !session.isExpired &&
        (ownerCandidates.isEmpty || ownerCandidates.contains(sessionOwnerId));
    if (hasMatchingManagerSession) {
      return directClient;
    }

    if (!attemptSessionRestore || resolvedToken.isEmpty) {
      return ownerCandidates.isEmpty && directClient is MainApiClient
          ? directClient
          : null;
    }

    if (ownerCandidates.isNotEmpty &&
        sessionOwnerId.isNotEmpty &&
        !ownerCandidates.contains(sessionOwnerId)) {
      log(
        'Manager session owner mismatch for $botId: expected one of ${ownerCandidates.join(',')} actual=$sessionOwnerId. Restoring from bot token.',
      );
    }

    final preferredOwnerId =
        preferredOwnerIdOverride?.trim().isNotEmpty == true
            ? preferredOwnerIdOverride?.trim()
            : ownerMetadata?.resolveOwnerId(preferredOwnerId: sessionOwnerId);

    final restored = await restoreMainApiSessionWithBotToken(
      botId: botId,
      botToken: resolvedToken,
      preferredOwnerId: preferredOwnerId,
      acceptableOwnerIds: ownerCandidates,
    );
    if (!restored) {
      return null;
    }

    runtime = await resolveRuntime(
      getTimeout: const Duration(seconds: 10),
      postTimeout: const Duration(seconds: 20),
    );
    final refreshedClient = runtime.client;
    return refreshedClient is MainApiClient ? refreshedClient : null;
  }
}
