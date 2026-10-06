import 'package:nyxx/nyxx.dart';

import '../actions/handler_utils.dart'
    show parseSnowflake, resolvePayloadValues;
import '../utils/global.dart';
import '../engine/execution_budget.dart';
import 'bot_moderation_service.dart';
import 'role_definition.dart';

export 'role_definition.dart' show parseBdfdRoleColor;

// Payload-to-request of the moderation and role blocks, shared by the native
// `bc_*` handlers (engine/bdfd/visual/moderation_actions.dart, role_actions.dart)
// and by the map-returning entry points below (`banUserAction`...), which the
// historical executor and the tests still use. No dependency on the action loop.

/// A payload the block refuses before any Discord call; [message] is the exact
/// failure text the block reports.
class BotBlockRequestError implements Exception {
  const BotBlockRequestError(this.message);
  final String message;
  @override
  String toString() => message;
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

BotModerationRequest banRequest(Map<String, dynamic> values) =>
    BotModerationRequest(
      operation: BotModerationOperation.ban,
      userId: values['userId']?.toString() ?? '',
      reason: _reason(values),
      deleteMessageDays: _days(values),
    );

BotModerationRequest kickRequest(Map<String, dynamic> values) =>
    BotModerationRequest(
      operation: BotModerationOperation.kick,
      userId: values['userId']?.toString() ?? '',
      reason: _reason(values),
      kickPermissionActorId: values['kickPermissionActorId']?.toString(),
      deleteMessageDays: _days(values),
    );

BotModerationRequest unbanRequest(Map<String, dynamic> values) {
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

/// Throws [BotBlockRequestError] for an unparsable `until`.
BotModerationRequest muteRequest(Map<String, dynamic> values) {
  final rawUntil = values['until']?.toString().trim() ?? '';
  final until = rawUntil.isEmpty ? null : DateTime.tryParse(rawUntil);
  if (rawUntil.isNotEmpty && until == null) {
    throw const BotBlockRequestError('Invalid until datetime format');
  }
  return BotModerationRequest(
    operation: BotModerationOperation.timeout,
    userId: _userOrMember(values),
    reason: _reason(values),
    duration: visualTimeoutDuration(values),
    until: until,
  );
}

BotModerationRequest unmuteRequest(Map<String, dynamic> values) =>
    BotModerationRequest(
      operation: BotModerationOperation.untimeout,
      userId: _userOrMember(values),
      reason: _reason(values),
    );

BotModerationRequest nicknameRequest(
  Map<String, dynamic> values,
) => BotModerationRequest(
  operation: BotModerationOperation.setNickname,
  // The block reports the normalized id; an invalid one fails in the service
  // with the block's own "Invalid userId".
  userId: parseSnowflake(values['userId'])?.toString() ?? '',
  nickname: values['nickname']?.toString() ?? '',
  reason: _reason(values),
);

Future<Map<String, String>> _moderate(
  NyxxGateway client,
  Snowflake? guildId,
  BotModerationRequest Function(Map<String, dynamic>) build,
  Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
) async {
  final values = resolve == null
      ? payload
      : resolvePayloadValues(payload, resolve);
  final BotModerationRequest request;
  try {
    request = build(values);
  } on BotBlockRequestError catch (error) {
    return {'error': error.message, 'userId': ''};
  }
  return executeDiscordModeration(
    client,
    guildId: guildId,
    budget: budget,
    request: request,
  );
}

/// Resolves block placeholders before invoking the shared moderation service.
Future<Map<String, String>> banUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => _moderate(client, guildId, banRequest, payload, resolve, budget);

Future<Map<String, String>> kickUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => _moderate(client, guildId, kickRequest, payload, resolve, budget);

Future<Map<String, String>> unbanUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => _moderate(client, guildId, unbanRequest, payload, resolve, budget);

Future<Map<String, String>> muteUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => _moderate(client, guildId, muteRequest, payload, resolve, budget);

Future<Map<String, String>> unmuteUserAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) => _moderate(client, guildId, unmuteRequest, payload, resolve, budget);

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

Future<Map<String, String>> addRoleAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) async {
  // Résoudre les variables dans le payload si une fonction resolve est fournie
  final resolvedPayload = resolve != null
      ? resolvePayloadValues(payload, resolve)
      : payload;

  try {
    if (guildId == null) {
      return {'error': 'Missing guildId', 'userId': '', 'roleId': ''};
    }

    budget?.check();
    if (isRoleDefinitionPayload(resolvedPayload)) {
      return await executeRoleDefinitionAction(
        client,
        guildId: guildId,
        payload: resolvedPayload,
        budget: budget,
      );
    }

    if (!resolvedPayload.containsKey('setRoles')) {
      final result = await executeDiscordModeration(
        client,
        guildId: guildId,
        budget: budget,
        request: BotModerationRequest(
          operation: BotModerationOperation.addRole,
          userId:
              (int.tryParse(resolvedPayload['userId']?.toString() ?? '') ??
                      int.tryParse(
                        resolvedPayload['memberId']?.toString() ?? '',
                      ) ??
                      '')
                  .toString(),
          roleId: (resolvedPayload['roleId'] ?? '').toString(),
          reason: (resolvedPayload['reason'] ?? '').toString(),
        ),
      );
      return {...result, 'roleId': result['roleId'] ?? ''};
    }
    final rawRoles = resolvedPayload['setRoles'];
    if (rawRoles is! List) {
      return {
        'error': 'setRoles must be a list of role IDs',
        'userId': '',
        'roleId': '',
      };
    }
    return await executeDiscordModeration(
      client,
      guildId: guildId,
      budget: budget,
      request: BotModerationRequest(
        operation: BotModerationOperation.setUserRoles,
        userId:
            (int.tryParse(resolvedPayload['userId']?.toString() ?? '') ??
                    int.tryParse(
                      resolvedPayload['memberId']?.toString() ?? '',
                    ) ??
                    '')
                .toString(),
        roleReplacement: RoleReplacement(rawRoles.map((r) => r.toString())),
        reason: (resolvedPayload['reason'] ?? '').toString(),
      ),
    );
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {'error': 'Failed to add role: $error', 'userId': '', 'roleId': ''};
  }
}

Future<Map<String, String>> removeRoleAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
  CommandExecutionBudget? budget,
}) async {
  // Résoudre les variables dans le payload si une fonction resolve est fournie
  final resolvedPayload = resolve != null
      ? resolvePayloadValues(payload, resolve)
      : payload;

  try {
    if (guildId == null) {
      return {'error': 'Missing guildId', 'userId': '', 'roleId': ''};
    }

    budget?.check();
    if (!isRoleDefinitionPayload(resolvedPayload)) {
      final result = await executeDiscordModeration(
        client,
        guildId: guildId,
        budget: budget,
        request: BotModerationRequest(
          operation: BotModerationOperation.removeRole,
          userId:
              (int.tryParse(resolvedPayload['userId']?.toString() ?? '') ??
                      int.tryParse(
                        resolvedPayload['memberId']?.toString() ?? '',
                      ) ??
                      '')
                  .toString(),
          roleId: (resolvedPayload['roleId'] ?? '').toString(),
          reason: (resolvedPayload['reason'] ?? '').toString(),
        ),
      );
      return {...result, 'roleId': result['roleId'] ?? ''};
    }
    return await executeRoleDefinitionAction(
      client,
      guildId: guildId,
      payload: resolvedPayload,
      budget: budget,
    );
  } on CommandExecutionTimeout {
    rethrow;
  } catch (error) {
    return {
      'error': 'Failed to remove role: $error',
      'userId': '',
      'roleId': '',
    };
  }
}
