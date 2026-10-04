import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/actions/handler_utils.dart';
import 'role_definition_actions.dart';
import '../services/bot_moderation_service.dart';
import '../services/role_definition.dart';
import '../engine/execution_budget.dart';

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
      return executeRoleDefinitionAction(
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
