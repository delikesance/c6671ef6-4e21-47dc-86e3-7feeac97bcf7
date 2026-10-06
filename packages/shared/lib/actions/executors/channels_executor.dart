import 'package:nyxx/nyxx.dart';

import '../../types/action.dart';
import '../../services/bot_channel_blocks.dart';
import '../permission_checks.dart' show BotPermissionCache;
import '../../engine/execution_budget.dart';

Snowflake? _toSnowflake(dynamic value) {
  if (value == null) return null;
  if (value is Snowflake) return value;
  if (value is BigInt) return Snowflake(value.toInt());
  final s = value.toString().trim();
  final parsed = int.tryParse(s);
  if (parsed == null) return null;
  return Snowflake(parsed);
}

Future<bool> executeChannelsAction({
  required BotCreatorActionType type,
  required NyxxGateway client,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required String Function(String input) resolveValue,
  BotPermissionCache? permissionCache,
  CommandExecutionBudget? budget,
}) async {
  switch (type) {
    case BotCreatorActionType.createChannel:
      if (guildId == null) {
        throw Exception('This action requires a guild context');
      }

      final Map<String, String> createResult = await createChannelAction(
        client,
        guildId: guildId,
        payload: payload,
        resolve: resolveValue,
        budget: budget,
      );

      // Robust error handling: handle non-null and empty error messages
      if ((createResult['error'] ?? '').toString().isNotEmpty) {
        throw Exception(createResult['error']);
      } else if (createResult.containsKey('error')) {
        throw Exception('Action failed with empty error message');
      }

      final channelIdValueCreate = createResult['channelId'] ?? '';
      if (resultKey.isNotEmpty) {
        results[resultKey] = channelIdValueCreate;
      }
      return true;

    case BotCreatorActionType.updateChannel:
      final Map<String, String> updateResult = await updateChannelAction(
        client,
        payload: payload,
        resolve: resolveValue,
        budget: budget,
      );

      if ((updateResult['error'] ?? '').toString().isNotEmpty) {
        throw Exception(updateResult['error']);
      } else if (updateResult.containsKey('error')) {
        throw Exception('Action failed with empty error message');
      }

      final channelIdValueUpdate = updateResult['channelId'] ?? '';
      if (resultKey.isNotEmpty) {
        results[resultKey] = channelIdValueUpdate;
      }
      return true;

    case BotCreatorActionType.removeChannel:
      final rawIds = payload['channelIds'];
      final rawNames = payload['channelNames'];
      final channelIds = <Snowflake>[];
      if (rawNames is List) {
        if (guildId == null) throw Exception('Channel names require a guild');
        budget?.check();
        final guildChannels = await client.guilds[guildId].fetchChannels();
        budget?.check();
        for (final rawName in rawNames) {
          final name = resolveValue(rawName.toString());
          channelIds.addAll(
            guildChannels
                .where((channel) => channel.name == name)
                .map((c) => c.id),
          );
        }
      } else {
        final values = rawIds is List ? rawIds : [payload['channelId']];
        for (final raw in values) {
          final channelId = _toSnowflake(resolveValue(raw?.toString() ?? ''));
          if (channelId == null) {
            throw Exception('Missing or invalid channelId for removeChannel');
          }
          channelIds.add(channelId);
        }
      }
      if (channelIds.isEmpty) {
        throw Exception('No matching channels found for removeChannel');
      }
      for (final channelId in channelIds.toSet()) {
        final removeResult = await removeChannel(
          client,
          channelId,
          budget: budget,
        );
        if (removeResult.containsKey('error')) {
          throw Exception(removeResult['error'] ?? 'Failed to delete channel');
        }
      }

      final channelIdValueRemove = channelIds.last.toString();
      if (resultKey.isNotEmpty) {
        results[resultKey] = channelIdValueRemove;
      }
      return true;

    case BotCreatorActionType.slowmode:
      if (guildId == null) {
        throw Exception('This action requires a guild context');
      }

      final Map<String, String> slowmodeResult = await slowmodeAction(
        client,
        guildId: guildId,
        payload: payload,
        resolve: resolveValue,
        budget: budget,
      );

      if ((slowmodeResult['error'] ?? '').toString().isNotEmpty) {
        throw Exception(slowmodeResult['error']);
      } else if (slowmodeResult.containsKey('error')) {
        throw Exception('Action failed with empty error message');
      }

      final channelIdValueSlowmode = slowmodeResult['channelId'] ?? '';
      if (resultKey.isNotEmpty) {
        results[resultKey] = channelIdValueSlowmode;
      }
      return true;

    default:
      return false;
  }
}
