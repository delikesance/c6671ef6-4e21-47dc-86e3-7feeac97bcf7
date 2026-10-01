import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/utils/global.dart';
import 'package:bot_creator_shared/actions/handler_utils.dart';
import 'permission_checks.dart';
import 'role_definition_actions.dart';

Snowflake? _toSnowflake(dynamic value) {
  final parsed = int.tryParse(value?.toString() ?? '');
  if (parsed == null) {
    return null;
  }
  return Snowflake(parsed);
}

Future<Map<String, String>> addRoleAction(
  NyxxGateway client, {
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  String Function(String)? resolve,
}) async {
  // Résoudre les variables dans le payload si une fonction resolve est fournie
  final resolvedPayload = resolve != null
      ? resolvePayloadValues(payload, resolve)
      : payload;

  try {
    if (guildId == null) {
      return {'error': 'Missing guildId', 'userId': '', 'roleId': ''};
    }

    final permError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.manageRoles],
      actionLabel: 'add roles',
    );
    if (permError != null) {
      return {'error': permError, 'userId': '', 'roleId': ''};
    }

    if (isRoleDefinitionPayload(resolvedPayload)) {
      return executeRoleDefinitionAction(
        client,
        guildId: guildId,
        payload: resolvedPayload,
      );
    }

    final userId =
        _toSnowflake(resolvedPayload['userId']) ??
        _toSnowflake(resolvedPayload['memberId']);
    if (userId == null) {
      return {
        'error': 'Missing or invalid userId/memberId',
        'userId': '',
        'roleId': '',
      };
    }

    if (resolvedPayload.containsKey('setRoles')) {
      final rawRoles = resolvedPayload['setRoles'];
      if (rawRoles is! List) {
        return {
          'error': 'setRoles must be a list of role IDs',
          'userId': '',
          'roleId': '',
        };
      }
      final roleIds = <Snowflake>[];
      for (final rawRole in rawRoles) {
        final roleId = _toSnowflake(rawRole);
        if (roleId == null) {
          return {
            'error': 'setRoles contains an invalid role ID',
            'userId': '',
            'roleId': '',
          };
        }
        roleIds.add(roleId);
      }
      final guild = await fetchGuildCached(client, guildId);
      if (guild == null) {
        return {'error': 'Guild not found', 'userId': '', 'roleId': ''};
      }
      final reason = resolvedPayload['reason']?.toString().trim();
      await guild.members[userId].update(
        MemberUpdateBuilder(roleIds: roleIds),
        auditLogReason: reason != null && reason.isNotEmpty
            ? reason
            : 'Set roles via BotCreator action',
      );
      return {
        'userId': userId.toString(),
        'roleId': roleIds.map((role) => role.toString()).join(','),
        'status': 'set',
      };
    }

    final roleId = _toSnowflake(resolvedPayload['roleId']);
    if (roleId == null) {
      return {'error': 'Missing or invalid roleId', 'userId': '', 'roleId': ''};
    }

    final reason = resolvedPayload['reason']?.toString().trim();
    final guild = await fetchGuildCached(client, guildId);
    if (guild == null) {
      return {'error': 'Guild not found', 'userId': '', 'roleId': ''};
    }

    final member = guild.members[userId];
    await member.addRole(
      roleId,
      auditLogReason: (reason != null && reason.isNotEmpty)
          ? reason
          : 'Add role via BotCreator action',
    );

    return {
      'userId': userId.toString(),
      'roleId': roleId.toString(),
      'status': 'added',
    };
  } catch (error) {
    return {'error': 'Failed to add role: $error', 'userId': '', 'roleId': ''};
  }
}
