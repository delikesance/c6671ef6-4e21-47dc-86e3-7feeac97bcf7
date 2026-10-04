import 'package:nyxx/nyxx.dart';

import '../engine/bdfd/runtime.dart' show BdfdResponseState;
import 'edit_interaction_response.dart';
import 'permission_checks.dart';
import 'pin_message.dart';
import 'respond_with_message.dart';
import 'unpin_message.dart';

/// Block bodies shared by the historical loop / executors and the native
/// `bc_*` functions (engine/bdfd/visual/message_actions.dart): one code path,
/// so effects, results and error texts cannot drift apart.

/// `pinMessage` (was inline in the historical loop's `switch`).
Future<void> pinMessageBlock({
  required NyxxGateway client,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Snowflake? fallbackChannelId,
  required String Function(String input) resolveValue,
  BotPermissionCache? permissionCache,
}) async {
  if (guildId != null) {
    final permError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.manageMessages],
      actionLabel: 'pin messages',
      cache: permissionCache,
    );
    if (permError != null) throw Exception(permError);
  }
  final resolvedPayload = Map<String, dynamic>.from(payload);
  if (payload.containsKey('messageId')) {
    resolvedPayload['messageId'] = resolveValue(payload['messageId'].toString());
  }
  if (payload.containsKey('channelId')) {
    resolvedPayload['channelId'] = resolveValue(payload['channelId'].toString());
  }
  final result = await pinMessageAction(
    client,
    payload: resolvedPayload,
    fallbackChannelId: fallbackChannelId,
  );
  if (result['error'] != null) {
    throw Exception(result['error']);
  }
  results[resultKey] = result['messageId'] ?? '';
}

/// `unpinMessage` (was inline in the historical loop's `switch`).
Future<void> unpinMessageBlock({
  required NyxxGateway client,
  required Snowflake? guildId,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Snowflake? fallbackChannelId,
  required String Function(String input) resolveValue,
  BotPermissionCache? permissionCache,
}) async {
  if (guildId != null) {
    final permError = await checkBotGuildPermission(
      client,
      guildId: guildId,
      requiredPermissions: [Permissions.manageMessages],
      actionLabel: 'unpin messages',
      cache: permissionCache,
    );
    if (permError != null) throw Exception(permError);
  }
  final resolvedPayload = Map<String, dynamic>.from(payload);
  if (payload.containsKey('messageId')) {
    resolvedPayload['messageId'] = resolveValue(payload['messageId'].toString());
  }
  if (payload.containsKey('channelId')) {
    resolvedPayload['channelId'] = resolveValue(payload['channelId'].toString());
  }
  final result = await unpinMessageAction(
    client,
    payload: resolvedPayload,
    fallbackChannelId: fallbackChannelId,
  );
  if (result['error'] != null) {
    throw Exception(result['error']);
  }
  results[resultKey] = result['status'] ?? 'unpinned';
}

/// `respondWithMessage` (was in the components/interactions executor).
Future<void> respondWithMessageBlock({
  required Interaction? interaction,
  required NyxxGateway? client,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String botId,
  required Snowflake? fallbackChannelId,
  required Snowflake? fallbackMessageId,
  required String Function(String input) resolveValue,
  BdfdResponseState? responseState,
}) async {
  final messageResult = await respondWithMessageAction(
    interaction,
    payload: payload,
    resolve: resolveValue,
    botId: botId,
    client: client,
    fallbackChannelId: fallbackChannelId,
    fallbackMessageId: fallbackMessageId,
    variables: variables,
  );
  if (messageResult['error'] != null) {
    throw Exception(messageResult['error']);
  }
  if (messageResult['originalResponseCompleted'] == true &&
      responseState != null) {
    responseState.originalResponseCompleted = true;
    responseState.acknowledged = true;
  }
  results[resultKey] = messageResult['messageId'] ?? 'responded';
  if ((messageResult['messageId'] ?? '').isNotEmpty) {
    variables['last.response.id'] = messageResult['messageId']!;
  }
}

/// `editInteractionMessage` (was in the components/interactions executor).
Future<void> editInteractionMessageBlock({
  required Interaction? interaction,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required String botId,
  required String Function(String input) resolveValue,
}) async {
  if (interaction == null) {
    results[resultKey] =
        'Error: editInteractionMessage requires an interaction context';
    return;
  }
  final editResult = await editInteractionMessageAction(
    interaction,
    payload: payload,
    resolve: resolveValue,
    botId: botId,
  );
  if (editResult['error'] != null) {
    throw Exception(editResult['error']);
  }
  results[resultKey] = editResult['messageId'] ?? '';
}
