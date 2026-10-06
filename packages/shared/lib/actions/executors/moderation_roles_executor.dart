import 'package:nyxx/nyxx.dart';

import '../../types/action.dart';
import '../../engine/execution_budget.dart';
import '../../services/bot_block_discord_actions.dart' show setNicknameAction;
import '../../services/bot_moderation_blocks.dart';

Future<bool> executeModerationRolesAction({
  required BotCreatorActionType type,
  required NyxxGateway client,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required String Function(String input) resolveValue,
  CommandExecutionBudget? budget,
}) async {
  switch (type) {
    case BotCreatorActionType.banUser:
    case BotCreatorActionType.unbanUser:
    case BotCreatorActionType.kickUser:
    case BotCreatorActionType.muteUser:
    case BotCreatorActionType.unmuteUser:
    case BotCreatorActionType.addRole:
    case BotCreatorActionType.removeRole:
    case BotCreatorActionType.setNickname:
      if (guildId == null) {
        throw Exception('User action requires a guild context');
      }

      final result = await switch (type) {
        BotCreatorActionType.banUser => banUserAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.unbanUser => unbanUserAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.kickUser => kickUserAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.muteUser => muteUserAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.unmuteUser => unmuteUserAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.addRole => addRoleAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.removeRole => removeRoleAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
          budget: budget,
        ),
        BotCreatorActionType.setNickname => setNicknameAction(
          client,
          guildId: guildId,
          payload: payload,
          resolve: resolveValue,
        ),
        _ => throw Exception('Unexpected action type'),
      };

      if (result['error'] != null) {
        throw Exception(result['error']);
      }

      results[resultKey] = result['userId'] ?? result['roleId'] ?? '';
      return true;

    default:
      return false;
  }
}
