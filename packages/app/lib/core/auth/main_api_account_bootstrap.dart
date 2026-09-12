import 'dart:developer' as developer;

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/utils/global.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_config_import.dart';
import 'package:bot_creator/features/bot_editor/logic/bot_reconciliation_service.dart';
import 'package:bot_creator/main.dart';
import 'package:nyxx/nyxx.dart';

/// Pull managed bots from the Manager after login so a fresh install
/// or connected account can recover cloud-synced bots, their avatars, and commands immediately,
/// while merging and retaining all local bots and commands without data loss.
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
    var config = bot['config'] as Map<String, dynamic>? ?? const {};

    var avatarHash =
        bot['avatar_hash']?.toString() ?? bot['avatar']?.toString();
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
          if (fetchedName != null &&
              fetchedName.isNotEmpty &&
              botName == 'Unnamed Bot') {
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

    // If commands/workflows are not inlined in config (e.g. stored in R2 / config_url),
    // fetch the full config from the manager
    if (config['commands'] == null) {
      try {
        final fullRemote = await client.getBotConfig(botId);
        if (fullRemote.isNotEmpty) {
          config = fullRemote;
        }
      } catch (e) {
        developer.log(
          'Failed to fetch full remote config for $botId: $e',
          name: 'MainApiAccountBootstrap',
        );
      }
    }

    // Rehydrate commands and workflows from remote config if available
    final remoteCommands = extractCommandListFromConfig(config['commands']);
    final remoteWorkflows = config['workflows'];
    final hasRemoteData =
        remoteCommands.isNotEmpty ||
        (remoteWorkflows is List && remoteWorkflows.isNotEmpty) ||
        (remoteWorkflows is Map && remoteWorkflows.isNotEmpty);

    final localCommands = await appManager.listAppCommands(
      botId,
      forceRefresh: true,
    );

    if (hasRemoteData) {
      try {
        if (localCommands.isEmpty) {
          // Fresh install or no local commands: restore all remote commands
          await applyManagerConfigToLocal(
            appManager: appManager,
            botId: botId,
            remoteConfig: config,
            saveAppMetadata: false,
            deleteMissingLocalCommands: false,
          );
        } else {
          // Both local and remote exist: smartMerge to retain local commands!
          await BotReconciliationService.smartMerge(
            botId: botId,
            remoteConfig: config,
            client: client,
            appManager: appManager,
            botName: botName,
          );
        }
      } catch (e) {
        developer.log(
          'Failed to restore commands/workflows during login sync for $botId: $e',
          name: 'MainApiAccountBootstrap',
        );
      }
    } else if (localCommands.isNotEmpty) {
      // Remote had no commands but local has commands: push local to remote!
      try {
        await BotReconciliationService.keepLocalAndPushToCloud(
          botId: botId,
          client: client,
          botName: botName,
          appManager: appManager,
        );
      } catch (e) {
        developer.log('Failed to push local commands to remote for $botId: $e');
      }
    }

    synced++;
  }

  // Phase 2: Preserve and register locally created bots that aren't on Manager yet
  try {
    final remoteBotIds = bots
        .map((b) => (b['bot_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final localApps = await appManager.getAllApps();
    for (final rawApp in localApps) {
      if (rawApp is! Map) continue;
      final localBotId = (rawApp['id'] ?? '').toString().trim();
      if (localBotId.isEmpty || remoteBotIds.contains(localBotId)) continue;
      final token = (rawApp['token'] ?? '').toString().trim();
      final name = (rawApp['name'] ?? 'Bot').toString();
      if (token.isEmpty) continue;

      try {
        final localCmds = await appManager.listAppCommands(
          localBotId,
          forceRefresh: true,
        );
        if (localCmds.isNotEmpty) {
          await BotReconciliationService.keepLocalAndPushToCloud(
            botId: localBotId,
            client: client,
            botName: name,
            appManager: appManager,
          );
          synced++;
        }
      } catch (e) {
        developer.log(
          'Failed to sync local-only bot $localBotId to cloud: $e',
          name: 'MainApiAccountBootstrap',
        );
      }
    }
  } catch (e) {
    developer.log('Local bot reconciliation scan failed: $e');
  }

  await appManager.refreshApps();
  return synced;
}
