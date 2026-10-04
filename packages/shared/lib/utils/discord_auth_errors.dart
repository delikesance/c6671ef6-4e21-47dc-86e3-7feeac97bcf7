/// Thrown when a Discord bot token is rejected (401/403) or gateway auth fails.
class DiscordTokenUnauthorizedException implements Exception {
  DiscordTokenUnauthorizedException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

const _gatewayDisallowedIntentsCode = '4014';

/// Returns whether [error] or [reason] indicates disallowed gateway intents (4014).
bool isDiscordGatewayDisallowedIntents(Object? error, [String? reason]) {
  if (error != null) {
    final message = error.toString().toLowerCase();
    if (message.contains('disallowed intent')) {
      return true;
    }
    if (_messageContainsGatewayCode(message, _gatewayDisallowedIntentsCode)) {
      return true;
    }
  }

  final normalized = (reason ?? '').toLowerCase();
  if (normalized.contains('disallowed intent')) {
    return true;
  }
  return _messageContainsGatewayCode(normalized, _gatewayDisallowedIntentsCode);
}

/// Formats a gateway disconnect [reason] into a clear, actionable message.
String formatGatewayDisconnectMessage(String reason) {
  if (isDiscordGatewayDisallowedIntents(null, reason)) {
    return 'Disallowed intents (4014) — enable the required intents in '
        'Discord Developer Portal → Bot → Privileged Gateway Intents';
  }
  return reason.trim().isEmpty ? 'Gateway disconnected' : reason.trim();
}

/// Returns whether [error] indicates an invalid or unauthorized Discord bot token.
bool isDiscordTokenUnauthorized(Object error) {
  if (error is DiscordTokenUnauthorizedException) {
    return true;
  }

  if (isDiscordGatewayDisallowedIntents(error)) {
    return false;
  }

  final message = error.toString().toLowerCase();

  if (_looksLikeDiscordRestUnauthorized(message)) {
    return true;
  }

  if (_looksLikeGatewayAuthFailure(message)) {
    return true;
  }

  return false;
}

/// Wraps [error] as [DiscordTokenUnauthorizedException] when applicable.
Never throwIfDiscordTokenUnauthorized(Object error, {String? context}) {
  if (!isDiscordTokenUnauthorized(error)) {
    throw error;
  }

  final prefix = context == null || context.isEmpty ? '' : '$context: ';
  throw DiscordTokenUnauthorizedException('$prefix$error', cause: error);
}

bool _messageContainsGatewayCode(String message, String code) {
  return message.contains(code) &&
      (message.contains('disconnect') ||
          message.contains('close') ||
          message.contains('gateway') ||
          message.contains('auth') ||
          message.contains('disallowed'));
}

bool _looksLikeDiscordRestUnauthorized(String message) {
  final hasUnauthorized =
      message.contains('unauthorized') || message.contains('forbidden');
  final hasAuthStatus = message.contains('401') || message.contains('403');
  final mentionsDiscordApi =
      message.contains('discord.com/api') ||
      message.contains('applications/@me') ||
      message.contains('/applications/');

  if (hasAuthStatus && hasUnauthorized) {
    return true;
  }

  if (hasAuthStatus && mentionsDiscordApi) {
    return true;
  }

  if (message.contains('discord_token_invalid')) {
    return true;
  }

  return false;
}

bool _looksLikeGatewayAuthFailure(String message) {
  if (isDiscordGatewayDisallowedIntents(null, message)) {
    return false;
  }

  const fatalCodes = <String>[
    '4004', // authentication failed
    '4010', // invalid shard
    '4011', // sharding required
    '4012', // invalid api version
    '4013', // invalid intents
  ];

  for (final code in fatalCodes) {
    if (_messageContainsGatewayCode(message, code)) {
      return true;
    }
  }

  return false;
}
