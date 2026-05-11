part of 'discord_runner.dart';

extension DiscordRunnerProfileExtension on DiscordRunner {
  Future<void> _reconcileCurrentBotProfile(NyxxGateway client) async {
    final username = config.username?.trim();
    final avatarPath = config.avatarPath?.trim();
    final shouldUpdateUsername = username != null && username.isNotEmpty;
    final shouldUpdateAvatar = avatarPath != null && avatarPath.isNotEmpty;

    if (!shouldUpdateUsername && !shouldUpdateAvatar) {
      return;
    }

    try {
      final builder = UserUpdateBuilder();
      var hasPayload = false;
      if (shouldUpdateUsername) {
        builder.username = username;
        hasPayload = true;
      }

      if (shouldUpdateAvatar) {
        final file = File(avatarPath);
        if (!await file.exists()) {
          _log.warning(
            'Avatar file not found for profile reconciliation: $avatarPath',
          );
        } else {
          builder.avatar = await ImageBuilder.fromFile(file);
          hasPayload = true;
        }
      }

      if (!hasPayload) {
        return;
      }

      await client.users.updateCurrentUser(builder);
      _log.info('Bot profile reconciled from config (username/avatar).');
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to reconcile bot profile: $error',
        error,
        stackTrace,
      );
    }
  }

  void _startStatusRotation(NyxxGateway client) {
    _statusRotationTimer?.cancel();
    _statusRotationTimer = null;

    if (config.statuses.isEmpty) {
      _log.info('No statuses configured, applying presence only.');
      try {
        client.updatePresence(
          PresenceBuilder(
            status: _mapPresenceStatus(config.presenceStatus),
            isAfk: false,
            activities: const [],
          ),
        );
      } catch (error) {
        _log.warning('Presence only update failed: $error');
      }
      return;
    }

    unawaited(_applyInitialStatusThenRotate(client));
  }

  Future<void> _applyInitialStatusThenRotate(NyxxGateway client) async {
    if (config.statuses.isEmpty) {
      return;
    }

    final firstStatus = config.statuses.first;
    await _applyStatus(client, firstStatus);

    // Some sessions ignore the first presence packet right after READY.
    // Re-sending shortly after improves reliability.
    Timer(const Duration(seconds: 3), () {
      unawaited(_applyStatus(client, firstStatus));
    });

    if (config.statuses.length == 1) {
      _log.info('Single status configured, skipping rotation timer.');
      return;
    }

    final nextDelaySeconds = _randomDelaySeconds(
      min: firstStatus.minIntervalSeconds,
      max: firstStatus.maxIntervalSeconds,
    );
    _statusRotationTimer?.cancel();
    _statusRotationTimer = Timer(Duration(seconds: nextDelaySeconds), () {
      unawaited(_applyRandomStatus(client));
    });
  }

  Future<void> _applyStatus(NyxxGateway client, BotStatusConfig status) async {
    final streamUrl = _parseStreamingUrl(status.url);
    final activityType = _mapActivityType(status.type, streamUrl: streamUrl);
    final activityText = _sanitizeActivityText(status.name);
    if (activityText.isEmpty) {
      _log.warning('Skipped status update because activity text is empty.');
      return;
    }

    try {
      client.updatePresence(
        PresenceBuilder(
          status: _mapPresenceStatus(config.presenceStatus),
          isAfk: false,
          activities: <ActivityBuilder>[
            ActivityBuilder(
              name: activityText,
              type: activityType,
              url: streamUrl,
            ),
          ],
        ),
      );
      _log.info('Presence updated: ${status.type} $activityText');
    } catch (error, stackTrace) {
      _log.warning('Failed to update presence: $error', error, stackTrace);
    }
  }

  Future<void> _applyRandomStatus(NyxxGateway client) async {
    if (config.statuses.isEmpty) {
      return;
    }

    final status = config.statuses[_random.nextInt(config.statuses.length)];
    await _applyStatus(client, status);

    final nextDelaySeconds = _randomDelaySeconds(
      min: status.minIntervalSeconds,
      max: status.maxIntervalSeconds,
    );
    _statusRotationTimer?.cancel();
    _statusRotationTimer = Timer(Duration(seconds: nextDelaySeconds), () {
      unawaited(_applyRandomStatus(client));
    });
  }

  int _randomDelaySeconds({required int min, required int max}) {
    if (max <= min) {
      return min;
    }
    return min + _random.nextInt(max - min + 1);
  }

  ActivityType _mapActivityType(String rawType, {required Uri? streamUrl}) {
    switch (rawType.trim().toLowerCase()) {
      case 'streaming':
        return streamUrl != null ? ActivityType.streaming : ActivityType.game;
      case 'listening':
        return ActivityType.listening;
      case 'watching':
        return ActivityType.watching;
      case 'competing':
        return ActivityType.competing;
      case 'playing':
      default:
        return ActivityType.game;
    }
  }

  String _sanitizeActivityText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    // Discord activity names should be short; keep a safe cap.
    if (trimmed.length > 120) {
      return trimmed.substring(0, 120);
    }

    return trimmed;
  }

  Uri? _parseStreamingUrl(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final parsed = Uri.tryParse(trimmed);
    if (parsed == null) {
      return null;
    }
    if ((parsed.scheme != 'http' && parsed.scheme != 'https') ||
        parsed.host.isEmpty) {
      return null;
    }
    return parsed;
  }

  CurrentUserStatus _mapPresenceStatus(String statusString) {
    switch (statusString.trim().toLowerCase()) {
      case 'idle':
        return CurrentUserStatus.idle;
      case 'dnd':
        return CurrentUserStatus.dnd;
      case 'invisible':
        return CurrentUserStatus.invisible;
      case 'online':
      default:
        return CurrentUserStatus.online;
    }
  }
}
