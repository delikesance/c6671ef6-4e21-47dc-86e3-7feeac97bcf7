import 'package:nyxx/nyxx.dart';

import '../services/bot_guild_admin_service.dart';

// The Discord logic lives in [BotGuildAdminService]; these functions are the historical entry
// points of the blocks and delegate to it.

/// Fetches current guild onboarding configuration.
///
/// Returns `{'onboardingJson': '{...}', 'enabled': 'true|false'}` or `{'error': '...'}`.
Future<Map<String, String>> getGuildOnboardingAction(
  NyxxGateway client, {
  required Snowflake? guildId,
}) => DiscordBotGuildAdminService(client).getGuildOnboarding(guildId: guildId);

/// Updates guild onboarding configuration.
///
/// Currently limited by nyxx support in this runtime.
/// Returns `{'status': 'updated'}` on success or `{'error': '...'}`.
Future<Map<String, String>> updateGuildOnboardingAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String Function(String) resolve,
}) => DiscordBotGuildAdminService(
  client,
).updateGuildOnboarding(guildId: guildId, payload: payload, resolve: resolve);
