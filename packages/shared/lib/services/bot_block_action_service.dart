import 'package:nyxx/nyxx.dart';

import '../actions/channel_permissions.dart' show deleteChannelPermissionAction;
import '../actions/register_guild_commands.dart';
import '../actions/thread_management.dart';
import '../actions/unregister_guild_commands.dart';
import '../actions/update_guild.dart' show updateGuildAction;
import '../actions/update_self_user.dart';
import '../bot/bot_data_store.dart';
import 'permission_checks.dart';

/// Operations of visual blocks whose payload is wider than any BDFD function
/// (thread type/slowmode/reason, a command-name filter, the avatar of the bot,
/// a channel overwrite removal...). Each returns the block's own result map
/// (`{'error': ...}` on failure) so that the hidden `bc_*` functions report the
/// same results and errors as the historical executors.
///
/// Placeholders are resolved by the caller-supplied `resolve`, field by field,
/// exactly as the block always did.
abstract interface class BotBlockActionService {
  /// `checkBotGuildPermission` of the bot (shared per-execution [cache]).
  Future<String?> guildPermissionError({
    required Snowflake guildId,
    required List<Flag<Permissions>> permissions,
    required String actionLabel,
    BotPermissionCache? cache,
  });

  Future<Map<String, String>> createThread(
    Map<String, dynamic> payload, {
    Snowflake? fallbackChannelId,
    required String Function(String) resolve,
  });
  Future<Map<String, String>> addThreadMember(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  });
  Future<Map<String, String>> removeThreadMember(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  });
  Future<Map<String, String>> leaveGuild(
    Snowflake? guildId, {
    required String Function(String) resolve,
  });
  Future<Map<String, String>> updateSelfUser(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  });
  Future<Map<String, String>> registerGuildCommands(
    Snowflake? guildId,
    Map<String, dynamic> payload,
  );
  Future<Map<String, String>> unregisterGuildCommands(
    Snowflake? guildId,
    Map<String, dynamic> payload,
  );
  Future<Map<String, String>> deleteChannelPermission(
    Map<String, dynamic> payload, {
    Snowflake? fallbackChannelId,
    required String Function(String) resolve,
  });
}

/// Discord adapter. The effects are the historical action functions, so the
/// block keeps its exact behaviour wherever it runs.
class DiscordBotBlockActionService implements BotBlockActionService {
  const DiscordBotBlockActionService({
    required this.client,
    required this.store,
    required this.botId,
  });

  final NyxxGateway client;

  /// Needed by the guild command registration only.
  final BotDataStore store;
  final String botId;

  @override
  Future<String?> guildPermissionError({
    required Snowflake guildId,
    required List<Flag<Permissions>> permissions,
    required String actionLabel,
    BotPermissionCache? cache,
  }) => checkBotGuildPermission(
    client,
    guildId: guildId,
    requiredPermissions: permissions,
    actionLabel: actionLabel,
    cache: cache,
  );

  @override
  Future<Map<String, String>> createThread(
    Map<String, dynamic> payload, {
    Snowflake? fallbackChannelId,
    required String Function(String) resolve,
  }) => createThreadAction(
    client,
    payload: payload,
    fallbackChannelId: fallbackChannelId,
    resolve: resolve,
  );

  @override
  Future<Map<String, String>> addThreadMember(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  }) => addThreadMemberAction(client, payload: payload, resolve: resolve);

  @override
  Future<Map<String, String>> removeThreadMember(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  }) => removeThreadMemberAction(client, payload: payload, resolve: resolve);

  @override
  Future<Map<String, String>> leaveGuild(
    Snowflake? guildId, {
    required String Function(String) resolve,
  }) => updateGuildAction(
    client,
    guildId: guildId,
    payload: const <String, dynamic>{'leave': true},
    resolve: resolve,
  );

  @override
  Future<Map<String, String>> updateSelfUser(
    Map<String, dynamic> payload, {
    required String Function(String) resolve,
  }) => updateSelfUserAction(client, payload: payload, resolve: resolve);

  @override
  Future<Map<String, String>> registerGuildCommands(
    Snowflake? guildId,
    Map<String, dynamic> payload,
  ) => registerGuildCommandsAction(
    client,
    botId: botId,
    store: store,
    guildId: guildId,
    payload: payload,
  );

  @override
  Future<Map<String, String>> unregisterGuildCommands(
    Snowflake? guildId,
    Map<String, dynamic> payload,
  ) => unregisterGuildCommandsAction(
    client,
    botId: botId,
    store: store,
    guildId: guildId,
    payload: payload,
  );

  @override
  Future<Map<String, String>> deleteChannelPermission(
    Map<String, dynamic> payload, {
    Snowflake? fallbackChannelId,
    required String Function(String) resolve,
  }) => deleteChannelPermissionAction(
    client,
    payload: payload,
    fallbackChannelId: fallbackChannelId,
    resolve: resolve,
  );
}
