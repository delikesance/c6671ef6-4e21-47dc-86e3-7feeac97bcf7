import 'package:nyxx/nyxx.dart' show Snowflake;

import '../../../services/bot_member_list_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Member query blocks on the native engine: listMembers and getMember. Parity
/// with the historical loop: only the documented fields are resolved
/// (`limit`/`after`/`query`, `userId`/`memberId`), the effect is
/// [BotMemberListService] and `results[key]` is the members JSON (`'[]'` on an
/// empty answer) or the member JSON.
///
/// Like the historical `switch`, these blocks trace only under a debug profile
/// / replay capture.
final Map<BotCreatorActionType, ActionHandler> memberActionHandlers = {
  BotCreatorActionType.listMembers: _list,
  BotCreatorActionType.getMember: _get,
};

const Set<BotCreatorActionType> memberProfilingOnlyTraceTypes = {
  BotCreatorActionType.listMembers,
  BotCreatorActionType.getMember,
};

bool _always(Action action) => true;

final Map<BotCreatorActionType, bool Function(Action)> memberLeafPredicates = {
  for (final type in memberActionHandlers.keys) type: _always,
};

BotMemberListService _service(ActionCall call) {
  final client = call.env.client;
  if (client == null) {
    throw StateError('A Discord client is required for ${call.type.name}.');
  }
  return DiscordBotMemberListService(client);
}

Map<String, dynamic> _resolveFields(ActionCall call, List<String> fields) {
  final resolved = Map<String, dynamic>.from(call.payload);
  for (final field in fields) {
    if (call.payload.containsKey(field)) {
      resolved[field] = call.resolve(call.payload[field].toString());
    }
  }
  return resolved;
}

Future<String?> _list(ActionCall call) async {
  final Snowflake? guild = call.env.guildSnowflake;
  final result = await _service(call).list(
    guildId: guild,
    payload: _resolveFields(call, const ['limit', 'after', 'query']),
  );
  if (result['error'] != null) throw Exception(result['error']);
  return result['members'] ?? '[]';
}

Future<String?> _get(ActionCall call) async {
  final Snowflake? guild = call.env.guildSnowflake;
  final result = await _service(call).get(
    guildId: guild,
    payload: _resolveFields(call, const ['userId', 'memberId']),
  );
  if (result['error'] != null) throw Exception(result['error']);
  return result['member'] ?? '';
}
