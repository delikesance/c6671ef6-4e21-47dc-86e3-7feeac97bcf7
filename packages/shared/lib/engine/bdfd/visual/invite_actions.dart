import 'package:nyxx/nyxx.dart' show Flag, Permissions;

import '../../../actions/permission_checks.dart' show checkBotGuildPermission;
import '../../../services/bot_invite_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';
import 'message_actions.dart' show visualResolvedFallbackChannel;

/// Invite blocks on the native engine: createInvite, deleteInvite and
/// getInvite. Parity with the historical loop: guild permission pre-checks
/// (`createInstantInvite` / `manageChannels`), the effect is
/// [BotInviteService], `results[key]` is the invite code (or `deleted`) and
/// create/get mirror every field into `variables['<key>.<field>']`.
///
/// Like the historical `switch`, these blocks trace only under a debug profile
/// / replay capture.
final Map<BotCreatorActionType, ActionHandler> inviteActionHandlers = {
  BotCreatorActionType.createInvite: _create,
  BotCreatorActionType.deleteInvite: _delete,
  BotCreatorActionType.getInvite: _get,
};

const Set<BotCreatorActionType> inviteProfilingOnlyTraceTypes = {
  BotCreatorActionType.createInvite,
  BotCreatorActionType.deleteInvite,
  BotCreatorActionType.getInvite,
};

bool _always(Action action) => true;

final Map<BotCreatorActionType, bool Function(Action)> inviteLeafPredicates = {
  for (final type in inviteActionHandlers.keys) type: _always,
};

BotInviteService _service(ActionCall call) {
  final client = call.env.client;
  if (client == null) {
    throw StateError('A Discord client is required for ${call.type.name}.');
  }
  return DiscordBotInviteService(client);
}

Future<void> _requirePermission(
  ActionCall call,
  Flag<Permissions> permission,
  String label,
) async {
  final guild = call.env.guildSnowflake;
  if (guild == null) return;
  final error = await checkBotGuildPermission(
    call.env.client!,
    guildId: guild,
    requiredPermissions: [permission],
    actionLabel: label,
    cache: call.env.permissionCache,
  );
  if (error != null) throw Exception(error);
}

void _mirror(ActionCall call, Map<String, String> result) {
  for (final entry in result.entries) {
    call.env.variables['${call.key}.${entry.key}'] = entry.value;
  }
}

Future<String?> _create(ActionCall call) async {
  await _requirePermission(
    call,
    Permissions.createInstantInvite,
    'create invites',
  );
  final result = await _service(call).create(
    payload: call.payload,
    resolve: call.resolve,
    fallbackChannelId: visualResolvedFallbackChannel(call.env),
  );
  if (result['error'] != null) throw Exception(result['error']);
  _mirror(call, result);
  return result['inviteCode'] ?? '';
}

Future<String?> _delete(ActionCall call) async {
  await _requirePermission(call, Permissions.manageChannels, 'delete invites');
  final result = await _service(
    call,
  ).delete(payload: call.payload, resolve: call.resolve);
  if (result['error'] != null) throw Exception(result['error']);
  return result['status'] ?? 'deleted';
}

Future<String?> _get(ActionCall call) async {
  final result = await _service(
    call,
  ).fetch(payload: call.payload, resolve: call.resolve);
  if (result['error'] != null) throw Exception(result['error']);
  _mirror(call, result);
  return result['inviteCode'] ?? '';
}
