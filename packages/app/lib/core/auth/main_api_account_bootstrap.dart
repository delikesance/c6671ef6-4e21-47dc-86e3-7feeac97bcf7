import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/main.dart';
import 'package:nyxx/nyxx.dart';

/// Pull managed bots from the Manager after Discord login so a fresh install
/// can recover cloud-synced bots immediately.
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
    final botName = (bot['bot_name'] ?? 'Unnamed Bot').toString();
    final token = (bot['bot_token'] ?? '').toString();
    final config = bot['config'] as Map<String, dynamic>? ?? const {};
    await appManager.createOrUpdateApp(
      id: Snowflake.parse(botId),
      username: botName,
      token: token,
      intents: (config['intents'] as Map?)?.cast<String, bool>(),
      prefix: config['prefix']?.toString(),
    );
    synced++;
  }

  return synced;
}
