import '../../../actions/handler_utils.dart' show parseSnowflake;
import '../../../services/bot_moderation_service.dart';
import '../../../types/action.dart';
import 'action_environment.dart';

/// Moderation blocks on the native engine: banUser, unbanUser, kickUser,
/// muteUser, unmuteUser and setNickname. Parity with the historical actions
/// (actions/ban_user.dart, ...): same payload keys, same
/// [BotModerationRequest] (the superset the BDFD functions only partly use:
/// `useDefaultReason` stays true, `deleteMessageDays`, `until`, a username to
/// unban, the kick actor), same result (`results[key]` = affected user id) and
/// same failure messages.
final Map<BotCreatorActionType, ActionHandler> moderationActionHandlers = {
  BotCreatorActionType.banUser: (call) => _moderate(call, _ban),
  BotCreatorActionType.unbanUser: (call) => _moderate(call, _unban),
  BotCreatorActionType.kickUser: (call) => _moderate(call, _kick),
  BotCreatorActionType.muteUser: (call) => _moderate(call, _mute),
  BotCreatorActionType.unmuteUser: (call) => _moderate(call, _unmute),
  BotCreatorActionType.setNickname: (call) => _moderate(call, _nickname),
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
  final request = build(call.resolvedPayload());
  try {
    return await service.moderate(request, budget: call.budget);
  } on StateError catch (error) {
    // The service reports a refused request as StateError(message); the visual
    // block has always surfaced it as Exception(message).
    throw Exception(error.message);
  }
}

int _days(Map<String, dynamic> values) =>
    int.tryParse((values['deleteMessageDays'] ?? '0').toString()) ?? 0;

String _reason(Map<String, dynamic> values) =>
    values['reason']?.toString() ?? '';

/// `userId`, else `memberId` when `userId` is not a positive integer.
String _userOrMember(Map<String, dynamic> values) {
  final id = int.tryParse(values['userId']?.toString() ?? '');
  return id != null && id > 0
      ? id.toString()
      : values['memberId']?.toString() ?? '';
}

BotModerationRequest _ban(Map<String, dynamic> values) => BotModerationRequest(
  operation: BotModerationOperation.ban,
  userId: values['userId']?.toString() ?? '',
  reason: _reason(values),
  deleteMessageDays: _days(values),
);

BotModerationRequest _kick(Map<String, dynamic> values) => BotModerationRequest(
  operation: BotModerationOperation.kick,
  userId: values['userId']?.toString() ?? '',
  reason: _reason(values),
  kickPermissionActorId: values['kickPermissionActorId']?.toString(),
  deleteMessageDays: _days(values),
);

BotModerationRequest _unban(Map<String, dynamic> values) {
  final rawId = values['userId']?.toString() ?? '';
  final parsed = int.tryParse(rawId);
  // Preserve the historical username fallback.
  return BotModerationRequest(
    operation: BotModerationOperation.unban,
    userId: parsed != null && parsed > 0 ? rawId : '',
    username: values['username']?.toString() ?? '',
    reason: _reason(values),
  );
}

BotModerationRequest _mute(Map<String, dynamic> values) {
  final rawUntil = values['until']?.toString().trim() ?? '';
  final until = rawUntil.isEmpty ? null : DateTime.tryParse(rawUntil);
  if (rawUntil.isNotEmpty && until == null) {
    throw Exception('Invalid until datetime format');
  }
  return BotModerationRequest(
    operation: BotModerationOperation.timeout,
    userId: _userOrMember(values),
    reason: _reason(values),
    duration: visualTimeoutDuration(values),
    until: until,
  );
}

BotModerationRequest _unmute(Map<String, dynamic> values) =>
    BotModerationRequest(
      operation: BotModerationOperation.untimeout,
      userId: _userOrMember(values),
      reason: _reason(values),
    );

BotModerationRequest _nickname(Map<String, dynamic> values) {
  final raw = values['userId'];
  final parsed = parseSnowflake(raw);
  return BotModerationRequest(
    operation: BotModerationOperation.setNickname,
    // The block reports the normalized id; an invalid one fails in the service
    // with the block's own "Invalid userId".
    userId: parsed?.toString() ?? '',
    nickname: values['nickname']?.toString() ?? '',
    reason: _reason(values),
  );
}
