import 'package:nyxx/nyxx.dart' show Flag, Permissions, Snowflake;

import '../../../services/bot_block_action_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Thread, guild and bot-profile blocks on the native engine: createThread,
/// addThreadMember, removeThreadMember, leaveGuild, updateSelfUser,
/// registerGuildCommands and unregisterGuildCommands.
///
/// Parity with the historical `handleActions` branches: same permission
/// pre-checks (sharing the execution's permission cache), same field-by-field
/// placeholder resolution, same `results[key]`, same `variables['<key>.*']`
/// mirrors and same failure messages. The effects go through
/// [BotBlockActionService] because the block payloads (thread type / slowmode /
/// reason, command name filter, avatar) are wider than the BDFD signatures.
final Map<BotCreatorActionType, ActionHandler> guildActionHandlers = {
  BotCreatorActionType.createThread: _createThread,
  BotCreatorActionType.addThreadMember: (call) =>
      _threadMember(call, add: true),
  BotCreatorActionType.removeThreadMember: (call) =>
      _threadMember(call, add: false),
  BotCreatorActionType.leaveGuild: _leaveGuild,
  BotCreatorActionType.updateSelfUser: _updateSelfUser,
  BotCreatorActionType.registerGuildCommands: (call) =>
      _guildCommands(call, register: true),
  BotCreatorActionType.unregisterGuildCommands: (call) =>
      _guildCommands(call, register: false),
};

/// Types the historical loop handles in its `switch` (not through an executor):
/// it records their trace (and with it the numeric "last message" quirk) only
/// while a `$debug` profile or a replay capture is running. The native path
/// must stay equally silent otherwise.
const Set<BotCreatorActionType> guildProfilingOnlyTraceTypes = {
  BotCreatorActionType.createThread,
  BotCreatorActionType.addThreadMember,
  BotCreatorActionType.removeThreadMember,
  BotCreatorActionType.leaveGuild,
  BotCreatorActionType.updateSelfUser,
  BotCreatorActionType.registerGuildCommands,
  BotCreatorActionType.unregisterGuildCommands,
  BotCreatorActionType.editChannelPermissions,
  BotCreatorActionType.deleteChannelPermission,
};

bool _always(Action action) => true;

/// Every payload of these types runs natively.
const Map<BotCreatorActionType, bool Function(Action)> guildLeafPredicates = {
  BotCreatorActionType.createThread: _always,
  BotCreatorActionType.addThreadMember: _always,
  BotCreatorActionType.removeThreadMember: _always,
  BotCreatorActionType.leaveGuild: _always,
  BotCreatorActionType.updateSelfUser: _always,
  BotCreatorActionType.registerGuildCommands: _always,
  BotCreatorActionType.unregisterGuildCommands: _always,
};

BotBlockActionService _service(ActionCall call) {
  final service = call.env.blockActions;
  if (service == null) {
    throw StateError(
      'A block action service is required for ${call.type.name}.',
    );
  }
  return service;
}

Snowflake? _snowflake(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = int.tryParse(value.trim());
  return parsed != null ? Snowflake(parsed) : null;
}

/// The bot-permission pre-check of the thread blocks (skipped without a guild).
Future<void> _requireGuildPermission(
  ActionCall call,
  Flag<Permissions> flag,
  String label,
) async {
  final guildId = call.env.guildSnowflake;
  if (guildId == null) return;
  final error = await _service(call).guildPermissionError(
    guildId: guildId,
    permissions: [flag],
    actionLabel: label,
    cache: call.env.permissionCache,
  );
  if (error != null) throw Exception(error);
}

/// `fallbackChannelId` of the historical loop: the explicit one, else the
/// channel of the interaction.
Snowflake? _fallbackChannel(ActionCall call) =>
    call.env.fallbackChannelId ??
    (call.env.interaction as dynamic)?.channel?.id as Snowflake?;

Map<String, String> _checked(Map<String, String> result) {
  if (result['error'] != null) throw Exception(result['error']);
  return result;
}

Future<String?> _createThread(ActionCall call) async {
  await _requireGuildPermission(
    call,
    Permissions.createPublicThreads,
    'create threads',
  );
  final result = _checked(
    await _service(call).createThread(
      call.payload,
      fallbackChannelId: _fallbackChannel(call),
      resolve: call.resolve,
    ),
  );
  final variables = call.env.variables;
  variables['${call.key}.threadId'] = result['threadId'] ?? '';
  variables['${call.key}.name'] = result['name'] ?? '';
  variables['${call.key}.parentId'] = result['parentId'] ?? '';
  variables['thread.lastId'] = result['threadId'] ?? '';
  variables['thread.lastName'] = result['name'] ?? '';
  return result['threadId'] ?? '';
}

Future<String?> _threadMember(ActionCall call, {required bool add}) async {
  await _requireGuildPermission(
    call,
    Permissions.manageThreads,
    add ? 'add thread members' : 'remove thread members',
  );
  final service = _service(call);
  final result = _checked(
    add
        ? await service.addThreadMember(call.payload, resolve: call.resolve)
        : await service.removeThreadMember(call.payload, resolve: call.resolve),
  );
  final variables = call.env.variables;
  variables['${call.key}.threadId'] = result['threadId'] ?? '';
  variables['${call.key}.userId'] = result['userId'] ?? '';
  return add ? 'ADDED' : 'REMOVED';
}

Future<String?> _leaveGuild(ActionCall call) async {
  final target = _snowflake(
    call.resolve((call.payload['guildId'] ?? '').toString()),
  );
  final result = _checked(
    await _service(
      call,
    ).leaveGuild(target ?? call.env.guildSnowflake, resolve: call.resolve),
  );
  return result['guildId'] ?? '';
}

Future<String?> _updateSelfUser(ActionCall call) async {
  final targetUserId = call.resolve(
    (call.payload['targetUserId'] ?? '').toString(),
  );
  if (targetUserId.isNotEmpty && targetUserId != call.env.variables['bot.id']) {
    throw StateError(
      'A bot token cannot change another user’s global username',
    );
  }
  final result = _checked(
    await _service(call).updateSelfUser(call.payload, resolve: call.resolve),
  );
  final variables = call.env.variables;
  variables['${call.key}.username'] = result['username'] ?? '';
  variables['${call.key}.userId'] = result['userId'] ?? '';
  return result['status'] ?? 'updated';
}

Future<String?> _guildCommands(
  ActionCall call, {
  required bool register,
}) async {
  final target = _snowflake(
    call.resolve((call.payload['guildId'] ?? '').toString()),
  );
  final guildId = target ?? call.env.guildSnowflake;
  final service = _service(call);
  // The command name list is passed as stored: it never was resolved.
  final result = _checked(
    register
        ? await service.registerGuildCommands(guildId, call.payload)
        : await service.unregisterGuildCommands(guildId, call.payload),
  );
  return register ? result['registered'] ?? '0' : result['unregistered'] ?? '0';
}
