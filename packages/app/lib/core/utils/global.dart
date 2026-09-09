import 'dart:convert';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'dart:developer' as developer;
import 'package:bot_creator_shared/utils/global.dart' as shared_global;

const String discordUrl = "https://discord.com/api/v10";

const List<String> supportedDiscordAvatarFormats = <String>[
  'png',
  'jpg',
  'jpeg',
  'webp',
  'gif',
];

class DiscordApplicationOwnerMetadata {
  const DiscordApplicationOwnerMetadata({
    required this.ownerId,
    required this.teamId,
    required this.teamOwnerUserId,
    required this.teamMemberUserIds,
    this.rawJson = const <String, dynamic>{},
    this.teamName = '',
    this.ownerUsername = '',
    this.ownerAvatar = '',
    this.teamOwnerUsername = '',
    this.teamMembersInfo = const <Map<String, dynamic>>[],
  });

  final String ownerId;
  final String teamId;
  final String teamOwnerUserId;
  final List<String> teamMemberUserIds;
  final Map<String, dynamic> rawJson;
  final String teamName;
  final String ownerUsername;
  final String ownerAvatar;
  final String teamOwnerUsername;
  final List<Map<String, dynamic>> teamMembersInfo;

  List<String> get ownerCandidateIds {
    final candidates = <String>[];
    _appendUniqueDiscordOwnerId(candidates, teamOwnerUserId);
    _appendUniqueDiscordOwnerId(candidates, ownerId);
    _appendUniqueDiscordOwnerId(candidates, teamId);
    for (final memberUserId in teamMemberUserIds) {
      _appendUniqueDiscordOwnerId(candidates, memberUserId);
    }
    return candidates;
  }

  bool matchesOwnerId(String? rawOwnerId) {
    final ownerId = rawOwnerId?.trim() ?? '';
    if (ownerId.isEmpty) {
      return false;
    }
    return ownerCandidateIds.contains(ownerId);
  }

  String? resolveOwnerId({String? preferredOwnerId}) {
    final normalizedPreferredOwnerId = preferredOwnerId?.trim() ?? '';
    if (normalizedPreferredOwnerId.isNotEmpty &&
        matchesOwnerId(normalizedPreferredOwnerId)) {
      return normalizedPreferredOwnerId;
    }

    final candidates = ownerCandidateIds;
    if (candidates.isEmpty) {
      return null;
    }
    return candidates.first;
  }

  String get candidatesLabel => ownerCandidateIds.join(', ');
}

void _appendUniqueDiscordOwnerId(List<String> candidates, String rawOwnerId) {
  final ownerId = rawOwnerId.trim();
  if (ownerId.isEmpty || candidates.contains(ownerId)) {
    return;
  }
  candidates.add(ownerId);
}

String? avatarFileExtension(String path) {
  final index = path.lastIndexOf('.');
  if (index < 0 || index == path.length - 1) {
    return null;
  }
  return path.substring(index + 1).toLowerCase();
}

bool isSupportedDiscordAvatarPath(String path) {
  final extension = avatarFileExtension(path);
  return extension != null && supportedDiscordAvatarFormats.contains(extension);
}

String supportedDiscordAvatarFormatsLabel() {
  return supportedDiscordAvatarFormats.join(', ');
}

Future<User> getDiscordUser(String botToken) async {
  final client = await Nyxx.connectRest(botToken);
  try {
    return await client.user.fetch();
  } finally {
    try {
      await client.close();
    } catch (_) {}
  }
}

/// Fetch bot's basic user profile from Discord REST API using bot token.
/// Returns null if the token is invalid or request fails.
Future<Map<String, String>?> getDiscordBotUserProfile(String botToken) async {
  final trimmedToken = botToken.trim();
  if (trimmedToken.isEmpty) {
    return null;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('$discordUrl/users/@me'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bot $trimmedToken');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final payload = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
    final id = map['id']?.toString() ?? '';
    final username = map['username']?.toString() ?? '';
    final avatar = map['avatar']?.toString() ?? '';
    final discriminator = map['discriminator']?.toString() ?? '';

    return <String, String>{
      'id': id,
      'username': username,
      'avatar': avatar,
      'discriminator': discriminator,
    };
  } catch (e) {
    developer.log(
      'Failed to fetch bot user profile: $e',
      name: 'GlobalUtils',
    );
    return null;
  } finally {
    client.close(force: true);
  }
}


Future<String?> getDiscordApplicationOwnerId(String botToken) async {
  final metadata = await getDiscordApplicationOwnerMetadata(botToken);
  return metadata?.resolveOwnerId();
}

Future<DiscordApplicationOwnerMetadata?> getDiscordApplicationOwnerMetadata(
  String botToken,
) async {
  final trimmedToken = botToken.trim();
  if (trimmedToken.isEmpty) {
    return null;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('$discordUrl/applications/@me'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bot $trimmedToken');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final payload = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Discord applications endpoint failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(payload);
    if (decoded is! Map) {
      return null;
    }

    final body = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
    var ownerId = '';
    var ownerUsername = '';
    var ownerAvatar = '';
    final owner = body['owner'];
    if (owner is Map) {
      final ownerMap = Map<String, dynamic>.from(
        owner.cast<dynamic, dynamic>(),
      );
      ownerId = (ownerMap['id'] ?? '').toString().trim();
      ownerUsername = (ownerMap['username'] ?? '').toString().trim();
      ownerAvatar = (ownerMap['avatar'] ?? '').toString().trim();
    }

    var teamId = '';
    var teamOwnerUserId = '';
    var teamName = '';
    var teamOwnerUsername = '';
    final teamMemberUserIds = <String>[];
    final teamMembersInfo = <Map<String, dynamic>>[];
    final team = body['team'];
    if (team is Map) {
      final teamMap = Map<String, dynamic>.from(team.cast<dynamic, dynamic>());
      teamId = (teamMap['id'] ?? '').toString().trim();
      teamOwnerUserId = (teamMap['owner_user_id'] ?? '').toString().trim();
      teamName = (teamMap['name'] ?? '').toString().trim();
      final members = teamMap['members'];
      if (members is List) {
        for (final member in members) {
          if (member is! Map) {
            continue;
          }
          final memberMap = Map<String, dynamic>.from(
            member.cast<dynamic, dynamic>(),
          );
          final user = memberMap['user'];
          if (user is! Map) {
            continue;
          }
          final userMap = Map<String, dynamic>.from(
            user.cast<dynamic, dynamic>(),
          );
          final memberUserId = (userMap['id'] ?? '').toString().trim();
          final memberUsername = (userMap['username'] ?? '').toString().trim();
          final memberAvatar = (userMap['avatar'] ?? '').toString().trim();
          final memberRole = (memberMap['role'] ?? 'member').toString().trim();

          if (memberUserId.isNotEmpty) {
            _appendUniqueDiscordOwnerId(teamMemberUserIds, memberUserId);
            teamMembersInfo.add(<String, dynamic>{
              'id': memberUserId,
              'username': memberUsername,
              'avatar': memberAvatar,
              'role': memberRole,
            });
            if (memberUserId == teamOwnerUserId) {
              teamOwnerUsername = memberUsername;
            }
          }
        }
      }
    }

    final metadata = DiscordApplicationOwnerMetadata(
      ownerId: ownerId,
      teamId: teamId,
      teamOwnerUserId: teamOwnerUserId,
      teamMemberUserIds: teamMemberUserIds,
      rawJson: body,
      teamName: teamName,
      ownerUsername: ownerUsername,
      ownerAvatar: ownerAvatar,
      teamOwnerUsername: teamOwnerUsername,
      teamMembersInfo: teamMembersInfo,
    );
    return metadata.ownerCandidateIds.isEmpty ? null : metadata;
  } finally {
    client.close(force: true);
  }
}

Future<int?> getDiscordBotGuildCount(String botToken) async {
  final trimmedToken = botToken.trim();
  if (trimmedToken.isEmpty) {
    return null;
  }

  final client = HttpClient();
  try {
    final request = await client.getUrl(
      Uri.parse('$discordUrl/users/@me/guilds'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bot $trimmedToken');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final response = await request.close();
    final payload = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Discord guilds endpoint failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(payload);
    if (decoded is List) {
      return decoded.length;
    }
    return null;
  } catch (error) {
    developer.log(
      'Failed to fetch bot guild count: $error',
      name: 'GlobalUtils',
    );
    return null;
  } finally {
    client.close(force: true);
  }
}

Future<User> updateDiscordBotProfile(
  String botToken, {
  String? username,
  String? avatarPath,
}) async {
  final trimmedUsername = username?.trim();
  final trimmedAvatarPath = avatarPath?.trim();
  final hasUsername = trimmedUsername != null && trimmedUsername.isNotEmpty;
  final hasAvatarPath =
      trimmedAvatarPath != null && trimmedAvatarPath.isNotEmpty;

  if (!hasUsername && !hasAvatarPath) {
    throw Exception('Nothing to update: username/avatar are empty');
  }

  NyxxRest? client;
  try {
    client = await Nyxx.connectRest(botToken);

    final builder = UserUpdateBuilder();
    if (hasUsername) {
      builder.username = trimmedUsername;
    }

    if (hasAvatarPath) {
      final avatarFile = File(trimmedAvatarPath);
      if (!await avatarFile.exists()) {
        throw Exception('Avatar file not found: $trimmedAvatarPath');
      }
      if (!isSupportedDiscordAvatarPath(trimmedAvatarPath)) {
        final extension = avatarFileExtension(trimmedAvatarPath) ?? 'unknown';
        throw Exception(
          "Unsupported avatar format '$extension'. Supported formats: ${supportedDiscordAvatarFormatsLabel()}",
        );
      }
      builder.avatar = await ImageBuilder.fromFile(avatarFile);
    }

    return await client.users.updateCurrentUser(builder);
  } catch (e) {
    throw Exception('Failed to update bot profile: $e');
  } finally {
    if (client != null) {
      try {
        await client.close();
      } catch (error) {
        developer.log(
          'Failed to close Nyxx REST client: $error',
          name: 'updateDiscordBotProfile',
        );
      }
    }
  }
}

String makeAvatarUrl(
  String userId, {
  String? avatarId,
  bool isAnimated = false,
  String legacyFormat = "webp",
  String? discriminator,
}) {
  if (avatarId == null || avatarId.isEmpty || avatarId == "0") {
    if (discriminator != null &&
        discriminator != "0" &&
        discriminator != "0000") {
      final parsedDiscrim = int.tryParse(discriminator);
      if (parsedDiscrim != null) {
        return "https://cdn.discordapp.com/embed/avatars/${parsedDiscrim % 5}.png";
      }
    }
    final parsedId = BigInt.tryParse(userId);
    if (parsedId != null) {
      return "https://cdn.discordapp.com/embed/avatars/${(parsedId >> 22).toInt() % 6}.png";
    }
    return "https://cdn.discordapp.com/embed/avatars/0.png";
  }
  if (isAnimated && legacyFormat == "gif") {
    return "https://cdn.discordapp.com/avatars/$userId/$avatarId.gif?size=1024";
  }

  return "https://cdn.discordapp.com/avatars/$userId/$avatarId.$legacyFormat?size=1024";
}

String makeGuildIcon(String guildId, String? iconId) {
  if (guildId == "DM" || iconId == null || iconId.isEmpty) {
    return "https://cdn.discordapp.com/embed/avatars/0.png";
  }
  return "https://cdn.discordapp.com/icons/$guildId/$iconId.webp?size=1024";
}

Future<Map<String, String>> generateKeyValues(
  Interaction<ApplicationCommandInteractionData> interaction,
) async {
  return shared_global.generateKeyValues(interaction);
}

Future<Map<String, String>> generateKeyValuesFromInteractionOption(
  InteractionOption value,
  Interaction<ApplicationCommandInteractionData> interaction,
) async {
  return shared_global.generateKeyValuesFromInteractionOption(
    value,
    interaction,
  );
}

InteractionOption? findFocusedOption(List<InteractionOption>? options) {
  return shared_global.findFocusedOption(options);
}

String getChannelName(PartialChannel? channel) {
  return shared_global.getChannelName(channel);
}

/// A thread-safe, bounded log buffer that prevents unbounded memory growth.
///
/// When the buffer exceeds [maxEntries], the oldest entries are evicted.
class LogBuffer {
  LogBuffer({this.maxEntries = 5000});

  final int maxEntries;
  final List<String> _entries = <String>[];

  List<String> get entries => List<String>.unmodifiable(_entries);

  bool get isEmpty => _entries.isEmpty;
  bool get isNotEmpty => _entries.isNotEmpty;
  int get length => _entries.length;

  void add(String entry) {
    _entries.add(entry);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  void addAll(Iterable<String> entries) {
    _entries.addAll(entries);
    while (_entries.length > maxEntries) {
      _entries.removeAt(0);
    }
  }

  void clear() => _entries.clear();

  @override
  String toString() => _entries.toString();
}
