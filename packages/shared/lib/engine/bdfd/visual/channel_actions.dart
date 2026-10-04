import 'package:nyxx/nyxx.dart' show Permissions, Snowflake;

import '../../../services/bot_channel_blocks.dart'
    show
        createChannelActionWith,
        editChannelPermissionsActionWith,
        removeChannelWith,
        slowmodeActionWith,
        updateChannelActionWith;
import '../../../bot/bot_data_store.dart';
import '../../../services/bot_channel_mutation_service.dart';
import '../../../services/bot_channel_permission_service.dart';
import '../../../services/bot_channel_query_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';
import 'message_actions.dart' show visualRespondWithMessage;

/// Channel blocks on the native engine: createChannel, updateChannel,
/// removeChannel, slowmode, editChannelPermissions and deleteChannelPermission.
///
/// The historical actions already ran on the shared channel services; the
/// native handlers call the very same payload-to-request functions (the
/// `...ActionWith` variants of the action files, which take the service), so
/// topic, nsfw, slowmode, reason, archive options... reach the service exactly
/// as before, without changing any BDFD function signature.
///
/// Tickets are `createChannel` with `isTicket` (private channel, store markers
/// `__ticket` / `__ticket_owner`, optional welcome message) and `removeChannel`
/// with `ticketClose` (marker and creator-or-staff check, then marker removal).
final Map<BotCreatorActionType, ActionHandler> channelActionHandlers = {
  BotCreatorActionType.createChannel: _createChannel,
  BotCreatorActionType.updateChannel: _updateChannel,
  BotCreatorActionType.removeChannel: _removeChannel,
  BotCreatorActionType.slowmode: _slowmode,
  BotCreatorActionType.editChannelPermissions: _editPermissions,
  BotCreatorActionType.deleteChannelPermission: _deletePermission,
};

bool _always(Action action) => true;

const Map<BotCreatorActionType, bool Function(Action)> channelLeafPredicates = {
  BotCreatorActionType.createChannel: _always,
  BotCreatorActionType.updateChannel: _always,
  BotCreatorActionType.removeChannel: _always,
  BotCreatorActionType.slowmode: _always,
  BotCreatorActionType.editChannelPermissions: _always,
  BotCreatorActionType.deleteChannelPermission: _always,
};

T _service<T>(ActionCall call) {
  final service = call.env.moderation;
  if (service is! T) {
    throw StateError('A channel service is required for ${call.type.name}.');
  }
  return service as T;
}

Snowflake? _fallbackChannel(ActionCall call) =>
    call.env.fallbackChannelId ??
    (call.env.interaction as dynamic)?.channel?.id as Snowflake?;

/// The executor's failure handling of a channel result map.
void _fail(Map<String, String> result) {
  if ((result['error'] ?? '').toString().isNotEmpty) {
    throw Exception(result['error']);
  } else if (result.containsKey('error')) {
    throw Exception('Action failed with empty error message');
  }
}

Snowflake? _toSnowflake(String value) {
  final parsed = int.tryParse(value.trim());
  return parsed == null ? null : Snowflake(parsed);
}

Future<String?> _createChannel(ActionCall call) async {
  if (call.payload['isTicket'] == true) return _createTicket(call);
  final guild = call.env.guildSnowflake;
  if (guild == null) throw Exception('This action requires a guild context');
  final result = await createChannelActionWith(
    _service<BotChannelMutationService>(call),
    guildId: '$guild',
    payload: call.payload,
    resolve: call.resolve,
    budget: call.budget,
  );
  _fail(result);
  return result['channelId'] ?? '';
}

Future<String?> _updateChannel(ActionCall call) async {
  final result = await updateChannelActionWith(
    _service<BotChannelMutationService>(call),
    payload: call.payload,
    resolve: call.resolve,
    budget: call.budget,
  );
  _fail(result);
  return result['channelId'] ?? '';
}

Future<String?> _slowmode(ActionCall call) async {
  if (call.env.guildSnowflake == null) {
    throw Exception('This action requires a guild context');
  }
  final result = await slowmodeActionWith(
    _service<BotChannelMutationService>(call),
    payload: call.payload,
    resolve: call.resolve,
    budget: call.budget,
  );
  _fail(result);
  return result['channelId'] ?? '';
}

Future<String?> _removeChannel(ActionCall call) async {
  if (call.payload['ticketClose'] != true) return _removeChannelCore(call);
  return _closeTicket(call);
}

BotDataStore _ticketStore(ActionCall call) {
  final store = call.env.store;
  if (store == null) {
    throw StateError('A data store is required for tickets.');
  }
  return store;
}

Future<String?> _createTicket(ActionCall call) async {
  final guild = call.env.guildSnowflake;
  if (guild == null) throw StateError('Tickets require a server');
  final blocks = call.env.blockActions;
  if (blocks == null) {
    throw StateError('A block action service is required for tickets.');
  }
  final ticket = await blocks.createTicketChannel(
    guild,
    call.payload,
    resolve: call.resolve,
  );
  if (ticket['error'] != null) throw StateError(ticket['error']!);
  final ticketId = ticket['channelId']!;
  final store = _ticketStore(call);
  await store.setScopedVariable(
    call.env.botId,
    'channel',
    ticketId,
    '__ticket',
    true,
  );
  await store.setScopedVariable(
    call.env.botId,
    'channel',
    ticketId,
    '__ticket_owner',
    ticket['ownerId'],
  );
  final welcome = call.resolve(
    (call.payload['welcomeMessage'] ?? '').toString(),
  );
  if (welcome.isNotEmpty) {
    final sent = await blocks.sendTicketWelcome(
      Snowflake.parse(ticketId),
      welcome,
    );
    if (sent['error'] != null) {
      call.env.onLog?.call('Ticket welcome: ${sent['error']}');
    }
  }
  return ticketId;
}

Future<String?> _closeTicket(ActionCall call) async {
  final env = call.env;
  final store = _ticketStore(call);
  final ticketId = call.resolve((call.payload['channelId'] ?? '').toString());
  final marker = await store.getScopedVariable(
    env.botId,
    'channel',
    ticketId,
    '__ticket',
  );
  if (marker != true && marker?.toString() != 'true') {
    final message = call.resolve(
      (call.payload['errorMessage'] ?? '').toString(),
    );
    if (message.isNotEmpty) {
      await visualRespondWithMessage(
        env,
        call.context,
        path: call.path,
        payload: {'content': message},
      );
      return '';
    }
    throw StateError('This channel is not a ticket');
  }
  final owner = await store.getScopedVariable(
    env.botId,
    'channel',
    ticketId,
    '__ticket_owner',
  );
  final variables = env.variables;
  final actorId = variables['author.id'] ?? variables['user.id'] ?? '';
  final perms = (variables['member.permissions'] ?? '').toLowerCase();
  if (actorId != owner?.toString() &&
      actorId != variables['guild.ownerId'] &&
      variables['member.isAdmin'] != 'true' &&
      !perms.contains('managechannels') &&
      !perms.contains('administrator')) {
    throw StateError('Only the ticket creator or staff can close it');
  }
  final result = await _removeChannelCore(call);
  await store.removeScopedVariable(env.botId, 'channel', ticketId, '__ticket');
  await store.removeScopedVariable(
    env.botId,
    'channel',
    ticketId,
    '__ticket_owner',
  );
  variables['channel.isTicket'] = 'false';
  return result;
}

Future<String?> _removeChannelCore(ActionCall call) async {
  final mutations = _service<BotChannelMutationService>(call);
  final rawIds = call.payload['channelIds'];
  final rawNames = call.payload['channelNames'];
  final channelIds = <Snowflake>[];
  if (rawNames is List) {
    final guild = call.env.guildSnowflake;
    if (guild == null) throw Exception('Channel names require a guild');
    call.budget.check();
    final guildChannels = await _service<BotChannelQueryService>(
      call,
    ).channels(guildId: '$guild', budget: call.budget);
    call.budget.check();
    for (final rawName in rawNames) {
      final name = call.resolve(rawName.toString());
      channelIds.addAll(
        guildChannels
            .where((channel) => channel.name == name)
            .map((channel) => Snowflake.parse(channel.id)),
      );
    }
  } else {
    final values = rawIds is List ? rawIds : [call.payload['channelId']];
    for (final raw in values) {
      final channelId = _toSnowflake(call.resolve(raw?.toString() ?? ''));
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
    final removed = await removeChannelWith(
      mutations,
      channelId,
      budget: call.budget,
    );
    if (removed.containsKey('error')) {
      throw Exception(removed['error'] ?? 'Failed to delete channel');
    }
  }
  return channelIds.last.toString();
}

Future<String?> _editPermissions(ActionCall call) async {
  final result = await editChannelPermissionsActionWith(
    _service<BotChannelPermissionService>(call),
    payload: call.payload,
    fallbackChannelId: _fallbackChannel(call),
    resolve: call.resolve,
    budget: call.budget,
  );
  if (result['error'] != null) throw Exception(result['error']);
  return result['status'] ?? 'updated';
}

Future<String?> _deletePermission(ActionCall call) async {
  final blocks = call.env.blockActions;
  if (blocks == null) {
    throw StateError(
      'A block action service is required for deleteChannelPermission.',
    );
  }
  final guild = call.env.guildSnowflake;
  if (guild != null) {
    final error = await blocks.guildPermissionError(
      guildId: guild,
      permissions: [Permissions.manageRoles],
      actionLabel: 'delete channel permissions',
      cache: call.env.permissionCache,
    );
    if (error != null) throw Exception(error);
  }
  final result = await blocks.deleteChannelPermission(
    call.payload,
    fallbackChannelId: _fallbackChannel(call),
    resolve: call.resolve,
  );
  if (result['error'] != null) throw Exception(result['error']);
  return result['status'] ?? 'deleted';
}
