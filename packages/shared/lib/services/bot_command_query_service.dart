import 'package:nyxx/nyxx.dart';

import '../bot/bot_data_store.dart';
import '../engine/execution_budget.dart';
import '../utils/command_trigger_type.dart';
import '../utils/legacy_command_triggers.dart';

class BotCommandDefinition {
  const BotCommandDefinition(this.name);
  final String name;
}

class BotGlobalSlashCommand {
  const BotGlobalSlashCommand({required this.id, required this.name});
  final String id;
  final String name;
}

abstract interface class BotCommandQueryService {
  Future<List<BotCommandDefinition>> commands({
    required CommandExecutionBudget budget,
  });
  Future<List<BotGlobalSlashCommand>> globalSlashCommands({
    required CommandExecutionBudget budget,
  });
  Future<String> invite({required CommandExecutionBudget budget});
  Future<void> leaveGuild(
    String? guildId, {
    required CommandExecutionBudget budget,
  });
}

/// Application command definitions come from the application's actual store;
/// enabled global slash commands come from a fresh Discord REST list.
class DiscordBotCommandQueryService implements BotCommandQueryService {
  const DiscordBotCommandQueryService({
    required this.client,
    required this.store,
    required this.botId,
    this.guildId,
    this.invitePermissions = 8,
  });
  final NyxxGateway client;
  final BotDataStore store;
  final String botId;
  final Snowflake? guildId;
  // Same configured permissions as the application's Discord invite helper.
  final int invitePermissions;

  @override
  Future<List<BotCommandDefinition>> commands({
    required CommandExecutionBudget budget,
  }) async {
    final app = await budget.run(() => store.getApp(botId));
    final rows = await budget.run(
      () => store.listAppCommands(botId, forceRefresh: true),
    );
    final prefix = (app['prefix'] ?? '!').toString().trim();
    final result = <BotCommandDefinition>[];
    for (final row in rows) {
      budget.check();
      final name = row['name'];
      if (name is! String || name.isEmpty) {
        throw StateError('Stored command has no name.');
      }
      final nested = row['data'];
      final data = nested is Map ? nested : row;
      final type = commandTriggerType(row);
      final override = data['legacyPrefixOverride'];
      final trigger = override is String && override.trim().isNotEmpty
          ? override
          : name;
      final displayed = const {'prefix', 'hybrid'}.contains(type)
          ? '$prefix${cleanLegacyCommandTriggerName(trigger)}'
          : name;
      result.add(BotCommandDefinition(displayed));
    }
    return List.unmodifiable(result);
  }

  @override
  Future<List<BotGlobalSlashCommand>> globalSlashCommands({
    required CommandExecutionBudget budget,
  }) async {
    final rows = await budget.run(() => client.commands.list());
    final result = <BotGlobalSlashCommand>[];
    for (final row in rows) {
      budget.check();
      if (row.type == ApplicationCommandType.chatInput) {
        result.add(BotGlobalSlashCommand(id: '${row.id}', name: row.name));
      }
    }
    return List.unmodifiable(result);
  }

  @override
  Future<String> invite({required CommandExecutionBudget budget}) async {
    budget.check();
    if (invitePermissions < 0) throw StateError('Invalid invite permissions.');
    final id = client.application.id;
    if (id.value <= 0) throw StateError('Application ID unavailable.');
    return 'https://discord.com/api/oauth2/authorize?client_id=$id&scope=bot+applications.commands&permissions=$invitePermissions';
  }

  @override
  Future<void> leaveGuild(
    String? raw, {
    required CommandExecutionBudget budget,
  }) async {
    final id = raw == null ? guildId : Snowflake(int.parse(raw));
    if (id == null || id.value <= 0) {
      throw StateError('Leaving a guild requires a guild ID.');
    }
    await budget.run(() => client.users.leaveGuild(id));
  }
}
