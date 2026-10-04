import '../../../actions/role_definition_actions.dart'
    show isRoleDefinitionPayload;
import '../../../services/bot_moderation_service.dart';
import '../../../services/role_definition.dart';
import '../../../types/action.dart';
import '../../execution_budget.dart';
import 'action_environment.dart';

/// Role actions on the native engine, parity with `addRoleAction` /
/// `removeRoleAction` (actions/add_role.dart, remove_role.dart): same payload
/// keys, same request (historical default audit reason included), same result
/// (`results[key]` = affected user id) and same failure messages. The effect is
/// the shared [BotModerationService], the service BDFD's `$giveRole`/`$takeRole`
/// already use; only the request differs from the narrower BDFD signatures.
///
/// Role *definitions* (`createNew`, `deleteRole`, `modify`, ...) are not
/// handled here: [supportsRoleAction] is false for them and they stay on the
/// historical executor.
bool supportsRoleAction(Action action) =>
    (action.type == BotCreatorActionType.addRole ||
        action.type == BotCreatorActionType.removeRole) &&
    !isRoleDefinitionPayload(action.payload);

Future<String?> addRoleAction(ActionCall call) => _roleAction(call, add: true);
Future<String?> removeRoleAction(ActionCall call) =>
    _roleAction(call, add: false);

Future<String?> _roleAction(ActionCall call, {required bool add}) async {
  // Same guard as the historical executor, before anything is resolved.
  if (call.env.guildId == null) {
    throw Exception('User action requires a guild context');
  }
  final service = call.env.moderation;
  if (service == null) {
    throw StateError('A moderation service is required for role actions.');
  }
  final Map<String, dynamic> payload;
  try {
    payload = call.resolvedPayload();
    call.budget.check();
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    // The `Failed to ...` wrapper of the historical action function.
    throw Exception('Failed to ${add ? 'add' : 'remove'} role: $error');
  }
  final userId =
      (int.tryParse(payload['userId']?.toString() ?? '') ??
              int.tryParse(payload['memberId']?.toString() ?? '') ??
              '')
          .toString();
  final reason = (payload['reason'] ?? '').toString();
  final BotModerationRequest request;
  if (add && payload.containsKey('setRoles')) {
    final rawRoles = payload['setRoles'];
    if (rawRoles is! List) {
      throw Exception('setRoles must be a list of role IDs');
    }
    request = BotModerationRequest(
      operation: BotModerationOperation.setUserRoles,
      userId: userId,
      roleReplacement: RoleReplacement(rawRoles.map((r) => r.toString())),
      reason: reason,
    );
  } else {
    request = BotModerationRequest(
      operation: add
          ? BotModerationOperation.addRole
          : BotModerationOperation.removeRole,
      userId: userId,
      roleId: (payload['roleId'] ?? '').toString(),
      reason: reason,
    );
  }
  try {
    return await service.moderate(request, budget: call.budget);
  } on StateError catch (error) {
    // The service reports a refused request as StateError(message); the visual
    // block has always surfaced it as Exception(message).
    throw Exception(error.message);
  }
}
