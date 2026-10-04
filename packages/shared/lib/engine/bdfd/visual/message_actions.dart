import 'package:nyxx/nyxx.dart' show NyxxGateway, Snowflake;

import '../../../actions/executors/messaging_executor.dart'
    show executeMessagingAction;
import '../../../actions/executors/reactions_executor.dart'
    show executeReactionsAction;
import '../../../actions/message_block_actions.dart';
import '../../../types/action.dart';
import '../../../utils/component_runtime.dart'
    show resolveComponentRuntimeFields;
import '../runtime.dart' show BdfdContext;
import 'action_environment.dart';

/// Messaging and interaction blocks on the native engine: sendMessage,
/// editMessage, getMessage, deleteMessages, deleteTrigger, sendDm, pinMessage,
/// unpinMessage, deferInteraction, respondWithMessage, editInteractionMessage,
/// addReaction, removeReaction and clearAllReactions.
///
/// Parity with the historical loop: the effect of every block is the very same
/// function the historical executors call (`executeMessagingAction`,
/// `executeReactionsAction`, [pinMessageBlock], [respondWithMessageBlock]...),
/// fed the same resolved values, so Discord calls, `results[key]`, the
/// `variables` mirrors (`<key>.messageId`, `last.response.id`, `<key>.count`),
/// canvas attachments, embeds/components payloads, allowed mentions and error
/// texts are identical.
///
/// **Immediate sending.** These blocks send right away. They never touch the
/// BDFD buffered response draft of a host script (the runner parks it for the
/// duration of a visual program and puts it back afterwards): a script's
/// `$title[...]`/text output is neither consumed nor flushed by a block, and
/// is still sent once, at the end of the script.
///
/// **Interaction acknowledgement.** `deferInteraction` acknowledges at once
/// (ephemeral from its payload), `respondWithMessage` picks edit-original /
/// follow-up / first response from the interaction's acknowledgement state
/// (`isInteractionAcknowledged`) and flags the host response state
/// (`originalResponseCompleted`) like the historical executor. The automatic
/// deferral before the actions (and its ephemeral hint) stays in
/// `executeVisualWorkflow`, fed by `BdfdActionProgram.hasDefer`/`hasModal`/
/// `ephemeralHint`.
final Map<BotCreatorActionType, ActionHandler> messageActionHandlers = {
  for (final type in _messagingTypes)
    type: (call) => _messaging(call, type),
  for (final type in _reactionTypes) type: (call) => _reaction(call, type),
  BotCreatorActionType.pinMessage: _pin,
  BotCreatorActionType.unpinMessage: _unpin,
  BotCreatorActionType.respondWithMessage: _respond,
  BotCreatorActionType.editInteractionMessage: _editInteraction,
};

const _messagingTypes = [
  BotCreatorActionType.sendMessage,
  BotCreatorActionType.editMessage,
  BotCreatorActionType.getMessage,
  BotCreatorActionType.deleteMessages,
  BotCreatorActionType.deleteTrigger,
  BotCreatorActionType.sendDm,
  BotCreatorActionType.deferInteraction,
];

const _reactionTypes = [
  BotCreatorActionType.addReaction,
  BotCreatorActionType.removeReaction,
  BotCreatorActionType.clearAllReactions,
];

/// The historical loop records the trace (and, with it, the numeric "last
/// message" bookkeeping) of these two only while a `$debug` profile or a replay
/// capture is running: they are handled in its `switch`, not by an executor.
const Set<BotCreatorActionType> messageProfilingOnlyTraceTypes = {
  BotCreatorActionType.pinMessage,
  BotCreatorActionType.unpinMessage,
};

bool _always(Action action) => true;

/// Every payload of these types runs natively.
final Map<BotCreatorActionType, bool Function(Action)> messageLeafPredicates = {
  for (final type in messageActionHandlers.keys) type: _always,
};

// -- Helpers shared with the other native families (components, listeners...) --

/// The Discord client of the execution; throws like a missing service.
NyxxGateway visualClient(ActionCall call) {
  final client = call.env.client;
  if (client == null) {
    throw StateError('A Discord client is required for ${call.type.name}.');
  }
  return client;
}

/// `resolvedFallbackChannelId` of the historical loop: the explicit fallback
/// channel, else the channel of the interaction.
Snowflake? visualResolvedFallbackChannel(ActionRunEnvironment env) =>
    env.fallbackChannelId ??
    (env.interaction as dynamic)?.channel?.id as Snowflake?;

/// The `fallbackChannelId` the historical *components* executor (and pin) get:
/// the raw fallback in the list the loop was started for, but the resolved one
/// in every nested list (`executeNestedActions` passes the resolved channel).
Snowflake? visualComponentFallbackChannel(ActionCall call) => call.path.isEmpty
    ? call.env.fallbackChannelId
    : visualResolvedFallbackChannel(call.env);

/// `fallbackMessageId` of `respondWithMessage`: the triggering message.
Snowflake? visualFallbackMessageId(Map<String, String> variables) {
  final raw = (variables['message.id'] ?? variables['messageId'])?.trim();
  if (raw == null || raw.isEmpty) return null;
  final parsed = int.tryParse(raw);
  return parsed == null ? null : Snowflake(parsed);
}

/// The payload as the historical loop hands it to an executor: the component
/// definitions of a *nested* action get their typed runtime fields resolved
/// here (the loop did it per nested list; a top-level action routed from the
/// loop already arrives resolved).
Map<String, dynamic> visualMessagePayload(ActionCall call) {
  if (call.path.isEmpty) return call.payload;
  final payload = Map<String, dynamic>.from(call.payload);
  for (final key in const ['components', 'componentV2', 'modal']) {
    final definition = payload[key];
    if (definition is Map) {
      payload[key] = resolveComponentRuntimeFields(
        Map<String, dynamic>.from(definition),
        call.resolve,
      );
    }
  }
  return payload;
}

Future<String?> _messaging(ActionCall call, BotCreatorActionType type) async {
  final env = call.env;
  final handled = await executeMessagingAction(
    type: type,
    client: visualClient(call),
    interaction: env.interaction,
    payload: visualMessagePayload(call),
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: env.variables,
    botId: env.botId,
    guildId: env.guildSnowflake,
    fallbackChannelId: visualResolvedFallbackChannel(env),
    resolveValue: call.resolve,
    permissionCache: env.permissionCache,
  );
  if (!handled) {
    throw StateError('Action ${type.name} has no messaging handler.');
  }
  return null; // Written by the shared body, like the historical executor.
}

Future<String?> _reaction(ActionCall call, BotCreatorActionType type) async {
  final env = call.env;
  final handled = await executeReactionsAction(
    type: type,
    client: visualClient(call),
    payload: visualMessagePayload(call),
    resultKey: call.key,
    results: call.sink.scope(call.path),
    fallbackChannelId: visualResolvedFallbackChannel(env),
    guildId: env.guildSnowflake,
    resolveValue: call.resolve,
    permissionCache: env.permissionCache,
  );
  if (!handled) {
    throw StateError('Action ${type.name} has no reaction handler.');
  }
  return null;
}

Future<String?> _pin(ActionCall call) async {
  await pinMessageBlock(
    client: visualClient(call),
    guildId: call.env.guildSnowflake,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    // The historical switch hands pinMessage the loop's raw fallback channel.
    fallbackChannelId: visualComponentFallbackChannel(call),
    resolveValue: call.resolve,
    permissionCache: call.env.permissionCache,
  );
  return null;
}

Future<String?> _unpin(ActionCall call) async {
  await unpinMessageBlock(
    client: visualClient(call),
    guildId: call.env.guildSnowflake,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    fallbackChannelId: visualResolvedFallbackChannel(call.env),
    resolveValue: call.resolve,
    permissionCache: call.env.permissionCache,
  );
  return null;
}

Future<String?> _respond(ActionCall call) async {
  final env = call.env;
  await respondWithMessageBlock(
    interaction: env.interaction,
    client: env.client,
    payload: visualMessagePayload(call),
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: env.variables,
    botId: env.botId,
    fallbackChannelId: visualComponentFallbackChannel(call),
    fallbackMessageId: visualFallbackMessageId(env.variables),
    resolveValue: call.resolve,
    responseState: call.context.response,
  );
  return null;
}

Future<String?> _editInteraction(ActionCall call) async {
  await editInteractionMessageBlock(
    interaction: call.env.interaction,
    payload: visualMessagePayload(call),
    resultKey: call.key,
    results: call.sink.scope(call.path),
    botId: call.env.botId,
    resolveValue: call.resolve,
  );
  return null;
}

/// Sends a `respondWithMessage` the way the historical loop runs a synthetic
/// one-action list (what `ifBlock.suppressErrors` does with its message and
/// embed): immediate, same hydration, error bookkeeping and "last message"
/// variables, and a result list that is dropped afterwards.
///
/// [path] is the path of the block that owns the message; the synthetic action
/// is `action_0` of a list nested under it.
Future<void> visualRespondWithMessage(
  ActionRunEnvironment env,
  BdfdContext context, {
  required List<String> path,
  required Map<String, dynamic> payload,
  String key = 'action_0',
}) async {
  // A list of its own: nothing it writes is published to the block's list.
  final scopePath = [...path, '\u0002respond'];
  final resolve = env.resolverFor(scopePath);
  final results = env.sink.scope(scopePath);
  try {
    env.budget.check();
    await env.prepare?.call(
      BotCreatorActionType.respondWithMessage,
      key,
      payload,
      scopePath,
    );
    env.flow.refreshExecutionTime?.call();
    await respondWithMessageBlock(
      interaction: env.interaction,
      client: env.client,
      payload: payload,
      resultKey: key,
      results: results,
      variables: env.variables,
      botId: env.botId,
      // Nested lists carry the resolved fallback channel.
      fallbackChannelId: visualResolvedFallbackChannel(env),
      fallbackMessageId: visualFallbackMessageId(env.variables),
      resolveValue: resolve,
      responseState: context.response,
    );
    env.sink.noteNumeric(scopePath, key);
  } catch (error) {
    // The nested list's own error bookkeeping, then the failure propagates.
    env.sink.recordError('respondWithMessage', key, scopePath, error);
    rethrow;
  } finally {
    env.sink.discard(scopePath);
  }
}
