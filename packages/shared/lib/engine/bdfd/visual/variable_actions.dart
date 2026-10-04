import '../../../types/action.dart';
import 'action_environment.dart';
import 'calculate_logic.dart';
import 'http_logic.dart';
import 'variable_logic.dart';

/// Variable, JSON, HTTP and calculation actions on the native engine.
///
/// The logic lives in `variable_logic.dart`, `http_logic.dart` and
/// `calculate_logic.dart` (no dependency on the historical loop); the hidden
/// `bc_<type>` handlers run it over the shared stores and the native result
/// list ([ActionCall.sink]).

/// Every payload of these types is covered natively.
bool supportsVariableAction(Action action) =>
    variableLeafPredicates.containsKey(action.type);
bool supportsHttpAction(Action action) =>
    action.type == BotCreatorActionType.httpRequest;
bool supportsCalculateAction(Action action) =>
    action.type == BotCreatorActionType.calculate;

/// Routing predicates of the types of this family (read by `ActionTranslator`).
const variableLeafPredicates = <BotCreatorActionType, bool Function(Action)>{
  BotCreatorActionType.setTemporaryVariable: supportsVariableAction,
  BotCreatorActionType.runtimeJsonBlock: supportsVariableAction,
  BotCreatorActionType.setScopedVariable: supportsVariableAction,
  BotCreatorActionType.getScopedVariable: supportsVariableAction,
  BotCreatorActionType.removeScopedVariable: supportsVariableAction,
  BotCreatorActionType.renameScopedVariable: supportsVariableAction,
  BotCreatorActionType.listScopedVariableIndex: supportsVariableAction,
  BotCreatorActionType.appendArrayElement: supportsVariableAction,
  BotCreatorActionType.removeArrayElement: supportsVariableAction,
  BotCreatorActionType.queryArray: supportsVariableAction,
  BotCreatorActionType.setGlobalVariable: supportsVariableAction,
  BotCreatorActionType.getGlobalVariable: supportsVariableAction,
  BotCreatorActionType.removeGlobalVariable: supportsVariableAction,
  BotCreatorActionType.randomChoice: supportsVariableAction,
  BotCreatorActionType.httpRequest: supportsHttpAction,
  BotCreatorActionType.calculate: supportsCalculateAction,
};

/// Handlers of the types of this family (read by the `bc_*` registry).
const variableActionHandlers = <BotCreatorActionType, ActionHandler>{
  BotCreatorActionType.setTemporaryVariable: variableAction,
  BotCreatorActionType.runtimeJsonBlock: variableAction,
  BotCreatorActionType.setScopedVariable: variableAction,
  BotCreatorActionType.getScopedVariable: variableAction,
  BotCreatorActionType.removeScopedVariable: variableAction,
  BotCreatorActionType.renameScopedVariable: variableAction,
  BotCreatorActionType.listScopedVariableIndex: variableAction,
  BotCreatorActionType.appendArrayElement: variableAction,
  BotCreatorActionType.removeArrayElement: variableAction,
  BotCreatorActionType.queryArray: variableAction,
  BotCreatorActionType.setGlobalVariable: variableAction,
  BotCreatorActionType.getGlobalVariable: variableAction,
  BotCreatorActionType.removeGlobalVariable: variableAction,
  BotCreatorActionType.randomChoice: variableAction,
  BotCreatorActionType.httpRequest: httpRequestAction,
  BotCreatorActionType.calculate: calculateBlockAction,
};

Future<String?> variableAction(ActionCall call) async {
  final env = call.env;
  final store = env.store;
  if (store == null) {
    throw StateError('A data store is required for variable actions.');
  }
  final handled = await executeVariableAction(
    type: call.type,
    store: store,
    botId: env.botId,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: env.variables,
    resolveValue: call.resolve,
    guildId: env.guildSnowflake,
    fallbackChannelId: env.fallbackChannelId,
    interaction: env.interaction,
    onLog: env.onLog,
  );
  if (!handled) {
    throw StateError('Action ${call.type.name} is not a variable action.');
  }
  return null; // Results were written through the sink.
}

Future<String?> httpRequestAction(ActionCall call) async {
  final env = call.env;
  final store = env.store;
  if (store == null) {
    throw StateError('A data store is required for httpRequest.');
  }
  await executeHttp(
    type: call.type,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: env.variables,
    resolveValue: call.resolve,
    onLog: env.onLog,
    httpService: env.http,
    executionBudget: call.budget,
    setGlobalVariable: (key, value) =>
        store.setGlobalVariable(env.botId, key, value),
  );
  return null;
}

Future<String?> calculateBlockAction(ActionCall call) async {
  await executeCalculate(
    type: call.type,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: call.env.variables,
    resolveValue: call.resolve,
  );
  return null;
}
