import '../../../actions/executors/components_interactions_executor.dart';
import '../../../types/action.dart';
import 'action_environment.dart';
import 'variable_actions.dart' show variableAction;

/// Component V2, modal and autocomplete blocks on the native engine:
/// respondWithComponentV2, sendComponentV2, editComponentV2, respondWithModal
/// (inline `actions` and `onSubmit*` included) and respondWithAutocomplete.
///
/// Parity strategy (as for the variable family): the component payload building
/// (`ComponentV2Definition` / `buildComponentNodes` / `buildModalResponse`), the
/// interaction responses, the acknowledgement bookkeeping and the registration
/// of the modal-submit listener are the very implementations the historical loop
/// runs (`executeComponentsInteractionsAction`, `executeVariablesAction`), over
/// the shared services and the native result list, so effects, `results` keys,
/// variables and error text are identical by construction.
///
/// Acknowledgement rules stay with the translator: a program holding a
/// `respondWithModal` is never auto-deferred (the modal must be the first
/// response) and the action marks the interaction acknowledged itself.

/// Every payload of these types runs natively.
bool supportsComponentAction(Action action) =>
    componentLeafPredicates.containsKey(action.type);

const componentLeafPredicates = <BotCreatorActionType, bool Function(Action)>{
  BotCreatorActionType.respondWithComponentV2: supportsComponentAction,
  BotCreatorActionType.sendComponentV2: supportsComponentAction,
  BotCreatorActionType.editComponentV2: supportsComponentAction,
  BotCreatorActionType.respondWithModal: supportsComponentAction,
  BotCreatorActionType.respondWithAutocomplete: supportsComponentAction,
};

const componentActionHandlers = <BotCreatorActionType, ActionHandler>{
  BotCreatorActionType.respondWithComponentV2: componentsInteractionsAction,
  BotCreatorActionType.sendComponentV2: componentsInteractionsAction,
  BotCreatorActionType.editComponentV2: componentsInteractionsAction,
  BotCreatorActionType.respondWithModal: componentsInteractionsAction,
  BotCreatorActionType.respondWithAutocomplete: autocompleteAction,
};

/// Runs a block of the components / interactions executor over the native
/// state. Shared with the listener family (`listener_actions.dart`).
Future<String?> componentsInteractionsAction(ActionCall call) async {
  final env = call.env;
  final handled = await executeComponentsInteractionsAction(
    type: call.type,
    client: env.client,
    interaction: env.interaction,
    payload: call.payload,
    resultKey: call.key,
    results: call.sink.scope(call.path),
    variables: env.variables,
    botId: env.botId,
    guildId: env.guildSnowflake,
    fallbackChannelId: env.fallbackChannelId,
    resolveValue: call.resolve,
    store: env.store,
    lavalinkService: env.lavalinkService,
  );
  if (!handled) {
    throw StateError('Action ${call.type.name} is not a component action.');
  }
  return null; // Results were written through the sink.
}

/// `respondWithAutocomplete`: answers the autocomplete interaction and stops the
/// list. The result list keeps `__stopped__ = AUTOCOMPLETE` (see `_markStopped`).
Future<String?> autocompleteAction(ActionCall call) async {
  await variableAction(call);
  if (call.sink.scope(call.path).containsKey('__stopped__')) {
    call.requestStop();
  }
  return null;
}
