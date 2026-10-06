import 'dart:async';
import 'package:nyxx/nyxx.dart';

import '../../../actions/handle_component_interaction.dart';
import '../../../bot/bot_data_store.dart';
import '../../../services/lavalink_service.dart';
import '../../../types/action.dart';
import '../../../utils/interaction_listener_registry.dart';
import '../../../utils/workflow_call.dart';

/// Registration (and immediate start) of interaction listeners: the logic of
/// listenForButtonClick, listenForSelectMenu, listenForModalSubmit and
/// listenAndExecute. Registers [ListenerEntry]s in the in-memory
/// [InteractionListenerRegistry]; returns false for any other type.
String? resolveListenerMessageId({
  required Map<String, dynamic> payload,
  required Map<String, String> variables,
  required String Function(String input) resolveValue,
  Interaction? interaction,
}) {
  final explicitMessageId = resolveValue(
    (payload['messageId'] ?? '').toString(),
  ).trim();
  if (explicitMessageId.isNotEmpty) {
    return explicitMessageId;
  }

  final runtimeMessageId =
      variables['interaction.messageId'] ??
      variables['messageId'] ??
      variables['message.id'];
  if (runtimeMessageId != null && runtimeMessageId.trim().isNotEmpty) {
    return runtimeMessageId.trim();
  }

  final dynamic dynInteraction = interaction;
  final interactionMessageId = (dynInteraction?.message?.id as Snowflake?)
      ?.toString();
  if (interactionMessageId != null && interactionMessageId.isNotEmpty) {
    return interactionMessageId;
  }

  return null;
}

String? resolveExplicitListenerMessageId(
  Map<String, dynamic> payload,
  String Function(String input) resolveValue,
) {
  final messageId = resolveValue(
    (payload['messageId'] ?? '').toString(),
  ).trim();
  return messageId.isEmpty ? null : messageId;
}

Future<bool> runListenerBlock({
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
  required String Function(String input) resolveValue,
  BotDataStore? store,
  LavalinkService? lavalinkService,
}) async {
  switch (type) {
    case BotCreatorActionType.listenForButtonClick:
    case BotCreatorActionType.listenForSelectMenu:
    case BotCreatorActionType.listenForModalSubmit:
      final customId = resolveValue((payload['customId'] ?? '').toString());
      if (customId.isEmpty) {
        throw Exception('customId is required for ${type.name}');
      }
      final workflowName = resolveValue(
        (payload['workflowName'] ?? '').toString(),
      );
      if (workflowName.isEmpty) {
        throw Exception('workflowName is required for ${type.name}');
      }

      // Guard: in an event workflow, listenForButtonClick/listenForSelectMenu
      // without an explicit messageId should NOT derive a messageId from the
      // triggering event context (that would cause mismatches on subsequent
      // clicks). Instead, pass null so the listener matches any message with
      // the given customId.

      final ttlRaw = payload['ttlMinutes'];
      final ttlMinutes =
          (ttlRaw is num
                  ? ttlRaw.toInt()
                  : int.tryParse(ttlRaw?.toString() ?? '') ?? 60)
              .clamp(1, 60);
      // Modals are always one-shot; buttons/selects repeat on every click until TTL.
      final oneShot = type == BotCreatorActionType.listenForModalSubmit;
      final workflowEntryPoint = resolveValue(
        (payload['entryPoint'] ?? '').toString(),
      ).trim();
      final workflowArguments = resolveWorkflowCallArguments(
        payload['arguments'],
        resolveValue,
      );

      InteractionListenerRegistry.instance.register(
        customId,
        ListenerEntry(
          botId: botId,
          workflowName: workflowName,
          workflowEntryPoint: workflowEntryPoint,
          workflowArguments: workflowArguments,
          expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
          type: type == BotCreatorActionType.listenForButtonClick
              ? 'button'
              : type == BotCreatorActionType.listenForSelectMenu
              ? 'select'
              : 'modal',
          oneShot: oneShot,
          guildId: guildId?.toString(),
          channelId: fallbackChannelId?.toString(),
          initialContext: extractListenerContext(variables),
          messageId: type == BotCreatorActionType.listenForModalSubmit
              ? resolveExplicitListenerMessageId(payload, resolveValue)
              : variables['workflow.type'] == workflowTypeEvent
              ? resolveExplicitListenerMessageId(payload, resolveValue)
              : resolveListenerMessageId(
                  payload: payload,
                  variables: variables,
                  resolveValue: resolveValue,
                  interaction: interaction,
                ),
        ),
      );

      final currentCustomId =
          (interaction is MessageComponentInteraction ||
              interaction is ModalSubmitInteraction)
          ? (interaction as dynamic).data.customId.toString()
          : null;
      if (currentCustomId == customId && store != null && client != null) {
        unawaited(
          runListenerWorkflow(
            client: client,
            store: store,
            botId: botId,
            workflowName: workflowName,
            workflowEntryPoint: workflowEntryPoint,
            workflowArguments: workflowArguments,
            variables: variables,
            interaction: interaction,
            lavalinkService: lavalinkService,
          ),
        );
      }

      results[resultKey] = 'listening:$customId';
      return true;

    case BotCreatorActionType.listenAndExecute:
      final customId = resolveValue((payload['customId'] ?? '').toString());
      if (customId.isEmpty) {
        throw Exception('customId is required for ${type.name}');
      }
      final rawActions = payload['actions'];
      final inlineActions = <Action>[];
      if (rawActions is List) {
        for (final item in rawActions) {
          if (item is Map) {
            inlineActions.add(Action.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      }

      final workflowName = resolveValue(
        (payload['workflowName'] ?? '').toString(),
      );
      final workflowEntryPoint = resolveValue(
        (payload['entryPoint'] ?? '').toString(),
      ).trim();
      final workflowArguments = resolveWorkflowCallArguments(
        payload['arguments'],
        resolveValue,
      );

      final ttlRaw = payload['ttlMinutes'];
      final ttlMinutes =
          (ttlRaw is num
                  ? ttlRaw.toInt()
                  : int.tryParse(ttlRaw?.toString() ?? '') ?? 60)
              .clamp(1, 60);

      // Register for button
      InteractionListenerRegistry.instance.register(
        customId,
        ListenerEntry(
          botId: botId,
          inlineActions: inlineActions.isNotEmpty ? inlineActions : null,
          workflowName: workflowName,
          workflowEntryPoint: workflowEntryPoint.isNotEmpty
              ? workflowEntryPoint
              : 'main',
          workflowArguments: workflowArguments,
          expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
          type: 'button',
          oneShot: false,
          guildId: guildId?.toString(),
          channelId: fallbackChannelId?.toString(),
          initialContext: extractListenerContext(variables),
          messageId: variables['workflow.type'] == workflowTypeEvent
              ? resolveExplicitListenerMessageId(payload, resolveValue)
              : resolveListenerMessageId(
                  payload: payload,
                  variables: variables,
                  resolveValue: resolveValue,
                  interaction: interaction,
                ),
        ),
      );

      // Register for select
      InteractionListenerRegistry.instance.register(
        customId,
        ListenerEntry(
          botId: botId,
          inlineActions: inlineActions.isNotEmpty ? inlineActions : null,
          workflowName: workflowName,
          workflowEntryPoint: workflowEntryPoint.isNotEmpty
              ? workflowEntryPoint
              : 'main',
          workflowArguments: workflowArguments,
          expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
          type: 'select',
          oneShot: false,
          guildId: guildId?.toString(),
          channelId: fallbackChannelId?.toString(),
          initialContext: extractListenerContext(variables),
          messageId: variables['workflow.type'] == workflowTypeEvent
              ? resolveExplicitListenerMessageId(payload, resolveValue)
              : resolveListenerMessageId(
                  payload: payload,
                  variables: variables,
                  resolveValue: resolveValue,
                  interaction: interaction,
                ),
        ),
      );

      // Register for modal
      InteractionListenerRegistry.instance.register(
        customId,
        ListenerEntry(
          botId: botId,
          inlineActions: inlineActions.isNotEmpty ? inlineActions : null,
          workflowName: workflowName,
          workflowEntryPoint: workflowEntryPoint.isNotEmpty
              ? workflowEntryPoint
              : 'main',
          workflowArguments: workflowArguments,
          expiresAt: DateTime.now().add(Duration(minutes: ttlMinutes)),
          type: 'modal',
          oneShot: true,
          guildId: guildId?.toString(),
          channelId: fallbackChannelId?.toString(),
          initialContext: extractListenerContext(variables),
          messageId: resolveExplicitListenerMessageId(payload, resolveValue),
        ),
      );

      // Immediate Execution Check!
      final currentCustomId =
          (interaction is MessageComponentInteraction ||
              interaction is ModalSubmitInteraction)
          ? (interaction as dynamic).data.customId.toString()
          : null;
      if (currentCustomId == customId && store != null && client != null) {
        if (inlineActions.isNotEmpty) {
          unawaited(
            runListenerInlineActions(
              client: client,
              store: store,
              botId: botId,
              inlineActions: inlineActions,
              variables: variables,
              workflowArguments: workflowArguments,
              interaction: interaction,
              lavalinkService: lavalinkService,
            ),
          );
        } else if (workflowName.isNotEmpty) {
          unawaited(
            runListenerWorkflow(
              client: client,
              store: store,
              botId: botId,
              workflowName: workflowName,
              workflowEntryPoint: workflowEntryPoint,
              workflowArguments: workflowArguments,
              variables: variables,
              interaction: interaction,
              lavalinkService: lavalinkService,
            ),
          );
        }
      }

      results[resultKey] = 'listening:$customId';
      return true;

    default:
      return false;
  }
}
