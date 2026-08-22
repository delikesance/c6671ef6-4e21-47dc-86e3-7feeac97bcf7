import 'dart:convert';

import 'package:bot_creator_shared/bot/bot_config.dart';
import 'package:bot_creator_shared/utils/discord_auth_errors.dart';
import 'package:bot_creator_shared/utils/intent_resolver.dart';
import 'package:http/http.dart' as http;
import 'package:nyxx/nyxx.dart';

const _discordApiBase = 'https://discord.com/api/v10';

const _applicationFlagGatewayPresenceLimited = 1 << 12;
const _applicationFlagGatewayPresence = 1 << 13;
const _applicationFlagGatewayGuildMembersLimited = 1 << 14;
const _applicationFlagGatewayGuildMembers = 1 << 15;
const _applicationFlagGatewayMessageContentLimited = 1 << 18;
const _applicationFlagGatewayMessageContent = 1 << 19;

/// Thrown when the bot is verified and privileged intents cannot be enabled via API.
class PortalIntentAutoEnableError implements Exception {
  const PortalIntentAutoEnableError([
    this.message =
        'Bot is verified, cannot enable privileged intents automatically. '
        'Please enable them in the Discord Developer Portal.',
  ]);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when PATCH /applications/@me fails to update intent flags.
class PortalIntentPatchFailedException implements Exception {
  PortalIntentPatchFailedException(this.statusCode, [this.detail]);

  final int statusCode;
  final String? detail;

  @override
  String toString() =>
      detail ??
      'Failed to update application flags via PATCH ($statusCode)';
}

/// Privileged intent keys enabled for the given application [flags] bitmask.
Set<String> portalEnabledPrivilegedIntentsFromFlags(int flags) {
  final enabled = <String>{};

  if ((flags & _applicationFlagGatewayGuildMembers) != 0 ||
      (flags & _applicationFlagGatewayGuildMembersLimited) != 0) {
    enabled.add('Guild Members');
  }
  if ((flags & _applicationFlagGatewayPresence) != 0 ||
      (flags & _applicationFlagGatewayPresenceLimited) != 0) {
    enabled.add('Guild Presence');
  }
  if ((flags & _applicationFlagGatewayMessageContent) != 0 ||
      (flags & _applicationFlagGatewayMessageContentLimited) != 0) {
    enabled.add('Message Content');
  }

  return enabled;
}

/// Privileged intent keys enabled in the Discord Developer Portal for [app].
Set<String> portalEnabledPrivilegedIntentsFromApplication(Application app) {
  return portalEnabledPrivilegedIntentsFromFlags(app.flags.value);
}

/// Full intents map reflecting portal-enabled privileged keys (Guilds baseline only).
/// Prefer [buildEffectiveIntentsMap] for gateway identify (all non-privileged on).
Map<String, bool> buildPortalIntentsMapFromPrivileged(
  Set<String> portalPrivileged,
) {
  final intents = <String, bool>{'Guilds': true};
  for (final key in portalPrivileged) {
    intents[key] = true;
  }
  return intents;
}

/// Full intents map reflecting portal-enabled privileged keys (Guilds baseline only).
Map<String, bool> buildPortalIntentsMap(Application app) {
  return buildPortalIntentsMapFromPrivileged(
    portalEnabledPrivilegedIntentsFromApplication(app),
  );
}

/// Reads privileged intents currently enabled in the Developer Portal.
Future<Set<String>> readPortalEnabledPrivilegedIntents(
  String token, {
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  final ownsClient = client == null;
  try {
    final flags = await _fetchApplicationFlags(token, client: httpClient);
    return portalEnabledPrivilegedIntentsFromFlags(flags);
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

/// Result of syncing privileged intents from the Developer Portal.
class PortalPrivilegedIntentSyncResult {
  const PortalPrivilegedIntentSyncResult({
    required this.enabled,
    this.didAutoEnable = false,
  });

  final Set<String> enabled;
  final bool didAutoEnable;
}

/// Fetches portal-enabled privileged intents (read-only; never PATCHes the portal).
///
/// Business logic is mirrored in runner-js `application-intent-sync.ts`.
Future<PortalPrivilegedIntentSyncResult> fetchPortalEnabledPrivilegedIntents(
  String token, {
  http.Client? client,
}) async {
  final httpClient = client ?? http.Client();
  final ownsClient = client == null;

  try {
    final flags = await _fetchApplicationFlags(token, client: httpClient);
    final enabled = portalEnabledPrivilegedIntentsFromFlags(flags);
    return PortalPrivilegedIntentSyncResult(enabled: enabled);
  } finally {
    if (ownsClient) {
      httpClient.close();
    }
  }
}

Future<int> _fetchApplicationFlags(
  String token, {
  required http.Client client,
}) async {
  final response = await client.get(
    Uri.parse('$_discordApiBase/applications/@me'),
    headers: {'Authorization': 'Bot $token'},
  );

  if (response.statusCode == 401 || response.statusCode == 403) {
    throw DiscordTokenUnauthorizedException(
      'Failed to fetch application flags (${response.statusCode})',
    );
  }
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw Exception(
      'Failed to fetch application flags (${response.statusCode})',
    );
  }

  final body = jsonDecode(response.body);
  if (body is! Map) {
    throw Exception('Invalid application response from Discord API');
  }

  final flags = body['flags'];
  return flags is int ? flags : int.tryParse(flags?.toString() ?? '') ?? 0;
}

bool botConfigHasLegacyCommands(BotConfig config) {
  if (config.builtInLegacyHelpEnabled) {
    return true;
  }

  for (final command in config.commands) {
    final data = command['data'];
    if (data is! Map) continue;
    final map = Map<String, dynamic>.from(data);
    if (map['legacyModeEnabled'] != true) continue;

    final type = (command['type'] ?? map['commandType'] ?? '').toString();
    if (type == 'chatInput' || type.isEmpty) {
      return true;
    }
  }
  return false;
}

/// Effective intents for gateway identify: all non-privileged intents on by
/// default; privileged keys set to true only when required by bot config AND
/// enabled in the portal.
Map<String, bool> buildEffectiveIntentsMap({
  required BotConfig config,
  required Set<String> portalEnabledPrivileged,
  List<String>? warnings,
}) {
  final requiredKeys = resolveRequiredIntentKeys(
    eventWorkflows: config.workflows,
    hasLegacyCommands: botConfigHasLegacyCommands(config),
    approvedPrivilegedIntents: portalEnabledPrivileged,
    warnings: warnings,
  );

  final effective = <String, bool>{
    for (final key in allIntentKeys)
      key: !privilegedIntentKeys.contains(key),
  };

  for (final key in requiredKeys) {
    if (privilegedIntentKeys.contains(key)) {
      effective[key] = portalEnabledPrivileged.contains(key);
    }
  }

  return effective;
}

/// Human-readable list of enabled intent keys from an effective map.
List<String> enabledIntentNames(Map<String, bool> effectiveMap) {
  return effectiveMap.entries
      .where((entry) => entry.value)
      .map((entry) => entry.key)
      .toList()
    ..sort();
}

final _intentKeyToGatewayBit = <String, Flag<GatewayIntents>>{
  'Guilds': GatewayIntents.guilds,
  'Guild Members': GatewayIntents.guildMembers,
  'Guild Moderation': GatewayIntents.guildModeration,
  'Guild Expressions': GatewayIntents.guildEmojisAndStickers,
  'Guild Integrations': GatewayIntents.guildIntegrations,
  'Guild Webhooks': GatewayIntents.guildWebhooks,
  'Guild Invites': GatewayIntents.guildInvites,
  'Guild Voice States': GatewayIntents.guildVoiceStates,
  'Guild Presence': GatewayIntents.guildPresences,
  'Guild Messages': GatewayIntents.guildMessages,
  'Guild Message Reactions': GatewayIntents.guildMessageReactions,
  'Guild Message Typing': GatewayIntents.guildMessageTyping,
  'Direct Messages': GatewayIntents.directMessages,
  'Direct Message Reactions': GatewayIntents.directMessageReactions,
  'Direct Message Typing': GatewayIntents.directMessageTyping,
  'Message Content': GatewayIntents.messageContent,
  'Guild Scheduled Events': GatewayIntents.guildScheduledEvents,
  'Auto Moderation Configuration': GatewayIntents.autoModerationConfiguration,
  'Auto Moderation Execution': GatewayIntents.autoModerationExecution,
  'Guild Message Polls': GatewayIntents.guildMessagePolls,
  'Direct Message Polls': GatewayIntents.directMessagePolls,
};

/// Safe fallback when portal sync fails: strip all privileged intents.
Map<String, bool> buildSafeFallbackIntentsMap({
  required BotConfig config,
  List<String>? warnings,
}) {
  warnings?.add(
    'Could not sync intents from Discord Developer Portal — '
    'privileged intents disabled for this connection.',
  );

  return buildEffectiveIntentsMap(
    config: config,
    portalEnabledPrivileged: const {},
    warnings: warnings,
  );
}

/// Builds the gateway intent bitmask from an effective intents map.
Flags<GatewayIntents> buildGatewayIntents(Map<String, bool> effectiveMap) {
  var intents = Flags<GatewayIntents>(0);

  for (final entry in effectiveMap.entries) {
    if (entry.value != true) {
      continue;
    }
    final bit = _intentKeyToGatewayBit[entry.key];
    if (bit != null) {
      intents |= bit;
    }
  }

  if (intents.value == 0) {
    intents |= GatewayIntents.guilds;
  }

  return intents;
}
