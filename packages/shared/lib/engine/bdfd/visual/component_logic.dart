import 'package:nyxx/nyxx.dart';

import '../../../actions/edit_component_v2.dart';
import '../../../actions/respond_modal.dart';
import '../../../actions/send_component_v2.dart';
import '../../../bot/bot_data_store.dart';
import '../../../services/lavalink_service.dart';
import '../../../types/action.dart';
import '../../../utils/interaction_listener_registry.dart';
import '../../../utils/workflow_call.dart';
import '../runtime.dart' show BdfdResponseState;
import 'listener_logic.dart';
import 'message_block_logic.dart';

/// Component V2, modal, respondWithMessage, editInteractionMessage and listener
/// blocks (the latter through [runListenerBlock]). Returns false for any other
/// type.
Future<bool> runComponentsBlock({
  required BotCreatorActionType type,
  required NyxxGateway? client,
  required Interaction? interaction,
  required Map<String, dynamic> payload,
  required String resultKey,
  required Map<String, String> results,
  required Map<String, String> variables,
  required String botId,
  required Snowflake? guildId,
  required Snowflake? fallbackChannelId,
  Snowflake? fallbackMessageId,
  required String Function(String input) resolveValue,
  BotDataStore? store,
  LavalinkService? lavalinkService,
  BdfdResponseState? responseState,
}) async {
  switch (type) {
    case BotCreatorActionType.sendComponentV2:
      final result = await respondWithComponentV2Action(
        interaction,
        payload: payload,
        client: client,
        fallbackChannelId: fallbackChannelId,
        resolve: resolveValue,
        botId: botId,
        guildId: guildId?.toString(),
        variables: variables,
      );
      if (result['error'] != null) {
        throw Exception(result['error']);
      }
      results[resultKey] = result['messageId'] ?? '';
      return true;

    case BotCreatorActionType.editComponentV2:
      final result = await editComponentV2Action(
        client!,
        payload: payload,
        fallbackChannelId: fallbackChannelId,
        resolve: resolveValue,
        botId: botId,
        guildId: guildId?.toString(),
      );
      if (result['error'] != null) {
        throw Exception(result['error']);
      }
      results[resultKey] = result['messageId'] ?? '';
      return true;

    case BotCreatorActionType.respondWithComponentV2:
      final respResult = await respondWithComponentV2Action(
        interaction,
        payload: payload,
        client: client,
        fallbackChannelId: fallbackChannelId,
        resolve: resolveValue,
        botId: botId,
        guildId: guildId?.toString(),
        variables: variables,
      );
      if (respResult['error'] != null) {
        throw Exception(respResult['error']);
      }
      results[resultKey] = respResult['messageId'] ?? 'responded';
      return true;

    case BotCreatorActionType.respondWithMessage:
      await respondWithMessageBlock(
        interaction: interaction,
        client: client,
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        botId: botId,
        fallbackChannelId: fallbackChannelId,
        fallbackMessageId: fallbackMessageId,
        resolveValue: resolveValue,
        responseState: responseState,
      );
      return true;

    case BotCreatorActionType.respondWithModal:
      if (interaction == null) {
        results[resultKey] =
            'Error: respondWithModal requires an active interaction context';
        return true;
      }
      final modalResult = await respondWithModalAction(
        interaction,
        payload: payload,
        resolve: resolveValue,
      );
      if (modalResult['error'] != null) {
        throw Exception(modalResult['error']);
      }
      final customId = modalResult['customId'] ?? 'modal_sent';
      results[resultKey] = customId;

      // Support inline actions (new format) alongside legacy onSubmitWorkflow.
      final rawActions = modalResult['actions'];
      final hasInlineActions = rawActions is List && rawActions.isNotEmpty;

      final onSubmitWorkflow = resolveValue(
        (modalResult['onSubmitWorkflow'] ?? '').toString(),
      ).trim();

      if (hasInlineActions || onSubmitWorkflow.isNotEmpty) {
        List<Action>? inlineActions;
        if (hasInlineActions) {
          inlineActions = rawActions
              .whereType<Map>()
              .map((a) => Action.fromJson(Map<String, dynamic>.from(a)))
              .toList();
        }

        final onSubmitEntryPoint = onSubmitWorkflow.isNotEmpty
            ? resolveValue(
                (modalResult['onSubmitEntryPoint'] ?? '').toString(),
              ).trim()
            : '';
        final onSubmitArguments = resolveWorkflowCallArguments(
          modalResult['onSubmitArguments'],
          resolveValue,
        );
        InteractionListenerRegistry.instance.register(
          customId,
          ListenerEntry(
            botId: botId,
            workflowName: onSubmitWorkflow,
            workflowEntryPoint: onSubmitEntryPoint,
            workflowArguments: onSubmitArguments,
            inlineActions: inlineActions,
            expiresAt: DateTime.now().add(const Duration(hours: 1)),
            type: 'modal',
            oneShot: true,
            guildId: guildId?.toString(),
            channelId: fallbackChannelId?.toString(),
            messageId: resolveExplicitListenerMessageId(
              modalResult,
              resolveValue,
            ),
            initialContext: extractListenerContext(variables),
          ),
        );
      }
      return true;

    case BotCreatorActionType.editInteractionMessage:
      await editInteractionMessageBlock(
        interaction: interaction,
        payload: payload,
        resultKey: resultKey,
        results: results,
        botId: botId,
        resolveValue: resolveValue,
      );
      return true;

    case BotCreatorActionType.listenForButtonClick:
    case BotCreatorActionType.listenForSelectMenu:
    case BotCreatorActionType.listenForModalSubmit:
    case BotCreatorActionType.listenAndExecute:
      return runListenerBlock(
        type: type,
        client: client,
        interaction: interaction,
        payload: payload,
        resultKey: resultKey,
        results: results,
        variables: variables,
        botId: botId,
        guildId: guildId,
        fallbackChannelId: fallbackChannelId,
        resolveValue: resolveValue,
        store: store,
        lavalinkService: lavalinkService,
      );

    default:
      return false;
  }
}
