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

Future<Map<String, String>> executeRoleDefinitionAction(
  NyxxGateway client, {
  required Snowflake guildId,
  required Map<String, dynamic> payload,
  CommandExecutionBudget? budget,
}) async {
  try {
    final create = payload['createNew'] == true;
    final delete = payload['deleteRole'] == true;
    final rawPermissions = payload['modifyPermissions'];
    final flags = rawPermissions is List
        ? bdfdPermissionFlags(rawPermissions.map((value) => value.toString()))
        : null;
    if (payload.containsKey('modifyPermissions') && flags == null) {
      return {'error': 'Invalid role permissions'};
    }
    final colorKey = payload.containsKey('updateColor')
        ? 'updateColor'
        : 'color';
    final color = parseBdfdRoleColor(payload[colorKey]);
    if (payload.containsKey(colorKey) && color == null) {
      return {'error': 'Invalid role color'};
    }
    return await executeDiscordModeration(
      client,
      guildId: guildId,
      budget: budget,
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
    );
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to modify role: $error'};
  }
}
