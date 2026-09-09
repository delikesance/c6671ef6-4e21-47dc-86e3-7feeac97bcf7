import 'dart:developer' as developer;

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/main.dart';
import 'package:nyxx/nyxx.dart';

/// Pull managed bots from the Manager after Discord login so a fresh install
/// can recover cloud-synced bots, their avatars, and commands immediately.
Future<int> syncManagedBotsAfterDiscordLogin({
  required String baseUrl,
  required String accessToken,
}) async {
  final client = MainApiClient(baseUrl: baseUrl, accessToken: accessToken);
  final bots = await client.listBots();
  var synced = 0;

  for (final bot in bots) {
    final botId = (bot['bot_id'] ?? '').toString().trim();
    if (botId.isEmpty) {
      continue;
    }
    var botName = (bot['bot_name'] ?? 'Unnamed Bot').toString();
    final token = (bot['bot_token'] ?? '').toString();
    final config = bot['config'] as Map<String, dynamic>? ?? const {};

    var avatarHash = bot['avatar_hash']?.toString() ?? bot['avatar']?.toString();
    var discriminator = bot['discriminator']?.toString();

    // If avatar is missing or not provided by manager, attempt fetching profile from Discord API
    if ((avatarHash == null || avatarHash.isEmpty) && token.trim().isNotEmpty) {
      try {
        final profile = await getDiscordBotUserProfile(token);
        if (profile != null) {
          final fetchedAvatar = profile['avatar'];
          if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
            avatarHash = fetchedAvatar;
          }
          final fetchedDiscrim = profile['discriminator'];
          if (fetchedDiscrim != null && fetchedDiscrim.isNotEmpty) {
            discriminator = fetchedDiscrim;
          }
          final fetchedName = profile['username'];
          if (fetchedName != null && fetchedName.isNotEmpty && botName == 'Unnamed Bot') {
            botName = fetchedName;
          }
        }
      } catch (e) {
        developer.log(
          'Failed to resolve Discord bot profile during login sync for $botId: $e',
          name: 'MainApiAccountBootstrap',
        );
      }
    }

    await appManager.createOrUpdateApp(
      id: Snowflake.parse(botId),
      username: botName,
      avatarHash: avatarHash,
      discriminator: discriminator,
      token: token,
      intents: (config['intents'] as Map?)?.cast<String, bool>(),
      prefix: config['prefix']?.toString(),
    );

    // Rehydrate commands and workflows from remote config if available
    final remoteCommands = extractCommandListFromConfig(config['commands']);
    final remoteWorkflows = config['workflows'];
    final hasRemoteData = remoteCommands.isNotEmpty ||
        (remoteWorkflows is List && remoteWorkflows.isNotEmpty) ||
        (remoteWorkflows is Map && remoteWorkflows.isNotEmpty);

    if (hasRemoteData) {
      try {
        await applyManagerConfigToLocal(
          appManager: appManager,
          botId: botId,
          remoteConfig: config,
          saveAppMetadata: false,
        );
      } catch (e) {
        developer.log(
          'Failed to restore commands/workflows during login sync for $botId: $e',
          name: 'MainApiAccountBootstrap',
        );
      }
    }

    synced++;
  }

  return synced;
}

