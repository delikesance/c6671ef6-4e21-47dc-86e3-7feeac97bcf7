import '../../../services/bot_moderation_blocks.dart';
import '../../../services/bot_moderation_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Moderation blocks on the native engine: banUser, unbanUser, kickUser,
/// muteUser, unmuteUser and setNickname. Parity with the historical actions
/// (services/bot_moderation_blocks.dart): same payload keys, same
/// [BotModerationRequest] (the superset the BDFD functions only partly use:
/// `useDefaultReason` stays true, `deleteMessageDays`, `until`, a username to
/// unban, the kick actor), same result (`results[key]` = affected user id) and
/// same failure messages.
final Map<BotCreatorActionType, ActionHandler> moderationActionHandlers = {
  BotCreatorActionType.banUser: (call) => _moderate(call, banRequest),
  BotCreatorActionType.unbanUser: (call) => _moderate(call, unbanRequest),
  BotCreatorActionType.kickUser: (call) => _moderate(call, kickRequest),
  BotCreatorActionType.muteUser: (call) => _moderate(call, muteRequest),
  BotCreatorActionType.unmuteUser: (call) => _moderate(call, unmuteRequest),
  BotCreatorActionType.setNickname: (call) => _moderate(call, nicknameRequest),
};

bool _always(Action action) => true;

/// Every payload of these types runs natively.
const Map<BotCreatorActionType, bool Function(Action)>
moderationLeafPredicates = {
  BotCreatorActionType.banUser: _always,
  BotCreatorActionType.unbanUser: _always,
  BotCreatorActionType.kickUser: _always,
  BotCreatorActionType.muteUser: _always,
  BotCreatorActionType.unmuteUser: _always,
  BotCreatorActionType.setNickname: _always,
};

Future<String?> _moderate(
  ActionCall call,
  BotModerationRequest Function(Map<String, dynamic> values) build,
) async {
  // Same guard as the historical executor, before anything is resolved.
  if (call.env.guildId == null) {
    throw Exception('User action requires a guild context');
  }
  final service = call.env.moderation;
  if (service == null) {
    throw StateError(
      'A moderation service is required for moderation actions.',
    );
  }
  final BotModerationRequest request;
  try {
    request = build(call.resolvedPayload());
  } on BotBlockRequestError catch (error) {
    throw Exception(error.message);
  }
  try {
    return await service.moderate(request, budget: call.budget);
  } on StateError catch (error) {
    // The service reports a refused request as StateError(message); the visual
    // block has always surfaced it as Exception(message).
    throw Exception(error.message);
  }
}
