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
  return await client.user.fetch();
}

Future<String?> getDiscordApplicationOwnerId(String botToken) async {
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
    final owner = body['owner'];
    if (owner is Map) {
      final ownerMap = Map<String, dynamic>.from(
        owner.cast<dynamic, dynamic>(),
      );
      final ownerId = (ownerMap['id'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        return ownerId;
      }
    }

    final team = body['team'];
    if (team is Map) {
      final teamMap = Map<String, dynamic>.from(team.cast<dynamic, dynamic>());
      final ownerId = (teamMap['owner_user_id'] ?? '').toString().trim();
      if (ownerId.isNotEmpty) {
        return ownerId;
      }
    }

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
  if (avatarId == null || avatarId.isEmpty) {
    if (discriminator != null) {
      return "https://cdn.discordapp.com/embed/avatars/${int.parse(discriminator) % 5}.png";
    }
    return "https://cdn.discordapp.com/embed/avatars/${(int.parse(userId) >> 22) % 6}.png";
  }
  if (isAnimated && legacyFormat == "gif") {
    return "https://cdn.discordapp.com/avatars/$userId/$avatarId.gif?size=1024";
  }

  if (avatarId == "0") {
    if (discriminator != null) {
      return "https://cdn.discordapp.com/embed/avatars/${int.parse(discriminator) % 5}.png";
    }
    return "https://cdn.discordapp.com/embed/avatars/${(int.parse(userId) >> 22) % 6}.png";
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
