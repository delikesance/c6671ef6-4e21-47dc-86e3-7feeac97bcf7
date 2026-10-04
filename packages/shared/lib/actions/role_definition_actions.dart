import 'package:nyxx/nyxx.dart';

import '../utils/global.dart';
import '../services/bot_moderation_service.dart';
import '../services/role_definition.dart';
import '../engine/execution_budget.dart';
export '../services/role_definition.dart' show parseBdfdRoleColor;

bool isRoleDefinitionPayload(Map<String, dynamic> payload) =>
    payload['createNew'] == true ||
    payload['deleteRole'] == true ||
    payload['modify'] == true ||
    payload.containsKey('updateColor') ||
    payload.containsKey('modifyPermissions');

/// The moderation request a role-definition payload stands for, or the
/// validation error the block has always reported for it. Shared by the
/// historical executor and the native `bc_addRole` / `bc_removeRole`. A payload
/// field of the wrong type throws (callers report it as "Failed to modify role").
({BotModerationRequest? request, String? error}) roleDefinitionRequest(
  Map<String, dynamic> payload,
) {
  final create = payload['createNew'] == true;
  final delete = payload['deleteRole'] == true;
  final rawPermissions = payload['modifyPermissions'];
  final flags = rawPermissions is List
      ? bdfdPermissionFlags(rawPermissions.map((value) => value.toString()))
      : null;
  if (payload.containsKey('modifyPermissions') && flags == null) {
    return (request: null, error: 'Invalid role permissions');
  }
  final colorKey = payload.containsKey('updateColor') ? 'updateColor' : 'color';
  final color = parseBdfdRoleColor(payload[colorKey]);
  if (payload.containsKey(colorKey) && color == null) {
    return (request: null, error: 'Invalid role color');
  }
  return (
    request: BotModerationRequest(
      operation: create
          ? BotModerationOperation.createRole
          : delete
          ? BotModerationOperation.deleteRole
          : BotModerationOperation.updateRole,
      userId: '',
      roleId: (payload['roleId'] ?? '').toString(),
      useDefaultReason: false,
      reason: (payload['reason'] ?? '').toString(),
      roleDefinition: delete
          ? null
          : RoleDefinition(
              name: payload['name']?.toString(),
              color: color,
              hoist: payload['hoist'] as bool?,
              mentionable: payload['mentionable'] as bool?,
              position: payload['position'] as int?,
              togglePermissions: flags?.map((f) => f.value).toList(),
            ),
    ),
    error: null,
  );
}

Future<Map<String, String>> executeRoleDefinitionAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  CommandExecutionBudget? budget,
}) async {
  try {
    final built = roleDefinitionRequest(payload);
    if (built.error != null) return {'error': built.error!};
    return await executeDiscordModeration(
      client,
      guildId: guildId,
      budget: budget,
      request: built.request!,
    );
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to modify role: $error'};
  }
}
