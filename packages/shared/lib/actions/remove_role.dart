import 'package:nyxx/nyxx.dart';
import 'package:bot_creator_shared/actions/handler_utils.dart';
import 'role_definition_actions.dart';
import '../services/bot_moderation_service.dart';
import '../engine/execution_budget.dart';

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
    return executeRoleDefinitionAction(
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
